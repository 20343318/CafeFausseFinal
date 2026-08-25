# Cafe Fausse REACT-03 Visual System and React Test Strategy

**Status:** APPROVED AND FROZEN

**Date:** 2026-08-24

**Roadmap increment:** REACT-03 / UI-03

**Scope:** Design and test planning only; no React implementation is authorized by this artifact.

## 1. Baseline and approval state

Phase 0 was performed against branch `main` at full HEAD
`8a605334d7a77b6dfbae2361c9907a29da5720b8`. The worktree and real Git index were
clean. The recent relevant commits are Prompt 21 at `8a60533`, approved REACT-02 at
`7b47c0f`, approved REACT-01 at `82adadd`, and Flask Hard Gate 2 at `73dbd68`.

REACT-01 and REACT-02 both say `APPROVED AND FROZEN`. Prompt 21 is the next
authorized increment. `frontend/` contains only the four supplied WebP source assets
under `frontend/assets/gallery/`; it has no package manifest, lockfile, runtime source,
build configuration, or testing convention. This document does not change that state.

The three REACT-01 content gaps remain open: no identifiable behind-the-scenes image,
no approved detailed founder biographies beyond the SRS facts, and no recorded asset
provenance/licensing evidence. Section 26 assigns their resolution checkpoints.

## 2. Authoritative sources reviewed

The following were applied in Prompt 21 precedence order:

1. repository instructions, SRS, and rubric;
2. Project Requirements Addendum 2.2.1, requirements baseline, and least-to-most
   roadmap/UI-03;
3. frozen PostgreSQL-to-Flask contract where frontend authority matters;
4. approved API-01 operation inventory, API-02 REST contract, API-03 architecture/test
   strategy, and API-09 Hard Gate 2 report;
5. frozen REACT-01 architecture/asset analysis and REACT-02 reservation/newsletter UX;
6. current public backend implementation only to confirm frozen API facts;
7. the four current Gallery assets and Prompt 21.

REACT-01 deferred the exact build/router/data/CSS choices, responsive metrics,
navigation details, runtime image convention, and test tools. REACT-02 additionally
deferred native date-control compatibility, debounce timing, skeleton/motion/touch
metrics, and complete form-state tests. Those technical decisions are resolved below;
the frozen component boundaries, workflows, and server-authority rules are unchanged.

## 3. Visual direction

Cafe Fausse should feel warm, composed, contemporary, and quietly celebratory rather
than ornate. The visual language uses deep wine actions, espresso text, warm ivory
surfaces, restrained brass accents, generous whitespace, editorial photography, and a
serif heading face from the local system stack. It should suggest fine dining without
pretending to have heritage or accolades beyond the approved copy.

- Surfaces: ivory page canvas, near-white content cards, and pale parchment accents.
- Shape: 4 px controls, 8 px cards, and fully rounded pills only for compact statuses.
- Borders: one-pixel warm neutral rules establish structure; avoid decorative frames.
- Elevation: none for normal sections; one soft shadow for menus, dialogs, and the
  lightbox only (`0 12px 32px rgb(33 26 23 / 18%)`).
- Images: natural color, no heavy filters; `object-fit: cover` for thumbnails and
  `contain` in the lightbox. Crops must not imply unsupported subject matter.
- Icons: optional project-owned inline SVG only where text remains available (menu,
  close, previous, next, status). Decorative icons are hidden from assistive technology.
- Motion: 120–180 ms opacity/color/transform transitions only. No parallax,
  auto-advancing content, or layout animation. `prefers-reduced-motion: reduce` removes
  nonessential transition and smooth-scroll behavior.

## 4. Color tokens and contrast evidence

These are the complete semantic Version 1 tokens. Ratios use the WCAG relative
luminance formula, rounded to two decimals. They are design evidence, not a claim of
certification. Normal body text uses pairs at or above 4.5:1; focus and non-text control
boundaries are also checked manually at implementation.

| Token | Value | Intended use and measured text pair |
|---|---:|---|
| `--color-page` | `#F7F2E8` | Page background; espresso text 15.37:1, secondary text 6.89:1 |
| `--color-surface` | `#FFFCF6` | Cards/forms; espresso text 16.74:1, secondary text 7.51:1 |
| `--color-surface-accent` | `#EFE4D2` | Quiet section band; espresso text 13.63:1 |
| `--color-text` | `#211A17` | Primary text |
| `--color-text-muted` | `#5C514A` | Secondary/helper text; never the only state signal |
| `--color-border` | `#C8B9A5` | Dividers and default input borders; not body text |
| `--color-action` | `#7A2432` | Primary action; white text 9.88:1 |
| `--color-action-active` | `#5E1724` | Hover/active action; white text 12.93:1 |
| `--color-focus` | `#0B6E75` | 3 px focus ring with 2 px surface offset; on surface 5.86:1 |
| `--color-success` | `#2F6B4F` | Success border/icon/text on surface, 6.15:1 |
| `--color-warning` | `#8A5A00` | Warning border/icon/text on surface, 5.79:1 |
| `--color-error` | `#A1262D` | Error border/icon/text on surface, 7.24:1 |
| `--color-disabled-bg` | `#DDD5CA` | Disabled control fill |
| `--color-disabled-text` | `#5B554F` | Disabled text on disabled fill, 5.06:1; also paired with native disabled semantics |
| `--color-selected-bg` | `#E6D5B8` | Selected slot/nav accent; espresso text 11.90:1 plus selected label/check |
| `--color-unavailable-bg` | `#E5E1DB` | Unavailable slot fill; `#5C5650` text 5.56:1 plus “Unavailable” and disabled semantics |

