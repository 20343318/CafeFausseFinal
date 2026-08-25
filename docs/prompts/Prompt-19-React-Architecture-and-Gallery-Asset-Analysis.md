# Prompt 19 — React Architecture and Gallery Asset Analysis

## Objective

Begin Phase D — React/JSX after the approved API-09 / Hard Gate 2 checkpoint.

This prompt is the revised and resequenced version of the original Game Plan Prompt 18:

> Analyze gallery assets and design React architecture.

Do not design the detailed reservation UX in this prompt. That work is now deferred to Prompt 20.

Do not generate React/JSX/CSS/JavaScript/TypeScript code yet.

The goal is to:

1. inspect the actual supplied Café Fausse gallery assets;
2. define a flexible, maintainable React page/component architecture for the complete site;
3. design the Gallery so the current asset set can start small and additional approved images can be added later without restructuring the application;
4. map the proposed frontend architecture to the authoritative SRS, rubric, approved supplemental requirements, and frozen Flask API boundary;
5. stop for independent review and explicit approval before reservation UX design begins.

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
- Flask Hard Gate 2.

The current approved repository checkpoint is:

`73dbd68` — `API-09 and Hard Gate 2 approved`

Verify the full commit hash during Phase 0 rather than relying only on the abbreviated value.

React design work is now authorized.

React implementation is not yet authorized.

## Resequenced React prompt plan

The remaining React sequence is intentionally shifted by one prompt number relative to the original Game Plan because Prompt 18 was used for the completed API-09 / Hard Gate 2 verification stage.

Use this sequence going forward:

- Prompt 19 — original Prompt 18 scope: gallery asset analysis + React architecture;
- Prompt 20 — original Prompt 19 scope: reservation UX design;
- Prompt 21 — original Prompt 20 scope: complete UI/UX + React test strategy;
- Prompt 22 — original Prompt 21 scope: static React application + Gallery;
- Prompt 23 — original Prompt 22 scope: reservation/newsletter forms;
- Prompt 24 — original Prompt 23 scope: connect React to Flask;
- Prompt 25 — original Prompt 24 scope: React verification gate;
- subsequent original prompts increment by one unless later explicitly revised.

Do not collapse future prompts together unless explicitly authorized.

## Authoritative sources and precedence

Use the current committed repository as the authoritative implementation state.

Read and apply, in this order:

1. repository-root `AGENTS.md` and any applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum v2.2.1;
5. approved least-to-most implementation roadmap;
6. approved API-01 Backend Operation Inventory;
7. approved API-02 Flask REST Contract;
8. approved API-03 Flask Architecture, Configuration, and Test Strategy;
9. approved API-09 / Hard Gate 2 verification report;
10. current committed backend implementation only where needed to confirm the frozen React-facing API boundary;
11. the actual supplied Café Fausse gallery/image assets;
12. this Prompt 19.

Do not reconstruct requirements from old chat text.

Do not contradict, weaken, replace, or reinterpret an explicit SRS, rubric, approved addendum, or frozen API requirement.

If a proposed frontend decision would introduce a new business rule rather than a presentational/architectural choice, identify the gap and stop for approval.

## Fixed SRS/rubric frontend baseline

The architecture must support at minimum:

- React with JSX;
- five required pages: Home, Menu, Reservations, About Us, Gallery;
- intuitive shared navigation;
- responsive desktop/tablet/smartphone design;
- major-browser compatibility considerations: Chrome, Firefox, Safari, Edge;
- CSS using Flexbox and/or Grid;
- clean, modern, visually appealing, consistent restaurant branding;
- reservation functionality in later prompts;
- newsletter signup functionality in later prompts;
- Gallery using high-resolution supplied imagery;
- Gallery lightbox behavior;
- awards;
- positive customer reviews;
- user-friendly loading/error/success presentation when later connected to Flask.

This prompt establishes architecture only. It must not claim these later functional requirements are already implemented.

## Current gallery asset direction

The initial Gallery asset set may contain only a small number of images.

The current project direction is:

- start with the supplied assets available now;
- do not assume the current image count is final;
- design the Gallery architecture so additional approved images can be added later with minimal or no structural change;
- avoid hard-coding assumptions such as an exact permanent image count;
- avoid layout logic that only works for one fixed number of assets;
- keep image metadata organized so filenames, alt text, category/grouping, captions, and presentation choices can be extended later;
- do not create a database-backed CMS or unnecessary enterprise asset-management system;
- do not invent an image-upload/admin feature.

