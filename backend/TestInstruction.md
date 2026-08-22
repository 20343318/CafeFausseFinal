# Cafe Fausse testing and safe nonproduction database instructions

This guide puts the Cafe Fausse database and backend test workflow in the
order in which it should be performed. Run the commands from the repository
root in Windows PowerShell unless a step says otherwise.

## Safety rules

- Use PostgreSQL 18.3 only.
- Use a dedicated, disposable local cluster bound to `127.0.0.1` and a
  database whose name begins with `cafe_fausse_test_`.
- Never use these instructions against production, production-like data, a
  shared development server, or another application's PostgreSQL cluster.
- The full backend PostgreSQL integration suite deliberately stops and
  restarts PostgreSQL. `CAFE_FAUSSE_TEST_PGDATA` must therefore identify this
  dedicated cluster's data directory under the Windows temporary directory.
- Keep three separate login identities:
  - the setup administrator, used only for provisioning, rebuilds, and final
    restoration;
  - the deployment login, which is a member only of `cafe_fausse_app` and is
    used by Flask;
  - the test-management login, which is a member only of
    `cafe_fausse_test` and is used by external test fixtures.
- Give all three logins different passwords. Store them outside the repository
  in a protected PostgreSQL passfile. Never commit passwords, passfiles,
  connection URLs, or environment dumps.
- Use `PGPASSFILE` or `PGPASSWORD`, never both. This guide uses `PGPASSFILE`.
- Stop immediately if a guard, version check, role audit, rebuild, verifier, or
  test command fails.

## 1. Define the isolated target

Open PowerShell at the repository root and define task-specific variables:

```powershell
$CafeRepo = (Resolve-Path '.').Path
$CafePgBin = 'C:\Program Files\PostgreSQL\18\bin'
$CafeClusterRoot = Join-Path $env:TEMP 'CafeFausse-api04-local'
$CafeDataDir = Join-Path $CafeClusterRoot 'data'
$CafeLogFile = Join-Path $CafeClusterRoot 'postgres.log'
$CafePort = '55435'
$CafeDatabase = 'cafe_fausse_test_api04'
$CafeAdminLogin = 'cafe_fausse_admin'
$CafeAppLogin = 'cafe_fausse_api04_login'
$CafeTestLogin = 'cafe_fausse_api04_test_manager'
```

Confirm that the shell is at the correct repository and that the required
programs exist:

```powershell
if (-not (Test-Path -LiteralPath (Join-Path $CafeRepo 'backend\pyproject.toml'))) {
    throw 'Run this guide from the Cafe Fausse repository root.'
}

foreach ($CafeProgram in @('initdb.exe', 'pg_ctl.exe', 'psql.exe', 'createdb.exe')) {
    $CafeProgramPath = Join-Path $CafePgBin $CafeProgram
    if (-not (Test-Path -LiteralPath $CafeProgramPath)) {
        throw "Required PostgreSQL program not found: $CafeProgramPath"
    }
}

& (Join-Path $CafePgBin 'psql.exe') --version
py -3.14 --version
```

The PostgreSQL output must report `18.3`. Normal application metadata supports
standard 64-bit CPython 3.14.x, but the formal integration acceptance test
requires Windows Server 2025 and standard GIL-enabled 64-bit CPython 3.14.6.
Use that exact platform for a formal test run. If the `py` launcher is
unavailable, use `C:\Python314\python.exe` in the Python commands below.

## 2. Initialize and start a dedicated PostgreSQL cluster

Only initialize a new directory. Do not reuse an unknown cluster:

```powershell
if (Test-Path -LiteralPath $CafeClusterRoot) {
    throw "Refusing to overwrite an existing cluster directory: $CafeClusterRoot"
}

New-Item -ItemType Directory -Path $CafeClusterRoot | Out-Null

& (Join-Path $CafePgBin 'initdb.exe') `
    -D $CafeDataDir `
    -U $CafeAdminLogin `
    -W `
    --auth-host=scram-sha-256 `
    --auth-local=scram-sha-256 `
    --encoding=UTF8

if ($LASTEXITCODE -ne 0) {
    throw "initdb failed with exit code $LASTEXITCODE"
}

& (Join-Path $CafePgBin 'pg_ctl.exe') `
    -D $CafeDataDir `
    -l $CafeLogFile `
    -o "-p $CafePort -h 127.0.0.1" `
    -w start

if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL startup failed with exit code $LASTEXITCODE"
}
```

`initdb -W` prompts for the administrator password. Use a new nonproduction
password that is not used by either of the other logins.

## 3. Create and protect an external password file

Create the passfile outside the repository and restrict it to the current
Windows identity:

```powershell
$CafePassDirectory = Join-Path $env:APPDATA 'postgresql'
$CafePassFile = Join-Path $CafePassDirectory 'cafe_fausse_api04_pgpass.conf'
$CafeCurrentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

New-Item -ItemType Directory -Path $CafePassDirectory -Force | Out-Null
New-Item -ItemType File -Path $CafePassFile -Force | Out-Null
& icacls.exe $CafePassFile /inheritance:r /grant:r "$CafeCurrentIdentity`:(R,W)"

if ($LASTEXITCODE -ne 0) {
    throw 'Could not restrict the PostgreSQL passfile ACL.'
}

$env:PGPASSFILE = $CafePassFile
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
```

Using a trusted text editor, add the administrator entry below, replacing the
placeholder with the administrator password. Do not type a real password into
source control, documentation, screenshots, or shell history.

```text
127.0.0.1:55435:*:cafe_fausse_admin:<ADMIN_PASSWORD>
```

The PostgreSQL passfile format is
`hostname:port:database:username:password`. Escape a literal `:` or `\` in a
password with `\` as required by libpq.

## 4. Create and verify the nonproduction database

Create the empty database using the setup administrator:

```powershell
& (Join-Path $CafePgBin 'createdb.exe') `
    -h 127.0.0.1 `
    -p $CafePort `
    -U $CafeAdminLogin `
    --owner=$CafeAdminLogin `
    $CafeDatabase

if ($LASTEXITCODE -ne 0) {
    throw "createdb failed with exit code $LASTEXITCODE"
}

& (Join-Path $CafePgBin 'psql.exe') `
    -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 `
    -p $CafePort `
    -U $CafeAdminLogin `
    -d $CafeDatabase `
    -c "SELECT current_database(), current_setting('server_version_num');"
```

The result must identify `cafe_fausse_test_api04` and version number `180003`.
Do not continue if either value differs.

## 5. Build and verify the approved database baseline

Set the guarded database-script environment. The repository scripts verify
both the requested and actual database names before resetting the fixed
`cafe_fausse` schema.

```powershell
$env:CAFE_FAUSSE_PSQL = Join-Path $CafePgBin 'psql.exe'
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = $CafePort
$env:PGDATABASE = $CafeDatabase
$env:PGUSER = $CafeAdminLogin

& .\database\scripts\rebuild.ps1
if (-not $?) { throw 'Database rebuild failed.' }

& .\database\scripts\verify.ps1
if (-not $?) { throw 'Database verification failed.' }
```

The rebuild creates the passwordless capability roles
`cafe_fausse_owner`, `cafe_fausse_app`, and `cafe_fausse_test`. These are
group roles, not login accounts. The next step creates the two distinct login
accounts that receive only the required membership.

## 6. Create the deployment and test-management logins

Connect as the setup administrator:

```powershell
& (Join-Path $CafePgBin 'psql.exe') `
    -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 `
    -p $CafePort `
    -U $CafeAdminLogin `
    -d $CafeDatabase
```

At the `psql` prompt, run these one-time statements:

```sql
CREATE ROLE cafe_fausse_api04_login
    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    NOBYPASSRLS NOINHERIT;

CREATE ROLE cafe_fausse_api04_test_manager
    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    NOBYPASSRLS NOINHERIT;

GRANT cafe_fausse_app TO cafe_fausse_api04_login;
GRANT cafe_fausse_test TO cafe_fausse_api04_test_manager;

GRANT CONNECT ON DATABASE cafe_fausse_test_api04
    TO cafe_fausse_api04_login, cafe_fausse_api04_test_manager;

\password cafe_fausse_api04_login
\password cafe_fausse_api04_test_manager
\q
```

Use different generated passwords at the two password prompts. If a login
already exists, inspect it using the audit in the next step; do not drop or
replace it blindly.

Add exact-database entries for both login passwords to the protected passfile:

```text
127.0.0.1:55435:cafe_fausse_test_api04:cafe_fausse_api04_login:<APP_PASSWORD>
127.0.0.1:55435:cafe_fausse_test_api04:cafe_fausse_api04_test_manager:<TEST_MANAGER_PASSWORD>
```

## 7. Audit role separation before testing

Run the membership and login-attribute audit as the administrator:

```powershell
& (Join-Path $CafePgBin 'psql.exe') `
    -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 `
    -p $CafePort `
    -U $CafeAdminLogin `
    -d $CafeDatabase `
    -c @'
SELECT
    pg_has_role('cafe_fausse_api04_login', 'cafe_fausse_app', 'MEMBER') AS app_has_app,
    pg_has_role('cafe_fausse_api04_login', 'cafe_fausse_test', 'MEMBER') AS app_has_test,
    pg_has_role('cafe_fausse_api04_test_manager', 'cafe_fausse_test', 'MEMBER') AS test_has_test,
    pg_has_role('cafe_fausse_api04_test_manager', 'cafe_fausse_app', 'MEMBER') AS test_has_app;

SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole,
       rolreplication, rolbypassrls, rolinherit
FROM pg_roles
WHERE rolname IN (
    'cafe_fausse_api04_login',
    'cafe_fausse_api04_test_manager'
)
ORDER BY rolname;
'@
```

