\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;
SET LOCAL search_path = cafe_fausse, pg_catalog;

INSERT INTO reservation_configuration (
    configuration_id,
    start_interval_minutes,
    reservation_duration_minutes,
    advance_booking_window_days,
    same_day_lead_minutes,
    restaurant_timezone
)
VALUES (1, 30, 90, 60, 120, 'America/New_York');

INSERT INTO restaurant_operating_hours (weekday, opens_at, closes_at)
VALUES
    (1, TIME '17:00', TIME '23:00'),
    (2, TIME '17:00', TIME '23:00'),
    (3, TIME '17:00', TIME '23:00'),
    (4, TIME '17:00', TIME '23:00'),
    (5, TIME '17:00', TIME '23:00'),
    (6, TIME '17:00', TIME '23:00'),
    (7, TIME '17:00', TIME '21:00');

INSERT INTO restaurant_tables (table_number, seating_capacity)
SELECT generated_number::SMALLINT, 4
FROM pg_catalog.generate_series(1, 30) AS generated_number;

DO $seed_verification$
BEGIN
    IF (SELECT pg_catalog.count(*) FROM reservation_configuration) <> 1 THEN
        RAISE EXCEPTION 'DB-05 seed requires exactly one reservation_configuration row';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_timezone_names
        WHERE name = 'America/New_York'
    ) THEN
        RAISE EXCEPTION
            'PostgreSQL does not report America/New_York in pg_timezone_names';
    END IF;

    IF (SELECT pg_catalog.count(*) FROM restaurant_operating_hours) <> 7 THEN
        RAISE EXCEPTION 'DB-05 seed requires exactly seven operating-hours rows';
    END IF;

    IF (SELECT pg_catalog.count(*) FROM restaurant_tables) <> 30
       OR (SELECT pg_catalog.min(table_number) FROM restaurant_tables) <> 1
       OR (SELECT pg_catalog.max(table_number) FROM restaurant_tables) <> 30
       OR (SELECT pg_catalog.min(seating_capacity) FROM restaurant_tables) <> 4
       OR (SELECT pg_catalog.max(seating_capacity) FROM restaurant_tables) <> 4
       OR (SELECT pg_catalog.sum(seating_capacity) FROM restaurant_tables) <> 120 THEN
        RAISE EXCEPTION 'DB-05 seed requires table numbers 1-30 at capacity four (total 120)';
    END IF;
END
$seed_verification$;

COMMIT;
