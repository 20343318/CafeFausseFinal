# Cafe Fausse REACT-01 Architecture and Gallery Asset Analysis

**Status:** APPROVED AND FROZEN

**Increment:** REACT-01 / roadmap UI-01

**Date:** 2026-08-24

**Implementation state:** Design only; no React/JSX/CSS/JavaScript/TypeScript or build tooling exists

**Next authorized increment:** Prompt 20 - detailed reservation UX design

## 1. Baseline and approval state

Phase 0 was performed read-only before this artifact was created.

| Check | Result |
|---|---|
| Branch | `main` |
| Full HEAD | `fd2d7df7b02ad6cf56de30401c533df6bc45f450` |
| Remote relation | `HEAD`, `origin/main`, and `origin/HEAD` identify the same commit |
| Approved API-09 checkpoint | `73dbd68b6c3edd6d7aae3afb233eb4727e8cf1e2` (`API-09 and Hard Gate 2 approved`) |
| Relationship to approved checkpoint | The approved checkpoint is the immediate parent of HEAD. HEAD adds only Prompt 19 and the four initial Gallery source assets. It adds no implementation or approved-design change. |
| Hard Gate 2 | `backend/API09_VERIFICATION_REPORT.md` records API-09 as independently reviewed, approved, and frozen and explicitly authorizes the next React/JSX design increment. |
| Initial worktree/index | Clean worktree; real Git index unchanged |
| Existing frontend | Only `frontend/assets/gallery/` and its four committed WebP files |
| Existing React/build/package artifacts | None found: no package manifest, lockfile, JSX/TSX, CSS, or build configuration |
| Existing React design convention | No `docs/react-design/` convention existed; the Prompt 19 preferred path is used |

The fact that HEAD is not byte-for-byte the `73dbd68` checkpoint is expected and bounded: commit `fd2d7df` is the committed Prompt-19 input commit. This is not a conflicting baseline and introduces no work from a later increment.

## 2. Authoritative sources reviewed

Applied in the required precedence order:

1. repository-root `AGENTS.md` (no nested instruction file exists);
2. `docs/SRS(1).pdf`, all seven pages;
3. `docs/Rubric(1).pdf`, all nine pages;
4. `docs/approved-design-artifacts/Cafe_Fausse_Project_Requirements_Baseline.md`;
5. Project Requirements Addendum v2.2.1;
6. least-to-most implementation roadmap v1.1.1, especially UI-01 through UI-09;
7. approved API-01 Backend Operation Inventory v1.0.3;
8. approved API-02 Flask REST Contract v1.0.2;
9. approved API-03 Flask Architecture, Configuration, and Test Strategy v1.0.4;
10. `backend/API09_VERIFICATION_REPORT.md` and the frozen current route implementation where needed;
11. all four actual files under `frontend/assets/gallery/`;
12. Prompt 19.

No source conflict or new business-rule ambiguity was found. The SRS itself supplies the exact three awards and two reviews; these are required content, not content gaps.

## 3. Asset availability and inventory

All four actual source assets were inspected directly. Dimensions were read from each WebP header; subject, crop, quality, alt, and placement findings came from visual inspection.

| Analysis order | Exact filename | Pixels / orientation | Visible subject | Recommended uses | Crop and fit | Proposed optional metadata |
|---:|---|---|---|---|---|---|
| 1 | `home-cafe-fausse.webp` | 1792x1024, landscape (7:4) | Symmetrical, warmly lit formal dining room with chandeliers, dark wood, set tables, and no visible diners | Best Home hero candidate; Gallery ambiance; Home supporting image | `cover` is suitable for a wide hero and fixed gallery thumbnail. Keep the central chandeliers/vanishing point as the focal area. Moderate side cropping is safe; a very narrow mobile crop would remove much of the room and should use a shallower container or responsive crop treatment. Lightbox uses intrinsic proportions/`contain`. | Category `ambiance`; alt: “Warmly lit formal dining room with chandeliers and set tables.” Caption optional and probably unnecessary. |
| 2 | `gallery-cafe-interior.webp` | 1792x1024, landscape (7:4) | Formal dining room arranged with round tables, floral centerpieces, chandeliers, tall windows, and no visible diners | Gallery ambiance; strong Home supporting image; alternate hero | `cover` works for wide or landscape thumbnails. Preserve the central foreground table and chandelier; moderate edge cropping is safe, but aggressive vertical cropping loses room context. Lightbox uses intrinsic proportions/`contain`. | Category `ambiance`; alt: “Formal dining room with chandeliers, floral arrangements, and round set tables.” Caption optional. |
| 3 | `gallery-ribeye-steak.webp` | 1024x1024, square | Close view of a plated grilled steak with vegetables and herbs | Gallery menu/dish image; Menu supporting visual; Home supporting image | Square thumbnail needs little or no crop. For non-square cards, use centered `cover` conservatively so the plate edge remains visible. Aggressive landscape or portrait cropping damages the plated composition. Lightbox uses `contain`. | Category `cuisine`; alt: “Grilled ribeye steak plated with vegetables and fresh herbs.” A short caption such as “Ribeye steak” can connect it to the SRS menu without inventing preparation details. |
| 4 | `gallery-special-event.webp` | 1024x1024, square | Formal evening event in a decorated dining room with seated guests, candles, flowers, and chandeliers | Gallery special event; limited Home supporting use | Native square presentation is preferred. `cover` is safe in a square thumbnail; aggressive wide or portrait cropping would cut guests, tables, and event context. Lightbox uses `contain`. | Category `events`; alt: “Guests seated at a candlelit formal event in a flower-filled dining room.” A generic “Special event” caption is optional; identities and event type must not be asserted. |

