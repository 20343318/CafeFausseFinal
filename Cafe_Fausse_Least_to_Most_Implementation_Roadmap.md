# Cafe Fausse Least-to-Most Implementation Roadmap

**Roadmap version:** 1.0  
**Established:** 2026-08-14  
**Authoritative sources:** `SRS(1).pdf`, `Rubric(1).pdf`, and `Cafe_Fausse_Project_Requirements_Addendum.md` version 2.0  
**Target:** Rubric score 5  
**Required architecture order:** PostgreSQL -> Flask REST API -> React/JSX UI -> integration  
**Status:** Planning document only; no implementation code is contained in this roadmap

## 1. Purpose and governing rules

This roadmap converts the authoritative requirements into small, ordered, independently verifiable increments. It implements the least amount needed to prove each capability before adding the next dependency.

The following rules govern execution:

1. Complete the phases strictly in this order: PostgreSQL, Flask, React, integration.
2. Do not begin a later phase until the preceding phase gate has been explicitly approved.
3. Within a phase, complete increments in ID order unless a later approved impact analysis changes the roadmap.
4. An increment is complete only when its artifacts exist, its specified tests pass, its manual checks are complete where applicable, and its approval checkpoint is accepted.
5. React-phase testing uses mocks or fixtures that conform to the approved Flask contract. Live React-to-Flask connection begins only in the integration phase.
6. PostgreSQL and Flask remain authoritative for data integrity and reservation decisions. React validation and availability displays are usability aids.
7. All tests use isolated test data. Demonstration data is separate and repeatable.
8. Maintain traceability from SRS, rubric, and PRA requirements to artifacts and evidence throughout—not as a final reconstruction exercise.
9. Future Enhancements FE-001 through FE-014 in Addendum 2.0 are inactive and excluded from Version 1.
10. Avoid unnecessary enterprise mechanisms: no microservices, event bus, distributed cache, customer authentication, administrative portal, CI/CD platform, or cloud infrastructure is required for Version 1.

## 2. Phase and gate summary

| Phase | Increments | Outcome required to pass the gate |
|---|---:|---|
| PostgreSQL | DB-01 through DB-07 | A reproducible PostgreSQL layer that stores and protects customers, settings, 30 tables, reservations, and exclusive multi-table assignments under concurrency. |
| Flask REST API | API-01 through API-09 | A tested Flask API that authoritatively validates customers and reservations, discovers slots, manages newsletter preferences, creates retry-safe reservations, and logs backend failures safely. |
| React/JSX UI | UI-01 through UI-09 | A complete, responsive, accessible five-page React application whose mocked form behavior conforms to the approved API contract. |
| Integration and delivery | INT-01 through INT-09 | Connected browser-to-database workflows, verified quality attributes, complete traceability/documentation, and a rubric-compliant demonstration/submission package. |

## 3. Phase A - PostgreSQL

No Flask application implementation begins until DB-07 is approved.

### DB-01 - Persistent-data requirements and lifecycle inventory

- **Objective:** Derive every persistent datum, relationship, lifecycle rule, and source-of-truth rule before selecting database structures.
- **Requirements addressed:** SRS FR-06 to FR-08 and FR-15 to FR-18; NFR-05 and NFR-09; baseline DB-01 to DB-08; PRA-004 to PRA-025, especially PRA-006 to PRA-022.
- **Dependencies:** Approved SRS, rubric, Project Requirements Baseline, and Addendum 2.0.
- **Artifacts produced:** Approved persistent-data inventory; required/optional data matrix; lifecycle and ownership matrix; explicit mapping of structured names to SRS Customer Name; explicit mapping of one-or-more assigned tables to SRS Table Number.
- **Unit tests required:** Define database-test cases for field presence, required/optional values, normalization inputs, derived values, and lifecycle transitions; no executable database tests yet.
- **Integration tests required:** Define future database-to-Flask data scenarios for customer reuse, newsletter state, reservations, and multi-table assignments.
- **Manual verification:** Trace every persistent datum to at least one SRS, rubric, or PRA requirement; verify no separate newsletter subscriber source is introduced.
- **Completion criteria:** The inventory covers customers, structured names, optional phone, newsletter state, restaurant configuration, exactly 30 current tables, individual capacities, reservation start/end/party size, and all assigned tables, with no unresolved persistence-level business ambiguity.
- **Approval checkpoint:** Approve the persistent-data analysis before conceptual modeling.

### DB-02 - Conceptual data model

- **Objective:** Define the smallest normalized conceptual model that can express the approved data and relationships without choosing PostgreSQL implementation details prematurely.
- **Requirements addressed:** SRS FR-17 and FR-18; NFR-05 and NFR-09; PRA-015 to PRA-022; rubric database integration and direct database-effect criteria.
- **Dependencies:** DB-01 approved.
- **Artifacts produced:** Conceptual entity-relationship model; entity definitions; relationship/cardinality list; conceptual uniqueness, exclusivity, and lifecycle constraints; traceability annotations.
- **Unit tests required:** Model-review cases proving one customer per normalized email, exactly 30 Version 1 tables, one reservation-to-many assigned tables, and one current newsletter state per customer.
- **Integration tests required:** Scenario walkthroughs showing how a single-table reservation, multi-table reservation, newsletter-only customer, and existing-customer reservation traverse the model.
- **Manual verification:** Confirm that structured name fields collectively satisfy Customer Name and multi-table relationships add to rather than remove the SRS Table Number requirement.
- **Completion criteria:** Every DB-01 datum has exactly one authoritative conceptual home; no unnecessary duplicate entity or future-enhancement entity exists.
- **Approval checkpoint:** Approve the conceptual model before logical schema design.

### DB-03 - Logical PostgreSQL schema and integrity design

- **Objective:** Convert the conceptual model into an implementation-ready logical PostgreSQL design with types, keys, nullability, uniqueness, checks, indexes, and configuration representation.
- **Requirements addressed:** SRS FR-06 to FR-08 and FR-15 to FR-18; NFR-05 and NFR-09; PRA-005 to PRA-023.
- **Dependencies:** DB-02 approved.
- **Artifacts produced:** Logical schema specification; column/data-type catalogue; key and constraint catalogue; index rationale; configuration-value constraints; migration ordering; schema-to-requirement traceability.
- **Unit tests required:** Planned tests for all nullability, range, format, uniqueness, referential-integrity, configuration-value, and exactly-30 initialization rules.
- **Integration tests required:** Planned tests proving valid records can support the Flask use cases and invalid direct writes cannot bypass critical integrity rules.
- **Manual verification:** Inspect coverage of SRS minimum Customers and Reservations data plus the approved additive fields/relationships.
- **Completion criteria:** The logical design is deterministic, normalized, supports future schema extensibility without activating more than 30 tables, and leaves no schema choice unresolved for implementation.
- **Approval checkpoint:** Approve the logical schema before transaction and concurrency design.

