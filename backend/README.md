# Cafe Fausse Flask backend through API-06

This directory contains the API-04 Flask/PostgreSQL foundation, API-05's
read-only OP-03 customer identity/newsletter-status query, and API-06's OP-04
independent newsletter-preference mutation. PostgreSQL remains the business
authority. There is no reservation API, ORM, CORS, session/cookie feature,
startup migration, React code, or production-server selection here.

API-01 through API-05 were approved before API-06 work began. API-06 is the
current unapproved review increment until it receives explicit acceptance.
API-07 and later increments are not authorized and have not been started.

## Supported and initially verified platform

- Windows Server 2025 Standard 24H2, build 26100.33158
- standard GIL-enabled 64-bit CPython 3.14.x; initially verified patch 3.14.6
- PostgreSQL 18.3 only
- project metadata: `requires-python = ">=3.14,<3.15"`

The OS and exact 3.14.6 patch are formal acceptance evidence, not normal
application startup gates. Node.js is not used by this increment.

## Local environment

Required working directory: the repository root. Run this block in PowerShell:

```powershell
py -3.14 -m venv backend\.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -e "backend[test]"
```

If the Windows Python launcher is unavailable but the approved interpreter is
installed at its verified location, run this replacement command from the
repository root:

```powershell
C:\Python314\python.exe -m venv backend\.venv
```

Working directory: these process-environment assignments may be made from any
directory in the same PowerShell session. Set configuration in the current
shell or a protected external secret source.
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

Required starting directory: the repository root. After setting the
environment and activating the virtual environment, run:

```powershell
Set-Location backend
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

## Newsletter-status query (OP-03)

`POST /api/v1/newsletter-status-queries` accepts only `first_name`, optional
`middle_initial`, `last_name`, `email`, and `confirmation_email` in a UTF-8
JSON object. It performs one bounded read-only customer projection and never
creates or changes a customer, newsletter preference, or reservation.

Example request for a fictitious identity:

```json
{"first_name":"Ada","middle_initial":"m.","last_name":"Rivera","email":"ADA.RIVERA@EXAMPLE.COM","confirmation_email":"ada.rivera@example.com"}
```

The exact success variants are:

```json
{"status":"not_found"}
```

```json
{"status":"matched","subscribed":true}
```

An identity mismatch is a generic `409 customer_identity_conflict`; a field
failure is `422 validation_failed` with ordered safe field entries. When the
read outcome cannot be established, the endpoint returns
`503 newsletter_status_indeterminate` with `retryable:true` and
`outcome_unknown:false`. None of these responses exposes stored identity,
contact, customer-ID, SQL, or database details.

## Independent newsletter-preference management (OP-04)

`POST /api/v1/newsletter-preferences` accepts only `first_name`, optional
`middle_initial`, `last_name`, `email`, `confirmation_email`, and a JSON
Boolean `subscribed`. Names and email use the same normalization and
confirmation rules as OP-03. The endpoint calls the approved controlled
PostgreSQL routine through the application role; it never performs direct
customer DML.

Fictitious new subscribe request and exact response:

```json
{"first_name":"Ada","middle_initial":"m.","last_name":"Rivera","email":"ADA.RIVERA@EXAMPLE.COM","confirmation_email":"ada.rivera@example.com","subscribed":true}
```

```json
{"result":"set","subscribed":true}
```

A new unsubscribe request does not create a customer:

```json
{"first_name":"Noah","last_name":"Chen","email":"noah.chen@example.com","confirmation_email":"noah.chen@example.com","subscribed":false}
```

```json
{"result":"no_customer_no_change","subscribed":false}
```

For an existing matched identity, subscribe, unsubscribe, and repeated
same-state requests return `{"result":"set","subscribed":true}` or
`{"result":"set","subscribed":false}`. Repeating the identical request is
idempotent. An identity mismatch returns the generic exact conflict envelope:

```json
{"error":{"code":"customer_identity_conflict","message":"The submitted identity details do not match.","retryable":false,"outcome_unknown":false}}
```

A field error returns `422 validation_failed` with ordered safe field entries;
for example, a non-Boolean `subscribed` value produces:

```json
{"error":{"code":"validation_failed","message":"One or more fields need attention.","retryable":false,"outcome_unknown":false,"fields":[{"field":"subscribed","code":"invalid_type","message":"This field must be a Boolean."}]}}
```

A conclusively known non-commit returns `503 temporary_failure` with
`retryable:true` and `outcome_unknown:false`. If commit status cannot be
established, the exact response is:

```json
{"error":{"code":"newsletter_preference_outcome_unknown","message":"The newsletter preference result could not be confirmed. Resubmit the same preference.","retryable":true,"outcome_unknown":true}}
```

For that outcome-unknown response, resubmit the identical request. Do not
infer the prior outcome or change the requested Boolean before resubmission.

## Tests

The recommended complete API-06 workflow is self-contained and removes its
marked disposable PostgreSQL cluster, roles, database, and every generated
Python artifact in `%TEMP%\CafeFausse-api06-tests\artifacts`. Its virtual
environment, pytest cache, coverage file, bytecode, and pip cache never use
repository paths. A developer's existing `backend\.venv`, caches, coverage,
bytecode, and package metadata are preserved exactly. Ownership requires both
the exact task-root path and its exact API-06 port/database marker; a missing or
mismatched marker causes refusal without deletion. Independent finalization
phases attempt PostgreSQL/process cleanup, artifact cleanup, cluster-root
cleanup, and exact environment restoration even when an earlier phase fails:

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse
& .\backend\tests\run_api06.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Codex confirmed that it generated `backend\.api06-correction-compile` during
API-06 compilation. After exact canonical-path and reparse-point verification,
only that Codex-owned directory was removed and its absence was verified.
API-06 nevertheless remains at the unapproved independent-review checkpoint.

See [TestInstructions.md](TestInstructions.md) for prerequisites, focused
commands, ordinary and cleanup failure injection, interruption recovery,
ownership-marker refusal rules, sentinel-preservation evidence, and cleanup
verification. That runbook is programmer-convenience documentation, not an
SRS, rubric, contract, or approved-design authority.

Required starting directory: the repository root. Run unit and Flask API tests
(the default local selection) with:

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
through `cafe_fausse_app`. Follow [TestInstructions.md](TestInstructions.md) for
the repeatable setup, secure interactive-password option, and optional passfile
option. The guide is the preferred convenience workflow. For the condensed
commands below, the required starting directory is the repository root:

```powershell
$env:CAFE_FAUSSE_PSQL = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
$env:CAFE_FAUSSE_TEST_PGDATA = 'C:\path\to\the\disposable\cluster\data'
$env:CAFE_FAUSSE_TEST_MANAGER_USER = 'your_cluster_administrator'
& .\database\scripts\rebuild.ps1
& .\database\scripts\verify.ps1
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
non-echoing PowerShell prompts and restores their prior values or absence
during cleanup.
