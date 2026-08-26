# Cafe Fausse Prompt 26 Requirements, Rubric, and Traceability Audit

**Status:** APPROVED AND FROZEN

**Audit date:** 2026-08-26

**Approval record:** Independent ChatGPT review accepted the corrected audit, and the user explicitly approved and froze Prompt 26 on 2026-08-26. This approval accepts the audit’s findings and classifications; it does not assert that every project requirement, verification gate, documentation obligation, demo obligation, or submission action is already closed.

**Authorized increment:** Prompt 26 only; audit-only; Prompt 27 and Prompt 28 have not begun.

## 1. Baseline and checkpoint

The user-authorized corrected Prompt-26 execution baseline is `e4011c1f23837c4448b9f7762683c8c84b7dc44d` (`Create Prompt-26-Complete-Requirements-Rubric-Traceability-Audit.md`). It is the direct child of approved Prompt-25 checkpoint `659165d13496302dfac6ce5b94c15f0e1e5a983e`; the only change between them is `docs/prompts/Prompt-26-Complete-Requirements-Rubric-Traceability-Audit.md`.

At audit start, branch `main`, `HEAD`, and `origin/main` all equalled the corrected baseline; the worktree and real Git index were clean. `docs/integration-verification/Cafe_Fausse_Prompt25_Full_Integration_Verification.md` recorded Prompt 25 as **APPROVED AND FROZEN**. No Prompt-27 README/AI-tooling artifact or Prompt-28 demo artifact existed.

The user later created `docs/demo/Cafe_Fausse_FR17_Demo_Queries.md` as an intentional read-only final-demo reference for the approved normalized FR-17 relation. It is outside the Prompt-26 review delta, is not modified by this audit, and does not by itself begin Prompt 28.

## 2. Authority, precedence, and scope

This audit applies, in order: repository instructions; `docs/SRS(1).pdf`; `docs/Rubric(1).pdf`; Project Requirements Addendum (PRA) v2.2.1; the approved Game Plan/roadmap; frozen PostgreSQL, API, React, and Prompt-25 artifacts; then the current committed implementation, tests, instructions, and configuration.

The SRS and rubric control over supplemental interpretations. The user has authoritatively accepted the normalized Reservation-to-Table Number relation as satisfying FR-17 because neither authority explicitly requires a physical scalar `reservations.table_number` column or prohibits normalization. Where the SRS leaves capacity and allocation details unspecified, the approved PRA may supply compatible rules without weakening an explicit requirement. The internal grading caveat and planned direct-database demonstration for FR-17 remain documented below.

Prompt 26 changed no production code, tests, configuration, frozen artifact, dependency, README, AI-tooling file, asset, or database. No live PostgreSQL, Flask, Vite, or browser process was started. Frozen verification results were reused; only read-only/static inspection and PDF/asset inspection were performed.

## 3. Methodology, evidence key, and status definitions

Each obligation was decomposed, traced through legitimate layers, checked against implementation rather than design alone, and classified using exactly:

- **Fully satisfied** — the complete obligation is implemented and sufficiently evidenced.
- **Partially satisfied** — implementation/evidence covers only part, or required manual/documentation/submission proof remains.
- **Not satisfied** — the required implementation or evidence is absent or contradictory.
- **Not applicable** — the obligation genuinely does not apply; every use below states why.

Open items use one primary category: implementation defect/gap; verification/evidence gap; documentation gap; or demo/submission/manual-action gap.

Evidence abbreviations used in dense matrices:

| Key | Committed evidence |
|---|---|
| DB | `database/migrations/002_foundation_tables.sql`, `003_baseline_seed.sql`, `005_reservation_tables_and_indexes.sql`, `007_availability_and_controlled_writers.sql`, `008_authoritative_booking.sql`, `011_allocator_exact_fast_paths.sql` |
| DBV | `database/DB07_VERIFICATION_REPORT.md`, `database/DB07_MANUAL_DEMONSTRATION.md`, `database/verification/verify_db05.sql`, `verify_db06.sql`, `verify_db07.sql`, `database/tests/db05_behavior_tests.sql`, `db06_behavior_tests.sql`, `db07_behavior_tests.sql` |
| API | `backend/src/cafe_fausse/http/routes/`, `services/`, `db/`, `validation/`, and `serialization/` |
| APIV | `backend/API09_VERIFICATION_REPORT.md` and named files under `backend/tests/` |
| R4 | `docs/react-implementation/Cafe_Fausse_REACT04_Static_Application_and_Gallery_Implementation.md` and static React source/tests |
| R5 | `docs/react-implementation/Cafe_Fausse_REACT05_Reservation_and_Newsletter_Mocked_UI_Implementation.md` and form/component tests |
| R6 | `docs/react-implementation/Cafe_Fausse_REACT06_Live_Flask_Integration_Implementation.md`, live adapter/tests, and live verification tooling |
| P25 | `docs/integration-verification/Cafe_Fausse_Prompt25_Full_Integration_Verification.md` and `frontend/scripts/verify-full-integration*.{ps1,mjs}` |

“Manual” below means committed engineering/browser/manual evidence, not the unrecorded final rubric presentation. “Demo” distinguishes existing demonstration capability from the final Prompt-28 recording, which has not occurred.

## 4. SRS functional requirements FR-1 through FR-18

