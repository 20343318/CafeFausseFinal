# DB-07 PostgreSQL Verification and Hard Gate 1 Report

Date: 2026-08-20  
Baseline: `main` at `82ab9d1bb6b9363a84dc6b4828a96549f9045ed8`, initially clean and synchronized with upstream  
Scope: DB-07 only; no Flask, REST, React, or API-01 work

Status: Approved by Abdul at Hard Gate 1 on 2026-08-20

## Executive assessment

The approved DB-05/DB-06 implementation reproduced from an empty isolated PostgreSQL 18.3 database and matched the approved DB-03/DB-04 architecture. DB-07 found one major privilege defect and one measured performance concern. Both were corrected by forward migrations, with migrations 001–009 preserved byte-for-byte. No approved table, column, constraint, index, fingerprint, locking, isolation, or allocation decision changed.

The final gate evidence consists of the DB-05/DB-06 regression tests, DB-07 catalog and behavior checks, role-denial tests, barrier-synchronized concurrency tests, rollback/failure injection, ambiguous-response recovery, rollback-safe query plans, and measured latency. The PostgreSQL Contract for Flask v1.0 is frozen in `POSTGRESQL_CONTRACT_FOR_FLASK.md`, and the PostgreSQL-only demonstration is in `DB07_MANUAL_DEMONSTRATION.md`.

## Initial read-only audit

- Authoritative files were present: SRS, rubric, Addendum 2.2.1, DB-01 1.2.1, DB-02 1.2, DB-03 1.1, DB-04 1.1, roadmap 1.1.1, and approved DB-05/DB-06 reports.
- Approved migration boundary was 001–009; all matched committed bytes and remain immutable.
- PostgreSQL 18.3 is the required, implemented, and verified Version 1 database version. `pgcrypto` is required; schema `cafe_fausse` and the owner/app/test non-login roles are the implemented boundary. Compatibility with other PostgreSQL versions is outside the verified Version 1 contract.
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

This targeted correction pass reran only affected evidence on a fresh disposable PostgreSQL 18.3 cluster. `rebuild.ps1` and `verify.ps1` passed with the exact 18.3 assertions; `performance_test.ps1 -Samples 20` passed after adding individual concurrent-request and general-production-booking measurements; the documented weekday/Sunday/opening/alignment SQL returned the exact expected outcomes; the deterministic capacity test returned `booked` with 30 assignments, then `unavailable` with rejected-state counts `0|0|0|0`; and a final rebuild plus read-only verification restored the approved empty baseline. No schema object or migration changed.

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

Reference host: Windows 10 build 26100, Intel Family 6 Model 141, 8 logical processors, required PostgreSQL 18.3, local loopback, warm/mixed cache, 20 samples, one local `psql` process per observed call. Client-observed figures conservatively include process startup. Concurrent group duration runs from launching the first child through observing every child exit; individual-request duration is each child process's `ExitTime - StartTime`, so it includes connection/process startup, lock wait, database execution, and result delivery to local `psql`. A rollback-only 200-reservation history fixture was analyzed for plans.

Representative plan execution: canonical email 0.058 ms via `customers_email_uq`; fingerprint 0.025 ms via its lookup index; same-customer lookup 0.077 ms via `reservations_customer_interval_idx`; global interval 0.044 ms via `reservations_interval_idx`; assignment-by-table 0.040 ms via its index; free-table derivation 0.107 ms with the interval index. Sequential scans on deliberately tiny 30-row inventory are appropriate. Before fast paths, one general 30-table allocator plan executed in 934.386 ms. The exact fast paths cover sufficient-single-table and necessarily-all-table cases; general exact allocation remains the approved meet-in-the-middle implementation.

The targeted 20-sample rerun produced these client-observed p50/p95/p99 values (milliseconds):

