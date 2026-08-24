"""Certainty-aware PostgreSQL adapter for OP-04."""

from __future__ import annotations

from dataclasses import replace
from time import monotonic

from psycopg import InterfaceError, OperationalError, ProgrammingError
from psycopg_pool import ConnectionPool, PoolTimeout

from ..services.results import (
    NewsletterPreferenceCommand,
    NewsletterPreferenceOutcome,
    NewsletterPreferenceResult,
)
from .exceptions import (
    DatabaseContractError,
    DatabaseMutationFailure,
    mutation_sqlstate,
)

_PREFERENCE_SQL = """
SELECT outcome, newsletter_subscribed
FROM cafe_fausse.set_newsletter_preference(%s, %s, %s, %s, %s)
"""
_RETRYABLE_SQLSTATES = frozenset({"55P03", "40P01", "40001"})
_OUTCOME_MAP = {
    "subscribed": NewsletterPreferenceOutcome.SUBSCRIBED,
    "unsubscribed": NewsletterPreferenceOutcome.UNSUBSCRIBED,
    "no_customer_no_change": NewsletterPreferenceOutcome.NO_CUSTOMER_NO_CHANGE,
    "invalid_request": NewsletterPreferenceOutcome.INVALID_REQUEST,
    "customer_identity_mismatch": NewsletterPreferenceOutcome.CUSTOMER_IDENTITY_CONFLICT,
    "middle_initial_conflict": NewsletterPreferenceOutcome.MIDDLE_INITIAL_CONFLICT,
}


def _milliseconds(seconds: float) -> float:
    return round(max(0.0, seconds) * 1000, 3)


def _close_unsafe(connection: object) -> bool:
    try:
        connection.close()
        return False
    except Exception:
        return True


def _mutation_failure(
    error: Exception,
    *,
    dispatched: bool,
    rollback_confirmed: bool,
    cleanup_failed: bool,
    pool_wait_ms: float,
    database_ms: float,
) -> DatabaseMutationFailure | DatabaseContractError:
    if isinstance(error, DatabaseContractError) and rollback_confirmed:
        error.cleanup_failed = error.cleanup_failed or cleanup_failed
        return error
    sqlstate = mutation_sqlstate(error)
    outcome_unknown = dispatched and not rollback_confirmed
    if (
        rollback_confirmed
        and isinstance(error, ProgrammingError)
        and sqlstate not in _RETRYABLE_SQLSTATES
    ):
        return DatabaseContractError(
            pool_wait_ms=pool_wait_ms,
            database_ms=database_ms,
            cleanup_failed=cleanup_failed,
        )
    safe_to_retry = (
        not outcome_unknown
        and rollback_confirmed
        and (
            not dispatched
            and isinstance(error, (InterfaceError, OperationalError, PoolTimeout))
            or dispatched and sqlstate in _RETRYABLE_SQLSTATES
        )
    )
    return DatabaseMutationFailure(
        sqlstate=sqlstate,
        safe_to_retry=safe_to_retry,
        mutation_dispatched=dispatched,
        outcome_unknown=outcome_unknown,
        pool_wait_ms=pool_wait_ms,
        database_ms=database_ms,
        cleanup_failed=cleanup_failed,
    )


def _decode_result(rows: object, pool_wait_ms: float, database_ms: float) -> NewsletterPreferenceResult:
    if not isinstance(rows, list) or len(rows) != 1:
        raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    row = rows[0]
    if not isinstance(row, (tuple, list)) or len(row) != 2:
        raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    outcome_text, subscribed = row
    if not isinstance(outcome_text, str) or outcome_text not in _OUTCOME_MAP:
        raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    outcome = _OUTCOME_MAP[outcome_text]
    success_outcomes = {
        NewsletterPreferenceOutcome.SUBSCRIBED,
        NewsletterPreferenceOutcome.UNSUBSCRIBED,
        NewsletterPreferenceOutcome.NO_CUSTOMER_NO_CHANGE,
    }
    conflict_outcomes = {
        NewsletterPreferenceOutcome.CUSTOMER_IDENTITY_CONFLICT,
        NewsletterPreferenceOutcome.MIDDLE_INITIAL_CONFLICT,
    }
    if outcome in success_outcomes:
        if type(subscribed) is not bool:
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    elif outcome in conflict_outcomes and type(subscribed) is not bool:
        raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    elif outcome is NewsletterPreferenceOutcome.INVALID_REQUEST and subscribed is not None:
        raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
    public_state = subscribed if outcome in success_outcomes else None
    try:
        return NewsletterPreferenceResult(outcome, public_state, pool_wait_ms, database_ms)
    except ValueError as error:
        raise DatabaseContractError(
            pool_wait_ms=pool_wait_ms,
            database_ms=database_ms,
        ) from error


