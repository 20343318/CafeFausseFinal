# Cafe Fausse database testing instructions

Use this runbook to validate DB-05, DB-06, and DB-07 in that order. It is
written for programmers using PowerShell and the repository scripts; no manual
database administration knowledge is assumed.

The commands are destructive only to the fixed `cafe_fausse` schema in the
explicitly named nonproduction database. Never use a production or
production-like database. The recommended database name is
`cafe_fausse_test_db07`.

## What a successful run proves

| Checkpoint | Evidence |
|---|---|
| DB-05 | PostgreSQL 18.3 and `pgcrypto`; roles; four foundation tables; exact seed populations; constraints; read-only runtime privileges; guarded rebuild. |
| DB-06 | Reservation persistence; controlled operations; exact allocation; retry behavior; rollback; privilege denials; multi-session concurrency correctness. |
| DB-07 | Default-function privilege correction; allocator fast paths and unchanged general path; performance evidence; query plans; final clean baseline. |

Every command below runs with fail-fast behavior and prints a marker in this
form:

```text
[VALIDATION:<step-id>:BEGIN] description
[VALIDATION:<step-id>:PASS] description
```

On failure, execution stops with:

```text
[VALIDATION:<step-id>:FAIL] useful error message
```

PostgreSQL `ERROR` messages during the intentional division-by-zero and
privilege-denial tests are expected. The enclosing step still prints `PASS`
only when those failures occurred as designed.

## 1. Open PowerShell at the repository root

Open a new PowerShell terminal and change to the Cafe Fausse repository. These
instructions work in Windows PowerShell 5.1 and PowerShell 7.

Confirm the repository root before continuing:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Write-Host '[VALIDATION:SETUP-01:BEGIN] Confirm the Cafe Fausse repository root.'
if (-not (Test-Path -LiteralPath '.\database\scripts\test.ps1' -PathType Leaf)) {
    throw '[VALIDATION:SETUP-01:FAIL] Run these instructions from the Cafe Fausse repository root.'
}

Write-Host '[VALIDATION:SETUP-01:PASS] Cafe Fausse repository root confirmed.'
```

## 2. Load the validation helpers

Paste this block once into the same PowerShell session. `Invoke-ValidationStep`
adds consistent markers and checks required success text. `Invoke-PsqlFile`
makes SQL failures visible through the process exit code.

```powershell
Write-Host '[VALIDATION:SETUP-02:BEGIN] Load validation helpers.'

function Invoke-ValidationStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [string[]]$RequiredMarkers = @()
    )

    Write-Host "[VALIDATION:$Id`:BEGIN] $Description"
    $stepLog = [System.Collections.Generic.List[string]]::new()

    try {
        & $Action *>&1 | ForEach-Object {
            $line = $_.ToString()
            [void]$stepLog.Add($line)
            Write-Host $line
        }

        $joinedLog = [string]::Join([Environment]::NewLine, $stepLog)
        foreach ($marker in $RequiredMarkers) {
            if (-not $joinedLog.Contains($marker)) {
                throw "Required success marker was not found: $marker"
            }
        }

        Write-Host "[VALIDATION:$Id`:PASS] $Description"
    }
    catch {
        Write-Host "[VALIDATION:$Id`:FAIL] $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Invoke-PsqlFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$AllowExpectedErrors
    )

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $arguments = @('-X')
    if (-not $AllowExpectedErrors) {
        $arguments += @('-v', 'ON_ERROR_STOP=1')
    }
    $arguments += @('-f', $resolvedPath)

    & $env:CAFE_FAUSSE_PSQL @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "psql failed with exit code $LASTEXITCODE while running $resolvedPath"
    }
}

