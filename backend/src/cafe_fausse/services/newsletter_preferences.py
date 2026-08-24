"""OP-04 preference orchestration and certainty mapping."""

from __future__ import annotations

from dataclasses import replace
from typing import Callable, Protocol

from ..db.exceptions import DatabaseContractError, DatabaseMutationFailure
from .results import NewsletterPreferenceCommand, NewsletterPreferenceResult
from .retry import AttemptFailure, RetryPolicy, execute_with_retry


class NewsletterPreferenceGateway(Protocol):
    def set_preference(
        self,
        command: NewsletterPreferenceCommand,
        timeout_seconds: float | None = None,
    ) -> NewsletterPreferenceResult: ...


class NewsletterPreferenceTemporaryFailure(Exception):
    def __init__(
        self,
        pool_wait_ms: float,
        database_ms: float,
        attempts: int,
        *,
        cleanup_failed: bool = False,
    ) -> None:
        super().__init__("newsletter preference temporary failure")
        self.pool_wait_ms = pool_wait_ms
        self.database_ms = database_ms
        self.attempts = attempts
        self.cleanup_failed = cleanup_failed


class NewsletterPreferenceOutcomeUnknown(Exception):
    def __init__(
        self,
        pool_wait_ms: float,
        database_ms: float,
        attempts: int,
        *,
        cleanup_failed: bool = False,
    ) -> None:
        super().__init__("newsletter preference outcome unknown")
        self.pool_wait_ms = pool_wait_ms
        self.database_ms = database_ms
        self.attempts = attempts
        self.cleanup_failed = cleanup_failed


class NewsletterPreferenceService:
    def __init__(
        self,
        gateway: NewsletterPreferenceGateway,
        *,
        deadline_ms: int,
        retry_policy: RetryPolicy,
        monotonic: Callable[[], float],
        sleeper: Callable[[float], None],
        uniform: Callable[[float, float], float],
        retry_observer: Callable[[int], None] | None = None,
        cleanup_failure_observer: Callable[[], None] | None = None,
    ) -> None:
        self._gateway = gateway
        self._deadline_ms = deadline_ms
        self._retry_policy = retry_policy
        self._monotonic = monotonic
        self._sleeper = sleeper
        self._uniform = uniform
        self._retry_observer = retry_observer
        self._cleanup_failure_observer = cleanup_failure_observer

    def set_preference(
        self, command: NewsletterPreferenceCommand
    ) -> NewsletterPreferenceResult:
        pool_wait_ms = 0.0
        database_ms = 0.0
        attempts = 0
        cleanup_failed = False

        def attempt(number: int, remaining: float) -> NewsletterPreferenceResult:
            nonlocal pool_wait_ms, database_ms, attempts, cleanup_failed
            attempts = number
            if number > 1 and self._retry_observer is not None:
                self._retry_observer(number)
            try:
                result = self._gateway.set_preference(command, remaining)
            except DatabaseMutationFailure as error:
                pool_wait_ms += error.pool_wait_ms
                database_ms += error.database_ms
                cleanup_failed = cleanup_failed or error.cleanup_failed
                raise AttemptFailure(
                    sqlstate=error.sqlstate,
                    safe_to_retry=error.safe_to_retry,
                    mutation_dispatched=error.mutation_dispatched,
                    outcome_unknown=error.outcome_unknown,
                ) from error
            except DatabaseContractError as error:
                if error.cleanup_failed and self._cleanup_failure_observer is not None:
                    self._cleanup_failure_observer()
                raise
            pool_wait_ms += result.pool_wait_ms
            database_ms += result.database_ms
            cleanup_failed = cleanup_failed or result.cleanup_failed
            completed = replace(
                result,
                pool_wait_ms=pool_wait_ms,
                database_ms=database_ms,
                attempts=number,
                cleanup_failed=cleanup_failed,
            )
            if completed.cleanup_failed and self._cleanup_failure_observer is not None:
                self._cleanup_failure_observer()
            return completed

        try:
            return execute_with_retry(
                attempt,
                deadline_ms=self._deadline_ms,
                policy=self._retry_policy,
                monotonic=self._monotonic,
                sleeper=self._sleeper,
                uniform=self._uniform,
            )
        except AttemptFailure as error:
            if error.outcome_unknown:
                raise NewsletterPreferenceOutcomeUnknown(
                    pool_wait_ms,
                    database_ms,
                    attempts,
                    cleanup_failed=cleanup_failed,
                ) from error
            raise NewsletterPreferenceTemporaryFailure(
                pool_wait_ms,
                database_ms,
                attempts,
                cleanup_failed=cleanup_failed,
            ) from error
        except DatabaseContractError:
            raise
