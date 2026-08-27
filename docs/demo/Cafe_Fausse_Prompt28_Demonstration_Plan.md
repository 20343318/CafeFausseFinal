# Cafe Fausse Prompt 28 Final Demonstration Plan

**Status:** PROPOSED - NOT YET APPROVED

**Prompt-28 execution baseline:** `96c7c70f8656571a7abff197b1c79b330ddb5b90`

**Target recording length:** 8 minutes 45 seconds across 11 timed segments. This leaves 1 minute 15 seconds before the rubric's 10-minute maximum and remains above its 5-minute minimum.

This is a plan only. It does not record or submit the presentation. It does not waive any SRS requirement.

## 1. Current evidence and recording gate

The committed evidence is:

- Chrome: **PASS**
- Edge: **PASS**
- Firefox: **pending manual verification**
- Safari: **pending manual verification**
- NFR-7: **not yet fully closed**
- NFR-1 performance: **PASS**; worst recorded page-load sample 782.601 ms
- NFR-2 newsletter performance: **PASS**; worst recorded submission 81.925 ms
- NFR-2 reservation performance: **PASS**; worst recorded submission 462.336 ms
- Performance protocol: one sequential browser user on the actual unthrottled demonstration/verification VM
- VM conclusion: **NO VM SCALING INDICATED**

The performance values are recorded verification results under that disclosed protocol, not universal guarantees.

**Final recording readiness gate - currently NOT READY:**

> Do not treat the project as fully SRS-ready for the final submission recording until the pending Firefox and Safari results have been received and reviewed. If either browser reveals a material SRS defect, stop final recording/submission and correct/reverify the defect first.

Prompt 28 intentionally performs no Firefox or Safari test. Planning may proceed, but the final recording may not begin while this gate remains open.

## 2. Team and privacy rules

Use only these presenter placeholders until the team replaces them in its private recording notes:

- `TEAM_MEMBER_1`
- `TEAM_MEMBER_2`
- `TEAM_MEMBER_3`

All three members must be visibly present on camera for the recording, each must state their name, each must speak at least once, and each must present a government-issued ID so the name and picture are clearly visible and legible. Show only what the rubric requires. Do not expose or read aloud ID numbers, birth dates, addresses, barcodes, or other unnecessary ID data. Only one member ultimately submits the group project.

## 3. Exact demo environment

### 3.1 Why the disposable owned environment is used

For the final demonstration, use the already approved guarded live-integration lifecycle rather than the ordinary long-lived developer database. This is existing automated-verification support reused as a human demo environment; it is not ordinary application startup and must be given the explicit authorization value only after the operator independently confirms the selected local PostgreSQL installation is nonproduction.

The helper creates and owns a disposable PostgreSQL 18.3 cluster/database, applies and verifies migrations 001-011, starts Flask and Vite, proves readiness, and later resets and removes its exact owned resources. Its fixed endpoints are:

| Layer | Exact value |
|---|---|
| Browser / Vite | `http://127.0.0.1:5173/` |
| Flask | `http://127.0.0.1:55004/` |
| Proxied readiness | `http://127.0.0.1:5173/api/v1/health/readiness` |
| Direct Flask readiness | `http://127.0.0.1:55004/api/v1/health/readiness` |
| PostgreSQL host/port | `127.0.0.1:55435` |
| Database | `cafe_fausse_test_api04` |
| Read/demo login | `cafe_fausse_prompt24_verifier` then `SET ROLE cafe_fausse_test` |

The owned cluster uses its existing local trust authentication. Do not put a password in this plan or on a command line. Do not substitute a production, shared, or ambiguously owned database.

### 3.2 Window and terminal layout before recording

Arrange the following without showing `.env` contents, tokens, passwords, private paths, or unrelated windows:

1. **Browser window:** normal Chrome or Edge at `http://127.0.0.1:5173/`, initially on Home. Keep DevTools closed until the responsive segment.
2. **Application-health PowerShell window:** repository root, with the successful owned-lifecycle `Status` output and proxied readiness result visible. This represents the running React -> Flask environment; the helper-owned Flask and Vite processes run hidden and write only to their owned temporary logs.
3. **PostgreSQL PowerShell/psql window:** connected with the exact verifier command below, role changed to `cafe_fausse_test`, variables prepared, expanded display off, and only the concise demo queries in command history.
4. **Optional documentation window:** only `README.md` and `ai-tooling.md` if the team wants to point to them during the final segment. Do not scroll through source or long test logs.

