# Cafe Fausse Developer Setup, Manual Test, and Demo Guide

## Purpose

This guide gives a developer one practical path for provisioning and running Cafe Fausse locally on Windows for manual testing, rehearsal, and demonstration. It consolidates the ordinary setup sequence so developers do not have to search through every Markdown file.

The application runs as three layers:

```text
Browser / React (normally :5173)
        -> Flask REST API (normally :5000)
        -> PostgreSQL 18.3 (normally :5432)
```

This is a convenience guide. It does not replace the SRS, Rubric, Project Requirements Addendum, frozen API/database contracts, or guarded test instructions.

## 1. Important safety rules

- Use only a local, disposable, nonproduction database.
- This guide uses `cafe_fausse_dev`. The database scripts accept only names beginning with `cafe_fausse_dev`, `cafe_fausse_test`, or `cafe_fausse_demo`.
- Never point `rebuild.ps1` at production or production-like data.
- `rebuild.ps1` drops and recreates the fixed `cafe_fausse` schema. It deletes Cafe Fausse data in the selected database.
- Do not put passwords, passfiles, connection strings, `.env` files, or environment-variable dumps in Git.
- Use the PostgreSQL administrator only for provisioning, rebuilds, and controlled evidence work. Flask must use the separate app-only login.
- Do not manually edit individual rows to prepare or repair a demo. Use the approved guarded preparation/reset workflow.
- Use fictional names, emails, and phone numbers for tests and demonstrations.

## 2. Supported local environment

The committed project expects:

- Windows PowerShell 5.1 or PowerShell 7+
- PostgreSQL 18.3 with `pgcrypto`, `psql`, and `createdb`
- 64-bit CPython 3.14.x
- Node.js 24.15.0 or newer
- npm with support for lockfile version 3
- Git

Other operating systems and PostgreSQL versions are outside the verified project contract.

Run these checks in PowerShell:

```powershell
git --version
psql --version
createdb --version
py -3.14 --version
node --version
npm --version
pwsh --version
```

Expected important results:

- PostgreSQL reports 18.3.
- Python reports 3.14.x.
- Node reports 24.15.0 or newer.

If `pwsh` is unavailable but Windows PowerShell 5.1 is installed, use `powershell` wherever this guide shows `pwsh`.

If PostgreSQL is installed but `psql` is not on `PATH`, either add the PostgreSQL 18 `bin` directory to the current shell's `PATH` or set the script-specific path:

```powershell
$env:CAFE_FAUSSE_PSQL = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
```

Use the actual PostgreSQL installation path if it differs.

## 3. Set the repository location

Open PowerShell and set the repository root. Change the path if the repository is elsewhere.

```powershell
$CafeRepo = 'C:\Users\Administrator\source\CafeFausse'
Set-Location $CafeRepo
```

All commands in this guide assume the repository root unless a step explicitly changes directories.

## 4. One-time database provisioning

### Step 4.1 - Start PostgreSQL

Start the locally installed PostgreSQL 18.3 service using Windows Services or the normal startup method for the installation.

Confirm the server accepts connections:

```powershell
pg_isready -h localhost -p 5432
```

Do not continue until PostgreSQL reports that it is accepting connections.

### Step 4.2 - Select the PostgreSQL administrator

Replace `postgres` if the local administrator login has a different name.

```powershell
$CafeAdminLogin = 'postgres'
$env:PGHOST = 'localhost'
$env:PGPORT = '5432'
$env:PGDATABASE = 'cafe_fausse_dev'
$env:PGUSER = $CafeAdminLogin
$env:CAFE_FAUSSE_ENVIRONMENT = 'development'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
```

If password authentication is required, read the administrator password without displaying it:

```powershell
$CafeAdminPassword = Read-Host "Password for $CafeAdminLogin" -AsSecureString
$env:PGPASSWORD = [System.Net.NetworkCredential]::new(
    '', $CafeAdminPassword
).Password
$CafeAdminPassword.Dispose()
Remove-Variable CafeAdminPassword
```

This keeps the password out of the repository and visible command text. `PGPASSWORD` still exists in the current process environment until it is cleared later.

If a protected `PGPASSFILE` is already configured, use it instead of `PGPASSWORD`; never set both.

