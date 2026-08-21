# Prompt 9 - Verify PostgreSQL and complete Hard Gate 1

Begin only **DB-07 - PostgreSQL Verification and Phase Gate** of the approved least-to-most implementation roadmap.

Work in the repository-connected Codex environment with the Cafe Fausse repository root open. This is the final PostgreSQL increment before Flask. Audit the implemented DB-05 and DB-06 repository state, correct proven implementation defects that remain within the approved designs, produce repeatable evidence, freeze the PostgreSQL contract that later Flask work may rely on, and present DB-07 for explicit approval.

Do not begin Flask or any later increment.

## Authoritative sources

Use the following as authoritative, in this order:

1. `docs/SRS(1).pdf`;
2. `docs/Rubric(1).pdf`;
3. the approved Project Requirements Addendum version 2.2.1, including PRA-001 through PRA-029;
4. the approved DB-01 Persistent-Data Requirements Analysis version 1.2.1;
5. the approved DB-02 Conceptual Data Model version 1.2;
6. the approved DB-03 Logical PostgreSQL Schema and Integrity Design version 1.1;
7. the approved DB-04 Reservation Transaction and Concurrency Design version 1.1;
8. the approved DB-05 database-foundation implementation currently present in the repository, including migrations, roles, initialization/reset tooling, tests, documentation, and completion evidence;
9. the approved DB-06 reservation-persistence, allocation, and concurrency implementation currently present in the repository, including migrations, routines, privileges, tests, documentation, and completion evidence;
10. the approved least-to-most implementation roadmap version 1.1.1;
11. the repository-root `AGENTS.md` and any more-specific applicable repository instructions.

DB-01 through DB-06 are approved. DB-06 was explicitly approved by Abdul on 2026-08-20. Do not reopen or silently replace their requirements, logical-schema decisions, transaction design, or implementation architecture unless verification discovers a genuine contradiction or implementation-blocking defect.

The current repository is authoritative for approved DB-05 and DB-06 implementation details such as migration numbers, schema names, role names, routine names and signatures, advisory-lock identifiers, timeout configuration, test-harness conventions, and reset commands. The approved requirement and design artifacts remain authoritative for business behavior.

## Accepted repository-history notes

Treat the following as accepted historical facts, not defects, blockers, or reasons to rename approved files:

- The approved DB-05 and DB-06 prompt filenames and headers both identify themselves as “Prompt 8.” This reflects how those two prompts were generated and used. Their database increment identifiers, repository contents, implementation reports, and approval records distinguish them.
- Two roadmap references say Project Requirements Addendum version 2.2. The authoritative addendum header and downstream approved artifacts use version 2.2.1. Version 2.2.1 is the regenerated downloadable copy of the materially unchanged 2.2 content and is authoritative for DB-07.
- DB-05 and DB-06 implementation reports may retain “ready” or “paused at approval checkpoint” wording written before approval. Those historical completion statements are superseded by Abdul’s later explicit approvals: DB-05 on 2026-08-19 and DB-06 on 2026-08-20.
- Prompt filenames in this repository do not include document-version suffixes. The authoritative DB-07 prompt path is `docs/prompts/Cafe_Fausse_Prompt_9_DB07_PostgreSQL_Verification_and_Phase_Gate.md`.

## DB-07 objective and hard boundary

Prove that the PostgreSQL layer is:

- complete for every database-applicable approved requirement;
- reproducible from an empty, isolated database;
- protected by the approved constraints, roles, privileges, transaction behavior, and concurrency control;
- free of blocking correctness, atomicity, security, or reproducibility defects;
- supported by repeatable unit, integration, concurrency, rollback, and manual-verification evidence;
- measured sufficiently to judge its contribution to the SRS two-second submission expectation;
- documented through a stable database contract that later Flask increments can consume.

DB-07 may add or improve database verification tests, concurrent-session drivers, test fixtures, documentation, reports, and tightly scoped database fixes proven necessary by the audit. Any database-object correction must be forward-only and preserve approved migration history.

Do not implement or design:

- Flask application code;
- Python application services or repositories;
- REST endpoints, paths, payloads, HTTP statuses, or error envelopes;
- React, JSX, browser behavior, or end-to-end UI flows;
- API-01 or any later roadmap increment;
- new business features, tables, columns, histories, workflows, or rules;
- an alternative logical schema or concurrency architecture.

Python or shell tooling is permitted only for database migration orchestration, database tests, reproducible concurrent-session tests, evidence collection, or verification reporting. It must not duplicate authoritative PostgreSQL business logic or become the backend application.

## Required initial read-only repository audit

Before changing any file or database object:

1. Read the applicable `AGENTS.md` instructions.
2. Inspect Git status and preserve all unrelated user changes.
3. Locate the approved requirements, design artifacts, DB-05 and DB-06 completion records, migrations, seed/reset tooling, roles, routines, tests, and database documentation.
4. Record the current migration sequence and immutable approved migration boundary.
5. Identify the repository's supported PostgreSQL version, extension requirements, schema namespace, role model, connection conventions, and test commands.
6. Inventory the implemented database objects, including tables, columns, constraints, indexes, sequences/identities, functions or procedures, extensions, roles, grants, and default privileges.
7. Inspect the approved DB-05 and DB-06 verification evidence and identify every claim that DB-07 must independently reproduce.
8. Run the established database verification suite against an isolated test database without changing repository files.
9. Record the baseline commit or working-tree state, test command, test count, pass/fail/skip result, database version, and any environmental limitation.
10. Compare the implemented objects and behavior with DB-03 and DB-04 before proposing a correction.

If the required source files are missing, the database cannot be tested safely, DB-05 or DB-06 approval evidence is absent, approved migration files have unexplained modifications, or the implementation materially contradicts an approved design, stop and report the exact discrepancy. Do not conceal it by building a second database path.

## Defect classification and correction policy

Classify every finding as one of:

- **Blocking defect:** can permit incorrect committed business state, data loss, privilege bypass, nonreproducible deployment, or failure of a required workflow.
- **Major defect:** violates an approved requirement or materially weakens repeatable verification, but does not presently demonstrate corrupt committed state.
- **Minor defect:** bounded maintainability, naming, diagnostics, or documentation problem with no approved behavioral impact.
- **Evidence gap:** an approved behavior may be correct, but the repository lacks repeatable proof.
- **Observation:** useful fact that requires no change.

Apply these rules:

- Correct implementation defects only when the correction stays squarely inside the approved DB-03 schema and DB-04 transaction/concurrency design.
- Preserve the bytes and order of approved migrations. Correct a deployed database object through a new forward migration.
- Add focused regression evidence for every corrected defect.
- Rerun the affected tests immediately and the complete clean-build suite before completion.
- Do not treat a failing test caused by a genuine product defect as a test-only problem.
- Do not weaken assertions, remove concurrency barriers, add sleeps as correctness mechanisms, broaden privileges, or bypass constraints merely to obtain a passing result.
- Do not add speculative indexes or optimizations without measurement and an approved semantic fit.
- If a correction requires changing a DB-03 table, column, type, key, constraint, index decision, or the selected DB-04 isolation/locking/fingerprint/allocation design, stop and request approval. State the violated requirement, evidence, smallest proposed change, compatibility impact, and affected artifacts.
- If a requirement remains genuinely ambiguous or would introduce a new business rule, stop and request approval rather than choosing silently.

## Clean rebuild and reproducibility verification

Prove the database can be constructed from nothing in an isolated nonproduction environment using only version-controlled repository artifacts and documented prerequisites.

Verify:

- all migrations apply once, in deterministic order, from an empty database;
- approved migrations remain immutable and repeatable;
- required PostgreSQL capabilities and `pgcrypto` are available through the documented setup path;
- roles, schema ownership, grants, default privileges, routines, constraints, and indexes are created as intended;
- seed or initialization creates exactly one reservation-configuration row;
- seed or initialization creates exactly seven operating-hours rows;
- the normal schedule is Monday through Saturday 5:00 PM-11:00 PM and Sunday 5:00 PM-9:00 PM in recurring restaurant-local time;
- seed or initialization creates exactly 30 restaurant tables, each with capacity four, for derived total capacity 120;
- the guarded nonproduction reset returns configuration, schedule, inventory, customers, reservations, assignments, and identities to the approved initial state;
- reset removes dependent assignment and reservation data in a safe dependency order;
- normal production roles cannot invoke destructive reset behavior;
- a second clean rebuild produces the same logical objects and seed facts;
- setup does not depend on local absolute paths, embedded credentials, uncommitted files, manual object creation, or a developer-specific machine state.

