\set ON_ERROR_STOP on
\pset pager off

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE TEMPORARY TABLE db06_verification_results (
    check_name text PRIMARY KEY
) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.assert_db06(condition boolean, check_name text)
RETURNS void
LANGUAGE plpgsql
AS $function$
BEGIN
    IF condition IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'DB-06 verification failed: %', check_name;
    END IF;
    INSERT INTO db06_verification_results VALUES (check_name);
END
$function$;

SELECT pg_temp.assert_db06(
    pg_catalog.current_setting('server_version_num')::integer = 180003,
    'required PostgreSQL version 18.3'
);

SELECT pg_temp.assert_db06(
    EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pgcrypto')
    AND NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_extension WHERE extname NOT IN ('plpgsql', 'pgcrypto')
    ),
    'only approved pgcrypto extension plus built-in plpgsql'
);

SELECT pg_temp.assert_db06(
    EXISTS (
        SELECT 1 FROM pg_catalog.pg_namespace
        WHERE nspname = 'cafe_fausse'
          AND nspowner = 'cafe_fausse_owner'::regrole
    ),
    'cafe_fausse schema ownership'
);

SELECT pg_temp.assert_db06(
    (
        SELECT pg_catalog.array_agg(class.relname::text ORDER BY class.relname)
        FROM pg_catalog.pg_class AS class
        JOIN pg_catalog.pg_namespace AS namespace ON namespace.oid = class.relnamespace
        WHERE namespace.nspname = 'cafe_fausse'
          AND class.relkind IN ('r', 'p')
    ) = ARRAY[
        'customers',
        'reservation_configuration',
        'reservation_table_assignments',
        'reservations',
        'restaurant_operating_hours',
        'restaurant_tables'
    ]::text[],
    'exactly six approved business tables'
);

SELECT pg_temp.assert_db06(
    (
        SELECT pg_catalog.array_agg(column_name::text ORDER BY ordinal_position)
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse' AND table_name = 'reservations'
    ) = ARRAY[
        'reservation_id', 'customer_id', 'starts_at', 'ends_at', 'party_size',
        'fingerprint_version', 'reservation_fingerprint'
    ]::text[],
    'reservations exact columns'
);

SELECT pg_temp.assert_db06(
    (
        SELECT pg_catalog.array_agg(column_name::text ORDER BY ordinal_position)
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse'
          AND table_name = 'reservation_table_assignments'
    ) = ARRAY['reservation_id', 'table_number']::text[],
    'reservation_table_assignments exact columns'
);

SELECT pg_temp.assert_db06(
    (
        SELECT pg_catalog.array_agg(
            pg_catalog.format(
                '%s:%s:%s:%s:%s',
                column_name,
                udt_name,
                is_nullable,
                COALESCE(column_default, '<null>'),
                is_identity
            )
            ORDER BY ordinal_position
        )
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse' AND table_name = 'reservations'
    ) = ARRAY[
        'reservation_id:int8:NO:<null>:YES',
        'customer_id:int8:NO:<null>:NO',
        'starts_at:timestamptz:NO:<null>:NO',
        'ends_at:timestamptz:NO:<null>:NO',
        'party_size:int4:NO:<null>:NO',
        'fingerprint_version:int2:NO:1:NO',
        'reservation_fingerprint:bytea:NO:<null>:NO'
    ]::text[],
    'reservations exact types nullability defaults and identity'
);

SELECT pg_temp.assert_db06(
    (
        SELECT pg_catalog.array_agg(
            pg_catalog.format('%s:%s:%s', column_name, udt_name, is_nullable)
            ORDER BY ordinal_position
        )
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse'
          AND table_name = 'reservation_table_assignments'
    ) = ARRAY['reservation_id:int8:NO', 'table_number:int2:NO']::text[],
    'reservation assignments exact types and nullability'
);

SELECT pg_temp.assert_db06(
    NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'cafe_fausse'
          AND table_name IN ('reservations', 'reservation_table_assignments')
          AND column_name IN (
              'status', 'created_at', 'updated_at', 'cancelled_at', 'configuration_id',
              'assigned_capacity', 'availability', 'rank', 'waste', 'random_seed'
          )
    ),
    'unapproved business and audit columns absent'
);

