"""Sparse safe text/NDJSON logging."""

from __future__ import annotations

from datetime import UTC, datetime
import json
import logging
from typing import TextIO

from .redaction import sanitize_event


class _EventFormatter(logging.Formatter):
    def __init__(self, json_format: bool) -> None:
        super().__init__()
        self._json_format = json_format

    def format(self, record: logging.LogRecord) -> str:
        event = record.msg if isinstance(record.msg, dict) else {}
        if self._json_format:
            return json.dumps(event, separators=(",", ":"), ensure_ascii=True)
        return " ".join(f"{name}={value}" for name, value in event.items())


class SafeLogger:
    def __init__(self, logger: logging.Logger, environment: str) -> None:
        self._logger = logger
        self._environment = environment

    def event(self, event: str, *, severity: str = "INFO", **fields: object) -> None:
        payload = sanitize_event(
            {
                "timestamp": datetime.now(UTC).isoformat(timespec="milliseconds"),
                "severity": severity,
                "event": event,
                "environment": self._environment,
                **fields,
            }
        )
        self._logger.log(getattr(logging, severity, logging.INFO), payload)


def configure_safe_logging(environment: str, level: str, log_format: str, stream: TextIO | None = None) -> SafeLogger:
    # Psycopg pool reconnect exceptions may contain connection facts. The
    # application reports only its own coarse readiness categories.
    pool_logger = logging.getLogger("psycopg.pool")
    pool_logger.handlers = [logging.NullHandler()]
    pool_logger.propagate = False
    logger = logging.Logger(f"cafe_fausse.application.{id(stream)}", getattr(logging, level))
    logger.propagate = False
    handler = logging.StreamHandler(stream)
    handler.setFormatter(_EventFormatter(log_format == "json"))
    logger.addHandler(handler)
    return SafeLogger(logger, environment)