### Step 4.3 - Create the empty development database

For a new environment:

```powershell
createdb `
    -h $env:PGHOST `
    -p $env:PGPORT `
    -U $env:PGUSER `
    $env:PGDATABASE
```

If PostgreSQL reports that `cafe_fausse_dev` already exists, do not recreate it. Confirm that it is the intended disposable local development database before continuing.

### Step 4.4 - Build and verify the Cafe Fausse schema

From the repository root:

```powershell
pwsh -File database/scripts/rebuild.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The guarded rebuild:

- verifies the requested and actual database names;
- provisions the passwordless group roles;
- drops only the fixed `cafe_fausse` schema in the selected safe database;
- runs migrations `001` through `011` in lexical order;
- restores the approved configuration, operating hours, and 30-table baseline; and
- runs the database verifiers.

Run a read-only verification once more:

```powershell
pwsh -File database/scripts/verify.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Stop and diagnose any rebuild or verification failure. Do not continue with a partially provisioned database.

### Step 4.5 - Create the app-only login

Flask must not use the PostgreSQL administrator, schema owner, or test role. Create a dedicated local login once.

Start an administrator `psql` session:

```powershell
psql -X -v ON_ERROR_STOP=1 `
    -h $env:PGHOST `
    -p $env:PGPORT `
    -U $CafeAdminLogin `
    -d $env:PGDATABASE
```

At the `psql` prompt, run:

```sql
CREATE ROLE cafe_fausse_local_app
    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    NOBYPASSRLS NOINHERIT;
GRANT cafe_fausse_app TO cafe_fausse_local_app;
GRANT CONNECT ON DATABASE cafe_fausse_dev TO cafe_fausse_local_app;
\password cafe_fausse_local_app
```

Enter the new app-login password twice when prompted. Use a password different from the administrator password. Then exit:

```sql
\q
```

This is a one-time role-creation step. On a later rebuild, the login normally remains because the rebuild replaces the application schema, not the whole database cluster. If the login already exists, do not rerun `CREATE ROLE`; verify its grants or reset its password through an administrator `psql` session.

### Step 4.6 - Verify the role boundary

Temporarily authenticate as the app login:

```powershell
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
$CafeAppPassword = Read-Host 'Password for cafe_fausse_local_app' -AsSecureString
$env:PGPASSWORD = [System.Net.NetworkCredential]::new(
    '', $CafeAppPassword
).Password
$CafeAppPassword.Dispose()
Remove-Variable CafeAppPassword

psql -X -tA -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 `
    -p 5432 `
    -U cafe_fausse_local_app `
    -d cafe_fausse_dev `
    -c "SET ROLE cafe_fausse_app; SELECT session_user || '|' || current_user; RESET ROLE;"
```

Expected result:

```text
cafe_fausse_local_app|cafe_fausse_app
```

Clear the credential after verification:

```powershell
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
```

## 5. One-time backend provisioning

From the repository root:

```powershell
py -3.14 -m venv backend\.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -e "backend[test]"
```

If the Windows Python launcher is unavailable but Python is installed at the project's verified location, use:

```powershell
C:\Python314\python.exe -m venv backend\.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -e "backend[test]"
```

Confirm the package imports:

```powershell
python -c "import cafe_fausse; print('Backend import: PASS')"
```

Deactivate when the one-time installation is complete:

```powershell
deactivate
```

## 6. One-time frontend provisioning

From the repository root:

```powershell
Set-Location frontend
npm ci
Set-Location ..
```

Use `npm ci` so dependencies come from the committed lockfile. Do not use `npm update` as a setup or recovery step.

Confirm that the production build succeeds:

```powershell
Set-Location frontend
npm run build
Set-Location ..
```

## 7. Start Cafe Fausse for each manual-test or demo session

Use three PowerShell terminals. Start them in the order below.

### Terminal 1 - Flask backend

