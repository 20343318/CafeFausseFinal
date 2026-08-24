from __future__ import annotations

import pytest

from cafe_fausse.db.exceptions import DatabaseContractError, DatabaseMutationFailure
from cafe_fausse.db.newsletter_gateway import NewsletterGateway, _PREFERENCE_SQL
from cafe_fausse.services.results import (
    NewsletterPreferenceCommand,
    NewsletterPreferenceOutcome,
)


COMMAND = NewsletterPreferenceCommand("Ada", None, "Rivera", "ada@example.com", True)


class DriverFailure(Exception):
    def __init__(self, sqlstate=None):
        super().__init__("private driver detail")
        self.sqlstate = sqlstate


class Cursor:
    def __init__(self, rows=None, execute_error=None, fetch_error=None):
        self.rows = [("subscribed", True)] if rows is None else rows
        self.execute_error = execute_error
        self.fetch_error = fetch_error
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
        if self.fetch_error is not None:
            raise self.fetch_error
        return list(self.rows)


class Connection:
    def __init__(
        self,
        cursor,
        commit_error=None,
        rollback_error=None,
        close_error=None,
    ):
        self.cursor_value = cursor
        self.commit_error = commit_error
        self.rollback_error = rollback_error
        self.close_error = close_error
        self.commits = 0
        self.rollbacks = 0
        self.closes = 0
        self.closed = False
        self.exits = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, _traceback):
        self.exits.append((exc_type, exc))
        if exc_type is None:
            self.commit()
        else:
            self.rollback()
        return False

    def cursor(self):
        return self.cursor_value

    def commit(self):
        self.commits += 1
        if self.commit_error is not None:
            raise self.commit_error

    def rollback(self):
        self.rollbacks += 1
        if self.rollback_error is not None:
            raise self.rollback_error

    def close(self):
        self.closes += 1
        if self.close_error is not None:
            raise self.close_error
        self.closed = True


class Pool:
    def __init__(
        self,
        rows=None,
        acquisition_error=None,
        execute_error=None,
        fetch_error=None,
        commit_error=None,
        rollback_error=None,
        close_error=None,
        putconn_error=None,
    ):
        self.cursor = Cursor(rows, execute_error, fetch_error)
        self.connection_value = Connection(
            self.cursor,
            commit_error,
            rollback_error,
            close_error,
        )
        self.acquisition_error = acquisition_error
        self.putconn_error = putconn_error
        self.timeouts = []
        self.puts = []
        self.reusable_returns = []
        self.discarded_returns = []

    def getconn(self, *, timeout):
        self.timeouts.append(timeout)
        if self.acquisition_error is not None:
            raise self.acquisition_error
        return self.connection_value

    def putconn(self, connection):
        self.puts.append(connection)
        if self.putconn_error is not None:
            raise self.putconn_error
        if connection.closed:
            self.discarded_returns.append(connection)
        else:
            self.reusable_returns.append(connection)


class Clock:
    def __init__(self, values):
        self.values = iter(values)

    def __call__(self):
        return next(self.values)


@pytest.mark.unit
@pytest.mark.parametrize(
    ("row", "outcome", "subscribed"),
    [
        (("subscribed", True), NewsletterPreferenceOutcome.SUBSCRIBED, True),
        (("unsubscribed", False), NewsletterPreferenceOutcome.UNSUBSCRIBED, False),
        (("no_customer_no_change", False), NewsletterPreferenceOutcome.NO_CUSTOMER_NO_CHANGE, False),
        (("invalid_request", None), NewsletterPreferenceOutcome.INVALID_REQUEST, None),
        (("customer_identity_mismatch", True), NewsletterPreferenceOutcome.CUSTOMER_IDENTITY_CONFLICT, None),
        (("middle_initial_conflict", False), NewsletterPreferenceOutcome.MIDDLE_INITIAL_CONFLICT, None),
    ],
)
def test_ut_api06_gateway_maps_every_stable_outcome(row, outcome, subscribed):
    pool = Pool([row])
    result = NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
        COMMAND, 1.0
    )
    assert (result.outcome, result.subscribed) == (outcome, subscribed)
    assert pool.connection_value.commits == 1
    assert pool.connection_value.rollbacks == 0
    assert pool.connection_value.exits == [(None, None)]
    assert pool.puts == [pool.connection_value]


