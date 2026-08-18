# Cafe Fausse Project Requirements Baseline

**Baseline version:** 1.0  
**Established:** 2026-08-13  
**Authoritative sources:** `SRS(1).pdf` (7 pages) and `Rubric(1).pdf` (9 pages), read in full  
**Implementation order:** PostgreSQL -> Flask REST API -> React/JSX UI -> integration  
**Implementation strategy:** least-to-most  
**Status:** analysis and planning only; no application code has been generated

## 1. Baseline governance

1. The SRS and rubric are fixed authoritative documents. Their explicit requirements may be clarified but not contradicted or silently weakened.
2. The target is the rubric's score-5 standard: all SRS requirements, all submission requirements, excellent UI/UX, working forms, correct full-stack integration, a complete demonstration, visible database effects, and the required AI-tooling documentation.
3. The separate `Cafe_Fausse_Project_Requirements_Addendum.md` records only approved supplemental business rules, refinements, constraints, and design decisions.
4. An unresolved item in this baseline is not permission to invent a requirement. Decisions that affect behavior, scope, data, architecture, verification, or the demonstration require approval before implementation.
5. Optional enhancements remain outside the committed scope unless explicitly approved and added to the addendum.

### Classification key

| Label | Meaning |
|---|---|
| SRS | Explicit requirement in `SRS(1).pdf` |
| RUB | Explicit requirement in `Rubric(1).pdf` |
| DEC | Implementation or operational decision still required; not yet a requirement |
| OPT | Optional enhancement; excluded unless approved |
| ADD | Approved supplemental constraint recorded in the addendum |

## 2. Functional requirements inventory

### 2.1 Explicit SRS functional requirements

| ID | Requirement | Source | Primary verification |
|---|---|---|---|
| FR-01 | Display the Cafe Fausse name prominently on the Home page. | SRS §3.1.1, p.2 | UI inspection |
| FR-02 | Display the specified address, phone number, and business hours. | SRS §3.1.1, pp.2-3 | UI inspection |
| FR-03 | Use high-quality images and a consistent theme. | SRS §3.1.1, p.3 | UI review |
| FR-04 | Provide navigation to Menu, Reservations, About Us, and Gallery. | SRS §3.1.1, p.3 | Navigation test |
| FR-05 | Display the complete specified menu, segmented into Starters, Main Courses, Desserts, and Beverages, with the specified descriptions and prices. | SRS §3.1.2, pp.3-4 | Content/UI test |
| FR-06 | Provide a reservation form with date/time slot, number of guests, customer name, email, and optional phone number. | SRS §3.1.3, p.4 | Form/UI test |
| FR-07 | Validate that the selected time slot is valid and available. | SRS §3.1.3, p.4 | API and integration tests |
| FR-08 | When a slot is available, integrate with the backend to assign a random table from 30 total tables. | SRS §3.1.3, p.4 | Database/API/integration tests |
| FR-09 | Show a booking-success message or, when the slot is fully booked, an error asking the customer to choose another time. | SRS §3.1.3, p.4; Rubric p.3 | UI/API integration test |
| FR-10 | Present the specified Cafe Fausse history, including the 2010 founding, founders, culinary concept, and mission. | SRS §3.1.4, p.4 | Content/UI test |
| FR-11 | Include founder biographies and the commitments to an unforgettable dining experience, excellent food, and locally sourced ingredients. | SRS §3.1.4, p.4 | Content/UI test |
| FR-12 | Display high-resolution images of the interior, menu dishes, special events, and behind-the-scenes activity. | SRS §3.1.5, pp.4-5 | Content/UI review |
| FR-13 | Provide a lightbox for enlarged gallery-image viewing. | SRS §3.1.5, p.5 | UI interaction test |
| FR-14 | Feature all specified awards and positive customer reviews. | SRS §3.1.5, p.5 | Content/UI test |
| FR-15 | Provide a newsletter email-signup form with proper email-format validation. | SRS §3.1.6, p.5 | Form/UI/API test |
| FR-16 | Store submitted newsletter email addresses in the backend database for future marketing. | SRS §3.1.6, p.5; Rubric p.3 | Database/integration test |
| FR-17 | Use PostgreSQL with, at minimum, Customers and Reservations tables containing the fields named in the SRS. | SRS §3.1.7, p.5 | Schema inspection |
| FR-18 | Use Flask logic to insert customer records, check time-slot availability, assign a random available table from 30, and return confirmation or error messages. | SRS §3.1.7, pp.5-6 | API/unit/integration tests |

