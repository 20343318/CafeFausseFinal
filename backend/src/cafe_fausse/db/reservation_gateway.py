"""Certainty-aware PostgreSQL adapter for OP-05 reservation booking."""

from __future__ import annotations

from dataclasses import replace
from datetime import datetime
from time import monotonic
from zoneinfo import ZoneInfo

from psycopg import InterfaceError, OperationalError, ProgrammingError
from psycopg_pool import ConnectionPool, PoolTimeout

from ..services.results import BookingOutcome, ReservationBookingResult, ReservationCommand
from .exceptions import (
    DatabaseContractError,
    DatabaseMutationFailure,
    ReservationConfirmationFailure,
    mutation_sqlstate,
)

_BOOK_SQL = """
SELECT outcome, detail_code, reservation_id, starts_at, ends_at, party_size,
       assigned_table_numbers, newsletter_subscribed, phone_notice,
       fingerprint_version, reservation_fingerprint
FROM cafe_fausse.book_reservation(%s, %s, %s, %s, %s, %s, %s::smallint, %s, %s)
"""
_CONFIRMATION_SQL = """
SELECT customer.first_name, customer.middle_initial, customer.last_name,
       configuration.restaurant_timezone
FROM cafe_fausse.customers AS customer
CROSS JOIN cafe_fausse.reservation_configuration AS configuration
WHERE customer.email = %s
  AND configuration.configuration_id = 1
"""
_RETRYABLE_SQLSTATES = frozenset({"55P03", "40P01", "40001"})
_OUTCOME_MAP = {
    "booked": BookingOutcome.BOOKED,
    "booked_phone_notice": BookingOutcome.BOOKED_PHONE_NOTICE,
    "exact_retry": BookingOutcome.EXACT_RETRY,
    "same_customer_overlap": BookingOutcome.SAME_CUSTOMER_OVERLAP,
    "customer_identity_mismatch": BookingOutcome.CUSTOMER_IDENTITY_CONFLICT,
    "middle_initial_conflict": BookingOutcome.MIDDLE_INITIAL_CONFLICT,
    "unavailable": BookingOutcome.UNAVAILABLE,
    "invalid_request": BookingOutcome.INVALID_REQUEST,
    "invalid_database_configuration": BookingOutcome.INVALID_DATABASE_CONFIGURATION,
}
_DETAILS = frozenset({
    "requires_read_committed", "invalid_normalized_input", "configuration_row_count",
    "operating_hours_population", "restaurant_table_population", "invalid_timezone",
    "nonexistent_local_start", "ambiguous_local_start", "utc_offset_mismatch",
    "date_outside_booking_window", "insufficient_same_day_lead", "start_before_opening",
    "misaligned_start", "end_after_closing", "duration_or_party_size_out_of_range",
    "no_capacity_sufficient_combination", "time_boundary_crossed_during_booking",
})


def _milliseconds(seconds: float) -> float:
    return round(max(0.0, seconds) * 1000, 3)


def _close_unsafe(connection: object) -> bool:
    try:
        connection.close()
        return False
    except Exception:
        return True


def _failure(error: Exception, *, dispatched: bool, rollback_confirmed: bool, cleanup_failed: bool, pool_wait_ms: float, database_ms: float):
    if isinstance(error, DatabaseContractError) and rollback_confirmed:
        error.cleanup_failed = error.cleanup_failed or cleanup_failed
        return error
    sqlstate = mutation_sqlstate(error)
    outcome_unknown = dispatched and not rollback_confirmed
    if rollback_confirmed and isinstance(error, ProgrammingError) and sqlstate not in _RETRYABLE_SQLSTATES:
        return DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms, cleanup_failed=cleanup_failed)
    safe_to_retry = not outcome_unknown and rollback_confirmed and (
        (not dispatched and isinstance(error, (InterfaceError, OperationalError, PoolTimeout, TimeoutError)))
        or (dispatched and sqlstate in _RETRYABLE_SQLSTATES)
    )
    return DatabaseMutationFailure(
        sqlstate=sqlstate, safe_to_retry=safe_to_retry,
        mutation_dispatched=dispatched, outcome_unknown=outcome_unknown,
        pool_wait_ms=pool_wait_ms, database_ms=database_ms, cleanup_failed=cleanup_failed,
    )


