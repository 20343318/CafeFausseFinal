[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('AUTHORIZED_NONPRODUCTION')]
    [string]$NonProductionClusterAuthorization,

    [ValidateSet('chrome', 'edge')]
    [string]$Browser = 'chrome',

    [ValidateRange(1024, 65535)]
    [int]$CdpPort = 9341
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
Add-Type -AssemblyName System.Net.Http
trap {
    Write-Error $_
    exit 1
}

$Repository = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\')
$EnvironmentHelper = Join-Path $PSScriptRoot 'owned-live-integration.ps1'
$BrowserHelper = Join-Path $PSScriptRoot 'owned-browser-process.ps1'
$BrowserVerifier = Join-Path $PSScriptRoot 'verify-full-integration-browser.mjs'
$ExistingBrowserVerifier = Join-Path $PSScriptRoot 'verify-live-browser.mjs'
$Psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
$BaseUri = 'http://127.0.0.1:5173'
$PostgresPort = 55435
$Database = 'cafe_fausse_test_api04'
$VerifierLogin = 'cafe_fausse_prompt24_verifier'
$RunId = [guid]::NewGuid().ToString('N')

function Send-Api {
    param(
        [Parameter(Mandatory)][ValidateSet('GET', 'POST')][string]$Method,
        [Parameter(Mandatory)][string]$Path,
        $Body
    )
    $Client = [Net.Http.HttpClient]::new()
    try {
        $Request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::new($Method), "$BaseUri$Path")
        if ($Method -eq 'POST') {
            $Json = $Body | ConvertTo-Json -Depth 12 -Compress
            $Request.Content = [Net.Http.StringContent]::new($Json, [Text.Encoding]::UTF8, 'application/json')
        }
        $Response = $Client.SendAsync($Request).GetAwaiter().GetResult()
        $Text = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        try { $Parsed = $Text | ConvertFrom-Json }
        catch { throw "The live $Method $Path response was not JSON." }
        if (-not ([string]$Response.Content.Headers.ContentType).StartsWith('application/json', [StringComparison]::OrdinalIgnoreCase)) {
            throw "The live $Method $Path response content type was not JSON."
        }
        if (([string]$Response.Headers.CacheControl).IndexOf('no-store', [StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw "The live $Method $Path response lacked no-store."
        }
        return [pscustomobject]@{ status = [int]$Response.StatusCode; body = $Parsed }
    }
    finally { $Client.Dispose() }
}

function Assert-Status {
    param([Parameter(Mandatory)]$Response, [Parameter(Mandatory)][int]$Expected, [Parameter(Mandatory)][string]$Description)
    if ($Response.status -ne $Expected) {
        $Code = if ($Response.body.PSObject.Properties.Name -contains 'error') { [string]$Response.body.error.code } else { 'success-body' }
        throw "$Description returned HTTP $($Response.status) / $Code; expected $Expected."
    }
}

function Assert-Error {
    param(
        [Parameter(Mandatory)]$Response,
        [Parameter(Mandatory)][int]$Status,
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][bool]$Retryable,
        [Parameter(Mandatory)][bool]$OutcomeUnknown
    )
    Assert-Status $Response $Status $Code
    if ([string]$Response.body.error.code -cne $Code -or
        [bool]$Response.body.error.retryable -ne $Retryable -or
        [bool]$Response.body.error.outcome_unknown -ne $OutcomeUnknown) {
        throw "The $Code error envelope did not match API-02."
    }
}