Status panels use a 4 px semantic-color leading border, a text heading, and a simple
symbol, while retaining the surface background. This avoids low-contrast tinted text and
color-only communication. Links are wine, underlined in prose, and darken on hover.

## 5. Typography

No font download is proposed. Headings use `Georgia, "Times New Roman", serif`; body,
navigation, labels, and controls use `system-ui, -apple-system, "Segoe UI", Roboto,
Arial, sans-serif`. This has no network/privacy/cache dependency and renders promptly.

| Role | Size / line height | Weight / treatment |
|---|---|---|
| Hero | `clamp(2.5rem, 7vw, 5.5rem) / 0.98` | Georgia 700, balanced short lines |
| H1 | `clamp(2rem, 4vw, 3.5rem) / 1.08` | Georgia 700 |
| H2 | `clamp(1.5rem, 2.5vw, 2.25rem) / 1.18` | Georgia 700 |
| H3 | `1.25rem / 1.3` | Georgia 700 |
| Body | `1rem / 1.6` | 400; max reading line 68 characters |
| Large body | `1.125rem / 1.6` | Introductory copy only |
| Label/nav/button | `0.9375rem / 1.35` | 600; normal case, not letter-spaced all caps |
| Helper/error | `0.875rem / 1.45` | 400/600 according to emphasis |
| Menu price | `1rem / 1.4` | 700, tabular numerals, right aligned where space permits |

Heading levels follow document structure, not size. No paragraph is justified or set in
all caps. Browser zoom to 200% must retain readable reflow.

## 6. Spacing and sizing

Use a 4 px base scale: `--space-1: .25rem`, `2: .5rem`, `3: .75rem`, `4: 1rem`,
`5: 1.5rem`, `6: 2rem`, `7: 3rem`, `8: 4rem`, `9: 6rem`. Section spacing uses
`clamp(3rem, 7vw, 6rem)`. The content container is `min(100% - 2rem, 75rem)`;
reading/form content is capped at 46 rem and reservation content at 64 rem. Controls are
at least 44 by 44 CSS px; primary mobile actions are full-width where useful. Input
height is at least 44 px and textarea, if later justified, at least 7.5 rem. No current
approved form requires a textarea.

## 7. Responsive breakpoints and device matrix

Breakpoints are content-driven CSS minimum widths: base `<30rem`, `30rem` (480 px),
`48rem` (768 px), `64rem` (1024 px), and `90rem` (1440 px). Representative manual
viewports are 320×568, 390×844, 768×1024, 1280×800, and 1440×900. Tests change
`matchMedia`/viewport assumptions only for presentational behavior such as the nav;
business behavior never varies by device.

| Viewport | Navigation/container | Gallery | Menu | Reservation controls / slots |
|---|---|---|---|---|
| 320 narrow phone | Collapsed menu; 1 rem gutters | 1 column | One item column; price below/right | Date/party stacked; 1 column slots |
| 390 larger phone | Collapsed menu; fluid | 2 columns when each tile remains ≥160 px | Same, price may share row | Stacked controls; 2 slot columns |
| 768 tablet | Collapsed menu; 2 rem gutters | 3 columns | Two category columns only when reading order remains logical | Date/party row; 3 slot columns; identity pairs selectively |
| 1280 desktop | Inline nav; max 75 rem | 4 columns | Two balanced category columns | Context beside summary where useful; 4 slot columns |
| 1440 wide | Inline nav; centered max width, no unlimited stretching | 4 columns, larger gutters | Two columns | Same source order; 4–5 slots only if 44 px targets and labels fit |

At 400% zoom in a 1280 px browser, the experience must reflow like the narrow layout
without horizontal page scrolling. Grid uses `minmax()` so intermediate widths remain
sound. CSS layout, not JavaScript device detection, controls columns.

## 8. Page layout specifications

### Home

Order: header; split editorial hero; contact/hours strip; restaurant story teaser;
featured ribeye/interior image pair; reviews/awards teaser; one full newsletter form;
footer. The hero uses `home-cafe-fausse.webp` with a dark lower-edge gradient only when
text overlays it; preferred desktop treatment places text beside the image for reliable
contrast. Primary CTA is “Reserve a table,” secondary is “View the menu.” Address,
phone, and current hours appear below the hero; hours use OP-01 when live integration is
later added, with a clear load/retry state and no fabricated fallback authority.

The single canonical standalone `NewsletterPreferences` form is near the end of Home,
after the substantive content and before the footer. The header/footer may link to the
`#newsletter` region but must not duplicate the form.

### Menu

An understated page header introduces four SRS categories. A CSS Grid places category
sections in one column on phones and two columns at tablet/desktop, preserving DOM order:
Starters, Main Courses, Desserts, Beverages. Each item is a compact row with name and
price aligned on one line when possible and description below; dot leaders are avoided.
All exact SRS names, descriptions, and prices remain unchanged. The ribeye image is one
optional supporting figure adjacent to Main Courses on wide layouts, never replacing
menu text.

### Reservations