### DB-04 - Reservation transaction and concurrency design

- **Objective:** Define atomic database behavior for availability, multi-table selection, exclusivity, overlap, duplicate suppression, exact retry, and concurrent booking.
- **Requirements addressed:** SRS FR-07 to FR-09 and FR-18; NFR-05; PRA-007, PRA-013 to PRA-018, PRA-021 to PRA-023; rubric sophisticated reservation logic.
- **Dependencies:** DB-03 approved.
- **Artifacts produced:** Transaction-boundary specification; half-open overlap predicate; eligible-combination algorithm specification; minimum-table/least-waste/random-tie order; concurrency-control decision; retry/idempotency rules; failure/rollback matrix.
- **Unit tests required:** Planned cases for all overlap shapes, back-to-back bookings, capacity combinations, tie candidates, no eligible combination, same-customer overlap, and exact retry.
- **Integration tests required:** Planned concurrent-session tests proving at most one conflicting assignment commits, all tables commit together, and failed bookings leave no partial customer/preference/reservation state.
- **Manual verification:** Walk through competing single-table and multi-table transactions against the design.
- **Completion criteria:** The design proves how PostgreSQL prevents double/overbooking and partial assignment without relying on React timing or a prior availability result.
- **Approval checkpoint:** Approve transaction/concurrency behavior before database implementation.

### DB-05 - Database foundation implementation

- **Objective:** Implement the smallest reproducible database foundation: migrations, customers, business configuration, and exactly 30 initialized tables.
- **Requirements addressed:** SRS FR-16 and FR-17; NFR-05 and NFR-09; PRA-005, PRA-006, PRA-007, PRA-010 to PRA-012, PRA-015 to PRA-017, PRA-019 to PRA-021.
- **Dependencies:** DB-03 and DB-04 approved; PostgreSQL development/test environments available.
- **Artifacts produced:** Versioned database migrations; customer/configuration/table objects; initial business configuration; 30 table records at capacity four; rollback/reset instructions; database unit-test fixtures.
- **Unit tests required:** Migration up/down or clean rebuild; required constraints; normalized-email uniqueness; name/phone/newsletter integrity; permitted configuration values; exactly 30 bookable tables; initial total capacity 120.
- **Integration tests required:** Rebuild a clean test database from migrations and verify expected seed/configuration state through database access available to the future Flask layer.
- **Manual verification:** Inspect tables, constraints, settings, and the 30 x 4 initialization using direct PostgreSQL queries.
- **Completion criteria:** A clean database can be created reproducibly and all foundation tests pass; no reservation implementation exists yet.
- **Approval checkpoint:** Approve foundation persistence before adding reservations.

### DB-06 - Reservation persistence, allocation, and concurrency implementation

- **Objective:** Add reservation storage and exclusive table assignments, then implement the approved atomic availability/allocation behavior from simplest success to concurrent conflict.
- **Requirements addressed:** SRS FR-06 to FR-09, FR-17, FR-18; NFR-05; PRA-007 to PRA-018, PRA-022, PRA-023; rubric sophisticated logic and direct database effects.
- **Dependencies:** DB-05 complete.
- **Artifacts produced:** Reservation and assignment database objects; authoritative availability/allocation database operations; indexes; deterministic test hooks for random tie selection where needed; database test dataset.
- **Unit tests required:** Valid single-table insert; valid multi-table insert; start/end/party constraints; half-open overlap; back-to-back acceptance; allocation priorities; random tie eligibility; same-customer overlap; exact retry; invalid configuration dependency.
- **Integration tests required:** Concurrent competing bookings; all-or-none multi-table assignment; rollback of reservation-linked newsletter change; no unused-seat sharing; no overlapping table participation.
- **Manual verification:** Execute representative transactions and directly inspect customer, reservation, assignment, and preference state before/after commit and rollback.
- **Completion criteria:** All correctness and concurrency tests pass repeatedly; no conflicting or partial committed state is observable.
- **Approval checkpoint:** Approve reservation persistence and concurrency evidence before hardening.

### DB-07 - PostgreSQL verification and phase gate

- **Objective:** Prove the PostgreSQL layer is complete, reproducible, performant enough for the required workflows, and ready to serve Flask.
- **Requirements addressed:** All database-applicable SRS requirements; NFR-02, NFR-05, NFR-09; PRA-001 to PRA-023; rubric PostgreSQL integration, sophisticated logic, and database-demonstration evidence.
- **Dependencies:** DB-01 through DB-06 complete.
- **Artifacts produced:** PostgreSQL verification report; schema/data dictionary; migration/seed/reset guide; test results; representative query plans/timing results; updated traceability matrix; known-limitations record.
- **Unit tests required:** Full `UT-DB-*` suite from a clean database, including constraints and configuration boundaries.
- **Integration tests required:** Full database transaction/concurrency suite under repeatable parallel attempts and clean-reset verification.
- **Manual verification:** Rebuild from nothing, inspect exactly 30 tables and settings, create single/multi-table reservations, show overlap rejection and back-to-back acceptance, and verify direct database effects.
- **Completion criteria:** Clean rebuild succeeds; all PostgreSQL tests pass; required operations meet an agreed portion of the two-second submission budget; evidence maps to every database-applicable requirement; no blocking defect remains.
- **Approval checkpoint:** **Hard Gate 1.** Explicitly approve PostgreSQL before any Flask implementation begins.

## 4. Phase B - Flask REST API

No React implementation begins until API-09 is approved.

### API-01 - Backend operation inventory