| Requirement | Exact SRS obligation | PostgreSQL | Flask | React | Automated tests | Manual verification | Demo evidence | Status | Gap / rationale |
|---|---|---|---|---|---|---|---|---|---|
| FR-1 | Display Café Fausse prominently. | N/A — static content. | N/A — static content. | `HomePage.jsx` H1. | `AppRoutes.test.jsx` “renders exact Home identity…” | R4 Chrome/Edge five-route checks. | Prompt 28 must show Home. | Fully satisfied | Exact name is present and prominent. |
| FR-2 | Exact address, phone, and Monday-Saturday/Sunday hours. | Seven authoritative hours rows seeded in DB. | OP-01 reads current schedule. | `HomePage.jsx`, `restaurant.js`, `CurrentHours.jsx`. | `AppRoutes.test.jsx`; `CurrentHours.test.jsx`; `verify_db05.sql` exact seed; P25 scenario 4. | R6/P25 Chrome and Edge rendered restored live hours. | Show contact and live SRS schedule. | Fully satisfied | Address/phone are exact; normal DB seed exactly matches SRS hours. |
| FR-3 | High-quality images and consistent theme. | N/A — UI/content. | N/A — UI/content. | Five high-resolution WebPs; tokenized visual system/CSS. | Route, Gallery, build, and asset-discovery tests. | R4 responsive Chrome/Edge evidence; Prompt-26 visual inspection. | Show Home/Gallery visual quality. | Fully satisfied | Quality/use is evidenced; the four supplied-input and one AI-generated source categories are established. |
| FR-4 | Links to Menu, Reservations, About Us, and Gallery. | N/A — UI. | N/A — UI. | `App.jsx`, `navigation.js`, `SiteHeader.jsx`. | `AppRoutes.test.jsx`; `SiteHeader.test.jsx`. | R4/R6 Chrome/Edge navigation. | Navigate all five pages. | Fully satisfied | Canonical shared navigation works. |
| FR-5 | Exact four menu categories, eleven items, descriptions, and prices. | N/A — static content. | N/A — static content. | `content/menu.js`, `MenuPage.jsx`. | `AppRoutes.test.jsx` “renders every exact Menu…” | R4 five-route checks. | Show Menu categories/items. | Fully satisfied | Static inspection matches every SRS value. |
| FR-6 | Reservation fields: date/time, guests, name, email, optional phone. | Customer/reservation facts persisted. | OP-01/02/03/05 accept/revalidate approved facts. | `ReservationFeature.jsx` supplies date, server slot, party, structured name, email confirmation, optional phone. | `ReservationFeature.test.jsx`; `validation.test.js`; API validation tests. | R5/R6 Chrome/Edge complete flows. | Complete a booking. | Fully satisfied | Structured name and confirmation email are additive; required facts are present. |
| FR-7 | Validate selected slot is valid and available. | `provisional_availability`; `book_reservation` revalidates current facts atomically. | OP-02 provisional slots; OP-05 authoritative validation. | Only API slots; unavailable disabled; refetch/recovery. | `test_reservation_discovery_postgresql.py`; `test_reservation_discovery.py`; `ReservationFeature.test.jsx`; P25 scenarios 3, 7, 8. | R6/P25 live full and manipulated-slot evidence. | Show available, full, and rejected invalid slot. | Fully satisfied | Both UX and authoritative enforcement are proven. |
| FR-8 | Backend assigns a random table from a total of 30 when available. | Exactly 30 seeded; allocator chooses minimum table count, least waste, then random tie among equally optimal choices; assignments normalized. | OP-05 invokes DB allocation and returns all assigned numbers. | No table choice; confirmation shows one or more assigned numbers. | DBV allocation/random tests; `test_booking_creates_customer_and_atomic_reservation_then_exact_retry_reconstructs`; P25 scenarios 5-7. | DBV single/multi/all-table demonstrations; P25 party-of-6 got two tables. | Show assignment and capacity-aware logic honestly. | Fully satisfied | The SRS does not require exactly one table per reservation, define capacity, demand uniform choice across all available tables, or prohibit combined tables. PRA-018 validly fills those gaps while retaining random selection among equally suitable/optimal choices. |
| FR-9 | Success on booking or error if slot fully booked. | Stable `booked`/`exact_retry`/`unavailable` outcomes with rollback. | OP-05 maps confirmation and `reservation_unavailable`. | Distinct confirmation; all-unavailable and booking error states. | `test_booking_success_contract`; `test_booking_business_outcomes`; `MockedPageFlows.test.jsx`; P25 scenario 7. | R6/P25 Chrome/Edge success/full evidence. | Show success and fully booked behavior. | Fully satisfied | Required outcomes and user messages exist. |
| FR-10 | Exact 2010 founders/history/mission substance. | N/A — static content. | N/A — static content. | `AboutPage.jsx`; Home story. | `AppRoutes.test.jsx` About-content test. | R4 route evidence. | Show About. | Fully satisfied | Text preserves every required fact without invented biography facts. |
| FR-11 | Founder biographies and commitments to unforgettable dining, excellent food, local sourcing. | N/A — static content. | N/A — static content. | `AboutPage.jsx` founder cards and commitments. | `AppRoutes.test.jsx` About-content test. | R4 route evidence. | Show founders/commitments. | Fully satisfied | Both founders and all required commitments are explicit. |
| FR-12 | High-resolution interior, menu dish, special-event, and behind-scenes images. | N/A — assets/UI. | N/A — assets/UI. | Five WebPs and `gallery-metadata.js`; all four categories covered. | `gallery-discovery.test.js`; `GalleryPage.test.jsx`; build. | R4 and Prompt-26 visual inspection. | Show all Gallery categories. | Fully satisfied | Images are 1024-1792 px and visibly cover the categories. |
| FR-13 | Enlarged-image lightbox. | N/A — UI. | N/A — UI. | `GalleryLightbox.jsx`. | `GalleryLightbox.test.jsx`; `GalleryPage.test.jsx`. | R4 Chrome/Edge keyboard/focus verification. | Open/operate lightbox. | Fully satisfied | Accessible bounded lightbox is implemented. |
| FR-14 | Exact three awards and two attributed positive reviews. | N/A — static content. | N/A — static content. | `restaurant.js`, `AwardsAndReviews.jsx`. | `AppRoutes.test.jsx` exact awards/reviews. | R4 route evidence. | Show Gallery recognition. | Fully satisfied | Exact names, years, quotes, and sources match. |
| FR-15 | Newsletter form with proper email-format validation. | Canonical email constraints and newsletter Boolean. | OP-03/04 authoritative validation. | `NewsletterPreferences.jsx`; immediate validation and confirmation. | `validation.test.js`; `test_validation_identity.py`; `NewsletterPreferences.test.jsx`; P25 scenario 2. | R6/P25 live valid/conflict/invalid paths. | Submit valid and invalid cases. | Fully satisfied | Client and server validation are proven. |
| FR-16 | Submitted emails stored in backend DB for marketing. | `customers.email` plus authoritative `newsletter_subscribed`. | OP-04 persists; OP-03 reads. | Home preferences form uses live client. | Newsletter PostgreSQL suites; P25 scenarios 1, 2, 12. | P25 direct SQL `1|Prompt|M|Twentyfive|t`. | Show form then direct SQL state. | Fully satisfied | Persistence and idempotency are proven. |
| FR-17 | Customers table has ID, Customer Name, Email, Phone, Newsletter Signup; Reservations table has ID, Customer ID, Time Slot, Table Number. | Reservation-level facts are in `reservations`; all Table Number facts are authoritatively normalized in `reservation_table_assignments` and joined by `reservation_id`. | Gateways return the complete assigned-table set from the normalized relation. | Confirmation displays all assigned table numbers. | `verify_db05.sql`, `verify_db06.sql`, DBV catalogue; P25 exact application-to-PostgreSQL table-set comparison. | DBV catalogue/manual row inspection; P25 direct SQL. | Show React confirmation, matching reservation/assignment rows, and optional joined aggregate. | Fully satisfied | The complete one-or-more Table Number relationship is preserved and demonstrated; neither authority requires a physical scalar column or prohibits normalization. Strict reconciliation is in §5. |
| FR-18 | Flask inserts customer, checks selected-slot availability, assigns random table from 30, returns confirmation/error. | Atomic routine performs all persistence and capacity-aware randomized allocation. | OP-05/service/gateway implement the complete workflow. | Live form consumes the result. | `test_reservation_creation_postgresql.py`; `test_reservations.py`; cross-operation tests; P25 scenarios 5-10. | R6/P25 live evidence. | Show booking, DB effect, full error, and sophisticated logic. | Fully satisfied | Insert/check/assignment/message behavior is complete; PRA-018 supplies capacity and multi-table details that the SRS leaves unspecified without contradicting an explicit one-table rule. |

**FR totals:** Fully satisfied 18; Partially satisfied 0; Not satisfied 0; Not applicable 0.

## 5. Strict FR-17 database reconciliation

| SRS-required fact | Actual authoritative storage location | Equivalent business fact preserved? | Evidence | Compliance conclusion |
|---|---|---|---|---|
| Customer ID | `customers.customer_id` | Yes | migration 002; DBV catalogue | Literal/equivalent. |
| Customer Name | `customers.first_name`, nullable `middle_initial`, `last_name` | Yes | migration 002; PRA-019 tests; API confirmation composition | Normalized structured fields collectively preserve the name. |
| Email Address | `customers.email` | Yes | migration 002; newsletter/reservation integration tests | Literal/equivalent. |
| Phone Number | `customers.phone` | Yes | migration 002; phone validation/preservation tests | Literal/equivalent and optional as required by FR-6. |
| Newsletter Signup | `customers.newsletter_subscribed` | Yes | migration 002; OP-04/P25 SQL | Boolean wording differs but fact is exact. |
| Reservation ID | `reservations.reservation_id` | Yes | migration 005; P25 SQL | Literal/equivalent. |
| Customer ID | `reservations.customer_id` | Yes | migration 005; FK verification | Literal/equivalent. |
| Time Slot | `reservations.starts_at` and `reservations.ends_at` | Yes | migration 005; interval/overlap tests | A more precise interval preserves date/time and occupancy. |
| Table Number | One or more rows in `reservation_table_assignments.table_number` keyed to `reservations.reservation_id` | Yes, completely | migration 005; DBV no-overlap/assignment checks; Flask complete assigned-table response; React complete confirmation; P25 exact table-set comparison | Fully satisfied. Neither authority explicitly requires physical scalar placement; the normalized relation authoritatively preserves every assigned Table Number. |

**Conclusion:** the user has approved FR-17 as **Fully satisfied** by the current normalized representation. `reservations` stores reservation-level facts; `reservation_table_assignments` is the authoritative one-to-many Table Number relation; and joining on `reservation_id` reconstructs the complete allocation. This intentional relational implementation is semantically more complete for multi-table reservations than a scalar compatibility witness. No migration, view, derived/array/encoded column, PostgreSQL/Flask/React reopening, or Prompt-25 reverification is required.

The final demo may create a reservation in React, show every assigned table number in its confirmation, show the matching PostgreSQL rows, and optionally run this read-only evidence query after substituting the displayed reservation reference:

```sql
\set reservation_reference 123

SELECT
    r.reservation_id,
    r.customer_id,
    r.starts_at AS time_slot_start,
    r.ends_at AS time_slot_end,
    string_agg(
        rta.table_number::text,
        ', ' ORDER BY rta.table_number
    ) AS table_number
FROM cafe_fausse.reservations AS r
JOIN cafe_fausse.reservation_table_assignments AS rta
  ON rta.reservation_id = r.reservation_id
WHERE r.reservation_id = :'reservation_reference'::bigint
GROUP BY
    r.reservation_id,
    r.customer_id,
    r.starts_at,
    r.ends_at;
```

**Internal grading caveat:** an unusually schema-literal reviewer could initially expect a direct scalar column. This is not an FR-17 defect, blocker, partial classification, or reason to alter the database. The demo should proactively explain and demonstrate the normalized relation so the complete Reservation-to-Table Number fact is unmistakable.

The user-created `docs/demo/Cafe_Fausse_FR17_Demo_Queries.md` separately retains the approved read-only demonstration queries. It is an intentional demo-reference artifact, not an FR-17 implementation change, Prompt-26 audit output, or path in `Prompt26-review-candidate.diff`.

## 6. Strict FR-8/FR-18 random-table reconciliation

