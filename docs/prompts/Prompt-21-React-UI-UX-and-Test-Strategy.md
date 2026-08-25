# Prompt 21 — Complete UI/UX Visual System and React Test Strategy

## Objective

Continue Phase D — React/JSX after the approved REACT-02 / UI-02 reservation and newsletter UX checkpoint.

This prompt is the **revised and resequenced version of the original Game Plan Prompt 20**:

> Design UI/UX and React test strategy.

This increment is **design-only**.

Do not generate React, JSX, CSS, JavaScript, TypeScript, package configuration, build tooling, frontend tests, or live API integration yet.

The goal is to approve the smallest complete visual system, responsive layout strategy, browser/device matrix, frontend toolchain decisions needed for the next implementation increment, and a repeatable React unit/integration/manual test strategy that can be implemented incrementally from Prompt 22 onward.

The result must be polished enough to target the rubric's highest UI/UX score without introducing unnecessary framework, component-library, state-management, or testing complexity.

Stop for independent review and explicit approval before Prompt 22.

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
- REACT-01 / UI-01 architecture and Gallery asset analysis;
- REACT-02 / UI-02 reservation and newsletter UX design.

Verify the current full repository HEAD during Phase 0.

React visual/test design decisions are now authorized.

React implementation is **not** yet authorized.

---

## Resequenced React prompt plan

The approved/current sequence is:

- Prompt 19 — REACT-01 / UI-01: Gallery asset analysis + React architecture — approved/frozen;
- Prompt 20 — REACT-02 / UI-02: reservation/newsletter/accessibility UX — approved/frozen;
- **Prompt 21 — REACT-03 / UI-03: complete UI/UX visual system + React test strategy — this prompt;**
- Prompt 22 — original Prompt 21 scope: static React application + Gallery;
- Prompt 23 — original Prompt 22 scope: reservation/newsletter UI;
- Prompt 24 — original Prompt 23 scope: connect React to Flask;
- Prompt 25 — original Prompt 24 scope: React verification gate;
- subsequent original prompts remain incremented by one unless later explicitly revised.

Do not collapse Prompt 21 with Prompt 22.

---

## Authoritative sources and precedence

Use the current committed repository as the authoritative implementation state.

Read and apply, in this order:

1. repository-root `AGENTS.md` and any applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum v2.2.1;
5. approved least-to-most implementation roadmap, especially UI-03;
6. approved PostgreSQL-to-Flask contract where frontend authority boundaries matter;
7. approved API-01 Backend Operation Inventory;
8. approved API-02 Flask REST Contract;
9. approved API-03 Flask Architecture, Configuration, and Test Strategy;
10. approved API-09 / Hard Gate 2 verification report;
11. approved/frozen REACT-01 artifact;
12. approved/frozen REACT-02 artifact;
13. current committed backend implementation only where needed to verify a frozen public API fact;
14. current gallery assets under `frontend/assets/gallery/`;
15. this Prompt 21.

Do not reconstruct requirements from old chat text.

Do not contradict, weaken, replace, or reinterpret an explicit SRS, rubric, approved addendum, frozen API requirement, REACT-01 decision, or REACT-02 UX decision.

If a proposed decision would create a new business rule rather than a technical/presentational/test choice, identify the gap and stop for approval.

---

## Original Game Plan / roadmap scope that must be preserved

The original Game Plan requires this increment to complete UI/UX design before coding and define:

- page layouts;
- responsive behavior;
- shared navigation;
- styling strategy using Flexbox/Grid;
- accessibility considerations;
- forms;
- Gallery behavior;
- API interaction states;
- React test plan for:
  - navigation;
  - reservation controls;
  - slot rendering;
  - validation;
  - loading/success/error states;
  - newsletter signup;
  - Gallery lightbox.

The approved roadmap UI-03 further requires:

- brand/color/type/spacing decisions;
- responsive breakpoint/device matrix;
- Flexbox/Grid layout plan;
- interaction/focus styles;
- browser test matrix;
- React unit/integration test plan;
- planned tests for shared controls, responsive navigation states, accessibility attributes, and visual-state classes;
- mocked page/form flow tests across representative desktop, tablet, and mobile viewports;
- manual design review for contrast, typography, spacing, focus visibility, touch targets, and representative browsers;
- no unnecessary component framework or state infrastructure.

This prompt must satisfy that scope without implementation.

---

## Fixed design constraints

Preserve at minimum:

- React with JSX;
- five required pages:
  - Home;
  - Menu;
  - Reservations;
  - About Us;
  - Gallery;
- responsive desktop/tablet/smartphone design;
- Chrome, Firefox, Safari, and Edge compatibility considerations;
- CSS using Flexbox and/or Grid;
- clean, modern, visually appealing, consistent restaurant branding;
- accessible navigation, forms, feedback, and lightbox interactions;
- approved REACT-01 page/component architecture;
- approved REACT-01 automatic Gallery discovery and optional-metadata rules;
- approved REACT-02 progressive reservation/newsletter interaction model;
- Flask/PostgreSQL authority for business rules.

Do not redesign frozen interaction semantics merely for visual preference.

---

## Phase 0 — mandatory read-only verification

Before creating the design artifact:

1. record:
   - current branch;
   - full HEAD;
   - recent relevant Git history;
   - worktree status;

2. confirm:
   - worktree is clean;
   - REACT-01 is committed and `APPROVED AND FROZEN`;
   - REACT-02 is committed and `APPROVED AND FROZEN`;
   - Prompt 21 is the next authorized increment;
   - no React implementation or build tooling exists unless introduced by a separately approved checkpoint;

3. inspect:
   - `frontend/`;
   - `frontend/assets/gallery/`;
   - current approved React design documents;
   - any existing package/toolchain artifacts;
   - any existing frontend testing convention;

4. verify the three REACT-01 tracked content gaps remain recorded:
   - behind-the-scenes imagery;
   - founder biography content;
   - asset provenance/licensing;

5. inventory all decisions explicitly deferred by REACT-01 and REACT-02 to Prompt 21.

If the baseline is not clean or the approved artifacts are missing/inconsistent, stop and report the blocker.

---

## Part A — visual design direction

Define a cohesive visual identity suitable for Café Fausse and the SRS/rubric.

Specify:

- overall visual mood;
- brand personality;
- color system;
- typography system;
- spacing system;
- corner radius/border philosophy;
- elevation/shadow use;
- image treatment;
- surface/background hierarchy;
- icon usage policy;
- animation/motion philosophy.

### Color system

Define semantic design tokens rather than scattered page-specific values.

At minimum specify tokens for:

- page background;
- primary surface;
- secondary/accent surface;
- primary text;
- secondary text;
- border/divider;
- primary action;
- primary action hover/active;
- focus indicator;
- success;
- warning;
- error;
- disabled;
- selected;
- unavailable.

For each proposed color value:

- provide a concrete CSS-compatible value;
- state its intended use;
- verify or calculate sufficient contrast for its intended text/background pair where text is involved;
- do not claim a WCAG certification level unless the measured pairs support the claim and the project requires it.

Avoid a palette so large that implementation becomes inconsistent.

### Typography

Choose a minimal type system.

Define:

- primary font family strategy;
- fallback stack;
- heading hierarchy;
- body size/line height;
- labels/helper/error text;
- navigation;
- buttons;
- menu prices;
- large hero treatment.

Prefer system/web-safe fonts unless there is a justified, low-risk reason to require an external font dependency.

If proposing an external font, explicitly identify:
- dependency/network/privacy/caching implications;
- fallback;
- whether local bundling or hosted loading is preferred;
- why the visual benefit justifies the complexity.

Do not require paid/proprietary fonts.

### Spacing

Define a small reusable spacing scale and max-content widths.

Use consistent tokens rather than one-off values.

---

## Part B — responsive layout system

Approve concrete responsive breakpoints/viewports for implementation and testing.

Use the smallest useful set.

At minimum address:

- narrow smartphone;
- larger smartphone;
- tablet;
- desktop;
- wide desktop.

