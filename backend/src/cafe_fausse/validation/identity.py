"""API-02 identity validation and normalization."""

from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Any

from ..services.results import CustomerIdentity
from .common import FieldError, ValidationResult, ordered_errors

_FIELD_ORDER = ("first_name", "middle_initial", "last_name", "email", "confirmation_email")
_REQUIRED_FIELDS = frozenset({"first_name", "last_name", "email", "confirmation_email"})
_LOCAL_ATOM = re.compile(r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*$")
_DOMAIN_LABEL = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$")
_PHONE_CHARS = re.compile(r"^[0-9 +().-]+$")


@dataclass(frozen=True, slots=True)
class NormalizedPhone:
    display: str
    digits: str


def _error(field: str, code: str, message: str) -> FieldError:
    return FieldError(field, code, message)


def _required_error(field: str) -> FieldError:
    return _error(field, "required", "This field is required.")


def _string_error(field: str) -> FieldError:
    return _error(field, "invalid_type", "This field must be a string.")


def _normalize_name(field: str, value: Any) -> tuple[str | None, FieldError | None]:
    if not isinstance(value, str):
        return None, _string_error(field)
    normalized = " ".join(value.split())
    if not normalized:
        return None, _error(field, "empty", "This field cannot be empty.")
    if len(normalized) > 100:
        return None, _error(field, "too_long", "This field must be 100 characters or fewer.")
    if not any(character.isalpha() for character in normalized):
        return None, _error(field, "invalid_format", "This field must contain a letter.")
    return normalized, None


def _normalize_middle(value: Any) -> tuple[str | None, FieldError | None]:
    field = "middle_initial"
    if not isinstance(value, str):
        return None, _string_error(field)
    normalized = value.strip()
    if not normalized:
        return None, None
    if len(normalized) != 1 or not normalized.isalpha():
        return None, _error(field, "invalid_format", "Enter one letter.")
    upper = normalized.upper()
    if len(upper) != 1:
        return None, _error(field, "invalid_format", "Enter one letter.")
    return upper, None


def _normalize_email(field: str, value: Any) -> tuple[str | None, FieldError | None]:
    if not isinstance(value, str):
        return None, _string_error(field)
    normalized = value.strip()
    if not normalized:
        return None, _error(field, "empty", "This field cannot be empty.")
    if len(normalized) > 254:
        return None, _error(field, "too_long", "This field must be 254 characters or fewer.")
    if normalized.count("@") != 1:
        return None, _error(field, "invalid_format", "Enter a valid email address.")
    local, domain = normalized.split("@", 1)
    labels = domain.split(".")
    if (
        not local
        or not domain
        or _LOCAL_ATOM.fullmatch(local) is None
        or any(_DOMAIN_LABEL.fullmatch(label) is None for label in labels)
    ):
        return None, _error(field, "invalid_format", "Enter a valid email address.")
    return normalized.lower(), None


def normalize_phone(value: Any) -> ValidationResult[NormalizedPhone]:
    field = "phone"
    if not isinstance(value, str):
        return ValidationResult(None, (_string_error(field),))
    display = value.strip()
    if not display:
        return ValidationResult(None, (_error(field, "empty", "This field cannot be empty."),))
    if len(display) > 32:
        return ValidationResult(
            None,
            (_error(field, "too_long", "This field must be 32 characters or fewer."),),
        )
    digits = "".join(character for character in display if character.isdigit())
    if _PHONE_CHARS.fullmatch(display) is None or not 7 <= len(digits) <= 15:
        return ValidationResult(
            None,
            (_error(field, "invalid_format", "Enter a valid phone number."),),
        )
    return ValidationResult(NormalizedPhone(display, digits))


def validate_newsletter_status_identity(payload: dict[str, Any]) -> ValidationResult[CustomerIdentity]:
    errors: dict[str, list[FieldError]] = {}
    normalized: dict[str, str | None] = {"middle_initial": None}

    for field in _FIELD_ORDER:
        if field not in payload:
            if field in _REQUIRED_FIELDS:
                errors.setdefault(field, []).append(_required_error(field))
            continue
        value = payload[field]
        if value is None:
            errors.setdefault(field, []).append(_error(field, "null_not_allowed", "This field cannot be null."))
            continue
        if field in {"first_name", "last_name"}:
            result, failure = _normalize_name(field, value)
        elif field == "middle_initial":
            result, failure = _normalize_middle(value)
        else:
            result, failure = _normalize_email(field, value)
        if failure is not None:
            errors.setdefault(field, []).append(failure)
        else:
            normalized[field] = result

    if "email" in normalized and "confirmation_email" in normalized:
        if normalized["email"] != normalized["confirmation_email"]:
            errors.setdefault("confirmation_email", []).append(
                _error(
                    "confirmation_email",
                    "email_mismatch",
                    "The email addresses must match.",
                )
            )

    ordered = ordered_errors(errors, _FIELD_ORDER)
    if ordered:
        return ValidationResult(None, ordered)
    return ValidationResult(
        CustomerIdentity(
            first_name=str(normalized["first_name"]),
            middle_initial=normalized["middle_initial"],
            last_name=str(normalized["last_name"]),
            email=str(normalized["email"]),
        )
    )
