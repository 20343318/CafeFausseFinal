param(
    [ValidateRange(2, 20)]
    [int]$Iterations = 3,

    [switch]$RunChildCleanupSelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'Common.ps1')

Assert-CafeFausseResetGuard
$psqlPath = Get-CafeFaussePsqlPath
$script:ScenarioCount = 0

function Invoke-ScalarSql {
    param([Parameter(Mandatory = $true)][string]$Sql)

    $output = & $psqlPath -X -qAt -v ON_ERROR_STOP=1 -c $Sql
    if ($LASTEXITCODE -ne 0) {
        throw "Concurrency harness SQL failed: $Sql"
    }
    return (($output | Select-Object -Last 1) -as [string]).Trim()
}

function Reset-ScenarioState {
    $sql = @"
BEGIN;
DELETE FROM cafe_fausse.reservation_table_assignments;
DELETE FROM cafe_fausse.reservations;
DELETE FROM cafe_fausse.customers;
UPDATE cafe_fausse.restaurant_tables SET seating_capacity = 4;
UPDATE cafe_fausse.reservation_configuration
SET start_interval_minutes = 30,
    reservation_duration_minutes = 90,
    advance_booking_window_days = 60,
    same_day_lead_minutes = 120,
    restaurant_timezone = 'America/New_York'
WHERE configuration_id = 1;
UPDATE cafe_fausse.restaurant_operating_hours
SET opens_at = TIME '17:00',
    closes_at = CASE WHEN weekday = 7 THEN TIME '21:00' ELSE TIME '23:00' END;
COMMIT;
"@
    [void](Invoke-ScalarSql $sql)
}

function Get-TestSlot {
    $sql = @"
SELECT pg_catalog.to_char(slot.local_start, 'YYYY-MM-DD HH24:MI:SS')
       || '|' || (
           EXTRACT(epoch FROM (slot.local_start - (slot.starts_at AT TIME ZONE 'UTC'))) / 60
       )::smallint
       || '|' || EXTRACT(isodow FROM slot.local_start)::smallint
FROM pg_catalog.generate_series(CURRENT_DATE + 1, CURRENT_DATE + 45, INTERVAL '1 day') AS day(local_date)
CROSS JOIN LATERAL cafe_fausse.provisional_availability(day.local_date::date, 4) AS slot
WHERE slot.available
ORDER BY slot.local_start
LIMIT 1;
"@
    $parts = (Invoke-ScalarSql $sql).Split('|')
    return [pscustomobject]@{
        LocalStart = [datetime]::ParseExact($parts[0], 'yyyy-MM-dd HH:mm:ss', $null)
        Offset = [int]$parts[1]
        Weekday = [int]$parts[2]
    }
}

function Get-EffectiveApplicationName {
    param([Parameter(Mandatory = $true)][string]$ApplicationName)
    $effectiveApplicationName = $ApplicationName
    if (-not [string]::IsNullOrWhiteSpace($env:PGAPPNAME)) {
        $effectiveApplicationName = "$($env:PGAPPNAME):$ApplicationName"
    }
    if ($effectiveApplicationName.Length -gt 63) {
        $effectiveApplicationName = $effectiveApplicationName.Substring(0, 63)
    }
    return $effectiveApplicationName
}

function New-PsqlSession {
    param([Parameter(Mandatory = $true)][string]$ApplicationName)

    $effectiveApplicationName = Get-EffectiveApplicationName $ApplicationName

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $psqlPath
    $startInfo.Arguments = '-X -qAt -v ON_ERROR_STOP=1'
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.EnvironmentVariables['PGAPPNAME'] = $effectiveApplicationName

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw 'Unable to start a psql test session.'
    }
    return $process
}

function Send-SessionSql {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Session,
        [Parameter(Mandatory = $true)][string]$Sql
    )
    $Session.StandardInput.WriteLine($Sql)
    $Session.StandardInput.Flush()
}

