[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('AUTHORIZED_NONPRODUCTION')]
    [string]$NonProductionClusterAuthorization,

    [ValidateRange(1024, 65535)]
    [int]$CdpPort = 9351,

    [ValidateSet('Measure', 'Cleanup', 'VerifyCleanup')]
    [string]$Action = 'Measure'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$ExpectedBaseline = '000d8d4bdd9972d98c30cf2e886d33c3b137b86b'
$Repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
$Frontend = Join-Path $Repository 'frontend'
$EnvironmentHelper = Join-Path $PSScriptRoot 'owned-live-integration.ps1'
$BrowserHelper = Join-Path $PSScriptRoot 'owned-browser-process.ps1'
$BrowserVerifier = Join-Path $PSScriptRoot 'verify-nfr-performance-browser.mjs'
$ResultRoot = Join-Path $Frontend '.tmp-prompt26a-performance'
$ResultPath = Join-Path $ResultRoot 'results.json'
$OwnedIntegrationRoot = Join-Path ([IO.Path]::GetTempPath()) 'CafeFausse-prompt24-integration'
$Psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$Python = Join-Path $Repository 'backend\.venv\Scripts\python.exe'

function Test-LocalPortOpen {
    param([Parameter(Mandatory)][int]$Port)
    $Client = [Net.Sockets.TcpClient]::new()
    try { $Attempt = $Client.ConnectAsync('127.0.0.1', $Port); return $Attempt.Wait(300) -and $Client.Connected }
    catch { return $false }
    finally { $Client.Dispose() }
}

