# Prompt 12 - Design Flask architecture, configuration, and test strategy

**Prompt version:** 1.0  
**Date:** 2026-08-21  
**Roadmap increment:** API-03 - Flask Architecture, Configuration, and Test Strategy  
**Authorized baseline:** API-02 version 1.0.1 approved and committed  
**Execution type:** Design-only phase gate with mandatory read-only verification

Begin only **API-03 - Flask Architecture, Configuration, and Test Strategy** of the approved least-to-most implementation roadmap.

Work in the repository-connected Codex environment with the Cafe Fausse repository root open. Design the smallest clear Flask architecture, runtime-configuration model, PostgreSQL access boundary, error and retry structure, and pytest strategy capable of implementing the approved API-01 operation inventory and API-02 REST contract.

This is a design and phase-gate increment. Do not generate application code, tests, package manifests, setup files, or executable configuration.

Do not begin API-04 or any later increment.

## Authoritative sources

Use the following as authoritative, in this order:

1. `AGENTS.md` and any more-specific applicable repository instructions;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. `docs/approved-design-artifacts/Cafe_Fausse_Project_Requirements_Baseline.md`, version 1.0, if present and cited by the approved API artifacts;
5. `docs/approved-design-artifacts/Cafe_Fausse_Project_Requirements_Addendum.md`, version 2.2.1, including PRA-001 through PRA-029;
6. `docs/approved-design-artifacts/Cafe_Fausse_DB01_Persistent_Data_Requirements_Analysis.md`, version 1.2.1;
7. `docs/approved-design-artifacts/Cafe_Fausse_DB02_Conceptual_Data_Model.md`, version 1.2;
8. `docs/approved-design-artifacts/Cafe_Fausse_DB03_Logical_PostgreSQL_Schema.md`, version 1.1;
9. `docs/approved-design-artifacts/Cafe_Fausse_DB04_Reservation_Transaction_and_Concurrency_Design.md`, version 1.1;
10. the approved DB-05, DB-06, and DB-07 implementation, verification, completion, and manual-demonstration evidence in `database/`;
11. `database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, approved and frozen version 1.0;
12. `docs/approved-design-artifacts/Cafe_Fausse_API01_Backend_Operation_Inventory.md`, approved version 1.0.1;
13. `docs/approved-design-artifacts/Cafe_Fausse_API02_Flask_REST_Contract.md`, approved version 1.0.1;
14. `docs/approved-design-artifacts/Cafe_Fausse_Least_to_Most_Implementation_Roadmap.md`, version 1.1.1;
15. the current repository state needed to verify exact filenames, database signatures, grants, runtime scripts, and the absence or presence of Flask implementation.

DB-01 through DB-07, Hard Gate 1, API-01, and API-02 are approved. API-02 version 1.0.1 was approved and committed before this prompt was authorized. Treat every approved requirement, database decision, operation, route, HTTP method, wire field, outcome mapping, retry semantic, privacy boundary, and Version 1 exclusion as fixed.

Do not reopen or silently reinterpret an approved decision unless a genuine implementation-blocking contradiction is found. If such a contradiction exists, stop and request approval rather than selecting a replacement.

The current repository is authoritative for the exact paths and content. Locate and read the actual files; do not rely only on names, versions, signatures, or summaries copied into this prompt.

## Accepted baseline

Treat the following as approved facts rather than API-03 design questions:

- PostgreSQL 18.3 is the sole required Version 1 PostgreSQL target.
- `pgcrypto` is an approved required database extension.
- Hard Gate 1 passed and the PostgreSQL Contract for Flask version 1.0 is frozen.
- PostgreSQL remains authoritative for persistence, configuration, recurring hours, customer uniqueness, provisional availability, final booking validation, exact retry, concurrency, allocation, assignments, and atomic commit or rollback.
- Flask may use only the read paths, roles, privileges, and three production database operations authorized by the frozen contract.
- Flask must not directly read reservations or reservation-table assignments or directly write business tables.
- API-01 defines exactly seven conceptual operations, OP-01 through OP-07.
- API-02 version 1.0.1 defines exactly seven Version 1 endpoints:
  - `GET /api/v1/reservation-context`;
  - `GET /api/v1/reservation-availability`;
  - `POST /api/v1/newsletter-status-queries`;
  - `POST /api/v1/newsletter-preferences`;
  - `POST /api/v1/reservations`;
  - `GET /api/v1/health/liveness`;
  - `GET /api/v1/health/readiness`.
- OP-04 uses application-level idempotency by setting a final Boolean preference through `POST /api/v1/newsletter-preferences`.
- OP-05 uses ordinary identical request resubmission and PostgreSQL exact-retry behavior; clients do not supply an idempotency key, fingerprint, customer ID, reservation ID, assigned table, duration, end time, or availability assertion.
- `reservation_confirmation_unavailable` means a reservation is known to exist but the separate post-commit stored-name read failed. It has `retryable:true` and `outcome_unknown:false`.
- `reservation_outcome_unknown` means the reservation transaction's commit outcome cannot be proven. It is distinct from confirmation reconstruction failure.
- `reservation_unavailable` has `retryable:false`; the caller must refresh availability or choose another slot rather than repeat the same unchanged request.
- In API-02, `retryable:true` means unchanged complete-request resubmission is an appropriate recovery action. It does not merely mean that a different request might succeed.
- All Version 1 responses require `no-store` semantics.
- PostgreSQL `BIGINT` reservation references are exposed as decimal JSON strings, not JSON numbers.
- No public customer identifier, fingerprint, database outcome literal, table-capacity fact, free-table fact, SQL detail, or internal diagnostic may leak.
- The accepted database performance record includes general allocation p95 near 1.14-1.27 seconds in the DB-07 environment. Contended five- and eight-request cases can exceed two seconds under the approved restaurant-wide coordination lock. API-03 must not promise a stronger result or redesign that approved lock.
- The SRS two-second form-submission expectation remains a later executable measurement and full-stack gate, not a guarantee to invent in a design artifact.

## API-03 objective

Produce one approved, non-executable architecture and test-strategy artifact that allows API-04 through API-09 to implement the frozen operations and REST contract without inventing architecture, configuration, dependency, database-lifecycle, retry, error, privacy, or testing rules while coding.

API-03 must decide and document:

- the Flask application shape and application-factory lifecycle;
- the backend package and test-directory structure;
- module responsibilities and permitted dependency directions;
- route, validation, service, PostgreSQL gateway, error, configuration, health, and logging boundaries;
- the minimum runtime and test dependencies and why each exists;
- the supported Python runtime policy for this project;
- input parsing, duplicate-JSON-member detection, normalization, validation, and output serialization ownership;
- PostgreSQL driver and connection-pool strategy;
- connection, cursor, transaction, commit, rollback, and cleanup ownership;
- operation-specific database-call sequences, especially OP-05's committed booking followed by its separate customer-name projection;
- transient error classification and bounded retry placement;
- exact numeric timeout, retry-attempt, backoff, and jitter configuration decisions assigned to API-03;
- error translation and safe response assembly without changing API-02;
- `no-store`, JSON media type, CORS, request-size, and other relevant HTTP policy implementation points;
- structured logging, privacy redaction, secret handling, and internal diagnostics;
- liveness and readiness architecture;
- dependency injection and deterministic test seams;
- pytest suite organization, fixtures, markers, isolation, and database-test lifecycle;
- the required unit, validation, API, PostgreSQL-integration, failure-injection, and performance test coverage;
- the boundary among API-04 through API-09 and later React/integration work.

The result must be understandable, proportional to an academic Version 1 application, and specific enough that API-04 can implement the Flask foundation without reopening API-03.

## Phase 0 - mandatory read-only repository verification

Perform this verification before creating or modifying the API-03 artifact. This phase is part of Prompt 12; a separate verification prompt is not required.

### Verification actions

1. Identify the repository root and read the root `AGENTS.md` plus any applicable nested instruction files.
2. Run read-only Git inspection sufficient to record:
   - current branch;
   - upstream relationship where configured;
   - staged changes;
   - tracked modifications;
   - untracked files.
3. Do not discard, overwrite, stage, commit, stash, move, or reformat any existing user work.
4. Locate and read every authoritative source listed above.
5. Confirm the exact source filenames and authoritative version headers.
6. Confirm that DB-07 Hard Gate 1, API-01 version 1.0.1, and API-02 version 1.0.1 contain explicit approval records consistent with the user's authorization.
7. Confirm that `database/POSTGRESQL_CONTRACT_FOR_FLASK.md` remains version 1.0 and frozen.
8. Read the exact database operation signatures, stable outcomes, SQLSTATE/retry guidance, roles, grants, and read restrictions from the contract and implemented migrations rather than copying them from an earlier prompt.
9. Confirm the API-01 seven-operation catalogue and the API-02 seven-endpoint bijection.
10. Verify that every API-02 non-executable JSON example remains parseable and that the approved OP-04 method/path, OP-05 recovery codes, and `retryable` semantics are present without stale alternatives.
11. Inspect `backend/` and its current Git history only to establish its existing state. Do not modify it during verification.
12. Inspect existing root or backend dependency/configuration files, if any, without installing packages or changing environments.
13. Confirm the roadmap definition of API-03 and the boundary that API-04 is the next implementation increment.
14. Confirm that no required API-03 decision would force a PostgreSQL, API-01, or API-02 change.
15. Record the initial repository state and evidence paths for the API-03 artifact.

### Verification result and gate behavior

Provide a concise progress result before authoring:

- `READY` when the repository is internally consistent and API-03 may proceed; or
- `NOT READY` with exact blockers when it may not.

If `READY`, continue automatically with API-03 in the same run. Do not wait for a second authorization merely because verification passed.

If `NOT READY`, stop immediately and make no file changes. A blocking condition includes any of the following:

- missing or unreadable authoritative sources;
- missing or inconsistent API-01/API-02 approval records;
- API-02 not at approved version 1.0.1;
- a material mismatch among API-01, API-02, the frozen PostgreSQL contract, and implemented database privileges or signatures;
- unresolved working-tree changes that overlap the intended API-03 artifact;
- Flask implementation already present that embodies unapproved architecture or makes API-03 retrospective rather than prospective;
- a required API-03 choice that needs a new business rule, REST-contract change, database change, privilege expansion, or PostgreSQL schema/routine change.

Do not treat accepted historical naming corrections, approved version-history explanations, or already-resolved warnings as blockers without new material evidence.

## Hard scope boundary

After a `READY` result, API-03 may create or update only:

`docs/approved-design-artifacts/Cafe_Fausse_API03_Flask_Architecture_Configuration_and_Test_Strategy.md`

Do not modify any other path unless a genuinely unavoidable documentation-reference correction is first reported and explicitly approved.

Do not generate or modify:

- Flask or Python source code;
- executable validation or serialization code;
- SQL, migrations, stored routines, grants, roles, or database tests;
- `requirements.txt`, `pyproject.toml`, lock files, virtual environments, or installed dependencies;
- environment files, secrets, example secrets, connection strings, or deployment credentials;
- pytest files, fixtures, executable mocks, coverage configuration, or CI workflows;
- OpenAPI, JSON Schema, Postman collections, or executable contract specifications;
- React, JSX, CSS, browser logic, mocks, or frontend tests;
- Dockerfiles, container definitions, reverse-proxy configuration, hosting configuration, or production deployment files;
- API-04 Flask foundation implementation;
- API-05 through API-09;
- React or integration increments;
- any approved database or API design artifact.

Use non-executable catalogues, responsibility tables, dependency matrices, directory trees, sequence descriptions, decision records, and test plans. Prefer Markdown tables and indented trees. If Mermaid is used, validate every Mermaid block against Mermaid 11.13-compatible syntax before completion; a diagram parse error is a defect.

## Architecture principles

Select and justify a design that preserves all of these principles:

- one clear Flask application factory and explicit startup lifecycle;
- thin route handlers;
- validation and wire serialization separated from business orchestration;
- one service/orchestration boundary per approved operation or a rigorously justified minimal grouping;
- PostgreSQL access isolated behind explicit gateways or equivalent adapters;
- parameterized, schema-qualified database calls only;
- no ORM entity model that competes with the approved PostgreSQL schema;
- no duplication of allocation, overlap, exact-retry, configuration, hours, capacity, or transaction rules in Flask;
- explicit error translation from internal/domain/database categories to the frozen API-02 contract;
- configuration supplied from the environment or another justified runtime source, never hardcoded secrets;
- safe construction and deterministic teardown of database pools and other resources;
- testability without process-global mutable business state;
- dependency directions that prevent routes and validation modules from bypassing services or database gateways;
- enough separation for clarity without speculative frameworks, generic repositories, command buses, event buses, plugins, or microservices.

Compare reasonable alternatives only where a real API-03 decision exists. Select one primary Version 1 approach and reject unnecessary complexity.

## Required project and module structure

Define the proposed logical tree under `backend/` and explain every planned file or directory. At minimum, establish logical homes for:

- application factory and application lifecycle;
- runtime configuration and configuration validation;
- route registration and Version 1 blueprints or equivalent grouping;
- shared request parsing and protocol checks;
- customer-input normalization and validation;
- operation-specific validation and serialization;
- service/orchestration logic;
- PostgreSQL connection pool and connection lifecycle;
- operation-specific PostgreSQL gateway calls;
- internal outcome and error categories;
- API-02 error-envelope creation and global handlers;
- security/cache/media-type response policy;
- liveness and readiness;
- structured logging and redaction;
- tests, fixtures, helpers, and markers.

For every module or package, specify:

- purpose;
- allowed imports/dependencies;
- prohibited responsibilities;
- whether it contains pure logic, Flask coupling, PostgreSQL coupling, or test-only support;
- API-04 through API-09 implementation ownership.

Provide a dependency-direction matrix proving that:

- routes do not issue SQL;
- validators do not mutate data;
- database gateways do not construct public HTTP responses;
- services do not depend on React or request-global state;
- public error construction does not expose database exceptions;
- tests can replace gateways or clocks/randomness only through explicit seams.

## Application factory and lifecycle

Select and specify:

- application-factory use and inputs;
- when configuration is loaded and validated;
- when blueprints/routes are registered;
- when error handlers and response policies are installed;
- when the PostgreSQL pool is created;
- how pool ownership is attached to the application without uncontrolled globals;
- development/test/production lifecycle differences;
- how startup failure differs from readiness failure;
- how resources close during normal shutdown and test teardown;
- how Flask application context and request context are used without hiding transaction ownership;
- how repeated application creation in pytest avoids state leakage.

Do not implement the factory or choose a deployment server in API-03 unless the roadmap explicitly assigns that choice here. Local development and test startup requirements may be designed; hosting topology remains deferred.

## Runtime and dependency decisions

Provide a minimum dependency catalogue. Evaluate and select, with rationale:

- supported Python runtime/version policy;
- Flask versioning policy;
- direct `psycopg` 3 access versus SQLAlchemy or another database layer;
- whether a separate PostgreSQL pool package is needed;
- manual validation versus a focused validation/serialization library;
- timezone and IANA validation support available from the Python standard library versus a dependency;
- pytest and only the test plugins that add concrete value;
- structured logging through the standard library versus another package;
- CORS handling through native response policy versus an extension.

For each selected dependency, state:

- purpose;
- runtime or test-only classification;
- why the standard library or an already selected package is insufficient;
- compatibility and pinning policy to be implemented later;
- security/update implications;
- the first authorized increment that may add it.

Do not install packages, write manifests, or invent a dependency because it is fashionable. Avoid an ORM unless it provides a demonstrated benefit without weakening the frozen database boundary.

## Configuration design

Define one authoritative runtime-configuration catalogue covering at least:

- application environment name;
- Flask debug/testing flags and safe defaults;
- PostgreSQL connection source, application role, and database selection;
- pool minimum/maximum size and acquisition timeout;
- connection timeout;
- statement timeout or equivalent per-operation deadline mechanism;
- lock timeout behavior where applicable;
- bounded transient retry attempts;
- backoff base/cap and jitter policy;
- maximum request-body size;
- allowed CORS origins or same-origin-only policy;
- log level and log format;
- whether internal correlation identifiers are used without adding them to the public API;
- test-only configuration and safeguards;
- readiness deadline;
- any explicit feature flag that is truly necessary.

For every setting, define:

- stable configuration name to be implemented later;
- type;
- allowed range or values;
- whether required in development, test, and deployed environments;
- safe default, if any;
- secret versus non-secret classification;
- validation timing;
- failure behavior;
- authoritative owner;
- rationale.

Prefer existing libpq/PostgreSQL environment conventions where they provide one source of truth. If a consolidated DSN is selected instead, explain how duplicate connection settings are avoided. Never put passwords, full connection strings, secrets, or real credentials in the design artifact.

Do not reuse reset authorization as application runtime configuration. The Flask application role must never receive reset, migration, verification-helper, test-helper, DDL, or elevated writer capability.

## Numeric timeout and retry design

API-03 must choose exact Version 1 numeric defaults and permitted configuration bounds for application-owned timeouts and retries. Do not defer every number to implementation.

Define separately:

- HTTP/request processing budget as an internal target, not a guaranteed public SLA;
- pool acquisition timeout;
- database connect timeout;
- read-only operation timeout;
- booking/preference operation timeout;
- readiness timeout;
- retry-eligible SQLSTATEs and connection conditions;
- maximum full-operation attempts;
- exponential or other bounded backoff calculation;
- jitter range;
- behavior when the remaining request budget cannot support another attempt;
- classification of known rollback, unknown commit, lock timeout, deadlock, serialization failure, pool exhaustion, connection loss, and unexpected driver failure.

Preserve the frozen three-attempt maximum where required by the approved upstream design. Every retry of a database operation must restart the full relevant database attempt, reacquire authoritative facts and locks, and avoid replaying an already proven committed mutation.

Prove that retry placement preserves:

- OP-04 final-state idempotency;
- OP-05 exact-retry recovery;
- no replay of booking-linked newsletter mutation after a known commit;
- `reservation_confirmation_unavailable` as known committed state;
- `reservation_outcome_unknown` as uncertain commit state;
- API-02 `retryable` semantics;
- the accepted PostgreSQL contention tradeoff.

Do not claim that configured timeouts prove the SRS two-second expectation. Define what later performance tests must measure.

## PostgreSQL access and transaction ownership

Define the database adapter/gateway contract for OP-01 through OP-07 using the exact frozen contract and implemented privileges.

For each operation specify:

- exact authorized table projection or controlled routine;
- input adaptation;
- returned database facts consumed internally;
- transaction mode and isolation expectation;
- commit and rollback owner;
- connection return/discard rule;
- timeout and retry classification;
- safe internal result object or category;
- prohibited direct reads, writes, or SQL;
- expected test double boundary.

Address these required sequences explicitly:

### OP-01 current reservation context

- one coherent read-only snapshot of current configuration, seven weekday hours, exactly 30 positive-capacity tables, capacity-derived maximum party size, and database-clock-derived date bounds;
- no fabricated defaults or application-owned authoritative cache.

### OP-02 provisional availability

- exact controlled routine call;
- all legitimate starts returned, including unavailable starts;
- no persisted availability, holds, candidates, or allocation state.

### OP-03 newsletter-status query

- minimal authorized customer projection by canonical email;
- identity matching and privacy boundary;
- no mutation, profile return, or customer creation.

### OP-04 newsletter preference

- exact controlled routine call;
- final-state application idempotency;
- safe handling of known rollback versus unknown mutation outcome.

### OP-05 reservation creation or reconstruction

Define a precise non-executable sequence that preserves the approved two-stage behavior:

1. obtain a connection and establish the required transaction context;
2. invoke the exact controlled booking routine with only approved server-normalized facts;
3. classify the database result or exception;
4. when a new booking or exact retry is known successful, commit or otherwise establish the routine transaction's committed outcome before confirmation-name reconstruction;
5. only then perform the separate minimal authorized `customers` read by canonical email for stored first name, optional middle initial, and last name;
6. assemble the confirmation using stored display spelling, never request casing;
7. if that name read fails, return the API-02 `reservation_confirmation_unavailable` category without rolling back, deleting, or describing the known reservation as uncertain;
8. if booking commit is genuinely uncertain, do not misclassify it as a confirmation-read failure;
9. on identical resubmission, allow PostgreSQL exact retry to reconstruct the existing reservation and ignore replayed customer/contact/newsletter mutation as approved.

Explain whether the separate name read uses the same physical connection after commit or another pooled connection, and why. Preserve clean transaction state and reliable connection reuse.

### OP-06 and OP-07 health

- liveness is process-local and does not claim database readiness;
- readiness is a short, non-mutating, least-privilege check of the minimum approved PostgreSQL prerequisites;
- neither endpoint performs migration, reset, seed, DB-07 verification, test booking, or destructive work;
- public output reveals no server version, extension, role, schema, row count, SQL, credential, or failed internal check.

## Validation and serialization architecture

Define one implementation-neutral but complete validation pipeline for all API-02 rules:

1. method and route selection;
2. content type and body-presence checks;
3. UTF-8 and JSON parsing;
4. detection and rejection of duplicate JSON object members;
5. top-level object and unknown-field checks;
6. type, presence, omission, null, empty-string, numeric-form, and length checks;
7. Unicode-aware whitespace and name normalization;
8. canonical email and confirmation-email comparison;
9. middle-initial and phone rules;
10. date, local date-time, offset, DST, and integer validation;
11. cross-field validation;
12. service/database orchestration;
13. internal outcome translation;
14. success serialization or common API-02 error envelope;
15. final media-type, cache, and security response policy.

Choose where reusable schemas/validators live and how they remain pure enough for unit tests. Document how the design will preserve:

- API-02's exact request fields and rejection of unknown/server-controlled fields;
- distinction between omission, `null`, and empty string;
- no lossy Boolean or integer coercion;
- accepted email profile;
- no display-changing Unicode normalization not approved by API-02;
- restaurant timezone rather than browser or host timezone;
- decimal-string reservation references;
- stable ordering of weekday hours, slots, and assigned tables;
- all 36 approved JSON examples;
- safe messages and field errors without stack traces or database literals.

Do not create a second public contract, OpenAPI schema, or JSON Schema in API-03.

## Error handling and outcome translation

Define the internal error taxonomy and translation flow for:

- protocol/router errors;
- JSON/media-type errors;
- field and cross-field validation;
- API-01 business outcomes;
- stable PostgreSQL routine outcomes and details;
- database configuration failures;
- pool and connection failures;
- known rollback and transient exhaustion;
- unknown mutation outcome;
- known booking plus failed confirmation-name reconstruction;
- unexpected application errors;
- liveness/readiness failures.

Map ownership to the complete API-02 status/error catalogue without changing any HTTP status, public code, Boolean flag, or response shape.

Specify:

- which layer raises or returns each internal category;
- which layer maps it to API-02;
- which details are safe for logs only;
- which details must be redacted even from ordinary logs;
- rollback/cleanup responsibility;
- whether retry occurs before or after translation;
- how global Flask handlers prevent HTML error pages;
- how `404`, `405`, oversized body, malformed JSON, and unexpected exceptions receive the common JSON envelope;
- how no public response exposes SQLSTATE, SQL, relation/routine names, driver types, credentials, or stack traces.

## HTTP, privacy, and security policy

Design, without implementing:

- exact `Cache-Control` and related headers needed to achieve API-02 no-store semantics;
- JSON response media type and character encoding;
- request content-type enforcement;
- request-size protection;
- same-origin versus configured-origin CORS policy, including development behavior;
- why wildcard credentialed CORS is prohibited;
- treatment of cookies, sessions, authentication, CSRF, and credentials given the approved unauthenticated Version 1 scope;
- safe host/proxy assumptions deferred to deployment;
- security headers that belong at Flask versus a later deployment layer;
- prevention of PII in URLs, caches, logs, exception text, metrics labels, and readiness diagnostics;
- safe handling of confirmation email as transient input only;
- secret loading and redaction;
- parameterized database calls and schema qualification.

Do not add authentication, accounts, sessions, tokens, rate-limit business behavior, CAPTCHA, ownership verification, or a new public correlation field. If an internal request correlation value is selected, it must not alter the frozen response contract.

## Logging and observability design

Define a minimal structured logging catalogue containing only justified fields such as:

- event name;
- severity;
- operation/endpoint identifier;
- outcome category;
- elapsed time;
- retry attempt/class;
- internal correlation value if selected;
- coarse readiness component;
- exception class or SQLSTATE only under tightly controlled internal logging when safe.

Define an explicit never-log list including raw or normalized names, email, confirmation email, phone, newsletter request content, reservation fingerprint, full request/response bodies, connection string, password, SQL parameters, assigned-table combinations where unnecessary, stack traces in public responses, and secrets.

Explain:

- redaction responsibility;
- production versus development exception logging;
- how logs remain useful for retry, ambiguity, timeout, and performance diagnosis;
- how tests prove redaction without requiring real PII;
- what metrics/tracing remain deferred.

Do not build a generic audit log or persistent business-event history.

## pytest architecture and test taxonomy

Define a concrete, non-executable pytest structure with at least these categories:

1. **Pure unit tests**
   - normalization;
   - validators;
   - serializers;
   - internal outcome objects;
   - database-to-domain translation;
   - domain-to-HTTP mapping;
   - retry/backoff calculations;
   - redaction;
   - configuration parsing and validation.

2. **Flask API tests with controlled dependencies**
   - application factory and route registration;
   - exact methods and paths;
   - request parsing and validation;
   - all success/error envelopes and headers;
   - unknown routes, methods, fields, query parameters, media types, malformed JSON, duplicate JSON keys, oversized requests, and unhandled exceptions;
   - liveness and dependency-controlled readiness;
   - no direct PostgreSQL requirement unless explicitly marked integration.

3. **PostgreSQL integration tests**
   - run against an isolated nonproduction PostgreSQL 18.3 database;
   - use approved migrations and controlled reset/rebuild tooling;
   - exercise the actual application role and privileges;
   - use real controlled routines and authorized read paths;
   - verify OP-01 through OP-05 and readiness mapping;
   - verify no forbidden direct access;
   - prove commit, rollback, exact retry, ambiguity, and post-commit confirmation-read handling at the Flask boundary.

4. **Failure-injection and multi-session integration tests**
   - known rollback;
   - retryable SQLSTATEs;
   - retry exhaustion;
   - pool acquisition timeout;
   - connection loss before work;
   - connection loss with unknown mutation outcome;
   - booking success followed by stored-name read failure;
   - concurrent identical and conflicting requests;
   - application-level newsletter idempotency;
   - stale availability followed by booking.

5. **Performance-oriented tests and measurement**
   - representative uncontended context, availability, newsletter, and booking calls;
   - contended booking scenarios consistent with DB-07;
   - warm-up, sample count, percentile, pool-wait, database, Flask, and end-to-end timing separation;
   - no unsupported claim that a unit test proves the SRS two-second expectation.

For the proposed test tree, define:

- filename and directory naming rules;
- pytest markers;
- fixture scopes;
- application/pool/database lifecycle;
- test-data builders or factories;
- deterministic clock/timezone strategy;
- deterministic retry/backoff/random test seams;
- HTTP client strategy;
- gateway fakes/stubs and their limits;
- real database role and migration use;
- reset safeguards;
- parallel-test policy;
- failure-injection mechanism boundaries;
- assertion helpers for the common envelope, headers, privacy, and JSON parsing;
- coverage measurement policy and why branch/requirement coverage matters more than an arbitrary percentage alone.

Tests must not require production credentials or reset a production database. Test-only seams must be structurally unavailable or disabled in normal production behavior and must not change the approved PostgreSQL schema or public API.

## Minimum non-executable test coverage catalogue

Map every API-02 contract test and integration case into the API-03 test architecture. Include at least:

- all seven endpoints and exact allowed methods;
- all 36 approved JSON examples;
- common error envelope invariants;
- `Content-Type` and `no-store` headers on success and errors;
- body-required, invalid JSON, duplicate members, non-object JSON, unsupported media type, body-on-GET, unknown field, extra/repeated query parameter, 404, and 405;
- names, whitespace, Unicode letters, middle initial, email profile/confirmation, and phone rules;
- Boolean and bounded-integer non-coercion;
- restaurant-local dates, offsets, DST ambiguity/nonexistence, alignment, opening/closing, advance window, and lead time;
- OP-01 coherent foundation snapshot and unusable configuration;
- OP-02 available, all unavailable, empty legitimate-slot list, and stale snapshot;
- OP-03 matched, not found, mismatch, middle conflict, and indeterminate lookup;
- OP-04 new subscribe, existing subscribe/unsubscribe, nonexistent false/no customer, repeated same final state, conflict, retry, and outcome unknown;
- OP-05 new booking, phone notice, exact retry, unavailable, same-customer overlap, validation/configuration conflict, known transient failure, retry exhaustion, unknown outcome, stable decimal-string reference, stored-name display reconstruction, and `reservation_confirmation_unavailable`;
- identical retry after lost response without newsletter replay;
- different-customer overlap when capacity permits;
- liveness independent from database readiness;
- readiness success and safe coarse failure;
- privacy/redaction and forbidden response fields;
- denied direct reservation/assignment access and denied writes;
- cleanup after every request, rollback, exception, and test.

## Operation-to-layer design

For OP-01 through OP-07 provide a complete matrix containing:

- API-02 endpoint;
- route/controller responsibility;
- validator/serializer responsibility;
- service/orchestrator responsibility;
- PostgreSQL gateway responsibility;
- transaction and retry owner;
- success result type;
- internal failure categories;
- public mapping owner;
- unit-test boundary;
- API-test boundary;
- PostgreSQL-integration boundary;
- first implementation increment.

Do not create a generic CRUD service or generic repository that obscures the seven approved operations.

## API-04 through API-09 implementation boundaries

Use the current roadmap's exact increment names and assign planned modules/tests to the correct increment. At minimum, keep these conceptual boundaries:

- API-04 implements only the Flask foundation, configuration, connectivity, shared errors/responses, liveness/readiness, and test infrastructure authorized by the roadmap;
- later increments implement reservation context/availability, newsletter behavior, reservation creation/retry, and broader verification only in their approved order;
- React remains unimplemented and non-authoritative;
- live React-Flask integration and final performance acceptance remain later integration work.

If the current roadmap uses more specific or different API-05 through API-09 names, quote and follow the repository rather than inventing names.

Provide a future file-creation matrix showing which planned backend files first appear in which increment. This is a plan only; do not create those files in API-03.

## Alternatives to evaluate

Compare and decide only the alternatives that materially affect API-03, including:

- application factory versus module-level singleton app;
- Flask blueprints versus one route module;
- operation-specific gateways versus generic repository abstraction;
- direct psycopg access versus SQLAlchemy;
- psycopg pool versus per-request connections;
- validation library versus disciplined manual validation;
- exception-based versus explicit-result internal outcomes;
- route-level versus service-level retry orchestration;
- one transaction wrapper for all operations versus operation-specific transaction policies;
- standard-library structured logging versus an added logging package;
- same-origin policy versus narrowly configured CORS;
- test database per run versus another isolated reset strategy.

For each selected approach, explain correctness, simplicity, teaching value, testability, deployment impact, and compatibility with the frozen PostgreSQL/API contracts. Reject speculative enterprise patterns.

## Normal operation and failure sequences

Provide compact non-executable sequence specifications for at least:

1. OP-01 successful current-context read;
2. OP-02 successful provisional availability request;
3. OP-04 successful preference update;
4. OP-04 transient failure followed by bounded full-attempt retry;
5. OP-05 successful new reservation and post-commit name reconstruction;
6. OP-05 exact retry after a lost response;
7. OP-05 known booking followed by failed name read;
8. OP-05 connection loss with unknown commit outcome;
9. request validation failure before database access;
10. liveness success while readiness fails safely.

Each sequence must identify configuration, pool acquisition, validation, service, gateway, transaction, commit/rollback, retry, response mapping, logging, and cleanup ownership where applicable.

## Performance and explainability assessment

Assess the selected architecture against the SRS expectation that reservation and newsletter submissions should normally complete within two seconds.

Do not promise an unsupported benchmark. Instead:

- preserve the accepted DB-07 measurements and contention limitations;
- identify Flask-added work such as parsing, validation, pool acquisition, database round trips, post-commit name read, serialization, and logging;
- define timing instrumentation boundaries without exposing PII;
- explain how pool sizing and timeout choices interact with the restaurant-wide booking lock;
- define representative API-08/API-09 and integration measurements;
- specify p50, p95, p99, maximum, error rate, pool wait, database time, and total request time evidence where appropriate;
- state how an academic demonstration can clearly explain correctness, exact retry, failure recovery, and measured limitations.

Correctness, privacy, and atomicity take priority over hiding contention with unsafe retries or enlarged pools.

## Version 1 exclusions

Do not introduce architecture, configuration, modules, dependencies, endpoints, or tests for:

- authentication, authorization, customer accounts, sessions, passwords, tokens, or ownership verification;
- customer profiles, automatic prefill, or general customer updates;
- reservation lookup, listing, cancellation, modification, rescheduling, no-show, administration, or history;
- temporary holds, waiting lists, queues, background jobs, or asynchronous booking;
- customer-selected tables, seat sharing, adjacency, combinability, or seat-level assignment;
- holiday/date-specific schedules, recurring closed days, overnight hours, or multiple periods;
- configuration, schedule, newsletter, reservation, or audit history;
- email or SMS confirmation delivery;
- payments, ordering, loyalty, analytics, or administrative content management;
- persistent availability, slots, candidates, rankings, retry events, or random history;
- ORM-managed schema creation or Flask-side migrations;
- database reset, seed, verification, performance, or test-helper endpoints;
- automatic schema migration at Flask startup;
- background health repair or readiness-triggered mutation;
- GraphQL, WebSockets, server-sent events, microservices, event buses, generic plugins, or distributed caches;
- production deployment topology, TLS termination, reverse proxy, CI/CD, or React integration unless the roadmap explicitly assigns a narrow configuration decision to API-03.

## Required API-03 deliverable

Create:

`docs/approved-design-artifacts/Cafe_Fausse_API03_Flask_Architecture_Configuration_and_Test_Strategy.md`

The artifact must include:

1. document metadata, version, status, author, and pending approval record;
2. executive summary;
3. authority and accepted baseline;
4. Phase 0 read-only verification report and evidence paths;
5. scope and API-04 boundary;
6. selected architecture and guiding principles;
7. alternatives considered and rejection rationale;
8. complete proposed `backend/` and `tests/` logical tree;
9. module responsibility catalogue;
10. dependency-direction matrix;
11. application factory and lifecycle design;
12. minimum dependency catalogue and versioning policy;
13. complete runtime-configuration catalogue and environment matrix;
14. exact timeout, retry, backoff, and jitter decisions;
15. PostgreSQL pool, connection, transaction, and cleanup design;
16. OP-01 through OP-07 database-access specifications;
17. OP-05 commit/name-read/ambiguity recovery design;
18. validation and serialization pipeline;
19. error taxonomy and API-02 translation matrix;
20. HTTP/cache/CORS/security/privacy policy;
21. structured logging and redaction policy;
22. liveness and readiness architecture;
23. dependency-injection and deterministic test-seam design;
24. pytest tree, markers, fixtures, lifecycle, and isolation strategy;
25. unit-test catalogue;
26. Flask API-test catalogue;
27. PostgreSQL-integration and failure-injection catalogue;
28. performance-measurement plan;
29. OP-01 through OP-07 operation-to-layer matrix;
30. API-02 endpoint/error/example coverage confirmation;
31. API-04 through API-09 future file-creation and test-ownership matrix;
32. SRS, rubric, Project Requirements Baseline, PRA-001 through PRA-029, API-01, API-02, DB-07, and frozen-contract traceability;
33. privacy and least-privilege assessment;
34. explicit Version 1 exclusions;
35. compatibility assessment proving no PostgreSQL/API-01/API-02 change;
36. unresolved issues and deviations, or an explicit statement that none remain;
37. API-03 completion assessment;
38. API-03 approval checkpoint and the exact next increment it would authorize.

The artifact must make technical choices that belong squarely to API-03 and explain their rationale. It must not defer every implementation-relevant decision to API-04.

## Source-of-truth and compatibility proof

Before declaring API-03 complete, prove that:

- all seven API-01 operations map one-to-one to the seven approved API-02 endpoints;
- no endpoint, method, request field, response field, HTTP status, public error code, retry flag, unknown-outcome flag, or JSON example changed;
- no approved PostgreSQL table, column, constraint, index, role, grant, routine, signature, transaction, isolation, lock, retry, outcome, or migration changed;
- every database access path uses the frozen application-role privilege boundary;
- Flask does not become authoritative for current configuration, hours, capacities, availability, booking, allocation, overlap, exact retry, or persisted newsletter state;
- OP-05 confirmation uses stored customer-name spelling after a known successful booking/exact retry;
- post-commit name-read failure remains distinct from unknown booking outcome;
- no secret, PII, or internal database fact is added to the public contract;
- no derived/transient business data gains a second persistent source of truth;
- no API-04 implementation was created.

If this proof fails, stop and report the exact contradiction. Do not revise an approved upstream artifact in API-03.

## Completion verification

After writing the API-03 artifact:

1. inspect the final Git diff;
2. confirm only the authorized API-03 artifact changed;
3. run `git diff --check` or the repository-equivalent whitespace verification;
4. verify every required section and matrix is present;
5. verify all cited paths and versions against the repository;
6. search for stale route/method/error alternatives and accidental API-02 changes;
7. search for forbidden code, SQL, executable test, dependency-manifest, Flask implementation, React, or deployment content;
8. validate every Mermaid block if any were used;
9. confirm the final working tree preserves all unrelated user files;
10. do not stage, commit, push, or create a pull request.

No executable tests or setup/runtime commands are required for a design-only artifact. Report that fact accurately rather than claiming runtime verification.

## Final Codex response

At completion, report:

- the initial Phase 0 `READY` result;
- the one file created or modified;
- the document version and status;
- the primary architecture, driver/pool, validation, retry, timeout, logging, and pytest decisions;
- verification commands/checks performed and their results;
- confirmation that no database, backend implementation, frontend, dependency, or executable test file changed;
- unresolved issues or deviations, if any;
- the approval checkpoint.

End with this phase boundary in substance:

> **API-03 approval is required before API-04 may begin. Approval authorizes only API-04 Flask Foundation Implementation. It does not authorize later Flask capabilities, React work, integration work, or changes to the approved PostgreSQL, API-01, or API-02 contracts.**

Do not approve API-03 on the user's behalf.

Do not begin API-04.

Do not generate application code, executable tests, SQL, React code, or dependency files.
