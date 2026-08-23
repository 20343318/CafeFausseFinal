"""OP-03 read-only newsletter-status orchestration."""

from __future__ import annotations

from dataclasses import replace
from typing import Callable, Protocol

from ..db.exceptions import DatabaseContractError, DatabaseUnavailable
from .results import CustomerIdentity, NewsletterStatusResult
from .retry import AttemptFailure, RetryPolicy, execute_with_retry


class NewsletterStatusGateway(Protocol):
    def get_newsletter_status(
        self, identity: CustomerIdentity, timeout_seconds: float | None = None
    ) -> NewsletterStatusResult: ...


class NewsletterStatusIndeterminate(Exception):
    def __init__(self, pool_wait_ms: float = 0.0, database_ms: float = 0.0) -> None:
        super().__init__("newsletter status indeterminate")
        self.pool_wait_ms = pool_wait_ms
        self.database_ms = database_ms


class NewsletterStatusService:
    def __init__(
        self,
        gateway: NewsletterStatusGateway,
        *,
        deadline_ms: int,
        retry_policy: RetryPolicy,
        monotonic: Callable[[], float],
        sleeper: Callable[[float], None],
        uniform: Callable[[float, float], float],
        retry_observer: Callable[[int], None] | None = None,
    ) -> None:
        self._gateway = gateway
        self._deadline_ms = deadline_ms
        self._retry_policy = retry_policy
        self._monotonic = monotonic
        self._sleeper = sleeper
        self._uniform = uniform
        self._retry_observer = retry_observer

    def lookup(self, identity: CustomerIdentity) -> NewsletterStatusResult:
        pool_wait_ms = 0.0
        database_ms = 0.0

        def attempt(number: int, remaining: float) -> NewsletterStatusResult:
            nonlocal pool_wait_ms, database_ms
            if number > 1 and self._retry_observer is not None:
                self._retry_observer(number)
            try:
                result = self._gateway.get_newsletter_status(identity, remaining)
            except DatabaseUnavailable as error:
                pool_wait_ms += error.pool_wait_ms
                database_ms += error.database_ms
                raise AttemptFailure(
                    sqlstate=error.sqlstate,
                    safe_to_retry=error.safe_to_retry,
                    mutation_dispatched=False,
                ) from error
            pool_wait_ms += result.pool_wait_ms
            database_ms += result.database_ms
            return replace(result, pool_wait_ms=pool_wait_ms, database_ms=database_ms)

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
            raise NewsletterStatusIndeterminate(pool_wait_ms, database_ms) from error
        except DatabaseContractError:
            raise
