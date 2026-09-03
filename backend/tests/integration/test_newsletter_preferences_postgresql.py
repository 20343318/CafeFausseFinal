from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from dataclasses import replace
import os
import time
from uuid import uuid4

import psycopg
from psycopg.errors import InsufficientPrivilege, OperationalError
from psycopg.pq import TransactionStatus
import pytest

from cafe_fausse.application import close_resources, create_app
from cafe_fausse.config import Settings
from cafe_fausse.db.newsletter_gateway import NewsletterGateway, _PREFERENCE_SQL
from cafe_fausse.db.pool import create_pool
from cafe_fausse.services.newsletter_preferences import (
    NewsletterPreferenceOutcomeUnknown,
    NewsletterPreferenceService,
    NewsletterPreferenceTemporaryFailure,
)
from cafe_fausse.services.results import NewsletterPreferenceCommand
from cafe_fausse.services.retry import RetryPolicy


def _settings(*, mutation_deadline_ms=15000, pool_max_size=5) -> Settings:
    values = {
        "CAFE_FAUSSE_ENVIRONMENT": "test",
        "PGHOST": os.environ["PGHOST"],
        "PGPORT": os.environ.get("PGPORT", "5432"),
        "PGDATABASE": os.environ["PGDATABASE"],
        "PGUSER": os.environ["PGUSER"],
        "PGCONNECT_TIMEOUT": "1",
        "CAFE_FAUSSE_POOL_MIN_SIZE": "1",
        "CAFE_FAUSSE_POOL_MAX_SIZE": str(pool_max_size),
        "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS": "500",
        "CAFE_FAUSSE_MUTATION_DEADLINE_MS": str(mutation_deadline_ms),
        "CAFE_FAUSSE_RETRY_MIN_REMAINING_MS": "500",
    }
    if os.environ.get("PGPASSWORD"):
        values["PGPASSWORD"] = os.environ["PGPASSWORD"]
    if os.environ.get("PGPASSFILE"):
        values["PGPASSFILE"] = os.environ["PGPASSFILE"]
    return Settings.from_environment(values)


def _connection_values(user):
    values = {
        "host": os.environ["PGHOST"],
        "port": int(os.environ.get("PGPORT", "5432")),
        "dbname": os.environ["PGDATABASE"],
        "user": user,
    }
    if os.environ.get("PGPASSFILE"):
        values["passfile"] = os.environ["PGPASSFILE"]
    elif user == os.environ.get("CAFE_FAUSSE_TEST_MANAGER_USER") and os.environ.get(
        "CAFE_FAUSSE_TEST_MANAGER_PASSWORD"
    ):
        values["password"] = os.environ["CAFE_FAUSSE_TEST_MANAGER_PASSWORD"]
    elif os.environ.get("PGPASSWORD"):
        values["password"] = os.environ["PGPASSWORD"]
    return values


def _manager_connect():
    user = os.environ["CAFE_FAUSSE_TEST_MANAGER_USER"]
    if not os.environ.get("PGPASSFILE") and not os.environ.get(
        "CAFE_FAUSSE_TEST_MANAGER_PASSWORD"
    ):
        pytest.fail("API-06 integration tests require test-manager credentials")
    return psycopg.connect(**_connection_values(user))


def _request(client, email, subscribed, **overrides):
    payload = {
        "first_name": "Ada",
        "last_name": "Rivera",
        "email": email,
        "confirmation_email": email,
        "subscribed": subscribed,
    }
    payload.update(overrides)
    return client.post("/api/v1/newsletter-preferences", json=payload)


def _customer_row(connection, email):
    return connection.execute(
        "SELECT customer_id, first_name, middle_initial, last_name, email, phone, "
        "newsletter_subscribed FROM cafe_fausse.customers WHERE email = %s",
        (email,),
    ).fetchone()


