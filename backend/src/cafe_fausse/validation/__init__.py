"""Pure identity and newsletter input validation."""

from .identity import normalize_phone, validate_newsletter_status_identity
from .newsletter import validate_newsletter_preference

__all__ = [
    "normalize_phone",
    "validate_newsletter_preference",
    "validate_newsletter_status_identity",
]
from .reservation import validate_availability_query

__all__ = ["validate_availability_query"]
