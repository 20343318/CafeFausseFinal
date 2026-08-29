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

### How to interpret expected output

- Output labelled **Expected** is the success condition to verify before continuing.
- Output labelled **Representative** may differ slightly by PowerShell, PostgreSQL, Python, npm, Flask, or Vite patch version. Match the meaning, not incidental spacing, timing, or dependency counts.
- A command that returns to the PowerShell prompt without red error text may legitimately produce no output. Such steps explicitly say **no output on success**.
- `$LASTEXITCODE` must be `0` whenever this guide checks it.
- Stop at the first failed success condition. Do not continue and hope a later layer repairs an earlier one.

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

In every new PowerShell session that will use PostgreSQL command-line tools, add the PostgreSQL 18 `bin` directory to that session's `PATH` first:

```powershell
$PostgreSqlBin = 'C:\Program Files\PostgreSQL\18\bin'
if (-not (Test-Path -LiteralPath $PostgreSqlBin)) {
    throw "PostgreSQL 18 bin directory not found: $PostgreSqlBin"
}
if (($env:PATH -split ';') -notcontains $PostgreSqlBin) {
    $env:PATH += ";$PostgreSqlBin"
}
```

Expected result: the commands produce no output and return to the prompt. This changes only the current PowerShell session; repeat it in each newly opened terminal that needs `psql`, `createdb`, or `pg_isready`.

**Stop when:** the directory is not found. Locate the actual PostgreSQL 18 `bin` directory and update `$PostgreSqlBin` before continuing.

Run these checks:

```powershell
git --version
psql --version
createdb --version
py -3.14 --version
node --version
npm --version
$PSVersionTable.PSVersion.ToString()
```

Expected important results:

- PostgreSQL reports 18.3.
- Python reports 3.14.x.
- Node reports 24.15.0 or newer.

Representative output:

```text
git version 2.x.x.windows.x
psql (PostgreSQL) 18.3
createdb (PostgreSQL) 18.3
Python 3.14.x
v24.15.0 or newer
10.x/11.x/12.x or another npm version compatible with lockfile version 3
5.1.x or 7.x.x
```

**Continue when:** every command is recognized and the PostgreSQL, Python, and Node versions meet the values above.

**Stop when:** a command is not recognized, PostgreSQL is not 18.3, Python is not 3.14.x, or Node is older than 24.15.0.

If `pwsh` is unavailable but Windows PowerShell 5.1 is installed, use `powershell` wherever this guide shows `pwsh`.

If only the repository scripts need help locating `psql`, set the script-specific path:

```powershell
$env:CAFE_FAUSSE_PSQL = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
```

Use the actual PostgreSQL installation path if it differs. `CAFE_FAUSSE_PSQL` helps the repository's database scripts locate `psql`; it does not make the separate `createdb` or `pg_isready` commands available. The session-level `PATH` setup above is preferred for this guide because all three tools remain available.

## 3. Set the repository location

Open PowerShell and set the repository root. This command assumes the repository is in `source\CafeFausse` beneath the current Windows user's profile. If it is elsewhere, assign its actual absolute path to `$CafeRepo` instead.

```powershell
$CafeRepo = Join-Path $env:USERPROFILE 'source\CafeFausse'
Set-Location $CafeRepo
Get-Location
```

Expected result: `Get-Location` displays the repository root, for example:

```text
Path
----
C:\Users\<UserName>\source\CafeFausse
```

**Continue when:** the displayed directory contains `database`, `backend`, `frontend`, and `README.md`.

**Stop when:** `Set-Location` fails or the displayed directory is not the intended repository.

All commands in this guide assume the repository root unless a step explicitly changes directories.

## 4. One-time database provisioning

### Step 4.1 - Start PostgreSQL

Start the locally installed PostgreSQL 18.3 service using Windows Services or the normal startup method for the installation.

Confirm the server accepts connections:

```powershell
pg_isready -h localhost -p 5432
```

Expected result:

```text
localhost:5432 - accepting connections
```

The host text may appear as `127.0.0.1` depending on local resolution.

