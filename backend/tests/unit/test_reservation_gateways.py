from datetime import date, datetime, time, timedelta, timezone

import pytest

from cafe_fausse.db.availability_gateway import ReservationAvailabilityGateway
from cafe_fausse.db.context_gateway import ReservationContextGateway
from cafe_fausse.db.exceptions import DatabaseContractError, DatabaseUnavailable
from cafe_fausse.services.results import AvailabilityOutcome, AvailabilityRequest


pytestmark = pytest.mark.unit


class Cursor:
    def __init__(self, result_sets, *, fail_at=None):
        self.result_sets = list(result_sets)
        self.calls = []
        self.fail_at = fail_at

    def __enter__(self):
        return self

    def __exit__(self, *_):
        return False

    def execute(self, sql, params=None):
        self.calls.append((" ".join(sql.split()), params))
        if self.fail_at == len(self.calls):
            raise TimeoutError()

    def fetchall(self):
        return self.result_sets.pop(0)


class Transaction:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        self.connection.transactions += 1
        return self

    def __exit__(self, *_):
        return False


class Connection:
    def __init__(self, result_sets, *, fail_at=None):
        self.cursor_value = Cursor(result_sets, fail_at=fail_at)
        self.transactions = 0

    def transaction(self):
        return Transaction(self)

    def cursor(self):
        return self.cursor_value


class Lease:
    def __init__(self, pool):
        self.pool = pool

    def __enter__(self):
        self.pool.leases += 1
        return self.pool.connection_value

    def __exit__(self, *_):
        self.pool.exits += 1
        return False


class Pool:
    def __init__(self, result_sets, *, fail_at=None):
        self.connection_value = Connection(result_sets, fail_at=fail_at)
        self.leases = 0
        self.exits = 0

    def connection(self, timeout=None):
        self.timeout = timeout
        return Lease(self)


def context_sets():
    configuration = [
        (
            30,
            90,
            60,
            120,
            "America/New_York",
            date(2026, 8, 23),
            date(2026, 10, 22),
            30,
            120,
            0,
        )
    ]
    hours = [(day, time(17), time(21 if day == 7 else 23)) for day in range(1, 8)]
    return [configuration, hours]


def slot_row(local_date=date(2026, 9, 12), hour=17, *, duration=90, available=True):
    local_start = datetime.combine(local_date, time(hour))
    starts_at = local_start.replace(tzinfo=timezone(timedelta(hours=-4))).astimezone(timezone.utc)
    return ("slots", None, local_start, starts_at, starts_at + timedelta(minutes=duration), available)


def test_context_gateway_uses_one_repeatable_read_read_only_lease_and_validates_default_snapshot():
    pool = Pool(context_sets())
    result = ReservationContextGateway(pool, acquire_timeout_ms=500, clock=lambda: 0.0).get_context(1.0)
    assert pool.leases == pool.exits == pool.connection_value.transactions == 1
    calls = pool.connection_value.cursor_value.calls
    assert calls[0] == ("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY", None)
    assert [hours.iso_weekday for hours in result.weekday_hours] == list(range(1, 8))
    assert result.maximum_party_size == 120
    sql = " ".join(call[0] for call in calls)
    for relation in (
        "cafe_fausse.reservation_configuration",
        "cafe_fausse.restaurant_operating_hours",
        "cafe_fausse.restaurant_tables",
    ):
        assert relation in sql
    for forbidden in (
        "pg_timezone_names",
        "cafe_fausse.customers",
        "cafe_fausse.reservations",
        "cafe_fausse.reservation_table_assignments",
    ):
        assert forbidden not in sql
    assert all(call[0].split()[0] in {"SET", "SELECT"} for call in calls)


