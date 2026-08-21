# Prompt 13 - Implement Flask Foundation and PostgreSQL Connectivity

Begin only API-04 of the approved least-to-most implementation roadmap.

API-03 version 1.0.2 is approved and committed. API-04 is the first executable Flask increment. Implement only the Flask foundation, PostgreSQL connectivity, common HTTP infrastructure, and the two approved health operations.

Perform the Phase 0 read-only repository verification in this prompt before making any change. Do not ask for or rely on a separate verification prompt.

## 1. Authoritative sources

Read and follow, in this order:

1. the repository-root `AGENTS.md` and any applicable nested `AGENTS.md` files;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. the approved Project Requirements Addendum version 2.2.1, including PRA-001 through PRA-029;
5. the approved DB-01 Persistent-Data Requirements Analysis version 1.2.1;
6. the approved DB-02 Conceptual Data Model version 1.2;
7. the approved DB-03 Logical PostgreSQL Schema and Integrity Design version 1.1;
8. the approved DB-04 Reservation Transaction and Concurrency Design version 1.1;
9. the approved DB-05 and DB-06 implementation artifacts, migrations, tests, and completion reports;
10. the approved DB-07 verification report, manual-demonstration guide, and Hard Gate 1 evidence;
11. the approved PostgreSQL Contract for Flask version 1.0;
12. the approved API-01 Backend Operation Inventory version 1.0.1;
13. the approved API-02 Flask REST Contract version 1.0.1;
14. the approved API-03 Flask Architecture, Configuration, and Test Strategy version 1.0.2;
15. the approved least-to-most implementation roadmap version 1.1.1;
16. the current database implementation under `database/`;
17. this Prompt 13.

Use the actual repository filenames and approval records found during Phase 0. The authoritative source PDF names are exactly `docs/SRS(1).pdf` and `docs/Rubric(1).pdf`. Do not substitute `docs/SRS.pdf` or `docs/Rubric.pdf`.

DB-01 through DB-07 and API-01 through API-03 are approved. Do not repeat or reopen their decisions unless a genuine contradiction or implementation-blocking ambiguity is discovered.

## 2. Authorization and scope boundary

API-03 approval authorizes exactly API-04 - Flask Foundation and PostgreSQL Connectivity.

API-04 may implement:

- the Python project and dependency manifest under `backend/`;
- the Flask application factory and lifecycle;
- immutable environment configuration parsing and validation;
- the bounded Psycopg connection pool;
- safe PostgreSQL session configuration and application-role enforcement;
- common response construction and error handling;
- the single `/api/v1` blueprint structure;
- shared protocol parsing infrastructure needed by the foundation;
- shared internal result and retry scaffolding without implementing a business operation;
- safe logging, redaction, correlation, and timing infrastructure;
- OP-06 liveness;
- OP-07 readiness;
- dependency injection and deterministic foundational test seams;
- foundational unit, Flask API, and PostgreSQL integration tests;
- backend setup, run, configuration, and test documentation;
- an API-04 implementation/completion report.

API-04 must not implement:

- OP-01 reservation context;
- OP-02 reservation availability;
- OP-03 newsletter-status query;
- OP-04 newsletter-preference mutation;
- OP-05 reservation creation or exact-retry reconstruction;
- any placeholder route for OP-01 through OP-05;
- customer, newsletter, availability, or reservation validation/business behavior assigned to API-05 through API-08;
- API-09 verification or Hard Gate 2;
- React, JSX, JavaScript, TypeScript, npm, Vite, or other frontend work;
- CORS or `Flask-CORS`;
- an ORM, SQLAlchemy, Flask-SQLAlchemy, or migration framework;
- new SQL migrations, tables, columns, constraints, indexes, roles, grants, routines, triggers, or database business logic;
- changes to approved PostgreSQL migration bytes or order;
- database schema creation, migration, reset, seed, or repair at Flask startup;
- authentication, sessions, cookies, CSRF, profiles, or ownership verification;
- deployment topology, production WSGI-server selection, reverse-proxy configuration, TLS termination, CI/CD, or monitoring-vendor integration;
- commits, pushes, pull requests, or production-database operations.

