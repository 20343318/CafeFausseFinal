# Prompt 22 — Implement Static React Application and Gallery

## Objective

Begin the first React/JSX implementation increment for Café Fausse.

This prompt is the **revised and resequenced version of the original Game Plan Prompt 21**:

> Implement static React application.

Implement only the approved static React application foundation, required static page content, shared application shell/navigation, responsive visual system, Gallery automatic discovery, and Gallery lightbox.

Also establish the approved frontend build/test tooling and the first repeatable/restartable `frontend/TestInstructions.md`.

This increment must implement the approved and frozen REACT-01, REACT-02, and REACT-03 decisions without pulling forward Prompt 23 reservation/newsletter form-state implementation or Prompt 24 live Flask integration.

Use a least-to-most implementation strategy:

`toolchain → shell/routes → shared/static content → Gallery discovery → Gallery grid → lightbox → tests → manual/repeatable verification`

Stop for independent review and explicit approval before Prompt 23.

---

## Current authorization state

The following are approved, committed, pushed, and frozen:

- SRS and rubric baseline;
- Project Requirements Addendum v2.2.1;
- PostgreSQL DB-01 through DB-07;
- PostgreSQL Hard Gate 1;
- frozen PostgreSQL contract for Flask;
- Flask/API increments through API-09;
- API08-RC-01 and API08-RC-02;
- Flask Hard Gate 2;
- REACT-01 / UI-01 architecture and Gallery design;
- REACT-02 / UI-02 reservation/newsletter UX design;
- REACT-03 / UI-03 visual system and React test strategy.

Prompt 22 is authorized.

Prompt 23 is **not** authorized.

Verify the current full repository HEAD during Phase 0. Do not assume any abbreviated hash from an earlier prompt is still current.

---

## Newly resolved Prompt-22 content prerequisites

Two REACT-03 content gaps were resolved before this prompt.

### Founder biographies

The user approved the following deliberately fact-limited biographies because they use only facts established by the SRS and do not invent credentials, personal histories, education, nationality, employment history, quotations, or individual accomplishments.

Use exactly this approved factual substance. Minor punctuation/layout changes are allowed, but do not add biographical facts.

**Chef Antonio Rossi**

> Chef Antonio Rossi co-founded Café Fausse in 2010 with restaurateur Maria Lopez. At Café Fausse, he is part of a restaurant founded around the combination of traditional Italian flavors and modern culinary innovation, with a commitment to excellent food and an unforgettable dining experience.

**Maria Lopez**

> Restaurateur Maria Lopez co-founded Café Fausse in 2010 with Chef Antonio Rossi. At Café Fausse, she is part of a restaurant committed to quality, creativity, locally sourced ingredients, and providing guests with an unforgettable dining experience.

These satisfy the approved FR-11 treatment without inventing unsupported facts.

### Behind-the-scenes Gallery imagery

An approved AI-generated behind-the-scenes asset has been added and committed:

`frontend/assets/gallery/gallery-behind-the-scenes.webp`

It visibly depicts chefs plating food in a professional restaurant kitchen and is approved for the FR-12 behind-the-scenes category.

The current Gallery asset set is expected to contain at least:

- `home-cafe-fausse.webp`
- `gallery-cafe-interior.webp`
- `gallery-ribeye-steak.webp`
- `gallery-special-event.webp`
- `gallery-behind-the-scenes.webp`

Do not treat five as a permanent/fixed Gallery count. Automatic discovery remains authoritative.

The generated behind-the-scenes source asset is 1536×1024. Do not resize/crop the committed source file merely to match another asset.

### Remaining provenance gap

Asset provenance/licensing documentation remains an explicitly tracked content-governance item due before final delivery/INT-08.

It **does not block Prompt 22 implementation or completion**.

Do not invent provenance for the original supplied assets.

For the newly generated behind-the-scenes image, it is acceptable later to record that it was AI-generated during this Café Fausse project, but do not begin final provenance documentation unless an existing approved artifact specifically requires an incremental note.

---

## Resequenced React implementation plan

Current sequence:

- Prompt 19 — REACT-01 / UI-01 architecture + Gallery design — approved/frozen;
- Prompt 20 — REACT-02 / UI-02 reservation/newsletter UX — approved/frozen;
- Prompt 21 — REACT-03 / UI-03 visual system + React test strategy — approved/frozen;
- **Prompt 22 — REACT-04 / UI-04 static React application + Gallery — this prompt;**
- Prompt 23 — reservation/newsletter UI with mocked API behavior;
- Prompt 24 — connect React to frozen Flask API;
- Prompt 25 — React verification gate.

Do not collapse Prompt 22 with Prompt 23.

---

## Authoritative sources and precedence

Use the current committed repository as the authoritative implementation state.

Read and apply, in this order:

1. repository-root `AGENTS.md` and any applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum v2.2.1;
5. approved least-to-most implementation roadmap;
6. approved/frozen PostgreSQL and Flask contract artifacts where frontend authority boundaries matter;
7. approved/frozen API-01 through API-09 artifacts as needed;
8. approved/frozen REACT-01 architecture and Gallery asset-analysis artifact;
9. approved/frozen REACT-02 reservation/newsletter UX artifact;
10. approved/frozen REACT-03 visual-system and React-test-strategy artifact;
11. current committed Gallery assets under `frontend/assets/gallery/`;
12. this Prompt 22.

Do not reconstruct requirements from old chat text.

Do not contradict, weaken, replace, or reinterpret explicit SRS/rubric requirements or approved/frozen project decisions.

If implementation exposes a genuine conflict or a business-rule gap, stop and report it instead of silently inventing a rule.

---

# Phase 0 — mandatory read-only baseline verification

Before changing files:

1. Record:
   - current branch;
   - full HEAD;
   - upstream relation;
   - recent relevant Git history;
   - `git status`;
   - Git-index state.

2. Confirm:
   - worktree is clean;
   - REACT-01, REACT-02, and REACT-03 are `APPROVED AND FROZEN`;
   - Prompt 22 is the next authorized increment;
   - `gallery-behind-the-scenes.webp` is committed under `frontend/assets/gallery/`;
   - no unapproved React implementation already exists.

3. Inventory the actual files in:
   - `frontend/`;
   - `frontend/assets/gallery/`;
   - applicable React design docs.

4. Inspect all current Gallery assets sufficiently to confirm:
   - filename;
   - image dimensions;
   - supported format;
   - no asset is silently missing from the committed source folder.

5. Verify the approved founder biography wording is not contradicted by another authoritative source.

6. Confirm the remaining asset-provenance gap does not block this increment.

If the baseline is not clean, a frozen artifact is missing, or repository contents conflict with this prompt, stop and report `BLOCKED`.

---

# Part A — establish the approved frontend toolchain

Initialize the smallest approved Vite + React application under `frontend/`.

Use **plain JavaScript + JSX**, not TypeScript.

## Required runtime/tooling decisions

Implement the frozen REACT-03 choices:

- React `19.2.8`;
- React DOM `19.2.8`;
- React Router declarative mode using `react-router@8.3.0`;
- Vite `8.2.2`;
- `@vitejs/plugin-react@6.1.0`;
- ordinary imported CSS;
- native React state/hooks;
- no Axios;
- no Redux/Zustand;
- no TanStack Query;
- no Tailwind;
- no Sass;
- no CSS-in-JS;
- no UI/component framework;
- no date-picker library;
- no lightbox library;
- no icon library.

Use project-owned semantic HTML, React, CSS, and small inline SVGs only where justified.

## Approved test tooling

Install/configure exactly:

- `vitest@4.1.11`
- `@vitest/coverage-v8@4.1.11`
- `jsdom@30.0.1`
- `@testing-library/react@16.3.2`
- `@testing-library/dom@10.4.1`
- `@testing-library/user-event@14.6.6`
- `@testing-library/jest-dom@7.0.1`
- `msw@2.15.0`

Prompt 22 may install these packages and create/update:

- `frontend/package.json`;
- the generated lockfile;
- Vite configuration;
- Vitest configuration/setup;
- normal frontend source/test files.

Dependency ranges must not float across clean installations. Use exact versions or a lockfile/manifest arrangement that reproduces the approved versions.

Before proceeding past dependency setup:

1. verify npm dependency resolution succeeds;
2. record actual Node and npm versions;
3. verify the installed Node version satisfies all selected package engine requirements;
4. inspect npm audit output.

If the exact approved versions have an actual peer/engine incompatibility or a material security issue that prevents reasonable use, **stop for design reconciliation**. Do not silently substitute package versions.

