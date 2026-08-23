# Revised Prompt 15 - API-06 Independent Newsletter Preference Management

Implement API-06 only: the independent, idempotent newsletter subscribe/unsubscribe operation defined by the approved Flask and PostgreSQL contracts.

Do not begin API-07 or any later Flask increment. Do not implement React.

## Approval state

The following work is approved, committed, pushed, and closed:

- DB-01 through DB-07;
- the frozen PostgreSQL Contract for Flask;
- API-01 through API-05;
- the post-approval DB-05-through-DB-07 programmer-test-harness hardening.

The working tree is clean at the start of this increment.

This prompt authorizes API-06 only. It does not authorize:

- reservation-context or slot discovery;
- reservation creation;
- reservation retry or confirmation behavior;
- API-07 through API-09;
- React work;
- database design or implementation changes;
- deployment work.

## Authoritative sources and precedence

Use the repository's current committed artifacts. Do not reconstruct approved behavior from earlier chat messages.

Read and apply, in this order:

1. Root `AGENTS.md` and current project instructions.
2. `SRS.pdf` and `Rubric.pdf` as the fixed authoritative baseline.
3. The approved Project Requirements Addendum.
4. The frozen PostgreSQL Contract for Flask.
5. The approved API-01 backend-operation inventory.
6. The approved API-02 Flask REST contract.
7. The approved API-03 Flask architecture, configuration, ownership, and test strategy.
8. The approved API-04 and API-05 implementation reports and the current Flask implementation.
9. Current backend and database setup/testing documentation.

The exact API-02 contract controls API-06's route, method, request fields, response fields, HTTP statuses, public error codes, retry indicators, unknown-outcome representation, and examples.

The frozen PostgreSQL contract controls the routine signature, stable database outcomes, transaction requirements, privilege boundary, retryable SQLSTATEs, and database-owned business behavior.

Do not invent alternative fields, routes, statuses, response shapes, or business rules.

If these sources conflict or an API-06 behavior remains materially unspecified, stop and request approval. Do not silently resolve a new business rule.

## Phase 0 - Mandatory read-only verification

Before modifying anything:

1. Read all authoritative artifacts listed above.
2. Inspect:
   - the complete backend source tree;
   - the complete backend test tree;
   - `backend/README.md`;
   - `backend/TestInstructions.md`;
   - `backend/pyproject.toml`;
   - the API-05 programmer-test runner and cleanup mechanism;
   - the database programmer-test harness documentation;
   - the frozen routine and privileges exposed by the PostgreSQL contract;
   - recent Git history and current Git status.
3. Record the full current HEAD commit as the API-06 review baseline.
4. Confirm that the working tree is clean and that `HEAD` is synchronized with the expected approved API-05 commit.
5. Identify the exact API-06 operation identifier, route, schema, status codes, public error mappings, and retry/ambiguity rules from API-02 and API-03.
6. Confirm the exact signature and stable outcomes of `cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)`.
7. Audit the API-05 identity validation, parser, response builder, error handlers, dependency container, composition root, retry service, database exceptions, serializers, test runner, and cleanup behavior for safe reuse.
8. Confirm that API-06 can be implemented without changing the database or an approved design artifact.
9. Identify every production path required and compare it with the authorization in this prompt.
10. Identify every resource that API-06 tests may create, change, start, or leave behind, and how ownership will be proved before cleanup.
11. Report either:
    - `READY - API-06`, followed by the verified scope and production-path audit, and then continue; or
    - `BLOCKED`, followed by the exact conflict or missing approval, and make no changes.

Stop if unrelated changes overlap an authorized path.

Stop before editing if an additional production path beyond the explicit authorization below is technically required. Report the exact path, why it is required, the smallest proposed change, and why an existing authorized extension point is insufficient.

## API-06 objective

Implement operation `OP-04`:

- `POST /api/v1/newsletter-preferences`

The operation must:

- independently set a customer's current newsletter preference without creating a reservation;
- use the structured identity rules approved for API-05, except that phone is prohibited for this operation;
- create a new customer only when the identity is new and `subscribed` is `true`;
- create no customer when the identity is new and `subscribed` is `false`;
- set the current preference for an exact existing identity;
- preserve all existing identity, phone, reservation, and assignment data;
- remain idempotent for repeated identical requests;
- return the committed current state for a successful response;
- represent known failure and outcome uncertainty exactly as approved.

Customers remain the single source of truth for current newsletter state. Do not create a separate subscriber table, file, cache, queue, or application-side store.

## Exact request contract

Accept only a JSON object with:

- required `first_name` string;
- optional `middle_initial` string, following the approved omission/null rules;
- required `last_name` string;
- required `email` string;
- required `confirmation_email` string;
- required, non-null JSON Boolean `subscribed`.

Phone is prohibited. Unknown fields are prohibited. Query parameters are prohibited unless the approved API-02 contract explicitly permits one; do not add any.

`subscribed` must be a JSON Boolean. Reject:

- `null`;
- numbers, including `0` and `1`;
- strings such as `"true"` or `"false"`;
- arrays;
- objects.

In Python, take care that `bool` is a subclass of `int`; the validator must accept only actual Boolean values and must not accidentally accept arbitrary integers.

Use the approved shared parser for media type, body presence, UTF-8, JSON grammar, duplicate-member, non-finite-number, and top-level-object rules. Do not duplicate parser behavior inside the route.

## Exact public outcomes

On a successful committed result, return HTTP `200` with exactly one of:

```json
{"result":"set","subscribed":true}
```

```json
{"result":"set","subscribed":false}
```

```json
{"result":"no_customer_no_change","subscribed":false}
```

The public `set` result intentionally does not reveal whether a customer was created, changed, or already in the requested state.

Map expected identity conflicts exactly as approved:

- `409 customer_identity_conflict`;
- `409 middle_initial_conflict`.

Map request and validation failures exactly as approved, including:

- `400 invalid_json`;
- `400 request_body_required`;
- `400 invalid_request` for disallowed request shape or unknown fields;
- `415 unsupported_media_type`;
- `422 validation_failed` with deterministically ordered, allowlisted field errors.

Map technical mutation failures exactly as approved:

- conclusively known non-commit/rollback after permitted retry is unavailable or exhausted: `503 temporary_failure`, with the approved retry and outcome-known flags;
- any failure for which the application cannot establish whether the preference mutation committed: `503 newsletter_preference_outcome_unknown`, with the approved retry and outcome-unknown flags.

Do not return `201` or `204`. Do not expose database outcome labels directly unless API-02 uses the same public value.

## Identity and preference rules

Reuse the approved API-05 identity normalization and comparison behavior. Do not fork or subtly alter it for API-06.

Apply at least these rules exactly:

- canonical email identifies the customer;
- first and last names are required;
- middle initial is optional and follows the approved omission and conflict rules;
- phone is neither accepted nor used as identity by this route;
- confirmation email is transient and is never persisted, logged, returned, or passed unnecessarily into the database layer;
- an existing identity mismatch never silently overwrites stored identity;
- an existing middle-initial conflict uses the distinct approved public conflict;
- new identity plus `subscribed: true` creates the approved complete customer record with no fabricated phone;
- new identity plus `subscribed: false` creates no customer row;
- exact existing identity sets `newsletter_subscribed` to the requested Boolean without altering name, phone, reservations, assignments, or unrelated fields;
- unsubscribe retains an existing customer record;
- a same-state request succeeds idempotently;
- concurrent valid preference writes for the same identity result in the last committed value;
- a successful response is authoritative for the value committed by that request;
- no email verification, confirmation email, or background delivery workflow is implied.

The application must call PostgreSQL for the authoritative mutation decision. Do not reimplement database-owned identity matching, creation, serialization, or last-committed-write logic in Flask.

## PostgreSQL gateway and transaction contract

The API-06 gateway must call only:

```text
cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)
```

Pass only:

1. normalized first name;
2. nullable normalized middle initial;
3. normalized last name;
4. canonical email;
5. requested subscribed Boolean.

