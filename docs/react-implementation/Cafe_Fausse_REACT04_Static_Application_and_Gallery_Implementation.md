# Café Fausse REACT-04 Static Application and Gallery Implementation

**Status:** APPROVED AND FROZEN

**Increment:** REACT-04 / UI-04 / Prompt 22

**Date:** 2026-08-24

## 1. Baseline

Implementation began from full HEAD `7e7c14cce6254742bdcc3fd5ac2b68aff57ee984` on `main`. `main`, `origin/main`, and `origin/HEAD` were aligned. The worktree and real Git index were clean. Recent history confirmed REACT-01, REACT-02, and REACT-03 as approved/frozen and Prompt 22 as the next authorized increment. No React implementation or build tooling pre-existed.

The five committed Gallery inputs were inspected visually and structurally: `home-cafe-fausse.webp` (1792×1024), `gallery-cafe-interior.webp` (1792×1024), `gallery-ribeye-steak.webp` (1024×1024), `gallery-special-event.webp` (1024×1024), and `gallery-behind-the-scenes.webp` (1536×1024). All are supported WebP files. The behind-the-scenes image visibly shows chefs plating dishes in a professional kitchen.

## 2. Scope implemented

This increment establishes the pinned Vite/React/Vitest frontend, shared responsive shell, five required routes plus not-found handling, a project-owned global error boundary, exact static SRS content, the frozen visual system, automatic Gallery discovery and metadata enrichment, and a project-owned accessible Gallery lightbox. It deliberately excludes Prompt-23 forms/mocked reservation-newsletter flows and Prompt-24 live API/database integration.

## 3. File inventory

- `.gitignore`: ignores frontend dependency/build/coverage/cache output.
- `frontend/package.json`, `frontend/package-lock.json`: exact runtime/test dependencies and repeatable scripts.
- `frontend/index.html`, `frontend/vite.config.js`: Vite entry point and Vitest/V8 coverage configuration.
- `frontend/src/main.jsx`, `frontend/src/App.jsx`, `frontend/src/AppErrorBoundary.jsx`: browser composition root, global fallback boundary, and declarative route table.
- `frontend/src/layout/`: shared shell, header/navigation, route title/focus management, and footer.
- `frontend/src/pages/`: Home, Menu, Reservations static boundary, About, Gallery, and not-found pages.
- `frontend/src/components/AwardsAndReviews.jsx`: exact shared awards/reviews presentation.
- `frontend/src/content/`: canonical navigation, restaurant/menu facts, and optional Gallery metadata.
- `frontend/src/gallery/`: Vite discovery/normalization/sorting, Gallery grid, and shared lightbox.
- `frontend/src/styles/`: frozen tokens, reset/base, layout, shared components, and page-specific ordinary CSS.
- `frontend/src/test/`: semantic route/content/navigation/error-boundary/discovery/grid/lightbox tests and setup utilities.
- `frontend/scripts/owned-vite-process.ps1`: guarded dev/preview ownership, recovery, stop, and metadata cleanup helper.
- `frontend/TestInstructions.md`: repeatable install/build/test/manual/ownership/recovery/cleanup procedure.
- This report: implementation evidence and traceability.

No backend, database, frozen design artifact, or committed Gallery source image was changed.

## 4. Toolchain and exact versions

Node `v24.15.0` and npm `11.12.1` were used. The resolved direct dependency tree exactly matches the frozen versions.

Production: `react@19.2.8`, `react-dom@19.2.8`, `react-router@8.3.0`.

Development: `vite@8.2.2`, `@vitejs/plugin-react@6.1.0`, `vitest@4.1.11`, `@vitest/coverage-v8@4.1.11`, `jsdom@30.0.1`, `@testing-library/react@16.3.2`, `@testing-library/dom@10.4.1`, `@testing-library/user-event@14.6.6`, `@testing-library/jest-dom@7.0.1`, and `msw@2.15.0`.

`npm install --ignore-scripts` resolved 178 packages with no peer or engine error. Node satisfies the selected package engine requirements. The install audit and a separate `npm audit --audit-level=low` both reported zero vulnerabilities.

