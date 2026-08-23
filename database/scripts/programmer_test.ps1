[CmdletBinding()]
param(
    [ValidateSet('Complete', 'DB05', 'DB06', 'DB07', 'CleanupOnly')]
    [string]$Mode = 'Complete',

    [ValidateSet(
        'None',
        'Setup',
        'AfterDatabaseCreation',
        'AfterRoleProvisioning',
        'AfterMigrationsBegin',
        'AfterDB05',
        'AfterDB06',
        'AfterDB07',
        'BeforeFinalBaseline'
    )]
    [string]$FailurePoint = 'None',

    [switch]$LeaveOwnedResourcesForRecovery,

    [ValidateSet('127.0.0.1')]
    [string]$HostName = '127.0.0.1',

    [ValidateRange(1, 65535)]
    [int]$Port = 5432,

    [ValidatePattern('^[a-z_][a-z0-9_]{0,62}$')]
    [string]$AdministratorRole = 'postgres',

    [string]$PsqlPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:MarkerSchemaVersion = 1
$script:OwnedDatabasePrefix = 'cafe_fausse_test_harness_'
$script:OwnershipCommentPrefix = 'cafe_fausse_test_harness:'
$script:GroupRoles = @('cafe_fausse_owner', 'cafe_fausse_app', 'cafe_fausse_test')
$script:MembershipRoles = @('cafe_fausse_owner', 'cafe_fausse_test')
$script:EnvironmentNames = @(
    'PGHOST',
    'PGPORT',
    'PGDATABASE',
    'PGUSER',
    'PGPASSWORD',
    'PGPASSFILE',
    'PGOPTIONS',
    'PGAPPNAME',
    'CAFE_FAUSSE_ENVIRONMENT',
    'CAFE_FAUSSE_ALLOW_RESET',
    'CAFE_FAUSSE_PSQL'
)
$script:TaskRoot = [System.IO.Path]::GetFullPath(
    (Join-Path ([System.IO.Path]::GetTempPath()) 'CafeFausse-db-test-harness')
)
$script:MarkerPath = Join-Path $script:TaskRoot 'ownership.json'
$script:ProvisioningWrapperPath = Join-Path $script:TaskRoot 'provisioning-wrapper.sql'
$script:RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:DatabaseRoot = Join-Path $script:RepositoryRoot 'database'
$script:SecurePassword = $null
$script:ResolvedPsqlPath = $null
$script:CreatedbPath = $null
$script:DropdbPath = $null

function Write-HarnessMarker {
    param(
        [Parameter(Mandatory = $true)][string]$Area,
        [Parameter(Mandatory = $true)][string]$State,
        [Parameter(Mandatory = $true)][string]$Message
    )

    Write-Host "[HARNESS:$Area`:$State] $Message"
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
        if ($saved.WasPresent) {
            [Environment]::SetEnvironmentVariable($name, $saved.Value, 'Process')
        }
        else {
            [Environment]::SetEnvironmentVariable($name, $null, 'Process')
        }
    }
}

