# Cafe Fausse testing and safe nonproduction database instructions

This guide puts the Cafe Fausse database and backend test workflow in the
order in which it should be performed. Run the commands from the repository
root in Windows PowerShell unless a step says otherwise.

This is a user-requested programmer-convenience runbook. It is not required by
the SRS or rubric and is not an approved requirements or design authority.

## API-07 recommended complete workflow

API-01 through API-06 are approved. API-07 is the current unapproved review
increment. API-08, reservation creation, React, integration, and database
changes are not authorized by this workflow.

Run the complete API-07 gate from the repository root in Windows PowerShell
5.1. It requires CPython 3.14.6, PostgreSQL 18.3, and explicit nonproduction
authorization:

```powershell
& .\backend\tests\run_api07.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The runner refuses a preexisting `%TEMP%\CafeFausse-api07-tests` root. On a
new run it writes and validates `ownership.json` before starting the contained
runner. API-07 passes API-06 the explicit independent sibling root
`%TEMP%\CafeFausse-api07-contained-api06-tests`; it never redirects `TEMP` or
`TMP` into the API-07 root. The contained runner records its own ownership and
keeps PostgreSQL data, venv, pip cache, coverage, and process-temporary paths
as shallow siblings beneath its root. Ordinary tests set
`PYTHONDONTWRITEBYTECODE=1`, remove inherited `PYTHONPYCACHEPREFIX`, disable
pytest's cache provider, and use pip `--no-compile`. Cleanup validates and
removes the two roots independently, rejecting missing markers, mismatches,
reparse points, containment failures, unproved processes, or listeners.

### Artifact-safe focused API-07 verification

The focused workflow below is restartable and refuses a preexisting root. It
uses shallow venv, pip-cache, coverage, and process-temp paths beneath the
marker-owned `%TEMP%\CafeFausse-api07-focused` root. Each resource's marker is
written before that resource is created. Routine bytecode and pytest caching
are disabled. The final `finally` phase restores every changed environment value,
validates the exact canonical root, repository identity, owner ID, marker,
containment, and absence of reparse-point descendants, removes only that
root, and verifies absence.

Set `$CafeRunApi07FocusedPostgres` to `$true` only when the current environment
already identifies a separately ownership-proven disposable PostgreSQL 18.3
cluster through `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`,
`CAFE_FAUSSE_TEST_MANAGER_USER`, and `CAFE_FAUSSE_API07_ADMIN_USER`. The
focused workflow creates no cluster and neither adopts nor deletes that
external resource. Its API-07 fixture changes use the approved test seams and
restore themselves. A missing explicit authorization causes refusal.

```powershell
$ErrorActionPreference = 'Stop'
$CafeRepo = [IO.Path]::GetFullPath((Get-Location).Path).TrimEnd('\')
$CafeOriginalTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
$CafeFocusedRoot = [IO.Path]::GetFullPath(
    (Join-Path $CafeOriginalTemp 'CafeFausse-api07-focused')
).TrimEnd('\')
$CafeFocusedMarker = Join-Path $CafeFocusedRoot 'ownership.json'
$CafeFocusedOwner = 'cafe-fausse-api07-focused-prompt16'
$CafeFocusedVenv = Join-Path $CafeFocusedRoot 'venv'
$CafeFocusedPipCache = Join-Path $CafeFocusedRoot 'pip-cache'
$CafeFocusedCoverageRoot = Join-Path $CafeFocusedRoot 'coverage'
$CafeFocusedProcessTemp = Join-Path $CafeFocusedRoot 'process-temp'
$CafeFocusedResources = @(
    @{ Name = 'venv'; Root = $CafeFocusedVenv; Purpose = 'focused disposable venv' },
    @{ Name = 'pip-cache'; Root = $CafeFocusedPipCache; Purpose = 'focused pip cache' },
    @{ Name = 'coverage'; Root = $CafeFocusedCoverageRoot; Purpose = 'focused coverage data' },
    @{ Name = 'process-temp'; Root = $CafeFocusedProcessTemp; Purpose = 'focused process temporary files' }
)
$CafeRunApi07FocusedPostgres = $false
$CafeApi07FocusedPostgresAuthorization = $null
$CafeFocusedNames = @(
    'TEMP', 'TMP', 'PYTHONPATH', 'PYTHONDONTWRITEBYTECODE', 'PYTHONPYCACHEPREFIX',
    'COVERAGE_FILE', 'PIP_CACHE_DIR', 'PYTEST_ADDOPTS'
)
$CafeFocusedPrior = @{}
foreach ($CafeFocusedName in $CafeFocusedNames) {
    $CafeFocusedPrior[$CafeFocusedName] =
        [Environment]::GetEnvironmentVariable($CafeFocusedName, 'Process')
}
$CafeFocusedCreated = $false
$CafeFocusedFailure = $null

function Assert-CafeApi07FocusedOwnership {
    $CafeExpectedFocusedRoot = [IO.Path]::GetFullPath(
        (Join-Path $CafeOriginalTemp 'CafeFausse-api07-focused')
    ).TrimEnd('\')
    if ($CafeFocusedRoot -cne $CafeExpectedFocusedRoot) {
        throw 'The focused API-07 root canonical path changed.'
    }
    if (-not (Test-Path -LiteralPath $CafeFocusedRoot -PathType Container)) {
        throw 'The focused API-07 root is absent.'
    }
    $CafeFocusedRootItem = Get-Item -LiteralPath $CafeFocusedRoot -Force
    if (($CafeFocusedRootItem.Attributes -band
            [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'The focused API-07 root is a reparse point.'
    }
    if (-not (Test-Path -LiteralPath $CafeFocusedMarker -PathType Leaf)) {
        throw 'The focused API-07 ownership marker is absent.'
    }
    $CafeFocusedMarkerItem = Get-Item -LiteralPath $CafeFocusedMarker -Force
    if (($CafeFocusedMarkerItem.Attributes -band
            [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'The focused API-07 marker is a reparse point.'
    }
    $CafeFocusedValue =
        Get-Content -LiteralPath $CafeFocusedMarker -Raw | ConvertFrom-Json
    if ($CafeFocusedValue.task -cne 'API-07' -or
        $CafeFocusedValue.phase -cne 'Prompt-16-focused-verification' -or
        $CafeFocusedValue.repository -cne $CafeRepo -or
        $CafeFocusedValue.owner_id -cne $CafeFocusedOwner -or
        $CafeFocusedValue.root -cne $CafeFocusedRoot) {
        throw 'The focused API-07 ownership marker does not match.'
    }
}

function Remove-CafeApi07FocusedRoot {
    Assert-CafeApi07FocusedOwnership
    foreach ($CafeFocusedResource in $CafeFocusedResources) {
        $CafeFocusedResourceMarker = Join-Path $CafeFocusedRoot (
            '.' + $CafeFocusedResource.Name + '.ownership.json'
        )
        if (-not (Test-Path -LiteralPath $CafeFocusedResourceMarker -PathType Leaf)) {
            throw 'A focused resource ownership marker is absent.'
        }
        $CafeFocusedResourceValue = Get-Content -LiteralPath `
            $CafeFocusedResourceMarker -Raw | ConvertFrom-Json
        if ($CafeFocusedResourceValue.repository -cne $CafeRepo -or
            $CafeFocusedResourceValue.task -cne 'API-07' -or
            $CafeFocusedResourceValue.phase -cne 'Prompt-16-focused-verification' -or
            $CafeFocusedResourceValue.purpose -cne $CafeFocusedResource.Purpose -or
            $CafeFocusedResourceValue.owner_id -cne (
                $CafeFocusedOwner + '-' + $CafeFocusedResource.Name
            ) -or
            $CafeFocusedResourceValue.root -cne $CafeFocusedResource.Root) {
            throw 'A focused resource ownership marker does not match.'
        }
    }
    $CafeFocusedPrefix = $CafeFocusedRoot + '\'
    foreach ($CafeFocusedItem in
        Get-ChildItem -LiteralPath $CafeFocusedRoot -Force -Recurse) {
        $CafeFocusedFullPath =
            [IO.Path]::GetFullPath($CafeFocusedItem.FullName)
        if (-not $CafeFocusedFullPath.StartsWith(
            $CafeFocusedPrefix,
            [StringComparison]::OrdinalIgnoreCase
        )) {
            throw 'A focused API-07 descendant escaped the owned root.'
        }
        if (($CafeFocusedItem.Attributes -band
                [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'A focused API-07 descendant is a reparse point.'
        }
    }
    Remove-Item -LiteralPath $CafeFocusedRoot -Recurse -Force
    if (Test-Path -LiteralPath $CafeFocusedRoot) {
        throw 'The focused API-07 root survived cleanup.'
    }
}

try {
    if (Test-Path -LiteralPath $CafeFocusedRoot) {
        throw 'Refusing a preexisting or ambiguous focused API-07 root.'
    }
    New-Item -ItemType Directory -Path $CafeFocusedRoot | Out-Null
    $CafeFocusedCreated = $true
    $CafeFocusedMarkerValue = [ordered]@{
        task = 'API-07'
        phase = 'Prompt-16-focused-verification'
        purpose = 'artifact-confined focused API-07 verification'
        repository = $CafeRepo
        owner_id = $CafeFocusedOwner
        root = $CafeFocusedRoot
    } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText(
        $CafeFocusedMarker,
        $CafeFocusedMarkerValue + "`n",
        (New-Object Text.UTF8Encoding($false))
    )
    Assert-CafeApi07FocusedOwnership
    foreach ($CafeFocusedResource in $CafeFocusedResources) {
        $CafeFocusedResourceMarker = Join-Path $CafeFocusedRoot (
            '.' + $CafeFocusedResource.Name + '.ownership.json'
        )
        $CafeFocusedResourceValue = [ordered]@{
            repository = $CafeRepo
            task = 'API-07'
            phase = 'Prompt-16-focused-verification'
            purpose = $CafeFocusedResource.Purpose
            owner_id = $CafeFocusedOwner + '-' + $CafeFocusedResource.Name
            root = $CafeFocusedResource.Root
        } | ConvertTo-Json -Compress
        [IO.File]::WriteAllText(
            $CafeFocusedResourceMarker,
            $CafeFocusedResourceValue + "`n",
            (New-Object Text.UTF8Encoding($false))
        )
    }
    New-Item -ItemType Directory -Path $CafeFocusedCoverageRoot | Out-Null
    New-Item -ItemType Directory -Path $CafeFocusedProcessTemp | Out-Null
    $env:TEMP = $CafeFocusedProcessTemp
    $env:TMP = $CafeFocusedProcessTemp
    $env:PYTHONPATH = Join-Path $CafeRepo 'backend\src'
    $env:PYTHONDONTWRITEBYTECODE = '1'
    Remove-Item Env:PYTHONPYCACHEPREFIX -ErrorAction SilentlyContinue
    $env:COVERAGE_FILE = Join-Path $CafeFocusedCoverageRoot '.coverage'
    $env:PIP_CACHE_DIR = $CafeFocusedPipCache
    $env:PYTEST_ADDOPTS = '-p no:cacheprovider'
    & 'C:\Python314\python.exe' -m venv --without-pip $CafeFocusedVenv
    if ($LASTEXITCODE -ne 0) { throw 'Focused API-07 venv creation failed.' }
    $CafeFocusedPython = Join-Path $CafeFocusedVenv 'Scripts\python.exe'
    & 'C:\Python314\python.exe' -m pip --python $CafeFocusedPython install `
        --disable-pip-version-check --quiet --no-compile `
        --cache-dir $env:PIP_CACHE_DIR `
        'Flask==3.1.3' 'psycopg[binary]==3.2.13' `
        'psycopg-pool==3.2.8' 'pytest==9.1.1' 'pytest-cov==7.1.0'
    if ($LASTEXITCODE -ne 0) { throw 'Focused dependency setup failed.' }
    Assert-CafeApi07FocusedOwnership

    Push-Location (Join-Path $CafeRepo 'backend')
    try {
        & $CafeFocusedPython -m pytest `
            tests\unit\test_validation_reservation.py `
            tests\unit\test_reservation_gateways.py `
            tests\unit\test_reservation_services.py
        if ($LASTEXITCODE -ne 0) { throw 'Focused OP-01/OP-02 tests failed.' }
        & $CafeFocusedPython -m pytest `
            tests\api\test_reservation_discovery.py
        if ($LASTEXITCODE -ne 0) { throw 'Focused Flask API tests failed.' }
        if ($CafeRunApi07FocusedPostgres) {
            if ($CafeApi07FocusedPostgresAuthorization -cne
                'AUTHORIZED_NONPRODUCTION') {
                throw 'Focused PostgreSQL authorization is missing.'
            }
            & $CafeFocusedPython -m pytest `
                tests\integration\test_reservation_discovery_postgresql.py `
                -m 'integration and postgres'
            if ($LASTEXITCODE -ne 0) {
                throw 'Focused PostgreSQL API-07 tests failed.'
            }
        }
    }
    finally {
        Pop-Location
    }
}
catch {
    $CafeFocusedFailure = $_
}
finally {
    foreach ($CafeFocusedName in $CafeFocusedNames) {
        if ($null -eq $CafeFocusedPrior[$CafeFocusedName]) {
            [Environment]::SetEnvironmentVariable(
                $CafeFocusedName, $null, 'Process'
            )
        }
        else {
            [Environment]::SetEnvironmentVariable(
                $CafeFocusedName,
                [string]$CafeFocusedPrior[$CafeFocusedName],
                'Process'
            )
        }
    }
    if ($CafeFocusedCreated -and
        (Test-Path -LiteralPath $CafeFocusedRoot)) {
        try {
            Remove-CafeApi07FocusedRoot
        }
        catch {
            if ($null -eq $CafeFocusedFailure) { $CafeFocusedFailure = $_ }
            else {
                Write-Warning (
                    'Focused cleanup failed; the owned root was preserved: ' +
                    $_.Exception.Message
                )
            }
        }
    }
}
if ($null -ne $CafeFocusedFailure) { throw $CafeFocusedFailure }
if (Test-Path -LiteralPath $CafeFocusedRoot) {
    throw 'Final focused API-07 root-absence verification failed.'
}
Write-Host 'API07 FOCUSED CLEANUP PASS: exact owned root is absent.'
```

To demonstrate ordinary failure cleanup and immediate restart:

```powershell
try {
    & .\backend\tests\run_api07.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' -InjectFailure
    throw 'The controlled API-07 failure unexpectedly passed.'
}
catch {
    $CafeOrdinaryRoots = @(
        (Join-Path $env:TEMP 'CafeFausse-api07-tests'),
        (Join-Path $env:TEMP 'CafeFausse-api07-contained-api06-tests')
    )
    if (@($CafeOrdinaryRoots | Where-Object { Test-Path -LiteralPath $_ }).Count -ne 0) {
        throw 'The controlled ordinary failure left an owned runner root behind.'
    }
}
& .\backend\tests\run_api07.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

To demonstrate a controlled cleanup failure and later exact recovery:

```powershell
try {
    & .\backend\tests\run_api07.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' -InjectCleanupFailure
    throw 'The controlled API-07 cleanup failure unexpectedly passed.'
}
catch {
    if (-not (Test-Path -LiteralPath (Join-Path $env:TEMP 'CafeFausse-api07-tests'))) {
        throw 'The controlled cleanup failure did not preserve its owned root.'
    }
}
& .\backend\tests\run_api07.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' -CleanupOwnedRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The actual interruption/recovery test uses the real API-07 runner launching the
real contained API-06 runner. The expected preparation exit is `86`:

```powershell
$CafePowerShell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
& $CafePowerShell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File .\backend\tests\run_api07.ps1 `
    -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' `
    -PrepareInterruptionState
if ($LASTEXITCODE -ne 86) {
    throw "Interruption preparation returned unexpected exit $LASTEXITCODE."
}
& .\backend\tests\run_api07.ps1 `
    -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' `
    -CleanupOwnedRoot
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Preparation keeps the outer process alive while the contained runner creates
its independently marker-owned sibling root and holds its live PostgreSQL 18.3
cluster. Empty, partial, or temporarily unparsable `postmaster.pid` content is
retried until timeout. Before the outer runner exits, it proves the postmaster
and sole port-55446 listener, writes the contained runner's PID, executable,
parent, command hash, start time, purpose, relationship, and both root paths
using write-through I/O, rereads the marker, and revalidates process/listener
identity. Recovery validates both sibling roots, stops PostgreSQL, verifies
zero listeners, validates and terminates the recorded held process, removes
the contained root and outer root independently, and proves both absent. A
missing/mismatched marker or ambiguous process causes refusal and preservation.
Never create a replacement marker, adopt a root, use `git clean`, or delete by
name alone.

## API-06 recommended complete workflow

API-01 through API-05 were approved before this work. API-06 is the current
unapproved review increment until explicit acceptance. API-07 and later work
is not authorized. This runbook is programmer-convenience documentation; the
SRS, rubric, and approved design artifacts remain authoritative.

The single recommended API-06 command requires:

- working directory `C:\Users\Administrator\source\CafeFausse`;
- Windows PowerShell 5.1;
- standard GIL-enabled CPython 3.14.6 at `C:\Python314\python.exe`;
- PostgreSQL 18.3 at `C:\Program Files\PostgreSQL\18\bin`;
- an unoccupied loopback port 55446;
- explicit confirmation that the target is disposable, isolated, and
  nonproduction.

It needs no caller-supplied database credential. The local cluster uses trust
authentication only on loopback, and the test-only manager placeholder is not
a reusable secret. Never point this workflow at production, production-like,
shared, or developer-owned data.

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse
& .\backend\tests\run_api06.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The exact authorization value is mandatory and case-sensitive. The runner
refuses an unexpected Python/PostgreSQL version, occupied port, unexpected
root, missing marker, or mismatched marker before deleting anything.

The standalone runner creates only `%TEMP%\CafeFausse-api06-tests`, whose JSON
marker records repository, task, phase, purpose, owner ID, canonical root,
port 55446, and database `cafe_fausse_test_api06`. PostgreSQL data, venv, pip
cache, coverage, and process-temp paths are shallow siblings beneath that
root, with resource ownership recorded before creation. Routine testing sets
`PYTHONDONTWRITEBYTECODE=1`, removes inherited `PYTHONPYCACHEPREFIX`, disables
pytest caching, and uses pip `--no-compile`. It creates a loopback PostgreSQL
cluster, the one test database, app/test-manager logins, and uniquely owned
fixtures. It preserves unrelated databases, roles, memberships, rows,
processes, listeners, files, directories, passfiles, and environment values.

Independent `finally` phases restore the original working directory, stop the
owned PostgreSQL child, remove generated artifacts, remove the exact
marker-owned cluster root, restore all 24 changed environment variables to
their prior value or absence without displaying values, and verify no owned
root or listener remains. An earlier cleanup failure does not skip later
phases. An ordinary test failure remains primary; cleanup failures are
reported separately and force a nonzero exit.

Expected clean markers are `API06 FOCUSED PASS`, `API06 TEST PASS`,
`API06 CLEANUP EVIDENCE`, and `API06 CLEANUP PASS`. The current complete suite
collects 345 tests: 301 unit/API tests and 44 PostgreSQL integration tests.
Counts can increase in
later approved work, so the process exit and markers remain authoritative.

### Focused API-06 commands

For unit and Flask-API diagnosis, use a developer-owned environment installed
as documented in `README.md`. These commands do not replace the complete
runner:

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse\backend
& .\.venv\Scripts\python.exe -m pytest tests\unit\test_validation_newsletter.py
& .\.venv\Scripts\python.exe -m pytest tests\unit\test_newsletter_preference_service.py tests\unit\test_retry.py
& .\.venv\Scripts\python.exe -m pytest tests\unit\test_newsletter_gateway.py
& .\.venv\Scripts\python.exe -m pytest tests\api\test_newsletter_preferences.py tests\unit\test_logging_and_lifecycle.py
```

The PostgreSQL commands below require an already provisioned, isolated
PostgreSQL 18.3 test environment with the same app/test-manager separation and
environment contract established by the complete runner. They are focused
diagnostics, not standalone setup instructions:

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse\backend
& .\.venv\Scripts\python.exe -m pytest tests\integration\test_newsletter_preferences_postgresql.py -m "integration and postgres"
& .\.venv\Scripts\python.exe -m pytest tests\integration\test_newsletter_preferences_postgresql.py -m "integration and postgres" -k "concurrent or opposing"
```

### Failure, restart, and cleanup demonstrations

The ordinary-failure switch is explicit, isolated, and test-only. Expect the
first command to return nonzero, report the controlled integration failure,
and still print cleanup evidence. Then run the complete command immediately:

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse
& .\backend\tests\run_api06.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' -InjectFailure
if ($LASTEXITCODE -eq 0) { throw 'The controlled API-06 failure did not fail.' }
& .\backend\tests\run_api06.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The cleanup-failure switch lets the test suite pass, injects one
generated-artifact cleanup failure, requires a nonzero exit, and proves that
cluster removal and exact environment restoration are still attempted:

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse
& .\backend\tests\run_api06.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' -InjectCleanupFailure
if ($LASTEXITCODE -eq 0) { throw 'The controlled API-06 cleanup failure did not fail.' }
```

The complete command is immediately repeatable in the same session. To prove
the new-session model, open a fresh PowerShell or invoke PowerShell 5.1 and run
the same command:

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\backend\tests\run_api06.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

After an interruption, rerun the complete command. A partial exact task root
with the exact marker is stopped and removed before a clean rebuild. A
separate cleanup-only switch is intentionally unnecessary: the normal command
performs guarded recovery before setup and always performs final cleanup. If
the marker is absent, malformed, or mismatched, the runner refuses the root
without deletion. Stop and inspect it; do not rename, adopt, or delete an
ambiguous resource.

The runner never scans the repository for generic `.venv`, `.pytest_cache`,
`.coverage`, `__pycache__`, or `*.egg-info` names. To demonstrate preservation,
record file lengths and SHA-256 hashes before a run, execute the complete
workflow, and compare the same explicit paths afterward. Apply the same rule
to a preexisting task-like database: create and verify it only in a separately
owned isolated cluster, then prove its database and contents remain after the
runner. Never create a collision proof in a shared or production cluster.

Codex explicitly confirmed that it generated
`backend\.api06-correction-compile` during API-06 compilation. That statement
established provenance for this exact resource; after canonical-path and
root/descendant reparse-point verification, only that directory was removed
and absence was verified. This does not authorize deletion of any other
unmarked or ambiguously owned resource.

After success or controlled failure, the following must show an absent runner
root, no listener, and no runner-generated repository artifact. Preexisting or
ambiguously owned artifacts may legitimately remain and must retain their
exact bytes:

```powershell
Test-Path -LiteralPath "$env:TEMP\CafeFausse-api06-tests"
Get-NetTCPConnection -State Listen -LocalPort 55446 -ErrorAction SilentlyContinue
git status --short
```

The integration suite verifies that successful public results equal committed
PostgreSQL state, same-state requests are idempotent, opposing concurrent
writes follow last-committed-write semantics, a preexisting same-email
customer retains identity, phone, reservation, and table-assignment data, and
every uniquely owned fixture is removed. Final runner evidence requires zero
customers, reservations, and assignments before the owned database and roles
are removed with their cluster.

API-06 certainty tests use three explicitly distinguished evidence levels.
The existing table-lock test produces an organic PostgreSQL `55P03`. The
`40P01` and `40001` classifications—and an additional deterministic `55P03`
retry case—use a test-only cursor adapter because the frozen single-key
READ COMMITTED routine cannot organically create those states. That adapter
still uses the production gateway and service, real PostgreSQL pool leases,
real BEGIN/statement-timeout work, and Psycopg connection-context rollback on
every failed attempt. Other test-only adapters lose a result after the real
routine executes, close a real connection before rollback can be confirmed,
or raise only after a real context commit to model lost acknowledgement.
These are controlled adapter results, not claims of organically generated
PostgreSQL failures.

## API-05 recommended complete workflow

For API-05, the single recommended command is the guarded runner below. It
requires Windows PowerShell 5.1, standard GIL-enabled CPython 3.14.6 at
`C:\Python314\python.exe`, PostgreSQL 18.3 under
`C:\Program Files\PostgreSQL\18\bin`, and a repository checkout at the exact
working directory shown. It does not require the caller to set or reveal a
credential: the runner creates a loopback-only, trust-authenticated disposable
cluster and uses a non-secret local-trust placeholder only to satisfy the
test-manager fixture's explicit credential boundary.

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse
& .\backend\tests\run_api05.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The runner refuses a wrong Python/PostgreSQL version, an occupied dedicated
port, an unmarked cluster directory, or a marker mismatch. It creates only:

- `%TEMP%\CafeFausse-api05-tests` with an ownership marker, disposable
  PostgreSQL cluster, `cafe_fausse_test_api05` database, app/test-manager
  logins, and task-owned test rows;
- `%TEMP%\CafeFausse-api05-tests\artifacts`, containing the runner's virtual
  environment, pytest cache, coverage data, Python bytecode, and pip cache.
  The runner installs the fixed test dependencies without an editable project
  install, so it creates no repository package/build metadata.

It preserves every preexisting database, role, membership, row, file,
listener, process, passfile, and process-environment value. Its `finally` path
stops the child PostgreSQL server, proves the dedicated port is no longer
served, removes only marker-owned resources, and restores every changed
environment variable to its exact prior value or prior absence without
displaying values. PostgreSQL/process cleanup, artifact cleanup, cluster-root
cleanup, and environment restoration are attempted independently. Test or
cleanup failure returns nonzero; the original test failure is reported first
and cleanup failures are reported separately and prominently.

Expected success includes these markers (counts may increase as tests are
added): `API05 TEST PASS`, `224 passed`, zero-row evidence, and
`API05 CLEANUP PASS`. Expected cleanup output states that the task-owned
cluster directory is absent and that all 19 captured environment variables
were restored.

### Focused API-05 commands

For focused unit/API work, use a developer-owned environment created as shown
in `README.md`. The complete runner neither reads, changes, nor deletes that
environment. PostgreSQL integration still requires the complete runner's
isolated cluster and manager variables, so the integration line is diagnostic
rather than a substitute for the complete workflow.

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse\backend
& .\.venv\Scripts\python.exe -m pytest tests\unit\test_validation_identity.py tests\unit\test_newsletter_status_service.py tests\unit\test_customer_gateway.py
& .\.venv\Scripts\python.exe -m pytest tests\api\test_newsletter_status.py
& .\.venv\Scripts\python.exe -m pytest tests\integration\test_newsletter_status_postgresql.py -m "integration and postgres"
```

To prove ordinary-failure cleanup and restart, run the controlled failure and
expect a nonzero result, then run the ordinary command and expect success:

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse
& .\backend\tests\run_api05.ps1 -InjectFailure
if ($LASTEXITCODE -eq 0) { throw 'The controlled API-05 failure did not fail.' }
& .\backend\tests\run_api05.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

To prove cleanup-failure handling, run the test-only cleanup injection. It must
return nonzero, report the controlled artifact-cleanup failure, still restore
all 19 environment variables, and use the independently attempted cluster-root
cleanup to remove every task-owned artifact safely:

```powershell
Set-Location C:\Users\Administrator\source\CafeFausse
& .\backend\tests\run_api05.ps1 -InjectCleanupFailure
if ($LASTEXITCODE -eq 0) { throw 'The controlled API-05 cleanup failure did not fail.' }
```

The complete command may be repeated immediately in the same PowerShell
session or after opening a new PowerShell session and returning to the exact
repository root. After an interrupted run, invoke the same command: it removes
a matching marked partial cluster before rebuilding. If the cluster path is
unmarked, the marker differs, or ownership of a path/process/database/role is
ambiguous, stop and inspect it; do not delete or adopt it.

After any completed success, ordinary failure, or controlled cleanup failure,
this read-only check must report `False` for the task root and no listener on
port 55445. A preexisting `backend\.venv`, cache, coverage, bytecode, or
package-metadata sentinel must retain its original bytes and may legitimately
remain present:

```powershell
Test-Path -LiteralPath "$env:TEMP\CafeFausse-api05-tests"
Get-NetTCPConnection -State Listen -LocalPort 55445 -ErrorAction SilentlyContinue
git status --short
```

The legacy numbered API-04 convenience workflow remains below for manual
foundation diagnostics. API-05's recommended complete command above is the
authoritative programmer workflow for this increment.

Working-directory contract: start Step 1 at the repository root and keep the
same PowerShell session for Steps 2 through 16. Step 1 records that exact path
in `$CafeRepo`. Later blocks either operate from that repository root or use
`Push-Location`/`Pop-Location` internally and restore it. Do not start a
numbered block from `backend` or another directory unless that block explicitly
changes location itself.

## Safety rules

- Use PostgreSQL 18.3 only.
- Use a dedicated, disposable local cluster bound to `127.0.0.1` and a
  database whose name begins with `cafe_fausse_test_`.
- Never use these instructions against production, production-like data, a
  shared development server, or another application's PostgreSQL cluster.
- The full backend PostgreSQL integration suite deliberately stops and
  restarts PostgreSQL. `CAFE_FAUSSE_TEST_PGDATA` must therefore identify this
  dedicated cluster's data directory under the Windows temporary directory.
- The Windows user running this guide needs only two PostgreSQL logins:
  - the cluster administrator created in Step 2, used for setup, rebuilds,
    final restoration, and external test management through
    `cafe_fausse_test`;
  - the deployment login, which is a member only of `cafe_fausse_app` and is
    used by Flask.
- Keep the deployment login separate from administrator/test authority. This
  preserves the approved API-03 least-privilege boundary while removing the
  redundant third login from the local test harness.
- Give the cluster administrator and deployment login different passwords.
  Reusing the administrator password for the app-only login would undermine
  the benefit of separating their privileges.
- Either store both passwords outside the repository in a protected PostgreSQL
  passfile or enter both at secure interactive prompts when a command needs
  them. Never commit passwords, passfiles, connection URLs, or environment
  dumps.
- Use `PGPASSFILE` or `PGPASSWORD`, never both. Step 3 detects the documented
  passfile automatically and removes the unused credential variables. Steps
  11 and 12 support either one protected passfile or two secure interactive
  prompts.
- Use the dedicated Flask port from Step 1 only. A listening process is never
  reused or terminated unless its PID file, interpreter path, and TCP listener
  ownership agree.
- Step 1 snapshots every PostgreSQL/Cafe Fausse process variable this workflow
  can change. Step 16 restores each prior value or prior absence without
  displaying secrets.
- Stop immediately if a guard, version check, role audit, rebuild, verifier, or
  test command fails.
- Every numbered step is restartable. A rerun must inspect and reuse valid
  state, repair only task-owned partial state, and produce the same `STEP n
  PASS` marker. It must not treat "already exists", "already running", or
  "already stopped" as a failure when the existing state matches this guide.

## Rerun behavior

| Step | Repeatable behavior |
|---|---|
| 1 | Preserves the original process environment once, reassigns task variables, and redetects approved tools without overwriting the snapshot on a rerun. |
| 2 | Reuses a valid marked cluster, recreates marker-owned partial data, or starts a stopped cluster; an unmarked/mismatched directory is refused. |
| 3 | Replaces the active credential source; passfile entries are updated in place without duplicates. |
| 4 | Creates a missing database or validates the existing database, owner, and version. |
| 5 | Guardedly rebuilds the fixed schema and verifies the baseline. |
| 6 | Creates or normalizes the one deployment login, resets and verifies its password, and reapplies the exact app-only grants. |
| 7 | Repeats read-only role and authentication audits. |
| 8 | Repeats the destructive nonproduction PostgreSQL gate and restores its baseline. |
| 9 | Reuses or recreates only the task-owned temporary environment, then refreshes dependencies without touching a repository `.venv`. |
| 10 | Repeats unit/API tests and always restores the caller's directory. |
| 11 | Ensures PostgreSQL is running, then repeats integration/recovery tests and restores the caller's directory. |
| 12 | Reestablishes all test variables, then repeats coverage and restores the caller's directory. |
| 13 | Uses a dedicated port and reuses or replaces Flask only after PID, interpreter, and listener ownership agree. |
| 14 | Repeats the guarded final rebuild and exact baseline-count proof. |
| 15 | Repeats compilation/Git checks from the repository root. |
| 16 | Removes the test database, generated roles/files, app credential, recognized processes, and the entire task-owned PostgreSQL cluster; retains an external administrator passfile entry when present; and restores the original process environment. |

## How credential selection works

No credential-mode variable or manual true/false switch is used. Step 3 always
checks this external path:

```text
%APPDATA%\postgresql\cafe_fausse_api04_pgpass.conf
```

The selection rule is automatic and applies to every later step:

1. If the passfile exists and is nonempty, the helpers set `PGPASSFILE` and
   use it.
2. If the passfile does not exist, the helpers securely prompt for the needed
   password with `Read-Host -AsSecureString` and set process-scoped
   `PGPASSWORD` values.
3. If the passfile exists but is empty, the helpers stop with an error instead
   of silently falling back or attempting authentication with incomplete
   state.

Step 3 includes an optional block that creates and populates the passfile. Run
that block only when persistent external credential storage is wanted. Skip it
when interactive prompts are wanted. The runbook never deletes an existing
passfile automatically; its presence always selects passfile mode.

## 1. Define the isolated target

Open PowerShell at the repository root and define task-specific variables:

```powershell
$CafeManagedEnvironmentNames = @(
    'CAFE_FAUSSE_ALLOW_RESET',
    'CAFE_FAUSSE_ENVIRONMENT',
    'CAFE_FAUSSE_PSQL',
    'CAFE_FAUSSE_TEST_MANAGER_PASSWORD',
    'CAFE_FAUSSE_TEST_MANAGER_USER',
    'CAFE_FAUSSE_TEST_PGDATA',
    'COVERAGE_FILE',
    'PIP_CACHE_DIR',
    'PGDATABASE',
    'PGHOST',
    'PGOPTIONS',
    'PGPASSFILE',
    'PGPASSWORD',
    'PGPORT',
    'PGUSER',
    'PYTHONPATH',
    'PYTHONPYCACHEPREFIX'
)

if (-not (Get-Variable CafePriorProcessEnvironment -Scope Script -ErrorAction SilentlyContinue)) {
    $CafeOriginalProcessEnvironment = [Environment]::GetEnvironmentVariables(
        [EnvironmentVariableTarget]::Process
    )
    $CafePriorProcessEnvironment = [ordered]@{}
    foreach ($CafeEnvironmentName in $CafeManagedEnvironmentNames) {
        $CafeWasPresent = $CafeOriginalProcessEnvironment.Contains(
            $CafeEnvironmentName
        )
        $CafePriorProcessEnvironment[$CafeEnvironmentName] = [pscustomobject]@{
            WasPresent = $CafeWasPresent
            Value = if ($CafeWasPresent) {
                [string]$CafeOriginalProcessEnvironment[$CafeEnvironmentName]
            } else {
                $null
            }
        }
    }
    Remove-Variable CafeOriginalProcessEnvironment -ErrorAction SilentlyContinue
    $CafeEnvironmentRestoreCompleted = $false
    Write-Host 'Environment snapshot created without displaying values.'
} else {
    Write-Host 'Existing environment snapshot retained; prior values were not overwritten.'
}

function Restore-CafeFausseProcessEnvironment {
    if (Get-Variable CafePriorProcessEnvironment -Scope Script -ErrorAction SilentlyContinue) {
        foreach ($CafeEnvironmentName in $CafeManagedEnvironmentNames) {
            $CafePriorEnvironmentEntry = $CafePriorProcessEnvironment[
                $CafeEnvironmentName
            ]
            if ($CafePriorEnvironmentEntry.WasPresent) {
                [Environment]::SetEnvironmentVariable(
                    $CafeEnvironmentName,
                    [string]$CafePriorEnvironmentEntry.Value,
                    [EnvironmentVariableTarget]::Process
                )
            } else {
                [Environment]::SetEnvironmentVariable(
                    $CafeEnvironmentName,
                    $null,
                    [EnvironmentVariableTarget]::Process
                )
            }
        }

        $CafeRestoredProcessEnvironment = [Environment]::GetEnvironmentVariables(
            [EnvironmentVariableTarget]::Process
        )
        foreach ($CafeEnvironmentName in $CafeManagedEnvironmentNames) {
            $CafePriorEnvironmentEntry = $CafePriorProcessEnvironment[
                $CafeEnvironmentName
            ]
            $CafeIsPresentAfterRestore = $CafeRestoredProcessEnvironment.Contains(
                $CafeEnvironmentName
            )
            if ($CafePriorEnvironmentEntry.WasPresent -ne
                $CafeIsPresentAfterRestore) {
                throw "Environment presence restoration failed for $CafeEnvironmentName."
            }
            if ($CafePriorEnvironmentEntry.WasPresent -and
                [string]$CafeRestoredProcessEnvironment[$CafeEnvironmentName] -cne
                    [string]$CafePriorEnvironmentEntry.Value) {
                throw "Environment value restoration failed for $CafeEnvironmentName."
            }
        }

        foreach ($CafePriorEnvironmentEntry in $CafePriorProcessEnvironment.Values) {
            $CafePriorEnvironmentEntry.Value = $null
        }
        $CafePriorProcessEnvironment.Clear()
        Remove-Variable CafePriorProcessEnvironment -Scope Script -ErrorAction SilentlyContinue
        $script:CafeEnvironmentRestoreCompleted = $true
        Write-Host "STEP 16 EVIDENCE: restored prior presence/values for $($CafeManagedEnvironmentNames.Count) process environment variables without displaying values."
    } elseif (-not (Get-Variable CafeEnvironmentRestoreCompleted -Scope Script -ErrorAction SilentlyContinue) -or
        -not $CafeEnvironmentRestoreCompleted) {
        throw 'The Step 1 environment snapshot is unavailable; refusing to claim environment restoration.'
    } else {
        Write-Host 'STEP 16 EVIDENCE: prior process environment was already restored.'
    }
}

$CafeRepo = (Resolve-Path '.').Path
$CafePgBin = 'C:\Program Files\PostgreSQL\18\bin'
$CafeClusterRoot = Join-Path $env:TEMP 'CafeFausse-api04-local'
$CafeDataDir = Join-Path $CafeClusterRoot 'data'
$CafeLogFile = Join-Path $CafeClusterRoot 'postgres.log'
$CafeClusterMarker = Join-Path $CafeClusterRoot '.cafe-fausse-api04-test-cluster'
$CafeFlaskPidFile = Join-Path $CafeClusterRoot 'flask.pid'
$CafeFlaskOutputLog = Join-Path $CafeClusterRoot 'flask-output.log'
$CafeFlaskErrorLog = Join-Path $CafeClusterRoot 'flask-error.log'
$CafeArtifactRoot = Join-Path $CafeClusterRoot 'artifacts'
$CafeVenvRoot = Join-Path $CafeArtifactRoot 'venv'
$CafeVenvPython = Join-Path $CafeVenvRoot 'Scripts\python.exe'
$CafePytestCache = Join-Path $CafeArtifactRoot 'pytest-cache'
$CafeCoverageFile = Join-Path $CafeArtifactRoot '.coverage'
$CafePythonCache = Join-Path $CafeArtifactRoot 'pycache'
$CafePipCache = Join-Path $CafeArtifactRoot 'pip-cache'
$CafePort = '55435'
$CafeFlaskPort = '55004'
$CafeDatabase = 'cafe_fausse_test_api04'
$CafeAdminLogin = 'cafe_fausse_admin'
$CafeAppLogin = 'cafe_fausse_api04_login'
```

Confirm that the shell is at the correct repository and that the required
programs exist:

```powershell
if (-not (Test-Path -LiteralPath (Join-Path $CafeRepo 'backend\pyproject.toml'))) {
    throw 'Run this guide from the Cafe Fausse repository root.'
}

foreach ($CafeProgram in @('initdb.exe', 'pg_ctl.exe', 'pg_isready.exe', 'psql.exe', 'createdb.exe', 'dropdb.exe')) {
    $CafeProgramPath = Join-Path $CafePgBin $CafeProgram
    if (-not (Test-Path -LiteralPath $CafeProgramPath)) {
        throw "Required PostgreSQL program not found: $CafeProgramPath"
    }
}

$CafePsqlVersionLines = & (Join-Path $CafePgBin 'psql.exe') --version 2>&1
$CafePsqlVersionExitCode = $LASTEXITCODE
$CafePsqlVersion = $CafePsqlVersionLines -join [Environment]::NewLine
if ($CafePsqlVersionExitCode -ne 0 -or $CafePsqlVersion -notmatch '18\.3') {
    throw "Expected PostgreSQL 18.3; received: $CafePsqlVersion"
}

$CafePythonExecutable = $null
$CafePythonLauncherArguments = @()
$CafePythonVersion = $null
$CafePythonAttempts = [System.Collections.Generic.List[string]]::new()
$CafePythonCandidates = [System.Collections.Generic.List[object]]::new()
$CafePyLauncher = Get-Command py -ErrorAction SilentlyContinue

if ($null -ne $CafePyLauncher) {
    $CafePythonCandidates.Add([pscustomobject]@{
        Executable = $CafePyLauncher.Source
        Arguments = @('-3.14')
    })
}

if (Test-Path -LiteralPath 'C:\Python314\python.exe' -PathType Leaf) {
    $CafePythonCandidates.Add([pscustomobject]@{
        Executable = 'C:\Python314\python.exe'
        Arguments = @()
    })
}

foreach ($CafePythonCandidate in $CafePythonCandidates) {
    $CafeCandidateArguments = @($CafePythonCandidate.Arguments)
    $CafeCandidateVersion = & $CafePythonCandidate.Executable `
        @CafeCandidateArguments --version 2>&1
    $CafeCandidateExitCode = $LASTEXITCODE
    $CafeCandidateVersionText = ($CafeCandidateVersion -join [Environment]::NewLine).Trim()
    $CafePythonAttempts.Add(
        "$($CafePythonCandidate.Executable) $($CafePythonCandidate.Arguments -join ' '): exit=$CafeCandidateExitCode version=$CafeCandidateVersionText"
    )
    if ($CafeCandidateExitCode -eq 0 -and
        $CafeCandidateVersionText -match '^Python 3\.14\.6$') {
        $CafePythonExecutable = $CafePythonCandidate.Executable
        $CafePythonLauncherArguments = @($CafePythonCandidate.Arguments)
        $CafePythonVersion = $CafeCandidateVersionText
        break
    }
}

if ($null -eq $CafePythonExecutable) {
    throw "Could not find approved CPython 3.14.6. Attempts: $($CafePythonAttempts -join '; ')"
}

Write-Host "STEP 1 PASS: environment preserved; PostgreSQL=127.0.0.1:$CafePort; Flask=127.0.0.1:$CafeFlaskPort; $CafePsqlVersion; $CafePythonVersion"
```

The PostgreSQL output must report `18.3`. Normal application metadata supports
standard 64-bit CPython 3.14.x, but the formal integration acceptance test
requires Windows Server 2025 and standard GIL-enabled 64-bit CPython 3.14.6.
Use that exact platform for a formal test run. Step 1 records either the `py`
launcher or `C:\Python314\python.exe` in `$CafePythonExecutable` for reuse by
later steps.

Expected verification output contains:

```text
STEP 1 PASS: environment preserved; PostgreSQL=127.0.0.1:55435; Flask=127.0.0.1:55004; psql (PostgreSQL) 18.3; Python 3.14.6
```

## 2. Ensure the dedicated PostgreSQL cluster exists and is running

This step is repeatable after successful, failed, or interrupted runs. It uses
a task-specific marker beneath the exact temporary path. A valid existing
cluster is reused; a marker-owned partial initialization is removed and
recreated; a stopped valid cluster is restarted; and a running valid cluster
is left running. An unmarked, mismatched, or otherwise ambiguous directory is
never adopted, overwritten, or deleted.

```powershell
$CafeExpectedClusterRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $env:TEMP 'CafeFausse-api04-local')
)
$CafeResolvedClusterRoot = [System.IO.Path]::GetFullPath($CafeClusterRoot)
if (-not $CafeResolvedClusterRoot.Equals(
    $CafeExpectedClusterRoot,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Unsafe cluster path. Expected $CafeExpectedClusterRoot; received $CafeResolvedClusterRoot"
}

$CafeMarkerText = @"
Cafe Fausse API-04 disposable PostgreSQL 18 cluster
port=$CafePort
database=$CafeDatabase
"@.Trim()
$CafeVersionFile = Join-Path $CafeDataDir 'PG_VERSION'

if (-not (Test-Path -LiteralPath $CafeClusterRoot)) {
    New-Item -ItemType Directory -Path $CafeClusterRoot | Out-Null
    Set-Content -LiteralPath $CafeClusterMarker -Value $CafeMarkerText -Encoding UTF8
} elseif (-not (Test-Path -LiteralPath $CafeClusterMarker -PathType Leaf)) {
    throw "Existing task path has no ownership marker and will not be adopted or deleted: $CafeClusterRoot"
}

$CafeRecordedMarker = (Get-Content -LiteralPath $CafeClusterMarker -Raw).Trim()
if ($CafeRecordedMarker -ne $CafeMarkerText) {
    throw "Cluster ownership marker does not match this runbook: $CafeClusterMarker"
}

$CafeNeedsInitialization = $true
if (Test-Path -LiteralPath $CafeVersionFile -PathType Leaf) {
    $CafeExistingMajor = (Get-Content -LiteralPath $CafeVersionFile -Raw).Trim()
    if ($CafeExistingMajor -ne '18') {
        throw "Expected PostgreSQL data major version 18; found $CafeExistingMajor"
    }
    $CafeRequiredDataPaths = @(
        (Join-Path $CafeDataDir 'global\pg_control'),
        (Join-Path $CafeDataDir 'postgresql.conf'),
        (Join-Path $CafeDataDir 'pg_hba.conf'),
        (Join-Path $CafeDataDir 'base')
    )
    $CafeNeedsInitialization = @(
        $CafeRequiredDataPaths | Where-Object {
            -not (Test-Path -LiteralPath $_)
        }
    ).Count -gt 0
}

if ($CafeNeedsInitialization) {
    if (Test-Path -LiteralPath $CafeDataDir) {
        if (Test-Path -LiteralPath (Join-Path $CafeDataDir 'postmaster.pid')) {
            $CafePartialStatusLines = & (Join-Path $CafePgBin 'pg_ctl.exe') `
                -D $CafeDataDir status 2>&1
            $CafePartialStatusExitCode = $LASTEXITCODE
            $CafePartialStatus = $CafePartialStatusLines -join [Environment]::NewLine
            if ($CafePartialStatusExitCode -eq 0 -and
                $CafePartialStatus -match 'server is running') {
                & (Join-Path $CafePgBin 'pg_ctl.exe') `
                    -D $CafeDataDir -m fast -w stop
                $CafePartialStopExitCode = $LASTEXITCODE
                if ($CafePartialStopExitCode -ne 0) {
                    throw "Could not stop the marker-owned partial cluster; exit code $CafePartialStopExitCode"
                }
            } elseif ($CafePartialStatusExitCode -eq 0 -or
                $CafePartialStatus -notmatch 'no server running') {
                throw "Unrecognized partial-cluster status; refusing cleanup: $CafePartialStatus"
            }
        }

        $CafePartialReadyOutput = & (Join-Path $CafePgBin 'pg_isready.exe') `
            -h 127.0.0.1 -p $CafePort -t 3 2>&1
        $CafePartialReadyExitCode = $LASTEXITCODE
        if ($CafePartialReadyExitCode -eq 0) {
            throw "A PostgreSQL server is still accepting connections on the task port; refusing partial-data cleanup: $($CafePartialReadyOutput -join ' ')"
        }

        $CafeResolvedDataDir = [System.IO.Path]::GetFullPath($CafeDataDir)
        $CafeExpectedDataDir = [System.IO.Path]::GetFullPath(
            (Join-Path $CafeExpectedClusterRoot 'data')
        )
        if (-not $CafeResolvedDataDir.Equals(
            $CafeExpectedDataDir,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Refusing partial-cluster cleanup outside the exact task data directory: $CafeResolvedDataDir"
        }
        Remove-Item -LiteralPath $CafeDataDir -Recurse -Force
    }

    & (Join-Path $CafePgBin 'initdb.exe') `
        -D $CafeDataDir `
        -U $CafeAdminLogin `
        -W `
        --auth-host=scram-sha-256 `
        --auth-local=scram-sha-256 `
        --encoding=UTF8
    $CafeInitExitCode = $LASTEXITCODE
    if ($CafeInitExitCode -ne 0) {
        throw "initdb failed with exit code $CafeInitExitCode. Rerun Step 2; the marker-owned partial data directory will be safely recreated."
    }
}

function Start-CafeFausseTestPostgres {
    $CafeInitialReadyOutput = & (Join-Path $CafePgBin 'pg_isready.exe') `
        -h 127.0.0.1 -p $CafePort -t 3 2>&1
    $CafeInitialReadyExitCode = $LASTEXITCODE

    if ($CafeInitialReadyExitCode -eq 0) {
        $CafePostmasterPidFile = Join-Path $CafeDataDir 'postmaster.pid'
        if (-not (Test-Path -LiteralPath $CafePostmasterPidFile -PathType Leaf)) {
            throw "Port $CafePort is accepting PostgreSQL connections but this task data directory has no postmaster.pid; refusing to reuse an unknown server."
        }
        $CafePostmasterPidLines = @(Get-Content -LiteralPath $CafePostmasterPidFile)
        if ($CafePostmasterPidLines.Count -lt 4 -or
            $CafePostmasterPidLines[0].Trim() -notmatch '^\d+$' -or
            $CafePostmasterPidLines[3].Trim() -ne $CafePort) {
            throw "Port $CafePort is ready but the task postmaster.pid is invalid or names another port."
        }
        $CafePostmasterProcess = Get-Process `
            -Id ([int]$CafePostmasterPidLines[0].Trim()) `
            -ErrorAction SilentlyContinue
        if ($null -eq $CafePostmasterProcess -or
            $CafePostmasterProcess.ProcessName -ne 'postgres') {
            throw "Port $CafePort is ready but the task postmaster PID is not a live postgres process."
        }
        Write-Host 'PostgreSQL is already running; startup was not repeated.'
    } else {
        $CafeStatusLines = & (Join-Path $CafePgBin 'pg_ctl.exe') `
            -D $CafeDataDir status 2>&1
        $CafeStatusExitCode = $LASTEXITCODE
        $CafeStatusText = $CafeStatusLines -join [Environment]::NewLine
        if ($CafeStatusExitCode -eq 0 -and
            $CafeStatusText -match 'server is running') {
            throw "The task postgres process exists but is not ready on 127.0.0.1:$CafePort`: $CafeStatusText"
        }
        if ($CafeStatusExitCode -eq 0 -or
            $CafeStatusText -notmatch 'no server running') {
            throw "Unrecognized PostgreSQL status (exit $CafeStatusExitCode): $CafeStatusText"
        }

        & (Join-Path $CafePgBin 'pg_ctl.exe') `
            -D $CafeDataDir `
            -l $CafeLogFile `
            -o "-p $CafePort -h 127.0.0.1" `
            -w start
        $CafeStartExitCode = $LASTEXITCODE
        if ($CafeStartExitCode -ne 0) {
            throw "PostgreSQL startup failed with exit code $CafeStartExitCode"
        }
    }

    $CafeReadyOutput = & (Join-Path $CafePgBin 'pg_isready.exe') `
        -h 127.0.0.1 -p $CafePort -t 5 2>&1
    $CafeReadyExitCode = $LASTEXITCODE
    if ($CafeReadyExitCode -ne 0) {
        throw "PostgreSQL did not become ready on 127.0.0.1:$CafePort`: $($CafeReadyOutput -join ' ')"
    }
}

Start-CafeFausseTestPostgres
Write-Host "STEP 2 PASS: task-owned PostgreSQL cluster is initialized and running on 127.0.0.1:$CafePort"
```

`initdb -W` prompts only when initialization or safe partial-state recovery is
actually required. Use the same nonproduction administrator password when
recovering a partial first run. A normal rerun does not reinitialize the
cluster or prompt again.

Expected verification output ends with:

```text
STEP 2 PASS: task-owned PostgreSQL cluster is initialized and running on 127.0.0.1:55435
```

## 3. Select a protected external file or secure interactive password

Define the one external passfile location used by automatic detection:

```powershell
$CafePassDirectory = Join-Path $env:APPDATA 'postgresql'
$CafePassFile = Join-Path $CafePassDirectory 'cafe_fausse_api04_pgpass.conf'
$CafeCurrentWindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$CafeApprovedPassfileSid = $CafeCurrentWindowsIdentity.User
$CafeCurrentWindowsIdentity.Dispose()

function Assert-CafeFaussePassfileAcl {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Protected PostgreSQL passfile does not exist: $Path"
    }

    $CafeVerifiedAcl = Get-Acl -LiteralPath $Path
    if (-not $CafeVerifiedAcl.AreAccessRulesProtected) {
        throw "Passfile ACL still inherits access entries: $Path"
    }

    $CafeVerifiedRules = @(
        $CafeVerifiedAcl.GetAccessRules(
            $true,
            $true,
            [System.Security.Principal.SecurityIdentifier]
        )
    )
    if ($CafeVerifiedRules.Count -ne 1) {
        throw "Passfile ACL must contain exactly one explicit access rule; found $($CafeVerifiedRules.Count)."
    }

    $CafeVerifiedRule = $CafeVerifiedRules[0]
    if ($CafeVerifiedRule.IsInherited -or
        $CafeVerifiedRule.AccessControlType -ne
            [System.Security.AccessControl.AccessControlType]::Allow -or
        $CafeVerifiedRule.IdentityReference.Value -ne
            $CafeApprovedPassfileSid.Value -or
        $CafeVerifiedRule.FileSystemRights -ne
            [System.Security.AccessControl.FileSystemRights]::FullControl) {
        throw 'Passfile ACL permits an identity or access rule outside the approved current-user allowlist.'
    }
}

function Protect-CafeFaussePassfileAcl {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Protected PostgreSQL passfile does not exist: $Path"
    }

    $CafeApprovedPassfileTrustee = "*$($CafeApprovedPassfileSid.Value)"
    & icacls.exe $Path `
        /inheritance:r `
        /grant:r "$CafeApprovedPassfileTrustee`:(F)" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not establish the current-user passfile ACL.'
    }

    $CafeCandidateAcl = Get-Acl -LiteralPath $Path
    $CafeCandidateRules = @(
        $CafeCandidateAcl.GetAccessRules(
            $true,
            $true,
            [System.Security.Principal.SecurityIdentifier]
        )
    )
    $CafeUnapprovedSids = @(
        $CafeCandidateRules |
            Where-Object {
                $_.IdentityReference.Value -ne
                    $CafeApprovedPassfileSid.Value
            } |
            ForEach-Object { $_.IdentityReference.Value } |
            Sort-Object -Unique
    )
    foreach ($CafeUnapprovedSid in $CafeUnapprovedSids) {
        $CafeUnapprovedTrustee = "*$CafeUnapprovedSid"
        & icacls.exe $Path `
            /remove:g $CafeUnapprovedTrustee `
            /remove:d $CafeUnapprovedTrustee | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'Could not remove an unapproved explicit passfile ACL identity.'
        }
    }

    & icacls.exe $Path `
        /remove:d $CafeApprovedPassfileTrustee `
        /grant:r "$CafeApprovedPassfileTrustee`:(F)" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not finalize the current-user-only passfile ACL.'
    }
    Assert-CafeFaussePassfileAcl -Path $Path
}
```

Choose the workflow by file presence, not by changing a variable:

| Detected state | Automatic behavior | What to do in Step 3 |
|---|---|---|
| Passfile exists and is nonempty | Use `PGPASSFILE` | Run the protected-passfile block so its ACL and administrator entry are validated or refreshed, then run the shared helpers. |
| Passfile is absent | Use secure interactive prompts | Skip the protected-passfile block and run the automatic-selection check followed by the shared helpers. |
| Passfile exists but is empty | Stop with an error | Populate it through the protected-passfile block or intentionally remove the empty external file before continuing. |

### Optional: create or refresh the protected external passfile

Run this block only when using external credential storage. It creates a
missing passfile outside the repository, restricts it to the current Windows
identity, and creates or replaces the administrator entry without displaying
the password. If a passfile already exists, rerunning the block preserves
unrelated credential lines and refreshes the matching administrator entry. Its
ACL is rebuilt from an empty explicit-access list: inheritance is disabled and
the current Windows user's SID is the only approved identity. Any inherited or
additional explicit access rule causes verification to fail.

```powershell
New-Item -ItemType Directory -Path $CafePassDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $CafePassFile)) {
    New-Item -ItemType File -Path $CafePassFile | Out-Null
}

