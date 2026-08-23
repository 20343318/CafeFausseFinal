"""Pure common response projections first required by OP-03."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from ..services.results import NewsletterStatusOutcome, NewsletterStatusResult


@dataclass(frozen=True, slots=True)
class ResponseProjection:
    status: int
    payload: dict[str, Any] | None = None
    error_code: str | None = None

    def __post_init__(self) -> None:
        if (self.payload is None) == (self.error_code is None):
            raise ValueError("response projection requires exactly one payload or error")


def serialize_newsletter_status(result: NewsletterStatusResult) -> ResponseProjection:
    if result.outcome is NewsletterStatusOutcome.MATCHED:
        return ResponseProjection(200, {"status": "matched", "subscribed": result.subscribed})
    if result.outcome is NewsletterStatusOutcome.NOT_FOUND:
        return ResponseProjection(200, {"status": "not_found"})
    if result.outcome is NewsletterStatusOutcome.CUSTOMER_IDENTITY_CONFLICT:
        return ResponseProjection(409, error_code="customer_identity_conflict")
    if result.outcome is NewsletterStatusOutcome.MIDDLE_INITIAL_CONFLICT:
        return ResponseProjection(409, error_code="middle_initial_conflict")
    raise ValueError("unknown newsletter-status outcome")
