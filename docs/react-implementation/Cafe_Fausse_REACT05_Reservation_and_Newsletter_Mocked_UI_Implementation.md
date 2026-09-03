# Cafe Fausse REACT-05 Reservation and Newsletter Mocked UI Implementation

**Status:** APPROVED AND FROZEN

**Increment:** REACT-05 / Prompt 23

**Date:** 2026-08-25

> **Supersession note (2026-09-02):** PRA-030 supersedes only this historical report's legacy optional-period and missing-`maxLength` middle-initial behavior. Current request input is optional and, when supplied, accepts exactly one alphabetic character with maximum length one and no period. The implementation record below is intentionally preserved as historical evidence; read-only name formatting is unchanged.

## 1. Baseline and scope

Phase 0 began on `main` at full HEAD `f1fee08834f781ce6288ad771343b5a0842025b9`. `HEAD`, `origin/main`, and `origin/HEAD` were aligned (`0/0`), the worktree and real Git index were clean, and recent history showed the approved Prompt-22 checkpoint `417b212edf23b620ee008bdb371f690d6e3e2abf` followed only by the committed Prompt-23 input. REACT-01 through REACT-04 were confirmed `APPROVED AND FROZEN`; all 57 pre-existing tests passed before implementation.

This increment implements reservation and newsletter React behavior against project-owned mock operations only. It makes no backend/database/API-contract change and adds no production/native-fetch adapter, live Flask request, proxy, CORS, persistence, or cross-layer verification. Those remain Prompt 24.

## 2. Paths and preserved toolchain

Created:

- `frontend/src/api/contractFixtures.js` — centralized API-02 fixtures and public error test helper.
- `frontend/src/api/operations.js` — injected OP-01–OP-05 boundary and default in-memory mocked client.
- `frontend/src/forms/validation.js` — contract-compatible identity/contact validation and request normalization.
- `frontend/src/forms/useNewsletterLookup.js` — 400 ms OP-03 debounce with sequence, identity-snapshot, retry, and dirty-choice guards.
- `frontend/src/components/FormPrimitives.jsx` — labelled fields, linked error summary, and status-panel semantics.
- `frontend/src/features/reservations/ReservationFeature.jsx` — the approved reservation feature boundaries and complete progressive flow.
- `frontend/src/features/newsletter/NewsletterPreferences.jsx` — canonical Home-only standalone preference form.
- `frontend/src/test/validation.test.js`, `ContractMockSemantics.test.js`, `ReservationFeature.test.jsx`, `NewsletterPreferences.test.jsx`, and `MockedPageFlows.test.jsx` — focused contract/unit/component/full-route coverage.
- `frontend/src/test/msw/server.js` and `operationClient.js` — test-only MSW handlers and fetch client; neither is shipped in the application build.
- `frontend/scripts/owned-browser-process.ps1` — guarded REACT-05 Chrome/Edge launch, durable ownership markers, status, stop, and cleanup verification.
- this report.

Changed:

- `frontend/src/App.jsx`, `pages/HomePage.jsx`, and `pages/ReservationsPage.jsx` — inject operations and fill the frozen feature boundaries.
- `frontend/src/styles/components.css` and `styles/pages.css` — form/status/slot/confirmation presentation and frozen responsive grids.
- `frontend/src/test/setup.js`, `test-utils.jsx`, and `AppRoutes.test.jsx` — MSW lifecycle, injectable clients, and Prompt-23 route expectations.
- `frontend/package.json` — focused test scripts only; no dependency or version change.
- `frontend/TestInstructions.md` — repeatable Prompt-23 test/manual/recovery/cleanup procedures.

The exact frozen React 19.2.8, React DOM 19.2.8, React Router 8.3.0, Vite 8.2.2, Vitest/V8 4.1.11, jsdom 30.0.1, Testing Library, and MSW 2.15.0 dependency graph and lockfile are preserved.

## 3. Component and state architecture

`ReservationsPage` retains `ReservationFeatureBoundary`, which delegates OP-01 lifecycle to `ReservationContextBoundary` and owns one progressive form containing `AvailabilityArea`, `CustomerAndReservationFormArea`, `ReservationReviewArea`, `ReservationFeedback`, and the distinct `ReservationConfirmationView`. `NewsletterPreferences` is reusable but instantiated once in the frozen Home placement. Small repeated field/error/status markup is shared; one-use business markup stays within its feature.

State distinguishes API snapshots (context, current-key availability, newsletter baseline, mutation result), user values/selections, and transient touched/error/pending/sequence/dirty/snapshot/recovery/confirmation state. No PII or workflow snapshot is placed in URLs, browser history state, localStorage, sessionStorage, IndexedDB, analytics, or logs.

