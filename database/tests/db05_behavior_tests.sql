\set ON_ERROR_STOP on
\pset pager off

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE TEMPORARY TABLE db05_test_results (
    test_name text PRIMARY KEY
) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.assert_true(condition boolean, test_name text)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    IF condition IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'DB-05 test failed: %', test_name;
    END IF;
    INSERT INTO db05_test_results VALUES (test_name);
END
$function$;

CREATE OR REPLACE FUNCTION pg_temp.assert_raises(
    statement_text text,
    expected_states text[],
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
    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS actual_state = RETURNED_SQLSTATE;
            IF actual_state = ANY(expected_states) THEN
                INSERT INTO db05_test_results VALUES (test_name);
                RETURN;
            END IF;
            RAISE EXCEPTION
                'DB-05 test failed: % raised SQLSTATE %, expected one of %',
                test_name, actual_state, expected_states;
    END;

    RAISE EXCEPTION 'DB-05 test failed: % did not raise an error', test_name;
END
$function$;

CREATE OR REPLACE FUNCTION pg_temp.pgcrypto_sha256_length(value text)
RETURNS integer
LANGUAGE plpgsql
AS $function$
DECLARE
    extension_schema name;
    digest_length integer;
BEGIN
    SELECT namespace.nspname
    INTO extension_schema
    FROM pg_catalog.pg_extension AS extension
    JOIN pg_catalog.pg_namespace AS namespace
      ON namespace.oid = extension.extnamespace
    WHERE extension.extname = 'pgcrypto';

    IF extension_schema IS NULL THEN
        RETURN NULL;
    END IF;

    EXECUTE pg_catalog.format(
        'SELECT pg_catalog.octet_length(%I.digest(pg_catalog.convert_to($1, ''UTF8''), ''sha256''))',
        extension_schema
    )
    INTO digest_length
    USING value;

    RETURN digest_length;
END
$function$;

-- Clean state and catalogue verification.
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM information_schema.tables WHERE table_schema = 'cafe_fausse') = 4,
    'four and only four DB-05 tables exist'
);
SELECT pg_temp.assert_true(
    to_regclass('cafe_fausse.reservations') IS NULL
    AND to_regclass('cafe_fausse.reservation_table_assignments') IS NULL,
    'reservation and assignment tables do not exist'
);
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM pg_catalog.pg_constraint AS c
      JOIN pg_catalog.pg_namespace AS n ON n.oid = c.connamespace
      WHERE n.nspname = 'cafe_fausse' AND c.contype <> 'n') = 20,
    'twenty approved named foundation constraints exist'
);
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM pg_catalog.pg_indexes WHERE schemaname = 'cafe_fausse') = 5,
    'five nonredundant constraint-owned indexes exist'
);
SELECT pg_temp.assert_true(
    EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pgcrypto')
    AND pg_temp.pgcrypto_sha256_length('db05-test') = 32,
    'pgcrypto SHA-256 is ready'
);

-- Customer integrity and preserved display values.
INSERT INTO customers (first_name, middle_initial, last_name, email, phone)
VALUES ('Élodie', 'A', 'O''Connor-Smith', 'elodie@example.com', '+1 (202) 555-0199');

INSERT INTO customers (first_name, last_name, email, newsletter_subscribed)
VALUES ('B', 'Ng', 'b@example.com', TRUE);

SELECT pg_temp.assert_true(
    (SELECT count(*) FROM customers WHERE email IN ('elodie@example.com', 'b@example.com')) = 2,
    'valid customers insert successfully'
);
SELECT pg_temp.assert_true(
    (SELECT count(DISTINCT customer_id) FROM customers WHERE email IN ('elodie@example.com', 'b@example.com')) = 2,
    'customer identity is database-generated and unique'
);
SELECT pg_temp.assert_true(
    (SELECT newsletter_subscribed FROM customers WHERE email = 'elodie@example.com') = FALSE,
    'newsletter default is false'
);
SELECT pg_temp.assert_true(
    (SELECT first_name || '|' || last_name FROM customers WHERE email = 'elodie@example.com')
        = 'Élodie|O''Connor-Smith',
    'name punctuation and accents are preserved'
);
SELECT pg_temp.assert_true(
    (SELECT phone FROM customers WHERE email = 'elodie@example.com') = '+1 (202) 555-0199',
    'permitted phone formatting is preserved'
);

UPDATE customers SET newsletter_subscribed = TRUE WHERE email = 'elodie@example.com';
SELECT pg_temp.assert_true(
    (SELECT newsletter_subscribed FROM customers WHERE email = 'elodie@example.com'),
    'newsletter state can be set true without deleting customer'
);
UPDATE customers SET newsletter_subscribed = FALSE WHERE email = 'elodie@example.com';
SELECT pg_temp.assert_true(
    NOT (SELECT newsletter_subscribed FROM customers WHERE email = 'elodie@example.com'),
    'newsletter state can be set false without deleting customer'
);

SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES (NULL, 'Valid', 'missing-first@example.com')$sql$,
    ARRAY['23502'], 'missing first name is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('Valid', NULL, 'missing-last@example.com')$sql$,
    ARRAY['23502'], 'missing last name is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('Valid', 'Name', NULL)$sql$,
    ARRAY['23502'], 'missing email is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email, newsletter_subscribed) VALUES ('Valid', 'Name', 'missing-newsletter@example.com', NULL)$sql$,
    ARRAY['23502'], 'missing newsletter state is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('Valid', 'Name', 'UPPER@example.com')$sql$,
    ARRAY['23514'], 'uppercase persisted email is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('Valid', 'Name', ' spaced@example.com ')$sql$,
    ARRAY['23514'], 'outer-whitespace email is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('Valid', 'Name', '')$sql$,
    ARRAY['23514'], 'empty email is rejected'
);
SELECT pg_temp.assert_raises(
    'INSERT INTO customers (first_name, last_name, email) VALUES (''Valid'', ''Name'', '''
        || repeat('a', 243) || '@example.com'')',
    ARRAY['22001', '23514'], 'over-254-character email is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('Other', 'Person', 'elodie@example.com')$sql$,
    ARRAY['23505'], 'duplicate canonical email is rejected'
);

INSERT INTO customers (first_name, last_name, email)
VALUES ('É', repeat('L', 100), 'name-boundary@example.com');
SELECT pg_temp.assert_true(
    (SELECT char_length(first_name) = 1 AND char_length(last_name) = 100
     FROM customers WHERE email = 'name-boundary@example.com'),
    'one-character alphabetic and 100-character names are accepted'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('', 'Valid', 'blank-first@example.com')$sql$,
    ARRAY['23514'], 'blank first name is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('   ', 'Valid', 'spaces-first@example.com')$sql$,
    ARRAY['23514'], 'whitespace-only first name is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('123-', 'Valid', 'letterless-first@example.com')$sql$,
    ARRAY['23514'], 'letterless first name is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('Mary  Jane', 'Valid', 'uncollapsed-first@example.com')$sql$,
    ARRAY['23514'], 'uncollapsed first-name whitespace is rejected'
);
SELECT pg_temp.assert_raises(
    'INSERT INTO customers (first_name, last_name, email) VALUES ('''
        || repeat('A', 101) || ''', ''Valid'', ''long-first@example.com'')',
    ARRAY['22001', '23514'], 'over-100-character first name is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email) VALUES ('Valid', '---', 'letterless-last@example.com')$sql$,
    ARRAY['23514'], 'letterless last name is rejected'
);

INSERT INTO customers (first_name, middle_initial, last_name, email)
VALUES ('Null', NULL, 'Initial', 'null-initial@example.com');
SELECT pg_temp.assert_true(
    (SELECT middle_initial IS NULL FROM customers WHERE email = 'null-initial@example.com'),
    'null middle initial is accepted'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, middle_initial, last_name, email) VALUES ('Lower', 'a', 'Initial', 'lower-initial@example.com')$sql$,
    ARRAY['23514'], 'lowercase middle initial is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, middle_initial, last_name, email) VALUES ('Punct', '.', 'Initial', 'punct-initial@example.com')$sql$,
    ARRAY['23514'], 'punctuation middle initial is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, middle_initial, last_name, email) VALUES ('Empty', '', 'Initial', 'empty-initial@example.com')$sql$,
    ARRAY['23514'], 'empty middle initial is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, middle_initial, last_name, email) VALUES ('Multi', 'AB', 'Initial', 'multi-initial@example.com')$sql$,
    ARRAY['22001', '23514'], 'multi-character middle initial is rejected'
);

INSERT INTO customers (first_name, last_name, email, phone)
VALUES ('Null', 'Phone', 'null-phone@example.com', NULL);
SELECT pg_temp.assert_true(
    (SELECT phone IS NULL FROM customers WHERE email = 'null-phone@example.com'),
    'null phone is accepted'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email, phone) VALUES ('Bad', 'Phone', 'bad-phone-char@example.com', '202/555/0199')$sql$,
    ARRAY['23514'], 'phone with disallowed characters is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email, phone) VALUES ('Short', 'Phone', 'short-phone@example.com', '123-456')$sql$,
    ARRAY['23514'], 'phone with fewer than seven digits is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO customers (first_name, last_name, email, phone) VALUES ('Long', 'Phone', 'long-phone@example.com', '1234567890123456')$sql$,
    ARRAY['23514'], 'phone with more than fifteen digits is rejected'
);

SELECT pg_temp.assert_true(
    NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse'
          AND column_name IN (
              'confirmation_email', 'raw_email', 'normalized_email', 'normalized_phone',
              'password', 'created_at', 'updated_at', 'status', 'active'
          )
    ),
    'excluded customer and audit columns are absent'
);

-- Configuration integrity.
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM reservation_configuration) = 1
    AND (SELECT restaurant_timezone FROM reservation_configuration WHERE configuration_id = 1)
        = 'America/New_York',
    'exact default singleton configuration exists'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO reservation_configuration (configuration_id) VALUES (2)$sql$,
    ARRAY['23514'], 'second configuration row is rejected'
);

UPDATE reservation_configuration SET start_interval_minutes = 15;
UPDATE reservation_configuration SET start_interval_minutes = 30;
UPDATE reservation_configuration SET start_interval_minutes = 60;
SELECT pg_temp.assert_true(
    (SELECT start_interval_minutes FROM reservation_configuration) = 60,
    'all allowed start intervals are accepted'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE reservation_configuration SET start_interval_minutes = 45$sql$,
    ARRAY['23514'], 'disallowed start interval is rejected'
);

UPDATE reservation_configuration SET reservation_duration_minutes = 60;
UPDATE reservation_configuration SET reservation_duration_minutes = 90;
UPDATE reservation_configuration SET reservation_duration_minutes = 120;
SELECT pg_temp.assert_true(
    (SELECT reservation_duration_minutes FROM reservation_configuration) = 120,
    'all allowed reservation durations are accepted'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE reservation_configuration SET reservation_duration_minutes = 75$sql$,
    ARRAY['23514'], 'disallowed reservation duration is rejected'
);

UPDATE reservation_configuration SET advance_booking_window_days = 1;
UPDATE reservation_configuration SET advance_booking_window_days = 365;
SELECT pg_temp.assert_true(
    (SELECT advance_booking_window_days FROM reservation_configuration) = 365,
    'advance-window boundaries 1 and 365 are accepted'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE reservation_configuration SET advance_booking_window_days = 0$sql$,
    ARRAY['23514'], 'advance window below one is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE reservation_configuration SET advance_booking_window_days = 366$sql$,
    ARRAY['23514'], 'advance window above 365 is rejected'
);

UPDATE reservation_configuration SET same_day_lead_minutes = 0;
UPDATE reservation_configuration SET same_day_lead_minutes = 1440;
SELECT pg_temp.assert_true(
    (SELECT same_day_lead_minutes FROM reservation_configuration) = 1440,
    'lead-time boundaries 0 and 1440 are accepted'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE reservation_configuration SET same_day_lead_minutes = -1$sql$,
    ARRAY['23514'], 'lead time below zero is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE reservation_configuration SET same_day_lead_minutes = 1441$sql$,
    ARRAY['23514'], 'lead time above 1440 is rejected'
);

UPDATE reservation_configuration SET restaurant_timezone = 'Europe/Paris';
SELECT pg_temp.assert_true(
    (SELECT restaurant_timezone FROM reservation_configuration) = 'Europe/Paris',
    'alternate trimmed timezone text can be installed in an isolated test'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE reservation_configuration SET restaurant_timezone = ''$sql$,
    ARRAY['23514'], 'empty timezone is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE reservation_configuration SET restaurant_timezone = ' America/New_York '$sql$,
    ARRAY['23514'], 'untrimmed timezone is rejected'
);
SELECT pg_temp.assert_true(
    EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = 'America/New_York'),
    'America/New_York exists in PostgreSQL timezone catalogue'
);
SELECT pg_temp.assert_true(
    to_regclass('cafe_fausse.reservation_configuration_history') IS NULL,
    'configuration history object is absent'
);

-- Operating-hours integrity.
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM restaurant_operating_hours) = 7
    AND (SELECT count(*) FROM restaurant_operating_hours WHERE weekday BETWEEN 1 AND 7) = 7,
    'exactly seven ISO weekday rows are seeded'
);
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM restaurant_operating_hours
      WHERE weekday BETWEEN 1 AND 6 AND opens_at = TIME '17:00' AND closes_at = TIME '23:00') = 6,
    'Monday through Saturday SRS hours are exact'
);
SELECT pg_temp.assert_true(
    EXISTS (SELECT 1 FROM restaurant_operating_hours
            WHERE weekday = 7 AND opens_at = TIME '17:00' AND closes_at = TIME '21:00'),
    'Sunday SRS hours are exact'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO restaurant_operating_hours VALUES (1, TIME '10:00', TIME '11:00')$sql$,
    ARRAY['23505'], 'duplicate weekday is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO restaurant_operating_hours VALUES (8, TIME '10:00', TIME '11:00')$sql$,
    ARRAY['23514'], 'weekday outside one through seven is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE restaurant_operating_hours SET opens_at = NULL WHERE weekday = 1$sql$,
    ARRAY['23502'], 'null opening boundary is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE restaurant_operating_hours SET closes_at = NULL WHERE weekday = 1$sql$,
    ARRAY['23502'], 'null closing boundary is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE restaurant_operating_hours SET opens_at = TIME '17:00', closes_at = TIME '17:00' WHERE weekday = 1$sql$,
    ARRAY['23514'], 'equal opening and closing is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE restaurant_operating_hours SET opens_at = TIME '18:00', closes_at = TIME '17:00' WHERE weekday = 1$sql$,
    ARRAY['23514'], 'opening after closing is rejected'
);
UPDATE restaurant_operating_hours
SET opens_at = TIME '16:00', closes_at = TIME '22:00'
WHERE weekday = 1;
SELECT pg_temp.assert_true(
    EXISTS (SELECT 1 FROM restaurant_operating_hours
            WHERE weekday = 1 AND opens_at = TIME '16:00' AND closes_at = TIME '22:00'),
    'alternate same-day recurring hours work without schema changes'
);
SELECT pg_temp.assert_true(
    NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'cafe_fausse'
          AND table_name IN ('holiday_hours', 'operating_hours_exceptions', 'schedule_history')
    ),
    'holiday exception and schedule history objects are absent'
);

-- Restaurant-table integrity.
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM restaurant_tables) = 30
    AND (SELECT min(table_number) FROM restaurant_tables) = 1
    AND (SELECT max(table_number) FROM restaurant_tables) = 30,
    'table numbers are exactly one through thirty'
);
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM restaurant_tables WHERE seating_capacity = 4) = 30,
    'all seeded seating capacities equal four'
);
SELECT pg_temp.assert_true(
    (SELECT sum(seating_capacity) FROM restaurant_tables) = 120,
    'derived initial total capacity is 120'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO restaurant_tables VALUES (1, 4)$sql$,
    ARRAY['23505'], 'duplicate table number is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO restaurant_tables VALUES (0, 4)$sql$,
    ARRAY['23514'], 'zero table number is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$INSERT INTO restaurant_tables VALUES (-1, 4)$sql$,
    ARRAY['23514'], 'negative table number is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE restaurant_tables SET seating_capacity = 0 WHERE table_number = 1$sql$,
    ARRAY['23514'], 'zero seating capacity is rejected'
);
SELECT pg_temp.assert_raises(
    $sql$UPDATE restaurant_tables SET seating_capacity = -1 WHERE table_number = 1$sql$,
    ARRAY['23514'], 'negative seating capacity is rejected'
);
UPDATE restaurant_tables SET seating_capacity = 6 WHERE table_number = 1;
SELECT pg_temp.assert_true(
    (SELECT seating_capacity FROM restaurant_tables WHERE table_number = 1) = 6,
    'alternate positive table capacity is accepted in isolated tests'
);
SELECT pg_temp.assert_true(
    NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse' AND table_name = 'restaurant_tables'
          AND column_name IN (
              'active', 'is_active', 'adjacent_to', 'combinable', 'location',
              'total_capacity', 'maximum_party_size'
          )
    ),
    'excluded restaurant-table columns are absent'
);

-- Role and source-of-truth boundaries.
SELECT pg_temp.assert_true(
    has_table_privilege('cafe_fausse_app', 'cafe_fausse.customers', 'SELECT')
    AND NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.customers', 'INSERT')
    AND NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.customers', 'UPDATE')
    AND NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.customers', 'DELETE'),
    'runtime customer access is read-only until controlled operations exist'
);
SELECT pg_temp.assert_true(
    NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.reservation_configuration', 'DELETE')
    AND NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.restaurant_operating_hours', 'DELETE')
    AND NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.restaurant_tables', 'INSERT'),
    'runtime cannot remove or expand foundation populations'
);
SELECT pg_temp.assert_true(
    NOT has_schema_privilege('cafe_fausse_app', 'cafe_fausse', 'CREATE'),
    'runtime cannot alter foundation schema'
);
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM information_schema.columns
     WHERE table_schema = 'cafe_fausse' AND column_name = 'newsletter_subscribed') = 1,
    'newsletter Boolean has one authoritative home'
);
SELECT pg_temp.assert_true(
    (SELECT count(*) FROM information_schema.columns
     WHERE table_schema = 'cafe_fausse' AND column_name = 'restaurant_timezone') = 1,
    'scalar timezone setting has one authoritative home'
);

SELECT test_name AS passed_test
FROM db05_test_results
ORDER BY test_name;

SELECT count(*) AS passed_behavior_tests
FROM db05_test_results;

ROLLBACK;
