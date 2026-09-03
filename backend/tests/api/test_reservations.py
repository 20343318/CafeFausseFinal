from dataclasses import replace
from datetime import datetime, timedelta, timezone

import pytest

from cafe_fausse.application import create_app
from cafe_fausse.services.reservations import ReservationConfirmationUnavailable, ReservationOutcomeUnknown, ReservationServiceUnavailable, ReservationTemporaryFailure
from cafe_fausse.services.results import BookingOutcome, ReservationBookingResult


pytestmark = pytest.mark.api
VALID = {
    "first_name": "Ada", "last_name": "Rivera",
    "email": "ada@example.test", "confirmation_email": "ada@example.test",
    "starts_at_local": "2026-09-12T17:00:00-04:00", "utc_offset_minutes": -240,
    "party_size": 6, "newsletter_action": "no_change",
}


class Service:
    def __init__(self, value): self.value = value; self.calls = []
    def book(self, command):
        self.calls.append(command)
        if isinstance(self.value, Exception): raise self.value
        return self.value


def result(outcome=BookingOutcome.BOOKED):
    start = datetime(2026, 9, 12, 21, tzinfo=timezone.utc)
    return ReservationBookingResult(
        outcome, reservation_id=9007199254740993, starts_at=start,
        ends_at=start + timedelta(minutes=90), party_size=6,
        assigned_table_numbers=(2, 7), newsletter_subscribed=False,
        phone_notice=outcome is BookingOutcome.BOOKED_PHONE_NOTICE,
        customer_name="Ada Q. Rivera", restaurant_timezone="America/New_York",
    )


def client_for(settings, dependency_factory, service):
    dependencies, _, _ = dependency_factory()
    dependencies = replace(dependencies, reservation_service=service)
    return create_app(settings, dependencies).test_client()


@pytest.mark.parametrize(("outcome", "status", "booking_result"), [
    (BookingOutcome.BOOKED, 201, "created"),
    (BookingOutcome.BOOKED_PHONE_NOTICE, 201, "created"),
    (BookingOutcome.EXACT_RETRY, 200, "exact_retry"),
])
def test_booking_success_contract(settings, dependency_factory, outcome, status, booking_result):
    response = client_for(settings, dependency_factory, Service(result(outcome))).post("/api/v1/reservations", json=VALID)
    assert response.status_code == status
    body = response.get_json()
    assert body["booking_result"] == booking_result
    assert body["confirmation"] == {
        "reservation_reference": "9007199254740993", "customer_name": "Ada Q. Rivera",
        "starts_at_local": "2026-09-12T17:00:00-04:00", "ends_at_local": "2026-09-12T18:30:00-04:00",
        "starts_at": "2026-09-12T21:00:00Z", "ends_at": "2026-09-12T22:30:00Z",
        "party_size": 6, "assigned_table_numbers": [2, 7], "newsletter_subscribed": False,
        "restaurant": {"address": "1234 Culinary Ave, Suite 100, Washington, DC 20002", "phone": "(202) 555-4567"},
    }
    assert ("phone_notice" in body) is (outcome is BookingOutcome.BOOKED_PHONE_NOTICE)
    wire = response.get_data(as_text=True)
    for forbidden in ("ada@example.test", "fingerprint", "customer_id", "database"):
        assert forbidden not in wire


@pytest.mark.parametrize(("value", "status", "code"), [
    (ReservationBookingResult(BookingOutcome.CUSTOMER_IDENTITY_CONFLICT), 409, "customer_identity_conflict"),
    (ReservationBookingResult(BookingOutcome.MIDDLE_INITIAL_CONFLICT), 409, "middle_initial_conflict"),
    (ReservationBookingResult(BookingOutcome.SAME_CUSTOMER_OVERLAP), 409, "reservation_overlap"),
    (ReservationBookingResult(BookingOutcome.UNAVAILABLE, detail_code="no_capacity_sufficient_combination"), 409, "reservation_unavailable"),
    (ReservationBookingResult(BookingOutcome.INVALID_REQUEST, detail_code="misaligned_start"), 422, "validation_failed"),
    (ReservationBookingResult(BookingOutcome.INVALID_REQUEST, detail_code="duration_or_party_size_out_of_range"), 422, "validation_failed"),
])
def test_booking_business_outcomes(settings, dependency_factory, value, status, code):
    response = client_for(settings, dependency_factory, Service(value)).post("/api/v1/reservations", json=VALID)
    assert response.status_code == status and response.get_json()["error"]["code"] == code


def test_reconciled_party_size_outcome_targets_only_the_caller_field(settings, dependency_factory):
    value = ReservationBookingResult(
        BookingOutcome.INVALID_REQUEST,
        detail_code="duration_or_party_size_out_of_range",
    )
    response = client_for(settings, dependency_factory, Service(value)).post(
        "/api/v1/reservations", json=VALID,
    )
    assert response.status_code == 422
    assert response.get_json()["error"]["fields"] == [{
        "field": "party_size",
        "code": "out_of_range",
        "message": "The party size is outside the current allowed range.",
    }]


@pytest.mark.parametrize(("error", "code", "unknown"), [
    (ReservationTemporaryFailure("x"), "temporary_failure", False),
    (ReservationOutcomeUnknown("x"), "reservation_outcome_unknown", True),
    (ReservationConfirmationUnavailable("x"), "reservation_confirmation_unavailable", False),
    (ReservationServiceUnavailable("x"), "service_unavailable", False),
])
def test_booking_technical_outcomes(settings, dependency_factory, error, code, unknown):
    error.pool_wait_ms = error.database_ms = 0
    error.attempts = 1
    error.cleanup_failed = False
    response = client_for(settings, dependency_factory, Service(error)).post("/api/v1/reservations", json=VALID)
    assert response.status_code == 503
    assert response.get_json()["error"]["code"] == code
    assert response.get_json()["error"]["outcome_unknown"] is unknown


def test_booking_rejects_unknown_fields_and_invalid_slot_before_service(settings, dependency_factory):
    service = Service(result())
    client = client_for(settings, dependency_factory, service)
    assert client.post("/api/v1/reservations", json=VALID | {"table_number": 1}).status_code == 400
    response = client.post("/api/v1/reservations", json=VALID | {"starts_at_local": "2026-09-12T17:00:00Z"})
    assert response.status_code == 422 and service.calls == []


def test_booking_rejects_period_middle_before_service(settings, dependency_factory):
    service = Service(result())
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/reservations", json=VALID | {"middle_initial": "A."}
    )
    assert response.status_code == 422
    assert response.get_json()["error"]["fields"] == [{
        "field": "middle_initial",
        "code": "invalid_format",
        "message": "Enter one letter.",
    }]
    assert service.calls == []


def test_confirmation_local_times_apply_iana_rules_to_each_committed_instant(settings, dependency_factory):
    start = datetime(2026, 11, 1, 4, 30, tzinfo=timezone.utc)
    transition_result = ReservationBookingResult(
        BookingOutcome.BOOKED,
        reservation_id=42,
        starts_at=start,
        ends_at=start + timedelta(minutes=90),
        party_size=2,
        assigned_table_numbers=(1,),
        newsletter_subscribed=False,
        customer_name="Ada Q. Rivera",
        restaurant_timezone="America/New_York",
    )
    response = client_for(settings, dependency_factory, Service(transition_result)).post(
        "/api/v1/reservations", json=VALID,
    )
    assert response.status_code == 201
    confirmation = response.get_json()["confirmation"]
    assert confirmation["starts_at_local"] == "2026-11-01T00:30:00-04:00"
    assert confirmation["ends_at_local"] == "2026-11-01T01:00:00-05:00"
