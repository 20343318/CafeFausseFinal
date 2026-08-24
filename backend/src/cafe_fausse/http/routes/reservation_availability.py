"""Thin HTTP adapter for OP-02."""

from flask import current_app, g, request

from ...serialization.reservation import serialize_reservation_availability
from ...validation.reservation import validate_availability_query
from ..parsing import InvalidRequest
from ..responses import projection_response, validation_error_response


def reservation_availability():
    if request.content_length not in (None, 0) or request.get_data(cache=False):
        raise InvalidRequest()
    if set(request.args) != {"local_date", "party_size"}:
        raise InvalidRequest()
    if any(len(request.args.getlist(name)) != 1 or request.args.getlist(name)[0] == "" for name in ("local_date", "party_size")):
        raise InvalidRequest()
    validation = validate_availability_query({name: request.args.getlist(name) for name in request.args})
    if validation.errors:
        return validation_error_response(error.as_dict() for error in validation.errors)
    assert validation.value is not None
    service = current_app.extensions["cafe_fausse"].reservation_availability_service
    if service is None:
        raise RuntimeError("reservation-availability dependency is unavailable")
    result = service.get(validation.value)
    g.cafe_fausse_pool_wait_ms = result.pool_wait_ms
    g.cafe_fausse_database_ms = result.database_ms
    return projection_response(serialize_reservation_availability(result))
