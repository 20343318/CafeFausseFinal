from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, time, timedelta, timezone
import os

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
        "CAFE_FAUSSE_POOL_MAX_SIZE": "5",
        "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS": "500",
        "CAFE_FAUSSE_READ_DEADLINE_MS": "2000",
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


def _admin():
    values = {
        "host": os.environ["PGHOST"],
        "port": int(os.environ["PGPORT"]),
        "dbname": os.environ["PGDATABASE"],
        "user": os.environ.get("CAFE_FAUSSE_API07_ADMIN_USER", "cafe_fausse_admin"),
    }
    if os.environ.get("PGPASSFILE"):
        values["passfile"] = os.environ["PGPASSFILE"]
    return psycopg.connect(**values)


def _set_configuration(connection, interval=30, duration=90, window=60, lead=120, timezone_name="America/New_York"):
    connection.execute("SET ROLE cafe_fausse_test")
    connection.execute(
        "SELECT cafe_fausse.set_reservation_configuration(%s::smallint,%s::smallint,%s::smallint,%s::smallint,%s)",
        (interval, duration, window, lead, timezone_name),
    )


def _set_hours(connection, weekday, opens_at, closes_at):
    connection.execute("SET ROLE cafe_fausse_test")
    connection.execute(
        "SELECT cafe_fausse.set_restaurant_operating_hours(%s::smallint,%s::time,%s::time)",
        (weekday, opens_at, closes_at),
    )


def _set_capacity(connection, table_number, capacity):
    connection.execute("SET ROLE cafe_fausse_test")
    connection.execute(
        "SELECT cafe_fausse.set_restaurant_table_capacity(%s::smallint,%s)",
        (table_number, capacity),
    )


def _date_for_weekday(minimum, maximum, weekday):
    candidate = minimum + timedelta(days=(weekday - minimum.isoweekday()) % 7)
    if candidate < minimum:
        candidate += timedelta(days=7)
    assert candidate <= maximum
    return candidate


def _availability(client, requested, party_size):
    return client.get(
        f"/api/v1/reservation-availability?local_date={requested.isoformat()}&party_size={party_size}"
    )


def _business_counts(connection):
    connection.execute("SET ROLE cafe_fausse_test")
    return connection.execute(
        "SELECT (SELECT count(*) FROM cafe_fausse.customers),"
        "(SELECT count(*) FROM cafe_fausse.reservations),"
        "(SELECT count(*) FROM cafe_fausse.reservation_table_assignments)"
    ).fetchone()


def test_context_is_exact_database_clock_snapshot_and_application_role_is_read_only():
    app = create_app(_settings())
    try:
        response = app.test_client().get("/api/v1/reservation-context")
        assert response.status_code == 200
        payload = response.get_json()
        assert payload["restaurant_timezone"] == "America/New_York"
        assert [row["iso_weekday"] for row in payload["weekday_hours"]] == list(range(1, 8))
        assert payload["reservation_policy"] == {
            "start_interval_minutes": 30,
            "reservation_duration_minutes": 90,
            "advance_window_days": 60,
            "same_day_lead_minutes": 120,
        }
        minimum = date.fromisoformat(payload["reservable_date_range"]["minimum_local_date"])
        maximum = date.fromisoformat(payload["reservable_date_range"]["maximum_local_date"])
        assert maximum - minimum == timedelta(days=60)
        assert payload["maximum_party_size"] == 120
        pool = app.extensions["cafe_fausse"].resource
        with pool.connection(timeout=1) as connection:
            with pytest.raises(psycopg.Error):
                with connection.transaction():
                    connection.execute("DELETE FROM cafe_fausse.reservation_configuration")
    finally:
        close_resources(app)