@contextmanager
def _owned_customer(
    connection,
    *,
    email,
    first_name="Ada",
    middle_initial=None,
    last_name="Rivera",
    phone=None,
    subscribed=False,
    reservation=False,
):
    assert _customer_row(connection, email) is None
    inserted = connection.execute(
        "INSERT INTO cafe_fausse.customers"
        "(first_name,middle_initial,last_name,email,phone,newsletter_subscribed) "
        "VALUES (%s,%s,%s,%s,%s,%s) RETURNING customer_id",
        (first_name, middle_initial, last_name, email, phone, subscribed),
    ).fetchone()
    assert inserted is not None
    customer_id = inserted[0]
    reservation_id = None
    if reservation:
        reserved = connection.execute(
            "INSERT INTO cafe_fausse.reservations"
            "(customer_id,starts_at,ends_at,party_size,reservation_fingerprint) "
            "VALUES (%s, date_trunc('hour', CURRENT_TIMESTAMP) + interval '100 days', "
            "date_trunc('hour', CURRENT_TIMESTAMP) + interval '100 days 90 minutes', "
            "2, decode(md5(%s), 'hex')) RETURNING reservation_id",
            (customer_id, email),
        ).fetchone()
        assert reserved is not None
        reservation_id = reserved[0]
        connection.execute(
            "INSERT INTO cafe_fausse.reservation_table_assignments"
            "(reservation_id,table_number) VALUES (%s,1)",
            (reservation_id,),
        )
    connection.commit()
    try:
        yield customer_id, reservation_id
    finally:
        connection.rollback()
        if reservation_id is not None:
            connection.execute(
                "DELETE FROM cafe_fausse.reservation_table_assignments "
                "WHERE reservation_id = %s",
                (reservation_id,),
            )
            connection.execute(
                "DELETE FROM cafe_fausse.reservations "
                "WHERE reservation_id = %s AND customer_id = %s",
                (reservation_id, customer_id),
            )
        connection.execute(
            "DELETE FROM cafe_fausse.customers WHERE customer_id = %s AND email = %s",
            (customer_id, email),
        )
        connection.commit()
        assert _customer_row(connection, email) is None


def _cleanup_created_customer(connection, email, customer_id):
    connection.rollback()
    connection.execute(
        "DELETE FROM cafe_fausse.customers WHERE customer_id = %s AND email = %s",
        (customer_id, email),
    )
    connection.commit()
    assert _customer_row(connection, email) is None


