"""Exhaustive common error translation for the API-04 surface."""

from __future__ import annotations

from flask import Flask
from werkzeug.exceptions import MethodNotAllowed, NotFound, RequestEntityTooLarge

from .parsing import InvalidRequest
from .responses import error_response


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(InvalidRequest)
    def invalid_request(_error: InvalidRequest):
        return error_response("invalid_request", 400)

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