Do not silently modify an approved API, schema, privilege, transaction, concurrency, or platform decision. If API-04 cannot be implemented without such a change, stop and request approval.

## 3. Phase 0 - mandatory read-only repository verification

Perform this phase before editing files, creating a virtual environment, installing dependencies, or running any command that could change the database.

### 3.1 Repository and instruction verification

Using read-only commands:

1. Confirm the repository root and read the complete applicable `AGENTS.md` instructions.
2. Show the current branch, upstream relationship, concise Git status, staged changes, unstaged changes, and untracked files.
3. Confirm whether the worktree is clean. Do not overwrite or incorporate unrelated user changes.
4. Inspect the repository tree, especially `docs/`, `docs/approved-design-artifacts/`, `docs/prompts/`, `database/`, `backend/`, and `frontend/`.
5. Confirm the exact source paths `docs/SRS(1).pdf` and `docs/Rubric(1).pdf`.
6. Locate every authority listed in section 1 and verify its internal title, version, status, and approval record rather than relying only on its filename.
7. Confirm that API-03 version 1.0.2 is explicitly approved and that its approval authorizes API-04 only.
8. Confirm that DB-07 Hard Gate 1 is approved and that the PostgreSQL Contract for Flask version 1.0 is present.
9. Confirm that the implemented database objects, migration order, roles, grants, routines, verification evidence, and known accepted performance limitations match the approved DB-07 and Flask contract artifacts.
10. Inspect existing `backend/` content and Git history so API-04 does not overwrite pre-existing work.

Do not modify the worktree during this inspection. If the worktree is not clean, distinguish the intentionally committed Prompt 13 from unrelated changes. Stop rather than overwriting or absorbing any unrelated modification.

### 3.2 Platform verification

Use non-mutating commands to record:

- Windows Server 2025 edition/build;
- the interpreter resolved by `py -3.14`;
- `platform.python_implementation()`;
- exact Python version;
- whether the standard GIL is enabled, using the supported runtime inspection capability;
- architecture and interpreter path;
- PostgreSQL client version and the available local PostgreSQL server version where safely queryable;
- the installed Node.js version only as a recorded future-React fact.

The authoritative implementation and initial verification platform is:

- Windows Server 2025;
- standard GIL-enabled CPython 3.14.x;
- installed and initially verified CPython patch 3.14.6;
- PostgreSQL 18.3 as the sole Version 1 PostgreSQL target;
- Node.js 24.15.0 reserved for later React work only.

Windows Server 2025 and exact CPython 3.14.6 are formal initial evidence facts, not Flask environment settings or customer-facing startup gates. Application metadata must remain `requires-python = ">=3.14,<3.15"`. Do not add an OS check or an exact-patch rejection to normal `create_app()` startup.

Do not install, uninstall, upgrade, downgrade, or reconfigure software during Phase 0.

### 3.3 PostgreSQL target and safety verification

Without printing secrets:

1. Identify the intended isolated, nonproduction PostgreSQL 18.3 test target and relevant connection-variable presence.
2. Confirm that its database name satisfies the repository's approved `cafe_fausse_test_*` naming and reset guards.
3. Confirm that no production database is selected.
4. Confirm that the approved database rebuild and verification tooling exists.
5. Confirm that a deployment-style login capable of assuming `cafe_fausse_app`, and separate approved test-management authority, can be provided without embedding credentials in source or logs.
6. Use only read-only connectivity checks during Phase 0.

Do not run rebuild, reset, seed, migration, DDL, DML, dependency installation, or Flask implementation commands during Phase 0.

### 3.4 Phase 0 decision

Produce a concise Phase 0 report with one result:

- `READY`: all authoritative inputs, approvals, scope, platform, worktree, and safe nonproduction prerequisites are consistent; or
- `NOT READY`: list each exact blocker and stop before any mutation.

