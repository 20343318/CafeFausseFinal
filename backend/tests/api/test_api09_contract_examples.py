from __future__ import annotations

from dataclasses import dataclass, replace
from datetime import date, datetime, time
import json
from pathlib import Path
import re

import pytest

from cafe_fausse.application import create_app
from cafe_fausse.http.responses import ERRORS
from cafe_fausse.services.health import ReadinessProbeFailure, ReadinessService
from cafe_fausse.services.newsletter_preferences import NewsletterPreferenceOutcomeUnknown
from cafe_fausse.services.newsletter_status import NewsletterStatusIndeterminate
from cafe_fausse.services.reservation_context import ReservationServiceUnavailable
from cafe_fausse.services.reservations import (
    ReservationConfirmationUnavailable,
    ReservationOutcomeUnknown,
    ReservationTemporaryFailure,
)
from cafe_fausse.services.results import (
    AvailabilityOutcome,
    AvailabilityRequest,
    AvailabilitySlot,
    BookingOutcome,
    NewsletterPreferenceOutcome,
    NewsletterPreferenceResult,
    NewsletterStatusOutcome,
    NewsletterStatusResult,
    ReadinessCategory,
    ReservationAvailabilityResult,
    ReservationBookingResult,
    ReservationContextResult,
    WeekdayHours,
)


pytestmark = pytest.mark.api
CONTRACT = Path(__file__).parents[3] / "docs" / "approved-design-artifacts" / "Cafe_Fausse_API02_Flask_REST_Contract.md"


@dataclass(frozen=True)
class ContractExample:
    line: int
    body: dict


# Role is the JSON block's role. Evidence records whether the block is directly
# submitted or requires an approved deterministic application seam.
CLASSIFICATION = {
    89: ("error-response", "direct-request"),
    300: ("success-response", "direct-request"),
    308: ("success-response", "deterministic-health-seam"),
    423: ("success-response", "deterministic-database-seam"),
    457: ("success-response", "deterministic-database-seam"),
    480: ("success-response", "deterministic-database-seam"),
    501: ("request", "direct-request"),
    507: ("success-response", "deterministic-database-seam"),
    511: ("success-response", "deterministic-database-seam"),
    517: ("success-response", "deterministic-database-seam"),
    523: ("error-response", "deterministic-database-seam"),
    527: ("error-response", "deterministic-failure-seam"),
    535: ("request", "direct-request"),
    541: ("success-response", "deterministic-database-seam"),
    547: ("success-response", "deterministic-database-seam"),
    553: ("success-response", "deterministic-database-seam"),
    559: ("error-response", "deterministic-database-seam"),
    567: ("request", "direct-request"),
    584: ("success-response", "deterministic-database-seam"),
    604: ("success-response", "deterministic-database-seam"),
    624: ("success-response", "deterministic-database-seam"),
    645: ("success-response", "deterministic-database-seam"),
    667: ("error-response", "deterministic-database-seam"),
    673: ("error-response", "deterministic-database-seam"),
    679: ("error-response", "deterministic-database-seam"),
    685: ("error-response", "deterministic-failure-seam"),
    691: ("error-response", "deterministic-failure-seam"),
    697: ("error-response", "deterministic-failure-seam"),
    705: ("success-response", "direct-request"),
    709: ("success-response", "deterministic-health-seam"),
    715: ("error-response", "deterministic-health-seam"),
    721: ("error-response", "direct-request"),
    725: ("error-response", "direct-request"),
    729: ("error-response", "deterministic-failure-seam"),
    735: ("error-response", "deterministic-failure-seam"),
    739: ("error-response", "deterministic-failure-seam"),
}


class OperationSeam:
    def __init__(self, value):
        self.value = value
        self.calls = []

    def _answer(self, value=None):
        self.calls.append(value)
        if isinstance(self.value, BaseException):
            raise self.value
        return self.value

    def get(self, request=None): return self._answer(request)
    def lookup(self, identity): return self._answer(identity)
    def set_preference(self, command): return self._answer(command)
    def book(self, command): return self._answer(command)


class ReadinessGateway:
    def __init__(self, fails=False): self.fails = fails

    def check_readiness(self, _deadline_ms):
        if self.fails:
            raise ReadinessProbeFailure(ReadinessCategory.FOUNDATION)
        return 0.0, 0.0