## 4. Mock-operation and API-02 contract handling

Components depend on five operation methods, not fixtures or transport. `contractFixtures.js` adapts the exact frozen API-02 examples: public paths and the test-only MSW layer retain exact methods, query/body fields, status classes, codes, flags, success enums, and confirmation properties. Default browser behavior is deterministic without modeling a database, allocation, overlap, capacity, or slot-generation algorithm. Only exact OP-02 key `2026-09-12|4` has the approved ten-slot example; changing date or party returns a keyed empty response. Shared fixture resolvers make the in-app mock and MSW defaults use the same full-identity OP-03 conflict/omitted-middle semantics, OP-04 final-state results, and OP-05 stored spelling, committed interval, and final newsletter facts.

MSW is used only for full-route tests. Its native-fetch test client lives under `src/test/`; the production bundle has no Flask adapter or live request path.

## 5. Reservation context, controls, availability, and slots

OP-01 loads on feature entry with stable loading status, contract-fact rendering, blocked failure, and explicit retry. Context supplies timezone, seven hours rows, interval, duration, advance/lead policy, inclusive native date bounds, and party maximum. No browser/server clock or fallback booking authority is invented.

The date and integer party inputs use native controls and OP-01 bounds. Edits invalidate the exact current availability key, request sequence, selection, and eligibility while preserving customer data. OP-02 is explicit, suppresses duplicate pending requests, ignores any sequence/key-stale completion, preserves API order, renders every returned slot, retains disabled unavailable entries, never auto-selects, distinguishes empty and all-unavailable results, and moves focus when refresh removes a selection. The 320/390/768/1280 layout is 1/2/3/4 columns; wide layouts remain at four so targets/labels remain safe.

## 6. Customer validation and email confirmation

Required first/last/email/confirmation and optional middle/phone fields use persistent labels, Required/Optional text, approved autofill/mobile types, touched blur validation, corrected-field revalidation, and all-field submit validation. Name limits count Unicode code points, including supplementary-plane letters; middle initial accepts exactly one Unicode letter plus optional period; native UTF-16 `maxLength` is not applied to these code-point-limited controls. Email accepts the frozen dot-atom/domain-label profile, including one valid single-label domain, while retaining all prohibited-form and 254-character checks. Paste is unrestricted; confirmation is never copied or hidden. Invalid submit focuses a linked summary while preserving values; public server field objects map by exact field/code, never message parsing.

## 7. Newsletter synchronization and standalone preferences

Both flows use a 400 ms eligible OP-03 debounce plus monotonically increasing request sequence, exact normalized identity snapshot, retry generation, and choice version. Identity edits invalidate the baseline; stale/late results cannot update current state, and any deliberate checkbox choice remains dirty across later lookups. Matched/not-found/conflict/indeterminate states reveal only allowed facts. Reservation can continue with `newsletter_action:"no_change"` after indeterminate lookup; a dirty choice is applied only after a reliable current result.

The sole Home form submits exact OP-04 identity plus final Boolean, locks the immutable snapshot while pending, suppresses duplicates, uses authoritative returned state, treats `no_customer_no_change` as successful false/no-created-customer behavior, maps safe conflicts, and distinguishes known failure from outcome unknown. Unknown recovery resends the same frozen object; unsubscribe never claims deletion.

After OP-04 success, the returned Boolean replaces the displayed OP-03 baseline as well as the checkbox. This prevents matched-subscribed copy after unsubscribe and not-found copy after successful subscribe; a later identity edit clears the acknowledgement and starts the ordinary eligible lookup sequence.

## 8. Review, immutable booking, recovery, and confirmation

Eligibility requires current context, valid date/party, an available selected slot belonging to the exact OP-02 key, valid structured customer data, matching emails, an allowed newsletter action, and no pending/recovery owner. Review is a `dl`. Activation revalidates, captures one frozen OP-05 body containing only approved ordinary facts, locks controls, suppresses duplicate submit, and announces pending without optimistic success.

Behavior branches on operation, status/code, `retryable`, `outcome_unknown`, and field codes. Implemented branches cover validation, both identity conflicts, overlap, unavailable plus required refresh, newsletter indeterminate, temporary/service failures, confirmation unavailable, outcome unknown, transport ambiguity, protocol/integration-defect fallback, and unexpected known errors. Known retry/confirmation/unknown states retain the exact body; unknown does not claim failure; no mutation is automatically retried; unavailable cannot reuse stale availability.