Required membership result: `true, false, true, false`. For both login rows,
only `rolcanlogin` may be true; `rolinherit` and every elevated attribute must
be false.

Confirm that each login can authenticate and assume only its intended group
role:

```powershell
& (Join-Path $CafePgBin 'psql.exe') -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeAppLogin -d $CafeDatabase `
    -c 'SET ROLE cafe_fausse_app; SELECT session_user, current_user; RESET ROLE;'

& (Join-Path $CafePgBin 'psql.exe') -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeTestLogin -d $CafeDatabase `
    -c 'SET ROLE cafe_fausse_test; SELECT session_user, current_user; RESET ROLE;'
```

## 8. Run the complete PostgreSQL test suite

Keep the administrator selected because the database runner performs guarded
rebuilds and provisions cluster roles:

```powershell
$env:PGUSER = $CafeAdminLogin
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'

& .\database\scripts\test.ps1
if (-not $?) { throw 'PostgreSQL test suite failed.' }
```

This suite checks the reset guard, fail-visible SQL behavior, DB-05 through
DB-07 behavior and privilege boundaries, repeated clean rebuilds, 20
concurrency iterations, performance samples, query plans, and final baseline
restoration. It is intentionally destructive to the `cafe_fausse` schema in
the selected isolated test database.

Expected permission-denied messages and the intentional division-by-zero
message are passing evidence. The runner returns success only when the expected
failures and all other checks behave correctly.

For a shorter read-only database check after the full suite, run:

```powershell
& .\database\scripts\verify.ps1
if (-not $?) { throw 'PostgreSQL verification failed.' }
```

## 9. Create or refresh the backend Python environment

Create the virtual environment once. If `backend\.venv` already contains the
approved environment, activate it and reinstall the editable test extras to
bring it up to date.

```powershell
if (-not (Test-Path -LiteralPath '.\backend\.venv\Scripts\python.exe')) {
    py -3.14 -m venv backend\.venv
}

.\backend\.venv\Scripts\Activate.ps1
python -m pip install --disable-pip-version-check -e "backend[test]"
python --version
python -c "import importlib.metadata as m; print({n: m.version(n) for n in ('Flask','psycopg','psycopg-binary','psycopg-pool','pytest','pytest-cov')})"
```

If `py` is unavailable, replace the environment-creation line with:

```powershell
C:\Python314\python.exe -m venv backend\.venv
```

Formal API-04 acceptance evidence expects Flask 3.1.3, psycopg 3.2.13,
psycopg-binary 3.2.13, psycopg-pool 3.2.8, pytest 9.1.1, and pytest-cov
7.1.0. The integration test fails visibly if the installed versions or formal
platform differ; do not report formal acceptance from a different platform or
dependency set.

## 10. Run backend unit and API tests without PostgreSQL

The default pytest selection is the combined unit and Flask API suite. These
tests do not require the database server:

```powershell
Set-Location $CafeRepo\backend

python -m pytest
if ($LASTEXITCODE -ne 0) { throw 'Default backend tests failed.' }

python -m pytest -m unit
if ($LASTEXITCODE -ne 0) { throw 'Backend unit tests failed.' }

python -m pytest -m api
if ($LASTEXITCODE -ne 0) { throw 'Backend API tests failed.' }

Set-Location $CafeRepo
```

Running all three commands is useful when producing separate unit and API
evidence; the first command already exercises both sets together. Test counts
may increase as later approved increments add tests, so success is determined
by pytest's exit code rather than a permanently fixed count.

## 11. Run backend PostgreSQL integration tests

Select the ordinary deployment login for the application connection and the
separate test-management login for fixture management. Keep both password
entries in `PGPASSFILE` so each connection authenticates with its own secret.

```powershell
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = $CafePort
$env:PGDATABASE = $CafeDatabase
$env:PGUSER = $CafeAppLogin
$env:CAFE_FAUSSE_TEST_MANAGER_USER = $CafeTestLogin
$env:CAFE_FAUSSE_TEST_PGDATA = $CafeDataDir
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

Set-Location $CafeRepo\backend
python -m pytest -m "integration and postgres"
$CafeIntegrationExit = $LASTEXITCODE
Set-Location $CafeRepo

if ($CafeIntegrationExit -ne 0) {
    throw 'Backend PostgreSQL integration tests failed.'
}
```

The formal recovery test validates that `$CafeDataDir` resolves beneath the
system temporary directory before it stops and restarts the PostgreSQL server.
The test is not safe for a shared cluster even when the database itself is
nonproduction.

## 12. Run the combined backend coverage gate

With the same application, test-management, database, passfile, and data
directory variables still set:

```powershell
Set-Location $CafeRepo\backend
python -m pytest -m "unit or api or integration" `
    --cov=cafe_fausse `
    --cov-report=term-missing
$CafeCoverageExit = $LASTEXITCODE
Set-Location $CafeRepo

if ($CafeCoverageExit -ne 0) {
    throw 'Combined backend coverage run failed.'
}
```

The command must exit zero. Review the missing-line report as well as the total
coverage number; do not hide new untested behavior behind an unchanged total.

## 13. Perform a manual Flask health smoke test

The database scripts and test manager use variables that are intentionally not
valid Flask application settings. Remove them before starting Flask, keep the
deployment login selected, and do not use the administrator or test manager as
the application identity:

```powershell
Remove-Item Env:CAFE_FAUSSE_ALLOW_RESET -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_PSQL -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_TEST_MANAGER_USER -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_TEST_PGDATA -ErrorAction SilentlyContinue

$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = $CafePort
$env:PGDATABASE = $CafeDatabase
$env:PGUSER = $CafeAppLogin

Set-Location $CafeRepo\backend
python -m flask --app cafe_fausse run
```

Leave that shell running. In a second PowerShell window, call both health
operations:

```powershell
Invoke-RestMethod http://127.0.0.1:5000/api/v1/health/liveness
Invoke-RestMethod http://127.0.0.1:5000/api/v1/health/readiness
```

Liveness must report `status = live`. Readiness must report
`status = ready`. Stop the Flask development server with `Ctrl+C`; it is only
for local verification and is not a production server.

## 14. Restore and prove the clean baseline

Automated integration tests manage their own data, but finish every formal run
by rebuilding with the administrator and verifying the empty approved
baseline:

```powershell
$env:CAFE_FAUSSE_PSQL = Join-Path $CafePgBin 'psql.exe'
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
$env:PGUSER = $CafeAdminLogin

& .\database\scripts\rebuild.ps1
if (-not $?) { throw 'Final database rebuild failed.' }

& .\database\scripts\verify.ps1
if (-not $?) { throw 'Final database verification failed.' }

& (Join-Path $CafePgBin 'psql.exe') -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeAdminLogin -d $CafeDatabase `
    -c @'
SELECT
    (SELECT count(*) FROM cafe_fausse.customers) AS customers,
    (SELECT count(*) FROM cafe_fausse.reservations) AS reservations,
    (SELECT count(*) FROM cafe_fausse.reservation_table_assignments) AS assignments,
    (SELECT count(*) FROM cafe_fausse.reservation_configuration) AS configurations,
    (SELECT count(*) FROM cafe_fausse.restaurant_operating_hours) AS operating_hours,
    (SELECT count(*) FROM cafe_fausse.restaurant_tables) AS restaurant_tables;
'@
```

The final counts must be `0, 0, 0, 1, 7, 30` in the displayed column order.

## 15. Run repository-level finishing checks

These checks catch Python syntax problems and accidental whitespace damage:

```powershell
Set-Location $CafeRepo
python -m compileall -q backend\src backend\tests
if ($LASTEXITCODE -ne 0) { throw 'Python compilation check failed.' }

git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed.' }

git status --short
```

Review `git status` and preserve unrelated user changes. Do not commit, push,
or create a pull request unless separately instructed.

## 16. Stop the disposable PostgreSQL server

After all tests and evidence collection are complete:

```powershell
& (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir -m fast -w stop
if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL shutdown failed with exit code $LASTEXITCODE"
}
```

Retain the stopped cluster if it will be reused for later API work. Before
deleting it, independently resolve and verify that its exact path is beneath
`$env:TEMP`; never recursively delete a path derived from an unchecked or empty
variable.

## Failure diagnosis

- If readiness returns HTTP 503, confirm that the dedicated server is running,
  the server version is 18.3, the passfile entry matches the deployment login,
  the login has only `cafe_fausse_app` membership, and the rebuild and verifier
  succeed.
- If Flask reports an unknown `CAFE_FAUSSE_*` setting, remove database-script
  and test-only variables as shown in the manual smoke-test step.
- If authentication fails for only one identity, check that identity's exact
  passfile entry and password. Do not work around the problem by giving the
  application the administrator or test-management credentials.
- If the recovery test refuses the data path, do not weaken its check. Create a
  genuinely disposable cluster beneath the Windows temporary directory.
- If a database test leaves test data after a failure, run the guarded final
  rebuild and verifier as the administrator before continuing.
- Do not paste passfile contents, passwords, or connection strings into logs or
  issue reports.

## Related repository documentation

- [Backend README](README.md)
- [API-04 implementation report](API04_IMPLEMENTATION_REPORT.md)
- [Database README](../database/README.md)
- [PostgreSQL contract for Flask](../database/POSTGRESQL_CONTRACT_FOR_FLASK.md)
