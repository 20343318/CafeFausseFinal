\set ON_ERROR_STOP on
\pset pager off

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE TEMPORARY TABLE db05_verification_results (
    check_name text PRIMARY KEY
) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.assert_db05(condition boolean, check_name text)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    IF condition IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'DB-05 verification failed: %', check_name;
    END IF;

    INSERT INTO db05_verification_results VALUES (check_name);
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

SELECT pg_temp.assert_db05(
    pg_catalog.current_setting('server_version_num')::integer >= 140000,
    'supported PostgreSQL version (14 or newer)'
);

SELECT pg_temp.assert_db05(
    EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pgcrypto'),
    'pgcrypto extension installed'
);

SELECT pg_temp.assert_db05(
    pg_temp.pgcrypto_sha256_length('cafe-fausse-db05-verification') = 32,
    'pgcrypto SHA-256 digest capability'
);

SELECT pg_temp.assert_db05(
    EXISTS (
        SELECT 1
        FROM pg_catalog.pg_namespace
        WHERE nspname = 'cafe_fausse'
          AND nspowner = 'cafe_fausse_owner'::regrole
    ),
    'cafe_fausse schema ownership'
);

SELECT pg_temp.assert_db05(
    (
        SELECT pg_catalog.array_agg(c.relname::text ORDER BY c.relname)
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'cafe_fausse'
          AND c.relkind IN ('r', 'p')
    ) = ARRAY[
        'customers',
        'reservation_configuration',
        'restaurant_operating_hours',
        'restaurant_tables'
    ]::text[],
    'exactly four DB-05 business tables'
);

SELECT pg_temp.assert_db05(
    pg_catalog.to_regclass('cafe_fausse.reservations') IS NULL
    AND pg_catalog.to_regclass('cafe_fausse.reservation_table_assignments') IS NULL,
    'DB-06 tables absent'
);

SELECT pg_temp.assert_db05(
    (
        SELECT pg_catalog.array_agg(column_name::text ORDER BY ordinal_position)
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse' AND table_name = 'customers'
    ) = ARRAY[
        'customer_id', 'first_name', 'middle_initial', 'last_name',
        'email', 'phone', 'newsletter_subscribed'
    ]::text[],
    'customers exact columns'
);

SELECT pg_temp.assert_db05(
    (
        SELECT pg_catalog.array_agg(column_name::text ORDER BY ordinal_position)
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse' AND table_name = 'reservation_configuration'
    ) = ARRAY[
        'configuration_id', 'start_interval_minutes',
        'reservation_duration_minutes', 'advance_booking_window_days',
        'same_day_lead_minutes', 'restaurant_timezone'
    ]::text[],
    'reservation_configuration exact columns'
);

SELECT pg_temp.assert_db05(
    (
        SELECT pg_catalog.array_agg(column_name::text ORDER BY ordinal_position)
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse' AND table_name = 'restaurant_operating_hours'
    ) = ARRAY['weekday', 'opens_at', 'closes_at']::text[],
    'restaurant_operating_hours exact columns'
);

SELECT pg_temp.assert_db05(
    (
        SELECT pg_catalog.array_agg(column_name::text ORDER BY ordinal_position)
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse' AND table_name = 'restaurant_tables'
    ) = ARRAY['table_number', 'seating_capacity']::text[],
    'restaurant_tables exact columns'
);

SELECT pg_temp.assert_db05(
    (
        SELECT pg_catalog.array_agg(con.conname::text ORDER BY con.conname)
        FROM pg_catalog.pg_constraint AS con
        JOIN pg_catalog.pg_namespace AS n ON n.oid = con.connamespace
        WHERE n.nspname = 'cafe_fausse'
          AND con.contype <> 'n'
    ) = ARRAY[
        'customers_email_canonical_ck',
        'customers_email_uq',
        'customers_first_name_ck',
        'customers_last_name_ck',
        'customers_middle_initial_ck',
        'customers_phone_ck',
        'customers_pk',
        'reservation_configuration_duration_ck',
        'reservation_configuration_interval_ck',
        'reservation_configuration_lead_ck',
        'reservation_configuration_pk',
        'reservation_configuration_singleton_ck',
        'reservation_configuration_timezone_ck',
        'reservation_configuration_window_ck',
        'restaurant_operating_hours_bounds_ck',
        'restaurant_operating_hours_pk',
        'restaurant_operating_hours_weekday_ck',
        'restaurant_tables_capacity_ck',
        'restaurant_tables_number_ck',
        'restaurant_tables_pk'
    ]::text[],
    'exact approved foundation constraint names'
);

SELECT pg_temp.assert_db05(
    (
        SELECT pg_catalog.array_agg(indexname::text ORDER BY indexname)
        FROM pg_catalog.pg_indexes
        WHERE schemaname = 'cafe_fausse'
    ) = ARRAY[
        'customers_email_uq',
        'customers_pk',
        'reservation_configuration_pk',
        'restaurant_operating_hours_pk',
        'restaurant_tables_pk'
    ]::text[],
    'only five constraint-owned foundation indexes'
);