### 3.1 Suitability summary

- All four files are suitable for high-resolution Gallery thumbnails and enlarged lightbox viewing at typical desktop viewport sizes. The 1792-pixel landscapes are strongest for wide Home presentation; the 1024-pixel square files should not be upscaled into an oversized full-bleed desktop hero.
- `home-cafe-fausse.webp` is the preferred Home hero because its wide composition, centered sight line, and open foreground tolerate responsive copy placement better than the square assets. The second interior is the strongest supporting ambiance image.
- `gallery-ribeye-steak.webp` is the only supplied food image and is a natural Menu supporting asset. Visual inspection supports “grilled ribeye steak,” but does not support claiming all SRS-listed accompaniments are present.
- The supplied set covers interior ambiance, a menu dish, and a special event. No file is visibly identifiable as behind-the-scenes activity.
- Four items do not justify visible category/filter controls. Start with a single ordered gallery. Preserve optional category metadata so filters can be introduced if a later approved collection is large and meaningfully grouped. Metadata enriches discovered assets but never controls whether a supported file appears.
- No image includes embedded project-facing provenance or licensing documentation in the repository. Source/license attribution remains a content-governance gap for later delivery documentation, not a reason to invent a source.

## 4. Flexible Gallery architecture

### 4.1 Automatic discovery and optional metadata model

Every supported image file present in `frontend/assets/gallery/` is a Gallery input and must be discovered automatically. Display inclusion comes from the discovered file set, never from a manually maintained one-entry-per-image registry. The exact build-time or runtime discovery mechanism and supported-format catalogue depend on the frontend toolchain selected in Prompt 21; this architecture does not require Vite, webpack-specific APIs, Next.js, or any other implementation mechanism. Whatever neutral mechanism is later approved must include the four current WebP files and expose a deterministic asset descriptor for every supported file in the folder.

Each discovered asset receives a normalized descriptor with a stable ID derived from its repository-relative path or filename, a resolvable asset reference, its filename, and an accessible alt value. Intrinsic dimensions may be discovered by the future asset pipeline when practical or optionally supplied as a presentational hint. These normalized descriptors, rather than optional metadata records, are what `GalleryGrid` renders.

Metadata is a separate optional enrichment map keyed deterministically to a discovered asset, such as by repository-relative filename. An image with no metadata must still appear. When present, metadata may provide or override:

| Optional field | Purpose |
|---|---|
| `order` | Explicit editorial order within the metadata-backed group |
| `alt` | Curated concise description that overrides the filename-derived fallback |
| `caption` | Additional useful context only; must not merely duplicate alt text or invent facts |
| `category` | Optional grouping such as `ambiance`, `cuisine`, or `events`; no filter is exposed for the initial four images |
| thumbnail focal position | Presentational crop hint for `cover`; defaults to center |
| placement/reuse roles | Approved reuse such as Home hero, Home support, Menu support, or Gallery |
| intrinsic dimensions or other hints | Optional layout/performance data when discovery does not provide it or curation needs an override |

Curated metadata alt text is preferred. When it is absent, derive a readable fallback strictly from the filename: remove the final extension; treat runs of hyphens, underscores, and whitespace as word separators; trim and collapse whitespace; and convert the result to readable sentence-style capitalization without adding facts. For example, `private-dining-room.webp` becomes `Private dining room`. Metadata may replace that fallback with a more descriptive factually supported alt value.