def test_availability_calls_frozen_routine_returns_full_ordered_schedule_and_does_not_mutate():
    with _manager() as manager:
        before = _business_counts(manager)
    app = create_app(_settings())
    try:
        context = app.test_client().get("/api/v1/reservation-context").get_json()
        requested = date.fromisoformat(context["reservable_date_range"]["minimum_local_date"]) + timedelta(days=1)
        response = app.test_client().get(f"/api/v1/reservation-availability?local_date={requested.isoformat()}&party_size=4")
        assert response.status_code == 200
        payload = response.get_json()
        assert payload["local_date"] == requested.isoformat()
        assert payload["party_size"] == 4 and payload["provisional"] is True
        assert payload["restaurant_timezone"] == context["restaurant_timezone"]
        starts = [slot["starts_at"] for slot in payload["slots"]]
        assert starts == sorted(starts) and len(starts) == len(set(starts))
        assert all(type(slot["available"]) is bool for slot in payload["slots"])
        assert all(set(slot) == {"starts_at_local", "utc_offset_minutes", "starts_at", "ends_at_local", "ends_at", "available"} for slot in payload["slots"])
    finally:
        close_resources(app)
    with _manager() as manager:
        assert _business_counts(manager) == before


def test_availability_all_unavailable_and_controlled_out_of_range_mapping():
    customer_id = None
    reservation_ids: list[int] = []
    app = create_app(_settings())
    try:
        context = app.test_client().get("/api/v1/reservation-context").get_json()
        requested = context["reservable_date_range"]["minimum_local_date"]
        weekday = date.fromisoformat(requested).isoweekday()
        hours = context["weekday_hours"][weekday - 1]
        timezone_name = context["restaurant_timezone"]
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            customer_id = manager.execute(
                "INSERT INTO cafe_fausse.customers(first_name,last_name,email) "
                "VALUES ('Availability','Fixture','api07-all-unavailable@example.test') RETURNING customer_id"
            ).fetchone()[0]
            starts = manager.execute(
                "SELECT value FROM generate_series((%s::date + %s::time) AT TIME ZONE %s, "
                "((%s::date + %s::time) AT TIME ZONE %s) - interval '90 minutes', interval '90 minutes') value",
                (requested, hours["opens_at_local"], timezone_name, requested, hours["closes_at_local"], timezone_name),
            ).fetchall()
            for index, (start,) in enumerate(starts):
                reservation_id = manager.execute(
                    "INSERT INTO cafe_fausse.reservations(customer_id,starts_at,ends_at,party_size,reservation_fingerprint) "
                    "VALUES (%s,%s,%s + interval '90 minutes',1,decode(md5(%s),'hex')) RETURNING reservation_id",
                    (customer_id, start, start, f"api07-unavailable-{index}"),
                ).fetchone()[0]
                reservation_ids.append(reservation_id)
                manager.execute(
                    "INSERT INTO cafe_fausse.reservation_table_assignments(reservation_id,table_number) VALUES (%s,1)",
                    (reservation_id,),
                )
            manager.commit()
        all_unavailable = app.test_client().get(f"/api/v1/reservation-availability?local_date={requested}&party_size=120")
        assert all_unavailable.status_code == 200
        assert all_unavailable.get_json()["slots"]
        assert all(slot["available"] is False for slot in all_unavailable.get_json()["slots"])
        outside = app.test_client().get("/api/v1/reservation-availability?local_date=2000-01-01&party_size=2147483647")
        assert outside.status_code == 422
        assert [item["field"] for item in outside.get_json()["error"]["fields"]] == ["local_date", "party_size"]
    finally:
        close_resources(app)
        if customer_id is not None:
            with _manager() as manager:
                manager.execute("SET ROLE cafe_fausse_test")
                manager.execute("DELETE FROM cafe_fausse.reservation_table_assignments WHERE reservation_id = ANY(%s)", (reservation_ids,))
                manager.execute("DELETE FROM cafe_fausse.reservations WHERE reservation_id = ANY(%s)", (reservation_ids,))
                manager.execute("DELETE FROM cafe_fausse.customers WHERE customer_id = %s", (customer_id,))
                manager.commit()


@pytest.mark.concurrency
def test_concurrent_identical_availability_reads_are_coherent_and_nonmutating():
    app = create_app(_settings())
    try:
        context = app.test_client().get("/api/v1/reservation-context").get_json()
        requested = context["reservable_date_range"]["maximum_local_date"]
        path = f"/api/v1/reservation-availability?local_date={requested}&party_size=4"
        def read():
            with app.test_client() as client:
                response = client.get(path)
                return response.status_code, response.get_json()
        with ThreadPoolExecutor(max_workers=8) as executor:
            results = list(executor.map(lambda _index: read(), range(16)))
        assert all(status == 200 for status, _payload in results)
        assert all(payload == results[0][1] for _status, payload in results)
    finally:
        close_resources(app)


