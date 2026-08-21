# Cafe Fausse API-01 Backend Operation Inventory

**Document version:** 1.0.1
**Date:** 2026-08-21  
**Roadmap increment:** API-01 - Backend Operation Inventory  
**Status:** Approved  
**Author:** Codex, prepared for Abdul  
**Approval record:** Approved by Abdul on 2026-08-21. This approval authorizes only API-02 REST Contract Design. It does not authorize Flask implementation, React work, integration work, or PostgreSQL changes.

## 1. Executive summary

Version 1 needs seven conceptual Flask-facing operations:

1. obtain the current reservation context;
2. obtain daily provisional availability;
3. look up a customer's current newsletter status;
4. set a newsletter preference;
5. create or reconstruct a reservation;
6. report process liveness; and
7. report service readiness.

The current reservation context deliberately groups recurring hours, the five current reservation settings, restaurant-local date bounds, and capacity-derived party limits. Those facts share one public discovery use case, one read-only foundation privilege boundary, one freshness rule, and one unusable-foundation failure boundary. The other concerns remain separate because they have materially different inputs, mutation, retry, privacy, or infrastructure exposure.

This inventory is implementation-neutral. It defines no route, HTTP method, URL/query syntax, serialized field name, payload schema, status code, public error identifier, Flask architecture, dependency, or React implementation. PostgreSQL remains authoritative for persistence, current configuration, provisional availability, final booking decisions, concurrency, exact retry, and allocation.

No stop condition was found. The approved PostgreSQL layer supports all seven operations without a schema, routine, grant, transaction, or frozen-contract change.

## 2. Authority and accepted baseline

Sources were applied in the required order:

1. `docs/SRS(1).pdf`, read in full (SRS FR-01 through FR-18 and NFR-01 through NFR-12);
2. `docs/Rubric(1).pdf`, read in full, including the score-5, working-form, full-stack integration, direct-database-effect, and demonstration expectations;
3. `docs/approved-design-artifacts/Cafe_Fausse_Project_Requirements_Addendum.md`, version 2.2.1;
4. `docs/approved-design-artifacts/Cafe_Fausse_DB01_Persistent_Data_Requirements_Analysis.md`, version 1.2.1;
5. `docs/approved-design-artifacts/Cafe_Fausse_DB02_Conceptual_Data_Model.md`, version 1.2;
6. `docs/approved-design-artifacts/Cafe_Fausse_DB03_Logical_PostgreSQL_Schema.md`, version 1.1;
7. `docs/approved-design-artifacts/Cafe_Fausse_DB04_Reservation_Transaction_and_Concurrency_Design.md`, version 1.1;
8. the DB-05 implementation and completion evidence;
9. the DB-06 implementation and completion evidence;
10. the DB-07 report, manual guide, README, verification assets, and Hard Gate 1 evidence;
11. `database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, approved and frozen version 1.0;
12. `docs/approved-design-artifacts/Cafe_Fausse_Least_to_Most_Implementation_Roadmap.md`, version 1.1.1;
13. `AGENTS.md`.

The Project Requirements Baseline version 1.0 was also used for baseline API-01 through API-07 and rubric identifiers RUB-01 through RUB-15.

Accepted facts are not reopened here: PostgreSQL 18.3 is the sole verified Version 1 target; `pgcrypto` is required; DB-01 through DB-07 and Hard Gate 1 were approved by Abdul on 2026-08-20; the PostgreSQL Contract for Flask v1.0 is frozen; migrations 001-011, six business tables, role/grant boundary, three production routines, `READ COMMITTED` booking transaction, advisory-lock strategy, exact allocation, retry behavior, and DB-07 conclusions are approved. General production allocation p95 of about 1.14-1.27 seconds and five/eight-request contention that may exceed two seconds are accepted inputs to later full-stack measurement, not Flask guarantees.

## 3. Scope and API-02 boundary

API-01 answers which operations later Flask work must provide, the business facts each accepts and returns, validation/normalization ownership, PostgreSQL interaction, conceptual outcomes, retry/idempotency/privacy rules, and future test cases.

API-01 does not select REST paths, HTTP methods, parameters, JSON names or shapes, HTTP statuses, public error codes, error envelopes, time serialization, retry headers, numeric application/HTTP timeouts, Flask modules, database driver, ORM, connection pool, logging library, authentication, React behavior, or executable tests. Those decisions remain assigned to API-02 and later increments.

## 4. Initial repository verification

| Check | Evidence and result |
|---|---|
| Initial worktree | `git status --short --branch` returned only `## main...origin/main`; no user changes existed. |
| Instructions | Repository-root `AGENTS.md` was present and read; no more-specific applicable instruction file was found. |
| Required sources | Every source listed in Section 2 exists at the exact repository path shown. |
| Versions | Addendum 2.2.1; DB-01 1.2.1; DB-02 1.2; DB-03 1.1; DB-04 1.1; roadmap 1.1.1; PostgreSQL contract 1.0. |
| Hard Gate 1 | `database/DB07_VERIFICATION_REPORT.md` records approval by Abdul on 2026-08-20 and authorizes only API-01 after separate instruction. |
| Frozen contract | `database/POSTGRESQL_CONTRACT_FOR_FLASK.md` records the same approval/date and freezes signatures, outcomes, grants, retry, and transaction semantics. |
| Implementation match | Migrations 007-009 contain the same three production signatures/result shapes; migration 009 grants their execution to `cafe_fausse_app`; migration 004 grants the documented foundation reads. Contract outcome/detail literals match migrations 007-008. |
| Runtime reads | `cafe_fausse_app` has `SELECT` on `customers`, `reservation_configuration`, `restaurant_operating_hours`, and `restaurant_tables`. |
| Runtime denials | It has no business-table DML, no reservation/assignment reads, no sequence/DDL/reset/test/helper path, and no direct configuration writer. |
| Backend state | `backend/` exists and is empty; no unapproved Flask implementation is present. |
| API boundary | Roadmap API-01 is design-only. API-02, which alone selects the REST contract, requires API-01 approval. |

The wording that production Flask uses the three production controlled operations is reconciled with the explicit foundation `SELECT` grants as follows: writes, provisional availability, and reservation persistence use only the three routines; the four foundation relations remain authorized read-only sources for context, status lookup, and readiness. No direct reservation or assignment access is permitted.

## 5. Version 1 workflow inventory

| Workflow | Required operation path | Orchestration rather than another business operation |
|---|---|---|
| Home/reservation discovery | OP-01 | React may choose which returned facts to display; PostgreSQL facts remain current snapshots. |
| Reservation slot discovery | OP-01 -> OP-02 | Party/date changes invalidate a prior selection and cause a later refetch; this is future React/Flask orchestration. |
| Reservation identity/preference synchronization | OP-03 | Debouncing and stale-response suppression belong to later React work. An indeterminate lookup does not block booking with no preference change. |
| Reservation booking | OP-05, optionally preceded by OP-01/OP-02/OP-03 | Selection/review/refresh are orchestration; OP-05 does not trust OP-02. |
| Lost/ambiguous booking response | Repeat OP-05 with the same ordinary business facts | PostgreSQL reconstructs an exact committed reservation or evaluates a new request; clients never supply a fingerprint or idempotency key. |
| Independent subscribe/unsubscribe | OP-03 when appropriate -> OP-04 | OP-04 is authoritative even if lookup was skipped or became stale. |
| Infrastructure supervision | OP-06 and OP-07 | Liveness and readiness remain distinct so a live process can truthfully report a database-backed service as not ready. |

### 5.1 Reservation discovery and booking sequence

| Step | Owner |
|---|---|
| Obtain current hours/settings/date and party limits | OP-01 |
| Accept restaurant-local date and party size | Future client collection; Flask syntax validation in OP-02 |
| Return all legitimate aligned starts and provisional state | OP-02 |
| Select one displayed available start | Future React; never authoritative |
| Normalize customer/contact facts | Flask responsibility within OP-03/OP-05 |
| Synchronize newsletter status | OP-03; failure may yield indeterminate state |
| Submit authoritative booking | OP-05 with `no_change` when the user made no reliable preference choice |
| Reconstruct a committed exact retry | OP-05 |
| Return confirmation or safe outcome | OP-05 |
| Refresh after stale/full result | Future client orchestration invokes OP-02 again; no availability is persisted |

### 5.2 Independent newsletter sequence

Flask normalizes first name, optional middle initial, last name, email, confirmation email, and Boolean preference. OP-03 may read the current state. OP-04 sets the requested final Boolean through the controlled routine and preserves new-unselected/no-customer, identity conflict, idempotency, concurrency, and safe retry behavior.

### 5.3 Service supervision sequence

OP-06 answers only whether the Flask process can respond. OP-07 separately checks database connectivity and the minimum frozen-contract prerequisites. A live process may therefore be not ready without disclosing why to an untrusted caller.

## 6. Minimum operation catalogue