Warnings that do not block API-04 must be distinguished from blockers. Do not convert a genuine contradiction into an assumption. If the result is `READY`, continue directly with API-04 in the same chat.

## 4. Approved runtime and dependency policy

Implement the least dependency set approved by API-03:

- Flask `>=3.1,<3.2`;
- Psycopg `>=3.2.10,<3.3` with matching synchronized binary support appropriate for 64-bit CPython 3.14 on Windows;
- `psycopg_pool >=3.2.8,<3.3`;
- pytest `>=9,<10` as a test dependency;
- pytest-cov `>=7,<8` as a test dependency.

Use direct, fixed, parameterized Psycopg access. Do not add an ORM, generic repository base class, migration library, runtime schema-validation library, retry library, timezone package, fake-data library, task queue, or pytest-Flask. Use the Flask test client and standard library facilities where API-03 assigns them.

Create `backend/pyproject.toml` with:

- `requires-python = ">=3.14,<3.15"`;
- a proportional standards-compliant `src/` package layout;
- the approved direct dependency bounds;
- a separate test dependency group or extra;
- pytest marker declarations and test configuration;
- pytest-cov configuration without inventing an unapproved coverage threshold.

Resolve and record the exact installed dependency versions. Verify the resolved imports under CPython 3.14.6. Do not add Node.js dependencies or use Node.js during API-04.

Use a repository-local virtual environment under `backend/.venv` if one is needed and ensure it and all generated test/build artifacts are ignored. Do not modify the global Python installation.

## 5. Required API-04 project structure

Implement only the API-04-owned portion of the API-03 project tree. At minimum, provide responsibilities equivalent to:

```text
backend/
  pyproject.toml
  README.md
  API04_IMPLEMENTATION_REPORT.md
  src/
    cafe_fausse/
      __init__.py
      application.py
      config.py
      dependencies.py
      http/
        __init__.py
        blueprint.py
        parsing.py
        responses.py
        error_handlers.py
        routes/
          __init__.py
          health.py
      services/
        __init__.py
        results.py
        retry.py
        health.py
      db/
        __init__.py
        pool.py
        exceptions.py
        health_gateway.py
      observability/
        __init__.py
        logging.py
        redaction.py
        timing.py
  tests/
    conftest.py
    unit/
    api/
    integration/
```

File grouping may differ only where the API-03 artifact explicitly permits a responsibility-preserving path adjustment. Record any such mapping in the implementation report. Do not create unused business-operation modules merely to mirror the eventual tree.

Every `__init__.py` must be side-effect free. Importing the package must not open a database connection, register routes globally, read test selectors, or mutate process state.

## 6. Application factory and dependency direction

Implement the approved public factory contract:

`create_app(settings: Settings | None = None, dependencies: Dependencies | None = None) -> Flask`

Production construction with neither argument must:

1. read and validate immutable settings once;
2. configure Flask without sessions;
3. install safe logging and request policies;
4. construct one bounded Psycopg pool with `open=False`;
5. start the pool's background connection process without requiring immediate database availability;
6. construct immutable application dependencies;
7. store them under `app.extensions["cafe_fausse"]`;
8. register common error handling and the single `/api/v1` blueprint;
9. register only the two API-04 health routes;
10. return the application.

Tests may inject a complete validated `Settings` object and/or complete `Dependencies`. Do not implement an environment-controlled production switch that selects fake dependencies.

Preserve these dependency rules:

- HTTP modules may depend on services, safe response infrastructure, and dependency access.
- Services must not import Flask or Psycopg.
- Only database adapters may import Psycopg or execute SQL.
- `application.py` is the composition root allowed to import concrete adapters from all layers.
- Routes must not own connections or SQL.
- Expected results are typed values; exceptions represent protocol, dependency, invariant, or unexpected failures.

## 7. Configuration implementation

Implement the exact API-03 runtime-configuration catalogue and environment matrix. Do not rename, remove, add, or reinterpret settings silently.

Required behaviors include:

- parse settings once into an immutable `Settings` value;
- treat variable names as case-sensitive;
- treat whitespace-only required values as missing;
- reject unknown `CAFE_FAUSSE_*` variables;
- ignore unrelated standard process variables;
- apply all exact types, defaults, numeric ranges, and cross-field rules from API-03;
- reject debug mode outside development;
- reject production `DEBUG` logging and require JSON logs in production;
- prevent deliberate simultaneous use of `PGPASSWORD` and `PGPASSFILE`;
- validate production TLS restrictions defined by API-03 without designing TLS termination;
- validate `CAFE_FAUSSE_POOL_MIN_SIZE <= CAFE_FAUSSE_POOL_MAX_SIZE`;
- validate retry base/cap and all other API-03 cross-field constraints;
- enforce the approved nonproduction database guard for test operations;
- never include secrets or connection values in exceptions, logs, representations, Flask configuration dumps, or reports.

Do not create a consolidated DSN. Pass the approved standard libpq variables to Psycopg as the single connection source.

The formal acceptance-platform guard must be test-only. It must record/refuse invalid formal evidence for Windows Server 2025, CPython 3.14.6, CPython implementation, and enabled GIL, but ordinary application startup and ordinary non-acceptance tests must not invoke it.

## 8. PostgreSQL pool and session behavior

Implement one process-scoped bounded `psycopg_pool.ConnectionPool` per Flask application.

Preserve the API-03 rules:

- create the pool unopened and open it without blocking application construction on database readiness;
- use approved minimum/maximum sizes and acquisition/close bounds from immutable settings;
- configure every newly established session with a fixed, non-sensitive `application_name`;
- execute only fixed session-control SQL needed to assume `cafe_fausse_app`;
- verify that the active role is `cafe_fausse_app` before a session is usable;
- bind no user input into session-control identifiers;
- lease and release connections with context managers;
- discard broken or uncertain connections rather than returning them as healthy;
- never keep a connection or transaction open across an HTTP response;
- never close the process pool during ordinary request teardown;
- provide idempotent `close_resources(app)` with the approved bounded wait;
- close already-created resources if factory construction fails;
- make repeated factory/create/close cycles safe;
- never perform migration, reset, seed, repair, or business SQL during startup or shutdown.

Implement the foundational transaction/context scaffolding required by API-03, but do not call an OP-01 through OP-05 database routine and do not implement their business transaction flows.

## 9. Common HTTP behavior

Register one versioned blueprint under `/api/v1`. Register exactly:

- OP-06: `GET /api/v1/health/liveness`;
- OP-07: `GET /api/v1/health/readiness`.

Do not register placeholder, stub, `501`, or incomplete routes for OP-01 through OP-05.

All API-04 responses, including health, 404, 405, request-policy, and unexpected-error responses, must follow API-02 exactly:

- JSON only;
- `Content-Type: application/json; charset=utf-8`;
- `Cache-Control: no-store, max-age=0`;
- `Pragma: no-cache`;
- `Expires: 0`;
- `X-Content-Type-Options: nosniff`;
- `Referrer-Policy: no-referrer`;
- correct `Allow` header on 405;
- no HTML error pages;
- no `Retry-After`, ETag, cookies, redirect, public correlation header, or unapproved field;
- no `Access-Control-Allow-*` headers and no automatic cross-origin OPTIONS contract.

Implement only the API-02 error codes that may be exercised by the common foundation and OP-06/OP-07 now, while structuring the internal exhaustive translation types for later increments as API-03 directs. At minimum, correctly handle applicable `invalid_request`, `route_not_found`, `method_not_allowed`, `service_not_ready`, and `internal_error` outcomes without inventing a new public code.

Do not expose exception messages, SQL, SQLSTATE, server versions, schema/role names, object names, pool state, connection information, or readiness component details.

## 10. OP-06 liveness

Implement liveness as a process-local constant check proving the Flask request path executes.

It must:

- perform no pool checkout;
- perform no SQL or filesystem/network access;
- perform no dependency repair;
- return the exact API-02 `200` liveness representation `{"status":"live"}`;
- return all approved common response headers;
- expose no diagnostics, versions, components, or environment facts;
- remain successful when PostgreSQL is unavailable, unless Flask itself cannot execute the request.

