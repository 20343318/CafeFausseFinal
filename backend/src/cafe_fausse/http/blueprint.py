"""The single versioned API blueprint."""

from __future__ import annotations

from flask import Blueprint

from .routes.health import liveness, readiness
from .routes.newsletter_preferences import newsletter_preferences
from .routes.newsletter_status import newsletter_status
from .routes.reservation_availability import reservation_availability
from .routes.reservation_context import reservation_context
from .routes.reservations import reservations


def create_api_blueprint() -> Blueprint:
    blueprint = Blueprint("api_v1", __name__, url_prefix="/api/v1")
    blueprint.add_url_rule(
        "/health/liveness",
        endpoint="health_liveness",
        view_func=liveness,
        methods=["GET"],
        provide_automatic_options=False,
    )
    blueprint.add_url_rule(
        "/health/readiness",
        endpoint="health_readiness",
        view_func=readiness,
        methods=["GET"],
        provide_automatic_options=False,
    )
    blueprint.add_url_rule(
        "/reservation-context",
        endpoint="reservation_context",
        view_func=reservation_context,
        methods=["GET"],
        provide_automatic_options=False,
    )
    blueprint.add_url_rule(
        "/reservation-availability",
        endpoint="reservation_availability",
        view_func=reservation_availability,
        methods=["GET"],
        provide_automatic_options=False,
    )
    blueprint.add_url_rule(
        "/newsletter-preferences",
        endpoint="newsletter_preferences",
        view_func=newsletter_preferences,
        methods=["POST"],
        provide_automatic_options=False,
    )
    blueprint.add_url_rule(
        "/newsletter-status-queries",
        endpoint="newsletter_status_queries",
        view_func=newsletter_status,
        methods=["POST"],
        provide_automatic_options=False,
    )
    blueprint.add_url_rule(
        "/reservations",
        endpoint="reservations",
        view_func=reservations,
        methods=["POST"],
        provide_automatic_options=False,
    )
    return blueprint