Do not install Playwright/Cypress in this increment.

---

# Part B — required source organization

Implement a clear, modest structure consistent with frozen REACT-01/03.

Use the smallest useful set of directories such as:

- application/root;
- layout/navigation;
- pages;
- Gallery components;
- static content/data;
- Gallery discovery/metadata;
- styles;
- tests/test utilities.

Do not create enterprise-style layers or excessive one-use components.

Preserve the approved conceptual boundaries:

- `App`
- `AppShell` / site layout
- `SiteHeader`
- primary/mobile navigation
- route outlet/main landmark
- `HomePage`
- `MenuPage`
- `ReservationsPage`
- `AboutPage`
- `GalleryPage`
- `GalleryGrid`
- `GalleryItem`
- one shared `GalleryLightbox`
- `NewsletterPreferences` boundary reserved for Prompt 23
- reservation feature boundaries reserved for Prompt 23

Component names may differ slightly when implementation conventions require it, but the architecture and responsibility boundaries must remain recognizable and traceable.

---

# Part C — implement the five addressable routes

Implement all five required React routes:

- `/` — Home
- `/menu` — Menu
- `/reservations` — Reservations
- `/about` — About Us
- `/gallery` — Gallery

Also implement the approved technical not-found route.

Use React Router declarative/browser-history behavior as frozen in REACT-03.

## Direct-route behavior

The app must support normal client-side navigation.

Document the static-host/server requirement that unknown non-asset SPA paths must rewrite to `index.html`.

Do not modify Flask deployment/routing in this increment merely to implement the future production rewrite.

Tests may verify route rendering in-memory; manual local preview should verify supported direct navigation as far as the local Vite/preview environment permits.

---

# Part D — shared application shell and navigation

Implement:

- skip link as the first focusable control;
- semantic header;
- brand/Home link;
- canonical five-link navigation model;
- responsive desktop navigation;
- approved mobile navigation;
- one `main` landmark;
- footer;
- active-route semantics;
- document title updates;
- managed route-change focus;
- not-found presentation.

## Desktop/mobile navigation behavior

Preserve REACT-03:

- desktop navigation is inline at/above the approved breakpoint;
- mobile menu is controlled by a real button;
- button exposes `aria-expanded` and `aria-controls`;
- opening moves focus to the first navigation link;
- Tab/Shift+Tab follow normal document order; mobile nav is not a modal/focus trap;
- Escape closes and returns focus to trigger;
- selecting a route closes the menu;
- route change manages focus to the new page heading/main region without duplicate announcements;
- pointer outside may close only as a convenience;
- resizing into desktop state clears mobile-expanded state;
- current route has `aria-current="page"`.

Use one canonical navigation-link data model.

---

# Part E — implement the frozen visual system

Implement REACT-03's approved design tokens exactly unless a browser-valid syntax correction is needed.

At minimum preserve:

- warm ivory page;
- near-white content surfaces;
- espresso primary text;
- wine primary actions;
- teal focus;
- approved semantic success/warning/error colors;
- approved disabled/selected/unavailable states;
- Georgia/system heading stack;
- system UI body stack;
- approved type scale;
- approved 4px-based spacing scale;
- approved radii/elevation;
- approved 44×44 CSS px minimum interactive targets;
- approved reduced-motion behavior.

CSS organization must follow the frozen ordinary-CSS architecture:

- tokens;
- base/reset;
- layout;
- shared components;
- page-specific styles as justified.

Use CSS Grid for macro page sections, Menu categories, Gallery, and later slot/form layouts where applicable.

Use Flexbox for navigation rows, action groups, and inline alignment.

Avoid:

- IDs for styling;
- deep specificity chains;
- unnecessary `!important`;
- JavaScript device detection for layout.

Implement mobile-first breakpoints at:

- base below 480px;
- 480px;
- 768px;
- 1024px;
- 1440px.

Representative manual viewports:

- 320×568;
- 390×844;
- 768×1024;
- 1280×800;
- 1440×900.

---

# Part F — Home page static implementation

Implement the approved Home layout and all static SRS content appropriate to this increment.

Required:

- Café Fausse name prominently;
- address:
  `1234 Culinary Ave, Suite 100, Washington, DC 20002`
- phone:
  `(202) 555-4567`
