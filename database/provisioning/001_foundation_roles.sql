\set ON_ERROR_STOP on

-- Cluster-level, passwordless group roles. Run this file as a database
-- administrator in an isolated Cafe Fausse development/test database.
DO $roles$
DECLARE
    role_record record;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'cafe_fausse_owner') THEN
        CREATE ROLE cafe_fausse_owner
            NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'cafe_fausse_app') THEN
        CREATE ROLE cafe_fausse_app
            NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'cafe_fausse_test') THEN
        CREATE ROLE cafe_fausse_test
            NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
    END IF;

    FOR role_record IN
        SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole, rolreplication, rolbypassrls
        FROM pg_catalog.pg_roles
        WHERE rolname IN ('cafe_fausse_owner', 'cafe_fausse_app', 'cafe_fausse_test')
    LOOP
        IF role_record.rolcanlogin
           OR role_record.rolsuper
           OR role_record.rolcreatedb
           OR role_record.rolcreaterole
           OR role_record.rolreplication
           OR role_record.rolbypassrls THEN
            RAISE EXCEPTION
                'Role % already exists with privileges incompatible with DB-05',
                role_record.rolname;
        END IF;
    END LOOP;
END
$roles$;

-- The invoking administrator receives membership so migration and test scripts
-- can SET ROLE without storing a login password in this repository.
SELECT format('GRANT cafe_fausse_owner TO %I', current_user) \gexec
SELECT format('GRANT cafe_fausse_test TO %I', current_user) \gexec

SELECT format(
    'GRANT CONNECT, CREATE, TEMPORARY ON DATABASE %I TO cafe_fausse_owner',
    current_database()
) \gexec
SELECT format(
    'GRANT CONNECT ON DATABASE %I TO cafe_fausse_app',
    current_database()
) \gexec
SELECT format(
    'GRANT CONNECT, TEMPORARY ON DATABASE %I TO cafe_fausse_test',
    current_database()
) \gexec