## 5. Application architecture and routes

`BrowserRouter` supplies browser-history routing. `App` is the composition root for a project-owned global error boundary and one shared `AppShell` route with Home `/`, Menu `/menu`, Reservations `/reservations`, About `/about`, Gallery `/gallery`, and `*` not-found children. The boundary catches unexpected descendant render failures, exposes no internal detail, presents an accessible friendly fallback, and provides a full-page Home recovery link. It does not alter ordinary route or not-found behavior. Static hosts must rewrite unknown non-asset SPA paths to `index.html`; no Flask routing was changed.

The shell contains the first-focusable skip link, one site header/banner, canonical five-link model, responsive mobile disclosure, one main landmark/outlet, and footer. `NavLink` supplies `aria-current="page"`. Route changes update a descriptive title and focus the route H1. The technical not-found page does not redirect.

The mobile Menu is a real button with `aria-expanded`/`aria-controls`. Opening focuses Home; Tab order is normal and not trapped; Escape returns focus to the trigger; route selection and outside pointer activation close; and the 1024 px media-query transition clears expanded state. Desktop navigation is inline.

## 6. Frozen visual and responsive system

The implementation uses the exact warm ivory/surface/espresso/wine/teal and semantic status tokens, Georgia/system heading stack, system UI body stack, approved type scale, 4 px spacing scale, 4/8 px radii, soft raised shadow, minimum 44×44 px targets, and reduced-motion reset. CSS is ordinary imported CSS with low-specificity class/attribute selectors and no styling IDs or JavaScript layout detection.

CSS Grid owns page macro layouts, Menu categories, Gallery, founder cards, and awards/reviews. Flexbox owns navigation, action groups, item/price alignment, and modal controls. Mobile-first transitions exist at 480, 768, 1024, and 1440 px. Every responsive Gallery track template now uses `repeat(auto-fit, minmax(...))`: the base keeps a 10 rem minimum with a 16 px narrow gap, while breakpoint-specific calculated minimums cap the natural auto-fit result at two, three, or four columns without fixed repeat counts, asset-count assumptions, JavaScript detection, or count-specific selectors. The Home feature uses exactly two tracks at 768 px and wider. The former artificial 320 px body minimum was removed so classic scrollbars cannot create page overflow. Direct Chrome metrics recorded zero horizontal overflow at all five representative viewports.

## 7. Static page implementation

Home presents the Café Fausse identity, exact address/phone, exact SRS hours, Reservations/Menu CTAs, the approved hero, fact-limited 2010 story/mission, approved supporting imagery, awards/reviews teaser, and Home-only newsletter section boundary. It does not call OP-01 or render a fake form.

Menu renders the exact four categories and all eleven exact names, descriptions, and prices from the SRS. The supporting ribeye image never replaces text.

Reservations contains a production-appropriate heading, dining introduction, exact contact/hours, and an internal empty reservation feature boundary. It contains no date, party, time, customer, email, newsletter, availability, submit, result, or API behavior.

About renders the exact-substance 2010 history/mission, both prompt-approved fact-limited founder biographies, and only the approved commitments: unforgettable dining, excellent food, locally sourced ingredients, quality, and creativity.

Gallery renders the discovered photos followed by the three exact awards and two exact semantic attributed reviews.

## 8. Gallery discovery, metadata, and ordering

`gallery-discovery.js` uses the literal Vite pattern `../../assets/gallery/*.{webp,jpg,jpeg,png,avif}` with eager URL resolution, `query: '?url'`, `import: 'default'`, and `caseSensitive: false`. Every supported discovered file becomes a descriptor. SVG/GIF are excluded. There is no manual inclusion registry or fixed count.

Optional exact-filename metadata supplies current factual alt text, optional captions, numeric order, focal position, and intrinsic dimensions. It never determines inclusion. Missing metadata derives fact-limited sentence-style alt text from the filename. Unknown metadata is diagnosed. Duplicate normalized filenames are rejected deterministically.

The frozen metadata-first/two-group ordering algorithm is implemented completely, including explicit-order precedence, duplicate-order normalized/exact tie breakers, unordered metadata order, no-metadata order, and enumeration-order independence.