| ID | Stable conceptual operation | Kind | Initiator/consumer | Approved justification |
|---|---|---|---|---|
| OP-01 | Obtain current reservation context | Read-only snapshot | Public client; home/reservation discovery | SRS FR-02, FR-06/FR-07; PRA-006 to PRA-012, PRA-015 to PRA-017, PRA-023, PRA-025, PRA-029 |
| OP-02 | Obtain daily provisional availability | Frozen read-only routine | Public client; slot discovery | SRS FR-06 to FR-08, FR-18; PRA-006 to PRA-018, PRA-023, PRA-025, PRA-029 |
| OP-03 | Look up customer newsletter status | Read-only snapshot | Public client; both forms | SRS FR-06, FR-15 to FR-18; PRA-019, PRA-020, PRA-023 to PRA-025 |
| OP-04 | Set newsletter preference | Frozen controlled transaction | Public client; dedicated preferences form | SRS FR-15 to FR-18; PRA-019 to PRA-024 |
| OP-05 | Create or reconstruct reservation | Frozen controlled transaction | Public client; reservation submit/retry | SRS FR-06 to FR-09, FR-17/FR-18; PRA-006 to PRA-025 |
| OP-06 | Check process liveness | Process-local technical check | Infrastructure supervisor | Roadmap API-01 required health/readiness concern; API-04 later implementation; reliable deployment support |
| OP-07 | Check service readiness | Read-only technical check | Infrastructure supervisor | Roadmap API-01 required health/readiness concern; API-04 later implementation; DB-07 gate and frozen deployment contract |

## 7. Minimization analysis

| Choice | Advantages | Costs | Decision |
|---|---|---|---|
| Separate hours and configuration/limits | A home-hours consumer can request less data; failures can be named separately. | Duplicates public discovery calls and can produce mismatched snapshots of schedule versus limits. | Rejected. |
| Combined current reservation context | One coherent discovery result and unusable-state boundary; supports home and reservation consumers; no extra authority or mutation. | A home-only consumer may receive harmless additional public facts. | Selected as OP-01. Independent component validity remains observable internally without exposing diagnostics. |
| Combine context and daily availability | One client call. | Mixes input-free/current data with party/date-specific, potentially costlier provisional calculation and different caching/freshness/failure behavior. | Rejected; OP-02 remains separate. |
| Combine status lookup and preference setting | Fewer names. | Turns a side-effect-free debounced check into a mutation-capable concern and obscures indeterminate lookup handling. | Rejected. |
| Separate reservation creation and exact retry | Appears explicit. | Would require a client retry key or reservation identifier and would contradict the frozen ordinary-resubmission design. | Rejected; both are OP-05 outcomes. |
| Combine liveness/readiness | One technical operation. | Cannot distinguish a responsive process from inability to serve database workflows. | Rejected; OP-06 and OP-07 remain separate. |

## 8. Complete per-operation specifications

### 8.1 OP-01 - Obtain current reservation context

| Item | Specification |
|---|---|
| Purpose and workflow | Supply current recurring hours, current reservation policy, and derived public limits for home/reservation discovery. |
| Traceability | SRS FR-02, FR-06/FR-07; NFR-05/NFR-06/NFR-09; RUB-01/RUB-05/RUB-06; baseline API-03/API-06/API-07; PRA-006 to PRA-012, PRA-015 to PRA-017, PRA-023, PRA-025, PRA-029; DB-03 Sections 5.2-5.4; contract privilege boundary. |
| Initiator/consumer | Unauthenticated public client; home hours and reservation input setup. |
| Conceptual inputs | None. No client-supplied date, configuration, capacity, or timezone fact. |
| Provenance | Hours/settings/capacities are PostgreSQL-current; local current date and inclusive maximum date are server-derived using database time/timezone; total capacity and maximum party size are PostgreSQL-derived. |
| Flask normalization | None for caller input. Preserve ISO weekday 1-7 and restaurant-local wall-clock semantics; do not substitute process/browser timezone. |
| Flask validation | Require exactly one usable configuration row, weekdays exactly 1-7 with one same-day interval each, a PostgreSQL-valid timezone, and exactly 30 positive-capacity table rows. Never fabricate defaults. |
| PostgreSQL interaction | Direct read-only `SELECT` from `cafe_fausse.reservation_configuration`, `cafe_fausse.restaurant_operating_hours`, and `cafe_fausse.restaurant_tables`, authorized by migration 004; use database clock/timezone for date bounds. Do not read customers/reservations/assignments. |
| Transaction character | One short read-only snapshot/statement composition. |
| Successful result | Seven weekday opening/closing facts; current interval, duration, advance window, lead time, and timezone; current restaurant-local minimum/maximum reservable dates; total capacity and equal maximum party size. Table-level inventory is not returned. |
| Outcomes | Successful read; invalid/unusable database configuration; database unavailable/timeout; unexpected internal failure. |
| Retry/idempotency | Side-effect free. Bounded technical retry is safe within the overall deadline; every attempt re-reads all current facts. Caller repetition is safe. |
| Privacy/minimization/logging | Accepts/returns no PII. Logs may record operation/category/timing, not connection strings, SQL, or credentials. |
| Freshness | A snapshot, not a promise. Later reads may reflect prospective changes; OP-02 and OP-05 re-read authoritative facts. No application constant or durable cache may become authoritative. |
| Unit cases | UT-01 group in Section 17. |
| PostgreSQL integration cases | IT-01 to IT-04 and IT-16 in Section 18. |
| Exclusions | No schedule/configuration editing, table inventory administration, holiday/closed-day/multiple-period support, or reservation guarantee. |

### 8.2 OP-02 - Obtain daily provisional availability

| Item | Specification |
|---|---|
| Purpose and workflow | Return every legitimate aligned start for a restaurant-local date and party size, including unavailable starts. |
| Traceability | SRS FR-06 to FR-08/FR-18; NFR-02/NFR-05/NFR-06; RUB-05 to RUB-07; baseline API-03/API-05 to API-07; PRA-006 to PRA-018, PRA-023, PRA-025, PRA-029; DB-04 Section 7; frozen contract availability operation. |
| Initiator/consumer | Unauthenticated public client after party/date selection. |
| Conceptual inputs | Requested restaurant-local calendar date and party size only. |
| Provenance | Caller supplies date/party; Flask validates their basic types; PostgreSQL supplies local/canonical interval facts and provisional state from current data. |
| Flask normalization | Parse an unambiguous calendar date without applying browser timezone. Party size must be an integer, not a numeric string with loss or fractional value. |
| Flask validation | Reject malformed date/party before SQL. A current maximum may assist early validation, but PostgreSQL remains authoritative for current range/window/lead/configuration. |
| PostgreSQL interaction | Execute exactly `cafe_fausse.provisional_availability(date, integer)`. Stable outcomes: `slots`, `invalid_request`, `invalid_database_configuration`; details: `date_or_party_size_out_of_range`, `incomplete_foundation_population`, `invalid_timezone`. |
| Transaction character | Read-only statement snapshot; no booking lock and no persistence. |
| Successful result | For each legitimate start: restaurant-local wall time, canonical start/end instants, and provisional available/unavailable state. Preserve all rows, including false states. |
| Outcomes | Successful snapshot; validation failure; invalid/unusable configuration; database unavailable/timeout; unexpected failure. No-capacity is represented by legitimate rows marked unavailable, not by persisting a full state. |
| Retry/idempotency | Side-effect free; bounded retry/caller repetition is safe, but a new result may differ. |
| Privacy/minimization/logging | Return no customer, reservation, assigned/free table, candidate, rank, random, or unnecessary capacity fact. Log only coarse date/party validation category and timing; no PII. |
| Freshness | Immediate snapshot only. Available does not mean held or guaranteed. OP-05 always revalidates. |
| Unit cases | UT-02 group in Section 17. |
| PostgreSQL integration cases | IT-05 to IT-07, IT-16, and IT-17 in Section 18. |
| Exclusions | No holds, waitlist, selection of tables, slot persistence, or alternate allocator. |

### 8.3 OP-03 - Look up customer newsletter status

| Item | Specification |
|---|---|
| Purpose and workflow | Support the approved pre-submission preference synchronization without retrieving a profile or mutating a customer. |
| Traceability | SRS FR-06, FR-15 to FR-18; NFR-06; RUB-05/RUB-06; baseline API-03/API-04/API-06/API-07; PRA-019, PRA-020, PRA-023 to PRA-025; contract foundation-read grant. |
| Initiator/consumer | Unauthenticated public client after valid identity facts are available in either form. |
| Conceptual inputs | First name, optional middle initial, last name, email, and confirmation email. No phone is needed because phone is not identity. |
| Provenance | Caller supplies values; Flask creates normalized names/middle/canonical email and compares confirmation; PostgreSQL supplies any matching row's stored name/middle/current Boolean. |
| Flask normalization | Trim/collapse names; validate 1-100 and Unicode-letter rule; preserve display spelling; normalize optional middle to one uppercase alphabetic character without period; trim/validate/lowercase email and compare normalized confirmation. |
| Flask validation | Complete request-shape/format validation before lookup; reject identifiers, phone-based identity, malformed email, or mismatched confirmation. |
| PostgreSQL interaction | Read only `cafe_fausse.customers` by exact canonical `email`, authorized by migration 004. Read only first name, middle initial, last name, and `newsletter_subscribed`; use case-insensitive normalized first/last comparison. Omitted input middle matches either stored state; supplied middle matches stored equal, is accepted without mutation when stored is blank, and conflicts when both populated/different. |
| Transaction character | One short read-only snapshot. |
| Successful result | Minimal workflow state: matching customer and current Boolean, or no existing customer. Generic identity mismatch does not reveal which name component differed. |
| Outcomes | Matching subscribed; matching unsubscribed; no customer/not applicable; generic identity mismatch; middle-initial conflict; Flask validation failure; technical indeterminate lookup; unexpected failure. |
| Retry/idempotency | Side-effect free. A bounded technical retry is safe. Caller may repeat; state may change concurrently. Booking may proceed after indeterminate lookup only with newsletter action `no_change`. |
| Privacy/minimization/logging | Return no name spelling, email, phone, customer ID, reservations, or contact/profile data. Do not log raw names/email/confirmation; a one-way diagnostic correlation, if later approved, is not a client identity mechanism. |
| Freshness | Current snapshot only. OP-04/OP-05 remain authoritative and return current committed state. |
| Unit cases | UT-03 group in Section 17. |
| PostgreSQL integration cases | IT-08 to IT-10 and IT-16 in Section 18. |
| Exclusions | No customer creation, middle/phone population, preference mutation, prefill, account ownership, or arbitrary profile lookup. |

