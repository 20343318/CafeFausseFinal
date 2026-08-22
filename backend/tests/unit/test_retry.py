import pytest

from cafe_fausse.services.retry import AttemptFailure, RetryPolicy, execute_with_retry


class Clock:
    def __init__(self):
        self.now = 0.0
        self.sleeps = []
    def __call__(self):
        return self.now
    def sleep(self, seconds):
        self.sleeps.append(seconds)
        self.now += seconds


POLICY = RetryPolicy(3, 25, 200, 0.25, 500)


@pytest.mark.unit
@pytest.mark.parametrize("sqlstate", ["55P03", "40P01", "40001"])
def test_ut_api_retry_approved_states_new_attempts(sqlstate):
    clock = Clock()
    calls = []
    def operation(attempt, remaining):
        calls.append(attempt)
        if attempt < 3:
            raise AttemptFailure(sqlstate=sqlstate, safe_to_retry=True, mutation_dispatched=True)
        return "done"
    assert execute_with_retry(operation, deadline_ms=5000, policy=POLICY, monotonic=clock, sleeper=clock.sleep, uniform=lambda a, b: 1.0) == "done"
    assert calls == [1, 2, 3]
    assert clock.sleeps == [0.025, 0.05]


@pytest.mark.unit
def test_ut_api_retry_jitter_cap_deadline_and_exclusions():
    for jitter, expected in ((0.75, 0.01875), (1.25, 0.03125)):
        clock = Clock()
        calls = 0
        def operation(attempt, remaining):
            nonlocal calls
            calls += 1
            if attempt == 1:
                raise AttemptFailure(sqlstate="55P03", safe_to_retry=True, mutation_dispatched=True)
            return True
        execute_with_retry(operation, deadline_ms=5000, policy=POLICY, monotonic=clock, sleeper=clock.sleep, uniform=lambda a, b: jitter)
        assert clock.sleeps == [expected]
    for failure in (
        AttemptFailure(sqlstate="57014", safe_to_retry=True, mutation_dispatched=True),
        AttemptFailure(sqlstate="55P03", safe_to_retry=False, mutation_dispatched=True),
        AttemptFailure(sqlstate="55P03", safe_to_retry=True, mutation_dispatched=True, outcome_unknown=True),
    ):
        with pytest.raises(AttemptFailure):
            execute_with_retry(lambda *_: (_ for _ in ()).throw(failure), deadline_ms=5000, policy=POLICY, monotonic=lambda: 0.0, sleeper=lambda _: None, uniform=lambda *_: 1.0)
    with pytest.raises(AttemptFailure):
        execute_with_retry(lambda *_: (_ for _ in ()).throw(AttemptFailure(safe_to_retry=True)), deadline_ms=500, policy=POLICY, monotonic=lambda: 0.0, sleeper=lambda _: None, uniform=lambda *_: 1.0)


@pytest.mark.unit
def test_ut_api_retry_read_only_connection_loss_is_eligible():
    clock = Clock()
    calls = 0
    def operation(attempt, remaining):
        nonlocal calls
        calls += 1
        if attempt == 1:
            raise AttemptFailure(sqlstate="08006", safe_to_retry=True, mutation_dispatched=False)
        return "read-ok"
    assert execute_with_retry(operation, deadline_ms=5000, policy=POLICY, monotonic=clock, sleeper=clock.sleep, uniform=lambda *_: 1.0) == "read-ok"
    assert calls == 2
