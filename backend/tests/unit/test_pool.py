from __future__ import annotations

import pytest

import cafe_fausse.db.pool as pool_module
from cafe_fausse.db.pool import check_session, configure_session, create_pool


class Cursor:
    def __init__(self, role="cafe_fausse_app"):
        self.role = role
        self.statements = []
    def __enter__(self):
        return self
    def __exit__(self, *_):
        return False
    def execute(self, statement):
        self.statements.append(statement)
    def fetchone(self):
        return (self.role,)


class Info:
    transaction_status = pool_module.TransactionStatus.IDLE


class Connection:
    def __init__(self, role="cafe_fausse_app"):
        self.cursor_value = Cursor(role)
        self.info = Info()
        self.commits = 0
        self.closed = 0
    def cursor(self):
        return self.cursor_value
    def commit(self):
        self.commits += 1
    def close(self):
        self.closed += 1


@pytest.mark.unit
def test_ut_api_pool_fixed_session_configuration_and_wrong_role_discard():
    """UT-API-POOL-001: fixed SQL sets application name/role and verifies the role."""
    connection = Connection()
    configure_session(connection)
    assert connection.cursor_value.statements == [
        "SET SESSION application_name = 'cafe_fausse_api'",
        "SET ROLE cafe_fausse_app",
        "SELECT current_user",
    ]
    assert connection.commits == 1
    wrong = Connection("wrong_role")
    with pytest.raises(RuntimeError):
        configure_session(wrong)
    assert wrong.closed >= 1


@pytest.mark.unit
def test_ut_api_pool_check_verifies_idle_role(monkeypatch):
    monkeypatch.setattr(pool_module.ConnectionPool, "check_connection", lambda connection: None)
    connection = Connection()
    check_session(connection)
    assert connection.cursor_value.statements == ["SELECT current_user"]
    assert connection.commits == 1


@pytest.mark.unit
def test_ut_api_pool_construction_is_bounded_unopened_and_secret_safe(monkeypatch, settings):
    captured = {}
    class FakePool:
        def __init__(self, **kwargs):
            captured.update(kwargs)
    monkeypatch.setattr(pool_module, "ConnectionPool", FakePool)
    result = create_pool(settings)
    assert isinstance(result, FakePool)
    assert captured["open"] is False
    assert captured["min_size"] == 0
    assert captured["max_size"] == 2
    assert captured["timeout"] == 0.5
    assert captured["kwargs"]["application_name"] == "cafe_fausse_api"
    assert "conninfo" in captured and captured["conninfo"] == ""
