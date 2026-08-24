"""Typed operation values and exhaustive internal outcomes."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime, time
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


class NewsletterPreferenceOutcome(StrEnum):
    SUBSCRIBED = "subscribed"
    UNSUBSCRIBED = "unsubscribed"
    NO_CUSTOMER_NO_CHANGE = "no_customer_no_change"
    INVALID_REQUEST = "invalid_request"
    CUSTOMER_IDENTITY_CONFLICT = "customer_identity_conflict"
    MIDDLE_INITIAL_CONFLICT = "middle_initial_conflict"


class AvailabilityOutcome(StrEnum):
    SLOTS = "slots"
    INVALID_REQUEST = "invalid_request"


@dataclass(frozen=True, slots=True)
class CustomerIdentity:
    first_name: str = field(repr=False)
    middle_initial: str | None = field(repr=False)
    last_name: str = field(repr=False)
    email: str = field(repr=False)


@dataclass(frozen=True, slots=True)
class NewsletterPreferenceCommand:
    first_name: str = field(repr=False)
    middle_initial: str | None = field(repr=False)
    last_name: str = field(repr=False)
    email: str = field(repr=False)
    subscribed: bool = field(repr=False)

    def __post_init__(self) -> None:
        if type(self.subscribed) is not bool:
            raise ValueError("newsletter preference requires a Boolean state")


@dataclass(frozen=True, slots=True)
class NewsletterPreferenceResult:
    outcome: NewsletterPreferenceOutcome
    subscribed: bool | None = None
    pool_wait_ms: float = 0.0
    database_ms: float = 0.0
    attempts: int = 1
    cleanup_failed: bool = False

    def __post_init__(self) -> None:
        expected_state = {
            NewsletterPreferenceOutcome.SUBSCRIBED: True,
            NewsletterPreferenceOutcome.UNSUBSCRIBED: False,
            NewsletterPreferenceOutcome.NO_CUSTOMER_NO_CHANGE: False,
        }.get(self.outcome)
        if expected_state is None:
            if self.subscribed is not None:
                raise ValueError("a non-success preference result cannot contain state")
        elif self.subscribed is not expected_state:
            raise ValueError("preference outcome and state contradict each other")
        if self.pool_wait_ms < 0 or self.database_ms < 0:
            raise ValueError("newsletter-preference timings cannot be negative")
        if not 1 <= self.attempts <= 3:
            raise ValueError("newsletter preference attempts must be between one and three")
        if type(self.cleanup_failed) is not bool:
            raise ValueError("newsletter preference cleanup status must be Boolean")


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
class WeekdayHours:
    iso_weekday: int
    opens_at_local: time
    closes_at_local: time


@dataclass(frozen=True, slots=True)
class ReservationContextResult:
    restaurant_timezone: str
    weekday_hours: tuple[WeekdayHours, ...]
    start_interval_minutes: int
    reservation_duration_minutes: int
    advance_window_days: int
    same_day_lead_minutes: int
    minimum_local_date: date
    maximum_local_date: date
    maximum_party_size: int
    pool_wait_ms: float = 0.0
    database_ms: float = 0.0


@dataclass(frozen=True, slots=True)
class AvailabilityRequest:
    local_date: date
    party_size: int


@dataclass(frozen=True, slots=True)
class AvailabilitySlot:
    local_start: datetime
    starts_at: datetime
    ends_at: datetime
    available: bool


@dataclass(frozen=True, slots=True)
class ReservationAvailabilityResult:
    outcome: AvailabilityOutcome
    request: AvailabilityRequest
    restaurant_timezone: str | None = None
    slots: tuple[AvailabilitySlot, ...] = ()
    pool_wait_ms: float = 0.0
    database_ms: float = 0.0


@dataclass(frozen=True, slots=True)
class LiveResult:
    live: bool = True


@dataclass(frozen=True, slots=True)
class ReadinessResult:
    ready: bool
    category: ReadinessCategory | None = None
    pool_wait_ms: float = 0.0
    database_ms: float = 0.0