Protect-CafeFaussePassfileAcl -Path $CafePassFile

function Set-CafeFaussePassfileEntry {
    param(
        [Parameter(Mandatory)][string]$Login,
        [Parameter(Mandatory)][string]$DatabaseName,
        [Parameter(Mandatory)][string]$Prompt,
        [Security.SecureString]$SecurePassword
    )

    $CafeSecurePassword = $SecurePassword
    $CafeDisposeSecurePassword = $false
    if ($null -eq $CafeSecurePassword) {
        $CafeSecurePassword = Read-Host $Prompt -AsSecureString
        $CafeDisposeSecurePassword = $true
    }
    try {
        $CafePlainPassword = [System.Net.NetworkCredential]::new(
            '', $CafeSecurePassword
        ).Password
        if ([string]::IsNullOrEmpty($CafePlainPassword)) {
            throw "Password was empty for $Login"
        }

        $CafeEscapedPassword = $CafePlainPassword.Replace('\', '\\').Replace(':', '\:')
        $CafeEntryPrefix = "127.0.0.1:$CafePort`:$DatabaseName`:$Login`:"
        $CafeExistingLines = @(
            if (Test-Path -LiteralPath $CafePassFile -PathType Leaf) {
                Get-Content -LiteralPath $CafePassFile
            }
        )
        [string[]]$CafeUpdatedLines = @(
            $CafeExistingLines | Where-Object {
                -not $_.StartsWith(
                    $CafeEntryPrefix,
                    [System.StringComparison]::Ordinal
                )
            }
        ) + ($CafeEntryPrefix + $CafeEscapedPassword)

        [System.IO.File]::WriteAllLines(
            $CafePassFile,
            $CafeUpdatedLines,
            [System.Text.UTF8Encoding]::new($false)
        )
    }
    finally {
        if ($CafeDisposeSecurePassword -and $null -ne $CafeSecurePassword) {
            $CafeSecurePassword.Dispose()
        }
        Remove-Variable CafePlainPassword -ErrorAction SilentlyContinue
        Remove-Variable CafeEscapedPassword -ErrorAction SilentlyContinue
        Remove-Variable CafeSecurePassword -ErrorAction SilentlyContinue
        Remove-Variable CafeDisposeSecurePassword -ErrorAction SilentlyContinue
    }

    Protect-CafeFaussePassfileAcl -Path $CafePassFile
    Write-Host "Passfile entry created or replaced for $Login without displaying its password."
}

Set-CafeFaussePassfileEntry `
    -Login $CafeAdminLogin `
    -DatabaseName '*' `
    -Prompt "Password for $CafeAdminLogin"
```

The PostgreSQL passfile format is
`hostname:port:database:username:password`. Escape a literal `:` or `\` in a
password with `\` as required by libpq. The helper performs that escaping and
replaces an existing matching entry, so rerunning it does not create duplicate
lines.

### Verify the automatically selected credential source

Run this check whether or not the optional passfile block was run. It reports
the source that the shared helpers will use. It never prints a password or
passfile content:

```powershell
if (Test-Path -LiteralPath $CafePassFile -PathType Leaf) {
    if ((Get-Item -LiteralPath $CafePassFile).Length -eq 0) {
        throw "The detected external passfile is empty: $CafePassFile"
    }
    Assert-CafeFaussePassfileAcl -Path $CafePassFile
    Write-Host 'STEP 3 SOURCE: protected external passfile detected; PGPASSFILE will be used.'
} else {
    Write-Host 'STEP 3 SOURCE: no external passfile detected; secure interactive prompts will be used.'
}
```

Expected source-selection output is exactly one of:

```text
STEP 3 SOURCE: protected external passfile detected; PGPASSFILE will be used.
STEP 3 SOURCE: no external passfile detected; secure interactive prompts will be used.
```

### Shared credential helpers required for both sources

Run this entire block after the automatic-selection check. Do not skip it:
later steps depend on the two functions it defines.

When the passfile is absent, `Set-CafeFausseCredential` reads the current
login's password without echoing it, converts it only for the process
environment, and sets `PGPASSWORD`. When the passfile is present, it selects
`PGPASSFILE`. It always removes the unused credential variables first.

```powershell
function Set-CafeFausseCredential {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD -ErrorAction SilentlyContinue

    if (Test-Path -LiteralPath $CafePassFile -PathType Leaf) {
        if ((Get-Item -LiteralPath $CafePassFile).Length -eq 0) {
            throw "The external passfile exists but is empty: $CafePassFile"
        }

        Assert-CafeFaussePassfileAcl -Path $CafePassFile

        $env:PGPASSFILE = $CafePassFile
        Write-Host 'STEP 3 PASS: credential source is the protected external PGPASSFILE.'
        return
    }

    $securePassword = Read-Host $Prompt -AsSecureString
    try {
        $env:PGPASSWORD = [System.Net.NetworkCredential]::new('', $securePassword).Password
    }
    finally {
        $securePassword.Dispose()
        Remove-Variable securePassword -ErrorAction SilentlyContinue
    }

    if ([string]::IsNullOrEmpty($env:PGPASSWORD)) {
        throw 'The interactive PostgreSQL password was empty.'
    }

    Write-Host 'STEP 3 PASS: credential source is interactive PGPASSWORD for this PowerShell process.'
}

function Set-CafeFaussePytestCredentials {
    Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD -ErrorAction SilentlyContinue

    if (Test-Path -LiteralPath $CafePassFile -PathType Leaf) {
        if ((Get-Item -LiteralPath $CafePassFile).Length -eq 0) {
            throw "The external passfile exists but is empty: $CafePassFile"
        }
        Assert-CafeFaussePassfileAcl -Path $CafePassFile
        foreach ($CafeRequiredLogin in @($CafeAppLogin, $CafeAdminLogin)) {
            if (-not (Select-String -LiteralPath $CafePassFile -SimpleMatch ":${CafeRequiredLogin}:" -Quiet)) {
                throw "The passfile has no entry for required login: $CafeRequiredLogin"
            }
        }
        $env:PGPASSFILE = $CafePassFile
        Write-Host 'TEST CREDENTIAL PASS: protected passfile contains both required login entries.'
        return
    }

    $CafeAppSecurePassword = $null
    $CafeManagerSecurePassword = $null
    try {
        $CafeAppSecurePassword = Read-Host "Password for $CafeAppLogin" -AsSecureString
        $env:PGPASSWORD = [System.Net.NetworkCredential]::new(
            '', $CafeAppSecurePassword
        ).Password

        $CafeManagerSecurePassword = Read-Host "Password for $CafeAdminLogin (external test management)" -AsSecureString
        $env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD = [System.Net.NetworkCredential]::new(
            '', $CafeManagerSecurePassword
        ).Password
    }
    finally {
        if ($null -ne $CafeAppSecurePassword) { $CafeAppSecurePassword.Dispose() }
        if ($null -ne $CafeManagerSecurePassword) { $CafeManagerSecurePassword.Dispose() }
        Remove-Variable CafeAppSecurePassword -ErrorAction SilentlyContinue
        Remove-Variable CafeManagerSecurePassword -ErrorAction SilentlyContinue
    }

    if ([string]::IsNullOrEmpty($env:PGPASSWORD) -or
        [string]::IsNullOrEmpty($env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD)) {
        Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
        Remove-Item Env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD -ErrorAction SilentlyContinue
        throw 'One or both interactive PostgreSQL passwords were empty.'
    }

    Write-Host 'TEST CREDENTIAL PASS: deployment and test-management passwords were read interactively.'
}

Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"
```

Expected verification output is exactly one of:

```text
STEP 3 PASS: credential source is the protected external PGPASSFILE.
STEP 3 PASS: credential source is interactive PGPASSWORD for this PowerShell process.
```

An interactive value is plain text only after assignment to the current
process environment, which is necessary for libpq. It is inherited by child
processes. Step 16 restores the original values or original absence of both
interactive test variables. Run
`Set-CafeFausseCredential` again with the appropriate identity in the prompt
whenever a single-login step changes identities. Steps 11 and 12 instead call
`Set-CafeFaussePytestCredentials`, which supports the passfile or prompts for
both logins without displaying either password. Do not print any credential
environment variable.

## 4. Create and verify the nonproduction database

Create the database when absent or validate and reuse it when present. An
existing database is accepted only when it has the exact safe name, owner, and
PostgreSQL version required here:

```powershell
Start-CafeFausseTestPostgres

$CafeDatabaseExistsOutput = & (Join-Path $CafePgBin 'psql.exe') `
    -X -tA -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 `
    -p $CafePort `
    -U $CafeAdminLogin `
    -d postgres `
    -c "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$CafeDatabase');" 2>&1
$CafeDatabaseExistsExitCode = $LASTEXITCODE
$CafeDatabaseExistsText = ($CafeDatabaseExistsOutput -join [Environment]::NewLine).Trim()
if ($CafeDatabaseExistsExitCode -ne 0 -or $CafeDatabaseExistsText -notmatch '^(t|f)$') {
    throw "Database existence check failed with exit code $CafeDatabaseExistsExitCode`: $CafeDatabaseExistsText"
}

