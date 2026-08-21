\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;

-- Function EXECUTE is a global default privilege in PostgreSQL. The earlier
-- schema-qualified default-privilege statement did not override PUBLIC's
-- built-in EXECUTE default. Keep all future owner-created functions private
-- until a later migration grants an approved controlled entry point.
ALTER DEFAULT PRIVILEGES FOR ROLE cafe_fausse_owner
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- Preserve the already-approved current-state boundary defensively.
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA cafe_fausse FROM PUBLIC;

COMMIT;
