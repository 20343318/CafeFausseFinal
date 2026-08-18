Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CafeFaussePsqlPath {
    if (-not [string]::IsNullOrWhiteSpace($env:CAFE_FAUSSE_PSQL)) {
        if (-not (Test-Path -LiteralPath $env:CAFE_FAUSSE_PSQL -PathType Leaf)) {
            throw 'CAFE_FAUSSE_PSQL does not point to an existing psql executable.'
        }

        return (Resolve-Path -LiteralPath $env:CAFE_FAUSSE_PSQL).Path
    }

    $pathCommand = Get-Command psql -ErrorAction SilentlyContinue
    if ($null -ne $pathCommand) {
        return $pathCommand.Source
    }

    $programFiles = [Environment]::GetFolderPath('ProgramFiles')
    $postgresRoot = Join-Path $programFiles 'PostgreSQL'
    if (Test-Path -LiteralPath $postgresRoot -PathType Container) {
        $candidate = Get-ChildItem -LiteralPath $postgresRoot -Directory |
            Sort-Object -Property { [version]$_.Name } -Descending |
            ForEach-Object { Join-Path $_.FullName 'bin\psql.exe' } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
            Select-Object -First 1

        if ($null -ne $candidate) {
            return $candidate
        }
    }

    throw 'psql was not found. Put PostgreSQL client tools on PATH or set CAFE_FAUSSE_PSQL.'
}

function Assert-CafeFausseConnectionEnvironment {
    if ([string]::IsNullOrWhiteSpace($env:PGDATABASE)) {
        throw 'PGDATABASE is required; no default database will be targeted.'
    }

    if ($env:PGDATABASE -notmatch '^cafe_fausse_(dev|test|demo)(_[a-z0-9_]+)?$') {
        throw 'PGDATABASE must be an explicitly named Cafe Fausse development/test/demo database.'
    }
}

function Set-CafeFausseSessionBounds {
    if ([string]::IsNullOrWhiteSpace($env:PGOPTIONS)) {
        $env:PGOPTIONS = '-c lock_timeout=5000 -c statement_timeout=60000'
    }
}

function Invoke-CafeFaussePsql {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$PsqlArguments,

        [switch]$AllowFailure
    )

    $psqlPath = Get-CafeFaussePsqlPath
    & $psqlPath -X @PsqlArguments
    $exitCode = $LASTEXITCODE

    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "psql failed with exit code $exitCode."
    }

    return $exitCode
}

function Get-CafeFausseConnectedDatabase {
    $psqlPath = Get-CafeFaussePsqlPath
    $databaseName = & $psqlPath -X -A -t -v ON_ERROR_STOP=1 -c 'SELECT current_database();'
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to verify the connected PostgreSQL database.'
    }

    return ($databaseName | Select-Object -Last 1).Trim()
}

function Assert-CafeFausseResetGuard {
    Assert-CafeFausseConnectionEnvironment

    if ($env:CAFE_FAUSSE_ENVIRONMENT -notin @('development', 'test', 'demo')) {
        throw 'CAFE_FAUSSE_ENVIRONMENT must be development, test, or demo.'
    }

    if ($env:CAFE_FAUSSE_ALLOW_RESET -cne 'YES') {
        throw 'CAFE_FAUSSE_ALLOW_RESET must equal YES exactly.'
    }

    $connectedDatabase = Get-CafeFausseConnectedDatabase
    if ($connectedDatabase -cne $env:PGDATABASE) {
        throw 'The connected database does not match PGDATABASE; reset refused.'
    }

    if ($connectedDatabase -notmatch '^cafe_fausse_(dev|test|demo)(_[a-z0-9_]+)?$') {
        throw 'The connected database is not an approved Cafe Fausse nonproduction target.'
    }
}

Set-CafeFausseSessionBounds