function Close-PsqlChildBounded {
    param([Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process)

    $cleanupMessages = [System.Collections.Generic.List[string]]::new()
    try {
        if (-not $Process.HasExited) {
            try {
                if ($Process.StartInfo.RedirectStandardInput) {
                    $Process.StandardInput.WriteLine('\q')
                    $Process.StandardInput.Flush()
                }
            }
            catch {
                if (-not $Process.HasExited) {
                    [void]$cleanupMessages.Add("Graceful-exit request failed: $($_.Exception.Message)")
                }
            }
        }
        if (-not $Process.HasExited -and -not $Process.WaitForExit(3000)) {
            try { $Process.Kill() }
            catch { [void]$cleanupMessages.Add("Kill failed: $($_.Exception.Message)") }
            if (-not $Process.HasExited -and -not $Process.WaitForExit(3000)) {
                [void]$cleanupMessages.Add('Process did not exit within three seconds after kill.')
            }
        }
        if (-not $Process.HasExited) {
            [void]$cleanupMessages.Add('Process is still running after bounded cleanup.')
        }
    }
    finally {
        $Process.Dispose()
    }
    if ($cleanupMessages.Count -ne 0) {
        throw ($cleanupMessages -join ' ')
    }
}

function Close-PsqlChildrenBounded {
    param([System.Diagnostics.Process[]]$Processes)

    $failures = [System.Collections.Generic.List[string]]::new()
    foreach ($process in @($Processes)) {
        if ($null -eq $process) { continue }
        try { Close-PsqlChildBounded $process }
        catch { [void]$failures.Add($_.Exception.Message) }
    }
    if ($failures.Count -ne 0) {
        throw ($failures -join ' ')
    }
}

function Complete-PsqlProtectedBlock {
    param(
        $PrimaryError,
        $CleanupError,
        [Parameter(Mandatory = $true)][string]$Context
    )
    if ($null -ne $PrimaryError) {
        if ($null -ne $CleanupError) {
            throw "$Context primary failure: $($PrimaryError.Exception.Message) Cleanup failure: $($CleanupError.Exception.Message)"
        }
        throw $PrimaryError
    }
    if ($null -ne $CleanupError) { throw $CleanupError }
}

function Invoke-ChildCleanupSelfTest {
    $applicationName = Get-EffectiveApplicationName 'db06_cleanup_hang'
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $psqlPath
    $startInfo.Arguments = '-X -qAt -v ON_ERROR_STOP=1 -c "SELECT pg_sleep(60);"'
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.EnvironmentVariables['PGAPPNAME'] = $applicationName
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw 'Unable to start the hanging-child fixture.' }
    Start-Sleep -Milliseconds 250
    if ($process.HasExited) {
        $process.Dispose()
        throw 'The hanging-child fixture exited before cleanup was exercised.'
    }
    Close-PsqlChildBounded $process
    Write-Host 'DB-06 hanging-child bounded termination: PASS'
}

function Wait-SessionMarker {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Session,
        [Parameter(Mandatory = $true)][string]$Marker,
        [int]$TimeoutMilliseconds = 15000
    )

    $deadline = [datetime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    $lines = [System.Collections.Generic.List[string]]::new()
    while ([datetime]::UtcNow -lt $deadline) {
        $remaining = [math]::Max(1, [int]($deadline - [datetime]::UtcNow).TotalMilliseconds)
        $readTask = $Session.StandardOutput.ReadLineAsync()
        if (-not $readTask.Wait($remaining)) {
            throw "Timed out waiting for psql marker $Marker."
        }
        $line = $readTask.Result
        if ($null -eq $line) {
            $errorText = $Session.StandardError.ReadToEnd()
            throw "psql ended before marker $Marker. $errorText"
        }
        if ($line -eq $Marker) {
            return $lines.ToArray()
        }
        $lines.Add($line)
    }
    throw "Timed out waiting for psql marker $Marker."
}

function Wait-ForDatabaseLockWait {
    param([Parameter(Mandatory = $true)][string]$ApplicationName)

    $effectiveApplicationName = Get-EffectiveApplicationName $ApplicationName

    $deadline = [datetime]::UtcNow.AddSeconds(10)
    do {
        $waiting = Invoke-ScalarSql @"
SELECT EXISTS (
    SELECT 1 FROM pg_catalog.pg_stat_activity
WHERE application_name = '$effectiveApplicationName'
      AND wait_event_type = 'Lock'
);
"@
        if ($waiting -eq 't') {
            return
        }
        Start-Sleep -Milliseconds 25
    } while ([datetime]::UtcNow -lt $deadline)
    throw "Session $ApplicationName never reached a database-observable lock wait."
}

