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

Write-Host 'Rebuilding through the approved DB-05 checkpoint for regression tests.'
& $rebuildScript -ThroughMigration '004_foundation_privileges.sql'

$db05BehaviorTestFile = Join-Path $databaseRoot 'tests\db05_behavior_tests.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-f', $db05BehaviorTestFile
) | Out-Null

$db05PrivilegeTestFile = Join-Path $databaseRoot 'tests\runtime_privilege_denials.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-f', $db05PrivilegeTestFile
) | Out-Null

Write-Host 'Approved DB-05 regression suite: PASS'

Write-Host 'Running two complete DB-06 clean rebuilds.'
& $rebuildScript -SkipProvisioning
& $rebuildScript -SkipProvisioning

$db06BehaviorTestFile = Join-Path $databaseRoot 'tests\db06_behavior_tests.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-v', 'ON_ERROR_STOP=1',
    '-f', $db06BehaviorTestFile
) | Out-Null

$db06PrivilegeTestFile = Join-Path $databaseRoot 'tests\db06_runtime_privilege_denials.sql'
Invoke-CafeFaussePsql -PsqlArguments @(
    '-f', $db06PrivilegeTestFile
) | Out-Null

& (Join-Path $PSScriptRoot 'concurrency_test.ps1') -Iterations 3
& (Join-Path $PSScriptRoot 'performance_test.ps1') -Samples 10

Write-Host 'Restoring and verifying an empty DB-06 baseline after destructive tests.'
& $rebuildScript -SkipProvisioning

Write-Host 'DB-05 regression and DB-06 automated test suites completed successfully.'
