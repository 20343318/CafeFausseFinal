\set ON_ERROR_STOP on
\pset pager off

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE TEMPORARY TABLE db07_verification_results (
    check_name text PRIMARY KEY
) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.assert_db07(condition boolean, check_name text)
RETURNS void LANGUAGE plpgsql AS $function$
BEGIN
    IF condition IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'DB-07 verification failed: %', check_name;
    END IF;
    INSERT INTO db07_verification_results VALUES (check_name);
END
$function$;

SELECT pg_temp.assert_db07(
    EXISTS (
        SELECT 1
        FROM pg_catalog.pg_default_acl AS defaults
        CROSS JOIN LATERAL pg_catalog.aclexplode(defaults.defaclacl) AS privilege
        WHERE defaults.defaclrole = 'cafe_fausse_owner'::regrole
          AND defaults.defaclnamespace = 0
          AND defaults.defaclobjtype = 'f'
          AND privilege.grantee = 'cafe_fausse_owner'::regrole
          AND privilege.privilege_type = 'EXECUTE'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_default_acl AS defaults
        CROSS JOIN LATERAL pg_catalog.aclexplode(defaults.defaclacl) AS privilege
        WHERE defaults.defaclrole = 'cafe_fausse_owner'::regrole
          AND defaults.defaclnamespace = 0
          AND defaults.defaclobjtype = 'f'
          AND privilege.grantee = 0
          AND privilege.privilege_type = 'EXECUTE'
    ),
    'owner global function defaults exclude PUBLIC execute'
);

SELECT pg_temp.assert_db07(
    NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_proc AS routine
        JOIN pg_catalog.pg_namespace AS namespace ON namespace.oid = routine.pronamespace
        WHERE namespace.nspname = 'cafe_fausse'
          AND pg_catalog.has_function_privilege(
              'public', routine.oid, 'EXECUTE'
          )
    ),
    'PUBLIC cannot execute any current controlled routine'
);

SET LOCAL ROLE cafe_fausse_owner;
CREATE FUNCTION cafe_fausse.db07_default_acl_probe()
RETURNS integer LANGUAGE sql
SET search_path = pg_catalog, cafe_fausse
AS 'SELECT 1';
RESET ROLE;

SELECT pg_temp.assert_db07(
    NOT pg_catalog.has_function_privilege(
        'public', 'cafe_fausse.db07_default_acl_probe()', 'EXECUTE'
    )
    AND NOT pg_catalog.has_function_privilege(
        'cafe_fausse_app', 'cafe_fausse.db07_default_acl_probe()', 'EXECUTE'
    )
    AND pg_catalog.has_function_privilege(
        'cafe_fausse_owner', 'cafe_fausse.db07_default_acl_probe()', 'EXECUTE'
    ),
    'new owner-created function is private by default'
);

SELECT pg_temp.assert_db07(
    (SELECT pg_catalog.count(*) FROM cafe_fausse.reservation_configuration) = 1
    AND (SELECT pg_catalog.count(*) FROM cafe_fausse.restaurant_operating_hours) = 7
    AND (SELECT pg_catalog.count(*) FROM cafe_fausse.restaurant_tables) = 30
    AND (SELECT pg_catalog.sum(seating_capacity) FROM cafe_fausse.restaurant_tables) = 120,
    'approved singleton schedule inventory and capacity population'
);

SELECT pg_temp.assert_db07(
    NOT EXISTS (
        SELECT 1 FROM cafe_fausse.reservations AS reservation_row
        WHERE NOT EXISTS (
            SELECT 1 FROM cafe_fausse.reservation_table_assignments AS assignment
            WHERE assignment.reservation_id = reservation_row.reservation_id
        )
    ),
    'no committed reservation lacks assignments'
);

SELECT check_name AS passed_check
FROM db07_verification_results
ORDER BY check_name;
SELECT pg_catalog.count(*) AS passed_verification_checks
FROM db07_verification_results;

ROLLBACK;