```powershell
$CafeRepo = 'C:\Users\Administrator\source\CafeFausse'
Set-Location $CafeRepo

Remove-Item Env:CAFE_FAUSSE_ALLOW_RESET -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_PSQL -ErrorAction SilentlyContinue
Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue

$env:CAFE_FAUSSE_ENVIRONMENT = 'development'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = '5432'
$env:PGDATABASE = 'cafe_fausse_dev'
$env:PGUSER = 'cafe_fausse_local_app'

$CafeAppPassword = Read-Host 'Password for cafe_fausse_local_app' -AsSecureString
$env:PGPASSWORD = [System.Net.NetworkCredential]::new(
    '', $CafeAppPassword
).Password
$CafeAppPassword.Dispose()
Remove-Variable CafeAppPassword

backend\.venv\Scripts\Activate.ps1
Set-Location backend
python -m flask --app cafe_fausse run
```

Expected address:

```text
http://127.0.0.1:5000
```

Leave this terminal open. Flask performs no migration or schema change at startup.

### Terminal 2 - React/Vite frontend

```powershell
$CafeRepo = 'C:\Users\Administrator\source\CafeFausse'
Set-Location $CafeRepo
$env:CAFE_FAUSSE_FLASK_PROXY_TARGET = 'http://127.0.0.1:5000'
Set-Location frontend
npm run dev
```

Expected address:

```text
http://localhost:5173/
```

Open the exact URL displayed by Vite. Use the Vite development URL for the full local stack because it proxies relative `/api` requests to Flask.

Do not use `npm run preview` for the normal full-stack manual test; the committed development proxy belongs to the development server.

### Terminal 3 - Health checks and database evidence

```powershell
$DirectLiveness = Invoke-RestMethod `
    'http://127.0.0.1:5000/api/v1/health/liveness'
$DirectReadiness = Invoke-RestMethod `
    'http://127.0.0.1:5000/api/v1/health/readiness'
$ProxiedReadiness = Invoke-RestMethod `
    'http://localhost:5173/api/v1/health/readiness'

$DirectLiveness
$DirectReadiness
$ProxiedReadiness
```

Required results:

- direct liveness reports `status = live`;
- direct readiness reports `status = ready`; and
- proxied readiness reports `status = ready`.

Do not begin manual testing or a rehearsal unless all three checks succeed.

## 8. Quick manual smoke test

Use the application through `http://localhost:5173/`.

### Step 8.1 - Five pages and navigation

1. Open Home.
2. Verify the restaurant name, address, phone, hours, hero content, and shared navigation.
3. Open Menu and verify Starters, Main Courses, Desserts, and Beverages show descriptions and prices.
4. Open Reservations and confirm the availability and customer form workflow is present.
5. Open About Us and verify the history, founders, mission, and commitments.
6. Open Gallery and verify restaurant, dish, special-event, and behind-the-scenes imagery plus awards and reviews.
7. Use the shared navigation to return to Home.

### Step 8.2 - Gallery and keyboard behavior

1. Open Gallery.
2. Select a middle image.
3. Verify the lightbox opens.
4. Use Next or Previous once and verify the image/counter changes.
5. Close the lightbox.
6. Repeat with keyboard navigation where applicable, including `Tab`, `Enter` or `Space`, arrow keys, and `Escape`.

### Step 8.3 - Responsive behavior

1. Open Chrome or Edge DevTools.
2. Enable the device toolbar.
3. Set the viewport to 390 x 844.
4. Check Home, Gallery, and Reservations.
5. Verify navigation and content reflow without horizontal page scrolling.
6. Restore desktop width and close DevTools.

This is a responsive-layout check. It is not a substitute for the retained Firefox and Safari manual compatibility evidence.

### Step 8.4 - Newsletter persistence

Create a unique fictional identity. A timestamp helps avoid collisions:

```powershell
$CafeStamp = Get-Date -Format 'yyyyMMddHHmmss'
$CafeNewsletterEmail = "newsletter.$CafeStamp@example.test"
$CafeNewsletterEmail
```

1. Copy the displayed email.
2. On Home, enter a fictional first and last name.
3. Enter and confirm the unique fictional email if the form requests confirmation.
4. Select Subscribe and save.
5. Verify the browser reports that the newsletter preference was saved and that the authoritative state is subscribed.
6. For an official demo, also show the matching PostgreSQL before/after evidence using the approved Prompt-28 queries.

### Step 8.5 - Successful reservation

Create a different unique fictional email:

```powershell
$CafeStamp = Get-Date -Format 'yyyyMMddHHmmss'
$CafeReservationEmail = "reservation.$CafeStamp@example.test"
$CafeReservationEmail
```

1. Open Reservations.
2. Select a date inside the displayed booking window. Respect the same-day lead time if testing today.
3. Enter party size 6.
4. Select Check availability.
5. Verify the displayed slots came from the server and that unavailable slots cannot be selected.
6. Select an available slot.
7. Enter a fictional first name, last name, matching email and confirmation, and optional fictional phone number.
8. Submit once.
9. Verify `Reservation confirmed` appears.
10. Record the confirmation reference, local/canonical interval, party size, and assigned table numbers.
11. For an official demo, show the matching PostgreSQL customer, reservation, and assignment evidence using the approved Prompt-28 queries.

### Step 8.6 - Failure behavior worth checking

Without changing the database directly, verify a representative set of safe UI failures:

- mismatched email confirmation;
- omitted required name or email;
- invalid party size;
- no selected server-returned slot;
- repeated submit click remains controlled; and
- an unavailable slot cannot be selected.

The application should keep the user on the form for correctable errors and should not display raw database details or secrets.

## 9. Prepare the environment for the official demo

Ordinary startup is fully covered above. The official demonstration adds controlled evidence and deterministic data.

### Step 9.1 - Return to the clean baseline

This deletes current Cafe Fausse application data in `cafe_fausse_dev`. Stop Flask before rebuilding.

In an administrator PowerShell terminal:

```powershell
$CafeRepo = 'C:\Users\Administrator\source\CafeFausse'
Set-Location $CafeRepo

$env:PGHOST = 'localhost'
$env:PGPORT = '5432'
$env:PGDATABASE = 'cafe_fausse_dev'
$env:PGUSER = 'postgres' # Replace if the administrator login differs.
$env:CAFE_FAUSSE_ENVIRONMENT = 'development'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'

$CafeAdminPassword = Read-Host "Password for $env:PGUSER" -AsSecureString
$env:PGPASSWORD = [System.Net.NetworkCredential]::new(
    '', $CafeAdminPassword
).Password
$CafeAdminPassword.Dispose()
Remove-Variable CafeAdminPassword

pwsh -File database/scripts/rebuild.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
pwsh -File database/scripts/verify.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
```

### Step 9.2 - Start and verify all three layers

1. Start Flask using Section 7, Terminal 1.
2. Start React/Vite using Section 7, Terminal 2.
3. Run all three health checks using Section 7, Terminal 3.
4. Keep a clean health-check result visible for the demonstration.

### Step 9.3 - Prepare demo-only data and evidence

Use only these two companion documents for the official demonstration:

- `docs/demo/Cafe_Fausse_Prompt28_Demonstration_Plan.md`, especially its guarded preparation, cleanup, and Section 5 PostgreSQL evidence queries;
- `Cafe_Fausse_10_Minute_Three_Person_Demo_Runbook.md` for the P1/P2/P3 timing, narrative, and handoffs.

Prepare:

- one unique fictional newsletter identity;
- a different unique fictional reservation identity;
- the guarded, rehearsed full-capacity date/time;
- a different allowed date for the successful party-of-6 reservation; and
- a blank place to capture the confirmation reference.

The baseline capacity is 120 seats: 30 tables with four seats each. The official full/unavailable demonstration must use the approved guarded preparation workflow. Do not create the condition by manually inserting, updating, or deleting individual rows.

### Step 9.4 - Arrange the windows

Before rehearsal:

1. Open the application on Home.
2. Open a prepared `psql` evidence session.
3. Keep the clean direct and proxied readiness results available.
4. Prepare Chrome or Edge DevTools for 390 x 844, but leave it closed until needed.
5. Increase terminal text size enough for the audience to read results.
6. Hide passwords, tokens, environment dumps, `.env` files, personal information, notifications, and unrelated windows.
7. Confirm P1, P2, and P3 cameras, microphones, IDs, and handoffs.
8. Run the complete 10-minute rehearsal before any actual recording.

Stop and reset if any expected browser result and PostgreSQL result disagree.

## 10. Stop the application safely

### Stop React/Vite

In Terminal 2, press `Ctrl+C`. Then clear its proxy setting:

