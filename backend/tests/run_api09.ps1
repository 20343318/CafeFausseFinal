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
$CafeInitialHead = (& git -C $CafeRepository rev-parse HEAD).Trim()
$CafeInitialIndex = (@(& git -C $CafeRepository diff --cached --name-only) -join "`n")
$CafeApi08Runner = Join-Path $PSScriptRoot 'run_api08.ps1'

function Test-CafePowerShellSyntax {
    $CafeScripts = @(
        (Join-Path $PSScriptRoot 'run_api06.ps1'),
        (Join-Path $PSScriptRoot 'run_api07.ps1'),
        (Join-Path $PSScriptRoot 'run_api08.ps1'),
        $PSCommandPath
    )
    foreach ($CafeScript in $CafeScripts) {
        $CafeTokens = $null
        $CafeErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $CafeScript,
            [ref]$CafeTokens,
            [ref]$CafeErrors
        ) | Out-Null
        if ($CafeErrors.Count -ne 0) {
            throw "PowerShell parsing failed for $CafeScript"
        }
    }

    $CafeInstructions = Get-Content -LiteralPath (
        Join-Path $CafeRepository 'backend\TestInstructions.md'
    ) -Raw -Encoding UTF8
    $CafeBlocks = [regex]::Matches(
        $CafeInstructions,
        '(?ms)```powershell\s*\r?\n(.*?)\r?\n```'
    )
    foreach ($CafeBlock in $CafeBlocks) {
        $CafeTokens = $null
        $CafeErrors = $null
        [System.Management.Automation.Language.Parser]::ParseInput(
            $CafeBlock.Groups[1].Value,
            [ref]$CafeTokens,
            [ref]$CafeErrors
        ) | Out-Null
        if ($CafeErrors.Count -ne 0) {
            throw 'A PowerShell block in backend/TestInstructions.md did not parse.'
        }
    }
    Write-Host "API09 STATIC PASS: four runner scripts and $($CafeBlocks.Count) TestInstructions PowerShell blocks parsed."
}

function Test-CafePythonCompilation {
    $CafeTemporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $CafeCompilationRoot = Join-Path $CafeTemporaryBase (
        'CafeFausse-api09-compilation-' + [guid]::NewGuid().ToString('N')
    )
    $CafeMarker = Join-Path $CafeCompilationRoot 'ownership.txt'
    $CafePriorCache = [Environment]::GetEnvironmentVariable('PYTHONPYCACHEPREFIX', 'Process')
    try {
        New-Item -ItemType Directory -Path $CafeCompilationRoot -ErrorAction Stop | Out-Null
        Set-Content -LiteralPath $CafeMarker -Value $CafeRepository -Encoding UTF8 -NoNewline
        $env:PYTHONPYCACHEPREFIX = Join-Path $CafeCompilationRoot 'pycache'
        & 'C:\Python314\python.exe' -m compileall -q `
            (Join-Path $CafeRepository 'backend\src') `
            (Join-Path $CafeRepository 'backend\tests')
        if ($LASTEXITCODE -ne 0) {
            throw 'API-09 Python compilation failed.'
        }
    }
    finally {
        if ($null -eq $CafePriorCache) {
            Remove-Item Env:PYTHONPYCACHEPREFIX -ErrorAction SilentlyContinue
        } else {
            $env:PYTHONPYCACHEPREFIX = $CafePriorCache
        }
        $CafeResolved = [IO.Path]::GetFullPath($CafeCompilationRoot).TrimEnd('\')
        $CafeExpectedPrefix = $CafeTemporaryBase + [IO.Path]::DirectorySeparatorChar
        if (-not $CafeResolved.StartsWith($CafeExpectedPrefix, [StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $CafeMarker -PathType Leaf) -or
            (Get-Content -LiteralPath $CafeMarker -Raw -Encoding UTF8) -cne $CafeRepository) {
            throw 'Refusing API-09 compilation cleanup without exact ownership evidence.'
        }
        Remove-Item -LiteralPath $CafeResolved -Recurse -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $CafeResolved) {
            throw 'API-09 compilation root survived cleanup.'
        }
    }
    Write-Host 'API09 STATIC PASS: Python production and test sources compiled in an owned temporary cache.'
}

$CafeDelegated = @{
    NonProductionClusterAuthorization = $NonProductionClusterAuthorization
}
foreach ($CafeSwitch in @('InjectFailure', 'InjectCleanupFailure', 'CleanupOwnedRoot', 'PrepareInterruptionState')) {
    if ($PSBoundParameters.ContainsKey($CafeSwitch)) {
        $CafeDelegated[$CafeSwitch] = $true
    }
}

if ($InjectFailure -or $InjectCleanupFailure -or $CleanupOwnedRoot -or $PrepareInterruptionState) {
    & $CafeApi08Runner @CafeDelegated
    $CafeExitCode = $LASTEXITCODE
    exit $CafeExitCode
}

Test-CafePowerShellSyntax
Test-CafePythonCompilation

for ($CafePass = 1; $CafePass -le 2; $CafePass++) {
    Write-Host "API09 REPEATABILITY PASS $CafePass OF 2: starting complete guarded backend workflow."
    & $CafeApi08Runner @CafeDelegated
    $CafeExitCode = $LASTEXITCODE
    if ($CafeExitCode -ne 0) {
        throw "API-09 complete pass $CafePass failed with exit code $CafeExitCode."
    }
}

& git -C $CafeRepository diff --check
if ($LASTEXITCODE -ne 0) {
    throw 'API-09 git diff --check failed.'
}
$CafeFinalHead = (& git -C $CafeRepository rev-parse HEAD).Trim()
$CafeFinalIndex = (@(& git -C $CafeRepository diff --cached --name-only) -join "`n")
if ($CafeFinalHead -cne $CafeInitialHead -or
    $CafeFinalIndex -cne $CafeInitialIndex) {
    throw 'API-09 verification changed Git HEAD or the real index.'
}

Write-Host 'API09 TEST PASS: two consecutive complete Flask/backend gates passed with owned cleanup.'
Write-Host 'API09 GIT PASS: diff check passed and Git HEAD/index were unchanged.'
exit 0
