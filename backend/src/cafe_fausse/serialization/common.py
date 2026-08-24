"""Pure common response projections first required by OP-03."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from ..services.results import (
    NewsletterPreferenceOutcome,
    NewsletterPreferenceResult,
    NewsletterStatusOutcome,
    NewsletterStatusResult,
)


@dataclass(frozen=True, slots=True)
class ResponseProjection:
    status: int
    payload: dict[str, Any] | None = None
    error_code: str | None = None
    fields: tuple[dict[str, str], ...] | None = None

    def __post_init__(self) -> None:
        if (self.payload is None) == (self.error_code is None):
            raise ValueError("response projection requires exactly one payload or error")
        if self.fields is not None and self.error_code != "validation_failed":
            raise ValueError("only validation failures may contain field errors")


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


def serialize_newsletter_preference(
    result: NewsletterPreferenceResult,
) -> ResponseProjection:
    if result.outcome in {
        NewsletterPreferenceOutcome.SUBSCRIBED,
        NewsletterPreferenceOutcome.UNSUBSCRIBED,
    }:
        return ResponseProjection(200, {"result": "set", "subscribed": result.subscribed})
    if result.outcome is NewsletterPreferenceOutcome.NO_CUSTOMER_NO_CHANGE:
        return ResponseProjection(
            200,
            {"result": "no_customer_no_change", "subscribed": False},
        )
    if result.outcome is NewsletterPreferenceOutcome.CUSTOMER_IDENTITY_CONFLICT:
        return ResponseProjection(409, error_code="customer_identity_conflict")
    if result.outcome is NewsletterPreferenceOutcome.MIDDLE_INITIAL_CONFLICT:
        return ResponseProjection(409, error_code="middle_initial_conflict")
    if result.outcome is NewsletterPreferenceOutcome.INVALID_REQUEST:
        fields = tuple(
            {
                "field": field,
                "code": "invalid_value",
                "message": "The submitted value was not accepted.",
            }
            for field in (
                "first_name",
                "middle_initial",
                "last_name",
                "email",
                "confirmation_email",
                "subscribed",
            )
        )
        return ResponseProjection(422, error_code="validation_failed", fields=fields)
    raise ValueError("unknown newsletter-preference outcome")