The four Prompt-19 files remain source assets at `frontend/assets/gallery/`. A future approved toolchain may retain or relocate/copy them into its runtime convention while preserving automatic folder discovery, meaning, optional metadata, and Git history where practical. Optional metadata should live in one frontend content/data module adjacent to Gallery concerns, not in a database, component body, or API. It is not a manifest of files that are allowed to render.

### 4.2 Consumption, ordering, and extensibility

- A nonvisual Gallery asset source discovers every supported file in `frontend/assets/gallery/`. A normalization/enrichment step derives the stable ID and filename alt fallback, merges any matching optional metadata, and sorts the complete result before `GalleryPage` passes it to `GalleryGrid`. `GalleryGrid` maps every normalized descriptor to a `GalleryItem` button. There is no repeated hand-written image-card markup and no required per-image registry.
- Add an ordinary approved image by placing one supported file in `frontend/assets/gallery/`. It appears without a Gallery component, route, layout, or metadata change. Optional metadata may then refine presentation, but its absence never suppresses the file.
- Ordering has two deterministic groups. All metadata-backed images appear before all images without metadata. Within the metadata-backed group, entries with explicit numeric order sort by that value; duplicate explicit values use normalized filename and then exact filename as deterministic tie-breakers. Metadata-backed entries without explicit order follow explicitly ordered entries and sort by normalized filename and then exact filename. The no-metadata group sorts by normalized filename and then exact filename. Filesystem enumeration order is never authoritative.
- The grid is content-count agnostic: one item is centered or constrained; two to four fill available columns; odd final rows remain naturally aligned; larger sets flow to additional rows.
- CSS Grid is the natural Gallery layout mechanism. Use fluid/minimum-aware columns rather than rules tied to exact counts. Thumbnail boxes use a consistent chosen aspect ratio and `object-fit: cover` with per-image focal hints; the lightbox never inherits the thumbnail crop.
- For the initial four assets, render a flat discovered collection. If later approved assets create useful groupings, an optional `GalleryFilter` can derive available categories from optional metadata and filter the same complete discovered collection. Assets without a category remain included through an ungrouped/all view. Awards and reviews remain content sections, never image categories.
- Missing metadata is normal, not an error. Prompt 21 should define tests for discovery coverage, deterministic ordering, metadata merge behavior, and filename-alt fallback. Malformed metadata or an unsupported/corrupt file may receive a deliberate development/test diagnostic or safe presentation behavior without making valid metadata a display prerequisite.

### 4.3 Lightbox boundary

`GalleryLightbox` is one shared modal instance controlled by the selected image ID/index, not one modal per card.

- Open from a semantic button that contains the thumbnail; announce the action with an accessible name.
- Close with a clearly labelled close button, Escape, backdrop/pointer behavior only if it cannot cause accidental loss, and browser-safe event handling.
- On open, store the opener and move focus into the modal, initially to the close control or modal container according to the Prompt-20/21 accessibility decision.
- Trap focus within the active modal, prevent background content from being operable, provide dialog semantics and an accessible label, and restore focus to the exact opener on close.
- Left/Right Arrow navigation is appropriate when more than one image exists. Visible previous/next controls support pointer and touch. With one image, omit both controls.
- Use bounded first/last behavior rather than implicit wrapping: disable/omit Previous on the first item and Next on the last. This is easier to understand and announce; Prompt 21 may approve wrapping only as a presentational interaction revision.
- When navigating, update the enlarged image, caption/position announcement, and accessible context without returning focus to the grid. Do not place full alt text only in a visually hidden duplicate.
- On mobile, size the dialog to the viewport, keep close/previous/next touch targets reachable, preserve image proportions with `contain`, avoid gestures as the only control, and account for viewport/safe-area constraints. Optional swipe is enhancement-only.

### 4.4 Performance design

- Preserve intrinsic dimensions to reduce layout shift. Use responsive source sizing/derivatives if the approved toolchain supports them; do not send the largest file when a much smaller thumbnail suffices.
- Load the likely Home hero eagerly/high priority only when it is actually the above-the-fold hero. Gallery images below the initial viewport should use native lazy loading; never lazy-load an immediately visible hero.
- Decode images asynchronously where supported, retain WebP delivery, and avoid duplicating identical downloads through inconsistent asset references.
- Enlarged lightbox presentation may reuse an already suitable source initially; a future larger collection can add thumbnail/large variants through metadata without component changes.
- NFR-01’s three-second load expectation requires measurement under agreed conditions in UI-09/INT-07; this architecture does not claim compliance.