if ($CafeDatabaseExistsText -eq 'f') {
    & (Join-Path $CafePgBin 'createdb.exe') `
        -h 127.0.0.1 `
        -p $CafePort `
        -U $CafeAdminLogin `
        --owner=$CafeAdminLogin `
        $CafeDatabase
    $CafeCreateDatabaseExitCode = $LASTEXITCODE
    if ($CafeCreateDatabaseExitCode -ne 0) {
        throw "createdb failed with exit code $CafeCreateDatabaseExitCode"
    }
} else {
    Write-Host "Database $CafeDatabase already exists; validating it instead of recreating it."
}

$CafeDatabaseEvidence = & (Join-Path $CafePgBin 'psql.exe') `
    -X -tA -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 `
    -p $CafePort `
    -U $CafeAdminLogin `
    -d $CafeDatabase `
    -c "SELECT current_database() || '|' || current_setting('server_version_num') || '|' || pg_catalog.pg_get_userbyid(datdba) FROM pg_catalog.pg_database WHERE datname = current_database();"

$CafeDatabaseEvidenceExitCode = $LASTEXITCODE
$CafeDatabaseEvidenceText = ($CafeDatabaseEvidence -join [Environment]::NewLine).Trim()
if ($CafeDatabaseEvidenceExitCode -ne 0 -or
    $CafeDatabaseEvidenceText -ne "$CafeDatabase|180003|$CafeAdminLogin") {
    throw "Unexpected database evidence: $CafeDatabaseEvidence"
}

Write-Host "STEP 4 PASS: database=$CafeDatabase; server_version_num=180003; owner=$CafeAdminLogin"
```

The result must identify `cafe_fausse_test_api04` and version number `180003`.
Do not continue if either value differs.

Expected verification output:

```text
STEP 4 PASS: database=cafe_fausse_test_api04; server_version_num=180003; owner=cafe_fausse_admin
```

## 5. Build and verify the approved database baseline

Set the guarded database-script environment. The repository scripts verify
both the requested and actual database names before resetting the fixed
`cafe_fausse` schema.

```powershell
Start-CafeFausseTestPostgres

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
group roles, not login accounts. The cluster administrator already receives
the owner and test-management memberships from the approved provisioning
script. The next step creates only the separate app-only deployment login.

Expected verification output ends with:

```text
STEP 5 PASS: approved database baseline rebuilt and verified.
```

## 6. Create the app-only deployment login

Run this one PowerShell block in its entirety. It safely performs every Step 6
operation in sequence: start PostgreSQL, authenticate as the administrator,
create or normalize the app-only login, remove elevated memberships, grant
only `cafe_fausse_app`, set the app password through an isolated `psql`
password command, verify that PostgreSQL stored a password, update the detected
passfile when present, authenticate as the app login, assume
`cafe_fausse_app`, and verify the final boundary.

The isolated `psql` password command deliberately pauses twice on every run:

```text
Enter new password for user "cafe_fausse_api04_login":
Enter it again:
```

Do not paste anything during those two prompts; enter the same new app password
twice. Use a password different from the administrator password. If a passfile
is present, the block then asks once more for that same app password so it can
refresh the external passfile entry. If no passfile is present, it asks once
more to authenticate and prove the new password. No password is placed in SQL,
a command-line argument, documentation, or output.

```powershell
Start-CafeFausseTestPostgres
Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"

$CafeRoleSetupSql = @'
DO $role_setup$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_roles
        WHERE rolname = 'cafe_fausse_api04_login'
    ) THEN
        CREATE ROLE cafe_fausse_api04_login
            LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
            NOBYPASSRLS NOINHERIT;
    END IF;
END
$role_setup$;

ALTER ROLE cafe_fausse_api04_login
    LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
    NOBYPASSRLS NOINHERIT;
REVOKE cafe_fausse_owner FROM cafe_fausse_api04_login;
REVOKE cafe_fausse_test FROM cafe_fausse_api04_login;
GRANT cafe_fausse_app TO cafe_fausse_api04_login;
GRANT CONNECT ON DATABASE cafe_fausse_test_api04
    TO cafe_fausse_api04_login;
'@

$CafeRoleSetupSql | & (Join-Path $CafePgBin 'psql.exe') `
    -X -q -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort `
    -U $CafeAdminLogin -d $CafeDatabase
$CafeRoleSetupExitCode = $LASTEXITCODE
Remove-Variable CafeRoleSetupSql -ErrorAction SilentlyContinue
if ($CafeRoleSetupExitCode -ne 0) {
    throw "Deployment-login creation or normalization failed with exit code $CafeRoleSetupExitCode"
}

Write-Host 'Set the app-login password. The next command prompts twice.'
& (Join-Path $CafePgBin 'psql.exe') `
    -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort `
    -U $CafeAdminLogin -d $CafeDatabase `
    -c '\password cafe_fausse_api04_login'
$CafePasswordSetExitCode = $LASTEXITCODE
if ($CafePasswordSetExitCode -ne 0) {
    throw "Deployment-login password assignment failed with exit code $CafePasswordSetExitCode"
}

$CafePasswordEvidence = & (Join-Path $CafePgBin 'psql.exe') `
    -X -qAt -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort `
    -U $CafeAdminLogin -d $CafeDatabase `
    -c "SELECT rolpassword IS NOT NULL FROM pg_catalog.pg_authid WHERE rolname = 'cafe_fausse_api04_login';"
$CafePasswordEvidenceExitCode = $LASTEXITCODE
$CafePasswordEvidenceText = ($CafePasswordEvidence -join [Environment]::NewLine).Trim()
if ($CafePasswordEvidenceExitCode -ne 0 -or $CafePasswordEvidenceText -ne 't') {
    throw "PostgreSQL did not retain the deployment-login password; evidence: $CafePasswordEvidenceText"
}

if (Test-Path -LiteralPath $CafePassFile -PathType Leaf) {
    if (-not (Get-Command Set-CafeFaussePassfileEntry -ErrorAction SilentlyContinue)) {
        throw 'The passfile exists, but its Step 3 management helper is not loaded. Rerun the optional passfile block in Step 3.'
    }
    Set-CafeFaussePassfileEntry `
        -Login $CafeAppLogin `
        -DatabaseName $CafeDatabase `
        -Prompt "Enter the same password for $CafeAppLogin to refresh its passfile entry"
}

