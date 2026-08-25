[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'Status', 'Stop', 'Cleanup')]
    [string]$Action,

    [ValidateSet('dev', 'preview')]
    [string]$Kind = 'dev'
)

$ErrorActionPreference = 'Stop'
$owner = 'CafeFausse-REACT04-test-run'
$frontendRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$stateRoot = [IO.Path]::GetFullPath((Join-Path $frontendRoot '.tmp-react22-verification\processes'))
$nodePath = [IO.Path]::GetFullPath((Get-Command node.exe -ErrorAction Stop).Source)
$viteEntry = [IO.Path]::GetFullPath((Join-Path $frontendRoot 'node_modules\vite\bin\vite.js'))

function Get-ProcessConfig {
    param([string]$ProcessKind)

    if ($ProcessKind -eq 'preview') {
        return [pscustomobject]@{ Kind = 'preview'; Port = 4173 }
    }

    return [pscustomobject]@{ Kind = 'dev'; Port = 5173 }
}

function Get-MarkerPath {
    param([string]$ProcessKind)
    return Join-Path $stateRoot "$ProcessKind.json"
}

function Test-LocalPortOpen {
    param([int]$Port)

    $client = [Net.Sockets.TcpClient]::new()
    try {
        $attempt = $client.ConnectAsync('127.0.0.1', $Port)
        return $attempt.Wait(300) -and $client.Connected
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Read-OwnedMarker {
    param([string]$ProcessKind)

    $config = Get-ProcessConfig $ProcessKind
    $markerPath = Get-MarkerPath $ProcessKind
    if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
        throw "No $ProcessKind ownership marker exists at $markerPath. Refusing to guess a process owner."
    }

    try {
        $marker = Get-Content -LiteralPath $markerPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        throw "The $ProcessKind ownership marker is unreadable. Refusing process cleanup because ownership is ambiguous."
    }

    $expected = @{
        schema_version = 1
        owner = $owner
        kind = $config.Kind
        port = $config.Port
        executable_path = $nodePath
        working_directory = $frontendRoot
        vite_entry = $viteEntry
    }

    foreach ($field in $expected.Keys) {
        if ([string]$marker.$field -cne [string]$expected[$field]) {
            throw "Ownership field '$field' does not match the REACT-04 test-run identity. Refusing to stop any process."
        }
    }

    if (-not $marker.process_id -or -not $marker.start_time_utc) {
        throw 'The ownership marker lacks a PID or creation time. Refusing to stop any process.'
    }

    return $marker
}

function Get-ProvenOwnedProcess {
    param([string]$ProcessKind)

    $marker = Read-OwnedMarker $ProcessKind
    $process = Get-Process -Id ([int]$marker.process_id) -ErrorAction SilentlyContinue
    if (-not $process) {
        return [pscustomobject]@{ Marker = $marker; Process = $null }
    }

    $actualStart = $process.StartTime.ToUniversalTime().ToString('O')
    if ($actualStart -cne [string]$marker.start_time_utc) {
        throw 'The PID was reused or its creation time differs from the marker. Refusing to stop it.'
    }

    if ([IO.Path]::GetFullPath($process.Path) -ine [string]$marker.executable_path) {
        throw 'The PID executable differs from the recorded Node executable. Refusing to stop it.'
    }

    $cim = Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)" -ErrorAction Stop
    $commandLine = [string]$cim.CommandLine
    if ($commandLine.IndexOf([string]$marker.vite_entry, [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
        $commandLine.IndexOf("--port $($marker.port)", [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw 'The PID command line does not match the recorded Vite entry point and port. Refusing to stop it.'
    }

    return [pscustomobject]@{ Marker = $marker; Process = $process }
}

function Stop-OwnedProcess {
    param([string]$ProcessKind)

    $proof = Get-ProvenOwnedProcess $ProcessKind
    $markerPath = Get-MarkerPath $ProcessKind
    if ($proof.Process) {
        $ownedPid = [int]$proof.Marker.process_id
        $proof.Process.Kill()
        [void]$proof.Process.WaitForExit(15000)
        if (-not $proof.Process.HasExited) {
            throw "The proven-owned $ProcessKind process PID $ownedPid did not exit; retaining its marker."
        }
        Write-Output "Stopped proven-owned $ProcessKind process PID $ownedPid."
    }
    else {
        Write-Output "The proven-owned $ProcessKind marker is stale; no process currently has its recorded PID."
    }

    Remove-Item -LiteralPath $markerPath -Force
    Write-Output "Removed $markerPath."
}

if ($Action -eq 'Start') {
    $config = Get-ProcessConfig $Kind
    $markerPath = Get-MarkerPath $Kind
    if (Test-Path -LiteralPath $markerPath) {
        throw "A $Kind marker already exists. Run guarded Status or Stop recovery before starting another process."
    }

    if (Test-LocalPortOpen $config.Port) {
        throw "Port $($config.Port) is already in use. Refusing to start or terminate an unowned listener."
    }

    if (-not (Test-Path -LiteralPath $viteEntry -PathType Leaf)) {
        throw "Vite is not installed at $viteEntry. Run npm ci first."
    }

    New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    $stdoutPath = Join-Path $stateRoot "$Kind.stdout.log"
    $stderrPath = Join-Path $stateRoot "$Kind.stderr.log"
    $arguments = @($viteEntry)
    if ($Kind -eq 'preview') {
        $arguments += 'preview'
    }
    $arguments += @('--host', '127.0.0.1', '--port', [string]$config.Port, '--strictPort')

    $process = Start-Process -FilePath $nodePath -ArgumentList $arguments -WorkingDirectory $frontendRoot -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru
    Start-Sleep -Milliseconds 750
    $process.Refresh()
    if ($process.HasExited) {
        throw "The $Kind process exited before ownership could be recorded. Review $stderrPath."
    }

    $marker = [ordered]@{
        schema_version = 1
        owner = $owner
        kind = $Kind
        process_id = $process.Id
        start_time_utc = $process.StartTime.ToUniversalTime().ToString('O')
        executable_path = $nodePath
        working_directory = $frontendRoot
        vite_entry = $viteEntry
        port = $config.Port
        created_utc = [DateTime]::UtcNow.ToString('O')
    }
    $json = $marker | ConvertTo-Json
    [IO.File]::WriteAllText($markerPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    Write-Output "Started owned $Kind process PID $($process.Id) on port $($config.Port)."
    Write-Output "Ownership marker: $markerPath"
    exit 0
}

if ($Action -eq 'Status') {
    $proof = Get-ProvenOwnedProcess $Kind
    if ($proof.Process) {
        Write-Output "Ownership proven: $Kind PID $($proof.Process.Id), port $($proof.Marker.port), created $($proof.Marker.start_time_utc)."
    }
    else {
        Write-Output "Ownership marker is valid but stale: $Kind PID $($proof.Marker.process_id) is no longer running."
    }
    exit 0
}

if ($Action -eq 'Stop') {
    Stop-OwnedProcess $Kind
    exit 0
}

foreach ($processKind in @('dev', 'preview')) {
    if (Test-Path -LiteralPath (Get-MarkerPath $processKind)) {
        Stop-OwnedProcess $processKind
    }
}

$expectedParent = $frontendRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $stateRoot.StartsWith($expectedParent, [StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($stateRoot) -cne 'processes') {
    throw 'The process-state directory failed its repository-boundary check. Refusing recursive cleanup.'
}

if (Test-Path -LiteralPath $stateRoot) {
    Remove-Item -LiteralPath $stateRoot -Recurse -Force
    Write-Output "Removed test-owned process state: $stateRoot"
}