def _examples():
    text = CONTRACT.read_text(encoding="utf-8")
    return [
        ContractExample(text.count("\n", 0, match.start()) + 1, json.loads(match.group(1)))
        for match in re.finditer(r"```json\s*(.*?)```", text, flags=re.DOTALL)
    ]


EXAMPLES = _examples()
EXAMPLE_BY_LINE = {example.line: example.body for example in EXAMPLES}


def _client(settings, dependency_factory, value=None, *, readiness_fails=False):
    dependencies, _gateway, _live = dependency_factory()
    seam = OperationSeam(value)
    dependencies = replace(
        dependencies,
        readiness_service=ReadinessService(ReadinessGateway(readiness_fails), 1000),
        newsletter_status_service=seam,
        newsletter_preference_service=seam,
        reservation_context_service=seam,
        reservation_availability_service=seam,
        reservation_service=seam,
    )
    return create_app(settings, dependencies).test_client(), seam


def _instant(value): return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _context(body):
    policy, date_range = body["reservation_policy"], body["reservable_date_range"]
    return ReservationContextResult(
        body["restaurant_timezone"],
        tuple(WeekdayHours(row["iso_weekday"], time.fromisoformat(row["opens_at_local"]), time.fromisoformat(row["closes_at_local"])) for row in body["weekday_hours"]),
        policy["start_interval_minutes"], policy["reservation_duration_minutes"],
        policy["advance_window_days"], policy["same_day_lead_minutes"],
        date.fromisoformat(date_range["minimum_local_date"]),
        date.fromisoformat(date_range["maximum_local_date"]), body["maximum_party_size"],
    )


def _availability(body):
    request = AvailabilityRequest(date.fromisoformat(body["local_date"]), body["party_size"])
    slots = tuple(
        AvailabilitySlot(datetime.fromisoformat(row["starts_at_local"]).replace(tzinfo=None), _instant(row["starts_at"]), _instant(row["ends_at"]), row["available"])
        for row in body["slots"]
    )
    return ReservationAvailabilityResult(AvailabilityOutcome.SLOTS, request, body["restaurant_timezone"], slots)


def _booking(body):
    confirmation = body["confirmation"]
    outcome = {
        ("created", False): BookingOutcome.BOOKED,
        ("created", True): BookingOutcome.BOOKED_PHONE_NOTICE,
        ("exact_retry", False): BookingOutcome.EXACT_RETRY,
    }[(body["booking_result"], "phone_notice" in body)]
    return ReservationBookingResult(
        outcome, reservation_id=int(confirmation["reservation_reference"]),
        starts_at=_instant(confirmation["starts_at"]), ends_at=_instant(confirmation["ends_at"]),
        party_size=confirmation["party_size"], assigned_table_numbers=tuple(confirmation["assigned_table_numbers"]),
        newsletter_subscribed=confirmation["newsletter_subscribed"], phone_notice="phone_notice" in body,
        customer_name=confirmation["customer_name"], restaurant_timezone="America/New_York",
    )


def _reservation_payload(body):
    confirmation = body["confirmation"]
    parts = confirmation["customer_name"].split()
    email = f"{parts[0]}.{parts[-1]}@example.com".lower()
    payload = {
        "first_name": parts[0], "last_name": parts[-1], "email": email,
        "confirmation_email": email, "starts_at_local": confirmation["starts_at_local"],
        "utc_offset_minutes": -240, "party_size": confirmation["party_size"],
        "newsletter_action": "no_change",
    }
    if len(parts) == 3: payload["middle_initial"] = parts[1]
    return payload


def _reservation_error(error_type):
    error = error_type("contract example failure")
    error.pool_wait_ms, error.database_ms, error.attempts, error.cleanup_failed = 0.0, 0.0, 1, False
    return error


def _assert_illustrative_validation(actual, example, field, code):
    # Section 14 declares examples illustrative, not executable fixtures. Exercise
    # the route and compare stable envelope/field semantics; field messages remain
    # governed by the normative field catalogue.
    assert set(actual) == set(example) == {"error"}
    actual_error, example_error = actual["error"], example["error"]
    keys = ("code", "retryable", "outcome_unknown")
    assert {key: actual_error[key] for key in keys} == {key: example_error[key] for key in keys}
    assert set(actual_error) == set(example_error) == {"code", "message", "retryable", "outcome_unknown", "fields"}
    assert len(actual_error["fields"]) == len(example_error["fields"]) == 1
    assert actual_error["fields"][0]["field"] == field
    assert actual_error["fields"][0]["code"] == code
    assert set(actual_error["fields"][0]) == set(example_error["fields"][0])
    assert actual_error["message"] and actual_error["fields"][0]["message"]