The routine returns `(outcome text, newsletter_subscribed boolean)` with the stable database outcomes defined by the frozen contract.

Use fixed SQL and bound parameters. Do not directly insert, update, delete, merge, or lock customer rows from Flask.

Each attempt must:

1. use a fresh pool lease;
2. open a fresh explicit `READ COMMITTED` transaction;
3. constrain pool wait and database execution to the remaining overall deadline;
4. make the routine call as the only business statement;
5. consume and validate exactly one result;
6. commit only a valid expected result;
7. release or discard the connection correctly on every path.

Reject impossible row counts, malformed row shapes, unknown outcome strings, invalid Boolean projections, or contradictory outcome/value pairs as typed contract defects. Do not expose them publicly.

Do not change:

- migrations;
- PostgreSQL routines, functions, procedures, or views;
- tables, indexes, constraints, triggers, or sequences;
- roles, privileges, provisioning, or reset scripts;
- database verification or production test scripts;
- the frozen PostgreSQL contract.

## Mutation deadline, retry, and commit certainty

Use the approved API-03 mutation policy:

- one overall mutation deadline, default `15,000 ms`;
- maximum three total database attempts;
- pool acquisition of up to the configured limit within the remaining deadline;
- bounded jittered retry delays through the shared retry infrastructure;
- new lease and new transaction for every retry;
- automatic mutation retry only for SQLSTATE `55P03`, `40P01`, or `40001`;
- retry only after the preceding attempt is proven to have performed no database work or to have rolled back conclusively.

The SRS two-second form-operation expectation is a measurement and later phase-gate target. It does not replace the approved 15-second mutation correctness deadline, authorize premature failure, or guarantee that every contended valid mutation completes within two seconds. Measure and report API-06 timing evidence without changing the frozen deadline policy.

Enforce the overall deadline at every meaningful boundary, including:

- before pool acquisition;
- immediately after pool acquisition and before opening a transaction or dispatching SQL;
- before the routine call;
- after routine result decoding and before commit;
- before each retry sleep;
- immediately after each retry sleep and before another attempt.

An exhausted or sub-millisecond remaining budget must not be rounded up to a one-millisecond statement timeout and must not dispatch transaction or routine SQL. Release the lease and map the known no-dispatch outcome through the approved temporary-failure path.

Preserve exact mutation certainty:

- failure before routine dispatch is known not to have mutated;
- failure after routine dispatch is not automatically safe to retry unless rollback/non-commit is conclusively established;
- an approved retryable SQLSTATE is retryable only after rollback is confirmed;
- a returned routine result is not public success until commit is confirmed;
- failure while receiving the result, committing, or establishing commit status is outcome unknown unless non-commit is proven;
- outcome-unknown failures are never automatically retried;
- the public response for an outcome-unknown failure instructs only the contract-approved safe behavior: resubmit the identical request;
- ordinary resubmission of the identical body remains safe because the operation is idempotent.

If rollback or connection cleanup also fails, preserve the original operation failure as primary, report cleanup failure safely, and classify certainty conservatively. A connection with uncertain transactional state must not return to the pool as a normal reusable lease.

Do not broaden the retryable SQLSTATE allowlist. Do not add unbounded waits, recursive retry, a background job, or an independent retry loop.

## Typed internal results and thin adapters

Use frozen, exhaustive internal value/result types in the approved shared results module.

Expected business outcomes must be typed values, not control-flow exceptions. Protocol, dependency, certainty, and invariant failures must use narrow typed exceptions.

The route adapter must remain thin:

1. invoke the shared POST parser;
2. invoke identity and newsletter validation;
3. pass one normalized immutable command to one service;
4. pass the typed service result to the approved pure serializer/response builder.

The route must not:

- construct public error envelopes;
- choose public messages or flags;
- execute SQL;
- own retry logic;
- decide commit certainty;
- duplicate identity matching;
- inspect Psycopg exceptions;
- log request bodies or identity values.