SELECT pg_temp.assert_db06(
    (
        SELECT pg_catalog.array_agg(constraint_row.conname::text ORDER BY constraint_row.conname)
        FROM pg_catalog.pg_constraint AS constraint_row
        JOIN pg_catalog.pg_namespace AS namespace
          ON namespace.oid = constraint_row.connamespace
        WHERE namespace.nspname = 'cafe_fausse'
          AND constraint_row.contype <> 'n'
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
        'reservation_table_assignments_pk',
        'reservation_table_assignments_reservation_fk',
        'reservation_table_assignments_table_fk',
        'reservations_customer_fk',
        'reservations_duration_ck',
        'reservations_exact_identity_uq',
        'reservations_fingerprint_ck',
        'reservations_fingerprint_version_ck',
        'reservations_interval_ck',
        'reservations_party_size_ck',
        'reservations_pk',
        'restaurant_operating_hours_bounds_ck',
        'restaurant_operating_hours_pk',
        'restaurant_operating_hours_weekday_ck',
        'restaurant_tables_capacity_ck',
        'restaurant_tables_number_ck',
        'restaurant_tables_pk'
    ]::text[],
    'exact approved constraint names'
);

SELECT pg_temp.assert_db06(
    NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_constraint AS constraint_row
        JOIN pg_catalog.pg_namespace AS namespace
          ON namespace.oid = constraint_row.connamespace
        WHERE namespace.nspname = 'cafe_fausse'
          AND constraint_row.contype = 'f'
          AND (
              constraint_row.confupdtype <> 'r'
              OR constraint_row.confdeltype <> 'r'
          )
    ),
    'all foreign keys use explicit restrict actions'
);

SELECT pg_temp.assert_db06(
    (
        SELECT pg_catalog.array_agg(indexname::text ORDER BY indexname)
        FROM pg_catalog.pg_indexes
        WHERE schemaname = 'cafe_fausse'
    ) = ARRAY[
        'customers_email_uq',
        'customers_pk',
        'reservation_configuration_pk',
        'reservation_table_assignments_pk',
        'reservation_table_assignments_table_idx',
        'reservations_customer_interval_idx',
        'reservations_exact_identity_uq',
        'reservations_fingerprint_lookup_idx',
        'reservations_interval_idx',
        'reservations_pk',
        'restaurant_operating_hours_pk',
        'restaurant_tables_pk'
    ]::text[],
    'exact nonredundant index set'
);

SELECT pg_temp.assert_db06(
    (SELECT pg_catalog.count(*) FROM cafe_fausse.reservation_configuration) = 1
    AND (SELECT pg_catalog.count(*) FROM cafe_fausse.restaurant_operating_hours) = 7
    AND (SELECT pg_catalog.count(*) FROM cafe_fausse.restaurant_tables) = 30
    AND (SELECT pg_catalog.sum(seating_capacity) FROM cafe_fausse.restaurant_tables) > 0,
    'foundation population remains complete'
);

SELECT pg_temp.assert_db06(
    (
        SELECT pg_catalog.array_agg(routine.proname::text ORDER BY routine.proname)
        FROM pg_catalog.pg_proc AS routine
        JOIN pg_catalog.pg_namespace AS namespace ON namespace.oid = routine.pronamespace
        WHERE namespace.nspname = 'cafe_fausse'
    ) = ARRAY[
        'book_reservation',
        'book_reservation_core',
        'book_reservation_test',
        'canonical_email_lock_key',
        'local_timestamp_candidates',
        'provisional_availability',
        'reservation_fingerprint_serialization_v1',
        'reservation_fingerprint_v1',
        'select_table_allocation',
        'set_newsletter_preference',
        'set_reservation_configuration',
        'set_restaurant_operating_hours',
        'set_restaurant_table_capacity',
        'sha256_text'
    ]::text[],
    'exact controlled routine set'
);

SELECT pg_temp.assert_db06(
    NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_proc AS routine
        JOIN pg_catalog.pg_namespace AS namespace ON namespace.oid = routine.pronamespace
        WHERE namespace.nspname = 'cafe_fausse'
          AND (
              NOT routine.prosecdef
              OR routine.proowner <> 'cafe_fausse_owner'::regrole
              OR NOT routine.proconfig @> ARRAY['search_path=pg_catalog, cafe_fausse']::text[]
          )
    ),
    'all controlled routines are owner-held security definers with safe search path'
);

SELECT pg_temp.assert_db06(
    cafe_fausse.reservation_fingerprint_serialization_v1(
        1,
        TIMESTAMPTZ '2026-08-20 21:00:00+00',
        4
    ) = '1:1|27:2026-08-20T21:00:00.000000Z|1:4'
    AND pg_catalog.octet_length(
        cafe_fausse.reservation_fingerprint_v1(
            1,
            TIMESTAMPTZ '2026-08-20 21:00:00+00',
            4
        )
    ) = 32,
    'fingerprint version 1 serialization and SHA-256 length'
);

