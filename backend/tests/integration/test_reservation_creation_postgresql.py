from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime
import os
from uuid import uuid4
from zoneinfo import ZoneInfo

import psycopg
import pytest

from cafe_fausse.application import close_resources, create_app
from cafe_fausse.config import Settings


pytestmark = [pytest.mark.integration, pytest.mark.postgres]


def _settings() -> Settings:
    values = {
        "CAFE_FAUSSE_ENVIRONMENT": "test", "PGHOST": os.environ["PGHOST"],
        "PGPORT": os.environ.get("PGPORT", "5432"), "PGDATABASE": os.environ["PGDATABASE"],
        "PGUSER": os.environ["PGUSER"], "PGCONNECT_TIMEOUT": "1",
        "CAFE_FAUSSE_POOL_MIN_SIZE": "1", "CAFE_FAUSSE_POOL_MAX_SIZE": "5",
        "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS": "500", "CAFE_FAUSSE_MUTATION_DEADLINE_MS": "15000",
        "CAFE_FAUSSE_RETRY_MIN_REMAINING_MS": "500",
    }
    if os.environ.get("PGPASSFILE"): values["PGPASSFILE"] = os.environ["PGPASSFILE"]
    return Settings.from_environment(values)


def _manager():
    values = {"host": os.environ["PGHOST"], "port": int(os.environ["PGPORT"]), "dbname": os.environ["PGDATABASE"], "user": os.environ["CAFE_FAUSSE_TEST_MANAGER_USER"]}
    if os.environ.get("PGPASSFILE"): values["passfile"] = os.environ["PGPASSFILE"]
    return psycopg.connect(**values)


def _slot(client, party_size=4):
    context = client.get("/api/v1/reservation-context").get_json()
    requested = date.fromisoformat(context["reservable_date_range"]["maximum_local_date"])
    slots = client.get(f"/api/v1/reservation-availability?local_date={requested}&party_size={party_size}").get_json()["slots"]
    return next(slot for slot in slots if slot["available"])


def _payload(email, slot, party_size=4, **changes):
    value = {
        "first_name": "API08", "last_name": "Reservation", "email": email,
        "confirmation_email": email, "phone": "+1 (202) 555-0198",
        "starts_at_local": slot["starts_at_local"], "utc_offset_minutes": slot["utc_offset_minutes"],
        "party_size": party_size, "newsletter_action": "subscribe",
    }
    return value | changes


def _cleanup(emails):
    with _manager() as manager:
        manager.execute("SET ROLE cafe_fausse_test")
        ids = [row[0] for row in manager.execute("SELECT customer_id FROM cafe_fausse.customers WHERE email = ANY(%s)", (list(emails),)).fetchall()]
        if ids:
            reservation_ids = [row[0] for row in manager.execute("SELECT reservation_id FROM cafe_fausse.reservations WHERE customer_id = ANY(%s)", (ids,)).fetchall()]
            if reservation_ids:
                manager.execute("DELETE FROM cafe_fausse.reservation_table_assignments WHERE reservation_id = ANY(%s)", (reservation_ids,))
                manager.execute("DELETE FROM cafe_fausse.reservations WHERE reservation_id = ANY(%s)", (reservation_ids,))
            manager.execute("DELETE FROM cafe_fausse.customers WHERE customer_id = ANY(%s)", (ids,))
        manager.commit()


