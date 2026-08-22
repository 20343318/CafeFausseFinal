from __future__ import annotations

from dataclasses import replace
import io
import json

import pytest

import cafe_fausse.application as application
from cafe_fausse.application import close_resources, create_app
from cafe_fausse.dependencies import Dependencies
from cafe_fausse.observability.logging import configure_safe_logging
from cafe_fausse.observability.redaction import sanitize_event
from cafe_fausse.services.health import LivenessService, ReadinessService


class Resource:
    def __init__(self):
        self.calls = []
    def close(self, timeout=5.0):
        self.calls.append(timeout)


class Gateway:
    def check_readiness(self, deadline_ms):
        return None


@pytest.mark.unit
def test_ut_api_logging_allowlist_json_and_no_sentinel():
    stream = io.StringIO()
    logger = configure_safe_logging("production", "INFO", "json", stream)
    logger.event(
        "request_complete",
        severity="INFO",
        operation="OP-06",
        method="GET",
        route_template="/api/v1/health/liveness",
        status=200,
        correlation_id="123e4567-e89b-42d3-a456-426614174000",
        request_body="person@example.com",
        password="sentinel-password",
        host="private-host",
    )
    output = stream.getvalue()
    event = json.loads(output)
    assert event["operation"] == "OP-06"
    for sentinel in ("person@example.com", "sentinel-password", "private-host"):
        assert sentinel not in output


@pytest.mark.unit
def test_ut_api_redaction_rejects_raw_paths_sqlstates_and_bad_correlation():
    safe = sanitize_event(
        {
            "event": "retry",
            "route_template": "/secret/person@example.com",
            "sqlstate": "28P01",
            "correlation_id": "client-supplied",
            "unknown": "secret",
        }
    )
    assert safe == {"event": "retry"}


@pytest.mark.unit
def test_ut_api_close_resources_is_idempotent_and_bounded(settings):
    resource = Resource()
    dependencies = Dependencies(
        settings=settings,
        liveness_service=LivenessService(),
        readiness_service=ReadinessService(Gateway(), 1000),
        monotonic=lambda: 1.0,
        correlation_id_factory=lambda: "123e4567-e89b-42d3-a456-426614174000",
        resource=resource,
    )
    app = create_app(settings, dependencies)
    close_resources(app)
    close_resources(app)
    assert resource.calls == [1.0]


@pytest.mark.unit
def test_ut_api_factory_closes_partial_production_resource(monkeypatch, settings):
    class BrokenPool(Resource):
        def open(self, wait=False):
            raise RuntimeError("construction failure")
    resource = BrokenPool()
    monkeypatch.setattr(application, "create_pool", lambda _settings: resource)
    with pytest.raises(RuntimeError):
        create_app(settings)
    assert resource.calls == [1.0]


@pytest.mark.unit
def test_ut_api_normal_factory_does_not_call_formal_platform_guard(monkeypatch, settings):
    import cafe_fausse.config as config
    monkeypatch.setattr(config, "require_formal_acceptance_platform", lambda: (_ for _ in ()).throw(AssertionError()))
    dependencies = Dependencies(
        settings=settings,
        liveness_service=LivenessService(),
        readiness_service=ReadinessService(Gateway(), 1000),
        monotonic=lambda: 1.0,
        correlation_id_factory=lambda: "123e4567-e89b-42d3-a456-426614174000",
    )
    create_app(settings, dependencies)
