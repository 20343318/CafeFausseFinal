"""One-lease, read-only implementation of the frozen readiness contract."""

from __future__ import annotations

from time import monotonic

from psycopg_pool import ConnectionPool

from ..services.health import ReadinessProbeFailure
from ..services.results import ReadinessCategory


_READINESS_SQL = """
SELECT
    current_setting('server_version_num')::integer = 180003 AS platform_ok,
    current_user = 'cafe_fausse_app'
      AND EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pgcrypto')
      AND has_schema_privilege(current_user, 'cafe_fausse', 'USAGE')
      AND has_function_privilege(current_user, 'cafe_fausse.provisional_availability(date,integer)', 'EXECUTE')
      AND has_function_privilege(current_user, 'cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)', 'EXECUTE')
      AND has_function_privilege(current_user, 'cafe_fausse.book_reservation(text,text,text,text,text,timestamp without time zone,smallint,integer,text)', 'EXECUTE')
      AND has_table_privilege(current_user, 'cafe_fausse.customers', 'SELECT')
      AND has_table_privilege(current_user, 'cafe_fausse.reservation_configuration', 'SELECT')
      AND has_table_privilege(current_user, 'cafe_fausse.restaurant_operating_hours', 'SELECT')
      AND has_table_privilege(current_user, 'cafe_fausse.restaurant_tables', 'SELECT') AS contract_ok,
    (SELECT count(*) >= 0 FROM cafe_fausse.customers) AS customers_readable,
    (SELECT count(*) = 1
       AND bool_and(configuration_id = 1
         AND start_interval_minutes IN (15, 30, 60)
         AND reservation_duration_minutes IN (60, 90, 120)
         AND advance_booking_window_days BETWEEN 1 AND 365
         AND same_day_lead_minutes BETWEEN 0 AND 1440
         AND EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names
                     WHERE name = restaurant_timezone))
       FROM cafe_fausse.reservation_configuration) AS configuration_ok,
    (SELECT count(*) = 7 AND count(DISTINCT weekday) = 7
       AND min(weekday) = 1 AND max(weekday) = 7
       AND bool_and(opens_at < closes_at)
       FROM cafe_fausse.restaurant_operating_hours) AS hours_ok,
    (SELECT count(*) = 30 AND bool_and(table_number > 0 AND seating_capacity > 0)
       FROM cafe_fausse.restaurant_tables) AS tables_ok
"""


class PsycopgHealthGateway:
    def __init__(self, pool: ConnectionPool, clock=monotonic) -> None:
        self._pool = pool
        self._clock = clock

    def check_readiness(self, deadline_ms: int) -> tuple[float, float]:
        started = self._clock()
        deadline = started + deadline_ms / 1000
        acquired = started
        database_started = started
        try:
            remaining = deadline - self._clock()
            if remaining <= 0:
                raise ReadinessProbeFailure(ReadinessCategory.POOL)
            with self._pool.connection(timeout=remaining) as connection:
                acquired = self._clock()
                database_started = acquired
                remaining_ms = int((deadline - self._clock()) * 1000)
                if remaining_ms <= 0:
                    raise ReadinessProbeFailure(ReadinessCategory.POOL)
                with connection.transaction():
                    with connection.cursor() as cursor:
                        cursor.execute("SET TRANSACTION READ ONLY")
                        cursor.execute("SELECT set_config('statement_timeout', %s, true)", (f"{remaining_ms}ms",))
                        cursor.execute(_READINESS_SQL)
                        row = cursor.fetchone()
        except ReadinessProbeFailure:
            raise
        except Exception as exc:
            now = self._clock()
            raise ReadinessProbeFailure(
                ReadinessCategory.POOL,
                round(max(0.0, acquired - started) * 1000, 3),
                round(max(0.0, now - database_started) * 1000, 3) if acquired != started else 0.0,
            ) from exc
        finished = self._clock()
        pool_wait_ms = round(max(0.0, acquired - started) * 1000, 3)
        database_ms = round(max(0.0, finished - database_started) * 1000, 3)
        if row is None or len(row) != 6:
            raise ReadinessProbeFailure(ReadinessCategory.CONTRACT, pool_wait_ms, database_ms)
        if row[0] is not True:
            raise ReadinessProbeFailure(ReadinessCategory.PLATFORM, pool_wait_ms, database_ms)
        if row[1] is not True:
            raise ReadinessProbeFailure(ReadinessCategory.CONTRACT, pool_wait_ms, database_ms)
        if not all(value is True for value in row[2:]):
            raise ReadinessProbeFailure(ReadinessCategory.FOUNDATION, pool_wait_ms, database_ms)
        return pool_wait_ms, database_ms
