from __future__ import annotations

import pytest
from psycopg import OperationalError, ProgrammingError
from psycopg.errors import InsufficientPrivilege, UndefinedTable

from cafe_fausse.db.health_gateway import PsycopgHealthGateway
from cafe_fausse.services.health import ReadinessProbeFailure
from cafe_fausse.services.results import ReadinessCategory


READY_ROW = (True, True, True, True, True, True)


class Context:
    def __init__(self, value=None, error=None):
        self.value = value
        self.error = error

    def __enter__(self):
        if self.error is not None:
            raise self.error
        return self.value

    def __exit__(self, *_):
        return False


class Cursor:
    def __init__(self, *, row=READY_ROW, execute_error=None, fetch_error=None):
        self.row = row
        self.execute_error = execute_error
        self.fetch_error = fetch_error
        self.execute_calls = 0

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False

    def execute(self, *_):
        self.execute_calls += 1
        if self.execute_calls == 3 and self.execute_error is not None:
            raise self.execute_error

    def fetchone(self):
        if self.fetch_error is not None:
            raise self.fetch_error
        return self.row


class Connection:
    def __init__(self, cursor):
        self.cursor_value = cursor

    def transaction(self):
        return Context()

    def cursor(self):
        return self.cursor_value


class Pool:
    def __init__(self, *, cursor=None, acquisition_error=None):
        self.cursor = cursor or Cursor()
        self.acquisition_error = acquisition_error

    def connection(self, *, timeout):
        return Context(
            Connection(self.cursor),
            self.acquisition_error,
        )


def failure_category(pool):
    gateway = PsycopgHealthGateway(pool, clock=lambda: 0.0)
    with pytest.raises(ReadinessProbeFailure) as raised:
        gateway.check_readiness(1000)
    return raised.value.category


@pytest.mark.unit
def test_ut_api_health_gateway_acquisition_failure_is_pool():
    """UT-API-READY-001: dependency acquisition failures remain pool failures."""
    assert failure_category(Pool(acquisition_error=RuntimeError())) is ReadinessCategory.POOL


@pytest.mark.unit
@pytest.mark.parametrize(
    "sql_error",
    [
        ProgrammingError(),
        UndefinedTable(),
        InsufficientPrivilege(),
    ],
)
def test_ut_api_health_gateway_post_acquisition_sql_defects_are_contract(sql_error):
    """UT-API-READY-002: SQL/signature/object/privilege defects are contractual."""
    category = failure_category(Pool(cursor=Cursor(execute_error=sql_error)))
    assert category is ReadinessCategory.CONTRACT
    assert category is not ReadinessCategory.POOL


@pytest.mark.unit
def test_ut_api_health_gateway_post_acquisition_result_failure_is_contract():
    """UT-API-READY-003: result decoding/shape failures are contractual."""
    category = failure_category(Pool(cursor=Cursor(fetch_error=ValueError())))
    assert category is ReadinessCategory.CONTRACT
    assert category is not ReadinessCategory.POOL


@pytest.mark.unit
def test_ut_api_health_gateway_post_acquisition_connectivity_is_pool():
    """UT-API-READY-004: a genuine connectivity failure remains a pool category."""
    category = failure_category(Pool(cursor=Cursor(execute_error=OperationalError())))
    assert category is ReadinessCategory.POOL
