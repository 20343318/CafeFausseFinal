"""Exact JSON construction and uniform response headers."""

from __future__ import annotations

import json
from typing import Any

from flask import Response

COMMON_HEADERS = {
    "Cache-Control": "no-store, max-age=0",
    "Pragma": "no-cache",
    "Expires": "0",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
}

ERRORS: dict[str, tuple[str, bool, bool]] = {
    "invalid_request": ("The request is not valid for this endpoint.", False, False),
    "route_not_found": ("The requested route was not found.", False, False),
    "method_not_allowed": ("The request method is not allowed for this route.", False, False),
    "service_not_ready": ("The service is not ready.", True, False),
    "internal_error": ("An unexpected error occurred.", False, False),
}


def json_response(payload: dict[str, Any], status: int = 200, headers: dict[str, str] | None = None) -> Response:
    body = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    response = Response(body, status=status, content_type="application/json; charset=utf-8")
    for name, value in COMMON_HEADERS.items():
        response.headers[name] = value
    if headers:
        for name, value in headers.items():
            response.headers[name] = value
    return response


def error_response(code: str, status: int, headers: dict[str, str] | None = None) -> Response:
    message, retryable, outcome_unknown = ERRORS[code]
    return json_response(
        {
            "error": {
                "code": code,
                "message": message,
                "retryable": retryable,
                "outcome_unknown": outcome_unknown,
            }
        },
        status,
        headers,
    )


def apply_common_headers(response: Response) -> Response:
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    for name, value in COMMON_HEADERS.items():
        response.headers[name] = value
    response.headers.pop("ETag", None)
    response.headers.pop("Retry-After", None)
    return response