SELECT pg_temp.assert_db06(
    cafe_fausse.canonical_email_lock_key('lock@example.com')
        = cafe_fausse.canonical_email_lock_key('lock@example.com'),
    'canonical-email signed lock derivation is deterministic'
);

SELECT pg_temp.assert_db06(
    has_function_privilege(
        'cafe_fausse_app',
        'cafe_fausse.provisional_availability(date,integer)',
        'EXECUTE'
    )
    AND has_function_privilege(
        'cafe_fausse_app',
        'cafe_fausse.book_reservation(text,text,text,text,text,timestamp without time zone,smallint,integer,text)',
        'EXECUTE'
    )
    AND has_function_privilege(
        'cafe_fausse_app',
        'cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)',
        'EXECUTE'
    ),
    'runtime can execute only production entry points'
);

SELECT pg_temp.assert_db06(
    NOT has_function_privilege(
        'cafe_fausse_app',
        'cafe_fausse.book_reservation_test(text,text,text,text,text,timestamp without time zone,smallint,integer,text,bigint,text)',
        'EXECUTE'
    )
    AND NOT has_function_privilege(
        'cafe_fausse_app',
        'cafe_fausse.select_table_allocation(smallint[],integer[],integer,bigint)',
        'EXECUTE'
    )
    AND NOT has_function_privilege(
        'cafe_fausse_app',
        'cafe_fausse.set_restaurant_table_capacity(smallint,integer)',
        'EXECUTE'
    ),
    'runtime cannot execute test seams or controlled configuration writers'
);

SELECT pg_temp.assert_db06(
    NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.reservations', 'SELECT')
    AND NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.reservations', 'INSERT')
    AND NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.reservation_table_assignments', 'SELECT')
    AND NOT has_table_privilege('cafe_fausse_app', 'cafe_fausse.reservation_table_assignments', 'INSERT'),
    'runtime cannot read or mutate reservation persistence directly'
);

SELECT pg_temp.assert_db06(
    NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_proc AS routine
        JOIN pg_catalog.pg_namespace AS namespace ON namespace.oid = routine.pronamespace
        CROSS JOIN LATERAL pg_catalog.aclexplode(
            COALESCE(
                routine.proacl,
                pg_catalog.acldefault('f', routine.proowner)
            )
        ) AS privilege
        WHERE namespace.nspname = 'cafe_fausse'
          AND privilege.grantee = 0
          AND privilege.privilege_type = 'EXECUTE'
    ),
    'PUBLIC has no routine execution privilege'
);

SELECT pg_temp.assert_db06(
    NOT EXISTS (
        SELECT 1
        FROM cafe_fausse.reservations AS left_reservation
        JOIN cafe_fausse.reservations AS right_reservation
          ON left_reservation.reservation_id < right_reservation.reservation_id
         AND left_reservation.customer_id = right_reservation.customer_id
         AND left_reservation.starts_at < right_reservation.ends_at
         AND right_reservation.starts_at < left_reservation.ends_at
    ),
    'no same-customer overlapping reservations'
);

SELECT pg_temp.assert_db06(
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
    'no table participates in overlapping reservations'
);

SELECT pg_temp.assert_db06(
    NOT EXISTS (
        SELECT 1
        FROM cafe_fausse.reservations AS reservation_row
        WHERE NOT EXISTS (
            SELECT 1
            FROM cafe_fausse.reservation_table_assignments AS assignment
            WHERE assignment.reservation_id = reservation_row.reservation_id
        )
    ),
    'every committed reservation has at least one assignment'
);

SELECT pg_temp.assert_db06(
    NOT EXISTS (
        SELECT 1
        FROM cafe_fausse.reservations AS reservation_row
        WHERE reservation_row.fingerprint_version <> 1
           OR reservation_row.reservation_fingerprint
              <> cafe_fausse.reservation_fingerprint_v1(
                  reservation_row.customer_id,
                  reservation_row.starts_at,
                  reservation_row.party_size
              )
    ),
    'all committed fingerprints match version 1 facts'
);

SELECT check_name AS passed_check
FROM db06_verification_results
ORDER BY check_name;

SELECT pg_catalog.count(*) AS passed_verification_checks
FROM db06_verification_results;

ROLLBACK;
