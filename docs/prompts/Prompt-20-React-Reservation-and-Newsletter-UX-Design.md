# Prompt 20 — Detailed Reservation and Newsletter UX Design

## Objective

Continue Phase D — React/JSX after the approved REACT-01 / UI-01 architecture and Gallery asset-analysis checkpoint.

This prompt is the **revised and resequenced version of the original Game Plan Prompt 19**:

> Design reservation UX.

This increment is **design-only**.

Do not generate React, JSX, CSS, JavaScript, TypeScript, package configuration, build tooling, or frontend tests yet.

The goal is to design the complete reservation and newsletter user experience against:

- the fixed SRS and rubric;
- the approved Project Requirements Addendum;
- the approved and frozen REACT-01 architecture;
- the frozen Flask API contract and approved backend behavior.

The design must preserve Flask/PostgreSQL authority and must not duplicate reservation business logic in React.

Stop for independent review and explicit approval before Prompt 21.

---

## Approval state

The following are approved, committed, pushed, and frozen:

- SRS and rubric baseline;
- Project Requirements Addendum v2.2.1;
- PostgreSQL DB-01 through DB-07;
- PostgreSQL Hard Gate 1;
- frozen PostgreSQL Contract for Flask;
- API-01 Backend Operation Inventory;
- API-02 Flask REST Contract;
- API-03 Flask Architecture, Configuration, and Test Strategy;
- API-04 through API-09;
- API08-RC-01 and API08-RC-02;
- Flask Hard Gate 2;
- REACT-01 / UI-01 architecture and Gallery asset-analysis design.

Verify the current full repository HEAD during Phase 0.

Do not assume an abbreviated commit hash from an earlier prompt is still HEAD.

React UX design is authorized.

React implementation is **not** yet authorized.

---

## Resequenced React prompt plan

The React sequence is:

- Prompt 19 — REACT-01: Gallery asset analysis + React architecture — approved/frozen;
- **Prompt 20 — REACT-02: detailed reservation/newsletter UX design — this prompt;**
- Prompt 21 — complete UI/UX + React test strategy;
- Prompt 22 — static React application + Gallery;
- Prompt 23 — reservation/newsletter forms;
- Prompt 24 — connect React to Flask;
- Prompt 25 — React verification gate;
- subsequent original prompts remain incremented by one unless later explicitly revised.

Do not collapse this prompt with Prompt 21.

---

## Authoritative sources and precedence

Use the current committed repository as the authoritative implementation state.

Read and apply, in this order:

1. repository-root `AGENTS.md` and any applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum v2.2.1;
5. approved least-to-most implementation roadmap;
6. approved PostgreSQL-to-Flask contract and current approved database design artifacts where relevant;
7. approved API-01 Backend Operation Inventory;
8. approved API-02 Flask REST Contract;
9. approved API-03 Flask Architecture, Configuration, and Test Strategy;
10. approved API-07 reservation-context/availability evidence;
11. approved API-08 reservation-creation evidence and API08-RC-01/API08-RC-02;
12. approved API-09 / Hard Gate 2 verification report;
13. approved/frozen REACT-01 architecture and Gallery asset-analysis artifact;
14. current committed backend implementation only where necessary to confirm frozen API behavior;
15. this Prompt 20.

Do not reconstruct requirements from old chat text.

Do not contradict, weaken, replace, or reinterpret an explicit SRS, rubric, approved addendum, frozen API requirement, or approved REACT-01 architecture decision.

If an interaction decision would introduce a new business rule rather than a UX/presentational choice, identify the gap and stop for approval rather than silently choosing a rule.

---

## Fixed UX principles

### Server authority

React is a usability layer, not the reservation authority.

Flask/PostgreSQL remain authoritative for:

- restaurant-local current time;
- booking-window validity;
- same-day lead time;
- operating hours;
- reservation start-time interval;
- reservation duration;
- valid slot generation;
- party-size validity;
- availability;
- capacity;
- table allocation;
- overlap prevention;
- same-customer overlap;
- customer identity matching;
- reservation retry identity;
- booking transaction outcome;
- newsletter/customer persistence.

Do not recreate those rules in React.

Client-side validation may improve usability but must never weaken or replace Flask validation.

