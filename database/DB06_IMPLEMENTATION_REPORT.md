# DB-06 implementation report and traceability

## Scope and outcome

DB-06 extends the approved DB-05 chain without changing migrations `001`-`004`.
It adds the two approved persistence tables, provisional availability,
authoritative reservation booking, exact capacity allocation, fingerprint
version 1, advisory-lock coordination, controlled writers, hardened grants,
guarded reset/rebuild support, unit and multi-session tests, and preliminary
performance evidence. DB-07, Flask, REST, React, and end-to-end work are not
included.

## Migration sequence

| Migration | Result |
|---|---|
| `001_pgcrypto_and_schema.sql` | Approved DB-05 `pgcrypto` and owned schema. |
| `002_foundation_tables.sql` | Approved four-table DB-05 foundation. |
| `003_baseline_seed.sql` | Approved singleton, hours, and 30-table seed. |
| `004_foundation_privileges.sql` | Approved DB-05 role boundary and checkpoint. |
| `005_reservation_tables_and_indexes.sql` | Exact DB-03 reservation/assignment tables, 11 named constraints, and seven additional indexes. |
| `006_reservation_internal_helpers.sql` | SHA-256, versioned serialization, email lock key, local-time candidates, and exact meet-in-the-middle allocation. |
| `007_availability_and_controlled_writers.sql` | Provisional availability, newsletter operation, and configuration/hours/capacity writers. |
| `008_authoritative_booking.sql` | Production booking plus restricted deterministic/failure seam. |
| `009_reservation_privileges.sql` | Final application/test/PUBLIC privilege boundary. |

The rebuild runner verifies DB-05 immediately after migration `004`, before
DB-06 objects exist. A full rebuild then verifies all DB-06 catalog and data
invariants. `-ThroughMigration 004_foundation_privileges.sql` reproduces the
approved checkpoint for regression tests.

## Persistence and access paths

`reservations` contains only the approved identity, customer, half-open UTC
interval, party, fingerprint version, and 32-byte fingerprint facts.
`reservation_table_assignments` contains only the reservation/table pair.
All PK, unique, check, and explicit `ON UPDATE/DELETE RESTRICT` FKs use DB-03's
approved names. The four DB-03 reservation indexes support fingerprint lookup,
customer interval checks, global interval/free-table checks, and table-centric
overlap checks; three constraint-owned indexes complete the DB-06 index set.

No status, audit timestamp, cancellation, copied capacity, availability,
ranking, random-seed, history, trigger, range, or exclusion object was added.

## Authoritative operations

| Operation | Role | Behavior |
|---|---|---|
| `provisional_availability(date, integer)` | application/test | Read-only aligned local slots, authoritative instants, and provisional capacity. |
| `book_reservation(text,text,text,text,text,timestamp,smallint,integer,text)` | application/test | Complete lock/revalidation/customer/allocation/persistence transaction. |
| `set_newsletter_preference(text,text,text,text,boolean)` | application/test | Email-serialized standalone opt-in/opt-out. |
| `book_reservation_test(..., bigint, text)` | test only | One-based equal-best rank and five rollback injection stages. |
| `set_reservation_configuration`, `set_restaurant_operating_hours`, `set_restaurant_table_capacity` | test only | Restaurant-lock-compatible prospective change paths. |

All operations are owner-held `SECURITY DEFINER` routines with fixed
`search_path = pg_catalog, cafe_fausse`. `PUBLIC` has no execute privilege.
The application role has no direct reservation/assignment read or DML and
cannot execute internal helpers, the booking core, deterministic seams, failure
injection, or controlled test writers.

## Transaction, retry, and rollback behavior

Booking uses `READ COMMITTED`, a 3-second lock timeout, and a 15-second
statement timeout. Its total order is the restaurant transaction advisory lock
`(1128682322,1)`, configuration row, weekday rows ascending, table rows
ascending, canonical-email advisory lock `(1128678733,email_key)`, customer,
then reservation/assignment work. Availability never reserves; booking always
revalidates under the restaurant lock.

The email key is SHA-256 of canonical-email UTF-8 bytes, digest bytes 0-3 as an
unsigned big-endian value, mapped to signed two's complement. Fingerprint
version 1 hashes UTF-8 bytes of:

```text
<len>:<customer_id>|<len>:<UTC YYYY-MM-DDTHH:MM:SS.ffffffZ>|<len>:<party_size>
```

A fingerprint match is only a candidate: underlying customer/start/party facts
must also match. The approved unique tuple is a compatibility/race backstop.
An exact retry returns the original reservation, all sorted assignments, and
current newsletter state without contact or newsletter mutation.

Unavailable and time-boundary outcomes use an inner subtransaction so a newly
created customer or any optional/newsletter change is rolled back. Test
injections after customer insert, optional-field population, newsletter update,
reservation insert, and partial assignment insert preserve PostgreSQL error
classes `P6691`-`P6695` and leave no partial state. Later Flask must restart the
whole operation at most three total attempts within one overall deadline for
`55P03`, `40P01`, or `40001`; no failed transaction is resumed.

## Allocation evidence

