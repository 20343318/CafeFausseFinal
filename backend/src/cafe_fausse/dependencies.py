"""Immutable application-local dependency container."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Protocol

from .config import Settings
from .services.health import LivenessService, ReadinessService
from .services.results import CustomerIdentity, NewsletterStatusResult


class Closeable(Protocol):
    def close(self, timeout: float = 5.0) -> None: ...


class NewsletterStatusOperation(Protocol):
    def lookup(self, identity: CustomerIdentity) -> NewsletterStatusResult: ...


@dataclass(frozen=True, slots=True)
class Dependencies:
    settings: Settings
    liveness_service: LivenessService
    readiness_service: ReadinessService
    monotonic: Callable[[], float]
    correlation_id_factory: Callable[[], str]
    newsletter_status_service: NewsletterStatusOperation | None = None
    resource: Closeable | None = None