The frozen progressive order remains: page heading and policy/context panel; date and
party fieldset; Check/Update availability; full returned slot fieldset; identity/contact
fieldset; newsletter status/preference; read-only review; Reserve action; feedback;
confirmation or outcome-unknown recovery. Sections are numbered visually only when it
helps orientation; their semantic legends carry the names.

The form is one readable column by default. Desktop may place the date/party group and a
compact policy summary side-by-side, but DOM order never changes. Slots are a grid of
native radio controls styled as cards; every OP-02 slot remains visible and unavailable
ones say “Unavailable.” Review uses a definition list. Error summary precedes the first
affected fieldset. Outcome unknown is a prominent warning/recovery panel distinct from
ordinary errors and confirmation-unavailable. Confirmation is a focused single-column
card displaying only the approved OP-05 public facts.

Use the native `input[type=date]` for Version 1. It supplies keyboard/mobile platform
behavior without a date-picker dependency. Apply API-provided `min`/`max` for usability,
show the restaurant-local date instruction, and retain server validation. Browser-manual
testing covers its platform differences. Party size is `input[type=number]` with current
OP-01 bounds, visible increment controls where the browser supplies them, and direct
numeric entry; no custom stepper.

OP-03 lookup debounce is 400 ms after all required identity fields are locally eligible.
Sequence/snapshot checks, not timing, provide correctness. Tests use fake timers only for
the debounce boundary, then user-visible outcomes.

### About Us

Order: page header; approved 2010 origin story and mission; two equal founder cards;
commitments to unforgettable dining, excellent food, and locally sourced ingredients;
contact CTA. Founder cards state only Chef Antonio Rossi’s and restaurateur Maria
Lopez’s SRS roles until approved biographies exist. The interior image may support the
mission; no current image is relabeled as a founder or behind-the-scenes image. Cards
stack on narrow screens and form two columns at 768 px.

### Gallery

Order: page header; flat discovered image grid; awards; reviews. Tiles use a 4:3 thumbnail
box, natural focal center by default, 8 px radius, and captions beneath when metadata
exists. Hover adds a subtle overlay/scale of at most 1.02; focus uses the global ring and
must expose the same information. A Grid `auto-fit/minmax` implementation produces the
approved columns. Collections remain flat in Version 1.

Awards use three concise cards containing the exact SRS award names/years. Reviews use
semantic quotations and exact attribution. Larger future collections still use stable
metadata-first ordering and lazy thumbnails; no category/CMS behavior appears implicitly.

## 9. Shared navigation and application shell

`AppShell` owns one skip link, header, canonical five-link model, main landmark/route
outlet, and footer. The brand is a Home link. Desktop links are inline; `NavLink` supplies
active route behavior and `aria-current="page"`. The footer repeats contact facts and may
repeat text navigation plus a “Newsletter preferences” anchor link.

The not-found route is approved as a technical navigation necessity: it has an H1,
nontechnical explanation, and links to Home and the five destinations. It performs no
automatic redirect, preserving direct-route diagnosis.

Below 64 rem, a real button labeled “Menu” controls the navigation with
`aria-expanded` and `aria-controls`. It starts collapsed. Activation opens it and moves
focus to the first link; Tab/Shift+Tab follow normal document order without a focus trap.
Escape closes it and returns focus to the trigger. Selecting any route closes it and the
new page H1/main region receives managed focus after navigation. Pointer activation
outside closes it only when focus is not being moved into the menu; outside-click is a
convenience, never the sole close method. Resize to desktop clears the expanded state.
The trigger remains available while open and has visible focus.

The skip link is first focusable content, hidden offscreen until focused, and targets the
single `main` landmark. Route changes set a descriptive document title and move focus
without announcing twice.

## 10. Form and control visual system

- Labels sit above controls. “Required” or “Optional” is written in label/helper text and
  represented with native/ARIA attributes; middle initial and phone always say Optional.
- Helper text precedes errors and is linked with `aria-describedby`. Placeholder text is
  an example only and never the label.
- Inputs use surface fill, 1 px border, 4 px radius, and 0.75×1 rem padding. Focus uses
  the global 3 px ring. Invalid controls use an error border, icon, `aria-invalid`, and a
  linked error message—not color alone.
- Related controls use `fieldset`/`legend`: reservation choices, slots, identity/contact,
  and newsletter preference. Checkbox text describes the final Boolean choice.
- Slot radios preserve native checked semantics. Selected cards say “Selected”; disabled
  slots remain discoverable as text and say “Unavailable.”
- Review values are a `dl`, never disabled duplicate inputs.
- A pending mutation disables/locks the relevant fieldset, applies `aria-busy` to its
  region, changes the button label, and shows adjacent status. Read loading does not hide
  existing identity inputs.
- Disabled submit includes persistent adjacent explanation of what is missing. Native
  `disabled` is used only when action truly cannot be accepted; `aria-disabled` is not a
  substitute for validation.

Control hierarchy is limited to primary filled button, secondary outlined button, and
underlined text link/action. There is no destructive reservation action. Buttons respond
to Enter/Space natively, links to Enter, pointer targets meet 44 px, hover is additive,
and pressed/selected state uses native semantics. Loading buttons keep a stable width.

## 11. Status, error, and outcome-unknown presentation

One reusable `StatusPanel` visual grammar has icon, heading, concise detail, and action:

| State | Semantic/presentation rule |
|---|---|
| Inline field error | Adjacent linked text; no live announcement during ordinary typing |
| Error summary | Focused heading after invalid submit; list links to invalid fields |
| Information | Polite status region, teal icon/rule |
| Loading/busy | Polite one-time status and busy region; skeleton only for stable card geometry |
| Success | Green icon/rule and explicit “Confirmed”/“Saved” wording |
| Warning | Amber icon/rule; action remains clear |
| Retryable read failure | Ordinary error plus explicit “Try again”; current inputs preserved |
| Known mutation failure | Error; never implies commit ambiguity; retry only when API permits |
| Outcome unknown | Amber warning headed “Reservation result not confirmed” or newsletter equivalent; freeze exact snapshot and expose only identical retry or explicit abandon |
| Confirmation unavailable | Warning headed “Reservation exists; confirmation unavailable”; identical reconstruction action; never call it a failed reservation |

Alerts use `role=alert` only when immediate attention is required; progress and success
generally use `role=status`. Icons and headings distinguish all states without color. API
messages may be supporting text, but behavior branches only on frozen codes/flags.

## 12. Gallery lightbox final interaction

Activating a thumbnail opens a project-owned modal over `rgb(20 16 14 / 88%)`. The
dialog is at most 90 vw by 90 dvh; its image uses `max-inline-size: 100%`,
`max-block-size: min(75dvh, 56rem)`, and `object-fit: contain`. Caption and optional
position (“2 of 4”) sit below. Close is a labeled 44 px button at the upper end. Previous
and next are labeled buttons beside/below the image; first/last controls are disabled,
not wrapping. With one image both navigation controls are omitted and position may say
“1 of 1.”

On open, focus moves to Close (stable and predictable). Tab/Shift+Tab are trapped among
dialog controls; Left/Right Arrow moves within bounds; Escape closes; closing returns
focus to the exact originating thumbnail. Background content is inert and hidden from
the accessibility tree while open, and page scroll is locked without shifting layout.
The dialog has `role=dialog`, `aria-modal=true`, an accessible name, and caption
description. Touch users use the same visible buttons; swipe is unnecessary. At narrow
sizes controls move below the image and respect safe-area padding. Reduced motion uses
an immediate open/close; otherwise only a short fade occurs. Image-load failure leaves
the caption and a plain failure message plus navigation/close controls.

## 13. Accessibility implementation checklist

Prompt 22 and later acceptance checks:

- one header, nav label, main, and footer; one meaningful H1 per route and no skipped
  heading levels for presentation;
- skip link visible on focus; all routes, forms, slots, and lightbox usable keyboard-only;
- native link/button/input/radio/checkbox semantics; `aria-current=page` on one nav link;
- 3 px focus indicator remains visible in every state and is never clipped;
- explicit labels, linked descriptions/errors, required/optional text, fieldsets/legends,
  focused linked summary after invalid submit;
- polite status for progress/results, alert only for errors requiring attention, and no
  duplicate announcements;
- modal name, modal state, focus entry/trap/return, Escape, and inert background;
- unavailable slots disabled and named “Unavailable”; selected slot retains checked
  semantics and a non-color label;
- disabled Reserve action has adjacent explanation; pending lock is announced;
- layout reflows at 320 px and at 400% zoom with no two-dimensional page scrolling;
- motion remains understandable with reduced motion; no information depends on motion;
- pointer targets at least 44×44 CSS px with adequate separation;
- all intended text pairs use Section 4 contrast; images have meaningful approved alt or
  empty alt when truly decorative; status never relies on color alone.

Automated semantic assertions supplement but do not replace keyboard, screen-reader
spot checks, zoom/reflow, contrast, and browser review. No certification is claimed.

## 14. Image delivery and automatic discovery

The canonical source/runtime-import folder remains `frontend/assets/gallery/`; Prompt 22
must not copy the images into a second registry-like tree. A discovery module under
`frontend/src/` uses a literal relative Vite `import.meta.glob` pattern reaching that
folder, with `{ eager: true, query: '?url', import: 'default' }`, to obtain bundled image
URLs at build time. Optional presentation metadata lives separately at
`frontend/src/content/gallery-metadata.js`. This directly satisfies automatic inclusion
without a manual asset registry while keeping the currently supplied files in place.

Version 1 supported extensions are exactly `.webp`, `.jpg`, `.jpeg`, `.png`, and `.avif`.
The discovery module passes a literal relative pattern such as
`../../assets/gallery/*.{webp,jpg,jpeg,png,avif}` to `import.meta.glob` with
`{ eager: true, query: '?url', import: 'default', caseSensitive: false }`. Vite's
case-insensitive glob matching therefore includes lower-, upper-, and mixed-case forms of
every supported extension without separately enumerating case variants. SVG/GIF remain
unsupported Gallery-photo inputs.

Normalize every matched relative path and reject duplicate normalized names. The frozen
deterministic ordering algorithm is complete and authoritative:

1. All metadata-backed images appear before every image without metadata.
2. Within the metadata-backed group:
   1. entries with an explicit numeric `order` appear first, sorted by `order`;
   2. duplicate explicit `order` values use normalized filename and then exact filename
      as deterministic tie-breakers;
   3. metadata-backed entries without an explicit `order` follow all explicitly ordered
      metadata-backed entries; and
   4. those unordered metadata-backed entries sort by normalized filename and then exact
      filename.
3. The no-metadata group follows all metadata-backed images.
4. The no-metadata group sorts by normalized filename and then exact filename.
5. Filesystem enumeration order is never authoritative.

