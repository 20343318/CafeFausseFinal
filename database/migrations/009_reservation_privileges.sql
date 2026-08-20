\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;

REVOKE ALL ON cafe_fausse.reservations FROM PUBLIC, cafe_fausse_app;
REVOKE ALL ON cafe_fausse.reservation_table_assignments FROM PUBLIC, cafe_fausse_app;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA cafe_fausse FROM PUBLIC, cafe_fausse_app;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
ON cafe_fausse.reservations, cafe_fausse.reservation_table_assignments
TO cafe_fausse_test;

GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA cafe_fausse
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.provisional_availability(date, integer)
TO cafe_fausse_app, cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.book_reservation(text, text, text, text, text, timestamp without time zone, smallint, integer, text)
TO cafe_fausse_app, cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.set_newsletter_preference(text, text, text, text, boolean)
TO cafe_fausse_app, cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.reservation_fingerprint_serialization_v1(bigint, timestamp with time zone, integer)
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.reservation_fingerprint_v1(bigint, timestamp with time zone, integer)
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.canonical_email_lock_key(text)
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.local_timestamp_candidates(timestamp without time zone, text)
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.select_table_allocation(smallint[], integer[], integer, bigint)
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.book_reservation_test(text, text, text, text, text, timestamp without time zone, smallint, integer, text, bigint, text)
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.set_reservation_configuration(smallint, smallint, smallint, smallint, text)
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.set_restaurant_operating_hours(smallint, time without time zone, time without time zone)
TO cafe_fausse_test;

GRANT EXECUTE ON FUNCTION cafe_fausse.set_restaurant_table_capacity(smallint, integer)
TO cafe_fausse_test;

REVOKE ALL ON FUNCTION cafe_fausse.sha256_text(text) FROM cafe_fausse_app, cafe_fausse_test;
REVOKE ALL ON FUNCTION cafe_fausse.book_reservation_core(text, text, text, text, text, timestamp without time zone, smallint, integer, text, bigint, text)
FROM cafe_fausse_app, cafe_fausse_test;

COMMIT;
