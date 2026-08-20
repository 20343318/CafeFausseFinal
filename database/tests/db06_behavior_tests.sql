\set ON_ERROR_STOP on
\pset pager off

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE TEMPORARY TABLE db06_test_results (
    test_name text PRIMARY KEY
) ON COMMIT DROP;
GRANT SELECT, INSERT ON db06_test_results TO cafe_fausse_test;

CREATE OR REPLACE FUNCTION pg_temp.assert_true(condition boolean, test_name text)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    IF condition IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'DB-06 test failed: %', test_name;
    END IF;
    INSERT INTO db06_test_results VALUES (test_name);
END
$function$;

CREATE OR REPLACE FUNCTION pg_temp.assert_raises(
    statement_text text,
    expected_state text,
    test_name text
)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    actual_state text;
BEGIN
    BEGIN
        EXECUTE statement_text;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS actual_state = RETURNED_SQLSTATE;
        IF actual_state = expected_state THEN
            INSERT INTO db06_test_results VALUES (test_name);
            RETURN;
        END IF;
        RAISE EXCEPTION 'DB-06 test failed: % raised %, expected %',
            test_name, actual_state, expected_state;
    END;
    RAISE EXCEPTION 'DB-06 test failed: % did not raise', test_name;
END
$function$;

SET LOCAL ROLE cafe_fausse_test;

-- Exact allocation: table count outranks waste, then capacity outranks random tie choice.
SELECT pg_temp.assert_true(
    (SELECT table_numbers = ARRAY[1]::smallint[] AND total_capacity = 4
       FROM cafe_fausse.select_table_allocation(ARRAY[1]::smallint[], ARRAY[4], 4, 1)),
    'one-table exact allocation'
);
SELECT pg_temp.assert_true(
    (SELECT table_numbers = ARRAY[3]::smallint[] AND total_capacity = 9
       FROM cafe_fausse.select_table_allocation(ARRAY[1,2,3]::smallint[], ARRAY[4,4,9], 8, 1)),
    'minimum table count outranks lower waste'
);
SELECT pg_temp.assert_true(
    (SELECT table_numbers = ARRAY[1,2]::smallint[] AND total_capacity = 9
       FROM cafe_fausse.select_table_allocation(ARRAY[1,2,3]::smallint[], ARRAY[4,5,7], 8, 1)),
    'least waste breaks equal table-count choices'
);
SELECT pg_temp.assert_true(
    (SELECT tie_count = 3 AND selected_rank = 2 AND table_numbers = ARRAY[3]::smallint[]
       FROM cafe_fausse.select_table_allocation(ARRAY[1,2,3]::smallint[], ARRAY[4,4,4], 4, 2)),
    'deterministic seam selects every exact tie by rank'
);
SELECT pg_temp.assert_true(
    (SELECT count(*) = 0
       FROM cafe_fausse.select_table_allocation(ARRAY[1,2]::smallint[], ARRAY[2,2], 5, 1)),
    'allocator returns no row when capacity is insufficient'
);
SELECT pg_temp.assert_raises(
    $$SELECT * FROM cafe_fausse.select_table_allocation(ARRAY[1,2]::smallint[], ARRAY[4,4], 4, 3)$$,
    '22023',
    'out-of-range allocation tie rank is rejected'
);
SELECT pg_temp.assert_true(
    NOT EXISTS (
        SELECT 1
        FROM pg_catalog.generate_series(1, 20) AS attempt
        CROSS JOIN LATERAL cafe_fausse.select_table_allocation(
            ARRAY[1,2,3]::smallint[], ARRAY[4,4,4], 4, NULL
        ) AS allocation
        WHERE allocation.tie_count <> 3
           OR allocation.selected_rank NOT BETWEEN 1 AND 3
           OR pg_catalog.cardinality(allocation.table_numbers) <> 1
           OR allocation.table_numbers[1] NOT BETWEEN 1 AND 3
    ),
    'production randomness selects only among equal best candidates'
);
SELECT pg_temp.assert_true(
    (
        SELECT count(DISTINCT allocation.table_numbers) = 3
           AND bool_and(allocation.selected_rank = requested_rank)
           AND bool_and(allocation.tie_count = 3)
        FROM pg_catalog.generate_series(1, 3) AS rank_value(requested_rank)
        CROSS JOIN LATERAL cafe_fausse.select_table_allocation(
            ARRAY[1,2,3]::smallint[], ARRAY[4,4,4], 4, rank_value.requested_rank
        ) AS allocation
    ),
    'every deterministic equal-best rank is independently reachable'
);

