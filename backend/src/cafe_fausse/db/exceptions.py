"""Safe database exception categories and OP-03 read translation."""

from __future__ import annotations

from psycopg import InterfaceError, OperationalError
from psycopg_pool import PoolTimeout


class DatabaseUnavailable(Exception):
    """A dependency failure safe to expose only as a coarse category."""

    def __init__(
        self,
        *,
        sqlstate: str | None = None,
        safe_to_retry: bool,
        pool_wait_ms: float = 0.0,
        database_ms: float = 0.0,
    ) -> None:
        super().__init__("database unavailable")
        self.sqlstate = sqlstate
        self.safe_to_retry = safe_to_retry
        self.pool_wait_ms = pool_wait_ms
        self.database_ms = database_ms


class DatabaseContractError(Exception):
    """The frozen PostgreSQL contract is not usable."""

    def __init__(self, *, pool_wait_ms: float = 0.0, database_ms: float = 0.0) -> None:
        super().__init__("database contract failure")
        self.pool_wait_ms = pool_wait_ms
        self.database_ms = database_ms


_READ_RETRY_SQLSTATES = frozenset({"55P03", "40P01", "40001"})


def translate_read_exception(
    error: Exception,
    *,
    connection_acquired: bool,
    pool_wait_ms: float,
    database_ms: float,
) -> DatabaseUnavailable | DatabaseContractError:
    """Classify one failed read without retaining driver text or request values."""
    sqlstate_value = getattr(error, "sqlstate", None)
    sqlstate = sqlstate_value if isinstance(sqlstate_value, str) else None
    if sqlstate in _READ_RETRY_SQLSTATES or (
        sqlstate is not None and sqlstate.startswith("08")
    ):
        return DatabaseUnavailable(
            sqlstate=sqlstate,
            safe_to_retry=True,
            pool_wait_ms=pool_wait_ms,
            database_ms=database_ms,
        )
    if sqlstate == "57014":
        return DatabaseUnavailable(
            sqlstate=sqlstate,
            safe_to_retry=False,
            pool_wait_ms=pool_wait_ms,
            database_ms=database_ms,
        )
    if isinstance(error, TimeoutError):
        return DatabaseUnavailable(
            sqlstate=sqlstate,
            safe_to_retry=False,
            pool_wait_ms=pool_wait_ms,
            database_ms=database_ms,
        )
    if not connection_acquired or isinstance(error, (InterfaceError, OperationalError, PoolTimeout)):
        return DatabaseUnavailable(
            sqlstate=sqlstate,
            safe_to_retry=True,
            pool_wait_ms=pool_wait_ms,
            database_ms=database_ms,
        )
    return DatabaseContractError(pool_wait_ms=pool_wait_ms, database_ms=database_ms)