Independent-review corrections preserve OP-02 error metadata and remove retry controls/copy when `retryable:false`; separate OP-03 conflict, middle conflict, indeterminate, retryable read failure, and non-retryable integration states; invalidate the complete current availability snapshot only from approved OP-05 field/code pairs; and avoid retry instructions for generic known non-retryable reservation failures. Prompt 23 has no production dispatch-proof field, so unclassified OP-04/OP-05 transport loss remains conservatively outcome unknown pending Prompt 24.

The second independent-review correction makes mutation recovery represent only the latest completed OP-04/OP-05 result. Each caught mutation result first supersedes stale recovery ownership; only current retryable/unknown semantics reinstall an immutable snapshot. A definitive validation, identity/middle conflict, overlap, or unavailable response therefore unlocks controls and removes stale identical-resend actions. Reservation unavailable retains only refresh/reselect recovery. Commit-aware newsletter summary focus preserves the definitive error after recovery controls are replaced.

Both `201 created` and `200 exact_retry` render a focused confirmation with all and only public API fields: stored display name, public reference, returned local/UTC interval facts, party, assigned table numbers, final newsletter Boolean, restaurant contact, and optional safe phone notice. It exposes no customer/contact/fingerprint/capacity/allocation facts and makes no delivery claim. Active form/PII state is cleared after the confirmation snapshot renders; a new reservation starts fresh.

## 9. Accessibility and responsive implementation

The implementation uses semantic forms, fieldsets/legends, explicit labels, native date/number/radio/checkbox controls, programmatic descriptions/errors, focused linked summaries, status versus alert regions, busy/disabled locks, non-color-only Selected/Unavailable text, required-action focus, prominent unknown recovery, and confirmation focus. Existing 44 px targets, focus tokens, source order, breakpoints, and reduced-motion behavior are preserved. Manual results below are targeted evidence, not a WCAG certification claim.

## 10. Verification evidence

- Pre-existing baseline: 57/57 passed.
- Focused reservation/validation: 40 tests passed (15 validation, 25 reservation).
- Focused newsletter: 19 tests passed.
- Contract/default mock semantics: 4 tests passed; MSW full-route mocked flows: 21 tests passed (25 combined through `test:mocked-flows`).
- Full suite: 11 files, 141 tests passed.
- Coverage: statements 92.53% (669/723), branches 88.79% (539/607), functions 88.60% (171/193), lines 95.13% (567/596).
- Production build: passed; 111 modules transformed.
- Dependency audit: `npm audit --audit-level=low` passed with `found 0 vulnerabilities` after registry access was authorized.
- Browser/manual matrix: passed through directly launched, locally installed headless Chrome/Edge and CDP/browser-executed JavaScript; detailed evidence follows below.
- `TestInstructions.md` correction-pass restart/cleanup evidence: the guarded helper started and proved ownership of Vite PID 16508 on port 5173, then stopped only that process. Chrome PID 16204/profile/CDP 9331 and Edge PID 1892/profile/CDP 9332 were recorded before launch; each browser exited through CDP `Browser.close`. Final cleanup removed profiles/harnesses plus coverage/build/process state and verified ports 5173/4173/9331/9332 closed.
- Second-review browser-cleanup evidence: all 17 PowerShell blocks in `TestInstructions.md` and `owned-browser-process.ps1` parsed with zero errors. A live owned Chrome run on CDP 9441 recorded and validated PID 296, creation time, installed executable, exact profile, command line, and port before stopping only that process and removing verified evidence. A valid stale marker for exited PID 999999 on closed port 9442 cleaned without terminating a process. A mismatched-owner marker on port 9443 was refused, its marker/profile remained, and the unrelated PowerShell process remained alive; only the exact test-created refusal fixture was then removed. Final checks confirmed 5173, 4173, 9441, 9442, and 9443 closed.
- `git diff --check`: passed (line-ending conversion warnings only). The Git index matches `HEAD`, nothing is staged, and no commit/push was performed.

The automated suite covers OP-01 retry/bounds; native controls; explicit/current-key OP-02; empty/full/stale/refresh loss; field/email/optional validation; 400 ms lookup, stale and dirty guards; exact OP-04/05 bodies; pending deduplication; public failure/recovery distinctions; transport ambiguity; created/exact-retry confirmation; and MSW route-level happy/full/unknown/newsletter flows. Tests query roles, names, labels, descriptions, checked/disabled/busy state, status/alert, and focus without large snapshots.

### 10.1 Direct local browser evidence

