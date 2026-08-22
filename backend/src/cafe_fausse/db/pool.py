"""Bounded Psycopg pool construction and application-role enforcement."""

from __future__ import annotations

from psycopg import Connection
from psycopg.pq import TransactionStatus
from psycopg_pool import ConnectionPool

from ..config import Settings

APPLICATION_ROLE = "cafe_fausse_app"
APPLICATION_NAME = "cafe_fausse_api"


def configure_session(connection: Connection[object]) -> None:
    try:
        with connection.cursor() as cursor:
            cursor.execute("SET SESSION application_name = 'cafe_fausse_api'")
            cursor.execute("SET ROLE cafe_fausse_app")
            cursor.execute("SELECT current_user")
            row = cursor.fetchone()
        if row is None or row[0] != APPLICATION_ROLE:
            raise RuntimeError("application role enforcement failed")
        connection.commit()
    except Exception:
        connection.close()
        raise


def check_session(connection: Connection[object]) -> None:
    ConnectionPool.check_connection(connection)
    if connection.info.transaction_status != TransactionStatus.IDLE:
        connection.close()
        raise RuntimeError("pooled session is not idle")
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT current_user")
            row = cursor.fetchone()
        connection.commit()
        if row is None or row[0] != APPLICATION_ROLE:
            raise RuntimeError("pooled session has the wrong role")
    except Exception:
        connection.close()
        raise


def create_pool(settings: Settings) -> ConnectionPool[Connection[object]]:
    kwargs = settings.connection_kwargs()
    kwargs["application_name"] = APPLICATION_NAME
    return ConnectionPool(
        conninfo="",
        kwargs=kwargs,
        min_size=settings.pool_min_size,
        max_size=settings.pool_max_size,
        timeout=settings.pool_acquire_timeout_ms / 1000,
        configure=configure_session,
        check=check_session,
        open=False,
        name="cafe-fausse",
    )