def test_alternate_schedule_configuration_and_positive_capacity_affect_context_and_availability_then_restore():
    app = None
    try:
        with _manager() as manager:
            _set_configuration(manager, interval=15, duration=120, window=30, lead=0, timezone_name="UTC")
            _set_hours(manager, 1, time(18), time(22))
            _set_capacity(manager, 1, 7)
            manager.commit()

        app = create_app(_settings())
        client = app.test_client()
        context_response = client.get("/api/v1/reservation-context")
        assert context_response.status_code == 200
        context = context_response.get_json()
        assert context["restaurant_timezone"] == "UTC"
        assert context["reservation_policy"] == {
            "start_interval_minutes": 15,
            "reservation_duration_minutes": 120,
            "advance_window_days": 30,
            "same_day_lead_minutes": 0,
        }
        assert context["weekday_hours"][0] == {
            "iso_weekday": 1,
            "opens_at_local": "18:00:00",
            "closes_at_local": "22:00:00",
        }
        assert context["maximum_party_size"] == 123
        minimum = date.fromisoformat(context["reservable_date_range"]["minimum_local_date"])
        maximum = date.fromisoformat(context["reservable_date_range"]["maximum_local_date"])
        requested = _date_for_weekday(minimum, maximum, 1)
        payload = _availability(client, requested, 123).get_json()
        assert [slot["starts_at_local"][11:19] for slot in payload["slots"]] == [
            "18:00:00", "18:15:00", "18:30:00", "18:45:00", "19:00:00",
            "19:15:00", "19:30:00", "19:45:00", "20:00:00",
        ]
        assert all(
            datetime.fromisoformat(slot["ends_at"].replace("Z", "+00:00"))
            - datetime.fromisoformat(slot["starts_at"].replace("Z", "+00:00"))
            == timedelta(minutes=120)
            for slot in payload["slots"]
        )
    finally:
        if app is not None:
            close_resources(app)
        with _manager() as manager:
            _set_capacity(manager, 1, 4)
            _set_hours(manager, 1, time(17), time(23))
            _set_configuration(manager)
            manager.commit()

    restored = create_app(_settings())
    try:
        context = restored.test_client().get("/api/v1/reservation-context").get_json()
        assert context["restaurant_timezone"] == "America/New_York"
        assert context["reservation_policy"] == {
            "start_interval_minutes": 30,
            "reservation_duration_minutes": 90,
            "advance_window_days": 60,
            "same_day_lead_minutes": 120,
        }
        assert context["weekday_hours"][0]["opens_at_local"] == "17:00:00"
        assert context["weekday_hours"][0]["closes_at_local"] == "23:00:00"
        assert context["maximum_party_size"] == 120
    finally:
        close_resources(restored)


def test_incomplete_foundation_maps_both_operations_safely_and_is_restored():
    with _manager() as manager:
        before = _business_counts(manager)
    removed = None
    app = None
    try:
        with _admin() as admin:
            removed = admin.execute(
                "DELETE FROM cafe_fausse.restaurant_operating_hours WHERE weekday = 7 "
                "RETURNING weekday, opens_at, closes_at"
            ).fetchone()
            assert removed is not None
            admin.commit()
        app = create_app(_settings())
        context_response = app.test_client().get("/api/v1/reservation-context")
        assert context_response.status_code == 503
        assert context_response.get_json() == {
            "error": {
                "code": "service_unavailable",
                "message": "The service cannot process this request right now.",
                "retryable": True,
                "outcome_unknown": False,
            }
        }
        availability_response = _availability(app.test_client(), date.today() + timedelta(days=1), 4)
        assert availability_response.status_code == 503
        assert availability_response.get_json() == context_response.get_json()
    finally:
        if app is not None:
            close_resources(app)
        if removed is not None:
            with _admin() as admin:
                admin.execute(
                    "INSERT INTO cafe_fausse.restaurant_operating_hours(weekday,opens_at,closes_at) VALUES (%s,%s,%s)",
                    removed,
                )
                admin.commit()
    verifier = create_app(_settings())
    try:
        assert verifier.test_client().get("/api/v1/reservation-context").status_code == 200
    finally:
        close_resources(verifier)
    with _manager() as manager:
        assert _business_counts(manager) == before