The production build discovered exactly five runtime images in frozen metadata order: `home-cafe-fausse.webp`, `gallery-cafe-interior.webp`, `gallery-ribeye-steak.webp`, `gallery-special-event.webp`, and `gallery-behind-the-scenes.webp`. The behind-the-scenes asset was included automatically through the glob; no component or registry entry controls inclusion.

## 9. Gallery grid, performance, and lightbox

The flat Grid uses content-count-agnostic, minimum-aware columns, 4:3 `object-fit: cover` thumbnails, focal positions, optional captions, matching hover/focus information, async decode, eager initial images, lazy below-fold images, intrinsic size reservation, and logical DOM/keyboard order. The rendered column matrix is one at 320 px, two at 390 px, three at 768 px, and four at 1280/1440 px. The Home hero is eager/high-priority; supporting images are lazy where below fold.

One portal-owned modal handles the selected index. It provides a backdrop, named/described modal semantics, Close focus on open, a focus trap, background `inert` plus accessibility-tree hiding, layout-shift-compensated scroll lock, Close/Escape and exact opener return, bounded visible Previous/Next controls, Left/Right Arrow support, no wrap, one-image control omission, position text, contained enlarged imagery, optional captions, a plain image-failure state that preserves controls, mobile-safe layout, and reduced-motion behavior. Backdrop activation intentionally does not close, avoiding accidental loss.

## 10. Accessibility implementation

Implemented and tested: semantic landmarks; one H1 per route; logical headings; skip link; native links/buttons; current-route semantics; keyboard-complete navigation; managed route focus; meaningful image alts; accessible Gallery button names; modal naming/description, trap, Escape, inertness, scroll restoration, and focus return; color-independent text/state; visible 3 px teal focus; minimum targets; reduced motion; and narrow/zoom-equivalent reflow with no horizontal scrolling. This is evidence of deliberate accessibility implementation, not a WCAG certification claim.

## 11. Automated verification and coverage

`npm test -- --reporter=dot`: 6 files passed, 57 tests passed. Focused shell/error-boundary verification passed 22/22 tests; focused Gallery verification passed 35/35 tests. Tests cover all five direct routes, titles/H1 focus, exact static content, not-found, shared shell, canonical links/active state, mobile disclosure behavior, normal rendering through the global error boundary, descendant render-failure fallback, Home recovery, all supported extension cases, synthetic automatic inclusion, unsupported exclusion, metadata/fallback/orphan handling, duplicate detection, complete ordering, current asset inclusion, grid order, lightbox open/close/Escape/arrows/bounds/one-image/focus trap/focus return/inertness/scroll restore/caption/failure/backdrop behavior.

`npm run coverage`: statements 95.89% (187/195), branches 92.30% (96/104), functions 95.52% (64/67), lines 95.45% (168/176).

`npm run build`: succeeded with 104 modules transformed. The output emitted all five Gallery assets, one 251.45 kB JavaScript bundle (78.99 kB gzip), and one 14.21 kB CSS bundle (3.53 kB gzip). No asset-discovery failure occurred. `npm audit --audit-level=low` reported zero vulnerabilities.

## 12. Manual browser and responsive verification

Chrome `151.0.7922.170` on Windows was verified directly through headless Chrome and the Chrome DevTools Protocol without adding an automation framework or dependency. Computed Gallery evidence was:

| Viewport | Columns | Representative tile | Client width | Scroll width | Horizontal overflow |
|---|---:|---:|---:|---:|---|
| 320×568 | 1 | 273 px | 305 px | 305 px | No |
| 390×844 | 2 | 163.5 px | 375 px | 375 px | No |
| 768×1024 | 3 | 219 px | 753 px | 753 px | No |
| 1280×800 | 4 | 282 px | 1265 px | 1265 px | No |
| 1440×900 | 4 | 276 px | 1425 px | 1425 px | No |

The 390 px viewport therefore proves exactly two rendered columns and both first-row tiles measured 163.5 CSS px, exceeding the frozen 160 px minimum. Every representative thumbnail computed to a 4:3 aspect ratio.

