"""OP-04 validation composed from the approved shared identity rules."""

from __future__ import annotations

from typing import Any

from ..services.results import NewsletterPreferenceCommand
from .common import FieldError, ValidationResult
from .identity import validate_newsletter_status_identity


def validate_newsletter_preference(
    payload: dict[str, Any],
) -> ValidationResult[NewsletterPreferenceCommand]:
    identity_validation = validate_newsletter_status_identity(payload)
    errors = list(identity_validation.errors)
    if "subscribed" not in payload:
        errors.append(FieldError("subscribed", "required", "This field is required."))
    elif payload["subscribed"] is None:
        errors.append(
            FieldError(
                "subscribed",
                "null_not_allowed",
                "This field cannot be null.",
            )
        )
    elif type(payload["subscribed"]) is not bool:
        errors.append(
            FieldError(
                "subscribed",
                "invalid_type",
                "This field must be a Boolean.",
            )
        )
    if errors:
        return ValidationResult(None, tuple(errors))
    identity = identity_validation.value
    if identity is None:
        raise RuntimeError("identity validation produced no result")
    return ValidationResult(
        NewsletterPreferenceCommand(
            first_name=identity.first_name,
            middle_initial=identity.middle_initial,
            last_name=identity.last_name,
            email=identity.email,
            subscribed=payload["subscribed"],
        )
    )
