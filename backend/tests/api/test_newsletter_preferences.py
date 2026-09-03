from __future__ import annotations

from dataclasses import replace
import json

import pytest

from cafe_fausse.application import create_app
from cafe_fausse.db.exceptions import DatabaseContractError
from cafe_fausse.services.newsletter_preferences import (
    NewsletterPreferenceOutcomeUnknown,
    NewsletterPreferenceService,
    NewsletterPreferenceTemporaryFailure,
)
from cafe_fausse.services.results import (
    NewsletterPreferenceOutcome,
    NewsletterPreferenceResult,
)
from cafe_fausse.services.retry import RetryPolicy


VALID = {
    "first_name": "Ada",
    "last_name": "Rivera",
    "email": "ada.rivera@example.com",
    "confirmation_email": "ada.rivera@example.com",
    "subscribed": True,
}

EXPECTED_HEADERS = {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store, max-age=0",
    "Pragma": "no-cache",
    "Expires": "0",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
}


class PreferenceService:
    def __init__(self, result=None, error=None):
        self.result = result or NewsletterPreferenceResult(
            NewsletterPreferenceOutcome.SUBSCRIBED, True
        )
        self.error = error
        self.calls = []

    def set_preference(self, command):
        self.calls.append(command)
        if self.error is not None:
            raise self.error
        return self.result


class PreferenceGateway:
    def __init__(self, value):
        self.value = value
        self.calls = []

    def set_preference(self, command, timeout_seconds=None):
        self.calls.append((command, timeout_seconds))
        if isinstance(self.value, Exception):
            raise self.value
        return self.value


def client_for(settings, dependency_factory, service):
    dependencies, _gateway, _live = dependency_factory()
    dependencies = replace(dependencies, newsletter_preference_service=service)
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
@pytest.mark.parametrize(
    ("result", "body"),
    [
        (
            NewsletterPreferenceResult(NewsletterPreferenceOutcome.SUBSCRIBED, True),
            {"result": "set", "subscribed": True},
        ),
        (
            NewsletterPreferenceResult(NewsletterPreferenceOutcome.UNSUBSCRIBED, False),
            {"result": "set", "subscribed": False},
        ),
        (
            NewsletterPreferenceResult(
                NewsletterPreferenceOutcome.NO_CUSTOMER_NO_CHANGE, False
            ),
            {"result": "no_customer_no_change", "subscribed": False},
        ),
    ],
)
def test_at_api06_op04_exact_success_shapes(settings, dependency_factory, result, body):
    service = PreferenceService(result)
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-preferences", json=VALID
    )
    assert response.status_code == 200
    assert response.get_json() == body
    assert len(service.calls) == 1
    command = service.calls[0]
    assert command.email == "ada.rivera@example.com"
    assert type(command.subscribed) is bool
    assert not hasattr(command, "confirmation_email")
    assert not hasattr(command, "phone")
    assert_policy(response)


@pytest.mark.api
@pytest.mark.parametrize(
    ("outcome", "code", "message"),
    [
        (
            NewsletterPreferenceOutcome.CUSTOMER_IDENTITY_CONFLICT,
            "customer_identity_conflict",
            "The submitted identity details do not match.",
        ),
        (
            NewsletterPreferenceOutcome.MIDDLE_INITIAL_CONFLICT,
            "middle_initial_conflict",
            "The submitted middle initial conflicts with the existing identity details.",
        ),
    ],
)
def test_at_api06_op04_exact_conflicts(
    settings, dependency_factory, outcome, code, message
):
    response = client_for(
        settings,
        dependency_factory,
        PreferenceService(NewsletterPreferenceResult(outcome)),
    ).post("/api/v1/newsletter-preferences", json=VALID)
    assert response.status_code == 409
    assert response.get_json() == {
        "error": {
            "code": code,
            "message": message,
            "retryable": False,
            "outcome_unknown": False,
        }
    }


@pytest.mark.api
def test_at_api06_op04_database_invalid_request_has_ordered_allowlisted_fields(
    settings, dependency_factory
):
    response = client_for(
        settings,
        dependency_factory,
        PreferenceService(
            NewsletterPreferenceResult(NewsletterPreferenceOutcome.INVALID_REQUEST)
        ),
    ).post("/api/v1/newsletter-preferences", json=VALID)
    assert response.status_code == 422
    error = response.get_json()["error"]
    assert error["code"] == "validation_failed"
    assert [item["field"] for item in error["fields"]] == [
        "first_name",
        "middle_initial",
        "last_name",
        "email",
        "confirmation_email",
        "subscribed",
    ]


