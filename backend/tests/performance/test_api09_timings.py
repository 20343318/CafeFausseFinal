from __future__ import annotations

from datetime import date
import math
import os
from time import perf_counter_ns
from uuid import uuid4

import psycopg
import pytest

from cafe_fausse.application import close_resources, create_app
from cafe_fausse.config import Settings


pytestmark = [
    pytest.mark.integration,
    pytest.mark.postgres,
    pytest.mark.performance,
    pytest.mark.slow,
]

WARMUPS = 5
SAMPLES = 30


def _settings() -> Settings:
    values = {
        "CAFE_FAUSSE_ENVIRONMENT": "test",
        "PGHOST": os.environ["PGHOST"],
        "PGPORT": os.environ.get("PGPORT", "5432"),
        "PGDATABASE": os.environ["PGDATABASE"],
        "PGUSER": os.environ["PGUSER"],
        "PGCONNECT_TIMEOUT": "1",
        "CAFE_FAUSSE_POOL_MIN_SIZE": "1",
        "CAFE_FAUSSE_POOL_MAX_SIZE": "5",
        "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS": "500",
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
        "last_name": "Performance",
        "email": email,
        "confirmation_email": email,
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


def _nearest_rank(values: list[float], percentile: float) -> float:
    ordered = sorted(values)
    return ordered[max(0, math.ceil(percentile * len(ordered)) - 1)]


def _summary(values: list[float]) -> dict:
    return {
        "count": len(values),
        "p50_ms": _nearest_rank(values, 0.50),
        "p95_ms": _nearest_rank(values, 0.95),
        "p99_ms": _nearest_rank(values, 0.99),
        "max_ms": max(values),
    }


def _measure(call, expected_status: int) -> list[float]:
    measured = []
    for index in range(WARMUPS + SAMPLES):
        started = perf_counter_ns()
        response = call(index)
        elapsed_ms = (perf_counter_ns() - started) / 1_000_000
        assert response.status_code == expected_status, response.get_json()
        if index >= WARMUPS:
            measured.append(elapsed_ms)
    assert len(measured) == SAMPLES
    return measured


def test_api09_representative_api_performance(pytestconfig) -> None:
    suffix = uuid4().hex
    preference_email = f"api09-perf-preference-{suffix}@example.test"
    reservation_emails = {
        f"api09-perf-reservation-{suffix}-{index}@example.test"
        for index in range(WARMUPS + SAMPLES)
    }
    all_emails = reservation_emails | {preference_email}
    app = create_app(_settings())
    try:
        client = app.test_client()
        identity = _identity(preference_email)
        initial = client.post(
            "/api/v1/newsletter-preferences", json=identity | {"subscribed": True}
        )
        assert initial.status_code == 200
        context = client.get("/api/v1/reservation-context").get_json()
        requested = date.fromisoformat(
            context["reservable_date_range"]["maximum_local_date"]
        )
        availability_path = (
            f"/api/v1/reservation-availability?local_date={requested}&party_size=4"
        )
        slots = client.get(availability_path).get_json()["slots"]
        available = [slot for slot in slots if slot["available"]]
        assert available

        results = {
            "OP-03 newsletter status": _summary(
                _measure(
                    lambda _: client.post(
                        "/api/v1/newsletter-status-queries", json=identity
                    ),
                    200,
                )
            ),
            "OP-04 newsletter preference": _summary(
                _measure(
                    lambda index: client.post(
                        "/api/v1/newsletter-preferences",
                        json=identity | {"subscribed": index % 2 == 0},
                    ),
                    200,
                )
            ),
            "OP-01 reservation context": _summary(
                _measure(lambda _: client.get("/api/v1/reservation-context"), 200)
            ),
            "OP-02 reservation availability": _summary(
                _measure(lambda _: client.get(availability_path), 200)
            ),
        }

        payloads = []
        for index, email in enumerate(sorted(reservation_emails)):
            slot = available[index % len(available)]
            payloads.append(
                _identity(email)
                | {
                    "starts_at_local": slot["starts_at_local"],
                    "utc_offset_minutes": slot["utc_offset_minutes"],
                    "party_size": 4,
                    "newsletter_action": "no_change",
                }
            )
        creation_values = _measure(
            lambda index: client.post("/api/v1/reservations", json=payloads[index]),
            201,
        )
        results["OP-05 reservation creation"] = _summary(creation_values)
        retry_payload = payloads[WARMUPS]
        results["OP-05 exact retry"] = _summary(
            _measure(
                lambda _: client.post("/api/v1/reservations", json=retry_payload),
                200,
            )
        )
        results["OP-05 validation failure"] = _summary(
            _measure(
                lambda _: client.post(
                    "/api/v1/reservations", json=retry_payload | {"party_size": 0}
                ),
                422,
            )
        )
        pytestconfig._cafe_fausse_api09_performance = results
    finally:
        close_resources(app)
        _cleanup(all_emails)