Central error handlers must translate typed protocol and technical failures. The common response builder must own exact envelopes, headers, validation-field ordering, retry flags, and outcome-unknown flags.

## Privacy, logging, and enumeration resistance

Preserve the API-04/API-05 safe logging and response policies.

Never expose or log:

- raw or normalized names;
- raw or canonical email;
- confirmation email;
- phone data;
- customer IDs;
- customer-existence flags beyond the approved public result;
- the prior newsletter state;
- database outcome labels not intended for the public contract;
- SQL, bound values, DSNs, credentials, SQLSTATEs, driver details, pool details, or stack traces.

Log only approved allowlisted operational fields, such as the operation identifier, safe outcome category, attempt count, duration bucket/value as approved, and internal correlation identifier.

Use the same generic public identity-conflict behavior regardless of which protected stored name component caused the generic conflict. Preserve the separately approved middle-initial conflict without revealing stored values.

## Explicit production-path authorization

API-06 may create these operation-owned production files:

- `backend/src/cafe_fausse/validation/newsletter.py`
- `backend/src/cafe_fausse/services/newsletter_preferences.py`
- `backend/src/cafe_fausse/db/newsletter_gateway.py`
- `backend/src/cafe_fausse/http/routes/newsletter_preferences.py`

API-06 may narrowly modify these shared-foundation files when required for OP-04 only:

- `backend/src/cafe_fausse/application.py`
  - construct the OP-04 gateway/service and add the exact OP-04 request-classification mapping;
- `backend/src/cafe_fausse/dependencies.py`
  - add the narrow OP-04 service protocol/field for production and injected tests;
- `backend/src/cafe_fausse/http/blueprint.py`
  - register only `POST /api/v1/newsletter-preferences`;
- `backend/src/cafe_fausse/http/responses.py`
  - add only OP-04 result rendering and its approved error metadata/flags;
- `backend/src/cafe_fausse/http/error_handlers.py`
  - translate only the typed OP-04 known-failure and outcome-unknown categories not already handled;
- `backend/src/cafe_fausse/services/results.py`
  - add only the normalized OP-04 command, preference result, and exhaustive outcome/certainty categories required by API-03;
- `backend/src/cafe_fausse/db/exceptions.py`
  - add only mutation failure metadata/translation needed to preserve known-versus-unknown outcome certainty;
- `backend/src/cafe_fausse/serialization/common.py`
  - add only the pure OP-04 typed-result projection;
- `backend/src/cafe_fausse/validation/__init__.py`
  - add only intentionally public API-06 validation exports, if an export is actually needed;
- `backend/src/cafe_fausse/serialization/__init__.py`
  - add only intentionally public API-06 serializer exports, if an export is actually needed.

Conditional authorization is granted for a narrow modification to:

- `backend/src/cafe_fausse/services/retry.py`

Modify it only if Phase 0 proves that the accepted implementation cannot express API-03's certainty-aware mutation retry through its current public API. Preserve all read-retry and API-04/API-05 behavior. Do not change retry configuration, attempt limits, SQLSTATE policy, or deadline semantics. If no modification is required, leave it unchanged.

The following shared files are expected to remain unchanged unless Phase 0 finds a genuine missing, approved extension point:

- `backend/src/cafe_fausse/http/parsing.py`;
- `backend/src/cafe_fausse/config.py`;
- `backend/src/cafe_fausse/db/pool.py`;
- `backend/src/cafe_fausse/observability/logging.py`;
- `backend/src/cafe_fausse/observability/redaction.py`;
- `backend/src/cafe_fausse/timing.py`;
- API-04 health gateway, service, and routes;
- API-05 customer gateway, service, route, and identity rules except for reusable imports with no behavior change.

Also authorized:

- focused API-06 unit, API, and PostgreSQL integration tests;
- narrow updates to existing tests only when needed to assert an authorized shared-foundation extension or prevent regression;
- one API-06 programmer-test runner, or the smallest safe reusable refactor of the accepted API-05 runner if Phase 0 proves that avoids duplicated cleanup logic;
- `backend/TestInstructions.md`;
- `backend/README.md`, only where needed for accurate API-06 usage or test guidance;
- `backend/API06_IMPLEMENTATION_REPORT.md`.