@pytest.mark.api
@pytest.mark.parametrize(
    ("error", "code", "message", "unknown"),
    [
        (
            NewsletterPreferenceTemporaryFailure(2.0, 3.0, 3),
            "temporary_failure",
            "The newsletter preference could not be processed right now. Please retry shortly.",
            False,
        ),
        (
            NewsletterPreferenceOutcomeUnknown(2.0, 3.0, 1),
            "newsletter_preference_outcome_unknown",
            "The newsletter preference result could not be confirmed. Resubmit the same preference.",
            True,
        ),
    ],
)
def test_at_api06_op04_exact_technical_failure_flags(
    settings, dependency_factory, error, code, message, unknown
):
    response = client_for(
        settings, dependency_factory, PreferenceService(error=error)
    ).post("/api/v1/newsletter-preferences", json=VALID)
    assert response.status_code == 503
    assert response.get_json() == {
        "error": {
            "code": code,
            "message": message,
            "retryable": True,
            "outcome_unknown": unknown,
        }
    }
    assert_policy(response)


@pytest.mark.api
def test_at_api06_op04_cleanup_failure_is_safely_categorized_not_exposed(
    settings, dependency_factory, capfd
):
    pii = "private-cleanup-person@example.test"
    private_driver = "driver receive detail sqlstate=08006 SELECT secret_column"
    private_cleanup = "rollback password=private cleanup detail Connection(private-host)"
    private_first = "PrivateGiven"
    private_last = "PrivateFamily"
    error = NewsletterPreferenceOutcomeUnknown(
        2.0,
        3.0,
        1,
        cleanup_failed=True,
    )
    error.__cause__ = RuntimeError(f"{private_driver}; {private_cleanup}; {pii}")
    response = client_for(
        settings,
        dependency_factory,
        PreferenceService(error=error),
    ).post(
        "/api/v1/newsletter-preferences",
        json=VALID
        | {
            "first_name": private_first,
            "last_name": private_last,
            "email": pii,
            "confirmation_email": pii,
        },
    )
    captured = capfd.readouterr()
    logged = captured.out + captured.err
    assert response.status_code == 503
    assert response.get_json() == {
        "error": {
            "code": "newsletter_preference_outcome_unknown",
            "message": "The newsletter preference result could not be confirmed. Resubmit the same preference.",
            "retryable": True,
            "outcome_unknown": True,
        }
    }
    assert "retry_class=mutation_cleanup_failure" in logged
    assert "error_code=newsletter_preference_outcome_unknown" in logged
    for forbidden in (
        pii,
        private_first,
        private_last,
        private_driver,
        private_cleanup,
        "08006",
        "SELECT secret_column",
        "Connection(private-host)",
        "password",
    ):
        assert forbidden not in logged
        assert forbidden not in response.get_data(as_text=True)


@pytest.mark.api
def test_at_api06_op04_confirmed_success_cleanup_is_logged_without_public_change(
    settings, dependency_factory, capfd
):
    dependencies, _gateway, _live = dependency_factory()
    app = create_app(settings, dependencies)
    safe_logger = app.extensions["cafe_fausse_logger"]
    gateway = PreferenceGateway(
        NewsletterPreferenceResult(
            NewsletterPreferenceOutcome.SUBSCRIBED,
            True,
            cleanup_failed=True,
        )
    )
    service = NewsletterPreferenceService(
        gateway,
        deadline_ms=15000,
        retry_policy=RetryPolicy(3, 25, 200, 0.25, 500),
        monotonic=lambda: 0.0,
        sleeper=lambda _seconds: None,
        uniform=lambda *_bounds: 1.0,
        cleanup_failure_observer=lambda: safe_logger.event(
            "unexpected_error",
            severity="WARNING",
            operation="OP-04",
            retry_class="mutation_cleanup_failure",
        ),
    )
    app.extensions["cafe_fausse"] = replace(
        dependencies,
        newsletter_preference_service=service,
    )

    response = app.test_client().post(
        "/api/v1/newsletter-preferences",
        json=VALID,
    )
    captured = capfd.readouterr()
    logged = captured.out + captured.err

    assert response.status_code == 200
    assert response.get_json() == {"result": "set", "subscribed": True}
    assert len(gateway.calls) == 1
    assert "event=unexpected_error" in logged
    assert "operation=OP-04" in logged
    assert "retry_class=mutation_cleanup_failure" in logged
    for forbidden in (
        VALID["first_name"],
        VALID["last_name"],
        VALID["email"],
        "SELECT outcome",
        "Connection(",
        "Traceback",
    ):
        assert forbidden not in logged
        assert forbidden not in response.get_data(as_text=True)


@pytest.mark.api
def test_at_api06_op04_contract_defect_is_generic_and_nonleaky(
    settings, dependency_factory
):
    response = client_for(
        settings,
        dependency_factory,
        PreferenceService(error=DatabaseContractError()),
    ).post("/api/v1/newsletter-preferences", json=VALID)
    assert response.status_code == 500
    assert response.get_json()["error"] == {
        "code": "internal_error",
        "message": "An unexpected error occurred.",
        "retryable": False,
        "outcome_unknown": False,
    }


