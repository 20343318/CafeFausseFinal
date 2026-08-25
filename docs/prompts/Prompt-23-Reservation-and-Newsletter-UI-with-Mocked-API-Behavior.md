# Prompt 23 — Implement Reservation and Newsletter UI with Mocked API Behavior

## Objective

Continue Phase D — React/JSX from the approved and frozen REACT-04 / Prompt-22 checkpoint.

This prompt is the revised and resequenced version of the original Game Plan Prompt 22:

> Implement reservation and newsletter UI.

Implement the complete **reservation and newsletter frontend behavior with mocked API responses only**.

This increment must implement the frozen REACT-02 reservation/newsletter UX and the frozen REACT-03 form/test decisions while preserving the approved REACT-04 application.

Do **not** connect the application to the live Flask server or PostgreSQL in this prompt.

Stop for independent review and explicit approval before Prompt 24.

---

## Approval state

The approved repository checkpoint entering this increment is:

`417b212edf23b620ee008bdb371f690d6e3e2abf`

Commit message:

`feat(react): complete and approve REACT-04 static application`

At that checkpoint:

- `main`, `origin/main`, and `origin/HEAD` are aligned;
- the worktree is clean;
- REACT-01, REACT-02, REACT-03, and REACT-04 are approved and frozen;
- the static five-route React application, Gallery, visual system, accessibility shell, error boundary, test tooling, and `frontend/TestInstructions.md` are implemented;
- Prompt 23 is the next authorized increment.

Verify all of this from the repository during Phase 0 rather than relying only on this prompt.

---

## Resequenced React implementation plan

- Prompt 19 — REACT-01 / UI-01 architecture + Gallery design — approved/frozen;
- Prompt 20 — REACT-02 / UI-02 reservation/newsletter UX — approved/frozen;
- Prompt 21 — REACT-03 / UI-03 visual system + React test strategy — approved/frozen;
- Prompt 22 — REACT-04 / UI-04 static React application + Gallery — approved/frozen;
- **Prompt 23 — REACT-05 / UI-05 reservation/newsletter UI with mocked API behavior — this prompt;**
- Prompt 24 — live React → Flask integration;
- Prompt 25 — React verification gate.

Do not collapse Prompt 23 with Prompt 24.

---

## Authoritative sources and precedence

Use the current committed repository as the authoritative implementation state.

Read and apply, in this order:

1. repository-root `AGENTS.md` and any applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum v2.2.1;
5. approved least-to-most implementation roadmap;
6. frozen PostgreSQL contract and approved PostgreSQL artifacts only where frontend authority boundaries matter;
7. approved/frozen API-01 through API-09 artifacts, especially the exact API-02 Flask REST Contract;
8. approved/frozen REACT-01 architecture and Gallery artifact;
9. approved/frozen REACT-02 Reservation and Newsletter UX artifact;
10. approved/frozen REACT-03 Visual System and React Test Strategy;
11. approved/frozen REACT-04 implementation report and current committed frontend implementation;
12. this Prompt 23.

Do not reconstruct requirements from old chat text.

Do not contradict, weaken, replace, or reinterpret an explicit SRS, rubric, PRA, API-contract, or frozen React decision.

If implementation exposes a genuine contradiction or a business-rule gap, stop and report `BLOCKED` instead of inventing a supplemental requirement.

---

# Phase 0 — mandatory read-only baseline verification

Before modifying anything:

1. Record:
   - current branch;
   - full HEAD;
   - upstream relation;
   - recent relevant Git history;
   - `git status`;
   - Git-index state.

2. Confirm:
   - worktree is clean;
   - full HEAD is the approved Prompt-22 checkpoint or a later explicitly approved documentation-only equivalent;
   - REACT-01 through REACT-04 are recorded `APPROVED AND FROZEN`;
   - Prompt 23 is the next authorized increment;
   - existing frontend tests pass before changes.

3. Inventory:
   - `frontend/package.json`;
   - `frontend/package-lock.json`;
   - `frontend/src/`;
   - `frontend/src/test/`;
   - `frontend/TestInstructions.md`;
   - existing styles;
   - current Reservations and Home newsletter placeholders/boundaries.