def _wait_for_advisory_waiters(connection, lock_key, expected, timeout=5.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        count = connection.execute(
            "SELECT count(*) FROM pg_catalog.pg_locks "
            "WHERE locktype = 'advisory' AND classid = 1128678733::oid "
            "AND objid = (%s::integer)::oid AND NOT granted",
            (lock_key,),
        ).fetchone()[0]
        connection.commit()
        if count >= expected:
            return
        time.sleep(0.025)
    pytest.fail(f"Did not observe {expected} API-06 advisory-lock waiters")


class _InjectedOperationalError(OperationalError):
    def __init__(self, sqlstate):
        self._injected_sqlstate = sqlstate
        super().__init__("test-only injected dependency boundary")

    @property
    def sqlstate(self):
        return self._injected_sqlstate


class _InstrumentedCursor:
    def __init__(self, lease, cursor):
        self._lease = lease
        self._cursor = cursor

    def __enter__(self):
        self._cursor.__enter__()
        return self

    def __exit__(self, exc_type, exc, traceback):
        return self._cursor.__exit__(exc_type, exc, traceback)

    def execute(self, statement, params=None):
        if (
            self._lease.plan == "pre_dispatch_loss"
            and statement == "SELECT set_config('statement_timeout', %s, true)"
        ):
            self._lease.pre_dispatch_failure = True
            raise _InjectedOperationalError("08006")
        if statement == _PREFERENCE_SQL:
            self._lease.routine_boundary_reached = True
            if self._lease.plan in {"55P03", "40P01", "40001"}:
                raise _InjectedOperationalError(self._lease.plan)
            self._lease.routine_forwarded = True
        return self._cursor.execute(statement, params)

    def fetchall(self):
        rows = self._cursor.fetchall()
        if self._lease.plan == "result_loss_confirmed_rollback":
            raise _InjectedOperationalError("08006")
        if self._lease.plan == "result_connection_loss":
            self._lease.raw.close()
            raise _InjectedOperationalError("08006")
        return rows


class _InstrumentedLease:
    def __init__(self, raw, plan):
        self.raw = raw
        self.plan = plan
        self.entered_idle = raw.info.transaction_status == TransactionStatus.IDLE
        self.exit_exception = None
        self.exit_status = None
        self.pre_dispatch_failure = False
        self.routine_boundary_reached = False
        self.routine_forwarded = False
        self.close_calls = 0

    def __enter__(self):
        self.raw.__enter__()
        return self

    def __exit__(self, exc_type, exc, traceback):
        self.exit_exception = exc
        if self.plan == "commit_ack_loss" and exc_type is None:
            self.raw.__exit__(exc_type, exc, traceback)
            self.exit_status = self.raw.info.transaction_status
            raise _InjectedOperationalError("08006")
        if self.plan == "result_connection_loss" and exc_type is not None:
            try:
                self.raw.__exit__(exc_type, exc, traceback)
            finally:
                self.exit_status = self.raw.info.transaction_status
            raise _InjectedOperationalError("08006")
        try:
            return self.raw.__exit__(exc_type, exc, traceback)
        finally:
            self.exit_status = self.raw.info.transaction_status

    def cursor(self):
        return _InstrumentedCursor(self, self.raw.cursor())

    def close(self):
        self.close_calls += 1
        self.raw.close()


class _InstrumentedPool:
    def __init__(self, settings, plans):
        self._pool = create_pool(settings)
        self._pool.open(wait=True)
        self._plans = list(plans)
        self.leases = []
        self.returned = []

    def getconn(self, *, timeout):
        raw = self._pool.getconn(timeout=timeout)
        plan = self._plans.pop(0) if self._plans else None
        lease = _InstrumentedLease(raw, plan)
        self.leases.append(lease)
        return lease

    def putconn(self, lease):
        self.returned.append(lease)
        self._pool.putconn(lease.raw)

    def close(self):
        self._pool.close(timeout=2.0)


def _instrumented_service(pool, *, deadline_ms=15000, monotonic=time.monotonic, sleeper=None):
    return NewsletterPreferenceService(
        NewsletterGateway(pool, acquire_timeout_ms=500),
        deadline_ms=deadline_ms,
        retry_policy=RetryPolicy(3, 25, 200, 0.0, 500),
        monotonic=monotonic,
        sleeper=sleeper or (lambda _seconds: None),
        uniform=lambda _low, _high: 1.0,
    )


def _command(email, subscribed=True):
    return NewsletterPreferenceCommand("Ada", None, "Rivera", email, subscribed)


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_op04_new_subscribe_creates_once_and_repeats_idempotently():
    email = f"api06-new-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        assert _customer_row(manager, email) is None
        app = create_app(_settings())
        try:
            client = app.test_client()
            first = _request(client, email, True, first_name="  Ada  ")
            second = _request(client, email.upper(), True, first_name="Ada")
            row = _customer_row(manager, email)
            assert row is not None
            customer_id = row[0]
            assert first.status_code == second.status_code == 200
            assert first.get_json() == second.get_json() == {
                "result": "set",
                "subscribed": True,
            }
            assert row[1:] == ("Ada", None, "Rivera", email, None, True)
            assert manager.execute(
                "SELECT count(*) FROM cafe_fausse.customers WHERE email = %s", (email,)
            ).fetchone() == (1,)
            assert manager.execute(
                "SELECT count(*) FROM information_schema.tables "
                "WHERE table_schema = 'cafe_fausse' "
                "AND table_name ILIKE '%subscriber%'"
            ).fetchone() == (0,)
            assert manager.execute(
                "SELECT count(*) FROM information_schema.columns "
                "WHERE table_schema = 'cafe_fausse' "
                "AND column_name = 'confirmation_email'"
            ).fetchone() == (0,)
        finally:
            close_resources(app)
        _cleanup_created_customer(manager, email, customer_id)


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_op04_new_unsubscribe_creates_no_customer():
    email = f"api06-no-change-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        app = create_app(_settings())
        try:
            response = _request(app.test_client(), email, False)
        finally:
            close_resources(app)
        assert response.status_code == 200
        assert response.get_json() == {
            "result": "no_customer_no_change",
            "subscribed": False,
        }
        assert _customer_row(manager, email) is None


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_op04_existing_transitions_preserve_identity_phone_and_reservation():
    email = f"api06-existing-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _owned_customer(
            manager,
            email=email,
            middle_initial="M",
            phone="+1 (202) 555-0198",
            subscribed=True,
            reservation=True,
        ) as (customer_id, reservation_id):
            before_customer = _customer_row(manager, email)
            before_reservation = manager.execute(
                "SELECT * FROM cafe_fausse.reservations WHERE reservation_id = %s",
                (reservation_id,),
            ).fetchone()
            before_assignment = manager.execute(
                "SELECT * FROM cafe_fausse.reservation_table_assignments "
                "WHERE reservation_id = %s",
                (reservation_id,),
            ).fetchall()
            app = create_app(_settings())
            try:
                client = app.test_client()
                unsubscribed = _request(
                    client, email, False, middle_initial="m"
                )
                repeated = _request(client, email, False, middle_initial="M")
                subscribed = _request(client, email, True, middle_initial="M")
            finally:
                close_resources(app)
            assert unsubscribed.get_json() == repeated.get_json() == {
                "result": "set",
                "subscribed": False,
            }
            assert subscribed.get_json() == {"result": "set", "subscribed": True}
            after_customer = _customer_row(manager, email)
            assert after_customer[:-1] == before_customer[:-1]
            assert after_customer[-1] is True
            assert after_customer[0] == customer_id
            assert manager.execute(
                "SELECT * FROM cafe_fausse.reservations WHERE reservation_id = %s",
                (reservation_id,),
            ).fetchone() == before_reservation
            assert manager.execute(
                "SELECT * FROM cafe_fausse.reservation_table_assignments "
                "WHERE reservation_id = %s",
                (reservation_id,),
            ).fetchall() == before_assignment


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.parametrize(
    ("overrides", "code"),
    [
        ({"first_name": "Other", "middle_initial": "M"}, "customer_identity_conflict"),
        ({"middle_initial": "Q"}, "middle_initial_conflict"),
    ],
)
def test_it_dbapi_op04_conflicts_change_nothing(overrides, code):
    email = f"api06-conflict-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _owned_customer(
            manager,
            email=email,
            middle_initial="M",
            phone="202-555-0198",
            subscribed=False,
        ):
            before = _customer_row(manager, email)
            app = create_app(_settings())
            try:
                response = _request(app.test_client(), email, True, **overrides)
            finally:
                close_resources(app)
            assert response.status_code == 409
            assert response.get_json()["error"]["code"] == code
            assert _customer_row(manager, email) == before


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.concurrency
def test_it_dbapi_op04_concurrent_same_identity_create_is_one_customer():
    email = f"api06-concurrent-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        assert _customer_row(manager, email) is None
        app = create_app(_settings(pool_max_size=5))
        try:
            def submit(_index):
                return _request(app.test_client(), email, True)

            with ThreadPoolExecutor(max_workers=5) as executor:
                responses = list(executor.map(submit, range(5)))
            assert all(response.status_code == 200 for response in responses)
            assert all(
                response.get_json() == {"result": "set", "subscribed": True}
                for response in responses
            )
            row = _customer_row(manager, email)
            assert row is not None
            customer_id = row[0]
            assert manager.execute(
                "SELECT count(*) FROM cafe_fausse.customers WHERE email = %s", (email,)
            ).fetchone() == (1,)
        finally:
            close_resources(app)
        _cleanup_created_customer(manager, email, customer_id)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.concurrency