### 2.2 Explicit functional scope stated elsewhere in the sources

| ID | Requirement | Source | Classification |
|---|---|---|---|
| FS-01 | Provide at least five pages: Main/Home, Menu, Reservations, About Us, and Gallery. | SRS §2.2; Rubric pp.3, 4, 6 | SRS + RUB |
| FS-02 | Provide newsletter signup and a fully functional reservation backend. | SRS §2.2, pp.1-2 | SRS |
| FS-03 | The site is intended for customers; administrators/managers are identified as users responsible for content, menu management, and reservation oversight. | SRS §2.3, p.2 | SRS context; no corresponding admin functions are specified |
| FS-04 | Test all links and intended behavior. | Rubric p.3 | RUB |
| FS-05 | Demonstrate the correct effect of reservations and newsletter signups on the backend database itself, not through an admin page. | Rubric pp.4, 6-7 | RUB |

## 3. Non-functional requirements inventory

| ID | Requirement | Source | Primary verification | Operational gap |
|---|---|---|---|---|
| NFR-01 | Website loads within 3 seconds on a standard broadband connection. | SRS §3.2.1, p.6 | Performance measurement | Test device, browser, connection profile, dataset, warm/cold cache, and percentile are undefined. |
| NFR-02 | Reservation and newsletter submissions are processed within 2 seconds. | SRS §3.2.1, p.6 | API/integration timing | Start/end points, load, environment, and percentile are undefined. |
| NFR-03 | Interface is intuitive and easy to navigate. | SRS §3.2.2, p.6 | Heuristic/usability review | Acceptance criteria and evaluator are undefined. |
| NFR-04 | Design is visually appealing and consistent with the brand identity. | SRS §3.2.2, p.6; Rubric pp.6-7 | UI/UX review | Brand system and objective acceptance criteria are absent. |
| NFR-05 | Reservation data integrity is maintained; double and over-bookings are prevented. | SRS §3.2.3, p.6 | Concurrency and database tests | Booking/capacity semantics must be defined. |
| NFR-06 | Failures are handled in a user-friendly manner. | SRS §3.2.3, p.6 | Failure-path tests | Required failure cases and message style are undefined. |
| NFR-07 | Application is compatible with Chrome, Firefox, Safari, and Edge. | SRS §3.2.4, p.6 | Browser test matrix | Supported versions and operating systems are undefined. |
| NFR-08 | Design is responsive on desktop, tablet, and smartphone devices. | SRS §3.2.4, p.6 | Responsive UI tests | Breakpoints, orientations, and target viewport sizes are undefined. |
| NFR-09 | Code is modular and well documented for future updates. | SRS §3.2.5, p.6 | Code/documentation review | Module boundaries and documentation standard are undefined. |
| NFR-10 | Application operates consistently across major browsers and mobile devices. | SRS §2.4, p.2 | Cross-platform test | “Consistently” requires acceptance criteria. |
| NFR-11 | The UI is clean, modern, and consistently styled using CSS Flexbox or Grid. | SRS §3.3.1, p.6; Rubric pp.3, 6-9 | UI/code review | Exact design system remains a decision. |
| NFR-12 | Client-server communication uses HTTP/HTTPS and RESTful API endpoints. | SRS §3.3.3, p.7 | Architecture/API inspection | Local HTTP versus deployed HTTPS remains a deployment decision. |

## 4. PostgreSQL requirements

### 4.1 Explicit requirements

| ID | Requirement | Source |
|---|---|---|
| DB-01 | PostgreSQL provides persistent management of customer and reservation data. | SRS §§1.2, 2.1, 2.4, 3.3.2 |
| DB-02 | A Customers table contains, at minimum: Customer ID, Customer Name, Email Address, Phone Number, and Newsletter Signup. | SRS FR-17; Rubric p.3 |
| DB-03 | A Reservations table contains, at minimum: Reservation ID, Customer ID, Time Slot (date and time), and Table Number. | SRS FR-17; Rubric p.3 |
| DB-04 | Customer information is added to the Customers table during reservation processing. | SRS FR-18; Rubric p.3 |
| DB-05 | Newsletter signups are persisted in a backend database. | SRS FR-16; Rubric p.3 |
| DB-06 | Reservation storage and logic prevent double/over-booking and preserve data integrity. | SRS NFR-05 |
| DB-07 | The demonstration must directly show database changes caused by a reservation and a newsletter signup. | Rubric p.4 |

