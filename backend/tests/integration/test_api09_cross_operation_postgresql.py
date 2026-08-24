from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from datetime import date
import os
from uuid import uuid4

import psycopg
import pytest

from cafe_fausse.application import close_resources, create_app
from cafe_fausse.config import Settings


pytestmark = [pytest.mark.integration, pytest.mark.postgres]


def _settings() -> Settings:
    values = {
        "CAFE_FAUSSE_ENVIRONMENT": "test",
        "PGHOST": os.environ["PGHOST"],
        "PGPORT": os.environ.get("PGPORT", "5432"),
        "PGDATABASE": os.environ["PGDATABASE"],
        "PGUSER": os.environ["PGUSER"],
        "PGCONNECT_TIMEOUT": "1",
        "CAFE_FAUSSE_POOL_MIN_SIZE": "1",
        "CAFE_FAUSSE_POOL_MAX_SIZE": "8",
        "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS": "1000",
        "CAFE_FAUSSE_MUTATION_DEADLINE_MS": "15000",
        "CAFE_FAUSSE_RETRY_MIN_REMAINING_MS": "500",
    }
    if os.environ.get("PGPASSFILE"):
        values["PGPASSFILE"] = os.environ["PGPASSFILE"]
    return Settings.from_environment(values)


def _manager():
    values = {
        "host": os.environ["PGHOST"],
        "port": int(os.environ["PGPORT"]),
        "dbname": os.environ["PGDATABASE"],
        "user": os.environ["CAFE_FAUSSE_TEST_MANAGER_USER"],
    }
    if os.environ.get("PGPASSFILE"):
        values["passfile"] = os.environ["PGPASSFILE"]
    return psycopg.connect(**values)


def _identity(email: str) -> dict:
    return {
        "first_name": "API09",
        "last_name": "CrossOperation",
        "email": email,
        "confirmation_email": email,
    }


def _slots(client, party_size: int = 4) -> list[dict]:
    context = client.get("/api/v1/reservation-context").get_json()
    requested = date.fromisoformat(
        context["reservable_date_range"]["maximum_local_date"]
    )
    response = client.get(
        f"/api/v1/reservation-availability?local_date={requested}&party_size={party_size}"
    )
    assert response.status_code == 200
    return [slot for slot in response.get_json()["slots"] if slot["available"]]


def _booking(email: str, slot: dict, party_size: int = 4, action: str = "no_change") -> dict:
    return _identity(email) | {
        "phone": "+1 (202) 555-0198",
        "starts_at_local": slot["starts_at_local"],
        "utc_offset_minutes": slot["utc_offset_minutes"],
        "party_size": party_size,
        "newsletter_action": action,
    }


def _cleanup(emails: set[str]) -> None:
    with _manager() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        ids = [
            row[0]
            for row in manager.execute(
                "SELECT customer_id FROM cafe_fausse.customers WHERE email = ANY(%s)",
                (list(emails),),
            ).fetchall()
        ]
        if ids:
            reservation_ids = [
                row[0]
                for row in manager.execute(
                    "SELECT reservation_id FROM cafe_fausse.reservations WHERE customer_id = ANY(%s)",
                    (ids,),
                ).fetchall()
            ]
            if reservation_ids:
                manager.execute(
                    "DELETE FROM cafe_fausse.reservation_table_assignments WHERE reservation_id = ANY(%s)",
                    (reservation_ids,),
                )
                manager.execute(
                    "DELETE FROM cafe_fausse.reservations WHERE reservation_id = ANY(%s)",
                    (reservation_ids,),
                )
            manager.execute(
                "DELETE FROM cafe_fausse.customers WHERE customer_id = ANY(%s)",
                (ids,),
            )
        manager.commit()


def test_newsletter_signup_then_reservation_reuses_and_enriches_one_customer() -> None:
    email = f"api09-signup-book-{uuid4().hex}@example.test"
    app = create_app(_settings())
    try:
        client = app.test_client()
        subscribed = client.post(
            "/api/v1/newsletter-preferences",
            json=_identity(email) | {"subscribed": True},
        )
        assert subscribed.status_code == 200
        assert subscribed.get_json() == {"result": "set", "subscribed": True}

        before = client.post(
            "/api/v1/newsletter-status-queries", json=_identity(email)
        )
        assert before.get_json() == {"status": "matched", "subscribed": True}

        created = client.post(
            "/api/v1/reservations", json=_booking(email, _slots(client)[0])
        )
        assert created.status_code == 201
        assert created.get_json()["confirmation"]["newsletter_subscribed"] is True

        after = client.post(
            "/api/v1/newsletter-status-queries", json=_identity(email)
        )
        assert after.get_json() == before.get_json()
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            row = manager.execute(
                "SELECT count(*), min(phone), bool_and(newsletter_subscribed) "
                "FROM cafe_fausse.customers WHERE email=%s",
                (email,),
            ).fetchone()
            assert row == (1, "+1 (202) 555-0198", True)
    finally:
        close_resources(app)
        _cleanup({email})


