Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Common.ps1')

Assert-CafeFausseConnectionEnvironment

$databaseRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$verificationFile = Join-Path $databaseRoot 'verification\verify_db06.sql'

Invoke-CafeFaussePsql -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-f', $verificationFile
) | Out-Null

Write-Host 'DB-06 verification completed successfully.'