### 8.4 OP-04 - Set newsletter preference

| Item | Specification |
|---|---|
| Purpose and workflow | Set an explicit final subscribe/unsubscribe Boolean for the dedicated newsletter workflow. |
| Traceability | SRS FR-15 to FR-18; NFR-02/NFR-05/NFR-06; RUB-05 to RUB-07; baseline API-04 to API-07; PRA-019 to PRA-024; DB-04 customer/newsletter concurrency; frozen contract preference operation. |
| Initiator/consumer | Unauthenticated public client using the dedicated preferences form. |
| Conceptual inputs | First name, optional middle initial, last name, email, confirmation email, and explicit Boolean preference. |
| Provenance | Caller supplies intent/identity; Flask normalizes/validates and discards confirmation; PostgreSQL resolves/creates/updates and returns authoritative state. |
| Flask normalization | Apply the shared name/middle/email/confirmation rules in Section 12. |
| Flask validation | Require explicit Boolean, complete identity, matching confirmed canonical email, and no phone or client identifiers. |
| PostgreSQL interaction | Execute exactly `cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)`. Stable outcomes: `subscribed`, `unsubscribed`, `no_customer_no_change`, `invalid_request`, `customer_identity_mismatch`, `middle_initial_conflict`. |
| Transaction character | One controlled volatile transaction serialized by canonical email and customer row. |
| Successful result | New or existing current Boolean plus whether no customer/no change applied. Repeated current-state requests succeed idempotently. |
| Outcomes | Successful subscribed/unsubscribed; idempotent current state; no customer/not applicable; generic identity mismatch; middle conflict; validation failure; retryable transient conflict; retry exhaustion/timeout/indeterminate commit; unexpected failure. |
| Retry/idempotency | For SQLSTATE `55P03`, `40P01`, or `40001`, retry the complete transaction, at most three total attempts within one deadline, with bounded backoff/jitter and fresh reads. Final-state set semantics make caller resubmission safe after ambiguous outcome. |
| Privacy/minimization/logging | Confirmation email is never passed/persisted. Return only authoritative Boolean/minimal outcome. Do not expose stored identity/contact fields or mismatch cause. Redact PII and SQL diagnostics. |
| Freshness | Returned state is authoritative at commit but may be changed by a later valid operation; last committed valid set wins. |
| Unit cases | UT-04 group in Section 17. |
| PostgreSQL integration cases | IT-11 to IT-13, IT-16, and IT-18 in Section 18. |
| Exclusions | No phone/profile update, subscriber/history store, verification, message delivery, or audit event. |

### 8.5 OP-05 - Create or reconstruct reservation

| Item | Specification |
|---|---|
| Purpose and workflow | Perform the sole authoritative booking write path and reconstruct a prior committed reservation on exact retry. |
| Traceability | SRS FR-06 to FR-09, FR-17/FR-18; NFR-02/NFR-05/NFR-06; RUB-01/RUB-05 to RUB-07; baseline API-03/API-05 to API-07; PRA-006 to PRA-025; DB-04 Sections 3-20; frozen contract booking operation. |
| Initiator/consumer | Unauthenticated public client submitting or safely resubmitting ordinary reservation facts. |
| Conceptual inputs | Normalized first/optional middle/last name; canonical email plus transient confirmation; optional validated phone; selected restaurant-local start plus explicit selected UTC offset; party size; newsletter action subscribe/unsubscribe/no change. |
| Provenance | Caller supplies ordinary facts; Flask normalizes/validates/compares confirmation; PostgreSQL resolves customer, timezone instant, end, fingerprint, current rules, overlap, capacity, allocation, identity, and current newsletter state. |
| Flask normalization | Apply every shared rule in Section 12, including local-start/offset handling. Never accept or generate database identity, end, fingerprint, duration, table, availability, capacity, or configuration facts. |
| Flask validation | Validate request shape and syntax before SQL. Early context checks aid users but do not replace locked PostgreSQL validation. |
| PostgreSQL interaction | First execute exactly `cafe_fausse.book_reservation(text,text,text,text,text,timestamp without time zone,smallint,integer,text)` at `READ COMMITTED`. Stable outcomes: `booked`, `booked_phone_notice`, `exact_retry`, `same_customer_overlap`, `customer_identity_mismatch`, `middle_initial_conflict`, `unavailable`, `invalid_request`, `invalid_database_configuration`. Frozen details are `requires_read_committed`, `invalid_normalized_input`, `configuration_row_count`, `operating_hours_population`, `restaurant_table_population`, `invalid_timezone`, `nonexistent_local_start`, `ambiguous_local_start`, `utc_offset_mismatch`, `date_outside_booking_window`, `insufficient_same_day_lead`, `start_before_opening`, `misaligned_start`, `end_after_closing`, `duration_or_party_size_out_of_range`, `no_capacity_sufficient_combination`, and `time_boundary_crossed_during_booking`. After `booked`, `booked_phone_notice`, or `exact_retry`, use the existing migration-004 authorized read of `cafe_fausse.customers` by the same canonical email and project only stored `first_name`, `middle_initial`, and `last_name`. These database strings and columns remain internal traceability facts, not public field/error identifiers. |
| Transaction character | Each booking attempt is one controlled atomic transaction; the routine call is the only statement in its explicit caller transaction or runs in autocommit. Commit a returned result; after exception roll back before any retry. Only after a successful booking or exact-retry result, perform the separate minimal read-only customer-name lookup; it neither changes nor extends the booking transaction. |
| Successful result | Confirmation reference; customer display name composed deterministically from the stored first name, optional middle initial, and last name obtained by the post-success canonical-email read; immutable restaurant-local/canonical start/end; party size; all sorted assigned table numbers; current newsletter state; optional differing-phone notice; and fixed SRS restaurant address/phone. The stored name is used for both a new booking and an exact retry, so a resubmission with different accepted letter casing reconstructs the same authoritative display spelling rather than echoing request casing. Do not claim delivery. |
| Internal-only result facts | Contract `fingerprint_version` and `reservation_fingerprint` are database evidence/recovery internals. They are not required public confirmation facts, client identifiers, or caller inputs. Exact `outcome`/`detail_code` strings are database-to-Flask contract facts; API-02 will decide their public representation. |
| Outcomes | New success; success with phone notice; exact-retry success; validation/configuration failure; generic identity/middle conflict; same-customer overlap; authoritative unavailable/stale; transient SQL conflict; retry exhaustion; timeout; ambiguous commit; unexpected failure. |
| Retry/idempotency | Retry only `55P03`, `40P01`, `40001` as complete transactions, at most three total attempts in one deadline, with bounded backoff/jitter and fresh authoritative reads. Exact retry is success and performs no newsletter/contact mutation. Ordinary resubmission is safe after unknown commit. |
| Privacy/minimization/logging | Confirmation email never reaches PostgreSQL. The post-success name read projects only stored first name, optional middle initial, and last name. Return no customer ID, email, phone, profile data, fingerprint, free/candidate tables, capacity internals, unrelated customer facts, or SQL diagnostics. Logs minimize/redact all PII and never record confirmation email or secrets. |
| Freshness | OP-02 is never trusted. A successful commit/exact retry returns durable reservation/assignment facts; newsletter state is current at transaction time and may later change independently. |
| Unit cases | UT-05 group in Section 17. |
| PostgreSQL integration cases | IT-14 to IT-21 in Section 18. |
| Exclusions | No client table choice, reservation lookup, cancellation/change, messaging, payment, hold, waitlist, or direct reservation/assignment query. |

### 8.6 OP-06 - Check process liveness

