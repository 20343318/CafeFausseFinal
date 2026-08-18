\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

-- pgcrypto is a trusted PostgreSQL extension. The migration role still needs
-- permission to install extensions in the target deployment.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $readiness$
DECLARE
    extension_schema name;
    digest_length integer;
BEGIN
    SELECT namespace.nspname
    INTO extension_schema
    FROM pg_catalog.pg_extension AS extension
    JOIN pg_catalog.pg_namespace AS namespace
      ON namespace.oid = extension.extnamespace
    WHERE extension.extname = 'pgcrypto';

    IF extension_schema IS NULL THEN
        RAISE EXCEPTION
            'pgcrypto is required. Ask the database administrator or managed service to enable it.';
    END IF;

    EXECUTE pg_catalog.format(
        'SELECT pg_catalog.octet_length(%I.digest(pg_catalog.convert_to($1, ''UTF8''), ''sha256''))',
        extension_schema
    )
    INTO digest_length
    USING 'cafe-fausse-db05-readiness';

    IF digest_length <> 32 THEN
        RAISE EXCEPTION 'pgcrypto SHA-256 readiness check returned % bytes, expected 32', digest_length;
    END IF;
END
$readiness$;

SET LOCAL ROLE cafe_fausse_owner;
CREATE SCHEMA cafe_fausse AUTHORIZATION cafe_fausse_owner;
REVOKE ALL ON SCHEMA cafe_fausse FROM PUBLIC;

COMMIT;