- SRS hours displayed as static informational content:
  - Monday–Saturday: 5:00 PM–11:00 PM
  - Sunday: 5:00 PM–9:00 PM
- primary CTA to Reservations;
- secondary CTA to Menu;
- approved hero treatment using `home-cafe-fausse.webp`;
- story/mission teaser using only SRS facts;
- supporting imagery only from approved assets;
- awards/reviews teaser if consistent with frozen design;
- a Home newsletter section anchor/placement consistent with REACT-03.

## Important Prompt-22 boundary

Do **not** implement the functional `NewsletterPreferences` form/state machine in this increment.

Prompt 23 owns newsletter form fields, validation, OP-03/OP-04 mocked interactions, mutation states, and error/outcome-unknown behavior.

For Prompt 22:

- render the approved Home newsletter section location and static introductory copy/heading;
- provide a clearly reserved component boundary/placeholder that is **not a fake working form**;
- do not create a form that appears functional but silently does nothing;
- footer/header links may target the Home newsletter section.

Likewise, do not call OP-01 in Prompt 22. The static SRS hours may be shown now as fixed site information, but live/current reservation-context behavior belongs to Prompt 24 once the API connection is authorized.

Do not present static SRS hours as a substitute for server-authoritative booking eligibility.

---

# Part G — Menu page

Implement the complete exact SRS menu.

Do not alter names, descriptions, or prices.

## Starters

- Bruschetta — Fresh tomatoes, basil, olive oil, and toasted baguette slices — $8.50
- Caesar Salad — Crisp romaine with homemade Caesar dressing — $9.00

## Main Courses

- Grilled Salmon — Served with lemon butter sauce and seasonal vegetables — $22.00
- Ribeye Steak — 12 oz prime cut with garlic mashed potatoes — $28.00
- Vegetable Risotto — Creamy Arborio rice with wild mushrooms — $18.00

## Desserts

- Tiramisu — Classic Italian dessert with mascarpone — $7.50
- Cheesecake — Creamy cheesecake with berry compote — $7.00

## Beverages

- Red Wine (Glass) — A selection of Italian reds — $10.00
- White Wine (Glass) — Crisp and refreshing — $9.00
- Craft Beer — Local artisan brews — $6.00
- Espresso — Strong and aromatic — $3.00

Use the approved responsive Menu layout.

`gallery-ribeye-steak.webp` may be used as the approved supporting Main Courses image, but it must never replace required menu text.

---

# Part H — Reservations page static boundary only

Implement the `/reservations` route so all five required routes/pages exist.

This increment must **not** implement the reservation form/state machine.

Render only the static reservation page shell appropriate before Prompt 23, such as:

- H1;
- concise explanatory copy;
- semantic container where the frozen reservation feature will be mounted;
- user-friendly statement that reservation controls are not yet part of this implementation increment only if such development-only wording is not exposed as final customer copy.

Prefer a production-appropriate static introductory page plus an internal empty/reserved feature boundary rather than visible “coming soon” developer language.

Do not implement:

- date input;
- party input;
- slot controls;
- customer form;
- email confirmation;
- newsletter checkbox;
- availability mocks;
- reservation submission;
- success/error states;
- API calls.

Prompt 23 owns those behaviors.

Do not permit arbitrary time entry.

---

# Part I — About Us page

Implement:

1. the SRS history exactly in substance:
   - Café Fausse was founded in 2010 by Chef Antonio Rossi and restaurateur Maria Lopez;
   - it blends traditional Italian flavors with modern culinary innovation;
   - its mission is to provide an unforgettable dining experience reflecting quality and creativity;

2. the two approved founder biographies from this prompt;

3. commitment content using only approved SRS facts:
   - unforgettable dining;
   - excellent food;
   - locally sourced ingredients;
   - quality;
   - creativity.

Do not invent:

- education;
- birthplace/nationality;
- career history;
- awards;
- credentials;
- years of experience;
- personal quotes;
- culinary philosophy attributed individually to either founder;
- responsibilities not established by authoritative sources.

Use the approved responsive two-founder-card treatment where appropriate.

---

# Part J — Gallery automatic discovery

Implement the frozen automatic Gallery discovery architecture.

Canonical folder remains:

`frontend/assets/gallery/`

Do not copy those source images into a second manually maintained runtime registry.