function Assert-TaskRoot {
    $expected = [System.IO.Path]::GetFullPath(
        (Join-Path ([System.IO.Path]::GetTempPath()) 'CafeFausse-db-test-harness')
    )
    if (-not $script:TaskRoot.Equals(
        $expected,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Task root is not the exact approved temporary path: $script:TaskRoot"
    }

    $temporaryRoot = [System.IO.Path]::GetFullPath(
        [System.IO.Path]::GetTempPath()
    ).TrimEnd('\')
    if (-not $script:TaskRoot.StartsWith(
        $temporaryRoot + '\',
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Task root is not beneath the Windows temporary directory: $script:TaskRoot"
    }
}

function Resolve-PostgreSqlTools {
    if (-not [string]::IsNullOrWhiteSpace($PsqlPath)) {
        $candidate = $PsqlPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($env:CAFE_FAUSSE_PSQL)) {
        $candidate = $env:CAFE_FAUSSE_PSQL
    }
    else {
        $pathCommand = Get-Command psql -ErrorAction SilentlyContinue
        if ($null -ne $pathCommand) {
            $candidate = $pathCommand.Source
        }
        else {
            $candidate = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
        }
    }

    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "psql was not found: $candidate"
    }

    $script:ResolvedPsqlPath = (Resolve-Path -LiteralPath $candidate).Path
    $postgresBin = Split-Path -Parent $script:ResolvedPsqlPath
    $script:CreatedbPath = Join-Path $postgresBin 'createdb.exe'
    $script:DropdbPath = Join-Path $postgresBin 'dropdb.exe'
    foreach ($toolPath in @($script:CreatedbPath, $script:DropdbPath)) {
        if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
            throw "Required PostgreSQL tool was not found: $toolPath"
        }
    }
}

function Initialize-CredentialSource {
    $passwordPresent = $null -ne [Environment]::GetEnvironmentVariable(
        'PGPASSWORD', 'Process'
    )
    $passfilePresent = $null -ne [Environment]::GetEnvironmentVariable(
        'PGPASSFILE', 'Process'
    )

    if ($passwordPresent -and $passfilePresent) {
        throw 'PGPASSWORD and PGPASSFILE cannot both be configured.'
    }

    if (-not $passwordPresent -and -not $passfilePresent) {
        $script:SecurePassword = Read-Host 'PostgreSQL administrator password' -AsSecureString
        $plainPassword = $null
        try {
            $plainPassword = [System.Net.NetworkCredential]::new(
                '', $script:SecurePassword
            ).Password
            if ([string]::IsNullOrEmpty($plainPassword)) {
                throw 'The PostgreSQL administrator password was empty.'
            }
            [Environment]::SetEnvironmentVariable(
                'PGPASSWORD', $plainPassword, 'Process'
            )
        }
        finally {
            $plainPassword = $null
        }
        Write-HarnessMarker 'CREDENTIAL' 'PASS' 'Password read without echo for this process only.'
    }
    elseif ($passwordPresent) {
        Write-HarnessMarker 'CREDENTIAL' 'PASS' 'Using the caller-provided process password without displaying it.'
    }
    else {
        $passfilePath = [Environment]::GetEnvironmentVariable('PGPASSFILE', 'Process')
        if (-not (Test-Path -LiteralPath $passfilePath -PathType Leaf)) {
            throw 'PGPASSFILE does not point to an existing file.'
        }
        Write-HarnessMarker 'CREDENTIAL' 'PASS' 'Using the caller-provided external password file without reading or displaying it.'
    }
}

function Invoke-MaintenanceScalar {
    param([Parameter(Mandatory = $true)][string]$Sql)

    $output = & $script:ResolvedPsqlPath `
        -X -qAt -v ON_ERROR_STOP=1 `
        -h $HostName -p $Port -U $AdministratorRole -d postgres `
        -c $Sql 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "PostgreSQL maintenance query failed with exit code $exitCode."
    }
    if ($null -eq $output) {
        return ''
    }
    return (($output | Select-Object -Last 1) -as [string]).Trim()
}

function Assert-MaintenanceTarget {
    Write-HarnessMarker 'TARGET' 'BEGIN' 'Validate the local PostgreSQL 18.3 maintenance connection.'
    $facts = Invoke-MaintenanceScalar @"
SELECT pg_catalog.concat_ws('|',
    pg_catalog.current_setting('server_version_num'),
    pg_catalog.current_database(),
    COALESCE(pg_catalog.inet_server_addr()::text, ''),
    pg_catalog.inet_server_port()::text,
    pg_catalog.current_user,
    pg_catalog.pg_is_in_recovery()::text
);
"@
    $expected = "180003|postgres|127.0.0.1|$Port|$AdministratorRole|false"
    if ($facts -cne $expected) {
        throw "Unexpected PostgreSQL target. Expected $expected; received $facts."
    }
    Write-HarnessMarker 'TARGET' 'PASS' 'Connected to the expected local PostgreSQL 18.3 server.'
}

function Test-DirectMembership {
    param(
        [Parameter(Mandatory = $true)][string]$GrantedRole,
        [Parameter(Mandatory = $true)][string]$MemberRole
    )

    $result = Invoke-MaintenanceScalar @"
SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_auth_members AS membership
    JOIN pg_catalog.pg_roles AS granted_role
      ON granted_role.oid = membership.roleid
    JOIN pg_catalog.pg_roles AS member_role
      ON member_role.oid = membership.member
    WHERE granted_role.rolname = '$GrantedRole'
      AND member_role.rolname = '$MemberRole'
)::text;
"@
    return $result -eq 'true'
}

function Test-RoleExists {
    param([Parameter(Mandatory = $true)][string]$RoleName)
    return (Invoke-MaintenanceScalar (
        "SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '$RoleName')::text;"
    )) -eq 'true'
}

function New-MarkerData {
    $runId = [guid]::NewGuid().ToString('D').ToLowerInvariant()
    $compactRunId = $runId.Replace('-', '').Substring(0, 12)
    $createdRoles = [System.Collections.Generic.List[string]]::new()
    foreach ($roleName in $script:GroupRoles) {
        if (-not (Test-RoleExists $roleName)) {
            [void]$createdRoles.Add($roleName)
        }
    }

    $addedMemberships = [System.Collections.Generic.List[string]]::new()
    foreach ($roleName in $script:MembershipRoles) {
        if (-not (Test-DirectMembership $roleName $AdministratorRole)) {
            [void]$addedMemberships.Add($roleName)
        }
    }

    return [pscustomobject][ordered]@{
        schemaVersion = $script:MarkerSchemaVersion
        runId = $runId
        databaseName = $script:OwnedDatabasePrefix + $compactRunId
        applicationName = 'cfh_' + $compactRunId
        administratorRole = $AdministratorRole
        createdRoles = @($createdRoles)
        addedMemberships = @($addedMemberships)
    }
}

function Write-NewMarker {
    param([Parameter(Mandatory = $true)]$Marker)

    Assert-TaskRoot
    if (Test-Path -LiteralPath $script:TaskRoot) {
        throw "The task root already exists; recovery is required: $script:TaskRoot"
    }
    [void](New-Item -ItemType Directory -Path $script:TaskRoot)
    $json = $Marker | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText(
        $script:MarkerPath,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-HarnessMarker 'OWNERSHIP' 'PASS' "Durable ownership marker created for run $($Marker.runId)."
}

function ConvertTo-ValidatedStringArray {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string[]]$Allowed,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )

    $values = @($Value)
    if (@($values | Select-Object -Unique).Count -ne $values.Count) {
        throw "Marker property $PropertyName contains duplicates."
    }
    foreach ($item in $values) {
        if ($item -notin $Allowed) {
            throw "Marker property $PropertyName contains an unexpected value."
        }
    }
    return [string[]]$values
}

function Read-ValidatedMarker {
    Assert-TaskRoot
    if (-not (Test-Path -LiteralPath $script:MarkerPath -PathType Leaf)) {
        throw "Ownership marker is missing: $script:MarkerPath"
    }

    try {
        $marker = Get-Content -LiteralPath $script:MarkerPath -Raw | ConvertFrom-Json
    }
    catch {
        throw 'Ownership marker is malformed; no resource was deleted.'
    }

    $expectedProperties = @(
        'schemaVersion', 'runId', 'databaseName', 'applicationName',
        'administratorRole', 'createdRoles', 'addedMemberships'
    )
    $actualProperties = @($marker.PSObject.Properties.Name | Sort-Object)
    if (($actualProperties -join '|') -cne (($expectedProperties | Sort-Object) -join '|')) {
        throw 'Ownership marker has an unexpected schema; no resource was deleted.'
    }
    if ([int]$marker.schemaVersion -ne $script:MarkerSchemaVersion) {
        throw 'Ownership marker schema version is unsupported; no resource was deleted.'
    }

    $parsedRunId = [guid]::Empty
    if (-not [guid]::TryParseExact(
        [string]$marker.runId,
        'D',
        [ref]$parsedRunId
    )) {
        throw 'Ownership marker run identifier is invalid; no resource was deleted.'
    }
    $normalizedRunId = $parsedRunId.ToString('D').ToLowerInvariant()
    if ([string]$marker.runId -cne $normalizedRunId) {
        throw 'Ownership marker run identifier is not canonical; no resource was deleted.'
    }
    $compactRunId = $normalizedRunId.Replace('-', '').Substring(0, 12)
    if ([string]$marker.databaseName -cne ($script:OwnedDatabasePrefix + $compactRunId)) {
        throw 'Ownership marker database name does not match its run identifier; no resource was deleted.'
    }
    if ([string]$marker.applicationName -cne ('cfh_' + $compactRunId)) {
        throw 'Ownership marker application name does not match its run identifier; no resource was deleted.'
    }
    if ([string]$marker.administratorRole -notmatch '^[a-z_][a-z0-9_]{0,62}$') {
        throw 'Ownership marker administrator role is invalid; no resource was deleted.'
    }

    $marker.createdRoles = ConvertTo-ValidatedStringArray `
        -Value $marker.createdRoles `
        -Allowed $script:GroupRoles `
        -PropertyName 'createdRoles'
    $marker.addedMemberships = ConvertTo-ValidatedStringArray `
        -Value $marker.addedMemberships `
        -Allowed $script:MembershipRoles `
        -PropertyName 'addedMemberships'

    $unexpectedFiles = @(Get-ChildItem -LiteralPath $script:TaskRoot -Force | Where-Object {
        $_.Name -notin @('ownership.json', 'provisioning-wrapper.sql')
    })
    if ($unexpectedFiles.Count -ne 0) {
        throw 'The task directory contains an unexpected file; no resource was deleted.'
    }
    return $marker
}

function Assert-NoUnmarkedResources {
    Assert-TaskRoot
    if (Test-Path -LiteralPath $script:TaskRoot) {
        $entries = @(Get-ChildItem -LiteralPath $script:TaskRoot -Force)
        if ($entries.Count -eq 0) {
            Remove-Item -LiteralPath $script:TaskRoot -Force
        }
        else {
            throw 'The task directory exists without a usable ownership marker; no resource was deleted.'
        }
    }

    $databaseNames = Invoke-MaintenanceScalar @"
SELECT COALESCE(pg_catalog.string_agg(datname, ',' ORDER BY datname), '')
FROM pg_catalog.pg_database
WHERE datname LIKE '$($script:OwnedDatabasePrefix)%';
"@
    if (-not [string]::IsNullOrEmpty($databaseNames)) {
        throw "Harness-pattern databases exist without an ownership marker; no resource was deleted: $databaseNames"
    }

    $roleNames = Invoke-MaintenanceScalar @"
SELECT COALESCE(pg_catalog.string_agg(role_row.rolname, ',' ORDER BY role_row.rolname), '')
FROM pg_catalog.pg_roles AS role_row
WHERE pg_catalog.shobj_description(role_row.oid, 'pg_authid')
      LIKE '$($script:OwnershipCommentPrefix)%';
"@
    if (-not [string]::IsNullOrEmpty($roleNames)) {
        throw "Harness-tagged roles exist without an ownership marker; no resource was deleted: $roleNames"
    }
}

function New-OwnedDatabase {
    param([Parameter(Mandatory = $true)]$Marker)

    $existing = Invoke-MaintenanceScalar (
        "SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_database WHERE datname = '$($Marker.databaseName)')::text;"
    )
    if ($existing -ne 'false') {
        throw "Generated database unexpectedly already exists: $($Marker.databaseName)"
    }

    $comment = $script:OwnershipCommentPrefix + $Marker.runId
    & $script:CreatedbPath `
        -h $HostName -p $Port -U $AdministratorRole `
        -T template0 -O $AdministratorRole `
        $Marker.databaseName
    if ($LASTEXITCODE -ne 0) {
        throw "createdb failed with exit code $LASTEXITCODE."
    }
    [void](Invoke-MaintenanceScalar (
        "COMMENT ON DATABASE $($Marker.databaseName) IS '$comment'; SELECT 'commented';"
    ))

    $evidence = Invoke-MaintenanceScalar @"
SELECT pg_catalog.concat_ws('|',
    database_row.datname,
    pg_catalog.pg_get_userbyid(database_row.datdba),
    COALESCE(pg_catalog.shobj_description(database_row.oid, 'pg_database'), '')
)
FROM pg_catalog.pg_database AS database_row
WHERE database_row.datname = '$($Marker.databaseName)';
"@
    $expected = "$($Marker.databaseName)|$($Marker.administratorRole)|$comment"
    if ($evidence -cne $expected) {
        throw "New database ownership evidence did not match the marker: $evidence"
    }
    Write-HarnessMarker 'DATABASE' 'PASS' "Created task-owned database $($Marker.databaseName)."
}

function Invoke-OwnedProvisioning {
    param([Parameter(Mandatory = $true)]$Marker)

    $provisioningPath = (
        Resolve-Path (Join-Path $script:DatabaseRoot 'provisioning\001_foundation_roles.sql')
    ).Path.Replace('\', '/')
    $lines = [System.Collections.Generic.List[string]]::new()
    [void]$lines.Add('\set ON_ERROR_STOP on')
    [void]$lines.Add('BEGIN;')
    [void]$lines.Add("\i '$provisioningPath'")
    foreach ($roleName in $Marker.createdRoles) {
        [void]$lines.Add(
            "COMMENT ON ROLE $roleName IS '$($script:OwnershipCommentPrefix)$($Marker.runId)';"
        )
    }
    [void]$lines.Add('COMMIT;')
    [System.IO.File]::WriteAllLines(
        $script:ProvisioningWrapperPath,
        $lines,
        [System.Text.UTF8Encoding]::new($false)
    )

    $output = & $script:ResolvedPsqlPath `
        -X -v ON_ERROR_STOP=1 `
        -h $HostName -p $Port -U $AdministratorRole `
        -d $Marker.databaseName `
        -f $script:ProvisioningWrapperPath 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    if ($exitCode -ne 0) {
        throw "Role provisioning failed with exit code $exitCode."
    }

    foreach ($roleName in $script:GroupRoles) {
        $attributes = Invoke-MaintenanceScalar @"
SELECT pg_catalog.concat_ws('|',
    rolcanlogin, rolsuper, rolcreatedb, rolcreaterole,
    rolreplication, rolbypassrls
)
FROM pg_catalog.pg_roles
WHERE rolname = '$roleName';
"@
        if ($attributes -cne 'f|f|f|f|f|f') {
            throw "Role $roleName has incompatible attributes: $attributes"
        }
    }
    foreach ($roleName in $script:MembershipRoles) {
        if (-not (Test-DirectMembership $roleName $AdministratorRole)) {
            throw "Required direct membership was not established: $roleName -> $AdministratorRole"
        }
    }
    foreach ($roleName in $Marker.createdRoles) {
        $comment = Invoke-MaintenanceScalar @"
SELECT COALESCE(pg_catalog.shobj_description(role_row.oid, 'pg_authid'), '')
FROM pg_catalog.pg_roles AS role_row
WHERE role_row.rolname = '$roleName';
"@
        if ($comment -cne ($script:OwnershipCommentPrefix + $Marker.runId)) {
            throw "Created role $roleName lacks matching ownership evidence."
        }
    }
    Write-HarnessMarker 'ROLES' 'PASS' 'Provisioning completed with preexisting-state evidence retained.'
}

function Set-WorkflowEnvironment {
    param([Parameter(Mandatory = $true)]$Marker)

    $env:PGHOST = $HostName
    $env:PGPORT = $Port.ToString()
    $env:PGDATABASE = $Marker.databaseName
    $env:PGUSER = $AdministratorRole
    $env:PGOPTIONS = '-c lock_timeout=5000 -c statement_timeout=60000'
    $env:PGAPPNAME = $Marker.applicationName
    $env:CAFE_FAUSSE_ENVIRONMENT = 'test'
    $env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
    $env:CAFE_FAUSSE_PSQL = $script:ResolvedPsqlPath
}

function Invoke-RepositorySqlFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [switch]$AllowExpectedErrors,
        [string]$RequiredMarker
    )

    $resolvedPath = (Resolve-Path (Join-Path $script:RepositoryRoot $RelativePath)).Path
    $arguments = @('-X')
    if (-not $AllowExpectedErrors) {
        $arguments += @('-v', 'ON_ERROR_STOP=1')
    }
    $arguments += @('-f', $resolvedPath)
    $output = & $script:ResolvedPsqlPath @arguments 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    if ($exitCode -ne 0) {
        throw "psql failed with exit code $exitCode for $RelativePath"
    }
    if (-not [string]::IsNullOrEmpty($RequiredMarker) -and
        -not (($output -join [Environment]::NewLine).Contains($RequiredMarker))) {
        throw "Required marker was absent for $RelativePath`: $RequiredMarker"
    }
}