-- Timezone round trips distinguish nonexistent and ambiguous local wall times.
SELECT pg_temp.assert_true(
    (SELECT count(*) = 0 FROM cafe_fausse.local_timestamp_candidates(
        TIMESTAMP '2026-03-08 02:30', 'America/New_York')),
    'DST spring-forward local time is nonexistent'
);
SELECT pg_temp.assert_true(
    (SELECT count(*) = 2 FROM cafe_fausse.local_timestamp_candidates(
        TIMESTAMP '2026-11-01 01:30', 'America/New_York')),
    'DST fall-back local time is ambiguous'
);

CREATE TEMPORARY TABLE chosen_slots ON COMMIT DROP AS
SELECT
    row_number() OVER (ORDER BY availability.local_start)::integer AS slot_number,
    availability.local_start,
    availability.starts_at,
    (
        EXTRACT(epoch FROM (
            availability.local_start
            - (availability.starts_at AT TIME ZONE 'UTC')
        )) / 60
    )::smallint AS utc_offset_minutes
FROM pg_catalog.generate_series(
    CURRENT_DATE + 1,
    CURRENT_DATE + 45,
    INTERVAL '1 day'
) AS candidate(local_date)
CROSS JOIN LATERAL cafe_fausse.provisional_availability(candidate.local_date::date, 4)
    AS availability
WHERE availability.outcome = 'slots'
  AND availability.available
ORDER BY availability.local_start
LIMIT 12;

SELECT pg_temp.assert_true(
    (SELECT count(*) >= 6 FROM chosen_slots),
    'provisional availability exposes future bookable slots'
);
SELECT pg_temp.assert_true(
    NOT EXISTS (
        SELECT 1 FROM cafe_fausse.provisional_availability(CURRENT_DATE - 1, 4)
        WHERE outcome <> 'invalid_request'
    ),
    'availability rejects a past local date'
);
SELECT pg_temp.assert_true(
    (TIMESTAMPTZ '2026-01-01 17:00+00' < TIMESTAMPTZ '2026-01-01 19:00+00'
     AND TIMESTAMPTZ '2026-01-01 17:00+00' < TIMESTAMPTZ '2026-01-01 18:30+00')
    AND (TIMESTAMPTZ '2026-01-01 16:00+00' < TIMESTAMPTZ '2026-01-01 18:30+00'
         AND TIMESTAMPTZ '2026-01-01 17:00+00' < TIMESTAMPTZ '2026-01-01 20:00+00')
    AND NOT (TIMESTAMPTZ '2026-01-01 15:30+00' < TIMESTAMPTZ '2026-01-01 17:00+00'
             AND TIMESTAMPTZ '2026-01-01 17:00+00' < TIMESTAMPTZ '2026-01-01 17:00+00')
    AND NOT (TIMESTAMPTZ '2026-01-01 17:00+00' < TIMESTAMPTZ '2026-01-01 20:00+00'
             AND TIMESTAMPTZ '2026-01-01 18:30+00' < TIMESTAMPTZ '2026-01-01 18:30+00'),
    'half-open interval predicate covers overlap and permits touching endpoints'
);

DO $booking_tests$
DECLARE
    slot_one chosen_slots%ROWTYPE;
    slot_two chosen_slots%ROWTYPE;
    slot_three chosen_slots%ROWTYPE;
    first_result record;
    retry_result record;
    other_result record;
    overlap_result record;
    conflict_result record;
    population_result record;
    notice_result record;
    before_reservation_count bigint;
    assigned_table smallint;
