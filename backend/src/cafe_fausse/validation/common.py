"""Pure validation values and deterministic ordered error construction."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Generic, Mapping, TypeVar

T = TypeVar("T")


@dataclass(frozen=True, slots=True)
class FieldError:
    field: str
    code: str
    message: str

    def as_dict(self) -> dict[str, str]:
        return {"field": self.field, "code": self.code, "message": self.message}


@dataclass(frozen=True, slots=True)
class ValidationResult(Generic[T]):
    value: T | None
    errors: tuple[FieldError, ...] = ()

    def __post_init__(self) -> None:
        if (self.value is None) == (not self.errors):
            raise ValueError("validation result requires exactly one of value or errors")


def ordered_errors(
    errors: Mapping[str, list[FieldError]], field_order: tuple[str, ...]
) -> tuple[FieldError, ...]:
    return tuple(error for field in field_order for error in errors.get(field, ()))