function Invoke-Db05Checkpoint {
    & (Join-Path $PSScriptRoot 'rebuild.ps1') `
        -ThroughMigration '004_foundation_privileges.sql'
    Invoke-RepositorySqlFile 'database\tests\db05_behavior_tests.sql'
    Invoke-RepositorySqlFile `
        'database\tests\runtime_privilege_denials.sql' `
        -AllowExpectedErrors `
        -RequiredMarker 'Runtime privilege-denial behavior: 5/5 PASS'
    Write-HarnessMarker 'DB05' 'PASS' 'DB-05 diagnostic checkpoint passed.'
}

function Invoke-Db06Checkpoint {
    & (Join-Path $PSScriptRoot 'rebuild.ps1') `
        -ThroughMigration '009_reservation_privileges.sql'
    Invoke-RepositorySqlFile 'database\tests\db06_behavior_tests.sql'
    Invoke-RepositorySqlFile `
        'database\tests\db06_runtime_privilege_denials.sql' `
        -AllowExpectedErrors `
        -RequiredMarker 'DB-06 runtime privilege-denial behavior: 7/7 PASS'
    & (Join-Path $PSScriptRoot 'concurrency_test.ps1') -Iterations 20
    Write-HarnessMarker 'DB06' 'PASS' 'DB-06 diagnostic checkpoint passed.'
}

