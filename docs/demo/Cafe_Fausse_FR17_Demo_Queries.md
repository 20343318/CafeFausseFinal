# Café Fausse FR-17 Demo Queries --- Normalized Table Assignment Evidence

## Purpose

These read-only PostgreSQL queries are retained for the final Café
Fausse demonstration of **FR-17**.

The approved interpretation is that the reservation's table-number
relationship is normalized:

-   `cafe_fausse.reservations` stores reservation-level facts.
-   `cafe_fausse.reservation_table_assignments` stores the authoritative
    one-to-many relationship between a reservation and its assigned
    physical table number(s).
-   A reservation may therefore have one or more assigned tables.
-   The complete table allocation is reconstructed by joining the two
    relations on `reservation_id`.

These queries demonstrate that the required reservation facts, including
all assigned table numbers, are persistently represented in PostgreSQL
without adding a redundant scalar `table_number` column to
`reservations`.

## Before the Demo

Create a reservation through the Café Fausse React UI and note the
reservation reference/ID shown by the application.

In `psql`, replace `123` below with that reservation ID:

``` sql
\set reservation_reference 123
```

## Query 1 --- Reservation-Level Facts

``` sql
SELECT
    r.reservation_id,
    r.customer_id,
    r.starts_at,
    r.ends_at,
    r.party_size
FROM cafe_fausse.reservations AS r
WHERE r.reservation_id = :'reservation_reference'::bigint;
```

## Query 2 --- Complete Normalized Table-Number Relationship

``` sql
SELECT
    rta.reservation_id,
    rta.table_number
FROM cafe_fausse.reservation_table_assignments AS rta
WHERE rta.reservation_id = :'reservation_reference'::bigint
ORDER BY rta.table_number;
```

For a multi-table reservation, this returns multiple rows---one for each
assigned table.

## Query 3 --- All Required Reservation Facts in One Relational Result

``` sql
SELECT
    r.reservation_id,
    r.customer_id,
    r.starts_at AS time_slot_start,
    r.ends_at AS time_slot_end,
    string_agg(
        rta.table_number::text,
        ', ' ORDER BY rta.table_number
    ) AS table_number
FROM cafe_fausse.reservations AS r
JOIN cafe_fausse.reservation_table_assignments AS rta
  ON rta.reservation_id = r.reservation_id
WHERE r.reservation_id = :'reservation_reference'::bigint
GROUP BY
    r.reservation_id,
    r.customer_id,
    r.starts_at,
    r.ends_at;
```

Query 3 presents Reservation ID, Customer ID, Time Slot, and the
complete Table Number allocation together while preserving the
normalized physical schema.

## Suggested Demo Explanation

> The reservation row contains reservation-level facts. Table allocation
> is a potentially one-to-many relationship, so its complete value is
> normalized into `reservation_table_assignments` and linked by
> `reservation_id`. These rows are the authoritative Table Number data.
> The joined result reconstructs every required reservation fact without
> duplication or loss.

## Important Interpretation

The concatenated `table_number` produced by Query 3 is a **read-only
presentation of the normalized relationship**. It is not a separately
stored business value and does not replace
`reservation_table_assignments`.

For example, if a reservation uses tables 12 and 25:

-   the authoritative persisted assignment rows contain `12` and `25`;
-   Query 3 can display those assignments as `12, 25`;
-   no arbitrary primary table needs to be invented.

## Demo Recommendation

For the strongest FR-17 demonstration:

1.  Create a reservation in React, preferably one requiring more than
    one table.
2.  Show the table numbers displayed by the React confirmation.
3.  Run Query 1 to show the reservation-level PostgreSQL record.
4.  Run Query 2 to show the authoritative assignment rows.
5.  Run Query 3 to show all required reservation facts in one relational
    result.
6.  Point out that the UI table numbers and PostgreSQL assignment rows
    correspond.

This demonstrates the normalized implementation directly rather than
relying only on a verbal explanation.