## 5. Complete page architecture

### 5.1 Shared application shell

- `App`: composition root for routing, global error boundary, and shared providers that later prove necessary. It must not own restaurant business rules.
- `SiteLayout`: renders `SiteHeader`, `PrimaryNavigation`, main landmark/page outlet, and `SiteFooter` or equivalent contact/newsletter placement.
- Five addressable page routes are required: Home (`/`), Menu (`/menu`), Reservations (`/reservations`), About Us (`/about`), and Gallery (`/gallery`). A route-owned page model supports navigation, refresh, browser history, and direct links. Exact router package/build integration and not-found behavior are deferred to Prompt 21; no package is selected here.
- `SiteHeader` owns identity/home link and `PrimaryNavigation`; `MobileNavigation` is an interaction boundary within the same navigation model rather than a duplicate link source.
- Shared `ContentContainer`, section-heading patterns, buttons/links, and status primitives are justified by repeated layout/feedback needs. Do not split trivial one-use text blocks into components.
- A reusable modal foundation is justified by the Gallery lightbox and its focus/inert behavior, but only Gallery uses it in current approved scope.

### 5.2 Home

Suggested sections:

1. `HomeHero`: prominent Café Fausse identity, preferred `home-cafe-fausse.webp`, and navigation/CTA links to Menu and Reservations.
2. `RestaurantContact`: SRS address and phone. These fixed facts are also returned by OP-01/OP-05, but a single approved frontend content record may support static shell display until integration; integration must not create contradictory copies.
3. `CurrentHours`: displays current API-supplied OP-01 hours when mocked and later integrated. The SRS schedule is the seed, while PostgreSQL/Flask is authoritative under PRA-029. React must not calculate or hard-code authoritative current hours.
4. `HomeHighlights`: concise approved links/supporting imagery for Menu, About, and Gallery. `gallery-cafe-interior.webp` is the preferred ambiance support; the steak may support Menu.
5. Optional `NewsletterPreferences` placement near the page end or footer, pending Prompt 20/21 placement approval.

The name, address, phone, and required navigation are fixed SRS content. Current hours and reservation policy/context are dynamic/configurable through OP-01. Marketing copy beyond supplied SRS wording is a presentational content decision and must not invent facts.

### 5.3 Menu

- `MenuPage` owns the page heading/introduction and one data-driven SRS menu collection.
- `MenuSection` groups exactly Starters, Main Courses, Desserts, and Beverages.
- `MenuItem` presents exact name, description, and price. A compact semantic list/definition structure avoids layout-driven reading-order problems.
- `MenuFeatureImage` may use the supplied ribeye image as supporting presentation, but it does not replace or alter the exact Ribeye Steak entry.
- Menu content is fixed project content, not an API or database concern. Item names, descriptions, categories, and prices must exactly match FR-05.

### 5.4 Reservations (boundary only)

`ReservationsPage` reserves architectural regions for:

- `ReservationContextBoundary` for OP-01 current hours, timezone, policy, date range, and maximum party size;
- `AvailabilityArea` for party/date input and OP-02 slot selection;
- `CustomerAndReservationFormArea` for structured identity/contact, reservation facts, and later OP-03 status synchronization;
- `ReservationReviewArea` and submission boundary for OP-05;
- `ReservationFeedback` for loading, validation, conflict, unavailable, technical, and ambiguous states;
- `ReservationConfirmationView` for the complete OP-05 confirmation.

This document intentionally does not choose detailed date controls, validation timing, state transitions, retry wording, or a reservation state machine. Prompt 20 owns those decisions. The architecture prohibits arbitrary free-text reservation time, client-authoritative availability, table selection, and pre-success table promises.

### 5.5 About Us

- `AboutPage` owns the SRS history and mission narrative.
- `RestaurantStory` covers the 2010 founding by Chef Antonio Rossi and restaurateur Maria Lopez, the traditional-Italian/modern-innovation concept, and the exact mission supplied by FR-10.
- `FounderProfiles` provides a consistent place for each founder biography.
- `Commitments` covers unforgettable dining, excellent food, and locally sourced ingredients from FR-11.

No richer founder biography or restaurant history should be written until authoritative copy is supplied/approved.

