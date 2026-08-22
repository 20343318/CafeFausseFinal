from __future__ import annotations

import importlib.metadata as metadata
import os
from pathlib import Path
import subprocess
import time

import psycopg
import pytest

from cafe_fausse.application import close_resources, create_app
from cafe_fausse.config import Settings, require_formal_acceptance_platform


def _settings() -> Settings:
    values = {
        "CAFE_FAUSSE_ENVIRONMENT": "test",
        "PGHOST": os.environ["PGHOST"],
        "PGPORT": os.environ.get("PGPORT", "5432"),
        "PGDATABASE": os.environ["PGDATABASE"],
        "PGUSER": os.environ["PGUSER"],
        "PGCONNECT_TIMEOUT": "1",
        "CAFE_FAUSSE_POOL_MIN_SIZE": "1",
        "CAFE_FAUSSE_POOL_MAX_SIZE": "2",
        "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS": "500",
        "CAFE_FAUSSE_READINESS_DEADLINE_MS": "1000",
    }
    if os.environ.get("PGPASSWORD"):
        values["PGPASSWORD"] = os.environ["PGPASSWORD"]
    if os.environ.get("PGPASSFILE"):
        values["PGPASSFILE"] = os.environ["PGPASSFILE"]
    return Settings.from_environment(values)


def _test_manager_connect():
    connection_values = {
        "host": os.environ["PGHOST"],
        "port": int(os.environ.get("PGPORT", "5432")),
        "dbname": os.environ["PGDATABASE"],
        "user": os.environ["CAFE_FAUSSE_TEST_MANAGER_USER"],
    }
    if os.environ.get("PGPASSFILE"):
        connection_values["passfile"] = os.environ["PGPASSFILE"]
    elif os.environ.get("CAFE_FAUSSE_TEST_MANAGER_PASSWORD"):
        connection_values["password"] = os.environ[
            "CAFE_FAUSSE_TEST_MANAGER_PASSWORD"
        ]
    else:
        pytest.fail(
            "PostgreSQL integration tests require either PGPASSFILE or "
            "CAFE_FAUSSE_TEST_MANAGER_PASSWORD for external test management"
        )
    return psycopg.connect(
        **connection_values,
    )


