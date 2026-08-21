# DB-07 PostgreSQL Verification and Hard Gate 1 Report

Date: 2026-08-20  
Baseline: `main` at `82ab9d1bb6b9363a84dc6b4828a96549f9045ed8`, initially clean and synchronized with upstream  
Scope: DB-07 only; no Flask, REST, React, or API-01 work

## Executive assessment

The approved DB-05/DB-06 implementation reproduced from an empty isolated PostgreSQL 18.3 database and matched the approved DB-03/DB-04 architecture. DB-07 found one major privilege defect and one measured performance concern. Both were corrected by forward migrations, with migrations 001–009 preserved byte-for-byte. No approved table, column, constraint, index, fingerprint, locking, isolation, or allocation decision changed.

The final gate evidence consists of the DB-05/DB-06 regression tests, DB-07 catalog and behavior checks, role-denial tests, barrier-synchronized concurrency tests, rollback/failure injection, ambiguous-response recovery, rollback-safe query plans, and measured latency. The PostgreSQL Contract for Flask v1.0 is frozen in `POSTGRESQL_CONTRACT_FOR_FLASK.md`, and the PostgreSQL-only demonstration is in `DB07_MANUAL_DEMONSTRATION.md`.

## Initial read-only audit

- Authoritative files were present: SRS, rubric, Addendum 2.2.1, DB-01 1.2.1, DB-02 1.2, DB-03 1.1, DB-04 1.1, roadmap 1.1.1, and approved DB-05/DB-06 reports.
- Approved migration boundary was 001–009; all matched committed bytes and remain immutable.
- Supported baseline was PostgreSQL 14+, `pgcrypto`, schema `cafe_fausse`, and owner/app/test non-login roles. Verification ran on PostgreSQL 18.3.
- The initial suite passed the reset guard, fail-visible error check, DB-05 verifier/behavior/denial tests, two DB-06 rebuilds, DB-06 behavior/denial tests, and all 23 then-configured concurrency iterations. Its preliminary performance stage failed only because a correct `55P03` was treated as a harness failure; committed-state invariants remained intact.

## Defect register

| Class | Cause and impact | Correction | Regression evidence |
|---|---|---|---|
| Major | Migration 004 used schema-scoped default privileges for functions. PostgreSQL’s built-in `PUBLIC EXECUTE` function default is global, so a future owner-created function would be public until explicitly revoked. Current routines were explicitly protected; no current bypass existed. | Migration 010 sets the owner-wide default and defensively revokes current `PUBLIC` execution. | `verify_db07.sql` checks `pg_default_acl`, all current routines, and creates a rollback-only future probe that app/PUBLIC cannot execute. |
| Major performance concern | Exact subset enumeration cost about 0.93 s even where a sufficient single table or all tables made the exact answer provable, leaving little room under the SRS two-second expectation. | Migration 011 adds only mathematically exact one-table and all-tables fast paths; the approved general meet-in-the-middle path remains unchanged. | Three DB-07 allocator assertions plus the complete DB-06 allocation suite; worst-case booking p95 fell from 1,916.18 ms to 546.46 ms in 10-sample validation. |
| Evidence gap | Performance concurrency treated bounded retryable SQLSTATE as failure and reported only p50/p95. | Harness now classifies `55P03`/`40P01`/`40001`, checks committed counts, adds burst-8 and min/p99/max/outcome totals. | `performance_test.ps1`. |
| Evidence gap | Concurrent blank middle/phone population was not explicit. | Added a database-observed, email-lock-barrier scenario. | `concurrency_test.ps1`. |

## Final schema and object catalogue

There are exactly six business tables, 27 columns, 31 named non-null-independent constraints, 12 nonredundant indexes (including constraint-owned indexes), two identity sequences, 14 controlled routines, no triggers, and no unapproved business objects.

