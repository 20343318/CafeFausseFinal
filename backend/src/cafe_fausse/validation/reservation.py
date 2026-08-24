"""Pure validation for reservation discovery and creation inputs."""

from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
import re
from typing import Any, Mapping, Sequence

from ..services.results import AvailabilityRequest, ReservationCommand
from .common import FieldError, ValidationResult, ordered_errors
from .identity import normalize_phone, validate_newsletter_status_identity

_LOCAL_DATE = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
_PARTY_SIZE = re.compile(r"^[0-9]+$")
_LOCAL_START = re.compile(
    r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$"
)
_BOOKING_FIELD_ORDER = (
    "first_name", "middle_initial", "last_name", "email", "confirmation_email",
    "phone", "starts_at_local", "utc_offset_minutes", "party_size", "newsletter_action",
)


def validate_availability_query(
    values: Mapping[str, Sequence[str]],
) -> ValidationResult[AvailabilityRequest]:
    errors: list[FieldError] = []
    local_values = values.get("local_date", ())
    party_values = values.get("party_size", ())
    local_date: date | None = None
    party_size: int | None = None

    if len(local_values) != 1 or local_values[0] == "":
        errors.append(FieldError("local_date", "required", "This query parameter is required exactly once."))
    elif not _LOCAL_DATE.fullmatch(local_values[0]):
        errors.append(FieldError("local_date", "invalid_format", "Use a valid date in YYYY-MM-DD format."))
    else:
        try:
            local_date = date.fromisoformat(local_values[0])
        except ValueError:
            errors.append(FieldError("local_date", "invalid_value", "Use a valid calendar date."))

    if len(party_values) != 1 or party_values[0] == "":
        errors.append(FieldError("party_size", "required", "This query parameter is required exactly once."))
    elif not _PARTY_SIZE.fullmatch(party_values[0]):
        errors.append(FieldError("party_size", "invalid_type", "Use a base-10 whole number."))
    else:
        party_size = int(party_values[0], 10)
        if not 1 <= party_size <= 2_147_483_647:
            errors.append(FieldError("party_size", "out_of_range", "The party size is outside the allowed range."))

    if errors:
        return ValidationResult(None, tuple(errors))
    assert local_date is not None and party_size is not None
    return ValidationResult(AvailabilityRequest(local_date, party_size))


def _exact_integer(value: Any) -> int | None:
    if type(value) is int:
        return value
    if isinstance(value, Decimal) and value.is_finite() and value == value.to_integral_value():
        return int(value)
    return None


def validate_reservation(payload: dict[str, Any]) -> ValidationResult[ReservationCommand]:
    identity_validation = validate_newsletter_status_identity(payload)
    errors: dict[str, list[FieldError]] = {}
    for error in identity_validation.errors:
        errors.setdefault(error.field, []).append(error)

    phone: str | None = None
    if "phone" in payload:
        if payload["phone"] is None:
            errors.setdefault("phone", []).append(FieldError("phone", "null_not_allowed", "This field cannot be null."))
        else:
            phone_validation = normalize_phone(payload["phone"])
            if phone_validation.errors:
                errors.setdefault("phone", []).extend(phone_validation.errors)
            else:
                assert phone_validation.value is not None
                phone = phone_validation.value.display

    local_start: datetime | None = None
    offset_from_start: int | None = None
    raw_start = payload.get("starts_at_local")
    if "starts_at_local" not in payload:
        errors.setdefault("starts_at_local", []).append(FieldError("starts_at_local", "required", "This field is required."))
    elif raw_start is None:
        errors.setdefault("starts_at_local", []).append(FieldError("starts_at_local", "null_not_allowed", "This field cannot be null."))
    elif not isinstance(raw_start, str):
        errors.setdefault("starts_at_local", []).append(FieldError("starts_at_local", "invalid_type", "This field must be a string."))
    elif _LOCAL_START.fullmatch(raw_start) is None:
        errors.setdefault("starts_at_local", []).append(FieldError("starts_at_local", "invalid_format", "Use a date-time with seconds and a numeric UTC offset."))
    else:
        try:
            aware_start = datetime.fromisoformat(raw_start)
            offset = aware_start.utcoffset()
            if offset is None or offset.total_seconds() % 60:
                raise ValueError()
            offset_from_start = int(offset.total_seconds() // 60)
            if not -840 <= offset_from_start <= 840:
                raise ValueError()
            local_start = aware_start.replace(tzinfo=None)
        except ValueError:
            errors.setdefault("starts_at_local", []).append(FieldError("starts_at_local", "invalid_value", "Use a valid local date and time."))

    utc_offset = _exact_integer(payload.get("utc_offset_minutes"))
    if "utc_offset_minutes" not in payload:
        errors.setdefault("utc_offset_minutes", []).append(FieldError("utc_offset_minutes", "required", "This field is required."))
    elif payload["utc_offset_minutes"] is None:
        errors.setdefault("utc_offset_minutes", []).append(FieldError("utc_offset_minutes", "null_not_allowed", "This field cannot be null."))
    elif utc_offset is None:
        errors.setdefault("utc_offset_minutes", []).append(FieldError("utc_offset_minutes", "invalid_type", "This field must be a whole number."))
    elif not -840 <= utc_offset <= 840:
        errors.setdefault("utc_offset_minutes", []).append(FieldError("utc_offset_minutes", "out_of_range", "The UTC offset is outside the allowed range."))
    elif offset_from_start is not None and utc_offset != offset_from_start:
        errors.setdefault("utc_offset_minutes", []).append(FieldError("utc_offset_minutes", "utc_offset_mismatch", "The UTC offset must match the selected local start."))

    party_size = _exact_integer(payload.get("party_size"))
    if "party_size" not in payload:
        errors.setdefault("party_size", []).append(FieldError("party_size", "required", "This field is required."))
    elif payload["party_size"] is None:
        errors.setdefault("party_size", []).append(FieldError("party_size", "null_not_allowed", "This field cannot be null."))
    elif party_size is None:
        errors.setdefault("party_size", []).append(FieldError("party_size", "invalid_type", "This field must be a whole number."))
    elif not 1 <= party_size <= 2_147_483_647:
        errors.setdefault("party_size", []).append(FieldError("party_size", "out_of_range", "The party size is outside the allowed range."))

    action = payload.get("newsletter_action")
    if "newsletter_action" not in payload:
        errors.setdefault("newsletter_action", []).append(FieldError("newsletter_action", "required", "This field is required."))
    elif action is None:
        errors.setdefault("newsletter_action", []).append(FieldError("newsletter_action", "null_not_allowed", "This field cannot be null."))
    elif not isinstance(action, str):
        errors.setdefault("newsletter_action", []).append(FieldError("newsletter_action", "invalid_type", "This field must be a string."))
    elif action not in {"subscribe", "unsubscribe", "no_change"}:
        errors.setdefault("newsletter_action", []).append(FieldError("newsletter_action", "invalid_value", "Choose subscribe, unsubscribe, or no_change."))

    failures = ordered_errors(errors, _BOOKING_FIELD_ORDER)
    if failures:
        return ValidationResult(None, failures)
    identity = identity_validation.value
    assert identity is not None and local_start is not None and utc_offset is not None and party_size is not None and isinstance(action, str)
    return ValidationResult(ReservationCommand(
        identity.first_name, identity.middle_initial, identity.last_name, identity.email,
        phone, local_start, utc_offset, party_size, action,
    ))
