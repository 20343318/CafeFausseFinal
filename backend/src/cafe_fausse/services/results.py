"""Typed operation values and exhaustive internal outcomes."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum


class ReadinessCategory(StrEnum):
    POOL = "pool"
    PLATFORM = "platform"
    CONTRACT = "contract"
    FOUNDATION = "foundation"


class NewsletterStatusOutcome(StrEnum):
    MATCHED = "matched"
    NOT_FOUND = "not_found"
    CUSTOMER_IDENTITY_CONFLICT = "customer_identity_conflict"
    MIDDLE_INITIAL_CONFLICT = "middle_initial_conflict"


@dataclass(frozen=True, slots=True)
class CustomerIdentity:
    first_name: str = field(repr=False)
    middle_initial: str | None = field(repr=False)
    last_name: str = field(repr=False)
    email: str = field(repr=False)


@dataclass(frozen=True, slots=True)
class NewsletterStatusResult:
    outcome: NewsletterStatusOutcome
    subscribed: bool | None = None
    pool_wait_ms: float = 0.0
    database_ms: float = 0.0

    def __post_init__(self) -> None:
        if self.outcome is NewsletterStatusOutcome.MATCHED:
            if type(self.subscribed) is not bool:
                raise ValueError("matched newsletter status requires a Boolean state")
        elif self.subscribed is not None:
            raise ValueError("only a matched newsletter status may contain a Boolean state")
        if self.pool_wait_ms < 0 or self.database_ms < 0:
            raise ValueError("newsletter-status timings cannot be negative")


@dataclass(frozen=True, slots=True)
class LiveResult:
    live: bool = True


@dataclass(frozen=True, slots=True)
class ReadinessResult:
    ready: bool
    category: ReadinessCategory | None = None
    pool_wait_ms: float = 0.0
    database_ms: float = 0.0