def test_it_dbapi_op04_controlled_opposing_writes_are_last_commit_wins():
    email = f"api06-last-commit-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _owned_customer(manager, email=email, subscribed=False):
            lock_key = manager.execute(
                "SELECT cafe_fausse.canonical_email_lock_key(%s)", (email,)
            ).fetchone()[0]
            manager.execute("SELECT pg_catalog.pg_advisory_lock(1128678733, %s)", (lock_key,))
            manager.commit()
            app = create_app(_settings(pool_max_size=3))
            executor = ThreadPoolExecutor(max_workers=2)
            try:
                first = executor.submit(_request, app.test_client(), email, True)
                _wait_for_advisory_waiters(manager, lock_key, 1)
                second = executor.submit(_request, app.test_client(), email, False)
                _wait_for_advisory_waiters(manager, lock_key, 2)
                manager.execute(
                    "SELECT pg_catalog.pg_advisory_unlock(1128678733, %s)", (lock_key,)
                )
                manager.commit()
                first_response = first.result(timeout=10)
                second_response = second.result(timeout=10)
            finally:
                manager.execute(
                    "SELECT pg_catalog.pg_advisory_unlock(1128678733, %s)", (lock_key,)
                )
                manager.commit()
                executor.shutdown(wait=True, cancel_futures=True)
                close_resources(app)
            assert first_response.get_json() == {"result": "set", "subscribed": True}
            assert second_response.get_json() == {"result": "set", "subscribed": False}
            assert _customer_row(manager, email)[-1] is False


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.concurrency
def test_it_dbapi_op04_concurrent_identity_conflict_never_overwrites():
    email = f"api06-concurrent-conflict-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        with _owned_customer(manager, email=email, first_name="Ada", subscribed=False):
            before = _customer_row(manager, email)
            app = create_app(_settings(pool_max_size=3))
            try:
                with ThreadPoolExecutor(max_workers=2) as executor:
                    exact = executor.submit(_request, app.test_client(), email, True)
                    conflict = executor.submit(
                        _request,
                        app.test_client(),
                        email,
                        True,
                        first_name="Other",
                    )
                    exact_response = exact.result(timeout=10)
                    conflict_response = conflict.result(timeout=10)
            finally:
                close_resources(app)
            assert exact_response.get_json() == {"result": "set", "subscribed": True}
            assert conflict_response.status_code == 409
            assert conflict_response.get_json()["error"]["code"] == "customer_identity_conflict"
            after = _customer_row(manager, email)
            assert after[1:-1] == before[1:-1]
            assert after[-1] is True