def test_context_gateway_accepts_alternate_configuration_hours_and_changed_positive_capacity():
    sets = context_sets()
    sets[0][0] = (15, 120, 30, 0, "UTC", date(2026, 8, 23), date(2026, 9, 22), 30, 137, 0)
    sets[1] = [(day, time(11 + (day % 2)), time(20 + (day % 2))) for day in range(1, 8)]
    result = ReservationContextGateway(Pool(sets), acquire_timeout_ms=500, clock=lambda: 0.0).get_context(1.0)
    assert (
        result.restaurant_timezone,
        result.start_interval_minutes,
        result.reservation_duration_minutes,
        result.advance_window_days,
        result.same_day_lead_minutes,
        result.maximum_party_size,
    ) == ("UTC", 15, 120, 30, 0, 137)
    assert result.weekday_hours[0].opens_at_local == time(12)
    assert result.weekday_hours[1].closes_at_local == time(20)


def _missing_configuration(sets): sets[0].clear()
def _missing_weekday(sets): sets[1].pop()
def _duplicate_weekday(sets): sets[1][1] = (1, time(17), time(23))
def _invalid_schedule_shape(sets): sets[1][0] = (1, time(23), time(17))
def _invalid_timezone(sets): sets[0][0] = (*sets[0][0][:4], "Not/A_Zone", *sets[0][0][5:])
def _wrong_table_count(sets): sets[0][0] = (*sets[0][0][:7], 29, 120, 0)
def _nonpositive_capacity(sets): sets[0][0] = (*sets[0][0][:9], 1)
def _malformed_capacity(sets): sets[0][0] = (*sets[0][0][:8], "120", 0)
def _malformed_configuration(sets): sets[0][0] = sets[0][0][:-1]
def _invalid_policy(sets): sets[0][0] = (20, *sets[0][0][1:])
def _incoherent_dates(sets): sets[0][0] = (*sets[0][0][:6], date(2026, 10, 21), *sets[0][0][7:])


@pytest.mark.parametrize(
    "mutator",
    [
        _missing_configuration,
        _missing_weekday,
        _duplicate_weekday,
        _invalid_schedule_shape,
        _invalid_timezone,
        _wrong_table_count,
        _nonpositive_capacity,
        _malformed_capacity,
        _malformed_configuration,
        _invalid_policy,
        _incoherent_dates,
    ],
)
def test_context_gateway_rejects_each_unusable_foundation_category(mutator):
    sets = context_sets()
    mutator(sets)
    with pytest.raises(DatabaseContractError):
        ReservationContextGateway(Pool(sets), acquire_timeout_ms=500, clock=lambda: 0.0).get_context(1.0)


def test_context_gateway_translates_technical_failure_without_mutation():
    pool = Pool(context_sets(), fail_at=3)
    with pytest.raises(DatabaseUnavailable) as raised:
        ReservationContextGateway(pool, acquire_timeout_ms=500, clock=lambda: 0.0).get_context(1.0)
    assert raised.value.safe_to_retry is False
    assert pool.leases == pool.exits == pool.connection_value.transactions == 1
    assert all(call[0].split()[0] in {"SET", "SELECT"} for call in pool.connection_value.cursor_value.calls)


@pytest.mark.parametrize("requested", [date(2026, 9, 12), date(2026, 9, 13)])
def test_availability_gateway_preserves_order_and_unavailable_slots_for_weekday_and_sunday(requested):
    request = AvailabilityRequest(requested, 4)
    rows = [slot_row(requested, 17, available=False), slot_row(requested, 18, available=True)]
    pool = Pool([[("America/New_York",)], rows])
    result = ReservationAvailabilityGateway(pool, acquire_timeout_ms=500, clock=lambda: 0.0).get_availability(request, 1.0)
    assert result.outcome is AvailabilityOutcome.SLOTS
    assert [slot.available for slot in result.slots] == [False, True]
    assert pool.leases == pool.exits == pool.connection_value.transactions == 1
    calls = pool.connection_value.cursor_value.calls
    assert calls[0] == ("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY", None)
    assert calls[-1][1] == (requested, 4)
    assert all(call[0].split()[0] in {"SET", "SELECT"} for call in calls)


@pytest.mark.parametrize("duration", [60, 90, 120])
def test_availability_gateway_accepts_each_frozen_duration(duration):
    request = AvailabilityRequest(date(2026, 9, 12), 4)
    result = ReservationAvailabilityGateway(
        Pool([[("America/New_York",)], [slot_row(duration=duration)]]),
        acquire_timeout_ms=500,
        clock=lambda: 0.0,
    ).get_availability(request, 1.0)
    assert result.slots[0].ends_at - result.slots[0].starts_at == timedelta(minutes=duration)