4. Confirm the currently installed/frozen frontend stack remains:
   - React `19.2.8`;
   - React DOM `19.2.8`;
   - React Router `8.3.0`;
   - Vite `8.2.2`;
   - Vitest `4.1.11`;
   - V8 coverage `4.1.11`;
   - jsdom `30.0.1`;
   - Testing Library versions already frozen/installed;
   - MSW `2.15.0`;
   - ordinary project-owned CSS;
   - native React state/hooks.

5. Extract the exact API-02 request/response examples and public error semantics needed for:
   - OP-01 `GET /api/v1/reservation-context`;
   - OP-02 `GET /api/v1/reservation-availability`;
   - OP-03 `POST /api/v1/newsletter-status-queries`;
   - OP-04 `POST /api/v1/newsletter-preferences`;
   - OP-05 `POST /api/v1/reservations`.

6. Confirm Prompt 24 still owns:
   - the production/native-fetch Flask adapter;
   - live Flask calls;
   - Flask/PostgreSQL integration;
   - live cross-layer verification.

If the baseline is not clean, a frozen artifact is missing, or current repository state conflicts materially with the approved design, stop with `BLOCKED`.

---

# Part A — preserve the frozen frontend architecture

Do not redesign the site.

Preserve the existing REACT-04 shell, routes, Gallery, Home/Menu/About content, error boundary, navigation, visual tokens, responsive system, and tests.

Implement the previously reserved React boundaries using the smallest useful component structure consistent with REACT-01:

- `ReservationsPage`;
- `ReservationFeatureBoundary`;
- `ReservationContextBoundary`;
- `AvailabilityArea`;
- `CustomerAndReservationFormArea`;
- `ReservationReviewArea`;
- `ReservationFeedback`;
- `ReservationConfirmationView`;
- `NewsletterPreferences`.

Do not over-componentize trivial one-use markup.

Use:

- plain JavaScript + JSX;
- native React hooks/state;
- project-owned ordinary CSS;
- semantic HTML;
- existing frozen CSS tokens/breakpoints.

Do not add:

- Axios;
- Redux/Zustand;
- TanStack Query;
- Tailwind;
- Sass;
- CSS-in-JS;
- a UI/component framework;
- a date-picker library;
- a form library;
- a validation library;
- an icon library;
- Playwright/Cypress/Selenium/Puppeteer.

Do not change dependency versions unless an actual blocking issue is found. If a dependency change appears necessary, stop for approval.

---

# Part B — mocked-operation boundary and Prompt-24 separation

Prompt 23 implements complete UI behavior against **mocked operation results**, not live Flask.

Create the smallest operation boundary necessary for the React features to consume OP-01 through OP-05 without embedding mock fixtures directly throughout components.

Requirements:

- centralize mock contract fixtures/handlers;
- derive them from the exact frozen API-02 paths, schemas, statuses, fields, codes, `retryable`, and `outcome_unknown` semantics;
- do not invent a second or simplified API contract;
- tests must be able to substitute success/error/stale/unknown responses deterministically;
- use the already-approved MSW test tooling for mocked integration/page flows where appropriate;
- do not persist PII in localStorage/sessionStorage/IndexedDB;
- do not add mock database behavior;
- do not simulate table-allocation algorithms, capacity, overlap, or business-rule calculations in React.

**Prompt-24 boundary:** the production/native-fetch Flask adapter and actual live-server connection remain Prompt 24.

If satisfying the frozen REACT-03 MSW page-flow plan would require moving the production/live Flask adapter into Prompt 23, stop and report the boundary conflict rather than silently pulling Prompt-24 integration forward.

Mock behavior may model exact API-02 outcomes, but it must never be presented in documentation as proof of Flask/PostgreSQL integration.

---

# Part C — reservation context (OP-01)

Implement the frozen REACT-02 context workflow.

On `/reservations`:

- load mocked OP-01 context on feature entry;
- show the frozen skeleton/loading behavior;
- on success consume only public contract facts;
- on failure show the approved nontechnical failure/retry behavior;
- keep booking controls unavailable when authoritative context is unavailable.

Use OP-01 data for usability constraints and display, including as contract permits:

- restaurant timezone;
- operating hours;
- start interval;
- reservation duration;
- advance-window policy;
- same-day lead policy;
- inclusive minimum/maximum reservation dates;
- maximum party size.

Do not:

- invent a server clock;
- derive authoritative current restaurant time from the browser;
- hard-code the booking window, maximum party size, current hours, duration, interval, capacity, or table facts as booking authority;
- expose database configuration details.

