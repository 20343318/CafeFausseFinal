# Revised Prompt 16 — API-07 Reservation Context and Availability

Implement API-07 only: current reservation context and daily provisional reservation availability.

Do not begin API-08, API-09, reservation creation, or React.

## Approval state

The following work is approved, committed, pushed, and closed:

- DB-01 through DB-07;
- the frozen PostgreSQL Contract for Flask;
- API-01 through API-06;
- all previously approved programmer-test-harness hardening.

The repository should begin this increment from the clean committed API-06 state.

This prompt authorizes API-07 only.

It does not authorize:

- reservation creation or exact-retry behavior;
- OP-05;
- API-08 or API-09;
- React/frontend work;
- database schema, migration, routine, privilege, or design changes;
- deployment work.

## Authoritative sources and precedence

Use the repository's current committed artifacts. Do not reconstruct approved behavior from earlier chat messages.

Read and apply, in this order:

1. Root `AGENTS.md` and current project instructions.
2. `docs/SRS(1).pdf` and `docs/Rubric(1).pdf` as fixed authoritative baseline.
3. The approved Project Requirements Addendum version 2.2.1.
4. Approved DB-01 through DB-04 design artifacts.
5. Approved DB-05 through DB-07 implementation and verification evidence.
6. `database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, frozen version 1.0.
7. Approved API-01 Backend Operation Inventory version 1.0.2.
8. Approved API-02 Flask REST Contract version 1.0.1.
9. Approved API-03 Flask Architecture, Configuration, and Test Strategy version 1.0.3.
10. Approved API-04 through API-06 implementation reports and current committed backend implementation.
11. Current `backend/README.md`, `backend/TestInstructions.md`, and database testing documentation.
12. The approved least-to-most implementation roadmap version 1.1.1.
13. This Prompt 16.

The exact API-02 contract controls routes, methods, query parameters, response schemas, statuses, public errors, headers, caching policy, and examples.

The frozen PostgreSQL contract and API-03 architecture control database access, transaction isolation, result interpretation, retry behavior, connection ownership, and least privilege.

Do not invent alternative fields, routes, statuses, response shapes, availability rules, or business rules.

If any required behavior is materially unspecified or conflicts with an approved source, STOP and request approval.

## Phase 0 — Mandatory read-only verification

Before modifying anything:

1. Read all authoritative sources above.
2. Inspect:
   - complete backend source and test trees;
   - current Git status and recent history;
   - API-04 through API-06 implementation reports;
   - current dependency container, parser, responses, error handlers, retry service, pool, logging/redaction, timing, serializers, and test runner;
   - frozen PostgreSQL routine and read privileges relevant to OP-01 and OP-02.
3. Record current full HEAD.
4. Confirm the working tree is clean and API-06 is committed.
5. Confirm API-07 consists only of:
   - OP-01 current reservation context;
   - OP-02 daily provisional availability.
6. Confirm exact endpoints:
   - `GET /api/v1/reservation-context`
   - `GET /api/v1/reservation-availability`
7. Confirm OP-02 accepts exactly these query parameters:
   - `local_date`
   - `party_size`
8. Confirm OP-01 accepts no query parameters and neither GET endpoint accepts a request body.
9. Confirm exact API-02 success/error schemas and examples for OP-01 and OP-02.
10. Confirm API-03's approved database-access design:
    - OP-01 uses one coherent `REPEATABLE READ READ ONLY` transaction;
    - OP-02 uses one `REPEATABLE READ READ ONLY` transaction;
    - within that transaction, OP-02 reads only `reservation_configuration.restaurant_timezone` and calls the unchanged `cafe_fausse.provisional_availability(date, integer)` routine;
    - read-only retries follow the approved shared retry policy.
11. Identify the minimum production files required.
12. Identify every test-created resource and how durable ownership will be established at creation time.
13. Report:
    - `READY - API-07`, with concise verified scope/path plan, then continue; or
    - `BLOCKED`, with the exact conflict, and make no changes.

STOP before editing if an additional production path beyond the authorized scope is required.

## API-07 objective

Implement:

### OP-01 — Current reservation context

`GET /api/v1/reservation-context`

Return the exact API-02 current context containing only the approved public facts needed for Home/reservation discovery, including:

- fixed SRS restaurant contact facts;
- authoritative seven-day recurring operating hours;
- current reservation policy/configuration values;
- authoritative restaurant timezone;
- current inclusive reservation date bounds;
- derived maximum party size.

Do not expose:

- individual restaurant-table rows;
- table capacities;
- total-capacity implementation details unless API-02 explicitly exposes them;
- customer information;
- reservations or assignments;
- internal database identifiers;
- SQL/database diagnostics.

OP-01 must use current PostgreSQL facts and must not hard-code configurable reservation rules.

### OP-02 — Daily provisional availability

`GET /api/v1/reservation-availability`

Accept exactly:

- `local_date`
- `party_size`

Return the exact API-02 success representation, including:

- `provisional: true`;
- every legitimate aligned start returned by PostgreSQL;
- each slot's approved local start/offset representation;
- availability Boolean.

Availability is provisional only.

Do not:

- remove unavailable slots;
- create persistent slots;
- create holds;
- allocate tables;
- compute availability in Flask;
- expose free-table counts, candidate table combinations, capacities, reservations, assignments, or allocation details.

A previously returned available slot is never authoritative for later booking. API-08 reservation creation must independently revalidate through PostgreSQL.

## OP-01 PostgreSQL access

The context gateway may perform only the approved fixed projections from:

- `reservation_configuration`;
- `restaurant_operating_hours`;
- `restaurant_tables`;

plus the approved database-clock expression using the current restaurant timezone.

Use one explicit:

`REPEATABLE READ READ ONLY`

transaction to obtain one coherent snapshot.

Validate expected result shapes and invariants, including:

- exactly one valid configuration row;
- exactly seven valid weekday rows;
- weekdays 1 through 7 exactly once;
- exactly 30 current positive-capacity restaurant tables;
- valid permitted configuration values;
- valid IANA restaurant timezone;
- valid derived local date bounds;
- valid capacity-derived maximum party size.

If the database state is incomplete or internally invalid, map it to the exact approved generic API-02 service failure. Do not fabricate defaults or repair data.

Do not read:

- `customers`;
- `reservations`;
- `reservation_table_assignments`.

Do not perform DML.

## OP-02 PostgreSQL access

Within one transaction, the availability gateway must:

- read only `cafe_fausse.reservation_configuration.restaurant_timezone`;
- use that timezone identifier only to serialize the exact API-02 response; and
- call the unchanged availability routine:

`cafe_fausse.provisional_availability(%s::date, %s::integer)`

using bound validated values.

Use one explicit:

`REPEATABLE READ READ ONLY`

transaction per attempt so the timezone identifier and availability rows come from one coherent snapshot. No other foundation-table read is permitted.

Consume and validate the complete returned row set exactly according to the frozen PostgreSQL contract.

Preserve PostgreSQL row ordering after verifying:

- legitimate slot rows;
- unique slot starts;
- expected row shape/types;
- allowed outcome/detail combinations;
- valid canonical/local temporal facts;
- valid Boolean availability values.

Reject impossible row shapes, duplicate legitimate starts, unknown outcomes/details, or contradictory values as typed internal contract failures.

Do not expose database outcome/detail strings unless API-02 explicitly defines an identical public value.

## OP-02 request validation

Implement only the reservation validation needed by API-07.

`local_date`:

- must use the exact API-02 `YYYY-MM-DD` representation;
- must be a valid calendar date;
- must follow API-02 validation/error mapping;
- current booking-window validity remains authoritative in PostgreSQL.

`party_size`:

- must be an exact integer under API-02 rules;
- Boolean is not an integer;
- reject strings, fractions, invalid numeric forms, NaN/Infinity, zero, and negatives;
- respect the API-02 protocol ceiling;
- current capacity-derived maximum remains authoritative in PostgreSQL.

Reject:

- missing required query parameters;
- duplicated query parameters if prohibited by the approved parser/contract;
- unknown query parameters;
- request bodies on these GET routes;
- alternate date/time fields;
- table/capacity/availability assertions;
- server-controlled fields.

Do not accept arbitrary local start times in API-07.

## Temporal and DST behavior

Preserve API-02 and PostgreSQL timezone authority exactly.

The restaurant timezone comes from PostgreSQL, not:

- the Flask host timezone;
- Windows timezone;
- browser timezone;
- UTC assumptions.

OP-02 slot representations must preserve the approved restaurant-local/DST semantics.

Do not create alternate Flask-side business-time calculations.

Tests must include DST-relevant dates sufficient to prove that:

- offsets are derived consistently with the approved database result;
- local starts are not reinterpreted through the host timezone;
- duplicate/ambiguous representations are not invented by Flask.

## Read retry and deadline behavior

Use the existing API-03 read policy and shared retry infrastructure.

Preserve:

- `CAFE_FAUSSE_READ_DEADLINE_MS`, default 2000 ms;
- maximum three database attempts;
- fresh lease/transaction for every retry;
- approved bounded retry delays;
- deadline checks before another attempt;
- safe retry of read-only connection failure because no mutation can commit.

Do not:

- add a second retry loop;
- broaden retry behavior beyond the approved read policy;
- round an exhausted deadline upward and dispatch new work;
- hold leases between attempts;
- change mutation retry behavior from API-06.

Broken or uncertain connections must follow the already approved disposal rules and must not return as normal reusable leases.

## HTTP behavior

Preserve API-02 exactly.

Both endpoints must:

- return JSON with the existing content type policy;
- use `Cache-Control: no-store`;
- return exact API-02 success bodies;
- use the common safe error envelope;
- preserve existing method-not-allowed/not-found handling;
- expose no correlation ID or database diagnostics.

Do not introduce aliases or alternate routes.

Availability queries contain no PII, but logs still must not include arbitrary raw request/query serialization.

## Thin adapters and architecture

Follow API-03's approved structure.

Expected operation-owned modules are:

- `validation/reservation.py`
- `services/reservation_context.py`
- `services/reservation_availability.py`
- `db/context_gateway.py`
- `db/availability_gateway.py`
- `http/routes/reservation_context.py`
- `http/routes/reservation_availability.py`
- `serialization/reservation.py`

Narrow changes to existing shared API-04-through-API-06 foundation files are permitted only where required to register/wire OP-01/OP-02 or reuse approved common behavior.

Typical shared extension points include:

- `application.py`
- `dependencies.py`
- `http/blueprint.py`
- `http/responses.py`
- `http/error_handlers.py`
- `services/results.py`
- validation/serialization package exports

Do not modify a shared file unless necessary.

If another production file is required, STOP and request approval before changing it.

Routes must remain thin:

1. enforce GET/body/query rules;
2. validate query values where applicable;
3. invoke one service;
4. serialize one typed result.

Routes must not:

- execute SQL;
- calculate reservation availability;
- calculate business date/time limits;
- own retry logic;
- inspect Psycopg exceptions;
- fabricate fallback configuration;
- expose database details.

## Durable ownership and cleanup — mandatory

For every API-07-created temporary file, directory, virtual environment, cache, compile output, test artifact, disposable PostgreSQL resource, listener/process, or other non-source resource:

1. Establish durable ownership evidence at creation time.
2. Prefer one task-owned root with a unique ownership marker containing:
   - API-07/task identifier;
   - purpose;
   - repository canonical path;
   - unique owner ID.
3. Refuse to adopt or delete any preexisting or ambiguously owned resource.
4. Never infer ownership solely from name, timestamp, contents, or location.
5. Never create retroactive ownership evidence to justify deletion.
6. Before recursive deletion verify:
   - exact canonical target;
   - ownership marker;
   - repository identity;
   - containment;
   - absence of symlink/reparse-point escape.
7. If ownership cannot be proven, preserve the resource and report the blocker.
8. Cleanup must remove every resource proven to have been created by API-07.
9. Cleanup failures must be reported and must not be silently ignored.
10. Final documentation must accurately state what was created, preserved, restored, and removed.

No API-07-generated repository artifact may remain after successful verification except intended source/test/documentation changes and the explicitly requested review `.diff` handoff artifact, which is already ignored by Git.

## Required automated tests

Add focused deterministic tests at the approved layers.

### OP-01 unit/gateway tests

Cover at least:

- normal SRS recurring hours;
- alternate valid recurring schedule;
- normal current configuration;
- alternate permitted configuration values;
- exactly 30 tables;
- modified positive table capacities;
- capacity-derived maximum party size;
- missing configuration;
- duplicate/missing weekday;
- invalid schedule shape;
- invalid timezone;
- wrong table count;
- nonpositive capacity;
- malformed database result;
- coherent snapshot transaction isolation;
- technical read failure/retry;
- no mutation.

### OP-02 validation tests

Cover at least:

- valid date;
- invalid calendar date;
- missing date;
- valid party size;
- missing party size;
- zero/negative;
- above protocol ceiling;
- string instead of integer;
- Boolean instead of integer;
- fractional value;
- duplicate/unknown query parameters;
- GET request body rejection.

### OP-02 gateway/service tests

Cover at least:

- ordinary weekday;
- Sunday;
- every legitimate aligned slot returned;
- unavailable slots retained;
- all slots unavailable;
- empty legitimate slot array if the frozen contract permits it;
- current interval changes;
- current duration changes;
- current hours changes;
- same-day lead-time boundary;
- advance-window lower/upper boundaries;
- party-size capacity boundary;
- back-to-back reservations;
- partial/full overlapping occupancy;
- DST-relevant dates;
- database-provided ordering preserved;
- duplicate/impossible result rejected;
- safe read retry;
- no mutation/persistence.

### API tests

Verify exact API-02 behavior for:

- both routes;
- exact success schemas;
- no-store headers;
- unknown query parameters;
- missing/invalid fields;
- wrong methods;
- GET bodies;
- service/database failures;
- exact public error codes/messages/flags;
- no database/internal detail leakage.

Use API-02 examples as contract test inputs where applicable rather than inventing divergent examples.

### PostgreSQL integration tests

Using PostgreSQL 18.3 and the application-role boundary, verify at least:

OP-01:
- current SRS/default context;
- alternate valid schedule;
- alternate permitted scalar configuration;
- changed positive capacities;
- restoration of changed fixtures;
- incomplete/invalid foundation maps safely.

OP-02:
- empty/free day;
- partial occupancy;
- fully occupied slots;
- back-to-back intervals;
- alternate schedule/configuration/capacities;
- current interval/duration effects;
- same-day lead and advance-window boundaries;
- application role can execute the frozen routine;
- no direct reservation/assignment read is added;
- no database mutation occurs.

All fixture changes must be isolated and restored by the owned test workflow.

## Regression protection

API-07 must not regress API-04 through API-06.

Run focused regression coverage for:

- liveness/readiness;
- newsletter-status query;
- newsletter-preference mutation;
- shared request parsing;
- common error responses;
- retry/deadline logic;
- safe logging/redaction;
- connection cleanup/disposal.

Do not reopen approved API-04-through-API-06 behavior unless API-07 introduces a proven regression.

## TestInstructions.md

Update `backend/TestInstructions.md` for API-07.

It must provide repeatable/restartable human verification for:

- focused OP-01 tests;
- focused OP-02 tests;
- Flask API tests;
- PostgreSQL integration tests;
- complete API-07 verification workflow;
- rerunning in the same session;
- rerunning in a new session;
- recovery after ordinary failure;
- recovery after interruption;
- cleanup verification.

Document exactly what the workflow creates and how ownership is established.

The final cleanup step must remove every API-07-owned database, file, directory, process/listener, virtual environment, cache, compile output, or temporary object created by testing.

Ambiguous ownership must cause refusal, not deletion.

## Documentation

Update `backend/README.md` only as needed for the approved API-07 surface and programmer workflow.

Create:

`backend/API07_IMPLEMENTATION_REPORT.md`

Record:

- baseline HEAD;
- exact changed paths;
- OP-01 implementation;
- OP-02 implementation;
- database access used;
- tests and exact results;
- coverage;
- timing evidence;
- repeatability/restartability evidence;
- durable ownership and cleanup evidence;
- regressions checked;
- known limitations;
- unresolved issues;
- approval status.

Do not modify prior approved implementation reports.

## Verification gate

After implementation:

1. Parse affected PowerShell scripts and PowerShell blocks in `backend/TestInstructions.md`.
2. Run Python syntax/compilation checks with compile artifacts confined to a marker-owned temporary root.
3. Run configured formatting/lint/type checks; if none exist, report that accurately.
4. Run focused OP-01 unit/gateway/service tests.
5. Run focused OP-02 validation/gateway/service tests.
6. Run focused Flask API tests.
7. Run PostgreSQL 18.3 OP-01/OP-02 integration tests.
8. Run required API-04-through-API-06 regressions.
9. Run the complete current backend test suite.
10. Run configured coverage and preserve the existing threshold.
11. Run the complete API-07 programmer workflow twice consecutively.
12. Demonstrate ordinary test failure followed by cleanup and successful restart.
13. Demonstrate cleanup-failure handling where later cleanup/restoration still occurs.
14. Demonstrate interruption/recovery with valid ownership evidence.
15. Demonstrate malformed/mismatched ownership evidence is refused without deletion.
16. Verify exact restoration of all environment variables changed by testing.
17. Verify all API-07-owned processes/listeners/resources are absent at completion.
18. Verify no generated bytecode/cache/venv/coverage/temporary artifacts remain in the repository.
19. Verify no production database or production-like environment was modified.
20. Run `git diff --check`.
21. Verify the real Git index was not altered by test/diff-generation tooling.
22. Verify changed paths remain within authorized API-07 scope.

Do not stage, commit, push, reset, clean, stash, rebase, merge, cherry-pick, switch branches, create/delete tags, or perform pull-request operations.

## Review artifact

Generate one complete baseline-to-current:

`CafeFausse_API07_COMPLETE.diff`

for independent review.

The `.diff` artifact must not be staged or committed.

Generate it without modifying the real Git index.

Report:

- exact byte size;
- SHA-256;
- UTF-8/BOM status;
- final-newline status;
- exact changed-path count/list;
- proof that it reproduces the same intended tree.

## Completion checkpoint

At completion, report:

- API-07 implementation summary;
- exact changed paths;
- focused test results;
- complete backend test result;
- PostgreSQL integration result;
- coverage result;
- repeatability/restartability evidence;
- durable ownership and cleanup evidence;
- Git-index preservation;
- final diff filename and SHA-256;
- any unresolved issue.

Do not call API-07 approved.

STOP at the independent-review checkpoint.

Do not begin API-08, API-09, reservation creation, React, or integration work.
