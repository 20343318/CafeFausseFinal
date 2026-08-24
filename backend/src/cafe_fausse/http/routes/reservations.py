"""Thin HTTP adapter for OP-05."""

from flask import current_app, g

from ...serialization.reservation import serialize_reservation_booking
from ...validation.reservation import validate_reservation
from ..parsing import parse_post_json_object
from ..responses import projection_response, validation_error_response

_FIELDS = frozenset({
    "first_name", "middle_initial", "last_name", "email", "confirmation_email",
    "phone", "starts_at_local", "utc_offset_minutes", "party_size", "newsletter_action",
})


def reservations():
    payload = parse_post_json_object(allowed_fields=_FIELDS)
    validation = validate_reservation(payload)
    if validation.errors:
        return validation_error_response(error.as_dict() for error in validation.errors)
    assert validation.value is not None
    service = current_app.extensions["cafe_fausse"].reservation_service
    if service is None:
        raise RuntimeError("reservation dependency is unavailable")
    result = service.book(validation.value)
    g.cafe_fausse_pool_wait_ms = result.pool_wait_ms
    g.cafe_fausse_database_ms = result.database_ms
    return projection_response(serialize_reservation_booking(result))
