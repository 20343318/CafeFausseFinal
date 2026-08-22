"""Safe database exception categories."""


class DatabaseUnavailable(Exception):
    """A dependency failure safe to expose only as a coarse category."""


class DatabaseContractError(Exception):
    """The frozen PostgreSQL contract is not usable."""