## Supported Version-1 formats

Exactly:

- `.webp`
- `.jpg`
- `.jpeg`
- `.png`
- `.avif`

Match extensions case-insensitively, including mixed case.

SVG and GIF are not supported Gallery-photo inputs.

## Vite discovery

Use a literal relative `import.meta.glob` pattern that actually resolves from the implemented discovery-module location to `frontend/assets/gallery/`.

Use the frozen Vite URL import strategy:

- eager URL resolution;
- `query: '?url'`;
- `import: 'default'`;
- `caseSensitive: false`.

Do not blindly copy an example relative path from REACT-03 if the implemented module location requires a different path. The resolved target folder must be correct.

## Inclusion invariant

Every valid supported image physically present in `frontend/assets/gallery/` must be discovered and displayed automatically.

Adding an ordinary future supported image must not require:

- Gallery component change;
- route change;
- layout change;
- required metadata;
- manual registry inclusion.

---

# Part K — optional Gallery metadata

Implement optional presentation metadata only as enrichment.

Approved metadata may include:

- `alt`;
- optional `caption`;
- optional numeric `order`;
- optional `objectPosition`.

Metadata must **not** control inclusion.

Use an optional metadata object/module keyed by exact filename.

Unknown/stale metadata entries should be detected by an automated development/test check rather than silently controlling inclusion.

## Current curated metadata

Where REACT-01 already approved/recommended curated alt text for the original assets, preserve that content rather than inventing new facts.

For the new approved asset, use factual concise alt text such as:

`Chefs plating dishes in a warmly lit professional kitchen.`

This describes only visible content.

Do not identify any depicted person as Chef Antonio Rossi, Maria Lopez, or any real/fictional named individual.

Do not invent event names, dish identities, staff names, dates, or restaurant operational claims from image appearance.

Current files may all receive curated metadata, but tests must prove metadata remains optional and that future no-metadata assets are still included.

---

# Part L — exact frozen Gallery ordering

Implement and test the complete frozen algorithm:

1. All metadata-backed images appear before every image without metadata.
2. Within the metadata-backed group:
   1. entries with explicit numeric `order` appear first, sorted by `order`;
   2. duplicate explicit `order` values use normalized filename and then exact filename as deterministic tie-breakers;
   3. metadata-backed entries without explicit `order` follow all explicitly ordered metadata-backed entries;
   4. those unordered metadata-backed entries sort by normalized filename and then exact filename.
3. The no-metadata group follows all metadata-backed images.
4. The no-metadata group sorts by normalized filename and then exact filename.
5. Filesystem enumeration order is never authoritative.

Reject duplicate normalized filenames deterministically.

Do not introduce a manual asset-count assumption.

---

# Part M — Gallery grid

Render all discovered supported assets.

Preserve the approved design:

- flat Version-1 Gallery;
- no category filter required;
- CSS Grid;
- responsive/content-count-agnostic columns;
- 4:3 thumbnail treatment;
- `object-fit: cover`;
- optional `objectPosition`;
- captions only when metadata provides them;
- hover and focus parity;
- no information conveyed only by hover;
- loading strategy appropriate to initial visibility;
- below-fold Gallery images use native lazy loading where appropriate;
- asynchronous decode where appropriate;
- source order equals logical/keyboard order.

The current behind-the-scenes asset is part of the discovered set and must appear automatically.

Awards and reviews are content sections, not image categories.

---

# Part N — awards and reviews

Render the exact SRS content.

## Awards

- Culinary Excellence Award — 2022
- Restaurant of the Year — 2023
- Best Fine Dining Experience — Foodie Magazine, 2023

## Reviews

- “Exceptional ambiance and unforgettable flavors.” — Gourmet Review
- “A must-visit restaurant for food enthusiasts.” — The Daily Bite

Use semantic quotation markup where appropriate.

Do not add additional awards, publications, star ratings, customer names, or testimonial text.

---

# Part O — Gallery lightbox

Implement one project-owned shared `GalleryLightbox`.

Do not install a lightbox dependency.

Required behavior:

- semantic thumbnail activation;
- one modal instance controlled by selected image/index;
- backdrop;
- accessible dialog naming/description;
- focus moves to Close on open;
- focus trapped within open dialog;
- background inert/unavailable to assistive technology while open;
- page scroll lock without persistent layout shift;
- clearly labelled Close control;
- Escape closes;
- closing restores focus to exact originating thumbnail;
- previous/next visible controls for collections with >1 image;
- Left/Right Arrow navigation;
- bounded behavior, **no wrap**:
  - Previous disabled/omitted at first;
  - Next disabled/omitted at last;
- one-image behavior omits previous/next;
- optional position indicator such as “2 of 5”;
- enlarged image uses containment, not thumbnail crop;
- caption rendered when present;
- image-load failure keeps close/navigation controls usable and presents a plain failure message;
- responsive/mobile-safe control layout;
- no swipe-only functionality;
- reduced motion respected.

Do not identify people in the generated image.

---

# Part P — image performance and layout stability

Implement proportionate static-image behavior.

- Home hero is eager/high priority only because it is above the fold.
- Do not lazy-load the hero.
- Gallery images below the initial viewport use native lazy loading.
- Use intrinsic width/height or stable aspect-ratio boxes to reduce layout shift.
- Preserve correct aspect ratio in lightbox.
- Do not generate an unnecessary image-processing pipeline merely because one could be built.
- Current source assets are sufficiently small in count to reuse their bundled URLs for lightbox unless measurement later justifies variants.
- Do not mutate committed source images.

NFR-1 performance compliance is **not** declared here; measurement remains later verification work.

---

# Part Q — accessibility implementation

At minimum implement/test:

- semantic landmarks;
- one meaningful H1 per route;
- logical heading hierarchy;
- skip link;
- semantic links/buttons;
- `aria-current` active route;
- visible focus;
- keyboard-complete navigation;
- responsive mobile navigation keyboard behavior;
- meaningful image alt text;
- decorative images use empty alt only when truly decorative;
- Gallery buttons have accessible names;
- modal semantics/focus trap/Escape/focus return;
- non-color state indication;
- touch targets at least 44×44 CSS px;
- reduced-motion behavior;
- 200%/400% reflow considerations;
- no horizontal page scrolling at approved representative widths.

Do not claim WCAG certification.

---

# Part R — tests required in this increment

Implement meaningful behavior-oriented tests using the approved Vitest + Testing Library stack.

Do not rely on large DOM snapshots.

## Toolchain/build tests

Verify:

- clean dependency install from lockfile;
- test runner works;
- production build succeeds;
- no unexpected asset-discovery build failure.

## Shell/routes/navigation

Test:

- all five required routes render;
- canonical links have correct destinations;
- active-route `aria-current`;
- shared shell persists;
- skip link;
- route title/H1 focus behavior;
- direct route rendering in router test harness;
- not-found page;
- mobile menu initial state;
- open;
- first-link focus;
- normal Tab behavior;
- Escape close/focus return;
- route-selection close;
- outside close if implemented;
- resize-to-desktop reset.

## Static content

Test:

- exact Home identity/contact/hours;
- exact Menu categories/items/descriptions/prices;
- SRS About history/mission facts;
- approved founder biographies without extra invented facts;
- commitment content;
- exact awards;
- exact reviews;
- Reservations static route exists without reservation form controls;
- newsletter section exists without fake functional form.

## Gallery discovery

Test:

- every supported glob result is included;
- current committed asset set includes `gallery-behind-the-scenes.webp`;
- adding a synthetic supported file to the injected discovery result automatically adds it without component/registry changes;
- lower-, upper-, and mixed-case supported extensions;
- unsupported extensions excluded;
- duplicate normalized name detection;
- metadata enriches but does not control inclusion;
- orphan/stale metadata diagnostic;
- filename-derived alt fallback;
- current curated alt text;
- complete deterministic ordering algorithm;
- independence from input/filesystem enumeration order.

Do not modify committed assets merely to test discovery. Use injected glob/discovery fixtures/seams.

## Gallery/lightbox

Test:

- all discovered images render;
- open;
- Close;
- Escape;
- backdrop only if intentionally supported;
- previous/next;
- bounded first/last behavior;
- arrow keys;
- no wrap;
- one-image behavior;
- caption;
- load failure;
- focus entry;
- focus trap;
- focus return;
- background inertness;
- scroll restoration;
- accessible name/description;
- reduced-motion state where reasonably testable.

## Accessibility assertions

Use role/name/label/state/focus-based assertions.