**Continue when:** the result says `accepting connections` and the command exits with code `0`.

**Stop when:** it says `no response`, `rejecting connections`, or reports a different server/port.

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

Expected result: these assignments produce no output on success.

Verify only the nonsecret values:

```powershell
@{
    PGHOST = $env:PGHOST
    PGPORT = $env:PGPORT
    PGDATABASE = $env:PGDATABASE
    PGUSER = $env:PGUSER
    CAFE_FAUSSE_ENVIRONMENT = $env:CAFE_FAUSSE_ENVIRONMENT
    CAFE_FAUSSE_ALLOW_RESET = $env:CAFE_FAUSSE_ALLOW_RESET
}
```

Expected values:

```text
PGHOST                         localhost
PGPORT                         5432
PGDATABASE                     cafe_fausse_dev
PGUSER                         postgres (or the selected local administrator)
CAFE_FAUSSE_ENVIRONMENT        development
CAFE_FAUSSE_ALLOW_RESET        YES
```

PowerShell may display the rows in a different order.

**Stop when:** the database name, environment, reset authorization, host, port, or administrator is not the intended value.

If password authentication is required, read the administrator password without displaying it:

```powershell
Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
$CafeAdminPassword = Read-Host "Password for $CafeAdminLogin" -AsSecureString
$env:PGPASSWORD = [System.Net.NetworkCredential]::new(
    '', $CafeAdminPassword
).Password
$CafeAdminPassword.Dispose()
Remove-Variable CafeAdminPassword
```

Expected result: PowerShell displays the password prompt, does not echo the password, and returns to the prompt without error. Do not print `$env:PGPASSWORD` to verify it.

This keeps the password out of the repository and visible command text. `PGPASSWORD` still exists in the current process environment until it is cleared later.

If a protected `PGPASSFILE` is already configured, use it instead of `PGPASSWORD`; never set both.

Verify the running PostgreSQL server version, not only the installed client tools:

```powershell
psql -X -tA -v ON_ERROR_STOP=1 `
    -h $env:PGHOST `
    -p $env:PGPORT `
    -U $env:PGUSER `
    -d postgres `
    -c "SHOW server_version;"
```

Expected result:

```text
18.3
```

**Continue when:** the connected server reports exactly PostgreSQL 18.3.

**Stop when:** authentication fails, the server cannot be reached, or the server version differs. A PostgreSQL 18.3 client connected to a different server version does not satisfy the project contract.

### Optional Step 4.2A - Delete the existing development database for a complete provisioning retest

Skip this optional step for an initial setup or an ordinary clean-baseline rebuild. Use it only when deliberately retesting database creation and provisioning from an absent `cafe_fausse_dev` database.

This permanently deletes the entire local `cafe_fausse_dev` database and all data inside it. Stop Flask and close any `psql` session connected to that database before continuing. The command uses `--force` to terminate any remaining connections to this exact database.

First validate and explicitly confirm the fixed target:

```powershell
$CafeDatabaseToDrop = 'cafe_fausse_dev'
if ($env:PGDATABASE -cne $CafeDatabaseToDrop) {
    throw "Refusing to drop '$env:PGDATABASE'; expected '$CafeDatabaseToDrop'."
}

$DropConfirmation = Read-Host "Type DROP cafe_fausse_dev to permanently delete the database"
if ($DropConfirmation -cne 'DROP cafe_fausse_dev') {
    throw 'Database deletion was not confirmed.'
}
```

Expected result: PowerShell displays the confirmation prompt and returns to the prompt without error only after the exact confirmation text is entered.

**Stop when:** the selected database is not exactly `cafe_fausse_dev`, the database is not disposable, or the exact confirmation is not provided.

Delete only the validated database:

```powershell
dropdb `
    --if-exists `
    --force `
    -h $env:PGHOST `
    -p $env:PGPORT `
    -U $env:PGUSER `
    $CafeDatabaseToDrop

