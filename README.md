# Cafe Fausse

Cafe Fausse is a responsive full-stack restaurant web application built with React and JSX, Flask/Python, and PostgreSQL. It provides Home, Menu, Reservations, About Us, and Gallery routes; an accessible Gallery lightbox; newsletter preference signup; and server-authoritative reservation availability and creation. Customer, reservation, table-assignment, and newsletter state is persisted in PostgreSQL.

Version 1 does not include authentication, administration, reservation cancellation, modification, or rescheduling.

## Architecture

```text
Browser / React  ->  Flask REST API  ->  PostgreSQL
     :5173              :5000          configured local instance
```

- **PostgreSQL** owns persistent business data, recurring operating hours, reservation policy, table capacities, integrity and concurrency enforcement, and the controlled availability/allocation operations.
- **Flask** validates and normalizes requests, orchestrates bounded database operations, maps the frozen REST contract to safe responses, and connects through a deployment login that can assume only `cafe_fausse_app`.
- **React** owns presentation and interaction. It calls relative `/api/...` paths and displays server-returned hours, date bounds, policy, slots, and confirmations. It does not calculate authoritative availability or enforce database integrity.

The Vite development server proxies `/api` to Flask when `CAFE_FAUSSE_FLASK_PROXY_TARGET` is set. No CORS layer, ORM, startup migration, authentication, or admin API is part of Version 1.

## Repository layout

| Path | Purpose |
|---|---|
| `database/` | PostgreSQL provisioning, migrations, guarded rebuild/reset, verification, tests, and database contract. |
| `backend/` | Installable Flask package, REST API, and pytest suites. |
| `frontend/` | Vite/React application, Gallery assets, Vitest suites, and guarded live-verification helpers. |
| `docs/` | SRS, rubric, approved designs, prompts, and frozen integration/audit/performance evidence. |
| `README.md` | Project architecture, local setup, execution, and verification guide. |
| [`Cafe_Fausse_Developer_Setup_Manual_Test_and_Demo_Guide.md`](Cafe_Fausse_Developer_Setup_Manual_Test_and_Demo_Guide.md) | Developer-friendly, end-to-end provisioning, startup, manual-testing, and demonstration instructions with expected results and stop conditions. |
| [`ai-tooling.md`](ai-tooling.md) | AI-assisted development disclosure and review controls. |

## Prerequisites and verified environment

The project was developed and verified using the following windows powershell, PostgreSQL, Phyton, Node.js, and Git software and versions listed below:

- Windows PowerShell 5.1 or PowerShell 7+ for the repository's `.ps1` workflows. 
- PostgreSQL **18.3** with `pgcrypto`, plus `psql` and `createdb`. 
- A standard GIL-enabled 64-bit CPython **3.14.x**. `backend/pyproject.toml` requires `>=3.14,<3.15`.
- Node.js **24.15.0 or newer**, as declared by `frontend/package.json`, and npm capable of installing lockfile version 3 with `npm ci`.
- Git for source and review-diff workflows.
- Other versions of the above listed software weren't tested although they may in fact work as designed. 

Prompt-26A recorded the following development/test environment. These exact VM resources and browser patch are evidence, not new minimum requirements.

| Item | Recorded value |
|---|---|
| Operating system | Windows Server 2025 |
| VM resources | 8 logical processors, 8.00 GiB RAM |
| PostgreSQL | 18.3 |
| Python / Flask | 3.14.6 / 3.1.3 |
| Node.js / npm | 24.15.0 / 12.0.2 |
| React / Vite | 19.2.8 / 8.2.2 |
| Chrome | 151.0.7922.170 |

The backend manifest permits Flask `>=3.1,<3.2`, Psycopg `>=3.2.10,<3.3`, and psycopg-pool `>=3.2.8,<3.3`; the frontend manifest pins its direct dependencies exactly. Use the committed manifests and lockfile instead of substituting versions.

## Install dependencies

Run from the repository root in PowerShell.

### Flask/Python

```powershell
py -3.14 -m venv backend\.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -e "backend[test]"
```

If the Windows Python launcher is unavailable and Python 3.14 is installed at the verified project location, the documented replacement for the first command is:

```powershell
C:\Python314\python.exe -m venv backend\.venv
```

The `[test]` extra installs pytest and coverage tooling in addition to the application dependencies.

### React/Node