def test_free_partial_full_and_back_to_back_occupancy_are_provisional_and_nonmutating_after_cleanup():
    customer_ids = []
    reservation_ids = []
    with _manager() as manager:
        before = _business_counts(manager)
    app = create_app(_settings())
    try:
        client = app.test_client()
        context = client.get("/api/v1/reservation-context").get_json()
        requested = date.fromisoformat(context["reservable_date_range"]["maximum_local_date"])
        free = _availability(client, requested, 120).get_json()["slots"]
        assert free and all(slot["available"] is True for slot in free)
        first_start = datetime.fromisoformat(free[0]["starts_at"].replace("Z", "+00:00"))
        full_start = first_start + timedelta(minutes=180)
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            for index in range(2):
                customer_ids.append(
                    manager.execute(
                        "INSERT INTO cafe_fausse.customers(first_name,last_name,email) VALUES ('API07','Occupancy',%s) RETURNING customer_id",
                        (f"api07-occupancy-{index}@example.test",),
                    ).fetchone()[0]
                )
            reservation_ids.append(
                manager.execute(
                    "INSERT INTO cafe_fausse.reservations(customer_id,starts_at,ends_at,party_size,reservation_fingerprint) "
                    "VALUES (%s,%s,%s,1,decode(repeat('01',32),'hex')) RETURNING reservation_id",
                    (customer_ids[0], first_start, first_start + timedelta(minutes=90)),
                ).fetchone()[0]
            )
            manager.execute(
                "INSERT INTO cafe_fausse.reservation_table_assignments(reservation_id,table_number) VALUES (%s,1)",
                (reservation_ids[0],),
            )
            manager.commit()

        partial_small = _availability(client, requested, 4).get_json()["slots"]
        partial_full_party = _availability(client, requested, 120).get_json()["slots"]
        assert next(slot for slot in partial_small if slot["starts_at"] == free[0]["starts_at"])["available"] is True
        assert next(slot for slot in partial_full_party if slot["starts_at"] == free[0]["starts_at"])["available"] is False
        back_to_back = (first_start + timedelta(minutes=90)).isoformat().replace("+00:00", "Z")
        assert next(slot for slot in partial_full_party if slot["starts_at"] == back_to_back)["available"] is True

        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            reservation_ids.append(
                manager.execute(
                    "INSERT INTO cafe_fausse.reservations(customer_id,starts_at,ends_at,party_size,reservation_fingerprint) "
                    "VALUES (%s,%s,%s,120,decode(repeat('02',32),'hex')) RETURNING reservation_id",
                    (customer_ids[1], full_start, full_start + timedelta(minutes=90)),
                ).fetchone()[0]
            )
            with manager.cursor() as cursor:
                cursor.executemany(
                    "INSERT INTO cafe_fausse.reservation_table_assignments(reservation_id,table_number) VALUES (%s,%s)",
                    [(reservation_ids[1], table_number) for table_number in range(1, 31)],
                )
            manager.commit()
        full_start_text = full_start.isoformat().replace("+00:00", "Z")
        occupied = _availability(client, requested, 4).get_json()["slots"]
        assert next(slot for slot in occupied if slot["starts_at"] == full_start_text)["available"] is False
    finally:
        close_resources(app)
        if reservation_ids or customer_ids:
            with _manager() as manager:
                manager.execute("SET ROLE cafe_fausse_test")
                if reservation_ids:
                    manager.execute(
                        "DELETE FROM cafe_fausse.reservation_table_assignments WHERE reservation_id = ANY(%s)",
                        (reservation_ids,),
                    )
                    manager.execute("DELETE FROM cafe_fausse.reservations WHERE reservation_id = ANY(%s)", (reservation_ids,))
                if customer_ids:
                    manager.execute("DELETE FROM cafe_fausse.customers WHERE customer_id = ANY(%s)", (customer_ids,))
                manager.commit()
    with _manager() as manager:
        assert _business_counts(manager) == before