if ($LASTEXITCODE -ne 0) {
    throw "dropdb failed with exit code $LASTEXITCODE."
}
```

Expected result: `dropdb` normally produces no output and returns exit code `0`.

Verify that the database no longer exists:

```powershell
$DroppedDatabaseCheck = psql -X -tA -v ON_ERROR_STOP=1 `
    -h $env:PGHOST `
    -p $env:PGPORT `
    -U $env:PGUSER `
    -d postgres `
    -c "SELECT datname FROM pg_database WHERE datname = 'cafe_fausse_dev';"

if ($LASTEXITCODE -ne 0) {
    throw "Database verification failed with exit code $LASTEXITCODE."
}
if ($DroppedDatabaseCheck) {
    throw 'cafe_fausse_dev still exists.'
}
'Confirmed: cafe_fausse_dev does not exist.'
```

Expected result:

```text
Confirmed: cafe_fausse_dev does not exist.
```

**Continue when:** the verification confirms that `cafe_fausse_dev` does not exist. Proceed directly to Step 4.3 to recreate it.

**Stop when:** `dropdb` fails, verification cannot connect to the `postgres` maintenance database, or the verification query still finds `cafe_fausse_dev`.

Deleting a database does not delete PostgreSQL cluster roles. The passwordless group roles and `cafe_fausse_local_app` may still exist. When Step 4.5 is reached, follow its existing-role instructions rather than attempting to create the application login again.

### Step 4.3 - Create the empty development database

For a new environment:

```powershell
createdb `
    -h $env:PGHOST `
    -p $env:PGPORT `
    -U $env:PGUSER `
    $env:PGDATABASE
```

Expected result: `createdb` normally produces no output and returns exit code `0`.

Verify the result:

```powershell
psql -X -tA -v ON_ERROR_STOP=1 `
    -h $env:PGHOST `
    -p $env:PGPORT `
    -U $env:PGUSER `
    -d postgres `
    -c "SELECT datname FROM pg_database WHERE datname = 'cafe_fausse_dev';"
```

Expected result:

```text
cafe_fausse_dev
```

**Continue when:** the query returns exactly one `cafe_fausse_dev` row.

**Stop when:** database creation fails for a reason other than an already-existing, independently verified disposable database.

If PostgreSQL reports that `cafe_fausse_dev` already exists, do not recreate it. Confirm that it is the intended disposable local development database before continuing.

### Step 4.4 - Build and verify the Cafe Fausse schema

From the repository root:

```powershell
pwsh -File database/scripts/rebuild.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Expected progress: the script reports its nonproduction guard checks, applies the ordered provisioning/migration/seed work, runs the DB-05/DB-06/DB-07 verifiers, and returns exit code `0`. Exact informational wording can vary with the committed script.

Representative successful ending:

```text
... migrations applied ...
... baseline seed verified ...
... database verification passed ...
```

There must be no `ERROR`, unhandled exception, failed guard, failed migration, or failed verifier.

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

Expected result: all database verification sections report success, no failure is printed, and the command returns exit code `0`.

**Continue when:** both `rebuild.ps1` and `verify.ps1` finish successfully.

**Stop when:** either command returns nonzero, any guard refuses the target, or any verifier reports an unexpected schema, seed, role, privilege, function, or invariant.

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

Representative connection banner:

```text
psql (18.3)
Type "help" for help.

cafe_fausse_dev=#
```

**Stop when:** the prompt names a database other than `cafe_fausse_dev` or authentication fails.

At the `psql` prompt, run:

```sql
CREATE ROLE cafe_fausse_local_app
    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    NOBYPASSRLS NOINHERIT;
GRANT cafe_fausse_app TO cafe_fausse_local_app;
GRANT CONNECT ON DATABASE cafe_fausse_dev TO cafe_fausse_local_app;
\password cafe_fausse_local_app
```

Expected progress:

```text
CREATE ROLE
GRANT ROLE
GRANT
Enter new password for user "cafe_fausse_local_app":
Enter it again:
ALTER ROLE
```

PostgreSQL client wording can differ slightly. The password must not appear on screen.

**Continue when:** every SQL statement succeeds and the password operation completes.

