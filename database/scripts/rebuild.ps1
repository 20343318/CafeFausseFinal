param(
    [switch]$SkipProvisioning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Common.ps1')

Assert-CafeFausseResetGuard

$databaseRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if (-not $SkipProvisioning) {
    $provisioningFile = Join-Path $databaseRoot 'provisioning\001_foundation_roles.sql'
    Invoke-CafeFaussePsql -PsqlArguments @(
        '-v', 'ON_ERROR_STOP=1',
        '-f', $provisioningFile
    ) | Out-Null
}

$resetFile = Join-Path $databaseRoot 'reset\001_drop_foundation_schema.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-v', "cafe_fausse_environment=$env:CAFE_FAUSSE_ENVIRONMENT",
    '-v', "cafe_fausse_allow_reset=$env:CAFE_FAUSSE_ALLOW_RESET",
    '-f', $resetFile
) | Out-Null

$migrationFiles = Get-ChildItem -LiteralPath (Join-Path $databaseRoot 'migrations') -Filter '*.sql' |
    Sort-Object -Property Name

foreach ($migrationFile in $migrationFiles) {
    Write-Host "Applying $($migrationFile.Name)"
    Invoke-CafeFaussePsql -PsqlArguments @(
        '-v', 'ON_ERROR_STOP=1',
        '-f', $migrationFile.FullName
    ) | Out-Null
}

$verificationFile = Join-Path $databaseRoot 'verification\verify_db05.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-f', $verificationFile
) | Out-Null

Write-Host 'DB-05 clean rebuild and verification completed successfully.'
