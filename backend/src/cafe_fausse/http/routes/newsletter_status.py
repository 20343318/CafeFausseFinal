"""Thin HTTP adapter for OP-03."""

from __future__ import annotations

from flask import current_app, g

from ...serialization.common import serialize_newsletter_status
from ...validation.identity import validate_newsletter_status_identity
from ..parsing import parse_post_json_object
from ..responses import projection_response, validation_error_response

_FIELDS = frozenset(
    {"first_name", "middle_initial", "last_name", "email", "confirmation_email"}
)


def newsletter_status():
    payload = parse_post_json_object(allowed_fields=_FIELDS)
    validation = validate_newsletter_status_identity(payload)
    if validation.errors:
        return validation_error_response(error.as_dict() for error in validation.errors)
    if validation.value is None:
        raise RuntimeError("identity validation produced no result")
    service = current_app.extensions["cafe_fausse"].newsletter_status_service
    if service is None:
        raise RuntimeError("newsletter-status dependency is unavailable")
    result = service.lookup(validation.value)
    g.cafe_fausse_pool_wait_ms = result.pool_wait_ms
    g.cafe_fausse_database_ms = result.database_ms
    return projection_response(serialize_newsletter_status(result))