def _exercise(example, settings, dependency_factory):
    line, expected = example.line, example.body
    if line in {300, 705}:
        client, _ = _client(settings, dependency_factory); response = client.get("/api/v1/health/liveness")
    elif line in {308, 709}:
        client, _ = _client(settings, dependency_factory); response = client.get("/api/v1/health/readiness")
    elif line == 423:
        client, _ = _client(settings, dependency_factory, _context(expected)); response = client.get("/api/v1/reservation-context")
    elif line in {457, 480}:
        client, _ = _client(settings, dependency_factory, _availability(expected))
        response = client.get("/api/v1/reservation-availability", query_string={"local_date": expected["local_date"], "party_size": expected["party_size"]})
    elif line == 501:
        client, seam = _client(settings, dependency_factory, NewsletterStatusResult(NewsletterStatusOutcome.MATCHED, True))
        response = client.post("/api/v1/newsletter-status-queries", json=expected)
        assert response.get_json() == EXAMPLE_BY_LINE[507] and len(seam.calls) == 1
        assert seam.calls[0].middle_initial == "M" and seam.calls[0].email == "ada.rivera@example.com"
        return
    elif line in {507, 511, 517}:
        result = {507: NewsletterStatusResult(NewsletterStatusOutcome.MATCHED, True), 511: NewsletterStatusResult(NewsletterStatusOutcome.MATCHED, False), 517: NewsletterStatusResult(NewsletterStatusOutcome.NOT_FOUND)}[line]
        client, _ = _client(settings, dependency_factory, result); response = client.post("/api/v1/newsletter-status-queries", json=EXAMPLE_BY_LINE[501])
    elif line == 523:
        client, _ = _client(settings, dependency_factory, NewsletterStatusResult(NewsletterStatusOutcome.CUSTOMER_IDENTITY_CONFLICT)); response = client.post("/api/v1/newsletter-status-queries", json=EXAMPLE_BY_LINE[501])
    elif line == 527:
        client, _ = _client(settings, dependency_factory, NewsletterStatusIndeterminate()); response = client.post("/api/v1/newsletter-status-queries", json=EXAMPLE_BY_LINE[501])
    elif line == 535:
        client, seam = _client(settings, dependency_factory, NewsletterPreferenceResult(NewsletterPreferenceOutcome.SUBSCRIBED, True))
        response = client.post("/api/v1/newsletter-preferences", json=expected)
        assert response.get_json() == EXAMPLE_BY_LINE[541] and len(seam.calls) == 1
        assert seam.calls[0].middle_initial == "M"
        return
    elif line in {541, 547, 553, 559}:
        result = {541: NewsletterPreferenceResult(NewsletterPreferenceOutcome.SUBSCRIBED, True), 547: NewsletterPreferenceResult(NewsletterPreferenceOutcome.UNSUBSCRIBED, False), 553: NewsletterPreferenceResult(NewsletterPreferenceOutcome.NO_CUSTOMER_NO_CHANGE, False), 559: NewsletterPreferenceResult(NewsletterPreferenceOutcome.MIDDLE_INITIAL_CONFLICT)}[line]
        client, _ = _client(settings, dependency_factory, result); response = client.post("/api/v1/newsletter-preferences", json=EXAMPLE_BY_LINE[535])
    elif line == 567:
        client, seam = _client(settings, dependency_factory, _booking(EXAMPLE_BY_LINE[584])); response = client.post("/api/v1/reservations", json=expected)
        assert response.status_code == 201 and response.get_json() == EXAMPLE_BY_LINE[584] and len(seam.calls) == 1
        assert seam.calls[0].middle_initial == "M" and seam.calls[0].phone == "+1 (202) 555-0198"
        return
    elif line in {584, 604, 624, 645}:
        client, _ = _client(settings, dependency_factory, _booking(expected)); response = client.post("/api/v1/reservations", json=_reservation_payload(expected))
    elif line in {667, 673, 679}:
        result = {667: ReservationBookingResult(BookingOutcome.SAME_CUSTOMER_OVERLAP), 673: ReservationBookingResult(BookingOutcome.UNAVAILABLE), 679: ReservationBookingResult(BookingOutcome.INVALID_REQUEST, detail_code="utc_offset_mismatch")}[line]
        client, _ = _client(settings, dependency_factory, result); response = client.post("/api/v1/reservations", json=EXAMPLE_BY_LINE[567])
    elif line in {685, 691, 697}:
        error = {685: _reservation_error(ReservationTemporaryFailure), 691: _reservation_error(ReservationConfirmationUnavailable), 697: _reservation_error(ReservationOutcomeUnknown)}[line]
        client, _ = _client(settings, dependency_factory, error); response = client.post("/api/v1/reservations", json=EXAMPLE_BY_LINE[567])
    elif line == 715:
        client, _ = _client(settings, dependency_factory, readiness_fails=True); response = client.get("/api/v1/health/readiness")
    elif line == 721:
        client, _ = _client(settings, dependency_factory); response = client.post("/api/v1/newsletter-status-queries", data=b"{", content_type="application/json")
    elif line == 725:
        client, _ = _client(settings, dependency_factory); response = client.post("/api/v1/newsletter-status-queries", data=json.dumps(EXAMPLE_BY_LINE[501]), content_type="text/plain")
    elif line == 729:
        client, _ = _client(settings, dependency_factory, RuntimeError("private")); response = client.post("/api/v1/newsletter-status-queries", json=EXAMPLE_BY_LINE[501])
    elif line == 735:
        client, _ = _client(settings, dependency_factory, NewsletterPreferenceOutcomeUnknown(0.0, 0.0, 1)); response = client.post("/api/v1/newsletter-preferences", json=EXAMPLE_BY_LINE[535])
    elif line == 739:
        client, _ = _client(settings, dependency_factory, ReservationServiceUnavailable()); response = client.get("/api/v1/reservation-context")
    elif line == 89:
        client, _ = _client(settings, dependency_factory); response = client.post("/api/v1/reservations", json=EXAMPLE_BY_LINE[567] | {"party_size": 0})
        assert response.status_code == 422
        _assert_illustrative_validation(response.get_json(), expected, "party_size", "out_of_range")
        return
    else:  # pragma: no cover - classification closure makes this unreachable
        raise AssertionError(f"No executable evidence for API-02 example at line {line}")

    actual = response.get_json()
    if line == 679:
        assert response.status_code == 422
        _assert_illustrative_validation(actual, expected, "utc_offset_minutes", "utc_offset_mismatch")
        return
    status = ERRORS[expected["error"]["code"]][0] if "error" in expected else 201 if expected.get("booking_result") == "created" else 200
    assert response.status_code == status
    assert actual == expected


