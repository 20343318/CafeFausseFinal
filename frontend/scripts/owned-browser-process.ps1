[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'Status', 'Stop', 'Cleanup')]
    [string]$Action,

    [ValidateSet('chrome', 'edge')]
    [string]$Browser = 'chrome',

    [ValidateRange(1024, 65535)]
    [int]$CdpPort = 9331,

    [string]$StartUrl = 'http://127.0.0.1:5173/reservations',

    [ValidatePattern('^\d+,\d+$')]
    [string]$WindowSize = '1280,900'
)

$ErrorActionPreference = 'Stop'
$owner = 'CafeFausse-REACT05-browser-verification'
$frontendRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$browserRoot = [IO.Path]::GetFullPath((Join-Path $frontendRoot '.tmp-react23-verification\browsers'))
$markerRoot = Join-Path $browserRoot 'markers'
$profileRoot = Join-Path $browserRoot 'profiles'

function Assert-ContainedPath {
    param([string]$Path, [string]$Parent, [string]$Description)
    $canonicalPath = [IO.Path]::GetFullPath($Path)
    $canonicalParent = [IO.Path]::GetFullPath($Parent).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if (-not $canonicalPath.StartsWith($canonicalParent + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Description is outside its task-owned root: $canonicalPath"
    }
    return $canonicalPath
}

function Test-LocalPortOpen {
    param([int]$Port)
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $attempt = $client.ConnectAsync('127.0.0.1', $Port)
        return $attempt.Wait(300) -and $client.Connected
    }
    catch { return $false }
    finally { $client.Dispose() }
}

function Get-BrowserExecutable {
    param([string]$BrowserName)
    $candidates = if ($BrowserName -eq 'chrome') {
        @('C:\Program Files\Google\Chrome\Application\chrome.exe', 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe')
    }
    else {
        @('C:\Program Files\Microsoft\Edge\Application\msedge.exe', 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe')
    }
    $match = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $match) { throw "$BrowserName is not installed in an approved checked location." }
    return [IO.Path]::GetFullPath($match)
}

function Get-MarkerPath {
    param([string]$BrowserName, [int]$Port)
    return Join-Path $markerRoot "$BrowserName-$Port.json"
}

function Read-OwnedMarker {
    param([string]$MarkerPath)
    $canonicalMarker = Assert-ContainedPath $MarkerPath $markerRoot 'Browser marker'
    if (-not (Test-Path -LiteralPath $canonicalMarker -PathType Leaf)) { throw "Browser marker is missing: $canonicalMarker" }
    try { $marker = Get-Content -LiteralPath $canonicalMarker -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw "Browser marker is malformed; preserving it: $canonicalMarker" }
    if ([int]$marker.schema_version -ne 1 -or [string]$marker.owner -cne $owner) { throw "Browser marker owner/schema mismatch; preserving it: $canonicalMarker" }
    if ([string]$marker.browser -notin @('chrome', 'edge')) { throw "Browser marker type is invalid; preserving it: $canonicalMarker" }
    if (-not $marker.process_id -or -not $marker.start_time_utc -or -not $marker.executable_path -or -not $marker.profile_path -or -not $marker.cdp_port) { throw "Browser marker lacks ownership fields; preserving it: $canonicalMarker" }
    $expectedMarker = [IO.Path]::GetFullPath((Get-MarkerPath ([string]$marker.browser) ([int]$marker.cdp_port)))
    if ($canonicalMarker -ine $expectedMarker) { throw "Browser marker filename does not match its browser/port; preserving it: $canonicalMarker" }
    $expectedProfile = [IO.Path]::GetFullPath((Join-Path $profileRoot "$($marker.browser)-$($marker.cdp_port)"))
    $profile = Assert-ContainedPath ([string]$marker.profile_path) $profileRoot 'Browser profile'
    if ($profile -ine $expectedProfile) { throw "Browser marker profile does not match its browser/port; preserving it: $canonicalMarker" }
    $executable = [IO.Path]::GetFullPath([string]$marker.executable_path)
    if ($executable -ine (Get-BrowserExecutable ([string]$marker.browser))) { throw "Browser marker executable is not the installed browser path; preserving it: $canonicalMarker" }
    return [pscustomobject]@{ Marker = $marker; MarkerPath = $canonicalMarker; ProfilePath = $profile; ExecutablePath = $executable }
}

function Get-ProfileProcesses {
    param([string]$ProfilePath)
    return @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
        $_.CommandLine -and $_.CommandLine.IndexOf($ProfilePath, [StringComparison]::OrdinalIgnoreCase) -ge 0
    })
}

