[CmdletBinding()]
param(
    [ValidateSet('127.0.0.1')]
    [string]$HostName = '127.0.0.1',

    [ValidateRange(1, 65535)]
    [int]$Port = 5432,

    [ValidatePattern('^[a-z_][a-z0-9_]{0,62}$')]
    [string]$AdministratorRole = 'postgres',

    [string]$PsqlPath,

    [switch]$SkipCompleteRuns
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:EnvironmentNames = @(
    'PGHOST', 'PGPORT', 'PGDATABASE', 'PGUSER', 'PGPASSWORD', 'PGPASSFILE',
    'PGOPTIONS', 'PGAPPNAME', 'CAFE_FAUSSE_ENVIRONMENT',
    'CAFE_FAUSSE_ALLOW_RESET', 'CAFE_FAUSSE_PSQL'
)
$script:TaskRoot = [System.IO.Path]::GetFullPath(
    (Join-Path ([System.IO.Path]::GetTempPath()) 'CafeFausse-db-test-harness')
)
$script:MarkerPath = Join-Path $script:TaskRoot 'ownership.json'
$script:WorkflowPath = Join-Path $PSScriptRoot 'programmer_test.ps1'
$script:RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:OwnedDatabasePrefix = 'cafe_fausse_test_harness_'
$script:OwnershipCommentPrefix = 'cafe_fausse_test_harness:'
$script:SecurePassword = $null
$script:ResolvedPsqlPath = $null
$script:CreatedbPath = $null
$script:DropdbPath = $null

function Write-SafetyMarker {
    param(
        [Parameter(Mandatory = $true)][string]$Case,
        [Parameter(Mandatory = $true)][ValidateSet('BEGIN', 'PASS')][string]$State,
        [Parameter(Mandatory = $true)][string]$Message
    )
    Write-Host "[HARNESS-TEST:$Case`:$State] $Message"
}

function Get-EnvironmentSnapshot {
    $snapshot = @{}
    foreach ($name in $script:EnvironmentNames) {
        $snapshot[$name] = [pscustomobject]@{
            WasPresent = $null -ne [Environment]::GetEnvironmentVariable($name, 'Process')
            Value = [Environment]::GetEnvironmentVariable($name, 'Process')
        }
    }
    return $snapshot
}

function Restore-EnvironmentSnapshot {
    param([Parameter(Mandatory = $true)][hashtable]$Snapshot)
    foreach ($name in $script:EnvironmentNames) {
        $saved = $Snapshot[$name]
        [Environment]::SetEnvironmentVariable(
            $name,
            $(if ($saved.WasPresent) { $saved.Value } else { $null }),
            'Process'
        )
    }
}

function Assert-EnvironmentEquals {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Expected,
        [Parameter(Mandatory = $true)][string]$Case
    )
    foreach ($name in $script:EnvironmentNames) {
        $actualPresent = $null -ne [Environment]::GetEnvironmentVariable($name, 'Process')
        $actualValue = [Environment]::GetEnvironmentVariable($name, 'Process')
        if ($actualPresent -ne $Expected[$name].WasPresent -or
            $actualValue -cne $Expected[$name].Value) {
            throw "Environment variable $name was not restored after $Case."
        }
    }
}

function Resolve-Tools {
    if (-not [string]::IsNullOrWhiteSpace($PsqlPath)) {
        $candidate = $PsqlPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($env:CAFE_FAUSSE_PSQL)) {
        $candidate = $env:CAFE_FAUSSE_PSQL
    }
    else {
        $pathCommand = Get-Command psql -ErrorAction SilentlyContinue
        $candidate = if ($null -ne $pathCommand) {
            $pathCommand.Source
        }
        else {
            'C:\Program Files\PostgreSQL\18\bin\psql.exe'
        }
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "psql was not found: $candidate"
    }
    $script:ResolvedPsqlPath = (Resolve-Path -LiteralPath $candidate).Path
    $bin = Split-Path -Parent $script:ResolvedPsqlPath
    $script:CreatedbPath = Join-Path $bin 'createdb.exe'
    $script:DropdbPath = Join-Path $bin 'dropdb.exe'
    foreach ($tool in @($script:CreatedbPath, $script:DropdbPath)) {
        if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
            throw "Required PostgreSQL tool was not found: $tool"
        }
    }
}