### No arbitrary reservation time

The user must **not** type an arbitrary reservation time.

The conceptual flow remains:

`load reservation context → select valid date and party size → retrieve Flask availability → display all legitimate slots → select available slot → enter customer information → reconcile newsletter preference → submit reservation → show confirmation or recoverable failure`

React must use the frozen API-provided slot facts rather than calculate slot times itself.

### All legitimate slots remain visible

Where the frozen availability API returns all legitimate slots with availability state:

- display all returned legitimate slots;
- available slots are selectable;
- unavailable slots are visibly unavailable and not selectable;
- React must not silently hide an API-provided legitimate slot because client logic thinks it is invalid.

### Success and failure behavior

Approved behavior remains:

- prevent accidental duplicate submission while a reservation mutation is pending;
- on success, transition to confirmation;
- on ordinary validation/availability/error failure, remain on the reservation workflow and preserve useful user-entered data;
- do not assume an ambiguous/outcome-unknown mutation failed.

---

## Phase 0 — mandatory read-only prerequisite verification

Before creating the UX artifact:

1. record:
   - current branch;
   - full HEAD;
   - recent relevant Git history;
   - worktree status;

2. confirm:
   - worktree is clean;
   - REACT-01 is committed and recorded as approved/frozen;
   - API-09 / Hard Gate 2 remains approved/frozen;
   - no React implementation/build tooling exists unless already introduced by an approved checkpoint;

3. read the approved REACT-01 artifact and preserve its component boundaries, especially:
   - `ReservationsPage`;
   - `ReservationFeatureBoundary`;
   - `ReservationContextBoundary`;
   - `AvailabilityArea`;
   - `CustomerAndReservationFormArea`;
   - `ReservationReviewArea`;
   - `ReservationFeedback`;
   - `ReservationConfirmationView`;
   - `NewsletterPreferences`;

4. extract the exact React-facing API facts from the frozen API-02 contract for:
   - OP-01 reservation context;
   - OP-02 reservation availability;
   - OP-03 newsletter-status query;
   - OP-04 newsletter-preference mutation;
   - OP-05 reservation creation/reconstruction;

5. inventory the exact public error/status semantics React is allowed or required to distinguish;

6. confirm the approved customer identity/newsletter rules in the Project Requirements Addendum;

7. confirm the SRS-required reservation form fields and success/failure expectations.

If authoritative sources conflict, stop and report the conflict.

---

## Part A — reservation page interaction model

Design the reservation page as a clear sequence without turning it into unnecessary multi-step ceremony.

Define:

- first-load state;
- context-loading state;
- ready state;
- date/party selection state;
- availability-loading state;
- slot-selection state;
- customer-information state;
- newsletter-status synchronization state;
- submission-ready state;
- submission-pending state;
- success/confirmation state;
- recoverable-error state;
- ambiguous/outcome-unknown state.

Recommend whether the page should behave as:

- one progressive form;
- visually grouped sections;
- a limited stepper;
- or another simple pattern.

Choose based on clarity, accessibility, mobile behavior, and the small academic-project scope.

Do not invent a business rule requiring completion of an unnecessary step.

---

## Part B — initial reservation context

Design how `ReservationContextBoundary` uses OP-01.

Account only for contract-authorized public facts, including where applicable:

- restaurant identity/contact facts;
- restaurant timezone;
- server/current restaurant-local time facts;
- current operating hours;
- earliest/latest allowed reservation dates;
- reservation interval;
- duration where publicly exposed and useful;
- maximum party size;
- other approved public policy values.

Define:

- initial skeleton/loading behavior;
- successful context load;
- service-unavailable/configuration failure;
- user-facing retry control;
- what remains usable if context fails;
- accessibility announcement behavior.

Do not:

- hard-code a fallback booking window as if authoritative;
- calculate current restaurant date from browser local time when OP-01 supplies authoritative context;
- expose internal database/table configuration.

---

## Part C — date selection UX

Design the date control using API-provided bounds.

Address:

- earliest selectable date;
- latest selectable date;
- past dates;
- out-of-window dates;
- disabled versus hidden dates;
- restaurant timezone implications;
- keyboard use;
- screen-reader labeling;
- smartphone behavior;
- changing the selected date;
- clearing/invalidation of dependent availability and slot state.

