from __future__ import annotations

from contextlib import contextmanager
import os
from uuid import uuid4

import psycopg
import pytest

from cafe_fausse.application import close_resources, create_app
from cafe_fausse.config import Settings


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
        "CAFE_FAUSSE_READ_DEADLINE_MS": "2000",
        "CAFE_FAUSSE_RETRY_MIN_REMAINING_MS": "500",
    }
    if os.environ.get("PGPASSWORD"):
        values["PGPASSWORD"] = os.environ["PGPASSWORD"]
    if os.environ.get("PGPASSFILE"):
        values["PGPASSFILE"] = os.environ["PGPASSFILE"]
    return Settings.from_environment(values)


def _test_manager_connect():
    values = {
        "host": os.environ["PGHOST"],
        "port": int(os.environ.get("PGPORT", "5432")),
        "dbname": os.environ["PGDATABASE"],
        "user": os.environ["CAFE_FAUSSE_TEST_MANAGER_USER"],
    }
    if os.environ.get("PGPASSFILE"):
        values["passfile"] = os.environ["PGPASSFILE"]
    elif os.environ.get("CAFE_FAUSSE_TEST_MANAGER_PASSWORD"):
        values["password"] = os.environ["CAFE_FAUSSE_TEST_MANAGER_PASSWORD"]
    else:
        pytest.fail(
            "PostgreSQL integration tests require PGPASSFILE or "
            "CAFE_FAUSSE_TEST_MANAGER_PASSWORD"
        )
    return psycopg.connect(**values)


def _snapshot(connection):
    return (
        connection.execute(
            "SELECT customer_id, first_name, middle_initial, last_name, email, phone, "
            "newsletter_subscribed FROM cafe_fausse.customers ORDER BY customer_id"
        ).fetchall(),
        connection.execute(
            "SELECT reservation_id, customer_id, starts_at, ends_at, party_size "
            "FROM cafe_fausse.reservations ORDER BY reservation_id"
        ).fetchall(),
        connection.execute(
            "SELECT reservation_id, table_number FROM "
            "cafe_fausse.reservation_table_assignments ORDER BY reservation_id, table_number"
        ).fetchall(),
    )


@contextmanager
def _temporary_customer(
    connection,
    *,
    email,
    first_name="Ada",
    middle_initial=None,
    last_name="Rivera",
    phone=None,
    subscribed=False,
):
    existing = connection.execute(
        "SELECT count(*) FROM cafe_fausse.customers WHERE email = %s", (email,)
    ).fetchone()
    assert existing == (0,)
    inserted = connection.execute(
        "INSERT INTO cafe_fausse.customers"
        "(first_name,middle_initial,last_name,email,phone,newsletter_subscribed) "
        "VALUES (%s,%s,%s,%s,%s,%s) RETURNING customer_id",
        (first_name, middle_initial, last_name, email, phone, subscribed),
    ).fetchone()
    assert inserted is not None
    customer_id = inserted[0]
    connection.commit()
    try:
        yield
    finally:
        connection.rollback()
        connection.execute(
            "DELETE FROM cafe_fausse.customers WHERE customer_id = %s AND email = %s",
            (customer_id, email),
        )
        connection.commit()
        remaining = connection.execute(
            "SELECT count(*) FROM cafe_fausse.customers WHERE email = %s", (email,)
        ).fetchone()
        assert remaining == (0,)


def _unused_email(connection, label, candidates=()):
    for email in (*candidates, *(f"api05-{label}-{uuid4().hex}@example.test" for _ in range(5))):
        existing = connection.execute(
            "SELECT count(*) FROM cafe_fausse.customers WHERE email = %s", (email,)
        ).fetchone()
        if existing == (0,):
            return email
    pytest.fail("Could not select an unused API-05-owned integration email")