| Table | Columns (type; null/default/identity where material) | Keys and rules |
|---|---|---|
| `customers` | `customer_id bigint` identity always; `first_name varchar(100)`; `middle_initial varchar(1)` nullable; `last_name varchar(100)`; `email varchar(254)`; `phone text` nullable; `newsletter_subscribed boolean default false` | PK identity; unique canonical email; normalized names; uppercase middle initial; phone character/digit rules. |
| `reservation_configuration` | `configuration_id smallint default 1`; intervals/duration/window/lead `smallint` defaults 30/90/60/120; `restaurant_timezone text default America/New_York` | Singleton PK/check; permitted intervals 15/30/60, durations 60/90/120, window 1–365, lead 0–1440, bounded trimmed timezone. |
| `restaurant_operating_hours` | `weekday smallint`; `opens_at`, `closes_at time without time zone` | Weekday PK 1–7; opening strictly before closing. |
| `restaurant_tables` | `table_number smallint`; `seating_capacity integer default 4` | PK; both values positive. |
| `reservations` | `reservation_id bigint` identity always; `customer_id bigint`; `starts_at`, `ends_at timestamptz`; `party_size integer`; `fingerprint_version smallint default 1`; `reservation_fingerprint bytea` | PK; customer FK RESTRICT/RESTRICT; positive 60/90/120-minute interval; positive party/version/nonempty fingerprint; unique `(customer_id,starts_at,party_size)`. |
| `reservation_table_assignments` | `reservation_id bigint`; `table_number smallint` | Composite PK; both FKs RESTRICT/RESTRICT. |

Indexes are `customers_pk`, `customers_email_uq`, `reservation_configuration_pk`, `restaurant_operating_hours_pk`, `restaurant_tables_pk`, `reservations_pk`, `reservations_exact_identity_uq`, `reservations_fingerprint_lookup_idx`, `reservations_customer_interval_idx`, `reservations_interval_idx`, `reservation_table_assignments_pk`, and `reservation_table_assignments_table_idx`. All tables, indexes, sequences, and routines are owner-held.

The 14 routines are the three production operations; test-only controlled writers; booking core/test seam; fingerprint, timezone, email-lock, SHA-256, and exact-allocation helpers. Every routine is `SECURITY DEFINER`, owner-held, and fixed to `search_path=pg_catalog, cafe_fausse`. Exact signatures and stable results are frozen in the contract.

## Source-of-truth and reproducibility

Newsletter state exists only on `customers`; scalar settings only in the singleton; recurring hours only in the seven-row hours table; capacity only on 30 table rows; immutable reservation interval/party only on `reservations`; winners only in assignments. Total/maximum capacity, valid starts, availability, free/busy sets, candidates, counts, waste, ranks, fingerprints’ source facts, and random outcomes are derived. No status, audit/history, copied capacity/interval, availability, hold, candidate, or profile table exists.

A rebuild applies 001–011 lexically with `ON_ERROR_STOP`, verifies at the DB-05 checkpoint and final DB-06/DB-07 state, and depends on no absolute repository path or secret. The guarded reset deletes assignments, reservations, and customers in dependency order, drops only the fixed nonproduction schema, and restores one configuration row, weekdays 1–6 at 17:00–23:00, Sunday at 17:00–21:00, and tables 1–30 at capacity four (total 120). Production roles cannot reset.

## Test and concurrency evidence

The gate suite covers 21 DB-05 catalog checks, 25 DB-06 catalog/invariant checks, five DB-07 checks, 81 DB-05 behavior assertions, 39 DB-06 behavior assertions, three DB-07 allocator assertions, five DB-05 and seven DB-06 expected denials, and the reset/fail-visible checks. No test is skipped. DB-06 behavior includes normalization/boundaries, configuration/readiness, DST, every overlap shape, allocation ranking/random seam, collision safety, exact retry, prospective changes, retention, and five rollback injection points.

Concurrency uses explicit session markers plus `pg_stat_activity` lock-wait observation, not timing luck. Critical exact-request, same-new-email, and last-table conflicts run 20 clean iterations each; the full driver reports 75 scenario iterations. It also covers matching/mismatching identity, blank-field population, single/multi/mixed competition, customer overlap, back-to-back, stale availability, three coordinated writers, newsletter interaction, `55P03`, forced `40P01`, and response loss followed by exact retry. Final-state queries reject duplicate email, duplicate logical booking, same-customer overlap, shared overlapping tables, capacity shortfall, or missing assignments.