### 4.2 PostgreSQL decisions still required

| Decision ID | Question | Why it matters | Status |
|---|---|---|---|
| DEC-DB-01 | Are the 30 tables represented as rows in a Tables table, generated as numbers, or managed another way? | Availability, referential integrity, and random assignment | Unapproved |
| DEC-DB-02 | Where is `number_of_guests` stored? It is required on the form but omitted from the minimum Reservations schema. | Data completeness and availability logic | Unapproved; blocking |
| DEC-DB-03 | Does each restaurant table have a seating capacity, and must party size fit that capacity? | “Guests,” “all seats,” and “30 tables” can imply different capacity models. | Unapproved; blocking |
| DEC-DB-04 | What makes a reservation conflict: identical slot timestamp only, or overlapping dining intervals? | Preventing over-booking requires a precise conflict rule. | Unapproved; blocking |
| DEC-DB-05 | What slot interval and dining duration apply? | Availability and uniqueness constraints depend on these values. | Unapproved; blocking |
| DEC-DB-06 | What database constraints, transaction isolation, locking, or atomic-allocation rule prevents concurrent double booking? | NFR-05 must hold under simultaneous requests. | Unapproved; blocking before integration |
| DEC-DB-07 | How are repeat customers identified: unique normalized email, a new record per reservation, or another rule? | Duplicate customers and newsletter state | Unapproved |
| DEC-DB-08 | Is newsletter signup represented solely by `Customers.Newsletter Signup`, by a separate subscriber record, or both? | A newsletter-only visitor may not provide a customer name/phone. | Unapproved; blocking |
| DEC-DB-09 | What data types, nullability, lengths, keys, indexes, check constraints, timestamps, naming conventions, and migration strategy apply? | Reliable schema and maintainability | Unapproved |
| DEC-DB-10 | Is historical cancellation/status data needed? | No cancellation requirement exists, but schema design could otherwise assume it. | Unapproved; optional unless approved |

## 5. Flask/backend requirements

### 5.1 Explicit requirements

| ID | Requirement | Source |
|---|---|---|
| API-01 | Backend is implemented with Python Flask. | SRS §§1.2, 2.4, 3.3.2; Rubric |
| API-02 | Provide RESTful endpoints that process the reservation and newsletter forms. | SRS §§3.3.2-3.3.3 |
| API-03 | Accept reservation customer details, insert customer data, validate slot validity/availability, randomly assign an available table among 30, persist the reservation, and return success/error results. | SRS FR-06 to FR-09 and FR-18 |
| API-04 | Accept a newsletter email, validate basic email format, and persist the signup. | SRS FR-15 to FR-16; Rubric p.3 |
| API-05 | Process reservation and signup submissions within 2 seconds under the eventually approved test conditions. | SRS NFR-02 |
| API-06 | Return failures in a user-friendly manner. | SRS NFR-06 |
| API-07 | Correctly integrate with PostgreSQL and the React frontend. | SRS external interfaces; Rubric score-5 criteria |

### 5.2 Backend decisions still required

| Decision ID | Question | Status |
|---|---|---|
| DEC-API-01 | Exact endpoint paths, HTTP methods, request/response JSON schemas, status codes, and error codes | Unapproved |
| DEC-API-02 | Server-side validation rules for name, email, phone, party size, date/time, and business hours | Unapproved; blocking |
| DEC-API-03 | Reservation lead time, maximum advance window, past-time rejection, closing-time handling, and timezone | Unapproved; blocking |
| DEC-API-04 | Whether random assignment must be uniform and how it will be made testable/reproducible | Unapproved |
| DEC-API-05 | Database access layer/ORM, migrations tool, configuration mechanism, and connection management | Unapproved |
| DEC-API-06 | Cross-origin policy, secrets/config handling, logging, request limits, and production server | Unapproved |
| DEC-API-07 | Whether administration/content-management endpoints exist | Unapproved; no explicit admin feature requirement |

## 6. React/UI requirements

### 6.1 Explicit requirements