function Get-BookSql {
    param(
        [string]$FirstName,
        [string]$LastName,
        [string]$Email,
        [datetime]$LocalStart,
        [int]$Offset,
        [int]$PartySize,
        [string]$NewsletterAction = 'no_change',
        [string]$MiddleInitial,
        [string]$Phone
    )

    $localText = $LocalStart.ToString('yyyy-MM-dd HH:mm:ss')
    $middleSql = if ([string]::IsNullOrEmpty($MiddleInitial)) { 'NULL' } else { "'$MiddleInitial'" }
    $phoneSql = if ([string]::IsNullOrEmpty($Phone)) { 'NULL' } else { "'$Phone'" }
    return @"
SELECT outcome || COALESCE('|' || reservation_id::text, '')
FROM cafe_fausse.book_reservation_test(
    '$FirstName', $middleSql, '$LastName', '$Email', $phoneSql,
    TIMESTAMP '$localText', ($Offset)::smallint, $PartySize,
    '$NewsletterAction', 1, NULL
)
"@
}

function Assert-CommonCommittedState {
    param([string]$AdditionalPredicate = 'TRUE')

    $sql = @"
SELECT (
    NOT EXISTS (
        SELECT 1
        FROM cafe_fausse.reservation_table_assignments a1
        JOIN cafe_fausse.reservations r1 ON r1.reservation_id = a1.reservation_id
        JOIN cafe_fausse.reservation_table_assignments a2
          ON a2.table_number = a1.table_number AND a2.reservation_id > a1.reservation_id
        JOIN cafe_fausse.reservations r2 ON r2.reservation_id = a2.reservation_id
        WHERE r1.starts_at < r2.ends_at AND r2.starts_at < r1.ends_at
    )
    AND NOT EXISTS (
        SELECT 1 FROM cafe_fausse.reservations r
        WHERE NOT EXISTS (
            SELECT 1 FROM cafe_fausse.reservation_table_assignments a
            WHERE a.reservation_id = r.reservation_id
        )
        OR r.party_size > (
            SELECT COALESCE(sum(t.seating_capacity), 0)
            FROM cafe_fausse.reservation_table_assignments a
            JOIN cafe_fausse.restaurant_tables t ON t.table_number = a.table_number
            WHERE a.reservation_id = r.reservation_id
        )
    )
    AND NOT EXISTS (
        SELECT email FROM cafe_fausse.customers GROUP BY email HAVING count(*) > 1
    )
    AND ($AdditionalPredicate)
)::text;
"@
    if ((Invoke-ScalarSql $sql) -ne 'true') {
        throw 'A concurrent scenario violated its final-state invariants.'
    }
}

