# API-04 implementation report

## Increment and status

API-04 - Flask Foundation and PostgreSQL Connectivity is implemented and ready
for human review. It is not approved, and API-05 has not begun.

Phase 0 result: **READY**. The worktree was initially clean at committed Prompt
13 (`ac6fb0e`), `main` matched `origin/main`, no nested `AGENTS.md` applied, and
`backend/` contained no prior work. The exact SRS/rubric PDFs and every required
authority were present and readable. The database tree has no diff from the
DB-07 approval commit.

## Authorities and versions

- Project Requirements Addendum 2.2.1, PRA-001 through PRA-029
- DB-01 1.2.1; DB-02 1.2; DB-03 1.1; DB-04 1.1
- approved DB-05 and DB-06 implementation/evidence
- DB-07 Hard Gate 1, approved 2026-08-20
- PostgreSQL Contract for Flask 1.0, approved and frozen
- API-01 1.0.1; API-02 1.0.1
- API-03 1.0.2, approved 2026-08-21 and authorizing API-04 only
- least-to-most roadmap 1.1.1
- `docs/SRS(1).pdf`, `docs/Rubric(1).pdf`, and Prompt 13

## Environment and resolved dependencies

Formal evidence matched Windows Server 2025 Standard 24H2 build 26100.33158,
64-bit CPython 3.14.6, CPython implementation, and enabled standard GIL.
PostgreSQL client and disposable server were 18.3. The `py` launcher was absent,
so the authoritative interpreter path `C:\Python314\python.exe` was used. This
is a tooling warning, not an application startup gate.

Resolved direct versions: Flask 3.1.3, Psycopg 3.2.13,
`psycopg-binary` 3.2.13, `psycopg-pool` 3.2.8, pytest 9.1.1, and
pytest-cov 7.1.0. Resolved transitives were blinker 1.9.0, click 8.4.2,
colorama 0.4.6, coverage 7.15.4, iniconfig 2.3.0, itsdangerous 2.2.0,
Jinja2 3.1.6, MarkupSafe 3.0.3, packaging 26.3, pluggy 1.6.0,
Pygments 2.21.0, typing-extensions 4.16.0, tzdata 2026.3, and
Werkzeug 3.1.8.

## Files and responsibility mapping

- `pyproject.toml`: Python range, approved dependencies, package layout,
  strict markers, default test selection, and coverage configuration.
- `src/cafe_fausse/application.py`, `config.py`, `dependencies.py`: composition,
  immutable environment catalogue, deterministic seams, and lifecycle.
- `src/cafe_fausse/http/`: one `/api/v1` blueprint, health request parsing,
  exact JSON responses/headers, common error translation, and OP-06/OP-07 routes.
- `src/cafe_fausse/services/`: typed health results and bounded retry scaffolding.
- `src/cafe_fausse/db/`: safe exceptions, bounded pool/session enforcement, and
  one-lease read-only readiness gateway.
- `src/cafe_fausse/observability/`: monotonic timing and allowlist-only text/JSON
  logging with private UUIDv4 request correlation.
- `tests/unit/`, `tests/api/`, `tests/integration/`: API-04 traceable executable
  evidence.
- `README.md`: safe Windows setup, run, configuration, lifecycle, and test guide.
- root `.gitignore`: backend virtual environment and generated artifacts only.

Exact changed paths:

```text
.gitignore
backend/pyproject.toml
backend/README.md
backend/API04_IMPLEMENTATION_REPORT.md
backend/src/cafe_fausse/__init__.py
backend/src/cafe_fausse/application.py
backend/src/cafe_fausse/config.py
backend/src/cafe_fausse/dependencies.py
backend/src/cafe_fausse/http/__init__.py
backend/src/cafe_fausse/http/blueprint.py
backend/src/cafe_fausse/http/parsing.py
backend/src/cafe_fausse/http/responses.py
backend/src/cafe_fausse/http/error_handlers.py
backend/src/cafe_fausse/http/routes/__init__.py
backend/src/cafe_fausse/http/routes/health.py
backend/src/cafe_fausse/services/__init__.py
backend/src/cafe_fausse/services/results.py
backend/src/cafe_fausse/services/retry.py
backend/src/cafe_fausse/services/health.py
backend/src/cafe_fausse/db/__init__.py
backend/src/cafe_fausse/db/pool.py
backend/src/cafe_fausse/db/exceptions.py
backend/src/cafe_fausse/db/health_gateway.py
backend/src/cafe_fausse/observability/__init__.py
backend/src/cafe_fausse/observability/logging.py
backend/src/cafe_fausse/observability/redaction.py
backend/src/cafe_fausse/observability/timing.py
backend/tests/conftest.py
backend/tests/unit/test_config.py
backend/tests/unit/test_logging_and_lifecycle.py
backend/tests/unit/test_pool.py
backend/tests/unit/test_retry.py
backend/tests/api/test_health.py
backend/tests/integration/test_foundation_postgresql.py
```