| Item | Specification |
|---|---|
| Purpose and workflow | Tell infrastructure whether the Flask process can respond, independently of database readiness. |
| Traceability | Roadmap API-01 required health/readiness concern; roadmap API-04 later implementation; NFR-06/NFR-09; technical necessity for reliable deployment. |
| Initiator/consumer | Infrastructure supervisor, not a customer workflow. |
| Conceptual inputs/provenance | None; process-local state only. |
| Flask normalization/validation | None. The check must remain lightweight and nonbusiness. |
| PostgreSQL interaction | None. This is the one operation with no database source. |
| Transaction character | No database transaction. |
| Successful result | Live/not live indication only; no build, environment, dependency, or diagnostic inventory. |
| Outcomes | Process live or no response/unexpected process failure. It never claims database readiness. |
| Retry/idempotency | Side-effect free and safely repeatable. |
| Privacy/freshness | Return/log no secrets or customer data. It reflects only the current process response. |
| Unit/integration cases | UT-06 and IT-22 in Sections 17-18. |
| Exclusions | No database query, migration, reset, detailed diagnostics, or business dependency check. |

### 8.7 OP-07 - Check service readiness

| Item | Specification |
|---|---|
| Purpose and workflow | Tell infrastructure whether the live service can safely serve the frozen PostgreSQL-backed workflows. |
| Traceability | Roadmap API-01 required health/readiness concern; roadmap API-04 later implementation; DB-07 Hard Gate 1; PostgreSQL Contract lifecycle/readiness; NFR-05/NFR-06/NFR-09. |
| Initiator/consumer | Infrastructure supervisor. Public exposure, if any, remains minimal and is decided later. |
| Conceptual inputs/provenance | None from caller. Deployment connection and database facts are server-controlled. |
| Flask normalization/validation | None for caller. Internally compare exact target 18.3 and required frozen object/population expectations. |
| PostgreSQL interaction | Nonmutating connection/catalog/foundation checks: exact server version 18.3; `pgcrypto`; schema accessibility; exact production routine signatures and effective execution privilege; direct read access to the four foundation tables; one valid configuration row/timezone, weekday identities 1-7, exactly 30 positive-capacity tables. Catalog access uses PostgreSQL system catalog/introspection available to the connected role; business-state checks use the migration-004 `SELECT` grants. Do not call either write routine. |
| Transaction character | Short read-only technical check. Full `verify.ps1`, test bookings, resets, migrations, performance probes, and DB-07 re-execution are deployment tooling, not readiness requests. |
| Successful result | Ready/not ready only, optionally with a coarse nonsecret category for trusted infrastructure; API-02 decides representation/exposure. |
| Outcomes | Ready; database unavailable/timeout; wrong target; missing/inaccessible schema/extension/routine; unusable foundation population/configuration; unexpected failure. |
| Retry/idempotency | Side-effect free and repeatable. Brief bounded connection retry may occur within one readiness deadline; no mutation/ambiguous commit exists. |
| Privacy/minimization/logging | Response reveals no role names unless operationally necessary, connection strings, credentials, SQL, versions beyond the approved public target, stack traces, business rows, or customer facts. Internal logs may record a coarse failed check and redacted technical exception. |
| Freshness | Point-in-time readiness only. Startup/deployment checks do not replace per-operation validation. |
| Unit/integration cases | UT-07 and IT-23 to IT-25 in Sections 17-18. |
| Exclusions | No destructive action, seed, reset, migration, full verification, performance benchmark, test booking, or internal diagnostic endpoint. |

Conceptual check timing is intentionally narrow: each OP-06 probe performs only the process-local liveness check; each OP-07 probe establishes current connectivity and rechecks the minimum version, extension/object access, routine privilege, and foundation usability facts above. Startup may use the same OP-07 result to remain unready until dependencies work, but a startup success is not permanent proof. Migrations, guarded rebuild, `verify.ps1`, full tests, query plans, and performance measurements are deployment/gate tooling only and never run from a health operation.

## 9. Operation-to-PostgreSQL contract mapping

| Operation | Exact authorized source/path | PostgreSQL authority retained | Prohibited bypass |
|---|---|---|---|
| OP-01 | Read `reservation_configuration`, `restaurant_operating_hours`, and aggregate `restaurant_tables` under migration-004 `SELECT` grants | Current settings/hours/capacity and database clock | Flask constants, direct writes, table-level exposure |
| OP-02 | `cafe_fausse.provisional_availability(date, integer)` | Current rule/clock/inventory/reservation calculation and canonical interval facts | Flask-generated authoritative slots; reads of reservations/assignments |
| OP-03 | Read `customers` by canonical `email` under migration-004 `SELECT`; project only name/middle/current Boolean needed for matching | Persisted identity spelling and current newsletter Boolean | Profile lookup, customer identifier, mutation |
| OP-04 | `cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)` | Customer create/reuse, email serialization, identity/middle rule, current Boolean, atomicity | Direct customer DML or second subscriber store |
| OP-05 | `cafe_fausse.book_reservation(text,text,text,text,text,timestamp without time zone,smallint,integer,text)`, followed only after `booked`, `booked_phone_notice`, or `exact_retry` by the migration-004 authorized `customers` read using canonical email and projecting stored first/middle/last name | Routine retains every final business validation, customer concurrency, fingerprint, retry identity, overlap, exact allocation, assignments, optional update, newsletter atomicity, and commit/rollback; `customers` remains authoritative for display spelling | Direct reservation/assignment access, Flask allocation/retry identity, or reading customer ID/email/phone/profile data for confirmation |
| OP-06 | No PostgreSQL interaction | Not applicable | Treating liveness as database readiness |
| OP-07 | Read-only connection/system-catalog privilege/object checks plus the four permitted foundation reads | Installed/versioned deployment and current usable foundation state | Calling mutating routines, admin/test helpers, or exposing diagnostics |

The controlled production routine result shapes remain internal database-to-Flask facts. Quoting them in this document does not select public serialized fields or error identifiers.

## 10. Conceptual input provenance matrix

| Business fact | Operations | Caller supplied | Flask normalized/derived | Server current | PostgreSQL derived | Never accepted from caller |
|---|---|---:|---:|---:|---:|---:|
| First/last name | OP-03/04/05 | Yes | Yes | - | Match/preserve | - |
| Optional middle initial | OP-03/04/05 | Yes | Yes | - | Match/conflict/populate per operation | - |
| Email and confirmation | OP-03/04/05 | Yes | Canonicalize and compare | - | Email resolves customer; confirmation never sent | - |
| Optional phone | OP-05 only | Yes | Validate/display-preserve; digits for transient comparison | - | Populate/preserve/notice | - |
| Explicit newsletter Boolean | OP-04 | Yes | Type validation | - | Final state | - |
| Booking newsletter action | OP-05 | Yes | Enumerated business intent validation | - | Applied only for new commit | - |
| Requested local date/party | OP-02 | Yes | Syntax/type validation | - | Current-range/capacity validation | - |
| Selected local start/UTC offset/party | OP-05 | Yes | Syntax and unambiguous representation | - | Timezone round-trip and final validation | - |
| Current hours/settings/table capacities | OP-01/02/05/07 | No | - | - | Yes | Yes |
| Current local date/time | OP-01/02/05 | No | Presentation may use result | Database clock | Yes | Yes |
| Customer/reservation identifiers | None as input | No | No | - | Server/database managed | Yes |
| Fingerprint/version | None as input | No | No | - | Server/database managed | Yes |
| End/duration/availability/capacity/table choice | None as input authority | No | May present current result | - | Yes | Yes |

## 11. Conceptual result-fact catalogue

| Fact group | Produced by | Later consumer need | Exposure boundary |
|---|---|---|---|
| Seven recurring weekday rules | OP-01 | Hours display and reservation context | Weekday plus local opening/closing only; no history |
| Current five settings | OP-01 | Valid-choice presentation and interpretation | Current public business limits, not editing controls |
| Local date range/total capacity/max party | OP-01 | Date and party controls | Derived aggregate only; no table rows |
| Daily start intervals and provisional state | OP-02 | Slot schedule | All legitimate rows; no free tables/candidates/reservations |
| Minimal status-match state/current Boolean | OP-03 | Checkbox synchronization/recovery | No profile/contact or mismatch cause |
| Authoritative preference state | OP-04 | Dedicated form confirmation | Boolean plus minimal operation outcome |
| Stable booking confirmation | OP-05 | Distinct confirmation view/retry recovery | Reference; stored first/optional middle/last name from the post-success canonical-email read; start/end; party; all tables; newsletter; phone notice; fixed contact facts. Stored spelling, not resubmitted casing, is authoritative on exact retry. |
| Database fingerprint facts | OP-05 contract only | Internal trace/recovery evidence | Not needed by public client; never an identity mechanism |
| Live/ready state | OP-06/07 | Infrastructure | Minimal status; no internals |

## 12. Flask normalization and validation catalogue

