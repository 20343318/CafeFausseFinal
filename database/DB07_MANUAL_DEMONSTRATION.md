# DB-07 PostgreSQL-only manual demonstration

Use only a disposable database named `cafe_fausse_dev*`, `cafe_fausse_test*`, or `cafe_fausse_demo*`. Set the variables shown in `database/README.md`, including `CAFE_FAUSSE_ALLOW_RESET=YES`; never use production data. Run SQL blocks below in `psql` from the repository root.

## Foundation and ordinary bookings

1. Run `database/scripts/rebuild.ps1`, followed by `database/scripts/verify.ps1`. Both must end with DB-07 success.
2. Inspect `pg_extension`, `pg_namespace`, `pg_proc`, and `pg_indexes` using `database/README.md`. Confirm repository migrations 001-011 are in lexical order and `SHOW server_version;` returns `18.3`.
3. Run `TABLE cafe_fausse.reservation_configuration;`. Expect exactly `(1,30,90,60,120,America/New_York)`.
4. Run `TABLE cafe_fausse.restaurant_operating_hours;`. Expect weekdays 1-6 at `17:00-23:00` and weekday 7 at `17:00-21:00`.
5. Run the inventory aggregate in `database/README.md`. Expect 30 tables, capacity four for every table, and total capacity 120.
6. Run the "Manual DB-06 demonstration" in `database/README.md` as `cafe_fausse_app`. Inspect the customer, newsletter state, reservation, and assignment as `cafe_fausse_test`.
7. Repeat the booking unchanged. Expect `exact_retry`, the same reservation ID/interval/tables, no duplicate row, and the current newsletter state. This simulates loss of the first successful response.
8. Choose another available slot and party size 8. Expect `booked` and two capacity-four table numbers. The returned sorted array is the authoritative multi-table confirmation fact.
9. Book the original customer at the first reservation's `ends_at` to show half-open back-to-back acceptance. Submit a different overlapping start for that customer to show `same_customer_overlap`; submit another customer at that overlap to show success when disjoint exclusive capacity remains.

## Exact schedule-boundary demonstration

Start from a clean rebuild. This block finds future weekday/Sunday dates from PostgreSQL, uses the authoritative availability operation to derive offsets, and then calls the production booking operation.

```sql
SELECT min(candidate.day)::date AS weekday_date
FROM generate_series(CURRENT_DATE + 7, CURRENT_DATE + 30, INTERVAL '1 day') AS candidate(day)
WHERE EXTRACT(isodow FROM candidate.day) BETWEEN 1 AND 6
\gset

SELECT min(candidate.day)::date AS sunday_date
FROM generate_series(CURRENT_DATE + 7, CURRENT_DATE + 30, INTERVAL '1 day') AS candidate(day)
WHERE EXTRACT(isodow FROM candidate.day) = 7
\gset

SET ROLE cafe_fausse_app;

SELECT to_char(local_start, 'YYYY-MM-DD HH24:MI:SS') AS weekday_close_start,
       (EXTRACT(epoch FROM (local_start - (starts_at AT TIME ZONE 'UTC'))) / 60)::smallint AS weekday_offset
FROM cafe_fausse.provisional_availability((:'weekday_date')::date, 4)
WHERE local_start::time = TIME '21:30'
\gset

-- Monday-Saturday: 21:30 + 90 minutes ends exactly at 23:00 and is accepted.
SELECT outcome, detail_code, starts_at, ends_at
FROM cafe_fausse.book_reservation(
    'Boundary', NULL, 'WeekdayClose', 'boundary-weekday-close@example.com', NULL,
    TIMESTAMP :'weekday_close_start', :weekday_offset::smallint, 4, 'no_change'
);
-- Expect booked and a restaurant-local end of 23:00.

-- Opening boundary: exactly 17:00 is accepted.
SELECT outcome, detail_code
FROM cafe_fausse.book_reservation(
    'Boundary', NULL, 'Opening', 'boundary-opening@example.com', NULL,
    (:'weekday_date')::date + TIME '17:00', :weekday_offset::smallint, 4, 'no_change'
);
-- Expect booked.

-- 22:00 + 90 minutes ends after the Monday-Saturday 23:00 close.
SELECT outcome, detail_code
FROM cafe_fausse.book_reservation(
    'Boundary', NULL, 'AfterClose', 'boundary-after-close@example.com', NULL,
    (:'weekday_date')::date + TIME '22:00', :weekday_offset::smallint, 4, 'no_change'
);
-- Expect invalid_request | end_after_closing.

-- 17:15 is after opening but not aligned to the default 30-minute interval.
SELECT outcome, detail_code
FROM cafe_fausse.book_reservation(
    'Boundary', NULL, 'Misaligned', 'boundary-misaligned@example.com', NULL,
    (:'weekday_date')::date + TIME '17:15', :weekday_offset::smallint, 4, 'no_change'
);
-- Expect invalid_request | misaligned_start.

SELECT to_char(local_start, 'YYYY-MM-DD HH24:MI:SS') AS sunday_close_start,
       (EXTRACT(epoch FROM (local_start - (starts_at AT TIME ZONE 'UTC'))) / 60)::smallint AS sunday_offset
FROM cafe_fausse.provisional_availability((:'sunday_date')::date, 4)
WHERE local_start::time = TIME '19:30'
\gset

-- Sunday: 19:30 + 90 minutes ends exactly at 21:00 and is accepted.
SELECT outcome, detail_code, starts_at, ends_at
FROM cafe_fausse.book_reservation(
    'Boundary', NULL, 'SundayClose', 'boundary-sunday-close@example.com', NULL,
    TIMESTAMP :'sunday_close_start', :sunday_offset::smallint, 4, 'no_change'
);
-- Expect booked and a restaurant-local end of 21:00.

-- 20:00 + 90 minutes ends after the Sunday 21:00 close.
SELECT outcome, detail_code
FROM cafe_fausse.book_reservation(
    'Boundary', NULL, 'SundayAfter', 'boundary-sunday-after@example.com', NULL,
    (:'sunday_date')::date + TIME '20:00', :sunday_offset::smallint, 4, 'no_change'
);
-- Expect invalid_request | end_after_closing.

RESET ROLE;
```

