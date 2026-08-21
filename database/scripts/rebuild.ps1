param(
    [switch]$SkipProvisioning,
    [ValidateSet(
        '004_foundation_privileges.sql',
        '009_reservation_privileges.sql',
        '010_default_function_privileges.sql',
        '011_allocator_exact_fast_paths.sql'
    )]
    [string]$ThroughMigration = '011_allocator_exact_fast_paths.sql'
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
    if ($migrationFile.Name -gt $ThroughMigration) {
        break
    }

    Write-Host "Applying $($migrationFile.Name)"
    Invoke-CafeFaussePsql -PsqlArguments @(
        '-v', 'ON_ERROR_STOP=1',
        '-f', $migrationFile.FullName
    ) | Out-Null

    if ($migrationFile.Name -eq '004_foundation_privileges.sql') {
        $db05VerificationFile = Join-Path $databaseRoot 'verification\verify_db05.sql'
        Invoke-CafeFaussePsql -PsqlArguments @(
            '-v', 'ON_ERROR_STOP=1',
            '-f', $db05VerificationFile
        ) | Out-Null
        Write-Host 'DB-05 checkpoint verification: PASS'
    }
}

if ($ThroughMigration -eq '004_foundation_privileges.sql') {
    Write-Host 'DB-05 clean rebuild and verification completed successfully.'
    return
}

$verificationFile = Join-Path $databaseRoot 'verification\verify_db06.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-f', $verificationFile
) | Out-Null

Write-Host 'DB-06 clean rebuild and verification completed successfully.'

if ($ThroughMigration -eq '009_reservation_privileges.sql') {
    return
}

$db07VerificationFile = Join-Path $databaseRoot 'verification\verify_db07.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-f', $db07VerificationFile
) | Out-Null

Write-Host 'DB-07 clean rebuild and verification completed successfully.'