A simple data-driven static asset model is appropriate unless an approved source requires something else.

The current image count is not a business rule.


## Approved temporary/source asset location for Prompt 19

Because the `frontend` directory is currently empty and no React framework/build-tool convention has yet been approved, use this framework-neutral repository location for the supplied Gallery source assets:

`frontend/assets/gallery/`

Place the current four Gallery images directly in that directory before executing Prompt 19.

Rationale:

- it keeps frontend-owned assets inside the frontend layer;
- it does not prematurely assume Vite, CRA, Next.js, or a specific `public/` versus `src/assets/` convention;
- it gives Codex a stable location from which to inspect the actual files during this design-only prompt;
- it supports adding more approved images later without changing the architecture;
- it avoids treating the current four-image set as permanent.

For Prompt 19, this path is the **source asset location**, not a final runtime/build-tool decision.

A later approved React implementation prompt may retain or relocate/copy these assets into the build-tool-specific runtime location once the frontend toolchain is explicitly approved. Any such implementation-time relocation must preserve Git history where practical and must not change image meaning or metadata silently.

Do not create additional asset-management infrastructure in Prompt 19.

## Phase 0 — mandatory read-only repository verification

Before producing the design artifact:

1. Record current branch, full HEAD commit hash, recent relevant Git history, and working-tree status.
2. Confirm the worktree is clean, HEAD matches the approved API-09 / Hard Gate 2 checkpoint, and Hard Gate 2 is recorded as approved/frozen.
3. Inspect the repository for:
   - the existing `frontend` directory;
   - any existing React/package/build artifacts;
   - existing frontend design documents;
   - `frontend/assets/gallery/`;
   - the actual supplied restaurant images placed directly in `frontend/assets/gallery/`;
   - any existing naming convention for frontend design artifacts.
4. Inventory the frozen React-facing Flask operations at a high level so page/component boundaries do not invent incompatible responsibilities.
5. Confirm the SRS/rubric frontend page requirements.
6. Confirm the actual gallery assets are available to this Codex workspace before doing image-specific analysis.

If the worktree is unexpectedly dirty, the baseline is wrong, approval is missing, or an authoritative source materially conflicts with another approved source, stop and report the issue.

## Gallery asset prerequisite

The original Game Plan explicitly requires inspection of the actual supplied gallery files before finalizing Gallery architecture.

For Prompt 19, first look specifically in `frontend/assets/gallery/`.

If the actual image files are unavailable there or otherwise unavailable to Codex:

- complete only the architecture work that does not depend on visual inspection;
- mark Gallery asset analysis as `BLOCKED — ACTUAL ASSETS NOT AVAILABLE`;
- identify the exact missing asset dependency;
- do not invent image-specific categories, crops, quality judgments, or alt text;
- do not declare Prompt 19 ready for approval.

If the files are available, inspect all of them directly.

## Part A — inspect and inventory the supplied assets

For each supplied image, record as appropriate:

- exact filename;
- pixel dimensions if available;
- landscape / portrait / square orientation;
- apparent visual subject/content;
- image quality/resolution suitability for Home hero, Home supporting imagery, Gallery thumbnail, Gallery lightbox, Menu/food visual, ambiance/interior/exterior presentation;
- reasonable crop behavior;
- whether `cover` or `contain` behavior is preferable;
- whether aggressive cropping would damage the subject;
- recommended Gallery category/group if categories are warranted;
- concise descriptive accessible alt text;
- whether a caption would add useful meaning.

Do not infer facts that are not visible in the image.

Do not fabricate restaurant history, dish names, people identities, awards, locations, or events from image appearance alone.

If the current image set is too small to justify categories, say so and recommend a flat Gallery initially while preserving a data model that can support categories later.

## Part B — flexible Gallery architecture

Design a Gallery architecture that works with the initial asset set and scales gracefully when more approved images are added later.

Address:

- asset metadata structure;
- where static assets should live conceptually;
- how page/components consume asset metadata;
- avoiding repeated hard-coded image markup;
- ordering;
- optional categories/grouping;
- responsive grid behavior;
- odd/even asset counts;
- 1–4 images;
- larger future asset collections;
- thumbnail aspect-ratio handling;
- consistent thumbnail sizing without distortion;
- lightbox opening/closing;
- Escape behavior;
- keyboard navigation;
- previous/next navigation if appropriate;
- first/last-image behavior;
- focus management and focus return;
- captions and alt text;
- mobile/touch behavior;
- design-level performance considerations such as appropriate image sizing/lazy loading.