Home current-hours live integration remains Prompt 24 unless the frozen artifacts explicitly require a mocked Home context state in this increment; if implemented now, it must use the same mock operation boundary and must not create contradictory static/live authority.

---

# Part D — date and party controls

Implement the frozen REACT-03 choices:

### Reservation date

Use native:

`<input type="date">`

Requirements:

- label persistently;
- apply OP-01 `min`/`max` values;
- include restaurant-local guidance;
- no combined date/time free-text input;
- no custom date-picker dependency.

When date changes:

- invalidate current availability;
- clear selected slot;
- preserve useful customer fields;
- ignore any later stale OP-02 completion for the old date/party key.

### Party size

Use native:

`<input type="number">`

Requirements:

- minimum `1`;
- current maximum from OP-01;
- integer-only UI validation;
- direct numeric entry;
- no custom stepper;
- do not expose capacity/table derivation.

When party size changes:

- invalidate current availability;
- clear selected slot;
- preserve useful customer fields;
- ignore any stale OP-02 response for the old key.

Client validation is usability only. Do not create rules stricter than the frozen backend contract.

---

# Part E — availability request and slot selection (OP-02)

Implement explicit availability retrieval using the frozen request key:

- `local_date`;
- `party_size`.

Normal user flow:

`valid date + party → Check availability / Update times → mocked OP-02 → display full schedule`

Requirements:

- no arbitrary reservation-time text input;
- do not calculate slots locally;
- do not calculate missing times;
- do not compute end time;
- do not infer duration;
- do not calculate capacity/availability;
- do not choose or promise a table.

Async/staleness:

- suppress concurrent duplicate request for the same key;
- each request gets sequence/snapshot identity;
- only the latest response whose exact key still matches current date/party may update state;
- date/party edits invalidate in-flight older results;
- no polling/background refresh.

Slot rendering:

- render every returned legitimate slot;
- preserve API order;
- available slots selectable;
- unavailable slots remain visible and nonselectable;
- selected slot has checked semantics and visible non-color-only treatment;
- one available slot is not auto-selected;
- all-unavailable state is explicit;
- empty schedule is handled if the frozen contract permits it;
- refresh never auto-selects a replacement.

Use the frozen responsive slot layout:

- 320: 1 column;
- 390: 2 columns where labels/44px targets fit;
- 768: 3 columns;
- 1280: 4 columns;
- 1440: 4–5 only if frozen minimum target/label constraints remain satisfied.

If refresh removes/disables the previously selected slot:

- clear selection;
- announce/focus the required-action message per REACT-02;
- preserve customer details;
- never choose another time automatically.

---

# Part F — customer and reservation fields

Implement the structured form exactly as frozen.

Required:

- First name;
- Last name;
- Email;
- Confirm email.

Optional:

- Middle initial;
- Phone.

Also display/review:

- selected reservation date;
- selected slot;
- party size;
- newsletter preference/action.

Use persistent labels and visible Required/Optional guidance.

Honor frozen input/autofill/mobile guidance where applicable.

Do not:

- make middle initial required;
- make phone required;
- infer identity from phone;
- imply SMS or phone confirmation;
- add address/payment/account/password fields.

Implement client validation consistent with API-02/PRA only.

Validation timing:

- touched-field blur validation;
- revalidate corrected fields;
- validate all relevant fields at submission;
- do not show initial untouched-field errors.

After invalid submission:

- show linked error summary;
- focus the summary;
- keep field-level programmatic associations;
- preserve user-entered values.

Server/mock `validation_failed.fields` must map by exact public field/code semantics, not message parsing.

---

# Part G — email confirmation

Implement the frozen two-entry behavior.

Requirements:

- validate both email fields independently;
- once both are nonempty compare using only the approved normalization;
- mismatch message: `Email addresses must match.`;
- associate mismatch with Confirm email and error summary;
- never block paste;
- do not silently copy confirmation from Email;
- if primary Email changes, keep Confirm email visible so mismatch can be corrected;
- invalidate newsletter-status eligibility/result when identity becomes nonmatching;
- include `confirmation_email` in exact mocked OP-03/04/05 bodies as required by API-02.

Do not add domain ownership checks, double opt-in, case-sensitive matching, or delivery verification.

---