Place the browser and `psql` windows so switching is one deliberate action. Keep all three presenter cameras visible in the recording layout throughout.

## 4. Pre-recording setup and rehearsal

Run commands from the repository root in a fresh PowerShell session unless stated otherwise.

### 4.1 Git checkpoint gate

After Prompt 28 has been independently reviewed, approved, and committed by the user, replace the placeholder below with that final full commit ID. Do not record with an unstaged plan or an unknown checkpoint.

```powershell
$DemoExpectedHead = '<FINAL_COMMITTED_PROJECT_CHECKPOINT>'
$DemoHead = (git rev-parse HEAD).Trim()
$DemoOrigin = (git rev-parse origin/main).Trim()
if ($DemoHead -cne $DemoExpectedHead) { throw "HEAD $DemoHead is not the approved demo checkpoint $DemoExpectedHead." }
if ($DemoOrigin -cne $DemoHead) { throw "origin/main $DemoOrigin does not equal HEAD $DemoHead." }
$DemoStatus = @(git status --short)
if ($DemoStatus.Count -ne 0) { throw "The working tree or index is not clean: $($DemoStatus -join ', ')" }
$DemoHead
```

Record the printed full commit ID in the readiness checklist.

### 4.2 Start and prove the disposable stack

Independently confirm that the local PostgreSQL 18.3 installation is nonproduction before assigning the authorization value. The literal value is an operator assertion, not proof by itself.

```powershell
$CafeDemoAuthorization = 'AUTHORIZED_NONPRODUCTION'
& .\frontend\scripts\owned-live-integration.ps1 `
  -Action Start `
  -NonProductionClusterAuthorization $CafeDemoAuthorization
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& .\frontend\scripts\owned-live-integration.ps1 `
  -Action Status `
  -NonProductionClusterAuthorization $CafeDemoAuthorization
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Invoke-RestMethod 'http://127.0.0.1:5173/api/v1/health/readiness'
```

Expected lifecycle output includes `Prompt-24 environment ready: PostgreSQL 55435 -> Flask 55004 -> Vite 5173.` The status call must report that every owned process, listener, marker, and readiness response is current, and the readiness body must report `status` as `ready`. If not, stop and use the guarded recovery rules in Section 10; do not start recording.

### 4.3 Prepare unique fictional identities

Choose a fresh token for every recording attempt. The example produces no personal address and uses the reserved `.test` domain.

```powershell
$DemoAttemptToken = Get-Date -Format 'yyyyMMdd-HHmmss'
$NewsletterEmail = "prompt28-newsletter-$DemoAttemptToken@example.test"
$ReservationEmail = "prompt28-reservation-$DemoAttemptToken@example.test"
$FullSlotEmail = "prompt28-full-$DemoAttemptToken@example.test"
$NewsletterEmail
$ReservationEmail
$FullSlotEmail
```

Use these fictional form values:

| Purpose | First name | Last name | Email | Other values |
|---|---|---|---|---|
| Newsletter | `Demo` | `Newsletter` | value of `$NewsletterEmail` | Check Subscribe; confirmation email matches |
| Successful reservation | `Demo` | `Reservation` | value of `$ReservationEmail` | Party 6; optional phone `202-555-0199`; confirmation email matches; leave newsletter unchanged |
| Full-slot precondition | `Demo` | `Fullslot` | value of `$FullSlotEmail` | Party 120; confirmation email matches; leave newsletter unchanged |

Never use a team member's real name, email, or phone for demo data.

### 4.4 Open the direct PostgreSQL session

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' `
  -X -v ON_ERROR_STOP=1 `
  -h 127.0.0.1 -p 55435 `
  -U cafe_fausse_prompt24_verifier `
  -d cafe_fausse_test_api04
```

At the `psql` prompt:

```sql
SET ROLE cafe_fausse_test;
\pset pager off
\set newsletter_email 'prompt28-newsletter-YYYYMMDD-HHMMSS@example.test'
\set reservation_email 'prompt28-reservation-YYYYMMDD-HHMMSS@example.test'
\set full_slot_email 'prompt28-full-YYYYMMDD-HHMMSS@example.test'
```

Replace each `YYYYMMDD-HHMMSS` with the same value printed by PowerShell. `SET ROLE` is required because the login itself is only a non-inheriting verifier login. Keep this session open for the demo.

