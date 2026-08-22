from __future__ import annotations

from dataclasses import replace
from decimal import Decimal
from pathlib import Path
import sys

import pytest

SRC = Path(__file__).parents[1] / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from cafe_fausse.config import Settings
from cafe_fausse.dependencies import Dependencies
from cafe_fausse.services.health import LivenessService, ReadinessProbeFailure, ReadinessService
from cafe_fausse.services.results import ReadinessCategory


class FakeGateway:
    def __init__(self, category: ReadinessCategory | None = None, unexpected: bool = False) -> None:
        self.category = category
        self.unexpected = unexpected
        self.calls = 0

    def check_readiness(self, deadline_ms: int) -> None:
        self.calls += 1
        assert deadline_ms == 1000
        if self.unexpected:
            raise RuntimeError("sentinel-secret@example.com password=do-not-leak")
        if self.category is not None:
            raise ReadinessProbeFailure(self.category)


class CounterLiveness(LivenessService):
    def __init__(self) -> None:
        self.calls = 0

    def check(self):
        self.calls += 1
        return super().check()


@pytest.fixture
def settings() -> Settings:
    return Settings(
        environment="test",
        debug=False,
        pghost="127.0.0.1",
        pgport=55433,
        pgdatabase="cafe_fausse_test_api04",
        pguser="deployment_login",
        pool_min_size=0,
        pool_max_size=2,
        retry_jitter_ratio=Decimal("0.25"),
    )


@pytest.fixture
def dependency_factory(settings):
    def build(category=None, unexpected=False):
        gateway = FakeGateway(category, unexpected)
        live = CounterLiveness()
        dependencies = Dependencies(
            settings=settings,
            liveness_service=live,
            readiness_service=ReadinessService(gateway, 1000),
            monotonic=lambda: 10.0,
            correlation_id_factory=lambda: "123e4567-e89b-42d3-a456-426614174000",
        )
        return dependencies, gateway, live
    return build