function Invoke-Db07Checkpoint {
    & (Join-Path $PSScriptRoot 'rebuild.ps1') -SkipProvisioning
    & (Join-Path $PSScriptRoot 'verify.ps1')
    Invoke-RepositorySqlFile `
        'database\tests\db07_behavior_tests.sql' `
        -RequiredMarker 'DB-07 behavior assertions: 3 passed'
    & (Join-Path $PSScriptRoot 'performance_test.ps1') -Samples 20
    Invoke-RepositorySqlFile 'database\verification\query_plans_db07.sql'
    & (Join-Path $PSScriptRoot 'rebuild.ps1') -SkipProvisioning
    & (Join-Path $PSScriptRoot 'verify.ps1')
    Write-HarnessMarker 'DB07' 'PASS' 'DB-07 diagnostic checkpoint passed and baseline restored.'
}

function Throw-InjectedFailure {
    param([Parameter(Mandatory = $true)][string]$Point)
    throw "[HARNESS:INJECTED:FAIL] Controlled test-only failure at $Point."
}

function Invoke-RequestedExecution {
    if ($FailurePoint -eq 'Setup') {
        Throw-InjectedFailure $FailurePoint
    }
    if ($FailurePoint -eq 'AfterDatabaseCreation' -or
        $FailurePoint -eq 'AfterRoleProvisioning') {
        Throw-InjectedFailure $FailurePoint
    }
    if ($FailurePoint -eq 'AfterMigrationsBegin') {
        & (Join-Path $PSScriptRoot 'rebuild.ps1') `
            -ThroughMigration '004_foundation_privileges.sql'
        Throw-InjectedFailure $FailurePoint
    }
    if ($FailurePoint -eq 'AfterDB05') {
        Invoke-Db05Checkpoint
        Throw-InjectedFailure $FailurePoint
    }
    if ($FailurePoint -eq 'AfterDB06') {
        Invoke-Db06Checkpoint
        Throw-InjectedFailure $FailurePoint
    }
    if ($FailurePoint -eq 'AfterDB07') {
        Invoke-Db07Checkpoint
        Throw-InjectedFailure $FailurePoint
    }
    if ($FailurePoint -eq 'BeforeFinalBaseline') {
        & (Join-Path $PSScriptRoot 'rebuild.ps1') -SkipProvisioning
        & (Join-Path $PSScriptRoot 'performance_test.ps1') -Samples 10
        Throw-InjectedFailure $FailurePoint
    }

    switch ($Mode) {
        'Complete' {
            & (Join-Path $PSScriptRoot 'test.ps1')
            & (Join-Path $PSScriptRoot 'verify.ps1')
            Write-HarnessMarker 'EXECUTION' 'PASS' 'Complete ordered DB-05 through DB-07 gate passed.'
        }
        'DB05' { Invoke-Db05Checkpoint }
        'DB06' { Invoke-Db06Checkpoint }
        'DB07' { Invoke-Db07Checkpoint }
        default { throw "Unsupported execution mode: $Mode" }
    }
}

function Remove-OwnedResources {
    param([Parameter(Mandatory = $true)]$Marker)

    if ([string]$Marker.administratorRole -cne $AdministratorRole) {
        throw 'Marker administrator does not match the requested administrator; no resource was deleted.'
    }
    $expectedComment = $script:OwnershipCommentPrefix + $Marker.runId
    $databaseEvidence = Invoke-MaintenanceScalar @"
SELECT COALESCE((
    SELECT pg_catalog.concat_ws('|',
        pg_catalog.pg_get_userbyid(database_row.datdba),
        COALESCE(pg_catalog.shobj_description(database_row.oid, 'pg_database'), '')
    )
    FROM pg_catalog.pg_database AS database_row
    WHERE database_row.datname = '$($Marker.databaseName)'
), 'absent');
"@

    if ($databaseEvidence -ne 'absent') {
        $expectedDatabaseEvidence = "$($Marker.administratorRole)|$expectedComment"
        $incompleteCreationEvidence = "$($Marker.administratorRole)|"
        if ($databaseEvidence -cne $expectedDatabaseEvidence -and
            $databaseEvidence -cne $incompleteCreationEvidence) {
            throw 'Database ownership evidence does not match the marker; no resource was deleted.'
        }

        $unexpectedSessions = Invoke-MaintenanceScalar @"
SELECT pg_catalog.count(*)::text
FROM pg_catalog.pg_stat_activity
WHERE datname = '$($Marker.databaseName)'
  AND application_name NOT LIKE '$($Marker.applicationName)%';
"@
        if ($unexpectedSessions -ne '0') {
            throw 'Unexpected sessions are connected to the task database; cleanup refused.'
        }

        [void](Invoke-MaintenanceScalar @"
SELECT pg_catalog.count(*)::text
FROM (
    SELECT pg_catalog.pg_terminate_backend(pid)
    FROM pg_catalog.pg_stat_activity
    WHERE datname = '$($Marker.databaseName)'
      AND application_name LIKE '$($Marker.applicationName)%'
      AND pid <> pg_catalog.pg_backend_pid()
) AS terminated;
"@)

        $deadline = [datetime]::UtcNow.AddSeconds(10)
        do {
            $remainingSessions = Invoke-MaintenanceScalar (
                "SELECT pg_catalog.count(*)::text FROM pg_catalog.pg_stat_activity WHERE datname = '$($Marker.databaseName)';"
            )
            if ($remainingSessions -eq '0') { break }
            Start-Sleep -Milliseconds 100
        } while ([datetime]::UtcNow -lt $deadline)
        if ($remainingSessions -ne '0') {
            throw 'Task database sessions did not exit within the cleanup bound.'
        }

        & $script:DropdbPath `
            -h $HostName -p $Port -U $AdministratorRole `
            $Marker.databaseName
        if ($LASTEXITCODE -ne 0) {
            throw "dropdb failed with exit code $LASTEXITCODE."
        }
        $databaseAbsent = Invoke-MaintenanceScalar (
            "SELECT (NOT EXISTS (SELECT 1 FROM pg_catalog.pg_database WHERE datname = '$($Marker.databaseName)'))::text;"
        )
        if ($databaseAbsent -ne 'true') {
            throw 'Task database still exists after dropdb.'
        }
        Write-HarnessMarker 'CLEANUP-DATABASE' 'PASS' "Removed task-owned database $($Marker.databaseName)."
    }
    else {
        Write-HarnessMarker 'CLEANUP-DATABASE' 'PASS' 'Task-owned database was already absent.'
    }

    foreach ($roleName in $Marker.addedMemberships) {
        if (Test-DirectMembership $roleName $Marker.administratorRole) {
            [void](Invoke-MaintenanceScalar (
                "REVOKE $roleName FROM $($Marker.administratorRole); SELECT 'revoked';"
            ))
        }
    }

    $createdRolesInDropOrder = @($Marker.createdRoles)
    [array]::Reverse($createdRolesInDropOrder)
    foreach ($roleName in $createdRolesInDropOrder) {
        if (-not (Test-RoleExists $roleName)) {
            continue
        }
        $roleEvidence = Invoke-MaintenanceScalar @"
SELECT pg_catalog.concat_ws('|',
    COALESCE(pg_catalog.shobj_description(role_row.oid, 'pg_authid'), ''),
    role_row.rolcanlogin,
    role_row.rolsuper,
    role_row.rolcreatedb,
    role_row.rolcreaterole,
    role_row.rolreplication,
    role_row.rolbypassrls
)
FROM pg_catalog.pg_roles AS role_row
WHERE role_row.rolname = '$roleName';
"@
        if ($roleEvidence -cne "$expectedComment|f|f|f|f|f|f") {
            throw "Role ownership evidence does not match for $roleName; role deletion refused."
        }
        [void](Invoke-MaintenanceScalar "DROP ROLE $roleName; SELECT 'dropped';")
    }

    foreach ($roleName in $Marker.createdRoles) {
        if (Test-RoleExists $roleName) {
            throw "Task-created role still exists after cleanup: $roleName"
        }
    }
    foreach ($roleName in $Marker.addedMemberships) {
        if (Test-DirectMembership $roleName $Marker.administratorRole) {
            throw "Task-added membership still exists after cleanup: $roleName"
        }
    }
    Write-HarnessMarker 'CLEANUP-ROLES' 'PASS' 'Task-created roles and memberships were removed; preexisting roles were preserved.'

    if (Test-Path -LiteralPath $script:ProvisioningWrapperPath -PathType Leaf) {
        Remove-Item -LiteralPath $script:ProvisioningWrapperPath -Force
    }
    if (Test-Path -LiteralPath $script:MarkerPath -PathType Leaf) {
        Remove-Item -LiteralPath $script:MarkerPath -Force
    }
    $remainingFiles = @(Get-ChildItem -LiteralPath $script:TaskRoot -Force)
    if ($remainingFiles.Count -ne 0) {
        throw 'Task directory still contains artifacts after cleanup.'
    }
    Remove-Item -LiteralPath $script:TaskRoot -Force
    if (Test-Path -LiteralPath $script:TaskRoot) {
        throw 'Task directory still exists after cleanup.'
    }
    Write-HarnessMarker 'CLEANUP' 'PASS' 'All marker-proven task resources were removed.'
}

if ($LeaveOwnedResourcesForRecovery -and $FailurePoint -eq 'None') {
    throw '-LeaveOwnedResourcesForRecovery requires an explicit test-only FailurePoint.'
}
if ($Mode -ne 'Complete' -and $FailurePoint -ne 'None') {
    throw 'Failure injection is supported only with -Mode Complete.'
}

$environmentSnapshot = Get-EnvironmentSnapshot
$primaryError = $null
$cleanupError = $null
$activeMarker = $null
$skipResourceCleanup = $false

try {
    Write-HarnessMarker 'SETUP' 'BEGIN' 'Validate prerequisites and recover any prior owned leftovers.'
    Assert-TaskRoot
    Resolve-PostgreSqlTools
    Initialize-CredentialSource
    Assert-MaintenanceTarget

    if (Test-Path -LiteralPath $script:MarkerPath -PathType Leaf) {
        $recoveryMarker = Read-ValidatedMarker
        Write-HarnessMarker 'RECOVERY' 'BEGIN' "Recover prior run $($recoveryMarker.runId)."
        Remove-OwnedResources $recoveryMarker
        Write-HarnessMarker 'RECOVERY' 'PASS' 'Prior marker-proven leftovers were removed.'
    }
    else {
        Assert-NoUnmarkedResources
    }

    if ($Mode -eq 'CleanupOnly') {
        Write-HarnessMarker 'COMPLETE' 'PASS' 'Cleanup-only verification found no task-owned leftovers.'
        return
    }

    $activeMarker = New-MarkerData
    Write-NewMarker $activeMarker
    if ($FailurePoint -eq 'Setup') {
        Throw-InjectedFailure $FailurePoint
    }

    New-OwnedDatabase $activeMarker
    if ($FailurePoint -eq 'AfterDatabaseCreation') {
        Throw-InjectedFailure $FailurePoint
    }

    Invoke-OwnedProvisioning $activeMarker
    if ($FailurePoint -eq 'AfterRoleProvisioning') {
        Throw-InjectedFailure $FailurePoint
    }

    Set-WorkflowEnvironment $activeMarker
    Write-HarnessMarker 'EXECUTION' 'BEGIN' "Run mode $Mode against $($activeMarker.databaseName)."
    Invoke-RequestedExecution
}
catch {
    $primaryError = $_
    Write-HarnessMarker 'PRIMARY' 'FAIL' $_.Exception.Message
    if ($LeaveOwnedResourcesForRecovery -and
        $_.Exception.Message.StartsWith('[HARNESS:INJECTED:FAIL]', [System.StringComparison]::Ordinal)) {
        $skipResourceCleanup = $true
        Write-HarnessMarker 'RECOVERY-FIXTURE' 'PASS' 'Owned resources intentionally retained for the next-invocation recovery test.'
    }
}
finally {
    if ($null -ne $activeMarker -and -not $skipResourceCleanup) {
        try {
            Write-HarnessMarker 'CLEANUP' 'BEGIN' 'Remove only marker-proven task resources.'
            Remove-OwnedResources $activeMarker
        }
        catch {
            $cleanupError = $_
            Write-HarnessMarker 'CLEANUP' 'FAIL' $_.Exception.Message
        }
    }

    if ($null -ne $script:SecurePassword) {
        $script:SecurePassword.Dispose()
        $script:SecurePassword = $null
    }
    Restore-EnvironmentSnapshot $environmentSnapshot
}

if ($null -ne $primaryError) {
    if ($null -ne $cleanupError) {
        throw "Primary failure: $($primaryError.Exception.Message) Cleanup failure: $($cleanupError.Exception.Message)"
    }
    throw $primaryError
}
if ($null -ne $cleanupError) {
    throw $cleanupError
}

Write-HarnessMarker 'COMPLETE' 'PASS' 'Workflow passed, cleanup passed, and caller environment was restored.'