## 11. OP-07 readiness

Implement readiness as one bounded, read-only PostgreSQL check using at most one pool lease and the API-03 default 1,000 ms total deadline.

The readiness gateway must verify only the frozen conditions approved by API-01 through API-03 and the PostgreSQL Contract for Flask, including:

- PostgreSQL server version 18.3;
- `pgcrypto` availability;
- active `current_user` is `cafe_fausse_app` after the approved role assumption;
- the application role has the approved execute privileges on all three frozen production routines without invoking a mutation routine;
- the application role can perform the four approved foundation reads;
- the single reservation-configuration row is present and valid;
- all seven operating-hours rows are present and valid;
- exactly 30 positive-capacity Version 1 restaurant tables are present;
- the frozen database contract is usable within the app-role boundary.

Readiness must not:

- call a mutating routine;
- create a test booking or customer;
- run DB-07 verification, rebuild, migration, reset, seed, or repair tooling;
- inspect customer/reservation data beyond the approved minimum foundation privilege/shape checks;
- elevate to an owner or test role;
- expose which internal check failed.

Return the exact API-02 `200` response `{"status":"ready"}` on success. Map every pool, platform, contract, privilege, or foundation failure to the same generic `503` response:

```json
{"error":{"code":"service_not_ready","message":"The service is not ready.","retryable":true,"outcome_unknown":false}}
```

Record only the approved coarse internal component category in safe logs.

Readiness is evaluated on each request and is not cached as authority. Failure must not terminate the process or alter liveness.

## 12. Retry and failure scaffolding

Implement only the common retry/result/exception scaffolding assigned to API-04.

Preserve API-03's exact principles:

- at most three total attempts;
- only approved transient PostgreSQL classes are eligible;
- each retry begins with a new transaction/appropriate clean lease;
- no retry after an uncertain mutation outcome;
- deadline-aware exponential backoff with the approved base, cap, symmetric jitter, and minimum remaining-time rule;
- injected monotonic clock, sleeper, and randomness for deterministic tests;
- no unbounded loop;
- no third-party retry package;
- no business-operation orchestration in API-04.

Readiness itself performs one probe attempt and does not use workflow retry behavior unless API-03 explicitly requires it.

## 13. Logging, privacy, and observability

Implement API-03's allowlist-based logging and redaction boundary.

Required foundation behavior includes:

- text logs where allowed in development/test and newline-delimited JSON in production;
- one internal UUIDv4 correlation value per request, never accepted from a client and never returned publicly;
- monotonic elapsed, pool-wait, and database timing fields;
- registered route templates rather than raw paths;
- sparse startup, shutdown, readiness-transition, and request-completion events;
- allowlisted event fields only;
- defensive exception-class/category handling without exception messages or `repr()` output;
- sanitized tracebacks without local-variable capture;
- no request/response bodies, headers, query values, raw URLs, names, email addresses, phone numbers, reservation/customer/table identifiers, fingerprints, SQL parameters, result rows, credentials, hosts, database/user names, DSNs, passfiles, or environment dumps;
- no additional metrics/tracing vendor dependency.

Tests must use known sentinel secrets and PII-like values and prove they never appear in logs, errors, responses, or reports.

## 14. Testing requirements

Write executable tests for the implemented API-04 behavior. Use stable traceability identifiers such as `UT-API-*`, `AT-API-*`, and `IT-DBAPI-*` in test names, docstrings, or parameters.

### 14.1 Unit tests

Cover at least:

- every API-03 configuration default, required value, numeric boundary, invalid type, and cross-field restriction;
- rejection of unknown `CAFE_FAUSSE_*` values;
- secret-free configuration errors and representations;
- ordinary runtime behavior versus the formal test-only platform guard;
- positive formal evidence for Windows Server 2025, standard GIL-enabled CPython 3.14.6, and negative guard cases without installing/remediating software;
- pool construction parameters and safe session configuration;
- lifecycle cleanup after partial factory failure;
- idempotent resource closure;
- retry-attempt, delay, cap, jitter, deadline, and eligibility scaffolding;
- common response/error mapping;
- logging allowlist/redaction and internal-correlation privacy;
- injected wall/monotonic clocks and deterministic seams.

