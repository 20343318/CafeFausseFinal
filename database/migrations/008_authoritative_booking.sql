\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE FUNCTION cafe_fausse.book_reservation_core(
    p_first_name text,
    p_middle_initial text,
    p_last_name text,
    p_email text,
    p_phone text,
    p_local_start timestamp without time zone,
    p_utc_offset_minutes smallint,
    p_party_size integer,
    p_newsletter_action text,
    p_tie_rank bigint,
    p_failure_stage text
)
RETURNS TABLE (
    outcome text,
    detail_code text,
    reservation_id bigint,
    starts_at timestamp with time zone,
    ends_at timestamp with time zone,
    party_size integer,
    assigned_table_numbers smallint[],
    newsletter_subscribed boolean,
    phone_notice boolean,
    fingerprint_version smallint,
    reservation_fingerprint bytea
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    configuration cafe_fausse.reservation_configuration%ROWTYPE;
    customer cafe_fausse.customers%ROWTYPE;
    existing_reservation cafe_fausse.reservations%ROWTYPE;
    requested_hours cafe_fausse.restaurant_operating_hours%ROWTYPE;
    locked_table_numbers smallint[];
    locked_capacities integer[];
    free_table_numbers smallint[];
    free_capacities integer[];
    selected_tables smallint[];
    selected_capacity integer;
    allocation_tie_count bigint;
    allocation_selected_rank bigint;
    resolved_start timestamp with time zone;
    resolved_end timestamp with time zone;
    authoritative_now timestamp with time zone;
    authoritative_local_now timestamp without time zone;
    generated_fingerprint bytea;
    candidate_count integer;
    candidate_offset integer;
    total_capacity integer;
    inserted_reservation_id bigint;
    assigned_count integer;
    assigned_capacity integer;
    assignment_table smallint;
    supplied_phone_digits text;
    stored_phone_digits text;
    is_new_customer boolean := false;
    populate_middle_initial boolean := false;
    populate_phone boolean := false;
    differing_phone boolean := false;
    abort_outcome text;
    abort_detail text;
BEGIN
    PERFORM pg_catalog.set_config('lock_timeout', '3s', true);
    PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

    IF pg_catalog.current_setting('transaction_isolation') <> 'read committed' THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'requires_read_committed'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    END IF;

    IF p_first_name IS NULL
       OR p_last_name IS NULL
       OR p_email IS NULL
       OR p_local_start IS NULL
       OR p_utc_offset_minutes IS NULL
       OR p_party_size IS NULL
       OR p_newsletter_action IS NULL
       OR p_newsletter_action NOT IN ('subscribe', 'unsubscribe', 'no_change')
       OR pg_catalog.char_length(p_first_name) NOT BETWEEN 1 AND 100
       OR pg_catalog.char_length(p_last_name) NOT BETWEEN 1 AND 100
       OR p_first_name <> pg_catalog.regexp_replace(pg_catalog.btrim(p_first_name), '[[:space:]]+', ' ', 'g')
       OR p_last_name <> pg_catalog.regexp_replace(pg_catalog.btrim(p_last_name), '[[:space:]]+', ' ', 'g')
       OR p_first_name !~ '[[:alpha:]]'
       OR p_last_name !~ '[[:alpha:]]'
       OR p_email = ''
       OR p_email <> pg_catalog.btrim(p_email)
       OR p_email <> pg_catalog.lower(p_email)
       OR pg_catalog.char_length(p_email) > 254
       OR (p_middle_initial IS NOT NULL AND p_middle_initial !~ '^[[:upper:]]$')
       OR (
           p_phone IS NOT NULL
           AND (
               p_phone !~ '^[0-9 +().-]+$'
               OR pg_catalog.char_length(
                   pg_catalog.regexp_replace(p_phone, '[^0-9]', '', 'g')
               ) NOT BETWEEN 7 AND 15
           )
       )
       OR (
           p_failure_stage IS NOT NULL
           AND p_failure_stage NOT IN (
               'after_customer_insert',
               'after_optional_field_population',
               'after_newsletter_update',
               'after_reservation_insert',
               'after_partial_assignment_insert'
           )
       ) THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'invalid_normalized_input'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    END IF;

    PERFORM pg_catalog.pg_advisory_xact_lock(1128682322, 1);

    IF (SELECT pg_catalog.count(*) FROM cafe_fausse.reservation_configuration) <> 1 THEN
        RETURN QUERY SELECT
            'invalid_database_configuration'::text, 'configuration_row_count'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    END IF;

    SELECT config.*
    INTO STRICT configuration
    FROM cafe_fausse.reservation_configuration AS config
    WHERE config.configuration_id = 1
    FOR UPDATE;

    IF (SELECT pg_catalog.count(*) FROM cafe_fausse.restaurant_operating_hours) <> 7
       OR (SELECT pg_catalog.array_agg(hours.weekday ORDER BY hours.weekday)
           FROM cafe_fausse.restaurant_operating_hours AS hours)
          <> ARRAY[1,2,3,4,5,6,7]::smallint[] THEN
        RETURN QUERY SELECT
            'invalid_database_configuration'::text, 'operating_hours_population'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    END IF;

    PERFORM hours.weekday
    FROM cafe_fausse.restaurant_operating_hours AS hours
    ORDER BY hours.weekday
    FOR UPDATE;

    SELECT
        pg_catalog.array_agg(locked.table_number ORDER BY locked.table_number),
        pg_catalog.array_agg(locked.seating_capacity ORDER BY locked.table_number),
        pg_catalog.sum(locked.seating_capacity)
    INTO locked_table_numbers, locked_capacities, total_capacity
    FROM (
        SELECT table_row.table_number, table_row.seating_capacity
        FROM cafe_fausse.restaurant_tables AS table_row
        ORDER BY table_row.table_number
        FOR UPDATE
    ) AS locked;

    IF pg_catalog.cardinality(locked_table_numbers) <> 30
       OR EXISTS (
           SELECT 1 FROM pg_catalog.unnest(locked_capacities) AS capacity WHERE capacity <= 0
       ) THEN
        RETURN QUERY SELECT
            'invalid_database_configuration'::text, 'restaurant_table_population'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_timezone_names
        WHERE name = configuration.restaurant_timezone
    ) THEN
        RETURN QUERY SELECT
            'invalid_database_configuration'::text, 'invalid_timezone'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    END IF;

    authoritative_now := pg_catalog.clock_timestamp();
    authoritative_local_now := authoritative_now AT TIME ZONE configuration.restaurant_timezone;

    SELECT
        pg_catalog.count(*),
        pg_catalog.min(candidate.starts_at),
        pg_catalog.min(candidate.utc_offset_minutes)
    INTO candidate_count, resolved_start, candidate_offset
    FROM cafe_fausse.local_timestamp_candidates(
        p_local_start,
        configuration.restaurant_timezone
    ) AS candidate;

    IF candidate_count = 0 THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'nonexistent_local_start'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    ELSIF candidate_count > 1 THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'ambiguous_local_start'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    ELSIF candidate_offset <> p_utc_offset_minutes THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'utc_offset_mismatch'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    END IF;

    resolved_end := resolved_start + pg_catalog.make_interval(
        mins => configuration.reservation_duration_minutes
    );

    SELECT hours.*
    INTO STRICT requested_hours
    FROM cafe_fausse.restaurant_operating_hours AS hours
    WHERE hours.weekday = EXTRACT(isodow FROM p_local_start)::smallint;

    IF p_local_start::date < authoritative_local_now::date
       OR p_local_start::date > authoritative_local_now::date + configuration.advance_booking_window_days THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'date_outside_booking_window'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    ELSIF p_local_start::date = authoritative_local_now::date
          AND resolved_start < authoritative_now + pg_catalog.make_interval(
              mins => configuration.same_day_lead_minutes
          ) THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'insufficient_same_day_lead'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    ELSIF p_local_start::time < requested_hours.opens_at THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'start_before_opening'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    ELSIF pg_catalog.mod(
              EXTRACT(
                  epoch FROM (
                      p_local_start - (p_local_start::date + requested_hours.opens_at)
                  )
              )::bigint,
              configuration.start_interval_minutes::bigint * 60
          ) <> 0 THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'misaligned_start'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    ELSIF (resolved_end AT TIME ZONE configuration.restaurant_timezone)::date
              <> p_local_start::date
          OR (resolved_end AT TIME ZONE configuration.restaurant_timezone)::time
              > requested_hours.closes_at THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'end_after_closing'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    ELSIF configuration.reservation_duration_minutes NOT IN (60, 90, 120)
          OR p_party_size < 1
          OR p_party_size > total_capacity THEN
        RETURN QUERY SELECT
            'invalid_request'::text, 'duration_or_party_size_out_of_range'::text,
            NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
            NULL::smallint[], NULL::boolean, FALSE, NULL::smallint, NULL::bytea;
        RETURN;
    END IF;

    BEGIN
        PERFORM pg_catalog.pg_advisory_xact_lock(
            1128678733,
            cafe_fausse.canonical_email_lock_key(p_email)
        );

        SELECT customer_row.*
        INTO customer
        FROM cafe_fausse.customers AS customer_row
        WHERE customer_row.email = p_email
        FOR UPDATE;

        IF NOT FOUND THEN
            BEGIN
                INSERT INTO cafe_fausse.customers (
                    first_name,
                    middle_initial,
                    last_name,
                    email,
                    phone,
                    newsletter_subscribed
                )
                VALUES (
                    p_first_name,
                    p_middle_initial,
                    p_last_name,
                    p_email,
                    p_phone,
                    FALSE
                )
                RETURNING * INTO customer;
                is_new_customer := true;
            EXCEPTION
                WHEN unique_violation THEN
                    SELECT customer_row.*
                    INTO customer
                    FROM cafe_fausse.customers AS customer_row
                    WHERE customer_row.email = p_email
                    FOR UPDATE;
                    IF NOT FOUND THEN
                        RAISE;
                    END IF;
                    is_new_customer := false;
            END;

            IF is_new_customer AND p_failure_stage = 'after_customer_insert' THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'P6691',
                    MESSAGE = 'cafe_fausse_injected_failure_after_customer_insert';
            END IF;
        END IF;

        IF pg_catalog.lower(customer.first_name) <> pg_catalog.lower(p_first_name)
           OR pg_catalog.lower(customer.last_name) <> pg_catalog.lower(p_last_name) THEN
            RETURN QUERY SELECT
                'customer_identity_mismatch'::text, NULL::text,
                NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
                NULL::smallint[], customer.newsletter_subscribed, FALSE,
                NULL::smallint, NULL::bytea;
            RETURN;
        END IF;

        IF customer.middle_initial IS NOT NULL
           AND p_middle_initial IS NOT NULL
           AND customer.middle_initial <> p_middle_initial THEN
            RETURN QUERY SELECT
                'middle_initial_conflict'::text, NULL::text,
                NULL::bigint, NULL::timestamptz, NULL::timestamptz, NULL::integer,
                NULL::smallint[], customer.newsletter_subscribed, FALSE,
                NULL::smallint, NULL::bytea;
            RETURN;
        END IF;

        populate_middle_initial :=
            NOT is_new_customer
            AND customer.middle_initial IS NULL
            AND p_middle_initial IS NOT NULL;

        IF p_phone IS NOT NULL THEN
            supplied_phone_digits := pg_catalog.regexp_replace(p_phone, '[^0-9]', '', 'g');
        END IF;

        IF customer.phone IS NOT NULL THEN
            stored_phone_digits := pg_catalog.regexp_replace(customer.phone, '[^0-9]', '', 'g');
        END IF;

        populate_phone :=
            NOT is_new_customer
            AND customer.phone IS NULL
            AND p_phone IS NOT NULL;
        differing_phone :=
            NOT is_new_customer
            AND customer.phone IS NOT NULL
            AND p_phone IS NOT NULL
            AND stored_phone_digits <> supplied_phone_digits;

        generated_fingerprint := cafe_fausse.reservation_fingerprint_v1(
            customer.customer_id,
            resolved_start,
            p_party_size
        );

        SELECT reservation_row.*
        INTO existing_reservation
        FROM cafe_fausse.reservations AS reservation_row
        WHERE reservation_row.fingerprint_version = 1
          AND reservation_row.reservation_fingerprint = generated_fingerprint
          AND reservation_row.customer_id = customer.customer_id
          AND reservation_row.starts_at = resolved_start
          AND reservation_row.party_size = p_party_size
        ORDER BY reservation_row.reservation_id
        LIMIT 1;

        IF NOT FOUND THEN
            SELECT reservation_row.*
            INTO existing_reservation
            FROM cafe_fausse.reservations AS reservation_row
            WHERE reservation_row.customer_id = customer.customer_id
              AND reservation_row.starts_at = resolved_start
              AND reservation_row.party_size = p_party_size;
        END IF;

        IF FOUND THEN
            SELECT pg_catalog.array_agg(assignment.table_number ORDER BY assignment.table_number)
            INTO selected_tables
            FROM cafe_fausse.reservation_table_assignments AS assignment
            WHERE assignment.reservation_id = existing_reservation.reservation_id;

            RETURN QUERY SELECT
                'exact_retry'::text, NULL::text,
                existing_reservation.reservation_id,
                existing_reservation.starts_at,
                existing_reservation.ends_at,
                existing_reservation.party_size,
                selected_tables,
                customer.newsletter_subscribed,
                FALSE,
                existing_reservation.fingerprint_version,
                existing_reservation.reservation_fingerprint;
            RETURN;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM cafe_fausse.reservations AS reservation_row
            WHERE reservation_row.customer_id = customer.customer_id
              AND reservation_row.starts_at < resolved_end
              AND resolved_start < reservation_row.ends_at
        ) THEN
            RETURN QUERY SELECT
                'same_customer_overlap'::text, NULL::text,
                NULL::bigint, resolved_start, resolved_end, p_party_size,
                NULL::smallint[], customer.newsletter_subscribed, FALSE,
                1::smallint, generated_fingerprint;
            RETURN;
        END IF;

        SELECT
            pg_catalog.array_agg(table_row.table_number ORDER BY table_row.table_number),
            pg_catalog.array_agg(table_row.seating_capacity ORDER BY table_row.table_number)
        INTO free_table_numbers, free_capacities
        FROM cafe_fausse.restaurant_tables AS table_row
        WHERE NOT EXISTS (
            SELECT 1
            FROM cafe_fausse.reservation_table_assignments AS assignment
            JOIN cafe_fausse.reservations AS reservation_row
              ON reservation_row.reservation_id = assignment.reservation_id
            WHERE assignment.table_number = table_row.table_number
              AND reservation_row.starts_at < resolved_end
              AND resolved_start < reservation_row.ends_at
        );

        SELECT
            allocation.table_numbers,
            allocation.total_capacity,
            allocation.tie_count,
            allocation.selected_rank
        INTO
            selected_tables,
            selected_capacity,
            allocation_tie_count,
            allocation_selected_rank
        FROM cafe_fausse.select_table_allocation(
            COALESCE(free_table_numbers, ARRAY[]::smallint[]),
            COALESCE(free_capacities, ARRAY[]::integer[]),
            p_party_size,
            p_tie_rank
        ) AS allocation;

        IF NOT FOUND THEN
            abort_outcome := 'unavailable';
            abort_detail := 'no_capacity_sufficient_combination';
            RAISE EXCEPTION USING ERRCODE = 'P6601', MESSAGE = abort_outcome;
        END IF;

        authoritative_now := pg_catalog.clock_timestamp();
        authoritative_local_now := authoritative_now AT TIME ZONE configuration.restaurant_timezone;
        IF p_local_start::date < authoritative_local_now::date
           OR p_local_start::date > authoritative_local_now::date + configuration.advance_booking_window_days
           OR (
               p_local_start::date = authoritative_local_now::date
               AND resolved_start < authoritative_now + pg_catalog.make_interval(
                   mins => configuration.same_day_lead_minutes
               )
           ) THEN
            abort_outcome := 'invalid_request';
            abort_detail := 'time_boundary_crossed_during_booking';
            RAISE EXCEPTION USING ERRCODE = 'P6601', MESSAGE = abort_outcome;
        END IF;

        IF populate_middle_initial OR populate_phone THEN
            UPDATE cafe_fausse.customers
            SET middle_initial = CASE
                    WHEN populate_middle_initial THEN p_middle_initial
                    ELSE middle_initial
                END,
                phone = CASE
                    WHEN populate_phone THEN p_phone
                    ELSE phone
                END
            WHERE customer_id = customer.customer_id
            RETURNING * INTO customer;

            IF p_failure_stage = 'after_optional_field_population' THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'P6692',
                    MESSAGE = 'cafe_fausse_injected_failure_after_optional_field_population';
            END IF;
        END IF;

        IF p_newsletter_action <> 'no_change' THEN
            UPDATE cafe_fausse.customers
            SET newsletter_subscribed = (p_newsletter_action = 'subscribe')
            WHERE customer_id = customer.customer_id
            RETURNING * INTO customer;

            IF p_failure_stage = 'after_newsletter_update' THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'P6693',
                    MESSAGE = 'cafe_fausse_injected_failure_after_newsletter_update';
            END IF;
        END IF;

        BEGIN
            INSERT INTO cafe_fausse.reservations (
                customer_id,
                starts_at,
                ends_at,
                party_size,
                fingerprint_version,
                reservation_fingerprint
            )
            VALUES (
                customer.customer_id,
                resolved_start,
                resolved_end,
                p_party_size,
                1,
                generated_fingerprint
            )
            RETURNING cafe_fausse.reservations.reservation_id
            INTO inserted_reservation_id;
        EXCEPTION
            WHEN unique_violation THEN
                RAISE EXCEPTION USING
                    ERRCODE = '40001',
                    MESSAGE = 'cafe_fausse_exact_identity_race_retry';
        END;

        IF p_failure_stage = 'after_reservation_insert' THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P6694',
                MESSAGE = 'cafe_fausse_injected_failure_after_reservation_insert';
        END IF;

        assigned_count := 0;
        FOREACH assignment_table IN ARRAY selected_tables LOOP
            INSERT INTO cafe_fausse.reservation_table_assignments (
                reservation_id,
                table_number
            )
            VALUES (inserted_reservation_id, assignment_table);
            assigned_count := assigned_count + 1;

            IF assigned_count = 1
               AND p_failure_stage = 'after_partial_assignment_insert' THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'P6695',
                    MESSAGE = 'cafe_fausse_injected_failure_after_partial_assignment_insert';
            END IF;
        END LOOP;

        SELECT
            pg_catalog.count(*)::integer,
            pg_catalog.sum(table_row.seating_capacity)::integer
        INTO assigned_count, assigned_capacity
        FROM cafe_fausse.reservation_table_assignments AS assignment
        JOIN cafe_fausse.restaurant_tables AS table_row
          ON table_row.table_number = assignment.table_number
        WHERE assignment.reservation_id = inserted_reservation_id;

        IF assigned_count <> pg_catalog.cardinality(selected_tables)
           OR assigned_count < 1
           OR assigned_capacity < p_party_size
           OR selected_capacity <> assigned_capacity
           OR EXISTS (
               SELECT 1
               FROM cafe_fausse.reservation_table_assignments AS assignment
               JOIN cafe_fausse.reservations AS reservation_row
                 ON reservation_row.reservation_id = assignment.reservation_id
               WHERE assignment.table_number = ANY(selected_tables)
                 AND reservation_row.reservation_id <> inserted_reservation_id
                 AND reservation_row.starts_at < resolved_end
                 AND resolved_start < reservation_row.ends_at
           )
           OR EXISTS (
               SELECT 1
               FROM cafe_fausse.reservations AS reservation_row
               WHERE reservation_row.customer_id = customer.customer_id
                 AND reservation_row.reservation_id <> inserted_reservation_id
                 AND reservation_row.starts_at < resolved_end
                 AND resolved_start < reservation_row.ends_at
           )
           OR NOT EXISTS (
               SELECT 1
               FROM cafe_fausse.reservations AS reservation_row
               WHERE reservation_row.reservation_id = inserted_reservation_id
                 AND reservation_row.fingerprint_version = 1
                 AND reservation_row.reservation_fingerprint = cafe_fausse.reservation_fingerprint_v1(
                     customer.customer_id,
                     resolved_start,
                     p_party_size
                 )
           ) THEN
            RAISE EXCEPTION USING
                ERRCODE = 'P6502',
                MESSAGE = 'cafe_fausse_booking_postcondition_failed';
        END IF;

        RETURN QUERY SELECT
            CASE WHEN differing_phone THEN 'booked_phone_notice' ELSE 'booked' END::text,
            NULL::text,
            inserted_reservation_id,
            resolved_start,
            resolved_end,
            p_party_size,
            selected_tables,
            customer.newsletter_subscribed,
            differing_phone,
            1::smallint,
            generated_fingerprint;
        RETURN;
    EXCEPTION
        WHEN SQLSTATE 'P6601' THEN
            RETURN QUERY SELECT
                abort_outcome,
                abort_detail,
                NULL::bigint,
                resolved_start,
                resolved_end,
                p_party_size,
                NULL::smallint[],
                NULL::boolean,
                FALSE,
                1::smallint,
                generated_fingerprint;
            RETURN;
    END;
