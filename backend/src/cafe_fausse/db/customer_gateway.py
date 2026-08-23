"""Narrow read-only PostgreSQL adapter for OP-03."""

from __future__ import annotations

from time import monotonic

from psycopg_pool import ConnectionPool

from ..services.results import CustomerIdentity, NewsletterStatusOutcome, NewsletterStatusResult
from .exceptions import DatabaseContractError, translate_read_exception

_CUSTOMER_SELECT = """
SELECT first_name, middle_initial, last_name, newsletter_subscribed
FROM cafe_fausse.customers
WHERE email = %s
"""


class CustomerGateway:
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

    def get_newsletter_status(
        self,
        identity: CustomerIdentity,
        timeout_seconds: float | None = None,
    ) -> NewsletterStatusResult:
        started = self._clock()
        deadline = started + (
            timeout_seconds if timeout_seconds is not None else self._acquire_timeout_seconds
        )
        acquired = started
        database_started = started
        connection_acquired = False
        try:
            remaining = deadline - self._clock()
            if remaining <= 0:
                raise TimeoutError()
            with self._pool.connection(
                timeout=min(self._acquire_timeout_seconds, remaining)
            ) as connection:
                acquired = self._clock()
                database_started = acquired
                connection_acquired = True
                remaining_ms = int((deadline - self._clock()) * 1000)
                if remaining_ms < 1:
                    raise TimeoutError()
                with connection.transaction():
                    with connection.cursor() as cursor:
                        cursor.execute("SET TRANSACTION READ ONLY")
                        cursor.execute(
                            "SELECT set_config('statement_timeout', %s, true)",
                            (f"{remaining_ms}ms",),
                        )
                        cursor.execute(_CUSTOMER_SELECT, (identity.email,))
                        rows = cursor.fetchall()
        except Exception as error:
            finished = self._clock()
            pool_wait_ms = round(max(0.0, acquired - started) * 1000, 3)
            database_ms = (
                round(max(0.0, finished - database_started) * 1000, 3)
                if connection_acquired
                else 0.0
            )
            raise translate_read_exception(
                error,
                connection_acquired=connection_acquired,
                pool_wait_ms=pool_wait_ms,
                database_ms=database_ms,
            ) from error

        finished = self._clock()
        pool_wait_ms = round(max(0.0, acquired - started) * 1000, 3)
        database_ms = round(max(0.0, finished - database_started) * 1000, 3)
        if len(rows) > 1:
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
        if not rows:
            return NewsletterStatusResult(
                NewsletterStatusOutcome.NOT_FOUND,
                pool_wait_ms=pool_wait_ms,
                database_ms=database_ms,
            )
        row = rows[0]
        if (
            len(row) != 4
            or not isinstance(row[0], str)
            or row[1] is not None and not isinstance(row[1], str)
            or not isinstance(row[2], str)
            or type(row[3]) is not bool
        ):
            raise DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
        stored_first, stored_middle, stored_last, subscribed = row
        if (
            stored_first.casefold() != identity.first_name.casefold()
            or stored_last.casefold() != identity.last_name.casefold()
        ):
            outcome = NewsletterStatusOutcome.CUSTOMER_IDENTITY_CONFLICT
        elif (
            identity.middle_initial is not None
            and stored_middle is not None
            and stored_middle.casefold() != identity.middle_initial.casefold()
        ):
            outcome = NewsletterStatusOutcome.MIDDLE_INITIAL_CONFLICT
        else:
            return NewsletterStatusResult(
                NewsletterStatusOutcome.MATCHED,
                subscribed,
                pool_wait_ms,
                database_ms,
            )
        return NewsletterStatusResult(
            outcome,
            pool_wait_ms=pool_wait_ms,
            database_ms=database_ms,
        )
