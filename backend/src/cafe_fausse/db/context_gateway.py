"""Coherent PostgreSQL snapshot adapter for OP-01."""

from __future__ import annotations

from datetime import date, time
from time import monotonic
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from psycopg_pool import ConnectionPool

from ..services.results import ReservationContextResult, WeekdayHours
from .exceptions import DatabaseContractError, translate_read_exception

_CONTEXT_SELECT = """
SELECT start_interval_minutes, reservation_duration_minutes,
       advance_booking_window_days, same_day_lead_minutes, restaurant_timezone,
       (CURRENT_TIMESTAMP AT TIME ZONE restaurant_timezone)::date,
       ((CURRENT_TIMESTAMP AT TIME ZONE restaurant_timezone)::date
          + advance_booking_window_days)::date,
       (SELECT count(*) FROM cafe_fausse.restaurant_tables),
       (SELECT sum(seating_capacity) FROM cafe_fausse.restaurant_tables),
       (SELECT count(*) FROM cafe_fausse.restaurant_tables
         WHERE seating_capacity <= 0)
FROM cafe_fausse.reservation_configuration
WHERE configuration_id = 1
"""
_HOURS_SELECT = """
SELECT weekday, opens_at, closes_at
FROM cafe_fausse.restaurant_operating_hours
ORDER BY weekday
"""


class ReservationContextGateway:
    def __init__(self, pool: ConnectionPool, *, acquire_timeout_ms: int, clock=monotonic) -> None:
        self._pool = pool
        self._acquire_timeout_seconds = acquire_timeout_ms / 1000
        self._clock = clock

    def get_context(self, timeout_seconds: float | None = None) -> ReservationContextResult:
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
                        cursor.execute(_CONTEXT_SELECT)
                        configurations = cursor.fetchall()
                        cursor.execute(_HOURS_SELECT)
                        hours = cursor.fetchall()
        except Exception as error:
            finished = self._clock()
            pool_wait_ms = round(max(0.0, acquired - started) * 1000, 3)
            database_ms = round(max(0.0, finished - database_started) * 1000, 3) if connection_acquired else 0.0
            raise translate_read_exception(error, connection_acquired=connection_acquired, pool_wait_ms=pool_wait_ms, database_ms=database_ms) from error

        finished = self._clock()
        pool_wait_ms = round(max(0.0, acquired - started) * 1000, 3)
        database_ms = round(max(0.0, finished - database_started) * 1000, 3)
        try:
            if len(configurations) != 1 or len(hours) != 7:
                raise ValueError()
            row = configurations[0]
            if len(row) != 10:
                raise ValueError()
            interval, duration, window, lead, timezone, minimum, maximum, table_count, capacity, nonpositive_capacity_count = row
            if (
                type(interval) is not int or interval not in {15, 30, 60}
                or type(duration) is not int or duration not in {60, 90, 120}
                or type(window) is not int or not 1 <= window <= 365
                or type(lead) is not int or not 0 <= lead <= 1440
                or not isinstance(timezone, str)
                or not isinstance(minimum, date) or not isinstance(maximum, date)
                or maximum != minimum.fromordinal(minimum.toordinal() + window)
                or table_count != 30 or nonpositive_capacity_count != 0
                or type(capacity) is not int or capacity < 1
            ):
                raise ValueError()
            ZoneInfo(timezone)
            parsed_hours: list[WeekdayHours] = []
            for expected, hour in enumerate(hours, 1):
                if len(hour) != 3 or type(hour[0]) is not int or hour[0] != expected or not isinstance(hour[1], time) or not isinstance(hour[2], time) or hour[1].tzinfo is not None or hour[2].tzinfo is not None or hour[1].microsecond != 0 or hour[2].microsecond != 0 or hour[1] >= hour[2]:
                    raise ValueError()
                parsed_hours.append(WeekdayHours(expected, hour[1], hour[2]))
        except (ValueError, TypeError, ZoneInfoNotFoundError) as error:
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms) from error
        return ReservationContextResult(timezone, tuple(parsed_hours), interval, duration, window, lead, minimum, maximum, capacity, pool_wait_ms, database_ms)
