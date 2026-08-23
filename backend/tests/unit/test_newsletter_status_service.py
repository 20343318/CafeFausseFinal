from __future__ import annotations

import pytest

from cafe_fausse.db.exceptions import DatabaseContractError, DatabaseUnavailable
from cafe_fausse.services.newsletter_status import (
    NewsletterStatusIndeterminate,
    NewsletterStatusService,
)
from cafe_fausse.services.results import (
    CustomerIdentity,
    NewsletterStatusOutcome,
    NewsletterStatusResult,
)
from cafe_fausse.services.retry import RetryPolicy


IDENTITY = CustomerIdentity("Ada", None, "Rivera", "ada@example.com")
POLICY = RetryPolicy(3, 25, 200, 0.0, 100)


class Clock:
    def __init__(self):
        self.now = 0.0
        self.sleeps = []

    def __call__(self):
        return self.now

    def sleep(self, seconds):
        self.sleeps.append(seconds)
        self.now += seconds


class Gateway:
    def __init__(self, results):
        self.results = list(results)
        self.identities = []
        self.timeouts = []

    def get_newsletter_status(self, identity, timeout_seconds=None):
        self.identities.append(identity)
        self.timeouts.append(timeout_seconds)
        value = self.results.pop(0)
        if isinstance(value, Exception):
            raise value
        return value


def service(gateway, clock=None, observer=None):
    clock = clock or Clock()
    return NewsletterStatusService(
        gateway,
        deadline_ms=2000,
        retry_policy=POLICY,
        monotonic=clock,
        sleeper=clock.sleep,
        uniform=lambda *_: 1.0,
        retry_observer=observer,
    )


@pytest.mark.unit
@pytest.mark.parametrize(
    ("outcome", "subscribed"),
    [
        (NewsletterStatusOutcome.NOT_FOUND, None),
        (NewsletterStatusOutcome.MATCHED, True),
        (NewsletterStatusOutcome.MATCHED, False),
        (NewsletterStatusOutcome.CUSTOMER_IDENTITY_CONFLICT, None),
        (NewsletterStatusOutcome.MIDDLE_INITIAL_CONFLICT, None),
    ],
)
def test_ut_api05_service_preserves_every_expected_outcome(outcome, subscribed):
    gateway = Gateway([NewsletterStatusResult(outcome, subscribed, 1.0, 2.0)])
    result = service(gateway).lookup(IDENTITY)
    assert result == NewsletterStatusResult(outcome, subscribed, 1.0, 2.0)
    assert gateway.identities == [IDENTITY]
    assert not hasattr(IDENTITY, "confirmation_email")
    assert not hasattr(gateway, "create_customer")
    assert not hasattr(gateway, "set_preference")


@pytest.mark.unit
def test_ut_api05_service_retries_safe_read_with_new_attempt_and_accumulates_timings():
    failure = DatabaseUnavailable(
        sqlstate="08006", safe_to_retry=True, pool_wait_ms=3.0, database_ms=4.0
    )
    gateway = Gateway(
        [failure, NewsletterStatusResult(NewsletterStatusOutcome.MATCHED, True, 5.0, 6.0)]
    )
    clock = Clock()
    observed = []
    result = service(gateway, clock, observed.append).lookup(IDENTITY)
    assert result.pool_wait_ms == 8.0
    assert result.database_ms == 10.0
    assert len(gateway.identities) == 2
    assert observed == [2]
    assert clock.sleeps == [0.025]


@pytest.mark.unit
def test_ut_api05_service_exhaustion_and_nonretryable_read_are_indeterminate():
    retryable = DatabaseUnavailable(sqlstate="08006", safe_to_retry=True)
    with pytest.raises(NewsletterStatusIndeterminate):
        service(Gateway([retryable, retryable, retryable])).lookup(IDENTITY)
    nonretryable_gateway = Gateway(
        [DatabaseUnavailable(sqlstate="57014", safe_to_retry=False)]
    )
    with pytest.raises(NewsletterStatusIndeterminate):
        service(nonretryable_gateway).lookup(IDENTITY)
    assert len(nonretryable_gateway.identities) == 1


@pytest.mark.unit
def test_ut_api05_service_contract_failure_is_nonretryable_and_not_indeterminate():
    gateway = Gateway([DatabaseContractError()])
    with pytest.raises(DatabaseContractError):
        service(gateway).lookup(IDENTITY)
    assert len(gateway.identities) == 1


@pytest.mark.unit
def test_ut_api05_result_invariants_prevent_invalid_public_state():
    with pytest.raises(ValueError):
        NewsletterStatusResult(NewsletterStatusOutcome.MATCHED)
    with pytest.raises(ValueError):
        NewsletterStatusResult(NewsletterStatusOutcome.NOT_FOUND, True)