function Initialize-CredentialSource {
    $passwordPresent = $null -ne [Environment]::GetEnvironmentVariable('PGPASSWORD', 'Process')
    $passfilePresent = $null -ne [Environment]::GetEnvironmentVariable('PGPASSFILE', 'Process')
    if ($passwordPresent -and $passfilePresent) {
        throw 'PGPASSWORD and PGPASSFILE cannot both be configured.'
    }
    if (-not $passwordPresent -and -not $passfilePresent) {
        $script:SecurePassword = Read-Host 'PostgreSQL administrator password' -AsSecureString
        $plainPassword = $null
        try {
            $plainPassword = [System.Net.NetworkCredential]::new('', $script:SecurePassword).Password
            if ([string]::IsNullOrEmpty($plainPassword)) {
                throw 'The PostgreSQL administrator password was empty.'
            }
            $env:PGPASSWORD = $plainPassword
        }
        finally {
            $plainPassword = $null
        }
    }
    elseif ($passfilePresent) {
        if (-not (Test-Path -LiteralPath $env:PGPASSFILE -PathType Leaf)) {
            throw 'PGPASSFILE does not point to an existing file.'
        }
    }
}

function Invoke-Scalar {
    param([Parameter(Mandatory = $true)][string]$Sql)
    $output = & $script:ResolvedPsqlPath -X -qAt -v ON_ERROR_STOP=1 `
        -h $HostName -p $Port -U $AdministratorRole -d postgres -c $Sql 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw 'Safety-validation PostgreSQL query failed.'
    }
    return (($output | Select-Object -Last 1) -as [string]).Trim()
}

function Get-PreservedState {
    return Invoke-Scalar @"
SELECT pg_catalog.concat_ws(E'\n',
    (SELECT pg_catalog.concat_ws('|', database_row.datname,
        pg_catalog.pg_get_userbyid(database_row.datdba),
        COALESCE(pg_catalog.shobj_description(database_row.oid, 'pg_database'), ''))
     FROM pg_catalog.pg_database AS database_row WHERE database_row.datname = 'postgres'),
    (SELECT COALESCE(pg_catalog.string_agg(
        pg_catalog.concat_ws('|', role_row.rolname, role_row.rolcanlogin,
            role_row.rolsuper, role_row.rolcreatedb, role_row.rolcreaterole,
            COALESCE(pg_catalog.shobj_description(role_row.oid, 'pg_authid'), ''),
            pg_catalog.pg_has_role('$AdministratorRole', role_row.oid, 'MEMBER')),
        ',' ORDER BY role_row.rolname), '')
     FROM pg_catalog.pg_roles AS role_row
     WHERE role_row.rolname IN ('cafe_fausse_owner','cafe_fausse_app','cafe_fausse_test'))
);
"@
}

function Assert-NoOwnedArtifacts {
    param([Parameter(Mandatory = $true)][string]$Case)
    if (Test-Path -LiteralPath $script:TaskRoot) {
        throw "Task directory remained after $Case."
    }
    $facts = Invoke-Scalar @"
SELECT pg_catalog.concat_ws('|',
    (SELECT count(*) FROM pg_catalog.pg_database
     WHERE datname LIKE '$($script:OwnedDatabasePrefix)%'),
    (SELECT count(*) FROM pg_catalog.pg_roles AS role_row
     WHERE pg_catalog.shobj_description(role_row.oid, 'pg_authid')
           LIKE '$($script:OwnershipCommentPrefix)%'),
    (SELECT count(*) FROM pg_catalog.pg_stat_activity
     WHERE application_name LIKE 'cfh_%')
);
"@
    if ($facts -cne '0|0|0') {
        throw "Owned PostgreSQL artifacts remained after $Case`: $facts"
    }
}

function Invoke-CleanWorkflow {
    param(
        [Parameter(Mandatory = $true)][string]$Case,
        [string]$Mode = 'Complete'
    )
    Write-SafetyMarker $Case 'BEGIN' "Run clean workflow mode $Mode."
    $environment = Get-EnvironmentSnapshot
    & $script:WorkflowPath -Mode $Mode `
        -HostName $HostName -Port $Port `
        -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath
    Assert-EnvironmentEquals $environment $Case
    Assert-NoOwnedArtifacts $Case
    Write-SafetyMarker $Case 'PASS' 'Workflow, cleanup, artifact, and environment checks passed.'
}

