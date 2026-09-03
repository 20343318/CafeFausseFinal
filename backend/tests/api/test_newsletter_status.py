from __future__ import annotations

from dataclasses import replace
import json

import pytest

from cafe_fausse.application import close_resources, create_app
from cafe_fausse.db.exceptions import DatabaseContractError
from cafe_fausse.services.newsletter_status import NewsletterStatusIndeterminate
from cafe_fausse.services.results import NewsletterStatusOutcome, NewsletterStatusResult


VALID = {
    "first_name": "Ada",
    "last_name": "Rivera",
    "email": "ada.rivera@example.com",
    "confirmation_email": "ada.rivera@example.com",
}

EXPECTED_HEADERS = {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store, max-age=0",
    "Pragma": "no-cache",
    "Expires": "0",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
}


class StatusService:
    def __init__(self, result=None, error=None):
        self.result = result or NewsletterStatusResult(NewsletterStatusOutcome.NOT_FOUND)
        self.error = error
        self.calls = []

    def lookup(self, identity):
        self.calls.append(identity)
        if self.error is not None:
            raise self.error
        return self.result


def client_for(settings, dependency_factory, service):
    dependencies, _gateway, _live = dependency_factory()
    dependencies = replace(dependencies, newsletter_status_service=service)
    return create_app(settings, dependencies).test_client()


def assert_policy(response):
    for name, value in EXPECTED_HEADERS.items():
        assert response.headers[name] == value
    for name in (
        "Access-Control-Allow-Origin",
        "Set-Cookie",
        "X-Request-ID",
        "Retry-After",
        "ETag",
    ):
        assert name not in response.headers


@pytest.mark.api
def test_at_api05_registration_preserves_api04_health_common_errors_and_lifecycle(
    settings, dependency_factory
):
    class Resource:
        def __init__(self):
            self.close_calls = []

        def close(self, timeout=5.0):
            self.close_calls.append(timeout)

    resource = Resource()
    dependencies, gateway, live = dependency_factory()
    dependencies = replace(
        dependencies,
        newsletter_status_service=StatusService(),
        resource=resource,
    )
    app = create_app(settings, dependencies)
    client = app.test_client()
    assert client.get("/api/v1/health/liveness").get_json() == {"status": "live"}
    assert client.get("/api/v1/health/readiness").get_json() == {"status": "ready"}
    missing = client.get("/api/v1/not-a-route")
    assert missing.status_code == 404
    assert missing.get_json()["error"]["code"] == "route_not_found"
    assert live.calls == gateway.calls == 1
    close_resources(app)
    close_resources(app)
    assert resource.close_calls == [1.0]


@pytest.mark.api
@pytest.mark.parametrize(
    ("result", "expected"),
    [
        (
            NewsletterStatusResult(NewsletterStatusOutcome.MATCHED, True),
            {"status": "matched", "subscribed": True},
        ),
        (
            NewsletterStatusResult(NewsletterStatusOutcome.MATCHED, False),
            {"status": "matched", "subscribed": False},
        ),
        (
            NewsletterStatusResult(NewsletterStatusOutcome.NOT_FOUND),
            {"status": "not_found"},
        ),
    ],
)
def test_at_api05_op03_exact_success_responses(settings, dependency_factory, result, expected):
    service = StatusService(result)
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-status-queries", json=VALID
    )
    assert response.status_code == 200
    assert response.get_json() == expected
    assert len(service.calls) == 1
    identity = service.calls[0]
    assert identity.email == "ada.rivera@example.com"
    assert not hasattr(identity, "confirmation_email")
    assert_policy(response)


@pytest.mark.api
@pytest.mark.parametrize(
    ("outcome", "code", "message"),
    [
        (
            NewsletterStatusOutcome.CUSTOMER_IDENTITY_CONFLICT,
            "customer_identity_conflict",
            "The submitted identity details do not match.",
        ),
        (
            NewsletterStatusOutcome.MIDDLE_INITIAL_CONFLICT,
            "middle_initial_conflict",
            "The submitted middle initial conflicts with the existing identity details.",
        ),
    ],
)
def test_at_api05_op03_exact_generic_conflicts(
    settings, dependency_factory, outcome, code, message
):
    response = client_for(
        settings, dependency_factory, StatusService(NewsletterStatusResult(outcome))
    ).post("/api/v1/newsletter-status-queries", json=VALID)
    assert response.status_code == 409
    assert response.get_json() == {
        "error": {
            "code": code,
            "message": message,
            "retryable": False,
            "outcome_unknown": False,
        }
    }
    assert_policy(response)


@pytest.mark.api
def test_at_api05_op03_exact_indeterminate_response(settings, dependency_factory):
    service = StatusService(error=NewsletterStatusIndeterminate(2.0, 3.0))
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-status-queries", json=VALID
    )
    assert response.status_code == 503
    assert response.get_json() == {
        "error": {
            "code": "newsletter_status_indeterminate",
            "message": "Newsletter status could not be checked right now. You may retry, or continue a booking without changing it.",
            "retryable": True,
            "outcome_unknown": False,
        }
    }
    assert_policy(response)


@pytest.mark.api
def test_at_api05_op03_contract_defect_is_generic_500(settings, dependency_factory):
    response = client_for(
        settings, dependency_factory, StatusService(error=DatabaseContractError())
    ).post("/api/v1/newsletter-status-queries", json=VALID)
    assert response.status_code == 500
    assert response.get_json() == {
        "error": {
            "code": "internal_error",
            "message": "An unexpected error occurred.",
            "retryable": False,
            "outcome_unknown": False,
        }
    }