The final `database/scripts/test.ps1` run completed in 409.1 seconds with exit code 0: 51 distinct catalog/invariant checks, 123 behavior assertions, 12 expected privilege denials, two harness safety checks, and 75 barrier-synchronized concurrency scenario iterations all passed (263 distinct checks/scenarios), with no skips. It included two consecutive complete DB-07 rebuilds, query-plan execution, and a final rebuild/read-only verification of the empty approved baseline.

## Failure and recovery matrix

| Case | Database result | State/retry rule |
|---|---|---|
| Malformed/canonical/time/capacity input | `invalid_request` plus stable detail | Returned, no mutation; caller corrects input. |
| Missing singleton/hours/tables or invalid timezone | `invalid_database_configuration` plus detail | Returned, no mutation; operational correction required. |
| Identity/middle conflict | stable conflict outcome | No booking/customer mutation. |
| Differing populated phone | `booked_phone_notice` when booking otherwise succeeds | Booking commits; old phone retained. |
| Exact tuple | `exact_retry` | Existing booking/current newsletter returned; no mutation. |
| Same-customer overlap/full | `same_customer_overlap` or `unavailable` | Statement returns and partial work rolls back. |
| Unique races | serialized by email; exact uniqueness backstop | One customer/logical booking; stable competing result. |
| Lock/deadlock/serialization conflict | SQLSTATE `55P03`, `40P01`, or `40001` | Transaction rollback; later caller may retry within the contract bound. |
| Injected unexpected mutation-stage error | test SQLSTATE `P6691`–`P6695`; invariant failure `P6502` | Entire statement/transaction rolls back. Test seams unavailable to app/PUBLIC. |
| Loss before commit | no durable assumption | Roll back/disconnect; ordinary resubmission. |
| Unknown commit/response lost after commit | outcome initially unknown | Same request returns either first `booked` or later `exact_retry`; never duplicates or replays newsletter action. |

## Role and security result

Owner/app/test roles have no login, superuser, create-db, create-role, replication, or bypass-RLS capability. App can use the schema, select current foundation facts, and execute exactly the three production routines. Direct mutation, reservation/assignment reads, sequences, DDL, controlled writers, internal helpers, deterministic randomness, and failure injection are denied. `PUBLIC` has no schema or routine path; migration 010 also secures future functions. No password, credential, connection URL, unsafe dynamic object name, or production reset path is present.

## Query-plan and performance assessment

Reference host: Windows 10 build 26100, Intel Family 6 Model 141, 8 logical processors, PostgreSQL 18.3, local loopback, warm/mixed cache, 20 samples, one local `psql` process per observed call. Client-observed figures conservatively include process startup. A rollback-only 200-reservation history fixture was analyzed for plans.

Representative plan execution: canonical email 0.058 ms via `customers_email_uq`; fingerprint 0.025 ms via its lookup index; same-customer lookup 0.077 ms via `reservations_customer_interval_idx`; global interval 0.044 ms via `reservations_interval_idx`; assignment-by-table 0.040 ms via its index; free-table derivation 0.107 ms with the interval index. Sequential scans on deliberately tiny 30-row inventory are appropriate. Before fast paths, the general 30-table allocator plan was 934.386 ms; general equal/heterogeneous fixtures remain about 1.0 s by client observation, while production single/all-table bookings use the exact fast paths.

Post-correction 20-sample client-observed p50/p95/p99: availability 417.00/531.49/555.18 ms; single booking 442.92/524.84/532.34 ms; all-table booking 439.82/485.91/533.69 ms; exact retry 523.29/655.19/732.73 ms; overlap 437.07/500.04/646.12 ms; unavailable 463.19/560.85/566.31 ms; retained-history booking 456.45/556.90/562.40 ms. Groups of 2, 5, and 8 were 823.20/901.85/1,365.64, 2,048.68/2,424.18/2,427.34, and 3,254.49/3,361.94/3,399.17 ms respectively, with only booked or explicitly retryable outcomes and committed-count agreement. The full observed min/max table is reproducible with `performance_test.ps1 -Samples 20`.

The controlled timeout case separately observed 3,012.49 ms of waiter duration and 3,019.92 ms of holder lock-hold duration, consistent with the configured three-second booking lock timeout. That `55P03` transaction rolled back; the holder alone committed, and the final invariant check passed.