def test_availability_gateway_preserves_empty_legitimate_slot_array():
    request = AvailabilityRequest(date(2026, 9, 12), 4)
    result = ReservationAvailabilityGateway(
        Pool([[("America/New_York",)], []]), acquire_timeout_ms=500, clock=lambda: 0.0
    ).get_availability(request, 1.0)
    assert result.outcome is AvailabilityOutcome.SLOTS and result.slots == ()


def test_availability_gateway_preserves_database_dst_offset_without_host_reinterpretation():
    requested = date(2027, 3, 14)
    local_start = datetime(2027, 3, 14, 3)
    starts_at = datetime(2027, 3, 14, 7, tzinfo=timezone.utc)
    rows = [("slots", None, local_start, starts_at, starts_at + timedelta(minutes=60), True)]
    result = ReservationAvailabilityGateway(
        Pool([[("America/New_York",)], rows]), acquire_timeout_ms=500, clock=lambda: 0.0
    ).get_availability(AvailabilityRequest(requested, 4), 1.0)
    assert result.slots[0].local_start == local_start
    assert result.slots[0].starts_at.utcoffset() == timedelta(0)


def test_availability_gateway_maps_only_exact_controlled_invalid_request():
    request = AvailabilityRequest(date(2026, 9, 12), 4)
    rows = [("invalid_request", "date_or_party_size_out_of_range", None, None, None, None)]
    assert (
        ReservationAvailabilityGateway(
            Pool([[("America/New_York",)], rows]), acquire_timeout_ms=500, clock=lambda: 0.0
        ).get_availability(request, 1.0).outcome
        is AvailabilityOutcome.INVALID_REQUEST
    )


@pytest.mark.parametrize(
    "timezone_rows,rows",
    [
        ([("America/New_York",)], [("invalid_database_configuration", "invalid_timezone", None, None, None, None)]),
        ([("Not/A_Zone",)], [slot_row()]),
        ([("America/New_York",)], [("slots", None, datetime(2026, 9, 12, 17), datetime(2026, 9, 12, 21, tzinfo=timezone.utc), datetime(2026, 9, 12, 20, tzinfo=timezone.utc), True)]),
        ([("America/New_York",)], [slot_row(duration=75)]),
        ([("America/New_York",)], [slot_row(), slot_row()]),
        ([("America/New_York",)], [slot_row(hour=18), slot_row(hour=17)]),
    ],
)
def test_availability_gateway_rejects_configuration_and_impossible_temporal_rows(timezone_rows, rows):
    request = AvailabilityRequest(date(2026, 9, 12), 4)
    with pytest.raises(DatabaseContractError):
        ReservationAvailabilityGateway(
            Pool([timezone_rows, rows]), acquire_timeout_ms=500, clock=lambda: 0.0
        ).get_availability(request, 1.0)


def test_availability_gateway_rejects_subsecond_values_that_wire_format_cannot_represent():
    request = AvailabilityRequest(date(2026, 9, 12), 4)
    row = list(slot_row())
    row[2] = row[2].replace(microsecond=1)
    with pytest.raises(DatabaseContractError):
        ReservationAvailabilityGateway(
            Pool([[("America/New_York",)], [tuple(row)]]), acquire_timeout_ms=500, clock=lambda: 0.0
        ).get_availability(request, 1.0)


def test_availability_gateway_translates_technical_failure_and_performs_no_mutation():
    request = AvailabilityRequest(date(2026, 9, 12), 4)
    pool = Pool([[("America/New_York",)], [slot_row()]], fail_at=4)
    with pytest.raises(DatabaseUnavailable):
        ReservationAvailabilityGateway(pool, acquire_timeout_ms=500, clock=lambda: 0.0).get_availability(request, 1.0)
    assert pool.leases == pool.exits == pool.connection_value.transactions == 1
    assert all(call[0].split()[0] in {"SET", "SELECT"} for call in pool.connection_value.cursor_value.calls)