Do not add a new automated accessibility dependency unless compatibility has been independently approved. REACT-03 made that optional, not required.

---

# Part S — coverage

Configure V8 coverage for:

- statements;
- branches;
- functions;
- lines.

Exclude generated/build/config files where appropriate.

Do not impose an arbitrary 100% threshold.

Coverage is diagnostic, but critical branches implemented in this prompt must have direct tests, especially:

- navigation;
- Gallery inclusion/order;
- fallback alt;
- lightbox bounded navigation;
- focus behavior;
- image failure behavior.

Report achieved coverage.

---

# Part T — `frontend/TestInstructions.md`

Create:

`frontend/TestInstructions.md`

This file is mandatory for the frontend layer and must be usable by a repository contributor without reconstructing hidden Codex context.

Document the exact commands applicable to this Prompt-22 implementation.

At minimum include:

1. prerequisites;
2. exact Node/npm versions actually used;
3. install dependencies from the lockfile;
4. start development server;
5. stop development server cleanly;
6. build production bundle;
7. run focused shell/navigation tests;
8. run focused Gallery/lightbox tests;
9. run all frontend tests;
10. run coverage;
11. preview production build;
12. manually verify all five routes;
13. verify direct navigation/refresh behavior and document SPA rewrite limitations;
14. verify responsive widths:
    - 320×568
    - 390×844
    - 768×1024
    - 1280×800
    - 1440×900
15. verify keyboard navigation;
16. verify skip link/focus;
17. verify mobile menu behavior;
18. verify Gallery automatic discovery;
19. verify adding a **temporary test-owned supported image fixture** causes discovery/display without editing a manual registry;
20. verify metadata-less fallback behavior;
21. verify Gallery lightbox;
22. verify reduced-motion behavior;
23. verify zoom/reflow/no horizontal page scrolling;
24. record local browser checks:
    - Chrome;
    - Edge;
    - Firefox;
25. explicitly state Safari remains unverified unless actually tested in a Safari-capable environment;
26. interruption/restart guidance;
27. final cleanup.

## Final cleanup requirement

The **last test step** must clean up everything created specifically by testing/manual verification.

It must:

- stop test-owned dev/preview processes;
- remove temporary test asset fixtures;
- remove generated coverage;
- remove disposable reports/screenshots unless intentionally retained;
- remove test-created caches/temp files where safe;
- remove any other test-owned resources.

It must **not** remove:

- committed Gallery source assets;
- `package.json`;
- committed lockfile;
- committed source;
- required configuration;
- user-owned files.

Finish by verifying the repository/worktree state expected by the test procedure.

The instructions must be repeatable/restartable after success, failure, or Ctrl+C.

---

# Part U — manual browser verification during Prompt 22

Run what is realistically available locally and report exactly what was run.

At minimum, if installed/available:

- Chrome on Windows;
- Edge on Windows;
- Firefox on Windows.

Do not claim Safari was tested on Windows.

If Safari is unavailable, record it as deferred to the approved Prompt-25 Safari-capable verification checkpoint.

For each locally verified browser, perform a practical smoke check of:

- five routes;
- navigation;
- responsive menu;
- Home;
- Menu;
- About;
- Gallery;
- lightbox;
- keyboard focus;
- no obvious horizontal overflow.

Use browser automation only if already available without introducing an unapproved framework; otherwise manual evidence is sufficient for this increment.

---

# Part V — static content traceability

Create/update an implementation report artifact using the established project convention.

Preferred path:

`docs/react-implementation/Cafe_Fausse_REACT04_Static_Application_and_Gallery_Implementation.md`

If the repository already has a different approved implementation-report convention, use it and report the exact path.

The report must include:

1. baseline full HEAD;
2. implementation scope;
3. exact file inventory;
4. toolchain and exact installed versions;
5. Node/npm versions;
6. dependency/audit result;
7. app architecture;
8. five-route implementation;
9. shell/navigation;
10. visual/CSS implementation;
11. Home implementation;
12. Menu implementation;
13. Reservations static boundary;
14. About/founder content;
15. Gallery discovery;
16. Gallery metadata and ordering;
17. new behind-the-scenes asset handling;
18. Gallery lightbox;
19. accessibility implementation;
20. automated tests;
21. coverage;
22. build result;
23. manual browser/responsive verification actually performed;
24. `frontend/TestInstructions.md` status;
25. requirements/design traceability;
26. deferred Prompt-23 behavior;
27. remaining provenance gap;
28. approval status.