**Stop when:** any `ERROR` appears. Do not ignore an existing-role error; follow the existing-login instruction below instead.

Enter the new app-login password twice when prompted. Use a password different from the administrator password. Then exit:

```sql
\q
```

This is a one-time role-creation step. On a later rebuild, the login normally remains because the rebuild replaces the application schema, not the whole database cluster. If the login already exists, do not rerun `CREATE ROLE`; verify its grants or reset its password through an administrator `psql` session.

### Step 4.6 - Verify the role boundary

Temporarily authenticate as the app login:

```powershell
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
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

The command may also print `SET` and `RESET` status lines unless tuple-only formatting suppresses them.

**Continue when:** the only identity row is exactly `cafe_fausse_local_app|cafe_fausse_app` and the command exits with code `0`.

**Stop when:** authentication fails, the row is missing, or the current role is not `cafe_fausse_app`.

Clear the credential after verification:

```powershell
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
```

Expected result: clearing the credential produces no output on success.

## 5. One-time backend provisioning

From the repository root:

```powershell
py -3.14 -m venv backend\.venv
backend\.venv\Scripts\Activate.ps1
python -m pip install -e "backend[test]"
```

Expected progress:

- virtual-environment creation normally produces no output;
- activation changes the PowerShell prompt to include `(.venv)`;
- pip resolves/builds the editable Cafe Fausse backend and installs its application and test dependencies; and
- pip finishes without an `ERROR` or failed build.

Representative prompt after activation:

```text
(.venv) PS C:\Users\<UserName>\source\CafeFausse>
```

Representative pip ending:

```text
Successfully installed ... cafe-fausse ...
```

If dependencies are already present, pip may instead report `Requirement already satisfied` for some packages.

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

Expected result:

```text
Backend import: PASS
```

**Continue when:** the virtual environment is active, pip completed successfully, and the import prints the exact PASS line.

**Stop when:** Python reports `ModuleNotFoundError`, an unsupported Python version, dependency resolution failure, or another traceback.

Deactivate when the one-time installation is complete:

```powershell
deactivate
```

Expected result: `deactivate` produces no output and removes `(.venv)` from the PowerShell prompt.

## 6. One-time frontend provisioning

From the repository root:

```powershell
Set-Location frontend
npm ci
Set-Location ..
```

Expected progress: npm reads the committed lockfile, installs the locked dependency tree, and returns exit code `0`. The package count, timing, funding text, and audit summary can vary.

Representative ending:

```text
added ... packages, and audited ... packages in ...
```

There must be no `npm ERR!` line.

Use `npm ci` so dependencies come from the committed lockfile. Do not use `npm update` as a setup or recovery step.

Confirm that the production build succeeds:

```powershell
Set-Location frontend
npm run build
Set-Location ..
```

Expected progress: Vite transforms the application, writes the production build, reports generated assets, and finishes successfully.

Representative ending:

```text
vite ... building for production...
... modules transformed.
dist/... generated
... built in ...
```

**Continue when:** both `npm ci` and `npm run build` exit with code `0` and the build creates or refreshes `frontend/dist`.

**Stop when:** npm reports an install error, lockfile inconsistency, test/build compilation error, or missing asset.

## 7. Start Cafe Fausse for each manual-test or demo session

Use three PowerShell terminals. Start them in the order below.

### Terminal 1 - Flask backend

```powershell
$CafeRepo = Join-Path $env:USERPROFILE 'source\CafeFausse'
Set-Location $CafeRepo

$PostgreSqlBin = 'C:\Program Files\PostgreSQL\18\bin'
if (-not (Test-Path -LiteralPath $PostgreSqlBin)) {
    throw "PostgreSQL 18 bin directory not found: $PostgreSqlBin"
}
if (($env:PATH -split ';') -notcontains $PostgreSqlBin) {
    $env:PATH += ";$PostgreSqlBin"
}

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

if ([string]::IsNullOrEmpty($env:PGPASSWORD)) {
    throw 'PGPASSWORD is missing; Flask cannot authenticate to PostgreSQL.'
}
'PGPASSWORD is set for the Flask process.'