- Exactly 30 bookable records exist: migration 003 seeds table numbers 1-30 at capacity four; `verify_db05.sql` checks exact `30 x 4` and total 120; booking refuses incomplete inventory.
- The SRS's grammatical singular “a random table” identifies the assigned object but does not explicitly say that every reservation must receive exactly one table regardless of party size. It defines neither seating capacity nor a one-table maximum party size, uniform randomness across every available table, nor a prohibition on combining tables.
- PRA-015 through PRA-018 therefore fill genuine unspecified capacity/allocation details: for an initial-capacity party of 1-4, minimum table count is one and every equally suitable free capacity-four table participates in random tie selection.
- For larger parties, PRA-018 permits multiple exclusive tables. The allocator minimizes number of tables, then unused seating, and randomizes among equally optimal combinations (`select_table_allocation`, migrations 006/011).
- A reservation can therefore receive multiple table numbers. P25 deliberately proved a party of six received two (`12,25`).
- Atomic exclusivity, no shared overlap, all-or-none assignment, and full behavior are strongly implemented and evidenced.

**Conclusion:** no explicit SRS or rubric requirement says every reservation must receive exactly one table, prohibits multiple tables, or requires uniform random selection across candidates of differing suitability. The approved PRA compatibility interpretation preserves random selection for single-table bookings and random tie-breaking for equally optimal combinations while supplying otherwise unspecified capacity rules. FR-8 and FR-18 are **Fully satisfied**, and PRA-018 is not an SRS/rubric contradiction.

## 7. SRS NFR-1 through NFR-9

| Requirement | Obligation | Implementation/evidence | Manual evidence | Status | Gap / rationale |
|---|---|---|---|---|---|
| NFR-1 | Website loads within 3 seconds on standard broadband. | Build sizes exist, but no qualifying page-load measurement exists. The approved verification target is one concurrent user—the final-demo use case—on the actual Codex/demo VM under normal conditions, without invented numeric bandwidth or artificial network/CPU throttling. | None establishing this exact requirement. | Partially satisfied | Verification/evidence gap; API timing is not page-load timing. INT-07 must measure the required pages against 3 seconds and record enough methodology/environment detail to make the evidence reproducible. Cache state, timing boundaries, and sampling are test-method choices, not added SRS/rubric requirements. |
| NFR-2 | Reservation and newsletter submissions processed within 2 seconds. | API-09 sequential Flask/PostgreSQL maxima <0.5 s; R6/P25 live Vite operation maxima <0.5 s. DBV records contention/timeout paths over 2 s. The approved verification target is one concurrent user on the actual normally operating Codex/demo VM. | Live workflows completed, but browser submit-to-final-state duration was not measured. | Partially satisfied | Strong ordinary-path evidence, but no exact end-to-end result for both forms. INT-07 must measure each against 2 seconds and record reproducible boundaries/sampling/environment. Those methodology choices are evidence procedure, not new project requirements. |
| NFR-3 | Intuitive/easy navigation. | Shared five-link shell, active state, route focus/title, mobile disclosure, skip link. | R4 Chrome/Edge route/navigation/focus checks. | Fully satisfied | Multiple viewport/browser and semantic tests support the claim. |
| NFR-4 | Consistent, visually appealing brand design. | Frozen token/type/spacing system and consistent CSS across routes. | R4 Chrome/Edge visual/responsive evidence; Prompt-26 asset inspection. | Fully satisfied | Current evidence supports consistent polished design. |
| NFR-5 | Integrity; prevent double/overbooking. | DB constraints, atomic booking, exclusive assignments, locks, rollback, retries. | DBV/P25 overlap/full demonstrations. | Fully satisfied | Extensive concurrency evidence proves committed-state integrity. |
| NFR-6 | User-friendly failure handling. | Safe API envelopes, redacted logging, accessible React error/recovery/unknown states. | R6/P25 transport/full/conflict recovery. | Fully satisfied | Technical details are withheld and recovery is actionable. |
| NFR-7 | Chrome, Firefox, Safari, Edge compatibility. | Chrome and Edge live/full evidence only. | Chrome 151 and Edge 151 passed; Firefox/Safari explicitly deferred. | Partially satisfied | Manual Firefox and Safari evidence is missing; not a proven code defect. |
| NFR-8 | Responsive desktop/tablet/smartphone. | Mobile-first CSS at representative 320/390/768/1280/1440 widths. | R4/R5/R6 Chrome/Edge no-overflow and column matrices. | Fully satisfied | Phone/tablet/desktop responsive evidence is sufficient. |
| NFR-9 | Modular, well-documented, maintainable code. | Separate DB migrations/routines, Flask routes/services/gateways/validation, React pages/features/forms/API/styles; extensive layer instructions/reports. | Frozen independent reviews and complete test instructions. | Fully satisfied | Root deployment documentation is a separate explicit requirement and remains open. |

**NFR totals:** Fully satisfied 6; Partially satisfied 3; Not satisfied 0; Not applicable 0.

The authoritative performance requirements are limited to NFR-1’s page-load-within-3-seconds outcome on “standard broadband” and NFR-2’s reservation/newsletter-processing-within-2-seconds outcome. Neither source specifies a concurrent-user count, numeric bandwidth/latency profile, throttling, cache state, timing instrumentation, sample count/percentile, or VM allocation. The approved evidence basis is exactly one concurrent user on the actual Codex/demo VM under normal conditions, initially without artificial network or CPU throttling. A later verifier must choose and document reasonable reproducible measurement mechanics, but those mechanics do not become project requirements. Vertical scaling may later be used if necessary; it is neither required nor part of this audit update, and any later evidence must truthfully identify the environment that produced it. No performance measurement was run during this task.

## 8. External-interface and deployment audit

| ID | Obligation | Evidence | Status | Gap / rationale |
|---|---|---|---|---|
| IF-1 | Clean, modern, responsive React + JSX UI. | `frontend/src/main.jsx`, `App.jsx`, page/component JSX; R4-R6. | Fully satisfied | Five-page live UI exists. |
| IF-2 | CSS uses Flexbox or Grid consistently. | `frontend/src/styles/*.css`; R4 §6. | Fully satisfied | Both mechanisms are used appropriately. |
| IF-3 | Flask API processes form submissions. | `backend/src/cafe_fausse/application.py`, HTTP routes; API-09. | Fully satisfied | OP-03/04/05 plus health/discovery are live. |
| IF-4 | PostgreSQL manages customer/reservation data. | DB migrations, routines, P25 direct SQL. | Fully satisfied | Persistent effects proven. |
| IF-5 | HTTP/HTTPS client/server communication as applicable. | Same-origin browser HTTP through Vite `/api` proxy to Flask in local deployment. | Fully satisfied | Local hosting is permitted; HTTPS is not required when operating locally. |
| IF-6 | RESTful reservation integration. | Exact OP-01-OP-05 methods/routes; `liveOperations.js`; P25. | Fully satisfied | React-to-Flask REST integration is proven. |
| DEP-1 | Deployable locally or on a web server. | Owned PostgreSQL→Flask→Vite lifecycle and production build passed. | Fully satisfied | Local deployability is proven; public staging is optional. |
| DEP-2 | Accompanying README covers environment, dependencies, DB configuration, and deployment. | Layer-specific `database/README.md`, `backend/README.md`, and TestInstructions exist; repository-root `README.md` is absent. | Not satisfied | Required consolidated README is missing; Prompt 27 owns closure. |

**Interface/deployment totals:** Fully satisfied 7; Partially satisfied 0; Not satisfied 1; Not applicable 0.

## 9. Browser/manual-validation status

Committed evidence establishes Chrome and Edge live behavior, navigation, hours, newsletter, availability, reservation confirmation, lightbox/responsive smoke, and narrow/desktop no-overflow. It does not establish Firefox or Safari.

To close NFR-7, a Firefox-capable and Safari-capable environment must manually verify, in each browser:

1. direct loading and navigation of Home, Menu, Reservations, About Us, and Gallery;
2. server-authoritative Home/reservation hours and reservation context;
3. newsletter validation, successful save, conflict/error presentation, and recovery;
4. full reservation flow, unavailable slots/full behavior, confirmation, and safe failure state;
5. Gallery grid/lightbox keyboard controls, focus trap/return, and image rendering;
6. mobile-width and desktop-width reflow, controls, focus visibility, and absence of horizontal overflow.

Database effects need not be re-proven in each browser, but the live environment and exact browser/version/OS/viewports/results must be recorded. No browser installation or execution was attempted during Prompt 26.

## 10. Complete PRA v2.2.1 matrix

