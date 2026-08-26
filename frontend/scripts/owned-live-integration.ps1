[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Start', 'Status', 'StartFlask', 'StopFlask', 'Stop', 'Cleanup')]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [ValidateSet('AUTHORIZED_NONPRODUCTION')]
    [string]$NonProductionClusterAuthorization,

    [ValidateSet('None', 'FailAfterFlaskLauncherRecorded', 'ForceDirectReadinessNotReady', 'ForceProxyReadinessNotReady')]
    [string]$TestSeam = 'None'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$Owner = 'CafeFausse-REACT06-Prompt24-live-integration'
$Repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
$Frontend = Join-Path $Repository 'frontend'
$Backend = Join-Path $Repository 'backend'
$TemporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$OwnedRoot = [IO.Path]::GetFullPath((Join-Path $TemporaryBase 'CafeFausse-prompt24-integration')).TrimEnd('\')
$MarkerPath = Join-Path $OwnedRoot 'ownership.json'
$DataDirectory = Join-Path $OwnedRoot 'postgres-data'
$PostgresLog = Join-Path $OwnedRoot 'postgres.log'
$FlaskOutputLog = Join-Path $OwnedRoot 'flask.stdout.log'
$FlaskErrorLog = Join-Path $OwnedRoot 'flask.stderr.log'
$ViteCache = Join-Path $OwnedRoot 'vite-cache'
$PgBin = 'C:\Program Files\PostgreSQL\18\bin'
$Python = Join-Path $Backend '.venv\Scripts\python.exe'
$ViteHelper = Join-Path $Frontend 'scripts\owned-vite-process.ps1'
$ViteMarker = Join-Path $Frontend '.tmp-react22-verification\processes\dev.json'
$PostgresPort = 55435
$FlaskPort = 55004
$VitePort = 5173
$Database = 'cafe_fausse_test_api04'
$AdminLogin = 'cafe_fausse_admin'
$AppLogin = 'cafe_fausse_api04_login'
$VerifierLogin = 'cafe_fausse_prompt24_verifier'
$ManagedEnvironmentNames = @(
    'CAFE_FAUSSE_ENVIRONMENT',
    'CAFE_FAUSSE_ALLOW_RESET',
    'CAFE_FAUSSE_PSQL',
    'CAFE_FAUSSE_FLASK_PROXY_TARGET',
    'CAFE_FAUSSE_VITE_CACHE_DIR',
    'PGHOST',
    'PGPORT',
    'PGDATABASE',
    'PGUSER',
    'PGPASSWORD',
    'PGPASSFILE',
    'PGSSLMODE'
)

function Save-CallerEnvironment {
    $Snapshot = @{}
    $Current = [Environment]::GetEnvironmentVariables('Process')
    foreach ($Name in $ManagedEnvironmentNames) {
        if ($Current.Contains($Name)) {
            $Snapshot[$Name] = [pscustomobject]@{ present = $true; value = [string]$Current[$Name] }
        }
        else {
            $Snapshot[$Name] = [pscustomobject]@{ present = $false; value = $null }
        }
    }
    return $Snapshot
}

function Restore-CallerEnvironment {
    param([Parameter(Mandatory)][hashtable]$Snapshot)
    foreach ($Name in $ManagedEnvironmentNames) {
        $Prior = $Snapshot[$Name]
        if ([bool]$Prior.present) {
            [Environment]::SetEnvironmentVariable($Name, [string]$Prior.value, 'Process')
        }
        else {
            [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
        }
    }
}

function Clear-ManagedEnvironment {
    foreach ($Name in $ManagedEnvironmentNames) {
        [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
    }
}

function Test-LocalPortOpen {
    param([Parameter(Mandatory)][int]$Port)
    $Client = [Net.Sockets.TcpClient]::new()
    try {
        $Attempt = $Client.ConnectAsync('127.0.0.1', $Port)
        return $Attempt.Wait(300) -and $Client.Connected
    }
    catch { return $false }
    finally { $Client.Dispose() }
}

function Get-ListenerOwner {
    param([Parameter(Mandatory)][int]$Port)
    $Owners = @(
        Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
            ForEach-Object { $_.OwningProcess } |
            Sort-Object -Unique
    )
    if ($Owners.Count -gt 1) { throw "Multiple processes listen on port $Port; refusing ownership." }
    if ($Owners.Count -eq 0) { return $null }
    return [int]$Owners[0]
}

function Write-DurableMarker {
    param([Parameter(Mandatory)]$Marker)
    $TemporaryMarker = "$MarkerPath.new"
    [IO.File]::WriteAllText(
        $TemporaryMarker,
        (($Marker | ConvertTo-Json -Depth 8) + [Environment]::NewLine),
        [Text.UTF8Encoding]::new($false)
    )
    Move-Item -LiteralPath $TemporaryMarker -Destination $MarkerPath -Force
}

function Set-MarkerField {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name,
        $Value
    )
    if ($Object -is [Collections.IDictionary]) {
        $Object[$Name] = $Value
    }
    else {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
    }
}

function Get-MarkerFieldNames {
    param([Parameter(Mandatory)]$Object)
    if ($Object -is [Collections.IDictionary]) { return @($Object.Keys) }
    return @($Object.PSObject.Properties.Name)
}

function Read-OwnedMarker {
    if (-not (Test-Path -LiteralPath $OwnedRoot -PathType Container)) {
        throw "Prompt-24 ownership root is absent: $OwnedRoot"
    }
    $RootItem = Get-Item -LiteralPath $OwnedRoot -Force
    if (($RootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Prompt-24 ownership root is a reparse point; refusing cleanup.'
    }
    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        throw 'Prompt-24 ownership marker is missing; preserving the ambiguous root.'
    }
    try { $Marker = Get-Content -LiteralPath $MarkerPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { throw 'Prompt-24 ownership marker is malformed; preserving the ambiguous root.' }
    if ([int]$Marker.schema_version -ne 1 -or
        [string]$Marker.owner -cne $Owner -or
        [string]$Marker.repository -cne $Repository -or
        [string]$Marker.root -cne $OwnedRoot -or
        [int]$Marker.postgres_port -ne $PostgresPort -or
        [int]$Marker.flask_port -ne $FlaskPort -or
        [int]$Marker.vite_port -ne $VitePort -or
        [string]$Marker.database -cne $Database -or
        [string]$Marker.vite_marker -cne $ViteMarker) {
        throw 'Prompt-24 ownership marker does not match the exact task identity; preserving it.'
    }
    return $Marker
}

function Get-ProvenProcess {
    param(
        [Parameter(Mandatory)][int]$ProcessId,
        [Parameter(Mandatory)][string]$StartTimeUtc,
        [Parameter(Mandatory)][string]$ExecutablePath,
        [string]$RequiredCommandFragment,
        [Nullable[int]]$RequiredParentId
    )
    $Process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($null -eq $Process) { return $null }
    try {
        $ProvenSafeHandle = $Process.SafeHandle
        if ($Process.HasExited) { return $null }
        $ActualStartTimeUtc = $Process.StartTime.ToUniversalTime().ToString('O')
        $ActualExecutablePath = [IO.Path]::GetFullPath($Process.Path)
    }
    catch [System.InvalidOperationException] {
        return $null
    }
    if ($ProvenSafeHandle.IsInvalid -or $ProvenSafeHandle.IsClosed) {
        if ($Process.HasExited) { return $null }
        throw "Could not retain an exact process handle for PID $ProcessId; refusing termination."
    }
    if ($ActualStartTimeUtc -cne $StartTimeUtc -or
        $ActualExecutablePath -ine [IO.Path]::GetFullPath($ExecutablePath)) {
        throw "Process ownership evidence differs for PID $ProcessId; refusing termination."
    }
    $Record = Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
    if ($null -eq $Record) {
        if ($Process.HasExited) { return $null }
        throw "Could not revalidate process command/ancestry for PID $ProcessId; refusing termination."
    }
    if ($RequiredCommandFragment -and
        ([string]$Record.CommandLine).IndexOf($RequiredCommandFragment, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Process command line differs for PID $ProcessId; refusing termination."
    }
    if ($null -ne $RequiredParentId -and [int]$Record.ParentProcessId -ne [int]$RequiredParentId) {
        throw "Process parent differs for PID $ProcessId; refusing termination."
    }
    if ($Process.HasExited) { return $null }
    $Process | Add-Member -NotePropertyName CafeFausseOwnershipProof -NotePropertyValue ([pscustomobject]@{
        process_id = $ProcessId
        start_time_utc = $StartTimeUtc
        executable_path = [IO.Path]::GetFullPath($ExecutablePath)
        command_fragment = $RequiredCommandFragment
        required_parent_id = $RequiredParentId
        safe_handle = $ProvenSafeHandle
    }) -Force
    return $Process
}

function Get-FlaskProcessChain {
    param(
        [Parameter(Mandatory)][int]$ListenerProcessId,
        [Parameter(Mandatory)][int]$LauncherProcessId
    )
    $Chain = [Collections.Generic.List[object]]::new()
    $Seen = [Collections.Generic.HashSet[int]]::new()
    $CurrentId = $ListenerProcessId
    while ($CurrentId -ne $LauncherProcessId) {
        if ($CurrentId -le 0 -or -not $Seen.Add($CurrentId) -or $Chain.Count -ge 8) {
            throw 'Flask listener ancestry is cyclic, too deep, or does not reach the recorded launcher.'
        }
        $Record = Get-CimInstance Win32_Process -Filter "ProcessId = $CurrentId" -ErrorAction Stop
        $Process = Get-Process -Id $CurrentId -ErrorAction Stop
        if (([string]$Record.CommandLine).IndexOf('cafe_fausse', [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
            ([string]$Record.CommandLine).IndexOf($Python, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw 'Flask listener ancestry contains a process without the exact application/venv command.'
        }
        $Chain.Add([ordered]@{
            process_id = $Process.Id
            start_time_utc = $Process.StartTime.ToUniversalTime().ToString('O')
            executable_path = [IO.Path]::GetFullPath($Process.Path)
            parent_process_id = [int]$Record.ParentProcessId
        })
        $CurrentId = [int]$Record.ParentProcessId
    }
    return $Chain.ToArray()
}

function Get-LiveFlaskDescendants {
    param([Parameter(Mandatory)][int]$LauncherProcessId)
    $Records = @(Get-CimInstance Win32_Process -ErrorAction Stop)
    $ById = @{}
    foreach ($Record in $Records) { $ById[[int]$Record.ProcessId] = $Record }
    $Matches = [Collections.Generic.List[object]]::new()
    foreach ($Record in $Records) {
        $Command = [string]$Record.CommandLine
        if ($Command.IndexOf('cafe_fausse', [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
            $Command.IndexOf($Python, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
        $CurrentParent = [int]$Record.ParentProcessId
        $Depth = 0
        while ($CurrentParent -gt 0 -and $Depth -lt 8) {
            if ($CurrentParent -eq $LauncherProcessId) {
                $Matches.Add($Record)
                break
            }
            if (-not $ById.ContainsKey($CurrentParent)) { break }
            $CurrentParent = [int]$ById[$CurrentParent].ParentProcessId
            $Depth++
        }
    }
    return $Matches.ToArray()
}

function Get-TestSeamLauncher {
    param([Parameter(Mandatory)][int]$InitialLauncherId)
    $Records = @(Get-CimInstance Win32_Process -ErrorAction Stop)
    $ById = @{}
    foreach ($Record in $Records) { $ById[[int]$Record.ProcessId] = $Record }
    $Matches = @($Records | Where-Object {
        [string]$_.ExecutablePath -ieq (Join-Path $env:SystemRoot 'System32\ping.exe') -and
        ([string]$_.CommandLine).IndexOf('-t 127.0.0.1', [StringComparison]::OrdinalIgnoreCase) -ge 0
    })
    $OwnedMatches = @()
    foreach ($Record in $Matches) {
        $CurrentId = [int]$Record.ProcessId
        $Depth = 0
        while ($CurrentId -gt 0 -and $Depth -lt 8) {
            if ($CurrentId -eq $InitialLauncherId) { $OwnedMatches += $Record; break }
            if (-not $ById.ContainsKey($CurrentId)) { break }
            $CurrentId = [int]$ById[$CurrentId].ParentProcessId
            $Depth++
        }
    }
    if ($OwnedMatches.Count -gt 1) { throw 'Multiple test-seam launcher descendants were discovered; refusing ownership.' }
    if ($OwnedMatches.Count -eq 0) { return $null }
    return $OwnedMatches[0]
}

function Stop-ProvenProcess {
    param([Parameter(Mandatory)]$Process, [Parameter(Mandatory)][string]$Description)
    if ($null -eq $Process) { return }
    $ProofProperty = $Process.PSObject.Properties['CafeFausseOwnershipProof']
    if ($null -eq $ProofProperty -or $null -eq $ProofProperty.Value) {
        throw "$Description lacks in-memory exact ownership proof; refusing termination."
    }
    $Proof = $ProofProperty.Value
    $RecordedId = [int]$Proof.process_id
    if ($Process.Id -ne $RecordedId -or
        $Proof.safe_handle.IsInvalid -or
        $Proof.safe_handle.IsClosed) {
        throw "$Description exact process handle/identity is unavailable; refusing termination."
    }
    try {
        if ($Process.HasExited) {
            Write-Output "Recorded $Description PID $RecordedId already exited."
            return
        }
        if ($Process.StartTime.ToUniversalTime().ToString('O') -cne [string]$Proof.start_time_utc -or
            [IO.Path]::GetFullPath($Process.Path) -ine [string]$Proof.executable_path -or
            $Process.SafeHandle.DangerousGetHandle() -ne $Proof.safe_handle.DangerousGetHandle()) {
            throw "$Description in-memory process identity changed after proof; refusing termination."
        }
    }
    catch [System.InvalidOperationException] {
        Write-Output "Recorded $Description PID $RecordedId already exited."
        return
    }
    try { $Process.Kill() }
    catch {
        try {
            if ($Process.HasExited) {
                Write-Output "Recorded $Description PID $RecordedId exited during cleanup."
                return
            }
        }
        catch [System.InvalidOperationException] {
            Write-Output "Recorded $Description PID $RecordedId exited during cleanup."
            return
        }
        throw
    }
    if (-not $Process.WaitForExit(15000) -or -not $Process.HasExited) {
        throw "$Description did not exit; preserving ownership evidence."
    }
    Write-Output "Stopped proven-owned $Description PID $RecordedId."
}

function Assert-PostgresOwnership {
    param([Parameter(Mandatory)]$Marker)
    if (-not $Marker.postgres) { return $null }
    $Process = Get-ProvenProcess `
        -ProcessId ([int]$Marker.postgres.process_id) `
        -StartTimeUtc ([string]$Marker.postgres.start_time_utc) `
        -ExecutablePath ([string]$Marker.postgres.executable_path) `
        -RequiredCommandFragment $DataDirectory.Replace('\', '/')
    $ListenerOwner = Get-ListenerOwner $PostgresPort
    if ($null -ne $Process -and $ListenerOwner -ne $Process.Id) {
        throw 'PostgreSQL listener ownership differs from the recorded postmaster; refusing cleanup.'
    }
    if ($null -eq $Process -and $null -ne $ListenerOwner) {
        throw 'PostgreSQL port is occupied without the recorded postmaster; refusing cleanup.'
    }
    return $Process
}

function Assert-FlaskOwnership {
    param([Parameter(Mandatory)]$Marker)
    if (-not $Marker.flask) { return $null }

    $FlaskFields = @(Get-MarkerFieldNames $Marker.flask)
    foreach ($Required in @('state', 'readiness_proven', 'launcher_process_id', 'launcher_start_time_utc', 'launcher_executable_path', 'launcher_command_fragment')) {
        if ($FlaskFields -notcontains $Required) {
            throw "Recorded Flask ownership is missing $Required; preserving ambiguous evidence."
        }
    }
    if ([string]$Marker.flask.state -notin @('launcher_recorded', 'listener_recorded', 'ready')) {
        throw 'Recorded Flask ownership state is invalid; preserving ambiguous evidence.'
    }

    $Launcher = Get-ProvenProcess `
        -ProcessId ([int]$Marker.flask.launcher_process_id) `
        -StartTimeUtc ([string]$Marker.flask.launcher_start_time_utc) `
        -ExecutablePath ([string]$Marker.flask.launcher_executable_path) `
        -RequiredCommandFragment ([string]$Marker.flask.launcher_command_fragment)

    $ListenerFieldNames = @('listener_process_id', 'listener_start_time_utc', 'listener_executable_path', 'listener_parent_process_id', 'intermediate_processes')
    $ListenerFieldCount = @($ListenerFieldNames | Where-Object { $FlaskFields -contains $_ }).Count
    $ListenerOwner = Get-ListenerOwner $FlaskPort

    if ($ListenerFieldCount -ne 0 -and $ListenerFieldCount -ne $ListenerFieldNames.Count) {
        throw 'Recorded Flask listener ownership is incomplete; preserving ambiguous evidence.'
    }

    if ($ListenerFieldCount -eq 0 -and $null -ne $ListenerOwner) {
        $Chain = @(Get-FlaskProcessChain -ListenerProcessId $ListenerOwner -LauncherProcessId ([int]$Marker.flask.launcher_process_id))
        if ($Chain.Count -eq 0) { throw 'Flask listener ancestry evidence was empty.' }
        Set-MarkerField $Marker.flask 'listener_process_id' ([int]$Chain[0].process_id)
        Set-MarkerField $Marker.flask 'listener_start_time_utc' ([string]$Chain[0].start_time_utc)
        Set-MarkerField $Marker.flask 'listener_executable_path' ([string]$Chain[0].executable_path)
        Set-MarkerField $Marker.flask 'listener_parent_process_id' ([int]$Chain[0].parent_process_id)
        $Intermediates = if ($Chain.Count -gt 1) { @($Chain[1..($Chain.Count - 1)]) } else { @() }
        Set-MarkerField $Marker.flask 'intermediate_processes' $Intermediates
        $Marker.flask.state = 'listener_recorded'
        $Marker.flask.readiness_proven = $false
        Write-DurableMarker $Marker
        $FlaskFields = @(Get-MarkerFieldNames $Marker.flask)
        $ListenerFieldCount = $ListenerFieldNames.Count
    }

    $Listener = $null
    $IntermediateProcesses = @()
    if ($ListenerFieldCount -eq $ListenerFieldNames.Count) {
        [object[]]$IntermediateEvidence = @()
        if ($null -ne $Marker.flask.intermediate_processes) {
            $IntermediateEvidence = @($Marker.flask.intermediate_processes)
        }
        $ExpectedListenerParent = if ($IntermediateEvidence.Count) { [int]$IntermediateEvidence[0].process_id } else { [int]$Marker.flask.launcher_process_id }
        if ([int]$Marker.flask.listener_parent_process_id -ne $ExpectedListenerParent) {
            throw 'Recorded Flask listener ancestry does not connect to its first intermediate/launcher.'
        }
        for ($Index = 0; $Index -lt $IntermediateEvidence.Count; $Index++) {
            $Evidence = $IntermediateEvidence[$Index]
            $ExpectedParent = if ($Index + 1 -lt $IntermediateEvidence.Count) { [int]$IntermediateEvidence[$Index + 1].process_id } else { [int]$Marker.flask.launcher_process_id }
            if ([int]$Evidence.parent_process_id -ne $ExpectedParent) {
                throw 'Recorded Flask intermediate ancestry is disconnected; refusing cleanup.'
            }
            $Intermediate = Get-ProvenProcess `
                -ProcessId ([int]$Evidence.process_id) `
                -StartTimeUtc ([string]$Evidence.start_time_utc) `
                -ExecutablePath ([string]$Evidence.executable_path) `
                -RequiredCommandFragment 'cafe_fausse' `
                -RequiredParentId ([int]$Evidence.parent_process_id)
            if ($null -ne $Intermediate) { $IntermediateProcesses += $Intermediate }
        }
        $Listener = Get-ProvenProcess `
            -ProcessId ([int]$Marker.flask.listener_process_id) `
            -StartTimeUtc ([string]$Marker.flask.listener_start_time_utc) `
            -ExecutablePath ([string]$Marker.flask.listener_executable_path) `
            -RequiredCommandFragment 'cafe_fausse' `
            -RequiredParentId ([int]$Marker.flask.listener_parent_process_id)
    }

    if ($ListenerFieldCount -eq 0 -and [string]$Marker.flask.state -ne 'launcher_recorded') {
        throw 'Flask ownership state claims listener/readiness without listener evidence.'
    }
    if ($ListenerFieldCount -eq $ListenerFieldNames.Count -and [string]$Marker.flask.state -eq 'launcher_recorded') {
        throw 'Flask listener evidence conflicts with its durable ownership state.'
    }
    if ([string]$Marker.flask.state -eq 'ready' -and -not [bool]$Marker.flask.readiness_proven) {
        throw 'Flask ready state lacks readiness proof.'
    }
    if ([string]$Marker.flask.state -ne 'ready' -and [bool]$Marker.flask.readiness_proven) {
        throw 'Flask readiness proof conflicts with its durable ownership state.'
    }

    if ($null -ne $Listener -and $null -ne $ListenerOwner -and $ListenerOwner -ne $Listener.Id) {
        throw 'Flask listener ownership differs from the recorded child; refusing cleanup.'
    }
    if ($null -eq $Listener -and $null -ne $ListenerOwner) {
        throw 'Flask port is occupied without the recorded process pair; refusing cleanup.'
    }
    if ($null -eq $Launcher -and $null -eq $Listener) { return $null }
    return [pscustomobject]@{ Launcher = $Launcher; Listener = $Listener; Intermediates = @($IntermediateProcesses) }
}

function Invoke-Psql {
    param([Parameter(Mandatory)][string]$User, [Parameter(Mandatory)][string]$Sql)
    $Output = & (Join-Path $PgBin 'psql.exe') -X -qAt -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p $PostgresPort -U $User -d $Database -c $Sql
    if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 PostgreSQL command failed.' }
    return @($Output)
}

function Test-OwnedDatabaseExists {
    $Result = & (Join-Path $PgBin 'psql.exe') -X -qAt -v ON_ERROR_STOP=1 `
        -h 127.0.0.1 -p $PostgresPort -U $AdminLogin -d postgres `
        -c "SELECT 1 FROM pg_catalog.pg_database WHERE datname = '$Database';"
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the Prompt-24 disposable database.' }
    return (($Result -join '').Trim() -ceq '1')
}

function Set-DatabaseEnvironment {
    $env:CAFE_FAUSSE_ENVIRONMENT = 'test'
    $env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
    $env:CAFE_FAUSSE_PSQL = Join-Path $PgBin 'psql.exe'
    $env:PGHOST = '127.0.0.1'
    $env:PGPORT = [string]$PostgresPort
    $env:PGDATABASE = $Database
    $env:PGUSER = $AdminLogin
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:PGPASSFILE -ErrorAction SilentlyContinue
    Remove-Item Env:PGSSLMODE -ErrorAction SilentlyContinue
}

function Start-Flask {
    param([Parameter(Mandatory)]$Marker)
    foreach ($Name in @('CAFE_FAUSSE_ALLOW_RESET', 'CAFE_FAUSSE_PSQL')) {
        Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
    }
    $env:CAFE_FAUSSE_ENVIRONMENT = 'test'
    $env:PGHOST = '127.0.0.1'
    $env:PGPORT = [string]$PostgresPort
    $env:PGDATABASE = $Database
    $env:PGUSER = $AppLogin
    if ($null -ne (Get-ListenerOwner $FlaskPort)) { throw "Flask port $FlaskPort is already occupied." }
    if ($TestSeam -eq 'FailAfterFlaskLauncherRecorded') {
        $LauncherCommandFragment = '127.0.0.1'
        $TestPing = Join-Path $env:SystemRoot 'System32\ping.exe'
        $Launcher = Start-Process -FilePath $TestPing -ArgumentList @(
            '-t', $LauncherCommandFragment
        ) -WorkingDirectory $Backend -WindowStyle Hidden -PassThru
        $LauncherExecutablePath = [IO.Path]::GetFullPath($TestPing)
    }
    else {
        $LauncherCommandFragment = 'cafe_fausse'
        $Launcher = Start-Process -FilePath $Python -ArgumentList @(
            '-m', 'flask', '--app', 'cafe_fausse', 'run',
            '--host', '127.0.0.1', '--port', [string]$FlaskPort,
            '--no-reload', '--no-debugger'
        ) -WorkingDirectory $Backend -WindowStyle Hidden -RedirectStandardOutput $FlaskOutputLog `
            -RedirectStandardError $FlaskErrorLog -PassThru
        $LauncherExecutablePath = [IO.Path]::GetFullPath($Python)
    }

    $Marker.flask = [ordered]@{
        state = 'launcher_recorded'
        readiness_proven = $false
        launcher_process_id = $Launcher.Id
        launcher_start_time_utc = $Launcher.StartTime.ToUniversalTime().ToString('O')
        launcher_executable_path = $LauncherExecutablePath
        launcher_command_fragment = $LauncherCommandFragment
    }
    Write-DurableMarker $Marker
    if ($TestSeam -eq 'FailAfterFlaskLauncherRecorded') {
        $InitialLauncherId = $Launcher.Id
        $StableRecord = $null
        for ($Attempt = 0; $Attempt -lt 40; $Attempt++) {
            $StableRecord = Get-TestSeamLauncher -InitialLauncherId $InitialLauncherId
            if ($null -ne $StableRecord) { break }
            Start-Sleep -Milliseconds 100
        }
        if ($null -eq $StableRecord) {
            throw 'Controlled Prompt-24 seam could not durably associate its exact test launcher descendant.'
        }
        $StableProcess = Get-Process -Id ([int]$StableRecord.ProcessId) -ErrorAction Stop
        if ($StableProcess.Id -ne $InitialLauncherId) {
            Set-MarkerField $Marker.flask 'initial_launcher_process_id' $InitialLauncherId
            Set-MarkerField $Marker.flask 'initial_launcher_start_time_utc' ([string]$Marker.flask.launcher_start_time_utc)
            Set-MarkerField $Marker.flask 'initial_launcher_executable_path' ([string]$Marker.flask.launcher_executable_path)
            $Marker.flask.launcher_process_id = $StableProcess.Id
            $Marker.flask.launcher_start_time_utc = $StableProcess.StartTime.ToUniversalTime().ToString('O')
            $Marker.flask.launcher_executable_path = [IO.Path]::GetFullPath($StableProcess.Path)
            Write-DurableMarker $Marker
        }
        throw 'Controlled Prompt-24 test failure after durable Flask launcher ownership.'
    }

    $Ownership = Assert-FlaskOwnership $Marker
    if ($null -eq $Ownership -or $null -eq $Ownership.Launcher) {
        throw "Recorded Flask launcher exited before listener association. Review $FlaskErrorLog."
    }

    $DirectReady = $false
    $AttemptLimit = if ($TestSeam -eq 'ForceDirectReadinessNotReady') { 2 } else { 40 }
    for ($Attempt = 0; $Attempt -lt $AttemptLimit; $Attempt++) {
        $Ownership = Assert-FlaskOwnership $Marker
        if ($null -eq $Ownership -or $null -eq $Ownership.Launcher) { break }
        if ($null -ne $Ownership.Listener) {
            try {
                $Ready = Invoke-RestMethod "http://127.0.0.1:$FlaskPort/api/v1/health/readiness" -TimeoutSec 2
                $ReadyStatus = [string]$Ready.status
                if ($TestSeam -eq 'ForceDirectReadinessNotReady') { $ReadyStatus = 'controlled_not_ready' }
                if ($ReadyStatus -ceq 'ready') {
                    $Marker.flask.state = 'ready'
                    $Marker.flask.readiness_proven = $true
                    Set-MarkerField $Marker.flask 'readiness_proven_utc' ([DateTime]::UtcNow.ToString('O'))
                    Write-DurableMarker $Marker
                    $DirectReady = $true
                    break
                }
            }
            catch { }
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $DirectReady) {
        throw "Flask listener/readiness did not produce OP-07 status ready. Review $FlaskErrorLog."
    }
    Assert-FlaskOwnership $Marker | Out-Null
    Write-Output "Started proven-owned Flask with direct OP-07 readiness on 127.0.0.1:$FlaskPort."
}

function Stop-Flask {
    param([Parameter(Mandatory)]$Marker)
    if (-not $Marker.flask) {
        if (Test-LocalPortOpen $FlaskPort) { throw 'Flask port is occupied without recorded Flask ownership; refusing cleanup.' }
        return
    }
    $WasLauncherOnly = $Marker.flask -and [string]$Marker.flask.state -ceq 'launcher_recorded'
    $Ownership = $null
    $OwnershipAttempts = if ($WasLauncherOnly) { 20 } else { 1 }
    for ($Attempt = 0; $Attempt -lt $OwnershipAttempts; $Attempt++) {
        $Ownership = Assert-FlaskOwnership $Marker
        if (-not $WasLauncherOnly -or [string]$Marker.flask.state -ne 'launcher_recorded') { break }
        Start-Sleep -Milliseconds 100
    }
    if ($null -ne $Ownership) {
        if ($null -ne $Ownership.Listener) { Stop-ProvenProcess $Ownership.Listener 'Flask listener' }
        foreach ($Intermediate in @($Ownership.Intermediates)) {
            Stop-ProvenProcess $Intermediate 'Flask intermediate launcher'
        }
        if ($null -ne $Ownership.Launcher) { Stop-ProvenProcess $Ownership.Launcher 'Flask launcher' }
    }

    $QuietChecks = 0
    for ($Attempt = 0; $Attempt -lt 100 -and $QuietChecks -lt 20; $Attempt++) {
        if (Test-LocalPortOpen $FlaskPort) {
            $LateOwnership = Assert-FlaskOwnership $Marker
            if ($null -eq $LateOwnership -or $null -eq $LateOwnership.Listener) {
                throw 'A late Flask listener could not be tied to durable ownership evidence.'
            }
            Stop-ProvenProcess $LateOwnership.Listener 'late Flask listener'
            foreach ($Intermediate in @($LateOwnership.Intermediates)) {
                Stop-ProvenProcess $Intermediate 'late Flask intermediate launcher'
            }
            if ($null -ne $LateOwnership.Launcher) { Stop-ProvenProcess $LateOwnership.Launcher 'late Flask launcher' }
            $QuietChecks = 0
        }
        elseif (@(Get-LiveFlaskDescendants ([int]$Marker.flask.launcher_process_id)).Count -gt 0) {
            $QuietChecks = 0
        }
        else {
            $QuietChecks++
        }
        Start-Sleep -Milliseconds 100
    }
    if (Test-LocalPortOpen $FlaskPort) { throw "Flask port $FlaskPort remains open." }
    if ($Marker.flask) {
        $RemainingDescendants = @(Get-LiveFlaskDescendants ([int]$Marker.flask.launcher_process_id))
        if ($RemainingDescendants.Count) {
            throw 'A Flask process associated with the recorded launcher remains; preserving ownership evidence.'
        }
    }
    $Marker.flask = $null
    Write-DurableMarker $Marker
}

function Stop-OwnedEnvironment {
    param([Parameter(Mandatory)]$Marker)

    # Validate every recorded process/listener before stopping any layer. This
    # preserves the complete environment and its evidence when one layer is
    # malformed, mismatched, or otherwise ambiguous.
    Assert-PostgresOwnership $Marker | Out-Null
    Assert-FlaskOwnership $Marker | Out-Null
    if (Test-Path -LiteralPath $ViteMarker) {
        & $ViteHelper -Action Status -Kind dev
        if ($LASTEXITCODE -ne 0) { throw 'Owned Vite preflight status failed.' }
    }
    elseif (Test-LocalPortOpen $VitePort) {
        throw 'Vite port is occupied without its exact helper marker; refusing cleanup.'
    }

    if (Test-Path -LiteralPath $ViteMarker) {
        & $ViteHelper -Action Stop -Kind dev
        if ($LASTEXITCODE -ne 0) { throw 'Owned Vite stop failed.' }
    }
    elseif (Test-LocalPortOpen $VitePort) {
        throw 'Vite port is occupied without its exact helper marker; refusing cleanup.'
    }

    Stop-Flask $Marker

    $Postgres = Assert-PostgresOwnership $Marker
    if ($null -ne $Postgres) {
        if (Test-OwnedDatabaseExists) {
            Set-DatabaseEnvironment
            Set-Location $Repository
            & '.\database\scripts\rebuild.ps1'
            if ($LASTEXITCODE -ne 0) { throw 'Final Prompt-24 database reset failed.' }
            $Counts = (@(Invoke-Psql -User $VerifierLogin -Sql "SET ROLE cafe_fausse_test; SELECT concat_ws('|',(SELECT count(*) FROM cafe_fausse.customers),(SELECT count(*) FROM cafe_fausse.reservations),(SELECT count(*) FROM cafe_fausse.reservation_table_assignments));") -join '').Trim()
            if ($Counts -cne '0|0|0') { throw "Prompt-24 rows survived final reset: $Counts" }
        }
        else {
            Write-Output 'Prompt-24 partial-start cleanup: the recorded cluster contained no disposable database.'
        }
        & (Join-Path $PgBin 'pg_ctl.exe') -D $DataDirectory -m fast -w stop
        if ($LASTEXITCODE -ne 0) { throw 'Owned PostgreSQL shutdown failed.' }
    }
    if (Test-LocalPortOpen $PostgresPort) { throw "PostgreSQL port $PostgresPort remains open." }

    $ResolvedRoot = [IO.Path]::GetFullPath($OwnedRoot).TrimEnd('\')
    $ExpectedPrefix = $TemporaryBase + [IO.Path]::DirectorySeparatorChar
    if (-not $ResolvedRoot.StartsWith($ExpectedPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($ResolvedRoot) -cne 'CafeFausse-prompt24-integration') {
        throw 'Prompt-24 root failed its exact temporary-directory boundary check.'
    }
    Remove-Item -LiteralPath $ResolvedRoot -Recurse -Force
    if (Test-Path -LiteralPath $ResolvedRoot) { throw 'Prompt-24 root survived cleanup.' }
    Write-Output 'Prompt-24 cleanup pass: Vite, Flask, PostgreSQL, test rows, logs, cache, and ownership root are absent.'
}

if ($TestSeam -eq 'FailAfterFlaskLauncherRecorded' -and $Action -ne 'StartFlask') {
    throw 'FailAfterFlaskLauncherRecorded is permitted only with StartFlask.'
}
if ($TestSeam -eq 'ForceDirectReadinessNotReady' -and $Action -ne 'StartFlask') {
    throw 'ForceDirectReadinessNotReady is permitted only with StartFlask.'
}
if ($TestSeam -eq 'ForceProxyReadinessNotReady' -and $Action -ne 'Start') {
    throw 'ForceProxyReadinessNotReady is permitted only with Start.'
}

$CallerEnvironment = Save-CallerEnvironment
try {
Clear-ManagedEnvironment
if ($Action -eq 'Start') {
    if (Test-Path -LiteralPath $OwnedRoot) {
        throw 'A Prompt-24 ownership root already exists. Use guarded Status or Cleanup; refusing replacement.'
    }
    foreach ($Port in @($PostgresPort, $FlaskPort, $VitePort)) {
        if (Test-LocalPortOpen $Port) { throw "Required port $Port is occupied; refusing to claim it." }
    }
    foreach ($Path in @($Python, $ViteHelper, (Join-Path $PgBin 'initdb.exe'))) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required tool is missing: $Path" }
    }

    New-Item -ItemType Directory -Path $OwnedRoot -ErrorAction Stop | Out-Null
    $Marker = [ordered]@{
        schema_version = 1
        owner = $Owner
        repository = $Repository
        root = $OwnedRoot
        created_utc = [DateTime]::UtcNow.ToString('O')
        postgres_port = $PostgresPort
        flask_port = $FlaskPort
        vite_port = $VitePort
        database = $Database
        vite_marker = $ViteMarker
        postgres = $null
        flask = $null
    }
    Write-DurableMarker $Marker
    try {
        New-Item -ItemType Directory -Path $DataDirectory -ErrorAction Stop | Out-Null
        & (Join-Path $PgBin 'initdb.exe') -D $DataDirectory -U $AdminLogin --auth=trust --encoding=UTF8 --no-locale
        if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 disposable PostgreSQL initialization failed.' }
        & (Join-Path $PgBin 'pg_ctl.exe') -D $DataDirectory -l $PostgresLog -o "-p $PostgresPort -h 127.0.0.1" -w start
        if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 disposable PostgreSQL startup failed.' }
        $PostmasterId = [int](Get-Content -LiteralPath (Join-Path $DataDirectory 'postmaster.pid') -First 1)
        $Postmaster = Get-Process -Id $PostmasterId -ErrorAction Stop
        $Marker.postgres = [ordered]@{
            process_id = $Postmaster.Id
            start_time_utc = $Postmaster.StartTime.ToUniversalTime().ToString('O')
            executable_path = [IO.Path]::GetFullPath($Postmaster.Path)
        }
        Write-DurableMarker $Marker
        Assert-PostgresOwnership $Marker | Out-Null

        & (Join-Path $PgBin 'createdb.exe') -h 127.0.0.1 -p $PostgresPort -U $AdminLogin $Database
        if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 disposable database creation failed.' }
        Set-DatabaseEnvironment
        Set-Location $Repository
        & '.\database\scripts\rebuild.ps1'
        if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 approved database rebuild failed.' }
        & '.\database\scripts\verify.ps1'
        if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 approved database verification failed.' }
        $LoginSql = @"
CREATE ROLE $AppLogin LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE ROLE $VerifierLogin LOGIN NOINHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
GRANT cafe_fausse_app TO $AppLogin;
GRANT cafe_fausse_test TO $VerifierLogin;
GRANT CONNECT ON DATABASE $Database TO $AppLogin, $VerifierLogin;
"@
        $LoginSql | & (Join-Path $PgBin 'psql.exe') -X -v ON_ERROR_STOP=1 -h 127.0.0.1 -p $PostgresPort -U $AdminLogin -d $Database
        if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 application/verifier login creation failed.' }

        Start-Flask $Marker
        $env:CAFE_FAUSSE_FLASK_PROXY_TARGET = "http://127.0.0.1:$FlaskPort"
        $env:CAFE_FAUSSE_VITE_CACHE_DIR = $ViteCache
        & $ViteHelper -Action Start -Kind dev
        if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 owned Vite startup failed.' }
        $ProxyReady = $false
        $ProxyAttemptLimit = if ($TestSeam -eq 'ForceProxyReadinessNotReady') { 2 } else { 30 }
        for ($Attempt = 0; $Attempt -lt $ProxyAttemptLimit; $Attempt++) {
            try {
                $Ready = Invoke-RestMethod "http://127.0.0.1:$VitePort/api/v1/health/readiness" -TimeoutSec 2
                $ReadyStatus = [string]$Ready.status
                if ($TestSeam -eq 'ForceProxyReadinessNotReady') { $ReadyStatus = 'controlled_not_ready' }
                if ($ReadyStatus -ceq 'ready') {
                    $ProxyReady = $true
                    break
                }
            }
            catch { }
            Start-Sleep -Milliseconds 500
        }
        if (-not (Test-LocalPortOpen $VitePort)) { throw 'Vite proxy did not become reachable.' }
        if (-not $ProxyReady) { throw 'Vite listener existed but proxied OP-07 did not return status ready.' }
        Write-Output "Prompt-24 environment ready: PostgreSQL $PostgresPort -> Flask $FlaskPort -> Vite $VitePort."
    }
    catch {
        $Failure = $_
        try { Stop-OwnedEnvironment (Read-OwnedMarker) }
        catch { Write-Error "Prompt-24 guarded startup cleanup failed and preserved evidence: $($_.Exception.Message)" }
        throw $Failure
    }
    return
}

if ($Action -eq 'Status') {
    $Marker = Read-OwnedMarker
    Assert-PostgresOwnership $Marker | Out-Null
    Assert-FlaskOwnership $Marker | Out-Null
    if (-not (Test-Path -LiteralPath $ViteMarker -PathType Leaf)) { throw 'Owned Vite marker is absent.' }
    & $ViteHelper -Action Status -Kind dev
    if ($LASTEXITCODE -ne 0) { throw 'Owned Vite status failed.' }
    $Ready = Invoke-RestMethod "http://127.0.0.1:$VitePort/api/v1/health/readiness" -TimeoutSec 3
    if ($Ready.status -ne 'ready') { throw 'Vite-to-Flask readiness proxy is not ready.' }
    Write-Output 'Prompt-24 status pass: every process, listener, marker, and readiness response is owned and current.'
    return
}

if ($Action -eq 'StopFlask') {
    $Marker = Read-OwnedMarker
    Assert-PostgresOwnership $Marker | Out-Null
    if (-not (Test-Path -LiteralPath $ViteMarker -PathType Leaf)) { throw 'Owned Vite marker is absent.' }
    Stop-Flask $Marker
    Write-Output 'Prompt-24 controlled transport-failure state: Flask is stopped; owned PostgreSQL and Vite remain running.'
    return
}

if ($Action -eq 'StartFlask') {
    $Marker = Read-OwnedMarker
    Assert-PostgresOwnership $Marker | Out-Null
    if ($null -ne $Marker.flask) {
        $ExistingFlask = Assert-FlaskOwnership $Marker
        if ($null -ne $ExistingFlask) { throw 'A proven-owned Flask process is already running.' }
        $Marker.flask = $null
        Write-DurableMarker $Marker
    }
    Start-Flask $Marker
    $Ready = Invoke-RestMethod "http://127.0.0.1:$VitePort/api/v1/health/readiness" -TimeoutSec 3
    if ($Ready.status -ne 'ready') { throw 'Restarted Flask did not become ready through Vite.' }
    Write-Output 'Prompt-24 Flask restart pass: readiness restored through the owned Vite proxy.'
    return
}

$Marker = Read-OwnedMarker
Stop-OwnedEnvironment $Marker
}
finally {
    Restore-CallerEnvironment $CallerEnvironment
}
