# DB-05 implementation report and traceability

## Scope and outcome

DB-05 implements the PostgreSQL foundation only: `customers`,
`reservation_configuration`, `restaurant_operating_hours`, and
`restaurant_tables`, plus approved constraints, exact initialization,
`pgcrypto` readiness, roles, guarded rebuild, verification, and tests. No
reservation/assignment table, booking function, availability operation,
fingerprint implementation, Flask code, or React code is present.

## Technical decisions and rationale

| Decision | DB-05 implementation | Rationale |
|---|---|---|
| Migration runner | `psql` with `ON_ERROR_STOP`, lexically ordered numbered SQL files | Smallest dependency-free PostgreSQL-native approach in an empty repository. |
| Migration tracking | No metadata table; clean schema rebuild and forward replay | The prompt forbids choosing an additional table without approval. |
| Namespace | One owned `cafe_fausse` schema | Gives reset a fixed narrow target and separates project objects from `public`. |
| Forward/rebuild policy | Forward files apply to a clean schema; guarded rebuild drops only that schema and replays | Avoids misleading destructive down migrations for extensions and cluster roles. |
| Constraint names | All 20 DB-03 foundation names are explicit | Makes errors, catalog tests, and future migrations deterministic. |
| Name checks | Persisted trim/collapse equality, 1-100 length, and locale-aware alphabetic check | Preserves punctuation/accents while leaving complete Unicode normalization to Flask. |
| Timezone technical bound | `TEXT`, 1-255 characters, trimmed at both ends; catalogue membership verified separately | Implements DB-03's bounded technical text without pretending `pg_timezone_names` is immutable. |
| Seed behavior | Plain exact inserts followed by invariant assertions | Clean replay is deterministic and unexpected existing state fails rather than being overwritten. |
| Roles | Passwordless non-login owner, app, and test groups | Separates migration ownership, ordinary runtime reads, and isolated constraint testing without secrets or superuser grants. |
| Runtime writes | No direct DB-05 table DML | Protects singleton/schedule/inventory; DB-06 can later expose narrowly controlled operations. |
| Extension | `pgcrypto` migration plus a 32-byte SHA-256 readiness probe | Fulfills approved DB-04 readiness without implementing reservation fingerprints. |
| Reset guard | Two explicit environment values, verified actual DB name, and a fixed schema target | Refuses production-like or ambiguous targets before deletion. |
| Population invariants | Seed assertions, read-only runtime grants, catalog verification, and behavior tests | Row constraints cannot guarantee required row counts or timezone catalogue membership. |
| Timeouts | DB-05 sessions use 5-second lock and 60-second statement bounds | Prevents indefinite development/test hangs; DB-06 must separately measure booking limits. |
| Advisory locks | Collision-separated two-key namespaces documented only | Gives DB-06 stable identities without prematurely acquiring locks or implementing bookings. |

No DB-03 schema decision was changed. `GENERATED ALWAYS AS IDENTITY` is the
DB-05 physical expression of the approved database-generated customer ID.

## Source-of-truth and normalization confirmation

| Fact | Sole DB-05 home |
|---|---|
| Customer identity, structured name, canonical email, and optional phone | `cafe_fausse.customers` |
| Current newsletter Boolean | `customers.newsletter_subscribed` |
| Five current scalar reservation settings | `cafe_fausse.reservation_configuration` |
| Current recurring weekly hours | `cafe_fausse.restaurant_operating_hours` |
| Individual table identity and capacity | `cafe_fausse.restaurant_tables` |

The four relations are in third normal form. Total capacity, maximum party size,
latest starts, slots, availability, table combinations, and normalized helper
values are derived and not persisted. There are no duplicate configuration,
schedule, newsletter, contact, or audit stores.

## Traceability matrix

