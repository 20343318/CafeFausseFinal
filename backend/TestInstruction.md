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
- Use `PGPASSFILE` or `PGPASSWORD`, never both. The helper in Step 3 enforces
  this choice for the Flask connection. Steps 11 and 12 support either one
  protected passfile or two secure interactive prompts.
- Stop immediately if a guard, version check, role audit, rebuild, verifier, or
  test command fails.
- Every numbered step is restartable. A rerun must inspect and reuse valid
  state, repair only task-owned partial state, and produce the same `STEP n
  PASS` marker. It must not treat "already exists", "already running", or
  "already stopped" as a failure when the existing state matches this guide.

## Rerun behavior

| Step | Repeatable behavior |
|---|---|
| 1 | Reassigns the same task variables and redetects the approved tools. |
| 2 | Reuses a valid marked cluster, adopts exact-path legacy state, recreates marker-owned partial data, or starts a stopped cluster. |
| 3 | Replaces the active credential source; passfile entries are updated in place without duplicates. |
| 4 | Creates a missing database or validates the existing database, owner, and version. |
| 5 | Guardedly rebuilds the fixed schema and verifies the baseline. |
| 6 | Creates or normalizes the one deployment login, preserves its existing password, and reapplies the exact app-only grants. |
| 7 | Repeats read-only role and authentication audits. |
| 8 | Repeats the destructive nonproduction PostgreSQL gate and restores its baseline. |
| 9 | Reuses a valid environment or safely recreates a partial/wrong-version `.venv`, then refreshes dependencies. |
| 10 | Repeats unit/API tests and always restores the caller's directory. |
| 11 | Ensures PostgreSQL is running, then repeats integration/recovery tests and restores the caller's directory. |
| 12 | Reestablishes all test variables, then repeats coverage and restores the caller's directory. |
| 13 | Reuses healthy Flask, or replaces only a task-owned unhealthy Flask process. |
| 14 | Repeats the guarded final rebuild and exact baseline-count proof. |
| 15 | Repeats compilation/Git checks from the repository root. |
| 16 | Stops only recognized task processes; already-stopped state succeeds. |

## 1. Define the isolated target

Open PowerShell at the repository root and define task-specific variables:

```powershell
$CafeRepo = (Resolve-Path '.').Path
$CafePgBin = 'C:\Program Files\PostgreSQL\18\bin'
$CafeClusterRoot = Join-Path $env:TEMP 'CafeFausse-api04-local'
$CafeDataDir = Join-Path $CafeClusterRoot 'data'
$CafeLogFile = Join-Path $CafeClusterRoot 'postgres.log'
$CafeClusterMarker = Join-Path $CafeClusterRoot '.cafe-fausse-api04-test-cluster'
$CafeFlaskPidFile = Join-Path $CafeClusterRoot 'flask.pid'
$CafeFlaskOutputLog = Join-Path $CafeClusterRoot 'flask-output.log'
$CafeFlaskErrorLog = Join-Path $CafeClusterRoot 'flask-error.log'
$CafeVenvRoot = Join-Path $CafeRepo 'backend\.venv'
$CafeVenvPython = Join-Path $CafeVenvRoot 'Scripts\python.exe'
$CafePort = '55435'
$CafeDatabase = 'cafe_fausse_test_api04'
$CafeAdminLogin = 'cafe_fausse_admin'
$CafeAppLogin = 'cafe_fausse_api04_login'
$CafeUsePassFile = $false  # Default: use secure interactive prompts.
```

Confirm that the shell is at the correct repository and that the required
programs exist:

```powershell
if (-not (Test-Path -LiteralPath (Join-Path $CafeRepo 'backend\pyproject.toml'))) {
    throw 'Run this guide from the Cafe Fausse repository root.'
}

foreach ($CafeProgram in @('initdb.exe', 'pg_ctl.exe', 'pg_isready.exe', 'psql.exe', 'createdb.exe')) {
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

## 2. Ensure the dedicated PostgreSQL cluster exists and is running

This step is repeatable after successful, failed, or interrupted runs. It uses
a task-specific marker beneath the exact temporary path. A valid existing
cluster is reused; a marker-owned partial initialization is removed and
recreated; a stopped valid cluster is restarted; and a running valid cluster
is left running. An unrecognized directory is never overwritten.

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
    # One-time adoption of state created by an earlier version of this guide.
    # A complete cluster must match version, port, and loopback binding. A
    # partial initialization may contain only the known data/log paths.
    if (-not (Test-Path -LiteralPath $CafeVersionFile -PathType Leaf)) {
        $CafeUnexpectedLegacyItems = @(
            Get-ChildItem -LiteralPath $CafeClusterRoot -Force | Where-Object {
                $_.Name -notin @('data', 'postgres.log')
            }
        )
        if ($CafeUnexpectedLegacyItems.Count -gt 0) {
            throw "Existing unmarked directory contains unexpected items and will not be adopted: $($CafeUnexpectedLegacyItems.FullName -join ', ')"
        }
        Set-Content -LiteralPath $CafeClusterMarker -Value $CafeMarkerText -Encoding UTF8
        Write-Host 'Marked an exact-path legacy partial initialization for safe recreation.'
    }
    else {
        $CafeExistingMajor = (Get-Content -LiteralPath $CafeVersionFile -Raw).Trim()
        $CafePostmasterOptionsFile = Join-Path $CafeDataDir 'postmaster.opts'
        $CafePostmasterOptions = if (Test-Path -LiteralPath $CafePostmasterOptionsFile) {
            Get-Content -LiteralPath $CafePostmasterOptionsFile -Raw
        } else {
            ''
        }
        if ($CafeExistingMajor -ne '18' -or
            $CafePostmasterOptions -notmatch [regex]::Escape($CafePort) -or
            $CafePostmasterOptions -notmatch '127\.0\.0\.1') {
            throw "Refusing to adopt an unrecognized cluster at $CafeClusterRoot"
        }
        Set-Content -LiteralPath $CafeClusterMarker -Value $CafeMarkerText -Encoding UTF8
        Write-Host 'Recognized and marked the existing task-specific PostgreSQL cluster.'
    }
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

Define the external passfile location. Step 1 defaults
`$CafeUsePassFile = $false`, so an existing file never silently changes the
chosen mode. Leave it false for secure interactive prompts. Set it true only
when selecting Option A.

Choose exactly one credential-storage option:

| Choice | Setting | What to run |
|---|---|---|
| Option A: protected passfile | `$CafeUsePassFile = $true` | Run the Option A block, then run the shared credential-helper block. |
| Option B: interactive prompts (default) | `$CafeUsePassFile = $false` | Skip the entire Option A block and run the Option B confirmation followed by the shared credential-helper block. |

Do not run Option A merely because a passfile from an earlier session exists.
The value of `$CafeUsePassFile` is the explicit choice and prevents a stale
file from silently overriding interactive mode.

```powershell
$CafePassDirectory = Join-Path $env:APPDATA 'postgresql'
$CafePassFile = Join-Path $CafePassDirectory 'cafe_fausse_api04_pgpass.conf'
$CafeCurrentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
```

### Option A: protected external passfile

To use an external passfile, create it outside the repository and restrict it
to the current Windows identity:

```powershell
$CafeUsePassFile = $true
New-Item -ItemType Directory -Path $CafePassDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $CafePassFile)) {
    New-Item -ItemType File -Path $CafePassFile | Out-Null
}

& icacls.exe $CafePassFile /inheritance:r /grant:r "$CafeCurrentIdentity`:(R,W)"

if ($LASTEXITCODE -ne 0) {
    throw 'Could not restrict the PostgreSQL passfile ACL.'
}