@pytest.mark.integration
@pytest.mark.postgres
def test_it_dbapi_op04_app_role_routine_succeeds_but_direct_dml_is_denied():
    email = f"api06-privilege-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        app = create_app(_settings())
        try:
            response = _request(app.test_client(), email, True)
            row = _customer_row(manager, email)
            assert row is not None
            customer_id = row[0]
        finally:
            close_resources(app)
        with psycopg.connect(**_connection_values(os.environ["PGUSER"])) as app_connection:
            app_connection.execute("SET ROLE cafe_fausse_app")
            with pytest.raises(InsufficientPrivilege):
                app_connection.execute(
                    "UPDATE cafe_fausse.customers SET newsletter_subscribed = false "
                    "WHERE email = %s",
                    (email,),
                )
            app_connection.rollback()
        assert response.get_json() == {"result": "set", "subscribed": True}
        assert _customer_row(manager, email)[-1] is True
        _cleanup_created_customer(manager, email, customer_id)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_known_lock_timeout_is_temporary_and_nonmutating():
    email = f"api06-lock-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        app = create_app(_settings(mutation_deadline_ms=3000))
        try:
            manager.execute("LOCK TABLE cafe_fausse.customers IN ACCESS EXCLUSIVE MODE")
            response = _request(app.test_client(), email, True)
        finally:
            manager.rollback()
            close_resources(app)
        assert response.status_code == 503
        assert response.get_json()["error"] == {
            "code": "temporary_failure",
            "message": "The newsletter preference could not be processed right now. Please retry shortly.",
            "retryable": True,
            "outcome_unknown": False,
        }
        assert _customer_row(manager, email) is None


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_controlled_no_dispatch_failure_mutates_nothing():
    email = f"api06-no-dispatch-{uuid4().hex}@example.test"
    app = create_app(_settings())
    dependencies = app.extensions["cafe_fausse"]

    class NoDispatchService:
        def set_preference(self, _command):
            raise NewsletterPreferenceTemporaryFailure(0.0, 0.0, 1)

    app.extensions["cafe_fausse"] = replace(
        dependencies, newsletter_preference_service=NoDispatchService()
    )
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        before = _customer_row(manager, email)
        try:
            response = _request(app.test_client(), email, True)
        finally:
            close_resources(app)
        assert response.status_code == 503
        assert response.get_json()["error"]["code"] == "temporary_failure"
        assert _customer_row(manager, email) == before is None


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_ambiguous_completion_resubmission_converges():
    email = f"api06-ambiguous-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        assert _customer_row(manager, email) is None
        app = create_app(_settings())
        dependencies = app.extensions["cafe_fausse"]
        original = dependencies.newsletter_preference_service

        class LoseCommittedResponse:
            def set_preference(self, command):
                result = original.set_preference(command)
                raise NewsletterPreferenceOutcomeUnknown(
                    result.pool_wait_ms, result.database_ms, result.attempts
                )

        app.extensions["cafe_fausse"] = replace(
            dependencies, newsletter_preference_service=LoseCommittedResponse()
        )
        try:
            unknown = _request(app.test_client(), email, True)
            row = _customer_row(manager, email)
            assert row is not None and row[-1] is True
            customer_id = row[0]
            app.extensions["cafe_fausse"] = dependencies
            repeated = _request(app.test_client(), email, True)
        finally:
            close_resources(app)
        assert unknown.status_code == 503
        assert unknown.get_json()["error"] == {
            "code": "newsletter_preference_outcome_unknown",
            "message": "The newsletter preference result could not be confirmed. Resubmit the same preference.",
            "retryable": True,
            "outcome_unknown": True,
        }
        assert repeated.get_json() == {"result": "set", "subscribed": True}
        assert _customer_row(manager, email)[0] == customer_id
        _cleanup_created_customer(manager, email, customer_id)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