Metadata is an optional exported object keyed by exact filename with `alt`, optional
`caption`, optional numeric `order`, and optional normalized `objectPosition`. It enriches
presentation but never controls inclusion. Unknown metadata keys fail a build/test check
so stale records are visible.

Alt fallback removes path/extension, replaces hyphens/underscores with spaces, collapses
whitespace, and sentence-capitalizes the filename. It must be reviewed for meaningfulness;
it does not license inventing subject matter. Corrupt files remain discovered but render a
clear fallback in the grid/lightbox and fail the build-time image verification; unsupported
files are ignored and reported by the verification script/test.

Gallery thumbnails use intrinsic `width`/`height` obtained during the approved build step
or explicit metadata to reserve 4:3 boxes, `srcset`/`sizes` when generated variants are
later justified, `loading=lazy`, and `decoding=async`. The hero is eager with
`fetchpriority=high`, fixed dimensions/aspect ratio, and a responsive `sizes` value.
Version 1 may use the same optimized source for thumbnail and lightbox because there are
only four WebPs; generated variants are a measured optimization, not a prerequisite.
Tests inject glob results so they prove automatic discovery; lower-, upper-, and
mixed-case forms of all five supported extensions; addition of a new file; build URL
emission; metadata-backed-before-no-metadata grouping; explicit numeric ordering;
duplicate-order normalized-then-exact-filename tie-breaking; unordered-metadata placement
and normalized-then-exact-filename ordering; no-metadata normalized-then-exact-filename
ordering; filename-alt fallback; and independence from filesystem enumeration order.

## 15. Frontend toolchain decision

- **Build:** Vite, plain JavaScript + JSX, ES modules. It supplies the dev server,
  production build, environment replacement, CSS handling, and literal
  `import.meta.glob`. Use only `VITE_` public configuration; secrets never enter the
  client. Build output is static SPA assets.
- **React:** React/React DOM `19.2.8`.
- **Routing:** React Router declarative mode with browser history. It provides five direct
  routes, nested shared layout, active links, navigation, and a splat not-found route
  without adopting loaders, actions, SSR, or framework mode. The serving environment
  must rewrite unknown non-asset paths to `index.html`; this is documented and tested.
- **HTTP:** native `fetch`, one small project-owned JSON/error adapter, `AbortController`
  for optional read cancellation, and REACT-02 sequence/snapshot guards. No Axios.
- **State:** local state/hooks and narrowly scoped custom hooks/reducers for the frozen
  reservation/newsletter machines. No global store or query library.
- **UI/icons:** semantic HTML and project-owned CSS; a few inline SVGs. No component or
  icon library.
- **Environment/browser:** Node `24.15.0` or a later Node 24 release is the proposed
  Prompt-22 development line; it satisfies the selected Vite, Vitest, jsdom, and jest-dom
  engine floors. Prompt 22 records the exact Node/npm patch actually used. Production targets the current Vite
  Baseline Widely Available default, then the manual matrix confirms the required modern
  Chrome, Firefox, Safari, and Edge versions. No legacy plugin unless evidence requires it.

Official capability references used for this decision are the Vite feature guide
(`https://vite.dev/guide/features`) and React Router mode/routing guides
(`https://reactrouter.com/start/modes`). Versions are not installed or locked here.

## 16. Production dependency decision table

| Package | Purpose | Why native platform is insufficient | Status |
|---|---|---|---|
| `react@19.2.8` | Required JSX component runtime | SRS explicitly requires React | Required |
| `react-dom@19.2.8` | Mount React into the browser DOM | Required React browser renderer | Required |
| `react-router@8.3.0` | Declarative addressable SPA routes, active links, not-found handling | Manual History API routing/focus/link interception adds avoidable risk | Required |

There are exactly three proposed production packages. `vite` and all test tools are
development-only. Axios, Redux/Zustand, TanStack Query, Tailwind, Sass, CSS-in-JS,
component frameworks, date pickers, lightbox packages, and icon libraries are rejected
because the approved requirements do not justify their runtime or maintenance cost.

## 17. CSS architecture

Use ordinary imported CSS organized as `styles/tokens.css`, `base.css`, `layout.css`,
shared component files, and page files. `tokens.css` owns only custom properties;
`base.css` applies a small box-sizing/margin/media reset and element defaults. Classes use
low-specificity component names (`.site-header`, `.button--primary`, `.status-panel`) and
state attributes/classes (`[aria-invalid=true]`, `[aria-current=page]`, `.is-loading`)
only where native attributes do not suffice. No IDs, deep descendant chains, or
`!important` except a documented reduced-motion reset if required.

Grid owns macro page sections, menu categories, Gallery, slots, and responsive form
groups. Flexbox owns nav rows, button groups, item/price alignment, and inline status
content. Media queries are mobile-first at Section 7 breakpoints and remain near the
component they adjust. A tiny `.visually-hidden` utility and container/flow utilities are
allowed; utility-class composition is not the styling architecture. Visual-state classes
must be testable without asserting large snapshots.

## 18. React testing-stack decision

