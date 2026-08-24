from datetime import date, datetime, time, timezone
import json

import pytest

from cafe_fausse.application import create_app
from cafe_fausse.dependencies import Dependencies
from cafe_fausse.services.health import LivenessService, ReadinessService
from cafe_fausse.services.reservation_context import ReservationServiceUnavailable
from cafe_fausse.services.results import AvailabilityOutcome, AvailabilityRequest, AvailabilitySlot, ReservationAvailabilityResult, ReservationContextResult, WeekdayHours


pytestmark = pytest.mark.api


class ReadyGateway:
    def check_readiness(self, _deadline_ms): pass


class ContextService:
    def __init__(self, result=None, error=None): self.result=result; self.error=error; self.calls=0
    def get(self):
        self.calls += 1
        if self.error: raise self.error
        return self.result


class AvailabilityService:
    def __init__(self, result=None, error=None): self.result=result; self.error=error; self.calls=[]
    def get(self, request):
        self.calls.append(request)
        if self.error: raise self.error
        return self.result if self.result is not None else ReservationAvailabilityResult(AvailabilityOutcome.SLOTS, request, "America/New_York")


def context_result():
    return ReservationContextResult("America/New_York", tuple(WeekdayHours(day,time(17),time(21 if day==7 else 23)) for day in range(1,8)),30,90,60,120,date(2026,8,23),date(2026,10,22),120)


def client(settings, context=None, availability=None):
    dependencies=Dependencies(settings,LivenessService(),ReadinessService(ReadyGateway(),1000),lambda:10.0,lambda:"123e4567-e89b-42d3-a456-426614174000",reservation_context_service=context or ContextService(context_result()),reservation_availability_service=availability or AvailabilityService())
    return create_app(settings,dependencies).test_client()


def test_context_exact_envelope_and_headers(settings):
    response=client(settings).get('/api/v1/reservation-context')
    assert response.status_code==200
    assert response.get_json()=={"restaurant":{"address":"1234 Culinary Ave, Suite 100, Washington, DC 20002","phone":"(202) 555-4567"},"restaurant_timezone":"America/New_York","weekday_hours":[{"iso_weekday":day,"opens_at_local":"17:00:00","closes_at_local":"21:00:00" if day==7 else "23:00:00"} for day in range(1,8)],"reservation_policy":{"start_interval_minutes":30,"reservation_duration_minutes":90,"advance_window_days":60,"same_day_lead_minutes":120},"reservable_date_range":{"minimum_local_date":"2026-08-23","maximum_local_date":"2026-10-22"},"maximum_party_size":120}
    assert response.headers['Cache-Control']=='no-store, max-age=0'


@pytest.mark.parametrize('suffix', ['?extra=x','?local_date=2026-09-12'])
def test_context_rejects_query(settings,suffix): assert client(settings).get('/api/v1/reservation-context'+suffix).status_code==400


def test_context_rejects_body_and_wrong_methods(settings):
    api=client(settings)
    assert api.open('/api/v1/reservation-context',method='GET',data=b'x').status_code==400
    assert api.head('/api/v1/reservation-context').status_code==405
    assert api.post('/api/v1/reservation-context').status_code==405


def test_availability_serializes_offsets_instants_and_unavailable_slots(settings):
    request=AvailabilityRequest(date(2026,9,12),4)
    slot=AvailabilitySlot(datetime(2026,9,12,17),datetime(2026,9,12,21,tzinfo=timezone.utc),datetime(2026,9,12,22,30,tzinfo=timezone.utc),False)
    service=AvailabilityService(ReservationAvailabilityResult(AvailabilityOutcome.SLOTS,request,'America/New_York',(slot,)))
    response=client(settings,availability=service).get('/api/v1/reservation-availability?local_date=2026-09-12&party_size=4')
    assert response.status_code==200
    assert response.headers['Cache-Control']=='no-store, max-age=0'
    assert response.mimetype=='application/json'
    assert response.get_json()=={"local_date":"2026-09-12","party_size":4,"restaurant_timezone":"America/New_York","provisional":True,"slots":[{"starts_at_local":"2026-09-12T17:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-12T21:00:00Z","ends_at_local":"2026-09-12T18:30:00-04:00","ends_at":"2026-09-12T22:30:00Z","available":False}]}


@pytest.mark.parametrize(
    'query,status,code',
    [
        ('',400,'invalid_request'),
        ('?local_date=2026-09-12',400,'invalid_request'),
        ('?party_size=4',400,'invalid_request'),
        ('?local_date=2026-09-12&party_size=4&extra=x',400,'invalid_request'),
        ('?local_date=2026-09-12&local_date=2026-09-13&party_size=4',400,'invalid_request'),
        ('?local_date=2026-09-12&party_size=4&party_size=5',400,'invalid_request'),
        ('?local_date=2026-02-29&party_size=4',422,'validation_failed'),
        ('?local_date=2026-09-12&party_size=true',422,'validation_failed'),
        ('?local_date=2026-09-12&party_size=4.0',422,'validation_failed'),
        ('?local_date=2026-09-12&party_size=-1',422,'validation_failed'),
        ('?local_date=2026-09-12&party_size=2147483648',422,'validation_failed'),
    ],
)
def test_availability_rejects_invalid_query_shapes_with_exact_public_code(settings,query,status,code):
    response=client(settings).get('/api/v1/reservation-availability'+query)
    assert response.status_code==status
    payload=response.get_json()
    assert payload['error']['code']==code
    assert 'sql' not in json.dumps(payload).lower()


def test_availability_controlled_range_error_is_stable(settings):
    request=AvailabilityRequest(date(2026,9,12),999)
    service=AvailabilityService(ReservationAvailabilityResult(AvailabilityOutcome.INVALID_REQUEST,request))
    response=client(settings,availability=service).get('/api/v1/reservation-availability?local_date=2026-09-12&party_size=999')
    assert response.status_code==422
    assert [item['field'] for item in response.get_json()['error']['fields']]==['local_date','party_size']


@pytest.mark.parametrize('path,operation', [('/api/v1/reservation-context','OP-01'),('/api/v1/reservation-availability?local_date=2026-09-12&party_size=4','OP-02')])
def test_discovery_failure_uses_exact_public_envelope_and_safe_log(settings,capfd,path,operation):
    error=ReservationServiceUnavailable(1.0,2.0)
    response=client(settings,ContextService(error=error),AvailabilityService(error=error)).get(path)
    assert response.status_code==503
    assert response.get_json()=={"error":{"code":"service_unavailable","message":"The service cannot process this request right now.","retryable":True,"outcome_unknown":False}}
    text=capfd.readouterr().err
    assert operation in text
    assert 'sentinel@example.com' not in text and 'SELECT ' not in text
    assert 'pg_timezone_names' not in text and 'connection' not in text.lower()


def test_availability_rejects_body_head_post_and_old_alias(settings):
    api=client(settings); path='/api/v1/reservation-availability?local_date=2026-09-12&party_size=4'
    assert api.open(path,method='GET',data=b'{}').status_code==400
    assert api.head(path).status_code==405
    assert api.post('/api/v1/reservation-availability').status_code==405
    assert api.get('/api/v1/availability?local_date=2026-09-12&party_size=4').status_code==404