- **Objective:** Derive the minimum Flask operations and use cases from the approved database behavior without defining endpoint syntax yet.
- **Requirements addressed:** SRS FR-06 to FR-09, FR-15, FR-16, FR-18; NFR-02, NFR-05, NFR-06, NFR-09; baseline API-01 to API-07; PRA-006 to PRA-025.
- **Dependencies:** DB-07 approved.
- **Artifacts produced:** Operation catalogue for configuration/limits, daily availability, customer/newsletter-status lookup, newsletter preference setting, reservation creation/retry, and health/readiness; authorization/out-of-scope statement.
- **Unit tests required:** Define success, validation, not-found/not-applicable, conflict, unavailable, retry, database-failure, and timeout cases per operation.
- **Integration tests required:** Map every operation to required PostgreSQL behavior and database fixture state.
- **Manual verification:** Confirm no cancellation, modification, authentication, administration, or messaging operation is introduced.
- **Completion criteria:** Every required user workflow has a backend operation and every operation traces to an approved requirement.
- **Approval checkpoint:** Approve the backend operation inventory before REST-contract design.

### API-02 - Flask REST contract

- **Objective:** Define stable HTTP methods, paths, request/response fields, error codes, status codes, time representation, and retry semantics.
- **Requirements addressed:** SRS external/communication interfaces, FR-06 to FR-09, FR-15, FR-16, FR-18; NFR-06; PRA-012, PRA-014, PRA-019 to PRA-025.
- **Dependencies:** API-01 approved; DB-07 contract available.
- **Artifacts produced:** REST contract specification; normalized field definitions; error envelope; confirmation representation; complete-slot availability representation; idempotency/retry behavior; privacy/exposure rules.
- **Unit tests required:** Contract-schema cases for every request/response variant, including all-slot status, authoritative newsletter state, multi-table confirmation, and safe nontechnical errors.
- **Integration tests required:** Contract-to-database mapping cases for success, stale availability, same-customer conflict, full slot, mismatch, and safe retry.
- **Manual verification:** Review that availability responses expose no customer, reservation, table-assignment, or unnecessary capacity details.
- **Completion criteria:** React can later be built against the contract without inventing fields or business behavior.
- **Approval checkpoint:** Approve the REST contract before Flask architecture or UI contract work.

### API-03 - Flask architecture, configuration, and test strategy

- **Objective:** Choose the smallest modular Flask structure and testing approach that supports the approved contract and database layer.
- **Requirements addressed:** SRS NFR-02, NFR-06, NFR-09 and software interfaces; PRA-001 to PRA-005, PRA-012, PRA-023, PRA-024; rubric correct Flask integration.
- **Dependencies:** API-02 approved.
- **Artifacts produced:** Backend module/responsibility diagram; database-access decision; configuration/environment catalogue; connection/transaction ownership rules; exception-to-response map; safe logging plan; API test plan.
- **Unit tests required:** Planned tests for configuration loading, validation, service decisions, error mapping, log redaction, and clock/timezone abstraction.
- **Integration tests required:** Planned Flask-to-PostgreSQL fixtures, isolation/reset method, transactional cases, and performance timing method.
- **Manual verification:** Confirm the architecture is one Flask application with focused modules, not unnecessary services or infrastructure.
- **Completion criteria:** All implementation-affecting Flask decisions are explicit and approved, with test seams for clock and random tie selection.
- **Approval checkpoint:** Approve Flask architecture/test strategy before implementation.

### API-04 - Flask foundation and PostgreSQL connectivity

- **Objective:** Implement application creation, configuration, database connectivity, health/readiness, transaction scaffolding, safe errors, and backend logging before business endpoints.
- **Requirements addressed:** SRS Flask/PostgreSQL interfaces; NFR-02, NFR-06, NFR-09; PRA-001, PRA-003, PRA-004, PRA-012, PRA-024.
- **Dependencies:** API-03 approved; DB-07 approved environment and guide.
- **Artifacts produced:** Flask application foundation; configuration loader; database connection layer; health/readiness behavior; common response/error/logging utilities; foundational tests.
- **Unit tests required:** Valid/missing configuration; timezone loading; connection failure; transaction commit/rollback wrapper; safe error output; redaction of PII, secrets, credentials, and confirmation-email input.
- **Integration tests required:** Flask starts against test PostgreSQL, reports readiness only when usable, and rolls back a forced database failure.
- **Manual verification:** Start/stop the service, inspect a health response, and inspect sanitized backend logs for a forced technical error.
- **Completion criteria:** Foundation tests pass and no business endpoint has bypassed the database transaction boundary.
- **Approval checkpoint:** Approve Flask foundation before customer/newsletter operations.

### API-05 - Customer identity and newsletter-status lookup

- **Objective:** Implement authoritative normalization/matching and the asynchronous status-lookup operation used by both forms.
- **Requirements addressed:** SRS FR-06, FR-15 to FR-18; NFR-06; PRA-019, PRA-020, PRA-023 to PRA-025.
- **Dependencies:** API-04 complete.
- **Artifacts produced:** Customer validation/identity service; newsletter-status lookup endpoint behavior; generic mismatch handling; tests and API examples.
- **Unit tests required:** Name/email/middle-initial/phone validation and normalization; new customer; exact existing match; generic mismatch; no phone identity; lookup indeterminate/error mapping; no confirmation-email persistence.
- **Integration tests required:** Query existing/new customer fixtures and verify no lookup changes database state or leaks unrelated customer information.
- **Manual verification:** Submit representative normalized variants and inspect response safety and unchanged data.
- **Completion criteria:** Lookup returns only the approved authoritative preference state or safe indeterminate/mismatch outcome and has no side effects.
- **Approval checkpoint:** Approve identity/lookup behavior before preference mutation.

### API-06 - Independent newsletter preference management

- **Objective:** Implement idempotent dedicated subscribe/unsubscribe behavior against `Customers` as the single source of truth.
- **Requirements addressed:** SRS FR-15, FR-16, FR-17; NFR-02, NFR-05, NFR-06; PRA-019 to PRA-021, PRA-023, PRA-024.
- **Dependencies:** API-05 complete.
- **Artifacts produced:** Newsletter preference operation; authoritative state response; database integration; request/service tests; usage examples.
- **Unit tests required:** New selected creates; new unselected creates nothing; existing true/false transitions; same-state repeat; mismatch; validation; last-committed-write semantics; safe timeout retry.
- **Integration tests required:** Concurrent create for the same normalized email; concurrent preference updates; preservation of phone/name/reservations; direct database state verification.
- **Manual verification:** Subscribe, repeat, unsubscribe, and show the single retained customer state in PostgreSQL.
- **Completion criteria:** All preference paths are idempotent, return committed state, meet the agreed two-second budget, and never create a parallel subscriber source.
- **Approval checkpoint:** Approve newsletter preferences before reservation availability.