For each, define:

- representative viewport width;
- major layout behavior;
- navigation mode;
- content container behavior;
- Gallery columns;
- Menu layout;
- reservation form layout;
- slot grid/list behavior.

Do not create device-specific business logic.

Prefer content-driven breakpoints, but Prompt 21 must now approve exact implementation/test values.

---

## Part C — page layout specifications

Define the visual/layout structure for each required page while preserving REACT-01 content ownership.

### Home

Specify:

- header/hero composition;
- hero image treatment;
- primary CTAs;
- restaurant contact/hours placement;
- supporting imagery;
- section order;
- newsletter placement.

Resolve the REACT-01/02 deferred newsletter placement.

Choose one primary full newsletter form placement and avoid unnecessary duplicate forms.

### Menu

Specify:

- page header;
- category presentation;
- menu item rows/cards;
- price alignment;
- responsive behavior;
- optional ribeye supporting image treatment;
- readability and scanning.

Do not change SRS menu content.

### Reservations

Specify visual presentation of the approved REACT-02 flow:

- context/policy region;
- date/party controls;
- Check/Update availability action;
- slot grid;
- customer fields;
- newsletter status/preference;
- review summary;
- submit;
- alerts/errors;
- outcome-unknown panel;
- confirmation view.

Do not alter the frozen REACT-02 state transitions or API semantics.

### About Us

Specify:

- story/mission layout;
- founders region;
- commitments;
- imagery usage if supported by approved assets;
- responsive behavior.

Do not invent missing founder biography facts.

### Gallery

Specify:

- responsive grid;
- thumbnail aspect ratio;
- spacing;
- hover/focus treatment;
- lightbox visual treatment;
- controls;
- captions;
- awards;
- reviews;
- larger future collections.

Preserve:
- automatic discovery of all supported folder assets;
- metadata-backed images first;
- no-metadata images after them;
- deterministic ordering;
- filename-derived alt fallback;
- flat Gallery initially;
- no CMS/admin/database gallery.

---

## Part D — shared navigation and application shell

Finalize presentational/interaction details for:

- header;
- brand/home link;
- desktop navigation;
- mobile navigation;
- active route;
- skip link;
- main landmark;
- footer;
- contact information;
- newsletter link/form placement;
- not-found route behavior if approved.

Define exact mobile navigation interaction:

- menu trigger;
- expanded/collapsed semantics;
- keyboard behavior;
- Escape behavior;
- focus movement/return;
- route-selection close behavior;
- outside-click behavior if any.

Keep a single canonical navigation-link model.

---

## Part E — form visual system

Define reusable form presentation for reservation and newsletter flows.

Specify:

- labels;
- required/optional markers;
- helper text;
- inputs;
- textareas if any;
- checkbox;
- date input/control;
- numeric party-size control;
- slot controls;
- fieldsets/legends;
- read-only review values;
- disabled state;
- invalid state;
- success state;
- loading state.

Preserve REACT-02 semantics.

Do not make optional middle initial or phone visually appear required.

Do not use placeholder text as the sole label.

---

## Part F — buttons, links, and interactive states

Define a minimal reusable control hierarchy:

- primary button;
- secondary button;
- text/link action;
- destructive action only if required by approved scope;
- disabled state;
- loading state;
- focus-visible state;
- pressed/selected state where applicable.

No cancellation/deletion control is currently required for reservations.

Specify keyboard and pointer interaction expectations.

---

## Part G — loading, success, warning, error, and outcome-unknown presentation

Define reusable status presentation primitives for:

- inline field error;
- form error summary;
- informational status;
- loading/busy;
- success;
- warning;
- retryable read failure;
- known mutation failure;
- outcome unknown;
- confirmation unavailable.

Visually and semantically distinguish:

- ordinary failure;
- known reservation existence with confirmation unavailable;
- mutation outcome unknown.

Do not use color alone.

Preserve the approved REACT-02 API-to-UX semantics.

---

## Part H — Gallery lightbox final interaction design

Finalize the visual and responsive treatment for the approved REACT-01 lightbox.