Proposed DB-07 budget for explicit approval is p95 under 1,000 ms for uncontended production booking and availability on this reference class of host, leaving at least half the SRS two-second expectation for later Flask/network/UI work. The approved 3-second lock timeout is measured/classified separately and is not a successful latency result. Coarse-lock group throughput is a known Version 1 limitation, not a correctness failure.

## Traceability matrix

| Requirement group | Implementation | Automated/manual evidence | Result / later layer |
|---|---|---|---|
| SRS customer/reservation PostgreSQL and FR-06–FR-09/FR-15–FR-18 | Tables, booking/newsletter/availability routines | DB-05/06 behavior, concurrency, demo | PostgreSQL complete; Flask owns request/API and messages. |
| SRS NFR-02 reliability, NFR-05 performance, NFR-09 security | Transactions/locks, plans/measurements, least privilege | rollback/races, performance/plans, denial suites | Database support complete; full-stack verification later. |
| Rubric PostgreSQL integration, sophisticated logic, tests/demo | Rebuild, exact allocator, controlled routines | full gate and demo guide | Complete at database layer. |
| PRA-001–004 | Ordered increments, versioned baseline, continuous tests | Git/migration audit and suite | Complete. |
| PRA-005–012, PRA-029 | Scalar configuration, intervals, duration, window/lead/timezone, recurring hours | schema checks; availability/booking boundary and DST tests | Complete. |
| PRA-013–018 | Half-open overlap, retry, capacity, 30 tables, multi-table exclusivity | DB-06 behavior/concurrency/plans | Complete. |
| PRA-019–021, PRA-023 | Identity/contact/newsletter validation and concurrency | behavior, rollback, denials, population race | Database enforcement complete; full syntax/UI validation later. |
| PRA-022, PRA-026, PRA-028 | Retained immutable bookings, prospective settings, controlled reset | constraints/tests/rebuild | Complete. |
| PRA-024–025 | Stable database outcomes, provisional availability/revalidation | contract and behavior tests | Database support complete; wording/UI/API later. |
| PRA-027 | DB-generated versioned fingerprint and retry separation | collision/exact/lost-response tests | Complete. |
| DB-03 full catalogue/source authority | Migrations 001–005 and 009–010 | 51 catalog/invariant checks plus catalogue above | Complete. |
| DB-04 transaction/locking/allocation/randomness/recovery | Migrations 006–008 and semantics-preserving 011 | behavior, 75 concurrency iterations, plans | Complete. |
| DB-05/DB-06 completion criteria | Approved artifacts/migrations/tests | clean checkpoint, two final builds, full regressions | Reproduced. |

## Known nonblocking limitations and exclusions

- The restaurant-wide advisory lock serializes bookings and coordinated writers. This preserves correctness but limits burst throughput; later Flask must implement the bounded retry policy. Evidence shows no invalid committed state.
- Exact general 30-table heterogeneous/equal subset allocation is CPU-intensive (~1.0 s client observed); production one-table/all-table cases are fast-pathed. The 30-table Version 1 bound keeps it finite and exact.
- Population invariants and IANA timezone membership are readiness/controlled-operation checks rather than impossible cross-row CHECK constraints.
- PostgreSQL does not implement full email syntax, confirmation matching, HTTP/user messaging, or Unicode-aware request normalization; later approved Flask work owns them.

DB-07 introduces no authentication, profile prefill/update workflow, cancellations/status, admin management, holds/waitlist/slot ledger, selected/shared/adjacent tables, active flags or table 31, holiday/overnight/multiple periods, histories/audit timestamps, confirmation delivery, persistent availability/candidates/ranks/seeds, purge/archive, Flask, REST, or React.

## Approval checkpoint

No blocking correctness, atomicity, security, reproducibility, or contract defect remains. DB-07 is ready for explicit approval at Hard Gate 1. It is not approved until Abdul explicitly approves it. Approval authorizes only the next increment, **API-01 — Backend Operation Inventory**, a design-only inventory; it does not by itself authorize Flask implementation, REST-contract design, or React work.