Run the complete database suite after a clean rebuild and again after a reset/reinitialization cycle. Record commands, prerequisites, results, and any deliberate environment-sensitive variation.

## Final schema and source-of-truth audit

Verify the implemented schema against the complete DB-03 catalogue, not merely table existence.

The six approved business tables must remain recognizable and authoritative:

- `customers`;
- `reservation_configuration`;
- `restaurant_operating_hours`;
- `restaurant_tables`;
- `reservations`;
- `reservation_table_assignments`.

For every table, verify and document:

- final table and column names;
- PostgreSQL data types;
- identity/default generation;
- nullability;
- primary keys;
- foreign keys and update/delete actions;
- unique constraints;
- check constraints;
- indexes and their ownership by constraints where applicable;
- role privileges and permitted write paths;
- correspondence to the DB-03 data dictionary.

Confirm that no unapproved business table, column, status, audit field, history record, copied interval, copied capacity, availability row, candidate row, or duplicate source of truth has appeared.

Reconfirm normalization and authority:

- newsletter status exists only on `customers`;
- recurring hours exist only on `restaurant_operating_hours`;
- the five scalar settings exist only on `reservation_configuration`;
- table capacity exists only on `restaurant_tables`;
- reservation interval and party size exist only on `reservations`;
- winning reservation-table relationships exist only on `reservation_table_assignments`;
- total capacity, maximum party size, availability, legitimate slots, free tables, candidate combinations, ranks, and random outcomes are derived and not persisted independently.

## Configuration, schedule, and table-inventory verification

Provide repeatable tests and direct evidence for:

- one and only one current configuration row;
- start interval default 30 minutes and permitted values 15, 30, or 60;
- duration default 90 minutes and permitted values 60, 90, or 120;
- maximum advance window default 60 days and permitted range 1-365;
- same-day minimum lead default 120 minutes and permitted range 0-1440;
- default timezone `America/New_York` and rejection or controlled failure for invalid timezone configuration;
- one unique row for every ISO weekday;
- rejection of duplicate weekdays and invalid same-day open/close boundaries;
- exact normal SRS weekday and Sunday hours;
- a controlled alternate recurring weekly schedule used by tests without changing database business logic, followed by restoration;
- exactly 30 seeded table identities and no duplicates;
- capacity four for every initial table and derived total capacity 120;
- rejection of nonpositive capacity;
- readiness failure when singleton, seven-row, or 30-row population invariants are missing or unexpected;
- prospective configuration, hours, and capacity changes without mutation of existing reservation intervals or assignments.

Do not add closed weekdays, overnight periods, multiple service periods, holiday exceptions, active/inactive tables, or more than 30 Version 1 tables.

## Customer and newsletter verification

Verify the declarative constraints, controlled operations, and transaction behavior for:

- database-generated stable customer identity;
- required normalized first and last names;
- optional normalized middle initial;
- canonical trimmed lowercase email of no more than 254 characters;
- unique canonical email under concurrent creation;
- optional phone containing only approved characters and 7-15 digits;
- required Boolean newsletter state;
- newsletter-only customer creation;
- subscribe, unsubscribe, and no-change behavior;
- generic rejection of case-insensitive normalized name mismatch;
- preservation or approved blank-field population for middle initial and phone;
- rejection of conflicting populated middle initial;
- differing existing phone notice behavior without overwrite;
- rollback of customer creation or field population after unsuccessful booking;
- rollback of booking-linked newsletter mutation after unsuccessful booking;
- last-committed-write-wins interaction with an independent newsletter update;
- exact-retry nonmutation and return of the current authoritative newsletter state.

Confirm that raw/confirmation email, newsletter history, customer profile, authentication, verification, or automatic-prefill data is not stored.

## Reservation and assignment integrity verification

