"""Monotonic request timing value."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable


@dataclass(frozen=True, slots=True)
class RequestTimer:
    started: float
    clock: Callable[[], float]

    def elapsed_ms(self) -> float:
        return round(max(0.0, self.clock() - self.started) * 1000, 3)
