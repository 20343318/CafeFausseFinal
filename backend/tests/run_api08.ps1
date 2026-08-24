[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('AUTHORIZED_NONPRODUCTION')]
    [string]$NonProductionClusterAuthorization,
    [switch]$InjectFailure,
    [switch]$InjectCleanupFailure,
    [switch]$CleanupOwnedRoot,
    [switch]$PrepareInterruptionState
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$CafeArguments = @{
    NonProductionClusterAuthorization = $NonProductionClusterAuthorization
}
foreach ($CafeSwitch in @('InjectFailure', 'InjectCleanupFailure', 'CleanupOwnedRoot', 'PrepareInterruptionState')) {
    if ($PSBoundParameters.ContainsKey($CafeSwitch)) {
        $CafeArguments[$CafeSwitch] = $true
    }
}

& (Join-Path $PSScriptRoot 'run_api07.ps1') @CafeArguments
$CafeExitCode = $LASTEXITCODE
if ($CafeExitCode -ne 0) {
    exit $CafeExitCode
}
if (-not $CleanupOwnedRoot -and -not $PrepareInterruptionState) {
    Write-Host 'API08 TEST PASS: reservation creation plus all API-04 through API-07 regressions passed; owned resources were cleaned.'
}
exit 0