### 5.6 Gallery

- `GalleryPage` composes `GalleryGrid`, optional future `GalleryFilter`, `GalleryLightbox`, `AwardsSection`, and `ReviewsSection`.
- A toolchain-neutral Gallery asset-source boundary supplies every automatically discovered supported file after optional metadata enrichment, fallback-alt derivation, and deterministic sorting. `GalleryGrid` and `GalleryItem` consume those normalized descriptors from Section 4, not a hand-maintained display registry.
- `AwardsSection` renders all SRS-provided awards: Culinary Excellence Award - 2022; Restaurant of the Year - 2023; Best Fine Dining Experience - Foodie Magazine, 2023.
- `ReviewsSection` renders both SRS-provided attributed reviews: “Exceptional ambiance and unforgettable flavors.” - Gourmet Review; “A must-visit restaurant for food enthusiasts.” - The Daily Bite.
- Awards and reviews use fixed SRS content and are not filters or Gallery categories.

### 5.7 Newsletter signup/preferences

`NewsletterPreferences` is a reusable feature boundary with its own form, status lookup, mutation feedback, and API adapter seams. Likely placements are a dedicated section on Home or a spacious shared footer; the SRS does not require it on every page. Use one canonical component even if an approved design later places it in more than one location.

At a high level it depends on OP-03 for existing status and OP-04 for the authoritative final preference. Detailed validation, debounce, pending, indeterminate, subscribe/unsubscribe, and recovery behavior remains Prompt 20 work.

## 6. Proposed component hierarchy

Nonvisual Gallery data flow: supported files in `frontend/assets/gallery/` -> automatic discovery -> normalized descriptors and filename-alt fallbacks -> optional metadata enrichment -> deterministic two-group sort -> `GalleryGrid`/`GalleryLightbox`.

```text
App
├── GlobalErrorBoundary
└── SiteLayout
    ├── SiteHeader
    │   ├── BrandLink
    │   └── PrimaryNavigation
    │       └── MobileNavigation (responsive boundary; same link model)
    ├── Main / route outlet
    │   ├── HomePage
    │   │   ├── HomeHero
    │   │   ├── RestaurantContact
    │   │   ├── CurrentHours
    │   │   ├── HomeHighlights
    │   │   └── NewsletterPreferences (placement proposed, not fixed)
    │   ├── MenuPage
    │   │   ├── MenuSection (repeated by category)
    │   │   │   └── MenuItem (repeated from fixed menu data)
    │   │   └── MenuFeatureImage
    │   ├── ReservationsPage
    │   │   └── ReservationFeatureBoundary
    │   │       ├── ReservationContextBoundary
    │   │       ├── AvailabilityArea
    │   │       ├── CustomerAndReservationFormArea
    │   │       ├── ReservationReviewArea
    │   │       ├── ReservationFeedback
    │   │       └── ReservationConfirmationView
    │   ├── AboutPage
    │   │   ├── RestaurantStory
    │   │   ├── FounderProfiles
    │   │   └── Commitments
    │   └── GalleryPage
    │       ├── GalleryFilter (dormant until justified)
    │       ├── GalleryGrid
    │       │   └── GalleryItem (repeated from discovered asset descriptors)
    │       ├── GalleryLightbox (single modal instance)
    │       ├── AwardsSection
    │       └── ReviewsSection
    └── SiteFooter
        ├── RestaurantContact (if approved here)
        └── NewsletterPreferences (alternative placement, not duplicate state)
```

The repeated/data-driven boundaries (`MenuSection`, `MenuItem`, `GalleryItem`) prevent duplicate markup. Gallery discovery, optional enrichment, fallback-alt derivation, and sorting form a nonvisual data pipeline rather than a manually maintained component list. Shell/navigation/contact are reused across pages. Reservation and newsletter boundaries isolate future async/API concerns. Story, awards, and reviews remain page-level sections; smaller one-use copy fragments do not need components.

## 7. Frontend data and content ownership

