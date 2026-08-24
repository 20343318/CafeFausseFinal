"""Pure common response projections."""

from .common import (
    ResponseProjection,
    serialize_newsletter_preference,
    serialize_newsletter_status,
)

__all__ = [
    "ResponseProjection",
    "serialize_newsletter_preference",
    "serialize_newsletter_status",
]
from .reservation import serialize_reservation_availability, serialize_reservation_context

__all__ = ["serialize_reservation_availability", "serialize_reservation_context"]
