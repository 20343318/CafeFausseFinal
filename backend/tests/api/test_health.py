from __future__ import annotations

import json

import pytest

from cafe_fausse.application import create_app
from cafe_fausse.services.results import ReadinessCategory


EXPECTED_HEADERS = {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store, max-age=0",
    "Pragma": "no-cache",
    "Expires": "0",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
}


def assert_policy(response):
    for name, value in EXPECTED_HEADERS.items():
        assert response.headers[name] == value
    assert "Access-Control-Allow-Origin" not in response.headers
    assert "Set-Cookie" not in response.headers
    assert "X-Request-ID" not in response.headers
    assert "Retry-After" not in response.headers
    assert "ETag" not in response.headers


@pytest.mark.api
def test_at_api_op06_exact_liveness_and_zero_database_calls(settings, dependency_factory):
    """AT-API-OP06-001: liveness is exact and database-independent."""
    dependencies, gateway, live = dependency_factory(ReadinessCategory.POOL)
    app = create_app(settings, dependencies)
    response = app.test_client().get("/api/v1/health/liveness")
    assert response.status_code == 200
    assert response.get_json() == {"status": "live"}
    assert gateway.calls == 0
    assert live.calls == 1
    assert_policy(response)


@pytest.mark.api
def test_at_api_op07_exact_ready(settings, dependency_factory):
    dependencies, gateway, _live = dependency_factory()
    response = create_app(settings, dependencies).test_client().get("/api/v1/health/readiness")
    assert response.status_code == 200
    assert response.get_json() == {"status": "ready"}
    assert gateway.calls == 1
    assert_policy(response)


@pytest.mark.api
@pytest.mark.parametrize("category", list(ReadinessCategory))
def test_at_api_op07_all_internal_failures_are_identical(settings, dependency_factory, category):
    dependencies, _gateway, _live = dependency_factory(category)
    response = create_app(settings, dependencies).test_client().get("/api/v1/health/readiness")
    assert response.status_code == 503
    assert response.get_json() == {
        "error": {
            "code": "service_not_ready",
            "message": "The service is not ready.",
            "retryable": True,
            "outcome_unknown": False,
        }
    }
    assert_policy(response)


@pytest.mark.api
def test_at_api_common_methods_routes_and_request_policy(settings, dependency_factory):
    dependencies, _gateway, _live = dependency_factory()
    client = create_app(settings, dependencies).test_client()
    method = client.post("/api/v1/health/liveness")
    assert method.status_code == 405
    assert method.get_json()["error"]["code"] == "method_not_allowed"
    assert set(part.strip() for part in method.headers["Allow"].split(",")) == {"GET"}
    head = client.head("/api/v1/health/liveness")
    options = client.options("/api/v1/health/liveness")
    assert head.status_code == options.status_code == 405
    assert head.headers["Allow"] == options.headers["Allow"] == "GET"
    unknown = client.get("/api/v1/health/live")
    assert unknown.status_code == 404
    assert unknown.get_json()["error"]["code"] == "route_not_found"
    query = client.get("/api/v1/health/liveness?diagnostics=true")
    body = client.get("/api/v1/health/liveness", data=b"x")
    for response in (method, head, options, unknown, query, body):
        assert_policy(response)
    assert query.status_code == body.status_code == 400
    assert query.get_json()["error"]["code"] == body.get_json()["error"]["code"] == "invalid_request"


@pytest.mark.api
def test_at_api_only_approved_through_api07_routes_registered(settings, dependency_factory):
    dependencies, _gateway, _live = dependency_factory()
    app = create_app(settings, dependencies)
    api_rules = sorted(rule.rule for rule in app.url_map.iter_rules() if rule.rule.startswith("/api/"))
    assert api_rules == [
        "/api/v1/health/liveness",
        "/api/v1/health/readiness",
        "/api/v1/newsletter-preferences",
        "/api/v1/newsletter-status-queries",
        "/api/v1/reservation-availability",
        "/api/v1/reservation-context",
    ]


@pytest.mark.api
def test_at_api_unexpected_failure_is_generic_and_secret_free(settings, dependency_factory):
    dependencies, _gateway, _live = dependency_factory(unexpected=True)
    response = create_app(settings, dependencies).test_client().get("/api/v1/health/readiness")
    assert response.status_code == 503
    wire = response.get_data(as_text=True)
    assert "sentinel-secret" not in wire
    assert response.get_json()["error"]["code"] == "service_not_ready"


@pytest.mark.api
def test_at_api_unexpected_route_failure_is_generic_500(settings, dependency_factory):
    dependencies, _gateway, _live = dependency_factory()
    class BrokenLiveness:
        def check(self):
            raise RuntimeError("person@example.com password=sentinel")
    from dataclasses import replace
    dependencies = replace(dependencies, liveness_service=BrokenLiveness())
    response = create_app(settings, dependencies).test_client().get("/api/v1/health/liveness")
    assert response.status_code == 500
    assert response.get_json() == {
        "error": {
            "code": "internal_error",
            "message": "An unexpected error occurred.",
            "retryable": False,
            "outcome_unknown": False,
        }
    }
    assert "sentinel" not in response.get_data(as_text=True)
    assert_policy(response)