Write-Host '[VALIDATION:SETUP-02:PASS] Validation helpers loaded.'
```

## 3. Configure PostgreSQL without displaying the password

Use the PostgreSQL administrator login that owns or can create the disposable
database and can provision the three passwordless group roles. Change only the
host, port, administrator login, or executable path if your installation is
different.

`PGPASSWORD` must temporarily contain the plain-text value because PostgreSQL's
client library reads that environment variable, but the password is entered as
a secure prompt, is never printed, and is removed in the cleanup step.

```powershell
Invoke-ValidationStep -Id 'SETUP-03' -Description 'Configure the isolated PostgreSQL target.' -Action {
    $env:PGHOST = 'localhost'
    $env:PGPORT = '5432'
    $env:PGUSER = 'postgres'
    $env:PGDATABASE = 'cafe_fausse_test_db07'
    $env:CAFE_FAUSSE_ENVIRONMENT = 'test'
    $env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
    $env:PGOPTIONS = '-c lock_timeout=5000 -c statement_timeout=60000'

    $psqlCommand = Get-Command psql -ErrorAction SilentlyContinue
    if ($null -ne $psqlCommand) {
        $env:CAFE_FAUSSE_PSQL = $psqlCommand.Source
    }
    else {
        $env:CAFE_FAUSSE_PSQL = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
    }

    if (-not (Test-Path -LiteralPath $env:CAFE_FAUSSE_PSQL -PathType Leaf)) {
        throw "psql was not found at $env:CAFE_FAUSSE_PSQL. Install PostgreSQL 18.3 or correct CAFE_FAUSSE_PSQL."
    }
    if ($env:PGDATABASE -notmatch '^cafe_fausse_(dev|test|demo)(_[a-z0-9_]+)?$') {
        throw "Unsafe database name: $env:PGDATABASE"
    }

    $global:CafeFausseSecurePassword = Read-Host 'PostgreSQL password' -AsSecureString
    $env:PGPASSWORD = [System.Net.NetworkCredential]::new('', $global:CafeFausseSecurePassword).Password
}
```

## 4. Verify PostgreSQL 18.3 and create the test database if needed

This check explicitly validates the `psql` exit code and parses only `t` or
`f`. It therefore fails clearly instead of silently treating missing output as
"database does not exist."

```powershell
Invoke-ValidationStep -Id 'SETUP-04' -Description 'Verify PostgreSQL 18.3 and the disposable database.' -Action {
    $postgresBin = Split-Path -Parent $env:CAFE_FAUSSE_PSQL
    $createdbPath = Join-Path $postgresBin 'createdb.exe'
    if (-not (Test-Path -LiteralPath $createdbPath -PathType Leaf)) {
        throw "createdb was not found beside psql: $createdbPath"
    }

    $versionOutput = & $env:CAFE_FAUSSE_PSQL -X -d postgres -qAt -v ON_ERROR_STOP=1 -c 'SHOW server_version_num;' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Could not connect to the postgres maintenance database: $($versionOutput -join ' ')"
    }
    $serverVersionNumber = @($versionOutput | ForEach-Object { $_.ToString().Trim() } |
        Where-Object { $_ -match '^\d+$' } | Select-Object -Last 1)
    if ($serverVersionNumber.Count -ne 1 -or $serverVersionNumber[0] -ne '180003') {
        throw "Expected PostgreSQL server_version_num 180003 (18.3); received: $($versionOutput -join ' ')"
    }

    $testDatabase = $env:PGDATABASE
    $databaseExistsOutput = & $env:CAFE_FAUSSE_PSQL -X -d postgres -qAt -v ON_ERROR_STOP=1 `
        -c "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = '$testDatabase');" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Database existence query failed: $($databaseExistsOutput -join ' ')"
    }
    $databaseExists = @($databaseExistsOutput | ForEach-Object { $_.ToString().Trim() } |
        Where-Object { $_ -match '^(t|f)$' } | Select-Object -Last 1)
    if ($databaseExists.Count -ne 1) {
        throw "Database existence query returned no recognizable t/f value: $($databaseExistsOutput -join ' ')"
    }

    if ($databaseExists[0] -eq 'f') {
        & $createdbPath -h $env:PGHOST -p $env:PGPORT -U $env:PGUSER $testDatabase
        if ($LASTEXITCODE -ne 0) {
            throw "createdb failed with exit code $LASTEXITCODE for $testDatabase"
        }
        Write-Host "Created isolated database $testDatabase."
    }
    else {
        Write-Host "Using existing isolated database $testDatabase. Its cafe_fausse schema will be reset."
    }

    $connectedDatabaseOutput = & $env:CAFE_FAUSSE_PSQL -X -qAt -v ON_ERROR_STOP=1 -c 'SELECT current_database();' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Could not connect to $testDatabase`: $($connectedDatabaseOutput -join ' ')"
    }
    $connectedDatabase = ($connectedDatabaseOutput | Select-Object -Last 1).ToString().Trim()
    if ($connectedDatabase -cne $testDatabase) {
        throw "Connected to $connectedDatabase instead of $testDatabase."
    }

    Write-Host "PostgreSQL 18.3 connection confirmed for $connectedDatabase."
}
```

## 5. Recommended validation: run the complete gate

This is the normal future validation command. The repository runner executes
the checkpoints in this order:

1. safety-guard and fail-visible-error tests;
2. DB-05 rebuild through migration 004, verification, behavior, and denials;
3. two full rebuilds through migrations 001-011;
4. DB-06 and DB-07 behavior and privilege tests;
5. 20 iterations of every concurrency scenario;
6. 20-sample performance evidence and rollback-safe query plans; and
7. a final rebuild to the approved empty DB-07 baseline.

Expect this step to take several minutes. Do not close the terminal while it is
running.

```powershell
Invoke-ValidationStep `
    -Id 'GATE-01' `
    -Description 'Run the complete ordered DB-05, DB-06, and DB-07 gate.' `
    -RequiredMarkers @(
        'Approved DB-05 regression suite: PASS',
        'DB-06 deterministic concurrency suite completed:',
        'DB-05/DB-06 regression and DB-07 automated gate suites completed successfully.'
    ) `
    -Action {
        & '.\database\scripts\test.ps1'
    }