Specify:

- backdrop;
- modal size;
- image containment;
- close control;
- previous/next controls;
- bounded first/last behavior;
- caption;
- position indicator if used;
- focus styling;
- keyboard controls;
- Escape;
- focus trap;
- focus return;
- background inertness;
- mobile/touch behavior;
- reduced motion;
- one-image behavior;
- larger future collections.

Do not select a third-party lightbox package unless the technical analysis in Part K proves it is necessary.

Default preference: implement the small required lightbox behavior with project-owned React/CSS if feasible.

---

## Part I — accessibility design specification

Create a concrete accessibility implementation checklist for Prompt 22+.

At minimum specify:

- semantic landmarks;
- heading hierarchy;
- skip link;
- link/button semantics;
- navigation current-state semantics;
- keyboard access;
- visible focus;
- form labels/descriptions/errors;
- fieldset/legend use;
- live/status/alert regions;
- modal semantics;
- focus trap and return;
- unavailable-slot semantics;
- selected-slot semantics;
- disabled-submit explanation;
- zoom/reflow;
- reduced motion;
- touch targets;
- text contrast;
- non-color status indicators.

Define measurable acceptance checks where practical.

Do not claim certification.

---

## Part J — image delivery and asset strategy

Finalize the frontend design strategy for the existing source assets under:

`frontend/assets/gallery/`

Preserve the source-asset location until an approved toolchain-specific runtime decision is made in this prompt.

Determine:

- final runtime/import convention;
- automatic folder discovery approach;
- supported image formats for Version 1;
- deterministic discovery behavior;
- optional metadata location/shape at design level;
- handling of metadata-backed versus no-metadata images;
- filename alt fallback;
- responsive image sizing;
- lazy loading;
- hero eager loading;
- intrinsic dimensions/layout shift;
- thumbnails versus full/lightbox source strategy;
- corrupt/unsupported file behavior;
- build/test coverage for automatic discovery.

The current four WebP files must work.

Do not require a manual registry for inclusion.

Do not require a CMS, database, admin upload, or external image host.

If the proposed toolchain cannot support the approved automatic-discovery rule cleanly, stop and identify the conflict rather than weaken REACT-01.

---

## Part K — frontend toolchain decision

Prompt 21 is the point at which the minimum React toolchain may be approved because Prompt 22 needs an executable frontend.

Recommend the smallest maintainable toolchain that satisfies the SRS/rubric and the approved React design.

Decide and justify:

### React project/build tooling

Choose one appropriate approach.

Prefer a current, simple React setup suitable for an academic SPA rather than a framework whose server-side features are unnecessary.

Address:

- JSX support;
- development server;
- production build;
- static assets;
- automatic Gallery discovery;
- environment/config handling;
- browser support;
- test integration.

### Routing

Decide whether a routing library is justified.

The site needs five addressable routes, refresh/direct navigation behavior, active navigation, and not-found behavior.

Prefer a well-supported small routing solution if implementing those manually would add more risk.

### HTTP/API layer

Decide whether native `fetch` is sufficient.

Do not add Axios or another HTTP client unless there is a concrete need.

### State management

Decide whether React local state/hooks are sufficient.

Do not add Redux/Zustand/etc. unless REACT-02's approved state model genuinely requires it.

### Component/UI library

Default to **no general-purpose component framework** unless there is a compelling reason.

The rubric expects excellent custom UI/UX and Flexbox/Grid, and the roadmap explicitly requires avoiding unnecessary component framework/state infrastructure.

### Icon library

Decide whether a small icon dependency is justified or whether inline/simple icons are preferable.

Do not add dependencies merely for decoration.

### Dependency policy

For each proposed production dependency, record:

- package;
- purpose;
- why platform/native React is insufficient;
- whether it is required or optional.

Keep the production dependency count intentionally small.

---

## Part L — CSS architecture

Choose a clear CSS strategy suitable for this project.

Address:

- global reset/base styles;
- design tokens/custom properties;
- shared component styles;
- page styles;
- responsive rules;
- utility classes if any;
- naming convention;
- focus/error/status styles;
- avoiding specificity conflicts.