def test_same_day_lead_and_advance_window_boundaries_use_database_time():
    app = None
    changed_weekday = None
    original_hours = None
    try:
        with _manager() as manager:
            manager.execute("SET ROLE cafe_fausse_test")
            timezone_name, local_now = manager.execute(
                "SELECT candidate.name, statement_timestamp() AT TIME ZONE candidate.name "
                "FROM (VALUES ('UTC'),('America/New_York'),('America/Los_Angeles'),('Pacific/Honolulu'),('Asia/Tokyo')) candidate(name) "
                "WHERE (statement_timestamp() AT TIME ZONE candidate.name)::time BETWEEN TIME '04:00' AND TIME '20:00' LIMIT 1"
            ).fetchone()
            changed_weekday = local_now.date().isoweekday()
            original_hours = manager.execute(
                "SELECT opens_at, closes_at FROM cafe_fausse.restaurant_operating_hours WHERE weekday=%s",
                (changed_weekday,),
            ).fetchone()
            floor_minutes = (local_now.minute // 15) * 15
            floor_local = local_now.replace(minute=floor_minutes, second=0, microsecond=0)
            opens_at = (floor_local - timedelta(minutes=15)).time()
            closes_at = (floor_local + timedelta(minutes=120)).time()
            _set_configuration(manager, interval=15, duration=60, window=30, lead=30, timezone_name=timezone_name)
            _set_hours(manager, changed_weekday, opens_at, closes_at)
            manager.commit()
        app = create_app(_settings())
        with _manager() as manager:
            before_call = manager.execute("SELECT statement_timestamp()").fetchone()[0]
        today_response = _availability(app.test_client(), local_now.date(), 4)
        with _manager() as manager:
            after_call = manager.execute("SELECT statement_timestamp()").fetchone()[0]
        assert today_response.status_code == 200
        slots = today_response.get_json()["slots"]
        definitely_before = [slot for slot in slots if datetime.fromisoformat(slot["starts_at"].replace("Z", "+00:00")) < before_call + timedelta(minutes=30)]
        definitely_after = [slot for slot in slots if datetime.fromisoformat(slot["starts_at"].replace("Z", "+00:00")) >= after_call + timedelta(minutes=30)]
        assert definitely_before and all(slot["available"] is False for slot in definitely_before)
        assert definitely_after and all(slot["available"] is True for slot in definitely_after)

        context = app.test_client().get("/api/v1/reservation-context").get_json()
        minimum = date.fromisoformat(context["reservable_date_range"]["minimum_local_date"])
        maximum = date.fromisoformat(context["reservable_date_range"]["maximum_local_date"])
        assert _availability(app.test_client(), minimum, 4).status_code == 200
        assert _availability(app.test_client(), maximum, 4).status_code == 200
        assert _availability(app.test_client(), minimum - timedelta(days=1), 4).status_code == 422
        assert _availability(app.test_client(), maximum + timedelta(days=1), 4).status_code == 422
    finally:
        if app is not None:
            close_resources(app)
        if changed_weekday is not None and original_hours is not None:
            with _manager() as manager:
                _set_hours(manager, changed_weekday, original_hours[0], original_hours[1])
                _set_configuration(manager)
                manager.commit()


def test_application_role_executes_routine_but_cannot_read_reservations_or_assignments_and_does_not_mutate():
    with _manager() as manager:
        before = _business_counts(manager)
    app = create_app(_settings())
    try:
        context = app.test_client().get("/api/v1/reservation-context").get_json()
        requested = date.fromisoformat(context["reservable_date_range"]["maximum_local_date"])
        pool = app.extensions["cafe_fausse"].resource
        with pool.connection(timeout=1) as connection:
            with connection.transaction():
                outcome = connection.execute(
                    "SELECT outcome FROM cafe_fausse.provisional_availability(%s::date,%s::integer) LIMIT 1",
                    (requested, 4),
                ).fetchone()[0]
                assert outcome == "slots"
            for relation in ("cafe_fausse.reservations", "cafe_fausse.reservation_table_assignments"):
                with pytest.raises(psycopg.Error):
                    with connection.transaction():
                        connection.execute(f"SELECT count(*) FROM {relation}").fetchone()
    finally:
        close_resources(app)
    with _manager() as manager:
        assert _business_counts(manager) == before
