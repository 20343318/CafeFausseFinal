"""Thin HTTP adapters for OP-06 and OP-07."""

from __future__ import annotations

from flask import current_app, g

from ..parsing import require_empty_health_get
from ..responses import error_response, json_response


def liveness():
    require_empty_health_get()
    dependencies = current_app.extensions["cafe_fausse"]
    result = dependencies.liveness_service.check()
    if not result.live:
        return error_response("internal_error", 500)
    return json_response({"status": "live"})


def readiness():
    require_empty_health_get()
    dependencies = current_app.extensions["cafe_fausse"]
    result = dependencies.readiness_service.check()
    g.cafe_fausse_pool_wait_ms = result.pool_wait_ms
    g.cafe_fausse_database_ms = result.database_ms
    safe_logger = current_app.extensions.get("cafe_fausse_logger")
    state = current_app.extensions["cafe_fausse_readiness_state"]
    now = dependencies.monotonic()
    if not result.ready:
        category = result.category.value if result.category else "pool"
        changed = state["category"] != category
        cadence_elapsed = state["logged_at"] is None or now - state["logged_at"] >= 60.0
        if safe_logger is not None and (changed or cadence_elapsed):
            safe_logger.event(
                "readiness_transition",
                severity="WARNING",
                operation="OP-07",
                readiness_component=category,
            )
            state["logged_at"] = now
        state["category"] = category
        return error_response("service_not_ready", 503)
    if state["category"] is not None and safe_logger is not None:
        safe_logger.event("readiness_transition", operation="OP-07")
    state["category"] = None
    state["logged_at"] = now
    return json_response({"status": "ready"})