function Invoke-LockedPair {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$SessionASql,
        [Parameter(Mandatory = $true)][string]$SessionBSql,
        [Parameter(Mandatory = $true)][string]$ExpectedA,
        [Parameter(Mandatory = $true)][string]$ExpectedB,
        [string]$SetupSql,
        [string]$FinalPredicate = 'TRUE',
        [int]$Repeat = 1
    )

    for ($iteration = 1; $iteration -le $Repeat; $iteration++) {
        Reset-ScenarioState
        if (-not [string]::IsNullOrWhiteSpace($SetupSql)) {
            [void](Invoke-ScalarSql $SetupSql)
        }

        $safeName = ($Name -replace '[^A-Za-z0-9]', '_')
        $appA = "db06_A_${safeName}_$iteration"
        $appB = "db06_B_${safeName}_$iteration"
        $sessionA = New-PsqlSession $appA
        $sessionB = New-PsqlSession $appB
        $primaryError = $null
        $cleanupError = $null
        try {
            Send-SessionSql $sessionA "BEGIN; SET LOCAL ROLE cafe_fausse_test; $SessionASql; \echo A_READY"
            $aLines = Wait-SessionMarker $sessionA 'A_READY'

            Send-SessionSql $sessionB "BEGIN; SET LOCAL ROLE cafe_fausse_test; $SessionBSql;`n\echo B_DONE`nCOMMIT;`n\echo B_COMMITTED"
            Wait-ForDatabaseLockWait $appB

            Send-SessionSql $sessionA "COMMIT; \echo A_COMMITTED"
            [void](Wait-SessionMarker $sessionA 'A_COMMITTED')
            $bLines = Wait-SessionMarker $sessionB 'B_DONE'
            [void](Wait-SessionMarker $sessionB 'B_COMMITTED')

            $aText = $aLines -join "`n"
            $bText = $bLines -join "`n"
            if ($aText -notmatch $ExpectedA) {
                throw "$Name iteration ${iteration}: session A result '$aText' did not match '$ExpectedA'."
            }
            if ($bText -notmatch $ExpectedB) {
                throw "$Name iteration ${iteration}: session B result '$bText' did not match '$ExpectedB'."
            }
        }
        catch { $primaryError = $_ }
        finally {
            try { Close-PsqlChildrenBounded @($sessionA, $sessionB) }
            catch { $cleanupError = $_ }
        }
        Complete-PsqlProtectedBlock $primaryError $cleanupError "$Name iteration $iteration"

        Assert-CommonCommittedState $FinalPredicate
        $script:ScenarioCount++
        Write-Host "$Name iteration $iteration`: PASS"
    }
}

if ($RunChildCleanupSelfTest) {
    Invoke-ChildCleanupSelfTest
    return
}

$slot = Get-TestSlot
$start = $slot.LocalStart
$offset = $slot.Offset
$backToBack = $start.AddMinutes(90)
$overlap = $start.AddMinutes(30)

$exactA = Get-BookSql 'Concurrent' 'Exact' 'concurrent-exact@example.com' $start $offset 4
$exactB = Get-BookSql 'Concurrent' 'Exact' 'concurrent-exact@example.com' $start $offset 4
Invoke-LockedPair 'identical request and exact-identity backstop' $exactA $exactB '^booked\|' '^exact_retry\|' `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.customers) AND (SELECT count(*) = 1 FROM cafe_fausse.reservations)" `
    -Repeat $Iterations

$differentA = Get-BookSql 'Concurrent' 'Email' 'same-new-email@example.com' $start $offset 4
$differentB = Get-BookSql 'Concurrent' 'Email' 'same-new-email@example.com' $overlap $offset 5
Invoke-LockedPair 'different requests and unique-email backstop' $differentA $differentB '^booked\|' '^same_customer_overlap$' `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.customers) AND (SELECT count(*) = 1 FROM cafe_fausse.reservations)" `
    -Repeat $Iterations

$mismatchB = Get-BookSql 'Different' 'Identity' 'same-new-email@example.com' $overlap $offset 5
Invoke-LockedPair 'matching versus mismatching names' $differentA $mismatchB '^booked\|' '^customer_identity_mismatch$' `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.customers) AND (SELECT count(*) = 1 FROM cafe_fausse.reservations)"

$blankFieldSetup = @"
SET ROLE cafe_fausse_test;
INSERT INTO cafe_fausse.customers(first_name, last_name, email)
VALUES ('Populate', 'Race', 'populate-race@example.com');
"@
$populateA = Get-BookSql 'Populate' 'Race' 'populate-race@example.com' $start $offset 4 'no_change' 'P' '202-555-0199'
$populateB = Get-BookSql 'Populate' 'Race' 'populate-race@example.com' $backToBack $offset 4 'no_change' 'P' '2025550199'
Invoke-LockedPair 'blank middle-initial and phone population race' $populateA $populateB '^booked\|' '^booked\|' `
    -SetupSql $blankFieldSetup `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.customers WHERE middle_initial = 'P' AND phone = '202-555-0199') AND (SELECT count(*) = 2 FROM cafe_fausse.reservations)"

$lastSetup = "UPDATE cafe_fausse.restaurant_tables SET seating_capacity = CASE WHEN table_number = 1 THEN 120 ELSE 1 END;"
$lastA = Get-BookSql 'Last' 'TableA' 'last-a@example.com' $start $offset 120
$lastB = Get-BookSql 'Last' 'TableB' 'last-b@example.com' $start $offset 120
Invoke-LockedPair 'different customers competing for last table' $lastA $lastB '^booked\|' '^unavailable$' `
    -SetupSql $lastSetup `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.reservations) AND (SELECT count(*) = 1 FROM cafe_fausse.customers)" `
    -Repeat $Iterations