Home computed as one 343 px stacked track at 390×844 with no overflow. At 768×1024 it computed exactly two occupied tracks (302.656 px image and 378.344 px text); at 1280×800 it computed exactly two occupied tracks (522.656 px image and 653.344 px text). In both wide cases the two children shared one row, no unused third track existed, and client width equaled scroll width.

All five direct routes rendered one expected H1, expected title, five canonical primary links, correct current-link semantics, and no overflow. At 390 px the Menu disclosure changed from collapsed/hidden to expanded/Grid, focused Home, then closed on Menu selection and focused the Menu H1. The Gallery lightbox opened with dialog heading, Close focus, inert background, scroll lock, bounded Previous/Next controls, then closed with exact opener focus, inertness removal, and scroll restoration.

Edge `151.0.4129.101` on Windows was exercised directly through headless Edge/CDP at 390×844 and 1280×800 without a browser framework. At 1280×800, Home, Menu, Reservations, About Us, and Gallery each rendered the expected title and sole H1, one banner, labelled Primary navigation, one main, one contentinfo, the canonical five links, correct `aria-current`, hidden mobile toggle, and equal client/scroll widths (1265 px). Home retained exactly two occupied tracks with no overflow. At 390×844, Gallery rendered two 163.5 px columns, five tiles, completed images, 4:3 thumbnails, and no overflow. The mobile Menu changed from collapsed/hidden to expanded/Grid and focused Home; Escape closed it and restored trigger focus; selecting Menu closed it, set current-link semantics, and focused the Menu H1. The Gallery lightbox opened as the named dialog with Close focus, inert background and scroll lock; Right Arrow advanced from `1 of 5` to `2 of 5`; Escape closed it, restored the opener, removed inertness, and restored scrolling.

Firefox was not installed on this host. Safari is unavailable on Windows and remains deferred to the approved Prompt-25 Safari-capable checkpoint. No claim is made for either browser.

## 13. Test instructions and repeatability

`frontend/TestInstructions.md` records exact prerequisites, locked install, focused/full/coverage/build commands, five-route/direct-refresh checks, add-file discovery and no-metadata verification, lightbox/reduced-motion/zoom/reflow/browser checks, and explicit dev/preview process ownership. Human checks now explicitly cover banner/labelled Primary navigation/main/contentinfo landmarks, one meaningful H1 and active `aria-current` per route, named Gallery dialog semantics, frozen token-pair contrast spot checks, color-independent state meaning, reduced motion, 200%/400% zoom/reflow, and practical phone/tablet portrait/landscape checks. These are verification instructions, not a WCAG certification claim.

The project-owned PowerShell helper records durable owner/schema, PID, process creation time, Node executable, Vite entry point, working directory, kind, and port evidence under the ignored test-owned temporary area. Status/Stop re-prove all identity fields and the live command line before stopping; occupied ports without ownership are refused; stale valid markers are recoverable; ambiguous markers cause refusal. Discovery-fixture creation now records an owner/path/SHA-256 marker, and final cleanup refuses to remove an existing fixture unless it is untracked and matches that proof. Cleanup failures are terminating; process marker/log absence, generated-directory absence, ports 5173/4173 closure, and protected package/Gallery hashes are explicitly asserted before the final Git-status command.

The workflow was exercised with owned dev and preview processes: ownership was recorded, Status re-proved the live process, Stop terminated only that proven PID, and markers were removed. An intentionally non-owned marker pointing at the current PowerShell PID was rejected on owner mismatch; the process remained alive and the exact test-created fixture was removed. Final helper cleanup removed process metadata/logs. Temporary headless Chrome profile/CDP diagnostics and generated coverage/build output are removed during final cleanup while preserving package files, lockfile, source, tests, and all five Gallery assets.

## 14. Independent-review corrections

