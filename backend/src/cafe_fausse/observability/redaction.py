"""Allowlist-based event sanitization."""

from __future__ import annotations

import re

_ALLOWED_FIELDS = frozenset(
    {
        "timestamp",
        "severity",
        "event",
        "environment",
        "operation",
        "method",
        "route_template",
        "status",
        "error_code",
        "elapsed_ms",
        "pool_wait_ms",
        "database_ms",
        "attempt",
        "retry_class",
        "remaining_deadline_bucket",
        "correlation_id",
        "readiness_component",
        "exception_class",
        "sqlstate",
    }
)
_SEVERITIES = frozenset({"DEBUG", "INFO", "WARNING", "ERROR"})
_EVENTS = frozenset({"startup", "shutdown", "request_complete", "readiness_transition", "retry", "unexpected_error"})
_OPERATIONS = frozenset({f"OP-0{number}" for number in range(1, 8)})
_COMPONENTS = frozenset({"pool", "platform", "contract", "foundation"})
_SQLSTATES = frozenset({"55P03", "40P01", "40001"})
_EXCEPTION_CLASSES = frozenset(
    {
        "Exception",
        "RuntimeError",
        "ValueError",
        "InvalidRequest",
        "NotFound",
        "MethodNotAllowed",
        "RequestEntityTooLarge",
        "ReadinessProbeFailure",
        "PoolTimeout",
        "OperationalError",
    }
)
_UUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")


def sanitize_event(fields: dict[str, object]) -> dict[str, object]:
    safe = {name: value for name, value in fields.items() if name in _ALLOWED_FIELDS}
    if safe.get("severity") not in _SEVERITIES:
        safe.pop("severity", None)
    if safe.get("event") not in _EVENTS:
        safe.pop("event", None)
    if "operation" in safe and safe["operation"] not in _OPERATIONS:
        safe.pop("operation")
    if "readiness_component" in safe and safe["readiness_component"] not in _COMPONENTS:
        safe.pop("readiness_component")
    if "sqlstate" in safe and safe["sqlstate"] not in _SQLSTATES:
        safe.pop("sqlstate")
    if "correlation_id" in safe and not _UUID.fullmatch(str(safe["correlation_id"])):
        safe.pop("correlation_id")
    if "route_template" in safe and not str(safe["route_template"]).startswith("/api/v1/"):
        safe.pop("route_template")
    if "exception_class" in safe:
        value = str(safe["exception_class"])
        safe["exception_class"] = value if value in _EXCEPTION_CLASSES else "Exception"
    return safe