@pytest.mark.unit
def test_ut_api06_gateway_exact_transaction_routine_and_parameters():
    pool = Pool()
    NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(COMMAND, 1.0)
    assert pool.cursor.calls == [
        ("BEGIN ISOLATION LEVEL READ COMMITTED", None),
        ("SELECT set_config('statement_timeout', %s, true)", ("1000ms",)),
        (
            _PREFERENCE_SQL,
            ("Ada", None, "Rivera", "ada@example.com", True),
        ),
    ]
    normalized = " ".join(_PREFERENCE_SQL.lower().split())
    assert normalized == (
        "select outcome, newsletter_subscribed from "
        "cafe_fausse.set_newsletter_preference(%s, %s, %s, %s, %s)"
    )
    for forbidden in ("insert ", "update ", "delete ", "reservation", "assignment"):
        assert forbidden not in normalized
    assert type(pool.cursor.calls[2][1][4]) is bool


@pytest.mark.unit
def test_ut_api06_gateway_post_acquisition_submillisecond_budget_dispatches_nothing():
    pool = Pool()
    clock = Clock([0.0, 0.0, 0.9995, 0.9995, 1.0])
    with pytest.raises(DatabaseMutationFailure) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=clock).set_preference(COMMAND, 1.0)
    assert raised.value.mutation_dispatched is False
    assert raised.value.outcome_unknown is False
    assert pool.cursor.calls == []
    assert pool.connection_value.commits == 0
    assert pool.connection_value.rollbacks == 1
    assert pool.puts == [pool.connection_value]


@pytest.mark.unit
@pytest.mark.parametrize(
    "rows",
    [
        [],
        [("subscribed", True), ("subscribed", True)],
        [("unknown", True)],
        [("subscribed", False)],
        [("unsubscribed", True)],
        [("no_customer_no_change", True)],
        [("subscribed", 1)],
        [("invalid_request", False)],
        [("customer_identity_mismatch", None)],
        [("subscribed", True, "extra")],
    ],
)
def test_ut_api06_gateway_contract_defects_roll_back_before_commit(rows):
    pool = Pool(rows)
    with pytest.raises(DatabaseContractError):
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )
    assert pool.connection_value.rollbacks == 1
    assert pool.connection_value.commits == 0


@pytest.mark.unit
@pytest.mark.parametrize("sqlstate", ["55P03", "40P01", "40001"])
def test_ut_api06_gateway_confirmed_retryable_rollback(sqlstate):
    pool = Pool(execute_error=DriverFailure(sqlstate))
    with pytest.raises(DatabaseMutationFailure) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )
    assert raised.value.safe_to_retry is True
    assert raised.value.mutation_dispatched is True
    assert raised.value.outcome_unknown is False
    assert pool.connection_value.rollbacks == 1


@pytest.mark.unit
def test_ut_api06_gateway_result_failure_is_known_only_after_confirmed_rollback():
    pool = Pool(fetch_error=DriverFailure("08006"))
    with pytest.raises(DatabaseMutationFailure) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )
    assert raised.value.outcome_unknown is False
    assert raised.value.safe_to_retry is False
    assert pool.connection_value.rollbacks == 1


@pytest.mark.unit
def test_ut_api06_gateway_rollback_failure_close_success_is_retained_and_unknown():
    primary = DriverFailure("08006")
    pool = Pool(fetch_error=primary, rollback_error=RuntimeError("cleanup secret"))
    with pytest.raises(DatabaseMutationFailure) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )
    assert raised.value.outcome_unknown is True
    assert raised.value.safe_to_retry is False
    assert raised.value.cleanup_failed is True
    assert raised.value.__cause__ is primary
    assert pool.connection_value.closes == 1
    assert pool.puts == [pool.connection_value]
    assert pool.reusable_returns == []
    assert pool.discarded_returns == [pool.connection_value]


@pytest.mark.unit
def test_ut_api06_gateway_rollback_and_close_failures_retain_primary_and_cleanup():
    primary = DriverFailure("08006")
    pool = Pool(
        fetch_error=primary,
        rollback_error=RuntimeError("private rollback detail"),
        close_error=RuntimeError("private close detail"),
    )
    with pytest.raises(DatabaseMutationFailure) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )
    assert raised.value.__cause__ is primary
    assert raised.value.cleanup_failed is True
    assert raised.value.outcome_unknown is True
    assert raised.value.safe_to_retry is False
    assert pool.connection_value.rollbacks == 1
    assert pool.connection_value.closes == 1
    assert pool.puts == []
    assert pool.reusable_returns == []
    assert pool.discarded_returns == []