```powershell
Set-Location frontend
npm ci
Set-Location ..
```

`npm ci` installs exactly from `frontend/package-lock.json`; do not use `npm update` as a setup or recovery step.

### PostgreSQL

Install and start PostgreSQL 18.3 separately. Ensure `pgcrypto` can be created by the administrator used for initialization. The repository intentionally does not install or manage a general-purpose PostgreSQL server.

In every new PowerShell session that will use PostgreSQL command-line tools, add the PostgreSQL 18 `bin` directory to that session's `PATH`:

```powershell
$PostgreSqlBin = 'C:\Program Files\PostgreSQL\18\bin'
if (-not (Test-Path -LiteralPath $PostgreSqlBin)) {
    throw "PostgreSQL 18 bin directory not found: $PostgreSqlBin"
}
if (($env:PATH -split ';') -notcontains $PostgreSqlBin) {
    $env:PATH += ";$PostgreSqlBin"
}
```

This is session-local and must be repeated in newly opened terminals that need `psql`, `createdb`, or `pg_isready`. Use the actual PostgreSQL installation path if it differs. Setting `CAFE_FAUSSE_PSQL` helps repository database scripts locate `psql`, but does not make `createdb` or `pg_isready` available.

## Initialize a local PostgreSQL database

Use only an isolated nonproduction database. The core scripts require an explicit name beginning with `cafe_fausse_dev`, `cafe_fausse_test`, or `cafe_fausse_demo` and verify the actual connected database before resetting the fixed `cafe_fausse` schema.

1. Create an empty local database as a PostgreSQL administrator:

   ```powershell
   createdb cafe_fausse_dev
   ```

2. Set the database-script environment in the same PowerShell session. Replace the role placeholder; keep passwords in the shell or a protected PostgreSQL password file, never in the repository.

   ```powershell
   $env:PGHOST = 'localhost'
   $env:PGPORT = '5432'
   $env:PGDATABASE = 'cafe_fausse_dev'
   $env:PGUSER = 'your_local_postgres_administrator'
   $env:CAFE_FAUSSE_ENVIRONMENT = 'development'
   $env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
   ```

3. From the repository root, run the guarded rebuild:

   ```powershell
   pwsh -File database/scripts/rebuild.ps1
   ```

   On Windows PowerShell 5.1, use `powershell` instead of `pwsh`.

The rebuild provisions the passwordless group roles, drops only the guarded `cafe_fausse` schema, applies migrations `001` through `011` in lexical order, seeds the approved baseline, and runs the DB-05/DB-06/DB-07 verifiers. It performs no Flask startup migration.

Create a separate non-superuser deployment login outside Flask. The following is the local-development form of the role setup used by the committed backend runbook; run it once in an administrator `psql` session connected to `cafe_fausse_dev`:

```sql
CREATE ROLE cafe_fausse_local_app
    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    NOBYPASSRLS NOINHERIT;
GRANT cafe_fausse_app TO cafe_fausse_local_app;
GRANT CONNECT ON DATABASE cafe_fausse_dev TO cafe_fausse_local_app;
\password cafe_fausse_local_app
```

The final command prompts securely for the password. The complete guarded example and role-boundary audit are in [`backend/TestInstructions.md`](backend/TestInstructions.md), Section 6. Do not use the schema owner or test role as the Flask login, and do not place a password in SQL, documentation, or a command-line argument.

For a read-only check of an initialized database:

```powershell
pwsh -File database/scripts/verify.ps1
```

### Database reset safety

`rebuild.ps1` is intentionally destructive only to the fixed `cafe_fausse` schema in the explicitly named nonproduction database. It requires `CAFE_FAUSSE_ENVIRONMENT` to be `development`, `test`, or `demo`, `CAFE_FAUSSE_ALLOW_RESET` to equal `YES`, and the connected database name to match `PGDATABASE` and the approved naming pattern. Never point it at production or production-like data.

## Configurable restaurant settings

Business settings are stored in PostgreSQL rather than duplicated in React or Flask environment variables.

