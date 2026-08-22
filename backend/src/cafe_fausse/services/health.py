"""OP-06 and OP-07 orchestration without Flask or Psycopg imports."""

from __future__ import annotations

from typing import Protocol

from .results import LiveResult, ReadinessCategory, ReadinessResult


class ReadinessGateway(Protocol):
    def check_readiness(self, deadline_ms: int) -> tuple[float, float] | None: ...


class ReadinessProbeFailure(Exception):
    def __init__(self, category: ReadinessCategory, pool_wait_ms: float = 0.0, database_ms: float = 0.0) -> None:
        super().__init__("readiness probe failed")
        self.category = category
        self.pool_wait_ms = pool_wait_ms
        self.database_ms = database_ms


class LivenessService:
    def check(self) -> LiveResult:
        return LiveResult()


class ReadinessService:
    def __init__(self, gateway: ReadinessGateway, deadline_ms: int) -> None:
        self._gateway = gateway
        self._deadline_ms = deadline_ms

    def check(self) -> ReadinessResult:
        try:
            timings = self._gateway.check_readiness(self._deadline_ms)
        except ReadinessProbeFailure as exc:
            return ReadinessResult(False, exc.category, exc.pool_wait_ms, exc.database_ms)
        except Exception:
            return ReadinessResult(False, ReadinessCategory.POOL)
        pool_wait_ms, database_ms = timings or (0.0, 0.0)
        return ReadinessResult(True, pool_wait_ms=pool_wait_ms, database_ms=database_ms)