@pytest.mark.unit
def test_ut_api06_gateway_commit_failure_is_unknown_and_never_retried():
    primary = DriverFailure("08006")
    pool = Pool(commit_error=primary)
    with pytest.raises(DatabaseMutationFailure) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )
    assert raised.value.outcome_unknown is True
    assert raised.value.safe_to_retry is False
    assert raised.value.__cause__ is primary
    assert pool.connection_value.rollbacks == 0
    assert pool.connection_value.closes == 1
    assert pool.puts == [pool.connection_value]
    assert pool.reusable_returns == []
    assert pool.discarded_returns == [pool.connection_value]


@pytest.mark.unit
def test_ut_api06_gateway_commit_uncertainty_close_failure_withholds_unsafe_lease():
    primary = DriverFailure("08006")
    pool = Pool(
        commit_error=primary,
        close_error=RuntimeError("private close detail"),
    )

    with pytest.raises(DatabaseMutationFailure) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )

    assert raised.value.__cause__ is primary
    assert raised.value.cleanup_failed is True
    assert raised.value.mutation_dispatched is True
    assert raised.value.outcome_unknown is True
    assert raised.value.safe_to_retry is False
    assert pool.connection_value.commits == 1
    assert pool.connection_value.rollbacks == 0
    assert pool.connection_value.closes == 1
    assert pool.connection_value.closed is False
    assert pool.puts == []
    assert pool.reusable_returns == []
    assert pool.discarded_returns == []


@pytest.mark.unit
def test_ut_api06_gateway_confirmed_commit_putconn_failure_closes_and_reports_cleanup():
    pool = Pool(putconn_error=RuntimeError("private pool-return detail"))

    result = NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
        COMMAND, 1.0
    )

    assert result.outcome is NewsletterPreferenceOutcome.SUBSCRIBED
    assert result.subscribed is True
    assert result.cleanup_failed is True
    assert pool.connection_value.commits == 1
    assert pool.connection_value.rollbacks == 0
    assert pool.connection_value.closes == 1
    assert pool.connection_value.closed is True
    assert pool.puts == [pool.connection_value]


@pytest.mark.unit
def test_ut_api06_gateway_confirmed_commit_putconn_and_close_failures_report_cleanup():
    pool = Pool(
        putconn_error=RuntimeError("private pool-return detail"),
        close_error=RuntimeError("private close detail"),
    )

    result = NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
        COMMAND, 1.0
    )

    assert result.outcome is NewsletterPreferenceOutcome.SUBSCRIBED
    assert result.subscribed is True
    assert result.cleanup_failed is True
    assert pool.connection_value.commits == 1
    assert pool.connection_value.rollbacks == 0
    assert pool.connection_value.closes == 1
    assert pool.connection_value.closed is False
    assert pool.puts == [pool.connection_value]


@pytest.mark.unit
def test_ut_api06_gateway_putconn_failure_preserves_pending_mutation_failure():
    primary = DriverFailure("55P03")
    pool = Pool(
        execute_error=primary,
        putconn_error=RuntimeError("private pool-return detail"),
    )

    with pytest.raises(DatabaseMutationFailure) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )

    assert raised.value.__cause__ is primary
    assert raised.value.cleanup_failed is True
    assert raised.value.mutation_dispatched is True
    assert raised.value.outcome_unknown is False
    assert raised.value.safe_to_retry is True
    assert pool.connection_value.rollbacks == 1
    assert pool.connection_value.closes == 1
    assert pool.connection_value.closed is True
    assert pool.puts == [pool.connection_value]


@pytest.mark.unit
def test_ut_api06_gateway_putconn_failure_preserves_pending_contract_error():
    pool = Pool(
        rows=[],
        putconn_error=RuntimeError("private pool-return detail"),
        close_error=RuntimeError("private close detail"),
    )

    with pytest.raises(DatabaseContractError) as raised:
        NewsletterGateway(pool, acquire_timeout_ms=500, clock=lambda: 1.0).set_preference(
            COMMAND, 1.0
        )

    assert raised.value.cleanup_failed is True
    assert raised.value.__cause__ is raised.value
    assert pool.connection_value.commits == 0
    assert pool.connection_value.rollbacks == 1
    assert pool.connection_value.closes == 1
    assert pool.connection_value.closed is False
    assert pool.puts == [pool.connection_value]