```

Run a separate read-only verification after the suite. This makes the final
baseline state unmistakable even if the long gate output has scrolled away.

```powershell
Invoke-ValidationStep `
    -Id 'GATE-02' `
    -Description 'Confirm the final empty DB-07 baseline.' `
    -RequiredMarkers @('DB-07 verification completed successfully.') `
    -Action {
        & '.\database\scripts\verify.ps1'
    }
```

When both `GATE-01` and `GATE-02` print `PASS`, DB-05, DB-06, and DB-07 have
been validated in the required order. The database is left at the approved
baseline: zero customers, reservations, and assignments; one configuration
row; seven operating-hours rows; and 30 capacity-four restaurant tables.

## 6. Staged diagnostic validation

Use this section when a full gate fails and you need to identify the increment
responsible. Run the steps in order. This workflow is diagnostic; after fixing
an issue, rerun `GATE-01` and `GATE-02` above for the authoritative result.

### DB-05 foundation checkpoint

```powershell
Invoke-ValidationStep `
    -Id 'DB05-01' `
    -Description 'Rebuild and verify migrations 001-004.' `
    -RequiredMarkers @(
        'DB-05 checkpoint verification: PASS',
        'DB-05 clean rebuild and verification completed successfully.'
    ) `
    -Action {
        & '.\database\scripts\rebuild.ps1' -ThroughMigration '004_foundation_privileges.sql'
    }

Invoke-ValidationStep -Id 'DB05-02' -Description 'Run DB-05 behavior assertions.' -Action {
    Invoke-PsqlFile '.\database\tests\db05_behavior_tests.sql'
}

Invoke-ValidationStep `
    -Id 'DB05-03' `
    -Description 'Prove DB-05 runtime privilege denials.' `
    -RequiredMarkers @('Runtime privilege-denial behavior: 5/5 PASS') `
    -Action {
        Invoke-PsqlFile '.\database\tests\runtime_privilege_denials.sql' -AllowExpectedErrors
    }
```

Do not proceed unless `DB05-01`, `DB05-02`, and `DB05-03` all print `PASS`.

### DB-06 reservation and concurrency checkpoint

```powershell
Invoke-ValidationStep `
    -Id 'DB06-01' `
    -Description 'Rebuild and verify migrations 001-009.' `
    -RequiredMarkers @('DB-06 clean rebuild and verification completed successfully.') `
    -Action {
        & '.\database\scripts\rebuild.ps1' -ThroughMigration '009_reservation_privileges.sql'
    }

Invoke-ValidationStep -Id 'DB06-02' -Description 'Run DB-06 behavior, allocation, retry, and rollback assertions.' -Action {
    Invoke-PsqlFile '.\database\tests\db06_behavior_tests.sql'
}

Invoke-ValidationStep `
    -Id 'DB06-03' `
    -Description 'Prove DB-06 runtime privilege denials.' `
    -RequiredMarkers @('DB-06 runtime privilege-denial behavior: 7/7 PASS') `
    -Action {
        Invoke-PsqlFile '.\database\tests\db06_runtime_privilege_denials.sql' -AllowExpectedErrors
    }

Invoke-ValidationStep `
    -Id 'DB06-04' `
    -Description 'Run 20 iterations of the DB-06 multi-session concurrency scenarios.' `
    -RequiredMarkers @('DB-06 deterministic concurrency suite completed:') `
    -Action {
        & '.\database\scripts\concurrency_test.ps1' -Iterations 20
    }
```

Do not proceed unless `DB06-01` through `DB06-04` all print `PASS`. Retryable
SQLSTATEs intentionally exercised by the suite are not failures when the final
marker is present and committed-state invariants pass.

### DB-07 final verification checkpoint

```powershell
Invoke-ValidationStep `
    -Id 'DB07-01' `
    -Description 'Rebuild and verify all migrations 001-011.' `
    -RequiredMarkers @('DB-07 clean rebuild and verification completed successfully.') `
    -Action {
        & '.\database\scripts\rebuild.ps1' -SkipProvisioning
    }