The allocator divides at most 30 free tables into two halves, enumerates each
half's subsets in session-local temporary tables, groups right-half choices,
then reconstructs only global best candidates. It minimizes table count first,
total assigned capacity second, and selects uniformly only among equal-best
candidates. Production supplies no rank and uses PostgreSQL randomness; the
test role may supply every one-based equal-best rank. Tests cover one/multiple
tables, heterogeneous capacity, ranking precedence, all-equal ties, invalid
rank, and insufficient capacity.

## Verification and test evidence

Executed on 2026-08-20 in a disposable local PostgreSQL 18.3 cluster and an
isolated database named `cafe_fausse_test_db06_baseline`:

| Evidence | Result |
|---|---|
| Approved pre-change DB-05 suite | 81 behavior tests and 5 runtime denials passed. |
| DB-05 checkpoint after reset/replay | Original verifier, behavior suite, and runtime denials passed. |
| DB-06 verifier | 25 catalog, ownership, grant, population, and committed-data checks passed. |
| DB-06 behavior suite | 39 transactional tests passed, including all five injected rollback stages. |
| DB-06 runtime boundary | 7 direct-read/DML/internal-seam denials passed. |
| Multi-session integration | 23 barrier-synchronized scenario iterations passed with `-Iterations 3`; critical exact/email/last-table races each repeated three times. |
| Retryable failures | Bounded restaurant-lock wait returned `55P03`; forced test-role row deadlock preserved `40P01`. |
| Lost response | Commit followed by a new ordinary submission returned the original exact reservation. |

Each race waits until session B is visibly in PostgreSQL `wait_event_type =
'Lock'` before session A commits. Final assertions reject duplicate customers,
duplicate exact identities, overlapping table assignments, missing assignments,
or insufficient assigned capacity. The full runner uses three repetitions for
the critical races and finishes with a guarded rebuild to an empty reservation
state.

## Preliminary performance evidence

Environment: PostgreSQL 18.3, Windows NT 10.0.26100.0, Intel64 Family 6 Model
141 Stepping 1, 8 logical processors. Each sample includes local `psql` process
startup. Ten samples were collected per path:

| Measurement | p50 ms | p95 ms |
|---|---:|---:|
| Provisional availability day | 309.05 | 333.29 |
| 30 equal-capacity allocation | 737.64 | 829.96 |
| 30 heterogeneous-capacity allocation | 681.76 | 716.85 |
| Uncontended worst-case multi-table booking | 1173.92 | 1205.66 |
| Exact retry | 333.32 | 367.55 |
| Same-customer conflict | 337.02 | 370.72 |
| Unavailable/full outcome | 366.88 | 482.41 |
| Two concurrent submissions | 1488.24 | 1599.30 |
| Five concurrent submissions | 2932.52 | 3005.13 |
| Booking with 100 retained history rows | 479.62 | 938.99 |

These are preliminary DB-06 measurements, not the DB-07 performance gate and
not a claim that the later browser form always completes within two seconds.
The five-request result is expected to reflect the approved restaurant-wide
serialization and is an explicit DB-07 measurement/optimization input.

## Traceability matrix

| Source | DB-06 evidence |
|---|---|
| SRS FR-02 | PostgreSQL-backed recurring hours are seeded to the SRS schedule; provisional availability and authoritative booking read the current schedule and enforce its opening and closing boundaries. |
| SRS FR-06-FR-09 | Provisional availability, booking-window/lead/hours/alignment validation, party capacity, and exact table assignment. |
| SRS FR-15-FR-18 | Thirty seeded tables remain authoritative; allocation supports one or several tables, randomized equal-best choice, and no overbooking. |
| SRS NFR-02 | Preliminary p50/p95 evidence is recorded without claiming the later end-to-end gate. |
| SRS NFR-05/NFR-06 | Referential integrity, half-open overlap checks, complete assignments, transaction rollback, and hardened grants. |
| SRS NFR-09 | PostgreSQL remains authoritative; no Flask/React duplicate logic was created. |
| Rubric PostgreSQL integration/direct effects | Clean migration chain and direct customer/reservation/assignment/newsletter persistence are inspectable. |
| Rubric sophisticated logic | Exact allocation, revalidation, retry identity, overlap prevention, and deterministic concurrency tests. |
| PRA-001-PRA-029 | Canonical customer rules, configuration, hours, allocation, newsletter, DST, retry, and excluded-field decisions are preserved. |
| DB-03 1.1 | Exact two-table logical schema, types, keys, constraints, referential actions, and indexes. |
| DB-04 1.1 | READ COMMITTED operation order, advisory namespaces, revalidation, allocation ranking, exact retry, rollback, and retry classes. |
| DB-05 approved implementation | Migrations `001`-`004`, four foundation tables, roles, `pgcrypto`, and the original checkpoint verifier/tests are preserved. |

## Compatibility, deviations, and checkpoint

No approved DB-05 migration was edited. The reset script was extended only to
delete DB-06 dependants in explicit FK order before its existing guarded schema
drop. The rebuild/test/verify scripts were extended to retain an executable
DB-05 checkpoint and to run DB-06. No approved design artifact was modified.

There are no known schema or behavioral deviations and no implementation
blocker. Preliminary performance is intentionally deferred for final DB-07
evaluation. DB-06 is implemented and verified, but the roadmap remains paused
at the explicit **DB-06 approval checkpoint**; DB-07 and application work must
not begin without approval.
