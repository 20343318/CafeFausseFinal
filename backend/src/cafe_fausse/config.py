"""Immutable, secret-safe application configuration."""

from __future__ import annotations

from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation
import os
import platform
import re
import sys
import sysconfig
from typing import Mapping


class ConfigurationError(ValueError):
    """A safe configuration failure which never includes a configured value."""


_APP_NAMES = frozenset(
    {
        "CAFE_FAUSSE_ENVIRONMENT",
        "CAFE_FAUSSE_DEBUG",
        "CAFE_FAUSSE_POOL_MIN_SIZE",
        "CAFE_FAUSSE_POOL_MAX_SIZE",
        "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS",
        "CAFE_FAUSSE_READ_DEADLINE_MS",
        "CAFE_FAUSSE_MUTATION_DEADLINE_MS",
        "CAFE_FAUSSE_READINESS_DEADLINE_MS",
        "CAFE_FAUSSE_MAX_DB_ATTEMPTS",
        "CAFE_FAUSSE_RETRY_BASE_DELAY_MS",
        "CAFE_FAUSSE_RETRY_CAP_DELAY_MS",
        "CAFE_FAUSSE_RETRY_JITTER_RATIO",
        "CAFE_FAUSSE_RETRY_MIN_REMAINING_MS",
        "CAFE_FAUSSE_MAX_REQUEST_BYTES",
        "CAFE_FAUSSE_LOG_LEVEL",
        "CAFE_FAUSSE_LOG_FORMAT",
        "CAFE_FAUSSE_POOL_CLOSE_TIMEOUT_MS",
    }
)


def _missing(name: str) -> ConfigurationError:
    return ConfigurationError(f"Required configuration variable {name} is missing.")


def _text(values: Mapping[str, str], name: str, *, required: bool = False) -> str | None:
    value = values.get(name)
    if value is None or not value.strip():
        if required:
            raise _missing(name)
        return None
    return value


def _choice(
    values: Mapping[str, str], name: str, allowed: frozenset[str], default: str | None = None
) -> str:
    value = _text(values, name)
    if value is None:
        if default is None:
            raise _missing(name)
        return default
    if value not in allowed:
        raise ConfigurationError(f"Configuration variable {name} has an invalid value.")
    return value


def _integer(
    values: Mapping[str, str], name: str, default: int, minimum: int, maximum: int
) -> int:
    raw = _text(values, name)
    if raw is None:
        return default
    try:
        value = int(raw, 10)
    except ValueError as exc:
        raise ConfigurationError(f"Configuration variable {name} must be an integer.") from exc
    if str(value) != raw:
        raise ConfigurationError(f"Configuration variable {name} must be an integer.")
    if not minimum <= value <= maximum:
        raise ConfigurationError(f"Configuration variable {name} is outside its allowed range.")
    return value


def _decimal(
    values: Mapping[str, str], name: str, default: str, minimum: Decimal, maximum: Decimal
) -> Decimal:
    raw = _text(values, name) or default
    try:
        value = Decimal(raw)
    except InvalidOperation as exc:
        raise ConfigurationError(f"Configuration variable {name} must be a decimal.") from exc
    if not value.is_finite() or not minimum <= value <= maximum:
        raise ConfigurationError(f"Configuration variable {name} is outside its allowed range.")
    return value


