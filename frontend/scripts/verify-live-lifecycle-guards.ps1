[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('AUTHORIZED_NONPRODUCTION')]
    [string]$NonProductionClusterAuthorization
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$Repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
$Lifecycle = Join-Path $PSScriptRoot 'owned-live-integration.ps1'
$OwnedRoot = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'CafeFausse-prompt24-integration')).TrimEnd('\')
$MarkerPath = Join-Path $OwnedRoot 'ownership.json'
$ManagedNames = @(
    'CAFE_FAUSSE_ENVIRONMENT',
    'CAFE_FAUSSE_ALLOW_RESET',
    'CAFE_FAUSSE_PSQL',
    'CAFE_FAUSSE_FLASK_PROXY_TARGET',
    'CAFE_FAUSSE_VITE_CACHE_DIR',
    'PGHOST',
    'PGPORT',
    'PGDATABASE',
    'PGUSER',
    'PGPASSWORD',
    'PGPASSFILE',
    'PGSSLMODE'
)

function Save-EnvironmentProfile {
    $Profile = @{}
    $Current = [Environment]::GetEnvironmentVariables('Process')
    foreach ($Name in $ManagedNames) {
        $Profile[$Name] = [pscustomobject]@{
            present = $Current.Contains($Name)
            value = if ($Current.Contains($Name)) { [string]$Current[$Name] } else { $null }
        }
    }
    return $Profile
}

function Restore-EnvironmentProfile {
    param([Parameter(Mandatory)][hashtable]$Profile)
    foreach ($Name in $ManagedNames) {
        if ([bool]$Profile[$Name].present) {
            [Environment]::SetEnvironmentVariable($Name, [string]$Profile[$Name].value, 'Process')
        }
        else {
            [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
        }
    }
}

function Set-SentinelEnvironment {
    for ($Index = 0; $Index -lt $ManagedNames.Count; $Index++) {
        if ($Index % 2 -eq 0) {
            [Environment]::SetEnvironmentVariable($ManagedNames[$Index], "prompt24-guard-sentinel-$Index", 'Process')
        }
        else {
            [Environment]::SetEnvironmentVariable($ManagedNames[$Index], $null, 'Process')
        }
    }
}

function Assert-SentinelEnvironment {
    $Current = [Environment]::GetEnvironmentVariables('Process')
    for ($Index = 0; $Index -lt $ManagedNames.Count; $Index++) {
        $Name = $ManagedNames[$Index]
        if ($Index % 2 -eq 0) {
            if (-not $Current.Contains($Name) -or [string]$Current[$Name] -cne "prompt24-guard-sentinel-$Index") {
                throw "Caller environment value/presence was not restored for $Name."
            }
        }
        elseif ($Current.Contains($Name)) {
            throw "Originally absent caller environment variable was not removed: $Name."
        }
    }
}

function Invoke-LifecycleCase {
    param(
        [Parameter(Mandatory)][string]$Action,
        [string]$TestSeam = 'None',
        [switch]$ExpectFailure
    )
    Set-SentinelEnvironment
    $Failed = $false
    try {
        & $Lifecycle -Action $Action `
            -NonProductionClusterAuthorization $NonProductionClusterAuthorization `
            -TestSeam $TestSeam
    }
    catch {
        $Failed = $true
        $FailureMessage = $_.Exception.Message
    }
    Assert-SentinelEnvironment
    if ($ExpectFailure -and -not $Failed) { throw "$Action/$TestSeam unexpectedly succeeded." }
    if ($ExpectFailure -and $Failed) { Write-Output "Expected $Action/$TestSeam failure: $FailureMessage" }
    if (-not $ExpectFailure -and $Failed) {
        throw "$Action/$TestSeam failed unexpectedly: $FailureMessage"
    }
}

function Test-LocalPortOpen {
    param([Parameter(Mandatory)][int]$Port)
    $Client = [Net.Sockets.TcpClient]::new()
    try { $Attempt = $Client.ConnectAsync('127.0.0.1', $Port); return $Attempt.Wait(300) -and $Client.Connected }
    catch { return $false }
    finally { $Client.Dispose() }
}

function Assert-NoOwnedEnvironment {
    if (Test-Path -LiteralPath $OwnedRoot) { throw 'Prompt-24 owned root remains after guarded recovery.' }
    foreach ($Port in @(55435, 55004, 5173)) {
        if (Test-LocalPortOpen $Port) { throw "Prompt-24 port $Port remains after guarded recovery." }
    }
}

function Assert-ExactHandleTerminationImplementation {
    $Tokens = $null
    $Errors = $null
    $Ast = [Management.Automation.Language.Parser]::ParseFile(
        $Lifecycle,
        [ref]$Tokens,
        [ref]$Errors
    )
    if ($Errors.Count) { throw 'The lifecycle helper did not parse for exact-handle inspection.' }
    $StopFunction = $Ast.Find({
        param($Node)
        $Node -is [Management.Automation.Language.FunctionDefinitionAst] -and
        $Node.Name -ceq 'Stop-ProvenProcess'
    }, $true)
    if ($null -eq $StopFunction) { throw 'Stop-ProvenProcess was not found.' }
    $StopText = $StopFunction.Extent.Text
    if ($StopText -match '(?i)\bGet-Process\b') {
        throw 'Stop-ProvenProcess reacquires by PID; exact-handle termination regression detected.'
    }
    foreach ($Required in @('CafeFausseOwnershipProof', '.SafeHandle', '$Process.Kill()', '$Process.HasExited')) {
        if ($StopText.IndexOf($Required, [StringComparison]::Ordinal) -lt 0) {
            throw "Stop-ProvenProcess lacks required exact-handle behavior: $Required"
        }
    }
    Write-Output 'Exact-handle termination guard pass: Stop-ProvenProcess has no PID reacquisition and kills only its proven process object.'
}

$OriginalEnvironment = Save-EnvironmentProfile
$UnrelatedCaller = $null
$UnrelatedCallerHandle = $null
$UnrelatedCallerIdentity = $null
$SavedMarkerJson = $null
try {
    Assert-ExactHandleTerminationImplementation
    Write-Output 'CASE: successful Start/Status and StopFlask environment restoration'
    Invoke-LifecycleCase -Action Start
    Invoke-LifecycleCase -Action Status
    Invoke-LifecycleCase -Action StopFlask

    Write-Output 'CASE: launcher-only durable ownership and guarded recovery'
    $UnrelatedCaller = [Diagnostics.Process]::GetCurrentProcess()
    $UnrelatedCallerHandle = $UnrelatedCaller.SafeHandle
    if ($UnrelatedCallerHandle.IsInvalid -or $UnrelatedCallerHandle.IsClosed) {
        throw 'The unrelated caller process does not have a usable retained handle.'
    }
    $UnrelatedCallerIdentity = [pscustomobject]@{
        process_id = $UnrelatedCaller.Id
        start_time_utc = $UnrelatedCaller.StartTime.ToUniversalTime().ToString('O')
        executable_path = [IO.Path]::GetFullPath($UnrelatedCaller.Path)
        safe_handle = $UnrelatedCallerHandle.DangerousGetHandle().ToInt64()
    }
    Invoke-LifecycleCase -Action StartFlask -TestSeam FailAfterFlaskLauncherRecorded -ExpectFailure
    $Marker = Get-Content -LiteralPath $MarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $PartialFields = if ($Marker.flask) { @($Marker.flask.PSObject.Properties.Name) } else { @() }
    if (-not $Marker.flask -or $PartialFields -notcontains 'state' -or $PartialFields -notcontains 'readiness_proven') {
        throw "Controlled launcher-only failure lacked durable Flask fields: $($PartialFields -join ',')."
    }
    if ([string]$Marker.flask.state -cne 'launcher_recorded' -or [bool]$Marker.flask.readiness_proven -or
        @($PartialFields | Where-Object { $_ -like 'listener_*' }).Count -ne 0) {
        throw 'Controlled launcher-only failure did not preserve the exact partial Flask marker.'
    }
    Invoke-LifecycleCase -Action Cleanup
    Assert-NoOwnedEnvironment
    if ($UnrelatedCaller.HasExited -or
        $UnrelatedCaller.Id -ne $UnrelatedCallerIdentity.process_id -or
        $UnrelatedCaller.StartTime.ToUniversalTime().ToString('O') -cne $UnrelatedCallerIdentity.start_time_utc -or
        [IO.Path]::GetFullPath($UnrelatedCaller.Path) -ine $UnrelatedCallerIdentity.executable_path -or
        $UnrelatedCallerHandle.IsInvalid -or $UnrelatedCallerHandle.IsClosed -or
        $UnrelatedCallerHandle.DangerousGetHandle().ToInt64() -ne $UnrelatedCallerIdentity.safe_handle) {
        throw 'Guarded launcher-only recovery affected the unrelated caller process.'
    }

    Write-Output 'CASE: open Flask listener without accepted direct OP-07 readiness'
    Invoke-LifecycleCase -Action Start
    Invoke-LifecycleCase -Action StopFlask
    Invoke-LifecycleCase -Action StartFlask -TestSeam ForceDirectReadinessNotReady -ExpectFailure
    $Marker = Get-Content -LiteralPath $MarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$Marker.flask.state -cne 'listener_recorded' -or [bool]$Marker.flask.readiness_proven -or -not (Test-LocalPortOpen 55004)) {
        throw 'Direct non-ready seam did not retain a proven listener with readiness separate and false.'
    }
    Invoke-LifecycleCase -Action Cleanup
    Assert-NoOwnedEnvironment

    Write-Output 'CASE: open Vite listener without accepted proxied OP-07 readiness'
    Invoke-LifecycleCase -Action Start -TestSeam ForceProxyReadinessNotReady -ExpectFailure
    Assert-NoOwnedEnvironment

    Write-Output 'CASE: malformed and mismatched ownership refusal and fresh clean restart'
    Invoke-LifecycleCase -Action Start
    $SavedMarkerJson = Get-Content -LiteralPath $MarkerPath -Raw -Encoding UTF8
    $Mismatched = $SavedMarkerJson | ConvertFrom-Json
    $Mismatched.owner = 'NOT-PROMPT24-OWNED'
    [IO.File]::WriteAllText($MarkerPath, (($Mismatched | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    Invoke-LifecycleCase -Action Cleanup -ExpectFailure
    if (-not (Test-LocalPortOpen 55435) -or -not (Test-LocalPortOpen 55004) -or -not (Test-LocalPortOpen 5173)) {
        throw 'Mismatched ownership refusal stopped an owned resource before proof.'
    }

    $MismatchedLauncher = $SavedMarkerJson | ConvertFrom-Json
    $MismatchedLauncher.flask.launcher_start_time_utc = '2000-01-01T00:00:00.0000000Z'
    [IO.File]::WriteAllText($MarkerPath, (($MismatchedLauncher | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    Invoke-LifecycleCase -Action Cleanup -ExpectFailure
    if (-not (Test-LocalPortOpen 55435) -or -not (Test-LocalPortOpen 55004) -or -not (Test-LocalPortOpen 5173)) {
        throw 'Mismatched Flask launcher refusal stopped an owned resource before proof.'
    }

    $MismatchedListener = $SavedMarkerJson | ConvertFrom-Json
    $MismatchedListener.flask.listener_parent_process_id = -1
    [IO.File]::WriteAllText($MarkerPath, (($MismatchedListener | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
    Invoke-LifecycleCase -Action Cleanup -ExpectFailure
    if (-not (Test-LocalPortOpen 55435) -or -not (Test-LocalPortOpen 55004) -or -not (Test-LocalPortOpen 5173)) {
        throw 'Mismatched Flask listener refusal stopped an owned resource before proof.'
    }

    [IO.File]::WriteAllText($MarkerPath, '{malformed Prompt-24 ownership JSON', [Text.UTF8Encoding]::new($false))
    Invoke-LifecycleCase -Action Cleanup -ExpectFailure
    if (-not (Test-LocalPortOpen 55435) -or -not (Test-LocalPortOpen 55004) -or -not (Test-LocalPortOpen 5173)) {
        throw 'Malformed ownership refusal stopped an owned resource before proof.'
    }

    [IO.File]::WriteAllText($MarkerPath, $SavedMarkerJson, [Text.UTF8Encoding]::new($false))
    $SavedMarkerJson = $null
    Invoke-LifecycleCase -Action Cleanup
    Assert-NoOwnedEnvironment

    Write-Output 'PROMPT24 LIFECYCLE GUARD PASS'
    Write-Output 'Environment presence/value restoration passed for success, ordinary failure, partial recovery, readiness failure, refusal, and cleanup.'
    Write-Output 'Launcher-only recovery removed the owned launcher/root and preserved the unrelated PowerShell caller without creating a sentinel process.'
    Write-Output 'Direct and proxied listener-without-accepted-readiness seams produced no ready output.'
    Write-Output 'Malformed, owner-mismatched, launcher-mismatched, and listener-mismatched evidence was refused before any resource stop.'
}
finally {
    try {
        $CleanupFailure = $null
        if ($null -ne $SavedMarkerJson -and (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
            [IO.File]::WriteAllText($MarkerPath, $SavedMarkerJson, [Text.UTF8Encoding]::new($false))
        }
        if (Test-Path -LiteralPath $OwnedRoot) {
            try {
                & $Lifecycle -Action Cleanup -NonProductionClusterAuthorization $NonProductionClusterAuthorization
            }
            catch {
                $CleanupFailure = $_
                Write-Warning "Guarded lifecycle-test cleanup preserved unresolved evidence: $($_.Exception.Message)"
            }
        }
        if ($null -ne $CleanupFailure) { throw $CleanupFailure }
    }
    finally {
        Restore-EnvironmentProfile $OriginalEnvironment
    }
}