Verify:

- `reservation_id` is database generated, stable, unique, and serves as the SRS reservation/confirmation reference;
- every reservation has exactly one valid customer;
- `starts_at` and `ends_at` are canonical timezone-aware facts;
- each interval is immutable, half-open, and strictly positive;
- the stored duration is one approved duration and remains unchanged after later configuration changes;
- party size is immutable and positive;
- `fingerprint_version` and nonempty fingerprint are required;
- `(customer_id, starts_at, party_size)` is unique;
- the fingerprint index is non-unique and collisions remain representable;
- every committed new reservation has one or more assignments;
- every assignment references one reservation and one restaurant table;
- duplicate reservation-table pairs are rejected;
- the combined assigned capacity covers the party size at booking time;
- each assigned table is exclusive for the complete reservation interval;
- no copied interval, capacity, rank, random value, or independent assignment identifier is stored;
- ordinary application paths cannot update or delete retained reservations or assignments directly;
- a failed transaction never leaves an orphan reservation, partial assignment set, unintended customer mutation, or newsletter mutation.

Exercise all half-open interval shapes, including partial overlap, identical interval, containing, contained, and endpoint-touching/back-to-back intervals.

## Provisional availability verification

Verify that the implemented read-only availability operation:

- reads authoritative current configuration, timezone, weekday schedule, tables, reservations, and assignments;
- validates the requested restaurant-local date and party size;
- generates every legitimate interval-aligned start for the date;
- applies the advance window and same-day lead time;
- derives the proposed end from the current duration;
- excludes starts before opening or ending after closing;
- reports every legitimate start with provisional available/unavailable state;
- uses full-interval table exclusivity and capacity-sufficient combinations;
- persists no slot, availability, free/busy, candidate, ranking, or random-selection data;
- holds no booking lock after the read-only response;
- makes no promise that a displayed available start remains available;
- is always revalidated by authoritative booking.

Test the Monday-Saturday 11:00 PM boundary, the Sunday 9:00 PM boundary, alternate recurring hours, start-interval alignment, same-day lead, advance-window edges, full capacity, retained past reservations, and stale provisional availability.

## Exact retry, overlap, allocation, and randomness verification

Verify the approved DB-04/DB-06 behavior directly.

### Exact retry and collision safety

- PostgreSQL generates the version-1 fingerprint using the approved DB-04 algorithm and canonical serialization.
- Only resolved `customer_id`, canonical `starts_at`, and `party_size` contribute to the fingerprint.
- Fingerprint lookup is followed by equality verification of the underlying tuple.
- An exact retry returns the existing reservation, existing immutable interval and party size, all existing assigned tables, and current newsletter state.
- An exact retry creates no row and performs no customer/contact/newsletter mutation.
- A non-unique fingerprint collision with different underlying facts neither returns the wrong reservation nor blocks an otherwise valid booking solely because of the collision.
- Concurrent identical submissions produce one logical reservation.
- A lost successful response can be recovered by an ordinary resubmission without a client-supplied idempotency key or fingerprint.

### Same-customer overlap

- Exact retry is recognized before different-reservation overlap handling.
- A different overlapping request for the same customer is rejected for every overlap shape.
- Endpoint contact is allowed.
- Concurrent nonidentical overlapping attempts by one customer cannot both commit.
- Different customers may hold overlapping reservations when different exclusive table capacity is available.

### Free-table derivation and allocation

- A table is free only when it has no assignment whose parent interval overlaps the complete proposed interval.
- Candidate generation uses only currently free tables.
- Eligible combinations cover party size.
- The algorithm is exact for at most 30 Version 1 tables and does not use an unapproved heuristic.
- It first minimizes table count, then minimizes unused capacity, then randomly selects only among equal best combinations.
- Both single-table and multi-table cases are demonstrated.
- No eligible combination yields the authoritative unavailable/full result without partial persistence.
- Table numbers are deterministically ordered for locking and comparison; random choice never determines lock order.
- Only the winning assignments persist.

### Random tie behavior

