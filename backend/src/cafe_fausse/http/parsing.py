"""Shared protocol parsing owned by the HTTP boundary."""

from __future__ import annotations

from flask import request


class InvalidRequest(Exception):
    """The request shape violates the frozen REST contract."""


def require_empty_health_get() -> None:
    if request.query_string:
        raise InvalidRequest()
    content_length = request.content_length
    if content_length is not None and content_length > 0:
        raise InvalidRequest()
    if request.get_data(cache=False):
        raise InvalidRequest()
