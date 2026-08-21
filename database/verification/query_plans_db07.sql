\set ON_ERROR_STOP on
\pset pager off

BEGIN;
SET LOCAL ROLE cafe_fausse_test;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

-- A rollback-safe retained-history fixture large enough to expose the intended
-- reservation access paths without becoming repository business data.
INSERT INTO cafe_fausse.customers(first_name, last_name, email)
SELECT 'Plan', 'History', 'db07-plan-' || series.value || '@example.com'
FROM pg_catalog.generate_series(1, 200) AS series(value);

INSERT INTO cafe_fausse.reservations(
    customer_id, starts_at, ends_at, party_size,
    fingerprint_version, reservation_fingerprint
)
SELECT customer.customer_id,
       TIMESTAMPTZ '2020-01-01 17:00:00-05' + (row_number() OVER () * INTERVAL '1 day'),
       TIMESTAMPTZ '2020-01-01 18:30:00-05' + (row_number() OVER () * INTERVAL '1 day'),
       4,
       1,
       cafe_fausse.reservation_fingerprint_v1(
           customer.customer_id,
           TIMESTAMPTZ '2020-01-01 17:00:00-05' + (row_number() OVER () * INTERVAL '1 day'),
           4
       )
FROM cafe_fausse.customers AS customer
WHERE customer.email LIKE 'db07-plan-%@example.com';

INSERT INTO cafe_fausse.reservation_table_assignments(reservation_id, table_number)
SELECT reservation.reservation_id,
       (((row_number() OVER (ORDER BY reservation.reservation_id)) - 1) % 30 + 1)::smallint
FROM cafe_fausse.reservations AS reservation
JOIN cafe_fausse.customers AS customer USING (customer_id)
WHERE customer.email LIKE 'db07-plan-%@example.com';

SET LOCAL ROLE cafe_fausse_owner;
ANALYZE cafe_fausse.customers;
ANALYZE cafe_fausse.reservations;
ANALYZE cafe_fausse.reservation_table_assignments;
SET LOCAL ROLE cafe_fausse_test;

\echo 'PLAN canonical-email lookup'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT * FROM cafe_fausse.customers WHERE email = 'db07-plan-100@example.com';

\echo 'PLAN fingerprint candidate lookup'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT * FROM cafe_fausse.reservations
WHERE fingerprint_version = 1
  AND reservation_fingerprint = decode(repeat('00', 32), 'hex');

\echo 'PLAN exact-identity tuple lookup'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT * FROM cafe_fausse.reservations
WHERE customer_id = (SELECT customer_id FROM cafe_fausse.customers WHERE email = 'db07-plan-100@example.com')
  AND starts_at = TIMESTAMPTZ '2020-04-10 17:00:00-05'
  AND party_size = 4;

\echo 'PLAN same-customer interval lookup'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT reservation_id FROM cafe_fausse.reservations
WHERE customer_id = (SELECT customer_id FROM cafe_fausse.customers WHERE email = 'db07-plan-100@example.com')
  AND starts_at < TIMESTAMPTZ '2020-04-11 19:00:00-05'
  AND ends_at > TIMESTAMPTZ '2020-04-11 17:00:00-05';

\echo 'PLAN global interval lookup'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT reservation_id FROM cafe_fausse.reservations
WHERE starts_at < TIMESTAMPTZ '2020-04-11 19:00:00-05'
  AND ends_at > TIMESTAMPTZ '2020-04-11 17:00:00-05';

\echo 'PLAN assignment by reservation'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT * FROM cafe_fausse.reservation_table_assignments
WHERE reservation_id = (SELECT min(reservation_id) FROM cafe_fausse.reservations);

\echo 'PLAN assignment by table'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT * FROM cafe_fausse.reservation_table_assignments WHERE table_number = 15;

\echo 'PLAN free-table derivation'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT table_row.table_number, table_row.seating_capacity
FROM cafe_fausse.restaurant_tables AS table_row
WHERE NOT EXISTS (
    SELECT 1
    FROM cafe_fausse.reservation_table_assignments AS assignment
    JOIN cafe_fausse.reservations AS reservation USING (reservation_id)
    WHERE assignment.table_number = table_row.table_number
      AND reservation.starts_at < TIMESTAMPTZ '2030-01-01 18:30:00-05'
      AND reservation.ends_at > TIMESTAMPTZ '2030-01-01 17:00:00-05'
);

\echo 'PLAN exact allocator over 30 tables'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT * FROM cafe_fausse.select_table_allocation(
    ARRAY(SELECT value::smallint FROM generate_series(1,30) AS value),
    ARRAY(SELECT 4 FROM generate_series(1,30)),
    61,
    1
);

\echo 'PLAN representative availability day'
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT * FROM cafe_fausse.provisional_availability(CURRENT_DATE + 14, 4);

ROLLBACK;