- Production selection includes every equal best candidate without systematic exclusion.
- Statistical evidence is sufficient to detect an obvious deterministic bias but does not claim a formal guarantee of perfect uniformity.
- The restricted deterministic test seam can force or observe stable selection in tests.
- The production application role cannot invoke or influence that seam.
- Random seeds, ranks, candidate combinations, and rejected alternatives are not stored as business data.

## Transaction, concurrency, and atomicity verification

Verify the approved primary strategy rather than substituting a new one:

- `READ COMMITTED` transaction isolation;
- the approved transaction-scoped restaurant-wide booking advisory lock;
- the approved per-canonical-email advisory-lock protocol;
- deterministic lock acquisition order;
- customer-row locking when required;
- coordinated configuration, operating-hours, and table-capacity writes;
- authoritative re-read and revalidation inside the transaction;
- all-or-none customer, preference, reservation, and assignment persistence;
- bounded recovery behavior for deadlock, lock timeout, and retryable technical conflict.

Use reproducible multi-session tests with explicit barriers or database-observable synchronization. Do not depend on timing luck or long sleeps as the proof of concurrency correctness.

Cover at least:

- two identical requests submitted concurrently;
- two different requests for the same new canonical email;
- concurrent matching and mismatching names;
- blank middle-initial or phone population races;
- reservation versus independent newsletter signup/update;
- two different customers competing for the last table;
- competing single-table reservations;
- competing multi-table reservations with partially overlapping candidate sets;
- single-table versus multi-table competition;
- two different overlapping requests by the same customer;
- concurrent back-to-back requests;
- stale availability followed by authoritative booking;
- booking versus configuration change;
- booking versus operating-hours change;
- booking versus table-capacity change;
- failure after customer creation;
- failure after customer-field population;
- failure after newsletter update;
- failure after reservation insertion;
- failure after partial assignment insertion;
- forced deadlock, retryable conflict, or lock timeout where the implementation supports controlled injection;
- connection or response loss after commit followed by exact retry.

For each multi-session case, document initial state, session A and B steps, barrier point, permitted outcomes, final database state, and evidence that no duplicate customer, duplicate reservation, overbooking, same-customer overlap, or partial persistence occurred.

Run the critical concurrency scenarios repeatedly from a known clean state. Use the repository's approved repeat count if one exists. Otherwise make the repeat count configurable, use at least 20 clean iterations for the critical two-session commit-conflict cases when the environment permits, and report the actual count and any justified limitation. A single lucky run is not sufficient evidence.

## Failure, rollback, and network-ambiguity verification

Build a verification matrix covering at least:

- malformed input rejected before the database operation;
- missing or invalid configuration;
- incomplete operating-hours schedule;
- unexpected table count;
- invalid timezone;
- date-window, lead-time, alignment, opening, and closing failures;
- party size outside derived capacity;
- customer name or middle-initial conflict;
- differing existing phone notice condition;
- exact retry;
- fingerprint collision without tuple equality;
- same-customer overlap;
- no capacity-sufficient free combination;
- unique-email race;
- exact-identity unique race;
- concurrent table conflict;
- lock timeout;
- deadlock or other retryable database conflict;
- unexpected database error;
- failures after each partial in-transaction mutation point;
- connection loss before commit;
- connection loss while commit outcome is unknown;
- response loss after commit.

For every case, record outcome category, commit or rollback, safe internal retryability, safe caller resubmission, possible persistent state, and the stable database outcome or SQLSTATE that later Flask work may consume. Do not define HTTP behavior or user-facing wording.

Prove that ambiguous post-commit resubmission reconstructs the existing reservation and current newsletter state without duplicating the booking or replaying the original newsletter action.

## Role, privilege, and database-security audit

Verify the implemented least-privilege boundary, including:

- role ownership and membership;
- schema usage and object privileges;
- default privileges for later objects where applicable;
- revocation of unsafe access from `PUBLIC`;
- execute-only access to approved controlled operations for the ordinary application role;
- denial of direct application-role DML that could bypass customer, reservation, assignment, configuration, schedule, capacity, or newsletter rules;
- protected migration/owner capabilities;
- nonproduction-only reset privileges;
- restricted deterministic randomness and failure-injection seams;
- safe `SECURITY DEFINER` ownership where used;
- fixed safe `search_path` and schema-qualified protected object references;
- absence of caller-controlled object names or unsafe dynamic SQL;
- absence of embedded passwords, secrets, production connection strings, or developer-specific paths.