| Rule | Flask responsibility | PostgreSQL authority/defense | Operations |
|---|---|---|---|
| Required names | Require first/last; trim and collapse internal whitespace; 1-100 characters; at least one Unicode letter; preserve punctuation, accents, and display spelling | Persisted length/coarse checks; case-insensitive stored matching under controlled behavior | OP-03/04/05 |
| Name matching | Supply approved normalized display values; never overwrite based on case variants | Match first/last case-insensitively for the customer resolved by canonical email | OP-03/04/05 |
| Middle initial | Optional; trim; accept one alphabetic character with optional period; normalize uppercase without period | Omission preserves; blank stored may be populated only in mutating paths; populated conflict rejects | OP-03/04/05 |
| Email | Require; trim; full syntax validation; maximum 254; lowercase canonical | Exact unique canonical identity and persisted canonical defense | OP-03/04/05 |
| Confirmation email | Require on both user-facing forms; apply same normalization and require equality | Never passed to a routine or persisted | OP-03/04/05 |
| Phone | Optional reservation-only; allow digits/spaces/plus/parentheses/hyphens/periods; require 7-15 digits; derive digits transiently for comparison | New/existing blank may populate on successful new booking; omission preserves; differing populated stays unchanged with notice | OP-05 |
| Party size | Require a true integer; reject fractional/non-numeric form; current OP-01 maximum may aid early feedback | Final range uses current sum of all 30 positive capacities; actual combination required | OP-02/05 |
| Local date | Parse as restaurant-local calendar date without browser/host conversion | Database clock/timezone, inclusive window, and same-day lead are current authority | OP-02 |
| Local start and offset | Require an unambiguous selected local wall time and explicit selected UTC offset in minutes | PostgreSQL rejects nonexistent/ambiguous local time, offset mismatch, window/lead/alignment/open/close violations, and derives end | OP-05 |
| Duration/latest start | Never accept from client or store in Flask | Current duration and hours derive end/latest start; booking preserves committed interval | OP-01/02/05 |
| Newsletter semantics | OP-04 requires an explicit Boolean. OP-05 accepts exactly subscribe, unsubscribe, or no change; indeterminate lookup leads to no change | Controlled routines apply current-state and exact-retry nonreplay rules | OP-04/05 |
| Client assertions | Reject customer/reservation IDs, fingerprints, tables, calculated end, duration/configuration/capacity values, availability assertions, candidate/rank/seed, or current newsletter assertions as authority | Database generates/re-reads all such facts | All applicable |

React may duplicate syntax checks and constrain controls for usability, but those checks are non-authoritative. Flask owns request-shape and Unicode-aware normalization. PostgreSQL owns current business validation and every transaction-dependent invariant.

## 13. Outcome and failure taxonomy

`A` means an automatic internal retry is safe only within the applicable bounded deadline; `C` means caller resubmission is safe, though current business results may differ.

| Conceptual category | Operations | Class | A | C | May state have committed? | Facts later API design must preserve | Never disclose |
|---|---|---|:---:|:---:|---|---|---|
| Successful read | OP-01/02/03/07 | Success | - | Yes | No | Current/snapshot nature and minimal facts | SQL, rows beyond result, diagnostics |
| Successful new reservation | OP-05 | Success | - | Yes | Yes | Stable confirmation and current newsletter | Customer ID/fingerprint/candidates |
| Successful exact retry | OP-05 | Success-existing | - | Yes | Existing prior commit | Same confirmation, current newsletter, no mutation replay | Fingerprint mechanics |
| Successful preference set/current state | OP-04 | Success | - | Yes | Yes, or idempotent no-op | Authoritative Boolean | Stored identity/contact |
| No customer/no change | OP-03/04 | Not applicable | - | Yes | No | No existing customer/current false workflow meaning | Whether any unrelated data exists |
| Generic identity mismatch | OP-03/04/05 | Business conflict | No | Only with corrected matching identity | No attempted mutation | Generic conflict only | Which stored field/value differed |
| Middle-initial conflict | OP-03/04/05 | Business conflict | No | Only with corrected matching value/omission where allowed | No attempted mutation | Conflict category | Stored initial |
| Differing-phone booking notice | OP-05 | Success with notice | - | Yes | Booking committed | Stored phone unchanged; booking facts | Stored phone |
| Pre-database validation failure | OP-02/03/04/05 | Validation | No | After correction | No | Affected conceptual input/rule | Stack trace/library details |
| Invalid/unusable database configuration | OP-01/02/05/07 | Service/configuration failure | No until repaired | Not usefully | No attempted booking/preferences from returned failure | Safe temporary/unready meaning | Population contents, SQL, role/grants |
| Same-customer overlap | OP-05 | Business conflict | No | With nonoverlapping facts | No attempted mutation | Conflict and ability to choose another time | Existing reservation facts |
| Stale/no capacity-sufficient combination | OP-02/05 | Unavailable | No | Yes after refresh | No failed-attempt state | Snapshot/stale meaning and refreshed choice | Free tables/candidates/ranks |
| Transient PostgreSQL conflict | OP-04/05; possibly reads | Transient technical | Yes | Yes | Failed transaction did not commit | Temporary uncertainty/retry context | SQLSTATE publicly, locks/SQL |
| Bounded retry exhaustion | OP-04/05 | Transient technical | No more in operation | Yes | No failed attempt; an earlier ambiguous connection case may be unknown | Safe retry later; do not claim definitive booking failure if unknown | Attempts/backoff internals |
| Operation timeout before known commit | All DB operations | Indeterminate/technical | Depends on classification/deadline | Yes; OP-05 exact recovery, OP-04 set semantics | Mutating call may have committed if connection/commit result unknown | Ambiguity and safe resubmission | Connection/driver internals |
| Database unavailable | OP-01 to OP-05/07 | Technical/unready | Brief bounded retry if deadline permits | Yes later | Normally no; unknown only if during a mutation commit | Temporary failure/unready | Credentials, host topology, stack |
| Unexpected internal failure | All | Unexpected | Only if explicitly classified transient | OP-04/05 safe ordinary resubmission; reads repeatable | Mutations rolled back unless commit ambiguous | Safe generic failure/ambiguity | SQL, stack, PII, secrets |
| Service not ready | OP-07 | Technical state | Check may repeat | Yes | No | Not-ready only | Specific sensitive cause |
| Process live | OP-06 | Success technical | - | Yes | No | Liveness only | Internals/version/config |

No HTTP representation or final user wording is selected here.

## 14. Retry, timeout, idempotency, and ambiguous commit boundary

1. PostgreSQL SQLSTATE `55P03`, `40P01`, and `40001` are the frozen automatic-retry classes.
2. A controlled mutating operation receives no more than three complete transaction attempts in one overall operation deadline.
3. Each retry starts a new transaction, reacquires locks, and re-reads configuration, hours, inventory, customer state, reservations, and assignments as the routine requires.
4. Backoff is short, bounded, exponential, and jittered. There is no unbounded loop.
5. A returned validation, identity, middle conflict, overlap, unavailable, or invalid-configuration outcome is not automatically retried.
6. OP-04 uses idempotent final-state set semantics; resubmission after a timeout is safe.
7. OP-05 uses ordinary business facts as retry identity. If a prior attempt committed, PostgreSQL returns `exact_retry`; if it rolled back, the repeated request is freshly evaluated.
8. Once `exact_retry` is established, the submitted newsletter action is never replayed; current newsletter state is returned.
9. A lost connection during commit is ambiguous. Flask must neither announce success nor claim definitive failure without an authoritative returned result. Caller resubmission is the recovery path.
10. Read operations are side-effect free and repeatable, but later snapshots can legitimately differ.
11. API-02 will define wire-level retry/ambiguity semantics. API-03 will select the numeric application deadline, driver behavior, and implementation placement. API-09 and INT-07 will measure them. No HTTP timeout or retry header is chosen here.

## 15. Data minimization, privacy, and safe logging

| Operation | Minimum accepted/read | Minimum returned | Later safe logging | Prohibited |
|---|---|---|---|---|
| OP-01 | Three foundation sources and database time | Public hours/settings/aggregates | Outcome, duration, coarse readiness category | Table rows, SQL/connection data |
| OP-02 | Date/party plus routine's internal current facts | Intervals/provisional flags | Outcome/timing and non-PII bounds category | Customers/reservations/free tables/candidates |
| OP-03 | Normalized identity; one customer projection by email | Match/no customer/mismatch/indeterminate and Boolean only on match | Outcome/timing; no raw identity | Profile, phone, IDs, activity/reservations |
| OP-04 | Normalized identity and Boolean; confirmation transient | Authoritative Boolean/minimal outcome | Outcome/timing/retry class; PII redacted | Confirmation email, stored name/email/phone, history |
| OP-05 | Normalized booking facts; confirmation transient | Approved confirmation/minimal failure | Outcome/timing/retry/notice and redacted correlation | Confirmation email, raw/canonical duplication, fingerprint, SQL, free/candidate data |
| OP-06 | Process state | Live only | Availability/timing | Configuration/environment dump |
| OP-07 | Catalog/privilege/foundation invariants | Ready/not ready | Coarse failed check/redacted exception | Credentials, connection string, SQL, role details, business/customer data |

Version 1 contains no password, authentication token, ownership-verification state, newsletter history, or customer activity-history workflow. Fingerprints remain database-managed retry aids, not client identifiers or secrets. Confirmation email is transient and is never persisted or logged. A single canonical email is stored; no raw/canonical duplicate is introduced.

## 16. Authorization and exposure statement

OP-01 through OP-05 are intentionally usable by a future unauthenticated public client after Flask validation because the approved reservation and newsletter workflows include no customer authentication or verified ownership. OP-06 and OP-07 are technical infrastructure operations; their future exposure must be limited to minimal nonsecret state, with readiness intended for infrastructure use.