$singleA = Get-BookSql 'Single' 'A' 'single-a@example.com' $start $offset 4
$singleB = Get-BookSql 'Single' 'B' 'single-b@example.com' $start $offset 4
Invoke-LockedPair 'competing single-table requests' $singleA $singleB '^booked\|' '^booked\|' `
    -FinalPredicate "(SELECT count(*) = 2 FROM cafe_fausse.reservations)"

$multiA = Get-BookSql 'Multi' 'A' 'multi-a@example.com' $start $offset 8
$multiB = Get-BookSql 'Multi' 'B' 'multi-b@example.com' $start $offset 8
Invoke-LockedPair 'multi-table requests with overlapping candidate sets' $multiA $multiB '^booked\|' '^booked\|' `
    -FinalPredicate "(SELECT count(*) = 4 FROM cafe_fausse.reservation_table_assignments)"

$mixedA = Get-BookSql 'Mixed' 'Single' 'mixed-single@example.com' $start $offset 4
$mixedB = Get-BookSql 'Mixed' 'Multi' 'mixed-multi@example.com' $start $offset 8
Invoke-LockedPair 'single-table versus multi-table competition' $mixedA $mixedB '^booked\|' '^booked\|' `
    -FinalPredicate "(SELECT count(*) = 3 FROM cafe_fausse.reservation_table_assignments)"

$customerA = Get-BookSql 'Overlap' 'Customer' 'overlap-customer@example.com' $start $offset 4
$customerB = Get-BookSql 'Overlap' 'Customer' 'overlap-customer@example.com' $overlap $offset 5
Invoke-LockedPair 'same-customer overlapping requests' $customerA $customerB '^booked\|' '^same_customer_overlap$' `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.reservations)"

$backA = Get-BookSql 'Back' 'ToBack' 'back-to-back@example.com' $start $offset 4
$backB = Get-BookSql 'Back' 'ToBack' 'back-to-back@example.com' $backToBack $offset 4
Invoke-LockedPair 'back-to-back requests' $backA $backB '^booked\|' '^booked\|' `
    -FinalPredicate "(SELECT count(*) = 2 FROM cafe_fausse.reservations)"

$stalePredicate = "EXISTS (SELECT 1 FROM cafe_fausse.provisional_availability(DATE '$($start.ToString('yyyy-MM-dd'))', 120) WHERE local_start = TIMESTAMP '$($start.ToString('yyyy-MM-dd HH:mm:ss'))' AND available)"
Reset-ScenarioState
[void](Invoke-ScalarSql $lastSetup)
if ((Invoke-ScalarSql "SELECT ($stalePredicate)::text;") -ne 'true') {
    throw 'Stale-availability precondition was not visible.'
}
Invoke-LockedPair 'stale availability followed by booking' $lastA $lastB '^booked\|' '^unavailable$' `
    -SetupSql $lastSetup `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.reservations)"

$writerBooking = Get-BookSql 'Writer' 'Booking' 'writer-booking@example.com' $start $offset 4
Invoke-LockedPair 'booking versus table-capacity writer' $writerBooking `
    "SELECT 'capacity_changed' FROM cafe_fausse.set_restaurant_table_capacity(1::smallint, 5)" `
    '^booked\|' '^capacity_changed$' `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.reservations)"

Invoke-LockedPair 'booking versus recurring-hours writer' $writerBooking `
    "SELECT 'hours_changed' FROM cafe_fausse.set_restaurant_operating_hours(($($slot.Weekday))::smallint, TIME '16:00', TIME '23:00')" `
    '^booked\|' '^hours_changed$' `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.reservations)"

Invoke-LockedPair 'booking versus scalar-configuration writer' $writerBooking `
    "SELECT 'configuration_changed' FROM cafe_fausse.set_reservation_configuration(30::smallint, 120::smallint, 60::smallint, 120::smallint, 'America/New_York')" `
    '^booked\|' '^configuration_changed$' `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.reservations) AND (SELECT EXTRACT(epoch FROM (ends_at - starts_at)) = 5400 FROM cafe_fausse.reservations LIMIT 1)"