Set-CafeFausseCredential -Prompt "Enter the new password for $CafeAppLogin to verify authentication"
$CafeAppRoleEvidence = & (Join-Path $CafePgBin 'psql.exe') `
    -X -qAt -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort `
    -U $CafeAppLogin -d $CafeDatabase `
    -c "SET ROLE cafe_fausse_app; SELECT concat_ws('|', session_user, current_user); RESET ROLE;"
$CafeAppRoleExitCode = $LASTEXITCODE
$CafeAppRoleEvidenceText = ($CafeAppRoleEvidence -join [Environment]::NewLine).Trim()
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue

if ($CafeAppRoleExitCode -ne 0 -or
    $CafeAppRoleEvidenceText -ne "$CafeAppLogin|cafe_fausse_app") {
    throw "Deployment-login authentication or role verification failed; received: $CafeAppRoleEvidenceText"
}

Write-Host 'STEP 6 PASS: app-only deployment login, password, authentication, and role boundary verified.'
```

Expected final output:

```text
STEP 6 PASS: app-only deployment login, password, authentication, and role boundary verified.
```

## 7. Audit role separation before testing

Run the membership and login-attribute audit as the administrator. These
queries inspect direct grants rather than treating a superuser's inherent
ability to assume roles as an explicit membership:

```powershell
Start-CafeFausseTestPostgres
Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"

$CafeMembershipEvidence = & (Join-Path $CafePgBin 'psql.exe') `
    -X -qAt -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeAdminLogin -d $CafeDatabase `
    -c @'
SELECT concat_ws('|',
    EXISTS (
        SELECT 1 FROM pg_catalog.pg_auth_members membership
        JOIN pg_catalog.pg_roles granted_role ON granted_role.oid = membership.roleid
        JOIN pg_catalog.pg_roles member_role ON member_role.oid = membership.member
        WHERE granted_role.rolname = 'cafe_fausse_app'
          AND member_role.rolname = 'cafe_fausse_api04_login'
    ),
    EXISTS (
        SELECT 1 FROM pg_catalog.pg_auth_members membership
        JOIN pg_catalog.pg_roles granted_role ON granted_role.oid = membership.roleid
        JOIN pg_catalog.pg_roles member_role ON member_role.oid = membership.member
        WHERE granted_role.rolname = 'cafe_fausse_test'
          AND member_role.rolname = 'cafe_fausse_api04_login'
    ),
    EXISTS (
        SELECT 1 FROM pg_catalog.pg_auth_members membership
        JOIN pg_catalog.pg_roles granted_role ON granted_role.oid = membership.roleid
        JOIN pg_catalog.pg_roles member_role ON member_role.oid = membership.member
        WHERE granted_role.rolname = 'cafe_fausse_owner'
          AND member_role.rolname = 'cafe_fausse_api04_login'
    ),
    EXISTS (
        SELECT 1 FROM pg_catalog.pg_auth_members membership
        JOIN pg_catalog.pg_roles granted_role ON granted_role.oid = membership.roleid
        JOIN pg_catalog.pg_roles member_role ON member_role.oid = membership.member
        WHERE granted_role.rolname = 'cafe_fausse_test'
          AND member_role.rolname = 'cafe_fausse_admin'
    )
);
'@
if ($LASTEXITCODE -ne 0 -or $CafeMembershipEvidence -ne 't|f|f|t') {
    throw "Role membership audit failed; expected t|f|f|t, received: $CafeMembershipEvidence"
}

$CafeAppAttributeEvidence = & (Join-Path $CafePgBin 'psql.exe') `
    -X -qAt -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeAdminLogin -d $CafeDatabase `
    -c "SELECT concat_ws('|', rolcanlogin, rolsuper, rolcreatedb, rolcreaterole, rolreplication, rolbypassrls, rolinherit) FROM pg_catalog.pg_roles WHERE rolname = 'cafe_fausse_api04_login';"
if ($LASTEXITCODE -ne 0 -or $CafeAppAttributeEvidence -ne 't|f|f|f|f|f|f') {
    throw "Deployment-login attribute audit failed; expected t|f|f|f|f|f|f, received: $CafeAppAttributeEvidence"
}
```

