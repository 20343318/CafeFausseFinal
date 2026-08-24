"""PostgreSQL routine adapter for OP-02."""

from __future__ import annotations

from datetime import datetime, timedelta
from time import monotonic
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from psycopg_pool import ConnectionPool

from ..services.results import AvailabilityOutcome, AvailabilityRequest, AvailabilitySlot, ReservationAvailabilityResult
from .exceptions import DatabaseContractError, translate_read_exception

_TIMEZONE_SELECT = "SELECT restaurant_timezone FROM cafe_fausse.reservation_configuration WHERE configuration_id = 1"
_AVAILABILITY_SELECT = """
SELECT outcome, detail_code, local_start, starts_at, ends_at, available
FROM cafe_fausse.provisional_availability(%s, %s)
"""


class ReservationAvailabilityGateway:
    def __init__(self, pool: ConnectionPool, *, acquire_timeout_ms: int, clock=monotonic) -> None:
        self._pool = pool
        self._acquire_timeout_seconds = acquire_timeout_ms / 1000
        self._clock = clock

    def get_availability(self, request: AvailabilityRequest, timeout_seconds: float | None = None) -> ReservationAvailabilityResult:
        started = self._clock()
        deadline = started + (timeout_seconds if timeout_seconds is not None else self._acquire_timeout_seconds)
        acquired = started
        database_started = started
        connection_acquired = False
        try:
            remaining = deadline - self._clock()
            if remaining <= 0:
                raise TimeoutError()
            with self._pool.connection(timeout=min(self._acquire_timeout_seconds, remaining)) as connection:
                acquired = self._clock()
                database_started = acquired
                connection_acquired = True
                remaining_ms = int((deadline - self._clock()) * 1000)
                if remaining_ms < 1:
                    raise TimeoutError()
                with connection.transaction():
                    with connection.cursor() as cursor:
                        cursor.execute("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY")
                        cursor.execute("SELECT set_config('statement_timeout', %s, true)", (f"{remaining_ms}ms",))
                        cursor.execute(_TIMEZONE_SELECT)
                        timezone_rows = cursor.fetchall()
                        cursor.execute(_AVAILABILITY_SELECT, (request.local_date, request.party_size))
                        rows = cursor.fetchall()
        except Exception as error:
            finished = self._clock()
            pool_wait_ms = round(max(0.0, acquired - started) * 1000, 3)
            database_ms = round(max(0.0, finished - database_started) * 1000, 3) if connection_acquired else 0.0
            raise translate_read_exception(error, connection_acquired=connection_acquired, pool_wait_ms=pool_wait_ms, database_ms=database_ms) from error

        finished = self._clock()
        pool_wait_ms = round(max(0.0, acquired - started) * 1000, 3)
        database_ms = round(max(0.0, finished - database_started) * 1000, 3)
        try:
            if len(timezone_rows) != 1 or len(timezone_rows[0]) != 1 or not isinstance(timezone_rows[0][0], str):
                raise ValueError()
            timezone = timezone_rows[0][0]
            zone = ZoneInfo(timezone)
            if len(rows) == 1 and rows[0][:2] == ("invalid_request", "date_or_party_size_out_of_range") and all(value is None for value in rows[0][2:]):
                return ReservationAvailabilityResult(AvailabilityOutcome.INVALID_REQUEST, request, pool_wait_ms=pool_wait_ms, database_ms=database_ms)
            if len(rows) == 1 and rows[0][0] == "invalid_database_configuration":
                detail = rows[0][1]
                if detail not in {"incomplete_foundation_population", "invalid_timezone"} or any(value is not None for value in rows[0][2:]):
                    raise ValueError()
                raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
            slots: list[AvailabilitySlot] = []
            previous: datetime | None = None
            for row in rows:
                if len(row) != 6 or row[0] != "slots" or row[1] is not None:
                    raise ValueError()
                local_start, starts_at, ends_at, available = row[2:]
                if not isinstance(local_start, datetime) or local_start.tzinfo is not None or not isinstance(starts_at, datetime) or starts_at.tzinfo is None or not isinstance(ends_at, datetime) or ends_at.tzinfo is None or local_start.microsecond != 0 or starts_at.microsecond != 0 or ends_at.microsecond != 0 or type(available) is not bool:
                    raise ValueError()
                if (
                    local_start.date() != request.local_date
                    or ends_at - starts_at not in {timedelta(minutes=60), timedelta(minutes=90), timedelta(minutes=120)}
                    or (previous is not None and starts_at <= previous)
                ):
                    raise ValueError()
                if starts_at.astimezone(zone).replace(tzinfo=None) != local_start:
                    raise ValueError()
                previous = starts_at
                slots.append(AvailabilitySlot(local_start, starts_at, ends_at, available))
        except DatabaseContractError:
            raise
        except (ValueError, TypeError, ZoneInfoNotFoundError) as error:
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms) from error
        return ReservationAvailabilityResult(AvailabilityOutcome.SLOTS, request, timezone, tuple(slots), pool_wait_ms, database_ms)