### 4.5 Establish clean before-state evidence

Run and retain these concise results; each must be zero before its browser operation:

```sql
SELECT count(*) AS newsletter_customer_before
FROM cafe_fausse.customers
WHERE email = :'newsletter_email';

SELECT count(*) AS reservation_before
FROM cafe_fausse.reservations AS r
JOIN cafe_fausse.customers AS c
  ON c.customer_id = r.customer_id
WHERE c.email = :'reservation_email';
```

If either count is nonzero, do not delete rows manually. Stop the owned environment with Section 11, start a new one, and choose a fresh token.

### 4.6 Prepare one deterministic unavailable/full interval

Use the real browser and server-authoritative workflow; do not write reservation rows directly.

1. Open Reservations and wait for `Reservation options are ready.`
2. Choose an allowed date shown by the server-provided range, preferably at least eight days after the minimum date and different from the date planned for the successful reservation.
3. Enter party size `120`, select **Check availability**, and note the first server-returned **Available** interval as `FULL_DEMO_DATE` and `FULL_DEMO_TIME`.
4. Select that interval, enter the Full-slot identity above, submit, and require `Reservation confirmed`.
5. Select **Make another reservation**, re-enter the same date and party size `120`, and select **Check availability**.
6. Confirm that the exact `FULL_DEMO_TIME` interval is labelled **Unavailable** and its radio control is disabled. Other nonoverlapping intervals may remain available; the requirement is one deterministic full/unavailable target interval.
7. In `psql`, prove the precondition uses all current capacity:

```sql
SELECT
    r.reservation_id,
    r.party_size,
    count(rta.table_number) AS assigned_table_count,
    sum(rt.seating_capacity) AS assigned_capacity
FROM cafe_fausse.reservations AS r
JOIN cafe_fausse.customers AS c
  ON c.customer_id = r.customer_id
JOIN cafe_fausse.reservation_table_assignments AS rta
  ON rta.reservation_id = r.reservation_id
JOIN cafe_fausse.restaurant_tables AS rt
  ON rt.table_number = rta.table_number
WHERE c.email = :'full_slot_email'
GROUP BY r.reservation_id, r.party_size;
```

Expected precondition: one party-120 reservation, 30 assigned tables, and assigned capacity 120. This is the same safe production booking path proven by Prompt 25, performed only in the explicitly disposable owned database. It neither corrupts data nor bypasses Flask authority.

Before recording, return the browser to Home. Rehearse all window switches, ensure the reservation success date is different from `FULL_DEMO_DATE`, and confirm no stale browser autofill will substitute personal data.

### 4.7 Camera, audio, screen, and duration preflight

- Keep all three cameras visible in the captured layout.
- Verify all three microphones and each speaking assignment.
- Have IDs ready, but keep them off screen until the opening.
- Hide notifications, passwords, tokens, `.env` files, unrelated terminals, and personal browser data.
- Rehearse to 8:45; allow the 1:15 buffer for navigation and normal speaking pauses.
- Verify the recording tool captures the shared screen, all three cameras, and all three microphones.
- Do not begin until Firefox and Safari results are received/reviewed and NFR-7 is closed, or any discovered material defect has been corrected and reverified.

## 5. Direct PostgreSQL evidence queries

These are read-only and use deterministic email/reference keys. Do not use `latest row` queries.

### 5.1 Newsletter after-state

Immediately after the Home form reports `Newsletter preference saved`, run:

```sql
SELECT
    customer_id,
    first_name,
    middle_initial,
    last_name,
    email,
    newsletter_subscribed
FROM cafe_fausse.customers
WHERE email = :'newsletter_email';
```

Expected: exactly one `Demo Newsletter` customer with the exact browser email and `newsletter_subscribed = true`. For this chosen new identity, the operation inserts a customer. The implementation can also update the Boolean on an existing matching customer, but that alternate path is not used in this deterministic demo and must not be described as an insert.

### 5.2 Reservation before-state and reference capture

The before query in Section 4.5 must show zero reservations for `:'reservation_email'`. After browser confirmation, copy its decimal **Reference** value into `psql`:

```sql
\set reservation_reference 123
```

Replace `123` with the exact on-screen reference. The reference plus the unique email provides two-key correlation.

### 5.3 Reservation, customer, local interval, and party size

