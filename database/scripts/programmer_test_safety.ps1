[CmdletBinding()]
param(
    [ValidateSet('127.0.0.1')]
    [string]$HostName = '127.0.0.1',

    [ValidateRange(1, 65535)]
    [int]$Port = 5432,

    [ValidatePattern('^[a-z_][a-z0-9_]{0,62}$')]
    [string]$AdministratorRole = 'postgres',

    [string]$PsqlPath,

    [string]$NonProductionClusterAuthorization,

    [switch]$SkipCompleteRuns,

    [switch]$TestOnlyTopLevelAbort
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
$script:RequiredNonProductionAuthorization = 'AUTHORIZED_NONPRODUCTION'

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
        -h $HostName -p $Port -U $AdministratorRole -d postgres -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw 'Safety-validation PostgreSQL query failed.'
    }
    return (($output | Select-Object -Last 1) -as [string]).Trim()
}

function Get-DirectMembershipEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$GrantedRole,
        [Parameter(Mandatory = $true)][string]$MemberRole
    )
    return Invoke-Scalar @"
SELECT COALESCE(pg_catalog.string_agg(
    pg_catalog.concat_ws('|', grantor_role.rolname,
        membership.admin_option, membership.inherit_option,
        membership.set_option), ',' ORDER BY grantor_role.rolname), '')
FROM pg_catalog.pg_auth_members AS membership
JOIN pg_catalog.pg_roles AS granted_role ON granted_role.oid = membership.roleid
JOIN pg_catalog.pg_roles AS member_role ON member_role.oid = membership.member
JOIN pg_catalog.pg_roles AS grantor_role ON grantor_role.oid = membership.grantor
WHERE granted_role.rolname = '$GrantedRole'
  AND member_role.rolname = '$MemberRole';
"@
}

function Close-SafetyPsqlChildBounded {
    param([Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process)
    try {
        if (-not $Process.HasExited -and $Process.StartInfo.RedirectStandardInput) {
            try {
                $Process.StandardInput.WriteLine('\q')
                $Process.StandardInput.Flush()
            }
            catch {
                if (-not $Process.HasExited) { throw }
            }
        }
        if (-not $Process.HasExited -and -not $Process.WaitForExit(3000)) {
            $Process.Kill()
            if (-not $Process.WaitForExit(3000)) {
                throw 'Safety psql child did not exit after kill.'
            }
        }
        if (-not $Process.HasExited) {
            throw 'Safety psql child remains after bounded cleanup.'
        }
    }
    finally { $Process.Dispose() }
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
            role_row.rolinherit, role_row.rolreplication, role_row.rolbypassrls,
            COALESCE(pg_catalog.shobj_description(role_row.oid, 'pg_authid'), '')),
        ',' ORDER BY role_row.rolname), '')
     FROM pg_catalog.pg_roles AS role_row
     WHERE role_row.rolname IN (
        '$AdministratorRole','cafe_fausse_owner','cafe_fausse_app','cafe_fausse_test'
     )),
    (SELECT COALESCE(pg_catalog.string_agg(
        pg_catalog.concat_ws('|', granted_role.rolname, member_role.rolname,
            grantor_role.rolname, membership.admin_option,
            membership.inherit_option, membership.set_option),
        ',' ORDER BY granted_role.rolname, member_role.rolname,
            grantor_role.rolname), '')
     FROM pg_catalog.pg_auth_members AS membership
     JOIN pg_catalog.pg_roles AS granted_role ON granted_role.oid = membership.roleid
     JOIN pg_catalog.pg_roles AS member_role ON member_role.oid = membership.member
     JOIN pg_catalog.pg_roles AS grantor_role ON grantor_role.oid = membership.grantor
     WHERE granted_role.rolname IN (
            'cafe_fausse_owner','cafe_fausse_app','cafe_fausse_test'
        )
        OR member_role.rolname IN (
            '$AdministratorRole','cafe_fausse_owner','cafe_fausse_app','cafe_fausse_test'
        ))
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
     WHERE role_row.rolname LIKE 'cafe_fausse_harness_%'
        OR pg_catalog.shobj_description(role_row.oid, 'pg_authid')
           LIKE '$($script:OwnershipCommentPrefix)%'),
    (SELECT count(*) FROM pg_catalog.pg_stat_activity
     WHERE application_name LIKE 'cfh_%'),
    (SELECT count(*) FROM pg_catalog.pg_auth_members AS membership
     JOIN pg_catalog.pg_roles AS granted_role ON granted_role.oid = membership.roleid
     JOIN pg_catalog.pg_roles AS member_role ON member_role.oid = membership.member
     WHERE granted_role.rolname LIKE 'cafe_fausse_harness_%'
        OR member_role.rolname LIKE 'cafe_fausse_harness_%')
);
"@
    if ($facts -cne '0|0|0|0') {
        throw "Owned PostgreSQL artifacts remained after $Case`: $facts"
    }
}