| PostgreSQL setting/data | Initial value | Permitted value or invariant |
|---|---:|---|
| `reservation_configuration.start_interval_minutes` | 30 | `15`, `30`, or `60` minutes |
| `reservation_configuration.reservation_duration_minutes` | 90 | `60`, `90`, or `120` minutes |
| `reservation_configuration.advance_booking_window_days` | 60 | 1-365 days, inclusive from the restaurant-local current date |
| `reservation_configuration.same_day_lead_minutes` | 120 | 0-1440 minutes |
| `reservation_configuration.restaurant_timezone` | `America/New_York` | Trimmed IANA timezone recognized by PostgreSQL |
| `restaurant_operating_hours` | Monday-Saturday 17:00-23:00; Sunday 17:00-21:00 | One valid opening/closing row for each ISO weekday 1-7; opening precedes closing |
| `restaurant_tables.seating_capacity` | 4 for each table | Positive integer capacity; Version 1 retains exactly table numbers 1-30 |

The singleton reservation configuration, weekly hours, and 30 per-table capacities are privileged operational data. They are not customer-facing controls. The supported rebuild restores the initial values. Changes apply prospectively and do not rewrite existing reservations.

Availability and permitted reservation starts are derived from the current server-authoritative settings, database clock, current table inventory, and existing reservations. The latest start is derived from closing time and configured duration; it is not a separate setting. React only renders the context and slots returned through Flask.

## Configure and start Flask

Required application variables are `CAFE_FAUSSE_ENVIRONMENT`, `PGHOST`, `PGDATABASE`, and `PGUSER`. `PGPORT` defaults to `5432`. Use the app-only deployment login created above.

```powershell
Remove-Item Env:CAFE_FAUSSE_ALLOW_RESET -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_PSQL -ErrorAction SilentlyContinue
$env:CAFE_FAUSSE_ENVIRONMENT = 'development'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = '5432'
$env:PGDATABASE = 'cafe_fausse_dev'
$env:PGUSER = 'cafe_fausse_local_app'

Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
$CafeAppPassword = Read-Host 'Password for cafe_fausse_local_app' -AsSecureString
$env:PGPASSWORD = [System.Net.NetworkCredential]::new(
    '', $CafeAppPassword
).Password
$CafeAppPassword.Dispose()
Remove-Variable CafeAppPassword

if ([string]::IsNullOrEmpty($env:PGPASSWORD)) {
    throw 'PGPASSWORD is missing; Flask cannot authenticate to PostgreSQL.'
}
'PGPASSWORD is set for the Flask process.'

backend\.venv\Scripts\Activate.ps1
Set-Location backend
python -m flask --app cafe_fausse run
```

The Flask development server normally listens at `http://127.0.0.1:5000`. It opens a bounded Psycopg pool, assumes `cafe_fausse_app` on each connection, and performs no schema or data changes at startup.

Health endpoints are:

- `GET /api/v1/health/liveness` - process-only response `{"status":"live"}`;
- `GET /api/v1/health/readiness` - bounded read-only PostgreSQL/app-role probe returning ready or a generic not-ready response.

Before using the browser, verify direct readiness from another PowerShell terminal:

```powershell
curl.exe -i http://127.0.0.1:5000/api/v1/health/readiness
```

Continue only when the response is `HTTP/1.1 200 OK` with `{"status":"ready"}`. A `503 SERVICE UNAVAILABLE` means Flask is running but its database connection pool is not ready; verify the Flask terminal's database variables and that exactly one valid credential source`PGPASSWORD` or `PGPASSFILE`was supplied to the Flask process.

Supported application settings and defaults are:

| Variable | Default / constraint |
|---|---|
| `CAFE_FAUSSE_DEBUG` | `false`; `true` only in development |
| `PGPORT` | `5432`; 1-65535 |
| `PGPASSWORD` / `PGPASSFILE` | Optional alternatives; configure at most one |
| `PGSSLMODE` | libpq default; production network use cannot set `disable` |
| `PGCONNECT_TIMEOUT` | 3 seconds; 1-10 |
| `CAFE_FAUSSE_POOL_MIN_SIZE` / `CAFE_FAUSSE_POOL_MAX_SIZE` | 1 / 5; ranges 0-5 / 1-20; minimum cannot exceed maximum |
| `CAFE_FAUSSE_POOL_ACQUIRE_TIMEOUT_MS` | 500; 50-3000 |
| `CAFE_FAUSSE_READ_DEADLINE_MS` | 2000; 250-5000 |
| `CAFE_FAUSSE_MUTATION_DEADLINE_MS` | 15000; 3000-15000 |
| `CAFE_FAUSSE_READINESS_DEADLINE_MS` | 1000; 100-3000 |
| `CAFE_FAUSSE_MAX_DB_ATTEMPTS` | 3; 1-3, and exactly 3 in production |
| `CAFE_FAUSSE_RETRY_BASE_DELAY_MS` / `CAFE_FAUSSE_RETRY_CAP_DELAY_MS` | 25 / 200; base cannot exceed cap |
| `CAFE_FAUSSE_RETRY_JITTER_RATIO` | 0.25; 0.0-0.5 |
| `CAFE_FAUSSE_RETRY_MIN_REMAINING_MS` | 500; 100-2000 |
| `CAFE_FAUSSE_MAX_REQUEST_BYTES` | 16384; 4096-65536 |
| `CAFE_FAUSSE_LOG_LEVEL` | `DEBUG` in development, otherwise `INFO`; production forbids `DEBUG` |
| `CAFE_FAUSSE_LOG_FORMAT` | `json` in production, otherwise `text`; production requires JSON |
| `CAFE_FAUSSE_POOL_CLOSE_TIMEOUT_MS` | 1000; 100-5000 |