Prefer ordinary maintainable CSS unless another approach is clearly justified.

The SRS/rubric requires CSS using Flexbox and/or Grid. Make explicit where each will be used.

Do not introduce Tailwind, CSS-in-JS, Sass, or a CSS framework without explicit justification.

---

## Part M — React testing stack decision

Prompt 21 must define the exact frontend testing strategy but must **not install or write tests yet**.

Choose the smallest practical testing stack.

At minimum decide:

- test runner;
- React component testing library;
- user interaction helper;
- DOM assertion support;
- API mocking strategy;
- browser/E2E strategy if warranted;
- coverage approach.

Prefer tests that exercise behavior from the user's perspective rather than implementation details.

If a full E2E browser framework is deferred until integration, state that clearly and define what will cover browser behavior before then.

---

## Part N — unit/component test plan

Define restartable unit/component tests for implementation increments.

At minimum cover:

### Shared shell/navigation

- all required navigation destinations;
- active-route state;
- mobile menu open/close;
- keyboard navigation;
- Escape;
- focus return;
- skip link;
- not-found behavior if approved;
- current-hours mocked success/failure presentation.

### Static pages

- SRS-required Home content;
- exact Menu categories/items/prices;
- About content;
- awards;
- reviews;
- Gallery asset discovery;
- metadata/no-metadata ordering;
- filename-alt fallback;
- responsive/presentational state hooks where behavior matters.

### Gallery lightbox

- open;
- close;
- close button;
- Escape;
- previous/next;
- first/last bounded behavior;
- one-image behavior;
- focus entry;
- focus trap;
- focus return;
- accessible name;
- caption/alt handling.

### Reservation

Plan tests for all approved REACT-02 behaviors, including:

- OP-01 loading/success/failure;
- date bounds;
- party bounds;
- explicit availability request;
- all returned slots visible;
- unavailable nonselectable;
- selected slot;
- stale availability responses;
- date/party invalidation;
- customer validation;
- email confirmation;
- optional middle/phone;
- newsletter dirty-choice protection;
- submit enablement;
- double-submit prevention;
- ordinary failures;
- unavailable;
- overlap;
- confirmation unavailable;
- outcome unknown;
- exact retry;
- confirmation.

### Standalone newsletter

- lookup states;
- matched/not-found;
- dirty choice;
- stale response;
- subscribe;
- unsubscribe;
- no-customer-no-change;
- known failure;
- outcome unknown;
- identical recovery.

### Accessibility assertions

- labels;
- roles;
- names;
- descriptions;
- alerts/statuses;
- disabled state;
- focus behavior.

Do not prescribe brittle snapshots for large page markup.

---

## Part O — frontend integration test plan

Define mocked integration-oriented frontend tests that exercise components/pages together without live Flask initially.

At minimum cover:

- navigation among five pages;
- shared layout persistence;
- Home context-hours success/failure;
- Gallery discovery → grid → lightbox flow;
- reservation happy path;
- fully unavailable day;
- selected slot becomes unavailable;
- identity conflict;
- newsletter-status indeterminate;
- stale newsletter lookup;
- reservation network ambiguity;
- safe identical retry/reconstruction;
- standalone newsletter subscribe/unsubscribe;
- responsive navigation states.

Use frozen API-02 examples/semantics as mock-contract sources where practical rather than inventing divergent payloads.

Do not connect to a production-like database.

Live React→Flask integration remains Prompt 24.

---

## Part P — browser/device/manual verification matrix

Define a practical manual verification matrix for:

- Chrome;
- Firefox;
- Safari;
- Edge.

Account for the development environment realistically.

If Safari cannot be run locally on the Windows development machine, explicitly distinguish:

- locally executable browser verification;
- deferred/alternate Safari verification;
- what can be validated through standards-based automated tests versus what still requires a Safari-capable environment.

Do not falsely claim Safari verification that cannot actually be run.

For representative viewport sizes include:

- narrow phone;
- larger phone;
- tablet;
- desktop;
- wide desktop.