| Operation/path | p50 | p95 | p99 |
|---|---:|---:|---:|
| Provisional availability day | 342.14 | 433.50 | 438.89 |
| General exact allocation, 30 equal-capacity tables | 813.50 | 863.08 | 892.64 |
| General exact allocation, 30 heterogeneous-capacity tables | 739.73 | 863.64 | 1,019.60 |
| Uncontended all-tables fast-path booking | 347.19 | 440.46 | 445.63 |
| Uncontended single-table fast-path booking | 352.64 | 454.32 | 490.48 |
| Production booking through general equal-capacity allocation | 1,124.99 | 1,265.04 | 1,370.08 |
| Production booking through general heterogeneous-capacity allocation | 1,015.54 | 1,135.29 | 1,157.33 |
| Exact retry | 347.00 | 446.20 | 471.41 |
| Same-customer overlap result | 338.95 | 427.58 | 445.07 |
| Unavailable/full result | 342.86 | 451.46 | 487.60 |
| Booking with 100 retained-history rows | 341.59 | 446.10 | 457.63 |

Concurrent evidence distinguishes group completion from individual child-request lifetime:

| Concurrent group | Metric | Observations | p50 | p95 | p99 |
|---|---|---:|---:|---:|---:|
| 2 requests | Group completion | 20 | 644.56 | 684.30 | 847.23 |
| 2 requests | Individual request | 40 | 548.26 | 673.23 | 826.81 |
| 5 requests | Group completion | 20 | 1,507.61 | 1,606.22 | 1,720.56 |
| 5 requests | Individual request | 100 | 936.26 | 1,528.69 | 1,591.50 |
| 8 requests | Group completion | 20 | 2,410.85 | 2,619.48 | 2,626.82 |
| 8 requests | Individual request | 160 | 1,423.82 | 2,397.74 | 2,600.18 |

All 300 concurrent requests in this rerun booked successfully (40/100/160 for groups 2/5/8), no retryable outcome occurred, and committed counts matched outcomes. The eight-request group and individual p95 exceed two seconds. Five-request contention is variable: the original gate recorded group p95 2,424.18 ms, and the first individual-latency rerun recorded group/individual p95 2,429.22/2,080.20 ms, all above two seconds; the final targeted rerun was below two seconds at 1,606.22/1,528.69 ms. Therefore five-request contention has exceeded two seconds in recorded evidence and cannot be represented as reliably below the SRS threshold.

The controlled timeout case separately observed 3,012.49 ms of waiter duration and 3,019.92 ms of holder lock-hold duration, consistent with the configured three-second booking lock timeout. That `55P03` transaction rolled back; the holder alone committed, and the final invariant check passed.

The proposed DB-07 budget of uncontended p95 below 1,000 ms is met by availability, ordinary outcome paths, and single/all-table fast-path production bookings, but it is **not met by every production allocation path**: full production bookings through the general equal-capacity and heterogeneous-capacity paths measured p95 1,265.04 ms and 1,135.29 ms. The budget remains a proposal rather than an approved guarantee, and these are documented exceptions. The approved restaurant-wide lock remains the Version 1 correctness strategy; five/eight-request throughput and latency require later full-stack validation. The approved 3-second lock timeout is classified separately as retryable and is not a successful latency result.

## Traceability matrix

The following tables identify every SRS and PRA requirement separately, including database-inapplicable requirements that remain assigned to later layers.

### SRS requirements