function Invoke-VerifierSql {
    param([Parameter(Mandatory)][string]$Sql)
    $Output = & $Psql -X -qAt -v ON_ERROR_STOP=1 -h 127.0.0.1 -p $PostgresPort `
        -U $VerifierLogin -d $Database -c "SET ROLE cafe_fausse_test; $Sql"
    if ($LASTEXITCODE -ne 0) { throw 'Prompt-25 verifier-role SQL failed.' }
    return (@($Output) -join [Environment]::NewLine).Trim()
}

function Invoke-BrowserMode {
    param([Parameter(Mandatory)][string]$Mode, [string[]]$Arguments = @())
    $Output = @(& node $BrowserVerifier $Mode $CdpPort $Browser $RunId @Arguments)
    if ($LASTEXITCODE -ne 0) { throw "Prompt-25 browser mode $Mode failed." }
    $JsonLine = @($Output | Where-Object { $_ -match '^\{' })[-1]
    if (-not $JsonLine) { throw "Prompt-25 browser mode $Mode returned no JSON evidence." }
    return $JsonLine | ConvertFrom-Json
}

function New-Identity {
    param([Parameter(Mandatory)][string]$Label, [string]$MiddleInitial)
    $Identity = [ordered]@{
        first_name = 'Prompt'
        last_name = 'Twentyfive'
        email = "prompt25-$Label-$RunId@example.test"
        confirmation_email = "prompt25-$Label-$RunId@example.test"
    }
    if ($MiddleInitial) { $Identity.middle_initial = $MiddleInitial }
    return $Identity
}

function New-ReservationBody {
    param([Parameter(Mandatory)]$Identity, [Parameter(Mandatory)]$Slot, [int]$PartySize = 4, [string]$NewsletterAction = 'no_change')
    $Body = [ordered]@{}
    foreach ($Property in $Identity.GetEnumerator()) { $Body[$Property.Key] = $Property.Value }
    $Body.starts_at_local = [string]$Slot.starts_at_local
    $Body.utc_offset_minutes = [int]$Slot.utc_offset_minutes
    $Body.party_size = $PartySize
    $Body.newsletter_action = $NewsletterAction
    return $Body
}

function Find-AvailableDate {
    param([Parameter(Mandatory)]$Context, [int]$PartySize = 4, [int]$StartOffset = 1)
    $Minimum = [datetime]::ParseExact([string]$Context.reservable_date_range.minimum_local_date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
    for ($Offset = $StartOffset; $Offset -le 14; $Offset++) {
        $Date = $Minimum.AddDays($Offset).ToString('yyyy-MM-dd')
        $Availability = Send-Api -Method GET -Path "/api/v1/reservation-availability?local_date=$Date&party_size=$PartySize"
        Assert-Status $Availability 200 'availability date discovery'
        if (@($Availability.body.slots | Where-Object { $_.available }).Count -gt 0) {
            return [pscustomobject]@{ local_date = $Date; response = $Availability.body }
        }
    }
    throw "No available date was found for party size $PartySize."
}

function Assert-BrowserContextMatchesApi {
    param([Parameter(Mandatory)]$BrowserEvidence, [Parameter(Mandatory)]$Context, [Parameter(Mandatory)]$Availability)
    $Ui = $BrowserEvidence.result
    if ([string]$Ui.minimumLocalDate -cne [string]$Context.reservable_date_range.minimum_local_date -or
        [string]$Ui.maximumLocalDate -cne [string]$Context.reservable_date_range.maximum_local_date -or
        [int]$Ui.maximumPartySize -ne [int]$Context.maximum_party_size) {
        throw 'React date or party bounds did not match OP-01.'
    }
    $ExpectedPolicy = @(
        "$($Context.reservation_policy.start_interval_minutes) minutes",
        "$($Context.reservation_policy.reservation_duration_minutes) minutes",
        "$($Context.reservation_policy.same_day_lead_minutes) minutes",
        "$($Context.reservation_policy.advance_window_days) days"
    )
    if ((@($Ui.policy) -join '|') -cne ($ExpectedPolicy -join '|')) { throw 'React policy facts did not match OP-01.' }
    $UiSlots = @($Ui.slots)
    $ApiSlots = @($Availability.slots)
    if ($UiSlots.Count -ne $ApiSlots.Count) { throw 'React and OP-02 slot counts differ.' }
    for ($Index = 0; $Index -lt $ApiSlots.Count; $Index++) {
        if ([string]$UiSlots[$Index].startsAtLocal -cne [string]$ApiSlots[$Index].starts_at_local -or
            [bool]$UiSlots[$Index].disabled -ne (-not [bool]$ApiSlots[$Index].available)) {
            throw "React and OP-02 differ at slot index $Index."
        }
    }
}

Set-Location $Repository
& $EnvironmentHelper -Action Status -NonProductionClusterAuthorization $NonProductionClusterAuthorization
if ($LASTEXITCODE -ne 0) { throw 'Prompt-25 environment status failed.' }
& $BrowserHelper -Action Status -Browser $Browser -CdpPort $CdpPort
if ($LASTEXITCODE -ne 0) { throw 'Prompt-25 browser ownership status failed.' }

# A failed/interrupted rerun removes only the stable Prompt-25 fictional namespace.
Invoke-VerifierSql "DELETE FROM cafe_fausse.reservation_table_assignments a USING cafe_fausse.reservations r, cafe_fausse.customers c WHERE a.reservation_id=r.reservation_id AND r.customer_id=c.customer_id AND c.email LIKE 'prompt25-%@example.test'; DELETE FROM cafe_fausse.reservations r USING cafe_fausse.customers c WHERE r.customer_id=c.customer_id AND c.email LIKE 'prompt25-%@example.test'; DELETE FROM cafe_fausse.customers WHERE email LIKE 'prompt25-%@example.test';" | Out-Null

$Newsletter = Invoke-BrowserMode -Mode 'newsletter'
$NewsletterEmail = [string]$Newsletter.result.email
$NewsletterEvidence = Invoke-VerifierSql "SELECT concat_ws('|',count(*),min(first_name),min(middle_initial),min(last_name),bool_and(newsletter_subscribed)) FROM cafe_fausse.customers WHERE email='$NewsletterEmail';"
if ($NewsletterEvidence -cne '1|Prompt|M|Twentyfive|t') { throw "Newsletter PostgreSQL evidence was unexpected: $NewsletterEvidence" }

$InvalidIdentity = New-Identity 'server-invalid'
$InvalidIdentity.email = 'not-an-email'
$InvalidIdentity.confirmation_email = 'not-an-email'
$InvalidBody = [ordered]@{}
foreach ($Property in $InvalidIdentity.GetEnumerator()) { $InvalidBody[$Property.Key] = $Property.Value }
$InvalidBody.subscribed = $true
$InvalidNewsletter = Send-Api -Method POST -Path '/api/v1/newsletter-preferences' -Body $InvalidBody
Assert-Error $InvalidNewsletter 422 'validation_failed' $false $false
$InvalidServerCount = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.customers WHERE email='not-an-email';"
if ($InvalidServerCount -cne '0') { throw 'Server-invalid newsletter input created a customer.' }

$Context = (Send-Api -Method GET -Path '/api/v1/reservation-context').body
$ContextDate = Find-AvailableDate -Context $Context -PartySize 4 -StartOffset 1
$BaselineAvailability = (Send-Api -Method GET -Path "/api/v1/reservation-availability?local_date=$($ContextDate.local_date)&party_size=4").body
$BaselineBrowser = Invoke-BrowserMode -Mode 'context' -Arguments @($ContextDate.local_date, '4')
Assert-BrowserContextMatchesApi $BaselineBrowser $Context $BaselineAvailability

$OriginalInterval = [int]$Context.reservation_policy.start_interval_minutes
$OriginalDuration = [int]$Context.reservation_policy.reservation_duration_minutes
$OriginalWindow = [int]$Context.reservation_policy.advance_window_days
$OriginalLead = [int]$Context.reservation_policy.same_day_lead_minutes
$OriginalTimezone = [string]$Context.restaurant_timezone
$ChangedInterval = if ($OriginalInterval -eq 60) { 30 } else { 60 }
try {
    Invoke-VerifierSql "SELECT cafe_fausse.set_reservation_configuration($ChangedInterval::smallint,$OriginalDuration::smallint,$OriginalWindow::smallint,$OriginalLead::smallint,'$OriginalTimezone'::text);" | Out-Null
    $ChangedContext = (Send-Api -Method GET -Path '/api/v1/reservation-context').body
    if ([int]$ChangedContext.reservation_policy.start_interval_minutes -ne $ChangedInterval) { throw 'The approved configuration change did not reach Flask.' }
    $ChangedAvailability = (Send-Api -Method GET -Path "/api/v1/reservation-availability?local_date=$($ContextDate.local_date)&party_size=4").body
    $ChangedBrowser = Invoke-BrowserMode -Mode 'context' -Arguments @($ContextDate.local_date, '4')
    Assert-BrowserContextMatchesApi $ChangedBrowser $ChangedContext $ChangedAvailability
    if ((@($ChangedAvailability.slots).Count -eq @($BaselineAvailability.slots).Count) -and
        ((@($ChangedAvailability.slots | ForEach-Object { $_.starts_at_local }) -join '|') -ceq (@($BaselineAvailability.slots | ForEach-Object { $_.starts_at_local }) -join '|'))) {
        throw 'The approved interval setting change did not change slot behavior.'
    }
}
finally {
    Invoke-VerifierSql "SELECT cafe_fausse.set_reservation_configuration($OriginalInterval::smallint,$OriginalDuration::smallint,$OriginalWindow::smallint,$OriginalLead::smallint,'$OriginalTimezone'::text);" | Out-Null
}
$RestoredContext = (Send-Api -Method GET -Path '/api/v1/reservation-context').body
$RestoredAvailability = (Send-Api -Method GET -Path "/api/v1/reservation-availability?local_date=$($ContextDate.local_date)&party_size=4").body
$RestoredBrowser = Invoke-BrowserMode -Mode 'context' -Arguments @($ContextDate.local_date, '4')
Assert-BrowserContextMatchesApi $RestoredBrowser $RestoredContext $RestoredAvailability
if ([int]$RestoredContext.reservation_policy.start_interval_minutes -ne $OriginalInterval -or
    (@($RestoredAvailability.slots | ForEach-Object { $_.starts_at_local }) -join '|') -cne (@($BaselineAvailability.slots | ForEach-Object { $_.starts_at_local }) -join '|')) {
    throw 'Restoring the approved setting did not restore original behavior.'
}

$ReservationDate = Find-AvailableDate -Context $RestoredContext -PartySize 6 -StartOffset 2
$Reservation = Invoke-BrowserMode -Mode 'reservation-success' -Arguments @($ReservationDate.local_date, '6')
$ReservationEmail = [string]$Reservation.result.email
$ReservationReference = [string]$Reservation.result.reservationReference
$ReservationEvidence = Invoke-VerifierSql "SELECT concat_ws('|',(SELECT count(*) FROM cafe_fausse.customers WHERE email='$ReservationEmail'),(SELECT count(*) FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email='$ReservationEmail'),(SELECT count(*) FROM cafe_fausse.reservation_table_assignments a JOIN cafe_fausse.reservations r ON r.reservation_id=a.reservation_id JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email='$ReservationEmail'),(SELECT count(DISTINCT a.table_number) FROM cafe_fausse.reservation_table_assignments a JOIN cafe_fausse.reservations r ON r.reservation_id=a.reservation_id JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email='$ReservationEmail'),(SELECT bool_and(newsletter_subscribed) FROM cafe_fausse.customers WHERE email='$ReservationEmail'));"
$ReservationParts = $ReservationEvidence.Split('|')
if ($ReservationParts.Count -ne 5 -or $ReservationParts[0] -cne '1' -or $ReservationParts[1] -cne '1' -or
    [int]$ReservationParts[2] -ne @($Reservation.result.assignedTables).Count -or $ReservationParts[3] -cne $ReservationParts[2] -or $ReservationParts[4] -cne 't') {
    throw "React reservation PostgreSQL evidence was unexpected: $ReservationEvidence"
}
$StoredReference = Invoke-VerifierSql "SELECT r.reservation_id::text FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email='$ReservationEmail';"
if ($StoredReference -cne $ReservationReference) { throw 'React confirmation reference did not match PostgreSQL.' }
$ReactAssignedSet = (@($Reservation.result.assignedTables | ForEach-Object { [int]$_ } | Sort-Object -Unique) -join ',')
$StoredAssignedSet = Invoke-VerifierSql "SELECT string_agg(a.table_number::text,',' ORDER BY a.table_number) FROM cafe_fausse.reservation_table_assignments a JOIN cafe_fausse.reservations r ON r.reservation_id=a.reservation_id JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE r.reservation_id=$($ReservationReference)::bigint AND c.email='$ReservationEmail';"
if ($StoredAssignedSet -cne $ReactAssignedSet) {
    throw "React assigned tables did not match PostgreSQL: React=$ReactAssignedSet PostgreSQL=$StoredAssignedSet"
}

$SelectedSlot = @($ReservationDate.response.slots | Where-Object { $_.starts_at_local -ceq [string]$Reservation.result.selectedStart })[0]
if ($null -eq $SelectedSlot) { throw 'The UI-selected reservation slot was not in the authoritative OP-02 response.' }
$OverlapIdentity = New-Identity 'overlap-other'
$OverlapBody = New-ReservationBody $OverlapIdentity $SelectedSlot 4 'no_change'
$OverlapBooking = Send-Api -Method POST -Path '/api/v1/reservations' -Body $OverlapBody
Assert-Status $OverlapBooking 201 'different-customer overlapping booking'
$SharedTableCount = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.reservation_table_assignments a1 JOIN cafe_fausse.reservations r1 ON r1.reservation_id=a1.reservation_id JOIN cafe_fausse.customers c1 ON c1.customer_id=r1.customer_id JOIN cafe_fausse.reservation_table_assignments a2 ON a2.table_number=a1.table_number JOIN cafe_fausse.reservations r2 ON r2.reservation_id=a2.reservation_id JOIN cafe_fausse.customers c2 ON c2.customer_id=r2.customer_id WHERE c1.email='$ReservationEmail' AND c2.email='$($OverlapIdentity.email)' AND r1.starts_at < r2.ends_at AND r2.starts_at < r1.ends_at;"
if ($SharedTableCount -cne '0') { throw 'An overlapping reservation reused a table assigned by the React booking.' }

$RetryDate = Find-AvailableDate -Context $RestoredContext -PartySize 4 -StartOffset 3
$Unknown = Invoke-BrowserMode -Mode 'reservation-unknown' -Arguments @($RetryDate.local_date, '4')
if (-not [bool]$Unknown.result.outcomeUnknown -or -not [bool]$Unknown.result.recoveryLocked -or
    [int]$Unknown.result.committedResponse.status -ne 201 -or
    [string]$Unknown.result.committedResponse.body.booking_result -cne 'created') {
    throw 'Controlled post-commit transport loss did not produce the expected locked React uncertainty state.'
}
$RetryEmail = [string]$Unknown.result.email
$RetryBefore = Invoke-VerifierSql "SELECT concat_ws('|',(SELECT count(*) FROM cafe_fausse.customers WHERE email='$RetryEmail'),(SELECT count(*) FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email='$RetryEmail'),(SELECT newsletter_subscribed FROM cafe_fausse.customers WHERE email='$RetryEmail'));"
if ($RetryBefore -cne '1|1|t') { throw "The first UI retry request did not commit exactly once: $RetryBefore" }
$UnsubscribeBody = [ordered]@{}
foreach ($Property in @('first_name','middle_initial','last_name','email','confirmation_email')) { $UnsubscribeBody[$Property] = $Unknown.result.submittedBody.$Property }
$UnsubscribeBody.subscribed = $false
$Unsubscribed = Send-Api -Method POST -Path '/api/v1/newsletter-preferences' -Body $UnsubscribeBody
Assert-Status $Unsubscribed 200 'distinguishing newsletter update before exact retry'
$Recovered = Invoke-BrowserMode -Mode 'reservation-recover'
if ([int]$Recovered.result.attempts -ne 2) {
    throw "React made $($Recovered.result.attempts) OP-05 attempts; expected exactly two."
}
if ([string]$Recovered.result.retryBodyText -cne [string]$Unknown.result.submittedBodyText) {
    throw 'React did not resend the byte-identical captured OP-05 body.'
}
if ([int]$Recovered.result.retryResponse.status -ne 200 -or
    [string]$Recovered.result.retryResponse.body.booking_result -cne 'exact_retry') {
    throw 'The second OP-05 response did not match the frozen HTTP 200 / booking_result exact_retry contract.'
}
$FirstRetryReference = [string]$Unknown.result.committedResponse.body.confirmation.reservation_reference
$SecondRetryReference = [string]$Recovered.result.retryResponse.body.confirmation.reservation_reference
if ($SecondRetryReference -cne $FirstRetryReference -or
    [string]$Recovered.result.reservationReference -cne $FirstRetryReference -or
    [bool]$Recovered.result.retryResponse.body.confirmation.newsletter_subscribed -ne $false -or
    -not [bool]$Recovered.result.recovered -or
    [string]$Recovered.result.newsletter -cne 'Not subscribed') {
    throw 'React exact retry did not recover the existing reservation with current newsletter false.'
}
$RetryAfter = Invoke-VerifierSql "SELECT concat_ws('|',(SELECT count(*) FROM cafe_fausse.customers WHERE email='$RetryEmail'),(SELECT count(*) FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email='$RetryEmail'),(SELECT newsletter_subscribed FROM cafe_fausse.customers WHERE email='$RetryEmail'));"
if ($RetryAfter -cne '1|1|f') { throw "Exact retry duplicated the booking or replayed newsletter subscribe: $RetryAfter" }

$ManipulatedIdentity = New-Identity 'manipulated-slot'
$ManipulatedSlot = [ordered]@{}
foreach ($Property in $SelectedSlot.PSObject.Properties) { $ManipulatedSlot[$Property.Name] = $Property.Value }
$ManipulatedStart = [datetimeoffset]::Parse([string]$SelectedSlot.starts_at_local).AddMinutes(1)
$ManipulatedSlot.starts_at_local = $ManipulatedStart.ToString("yyyy-MM-dd'T'HH:mm:sszzz", [Globalization.CultureInfo]::InvariantCulture)
$ManipulatedBody = New-ReservationBody $ManipulatedIdentity $ManipulatedSlot 4 'no_change'
$Manipulated = Send-Api -Method POST -Path '/api/v1/reservations' -Body $ManipulatedBody
Assert-Error $Manipulated 422 'validation_failed' $false $false
if (-not @($Manipulated.body.error.fields | Where-Object { $_.field -eq 'starts_at_local' -and $_.code -eq 'invalid_reservation_time' }).Count) {
    throw 'The manipulated slot did not receive the frozen invalid_reservation_time field error.'
}
$ManipulatedCount = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.customers WHERE email='$($ManipulatedIdentity.email)';"
if ($ManipulatedCount -cne '0') { throw 'The manipulated reservation slot created customer state.' }

$FullDate = Find-AvailableDate -Context $RestoredContext -PartySize 120 -StartOffset 8
$BlockIndex = 0
while ($true) {
    $FullSnapshot = (Send-Api -Method GET -Path "/api/v1/reservation-availability?local_date=$($FullDate.local_date)&party_size=120").body
    $Available = @($FullSnapshot.slots | Where-Object { $_.available })
    if ($Available.Count -eq 0) { break }
    $BlockIdentity = New-Identity "full-$BlockIndex"
    $BlockBody = New-ReservationBody $BlockIdentity $Available[0] 120 'no_change'
    $Block = Send-Api -Method POST -Path '/api/v1/reservations' -Body $BlockBody
    Assert-Status $Block 201 "full-capacity blocker $BlockIndex"
    $BlockIndex += 1
    if ($BlockIndex -gt 16) { throw 'The full-capacity setup exceeded its deterministic bound.' }
}
if (@($FullSnapshot.slots).Count -eq 0) { throw 'The controlled fully booked date had no legitimate schedule.' }
$FullBrowser = Invoke-BrowserMode -Mode 'fully-booked' -Arguments @($FullDate.local_date, '120')
if ([int]$FullBrowser.result.slotCount -ne @($FullSnapshot.slots).Count -or [int]$FullBrowser.result.disabledCount -ne @($FullSnapshot.slots).Count) {
    throw 'React fully booked state did not match OP-02.'
}
$UnavailableIdentity = New-Identity 'unavailable'
$UnavailableBody = New-ReservationBody $UnavailableIdentity @($FullSnapshot.slots)[0] 120 'no_change'
$Unavailable = Send-Api -Method POST -Path '/api/v1/reservations' -Body $UnavailableBody
Assert-Error $Unavailable 409 'reservation_unavailable' $false $false
$UnavailableCount = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.customers WHERE email='$($UnavailableIdentity.email)';"
if ($UnavailableCount -cne '0') { throw 'The fully booked reservation attempt created customer state.' }

$OverlapInvariant = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.reservation_table_assignments a1 JOIN cafe_fausse.reservations r1 ON r1.reservation_id=a1.reservation_id JOIN cafe_fausse.reservation_table_assignments a2 ON a2.table_number=a1.table_number AND a2.reservation_id>a1.reservation_id JOIN cafe_fausse.reservations r2 ON r2.reservation_id=a2.reservation_id WHERE r1.starts_at < r2.ends_at AND r2.starts_at < r1.ends_at;"
if ($OverlapInvariant -cne '0') { throw 'Prompt-25 data contains an overlapping shared table assignment.' }

$FlaskStopped = $false
try {
    & $EnvironmentHelper -Action StopFlask -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    if ($LASTEXITCODE -ne 0) { throw 'Controlled Flask stop failed.' }
    $FlaskStopped = $true
    $FailureOutput = @(& node $ExistingBrowserVerifier failure $CdpPort "$Browser-prompt25")
    if ($LASTEXITCODE -ne 0) { throw 'Controlled React transport-failure verification failed.' }
    & $EnvironmentHelper -Action StartFlask -NonProductionClusterAuthorization $NonProductionClusterAuthorization
    if ($LASTEXITCODE -ne 0) { throw 'Controlled Flask recovery failed.' }
    $FlaskStopped = $false
    $RecoveryOutput = @(& node $ExistingBrowserVerifier recovery $CdpPort "$Browser-prompt25")
    if ($LASTEXITCODE -ne 0) { throw 'React transport recovery verification failed.' }
}
finally {
    if ($FlaskStopped) {
        & $EnvironmentHelper -Action StartFlask -NonProductionClusterAuthorization $NonProductionClusterAuthorization
        if ($LASTEXITCODE -ne 0) { throw 'Flask restoration after controlled transport failure failed.' }
    }
}

Write-Output 'PROMPT25 FULL INTEGRATION PASS'
Write-Output "Run ID: $RunId"
Write-Output "Newsletter PostgreSQL customer|first|middle|last|subscribed: $NewsletterEvidence"
Write-Output "Configuration interval baseline|changed|restored: $OriginalInterval|$ChangedInterval|$($RestoredContext.reservation_policy.start_interval_minutes)"
Write-Output "React reservation customer|reservation|assignments|distinct_assignments|newsletter: $ReservationEvidence"
Write-Output "React reservation reference: $ReservationReference"
Write-Output "React/PostgreSQL sorted assigned tables: $ReactAssignedSet"
Write-Output "Overlapping shared table assignments for the React booking: $SharedTableCount"
Write-Output "Second OP-05 response status|booking_result: $($Recovered.result.retryResponse.status)|$($Recovered.result.retryResponse.body.booking_result)"
Write-Output "Exact-retry customer|reservation|newsletter before/after: $RetryBefore -> $RetryAfter"
Write-Output "Fully booked date: $($FullDate.local_date); slots: $(@($FullSnapshot.slots).Count); blockers: $BlockIndex"
Write-Output "Global overlapping shared-table assignments: $OverlapInvariant"
Write-Output "Transport failure: $(@($FailureOutput | Where-Object { $_ -match '^\{' })[-1])"
Write-Output "Transport recovery: $(@($RecoveryOutput | Where-Object { $_ -match '^\{' })[-1])"
exit 0
