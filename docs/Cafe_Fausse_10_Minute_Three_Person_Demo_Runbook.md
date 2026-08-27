# Cafe Fausse 10-Minute Three-Person Demo Runbook

**Participants:** P1, P2, and P3  
**Target duration:** 10:00 maximum  
**Equal clock allocation:** 3:20 per person  
**Purpose:** Choreograph the future three-person Cafe Fausse demonstration. Preparing this runbook does not start or perform a recording.

## 1. Presentation rules that cannot be skipped

- Keep P1, P2, and P3 visible on camera throughout the demonstration.
- Each person must state their actual name and briefly present a government-issued ID so the name and picture are clearly visible and legible.
- Show the shared application screen as well as the presenters.
- Demonstrate all five pages and navigation between them.
- Demonstrate newsletter signup and a successful reservation.
- Demonstrate an unavailable/full reservation time.
- Show the actual PostgreSQL effects of newsletter signup and reservation creation. An application administration page is not a substitute.
- Discuss important implementation decisions.
- Finish at or before 10:00. Rehearse to the cue times; do not improvise additional technical detail.

## 2. Speaking and timing allocation

| Person | Clock window | Duration | Primary responsibility |
|---|---:|---:|---|
| P1 | 0:00-3:20 | 3:20 | Introduction, Home, newsletter plus PostgreSQL, Menu, About Us, architecture |
| P2 | 3:20-6:40 | 3:20 | Gallery/lightbox, responsive design, reservation availability and full/unavailable behavior |
| P3 | 6:40-10:00 | 3:20 | Successful reservation, PostgreSQL persistence, configuration, verification and close |

The 3:20 allocations include each person's screen actions, pauses, identity check, and handoff. They are not 3:20 of uninterrupted narration.

## 3. Pre-demo preparation

Complete these steps before the timed demonstration begins.

### People and recording layout

- Confirm P1, P2, and P3 are present, visible, audible, and assigned to the segments below.
- Confirm each person has the required ID ready. Display it only as long as needed for the required name-and-picture verification.
- Place the three camera tiles where they do not obscure the application, terminal, confirmation reference, or database results.
- Silence notifications and hide passwords, tokens, `.env` files, personal data, unrelated browser tabs, and unrelated terminals.

### Application and evidence windows

- Start the clean, repeatable nonproduction Cafe Fausse environment using the approved repository instructions.
- Confirm PostgreSQL, Flask, React/Vite, direct readiness, and proxied readiness are healthy.
- Open the application on Home.
- Open a prepared `psql` session in a second window.
- Keep the approved PostgreSQL evidence queries from Section 5 of `docs/demo/Cafe_Fausse_Prompt28_Demonstration_Plan.md` ready to run. Do not improvise replacement SQL during the demo.
- Prepare Chrome or Edge DevTools for the 390 x 844 responsive viewport, but leave DevTools closed until P2's segment.
- Make browser zoom, terminal font size, and camera layout readable in the shared screen.

### Demo-safe data

Record these values on a private operator cue sheet; do not put real personal information in the demo:

- `NEWSLETTER_DEMO_EMAIL`: unique fictional email with no existing customer row.
- `RESERVATION_DEMO_EMAIL`: a different unique fictional email with no existing reservation.
- `FULL_DEMO_DATE` and `FULL_DEMO_TIME`: the rehearsed deterministic interval that is already at full capacity.
- `SUCCESS_DEMO_DATE`: a different allowed date with sufficient capacity for the successful party-of-6 reservation.
- `reservation_reference`: leave blank until the confirmation page displays it.

Before the timed demo, use the approved guarded preparation workflow to establish the full/unavailable scenario. Verify the newsletter and reservation before-state queries return zero for the two unique fictional identities. Never repair the demo by manually editing individual database rows.

## 4. Master choreography