def test_api02_all_36_json_examples_have_one_explicit_evidence_classification():
    assert len(EXAMPLES) == len(EXAMPLE_BY_LINE) == 36
    assert set(EXAMPLE_BY_LINE) == set(CLASSIFICATION)
    assert sum(role == "request" for role, _ in CLASSIFICATION.values()) == 3
    assert sum(role == "success-response" for role, _ in CLASSIFICATION.values()) == 17
    assert sum(role == "error-response" for role, _ in CLASSIFICATION.values()) == 16
    assert all(evidence.endswith(("request", "seam")) for _, evidence in CLASSIFICATION.values())


@pytest.mark.parametrize("example", EXAMPLES, ids=lambda item: f"line-{item.line}-{CLASSIFICATION[item.line][0]}-{CLASSIFICATION[item.line][1]}")
def test_api02_authoritative_example_has_executable_flask_evidence(example, settings, dependency_factory):
    _exercise(example, settings, dependency_factory)


def test_api02_public_error_inventory_exactly_matches_implementation_registry():
    text = CONTRACT.read_text(encoding="utf-8")
    catalogue = text.split("## 10. Public status and error catalogue", 1)[1].split("## 11. Retry, idempotency, timeout, and ambiguity semantics", 1)[0]
    rows = re.findall(r"^\| `([^`]+)` \| (\d+) \| Yes \| (true|false) / (true|false) \|", catalogue, flags=re.MULTILINE)
    approved = {code: (int(status), retryable == "true", unknown == "true") for code, status, retryable, unknown in rows}
    assert len(approved) == 19
    assert set(ERRORS) == set(approved)
    assert {code: (status, retryable, unknown) for code, (status, _message, retryable, unknown) in ERRORS.items()} == approved