BEGIN
    SELECT * INTO STRICT slot_one FROM chosen_slots WHERE slot_number = 1;
    SELECT * INTO STRICT slot_two FROM chosen_slots WHERE slot_number = 4;
    SELECT * INTO STRICT slot_three FROM chosen_slots WHERE slot_number = 7;

    SELECT * INTO STRICT first_result
    FROM cafe_fausse.book_reservation_test(
        'Ada', 'A', 'Lovelace', 'ada.db06@example.com', '+1 (202) 555-0101',
        slot_one.local_start, slot_one.utc_offset_minutes, 4, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        first_result.outcome = 'booked'
        AND first_result.reservation_id IS NOT NULL
        AND pg_catalog.cardinality(first_result.assigned_table_numbers) = 1
        AND pg_catalog.octet_length(first_result.reservation_fingerprint) = 32,
        'authoritative booking persists one exact allocation'
    );

    SELECT * INTO STRICT retry_result
    FROM cafe_fausse.book_reservation_test(
        'Ada', 'A', 'Lovelace', 'ada.db06@example.com', '+1 (202) 555-0101',
        slot_one.local_start, slot_one.utc_offset_minutes, 4, 'subscribe', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        retry_result.outcome = 'exact_retry'
        AND retry_result.reservation_id = first_result.reservation_id
        AND retry_result.newsletter_subscribed = FALSE
        AND (SELECT count(*) FROM cafe_fausse.reservations
             WHERE customer_id = (SELECT customer_id FROM cafe_fausse.customers
                                    WHERE email = 'ada.db06@example.com')) = 1,
        'exact retry returns the original reservation without mutation'
    );

    SELECT * INTO STRICT overlap_result
    FROM cafe_fausse.book_reservation_test(
        'Ada', 'A', 'Lovelace', 'ada.db06@example.com', '+1 (202) 555-0101',
        slot_one.local_start, slot_one.utc_offset_minutes, 5, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        overlap_result.outcome = 'same_customer_overlap',
        'same customer cannot create overlapping reservations'
    );

    SELECT * INTO STRICT other_result
    FROM cafe_fausse.book_reservation_test(
        'Grace', NULL, 'Hopper', 'grace.db06@example.com', NULL,
        slot_one.local_start, slot_one.utc_offset_minutes, 4, 'subscribe', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        other_result.outcome = 'booked'
        AND other_result.newsletter_subscribed,
        'different customer can use a disjoint table concurrently in the interval'
    );

    SELECT * INTO STRICT conflict_result
    FROM cafe_fausse.book_reservation_test(
        'Ada', 'B', 'Lovelace', 'ada.db06@example.com', NULL,
        slot_two.local_start, slot_two.utc_offset_minutes, 4, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        conflict_result.outcome = 'middle_initial_conflict',
        'nonblank middle initial is immutable once stored'
    );

    SELECT * INTO STRICT conflict_result
    FROM cafe_fausse.book_reservation_test(
        'Augusta', 'A', 'Lovelace', 'ada.db06@example.com', NULL,
        slot_two.local_start, slot_two.utc_offset_minutes, 4, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        conflict_result.outcome = 'customer_identity_mismatch',
        'canonical email cannot silently change customer identity'
    );

    SELECT * INTO STRICT population_result
    FROM cafe_fausse.book_reservation_test(
        'Katherine', NULL, 'Johnson', 'katherine.db06@example.com', NULL,
        slot_two.local_start, slot_two.utc_offset_minutes, 4, 'no_change', 1, NULL
    );
    SELECT * INTO STRICT notice_result
    FROM cafe_fausse.book_reservation_test(
        'Katherine', 'C', 'Johnson', 'katherine.db06@example.com', '202-555-0110',
        slot_three.local_start, slot_three.utc_offset_minutes, 4, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        population_result.outcome = 'booked'
        AND notice_result.outcome = 'booked'
        AND (SELECT middle_initial = 'C' AND phone = '202-555-0110'
             FROM cafe_fausse.customers WHERE email = 'katherine.db06@example.com'),
        'blank optional customer fields are populated atomically'
    );

    SELECT * INTO STRICT notice_result
    FROM cafe_fausse.book_reservation_test(
        'Katherine', 'C', 'Johnson', 'katherine.db06@example.com', '202-555-0199',
        (SELECT local_start FROM chosen_slots WHERE slot_number = 10),
        (SELECT utc_offset_minutes FROM chosen_slots WHERE slot_number = 10),
        4, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        notice_result.outcome = 'booked_phone_notice'
        AND notice_result.phone_notice
        AND (SELECT phone = '202-555-0110' FROM cafe_fausse.customers
             WHERE email = 'katherine.db06@example.com'),
        'different later phone is reported without overwriting stored phone'
    );

    assigned_table := first_result.assigned_table_numbers[1];
    PERFORM cafe_fausse.set_restaurant_table_capacity(assigned_table, 5);
    PERFORM pg_temp.assert_true(
        EXISTS (SELECT 1 FROM cafe_fausse.reservations
                WHERE reservation_id = first_result.reservation_id)
        AND EXISTS (SELECT 1 FROM cafe_fausse.reservation_table_assignments
                    WHERE reservation_id = first_result.reservation_id
                      AND table_number = assigned_table),
        'controlled capacity changes do not rewrite existing reservations'
    );
    PERFORM cafe_fausse.set_restaurant_table_capacity(assigned_table, 4);

    SELECT count(*) INTO before_reservation_count FROM cafe_fausse.reservations;
    BEGIN
        PERFORM * FROM cafe_fausse.book_reservation_test(
            'Rollback', NULL, 'Customer', 'rollback-customer.db06@example.com', NULL,
            slot_two.local_start, slot_two.utc_offset_minutes, 4,
            'subscribe', 1, 'after_customer_insert'
        );
        RAISE EXCEPTION 'failure injection unexpectedly returned';
    EXCEPTION WHEN SQLSTATE 'P6691' THEN NULL;
    END;
    PERFORM pg_temp.assert_true(
        NOT EXISTS (SELECT 1 FROM cafe_fausse.customers
                    WHERE email = 'rollback-customer.db06@example.com')
        AND (SELECT count(*) FROM cafe_fausse.reservations) = before_reservation_count,
        'customer-stage failure injection rolls back every write'
    );

    INSERT INTO cafe_fausse.customers(first_name, last_name, email)
    VALUES ('Rollback', 'Optional', 'rollback-optional.db06@example.com');
    BEGIN
        PERFORM * FROM cafe_fausse.book_reservation_test(
            'Rollback', 'Z', 'Optional', 'rollback-optional.db06@example.com', '202-555-0123',
            slot_two.local_start, slot_two.utc_offset_minutes, 4,
            'no_change', 1, 'after_optional_field_population'
        );
        RAISE EXCEPTION 'failure injection unexpectedly returned';
    EXCEPTION WHEN SQLSTATE 'P6692' THEN NULL;
    END;
    PERFORM pg_temp.assert_true(
        (SELECT middle_initial IS NULL AND phone IS NULL
         FROM cafe_fausse.customers WHERE email = 'rollback-optional.db06@example.com')
        AND (SELECT count(*) FROM cafe_fausse.reservations) = before_reservation_count,
        'optional-field failure injection rolls back customer population'
    );

    BEGIN
        PERFORM * FROM cafe_fausse.book_reservation_test(
            'Rollback', NULL, 'Newsletter', 'rollback-newsletter.db06@example.com', NULL,
            slot_two.local_start, slot_two.utc_offset_minutes, 4,
            'subscribe', 1, 'after_newsletter_update'
        );
        RAISE EXCEPTION 'failure injection unexpectedly returned';
    EXCEPTION WHEN SQLSTATE 'P6693' THEN NULL;
    END;
    PERFORM pg_temp.assert_true(
        NOT EXISTS (SELECT 1 FROM cafe_fausse.customers
                    WHERE email = 'rollback-newsletter.db06@example.com')
        AND (SELECT count(*) FROM cafe_fausse.reservations) = before_reservation_count,
        'newsletter failure injection rolls back customer and preference'
    );

    BEGIN
        PERFORM * FROM cafe_fausse.book_reservation_test(
            'Rollback', NULL, 'Reservation', 'rollback-reservation.db06@example.com', NULL,
            slot_two.local_start, slot_two.utc_offset_minutes, 4,
            'subscribe', 1, 'after_reservation_insert'
        );
        RAISE EXCEPTION 'failure injection unexpectedly returned';
    EXCEPTION WHEN SQLSTATE 'P6694' THEN NULL;
    END;
    PERFORM pg_temp.assert_true(
        NOT EXISTS (SELECT 1 FROM cafe_fausse.customers
                    WHERE email = 'rollback-reservation.db06@example.com')
        AND (SELECT count(*) FROM cafe_fausse.reservations) = before_reservation_count,
        'reservation-stage failure injection rolls back customer and reservation'
    );

    BEGIN
        PERFORM * FROM cafe_fausse.book_reservation_test(
            'Rollback', NULL, 'Assignment', 'rollback-assignment.db06@example.com', NULL,
            slot_two.local_start, slot_two.utc_offset_minutes, 8,
            'subscribe', 1, 'after_partial_assignment_insert'
        );
        RAISE EXCEPTION 'failure injection unexpectedly returned';
    EXCEPTION WHEN SQLSTATE 'P6695' THEN NULL;
    END;
    PERFORM pg_temp.assert_true(
        NOT EXISTS (SELECT 1 FROM cafe_fausse.customers
                    WHERE email = 'rollback-assignment.db06@example.com')
        AND (SELECT count(*) FROM cafe_fausse.reservations) = before_reservation_count
        AND NOT EXISTS (
            SELECT 1 FROM cafe_fausse.reservation_table_assignments AS assignment
            LEFT JOIN cafe_fausse.reservations AS reservation
              ON reservation.reservation_id = assignment.reservation_id
            WHERE reservation.reservation_id IS NULL
        ),
        'partial-assignment failure injection leaves no partial state'
    );