SELECT pg_temp.assert_db05(
    (SELECT pg_catalog.count(*) FROM reservation_configuration) = 1
    AND EXISTS (
        SELECT 1
        FROM reservation_configuration
        WHERE configuration_id = 1
          AND start_interval_minutes = 30
          AND reservation_duration_minutes = 90
          AND advance_booking_window_days = 60
          AND same_day_lead_minutes = 120
          AND restaurant_timezone = 'America/New_York'
    ),
    'exact singleton configuration seed'
);

SELECT pg_temp.assert_db05(
    EXISTS (
        SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = 'America/New_York'
    ),
    'seeded timezone in PostgreSQL catalogue'
);

SELECT pg_temp.assert_db05(
    (SELECT pg_catalog.count(*) FROM restaurant_operating_hours) = 7
    AND NOT EXISTS (
        SELECT expected.weekday, expected.opens_at, expected.closes_at
        FROM (
            VALUES
                (1::smallint, TIME '17:00', TIME '23:00'),
                (2::smallint, TIME '17:00', TIME '23:00'),
                (3::smallint, TIME '17:00', TIME '23:00'),
                (4::smallint, TIME '17:00', TIME '23:00'),
                (5::smallint, TIME '17:00', TIME '23:00'),
                (6::smallint, TIME '17:00', TIME '23:00'),
                (7::smallint, TIME '17:00', TIME '21:00')
        ) AS expected(weekday, opens_at, closes_at)
        EXCEPT
        SELECT actual.weekday, actual.opens_at, actual.closes_at
        FROM restaurant_operating_hours AS actual
    ),
    'exact seven-row SRS operating-hours seed'
);

SELECT pg_temp.assert_db05(
    (SELECT pg_catalog.count(*) FROM restaurant_tables) = 30
    AND (SELECT pg_catalog.min(table_number) FROM restaurant_tables) = 1
    AND (SELECT pg_catalog.max(table_number) FROM restaurant_tables) = 30
    AND (SELECT pg_catalog.min(seating_capacity) FROM restaurant_tables) = 4
    AND (SELECT pg_catalog.max(seating_capacity) FROM restaurant_tables) = 4
    AND (SELECT pg_catalog.sum(seating_capacity) FROM restaurant_tables) = 120,
    'exact 30 x 4 table seed and total capacity 120'
);

SELECT pg_temp.assert_db05(
    NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_tables
        WHERE schemaname = 'cafe_fausse'
          AND tableowner <> 'cafe_fausse_owner'
    ),
    'foundation tables owned by migration owner role'
);

SELECT pg_temp.assert_db05(
    has_schema_privilege('cafe_fausse_app', 'cafe_fausse', 'USAGE')
    AND NOT has_schema_privilege('cafe_fausse_app', 'cafe_fausse', 'CREATE'),
    'runtime schema usage without create privilege'
);

SELECT pg_temp.assert_db05(
    NOT EXISTS (
        SELECT 1
        FROM (VALUES
            ('cafe_fausse.customers'::text),
            ('cafe_fausse.reservation_configuration'::text),
            ('cafe_fausse.restaurant_operating_hours'::text),
            ('cafe_fausse.restaurant_tables'::text)
        ) AS foundation(table_name)
        WHERE NOT has_table_privilege('cafe_fausse_app', foundation.table_name, 'SELECT')
           OR has_table_privilege('cafe_fausse_app', foundation.table_name, 'INSERT')
           OR has_table_privilege('cafe_fausse_app', foundation.table_name, 'UPDATE')
           OR has_table_privilege('cafe_fausse_app', foundation.table_name, 'DELETE')
           OR has_table_privilege('cafe_fausse_app', foundation.table_name, 'TRUNCATE')
    ),
    'runtime role has read-only foundation access'
);

SELECT pg_temp.assert_db05(
    NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_roles
        WHERE rolname IN ('cafe_fausse_owner', 'cafe_fausse_app', 'cafe_fausse_test')
          AND (
              rolcanlogin OR rolsuper OR rolcreatedb OR rolcreaterole
              OR rolreplication OR rolbypassrls
          )
    ),
    'foundation roles are passwordless non-login least-privilege groups'
);

SELECT pg_temp.assert_db05(
    has_table_privilege('cafe_fausse_test', 'cafe_fausse.customers', 'INSERT')
    AND has_table_privilege('cafe_fausse_test', 'cafe_fausse.restaurant_tables', 'UPDATE'),
    'isolated test capability can exercise foundation constraints'
);

SELECT check_name AS passed_check
FROM db05_verification_results
ORDER BY check_name;

SELECT pg_catalog.count(*) AS passed_verification_checks
FROM db05_verification_results;

ROLLBACK;