# Part H — newsletter synchronization inside reservation flow (OP-03)

Implement the frozen reservation newsletter behavior.

The reservation checkbox/preference is a user preference control, not authentication.

OP-03 eligibility and timing:

- wait until the exact required identity fields are locally eligible;
- use the frozen **400 ms debounce**;
- use fake timers only in debounce tests;
- sequence/snapshot checks, not the timer itself, provide correctness.

Represent the frozen states:

- not checked;
- checking;
- matched;
- not found/new customer;
- customer identity conflict;
- middle-initial conflict where applicable;
- newsletter status indeterminate;
- other allowed generic/technical failure.

Critical dirty-choice rule:

**A late or stale OP-03 result must never overwrite a deliberate newsletter choice made by the user.**

Implement:

- identity snapshot/version guard;
- user-choice dirty/version guard;
- stale response suppression;
- clear guidance that the initially displayed choice may not yet reflect an existing customer's stored status.

Do not require OP-03 success before reservation submission when the frozen design permits continuation with `newsletter_action: "no_change"`.

Do not expose stored customer values on identity conflicts.

---

# Part I — standalone Home newsletter preferences (OP-03 + OP-04)

Replace the REACT-04 Home newsletter placeholder with the single canonical full newsletter form in its frozen Home-only placement.

Do not add duplicate newsletter forms elsewhere.

Implement the exact approved identity fields required by API-02/PRA, including confirmation email.

Support:

- eligible status lookup;
- 400 ms debounce;
- matched/not-found;
- dirty-choice protection;
- stale lookup suppression;
- subscribe final Boolean;
- unsubscribe final Boolean;
- pending lock;
- authoritative returned state;
- known failure;
- outcome unknown;
- exact identical recovery;
- no-customer/no-change behavior where the frozen contract specifies it.

Preserve approved business rules:

- a customer may exist solely from newsletter signup;
- newsletter state is one Boolean on the customer;
- unsubscribe does not delete the customer;
- preference changes independently of reservations;
- an unselected/false preference for a person who does not yet exist must not silently create a customer when the frozen contract says no customer/no change.

No newsletter topics, frequency choices, marketing categories, history, double opt-in, or delivery confirmation.

---

# Part J — reservation review and submission (OP-05)

Implement the frozen progressive reservation flow, not a route-changing wizard.

Before submission, show a compact review using the approved semantics.

Submission eligibility requires current valid UI state for:

- OP-01 context loaded;
- valid date;
- valid party size;
- current selected available OP-02 slot belonging to the current exact date/party key;
- required customer fields;
- matching confirmation email;
- newsletter action state permitted by the frozen design.

Provide visible guidance when submission is disabled/incomplete.

### Exact submission snapshot

On activation:

1. rerun client validation;
2. verify selected slot still belongs to current availability key;
3. construct one immutable exact OP-05 request snapshot;
4. lock controls that could alter that snapshot;
5. disable duplicate submission;
6. show accessible pending feedback;
7. do not clear data;
8. do not optimistically claim success.

The request must contain only API-02-approved ordinary booking facts.

Do not send or generate:

- reservation date duplicate if not in the contract;
- end time;
- duration;
- restaurant timezone;
- availability flag;
- capacity;
- customer ID;
- reservation ID;
- table choice;
- fingerprint;
- idempotency key.

Use the server/mock-provided slot local start and UTC offset exactly where required.

---

# Part K — reservation result and error behavior

Implement the exact frozen REACT-02 mapping.

Behavior must branch on:

- operation;
- HTTP/status class represented by the mock;
- `error.code`;
- `retryable`;
- `outcome_unknown`;
- field codes.

Never branch on mutable API message text.

At minimum implement/test:

- `validation_failed`;
- `customer_identity_conflict`;
- `middle_initial_conflict`;
- `reservation_overlap`;
- `reservation_unavailable`;
- `newsletter_status_indeterminate`;
- `temporary_failure`;
- `service_unavailable`;
- `reservation_confirmation_unavailable`;
- `reservation_outcome_unknown`;
- generic integration-defect/unexpected error handling defined by the frozen mapping;
- transport/read failure distinctions defined by REACT-02.

Preservation/recovery must exactly follow REACT-02.

Examples of mandatory distinctions:

- validation failure preserves useful data and focuses mapped errors;
- overlap clears slot and requires another time;
- unavailable clears slot and refreshes availability; no identical OP-05 retry;
- known temporary failure offers explicit identical retry only when permitted;
- confirmation unavailable means reservation is known to exist and exact resubmission reconstructs confirmation;
- outcome unknown must **not** claim failure and must retain/lock the exact snapshot for identical recovery;
- no automatic mutation retry;
- no reservation lookup endpoint;
- no cancellation/modification/rescheduling controls.

A transport failure during OP-05 must be treated conservatively according to the frozen outcome-unknown rule unless the mock/test proves the request was never dispatched.

---

# Part L — success and confirmation

Both:

- `201 created`;
- `200 exact_retry`

are successful outcomes.

Render the distinct `ReservationConfirmationView`.

Use **all and only** public confirmation fields supplied by API-02.

Display authoritative returned facts such as the frozen contract permits:

- stored customer display name;
- reservation-local start/end;
- party size;
- public confirmation/reference;
- assigned table number(s), when publicly returned.

Do not recalculate duration/timezone semantics.

Do not expose:

- customer ID;
- internal reservation ID if not public;
- fingerprint;
- database outcomes;
- capacity;
- allocation internals.

Focus/announce the confirmation according to REACT-02.

Do not claim email/SMS/phone delivery unless the SRS/API explicitly provides it.

After confirmation is safely rendered, clear the active editable form state as frozen by REACT-02.

---

# Part M — state ownership and PII handling

Keep the smallest useful local React state.

Distinguish:

### Server/mock-authoritative snapshots

- OP-01 context;
- current OP-02 availability;
- OP-03 returned newsletter status;
- OP-04 returned final newsletter state;
- OP-05 confirmation/result.

### User-entered/selected state

- date;
- party size;
- selected slot;
- identity/contact fields;
- confirmation email;
- explicit newsletter preference.

### Transient UI state

- touched/errors;
- loading/pending flags;
- request sequence/key;
- dirty-choice version;
- submitted immutable snapshot;
- recoverable error;
- outcome-unknown state;
- confirmation state.

Do not duplicate business truth across multiple independent state locations.

Do not persist PII or form snapshots to:

- localStorage;
- sessionStorage;
- IndexedDB;
- URL/query parameters;
- browser history state.

No analytics/logging of customer identity.

---

# Part N — accessibility and responsive implementation

Implement all frozen REACT-02/03 form accessibility behavior.

At minimum:

- semantic form/fieldset/legend structure;
- explicit labels;
- Required/Optional text;
- helper text;
- `aria-invalid` and associated error text;
- linked error summary;
- correct alert/status live-region distinctions;
- `aria-busy` or equivalent where frozen;
- selected-slot radio semantics;
- unavailable/disabled semantics;
- focus movement after validation;
- focus/announcement when slot selection is invalidated;
- newsletter lookup/status announcements;
- pending mutation announcements;
- prominent outcome-unknown alert;
- confirmation focus;
- keyboard-only completion;
- state never conveyed by color alone;
- existing 44×44 minimum interactive targets;
- reduced-motion behavior preserved.

Use the frozen responsive breakpoints and source order.

At 320, 390, 768, 1280, and 1440 representative widths verify:

- no horizontal page scrolling;
- date/party layout;
- slot columns;
- identity-field reflow;
- review/error readability;
- Home newsletter form;
- confirmation;
- 44px targets.

At 400% zoom in a 1280px browser, form UI must reflow rather than create horizontal page scrolling.

Do not claim WCAG certification.

---

# Part O — mocked contract fixtures and MSW tests

Use MSW `2.15.0` and the existing Vitest/Testing Library stack.

Create centralized contract-faithful fixtures/handlers for the exact Prompt-23 workflows.

Do not create a second divergent schema.

Mock examples should be copied/adapted from approved API-02 examples/semantics, with PII-free fictional test values.

At minimum the full-route mocked test set must exercise:

1. reservation happy path:
   - OP-01 context;
   - OP-02 availability;
   - slot selection;
   - identity/newsletter sync;
   - review;
   - OP-05 exact request body;
   - pending lock;
   - created confirmation;

2. fully unavailable day;

3. selected slot becomes unavailable after refresh;

4. stale/late OP-02 response ignored;

5. date/party invalidation;

6. customer validation and email mismatch;

7. customer identity conflict;

8. middle-initial conflict;