function Assert-ContainedPath {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Parent)
    $CanonicalPath = [IO.Path]::GetFullPath($Path)
    $CanonicalParent = [IO.Path]::GetFullPath($Parent).TrimEnd('\')
    if (-not $CanonicalPath.StartsWith($CanonicalParent + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Prompt-26A path is outside its owned root: $CanonicalPath"
    }
    return $CanonicalPath
}

function Remove-ResultRoot {
    if (-not (Test-Path -LiteralPath $ResultRoot)) { return }
    $Canonical = Assert-ContainedPath -Path $ResultRoot -Parent $Frontend
    $Item = Get-Item -LiteralPath $Canonical -Force
    if (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Prompt-26A result root is a reparse point; refusing cleanup.'
    }
    Remove-Item -LiteralPath $Canonical -Recurse -Force
}

function Remove-EmptyBrowserRoots {
    $BrowserRoot = Join-Path $Frontend '.tmp-react23-verification\browsers'
    if (-not (Test-Path -LiteralPath $BrowserRoot)) { return }
    $MarkerRoot = Join-Path $BrowserRoot 'markers'
    $ProfileRoot = Join-Path $BrowserRoot 'profiles'
    foreach ($Directory in @($ProfileRoot, $MarkerRoot, $BrowserRoot)) {
        if (-not (Test-Path -LiteralPath $Directory)) { continue }
        $Canonical = Assert-ContainedPath -Path $Directory -Parent (Split-Path -Parent $Directory)
        $Item = Get-Item -LiteralPath $Canonical -Force
        if (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Browser cleanup directory is a reparse point: $Canonical"
        }
        if (@(Get-ChildItem -LiteralPath $Canonical -Force).Count -ne 0) {
            throw "Unexpected browser cleanup material remains: $Canonical"
        }
        Remove-Item -LiteralPath $Canonical -Force
    }
}

function Complete-BrowserCleanupAfterFrozenScalarBug {
    param([Parameter(Mandatory)][string]$FailureMessage)
    if ($FailureMessage.IndexOf("property 'Count'", [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Frozen browser cleanup failed before its known zero/single-result strict-mode edge: $FailureMessage"
    }
    $BrowserRoot = Join-Path $Frontend '.tmp-react23-verification\browsers'
    $MarkerRoot = Join-Path $BrowserRoot 'markers'
    $ProfileRoot = Join-Path $BrowserRoot 'profiles'
    $MarkerPath = Join-Path $MarkerRoot "chrome-$CdpPort.json"
    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        throw 'Frozen helper failed at its strict-mode edge but the exact Prompt-26A marker is absent; preserving ambiguous browser material.'
    }
    try { $Marker = Get-Content -LiteralPath $MarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw 'Prompt-26A browser marker is malformed; preserving it.' }
    $ExpectedProfile = [IO.Path]::GetFullPath((Join-Path $ProfileRoot "chrome-$CdpPort"))
    if ([int]$Marker.schema_version -ne 1 -or
        [string]$Marker.owner -cne 'CafeFausse-REACT05-browser-verification' -or
        [string]$Marker.browser -cne 'chrome' -or
        [int]$Marker.cdp_port -ne $CdpPort -or
        [IO.Path]::GetFullPath([string]$Marker.profile_path) -ine $ExpectedProfile -or
        [IO.Path]::GetFullPath([string]$Marker.executable_path) -ine $Chrome) {
        throw 'Prompt-26A browser marker does not match the exact frozen ownership identity; preserving it.'
    }
    $RecordedProcess = Get-Process -Id ([int]$Marker.process_id) -ErrorAction SilentlyContinue
    if ($RecordedProcess) {
        throw 'The recorded Prompt-26A Chrome process remains live after frozen-helper cleanup; preserving it.'
    }
    $ProfileUsers = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
        $_.CommandLine -and $_.CommandLine.IndexOf($ExpectedProfile, [StringComparison]::OrdinalIgnoreCase) -ge 0
    })
    if ($ProfileUsers.Count -ne 0) {
        throw "A process still references the exact Prompt-26A Chrome profile; preserving it: $ExpectedProfile"
    }
    if (Test-LocalPortOpen $CdpPort) { throw "Prompt-26A CDP port remains open: $CdpPort" }
    if (Test-Path -LiteralPath $ExpectedProfile) {
        $ProfileItem = Get-Item -LiteralPath $ExpectedProfile -Force
        if (($ProfileItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'Prompt-26A Chrome profile is a reparse point; preserving it.'
        }
        Remove-Item -LiteralPath $ExpectedProfile -Recurse -Force
    }
    Remove-Item -LiteralPath $MarkerPath -Force
    Remove-EmptyBrowserRoots
    Write-Output '[PROMPT26A:BROWSER-SCALAR-EDGE-RECOVERY:PASS]'
}

function Invoke-Prompt26ABrowserCleanup {
    $MarkerPath = Join-Path $Frontend ".tmp-react23-verification\browsers\markers\chrome-$CdpPort.json"
    if (-not (Test-Path -LiteralPath $MarkerPath)) {
        Remove-EmptyBrowserRoots
        return
    }
    try {
        & $BrowserHelper -Action Stop -Browser chrome -CdpPort $CdpPort
        if ($LASTEXITCODE -ne 0) { throw "Frozen browser helper exited $LASTEXITCODE." }
    }
    catch {
        Complete-BrowserCleanupAfterFrozenScalarBug -FailureMessage $_.Exception.Message
        return
    }
    Remove-EmptyBrowserRoots
}

function Invoke-GuardedCleanup {
    Invoke-Prompt26ABrowserCleanup
    if (Test-Path -LiteralPath $OwnedIntegrationRoot) {
        & $EnvironmentHelper -Action Cleanup -NonProductionClusterAuthorization $NonProductionClusterAuthorization
        if ($LASTEXITCODE -ne 0) { throw 'Guarded live-integration cleanup failed.' }
    }
    elseif ((Test-LocalPortOpen 55435) -or (Test-LocalPortOpen 55004) -or (Test-LocalPortOpen 5173)) {
        throw 'A frozen live-integration listener exists without its ownership root; refusing destructive cleanup.'
    }
    Remove-ResultRoot
}

function Assert-Cleanup {
    foreach ($Port in @(55435, 55004, 5173, $CdpPort)) {
        if (Test-LocalPortOpen $Port) { throw "Prompt-26A listener remains: $Port" }
    }
    if (Test-Path -LiteralPath $OwnedIntegrationRoot) { throw "Owned integration root remains: $OwnedIntegrationRoot" }
    if (Test-Path -LiteralPath $ResultRoot) { throw "Prompt-26A result root remains: $ResultRoot" }
    $BrowserRoot = Join-Path $Frontend '.tmp-react23-verification\browsers'
    if (Test-Path -LiteralPath $BrowserRoot) { throw "Owned browser root remains: $BrowserRoot" }
    Write-Output '[PROMPT26A:CLEANUP:PASS]'
}

if ($Action -eq 'Cleanup') {
    Invoke-GuardedCleanup
    Assert-Cleanup
    exit 0
}
if ($Action -eq 'VerifyCleanup') {
    Assert-Cleanup
    exit 0
}

$Branch = (git -C $Repository branch --show-current).Trim()
$Head = (git -C $Repository rev-parse HEAD).Trim()
$OriginMain = (git -C $Repository rev-parse origin/main).Trim()
$Staged = @(git -C $Repository diff --cached --name-only)
if ($Branch -cne 'main' -or $Head -cne $ExpectedBaseline -or $OriginMain -cne $ExpectedBaseline -or $Staged.Count -ne 0) {
    throw "Prompt-26A baseline/index precondition failed: branch=$Branch HEAD=$Head origin/main=$OriginMain staged=$($Staged.Count)."
}

$ProtectedPaths = @(
    'docs\prompts\Prompt-26A-NFR01-NFR02-Performance-Verification.md',
    'docs\requirements-audit\Cafe_Fausse_Prompt26_Requirements_Rubric_Traceability_Audit.md',
    'frontend\package.json',
    'frontend\package-lock.json'
) + @(git -C $Repository ls-files -- 'frontend/assets/gallery/*')
$ProtectedHashes = @{}
foreach ($Relative in $ProtectedPaths) {
    $ProtectedHashes[$Relative] = (Get-FileHash -LiteralPath (Join-Path $Repository $Relative) -Algorithm SHA256).Hash
}

if (Test-Path -LiteralPath $ResultRoot) { Remove-ResultRoot }
$RunId = [guid]::NewGuid().ToString('N')
$MeasurementSucceeded = $false
$EnvironmentStarted = $false
$BrowserStarted = $false
try {
    & $EnvironmentHelper -Action Start -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    if ($LASTEXITCODE -ne 0) { throw 'Owned live-integration start failed.' }
    $EnvironmentStarted = $true
    & $EnvironmentHelper -Action Status -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    if ($LASTEXITCODE -ne 0) { throw 'Owned live-integration status failed.' }
    & $BrowserHelper -Action Start -Browser chrome -CdpPort $CdpPort -StartUrl 'http://127.0.0.1:5173/' -WindowSize '1280,900'
    if ($LASTEXITCODE -ne 0) { throw 'Owned Chrome start failed.' }
    $BrowserStarted = $true

    $Os = Get-CimInstance Win32_OperatingSystem
    $Computer = Get-CimInstance Win32_ComputerSystem
    $PageFile = @(Get-CimInstance Win32_PageFileUsage | Select-Object Name, CurrentUsage, PeakUsage, AllocatedBaseSize)
    $ChromeVersion = (Get-Item -LiteralPath $Chrome).VersionInfo.ProductVersion
    $NodeVersion = (& node --version).Trim()
    $NpmVersion = (& npm --version).Trim()
    $PythonVersion = (& $Python --version 2>&1).Trim()
    $FlaskVersion = (& $Python -c "import importlib.metadata; print(importlib.metadata.version('Flask'))").Trim()
    $PostgresVersion = (& $Psql -X -qAt -v ON_ERROR_STOP=1 -h 127.0.0.1 -p 55435 -U cafe_fausse_prompt24_verifier -d cafe_fausse_test_api04 -c 'SHOW server_version;').Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the owned PostgreSQL server version.' }
    $Package = Get-Content -LiteralPath (Join-Path $Frontend 'package.json') -Raw | ConvertFrom-Json

    & node $BrowserVerifier $CdpPort $ResultPath $RunId
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $ResultPath)) { throw 'Prompt-26A browser measurement failed.' }

    $Result = Get-Content -LiteralPath $ResultPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $Environment = [ordered]@{
        windows_caption = [string]$Os.Caption
        windows_version = [string]$Os.Version
        windows_build_number = [string]$Os.BuildNumber
        logical_processors = [int]$Computer.NumberOfLogicalProcessors
        total_physical_memory_bytes = [int64]$Computer.TotalPhysicalMemory
        available_memory_at_test_start_bytes = [int64]$Os.FreePhysicalMemory * 1KB
        free_space_in_paging_files_at_test_start_bytes = [int64]$Os.FreeSpaceInPagingFiles * 1KB
        page_file_usage_megabytes = $PageFile
        node_version = $NodeVersion
        npm_version = $NpmVersion
        python_version = $PythonVersion
        postgresql_version = $PostgresVersion
        chrome_version = $ChromeVersion
        flask_version = $FlaskVersion
        react_version = [string]$Package.dependencies.react
        vite_version = [string]$Package.devDependencies.vite
    }
    $Result | Add-Member -MemberType NoteProperty -Name environment -Value $Environment -Force
    $Utf8 = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText($ResultPath, (($Result | ConvertTo-Json -Depth 30) + [Environment]::NewLine), $Utf8)

    $NavigationSampleCount = 0
    foreach ($Route in $Result.nfr1.routes.PSObject.Properties.Value) {
        $NavigationSampleCount += @($Route.samples).Count
    }
    if (@($Result.nfr1.routes.PSObject.Properties).Count -ne 5 -or
        $NavigationSampleCount -ne 25 -or
        @($Result.nfr2.newsletter).Count -ne 10 -or
        @($Result.nfr2.reservation).Count -ne 10) {
        throw 'Prompt-26A required sample cardinality was not met.'
    }
    $MeasurementSucceeded = $true
    Write-Output "[PROMPT26A:MEASUREMENT:PASS] $ResultPath"
}
finally {
    try {
        if ($BrowserStarted) {
            Start-Sleep -Seconds 2
            Invoke-Prompt26ABrowserCleanup
        }
        if ($EnvironmentStarted) {
            & $EnvironmentHelper -Action Stop -NonProductionClusterAuthorization $NonProductionClusterAuthorization
            if ($LASTEXITCODE -ne 0) { throw 'Guarded live-integration stop failed.' }
        }
    }
    finally {
        foreach ($Relative in $ProtectedPaths) {
            if ((Get-FileHash -LiteralPath (Join-Path $Repository $Relative) -Algorithm SHA256).Hash -cne $ProtectedHashes[$Relative]) {
                throw "Protected file changed during Prompt-26A measurement: $Relative"
            }
        }
    }
}

if (-not $MeasurementSucceeded) { exit 1 }