| ID | Applicability / later layer | Implementation object | Specific automated or repeatable evidence | Manual evidence | Result / limitation or deferral |
|---|---|---|---|---|---|
| FR-01 | React content only | None in PostgreSQL | DB-07 scope/exclusion audit | None at DB gate | Not database-applicable; React later. |
| FR-02 | Hours are database-applicable; address/phone display is later | `restaurant_operating_hours`; migration 003; availability/booking routines | `verify_db05.sql` `exact seven-row SRS operating-hours seed`; DB-06 weekday/Sunday closing cases | Foundation and schedule-boundary sections | Database schedule complete; React displays content through later Flask work. |
| FR-03 | UI imagery/theme only | None | DB-07 exclusion audit | None | React/content later. |
| FR-04 | UI navigation only | None | DB-07 exclusion audit | None | React later. |
| FR-05 | Menu content/UI only | None | DB-07 exclusion audit | None | React/content later. |
| FR-06 | Persistence/booking inputs apply; form is later | `customers`, `reservations`; `book_reservation` | DB-05 customer-column/constraint cases; DB-06 reservation column/type cases | Ordinary booking | Database representation complete; Flask/React own request/form behavior. |
| FR-07 | Validity/availability applies | Configuration, hours, tables, reservations/assignments; `provisional_availability`; booking revalidation | DB-06 `provisional availability exposes future bookable slots`, past-date, DST, alignment/duration and closing cases | Schedule-boundary and full-capacity sections | PostgreSQL complete; Flask exposes and React renders later. |
| FR-08 | Thirty-table exact/random assignment applies | `restaurant_tables`; `select_table_allocation`; `book_reservation`; migrations 003/006/008/011 | Seed verifier; allocator `minimum table count`, `least waste`, `production randomness`; single/multi/last-table concurrency | One-, multi-, and all-table bookings | PostgreSQL complete; later layers invoke/display. |
| FR-09 | Durable success/full outcomes apply; wording/display is later | Booking outcomes `booked`, `exact_retry`, `unavailable` | DB-06 authoritative-booking case; performance full outcome; last-table concurrency | Deterministic full-capacity section | Database outcomes complete; Flask/React message mapping later. |
| FR-10 | About content only | None | DB-07 exclusion audit | None | React/content later. |
| FR-11 | Founder/mission content only | None | DB-07 exclusion audit | None | React/content later. |
| FR-12 | Gallery imagery only | None | DB-07 exclusion audit | None | React later. |
| FR-13 | Lightbox interaction only | None | DB-07 exclusion audit | None | React later. |
| FR-14 | Awards/reviews content only | None | DB-07 exclusion audit | None | React/content later. |
| FR-15 | Preference identity/persistence applies; form syntax/UI later | `customers.email`, `newsletter_subscribed`; `set_newsletter_preference` | DB-05 email constraints; DB-06 standalone opt-in/out and newsletter concurrency | Customer/newsletter inspection | Database complete; Flask full syntax and React form later. |
| FR-16 | Database-applicable | Customer email/preference columns and controlled preference routine | DB-06 `standalone newsletter opt-in creates an identified customer`; unique-email concurrency | Newsletter inspection | Complete. |
| FR-17 | Database-applicable | Six-table schema; migrations 002/005 | DB-05 exact foundation columns; DB-06 exact reservation/assignment columns, types, constraints and indexes | Catalog inspection | Complete additive representation of SRS minimum fields. |
| FR-18 | PostgreSQL operations apply; Flask logic is later | Three production routines and six tables | DB-06 39-case suite; 75 concurrency scenarios; privilege denials | Booking/full/rollback demonstrations | PostgreSQL complete; Flask orchestration/response mapping deferred. |
| NFR-01 | Full website-load timing is not database-verifiable | Relevant indexes only | `query_plans_db07.sql` contribution evidence | None | Browser/network/full-stack measurement later. |
| NFR-02 | Reservation/newsletter form-submission performance; DB contribution applies | Production routines, indexes, performance harness | `performance_test.ps1 -Samples 20`, including production general paths and individual contention latency | Performance tables above | General production allocation exceeds proposed 1,000 ms p95 budget; contention can exceed SRS two seconds; full-stack validation later. |
| NFR-03 | UI usability only | None | DB-07 exclusion audit | None | React usability review later. |
| NFR-04 | Brand/UI design only | None | DB-07 exclusion audit | None | React/UI later. |
| NFR-05 | Reliability, integrity, prevention of double/overbooking | PK/FK/UQ/checks; restaurant/email locks; atomic booking | DB-06 overlap/assignment/rollback cases; 75 concurrency scenarios; committed-state verifiers | Half-open, full-capacity, rollback and concurrency sections | Complete at PostgreSQL layer; later integration must preserve contract. |
| NFR-06 | Stable failure classification applies; friendly messaging later | Routine outcome/detail codes and retryable SQLSTATEs | DB-06 invalid/readiness/rollback cases; concurrency `55P03`/`40P01` | Rejected schedule/full cases | Database classification complete; Flask/React wording/accessibility later. |
| NFR-07 | Browser compatibility only | None | DB-07 exclusion audit | None | React/browser matrix later. |
| NFR-08 | Responsive UI only | None | DB-07 exclusion audit | None | React/device testing later. |
| NFR-09 | Maintainability and documentation apply | Lexical migrations; scripts; README; report; contract; manual guide; named objects | `rebuild.ps1`, `verify.ps1`, `test.ps1`; static and immutable-migration audits | Guide/contract review | Complete for PostgreSQL; later modules need their own documentation. |
| NFR-10 | Cross-browser/mobile consistency only | None | DB-07 exclusion audit | None | React/full-stack later. |
| NFR-11 | React/CSS UI only | None | DB-07 exclusion audit | None | React later. |
| NFR-12 | HTTP/HTTPS and REST are outside DB-07 | Database contract only; no endpoints | Repository audit confirms no Flask/REST work | None | API design/implementation later; not claimed complete. |
| DB-01 | Persistent customer/reservation management applies | `cafe_fausse` schema and six tables | Clean rebuild; exact-table verifiers | Catalog inspection | Complete. |
| DB-02 | SRS Customers fields apply | Structured `customers` columns | DB-05 exact columns/constraints/behavior | Customer inspection | Complete through approved normalization. |
| DB-03 | SRS Reservations fields apply | `reservations` and normalized assignments | DB-06 exact columns/FKs/indexes | Reservation/assignment inspection | Complete; multiple assignment rows support larger parties. |
| DB-04 | Customer persistence during booking applies | `book_reservation` insert/reuse | New/reuse/identity/rollback cases; same-email concurrency | Booking and rejected-full state query | Complete and atomic. |
| DB-05 | Newsletter persistence applies | Customer Boolean and preference routine | Standalone opt-in/out and newsletter races | Newsletter inspection | Complete. |
| DB-06 | Integrity/no-overbooking applies | Constraints, locks, controlled routines | Overlap/allocation/rollback cases and 75 concurrency scenarios | Full/concurrency proof | Complete. |
| DB-07 | Rubric database-effect demonstration | Manual guide and test-role inspection | Repeatable manual SQL plus full gate | Ordinary/full/rollback sections | Complete at DB layer; final presentation later. |