### API-07 - Reservation-slot discovery

- **Objective:** Implement authoritative daily slot generation and availability status for a selected date and party size.
- **Requirements addressed:** SRS FR-06 to FR-08 and FR-18; NFR-02, NFR-05, NFR-06; PRA-006 to PRA-013, PRA-015 to PRA-018, PRA-023, PRA-025.
- **Dependencies:** API-06 complete; approved database availability operations.
- **Artifacts produced:** Availability operation/endpoint; full-day slot response; validation/error behavior; controlled-clock and inventory fixtures; tests.
- **Unit tests required:** Weekday/Sunday hours; interval alignment; duration/closing; advance window; same-day lead; timezone/DST; party bounds; available/unavailable marking; no arbitrary slot; safe payload exposure.
- **Integration tests required:** Compare API results with database inventory across empty, partially occupied, fragmented, multi-table, and fully unavailable dates.
- **Manual verification:** Request weekday, Sunday, boundary, same-day, and full/fragmented examples and inspect complete slot schedules.
- **Completion criteria:** Every legitimate daily start is returned exactly once with correct provisional status, and invalid date/party inputs are safely rejected.
- **Approval checkpoint:** Approve slot discovery before reservation creation.

### API-08 - Reservation creation, confirmation, and retry safety

- **Objective:** Implement the final authoritative booking transaction, including customer handling, optional newsletter change, table allocation, conflict recovery, and confirmation.
- **Requirements addressed:** SRS FR-06 to FR-09, FR-17, FR-18; NFR-02, NFR-05, NFR-06; PRA-013, PRA-014, PRA-018 to PRA-025; rubric sophisticated logic.
- **Dependencies:** API-07 complete.
- **Artifacts produced:** Reservation-creation operation/endpoint; confirmation and failure responses; idempotency/retry behavior; transactional integration; tests and examples.
- **Unit tests required:** Full validation; exact retry; changed overlapping request; customer mismatch; phone/middle-initial rules; newsletter unchanged/changed; confirmation completeness; message/error mapping.
- **Integration tests required:** Single/multi-table success; stale slot; full slot; same-customer overlap; simultaneous conflicts; atomic preference+reservation; rollback on forced failure; safe network retry; direct database verification.
- **Manual verification:** Create a reservation, inspect all confirmation fields and assigned tables, retry it, force a conflict, and inspect committed database state.
- **Completion criteria:** Only valid, available, fully committed reservations succeed; retries do not duplicate; all errors are safe; processing meets the agreed two-second budget.
- **Approval checkpoint:** Approve the complete booking operation before API hardening.

### API-09 - Flask verification and phase gate

- **Objective:** Verify the entire Flask contract, quality attributes, logging, and database integration before React implementation.
- **Requirements addressed:** All API-applicable SRS requirements; NFR-02, NFR-05, NFR-06, NFR-09; PRA-001 to PRA-025; rubric Flask/database/form integration.
- **Dependencies:** API-01 through API-08 complete.
- **Artifacts produced:** Flask verification report; passing unit/integration results; contract examples; performance evidence; logging/redaction evidence; updated traceability; known-limitations record.
- **Unit tests required:** Full `UT-API-*` suite for configuration, validation, services, errors, clock, randomness test seam, retry semantics, and log redaction.
- **Integration tests required:** Full `IT-DBAPI-*` suite against a clean PostgreSQL database, including concurrency, rollback, and timing.
- **Manual verification:** Exercise every endpoint without a browser and directly compare results with PostgreSQL state and logs.
- **Completion criteria:** All contract variants are implemented and tested; no database rule is redefined inconsistently; no critical defect or unresolved React-blocking contract issue remains.
- **Approval checkpoint:** **Hard Gate 2.** Explicitly approve Flask before any React implementation begins.

## 5. Phase C - React/JSX UI

During this phase, API behavior is mocked from the approved Flask contract. Live connection begins only after UI-09.

### UI-01 - Content, asset, and React architecture analysis

- **Objective:** Inventory required content/assets and define a minimal React page/component architecture before visual implementation.
- **Requirements addressed:** SRS FR-01 to FR-16, user-interface requirements, NFR-03, NFR-04, NFR-07 to NFR-09; rubric five pages, excellent UI/UX, images, and Flexbox/Grid; PRA-001 to PRA-004.
- **Dependencies:** API-09 approved; supplied image collection available or asset gaps explicitly recorded.
- **Artifacts produced:** Content matrix; asset inventory and attribution/licensing record; page map; component-responsibility plan; routing decision; shared-layout plan; deferred copy/asset decisions requiring approval.
- **Unit tests required:** Planned render/content/navigation tests and asset fallback/alt-text checks.
- **Integration tests required:** Planned route-to-page and shared-layout tests using no live API.
- **Manual verification:** Compare every required menu item, price, address, phone, hour, history element, award, review, and gallery category to the SRS.
- **Completion criteria:** All five pages and required content have an approved home; missing assets/copy are resolved without adding unsupported claims.
- **Approval checkpoint:** Approve content/assets/architecture before detailed UX design.

### UI-02 - Reservation, newsletter, and accessibility UX design

- **Objective:** Define responsive user flows and states for reservations and newsletter preferences before building components.
- **Requirements addressed:** SRS FR-06 to FR-09, FR-13, FR-15, FR-16; NFR-03, NFR-04, NFR-06 to NFR-08; PRA-014, PRA-019 to PRA-025; rubric excellent UX and working forms.
- **Dependencies:** UI-01 approved; approved Flask contract.
- **Artifacts produced:** Wireflows/state matrices for full-day slots, structured identity, async preference, review/submission, confirmation, newsletter preferences, lightbox, errors, focus, loading, stale responses, and mobile navigation.
- **Unit tests required:** Planned component-state, keyboard, focus, accessible-name/status, stale-response, double-click, and validation tests.
- **Integration tests required:** Mock-contract scenarios for success, unavailable, mismatch, lookup failure, network ambiguity, and safe retry.
- **Manual verification:** Keyboard-only and screen-reader-oriented design review; verify unavailable slots do not rely on color alone.
- **Completion criteria:** Every API outcome has an approved nontechnical, accessible UI state and all pending/invalidating transitions are deterministic.
- **Approval checkpoint:** Approve the UX/state model before visual system and component tests.

