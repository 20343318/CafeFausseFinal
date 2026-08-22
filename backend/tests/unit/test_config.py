from __future__ import annotations

from dataclasses import replace

import pytest

from cafe_fausse.config import (
    ConfigurationError,
    PlatformEvidence,
    Settings,
    require_formal_acceptance_platform,
)


BASE = {
    "CAFE_FAUSSE_ENVIRONMENT": "development",
    "PGHOST": "localhost",
    "PGDATABASE": "cafe_fausse_dev",
    "PGUSER": "deployment_login",
}


@pytest.mark.unit
def test_ut_api_config_defaults_and_immutable_value():
    """UT-API-CONFIG-001: every catalogue default is exact and immutable."""
    settings = Settings.from_environment(BASE)
    assert (
        settings.debug,
        settings.pgport,
        settings.pgconnect_timeout,
        settings.pool_min_size,
        settings.pool_max_size,
        settings.pool_acquire_timeout_ms,
        settings.read_deadline_ms,
        settings.mutation_deadline_ms,
        settings.readiness_deadline_ms,
        settings.max_db_attempts,
        settings.retry_base_delay_ms,
        settings.retry_cap_delay_ms,
        str(settings.retry_jitter_ratio),
        settings.retry_min_remaining_ms,
        settings.max_request_bytes,
        settings.log_level,
        settings.log_format,
        settings.pool_close_timeout_ms,
    ) == (False, 5432, 3, 1, 5, 500, 2000, 15000, 1000, 3, 25, 200, "0.25", 500, 16384, "DEBUG", "text", 1000)
    with pytest.raises(Exception):
        settings.debug = True


@pytest.mark.unit
@pytest.mark.parametrize("name", ["CAFE_FAUSSE_ENVIRONMENT", "PGHOST", "PGDATABASE", "PGUSER"])
@pytest.mark.parametrize("missing", [None, "", "   "])
def test_ut_api_config_required_values(name, missing):
    """UT-API-CONFIG-002: required values reject absence and whitespace."""
    values = BASE.copy()
    if missing is None:
        values.pop(name)
    else:
        values[name] = missing
    with pytest.raises(ConfigurationError, match=name):
        Settings.from_environment(values)


INTEGER_CASES = [
    ("PGPORT", 1, 65535),
    ("PGCONNECT_TIMEOUT", 1, 10),
    ("CAFE_FAUSSE_POOL_MIN_SIZE", 0, 5),
    ("CAFE_FAUSSE_POOL_MAX_SIZE", 1, 20),
    ("CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS", 50, 3000),
    ("CAFE_FAUSSE_READ_DEADLINE_MS", 250, 5000),
    ("CAFE_FAUSSE_MUTATION_DEADLINE_MS", 3000, 15000),
    ("CAFE_FAUSSE_READINESS_DEADLINE_MS", 100, 3000),
    ("CAFE_FAUSSE_MAX_DB_ATTEMPTS", 1, 3),
    ("CAFE_FAUSSE_RETRY_BASE_DELAY_MS", 10, 250),
    ("CAFE_FAUSSE_RETRY_CAP_DELAY_MS", 50, 1000),
    ("CAFE_FAUSSE_RETRY_MIN_REMAINING_MS", 100, 2000),
    ("CAFE_FAUSSE_MAX_REQUEST_BYTES", 4096, 65536),
    ("CAFE_FAUSSE_POOL_CLOSE_TIMEOUT_MS", 100, 5000),
]


@pytest.mark.unit
@pytest.mark.parametrize(("name", "minimum", "maximum"), INTEGER_CASES)
def test_ut_api_config_integer_boundaries(name, minimum, maximum):
    """UT-API-CONFIG-003: every integer setting accepts both bounds and rejects outside/type."""
    for value in (minimum, maximum):
        additions = {name: str(value)}
        if name == "CAFE_FAUSSE_RETRY_BASE_DELAY_MS" and value == maximum:
            additions["CAFE_FAUSSE_RETRY_CAP_DELAY_MS"] = str(value)
        Settings.from_environment(BASE | additions)
    for value in (str(minimum - 1), str(maximum + 1), "1.5", "true", "+1", "01"):
        with pytest.raises(ConfigurationError):
            Settings.from_environment(BASE | {name: value})


