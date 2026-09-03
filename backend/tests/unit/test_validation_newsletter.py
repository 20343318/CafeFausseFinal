from __future__ import annotations

from decimal import Decimal

import pytest

from cafe_fausse.validation.newsletter import validate_newsletter_preference


VALID = {
    "first_name": "  Ada   Marie ",
    "middle_initial": "m",
    "last_name": " Rivera ",
    "email": " ADA.RIVERA@EXAMPLE.COM ",
    "confirmation_email": "ada.rivera@example.com",
    "subscribed": True,
}


@pytest.mark.unit
@pytest.mark.parametrize("subscribed", [True, False])
def test_ut_api06_validation_reuses_identity_normalization(subscribed):
    result = validate_newsletter_preference(VALID | {"subscribed": subscribed})
    assert result.errors == ()
    assert result.value is not None
    assert (
        result.value.first_name,
        result.value.middle_initial,
        result.value.last_name,
        result.value.email,
        result.value.subscribed,
    ) == ("Ada Marie", "M", "Rivera", "ada.rivera@example.com", subscribed)
    assert not hasattr(result.value, "confirmation_email")
    assert not hasattr(result.value, "phone")


@pytest.mark.unit
def test_ut_api06_validation_optional_middle_is_omitted():
    payload = {name: value for name, value in VALID.items() if name != "middle_initial"}
    result = validate_newsletter_preference(payload)
    assert result.value is not None
    assert result.value.middle_initial is None


@pytest.mark.unit
@pytest.mark.parametrize(
    ("value", "code"),
    [
        (None, "null_not_allowed"),
        (0, "invalid_type"),
        (1, "invalid_type"),
        (2, "invalid_type"),
        (Decimal("1"), "invalid_type"),
        ("true", "invalid_type"),
        ([], "invalid_type"),
        ({}, "invalid_type"),
    ],
)
def test_ut_api06_validation_subscribed_is_exact_boolean(value, code):
    result = validate_newsletter_preference(VALID | {"subscribed": value})
    assert result.value is None
    assert result.errors[-1].field == "subscribed"
    assert result.errors[-1].code == code


@pytest.mark.unit
def test_ut_api06_validation_missing_subscribed_and_ordered_identity_errors():
    payload = {
        "first_name": "",
        "middle_initial": "12",
        "last_name": None,
        "email": "bad",
        "confirmation_email": 4,
    }
    result = validate_newsletter_preference(payload)
    assert [error.field for error in result.errors] == [
        "first_name",
        "middle_initial",
        "last_name",
        "email",
        "confirmation_email",
        "subscribed",
    ]
    assert result.errors[-1].code == "required"


@pytest.mark.unit
@pytest.mark.parametrize(
    ("changes", "field"),
    [
        ({"first_name": None}, "first_name"),
        ({"first_name": 3}, "first_name"),
        ({"first_name": " "}, "first_name"),
        ({"first_name": "A" * 101}, "first_name"),
        ({"last_name": "---"}, "last_name"),
        ({"middle_initial": "A."}, "middle_initial"),
        ({"middle_initial": "AB"}, "middle_initial"),
        ({"email": "invalid", "confirmation_email": "invalid"}, "email"),
        ({"confirmation_email": "other@example.com"}, "confirmation_email"),
    ],
)
def test_ut_api06_validation_identity_boundaries(changes, field):
    result = validate_newsletter_preference(VALID | changes)
    assert result.value is None
    assert field in [error.field for error in result.errors]