function Invoke-AuthorizationRefusalTest {
    $case = 'TARGET-AUTHORIZATION-REFUSAL'
    Write-SafetyMarker $case 'BEGIN' 'Require an explicit, exact nonproduction authorization.'
    $environment = Get-EnvironmentSnapshot
    foreach ($authorization in @($null, 'INVALID')) {
        $caught = $null
        try {
            & $script:WorkflowPath -Mode CleanupOnly `
                -HostName $HostName -Port $Port `
                -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
                -NonProductionClusterAuthorization $authorization
        }
        catch { $caught = $_ }
        if ($null -eq $caught -or
            -not $caught.Exception.Message.Contains('Explicit nonproduction-cluster authorization is required')) {
            throw 'Missing or invalid nonproduction authorization was not rejected.'
        }
        Assert-EnvironmentEquals $environment $case
        Assert-NoOwnedArtifacts $case
    }
    Write-SafetyMarker $case 'PASS' 'Missing and invalid authorization values were refused before resource creation.'
}

function Invoke-UntaggedDatabaseRestartTest {
    $case = 'UNTAGGED-DATABASE-RESTART'
    Write-SafetyMarker $case 'BEGIN' 'Require same-invocation cleanup but restart refusal across the database-tagging gap.'
    $caught = $null
    try {
        & $script:WorkflowPath -Mode Complete `
            -FailurePoint AfterDatabaseCreationBeforeTagging `
            -LeaveOwnedResourcesForRecovery `
            -HostName $HostName -Port $Port `
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    }
    catch { $caught = $_ }
    if ($null -eq $caught -or
        -not $caught.Exception.Message.Contains('[HARNESS:INJECTED:FAIL]')) {
        throw 'The untagged restart fixture did not reach the tagging gap.'
    }
    $marker = Get-Content -LiteralPath $script:MarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $databaseEvidence = Invoke-Scalar @"
SELECT pg_catalog.concat_ws('|', pg_catalog.pg_get_userbyid(database_row.datdba),
    COALESCE(pg_catalog.shobj_description(database_row.oid, 'pg_database'), ''))
FROM pg_catalog.pg_database AS database_row
WHERE database_row.datname = '$($marker.databaseName)';
"@
    if ($databaseEvidence -cne "$AdministratorRole|") {
        throw 'The tagging-gap fixture does not contain the expected untagged database.'
    }

    $recoveryError = $null
    try {
        & $script:WorkflowPath -Mode CleanupOnly `
            -HostName $HostName -Port $Port `
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    }
    catch { $recoveryError = $_ }
    if ($null -eq $recoveryError -or
        -not $recoveryError.Exception.Message.Contains('ownership evidence does not match')) {
        throw 'Restart recovery did not refuse the untagged database.'
    }
    if ((Invoke-Scalar "SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_database WHERE datname = '$($marker.databaseName)')::text;") -ne 'true') {
        throw 'Restart recovery deleted the ambiguous untagged database.'
    }

    # The safety suite created this exact fixture and can install the missing
    # durable tag before asking the ordinary recovery path to remove it.
    [void](Invoke-Scalar (
        "COMMENT ON DATABASE $($marker.databaseName) IS '$($script:OwnershipCommentPrefix)$($marker.runId)'; SELECT 'tagged';"
    ))
    & $script:WorkflowPath -Mode CleanupOnly `
        -HostName $HostName -Port $Port `
        -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
        -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'Restart refused deletion until the safety fixture installed exact durable ownership evidence.'
}