END
$booking_tests$;

DO $fingerprint_collision_test$
DECLARE
    collision_customer_id bigint;
    collision_fingerprint bytea;
    target_slot chosen_slots%ROWTYPE;
    result_row record;
    past_reservation_id bigint;
BEGIN
    SELECT * INTO STRICT target_slot FROM chosen_slots WHERE slot_number = 11;
    INSERT INTO cafe_fausse.customers(first_name, last_name, email)
    VALUES ('Collision', 'Candidate', 'collision-candidate.db06@example.com')
    RETURNING customer_id INTO collision_customer_id;

    collision_fingerprint := cafe_fausse.reservation_fingerprint_v1(
        collision_customer_id,
        target_slot.starts_at,
        4
    );
    INSERT INTO cafe_fausse.reservations(
        customer_id, starts_at, ends_at, party_size,
        fingerprint_version, reservation_fingerprint
    ) VALUES (
        collision_customer_id,
        TIMESTAMPTZ '2020-01-01 22:00:00+00',
        TIMESTAMPTZ '2020-01-01 23:30:00+00',
        4, 1, collision_fingerprint
    ) RETURNING reservation_id INTO past_reservation_id;
    INSERT INTO cafe_fausse.reservation_table_assignments(reservation_id, table_number)
    VALUES (past_reservation_id, 30);

    SELECT * INTO STRICT result_row
    FROM cafe_fausse.book_reservation_test(
        'Collision', NULL, 'Candidate', 'collision-candidate.db06@example.com', NULL,
        target_slot.local_start, target_slot.utc_offset_minutes,
        4, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        result_row.outcome = 'booked'
        AND result_row.reservation_id <> past_reservation_id
        AND (SELECT count(*) = 2 FROM cafe_fausse.reservations
             WHERE customer_id = collision_customer_id),
        'fingerprint collision without tuple equality is not an exact retry'
    );
