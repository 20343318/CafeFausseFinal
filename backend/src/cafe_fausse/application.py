"""Flask application factory and process-scoped resource lifecycle."""

from __future__ import annotations

import time
from random import uniform
from uuid import uuid4

from flask import Flask, g, request
from werkzeug.exceptions import MethodNotAllowed

from .config import Settings
from .db.customer_gateway import CustomerGateway
from .db.health_gateway import PsycopgHealthGateway
from .db.pool import create_pool
from .dependencies import Dependencies
from .http.blueprint import create_api_blueprint
from .http.error_handlers import register_error_handlers
from .http.responses import apply_common_headers
from .observability.logging import configure_safe_logging
from .observability.timing import RequestTimer
from .services.health import LivenessService, ReadinessService
from .services.newsletter_status import NewsletterStatusService
from .services.retry import RetryPolicy


def _production_dependencies(settings: Settings, safe_logger) -> Dependencies:
    pool = create_pool(settings)
    try:
        pool.open(wait=False)
        gateway = PsycopgHealthGateway(pool)
        customer_gateway = CustomerGateway(
            pool,
            acquire_timeout_ms=settings.pool_acquire_timeout_ms,
        )
        retry_policy = RetryPolicy(
            settings.max_db_attempts,
            settings.retry_base_delay_ms,
            settings.retry_cap_delay_ms,
            float(settings.retry_jitter_ratio),
            settings.retry_min_remaining_ms,
        )
        newsletter_status_service = NewsletterStatusService(
            customer_gateway,
            deadline_ms=settings.read_deadline_ms,
            retry_policy=retry_policy,
            monotonic=time.monotonic,
            sleeper=time.sleep,
            uniform=uniform,
            retry_observer=lambda attempt: safe_logger.event(
                "retry",
                operation="OP-03",
                attempt=attempt,
                retry_class="read_transient",
            ),
        )
        return Dependencies(
            settings=settings,
            liveness_service=LivenessService(),
            readiness_service=ReadinessService(gateway, settings.readiness_deadline_ms),
            monotonic=time.monotonic,
            correlation_id_factory=lambda: str(uuid4()),
            newsletter_status_service=newsletter_status_service,
            resource=pool,
        )
    except Exception:
        pool.close(timeout=settings.pool_close_timeout_ms / 1000)
        raise


def create_app(settings: Settings | None = None, dependencies: Dependencies | None = None) -> Flask:
    validated_settings = settings or (dependencies.settings if dependencies is not None else Settings.from_environment())
    created_dependencies = dependencies
    owns_dependencies = dependencies is None
    app = Flask(__name__)
    app.config.update(
        TESTING=validated_settings.environment == "test",
        DEBUG=validated_settings.debug,
        MAX_CONTENT_LENGTH=validated_settings.max_request_bytes,
        PROPAGATE_EXCEPTIONS=False,
        SECRET_KEY=None,
    )
    app.json.sort_keys = False
    logger = configure_safe_logging(
        validated_settings.environment, validated_settings.log_level, validated_settings.log_format
    )
    app.extensions["cafe_fausse_logger"] = logger
    try:
        if created_dependencies is None:
            created_dependencies = _production_dependencies(validated_settings, logger)
        elif created_dependencies.settings != validated_settings:
            raise ValueError("Injected dependencies and settings must agree.")
        app.extensions["cafe_fausse"] = created_dependencies
        app.extensions["cafe_fausse_closed"] = False
        app.extensions["cafe_fausse_readiness_state"] = {"category": None, "logged_at": None}
        register_error_handlers(app)
        app.register_blueprint(create_api_blueprint())

        @app.before_request
        def start_request_observation() -> None:
            g.cafe_fausse_correlation_id = created_dependencies.correlation_id_factory()
            g.cafe_fausse_timer = RequestTimer(created_dependencies.monotonic(), created_dependencies.monotonic)
            if request.method == "HEAD" and request.url_rule is not None:
                raise MethodNotAllowed(valid_methods=["GET"])

        @app.after_request
        def finish_request(response):
            response = apply_common_headers(response)
            route = request.url_rule.rule if request.url_rule is not None else None
            operation = None
            if route == "/api/v1/health/liveness":
                operation = "OP-06"
            elif route == "/api/v1/health/readiness":
                operation = "OP-07"
            elif route == "/api/v1/newsletter-status-queries":
                operation = "OP-03"
            timer = getattr(g, "cafe_fausse_timer", None)
            logger.event(
                "request_complete",
                operation=operation,
                method=request.method,
                route_template=route,
                status=response.status_code,
                elapsed_ms=timer.elapsed_ms() if timer else 0.0,
                pool_wait_ms=getattr(g, "cafe_fausse_pool_wait_ms", 0.0),
                database_ms=getattr(g, "cafe_fausse_database_ms", 0.0),
                correlation_id=getattr(g, "cafe_fausse_correlation_id", ""),
            )
            return response

        logger.event("startup")
        return app
    except Exception:
        if owns_dependencies and created_dependencies is not None and created_dependencies.resource is not None:
            created_dependencies.resource.close(timeout=validated_settings.pool_close_timeout_ms / 1000)
        raise


def close_resources(app: Flask) -> None:
    if app.extensions.get("cafe_fausse_closed", False):
        return
    app.extensions["cafe_fausse_closed"] = True
    dependencies = app.extensions.get("cafe_fausse")
    if dependencies is not None and dependencies.resource is not None:
        dependencies.resource.close(timeout=dependencies.settings.pool_close_timeout_ms / 1000)
    logger = app.extensions.get("cafe_fausse_logger")
    if logger is not None:
        logger.event("shutdown")