Security evidence is not attributed to NFR-09. It traces to the DB-07 role/security gate and approved DB-03/DB-04 responsibility/capability decisions: migrations 004, 009 and 010; the DB-05 role/grant verifier; DB-06 routine ownership, search-path and grant checks; DB-07 current/future `PUBLIC` denials; and both runtime denial suites. Result: least-privilege boundary complete with no current bypass.

### PRA-001 through PRA-029

| ID | Applicability / responsibility | Implementation object | Specific automated or repeatable evidence | Manual evidence | Result / limitation or deferred layer |
|---|---|---|---|---|---|
| PRA-001 | Ordering/gate control | Repository DB-only boundary | Git path/status audit; no backend/frontend changes | Report scope | Complete; API-01/Flask/React not begun. |
| PRA-002 | Least-to-most database delivery | Versioned migrations; three production routines | Clean lexical rebuild in `rebuild.ps1` | Foundation steps | Complete for DB-07. |
| PRA-003 | Testing throughout | Verification, behavior, denial, concurrency, performance and plan files | `test.ps1`; 263 full-gate checks/scenarios | Manual guide | Complete, no skips. |
| PRA-004 | Authoritative baseline control | Migrations 001-011 and approved artifacts | Git immutable-boundary audit; exact catalog verifiers | Catalog inspection | Complete; migrations 001-011 unchanged in this pass. |
| PRA-005 | Configurable supplemental rules | Configuration, hours and tables | DB-05 configuration constraints; DB-06 alternate configuration/hour/capacity cases | Configuration/schedule inspection | Complete; no duplicate persistent constants. |
| PRA-006 | Start interval | `start_interval_minutes`; alignment validation | DB-05 permitted/invalid values; DB-06 15/60-minute cases | Manual 17:15 rejection | Complete. |
| PRA-007 | Duration/occupancy | Duration setting; immutable start/end; duration check | DB-06 60/90/120 and prospective-change cases | Closing-boundary demonstrations | Complete. |
| PRA-008 | Valid calendar dates/weekly schedule | Seven hours rows; no exceptions | Exact seed verifier; availability past-date case | Weekday/Sunday selection | Complete; holiday exceptions excluded. |
| PRA-009 | Opening/latest derived start | Hours plus duration/alignment validation | Weekday/Sunday closing cases | Opening, exact-close, after-close SQL | Complete. |
| PRA-010 | Advance window | Window constraint/default and routine validation | DB-05 range cases; DB-06 past/window availability | Availability query | Complete. |
| PRA-011 | Same-day lead | Lead constraint/default and database clock | DB-05 boundaries; DB-06 availability/booking boundary coverage | Availability query | Complete. |
| PRA-012 | Timezone/clock authority | Timezone setting; local candidates; timestamptz facts | Timezone catalogue verifier; DST nonexistent/ambiguous cases | Offset derived from authoritative slots | Complete; Flask supplies selected offset later. |
| PRA-013 | Half-open overlap | Immutable interval; strict predicates/indexes | `half-open interval predicate...`; committed overlap verifiers; back-to-back concurrency | Back-to-back/overlap | Complete. |
| PRA-014 | Duplicate/retry safety | Exact-identity UQ; fingerprint lookup; retry-before-overlap | Exact retry/collision; identical request 20 iterations; lost response | Repeat unchanged booking | Complete. |
| PRA-015 | Party bounds/derived capacity | Positive party check; capacity sums derived | Party bound and insufficient allocator cases | Party 120/rejected overlap | Complete. |
| PRA-016 | Thirty tables | Seeded table identities 1-30 | `exact 30 x 4 table seed`; readiness checks | Inventory aggregate | Complete. |
| PRA-017 | Individual capacities | Positive `seating_capacity`; controlled writer | Capacity constraints; prospective capacity and writer race | Inventory/full-capacity demo | Complete. |
| PRA-018 | Exclusive exact multi-table assignment | Assignment table; allocator; restaurant lock | Min-count/least-waste/random tests; single/multi/mixed/last-table races | Multi-table/all-30 demo | Complete; coarse-lock throughput limitation accepted. |
| PRA-019 | Identity/contact/preference | Canonical email, structured names, optional fields, controlled routines | Name/middle/phone cases; mismatch and blank-field races | Customer inspection | Database complete; full syntax/normalization remains Flask. |
| PRA-020 | Newsletter source of truth | Sole customer Boolean | Exact schema/no-extra-object verifiers; opt-in/out | Newsletter inspection | Complete; no subscriber/history table. |
| PRA-021 | Concurrent/retry-safe preference | Email advisory lock and preference routine | Newsletter race, same-email race, retry nonmutation | Retry/current preference | Complete; Flask bounded retry later. |
| PRA-022 | No cancellation/modification | No status/lifecycle columns or operations | No-unapproved-columns verifier; retained overlap behavior | Catalog/exclusions | Complete Version 1 exclusion. |
| PRA-023 | Authoritative validation | Constraints and current-fact routine revalidation | DB-05 constraint matrix; DB-06 invalid/boundary/readiness cases | Boundary/full rejection | Database defense complete; Flask/React validation later. |
| PRA-024 | Confirmation/error/log support | Stable results/outcomes/details and reservation ID | Success/retry/failure cases; contract audit | Booking outputs | Database facts complete; messages/logging later. |
| PRA-025 | Provisional availability/revalidation | Availability and authoritative booking routines | Provisional case; stale-availability concurrency | Availability then booking/full | Complete at DB layer; UI schedule later. |
| PRA-026 | Prospective changes/reset | Immutable bookings; controlled writers; guarded reset | Prospective configuration/hour/capacity cases; reset guard/rebuilds | Rebuild around demos | Complete. |
| PRA-027 | DB fingerprint/retry separation | Versioned fingerprint; SHA-256 helpers; nonunique index | Serialization verifier; collision/retry/lost-response cases | Repeat booking | Complete; clients never generate it. |
| PRA-028 | Retention until reset | No purge/archive; RESTRICT FKs; guarded reset | Retained-history fixture/behavior; reset guard | Final rebuild | Complete; no automatic deletion. |
| PRA-029 | PostgreSQL recurring hours | Dedicated table, exact seed, controlled writer | Seven-row verifier; alternate-hours/writer-race cases | Foundation/boundary sections | Complete; later layers must consume, not duplicate. |