| Time | Person | Screen/action | Evidence or result |
|---|---|---|---|
| 0:00-0:25 | P1 | State actual name; present ID; introduce the project. | P1 identity; React-Flask-PostgreSQL scope |
| 0:25-1:05 | P1 | Show Home and shared navigation. | Restaurant identity, contact/hours, theme, navigation |
| 1:05-2:10 | P1 | Show newsletter database before-state, submit form on Home, then show PostgreSQL after-state. | Zero before; saved/subscribed UI; exact customer row with subscription true |
| 2:10-2:50 | P1 | Navigate to Menu and About Us. | Required menu categories, descriptions/prices, history, founders, mission |
| 2:50-3:20 | P1 | Summarize architecture and hand off. | React -> Flask -> PostgreSQL and server-authoritative persistence |
| 3:20-3:45 | P2 | State actual name; present ID; accept handoff on About Us. | P2 identity |
| 3:45-4:35 | P2 | Navigate to Gallery; show categories, awards/reviews; open, advance, and close lightbox. | Gallery content and interaction |
| 4:35-5:15 | P2 | Use DevTools at 390 x 844; show navigation/layout reflow; restore desktop. | Responsive Grid/Flexbox behavior without horizontal overflow |
| 5:15-6:15 | P2 | Navigate to Reservations; enter `FULL_DEMO_DATE`, party 120; check availability; point to `FULL_DEMO_TIME`. | Server-returned slot shown unavailable and non-clickable |
| 6:15-6:40 | P2 | Explain server-authoritative availability and hand off. | No arbitrary-time entry; full-capacity behavior |
| 6:40-7:05 | P3 | State actual name; present ID; accept handoff on Reservations. | P3 identity |
| 7:05-8:25 | P3 | Use `SUCCESS_DEMO_DATE`, party 6; retrieve/select an available slot; enter fictional customer details; submit; pause on confirmation and capture reference. | Successful reservation, assigned table numbers, canonical time, reference |
| 8:25-9:15 | P3 | Run approved reservation/customer and assignment queries using the captured reference. | Exact persisted reservation and normalized table assignments match browser |
| 9:15-9:40 | P3 | Run/show approved configuration/capacity query and explain implementation decisions. | Database-backed rules; PostgreSQL/Flask/React responsibilities |
| 9:40-10:00 | P3 | State verification, browser, and AI-tooling summary; close. | Testing disclosure, NFR results, four-browser status, clear ending |

## 5. Detailed narrative and operator cues

Text in brackets is an action cue and is not spoken. The narrative is a rehearsal script: speak naturally, but preserve every factual claim and do not add unsupported claims.

### P1 - 0:00 to 3:20

#### 0:00-0:25 - Identity and scope