Absence of authentication does not authorize direct database access, client-supplied customer/reservation identifiers, arbitrary profile/contact lookup, reservation lookup/administration, cancellation/modification/rescheduling, table choice/assignment control, destructive actions, or diagnostic disclosure. API-01 adds no API key, account, session, administrator, ownership verification, rate limit, or CAPTCHA requirement.

## 17. Non-executable unit-test inventory

These are design cases only. Executable automation belongs to the roadmap increments named in the final column.

| Group/operation | Required cases | Expected design result | Automation |
|---|---|---|---|
| UT-01 OP-01 context | Normal seven days; Monday-Saturday 17:00-23:00 and Sunday 17:00-21:00; alternate recurring schedule; incomplete/duplicate/unusable schedule; normal five settings; missing/invalid singleton; valid/invalid timezone; 30 x 4 gives total/max 120; unexpected count/nonpositive capacity; prospective later reads change while old reservations do not | One coherent current context or safe unusable-state failure; no fabricated constants/table details | API-04 foundation pieces, API-07 context integration, API-09 |
| UT-02 OP-02 availability | Valid future date/party; every legitimate aligned start; unavailable rows retained; weekday/Sunday latest starts; alternate hours/settings; exact/short same-day lead; both advance-window boundaries; malformed/out-of-range input; no available combination; stale snapshot label; no persistent slot/candidate data | Exact frozen-routine mapping and provisional-only semantics | API-07/API-09 |
| UT-03 OP-03 status | Existing subscribed/unsubscribed; nonexistent; case-insensitive name; generic first/last mismatch; omitted middle with stored; blank stored plus supplied without mutation; conflicting populated middle; malformed/noncanonical input; technical failure -> indeterminate; no contact/profile return/mutation | Minimal current status or safe category | API-05/API-09 |
| UT-04 OP-04 preference | New selected creates subscribed; new unselected creates none; matching existing subscribe/unsubscribe; same-state idempotency; generic mismatch; middle conflict; unique-email race category; transient retry eligibility; unexpected failure no partial state | Controlled set semantics and minimal result | API-06/API-09 |
| UT-05 OP-05 booking | Single/multi-table; differing phone success/notice/no overwrite; new booking confirmation name comes from stored first/middle/last; exact retry with different accepted request casing returns the same stored display spelling, same reservation confirmation/current newsletter, and no mutation; post-success name lookup projects no customer ID/email/phone/profile data; same-customer overlap; different-customer overlap with capacity; back-to-back; stale availability -> unavailable; party above current max; invalid local time/offset/window/lead/alignment/open/close; identity/middle conflicts; subscribe/unsubscribe/no-change; transient retry, exhaustion, timeout/loss before/after commit; unexpected failure no partial state; complete confirmation/no delivery claim | Frozen routine outcome, deterministic authoritative-name reconstruction, and safe recovery mapping | API-08/API-09 |
| UT-06 OP-06 liveness | Live process with ready DB; live process with unavailable DB | Both report live because DB is deliberately excluded | API-04/API-09 |
| UT-07 OP-07 readiness | Ready DB; unavailable DB; wrong/unsupported target versus exact PostgreSQL 18.3; missing/inaccessible schema/routines/extension; unusable foundation; safe nondiagnostic failure; no mutation | Ready only when frozen prerequisites are usable | API-04/API-09 |

## 18. Non-executable PostgreSQL-integration test inventory

Every row defines fixture, operation, exact source, outcome, persisted state, unchanged facts, and later automation owner.

| ID | Initial fixture | Operation/source | Expected category | Expected persistent state | Must remain unchanged | Automation |
|---|---|---|---|---|---|---|
| IT-01 | Clean normal seed | OP-01; three foundation reads | Successful context | None | All business rows | API-07/API-09 |
| IT-02 | Alternate seven-row recurring schedule | OP-01; hours read | Successful changed context | Test writer change only | Existing reservations/assignments | API-07; restore SRS seed |
| IT-03 | Alternate permitted scalar settings | OP-01; configuration read | Successful changed limits | Test writer change only | Existing bookings | API-07; restore defaults |
| IT-04 | Modified positive capacities across exactly 30 tables | OP-01; table aggregate | Changed derived total/max | Test writer change only | Existing party/interval/assignments | API-07; restore 30 x 4 |
| IT-05 | Empty date with normal seed | OP-02; `provisional_availability` | Slots with current flags | None | All rows | API-07 |
| IT-06 | Free/partial/full overlapping assignments and back-to-back intervals | OP-02; same routine | Correct available/unavailable rows | None | Reservations/assignments | API-07 |
| IT-07 | Alternate schedule/settings/capacities | OP-02; same routine | Slots reflect current facts | None | Old booking facts | API-07; restore fixtures |
| IT-08 | Existing subscribed/unsubscribed customer | OP-03; customer `SELECT` | Matching current status | None | Customer/contact/reservations | API-05 |
| IT-09 | No customer and name/middle mismatch variants including blank optional value | OP-03; customer `SELECT` | No customer, generic mismatch, middle conflict, or accepted blank case | None | Every business row | API-05 |
| IT-10 | Database read failure | OP-03; denied/unavailable simulated connection | Indeterminate | None | Every business row | API-05/API-09 |
| IT-11 | No customer; selected/unselected | OP-04; `set_newsletter_preference` | Subscribed or no-customer/no-change | One subscribed customer or none | No reservations/assignments | API-06 |
| IT-12 | Existing matching/mismatch/middle variants | OP-04; same routine | Subscribed/unsubscribed/idempotent/conflict | Boolean/middle only per approved path | Name, phone, reservations | API-06 |
| IT-13 | Concurrent matching new customer and preference writes | OP-04; same routine through app role | Stable serialized outcomes/transient retry | One customer; last valid commit wins | No duplicates/history | API-06/API-09 |
| IT-14 | Empty target interval with eligible single/multi combinations | OP-05; `book_reservation`, then canonical-email `customers` projection of first/middle/last | Booked/phone notice with stored display name | One customer, reservation, complete winning assignments, applicable newsletter | Existing customer protected fields; name read exposes no ID/email/phone/profile facts | API-08 |
| IT-15 | Exact first result deliberately ignored/lost; repeat uses accepted casing variants of the same first/last name | Repeat OP-05; same routine, then the same minimal canonical-email name read | Exact-retry success with the original stored display spelling | Exactly original rows; current newsletter and stored name read | Contact/name/newsletter action not replayed; no non-name customer facts exposed | API-08 |
| IT-16 | Execute as `cafe_fausse_app` | OP-01 to OP-05 approved paths | Permitted results | Only controlled OP-04/05 writes | No direct DML | API-09 |
| IT-17 | Attempt app direct reservation/assignment read and direct business DML | No public operation; privilege proof | Denied | None | All business data | API-09 |
| IT-18 | Preference-vs-booking same email concurrently | OP-04 and OP-05 controlled routines | Serialized stable outcomes/retry if needed | One customer; booking atomic; last valid preference commit wins | No history/duplicates | API-09 |
| IT-19 | Same-customer overlap, different customers, full/fragmented, back-to-back | OP-05 | Overlap/unavailable or valid booked | Only permitted winners complete | No overbooking/partial assignment | API-08/API-09 |
| IT-20 | Inject or induce `55P03`, `40P01`, `40001` | OP-04/05 full-operation retry | Success/stable business outcome or retry exhaustion | At most one logical effect | No failed-attempt partial state | API-09 |
| IT-21 | Connection loss before/during/after commit, with an accepted casing variant on ordinary repeat | OP-05 then ordinary repeat and post-success minimal name read | New/unknown then exact retry or fresh current result; success uses stored display spelling | Zero or one logical reservation, never duplicate | Name/contact/newsletter nonreplay after exact commit; no customer ID/email/phone/profile exposure | API-08/API-09 |
| IT-22 | Live Flask process with ready/unavailable DB fixture | OP-06; no SQL | Live in both | None | All data | API-04 |
| IT-23 | Normal DB-07 baseline | OP-07; read-only catalog/foundation checks | Ready | None | All data | API-04/API-09 |
| IT-24 | Missing/unusable foundation or privilege/routine/extension fixture in isolated DB | OP-07 | Not ready | None | No repair/mutation attempted | API-04/API-09 |
| IT-25 | Wrong server target relative to exact 18.3 | OP-07 | Not ready | None | Database untouched | API-04/API-09 |

All database-changing fixture cases use isolated test data and restore alternate hours, settings, and capacities. Final assertions prove no duplicate customer, duplicate logical reservation, overlapping assigned table, overbooking, partial assignment, or persisted provisional availability/candidate/retry/random data.

## 19. Layer responsibility matrix