| PRA ID | Requirement summary | PostgreSQL authority | Flask/API | React | Automated evidence | Manual evidence | Status | Notes |
|---|---|---|---|---|---|---|---|---|
| PRA-001 | Strict DB→Flask→React→integration order. | DB gates precede API. | API gates precede React. | React then P25. | Commit/checkpoint reports. | Frozen approvals. | Fully satisfied | Historical delivery order is evidenced. |
| PRA-002 | Least-to-most increments. | Migrations/gates. | API-04→09. | REACT-04→06. | Regression preservation. | Approval chain. | Fully satisfied | Incremental gates are explicit. |
| PRA-003 | Testing throughout. | DBV suites. | 458 API/unit plus integration. | 162 frontend plus P25. | All frozen reports. | Repeatable instructions. | Fully satisfied | No layer lacks tests. |
| PRA-004 | Fixed SRS/rubric baseline; no contradiction. | Normalized FR-17 table-number relation preserves the complete allocation. | Gateways consume and return the complete normalized relation. | Confirmation displays all assigned numbers. | Strict evidence in §5 and P25 exact table-set comparison. | User-approved normalized interpretation; final demo will show the relation. | Fully satisfied | Neither authority mandates scalar physical placement or prohibits normalization; PRA-018 is compatible with unspecified capacity/allocation details. |
| PRA-005 | Prefer configurable supplemental rules. | Singleton configuration/hours/table capacity. | Reads current facts. | Consumes OP-01/02. | DBV and P25 setting-change scenario. | P25 restore proof. | Fully satisfied | Mandated 30 remains fixed. |
| PRA-006 | Configurable aligned start interval. | `start_interval_minutes`. | Slot generation/enforcement. | API-supplied slots only. | DBV; reservation discovery tests; P25 scenario 4. | Live 30→60→30. | Fully satisfied | Permitted/default behavior proven. |
| PRA-007 | 60/90/120 duration; default 90. | Configuration and immutable interval. | Returns start/end. | Displays policy/confirmation. | DBV duration/boundary tests. | DB manual boundaries. | Fully satisfied | No turnover buffer. |
| PRA-008 | All dates under weekly schedule; no exceptions. | Seven-row hours; no exception tables. | Date/window validation. | Date control uses context. | DBV and API boundary tests. | Weekday/Sunday evidence. | Fully satisfied | PRA-029 amendment implemented. |
| PRA-009 | Opening-derived earliest/latest; finish by close. | Hours/duration/interval. | Generates valid starts. | Displays only returned starts. | DBV closing tests; OP-02 tests. | DB manual boundary. | Fully satisfied | Defaults derive 9:30/7:30. |
| PRA-010 | Inclusive configurable advance window. | `advance_booking_days`. | OP-01 bounds/OP-05 validation. | Native min/max. | API/DB boundary tests. | R5 browser min/max. | Fully satisfied | 60-day default proven. |
| PRA-011 | Same-day minimum lead. | `same_day_lead_minutes`; DB clock. | Authoritative validation. | Reflects availability. | `test_same_day_lead_and_advance_window_boundaries_use_database_time`. | P25 context. | Fully satisfied | Client clock is not authority. |
| PRA-012 | America/New_York and server/DB clock. | Timezone setting/timestamptz. | IANA serialization. | Restaurant-local display. | DST/offset gateway and API tests. | R6 confirmation. | Fully satisfied | Host timezone independence covered. |
| PRA-013 | Half-open overlap; back-to-back allowed. | Interval predicates/locks. | Preserves DB outcomes. | Availability/result UI. | DBV overlap shapes; discovery PostgreSQL test. | DB/P25 overlap checks. | Fully satisfied | Exact boundary behavior proven. |
| PRA-014 | Same-customer overlap, exact retry, pending lock. | Fingerprint/uniqueness/locks. | Exact retry semantics. | Immutable snapshot and disabled submit. | Cross-operation concurrency; R5 tests; P25 scenario 10. | Lost-response recovery. | Fully satisfied | One logical booking proven. |
| PRA-015 | Party 1 through derived total capacity. | Sum of 30 capacities. | Context/booking validation. | Dynamic maximum. | DBV party/capacity tests; R5 bounds. | P25 party 120/full. | Fully satisfied | Initial maximum 120. |
| PRA-016 | Exactly 30 persistent tables. | `restaurant_tables` seed 1-30. | Readiness/allocation requires 30. | No admin inventory. | `verify_db05.sql`; P25 SQL. | DBV/P25 direct evidence. | Fully satisfied | Strict count met. |
| PRA-017 | Per-table configurable capacity, initial 4. | `seating_capacity`; controlled writer. | Reads current capacities. | Uses returned maximum. | DBV writer/capacity tests. | P25 capacity scenarios. | Fully satisfied | Prospective behavior proven. |
| PRA-018 | Exclusive multi-table optimized/random-tie allocation. | Allocator/assignment join; atomic lock. | Returns all assigned numbers. | Confirmation displays all. | DBV allocator/concurrency; P25 scenarios 5-6. | Party-six and all-table evidence. | Fully satisfied | Implements capacity/allocation details not specified or prohibited by the SRS; no FR-8/18 contradiction remains. |
| PRA-019 | Structured identity/contact and synchronized newsletter. | One canonical customer. | OP-03/04/05 rules. | Debounced synchronization. | Newsletter/reservation API/integration/UI suites. | P25 conflicts/state. | Fully satisfied | No authentication, as approved. |
| PRA-020 | Customers is newsletter source of truth. | Sole Boolean; no subscriber table. | OP-04 set semantics. | Dedicated and booking controls. | DBV; newsletter suites; P25. | Direct SQL. | Fully satisfied | Current state only. |
| PRA-021 | Concurrent/retry-safe newsletter updates. | Email lock/unique customer. | Bounded retry; authoritative result. | Replaces local state. | Concurrent preference tests; P25 retry/state. | R6 recovery. | Fully satisfied | Last committed write wins. |
| PRA-022 | No reservation cancellation/modification. | No status/control; reservations retain occupancy. | No endpoint. | No UI control. | Route/schema inventories and retention tests. | Exclusion review. | Fully satisfied | Version-1 exclusion, not a gap. |
| PRA-023 | React validation plus authoritative Flask validation. | Constraints/booking validation. | Full field/business revalidation. | Immediate accessible validation. | Validation suites; P25 manipulated slot. | R5/R6 forms. | Fully satisfied | Defense in depth proven. |
| PRA-024 | Complete confirmation, friendly errors, safe logging. | Returns committed facts. | Safe mappings/redaction. | Accessible confirmation/recovery. | API privacy/error tests; R5 flows; P25. | Transport/full/conflict evidence. | Fully satisfied | No delivery claim. |
| PRA-025 | Availability-first full daily schedule; revalidate. | Provisional routine plus atomic booking. | OP-02 all slots; OP-05 revalidation. | Disabled unavailable slots; stale guards. | Discovery/UI tests; P25 scenarios 3, 7, 8. | Live all-unavailable/recovery. | Fully satisfied | Authority boundaries preserved. |
| PRA-026 | Prospective configuration and controlled reset. | Immutable booking facts; guarded scripts. | Current config for new work. | No reset UI. | DBV prospective/reset; lifecycle guards. | P25 setting restore/cleanup. | Fully satisfied | Nonproduction only. |
| PRA-027 | DB fingerprint and retry/newsletter separation. | Versioned opaque fingerprint, tuple verification. | Client-independent exact retry. | Never generates/exposes fingerprint. | DB collision/retry tests; cross-operation test; P25 scenario 10. | Lost-response evidence. | Fully satisfied | Collision alone is insufficient. |
| PRA-028 | Retain until controlled nonproduction reset. | No purge/archive; RESTRICT FKs. | No delete/archive API. | No delete UI. | DBV retention/reset tests. | P25 cleanup is controlled. | Fully satisfied | Past rows remain but stop blocking. |
| PRA-029 | PostgreSQL-backed recurring hours, exact SRS seed. | Dedicated seven-row table. | Reads/delivers current schedule. | `CurrentHours` and reservation context. | Exact seed/API tests; P25 30→60 is interval, R6 hours change/restore. | Chrome/Edge live hours. | Fully satisfied | No hard-coded UI authority. |

**PRA totals:** Fully satisfied 29; Partially satisfied 0; Not satisfied 0; Not applicable 0. Future enhancements FE-001 through FE-017 are inactive and therefore are not PRA rows or Version-1 gaps.

## 11. Score-5 rubric matrix

