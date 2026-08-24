"""Immutable application-local dependency container."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Protocol

from .config import Settings
from .services.health import LivenessService, ReadinessService
from .services.results import AvailabilityRequest, CustomerIdentity, NewsletterStatusResult
from .services.results import NewsletterPreferenceCommand, NewsletterPreferenceResult
from .services.results import ReservationAvailabilityResult, ReservationBookingResult, ReservationCommand, ReservationContextResult


class Closeable(Protocol):
    def close(self, timeout: float = 5.0) -> None: ...


class NewsletterStatusOperation(Protocol):
    def lookup(self, identity: CustomerIdentity) -> NewsletterStatusResult: ...


class NewsletterPreferenceOperation(Protocol):
    def set_preference(
        self, command: NewsletterPreferenceCommand
    ) -> NewsletterPreferenceResult: ...


class ReservationContextOperation(Protocol):
    def get(self) -> ReservationContextResult: ...


class ReservationAvailabilityOperation(Protocol):
    def get(self, request: AvailabilityRequest) -> ReservationAvailabilityResult: ...


class ReservationOperation(Protocol):
    def book(self, command: ReservationCommand) -> ReservationBookingResult: ...


@dataclass(frozen=True, slots=True)
class Dependencies:
    settings: Settings
    liveness_service: LivenessService
    readiness_service: ReadinessService
    monotonic: Callable[[], float]
    correlation_id_factory: Callable[[], str]
    newsletter_status_service: NewsletterStatusOperation | None = None
    newsletter_preference_service: NewsletterPreferenceOperation | None = None
    reservation_context_service: ReservationContextOperation | None = None
    reservation_availability_service: ReservationAvailabilityOperation | None = None
    reservation_service: ReservationOperation | None = None
    resource: Closeable | None = None