| Behavior/fact | PostgreSQL | Flask in later API increments | React later | Later contract/integration |
|---|---|---|---|---|
| Persisted data, constraints, uniqueness | Authoritative | Invoke permitted paths only | None | Verify end to end |
| Current settings/hours/table capacities | Authoritative foundation rows | OP-01 read/derive and safe mapping | Display server facts | Freshness/performance validation |
| Provisional availability | Exact current derivation in routine | Validate shape, invoke, minimize result | Present all starts/status | API-02 representation; INT-03 proof |
| Final booking validation | Locked routine authority | Supply normalized input; never trust snapshot | Submit ordinary facts | API-08/INT-04/05 |
| Customer create/reuse and newsletter concurrency | Controlled routine authority | Normalize and map outcomes | Collect/present | API-05/06/08 and INT-02/04 |
| Fingerprint/exact retry | Generate, store, verify, reconstruct | Ordinary resubmission and outcome mapping | Resubmit ordinary facts only | API-02 retry contract; INT-05 |
| Same-customer overlap | Enforce under lock | Safe conflict result | Present recovery | Integration concurrency proof |
| Exact exclusive allocation | Derive/rank/randomly select/commit | No allocation logic | No table choice | Confirmation presentation only |
| Transaction/locks/retryable SQL outcomes/atomicity | Authoritative | Full-attempt bounded retry and transaction discipline | Pending state is UX only | API-03 implementation decision; API-09 proof |
| Request shape/Unicode syntax | Defense-in-depth constraints only | Authoritative application validation | Immediate usability validation | Contract cases in API-02 |
| Confirmation email equality | None/persist nothing | Authoritative transient check | Collect twice | Verify nonpersistence/log redaction |
| Restaurant contact facts | Not required as business persistence | Compose fixed SRS address/phone for confirmation as later design chooses | Display | API-02 representation |
| Error containment/logging | Stable internal outcomes/rollback | Safe mapping and redacted technical logs | Friendly/accessibility behavior | API-03 library/format; API-09 evidence |
| Liveness/readiness | Readiness facts only | OP-06/07 composition | None | API-04 implementation |
| REST syntax/HTTP semantics | None | None in API-01 | Consume later contract | API-02 decides |
| End-to-end performance | Database evidence is an input | Flask contribution measured later | Client/network contribution measured later | API-09 and INT-07 decide acceptance |

## 20. Performance and freshness assessment

- OP-01 and OP-03 are narrow foundation reads and are expected to be relatively inexpensive. OP-06 is process-local. OP-07 is a short read-only dependency check, not DB-07 verification.
- OP-02 and OP-05 use exact PostgreSQL logic over no more than 30 Version 1 tables. OP-05 is coordinated by the approved restaurant-wide lock.
- DB-07 measured availability and ordinary/fast-path outcomes below the proposed 1,000 ms database p95, while general production equal/heterogeneous allocation measured p95 1,265.04/1,135.29 ms. These measurements are database/reference-host evidence, not Flask or public guarantees.
- Five-request contention has exceeded two seconds in recorded runs; the eight-request targeted group and individual p95 exceeded two seconds. The accepted coarse lock prioritizes correctness and explainability.
- API-09 and integration performance work must measure normalization, validation, connection acquisition, transaction/retries/backoff, serialization, Flask scheduling, network, and client costs in addition to PostgreSQL.
- The SRS NFR-02 two-second expectation remains unproven end to end. If approved contention exceeds it, correctness, atomicity, no double/overbooking, and safe outcomes remain mandatory; a new lock/allocator requires separately approved design change.
- OP-01, OP-02, OP-03, OP-06, and OP-07 return current snapshots. OP-04 returns a committed current preference that a later valid operation can change. OP-05 new/exact results contain durable reservation identity/interval/party/assignments, while returned newsletter state is only current at that transaction.
- No caching, queue, hold, waitlist, alternate allocator, or new coordination strategy is authorized.

## 21. Traceability matrices

### 21.1 SRS workflows and database-applicable fields

| SRS ID and actual requirement | API-01 operation coverage | Disposition |
|---|---|---|
| FR-01 name; FR-03 imagery/theme; FR-04 navigation; FR-05 menu | None | Static/UI requirements; do not create backend business operations. |
| FR-02 specified address/phone/hours | OP-01 supplies authoritative hours; OP-05 confirmation composition may use fixed SRS address/phone | Address/phone presentation is later UI/API representation. |
| FR-06 reservation fields: time slot, guests, customer name, email, optional phone | OP-01/02/03/05 | Structured name and confirmation email are approved additive refinements; OP-05 accepts the business facts. |
| FR-07 selected slot valid and available | OP-02 provisional discovery; OP-05 final authority | PostgreSQL satisfied integrity; Flask normalization/mapping later. |
| FR-08 random table from 30 when available | OP-05 | Frozen database routine performs exact minimum-table/least-waste/random-tie allocation across 30. |
| FR-09 success or full/error result | OP-05, with OP-02 refresh | Conceptual categories defined; wording/HTTP deferred. |
| FR-10 to FR-14 About/Gallery/awards/reviews | None | React/content-only; no operation invented. |
| FR-15 newsletter form with proper email validation | OP-03/04 | Flask normalization catalogue covers syntax/confirmation; form is React later. |
| FR-16 submitted newsletter emails stored | OP-04; OP-05 booking-linked action | Customer is the sole current source; new-unselected exception follows approved PRA. |
| FR-17 Customers/Reservations minimum fields | OP-03/04/05 use approved additive PostgreSQL representation | Schema satisfied in DB-07; no direct reservation read exposed. |
| FR-18 Flask inserts customer, checks availability, assigns table, returns confirmation/error | OP-02/04/05 | PostgreSQL owns mutation/allocation; future Flask invokes/maps instead of reproducing. |
| NFR-01, NFR-03/04, NFR-07/08, NFR-10/11 | None directly | UI/load/compatibility requirements deferred to React/integration. |
| NFR-02 forms within two seconds | OP-02/04/05 performance boundaries | DB-07 limitation preserved; API-09/INT-07 measure end to end. |
| NFR-05 integrity/no double or overbooking | OP-05 frozen controlled path; OP-02 nonpromise | PostgreSQL authority preserved; integration must not bypass. |
| NFR-06 user-friendly failures | All outcome-producing operations | Conceptual safe categories defined; final wording/accessibility/API semantics deferred. |
| NFR-09 modular/well documented | Seven bounded operations with one authority each | Architecture/code documentation still API-03 onward. |
| NFR-12 HTTP/HTTPS REST | None selected | API-02 defines REST; deployment/integration later. |

### 21.2 Rubric traceability

| Baseline rubric ID / wording | API-01 disposition |
|---|---|
| RUB-01 all SRS requirements | Every API-applicable workflow is mapped; UI/deployment items are explicitly deferred, not claimed complete. |
| RUB-02 five React/JSX pages | Not API-01 applicable; no operation added. |
| RUB-03 excellent UI/UX; RUB-04 Flexbox/Grid | React/UI phase. |
| RUB-05 required forms correctly implemented and working | OP-02 through OP-05 define the backend capabilities those forms need; implementation remains later. |
| RUB-06 Flask/PostgreSQL correctly integrated with React for reservation/newsletter | Operation-to-contract mapping prevents bypass; API/UI/integration gates remain. |
| RUB-07 demo includes functionality, direct database effects, sophisticated logic | OP-04/05 retain controlled database effects and exact allocation/retry outcomes; final demo is INT-09. |
| RUB-08 to RUB-15 recording/submission/repository obligations | Delivery-only; no backend operation justified. |

### 21.3 Roadmap API-01 requirement coverage

| Roadmap requirement | Coverage |
|---|---|
| FR-02 | OP-01 hours and OP-05 fixed contact confirmation composition |
| FR-06 to FR-09 | OP-01/02/03/05 complete discovery, identity, booking, confirmation/failure path |
| FR-15/FR-16 | OP-03/04 plus booking-linked OP-05 |
| FR-18 | OP-02/04/05 invoke frozen PostgreSQL authority |
| NFR-02 | Retry/deadline/performance boundary without unsupported guarantee |
| NFR-05 | No direct persistence bypass; booking controlled routine only |
| NFR-06 | Complete conceptual outcome taxonomy and safe disclosure |
| NFR-09 | Stable minimal catalogue, matrices, test plans, and exclusions |

### 21.4 Baseline API-01 through API-07

| Baseline ID | Requirement | API-01 disposition |
|---|---|---|
| API-01 | Backend implemented with Python Flask | Operations are Flask-facing; implementation is API-04 to API-08, not begun. |
| API-02 | RESTful reservation/newsletter endpoints | Workflows inventoried; endpoint contract explicitly deferred to roadmap API-02. |
| API-03 | Accept details, insert/reuse customer, validate/allocate/persist, return result | OP-02/03/05; PostgreSQL performs controlled mutation/allocation. |
| API-04 | Accept newsletter input, validate, persist | OP-03/04 and shared normalization. |
| API-05 | Process forms within two seconds under approved conditions | Measurement deferred; DB-07 limitations and later gates preserved. |
| API-06 | User-friendly failures | Outcome categories/minimization defined; words/HTTP deferred. |
| API-07 | Integrate PostgreSQL and React | Every operation maps to database source and future consumer; implementation/integration later. |

### 21.5 PRA-006 through PRA-025 and PRA-029