function Set-CafeFaussePassfileEntry {
    param(
        [Parameter(Mandatory)][string]$Login,
        [Parameter(Mandatory)][string]$DatabaseName,
        [Parameter(Mandatory)][string]$Prompt
    )

    $CafeSecurePassword = Read-Host $Prompt -AsSecureString
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
        $CafeSecurePassword.Dispose()
        Remove-Variable CafePlainPassword -ErrorAction SilentlyContinue
        Remove-Variable CafeEscapedPassword -ErrorAction SilentlyContinue
    }

    & icacls.exe $CafePassFile /inheritance:r /grant:r "$CafeCurrentIdentity`:(R,W)" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not reapply the PostgreSQL passfile ACL for $Login."
    }
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

After running Option A, continue to the shared credential-helper block below.
Do not run Option B's confirmation block.

### Option B: secure interactive prompts (default)

Choose this option when passwords should exist only in the current PowerShell
process rather than in a passfile. Skip every command under Option A, including
passfile creation and `Set-CafeFaussePassfileEntry`. Confirm interactive mode:

```powershell
$CafeUsePassFile = $false
Write-Host 'STEP 3 OPTION B: secure interactive password prompts selected.'
```

Expected option-selection output:

```text
STEP 3 OPTION B: secure interactive password prompts selected.
```

Now continue to the shared credential-helper block. Its final command prompts
for the administrator password needed by Steps 4 and 5. Later single-login
steps call the same helper again with the applicable login name. Steps 11 and
12 call the two-password pytest helper and prompt separately for the app login
and administrator/test-management login.

### Shared credential helpers required for both options

Run this entire block after completing either Option A or Option B. Do not skip
it: later steps depend on the two functions it defines.

When `$CafeUsePassFile` is false, `Set-CafeFausseCredential` reads the current
login's password without echoing it, converts it only for the process
environment, and sets `PGPASSWORD`. When the setting is true, it requires and
selects `PGPASSFILE`. It always removes the other variables first.

```powershell
function Set-CafeFausseCredential {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD -ErrorAction SilentlyContinue

    if ($CafeUsePassFile) {
        if (-not (Test-Path -LiteralPath $CafePassFile -PathType Leaf)) {
            throw "Passfile mode was selected but the file does not exist: $CafePassFile"
        }
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

    if ($CafeUsePassFile) {
        if (-not (Test-Path -LiteralPath $CafePassFile -PathType Leaf)) {
            throw "Passfile mode was selected but the file does not exist: $CafePassFile"
        }
        if ((Get-Item -LiteralPath $CafePassFile).Length -eq 0) {
            throw "The external passfile exists but is empty: $CafePassFile"
        }
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
processes. Step 16 clears both interactive test variables. Run
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
}
else {
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

Connect as the setup administrator:

```powershell
Start-CafeFausseTestPostgres
Set-CafeFausseCredential -Prompt "Password for $CafeAdminLogin"

& (Join-Path $CafePgBin 'psql.exe') `
    -X -v ON_ERROR_STOP=1 `
    -h 127.0.0.1 `
    -p $CafePort `
    -U $CafeAdminLogin `
    -d $CafeDatabase
```

At the `psql` prompt, run these repeatable statements. A missing deployment
login is created and passworded. An existing login is retained, normalized to
the exact nonprivileged attributes, and keeps its current password unless a
partial prior run left the password unset. The app login is explicitly removed
from owner/test membership before its one approved membership is reapplied:

```sql
SELECT NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_roles
    WHERE rolname = 'cafe_fausse_api04_login'
) AS create_app_login,
COALESCE((
    SELECT rolpassword IS NULL FROM pg_catalog.pg_authid
    WHERE rolname = 'cafe_fausse_api04_login'
), true) AS set_app_password
\gset
\if :create_app_login
    CREATE ROLE cafe_fausse_api04_login
        LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
        NOBYPASSRLS NOINHERIT;
\else
    ALTER ROLE cafe_fausse_api04_login
        LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION
        NOBYPASSRLS NOINHERIT;
\endif
\if :set_app_password
\password cafe_fausse_api04_login
\endif

SELECT
    EXISTS (
        SELECT 1 FROM pg_catalog.pg_auth_members membership
        JOIN pg_catalog.pg_roles granted_role ON granted_role.oid = membership.roleid
        JOIN pg_catalog.pg_roles member_role ON member_role.oid = membership.member
        WHERE granted_role.rolname = 'cafe_fausse_owner'
          AND member_role.rolname = 'cafe_fausse_api04_login'
    ) AS revoke_owner_membership,
    EXISTS (
        SELECT 1 FROM pg_catalog.pg_auth_members membership
        JOIN pg_catalog.pg_roles granted_role ON granted_role.oid = membership.roleid
        JOIN pg_catalog.pg_roles member_role ON member_role.oid = membership.member
        WHERE granted_role.rolname = 'cafe_fausse_test'
          AND member_role.rolname = 'cafe_fausse_api04_login'
    ) AS revoke_test_membership
\gset
\if :revoke_owner_membership
    REVOKE cafe_fausse_owner FROM cafe_fausse_api04_login;
\endif
\if :revoke_test_membership
    REVOKE cafe_fausse_test FROM cafe_fausse_api04_login;
\endif
GRANT cafe_fausse_app TO cafe_fausse_api04_login;

GRANT CONNECT ON DATABASE cafe_fausse_test_api04
    TO cafe_fausse_api04_login;

SELECT 'STEP 6 PASS: app-only deployment login created or validated; cluster administrator remains the external test manager.'
    AS verification;
\q
```

The `\password` prompt appears only when the deployment login is new or a prior
partial run left its password unset. A rerun does not reset an existing
password. Step 7 audits the resulting attributes and memberships on every run.

If Option A in Step 3 selected a passfile, create or replace the exact-database
entries after the first run or whenever a password changes:

```powershell
Set-CafeFaussePassfileEntry `
    -Login $CafeAppLogin `
    -DatabaseName $CafeDatabase `
    -Prompt "Password for $CafeAppLogin"
```

If Step 3 selected the interactive fallback, do not create a credential file
here merely by copying placeholders. Later single-login commands prompt for the
applicable password. Steps 11 and 12 securely prompt for both passwords.

Expected `psql` output includes `CREATE ROLE` on the first run or `ALTER ROLE`
on a rerun, repeatable `GRANT` output, and:

```text
STEP 6 PASS: app-only deployment login created or validated; cluster administrator remains the external test manager.
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

Create or repair the virtual environment, then reinstall the editable test
extras. A valid environment is reused. A partial, broken, or wrong-version
environment is removed only after its exact repository path is checked and is
then recreated.

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
    $CafeResolvedVenv = [System.IO.Path]::GetFullPath($CafeVenvRoot)
    $CafeExpectedVenv = [System.IO.Path]::GetFullPath(
        (Join-Path $CafeRepo 'backend\.venv')
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
    & $CafePythonExecutable @CafePythonLauncherArguments -m venv $CafeVenvRoot
    if ($LASTEXITCODE -ne 0) { throw 'Backend virtual-environment creation failed.' }
}