| ID | Independent score-5 criterion | Evidence | Status | Open issue |
|---|---|---|---|---|
| R5-1 | Minimum five pages built with React/JSX. | Five routes in `App.jsx`; R4/R6 browser evidence. | Fully satisfied | None. |
| R5-2 | All SRS requirements implemented. | 18/18 FRs full; six/nine NFRs full; seven/eight interface/deployment rows full. | Partially satisfied | NFR-1/2/7 evidence and required README remain open; FR-17 is fully satisfied. |
| R5-3 | Good appearance and excellent UI/UX. | Frozen visual/accessibility system; responsive Chrome/Edge and semantic tests. | Fully satisfied | Final grader judgment is inherently external, but current implementation evidences excellence. |
| R5-4 | Appropriate Flexbox/Grid for high-quality UX. | Grid/flex ownership documented in R4 and CSS. | Fully satisfied | None. |
| R5-5 | Required forms correctly implemented and working. | R5/R6/P25 newsletter and reservation flows. | Fully satisfied | Firefox/Safari validation remains under NFR-7, not a known form defect. |
| R5-6 | React correctly integrates Flask/PostgreSQL for reservation/newsletter. | `liveOperations.js`; R6; P25 direct SQL effects. | Fully satisfied | None. |
| R5-7 | Demo presents all required site elements. | Engineering capability exists; no final recording. | Not satisfied | Prompt 28/final user action. |
| R5-8 | Demo directly shows reservation/newsletter effects in PostgreSQL. | P25 proved effects but is not the final recorded demo. | Not satisfied | Prompt 28 must plan; final recording must show DB itself. |
| R5-9 | Sophisticated reservation logic. | Configurable slots/duration/window/timezone, capacity-aware exclusive allocation, randomized optimal ties, overlap/concurrency, exact retry. | Fully satisfied | None. |
| R5-10 | AI code-generation/tooling documentation. | No `ai-tooling.md`. | Not satisfied | Prompt 27. |

**Score-5 totals:** Fully satisfied 6; Partially satisfied 1; Not satisfied 3; Not applicable 0. The project is not currently score-5 ready.

## 12. Presentation and submission obligations

| ID | Obligation | Current evidence | Status | Closure |
|---|---|---|---|---|
| SUB-01 | Approximately 5-10 minute recorded demo. | No final recording. | Not satisfied | Prompt 28 plan, then user records. |
| SUB-02 | Presenter visible while screen is recorded. | No recording. | Not satisfied | User recording action. |
| SUB-03 | Government-issued ID shown legibly. | No evidence; identity details must not enter repository. | Not satisfied | User performs only in final recording. |
| SUB-04 | Presenter states name. | No recording. | Not satisfied | User action. |
| SUB-05 | Demo all five pages and navigation. | Capability verified; no final recording. | Not satisfied | Prompt 28/final recording. |
| SUB-06 | Demo newsletter signup. | Capability verified; no final recording. | Not satisfied | Prompt 28/final recording. |
| SUB-07 | Demo working reservation system. | Capability verified; no final recording. | Not satisfied | Prompt 28/final recording. |
| SUB-08 | Show direct backend DB effects, not admin page. | P25 direct SQL engineering evidence only. | Not satisfied | Prompt 28/final recording must show SQL. |
| SUB-09 | Discuss implementation decisions. | Reports exist; no presentation. | Not satisfied | Prompt 28/final recording. |
| SUB-10 | Do not use “Invite People” to share. | Future sharing action not evidenced. | Not satisfied | Deferred external action; user follows the sharing rule at submission time. |
| SUB-11 | Submit Google Drive recording link. | None. | Not satisfied | Deferred external user submission action. |
| SUB-12 | Submit PDF containing repository link(s). | None. | Not satisfied | Deferred external user action; the audit does not request names, URLs, or other-member repositories. |
| SUB-13 | Private GitHub repository contains all source. | Current repository source exists locally and origin points to GitHub; remote privacy/content cannot be proven from repository. | Partially satisfied | Deferred external user verification for this repository; no other team-member repository is inspected or required now. |
| SUB-14 | Add `quantic-grader` collaborator. | No repository evidence. | Not satisfied | Deferred external GitHub action handled manually by the user when appropriate. |
| SUB-15 | Repository contains required README. | Root `README.md` absent. | Not satisfied | Prompt 27. |
| SUB-16 | Repository contains required `ai-tooling.md`. | File absent. | Not satisfied | Prompt 27. |
| SUB-17 | Group visibility/speaking/single-submit/agreement rules and group repository links. | Group project of three is confirmed; no final recording/submission/agreement evidence exists. Names, URLs, other-member repositories, collaborator actions, and submission administration are intentionally deferred. | Not satisfied | Future manual/external action: satisfy the rubric’s applicable group recording, identity, repository-link, single-submitter, and signed Group Project Agreement requirements when appropriate. No current implementation or Prompt-26 documentation work is required. |
| SUB-18 | `staging.md`. | Local deployment is chosen/evidenced; staging file is explicitly optional. | Not applicable | No staging deployment is used, so the optional file is not required. |

**Submission totals:** Fully satisfied 0; Partially satisfied 1; Not satisfied 16; Not applicable 1.

## 13. README and AI-tooling status

The root `README.md` and `ai-tooling.md` required by the rubric are absent. Layer-specific READMEs and three `TestInstructions.md` files do not replace the required consolidated solution/design/local-run README. Prompt 27 must create the truthful final documents from the completed project, including environment setup, dependencies, PostgreSQL configuration/initialization, Flask/React startup, tests, architecture, and actual AI-tooling use. Current status is **Not satisfied** for both required artifacts.

## 14. Demo-evidence status and Prompt-28 input list

Prompt 25 proves engineering capability but is not the final rubric recording. Prompt 28 needs only these currently open evidence inputs:

1. all five pages, working navigation, responsive view, Gallery categories/lightbox, exact content/recognition;
2. newsletter validation and successful preference change, followed by direct PostgreSQL customer/email/newsletter-state query;
3. reservation context/date/party/full daily schedule, valid slot, completed form, confirmation showing every assigned table number, and direct PostgreSQL customer, `reservations`, and `reservation_table_assignments` rows; optionally run the §5 joined aggregate to reconstruct every required reservation fact;
4. unavailable/full behavior and an honest explanation of authoritative revalidation;
5. sophisticated rules: PostgreSQL hours/configuration, 30 tables, interval/duration/timezone, exclusive allocation, overlap prevention, and retry safety;
6. explain the approved capacity-aware assignment honestly, including single-table random selection and possible multi-table assignment for larger parties;
7. implementation architecture/decisions, automated verification summary, and local deployment;
8. required presenter, timing, identity, sharing, repository-PDF, and submission actions from §12;
9. group-of-three obligations from the rubric: all members visible and speaking at least once, identity/name steps, one group recording/submitting member, applicable repository link(s), and the signed final Group Project Agreement page. Names, URLs, other-member repository work, collaborator invitations, and exact external administration are deferred to the user and are not Prompt-26 inputs.

This is an input list, not a demo script.

## 15. Content, assets, provenance, and licensing

- Home contact/hours, all Menu values, About history/founders/commitments, and exact awards/reviews match the SRS.
- The five committed WebPs visibly cover interior ambience, menu dish, special event, and behind-the-scenes work. Dimensions are 1024×1024 through 1792×1024; metadata, intrinsic dimensions, lazy/eager loading, responsive Grid, and lightbox behavior are implemented and tested.
- The project record establishes the original four Gallery source images as assignment-supplied project inputs.
- The later `gallery-behind-the-scenes.webp` is project AI-generated. It is the only additional image, and therefore satisfies the rubric's alternative allowing AI-generated additional imagery.

Asset quality/use and applicable provenance classification are **Fully satisfied**. No unsupported additional image or separate royalty-free-license gap is evidenced. Prompt 27 may truthfully document four assignment-supplied images and one project AI-generated image; it need not invent or obtain unknown license evidence for the supplied inputs.

## 16. Consolidated requirement-to-evidence master matrix

This matrix is the canonical consolidated view. “N/A” always names why the layer does not apply. Exact obligations and rationale remain in §§4-12.

### 16.1 SRS master rows