| PRA | Coverage |
|---|---|
| PRA-006 | OP-01 current interval; OP-02 aligned slots; OP-05 final alignment. |
| PRA-007 | OP-01 duration; OP-02/05 derived complete occupancy; committed interval immutable. |
| PRA-008 | OP-01 seven-day recurring schedule; no holiday exceptions. |
| PRA-009 | OP-01 opening/derived limits; OP-02 legitimate starts; OP-05 closing authority. |
| PRA-010 | OP-01 derived inclusive date range; OP-02/05 current validation. |
| PRA-011 | OP-01 lead setting; OP-02/05 database-clock enforcement. |
| PRA-012 | OP-01 timezone; OP-02/05 restaurant-local/DST/offset semantics. |
| PRA-013 | OP-02/05 half-open intervals/back-to-back behavior. |
| PRA-014 | OP-05 exact retry before different same-customer overlap; safe ordinary resubmission. |
| PRA-015 | OP-01 derived maximum; OP-02/05 capacity-sufficient truth. |
| PRA-016 | OP-01/07 validate exactly 30; OP-05 allocates only current approved inventory. |
| PRA-017 | OP-01 derives current capacities; prospective changes flow to later reads. |
| PRA-018 | OP-05 exact exclusive one-or-more-table allocation; no customer table choice. |
| PRA-019 | OP-03/04/05 structured identity, optional fields, lookup synchronization, no auth. |
| PRA-020 | OP-03/04/05 use one customer Boolean; no subscriber/history source. |
| PRA-021 | OP-04/05 idempotency, email serialization, last valid commit, timeout retry. |
| PRA-022 | Explicitly no cancellation/modification/rescheduling operation. |
| PRA-023 | Section 12 authoritative normalization/validation plus OP-02 to OP-05 mapping. |
| PRA-024 | OP-05 complete confirmation/no delivery; all safe outcome/log boundaries. |
| PRA-025 | OP-01 -> OP-02 -> OP-03 -> OP-05 availability-first path, provisional/nonpromise/refresh behavior. |
| PRA-029 | OP-01 reads and delivers PostgreSQL current hours; OP-02/05 use them; no Flask/React constants. |

PRA-001 to PRA-005 govern ordering, least-to-most scope, testing, authority, and configurability and are honored by this design. PRA-026 to PRA-028 are already enforced by PostgreSQL and appear in freshness, exact retry, retention, exclusions, and test fixtures; they do not justify additional public operations.

### 21.6 Workflow and operation justification closure

| Required concern | Operation | Approved source/technical gate |
|---|---|---|
| Current hours/settings/derived limits | OP-01 | FR-02/FR-06/FR-07; PRA-006 to PRA-017/PRA-029 |
| Daily availability | OP-02 | FR-07/FR-18; PRA-025; frozen routine |
| Status synchronization | OP-03 | PRA-019/PRA-023/PRA-025; authorized customer read |
| Independent preferences | OP-04 | FR-15/FR-16; PRA-020/PRA-021; frozen routine |
| Booking/confirmation/exact retry | OP-05 | FR-06 to FR-09/FR-18; PRA-014/PRA-018/PRA-024; frozen routine |
| Process liveness | OP-06 | Roadmap API-01 required health/readiness concern; API-04 later implementation |
| Database-backed readiness | OP-07 | Roadmap API-01 required health/readiness concern; API-04 later implementation; DB-07/frozen deployment gate |

Every operation therefore has an approved user requirement or necessary technical-gate justification, and every Version 1 user workflow has a complete operation path.

## 22. Explicit Version 1 exclusions and rejected operations

The inventory contains no operation for authentication/login/logout/registration/password/session/verified ownership; profile retrieval/prefill/contact update; email verification; reservation lookup/cancellation/modification/rescheduling/no-show; administration of reservations/tables/configuration/schedules; table activation/adjacency/combinability/selection; waits/queues/holds/seat sharing; availability/slot/candidate persistence; holidays/exceptions/closed weekdays/overnight/multiple periods/history; newsletter history/audit; confirmation email/SMS; payment/menu ordering/loyalty/analytics; archive/purge/history browsing; generic audit; database reset/migration/seed/verification; raw SQL/roles/internal diagnostics; or more than 30 Version 1 tables.

| Considered operation | Rejection reason |
|---|---|
| Separate hours read | Grouped into OP-01 under identical public/read/freshness boundary. |
| Separate limits/capacity read | Derived within OP-01; no table-inventory exposure needed. |
| Latest-start calculation | Derived fact in OP-01/02, not an independent source or operation. |
| Availability refresh | Ordinary repetition of OP-02, not a new business action. |
| Free-table/candidate lookup | PostgreSQL internal allocation evidence; privacy and authority prohibit exposure. |
| Customer/profile retrieval | OP-03 returns only workflow status; profiles/authentication are excluded. |
| Customer creation/update | Creation/limited population occurs only inside OP-04/05 approved transactions. |
| Separate reservation retry/lookup | Exact retry is an OP-05 success from ordinary facts; public identifiers are not accepted. |
| Confirmation delivery | PRA-024/FE-011 explicitly exclude delivery. |
| Configuration/hours/table writer | Test/admin routines are denied to app and not customer workflows. |
| Database verification/reset | Deployment tooling only; not Flask operations. |
| Combined health check | Split into OP-06/07 to preserve truthful live-but-not-ready state. |

## 23. Decisions deferred by increment

| Increment | Decisions intentionally deferred |
|---|---|
| API-02 | REST paths/methods, URL/query usage, request/response serialized fields, status codes, public errors/envelope, exact time representation, public retry/ambiguity semantics, health/readiness wire exposure, privacy representation. |
| API-03 | Flask application/module design, database driver/access pattern, connection/pooling, configuration, transaction wrapper, numeric operation deadline/timeouts, retry implementation location, backoff values, logging library/format, fixtures/test framework. |
| API-04 | Executable foundation/connectivity/liveness/readiness and safe common errors/logging. |
| API-05 | Executable normalization/identity/status lookup. |
| API-06 | Executable independent preference behavior and timing evidence. |
| API-07 | Executable current-context/availability behavior and fixtures. |
| API-08 | Executable booking/confirmation/retry behavior. |
| API-09 | Full Flask verification, redaction, database integration, concurrency, and API performance gate. |
| React/UI | Component architecture, debounce timing, stale-response handling, wording, accessibility, presentation, state, routes. |
| Integration | CORS/base URLs, live composition, full-stack concurrency, browser/network costs, quantified NFR-02/other nonfunctional acceptance, final demo. |

## 24. DB-07 compatibility assessment

| Frozen DB-07 element | API-01 result |
|---|---|
| PostgreSQL 18.3/`pgcrypto` | Preserved; OP-07 treats exact target/extension as readiness facts. |
| Six tables and source-of-truth decisions | Preserved; reads use only authorized foundation sources. |
| Three production routines | Preserved exactly; no fourth write path or alternate booking query. |
| App role privileges | Preserved; no new grant. Direct reservation/assignment reads remain forbidden. |
| `READ COMMITTED`/restaurant and email locks | Preserved; OP-04/05 do not reproduce or reorder locking. |
| Exact allocator/random ties | Preserved inside PostgreSQL; no Flask candidate/table operation. |
| Fingerprint/exact retry | Preserved as server-managed OP-05 result behavior; no client key. |
| Three-attempt retry/SQLSTATE classes | Preserved without selecting application timing constants. |
| Performance envelope | Accurately carried forward; no stronger guarantee. |
| Coarse-lock contention limitation | Accepted and assigned to later full-stack validation; no redesign. |

The contract and implementation are compatible with every mandatory operation. No approved artifact or PostgreSQL object requires revision.

## 25. Unresolved issues

No API-01 blocker, frozen-contract contradiction, missing authoritative source, privilege gap, or required database change was found.

The wire/architecture/timing/presentation choices in Section 23 are deliberate roadmap deferrals, not unresolved API-01 business rules. They require their own later approval and do not block this inventory.

## 26. API-01 completion assessment

| Completion criterion | Assessment |
|---|---|
| Every Version 1 user workflow has a minimum operation path | Complete |
| Every operation has approved justification | Complete |
| Hours, context/limits, availability, status, preference, booking/retry, liveness/readiness covered | Complete |
| Every database-backed operation maps to authorized read/routine | Complete |
| OP-05 customer display name has one deterministic authorized source for new booking and exact retry | Complete: post-success `customers` read by canonical email projects stored first/middle/last only |
| No duplicated PostgreSQL authority/new source of truth | Complete |
| Inputs, normalization, results, outcomes, retries, privacy, tests defined | Complete |
| React/mobile/third-party ordinary clients need no integrity trust | Complete |
| PostgreSQL 18.3 baseline/performance limitations preserved | Complete |
| No endpoint/Flask/React/excluded implementation introduced | Complete |
| Contradictions escalated | Not applicable; none found |
| Approval pause before API-02 | Required and recorded below |

API-01 version 1.0.1 is ready for review. It is not approved merely by creation of this artifact.

## 27. Approval checkpoint

| Item | Value |
|---|---|
| Current increment | API-01 - Backend Operation Inventory |
| Current status | Ready for review; approval pending |
| Approver | Abdul |
| Approval effect | Authorizes API-02 REST Contract Design only |
| Not authorized | Flask implementation, API-03 or later work, React, integration, or PostgreSQL changes |

> **API-01 approval is required before API-02 may begin. Approval authorizes only API-02 REST Contract Design. It does not authorize Flask implementation, React work, or changes to the approved PostgreSQL layer.**
