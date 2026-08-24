"""Pure API-07 response projections."""

from __future__ import annotations

from datetime import datetime, timezone
from zoneinfo import ZoneInfo

from ..services.results import AvailabilityOutcome, BookingOutcome, ReservationAvailabilityResult, ReservationBookingResult, ReservationContextResult
from .common import ResponseProjection

_ADDRESS = "1234 Culinary Ave, Suite 100, Washington, DC 20002"
_PHONE = "(202) 555-4567"


def _instant(value: datetime) -> str:
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _local(value: datetime, zone: ZoneInfo) -> str:
    return value.astimezone(zone).isoformat(timespec="seconds")


def serialize_reservation_context(result: ReservationContextResult) -> ResponseProjection:
    return ResponseProjection(200, {
        "restaurant": {"address": _ADDRESS, "phone": _PHONE},
        "restaurant_timezone": result.restaurant_timezone,
        "weekday_hours": [{"iso_weekday": item.iso_weekday, "opens_at_local": item.opens_at_local.isoformat(timespec="seconds"), "closes_at_local": item.closes_at_local.isoformat(timespec="seconds")} for item in result.weekday_hours],
        "reservation_policy": {"start_interval_minutes": result.start_interval_minutes, "reservation_duration_minutes": result.reservation_duration_minutes, "advance_window_days": result.advance_window_days, "same_day_lead_minutes": result.same_day_lead_minutes},
        "reservable_date_range": {"minimum_local_date": result.minimum_local_date.isoformat(), "maximum_local_date": result.maximum_local_date.isoformat()},
        "maximum_party_size": result.maximum_party_size,
    })


def serialize_reservation_availability(result: ReservationAvailabilityResult) -> ResponseProjection:
    if result.outcome is AvailabilityOutcome.INVALID_REQUEST:
        fields = tuple({"field": field, "code": "out_of_range", "message": "The value is outside the current reservable range."} for field in ("local_date", "party_size"))
        return ResponseProjection(422, error_code="validation_failed", fields=fields)
    if result.outcome is not AvailabilityOutcome.SLOTS or result.restaurant_timezone is None:
        raise ValueError("unknown availability outcome")
    zone = ZoneInfo(result.restaurant_timezone)
    slots = []
    for slot in result.slots:
        local_start = slot.starts_at.astimezone(zone)
        offset = local_start.utcoffset()
        if offset is None:
            raise ValueError("availability offset unavailable")
        slots.append({
            "starts_at_local": _local(slot.starts_at, zone),
            "utc_offset_minutes": int(offset.total_seconds() // 60),
            "starts_at": _instant(slot.starts_at),
            "ends_at_local": _local(slot.ends_at, zone),
            "ends_at": _instant(slot.ends_at),
            "available": slot.available,
        })
    return ResponseProjection(200, {"local_date": result.request.local_date.isoformat(), "party_size": result.request.party_size, "restaurant_timezone": result.restaurant_timezone, "provisional": True, "slots": slots})


def _booking_validation(detail: str | None) -> ResponseProjection:
    mapping = {
        "nonexistent_local_start": ("starts_at_local", "nonexistent_local_time", "The selected local time does not exist."),
        "ambiguous_local_start": ("starts_at_local", "ambiguous_local_time", "The selected local time is ambiguous."),
        "utc_offset_mismatch": ("utc_offset_minutes", "utc_offset_mismatch", "The UTC offset does not match the selected time."),
        "date_outside_booking_window": ("starts_at_local", "date_outside_booking_window", "The selected date is outside the booking window."),
        "insufficient_same_day_lead": ("starts_at_local", "insufficient_same_day_lead", "The selected time does not meet the same-day lead time."),
        "start_before_opening": ("starts_at_local", "invalid_reservation_time", "The selected time is not a valid reservation start."),
        "misaligned_start": ("starts_at_local", "invalid_reservation_time", "The selected time is not a valid reservation start."),
        "end_after_closing": ("starts_at_local", "invalid_reservation_time", "The selected time is not a valid reservation start."),
        "duration_or_party_size_out_of_range": ("party_size", "out_of_range", "The party size is outside the current allowed range."),
    }
    if detail == "invalid_normalized_input":
        fields = tuple({"field": field, "code": "invalid_value", "message": "The submitted value was not accepted."} for field in (
            "first_name", "middle_initial", "last_name", "email", "confirmation_email", "phone", "starts_at_local", "utc_offset_minutes", "party_size", "newsletter_action",
        ))
    elif detail in mapping:
        field, code, message = mapping[detail]
        fields = ({"field": field, "code": code, "message": message},)
    else:
        raise ValueError("unknown caller-correctable booking detail")
    return ResponseProjection(422, error_code="validation_failed", fields=fields)


def serialize_reservation_booking(result: ReservationBookingResult) -> ResponseProjection:
    if result.outcome in {BookingOutcome.BOOKED, BookingOutcome.BOOKED_PHONE_NOTICE, BookingOutcome.EXACT_RETRY}:
        if any(value is None for value in (result.reservation_id, result.starts_at, result.ends_at, result.party_size, result.newsletter_subscribed, result.customer_name, result.restaurant_timezone)):
            raise ValueError("successful booking is incomplete")
        assert result.starts_at is not None and result.ends_at is not None and result.restaurant_timezone is not None
        zone = ZoneInfo(result.restaurant_timezone)
        payload = {
            "booking_result": "exact_retry" if result.outcome is BookingOutcome.EXACT_RETRY else "created",
            "confirmation": {
                "reservation_reference": str(result.reservation_id),
                "customer_name": result.customer_name,
                "starts_at_local": _local(result.starts_at, zone),
                "ends_at_local": _local(result.ends_at, zone),
                "starts_at": _instant(result.starts_at),
                "ends_at": _instant(result.ends_at),
                "party_size": result.party_size,
                "assigned_table_numbers": list(result.assigned_table_numbers),
                "newsletter_subscribed": result.newsletter_subscribed,
                "restaurant": {"address": _ADDRESS, "phone": _PHONE},
            },
        }
        if result.outcome is BookingOutcome.BOOKED_PHONE_NOTICE:
            payload["phone_notice"] = {
                "code": "stored_phone_preserved",
                "message": "The reservation was created, but the phone number already on file was kept.",
            }
        return ResponseProjection(200 if result.outcome is BookingOutcome.EXACT_RETRY else 201, payload)
    if result.outcome is BookingOutcome.CUSTOMER_IDENTITY_CONFLICT:
        return ResponseProjection(409, error_code="customer_identity_conflict")
    if result.outcome is BookingOutcome.MIDDLE_INITIAL_CONFLICT:
        return ResponseProjection(409, error_code="middle_initial_conflict")
    if result.outcome is BookingOutcome.SAME_CUSTOMER_OVERLAP:
        return ResponseProjection(409, error_code="reservation_overlap")
    if result.outcome is BookingOutcome.UNAVAILABLE or result.detail_code == "time_boundary_crossed_during_booking":
        return ResponseProjection(409, error_code="reservation_unavailable")
    if result.outcome is BookingOutcome.INVALID_REQUEST:
        return _booking_validation(result.detail_code)
    raise ValueError("unknown booking outcome")