Confirm that the app login assumes only the app role and the administrator can
enter the external test-management boundary:

```powershell
Set-CafeFausseCredential -Prompt "Password for $CafeAppLogin"
$CafeAppRoleEvidence = & (Join-Path $CafePgBin 'psql.exe') -X -qAt -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeAppLogin -d $CafeDatabase `
    -c "SET ROLE cafe_fausse_app; SELECT concat_ws('|', session_user, current_user); RESET ROLE;"
if ($LASTEXITCODE -ne 0 -or $CafeAppRoleEvidence -ne "$CafeAppLogin|cafe_fausse_app") {
    throw "Deployment-login role audit failed; received: $CafeAppRoleEvidence"
}

Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"
$CafeTestRoleEvidence = & (Join-Path $CafePgBin 'psql.exe') -X -qAt -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 -p $CafePort -U $CafeAdminLogin -d $CafeDatabase `
    -c "SET ROLE cafe_fausse_test; SELECT concat_ws('|', session_user, current_user); RESET ROLE;"
if ($LASTEXITCODE -ne 0 -or $CafeTestRoleEvidence -ne "$CafeAdminLogin|cafe_fausse_test") {
    throw "Administrator test-role audit failed; received: $CafeTestRoleEvidence"
}

Write-Host 'STEP 7 PASS: app-only deployment login and administrator test-management boundary verified.'
```

Every comparison is automated. Any unexpected membership, deployment-login
attribute, authentication failure, or wrong active role throws a targeted
error. Expected final verbiage:

```text
STEP 7 PASS: app-only deployment login and administrator test-management boundary verified.
```

## 8. Run the complete PostgreSQL test suite

Keep the administrator selected because the database runner performs guarded
rebuilds and provisions cluster roles:

```powershell
Start-CafeFausseTestPostgres
Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"
$env:CAFE_FAUSSE_PSQL = Join-Path $CafePgBin 'psql.exe'
$env:PGUSER = $CafeAdminLogin
$env:PGHOST = '127.0.0.1'
$env:PGPORT = $CafePort
$env:PGDATABASE = $CafeDatabase
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

Create or repair the marker-owned temporary virtual environment and install
the fixed test dependency set. A valid task-owned environment is reused. A
partial, broken, or wrong-version task-owned environment is removed only after
its exact path beneath the marked temporary root is checked. No repository
`.venv`, cache, coverage, bytecode, or package metadata is read or removed.

```powershell
$CafeRebuildVenv = $false
if (Test-Path -LiteralPath $CafeVenvRoot) {
    if (-not (Test-Path -LiteralPath $CafeVenvPython -PathType Leaf)) {
        $CafeRebuildVenv = $true
    }
    else {
        $CafeExistingVenvVersion = & $CafeVenvPython -c "import platform; print(platform.python_version())" 2>&1
        $CafeExistingVenvExitCode = $LASTEXITCODE
        if ($CafeExistingVenvExitCode -ne 0 -or
            ($CafeExistingVenvVersion -join '').Trim() -ne '3.14.6') {
            $CafeRebuildVenv = $true
        }
    }
}

if ($CafeRebuildVenv) {
    $CafeRecordedMarker = (Get-Content -LiteralPath $CafeClusterMarker -Raw).Trim()
    if ($CafeRecordedMarker -ne $CafeMarkerText) {
        throw "Cluster ownership marker does not match before environment cleanup."
    }
    $CafeResolvedVenv = [System.IO.Path]::GetFullPath($CafeVenvRoot)
    $CafeExpectedVenv = [System.IO.Path]::GetFullPath(
        (Join-Path $CafeExpectedClusterRoot 'artifacts\venv')
    )
    if (-not $CafeResolvedVenv.Equals(
        $CafeExpectedVenv,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing virtual-environment cleanup outside the expected path: $CafeResolvedVenv"
    }
    Remove-Item -LiteralPath $CafeVenvRoot -Recurse -Force
}

if (-not (Test-Path -LiteralPath $CafeVenvPython -PathType Leaf)) {
    New-Item -ItemType Directory -Path $CafeArtifactRoot -Force | Out-Null
    & $CafePythonExecutable @CafePythonLauncherArguments -m venv $CafeVenvRoot
    if ($LASTEXITCODE -ne 0) { throw 'Backend virtual-environment creation failed.' }
}

$env:COVERAGE_FILE = $CafeCoverageFile
$env:PIP_CACHE_DIR = $CafePipCache
$env:PYTHONPATH = Join-Path $CafeRepo 'backend\src'
$env:PYTHONPYCACHEPREFIX = $CafePythonCache

& $CafeVenvPython -m pip install `
    --disable-pip-version-check --quiet `
    --cache-dir $CafePipCache `
    'Flask==3.1.3' `
    'psycopg[binary]==3.2.13' `
    'psycopg-pool==3.2.8' `
    'pytest==9.1.1' `
    'pytest-cov==7.1.0'
if ($LASTEXITCODE -ne 0) { throw 'Backend test dependency installation failed.' }

$CafePythonVersionLines = & $CafeVenvPython -c "import platform; print(platform.python_version())" 2>&1
$CafePythonCheckExitCode = $LASTEXITCODE
$CafePythonVersion = ($CafePythonVersionLines -join [Environment]::NewLine).Trim()
$CafePackageVersionLines = & $CafeVenvPython -c "import importlib.metadata as m; print('|'.join(m.version(n) for n in ('Flask','psycopg','psycopg-binary','psycopg-pool','pytest','pytest-cov')))" 2>&1
$CafePackageCheckExitCode = $LASTEXITCODE
$CafePackageVersions = ($CafePackageVersionLines -join [Environment]::NewLine).Trim()

if ($CafePythonCheckExitCode -ne 0 -or $CafePythonVersion -ne '3.14.6') {
    throw "Expected CPython 3.14.6; received $CafePythonVersion"
}
if ($CafePackageCheckExitCode -ne 0 -or
    $CafePackageVersions -ne '3.1.3|3.2.13|3.2.13|3.2.8|9.1.1|7.1.0') {
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
Push-Location (Join-Path $CafeRepo 'backend')
try {
    & $CafeVenvPython -m pytest -o "cache_dir=$CafePytestCache"
    if ($LASTEXITCODE -ne 0) { throw 'Default backend tests failed.' }

    & $CafeVenvPython -m pytest -o "cache_dir=$CafePytestCache" -m unit
    if ($LASTEXITCODE -ne 0) { throw 'Backend unit tests failed.' }

    & $CafeVenvPython -m pytest -o "cache_dir=$CafePytestCache" -m api
    if ($LASTEXITCODE -ne 0) { throw 'Backend API tests failed.' }
}
finally {
    Pop-Location
}
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
existing cluster administrator for external fixture management. The helper
uses a protected passfile when present; otherwise it prompts securely for the
deployment password and administrator password. It replaces prior test
credential state on every call, so rerunning this step is safe.

```powershell
Start-CafeFausseTestPostgres
Set-CafeFaussePytestCredentials

$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = $CafePort
$env:PGDATABASE = $CafeDatabase
$env:PGUSER = $CafeAppLogin
$env:CAFE_FAUSSE_TEST_MANAGER_USER = $CafeAdminLogin
$env:CAFE_FAUSSE_TEST_PGDATA = $CafeDataDir

Push-Location (Join-Path $CafeRepo 'backend')
try {
    & $CafeVenvPython -m pytest -o "cache_dir=$CafePytestCache" -m "integration and postgres"
    $CafeIntegrationExit = $LASTEXITCODE
}
finally {
    Pop-Location
}

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

Reestablish the application, test-management, database, credential, and data
directory variables. This makes Step 12 independently repeatable even after a
new PowerShell command changed credentials:

```powershell
Start-CafeFausseTestPostgres
Set-CafeFaussePytestCredentials

$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = $CafePort
$env:PGDATABASE = $CafeDatabase
$env:PGUSER = $CafeAppLogin
$env:CAFE_FAUSSE_TEST_MANAGER_USER = $CafeAdminLogin
$env:CAFE_FAUSSE_TEST_PGDATA = $CafeDataDir

Push-Location (Join-Path $CafeRepo 'backend')
try {
    & $CafeVenvPython -m pytest -o "cache_dir=$CafePytestCache" `
        -m "unit or api or integration" `
        --cov=cafe_fausse `
        --cov-report=term-missing
    $CafeCoverageExit = $LASTEXITCODE
}
finally {
    Pop-Location
}

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

## 13. Perform a repeatable Flask health smoke test

The database scripts and test manager use variables that are intentionally not
valid Flask application settings. This step removes them, keeps the deployment
login selected, and uses the dedicated `$CafeFlaskPort` from Step 1. An
existing health service is queried or reused only after the PID file, expected
virtual-environment interpreter path, and Windows TCP listener owner all prove
that the process belongs to this runbook. If any process occupies the port
without that complete ownership evidence, the step fails without reusing or
terminating it. A proven task-owned unhealthy process may be replaced.