def _decode(rows: object, command: ReservationCommand, pool_wait_ms: float, database_ms: float) -> ReservationBookingResult:
    if not isinstance(rows, list) or len(rows) != 1 or not isinstance(rows[0], (tuple, list)) or len(rows[0]) != 11:
        raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    (outcome_text, detail, reservation_id, starts_at, ends_at, party_size, tables,
     subscribed, phone_notice, fingerprint_version, fingerprint) = rows[0]
    if not isinstance(outcome_text, str) or outcome_text not in _OUTCOME_MAP:
        raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    outcome = _OUTCOME_MAP[outcome_text]
    if detail is not None and (not isinstance(detail, str) or detail not in _DETAILS):
        raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    success = outcome in {BookingOutcome.BOOKED, BookingOutcome.BOOKED_PHONE_NOTICE, BookingOutcome.EXACT_RETRY}
    if success:
        valid = (
            detail is None and type(reservation_id) is int and reservation_id > 0
            and isinstance(starts_at, datetime) and starts_at.tzinfo is not None and starts_at.microsecond == 0
            and isinstance(ends_at, datetime) and ends_at.tzinfo is not None and ends_at.microsecond == 0 and ends_at > starts_at
            and type(party_size) is int and party_size > 0
            and isinstance(tables, list) and bool(tables)
            and all(type(number) is int and 1 <= number <= 32767 for number in tables)
            and tables == sorted(set(tables)) and type(subscribed) is bool
            and type(phone_notice) is bool and phone_notice is (outcome is BookingOutcome.BOOKED_PHONE_NOTICE)
            and fingerprint_version == 1 and isinstance(fingerprint, (bytes, bytearray, memoryview))
            and len(fingerprint) == 32
        )
        if not valid:
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    else:
        if outcome in {BookingOutcome.INVALID_REQUEST, BookingOutcome.INVALID_DATABASE_CONFIGURATION, BookingOutcome.UNAVAILABLE} and detail is None:
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
        if outcome in {BookingOutcome.CUSTOMER_IDENTITY_CONFLICT, BookingOutcome.MIDDLE_INITIAL_CONFLICT, BookingOutcome.SAME_CUSTOMER_OVERLAP} and detail is not None:
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
        if type(phone_notice) is not bool or phone_notice:
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    return ReservationBookingResult(
        outcome=outcome, detail_code=detail, reservation_id=reservation_id,
        starts_at=starts_at, ends_at=ends_at, party_size=party_size,
        assigned_table_numbers=tuple(tables or ()), newsletter_subscribed=subscribed,
        phone_notice=phone_notice,
        pool_wait_ms=pool_wait_ms, database_ms=database_ms,
    )


def _stored_name(rows: object) -> str:
    if not isinstance(rows, list) or len(rows) != 1 or not isinstance(rows[0], (tuple, list)) or len(rows[0]) != 3:
        raise ValueError()
    first, middle, last = rows[0]
    if not isinstance(first, str) or not first or middle is not None and (not isinstance(middle, str) or len(middle) != 1) or not isinstance(last, str) or not last:
        raise ValueError()
    return " ".join(part for part in (first, f"{middle}." if middle is not None else None, last) if part is not None)


def _confirmation_facts(rows: object) -> tuple[str, str]:
    if not isinstance(rows, list) or len(rows) != 1 or not isinstance(rows[0], (tuple, list)) or len(rows[0]) != 4:
        raise ValueError()
    first, middle, last, timezone_name = rows[0]
    name = _stored_name([(first, middle, last)])
    if not isinstance(timezone_name, str) or not timezone_name:
        raise ValueError()
    ZoneInfo(timezone_name)
    return name, timezone_name