| Requirement/design item | Implementing evidence | Verification evidence |
|---|---|---|
| SRS FR-02; PRA-008, PRA-009, PRA-029 | Migration `002` operating-hours relation; migration `003` exact SRS seed | Verification exact seven-row comparison; operating-hours behavior tests |
| SRS FR-07; PRA-005 to PRA-012 | Singleton scalar configuration and exact defaults/ranges | Configuration boundary tests; timezone catalogue assertion |
| SRS FR-16; PRA-019 to PRA-021 | Unique canonical customer email and sole current newsletter Boolean | Customer uniqueness/default/update tests; excluded-column checks |
| SRS FR-17 | Recognizable `customers`; foundation data needed for later reservations | Exact columns and absence of unapproved columns verified |
| SRS FR-18 | PostgreSQL foundation available to the future Flask runtime role | Runtime SELECT succeeds; prohibited direct writes fail |
| SRS NFR-05 | Keys/checks/unique constraints, protected populations, fail-fast migration/reset | Constraint behavior tests, role denial tests, two rebuilds |
| SRS NFR-09 | Numbered migrations, operating guide, named constraints, verification, traceability | Clean scripted replay and catalog checks |
| PRA-015 to PRA-017 | 30 persistent table rows, positive individual capacities, initial 4 each | Exact 1-30/count/min/max/sum checks and invalid-write tests |
| DB-03 columns/types/defaults/nullability | Migration `002` | Exact column arrays, defaults/behavior, excluded objects |
| DB-03 foundation constraints | Migration `002`, 20 deterministic names | Exact constraint-name set and behavioral rejection tests |
| DB-03 foundation indexes | Only PK/unique constraints create indexes | Exact five-index set; no manual indexes |
| DB-04 `pgcrypto` handoff | Migration `001` | Extension catalogue and 32-byte SHA-256 checks |
| DB-04 role restriction | Provisioning and migration `004` | Privilege catalog assertions plus five runtime denial attempts |
| DB-04 stable lock handoff | `ADVISORY_LOCKS.md` | Manual review; no lock-acquisition SQL exists in DB-05 |
| DB-04 environment readiness | `.env.example`, guarded scripts, session timeouts | Refused-reset and fail-visible runner tests |

Reservation-dependent parts of FR-07, FR-17, FR-18, NFR-05, PRA-013,
PRA-014, PRA-018, PRA-027, and DB-04 remain DB-06 work. This report does not
claim their booking behavior is implemented.

## Verification evidence - 2026-08-17

The final artifacts were executed against a disposable PostgreSQL 18.3 ICU
cluster bound only to `127.0.0.1:55432`, using the isolated database
`cafe_fausse_test_db05`. The existing machine PostgreSQL service was not used.
The temporary cluster was removed after verification.

| Evidence | Result |
|---|---|
| Static PowerShell parsing and `git diff --check` | Pass |
| Reset with `CAFE_FAUSSE_ALLOW_RESET=NO` | Refused as required |
| Intentional SQL error under `ON_ERROR_STOP` | Nonzero exit as required |
| Complete clean rebuild | Pass |
| Immediate second complete clean rebuild | Pass |
| Catalog/seed/extension/role verification | 21/21 pass |
| Transactional schema and constraint behavior tests | 81/81 pass |
| Actual `cafe_fausse_app` prohibited-operation attempts | 5/5 denied as required |
| Distinct automated checks | 109/109 pass |
| Manual direct seed query | 1 configuration, 7 weekdays, 30 tables, total capacity 120 |
| Index and DB-06 exclusion query | 5 constraint-owned indexes; both DB-06 tables absent |

`pgcrypto` version 1.4 was installed and returned a 32-byte SHA-256 digest.
The final direct catalogue query reported 20 approved explicit constraints.
PostgreSQL 18 additionally represents `NOT NULL` metadata in
`pg_constraint`; verification deliberately distinguishes that metadata from
the 20 named PK/unique/check constraints.

## Explicit DB-06 handoff

DB-06 must add only after DB-05 approval:

- `reservations` and `reservation_table_assignments`;
- their DB-03 constraints and nonredundant indexes;
- database-generated reservation fingerprint serialization/digest logic;
- provisional availability and authoritative booking operations;
- restaurant and canonical-email advisory-lock acquisition;
- same-customer overlap and table exclusivity;
- minimum-table/least-waste/random-tie allocation;
- atomic assignment/customer/newsletter behavior;
- bounded full-transaction retry and concurrency tests.

## Approval checkpoint

The required clean rebuild, verification, and automated suite have run
successfully in an isolated PostgreSQL database. DB-05 is ready for explicit
approval. Approval authorizes DB-06 only; it does not complete the PostgreSQL
phase or authorize Flask, React, or integration work.
