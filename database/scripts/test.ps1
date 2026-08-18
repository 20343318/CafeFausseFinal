Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Common.ps1')

Assert-CafeFausseResetGuard

$databaseRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rebuildScript = Join-Path $PSScriptRoot 'rebuild.ps1'

Write-Host 'Checking that the reset guard refuses an invalid authorization value.'
$savedResetAuthorization = $env:CAFE_FAUSSE_ALLOW_RESET
$env:CAFE_FAUSSE_ALLOW_RESET = 'NO'
try {
    & $rebuildScript -SkipProvisioning *> $null
    if ($LASTEXITCODE -eq 0) {
        throw 'Reset guard test failed: rebuild unexpectedly succeeded.'
    }
}
catch {
    Write-Host 'Reset guard refusal: PASS'
}
finally {
    $env:CAFE_FAUSSE_ALLOW_RESET = $savedResetAuthorization
}

Write-Host 'Checking that psql reports migration errors with a nonzero exit code.'
$failureExitCode = Invoke-CafeFaussePsql -AllowFailure -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-c', 'SELECT 1 / 0;'
)
if ($failureExitCode -eq 0) {
    throw 'Fail-visible test failed: an intentional SQL error returned success.'
}
Write-Host 'Fail-visible psql behavior: PASS'

Write-Host 'Running two complete clean rebuilds.'
& $rebuildScript
& $rebuildScript -SkipProvisioning

$behaviorTestFile = Join-Path $databaseRoot 'tests\db05_behavior_tests.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-f', $behaviorTestFile
) | Out-Null

$privilegeTestFile = Join-Path $databaseRoot 'tests\runtime_privilege_denials.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-f', $privilegeTestFile
) | Out-Null

Write-Host 'DB-05 automated test suite completed successfully.'