```powershell
Remove-Item Env:CAFE_FAUSSE_ALLOW_RESET -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_PSQL -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_TEST_MANAGER_USER -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_TEST_PGDATA -ErrorAction SilentlyContinue

Start-CafeFausseTestPostgres
Set-CafeFausseCredential -Prompt "Password for $CafeAppLogin"

$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = $CafePort
$env:PGDATABASE = $CafeDatabase
$env:PGUSER = $CafeAppLogin

function Get-CafeFausseFlaskListenerOwner {
    if (-not (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue)) {
        throw 'Get-NetTCPConnection is required to prove Flask port ownership.'
    }
    try {
        $CafeFlaskListeners = @(
            Get-NetTCPConnection -State Listen -ErrorAction Stop |
                Where-Object { $_.LocalPort -eq [int]$CafeFlaskPort }
        )
    }
    catch {
        throw "Could not inspect TCP listener ownership for port $CafeFlaskPort."
    }

    $CafeFlaskListenerOwners = @(
        $CafeFlaskListeners |
            ForEach-Object { $_.OwningProcess } |
            Sort-Object -Unique
    )
    if ($CafeFlaskListenerOwners.Count -gt 1) {
        throw "Multiple processes listen on dedicated Flask port $CafeFlaskPort; refusing reuse or termination."
    }
    if ($CafeFlaskListenerOwners.Count -eq 0) {
        return $null
    }
    return [int]$CafeFlaskListenerOwners[0]
}

function Get-CafeFausseRecordedFlaskOwnership {
    param(
        [Parameter(Mandatory)][int]$ListenerProcessId,
        [Parameter(Mandatory)][int]$LauncherProcessId
    )

    $CafeListenerProcess = Get-Process `
        -Id $ListenerProcessId `
        -ErrorAction SilentlyContinue
    $CafeLauncherProcess = Get-Process `
        -Id $LauncherProcessId `
        -ErrorAction SilentlyContinue
    if ($null -eq $CafeListenerProcess -and
        $null -eq $CafeLauncherProcess) {
        return $null
    }
    if ($null -eq $CafeListenerProcess -or
        $null -eq $CafeLauncherProcess) {
        throw 'Recorded Flask listener/launcher process pair is incomplete; refusing reuse or termination.'
    }

    try {
        $CafeLauncherPath = $CafeLauncherProcess.Path
    }
    catch {
        throw "Cannot inspect recorded Flask launcher PID $LauncherProcessId; refusing reuse or termination."
    }
    if ([string]::IsNullOrWhiteSpace($CafeLauncherPath) -or
        -not [System.IO.Path]::GetFullPath($CafeLauncherPath).Equals(
            [System.IO.Path]::GetFullPath($CafeVenvPython),
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw "Recorded launcher PID $LauncherProcessId does not use the expected backend virtual-environment interpreter; refusing reuse or termination."
    }

    try {
        $CafeListenerProcessRecord = Get-CimInstance `
            -ClassName Win32_Process `
            -Filter "ProcessId = $ListenerProcessId" `
            -ErrorAction Stop
    }
    catch {
        throw "Cannot inspect the parent of Flask listener PID $ListenerProcessId; refusing reuse or termination."
    }
    if ($null -eq $CafeListenerProcessRecord -or
        [int]$CafeListenerProcessRecord.ParentProcessId -ne
            $LauncherProcessId) {
        throw "Flask listener PID $ListenerProcessId is not a child of recorded virtual-environment launcher PID $LauncherProcessId; refusing reuse or termination."
    }

    return [pscustomobject]@{
        Listener = $CafeListenerProcess
        Launcher = $CafeLauncherProcess
    }
}

function Stop-CafeFausseRecordedFlaskOwnership {
    param([Parameter(Mandatory)]$Ownership)

    if (-not $Ownership.Listener.HasExited) {
        Stop-Process -Id $Ownership.Listener.Id -Force
        [void]$Ownership.Listener.WaitForExit(10000)
    }
    if (-not $Ownership.Launcher.HasExited) {
        Stop-Process -Id $Ownership.Launcher.Id -Force
        [void]$Ownership.Launcher.WaitForExit(10000)
    }
}

function Test-CafeFausseHealth {
    try {
        $CafeLiveness = Invoke-RestMethod `
            -Uri "http://127.0.0.1:$CafeFlaskPort/api/v1/health/liveness" `
            -TimeoutSec 3
        $CafeReadiness = Invoke-RestMethod `
            -Uri "http://127.0.0.1:$CafeFlaskPort/api/v1/health/readiness" `
            -TimeoutSec 3
        return (
            $CafeLiveness.status -eq 'live' -and
            $CafeReadiness.status -eq 'ready'
        )
    }
    catch {
        return $false
    }
}

$CafeStartFlask = $false
$CafeOwnedFlaskOwnership = $null
$CafeListenerOwner = Get-CafeFausseFlaskListenerOwner

if (Test-Path -LiteralPath $CafeFlaskPidFile -PathType Leaf) {
    $CafeRecordedFlaskPidText = (Get-Content -LiteralPath $CafeFlaskPidFile -Raw).Trim()
    if ($CafeRecordedFlaskPidText -notmatch '^(\d+)\|(\d+)$') {
        throw "Invalid task-owned Flask PID file: $CafeFlaskPidFile"
    }
    $CafeRecordedListenerPid = [int]$Matches[1]
    $CafeRecordedLauncherPid = [int]$Matches[2]
    $CafeRecordedFlaskOwnership = Get-CafeFausseRecordedFlaskOwnership `
        -ListenerProcessId $CafeRecordedListenerPid `
        -LauncherProcessId $CafeRecordedLauncherPid

    if ($null -eq $CafeRecordedFlaskOwnership) {
        if ($null -ne $CafeListenerOwner) {
            throw "Dedicated Flask port $CafeFlaskPort is owned by unrecorded PID $CafeListenerOwner; refusing reuse or termination."
        }
        Remove-Item -LiteralPath $CafeFlaskPidFile -Force
        $CafeStartFlask = $true
    }
    elseif ($null -ne $CafeListenerOwner -and
        $CafeListenerOwner -ne $CafeRecordedFlaskOwnership.Listener.Id) {
        throw "Dedicated Flask port $CafeFlaskPort is owned by PID $CafeListenerOwner, not recorded listener PID $CafeRecordedListenerPid; refusing reuse or termination."
    }
    elseif ($null -eq $CafeListenerOwner) {
        Stop-CafeFausseRecordedFlaskOwnership `
            -Ownership $CafeRecordedFlaskOwnership
        Remove-Item -LiteralPath $CafeFlaskPidFile -Force
        $CafeStartFlask = $true
    }
    elseif (Test-CafeFausseHealth) {
        $CafeOwnedFlaskOwnership = $CafeRecordedFlaskOwnership
        Write-Host ((
            "Reusing verified task-owned Flask listener PID {0} " +
            "through virtual-environment launcher PID {1}."
        ) -f
            $CafeOwnedFlaskOwnership.Listener.Id,
            $CafeOwnedFlaskOwnership.Launcher.Id
        )
    }
    else {
        Stop-CafeFausseRecordedFlaskOwnership `
            -Ownership $CafeRecordedFlaskOwnership
        Remove-Item -LiteralPath $CafeFlaskPidFile -Force
        $CafeStartFlask = $true
    }
} else {
    if ($null -ne $CafeListenerOwner) {
        throw "Dedicated Flask port $CafeFlaskPort is occupied by unrecorded PID $CafeListenerOwner; refusing reuse or termination."
    }
    $CafeStartFlask = $true
}