### DB-03 logical-schema decisions

| DB-03 decision | Implementation | Specific evidence | Result |
|---|---|---|---|
| Six tables and every column/type/null/default (§§4-5) | Migrations 002/005 | DB-05 four exact-column cases; DB-06 exact six tables and reservation/assignment column/type cases | Exact match. |
| Primary/natural keys and RESTRICT FKs (§6) | Named PK/UQ/FK constraints | DB-06 exact constraint names and `all foreign keys use explicit restrict actions`; invalid FK/key cases | Complete. |
| Declarative and cross-row invariants (§7) | 31 named constraints plus booking postconditions | DB-05 81 assertions; DB-06 duration/party/fingerprint and committed-state cases | Complete. |
| Nullability/default catalogue (§8) | DDL in migrations 002/005 | Information-schema verifier rows and DB-05 null/default cases | Complete. |
| Five constraint plus seven access-path indexes (§9) | Migrations 002/005 | `exact nonredundant index set`; `query_plans_db07.sql` | Complete; no speculative index. |
| PostgreSQL/Flask responsibility (§10) | Controlled routines; denied direct app mutation | Runtime denial suites; contract operations/grants | PostgreSQL complete; Flask deferred. |
| Availability/overlap/retry support (§11) | Interval/fingerprint/customer indexes and assignments | Plans plus availability, collision, retry and overlap cases | Complete. |
| Normalization/authoritative homes (§12) | No duplicated schedule/capacity/newsletter/availability/candidate facts | Exact table/column verifier; no-unapproved-column case | Complete 1NF/2NF/3NF and source authority. |
| SRS minimum-field reconciliation (§13) | Structured customer and normalized assignments | Exact catalogue and manual row inspection | Complete additive compliance. |
| Role/default-privilege safety supporting schema boundary | Owner/app/test roles; migrations 004/009/010 | DB-05/06/07 privilege verifiers and 12 expected denials | Complete; security is not NFR-09. |

