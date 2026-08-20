\set ON_ERROR_STOP on

BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL ROLE cafe_fausse_owner;
SET LOCAL search_path = cafe_fausse, pg_catalog;

CREATE TABLE reservations (
    reservation_id BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    party_size INTEGER NOT NULL,
    fingerprint_version SMALLINT NOT NULL DEFAULT 1,
    reservation_fingerprint BYTEA NOT NULL,
    CONSTRAINT reservations_pk PRIMARY KEY (reservation_id),
    CONSTRAINT reservations_customer_fk FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT reservations_interval_ck CHECK (ends_at > starts_at),
    CONSTRAINT reservations_duration_ck CHECK (
        ends_at - starts_at IN (
            INTERVAL '60 minutes',
            INTERVAL '90 minutes',
            INTERVAL '120 minutes'
        )
    ),
    CONSTRAINT reservations_party_size_ck CHECK (party_size > 0),
    CONSTRAINT reservations_fingerprint_version_ck CHECK (fingerprint_version > 0),
    CONSTRAINT reservations_fingerprint_ck CHECK (
        pg_catalog.octet_length(reservation_fingerprint) > 0
    ),
    CONSTRAINT reservations_exact_identity_uq UNIQUE (
        customer_id,
        starts_at,
        party_size
    )
);

CREATE TABLE reservation_table_assignments (
    reservation_id BIGINT NOT NULL,
    table_number SMALLINT NOT NULL,
    CONSTRAINT reservation_table_assignments_pk PRIMARY KEY (
        reservation_id,
        table_number
    ),
    CONSTRAINT reservation_table_assignments_reservation_fk FOREIGN KEY (reservation_id)
        REFERENCES reservations (reservation_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT,
    CONSTRAINT reservation_table_assignments_table_fk FOREIGN KEY (table_number)
        REFERENCES restaurant_tables (table_number)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);

CREATE INDEX reservations_fingerprint_lookup_idx
    ON reservations (fingerprint_version, reservation_fingerprint);

CREATE INDEX reservations_customer_interval_idx
    ON reservations (customer_id, starts_at, ends_at);

CREATE INDEX reservations_interval_idx
    ON reservations (starts_at, ends_at);

CREATE INDEX reservation_table_assignments_table_idx
    ON reservation_table_assignments (table_number, reservation_id);

COMMIT;