if ($CafeStartFlask) {
    $CafeListenerOwner = Get-CafeFausseFlaskListenerOwner
    if ($null -ne $CafeListenerOwner) {
        throw "Dedicated Flask port $CafeFlaskPort became occupied by PID $CafeListenerOwner; refusing startup or termination."
    }
    Remove-Item -LiteralPath $CafeFlaskOutputLog -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $CafeFlaskErrorLog -Force -ErrorAction SilentlyContinue
    $CafeFlaskLauncherProcess = Start-Process `
        -FilePath $CafeVenvPython `
        -ArgumentList @(
            '-m', 'flask', '--app', 'cafe_fausse', 'run',
            '--host', '127.0.0.1', '--port', $CafeFlaskPort,
            '--no-reload', '--no-debugger'
        ) `
        -WorkingDirectory (Join-Path $CafeRepo 'backend') `
        -RedirectStandardOutput $CafeFlaskOutputLog `
        -RedirectStandardError $CafeFlaskErrorLog `
        -WindowStyle Hidden `
        -PassThru

    $CafeHealthReady = $false
    $CafeOwnershipFailure = $null
    for ($CafeAttempt = 1; $CafeAttempt -le 30; $CafeAttempt++) {
        if ($CafeFlaskLauncherProcess.HasExited) {
            break
        }
        $CafeStartedListenerOwner = Get-CafeFausseFlaskListenerOwner
        if ($null -ne $CafeStartedListenerOwner) {
            try {
                $CafeStartedOwnership = Get-CafeFausseRecordedFlaskOwnership `
                    -ListenerProcessId $CafeStartedListenerOwner `
                    -LauncherProcessId $CafeFlaskLauncherProcess.Id
            }
            catch {
                $CafeOwnershipFailure = $_.Exception.Message
                break
            }

            if ($null -ne $CafeStartedOwnership) {
                $CafeOwnedFlaskOwnership = $CafeStartedOwnership
                Set-Content `
                    -LiteralPath $CafeFlaskPidFile `
                    -Value ("{0}|{1}" -f
                        $CafeStartedOwnership.Listener.Id,
                        $CafeStartedOwnership.Launcher.Id) `
                    -Encoding ASCII
                if (Test-CafeFausseHealth) {
                    $CafeHealthReady = $true
                    break
                }
            }
        }
        Start-Sleep -Seconds 1
    }

    if (-not $CafeHealthReady) {
        if ($null -ne $CafeOwnedFlaskOwnership) {
            Stop-CafeFausseRecordedFlaskOwnership `
                -Ownership $CafeOwnedFlaskOwnership
        }
        elseif (-not $CafeFlaskLauncherProcess.HasExited) {
            # The launcher is the only process whose ownership is proven here.
            # Do not terminate a listener unless the parent/launcher proof passed.
            Stop-Process -Id $CafeFlaskLauncherProcess.Id -Force
            [void]$CafeFlaskLauncherProcess.WaitForExit(10000)
        }
        Remove-Item -LiteralPath $CafeFlaskPidFile -Force -ErrorAction SilentlyContinue
        $CafeFlaskFailure = @(
            if (-not [string]::IsNullOrWhiteSpace($CafeOwnershipFailure)) {
                $CafeOwnershipFailure
            }
            if (Test-Path -LiteralPath $CafeFlaskErrorLog) {
                Get-Content -LiteralPath $CafeFlaskErrorLog -Tail 30
            }
        ) -join [Environment]::NewLine
        throw "Flask health endpoints did not become ready: $CafeFlaskFailure"
    }
}

$CafeFinalFlaskOwnership = Get-CafeFausseRecordedFlaskOwnership `
    -ListenerProcessId $CafeOwnedFlaskOwnership.Listener.Id `
    -LauncherProcessId $CafeOwnedFlaskOwnership.Launcher.Id
$CafeFinalListenerOwner = Get-CafeFausseFlaskListenerOwner
if ($null -eq $CafeFinalFlaskOwnership -or
    $CafeFinalListenerOwner -ne $CafeFinalFlaskOwnership.Listener.Id -or
    -not (Test-CafeFausseHealth)) {
    throw 'Final task-owned Flask process-chain, interpreter, listener, or health proof failed.'
}

Write-Host ((
    "STEP 13 PASS: task-owned Flask listener PID={0} through " +
    "virtual-environment launcher PID={1} on 127.0.0.1:{2}; " +
    "liveness=live; readiness=ready."
) -f
    $CafeFinalFlaskOwnership.Listener.Id,
    $CafeFinalFlaskOwnership.Launcher.Id,
    $CafeFlaskPort
)
```

Liveness must report `status = live`. Readiness must report
`status = ready`. On Windows, the virtual-environment launcher may create a
separate child Python process that owns the TCP listener, so the task PID file
records `<listener-pid>|<launcher-pid>`. Both PIDs, their parent-child
relationship, the launcher interpreter path, and the TCP listener must agree
before any health request, reuse, replacement, or cleanup. The development
server is local-only and remains available for a repeated Step 13. Step 16
safely stops it when this complete task-ownership proof succeeds. Expected
verification output:

```text
STEP 13 PASS: task-owned Flask listener PID=<listener-pid> through virtual-environment launcher PID=<launcher-pid> on 127.0.0.1:55004; liveness=live; readiness=ready.
```

## 14. Restore and prove the clean baseline

Automated integration tests manage their own data, but finish every formal run
by rebuilding with the administrator and verifying the empty approved
baseline:

```powershell
Start-CafeFausseTestPostgres
Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"
$env:CAFE_FAUSSE_PSQL = Join-Path $CafePgBin 'psql.exe'
$env:CAFE_FAUSSE_ENVIRONMENT = 'test'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
$env:PGHOST = '127.0.0.1'
$env:PGPORT = $CafePort
$env:PGDATABASE = $CafeDatabase
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

$CafeBaselineCountsExitCode = $LASTEXITCODE
$CafeBaselineCountsText = ($CafeBaselineCounts -join [Environment]::NewLine).Trim()
if ($CafeBaselineCountsExitCode -ne 0 -or $CafeBaselineCountsText -ne '0|0|0|1|7|30') {
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
& $CafeVenvPython -m compileall -q backend\src backend\tests
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

## 16. Self-clean all test objects while preserving the external administrator credential

Run this one PowerShell block after all tests and evidence collection. It is
safe to repeat and removes the objects created by this runbook:

- the `cafe_fausse_test_api04` database;
- the app login, legacy three-login test-manager login if present, and the
  three Cafe Fausse group roles;
- the app and legacy test-manager entries from the external passfile;
- the task-owned Flask process, PID file, Flask/PostgreSQL logs, and temporary
  `artifacts` directory containing the virtual environment, pytest/coverage
  data, Python bytecode, and pip cache;
- the entire task-owned `%TEMP%\CafeFausse-api04-local` directory, including
  `PGDATA` and its safety marker;
- task-set process environment values, after which every captured variable is
  restored to its original value or original absence without being displayed.

PostgreSQL stores its administrator password verifier inside `PGDATA`, so
deleting the cluster necessarily deletes that database-side verifier. The
credential retained by this step is the protected external administrator
passfile entry, when that optional file exists. In interactive mode, the
runbook has no persistent password file to retain; the next Step 2 run prompts
for the administrator password again. Step 16 never changes, displays, or
writes that password to the repository.

```powershell
$CafeExpectedCleanupRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $env:TEMP 'CafeFausse-api04-local')
)
$CafeResolvedCleanupRoot = [System.IO.Path]::GetFullPath($CafeClusterRoot)
if (-not $CafeResolvedCleanupRoot.Equals(
    $CafeExpectedCleanupRoot,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Refusing cleanup for an unexpected cluster root: $CafeResolvedCleanupRoot"
}
if ($CafeDatabase -ne 'cafe_fausse_test_api04' -or
    $CafeDatabase -notlike 'cafe_fausse_test_*') {
    throw "Refusing cleanup for unexpected database name: $CafeDatabase"
}
if ($CafeAppLogin -ne 'cafe_fausse_api04_login' -or
    $CafeAdminLogin -ne 'cafe_fausse_admin') {
    throw 'Refusing cleanup for unexpected PostgreSQL login names.'
}
if (Test-Path -LiteralPath $CafeResolvedCleanupRoot) {
    if (-not (Test-Path -LiteralPath $CafeClusterMarker -PathType Leaf)) {
        throw "Refusing cleanup because the task root has no ownership marker: $CafeResolvedCleanupRoot"
    }
    $CafeCleanupMarkerText = (Get-Content -LiteralPath $CafeClusterMarker -Raw).Trim()
    if ($CafeCleanupMarkerText -ne $CafeMarkerText) {
        throw "Refusing cleanup because the task-root ownership marker differs."
    }
}

# Stop only a recorded Flask listener/launcher pair whose interpreter,
# parent-child relationship, and listener ownership all agree. Never terminate
# an unrecorded process on the dedicated port.
if (-not (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue)) {
    throw 'Get-NetTCPConnection is required to prove Flask cleanup ownership.'
}
try {
    $CafeCleanupFlaskListeners = @(
        Get-NetTCPConnection -State Listen -ErrorAction Stop |
            Where-Object { $_.LocalPort -eq [int]$CafeFlaskPort }
    )
}
catch {
    throw "Could not inspect Flask listener ownership for cleanup on port $CafeFlaskPort."
}
$CafeCleanupFlaskOwners = @(
    $CafeCleanupFlaskListeners |
        ForEach-Object { $_.OwningProcess } |
        Sort-Object -Unique
)
if ($CafeCleanupFlaskOwners.Count -gt 1) {
    throw "Multiple processes occupy dedicated Flask port $CafeFlaskPort; refusing cleanup termination."
}
$CafeCleanupFlaskOwner = if ($CafeCleanupFlaskOwners.Count -eq 1) {
    [int]$CafeCleanupFlaskOwners[0]
} else {
    $null
}

if (Test-Path -LiteralPath $CafeFlaskPidFile -PathType Leaf) {
    $CafeRecordedFlaskPidText = (Get-Content -LiteralPath $CafeFlaskPidFile -Raw).Trim()
    if ($CafeRecordedFlaskPidText -notmatch '^(\d+)\|(\d+)$') {
        throw "Invalid task-owned Flask PID file: $CafeFlaskPidFile"
    }
    if (-not (Get-Command Get-CafeFausseRecordedFlaskOwnership -ErrorAction SilentlyContinue) -or
        -not (Get-Command Stop-CafeFausseRecordedFlaskOwnership -ErrorAction SilentlyContinue)) {
        throw 'Run Step 13 in this PowerShell session before Step 16 so Flask ownership can be proved safely.'
    }
    $CafeRecordedListenerPid = [int]$Matches[1]
    $CafeRecordedLauncherPid = [int]$Matches[2]
    $CafeRecordedFlaskOwnership = Get-CafeFausseRecordedFlaskOwnership `
        -ListenerProcessId $CafeRecordedListenerPid `
        -LauncherProcessId $CafeRecordedLauncherPid
    if ($null -eq $CafeRecordedFlaskOwnership) {
        if ($null -ne $CafeCleanupFlaskOwner) {
            throw "Dedicated Flask port $CafeFlaskPort is owned by unrecorded PID $CafeCleanupFlaskOwner; refusing termination."
        }
    } else {
        if ($null -ne $CafeCleanupFlaskOwner -and
            $CafeCleanupFlaskOwner -ne $CafeRecordedFlaskOwnership.Listener.Id) {
            throw "Dedicated Flask port $CafeFlaskPort is owned by PID $CafeCleanupFlaskOwner, not recorded listener PID $CafeRecordedListenerPid; refusing termination."
        }
        Stop-CafeFausseRecordedFlaskOwnership `
            -Ownership $CafeRecordedFlaskOwnership
    }
    Remove-Item -LiteralPath $CafeFlaskPidFile -Force
} elseif ($null -ne $CafeCleanupFlaskOwner) {
    throw "Dedicated Flask port $CafeFlaskPort is occupied by unrecorded PID $CafeCleanupFlaskOwner; refusing termination."
}

# Remove database and cluster-role objects while retaining cafe_fausse_admin.
if (Test-Path -LiteralPath (Join-Path $CafeDataDir 'PG_VERSION') -PathType Leaf) {
    Start-CafeFausseTestPostgres
    Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin during cleanup"

    & (Join-Path $CafePgBin 'dropdb.exe') `
        --if-exists --force `
        -h 127.0.0.1 -p $CafePort `
        -U $CafeAdminLogin $CafeDatabase
    $CafeDropDatabaseExitCode = $LASTEXITCODE
    if ($CafeDropDatabaseExitCode -ne 0) {
        throw "Test-database cleanup failed with exit code $CafeDropDatabaseExitCode"
    }

    $CafeRoleCleanupSql = @'
DROP ROLE IF EXISTS cafe_fausse_api04_login;
DROP ROLE IF EXISTS cafe_fausse_api04_test_manager;
DROP ROLE IF EXISTS cafe_fausse_app;
DROP ROLE IF EXISTS cafe_fausse_test;
DROP ROLE IF EXISTS cafe_fausse_owner;
SELECT count(*)
FROM pg_catalog.pg_roles
WHERE rolname IN (
    'cafe_fausse_api04_login',
    'cafe_fausse_api04_test_manager',
    'cafe_fausse_app',
    'cafe_fausse_test',
    'cafe_fausse_owner'
);
'@
    $CafeRemainingRoleEvidence = $CafeRoleCleanupSql | & (Join-Path $CafePgBin 'psql.exe') `
        -X -qAt -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p $CafePort `
        -U $CafeAdminLogin -d postgres
    $CafeRoleCleanupExitCode = $LASTEXITCODE
    Remove-Variable CafeRoleCleanupSql -ErrorAction SilentlyContinue
    $CafeRemainingRoleText = ($CafeRemainingRoleEvidence -join [Environment]::NewLine).Trim()
    if ($CafeRoleCleanupExitCode -ne 0 -or $CafeRemainingRoleText -ne '0') {
        throw "Cafe Fausse role cleanup failed; remaining-role evidence: $CafeRemainingRoleText"
    }

    $CafeRemainingDatabaseEvidence = & (Join-Path $CafePgBin 'psql.exe') `
        -X -qAt -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p $CafePort `
        -U $CafeAdminLogin -d postgres `
        -c "SELECT count(*) FROM pg_catalog.pg_database WHERE datname = 'cafe_fausse_test_api04';"
    $CafeDatabaseCleanupExitCode = $LASTEXITCODE
    $CafeRemainingDatabaseText = ($CafeRemainingDatabaseEvidence -join [Environment]::NewLine).Trim()
    if ($CafeDatabaseCleanupExitCode -ne 0 -or $CafeRemainingDatabaseText -ne '0') {
        throw "Test-database cleanup verification failed; evidence: $CafeRemainingDatabaseText"
    }

    $CafeStatusBeforeStopLines = & (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir status 2>&1
    $CafeStatusBeforeStopExitCode = $LASTEXITCODE
    $CafeStatusBeforeStop = $CafeStatusBeforeStopLines -join [Environment]::NewLine

    if ($CafeStatusBeforeStopExitCode -eq 0 -and $CafeStatusBeforeStop -match 'server is running') {
        & (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir -m fast -w stop
        $CafeStopExitCode = $LASTEXITCODE
        if ($CafeStopExitCode -ne 0) {
            throw "PostgreSQL shutdown failed with exit code $CafeStopExitCode"
        }
    }
    elseif ($CafeStatusBeforeStopExitCode -ne 0 -and $CafeStatusBeforeStop -match 'no server running') {
        Write-Host 'PostgreSQL is already stopped; shutdown was not repeated.'
    }
    else {
        throw "Unrecognized PostgreSQL pre-stop status (exit $CafeStatusBeforeStopExitCode): $CafeStatusBeforeStop"
    }
} else {
    Write-Host 'PostgreSQL data directory is absent; database/role cleanup is already satisfied.'
}

# Remove only the non-administrator entries created by this runbook. Preserve
# the administrator entry and every unrelated external passfile entry.
if (Test-Path -LiteralPath $CafePassFile -PathType Leaf) {
    $CafeCleanupPassfilePrefixes = @(
        "127.0.0.1:$CafePort`:$CafeDatabase`:$CafeAppLogin`:",
        "127.0.0.1:$CafePort`:$CafeDatabase`:cafe_fausse_api04_test_manager`:"
    )
    $CafeExistingPassfileLines = @(Get-Content -LiteralPath $CafePassFile)
    [string[]]$CafeRetainedPassfileLines = @(
        $CafeExistingPassfileLines | Where-Object {
            $CafeLine = $_
            @(
                $CafeCleanupPassfilePrefixes | Where-Object {
                    $CafeLine.StartsWith($_, [System.StringComparison]::Ordinal)
                }
            ).Count -eq 0
        }
    )
    [System.IO.File]::WriteAllLines(
        $CafePassFile,
        $CafeRetainedPassfileLines,
        [System.Text.UTF8Encoding]::new($false)
    )
    Protect-CafeFaussePassfileAcl -Path $CafePassFile
    foreach ($CafeRemovedPrefix in $CafeCleanupPassfilePrefixes) {
        if (Select-String -LiteralPath $CafePassFile -SimpleMatch $CafeRemovedPrefix -Quiet) {
            throw "A non-administrator passfile entry survived cleanup: $CafeRemovedPrefix"
        }
    }
}

# Generated Python artifacts exist only under the marker-owned task root.
# Never scan the repository for names that may belong to the developer.
$CafeResolvedArtifactRoot = [System.IO.Path]::GetFullPath($CafeArtifactRoot)
$CafeExpectedArtifactRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $CafeResolvedCleanupRoot 'artifacts')
)
if (-not $CafeResolvedArtifactRoot.Equals(
    $CafeExpectedArtifactRoot,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Refusing cleanup for an unexpected artifact root: $CafeResolvedArtifactRoot"
}
if (Test-Path -LiteralPath $CafeResolvedArtifactRoot) {
    Remove-Item -LiteralPath $CafeResolvedArtifactRoot -Recurse -Force
}

# Remove task logs/PID files beneath the validated temporary cluster root.
foreach ($CafeTaskFile in @(
    $CafeFlaskPidFile,
    $CafeFlaskOutputLog,
    $CafeFlaskErrorLog,
    $CafeLogFile
)) {
    $CafeTaskFileFullPath = [System.IO.Path]::GetFullPath($CafeTaskFile)
    $CafeTaskRootPrefix = $CafeResolvedCleanupRoot.TrimEnd('\') + '\'
    if (-not $CafeTaskFileFullPath.StartsWith(
        $CafeTaskRootPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing task-file cleanup outside validated cluster root: $CafeTaskFileFullPath"
    }
    Remove-Item -LiteralPath $CafeTaskFileFullPath -Force -ErrorAction SilentlyContinue
}

$CafeReadyAfterStop = & (Join-Path $CafePgBin 'pg_isready.exe') `
    -h 127.0.0.1 -p $CafePort -t 3 2>&1
$CafeReadyAfterStopExitCode = $LASTEXITCODE
if ($CafeReadyAfterStopExitCode -eq 0) {
    throw "A PostgreSQL server is still accepting connections on 127.0.0.1:$CafePort`: $($CafeReadyAfterStop -join ' ')"
}

$CafeFlaskListenersAfterStop = @(
    Get-NetTCPConnection -State Listen -ErrorAction Stop |
        Where-Object { $_.LocalPort -eq [int]$CafeFlaskPort }
)
if ($CafeFlaskListenersAfterStop.Count -ne 0) {
    throw "A process still occupies dedicated Flask port $CafeFlaskPort; refusing cluster-directory cleanup."
}

# Remove the whole task-owned cluster only after PostgreSQL is proven stopped.
# Windows can briefly retain handles after shutdown, so retry the same exact,
# previously validated TEMP path and fail unless the directory is truly gone.
if (Test-Path -LiteralPath $CafeResolvedCleanupRoot) {
    $CafeClusterRemoved = $false
    $CafeClusterRemovalError = $null
    foreach ($CafeCleanupAttempt in 1..5) {
        try {
            Remove-Item `
                -LiteralPath $CafeResolvedCleanupRoot `
                -Recurse -Force -ErrorAction Stop
        }
        catch {
            $CafeClusterRemovalError = $_.Exception.Message
        }

        if (-not (Test-Path -LiteralPath $CafeResolvedCleanupRoot)) {
            $CafeClusterRemoved = $true
            break
        }
        if ($CafeCleanupAttempt -eq 5) {
            throw "Could not remove the task-owned cluster after 5 attempts: $CafeResolvedCleanupRoot. $CafeClusterRemovalError"
        }
        Start-Sleep -Milliseconds (250 * $CafeCleanupAttempt)
    }

    if (-not $CafeClusterRemoved -or
        (Test-Path -LiteralPath $CafeResolvedCleanupRoot)) {
        throw "Task-owned cluster directory survived cleanup: $CafeResolvedCleanupRoot"
    }
}

Write-Host "STEP 16 EVIDENCE: task-owned cluster directory is absent: $CafeResolvedCleanupRoot"

Restore-CafeFausseProcessEnvironment

Write-Host 'STEP 16 PASS: test database, generated roles/files, app credential, processes, and entire task-owned cluster removed; external administrator credential retained when present.'
```

Expected final output:

```text
STEP 16 EVIDENCE: task-owned cluster directory is absent: C:\Users\<you>\AppData\Local\Temp\<session>\CafeFausse-api04-local
STEP 16 EVIDENCE: restored prior presence/values for 17 process environment variables without displaying values.
STEP 16 PASS: test database, generated roles/files, app credential, processes, and entire task-owned cluster removed; external administrator credential retained when present.
```

## Failure diagnosis

- If readiness returns HTTP 503, confirm that the dedicated server is running,
  the server version is 18.3, the selected credential source matches the
  deployment login, the login has only `cafe_fausse_app` membership, and the
  rebuild and verifier succeed.
- If Flask reports an unknown `CAFE_FAUSSE_*` setting, remove database-script
  and test-only variables as shown in the manual smoke-test step.
- If the PostgreSQL log says `cafe_fausse_api04_login` has no password
  assigned, rerun all of Step 6. Do not run an isolated fragment: Step 6
  creates or normalizes the login, resets its password, proves that PostgreSQL
  stored it, and verifies authentication before it can print PASS.
- If authentication fails for only one identity, check that identity's exact
  passfile entry. Rerun the complete numbered step that failed; do not paste a
  helper or SQL fragment by itself. For Step 6, enter the same application
  password at every application-password prompt, and keep it different from
  the administrator password. Do not work around the problem by giving the
  application administrator/test authority.
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
