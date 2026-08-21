\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE OR REPLACE FUNCTION cafe_fausse.select_table_allocation(
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
    available_capacity integer;
    single_best_capacity integer;
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
        RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'invalid allocation input';
    END IF;
    IF table_count = 0 THEN RETURN; END IF;

    FOR index_value IN 1..table_count LOOP
        IF p_table_numbers[index_value] <= 0
           OR p_capacities[index_value] <= 0
           OR (index_value > 1 AND p_table_numbers[index_value] <= p_table_numbers[index_value - 1]) THEN
            RAISE EXCEPTION USING
                ERRCODE = '22023',
                MESSAGE = 'allocation tables must be positive, unique, and ascending';
        END IF;
    END LOOP;

    SELECT pg_catalog.sum(capacity), pg_catalog.min(capacity) FILTER (WHERE capacity >= p_party_size)
    INTO available_capacity, single_best_capacity
    FROM pg_catalog.unnest(p_capacities) AS capacity;
    IF available_capacity < p_party_size THEN RETURN; END IF;

    -- Exact fast path 1: any sufficient single table is necessarily the
    -- minimum-table solution; minimum capacity is exactly least waste.
    IF single_best_capacity IS NOT NULL THEN
        SELECT pg_catalog.count(*)
        INTO best_tie_count
        FROM pg_catalog.unnest(p_capacities) AS capacity
        WHERE capacity = single_best_capacity;
        chosen_rank := COALESCE(
            p_tie_rank,
            pg_catalog.floor(pg_catalog.random() * best_tie_count)::bigint + 1
        );
        IF chosen_rank < 1 OR chosen_rank > best_tie_count THEN
            RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'allocation tie rank is out of range';
        END IF;
        SELECT ARRAY[p_table_numbers[array_position.position]]
        INTO winner
        FROM pg_catalog.generate_subscripts(p_table_numbers, 1)
             AS array_position(position)
        WHERE p_capacities[array_position.position] = single_best_capacity
        -- Preserve the approved general-path deterministic rank ordering:
        -- right-half singleton subsets precede left-half singleton subsets.
        ORDER BY
            CASE WHEN array_position.position > table_count / 2 THEN 0 ELSE 1 END,
            p_table_numbers[array_position.position]
        OFFSET (chosen_rank - 1) LIMIT 1;
        RETURN QUERY SELECT winner, single_best_capacity, best_tie_count, chosen_rank;
        RETURN;
    END IF;

    -- Exact fast path 2: with positive capacities, total capacity equal to the
    -- party size proves that every table is required and the winner is unique.
    IF available_capacity = p_party_size THEN
        IF p_tie_rank IS NOT NULL AND p_tie_rank <> 1 THEN
            RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'allocation tie rank is out of range';
        END IF;
        RETURN QUERY SELECT p_table_numbers, available_capacity, 1::bigint, 1::bigint;
        RETURN;
    END IF;

    -- General approved meet-in-the-middle path.
    left_count := table_count / 2;
    right_count := table_count - left_count;
    CREATE TEMPORARY TABLE IF NOT EXISTS pg_temp.cafe_fausse_left_subsets (
        subset_mask integer PRIMARY KEY, table_count smallint NOT NULL,
        capacity_sum integer NOT NULL, table_numbers smallint[] NOT NULL
    ) ON COMMIT DROP;
    CREATE TEMPORARY TABLE IF NOT EXISTS pg_temp.cafe_fausse_right_subsets (
        subset_mask integer PRIMARY KEY, table_count smallint NOT NULL,
        capacity_sum integer NOT NULL, table_numbers smallint[] NOT NULL
    ) ON COMMIT DROP;
    CREATE TEMPORARY TABLE IF NOT EXISTS pg_temp.cafe_fausse_right_groups (
        table_count smallint NOT NULL, capacity_sum integer NOT NULL,
        subset_count bigint NOT NULL, PRIMARY KEY (table_count, capacity_sum)
    ) ON COMMIT DROP;
    TRUNCATE TABLE pg_temp.cafe_fausse_left_subsets,
        pg_temp.cafe_fausse_right_subsets, pg_temp.cafe_fausse_right_groups;

    INSERT INTO pg_temp.cafe_fausse_left_subsets
    SELECT mask,
        (SELECT count(*)::smallint FROM generate_series(1,left_count) position
         WHERE (mask & (1 << (position - 1))) <> 0),
        COALESCE((SELECT sum(p_capacities[position])::integer FROM generate_series(1,left_count) position
                  WHERE (mask & (1 << (position - 1))) <> 0), 0),
        COALESCE((SELECT array_agg(p_table_numbers[position] ORDER BY p_table_numbers[position])
                  FROM generate_series(1,left_count) position
                  WHERE (mask & (1 << (position - 1))) <> 0), ARRAY[]::smallint[])
    FROM generate_series(0, (1 << left_count) - 1) mask;

    INSERT INTO pg_temp.cafe_fausse_right_subsets
    SELECT mask,
        (SELECT count(*)::smallint FROM generate_series(1,right_count) position
         WHERE (mask & (1 << (position - 1))) <> 0),
        COALESCE((SELECT sum(p_capacities[left_count + position])::integer
                  FROM generate_series(1,right_count) position
                  WHERE (mask & (1 << (position - 1))) <> 0), 0),
        COALESCE((SELECT array_agg(p_table_numbers[left_count + position]
                                  ORDER BY p_table_numbers[left_count + position])
                  FROM generate_series(1,right_count) position
                  WHERE (mask & (1 << (position - 1))) <> 0), ARRAY[]::smallint[])
    FROM generate_series(0, (1 << right_count) - 1) mask;

    INSERT INTO pg_temp.cafe_fausse_right_groups
    SELECT subset.table_count, subset.capacity_sum, count(*)
    FROM pg_temp.cafe_fausse_right_subsets subset
    GROUP BY subset.table_count, subset.capacity_sum;

    FOR candidate_table_count IN 1..table_count LOOP
        IF EXISTS (
            SELECT 1 FROM pg_temp.cafe_fausse_left_subsets left_subset
            WHERE left_subset.table_count <= candidate_table_count
              AND EXISTS (
                  SELECT 1 FROM pg_temp.cafe_fausse_right_groups right_group
                  WHERE right_group.table_count = candidate_table_count - left_subset.table_count
                    AND right_group.capacity_sum >= p_party_size - left_subset.capacity_sum
              )
        ) THEN best_table_count := candidate_table_count; EXIT; END IF;
    END LOOP;

    SELECT min(left_subset.capacity_sum + right_choice.capacity_sum)
    INTO best_capacity
    FROM pg_temp.cafe_fausse_left_subsets left_subset
    JOIN LATERAL (
        SELECT right_group.capacity_sum
        FROM pg_temp.cafe_fausse_right_groups right_group
        WHERE right_group.table_count = best_table_count - left_subset.table_count
          AND right_group.capacity_sum >= p_party_size - left_subset.capacity_sum
        ORDER BY right_group.capacity_sum LIMIT 1
    ) right_choice ON true;

    SELECT sum(right_group.subset_count)
    INTO best_tie_count
    FROM pg_temp.cafe_fausse_left_subsets left_subset
    JOIN pg_temp.cafe_fausse_right_groups right_group
      ON right_group.table_count = best_table_count - left_subset.table_count
     AND left_subset.capacity_sum + right_group.capacity_sum = best_capacity;
    IF best_tie_count IS NULL OR best_tie_count <= 0 THEN
        RAISE EXCEPTION USING ERRCODE = 'P6502', MESSAGE = 'allocation invariant failed';
    END IF;
    chosen_rank := COALESCE(
        p_tie_rank,
        floor(random() * best_tie_count)::bigint + 1
    );
    IF chosen_rank < 1 OR chosen_rank > best_tie_count THEN
        RAISE EXCEPTION USING ERRCODE = '22023', MESSAGE = 'allocation tie rank is out of range';
    END IF;

    remaining_rank := chosen_rank;
    FOR candidate IN
        SELECT left_subset.table_numbers AS left_tables,
               right_group.table_count AS right_table_count,
               right_group.capacity_sum AS right_capacity,
               right_group.subset_count
        FROM pg_temp.cafe_fausse_left_subsets left_subset
        JOIN pg_temp.cafe_fausse_right_groups right_group
          ON right_group.table_count = best_table_count - left_subset.table_count
         AND left_subset.capacity_sum + right_group.capacity_sum = best_capacity
        ORDER BY left_subset.table_numbers, right_group.capacity_sum
    LOOP
        IF remaining_rank > candidate.subset_count THEN
            remaining_rank := remaining_rank - candidate.subset_count;
            CONTINUE;
        END IF;
        SELECT subset.table_numbers INTO right_tables
        FROM pg_temp.cafe_fausse_right_subsets subset
        WHERE subset.table_count = candidate.right_table_count
          AND subset.capacity_sum = candidate.right_capacity
        ORDER BY subset.table_numbers OFFSET (remaining_rank - 1) LIMIT 1;
        winner := candidate.left_tables || right_tables;
        EXIT;
    END LOOP;
    IF winner IS NULL OR cardinality(winner) <> best_table_count THEN
        RAISE EXCEPTION USING ERRCODE = 'P6502', MESSAGE = 'allocation reconstruction invariant failed';
    END IF;
    RETURN QUERY SELECT winner, best_capacity, best_tie_count, chosen_rank;
END
$function$;

REVOKE ALL ON FUNCTION cafe_fausse.select_table_allocation(smallint[], integer[], integer, bigint) FROM PUBLIC, cafe_fausse_app;
GRANT EXECUTE ON FUNCTION cafe_fausse.select_table_allocation(smallint[], integer[], integer, bigint) TO cafe_fausse_test;

COMMIT;
