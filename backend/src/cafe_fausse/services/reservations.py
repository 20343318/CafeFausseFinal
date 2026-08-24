"""OP-05 reservation orchestration, retry, and certainty mapping."""

from __future__ import annotations

from dataclasses import replace
from typing import Callable, Protocol

from ..db.exceptions import DatabaseContractError, DatabaseMutationFailure, ReservationConfirmationFailure
from .results import BookingOutcome, ReservationBookingResult, ReservationCommand
from .retry import AttemptFailure, RetryPolicy, execute_with_retry


class ReservationGatewayProtocol(Protocol):
    def book(self, command: ReservationCommand, timeout_seconds: float | None = None) -> ReservationBookingResult: ...


class ReservationTemporaryFailure(Exception):
    pass


class ReservationOutcomeUnknown(Exception):
    pass


class ReservationConfirmationUnavailable(Exception):
    pass


class ReservationServiceUnavailable(Exception):
    pass


def _failure(error_type, pool_wait_ms, database_ms, attempts, cleanup_failed):
    error = error_type("reservation operation failed")
    error.pool_wait_ms = pool_wait_ms
    error.database_ms = database_ms
    error.attempts = attempts
    error.cleanup_failed = cleanup_failed
    return error


class ReservationService:
    def __init__(self, gateway: ReservationGatewayProtocol, *, deadline_ms: int, retry_policy: RetryPolicy, monotonic: Callable[[], float], sleeper: Callable[[float], None], uniform: Callable[[float, float], float], retry_observer: Callable[[int], None] | None = None, cleanup_failure_observer: Callable[[], None] | None = None) -> None:
        self._gateway = gateway
        self._deadline_ms = deadline_ms
        self._retry_policy = retry_policy
        self._monotonic = monotonic
        self._sleeper = sleeper
        self._uniform = uniform
        self._retry_observer = retry_observer
        self._cleanup_failure_observer = cleanup_failure_observer

    def book(self, command: ReservationCommand) -> ReservationBookingResult:
        pool_wait_ms = 0.0
        database_ms = 0.0
        attempts = 0
        cleanup_failed = False

        def attempt(number: int, remaining: float) -> ReservationBookingResult:
            nonlocal pool_wait_ms, database_ms, attempts, cleanup_failed
            attempts = number
            if number > 1 and self._retry_observer is not None:
                self._retry_observer(number)
            try:
                result = self._gateway.book(command, remaining)
            except DatabaseMutationFailure as error:
                pool_wait_ms += error.pool_wait_ms
                database_ms += error.database_ms
                cleanup_failed = cleanup_failed or error.cleanup_failed
                raise AttemptFailure(sqlstate=error.sqlstate, safe_to_retry=error.safe_to_retry, mutation_dispatched=error.mutation_dispatched, outcome_unknown=error.outcome_unknown) from error
            except ReservationConfirmationFailure as error:
                pool_wait_ms += error.pool_wait_ms
                database_ms += error.database_ms
                cleanup_failed = cleanup_failed or error.cleanup_failed
                raise _failure(ReservationConfirmationUnavailable, pool_wait_ms, database_ms, number, cleanup_failed) from error
            except DatabaseContractError as error:
                cleanup_failed = cleanup_failed or error.cleanup_failed
                if cleanup_failed and self._cleanup_failure_observer is not None:
                    self._cleanup_failure_observer()
                raise
            pool_wait_ms += result.pool_wait_ms
            database_ms += result.database_ms
            cleanup_failed = cleanup_failed or result.cleanup_failed
            completed = replace(result, pool_wait_ms=pool_wait_ms, database_ms=database_ms, attempts=number, cleanup_failed=cleanup_failed)
            if cleanup_failed and self._cleanup_failure_observer is not None:
                self._cleanup_failure_observer()
            if completed.outcome is BookingOutcome.INVALID_DATABASE_CONFIGURATION:
                raise _failure(ReservationServiceUnavailable, pool_wait_ms, database_ms, number, cleanup_failed)
            return completed

        try:
            return execute_with_retry(attempt, deadline_ms=self._deadline_ms, policy=self._retry_policy, monotonic=self._monotonic, sleeper=self._sleeper, uniform=self._uniform)
        except AttemptFailure as error:
            error_type = ReservationOutcomeUnknown if error.outcome_unknown else ReservationTemporaryFailure
            raise _failure(error_type, pool_wait_ms, database_ms, attempts, cleanup_failed) from error