backend\.venv\Scripts\Activate.ps1
Set-Location backend
python -m flask --app cafe_fausse run
```

Expected progress:

```text
PGPASSWORD is set for the Flask process.
* Serving Flask app 'cafe_fausse'
* Debug mode: off
* Running on http://127.0.0.1:5000
```

Flask may include its standard local-development warning and slightly different quoting.

**Continue when:** the process remains running and shows `http://127.0.0.1:5000` without a startup traceback or configuration error.

**Stop when:** the PostgreSQL `bin` directory is missing, the password check fails, the process exits, reports an unknown `CAFE_FAUSSE_*` variable, cannot bind port 5000, or reports invalid database/application configuration.

Expected address:

```text
http://127.0.0.1:5000
```

Leave this terminal open. Flask performs no migration or schema change at startup.

### Terminal 2 - React/Vite frontend

```powershell
$CafeRepo = Join-Path $env:USERPROFILE 'source\CafeFausse'
Set-Location $CafeRepo
$env:CAFE_FAUSSE_FLASK_PROXY_TARGET = 'http://127.0.0.1:5000'
Set-Location frontend
npm run dev
```

Expected progress:

```text
VITE ... ready in ...
Local: http://localhost:5173/
```

The Vite version, startup time, spacing, and network line can vary.

**Continue when:** Vite remains running and displays `http://localhost:5173/`.

**Stop when:** Vite exits, reports a missing dependency/asset, or selects a port other than 5173. A different port usually means another process owns 5173; stop and resolve that conflict before using the hard-coded proxied health check or rehearsing the demo.

Expected address:

```text
http://localhost:5173/
```

Open the exact URL displayed by Vite. Use the Vite development URL for the full local stack because it proxies relative `/api` requests to Flask.

Do not use `npm run preview` for the normal full-stack manual test; the committed development proxy belongs to the development server.

### Terminal 3 - Health checks and database evidence

