from __future__ import annotations

import pytest

from cafe_fausse.validation.identity import (
    normalize_phone,
    validate_newsletter_status_identity,
)


VALID = {
    "first_name": "Ada",
    "last_name": "Rivera",
    "email": "ada.rivera@example.com",
    "confirmation_email": "ada.rivera@example.com",
}


@pytest.mark.unit
def test_ut_api05_identity_required_normalization_case_and_transience():
    """UT-API-OP03-VAL-001: normalize identity and discard confirmation."""
    result = validate_newsletter_status_identity(
        VALID
        | {
            "first_name": "  Ada\t María  ",
            "middle_initial": "m.",
            "last_name": "  de   Rivera ",
            "email": " ADA.RIVERA@EXAMPLE.COM ",
        }
    )
    assert not result.errors
    assert result.value is not None
    assert (
        result.value.first_name,
        result.value.middle_initial,
        result.value.last_name,
        result.value.email,
    ) == ("Ada María", "M", "de Rivera", "ada.rivera@example.com")
    assert not hasattr(result.value, "confirmation_email")
    assert "ada.rivera" not in repr(result.value)


@pytest.mark.unit
@pytest.mark.parametrize("middle", ["a", "A", "a.", " A. ", "é", "é."])
def test_ut_api05_valid_middle_initials(middle):
    result = validate_newsletter_status_identity(VALID | {"middle_initial": middle})
    assert result.errors == ()
    assert result.value is not None
    assert len(result.value.middle_initial or "") == 1
    assert result.value.middle_initial == middle.strip().removesuffix(".").upper()


@pytest.mark.unit
@pytest.mark.parametrize("middle", ["", " ", ".", "AB", "A..", "1", None, True, "ß"])
def test_ut_api05_invalid_middle_initials(middle):
    result = validate_newsletter_status_identity(VALID | {"middle_initial": middle})
    assert result.value is None
    assert [error.field for error in result.errors] == ["middle_initial"]


@pytest.mark.unit
def test_ut_api05_omitted_middle_initial_is_none():
    result = validate_newsletter_status_identity(VALID)
    assert result.value is not None
    assert result.value.middle_initial is None


@pytest.mark.unit
@pytest.mark.parametrize(
    "email",
    [
        "a@example.com",
        "first.last+tag@example-domain.com",
        "customer@localhost",
        "x!#$%&'*+-/=?^_`{|}~@example.com",
    ],
)
def test_ut_api05_valid_email_profile(email):
    result = validate_newsletter_status_identity(
        VALID | {"email": email, "confirmation_email": email.upper()}
    )
    assert result.errors == ()
    assert result.value is not None
    assert result.value.email == email.lower()


@pytest.mark.unit
@pytest.mark.parametrize(
    "email",
    [
        "plainaddress",
        "@example.com",
        "a@",
        ".a@example.com",
        "a.@example.com",
        "a..b@example.com",
        "a@-example.com",
        "a@example-.com",
        "a@example..com",
        '"a"@example.com',
        "Ada <a@example.com>",
        "a@[127.0.0.1]",
        "a b@example.com",
    ],
)
def test_ut_api05_invalid_email_profile(email):
    result = validate_newsletter_status_identity(
        VALID | {"email": email, "confirmation_email": email}
    )
    assert result.value is None
    assert any(error.field == "email" for error in result.errors)


@pytest.mark.unit
def test_ut_api05_confirmation_mismatch_is_ordered_and_safe():
    result = validate_newsletter_status_identity(
        VALID | {"confirmation_email": "different@example.com"}
    )
    assert result.value is None
    assert [error.as_dict() for error in result.errors] == [
        {
            "field": "confirmation_email",
            "code": "email_mismatch",
            "message": "The email addresses must match.",
        }
    ]
    assert "different@example.com" not in repr(result.errors)


@pytest.mark.unit
@pytest.mark.parametrize("field", ["first_name", "last_name", "email", "confirmation_email"])
def test_ut_api05_missing_required_fields(field):
    payload = VALID.copy()
    payload.pop(field)
    result = validate_newsletter_status_identity(payload)
    assert result.value is None
    assert any(error.field == field and error.code == "required" for error in result.errors)


@pytest.mark.unit
@pytest.mark.parametrize("field", ["first_name", "last_name", "email", "confirmation_email"])
@pytest.mark.parametrize("value", [None, True, 12, [], {}])
def test_ut_api05_null_and_nonstring_required_fields(field, value):
    result = validate_newsletter_status_identity(VALID | {field: value})
    assert result.value is None
    assert [error.field for error in result.errors] == [field]


@pytest.mark.unit
@pytest.mark.parametrize("field", ["first_name", "last_name", "email", "confirmation_email"])
@pytest.mark.parametrize("value", ["", "   "])
def test_ut_api05_empty_required_fields(field, value):
    result = validate_newsletter_status_identity(VALID | {field: value})
    assert result.value is None
    assert any(error.field == field and error.code == "empty" for error in result.errors)


@pytest.mark.unit
def test_ut_api05_length_and_unicode_letter_boundaries():
    accepted = validate_newsletter_status_identity(VALID | {"first_name": "Á" * 100})
    assert accepted.value is not None
    too_long = validate_newsletter_status_identity(VALID | {"first_name": "Á" * 101})
    punctuation_only = validate_newsletter_status_identity(VALID | {"last_name": "---'"})
    assert too_long.errors[0].code == "too_long"
    assert punctuation_only.errors[0].code == "invalid_format"
    long_email = "a" * 243 + "@example.com"
    assert len(long_email) == 255
    assert validate_newsletter_status_identity(
        VALID | {"email": long_email, "confirmation_email": long_email}
    ).errors[0].code == "too_long"


@pytest.mark.unit
def test_ut_api05_multiple_errors_follow_contract_field_order():
    result = validate_newsletter_status_identity(
        {
            "first_name": "",
            "middle_initial": "12",
            "last_name": None,
            "email": "bad",
            "confirmation_email": 4,
        }
    )
    assert [error.field for error in result.errors] == [
        "first_name",
        "middle_initial",
        "last_name",
        "email",
        "confirmation_email",
    ]


@pytest.mark.unit
def test_ut_api05_phone_omission_and_transient_digit_normalization():
    result = normalize_phone(" +1 (202) 555-0198 ")
    assert result.value is not None
    assert (result.value.display, result.value.digits) == (
        "+1 (202) 555-0198",
        "12025550198",
    )


@pytest.mark.unit
@pytest.mark.parametrize(
    "phone",
    [None, "", "123", "1234567890123456", "202/555/0198", 2025550198, "1" * 33],
)
def test_ut_api05_invalid_phone_values(phone):
    result = normalize_phone(phone)
    assert result.value is None
    assert result.errors[0].field == "phone"