$newsletterBook = Get-BookSql 'News' 'Letter' 'newsletter-race@example.com' $start $offset 4 'subscribe'
$newsletterUpdate = "SELECT outcome FROM cafe_fausse.set_newsletter_preference('News', NULL, 'Letter', 'newsletter-race@example.com', FALSE)"
Invoke-LockedPair 'booking newsletter versus independent preference' $newsletterBook $newsletterUpdate '^booked\|' '^unsubscribed$' `
    -FinalPredicate "(SELECT count(*) = 1 FROM cafe_fausse.customers) AND (SELECT NOT newsletter_subscribed FROM cafe_fausse.customers LIMIT 1)"

# Hold the authoritative restaurant lock with an uncommitted booking and prove
# that the operation's bounded lock timeout is surfaced as retryable SQLSTATE
# 55P03, without leaving the losing customer's provisional state behind.
Reset-ScenarioState
$timeoutA = New-PsqlSession 'db06_timeout_holder'
$timeoutB = New-PsqlSession 'db06_timeout_waiter'
$primaryError = $null
$cleanupError = $null
try {
    Send-SessionSql $timeoutA "BEGIN; SET LOCAL ROLE cafe_fausse_test; $singleA; \echo TIMEOUT_A_READY"
    [void](Wait-SessionMarker $timeoutA 'TIMEOUT_A_READY')
    $lockHoldStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $lockWaitStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Send-SessionSql $timeoutB "\set VERBOSITY verbose`nBEGIN; SET LOCAL ROLE cafe_fausse_test; $singleB;"
    Wait-ForDatabaseLockWait 'db06_timeout_waiter'
    if (-not $timeoutB.WaitForExit(6000)) {
        throw 'Lock-timeout waiter did not terminate within its database bound.'
    }
    $lockWaitStopwatch.Stop()
    $timeoutError = $timeoutB.StandardError.ReadToEnd()
    if ($timeoutB.ExitCode -eq 0 -or $timeoutError -notmatch '55P03') {
        throw "Expected retryable SQLSTATE 55P03, received: $timeoutError"
    }
    Send-SessionSql $timeoutA "COMMIT; \echo TIMEOUT_A_COMMITTED"
    [void](Wait-SessionMarker $timeoutA 'TIMEOUT_A_COMMITTED')
    $lockHoldStopwatch.Stop()
}
catch { $primaryError = $_ }
finally {
    try { Close-PsqlChildrenBounded @($timeoutA, $timeoutB) }
    catch { $cleanupError = $_ }
}
Complete-PsqlProtectedBlock $primaryError $cleanupError 'bounded lock-timeout scenario'
Assert-CommonCommittedState "(SELECT count(*) = 1 FROM cafe_fausse.customers) AND (SELECT count(*) = 1 FROM cafe_fausse.reservations)"
$script:ScenarioCount++
Write-Host 'bounded restaurant-lock timeout and retryable classification: PASS'
Write-Host ("Observed timeout scenario: advisory-lock wait {0:N2} ms; holder lock-hold {1:N2} ms." -f `
    $lockWaitStopwatch.Elapsed.TotalMilliseconds, $lockHoldStopwatch.Elapsed.TotalMilliseconds)

# Force a conventional row-lock deadlock solely inside the test role. This
# proves the multi-session driver preserves PostgreSQL's retryable 40P01 class;
# production booking itself uses the approved total lock order to avoid it.
Reset-ScenarioState
[void](Invoke-ScalarSql @"
SET ROLE cafe_fausse_test;
INSERT INTO cafe_fausse.customers(first_name,last_name,email)
VALUES ('Deadlock','A','deadlock-a@example.com'), ('Deadlock','B','deadlock-b@example.com');
"@)
$deadlockA = New-PsqlSession 'db06_deadlock_a'
$deadlockB = New-PsqlSession 'db06_deadlock_b'
$primaryError = $null
$cleanupError = $null
try {
    Send-SessionSql $deadlockA "\set VERBOSITY verbose`nBEGIN; SET LOCAL ROLE cafe_fausse_test; SELECT customer_id FROM cafe_fausse.customers WHERE email='deadlock-a@example.com' FOR UPDATE; \echo DEADLOCK_A_FIRST"
    Send-SessionSql $deadlockB "\set VERBOSITY verbose`nBEGIN; SET LOCAL ROLE cafe_fausse_test; SELECT customer_id FROM cafe_fausse.customers WHERE email='deadlock-b@example.com' FOR UPDATE; \echo DEADLOCK_B_FIRST"
    [void](Wait-SessionMarker $deadlockA 'DEADLOCK_A_FIRST')
    [void](Wait-SessionMarker $deadlockB 'DEADLOCK_B_FIRST')
    Send-SessionSql $deadlockA "SELECT customer_id FROM cafe_fausse.customers WHERE email='deadlock-b@example.com' FOR UPDATE;`n\echo DEADLOCK_A_SECOND"
    Wait-ForDatabaseLockWait 'db06_deadlock_a'
    Send-SessionSql $deadlockB "SELECT customer_id FROM cafe_fausse.customers WHERE email='deadlock-a@example.com' FOR UPDATE;`n\echo DEADLOCK_B_SECOND"

    $deadline = [datetime]::UtcNow.AddSeconds(6)
    while (-not $deadlockA.HasExited -and -not $deadlockB.HasExited -and [datetime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 25
    }
    $victim = if ($deadlockA.HasExited) { $deadlockA } elseif ($deadlockB.HasExited) { $deadlockB } else { $null }
    if ($null -eq $victim) { throw 'PostgreSQL did not select a deadlock victim within six seconds.' }
    $deadlockError = $victim.StandardError.ReadToEnd()
    if ($deadlockError -notmatch '40P01') {
        throw "Expected retryable SQLSTATE 40P01, received: $deadlockError"
    }
}
catch { $primaryError = $_ }
finally {
    try { Close-PsqlChildrenBounded @($deadlockA, $deadlockB) }
    catch { $cleanupError = $_ }
}
Complete-PsqlProtectedBlock $primaryError $cleanupError 'forced-deadlock scenario'
if ((Invoke-ScalarSql "SELECT (count(*) = 2)::text FROM cafe_fausse.customers WHERE email LIKE 'deadlock-%';") -ne 'true') {
    throw 'Deadlock test changed committed customer state.'
}
$script:ScenarioCount++
Write-Host 'forced deadlock and retryable SQLSTATE preservation: PASS'

# Lost response simulation: commit, discard the first returned row, reconnect, and retry normally.
Reset-ScenarioState
$lostSession = New-PsqlSession 'db06_lost_response'
$primaryError = $null
$cleanupError = $null
try {
    Send-SessionSql $lostSession "BEGIN; SET LOCAL ROLE cafe_fausse_test; $exactA; COMMIT; \echo COMMITTED_WITH_RESPONSE_DISCARDED"
    [void](Wait-SessionMarker $lostSession 'COMMITTED_WITH_RESPONSE_DISCARDED')
}
catch { $primaryError = $_ }
finally {
    try { Close-PsqlChildrenBounded @($lostSession) }
    catch { $cleanupError = $_ }
}
Complete-PsqlProtectedBlock $primaryError $cleanupError 'lost-response scenario'
$retryOutcome = Invoke-ScalarSql "SET ROLE cafe_fausse_test; $exactB; RESET ROLE;"
if ($retryOutcome -notmatch '^exact_retry\|') {
    throw "Lost-response resubmission returned '$retryOutcome'."
}
Assert-CommonCommittedState "(SELECT count(*) = 1 FROM cafe_fausse.reservations)"
$script:ScenarioCount++
Write-Host 'connection loss after commit and ordinary resubmission: PASS'

Write-Host "DB-06 deterministic concurrency suite completed: $script:ScenarioCount scenario iterations PASS."