| ID | Requirement | Source |
|---|---|---|
| UI-01 | Build the frontend using React with JSX. | SRS §§1.2, 2.4, 3.3; Rubric |
| UI-02 | Provide at least five pages: Home, Menu, Reservations, About Us, and Gallery. | SRS §2.2; Rubric pp.3-4 |
| UI-03 | Implement the exact Home, Menu, About, Gallery, awards/reviews, reservation, and newsletter content/interactions specified by FR-01 through FR-15. | SRS §3.1 |
| UI-04 | Provide navigation among all five pages and verify that all links work. | SRS FR-04; Rubric pp.3-4 |
| UI-05 | Use consistent CSS with Flexbox or Grid and a responsive design. | SRS §§2.4, 3.3.1; Rubric |
| UI-06 | Achieve good appearance and excellent UI/UX for the score-5 target. | Rubric pp.6-7 |
| UI-07 | Display reservation confirmation and full-slot/error feedback. | SRS FR-09 |
| UI-08 | Work on desktop, tablet, smartphone, and the named major browsers. | SRS NFR-07, NFR-08 |

### 6.2 UI decisions still required

| Decision ID | Question | Status |
|---|---|---|
| DEC-UI-01 | Brand palette, typography, logo treatment, component styling, and exact visual direction | Unapproved |
| DEC-UI-02 | Supplied versus additional image assets, image credits/licenses, crops, alt text, and optimization | Unapproved |
| DEC-UI-03 | Navigation pattern on small screens and responsive breakpoints/viewports | Unapproved |
| DEC-UI-04 | Form controls, field limits, inline validation, disabled/loading states, and focus/error behavior | Unapproved |
| DEC-UI-05 | Where the newsletter form appears (one required page, several pages, or a shared footer) | Unapproved |
| DEC-UI-06 | Routing approach and not-found behavior | Unapproved |
| DEC-UI-07 | Accessibility target, keyboard behavior, focus management, and screen-reader acceptance criteria | Unapproved; accessibility is advisable but not explicit |
| DEC-UI-08 | Exact founder biographies beyond the SRS summary | Unapproved |

## 7. Integration requirements

### 7.1 Explicit requirements

| ID | Requirement | Source |
|---|---|---|
| INT-01 | React reservation and newsletter forms communicate with Flask via HTTP/HTTPS REST endpoints. | SRS §§3.3.2-3.3.3 |
| INT-02 | Flask persists and retrieves the required PostgreSQL data. | SRS FR-16 to FR-18 |
| INT-03 | The integrated reservation workflow checks availability, prevents double/over-booking, assigns a random available table, persists data, and returns the correct user message. | SRS FR-07 to FR-09, NFR-05; Rubric |
| INT-04 | The integrated newsletter workflow validates and persists the submitted address. | SRS FR-15 to FR-16; Rubric |
| INT-05 | The demonstration shows the frontend action and its direct effect on database state. | Rubric p.4 |

### 7.2 Approved sequencing constraints

| ID | Constraint | Source |
|---|---|---|
| ADD-01 | Implement strictly in this order: PostgreSQL -> Flask REST API -> React/JSX UI -> integration. | Approved in Prompt 0; Addendum PRA-001 |
| ADD-02 | Use a least-to-most implementation strategy. | Approved in Prompt 0; Addendum PRA-002 |
| ADD-03 | Include unit and integration testing throughout implementation. | Approved project instruction; Addendum PRA-003 |

### 7.3 Integration decisions still required

| Decision ID | Question | Status |
|---|---|---|
| DEC-INT-01 | Local ports/base URLs, environment-specific API URL, CORS policy, and development proxy | Unapproved |
| DEC-INT-02 | End-to-end test fixtures, database reset/seed approach, and isolation between test and demo data | Unapproved |
| DEC-INT-03 | How the direct database state will be shown during the recorded demo | Unapproved; rubric-critical |
| DEC-INT-04 | Definition of “sophisticated reservations logic” for score 5 | Unapproved; rubric-critical |
| DEC-INT-05 | Failure scenarios required in the demo and automated tests | Unapproved |

## 8. Deployment and documentation requirements

### 8.1 Explicit requirements