@pytest.mark.parametrize("sqlstate", ["55P03", "40P01", "40001"])
def test_it_dbapi_op04_test_adapter_retries_approved_state_after_real_rollback(
    sqlstate,
):
    email = f"api06-state-{sqlstate.lower()}-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        assert _customer_row(manager, email) is None
        pool = _InstrumentedPool(_settings(pool_max_size=2), [sqlstate, sqlstate, None])
        try:
            result = _instrumented_service(pool).set_preference(_command(email))
            row = _customer_row(manager, email)
            assert row is not None and row[-1] is True
            customer_id = row[0]
        finally:
            pool.close()
        assert result.attempts == 3
        assert len(pool.leases) == len(pool.returned) == 3
        assert all(lease.entered_idle for lease in pool.leases)
        assert all(
            lease.exit_status == TransactionStatus.IDLE for lease in pool.leases
        )
        assert all(
            lease.routine_boundary_reached and not lease.routine_forwarded
            for lease in pool.leases[:2]
        )
        assert pool.leases[2].routine_forwarded is True
        _cleanup_created_customer(manager, email, customer_id)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_test_adapter_enforces_three_attempt_maximum_with_real_rollbacks():
    email = f"api06-max-attempts-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        pool = _InstrumentedPool(_settings(pool_max_size=2), ["40001"] * 4)
        try:
            with pytest.raises(NewsletterPreferenceTemporaryFailure) as raised:
                _instrumented_service(pool).set_preference(_command(email))
        finally:
            pool.close()
        assert raised.value.attempts == 3
        assert len(pool.leases) == len(pool.returned) == 3
        assert all(lease.entered_idle for lease in pool.leases)
        assert all(
            lease.exit_status == TransactionStatus.IDLE for lease in pool.leases
        )
        assert _customer_row(manager, email) is None


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_test_adapter_deadline_guard_prevents_second_real_lease():
    email = f"api06-deadline-guard-{uuid4().hex}@example.test"

    class DeadlineClock:
        now = 0.0

        def __call__(self):
            return self.now

        def sleep(self, seconds):
            self.now += seconds + 1.0

    clock = DeadlineClock()
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        pool = _InstrumentedPool(_settings(pool_max_size=2), ["55P03", None])
        try:
            service = _instrumented_service(
                pool,
                deadline_ms=1000,
                monotonic=clock,
                sleeper=clock.sleep,
            )
            with pytest.raises(NewsletterPreferenceTemporaryFailure):
                service.set_preference(_command(email))
        finally:
            pool.close()
        assert len(pool.leases) == len(pool.returned) == 1
        assert pool.leases[0].exit_status == TransactionStatus.IDLE
        assert _customer_row(manager, email) is None


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_test_adapter_pre_dispatch_loss_is_known_and_retryable():
    email = f"api06-pre-dispatch-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        pool = _InstrumentedPool(
            _settings(pool_max_size=2), ["pre_dispatch_loss", None]
        )
        try:
            result = _instrumented_service(pool).set_preference(_command(email))
            row = _customer_row(manager, email)
            assert row is not None and row[-1] is True
            customer_id = row[0]
        finally:
            pool.close()
        assert result.attempts == 2
        assert len(pool.leases) == len(pool.returned) == 2
        first = pool.leases[0]
        assert first.pre_dispatch_failure is True
        assert first.routine_boundary_reached is False
        assert first.exit_status == TransactionStatus.IDLE
        _cleanup_created_customer(manager, email, customer_id)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_test_adapter_result_loss_with_real_rollback_is_known():
    email = f"api06-result-known-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        pool = _InstrumentedPool(
            _settings(pool_max_size=1), ["result_loss_confirmed_rollback"]
        )
        try:
            with pytest.raises(NewsletterPreferenceTemporaryFailure) as raised:
                _instrumented_service(pool).set_preference(_command(email))
        finally:
            pool.close()
        assert raised.value.attempts == 1
        assert raised.value.cleanup_failed is False
        assert len(pool.leases) == len(pool.returned) == 1
        assert pool.leases[0].routine_forwarded is True
        assert pool.leases[0].exit_status == TransactionStatus.IDLE
        assert _customer_row(manager, email) is None


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_test_adapter_result_connection_loss_is_unknown_and_not_retried():
    email = f"api06-result-unknown-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        pool = _InstrumentedPool(
            _settings(pool_max_size=1), ["result_connection_loss", None]
        )
        service = _instrumented_service(pool)
        try:
            with pytest.raises(NewsletterPreferenceOutcomeUnknown) as raised:
                service.set_preference(_command(email))
            assert len(pool.leases) == len(pool.returned) == 1
            assert raised.value.attempts == 1
            assert raised.value.cleanup_failed is True
            assert _customer_row(manager, email) is None
            repeated = service.set_preference(_command(email))
            row = _customer_row(manager, email)
            assert row is not None and row[-1] is True
            customer_id = row[0]
        finally:
            pool.close()
        assert repeated.subscribed is True
        assert len(pool.leases) == len(pool.returned) == 2
        _cleanup_created_customer(manager, email, customer_id)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_test_adapter_lost_commit_ack_is_unknown_and_resubmits():
    email = f"api06-commit-unknown-{uuid4().hex}@example.test"
    with _manager_connect() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        manager.commit()
        pool = _InstrumentedPool(_settings(pool_max_size=1), ["commit_ack_loss", None])
        service = _instrumented_service(pool)
        try:
            with pytest.raises(NewsletterPreferenceOutcomeUnknown) as raised:
                service.set_preference(_command(email))
            row_after_unknown = _customer_row(manager, email)
            assert row_after_unknown is not None and row_after_unknown[-1] is True
            customer_id = row_after_unknown[0]
            assert raised.value.attempts == 1
            assert len(pool.leases) == len(pool.returned) == 1
            repeated = service.set_preference(_command(email))
        finally:
            pool.close()
        assert repeated.subscribed is True
        assert len(pool.leases) == len(pool.returned) == 2
        assert _customer_row(manager, email)[0] == customer_id
        _cleanup_created_customer(manager, email, customer_id)


@pytest.mark.integration
@pytest.mark.postgres
@pytest.mark.failure_injection
def test_it_dbapi_op04_controlled_programmer_workflow_failure():
    if os.environ.get("CAFE_FAUSSE_API06_INJECT_FAILURE") == "YES":
        pytest.fail("controlled API-06 programmer-workflow failure")
    assert os.environ.get("CAFE_FAUSSE_API06_INJECT_FAILURE") is None
