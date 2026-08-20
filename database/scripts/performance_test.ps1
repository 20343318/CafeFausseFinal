param(
    [ValidateRange(10, 100)]
    [int]$Samples = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Common.ps1')

Assert-CafeFausseResetGuard
$psqlPath = Get-CafeFaussePsqlPath

function Invoke-ScalarSql {
    param([Parameter(Mandatory = $true)][string]$Sql)
    $output = & $psqlPath -X -qAt -v ON_ERROR_STOP=1 -c $Sql
    if ($LASTEXITCODE -ne 0) { throw 'Performance measurement SQL failed.' }
    return (($output | Select-Object -Last 1) -as [string]).Trim()
}

function Reset-Reservations {
    [void](Invoke-ScalarSql @"
BEGIN;
DELETE FROM cafe_fausse.reservation_table_assignments;
DELETE FROM cafe_fausse.reservations;
DELETE FROM cafe_fausse.customers;
UPDATE cafe_fausse.restaurant_tables SET seating_capacity = 4;
COMMIT;
"@)
}

function Measure-SqlSamples {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$SqlFactory,
        [scriptblock]$BeforeEach
    )

    $measurements = [System.Collections.Generic.List[double]]::new()
    for ($sample = 1; $sample -le $Samples; $sample++) {
        if ($null -ne $BeforeEach) { & $BeforeEach }
        $sql = & $SqlFactory $sample
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        [void](Invoke-ScalarSql $sql)
        $stopwatch.Stop()
        $measurements.Add($stopwatch.Elapsed.TotalMilliseconds)
    }

    $ordered = $measurements | Sort-Object
    $p50Index = [math]::Ceiling(0.50 * $ordered.Count) - 1
    $p95Index = [math]::Ceiling(0.95 * $ordered.Count) - 1
    return [pscustomobject]@{
        Measurement = $Name
        Samples = $ordered.Count
        P50Milliseconds = [math]::Round($ordered[$p50Index], 2)
        P95Milliseconds = [math]::Round($ordered[$p95Index], 2)
    }
}

function Measure-ConcurrentSamples {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$SubmissionCount
    )

    $measurements = [System.Collections.Generic.List[double]]::new()
    for ($sample = 1; $sample -le $Samples; $sample++) {
        Reset-Reservations
        $processes = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        for ($submission = 1; $submission -le $SubmissionCount; $submission++) {
            $email = "perf-concurrent-$SubmissionCount-$sample-$submission@example.com"
            $sql = "SET ROLE cafe_fausse_app; SELECT outcome FROM cafe_fausse.book_reservation('Perf', NULL, 'Concurrent', '$email', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 4, 'no_change');"
            $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
            $startInfo.FileName = $psqlPath
            $startInfo.Arguments = "-X -qAt -v ON_ERROR_STOP=1 -c `"$sql`""
            $startInfo.UseShellExecute = $false
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $startInfo.CreateNoWindow = $true
            $process = [System.Diagnostics.Process]::new()
            $process.StartInfo = $startInfo
            if (-not $process.Start()) { throw 'Unable to start concurrent measurement process.' }
            $processes.Add($process)
        }
        foreach ($process in $processes) {
            if (-not $process.WaitForExit(20000)) {
                $process.Kill()
                throw 'Concurrent measurement exceeded its 20-second bound.'
            }
            $output = $process.StandardOutput.ReadToEnd().Trim()
            $errorOutput = $process.StandardError.ReadToEnd().Trim()
            if ($process.ExitCode -ne 0 -or $output -notmatch '^booked$') {
                throw "Concurrent measurement failed: output '$output'; error '$errorOutput'."
            }
            $process.Dispose()
        }
        $stopwatch.Stop()
        $measurements.Add($stopwatch.Elapsed.TotalMilliseconds)
    }

    $ordered = $measurements | Sort-Object
    return [pscustomobject]@{
        Measurement = $Name
        Samples = $ordered.Count
        P50Milliseconds = [math]::Round($ordered[[math]::Ceiling(0.50 * $ordered.Count) - 1], 2)
        P95Milliseconds = [math]::Round($ordered[[math]::Ceiling(0.95 * $ordered.Count) - 1], 2)
    }
}

$slotText = Invoke-ScalarSql @"
SELECT pg_catalog.to_char(slot.local_start, 'YYYY-MM-DD HH24:MI:SS')
       || '|' || (
           EXTRACT(epoch FROM (slot.local_start - (slot.starts_at AT TIME ZONE 'UTC'))) / 60
       )::smallint
FROM pg_catalog.generate_series(CURRENT_DATE + 1, CURRENT_DATE + 45, INTERVAL '1 day') AS day(local_date)
CROSS JOIN LATERAL cafe_fausse.provisional_availability(day.local_date::date, 4) AS slot
WHERE slot.available
ORDER BY slot.local_start
LIMIT 1;
"@
$slotParts = $slotText.Split('|')
$localStart = $slotParts[0]
$offset = [int]$slotParts[1]
$localDate = $localStart.Substring(0, 10)

$results = [System.Collections.Generic.List[object]]::new()

$results.Add((Measure-SqlSamples 'provisional availability day' {
    param($sample)
    "SET ROLE cafe_fausse_app; SELECT count(*) FROM cafe_fausse.provisional_availability(DATE '$localDate', 4);"
}))

$results.Add((Measure-SqlSamples '30 equal-capacity exact allocation' {
    param($sample)
    "SET ROLE cafe_fausse_test; SELECT count(*) FROM cafe_fausse.select_table_allocation(ARRAY(SELECT i::smallint FROM generate_series(1,30) i), ARRAY(SELECT 4 FROM generate_series(1,30)), 61, 1);"
}))

$results.Add((Measure-SqlSamples '30 heterogeneous-capacity exact allocation' {
    param($sample)
    "SET ROLE cafe_fausse_test; SELECT count(*) FROM cafe_fausse.select_table_allocation(ARRAY(SELECT i::smallint FROM generate_series(1,30) i), ARRAY(SELECT 2 + (i % 7) FROM generate_series(1,30) i), 73, 1);"
}))

$bookingSql = {
    param($sample)
    "SET ROLE cafe_fausse_test; SELECT outcome FROM cafe_fausse.book_reservation_test('Perf', NULL, 'Booking', 'perf-booking-$sample@example.com', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 120, 'no_change', 1, NULL);"
}
$results.Add((Measure-SqlSamples 'uncontended worst-case multi-table booking' $bookingSql { Reset-Reservations }))

Reset-Reservations
[void](Invoke-ScalarSql (& $bookingSql 1))
$results.Add((Measure-SqlSamples 'exact retry' {
    param($sample)
    & $bookingSql 1
}))

Reset-Reservations
[void](Invoke-ScalarSql "SET ROLE cafe_fausse_test; SELECT outcome FROM cafe_fausse.book_reservation_test('Perf', NULL, 'Conflict', 'perf-conflict@example.com', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 4, 'no_change', 1, NULL);")
$results.Add((Measure-SqlSamples 'same-customer overlap outcome' {
    param($sample)
    "SET ROLE cafe_fausse_test; SELECT outcome FROM cafe_fausse.book_reservation_test('Perf', NULL, 'Conflict', 'perf-conflict@example.com', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 5, 'no_change', 1, NULL);"
}))

Reset-Reservations
[void](Invoke-ScalarSql (& $bookingSql 1))
$results.Add((Measure-SqlSamples 'unavailable full outcome' {
    param($sample)
    "SET ROLE cafe_fausse_test; SELECT outcome FROM cafe_fausse.book_reservation_test('Perf', NULL, 'Unavailable', 'perf-unavailable-$sample@example.com', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 1, 'no_change', 1, NULL);"
}))

$results.Add((Measure-ConcurrentSamples 'two concurrent submissions' 2))
$results.Add((Measure-ConcurrentSamples 'five concurrent submissions' 5))

# Retained history is inserted through the test role, then the normal booking
# path is measured against the production overlap indexes.
Reset-Reservations
[void](Invoke-ScalarSql @"
SET ROLE cafe_fausse_test;
INSERT INTO cafe_fausse.customers(first_name,last_name,email)
SELECT 'History', 'Customer', 'history-' || i || '@example.com'
FROM generate_series(1,100) i;
INSERT INTO cafe_fausse.reservations(
    customer_id, starts_at, ends_at, party_size,
    fingerprint_version, reservation_fingerprint
)
SELECT customer_id,
       TIMESTAMPTZ '2020-01-01 17:00:00-05' + (customer_id * INTERVAL '1 day'),
       TIMESTAMPTZ '2020-01-01 18:30:00-05' + (customer_id * INTERVAL '1 day'),
       4, 1,
       cafe_fausse.reservation_fingerprint_v1(
           customer_id,
           TIMESTAMPTZ '2020-01-01 17:00:00-05' + (customer_id * INTERVAL '1 day'),
           4
       )
FROM cafe_fausse.customers;
INSERT INTO cafe_fausse.reservation_table_assignments(reservation_id, table_number)
SELECT reservation_id, ((reservation_id - 1) % 30 + 1)::smallint
FROM cafe_fausse.reservations;
"@)
$results.Add((Measure-SqlSamples 'booking with 100 retained history rows' {
    param($sample)
    "SET ROLE cafe_fausse_test; SELECT outcome FROM cafe_fausse.book_reservation_test('History', NULL, 'Current', 'history-current-$sample@example.com', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 4, 'no_change', 1, NULL);"
}))

$serverVersion = Invoke-ScalarSql 'SHOW server_version;'
$processor = if ([string]::IsNullOrWhiteSpace($env:PROCESSOR_IDENTIFIER)) {
    'processor details unavailable'
} else {
    $env:PROCESSOR_IDENTIFIER
}
$operatingSystem = [System.Environment]::OSVersion.VersionString
$logicalProcessors = [System.Environment]::ProcessorCount

Write-Host "Environment: PostgreSQL $serverVersion; $operatingSystem; $processor; $logicalProcessors logical processors; local psql process per sample."
$results | Format-Table -AutoSize
Write-Host 'These are preliminary DB-06 measurements, not the DB-07 performance gate or a two-second guarantee.'
