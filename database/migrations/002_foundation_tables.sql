\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE TABLE customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY,
    first_name VARCHAR(100) NOT NULL,
    middle_initial VARCHAR(1) NULL DEFAULT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(254) NOT NULL,
    phone TEXT NULL DEFAULT NULL,
    newsletter_subscribed BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT customers_pk PRIMARY KEY (customer_id),
    CONSTRAINT customers_email_uq UNIQUE (email),
    CONSTRAINT customers_first_name_ck CHECK (
        pg_catalog.char_length(first_name) BETWEEN 1 AND 100
        AND first_name = pg_catalog.regexp_replace(
            pg_catalog.btrim(first_name), '[[:space:]]+', ' ', 'g'
        )
        AND first_name ~ '[[:alpha:]]'
    ),
    CONSTRAINT customers_middle_initial_ck CHECK (
        middle_initial IS NULL
        OR (
            pg_catalog.char_length(middle_initial) = 1
            AND middle_initial ~ '^[[:upper:]]$'
        )
    ),
    CONSTRAINT customers_last_name_ck CHECK (
        pg_catalog.char_length(last_name) BETWEEN 1 AND 100
        AND last_name = pg_catalog.regexp_replace(
            pg_catalog.btrim(last_name), '[[:space:]]+', ' ', 'g'
        )
        AND last_name ~ '[[:alpha:]]'
    ),
    CONSTRAINT customers_email_canonical_ck CHECK (
        pg_catalog.char_length(email) BETWEEN 1 AND 254
        AND email = pg_catalog.btrim(email)
        AND email = pg_catalog.lower(email)
    ),
    CONSTRAINT customers_phone_ck CHECK (
        phone IS NULL
        OR (
            phone ~ '^[0-9 +().-]+$'
            AND pg_catalog.char_length(
                pg_catalog.regexp_replace(phone, '[^0-9]', '', 'g')
            ) BETWEEN 7 AND 15
        )
    )
);

CREATE TABLE reservation_configuration (
    configuration_id SMALLINT NOT NULL DEFAULT 1,
    start_interval_minutes SMALLINT NOT NULL DEFAULT 30,
    reservation_duration_minutes SMALLINT NOT NULL DEFAULT 90,
    advance_booking_window_days SMALLINT NOT NULL DEFAULT 60,
    same_day_lead_minutes SMALLINT NOT NULL DEFAULT 120,
    restaurant_timezone TEXT NOT NULL DEFAULT 'America/New_York',
    CONSTRAINT reservation_configuration_pk PRIMARY KEY (configuration_id),
    CONSTRAINT reservation_configuration_singleton_ck CHECK (configuration_id = 1),
    CONSTRAINT reservation_configuration_interval_ck CHECK (
        start_interval_minutes IN (15, 30, 60)
    ),
    CONSTRAINT reservation_configuration_duration_ck CHECK (
        reservation_duration_minutes IN (60, 90, 120)
    ),
    CONSTRAINT reservation_configuration_window_ck CHECK (
        advance_booking_window_days BETWEEN 1 AND 365
    ),
    CONSTRAINT reservation_configuration_lead_ck CHECK (
        same_day_lead_minutes BETWEEN 0 AND 1440
    ),
    CONSTRAINT reservation_configuration_timezone_ck CHECK (
        pg_catalog.char_length(restaurant_timezone) BETWEEN 1 AND 255
        AND restaurant_timezone = pg_catalog.btrim(restaurant_timezone)
        AND restaurant_timezone !~ '^[[:space:]]|[[:space:]]$'
    )
);

CREATE TABLE restaurant_operating_hours (
    weekday SMALLINT NOT NULL,
    opens_at TIME WITHOUT TIME ZONE NOT NULL,
    closes_at TIME WITHOUT TIME ZONE NOT NULL,
    CONSTRAINT restaurant_operating_hours_pk PRIMARY KEY (weekday),
    CONSTRAINT restaurant_operating_hours_weekday_ck CHECK (weekday BETWEEN 1 AND 7),
    CONSTRAINT restaurant_operating_hours_bounds_ck CHECK (opens_at < closes_at)
);

CREATE TABLE restaurant_tables (
    table_number SMALLINT NOT NULL,
    seating_capacity INTEGER NOT NULL DEFAULT 4,
    CONSTRAINT restaurant_tables_pk PRIMARY KEY (table_number),
    CONSTRAINT restaurant_tables_number_ck CHECK (table_number > 0),
    CONSTRAINT restaurant_tables_capacity_ck CHECK (seating_capacity > 0)
);

COMMIT;