def _lookup(client, **overrides):
    payload = {
        "first_name": "Ada",
        "last_name": "Rivera",
        "email": "api05-integration@example.test",
        "confirmation_email": "api05-integration@example.test",
    }
    payload.update(overrides)
    return client.post("/api/v1/newsletter-status-queries", json=payload)


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_op03_new_customer_lookup_is_read_only():
    """IT-DBAPI-OP03-001: an absent canonical email returns not-found without mutation."""
    with _test_manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        email = _unused_email(manager, "not-found")
        before = _snapshot(manager)
        app = create_app(_settings())
        try:
            response = _lookup(
                app.test_client(), email=email, confirmation_email=email
            )
        finally:
            close_resources(app)
        assert response.status_code == 200
        assert response.get_json() == {"status": "not_found"}
        assert _snapshot(manager) == before


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_op03_setup_preserves_and_skips_preexisting_email_collision():
    """IT-DBAPI-OP03-007: lookup setup never deletes or adopts an existing collision."""
    collision = f"api05-collision-{uuid4().hex}@example.test"
    replacement = f"api05-replacement-{uuid4().hex}@example.test"
    with _test_manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _temporary_customer(
            manager,
            email=collision,
            first_name="Ada",
            last_name="Rivera",
            subscribed=True,
        ):
            before = _snapshot(manager)
            selected = _unused_email(
                manager, "collision", candidates=(collision, replacement)
            )
            assert selected == replacement
            app = create_app(_settings())
            try:
                response = _lookup(
                    app.test_client(), email=selected, confirmation_email=selected
                )
            finally:
                close_resources(app)
            assert response.status_code == 200
            assert response.get_json() == {"status": "not_found"}
            assert manager.execute(
                "SELECT first_name, last_name, newsletter_subscribed "
                "FROM cafe_fausse.customers WHERE email = %s",
                (collision,),
            ).fetchone() == ("Ada", "Rivera", True)
            assert _snapshot(manager) == before


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.parametrize(
    ("fixture", "request_overrides", "status", "body"),
    [
        ({"subscribed": True}, {}, 200, {"status": "matched", "subscribed": True}),
        ({"subscribed": False}, {}, 200, {"status": "matched", "subscribed": False}),
        ({"phone": None}, {}, 200, {"status": "matched", "subscribed": False}),
        ({"middle_initial": "M"}, {}, 200, {"status": "matched", "subscribed": False}),
        ({"middle_initial": None}, {"middle_initial": "M."}, 200, {"status": "matched", "subscribed": False}),
        ({}, {"first_name": "Other"}, 409, "customer_identity_conflict"),
        ({}, {"last_name": "Other"}, 409, "customer_identity_conflict"),
        ({"middle_initial": "M"}, {"middle_initial": "Q"}, 409, "middle_initial_conflict"),
        (
            {"first_name": "Ada María", "last_name": "de Rivera", "subscribed": True},
            {
                "first_name": "  ADA   MARÍA ",
                "last_name": " DE   RIVERA ",
                "email": " API05-INTEGRATION@EXAMPLE.TEST ",
                "confirmation_email": "api05-integration@example.test",
            },
            200,
            {"status": "matched", "subscribed": True},
        ),
    ],
)
def test_it_dbapi_op03_existing_identity_outcomes_are_read_only(
    fixture, request_overrides, status, body
):
    """IT-DBAPI-OP03-002: real customer outcomes preserve every business row."""
    email = "api05-integration@example.test"
    with _test_manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _temporary_customer(manager, email=email, **fixture):
            before = _snapshot(manager)
            app = create_app(_settings())
            try:
                response = _lookup(app.test_client(), **request_overrides)
            finally:
                close_resources(app)
            assert response.status_code == status
            if status == 200:
                assert response.get_json() == body
            else:
                assert response.get_json()["error"]["code"] == body
                assert "Ada" not in response.get_data(as_text=True)
            assert _snapshot(manager) == before


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_op03_confirmation_is_transient_and_invalid_request_does_not_query():
    """IT-DBAPI-OP03-003: confirmation is neither persisted nor returned."""
    email = "api05-integration@example.test"
    with _test_manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _temporary_customer(manager, email=email, subscribed=True):
            before = _snapshot(manager)
            app = create_app(_settings())
            try:
                client = app.test_client()
                valid = _lookup(client)
                invalid = _lookup(client, confirmation_email="different@example.test")
            finally:
                close_resources(app)
            assert valid.status_code == 200
            assert invalid.status_code == 422
            assert "confirmation" not in valid.get_data(as_text=True)
            assert "different@example.test" not in invalid.get_data(as_text=True)
            assert _snapshot(manager) == before


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op03_locked_read_is_indeterminate_and_cleanup_preserves_state():
    """IT-DBAPI-OP03-004: a controlled blocked read is generic and nonmutating."""
    email = "api05-integration@example.test"
    with _test_manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _temporary_customer(manager, email=email, subscribed=True):
            before = _snapshot(manager)
            app = create_app(_settings())
            try:
                manager.execute("LOCK TABLE cafe_fausse.customers IN ACCESS EXCLUSIVE MODE")
                response = _lookup(app.test_client())
            finally:
                manager.rollback()
                close_resources(app)
            assert response.status_code == 503
            assert response.get_json()["error"] == {
                "code": "newsletter_status_indeterminate",
                "message": "Newsletter status could not be checked right now. You may retry, or continue a booking without changing it.",
                "retryable": True,
                "outcome_unknown": False,
            }
            assert _snapshot(manager) == before


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op03_owned_fixture_cleans_after_injected_test_exception():
    """IT-DBAPI-OP03-005: fixture cleanup executes after a controlled test-body failure."""
    owned = "api05-owned-failure@example.test"
    preserved = "api05-preexisting-preserved@example.test"
    with _test_manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _temporary_customer(manager, email=preserved, first_name="Preserved"):
            with pytest.raises(RuntimeError, match="controlled API-05 test failure"):
                with _temporary_customer(manager, email=owned):
                    raise RuntimeError("controlled API-05 test failure")
            assert manager.execute(
                "SELECT count(*) FROM cafe_fausse.customers WHERE email = %s", (owned,)
            ).fetchone() == (0,)
            assert manager.execute(
                "SELECT first_name FROM cafe_fausse.customers WHERE email = %s", (preserved,)
            ).fetchone() == ("Preserved",)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op03_controlled_programmer_workflow_failure():
    """IT-DBAPI-OP03-006: opt-in failure proves outer harness cleanup/restart behavior."""
    if os.environ.get("CAFE_FAUSSE_API05_INJECT_FAILURE") == "YES":
        pytest.fail("controlled API-05 programmer-workflow failure")
    assert os.environ.get("CAFE_FAUSSE_API05_INJECT_FAILURE") is None