END
$fingerprint_collision_test$;

DO $temporal_configuration_tests$
DECLARE
    local_today date := statement_timestamp() AT TIME ZONE 'America/New_York';
    next_monday date;
    next_sunday date;
    invalid_row record;
BEGIN
    next_monday := local_today + ((1 - EXTRACT(isodow FROM local_today)::integer + 7) % 7);
    IF next_monday <= local_today THEN next_monday := next_monday + 7; END IF;
    next_sunday := local_today + ((7 - EXTRACT(isodow FROM local_today)::integer + 7) % 7);
    IF next_sunday <= local_today THEN next_sunday := next_sunday + 7; END IF;

    PERFORM pg_temp.assert_true(
        (SELECT max(local_start::time) = TIME '21:30'
         FROM cafe_fausse.provisional_availability(next_monday, 4)),
        'Monday through Saturday closing boundary is 23:00'
    );
    PERFORM pg_temp.assert_true(
        (SELECT max(local_start::time) = TIME '19:30'
         FROM cafe_fausse.provisional_availability(next_sunday, 4)),
        'Sunday closing boundary is 21:00'
    );
    PERFORM pg_temp.assert_true(
        (SELECT bool_and(outcome = 'invalid_request')
         FROM cafe_fausse.provisional_availability(next_monday, 0))
        AND (SELECT bool_and(outcome = 'invalid_request')
             FROM cafe_fausse.provisional_availability(next_monday, 121)),
        'party size is bounded by one and derived total capacity'
    );

    PERFORM cafe_fausse.set_reservation_configuration(
        15::smallint, 60::smallint, 60::smallint, 0::smallint, 'America/New_York'
    );
    PERFORM pg_temp.assert_true(
        (SELECT count(*) = 21 AND bool_and(EXTRACT(minute FROM local_start)::integer % 15 = 0)
         FROM cafe_fausse.provisional_availability(next_monday, 4)),
        '15-minute alignment and 60-minute duration are authoritative'
    );

    PERFORM cafe_fausse.set_reservation_configuration(
        60::smallint, 120::smallint, 60::smallint, 0::smallint, 'America/New_York'
    );
    PERFORM pg_temp.assert_true(
        (SELECT count(*) = 5 AND bool_and(ends_at - starts_at = INTERVAL '120 minutes')
         FROM cafe_fausse.provisional_availability(next_monday, 4)),
        '60-minute alignment and 120-minute duration are authoritative'
    );

    PERFORM cafe_fausse.set_restaurant_operating_hours(
        1::smallint, TIME '18:00', TIME '20:00'
    );
    PERFORM pg_temp.assert_true(
        (SELECT min(local_start::time) = TIME '18:00'
             AND max(local_start::time) = TIME '18:00'
         FROM cafe_fausse.provisional_availability(next_monday, 4)),
        'controlled alternate recurring hours affect only prospective availability'
    );

    PERFORM cafe_fausse.set_restaurant_operating_hours(
        1::smallint, TIME '17:00', TIME '23:00'
    );
    PERFORM cafe_fausse.set_reservation_configuration(
        30::smallint, 90::smallint, 365::smallint, 120::smallint, 'America/New_York'
    );
    SELECT * INTO STRICT invalid_row
    FROM cafe_fausse.book_reservation_test(
        'DST', NULL, 'Spring', 'dst-spring.db06@example.com', NULL,
        TIMESTAMP '2027-03-14 02:30', (-300)::smallint,
        4, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        invalid_row.outcome = 'invalid_request'
        AND invalid_row.detail_code = 'nonexistent_local_start',
        'booking rejects a nonexistent DST local time'
    );
    SELECT * INTO STRICT invalid_row
    FROM cafe_fausse.book_reservation_test(
        'DST', NULL, 'Fall', 'dst-fall.db06@example.com', NULL,
        TIMESTAMP '2026-11-01 01:30', (-240)::smallint,
        4, 'no_change', 1, NULL
    );
    PERFORM pg_temp.assert_true(
        invalid_row.outcome = 'invalid_request'
        AND invalid_row.detail_code = 'ambiguous_local_start',
        'booking rejects an ambiguous DST local time'
    );

    PERFORM cafe_fausse.set_reservation_configuration(
        30::smallint, 90::smallint, 60::smallint, 120::smallint, 'America/New_York'
    );