| Concern | Proposed development tool / policy |
|---|---|
| Runner | Vitest in Vite configuration, `jsdom` environment |
| Components | `@testing-library/react` plus its required DOM peer |
| Interaction | `@testing-library/user-event` |
| DOM assertions | `@testing-library/jest-dom/vitest` |
| API mocks | Mock Service Worker (MSW) request handlers built from frozen API-02 examples/semantics |
| Timers | Vitest fake timers only for debounce/time-bound behavior; restore after each test |
| Coverage | V8 provider; report statements/branches/functions/lines, exclude generated/build/config files; no arbitrary 100% gate |
| Browser/E2E | No Playwright/Cypress dependency in Prompt 22. Manual real-browser matrix covers browser behavior; reconsider a minimal Playwright smoke suite at Prompt 24/25 if live-integration risk justifies it. |

The proposed exact development pins, queried from the npm registry on 2026-08-24, are
`vite@8.2.2`, `@vitejs/plugin-react@6.1.0`, `vitest@4.1.11`,
`@vitest/coverage-v8@4.1.11`, `jsdom@30.0.1`,
`@testing-library/react@16.3.2`, `@testing-library/dom@10.4.1`,
`@testing-library/user-event@14.6.6`, `@testing-library/jest-dom@7.0.1`, and
`msw@2.15.0`. Prompt 22 installs these exact versions and commits the generated lockfile;
it must stop and request a design revision if peer/engine resolution or a security audit
shows they cannot be used together. Dependency ranges must not float across CI. Tests query by role, accessible name, label, and visible status.
`data-testid` is limited to otherwise unaddressable request-sequence seams. Large DOM or
CSS snapshots are prohibited. Coverage is diagnostic: critical navigation, discovery,
focus, validation, stale-response, and mutation-recovery branches must be directly tested
even if overall percentages look high.

## 19. Unit/component test plan

### Shell and static content

- canonical nav exposes Home, Menu, Reservations, About Us, Gallery with correct hrefs;
  direct route, active `aria-current`, title/H1 focus, skip link, shared shell persistence,
  not-found actions, and Home OP-01 hours success/failure/retry;
- mobile menu initial state, pointer/keyboard open, first-link focus, normal Tab order,
  Escape/trigger focus return, route-selection close, outside close, and desktop reset;
- Home required name/contact/hours/CTAs and sole newsletter form; exact Menu category,
  item, description, and price fixture; exact About history/mission/roles/commitments;
  exact awards and reviews;
- Gallery glob normalization and automatic inclusion; lower-, upper-, and mixed-case
  forms of every supported extension; metadata-backed-before-no-metadata grouping;
  explicitly ordered entries first; duplicate-order normalized filename then exact
  filename tie-breaking; unordered metadata-backed entries next in normalized filename
  then exact filename order; no-metadata entries last in the same filename order;
  filesystem enumeration independence; metadata enrichment; no-metadata fallback alt;
  orphan metadata; unsupported/corrupt behavior; and meaningful visual-state hooks.

### Gallery lightbox

- open from each tile; dialog name/description; Close and Escape; backdrop only if
  deliberately supported; previous/next; disabled first/last; arrows; no wrap; one-image
  controls; focus entry/trap/return; background inertness/scroll restoration; caption/alt,
  load failure, reduced motion, and rerender after larger collections.

### Reservation

- OP-01 loading/success/failure/retry and authoritative date/party bounds;
- native date and numeric party validation; explicit Check/Update action; OP-02 loading,
  every returned slot in server order, provisional wording, unavailable disabled, selected
  checked, empty/full/failure states;
- late OP-02 ignored by sequence/exact key; date/party edit invalidates results/selection;
  selected slot removed by refresh clears it and focuses/announces required action;
- structured names, email and confirmation normalized comparison, optional middle/phone,
  field errors, linked summary/focus, server field mapping, and preserved useful data;
- 400 ms eligible OP-03 debounce, suppression, matched/not-found/conflict/indeterminate,
  stale identity response, dirty-choice version protection, and `no_change` path;
- review facts, explicit eligibility explanation, immutable body snapshot, pending lock and
  double-submit suppression;
- ordinary validation/conflict/overlap/unavailable/read/known temporary failures; refresh
  semantics; confirmation unavailable; outcome unknown freeze; exact identical retry;
  explicit abandon warning; created and exact-retry confirmation with all and only public
  fields, restaurant-local values, table numbers, phone notice, focus, and missing-memory
  direct confirmation route.

### Standalone newsletter

- local identity validation and eligible lookup; matched/not-found/conflict/indeterminate;
  stale sequence and dirty choice; subscribe and unsubscribe final Boolean; unknown
  identity false yields no-customer-no-change; pending lock; known failure; outcome unknown
  exact snapshot/recovery; authoritative response sync; no PII persistence.

### Accessibility assertions

Every relevant test asserts roles/names/labels/descriptions, current/checked/disabled/busy
state, alert versus status behavior, and focus transitions. Add a lightweight automated
accessibility audit only if selected at Prompt 22 after compatibility review; semantic
Testing Library assertions remain required regardless.

## 20. Mocked frontend integration test plan

Render complete route trees with MSW and exercise:

1. all five routes, direct navigation, active state, shell persistence, mobile navigation,
   not-found recovery, and Home context-hours success/failure;
2. automatic Gallery result to grid to lightbox to returned thumbnail focus;
3. reservation happy path: context, availability, selected slot, identity/newsletter sync,
   review, POST body, pending lock, confirmation;
4. fully unavailable day, selected slot becoming unavailable, identity conflict,
   indeterminate lookup with `no_change`, late stale lookup, and field validation;
