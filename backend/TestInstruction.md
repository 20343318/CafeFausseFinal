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
- Give all three logins different passwords. Either store them outside the
  repository in a protected PostgreSQL passfile or enter the password for the
  current identity at a secure interactive prompt. Never commit passwords,
  passfiles, connection URLs, or environment dumps.
- Use `PGPASSFILE` or `PGPASSWORD`, never both. The helper in Step 3 enforces
  this choice. Because the integration suite connects as two differently
  credentialed logins in one process, Steps 11 and 12 require `PGPASSFILE`.
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

$CafePsqlVersion = & (Join-Path $CafePgBin 'psql.exe') --version
if ($LASTEXITCODE -ne 0 -or $CafePsqlVersion -notmatch '18\.3') {
    throw "Expected PostgreSQL 18.3; received: $CafePsqlVersion"
}

$CafePythonExecutable = $null
$CafePythonLauncherArguments = @()
$CafePyLauncher = Get-Command py -ErrorAction SilentlyContinue

if ($null -ne $CafePyLauncher) {
    $CafePythonExecutable = $CafePyLauncher.Source
    $CafePythonLauncherArguments = @('-3.14')
}

if ($null -eq $CafePythonExecutable -and (Test-Path -LiteralPath 'C:\Python314\python.exe')) {
    $CafePythonExecutable = 'C:\Python314\python.exe'
}

if ($null -eq $CafePythonExecutable) {
    throw 'Could not find the approved CPython 3.14 interpreter.'
}

$CafePythonVersion = & $CafePythonExecutable @CafePythonLauncherArguments --version 2>&1
$CafePythonVersionExitCode = $LASTEXITCODE
if ($CafePythonVersionExitCode -ne 0 -or $CafePythonVersion -notmatch '^Python 3\.14\.6$') {
    throw "Formal acceptance requires CPython 3.14.6; received: $CafePythonVersion"
}

Write-Host "STEP 1 PASS: isolated target variables defined; $CafePsqlVersion; $CafePythonVersion"
```

The PostgreSQL output must report `18.3`. Normal application metadata supports
standard 64-bit CPython 3.14.x, but the formal integration acceptance test
requires Windows Server 2025 and standard GIL-enabled 64-bit CPython 3.14.6.
Use that exact platform for a formal test run. Step 1 records either the `py`
launcher or `C:\Python314\python.exe` in `$CafePythonExecutable` for reuse by
later steps.

Expected verification output contains:

```text
STEP 1 PASS: isolated target variables defined; psql (PostgreSQL) 18.3; Python 3.14.6
```

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

$CafeServerStatus = & (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir status 2>&1
if ($LASTEXITCODE -ne 0 -or $CafeServerStatus -notmatch 'server is running') {
    throw "PostgreSQL status check failed: $CafeServerStatus"
}

Write-Host "STEP 2 PASS: dedicated PostgreSQL cluster is running on 127.0.0.1:$CafePort"
```

`initdb -W` prompts for the administrator password. Use a new nonproduction
password that is not used by either of the other logins.

Expected verification output contains the `pg_ctl` startup message followed
by:

```text
STEP 2 PASS: dedicated PostgreSQL cluster is running on 127.0.0.1:55435
```

## 3. Select a protected external file or secure interactive password

Define the external passfile location. Do not create an empty file unless you
intend to use the passfile option; an absent file activates the interactive
fallback below.

```powershell
$CafePassDirectory = Join-Path $env:APPDATA 'postgresql'
$CafePassFile = Join-Path $CafePassDirectory 'cafe_fausse_api04_pgpass.conf'
$CafeCurrentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
```

### Option A: protected external passfile

To use an external passfile, create it outside the repository and restrict it
to the current Windows identity:

```powershell
New-Item -ItemType Directory -Path $CafePassDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $CafePassFile)) {
    New-Item -ItemType File -Path $CafePassFile | Out-Null
}

& icacls.exe $CafePassFile /inheritance:r /grant:r "$CafeCurrentIdentity`:(R,W)"

if ($LASTEXITCODE -ne 0) {
    throw 'Could not restrict the PostgreSQL passfile ACL.'
}
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

### Option B: secure interactive prompt when the file is absent

If `$CafePassFile` does not exist, the helper below reads the current login's
password without echoing it, converts it only for the process environment, and
sets `PGPASSWORD`. If the passfile exists, the same helper selects
`PGPASSFILE`. It always removes the other variable first so both are never set.

