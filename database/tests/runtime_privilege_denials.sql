\set ON_ERROR_STOP off
\pset pager off

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_app;
SET LOCAL search_path = cafe_fausse, pg_catalog;

SELECT count(*) AS runtime_readable_configuration_rows
FROM reservation_configuration;
\if :ERROR
    \echo 'Runtime SELECT unexpectedly failed.'
    \quit 1
\endif

SAVEPOINT runtime_insert_customer;
INSERT INTO customers (first_name, last_name, email)
VALUES ('Runtime', 'Denied', 'runtime-denied@example.com');
\if :ERROR
    \echo 'Runtime customer INSERT denial: PASS'
\else
    \echo 'Runtime customer INSERT unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT runtime_insert_customer;

SAVEPOINT runtime_delete_configuration;
DELETE FROM reservation_configuration WHERE configuration_id = 1;
\if :ERROR
    \echo 'Runtime configuration DELETE denial: PASS'
\else
    \echo 'Runtime configuration DELETE unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT runtime_delete_configuration;

SAVEPOINT runtime_update_hours;
UPDATE restaurant_operating_hours SET closes_at = TIME '22:00' WHERE weekday = 1;
\if :ERROR
    \echo 'Runtime operating-hours UPDATE denial: PASS'
\else
    \echo 'Runtime operating-hours UPDATE unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT runtime_update_hours;

SAVEPOINT runtime_add_table;
INSERT INTO restaurant_tables VALUES (31, 4);
\if :ERROR
    \echo 'Runtime table-inventory INSERT denial: PASS'
\else
    \echo 'Runtime table-inventory INSERT unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT runtime_add_table;

SAVEPOINT runtime_schema_change;
ALTER TABLE customers ADD COLUMN forbidden_column text;
\if :ERROR
    \echo 'Runtime schema ALTER denial: PASS'
\else
    \echo 'Runtime schema ALTER unexpectedly succeeded.'
    \quit 1
\endif
ROLLBACK TO SAVEPOINT runtime_schema_change;

ROLLBACK;
\set ON_ERROR_STOP on
\echo 'Runtime privilege-denial behavior: 5/5 PASS'