### UI-03 - Visual system and React test strategy

- **Objective:** Approve the smallest reusable visual system and UI testing structure needed for a polished score-5 result.
- **Requirements addressed:** SRS FR-03, NFR-03, NFR-04, NFR-07 to NFR-09, user-interface requirements; rubric excellent UI/UX and Flexbox/Grid.
- **Dependencies:** UI-02 approved.
- **Artifacts produced:** Brand/color/type/spacing decisions; responsive breakpoint/device matrix; Flexbox/Grid layout plan; interaction/focus styles; browser test matrix; React unit/integration test plan.
- **Unit tests required:** Planned tests for shared controls, responsive navigation states, accessibility attributes, and visual-state classes.
- **Integration tests required:** Planned mocked page/form flows across representative desktop, tablet, and mobile viewports.
- **Manual verification:** Contrast, typography, spacing, focus visibility, touch-target, and representative-browser design review.
- **Completion criteria:** Visual and test decisions are approved, consistent, feasible, and introduce no unnecessary component framework or state infrastructure.
- **Approval checkpoint:** Approve visual/test strategy before React foundation implementation.

### UI-04 - React shell, routing, navigation, and shared layout

- **Objective:** Implement the smallest navigable React/JSX application with shared responsive structure.
- **Requirements addressed:** SRS FR-01, FR-02, FR-04, React/JSX and CSS interface constraints; NFR-03, NFR-04, NFR-07 to NFR-09; rubric five-page navigation and Flexbox/Grid.
- **Dependencies:** UI-03 approved.
- **Artifacts produced:** React application shell; five routes/pages as placeholders; shared header/navigation/footer/contact/hours; responsive navigation; base styles; tests.
- **Unit tests required:** Route rendering, navigation links, active/focus state, mobile navigation, shared contact/hours content, and not-found behavior if approved.
- **Integration tests required:** Mocked browser navigation among all five routes with no live API.
- **Manual verification:** Navigate with pointer and keyboard at desktop/mobile widths and compare contact/hours to SRS.
- **Completion criteria:** All five routes are reachable, navigation works accessibly, and the shell is responsive and visually consistent.
- **Approval checkpoint:** Approve the application shell before page content.

### UI-05 - Static required pages and gallery lightbox

- **Objective:** Complete Home, Menu, About Us, and Gallery content/interactions before adding data-entry workflows.
- **Requirements addressed:** SRS FR-01 to FR-05 and FR-10 to FR-14; NFR-01, NFR-03, NFR-04, NFR-07 to NFR-09; rubric required pages, visuals, UX, Flexbox/Grid.
- **Dependencies:** UI-04 complete; approved assets/copy.
- **Artifacts produced:** Complete static pages; exact menu content/prices; history/founder/mission content; gallery categories; awards/reviews; accessible lightbox; optimized images; tests.
- **Unit tests required:** Required content presence; menu grouping/prices; awards/reviews; image alt text; lightbox open/close, keyboard, focus return, and escape behavior.
- **Integration tests required:** Navigation-to-content and lightbox interaction flows using the full React shell.
- **Manual verification:** Visual review at representative viewports and browsers; inspect image quality, cropping, loading, and thematic consistency.
- **Completion criteria:** Four content pages fully satisfy FR-01 to FR-05 and FR-10 to FR-14 with no missing or invented authoritative content.
- **Approval checkpoint:** Approve static pages before newsletter UI.

### UI-06 - Dedicated newsletter preferences UI with mocked API

- **Objective:** Implement the dedicated newsletter subscribe/unsubscribe form and asynchronous status synchronization against contract-faithful mocks.
- **Requirements addressed:** SRS FR-15, FR-16; NFR-02, NFR-03, NFR-06, NFR-08; PRA-019 to PRA-021, PRA-023 to PRA-025; rubric working forms.
- **Dependencies:** UI-05 complete; API-02 contract; UI-02 states.
- **Artifacts produced:** Newsletter preferences form; structured name/email confirmation controls; async/debounced lookup state; explicit checkbox; success/error/indeterminate states; mocked API adapter; tests.
- **Unit tests required:** Field constraints, email confirmation, async debounce/blur behavior, stale-result suppression, checkbox synchronization, pending disablement, new-unselected behavior, mismatch, retry, and accessible feedback.
- **Integration tests required:** Mocked new subscribe, existing unsubscribe, repeated state, lookup failure, and network failure flows.
- **Manual verification:** Keyboard/mobile completion of subscribe and unsubscribe paths; verify wording never implies an unchecked unknown state means unsubscribed.
- **Completion criteria:** The form conforms exactly to the Flask contract and all mocked states pass without live backend access.
- **Approval checkpoint:** Approve newsletter UI before reservation UI.

### UI-07 - Reservation availability and slot-selection UI with mocked API

- **Objective:** Implement the availability-first reservation start: party size, date, complete daily slots, selection, and invalidation.
- **Requirements addressed:** SRS FR-06 to FR-08; NFR-03, NFR-06, NFR-08; PRA-006 to PRA-012, PRA-015 to PRA-018, PRA-023, PRA-025; rubric sophisticated logic presentation and working form.
- **Dependencies:** UI-06 complete; API-02 contract; UI-02 states.
- **Artifacts produced:** Party/date controls; dynamic bound display; availability request state; complete slot schedule; selectable available slots; disabled/labelled unavailable slots; refetch/invalidation behavior; mocks and tests.
- **Unit tests required:** Date/party validation; full schedule rendering; keyboard selection; non-color unavailable indication; pending/empty/error; changing inputs clears selection; stale response suppression; no arbitrary time entry.
- **Integration tests required:** Mocked weekday/Sunday, same-day lead, partial/full, changed-party, and stale-availability flows.
- **Manual verification:** Inspect/operate the schedule at mobile/desktop widths and with keyboard; verify no pre-submission table promise or customer data exposure.
- **Completion criteria:** Users can understand and select only provisionally available API-supplied slots, and changes deterministically invalidate stale selection.
- **Approval checkpoint:** Approve availability UI before reservation completion.