Do not modify an approved API-05 report. Do not add a runtime dependency or lower any test, coverage, lint, type-checking, or safety threshold.

## Required automated tests

Add focused, deterministic tests at the approved layers.

### Validation tests

Cover at least:

- valid structured identity with `subscribed: true`;
- valid structured identity with `subscribed: false`;
- exact reuse of API-05 name, middle-initial, email, and confirmation normalization;
- omitted optional middle initial;
- invalid middle initial;
- missing `subscribed`;
- null `subscribed`;
- Boolean values accepted;
- integers `0` and `1` rejected;
- numeric, string, array, and object substitutes rejected;
- missing, null, non-string, empty, whitespace-only, and overlength identity fields;
- invalid email syntax;
- nonmatching confirmation email;
- confirmation email remaining transient;
- `phone` rejected as an unknown/prohibited field;
- all other unknown fields rejected;
- deterministic field-error order;
- parser failures remain governed by the shared parser rather than newsletter validation.

### Service and retry tests

Cover at least:

- new selected identity returns public `set/true`;
- new unselected identity returns `no_customer_no_change/false`;
- existing subscribed and unsubscribed transitions;
- same-state repeat for both Boolean states;
- customer identity conflict;
- middle-initial conflict;
- database routine invalid-request mapping;
- known pre-dispatch failure;
- conclusively rolled-back nonretryable failure;
- each approved retryable SQLSTATE after confirmed rollback;
- maximum-three-attempt enforcement;
- fresh attempt/transaction behavior;
- retry delay and jitter through injected timing;
- deadline exhausted before attempt;
- deadline exhausted or below one millisecond immediately after acquisition;
- deadline exhausted after retry sleep, with no next attempt;
- failure after dispatch with rollback confirmed;
- failure after dispatch with rollback uncertain;
- result-receipt uncertainty;
- commit uncertainty;
- no automatic retry for any unknown-outcome case;
- exact mapping to `temporary_failure` versus `newsletter_preference_outcome_unknown`;
- original failure preservation when cleanup also fails.

### Gateway tests

Cover at least:

- the exact authorized routine signature;
- fixed SQL with all values parameterized;
- normalized parameter order and nullable middle initial;
- Boolean passed as a Boolean;
- each stable routine outcome;
- valid outcome/value combinations;
- malformed rows, zero rows, multiple rows, unknown outcomes, non-Boolean states, and contradictory combinations rejected as contract defects;
- explicit `READ COMMITTED` transaction boundary;
- one routine business statement per attempt;
- result consumed before commit;
- success returned only after confirmed commit;
- rollback before any retry;
- lease/cursor/transaction cleanup on every path;
- unsafe connection discarded rather than normally returned;
- pool-acquisition time charged to the overall deadline;
- no transaction or routine SQL after an expired/sub-millisecond post-acquisition budget;
- no direct customer DML;
- no reservation or assignment access;
- no sensitive value or SQL leakage.

### API tests

Cover at least:

- exact method and route;
- exact three HTTP `200` response shapes;
- no distinction among created, changed, and already-in-state for public `set`;
- `409 customer_identity_conflict`;
- `409 middle_initial_conflict`;
- exact parser error mappings;
- exact `422 validation_failed` field envelope;
- phone and unknown-field rejection;
- unsupported method behavior;
- query-string rejection as required by API-02;
- `503 temporary_failure` with exact flags;
- `503 newsletter_preference_outcome_unknown` with exact flags;
- no `201` or `204`;
- uniform response headers;
- correlation behavior;
- no customer ID, prior state, database outcome, SQLSTATE, or internal-detail leakage;
- API-04 health and API-05 newsletter-status behavior unchanged.

### PostgreSQL-backed integration and concurrency tests

Use PostgreSQL 18.3 and the production application role. Cover at least:

- new identity plus `true` creates exactly one customer with subscribed state true;
- new identity plus `false` creates no customer;
- exact existing identity changes true to false;
- exact existing identity changes false to true;
- same-state repeat is idempotent for both states;
- unsubscribe retains the existing customer;
- generic identity mismatch changes nothing;
- middle-initial conflict changes nothing;
- existing names, middle initial, phone, and unrelated customer values are preserved;
- existing reservations and reservation-table assignments are preserved;
- confirmation email is not persisted;
- the application role succeeds through the routine but remains unable to perform direct customer DML;
- no second newsletter source exists or is written;
- direct database state matches every successful public response;
- concurrent same-canonical-email creation yields one customer;
- concurrent same-state requests remain idempotent;
- controlled opposing preference updates demonstrate last-committed valid write wins;
- each successful response is consistent with the value committed by that request;
- concurrent conflicting identities do not silently overwrite identity;
- approved retryable contention/deadlock/serialization paths use a new transaction and stay within three attempts;
- known rollback produces `temporary_failure` when retry cannot proceed;
- controlled no-dispatch failure performs no mutation;
- controlled post-dispatch/result/commit ambiguity maps to outcome unknown;
- identical resubmission after simulated ambiguous completion converges safely to the requested current state;
- all fixtures are owned, isolated, and removed after success and controlled failure;
- a preexisting same-email customer collision is preserved and never adopted for cleanup.

Use only existing database test seams that are authorized for the isolated test role/database. Do not add production failure injection or weaken production privileges.

## Regression requirements

Run all preexisting backend tests, including API-04 foundation and API-05 query tests.

Verify that API-06 does not change:

- startup, shutdown, health, or readiness behavior;
- OP-03 request, validation, lookup, deadline, retry, and error behavior;
- common parsing behavior outside the approved OP-04 request;
- common response envelopes or headers outside the approved OP-04 additions;
- correlation identifiers and safe logging;
- database failure classification for reads;
- pool and connection cleanup;
- existing public routes.

Do not modify an existing test merely to accommodate an unintended behavior change.

## Programmer test workflow and cleanup

Update `backend/TestInstructions.md` during this increment.

It must remain user-requested programmer-convenience documentation, not an SRS, rubric, contract, or approved-design authority.

Provide one recommended PowerShell command, run from the exact documented repository directory, that executes the complete current backend gate including API-06.

Prefer a dedicated API-06 runner with a unique task root such as:

- `%TEMP%\CafeFausse-api06-tests`

If a reusable refactor of the accepted API-05 runner is safer and smaller than a new independent runner, preserve the API-05 command and behavior, prove both runners, and avoid duplicated ownership/cleanup implementations. Do not casually rewrite accepted harness logic.

The documented workflow must be repeatable and restartable after success, ordinary failure, setup failure, cleanup failure, or interruption. It must not depend on manually deleting resources.

Before destructive test setup, require and validate the accepted explicit nonproduction authorization and PostgreSQL 18.3 guard. Localhost alone does not prove a cluster is nonproduction.

Durable non-secret ownership evidence must be created before potentially orphaned resources. Marker/resource mismatch, malformed evidence, ambiguous ownership, unexpected owner, or a preexisting collision must cause refusal without deletion.

Confine every runner-generated Python resource to the exact marker-owned task directory, including as applicable:

- virtual environments;
- pip/download/build caches;
- pytest caches;
- coverage data;
- bytecode caches;
- package metadata;
- logs and result files;
- temporary credential/passfile material.

Do not clean the repository by scanning for or deleting generic names such as `.venv`, `.pytest_cache`, `.coverage`, `__pycache__`, or `*.egg-info`. Preserve every preexisting repository or temporary resource unless the workflow proves ownership or captured and can restore its exact prior state.

Every database fixture must use unique run-owned identity values. Delete or restore a row only when the test can prove it created or changed that exact row. A generated-looking email or absent preflight observation alone is not deletion authority. Prefer returned IDs plus run markers and exact before-state snapshots. Preserve preexisting same-email customers and all their data.

