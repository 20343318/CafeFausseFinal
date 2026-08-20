\set ON_ERROR_STOP on

SELECT pg_catalog.set_config(
    'cafe_fausse.reset_environment',
    :'cafe_fausse_environment',
    false
);
SELECT pg_catalog.set_config(
    'cafe_fausse.allow_reset',
    :'cafe_fausse_allow_reset',
    false
);

DO $reset_guard$
DECLARE
    requested_environment text := pg_catalog.current_setting('cafe_fausse.reset_environment');
    allow_reset text := pg_catalog.current_setting('cafe_fausse.allow_reset');
    target_database text := pg_catalog.current_database();
BEGIN
    IF requested_environment NOT IN ('development', 'test', 'demo') THEN
        RAISE EXCEPTION
            'DB-05 reset refused: environment must be development, test, or demo';
    END IF;

    IF allow_reset <> 'YES' THEN
        RAISE EXCEPTION
            'DB-05 reset refused: CAFE_FAUSSE_ALLOW_RESET must equal YES';
    END IF;

    IF target_database !~ '^cafe_fausse_(dev|test|demo)(_[a-z0-9_]+)?$' THEN
        RAISE EXCEPTION
            'DB-05 reset refused: database % is not an approved Cafe Fausse nonproduction name',
            target_database;
    END IF;
END
$reset_guard$;

-- Delete DB-06 dependants in explicit foreign-key order before removing the
-- project-owned schema. Conditional dynamic SQL keeps the same reset usable at
-- the DB-05 checkpoint, where these tables do not exist yet.
DO $dependency_cleanup$
BEGIN
    IF pg_catalog.to_regclass('cafe_fausse.reservation_table_assignments') IS NOT NULL THEN
        EXECUTE 'DELETE FROM cafe_fausse.reservation_table_assignments';
    END IF;

    IF pg_catalog.to_regclass('cafe_fausse.reservations') IS NOT NULL THEN
        EXECUTE 'DELETE FROM cafe_fausse.reservations';
    END IF;

    IF pg_catalog.to_regclass('cafe_fausse.customers') IS NOT NULL THEN
        EXECUTE 'DELETE FROM cafe_fausse.customers';
    END IF;
END
$dependency_cleanup$;

-- The target is a fixed, project-owned schema. No database or unresolved name
-- is dropped. Future DB-06 dependent objects will live in this schema and will
-- therefore be removed before the foundation is replayed.
DROP SCHEMA IF EXISTS cafe_fausse CASCADE;