The automated equivalents are the named cases `Monday through Saturday closing boundary is 23:00`, `Sunday closing boundary is 21:00`, `15-minute alignment and 60-minute duration are authoritative`, and `60-minute alignment and 120-minute duration are authoritative` in `database/tests/db06_behavior_tests.sql`. Rebuild before the next demonstration.

## Deterministic full-capacity and rollback demonstration

Use the normal 30 capacity-four tables. The first party of 120 must consume all 30 tables; no capacity mutation is needed.

```sql
SET ROLE cafe_fausse_app;

SELECT to_char(slot.local_start, 'YYYY-MM-DD HH24:MI:SS') AS full_local_start,
       (EXTRACT(epoch FROM (slot.local_start - (slot.starts_at AT TIME ZONE 'UTC'))) / 60)::smallint AS full_offset
FROM generate_series(CURRENT_DATE + 1, CURRENT_DATE + 45, INTERVAL '1 day') AS day(local_date)
CROSS JOIN LATERAL cafe_fausse.provisional_availability(day.local_date::date, 120) AS slot
WHERE slot.available
ORDER BY slot.local_start
LIMIT 1
\gset

SELECT outcome, reservation_id, assigned_table_numbers,
       cardinality(assigned_table_numbers) AS assigned_count
FROM cafe_fausse.book_reservation(
    'Capacity', NULL, 'Holder', 'capacity-holder@example.com', NULL,
    TIMESTAMP :'full_local_start', :full_offset::smallint, 120, 'no_change'
);
-- Expect booked and assigned_count = 30.

SELECT outcome, detail_code, reservation_id, assigned_table_numbers
FROM cafe_fausse.book_reservation(
    'Capacity', NULL, 'Rejected', 'capacity-rejected@example.com', '202-555-0198',
    TIMESTAMP :'full_local_start', :full_offset::smallint, 4, 'subscribe'
);
-- Expect unavailable | no_capacity_sufficient_combination and no reservation ID.

RESET ROLE;
SET ROLE cafe_fausse_test;

SELECT
    (SELECT count(*) FROM cafe_fausse.customers
     WHERE email = 'capacity-rejected@example.com') AS rejected_customer_rows,
    (SELECT count(*) FROM cafe_fausse.reservations AS reservation
     JOIN cafe_fausse.customers AS customer USING (customer_id)
     WHERE customer.email = 'capacity-rejected@example.com') AS rejected_reservation_rows,
    (SELECT count(*) FROM cafe_fausse.reservation_table_assignments AS assignment
     JOIN cafe_fausse.reservations AS reservation USING (reservation_id)
     JOIN cafe_fausse.customers AS customer USING (customer_id)
     WHERE customer.email = 'capacity-rejected@example.com') AS rejected_assignment_rows,
    (SELECT count(*) FROM cafe_fausse.customers
     WHERE email = 'capacity-rejected@example.com' AND newsletter_subscribed) AS rejected_newsletter_rows;
-- Expect 0 | 0 | 0 | 0.

RESET ROLE;
```

Run `database/scripts/rebuild.ps1` and `database/scripts/verify.ps1` immediately afterward to restore and prove the approved clean baseline.

## Failure, concurrency, privilege, and final reset evidence

10. Run `database/tests/db06_behavior_tests.sql`. Its five named failure-stage cases prove rollback after customer insert, blank-field population, newsletter update, reservation insert, and partial assignment insert.
11. Run `database/scripts/concurrency_test.ps1 -Iterations 20`. It uses PostgreSQL-observed lock waits and includes identical, same-email, blank-field, last-table, writer, timeout, deadlock, and lost-response cases.
12. Call each production routine as `cafe_fausse_app`, then run `database/tests/runtime_privilege_denials.sql` and `database/tests/db06_runtime_privilege_denials.sql` to prove direct DML/DDL, reservation reads, helpers, writers, and test seams are denied.
13. Run `database/verification/query_plans_db07.sql` for rollback-safe retained-history plan evidence.
14. Run `database/scripts/rebuild.ps1` and `database/scripts/verify.ps1` again. Verify zero customers, reservations, and assignments plus the exact initial configuration, schedule, and inventory.

For the complete repeatable gate, run `database/scripts/test.ps1`. It performs clean builds, resets, unit and privilege checks, concurrency, plans, performance measurement, and the final empty-baseline verification without Flask.
