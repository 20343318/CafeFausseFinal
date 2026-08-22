# Cafe Fausse Flask backend through API-04

This directory contains only API-04: the Flask application foundation, direct
Psycopg connectivity, common JSON/error/logging policy, and OP-06/OP-07 health
operations. PostgreSQL remains the business authority. There is no ORM, CORS,
session/cookie feature, startup migration, React code, or production-server
selection here.

## Supported and initially verified platform

- Windows Server 2025 Standard 24H2, build 26100.33158
- standard GIL-enabled 64-bit CPython 3.14.x; initially verified patch 3.14.6
- PostgreSQL 18.3 only
- project metadata: `requires-python = ">=3.14,<3.15"`

The OS and exact 3.14.6 patch are formal acceptance evidence, not normal
application startup gates. Node.js is not used by this increment.

## Local environment

From the repository root in PowerShell:

```powershell
py -3.14 -m venv backend\.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -e "backend[test]"
```

If the Windows Python launcher is unavailable but the approved interpreter is
installed at its verified location, use:

```powershell
C:\Python314\python.exe -m venv backend\.venv
```

Set configuration in the current shell or a protected external secret source.
Do not commit a password, passfile, DSN, or environment dump. The application
uses standard libpq variables directly:

```powershell
$env:CAFE_FAUSSE_ENVIRONMENT = 'development'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = '5432'
$env:PGDATABASE = 'cafe_fausse_dev'
$env:PGUSER = 'your_deployment_login'
```

The deployment login must be provisioned outside Flask as a member able to
`SET ROLE cafe_fausse_app`. Use either `PGPASSWORD` or `PGPASSFILE`, never both.
Production network connections may not set `PGSSLMODE=disable`.

## Configuration catalogue

Required: `CAFE_FAUSSE_ENVIRONMENT`, `PGHOST`, `PGDATABASE`, and `PGUSER`.
Supported application variables and defaults are:

| Variable | Default / constraint |
|---|---|
| `CAFE_FAUSSE_DEBUG` | `false`; `true` only in development |
| `PGPORT` | `5432`; 1-65535 |
| `PGPASSWORD` / `PGPASSFILE` | optional alternatives |
| `PGSSLMODE` | libpq default; production network use cannot disable TLS |
| `PGCONNECT_TIMEOUT` | 3 seconds; 1-10 |
| `CAFE_FAUSSE_POOL_MIN_SIZE` / `MAX_SIZE` | 1 / 5; ranges 0-5 / 1-20; min <= max |
| `CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS` | 500; 50-3000 |
| `CAFE_FAUSSE_READ_DEADLINE_MS` | 2000; 250-5000 |
| `CAFE_FAUSSE_MUTATION_DEADLINE_MS` | 15000; 3000-15000 |
| `CAFE_FAUSSE_READINESS_DEADLINE_MS` | 1000; 100-3000 |
| `CAFE_FAUSSE_MAX_DB_ATTEMPTS` | 3; 1-3 and exactly 3 in production |
| `CAFE_FAUSSE_RETRY_BASE_DELAY_MS` / `CAP_DELAY_MS` | 25 / 200; base <= cap |
| `CAFE_FAUSSE_RETRY_JITTER_RATIO` | 0.25; 0.0-0.5 |
| `CAFE_FAUSSE_RETRY_MIN_REMAINING_MS` | 500; 100-2000 |
| `CAFE_FAUSSE_MAX_REQUEST_BYTES` | 16384; 4096-65536 |
| `CAFE_FAUSSE_LOG_LEVEL` | development `DEBUG`, otherwise `INFO`; production forbids `DEBUG` |
| `CAFE_FAUSSE_LOG_FORMAT` | production `json`, otherwise `text`; production requires JSON |
| `CAFE_FAUSSE_POOL_CLOSE_TIMEOUT_MS` | 1000; 100-5000 |

Variable names and enum/Boolean values are case-sensitive. Unknown
`CAFE_FAUSSE_*` names fail startup. Test operation requires a database named
`cafe_fausse_test_*`. `CAFE_FAUSSE_ALLOW_RESET` belongs only to the existing
database scripts and is not a Flask setting.

## Local development server

After setting the environment and activating the virtual environment:

```powershell
python -m flask --app cafe_fausse run
```

This uses Flask's development server for local verification only. Normal
startup opens the bounded pool in background mode, performs no schema or data
changes, and remains live if PostgreSQL is temporarily unavailable.

## Health and lifecycle

- `GET /api/v1/health/liveness` returns `{"status":"live"}` without database,
  filesystem, or network work.
- `GET /api/v1/health/readiness` performs one bounded read-only app-role probe.
  It returns `{"status":"ready"}` or one generic `service_not_ready` response.
- Call `cafe_fausse.close_resources(app)` from the process shutdown hook and
  test fixture. It is idempotent. Request teardown never closes the process pool.

A not-ready result should be diagnosed through protected server operations:
confirm PostgreSQL 18.3, the deployment login's role membership, `pgcrypto`,
the approved rebuild/verification state, and connection availability. The API
intentionally exposes none of those details and never repairs them.

## Tests

Unit and Flask API tests (the default local selection):

```powershell
Set-Location backend
python -m pytest
python -m pytest -m unit
python -m pytest -m api
```

For PostgreSQL integration tests, first use the existing guarded database
scripts against an isolated `cafe_fausse_test_*` PostgreSQL 18.3 target. The
local test harness needs only the cluster administrator and one app-only
deployment login. The administrator also performs external fixture management
through `cafe_fausse_test`; Flask continues to use only the deployment login
through `cafe_fausse_app`. Follow [TestInstruction.md](TestInstruction.md) for
the repeatable setup, secure interactive-password option, and optional passfile
option. Then:

```powershell
$env:CAFE_FAUSSE_PSQL = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
$env:CAFE_FAUSSE_TEST_PGDATA = 'C:\path\to\the\disposable\cluster\data'
$env:CAFE_FAUSSE_TEST_MANAGER_USER = 'your_cluster_administrator'
database\scripts\rebuild.ps1
database\scripts\verify.ps1
Set-Location backend
python -m pytest -m "integration and postgres"
python -m pytest -m "unit or api or integration" --cov=cafe_fausse --cov-report=term-missing
```

The reset variables are for the external guarded scripts only. Do not leave
them in the Flask process environment; configuration intentionally rejects
unknown application-prefixed variables. Never point these commands at
production or production-like data. `CAFE_FAUSSE_TEST_PGDATA` is consumed only
by the formal failure-injection test, which validates that the resolved path is
under the system temporary directory before stopping/restarting the test server.
The integration process may use one protected `PGPASSFILE` containing both
login entries. Without a passfile, keep the app password in `PGPASSWORD` and
the administrator/test-management password in the test-only
`CAFE_FAUSSE_TEST_MANAGER_PASSWORD` variable; the guide populates both through
non-echoing PowerShell prompts and clears them during cleanup.