END
$function$;

CREATE FUNCTION cafe_fausse.book_reservation(
    p_first_name text,
    p_middle_initial text,
    p_last_name text,
    p_email text,
    p_phone text,
    p_local_start timestamp without time zone,
    p_utc_offset_minutes smallint,
    p_party_size integer,
    p_newsletter_action text
)
RETURNS TABLE (
    outcome text,
    detail_code text,
    reservation_id bigint,
    starts_at timestamp with time zone,
    ends_at timestamp with time zone,
    party_size integer,
    assigned_table_numbers smallint[],
    newsletter_subscribed boolean,
    phone_notice boolean,
    fingerprint_version smallint,
    reservation_fingerprint bytea
)
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
    SELECT *
    FROM cafe_fausse.book_reservation_core(
        p_first_name,
        p_middle_initial,
        p_last_name,
        p_email,
        p_phone,
        p_local_start,
        p_utc_offset_minutes,
        p_party_size,
        p_newsletter_action,
        NULL,
        NULL
    );
$function$;

CREATE FUNCTION cafe_fausse.book_reservation_test(
    p_first_name text,
    p_middle_initial text,
    p_last_name text,
    p_email text,
    p_phone text,
    p_local_start timestamp without time zone,
    p_utc_offset_minutes smallint,
    p_party_size integer,
    p_newsletter_action text,
    p_tie_rank bigint,
    p_failure_stage text
)
RETURNS TABLE (
    outcome text,
    detail_code text,
    reservation_id bigint,
    starts_at timestamp with time zone,
    ends_at timestamp with time zone,
    party_size integer,
    assigned_table_numbers smallint[],
    newsletter_subscribed boolean,
    phone_notice boolean,
    fingerprint_version smallint,
    reservation_fingerprint bytea
)
LANGUAGE sql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
    SELECT *
    FROM cafe_fausse.book_reservation_core(
        p_first_name,
        p_middle_initial,
        p_last_name,
        p_email,
        p_phone,
        p_local_start,
        p_utc_offset_minutes,
        p_party_size,
        p_newsletter_action,
        p_tie_rank,
        p_failure_stage
    );
$function$;

REVOKE ALL ON FUNCTION cafe_fausse.book_reservation_core(text, text, text, text, text, timestamp without time zone, smallint, integer, text, bigint, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.book_reservation(text, text, text, text, text, timestamp without time zone, smallint, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.book_reservation_test(text, text, text, text, text, timestamp without time zone, smallint, integer, text, bigint, text) FROM PUBLIC;

COMMIT;
