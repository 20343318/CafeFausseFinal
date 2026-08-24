[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('AUTHORIZED_NONPRODUCTION')]
    [string]$NonProductionClusterAuthorization,
    [switch]$InjectFailure,
    [switch]$InjectCleanupFailure,
    [switch]$CleanupOwnedRoot,
    [switch]$PrepareInterruptionState
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$CafeRepository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
$CafeTemporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$CafeExpectedRoot = [IO.Path]::GetFullPath(
    (Join-Path $CafeTemporaryBase 'CafeFausse-api07-tests')
).TrimEnd('\')
$CafeRoot = $CafeExpectedRoot
$CafeMarker = Join-Path $CafeRoot 'ownership.json'
$CafeOwnerId = 'cafe-fausse-api07-prompt16-20260823'
$CafeContainedRoot = [IO.Path]::GetFullPath(
    (Join-Path $CafeTemporaryBase 'CafeFausse-api07-contained-api06-tests')
).TrimEnd('\')
$CafeContainedMarker = Join-Path $CafeContainedRoot 'ownership.json'
$CafeInterruptionProcessMarker = Join-Path $CafeRoot 'interruption-processes.json'
$CafeInterruptionOwnerId = 'cafe-fausse-api07-actual-interruption-20260823'
$CafeInterruptionReady = Join-Path $CafeRoot 'interruption-ready.json'
$CafeInterruptionControl = Join-Path $CafeRoot 'interruption-control.json'
$CafeCreated = $false
$CafeLeaveInterruptionState = $false
$CafeContainedProcess = $null
$CafePriorTemp = [Environment]::GetEnvironmentVariable('TEMP', 'Process')
$CafePriorTmp = [Environment]::GetEnvironmentVariable('TMP', 'Process')

function Test-CafeOwnership {
    param([switch]$RequireExists)
    if ($CafeRoot -cne $CafeExpectedRoot) {
        throw 'API-07 root canonical-path validation failed.'
    }
    if (-not (Test-Path -LiteralPath $CafeRoot -PathType Container)) {
        if ($RequireExists) { throw 'The API-07 owned root is absent.' }
        return $false
    }
    $CafeItem = Get-Item -LiteralPath $CafeRoot -Force -ErrorAction Stop
    if (($CafeItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing an API-07 root that is a reparse point.'
    }
    if (-not (Test-Path -LiteralPath $CafeMarker -PathType Leaf)) {
        throw 'Refusing an API-07 root without its ownership marker.'
    }
    $CafeMarkerItem = Get-Item -LiteralPath $CafeMarker -Force -ErrorAction Stop
    if (($CafeMarkerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing an API-07 ownership marker that is a reparse point.'
    }
    $CafeStored = Get-Content -LiteralPath $CafeMarker -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($CafeStored.task -cne 'API-07' -or
        $CafeStored.phase -cne 'Prompt-16' -or
        $CafeStored.purpose -cne 'reservation context and availability verification' -or
        $CafeStored.repository -cne $CafeRepository -or
        $CafeStored.owner_id -cne $CafeOwnerId -or
        $CafeStored.root -cne $CafeRoot) {
        throw 'Refusing an API-07 root whose ownership marker does not match.'
    }
    return $true
}

function Test-CafeContainedOwnership {
    param([switch]$RequireExists)
    $CafeApi07Parent = [IO.Path]::GetDirectoryName($CafeRoot)
    $CafeContainedParent = [IO.Path]::GetDirectoryName($CafeContainedRoot)
    if (-not $CafeApi07Parent.Equals(
        $CafeContainedParent,
        [StringComparison]::OrdinalIgnoreCase
    ) -or
        $CafeContainedRoot.StartsWith(
            ($CafeRoot + [IO.Path]::DirectorySeparatorChar),
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        $CafeRoot.StartsWith(
            ($CafeContainedRoot + [IO.Path]::DirectorySeparatorChar),
            [StringComparison]::OrdinalIgnoreCase
        )) {
        throw 'The API-07 and contained API-06 roots are not exact shallow siblings.'
    }
    if (-not (Test-Path -LiteralPath $CafeContainedRoot -PathType Container)) {
        if ($RequireExists) { throw 'The contained API-06 owned root is absent.' }
        return $false
    }
    $CafeContainedItem = Get-Item -LiteralPath $CafeContainedRoot -Force -ErrorAction Stop
    if (($CafeContainedItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing a contained API-06 root that is a reparse point.'
    }
    if (-not (Test-Path -LiteralPath $CafeContainedMarker -PathType Leaf)) {
        throw 'Refusing a contained API-06 root without its ownership marker.'
    }
    $CafeContainedMarkerItem = Get-Item -LiteralPath $CafeContainedMarker -Force -ErrorAction Stop
    if (($CafeContainedMarkerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing a contained API-06 marker that is a reparse point.'
    }
    $CafeContainedEvidence = Get-Content -LiteralPath $CafeContainedMarker -Raw -Encoding UTF8 |
        ConvertFrom-Json
    if ($CafeContainedEvidence.repository -cne $CafeRepository -or
        $CafeContainedEvidence.task -cne 'API-06' -or
        $CafeContainedEvidence.phase -cne 'Prompt-16-contained-regression' -or
        $CafeContainedEvidence.purpose -cne 'contained API-06 regression and PostgreSQL verification for API-07' -or
        $CafeContainedEvidence.owner_id -cne 'cafe-fausse-api07-contained-api06-20260823' -or
        $CafeContainedEvidence.root -cne $CafeContainedRoot -or
        [int]$CafeContainedEvidence.port -ne 55446 -or
        $CafeContainedEvidence.database -cne 'cafe_fausse_test_api06') {
        throw 'Refusing a contained API-06 root whose ownership marker does not match.'
    }
    return $true
}

function Stop-CafeOwnedContainedCluster {
    Test-CafeOwnership -RequireExists | Out-Null
    if (-not (Test-CafeContainedOwnership)) {
        $CafeUnexpectedListeners = @(
            Get-NetTCPConnection -State Listen -LocalPort 55446 -ErrorAction SilentlyContinue
        )
        if ($CafeUnexpectedListeners.Count -ne 0) {
            throw 'Port 55446 is occupied without the expected contained API-06 root.'
        }
        return
    }
    $CafeData = Join-Path $CafeContainedRoot 'data'
    $CafeDataMarker = Join-Path $CafeContainedRoot '.data.ownership.json'
    $CafePgCtl = 'C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe'
    $CafeExpectedPostgres = 'C:\Program Files\PostgreSQL\18\bin\postgres.exe'
    $CafeContainedPort = 55446
    if (Test-Path -LiteralPath $CafeData -PathType Container) {
        if (-not (Test-Path -LiteralPath $CafeDataMarker -PathType Leaf)) {
            throw 'Refusing recovery because the contained PostgreSQL data marker is absent.'
        }
        $CafeDataItem = Get-Item -LiteralPath $CafeData -Force -ErrorAction Stop
        $CafeDataMarkerItem = Get-Item -LiteralPath $CafeDataMarker -Force -ErrorAction Stop
        if (($CafeDataItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
            ($CafeDataMarkerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'Refusing recovery because the contained data root or marker is a reparse point.'
        }
        $CafeDataEvidence = Get-Content -LiteralPath $CafeDataMarker -Raw -Encoding UTF8 |
            ConvertFrom-Json
        if ($CafeDataEvidence.repository -cne $CafeRepository -or
            $CafeDataEvidence.task -cne 'API-06' -or
            $CafeDataEvidence.phase -cne 'Prompt-16-contained-regression' -or
            $CafeDataEvidence.purpose -cne 'disposable PostgreSQL 18.3 data' -or
            $CafeDataEvidence.owner_id -cne 'cafe-fausse-api07-contained-api06-20260823-data' -or
            $CafeDataEvidence.root -cne $CafeData) {
            throw 'Refusing recovery because the contained data marker does not match.'
        }
        $CafePgVersion = Join-Path $CafeData 'PG_VERSION'
        if (-not (Test-Path -LiteralPath $CafePgVersion -PathType Leaf)) {
            $CafeUnexpectedListeners = @(
                Get-NetTCPConnection -State Listen -LocalPort $CafeContainedPort `
                    -ErrorAction SilentlyContinue
            )
            if ($CafeUnexpectedListeners.Count -ne 0) {
                throw 'Refusing recovery because port 55446 is occupied but the owned cluster is incomplete.'
            }
            return
        }
        $CafePgVersionItem = Get-Item -LiteralPath $CafePgVersion -Force -ErrorAction Stop
        if (($CafePgVersionItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw 'Refusing recovery because the nested PG_VERSION is a reparse point.'
        }
        $CafeStatus = & $CafePgCtl -D $CafeData status 2>&1
        $CafeStatusCode = $LASTEXITCODE
        if ($CafeStatusCode -eq 0) {
            $CafePostmasterPidPath = Join-Path $CafeData 'postmaster.pid'
            if (-not (Test-Path -LiteralPath $CafePostmasterPidPath -PathType Leaf)) {
                throw 'Refusing recovery because a running cluster has no postmaster PID file.'
            }
            $CafePostmasterPidItem = Get-Item -LiteralPath $CafePostmasterPidPath -Force -ErrorAction Stop
            if (($CafePostmasterPidItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Refusing recovery because the postmaster PID file is a reparse point.'
            }
            $CafePostmasterPid = 0
            $CafePostmasterPidText = Get-Content -LiteralPath $CafePostmasterPidPath -TotalCount 1
            if (-not [int]::TryParse($CafePostmasterPidText, [ref]$CafePostmasterPid) -or
                $CafePostmasterPid -le 0) {
                throw 'Refusing recovery because the postmaster PID is invalid.'
            }
            $CafePostmasterProcess = Get-Process -Id $CafePostmasterPid -ErrorAction Stop
            $CafePostmasterPath = [IO.Path]::GetFullPath($CafePostmasterProcess.Path)
            if (-not [string]::Equals(
                $CafePostmasterPath,
                $CafeExpectedPostgres,
                [StringComparison]::OrdinalIgnoreCase
            )) {
                throw 'Refusing recovery because the owned postmaster executable does not match PostgreSQL 18.'
            }
            $CafeContainedListeners = @(
                Get-NetTCPConnection -State Listen -LocalPort $CafeContainedPort `
                    -ErrorAction Stop
            )
            $CafeContainedListenerOwners = @(
                $CafeContainedListeners | ForEach-Object OwningProcess | Sort-Object -Unique
            )
            if ($CafeContainedListenerOwners.Count -ne 1 -or
                [int]$CafeContainedListenerOwners[0] -ne $CafePostmasterPid) {
                throw 'Refusing recovery because port 55446 ownership does not match the owned postmaster.'
            }
            & $CafePgCtl -D $CafeData -m fast -w stop
            if ($LASTEXITCODE -ne 0) {
                throw 'The owned interrupted PostgreSQL cluster could not be stopped.'
            }
        }
        elseif ($CafeStatusCode -ne 3) {
            throw 'The owned interrupted PostgreSQL cluster status could not be established.'
        }
        $CafeStoppedStatus = & $CafePgCtl -D $CafeData status 2>&1
        $CafeStoppedStatusCode = $LASTEXITCODE
        if ($CafeStoppedStatusCode -ne 3 -or
            ($CafeStoppedStatus -join [Environment]::NewLine) -notmatch 'no server running') {
            throw 'The owned interrupted PostgreSQL cluster could not be proven stopped.'
        }
    }
    $CafeListenersAfterStop = @(
        Get-NetTCPConnection -State Listen -LocalPort $CafeContainedPort `
            -ErrorAction SilentlyContinue
    )
    if ($CafeListenersAfterStop.Count -ne 0) {
        throw 'Port 55446 still has a listener after nested PostgreSQL shutdown.'
    }
}

function Get-CafeSha256Text {
    param([Parameter(Mandatory = $true)][string]$Text)
    $CafeSha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $CafeHashBytes = $CafeSha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
        return ([BitConverter]::ToString($CafeHashBytes)).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $CafeSha256.Dispose()
    }
}

function Write-CafeDurableJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )
    $CafeBytes = [Text.UTF8Encoding]::new($false).GetBytes(
        (($Value | ConvertTo-Json -Depth 6 -Compress) + "`n")
    )
    $CafeStream = New-Object IO.FileStream(
        $Path,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None,
        4096,
        [IO.FileOptions]::WriteThrough
    )
    try {
        $CafeStream.Write($CafeBytes, 0, $CafeBytes.Length)
        $CafeStream.Flush($true)
    }
    finally {
        $CafeStream.Dispose()
    }
}

function Write-CafeInterruptionAbortControl {
    param([Parameter(Mandatory = $true)][int]$ProcessId)
    Test-CafeOwnership -RequireExists | Out-Null
    if (Test-Path -LiteralPath $CafeInterruptionControl) {
        throw 'Refusing to overwrite an interruption control file.'
    }
    $CafeControl = [ordered]@{
        repository = $CafeRepository
        task = 'API-07'
        phase = 'Prompt-16-actual-interruption-recovery'
        purpose = 'abort contained runner before interruption ownership was completed'
        owner_id = 'cafe-fausse-api07-interruption-abort-20260823'
        outer_root = $CafeRoot
        contained_root = $CafeContainedRoot
        pid = $ProcessId
        action = 'abort'
    }
    Write-CafeDurableJson -Path $CafeInterruptionControl -Value $CafeControl
}

function Wait-CafeInterruptionStateAndWriteProcessEvidence {
    param([Parameter(Mandatory = $true)][Diagnostics.Process]$Process)
    $CafeContainedRunnerPath = [IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot 'run_api06.ps1')
    )
    $CafeExpectedPowerShell = [IO.Path]::GetFullPath(
        "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    )
    $CafePgCtl = 'C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe'
    $CafeExpectedPostgres = 'C:\Program Files\PostgreSQL\18\bin\postgres.exe'
    $CafeData = Join-Path $CafeContainedRoot 'data'
    $CafePostmasterPidPath = Join-Path $CafeData 'postmaster.pid'
    $CafeDeadline = [DateTime]::UtcNow.AddMinutes(5)
    $CafePostmasterPid = 0
    $CafeCurrentProcess = $null
    while ([DateTime]::UtcNow -lt $CafeDeadline) {
        if ($Process.HasExited) {
            throw "The contained API-06 runner exited before interruption readiness: $($Process.ExitCode)"
        }
        if ((Test-Path -LiteralPath $CafeInterruptionReady -PathType Leaf) -and
            (Test-CafeContainedOwnership) -and
            (Test-Path -LiteralPath $CafePostmasterPidPath -PathType Leaf)) {
            $CafeReadyItem = Get-Item -LiteralPath $CafeInterruptionReady -Force -ErrorAction Stop
            $CafePidItem = Get-Item -LiteralPath $CafePostmasterPidPath -Force -ErrorAction Stop
            if (($CafeReadyItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
                ($CafePidItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Interruption readiness or postmaster PID evidence is a reparse point.'
            }
            $CafeReady = Get-Content -LiteralPath $CafeInterruptionReady -Raw -Encoding UTF8 |
                ConvertFrom-Json
            if ($CafeReady.repository -cne $CafeRepository -or
                $CafeReady.task -cne 'API-07' -or
                $CafeReady.phase -cne 'Prompt-16-actual-interruption-recovery' -or
                $CafeReady.purpose -cne 'contained API-06 runner readiness for owned interruption proof' -or
                $CafeReady.owner_id -cne 'cafe-fausse-api07-interruption-ready-20260823' -or
                $CafeReady.outer_root -cne $CafeRoot -or
                $CafeReady.contained_root -cne $CafeContainedRoot -or
                [int]$CafeReady.pid -ne $Process.Id -or
                [int]$CafeReady.port -ne 55446) {
                throw 'The contained runner readiness evidence does not match.'
            }
            $CafePidText = Get-Content -LiteralPath $CafePostmasterPidPath -TotalCount 1 `
                -ErrorAction SilentlyContinue
            $CafeCandidatePid = 0
            if ([int]::TryParse([string]$CafePidText, [ref]$CafeCandidatePid) -and
                $CafeCandidatePid -gt 0) {
                $CafePostmaster = Get-Process -Id $CafeCandidatePid -ErrorAction SilentlyContinue
                if ($null -ne $CafePostmaster -and
                    [string]::Equals(
                        [IO.Path]::GetFullPath($CafePostmaster.Path),
                        $CafeExpectedPostgres,
                        [StringComparison]::OrdinalIgnoreCase
                    )) {
                    $CafeStatus = & $CafePgCtl -D $CafeData status 2>&1
                    $CafeStatusCode = $LASTEXITCODE
                    $CafeListeners = @(
                        Get-NetTCPConnection -State Listen -LocalPort 55446 `
                            -ErrorAction SilentlyContinue
                    )
                    $CafeOwners = @(
                        $CafeListeners | ForEach-Object OwningProcess | Sort-Object -Unique
                    )
                    if ($CafeStatusCode -eq 0 -and
                        $CafeOwners.Count -eq 1 -and
                        [int]$CafeOwners[0] -eq $CafeCandidatePid) {
                        $CafeCurrentProcess = Get-CimInstance Win32_Process `
                            -Filter "ProcessId = $($Process.Id)" -ErrorAction Stop
                        if ($null -ne $CafeCurrentProcess) {
                            $CafePostmasterPid = $CafeCandidatePid
                            break
                        }
                    }
                }
            }
        }
        Start-Sleep -Milliseconds 200
    }
    if ($CafePostmasterPid -le 0 -or $null -eq $CafeCurrentProcess) {
        throw 'Timed out before the contained runner and PostgreSQL identity were fully proven.'
    }
    $CafeCurrentExecutable = [IO.Path]::GetFullPath([string]$CafeCurrentProcess.ExecutablePath)
    if (-not [string]::Equals(
            $CafeCurrentExecutable,
            $CafeExpectedPowerShell,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        [string]$CafeCurrentProcess.Name -ine 'powershell.exe' -or
        [int]$CafeCurrentProcess.ParentProcessId -ne $PID -or
        -not $CafeCurrentProcess.CommandLine -or
        $CafeCurrentProcess.CommandLine.IndexOf(
            $CafeContainedRunnerPath,
            [StringComparison]::OrdinalIgnoreCase
        ) -lt 0 -or
        $CafeCurrentProcess.CommandLine.IndexOf(
            $CafeContainedRoot,
            [StringComparison]::OrdinalIgnoreCase
        ) -lt 0) {
        throw 'The held contained-runner process identity does not match.'
    }
    $CafePsProcess = Get-Process -Id $Process.Id -ErrorAction Stop
    $CafeCommandHash = Get-CafeSha256Text -Text ([string]$CafeCurrentProcess.CommandLine)
    $CafeProcessEvidence = [ordered]@{
        task = 'API-07'
        phase = 'Prompt-16-actual-interruption-recovery'
        purpose = 'durable ownership for the intentionally held contained API-06 runner'
        repository = $CafeRepository
        owner_id = $CafeInterruptionOwnerId
        outer_root = $CafeRoot
        contained_root = $CafeContainedRoot
        relationship = 'contained run_api06.ps1 child using an independently owned sibling root'
        postmaster_pid = $CafePostmasterPid
        processes = @([ordered]@{
            pid = $Process.Id
            executable_path = $CafeExpectedPowerShell
            executable_name = 'powershell.exe'
            process_purpose = 'contained API-06 runner held for actual interruption recovery proof'
            process_relationship = 'child runner operating the independently owned sibling API-06 root'
            parent_pid = $PID
            command_line_sha256 = $CafeCommandHash
            start_time_utc_ticks = $CafePsProcess.StartTime.ToUniversalTime().Ticks
        })
    }
    Write-CafeDurableJson -Path $CafeInterruptionProcessMarker -Value $CafeProcessEvidence
    $CafeMarkerItem = Get-Item -LiteralPath $CafeInterruptionProcessMarker -Force -ErrorAction Stop
    if (($CafeMarkerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'The durable interruption-process marker is a reparse point.'
    }
    $CafeRoundTrip = Get-Content -LiteralPath $CafeInterruptionProcessMarker -Raw -Encoding UTF8 |
        ConvertFrom-Json
    if ($CafeRoundTrip.repository -cne $CafeRepository -or
        $CafeRoundTrip.owner_id -cne $CafeInterruptionOwnerId -or
        $CafeRoundTrip.outer_root -cne $CafeRoot -or
        $CafeRoundTrip.contained_root -cne $CafeContainedRoot -or
        [int]$CafeRoundTrip.postmaster_pid -ne $CafePostmasterPid -or
        @($CafeRoundTrip.processes).Count -ne 1 -or
        [int]$CafeRoundTrip.processes[0].pid -ne $Process.Id -or
        $CafeRoundTrip.processes[0].command_line_sha256 -cne $CafeCommandHash) {
        throw 'The durable interruption-process marker failed round-trip validation.'
    }
    $CafeRecheck = Get-CimInstance Win32_Process -Filter "ProcessId = $($Process.Id)" `
        -ErrorAction Stop
    $CafeFinalListeners = @(
        Get-NetTCPConnection -State Listen -LocalPort 55446 -ErrorAction Stop
    )
    $CafeFinalOwners = @(
        $CafeFinalListeners | ForEach-Object OwningProcess | Sort-Object -Unique
    )
    if ($null -eq $CafeRecheck -or -not $CafeRecheck.CommandLine) {
        throw 'The owned contained process disappeared after marker validation.'
    }
    $CafeRecheckHash = Get-CafeSha256Text -Text ([string]$CafeRecheck.CommandLine)
    if ($CafeRecheckHash -cne [string]$CafeRoundTrip.processes[0].command_line_sha256 -or
        $CafeFinalOwners.Count -ne 1 -or
        [int]$CafeFinalOwners[0] -ne $CafePostmasterPid) {
        throw 'Process or listener identity changed after durable marker validation.'
    }
    return $CafePostmasterPid
}

function Stop-CafeOwnedInterruptionProcesses {
    Test-CafeOwnership -RequireExists | Out-Null
    Test-CafeContainedOwnership -RequireExists | Out-Null
    $CafeContainedRunnerPath = [IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot 'run_api06.ps1')
    )
    if (-not (Test-Path -LiteralPath $CafeInterruptionProcessMarker)) {
        if (Test-Path -LiteralPath $CafeContainedRoot) {
            $CafeUnmarkedContainedRunners = @(
                Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
                    Where-Object {
                        $_.CommandLine -and
                        $_.CommandLine.IndexOf(
                            $CafeContainedRunnerPath,
                            [StringComparison]::OrdinalIgnoreCase
                        ) -ge 0
                    }
            )
            if ($CafeUnmarkedContainedRunners.Count -ne 0) {
                throw 'Refusing cleanup because a contained runner exists without durable process ownership evidence.'
            }
        }
        return
    }
    if (-not (Test-Path -LiteralPath $CafeInterruptionProcessMarker -PathType Leaf)) {
        throw 'Refusing cleanup because the interruption-process marker is not a leaf file.'
    }
    $CafeProcessMarkerItem = Get-Item -LiteralPath $CafeInterruptionProcessMarker -Force -ErrorAction Stop
    if (($CafeProcessMarkerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Refusing cleanup because the interruption-process marker is a reparse point.'
    }
    $CafeProcessEvidence = Get-Content -LiteralPath $CafeInterruptionProcessMarker `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($CafeProcessEvidence.task -cne 'API-07' -or
        $CafeProcessEvidence.phase -cne 'Prompt-16-actual-interruption-recovery' -or
        $CafeProcessEvidence.purpose -cne 'durable ownership for the intentionally held contained API-06 runner' -or
        $CafeProcessEvidence.repository -cne $CafeRepository -or
        $CafeProcessEvidence.owner_id -cne $CafeInterruptionOwnerId -or
        $CafeProcessEvidence.outer_root -cne $CafeRoot -or
        $CafeProcessEvidence.contained_root -cne $CafeContainedRoot -or
        $CafeProcessEvidence.relationship -cne 'contained run_api06.ps1 child using an independently owned sibling root') {
        throw 'Refusing cleanup because the interruption-process ownership marker does not match.'
    }
    $CafeProcesses = @($CafeProcessEvidence.processes)
    if ($CafeProcesses.Count -ne 1) {
        throw 'Refusing cleanup because exactly one intentionally preserved process was not recorded.'
    }
    $CafeRecordedProcess = $CafeProcesses[0]
    $CafeRecordedPid = 0
    if (-not [int]::TryParse([string]$CafeRecordedProcess.pid, [ref]$CafeRecordedPid) -or
        $CafeRecordedPid -le 0 -or
        -not [string]::Equals(
            [string]$CafeRecordedProcess.executable_path,
            "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe",
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        $CafeRecordedProcess.executable_name -ine 'powershell.exe' -or
        $CafeRecordedProcess.process_purpose -cne 'contained API-06 runner held for actual interruption recovery proof' -or
        $CafeRecordedProcess.process_relationship -cne 'child runner operating the independently owned sibling API-06 root') {
        throw 'Refusing cleanup because the recorded interruption process identity is invalid.'
    }
    $CafeCurrentProcess = Get-CimInstance Win32_Process `
        -Filter "ProcessId = $CafeRecordedPid" -ErrorAction SilentlyContinue
    if ($null -eq $CafeCurrentProcess) {
        $CafeUnexpectedContainedRunners = @(
            Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
                Where-Object {
                    $_.CommandLine -and
                    $_.CommandLine.IndexOf(
                        $CafeContainedRunnerPath,
                        [StringComparison]::OrdinalIgnoreCase
                    ) -ge 0 -and
                    $_.CommandLine.IndexOf(
                        $CafeContainedRoot,
                        [StringComparison]::OrdinalIgnoreCase
                    ) -ge 0
                }
        )
        if ($CafeUnexpectedContainedRunners.Count -ne 0) {
            throw 'Refusing cleanup because another process corresponds to the recorded contained interruption state.'
        }
        Write-Host 'API07 RECOVERY EVIDENCE: the durably recorded interruption process is already absent.'
        return
    }
    $CafeCurrentExecutable = [IO.Path]::GetFullPath([string]$CafeCurrentProcess.ExecutablePath)
    if (-not [string]::Equals(
            $CafeCurrentExecutable,
            [string]$CafeRecordedProcess.executable_path,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        [string]$CafeCurrentProcess.Name -ine [string]$CafeRecordedProcess.executable_name -or
        [int]$CafeCurrentProcess.ParentProcessId -ne [int]$CafeRecordedProcess.parent_pid -or
        -not $CafeCurrentProcess.CommandLine -or
        (Get-CafeSha256Text -Text ([string]$CafeCurrentProcess.CommandLine)) -cne
            [string]$CafeRecordedProcess.command_line_sha256) {
        throw 'Refusing cleanup because the current interruption process no longer matches its durable identity.'
    }
    $CafeCurrentPsProcess = Get-Process -Id $CafeRecordedPid -ErrorAction Stop
    if ($CafeCurrentPsProcess.StartTime.ToUniversalTime().Ticks -ne
        [long]$CafeRecordedProcess.start_time_utc_ticks) {
        throw 'Refusing cleanup because the interruption PID was reused or its start time changed.'
    }
    if ($CafeCurrentProcess.CommandLine.IndexOf(
        $CafeContainedRunnerPath,
        [StringComparison]::OrdinalIgnoreCase
    ) -lt 0) {
        throw 'Refusing cleanup because the marked process is not the contained API-06 runner.'
    }
    Stop-Process -Id $CafeRecordedPid -Force -ErrorAction Stop
    $CafeProcessStopDeadline = [DateTime]::UtcNow.AddSeconds(15)
    while ([DateTime]::UtcNow -lt $CafeProcessStopDeadline -and
        (Get-Process -Id $CafeRecordedPid -ErrorAction SilentlyContinue)) {
        Start-Sleep -Milliseconds 100
    }
    if (Get-Process -Id $CafeRecordedPid -ErrorAction SilentlyContinue) {
        throw 'The owned interruption process could not be terminated.'
    }
    $CafeRemainingContainedRunners = @(
        Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" |
            Where-Object {
                $_.CommandLine -and
                $_.CommandLine.IndexOf(
                    $CafeContainedRunnerPath,
                    [StringComparison]::OrdinalIgnoreCase
                ) -ge 0 -and
                $_.CommandLine.IndexOf(
                    $CafeContainedRoot,
                    [StringComparison]::OrdinalIgnoreCase
                ) -ge 0
            }
    )
    if ($CafeRemainingContainedRunners.Count -ne 0) {
        throw 'A process still corresponds to the contained interruption state after recovery.'
    }
}

function Assert-CafeNoReparseDescendants {
    param([Parameter(Mandatory = $true)][string]$Root)
    $CafeResolved = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    $CafeProviderRoot = (Resolve-Path -LiteralPath $CafeResolved -ErrorAction Stop).ProviderPath.TrimEnd('\')
    $CafeShortPrefix = $CafeResolved + [IO.Path]::DirectorySeparatorChar
    $CafeProviderPrefix = $CafeProviderRoot + [IO.Path]::DirectorySeparatorChar
    $CafePending = New-Object 'System.Collections.Generic.Queue[string]'
    $CafePending.Enqueue($CafeResolved)
    while ($CafePending.Count -gt 0) {
        $CafeDirectory = $CafePending.Dequeue()
        foreach ($CafeEntry in [IO.Directory]::EnumerateFileSystemEntries($CafeDirectory)) {
            $CafeFullEntry = [IO.Path]::GetFullPath($CafeEntry)
            if (-not $CafeFullEntry.StartsWith($CafeShortPrefix, [StringComparison]::OrdinalIgnoreCase) -and
                -not $CafeFullEntry.StartsWith($CafeProviderPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                throw 'Refusing cleanup because a descendant escapes its exact owned root.'
            }
            $CafeAttributes = [IO.File]::GetAttributes($CafeFullEntry)
            if (($CafeAttributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw 'Refusing cleanup because a descendant is a reparse point or symlink.'
            }
            if (($CafeAttributes -band [IO.FileAttributes]::Directory) -ne 0) {
                $CafePending.Enqueue($CafeFullEntry)
            }
        }
    }
}

function Remove-CafeOwnedContainedRoot {
    if (-not (Test-CafeContainedOwnership)) {
        return
    }
    $CafeListeners = @(
        Get-NetTCPConnection -State Listen -LocalPort 55446 -ErrorAction SilentlyContinue
    )
    if ($CafeListeners.Count -ne 0) {
        throw 'Refusing contained-root deletion while port 55446 has a listener.'
    }
    Assert-CafeNoReparseDescendants -Root $CafeContainedRoot
    Test-CafeContainedOwnership -RequireExists | Out-Null
    Remove-Item -LiteralPath $CafeContainedRoot -Recurse -Force -ErrorAction Stop
    if (Test-Path -LiteralPath $CafeContainedRoot) {
        throw 'The exact contained API-06 owned root survived cleanup.'
    }
}

function Remove-CafeOwnedRoot {
    if (-not (Test-CafeOwnership -RequireExists)) {
        throw 'API-07 cleanup ownership validation failed.'
    }
    Stop-CafeOwnedContainedCluster
    if (Test-Path -LiteralPath $CafeContainedRoot) {
        Stop-CafeOwnedInterruptionProcesses
        Remove-CafeOwnedContainedRoot
    } elseif (Test-Path -LiteralPath $CafeInterruptionProcessMarker) {
        throw 'Refusing cleanup because process evidence exists without its contained owned root.'
    }
    $CafeResolved = [IO.Path]::GetFullPath($CafeRoot).TrimEnd('\')
    if ($CafeResolved -cne $CafeExpectedRoot) {
        throw 'API-07 cleanup target changed after validation.'
    }
    Assert-CafeNoReparseDescendants -Root $CafeResolved
    Test-CafeOwnership -RequireExists | Out-Null
    Remove-Item -LiteralPath $CafeResolved -Recurse -Force -ErrorAction Stop
    if (Test-Path -LiteralPath $CafeResolved) {
        throw 'API-07 owned-root cleanup did not remove the exact target.'
    }
}

if ($PrepareInterruptionState -and
    ($CleanupOwnedRoot -or $InjectFailure -or $InjectCleanupFailure)) {
    throw 'Interruption preparation cannot be combined with cleanup or controlled-failure switches.'
}

if ($CleanupOwnedRoot) {
    Test-CafeOwnership -RequireExists | Out-Null
    Remove-CafeOwnedRoot
    Write-Host "API07 CLEANUP PASS: exact marker-owned root is absent: $CafeRoot"
    exit 0
}

try {
    if (Test-Path -LiteralPath $CafeRoot) {
        throw 'Refusing a preexisting or ambiguous API-07 test root. Use -CleanupOwnedRoot only when its durable marker is valid.'
    }
    New-Item -ItemType Directory -Path $CafeRoot -ErrorAction Stop | Out-Null
    $CafeCreated = $true
    $CafeRootItem = Get-Item -LiteralPath $CafeRoot -Force -ErrorAction Stop
    if (($CafeRootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'The newly created API-07 root is a reparse point.'
    }
    $CafeMarkerValue = [ordered]@{
        task = 'API-07'
        phase = 'Prompt-16'
        purpose = 'reservation context and availability verification'
        repository = $CafeRepository
        owner_id = $CafeOwnerId
        root = $CafeRoot
    }
    Write-CafeDurableJson -Path $CafeMarker -Value $CafeMarkerValue
    Test-CafeOwnership -RequireExists | Out-Null

    $CafeArguments = @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass',
        '-File', (Join-Path $PSScriptRoot 'run_api06.ps1'),
        '-NonProductionClusterAuthorization', $NonProductionClusterAuthorization,
        '-OwnershipContext', 'API-07-contained',
        '-ExplicitOwnedRoot', $CafeContainedRoot
    )
    if ($InjectFailure) { $CafeArguments += '-InjectFailure' }
    if ($InjectCleanupFailure) { $CafeArguments += '-InjectCleanupFailure' }
    if ($PrepareInterruptionState) {
        $CafeArguments += @('-InterruptionHold', '-Api07OwnedRoot', $CafeRoot)
        $CafeContainedProcess = Start-Process `
            -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
            -ArgumentList $CafeArguments `
            -WindowStyle Hidden `
            -PassThru
        $CafeOwnedPostmasterPid = Wait-CafeInterruptionStateAndWriteProcessEvidence `
            -Process $CafeContainedProcess
        $CafeLeaveInterruptionState = $true
        Write-Host 'API07 INTERRUPTION EVIDENCE: actual run_api07.ps1 -> run_api06.ps1 workflow is durably owned and held.'
        Write-Host "API07 INTERRUPTION EVIDENCE: contained runner PID $($CafeContainedProcess.Id); owned PostgreSQL PID $CafeOwnedPostmasterPid; port 55446."
    } else {
        & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" @CafeArguments
        $CafeExitCode = $LASTEXITCODE
        if ($CafeExitCode -ne 0) {
            throw "The contained complete backend verification failed with exit code $CafeExitCode."
        }
        if (Test-Path -LiteralPath $CafeContainedRoot) {
            throw 'The contained runner left its independently owned sibling root behind.'
        }
        Write-Host 'API07 TEST PASS: unit/API, PostgreSQL integration, concurrency, complete branch coverage, and API-04 through API-06 regressions passed.'
    }
}
catch {
    $CafeFailure = $_
    if ($null -ne $CafeContainedProcess -and
        -not $CafeContainedProcess.HasExited -and
        -not (Test-Path -LiteralPath $CafeInterruptionProcessMarker)) {
        Write-CafeInterruptionAbortControl -ProcessId $CafeContainedProcess.Id
        $CafeContainedProcess.WaitForExit()
    }
    if ($InjectCleanupFailure) {
        Write-Error 'API07 CONTROLLED CLEANUP FAILURE: preserving the marker-owned root for an explicit later -CleanupOwnedRoot recovery.'
        throw $CafeFailure
    }
    if ($CafeCreated -and (Test-Path -LiteralPath $CafeRoot)) {
        try {
            Remove-CafeOwnedRoot
        }
        catch {
            Write-Error 'API07 CLEANUP FAILURE: exact ownership could not be revalidated or cleanup failed; the root is preserved for inspection.'
            throw
        }
    }
    throw $CafeFailure
}
finally {
    if ($null -eq $CafePriorTemp) { Remove-Item Env:TEMP -ErrorAction SilentlyContinue } else { $env:TEMP = $CafePriorTemp }
    if ($null -eq $CafePriorTmp) { Remove-Item Env:TMP -ErrorAction SilentlyContinue } else { $env:TMP = $CafePriorTmp }
}

if ($CafeLeaveInterruptionState) {
    Write-Host 'API07 INTERRUPTION STATE READY: outer runner is exiting only after durable process evidence was flushed and validated.'
    exit 86
}

Remove-CafeOwnedRoot
Write-Host "API07 CLEANUP EVIDENCE: exact marker-owned root is absent: $CafeRoot"
Write-Host 'API07 CLEANUP EVIDENCE: TEMP and TMP were not redirected into either owned runner root and their original values remain restored.'
