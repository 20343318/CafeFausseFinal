from __future__ import annotations

import pytest

from cafe_fausse.db.exceptions import (
    DatabaseContractError,
    DatabaseMutationFailure,
)
from cafe_fausse.services.newsletter_preferences import (
    NewsletterPreferenceOutcomeUnknown,
    NewsletterPreferenceService,
    NewsletterPreferenceTemporaryFailure,
)
from cafe_fausse.services.results import (
    NewsletterPreferenceCommand,
    NewsletterPreferenceOutcome,
    NewsletterPreferenceResult,
)
from cafe_fausse.services.retry import RetryPolicy


COMMAND = NewsletterPreferenceCommand("Ada", None, "Rivera", "ada@example.com", True)
POLICY = RetryPolicy(3, 25, 200, 0.25, 500)


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
    def __init__(self, values):
        self.values = list(values)
        self.calls = []

    def set_preference(self, command, timeout_seconds=None):
        self.calls.append((command, timeout_seconds))
        value = self.values.pop(0)
        if isinstance(value, Exception):
            raise value
        return value


def service(
    gateway,
    clock=None,
    observer=None,
    deadline_ms=15000,
    cleanup_observer=None,
):
    clock = clock or Clock()
    return NewsletterPreferenceService(
        gateway,
        deadline_ms=deadline_ms,
        retry_policy=POLICY,
        monotonic=clock,
        sleeper=clock.sleep,
        uniform=lambda *_: 1.0,
        retry_observer=observer,
        cleanup_failure_observer=cleanup_observer,
    )


@pytest.mark.unit
@pytest.mark.parametrize(
    ("outcome", "subscribed"),
    [
        (NewsletterPreferenceOutcome.SUBSCRIBED, True),
        (NewsletterPreferenceOutcome.UNSUBSCRIBED, False),
        (NewsletterPreferenceOutcome.NO_CUSTOMER_NO_CHANGE, False),
        (NewsletterPreferenceOutcome.INVALID_REQUEST, None),
        (NewsletterPreferenceOutcome.CUSTOMER_IDENTITY_CONFLICT, None),
        (NewsletterPreferenceOutcome.MIDDLE_INITIAL_CONFLICT, None),
    ],
)
def test_ut_api06_service_preserves_typed_database_outcomes(outcome, subscribed):
    gateway = Gateway([NewsletterPreferenceResult(outcome, subscribed, 2.0, 3.0)])
    result = service(gateway).set_preference(COMMAND)
    assert (result.outcome, result.subscribed, result.attempts) == (outcome, subscribed, 1)
    assert (result.pool_wait_ms, result.database_ms) == (2.0, 3.0)
    assert gateway.calls[0][0] is COMMAND


@pytest.mark.unit
@pytest.mark.parametrize("sqlstate", ["55P03", "40P01", "40001"])
def test_ut_api06_service_retries_only_approved_rolled_back_mutations(sqlstate):
    failure = DatabaseMutationFailure(
        sqlstate=sqlstate,
        safe_to_retry=True,
        mutation_dispatched=True,
        outcome_unknown=False,
        pool_wait_ms=1.0,
        database_ms=2.0,
    )
    gateway = Gateway(
        [
            failure,
            failure,
            NewsletterPreferenceResult(
                NewsletterPreferenceOutcome.SUBSCRIBED, True, 3.0, 4.0
            ),
        ]
    )
    clock = Clock()
    observed = []
    result = service(gateway, clock, observed.append).set_preference(COMMAND)
    assert result.attempts == 3
    assert (result.pool_wait_ms, result.database_ms) == (5.0, 8.0)
    assert clock.sleeps == [0.025, 0.05]
    assert observed == [2, 3]
    assert len({id(call[0]) for call in gateway.calls}) == 1


@pytest.mark.unit
def test_ut_api06_service_max_three_attempts_maps_known_temporary_failure():
    failure = DatabaseMutationFailure(
        sqlstate="55P03",
        safe_to_retry=True,
        mutation_dispatched=True,
        outcome_unknown=False,
        pool_wait_ms=1.0,
        database_ms=2.0,
    )
    gateway = Gateway([failure, failure, failure])
    with pytest.raises(NewsletterPreferenceTemporaryFailure) as raised:
        service(gateway).set_preference(COMMAND)
    assert raised.value.attempts == 3
    assert len(gateway.calls) == 3


@pytest.mark.unit
@pytest.mark.parametrize(
    "failure",
    [
        DatabaseMutationFailure(
            sqlstate=None,
            safe_to_retry=False,
            mutation_dispatched=False,
            outcome_unknown=False,
        ),
        DatabaseMutationFailure(
            sqlstate="57014",
            safe_to_retry=False,
            mutation_dispatched=True,
            outcome_unknown=False,
        ),
    ],
)
def test_ut_api06_service_known_failures_are_temporary(failure):
    gateway = Gateway([failure])
    with pytest.raises(NewsletterPreferenceTemporaryFailure) as raised:
        service(gateway).set_preference(COMMAND)
    assert raised.value.attempts == 1
    assert len(gateway.calls) == 1