Names and Boolean/enum values are case-sensitive. Unknown `CAFE_FAUSSE_*` variables fail startup. `CAFE_FAUSSE_ALLOW_RESET` and `CAFE_FAUSSE_PSQL` belong to the database scripts, not Flask; clear them before application startup as shown above.

## Configure and start React

In a second PowerShell terminal, after `npm ci`:

```powershell
$env:CAFE_FAUSSE_FLASK_PROXY_TARGET = 'http://127.0.0.1:5000'
Set-Location frontend
npm run dev
```

Open the Vite URL reported in the terminal, normally `http://localhost:5173/`. The proxy target must be an HTTP(S) origin with no path, query, or fragment. `CAFE_FAUSSE_VITE_CACHE_DIR` is an optional Vite cache-directory override used by owned verification workflows; ordinary development does not need it.

Other committed frontend commands are:

```powershell
npm run build
npm run preview
```

Vite preview normally listens at `http://localhost:4173/` and is useful for inspecting the production static build. The committed `/api` proxy belongs to the development server, not preview, so use the development path above for the local full stack. For guarded start/status/stop behavior on exact loopback ports `5173` and `4173`, use `frontend/scripts/owned-vite-process.ps1` as documented in [`frontend/TestInstructions.md`](frontend/TestInstructions.md).

## Recommended local run sequence

1. Start PostgreSQL 18.3 and initialize `cafe_fausse_dev` with the guarded rebuild.
2. In terminal 1, set the Flask/libpq environment and run Flask from `backend/`.
3. In terminal 2, set `CAFE_FAUSSE_FLASK_PROXY_TARGET`, run Vite from `frontend/`, and open the reported Vite URL.
4. Confirm readiness through `http://localhost:5173/api/v1/health/readiness`, then use the application through Vite so browser `/api` calls are proxied to Flask.

The owned live-integration helper is verification tooling, not the ordinary developer database. It creates a disposable PostgreSQL cluster and owned Flask/Vite processes on ports `55435`, `55004`, and `5173`. Run it only after independently confirming the selected environment is nonproduction and supplying its exact authorization value; follow [`frontend/TestInstructions.md`](frontend/TestInstructions.md), Sections 17-20, including final cleanup.

## Automated and manual testing

Testing follows the dependency order:

```text
unit/component -> PostgreSQL/API integration -> React integration
-> full-stack verification -> performance verification
```

The authoritative repeatable/restartable instructions are:

- [`database/TestInstructions.md`](database/TestInstructions.md)
- [`backend/TestInstructions.md`](backend/TestInstructions.md)
- [`frontend/TestInstructions.md`](frontend/TestInstructions.md)

Principal commands, all run from the repository root unless noted:

### PostgreSQL complete guarded gate

```powershell
$CafeNonProductionAuthorization = 'AUTHORIZED_NONPRODUCTION' # Set only after independent confirmation.
& .\database\scripts\programmer_test.ps1 `
    -NonProductionClusterAuthorization $CafeNonProductionAuthorization