@pytest.mark.api
def test_at_api05_op03_validation_fields_are_exact_and_ordered(settings, dependency_factory):
    service = StatusService()
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-status-queries",
        json={
            "first_name": "",
            "middle_initial": "12",
            "last_name": None,
            "email": "bad",
            "confirmation_email": 4,
        },
    )
    assert response.status_code == 422
    body = response.get_json()
    assert body["error"]["code"] == "validation_failed"
    assert body["error"]["message"] == "One or more fields need attention."
    assert body["error"]["retryable"] is False
    assert body["error"]["outcome_unknown"] is False
    assert [item["field"] for item in body["error"]["fields"]] == [
        "first_name",
        "middle_initial",
        "last_name",
        "email",
        "confirmation_email",
    ]
    assert service.calls == []
    assert "bad" not in response.get_data(as_text=True)


@pytest.mark.api
@pytest.mark.parametrize(
    ("payload", "field"),
    [
        ({name: value for name, value in VALID.items() if name != "first_name"}, "first_name"),
        (VALID | {"first_name": None}, "first_name"),
        (VALID | {"first_name": 7}, "first_name"),
        (VALID | {"first_name": " "}, "first_name"),
        (VALID | {"first_name": "A" * 101}, "first_name"),
        (VALID | {"middle_initial": "A."}, "middle_initial"),
        (VALID | {"email": "invalid", "confirmation_email": "invalid"}, "email"),
        (VALID | {"confirmation_email": "other@example.com"}, "confirmation_email"),
    ],
)
def test_at_api05_op03_strict_field_validation(
    settings, dependency_factory, payload, field
):
    service = StatusService()
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-status-queries", json=payload
    )
    assert response.status_code == 422
    assert field in [item["field"] for item in response.get_json()["error"]["fields"]]
    assert service.calls == []


@pytest.mark.api
@pytest.mark.parametrize(
    ("data", "content_type", "status", "code"),
    [
        (b"", "application/json", 400, "request_body_required"),
        (b"{", "application/json", 400, "invalid_json"),
        (b"[]", "application/json", 400, "invalid_json"),
        (b'"text"', "application/json", 400, "invalid_json"),
        (b'{"first_name":"Ada","first_name":"Other"}', "application/json", 400, "invalid_json"),
        (b'{"first_name":{"x":1,"x":2}}', "application/json", 400, "invalid_json"),
        (b'{"first_name":NaN}', "application/json", 400, "invalid_json"),
        (b"\xff", "application/json", 400, "invalid_json"),
        (json.dumps(VALID).encode(), "text/plain", 415, "unsupported_media_type"),
        (json.dumps(VALID).encode(), "application/json; charset=iso-8859-1", 415, "unsupported_media_type"),
    ],
)
def test_at_api05_op03_protocol_failures(
    settings, dependency_factory, data, content_type, status, code
):
    service = StatusService()
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-status-queries", data=data, content_type=content_type
    )
    assert response.status_code == status
    assert response.get_json()["error"]["code"] == code
    assert service.calls == []
    assert_policy(response)


@pytest.mark.api
@pytest.mark.parametrize("extra", [{"phone": "2025550198"}, {"customer_id": 1}, {"subscribed": True}])
def test_at_api05_op03_unknown_fields_are_invalid_request(
    settings, dependency_factory, extra
):
    service = StatusService()
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-status-queries", json=VALID | extra
    )
    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "invalid_request"
    assert service.calls == []


@pytest.mark.api
def test_at_api05_op03_query_and_oversized_body_are_invalid_request(
    settings, dependency_factory
):
    service = StatusService()
    client = client_for(settings, dependency_factory, service)
    query = client.post("/api/v1/newsletter-status-queries?debug=true", json=VALID)
    oversized = client.post(
        "/api/v1/newsletter-status-queries",
        data=b"{" + b"x" * 17000 + b"}",
        content_type="application/json",
    )
    for response in (query, oversized):
        assert response.status_code == 400
        assert response.get_json()["error"]["code"] == "invalid_request"
    assert service.calls == []


@pytest.mark.api
def test_at_api05_op03_exact_method_route_and_no_aliases(settings, dependency_factory):
    service = StatusService()
    client = client_for(settings, dependency_factory, service)
    for method in (client.get, client.put, client.delete, client.options):
        response = method("/api/v1/newsletter-status-queries")
        assert response.status_code == 405
        assert response.get_json()["error"]["code"] == "method_not_allowed"
        assert response.headers["Allow"] == "POST"
    for path in (
        "/api/v1/newsletter-status-query",
        "/api/v1/newsletter/status",
        "/api/v1/customers/newsletter-status",
    ):
        response = client.post(path, json=VALID)
        assert response.status_code == 404
        assert response.get_json()["error"]["code"] == "route_not_found"
    assert service.calls == []


@pytest.mark.api
def test_at_api05_op03_correlation_logging_and_privacy(
    settings, dependency_factory, capfd
):
    sentinel = "private-confirmation-sentinel@example.com"
    payload = VALID | {
        "email": sentinel,
        "confirmation_email": sentinel,
    }
    service = StatusService(NewsletterStatusResult(NewsletterStatusOutcome.NOT_FOUND))
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-status-queries", json=payload
    )
    captured = capfd.readouterr()
    wire = response.get_data(as_text=True)
    assert response.status_code == 200
    assert sentinel not in wire
    assert sentinel not in captured.out
    assert sentinel not in captured.err
    assert "OP-03" in captured.err
    assert "123e4567-e89b-42d3-a456-426614174000" in captured.err
    assert "123e4567-e89b-42d3-a456-426614174000" not in wire