| Area | Owner/source | Architecture rule |
|---|---|---|
| Restaurant identity/name | Fixed SRS/project content | Prominent Home/shell presentation; one frontend content source |
| Address and phone | Fixed SRS facts; also returned by OP-01 and OP-05 | Avoid contradictory copies; use API-returned confirmation facts in confirmation and a controlled fixed content record elsewhere until integration decisions |
| Current recurring hours | Frozen Flask OP-01, sourced from PostgreSQL | Display only; no React authority or fallback that pretends defaults are current |
| Menu categories/items/descriptions/prices | Fixed SRS content | Static data-driven collection; no API/CMS |
| About history/mission/commitments | Fixed SRS content | Static approved copy |
| Founder biography detail beyond SRS | Missing authoritative content | Keep boundary; do not invent copy |
| Gallery image binaries and display inclusion | All supported static files automatically discovered from `frontend/assets/gallery/` | The folder contents are the inclusion source; build/runtime discovery mechanism is selected later; no API/database or required per-image registry |
| Gallery alt/caption/category/order/focal/dimension/reuse hints | Filename-derived alt fallback plus optional local presentational metadata | Curated metadata enriches/overrides discovered descriptors but never determines inclusion; categories remain optional |
| Awards and reviews | Fixed exact SRS content | Static content sections |
| Reservation context/configuration | OP-01 | Server-authoritative snapshot; React renders and uses it for usability only |
| Reservation availability | OP-02 | Provisional server snapshot; React never calculates availability |
| Reservation identity/contact and selection | Future user input plus OP-02-selected facts | Client holds form state; Flask revalidates |
| Newsletter status | OP-03 | Snapshot/possibly indeterminate; not a local truth |
| Newsletter preference | Future user input; OP-04 or booking-linked OP-05 result is authoritative | Replace local pending intent with successful returned state |
| Reservation submission/reconstruction | OP-05 | Sole booking authority; React submits ordinary facts, never table/capacity/fingerprint authority |
| Reservation confirmation | OP-05 success | Render all returned confirmation facts; no email/SMS delivery claim |
| Liveness/readiness | OP-06/OP-07 infrastructure | Never normal customer-page content or navigation |

## 8. Responsive architecture

- Use a mobile-first, content-driven breakpoint strategy. Add layout transitions where navigation, menu columns, gallery cards, or line lengths stop working, rather than declaring arbitrary device-specific pixel requirements now. Prompt 21 will approve exact breakpoint/test values.
- Constrain reading content to a comfortable maximum width while allowing controlled full-width imagery. Use consistent gutters that shrink safely without horizontal scrolling.
- Desktop navigation may remain inline; smaller viewports use one mobile navigation boundary with the same destinations and active-page semantics. Its exact disclosure interaction is deferred.
- Gallery: fluid Grid columns; typically one column at narrow widths, increasing as card minimum width permits. One to four assets and odd final rows require no special-case markup. Enlarged images stay within viewport width/height using `contain`.
- Menu: stack categories/items on narrow screens; allow multiple columns only where name, description, and price retain logical reading order and do not collide. Prices should remain associated with their item without forcing horizontal scroll.
- Images always scale within their containers. Thumbnail crops are deliberate; content images preserve intrinsic aspect ratio where crop would harm meaning.
- Future form controls and modal actions must be touch-friendly and usable in portrait/landscape. No hover-only information or swipe-only navigation.
- Validate Chrome, Firefox, Safari, and Edge behavior later using the Prompt-21/UI-09 browser matrix; architecture avoids browser-specific APIs without fallbacks.

## 9. Accessibility architecture

- Use one banner, primary labelled navigation, main landmark, and contentinfo/footer where present. Each route has one descriptive page-level heading and a logical descending heading structure.
- The logo/name home link and navigation links have clear accessible names and visible active/focus states. Mobile navigation must expose expanded state and return focus appropriately when closed.
- Gallery thumbnails are semantic buttons because they open dialogs; alt text describes the image, while control naming communicates “open enlarged image” without redundant verbosity.
- Lightbox uses modal dialog semantics, a labelled close control, Escape, keyboard previous/next controls, a contained focus order, background inertness, focus entry, and exact focus return. Status such as image position can be announced without repeatedly announcing decorative text.
- Visible focus must never rely only on color. Selected, unavailable, success, error, and pending states require text/icon/semantic cues in addition to color.
- Decorative imagery uses empty alt only when it truly adds no content and duplicates nearby text. Every current Gallery image is content-bearing and should use the inspected curated alt text in Section 3. Any future discovered image without curated alt metadata receives the readable, fact-limited filename fallback defined in Section 4.1 rather than being omitted or rendered without an accessible name.
- Touch controls need adequate separation/target size; exact metrics belong to Prompt 21. Zoom, text scaling, and reflow must not create horizontal page scrolling.
- Later animation honors reduced-motion preferences. Essential state changes cannot depend on motion.
- Friendly messages and future loading/success/error regions need appropriate live/status semantics, focus behavior, and persistent text. Exact interaction behavior is deferred to Prompt 20.
- This architecture makes accessibility provisions but does not claim WCAG certification or a verified conformance level.