class ReservationGateway:
    def __init__(self, pool: ConnectionPool, *, acquire_timeout_ms: int, clock=monotonic) -> None:
        self._pool = pool
        self._acquire_timeout_seconds = acquire_timeout_ms / 1000
        self._clock = clock

    def book(self, command: ReservationCommand, timeout_seconds: float | None = None) -> ReservationBookingResult:
        started = self._clock()
        deadline = started + (timeout_seconds if timeout_seconds is not None else self._acquire_timeout_seconds)
        acquired = started
        database_started = started
        connection = None
        connection_acquired = False
        transaction_started = False
        dispatched = False
        body_completed = False
        committed = False
        cleanup_failed = False
        unsafe_disposal_failed = False
        primary_error: Exception | None = None
        pending_error: Exception | None = None
        result: ReservationBookingResult | None = None
        try:
            remaining = deadline - self._clock()
            if remaining <= 0:
                raise TimeoutError()
            connection = self._pool.getconn(timeout=min(self._acquire_timeout_seconds, remaining))
            acquired = self._clock()
            database_started = acquired
            connection_acquired = True
            try:
                try:
                    with connection:
                        try:
                            remaining_ms = int((deadline - self._clock()) * 1000)
                            if remaining_ms < 1:
                                raise TimeoutError()
                            with connection.cursor() as cursor:
                                cursor.execute("BEGIN ISOLATION LEVEL READ COMMITTED")
                                transaction_started = True
                                cursor.execute("SELECT set_config('statement_timeout', %s, true)", (f"{remaining_ms}ms",))
                                dispatched = True
                                cursor.execute(_BOOK_SQL, (
                                    command.first_name, command.middle_initial, command.last_name,
                                    command.email, command.phone, command.local_start,
                                    command.utc_offset_minutes, command.party_size, command.newsletter_action,
                                ))
                                rows = cursor.fetchall()
                                now = self._clock()
                                result = _decode(rows, command, _milliseconds(acquired - started), _milliseconds(now - database_started))
                            body_completed = True
                        except Exception as operation_error:
                            primary_error = operation_error
                            raise
                    transaction_started = False
                    committed = True
                except Exception as context_error:
                    if primary_error is None:
                        primary_error = context_error
                    rollback_confirmed = not body_completed and context_error is primary_error
                    if not body_completed and context_error is not primary_error:
                        cleanup_failed = True
                    if body_completed or (dispatched and not rollback_confirmed):
                        unsafe_disposal_failed = _close_unsafe(connection)
                        cleanup_failed = cleanup_failed or unsafe_disposal_failed
                    pending_error = _failure(
                        primary_error, dispatched=dispatched, rollback_confirmed=rollback_confirmed,
                        cleanup_failed=cleanup_failed, pool_wait_ms=_milliseconds(acquired - started),
                        database_ms=_milliseconds(self._clock() - database_started),
                    )

                if pending_error is None:
                    assert result is not None
                    if result.outcome in {BookingOutcome.BOOKED, BookingOutcome.BOOKED_PHONE_NOTICE, BookingOutcome.EXACT_RETRY}:
                        try:
                            remaining_ms = int((deadline - self._clock()) * 1000)
                            if remaining_ms < 1:
                                raise TimeoutError()
                            with connection.transaction():
                                with connection.cursor() as cursor:
                                    cursor.execute("SET TRANSACTION ISOLATION LEVEL READ COMMITTED READ ONLY")
                                    cursor.execute("SELECT set_config('statement_timeout', %s, true)", (f"{remaining_ms}ms",))
                                    cursor.execute(_CONFIRMATION_SQL, (command.email,))
                                    name, timezone_name = _confirmation_facts(cursor.fetchall())
                            result = replace(
                                result,
                                customer_name=name,
                                restaurant_timezone=timezone_name,
                                database_ms=_milliseconds(self._clock() - database_started),
                            )
                        except Exception as confirmation_error:
                            primary_error = confirmation_error
                            cleanup_failed = _close_unsafe(connection)
                            unsafe_disposal_failed = cleanup_failed
                            pending_error = ReservationConfirmationFailure(
                                pool_wait_ms=_milliseconds(acquired - started),
                                database_ms=_milliseconds(self._clock() - database_started),
                                cleanup_failed=cleanup_failed,
                            )
                    else:
                        result = replace(result, database_ms=_milliseconds(self._clock() - database_started))
            finally:
                if not unsafe_disposal_failed:
                    try:
                        self._pool.putconn(connection)
                    except Exception:
                        cleanup_failed = True
                        _close_unsafe(connection)
                        if pending_error is not None and hasattr(pending_error, "cleanup_failed"):
                            pending_error.cleanup_failed = True
                        elif result is not None:
                            result = replace(result, cleanup_failed=True)
            if pending_error is not None:
                raise pending_error from primary_error
            assert result is not None
            return result
        except (DatabaseContractError, DatabaseMutationFailure, ReservationConfirmationFailure):
            raise
        except Exception as error:
            translated = _failure(
                error, dispatched=dispatched, rollback_confirmed=not transaction_started and not committed,
                cleanup_failed=cleanup_failed,
                pool_wait_ms=_milliseconds((acquired if connection_acquired else self._clock()) - started),
                database_ms=_milliseconds(self._clock() - database_started) if connection_acquired else 0.0,
            )
            raise translated from error