```sql
SELECT
    r.reservation_id,
    c.customer_id,
    concat_ws(' ', c.first_name, c.middle_initial, c.last_name) AS customer_name,
    c.email,
    c.phone,
    c.newsletter_subscribed,
    r.starts_at AT TIME ZONE cfg.restaurant_timezone AS restaurant_local_start,
    r.ends_at AT TIME ZONE cfg.restaurant_timezone AS restaurant_local_end,
    r.party_size
FROM cafe_fausse.reservations AS r
JOIN cafe_fausse.customers AS c
  ON c.customer_id = r.customer_id
CROSS JOIN cafe_fausse.reservation_configuration AS cfg
WHERE r.reservation_id = :'reservation_reference'::bigint
  AND c.email = :'reservation_email';
```

Expected: exactly one row whose reference, customer name/email, local interval, party size 6, and newsletter state match the browser confirmation and submitted facts. `confirmation_email` is validation-only and is not a database column.

### 5.4 Authoritative normalized table-assignment rows

Reuse the approved FR-17 evidence pattern from `docs/demo/Cafe_Fausse_FR17_Demo_Queries.md`:

```sql
SELECT
    rta.reservation_id,
    rta.table_number
FROM cafe_fausse.reservation_table_assignments AS rta
WHERE rta.reservation_id = :'reservation_reference'::bigint
ORDER BY rta.table_number;
```

For party 6 under the baseline capacity-four inventory, the confirmation and query should show the same two assigned table numbers. Do not invent a primary table; each returned relation row is authoritative.

### 5.5 Compact joined/aggregated grader view

```sql
SELECT
    r.reservation_id,
    c.email,
    r.starts_at AT TIME ZONE cfg.restaurant_timezone AS restaurant_local_start,
    r.ends_at AT TIME ZONE cfg.restaurant_timezone AS restaurant_local_end,
    r.party_size,
    string_agg(rta.table_number::text, ', ' ORDER BY rta.table_number) AS assigned_table_numbers
FROM cafe_fausse.reservations AS r
JOIN cafe_fausse.customers AS c
  ON c.customer_id = r.customer_id
JOIN cafe_fausse.reservation_table_assignments AS rta
  ON rta.reservation_id = r.reservation_id
CROSS JOIN cafe_fausse.reservation_configuration AS cfg
WHERE r.reservation_id = :'reservation_reference'::bigint
  AND c.email = :'reservation_email'
GROUP BY
    r.reservation_id,
    c.email,
    r.starts_at,
    r.ends_at,
    r.party_size,
    cfg.restaurant_timezone;
```

Explain that `assigned_table_numbers` is a read-only presentation aggregate. Persistent assignment remains normalized in `reservation_table_assignments`.

### 5.6 Configurability view - show, do not mutate

The recording should show this one compact row and discuss it. Do not change any setting during the final recording.

```sql
SELECT
    start_interval_minutes,
    reservation_duration_minutes,
    advance_booking_window_days,
    same_day_lead_minutes,
    restaurant_timezone,
    (SELECT count(*) FROM cafe_fausse.restaurant_tables) AS table_count,
    (SELECT min(seating_capacity) FROM cafe_fausse.restaurant_tables) AS minimum_table_capacity,
    (SELECT max(seating_capacity) FROM cafe_fausse.restaurant_tables) AS maximum_table_capacity,
    (SELECT sum(seating_capacity) FROM cafe_fausse.restaurant_tables) AS total_capacity
FROM cafe_fausse.reservation_configuration
WHERE configuration_id = 1;
```

The disposable baseline must show 30, 90, 60, 120, `America/New_York`, 30 tables, per-table minimum/maximum capacity 4, and total capacity 120. Prompt 25 already proved that an approved `start_interval_minutes` change changes Flask/React behavior without a source-code edit and restores the setting afterward; the recording does not repeat that mutation.

## 6. Timed presenter talk track

Do not read this as a word-for-word essay. Keep each spoken portion to the listed 1-3 concise sentences.