Manual checks must include:

- navigation;
- responsive reflow;
- no horizontal scrolling;
- typography/readability;
- image crop/quality;
- Gallery lightbox;
- focus visibility;
- keyboard-only use;
- forms;
- validation;
- loading/errors;
- touch-target adequacy;
- reduced-motion behavior;
- contrast spot checks.

---

## Part Q — performance design/test strategy

Define how later React verification will evaluate relevant SRS performance expectations.

Address:

- initial page load;
- hero image;
- Gallery thumbnails;
- lazy loading;
- bundle size awareness;
- route/client rendering;
- API loading feedback;
- reservation form response perception.

Do not claim compliance now.

Define later measurement conditions and distinguish:

- frontend static/load performance;
- browser/network effects;
- backend API timing already verified separately;
- full-stack performance deferred to integration verification.

Avoid premature optimization infrastructure.

---

## Part R — `frontend/TestInstructions.md` plan

The standing project requirement is that each implementation layer has repeatable/restartable human verification in `TestInstructions.md`, and the final test step cleans up all test-created objects/files/resources.

Since this prompt is design-only, **do not create `frontend/TestInstructions.md` yet** unless an existing approved repository convention requires it.

Instead specify exactly what Prompt 22 must create in:

`frontend/TestInstructions.md`

The planned document must include, at minimum:

1. prerequisites/tool versions;
2. dependency installation;
3. development-server start/stop;
4. production build;
5. focused unit/component tests;
6. full frontend test suite;
7. coverage;
8. manual route/navigation verification;
9. responsive viewport checks;
10. keyboard/accessibility checks;
11. Gallery/lightbox checks;
12. mocked API-state checks as applicable to the implemented increment;
13. repeatability/restartability;
14. interruption/recovery where relevant;
15. final cleanup that removes all test-created:
    - temporary files;
    - generated coverage;
    - caches;
    - test reports/screenshots if not intentionally retained;
    - local temporary processes;
    - any other owned resources.

Do not remove committed source assets or ordinary dependency lockfiles as cleanup.

---

## Part S — implementation increment test mapping

Map each future prompt to the tests it must add/update.

At minimum:

### Prompt 22 — static React application + Gallery

Tests for:

- shell;
- routes;
- shared layout;
- responsive navigation;
- static content;
- Gallery discovery/order/fallback alt;
- Gallery lightbox;
- accessibility basics;
- build;
- initial `frontend/TestInstructions.md`.

### Prompt 23 — reservation/newsletter UI with mocks

Tests for:

- all REACT-02 component/state behavior;
- validation;
- availability slot rendering;
- stale responses;
- newsletter synchronization;
- errors;
- outcome unknown;
- responsive form behavior;
- update `frontend/TestInstructions.md`.

### Prompt 24 — live React→Flask integration

Tests for:

- real API integration where appropriate;
- reservation;
- availability;
- newsletter;
- error mapping;
- cross-layer behavior;
- PostgreSQL effects where required by the roadmap;
- update `frontend/TestInstructions.md`.

### Prompt 25 — React verification gate

Tests/audit for:

- all frontend SRS/rubric/PRA requirements;
- full suite;
- browser/manual matrix;
- accessibility checks;
- performance evidence;
- repeatability;
- cleanup;
- no leftover test resources.

---

## Part T — visual/test traceability

Create a traceability matrix mapping:

- SRS frontend functional requirements;
- SRS NFRs;
- rubric UI/UX/Flexbox/Grid/forms/integration expectations;
- applicable PRA requirements;
- REACT-01 architecture decisions;
- REACT-02 UX decisions;

to:

- visual-system rule;
- component/page;
- unit/component test;
- integration test;
- manual verification;
- implementation prompt.

Do not claim implementation compliance.

---

## Part U — unresolved gaps and approval decisions

Reassess the three tracked REACT-01 content gaps:

1. behind-the-scenes imagery;
2. founder biography content;
3. asset provenance/licensing.

Do not invent solutions.

For each state:

- whether it blocks Prompt 22;
- the latest prompt/checkpoint by which it must be resolved;
- what user-supplied information or asset would resolve it.

Also identify any new Prompt-21 technical decision that genuinely requires user approval before the artifact can be approved.

Do not silently convert optional technical preferences into project requirements.

---

## Required artifact

Create one proposed design artifact using the established React design convention:

`docs/react-design/Cafe_Fausse_REACT03_Visual_System_and_React_Test_Strategy.md`

It must include:

1. baseline and approval state;
2. authoritative sources reviewed;
3. visual direction;
4. color tokens and contrast evidence;
5. typography;
6. spacing/sizing;
7. responsive breakpoints/device matrix;
8. page layout specifications;
9. shared navigation/shell behavior;
10. form/control visual system;
11. status/error/outcome-unknown presentation;
12. Gallery/lightbox final visual interaction;
13. accessibility checklist;
14. image delivery/discovery strategy;
15. frontend toolchain decision;
16. production dependency decision table;
17. CSS architecture;
18. testing-stack decision;
19. unit/component test plan;
20. frontend integration test plan;
21. browser/manual matrix;
22. performance strategy;
23. `frontend/TestInstructions.md` plan;
24. future-prompt test mapping;
25. requirements/design/test traceability;
26. unresolved content/technical gaps;
27. approval status.

Mark it:

`PROPOSED — NOT YET APPROVED`

Do not modify REACT-01 or REACT-02.

---

## No-code rule

This prompt is strictly design/planning only.

Do not:

- create or modify `package.json`;
- create a lockfile;
- initialize Vite/CRA/Next.js/another frontend;
- install npm packages;
- create JSX/TSX;
- create CSS;
- create JS/TS runtime files;
- create tests;
- create `frontend/TestInstructions.md`;
- create build configuration;
- connect to Flask;
- modify Flask;
- modify PostgreSQL;
- modify API contracts;
- modify REACT-01;
- modify REACT-02;
- modify Gallery assets;
- begin Prompt 22 implementation.

Toolchain/package choices in the design artifact are **proposed design decisions**, not authorization to install them.

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

1. confirm only the proposed REACT-03 artifact changed;
2. confirm REACT-01 and REACT-02 remain unchanged;
3. confirm no frontend/backend/database implementation file changed;
4. confirm no package/lock/dependency file changed;
5. run `git diff --check`;
6. verify the real Git index remains unchanged;
7. verify every original Game Plan Prompt-20/UI-03 requirement is covered;
8. verify the proposed visual system is small and internally consistent;
9. verify the testing strategy covers navigation, reservation controls, slot rendering, validation, loading/success/error states, newsletter signup, and Gallery lightbox;
10. verify the browser/device matrix is realistic and does not falsely claim unavailable Safari execution;
11. verify automatic Gallery discovery remains compatible with the proposed toolchain;
12. verify no unnecessary production dependency is proposed;
13. verify `frontend/TestInstructions.md` planning includes repeatability/restartability and final cleanup;
14. verify no business rule was invented;
15. verify Prompt 22 implementation did not begin.

---

## Completion response

Lead with:

- `READY FOR REACT-03 DESIGN REVIEW`, or
- `BLOCKED`.

Report:

- baseline full HEAD;
- Phase 0 result;
- exact changed path;
- visual-system summary;
- color/contrast summary;
- typography/spacing summary;
- breakpoint/device summary;
- page-layout summary;
- navigation/mobile-nav summary;
- Gallery/lightbox summary;
- accessibility summary;
- image-discovery/runtime strategy;
- frontend toolchain recommendation;
- production dependencies proposed;
- CSS strategy;
- React testing stack;
- unit/component test summary;
- integration test summary;
- browser/manual matrix;
- performance strategy;
- `frontend/TestInstructions.md` plan;
- future-prompt test mapping;
- unresolved gaps requiring approval;
- `git diff --check` result;
- Git-index preservation;
- confirmation no implementation/package/test work began.

Do not declare REACT-03 approved.

Stop for independent review and explicit approval before Prompt 22.