def test_preference_change_preserves_reservation_and_exact_retry_does_not_replay_action() -> None:
    email = f"api09-book-pref-{uuid4().hex}@example.test"
    app = create_app(_settings())
    try:
        client = app.test_client()
        payload = _booking(email, _slots(client)[0], action="subscribe")
        created = client.post("/api/v1/reservations", json=payload)
        assert created.status_code == 201
        reference = created.get_json()["confirmation"]["reservation_reference"]
        tables = created.get_json()["confirmation"]["assigned_table_numbers"]

        changed = client.post(
            "/api/v1/newsletter-preferences",
            json=_identity(email) | {"subscribed": False},
        )
        assert changed.get_json() == {"result": "set", "subscribed": False}

        retried = client.post("/api/v1/reservations", json=payload)
        assert retried.status_code == 200
        assert retried.get_json()["booking_result"] == "exact_retry"
        assert retried.get_json()["confirmation"]["reservation_reference"] == reference
        assert retried.get_json()["confirmation"]["assigned_table_numbers"] == tables
        assert retried.get_json()["confirmation"]["newsletter_subscribed"] is False
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            row = manager.execute(
                "SELECT c.newsletter_subscribed, count(DISTINCT r.reservation_id), count(a.table_number) "
                "FROM cafe_fausse.customers c JOIN cafe_fausse.reservations r USING(customer_id) "
                "JOIN cafe_fausse.reservation_table_assignments a USING(reservation_id) "
                "WHERE c.email=%s GROUP BY c.newsletter_subscribed",
                (email,),
            ).fetchone()
            assert row == (False, 1, len(tables))
    finally:
        close_resources(app)
        _cleanup({email})


def test_unavailable_booking_rolls_back_linked_preference_and_unrelated_state() -> None:
    blocker = f"api09-capacity-{uuid4().hex}@example.test"
    customer = f"api09-rollback-{uuid4().hex}@example.test"
    emails = {blocker, customer}
    app = create_app(_settings())
    try:
        client = app.test_client()
        slot = _slots(client, 120)[0]
        full = client.post(
            "/api/v1/reservations", json=_booking(blocker, slot, 120)
        )
        assert full.status_code == 201
        subscribed = client.post(
            "/api/v1/newsletter-preferences",
            json=_identity(customer) | {"subscribed": True},
        )
        assert subscribed.status_code == 200

        rejected = client.post(
            "/api/v1/reservations",
            json=_booking(customer, slot, 4, action="unsubscribe"),
        )
        assert rejected.status_code == 409
        assert rejected.get_json()["error"]["code"] == "reservation_unavailable"
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            target = manager.execute(
                "SELECT newsletter_subscribed, "
                "(SELECT count(*) FROM cafe_fausse.reservations r WHERE r.customer_id=c.customer_id) "
                "FROM cafe_fausse.customers c WHERE email=%s",
                (customer,),
            ).fetchone()
            assert target == (True, 0)
            blocker_state = manager.execute(
                "SELECT count(DISTINCT r.reservation_id), count(a.table_number) "
                "FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c USING(customer_id) "
                "JOIN cafe_fausse.reservation_table_assignments a USING(reservation_id) "
                "WHERE c.email=%s",
                (blocker,),
            ).fetchone()
            assert blocker_state == (1, 30)
    finally:
        close_resources(app)
        _cleanup(emails)


@pytest.mark.concurrency
def test_concurrent_same_customer_overlaps_commit_only_one_reservation() -> None:
    email = f"api09-overlap-{uuid4().hex}@example.test"
    app = create_app(_settings())
    try:
        seed = app.test_client()
        available = _slots(seed)
        assert len(available) >= 2
        payloads = [_booking(email, available[0]), _booking(email, available[1])]

        def submit(payload):
            with app.test_client() as client:
                return client.post("/api/v1/reservations", json=payload)

        with ThreadPoolExecutor(max_workers=2) as executor:
            responses = list(executor.map(submit, payloads))
        assert sorted(response.status_code for response in responses) == [201, 409]
        assert next(
            response for response in responses if response.status_code == 409
        ).get_json()["error"]["code"] == "reservation_overlap"
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            assert manager.execute(
                "SELECT count(*) FROM cafe_fausse.customers WHERE email=%s", (email,)
            ).fetchone()[0] == 1
            assert manager.execute(
                "SELECT count(*) FROM cafe_fausse.reservations r "
                "JOIN cafe_fausse.customers c USING(customer_id) WHERE c.email=%s",
                (email,),
            ).fetchone()[0] == 1
    finally:
        close_resources(app)
        _cleanup({email})


@pytest.mark.concurrency
def test_concurrent_exact_retries_reconstruct_one_logical_reservation() -> None:
    email = f"api09-retry-{uuid4().hex}@example.test"
    app = create_app(_settings())
    try:
        seed = app.test_client()
        payload = _booking(email, _slots(seed)[0], action="subscribe")
        created = seed.post("/api/v1/reservations", json=payload)
        assert created.status_code == 201
        reference = created.get_json()["confirmation"]["reservation_reference"]

        def submit(_):
            with app.test_client() as client:
                return client.post("/api/v1/reservations", json=payload)

        with ThreadPoolExecutor(max_workers=5) as executor:
            responses = list(executor.map(submit, range(5)))
        assert all(response.status_code == 200 for response in responses)
        assert all(
            response.get_json()["booking_result"] == "exact_retry"
            and response.get_json()["confirmation"]["reservation_reference"]
            == reference
            for response in responses
        )
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            assert manager.execute(
                "SELECT count(*) FROM cafe_fausse.reservations r "
                "JOIN cafe_fausse.customers c USING(customer_id) WHERE c.email=%s",
                (email,),
            ).fetchone()[0] == 1
    finally:
        close_resources(app)
        _cleanup({email})