| # | Time | Elapsed | Presenter | Screen action | Presenter says | Expected visible result | Fallback |
|---:|---:|---:|---|---|---|---|---|
| 1 | 0:45 | 0:45 | `TEAM_MEMBER_1`, `TEAM_MEMBER_2`, `TEAM_MEMBER_3` | All three cameras visible. In turn, each states name and holds government ID close enough for name/picture legibility; then `TEAM_MEMBER_1` shows Home. | Each: “My name is [name].” `TEAM_MEMBER_1`: “This is Cafe Fausse, built as React/JSX -> Flask/Python -> PostgreSQL.” | Three visible members, three names, three required ID views, and the Home page. | If any camera/audio/ID is not legible, stop and restart; do not continue with an incomplete identity record. |
| 2 | 0:35 | 1:20 | `TEAM_MEMBER_1` | Scroll Home just enough to show name, image/theme, address, phone, live hours, shared navigation, and newsletter section. | “Home provides the required restaurant identity, contact information, server-backed hours, and consistent navigation. The same React shell links all five routes.” | Cafe Fausse, `1234 Culinary Ave, Suite 100, Washington, DC 20002`, `(202) 555-4567`, hours, images, and nav are visible. | If hours are unavailable or incorrect, stop; check stack health and restart safely. |
| 3 | 1:10 | 2:30 | `TEAM_MEMBER_1` | Switch to `psql`, show `newsletter_customer_before = 0`; return to Home, enter the unique newsletter identity, check Subscribe, save; return to `psql` and run Section 5.1. | “The form validates a real identity and email, then Flask persists the preference in PostgreSQL. The unique key was absent before; this row is the exact email and authoritative subscribed state shown after the browser success.” | `Newsletter preference saved`, `Authoritative preference: subscribed`, then one matching customer row with `newsletter_subscribed = true`. | If success or the exact row is missing/ambiguous, stop. Do not claim persistence or switch to another row. |
| 4 | 0:45 | 3:15 | `TEAM_MEMBER_2` | Use shared navigation to Menu, briefly show representative Starters/Main Courses/Desserts/Beverages content; navigate to About Us and show history, founders, mission, and commitments. | “The Menu contains the required categorized descriptions and prices without making the audience read every item. About Us preserves the 2010 founders, mission, unforgettable dining, excellent food, and locally sourced ingredients.” | Correct Menu and About routes/content; navigation remains functional. | If a route or required content does not render, stop and diagnose before rerecording. |
| 5 | 0:40 | 3:55 | `TEAM_MEMBER_2` | Navigate to Gallery, show responsive grid plus image categories, awards, and reviews; open a non-edge image, select Next or Previous, then Close. | “Gallery covers the restaurant interior, dishes, special occasions, and behind-the-scenes work, with the required awards and reviews. The lightbox enlarges images and supports bounded navigation and clean close.” | Grid, enlarged dialog, changed image/counter, and return to Gallery. | If the image/lightbox/navigation fails, stop; do not talk around it. |
| 6 | 0:30 | 4:25 | `TEAM_MEMBER_2` | Open Chrome/Edge DevTools device toolbar, set a 390 x 844 viewport, show shared navigation reflow and the Gallery grid or Home layout; restore desktop and close DevTools. | “The CSS Grid/Flexbox layout adapts to a narrow mobile viewport without horizontal page scrolling. This is responsive evidence only; it is not Firefox or Safari verification.” | Narrow navigation/layout and obvious grid reflow, then restored desktop. | If overflow or broken layout appears, stop. Do not treat an emulator as four-browser evidence. |
| 7 | 0:40 | 5:05 | `TEAM_MEMBER_3` | Navigate to Reservations. Enter recorded `FULL_DEMO_DATE`, party 120, Check availability, and point to recorded `FULL_DEMO_TIME`. | “This party uses the full 120-seat baseline capacity for the occupied interval. Flask returns server-authoritative availability, and React renders this target interval disabled and labelled Unavailable rather than accepting an arbitrary time.” | The preconditioned target slot is visibly **Unavailable** and non-clickable; other nonoverlapping slots may be available. | If the exact slot is not disabled, stop. Rebuild/reprepare through the guarded workflow; never patch rows manually. |
| 8 | 1:25 | 6:30 | `TEAM_MEMBER_3` | Briefly show the retained `reservation_before = 0`; return to Reservations, choose a different allowed date, party 6, Check availability, select a returned Available slot, enter the unique reservation identity and fictional phone, leave newsletter unchanged, review, and select Reserve table. Pause on confirmation and copy Reference. | “The unique reservation identity has no prior booking. The date bounds, policy, and selectable times come from Flask/PostgreSQL; PostgreSQL revalidates availability, prevents overlapping table occupancy, and allocates the best-capacity table combination atomically.” | Zero before-state, then `Reservation confirmed`, exact local/canonical interval, party 6, assigned tables, newsletter state, and decimal Reference. | If submission fails, confirmation is missing, or the reference cannot be captured, stop and restart with a fresh identity after guarded reset. |
| 9 | 0:55 | 7:25 | `TEAM_MEMBER_3` | In `psql`, set `reservation_reference`; run Sections 5.3, 5.4, and 5.5. | “The browser reference and unique email select exactly this persisted customer and reservation. Reservation facts live in `reservations`; the complete one-to-many table assignment is normalized in `reservation_table_assignments`, and this aggregate reconstructs the same table numbers shown in React.” | One matching reservation/customer row, sorted authoritative assignment rows, and an aggregate matching the browser reference/time/party/table numbers. | If any value differs or the query returns zero/multiple rows, stop; do not use a latest-row substitute. |
| 10 | 0:45 | 8:10 | `TEAM_MEMBER_3` | Run Section 5.6 and, if useful, keep browser/health terminal visible beside it. | “PostgreSQL owns persistent data and business configuration; Flask is the server-authoritative validator/orchestrator; React presents returned state. Start interval, duration, advance window, same-day lead, timezone, operating hours, and per-table capacity are database-backed; assignments are normalized and each table is exclusively occupied over the reservation interval.” | One configuration/capacity row plus healthy application evidence. | If values differ from the expected clean seed, stop and guarded-reset before rerecording; never edit configuration during the recording. |
| 11 | 0:35 | 8:45 | `TEAM_MEMBER_1` | Briefly point to `README.md`/`ai-tooling.md` or keep the app on screen while stating evidence. | “Verification was layered PostgreSQL -> Flask/API -> React -> full-stack -> performance; the frozen evidence includes the documented API-09 baseline anomaly, so we do not collapse it to ‘all tests pass.’ ChatGPT supported requirements, planning, review, and selected image generation; Codex supported repository work, testing, guarded tooling, and documentation, with independent review and user-only Git authority. Recorded NFR-1/NFR-2 evidence passed; Chrome and Edge passed, while this recording proceeded only after the separate Firefox/Safari gate was closed.” | Required testing/AI disclosure is stated naturally, with no large log scroll and no unsupported claim. | If elapsed time is already over 9:20, use only the first two sentences and end under 10:00; if under 5:00 or over 10:00, rerecord. |