```powershell
$PostgreSqlBin = 'C:\Program Files\PostgreSQL\18\bin'
if (-not (Test-Path -LiteralPath $PostgreSqlBin)) {
    throw "PostgreSQL 18 bin directory not found: $PostgreSqlBin"
}
if (($env:PATH -split ';') -notcontains $PostgreSqlBin) {
    $env:PATH += ";$PostgreSqlBin"
}

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

Representative PowerShell rendering:

```text
status
------
live
ready
ready
```

PowerShell may render each object as a separate table or as `@{status=...}`. The three values, in order, must be `live`, `ready`, and `ready`.

**Stop when:** the PostgreSQL `bin` directory is missing, a request throws, returns an HTTP error, reports `service_not_ready`, returns an unexpected body, or the proxied request cannot reach Flask.

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

Expected result:

- every navigation action changes to the intended route without an error page;
- all five required pages render their expected content;
- the shared navigation remains visible and usable; and
- returning to Home succeeds without a full-stack error.

**Stop when:** any page is missing, blank, visibly broken, routed incorrectly, or shows a browser/React/API error.

### Step 8.2 - Gallery and keyboard behavior

1. Open Gallery.
2. Select a middle image.
3. Verify the lightbox opens.
4. Use Next or Previous once and verify the image/counter changes.
5. Close the lightbox.
6. Repeat with keyboard navigation where applicable, including `Tab`, `Enter` or `Space`, arrow keys, and `Escape`.

Expected result:

- the selected image opens in a dialog/lightbox;
- Next or Previous changes the displayed image and position/counter;
- keyboard focus remains usable;
- `Escape` or Close dismisses the lightbox; and
- focus returns predictably to Gallery content.

**Stop when:** the dialog cannot open/close, navigation escapes the bounded collection, focus becomes trapped incorrectly, or an image fails to render.

### Step 8.3 - Responsive behavior

1. Open Chrome or Edge DevTools.
2. Enable the device toolbar.
3. Set the viewport to 390 x 844.
4. Check Home, Gallery, and Reservations.
5. Verify navigation and content reflow without horizontal page scrolling.
6. Restore desktop width and close DevTools.

Expected result:

- content reflows to the 390 x 844 viewport;
- text and controls remain readable and operable;
- the page has no horizontal document scrollbar; and
- restoring desktop width restores the desktop layout without reloading errors.

**Stop when:** content is clipped, controls overlap, the page scrolls horizontally, or navigation becomes unusable.

This is a responsive-layout check. It is not a substitute for the retained Firefox and Safari manual compatibility evidence.

### Step 8.4 - Newsletter persistence

Create a unique fictional identity. A timestamp helps avoid collisions:

```powershell
$CafeStamp = Get-Date -Format 'yyyyMMddHHmmss'
$CafeNewsletterEmail = "newsletter.$CafeStamp@example.com"
$CafeNewsletterEmail
```

Expected output resembles:

```text
newsletter.20260828153045@example.com
```

The timestamp will differ. `example.com` is a reserved example domain; the address must not contain real personal information.

1. Copy the displayed email.
2. On Home, enter a fictional first and last name.
3. Enter and confirm the unique fictional email if the form requests confirmation.
4. Select Subscribe and save.
5. Verify the browser reports that the newsletter preference was saved and that the authoritative state is subscribed.
6. For an official demo, also show the matching PostgreSQL before/after evidence using the approved Prompt-28 queries.

Expected result:

- the form accepts the unique fictional identity;
- the browser displays `Newsletter preference saved` or the committed equivalent success text;
- the authoritative preference is shown as subscribed; and
- official PostgreSQL evidence changes from zero matching rows before submission to exactly one matching subscribed customer afterward.

**Stop when:** the UI reports failure, the authoritative state is not subscribed, or the official database evidence is missing, duplicated, or inconsistent with the browser.

### Step 8.5 - Successful reservation

Create a different unique fictional email:

```powershell
$CafeStamp = Get-Date -Format 'yyyyMMddHHmmss'
$CafeReservationEmail = "reservation.$CafeStamp@example.com"
$CafeReservationEmail
```

Expected output resembles:

```text
reservation.20260828153110@example.com
```

The timestamp will differ. It must be different from the newsletter identity.

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

Expected result:

- the server returns the permitted date range, policy, and complete slot list;
- available slots are selectable and unavailable slots are visibly disabled/nonselectable;
- one submit produces `Reservation confirmed`;
- the confirmation contains a decimal reference, party size 6, interval details, assigned table number(s), and newsletter state; and
- official PostgreSQL evidence returns exactly one matching customer/reservation plus assignment rows that reconstruct the same table numbers.

**Stop when:** no valid slots appear for a valid date, an unavailable slot is selectable, submission fails, confirmation data is missing, or PostgreSQL does not match the browser confirmation.

### Step 8.6 - Failure behavior worth checking

Without changing the database directly, verify a representative set of safe UI failures:

- mismatched email confirmation;
- omitted required name or email;
- invalid party size;
- no selected server-returned slot;
- repeated submit click remains controlled; and
- an unavailable slot cannot be selected.

The application should keep the user on the form for correctable errors and should not display raw database details or secrets.

Expected result for each case:

- invalid/missing fields receive clear field-level or form-level guidance;
- the form remains available for correction;
- no confirmation reference is created for a rejected request;
- submit protection prevents accidental duplicate creation; and
- user-facing output contains no stack trace, SQL, credential, or internal exception detail.

**Stop when:** invalid input creates a reservation, a duplicate submit creates duplicate records, or internal implementation details are exposed.

## 9. Prepare the environment for the official demo

Ordinary startup is fully covered above. The official demonstration adds controlled evidence and deterministic data.

### Step 9.1 - Return to the clean baseline

This deletes current Cafe Fausse application data in `cafe_fausse_dev`. Stop Flask before rebuilding.

In an administrator PowerShell terminal:

```powershell
$CafeRepo = Join-Path $env:USERPROFILE 'source\CafeFausse'
Set-Location $CafeRepo