function Get-ProvenOwnedBrowser {
    param($Proof)
    $process = Get-Process -Id ([int]$Proof.Marker.process_id) -ErrorAction SilentlyContinue
    if (-not $process) { return $null }
    if ($process.StartTime.ToUniversalTime().ToString('O') -cne [string]$Proof.Marker.start_time_utc) { throw 'Browser PID creation time differs; preserving ownership evidence.' }
    if ([IO.Path]::GetFullPath($process.Path) -ine $Proof.ExecutablePath) { throw 'Browser PID executable differs; preserving ownership evidence.' }
    $cim = Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)" -ErrorAction Stop
    $command = [string]$cim.CommandLine
    if ($command.IndexOf("--remote-debugging-port=$($Proof.Marker.cdp_port)", [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
        $command.IndexOf($Proof.ProfilePath, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw 'Browser PID command line does not match the recorded CDP port/profile; preserving ownership evidence.'
    }
    return $process
}

function Complete-OwnedCleanup {
    param([string]$MarkerPath)
    $proof = Read-OwnedMarker $MarkerPath
    $process = Get-ProvenOwnedBrowser $proof
    if ($process) {
        $ownedPid = $process.Id
        $process.Kill()
        [void]$process.WaitForExit(15000)
        if (-not $process.HasExited) { throw "Proven-owned browser PID $ownedPid did not exit; preserving evidence." }
        Write-Output "Stopped proven-owned $($proof.Marker.browser) PID $ownedPid."
    }
    else { Write-Output "Recorded $($proof.Marker.browser) PID $($proof.Marker.process_id) already exited." }
    $profileProcesses = Get-ProfileProcesses $proof.ProfilePath
    if ($profileProcesses.Count) { throw "A process still uses the recorded browser profile; preserving evidence: $($proof.ProfilePath)" }
    for ($attempt = 0; $attempt -lt 20 -and (Test-LocalPortOpen ([int]$proof.Marker.cdp_port)); $attempt++) { Start-Sleep -Milliseconds 250 }
    if (Test-LocalPortOpen ([int]$proof.Marker.cdp_port)) { throw "Recorded CDP port remains open; preserving evidence: $($proof.Marker.cdp_port)" }
    if (Test-Path -LiteralPath $proof.ProfilePath) { Remove-Item -LiteralPath $proof.ProfilePath -Recurse -Force -ErrorAction Stop }
    Remove-Item -LiteralPath $proof.MarkerPath -Force -ErrorAction Stop
    Write-Output "Removed verified browser marker/profile for $($proof.Marker.browser) port $($proof.Marker.cdp_port)."
}

if ($Action -eq 'Start') {
    $executable = Get-BrowserExecutable $Browser
    $markerPath = Get-MarkerPath $Browser $CdpPort
    $profilePath = [IO.Path]::GetFullPath((Join-Path $profileRoot "$Browser-$CdpPort"))
    [void](Assert-ContainedPath $markerPath $markerRoot 'Browser marker')
    [void](Assert-ContainedPath $profilePath $profileRoot 'Browser profile')
    if (Test-Path -LiteralPath $markerPath) { throw "A browser ownership marker already exists: $markerPath" }
    if (Test-Path -LiteralPath $profilePath) { throw "An unclaimed browser profile already exists: $profilePath" }
    if (Test-LocalPortOpen $CdpPort) { throw "CDP port $CdpPort is already occupied; refusing launch." }
    New-Item -ItemType Directory -Path $markerRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
    $arguments = @('--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check', '--remote-debugging-address=127.0.0.1', "--remote-debugging-port=$CdpPort", "--user-data-dir=$profilePath", "--window-size=$WindowSize", $StartUrl)
    $process = Start-Process -FilePath $executable -ArgumentList $arguments -WindowStyle Hidden -PassThru
    $marker = [ordered]@{ schema_version = 1; owner = $owner; browser = $Browser; process_id = $process.Id; start_time_utc = $process.StartTime.ToUniversalTime().ToString('O'); executable_path = $executable; profile_path = $profilePath; cdp_port = $CdpPort; start_url = $StartUrl; created_utc = [DateTime]::UtcNow.ToString('O') }
    [IO.File]::WriteAllText($markerPath, ($marker | ConvertTo-Json) + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    $ready = $false
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        try { Invoke-RestMethod "http://127.0.0.1:$CdpPort/json/version" -TimeoutSec 1 | Out-Null; $ready = $true; break }
        catch { Start-Sleep -Milliseconds 250 }
    }
    if (-not $ready) { throw "Browser CDP endpoint did not become reachable; ownership evidence is retained for guarded cleanup: $markerPath" }
    Write-Output "Started owned $Browser PID $($process.Id), profile $profilePath, CDP port $CdpPort."
    Write-Output "Ownership marker: $markerPath"
    exit 0
}

if ($Action -eq 'Status') {
    $proof = Read-OwnedMarker (Get-MarkerPath $Browser $CdpPort)
    $process = Get-ProvenOwnedBrowser $proof
    $profileProcesses = Get-ProfileProcesses $proof.ProfilePath
    Write-Output "Ownership marker valid: $Browser PID $($proof.Marker.process_id), live=$([bool]$process), profile_processes=$($profileProcesses.Count), CDP port $CdpPort."
    exit 0
}

if ($Action -eq 'Stop') {
    Complete-OwnedCleanup (Get-MarkerPath $Browser $CdpPort)
    exit 0
}

if (-not (Test-Path -LiteralPath $browserRoot)) { Write-Output 'No Prompt-23 browser ownership root exists.'; exit 0 }
if (-not (Test-Path -LiteralPath $markerRoot -PathType Container)) { throw 'Prompt-23 browser root exists without its marker directory; preserving ambiguous evidence.' }
$markers = @(Get-ChildItem -LiteralPath $markerRoot -File -Filter '*.json')
foreach ($markerFile in $markers) { Complete-OwnedCleanup $markerFile.FullName }
$unclaimedProfiles = if (Test-Path -LiteralPath $profileRoot) { @(Get-ChildItem -LiteralPath $profileRoot -Force) } else { @() }
if ($unclaimedProfiles.Count) { throw 'Unclaimed Prompt-23 browser profile evidence remains; refusing recursive cleanup.' }
if (@(Get-ChildItem -LiteralPath $markerRoot -Force).Count) { throw 'Unexpected Prompt-23 browser marker material remains; refusing recursive cleanup.' }
if (Test-Path -LiteralPath $profileRoot) { Remove-Item -LiteralPath $profileRoot -Force -ErrorAction Stop }
Remove-Item -LiteralPath $markerRoot -Force -ErrorAction Stop
Remove-Item -LiteralPath $browserRoot -Force -ErrorAction Stop
Write-Output "Removed empty verified Prompt-23 browser ownership root: $browserRoot"