| Requirement | PostgreSQL | Flask | React | Automated test(s) | Manual verification | Demo evidence | Status |
|---|---|---|---|---|---|---|---|
| FR-1 | N/A — static | N/A — static | Home H1 | AppRoutes Home | R4 routes | Planned P28 | Fully satisfied |
| FR-2 | Hours seed | OP-01 | Contact + CurrentHours | seed/CurrentHours/P25-4 | Chrome/Edge live | Planned P28 | Fully satisfied |
| FR-3 | N/A — UI | N/A — UI | Assets/theme | routes/build/Gallery | R4 + asset inspection | Planned P28 | Fully satisfied |
| FR-4 | N/A — UI | N/A — UI | Shared routes/nav | AppRoutes/SiteHeader | Chrome/Edge | Planned P28 | Fully satisfied |
| FR-5 | N/A — content | N/A — content | Menu data/page | exact Menu test | R4 routes | Planned P28 | Fully satisfied |
| FR-6 | Stored facts | OP-01/02/03/05 | Reservation form | validation/UI/API suites | R5/R6 browsers | Planned P28 | Fully satisfied |
| FR-7 | provisional + booking | OP-02/05 | server slots | DB/API/UI/P25-3/7/8 | live full/manipulated | Planned P28 | Fully satisfied |
| FR-8 | 30 + optimized/random-tie assignment | OP-05 | no choice; all assigned shown | allocator/concurrency/P25-5/6 | single/multi DB/P25 | Planned P28 | Fully satisfied |
| FR-9 | success/full outcomes | mapping | confirmation/errors | API/UI/P25-7 | live success/full | Planned P28 | Fully satisfied |
| FR-10 | N/A — content | N/A — content | About story | About test | R4 | Planned P28 | Fully satisfied |
| FR-11 | N/A — content | N/A — content | founder/commitment copy | About test | R4 | Planned P28 | Fully satisfied |
| FR-12 | N/A — assets | N/A — assets | five Gallery assets | discovery/page/build | R4 + inspection | Planned P28 | Fully satisfied |
| FR-13 | N/A — UI | N/A — UI | lightbox | lightbox/page tests | Chrome/Edge | Planned P28 | Fully satisfied |
| FR-14 | N/A — content | N/A — content | exact recognition | AppRoutes exact test | R4 | Planned P28 | Fully satisfied |
| FR-15 | email/state constraints | OP-03/04 validation | newsletter form | validation/newsletter/P25-2 | live browser | Planned P28 | Fully satisfied |
| FR-16 | customer email/state | OP-04 | live form | integration/P25-1/12 | direct SQL | Planned P28 | Fully satisfied |
| FR-17 | normalized reservation/assignment relation | complete table set | confirmation shows all | catalog/schema/API/UI/P25 | DBV/P25 exact set | Planned normalized DB demonstration | Fully satisfied |
| FR-18 | atomic booking/allocation | OP-05 | live result | DB/API/integration/P25 | live/direct SQL | Planned P28 | Fully satisfied |
| NFR-1 | Query/build contribution only | API timing not load | optimized assets/build | build only | Approved one-user normal-VM basis; measurement pending | P28 may report evidence | Partially satisfied |
| NFR-2 | DB timings | Flask/live HTTP timings | forms | APIV/R6/P25 timings | Approved one-user normal-VM basis; submit-to-result measurement pending | P28 may report evidence | Partially satisfied |
| NFR-3 | N/A — UI | friendly responses | nav/focus/forms | UI tests | Chrome/Edge | Visible P28 | Fully satisfied |
| NFR-4 | N/A — UI | N/A — UI | visual system | route/UI tests | Chrome/Edge/inspection | Visible P28 | Fully satisfied |
| NFR-5 | atomic integrity | preserves outcomes | authoritative UX | DB/API concurrency/P25 | direct overlap SQL | Explain P28 | Fully satisfied |
| NFR-6 | safe outcomes | error envelopes/logging | accessible recovery | API/UI failure tests | P25 transport/full | Show P28 | Fully satisfied |
| NFR-7 | N/A — browser | browser-neutral API | browser UI | Chrome/Edge automation | Firefox/Safari pending | Mention validated set | Partially satisfied |
| NFR-8 | N/A — UI | N/A — UI | responsive CSS | UI/layout tests | 320-1440 Chrome/Edge | Show P28 | Fully satisfied |
| NFR-9 | migrations/docs | modular packages/docs | modular components/docs | full suites/reviews | frozen reviews | Repository evidence | Fully satisfied |

### 16.2 Interface/deployment master rows

| Requirement | PostgreSQL | Flask | React | Automated test(s) | Manual verification | Demo evidence | Status |
|---|---|---|---|---|---|---|---|
| IF-1 React/JSX UI | N/A — UI | N/A — UI | five-page JSX | frontend suite/build | Chrome/Edge | Planned P28 | Fully satisfied |
| IF-2 Flexbox/Grid | N/A — UI | N/A — UI | CSS Grid/Flexbox | layout tests/static review | R4 viewport matrix | Planned P28 | Fully satisfied |
| IF-3 Flask API | DB routines | seven Flask operations | live client consumes five | 458 unit/API + 61/62 current PG selection | R6/P25 | Planned P28 | Fully satisfied |
| IF-4 PostgreSQL | authoritative data/routines | app-role gateway | indirect via API | DBV/APIV/P25 | direct SQL | Planned P28 | Fully satisfied |
| IF-5 HTTP/HTTPS | N/A — transport | local HTTP server | same-origin `/api` | adapter/proxy/live tests | R6/P25 | Planned local demo | Fully satisfied |
| IF-6 REST integration | DB backing | exact routes/methods | native fetch adapter | API examples/adapter/P25 | live browsers | Planned P28 | Fully satisfied |
| DEP-1 local/web deployability | owned local cluster | owned Flask | Vite/build | lifecycle/build | R6/P25 | Planned local demo | Fully satisfied |
| DEP-2 README instructions | Fragmented layer docs | Fragmented layer docs | TestInstructions only | N/A — document absent | No consolidated run-through | Planned P27 then P28 | Not satisfied |

### 16.3 PRA master rows

| Requirement | PostgreSQL | Flask | React | Automated test(s) | Manual verification | Demo evidence | Status |
|---|---|---|---|---|---|---|---|
| PRA-001 | DB first | API second | UI third | gate history | frozen approvals | Explain order | Fully satisfied |
| PRA-002 | incremental migrations | incremental APIs | incremental React | preserved regressions | reports | Explain method | Fully satisfied |
| PRA-003 | DB suites | API suites | UI/P25 suites | frozen totals | instructions | Brief summary | Fully satisfied |
| PRA-004 | complete normalized FR-17 relation | consumes complete set | displays complete set | DB/API/UI/P25 evidence | user-approved interpretation | Demonstrate directly | Fully satisfied |
| PRA-005 | persisted config | consumes | consumes | config-change tests | P25 change/restore | Explain | Fully satisfied |
| PRA-006 | interval | enforce | supplied slots | DB/API/P25 | live change | Show default | Fully satisfied |
| PRA-007 | duration/interval | serialize | display | duration tests | boundary evidence | Explain | Fully satisfied |
| PRA-008 | weekly dates | validate | date input | boundary tests | weekday/Sunday | Explain limitation | Fully satisfied |
| PRA-009 | derived starts | generate | display | closing tests | boundary evidence | Show | Fully satisfied |
| PRA-010 | advance setting | enforce | min/max | boundary tests | browser bounds | Show | Fully satisfied |
| PRA-011 | lead/DB clock | enforce | reflect | DB-time tests | live context | Show if practical | Fully satisfied |
| PRA-012 | timezone/timestamptz | IANA serialization | local display | DST/offset tests | confirmation | State timezone | Fully satisfied |
| PRA-013 | half-open interval | preserve | reflect | overlap/back-to-back | DB/P25 | Explain | Fully satisfied |
| PRA-014 | uniqueness/fingerprint | retry mapping | pending/snapshot | concurrency/retry | lost response | Show retry if time | Fully satisfied |
| PRA-015 | derived capacity | validate | dynamic max | capacity tests | party 120 | Explain | Fully satisfied |
| PRA-016 | exactly 30 | readiness | N/A — no admin | exact seed | direct SQL | Show count | Fully satisfied |
| PRA-017 | capacity rows | context | dynamic bound | writer/capacity | P25 capacity | Explain | Fully satisfied |
| PRA-018 | exclusive multi-table allocator | returns list | displays list | allocation/concurrency | party six | Show honestly | Fully satisfied |
| PRA-019 | canonical customer | identity rules | sync forms | cross-layer suites | P25 conflicts | Show | Fully satisfied |
| PRA-020 | sole Boolean | preference API | two controls | newsletter suites | direct SQL | Show | Fully satisfied |
| PRA-021 | locks/state | bounded retry | authoritative sync | concurrency tests | recovery | Explain | Fully satisfied |
| PRA-022 | no lifecycle objects | no endpoints | no controls | inventories | exclusion review | State limitation | Fully satisfied |
| PRA-023 | constraints | authoritative validation | immediate validation | validation/P25-8 | invalid flows | Show | Fully satisfied |
| PRA-024 | committed facts | safe errors/logs | confirmation/recovery | error/privacy tests | P25 failures | Show | Fully satisfied |
| PRA-025 | provisional/atomic | OP-02/05 | all slots/stale guards | discovery/UI/P25 | live full | Show | Fully satisfied |
| PRA-026 | immutable/config/reset | prospective | no reset UI | lifecycle/DB tests | P25 restore | Prep reset only | Fully satisfied |
| PRA-027 | fingerprint | exact retry | client-independent | collision/retry/P25 | lost response | Explain | Fully satisfied |
| PRA-028 | retention | no delete API | no delete UI | retention/reset | cleanup evidence | Query rows | Fully satisfied |
| PRA-029 | hours table/seed | reads current | live display | seed/change tests | Chrome/Edge | Show DB/UI | Fully satisfied |

### 16.4 Rubric and submission master rows