### UI-08 - Reservation details, submission, confirmation, and recovery with mocked API

- **Objective:** Complete the reservation form from customer details through review, pending submission, confirmation, and recoverable failures.
- **Requirements addressed:** SRS FR-06 to FR-09; NFR-02, NFR-03, NFR-06, NFR-08; PRA-014, PRA-019, PRA-023 to PRA-025; rubric correctly implemented reservation form.
- **Dependencies:** UI-07 complete.
- **Artifacts produced:** Structured customer fields; reservation newsletter checkbox/status; review state; single-submit protection; distinct confirmation page; all approved error/retry states; browser-console UI error handling; tests.
- **Unit tests required:** Field rules; existing-customer mismatch; phone/middle-initial behavior; lookup failure/no-change; double-click; confirmation fields; full/stale/same-customer/network/unexpected errors; focus/status; no email/SMS claim.
- **Integration tests required:** Contract-faithful mocked success, exact retry, unavailable refresh, ambiguous network retry, and preserved-form failure workflows.
- **Manual verification:** Complete every major flow by keyboard/mobile; inspect friendly wording and ensure technical detail/PII is not exposed.
- **Completion criteria:** The complete mocked reservation flow matches the approved contract and retains user data safely through recoverable failures.
- **Approval checkpoint:** Approve functional reservation UI before final UI hardening.

### UI-09 - React quality verification and phase gate

- **Objective:** Verify all required React pages, forms, content, responsiveness, accessibility, browser behavior, and frontend performance before live integration.
- **Requirements addressed:** All UI-applicable SRS requirements; NFR-01, NFR-03, NFR-04, NFR-06 to NFR-09; PRA-023 to PRA-025; rubric five pages, excellent UI/UX, Flexbox/Grid, and working forms.
- **Dependencies:** UI-01 through UI-08 complete.
- **Artifacts produced:** React verification report; passing unit/mock-integration results; responsive/browser matrix; accessibility and page-load evidence; asset attribution; updated traceability; known-limitations record.
- **Unit tests required:** Full `UT-UI-*` suite for components, content, form states, accessibility semantics, and error handling.
- **Integration tests required:** Full mocked `IT-APIUI-*` contract-flow suite for newsletter and reservation behavior.
- **Manual verification:** All five pages in representative browsers and desktop/tablet/mobile viewports; keyboard navigation; lightbox; forms; visual polish; network-size/load review.
- **Completion criteria:** All required pages and mocked workflows pass; representative page load meets the three-second requirement under agreed conditions; no critical accessibility, compatibility, or UX defect remains.
- **Approval checkpoint:** **Hard Gate 3.** Explicitly approve React before connecting it to Flask.

## 6. Phase D - Integration, quality, documentation, and delivery

### INT-01 - Integration environment and contract alignment

- **Objective:** Establish a reproducible full-stack environment and verify configuration/contract alignment before connecting a user workflow.
- **Requirements addressed:** SRS software/communication/deployment interfaces; NFR-05, NFR-09; baseline INT-01, INT-02, DEP-01, DEP-02; PRA-001 to PRA-005.
- **Dependencies:** DB-07, API-09, and UI-09 approved.
- **Artifacts produced:** Integrated environment configuration; API base/proxy/CORS decision; test/demo database isolation and reset plan; startup order; contract comparison report; integration smoke checklist.
- **Unit tests required:** Re-run layer unit suites unchanged to prove integration configuration did not regress them.
- **Integration tests required:** Database readiness, Flask readiness, React load, one safe read-only API call, and clean test-data reset.
- **Manual verification:** Start all three layers from documented commands and verify no secrets or machine-specific paths are committed.
- **Completion criteria:** The environment starts reproducibly and the React adapter matches the live Flask contract without business workflow mutation yet.
- **Approval checkpoint:** Approve integration foundation before connecting newsletter behavior.

### INT-02 - Newsletter status and preferences end-to-end

- **Objective:** Connect and verify the complete customer lookup and dedicated subscribe/unsubscribe workflow from React through Flask to PostgreSQL.
- **Requirements addressed:** SRS FR-15 to FR-18; NFR-02, NFR-05, NFR-06; PRA-019 to PRA-021, PRA-023 to PRA-025; rubric newsletter form and direct database effects.
- **Dependencies:** INT-01 complete.
- **Artifacts produced:** Live newsletter integration; end-to-end fixtures; database evidence queries; passing E2E tests; defect records/resolutions.
- **Unit tests required:** Re-run affected customer/newsletter API and UI unit suites.
- **Integration tests required:** New subscribe; existing lookup; unsubscribe; repeat/idempotency; new-unselected no record; mismatch; lookup failure; concurrent same-email creation; direct database assertions.
- **Manual verification:** Perform subscribe/unsubscribe in the browser and show the matching single customer state directly in PostgreSQL.
- **Completion criteria:** Every newsletter path returns/display authoritative state, meets the two-second target under agreed conditions, and produces exactly the approved database effect.
- **Approval checkpoint:** Approve newsletter end-to-end before connecting reservations.

### INT-03 - Reservation availability end-to-end

- **Objective:** Connect party/date selection to live Flask slot discovery and PostgreSQL availability.
- **Requirements addressed:** SRS FR-06 to FR-08, FR-18; NFR-02, NFR-05, NFR-06; PRA-006 to PRA-013, PRA-015 to PRA-018, PRA-023, PRA-025.
- **Dependencies:** INT-02 complete.
- **Artifacts produced:** Live slot integration; controlled date/inventory fixtures; E2E availability tests; timing evidence.
- **Unit tests required:** Re-run affected availability service and slot UI unit suites.
- **Integration tests required:** Weekday/Sunday; window/lead boundaries; full schedule; partial/full inventory; multi-table fragmentation; input-change refetch; stale-response handling; database/API/UI agreement.
- **Manual verification:** Change date/party size and visually compare selectable/unavailable slots with direct database inventory.
- **Completion criteria:** React accurately displays every live authoritative slot status without exposing internal/customer data and within the two-second form-operation target.
- **Approval checkpoint:** Approve live availability before booking mutation.

### INT-04 - Successful reservation end-to-end