& $CafeVenvPython -m pip install --disable-pip-version-check -e "backend[test]"
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
    & $CafeVenvPython -m pytest
    if ($LASTEXITCODE -ne 0) { throw 'Default backend tests failed.' }

    & $CafeVenvPython -m pytest -m unit
    if ($LASTEXITCODE -ne 0) { throw 'Backend unit tests failed.' }

    & $CafeVenvPython -m pytest -m api
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
    & $CafeVenvPython -m pytest -m "integration and postgres"
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
    & $CafeVenvPython -m pytest -m "unit or api or integration" `
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
login selected, and starts one hidden development-server process only when the
health endpoints are not already available. A task-owned unhealthy process is
stopped and replaced; a healthy prior process is reused.

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

function Test-CafeFausseHealth {
    try {
        $CafeLiveness = Invoke-RestMethod `
            -Uri 'http://127.0.0.1:5000/api/v1/health/liveness' `
            -TimeoutSec 3
        $CafeReadiness = Invoke-RestMethod `
            -Uri 'http://127.0.0.1:5000/api/v1/health/readiness' `
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

if (-not (Test-CafeFausseHealth)) {
    if (Test-Path -LiteralPath $CafeFlaskPidFile -PathType Leaf) {
        $CafeRecordedFlaskPidText = (Get-Content -LiteralPath $CafeFlaskPidFile -Raw).Trim()
        if ($CafeRecordedFlaskPidText -notmatch '^\d+$') {
            throw "Invalid task-owned Flask PID file: $CafeFlaskPidFile"
        }
        $CafeRecordedFlaskProcess = Get-Process `
            -Id ([int]$CafeRecordedFlaskPidText) `
            -ErrorAction SilentlyContinue
        if ($null -ne $CafeRecordedFlaskProcess) {
            $CafeRecordedProcessPath = $CafeRecordedFlaskProcess.Path
            if ([string]::IsNullOrWhiteSpace($CafeRecordedProcessPath) -or
                -not [System.IO.Path]::GetFullPath($CafeRecordedProcessPath).Equals(
                    [System.IO.Path]::GetFullPath($CafeVenvPython),
                    [System.StringComparison]::OrdinalIgnoreCase
                )) {
                throw "PID $CafeRecordedFlaskPidText is not the task-owned Flask interpreter; refusing to stop it."
            }
            Stop-Process -Id $CafeRecordedFlaskProcess.Id -Force
            $CafeRecordedFlaskProcess.WaitForExit(10000)
        }
        Remove-Item -LiteralPath $CafeFlaskPidFile -Force
    }

    Remove-Item -LiteralPath $CafeFlaskOutputLog -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $CafeFlaskErrorLog -Force -ErrorAction SilentlyContinue
    $CafeFlaskProcess = Start-Process `
        -FilePath $CafeVenvPython `
        -ArgumentList @(
            '-m', 'flask', '--app', 'cafe_fausse', 'run',
            '--host', '127.0.0.1', '--port', '5000'
        ) `
        -WorkingDirectory (Join-Path $CafeRepo 'backend') `
        -RedirectStandardOutput $CafeFlaskOutputLog `
        -RedirectStandardError $CafeFlaskErrorLog `
        -WindowStyle Hidden `
        -PassThru
    Set-Content -LiteralPath $CafeFlaskPidFile -Value $CafeFlaskProcess.Id -Encoding ASCII

    $CafeHealthReady = $false
    for ($CafeAttempt = 1; $CafeAttempt -le 30; $CafeAttempt++) {
        if ($CafeFlaskProcess.HasExited) {
            break
        }
        if (Test-CafeFausseHealth) {
            $CafeHealthReady = $true
            break
        }
        Start-Sleep -Seconds 1
    }

    if (-not $CafeHealthReady) {
        if (-not $CafeFlaskProcess.HasExited) {
            Stop-Process -Id $CafeFlaskProcess.Id -Force
            $CafeFlaskProcess.WaitForExit(10000)
        }
        Remove-Item -LiteralPath $CafeFlaskPidFile -Force -ErrorAction SilentlyContinue
        $CafeFlaskFailure = @(
            if (Test-Path -LiteralPath $CafeFlaskErrorLog) {
                Get-Content -LiteralPath $CafeFlaskErrorLog -Tail 30
            }
        ) -join [Environment]::NewLine
        throw "Flask health endpoints did not become ready: $CafeFlaskFailure"
    }
}

