"""Exact JSON construction and uniform response headers."""

from __future__ import annotations

import json
from typing import Any, Iterable, Mapping

from flask import Response

COMMON_HEADERS = {
    "Cache-Control": "no-store, max-age=0",
    "Pragma": "no-cache",
    "Expires": "0",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
}

ERRORS: dict[str, tuple[int, str, bool, bool]] = {
    "invalid_json": (400, "The request body is not valid JSON.", False, False),
    "request_body_required": (400, "A JSON request body is required.", False, False),
    "invalid_request": (400, "The request is not valid for this endpoint.", False, False),
    "route_not_found": (404, "The requested route was not found.", False, False),
    "method_not_allowed": (405, "The request method is not allowed for this route.", False, False),
    "unsupported_media_type": (415, "This endpoint requires application/json.", False, False),
    "validation_failed": (422, "One or more fields need attention.", False, False),
    "customer_identity_conflict": (
        409,
        "The submitted identity details do not match.",
        False,
        False,
    ),
    "middle_initial_conflict": (
        409,
        "The submitted middle initial conflicts with the existing identity details.",
        False,
        False,
    ),
    "reservation_overlap": (
        409,
        "This customer already has a reservation that overlaps the selected time.",
        False,
        False,
    ),
    "reservation_unavailable": (
        409,
        "The selected time is no longer available. Refresh availability and choose another time.",
        False,
        False,
    ),
    "newsletter_status_indeterminate": (
        503,
        "Newsletter status could not be checked right now. You may retry, or continue a booking without changing it.",
        True,
        False,
    ),
    "temporary_failure": (
        503,
        "The newsletter preference could not be processed right now. Please retry shortly.",
        True,
        False,
    ),
    "newsletter_preference_outcome_unknown": (
        503,
        "The newsletter preference result could not be confirmed. Resubmit the same preference.",
        True,
        True,
    ),
    "reservation_confirmation_unavailable": (
        503,
        "The reservation exists, but its complete confirmation could not be prepared. Resubmit the same reservation details to recover it.",
        True,
        False,
    ),
    "reservation_outcome_unknown": (
        503,
        "The reservation result could not be confirmed. Resubmit the same reservation details to recover safely.",
        True,
        True,
    ),
    "service_not_ready": (503, "The service is not ready.", True, False),
    "service_unavailable": (
        503,
        "The service cannot process this request right now.",
        True,
        False,
    ),
    "internal_error": (500, "An unexpected error occurred.", False, False),
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


def error_response(
    code: str,
    status: int | None = None,
    headers: dict[str, str] | None = None,
    *,
    fields: Iterable[Mapping[str, str]] | None = None,
) -> Response:
    expected_status, message, retryable, outcome_unknown = ERRORS[code]
    if status is not None and status != expected_status:
        raise ValueError("public error status does not match its code")
    error: dict[str, Any] = {
        "code": code,
        "message": message,
        "retryable": retryable,
        "outcome_unknown": outcome_unknown,
    }
    if fields is not None:
        serialized_fields = [dict(field) for field in fields]
        if code != "validation_failed" or not serialized_fields:
            raise ValueError("only validation failures contain nonempty field errors")
        error["fields"] = serialized_fields
    return json_response(
        {"error": error},
        expected_status,
        headers,
    )


def validation_error_response(fields: Iterable[Mapping[str, str]]) -> Response:
    return error_response("validation_failed", fields=fields)


def projection_response(projection: Any) -> Response:
    if projection.error_code is not None:
        return error_response(
            projection.error_code,
            projection.status,
            fields=projection.fields,
        )
    if projection.payload is None:
        raise ValueError("successful response projection requires a payload")
    return json_response(projection.payload, projection.status)


def apply_common_headers(response: Response) -> Response:
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    for name, value in COMMON_HEADERS.items():
        response.headers[name] = value
    response.headers.pop("ETag", None)
    response.headers.pop("Retry-After", None)
    return response