The control must not allow arbitrary free-text date/time combinations that bypass the intended slot-selection workflow.

If browser-native date controls cannot present an approved constraint consistently across target browsers, document the UX concern for Prompt 21 without creating a new business rule.

---

## Part D — party-size UX

Use the authoritative public maximum supplied by the frozen API.

Define:

- minimum allowed user choice based on approved contract;
- maximum;
- recommended control type;
- integer-only behavior;
- keyboard and mobile usability;
- validation messaging;
- what happens to loaded availability and selected slot when party size changes.

Do not hard-code:

- 30 tables;
- total restaurant capacity;
- per-table capacity;
- derived maximum party size.

React must consume the public maximum instead.

---

## Part E — availability request behavior

Design when OP-02 is called.

Use exactly the frozen request fields and request location.

Define:

- triggering conditions;
- explicit versus automatic retrieval;
- loading state;
- request deduplication from a UX perspective;
- stale-response protection;
- behavior when date changes during an in-flight request;
- behavior when party size changes during an in-flight request;
- safe handling of network failure;
- safe handling of service failure;
- whether retry is explicit or automatic based on API semantics.

Do not invent background polling unless an approved source requires it.

Do not calculate missing slots locally.

---

## Part F — slot presentation and selection

Design the complete available-slot presentation.

Requirements:

- display every legitimate API-provided slot;
- available slots must be selectable;
- unavailable slots must remain visible but not selectable;
- selected slot must be visually and semantically distinct;
- keyboard access must be supported;
- selection must not depend on color alone;
- slot labels must be understandable in the restaurant's local-time context;
- no arbitrary time text box is permitted.

Address:

- zero returned slots if the contract permits that state;
- all returned slots unavailable;
- one available slot;
- many slots;
- mobile layout;
- wrapping/grid/list strategy at design level;
- loading replacement/skeleton behavior;
- focus behavior when refreshed availability removes the previously selected slot.

Do not:

- compute end time;
- infer duration;
- reorder slots contrary to the authoritative response unless the contract explicitly permits presentation sorting;
- silently drop unavailable slots;
- auto-select another slot when the user's selected slot becomes unavailable.

---

## Part G — customer information form

Map the UX to the SRS and approved supplemental requirements.

Account for:

- first name — required;
- middle initial — optional;
- last name — required;
- email — required;
- confirmation email — required and must match;
- phone — optional;
- party size — already selected/authoritative form state;
- reservation date/time — selected slot state, not free text;
- newsletter preference control where required by the approved flow.

Define:

- labels;
- required/optional indications;
- field grouping;
- browser autofill considerations;
- client-side validation timing;
- inline versus summary validation;
- preservation of values after recoverable failure;
- focus behavior on validation error;
- mobile keyboard/input-mode recommendations where appropriate.

Do not introduce accepted-value rules stricter than the backend contract unless they are purely presentational and do not reject valid API inputs.

---

## Part H — email confirmation behavior

The approved design requires email entry twice.

Define:

- when equality is checked;
- case/whitespace handling only as supported by approved backend/API behavior;
- mismatch message;
- whether confirmation email is included in API payload or is client-only validation based strictly on the frozen contract;
- what happens if the primary email changes after confirmation was entered.

Do not invent email normalization rules beyond approved contract behavior.

---

## Part I — middle initial and phone UX

Preserve approved semantics:

- middle initial optional;
- phone optional.

Do not make either field required.

Do not silently imply phone-based reservation confirmation if the system does not provide SMS/phone confirmation.

Do not infer identity from phone.

---

## Part J — newsletter synchronization inside reservation flow

Preserve the approved customer/newsletter rules.

The reservation form may expose a newsletter checkbox/preference control, but existing customers' stored newsletter status is synchronized asynchronously through OP-03.

Design:

- the point at which status lookup becomes eligible;
- minimum identity facts required by OP-03;
- lookup pending state;
- matched-customer state;
- not-found/new-customer state;
- mismatch/generic failure state;
- indeterminate/technical state where applicable;
- checkbox state before lookup completes;
- checkbox state after lookup completes;
- user interaction before lookup returns;
- stale lookup response protection if identity fields change;
- user guidance that the initially displayed checkbox may not yet reflect an existing customer's stored status.

