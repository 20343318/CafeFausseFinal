from datetime import datetime, timedelta, timezone

import pytest

from cafe_fausse.db.exceptions import DatabaseMutationFailure, ReservationConfirmationFailure
from cafe_fausse.services.reservations import (
    ReservationConfirmationUnavailable,
    ReservationOutcomeUnknown,
    ReservationService,
    ReservationServiceUnavailable,
    ReservationTemporaryFailure,
)
from cafe_fausse.services.results import BookingOutcome, ReservationBookingResult, ReservationCommand
from cafe_fausse.services.retry import RetryPolicy


pytestmark = pytest.mark.unit


class Clock:
    def __init__(self): self.value = 0.0
    def __call__(self): return self.value
    def sleep(self, seconds): self.value += seconds


class Gateway:
    def __init__(self, values): self.values = list(values); self.calls = []
    def book(self, command, timeout_seconds=None):
        self.calls.append((command, timeout_seconds))
        value = self.values.pop(0)
        if isinstance(value, Exception): raise value
        return value


COMMAND = ReservationCommand("Ada", None, "Rivera", "ada@example.test", None, datetime(2026, 9, 12, 17), -240, 4, "no_change")
POLICY = RetryPolicy(3, 10, 50, 0.0, 100)


def success():
    start = datetime(2026, 9, 12, 21, tzinfo=timezone.utc)
    return ReservationBookingResult(
        BookingOutcome.BOOKED, reservation_id=1, starts_at=start,
        ends_at=start + timedelta(minutes=90), party_size=4,
        assigned_table_numbers=(3,), newsletter_subscribed=False,
        customer_name="Ada Rivera", restaurant_timezone="America/New_York",
    )


def service(gateway, clock=None):
    clock = clock or Clock()
    return ReservationService(gateway, deadline_ms=15000, retry_policy=POLICY, monotonic=clock, sleeper=clock.sleep, uniform=lambda *_: 1.0)


@pytest.mark.parametrize("sqlstate", ["55P03", "40P01", "40001"])
def test_booking_retries_only_approved_known_rollback_classes(sqlstate):
    failure = DatabaseMutationFailure(sqlstate=sqlstate, safe_to_retry=True, mutation_dispatched=True, outcome_unknown=False)
    gateway = Gateway([failure, success()])
    result = service(gateway).book(COMMAND)
    assert result.attempts == 2 and len(gateway.calls) == 2


def test_booking_unknown_outcome_is_never_automatically_retried():
    failure = DatabaseMutationFailure(sqlstate="08006", safe_to_retry=False, mutation_dispatched=True, outcome_unknown=True)
    gateway = Gateway([failure])
    with pytest.raises(ReservationOutcomeUnknown): service(gateway).book(COMMAND)
    assert len(gateway.calls) == 1


def test_known_rollback_exhaustion_is_temporary_failure():
    failures = [DatabaseMutationFailure(sqlstate="55P03", safe_to_retry=True, mutation_dispatched=True, outcome_unknown=False) for _ in range(3)]
    with pytest.raises(ReservationTemporaryFailure): service(Gateway(failures)).book(COMMAND)


def test_post_commit_name_failure_is_known_confirmation_failure():
    gateway = Gateway([ReservationConfirmationFailure(pool_wait_ms=1, database_ms=2)])
    with pytest.raises(ReservationConfirmationUnavailable) as raised: service(gateway).book(COMMAND)
    assert raised.value.attempts == 1


def test_reconciled_server_duration_outcome_maps_to_service_unavailable_without_heuristic():
    result = ReservationBookingResult(
        BookingOutcome.INVALID_DATABASE_CONFIGURATION,
        detail_code="duration_or_party_size_out_of_range",
    )
    gateway = Gateway([result])
    with pytest.raises(ReservationServiceUnavailable) as raised:
        service(gateway).book(COMMAND)
    assert raised.value.attempts == 1
    assert len(gateway.calls) == 1