**Action:** [P1's camera is visible. P1 states their actual name and holds the required ID steadily so the name and picture are legible, then removes it. The shared screen shows Cafe Fausse Home.]

**Narrative:**

> My name is [P1 states actual name], and I am P1 for this demonstration. This is Cafe Fausse, a responsive full-stack restaurant application built with React and JSX, a Flask REST API, and PostgreSQL. We will demonstrate all five pages, newsletter persistence, reservation availability and creation, and the resulting database state.

#### 0:25-1:05 - Home and navigation

**Action:** [Point briefly to the Cafe Fausse name, address, phone number, hours, hero content, and shared navigation. Select Home once if necessary to make the active route clear.]

**Narrative:**

> Home establishes the restaurant's identity, contact details, operating hours, imagery, and consistent visual theme. The shared navigation provides direct access to Menu, Reservations, About Us, and Gallery. The same React navigation and styling are reused across the site so visitors can move between pages predictably.

#### 1:05-2:10 - Newsletter signup and direct PostgreSQL evidence

**Action:** [Switch to `psql`. Run the approved newsletter before-state query using `NEWSLETTER_DEMO_EMAIL`; show that the count is zero. Return to Home. Enter the prepared fictional name and email, confirm the email if the form requests it, select Subscribe, and save. Pause on the success state. Return to `psql` and run the approved newsletter after-state query.]

**Narrative:**

> Before submission, this unique fictional email has no customer row. On Home, the newsletter form validates the identity and email before sending the request to Flask. The success message now confirms that the preference was saved, and the returned authoritative state is subscribed. In PostgreSQL, the exact email now identifies one customer row with the newsletter subscription set to true. This is the database effect itself, not an administration-page representation.

**Required visible result:** The browser shows the saved/subscribed state, and PostgreSQL shows exactly one matching customer with `newsletter_subscribed = true`.

#### 2:10-2:50 - Menu and About Us

**Action:** [Navigate to Menu and scroll only enough to show representative Starters, Main Courses, Desserts, and Beverages with descriptions and prices. Navigate to About Us and point to history, founders, mission, and commitments.]

**Narrative:**

> The Menu organizes the required offerings into clear categories and includes descriptions and prices. About Us presents Cafe Fausse's history, its 2010 founding, the founders, the mission of an unforgettable dining experience, and commitments to excellent food and locally sourced ingredients. These routes preserve the same navigation and brand treatment.

#### 2:50-3:20 - Architecture and handoff

**Action:** [Keep About Us visible.]

**Narrative:**

> The user interface is React, Flask validates and orchestrates form requests, and PostgreSQL owns persistent customer, reservation, table, and business-configuration data. That separation keeps the browser simple while the server and database enforce authoritative rules. P2 will now demonstrate Gallery interaction, responsive behavior, and server-provided reservation availability.

### P2 - 3:20 to 6:40

#### 3:20-3:45 - Identity

**Action:** [P2's camera remains visible. P2 states their actual name and presents the required ID so the name and picture are legible, then removes it.]

**Narrative:**

> My name is [P2 states actual name], and I am P2. I will demonstrate the Gallery, responsive layout, and how Cafe Fausse prevents selection of a full reservation interval.

#### 3:45-4:35 - Gallery and lightbox

**Action:** [Use shared navigation to open Gallery. Point to restaurant-interior, dishes, special-occasion, and behind-the-scenes imagery plus awards and reviews. Open a middle image, select Next or Previous once, point to the changed image/counter, then Close.]

**Narrative:**

> Gallery presents the required restaurant interior, dishes, special occasions, and behind-the-scenes work in a responsive grid. It also showcases Cafe Fausse's awards and positive reviews. Selecting an image opens the accessible lightbox. The controls move through the bounded image collection, update the displayed image and position, and return cleanly to Gallery when closed.

#### 4:35-5:15 - Responsive behavior

**Action:** [Open Chrome or Edge DevTools, enable the device toolbar, set 390 x 844, and show the shared navigation and either the Gallery grid or Home layout reflowing. Verify there is no horizontal page scrollbar. Restore desktop width and close DevTools.]

**Narrative:**

> At a 390-by-844 viewport, the CSS Grid and Flexbox layout reflows the navigation and content without horizontal page scrolling. The same implementation supports desktop, tablet, and smartphone layouts. This responsive viewport demonstration is separate from the retained compatibility evidence: Chrome and Edge passed, and Firefox and Safari passed through manual, user-approved verification.

#### 5:15-6:15 - Full/unavailable reservation behavior

**Action:** [Navigate to Reservations. Enter `FULL_DEMO_DATE` and party size 120. Select Check availability. Point to `FULL_DEMO_TIME`, which must be labelled Unavailable and must not be selectable. Do not submit a reservation in this scenario.]

**Narrative:**

> On Reservations, the user selects a date and party size before requesting availability. The browser does not invent or accept an arbitrary time. Flask returns the valid time slots using database-backed operating hours, start interval, duration, booking window, lead time, timezone, and table capacity. This rehearsed party uses the full 120-seat baseline capacity for the occupied interval. The target time is therefore displayed as Unavailable and cannot be selected, while unrelated intervals may still remain available.

**Required visible result:** The exact rehearsed `FULL_DEMO_TIME` is visibly unavailable and non-clickable.

#### 6:15-6:40 - Reliability decision and handoff

**Action:** [Keep Reservations and the unavailable slot visible.]

**Narrative:**

> Availability is advisory in the browser but authoritative on the server: PostgreSQL and Flask recheck capacity during creation so stale or simultaneous requests cannot overbook a table. P3 will now create a valid reservation and prove its customer, reservation, and table-assignment records directly in PostgreSQL.

### P3 - 6:40 to 10:00

#### 6:40-7:05 - Identity

**Action:** [P3's camera remains visible. P3 states their actual name and presents the required ID so the name and picture are legible, then removes it.]

**Narrative:**

> My name is [P3 states actual name], and I am P3. I will complete a successful reservation, verify the persisted database records, and summarize the architecture and verification evidence.

#### 7:05-8:25 - Successful reservation

**Action:** [If not already shown immediately before the timed demo, briefly show the approved reservation before-state result of zero for `RESERVATION_DEMO_EMAIL`. In Reservations, enter `SUCCESS_DEMO_DATE`, party size 6, and select Check availability. Choose a returned Available slot. Enter the unique fictional customer name, email and confirmation, and fictional phone. Leave newsletter unchanged unless the approved rehearsal explicitly requires otherwise. Review, submit once, and pause on confirmation. Copy the decimal reference into `reservation_reference`.]

**Narrative:**

> This second fictional identity has no prior reservation. For a party of six, the application requests server-authoritative availability and allows selection only from the returned slots. The reservation form validates the required name, matching email entries, optional phone, party size, date, and selected time. When Reserve table is selected, Flask independently validates the request, PostgreSQL rechecks the interval atomically, and the capacity-aware allocation assigns an available table combination. The confirmation shows the reference, local and canonical interval, party size, assigned table numbers, and current newsletter state.

**Required visible result:** `Reservation confirmed` appears with a readable reference and assigned tables. Capture the reference before leaving the page.

#### 8:25-9:15 - Direct reservation persistence evidence

**Action:** [Switch to `psql`. Insert the captured value only into the prepared `reservation_reference` variable. Run the approved customer/reservation query and the approved normalized table-assignment and aggregate queries from Sections 5.3-5.5 of the committed Prompt-28 plan.]

**Narrative:**

> The browser reference and unique email select exactly one persisted customer and reservation. The reservation row contains the authoritative interval and party size. The separate reservation-to-table assignment rows preserve the complete one-to-many allocation, and the aggregate reconstructs the same sorted table numbers displayed in React. The browser confirmation and PostgreSQL records therefore refer to the same transaction.

**Required visible result:** One matching reservation/customer row, its assignment rows, and an aggregate matching the browser reference, interval, party size, and table numbers.

#### 9:15-9:40 - Configuration and implementation decisions

**Action:** [Run or show the approved configuration/capacity query from Section 5.6. Keep the result large enough to read.]

**Narrative:**

> PostgreSQL owns persistent data and configurable policies, including start interval, duration, advance window, same-day lead time, timezone, operating hours, and per-table capacity. Flask is the server-authoritative validator and transaction orchestrator, while React presents returned state. Normalized assignments and interval checks protect exclusive table occupancy.

#### 9:40-10:00 - Verification, AI disclosure, and close

**Action:** [Keep the application or readable evidence visible; do not scroll through large logs.]

**Narrative:**

> Verification progressed from PostgreSQL to Flask, React, full-stack integration, and performance. NFR-1 and both NFR-2 form measurements passed; all four required browsers are recorded as passed. ChatGPT supported requirements, planning, review, and selected image generation; Codex supported repository work, tests, guarded tooling, and documentation. This concludes Cafe Fausse.

## 6. Handoff choreography

- P1 finishes with the words **“P2 will now demonstrate…”** P2 begins immediately; do not exchange greetings.
- P2 finishes with **“P3 will now create…”** P3 begins immediately.
- The outgoing speaker stops sharing control only after the next required page is visible.
- Use one designated screen operator if the meeting platform makes control transfers slow. The assigned person still speaks the narrative for their segment.
- If a handoff consumes more than five seconds, the incoming speaker shortens only optional descriptive wording. Never remove a required identity check, functional demonstration, database effect, or implementation-decision statement.

## 7. Rehearsal checkpoints

Run at least one full rehearsal with a visible timer.

| Checkpoint | Expected clock | Corrective action if late |
|---|---:|---|
| P1 hands off to P2 | 3:20 | Reduce scrolling on Menu/About; do not remove newsletter database evidence |
| P2 hands off to P3 | 6:40 | Show only one lightbox navigation action and one responsive page |
| Reservation confirmation captured | 8:25 | Shorten explanation while preserving confirmation and reference capture |
| PostgreSQL reservation proof complete | 9:15 | Show prepared query results without narrating every column |
| Final sentence complete | 10:00 maximum | Rehearse again; do not rely on speaking faster during the real demo |

Recommended delivery target during rehearsal is **9:40-9:50**, leaving 10-20 seconds for ordinary pauses while retaining the hard 10:00 limit. The equal 3:20 windows remain the choreography boundaries; optional wording may be shortened within a window.

## 8. Rubric and requirement coverage

| Required evidence | Demo location |
|---|---|
| P1, P2, and P3 visible; each speaks, states name, and presents ID | Start of each person's segment |
| Five pages and navigation | P1: Home, Menu, About Us; P2: Gallery, Reservations |
| Newsletter signup | P1, 1:05-2:10 |
| Newsletter effect in backend database | P1, before/after `psql` evidence |
| Correctly functioning reservation system | P2 availability plus P3 successful creation |
| Unavailable/full behavior | P2, 5:15-6:15 |
| Reservation effect in backend database | P3, 8:25-9:15 |
| Gallery, awards, reviews, and lightbox | P2, 3:45-4:35 |
| Responsive design | P2, 4:35-5:15 |
| Implementation decisions | P1 architecture; P2 server authority; P3 configuration and transactions |
| React, Flask, and PostgreSQL roles | P1 and P3 |
| Automated testing and AI-assisted implementation | P3 close |
| Browser compatibility | P2 responsive narrative and P3 close; Firefox/Safari remain described only as manual, user-approved passes |

## 9. Stop and restart conditions

Stop rather than narrating around any of these failures:

- A presenter, camera, microphone, required name statement, or ID verification is missing.
- PostgreSQL, Flask, React/Vite, or readiness checks are unhealthy.
- A unique demo identity already has an unexpected row, making before/after evidence ambiguous.
- Newsletter success appears without the exact PostgreSQL row and subscribed state.
- `FULL_DEMO_TIME` is selectable or is not labelled Unavailable.
- Reservation submission fails, the confirmation/reference is missing, or the database result does not match it.
- The database query returns zero or multiple unexpected rows.
- A required page, navigation route, Gallery/lightbox action, or responsive layout fails.
- Secrets, personal information, unrelated notifications, or an unsafe terminal become visible.
- The rehearsal or demo exceeds 10:00.

Use the approved guarded reset/cleanup workflow before retrying. Do not manually patch database rows, invent substitute evidence, claim that all tests pass, or represent Firefox/Safari testing as automated.

## 10. Final ready-to-demo checklist

- [ ] P1, P2, and P3 have rehearsed their exact 3:20 windows.
- [ ] All three cameras and microphones work, and camera tiles do not obscure evidence.
- [ ] All three IDs are ready; actual names will be stated.
- [ ] Application and health checks pass in the clean nonproduction environment.
- [ ] `NEWSLETTER_DEMO_EMAIL` and `RESERVATION_DEMO_EMAIL` are unique and fictional.
- [ ] `FULL_DEMO_DATE` and `FULL_DEMO_TIME` produce the rehearsed unavailable state.
- [ ] `SUCCESS_DEMO_DATE` has an available party-of-6 slot.
- [ ] Approved PostgreSQL queries are prepared and readable.
- [ ] Browser, `psql`, and DevTools windows are arranged in demonstration order.
- [ ] Notifications, secrets, and unrelated content are hidden.
- [ ] Guarded cleanup/reset procedure is ready.
- [ ] Full rehearsal completes by 10:00, preferably by 9:40-9:50.

