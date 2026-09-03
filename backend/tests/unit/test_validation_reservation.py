from datetime import date

import pytest

from cafe_fausse.validation.reservation import validate_availability_query, validate_reservation


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


VALID_BOOKING = {
    "first_name": " Ada ",
    "middle_initial": "q",
    "last_name": " Rivera ",
    "email": " ADA.RIVERA@example.com ",
    "confirmation_email": "ada.rivera@EXAMPLE.COM",
    "phone": " +1 (202) 555-0198 ",
    "starts_at_local": "2026-09-12T17:00:00-04:00",
    "utc_offset_minutes": -240,
    "party_size": 4,
    "newsletter_action": "subscribe",
}


def test_valid_booking_normalizes_only_approved_request_facts():
    result = validate_reservation(VALID_BOOKING)
    assert result.errors == ()
    command = result.value
    assert command is not None
    assert (command.first_name, command.middle_initial, command.last_name) == ("Ada", "Q", "Rivera")
    assert command.email == "ada.rivera@example.com"
    assert command.phone == "+1 (202) 555-0198"
    assert command.local_start.isoformat() == "2026-09-12T17:00:00"
    assert command.utc_offset_minutes == -240
    assert not hasattr(command, "confirmation_email")


@pytest.mark.parametrize(
    ("changes", "field", "code"),
    [
        ({"middle_initial": "Q."}, "middle_initial", "invalid_format"),
        ({"starts_at_local": "2026-09-12T17:00-04:00"}, "starts_at_local", "invalid_format"),
        ({"starts_at_local": "2026-09-12T17:00:00Z"}, "starts_at_local", "invalid_format"),
        ({"starts_at_local": "2026-09-12T17:00:00.000-04:00"}, "starts_at_local", "invalid_format"),
        ({"utc_offset_minutes": -300}, "utc_offset_minutes", "utc_offset_mismatch"),
        ({"utc_offset_minutes": True}, "utc_offset_minutes", "invalid_type"),
        ({"party_size": False}, "party_size", "invalid_type"),
        ({"party_size": 0}, "party_size", "out_of_range"),
        ({"newsletter_action": "toggle"}, "newsletter_action", "invalid_value"),
        ({"phone": None}, "phone", "null_not_allowed"),
        ({"phone": "123"}, "phone", "invalid_format"),
    ],
)
def test_invalid_booking_fields_are_rejected(changes, field, code):
    result = validate_reservation(VALID_BOOKING | changes)
    assert result.value is None
    assert (field, code) in {(error.field, error.code) for error in result.errors}


def test_booking_validation_orders_identity_then_booking_fields():
    result = validate_reservation({})
    assert [error.field for error in result.errors] == [
        "first_name", "last_name", "email", "confirmation_email",
        "starts_at_local", "utc_offset_minutes", "party_size", "newsletter_action",
    ]