- **Objective:** Connect and verify a successful browser-to-database reservation, including customer handling, optional preference, exclusive allocation, and confirmation.
- **Requirements addressed:** SRS FR-06 to FR-09, FR-17, FR-18; NFR-02, NFR-05, NFR-06; PRA-014 to PRA-025; rubric integrated reservation system and database effects.
- **Dependencies:** INT-03 complete.
- **Artifacts produced:** Live booking integration; single/multi-table E2E fixtures; confirmation/database evidence; successful-flow tests.
- **Unit tests required:** Re-run affected booking API and reservation UI unit suites.
- **Integration tests required:** New/existing customer; single/multiple tables; newsletter unchanged/subscribe/unsubscribe; exact retry; confirmation-field/database agreement; no duplicate records.
- **Manual verification:** Book from browser, inspect confirmation, and directly query customer, reservation, assignments, and newsletter state.
- **Completion criteria:** One submission creates exactly one correct atomic booking, assigned tables are exclusive, confirmation is complete/nontechnical, and processing meets the two-second target.
- **Approval checkpoint:** Approve successful reservation integration before failure/concurrency testing.

### INT-05 - Reservation failure, stale state, and safe retry end-to-end

- **Objective:** Verify the integrated application recovers correctly from all expected business and communication failures.
- **Requirements addressed:** SRS FR-07 to FR-09, FR-18; NFR-05, NFR-06; PRA-014, PRA-019, PRA-021 to PRA-025.
- **Dependencies:** INT-04 complete.
- **Artifacts produced:** Negative-path E2E suite; fault fixtures; verified error/focus/form-preservation behavior; log-safety evidence.
- **Unit tests required:** Re-run message mapping, retry, validation, and stale-response suites.
- **Integration tests required:** Full/stale slot; same-customer overlap; identity mismatch; invalid direct payload; lookup failure with reservation/no preference change; forced backend failure; ambiguous network retry; rollback/no partial data.
- **Manual verification:** Trigger representative failures, inspect user wording/focus/form state, backend logs, browser console, and unchanged/rolled-back database state.
- **Completion criteria:** Every failure produces approved recovery behavior, safe logs/messages, and no corrupt or partial data.
- **Approval checkpoint:** Approve failure handling before concurrency stress.

### INT-06 - Concurrent booking and data-integrity proof

- **Objective:** Demonstrate that stale availability and simultaneous requests cannot cause double/overbooking or shared tables.
- **Requirements addressed:** SRS FR-07, FR-08, FR-18; NFR-05; PRA-013, PRA-014, PRA-018, PRA-021 to PRA-025; rubric sophisticated reservation logic.
- **Dependencies:** INT-05 complete.
- **Artifacts produced:** Repeatable concurrency harness/procedure; concurrent E2E/integration results; database integrity queries; sophisticated-logic demonstration notes.
- **Unit tests required:** Re-run all database/API overlap, exclusivity, idempotency, and allocation tests.
- **Integration tests required:** Simultaneous same-table demand; competing multi-table combinations; same-customer duplicate/different overlap; exact retry; concurrent customer/preference creation; all-or-none commit under forced conflict.
- **Manual verification:** Run a controlled competition and directly show that only valid winners committed and no table appears in overlapping reservations.
- **Completion criteria:** Repeated runs preserve all invariants and produce user-friendly loser outcomes without partial state.
- **Approval checkpoint:** Approve concurrency/data-integrity evidence before nonfunctional verification.

### INT-07 - Performance, responsiveness, compatibility, and usability verification

- **Objective:** Verify the integrated application against the SRS performance, browser, device, responsiveness, usability, and reliability expectations.
- **Requirements addressed:** SRS NFR-01 to NFR-08; FR-03, FR-04, FR-13; rubric excellent UI/UX and Flexbox/Grid.
- **Dependencies:** INT-06 complete; test conditions for “standard broadband” and two-second submissions documented.
- **Artifacts produced:** Performance results; representative browser/device matrix; responsive screenshots/evidence; accessibility/usability checklist; defect resolutions; accepted limitations.
- **Unit tests required:** Re-run all layer suites after performance/compatibility fixes.
- **Integration tests required:** Page-load timing; newsletter/reservation timing; Chrome, Firefox, Safari, and Edge coverage where available; desktop/tablet/mobile viewports; link, lightbox, keyboard, and failure behavior.
- **Manual verification:** Visual/interaction review on representative real browsers or documented emulation, including slow-network conditions.
- **Completion criteria:** Pages load within three seconds and forms process within two seconds under documented agreed conditions; major browsers/devices have evidence or a clearly approved limitation; no critical UX/reliability defect remains.
- **Approval checkpoint:** Approve nonfunctional evidence before final traceability/documentation.

### INT-08 - Traceability, repository, deployment, and documentation completion

- **Objective:** Complete the maintained evidence package proving all SRS, rubric, and PRA requirements are implemented and reproducible.
- **Requirements addressed:** SRS NFR-09 and deployment requirements; baseline DEP-01 to DEP-10; rubric repository, README, AI-tooling, academic-integrity, and score-5 completeness criteria; PRA-001 to PRA-025.
- **Dependencies:** INT-07 complete; deployment choice and individual/group status resolved.
- **Artifacts produced:** Final traceability matrix; `README.md`; `ai-tooling.md`; optional `staging.md`; deployment/run/database setup instructions; dependency/configuration inventory; image/source citations; test summary; private repository readiness checklist.
- **Unit tests required:** Full clean-run unit suite using documented setup.
- **Integration tests required:** Clean-machine/environment rehearsal from README through database initialization, Flask, React, and core E2E workflows.
- **Manual verification:** Audit every FR, NFR, PRA, DEP, and RUB item; verify repository contains all source and required docs but no secrets/test artifacts; confirm `quantic-grader` collaborator procedure.
- **Completion criteria:** Every active requirement has implemented/verified evidence; inactive enhancements are absent; another reviewer can run the application using README instructions.
- **Approval checkpoint:** Approve documentation/traceability before demonstration production.

### INT-09 - Demonstration, submission, and final release gate