END
$temporal_configuration_tests$;

SELECT pg_temp.assert_true(
    (SELECT outcome = 'subscribed' AND newsletter_subscribed
       FROM cafe_fausse.set_newsletter_preference(
           'Newsletter', NULL, 'Only', 'newsletter-only.db06@example.com', TRUE)),
    'standalone newsletter opt-in creates an identified customer'
);
SELECT pg_temp.assert_true(
    (SELECT outcome = 'unsubscribed' AND NOT newsletter_subscribed
       FROM cafe_fausse.set_newsletter_preference(
           'Newsletter', NULL, 'Only', 'newsletter-only.db06@example.com', FALSE)),
    'standalone newsletter opt-out updates the existing customer'
);

SELECT pg_temp.assert_true(
    NOT EXISTS (
        SELECT 1
        FROM cafe_fausse.reservation_table_assignments AS left_assignment
        JOIN cafe_fausse.reservations AS left_reservation
          ON left_reservation.reservation_id = left_assignment.reservation_id
        JOIN cafe_fausse.reservation_table_assignments AS right_assignment
          ON right_assignment.table_number = left_assignment.table_number
         AND right_assignment.reservation_id > left_assignment.reservation_id
        JOIN cafe_fausse.reservations AS right_reservation
          ON right_reservation.reservation_id = right_assignment.reservation_id
        WHERE left_reservation.starts_at < right_reservation.ends_at
          AND right_reservation.starts_at < left_reservation.ends_at
    ),
    'committed test state contains no table overlap'
);

SELECT test_name AS passed_test
FROM db06_test_results
ORDER BY test_name;

SELECT count(*) AS passed_behavior_tests
FROM db06_test_results;

ROLLBACK;