@dataclass(frozen=True, slots=True)
class Settings:
    environment: str
    debug: bool
    pghost: str = field(repr=False)
    pgport: int
    pgdatabase: str = field(repr=False)
    pguser: str = field(repr=False)
    pgpassword: str | None = field(default=None, repr=False)
    pgpassfile: str | None = field(default=None, repr=False)
    pgsslmode: str | None = field(default=None, repr=False)
    pgconnect_timeout: int = 3
    pool_min_size: int = 1
    pool_max_size: int = 5
    pool_acquire_timeout_ms: int = 500
    read_deadline_ms: int = 2000
    mutation_deadline_ms: int = 15000
    readiness_deadline_ms: int = 1000
    max_db_attempts: int = 3
    retry_base_delay_ms: int = 25
    retry_cap_delay_ms: int = 200
    retry_jitter_ratio: Decimal = Decimal("0.25")
    retry_min_remaining_ms: int = 500
    max_request_bytes: int = 16384
    log_level: str = "INFO"
    log_format: str = "text"
    pool_close_timeout_ms: int = 1000

    @classmethod
    def from_environment(cls, environ: Mapping[str, str] | None = None) -> "Settings":
        values = dict(os.environ if environ is None else environ)
        unknown = sorted(
            name for name in values if name.startswith("CAFE_FAUSSE_") and name not in _APP_NAMES
        )
        if unknown:
            raise ConfigurationError(f"Unknown Cafe Fausse configuration variable: {unknown[0]}.")

        environment = _choice(
            values,
            "CAFE_FAUSSE_ENVIRONMENT",
            frozenset({"development", "test", "production"}),
        )
        debug_text = _choice(
            values, "CAFE_FAUSSE_DEBUG", frozenset({"true", "false"}), "false"
        )
        debug = debug_text == "true"
        if debug and environment != "development":
            raise ConfigurationError("Debug mode is allowed only in development.")

        pghost = _text(values, "PGHOST", required=True)
        pgdatabase = _text(values, "PGDATABASE", required=True)
        pguser = _text(values, "PGUSER", required=True)
        assert pghost is not None and pgdatabase is not None and pguser is not None
        if environment == "test" and re.fullmatch(r"cafe_fausse_test_[a-z0-9_]+", pgdatabase) is None:
            raise ConfigurationError("Test configuration requires an approved nonproduction database name.")

        pgpassword = _text(values, "PGPASSWORD")
        pgpassfile = _text(values, "PGPASSFILE")
        if pgpassword is not None and pgpassfile is not None:
            raise ConfigurationError("PGPASSWORD and PGPASSFILE cannot both be configured.")
        pgsslmode = _text(values, "PGSSLMODE")
        ssl_modes = frozenset({"disable", "allow", "prefer", "require", "verify-ca", "verify-full"})
        if pgsslmode is not None and pgsslmode not in ssl_modes:
            raise ConfigurationError("Configuration variable PGSSLMODE has an invalid value.")
        network_host = not pghost.startswith("/") and not pghost.startswith("\\")
        if environment == "production" and network_host and pgsslmode == "disable":
            raise ConfigurationError("Production network connections may not disable PostgreSQL TLS.")

        min_size = _integer(values, "CAFE_FAUSSE_POOL_MIN_SIZE", 1, 0, 5)
        max_size = _integer(values, "CAFE_FAUSSE_POOL_MAX_SIZE", 5, 1, 20)
        if min_size > max_size:
            raise ConfigurationError("Pool minimum size must not exceed pool maximum size.")
        retry_base = _integer(values, "CAFE_FAUSSE_RETRY_BASE_DELAY_MS", 25, 10, 250)
        retry_cap = _integer(values, "CAFE_FAUSSE_RETRY_CAP_DELAY_MS", 200, 50, 1000)
        if retry_base > retry_cap:
            raise ConfigurationError("Retry base delay must not exceed retry cap delay.")

        log_default = "DEBUG" if environment == "development" else "INFO"
        format_default = "json" if environment == "production" else "text"
        log_level = _choice(
            values,
            "CAFE_FAUSSE_LOG_LEVEL",
            frozenset({"DEBUG", "INFO", "WARNING", "ERROR"}),
            log_default,
        )
        log_format = _choice(
            values, "CAFE_FAUSSE_LOG_FORMAT", frozenset({"text", "json"}), format_default
        )
        if environment == "production" and log_level == "DEBUG":
            raise ConfigurationError("Production logging may not use DEBUG level.")
        if environment == "production" and log_format != "json":
            raise ConfigurationError("Production logging requires JSON format.")

        max_attempts = _integer(values, "CAFE_FAUSSE_MAX_DB_ATTEMPTS", 3, 1, 3)
        if environment == "production" and max_attempts != 3:
            raise ConfigurationError("Production requires exactly three database attempts.")

        return cls(
            environment=environment,
            debug=debug,
            pghost=pghost,
            pgport=_integer(values, "PGPORT", 5432, 1, 65535),
            pgdatabase=pgdatabase,
            pguser=pguser,
            pgpassword=pgpassword,
            pgpassfile=pgpassfile,
            pgsslmode=pgsslmode,
            pgconnect_timeout=_integer(values, "PGCONNECT_TIMEOUT", 3, 1, 10),
            pool_min_size=min_size,
            pool_max_size=max_size,
            pool_acquire_timeout_ms=_integer(values, "CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS", 500, 50, 3000),
            read_deadline_ms=_integer(values, "CAFE_FAUSSE_READ_DEADLINE_MS", 2000, 250, 5000),
            mutation_deadline_ms=_integer(values, "CAFE_FAUSSE_MUTATION_DEADLINE_MS", 15000, 3000, 15000),
            readiness_deadline_ms=_integer(values, "CAFE_FAUSSE_READINESS_DEADLINE_MS", 1000, 100, 3000),
            max_db_attempts=max_attempts,
            retry_base_delay_ms=retry_base,
            retry_cap_delay_ms=retry_cap,
            retry_jitter_ratio=_decimal(values, "CAFE_FAUSSE_RETRY_JITTER_RATIO", "0.25", Decimal("0.0"), Decimal("0.5")),
            retry_min_remaining_ms=_integer(values, "CAFE_FAUSSE_RETRY_MIN_REMAINING_MS", 500, 100, 2000),
            max_request_bytes=_integer(values, "CAFE_FAUSSE_MAX_REQUEST_BYTES", 16384, 4096, 65536),
            log_level=log_level,
            log_format=log_format,
            pool_close_timeout_ms=_integer(values, "CAFE_FAUSSE_POOL_CLOSE_TIMEOUT_MS", 1000, 100, 5000),
        )

    def connection_kwargs(self) -> dict[str, object]:
        values: dict[str, object] = {
            "host": self.pghost,
            "port": self.pgport,
            "dbname": self.pgdatabase,
            "user": self.pguser,
            "connect_timeout": self.pgconnect_timeout,
        }
        if self.pgpassword is not None:
            values["password"] = self.pgpassword
        if self.pgpassfile is not None:
            values["passfile"] = self.pgpassfile
        if self.pgsslmode is not None:
            values["sslmode"] = self.pgsslmode
        return values