- **Objective:** Produce and verify the complete rubric-compliant demonstration and submission package without changing application scope.
- **Requirements addressed:** Rubric RUB-01 to RUB-15; baseline DEP-03 to DEP-10; all SRS requirements as demonstrated; PRA-024 and PRA-025 presentation behavior.
- **Dependencies:** INT-08 complete; individual/group submission details, recording method, Drive sharing, and final PDF format resolved.
- **Artifacts produced:** Approximately 5-10-minute demonstration script; repeatable demo seed/reset data; presenter checklist; recorded video; Google Drive sharing verification; repository-link PDF; group agreement if applicable; final release checklist.
- **Unit tests required:** Final unchanged full unit suite with archived result summary.
- **Integration tests required:** Final smoke/E2E rehearsal covering five pages/navigation, responsive view, lightbox, newsletter database effect, successful reservation database effect, unavailable/full behavior, multi-table/exclusivity logic, and safe errors.
- **Manual verification:** Confirm presenter visibility, government-issued ID/name step, speaking requirements, recording length, all rubric demonstration elements, direct PostgreSQL evidence rather than an admin page, repository access, Drive link access without “Invite People,” and submission files.
- **Completion criteria:** The final build is unchanged after the successful rehearsal; all automated/manual checks pass; video and submission links open with the intended permissions; every rubric score-5 criterion has evidence.
- **Approval checkpoint:** **Hard Gate 4 / final release approval.** Authorize project submission only after the complete checklist passes.

## 7. Cross-phase traceability summary

| Requirement group | Primary roadmap increments |
|---|---|
| SRS FR-01 to FR-05 | UI-01, UI-04, UI-05, UI-09, INT-07, INT-09 |
| SRS FR-06 to FR-09 | DB-01 to DB-07; API-01 to API-09; UI-02, UI-07 to UI-09; INT-03 to INT-07, INT-09 |
| SRS FR-10 to FR-14 | UI-01, UI-04, UI-05, UI-09, INT-07, INT-09 |
| SRS FR-15 to FR-16 | DB-01 to DB-05, DB-07; API-01 to API-06, API-09; UI-02, UI-06, UI-09; INT-02, INT-05, INT-07 to INT-09 |
| SRS FR-17 to FR-18 | DB-01 to DB-07; API-01 to API-09; INT-02 to INT-06, INT-08, INT-09 |
| SRS NFR-01 to NFR-02 | DB-07, API-06 to API-09, UI-05 to UI-09, INT-02 to INT-04, INT-07, INT-09 |
| SRS NFR-03 to NFR-04 | UI-01 to UI-09, INT-07, INT-09 |
| SRS NFR-05 to NFR-06 | DB-03 to DB-07; API-02 to API-09; UI-02, UI-06 to UI-09; INT-02 to INT-07, INT-09 |
| SRS NFR-07 to NFR-08 | UI-01 to UI-05, UI-09, INT-07, INT-09 |
| SRS NFR-09 | Every phase gate, especially DB-07, API-09, UI-09, INT-08 |
| PRA-001 to PRA-005 | Roadmap governance and all hard gates |
| PRA-006 to PRA-014 | DB-01 to DB-07; API-01, API-02, API-07 to API-09; UI-02, UI-07 to UI-09; INT-03 to INT-07 |
| PRA-015 to PRA-018 | DB-01 to DB-07; API-07 to API-09; UI-07 to UI-09; INT-03 to INT-06, INT-09 |
| PRA-019 to PRA-021 | DB-01 to DB-07; API-05, API-06, API-08, API-09; UI-02, UI-06, UI-08, UI-09; INT-02, INT-04 to INT-06 |
| PRA-022 | DB-01, DB-02, DB-06; API-01, API-08; UI-01, UI-02; INT-08 scope audit |
| PRA-023 to PRA-025 | DB-03 to DB-07; API-02 to API-09; UI-02 to UI-09; INT-02 to INT-09 |
| Rubric score-5 implementation | All four phase gates; especially UI-09 and INT-02 to INT-09 |
| Rubric documentation/submission | INT-08 and INT-09 |

## 8. Approval and evidence record

For each increment, record:

| Field | Required record |
|---|---|
| Increment ID | Stable roadmap ID |
| Status | Not started, in progress, ready for review, approved, blocked, or superseded |
| Approval | Approver, date, and approval message/reference |
| Requirements | FR/NFR/PRA/RUB/DEP IDs covered |
| Artifacts | Repository/document paths and version identifiers |
| Unit evidence | Test IDs, run date, result, and report location |
| Integration evidence | Test IDs, environment, run date, result, and report location |
| Manual evidence | Checklist, screenshot, database query result, or demo timestamp |
| Defects/limitations | Open item, severity, owner, and disposition |
| Next authorized increment | The single next increment or phase unlocked by approval |

## 9. Deferred decisions scheduled by this roadmap

These are technical or presentation decisions, not unresolved Prompt 1 business rules. Resolve them only at their scheduled increment:

| Decision area | Resolve by |
|---|---|
| PostgreSQL types, keys, constraints, indexes, configuration structure, and assignment representation | DB-03 |
| Transaction isolation/locking, atomic allocation, and exact retry mechanism | DB-04 |
| Flask endpoint paths, methods, payloads, status/error codes | API-02 |
| Flask modules, database access approach, configuration, logging framework, and test fixtures | API-03 |
| React page/component architecture, content placement, asset selection, and routing | UI-01 |
| Reservation/newsletter interaction details and accessible states | UI-02 |
| Visual identity, breakpoints, and browser/device test matrix | UI-03 |
| API base URL, development proxy/CORS, integrated seed/reset, and test/demo isolation | INT-01 |
| Quantified performance test conditions | No later than INT-07; preferably documented during API-03/UI-03 |
| Local-only versus staging, dependency/version policy, repository identity/workflow, and attribution format | Before INT-08 |
| Individual/group status, recording/sharing method, and submission-PDF format | Before INT-09 |

## 10. Scope exclusions

The roadmap does not authorize authentication, verified profiles, automatic prefilling, email-ownership verification, cancellation, modification/rescheduling, no-show handling, administrative reservation management, exceptional-closure configuration, subscription-history/audit events, confirmation email/SMS, table adjacency modeling, more than 30 active Version 1 tables, or customer self-service contact updates.

If an approved requirement changes later, perform the supplemental-requirement impact analysis before modifying the roadmap or implementation.

## 11. Roadmap completion condition

The roadmap is complete when Hard Gates 1 through 4 have been explicitly approved, every active SRS/rubric/PRA requirement has linked implementation and verification evidence, the final demonstration has been rehearsed successfully, and the submission package has passed its access and completeness checks.

No application code was generated in producing this roadmap.
