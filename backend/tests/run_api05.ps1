[CmdletBinding()]
param(
    [switch]$InjectFailure,
    [switch]$InjectCleanupFailure
)

$ErrorActionPreference = 'Stop'
$CafeScriptPath = [System.IO.Path]::GetFullPath($MyInvocation.MyCommand.Path)
$CafeRepo = [System.IO.Path]::GetFullPath(
    (Join-Path (Split-Path -Parent $CafeScriptPath) '..\..')
)
$CafeBackend = [System.IO.Path]::GetFullPath((Join-Path $CafeRepo 'backend'))
$CafeExpectedBackend = [System.IO.Path]::GetFullPath((Join-Path $CafeRepo 'backend'))
if (-not $CafeBackend.Equals($CafeExpectedBackend, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing an unexpected backend root: $CafeBackend"
}

$CafePython = 'C:\Python314\python.exe'
$CafePgBin = 'C:\Program Files\PostgreSQL\18\bin'
$CafePort = 55445
$CafeDatabase = 'cafe_fausse_test_api05'
$CafeAdminLogin = 'cafe_fausse_admin'
$CafeAppLogin = 'cafe_fausse_api05_login'
$CafeManagerLogin = 'cafe_fausse_api05_manager'
$CafeClusterRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $env:TEMP 'CafeFausse-api05-tests')
)
$CafeExpectedClusterRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $env:TEMP 'CafeFausse-api05-tests')
)
$CafeDataDir = Join-Path $CafeClusterRoot 'data'
$CafeMarker = Join-Path $CafeClusterRoot '.cafe-fausse-api05-test-cluster'
$CafeLog = Join-Path $CafeClusterRoot 'postgres.log'
$CafeArtifactRoot = Join-Path $CafeClusterRoot 'artifacts'
$CafeVenv = Join-Path $CafeArtifactRoot 'venv'
$CafeVenvPython = Join-Path $CafeVenv 'Scripts\python.exe'
$CafePytestCache = Join-Path $CafeArtifactRoot 'pytest-cache'
$CafeCoverageFile = Join-Path $CafeArtifactRoot '.coverage'
$CafePythonCache = Join-Path $CafeArtifactRoot 'pycache'
$CafePipCache = Join-Path $CafeArtifactRoot 'pip-cache'
$CafeMarkerText = "CafeFausse API-05 disposable test cluster|port=$CafePort|database=$CafeDatabase"
$CafeEnvironmentNames = @(
    'CAFE_FAUSSE_ALLOW_RESET',
    'CAFE_FAUSSE_API05_INJECT_FAILURE',
    'CAFE_FAUSSE_ENVIRONMENT',
    'CAFE_FAUSSE_PSQL',
    'CAFE_FAUSSE_TEST_MANAGER_PASSWORD',
    'CAFE_FAUSSE_TEST_MANAGER_USER',
    'CAFE_FAUSSE_TEST_PGDATA',
    'COVERAGE_FILE',
    'PIP_CACHE_DIR',
    'PGDATABASE',
    'PGHOST',
    'PGOPTIONS',
    'PGPASSFILE',
    'PGPASSWORD',
    'PGPORT',
    'PGSSLMODE',
    'PGUSER',
    'PYTHONPATH',
    'PYTHONPYCACHEPREFIX'
)
$CafePriorEnvironment = @{}
foreach ($CafeName in $CafeEnvironmentNames) {
    $CafeItem = Get-Item -LiteralPath "Env:$CafeName" -ErrorAction SilentlyContinue
    $CafePriorEnvironment[$CafeName] = @{
        Present = $null -ne $CafeItem
        Value = if ($null -ne $CafeItem) { $CafeItem.Value } else { $null }
    }
}

function Restore-CafeFausseApi05Environment {
    $CafeRestoreFailures = @()
    foreach ($CafeName in $CafeEnvironmentNames) {
        try {
            $CafePrior = $CafePriorEnvironment[$CafeName]
            if ($CafePrior.Present) {
                Set-Item -LiteralPath "Env:$CafeName" -Value $CafePrior.Value
            } else {
                Remove-Item -LiteralPath "Env:$CafeName" -ErrorAction SilentlyContinue
            }
            $CafeRestored = Get-Item -LiteralPath "Env:$CafeName" -ErrorAction SilentlyContinue
            if (($null -ne $CafeRestored) -ne $CafePrior.Present) {
                throw "presence differs"
            }
            if ($CafePrior.Present -and $CafeRestored.Value -cne $CafePrior.Value) {
                throw "value differs"
            }
        }
        catch {
            $CafeRestoreFailures += "$CafeName restoration failed"
        }
    }
    if ($CafeRestoreFailures.Count -ne 0) {
        throw ($CafeRestoreFailures -join '; ')
    }
    Write-Host "API05 CLEANUP EVIDENCE: restored prior presence/values for $($CafeEnvironmentNames.Count) process environment variables without displaying values."
}