```

The harness creates and removes a uniquely named, ownership-tagged test database and role resources. Localhost and a PostgreSQL version do not prove nonproduction status. Never supply the authorization value without independently confirming the cluster.

### Flask/API

Fast tests that do not require PostgreSQL:

```powershell
Set-Location backend
python -m pytest
python -m pytest -m unit
python -m pytest -m api
Set-Location ..
```

Complete API-09 guarded verification:

```powershell
& .\backend\tests\run_api09.ps1 `
    -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

### React

```powershell
Set-Location frontend
npm run test:integration
npm run test:reservations
npm run test:newsletter
npm run test:mocked-flows
npm test
npm run coverage
npm run build
npm audit --audit-level=low
Set-Location ..
```

The committed Prompt-25 evidence records that the standalone complete PostgreSQL programmer gate passed. In the API-09 PostgreSQL selection, 61 of 62 tests passed; the sole result was the accepted unchanged baseline test `test_free_partial_full_and_back_to_back_occupancy_are_provisional_and_nonmutating_after_cleanup`, with `StopIteration` while locating `full_start_text`. Do not report this historical baseline as a generic all tests pass result. See the frozen [Prompt-25 full-integration report](docs/integration-verification/Cafe_Fausse_Prompt25_Full_Integration_Verification.md) for the exact disposition and cleanup evidence.

Manual route, keyboard, responsive, lightbox, form, browser, and cleanup checks are detailed in the frontend instructions. Use fictional test identities and disposable nonproduction data.

## Recorded performance verification

Prompt-26A recorded one sequential browser user on the actual unthrottled demonstration/verification VM:

- **NFR-1 PASS:** all 25 page-load samples were at or below 3 seconds; worst sample **782.601 ms**.
- **NFR-2 newsletter PASS:** all 10 submissions were at or below 2 seconds; worst sample **81.925 ms**.
- **NFR-2 reservation PASS:** all 10 submissions were at or below 2 seconds; worst sample **462.336 ms**.
- **VM conclusion:** no VM scaling indicated.

These are recorded results under the disclosed protocol, not universal performance guarantees. Full methodology, samples, resource observations, and cleanup are in the [Prompt-26A performance report](docs/performance-verification/Cafe_Fausse_NFR01_NFR02_Performance_Verification.md).

## Responsive and browser status

Committed automated and manual evidence covers responsive desktop, tablet, and mobile layouts. Current compatibility status is:

- Chrome: **PASS**
- Edge: **PASS**
- Firefox: **PASS - manual**
- Safari: **PASS - manual**

Firefox and Safari were manually verified outside the Codex Windows environment, and the results were explicitly approved by the user. Exact Firefox/Safari browser and operating-system versions were not supplied in the retained project evidence. With the existing Chrome and Edge evidence, SRS NFR-7 is **satisfied and closed**. See the [NFR-7 manual browser verification record](docs/browser-verification/Cafe_Fausse_NFR07_Manual_Browser_Verification.md).

## Local deployment status

The current demonstration path is local/localhost. No staging server is claimed or configured, and no `staging.md` is required for the current repository. 

## Gallery assets and provenance

The original four project-supplied image inputs are assignment-provided assets. The additional committed `frontend/assets/gallery/gallery-behind-the-scenes.webp` image was AI-generated during the Cafe Fausse project. No external photographer, URL, license name, or royalty-free claim is asserted for the supplied inputs because the repository contains no such provenance record.

## Useful documentation

- [Software Requirements Specification](docs/SRS(1).pdf)
- [Project rubric](docs/Rubric(1).pdf)
- [Project Requirements Addendum](docs/approved-design-artifacts/Cafe_Fausse_Project_Requirements_Addendum.md) controlling record for approved supplemental decisions PRA-001 through PRA-029.
- [Approved Supplemental Decisions Report](Cafe_Fausse_Approved_Supplemental_Decisions_Report.md) consolidated informational summary; the Project Requirements Addendum remains controlling.
- [PostgreSQL Contract for Flask](database/POSTGRESQL_CONTRACT_FOR_FLASK.md)
- [Prompt-25 full-integration verification](docs/integration-verification/Cafe_Fausse_Prompt25_Full_Integration_Verification.md)
- [Prompt-26 requirements/rubric traceability audit](docs/requirements-audit/Cafe_Fausse_Prompt26_Requirements_Rubric_Traceability_Audit.md)
- [Prompt-26A performance verification](docs/performance-verification/Cafe_Fausse_NFR01_NFR02_Performance_Verification.md)
- [NFR-7 manual browser verification](docs/browser-verification/Cafe_Fausse_NFR07_Manual_Browser_Verification.md)