1. **Gallery responsive Grid:** the review found that `repeat(auto-fit, minmax(min(100%, 15rem), 1fr))` did not meet the frozen matrix. It was replaced with content-count-agnostic, minimum-aware base behavior plus bounded 2/3/4-column breakpoint templates. The final 16 px narrow gap preserves two tiles of at least 160 px at the rendered 390 px viewport, and removing the artificial body minimum prevents narrow scrollbar overflow.
2. **Global error boundary:** the review found that `App` lacked REACT-01's global boundary. `AppErrorBoundary` now wraps the route tree, catches unexpected descendant render failures, presents an accessible detail-free fallback, and provides a safe full-page Home recovery. Three focused tests cover ordinary rendering, failure fallback, and recovery.
3. **Home feature Grid:** the review found three declared tracks for two children. The tablet/desktop template now has exactly two tracks, with rendered evidence proving both are occupied and no phantom third column exists; mobile remains stacked.
4. **Test process ownership:** the review found insufficient durable dev/preview ownership and interruption recovery. The revised instructions and dependency-free PowerShell helper record and re-prove ownership, refuse ambiguous/non-owned cleanup, support stale-marker recovery, and remove only test-owned metadata/resources.

## 15. Final independent-review conformance pass

The final review accepted the preceding four corrections and identified three remaining conformance items:

1. **Frozen Gallery layout mechanism:** fixed `repeat(2/3/4, ...)` breakpoint templates produced the right screenshots but violated the frozen auto-fit/minmax design. Every breakpoint template is now auto-fit/minmax based, using responsive calculated minimums to preserve the verified 1/2/3/4/4 matrix and intermediate behavior for arbitrary collection sizes.
2. **Installed Edge smoke breadth:** the prior single Menu render was insufficient. The expanded 390×844 and 1280×800 Edge evidence now covers all five routes, canonical/current navigation, landmarks, responsive disclosure, focus/Escape/route-selection behavior, Gallery/lightbox arrows and restoration, Home tracks, and overflow.
3. **Human-check and cleanup instructions:** the instructions now explicitly cover semantic landmarks/dialog naming, frozen contrast pairs, reduced motion, 200%/400% zoom, practical orientation changes, proof-owned discovery cleanup, terminating removal errors, marker/log and generated-path absence, closed ports, protected hashes, and final status ordering.

Automated results, coverage, build, audit, Chrome evidence, and cleanup/refusal evidence were refreshed after these corrections. No Prompt-23/24 behavior was introduced.

## 16. Requirements/design traceability

- FR-01–04: Home identity, contact, hours, imagery, five-link shell.
- FR-05: exact static Menu data and responsive Grid.
- FR-10–11: fact-limited story, mission, biographies, commitments.
- FR-12–14: five-photo automatic Gallery, lightbox, exact awards/reviews.
- NFR-03/04/07/08/09 and rubric UI/UX/Grid/Flex: frozen tokens, responsive/semantic shell, modest dependency/component/CSS architecture, behavior tests, browser checks.
- REACT-01: page/component boundaries, automatic discovery, metadata enrichment, alt fallback, ordering, single lightbox.
- REACT-02: Home-only canonical newsletter placement and reserved form boundaries; no form state pulled forward.
- REACT-03: exact toolchain, CSS/tokens/breakpoints/navigation/lightbox/test strategy.

## 17. Deferred work and remaining gap

Prompt 23 remains responsible for all reservation/newsletter controls, validation, mocked operations, state machines, pending/error/unknown outcomes, confirmation, and MSW user flows. Prompt 24 remains responsible for native-fetch Flask integration and live API/database behavior. No backend/database/API files changed.

Asset provenance/licensing for the originally supplied images remains an explicit content-governance item due before final delivery/INT-08. The new behind-the-scenes image may later be documented as AI-generated during this project. Provenance was not invented and did not block REACT-04.

## 18. Approval checkpoint

REACT-04 passed independent final implementation review. The final complete review artifact used for that review was 238,964 bytes, had SHA-256 `035E3A179695054F4F2C7534BD34DEE32578D20C45408578FC7E66E57CA889E3`, and represented 41 paths. The four findings from the first independent review and the three subsequent conformance findings were corrected and independently re-reviewed.

REACT-04 / Prompt 22 is **APPROVED AND FROZEN**. Prompt 23 remains the next implementation increment and is not being implemented by this documentation closeout.