$env:PGHOST = 'localhost'
$env:PGPORT = '5432'
$env:PGDATABASE = 'cafe_fausse_dev'
$env:PGUSER = 'postgres' # Replace if the administrator login differs.
$env:CAFE_FAUSSE_ENVIRONMENT = 'development'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'

Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
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

Expected progress:

- the rebuild again passes all nonproduction guards;
- the schema, seed, and verification return to the approved clean baseline;
- both scripts exit with code `0`; and
- clearing `PGPASSWORD` produces no output on success.

**Continue when:** the final verifier succeeds and no old customer/reservation data remains in the rebuilt Cafe Fausse schema.

**Stop when:** a guard or verifier fails, the wrong database is selected, or the expected clean baseline is not restored.

### Step 9.2 - Start and verify all three layers

1. Start Flask using Section 7, Terminal 1.
2. Start React/Vite using Section 7, Terminal 2.
3. Run all three health checks using Section 7, Terminal 3.
4. Keep a clean health-check result visible for the demonstration.

Expected result: Flask and Vite remain running, direct liveness is `live`, direct readiness is `ready`, and proxied readiness is `ready`.

**Stop when:** any process exits, any readiness result is unhealthy, or a health terminal exposes a password or unrelated private information.

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

Expected result before rehearsal:

- the unique newsletter identity has zero matching customer rows;
- the unique reservation identity has zero matching reservation rows;
- the recorded full-capacity target time is labelled **Unavailable** and cannot be selected for party size 120;
- the separate success date has at least one available party-of-6 slot; and
- the confirmation-reference field on the operator cue sheet is blank.

**Stop when:** an identity is not unique, the full target is selectable, the success scenario lacks capacity, or preparation required an unapproved manual row edit.

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

Expected result:

- all required windows are readable without exposing secrets;
- P1, P2, and P3 can follow the scripted handoffs;
- newsletter and reservation browser results match direct PostgreSQL evidence;
- the prepared health view remains healthy; and
- the rehearsal finishes at or before 10:00, preferably between 9:40 and 9:50.

Do not proceed to an actual demonstration if any condition is missing or ambiguous.

## 10. Stop the application safely

### Stop React/Vite

In Terminal 2, press `Ctrl+C`. Then clear its proxy setting:

```powershell
Remove-Item Env:CAFE_FAUSSE_FLASK_PROXY_TARGET -ErrorAction SilentlyContinue
```

Expected result: Vite prints its normal interruption/termination behavior and the terminal returns to the PowerShell prompt. Clearing the environment variable produces no output on success. Port 5173 should no longer respond.

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

Expected result: Flask stops after `Ctrl+C`, the terminal returns to the prompt, `deactivate` removes `(.venv)` from the prompt, and the `Remove-Item` commands produce no output on success. Port 5000 should no longer respond.

Optional confirmation from a separate terminal:

```powershell
@(
    'http://127.0.0.1:5000/api/v1/health/liveness',
    'http://localhost:5173/'
) | ForEach-Object {
    try {
        Invoke-WebRequest $_ -TimeoutSec 2 -UseBasicParsing | Out-Null
        "STILL RESPONDING: $_"
    }
    catch {
        "STOPPED: $_"
    }
}
```

Expected result:

```text
STOPPED: http://127.0.0.1:5000/api/v1/health/liveness
STOPPED: http://localhost:5173/
```

**Stop and investigate when:** either address is still responding because another or orphaned process may own the port.

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

Expected progress summary:

| Checkpoint | Required observation |
|---|---|
| PostgreSQL | `pg_isready` says `accepting connections` |
| Flask | Terminal remains running on `127.0.0.1:5000` |
| Vite | Terminal remains running and shows the local URL |
| Direct liveness | `live` |
| Direct readiness | `ready` |
| Proxied readiness | `ready` |
| Browser smoke test | Five pages, Gallery, responsive layout, forms all work |
| Persistence | Browser success agrees with direct PostgreSQL evidence when required |
| Shutdown | Ports 5000 and 5173 no longer respond |

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