The cleanup path must:

1. run after both success and ordinary failure through `finally`-style control;
2. execute independent bounded cleanup phases so one failure does not prevent later cleanup or environment restoration;
3. restore every changed process environment variable to its exact prior value or prior absence without displaying its value;
4. remove only proven test-owned rows, databases, schemas, roles, memberships, files, directories, passfiles, processes, listeners, and generated artifacts;
5. preserve the original test failure as primary when cleanup also fails;
6. report every cleanup failure prominently and return nonzero;
7. never claim complete cleanup while any proven test-owned resource remains;
8. support safe cleanup-only recovery on the next invocation when durable ownership is valid;
9. refuse deletion when ownership is ambiguous;
10. verify that the task root, task-owned processes/listeners, database objects, rows, environment changes, and generated repository artifacts are absent at completion.

Document:

- prerequisites and exact working directory;
- PostgreSQL 18.3 and Python requirements;
- credentials/environment setup without exposing secrets;
- explicit nonproduction authorization;
- the single recommended complete command;
- focused API-06 unit, API, integration, and concurrency commands;
- what the runner creates, changes, preserves, restores, and removes;
- success, failure, cleanup, and recovery markers;
- same-session and new-session repetition;
- restart after interruption;
- cleanup-only recovery, if supported;
- how to verify that no test-created resource remains;
- conditions that require stopping rather than deleting.

Do not modify `database/TestInstructions.md` or redesign the accepted database harness.

## Required workflow safety demonstrations

In addition to functional tests, demonstrate at least:

1. two consecutive clean complete API-06 workflow executions;
2. a controlled API-06 test failure returning nonzero followed by successful cleanup;
3. immediate complete restart after that failure;
4. a controlled cleanup-phase failure where later cleanup and exact environment restoration are still attempted;
5. interrupted-run recovery with valid ownership evidence;
6. malformed or mismatched ownership evidence refused without deletion;
7. preservation of a preexisting task-like database resource;
8. preservation of preexisting `.venv`, cache, coverage, bytecode, metadata, file, and directory sentinels byte-for-byte;
9. preservation of a preexisting same-email customer and related data;
10. exact restoration of every changed environment variable;
11. termination and disposal of task-owned child processes/listeners on every path;
12. absence of generated repository artifacts after cleanup;
13. a clean immediate rerun in both the same and a new PowerShell session model.

Failure injection must be explicit, isolated, and test-only. It must not weaken a production assertion or introduce a production switch.

## Documentation and examples

Update `backend/README.md` only as needed to describe the current approved backend surface and point to the programmer workflow.

State accurately that:

- API-01 through API-05 are approved before this work;
- API-06 is the current unapproved review increment until explicit acceptance;
- API-07 and later increments are not authorized;
- the runbook is convenience documentation rather than design authority.

Examples must come from the exact API-02 contract and include:

- new subscribe;
- new unsubscribe/no-customer-no-change;
- existing subscribe or unsubscribe;
- repeated same-state success;
- identity conflict;
- validation failure;
- known temporary failure;
- outcome-unknown failure and identical-request resubmission guidance.

Use fictitious data only. Include no credentials, real personal data, customer IDs, SQL, or internal database details.

## Verification gate

After implementation:

1. Run Windows PowerShell 5.1 parsing for every affected PowerShell script and every PowerShell block in `backend/TestInstructions.md`.
2. Run Python syntax/compilation checks for affected production and test modules.
3. Run all configured formatting, linting, and type checks. If none are configured, report that fact accurately.
4. Run focused API-06 validation tests.
5. Run focused API-06 service/retry tests.
6. Run focused API-06 gateway tests.
7. Run focused API-06 API tests.
8. Run API-06 PostgreSQL integration and concurrency tests against PostgreSQL 18.3.
9. Run all API-04 and API-05 regressions.
10. Run the complete current backend suite.
11. Run the configured coverage command and enforce the existing threshold.
12. Run two consecutive complete executions using the documented programmer workflow.
13. Run the controlled ordinary-failure, immediate-restart, cleanup-failure, interruption-recovery, ownership-refusal, preservation, and environment-restoration demonstrations.
14. Verify directly that all successful public results match committed PostgreSQL state.
15. Verify final PostgreSQL evidence for zero test-owned rows, databases, schemas, roles, memberships, sessions, or added membership edges.
16. Verify no task-owned process, listener, file, directory, passfile, environment change, virtual environment, cache, coverage file, bytecode directory, package metadata, or generated repository artifact remains.
17. Verify all preexisting sentinels and collision records are preserved exactly.
18. Measure and report API-06 timing evidence without changing approved deadlines or hiding contention.
19. Run `git diff --check`.
20. Confirm the real Git index remains unchanged and the review diff remains untracked.
21. Confirm that no database, frontend, approved-design, API-07-plus, or unrelated path changed.
22. Confirm that every changed production path is explicitly authorized above.

If a required tool is unavailable, report the exact limitation. Do not claim a check passed unless it ran successfully.

## Implementation report

Create:

- `backend/API06_IMPLEMENTATION_REPORT.md`

Include:

- starting full baseline commit;
- authoritative artifacts used;
- Phase 0 readiness and production-path audit;
- OP-04 requirement and contract traceability;
- scope and exclusions;
- exact production, test, runner, and documentation files changed;
- validation and normalization behavior;
- exact public result and error mapping;
- PostgreSQL routine call and privilege boundary;
- transaction, deadline, retry, rollback, commit, and outcome-certainty behavior;
- idempotency, new-customer, unsubscribe, and preservation behavior;
- concurrency and last-committed-write evidence;
- privacy, logging, and enumeration protections;
- test commands and unit/API/integration/combined counts;
- coverage;
- PostgreSQL and Python versions;
- two-run repeatability results;
- ordinary-failure, immediate-restart, cleanup-failure, and interrupted-recovery results;
- preexisting-resource and collision-preservation evidence;
- exact environment-restoration evidence;
- final cleanup evidence;
- timing evidence and any contention limitation;
- static-verification results;
- warnings, deviations, or unresolved issues;
- confirmation that API-07 and React were not started;
- the API-06 approval checkpoint.

Report actual results only. Counts, changed-path lists, diff scope, and cleanup claims must match the final repository state.

## Review diff

Generate a complete task-only diff from the recorded Phase 0 baseline through the final uncommitted API-06 state.

Name it:

- `CafeFausse_API06_COMPLETE.diff`

The diff must:

- use the exact full API-06 baseline commit;
- include baseline-to-current tracked and untracked API-06 changes;
- contain only authorized API-06 source, tests, runner, documentation, and report paths;
- include all necessary new files;
- be byte-preserving Git unified-diff output;
- be valid UTF-8 without a UTF-16 encoding mismatch;
- exclude generated test artifacts and all database/frontend paths;
- contain no credentials or secrets;
- reverse-apply or cached-apply cleanly against the stated baseline as appropriate.

Report:

- baseline commit;
- diff path;
- byte size;
- encoding and BOM status;
- exact included-path count and list;
- SHA-256;
- apply/reverse-apply validation result.

Do not add the diff to Git.

## Completion response

At completion, report:

- Phase 0 findings and `READY - API-06` evidence;
- exact changed paths;
- implementation summary;
- contract and requirement traceability;
- every command executed;
- all focused and complete test counts/results;
- coverage;
- PostgreSQL and Python versions;
- timing evidence;
- consecutive-run results;
- ordinary-failure, cleanup-failure, restart, recovery, and ownership-refusal results;
- final cleanup and preexisting-resource-preservation evidence;
- diff metadata and validation;
- Git status and index status;
- unresolved issues or deviations;
- confirmation that database, approved design, frontend, API-07-plus, and unrelated files were unchanged;
- confirmation that React was not started;
- the API-06 approval checkpoint.

Do not commit, push, amend, rebase, tag, or create a pull request.

Stop at the API-06 review checkpoint and wait for explicit approval.
