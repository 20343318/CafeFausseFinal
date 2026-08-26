[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('AUTHORIZED_NONPRODUCTION')]
    [string]$NonProductionClusterAuthorization
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
$Psql = 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
$BaseUri = 'http://127.0.0.1:5173'
$PostgresPort = 55435
$Database = 'cafe_fausse_test_api04'
$VerifierLogin = 'cafe_fausse_prompt24_verifier'
$AppLogin = 'cafe_fausse_api04_login'
$RunId = [guid]::NewGuid().ToString('N')
$Timing = [ordered]@{ 'OP-01' = @(); 'OP-02' = @(); 'OP-03' = @(); 'OP-04' = @(); 'OP-05' = @() }

function Send-Api {
    param(
        [Parameter(Mandatory)][ValidateSet('GET', 'POST')][string]$Method,
        [Parameter(Mandatory)][string]$Path,
        $Body,
        [string]$TimingOperation
    )
    $Client = [Net.Http.HttpClient]::new()
    try {
        $Request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::new($Method), "$BaseUri$Path")
        if ($Method -eq 'POST') {
            $Json = $Body | ConvertTo-Json -Depth 12 -Compress
            $Request.Content = [Net.Http.StringContent]::new($Json, [Text.Encoding]::UTF8, 'application/json')
        }
        $Watch = [Diagnostics.Stopwatch]::StartNew()
        $Response = $Client.SendAsync($Request).GetAwaiter().GetResult()
        $Text = $Response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $Watch.Stop()
        if ($TimingOperation) { $Timing[$TimingOperation] += [math]::Round($Watch.Elapsed.TotalMilliseconds, 3) }
        try { $Parsed = $Text | ConvertFrom-Json }
        catch { throw "The live $Method $Path response was not JSON." }
        $ContentType = [string]$Response.Content.Headers.ContentType
        if (-not $ContentType.StartsWith('application/json', [StringComparison]::OrdinalIgnoreCase)) {
            throw "The live $Method $Path response content type was not JSON."
        }
        $CacheControl = [string]$Response.Headers.CacheControl
        if ($CacheControl.IndexOf('no-store', [StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw "The live $Method $Path response lacked no-store."
        }
        return [pscustomobject]@{
            status = [int]$Response.StatusCode
            body = $Parsed
            elapsed_ms = [math]::Round($Watch.Elapsed.TotalMilliseconds, 3)
        }
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
        throw "The $Code error-envelope flags did not match API-02."
    }
}

function Invoke-VerifierSql {
    param([Parameter(Mandatory)][string]$Sql)
    $Output = & $Psql -X -qAt -v ON_ERROR_STOP=1 -h 127.0.0.1 -p $PostgresPort `
        -U $VerifierLogin -d $Database -c "SET ROLE cafe_fausse_test; $Sql"
    if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 verifier-role SQL failed.' }
    return (@($Output) -join [Environment]::NewLine).Trim()
}

function New-Identity {
    param([Parameter(Mandatory)][string]$Label, [string]$MiddleInitial)
    $Identity = [ordered]@{
        first_name = 'Prompt'
        last_name = 'Twentyfour'
        email = "prompt24-$Label-$RunId@example.test"
        confirmation_email = "prompt24-$Label-$RunId@example.test"
    }
    if ($MiddleInitial) { $Identity.middle_initial = $MiddleInitial }
    return $Identity
}

function Send-Identity {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Identity, $Extra, [string]$TimingOperation)
    $Body = [ordered]@{}
    foreach ($Property in $Identity.GetEnumerator()) { $Body[$Property.Key] = $Property.Value }
    if ($Extra) {
        foreach ($Property in $Extra.GetEnumerator()) { $Body[$Property.Key] = $Property.Value }
    }
    return Send-Api -Method POST -Path $Path -Body $Body -TimingOperation $TimingOperation
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

& $EnvironmentHelper -Action Status -NonProductionClusterAuthorization $NonProductionClusterAuthorization
if ($LASTEXITCODE -ne 0) { throw 'Prompt-24 environment status failed.' }

# Recovery from an ordinary failed/interrupted verifier run removes only the
# stable Prompt-24-owned email namespace, in foreign-key order, through the
# approved verifier role. The final environment cleanup still performs a full
# approved reset before destroying the disposable cluster.
Invoke-VerifierSql "DELETE FROM cafe_fausse.reservation_table_assignments a USING cafe_fausse.reservations r, cafe_fausse.customers c WHERE a.reservation_id=r.reservation_id AND r.customer_id=c.customer_id AND c.email LIKE 'prompt24-%@example.test'; DELETE FROM cafe_fausse.reservations r USING cafe_fausse.customers c WHERE r.customer_id=c.customer_id AND c.email LIKE 'prompt24-%@example.test'; DELETE FROM cafe_fausse.customers WHERE email LIKE 'prompt24-%@example.test';" | Out-Null

$Readiness = Send-Api -Method GET -Path '/api/v1/health/readiness'
Assert-Status $Readiness 200 'OP-07 readiness'
if ([string]$Readiness.body.status -cne 'ready') { throw 'OP-07 readiness body was not ready.' }

$Context = Send-Api -Method GET -Path '/api/v1/reservation-context' -TimingOperation 'OP-01'
Assert-Status $Context 200 'OP-01 context'
if (@($Context.body.weekday_hours).Count -ne 7 -or [string]$Context.body.restaurant_timezone -cne 'America/New_York') {
    throw 'OP-01 context did not expose the complete current PostgreSQL schedule/timezone.'
}

$OriginalMonday = @($Context.body.weekday_hours | Where-Object { $_.iso_weekday -eq 1 })[0]
Invoke-VerifierSql "SELECT cafe_fausse.set_restaurant_operating_hours(1::smallint, '18:00:00'::time, '22:00:00'::time);" | Out-Null
try {
    $ChangedContext = Send-Api -Method GET -Path '/api/v1/reservation-context'
    Assert-Status $ChangedContext 200 'controlled OP-01 schedule change'
    $ChangedMonday = @($ChangedContext.body.weekday_hours | Where-Object { $_.iso_weekday -eq 1 })[0]
    if ([string]$ChangedMonday.opens_at_local -cne '18:00:00' -or [string]$ChangedMonday.closes_at_local -cne '22:00:00') {
        throw 'The controlled PostgreSQL hours change did not reach OP-01.'
    }
}
finally {
    Invoke-VerifierSql "SELECT cafe_fausse.set_restaurant_operating_hours(1::smallint, '$($OriginalMonday.opens_at_local)'::time, '$($OriginalMonday.closes_at_local)'::time);" | Out-Null
}
$RestoredContext = Send-Api -Method GET -Path '/api/v1/reservation-context'
$RestoredMonday = @($RestoredContext.body.weekday_hours | Where-Object { $_.iso_weekday -eq 1 })[0]
if ([string]$RestoredMonday.opens_at_local -cne [string]$OriginalMonday.opens_at_local -or
    [string]$RestoredMonday.closes_at_local -cne [string]$OriginalMonday.closes_at_local) {
    throw 'The controlled PostgreSQL hours state was not restored.'
}

$NewsletterIdentity = New-Identity 'newsletter' 'Q'
$UnknownIdentity = New-Identity 'unknown-false'
$NewsletterCountBefore = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.customers WHERE email = '$($NewsletterIdentity.email)';"
$NotFound = Send-Identity '/api/v1/newsletter-status-queries' $NewsletterIdentity $null 'OP-03'
Assert-Status $NotFound 200 'OP-03 not_found'
if ([string]$NotFound.body.status -cne 'not_found' -or $NotFound.body.PSObject.Properties.Name -contains 'subscribed') {
    throw 'OP-03 not_found response exposed an unexpected subscribed value.'
}
$NewsletterCountAfterLookup = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.customers WHERE email = '$($NewsletterIdentity.email)';"
if ($NewsletterCountBefore -cne $NewsletterCountAfterLookup) { throw 'OP-03 lookup persisted a side effect.' }

$Subscribed = Send-Identity '/api/v1/newsletter-preferences' $NewsletterIdentity ([ordered]@{ subscribed = $true }) 'OP-04'
Assert-Status $Subscribed 200 'OP-04 unknown subscribe'
if ([string]$Subscribed.body.result -cne 'set' -or -not [bool]$Subscribed.body.subscribed) { throw 'OP-04 subscribe result was not authoritative true.' }
$Matched = Send-Identity '/api/v1/newsletter-status-queries' $NewsletterIdentity $null 'OP-03'
Assert-Status $Matched 200 'OP-03 matched'
if ([string]$Matched.body.status -cne 'matched' -or -not [bool]$Matched.body.subscribed) { throw 'OP-03 matched result was not authoritative true.' }

$IdentityConflictBody = [ordered]@{}
foreach ($Property in $NewsletterIdentity.GetEnumerator()) { $IdentityConflictBody[$Property.Key] = $Property.Value }
$IdentityConflictBody.first_name = 'Different'
$IdentityConflict = Send-Identity '/api/v1/newsletter-status-queries' $IdentityConflictBody $null
Assert-Error $IdentityConflict 409 'customer_identity_conflict' $false $false
$MiddleConflictBody = [ordered]@{}
foreach ($Property in $NewsletterIdentity.GetEnumerator()) { $MiddleConflictBody[$Property.Key] = $Property.Value }
$MiddleConflictBody.middle_initial = 'R'
$MiddleConflict = Send-Identity '/api/v1/newsletter-status-queries' $MiddleConflictBody $null
Assert-Error $MiddleConflict 409 'middle_initial_conflict' $false $false

$NewsletterStateBeforeOp04Conflicts = Invoke-VerifierSql "SELECT concat_ws('|',count(*),bool_and(newsletter_subscribed)) FROM cafe_fausse.customers WHERE email = '$($NewsletterIdentity.email)';"
$Op04IdentityConflict = Send-Identity '/api/v1/newsletter-preferences' $IdentityConflictBody ([ordered]@{ subscribed = $false })
Assert-Error $Op04IdentityConflict 409 'customer_identity_conflict' $false $false
$NewsletterStateAfterIdentityConflict = Invoke-VerifierSql "SELECT concat_ws('|',count(*),bool_and(newsletter_subscribed)) FROM cafe_fausse.customers WHERE email = '$($NewsletterIdentity.email)';"
if ($NewsletterStateAfterIdentityConflict -cne $NewsletterStateBeforeOp04Conflicts) {
    throw 'OP-04 customer_identity_conflict caused an unsafe customer/newsletter mutation.'
}
$Op04MiddleConflict = Send-Identity '/api/v1/newsletter-preferences' $MiddleConflictBody ([ordered]@{ subscribed = $false })
Assert-Error $Op04MiddleConflict 409 'middle_initial_conflict' $false $false
$NewsletterStateAfterMiddleConflict = Invoke-VerifierSql "SELECT concat_ws('|',count(*),bool_and(newsletter_subscribed)) FROM cafe_fausse.customers WHERE email = '$($NewsletterIdentity.email)';"
if ($NewsletterStateAfterMiddleConflict -cne $NewsletterStateBeforeOp04Conflicts) {
    throw 'OP-04 middle_initial_conflict caused an unsafe customer/newsletter mutation.'
}

$Unsubscribed = Send-Identity '/api/v1/newsletter-preferences' $NewsletterIdentity ([ordered]@{ subscribed = $false }) 'OP-04'
Assert-Status $Unsubscribed 200 'OP-04 unsubscribe'
if ([bool]$Unsubscribed.body.subscribed) { throw 'OP-04 unsubscribe did not return false.' }
$Resubscribed = Send-Identity '/api/v1/newsletter-preferences' $NewsletterIdentity ([ordered]@{ subscribed = $true }) 'OP-04'
Assert-Status $Resubscribed 200 'OP-04 resubscribe'
$SameState = Send-Identity '/api/v1/newsletter-preferences' $NewsletterIdentity ([ordered]@{ subscribed = $true }) 'OP-04'
Assert-Status $SameState 200 'OP-04 same-state request'
$NoCustomerNoChange = Send-Identity '/api/v1/newsletter-preferences' $UnknownIdentity ([ordered]@{ subscribed = $false })
Assert-Status $NoCustomerNoChange 200 'OP-04 unknown false'
if ([string]$NoCustomerNoChange.body.result -cne 'no_customer_no_change' -or [bool]$NoCustomerNoChange.body.subscribed) {
    throw 'OP-04 unknown false did not return no_customer_no_change.'
}
$UnknownCount = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.customers WHERE email = '$($UnknownIdentity.email)';"
if ($UnknownCount -cne '0') { throw 'OP-04 unknown false created a customer.' }

$MinimumDate = [datetime]::ParseExact([string]$Context.body.reservable_date_range.minimum_local_date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
$Availability = $null
for ($DayOffset = 1; $DayOffset -le 7; $DayOffset++) {
    $LocalDate = $MinimumDate.AddDays($DayOffset).ToString('yyyy-MM-dd')
    $Candidate = Send-Api -Method GET -Path "/api/v1/reservation-availability?local_date=$LocalDate&party_size=4" -TimingOperation 'OP-02'
    Assert-Status $Candidate 200 'OP-02 availability'
    if (@($Candidate.body.slots | Where-Object { $_.available }).Count -gt 0) { $Availability = $Candidate; break }
}
if ($null -eq $Availability) { throw 'No deterministic future live availability date was found.' }
$Slots = @($Availability.body.slots)
if ($Slots.Count -eq 0) { throw 'OP-02 returned no legitimate slots for the selected live date.' }
for ($Index = 1; $Index -lt $Slots.Count; $Index++) {
    if ([datetimeoffset]::Parse($Slots[$Index - 1].starts_at) -gt [datetimeoffset]::Parse($Slots[$Index].starts_at)) {
        throw 'OP-02 did not preserve canonical ascending API order.'
    }
}
$Slot = @($Slots | Where-Object { $_.available })[0]

$ReservationIdentity = New-Identity 'reservation' 'M'
$ReservationBody = New-ReservationBody $ReservationIdentity $Slot 4 'subscribe'
$OriginalReservationSnapshot = $ReservationBody | ConvertTo-Json -Depth 12 -Compress
$Created = Send-Api -Method POST -Path '/api/v1/reservations' -Body $ReservationBody -TimingOperation 'OP-05'
Assert-Status $Created 201 'OP-05 created reservation'
if ([string]$Created.body.booking_result -cne 'created' -or
    [string]$Created.body.confirmation.reservation_reference -notmatch '^[1-9][0-9]*$' -or
    @($Created.body.confirmation.assigned_table_numbers).Count -lt 1 -or
    -not [bool]$Created.body.confirmation.newsletter_subscribed) {
    throw 'OP-05 created confirmation omitted or altered authoritative public facts.'
}
foreach ($Forbidden in @('email', 'phone', 'customer_id', 'fingerprint', 'capacity')) {
    if ($Created.body.confirmation.PSObject.Properties.Name -contains $Forbidden) { throw "OP-05 confirmation leaked $Forbidden." }
}

$ExplicitUnsubscribe = Send-Identity '/api/v1/newsletter-preferences' $ReservationIdentity ([ordered]@{ subscribed = $false }) 'OP-04'
Assert-Status $ExplicitUnsubscribe 200 'OP-04 distinguishing unsubscribe before OP-05 exact retry'
if ([bool]$ExplicitUnsubscribe.body.subscribed) {
    throw 'The distinguishing OP-04 action did not set newsletter state false.'
}
$NewsletterFalseBeforeRetry = Invoke-VerifierSql "SELECT concat_ws('|',count(*),bool_and(NOT newsletter_subscribed)) FROM cafe_fausse.customers WHERE email = '$($ReservationIdentity.email)';"
if ($NewsletterFalseBeforeRetry -cne '1|t') {
    throw "The distinguishing newsletter state was not false before exact retry: $NewsletterFalseBeforeRetry"
}
if (($ReservationBody | ConvertTo-Json -Depth 12 -Compress) -cne $OriginalReservationSnapshot) {
    throw 'The original OP-05 request snapshot changed before exact retry.'
}
$ExactRetry = Send-Api -Method POST -Path '/api/v1/reservations' -Body $ReservationBody -TimingOperation 'OP-05'
Assert-Status $ExactRetry 200 'OP-05 exact retry'
if ([string]$ExactRetry.body.booking_result -cne 'exact_retry' -or
    [string]$ExactRetry.body.confirmation.reservation_reference -cne [string]$Created.body.confirmation.reservation_reference -or
    [bool]$ExactRetry.body.confirmation.newsletter_subscribed) {
    throw 'OP-05 exact retry did not reconstruct the same reservation with current newsletter false.'
}

$ReservationEvidence = Invoke-VerifierSql "SELECT concat_ws('|',(SELECT count(*) FROM cafe_fausse.customers WHERE email = '$($ReservationIdentity.email)'),(SELECT count(*) FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email = '$($ReservationIdentity.email)'),(SELECT count(*) FROM cafe_fausse.reservation_table_assignments a JOIN cafe_fausse.reservations r ON r.reservation_id=a.reservation_id JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email = '$($ReservationIdentity.email)'),(SELECT count(DISTINCT a.table_number) FROM cafe_fausse.reservation_table_assignments a JOIN cafe_fausse.reservations r ON r.reservation_id=a.reservation_id JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email = '$($ReservationIdentity.email)'),(SELECT newsletter_subscribed FROM cafe_fausse.customers WHERE email = '$($ReservationIdentity.email)'));"
$EvidenceParts = $ReservationEvidence.Split('|')
$ExpectedAssignmentCount = @($Created.body.confirmation.assigned_table_numbers).Count
if ($EvidenceParts.Count -ne 5 -or $EvidenceParts[0] -cne '1' -or $EvidenceParts[1] -cne '1' -or
    [int]$EvidenceParts[2] -ne $ExpectedAssignmentCount -or
    $EvidenceParts[3] -cne $EvidenceParts[2] -or $EvidenceParts[4] -cne 'f') {
    throw "Reservation PostgreSQL-effect evidence was unexpected: $ReservationEvidence"
}

$OverlapBody = [ordered]@{}
foreach ($Property in $ReservationBody.GetEnumerator()) { $OverlapBody[$Property.Key] = $Property.Value }
$OverlappingSlots = @($Slots | Where-Object {
    $_.available -and
    $_.starts_at_local -ne $Slot.starts_at_local -and
    [datetimeoffset]::Parse($_.starts_at) -lt [datetimeoffset]::Parse($Slot.ends_at) -and
    [datetimeoffset]::Parse($Slot.starts_at) -lt [datetimeoffset]::Parse($_.ends_at)
})
if ($OverlappingSlots.Count -eq 0) { throw 'No controlled overlapping server slot was available.' }
$OverlappingSlot = $OverlappingSlots[0]
$OverlapBody.starts_at_local = [string]$OverlappingSlot.starts_at_local
$OverlapBody.utc_offset_minutes = [int]$OverlappingSlot.utc_offset_minutes
$Overlap = Send-Api -Method POST -Path '/api/v1/reservations' -Body $OverlapBody
Assert-Error $Overlap 409 'reservation_overlap' $false $false

$ConflictReservationBody = [ordered]@{}
foreach ($Property in $ReservationBody.GetEnumerator()) { $ConflictReservationBody[$Property.Key] = $Property.Value }
$ConflictReservationBody.first_name = 'Different'
$ReservationIdentityConflict = Send-Api -Method POST -Path '/api/v1/reservations' -Body $ConflictReservationBody
Assert-Error $ReservationIdentityConflict 409 'customer_identity_conflict' $false $false

$MiddleConflictReservationBody = [ordered]@{}
foreach ($Property in $ReservationBody.GetEnumerator()) { $MiddleConflictReservationBody[$Property.Key] = $Property.Value }
$MiddleConflictReservationBody.middle_initial = 'N'
$ReservationCountBeforeMiddleConflict = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email = '$($ReservationIdentity.email)';"
$ReservationMiddleInitialConflict = Send-Api -Method POST -Path '/api/v1/reservations' -Body $MiddleConflictReservationBody
Assert-Error $ReservationMiddleInitialConflict 409 'middle_initial_conflict' $false $false
$ReservationCountAfterMiddleConflict = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.reservations r JOIN cafe_fausse.customers c ON c.customer_id=r.customer_id WHERE c.email = '$($ReservationIdentity.email)';"
if ($ReservationCountAfterMiddleConflict -cne $ReservationCountBeforeMiddleConflict) {
    throw 'OP-05 middle_initial_conflict created an unintended reservation.'
}

$ValidationBody = [ordered]@{}
foreach ($Property in $ReservationBody.GetEnumerator()) { $ValidationBody[$Property.Key] = $Property.Value }
$ValidationBody.party_size = 0
$Validation = Send-Api -Method POST -Path '/api/v1/reservations' -Body $ValidationBody
Assert-Error $Validation 422 'validation_failed' $false $false

$Party120Path = "/api/v1/reservation-availability?local_date=$($Availability.body.local_date)&party_size=120"
$Partial = Send-Api -Method GET -Path $Party120Path
Assert-Status $Partial 200 'OP-02 partial availability'
$PartialAvailable = @($Partial.body.slots | Where-Object { $_.available }).Count
$PartialUnavailable = @($Partial.body.slots | Where-Object { -not $_.available }).Count
if ($PartialAvailable -lt 1 -or $PartialUnavailable -lt 1) { throw 'The controlled partial-availability scenario was not partial.' }

for ($BlockIndex = 0; $BlockIndex -lt 8; $BlockIndex++) {
    $Current = Send-Api -Method GET -Path $Party120Path
    $AvailableBlockers = @($Current.body.slots | Where-Object { $_.available })
    if ($AvailableBlockers.Count -eq 0) { break }
    $BlockIdentity = New-Identity "block-$BlockIndex"
    $BlockBody = New-ReservationBody $BlockIdentity $AvailableBlockers[0] 120 'no_change'
    $BlockResult = Send-Api -Method POST -Path '/api/v1/reservations' -Body $BlockBody
    Assert-Status $BlockResult 201 "controlled full-capacity blocker $BlockIndex"
}
$Full = Send-Api -Method GET -Path $Party120Path
Assert-Status $Full 200 'OP-02 fully unavailable'
if (@($Full.body.slots).Count -eq 0 -or @($Full.body.slots | Where-Object { $_.available }).Count -ne 0) {
    throw 'The controlled fully unavailable scenario did not retain every legitimate disabled slot.'
}
$UnavailableIdentity = New-Identity 'unavailable'
$FirstUnavailableSlot = @($Full.body.slots)[0]
$UnavailableBody = New-ReservationBody $UnavailableIdentity $FirstUnavailableSlot 120 'no_change'
$Unavailable = Send-Api -Method POST -Path '/api/v1/reservations' -Body $UnavailableBody
Assert-Error $Unavailable 409 'reservation_unavailable' $false $false

$OverlapAssignmentCount = Invoke-VerifierSql "SELECT count(*) FROM cafe_fausse.reservation_table_assignments a1 JOIN cafe_fausse.reservations r1 ON r1.reservation_id=a1.reservation_id JOIN cafe_fausse.reservation_table_assignments a2 ON a2.table_number=a1.table_number AND a2.reservation_id>a1.reservation_id JOIN cafe_fausse.reservations r2 ON r2.reservation_id=a2.reservation_id WHERE r1.starts_at < r2.ends_at AND r2.starts_at < r1.ends_at;"
if ($OverlapAssignmentCount -cne '0') { throw 'Controlled integration data contains overlapping shared table assignments.' }
$ForbiddenConfirmationColumn = Invoke-VerifierSql "SELECT count(*) FROM information_schema.columns WHERE table_schema='cafe_fausse' AND column_name='confirmation_email';"
if ($ForbiddenConfirmationColumn -cne '0') { throw 'A confirmation_email persistence column unexpectedly exists.' }

$PriorErrorPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $DeniedOutput = & $Psql -X -qAt -v ON_ERROR_STOP=1 -h 127.0.0.1 -p $PostgresPort `
        -U $AppLogin -d $Database -c 'SELECT count(*) FROM cafe_fausse.reservations;' 2>&1
    $DeniedExit = $LASTEXITCODE
}
finally { $ErrorActionPreference = $PriorErrorPreference }
if ($DeniedExit -eq 0) { throw 'The Flask application login unexpectedly read reservations directly.' }

for ($Sample = 0; $Sample -lt 4; $Sample++) {
    Send-Api -Method GET -Path '/api/v1/reservation-context' -TimingOperation 'OP-01' | Out-Null
    Send-Api -Method GET -Path "/api/v1/reservation-availability?local_date=$($Availability.body.local_date)&party_size=4" -TimingOperation 'OP-02' | Out-Null
    Send-Identity '/api/v1/newsletter-status-queries' $NewsletterIdentity $null 'OP-03' | Out-Null
    Send-Identity '/api/v1/newsletter-preferences' $NewsletterIdentity ([ordered]@{ subscribed = $true }) 'OP-04' | Out-Null
    $Repeat = Send-Api -Method POST -Path '/api/v1/reservations' -Body $ReservationBody -TimingOperation 'OP-05'
    Assert-Status $Repeat 200 'timed OP-05 exact retry'
}

$TimingSummary = [ordered]@{}
foreach ($Operation in $Timing.Keys) {
    $Samples = @($Timing[$Operation])
    $TimingSummary[$Operation] = [ordered]@{
        count = $Samples.Count
        minimum_ms = ($Samples | Measure-Object -Minimum).Minimum
        maximum_ms = ($Samples | Measure-Object -Maximum).Maximum
        average_ms = [math]::Round(($Samples | Measure-Object -Average).Average, 3)
    }
    if ($TimingSummary[$Operation].maximum_ms -gt 2000) {
        throw "$Operation exceeded two seconds in representative full-stack timing."
    }
}

Write-Output 'PROMPT24 LIVE API/POSTGRESQL PASS'
Write-Output "Run ID: $RunId"
Write-Output "Availability date: $($Availability.body.local_date); slots: $($Slots.Count); partial unavailable: $PartialUnavailable; full unavailable: $(@($Full.body.slots).Count)"
Write-Output 'OP-04 customer_identity_conflict and middle_initial_conflict preserved authoritative state.'
Write-Output 'OP-05 middle_initial_conflict preserved the logical reservation count.'
Write-Output "Reservation evidence customer|reservation|assignments|distinct_assignments|newsletter: $ReservationEvidence"
Write-Output "Exact retry reference stable: $($Created.body.confirmation.reservation_reference)"
Write-Output 'Exact retry preserved the explicit OP-04 newsletter false state and returned confirmation false.'
Write-Output "App-role direct reservation read denied with exit $DeniedExit."
Write-Output ('Timing: ' + ($TimingSummary | ConvertTo-Json -Depth 5 -Compress))
exit 0