function Assert-CafeFausseApi05ClusterOwnership {
    if (-not $CafeClusterRoot.Equals(
        $CafeExpectedClusterRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing unexpected cluster root: $CafeClusterRoot"
    }
    if (-not (Test-Path -LiteralPath $CafeMarker -PathType Leaf)) {
        throw "Refusing cluster operation without the API-05 ownership marker: $CafeMarker"
    }
    $CafeActualMarker = (Get-Content -LiteralPath $CafeMarker -Raw).Trim()
    if ($CafeActualMarker -ne $CafeMarkerText) {
        throw "Refusing cluster operation because its ownership marker does not match."
    }
}

function Stop-CafeFausseApi05Postgres {
    if (-not (Test-Path -LiteralPath (Join-Path $CafeDataDir 'PG_VERSION') -PathType Leaf)) {
        return
    }
    Assert-CafeFausseApi05ClusterOwnership
    $CafeStatus = & (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir status 2>&1
    $CafeStatusCode = $LASTEXITCODE
    $CafeStatusText = $CafeStatus -join [Environment]::NewLine
    if ($CafeStatusCode -eq 0 -and $CafeStatusText -match 'server is running') {
        & (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir -m fast -w stop
        if ($LASTEXITCODE -ne 0) {
            throw 'API-05 PostgreSQL shutdown failed.'
        }
    } elseif ($CafeStatusCode -ne 0 -and $CafeStatusText -notmatch 'no server running') {
        throw "Unrecognized API-05 PostgreSQL status: $CafeStatusText"
    }
}

function Remove-CafeFausseApi05Artifacts {
    if (-not (Test-Path -LiteralPath $CafeArtifactRoot)) {
        return
    }
    Assert-CafeFausseApi05ClusterOwnership
    $CafeResolvedArtifacts = [System.IO.Path]::GetFullPath($CafeArtifactRoot)
    $CafeExpectedArtifacts = [System.IO.Path]::GetFullPath(
        (Join-Path $CafeExpectedClusterRoot 'artifacts')
    )
    if (-not $CafeResolvedArtifacts.Equals(
        $CafeExpectedArtifacts,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing unexpected artifact cleanup path: $CafeResolvedArtifacts"
    }
    Remove-Item -LiteralPath $CafeResolvedArtifacts -Recurse -Force
}

function Remove-CafeFausseApi05ClusterRoot {
    if (-not (Test-Path -LiteralPath $CafeClusterRoot)) {
        return
    }
    Assert-CafeFausseApi05ClusterOwnership
    $CafeReady = & (Join-Path $CafePgBin 'pg_isready.exe') `
        -h 127.0.0.1 -p $CafePort -t 1 2>&1
    if ($LASTEXITCODE -eq 0) {
        throw "A PostgreSQL server remains available on the task-owned port: $($CafeReady -join ' ')"
    }
    Remove-Item -LiteralPath $CafeClusterRoot -Recurse -Force
    if (Test-Path -LiteralPath $CafeClusterRoot) {
        throw "Task-owned API-05 cluster directory survived cleanup: $CafeClusterRoot"
    }
}

$CafeTestExitCode = 0
$CafeCleanupExitCode = 0
$CafePrimaryFailure = $null
$CafeCleanupErrors = @()
$CafeOriginalLocation = Get-Location
try {
    foreach ($CafeRequired in @(
        $CafePython,
        (Join-Path $CafePgBin 'initdb.exe'),
        (Join-Path $CafePgBin 'pg_ctl.exe'),
        (Join-Path $CafePgBin 'psql.exe')
    )) {
        if (-not (Test-Path -LiteralPath $CafeRequired -PathType Leaf)) {
            throw "Required API-05 test program is missing: $CafeRequired"
        }
    }
    $CafeVersion = & (Join-Path $CafePgBin 'postgres.exe') --version
    if ($LASTEXITCODE -ne 0 -or $CafeVersion -notmatch '18\.3') {
        throw "API-05 tests require PostgreSQL 18.3; found: $CafeVersion"
    }
    $CafePythonVersion = & $CafePython -c "import sys; print('.'.join(map(str, sys.version_info[:3])))"
    if ($LASTEXITCODE -ne 0 -or $CafePythonVersion -ne '3.14.6') {
        throw "API-05 formal tests require CPython 3.14.6; found: $CafePythonVersion"
    }

    if (Test-Path -LiteralPath $CafeClusterRoot) {
        Assert-CafeFausseApi05ClusterOwnership
        Stop-CafeFausseApi05Postgres
        Remove-CafeFausseApi05Artifacts
        Remove-CafeFausseApi05ClusterRoot
    }
    $CafePortOwner = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -eq $CafePort }
    if ($CafePortOwner) {
        throw "Dedicated API-05 test port $CafePort is already occupied."
    }
    New-Item -ItemType Directory -Path $CafeClusterRoot | Out-Null
    [System.IO.File]::WriteAllText(
        $CafeMarker,
        $CafeMarkerText,
        [System.Text.UTF8Encoding]::new($false)
    )
    Assert-CafeFausseApi05ClusterOwnership
    & (Join-Path $CafePgBin 'initdb.exe') `
        -D $CafeDataDir `
        -U $CafeAdminLogin `
        --auth=trust `
        --encoding=UTF8 `
        --no-locale
    if ($LASTEXITCODE -ne 0) {
        throw 'API-05 disposable-cluster initialization failed.'
    }
    & (Join-Path $CafePgBin 'pg_ctl.exe') `
        -D $CafeDataDir `
        -l $CafeLog `
        -o "-p $CafePort -h 127.0.0.1" `
        -w start
    if ($LASTEXITCODE -ne 0) {
        throw 'API-05 disposable PostgreSQL startup failed.'
    }

    & (Join-Path $CafePgBin 'createdb.exe') `
        -h 127.0.0.1 -p $CafePort -U $CafeAdminLogin $CafeDatabase
    if ($LASTEXITCODE -ne 0) {
        throw 'API-05 test-database creation failed.'
    }

    $env:CAFE_FAUSSE_ENVIRONMENT = 'test'
    $env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
    $env:CAFE_FAUSSE_PSQL = Join-Path $CafePgBin 'psql.exe'
    $env:PGHOST = '127.0.0.1'
    $env:PGPORT = [string]$CafePort
    $env:PGDATABASE = $CafeDatabase
    $env:PGUSER = $CafeAdminLogin
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
    Remove-Item Env:PGSSLMODE -ErrorAction SilentlyContinue
    $env:COVERAGE_FILE = $CafeCoverageFile
    $env:PIP_CACHE_DIR = $CafePipCache
    $env:PYTHONPATH = Join-Path $CafeBackend 'src'
    $env:PYTHONPYCACHEPREFIX = $CafePythonCache

    Set-Location $CafeRepo
    & '.\database\scripts\rebuild.ps1'
    if ($LASTEXITCODE -ne 0) {
        throw 'API-05 database rebuild failed.'
    }
    & '.\database\scripts\verify.ps1'
    if ($LASTEXITCODE -ne 0) {
        throw 'API-05 database verification failed.'
    }

    $CafeLoginSql = @"
CREATE ROLE $CafeAppLogin LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE ROLE $CafeManagerLogin LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
GRANT cafe_fausse_app TO $CafeAppLogin;
GRANT cafe_fausse_test TO $CafeManagerLogin;
GRANT CONNECT ON DATABASE $CafeDatabase TO $CafeAppLogin, $CafeManagerLogin;
"@
    $CafeLoginSql | & (Join-Path $CafePgBin 'psql.exe') `
        -X -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p $CafePort -U $CafeAdminLogin -d $CafeDatabase
    if ($LASTEXITCODE -ne 0) {
        throw 'API-05 test-login creation failed.'
    }

    New-Item -ItemType Directory -Path $CafeArtifactRoot -Force | Out-Null
    & $CafePython -m venv $CafeVenv
    if ($LASTEXITCODE -ne 0) {
        throw 'API-05 virtual-environment creation failed.'
    }
    & $CafeVenvPython -m pip install `
        --disable-pip-version-check --quiet `
        --cache-dir $CafePipCache `
        'Flask==3.1.3' `
        'psycopg[binary]==3.2.13' `
        'psycopg-pool==3.2.8' `
        'pytest==9.1.1' `
        'pytest-cov==7.1.0'
    if ($LASTEXITCODE -ne 0) {
        throw 'API-05 dependency installation failed.'
    }

    $env:PGUSER = $CafeAppLogin
    $env:CAFE_FAUSSE_TEST_MANAGER_USER = $CafeManagerLogin
    $env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD = 'local-trust-placeholder'
    $env:CAFE_FAUSSE_TEST_PGDATA = $CafeDataDir
    if ($InjectFailure) {
        $env:CAFE_FAUSSE_API05_INJECT_FAILURE = 'YES'
    } else {
        Remove-Item Env:CAFE_FAUSSE_API05_INJECT_FAILURE -ErrorAction SilentlyContinue
    }

    Set-Location $CafeBackend
    & $CafeVenvPython -m pytest -o "cache_dir=$CafePytestCache" -m 'unit or api'
    if ($LASTEXITCODE -ne 0) {
        $CafeTestExitCode = $LASTEXITCODE
        throw "API-05 unit/API suite failed with exit code $CafeTestExitCode"
    }
    & $CafeVenvPython -m pytest -o "cache_dir=$CafePytestCache" -m 'integration and postgres'
    if ($LASTEXITCODE -ne 0) {
        $CafeTestExitCode = $LASTEXITCODE
        throw "API-05 PostgreSQL integration suite failed with exit code $CafeTestExitCode"
    }
    & $CafeVenvPython -m pytest -o "cache_dir=$CafePytestCache" `
        -m 'unit or api or (integration and postgres)' `
        --cov=cafe_fausse --cov-report=term-missing
    if ($LASTEXITCODE -ne 0) {
        $CafeTestExitCode = $LASTEXITCODE
        throw "API-05 complete coverage suite failed with exit code $CafeTestExitCode"
    }

    $CafeCounts = & (Join-Path $CafePgBin 'psql.exe') `
        -X -qAt -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p $CafePort -U $CafeManagerLogin -d $CafeDatabase `
        -c "SET ROLE cafe_fausse_test; SELECT concat_ws('|',(SELECT count(*) FROM cafe_fausse.customers),(SELECT count(*) FROM cafe_fausse.reservations),(SELECT count(*) FROM cafe_fausse.reservation_table_assignments));"
    if ($LASTEXITCODE -ne 0 -or ($CafeCounts -join '').Trim() -ne '0|0|0') {
        $CafeTestExitCode = 1
        throw "API-05 test rows survived the suite: $($CafeCounts -join ' ')"
    }
    Write-Host 'API05 TEST PASS: unit/API, PostgreSQL integration, complete coverage, and zero-row evidence all passed.'
}
catch {
    if ($CafeTestExitCode -eq 0) {
        $CafeTestExitCode = 1
    }
    $CafePrimaryFailure = $_.Exception.Message
}
finally {
    try {
        Set-Location $CafeOriginalLocation
    }
    catch {
        $CafeCleanupErrors += "working-directory restoration: $($_.Exception.Message)"
    }
    try {
        if (Test-Path -LiteralPath $CafeClusterRoot) {
            Stop-CafeFausseApi05Postgres
        }
    }
    catch {
        $CafeCleanupErrors += "PostgreSQL/process cleanup: $($_.Exception.Message)"
    }
    try {
        if ($InjectCleanupFailure) {
            throw 'controlled API-05 generated-artifact cleanup failure'
        }
        Remove-CafeFausseApi05Artifacts
    }
    catch {
        $CafeCleanupErrors += "generated-artifact cleanup: $($_.Exception.Message)"
    }
    try {
        Remove-CafeFausseApi05ClusterRoot
    }
    catch {
        $CafeCleanupErrors += "cluster-directory cleanup: $($_.Exception.Message)"
    }
    try {
        Restore-CafeFausseApi05Environment
    }
    catch {
        $CafeCleanupErrors += "environment restoration: $($_.Exception.Message)"
    }
    try {
        if (Test-Path -LiteralPath $CafeClusterRoot) {
            throw "task-owned cluster root remains: $CafeClusterRoot"
        }
        $CafeListener = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            Where-Object { $_.LocalPort -eq $CafePort }
        if ($CafeListener) {
            throw "a listener remains on task-owned port $CafePort"
        }
        Write-Host "API05 CLEANUP EVIDENCE: task-owned cluster directory is absent: $CafeClusterRoot"
    }
    catch {
        $CafeCleanupErrors += "cleanup postcondition: $($_.Exception.Message)"
    }
    if ($CafeCleanupErrors.Count -eq 0) {
        Write-Host 'API05 CLEANUP PASS: cluster, database, roles, rows, generated files, child server, and environment changes removed.'
    } else {
        $CafeCleanupExitCode = 1
    }
}

if ($null -ne $CafePrimaryFailure) {
    [Console]::Error.WriteLine("API-05 TEST FAILURE: $CafePrimaryFailure")
}
foreach ($CafeCleanupError in $CafeCleanupErrors) {
    [Console]::Error.WriteLine("API-05 CLEANUP FAILURE: $CafeCleanupError")
}
if ($CafeTestExitCode -ne 0 -or $CafeCleanupExitCode -ne 0) {
    exit 1
}
exit 0