@pytest.mark.unit
@pytest.mark.parametrize("value", ["0.0", "0.5"])
def test_ut_api_config_jitter_boundaries(value):
    Settings.from_environment(BASE | {"CAFE_FAUSSE_RETRY_JITTER_RATIO": value})


@pytest.mark.unit
@pytest.mark.parametrize("value", ["-0.01", "0.51", "NaN", "Infinity", "words"])
def test_ut_api_config_jitter_invalid(value):
    with pytest.raises(ConfigurationError):
        Settings.from_environment(BASE | {"CAFE_FAUSSE_RETRY_JITTER_RATIO": value})


@pytest.mark.unit
def test_ut_api_config_cross_field_and_environment_restrictions():
    cases = [
        {"CAFE_FAUSSE_POOL_MIN_SIZE": "5", "CAFE_FAUSSE_POOL_MAX_SIZE": "4"},
        {"CAFE_FAUSSE_RETRY_BASE_DELAY_MS": "250", "CAFE_FAUSSE_RETRY_CAP_DELAY_MS": "200"},
        {"CAFE_FAUSSE_ENVIRONMENT": "test", "PGDATABASE": "cafe_fausse_dev"},
        {"CAFE_FAUSSE_ENVIRONMENT": "test", "PGDATABASE": "cafe_fausse_test_api04", "CAFE_FAUSSE_DEBUG": "true"},
        {"CAFE_FAUSSE_ENVIRONMENT": "production", "CAFE_FAUSSE_LOG_LEVEL": "DEBUG"},
        {"CAFE_FAUSSE_ENVIRONMENT": "production", "CAFE_FAUSSE_LOG_FORMAT": "text"},
        {"CAFE_FAUSSE_ENVIRONMENT": "production", "CAFE_FAUSSE_MAX_DB_ATTEMPTS": "2"},
        {"CAFE_FAUSSE_ENVIRONMENT": "production", "PGSSLMODE": "disable"},
        {"PGPASSWORD": "secret-one", "PGPASSFILE": "secret-two"},
    ]
    for additions in cases:
        with pytest.raises(ConfigurationError):
            Settings.from_environment(BASE | additions)


@pytest.mark.unit
def test_ut_api_config_unknown_names_and_case_sensitive_values():
    with pytest.raises(ConfigurationError, match="CAFE_FAUSSE_TYPO"):
        Settings.from_environment(BASE | {"CAFE_FAUSSE_TYPO": "x"})
    with pytest.raises(ConfigurationError):
        Settings.from_environment(BASE | {"CAFE_FAUSSE_DEBUG": "TRUE"})
    Settings.from_environment(BASE | {"UNRELATED_VARIABLE": "ignored"})


@pytest.mark.unit
def test_ut_api_config_secrets_absent_from_repr_and_errors():
    secret = "sentinel-password-very-secret"
    settings = Settings.from_environment(BASE | {"PGPASSWORD": secret})
    assert secret not in repr(settings)
    assert "localhost" not in repr(settings)
    assert "cafe_fausse_dev" not in repr(settings)
    try:
        Settings.from_environment(BASE | {"PGPASSWORD": secret, "PGPASSFILE": secret})
    except ConfigurationError as exc:
        assert secret not in str(exc)


@pytest.mark.unit
def test_ut_api_formal_platform_guard_positive_and_negative():
    """UT-API-PLATFORM-001: formal evidence is test-only and exact."""
    good = PlatformEvidence(True, "CPython", (3, 14, 6), True, 64, "private")
    assert require_formal_acceptance_platform(good) is good
    for bad in (
        replace(good, windows_server_2025=False),
        replace(good, implementation="PyPy"),
        replace(good, version=(3, 14, 5)),
        replace(good, gil_enabled=False),
        replace(good, architecture_bits=32),
    ):
        with pytest.raises(RuntimeError, match="Formal acceptance platform mismatch"):
            require_formal_acceptance_platform(bad)