| Requirement | PostgreSQL | Flask | React | Automated test(s) | Manual verification | Demo/submission evidence | Status |
|---|---|---|---|---|---|---|---|
| R5-1 five pages | N/A | N/A | five routes | route suite | Chrome/Edge | P28 pending | Fully satisfied |
| R5-2 all SRS | §§5-8 | §§5-8 | §§4/7 | frozen suites | NFR-1/2/7 pending | P27/P28/manual pending | Partially satisfied |
| R5-3 excellent UI/UX | N/A | safe API supports UX | visual/accessibility system | UI suite | R4-R6 | P28 pending | Fully satisfied |
| R5-4 Flex/Grid | N/A | N/A | CSS | static/layout tests | viewport matrix | P28 pending | Fully satisfied |
| R5-5 forms work | persistence | OP-03/04/05 | forms | form/API/P25 | Chrome/Edge | P28 pending | Fully satisfied |
| R5-6 integration | data/routines | live API | live fetch | R6/P25 | direct SQL | P28 pending | Fully satisfied |
| R5-7 demo elements | capability | capability | capability | engineering only | no final demo | absent | Not satisfied |
| R5-8 demo DB effects | direct-query capability | mutation capability | form capability | P25 | no final demo | absent | Not satisfied |
| R5-9 sophisticated logic | allocator/concurrency/retry | mapping | safe UX | DB/API/P25 | demonstrations | P28 pending | Fully satisfied |
| R5-10 AI document | N/A | N/A | N/A | N/A — absent | none | P27 pending | Not satisfied |
| SUB-01 5-10 min | N/A | N/A | N/A | N/A | none | absent | Not satisfied |
| SUB-02 visible presenter/screen | N/A | N/A | N/A | N/A | none | absent | Not satisfied |
| SUB-03 ID | N/A | N/A | N/A | N/A | none | absent; user-only | Not satisfied |
| SUB-04 state name | N/A | N/A | N/A | N/A | none | absent | Not satisfied |
| SUB-05 five pages/nav | N/A | N/A | capability | route tests | engineering evidence | final demo absent | Not satisfied |
| SUB-06 newsletter demo | persistence | OP-04 | form | P25 | engineering evidence | final demo absent | Not satisfied |
| SUB-07 reservation demo | persistence | OP-05 | form | P25 | engineering evidence | final demo absent | Not satisfied |
| SUB-08 direct DB effect | queryable state | mutation | initiating form | P25 | engineering SQL | final demo absent | Not satisfied |
| SUB-09 decisions discussion | reports | reports | reports | N/A | none in recording | absent | Not satisfied |
| SUB-10 no Invite People | N/A | N/A | N/A | N/A | future action | not yet performed | Not satisfied |
| SUB-11 Drive link | N/A | N/A | N/A | N/A | none | absent | Not satisfied |
| SUB-12 PDF/repo link | N/A | N/A | N/A | N/A | none | absent | Not satisfied |
| SUB-13 private repo/source | local DB source | local API source | local UI source | Git inventory | remote privacy not verified | user verification pending | Partially satisfied |
| SUB-14 grader collaborator | N/A | N/A | N/A | N/A | none | user action pending | Not satisfied |
| SUB-15 README | docs fragmented | docs fragmented | instructions | N/A | none consolidated | P27 pending | Not satisfied |
| SUB-16 AI tooling | N/A | N/A | N/A | N/A | absent | P27 pending | Not satisfied |
| SUB-17 group conditions | N/A | N/A | N/A | N/A | group of three confirmed; actions pending | recording/agreement/repos/single-submit pending | Not satisfied |
| SUB-18 staging file | N/A | N/A | N/A | N/A | local deployment chosen | N/A — optional without staging | Not applicable |

## 17. Traceability consistency findings

1. DBV and API-09 previously call FR-8/17/18 complete using the addendum’s “additive compliance” interpretation. Current reconciliation agrees: FR-8/FR-18 have no explicit one-table, uniform-randomness, or no-combination rule, and the user has approved FR-17’s complete normalized Reservation-to-Table Number relation as fully satisfying the authority.
2. The user-approved FR-17 interpretation recognizes `reservations` as the reservation-level relation and `reservation_table_assignments` as the authoritative one-to-many Table Number relation. Flask returns and React displays the complete set, and P25 compared that set with PostgreSQL. No physical compatibility witness or layer reopening is required; only the internal schema-literal grading caveat and proactive final-demo explanation remain.
3. API-09’s frozen report records 62/62 PostgreSQL tests. The later approved P25 execution records 61/62 with the exact unchanged `test_free_partial_full_and_back_to_back_occupancy_are_provisional_and_nonmutating_after_cleanup` failing by `StopIteration`, while the separate authoritative complete PostgreSQL programmer gate passed. Prompt 25 explicitly accepted and froze this as baseline-pre-existing. It remains traceability history, not an active closure item or later-prompt prerequisite absent evidence of a product regression or a rubric/SRS dependency.
4. R6 correctly labels its timings descriptive and not final NFR-01/NFR-02 compliance. P25 adds live operation timings, but neither measures website load or browser form submit-to-final-state. The approved target is one concurrent user on the normally operating Codex/demo VM without invented numeric bandwidth or artificial throttling. INT-07 must choose and record reasonable reproducible timing mechanics, but cache state, boundaries, sampling, percentiles, and VM size are methodology—not additional SRS/rubric obligations or unresolved project requirements.
5. R4-R6 correctly defer Firefox/Safari, and P25 correctly preserves that limitation. The four original Gallery images are project-supplied inputs and the fifth is project AI-generated, so no unsupported additional-image provenance gap remains. No frozen artifact claims a four-browser pass.
6. Initial baseline traceability grouped ranges (for example FR-01 to FR-05) and was planning-only. This audit separates every authoritative requirement and finds no untraced implemented page/content feature.
7. The Game Plan’s older React prompt numbering differs from committed Prompt-22 through Prompt-25 filenames/reports. Frozen increment IDs and current prompt files resolve execution history, but Prompt 27 should avoid copying stale prompt-number statements.
8. Layer-specific READMEs/TestInstructions are substantial but do not satisfy the rubric’s required repository-root README or `ai-tooling.md`.
9. Group-of-three submission mode is confirmed. This resolves applicability but does not complete future recording, identity, speaking, repository-link, agreement, collaborator, or one-member-submission actions. Those are deferred manual/external obligations; this audit requires no names, URLs, invitations, or inspection/creation of other team-member repositories.
10. `docs/demo/Cafe_Fausse_FR17_Demo_Queries.md` is an intentional user-created read-only demo reference. It supports future explanation of FR-17 but is outside the Prompt-26 review delta and is not evidence that Prompt 28 has begun.

## 18. Prioritized score-5 blocker and gap register

| ID | Priority | Requirement(s) | Category | Current evidence | Why not fully satisfied | Smallest closure | Earliest affected layer/prompt | User action needed? | Score-5 impact |
|---|---|---|---|---|---|---|---|---|---|
| G-03 | P0 | NFR-1, R5-2 | Verification/evidence gap | Build/assets only; approved target is one user on the actual normally operating Codex/demo VM without invented numeric bandwidth or artificial throttling. | No quantified page-load evidence against the 3-second threshold. | Select and document reasonable reproducible methodology, measure required pages, record the actual environment/results, and address only a demonstrated failure. Methodology is not an added requirement. | INT-07 integration verification/manual performance. | No current user decision; later verification execution/evidence is required. | Explicit SRS evidence blocker. |
| G-04 | P0 | NFR-2, R5-2 | Verification/evidence gap | Descriptive API/live samples <0.5 s; approved target is one user on the actual normally operating Codex/demo VM. | No quantified browser submit-to-final-state evidence for both forms against the 2-second threshold. | Select and document reasonable reproducible methodology, measure reservation and newsletter end-to-end, record the actual environment/results, and address only a demonstrated failure. | INT-07 integration verification. | No current user decision; later verification execution/evidence is required. | Explicit SRS evidence blocker. |
| G-05 | P0 | NFR-7, R5-2 | Verification/evidence gap | Chrome/Edge only. | Firefox/Safari untested. | Perform and record §9 checklist in capable environments. | External manual browser validation. | Yes — Safari/Firefox access. | Explicit SRS blocker. |
| G-06 | P0 | DEP-2, SUB-15 | Documentation gap | Layer docs only. | Root README absent. | Prompt 27 creates consolidated truthful README. | Prompt 27. | Approval to begin after preceding verification and Prompt-26 approval. | Explicit deployment/submission blocker. |
| G-07 | P0 | R5-10, SUB-16 | Documentation gap | No `ai-tooling.md`. | Required score-5/submission artifact absent. | Prompt 27 documents actual AI use. | Prompt 27. | Approval to begin after preceding verification and Prompt-26 approval. | Direct score-5 blocker. |
| G-08 | P0 | R5-7/8, SUB-01-09 | Demo/submission/manual-action gap | Engineering capability/P25 evidence. | Final group 5-10 minute presentation absent. | Prompt 28 plan, then all three members record the required demonstration, including direct SQL and the normalized FR-17 relation. | Prompt 28 and user/group recording. | Yes. | Direct score-5 blocker. |
| G-09 | P0 | SUB-10-14 | Demo/submission/manual-action gap | Current repository origin exists; no external-state proof. | Sharing, Drive/PDF, repository link(s), collaborator, privacy/push, and submission actions are incomplete or unverified. | User completes the applicable final external submission checklist without using “Invite People”; no other team-member repository is inspected or prepared in Prompt 26. | Future user/group submission action. | Yes, later—not an implementation task or current input. | Submission blocker. |
| G-12 | P0 | SUB-17 | Demo/submission/manual-action gap | Group project of three is confirmed. | Applicable group recording/identity/speaking, repository-link, signed-agreement, and one-member-submission actions are not yet evidenced. | User handles names, URLs, repositories, invitations, exact link administration, agreement, and submission externally when appropriate. | Prompt 28 and future user/group submission action. | Yes, later; no current decision or repository work is required. | Direct group-submission blocker. |