### 14.2 Flask API tests

Use Flask's built-in test client with fake dependencies. Cover at least:

- application construction with injected settings/dependencies;
- exact OP-06 success body, status, headers, and proof of zero gateway/pool calls;
- exact OP-07 ready body and headers;
- every internal readiness-failure category mapping to the identical generic `503 service_not_ready` body;
- PostgreSQL unavailable while liveness remains `200` and readiness is `503`;
- wrong methods and exact `Allow` behavior;
- unknown and near-match routes returning the approved JSON 404;
- GET body and query restrictions required by API-02;
- exact content type, cache, and security headers on success and error;
- absence of CORS, cookies, public correlation, diagnostics, and unapproved fields;
- unexpected failures mapping to the generic `500 internal_error` without leakage;
- only the two API-04 routes being registered.

Assert complete JSON equality and complete required headers, not substring matches.

### 14.3 PostgreSQL integration tests

Run against only the isolated PostgreSQL 18.3 `cafe_fausse_test_*` target after all reset guards pass. Reuse the approved database rebuild/migration/verification tooling; do not rewrite it.

Cover at least:

- formal platform evidence under Windows Server 2025 and CPython 3.14.6;
- exact resolved dependency versions and imports;
- clean approved database rebuild and verification before the suite;
- deployment-style login assuming `cafe_fausse_app`;
- active-role verification on every pooled session;
- PostgreSQL 18.3 and `pgcrypto` readiness checks;
- approved foundation-table read privileges;
- approved production-routine execute privileges verified without mutation;
- denial of direct business-table DML, reservation/assignment reads, DDL, reset tooling, internal/test routines, and other forbidden actions where the existing contract requires these denials;
- valid foundation population producing ready `200`;
- controlled missing/invalid foundation facts producing only generic not-ready `503` and being restored by external approved test tooling;
- database unavailable at process construction, background recovery, liveness independence, and later readiness recovery;
- pool lease return, broken-connection discard, transaction rollback scaffolding, and repeated factory/close cycles;
- no committed customer, reservation, assignment, newsletter, configuration, hours, or table-capacity mutation caused by API-04 tests or health checks.

The Flask application role must never perform cleanup. Any controlled test setup/restoration uses only approved nonproduction test-management tooling. Ensure cleanup and resource closure in `finally` paths. If a test fails and clean restoration cannot be proven, stop subsequent database testing and use the approved guarded rebuild before continuing.

### 14.4 Test execution and evidence

Run and report separately:

- unit tests;
- Flask API tests;
- PostgreSQL integration tests;
- coverage reporting for the API-04 implementation;
- whitespace/static repository checks such as `git diff --check`;
- any formatter or static checker only if it is already approved or added without introducing an unapproved project dependency.

Do not claim API-09 completeness, performance compliance, concurrency completeness, or full REST-contract coverage. API-04 tests cover only the implemented foundation and health operations.

## 15. Documentation requirements

Create or update `backend/README.md` with concise Windows instructions for:

- supported runtime and initial verified platform;
- creating/using the repository-local virtual environment;
- installing the backend and test dependencies from `pyproject.toml`;
- configuring development and test environments without committing secrets;
- starting the Flask development application for local verification only;
- running unit/API tests;
- running guarded PostgreSQL integration tests;
- interpreting liveness and readiness;
- closing resources and troubleshooting safe connection/readiness failures;
- the no-ORM, same-origin/no-CORS, no-startup-migration, and PostgreSQL-authority boundaries.

Do not include real passwords, DSNs, tokens, host-specific secrets, or production deployment instructions.

Create `backend/API04_IMPLEMENTATION_REPORT.md` containing:

- increment identity and status;
- Phase 0 verification result;
- authoritative sources and versions;
- exact files created/modified;
- responsibility-preserving deviations from the planned tree, if any;
- exact resolved Python and dependency versions;
- implementation summary mapped to API-03 sections;
- configuration catalogue confirmation;
- route and HTTP-contract confirmation;
- pool/session/role/readiness behavior;
- privacy and logging evidence;
- test catalogue and commands;
- test counts and results;
- coverage result without inventing a threshold;
- PostgreSQL target-safety evidence without secrets;
- direct privilege and nonmutation evidence;
- known warnings or limitations;
- explicit exclusions;
- Git diff summary;
- API-03 compatibility assessment;
- API-04 completion assessment;
- approval checkpoint.

Do not mark API-04 approved. Completion and passing tests mean ready for human review only.

## 16. Required implementation postconditions

Before declaring API-04 ready for review, prove all of the following:

- the package imports and `create_app()` constructs correctly under the approved runtime;
- normal startup does not enforce Windows edition or exact Python patch as an application gate;
- no temporary PostgreSQL outage prevents process construction;
- liveness performs no database work;
- readiness is bounded, read-only, generic on failure, and uses the application-role boundary;
- no startup, health, shutdown, or test path changes business data except externally authorized test setup/restoration;
- every pool session assumes and verifies `cafe_fausse_app`;
- the pool is bounded and process-scoped;
- request teardown does not close the process pool;
- resource closure is idempotent and leak-free in tested cycles;
- every current response uses the approved JSON/header/error policy;
- no CORS headers, ORM, sessions, cookies, or unapproved dependency exists;
- no PII, secret, SQL detail, diagnostic, or public correlation value leaks;
- only OP-06 and OP-07 are implemented and registered;
- no API-01 through API-03 or PostgreSQL contract decision changed;
- all API-04 tests pass against the approved local environment;
- `git diff --check` passes;
- the final Git diff contains only API-04-authorized files.

## 17. Failure and stop conditions

Stop and ask for approval rather than improvising if any of these occurs:

- an authoritative artifact is missing, unapproved, internally inconsistent, or has an unexpected version;
- API-03 v1.0.2 approval cannot be confirmed;
- the worktree contains unrelated changes that overlap API-04;
- the platform is not the stated initial evidence platform and the discrepancy affects formal acceptance;
- the intended PostgreSQL target could be production or fails the approved nonproduction guards;
- a required database role, grant, routine, signature, migration, or object differs from the frozen contract;
- API-04 would require changing approved database or API behavior;
- dependency resolution cannot produce the approved compatible families under CPython 3.14.6;
- tests reveal a defect that cannot be corrected entirely within API-04's approved implementation responsibilities;
- safe cleanup or database state cannot be proven after a failed test.

An incidental implementation defect inside newly written API-04 code is not an approval question: correct it, rerun the affected tests, and document the result. Do not weaken a test, suppress an error, or broaden scope to manufacture a pass.

## 18. Completion report in the Codex chat

At completion, report:

1. Phase 0 result;
2. API-04 completion status;
3. files created and modified;
4. exact environment and resolved dependency versions;
5. commands executed;
6. unit, API, integration, coverage, and repository-check results;
7. confirmation that PostgreSQL business state and approved migration files were not changed;
8. confirmation that OP-01 through OP-05, API-05, React, and deployment were not started;
9. deviations, warnings, or unresolved issues;
10. exact manual setup/run/test commands Abdul should use;
11. the API-04 approval checkpoint.

Do not commit, push, or open a pull request.

## 19. API-04 approval checkpoint

End at this checkpoint:

> API-04 - Flask Foundation and PostgreSQL Connectivity is complete and ready for Abdul's review. Completion does not equal approval. API-04 approval is required before API-05 may begin.

Approval of API-04 would authorize only API-05 - Customer Identity and Newsletter-Status Query. It would not authorize API-06 newsletter-preference mutation, API-07 reservation-slot discovery, API-08 reservation creation, API-09 Hard Gate 2, React, integration-phase work, deployment, or PostgreSQL changes.

Do not begin API-05.
