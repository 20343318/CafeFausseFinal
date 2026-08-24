from datetime import datetime, timedelta, timezone

import pytest

from cafe_fausse.db.exceptions import DatabaseContractError
from cafe_fausse.db.reservation_gateway import _confirmation_facts, _decode, _stored_name
from cafe_fausse.services.results import BookingOutcome, ReservationCommand


pytestmark = pytest.mark.unit
COMMAND = ReservationCommand("Ada", None, "Rivera", "ada@example.test", None, datetime(2026, 9, 12, 17), -240, 4, "no_change")


def row(outcome="booked", detail=None):
    start = datetime(2026, 9, 12, 21, tzinfo=timezone.utc)
    return [(outcome, detail, 42, start, start + timedelta(minutes=90), 4, [2, 7], False, outcome == "booked_phone_notice", 1, bytes(32))]


@pytest.mark.parametrize(("literal", "expected"), [
    ("booked", BookingOutcome.BOOKED),
    ("booked_phone_notice", BookingOutcome.BOOKED_PHONE_NOTICE),
    ("exact_retry", BookingOutcome.EXACT_RETRY),
])
def test_booking_decoder_accepts_complete_known_success_and_hides_fingerprint(literal, expected):
    result = _decode(row(literal), COMMAND, 1, 2)
    assert result.outcome is expected and result.assigned_table_numbers == (2, 7)
    assert not hasattr(result, "reservation_fingerprint")


@pytest.mark.parametrize("mutation", [
    lambda value: value[:-1],
    lambda value: [("unknown", *value[0][1:])],
    lambda value: [(value[0][0], *value[0][1:6], [7, 2], *value[0][7:])],
    lambda value: [(value[0][0], *value[0][1:10], b"short")],
])
def test_booking_decoder_rejects_contract_shape_defects(mutation):
    with pytest.raises(DatabaseContractError): _decode(mutation(row()), COMMAND, 1, 2)


def test_authoritative_stored_name_composes_optional_middle_initial():
    assert _stored_name([("Ada", "Q", "Rivera")]) == "Ada Q. Rivera"
    assert _stored_name([("Ada", None, "Rivera")]) == "Ada Rivera"
    with pytest.raises(ValueError): _stored_name([])


def test_confirmation_facts_are_limited_to_stored_name_and_valid_iana_timezone():
    assert _confirmation_facts([("Ada", "Q", "Rivera", "America/New_York")]) == (
        "Ada Q. Rivera", "America/New_York",
    )
    for rows in [
        [("Ada", "QQ", "Rivera", "America/New_York")],
        [("Ada", "Q", "Rivera", "Not/A_Real_Zone")],
        [("Ada", "Q", "Rivera")],
    ]:
        with pytest.raises((ValueError, KeyError)):
            _confirmation_facts(rows)