```powershell
function Set-CafeFausseCredential {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

    if (Test-Path -LiteralPath $CafePassFile -PathType Leaf) {
        if ((Get-Item -LiteralPath $CafePassFile).Length -eq 0) {
            throw "The external passfile exists but is empty: $CafePassFile"
        }

        & icacls.exe $CafePassFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot read the passfile ACL: $CafePassFile"
        }

        $env:PGPASSFILE = $CafePassFile
        Write-Host 'STEP 3 PASS: credential source is the protected external PGPASSFILE.'
        return
    }

    $securePassword = Read-Host $Prompt -AsSecureString
    $env:PGPASSWORD = [System.Net.NetworkCredential]::new('', $securePassword).Password
    Remove-Variable securePassword

    if ([string]::IsNullOrEmpty($env:PGPASSWORD)) {
        throw 'The interactive PostgreSQL password was empty.'
    }

    Write-Host 'STEP 3 PASS: credential source is interactive PGPASSWORD for this PowerShell process.'
}

Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"
```

Expected verification output is exactly one of:

```text
STEP 3 PASS: credential source is the protected external PGPASSFILE.
STEP 3 PASS: credential source is interactive PGPASSWORD for this PowerShell process.
```

The interactive value is plain text only after assignment to the current
process environment, which is necessary for libpq. It is inherited by child
processes, so clear it with `Remove-Item Env:PGPASSWORD` when testing is done.
Run `Set-CafeFausseCredential` again with the appropriate identity in the
prompt whenever a later step changes logins. Do not print either credential
environment variable.

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

$CafeDatabaseEvidence = & (Join-Path $CafePgBin 'psql.exe') `
    -X -tA -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 `
    -p $CafePort `
    -U $CafeAdminLogin `
    -d $CafeDatabase `
    -c "SELECT current_database() || '|' || current_setting('server_version_num');"

if ($LASTEXITCODE -ne 0 -or $CafeDatabaseEvidence.Trim() -ne "$CafeDatabase|180003") {
    throw "Unexpected database evidence: $CafeDatabaseEvidence"
}

Write-Host "STEP 4 PASS: database=$CafeDatabase; server_version_num=180003"
```

The result must identify `cafe_fausse_test_api04` and version number `180003`.
Do not continue if either value differs.

Expected verification output:

```text
STEP 4 PASS: database=cafe_fausse_test_api04; server_version_num=180003
```

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

Write-Host 'STEP 5 PASS: approved database baseline rebuilt and verified.'
```

The rebuild creates the passwordless capability roles
`cafe_fausse_owner`, `cafe_fausse_app`, and `cafe_fausse_test`. These are
group roles, not login accounts. The next step creates the two distinct login
accounts that receive only the required membership.

Expected verification output ends with:

```text
STEP 5 PASS: approved database baseline rebuilt and verified.
```

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

SELECT 'STEP 6 PASS: deployment and test-management logins created and passworded.'
    AS verification;
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

If Step 3 selected the interactive fallback, do not create a credential file
here merely by copying placeholders. Later single-login commands will prompt
for the applicable password. The two-login integration and coverage runs in
Steps 11 and 12 require a completed protected passfile with all three entries.

Expected `psql` output includes `CREATE ROLE`, `GRANT ROLE`, `GRANT`, and:

```text
STEP 6 PASS: deployment and test-management logins created and passworded.
```

## 7. Audit role separation before testing

Run the membership and login-attribute audit as the administrator:

```powershell
Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"

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

if ($LASTEXITCODE -ne 0) { throw 'Role membership audit failed.' }
```

Required membership result: `true, false, true, false`. For both login rows,
only `rolcanlogin` may be true; `rolinherit` and every elevated attribute must
be false.

Confirm that each login can authenticate and assume only its intended group
role:

```powershell
Set-CafeFausseCredential -Prompt "Password for $CafeAppLogin"
& (Join-Path $CafePgBin 'psql.exe') -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeAppLogin -d $CafeDatabase `
    -c 'SET ROLE cafe_fausse_app; SELECT session_user, current_user; RESET ROLE;'
if ($LASTEXITCODE -ne 0) { throw 'Deployment-login authentication failed.' }

Set-CafeFausseCredential -Prompt "Password for $CafeTestLogin"
& (Join-Path $CafePgBin 'psql.exe') -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeTestLogin -d $CafeDatabase `
    -c 'SET ROLE cafe_fausse_test; SELECT session_user, current_user; RESET ROLE;'
if ($LASTEXITCODE -ne 0) { throw 'Test-management-login authentication failed.' }

Write-Host 'STEP 7 PASS: role separation and both login paths verified.'
```

The audit tables must show `t | f | t | f`; only `rolcanlogin` is true for
each login. The two authentication queries must respectively show
`cafe_fausse_app` and `cafe_fausse_test` as `current_user`. Expected final
verbiage:

```text
STEP 7 PASS: role separation and both login paths verified.
```

## 8. Run the complete PostgreSQL test suite

Keep the administrator selected because the database runner performs guarded
rebuilds and provisions cluster roles:

```powershell
Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"
$env:PGUSER = $CafeAdminLogin
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'

& .\database\scripts\test.ps1
if (-not $?) { throw 'PostgreSQL test suite failed.' }

