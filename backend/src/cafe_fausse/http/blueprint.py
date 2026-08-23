"""The single versioned API blueprint."""

from __future__ import annotations

from flask import Blueprint

from .routes.health import liveness, readiness
from .routes.newsletter_status import newsletter_status


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
        "/newsletter-status-queries",
        endpoint="newsletter_status_queries",
        view_func=newsletter_status,
        methods=["POST"],
        provide_automatic_options=False,
    )
    return blueprint