@pytest.mark.unit
def test_ut_api06_service_unknown_outcome_never_retries():
    primary = RuntimeError("private driver and cleanup detail")
    failure = DatabaseMutationFailure(
        sqlstate="08006",
        safe_to_retry=False,
        mutation_dispatched=True,
        outcome_unknown=True,
        cleanup_failed=True,
    )
    failure.__cause__ = primary
    gateway = Gateway([failure])
    with pytest.raises(NewsletterPreferenceOutcomeUnknown) as raised:
        service(gateway).set_preference(COMMAND)
    assert raised.value.attempts == 1
    assert raised.value.cleanup_failed is True
    assert len(gateway.calls) == 1
    attempt_failure = raised.value.__cause__
    assert attempt_failure is not None
    assert attempt_failure.__cause__ is failure
    assert failure.__cause__ is primary


@pytest.mark.unit
def test_ut_api06_service_retains_cleanup_failure_on_known_temporary_boundary():
    failure = DatabaseMutationFailure(
        sqlstate=None,
        safe_to_retry=False,
        mutation_dispatched=False,
        outcome_unknown=False,
        cleanup_failed=True,
    )
    gateway = Gateway([failure])
    with pytest.raises(NewsletterPreferenceTemporaryFailure) as raised:
        service(gateway).set_preference(COMMAND)
    assert raised.value.cleanup_failed is True
    assert raised.value.attempts == 1
    assert len(gateway.calls) == 1


@pytest.mark.unit
def test_ut_api06_service_deadline_exhausted_after_sleep_dispatches_no_next_attempt():
    failure = DatabaseMutationFailure(
        sqlstate="55P03",
        safe_to_retry=True,
        mutation_dispatched=True,
        outcome_unknown=False,
    )
    gateway = Gateway([failure, NewsletterPreferenceResult(NewsletterPreferenceOutcome.SUBSCRIBED, True)])
    clock = Clock()

    def oversleep(seconds):
        clock.sleeps.append(seconds)
        clock.now += seconds + 0.6

    instance = NewsletterPreferenceService(
        gateway,
        deadline_ms=1000,
        retry_policy=POLICY,
        monotonic=clock,
        sleeper=oversleep,
        uniform=lambda *_: 1.0,
    )
    with pytest.raises(NewsletterPreferenceTemporaryFailure):
        instance.set_preference(COMMAND)
    assert len(gateway.calls) == 1


@pytest.mark.unit
def test_ut_api06_service_contract_defect_is_not_translated():
    gateway = Gateway([DatabaseContractError()])
    with pytest.raises(DatabaseContractError):
        service(gateway).set_preference(COMMAND)


@pytest.mark.unit
def test_ut_api06_service_confirmed_result_cleanup_failure_is_reported_without_retry():
    gateway = Gateway(
        [
            NewsletterPreferenceResult(
                NewsletterPreferenceOutcome.SUBSCRIBED,
                True,
                cleanup_failed=True,
            )
        ]
    )
    observed = []

    result = service(gateway, cleanup_observer=lambda: observed.append(True)).set_preference(
        COMMAND
    )

    assert result.outcome is NewsletterPreferenceOutcome.SUBSCRIBED
    assert result.cleanup_failed is True
    assert result.attempts == 1
    assert len(gateway.calls) == 1
    assert observed == [True]


@pytest.mark.unit
def test_ut_api06_service_retains_prior_cleanup_failure_after_safe_retry():
    failure = DatabaseMutationFailure(
        sqlstate="55P03",
        safe_to_retry=True,
        mutation_dispatched=True,
        outcome_unknown=False,
        cleanup_failed=True,
    )
    gateway = Gateway(
        [
            failure,
            NewsletterPreferenceResult(NewsletterPreferenceOutcome.SUBSCRIBED, True),
        ]
    )
    observed = []

    result = service(gateway, cleanup_observer=lambda: observed.append(True)).set_preference(
        COMMAND
    )

    assert result.cleanup_failed is True
    assert result.attempts == 2
    assert len(gateway.calls) == 2
    assert observed == [True]


@pytest.mark.unit
def test_ut_api06_service_contract_cleanup_failure_remains_primary_and_is_reported():
    primary = DatabaseContractError(cleanup_failed=True)
    gateway = Gateway([primary])
    observed = []

    with pytest.raises(DatabaseContractError) as raised:
        service(gateway, cleanup_observer=lambda: observed.append(True)).set_preference(
            COMMAND
        )

    assert raised.value is primary
    assert raised.value.cleanup_failed is True
    assert len(gateway.calls) == 1
    assert observed == [True]
