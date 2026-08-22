"""Cafe Fausse backend package (side-effect free)."""

from .application import close_resources, create_app

__all__ = ["close_resources", "create_app"]