Mark the report:

`PROPOSED — NOT YET APPROVED`

Do not mark REACT-04 approved.

---

# Part W — explicit scope exclusions

Do not implement Prompt-23 form/state behavior.

Specifically, do not yet implement:

- live reservation context;
- reservation date control;
- party-size control;
- availability retrieval/mocks for user interaction;
- slot-selection UI;
- customer-information form;
- email-confirmation form logic;
- reservation newsletter checkbox synchronization;
- standalone newsletter form fields/state;
- newsletter status lookup;
- newsletter preference mutation;
- reservation submit;
- confirmation;
- API error mapping;
- outcome-unknown recovery;
- MSW reservation/newsletter user-flow fixtures beyond any minimal test infrastructure that does not expose those features.

Do not implement Prompt-24 live integration:

- no live Flask API calls;
- no PostgreSQL interaction;
- no backend changes;
- no database changes;
- no Flask changes;
- no API contract changes.

Do not modify frozen REACT-01/02/03.

Do not modify committed Gallery source images.

---

# Part X — Git restrictions

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

`npm install`/dependency setup and implementation changes are authorized working-tree changes, but leave all resulting project files unstaged for independent review.

Preserve the real Git index.

---

# Part Y — verification gate before stopping

Before reporting completion:

1. Run the full Prompt-22 frontend automated suite.
2. Run coverage.
3. Run production build.
4. Run `git diff --check`.
5. Verify the real Git index remains unchanged.
6. Verify no backend/database/API files changed.
7. Verify REACT-01/02/03 remain byte-for-byte unchanged.
8. Verify every five required route exists.
9. Verify no functional reservation/newsletter form was pulled forward.
10. Verify the Gallery automatically includes every current supported asset.
11. Verify `gallery-behind-the-scenes.webp` appears through automatic discovery.
12. Verify Gallery inclusion does not depend on metadata.
13. Verify the complete frozen ordering algorithm.
14. Verify case-insensitive supported extension behavior.
15. Verify no permanent fixed asset-count assumption.
16. Verify lightbox accessibility and bounded navigation tests.
17. Verify exact SRS menu content.
18. Verify About content contains only SRS facts plus the approved fact-limited biographies.
19. Verify no invented founder facts.
20. Verify exact awards/reviews.
21. Verify `frontend/TestInstructions.md` exists and its final step cleans up all test-owned resources.
22. Execute enough of `frontend/TestInstructions.md` to prove it is restartable/repeatable for the implemented increment.
23. Confirm final cleanup removes temporary test resources while preserving committed/project files.
24. Report actual locally tested browsers honestly.
25. Confirm asset provenance/licensing remains tracked for final delivery/INT-08 and did not become an implementation blocker.

If a substantive requirement/design conflict appears, stop rather than silently rewriting a frozen decision.

---

# Completion response

Lead with one of:

- `READY FOR REACT-04 IMPLEMENTATION REVIEW`
- `BLOCKED`

Report concisely but completely:

- baseline full HEAD;
- branch/upstream/worktree Phase-0 result;
- exact changed/created paths;
- installed production dependencies and versions;
- installed development dependencies and versions;
- Node/npm versions;
- npm audit/dependency-resolution result;
- five-route implementation summary;
- shared shell/navigation summary;
- visual/responsive implementation summary;
- Home summary;
- Menu summary;
- Reservations static-boundary summary;
- About/founder-biography summary;
- Gallery asset count discovered at runtime/build and filenames;
- explicit confirmation `gallery-behind-the-scenes.webp` was discovered automatically;
- Gallery ordering/metadata/fallback summary;
- lightbox behavior summary;
- accessibility summary;
- test counts/results;
- coverage result;
- production-build result;
- manual browser/responsive checks actually completed;
- `frontend/TestInstructions.md` verification/cleanup result;
- implementation report path;
- deferred Prompt-23/24 work;
- remaining asset-provenance gap/checkpoint;
- `git diff --check`;
- Git-index preservation;
- confirmation nothing staged/committed/pushed.

Do not declare REACT-04 approved.

Stop for independent review and explicit approval before Prompt 23.