Do not introduce a CMS, image-upload UI, database persistence for gallery metadata, admin tooling, external image hosting, or an image-generation workflow.

The design should make adding another static approved image primarily a metadata/asset addition rather than a component rewrite.

## Part C — complete React page architecture

Design the page/component architecture for the entire site.

### Home

Map architecture to SRS-required content including Café Fausse identity, address, phone, hours, imagery, and navigation.

Identify candidate supplied image(s) for Home use based only on actual asset inspection.

Distinguish fixed SRS content from dynamic/configurable information that may later come from the frozen Flask API.

Do not hard-code configurable reservation/business values into React architecture when Flask is the approved authority.

### Menu

Design component boundaries around the SRS menu: categories, menu item representation, name, description, price, responsive grouping/layout.

Do not add, remove, rename, or reinterpret SRS menu items.

### Reservations

Define only the page/component boundary, not the detailed reservation UX.

At this stage identify likely architectural pieces such as the Reservations page shell, reservation-context boundary, availability/slot-selection area, customer/reservation form area, and confirmation/error presentation boundary.

Do not specify detailed date-control behavior, slot-state rules, retry behavior, or a full reservation state machine here. Those belong to Prompt 20.

Do not permit an architecture that would require arbitrary free-text time entry.

### About Us

Map component/page structure to the SRS-required restaurant history, founder biographies, mission, dining experience, food quality, and locally sourced ingredient messaging.

Do not invent factual copy not present in the approved requirements.

### Gallery

Use the asset analysis and flexible Gallery architecture above.

Include architectural places for the Gallery page, image grid, image card/thumbnail, lightbox/modal, optional category/filter structure only if justified, awards section, and positive customer reviews section.

Awards and reviews are required page content but are not necessarily image categories.

Do not invent specific awards or customer quotations unless authoritative project content already supplies them.

If the SRS requires the existence of awards/reviews but does not provide actual text/details, identify that as a content gap rather than fabricate content.

### Newsletter signup

Define the reusable component boundary and likely placement options.

Do not implement or fully design interaction behavior yet.

Map it to the frozen newsletter-related API responsibilities at a high level.

Do not assume it must appear on every page unless the requirements say so.

### Shared application shell

Define reasonable architecture for app/root, routing/page switching, header, navigation, main content, footer if appropriate, shared layout/container components, reusable presentational components, loading/error/message primitives where useful, mobile navigation boundary, and lightbox/modal boundary.

Avoid unnecessary abstraction for an academic project.

## Part D — proposed component hierarchy

Produce a concise proposed component tree distinguishing application shell, page-level components, shared reusable components, Gallery-specific components, future reservation-specific boundaries, and future newsletter-specific boundaries.

Do not create implementation files.

Do not prematurely split trivial one-use markup into excessive components.

Explain why each reusable component boundary is justified.

## Part E — frontend data/content ownership map

For each major page/component, identify whether its content is expected to come from fixed SRS/project content, supplied static image assets, frozen Flask API, local presentational metadata, or future user input.

At minimum distinguish restaurant identity/contact content, menu content, gallery asset metadata, reservation configuration/context, reservation availability, reservation submission, and newsletter status/preference.

This is an ownership map only. Do not design the detailed API interaction workflow yet.

## Part F — responsive architecture

At architecture level, address desktop, tablet, smartphone, shared navigation adaptation, page content width, Gallery grid adaptation, Menu layout adaptation, image scaling, avoiding horizontal scrolling, touch-friendly future controls, and lightbox behavior across viewport sizes.

Detailed final styling belongs to Prompt 21.

Do not select arbitrary pixel-perfect breakpoints as a new fixed requirement unless an approved source already defines them. Present recommended breakpoint strategy as a presentational design choice.

## Part G — accessibility architecture

At architecture level address semantic landmarks, heading structure, navigation labeling, keyboard operation, visible focus, image alt text, lightbox focus management, Escape/close affordance, screen-reader-friendly modal semantics, color-independent interaction states, touch-target considerations, and reduced-motion awareness for any later animation.

Do not claim WCAG certification or a compliance level unless explicitly required and verified.

## Part H — React/API boundary

Map the site architecture to the frozen Flask operations at a high level.

At minimum identify which future UI areas depend on OP-01 current reservation context, OP-02 daily provisional availability, OP-03 customer newsletter-status query, OP-04 newsletter-preference mutation, and OP-05 reservation creation/reconstruction.