```powershell
Remove-Item Env:CAFE_FAUSSE_FLASK_PROXY_TARGET -ErrorAction SilentlyContinue
```

### Stop Flask

In Terminal 1, press `Ctrl+C`. Then clear credentials and application variables:

```powershell
deactivate
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
Remove-Item Env:PGHOST -ErrorAction SilentlyContinue
Remove-Item Env:PGPORT -ErrorAction SilentlyContinue
Remove-Item Env:PGDATABASE -ErrorAction SilentlyContinue
Remove-Item Env:PGUSER -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_ENVIRONMENT -ErrorAction SilentlyContinue
```

### Reset manual-test or rehearsal data when needed

If the next session needs a clean baseline, stop Flask and rerun the guarded rebuild and verification in Step 9.1. This is the supported reset path. Do not repair data manually.

Stopping Flask and Vite does not stop the general PostgreSQL Windows service. Leave it running or stop it through the normal PostgreSQL service-management method, depending on the machine's intended use.

## 11. Fast restart checklist

After one-time provisioning, most sessions need only:

1. Start PostgreSQL 18.3.
2. Start Flask in Terminal 1.
3. Start Vite in Terminal 2.
4. Run direct liveness, direct readiness, and proxied readiness in Terminal 3.
5. Open `http://localhost:5173/`.
6. Use unique fictional identities.
7. Run the manual smoke test or rehearse the approved demo.
8. Stop Vite and Flask and clear credentials.
9. Guarded-rebuild only when a clean baseline is required.

## 12. Troubleshooting

### `psql`, `createdb`, or `pg_isready` is not recognized

Use the PostgreSQL 18 `bin` directory or add it to the current PowerShell `PATH`. Confirm that the tools report PostgreSQL 18.3.

### `rebuild.ps1` refuses to run

Check all of the following:

- the selected database is truly nonproduction;
- `PGDATABASE` begins with `cafe_fausse_dev`, `cafe_fausse_test`, or `cafe_fausse_demo`;
- `CAFE_FAUSSE_ENVIRONMENT` is `development`, `test`, or `demo` for the database script;
- `CAFE_FAUSSE_ALLOW_RESET` is exactly `YES`; and
- the actual connected database matches `PGDATABASE`.

Do not weaken or bypass a guard.

### Flask reports not ready

Check:

1. PostgreSQL is running.
2. `cafe_fausse_dev` was rebuilt and verified.
3. `PGUSER` is `cafe_fausse_local_app`, not the administrator.
4. The app login can assume `cafe_fausse_app`.
5. Exactly one of `PGPASSWORD` and `PGPASSFILE` is configured.
6. The password belongs to the app login.
7. `PGHOST`, `PGPORT`, and `PGDATABASE` are correct.

### The frontend opens but API calls fail

Check:

1. Flask is listening at `http://127.0.0.1:5000`.
2. Terminal 2 set `CAFE_FAUSSE_FLASK_PROXY_TARGET` before starting Vite.
3. You opened the Vite development URL, normally `http://localhost:5173/`.
4. Proxied readiness succeeds.

Restart Vite after changing the proxy target.

### Python cannot import `cafe_fausse`

Return to the repository root, activate `backend\.venv`, and rerun:

```powershell
python -m pip install -e "backend[test]"
```

### Frontend dependency or build problems

From `frontend/`, rerun:

```powershell
npm ci
npm run build
```

Do not substitute `npm update`.

### No valid reservation date or slot appears

Confirm the browser shows the current server-provided booking window. The baseline uses:

- restaurant timezone `America/New_York`;
- 60-day advance window;
- 120-minute same-day lead time;
- 30-minute start intervals;
- 90-minute reservation duration;
- Monday-Saturday hours 17:00-23:00; and
- Sunday hours 17:00-21:00.

The latest permitted start is derived from closing time and reservation duration.

## 13. Source and scope note

This guide consolidates the current root `README.md`, the approved database/backend/frontend operating model, the SRS and Rubric constraints, and the approved three-person demonstration runbook. It intentionally preserves the exact guarded demo preparation and PostgreSQL evidence SQL in the committed Prompt-28 plan rather than duplicating security-sensitive or drift-prone database procedures.

