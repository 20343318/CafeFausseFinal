"""Pure API-07 response projections."""

from __future__ import annotations

from datetime import datetime, timezone
from zoneinfo import ZoneInfo

from ..services.results import AvailabilityOutcome, ReservationAvailabilityResult, ReservationContextResult
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