9. OP-03 matched/not-found/indeterminate;

10. late stale newsletter lookup ignored;

11. dirty user newsletter choice not overwritten by late lookup;

12. reservation continuing with `no_change` when permitted;

13. reservation double-submit suppression;

14. `reservation_unavailable`;

15. `reservation_overlap`;

16. known retryable temporary failure;

17. `reservation_confirmation_unavailable` exact reconstruction path;

18. `reservation_outcome_unknown` frozen exact snapshot + identical recovery returning `exact_retry`;

19. transport ambiguity behavior;

20. standalone newsletter:
   - subscribe;
   - unsubscribe;
   - no-customer/no-change;
   - stale lookup;
   - known failure;
   - outcome unknown;
   - identical recovery;

21. accessibility roles/names/descriptions/status/alert/focus transitions;

22. representative responsive form behavior where DOM/state behavior changes.

Do not use large DOM snapshots.

Use role/name/label/status assertions.

Use `data-testid` only for a request-sequence seam that is otherwise unobservable to the user.

---

# Part P — unit/component tests

Add focused tests for all frozen REACT-02 behaviors, including:

- OP-01 load/success/failure/retry;
- OP-01 date/party bounds;
- native date validation;
- native numeric party validation;
- explicit Check/Update action;
- OP-02 loading;
- every returned slot visible in order;
- unavailable disabled;
- selected checked;
- empty/full/failure states;
- stale OP-02 suppression;
- selection invalidation;
- structured customer fields;
- email confirmation;
- optional middle/phone;
- field summary/focus;
- server field-code mapping;
- 400 ms OP-03 debounce;
- stale identity response;
- dirty-choice protection;
- submission eligibility helper;
- immutable OP-05 body;
- pending lock;
- duplicate-submit suppression;
- all frozen public failure/recovery branches;
- created confirmation;
- exact-retry confirmation;
- standalone newsletter state machine.

Preserve all REACT-04 tests.

No test may require live Flask or PostgreSQL.

---

# Part Q — visual/manual verification

Use the existing Prompt-22 guarded process-ownership procedures and `frontend/TestInstructions.md` conventions.

Perform practical local browser verification for the mocked forms using installed browsers.

At minimum verify in Chrome and Edge if still installed:

- `/reservations`;
- Home newsletter section;
- 320×568;
- 390×844;
- 768×1024;
- 1280×800;
- 1440×900 where practical;
- native date input presence and constraints;
- slot layouts;
- keyboard flow;
- focus/error summary;
- unavailable slots;
- pending states;
- outcome-unknown panel;
- confirmation;
- newsletter form;
- no horizontal overflow.

Do not claim Firefox if unavailable.

Do not claim Safari on Windows. Preserve the frozen requirement that actual Safari evidence is required before Prompt 25 approval in a Safari-capable environment.

No new browser automation framework.

---

# Part R — update `frontend/TestInstructions.md`

Update the existing file for Prompt 23.

Preserve the approved restartable/recoverable structure and guarded process ownership.

Add exact repeatable steps for:

- focused reservation tests;
- focused newsletter tests;
- MSW mocked page-flow tests;
- debounce/stale-response tests;
- full frontend suite;
- coverage;
- build;
- manual mocked reservation flow;
- manual Home newsletter flow;
- error/outcome-unknown/retry flows;
- responsive form checks;
- keyboard/focus/semantic checks;
- 200%/400% zoom and no-horizontal-scroll checks;
- interruption/recovery;
- final cleanup.

The final cleanup must:

- stop only proven-owned processes;
- remove all test-owned temporary resources;
- remove generated coverage/build/cache outputs;
- remove mock-only temporary fixtures/reports/screenshots not intentionally retained;
- verify cleanup actually succeeded;
- preserve source/tests/package files/lockfile/Gallery assets/user files;
- verify expected ports are closed;
- finish with the existing final repository status check.

Do not weaken any Prompt-22 cleanup safeguard.

---

# Part S — implementation report

Create:

`docs/react-implementation/Cafe_Fausse_REACT05_Reservation_and_Newsletter_Mocked_UI_Implementation.md`

Mark:

`PROPOSED — NOT YET APPROVED`

Include at minimum:

1. baseline full HEAD;
2. scope and Prompt-24 exclusion;
3. exact changed/created paths;
4. preserved toolchain/dependencies;
5. component/state architecture;
6. mock-operation boundary;
7. API-02 fixture source/contract handling;
8. reservation context;
9. date/party controls;
10. availability/staleness;
11. slots;
12. customer fields/validation;
13. email confirmation;
14. reservation newsletter synchronization;
15. standalone newsletter;
16. review/submission eligibility;
17. immutable OP-05 snapshot;
18. error/recovery mapping;
19. outcome-unknown behavior;
20. confirmation;
21. accessibility;
22. responsive implementation;
23. unit/component tests;
24. MSW mocked integration tests;
25. test totals;
26. coverage;
27. build/audit result;
28. manual browser checks actually performed;
29. `frontend/TestInstructions.md` updates and cleanup evidence;
30. requirements/design traceability;
31. explicit deferred Prompt-24 live integration;
32. remaining asset-provenance checkpoint;
33. approval status.

Do not declare REACT-05 approved.

---

# Part T — explicit scope exclusions

Do **not** implement Prompt 24.

Specifically:

- no production/native-fetch Flask adapter;
- no live Flask calls;
- no development proxy to Flask unless already approved and unused by this prompt;
- no PostgreSQL calls;
- no database changes;
- no backend changes;
- no Flask changes;
- no API contract changes;
- no CORS/deployment work;
- no live persistence verification;
- no performance-compliance claim from mocked tests.

Do not modify:

- SRS;
- Rubric;
- PRA;
- frozen DB/API/REACT-01/02/03/04 artifacts;
- committed Gallery source images.

Do not add:

- cancellation;
- modification;
- rescheduling;
- authentication/accounts;
- table selection;
- admin UI;
- reservation lookup;
- newsletter topics/history.

---

# Part U — Git restrictions

Do not:

- stage;
- commit;
- push;
- reset;
- clean;
- stash;
- rebase;
- merge;
- cherry-pick;
- switch branches;
- create/delete tags;
- modify pull requests.

Leave every Prompt-23 project change unstaged for independent review.

Preserve the real Git index.

Temporary test artifacts must use only approved/test-owned locations and be removed by final cleanup.

---

# Part V — verification gate before stopping

Before reporting completion:

1. Run the pre-existing REACT-04 test suite and all new Prompt-23 tests.
2. Run focused reservation tests.
3. Run focused newsletter tests.
4. Run MSW mocked page-flow tests.
5. Run full frontend tests.
6. Run coverage and report statements/branches/functions/lines.
7. Run the production build.
8. Run `npm audit --audit-level=low`.
9. Execute enough of the updated `frontend/TestInstructions.md` to prove restartability and cleanup.
10. Verify Chrome/Edge mocked form behavior actually performed.
11. Verify no live Flask/PostgreSQL request was used.
12. Verify no production/native-fetch Flask adapter was pulled forward.
13. Verify no backend/database/API/frozen-design/Gallery-source file changed.
14. Verify no PII persistence mechanism was added.
15. Run `git diff --check`.
16. Verify the real Git index is unchanged.
17. Verify nothing is staged, committed, or pushed.
18. Verify final cleanup removed all Prompt-23 test-owned resources.

If any frozen requirement cannot be implemented without changing an approved business/API rule, report `BLOCKED`.

---

# Completion response

Lead with exactly one of:

`READY FOR REACT-05 IMPLEMENTATION REVIEW`

or

`BLOCKED`

If ready, report concisely but completely:

- baseline full HEAD;
- branch/upstream/worktree Phase-0 result;
- exact changed/created paths;
- component/state architecture summary;
- mock-operation/MSW strategy;
- reservation context/date/party summary;
- availability/staleness/slot summary;
- customer/email-validation summary;
- reservation newsletter synchronization summary;
- standalone newsletter summary;
- submission snapshot/pending/deduplication summary;
- error/recovery/outcome-unknown summary;
- confirmation summary;
- accessibility/responsive summary;
- focused test counts;
- full test count;
- coverage;
- production build;
- npm audit;
- actual local browser checks;
- updated `frontend/TestInstructions.md` evidence and cleanup result;
- implementation report path;
- explicit Prompt-24 deferral;
- asset-provenance checkpoint;
- `git diff --check`;
- Git-index preservation;
- confirmation nothing staged/committed/pushed.

Do not declare REACT-05 approved.

Stop for independent review before Prompt 24.
