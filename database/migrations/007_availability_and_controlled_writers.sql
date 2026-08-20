\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE FUNCTION cafe_fausse.provisional_availability(
    p_local_date date,
    p_party_size integer
)
RETURNS TABLE (
    outcome text,
    detail_code text,
    local_start timestamp without time zone,
    starts_at timestamp with time zone,
    ends_at timestamp with time zone,
    available boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    configuration cafe_fausse.reservation_configuration%ROWTYPE;
    opening_time time without time zone;
    closing_time time without time zone;
    current_instant timestamp with time zone := pg_catalog.statement_timestamp();
    current_local timestamp without time zone;
    requested_weekday smallint;
    total_capacity integer;
    slot_local timestamp without time zone;
    slot_start timestamp with time zone;
    slot_end timestamp with time zone;
    candidate_count integer;
    free_capacity integer;
BEGIN
    IF (SELECT pg_catalog.count(*) FROM cafe_fausse.reservation_configuration) <> 1
       OR (SELECT pg_catalog.count(*) FROM cafe_fausse.restaurant_operating_hours) <> 7
       OR (SELECT pg_catalog.array_agg(weekday ORDER BY weekday)
           FROM cafe_fausse.restaurant_operating_hours) <> ARRAY[1,2,3,4,5,6,7]::smallint[]
       OR (SELECT pg_catalog.count(*) FROM cafe_fausse.restaurant_tables) <> 30
       OR EXISTS (
           SELECT 1 FROM cafe_fausse.restaurant_tables WHERE seating_capacity <= 0
       ) THEN
        RETURN QUERY SELECT
            'invalid_database_configuration'::text,
            'incomplete_foundation_population'::text,
            NULL::timestamp,
            NULL::timestamptz,
            NULL::timestamptz,
            NULL::boolean;
        RETURN;
    END IF;

    SELECT *
    INTO STRICT configuration
    FROM cafe_fausse.reservation_configuration
    WHERE configuration_id = 1;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_timezone_names
        WHERE name = configuration.restaurant_timezone
    ) THEN
        RETURN QUERY SELECT
            'invalid_database_configuration'::text,
            'invalid_timezone'::text,
            NULL::timestamp,
            NULL::timestamptz,
            NULL::timestamptz,
            NULL::boolean;
        RETURN;
    END IF;

    current_local := current_instant AT TIME ZONE configuration.restaurant_timezone;
    SELECT pg_catalog.sum(seating_capacity)
    INTO total_capacity
    FROM cafe_fausse.restaurant_tables;

    IF p_local_date IS NULL
       OR p_local_date < current_local::date
       OR p_local_date > current_local::date + configuration.advance_booking_window_days
       OR p_party_size IS NULL
       OR p_party_size < 1
       OR p_party_size > total_capacity THEN
        RETURN QUERY SELECT
            'invalid_request'::text,
            'date_or_party_size_out_of_range'::text,
            NULL::timestamp,
            NULL::timestamptz,
            NULL::timestamptz,
            NULL::boolean;
        RETURN;
    END IF;

    requested_weekday := EXTRACT(isodow FROM p_local_date)::smallint;
    SELECT hours.opens_at, hours.closes_at
    INTO STRICT opening_time, closing_time
    FROM cafe_fausse.restaurant_operating_hours AS hours
    WHERE hours.weekday = requested_weekday;

    slot_local := p_local_date + opening_time;
    WHILE slot_local + pg_catalog.make_interval(
        mins => configuration.reservation_duration_minutes
    ) <= p_local_date + closing_time LOOP
        SELECT pg_catalog.count(*), pg_catalog.min(candidate.starts_at)
        INTO candidate_count, slot_start
        FROM cafe_fausse.local_timestamp_candidates(
            slot_local,
            configuration.restaurant_timezone
        ) AS candidate;

        IF candidate_count = 1 THEN
            slot_end := slot_start + pg_catalog.make_interval(
                mins => configuration.reservation_duration_minutes
            );

            SELECT COALESCE(pg_catalog.sum(table_row.seating_capacity), 0)
            INTO free_capacity
            FROM cafe_fausse.restaurant_tables AS table_row
            WHERE NOT EXISTS (
                SELECT 1
                FROM cafe_fausse.reservation_table_assignments AS assignment
                JOIN cafe_fausse.reservations AS reservation
                  ON reservation.reservation_id = assignment.reservation_id
                WHERE assignment.table_number = table_row.table_number
                  AND reservation.starts_at < slot_end
                  AND slot_start < reservation.ends_at
            );

            RETURN QUERY SELECT
                'slots'::text,
                NULL::text,
                slot_local,
                slot_start,
                slot_end,
                (
                    free_capacity >= p_party_size
                    AND (
                        p_local_date <> current_local::date
                        OR slot_start >= current_instant + pg_catalog.make_interval(
                            mins => configuration.same_day_lead_minutes
                        )
                    )
                );
        END IF;

        slot_local := slot_local + pg_catalog.make_interval(
            mins => configuration.start_interval_minutes
        );
    END LOOP;
