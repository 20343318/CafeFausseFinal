from __future__ import annotations

import pytest
from psycopg import OperationalError, ProgrammingError

from cafe_fausse.db.customer_gateway import CustomerGateway, _CUSTOMER_SELECT
from cafe_fausse.db.exceptions import DatabaseContractError, DatabaseUnavailable
from cafe_fausse.services.results import CustomerIdentity, NewsletterStatusOutcome


IDENTITY = CustomerIdentity("Ada", None, "Rivera", "ada@example.com")


class Context:
    def __init__(self, value=None, error=None, exits=None):
        self.value = value
        self.error = error
        self.exits = exits

    def __enter__(self):
        if self.error is not None:
            raise self.error
        return self.value

    def __exit__(self, *_):
        if self.exits is not None:
            self.exits.append(True)
        return False


class Cursor:
    def __init__(self, rows=(), execute_error=None):
        self.rows = list(rows)
        self.execute_error = execute_error
        self.calls = []
        self.exits = []

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.exits.append(True)
        return False

    def execute(self, statement, params=None):
        self.calls.append((statement, params))
        if len(self.calls) == 3 and self.execute_error is not None:
            raise self.execute_error

    def fetchall(self):
        return self.rows


class Connection:
    def __init__(self, cursor):
        self.cursor_value = cursor
        self.transaction_exits = []

    def transaction(self):
        return Context(exits=self.transaction_exits)

    def cursor(self):
        return self.cursor_value


class Pool:
    def __init__(self, rows=(), acquisition_error=None, execute_error=None):
        self.cursor = Cursor(rows, execute_error)
        self.connection_value = Connection(self.cursor)
        self.acquisition_error = acquisition_error
        self.connection_exits = []
        self.timeouts = []

    def connection(self, *, timeout):
        self.timeouts.append(timeout)
        return Context(self.connection_value, self.acquisition_error, self.connection_exits)


class Clock:
    def __init__(self, values):
        self.values = iter(values)

    def __call__(self):
        return next(self.values)


@pytest.mark.unit
@pytest.mark.parametrize(
    ("rows", "identity", "outcome", "subscribed"),
    [
        ([], IDENTITY, NewsletterStatusOutcome.NOT_FOUND, None),
        ([('Ada', None, 'Rivera', True)], IDENTITY, NewsletterStatusOutcome.MATCHED, True),
        ([('ADA', None, 'RIVERA', False)], IDENTITY, NewsletterStatusOutcome.MATCHED, False),
        ([('Other', None, 'Rivera', True)], IDENTITY, NewsletterStatusOutcome.CUSTOMER_IDENTITY_CONFLICT, None),
        ([('Ada', None, 'Other', True)], IDENTITY, NewsletterStatusOutcome.CUSTOMER_IDENTITY_CONFLICT, None),
        ([('Ada', 'M', 'Rivera', True)], CustomerIdentity('Ada', 'Q', 'Rivera', 'ada@example.com'), NewsletterStatusOutcome.MIDDLE_INITIAL_CONFLICT, None),
        ([('Ada', None, 'Rivera', True)], CustomerIdentity('Ada', 'M', 'Rivera', 'ada@example.com'), NewsletterStatusOutcome.MATCHED, True),
        ([('Ada', 'M', 'Rivera', True)], IDENTITY, NewsletterStatusOutcome.MATCHED, True),
    ],
)
def test_ut_api05_gateway_result_mapping_and_optional_middle(rows, identity, outcome, subscribed):
    pool = Pool(rows)
    result = CustomerGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).get_newsletter_status(
        identity, 1.0
    )
    assert (result.outcome, result.subscribed) == (outcome, subscribed)
    assert pool.connection_exits == [True]
    assert pool.connection_value.transaction_exits == [True]
    assert pool.cursor.exits == [True]


@pytest.mark.unit
def test_ut_api05_gateway_uses_only_fixed_parameterized_read_sql():
    pool = Pool([])
    CustomerGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).get_newsletter_status(
        IDENTITY, 1.0
    )
    assert pool.cursor.calls[0] == ("SET TRANSACTION READ ONLY", None)
    assert pool.cursor.calls[1][0].startswith("SELECT set_config")
    assert pool.cursor.calls[2] == (_CUSTOMER_SELECT, (IDENTITY.email,))
    normalized_sql = " ".join(_CUSTOMER_SELECT.lower().split())
    assert normalized_sql.startswith(
        "select first_name, middle_initial, last_name, newsletter_subscribed"
    )
    for forbidden in (
        "customer_id",
        "phone",
        "reservation",
        "assignment",
        "insert ",
        "update ",
        "delete ",
    ):
        assert forbidden not in normalized_sql


@pytest.mark.unit
def test_ut_api05_gateway_does_not_dispatch_after_acquisition_consumes_deadline():
    pool = Pool([])
    clock = Clock([0.0, 0.0, 1.0, 1.0, 1.0])
    with pytest.raises(DatabaseUnavailable) as raised:
        CustomerGateway(pool, acquire_timeout_ms=500, clock=clock).get_newsletter_status(
            IDENTITY, 1.0
        )
    assert raised.value.safe_to_retry is False
    assert raised.value.pool_wait_ms == 1000.0
    assert raised.value.database_ms == 0.0
    assert pool.cursor.calls == []
    assert pool.connection_value.transaction_exits == []
    assert pool.connection_exits == [True]


@pytest.mark.unit
def test_ut_api05_gateway_uses_positive_bounded_post_acquisition_statement_budget():
    pool = Pool([])
    clock = Clock([0.0, 0.0, 0.25, 0.25, 0.5])
    result = CustomerGateway(pool, acquire_timeout_ms=500, clock=clock).get_newsletter_status(
        IDENTITY, 1.0
    )
    assert result.outcome is NewsletterStatusOutcome.NOT_FOUND
    assert pool.cursor.calls == [
        ("SET TRANSACTION READ ONLY", None),
        ("SELECT set_config('statement_timeout', %s, true)", ("750ms",)),
        (_CUSTOMER_SELECT, (IDENTITY.email,)),
    ]
    assert pool.connection_exits == [True]


@pytest.mark.unit
def test_ut_api05_gateway_translates_acquisition_and_post_acquisition_failures():
    unavailable = Pool(acquisition_error=OperationalError())
    with pytest.raises(DatabaseUnavailable) as acquired:
        CustomerGateway(unavailable, acquire_timeout_ms=500, clock=lambda: 1.0).get_newsletter_status(
            IDENTITY, 1.0
        )
    assert acquired.value.safe_to_retry is True

    broken = Pool(execute_error=ProgrammingError())
    with pytest.raises(DatabaseContractError):
        CustomerGateway(broken, acquire_timeout_ms=500, clock=lambda: 1.0).get_newsletter_status(
            IDENTITY, 1.0
        )
    assert broken.connection_exits == [True]
    assert broken.connection_value.transaction_exits == [True]
    assert broken.cursor.exits == [True]


@pytest.mark.unit
@pytest.mark.parametrize(
    "rows",
    [
        [("Ada", None, "Rivera", True), ("Ada", None, "Rivera", True)],
        [("Ada", None, "Rivera")],
        [("Ada", 2, "Rivera", True)],
        [("Ada", None, "Rivera", 1)],
    ],
)
def test_ut_api05_gateway_rejects_impossible_or_leaky_row_shapes(rows):
    with pytest.raises(DatabaseContractError):
        CustomerGateway(Pool(rows), acquire_timeout_ms=500, clock=lambda: 1.0).get_newsletter_status(
            IDENTITY, 1.0
        )
