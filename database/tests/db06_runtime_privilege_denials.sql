\set ON_ERROR_STOP off
\pset pager off

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_app;
SET LOCAL search_path = cafe_fausse, pg_catalog;

SAVEPOINT direct_read;
SELECT count(*) FROM reservations;
\if :ERROR
    \echo 'Runtime reservation SELECT denial: PASS'
\else
    \echo 'Runtime reservation SELECT unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT direct_read;

SAVEPOINT direct_insert;
INSERT INTO reservations (
    customer_id, starts_at, ends_at, party_size,
    fingerprint_version, reservation_fingerprint
) VALUES (1, now(), now() + interval '90 minutes', 1, 1, decode(repeat('00', 32), 'hex'));
\if :ERROR
    \echo 'Runtime reservation INSERT denial: PASS'
\else
    \echo 'Runtime reservation INSERT unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT direct_insert;

SAVEPOINT direct_assignment;
DELETE FROM reservation_table_assignments;
\if :ERROR
    \echo 'Runtime assignment DELETE denial: PASS'
\else
    \echo 'Runtime assignment DELETE unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT direct_assignment;

SAVEPOINT allocator_seam;
SELECT * FROM cafe_fausse.select_table_allocation(
    ARRAY[1]::smallint[], ARRAY[4], 4, 1
);
\if :ERROR
    \echo 'Runtime allocator seam denial: PASS'
\else
    \echo 'Runtime allocator seam unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT allocator_seam;

SAVEPOINT booking_seam;
SELECT * FROM cafe_fausse.book_reservation_test(
    'Runtime', NULL, 'Denied', 'runtime-db06@example.com', NULL,
    TIMESTAMP '2030-01-01 17:00', (-480)::smallint, 4,
    'no_change', 1, NULL
);
\if :ERROR
    \echo 'Runtime booking test seam denial: PASS'
\else
    \echo 'Runtime booking test seam unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT booking_seam;

SAVEPOINT writer_seam;
SELECT cafe_fausse.set_restaurant_table_capacity(1::smallint, 4);
\if :ERROR
    \echo 'Runtime controlled writer denial: PASS'
\else
    \echo 'Runtime controlled writer unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT writer_seam;

SAVEPOINT core_seam;
SELECT * FROM cafe_fausse.book_reservation_core(
    'Runtime', NULL, 'Denied', 'runtime-db06@example.com', NULL,
    TIMESTAMP '2030-01-01 17:00', (-480)::smallint, 4,
    'no_change', NULL, NULL
);
\if :ERROR
    \echo 'Runtime internal booking core denial: PASS'
\else
    \echo 'Runtime internal booking core unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT core_seam;

ROLLBACK;
\set ON_ERROR_STOP on
\echo 'DB-06 runtime privilege-denial behavior: 7/7 PASS'
