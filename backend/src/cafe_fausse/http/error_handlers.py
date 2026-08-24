"""Exhaustive common error translation for the API-04 surface."""

from __future__ import annotations

from flask import Flask, g, request
from werkzeug.exceptions import MethodNotAllowed, NotFound, RequestEntityTooLarge

from ..services.newsletter_status import NewsletterStatusIndeterminate
from ..services.newsletter_preferences import (
    NewsletterPreferenceOutcomeUnknown,
    NewsletterPreferenceTemporaryFailure,
)
from ..services.reservation_context import ReservationServiceUnavailable
from .parsing import InvalidRequest, ProtocolError
from .responses import error_response


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(InvalidRequest)
    def invalid_request(_error: InvalidRequest):
        return error_response("invalid_request", 400)

    @app.errorhandler(ProtocolError)
    def protocol_error(error: ProtocolError):
        return error_response(error.code, error.status)

    @app.errorhandler(NewsletterStatusIndeterminate)
    def newsletter_status_indeterminate(error: NewsletterStatusIndeterminate):
        g.cafe_fausse_pool_wait_ms = error.pool_wait_ms
        g.cafe_fausse_database_ms = error.database_ms
        safe_logger = app.extensions.get("cafe_fausse_logger")
        if safe_logger is not None:
            safe_logger.event(
                "unexpected_error",
                severity="WARNING",
                operation="OP-03",
                error_code="newsletter_status_indeterminate",
            )
        return error_response("newsletter_status_indeterminate", 503)

    def _preference_failure(error, code: str):
        g.cafe_fausse_pool_wait_ms = error.pool_wait_ms
        g.cafe_fausse_database_ms = error.database_ms
        safe_logger = app.extensions.get("cafe_fausse_logger")
        if safe_logger is not None:
            fields = {
                "operation": "OP-04",
                "error_code": code,
                "attempt": error.attempts,
            }
            if error.cleanup_failed:
                fields["retry_class"] = "mutation_cleanup_failure"
            safe_logger.event("unexpected_error", severity="WARNING", **fields)
        return error_response(code, 503)

    @app.errorhandler(NewsletterPreferenceTemporaryFailure)
    def newsletter_preference_temporary(error: NewsletterPreferenceTemporaryFailure):
        return _preference_failure(error, "temporary_failure")

    @app.errorhandler(NewsletterPreferenceOutcomeUnknown)
    def newsletter_preference_unknown(error: NewsletterPreferenceOutcomeUnknown):
        return _preference_failure(error, "newsletter_preference_outcome_unknown")

    @app.errorhandler(ReservationServiceUnavailable)
    def reservation_service_unavailable(error: ReservationServiceUnavailable):
        g.cafe_fausse_pool_wait_ms = error.pool_wait_ms
        g.cafe_fausse_database_ms = error.database_ms
        safe_logger = app.extensions.get("cafe_fausse_logger")
        route = getattr(request.url_rule, "rule", "")
        operation = "OP-01" if route.endswith("reservation-context") else "OP-02"
        if safe_logger is not None:
            safe_logger.event("unexpected_error", severity="WARNING", operation=operation, error_code="service_unavailable")
        return error_response("service_unavailable", 503)

    @app.errorhandler(NotFound)
    def route_not_found(_error: NotFound):
        return error_response("route_not_found", 404)

    @app.errorhandler(MethodNotAllowed)
    def method_not_allowed(error: MethodNotAllowed):
        methods = set(error.valid_methods or ())
        if "GET" in methods:
            methods.discard("HEAD")
            methods.discard("OPTIONS")
        allowed = ", ".join(sorted(methods))
        headers = {"Allow": allowed} if allowed else None
        return error_response("method_not_allowed", 405, headers)

    @app.errorhandler(RequestEntityTooLarge)
    def request_too_large(_error: RequestEntityTooLarge):
        return error_response("invalid_request", 400)

    @app.errorhandler(Exception)
    def unexpected_error(error: Exception):
        safe_logger = app.extensions.get("cafe_fausse_logger")
        if safe_logger is not None:
            safe_logger.event("unexpected_error", severity="ERROR", exception_class=type(error).__name__)
        return error_response("internal_error", 500)