END
$function$;

CREATE FUNCTION cafe_fausse.set_newsletter_preference(
    p_first_name text,
    p_middle_initial text,
    p_last_name text,
    p_email text,
    p_subscribed boolean
)
RETURNS TABLE (
    outcome text,
    newsletter_subscribed boolean
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    customer cafe_fausse.customers%ROWTYPE;
    customer_found boolean := false;
BEGIN
    PERFORM pg_catalog.set_config('lock_timeout', '3s', true);
    PERFORM pg_catalog.set_config('statement_timeout', '15s', true);

    IF p_first_name IS NULL
       OR p_last_name IS NULL
       OR p_email IS NULL
       OR p_subscribed IS NULL
       OR pg_catalog.char_length(p_first_name) NOT BETWEEN 1 AND 100
       OR pg_catalog.char_length(p_last_name) NOT BETWEEN 1 AND 100
       OR p_first_name <> pg_catalog.regexp_replace(pg_catalog.btrim(p_first_name), '[[:space:]]+', ' ', 'g')
       OR p_last_name <> pg_catalog.regexp_replace(pg_catalog.btrim(p_last_name), '[[:space:]]+', ' ', 'g')
       OR p_email = ''
       OR p_email <> pg_catalog.btrim(p_email)
       OR p_email <> pg_catalog.lower(p_email)
       OR pg_catalog.char_length(p_email) > 254
       OR (p_middle_initial IS NOT NULL AND p_middle_initial !~ '^[[:upper:]]$') THEN
        RETURN QUERY SELECT 'invalid_request'::text, NULL::boolean;
        RETURN;
    END IF;

    PERFORM pg_catalog.pg_advisory_xact_lock(
        1128678733,
        cafe_fausse.canonical_email_lock_key(p_email)
    );

    SELECT *
    INTO customer
    FROM cafe_fausse.customers
    WHERE email = p_email
    FOR UPDATE;
    customer_found := FOUND;

    IF NOT customer_found AND NOT p_subscribed THEN
        RETURN QUERY SELECT 'no_customer_no_change'::text, FALSE;
        RETURN;
    END IF;

    IF NOT customer_found THEN
        BEGIN
            INSERT INTO cafe_fausse.customers (
                first_name,
                middle_initial,
                last_name,
                email,
                newsletter_subscribed
            )
            VALUES (
                p_first_name,
                p_middle_initial,
                p_last_name,
                p_email,
                TRUE
            )
            RETURNING * INTO customer;
        EXCEPTION
            WHEN unique_violation THEN
                SELECT *
                INTO customer
                FROM cafe_fausse.customers
                WHERE email = p_email
                FOR UPDATE;
                IF NOT FOUND THEN
                    RAISE;
                END IF;
        END;
    END IF;

    IF pg_catalog.lower(customer.first_name) <> pg_catalog.lower(p_first_name)
       OR pg_catalog.lower(customer.last_name) <> pg_catalog.lower(p_last_name) THEN
        RETURN QUERY SELECT 'customer_identity_mismatch'::text, customer.newsletter_subscribed;
        RETURN;
    END IF;

    IF customer.middle_initial IS NOT NULL
       AND p_middle_initial IS NOT NULL
       AND customer.middle_initial <> p_middle_initial THEN
        RETURN QUERY SELECT 'middle_initial_conflict'::text, customer.newsletter_subscribed;
        RETURN;
    END IF;

    UPDATE cafe_fausse.customers
    SET newsletter_subscribed = p_subscribed
    WHERE customer_id = customer.customer_id
    RETURNING * INTO customer;

    RETURN QUERY SELECT
        CASE WHEN p_subscribed THEN 'subscribed' ELSE 'unsubscribed' END::text,
        customer.newsletter_subscribed;
END
$function$;

CREATE FUNCTION cafe_fausse.set_reservation_configuration(
    p_start_interval_minutes smallint,
    p_reservation_duration_minutes smallint,
    p_advance_booking_window_days smallint,
    p_same_day_lead_minutes smallint,
    p_restaurant_timezone text
)
RETURNS cafe_fausse.reservation_configuration
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    updated_row cafe_fausse.reservation_configuration%ROWTYPE;
BEGIN
    PERFORM pg_catalog.set_config('lock_timeout', '3s', true);
    PERFORM pg_catalog.set_config('statement_timeout', '15s', true);
    PERFORM pg_catalog.pg_advisory_xact_lock(1128682322, 1);

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_timezone_names WHERE name = p_restaurant_timezone
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'restaurant timezone is not supported by PostgreSQL';
    END IF;

    SELECT *
    INTO STRICT updated_row
    FROM cafe_fausse.reservation_configuration
    WHERE configuration_id = 1
    FOR UPDATE;

    UPDATE cafe_fausse.reservation_configuration
    SET start_interval_minutes = p_start_interval_minutes,
        reservation_duration_minutes = p_reservation_duration_minutes,
        advance_booking_window_days = p_advance_booking_window_days,
        same_day_lead_minutes = p_same_day_lead_minutes,
        restaurant_timezone = p_restaurant_timezone
    WHERE configuration_id = 1
    RETURNING * INTO updated_row;

    RETURN updated_row;
END
$function$;

CREATE FUNCTION cafe_fausse.set_restaurant_operating_hours(
    p_weekday smallint,
    p_opens_at time without time zone,
    p_closes_at time without time zone
)
RETURNS cafe_fausse.restaurant_operating_hours
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    updated_row cafe_fausse.restaurant_operating_hours%ROWTYPE;
BEGIN
    PERFORM pg_catalog.set_config('lock_timeout', '3s', true);
    PERFORM pg_catalog.set_config('statement_timeout', '15s', true);
    PERFORM pg_catalog.pg_advisory_xact_lock(1128682322, 1);

    PERFORM 1
    FROM cafe_fausse.restaurant_operating_hours
    ORDER BY weekday
    FOR UPDATE;

    UPDATE cafe_fausse.restaurant_operating_hours
    SET opens_at = p_opens_at,
        closes_at = p_closes_at
    WHERE weekday = p_weekday
    RETURNING * INTO STRICT updated_row;

    RETURN updated_row;
END
$function$;

CREATE FUNCTION cafe_fausse.set_restaurant_table_capacity(
    p_table_number smallint,
    p_seating_capacity integer
)
RETURNS cafe_fausse.restaurant_tables
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    updated_row cafe_fausse.restaurant_tables%ROWTYPE;
BEGIN
    PERFORM pg_catalog.set_config('lock_timeout', '3s', true);
    PERFORM pg_catalog.set_config('statement_timeout', '15s', true);
    PERFORM pg_catalog.pg_advisory_xact_lock(1128682322, 1);

    PERFORM 1
    FROM cafe_fausse.restaurant_tables
    ORDER BY table_number
    FOR UPDATE;

    UPDATE cafe_fausse.restaurant_tables
    SET seating_capacity = p_seating_capacity
    WHERE table_number = p_table_number
    RETURNING * INTO STRICT updated_row;

    RETURN updated_row;
END
$function$;

REVOKE ALL ON FUNCTION cafe_fausse.provisional_availability(date, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.set_newsletter_preference(text, text, text, text, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.set_reservation_configuration(smallint, smallint, smallint, smallint, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.set_restaurant_operating_hours(smallint, time without time zone, time without time zone) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.set_restaurant_table_capacity(smallint, integer) FROM PUBLIC;

COMMIT;
