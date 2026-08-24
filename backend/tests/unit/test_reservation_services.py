from dataclasses import replace
from datetime import date

import pytest

from cafe_fausse.db.exceptions import DatabaseContractError, DatabaseUnavailable
from cafe_fausse.services.reservation_availability import ReservationAvailabilityService
from cafe_fausse.services.reservation_context import ReservationContextService, ReservationServiceUnavailable
from cafe_fausse.services.results import AvailabilityOutcome, AvailabilityRequest, ReservationAvailabilityResult, ReservationContextResult
from cafe_fausse.services.retry import RetryPolicy


pytestmark = pytest.mark.unit
POLICY = RetryPolicy(3, 10, 50, 0.0, 100)


class Clock:
    def __init__(self): self.value = 0.0
    def __call__(self): return self.value
    def sleep(self, seconds): self.value += seconds


class Gateway:
    def __init__(self, results): self.results = list(results); self.calls = []
    def get_context(self, timeout_seconds=None):
        self.calls.append(timeout_seconds)
        result = self.results.pop(0)
        if isinstance(result, Exception): raise result
        return result
    def get_availability(self, request, timeout_seconds=None):
        self.calls.append((request, timeout_seconds))
        result = self.results.pop(0)
        if isinstance(result, Exception): raise result
        return result


def context_result():
    return ReservationContextResult("America/New_York", (), 30, 90, 60, 120, date(2026, 8, 23), date(2026, 10, 22), 120, 1.0, 2.0)


@pytest.mark.parametrize("sqlstate", ["55P03", "40P01", "40001", "08006"])
def test_context_read_retries_transient_failure_with_fresh_gateway_attempt(sqlstate):
    clock = Clock(); retries = []
    gateway = Gateway([DatabaseUnavailable(sqlstate=sqlstate, safe_to_retry=True, pool_wait_ms=3, database_ms=4), context_result()])
    service = ReservationContextService(gateway, deadline_ms=2000, retry_policy=POLICY, monotonic=clock, sleeper=clock.sleep, uniform=lambda *_: 1.0, retry_observer=retries.append)
    result = service.get()
    assert len(gateway.calls) == 2 and retries == [2]
    assert (result.pool_wait_ms, result.database_ms) == (4.0, 6.0)


@pytest.mark.parametrize("error", [DatabaseContractError(pool_wait_ms=3, database_ms=4), DatabaseUnavailable(sqlstate="57014", safe_to_retry=False)])
def test_context_contract_or_nonretryable_failure_maps_to_service_unavailable(error):
    clock = Clock(); service = ReservationContextService(Gateway([error]), deadline_ms=2000, retry_policy=POLICY, monotonic=clock, sleeper=clock.sleep, uniform=lambda *_: 1.0)
    with pytest.raises(ReservationServiceUnavailable) as raised: service.get()
    if isinstance(error, DatabaseContractError):
        assert (raised.value.pool_wait_ms, raised.value.database_ms) == (3, 4)


def test_availability_retries_read_only_and_preserves_request():
    clock = Clock(); request = AvailabilityRequest(date(2026, 9, 12), 4)
    expected = ReservationAvailabilityResult(AvailabilityOutcome.SLOTS, request, "America/New_York")
    gateway = Gateway([DatabaseUnavailable(sqlstate="55P03", safe_to_retry=True), expected])
    service = ReservationAvailabilityService(gateway, deadline_ms=2000, retry_policy=POLICY, monotonic=clock, sleeper=clock.sleep, uniform=lambda *_: 1.0)
    assert service.get(request).request == request
    assert len(gateway.calls) == 2


def test_availability_read_retry_stops_after_three_fresh_attempts():
    clock = Clock(); request = AvailabilityRequest(date(2026, 9, 12), 4)
    failures = [DatabaseUnavailable(sqlstate="40001", safe_to_retry=True) for _ in range(3)]
    gateway = Gateway(failures)
    service = ReservationAvailabilityService(gateway, deadline_ms=2000, retry_policy=POLICY, monotonic=clock, sleeper=clock.sleep, uniform=lambda *_: 1.0)
    with pytest.raises(ReservationServiceUnavailable):
        service.get(request)
    assert len(gateway.calls) == 3
    assert all(call[0] == request for call in gateway.calls)


@pytest.mark.parametrize(
    "error",
    [
        DatabaseContractError(pool_wait_ms=1, database_ms=2),
        DatabaseUnavailable(sqlstate="57014", safe_to_retry=False),
    ],
)
def test_availability_contract_and_nonretryable_failures_are_not_retried(error):
    request = AvailabilityRequest(date(2026, 9, 12), 4)
    gateway = Gateway([error])
    service = ReservationAvailabilityService(gateway, deadline_ms=2000, retry_policy=POLICY, monotonic=Clock(), sleeper=lambda _seconds: None, uniform=lambda *_: 1.0)
    with pytest.raises(ReservationServiceUnavailable):
        service.get(request)
    assert len(gateway.calls) == 1