@dataclass(frozen=True, slots=True)
class PlatformEvidence:
    windows_server_2025: bool
    implementation: str
    version: tuple[int, int, int]
    gil_enabled: bool
    architecture_bits: int
    executable: str = field(repr=False)


def inspect_platform_evidence() -> PlatformEvidence:
    version_text = platform.version()
    release_text = platform.release()
    is_server_2025 = sys.platform == "win32" and (
        "2025" in release_text or int(version_text.split(".")[2]) >= 26100
    )
    gil_probe = getattr(sys, "_is_gil_enabled", None)
    gil_enabled = bool(gil_probe()) if gil_probe is not None else sysconfig.get_config_var("Py_GIL_DISABLED") == 0
    return PlatformEvidence(
        windows_server_2025=is_server_2025,
        implementation=platform.python_implementation(),
        version=sys.version_info[:3],
        gil_enabled=gil_enabled,
        architecture_bits=64 if sys.maxsize > 2**32 else 32,
        executable=sys.executable,
    )


def require_formal_acceptance_platform(evidence: PlatformEvidence | None = None) -> PlatformEvidence:
    """Test-only formal evidence gate; ordinary app construction never calls it."""
    actual = evidence or inspect_platform_evidence()
    failures: list[str] = []
    if not actual.windows_server_2025:
        failures.append("Windows Server 2025")
    if actual.implementation != "CPython":
        failures.append("CPython implementation")
    if actual.version != (3, 14, 6):
        failures.append("CPython 3.14.6")
    if not actual.gil_enabled:
        failures.append("enabled standard GIL")
    if actual.architecture_bits != 64:
        failures.append("64-bit architecture")
    if failures:
        raise RuntimeError("Formal acceptance platform mismatch: " + ", ".join(failures) + ".")
    return actual
