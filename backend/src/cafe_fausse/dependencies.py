"""Immutable application-local dependency container."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Protocol

from .config import Settings
from .services.health import LivenessService, ReadinessService


class Closeable(Protocol):
    def close(self, timeout: float = 5.0) -> None: ...


@dataclass(frozen=True, slots=True)
class Dependencies:
    settings: Settings
    liveness_service: LivenessService
    readiness_service: ReadinessService
    monotonic: Callable[[], float]
    correlation_id_factory: Callable[[], str]
    resource: Closeable | None = None
