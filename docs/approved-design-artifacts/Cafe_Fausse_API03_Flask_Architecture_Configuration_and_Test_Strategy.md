# Cafe Fausse API-03 Flask Architecture, Configuration, and Test Strategy

**Document version:** 1.0.3

**Date:** 2026-08-21

**Roadmap increment:** API-03 - Flask Architecture, Configuration, and Test Strategy

**Status:** Approved

**Author:** Codex, prepared for Abdul

**Approval record:** Approved by Abdul on 2026-08-21. Approval of this document authorizes only API-04 - Flask Foundation and PostgreSQL Connectivity. It does not authorize API-05 or later Flask capabilities, React work, integration work, deployment work, or PostgreSQL changes.

**Reconciliation record:** Version 1.0.3 applies the approved `API-07 OP-02 timezone/snapshot reconciliation` from 2026-08-23. It changes no API-02 public contract or frozen PostgreSQL contract.

## 1. Executive summary

Cafe Fausse Version 1 will be one modular Flask application on Windows Server 2025 using standard GIL-enabled CPython 3.14.x, with installed CPython 3.14.6 as the initial implementation and verification patch, backed directly by the frozen PostgreSQL 18.3 contract. The application uses an application factory, a single bounded Psycopg 3 connection pool, one versioned Flask blueprint, operation-specific services and gateways, pure validation/serialization functions, and a small dependency container held in `app.extensions`. It does not use an ORM, schema creation, Flask-side business-rule reimplementation, or a generic repository abstraction.

The HTTP boundary remains exactly API-02 version 1.0.1. Each of its seven endpoints maps one-to-one to one API-01 operation. PostgreSQL remains authoritative for current configuration, operating hours, inventory, availability, booking, allocation, overlap prevention, exact retry, and persisted newsletter state. Flask owns protocol parsing, caller-visible validation, orchestration, bounded technical retry, safe outcome translation, confirmation shaping, response policy, and observability.

This document chooses the Python/dependency families, logical source tree, lifecycle, complete configuration surface, numeric timeout/retry policy, transaction ownership, health design, error policy, logging/redaction boundary, deterministic test seams, and test strategy needed by API-04 through API-09. Node.js 24.15.0 is an installed platform fact reserved for future React implementation and verification; it is not a Flask runtime dependency, is not used by API-03 or API-04, and creates no Node.js package or frontend compatibility decision here. This document creates no Flask implementation and does not begin API-04.

## 2. Authority and accepted baseline

The following repository sources are authoritative for this design:

| Authority | Accepted version or state | Binding effect on API-03 |
|---|---:|---|
| `AGENTS.md` | Current repository instructions | Increment boundary, source locations, testing, and completion reporting |
| `docs/SRS(1).pdf` | Supplied SRS | Flask/PostgreSQL architecture, functional behavior, quality attributes, and two-second form-processing expectation |
| `docs/Rubric(1).pdf` | Supplied rubric | Correct Flask/PostgreSQL integration, five-page application, direct persistence evidence, sophisticated reservation logic, and documentation quality |
| `Cafe_Fausse_Project_Requirements_Baseline.md` | 1.0 | Fixed project and Version 1 scope baseline |
| `Cafe_Fausse_Project_Requirements_Addendum.md` | 2.2.1 | PRA-001 through PRA-029 |
| DB-01 through DB-04 approved artifacts | Approved versions in their headers | Persistent model, schema, transaction, concurrency, validation, and allocation decisions |
| `database/` migrations and evidence | Implemented DB-05 through DB-07 | Exact implemented schema, privileges, operations, verification, performance envelope, and manual demonstration |
| `database/POSTGRESQL_CONTRACT_FOR_FLASK.md` | 1.0, frozen | Exclusive Flask-to-PostgreSQL contract |
| `Cafe_Fausse_API01_Backend_Operation_Inventory.md` | 1.0.2, approved reconciliation | Seven operations and database-access responsibilities |
| `Cafe_Fausse_API02_Flask_REST_Contract.md` | 1.0.1, approved | Exact routes, methods, media types, fields, statuses, errors, flags, and 36 examples |
| `Cafe_Fausse_Least_to_Most_Implementation_Roadmap.md` | 1.1.1 | API-03 objective and API-04 through API-09 boundaries |
| User-authorized implementation-platform correction | 2026-08-21 | Windows Server 2025; standard GIL-enabled CPython 3.14.x with installed 3.14.6 as the initial implementation/tested patch; PostgreSQL 18.3; Node.js 24.15.0 for the later React phase only |

Accepted platform facts are Windows Server 2025, standard GIL-enabled CPython 3.14.x with installed CPython 3.14.6 as the initial implementation and verification patch, PostgreSQL 18.3, and Node.js 24.15.0 reserved for future React work. PostgreSQL 18.3 remains the sole approved and verified Version 1 PostgreSQL target. Accepted database facts include `pgcrypto`; six approved business tables; thirty Version 1 tables; the `cafe_fausse_owner`, `cafe_fausse_app`, and `cafe_fausse_test` NOLOGIN roles; the application-role least-privilege grants; recurring database-owned hours; the three callable production routines; `READ COMMITTED` booking; a restaurant-wide advisory lock; three total attempts for only the approved retry classes; and the database performance limitations accepted at DB-07.

API-03 does not reinterpret the SRS two-second expectation as a guarantee. DB-07 recorded ordinary general-allocation p95 near 1.14-1.27 seconds and contended five/eight-request cases over two seconds. The approved lock and exact allocation remain unchanged; API-09 and later full-stack gates will measure end-to-end behavior.

## 3. Phase 0 read-only verification report

### 3.1 Result

**READY.** The mandatory gate completed before this file was created.

| Check | Evidence | Result |
|---|---|---|
| Repository instructions | Root `AGENTS.md`; no nested `AGENTS.md` applies | PASS |
| Initial worktree | `git status --porcelain=v2 --branch` at `dae08d21d0b35d9fb646fce610ea69e3d5bd17d7`, `main...origin/main`, `+0 -0`, no path entries | PASS - clean |
| Prompt authorization | `docs/prompts/Cafe_Fausse_Prompt_12_API03_Flask_Architecture_Configuration_and_Test_Strategy.md` | PASS |
| SRS and rubric readable | `docs/SRS(1).pdf`; `docs/Rubric(1).pdf` | PASS |
| Approved design sources | All files named in section 2 under `docs/approved-design-artifacts/` | PASS |
| Implemented database source | `database/provisioning/`, `database/migrations/001` through `011`, `database/reset/`, `database/verification/`, `database/tests/`, and `database/scripts/` | PASS |
| DB completion evidence | `DB05_IMPLEMENTATION_REPORT.md`, `DB06_IMPLEMENTATION_REPORT.md`, `DB07_VERIFICATION_REPORT.md`, and `DB07_MANUAL_DEMONSTRATION.md` | PASS |
| Frozen DB contract | `database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, version 1.0, explicitly approved and frozen | PASS |
| DB-07 approval | Hard Gate 1 approved by Abdul on 2026-08-20 | PASS |
| API-01 approval | Version 1.0.1 explicitly approved; authorizes API-02 only | PASS |
| API-02 approval | Version 1.0.1 explicitly approved by Abdul on 2026-08-21; authorizes API-03 only | PASS |
| API-02 examples | All fenced `json` blocks parsed independently: 36 present, 36 valid, 0 invalid | PASS |
| Existing backend implementation | `backend/` contains no Flask source, tests, or dependency manifest | PASS - no overlap |
| Authorized artifact | This path did not exist at gate time | PASS |

No missing source, approval mismatch, upstream contradiction, existing implementation overlap, dirty worktree, or unsafe repository state was found.

### 3.2 Version 1.0.2 correction verification

The correction pass began on a clean `main...origin/main` worktree at `cf9d3d8d3fa0aa2fd341285d0c998ef3d7b0a72c`. Read-only platform checks produced:

| Platform check | Evidence observed in the correction environment | Assessment |
|---|---|---|
| Operating system | Windows Server 2025 Standard, 24H2, build `26100.33158`, Server installation | MATCH |
| Python implementation | `platform.python_implementation()` returned `CPython` | Family MATCH |
| Python GIL mode | `sys._is_gil_enabled()` returned `True`; `Py_GIL_DISABLED` was `0` | Standard GIL-enabled build MATCH |
| Exact Python patch | The verified interpreter was `C:\Python314\python.exe`, CPython `3.14.6` | MATCH - installed and authoritative initial implementation/verification patch |
| PostgreSQL client | `C:\Program Files\PostgreSQL\18\bin\psql.exe --version` and file metadata both reported PostgreSQL 18.3; `psql` itself was not on PATH | MATCH; PATH discovery is nonblocking and authorizes no installation/change |
| Node.js | `node --version` reported `v24.15.0` | MATCH; future React phase only |

The correction environment exactly matches the authoritative Python platform: CPython 3.14.6, the standard GIL-enabled build. No Python installation, downgrade, upgrade, or environment correction is required. After API-03 approval, API-04 may proceed on this installed environment and record it as target-conforming evidence. No software was installed, removed, upgraded, downgraded, or reconfigured during verification.

## 4. Scope and API-04 boundary

API-03 is design only. It selects the implementation architecture and test strategy but creates only this Markdown artifact.

In scope:

- one Flask application's logical modules and dependency direction;
- Python and dependency family policy;
- runtime configuration and numeric bounds;
- pool, connection, transaction, retry, and cleanup behavior;
- request validation, serialization, error translation, health, response, privacy, logging, and test architecture;
- future ownership across API-04 through API-09.

Out of scope now:

- Python or Flask source, tests, fixtures, dependency manifests, lock files, environment files, SQL, migrations, executable commands, or deployment configuration;
- implementation of any endpoint;
- changes to an approved artifact or database object;
- API-04 or later work.

API-04 may implement only the common foundation described here: application creation, configuration, connectivity, transaction/retry scaffolding, response/error/logging utilities, and OP-06/OP-07. It must not implement OP-01 through OP-05.

## 5. Selected architecture and guiding principles

### 5.1 Logical flow

```text
WSGI process
  -> create_app()
     -> validated immutable Settings
     -> bounded PostgreSQL Pool
     -> app-local Dependencies
     -> /api/v1 Blueprint
        -> protocol parser + field validators
        -> operation-specific Service
        -> operation-specific Gateway
        -> frozen PostgreSQL reads/routines
        <- typed internal result
        <- serializer / public error translator
        <- uniform response policies