Write-Host 'STEP 8 PASS: complete PostgreSQL test suite passed and restored its baseline.'
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

The full runner should end with
`DB-05/DB-06 regression and DB-07 automated gate suites completed successfully.`
Expected step verbiage:

```text
STEP 8 PASS: complete PostgreSQL test suite passed and restored its baseline.
```

## 9. Create or refresh the backend Python environment

Create the virtual environment once. If `backend\.venv` already contains the
approved environment, activate it and reinstall the editable test extras to
bring it up to date.

```powershell
if (-not (Test-Path -LiteralPath '.\backend\.venv\Scripts\python.exe')) {
    & $CafePythonExecutable @CafePythonLauncherArguments -m venv backend\.venv
    if ($LASTEXITCODE -ne 0) { throw 'Backend virtual-environment creation failed.' }
}

.\backend\.venv\Scripts\Activate.ps1
python -m pip install --disable-pip-version-check -e "backend[test]"
if ($LASTEXITCODE -ne 0) { throw 'Backend test dependency installation failed.' }

$CafePythonVersion = python -c "import platform; print(platform.python_version())"
$CafePackageVersions = python -c "import importlib.metadata as m; print('|'.join(m.version(n) for n in ('Flask','psycopg','psycopg-binary','psycopg-pool','pytest','pytest-cov')))"

if ($CafePythonVersion.Trim() -ne '3.14.6') {
    throw "Expected CPython 3.14.6; received $CafePythonVersion"
}
if ($CafePackageVersions.Trim() -ne '3.1.3|3.2.13|3.2.13|3.2.8|9.1.1|7.1.0') {
    throw "Unexpected backend package versions: $CafePackageVersions"
}

Write-Host "STEP 9 PASS: Python $CafePythonVersion; packages=$CafePackageVersions"
```

Formal API-04 acceptance evidence expects Flask 3.1.3, psycopg 3.2.13,
psycopg-binary 3.2.13, psycopg-pool 3.2.8, pytest 9.1.1, and pytest-cov
7.1.0. The integration test fails visibly if the installed versions or formal
platform differ; do not report formal acceptance from a different platform or
dependency set.

Expected verification output:

```text
STEP 9 PASS: Python 3.14.6; packages=3.1.3|3.2.13|3.2.13|3.2.8|9.1.1|7.1.0
```

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
Write-Host 'STEP 10 PASS: default, unit, and API backend test selections passed.'
```

Running all three commands is useful when producing separate unit and API
evidence; the first command already exercises both sets together. Test counts
may increase as later approved increments add tests, so success is determined
by pytest's exit code rather than a permanently fixed count.

Each pytest run must contain a green summary ending in `passed`. Expected
final verbiage:

```text
STEP 10 PASS: default, unit, and API backend test selections passed.
```

## 11. Run backend PostgreSQL integration tests

Select the ordinary deployment login for the application connection and the
separate test-management login for fixture management. Keep both password
entries in `PGPASSFILE` so each connection authenticates with its own secret.

```powershell
if (-not (Test-Path -LiteralPath $CafePassFile -PathType Leaf)) {
    throw 'Steps 11 and 12 require the protected passfile because pytest opens two differently credentialed login connections in one process.'
}

Set-CafeFausseCredential -Prompt 'This prompt is not used when the required passfile exists'

foreach ($CafeRequiredLogin in @($CafeAppLogin, $CafeTestLogin)) {
    if (-not (Select-String -LiteralPath $CafePassFile -SimpleMatch ":${CafeRequiredLogin}:" -Quiet)) {
        throw "The passfile has no entry for required login: $CafeRequiredLogin"
    }
}

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

Write-Host 'STEP 11 PASS: backend PostgreSQL integration and recovery tests passed.'
```

The formal recovery test validates that `$CafeDataDir` resolves beneath the
system temporary directory before it stops and restarts the PostgreSQL server.
The test is not safe for a shared cluster even when the database itself is
nonproduction.

Pytest must show a summary ending in `passed`, including the marked recovery
test. Expected final verbiage:

```text
STEP 11 PASS: backend PostgreSQL integration and recovery tests passed.
```

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

Write-Host 'STEP 12 PASS: combined unit, API, integration, and coverage run passed.'
```

The command must exit zero. Review the missing-line report as well as the total
coverage number; do not hide new untested behavior behind an unchanged total.

The coverage report must contain a `TOTAL` row and pytest must end in `passed`.
Expected final verbiage:

```text
STEP 12 PASS: combined unit, API, integration, and coverage run passed.
```

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

Set-CafeFausseCredential -Prompt "Password for $CafeAppLogin"

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
$CafeLiveness = Invoke-RestMethod http://127.0.0.1:5000/api/v1/health/liveness
$CafeReadiness = Invoke-RestMethod http://127.0.0.1:5000/api/v1/health/readiness

