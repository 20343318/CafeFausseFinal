"""Bounded, deadline-aware retry scaffolding for later operation services."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, TypeVar

T = TypeVar("T")
_APPROVED_SQLSTATES = frozenset({"55P03", "40P01", "40001"})


@dataclass(frozen=True, slots=True)
class RetryPolicy:
    max_attempts: int
    base_delay_ms: int
    cap_delay_ms: int
    jitter_ratio: float
    min_remaining_ms: int


class AttemptFailure(Exception):
    def __init__(
        self,
        *,
        sqlstate: str | None = None,
        safe_to_retry: bool,
        mutation_dispatched: bool = False,
        outcome_unknown: bool = False,
    ) -> None:
        super().__init__("database attempt failed")
        self.sqlstate = sqlstate
        self.safe_to_retry = safe_to_retry
        self.mutation_dispatched = mutation_dispatched
        self.outcome_unknown = outcome_unknown

    @property
    def eligible(self) -> bool:
        if not self.safe_to_retry or self.outcome_unknown:
            return False
        if self.mutation_dispatched:
            return self.sqlstate in _APPROVED_SQLSTATES
        return (
            self.sqlstate is None
            or self.sqlstate in _APPROVED_SQLSTATES
            or self.sqlstate.startswith("08")
        )


def execute_with_retry(
    operation: Callable[[int, float], T],
    *,
    deadline_ms: int,
    policy: RetryPolicy,
    monotonic: Callable[[], float],
    sleeper: Callable[[float], None],
    uniform: Callable[[float, float], float],
) -> T:
    if not 1 <= policy.max_attempts <= 3:
        raise ValueError("retry attempts must be between one and three")
    deadline = monotonic() + deadline_ms / 1000
    attempt = 1
    retry_guard_failure: AttemptFailure | None = None
    while True:
        remaining = max(0.0, deadline - monotonic())
        if (
            attempt > 1
            and remaining * 1000 < policy.min_remaining_ms
        ):
            if retry_guard_failure is None:
                raise RuntimeError("retry deadline guard lost its failure context")
            raise retry_guard_failure
        try:
            return operation(attempt, remaining)
        except AttemptFailure as exc:
            if not exc.eligible or attempt >= policy.max_attempts:
                raise
            nominal_ms = min(policy.cap_delay_ms, policy.base_delay_ms * (2 ** (attempt - 1)))
            delay_ms = nominal_ms * uniform(1 - policy.jitter_ratio, 1 + policy.jitter_ratio)
            remaining_ms = (deadline - monotonic()) * 1000
            if remaining_ms - delay_ms < policy.min_remaining_ms:
                raise
            sleeper(delay_ms / 1000)
            post_sleep_remaining_ms = (deadline - monotonic()) * 1000
            if post_sleep_remaining_ms < policy.min_remaining_ms:
                raise
            retry_guard_failure = exc
            attempt += 1