## 10. High-level React/API boundary

| Operation | Future UI consumer | Permitted React responsibility | Prohibited React authority |
|---|---|---|---|
| OP-01 `GET /api/v1/reservation-context` | Home `CurrentHours`; reservation context | Render current contact/hours/timezone/policy/date bounds/maximum party size; provide usability constraints | Hard-coded authoritative hours, timezone, booking window, lead time, interval, duration, capacity, or server clock |
| OP-02 `GET /api/v1/reservation-availability` | `AvailabilityArea` | Request by restaurant-local date/party size; render every returned slot and provisional availability; preserve supplied local start/offset for later submission | Generate slots, calculate availability/end time/offset, hide required unavailable slots, promise/hold a table, choose a table |
| OP-03 `POST /api/v1/newsletter-status-queries` | Reservation and newsletter identity boundaries | Request minimal status after valid identity; represent matched/not-found/indeterminate | Profile lookup/prefill, identity ownership claim, local state as authority |
| OP-04 `POST /api/v1/newsletter-preferences` | `NewsletterPreferences` | Submit explicit final Boolean and render returned authoritative state | Newsletter history, customer/profile updates, optimistic state treated as committed |
| OP-05 `POST /api/v1/reservations` | Reservation submit/confirmation | Submit ordinary selected and customer facts; render created/exact-retry confirmation or structured recovery state | Allocation, overlap, capacity, retry identity/fingerprint, end/duration, table choice, booking transaction semantics |
| OP-06/OP-07 health | Infrastructure only | None in customer pages | Navigation, status banner, diagnostics, business readiness inference |

All workflow responses are no-store snapshots/results under the frozen contract. Same-origin integration, API adapter details, development proxy, and live connection remain later increments. React must never become authoritative for interval, duration, booking-window, lead-time, timezone/clock, capacity, allocation, overlap, customer matching, retry identity, or transaction semantics.

## 11. Architecture-level requirements traceability

| Page/component area | SRS / baseline | NFR / rubric | Addendum | Flask boundary | Status / deferral |
|---|---|---|---|---|---|
| `App` / routes / shell / navigation | FR-01, FR-02, FR-04; FS-01; UI-01/02/04 | NFR-03/04/07-11; score-5 five React/JSX pages and Flexbox/Grid | PRA-001-004, PRA-029 | OP-01 for current hours | Architecture addressed; router/toolchain and detailed visual system Prompt 21; implementation Prompt 22+ |
| Home hero/contact/hours/highlights | FR-01-04 | NFR-01/03/04/08/11; rubric imagery/UX | PRA-029 | OP-01 | Content/asset placement addressed; styling/tests later |
| Menu data/sections/items | FR-05 | NFR-03/04/08/09/11; all-SRS rubric criterion | PRA-004 | None | Exact content ownership and component boundaries addressed; implementation later |
| Reservations boundary | FR-06-09, FR-18 | NFR-02/03/05/06/08/09; working-form/integration/sophisticated-logic rubric | PRA-006-025, PRA-029 | OP-01/02/03/05 | Boundary addressed; detailed UX/state explicitly Prompt 20; tests/visual system Prompt 21; implementation later |
| About story/founders/commitments | FR-10/11 | NFR-03/04/08/09/11; all-SRS rubric criterion | PRA-004 | None | Required homes addressed; missing biography copy recorded |
| Gallery discovery/grid/optional metadata | FR-03, FR-12 | NFR-01/03/04/07-11; images/Flexbox/Grid/UX rubric | PRA-004 | None | Every supported folder asset is included automatically; optional enrichment, deterministic two-group ordering, filename-alt fallback, and a flat count-agnostic grid are addressed; implementation later |
| Gallery lightbox | FR-13 | NFR-03/06-09; rubric UX | PRA-003/004 | None | Architecture/keyboard/focus boundary addressed; interaction detail/tests later |
| Awards/reviews | FR-14 | NFR-03/04/08/09/11; all-SRS rubric criterion | PRA-004 | None | Exact supplied SRS content assigned; implementation later |
| Newsletter boundary | FR-15/16, FS-02 | NFR-02/03/05/06/08/09; working form and integration rubric | PRA-019-025 | OP-03/04; OP-05 only for booking-linked preference | Reusable boundary/ownership addressed; detailed UX Prompt 20; implementation later |
| Shared status/error primitives | FR-09/15; API-06/UI-07 | NFR-06/08/09; rubric working forms/UX | PRA-014, PRA-021, PRA-023-025 | Structured OP-01-05 results/errors | Architecture only; exact mapping/focus/retry UX Prompt 20 |
| Responsive and browser boundaries | All page-applicable FRs | NFR-01/03/04/07/08/10/11; rubric excellent UI/UX and Flexbox/Grid | PRA-023/025 | No business authority | Strategy addressed; exact breakpoints/matrix Prompt 21; verification UI-09/INT-07 |