The correction pass invoked Chrome directly from `C:\Program Files\Google\Chrome\Application\chrome.exe`, version `151.0.7922.170`, with `--headless=new`, an isolated repository-local user-data directory, and CDP port 9331. The exact `2026-09-12|5` key rendered zero slots, while `2026-09-12|4` rendered ten. Reservation layouts at 390×844 and 1280×800 measured 2 and 4 slot columns with `scrollWidth === clientWidth` (375 and 1265). The complete Ada/no-middle flow displayed matched subscribed status, sent `no_change`, preserved authoritative subscribed confirmation state, focused confirmation, and rendered returned local interval plus canonical `2026-09-12T21:00:00Z`/`2026-09-12T22:30:00Z` values.

Chrome rendered native `date` and `number` inputs with mock OP-01-derived date `min=2026-08-24`, `max=2026-10-23`, party `min=1`, and party `max=120`. Date/party columns were 1/1/2/2/2; slot columns were 1/2/3/4/4. Every run rendered all ten slots in API order, including three disabled unavailable radios; one deliberately selected available slot was checked and displayed `Selected`. The structured six customer/contact fields, confirmation email, reservation newsletter control, and absence of the standalone Home form on Reservations were all observed. First slot targets were at least 70 px high and the measured reservation action was 50 px high.

The complete mocked Chrome booking exercised context, availability, slot selection, all identity/contact fields, pending `aria-busy`, disabled submit, pending status, focused confirmation, public reference/table, delivery disclaimer, and absence of the submitted email from confirmation. CDP Tab injection traversed the native date control's internal segments and reached `party_size`. Invalid submission produced four linked errors and focused the summary. A mocked refreshed slot became disabled, cleared selection, and focused the required-action message. A test-only injected `reservation_outcome_unknown` displayed the alert, locked ordinary fields, exposed identical retry, and recovered to a focused `exact_retry` confirmation.

Chrome confirmation checks at 320×568, 390×844, 768×1024, 1280×800, and 1440×900 measured client/scroll widths 305/305, 375/375, 753/753, 1265/1265, and 1425/1425: no horizontal overflow. The Home flow changed matched subscribed to authoritative not subscribed with no contradictory old copy, then changed identity and saved unknown false as `no_customer_no_change` with current not-subscribed copy. Chrome's 400%-equivalent CDP setting exposed a 320 CSS px effective viewport at device scale 4 (`clientWidth=305`, `scrollWidth=305`) with no horizontal overflow.

The correction pass invoked Edge directly from `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`, version `151.0.4129.101`, with an isolated profile and CDP port 9332. It repeated exact-key isolation, 390×844 two-column and 1280×800 four-column reservation layouts, matched/no-change subscribed confirmation, local/canonical interval rendering, authoritative standalone unsubscribe, unknown false/no-customer behavior, and confirmation overflow checks at all five widths. Every recorded Edge `scrollWidth` equaled `clientWidth`.

The first Chrome run exposed one actual CSS defect: 390 px still used one slot column because the two-column media query began at 480 px. The sole implementation correction moved the slot-only breakpoint to 24 rem (384 px). The complete Chrome matrix was rerun and recorded the frozen 1/2/3/4/4 result; Edge then passed with the corrected CSS. No business, component, API, or dependency decision changed.

## 11. Traceability, exclusions, and checkpoint

The implementation traces to SRS FR-06–09 and FR-15–16, NFR-03–09; PRA-006–025 and PRA-029 at the React authority boundary; API-02 OP-01–OP-05; and frozen REACT-01/02/03/04 architecture, UX, visual, accessibility, responsive, and test decisions. Home/Menu/About/Gallery, shell/navigation, Gallery source assets, error boundary, and frozen design/API/backend/database artifacts are unchanged.

Prompt 24 remains explicitly deferred: production/native fetch, live Flask/PostgreSQL calls, cross-layer effects, live timings, and integration proof are not present or claimed. Asset provenance/licensing remains the frozen checkpoint for final delivery/INT-08 and is not changed by this increment.

**Approval checkpoint:** REACT-05 passed independent final implementation review and is **APPROVED AND FROZEN**. The final complete review artifact was `REACT05-review-final.diff` (181,299 bytes; SHA-256 `F7ED5824A368D6659A92F7C3849CE378684A814F6655F8047348E407F5C7B02C`; 26 represented paths). The first independent review identified five findings, and the second independent review identified three additional findings; all eight findings were corrected and independently re-reviewed. REACT-05 / Prompt 23 is approved and frozen. Prompt 24 remains the next implementation increment; Prompt 24 live React-to-Flask integration is not being implemented by this documentation closeout.