Calculated total: **8:45**. Planned buffer before 10:00: **1:15**.

## 7. Key implementation-decision notes

Use these facts only; do not turn the recording into an architecture lecture.

- PostgreSQL owns persistent customer/newsletter/reservation/assignment data, operating hours, booking configuration, per-table capacity, integrity, overlap prevention, and allocation.
- Flask validates and normalizes requests, applies bounded retries/deadlines, orchestrates the frozen database operations, and returns safe REST responses. It remains authoritative even if a client manipulates a request.
- React owns presentation and interaction. It requests context and provisional availability and renders only returned legitimate start times; no arbitrary time field is accepted.
- `reservations` stores immutable reservation-level facts. `reservation_table_assignments` stores the normalized one-to-many physical table relationship.
- Table occupancy uses an exclusive half-open interval: an existing table conflicts when its interval overlaps the proposed interval; back-to-back endpoint contact is allowed.
- The clean seed uses `start_interval_minutes = 30`, `reservation_duration_minutes = 90`, `advance_booking_window_days = 60`, `same_day_lead_minutes = 120`, `restaurant_timezone = 'America/New_York'`, and 30 tables each with `seating_capacity = 4`.
- Operating hours and table capacities are configurable PostgreSQL data too. The latest valid start is derived from closing time and duration; it is not a separate setting.
- Availability is provisional. Booking rechecks under the database-controlled transaction, then selects the minimum table count, least wasted capacity, and a random winner among equally optimal combinations.

## 8. Testing, performance, and AI disclosure notes

The concise testing statement must reference the existing runbooks and evidence, not rerun suites or scroll logs during the presentation:

- `database/TestInstructions.md`
- `backend/TestInstructions.md`
- `frontend/TestInstructions.md`
- `docs/integration-verification/Cafe_Fausse_Prompt25_Full_Integration_Verification.md`
- `docs/performance-verification/Cafe_Fausse_NFR01_NFR02_Performance_Verification.md`

State the accepted evidence accurately: the standalone complete PostgreSQL programmer gate passed; one frozen API-09 PostgreSQL selection retained its documented accepted `StopIteration` baseline anomaly. Do not say a generic “all tests pass.”