5. ambiguous reservation response, frozen exact body, identical recovery returning
   `exact_retry`, plus distinct known confirmation-unavailable reconstruction;
6. standalone newsletter subscribe, unsubscribe, no-customer-no-change, stale lookup,
   known error, unknown outcome, and identical recovery;
7. representative 320/768/1280 navigation state assumptions while asserting invariant
   DOM/source order and functionality.

Handlers reuse frozen paths, statuses, fields, codes, `retryable`, and `outcome_unknown`
semantics. Contract fixtures are centralized and validated for required shape so tests do
not invent a second API. No live Flask/database is used until Prompt 24.

## 21. Browser, device, and manual matrix

| Environment | Local status | Required checks |
|---|---|---|
| Latest stable Chrome on Windows | Executable | Full five-route/forms/Gallery flow at all representative viewports; DevTools throttling and mobile emulation |
| Latest stable Edge on Windows | Executable | Full smoke flow plus native date, focus, direct route refresh |
| Latest stable Firefox on Windows | Executable | Full smoke flow plus Grid/Flex reflow, keyboard, image behavior |
| Latest stable Safari on current macOS/iOS | Not locally executable on this Windows host | Required before Prompt 25 approval via a Safari-capable physical/hosted environment; native date, focus/inert dialog, dynamic viewport, touch, direct refresh |

Standards-based jsdom/unit tests can validate DOM semantics and state transitions but do
not validate Safari layout, native date UI, focus rendering, touch behavior, or image
decoding. Safari therefore cannot be marked passed from automated component tests.

At 320×568, 390×844, 768×1024, 1280×800, and 1440×900, manually verify navigation,
source/logical order, no horizontal scroll, typography/line length, image crop/quality,
lightbox/scroll lock, focus visibility, complete keyboard flow, forms/validation,
loading/success/error/unknown recovery, 44 px targets, reduced motion, 200%/400% zoom,
and contrast spot checks. Test portrait and landscape for phone/tablet. Record browser
versions, OS, viewport, result, defect, and evidence; do not claim unrun coverage.

## 22. Performance design and later measurement

No performance compliance is claimed. Prompt 25 measures a clean production build with
cache cold and warm, browser extensions disabled, documented hardware/OS/browser, and a
standard-broadband throttling profile. Record navigation timing, transferred bytes,
largest image/content paint, layout shift, and screenshots/traces sufficient to reproduce
the result. The SRS initial-load target is under three seconds; report measured evidence
and conditions rather than a synthetic universal guarantee.

Keep the initial route small, reserve image dimensions, eagerly prioritize only the hero,
lazy-load below-fold/Gallery images, avoid font downloads and UI frameworks, and inspect
Vite bundle output. Route-level code splitting is optional only if measurement shows a
useful reduction; five small static routes do not justify premature machinery. Gallery
variant generation is likewise measurement-driven.

For forms, show feedback immediately after a valid action and measure click-to-visible
pending state separately from API completion. Backend API-09 evidence remains backend
evidence; browser/network and full React→Flask→PostgreSQL timing are measured in Prompt
24/25 and final integration. The SRS two-second submission expectation is not weakened
by responsive loading UI or claimed from mocked tests.

## 23. Planned `frontend/TestInstructions.md`

Prompt 22 creates this file, not Prompt 21. It must document exact Node/npm/browser
versions; clean dependency installation from the lockfile; development server start and
graceful stop; production build/preview; named focused tests; full deterministic suite;
coverage generation/review; route/direct-refresh/navigation checks; the five viewport
checks; keyboard, focus, zoom, contrast, reduced-motion, and semantic checks;
Gallery discovery/add-file/case-insensitive-extension/complete-Section-14-ordering/fallback/lightbox checks; mocked API states present in
the implemented increment; and honest Safari alternatives.

Every procedure must be restartable after success, failure, or Ctrl+C. It records ports
and process ownership, uses only test-owned temporary locations, and includes recovery
for interrupted dev/preview/test runs. The final step stops owned processes and removes
only generated coverage, caches, temporary fixtures, reports/screenshots not intentionally
retained, and other test-owned resources. It must preserve committed source/assets,
package/lockfiles, and user resources. A final status check demonstrates cleanup.

## 24. Future-prompt test mapping

| Prompt | Required additions / evidence |
|---|---|
| 22 — static app + Gallery | Vite build; shell/routes/direct refresh/not-found; exact static content; responsive nav; Gallery automatic discovery, case-insensitive supported-extension matching, complete Section 14 ordering/fallback, and lightbox/focus; accessibility basics; initial `TestInstructions.md`; manual responsive/browser smoke |
| 23 — forms with mocks | All REACT-02 state, validation, slots, staleness, dirty-choice, mutation snapshot/error/unknown/confirmation tests; MSW page flows; responsive forms; update instructions |
| 24 — live Flask integration | Native fetch adapter and frozen contract mapping; real availability/reservation/newsletter happy/error/recovery paths; PostgreSQL effects in controlled test data; cross-layer timing; update instructions and cleanup |
| 25 — React gate | Full unit/integration/build/coverage suite; complete SRS/PRA/rubric audit; Chrome/Edge/Firefox and actual Safari evidence; accessibility/manual matrix; performance measurements; repeatability and clean final state |

## 25. Requirements, visual, and test traceability