class NewsletterGateway:
    def __init__(
        self,
        pool: ConnectionPool,
        *,
        acquire_timeout_ms: int,
        clock=monotonic,
    ) -> None:
        self._pool = pool
        self._acquire_timeout_seconds = acquire_timeout_ms / 1000
        self._clock = clock

    def set_preference(
        self,
        command: NewsletterPreferenceCommand,
        timeout_seconds: float | None = None,
    ) -> NewsletterPreferenceResult:
        started = self._clock()
        deadline = started + (
            timeout_seconds if timeout_seconds is not None else self._acquire_timeout_seconds
        )
        acquired = started
        database_started = started
        connection_acquired = False
        connection = None
        transaction_started = False
        dispatched = False
        body_completed = False
        primary_error: Exception | None = None
        pending_error: Exception | None = None
        cleanup_failed = False
        unsafe_disposal_failed = False
        try:
            remaining = deadline - self._clock()
            if remaining <= 0:
                raise TimeoutError()
            connection = self._pool.getconn(
                timeout=min(self._acquire_timeout_seconds, remaining)
            )
            try:
                acquired = self._clock()
                database_started = acquired
                connection_acquired = True
                try:
                    with connection:
                        try:
                            remaining_ms = int((deadline - self._clock()) * 1000)
                            if remaining_ms < 1:
                                raise TimeoutError()
                            with connection.cursor() as cursor:
                                cursor.execute("BEGIN ISOLATION LEVEL READ COMMITTED")
                                transaction_started = True
                                cursor.execute(
                                    "SELECT set_config('statement_timeout', %s, true)",
                                    (f"{remaining_ms}ms",),
                                )
                                if (deadline - self._clock()) * 1000 < 1:
                                    raise TimeoutError()
                                dispatched = True
                                cursor.execute(
                                    _PREFERENCE_SQL,
                                    (
                                        command.first_name,
                                        command.middle_initial,
                                        command.last_name,
                                        command.email,
                                        command.subscribed,
                                    ),
                                )
                                rows = cursor.fetchall()
                                now = self._clock()
                                pool_wait_ms = _milliseconds(acquired - started)
                                database_ms = _milliseconds(now - database_started)
                                result = _decode_result(rows, pool_wait_ms, database_ms)
                                if (deadline - self._clock()) * 1000 < 1:
                                    raise TimeoutError()
                            body_completed = True
                        except Exception as operation_error:
                            primary_error = operation_error
                            raise
                except Exception as context_error:
                    if primary_error is None:
                        primary_error = context_error
                    rollback_confirmed = (
                        not body_completed and context_error is primary_error
                    )
                    if not body_completed and context_error is not primary_error:
                        cleanup_failed = True
                    if body_completed or (dispatched and not rollback_confirmed):
                        close_failed = _close_unsafe(connection)
                        unsafe_disposal_failed = close_failed
                        cleanup_failed = cleanup_failed or close_failed
                    now = self._clock()
                    pending_error = _mutation_failure(
                        primary_error,
                        dispatched=dispatched,
                        rollback_confirmed=rollback_confirmed,
                        cleanup_failed=cleanup_failed,
                        pool_wait_ms=_milliseconds(acquired - started),
                        database_ms=_milliseconds(now - database_started),
                    )
                else:
                    transaction_started = False
                    finished = self._clock()
                    pending_error = None
                    result = NewsletterPreferenceResult(
                        result.outcome,
                        result.subscribed,
                        pool_wait_ms,
                        _milliseconds(finished - database_started),
                    )
            except Exception as error:
                if primary_error is None:
                    primary_error = error
                pending_error = error
            finally:
                if unsafe_disposal_failed:
                    if isinstance(
                        pending_error,
                        (DatabaseContractError, DatabaseMutationFailure),
                    ):
                        pending_error.cleanup_failed = True
                else:
                    try:
                        self._pool.putconn(connection)
                    except Exception:
                        cleanup_failed = True
                        _close_unsafe(connection)
                        if isinstance(
                            pending_error,
                            (DatabaseContractError, DatabaseMutationFailure),
                        ):
                            pending_error.cleanup_failed = True
                        elif pending_error is None:
                            result = replace(result, cleanup_failed=True)
            if pending_error is not None:
                raise pending_error from primary_error
            return result
        except (DatabaseContractError, DatabaseMutationFailure):
            raise
        except Exception as error:
            now = self._clock()
            pool_wait_ms = (
                _milliseconds(acquired - started)
                if connection_acquired
                else _milliseconds(now - started)
            )
            database_ms = (
                _milliseconds(now - database_started) if connection_acquired else 0.0
            )
            translated = _mutation_failure(
                error,
                dispatched=dispatched,
                rollback_confirmed=not transaction_started,
                cleanup_failed=cleanup_failed,
                pool_wait_ms=pool_wait_ms,
                database_ms=database_ms,
            )
            raise translated from error