| ID | Requirement | Source |
|---|---|---|
| DEP-01 | Application must be deployable locally or on a publicly accessible/staging web server. | SRS §4; Rubric pp.3-4 |
| DEP-02 | `README.md` provides detailed environment setup, dependency installation, database configuration, solution/design description, and local run instructions. | SRS §4; Rubric p.5 |
| DEP-03 | A private GitHub repository contains all frontend and backend source code. | Rubric p.5 |
| DEP-04 | Add `quantic-grader` as a collaborator to the private repository. | Rubric p.5 |
| DEP-05 | Include `ai-tooling.md` summarizing AI tools used, how they were used, what worked well, and what did not. | Rubric pp.2, 5-9 |
| DEP-06 | Submit a PDF containing a link to the GitHub repository (or each group member's repository). | Rubric p.5 |
| DEP-07 | Submit a Google Drive link to the recorded demonstration. | Rubric p.5 |
| DEP-08 | If staging is used, an optional `staging.md` may contain the URL; otherwise it may state local-only operation. | Rubric p.5 |
| DEP-09 | Additional images must be royalty-free or AI-generated. | Rubric p.3 |
| DEP-10 | Cite referenced work appropriately and comply with the academic-integrity policy. | Rubric p.6 |

### 8.2 Deployment/documentation decisions still required

| Decision ID | Question | Status |
|---|---|---|
| DEC-DEP-01 | Local-only or staging deployment | Unapproved |
| DEC-DEP-02 | Supported operating-system setup and exact dependency/version policy | Unapproved |
| DEC-DEP-03 | Repository layout, branch workflow, and GitHub repository name | Unapproved |
| DEC-DEP-04 | Environment-variable names, secret handling, database initialization, migrations, and seed commands | Unapproved |
| DEC-DEP-05 | Image/source attribution format and location | Unapproved |
| DEC-DEP-06 | Individual versus group submission and, if a group, responsibilities and agreement | Unapproved |

## 9. Rubric and demonstration requirements

The implementation target is score 5, not merely the passing score of 2.

| ID | Requirement/evidence for the target submission | Source |
|---|---|---|
| RUB-01 | All SRS requirements are implemented. | Rubric p.6 |
| RUB-02 | All five minimum pages are built with React/JSX and demonstrated with navigation. | Rubric pp.4, 6 |
| RUB-03 | UI has good appearance and evidences excellent UI/UX. | Rubric pp.6-7 |
| RUB-04 | Flexbox or Grid is appropriately used for a high-quality UX. | Rubric p.7 |
| RUB-05 | Required forms are correctly implemented and working. | Rubric p.7 |
| RUB-06 | Flask and PostgreSQL are correctly integrated with React for reservations and newsletter signup. | Rubric p.7 |
| RUB-07 | Demo includes all required elements, direct database effects, and sophisticated reservation logic. | Rubric pp.4, 7 |
| RUB-08 | Demo lasts approximately 5-10 minutes. | Rubric p.4 |
| RUB-09 | Presenter is visible on-screen while the screen presentation is recorded. | Rubric p.4 |
| RUB-10 | Presenter shows a government-issued ID with legible name/photo and states their name. | Rubric p.5 |
| RUB-11 | Each individual submits a recording; for a group, one group presentation is submitted, all members are visible, and each speaks. | Rubric pp.4-5 |
| RUB-12 | Do not use “Invite People” to share the presentation. | Rubric p.5 |
| RUB-13 | Submit the Google Drive video link and the required PDF with repository link(s). | Rubric p.5 |
| RUB-14 | Private repository contains all source, `README.md`, and `ai-tooling.md`; `quantic-grader` is a collaborator. | Rubric p.5 |
| RUB-15 | If a group submits, only one member submits and the signed final page of the Group Project Agreement is included. | Rubric p.5 |

### Demonstration evidence checklist

1. Open Home, Menu, Reservations, About Us, and Gallery; navigate among them.
2. Show responsive behavior and the gallery lightbox.
3. Submit a valid newsletter address; show success; query PostgreSQL directly to show the saved data.
4. Submit an available reservation; show confirmation and assigned table; query PostgreSQL directly to show the customer and reservation rows.
5. Demonstrate availability/full-slot behavior and the appropriate user message.
6. Briefly explain the database, API, UI, integration, concurrency/data-integrity approach, and major approved decisions.
7. Briefly disclose AI tooling and its effective/ineffective uses.
8. Complete identity and recording obligations without exposing unnecessary personal details in the shared application or repository.

Items 5 and 6 depend on approved definitions of capacity and “sophisticated reservations logic.”

## 10. Requirements requiring further operational definition

### 10.1 Blocking before PostgreSQL implementation

| Priority | Decision | Related requirements |
|---|---|---|
| 1 | Define whether capacity is 30 simultaneously occupied tables or a seat-based system, and whether tables have seating capacities. | FR-06 to FR-09, FR-18, NFR-05 |
| 2 | Define time-slot increments, dining duration, and overlap rules. | FR-07 to FR-09, NFR-05 |
| 3 | Approve storage of required `number_of_guests`, which is absent from the minimum Reservations field list. | FR-06, FR-17 |
| 4 | Define table representation and the atomic database rule preventing concurrent double assignment. | FR-08, FR-18, NFR-05 |
| 5 | Define customer identity/deduplication and how newsletter-only signups map to the required Customers fields. | FR-15 to FR-18 |
| 6 | Define schema conventions: types, nullability, keys, constraints, timestamps, indexes, and migrations. | FR-17, NFR-05, NFR-09 |

### 10.2 Needed before Flask implementation

- Reservation validity rules: timezone, opening hours, past dates, lead time, maximum advance booking, party-size range, and closing-time handling.
- API contract: endpoints, HTTP methods, payloads, responses, status codes, validation/error shape, and idempotency/retry behavior.
- Random-table semantics and testability.
- Database access/configuration, CORS, logging, error handling, and secret management.
- Quantifiable test conditions for NFR-02.

### 10.3 Needed before React implementation

- Brand/design direction, page compositions, component states, and supplied image inventory.
- Exact founder biography copy beyond the SRS summary.
- Responsive breakpoints, target device widths, and browser/version test matrix.
- Form field constraints, validation wording, success/error presentation, and accessibility target.
- Newsletter form placement.
- Quantifiable test conditions for NFR-01 and acceptance criteria for NFR-03/NFR-04.

### 10.4 Needed before integration, deployment, and demonstration

- Definition of “sophisticated reservations logic.”
- Test/demo database seed and reset strategy.
- Direct database inspection method for the recording.
- Local-only versus staging deployment.
- Individual/group status, repository identity, and presentation plan.
- Recording method, Google Drive sharing settings, and final submission-PDF format.

## 11. Optional enhancements (not approved and not in scope)

| ID | Enhancement | Reason it is optional |
|---|---|---|
| OPT-01 | Customer accounts/authentication | Not required by SRS or rubric |
| OPT-02 | Admin dashboard or content-management UI | Managers are described, but no admin functions are specified; database effects must be shown directly in the demo |
| OPT-03 | Reservation cancellation/modification | Not required |
| OPT-04 | Waitlist, reminder email/SMS, or confirmation email | Not required |
| OPT-05 | Online ordering, payment, delivery, or loyalty program | Not required |
| OPT-06 | Dynamic menu/content management in PostgreSQL | Menu display is required; persistence/editing is not |
| OPT-07 | Analytics, cookie consent tooling, or marketing automation | Not required |
| OPT-08 | Localization/multiple languages | Not required |
| OPT-09 | Advanced image carousel, video, social feed, or map integration | Not required |
| OPT-10 | Public cloud deployment/CI-CD | Staging is optional and local deployment is allowed |

Security, accessibility, privacy, and data-protection practices should not be mistaken for product enhancements; however, the sources do not supply concrete acceptance criteria for them. Any behavior or scope beyond standard safe implementation must be approved through the addendum.

## 12. Initial traceability structure

### 12.1 Traceability record format

Each requirement will be tracked using:

| Field | Purpose |
|---|---|
| Requirement ID | Stable identifier (`FR`, `NFR`, `DB`, `API`, `UI`, `INT`, `DEP`, `RUB`, or `PRA`) |
| Source and locator | Document, section/page, or approved addendum record |
| Requirement statement | Testable requirement text |
| Classification | SRS, RUB, ADD, DEC, or OPT |
| Components | Database objects, API handlers/services, React pages/components, configuration, or documentation |
| Verification | Schema inspection, unit test, integration test, UI test, performance test, manual review, or demo evidence |
| Status | Not started, in progress, implemented, verified, deferred, or not applicable |
| Evidence | Test ID/result, screenshot, query, demo timestamp, or document/repository path |

### 12.2 Initial end-to-end traceability matrix

| Requirement group | PostgreSQL | Flask | React/JSX | Integration/tests | Demo/submission |
|---|---|---|---|---|---|
| FR-01 to FR-05 | None required | None required | Home/Menu content and navigation | UI/content/link tests | Show Home/Menu |
| FR-06 | Reservation storage must retain required data after DEC-DB-02 | Validate/accept form data | Reservation form | API contract and end-to-end form test | Show completed form |
| FR-07 | Availability constraints/query support | Validity and availability service | Prevent/communicate invalid input | Availability and boundary tests | Show valid and unavailable paths |
| FR-08 | 30-table model; atomic allocation | Random available-table assignment | Submit and show result | Concurrency/integration tests | Show assigned table and DB row |
| FR-09 | Persist only successful booking | Success/full/error response | User feedback | Success/full/failure tests | Show both required outcomes |
| FR-10 to FR-14 | None required | None required | About/Gallery, lightbox, awards/reviews | Content and interaction tests | Show About/Gallery/lightbox |
| FR-15 to FR-16 | Persist newsletter state/address | Validate and save | Signup form/feedback | Validation and persistence tests | Submit and show DB effect |
| FR-17 | Customers and Reservations schema | Data access | None directly | Schema/migration/integration tests | Query required columns/rows |
| FR-18 | Transactional persistence/availability | Full reservation workflow | Consume API result | Unit, concurrency, and end-to-end tests | Explain and demonstrate logic |
| NFR-01 to NFR-02 | Query/index contribution | API timing | Load/render timing | Approved performance tests | Report results if useful |
| NFR-03 to NFR-04 | None directly | Clear error content | UX and brand consistency | Heuristic/manual review | Visible throughout demo |
| NFR-05 to NFR-06 | Constraints/transactions | Failure handling | Friendly messages | Conflict/concurrency/failure tests | Show relevant failure path |
| NFR-07 to NFR-08 | None directly | Browser-independent API | Responsive/cross-browser UI | Browser/device matrix | Show representative responsive view |
| NFR-09 | Migrations/schema docs | Modular documented backend | Modular documented UI | Test/documentation review | Repository evidence |
| DEP-01 to DEP-10 | Setup/migration/seed docs | Setup/run docs | Build/run docs | Environment verification | README, repository, AI-tooling, video, PDF |
| RUB-01 to RUB-15 | Direct DB evidence | Integrated behavior | Five pages/forms/UX | Complete verification set | Recorded demo and submission package |

### 12.3 Planned verification ID convention

- `UT-DB-*`: database function/constraint tests
- `UT-API-*`: Flask unit tests
- `UT-UI-*`: React component tests
- `IT-DBAPI-*`: PostgreSQL-Flask integration tests
- `IT-APIUI-*`: Flask-React contract/integration tests
- `E2E-*`: complete browser-to-database workflows
- `PERF-*`: load and submission performance checks
- `COMPAT-*`: browser/device compatibility checks
- `DEMO-*`: recorded demonstration evidence
- `DOC-*`: README, AI-tooling, repository, and submission checks

## 13. Least-to-most delivery gates

No gate authorizes unresolved design decisions; relevant addendum approvals must exist first.

1. **Gate 1 - PostgreSQL:** approve blocking business rules; create and verify the minimum schema; then add constraints, availability support, concurrency protection, migrations, and demo seed/reset support.
2. **Gate 2 - Flask API:** begin with database connectivity/health; add newsletter persistence; add the simplest valid reservation path; then availability, random assignment, full-slot handling, validation, failure handling, and backend tests.
3. **Gate 3 - React/JSX:** begin with application shell/routing; add static required pages/content; add newsletter form; add reservation form; add gallery lightbox; then responsive, validation, loading/error, and UI/UX refinements with tests.
4. **Gate 4 - Integration:** connect one workflow at a time; verify newsletter end-to-end; verify successful reservation; verify unavailable/full slot; verify concurrency/data integrity; verify performance, compatibility, deployment, documentation, and demo evidence.

Progression to a later technology layer occurs only after the preceding layer's applicable requirements and tests meet the agreed gate.

## 14. Baseline conclusion

The project is feasible with the required stack and order. The documents define the visible site, minimum database entities, primary reservation/newsletter workflows, quality expectations, deployment documentation, and submission/demo obligations. They do not fully define the reservation domain model or several testable operational limits. Those gaps must be resolved through explicit approvals in the Project Requirements Addendum, beginning with the six PostgreSQL-blocking decisions in §10.1.