```

### 5.2 Principles

1. One Flask application and one PostgreSQL database; no service split.
2. Dependency direction always points inward: HTTP depends on services; services depend on narrow gateway protocols; adapters depend on Psycopg. Domain/service code never imports Flask.
3. PostgreSQL owns database business truth. Flask does not duplicate availability, allocation, overlap, fingerprint, newsletter-state, or current configuration logic.
4. Expected database/business outcomes are values, not exceptions. Exceptions represent protocol failures, invalid local configuration, dependency failures, or broken invariants.
5. Every mutation has an explicit transaction boundary and a known/unknown outcome classification.
6. Only fixed SQL and approved signatures are issued. User values are always bound parameters.
7. Public messages contain no database details; logs contain no PII, bodies, query values, secrets, or fingerprints.
8. Clock, monotonic time, sleeping, jitter randomness, and internal correlation IDs are injected, making tests deterministic.
9. Resources are process-scoped, bounded, explicitly closed, and never closed during ordinary request teardown.
10. The structure stays proportional: no ORM, repository base class, command bus, event bus, plugin system, or framework inside the framework.

## 6. Alternatives considered

| Decision | Selected | Rejected alternative | Rationale |
|---|---|---|---|
| Application shape | One modular Flask app | Microservices/serverless functions | Seven tightly related operations share one database and transaction vocabulary; a split adds failure modes without an approved need. |
| SQL access | Psycopg 3, explicit fixed SQL | SQLAlchemy ORM | The schema/routines already exist and are frozen; ORM mapping and migration machinery add a competing abstraction and risk accidental DML. |
| Data-access modules | Operation-specific gateways | Generic repository/DAO base class | Each operation has different privileges, result shapes, transaction semantics, and ambiguity rules. |
| Blueprint layout | One `/api/v1` blueprint with focused route modules | Blueprint per endpoint or one monolithic routes file | One version boundary is cohesive; route modules prevent a monolith without multiplying registration objects. |
| Validation | Small pure validators using the standard library | Marshmallow/Pydantic/JSON Schema runtime validation | API-02 has seven bounded schemas. Manual pure functions minimize dependencies and preserve exact error ordering/codes. |
| Expected outcomes | Frozen dataclass/enum-like result values | Exceptions for every business result | Values make mappings exhaustive and prevent expected conflicts from producing tracebacks. |
| Technical failures | Narrow typed exceptions | Untyped catch-all branching | Typed categories preserve retry and ambiguity semantics while one outer handler safely contains defects. |
| Pool | One Psycopg bounded pool | Connect per request; global raw connection | A pool bounds cost/contention and health-checks leases; one shared connection is unsafe across requests. |
| Retry | In-process bounded retry with injected policy | Celery/background queue; unlimited retry | Only three approved SQLSTATEs may retry and HTTP outcomes must remain synchronous. |
| Test client | Flask built-in test client | `pytest-flask` | Flask already provides the needed request client and context lifecycle. |
| CORS | Same-origin, no CORS headers | Permissive wildcard or Flask-CORS | Version 1 is unauthenticated and exposes mutation endpoints; React integration can use a same-origin proxy. |
| Correlation | Internal opaque UUID per request, logs only | Public request/correlation header | API-02 explicitly exposes no correlation field/value in Version 1. |

## 7. Proposed logical project tree

All entries below are future planned paths. API-03 creates none of them.

```text
backend/
  pyproject.toml
  README.md
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
          newsletter_status.py
          newsletter_preferences.py
          reservation_context.py
          reservation_availability.py
          reservations.py
      services/
        __init__.py
        results.py
        retry.py
        health.py
        newsletter_status.py
        newsletter_preferences.py
        reservation_context.py
        reservation_availability.py
        reservations.py
      validation/
        __init__.py
        common.py
        identity.py
        newsletter.py
        reservation.py
      serialization/
        __init__.py
        common.py
        reservation.py
      db/
        __init__.py
        pool.py
        exceptions.py
        health_gateway.py
        customer_gateway.py
        newsletter_gateway.py
        context_gateway.py
        availability_gateway.py
        reservation_gateway.py
      observability/
        __init__.py
        logging.py
        redaction.py
        timing.py
  tests/
    conftest.py
    unit/
      test_config.py
      test_parsing.py
      test_validation_common.py
      test_validation_identity.py
      test_validation_newsletter.py
      test_validation_reservation.py
      test_retry.py
      test_services.py
      test_serialization.py
      test_error_translation.py
      test_redaction.py
    api/
      conftest.py
      test_protocol_errors.py
      test_response_policies.py
      test_health.py
      test_reservation_context.py
      test_reservation_availability.py
      test_newsletter_status.py
      test_newsletter_preferences.py
      test_reservations.py
    integration/
      conftest.py
      test_connectivity_and_privileges.py
      test_health_postgresql.py
      test_reservation_context_postgresql.py
      test_availability_postgresql.py
      test_newsletter_status_postgresql.py
      test_newsletter_preferences_postgresql.py
      test_reservations_postgresql.py
      test_transactions_and_retries.py
      test_failure_injection.py
      test_concurrency.py
    performance/
      conftest.py
      test_api_timings.py
      test_booking_contention.py