def test_booking_creates_customer_and_atomic_reservation_then_exact_retry_reconstructs():
    email = f"api08-success-{uuid4().hex}@example.test"
    app = create_app(_settings())
    try:
        client = app.test_client(); slot = _slot(client, 6); payload = _payload(email, slot, 6, middle_initial="q")
        created = client.post("/api/v1/reservations", json=payload)
        assert created.status_code == 201 and created.get_json()["booking_result"] == "created"
        confirmation = created.get_json()["confirmation"]
        assert confirmation["customer_name"] == "API08 Q. Reservation"
        assert confirmation["assigned_table_numbers"] == sorted(set(confirmation["assigned_table_numbers"]))
        zone = ZoneInfo(client.get("/api/v1/reservation-context").get_json()["restaurant_timezone"])
        starts_at = datetime.fromisoformat(confirmation["starts_at"].replace("Z", "+00:00"))
        ends_at = datetime.fromisoformat(confirmation["ends_at"].replace("Z", "+00:00"))
        assert confirmation["starts_at_local"] == starts_at.astimezone(zone).isoformat(timespec="seconds")
        assert confirmation["ends_at_local"] == ends_at.astimezone(zone).isoformat(timespec="seconds")
        retried = client.post("/api/v1/reservations", json=payload)
        assert retried.status_code == 200 and retried.get_json()["booking_result"] == "exact_retry"
        assert retried.get_json()["confirmation"] == confirmation
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            row = manager.execute(
                    "SELECT c.first_name,c.middle_initial,c.last_name,c.email,c.phone,c.newsletter_subscribed,count(DISTINCT r.reservation_id),count(a.table_number) "
                "FROM cafe_fausse.customers c JOIN cafe_fausse.reservations r USING(customer_id) "
                "JOIN cafe_fausse.reservation_table_assignments a USING(reservation_id) WHERE c.email=%s "
                "GROUP BY c.first_name,c.middle_initial,c.last_name,c.email,c.phone,c.newsletter_subscribed", (email,),
            ).fetchone()
            assert row[:6] == ("API08", "Q", "Reservation", email, "+1 (202) 555-0198", True)
            assert row[6] == 1 and row[7] == len(confirmation["assigned_table_numbers"])
    finally:
        close_resources(app); _cleanup({email})


def test_invalid_request_and_identity_conflict_do_not_leave_partial_state():
    email = f"api08-rollback-{uuid4().hex}@example.test"
    app = create_app(_settings())
    try:
        client = app.test_client(); slot = _slot(client)
        period = client.post("/api/v1/reservations", json=_payload(email, slot, middle_initial="A."))
        assert period.status_code == 422
        assert period.get_json()["error"]["fields"] == [{
            "field": "middle_initial", "code": "invalid_format", "message": "Enter one letter."
        }]
        invalid = client.post("/api/v1/reservations", json=_payload(email, slot, party_size=0))
        assert invalid.status_code == 422
        created = client.post("/api/v1/reservations", json=_payload(email, slot))
        assert created.status_code == 201
        conflict = client.post("/api/v1/reservations", json=_payload(email, slot, first_name="Different"))
        assert conflict.status_code == 409 and conflict.get_json()["error"]["code"] == "customer_identity_conflict"
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            assert manager.execute("SELECT count(*) FROM cafe_fausse.customers WHERE email=%s", (email,)).fetchone()[0] == 1
            assert manager.execute("SELECT count(*) FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c USING(customer_id) WHERE c.email=%s", (email,)).fetchone()[0] == 1
    finally:
        close_resources(app); _cleanup({email})


@pytest.mark.concurrency
def test_concurrent_full_capacity_requests_commit_one_winner_without_shared_tables():
    emails = {f"api08-concurrency-{uuid4().hex}@example.test" for _ in range(2)}
    app = create_app(_settings())
    try:
        seed_client = app.test_client(); slot = _slot(seed_client, 120)
        payloads = [_payload(email, slot, 120, phone="202-555-0198") for email in emails]
        def submit(payload):
            with app.test_client() as client: return client.post("/api/v1/reservations", json=payload)
        with ThreadPoolExecutor(max_workers=2) as executor:
            responses = list(executor.map(submit, payloads))
        assert sorted(response.status_code for response in responses) == [201, 409]
        loser = next(response for response in responses if response.status_code == 409)
        assert loser.get_json()["error"]["code"] == "reservation_unavailable"
        winner = next(response for response in responses if response.status_code == 201)
        assert winner.get_json()["confirmation"]["assigned_table_numbers"] == list(range(1, 31))
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            counts = manager.execute(
                "SELECT count(DISTINCT r.reservation_id),count(a.table_number) FROM cafe_fausse.reservations r "
                "JOIN cafe_fausse.customers c USING(customer_id) JOIN cafe_fausse.reservation_table_assignments a USING(reservation_id) "
                "WHERE c.email = ANY(%s)", (list(emails),),
            ).fetchone()
            assert counts == (1, 30)
    finally:
        close_resources(app); _cleanup(emails)