Also identify OP-06/OP-07 as operational health endpoints rather than normal customer-page content.

React must not become authoritative for reservation interval rules, reservation duration rules, booking-window rules, same-day lead time, capacity, table allocation, overlap protection, customer matching, retry identity, or booking transaction semantics.

Detailed reservation UX/API state behavior belongs to Prompt 20.

## Part I — requirements traceability

Create a concise architecture-level traceability matrix.

Map each proposed page/component area to applicable SRS functional requirements, applicable frontend nonfunctional requirements, rubric criteria, approved supplemental requirements where applicable, and frozen Flask operations where applicable.

Clearly distinguish architecture addressed now, detailed UX deferred to Prompt 20, detailed site-wide UI/test design deferred to Prompt 21, and implementation deferred to Prompt 22+.

Do not claim implementation compliance.

## Content gaps

Explicitly identify any content required by SRS/rubric that is not actually supplied in authoritative sources.

Examples may include specific award names/details, actual customer review quotations, missing imagery categories, or missing textual content.

Do not fill those gaps by invention.

Classify each gap as implementation-independent content gap, future presentational decision, or business-rule ambiguity requiring approval.

Only business-rule ambiguities require stopping for user approval.

## Required design artifact

Create one proposed design artifact.

Preferred filename:

`docs/react-design/Cafe_Fausse_REACT01_Architecture_and_Gallery_Asset_Analysis.md`

If the repository already has an established location/naming convention for unapproved React design artifacts, use that convention instead and report the exact path.

The artifact must include:

1. baseline/approval state;
2. authoritative sources reviewed;
3. asset availability and inventory;
4. Gallery asset analysis;
5. flexible Gallery architecture;
6. full page architecture;
7. proposed component hierarchy;
8. content/data ownership map;
9. responsive architecture;
10. accessibility architecture;
11. high-level React/API boundary;
12. requirements traceability;
13. content gaps;
14. decisions deferred to Prompt 20/21;
15. unresolved blockers, if any;
16. approval status.

Mark it clearly as `PROPOSED — NOT YET APPROVED`.

## No-code rule

This prompt is strictly design-only.

Do not create or modify package.json; initialize a React framework; install npm packages; create React source, JSX, CSS, JavaScript/TypeScript, frontend tests, or build tooling; connect to Flask; modify Flask or PostgreSQL; modify frozen API contracts; modify approved backend/database design artifacts; design the detailed reservation UX assigned to Prompt 20; design the complete React test strategy assigned to Prompt 21; or implement the static site assigned to Prompt 22.

If framework/toolchain selection is not already approved, defer it to Prompt 21 rather than silently choosing it.

## Git restrictions

Do not stage, commit, push, reset, clean, stash, rebase, merge, cherry-pick, switch branches, create/delete tags, or modify pull requests.

Preserve the real Git index and repository history.

## Verification

Before stopping:

1. confirm the only intentional pre-existing Prompt-19 inputs are the committed Gallery assets under `frontend/assets/gallery/`, and that Codex itself changed only the proposed React design artifact;
2. confirm no backend/database/frontend implementation file changed;
3. confirm no package/dependency file changed;
4. confirm no approved design artifact changed;
5. run `git diff --check`;
6. verify the real Git index remains unchanged;
7. verify every analyzed image fact came from the actual supplied asset;
8. verify Gallery architecture does not assume a permanent fixed asset count;
9. verify architecture supports future additional approved static assets without component redesign;
10. verify detailed reservation UX was not pulled forward from Prompt 20;
11. verify no business rule was invented;
12. verify all content gaps are explicitly identified.

## Completion response

Lead with `READY FOR REACT-01 DESIGN REVIEW` or `BLOCKED`.

Report:

- baseline full HEAD;
- Phase 0 result;
- exact changed path;
- actual gallery asset count inspected;
- asset filenames;
- Gallery analysis summary;
- flexible Gallery extensibility summary;
- page architecture summary;
- component hierarchy summary;
- content/data ownership summary;
- responsive/accessibility summary;
- high-level frozen API boundary summary;
- requirements traceability summary;
- content gaps;
- any ambiguity requiring approval;
- `git diff --check` result;
- Git-index preservation;
- confirmation no React/frontend code was generated;
- confirmation Prompt 20 reservation UX work was not started.

Do not declare React-01 approved.

Stop for independent review and explicit approval before Prompt 20.