**Gap totals:** P0 8; P1 0; P2 0.

**Primary-category totals:** implementation defect/gap 0; verification/evidence gap 3; documentation gap 2; demo/submission/manual-action gap 3.

## 19. Least-to-most closure recommendations

1. Record FR-17 as closed by the user-approved normalized interpretation. Retain the internal grading caveat and §5 demo evidence, but make no database, Flask, React, test, contract, or Prompt-25 change.
2. For later INT-07 execution, retain the approved one-user actual-VM basis, choose and document reasonable reproducible timing mechanics, and do not present cache state, timing boundaries, sampling, percentile, numeric bandwidth, or VM sizing as authoritative requirements.
3. Measure NFR-1/NFR-2 in the existing Codex VM against the SRS thresholds. If a threshold fails, diagnose obvious software/application causes first. Scaling is optional later—not a requirement or part of Prompt 26—and any evidence must truthfully record its actual environment.
4. Perform external Firefox and Safari manual validation and record exact environments/results; do not install them in the current Codex environment.
5. Preserve the accepted frozen API-09 `StopIteration` as history. It is not a closure action or prerequisite absent new regression or requirement-dependent evidence.
6. Prompt 26 is approved and frozen with the evidence gaps disclosed. After the required NFR-1/NFR-2 measurements and Firefox/Safari validation are completed and incorporated through the project workflow, begin Prompt 27 to create the root README and `ai-tooling.md`. It may truthfully describe the FR-17 normalized relation and Gallery provenance; no team names, URLs, other-member repositories, or external collaborator actions are required to begin that documentation increment.
7. Begin Prompt 28 only afterward; create the group 5-10 minute demonstration plan from §14, including proactive normalized FR-17 PostgreSQL evidence.
8. At the appropriate later submission stage, the user/group handles recording/identity/speaking, sharing, collaborator, repository/privacy/push, rubric-required repository-link PDF, signed Group Project Agreement, and one-member submission actions outside Prompt 26.

## 20. Requirements fully satisfied

- FR-1 through FR-18.
- NFR-3 through NFR-6, NFR-8, and NFR-9.
- React/JSX, Flexbox/Grid, Flask, PostgreSQL, local HTTP/REST integration, and local deployability.
- PRA-001 through PRA-029; PRA-004 includes the user-approved normalized FR-17 interpretation, and PRA-018 is implemented compatibly with the SRS’s unspecified capacity/allocation details.
- Score-5 implementation criteria for five pages, evidenced excellent UI/UX, Flexbox/Grid, working forms, live integration, and sophisticated logic.

## 21. Requirements remaining partial or not satisfied

- **Partially satisfied:** NFR-1, NFR-2, NFR-7; score-5 “all SRS”; private-repository/source external proof.
- **Not satisfied:** consolidated README; `ai-tooling.md`; final demo and its direct DB-effect evidence; and the applicable future manual/external recording, identity, sharing, Drive/PDF, collaborator, group, agreement, repository-link, and submission actions. These are not implementation defects or current requests for team details.
- **Not applicable:** optional `staging.md`, because the project currently uses the explicitly permitted local deployment path and no staging server is claimed.

## 22. Contradictions and user decisions

No SRS/rubric-versus-frozen-design contradiction remains. The user has authoritatively accepted the normalized FR-17 representation as fully satisfied, and FR-8/FR-18 remain compatible with the approved capacity-aware allocation. The schema-literal FR-17 caveat is internal grading preparation only, not a defect or reopening decision.

The user has also resolved the relevant interpretation questions for NFR-1/NFR-2 and confirmed a group of three. No missing requirements decision remains. A later verifier must select and disclose reasonable reproducible performance methodology, but that is an execution/evidence choice rather than a supplemental project requirement requiring current user approval. Team names, URLs, other-member repositories, collaborator invitations, and detailed submission administration are intentionally deferred manual/external matters. Gallery source categories are established: four project-supplied inputs and one project AI-generated image. No admin/authentication/cancellation/content-management gap exists.

## 23. Prompt-26 completion assessment

1. **Is every SRS functional requirement fully satisfied?** Yes. FR-1 through FR-18 are fully satisfied, including the user-approved normalized FR-17 representation and compatible FR-8/FR-18 allocation.
2. **Is every SRS NFR fully satisfied?** No. NFR-1, NFR-2, and NFR-7 lack exact evidence.
3. **Are all explicit interface/deployment requirements fully satisfied?** No. The consolidated README requirement is not satisfied.
4. **Is every approved Version-1 PRA requirement fully satisfied?** Yes. PRA-001 through PRA-029 are implemented/evidenced under the approved FR-17 and FR-8/FR-18 interpretations.
5. **Is every score-5 implementation criterion fully satisfied?** No. The operational UI/forms/integration/sophisticated-logic criteria are satisfied, but “all SRS” is partial.
6. **Which score-5 requirements remain open only because Prompt 27 has not been completed?** Required root README and `ai-tooling.md`. Gallery source categories are established and do not create a score-5 blocker.
7. **Which remain open only because Prompt 28/final submission has not been completed?** Final group 5-10 minute demo, all-site demonstration, direct database effects including normalized FR-17 evidence, applicable group visibility/speaking/ID/name, implementation discussion, Drive link, rubric-required repository-link PDF, collaborator/privacy/push/share, signed Group Project Agreement, and one-member submission. Their administration is intentionally deferred.
8. **Which remain open because Firefox/Safari evidence is deferred?** NFR-7 and the “all SRS” score-5 criterion.
9. **Are there actual implementation defects?** No operational or strict-conformance implementation defect was found in the frozen tested behavior. FR-17 requires no reopening.
10. **Are there SRS/rubric-versus-frozen-design contradictions?** No. The normalized FR-17 relation and capacity-aware FR-8/FR-18 behavior have been reconciled without weakening explicit authority.
11. **Are there missing user decisions?** No current requirements/interpretation decision is missing. Performance methodology remains a later verifier choice to document, not a new requirement; team names, URLs, collaborator actions, and submission administration are deferred and not Prompt-26 inputs.
12. **Exact least-to-most sequence?** Prompt-26 audit approval is complete. Next, select/document reasonable INT-07 methodology and quantify NFR-1/NFR-2 under the approved one-user actual-VM basis; separately obtain Firefox/Safari manual evidence in capable environments; incorporate the verification results through the project workflow; complete Prompt 27; complete Prompt 28; then perform deferred group/external submission actions. The accepted API-09 baseline failure and FR-17 are not active closure steps.
13. **Is Prompt 27 safe to begin after audit approval?** No. Prompt 26 is now approved, but Prompt 27 is **not yet safe to begin** because NFR-1/NFR-2 quantified evidence and Firefox/Safari NFR-7 evidence remain open verification gates. No earlier implementation layer must be reopened; documentation and deferred group/external administration do not themselves block Prompt 27 after those verification gates close.

**Prompt-26 approval result:** independent ChatGPT review accepted the corrected audit and the user explicitly approved it. No further work is required to approve the audit itself. The open compliance/evidence/documentation/demo/submission items remain accurately classified and must not be mistaken for closed merely because the audit is approved.

**Exact work before Prompt 27:** first perform quantified NFR-1 page-load verification and quantified NFR-2 reservation/newsletter submission verification using disclosed reproducible methodology. Firefox and Safari manual NFR-7 validation remain separately pending in capable environments and must also close according to the project verification workflow. Prompt 27 then owns the root README and `ai-tooling.md`; those missing documents are reasons to begin Prompt 27, not prerequisites to it. Prompt-28 recording and future group/external submission administration likewise occur later and do not block Prompt 27.

## 24. Explicit approval checkpoint

Prompt 26 is **APPROVED AND FROZEN**. Independent ChatGPT review accepted the corrected audit, and the user explicitly approved its findings and classifications. Audit approval does **not** mean every project requirement is closed: NFR-1 and NFR-2 remain partially satisfied pending quantified evidence, and NFR-7 remains partially satisfied with Chrome and Edge passed but Firefox and Safari manual validation pending. The next engineering/verification work is quantified NFR-1 and NFR-2 verification; Firefox/Safari evidence remains a separate later user-supplied manual gate. Prompt 27 is **not yet safe to begin**, and Prompt 28 has not begun. No implementation layer is reopened. FR-17 remains fully satisfied without implementation change, and the intentional user-created demo-query reference remains untouched and outside the Prompt-26 review delta.