There are no responsibility-preserving path deviations from API-03. Later
business-operation validation/serialization modules were intentionally not
created.

## Implementation confirmation

The public factory is `create_app(settings=None, dependencies=None)`. Production
construction parses settings once; leaves the exact-patch/OS evidence guard out
of startup; creates one bounded unopened pool; starts it with `wait=False`;
enforces fixed application name and `SET ROLE cafe_fausse_app` on every new
session; verifies the role on leases; installs common HTTP/error/logging policy;
registers only OP-06 and OP-07; and stores immutable dependencies under
`app.extensions["cafe_fausse"]`. Cleanup is explicit, bounded, and idempotent.

All API-03 configuration names, defaults, types, numeric ranges, environment
defaults, production restrictions, TLS constraint, nonproduction test-name
guard, pool/retry cross-field rules, and unknown-name rejection are implemented.
Connection facts and secrets are excluded from representations and errors.

OP-06 is constant and does no I/O. OP-07 uses at most one lease and one explicit
read-only transaction within its default 1,000 ms total deadline. It checks
PostgreSQL 18.3, `pgcrypto`, current app role, all three production routine
execute privileges, four foundation reads, valid singleton configuration,
seven valid hours, and exactly 30 positive-capacity tables. Every internal
failure returns the same generic 503 body.

Every response uses the API-02 JSON content type, no-store/cache headers, and
security headers. There is no CORS, cookie, redirect, ETag, Retry-After, public
correlation value, HTML error, or diagnostic response. Logging emits only
allowlisted fields; sentinel secret/PII tests prove body/value omission.

## Verification evidence

The isolated target was a fresh local PostgreSQL 18.3 database named
`cafe_fausse_test_api04` in a disposable cluster. No password was embedded or
logged. The existing `rebuild.ps1` applied migrations 001-011 and both rebuild
and `verify.ps1` completed successfully before integration tests. After the
final clean-baseline proof, the disposable server was stopped and its temporary
cluster directory removed; it is reproducible from PostgreSQL 18.3 plus the
approved repository tooling.

Principal evidence commands (run from the repository root unless noted):

```powershell
C:\Python314\python.exe -m venv backend\.venv
backend\.venv\Scripts\python.exe -m pip install -e "backend[test]"
database\scripts\rebuild.ps1
database\scripts\verify.ps1
Set-Location backend
python -m pytest -m unit
python -m pytest -m api
python -m pytest -m "integration and postgres"
python -m pytest -m "unit or api or integration" --cov=cafe_fausse --cov-report=term-missing
python -m compileall -q src tests
git diff --check
```

The guarded database commands used explicit local host/port, the approved test
database name, `CAFE_FAUSSE_ENVIRONMENT=test`, and
`CAFE_FAUSSE_ALLOW_RESET=YES`. The integration process used separate
passwordless non-superuser logins for the deployment/app-role boundary and the
external test-management boundary. No connection fact is stored in source.

- Unit: 51 passed.
- Flask API: 10 passed.
- PostgreSQL integration: 7 passed.
- Consolidated coverage: 68 passed; 94% total statement/branch report. No
  unapproved threshold was imposed.
- Static/repository: CPython `compileall` passed; `git diff --check` passed.

Integration evidence includes exact platform/dependency versions, role on a
pooled session, PostgreSQL/extension/routine/foundation readiness, direct DML,
reservation-read, DDL, internal-helper denials, zero customer/reservation/
assignment mutation, controlled missing-hours generic failure with external
test-role restoration, unavailable-database liveness, real server-down/server-up
background recovery, transaction rollback, wrong-role lease discard, and
repeated factory closure. The application role never performed setup or cleanup.

## Warnings, limitations, and exclusions

The Windows `py` launcher was unavailable; direct CPython 3.14.6 execution was
used. The first recovery-test attempt was correctly blocked by sandbox process
permissions; the identical test passed when authorized to control only the
disposable cluster. The accepted DB-07 general-allocation and contention
performance limits remain unchanged and are deferred to API-09/full-stack
measurement. API-04 does not claim performance, concurrency, or complete
seven-operation REST coverage.

No OP-01 through OP-05 route or business behavior, API-05 work, React/Node.js
work, CORS, ORM, authentication, deployment topology, migration, database
object, or production operation was added. Approved migration bytes/order and
all PostgreSQL contract decisions remain unchanged.

## Diff and compatibility assessment

The intended final diff consists only of `.gitignore` plus API-04-owned files
under `backend/`. API-03 1.0.2, API-02 1.0.1, API-01 1.0.1, DB-07 Hard Gate 1,
and PostgreSQL Contract 1.0 remain compatible without revision.

## Approval checkpoint

> API-04 - Flask Foundation and PostgreSQL Connectivity is complete and ready
> for Abdul's review. Completion does not equal approval. API-04 approval is
> required before API-05 may begin.

Approval would authorize only API-05 - Customer Identity and Newsletter-Status
Query. It would not authorize API-06 through API-09, React, integration-phase
work, deployment, or PostgreSQL changes.