For AI assistance, point to `ai-tooling.md` and state only:

- ChatGPT assisted with SRS/rubric analysis, least-to-most planning, prompt generation, independent review, and the approved behind-the-scenes Gallery image.
- OpenAI Codex assisted with repository inspection, implementation, testing, guarded verification tooling, and documentation.
- AI-generated work was independently reviewed and tested before approval.
- Git staging, commit, and push authority remained with the user.

Do not name unsupported AI tools or estimate an AI-generated-code percentage.

## 9. Rubric-to-demo evidence matrix

| Demo segment | What is shown | Rubric/SRS obligation proved | PostgreSQL/Flask/React evidence | Presenter |
|---|---|---|---|---|
| 1 | Three cameras, names, IDs, stack introduction | Group visibility, identity, every member speaks | Human recording obligation plus React/Flask/PostgreSQL stack | All three placeholders |
| 2 | Home, restaurant facts, shared navigation | FR-1 to FR-4; intuitive/consistent UI | React Home/shell; OP-01-backed hours | `TEAM_MEMBER_1` |
| 3 | Newsletter before query, form success, after row | FR-15/FR-16; working form; direct DB effect | React OP-04 -> Flask -> `customers.email/newsletter_subscribed` | `TEAM_MEMBER_1` |
| 4 | Menu and About Us via navigation | FR-5, FR-10, FR-11; required pages/navigation | React routes and exact static content | `TEAM_MEMBER_2` |
| 5 | Gallery grid/content, awards/reviews, lightbox interaction | FR-12 to FR-14; high-quality UI | React Gallery/lightbox and assets | `TEAM_MEMBER_2` |
| 6 | Desktop-to-390 x 844 reflow | NFR-8; CSS Grid/Flexbox responsive UX | React responsive CSS in Chrome/Edge DevTools | `TEAM_MEMBER_2` |
| 7 | Party-120 target slot disabled/unavailable | FR-7, FR-9, NFR-5/NFR-6; full behavior | PostgreSQL capacity -> Flask OP-02 -> disabled React slot | `TEAM_MEMBER_3` |
| 8 | Complete real booking and confirmation | FR-6 to FR-9, FR-18; sophisticated reservation logic | Server slots, Flask validation/orchestration, PostgreSQL booking/allocation, React confirmation | `TEAM_MEMBER_3` |
| 9 | Customer/reservation row, normalized assignment rows, aggregate | FR-17/FR-18; direct reservation DB effect, not admin UI | `customers`, `reservations`, `reservation_table_assignments` correlated by email/reference | `TEAM_MEMBER_3` |
| 10 | Configuration/capacity query and architecture explanation | Implementation decisions; configurable rules; NFR-5/NFR-9 | PostgreSQL configuration, Flask authority, React presentation | `TEAM_MEMBER_3` |
| 11 | Layered tests, performance, AI disclosure | NFR-1/NFR-2 evidence; AI tooling document; maintainability | Frozen reports/runbooks and `ai-tooling.md` | `TEAM_MEMBER_1` |

All five required pages are covered: Home (2/3), Menu and About Us (4), Gallery (5), and Reservations (7/8). Navigation is exercised across them. This matrix does not claim that any segment proves Firefox or Safari compatibility.

## 10. Failure and abort rules

Stop and restart the recording rather than narrating around any of these conditions:

- PostgreSQL, Flask, Vite, direct readiness, or proxied readiness is not healthy before recording.
- The working tree/index is not clean or `HEAD`, `origin/main`, and the approved final checkpoint do not match.
- Firefox/Safari results have not been received/reviewed, NFR-7 is not closed, or a browser result reveals a material SRS defect.
- Stale demo data makes a before count nonzero or correlation ambiguous.
- The target full interval is selectable, not labelled Unavailable, or otherwise nondeterministic.
- Newsletter save fails or its exact PostgreSQL row/state cannot be shown.
- Reservation creation fails, confirmation/reference is absent, or direct queries do not match the browser result.
- Any password, token, `.env` content, personal data, or unnecessary ID detail becomes visible.
- Any required presenter's camera/audio is missing or illegible.
- A required page, navigation action, Gallery/lightbox action, or responsive view fails visibly.
- The final recording is shorter than 5:00 or longer than 10:00.

Recovery uses only existing safe mechanisms:

1. End the recording attempt.
2. Close the normal browser window/tab opened for the demo and exit `psql` with `\q`.
3. Run the guarded whole-environment stop in Section 11. It verifies ownership, resets the disposable database to zero business rows, stops owned Vite/Flask/PostgreSQL processes, and removes its owned temporary root.
4. If the helper refuses because evidence is missing, malformed, mismatched, or ambiguous, preserve the evidence and investigate. Do not kill a PID, delete a root, or drop a database by inference.
5. Start again from Section 4 with a new attempt token, recreate the full-slot precondition through React, and rehearse before rerecording.

## 11. Repeatability, shutdown, and cleanup

Direct per-row cleanup is intentionally not the demo procedure. Reservations have no Version 1 cancellation/deletion API, and unguarded SQL deletion would bypass the approved safeguards. A fresh unique `.test` identity prevents collision during an attempt; the approved whole disposable-environment reset removes demo-created state between attempts.

After every rehearsal or recording attempt, successful or failed:

1. In `psql`, use `\q`.
2. Close only the browser tab/window opened for this demo. Do not terminate unrelated browser processes.
3. From the repository root, run:

```powershell
& .\frontend\scripts\owned-live-integration.ps1 `
  -Action Stop `
  -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Expected final message: `Prompt-24 cleanup pass: Vite, Flask, PostgreSQL, test rows, logs, cache, and ownership root are absent.`

4. Verify the known owned ports and root are absent without altering anything:

```powershell
$DemoOwnedPorts = @(55435, 55004, 5173)
foreach ($DemoOwnedPort in $DemoOwnedPorts) {
    if (@(Get-NetTCPConnection -State Listen -LocalPort $DemoOwnedPort -ErrorAction SilentlyContinue).Count -ne 0) {
        throw "Demo-owned port still listens: $DemoOwnedPort"
    }
}
$DemoOwnedRoot = Join-Path ([IO.Path]::GetTempPath()) 'CafeFausse-prompt24-integration'
if (Test-Path -LiteralPath $DemoOwnedRoot) { throw "Demo-owned root survived: $DemoOwnedRoot" }
git status --short
```

The final `git status --short` must be empty at the committed recording checkpoint. If cleanup refuses or residue remains, preserve the ownership evidence and stop; do not remove or terminate anything by guesswork.

## 12. Recording readiness checklist

- [ ] Prompt 28 plan approved
- [ ] final committed project checkpoint recorded
- [ ] working tree clean
- [ ] Chrome result available
- [ ] Edge result available
- [ ] Firefox result received/reviewed
- [ ] Safari result received/reviewed
- [ ] NFR-7 closed or any failure corrected/reverified
- [ ] all three group members available
- [ ] all three cameras/microphones verified
- [ ] IDs ready for required on-camera verification
- [ ] each member assigned at least one speaking segment
- [ ] demo-safe unique customer/newsletter identity prepared
- [ ] deterministic unavailable/full scenario prepared
- [ ] direct PostgreSQL queries rehearsed
- [ ] browser/Flask/PostgreSQL windows arranged
- [ ] secrets/private data hidden
- [ ] cleanup/reset procedure ready
- [ ] expected duration rehearsed within 5-10 minutes

Do not check pending items automatically. As of Prompt 28, Firefox, Safari, NFR-7 closure, Prompt-28 approval, the future committed checkpoint, recording, and submission remain pending.

## 13. Post-demo submission handoff - outside Prompt 28

Only after a valid final recording exists, the team must separately handle the rubric's external submission work:

- upload the recording and provide its Google Drive link without using “Invite People” for graders;
- create the required PDF containing the appropriate GitHub repository link(s), including each group member's repository link when applicable;
- add `quantic-grader` as a collaborator to each required private repository;
- ensure required source, `README.md`, and `ai-tooling.md` are present in each submitted repository;
- include optional `staging.md` only if a real staging deployment exists, otherwise truthfully indicate local-only operation where required;
- include the completed/signed final page of the Group Project Agreement when prompted; and
- have exactly one group member submit for the group.

This plan does not upload video, create a Drive link or PDF, invent repository URLs, change repository privacy, invite collaborators, inspect teammates' repositories, or claim submission completion.

## 14. Review checkpoint

Prompt 28 remains **PROPOSED - NOT YET APPROVED** until independent ChatGPT review and explicit user approval. The final recording and all external submission actions remain outside this increment.