```

## 8. Module responsibility catalogue

| Module | Single responsibility |
|---|---|
| `application.py` | Create/configure the Flask app, construct production dependencies, register handlers/blueprint, start the pool, and expose explicit resource close. |
| `config.py` | Parse application environment values into immutable `Settings`; validate required values, types, ranges, cross-field rules, and environment restrictions. Operating-system, Python patch, implementation, and GIL evidence are not application environment configuration. |
| `dependencies.py` | Define the immutable app-local container and narrow callable/protocol types for injected gateways, clocks, timers, sleepers, randomness, and IDs. |
| `http/blueprint.py` | Create and register the single `/api/v1` blueprint and the exact endpoint rules. |
| `http/parsing.py` | Enforce body/media/UTF-8/JSON/object/duplicate-key/GET-body rules and return untrusted Python values only. |
| `http/responses.py` | Build exact JSON responses and apply media, cache, and security headers. |
| `http/error_handlers.py` | Convert protocol exceptions, `HTTPException`, service failures, and unexpected exceptions to API-02 envelopes. |
| `http/routes/*` | Thin endpoint adapters: parse, validate, call one service, serialize one result. No SQL or business persistence. |
| `services/results.py` | Frozen internal result types and exhaustive outcome categories; no Flask or Psycopg imports. |
| `services/retry.py` | Deadline-aware, maximum-three-attempt technical retry orchestration with injected timer/sleeper/jitter. |
| `services/health.py` | OP-06/OP-07 orchestration and coarse public health mapping. |
| `services/newsletter_status.py` | OP-03 identity lookup decision flow. |
| `services/newsletter_preferences.py` | OP-04 routine orchestration and known/unknown mutation mapping. |
| `services/reservation_context.py` | OP-01 coherent current foundation snapshot orchestration. |
| `services/reservation_availability.py` | OP-02 provisional availability orchestration. |
| `services/reservations.py` | OP-05 booking/reconstruction, commit certainty, stored-name read, and confirmation assembly. |
| `validation/common.py` | Exact primitive/type/length/whitespace/date/time/offset helpers and ordered field-error construction. |
| `validation/identity.py` | API-02 name, middle-initial, email, and optional-phone normalization/validation. |
| `validation/newsletter.py` | Newsletter action/preference request validation. |
| `validation/reservation.py` | Availability and booking field/cross-field validation; it does not decide authoritative availability. |
| `serialization/common.py` | Canonical UTC/local text, decimal-string BIGINT references, and common envelope-safe primitives. |
| `serialization/reservation.py` | Exact API-02 slot and confirmation projections. |
| `db/pool.py` | Construct/configure/check/close the bounded Psycopg pool and enforce the application-role session. |
| `db/exceptions.py` | Translate Psycopg/libpq failures to safe internal technical categories and commit certainty. |
| `db/*_gateway.py` | Fixed, parameterized SQL for one operation family; consume exact rows and reject impossible shapes/outcomes. |
| `observability/logging.py` | Configure structured records and request/operation completion events. |
| `observability/redaction.py` | Central allowlist of permitted fields and defensive scrubbing of exception metadata. |
| `observability/timing.py` | Monotonic elapsed/pool-wait/database timing collection. |

Route modules are deliberately separate from operation services. Tests may replace gateways and nondeterministic callables, but production routes never select implementations at runtime.

### 8.1 Remaining tree-entry responsibilities

| Planned entry | Responsibility |
|---|---|
| `backend/` | Sole Flask project root; contains no database migrations or React code. |
| `pyproject.toml` | API-04 build metadata with `requires-python = ">=3.14,<3.15"`, direct dependency bounds, pytest configuration, markers, and coverage settings. |
| `README.md` | API-04 local setup/run/test/configuration instructions and safety boundary; no credentials. |
| `src/` | Importable-source root, preventing accidental imports from the repository working directory. |
| Every `__init__.py` | Declares a package and exports only its intentionally public construction/types; performs no connection or registration side effect at import time. |
| `http/` | Flask-only protocol adapters and common HTTP policy. |
| `http/routes/health.py` | Both health routes only; their service decisions remain separate. |
| `http/routes/newsletter_status.py` | OP-03 route only. |
| `http/routes/newsletter_preferences.py` | OP-04 route only. |
| `http/routes/reservation_context.py` | OP-01 route only. |
| `http/routes/reservation_availability.py` | OP-02 route only. |
| `http/routes/reservations.py` | OP-05 route only. |
| `services/` | Framework-independent orchestration and typed result decisions. |
| `validation/` | Pure public-input rules; no database or Flask request access. |
| `serialization/` | Pure internal-result to API-02 JSON projections. |
| `db/` | The only package that imports Psycopg or executes SQL. |
| `observability/` | Safe structured logs and monotonic measurements; no vendor backend. |
| `tests/conftest.py` | Global marker registration plus safe settings, deterministic seam, and app lifecycle fixtures. |
| `tests/unit/` and each listed file | One pure concern per file corresponding to section 23; no Flask app or PostgreSQL. |
| `tests/api/conftest.py` | Fake operation dependencies and exact-response assertion helpers. |
| Each `tests/api/test_*.py` | Exact API-02 behavior for the common boundary or one operation, as catalogued in section 24. |
| `tests/integration/conftest.py` | Guarded PostgreSQL rebuild, app-role and management connections, scenario cleanup, failure control, and lifecycle. |
| Each `tests/integration/test_*.py` | One real database-access, operation, transaction, failure, or concurrency concern from section 25. |
| `tests/performance/conftest.py` | Nonproduction environment evidence, warm-up/sampling helpers, and percentile calculation. |
| `tests/performance/test_api_timings.py` | Sequential OP-01 through OP-07 timing evidence. |
| `tests/performance/test_booking_contention.py` | Coordinated 2/5/8-client booking evidence and integrity assertions. |

Every file shown in the logical tree is covered by the two catalogues. Test data/build artifacts such as `.pytest_cache`, `.coverage`, HTML coverage, virtual environments, logs, and timing exports are generated files and therefore are not planned source-tree entries.

## 9. Dependency-direction matrix

`A -> B` means A may import B. A dash means imports are forbidden.

| From / To | Flask HTTP | Validation/serialization | Services/results | DB adapters | Observability | Config/dependencies |
|---|---:|---:|---:|---:|---:|---:|
| Flask HTTP | local | yes | yes | no | yes | yes |
| Validation/serialization | no | local | result/value types only | no | no | no |
| Services/results | no | no | local | gateway protocols only | timing interface only | callable protocols only |
| DB adapters | no | no | result/value types | local | timing interface only | settings only |
| Observability | no Flask request globals | no | no | no | local | settings only |
| Config/dependencies | no | no | protocol typing only | construction imports in composition root only | construction imports in composition root only | local |

Only `application.py` is a composition root allowed to import concrete adapters from every layer. Database adapters may import Psycopg; no other layer may. Services receive protocols/objects, never fetch Flask globals.

## 10. Application factory and lifecycle

### 10.1 Factory

The public construction function is `create_app(settings: Settings | None = None, dependencies: Dependencies | None = None) -> Flask`.

Production calls it with neither argument. It loads and validates environment configuration, configures Flask without sessions, installs safe logging, constructs an unopened `ConnectionPool`, starts its background workers without waiting for database readiness, constructs immutable dependencies, stores them at `app.extensions["cafe_fausse"]`, registers handlers and the single blueprint, and returns the app.

Tests may supply a validated `Settings` and/or a complete `Dependencies` object. Partial implicit mutation of `app.config` after creation is unsupported. The production WSGI entry point never imports test helpers or reads test-only dependency selectors from the environment.

### 10.2 Startup behavior

- Missing, malformed, contradictory, or production-unsafe application configuration raises a configuration error before serving and fails startup.
- A temporarily unavailable PostgreSQL server does not fail process construction. The pool starts reconnecting in the background; liveness remains true and readiness remains false.
- A permanent local contract mismatch detected on the first readiness check remains not ready and is logged safely. It is not repaired.
- No migration, reset, seed, verification suite, test helper, or write occurs at startup.

Windows Server 2025 and the exact CPython 3.14.6 patch are implementation/acceptance-evidence facts, not Flask settings and not customer-facing runtime gates. The factory does not read environment variables for them and does not reject another compatible standard GIL-enabled CPython 3.14.x patch merely because it is not 3.14.6. Use of another patch for formal acceptance evidence would require its own recorded verification; it does not change `requires-python = ">=3.14,<3.15"`.

### 10.3 Request and shutdown lifecycle

Pool leases and transactions use nested context managers. They are released before the route returns. `teardown_appcontext` performs request-local cleanup only; it must not close the process pool after each request.

`close_resources(app)` is idempotent and closes the pool with a bounded close wait. The WSGI process hook and every application fixture call it. If construction fails after the pool exists, the factory closes already-created resources before reraising. A broken connection is closed/discarded, not returned as healthy. Normal application shutdown never issues business SQL.

## 11. Runtime and dependency decisions

### 11.1 Runtime

- Version 1 supports standard GIL-enabled CPython 3.14.x only. CPython 3.14.6 is the installed and initially tested implementation and verification patch. API-04 records the exact initially tested patch as CPython 3.14.6 and constrains future project metadata to `>=3.14,<3.15`.
- Free-threaded CPython builds, PyPy, and other Python implementations are outside the initially verified target. Formal API-04/API-09 evidence verifies `platform.python_implementation() == "CPython"`, the exact installed `3.14.6` patch, and an enabled GIL. These evidence checks are not Flask configuration or startup behavior.
- The service is a WSGI Flask application. Production server/topology selection is deployment scope; Flask's development server is never a production requirement.
- Source uses type annotations and immutable dataclasses where they make boundaries explicit. Runtime type checking is not added.
- The initial implementation, dependency verification, automated-test evidence, manual evidence, and performance evidence run on Windows Server 2025.
- Node.js 24.15.0 is not a Flask runtime or test dependency and is not used by API-03 or API-04. No Node.js package, npm setting, JavaScript tool, frontend dependency, or React compatibility choice is selected here; those decisions remain assigned to the later React phase.

### 11.2 Minimum dependencies

| Class | Family selected | Purpose | Version policy |
|---|---|---|---|
| Runtime | Flask 3.1.x | WSGI app, routing, request/response, test client | `>=3.1,<3.2`; official metadata is Python 3 compatible, requires Python >=3.9, and publishes an OS-independent wheel; exact tested resolution recorded by API-04 |
| Runtime | Psycopg 3.2.x with synchronized binary support | PostgreSQL protocol and parameter binding | `>=3.2.10,<3.3`; 3.2.10 is the first 3.2 patch whose official release notes add Python 3.14 support; API-04 resolves a matching `psycopg-binary` patch that publishes a CPython 3.14 Windows x86-64 wheel |
| Runtime | `psycopg_pool` 3.2.x | Bounded PostgreSQL connection pool | `>=3.2.8,<3.3`; official 3.2.8 metadata explicitly classifies Python 3.14, CPython, and Microsoft Windows and is compatible with the selected Psycopg 3.2 family |
| Test | pytest 9.x | Test discovery, fixtures, markers, parametrization | `>=9,<10`; official metadata explicitly classifies Python 3.14 and Microsoft Windows; exact tested resolution recorded by API-04 |
| Test | pytest-cov 7.x | Coverage reporting only | `>=7,<8`; official metadata explicitly classifies Python 3.14, CPython, and Microsoft Windows; exact tested resolution recorded by API-04 |

No ORM, migration framework, schema-validation library, Flask-CORS, retry library, timezone package, fake-data package, task queue, or pytest-Flask plugin is justified. The standard library supplies JSON decoding, `zoneinfo`, dataclasses, enums, logging, UUID generation, random jitter, clocks, email-shape helpers supplemented by the approved rules, and sleeping.

Direct dependency families are bounded to one minor/major compatibility series. API-04 must resolve and record exact installed versions reproducibly under standard GIL-enabled CPython 3.14.6 on Windows Server 2025; patch upgrades require the API-04/API-09 test suites, while a new major/minor family requires an explicit design review. No dependency is auto-updated at runtime.

### 11.3 Authoritative dependency-compatibility evidence

| Family | Official metadata/documentation evidence | CPython 3.14.6 on Windows Server 2025 conclusion |
|---|---|---|
| Flask 3.1.x | [Flask 3.1.3 PyPI metadata](https://pypi.org/project/Flask/3.1.3/) requires Python >=3.9, classifies the distribution as OS Independent, and publishes `py3-none-any`; [official 3.1.x changes](https://flask.palletsprojects.com/en/stable/changes/) preserve the 3.1 family | Compatible: 3.14.6 satisfies the Python range and the universal wheel has no Windows/CPython ABI restriction |
| Psycopg 3.2.x | [Official Psycopg release notes](https://www.psycopg.org/psycopg3/docs/news.html#psycopg-3-2-10) state that 3.2.10 added Python 3.14 support; [Psycopg 3.2.13 metadata](https://pypi.org/project/psycopg/3.2.13/) classifies Python 3.14, CPython, and Microsoft Windows | Compatible only from 3.2.10 within the selected family; the lower bound is tightened accordingly |
| Psycopg binary | [Psycopg Binary 3.2.13 files](https://pypi.org/project/psycopg-binary/3.2.13/) include `psycopg_binary-3.2.13-cp314-cp314-win_amd64.whl` | Compatible with standard 64-bit CPython 3.14 on Windows; API-04 must keep the binary patch synchronized with `psycopg` |
| `psycopg_pool` 3.2.x | [`psycopg_pool` 3.2.8 metadata](https://pypi.org/project/psycopg-pool/3.2.8/) requires Python >=3.8, explicitly classifies Python 3.14/CPython/Microsoft Windows, and publishes `py3-none-any` | Compatible with CPython 3.14.6 on Windows Server 2025 and the selected Psycopg 3.2 family |
| pytest 9.x | [pytest 9.1.1 metadata](https://pypi.org/project/pytest/9.1.1/) requires Python >=3.10, explicitly classifies Python 3.14 and Microsoft Windows, and publishes `py3-none-any` | Compatible |
| pytest-cov 7.x | [pytest-cov 7.1.0 metadata](https://pypi.org/project/pytest-cov/7.1.0/) requires Python >=3.9, explicitly classifies Python 3.14/CPython/Microsoft Windows, and publishes `py3-none-any` | Compatible |

This is metadata/documentation compatibility evidence, not substituted runtime evidence. API-04 must verify the resolved dependency set by importing it and running its formal initial tests under installed CPython 3.14.6 on Windows Server 2025. No package was installed or changed during this API-03 verification.

## 12. Runtime configuration catalogue

All application settings are read once at factory construction and become immutable. Names are case-sensitive. Whitespace-only values are missing. Unknown `CAFE_FAUSSE_*` variables are rejected to catch misspellings; standard unrelated process variables are ignored. Secrets are never placed in Flask config dumps or logs.

### 12.1 Catalogue

| Variable | Type / allowed values | Default | Required / rule | Secret? |
|---|---|---:|---|---:|
| `CAFE_FAUSSE_ENVIRONMENT` | `development`, `test`, `production` | none | Required | no |
| `CAFE_FAUSSE_DEBUG` | exact `true` or `false` | `false` | `true` is accepted only in development; test/production reject it | no |
| `PGHOST` | nonblank libpq host/socket path | none | Required | no |
| `PGPORT` | integer 1-65535 | `5432` | Optional | no |
| `PGDATABASE` | nonblank database name | none | Required; test must target an approved nonproduction database | no |
| `PGUSER` | nonblank deployment login | none | Required; login must be able to `SET ROLE cafe_fausse_app` | potentially |
| `PGPASSWORD` | libpq password | none | Optional; prefer protected passfile/secret injection | yes |
| `PGPASSFILE` | protected passfile path | libpq default | Optional alternative credential source; not logged | yes |
| `PGSSLMODE` | libpq supported value | libpq default | Deployment-owned; production must not select `disable` for a network connection | no |
| `PGCONNECT_TIMEOUT` | integer seconds 1-10 | `3` | Optional; validated | no |
| `CAFE_FAUSSE_POOL_MIN_SIZE` | integer 0-5 | `1` | Must be <= max | no |
| `CAFE_FAUSSE_POOL_MAX_SIZE` | integer 1-20 | `5` | Must be >= min | no |
| `CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS` | integer 50-3000 | `500` | Per lease acquisition | no |
| `CAFE_FAUSSE_READ_DEADLINE_MS` | integer 250-5000 | `2000` | OP-01/02/03 read deadline | no |
| `CAFE_FAUSSE_MUTATION_DEADLINE_MS` | integer 3000-15000 | `15000` | OP-04/05 overall deadline | no |
| `CAFE_FAUSSE_READINESS_DEADLINE_MS` | integer 100-3000 | `1000` | OP-07 total check deadline | no |
| `CAFE_FAUSSE_MAX_DB_ATTEMPTS` | integer 1-3 | `3` | Three is the approved production value; production rejects any other value | no |
| `CAFE_FAUSSE_RETRY_BASE_DELAY_MS` | integer 10-250 | `25` | Base exponential delay | no |
| `CAFE_FAUSSE_RETRY_CAP_DELAY_MS` | integer 50-1000 | `200` | Must be >= base | no |
| `CAFE_FAUSSE_RETRY_JITTER_RATIO` | decimal 0.0-0.5 | `0.25` | Symmetric multiplicative jitter | no |
| `CAFE_FAUSSE_RETRY_MIN_REMAINING_MS` | integer 100-2000 | `500` | Do not start another attempt below this remaining budget | no |
| `CAFE_FAUSSE_MAX_REQUEST_BYTES` | integer 4096-65536 | `16384` | Global request-body ceiling | no |
| `CAFE_FAUSSE_LOG_LEVEL` | `DEBUG`, `INFO`, `WARNING`, `ERROR` | environment-specific | Production may not use `DEBUG` | no |
| `CAFE_FAUSSE_LOG_FORMAT` | `text`, `json` | environment-specific | Production requires `json` | no |
| `CAFE_FAUSSE_POOL_CLOSE_TIMEOUT_MS` | integer 100-5000 | `1000` | Process/test teardown bound | no |

There is no consolidated DSN. Psycopg receives standard libpq variables as the single connection source. `PGPASSWORD` and `PGPASSFILE` must not both be deliberately configured by Cafe Fausse tooling. Actual credential distribution, TLS termination, and production login creation are deployment concerns; API-04 only consumes the connection environment. The database group role remains NOLOGIN, so the deployment login must be granted membership outside the application and every pooled session must successfully `SET ROLE cafe_fausse_app` before use.

The database-owned lock timeout (3 seconds), routine statement timeout (15 seconds), three-attempt ceiling, and `READ COMMITTED` mutation isolation are frozen facts, not application feature flags. Application deadlines do not weaken or override them.

### 12.2 Environment matrix

| Concern | Development | Test | Production |
|---|---|---|---|
| Initial evidence host (not Flask configuration) | Windows Server 2025 | Windows Server 2025; recorded by formal evidence guard | Windows Server 2025 initial deployment/evidence host |
| Supported Python runtime | Standard GIL-enabled CPython 3.14.x | Standard GIL-enabled CPython 3.14.x | Standard GIL-enabled CPython 3.14.x |
| Initial Python evidence patch (not Flask configuration) | Installed CPython 3.14.6 | CPython 3.14.6 with implementation/version/GIL evidence | CPython 3.14.6 initial deployment/evidence patch |
| `CAFE_FAUSSE_ENVIRONMENT` | `development` | `test` | `production` |
| Flask debug/reloader | May be enabled by local entry command; never inferred from secret values | off | off |
| Log default | `DEBUG`, text | `INFO`, text unless log-format tests select JSON | `INFO`, JSON |
| Database | Explicit approved local nonproduction target | Dedicated guarded database named `cafe_fausse_test_*`; never production | Explicit deployed target |
| Pool defaults | 1-5 | 0-2 for most tests; integration may choose 1-5; contention fixture explicitly sizes >= workers | 1-5 until API-09 evidence justifies change |
| Dependency injection | Production dependencies unless code calls factory explicitly | Explicit fixture-supplied dependencies allowed | Production WSGI path only; no test selector |
| Exception detail in public response | Never | Never | Never |
| Traceback logging | Sanitized, no locals/bodies | Captured and asserted sanitized | Sanitized internal event; never public |
| CORS | Same-origin; frontend dev proxy later | Same-origin | Same-origin |
| Startup config failures | Fatal | Fatal | Fatal |
| Database unavailable at startup | App live, not ready | Fixture decides expected behavior | App live, not ready |
| Node.js | Not used by Flask/API-04 | Not used by Flask/API tests | Not a Flask runtime dependency; Node.js 24.15.0 remains reserved for later React work |

`CAFE_FAUSSE_ALLOW_RESET` belongs exclusively to existing guarded database scripts. It is not an application setting and Flask never reads it.

Factory-derived Flask settings are also fixed: `TESTING` is true only for the `test` environment, `DEBUG` equals the validated development-only debug setting, `MAX_CONTENT_LENGTH` equals the byte limit, JSON key sorting is disabled, and exception propagation is disabled so the API-02 handler is exercised in every environment. `SECRET_KEY` remains unset because Version 1 uses no session/cookie/signing feature. These values cannot be overridden by a second Flask-prefixed environment source.

The evidence-host and evidence-patch rows are recorded platform facts, not variables consumed by `config.py`. They do not add an OS/exact-patch branch to application startup and do not narrow the project metadata below `>=3.14,<3.15`.

## 13. Exact timeout, retry, backoff, and jitter design

Deadlines use an injected monotonic clock. Wall-clock changes cannot extend them.

| Operation | Overall application deadline | Pool acquisition | Database/server limit | Internal retry |
|---|---:|---:|---:|---|
| OP-01/02/03 | 2,000 ms default | Up to 500 ms within deadline | Read transaction constrained to remaining deadline, never above 2,000 ms | Safe technical retries within remaining budget, max 3 attempts |
| OP-04/05 | 15,000 ms default | Up to 500 ms each attempt within deadline | Frozen routine sets 15-second statement timeout and 3-second lock timeout | Only approved safe classes, max 3 total attempts |
| OP-06 | No database deadline | none | none | none |
| OP-07 | 1,000 ms default | Up to 500 ms within deadline | Read-only readiness statements constrained to remaining deadline | No retry within one probe |

An attempt includes pool wait, transaction, row decoding, and commit. The service records a deadline once and passes remaining time downward. Before attempts 2 or 3 it computes:

`nominal_delay = min(cap, base * 2 ** (completed_attempts - 1))`

`actual_delay = nominal_delay * uniform(1 - jitter_ratio, 1 + jitter_ratio)`

With defaults, the nominal delays are 25 ms before attempt 2 and 50 ms before attempt 3; actual ranges are 18.75-31.25 ms and 37.5-62.5 ms. Tests inject exact jitter values and a non-sleeping recorder. Production uses a process-local cryptographically unnecessary pseudorandom source; tie selection remains database-owned and is not affected by this source.

A retry starts only when the prior attempt is conclusively rolled back or performed no database work, the class is eligible, the attempt count is below three, and remaining time after the chosen sleep is at least `CAFE_FAUSSE_RETRY_MIN_REMAINING_MS`. Otherwise the operation returns its API-02 temporary/unknown mapping immediately.

Automatic mutation retry is limited to PostgreSQL SQLSTATE `55P03`, `40P01`, and `40001`, exactly as frozen. Each retry acquires a connection and opens a new transaction. Pool acquisition failure before any statement may retry within the same ceiling. Read-only operations may also retry a connection loss because they cannot commit state. Mutation connection loss after dispatch, during result receipt, or during commit is never automatically retried because outcome may be unknown. SQLSTATE `57014`, validation errors, database business outcomes, programming errors, contract-shape errors, and arbitrary `08xxx` failures after mutation dispatch do not enter the approved automatic mutation loop.

The two-second SRS expectation is an API-09 measurement target, not a changed timeout or success guarantee. The 15-second mutation ceiling accommodates the frozen 3-second lock behavior and bounded retry; many successful requests are expected to finish much sooner.

## 14. PostgreSQL pool, connection, transaction, and cleanup design

### 14.1 Pool construction and session safety

One `psycopg_pool.ConnectionPool` is created per Flask application with `open=False`, the configured min/max sizes, and a configure callback. Startup calls `open(wait=False)`. The callback performs only fixed session configuration: sets a non-sensitive `application_name`, executes `SET ROLE cafe_fausse_app`, and verifies `current_user` is the frozen application role. No user value enters this SQL.

A check callback rejects closed, transaction-dirty, wrong-role, or otherwise unusable leases. Each checkout starts idle and application-role constrained. Any failed rollback, lost connection, wrong role, or uncertain session state causes close/discard. Pool statistics may be logged only as counts/timings, never connection strings.

### 14.2 Connection and transaction ownership

Routes and validators never own connections. The operation service owns the orchestration deadline and asks its gateway to perform a precisely defined attempt. The gateway owns the lease and explicit transaction context.

- Read operations use explicit read-only transactions. OP-01 and OP-02 each use one `REPEATABLE READ READ ONLY` transaction for a coherent multi-query snapshot. OP-03 uses one `READ COMMITTED READ ONLY` transaction.
- OP-04 and the booking stage of OP-05 use explicit `READ COMMITTED` transactions. The approved routine call is the only statement inside the mutation transaction, apart from fixed transaction/session control performed by the adapter. The returned row is fully consumed before commit.
- A successful transaction context exit is the commit-certainty boundary. A raised exception triggers rollback before classification. If rollback itself cannot be confirmed after a mutation was dispatched, outcome is unknown.
- Application code never nests business transactions, holds a lease across an HTTP response, performs routine calls in autocommit mode, or retries on the same transaction.

### 14.3 Cleanup

Gateway contexts release healthy idle connections. Broken/uncertain connections are closed so the pool replaces them. Request teardown clears only request-local timing/correlation data. Test fixtures and process shutdown call the idempotent application resource closer. No cleanup path performs schema/data cleanup; database-test cleanup is separately authorized test tooling.

## 15. OP-01 through OP-07 database-access specifications

### 15.1 OP-01 current reservation context

The context gateway performs fixed SELECT projections from `reservation_configuration`, `restaurant_operating_hours`, and `restaurant_tables`, all granted foundation reads, plus a database-clock expression using the configured timezone. One `REPEATABLE READ READ ONLY` transaction yields a coherent current snapshot: one configuration, weekdays 1-7, exactly 30 positive-capacity tables, database-local current/minimum/maximum dates, total capacity, and capacity-derived maximum party size. Flask checks result shape/invariants only to detect an invalid database configuration; it does not calculate replacement configuration or persist a cache. Table inventory is summarized only into API-02 public fields; table identities/capacities are never exposed.

### 15.2 OP-02 provisional availability

Within one `REPEATABLE READ READ ONLY` transaction, the availability gateway reads only `cafe_fausse.reservation_configuration.restaurant_timezone`, calls the unchanged `cafe_fausse.provisional_availability(%s::date, %s::integer)` routine with bound validated values, and consumes all rows. The timezone identifier is used only to serialize the exact API-02 response. No other foundation-table read is permitted. The gateway preserves database order after verifying unique legitimate local starts and maps database outcome/detail through the frozen catalogue. Flask serializes every returned slot, including unavailable slots, and never computes capacity, allocates tables, removes full slots, or treats provisional availability as a guarantee.

### 15.3 OP-03 newsletter-status query

The customer gateway performs the approved, narrow `customers` projection by canonical email in one read-only transaction. It selects only fields needed to distinguish no customer, an exact identity match, or the generic mismatch and to return the authoritative current newsletter state. It never selects phone, reservations, assignments, or other customers and never writes. Normalization is caller-boundary validation; stored names govern match/response behavior.

### 15.4 OP-04 newsletter preference

The newsletter gateway calls only `cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)` in an explicit `READ COMMITTED` transaction. Its single result is consumed, decoded to an internal expected outcome, then committed. Known routine outcomes map to API-02. A failure before dispatch or a conclusively rolled-back approved retry class may retry; inability to establish whether commit occurred maps to `newsletter_preference_outcome_unknown` with both flags true. Flask never writes `customers` directly and never maintains a second subscriber store.

### 15.5 OP-05 reservation creation or reconstruction

The reservation gateway calls only `cafe_fausse.book_reservation(text,text,text,text,text,timestamp without time zone,smallint,integer,text)` with validated bound values in `READ COMMITTED`. It consumes exactly one result and validates its stable shape/outcome. `booked`, `booked_phone_notice`, and `exact_retry` are known reservation results; all other stable outcomes follow the frozen mapping.

On a known successful booking or exact retry, the mutation transaction commits first. While retaining the same healthy leased physical connection, the gateway begins a separate `READ COMMITTED READ ONLY` transaction and selects the approved stored first/middle/last name projection from `customers` by canonical email. The separation is mandatory: the name read is not part of, and cannot roll back, the booking. Reusing the clean lease avoids a second pool wait but does not reuse the mutation transaction.

The public confirmation uses the routine's committed reservation facts plus stored customer-name spelling. It never echoes submitted spelling as authoritative. If the post-commit name read succeeds, the connection returns idle to the pool. If that read fails or returns an impossible shape, the known reservation facts are retained internally, the connection is discarded when needed, and the response is `reservation_confirmation_unavailable` (`retryable:true`, `outcome_unknown:false`). The service does not call booking again merely to repair a confirmation-name read.

If connection/commit failure leaves the booking transaction uncertain, there is no post-commit name read and no automatic retry. The response is `reservation_outcome_unknown` (`retryable:true`, `outcome_unknown:true`). An unchanged client resubmission is safe because the frozen database fingerprint/exact-retry logic reconstructs the committed outcome if the first attempt committed. Known rollback or pre-dispatch failure remains distinct and maps to the applicable temporary response.

### 15.6 OP-06 liveness

Liveness is an in-process constant check that the Flask request path is executing. It performs no pool checkout, SQL, filesystem access, migration, reset, seed, network call, or background repair. It returns exactly the API-02 live body and uniform response headers.

### 15.7 OP-07 readiness

Readiness obtains at most one lease within its 1,000 ms deadline and performs fixed read-only checks sufficient to prove the session is PostgreSQL 18.3, has `pgcrypto`, is acting as `cafe_fausse_app`, can execute all three frozen production routines, can select the four foundation tables, and sees complete/valid foundation population. It does not call a mutation routine, generate availability as a substitute health write, run DB-07 verification, or inspect/repair schema beyond the frozen checks.

Internally the result categories are `pool`, `platform`, `contract`, and `foundation`; the public response remains only the API-02 ready body or generic `service_not_ready` envelope. Detailed component/SQL facts are log-only allowlisted categories. Failure never changes liveness.

### 15.8 Gateway contracts and test-double boundaries

| Op | Adapted input | Authorized access and internal facts | Transaction / owner / retry | Safe result and prohibited access | Test double |
|---|---|---|---|---|---|
| OP-01 | None | Fixed projections of configuration, seven weekday hours, 30 positive capacities, aggregates, and database-local date bounds | Gateway owns one `REPEATABLE READ READ ONLY` lease/transaction; service may safely retry a read | `ContextResult` or invalid-foundation/technical category; no customers, reservations, assignments, fabricated defaults, or cache | `ContextGateway.get_context()` |
| OP-02 | Validated `date` and exact integer party size | In one snapshot, reads only `reservation_configuration.restaurant_timezone`, then calls `provisional_availability(date,integer)` and consumes `outcome`, nullable `detail_code`, `local_start`, `starts_at`, `ends_at`, `available` for every row | Gateway owns one `REPEATABLE READ READ ONLY` transaction; safe read retry uses a fresh lease/transaction | `AvailabilityResult` containing the serialization timezone and every legitimate start or frozen invalid/config category; no other foundation read, holds, candidates, assignments, capacity query, or persistence | `AvailabilityGateway.get_day(date, party_size)` |
| OP-03 | Normalized names/middle and canonical email | Minimal `customers` projection of first/middle/last and `newsletter_subscribed` by canonical email | Gateway owns one short read-only transaction; safe read retry | `NewsletterStatusResult` for no customer/exact match/generic mismatch/current Boolean; no phone, ID, profile, reservation, assignment, or write | `CustomerGateway.get_newsletter_status(identity)` |
| OP-04 | Normalized names/middle/email and exact Boolean | `set_newsletter_preference(...)`; consumes `outcome`, `newsletter_subscribed` | Gateway owns explicit `READ COMMITTED`; commit on returned result, rollback before eligible retry; discard uncertain connection | `PreferenceResult` or frozen conflict/known/unknown technical category; no direct customer DML/read-after-write or second subscriber state | `NewsletterGateway.set_preference(command)` |
| OP-05 | Normalized names/middle/email, optional phone, local start, `smallint` offset, integer party, newsletter action | `book_reservation(...)`; consumes `outcome`, `detail_code`, `reservation_id`, `starts_at`, `ends_at`, `party_size`, sorted `assigned_table_numbers`, `newsletter_subscribed`, `phone_notice`, internal fingerprint version/bytes; after known commit, minimal stored-name SELECT | Gateway owns explicit booking `READ COMMITTED`, commit/rollback/certainty, then separate read-only name transaction; only approved retry classes | `BookingResult`, known confirmation-unavailable, or unknown-booking result; fingerprint stays internal and is not logged; no direct reservations/assignments read, DML, allocator, or test helper | `ReservationGateway.book(command)` returning a certainty-aware attempt result |
| OP-06 | None | No database access or returned DB fact | No transaction/retry/lease | `LiveResult`; no I/O or diagnostics | `LivenessService` is pure; a gateway double is unnecessary |
| OP-07 | None | Fixed catalog privilege/platform checks and minimum foundation projections through the app-role lease | Gateway owns one short read-only transaction; one probe attempt, no retry | `ReadyResult` or coarse internal component failure; no mutation routine invocation, test/verification helper, repair, or public diagnostic | `HealthGateway.check_readiness()` |

The gateway protocols return typed values and raise only the internal technical exception categories. Fakes implement these methods without Flask/Psycopg. Contract-shape tests exercise the concrete adapters separately so fake success cannot hide a wrong SQL signature or row decoder.

### 15.9 Normal-operation and failure sequences

| Sequence | Ordered behavior and terminal result |
|---|---|
| Read success (OP-01/02/03) | Parse/validate -> start monotonic deadline -> acquire app-role lease -> begin read-only transaction -> execute fixed projection/routine -> consume and validate rows -> commit/end read transaction -> release lease -> serialize exact 200 response. |
| Read transient | Failure -> end/rollback transaction -> discard broken lease when necessary -> classify as safely repeatable -> apply bounded delay if eligible/budgeted -> use a new lease/transaction -> otherwise emit the operation's API-02 503 with known outcome. |
| Mutation success (OP-04) | Parse/validate -> acquire lease -> begin `READ COMMITTED` -> call the single preference routine -> consume expected result -> commit -> release lease -> serialize authoritative 200 state. |
| Booking success/exact retry (OP-05) | Parse/validate -> acquire lease -> begin `READ COMMITTED` -> call booking routine -> consume known result -> commit -> begin a separate read-only transaction on the clean lease -> read stored name -> end transaction/release -> serialize 201 created or 200 exact-retry confirmation. |
| Approved retryable mutation failure | Routine returns SQLSTATE `55P03`, `40P01`, or `40001` -> transaction is conclusively rolled back -> release/discard as health requires -> check attempts/deadline -> jittered sleep -> new lease and new `READ COMMITTED` transaction -> at most three total attempts. |
| Known mutation rollback/exhaustion | Rollback/no commit is proven but no allowed retry remains -> release/discard -> emit `temporary_failure`, `retryable:true`, `outcome_unknown:false`. |
| Unknown mutation | Connection/result/commit certainty is lost after dispatch -> discard connection -> do not auto-retry or perform OP-05 name read -> emit the operation-specific outcome-unknown 503; client may resubmit the identical body. |
| Known booking, failed confirmation read | Booking/exact retry commit is proven -> separate stored-name read fails -> discard if needed -> do not undo/rebook -> emit `reservation_confirmation_unavailable`, `retryable:true`, `outcome_unknown:false`. |
| Unexpected defect | Roll back if possible -> determine mutation certainty before response selection -> log only allowlisted metadata -> emit `internal_error` only for a known nonmutation/noncommit; otherwise preserve the operation-specific unknown-outcome response. |

These sequences make response selection occur only after the transaction certainty boundary. Logging occurs after safe result selection and cannot change the HTTP/database outcome.

## 16. Validation and serialization pipeline

### 16.1 Pipeline

1. Reject any body above 16,384 bytes through Flask's maximum-content-length setting.
2. For GET, reject any nonempty body and reject query names/counts not exactly allowed by the endpoint.
3. For POST, require `Content-Type: application/json` with optional charset compatible with UTF-8; reject missing/wrong media type before parsing.
4. Read bytes once, decode strict UTF-8, and require a nonempty body.
5. Decode JSON with duplicate-key detection at every object level, parse fractional/exponent number tokens as `Decimal`, and reject `NaN`, `Infinity`, and `-Infinity`.
6. Require a top-level object and exact allowed/required property sets.
7. Validate primitive JSON types strictly (`bool` is not an integer), lengths, character rules, canonical format rules, and ordered cross-field rules.
8. Normalize only as approved: surrounding permitted whitespace, names/email/phone/temporal values according to API-02 and PRA rules. Retain submitted input only in request-local memory.
9. Call one service with an immutable validated command/query.
10. Convert one typed result with a pure serializer, then apply uniform response policies.

Duplicate JSON properties map to `invalid_json`; absent/non-object bodies and forbidden properties follow the exact API-02 syntax/shape categories. A bounded integer accepts an ordinary JSON integer or a finite decimal/exponent token whose mathematical value is exactly integral (for example, `1e0`); it rejects Booleans, strings, and any non-integral value. Validation errors are deterministically ordered first by API-02 field order and then by rule order so tests and clients never depend on dictionary/set iteration.

### 16.2 Validation ownership

Flask validates public syntax and fields early for safe feedback. PostgreSQL remains authoritative for current date/window, current configuration, schedule, timezone validity, availability, capacity, overlap, identity conflict, exact retry, and committed newsletter state. A database rejection after Flask validation is preserved; Flask never converts it into success or recalculates the answer.

### 16.3 Serialization

Serialization functions accept only typed internal results. They emit exact API-02 names/types/nullability/enums, explicit `HH:MM:SS` local time, canonical timestamps, and BIGINT reservation references as decimal JSON strings. They do not serialize dataclasses generically, Psycopg rows, exceptions, Decimal/date/time objects, internal outcome details, fingerprints, SQLSTATE, table capacity, customer identifiers, or pool facts. Flask's JSON provider is configured for UTF-8 JSON and does not sort away the intentional human-readable property order; consumers still treat object order as insignificant.

## 17. Error taxonomy and API-02 translation

### 17.1 Internal taxonomy

| Internal category | Meaning | Mechanism |
|---|---|---|
| Protocol syntax/shape | HTTP body/media/JSON/method/route failure | Typed protocol exception or Flask `HTTPException` |
| Caller validation | Field/cross-field issue | Validation result containing ordered safe field errors |
| Expected business outcome | Routine/read returned a frozen non-success outcome | Typed result value |
| Known transient dependency failure | No mutation or confirmed rollback; service temporarily unavailable | Typed technical exception with certainty `known` |
| Unknown mutation outcome | Dispatch/commit may have persisted state | Typed technical exception with certainty `unknown` |
| Known post-commit confirmation failure | Booking known committed; stored-name projection unavailable | Typed OP-05 result retaining safe reservation facts internally |
| Contract/invariant defect | Unexpected row count/type/outcome or impossible state | Internal exception; log safe class/category |
| Unexpected defect | Unhandled programming/runtime fault | Outer exception handler; generic public response |

### 17.2 Public translation matrix

Every error body has `code`, `message`, `retryable`, and `outcome_unknown`. `fields` appears only where API-02 allows it. Message text is the exact approved safe text selected during implementation; internal exception text is never used.

| HTTP | API-02 code | `retryable` | `outcome_unknown` | Principal trigger |
|---:|---|---:|---:|---|
| 400 | `invalid_json` | false | false | Malformed/non-UTF-8/duplicate-key/non-finite JSON |
| 400 | `request_body_required` | false | false | Required POST body absent/empty |
| 400 | `invalid_request` | false | false | API-02 request-shape/protocol failure not represented as field validation, including a body over 16,384 bytes |
| 404 | `route_not_found` | false | false | Unknown route, including unapproved API paths |
| 405 | `method_not_allowed` | false | false | Known route with wrong method; preserve exact `Allow` header |
| 415 | `unsupported_media_type` | false | false | POST media type is not acceptable JSON |
| 422 | `validation_failed` | false | false | Caller-correctable field/cross-field validation; include fields |
| 409 | `customer_identity_conflict` | false | false | Frozen generic stored-identity mismatch |
| 409 | `middle_initial_conflict` | false | false | Frozen middle-initial conflict |
| 409 | `reservation_overlap` | false | false | Known same-customer overlap |
| 409 | `reservation_unavailable` | false | false | Known authoritative capacity/stale-slot loss; refresh/choose slot |
| 503 | `newsletter_status_indeterminate` | true | false | Read outcome temporarily cannot be established; safe identical lookup retry |
| 503 | `temporary_failure` | true | false | Known no-commit/rollback dependency failure where unchanged retry is safe |
| 503 | `newsletter_preference_outcome_unknown` | true | true | OP-04 commit outcome cannot be established |
| 503 | `reservation_confirmation_unavailable` | true | false | OP-05 booking known, post-commit stored-name read failed |
| 503 | `reservation_outcome_unknown` | true | true | OP-05 booking commit may or may not have occurred |
| 503 | `service_unavailable` | true | false | Liveness-independent dependency unavailable for a workflow |
| 503 | `service_not_ready` | true | false | OP-07 coarse not-ready result |
| 500 | `internal_error` | false | false | Unexpected server defect with no unknown mutation outcome |

Database `outcome`/`detail` literals are accepted only through exhaustive operation-specific mapping tables in the gateway/service. Unknown literals are contract defects, never reflected publicly. Error handlers also cover Flask-generated 404/405/413 cases so HTML is never returned. An intercepted 413 is deliberately translated to the existing `400 invalid_request` envelope because API-02 defines neither a 413 status nor a payload-too-large code; no new public contract element is added.

## 18. HTTP, cache, CORS, security, and privacy policy

### 18.1 Exact response policy

Every Version 1 response, including errors and health responses, carries:

- `Content-Type: application/json; charset=utf-8`;
- `Cache-Control: no-store, max-age=0`;
- `Pragma: no-cache`;
- `Expires: 0`;
- `X-Content-Type-Options: nosniff`;
- `Referrer-Policy: no-referrer`.

405 responses additionally carry Flask's correct `Allow` header. API-02 defines no `Retry-After`, ETag, cookies, redirect, HTML, or public correlation header, so none is added. HSTS belongs at the TLS edge and Content-Security-Policy belongs with the future frontend/deployment response; neither is fabricated by this JSON-only application design.

### 18.2 CORS and request policy

Version 1 is same-origin. Flask emits no `Access-Control-Allow-*` headers and provides no automatic OPTIONS-based cross-origin contract. Future React development uses a same-origin development proxy and deployed integration uses the same origin. Changing allowed origins is a later explicit contract/deployment decision, not an environment wildcard. No Flask sessions, CSRF token, authentication cookie, profile, or ownership claim exists in Version 1.

Only the seven exact `/api/v1` routes are registered. Request bodies are capped at 16 KiB. SQL is fixed and values are parameterized. The service never accepts a database fingerprint, table identifier, customer identifier, SQL fragment, role, schema, or connection setting from HTTP input.

### 18.3 Privacy boundary

Responses expose only API-02 workflow-minimum data. There is no customer/reservation listing or lookup, table selection, capacity detail, internal identifier beyond the approved reservation reference, diagnostic detail, or authentication claim. Submitted identity/contact data lives only long enough to validate and execute the request. Confirmation-name output comes from approved stored spelling. Health exposes no version, role, host, database, extension, table, routine, pool, or exception detail.

## 19. Structured logging, redaction, and observability

### 19.1 Events and allowlisted fields

Production emits newline-delimited JSON through the standard logging package. One request-completion event is produced after response selection; retry/readiness/startup/shutdown events are separate and sparse.

Allowed fields are: timestamp, severity, event name, environment, operation (`OP-01` through `OP-07`), HTTP method, registered route template (never raw path), status, public error code or internal coarse outcome category, elapsed milliseconds, pool-wait milliseconds, database milliseconds, attempt number, retry class from an allowlist, remaining deadline bucket, internal correlation UUID, readiness component category, exception class from an allowlist, and approved SQLSTATE only for `55P03`, `40P01`, or `40001`.

Forbidden at every level:

- request/response bodies or headers;
- names, emails, phone numbers, local/UTC reservation times tied to a person, newsletter choices, or party size tied to a request;
- reservation/customer/table/assignment identifiers, fingerprints, database result rows, SQL parameters, query strings, or raw URL paths;
- passwords, passfiles, hosts, database/user names, DSNs, environment dumps, stack-frame locals, or pool connection strings;
- database outcome/detail text unless represented by an explicitly allowlisted coarse internal category.

The formatter constructs output from an allowlist rather than trying to redact arbitrary objects after interpolation. Exception messages and `repr()` values are not fields. Sanitized tracebacks may record code locations/classes but must disable local-variable capture. Development follows the same PII/secret boundary.

### 19.2 Correlation, timing, metrics, and traces

An internal UUIDv4 is generated for every request, stored request-locally, and used only in logs. Incoming correlation headers are ignored and the ID is never returned publicly. Tests inject deterministic IDs.

Monotonic timers measure total request time, cumulative pool wait, cumulative database time, retry sleeps, and post-commit name-read time. Values are numeric milliseconds and contain no labels derived from input. External metrics/tracing systems are not added in Version 1; API-09 may summarize sanitized log timings. Readiness logs transition events at INFO/WARNING and repeated unchanged failures at a bounded cadence to avoid floods.

## 20. Liveness and readiness architecture

| Property | OP-06 liveness | OP-07 readiness |
|---|---|---|
| Purpose | Prove Flask request execution | Prove this instance can safely serve the frozen database contract |
| DB checkout | Never | One bounded lease |
| Mutation | Never | Never |
| Timeout | Ordinary local request only | 1,000 ms total default |
| Success | Exact API-02 live response | Exact API-02 ready response |
| Failure | Unexpected Flask defect only | Generic `service_not_ready` 503 |
| Detail exposure | None | None publicly; coarse internal log category only |
| Side effects | None | PostgreSQL read/session checks only |

Readiness is evaluated per probe and not cached as authority. The pool may perform its own connection maintenance, but the endpoint triggers no repair. A failed readiness check cannot terminate the process, reset the pool globally, migrate, seed, or elevate role. A wrong PostgreSQL version, missing extension/grant/foundation population, or wrong active role is not ready even if a trivial `SELECT 1` succeeds.

## 21. Dependency injection and deterministic test seams

`Dependencies` is an immutable app-local object, never a mutable process singleton. It contains service/gateway instances plus these narrow callables:

| Seam | Production implementation | Test use |
|---|---|---|
| Wall clock | timezone-aware UTC now | Deterministic validation/date cases; never overrides DB authoritative clock |
| Monotonic clock | `time.monotonic` | Deadline progression without real waiting |
| Sleeper | `time.sleep` | Record intended backoff; advance fake monotonic clock |
| Jitter source | bounded `random.Random` draw | Exact low/mid/high jitter assertions |
| Correlation ID factory | UUIDv4 string | Stable sanitized log assertions |
| Gateway protocols | Psycopg adapters | Result/failure fakes for pure service/API tests |
| Pool | Psycopg bounded pool | Fake pool for foundation tests; real pool only under PostgreSQL markers |

Database tie selection remains inside PostgreSQL. The application does not introduce a random table-selection seam. Existing database test-only selection control remains available only to the `cafe_fausse_test` role in database tests and is denied to `cafe_fausse_app`.

Factory injection is explicit Python API used by tests. No environment variable, header, query parameter, Flask route, production registry, or plugin chooses fakes. Integration fixtures construct a real app with an application login constrained to `cafe_fausse_app`; test-role/admin connections live only in fixture management outside the app container.

## 22. pytest architecture, markers, fixtures, lifecycle, and isolation

### 22.1 Test tiers and markers

| Marker | Meaning | Default local selection |
|---|---|---|
| `unit` | Pure modules with no Flask app and no PostgreSQL | yes |
| `api` | Flask test client with fake gateways; exact HTTP contract | yes |
| `integration` | Real Flask plus PostgreSQL | explicit |
| `postgres` | Requires approved local PostgreSQL 18.3 test target | explicit |
| `failure_injection` | Controlled DB/network/adapter failure seam | explicit |
| `concurrency` | Multiple clients/connections with deterministic coordination | explicit |
| `performance` | Non-gating timing evidence unless API-09 says otherwise | explicit |
| `slow` | Rebuild/contention/timing cases | explicit |

Tests fail on unknown markers. Test names carry stable IDs in docstrings/parameters (`UT-API-*`, `AT-API-*`, `IT-DBAPI-*`, `PT-API-*`) for traceability.

### 22.2 Core fixtures

| Scope | Fixture | Responsibility |
|---|---|---|
| session | `acceptance_platform_guard` | When a formal API-04/API-09 evidence run is requested, require and record Windows Server 2025, CPython 3.14.6, CPython implementation, and an enabled GIL; report mismatches without changing software. Ordinary application startup and non-acceptance test runs do not invoke this guard. |
| session | `validated_settings` | Build immutable test settings without secrets in reports |
| session | `postgres_test_database` | Verify target guard, rebuild through approved scripts/migrations, verify PostgreSQL 18.3/contract, and yield connection facts without printing credentials |
| session | `admin_connection` | Test-management connection using approved nonproduction authority only |
| session | `app_login` | Deployment-style login able to `SET ROLE cafe_fausse_app`; never test/admin role |
| function | `fake_dependencies` | Deterministic clocks/jitter/IDs and operation fakes |
| function | `app` | Create exactly one app instance and always close resources |
| function | `client` | Flask test client bound to `app` |
| function | `db_scenario` | Create unique-email/time scenarios through approved test-role tools; record cleanup |
| function | `database_clean` | Delete test-owned transactional data and restore foundation values through approved test tooling, then assert baseline |
| function | `log_capture` | Capture structured records and run forbidden-value assertions |
| function | `failure_controller` | Coordinate known rollback, connection loss, commit ambiguity, and post-commit read failures without production hooks |

### 22.3 Isolation and teardown

The formal PostgreSQL acceptance suite runs on Windows Server 2025 under standard GIL-enabled CPython 3.14.6 and only against a PostgreSQL 18.3 database whose name matches `cafe_fausse_test_*` and passes the existing nonproduction/reset guards. It performs a clean session rebuild using `database/scripts/rebuild.ps1` and the approved migration sequence, followed by verification. Production databases, roles, other PostgreSQL versions, other Python implementations/GIL modes, and other host operating systems are refused as initial acceptance evidence. A non-acceptance developer test run may use another compatible standard GIL-enabled CPython 3.14.x patch; this neither changes the metadata range nor substitutes for the required initial 3.14.6 evidence.

Function scenarios use unique canonical emails and controlled future slots. After each mutating test, an external test-management connection using the approved `cafe_fausse_test` boundary removes assignments before reservations before customers and restores configuration/hours/table capacities through approved controlled test tooling; it then asserts the baseline. The Flask application's app-role connection never cleans data. Full rebuild is the fallback after a failed test or failed cleanup and before subsequent DB tests.

Integration tests are serial by default. No parallel pytest dependency is selected. Concurrency tests create their own bounded clients/connections, explicit barriers, and unique data; the pool maximum is at least the worker count plus one readiness/control lease. Every fixture closes clients, app resources, pool, management connections, and child workers in `finally` paths. Repeated `create_app`/close cycles are tested for leaks.

The DB's current time remains authoritative in real integration tests. Fixtures choose dates relative to a database `CURRENT_DATE` read and use approved controlled schedules. Pure/API tests use an injected clock for deterministic edge cases. DST cases use fixed dates and the approved configured IANA zone.

## 23. Unit-test catalogue

Minimum planned pure tests:

| Area | Required cases |
|---|---|
| Configuration | Every required value; defaults; each boundary/invalid type; min<=max; cap>=base; production log restrictions; test DB guard; unknown application variable; secret-free error text |
| Acceptance-evidence guard | Formal-evidence mode versus ordinary test mode; Windows Server 2025 identity; exact initial CPython 3.14.6; CPython implementation; enabled GIL; clear mismatch output; no application-startup/customer behavior and no installation/remediation side effect |
| JSON parsing | Missing/empty, malformed, non-UTF-8, duplicate nested/top-level keys, non-finite number, scalar/array root, oversized body, wrong media type, GET body/query extras |
| Common validation | Strict Boolean rejection for integer fields; ordinary integers; exact integral/non-integral decimal and exponent forms; Unicode/name rules; whitespace; lengths; email; phone; date/time/offset forms; party bounds; deterministic field ordering |
| Identity/newsletter | Canonical email; stored identity match/mismatch; absent/present middle initial; subscribe/unsubscribe/no-change rules; no phone identity |
| Reservation | Required/optional fields, cross-field rules, arbitrary slot rejection at boundary where applicable, offset and local timestamp shapes, newsletter action |
| Retry | Attempts 1-3, all approved SQLSTATEs, excluded SQLSTATEs, deadline exhaustion, minimum remaining guard, base/cap, exact jitter endpoints, rollback uncertainty, no sleep after final attempt |
| Services | Every expected DB outcome/detail, unknown literal defect, read failure, known rollback, pre-dispatch failure, commit ambiguity, exact retry, post-commit name-read failure |
| Serialization | Every API-02 response variant, nullability, enum, decimal-string BIGINT, stored spelling, full slot list/order, multi-table confirmation, no internal fields |
| Error mapping | Every public code/status/flag combination; fields presence rule; generic 404/405/413/500; no exception/database text |
| Response policy | Exact content type, no-store headers, security headers, no CORS/cookie/correlation/Retry-After |
| Logging/redaction | Each allowed field and every forbidden PII/secret/database value; sanitized traceback; route template; internal ID not public |
| Lifecycle | Config failure cleanup, DB unavailable startup, pool open/close once, idempotent close, no request-teardown pool close |
| Timezone/clock | Injected wall/monotonic clocks; deadline immune to wall-clock change; fixed DST boundaries without replacing DB authority |

## 24. Flask API-test catalogue

API tests use the built-in client and fake operation gateways; they assert complete JSON equality and headers, not substrings.

| Catalogue | Coverage |
|---|---|
| `AT-API-COMMON-*` | All 404, 405, media, JSON, body, query, size, header, cache, CORS, and unexpected-error behavior |
| `AT-API-OP01-*` | Exact context success and invalid-configuration/temporary mappings; side-effect-free gateway call |
| `AT-API-OP02-*` | Exact query contract; all slots including unavailable; invalid input; DB outcomes; safe no-capacity/table exposure |
| `AT-API-OP03-*` | New customer, exact match, generic mismatch, indeterminate lookup; no mutation call |
| `AT-API-OP04-*` | Subscribe/unsubscribe success; no-customer-no-change; identity conflicts; known temporary and unknown mutation outcomes |
| `AT-API-OP05-*` | Booked, phone notice, exact retry, multi-table confirmation, overlap, unavailable, identity conflicts, invalid DB config, known rollback, unknown booking, post-commit confirmation unavailable |
| `AT-API-OP06-*` | Exact liveness response when DB fake is unavailable; prove no gateway call |
| `AT-API-OP07-*` | Exact ready response; each internal failure category maps to identical generic not-ready body |
| `AT-API-EXAMPLES-*` | Replay all 36 API-02 JSON examples against the corresponding serializer/error schema; parse all independently |

For every route, test exact allowed method, wrong method/`Allow`, unknown near-match path, forbidden body/query, content type, response headers, types, omitted optional properties, and absence of unapproved fields. Route tests explicitly guard against singular/legacy newsletter routes and method alternatives.

## 25. PostgreSQL integration and failure-injection catalogue

| ID family | Required real-DB evidence |
|---|---|
| `IT-DBAPI-FOUND-*` | PostgreSQL 18.3; `pgcrypto`; app role active; exact foundation reads; production routine execute; denied DML/reservation reads/test helpers/DDL/reset |
| `IT-DBAPI-LIFE-*` | Pool unavailable/recovery, lease hygiene, rollback, broken connection discard, repeated factory teardown |
| `IT-DBAPI-OP01-*` | Coherent configured context, alternate approved test configuration, incomplete/invalid foundation detection, no writes |
| `IT-DBAPI-OP02-*` | Weekday/Sunday, full daily schedule, lead/window/party boundaries, DST, empty/partial/fragmented/full capacity, database order |
| `IT-DBAPI-OP03-*` | No customer/exact/mismatch, authoritative preference, no side effects or phone/reservation exposure |
| `IT-DBAPI-OP04-*` | New selected creates, new unselected no create, transitions, same-state repeat, concurrent final commit, preserved identity/phone/reservations |
| `IT-DBAPI-OP05-*` | Single/multi-table, 30-table maximum, stale slot/full slot, same-customer overlap, exact retry, changed overlap, mismatch, phone notice, atomic preference+booking, rollback |
| `IT-DBAPI-RETRY-*` | Controlled `55P03`, `40P01`, `40001`; max attempts; new transaction/lease; deadline; excluded timeout classes |
| `IT-DBAPI-UNKNOWN-*` | Connection loss before dispatch, after dispatch, during commit; OP-04 unknown; OP-05 unknown; unchanged client resubmission/exact reconstruction |
| `IT-DBAPI-CONFIRM-*` | Commit then stored-name read; same clean lease/new transaction; forced post-commit read failure gives known confirmation-unavailable; stored spelling only |
| `IT-DBAPI-CONCUR-*` | Simultaneous conflicting bookings, no over/double booking, same customer, concurrent preference create/update, accepted DB-07 2/5/8-request patterns |

Failure injection is external to production code. It uses controllable fake adapters for unit/API certainty transitions and existing PostgreSQL test-role locks/helpers plus test-process connection termination for integration cases. Production packages contain no failure flag, endpoint, alternate routine name, injected SQL string, or test role credential.

After each integration case, assertions use the external test role to inspect committed PostgreSQL state directly. HTTP success alone is insufficient evidence.

## 26. Performance-measurement plan

API-09 will run performance tests on Windows Server 2025 under standard GIL-enabled CPython 3.14.6 against a clean, local PostgreSQL 18.3 test database with Flask configured as production-like except for the nonproduction database. Environment evidence records Windows edition/build, enabled-GIL proof, exact CPython 3.14.6, PostgreSQL 18.3, CPU, exact direct/transitive dependency versions, pool size, test data volume, warm-up count, and concurrency. Node.js is excluded from Flask performance execution and dependency accounting. PII-free unique tokens identify test records only inside the test database and are not logged by Flask.

### 26.1 Scenarios and samples

- Five warm-up requests per scenario, excluded from statistics.
- Thirty measured sequential requests for OP-01, OP-02 representative available/full dates, OP-03 new/existing, OP-04 idempotent changes, OP-05 single-table, all-table fast path, general equal-capacity, general heterogeneous-capacity, exact retry, conflict, and unavailable outcomes.
- Twenty measured readiness probes in ready and dependency-failure states.
- Twenty coordinated groups each at 2, 5, and 8 conflicting/distinct booking clients, matching the accepted DB-07 contention shapes.
- Separately measure whole HTTP latency, pool wait, database transaction, retry sleep, and OP-05 post-commit name read through sanitized timers.

Report count, successes/errors by public code, min, median/p50, p95, p99, maximum, and group-completion time. Use nearest-rank percentiles with the method stated. Do not mix warm-ups, retries, errors, sequential, and contention samples into one percentile.

Correctness gates first: no duplication, overbooking, partial mutation, privacy leak, or wrong ambiguity flag. The SRS two-second form expectation is then assessed honestly. DB-07's accepted 1.14-1.27-second general allocation and over-two-second contention limitations are preserved as the comparison baseline, not hidden or redefined. Pool-size tuning may be evaluated without exceeding the configured bound, but the restaurant-wide lock and database algorithms cannot change in API work.

## 27. Operation-to-layer matrix

| Op | Exact endpoint | Route module | Validator | Service | Gateway / DB access | Serializer |
|---|---|---|---|---|---|---|
| OP-01 | `GET /api/v1/reservation-context` | `reservation_context.py` | GET/query rules | `reservation_context.py` | `context_gateway.py`: three foundation projections | common/context projection in route + common serializer |
| OP-02 | `GET /api/v1/reservation-availability` | `reservation_availability.py` | `reservation.py` date/party | `reservation_availability.py` | `availability_gateway.py`: same-snapshot timezone projection plus `provisional_availability(date,integer)` | `serialization/reservation.py` slots |
| OP-03 | `POST /api/v1/newsletter-status-queries` | `newsletter_status.py` | `identity.py` | `newsletter_status.py` | `customer_gateway.py`: narrow customer SELECT | common newsletter projection |
| OP-04 | `POST /api/v1/newsletter-preferences` | `newsletter_preferences.py` | `identity.py`, `newsletter.py` | `newsletter_preferences.py` | `newsletter_gateway.py`: `set_newsletter_preference(...)` | common newsletter projection |
| OP-05 | `POST /api/v1/reservations` | `reservations.py` | `identity.py`, `reservation.py`, `newsletter.py` | `reservations.py`, `retry.py` | `reservation_gateway.py`: `book_reservation(...)`, then stored-name SELECT after known commit | `serialization/reservation.py` confirmation |
| OP-06 | `GET /api/v1/health/liveness` | `health.py` | GET/body/query rules | `health.py` | none | exact live body |
| OP-07 | `GET /api/v1/health/readiness` | `health.py` | GET/body/query rules | `health.py` | `health_gateway.py`: fixed read-only contract checks | exact ready body or generic envelope |

This is one-to-one: no operation has multiple public endpoints and no endpoint invokes multiple operations.

## 28. API-02 endpoint, error, and example coverage confirmation

The seven methods/routes above exactly match API-02 version 1.0.1. No route, method, request property, response property, HTTP status, error code, retry flag, unknown-outcome flag, or media representation is revised here.

The public error inventory is exactly the 19 codes in section 17.2: three 400 codes, one 404, one 405, one 415, one 422, four 409 codes, seven 503 codes, and one 500 code. `reservation_unavailable` remains non-retryable; OP-04 and OP-05 unknown outcomes remain distinct; OP-05 known post-commit name-read failure remains `reservation_confirmation_unavailable` with `outcome_unknown:false`.

Read-only Phase 0 independently found 36 fenced JSON examples in API-02 and parsed all 36 successfully. Future API tests parameterize those exact examples; API-03 adds, deletes, or edits none. API-04 must treat API-02 as test input, not copy a divergent schema.

## 29. API-04 through API-09 future file and test ownership

| Increment | First implementation ownership | Tests first owned or completed | Explicit boundary |
|---|---|---|---|
| API-04 foundation/connectivity | `pyproject.toml` with `requires-python = ">=3.14,<3.15"`, `README.md`, package init, `application.py`, `config.py`, `dependencies.py`, HTTP blueprint/parsing/responses/error handlers, health route/service/gateway, DB pool/exceptions, observability modules, shared result/retry scaffolding, and a test-only acceptance-evidence guard | Windows Server 2025 and exact initial standard GIL-enabled CPython 3.14.6 evidence; resolved-family compatibility; config, lifecycle, protocol/common policy, safe errors/logs, connectivity/privileges, transaction wrapper, OP-06/07 | No OS/exact-patch Flask configuration/startup gate; no OP-01 through OP-05 business implementation; no Node.js/npm/React work |
| API-05 identity/status | `validation/common.py`, `validation/identity.py`, `services/newsletter_status.py`, `db/customer_gateway.py`, `http/routes/newsletter_status.py`, needed common serializer | Identity validation/normalization and OP-03 unit/API/DB tests | No preference mutation |
| API-06 preferences | `validation/newsletter.py`, `services/newsletter_preferences.py`, `db/newsletter_gateway.py`, `http/routes/newsletter_preferences.py` | OP-04 idempotency, concurrency, mutation ambiguity, direct-state tests | No availability/booking |
| API-07 slot discovery | `validation/reservation.py` portions for date/party, context/availability routes/services/gateways, slot serializer | OP-01/02 schedule/config/timezone/DST/inventory/full-slot tests | No reservation mutation |
| API-08 reservations | Remaining reservation/identity/phone validation, `services/reservations.py`, `db/reservation_gateway.py`, reservation route/confirmation serializer | OP-05 exact retry, concurrency, atomicity, ambiguity, post-commit confirmation, direct-state tests | No broad hardening claim |
| API-09 verification/gate | No new business capability; only narrowly justified verification support/docs | Complete UT/AT/IT/PT catalogues, contract examples, coverage, timing, redaction, manual evidence on Windows Server 2025 with exact initial standard GIL-enabled CPython 3.14.6, PostgreSQL 18.3, and resolved dependency versions | Hard Gate 2; no React or Node.js dependency decision until explicit approval |

API-04 may adjust file grouping only if responsibilities and dependency direction remain identical and the review records the path mapping. It may not change the approved behavioral decisions silently.

## 30. Requirements and contract traceability

### 30.1 SRS, rubric, and baseline

| Source obligation | API-03 design evidence |
|---|---|
| SRS Flask REST/PostgreSQL interface | One Flask app, exact API-02 HTTP adapter, direct Psycopg access through frozen routines/reads |
| FR-02, FR-06 through FR-09 | OP-01/02/05 layers preserve DB-owned hours, availability, booking, allocation, and confirmation |
| FR-15 through FR-18 | OP-03/04/05 identity/newsletter services preserve `customers` as sole state |
| NFR-02 performance | Numeric pool/deadline/retry policy and API-09 measurement plan without stronger promise |
| NFR-05 data integrity | Explicit transactions, certainty model, no direct DML, exact-retry recovery |
| NFR-06 user-friendly failures | Exhaustive safe API-02 error translation and privacy boundary |
| NFR-09 modular/documented | Focused modules, dependency matrix, ownership/test catalogues |
| Rubric correct Flask/database integration | Real integration tests and direct committed-state assertions |
| Rubric sophisticated reservation logic | Delegated to approved exact DB allocator, exercised at API boundary rather than duplicated |
| Project Requirements Baseline 1.0 | One incremental modular application; no unapproved feature/infrastructure |
| Authoritative implementation platform | Windows Server 2025; standard GIL-enabled CPython 3.14.6 as the installed/initial evidence patch within future metadata `>=3.14,<3.15`; PostgreSQL 18.3; Node.js 24.15.0 recorded only for the later React phase |

### 30.2 PRA-001 through PRA-029

| PRA | Preserved by |
|---:|---|
| PRA-001 | PostgreSQL is authoritative; Flask is an adapter/orchestrator. |
| PRA-002 | API-03 remains design-only; future work follows API-04 through API-09. |
| PRA-003 | Environment configuration, factory, immutable dependencies, proportional modules. |
| PRA-004 | One Flask application and bounded direct PostgreSQL integration. |
| PRA-005 | Pure validation and operation services keep presentation separate from persistence. |
| PRA-006 | OP-01/02 read current recurring database schedule; no hardcoded SRS hours. |
| PRA-007 | Database-generated 30-minute interval remains authoritative. |
| PRA-008 | Database-owned 90-minute duration remains authoritative. |
| PRA-009 | Full legitimate daily start list is preserved and serialized once. |
| PRA-010 | Advance window and same-day lead are validated authoritatively by DB outcomes. |
| PRA-011 | Approved IANA timezone/DST semantics are not recalculated as business truth. |
| PRA-012 | Explicit app deadlines/pool timeouts coexist with frozen 3s lock/15s statement bounds. |
| PRA-013 | Availability is provisional; OP-05 rechecks authoritatively in the booking transaction. |
| PRA-014 | Exact booking routine/lock/`READ COMMITTED` boundary and certainty are preserved. |
| PRA-015 | Party range is read/validated against current authoritative configuration. |
| PRA-016 | Capacity and all-table maximum remain database/inventory derived. |
| PRA-017 | Exact minimum-table/least-waste/random-tie allocation remains database-only. |
| PRA-018 | Same-customer overlap and capacity outcomes map without Flask reimplementation. |
| PRA-019 | Canonical email and structured stored name drive customer identity. |
| PRA-020 | Middle-initial/phone rules have shared pure validation and database outcome tests. |
| PRA-021 | `customers` remains the sole current newsletter state; OP-04 is idempotent. |
| PRA-022 | No cancellation, modification, reschedule, lifecycle, or no-show capability is introduced. |
| PRA-023 | Strict validation, parameter binding, safe errors, privacy, and least privilege. |
| PRA-024 | Mutation atomicity, rollback, bounded retry, unknown-outcome semantics, and direct DB verification. |
| PRA-025 | No profile/ownership claim; status lookup exposes only workflow-minimum state. |
| PRA-026 | Database identifier/constraint/index choices remain untouched. |
| PRA-027 | Client never supplies/sees fingerprint; unchanged retry relies on frozen exact reconstruction. |
| PRA-028 | No transient/derived business state or audit/history source is added. |
| PRA-029 | OP-01/02 consume the PostgreSQL recurring weekly schedule as the single source. |

### 30.3 API-01, API-02, DB-07, and frozen DB contract

| Authority | Proof of preservation |
|---|---|
| API-01 1.0.1 | Sections 15 and 27 give one service/access specification per OP-01 through OP-07. |
| API-02 1.0.1 | Sections 17, 18, 27, and 28 preserve endpoints, statuses, bodies, flags, examples, privacy, and no-store semantics. |
| DB-07 Hard Gate 1 | PostgreSQL 18.3, performance evidence, accepted contention, least privilege, and exact routines are unchanged. |
| Frozen DB contract 1.0 | Only four approved foundation reads and three routine signatures are used; no unauthorized DML/read/test helper is reachable. |

## 31. Privacy and least-privilege assessment

The deployment login is not a database owner or test role. Every pooled session must enter `cafe_fausse_app`, which has schema `USAGE`, `SELECT` only on the four approved foundation tables, and `EXECUTE` only on the three frozen production routines. It has no direct reservation/assignment read, business-table DML, sequence, DDL, reset, controlled-writer, internal-helper, or test-routine access. Readiness positively verifies the expected usable boundary but never attempts forbidden work as a probe.

Flask selects the smallest operation-specific projection. OP-03 cannot retrieve phone/reservations; OP-05's post-commit query retrieves only stored name parts by canonical email. Public responses never add database IDs, table identifiers/capacities, fingerprints, query details, health diagnostics, or unrelated customer data. Logs use an allowlist and deliberately exclude all request values. Database-management credentials and test seams remain outside the production dependency graph.

No derived/transient business data is persisted or cached by Flask. In-memory validated commands, results, and confirmation material are request-scoped and discarded after response/log timing completion.

## 32. Explicit Version 1 exclusions

- Authentication, authorization accounts, profiles, verified identity/email ownership, sessions, and automatic personal-data prefilling.
- Reservation lookup/listing, cancellation, modification, rescheduling, status lifecycle, no-show handling, administration, and table choice.
- Holiday/date-specific exceptions, schedule history, subscriber history/audit events, confirmation email/SMS sending, adjacency/combination modeling, or more than 30 active tables.
- New endpoints, legacy aliases, GraphQL, WebSockets, server-sent events, background jobs, task queues, microservices, event buses, generic plugins, distributed/application caches, or alternate persistence.
- ORM models, Flask migrations, schema create/reset/seed/verify/performance endpoints, startup migrations, or readiness repair.
- Direct Flask DML to business tables, direct reservation/assignment reads, app access to test helpers, Flask-side availability/allocation/overlap/fingerprint logic.
- Public correlation/diagnostic values, database errors, SQLSTATE, fingerprints, capacity/table details, or new error codes.
- Cross-origin API access, production topology, WSGI server selection, reverse proxy, TLS termination, CI/CD, monitoring vendor, and React integration.
- API-04 implementation or any API-05 through API-09 implementation in this increment.

## 33. Compatibility and source-of-truth proof

1. OP-01 through OP-07 map one-to-one to the seven exact endpoints in section 27.
2. API-03 changes no API-02 route, method, request/response field, status, public code, retry/unknown flag, or JSON example.
3. It changes no PostgreSQL table, column, constraint, index, role, grant, routine, signature, outcome/detail, migration, lock, or retry rule. The approved API-07 reconciliation changes only OP-02's caller-managed read-only isolation from `READ COMMITTED` to `REPEATABLE READ` so its timezone projection and routine result share one snapshot.
4. All database paths activate `cafe_fausse_app` and use only four granted foundation reads or three granted production routines.
5. Current configuration, hours, capacities, availability, booking, allocation, overlap, exact retry, and persisted newsletter state stay PostgreSQL-authoritative.
6. OP-05 returns stored customer-name spelling after a known booking/exact retry and never treats submitted spelling as confirmation authority.
7. A failed post-commit name read is a known booking with `reservation_confirmation_unavailable`; an uncertain commit is `reservation_outcome_unknown`.
8. No secret, PII, internal database fact, or second persistent source is added to the public contract or Flask architecture.
9. This increment creates only this Markdown document; no Flask source, test, SQL, manifest, React, or deployment file is created.
10. The selected Flask/Psycopg/pytest families have authoritative Python 3.14 and Windows compatibility evidence; Psycopg is constrained to 3.2.10 or newer within 3.2 because that is where official Python 3.14 support begins.
11. The initial Flask implementation and verification platform is Windows Server 2025 with standard GIL-enabled CPython 3.14.6 and PostgreSQL 18.3. The OS and exact patch are formal evidence facts rather than Flask configuration/startup gates; project metadata remains `>=3.14,<3.15`. Node.js 24.15.0 is only a recorded future-React platform fact and is absent from the Flask dependency/runtime/test/performance graph.

Therefore API-03 is compatible with API-01 1.0.2, API-02 1.0.1, DB-07 Hard Gate 1, and PostgreSQL Contract for Flask 1.0 without revising the public or database contract.

## 34. Unresolved issues and deviations

No dependency-family incompatibility, upstream-contract contradiction, platform mismatch, or API-03 design deviation remains. Official metadata supports the selected dependency families on CPython 3.14 and Windows, with Psycopg's minimum corrected to 3.2.10 within the already selected 3.2 family. Read-only verification found the authoritative standard GIL-enabled CPython 3.14.6 at `C:\Python314\python.exe`; no Python installation, downgrade, upgrade, or environment correction is required.

The accepted database performance limitations remain explicit evidence items for API-09 and full-stack verification. They are not an API-03 deviation and do not authorize a database redesign. Exact dependency patch resolutions and production deployment topology are intentionally assigned to their future implementation/deployment checkpoints; their compatibility families and application-facing decisions are fixed here. Node.js package/frontend compatibility choices remain assigned to the later React phase.

## 35. API-03 completion assessment

| Completion criterion | Assessment |
|---|---|
| Small modular Flask architecture selected | Complete |
| Database-access and transaction ownership explicit | Complete |
| Configuration/environment catalogue complete | Complete |
| Numeric timeout/retry/jitter choices exact | Complete |
| Safe errors, privacy, logging, and health explicit | Complete |
| Clock/randomness/lifecycle test seams explicit | Complete |
| Unit/API/PostgreSQL/concurrency/performance plans complete | Complete |
| Windows Server 2025 / standard GIL-enabled CPython 3.14.6 initial target and `>=3.14,<3.15` metadata policy explicit | Complete |
| Dependency-family compatibility verified from authoritative metadata/documentation | Complete; Psycopg lower bound corrected to 3.2.10 |
| PostgreSQL 18.3 preserved as sole Version 1 target | Complete |
| Node.js 24.15.0 recorded only for future React work | Complete |
| Local exact initial CPython patch conformance | Complete: installed/observed initial evidence patch is 3.14.6 with enabled GIL |
| OS/exact-patch checks separated from Flask configuration/startup | Complete: formal acceptance evidence only; compatible standard GIL-enabled CPython 3.14.x remains the runtime range |
| Seven operations and API-02 contract covered one-to-one | Complete |
| API-04 through API-09 ownership bounded | Complete |
| Upstream database/API contracts preserved | Complete |
| API-04 implementation absent | Complete |

API-03 version 1.0.3 is complete as a reconciled design artifact and is ready for independent review. This documentation reconciliation does not authorize API-07 implementation by itself.

## 36. Version record

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-21 | Initial API-03 Flask architecture, configuration, and test strategy prepared for review. |
| 1.0.1 | 2026-08-21 | Added the implementation-platform and dependency-compatibility correction using the then-supplied Python patch value; tightened Psycopg 3.2 to 3.2.10+, preserved PostgreSQL 18.3, and recorded Node.js 24.15.0 only for future React work. Superseded by 1.0.2 for the corrected Python patch and evidence/startup distinction. |
| 1.0.2 | 2026-08-21 | Corrected the authoritative installed/initial Python patch to standard GIL-enabled CPython 3.14.6; changed the read-only result from mismatch to match; removed the OS/exact-patch Flask configuration/startup gate; retained formal API-04/API-09 evidence checks, `requires-python = ">=3.14,<3.15"`, Psycopg 3.2.10+, PostgreSQL 18.3, and Node.js's future-React-only status. No API/database/transaction/architecture behavior changed. |
| 1.0.3 | 2026-08-23 | Applied the approved `API-07 OP-02 timezone/snapshot reconciliation`: OP-02 now reads only `reservation_configuration.restaurant_timezone` and calls the unchanged provisional-availability routine within one `REPEATABLE READ READ ONLY` snapshot. API-02 and the frozen PostgreSQL contract remain unchanged. |

## 37. Approval checkpoint

**Current checkpoint:** API-03 version 1.0.3 contains the approved API-07 OP-02 timezone/snapshot reconciliation and awaits independent review before revised Prompt 16 is executed.

The original API-03 approval boundary is preserved. Prompt 16A authorizes only this documentation reconciliation; it does not authorize API-07 implementation, API-08/API-09, React, integration, deployment, or PostgreSQL changes.
