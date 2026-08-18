\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;

REVOKE ALL ON SCHEMA cafe_fausse FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA cafe_fausse FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA cafe_fausse FROM PUBLIC;

GRANT USAGE ON SCHEMA cafe_fausse TO cafe_fausse_app, cafe_fausse_test;

-- DB-05 exposes read-only foundation data to the future runtime role. Later
-- controlled SECURITY DEFINER operations may receive EXECUTE grants in DB-06;
-- direct business-table DML is intentionally not granted here.
GRANT SELECT ON
    cafe_fausse.customers,
    cafe_fausse.reservation_configuration,
    cafe_fausse.restaurant_operating_hours,
    cafe_fausse.restaurant_tables
TO cafe_fausse_app;

-- The non-login test capability can exercise constraints in an isolated DB.
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA cafe_fausse
TO cafe_fausse_test;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA cafe_fausse
TO cafe_fausse_test;

ALTER DEFAULT PRIVILEGES FOR ROLE cafe_fausse_owner IN SCHEMA cafe_fausse
    REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE cafe_fausse_owner IN SCHEMA cafe_fausse
    REVOKE ALL ON SEQUENCES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE cafe_fausse_owner IN SCHEMA cafe_fausse
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

COMMIT;
