"""Pure validation for API-07 reservation discovery inputs."""

from __future__ import annotations

from datetime import date
import re
from typing import Mapping, Sequence

from ..services.results import AvailabilityRequest
from .common import FieldError, ValidationResult

_LOCAL_DATE = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
_PARTY_SIZE = re.compile(r"^[0-9]+$")


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
