"""Shared protocol parsing owned by the HTTP boundary."""

from __future__ import annotations

import codecs
from decimal import Decimal
import json
from typing import Any, Collection

from flask import request


class ProtocolError(Exception):
    """A safe API-02 protocol failure selected before field validation."""

    def __init__(self, code: str, status: int) -> None:
        super().__init__("request protocol failure")
        self.code = code
        self.status = status


class InvalidRequest(ProtocolError):
    """The request shape violates the frozen REST contract."""

    def __init__(self) -> None:
        super().__init__("invalid_request", 400)


class _InvalidJson(ValueError):
    pass


def _object_without_duplicates(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for name, value in pairs:
        if name in result:
            raise _InvalidJson()
        result[name] = value
    return result


def _reject_nonfinite(_value: str) -> None:
    raise _InvalidJson()


def _is_utf8_charset(value: str) -> bool:
    try:
        return codecs.lookup(value).name == "utf-8"
    except LookupError:
        return False


def parse_post_json_object(*, allowed_fields: Collection[str]) -> dict[str, Any]:
    if request.query_string:
        raise InvalidRequest()
    if request.mimetype != "application/json":
        raise ProtocolError("unsupported_media_type", 415)
    charset = request.mimetype_params.get("charset")
    if charset is not None and not _is_utf8_charset(charset):
        raise ProtocolError("unsupported_media_type", 415)
    raw = request.get_data(cache=False)
    if not raw:
        raise ProtocolError("request_body_required", 400)
    try:
        text = raw.decode("utf-8", errors="strict")
        value = json.loads(
            text,
            object_pairs_hook=_object_without_duplicates,
            parse_float=Decimal,
            parse_constant=_reject_nonfinite,
        )
    except (UnicodeDecodeError, json.JSONDecodeError, _InvalidJson, RecursionError):
        raise ProtocolError("invalid_json", 400) from None
    if not isinstance(value, dict):
        raise ProtocolError("invalid_json", 400)
    if any(name not in allowed_fields for name in value):
        raise InvalidRequest()
    return value


def require_empty_health_get() -> None:
    if request.query_string:
        raise InvalidRequest()
    content_length = request.content_length
    if content_length is not None and content_length > 0:
        raise InvalidRequest()
    if request.get_data(cache=False):
        raise InvalidRequest()
