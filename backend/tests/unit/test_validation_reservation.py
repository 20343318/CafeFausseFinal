from datetime import date

import pytest

from cafe_fausse.validation.reservation import validate_availability_query


pytestmark = pytest.mark.unit


def test_valid_availability_query_is_strict_and_typed():
    result = validate_availability_query({"local_date": ["2026-09-12"], "party_size": ["4"]})
    assert result.errors == ()
    assert result.value is not None
    assert result.value.local_date == date(2026, 9, 12)
    assert result.value.party_size == 4


@pytest.mark.parametrize(
    ("values", "field", "code"),
    [
        ({"local_date": [], "party_size": ["4"]}, "local_date", "required"),
        ({"local_date": ["2026-09-12"], "party_size": []}, "party_size", "required"),
        ({"local_date": ["2026-02-29"], "party_size": ["4"]}, "local_date", "invalid_value"),
        ({"local_date": ["2026-9-12"], "party_size": ["4"]}, "local_date", "invalid_format"),
        ({"local_date": ["2026-09-12"], "party_size": ["four"]}, "party_size", "invalid_type"),
        ({"local_date": ["2026-09-12"], "party_size": ["true"]}, "party_size", "invalid_type"),
        ({"local_date": ["2026-09-12"], "party_size": ["4.0"]}, "party_size", "invalid_type"),
        ({"local_date": ["2026-09-12"], "party_size": ["+4"]}, "party_size", "invalid_type"),
        ({"local_date": ["2026-09-12"], "party_size": [" 4"]}, "party_size", "invalid_type"),
        ({"local_date": ["2026-09-12"], "party_size": ["-1"]}, "party_size", "invalid_type"),
        ({"local_date": ["2026-09-12"], "party_size": ["0"]}, "party_size", "out_of_range"),
        ({"local_date": ["2026-09-12"], "party_size": ["2147483648"]}, "party_size", "out_of_range"),
        ({"local_date": ["2026-09-12", "2026-09-13"], "party_size": ["4"]}, "local_date", "required"),
        ({"local_date": ["2026-09-12"], "party_size": ["4", "5"]}, "party_size", "required"),
    ],
)
def test_invalid_availability_query(values, field, code):
    result = validate_availability_query(values)
    assert result.value is None
    assert (field, code) in {(error.field, error.code) for error in result.errors}