Invoke-ValidationStep `
    -Id 'DB07-02' `
    -Description 'Run read-only DB-06 and DB-07 catalogue and invariant verification.' `
    -RequiredMarkers @('DB-07 verification completed successfully.') `
    -Action {
        & '.\database\scripts\verify.ps1'
    }

Invoke-ValidationStep `
    -Id 'DB07-03' `
    -Description 'Regress both exact allocator fast paths and the general path.' `
    -RequiredMarkers @('DB-07 behavior assertions: 3 passed') `
    -Action {
        Invoke-PsqlFile '.\database\tests\db07_behavior_tests.sql'
    }

Invoke-ValidationStep `
    -Id 'DB07-04' `
    -Description 'Capture 20-sample DB-07 performance and contention evidence.' `
    -RequiredMarkers @('Measurements are conservative local client-observed database calls') `
    -Action {
        & '.\database\scripts\performance_test.ps1' -Samples 20
    }

Invoke-ValidationStep -Id 'DB07-05' -Description 'Execute rollback-safe DB-07 query-plan evidence.' -Action {
    Invoke-PsqlFile '.\database\verification\query_plans_db07.sql'
}

Invoke-ValidationStep `
    -Id 'DB07-06' `
    -Description 'Restore and verify the approved empty DB-07 baseline.' `
    -RequiredMarkers @(
        'DB-07 clean rebuild and verification completed successfully.',
        'DB-07 verification completed successfully.'
    ) `
    -Action {
        & '.\database\scripts\rebuild.ps1' -SkipProvisioning
        & '.\database\scripts\verify.ps1'
    }
```

The performance step is evidence, not a universal pass/fail latency promise.
Compare its p50, p95, and p99 results with
`DB07_VERIFICATION_REPORT.md`. The approved Version 1 contract accepts the
documented general-allocation and coarse-lock contention limitations while
requiring committed-state correctness to remain intact.

## 7. Optional programmer walkthrough

After automated validation, use `DB07_MANUAL_DEMONSTRATION.md` when a person
needs to see the database effects directly. It contains reproducible commands
for:

- opening and exact-closing boundary acceptance;
- after-closing and interval-alignment rejection;
- exact retry and half-open overlap behavior;
- a deterministic party-size-120 full-capacity reservation;
- an overlapping `unavailable` result with zero partial customer,
  reservation, assignment, or newsletter state; and
- restoration of the approved clean baseline.

The walkthrough is demonstration evidence, not a substitute for `GATE-01`.
Always finish it by running the `DB07-06` restore-and-verify step.

## 8. Remove the password from the session

Run this cleanup after success or failure. It does not delete the test database;
it only removes the password material from the current PowerShell process.

```powershell
Write-Host '[VALIDATION:CLEANUP-01:BEGIN] Remove PostgreSQL password material from the session.'
if (Test-Path Env:PGPASSWORD) {
    Remove-Item Env:PGPASSWORD
}
$passwordVariable = Get-Variable -Name CafeFausseSecurePassword -Scope Global -ErrorAction SilentlyContinue
if ($null -ne $passwordVariable) {
    $passwordVariable.Value.Dispose()
    Remove-Variable CafeFausseSecurePassword -Scope Global
}
if (Test-Path Env:PGPASSWORD) {
    throw '[VALIDATION:CLEANUP-01:FAIL] PGPASSWORD is still present in the session.'
}

Write-Host '[VALIDATION:CLEANUP-01:PASS] PostgreSQL password removed from the session.'
```

## Failure guide

| Failed marker | First thing to check |
|---|---|
| `SETUP-01` | The terminal is not at the repository root. |
| `SETUP-03` | `psql.exe` path, safe database name, or environment values are wrong. |
| `SETUP-04` | PostgreSQL is not running, credentials are wrong, or the server is not exactly 18.3. |
| `DB05-*` | Foundation migrations, seed populations, constraints, or foundation grants. |
| `DB06-01` to `DB06-03` | Reservation objects, behavior, rollback, or controlled-operation privileges. |
| `DB06-04` | Multi-session locking/concurrency; preserve the complete scenario name and SQLSTATE in the failure report. |
| `DB07-01` to `DB07-03` | Migrations 010-011, future-function defaults, or exact allocator paths. |
| `DB07-04` | Record the full measurement table and environment line; do not invent or hide results. |
| `DB07-05` | Preserve the failing plan query and PostgreSQL error. |
| `GATE-01` | Use the last printed repository marker to choose the matching staged diagnostic step. |
| `GATE-02` or `DB07-06` | The final database is not at the approved clean baseline. Rerun the guarded rebuild, then verification. |

Do not edit migrations merely to make a failing test pass. A genuine conflict
with the approved schema, transaction architecture, locking strategy,
allocation semantics, or PostgreSQL Contract requires an explicit impact
analysis and approval before implementation changes.