function Invoke-ProvisionerRoleRaceTest {
    $case = 'PROVISIONER-ROLE-RACE'
    Write-SafetyMarker $case 'BEGIN' 'Require refusal when the unique provisioner name appears before harness creation.'
    $caught = $null
    try {
        & $script:WorkflowPath -Mode Complete `
            -TestOnlyOwnershipRace ProvisionerRole `
            -HostName $HostName -Port $Port `
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    }
    catch { $caught = $_ }
    if ($null -eq $caught) { throw 'The provisioner-role race was not rejected.' }
    $marker = Get-Content -LiteralPath $script:MarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $comment = Invoke-Scalar @"
SELECT COALESCE(pg_catalog.shobj_description(role_row.oid, 'pg_authid'), '')
FROM pg_catalog.pg_roles AS role_row WHERE role_row.rolname = '$($marker.provisionerRole)';
"@
    if ($comment -cne '') { throw 'The colliding provisioner role was incorrectly tagged.' }
    [void](Invoke-Scalar "DROP ROLE $($marker.provisionerRole); SELECT 'dropped';")
    & $script:WorkflowPath -Mode CleanupOnly `
        -HostName $HostName -Port $Port `
        -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
        -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'The untagged colliding role was preserved until explicit fixture cleanup.'
}

function Invoke-FixedRoleRaceTest {
    $case = 'FIXED-ROLE-RACE'
    Write-SafetyMarker $case 'BEGIN' 'Require a fixed role appearing after preflight to remain untagged and preserved.'
    $beforeRoles = Invoke-Scalar @"
SELECT COALESCE(pg_catalog.string_agg(rolname, ',' ORDER BY rolname), '')
FROM pg_catalog.pg_roles
WHERE rolname IN ('cafe_fausse_owner','cafe_fausse_app','cafe_fausse_test');
"@
    $caught = $null
    try {
        & $script:WorkflowPath -Mode Complete `
            -TestOnlyOwnershipRace FixedRole `
            -HostName $HostName -Port $Port `
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    }
    catch { $caught = $_ }
    if ($null -eq $caught) { throw 'The fixed-role race was not rejected.' }
    $afterRoles = @((Invoke-Scalar @"
SELECT COALESCE(pg_catalog.string_agg(rolname, ',' ORDER BY rolname), '')
FROM pg_catalog.pg_roles
WHERE rolname IN ('cafe_fausse_owner','cafe_fausse_app','cafe_fausse_test');
"@).Split(',') | Where-Object { -not [string]::IsNullOrEmpty($_) })
    $beforeRoleArray = @($beforeRoles.Split(',') | Where-Object { -not [string]::IsNullOrEmpty($_) })
    $raceRoles = @($afterRoles | Where-Object { $_ -notin $beforeRoleArray })
    if ($raceRoles.Count -ne 1) { throw 'Unable to identify the single preserved fixed-role race fixture.' }
    $comment = Invoke-Scalar @"
SELECT COALESCE(pg_catalog.shobj_description(role_row.oid, 'pg_authid'), '')
FROM pg_catalog.pg_roles AS role_row WHERE role_row.rolname = '$($raceRoles[0])';
"@
    if ($comment -cne '') { throw 'The fixed-role race fixture was incorrectly tagged.' }
    [void](Invoke-Scalar "DROP ROLE $($raceRoles[0]); SELECT 'dropped';")
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'The post-preflight role was not adopted, tagged, or dropped by the harness.'
}

function Invoke-FixedMembershipPreservationTest {
    $case = 'DIRECT-MEMBERSHIP-PRESERVATION'
    Write-SafetyMarker $case 'BEGIN' 'Preserve an exact direct administrator membership not owned by the harness.'
    $createdFixtureRoles = [System.Collections.Generic.List[string]]::new()
    $beforeEdge = $null
    try {
        foreach ($roleName in @('cafe_fausse_owner','cafe_fausse_app','cafe_fausse_test')) {
            $exists = Invoke-Scalar "SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '$roleName')::text;"
            if ($exists -eq 'false') {
                [void](Invoke-Scalar "CREATE ROLE $roleName NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS; SELECT 'created';")
                [void]$createdFixtureRoles.Add($roleName)
            }
        }
        $beforeEdge = Get-DirectMembershipEvidence 'cafe_fausse_owner' $AdministratorRole
        if (-not [string]::IsNullOrEmpty($beforeEdge)) {
            throw 'The controlled direct-membership fixture requires a missing owner-to-administrator edge.'
        }
        $caught = $null
        try {
            & $script:WorkflowPath -Mode Complete `
                -TestOnlyOwnershipRace FixedMembership `
                -HostName $HostName -Port $Port `
                -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
                -NonProductionClusterAuthorization $NonProductionClusterAuthorization
        }
        catch { $caught = $_ }
        if ($null -eq $caught -or
            -not $caught.Exception.Message.Contains('[HARNESS:TEST-RACE:FAIL]')) {
            throw 'The fixed direct-membership ambiguity fixture did not fail as expected.'
        }
        $afterEdge = Get-DirectMembershipEvidence 'cafe_fausse_owner' $AdministratorRole
        if ($afterEdge -cne "$AdministratorRole|f|t|t") {
            throw 'The direct membership or its exact option state was not preserved.'
        }
    }
    finally {
        if (-not [string]::IsNullOrEmpty((Get-DirectMembershipEvidence 'cafe_fausse_owner' $AdministratorRole)) -and
            [string]::IsNullOrEmpty($beforeEdge)) {
            [void](Invoke-Scalar "REVOKE cafe_fausse_owner FROM $AdministratorRole; SELECT 'revoked';")
        }
        $dropRoles = @($createdFixtureRoles)
        [array]::Reverse($dropRoles)
        foreach ($roleName in $dropRoles) {
            if ((Invoke-Scalar "SELECT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = '$roleName')::text;") -eq 'true') {
                [void](Invoke-Scalar "DROP ROLE $roleName; SELECT 'dropped';")
            }
        }
    }
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'Exact pg_auth_members evidence survived harness cleanup and fixture state was restored.'
}

function Invoke-ProvisioningSessionRecoveryTest {
    $case = 'PROVISIONING-SESSION-RECOVERY'
    Write-SafetyMarker $case 'BEGIN' 'Recover a run-tagged session connected during the provisioning phase.'
    $caught = $null
    try {
        & $script:WorkflowPath -Mode Complete `
            -FailurePoint AfterRoleProvisioning `
            -LeaveOwnedResourcesForRecovery `
            -HostName $HostName -Port $Port `
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    }
    catch { $caught = $_ }
    if ($null -eq $caught -or
        -not $caught.Exception.Message.Contains('[HARNESS:INJECTED:FAIL]')) {
        throw 'Unable to create the provisioning-session recovery fixture.'
    }
    $marker = Get-Content -LiteralPath $script:MarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $script:ResolvedPsqlPath
    $startInfo.Arguments = "-X -qAt -v ON_ERROR_STOP=1 -h $HostName -p $Port -U $AdministratorRole -d $($marker.databaseName) -c `"SELECT pg_sleep(60);`""
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.EnvironmentVariables['PGAPPNAME'] = "$($marker.applicationName):provisioning"
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw 'Unable to start the provisioning-session fixture.' }
    try {
        $deadline = [datetime]::UtcNow.AddSeconds(5)
        do {
            $sessionCount = Invoke-Scalar "SELECT count(*) FROM pg_catalog.pg_stat_activity WHERE datname = '$($marker.databaseName)' AND application_name LIKE '$($marker.applicationName)%';"
            if ($sessionCount -eq '1') { break }
            Start-Sleep -Milliseconds 50
        } while ([datetime]::UtcNow -lt $deadline)
        if ($sessionCount -ne '1') { throw 'The run-tagged provisioning session was not observable.' }
        & $script:WorkflowPath -Mode CleanupOnly `
            -HostName $HostName -Port $Port `
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization
        if (-not $process.WaitForExit(5000)) {
            throw 'Recovery did not terminate the run-tagged provisioning session.'
        }
    }
    finally {
        Close-SafetyPsqlChildBounded $process
    }
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'Recovery identified the early run tag and removed the session and owned resources.'
}

function Invoke-TopLevelAbortRecoveryTest {
    $case = 'TOP-LEVEL-ABORT-RECOVERY'
    Write-SafetyMarker $case 'BEGIN' 'Require the safety suite outer finally to recover an unexpected abort.'
    $powerShellPath = Join-Path $PSHOME 'powershell.exe'
    $arguments = "-NoProfile -File `"$PSCommandPath`" -HostName $HostName -Port $Port -AdministratorRole $AdministratorRole -PsqlPath `"$($script:ResolvedPsqlPath)`" -NonProductionClusterAuthorization $NonProductionClusterAuthorization -SkipCompleteRuns -TestOnlyTopLevelAbort"
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powerShellPath
    $startInfo.Arguments = $arguments
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw 'Unable to start the top-level-abort child suite.' }
    try {
        if (-not $process.WaitForExit(60000)) {
            $process.Kill()
            if (-not $process.WaitForExit(5000)) {
                throw 'Top-level-abort child did not exit after kill.'
            }
            throw 'Top-level-abort child exceeded its 60-second bound.'
        }
        if ($process.ExitCode -eq 0) {
            throw 'Top-level-abort child did not preserve its injected primary failure.'
        }
    }
    finally { $process.Dispose() }
    Assert-NoOwnedArtifacts $case
    Write-SafetyMarker $case 'PASS' 'The child preserved its primary failure while outer recovery removed proven leftovers.'
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
        -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
        -NonProductionClusterAuthorization $NonProductionClusterAuthorization
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
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization
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
        -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
        -NonProductionClusterAuthorization $NonProductionClusterAuthorization
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
            -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization
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
        -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
        -NonProductionClusterAuthorization $NonProductionClusterAuthorization
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
                -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
                -NonProductionClusterAuthorization $NonProductionClusterAuthorization
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
        schemaVersion = 2
        runId = $runId
        databaseName = $databaseName
        applicationName = 'cfh_' + $compact
        administratorRole = $AdministratorRole
        provisionerRole = 'cafe_fausse_harness_' + $compact
        plannedCreatedRoles = @()
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
                -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
                -NonProductionClusterAuthorization $NonProductionClusterAuthorization
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
$suitePrimaryError = $null
$outerCleanupError = $null
try {
    if ($NonProductionClusterAuthorization -cne $script:RequiredNonProductionAuthorization) {
        throw "Explicit nonproduction-cluster authorization is required. Pass -NonProductionClusterAuthorization $($script:RequiredNonProductionAuthorization) only after confirming the selected PostgreSQL cluster is nonproduction."
    }
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

    if ($TestOnlyTopLevelAbort) {
        $fixtureError = $null
        try {
            & $script:WorkflowPath -Mode Complete `
                -FailurePoint AfterRoleProvisioning `
                -LeaveOwnedResourcesForRecovery `
                -HostName $HostName -Port $Port `
                -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
                -NonProductionClusterAuthorization $NonProductionClusterAuthorization
        }
        catch { $fixtureError = $_ }
        if ($null -eq $fixtureError -or
            -not $fixtureError.Exception.Message.Contains('[HARNESS:INJECTED:FAIL]')) {
            throw 'Unable to establish the top-level-abort ownership fixture.'
        }
        throw '[HARNESS-TEST:TOP-LEVEL-ABORT] Unexpected suite-level failure after an owned fixture.'
    }

    Invoke-AuthorizationRefusalTest

    foreach ($failurePoint in @(
        'Setup',
        'AfterDatabaseCreationBeforeTagging',
        'AfterDatabaseCreation',
        'AfterRoleProvisioning',
        'AfterChildCleanup',
        'AfterMigrationsBegin',
        'AfterDB05',
        'AfterDB06',
        'AfterDB07',
        'BeforeFinalBaseline'
    )) {
        Invoke-ExpectedInjectedFailure $failurePoint
    }

    Invoke-UntaggedDatabaseRestartTest
    Invoke-ProvisionerRoleRaceTest
    Invoke-FixedRoleRaceTest
    Invoke-FixedMembershipPreservationTest
    Invoke-ProvisioningSessionRecoveryTest
    Invoke-TopLevelAbortRecoveryTest
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
catch {
    $suitePrimaryError = $_
    Write-Host "[HARNESS-TEST:PRIMARY:FAIL] $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $script:MarkerPath -PathType Leaf) {
        try {
            Write-Host '[HARNESS-TEST:OUTER-RECOVERY:BEGIN] Valid marker remains; attempt bounded CleanupOnly recovery.'
            & $script:WorkflowPath -Mode CleanupOnly `
                -HostName $HostName -Port $Port `
                -AdministratorRole $AdministratorRole -PsqlPath $script:ResolvedPsqlPath `
                -NonProductionClusterAuthorization $NonProductionClusterAuthorization
            Write-Host '[HARNESS-TEST:OUTER-RECOVERY:PASS] Marker-proven leftovers were removed.'
        }
        catch {
            $outerCleanupError = $_
            Write-Host "[HARNESS-TEST:OUTER-RECOVERY:FAIL] $($_.Exception.Message)"
        }
    }
    if ($null -ne $script:SecurePassword) {
        $script:SecurePassword.Dispose()
        $script:SecurePassword = $null
    }
    Restore-EnvironmentSnapshot $callerEnvironment
}

if ($null -ne $suitePrimaryError) {
    if ($null -ne $outerCleanupError) {
        throw "Safety-suite primary failure: $($suitePrimaryError.Exception.Message) Outer recovery failure: $($outerCleanupError.Exception.Message)"
    }
    throw $suitePrimaryError
}
if ($null -ne $outerCleanupError) { throw $outerCleanupError }