@pytest.mark.api
@pytest.mark.parametrize(
    "value",
    [None, 0, 1, 2, 1.0, "true", "false", [], {}],
)
def test_at_api06_op04_subscribed_is_strict_boolean(
    settings, dependency_factory, value
):
    service = PreferenceService()
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-preferences", json=VALID | {"subscribed": value}
    )
    assert response.status_code == 422
    fields = response.get_json()["error"]["fields"]
    assert fields[-1]["field"] == "subscribed"
    assert service.calls == []


@pytest.mark.api
def test_at_api06_op04_validation_order_phone_and_unknown_fields(
    settings, dependency_factory
):
    service = PreferenceService()
    client = client_for(settings, dependency_factory, service)
    invalid = client.post(
        "/api/v1/newsletter-preferences",
        json={
            "first_name": "",
            "middle_initial": "12",
            "last_name": None,
            "email": "bad",
            "confirmation_email": 4,
        },
    )
    assert [item["field"] for item in invalid.get_json()["error"]["fields"]] == [
        "first_name",
        "middle_initial",
        "last_name",
        "email",
        "confirmation_email",
        "subscribed",
    ]
    for extra in ({"phone": "2025550198"}, {"customer_id": 1}, {"extra": True}):
        response = client.post(
            "/api/v1/newsletter-preferences", json=VALID | extra
        )
        assert response.status_code == 400
        assert response.get_json()["error"]["code"] == "invalid_request"
    assert service.calls == []


@pytest.mark.api
def test_at_api06_op04_rejects_period_middle_before_service(settings, dependency_factory):
    service = PreferenceService()
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-preferences",
        json=VALID | {"middle_initial": "A."},
    )
    assert response.status_code == 422
    assert response.get_json()["error"]["fields"] == [{
        "field": "middle_initial",
        "code": "invalid_format",
        "message": "Enter one letter.",
    }]
    assert service.calls == []


@pytest.mark.api
@pytest.mark.parametrize(
    ("data", "content_type", "status", "code"),
    [
        (b"", "application/json", 400, "request_body_required"),
        (b"{", "application/json", 400, "invalid_json"),
        (b"[]", "application/json", 400, "invalid_json"),
        (b'{"subscribed":true,"subscribed":false}', "application/json", 400, "invalid_json"),
        (b'{"subscribed":NaN}', "application/json", 400, "invalid_json"),
        (b"\xff", "application/json", 400, "invalid_json"),
        (json.dumps(VALID).encode(), "text/plain", 415, "unsupported_media_type"),
    ],
)
def test_at_api06_op04_shared_parser_failures(
    settings, dependency_factory, data, content_type, status, code
):
    service = PreferenceService()
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-preferences", data=data, content_type=content_type
    )
    assert response.status_code == status
    assert response.get_json()["error"]["code"] == code
    assert service.calls == []


@pytest.mark.api
def test_at_api06_op04_exact_route_method_query_and_no_aliases(
    settings, dependency_factory
):
    service = PreferenceService()
    client = client_for(settings, dependency_factory, service)
    query = client.post("/api/v1/newsletter-preferences?debug=true", json=VALID)
    assert query.status_code == 400
    assert query.get_json()["error"]["code"] == "invalid_request"
    for method in (client.get, client.put, client.delete, client.options):
        response = method("/api/v1/newsletter-preferences")
        assert response.status_code == 405
        assert response.headers["Allow"] == "POST"
    for path in (
        "/api/v1/newsletter-preference",
        "/api/v1/newsletter/subscribe",
        "/api/v1/subscribers",
    ):
        assert client.post(path, json=VALID).status_code == 404
    assert service.calls == []


@pytest.mark.api
def test_at_api06_op04_privacy_logging_and_no_internal_details(
    settings, dependency_factory, capfd
):
    sentinel = "private-api06-sentinel@example.com"
    service = PreferenceService(
        NewsletterPreferenceResult(NewsletterPreferenceOutcome.SUBSCRIBED, True)
    )
    response = client_for(settings, dependency_factory, service).post(
        "/api/v1/newsletter-preferences",
        json=VALID | {"email": sentinel, "confirmation_email": sentinel},
    )
    captured = capfd.readouterr()
    wire = response.get_data(as_text=True)
    assert response.status_code == 200
    for forbidden in (
        sentinel,
        "customer_id",
        "sqlstate",
        "outcome",
        "prior",
        "123e4567-e89b-42d3-a456-426614174000",
    ):
        assert forbidden not in wire
    assert sentinel not in captured.out + captured.err
    assert "OP-04" in captured.err