This matrix records architectural coverage only. It does not claim React implementation or SRS/rubric compliance.

## 12. Content gaps and decisions

| Gap/decision | Classification | Disposition |
|---|---|---|
| No clearly identifiable behind-the-scenes image, although FR-12 names behind-the-scenes activity | Implementation-independent content gap | Obtain an approved image before static Gallery completion or explicitly approve how FR-12 will be satisfied. Do not relabel the special-event image as behind-the-scenes. |
| Founder biographies beyond names/roles and the brief history/mission in FR-10/11 | Implementation-independent content gap | Obtain approved biography copy; do not invent personal histories, credentials, or quotations. |
| Asset source/licensing/attribution record is not present | Implementation-independent content-governance gap | Record provenance/license before final delivery/INT-08; do not guess. |
| Exact caption wording | Future presentational decision | Captions are optional for this set; approve only factual wording derived from visible/SRS content. |
| Whether/where Newsletter appears (Home section or footer) | Future presentational/UX decision | Resolve in Prompt 20/21; the SRS does not require every-page placement. |
| Exact router/build tool, route-not-found behavior, breakpoints, palette, typography, spacing, navigation disclosure, and browser/device matrix | Future technical/presentational decisions | Resolve in Prompt 21; no package/toolchain selected here. |
| Category filter introduction threshold and exact labels | Future presentational decision | No filter initially. Add only when a larger approved collection makes categories useful. Metadata already permits it. |

The exact awards and customer reviews are not gaps: the SRS supplies all required names, years, quotations, and attributions. No business-rule ambiguity requiring approval was found.

## 13. Decisions deferred to Prompt 20 and Prompt 21

### Prompt 20 - reservation/newsletter/accessibility UX

- Detailed reservation sequence, control behavior, validation timing, loading/stale states, state transitions, retry/recovery wording, confirmation transitions, and focus/error behavior.
- Newsletter lookup/mutation flow, debounce/stale-response behavior, checkbox semantics, pending/success/error/indeterminate presentation, and final placement recommendation.
- Detailed mobile navigation and form/lightbox interaction wireflows where they intersect accessibility.

### Prompt 21 - complete UI/UX and React test strategy

- Brand palette, typography, spacing, surfaces, visual hierarchy, exact responsive breakpoints/viewports, and browser matrix.
- React framework/build tool/router/package decisions, CSS organization, runtime asset convention, not-found behavior, and detailed component test plan.
- Exact modal styling/animation, reduced-motion treatment, touch-target metrics, content fallback presentation, image optimization plan, and performance test conditions.

Prompt 22+ owns code and implementation. Live Flask connection begins only after the approved React gate according to the roadmap.

## 14. Unresolved blockers and approval status

No blocker remained at the REACT-01 approval checkpoint. The three implementation-independent content gaps in Section 12 remain tracked and must be resolved before the affected final static content/delivery checkpoints. None is a new business-rule ambiguity, and none justifies fabricating content.

**Approval status: APPROVED AND FROZEN.**

REACT-01 / roadmap UI-01 passed independent review on 2026-08-24. The React architecture and Gallery asset-analysis design in this artifact are approved and frozen.

The approved Gallery rule is frozen as follows:

- every supported image in `frontend/assets/gallery/` is included automatically through the toolchain-neutral discovery boundary;
- optional metadata enriches discovered images and does not control inclusion;
- metadata-backed images sort before images without metadata, with the deterministic within-group ordering defined in Section 4.2; and
- when curated metadata alt text is absent, the readable filename-derived alt text defined in Section 4.1 remains the accessibility fallback.

This approval authorizes Prompt 20 - detailed reservation UX design. It does not authorize React implementation, Prompt 21 toolchain/visual-system work, live Flask integration, or any change to the frozen backend, API, or database layers.