if ($CafeLiveness.status -ne 'live') {
    throw "Unexpected liveness response: $($CafeLiveness | ConvertTo-Json -Compress)"
}
if ($CafeReadiness.status -ne 'ready') {
    throw "Unexpected readiness response: $($CafeReadiness | ConvertTo-Json -Compress)"
}

Write-Host 'STEP 13 PASS: Flask liveness=live; readiness=ready.'
```

Liveness must report `status = live`. Readiness must report
`status = ready`. Stop the Flask development server with `Ctrl+C`; it is only
for local verification and is not a production server.

The server shell should contain `Running on http://127.0.0.1:5000`. Expected
verification output in the second shell:

```text
STEP 13 PASS: Flask liveness=live; readiness=ready.
```

## 14. Restore and prove the clean baseline

Automated integration tests manage their own data, but finish every formal run
by rebuilding with the administrator and verifying the empty approved
baseline:

```powershell
Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"
$env:CAFE_FAUSSE_PSQL = Join-Path $CafePgBin 'psql.exe'
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
$env:PGUSER = $CafeAdminLogin

& .\database\scripts\rebuild.ps1
if (-not $?) { throw 'Final database rebuild failed.' }

& .\database\scripts\verify.ps1
if (-not $?) { throw 'Final database verification failed.' }

$CafeBaselineCounts = & (Join-Path $CafePgBin 'psql.exe') -X -tA -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeAdminLogin -d $CafeDatabase `
    -c @'
SELECT concat_ws('|',
    (SELECT count(*) FROM cafe_fausse.customers),
    (SELECT count(*) FROM cafe_fausse.reservations),
    (SELECT count(*) FROM cafe_fausse.reservation_table_assignments),
    (SELECT count(*) FROM cafe_fausse.reservation_configuration),
    (SELECT count(*) FROM cafe_fausse.restaurant_operating_hours),
    (SELECT count(*) FROM cafe_fausse.restaurant_tables)
);
'@

if ($LASTEXITCODE -ne 0 -or $CafeBaselineCounts.Trim() -ne '0|0|0|1|7|30') {
    throw "Unexpected final baseline counts: $CafeBaselineCounts"
}

Write-Host 'STEP 14 PASS: clean baseline counts=0|0|0|1|7|30.'
```

The final counts must be `0, 0, 0, 1, 7, 30` in the displayed column order.

Expected verification output:

```text
STEP 14 PASS: clean baseline counts=0|0|0|1|7|30.
```

## 15. Run repository-level finishing checks

These checks catch Python syntax problems and accidental whitespace damage:

```powershell
Set-Location $CafeRepo
python -m compileall -q backend\src backend\tests
if ($LASTEXITCODE -ne 0) { throw 'Python compilation check failed.' }

git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git whitespace check failed.' }

git status --short

Write-Host 'STEP 15 PASS: Python compilation and Git whitespace checks passed; status displayed above.'
```

Review `git status` and preserve unrelated user changes. Do not commit, push,
or create a pull request unless separately instructed.

`git status --short` may be empty in a clean checkout or list only intentional
changes. Expected final verbiage:

```text
STEP 15 PASS: Python compilation and Git whitespace checks passed; status displayed above.
```

## 16. Stop the disposable PostgreSQL server

After all tests and evidence collection are complete:

```powershell
& (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir -m fast -w stop
if ($LASTEXITCODE -ne 0) {
    throw "PostgreSQL shutdown failed with exit code $LASTEXITCODE"
}

$CafeStoppedStatus = & (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir status 2>&1
if ($LASTEXITCODE -eq 0 -or $CafeStoppedStatus -notmatch 'no server running') {
    throw "PostgreSQL still appears to be running: $CafeStoppedStatus"
}

Write-Host $CafeStoppedStatus
Write-Host 'STEP 16 PASS: disposable PostgreSQL server is stopped.'
```

Retain the stopped cluster if it will be reused for later API work. Before
deleting it, independently resolve and verify that its exact path is beneath
`$env:TEMP`; never recursively delete a path derived from an unchecked or empty
variable.

Expected output contains `server stopped`, `no server running`, and:

```text
STEP 16 PASS: disposable PostgreSQL server is stopped.
```

## Failure diagnosis

- If readiness returns HTTP 503, confirm that the dedicated server is running,
  the server version is 18.3, the selected credential source matches the
  deployment login, the login has only `cafe_fausse_app` membership, and the
  rebuild and verifier succeed.
- If Flask reports an unknown `CAFE_FAUSSE_*` setting, remove database-script
  and test-only variables as shown in the manual smoke-test step.
- If authentication fails for only one identity, check that identity's exact
  passfile entry or rerun `Set-CafeFausseCredential` and carefully enter that
  identity's password. Do not work around the problem by giving the
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