Critical rule:

**Never overwrite a deliberate user newsletter choice merely because an older asynchronous lookup returns later.**

Do not require newsletter-status lookup to succeed before reservation submission unless the frozen API contract explicitly requires that.

---

## Part K — standalone newsletter UX

Prompt 20 also owns the detailed UX for the reusable `NewsletterPreferences` component.

Design the standalone newsletter flow against OP-03 and OP-04.

Account for approved rules:

- newsletter signup requires name and email identity as defined by the frozen contract/addendum;
- customer may exist solely through newsletter signup;
- newsletter state is one Boolean customer preference;
- subscribe/unsubscribe can change independently from reservations;
- unsubscribing does not delete the customer;
- unselected newsletter preference for a new person does not create a customer;
- status query is read-only;
- preference mutation returns authoritative resulting state.

Define:

- identity entry;
- status lookup timing;
- subscribe/unsubscribe control;
- pending state;
- success state;
- validation errors;
- customer mismatch behavior;
- network/service errors;
- stale responses;
- explicit user choice protection;
- whether the UI should use checkbox, switch, button pair, or another accessible control and why.

Do not invent newsletter history, topics, frequency, marketing categories, double opt-in, or email-delivery confirmation.

---

## Part L — reservation submission eligibility

Define when OP-05 submission becomes enabled.

At minimum require valid UI state for:

- context loaded;
- selected date;
- selected party size;
- current selected available slot;
- required customer fields;
- email confirmation match;
- any required newsletter choice state only where approved.

Do not make client validation the security boundary.

Define visible disabled-state guidance so users understand what remains incomplete.

---

## Part M — reservation submission behavior

Design the UX around OP-05.

Address:

- submit control;
- accidental double-click prevention;
- pending state;
- progress indication;
- preservation of form data during request;
- success transition;
- ordinary validation failure;
- identity mismatch;
- no-longer-available/full result;
- server/service failure;
- network failure;
- ambiguous/outcome-unknown result;
- exact retry behavior where the API exposes it.

Do not:

- generate a reservation fingerprint in React;
- reconstruct server idempotency/retry identity logic;
- choose a table;
- promise a table before success;
- assume a network error means the reservation was not committed.

---

## Part N — error taxonomy to UX mapping

Build a UX mapping from the frozen API-02 public error semantics.

For each user-relevant error class, record:

- API operation;
- HTTP status;
- public error code or error category;
- retryable flag where exposed;
- outcome-unknown flag where exposed;
- whether user input should be preserved;
- whether slot availability should be refreshed;
- whether identity fields should be highlighted;
- whether the user should explicitly retry;
- whether the UI must warn that the outcome may be unknown;
- whether navigation away should be discouraged until the user resolves the situation.

Do not expose:

- SQL;
- SQLSTATE;
- database role;
- table IDs;
- stack traces;
- internal exception details;
- connection/pool information;
- internal retry fingerprints.

User-facing wording can be proposed, but distinguish approved contract meaning from presentational copy.

---

## Part O — ambiguous/outcome-unknown UX

This state requires explicit treatment.

Design a distinct user experience when the API reports that mutation outcome may be unknown.

The UX must:

- clearly distinguish it from an ordinary failed reservation;
- not tell the user “reservation failed” unless authoritative;
- preserve the submitted reservation facts;
- provide the contract-supported recovery/retry path;
- avoid encouraging repeated blind submissions;
- explain what the user should do next in concise, nontechnical language.

Do not invent a lookup endpoint that does not exist.

---

## Part P — fully booked and availability-change UX

Distinguish:

1. one unavailable slot among others;
2. all legitimate slots unavailable for the selected date/party size;
3. selected slot becomes unavailable before submission;
4. booking loses capacity during final submission;
5. temporary OP-02 failure;
6. temporary OP-05 failure.

Define user recovery for each.

Do not automatically move the customer to a different time.

---

## Part Q — reservation confirmation UX

Design `ReservationConfirmationView` using only OP-05 public response facts.

Where returned by the contract, account for:

- customer's stored/display name;
- reservation date/start;
- reservation end;
- party size;
- confirmation/retry identifier if and only if publicly exposed;
- newsletter resulting state if returned;
- restaurant contact facts if returned/appropriate.

Define:

- confirmation heading;
- concise success message;
- reservation detail layout;
- local-time/timezone clarity;
- primary next action;
- route/navigation behavior;
- browser refresh/direct revisit considerations at design level.

Do not expose:

- database customer IDs;
- reservation fingerprint internals;
- table allocation details unless the frozen API explicitly makes them public;
- SQL/database information.

React must not recalculate end time or timezone conversion.

---

## Part R — state ownership model

Define the smallest useful UX state model without writing React code.

Classify each state as:

### Server-authoritative

Examples:

- reservation context;
- availability response;
- existing newsletter state;
- reservation result/confirmation.

### User-entered/selected

Examples:

- date;
- party size;
- selected slot;
- names;
- email;
- confirmation email;
- phone;
- explicit newsletter preference.

### Transient UI state

Examples:

- loading flags;
- touched/validation state;
- lookup sequence/version;
- stale-response guard;
- pending submission;
- open error message;
- ambiguous outcome state.

Specify invalidation rules.

At minimum define what becomes stale or clears when:

- date changes;
- party size changes;
- selected slot becomes unavailable;
- email/name identity changes;
- newsletter lookup completes late;
- reservation submission fails ordinarily;
- reservation submission outcome is unknown;
- reservation succeeds.

Avoid duplicating server-derived truth in multiple client state locations.

---

## Part S — request/staleness model

Without selecting a React data library, define UX-safe async behavior for:

- OP-01 context;
- OP-02 availability;
- OP-03 newsletter status;
- OP-04 preference update;
- OP-05 reservation submit.

For each, specify:

- trigger;
- whether concurrent duplicate requests should be suppressed;
- stale-response condition;
- whether later user edits invalidate prior response;
- retry affordance;
- whether mutation controls are disabled while pending.

Do not pick React Query, Redux, Axios, fetch wrappers, or other tooling here unless already approved.

Prompt 21 owns toolchain/state-library choices.

---

## Part T — responsive/mobile UX

Design the reservation/newsletter experience for:

- smartphone;
- tablet;
- desktop.

Address:

- order of controls;
- date and party controls;
- slot list/grid;
- customer form stacking;
- email/confirmation placement;
- newsletter preference placement;
- submit control;
- error placement;
- confirmation;
- touch targets;
- virtual-keyboard implications;
- avoiding horizontal scrolling.

Do not invent exact breakpoints; Prompt 21 owns final responsive-system values.

---

## Part U — accessibility UX

Design at interaction level:

- semantic form structure;
- explicit labels;
- required/optional indication;
- instructions before controls where needed;
- field-level error association;
- error-summary behavior if recommended;
- focus movement after invalid submit;
- loading announcements;
- availability refresh announcements;
- selected-slot semantics;
- unavailable-slot semantics;
- newsletter lookup announcements;
- mutation-success/error announcements;
- ambiguous-outcome alert semantics;
- confirmation focus/announcement;
- disabled submit explanation;
- keyboard-only completion;
- color-independent state communication.

Do not claim a WCAG conformance level unless required and verified later.

---

## Part V — UX copy inventory

Identify user-facing copy that must eventually exist, without writing excessive marketing content.

At minimum propose concise wording categories for:

- context load failure;
- availability load failure;
- fully booked day;
- selected slot no longer available;
- validation summary;
- email mismatch;
- customer identity mismatch;
- newsletter status unavailable;
- reservation submission pending;
- reservation success;
- reservation ordinary failure;
- reservation outcome unknown;
- newsletter update success/failure.

Mark wording as:

`PROPOSED UX COPY — PRESENTATIONAL`

unless the exact wording is fixed by the SRS/API.

Do not change API error semantics through friendlier copy.

---

## Part W — UX traceability

Create a detailed UX traceability matrix covering at minimum:

- SRS FR-06 through FR-09;
- FR-15 through FR-18 where applicable;
- applicable frontend NFRs;
- rubric working-form/UI/UX/integration expectations;
- approved PRA customer/newsletter/reservation rules;
- OP-01 through OP-05;
- approved REACT-01 component boundaries.