Demonstrate both allowed operations and expected denied operations using the intended roles. Do not merely inspect grants.

## Query-plan and performance evidence

Measure rather than promise. The SRS expects normal form submission to complete within two seconds, but DB-07 must not invent an unapproved arbitrary database/API/UI split.

If an approved database-layer budget already exists in the DB-05 or DB-06 repository evidence, verify against it. If no database-layer budget has been approved, report measured results and propose a defensible database contribution budget for explicit DB-07 approval. Treat that proposed budget as a DB-07 technical decision, not as a silently established requirement. Flag any result that plainly leaves insufficient room for later Flask and network work.

Record:

- PostgreSQL version and relevant settings;
- host/container resources and test environment;
- database state and retained-history size;
- warm versus cold-cache treatment where observable;
- sample count and measurement method;
- transaction duration;
- advisory-lock wait and lock-hold duration separately where applicable;
- p50, p95, p99, minimum, and maximum database-operation time where the sample size supports them;
- correctness outcome under contention, not latency alone.

Measure representative scenarios from DB-04, including:

- uncontended single-table booking;
- uncontended worst-reasonable multi-table booking;
- exact retry;
- same-customer overlap rejection;
- unavailable/full result;
- concurrent groups of 2 and 5 requests plus a documented short burst;
- allocation with 30 equal-capacity tables;
- allocation with a controlled heterogeneous-capacity test fixture restored afterward;
- availability for representative days;
- retained-history overlap and free-table lookup.

Inspect representative PostgreSQL query plans, with execution and buffer evidence when safe, for:

- canonical-email lookup;
- fingerprint candidate lookup;
- exact-identity tuple lookup;
- same-customer interval lookup;
- global interval/availability lookup;
- assignment lookup by reservation;
- assignment lookup by table;
- free-table derivation;
- any allocation query or internal query that dominates measured booking time.

Use an isolated database or rollback-safe method for plan collection that would otherwise mutate data. Explain why a sequential scan is reasonable for deliberately tiny configuration, seven-row hours, or 30-row inventory tables; do not label every sequential scan a defect. Confirm that approved indexes are present and nonredundant. Add an index only when measured evidence proves it necessary, it preserves DB-03 semantics, and it does not prematurely replace the approved DB-04 mechanism.

Correctness has priority over throughput. If the approved coarse restaurant-wide lock creates a measured concern, document the limitation. Do not silently replace it with finer locking, serializable isolation, exclusion constraints, or a different concurrency design; such a change requires a separately approved DB-04 revision.

## Database unit-test gate

Run the complete `UT-DB-*` suite, or the repository's equivalent naming convention, from a clean database. Ensure it covers at least:

- every column, nullability, default, key, foreign key, unique constraint, check constraint, and referential action;
- configuration defaults and every permitted/invalid boundary;
- singleton, seven-weekday, and 30-table readiness invariants;
- normal SRS hours and alternate schedule boundaries;
- customer normalization, uniqueness, matching, optional fields, and newsletter state;
- every half-open overlap shape and back-to-back contact;
- total capacity derivation and party-size bounds;
- single-table and multi-table eligibility;
- minimum-table-count and least-waste ranking;
- equal-best random tie behavior and deterministic seam;
- exact retry, changed party size, fingerprint serialization/version, and collision safety;
- same-customer rejection and different-customer allowed overlap;
- all-or-none assignments and injected rollback points;
- prospective configuration, hours, and capacity changes;
- no persistent availability/candidate data;
- retention of past reservations;
- role and privilege boundaries.

Skipped tests do not count as passing evidence unless the report identifies the exact reason, requirement impact, and an approved equivalent proof.

## Manual database demonstration

Provide a concise, repeatable demonstration guide that can be run from the repository without Flask. It must show:

1. rebuild from an empty database;
2. migration and extension state;
3. one configuration row and its five settings;
4. seven operating-hours rows with exact SRS normal values;
5. exactly 30 tables at capacity four and derived total capacity 120;
6. a valid customer and newsletter state;
7. a successful one-table reservation;
8. a successful multi-table reservation;
9. immutable half-open interval and back-to-back behavior;
10. same-customer overlap rejection;
11. different-customer overlapping bookings when exclusive capacity permits;
12. exact retry after simulated lost response;
13. full/unavailable behavior;
14. transaction rollback after injected partial work;
15. two-session concurrency protection;
16. application-role success through controlled operations and denial of direct bypass DML;
17. reset/reinitialization back to the approved initial state.

Use safe nonproduction data and commands. Do not require manual database edits that bypass the approved operation solely to make the demonstration succeed.

## Freeze the PostgreSQL contract for later Flask work

After verification and any approved-scope corrections, produce a versioned **PostgreSQL Contract for Flask v1.0**. This is a database-facing contract, not a REST contract.

Document exactly what later Flask increments may rely on:

- supported PostgreSQL version and required extension;
- database schema names and intended roles;
- approved controlled operation names and exact signatures as implemented;
- parameter types and normalization assumptions;
- operation transaction ownership and whether the caller starts any surrounding transaction;
- result row shapes, field names, PostgreSQL types, and stable database outcome identifiers;
- provisional-availability semantics and its nonpromise character;
- booking success, exact-retry, conflict, unavailable, validation/readiness, notice, and retryable-technical outcomes;
- reservation and table-assignment retrieval needed to reconstruct confirmation;
- canonical time, timezone, weekday, interval, and duration semantics;
- exact-retry and network-ambiguity behavior;
- newsletter action/no-change/exact-retry behavior;
- required grants and explicitly forbidden direct DML;
- relevant SQLSTATE or routine outcomes for bounded later retry orchestration;
- migration, initialization, reset, test, and readiness commands;
- performance evidence and approved/proposed database budget;
- known limitations and change-control rule.

The contract must state that later Flask code calls the controlled PostgreSQL operations and does not reproduce allocation, overlap, exact-retry, or concurrency rules in process-local logic. It must also state that changing a signature, result shape, stable outcome, privilege expectation, temporal semantic, or transaction semantic requires an explicit contract revision.

Do not define endpoint paths, HTTP methods, JSON field names, status codes, CORS policy, Flask architecture, or UI behavior. Those belong to API-01 and later increments after DB-07 approval.

## Traceability and coverage

Update the traceability matrix so every database-applicable requirement maps to:

- authoritative source and requirement identifier;
- implemented migration/object/routine/role;
- automated test or repeatable verification case;
- manual evidence where useful;
- result;
- known limitation or deferred layer, if any.

Cover:

- all database-applicable SRS functional requirements;
- SRS minimum Customers and Reservations structures;
- NFR-02, NFR-05, and NFR-09;
- applicable rubric PostgreSQL-integration, sophisticated-logic, testing, and demonstration criteria;
- PRA-001 through PRA-029 as applicable;
- every DB-03 table, column, key, constraint, index, source-of-truth, and responsibility decision;
- every DB-04 transaction, locking, exact-retry, overlap, allocation, randomness, rollback, recovery, capability, and test decision;
- DB-05 and DB-06 completion criteria.

For requirements enforced partly in Flask later, identify the precise PostgreSQL support already present and the precise remaining responsibility. Do not mark a later-layer obligation as implemented merely because PostgreSQL stores supporting facts.

## Known limitations record

Record all remaining nonblocking limitations with:

- description;
- affected requirement or scenario;
- reason it is acceptable for Version 1;
- operational or performance impact;
- later increment, if any, responsible for handling it;
- evidence that it does not compromise committed-state correctness.

No blocking correctness, concurrency, atomicity, security, reproducibility, or database-contract defect may remain at DB-07 completion.

## Explicit Version 1 exclusions

Confirm that DB-07 does not introduce:

