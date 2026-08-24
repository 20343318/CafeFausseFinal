"""Thin HTTP adapter for OP-01."""

from flask import current_app, g

from ...serialization.reservation import serialize_reservation_context
from ..parsing import require_empty_health_get
from ..responses import projection_response


def reservation_context():
    require_empty_health_get()
    service = current_app.extensions["cafe_fausse"].reservation_context_service
    if service is None:
        raise RuntimeError("reservation-context dependency is unavailable")
    result = service.get()
    g.cafe_fausse_pool_wait_ms = result.pool_wait_ms
    g.cafe_fausse_database_ms = result.database_ms
    return projection_response(serialize_reservation_context(result))
