"""Typed foundational operation results."""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum


class ReadinessCategory(StrEnum):
    POOL = "pool"
    PLATFORM = "platform"
    CONTRACT = "contract"
    FOUNDATION = "foundation"


@dataclass(frozen=True, slots=True)
class LiveResult:
    live: bool = True


@dataclass(frozen=True, slots=True)
class ReadinessResult:
    ready: bool
    category: ReadinessCategory | None = None
    pool_wait_ms: float = 0.0
    database_ms: float = 0.0
