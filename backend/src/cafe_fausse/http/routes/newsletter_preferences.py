"""Thin HTTP adapter for OP-04."""

from __future__ import annotations

from flask import current_app, g

from ...serialization.common import serialize_newsletter_preference
from ...validation.newsletter import validate_newsletter_preference
from ..parsing import parse_post_json_object
from ..responses import projection_response, validation_error_response

_FIELDS = frozenset(
    {
        "first_name",
        "middle_initial",
        "last_name",
        "email",
        "confirmation_email",
        "subscribed",
    }
)


def newsletter_preferences():
    payload = parse_post_json_object(allowed_fields=_FIELDS)
    validation = validate_newsletter_preference(payload)
    if validation.errors:
        return validation_error_response(error.as_dict() for error in validation.errors)
    if validation.value is None:
        raise RuntimeError("newsletter preference validation produced no result")
    service = current_app.extensions["cafe_fausse"].newsletter_preference_service
    if service is None:
        raise RuntimeError("newsletter-preference dependency is unavailable")
    result = service.set_preference(validation.value)
    g.cafe_fausse_pool_wait_ms = result.pool_wait_ms
    g.cafe_fausse_database_ms = result.database_ms
    return projection_response(serialize_newsletter_preference(result))