- customer authentication or email ownership verification;
- automatic profile prefilling or general contact-update workflows;
- cancellation, modification, rescheduling, no-show, or reservation-status lifecycles;
- administrative reservation management;
- temporary holds, waiting lists, queues, or slot ledgers;
- customer-selected tables, table sharing, adjacency, combinability, or seat-level assignment;
- active/inactive tables or more than 30 Version 1 tables;
- holiday/date-specific schedules, closed weekdays, overnight service, or multiple daily periods;
- configuration, schedule, newsletter, reservation, or allocation history;
- confirmation email/SMS delivery state;
- persistent availability, free-table, candidate, rank, seed, or rejected-combination rows;
- archival or automatic purge;
- generic audit tables or unapproved timestamps;
- Flask, REST, or React implementation.

## Required DB-07 deliverables

At completion, create or update repository artifacts containing:

1. DB-07 executive summary and scope statement;
2. initial read-only audit and baseline results;
3. final migration/object inventory;
4. final schema catalogue and column-level data dictionary;
5. keys, foreign keys, checks, uniqueness, defaults, nullability, indexes, routines, roles, and privileges catalogue;
6. source-of-truth and normalization confirmation;
7. clean rebuild, seed, reset, and reproducibility guide;
8. SRS operating-hours and 30-table seed evidence;
9. complete database unit-test results;
10. repeatable concurrent-integration-test results;
11. rollback and network-ambiguity evidence;
12. role and security-boundary evidence;
13. representative query plans and analysis;
14. performance method, environment, raw summary, p50/p95/p99 results, lock-wait/hold observations, and budget assessment;
15. manual database demonstration guide;
16. defect register with classification, cause, correction, migration impact, and regression evidence;
17. PostgreSQL-versus-later-Flask responsibility confirmation;
18. PostgreSQL Contract for Flask v1.0;
19. SRS, rubric, PRA, DB-03, DB-04, DB-05, and DB-06 traceability matrix;
20. known-limitations record;
21. explicit Version 1 exclusions;
22. DB-07 completion assessment;
23. Hard Gate 1 approval checkpoint and the next increment it would authorize.

Keep raw machine-generated logs reasonably sized. Store concise reproducible summaries in approved artifacts and keep full raw evidence in the repository only when it is stable, useful, and consistent with repository conventions. Do not commit secrets, personal data, transient database files, coverage caches, or machine-specific output.

## Required final response

Lead with the DB-07 result. Include:

- whether the clean rebuild and reset cycle succeeded;
- complete unit and integration/concurrency test counts and outcomes;
- repeated-concurrency iteration counts;
- defects found and corrected, with changed files and forward migrations;
- any unresolved blocker that prevented completion;
- representative performance results and the database-budget assessment;
- role/privilege verification result;
- traceability completeness;
- PostgreSQL contract artifact location and version;
- known limitations;
- Git working-tree summary;
- an explicit statement that no Flask, REST, or React work began;
- the exact DB-07 approval checkpoint.

If all completion criteria are satisfied, state that **DB-07 is ready for explicit approval at Hard Gate 1**. Do not claim it is approved until Abdul explicitly approves it.

After explicit DB-07 approval, the next authorized increment is **API-01 - Backend Operation Inventory**, a design-only inventory of the minimum Flask operations. DB-07 approval does not authorize Flask implementation, REST-contract design, or React work by itself.

## DB-07 completion criteria

DB-07 is complete only when all of the following are true:

- a clean isolated rebuild succeeds from version-controlled artifacts;
- the reset/reinitialization cycle restores the exact approved initial state;
- the final schema, constraints, indexes, routines, roles, and privileges match approved DB-03, DB-04, DB-05, and DB-06 decisions;
- all required database tests pass without unexplained skips;
- critical concurrency tests pass repeatedly with no duplicate customer, duplicate logical reservation, same-customer overlap, shared overlapping table, incomplete assignment, or partial state;
- exact retries and ambiguous-response recovery are collision safe and newsletter nonmutating;
- direct privilege-bypass attempts fail as designed;
- representative query plans and timings are documented and support a defensible contribution to the SRS two-second expectation;
- every database-applicable requirement has implementation and evidence traceability;
- the PostgreSQL Contract for Flask v1.0 is complete and consistent with the implemented database;
- no blocking defect remains;
- no unapproved business behavior or later-layer implementation was introduced.

Stop at the Hard Gate 1 approval checkpoint. Do not begin API-01, Flask, REST, or React work.
