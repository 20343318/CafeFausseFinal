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

function Set-HeterogeneousCapacities {
    Reset-Reservations
    [void](Invoke-ScalarSql @"
SET ROLE cafe_fausse_test;
UPDATE cafe_fausse.restaurant_tables
SET seating_capacity = 2 + (table_number % 7);
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
        Metric = 'individual client-observed call'
        Samples = $ordered.Count
        MinimumMilliseconds = [math]::Round($ordered[0], 2)
        P50Milliseconds = [math]::Round($ordered[$p50Index], 2)
        P95Milliseconds = [math]::Round($ordered[$p95Index], 2)
        P99Milliseconds = [math]::Round($ordered[[math]::Ceiling(0.99 * $ordered.Count) - 1], 2)
        MaximumMilliseconds = [math]::Round($ordered[$ordered.Count - 1], 2)
    }
}

function Measure-ConcurrentSamples {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$SubmissionCount
    )

    $measurements = [System.Collections.Generic.List[double]]::new()
    $individualMeasurements = [System.Collections.Generic.List[double]]::new()
    $totalBooked = 0
    $totalRetryable = 0
    for ($sample = 1; $sample -le $Samples; $sample++) {
        Reset-Reservations
        $processes = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            for ($submission = 1; $submission -le $SubmissionCount; $submission++) {
                $email = "perf-concurrent-$SubmissionCount-$sample-$submission@example.com"
                $sql = "SET ROLE cafe_fausse_app; SELECT outcome FROM cafe_fausse.book_reservation('Perf', NULL, 'Concurrent', '$email', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 4, 'no_change');"
                $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
                $startInfo.FileName = $psqlPath
                $startInfo.Arguments = "-X -qAt -v ON_ERROR_STOP=1 -v VERBOSITY=verbose -c `"$sql`""
                $startInfo.UseShellExecute = $false
                $startInfo.RedirectStandardOutput = $true
                $startInfo.RedirectStandardError = $true
                $startInfo.CreateNoWindow = $true
                $process = [System.Diagnostics.Process]::new()
                $process.StartInfo = $startInfo
                if (-not $process.Start()) { throw 'Unable to start concurrent measurement process.' }
                $processes.Add($process)
            }
            $bookedCount = 0
            $retryableCount = 0
            foreach ($process in $processes) {
                if (-not $process.WaitForExit(20000)) {
                    $process.Kill()
                    throw 'Concurrent measurement exceeded its 20-second bound.'
                }
                $individualMeasurements.Add(
                    ($process.ExitTime - $process.StartTime).TotalMilliseconds
                )
                $output = $process.StandardOutput.ReadToEnd().Trim()
                $errorOutput = $process.StandardError.ReadToEnd().Trim()
                if ($process.ExitCode -eq 0 -and $output -match '^booked$') {
                    $bookedCount++
                }
                elseif ($process.ExitCode -ne 0 -and $errorOutput -match '(55P03|40P01|40001)') {
                    $retryableCount++
                }
                else {
                    throw "Concurrent measurement failed: output '$output'; error '$errorOutput'."
                }
            }
            $stopwatch.Stop()
        }
        finally {
            foreach ($process in $processes) {
                if (-not $process.HasExited) {
                    $process.Kill()
                    [void]$process.WaitForExit(3000)
                }
                $process.Dispose()
            }
        }
        if ($bookedCount + $retryableCount -ne $SubmissionCount -or $bookedCount -lt 1) {
            throw 'Concurrent measurement produced an invalid outcome count.'
        }
        $committedCount = [int](Invoke-ScalarSql 'SELECT count(*) FROM cafe_fausse.reservations;')
        if ($committedCount -ne $bookedCount) {
            throw "Concurrent outcome count did not match committed reservations."
        }
        $totalBooked += $bookedCount
        $totalRetryable += $retryableCount
        $measurements.Add($stopwatch.Elapsed.TotalMilliseconds)
    }

    $ordered = $measurements | Sort-Object
    $individualOrdered = $individualMeasurements | Sort-Object
    Write-Host "$Name outcomes across $Samples samples: booked=$totalBooked retryable=$totalRetryable"
    return @(
        [pscustomobject]@{
            Measurement = $Name
            Metric = 'group completion'
            Samples = $ordered.Count
            MinimumMilliseconds = [math]::Round($ordered[0], 2)
            P50Milliseconds = [math]::Round($ordered[[math]::Ceiling(0.50 * $ordered.Count) - 1], 2)
            P95Milliseconds = [math]::Round($ordered[[math]::Ceiling(0.95 * $ordered.Count) - 1], 2)
            P99Milliseconds = [math]::Round($ordered[[math]::Ceiling(0.99 * $ordered.Count) - 1], 2)
            MaximumMilliseconds = [math]::Round($ordered[$ordered.Count - 1], 2)
            BookedOutcomes = $totalBooked
            RetryableOutcomes = $totalRetryable
        },
        [pscustomobject]@{
            Measurement = $Name
            Metric = 'individual request process lifetime'
            Samples = $individualOrdered.Count
            MinimumMilliseconds = [math]::Round($individualOrdered[0], 2)
            P50Milliseconds = [math]::Round($individualOrdered[[math]::Ceiling(0.50 * $individualOrdered.Count) - 1], 2)
            P95Milliseconds = [math]::Round($individualOrdered[[math]::Ceiling(0.95 * $individualOrdered.Count) - 1], 2)
            P99Milliseconds = [math]::Round($individualOrdered[[math]::Ceiling(0.99 * $individualOrdered.Count) - 1], 2)
            MaximumMilliseconds = [math]::Round($individualOrdered[$individualOrdered.Count - 1], 2)
            BookedOutcomes = $totalBooked
            RetryableOutcomes = $totalRetryable
        }
    )
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

$results.Add((Measure-SqlSamples 'uncontended single-table booking' {
    param($sample)
    "SET ROLE cafe_fausse_test; SELECT outcome FROM cafe_fausse.book_reservation_test('Perf', NULL, 'Single', 'perf-single-$sample@example.com', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 4, 'no_change', 1, NULL);"
} { Reset-Reservations }))

$results.Add((Measure-SqlSamples 'production booking through general equal-capacity allocation' {
    param($sample)
    "SET ROLE cafe_fausse_app; SELECT outcome FROM cafe_fausse.book_reservation('Perf', NULL, 'GeneralEqual', 'perf-general-equal-$sample@example.com', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 61, 'no_change');"
} { Reset-Reservations }))

$results.Add((Measure-SqlSamples 'production booking through general heterogeneous-capacity allocation' {
    param($sample)
    "SET ROLE cafe_fausse_app; SELECT outcome FROM cafe_fausse.book_reservation('Perf', NULL, 'GeneralHeterogeneous', 'perf-general-heterogeneous-$sample@example.com', NULL, TIMESTAMP '$localStart', ($offset)::smallint, 73, 'no_change');"
} { Set-HeterogeneousCapacities }))

Reset-Reservations

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

foreach ($result in @(Measure-ConcurrentSamples 'two concurrent submissions' 2)) {
    $results.Add($result)
}
foreach ($result in @(Measure-ConcurrentSamples 'five concurrent submissions' 5)) {
    $results.Add($result)
}
foreach ($result in @(Measure-ConcurrentSamples 'short burst of eight submissions' 8)) {
    $results.Add($result)
}

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
$results | Format-Table -AutoSize | Out-String -Width 240 | Write-Host
Write-Host 'Measurements are conservative local client-observed database calls and include psql startup; they are DB-07 evidence, not a full-stack two-second guarantee.'
