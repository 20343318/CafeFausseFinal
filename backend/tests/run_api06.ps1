[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$NonProductionClusterAuthorization,
    [switch]$InjectFailure,
    [switch]$InjectCleanupFailure,
    [ValidateSet('Prompt-15', 'API-07-contained')]
    [string]$OwnershipContext = 'Prompt-15',
    [string]$ExplicitOwnedRoot,
    [switch]$InterruptionHold,
    [string]$Api07OwnedRoot
)

$ErrorActionPreference = 'Stop'
$CafeRequiredAuthorization = 'AUTHORIZED_NONPRODUCTION'
if ($NonProductionClusterAuthorization -cne $CafeRequiredAuthorization) {
    throw 'API-06 requires explicit AUTHORIZED_NONPRODUCTION confirmation before destructive test setup.'
}
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
$CafePort = 55446
$CafeDatabase = 'cafe_fausse_test_api06'
$CafeAdminLogin = 'cafe_fausse_admin'
$CafeAppLogin = 'cafe_fausse_api06_login'
$CafeManagerLogin = 'cafe_fausse_api06_manager'
$CafeTemporaryBase = [System.IO.Path]::GetFullPath(
    [System.IO.Path]::GetTempPath()
).TrimEnd('\')
if ($OwnershipContext -ceq 'API-07-contained') {
    if ([string]::IsNullOrWhiteSpace($ExplicitOwnedRoot)) {
        throw 'The contained API-06 runner requires an explicit independently derived owned root.'
    }
    $CafeClusterRoot = [System.IO.Path]::GetFullPath($ExplicitOwnedRoot).TrimEnd('\')
    $CafeExpectedClusterRoot = [System.IO.Path]::GetFullPath(
        (Join-Path $CafeTemporaryBase 'CafeFausse-api07-contained-api06-tests')
    ).TrimEnd('\')
    $CafePhase = 'Prompt-16-contained-regression'
    $CafePurpose = 'contained API-06 regression and PostgreSQL verification for API-07'
    $CafeOwnerId = 'cafe-fausse-api07-contained-api06-20260823'
} else {
    if (-not [string]::IsNullOrWhiteSpace($ExplicitOwnedRoot)) {
        throw 'An explicit API-06 root is accepted only for the API-07-contained ownership context.'
    }
    $CafeClusterRoot = [System.IO.Path]::GetFullPath(
        (Join-Path $CafeTemporaryBase 'CafeFausse-api06-tests')
    ).TrimEnd('\')
    $CafeExpectedClusterRoot = $CafeClusterRoot
    $CafePhase = 'Prompt-15'
    $CafePurpose = 'newsletter preference verification'
    $CafeOwnerId = 'cafe-fausse-api06-prompt15-20260823'
}
if (-not $CafeClusterRoot.Equals(
    $CafeExpectedClusterRoot,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw "Refusing an unexpected API-06 owned root: $CafeClusterRoot"
}
if ($InterruptionHold) {
    if ($OwnershipContext -cne 'API-07-contained' -or
        [string]::IsNullOrWhiteSpace($Api07OwnedRoot)) {
        throw 'The interruption hold is valid only for an explicitly owned API-07-contained run.'
    }
    $CafeApi07Root = [System.IO.Path]::GetFullPath($Api07OwnedRoot).TrimEnd('\')
    $CafeExpectedApi07Root = [System.IO.Path]::GetFullPath(
        (Join-Path $CafeTemporaryBase 'CafeFausse-api07-tests')
    ).TrimEnd('\')
    if (-not $CafeApi07Root.Equals(
        $CafeExpectedApi07Root,
        [System.StringComparison]::OrdinalIgnoreCase
    ) -or
        -not [System.IO.Path]::GetDirectoryName($CafeApi07Root).Equals(
            [System.IO.Path]::GetDirectoryName($CafeClusterRoot),
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The API-07 and contained API-06 roots must be exact shallow siblings.'
    }
    $CafeApi07Marker = Join-Path $CafeApi07Root 'ownership.json'
    $CafeInterruptionReady = Join-Path $CafeApi07Root 'interruption-ready.json'
    $CafeInterruptionControl = Join-Path $CafeApi07Root 'interruption-control.json'
} elseif (-not [string]::IsNullOrWhiteSpace($Api07OwnedRoot)) {
    throw 'An API-07 owned root is accepted only for the interruption hold.'
}
$CafeDataDir = Join-Path $CafeClusterRoot 'data'
$CafeMarker = Join-Path $CafeClusterRoot 'ownership.json'
$CafeLog = Join-Path $CafeClusterRoot 'postgres.log'
$CafeVenv = Join-Path $CafeClusterRoot 'venv'
$CafeVenvPython = Join-Path $CafeVenv 'Scripts\python.exe'
$CafeCoverageRoot = Join-Path $CafeClusterRoot 'coverage'
$CafeCoverageFile = Join-Path $CafeCoverageRoot '.coverage'
$CafePipCache = Join-Path $CafeClusterRoot 'pip-cache'
$CafeProcessTemp = Join-Path $CafeClusterRoot 'process-temp'
$CafeResourceDefinitions = @(
    @{ Name = 'data'; Root = $CafeDataDir; Purpose = 'disposable PostgreSQL 18.3 data' },
    @{ Name = 'venv'; Root = $CafeVenv; Purpose = 'disposable Python virtual environment' },
    @{ Name = 'pip-cache'; Root = $CafePipCache; Purpose = 'disposable pip download cache' },
    @{ Name = 'coverage'; Root = $CafeCoverageRoot; Purpose = 'disposable coverage data' },
    @{ Name = 'process-temp'; Root = $CafeProcessTemp; Purpose = 'disposable child-process temporary files' }
)
$CafeEnvironmentNames = @(
    'CAFE_FAUSSE_ALLOW_RESET',
    'CAFE_FAUSSE_API06_INJECT_FAILURE',
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
    'PYTHONDONTWRITEBYTECODE',
    'PYTHONPYCACHEPREFIX',
    'PYTEST_ADDOPTS',
    'TEMP',
    'TMP',
    'TMPDIR'
)
$CafePriorEnvironment = @{}
foreach ($CafeName in $CafeEnvironmentNames) {
    $CafeItem = Get-Item -LiteralPath "Env:$CafeName" -ErrorAction SilentlyContinue
    $CafePriorEnvironment[$CafeName] = @{
        Present = $null -ne $CafeItem
        Value = if ($null -ne $CafeItem) { $CafeItem.Value } else { $null }
    }
}

function Restore-CafeFausseApi06Environment {
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
    Write-Host "API06 CLEANUP EVIDENCE: restored prior presence/values for $($CafeEnvironmentNames.Count) process environment variables without displaying values."
}

function Assert-CafeFausseApi06ClusterOwnership {
    if (-not $CafeClusterRoot.Equals(
        $CafeExpectedClusterRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing unexpected cluster root: $CafeClusterRoot"
    }
    if (-not (Test-Path -LiteralPath $CafeMarker -PathType Leaf)) {
        throw "Refusing cluster operation without the API-06 ownership marker: $CafeMarker"
    }
    $CafeRootItem = Get-Item -LiteralPath $CafeClusterRoot -Force -ErrorAction Stop
    $CafeMarkerItem = Get-Item -LiteralPath $CafeMarker -Force -ErrorAction Stop
    if (($CafeRootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($CafeMarkerItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing API-06 ownership through a reparse point.'
    }
    $CafeActualMarker = Get-Content -LiteralPath $CafeMarker -Raw -Encoding UTF8 |
        ConvertFrom-Json
    if ($CafeActualMarker.repository -cne $CafeRepo.TrimEnd('\') -or
        $CafeActualMarker.task -cne 'API-06' -or
        $CafeActualMarker.phase -cne $CafePhase -or
        $CafeActualMarker.purpose -cne $CafePurpose -or
        $CafeActualMarker.owner_id -cne $CafeOwnerId -or
        $CafeActualMarker.root -cne $CafeClusterRoot -or
        [int]$CafeActualMarker.port -ne $CafePort -or
        $CafeActualMarker.database -cne $CafeDatabase) {
        throw "Refusing cluster operation because its ownership marker does not match."
    }
}

function Get-CafeFausseApi06ResourceMarkerPath {
    param([Parameter(Mandatory = $true)][string]$Name)
    return Join-Path $CafeClusterRoot ".$Name.ownership.json"
}

function Write-CafeFausseApi06ResourceMarker {
    param([Parameter(Mandatory = $true)]$Definition)
    Assert-CafeFausseApi06ClusterOwnership
    $CafeResourceRoot = [System.IO.Path]::GetFullPath($Definition.Root).TrimEnd('\')
    $CafeClusterPrefix = $CafeClusterRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $CafeResourceRoot.StartsWith(
        $CafeClusterPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw 'Refusing an API-06 resource root outside the owned task root.'
    }
    $CafeResourceMarker = Get-CafeFausseApi06ResourceMarkerPath -Name $Definition.Name
    if (Test-Path -LiteralPath $CafeResourceMarker) {
        throw "Refusing to overwrite an API-06 resource marker: $CafeResourceMarker"
    }
    $CafeResourceEvidence = [ordered]@{
        repository = $CafeRepo.TrimEnd('\')
        task = 'API-06'
        phase = $CafePhase
        purpose = $Definition.Purpose
        owner_id = "$CafeOwnerId-$($Definition.Name)"
        root = $CafeResourceRoot
    }
    Write-CafeFausseDurableJson -Path $CafeResourceMarker -Value $CafeResourceEvidence
    Assert-CafeFausseApi06ResourceOwnership -Definition $Definition
}

function Assert-CafeFausseApi06ResourceOwnership {
    param([Parameter(Mandatory = $true)]$Definition)
    Assert-CafeFausseApi06ClusterOwnership
    $CafeResourceRoot = [System.IO.Path]::GetFullPath($Definition.Root).TrimEnd('\')
    $CafeClusterPrefix = $CafeClusterRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $CafeResourceRoot.StartsWith(
        $CafeClusterPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw 'Refusing an API-06 resource root outside the owned task root.'
    }
    $CafeResourceMarker = Get-CafeFausseApi06ResourceMarkerPath -Name $Definition.Name
    if (-not (Test-Path -LiteralPath $CafeResourceMarker -PathType Leaf)) {
        throw "Refusing an API-06 resource without its ownership marker: $CafeResourceRoot"
    }
    $CafeResourceMarkerItem = Get-Item -LiteralPath $CafeResourceMarker -Force -ErrorAction Stop
    if (($CafeResourceMarkerItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing an API-06 resource marker that is a reparse point.'
    }
    $CafeResourceEvidence = Get-Content -LiteralPath $CafeResourceMarker -Raw -Encoding UTF8 |
        ConvertFrom-Json
    if ($CafeResourceEvidence.repository -cne $CafeRepo.TrimEnd('\') -or
        $CafeResourceEvidence.task -cne 'API-06' -or
        $CafeResourceEvidence.phase -cne $CafePhase -or
        $CafeResourceEvidence.purpose -cne $Definition.Purpose -or
        $CafeResourceEvidence.owner_id -cne "$CafeOwnerId-$($Definition.Name)" -or
        $CafeResourceEvidence.root -cne $CafeResourceRoot) {
        throw 'Refusing an API-06 resource whose ownership marker does not match.'
    }
    if (Test-Path -LiteralPath $CafeResourceRoot) {
        $CafeResourceItem = Get-Item -LiteralPath $CafeResourceRoot -Force -ErrorAction Stop
        if (($CafeResourceItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'Refusing an API-06 resource root that is a reparse point.'
        }
    }
}

function Assert-CafeFausseApi06NoReparseDescendants {
    param([Parameter(Mandatory = $true)][string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return
    }
    $CafeResolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
    $CafePrefix = $CafeResolvedRoot + [System.IO.Path]::DirectorySeparatorChar
    $CafePending = New-Object 'System.Collections.Generic.Queue[string]'
    $CafePending.Enqueue($CafeResolvedRoot)
    while ($CafePending.Count -gt 0) {
        $CafeDirectory = $CafePending.Dequeue()
        foreach ($CafeEntry in [System.IO.Directory]::EnumerateFileSystemEntries($CafeDirectory)) {
            $CafeFullEntry = [System.IO.Path]::GetFullPath($CafeEntry)
            if (-not $CafeFullEntry.StartsWith(
                $CafePrefix,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                throw 'Refusing API-06 cleanup because a descendant escapes its owned root.'
            }
            $CafeAttributes = [System.IO.File]::GetAttributes($CafeFullEntry)
            if (($CafeAttributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Refusing API-06 cleanup because a descendant is a reparse point.'
            }
            if (($CafeAttributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
                $CafePending.Enqueue($CafeFullEntry)
            }
        }
    }
}

function Assert-CafeFausseApi07InterruptionOwnership {
    if (-not $InterruptionHold) {
        throw 'API-07 interruption ownership was requested outside interruption mode.'
    }
    if (-not (Test-Path -LiteralPath $CafeApi07Root -PathType Container) -or
        -not (Test-Path -LiteralPath $CafeApi07Marker -PathType Leaf)) {
        throw 'The API-07 interruption owner or marker is absent.'
    }
    $CafeApi07RootItem = Get-Item -LiteralPath $CafeApi07Root -Force -ErrorAction Stop
    $CafeApi07MarkerItem = Get-Item -LiteralPath $CafeApi07Marker -Force -ErrorAction Stop
    if (($CafeApi07RootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($CafeApi07MarkerItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing API-07 interruption ownership through a reparse point.'
    }
    $CafeApi07Evidence = Get-Content -LiteralPath $CafeApi07Marker -Raw -Encoding UTF8 |
        ConvertFrom-Json
    if ($CafeApi07Evidence.repository -cne $CafeRepo.TrimEnd('\') -or
        $CafeApi07Evidence.task -cne 'API-07' -or
        $CafeApi07Evidence.phase -cne 'Prompt-16' -or
        $CafeApi07Evidence.purpose -cne 'reservation context and availability verification' -or
        $CafeApi07Evidence.owner_id -cne 'cafe-fausse-api07-prompt16-20260823' -or
        $CafeApi07Evidence.root -cne $CafeApi07Root) {
        throw 'The API-07 interruption ownership marker does not match.'
    }
}

function Write-CafeFausseDurableJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )
    $CafeBytes = [System.Text.UTF8Encoding]::new($false).GetBytes(
        (($Value | ConvertTo-Json -Depth 6 -Compress) + "`n")
    )
    $CafeStream = New-Object System.IO.FileStream(
        $Path,
        [System.IO.FileMode]::CreateNew,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None,
        4096,
        [System.IO.FileOptions]::WriteThrough
    )
    try {
        $CafeStream.Write($CafeBytes, 0, $CafeBytes.Length)
        $CafeStream.Flush($true)
    }
    finally {
        $CafeStream.Dispose()
    }
}

function Wait-CafeFausseApi07InterruptionControl {
    Assert-CafeFausseApi07InterruptionOwnership
    $CafeReadyEvidence = [ordered]@{
        repository = $CafeRepo.TrimEnd('\')
        task = 'API-07'
        phase = 'Prompt-16-actual-interruption-recovery'
        purpose = 'contained API-06 runner readiness for owned interruption proof'
        owner_id = 'cafe-fausse-api07-interruption-ready-20260823'
        outer_root = $CafeApi07Root
        contained_root = $CafeClusterRoot
        pid = $PID
        port = $CafePort
    }
    Write-CafeFausseDurableJson -Path $CafeInterruptionReady -Value $CafeReadyEvidence
    $CafeReadyRoundTrip = Get-Content -LiteralPath $CafeInterruptionReady -Raw -Encoding UTF8 |
        ConvertFrom-Json
    if ($CafeReadyRoundTrip.repository -cne $CafeRepo.TrimEnd('\') -or
        $CafeReadyRoundTrip.owner_id -cne 'cafe-fausse-api07-interruption-ready-20260823' -or
        $CafeReadyRoundTrip.outer_root -cne $CafeApi07Root -or
        $CafeReadyRoundTrip.contained_root -cne $CafeClusterRoot -or
        [int]$CafeReadyRoundTrip.pid -ne $PID -or
        [int]$CafeReadyRoundTrip.port -ne $CafePort) {
        throw 'The durable API-07 interruption-ready evidence failed round-trip validation.'
    }
    while ($true) {
        if (Test-Path -LiteralPath $CafeInterruptionControl -PathType Leaf) {
            $CafeControlItem = Get-Item -LiteralPath $CafeInterruptionControl -Force -ErrorAction Stop
            if (($CafeControlItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Refusing an interruption control file that is a reparse point.'
            }
            $CafeControl = Get-Content -LiteralPath $CafeInterruptionControl -Raw -Encoding UTF8 |
                ConvertFrom-Json
            if ($CafeControl.repository -cne $CafeRepo.TrimEnd('\') -or
                $CafeControl.task -cne 'API-07' -or
                $CafeControl.phase -cne 'Prompt-16-actual-interruption-recovery' -or
                $CafeControl.purpose -cne 'abort contained runner before interruption ownership was completed' -or
                $CafeControl.owner_id -cne 'cafe-fausse-api07-interruption-abort-20260823' -or
                $CafeControl.outer_root -cne $CafeApi07Root -or
                $CafeControl.contained_root -cne $CafeClusterRoot -or
                [int]$CafeControl.pid -ne $PID -or
                $CafeControl.action -cne 'abort') {
                throw 'The API-07 interruption control does not match the held process.'
            }
            throw 'API-07 interruption preparation was aborted before ownership completion.'
        }
        Start-Sleep -Milliseconds 200
    }
}

function Stop-CafeFausseApi06Postgres {
    if (-not (Test-Path -LiteralPath (Join-Path $CafeDataDir 'PG_VERSION') -PathType Leaf)) {
        return
    }
    Assert-CafeFausseApi06ClusterOwnership
    $CafeStatus = & (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir status 2>&1
    $CafeStatusCode = $LASTEXITCODE
    $CafeStatusText = $CafeStatus -join [Environment]::NewLine
    if ($CafeStatusCode -eq 0 -and $CafeStatusText -match 'server is running') {
        & (Join-Path $CafePgBin 'pg_ctl.exe') -D $CafeDataDir -m fast -w stop
        if ($LASTEXITCODE -ne 0) {
            throw 'API-06 PostgreSQL shutdown failed.'
        }
    } elseif ($CafeStatusCode -ne 0 -and $CafeStatusText -notmatch 'no server running') {
        throw "Unrecognized API-06 PostgreSQL status: $CafeStatusText"
    }
}

function Remove-CafeFausseApi06Artifacts {
    Assert-CafeFausseApi06ClusterOwnership
    foreach ($CafeDefinition in @(
        $CafeResourceDefinitions | Where-Object { $_.Name -cne 'data' }
    )) {
        Assert-CafeFausseApi06ResourceOwnership -Definition $CafeDefinition
        if (Test-Path -LiteralPath $CafeDefinition.Root) {
            Assert-CafeFausseApi06NoReparseDescendants -Root $CafeDefinition.Root
            Remove-Item -LiteralPath $CafeDefinition.Root -Recurse -Force -ErrorAction Stop
            if (Test-Path -LiteralPath $CafeDefinition.Root) {
                throw "API-06 resource survived cleanup: $($CafeDefinition.Root)"
            }
        }
    }
}

function Remove-CafeFausseApi06ClusterRoot {
    if (-not (Test-Path -LiteralPath $CafeClusterRoot)) {
        return
    }
    Assert-CafeFausseApi06ClusterOwnership
    $CafeReady = & (Join-Path $CafePgBin 'pg_isready.exe') `
        -h 127.0.0.1 -p $CafePort -t 1 2>&1
    if ($LASTEXITCODE -eq 0) {
        throw "A PostgreSQL server remains available on the task-owned port: $($CafeReady -join ' ')"
    }
    foreach ($CafeDefinition in $CafeResourceDefinitions) {
        Assert-CafeFausseApi06ResourceOwnership -Definition $CafeDefinition
    }
    Assert-CafeFausseApi06NoReparseDescendants -Root $CafeClusterRoot
    Remove-Item -LiteralPath $CafeClusterRoot -Recurse -Force
    if (Test-Path -LiteralPath $CafeClusterRoot) {
        throw "Task-owned API-06 cluster directory survived cleanup: $CafeClusterRoot"
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
            throw "Required API-06 test program is missing: $CafeRequired"
        }
    }
    $CafeVersion = & (Join-Path $CafePgBin 'postgres.exe') --version
    if ($LASTEXITCODE -ne 0 -or $CafeVersion -notmatch '18\.3') {
        throw "API-06 tests require PostgreSQL 18.3; found: $CafeVersion"
    }
    $CafePythonVersion = & $CafePython -c "import sys; print('.'.join(map(str, sys.version_info[:3])))"
    if ($LASTEXITCODE -ne 0 -or $CafePythonVersion -ne '3.14.6') {
        throw "API-06 formal tests require CPython 3.14.6; found: $CafePythonVersion"
    }

    if (Test-Path -LiteralPath $CafeClusterRoot) {
        Assert-CafeFausseApi06ClusterOwnership
        Stop-CafeFausseApi06Postgres
        Remove-CafeFausseApi06Artifacts
        Remove-CafeFausseApi06ClusterRoot
    }
    $CafePortOwner = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -eq $CafePort }
    if ($CafePortOwner) {
        throw "Dedicated API-06 test port $CafePort is already occupied."
    }
    New-Item -ItemType Directory -Path $CafeClusterRoot | Out-Null
    $CafeClusterItem = Get-Item -LiteralPath $CafeClusterRoot -Force -ErrorAction Stop
    if (($CafeClusterItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'The newly created API-06 root is a reparse point.'
    }
    $CafeMarkerEvidence = [ordered]@{
        repository = $CafeRepo.TrimEnd('\')
        task = 'API-06'
        phase = $CafePhase
        purpose = $CafePurpose
        owner_id = $CafeOwnerId
        root = $CafeClusterRoot
        port = $CafePort
        database = $CafeDatabase
    }
    Write-CafeFausseDurableJson -Path $CafeMarker -Value $CafeMarkerEvidence
    Assert-CafeFausseApi06ClusterOwnership
    foreach ($CafeDefinition in $CafeResourceDefinitions) {
        Write-CafeFausseApi06ResourceMarker -Definition $CafeDefinition
    }
    & (Join-Path $CafePgBin 'initdb.exe') `
        -D $CafeDataDir `
        -U $CafeAdminLogin `
        --auth=trust `
        --encoding=UTF8 `
        --no-locale
    if ($LASTEXITCODE -ne 0) {
        throw 'API-06 disposable-cluster initialization failed.'
    }
    & (Join-Path $CafePgBin 'pg_ctl.exe') `
        -D $CafeDataDir `
        -l $CafeLog `
        -o "-p $CafePort -h 127.0.0.1" `
        -w start
    if ($LASTEXITCODE -ne 0) {
        throw 'API-06 disposable PostgreSQL startup failed.'
    }

    & (Join-Path $CafePgBin 'createdb.exe') `
        -h 127.0.0.1 -p $CafePort -U $CafeAdminLogin $CafeDatabase
    if ($LASTEXITCODE -ne 0) {
        throw 'API-06 test-database creation failed.'
    }
    if ($InterruptionHold) {
        Wait-CafeFausseApi07InterruptionControl
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
    New-Item -ItemType Directory -Path $CafeCoverageRoot -ErrorAction Stop | Out-Null
    New-Item -ItemType Directory -Path $CafeProcessTemp -ErrorAction Stop | Out-Null
    $env:COVERAGE_FILE = $CafeCoverageFile
    $env:PIP_CACHE_DIR = $CafePipCache
    $env:PYTHONPATH = Join-Path $CafeBackend 'src'
    $env:PYTHONDONTWRITEBYTECODE = '1'
    Remove-Item Env:PYTHONPYCACHEPREFIX -ErrorAction SilentlyContinue
    $env:PYTEST_ADDOPTS = '-p no:cacheprovider'
    $env:TEMP = $CafeClusterRoot
    $env:TMP = $CafeProcessTemp
    $env:TMPDIR = $CafeProcessTemp

    Set-Location $CafeRepo
    & '.\database\scripts\rebuild.ps1'
    if ($LASTEXITCODE -ne 0) {
        throw 'API-06 database rebuild failed.'
    }
    & '.\database\scripts\verify.ps1'
    if ($LASTEXITCODE -ne 0) {
        throw 'API-06 database verification failed.'
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
        throw 'API-06 test-login creation failed.'
    }

    & $CafePython -m venv --without-pip $CafeVenv
    if ($LASTEXITCODE -ne 0) {
        throw 'API-06 virtual-environment creation failed.'
    }
    & $CafePython -m pip --python $CafeVenvPython install `
        --disable-pip-version-check --quiet --no-compile `
        --cache-dir $CafePipCache `
        'Flask==3.1.3' `
        'psycopg[binary]==3.2.13' `
        'psycopg-pool==3.2.8' `
        'pytest==9.1.1' `
        'pytest-cov==7.1.0'
    if ($LASTEXITCODE -ne 0) {
        throw 'API-06 dependency installation failed.'
    }

    $env:PGUSER = $CafeAppLogin
    $env:CAFE_FAUSSE_TEST_MANAGER_USER = $CafeManagerLogin
    $env:CAFE_FAUSSE_TEST_MANAGER_PASSWORD = 'local-trust-placeholder'
    $env:CAFE_FAUSSE_TEST_PGDATA = $CafeDataDir
    if ($InjectFailure) {
        $env:CAFE_FAUSSE_API06_INJECT_FAILURE = 'YES'
    } else {
        Remove-Item Env:CAFE_FAUSSE_API06_INJECT_FAILURE -ErrorAction SilentlyContinue
    }

    Set-Location $CafeBackend
    & $CafeVenvPython -m pytest `
        'tests\unit\test_newsletter_gateway.py' `
        'tests\unit\test_newsletter_preference_service.py' `
        'tests\unit\test_logging_and_lifecycle.py' `
        'tests\api\test_newsletter_preferences.py'
    if ($LASTEXITCODE -ne 0) {
        $CafeTestExitCode = $LASTEXITCODE
        throw "API-06 focused certainty/logging suite failed with exit code $CafeTestExitCode"
    }
    Write-Host 'API06 FOCUSED PASS: gateway, service, error-handler, and safe-logging tests passed.'
    & $CafeVenvPython -m pytest -m 'unit or api'
    if ($LASTEXITCODE -ne 0) {
        $CafeTestExitCode = $LASTEXITCODE
        throw "API-06 unit/API suite failed with exit code $CafeTestExitCode"
    }
    & $CafeVenvPython -m pytest -m 'integration and postgres'
    if ($LASTEXITCODE -ne 0) {
        $CafeTestExitCode = $LASTEXITCODE
        throw "API-06 PostgreSQL integration suite failed with exit code $CafeTestExitCode"
    }
    & $CafeVenvPython -m pytest `
        -m 'unit or api or (integration and postgres)' `
        --cov=cafe_fausse --cov-report=term-missing
    if ($LASTEXITCODE -ne 0) {
        $CafeTestExitCode = $LASTEXITCODE
        throw "API-06 complete coverage suite failed with exit code $CafeTestExitCode"
    }

    $CafeCounts = & (Join-Path $CafePgBin 'psql.exe') `
        -X -qAt -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p $CafePort -U $CafeManagerLogin -d $CafeDatabase `
        -c "SET ROLE cafe_fausse_test; SELECT concat_ws('|',(SELECT count(*) FROM cafe_fausse.customers),(SELECT count(*) FROM cafe_fausse.reservations),(SELECT count(*) FROM cafe_fausse.reservation_table_assignments));"
    if ($LASTEXITCODE -ne 0 -or ($CafeCounts -join '').Trim() -ne '0|0|0') {
        $CafeTestExitCode = 1
        throw "API-06 test rows survived the suite: $($CafeCounts -join ' ')"
    }
    Write-Host 'API06 TEST PASS: unit/API, PostgreSQL integration, complete coverage, and zero-row evidence all passed.'
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
            Stop-CafeFausseApi06Postgres
        }
    }
    catch {
        $CafeCleanupErrors += "PostgreSQL/process cleanup: $($_.Exception.Message)"
    }
    try {
        if ($InjectCleanupFailure) {
            throw 'controlled API-06 generated-artifact cleanup failure'
        }
        Remove-CafeFausseApi06Artifacts
    }
    catch {
        $CafeCleanupErrors += "generated-artifact cleanup: $($_.Exception.Message)"
    }
    try {
        Remove-CafeFausseApi06ClusterRoot
    }
    catch {
        $CafeCleanupErrors += "cluster-directory cleanup: $($_.Exception.Message)"
    }
    try {
        Restore-CafeFausseApi06Environment
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
        Write-Host "API06 CLEANUP EVIDENCE: task-owned cluster directory is absent: $CafeClusterRoot"
    }
    catch {
        $CafeCleanupErrors += "cleanup postcondition: $($_.Exception.Message)"
    }
    if ($CafeCleanupErrors.Count -eq 0) {
        Write-Host 'API06 CLEANUP PASS: cluster, database, roles, rows, generated files, child server, and environment changes removed.'
    } else {
        $CafeCleanupExitCode = 1
    }
}

if ($null -ne $CafePrimaryFailure) {
    [Console]::Error.WriteLine("API-06 TEST FAILURE: $CafePrimaryFailure")
}
foreach ($CafeCleanupError in $CafeCleanupErrors) {
    [Console]::Error.WriteLine("API-06 CLEANUP FAILURE: $CafeCleanupError")
}
if ($CafeTestExitCode -ne 0 -or $CafeCleanupExitCode -ne 0) {
    exit 1
}
exit 0
