\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE cafe_fausse_test;

CREATE OR REPLACE FUNCTION pg_temp.assert_db07(condition boolean, check_name text)
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
    IF condition IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'DB-07 behavior test failed: %', check_name;
    END IF;
END
$function$;

SELECT pg_temp.assert_db07(
    (SELECT table_numbers = ARRAY[3]::smallint[] AND total_capacity = 4
            AND tie_count = 3 AND selected_rank = 2
     FROM cafe_fausse.select_table_allocation(
        ARRAY[1,2,3]::smallint[], ARRAY[4,4,4], 4, 2)),
    'single-table exact fast path preserves deterministic equal-best rank'
);

SELECT pg_temp.assert_db07(
    (SELECT table_numbers = ARRAY[1,2,3]::smallint[] AND total_capacity = 12
            AND tie_count = 1 AND selected_rank = 1
     FROM cafe_fausse.select_table_allocation(
        ARRAY[1,2,3]::smallint[], ARRAY[4,4,4], 12, 1)),
    'all-tables exact fast path returns the unique complete allocation'
);

SELECT pg_temp.assert_db07(
    (SELECT table_numbers = ARRAY[1,3]::smallint[] AND total_capacity = 8
     FROM cafe_fausse.select_table_allocation(
        ARRAY[1,2,3]::smallint[], ARRAY[3,4,5], 8, 1)),
    'general meet-in-the-middle path retains least-waste semantics'
);

ROLLBACK;
\echo 'DB-07 behavior assertions: 3 passed'