### DB-04 transaction and concurrency decisions

| DB-04 decision | Implementation | Specific evidence | Result / limitation |
|---|---|---|---|
| `READ COMMITTED` plus transaction restaurant lock (§3) | Booking core; `ADVISORY_LOCKS.md` | `requires_read_committed`; lock barriers and timeout scenario | Complete; coarse serialization retained. |
| Atomic new/retry boundary (§4) | Single controlled routine/subtransaction | Five rollback stages; exact-retry nonmutation | Complete. |
| Input/normalization boundary (§5) | Routine validation and constraints | DB-05 normalization; DB-06 identity/middle/phone cases | Database defense complete; full syntax remains Flask. |
| Deterministic lock order (§6) | Restaurant, ordered foundation/table, email and row locks | Writer/same-email races; forced deadlock classification | Complete. |
| Provisional nonpromise (§7) | Read-only availability routine | Availability case and stale-availability race | Complete. |
| Authoritative validation order (§8) | Locked re-read of current config/hours/tables | Boundary/readiness cases and three writer races | Complete. |
| Customer creation/reuse (§9) | Email lock plus unique key/row lock | Same-email 20 iterations, mismatch and blank-population races | Complete. |
| Fingerprint/retry/collision (§10) | Versioned SHA-256; nonunique lookup then tuple equality | Serialization, exact retry, collision, lost-response cases | Complete. |
| Same-customer overlap (§11) | Strict half-open check after retry | Overlap shapes and same-customer race | Complete. |
| Free-table exclusivity (§12) | Assignment/reservation overlap derivation | Last-table, single/multi/mixed races; committed-overlap verifier | Complete. |
| Exact ranking (§13) | Meet-in-the-middle plus exact fast paths | Min-table, least-waste, insufficient and DB-07 path tests | Semantics complete; general path exceeds proposed p95 budget. |
| Random tie/test seam (§14) | Random equal-best choice; restricted rank seam | Every-rank/random cases and app seam denial | Complete; no rank/seed persistence. |
| Configuration consistency (§15) | Coordinated controlled writers | Three writer races and prospective-change cases | Complete. |
| Newsletter in booking (§16) | Atomic action and independent email-locked writer | Newsletter rollback/race/retry-state cases | Complete. |
| Postconditions/rollback (§§17/19) | Capacity/fingerprint/assignment checks and injection seams | Five named rollback cases; no-missing-assignment verifier | Complete. |
| Retry recovery (§18) | 3-second timeout; `55P03`/`40P01`/`40001` contract | Timeout and forced-deadlock scenarios | DB classification complete; Flask retry later. |
| Network ambiguity (§20) | Ordinary exact resubmission | `connection loss after commit and ordinary resubmission` | Complete without client key. |
| Capability/privileges (§22) | `pgcrypto`; roles/grants; fixed search paths | Extension/routine/default-ACL verifiers and denials | Complete on required PostgreSQL 18.3 only. |
| Performance/explainability (§26) | Performance harness and plan fixture | `performance_test.ps1 -Samples 20`; `query_plans_db07.sql` | Correctness complete; general-path/contention limitations documented. |

