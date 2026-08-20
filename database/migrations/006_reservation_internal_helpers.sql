\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE FUNCTION cafe_fausse.sha256_text(value text)
RETURNS bytea
LANGUAGE plpgsql
IMMUTABLE
STRICT
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    extension_schema name;
    digest_value bytea;
BEGIN
    SELECT namespace.nspname
    INTO extension_schema
    FROM pg_catalog.pg_extension AS extension
    JOIN pg_catalog.pg_namespace AS namespace
      ON namespace.oid = extension.extnamespace
    WHERE extension.extname = 'pgcrypto';

    IF extension_schema IS NULL THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P6501',
            MESSAGE = 'cafe_fausse_invalid_database_configuration',
            DETAIL = 'pgcrypto is not installed';
    END IF;

    EXECUTE pg_catalog.format(
        'SELECT %I.digest(pg_catalog.convert_to($1, ''UTF8''), ''sha256'')',
        extension_schema
    )
    INTO digest_value
    USING value;

    IF pg_catalog.octet_length(digest_value) <> 32 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P6501',
            MESSAGE = 'cafe_fausse_invalid_database_configuration',
            DETAIL = 'pgcrypto SHA-256 did not return 32 bytes';
    END IF;

    RETURN digest_value;
END
$function$;

CREATE FUNCTION cafe_fausse.reservation_fingerprint_serialization_v1(
    p_customer_id bigint,
    p_starts_at timestamp with time zone,
    p_party_size integer
)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
STRICT
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    customer_value text;
    start_value text;
    party_value text;
BEGIN
    IF p_customer_id <= 0 OR p_party_size <= 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'fingerprint inputs must be positive';
    END IF;

    customer_value := p_customer_id::text;
    start_value := pg_catalog.to_char(
        p_starts_at AT TIME ZONE 'UTC',
        'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
    );
    party_value := p_party_size::text;

    RETURN pg_catalog.octet_length(pg_catalog.convert_to(customer_value, 'UTF8'))::text
        || ':' || customer_value
        || '|' || pg_catalog.octet_length(pg_catalog.convert_to(start_value, 'UTF8'))::text
        || ':' || start_value
        || '|' || pg_catalog.octet_length(pg_catalog.convert_to(party_value, 'UTF8'))::text
        || ':' || party_value;
END
$function$;

CREATE FUNCTION cafe_fausse.reservation_fingerprint_v1(
    p_customer_id bigint,
    p_starts_at timestamp with time zone,
    p_party_size integer
)
RETURNS bytea
LANGUAGE sql
IMMUTABLE
STRICT
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
    SELECT cafe_fausse.sha256_text(
        cafe_fausse.reservation_fingerprint_serialization_v1(
            p_customer_id,
            p_starts_at,
            p_party_size
        )
    );
$function$;