For each requirement show:

- UX component/interaction;
- server authority;
- client usability responsibility;
- deferred implementation/test prompt.

Do not claim implementation compliance.

---

## Decisions that belong to Prompt 21, not Prompt 20

Do not finalize:

- React framework/build tool;
- router package;
- network library;
- state-management/data-fetching library;
- CSS architecture;
- exact typography;
- color palette;
- spacing scale;
- exact breakpoints;
- exact browser/device test matrix;
- component test framework;
- E2E framework;
- package versions;
- build scripts.

You may identify UX-driven needs those decisions must support.

---

## Required artifact

Create one proposed design artifact using the established React design-document convention.

Preferred filename:

`docs/react-design/Cafe_Fausse_REACT02_Reservation_and_Newsletter_UX.md`

The artifact must include:

1. baseline and approval state;
2. authoritative sources reviewed;
3. reservation interaction model;
4. OP-01 initial context UX;
5. date UX;
6. party-size UX;
7. availability request UX;
8. slot presentation/selection UX;
9. customer form UX;
10. email-confirmation UX;
11. newsletter-in-reservation UX;
12. standalone newsletter UX;
13. reservation submission eligibility;
14. reservation submission behavior;
15. public API error-to-UX mapping;
16. ambiguous/outcome-unknown UX;
17. fully booked/availability-change UX;
18. confirmation UX;
19. state ownership/invalidation model;
20. async/staleness model;
21. responsive/mobile UX;
22. accessibility UX;
23. proposed UX copy inventory;
24. requirements/API/REACT-01 traceability;
25. decisions deferred to Prompt 21;
26. unresolved ambiguities;
27. approval status.

Mark it clearly:

`PROPOSED — NOT YET APPROVED`

Do not modify the approved REACT-01 artifact.

---

## No-code rule

This prompt is strictly design-only.

Do not:

- create/modify `package.json`;
- initialize Vite, CRA, Next.js, or another framework;
- install packages;
- create JSX/TSX;
- create CSS;
- create JavaScript/TypeScript;
- create frontend runtime files;
- create frontend tests;
- create `frontend/TestInstructions.md` yet;
- connect React to Flask;
- modify backend Flask code;
- modify PostgreSQL;
- modify API contracts;
- modify approved REACT-01;
- modify gallery assets;
- begin Prompt 21;
- begin Prompt 22+ implementation.

---

## Git restrictions

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

Preserve the real Git index and repository history.

---

## Verification

Before stopping:

1. confirm only the proposed REACT-02 artifact changed;
2. confirm approved REACT-01 remains unchanged;
3. confirm no backend/database/frontend implementation file changed;
4. confirm no package/dependency file changed;
5. run `git diff --check`;
6. verify the real Git index remains unchanged;
7. verify no arbitrary time entry exists anywhere in the proposed UX;
8. verify all legitimate API-returned slots remain visible;
9. verify unavailable slots are nonselectable;
10. verify React never calculates authoritative slot/business/capacity/allocation rules;
11. verify user newsletter edits cannot be overwritten by stale async lookup;
12. verify outcome-unknown is distinct from ordinary failure;
13. verify no invented endpoint or business rule was introduced;
14. verify Prompt 21 toolchain/visual/test-system decisions were not pulled forward.

---

## Completion response

Lead with:

- `READY FOR REACT-02 DESIGN REVIEW`, or
- `BLOCKED`.

Report:

- baseline full HEAD;
- Phase 0 result;
- exact changed path;
- reservation-flow summary;
- date/party/availability UX summary;
- slot-selection summary;
- customer-form/email-confirmation summary;
- newsletter synchronization summary;
- standalone newsletter UX summary;
- submission/error/outcome-unknown summary;
- confirmation summary;
- state/staleness model summary;
- responsive/accessibility summary;
- error-to-UX mapping summary;
- requirements traceability summary;
- any ambiguity requiring approval;
- `git diff --check` result;
- Git-index preservation;
- confirmation no implementation/code/test/toolchain work began.

Do not declare REACT-02 approved.

Stop for independent review and explicit approval before Prompt 21.