Write-Host 'STEP 13 PASS: Flask liveness=live; readiness=ready.'
```

Liveness must report `status = live`. Readiness must report
`status = ready`. The development server is local-only and remains available
for a repeated Step 13. Step 16 safely stops it when its task-owned PID file is
present. Expected verification output:

```text
STEP 13 PASS: Flask liveness=live; readiness=ready.
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

## 16. Stop the task-owned Flask and PostgreSQL servers

After all tests and evidence collection are complete, stop task-owned Flask
and PostgreSQL processes. Missing/stale Flask PID state and an already-stopped
PostgreSQL cluster are successful no-op conditions, making this cleanup safe to
repeat:

```powershell
if (Test-Path -LiteralPath $CafeFlaskPidFile -PathType Leaf) {
    $CafeRecordedFlaskPidText = (Get-Content -LiteralPath $CafeFlaskPidFile -Raw).Trim()
    if ($CafeRecordedFlaskPidText -notmatch '^\d+$') {
        throw "Invalid task-owned Flask PID file: $CafeFlaskPidFile"
    }
    $CafeRecordedFlaskProcess = Get-Process `
        -Id ([int]$CafeRecordedFlaskPidText) `
        -ErrorAction SilentlyContinue
    if ($null -ne $CafeRecordedFlaskProcess) {
        $CafeRecordedProcessPath = $CafeRecordedFlaskProcess.Path
        if ([string]::IsNullOrWhiteSpace($CafeRecordedProcessPath) -or
            -not [System.IO.Path]::GetFullPath($CafeRecordedProcessPath).Equals(
                [System.IO.Path]::GetFullPath($CafeVenvPython),
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
            throw "PID $CafeRecordedFlaskPidText is not the task-owned Flask interpreter; refusing to stop it."
        }
        Stop-Process -Id $CafeRecordedFlaskProcess.Id -Force
        $CafeRecordedFlaskProcess.WaitForExit(10000)
    }
    Remove-Item -LiteralPath $CafeFlaskPidFile -Force
}

if (Test-Path -LiteralPath (Join-Path $CafeDataDir 'PG_VERSION') -PathType Leaf) {
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
}
else {
    Write-Host 'PostgreSQL data directory is not initialized; shutdown is already satisfied.'
}

$CafeReadyAfterStop = & (Join-Path $CafePgBin 'pg_isready.exe') `
    -h 127.0.0.1 -p $CafePort -t 3 2>&1
$CafeReadyAfterStopExitCode = $LASTEXITCODE
if ($CafeReadyAfterStopExitCode -eq 0) {
    throw "A PostgreSQL server is still accepting connections on 127.0.0.1:$CafePort`: $($CafeReadyAfterStop -join ' ')"
}

Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
Remove-Item Env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD -ErrorAction SilentlyContinue
Write-Host 'STEP 16 PASS: task-owned Flask is absent and disposable PostgreSQL is stopped.'
```

Retain the stopped cluster if it will be reused for later API work. Before
deleting it, independently resolve and verify that its exact path is beneath
`$env:TEMP`; never recursively delete a path derived from an unchecked or empty
variable.

Expected output contains `server stopped` on the first cleanup or the
already-stopped message on a rerun, followed by:

```text
STEP 16 PASS: task-owned Flask is absent and disposable PostgreSQL is stopped.
```

## Failure diagnosis

- If readiness returns HTTP 503, confirm that the dedicated server is running,
  the server version is 18.3, the selected credential source matches the
  deployment login, the login has only `cafe_fausse_app` membership, and the
  rebuild and verifier succeed.
- If Flask reports an unknown `CAFE_FAUSSE_*` setting, remove database-script
  and test-only variables as shown in the manual smoke-test step.
- If authentication fails for only one identity, check that identity's exact
  passfile entry. In interactive mode, rerun `Set-CafeFausseCredential` for a
  single-login step or `Set-CafeFaussePytestCredentials` for Steps 11 and 12,
  then carefully enter the requested password. Do not work around the problem
  by giving the application administrator/test authority.
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
