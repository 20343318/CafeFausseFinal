# API-08 Implementation Report - Reservation Creation

## Status and scope

API-08 implements only `POST /api/v1/reservations` (OP-05). API-01 through
API-07 remain unchanged except for the route-inventory assertion and shared
dependency/application registration needed to expose OP-05. React, API-09,
deployment, and database schema work were not started.

## Implemented contract

- Strict JSON shape and normalization for structured name, canonical matching
  emails, optional phone, selected offset local start, explicit UTC offset,
  party size, and newsletter action.
- One frozen `cafe_fausse.book_reservation(...)` call in an explicit
  `READ COMMITTED` transaction. Flask adds no allocation, overlap, capacity,
  fingerprint, or customer-write logic.
- Bounded full-transaction retries only for `55P03`, `40P01`, and `40001`,
  with separate known-rollback and unknown-commit responses.
- A distinct post-commit read-only confirmation transaction retrieving only stored
  name components and the current restaurant IANA timezone; failure maps to
  known-existence confirmation recovery.
- Exhaustive mapping for created, phone notice, exact retry, identity/middle
  conflict, same-customer overlap, unavailable/full, caller validation,
  configuration failure, temporary failure, and ambiguous outcome.
- Confirmation serialization from committed instants through the current restaurant
  IANA timezone, with JavaScript-safe reservation reference,
  local/canonical interval, multi-table assignment, newsletter state, and SRS
  restaurant contact facts. Contact, customer ID, fingerprint, database
  literals, and allocation internals remain private.

## Requirements traceability

- SRS FR-06 through FR-09 and FR-17 through FR-18: form data processing,
  authoritative slot validation, random assignment from 30 tables, persistent
  customer/reservation state, and confirmation/full responses.
- SRS NFR-02, NFR-05, NFR-06, and NFR-09: bounded submission processing,
  transactional integrity/no double booking, safe failures, and modular code.
- Rubric: working forms' backend contract, Flask/PostgreSQL integration,
  direct persistent effects, and sophisticated reservation logic.
- PRA-006 through PRA-014 and PRA-017 through PRA-025: configured time rules,
  half-open occupancy, retry safety, capacity/multi-table selection, customer
  identity/reuse, synchronized newsletter state, authoritative validation,
  safe confirmation/errors, and availability-first authoritative revalidation.

## Tests and evidence

- Correction-focused gateway/service/API selection: `32 passed`.
- Unit/API selection: `420 passed, 56 deselected`.
- Guarded PostgreSQL integration selection: `56 passed, 420 deselected`.
- Complete guarded suite: `476 passed`; aggregate branch-aware coverage `90%`.
- API-08 integration covers new customer/persistence, multi-table assignment,
  exact retry reconstruction, stored middle-initial display, authoritative IANA
  local-time reconstruction, invalid request, identity-conflict rollback, full
  capacity, concurrent competing bookings, one-winner semantics, and no shared
  tables. Unit/API coverage also proves independent offset-transition conversion
  and deterministic party-size/server-duration error classification.
- The runner verified zero surviving business rows, stopped PostgreSQL,
  restored 24 process-environment values, and removed both marker-owned roots.

## Deviations, risks, and checkpoint

The approved API08-RC-01/API08-RC-02 contract reconciliation changed
`database/migrations/008_authoritative_booking.sql`,
`database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, and the approved API-01, API-02,
and API-03 artifacts. The reconciliation did not change the public REST
request/response shape; PostgreSQL schema, table, column, or constraint
definitions; roles or grants; production routine signatures or result shapes;
allocation logic; retry behavior; or React/frontend behavior. Random
tie-breaking and table selection remain correctly owned by PostgreSQL. The
accepted Version 1 coarse booking lock and previously documented
contention/performance limitations remain.

API-08 is implemented and verified, passed independent final review, and is
approved. API-01 through API-08 are approved and frozen; React work has not
started.