### Rubric and approved implementation checkpoints

| Source | Implementation/evidence | Result |
|---|---|---|
| Rubric - complete SRS coverage | Individual SRS table and explicit later-layer deferrals | Complete for database-applicable scope without overclaim. |
| Rubric - Flask/PostgreSQL integration | Frozen contract and three controlled entry points | Database side ready; Flask later. |
| Rubric - sophisticated reservation logic | Exact allocation, random ties, collision-safe retry, concurrency and rollback | Complete at database layer. |
| Rubric - direct database effects/demo | Manual customer/newsletter/reservation/assignment and rollback queries | Repeatable without Flask. |
| DB-05 checkpoint | Clean 004 rebuild, 21 verifier checks, 81 behaviors, five denials | Reproduced. |
| DB-06 checkpoint | 25 verifier checks, 39 behaviors, seven denials, 75 concurrency scenarios | Reproduced. |

## Known nonblocking limitations and exclusions

- The restaurant-wide advisory lock serializes bookings and coordinated writers. This approved Version 1 strategy preserves correctness but limits contention throughput: five-request observations have exceeded two seconds, and the eight-request targeted p95 exceeded two seconds for group completion and individual requests. Later Flask must implement bounded retry and later full-stack work must validate the two-second expectation. No invalid committed state was observed.
- General exact 30-table allocation is CPU-intensive. Full production equal-capacity and heterogeneous-capacity booking paths measured p95 1,265.04 ms and 1,135.29 ms, above the proposed 1,000 ms database budget; single/all-table cases are fast-pathed. The 30-table Version 1 bound keeps the approved general algorithm finite and exact.
- Population invariants and IANA timezone membership are readiness/controlled-operation checks rather than impossible cross-row CHECK constraints.
- PostgreSQL does not implement full email syntax, confirmation matching, HTTP/user messaging, or Unicode-aware request normalization; later approved Flask work owns them.

DB-07 introduces no authentication, profile prefill/update workflow, cancellations/status, admin management, holds/waitlist/slot ledger, selected/shared/adjacent tables, active flags or table 31, holiday/overnight/multiple periods, histories/audit timestamps, confirmation delivery, persistent availability/candidates/ranks/seeds, purge/archive, Flask, REST, or React.

## Approval checkpoint

DB-07 was explicitly approved by Abdul at Hard Gate 1 on 2026-08-20. The approval accepts:

- PostgreSQL 18.3 as the required and verified Version 1 database;
- the PostgreSQL Contract for Flask v1.0;
- the documented database performance envelope and general exact-allocation p95 measurements;
- the documented coarse-lock contention limitation, including that five- and eight-request contention may exceed two seconds; and
- deferral of complete two-second form-submission validation to the later Flask and full-stack integration performance gates.

The performance limitations are accepted as nonblocking Version 1 tradeoffs because committed-state correctness, atomicity, retry safety, and prevention of double and overbooking remain intact.

Hard Gate 1 approval authorizes only **API-01 — Backend Operation Inventory**, a design-only increment. API-01 has not begun and requires a separate instruction. This approval does not authorize Flask implementation, REST-contract design, API-02 or later increments, React work, or changes to the approved PostgreSQL Contract for Flask v1.0.