function Invoke-ExpectedInjectedFailure {
    param([Parameter(Mandatory = $true)][string]$FailurePoint)
    $case = "FAIL-$FailurePoint"
    Write-SafetyMarker $case 'BEGIN' 'Inject a controlled failure and require cleanup.'
    $environment = Get-EnvironmentSnapshot
    $caught = $null
    try {
        & $script:WorkflowPath -Mode Complete -FailurePoint $FailurePoint `
            -HostName $HostName -Port $Port `
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath
    }
    catch {
        $caught = $_
    }
    if ($null -eq $caught -or
        -not $caught.Exception.Message.Contains('[HARNESS:INJECTED:FAIL]')) {
        throw "The $FailurePoint scenario did not report the expected injected failure."
    }
    Assert-EnvironmentEquals $environment $case
    Assert-NoOwnedArtifacts $case
    & $script:WorkflowPath -Mode CleanupOnly `
        -HostName $HostName -Port $Port `
        -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath
    Assert-NoOwnedArtifacts "$case cleanup-only retry"
    Write-SafetyMarker $case 'PASS' 'Expected failure was visible and cleanup was repeatable.'
}

function Invoke-InterruptionRecoveryTest {
    $case = 'INTERRUPTION-RECOVERY'
    Write-SafetyMarker $case 'BEGIN' 'Retain proven resources, then recover on the next invocation.'
    $environment = Get-EnvironmentSnapshot
    $caught = $null
    try {
        & $script:WorkflowPath -Mode Complete `
            -FailurePoint AfterRoleProvisioning `
            -LeaveOwnedResourcesForRecovery `
            -HostName $HostName -Port $Port `
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath
    }
    catch {
        $caught = $_
    }
    if ($null -eq $caught -or
        -not $caught.Exception.Message.Contains('[HARNESS:INJECTED:FAIL]')) {
        throw 'The interruption fixture did not report its controlled failure.'
    }
    if (-not (Test-Path -LiteralPath $script:MarkerPath -PathType Leaf)) {
        throw 'The interruption fixture did not retain its ownership marker.'
    }
    Assert-EnvironmentEquals $environment $case
    & $script:WorkflowPath -Mode CleanupOnly `
        -HostName $HostName -Port $Port `
        -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'Next invocation removed only marker-proven leftovers.'
}