CREATE FUNCTION cafe_fausse.canonical_email_lock_key(p_email text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
STRICT
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    digest_value bytea;
    unsigned_value bigint;
BEGIN
    IF p_email = ''
       OR p_email <> pg_catalog.btrim(p_email)
       OR p_email <> pg_catalog.lower(p_email) THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'canonical email lock input must be nonempty, trimmed, and lowercase';
    END IF;

    digest_value := cafe_fausse.sha256_text(p_email);
    unsigned_value :=
          pg_catalog.get_byte(digest_value, 0)::bigint * 16777216
        + pg_catalog.get_byte(digest_value, 1)::bigint * 65536
        + pg_catalog.get_byte(digest_value, 2)::bigint * 256
        + pg_catalog.get_byte(digest_value, 3)::bigint;

    IF unsigned_value >= 2147483648 THEN
        RETURN (unsigned_value - 4294967296)::integer;
    END IF;

    RETURN unsigned_value::integer;
END
$function$;

CREATE FUNCTION cafe_fausse.local_timestamp_candidates(
    p_local_start timestamp without time zone,
    p_timezone text
)
RETURNS TABLE (
    starts_at timestamp with time zone,
    utc_offset_minutes integer
)
LANGUAGE sql
STABLE
STRICT
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
    WITH sampled_local(sample_value) AS (
        VALUES
            (p_local_start - INTERVAL '2 days'),
            (p_local_start),
            (p_local_start + INTERVAL '2 days')
    ),
    sampled_offsets(utc_offset_minutes) AS (
        SELECT DISTINCT pg_catalog.round(
            EXTRACT(
                epoch FROM (
                    sample_value
                    - ((sample_value AT TIME ZONE p_timezone) AT TIME ZONE 'UTC')
                )
            ) / 60.0
        )::integer
        FROM sampled_local
    ),
    candidates(starts_at, utc_offset_minutes) AS (
        SELECT
            (
                p_local_start
                - pg_catalog.make_interval(mins => utc_offset_minutes)
            ) AT TIME ZONE 'UTC',
            utc_offset_minutes
        FROM sampled_offsets
    )
    SELECT DISTINCT candidate.starts_at, candidate.utc_offset_minutes
    FROM candidates AS candidate
    WHERE candidate.starts_at AT TIME ZONE p_timezone = p_local_start
    ORDER BY candidate.starts_at;
$function$;

CREATE FUNCTION cafe_fausse.select_table_allocation(
    p_table_numbers smallint[],
    p_capacities integer[],
    p_party_size integer,
    p_tie_rank bigint DEFAULT NULL
)
RETURNS TABLE (
    table_numbers smallint[],
    total_capacity integer,
    tie_count bigint,
    selected_rank bigint
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, cafe_fausse
AS $function$
DECLARE
    table_count integer;
    left_count integer;
    right_count integer;
    index_value integer;
    candidate_table_count integer;
    best_table_count integer;
    best_capacity integer;
    best_tie_count bigint;
    chosen_rank bigint;
    remaining_rank bigint;
    candidate record;
    right_tables smallint[];
    winner smallint[];
BEGIN
    table_count := COALESCE(pg_catalog.array_length(p_table_numbers, 1), 0);

    IF table_count <> COALESCE(pg_catalog.array_length(p_capacities, 1), 0)
       OR table_count > 30
       OR p_party_size <= 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'invalid allocation input';
    END IF;

    IF table_count = 0 THEN
        RETURN;
    END IF;

    FOR index_value IN 1..table_count LOOP
        IF p_table_numbers[index_value] <= 0
           OR p_capacities[index_value] <= 0
           OR (
               index_value > 1
               AND p_table_numbers[index_value] <= p_table_numbers[index_value - 1]
           ) THEN
            RAISE EXCEPTION USING
                ERRCODE = '22023',
                MESSAGE = 'allocation tables must be positive, unique, and ascending';
        END IF;
    END LOOP;

    IF (SELECT pg_catalog.sum(capacity) FROM pg_catalog.unnest(p_capacities) AS capacity)
       < p_party_size THEN
        RETURN;
    END IF;

    left_count := table_count / 2;
    right_count := table_count - left_count;

    CREATE TEMPORARY TABLE IF NOT EXISTS pg_temp.cafe_fausse_left_subsets (
        subset_mask integer PRIMARY KEY,
        table_count smallint NOT NULL,
        capacity_sum integer NOT NULL,
        table_numbers smallint[] NOT NULL
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE IF NOT EXISTS pg_temp.cafe_fausse_right_subsets (
        subset_mask integer PRIMARY KEY,
        table_count smallint NOT NULL,
        capacity_sum integer NOT NULL,
        table_numbers smallint[] NOT NULL
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE IF NOT EXISTS pg_temp.cafe_fausse_right_groups (
        table_count smallint NOT NULL,
        capacity_sum integer NOT NULL,
        subset_count bigint NOT NULL,
        PRIMARY KEY (table_count, capacity_sum)
    ) ON COMMIT DROP;

    TRUNCATE TABLE
        pg_temp.cafe_fausse_left_subsets,
        pg_temp.cafe_fausse_right_subsets,
        pg_temp.cafe_fausse_right_groups;

    INSERT INTO pg_temp.cafe_fausse_left_subsets (
        subset_mask,
        table_count,
        capacity_sum,
        table_numbers
    )
    SELECT
        mask,
        (
            SELECT pg_catalog.count(*)::smallint
            FROM pg_catalog.generate_series(1, left_count) AS position
            WHERE (mask & (1 << (position - 1))) <> 0
        ),
        COALESCE((
            SELECT pg_catalog.sum(p_capacities[position])::integer
            FROM pg_catalog.generate_series(1, left_count) AS position
            WHERE (mask & (1 << (position - 1))) <> 0
        ), 0),
        COALESCE((
            SELECT pg_catalog.array_agg(p_table_numbers[position] ORDER BY p_table_numbers[position])
            FROM pg_catalog.generate_series(1, left_count) AS position
            WHERE (mask & (1 << (position - 1))) <> 0
        ), ARRAY[]::smallint[])
    FROM pg_catalog.generate_series(0, (1 << left_count) - 1) AS mask;

    INSERT INTO pg_temp.cafe_fausse_right_subsets (
        subset_mask,
        table_count,
        capacity_sum,
        table_numbers
    )
    SELECT
        mask,
        (
            SELECT pg_catalog.count(*)::smallint
            FROM pg_catalog.generate_series(1, right_count) AS relative_position
            WHERE (mask & (1 << (relative_position - 1))) <> 0
        ),
        COALESCE((
            SELECT pg_catalog.sum(p_capacities[left_count + relative_position])::integer
            FROM pg_catalog.generate_series(1, right_count) AS relative_position
            WHERE (mask & (1 << (relative_position - 1))) <> 0
        ), 0),
        COALESCE((
            SELECT pg_catalog.array_agg(
                p_table_numbers[left_count + relative_position]
                ORDER BY p_table_numbers[left_count + relative_position]
            )
            FROM pg_catalog.generate_series(1, right_count) AS relative_position
            WHERE (mask & (1 << (relative_position - 1))) <> 0
        ), ARRAY[]::smallint[])
    FROM pg_catalog.generate_series(0, (1 << right_count) - 1) AS mask;

    INSERT INTO pg_temp.cafe_fausse_right_groups (
        table_count,
        capacity_sum,
        subset_count
    )
    SELECT
        right_subset.table_count,
        right_subset.capacity_sum,
        pg_catalog.count(*)
    FROM pg_temp.cafe_fausse_right_subsets AS right_subset
    GROUP BY right_subset.table_count, right_subset.capacity_sum;

    FOR candidate_table_count IN 1..table_count LOOP
        IF EXISTS (
            SELECT 1
            FROM pg_temp.cafe_fausse_left_subsets AS left_subset
            WHERE left_subset.table_count <= candidate_table_count
              AND EXISTS (
                  SELECT 1
                  FROM pg_temp.cafe_fausse_right_groups AS right_group
                  WHERE right_group.table_count = candidate_table_count - left_subset.table_count
                    AND right_group.capacity_sum >= p_party_size - left_subset.capacity_sum
              )
        ) THEN
            best_table_count := candidate_table_count;
            EXIT;
        END IF;
    END LOOP;

    SELECT pg_catalog.min(left_subset.capacity_sum + right_choice.capacity_sum)
    INTO best_capacity
    FROM pg_temp.cafe_fausse_left_subsets AS left_subset
    JOIN LATERAL (
        SELECT right_group.capacity_sum
        FROM pg_temp.cafe_fausse_right_groups AS right_group
        WHERE right_group.table_count = best_table_count - left_subset.table_count
          AND right_group.capacity_sum >= p_party_size - left_subset.capacity_sum
        ORDER BY right_group.capacity_sum
        LIMIT 1
    ) AS right_choice ON true;

    SELECT pg_catalog.sum(right_group.subset_count)
    INTO best_tie_count
    FROM pg_temp.cafe_fausse_left_subsets AS left_subset
    JOIN pg_temp.cafe_fausse_right_groups AS right_group
      ON right_group.table_count = best_table_count - left_subset.table_count
     AND left_subset.capacity_sum + right_group.capacity_sum = best_capacity;

    IF best_tie_count IS NULL OR best_tie_count <= 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P6502',
            MESSAGE = 'allocation invariant failed';
    END IF;

    IF p_tie_rank IS NULL THEN
        chosen_rank := pg_catalog.floor(pg_catalog.random() * best_tie_count)::bigint + 1;
    ELSE
        chosen_rank := p_tie_rank;
    END IF;

    IF chosen_rank < 1 OR chosen_rank > best_tie_count THEN
        RAISE EXCEPTION USING
            ERRCODE = '22023',
            MESSAGE = 'allocation tie rank is out of range';
    END IF;

    remaining_rank := chosen_rank;
    FOR candidate IN
        SELECT
            left_subset.table_numbers AS left_tables,
            left_subset.table_count AS left_table_count,
            left_subset.capacity_sum AS left_capacity,
            right_group.table_count AS right_table_count,
            right_group.capacity_sum AS right_capacity,
            right_group.subset_count
        FROM pg_temp.cafe_fausse_left_subsets AS left_subset
        JOIN pg_temp.cafe_fausse_right_groups AS right_group
          ON right_group.table_count = best_table_count - left_subset.table_count
         AND left_subset.capacity_sum + right_group.capacity_sum = best_capacity
        ORDER BY left_subset.table_numbers, right_group.capacity_sum
    LOOP
        IF remaining_rank > candidate.subset_count THEN
            remaining_rank := remaining_rank - candidate.subset_count;
            CONTINUE;
        END IF;

        SELECT right_subset.table_numbers
        INTO right_tables
        FROM pg_temp.cafe_fausse_right_subsets AS right_subset
        WHERE right_subset.table_count = candidate.right_table_count
          AND right_subset.capacity_sum = candidate.right_capacity
        ORDER BY right_subset.table_numbers
        OFFSET (remaining_rank - 1)
        LIMIT 1;

        winner := candidate.left_tables || right_tables;
        EXIT;
    END LOOP;

    IF winner IS NULL OR pg_catalog.cardinality(winner) <> best_table_count THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P6502',
            MESSAGE = 'allocation reconstruction invariant failed';
    END IF;

    RETURN QUERY
    SELECT winner, best_capacity, best_tie_count, chosen_rank;
END
$function$;

REVOKE ALL ON FUNCTION cafe_fausse.sha256_text(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.reservation_fingerprint_serialization_v1(bigint, timestamp with time zone, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.reservation_fingerprint_v1(bigint, timestamp with time zone, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.canonical_email_lock_key(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.local_timestamp_candidates(timestamp without time zone, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION cafe_fausse.select_table_allocation(smallint[], integer[], integer, bigint) FROM PUBLIC;

COMMIT;