| Authority | Visual/system response | Component/page | Automated evidence | Manual evidence | Prompt |
|---|---|---|---|---|---|
| FR-01–04 | Hero, exact contact/hours, images, canonical nav | Home/Shell | content, links, OP-01 states | brand/readability/routes | 22/24/25 |
| FR-05 | Scannable category Grid, tabular prices | Menu | exact fixture content | reflow/scanning | 22/25 |
| FR-06–09 | Progressive labeled form, API slots, distinct confirmation/errors | Reservations | full Section 19 + mocked flow | keyboard/mobile/live flow | 23–25 |
| FR-10–11 | Story/mission/founder/commitment regions without invented copy | About | exact approved content | editorial layout | 22/25 |
| FR-12–14 | Automatic grid, lightbox, exact awards/reviews | Gallery | discovery/lightbox/content | crop/touch/focus | 22/25 |
| FR-15–16 | Sole Home preference form and frozen final-state semantics | Newsletter | validation/state/recovery | complete form/live persistence | 23–25 |
| NFR-01/02 | Lean assets, prompt feedback, measured—not claimed—budgets | Shell/forms | build and pending states | controlled timing | 25/integration |
| NFR-03/04 | Consistent warm visual system, obvious hierarchy/actions | All | shared primitives/states | design review | 22–25 |
| NFR-05/06 | Provisional language and distinct safe recovery | Reservation/status | stale/full/error/unknown cases | live failure review | 23–25 |
| NFR-07/08 | Modern-browser matrix and five-width responsive system | All | behavior invariant/nav states | four browsers/devices | 22–25 |
| NFR-09 | Small dependency/CSS/component/test architecture | All | focused tests/build | repository review | 22–25 |
| Rubric UI/UX, Flex/Grid, forms | Tokens, editorial layouts, explicit Grid/Flex, working-state plan | All | component/integration plans | highest-score design audit | 22–25 |
| PRA-006–013, 015–018, 025, 029 | Server-returned context/slots/time; no client rules/table choice | Reservation/Home | contract fixtures, bounds/slots/stale tests | live comparison | 23–25 |
| PRA-014, 019–024 | Structured identity, Boolean preference, pending lock, exact retry, safe confirmation/recovery | Forms/status | dirty choice, snapshot, conflict/unknown/retry tests | interruption/error flows | 23–25 |
| REACT-01 | Frozen shell/pages/components, automatic flat Gallery, complete deterministic metadata/no-metadata ordering, case-insensitive supported-extension discovery, and fallback alt | All/Gallery | architecture boundary + complete Section 14 discovery/order tests | content/crop review | 22 |
| REACT-02 | Frozen progressive order, state ownership/invalidation, focus and copy semantics | Forms | full Sections 19–20 | responsive/accessibility flow | 23–25 |

This is planned traceability only. It claims neither implementation nor conformance.

## 26. Unresolved content and technical gaps

| Gap | Blocks Prompt 22? | Latest required checkpoint | Resolution required from user |
|---|---|---|---|
| No identifiable behind-the-scenes image | It blocks claiming complete FR-12 static Gallery content, but not scaffolding the shell/discovery/lightbox | Before Prompt 22 is declared complete | Supply an approved image or explicitly approve another SRS-consistent resolution; its provenance record remains tracked separately for final delivery/INT-08 |
| Detailed founder biographies absent | It blocks claiming complete FR-11 biography content, but not the About layout using approved names/roles | Before Prompt 22 is declared complete | Supply/approve biography copy for Antonio Rossi and Maria Lopez; no facts will be invented |
| Asset provenance/licensing absent | No. It does not block Prompt 22 implementation or completion; it remains an explicitly tracked content-governance gap | Before final delivery/INT-08, preserving the frozen REACT-01 checkpoint | Supply source, owner/license, attribution requirements, and AI-generation record if applicable for each asset; do not guess |

No new business-rule ambiguity was found. The native date input, Home-only full
newsletter form, 400 ms debounce, exact breakpoints, not-found route, declarative router,
and test stack are approved and frozen technical/presentational decisions in this
artifact. None changes the frozen API or business semantics. The behind-the-scenes-image
and founder-biography gaps require separate user-supplied material or an explicit
requirements decision before Prompt 22 can be completed. Asset provenance/licensing
remains tracked but does not block Prompt 22 implementation or completion; its approved
resolution checkpoint is before final delivery/INT-08.

## 27. Approval status

**APPROVED AND FROZEN.**

REACT-03 / UI-03 passed independent review on 2026-08-24. The visual system, responsive
system, frontend toolchain, CSS architecture, Gallery runtime/discovery strategy,
accessibility criteria, and React test strategy documented here are approved and frozen.
The complete deterministic Gallery ordering algorithm in Section 14 is frozen. Vite
case-insensitive automatic discovery for the five approved Version 1 image formats
(`.webp`, `.jpg`, `.jpeg`, `.png`, and `.avif`) is frozen.

Asset provenance/licensing remains explicitly tracked for resolution before final
delivery/INT-08 and does not block Prompt 22. The behind-the-scenes-image and
founder-biography gaps remain tracked with the Prompt 22 implications and resolution
checkpoints documented in Section 26.

This approval authorizes Prompt 22 — static React application + Gallery. It does not
authorize Prompt 23 forms, Prompt 24 live integration, changes to REACT-01/02, or changes
to the frozen API, Flask, or PostgreSQL layers.