function Remove-ExactFixtureDirectory {
    $expected = [System.IO.Path]::GetFullPath(
        (Join-Path ([System.IO.Path]::GetTempPath()) 'CafeFausse-db-test-harness')
    )
    if (-not $script:TaskRoot.Equals($expected, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Fixture cleanup path was not exact.'
    }
    if (Test-Path -LiteralPath $script:TaskRoot) {
        Remove-Item -LiteralPath $script:TaskRoot -Recurse -Force
    }
}

function Invoke-MalformedMarkerTest {
    $case = 'MALFORMED-MARKER'
    Write-SafetyMarker $case 'BEGIN' 'Require refusal when ownership evidence is malformed.'
    Assert-NoOwnedArtifacts "$case precondition"
    try {
        [void](New-Item -ItemType Directory -Path $script:TaskRoot)
        [System.IO.File]::WriteAllText(
            $script:MarkerPath, '{not-json', [System.Text.UTF8Encoding]::new($false)
        )
        $stateBefore = Get-PreservedState
        $caught = $null
        try {
            & $script:WorkflowPath -Mode CleanupOnly `
                -HostName $HostName -Port $Port `
                -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath
        }
        catch { $caught = $_ }
        if ($null -eq $caught -or
            -not $caught.Exception.Message.Contains('malformed')) {
            throw 'Malformed ownership evidence was not rejected.'
        }
        if ((Get-PreservedState) -cne $stateBefore) {
            throw 'Preserved PostgreSQL state changed during malformed-marker refusal.'
        }
    }
    finally {
        Remove-ExactFixtureDirectory
    }
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'Malformed evidence caused a fail-safe refusal and no deletion.'
}

function Invoke-MismatchedOwnershipTest {
    $case = 'OWNERSHIP-MISMATCH'
    Write-SafetyMarker $case 'BEGIN' 'Require refusal when database evidence mismatches the marker.'
    Assert-NoOwnedArtifacts "$case precondition"
    $runId = [guid]::NewGuid().ToString('D').ToLowerInvariant()
    $compact = $runId.Replace('-', '').Substring(0, 12)
    $databaseName = $script:OwnedDatabasePrefix + $compact
    $marker = [pscustomobject][ordered]@{
        schemaVersion = 1
        runId = $runId
        databaseName = $databaseName
        applicationName = 'cfh_' + $compact
        administratorRole = $AdministratorRole
        createdRoles = @()
        addedMemberships = @()
    }
    try {
        [void](New-Item -ItemType Directory -Path $script:TaskRoot)
        [System.IO.File]::WriteAllText(
            $script:MarkerPath,
            ($marker | ConvertTo-Json -Depth 4),
            [System.Text.UTF8Encoding]::new($false)
        )
        & $script:CreatedbPath -h $HostName -p $Port -U $AdministratorRole `
            -T template0 -O $AdministratorRole $databaseName
        if ($LASTEXITCODE -ne 0) { throw 'Unable to create the mismatch fixture database.' }
        [void](Invoke-Scalar (
            "COMMENT ON DATABASE $databaseName IS 'deliberately-mismatched-safety-fixture'; SELECT 'commented';"
        ))

        $caught = $null
        try {
            & $script:WorkflowPath -Mode CleanupOnly `
                -HostName $HostName -Port $Port `
                -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath
        }
        catch { $caught = $_ }
        if ($null -eq $caught -or
            -not $caught.Exception.Message.Contains('ownership evidence does not match')) {
            throw 'Mismatched ownership evidence was not rejected.'
        }
        if ((Invoke-Scalar "SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_database WHERE datname = '$databaseName')::text;") -ne 'true') {
            throw 'Mismatch fixture database was deleted despite conflicting evidence.'
        }
    }
    finally {
        if ((Invoke-Scalar "SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_database WHERE datname = '$databaseName')::text;") -eq 'true') {
            & $script:DropdbPath -h $HostName -p $Port -U $AdministratorRole $databaseName
            if ($LASTEXITCODE -ne 0) { throw 'Unable to remove the task-created mismatch fixture.' }
        }
        Remove-ExactFixtureDirectory
    }
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'Mismatched evidence caused refusal; the fixture survived until explicit owner cleanup.'
}

function Assert-NoGeneratedGitArtifacts {
    $status = & git -C $script:RepositoryRoot status --porcelain=v1
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect Git status.' }
    $forbidden = @($status | Where-Object {
        $_ -match '(ownership\.json|provisioning-wrapper\.sql|\.pgpass|test-result|test-output|CafeFausse-db-test-harness)'
    })
    if ($forbidden.Count -ne 0) {
        throw "Generated test artifact appeared in Git status: $($forbidden -join ', ')"
    }
    Write-SafetyMarker 'GIT-ARTIFACTS' 'PASS' 'No generated test artifact appears in Git status.'
}

$callerEnvironment = Get-EnvironmentSnapshot
try {
    Resolve-Tools
    Initialize-CredentialSource

    # Deliberately hostile caller values prove that the workflow overrides them
    # only within its own process scope and restores them exactly.
    $env:PGHOST = 'sentinel.invalid'
    $env:PGPORT = '1'
    $env:PGDATABASE = 'sentinel_database'
    $env:PGUSER = 'sentinel_user'
    $env:PGOPTIONS = '-c application_name=sentinel_option'
    $env:PGAPPNAME = 'sentinel_application'
    $env:CAFE_FAUSSE_ENVIRONMENT = 'sentinel_environment'
    $env:CAFE_FAUSSE_ALLOW_RESET = 'sentinel_reset'
    $env:CAFE_FAUSSE_PSQL = 'sentinel_psql'

    $preservedState = Get-PreservedState
    Assert-NoOwnedArtifacts 'initial precondition'

    foreach ($failurePoint in @(
        'Setup',
        'AfterDatabaseCreation',
        'AfterRoleProvisioning',
        'AfterMigrationsBegin',
        'AfterDB05',
        'AfterDB06',
        'AfterDB07',
        'BeforeFinalBaseline'
    )) {
        Invoke-ExpectedInjectedFailure $failurePoint
    }

    Invoke-InterruptionRecoveryTest
    Invoke-MalformedMarkerTest
    Invoke-MismatchedOwnershipTest

    if (-not $SkipCompleteRuns) {
        Invoke-CleanWorkflow 'COMPLETE-RUN-1'
        Invoke-CleanWorkflow 'COMPLETE-RUN-2'
    }

    if ((Get-PreservedState) -cne $preservedState) {
        throw 'Preexisting database, role, or administrator-membership state was not preserved.'
    }
    Write-SafetyMarker 'PREEXISTING-STATE' 'PASS' 'Preexisting postgres database, roles, and memberships were preserved.'
    Assert-NoOwnedArtifacts 'final validation'
    Assert-NoGeneratedGitArtifacts
    Write-SafetyMarker 'COMPLETE' 'PASS' 'All selected harness safety cases passed.'
}
finally {
    if ($null -ne $script:SecurePassword) {
        $script:SecurePassword.Dispose()
        $script:SecurePassword = $null
    }
    Restore-EnvironmentSnapshot $callerEnvironment
}