def _wait_ready(client, attempts=30):
    for _ in range(attempts):
        response = client.get("/api/v1/health/readiness")
        if response.status_code == 200:
            return response
        time.sleep(0.1)
    return response


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.acceptance
def test_it_dbapi_found_platform_dependencies_and_ready_contract():
    """IT-DBAPI-FOUND-001: formal platform, versions, imports, role, contract, and population."""
    evidence = require_formal_acceptance_platform()
    assert evidence.version == (3, 14, 6)
    assert {
        "Flask": metadata.version("Flask"),
        "psycopg": metadata.version("psycopg"),
        "psycopg-binary": metadata.version("psycopg-binary"),
        "psycopg-pool": metadata.version("psycopg-pool"),
        "pytest": metadata.version("pytest"),
        "pytest-cov": metadata.version("pytest-cov"),
    } == {
        "Flask": "3.1.3",
        "psycopg": "3.2.13",
        "psycopg-binary": "3.2.13",
        "psycopg-pool": "3.2.8",
        "pytest": "9.1.1",
        "pytest-cov": "7.1.0",
    }
    settings = _settings()
    app = create_app(settings)
    try:
        response = _wait_ready(app.test_client())
        assert response.status_code == 200
        assert response.get_json() == {"status": "ready"}
        pool = app.extensions["cafe_fausse"].resource
        with pool.connection(timeout=1) as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT current_user, current_setting('server_version_num')::integer, "
                    "(SELECT NOT rolsuper AND NOT rolcreatedb AND NOT rolcreaterole FROM pg_catalog.pg_roles WHERE rolname=session_user)"
                )
                assert cursor.fetchone() == ("cafe_fausse_app", 180003, True)
            connection.commit()
    finally:
        close_resources(app)


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_found_privilege_denials_and_nonmutation():
    """IT-DBAPI-FOUND-002: runtime reads only foundation and cannot bypass controlled operations."""
    app = create_app(_settings())
    try:
        pool = app.extensions["cafe_fausse"].resource
        with pool.connection(timeout=1) as connection:
            for statement in (
                "INSERT INTO cafe_fausse.customers(first_name,last_name,email) VALUES ('Denied','User','denied@example.com')",
                "SELECT count(*) FROM cafe_fausse.reservations",
                "DELETE FROM cafe_fausse.restaurant_tables",
                "CREATE TABLE cafe_fausse.forbidden(value integer)",
                "SELECT * FROM cafe_fausse.select_table_allocation(ARRAY[1]::smallint[], ARRAY[4], 4, 1)",
            ):
                with pytest.raises(psycopg.Error):
                    with connection.transaction():
                        connection.execute(statement)
        with _test_manager_connect() as admin:
            admin.execute("SET ROLE cafe_fausse_test")
            counts = admin.execute(
                "SELECT (SELECT count(*) FROM cafe_fausse.customers),"
                " (SELECT count(*) FROM cafe_fausse.reservations),"
                " (SELECT count(*) FROM cafe_fausse.reservation_table_assignments)"
            ).fetchone()
            assert counts == (0, 0, 0)
    finally:
        close_resources(app)


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_found_controlled_foundation_failure_is_generic_and_restored():
    """IT-DBAPI-FOUND-003: external test authority controls/restores a missing foundation fact."""
    settings = _settings()
    app = create_app(settings)
    client = app.test_client()
    try:
        assert _wait_ready(client).status_code == 200
        with _test_manager_connect() as admin:
            admin.execute("SET ROLE cafe_fausse_test")
            admin.execute("DELETE FROM cafe_fausse.restaurant_operating_hours WHERE weekday = 7")
            admin.commit()
        failed = client.get("/api/v1/health/readiness")
        assert failed.status_code == 503
        assert failed.get_json() == {
            "error": {
                "code": "service_not_ready",
                "message": "The service is not ready.",
                "retryable": True,
                "outcome_unknown": False,
            }
        }
    finally:
        with _test_manager_connect() as admin:
            admin.execute("SET ROLE cafe_fausse_test")
            admin.execute(
                "INSERT INTO cafe_fausse.restaurant_operating_hours(weekday,opens_at,closes_at) "
                "VALUES (7, TIME '17:00', TIME '21:00') ON CONFLICT (weekday) DO UPDATE "
                "SET opens_at=EXCLUDED.opens_at, closes_at=EXCLUDED.closes_at"
            )
            admin.commit()
        assert _wait_ready(client).status_code == 200
        close_resources(app)


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_life_unavailable_construction_liveness_and_bounded_close():
    """IT-DBAPI-LIFE-001: temporary outage does not prevent construction or liveness."""
    unavailable = Settings.from_environment(
        {
            "CAFE_FAUSSE_ENVIRONMENT": "test",
            "PGHOST": "127.0.0.1",
            "PGPORT": "55999",
            "PGDATABASE": "cafe_fausse_test_unavailable",
            "PGUSER": "deployment_login",
            "PGCONNECT_TIMEOUT": "1",
            "CAFE_FAUSSE_POOL_MIN_SIZE": "0",
            "CAFE_FAUSSE_POOL_MAX_SIZE": "1",
            "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS": "100",
            "CAFE_FAUSSE_READINESS_DEADLINE_MS": "150",
            "CAFE_FAUSSE_POOL_CLOSE_TIMEOUT_MS": "100",
        }
    )
    app = create_app(unavailable)
    try:
        client = app.test_client()
        assert client.get("/api/v1/health/liveness").status_code == 200
        assert client.get("/api/v1/health/readiness").status_code == 503
    finally:
        close_resources(app)
        close_resources(app)


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_life_repeated_factory_close_cycles():
    """IT-DBAPI-LIFE-002: repeated process-resource cycles remain usable and leak-free."""
    for _ in range(3):
        app = create_app(_settings())
        try:
            assert _wait_ready(app.test_client()).status_code == 200
        finally:
            close_resources(app)


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_life_transaction_rollback_and_wrong_role_discard():
    """IT-DBAPI-LIFE-003: rollback returns idle; a wrong-role lease is discarded."""
    app = create_app(_settings())
    try:
        pool = app.extensions["cafe_fausse"].resource
        with pool.connection(timeout=1) as connection:
            with pytest.raises(RuntimeError, match="forced rollback"):
                with connection.transaction():
                    connection.execute("SELECT 1")
                    raise RuntimeError("forced rollback")
            assert connection.info.transaction_status == psycopg.pq.TransactionStatus.IDLE
            connection.execute("RESET ROLE")
            connection.commit()
        with pool.connection(timeout=2) as replacement:
            assert replacement.execute("SELECT current_user").fetchone() == ("cafe_fausse_app",)
            replacement.commit()
    finally:
        close_resources(app)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
@pytest.mark.slow
def test_it_dbapi_life_background_recovery_after_database_start():
    """IT-DBAPI-LIFE-004: construct while down, stay live, then recover readiness."""
    pgdata_text = os.environ.get("CAFE_FAUSSE_TEST_PGDATA")
    if not pgdata_text:
        pytest.fail("CAFE_FAUSSE_TEST_PGDATA is required for formal recovery evidence")
    pgdata = Path(pgdata_text).resolve()
    expected_parent = Path(os.environ["TEMP"]).resolve()
    if expected_parent not in pgdata.parents:
        pytest.fail("Recovery test PGDATA must be inside the system temporary directory")
    pg_ctl = Path(r"C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe")
    port = int(os.environ["PGPORT"])
    with _test_manager_connect() as admin:
        assert admin.execute("SELECT current_database(), current_setting('server_version_num')::integer").fetchone() == (
            os.environ["PGDATABASE"],
            180003,
        )
    subprocess.run([str(pg_ctl), "-D", str(pgdata), "-m", "fast", "-w", "stop"], check=True)
    app = None
    started = False
    try:
        app = create_app(_settings())
        client = app.test_client()
        assert client.get("/api/v1/health/liveness").status_code == 200
        assert client.get("/api/v1/health/readiness").status_code == 503
        log_file = pgdata.parent / "postgres.log"
        subprocess.run(
            [str(pg_ctl), "-D", str(pgdata), "-l", str(log_file), "-o", f"-p {port} -h 127.0.0.1", "-w", "start"],
            check=True,
        )
        started = True
        assert _wait_ready(client, attempts=50).status_code == 200
    finally:
        if not started:
            subprocess.run(
                [str(pg_ctl), "-D", str(pgdata), "-l", str(pgdata.parent / "postgres.log"), "-o", f"-p {port} -h 127.0.0.1", "-w", "start"],
                check=True,
            )
        if app is not None:
            close_resources(app)
