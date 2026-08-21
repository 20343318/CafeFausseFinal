# Prompt 10 - Define the Flask backend operation inventory

Begin only **API-01 - Backend Operation Inventory** of the approved least-to-most implementation roadmap.

Work in the repository-connected Codex environment with the Cafe Fausse repository root open. Derive the smallest complete set of Flask-facing backend operations needed to support the approved Version 1 workflows. Base every operation on the approved requirements, completed PostgreSQL implementation, DB-07 Hard Gate 1 evidence, and frozen PostgreSQL Contract for Flask.

This is a design and phase-gate increment. Do not implement Flask, define a REST contract, or change PostgreSQL.

Do not begin API-02 or any later increment.

## Authoritative sources

Use the following as authoritative, in this order:

1. `docs/SRS(1).pdf`;
2. `docs/Rubric(1).pdf`;
3. the approved Project Requirements Addendum version 2.2.1, including PRA-001 through PRA-029;
4. the approved DB-01 Persistent-Data Requirements Analysis version 1.2.1;
5. the approved DB-02 Conceptual Data Model version 1.2;
6. the approved DB-03 Logical PostgreSQL Schema and Integrity Design version 1.1;
7. the approved DB-04 Reservation Transaction and Concurrency Design version 1.1;
8. the approved DB-05 database-foundation implementation and completion evidence in the repository;
9. the approved DB-06 reservation-persistence, allocation, and concurrency implementation and completion evidence in the repository;
10. the approved DB-07 verification report, manual-demonstration guide, database README, and other Hard Gate 1 evidence in the repository;
11. the approved and frozen **PostgreSQL Contract for Flask version 1.0**;
12. the approved least-to-most implementation roadmap version 1.1.1;
13. the repository-root `AGENTS.md` and any more-specific applicable repository instructions.

DB-01 through DB-07 are approved. Hard Gate 1 and its PostgreSQL Contract for Flask version 1.0 were explicitly approved by Abdul on 2026-08-20. Do not reopen, silently reinterpret, or replace their requirements, schema, transaction behavior, concurrency strategy, privileges, routines, or verification conclusions unless a genuine contradiction prevents API-01 from being completed.

The current repository is authoritative for exact approved artifact filenames, database object names, operation signatures, outcome names, role permissions, migration state, and DB-07 evidence. Before writing API-01, locate and read the actual files rather than relying on names or signatures copied into this prompt.

## Accepted DB-07 baseline

Treat the following as approved baseline facts, not API-01 defects or reasons to repeat DB-07:

- PostgreSQL 18.3 is the sole required and verified Version 1 PostgreSQL target. Do not require verification against another PostgreSQL version.
- `pgcrypto` is an approved required extension.
- The PostgreSQL schema, roles, privileges, migrations, initialization/reset path, constraints, indexes, routines, concurrency behavior, and repeatable verification passed Hard Gate 1.
- The PostgreSQL Contract for Flask version 1.0 is frozen for API work unless a genuine blocking contradiction is formally escalated.
- The accepted database performance envelope includes a general exact-allocation p95 of approximately 1.14-1.27 seconds in the recorded DB-07 environment.
- The approved restaurant-wide coordination lock favors correctness and explainability. Under contention, five or eight simultaneous booking requests may exceed two seconds.
- That contention limitation is documented and accepted for Version 1. Full validation of the SRS two-second form-submission expectation remains deferred to later Flask and full-stack performance gates.
- API-01 must not claim a stronger performance guarantee, redesign the database allocator, or reopen the approved coarse-lock decision.

## API-01 objective

Produce an approved, implementation-neutral operation inventory that answers:

- Which backend operations must Flask eventually provide?
- Which approved user or technical workflow requires each operation?
- What conceptual business input does each operation need?
- Which normalization and validation responsibilities belong to Flask?
- Which frozen PostgreSQL facts or controlled operations does each operation use?
- What conceptual result and outcome categories must later API design support?
- What retry, idempotency, privacy, and failure behavior applies?
- Which unit and PostgreSQL-integration cases must later implementation prove?
- Which tempting operations are explicitly excluded from Version 1?

The result must be sufficiently complete for API-02 to define the REST contract without inventing a new workflow, business rule, database access path, or source of truth.

## Hard scope boundary

API-01 may create or update only the API-01 design artifact and narrowly necessary documentation references. It must not change `database/`, `backend/`, or `frontend/` implementation files.

Do not generate or select:

- Flask or Python code;
- SQL, migrations, functions, procedures, views, grants, or database fixes;
- package manifests or dependencies;
- application architecture, module layout, class design, repository pattern, or ORM choice;
- REST endpoint paths;
- HTTP methods;
- URL parameters or query-string syntax;
- JSON property names or payload schemas;
- HTTP status codes;
- public error-code strings or a final error envelope;
- authentication, authorization middleware, sessions, tokens, or user accounts;
- React, JSX, components, hooks, forms, state management, or browser behavior;
- executable unit, integration, concurrency, or end-to-end tests;
- deployment, hosting, CI/CD, containers, or production observability;
- API-02, API-03, API-04, or later roadmap work.

Conceptual inputs and outputs are required, but they must be described as business facts rather than serialized request or response fields. Operation-level outcome categories are required, but their eventual HTTP representation belongs to API-02.

If a useful-looking decision would determine endpoint syntax, wire format, HTTP semantics, Flask architecture, or implementation technology, defer it explicitly to the appropriate later increment.

## Required initial read-only repository verification

Before creating or modifying the API-01 artifact:

1. Read the applicable `AGENTS.md` instructions.
2. Inspect Git status and preserve every unrelated user change.
3. Locate and read all authoritative sources listed above.
4. Confirm the exact approved filenames and versions present in the repository.
5. Confirm that DB-07 approval and the Hard Gate 1 conclusion are recorded.
6. Locate the frozen PostgreSQL Contract for Flask version 1.0 and verify that its documented signatures and outcomes match the implemented database artifacts.
7. Inventory the PostgreSQL read privileges and controlled operation paths available to the Flask application role.
8. Inspect the current `backend/` directory only to establish whether unapproved Flask implementation already exists. Do not edit it.
9. Inspect the roadmap definition of API-01 and its boundary with API-02.
10. Record the initial working-tree state and the repository paths used as evidence.

If DB-07 is not clearly approved, the frozen PostgreSQL contract is missing, the repository contract materially differs from the approved database implementation, required authoritative sources are absent, or API-01 would require a database change, stop and report the exact blocker. Do not invent a replacement contract or silently repair PostgreSQL.

Warnings or historical naming differences that have already been resolved and accepted must not be reopened without new evidence of a material contradiction.

## Minimum Version 1 operation set

Evaluate and define the minimum operation set needed to cover the approved workflows. The final catalogue must contain recognizable coverage for all of the following concerns, whether a concern is best represented by one operation or a rigorously justified minimal grouping:

1. **Current recurring restaurant hours**
   - Retrieve the authoritative seven-day recurring schedule from PostgreSQL.
   - Support the normal Monday-Saturday and Sunday hours and controlled alternate test schedules without Flask constants.
   - Preserve recurring restaurant-local-time semantics.

2. **Current reservation configuration and derived limits**
   - Obtain the authoritative start interval, duration, advance window, same-day lead time, and restaurant timezone.
   - Derive, where required, the current reservation-local date range, total restaurant capacity, and maximum permitted party size from authoritative PostgreSQL data.
   - Do not store or hardcode derived limits in Flask or React.

3. **Daily provisional availability**
   - Accept a requested restaurant-local date and party size as conceptual input.
   - Use the approved PostgreSQL provisional-availability operation.
   - Return all legitimate aligned starts for the date with provisional available or unavailable state.
   - Make clear that availability is a snapshot and booking-time revalidation remains authoritative.

4. **Customer newsletter-status lookup**
   - Support the approved debounced pre-submission status check using canonical email and normalized customer identity facts.
   - Distinguish a matching existing customer, no existing customer, a generic identity mismatch, and an indeterminate technical lookup failure.
   - Return only the current newsletter state needed by the workflow; do not create a profile or expose unrelated customer data.
   - Perform no customer creation, contact population, or preference mutation.

5. **Newsletter preference setting**
   - Support the independent newsletter-preferences workflow for subscribe and unsubscribe intent.
   - Use the approved controlled PostgreSQL operation and its new-customer, existing-customer, identity-mismatch, middle-initial-conflict, idempotency, and concurrency semantics.
   - Preserve the rule that an unselected preference for a nonexistent customer creates no customer.

6. **Reservation creation and exact retry**
   - Support authoritative reservation creation, allocation, booking-linked newsletter action, exact retry, customer reuse or creation, overlap rejection, and unavailable outcomes through the approved PostgreSQL booking operation.
   - Treat exact retry as a successful reconstruction of the existing reservation rather than a second booking.
   - Obtain all confirmation facts required by the approved requirements without adding delivery behavior.

7. **Health and readiness**
   - Identify the minimum technical operation or operations needed to distinguish process liveness from readiness to serve database-backed workflows.
   - Readiness must be grounded in the approved PostgreSQL deployment and contract, while exposing no secrets, diagnostic internals, customer data, or destructive capability.
   - Decide whether liveness and readiness should remain two conceptual operations or a justified minimal grouping. Do not define endpoint paths or HTTP behavior.

The inventory may split or combine read-only configuration concerns only when the choice reduces complexity without hiding materially different failure, caching, authorization, or freshness behavior. Explain the decision and prove that all roadmap-listed concerns remain covered.

Do not add an operation merely because it is common in other applications. Every operation must trace to an approved Cafe Fausse requirement, a required technical gate, or a necessary composition of the frozen PostgreSQL contract.

## Frozen PostgreSQL interaction boundary

Map each API-01 operation to the exact read path or controlled PostgreSQL operation authorized by the frozen contract.

At minimum, inspect and account for the contract's approved production operations for:

- provisional availability;
- setting newsletter preference;
- booking or reconstructing a reservation.

Use the exact repository signatures and documented PostgreSQL outcome names in the API-01 evidence. Do not rely only on the abbreviated descriptions in this prompt.

Also inspect the application role's approved read permissions for current customers, reservation configuration, restaurant operating hours, and restaurant tables. Reconcile those read grants with the contract's statement about controlled production operations. The API-01 artifact must state precisely which read-only data access is permitted for hours, configuration/limits, newsletter-status lookup, and readiness, and which data must be accessed only through controlled database routines.

Preserve these boundaries:

- Flask must not perform direct reservation or assignment data access when the application role is denied that access.
- Flask must not perform direct business-table writes.
- Flask must not reproduce PostgreSQL booking, allocation, locking, exact-retry, overlap, or newsletter-mutation logic.
- PostgreSQL remains authoritative for persisted uniqueness, current database configuration and hours, table inventory and capacity, final availability revalidation, customer concurrency, fingerprinting, retry identity, table allocation, exclusivity, and atomic commit or rollback.
- The API-01 design must not add a fourth database write path, an alternate booking query, or a bypass around the frozen routines.

If the approved privileges and written contract cannot support one of the mandatory operations, identify the exact contradiction and stop for approval. Do not silently broaden grants, add a database object, or make Flask authoritative.

## Required per-operation specification

For every operation in the final inventory, provide a non-executable specification containing all of the following:

1. **Operation name and purpose** - a stable conceptual name and the approved workflow it serves.
2. **Requirement traceability** - exact SRS, rubric, PRA, roadmap, DB design, and PostgreSQL-contract references.
3. **Initiator and consumer** - the future caller and the workflow that consumes the result, without defining a route.
4. **Conceptual inputs** - business facts required from the caller, explicitly excluding server-derived facts.
5. **Input provenance** - client-supplied, Flask-normalized, server-current, or PostgreSQL-derived.
6. **Flask normalization** - trimming, whitespace normalization, case handling, Unicode-aware validation, canonicalization, date/time interpretation, and confirmation-field handling as applicable.
7. **Flask validation** - request-shape and format rules that must be satisfied before database interaction.
8. **PostgreSQL interaction** - exact approved read source or controlled operation and the authority retained by PostgreSQL.
9. **Transaction character** - read-only snapshot, single controlled transaction, or technical readiness check, based on the frozen contract.
10. **Conceptual successful result** - business facts the later API contract must be able to represent, without choosing JSON names.
11. **Outcome categories** - success, not found or not applicable, validation failure, identity conflict, business conflict, unavailable, exact retry, transient technical conflict, timeout, indeterminate result, and unexpected failure as applicable.
12. **Retry and idempotency behavior** - whether an automatic retry or caller resubmission is safe and what authoritative result must be re-read.
13. **Privacy and minimization** - permitted returned facts, prohibited fields, confirmation-only transient data, and safe logging considerations.
14. **Freshness and caching constraints** - whether current configuration, hours, capacity, or newsletter state may become stale and why booking must still revalidate.
15. **Unit-test cases** - non-executable success, validation, edge, and failure scenarios.
16. **PostgreSQL-integration cases** - fixture state, database behavior used, and expected conceptual result.
17. **Explicit exclusions** - adjacent behavior that this operation must not acquire.

Do not turn this catalogue into an API schema. Names used inside the PostgreSQL contract may be quoted for traceability; they must not be adopted automatically as future public JSON fields or public API error codes.

## Workflow-to-operation coverage

Demonstrate how the operation inventory covers the complete Version 1 flows.

### Reservation discovery and booking flow

Cover this sequence conceptually:

1. Obtain current hours, configuration, and derived input limits needed to present valid choices.
2. Accept a party size and restaurant-local date.
3. Retrieve all legitimate starts and their provisional availability.
4. Accept selection of one available displayed start.
5. Collect and normalize customer and optional contact data.
6. Check current newsletter state when valid identity data is available.
7. Permit booking to continue with no preference change if that lookup is technically indeterminate.
8. Submit the authoritative booking request without trusting provisional availability.
9. Reconstruct a prior committed reservation on exact retry.
10. Return the approved confirmation facts or a safe conceptual failure outcome.
11. Refresh availability after a stale/full outcome in later orchestration without persisting availability.

Show which operation owns each step and which steps are future Flask or React orchestration rather than distinct business operations.

### Independent newsletter-preferences flow

Cover:

1. normalize first name, optional middle initial, last name, email, email confirmation, and Boolean preference;
2. inspect current status when appropriate;
3. submit an affirmative subscribe or unsubscribe setting through the controlled PostgreSQL operation;
4. preserve the no-customer/no-change behavior for a nonexistent unselected customer;
5. handle matching, generic mismatch, middle-initial conflict, idempotent repetition, transient conflict, and technical failure;
6. return only the current authoritative preference state and safe outcome needed by later API design.

### Service health/readiness flow

Cover:

- process liveness independent of business data where appropriate;
- database connectivity and the approved PostgreSQL 18.3 deployment expectation;
- required extension/schema/routine accessibility and usable foundation population only to the degree justified by the frozen contract and DB-07 evidence;
- safe failure without leaking connection strings, role names where unnecessary, SQL text, stack traces, or business data.

Do not turn readiness into a database mutation, reset, performance test, or substitute for DB-07.

## Flask normalization and validation catalogue

Provide one consolidated catalogue and map every rule to the operations that use it.

At minimum, address:

- required first and last names;
- approved trimming and internal-whitespace normalization;
- 1-100-character first- and last-name limits;
- at least one Unicode letter in each required name;
- preservation of approved display spelling, punctuation, and accents;
- case-insensitive normalized customer-name matching delegated according to the frozen database behavior;
- optional middle initial, optional period handling, one alphabetic character, and uppercase normalized form;
- required email and confirmation email in relevant user-facing forms;
- trimming, syntax validation, 254-character limit, lowercase canonical email, and equality of email with confirmation;
- confirmation email remaining transient and never entering persistent customer data;
- optional reservation phone, approved characters, and 7-15-digit requirement;
- party size as an integer within the current derived capacity maximum;
- restaurant-local date validity;
- an unambiguous selected restaurant-local start and explicit offset handling required by the approved database contract;
- current timezone and daylight-saving ambiguity or nonexistence handling;
- current advance window, same-day lead, interval alignment, opening boundary, and complete occupancy through closing;
- newsletter action semantics: subscribe, unsubscribe, or no change for booking, and explicit Boolean state for the independent preference workflow;
- rejection of client-supplied customer IDs, reservation IDs, fingerprints, assigned tables, calculated end times, duration, configuration values, availability assertions, or capacity values.

Separate:

- syntax and Unicode-aware normalization performed by Flask;
- current business validation obtained from PostgreSQL;
- transaction-dependent validation performed authoritatively by the booking routine;
- presentation assistance that may later occur in React but is never authoritative.

Do not define a validation-library dependency or Python implementation.

## Operation-specific requirements

### Current hours

The operation must:

- read the seven authoritative weekday rows from PostgreSQL;
- preserve ISO weekday identity and local opening/closing meaning;
- support controlled alternate recurring schedules without Flask changes;
- detect an unusable or incomplete schedule as a readiness/configuration failure rather than fabricate missing days;
- avoid holiday, date-specific, closed-day, overnight, or multiple-period behavior;
- avoid hardcoded SRS hours as an independent application source of truth.

### Current configuration and limits

The operation must:

- use the one current configuration set;
- make the current interval, duration, advance window, lead time, and timezone available to later orchestration as justified;
- derive total capacity and maximum party size from current restaurant-table capacities;
- identify unusable singleton, timezone, or 30-table-inventory state safely;
- avoid exposing table-level inventory when the user workflow needs only a derived party limit;
- avoid caching assumptions that could make final booking authoritative on stale values.

Explain whether current hours and configuration/limits are separate operations or one combined bootstrap/context operation. Compare only the reasonable choices and select the smallest design that preserves independent failure and freshness semantics.

### Daily provisional availability

The operation must:

- use the frozen PostgreSQL provisional-availability routine;
- perform Flask request-format checks before calling PostgreSQL;
- let PostgreSQL read current configuration, hours, reservations, assignments, and table capacities;
- represent every legitimate aligned start, including unavailable starts;
- include the corresponding immutable proposed interval facts supplied by PostgreSQL where required by later presentation;
- avoid exposing free tables, candidate combinations, allocation ranks, random outcomes, customer data, reservation data, or unnecessary capacity internals;
- state that a provisional available result is not a hold or guarantee;
- persist nothing;
- require booking-time revalidation.

### Customer newsletter-status lookup

The operation must:

- use canonical email and normalized first, optional middle, and last name for approved identity matching;
- never accept a client-supplied customer identifier;
- distinguish matching customer, nonexistent customer, generic mismatch, and technical indeterminacy;
- preserve the approved optional-middle-initial behavior;
- return only the current Boolean preference and minimal workflow state;
- avoid automatic form prefilling, contact disclosure, ownership verification, authentication, or customer mutation;
- permit a later booking to proceed with newsletter action set to no change when lookup is indeterminate;
- identify the exact permitted PostgreSQL read path and app-role privilege that supports it.

If the frozen contract does not unambiguously authorize this lookup, stop and report the contradiction rather than creating a new database routine or broadening privileges.

### Newsletter preference setting

The operation must:

- use the frozen controlled newsletter-preference routine;
- preserve customer creation only for an affirmative subscription when no customer exists;
- preserve no-customer/no-change for a nonexistent unselected request;
- preserve existing-customer subscribe and unsubscribe updates;
- preserve case-insensitive name matching and approved middle-initial behavior;
- preserve unique-email concurrency, customer-row serialization, last-committed-write-wins, and all-or-none database behavior;
- treat repetition of the current state as idempotent;
- return a safe conceptual result without revealing whether a generic identity mismatch was caused by a particular stored field;
- add no subscription history, audit event, verification, messaging, or profile workflow.

### Reservation creation and exact retry

The operation must:

- use the frozen controlled booking routine as the sole authoritative write path;
- pass only approved Flask-normalized input facts;
- let PostgreSQL resolve or create the customer, derive the end time and fingerprint, revalidate current rules, check exact retry and overlap, allocate tables, update a booking-linked preference when applicable, and commit atomically;
- preserve the frozen bounded retry rule for approved transient PostgreSQL outcomes: no more than three full attempts within one overall operation deadline, with bounded backoff and jitter;
- restart the complete database transaction and re-read authoritative facts on an eligible transient retry;
- distinguish automatic transient retry from an ordinary resubmission after an ambiguous commit;
- use exact-retry behavior after a lost or uncertain response so a committed booking is reconstructed without replaying newsletter mutation;
- preserve exact retry as success and return the current authoritative newsletter state;
- preserve safe outcomes for identity mismatch, middle-initial conflict, same-customer overlap, unavailable capacity, invalid configuration/request, exhausted transient conflict, timeout, and unexpected database failure;
- surface the approved differing-phone notice without overwriting the stored phone;
- provide the confirmation reference, customer display name, local start and end, party size, all assigned table numbers, final newsletter state, and restaurant contact facts required by later confirmation presentation;
- avoid claiming email or SMS confirmation delivery;
- avoid exposing the fingerprint as a client responsibility or requiring clients to generate it;
- avoid direct reservation or assignment queries by Flask.

Determine which database result facts are operationally required by Flask and which are internal evidence only. Final public response fields belong to API-02.

### Health and readiness

The design must distinguish:

- a lightweight process-liveness concern; and
- readiness to execute the frozen PostgreSQL contract safely.

Readiness design should account for the approved database version target, connectivity, schema/routine access, and critical usable-state checks only as justified by the contract. It must not use destructive reset, create test bookings, run full verification, expose secrets, or grant application access to administrative functions.

State which checks are performed per request, at startup, or by deployment tooling only at a conceptual level. Do not choose a Flask framework package, monitoring system, endpoint, or status code.

## Outcome and failure taxonomy

Build one conceptual taxonomy that later API-02 can map to wire-level contracts. Include, where applicable:

- successful read;
- successful new reservation;
- successful exact retry;
- successful preference change or idempotent current-state result;
- no existing customer/not applicable;
- generic customer-identity mismatch;
- middle-initial conflict;
- differing-phone notice with successful booking;
- validation failure before database interaction;
- invalid or unusable database configuration;
- same-customer overlap;
- stale provisional availability or no capacity-sufficient combination;
- transient PostgreSQL conflict eligible for bounded retry;
- bounded retry exhaustion;
- operation timeout;
- database unavailability;
- ambiguous commit result followed by safe caller resubmission;
- unexpected internal failure;
- service not ready.

For each category, state:

- which operations may produce it;
- whether it is success, validation, not applicable, business conflict, unavailable, transient technical, indeterminate, or unexpected;
- whether automatic internal retry is safe;
- whether caller resubmission is safe;
- whether any persistent state may have committed;
- what conceptual facts later API design must preserve;
- what technical details must not be disclosed.

Do not assign HTTP statuses, public error identifiers, or final user-facing wording.

## Retry, timeout, and ambiguity boundary

Preserve the frozen database retry and ambiguity behavior without expanding API-01 into execution code.

Define conceptually:

- which PostgreSQL outcomes are eligible for automatic bounded full-operation retry;
- the maximum of three total attempts within one overall deadline;
- bounded backoff and jitter between attempts;
- authoritative re-read on every full retry;
- no unbounded loops;
- no replay of a newsletter action after an exact retry has established that the reservation already committed;
- safe ordinary resubmission after a connection loss or client timeout with unknown commit outcome;
- exact-retry reconstruction for React, mobile, or third-party clients submitting the same ordinary booking facts;
- nonretryable validation, mismatch, overlap, and unavailable outcomes;
- safe technical failure when the retry budget or overall deadline is exhausted.

Do not finalize the numeric application timeout, HTTP timeout behavior, or public retry headers. Identify the later increment responsible for those decisions.

## Data minimization, privacy, and logging boundary

For each operation, identify the minimum data it may accept, read, return, and later log.

Preserve these rules:

- confirmation email is transient validation input and is never persisted;
- no raw and canonical email duplication is introduced;
- customer-status lookup does not become profile retrieval;
- availability exposes no customer, reservation, table-assignment, candidate, or unnecessary capacity data;
- health/readiness exposes no credentials, connection strings, SQL, stack traces, database internals, or customer facts;
- identity mismatch remains generic;
- fingerprints remain server/database-managed and are not a client identity mechanism;
- logs later produced by Flask must be useful for technical diagnosis while redacting or minimizing personally identifiable information;
- no password, authentication token, verification state, newsletter history, or customer activity history exists in Version 1.

Do not define a logging library, telemetry vendor, retention policy, or implementation format.

## Authorization and exposure statement

Provide an explicit Version 1 authorization statement.

The public Cafe Fausse reservation and newsletter workflows do not include customer authentication or verified account ownership. API-01 must therefore identify which operations are intentionally available to an unauthenticated public client through future Flask validation and which technical readiness operation is intended for infrastructure use.

The statement must also explain that the absence of authentication does not authorize:

- direct database access;
- client-supplied customer or reservation identifiers;
- arbitrary customer-profile lookup;
- customer-contact disclosure;
- reservation administration;
- cancellation, modification, or rescheduling;
- table selection or assignment control;
- destructive database operations;
- internal diagnostic disclosure.

Do not invent API keys, administrator accounts, roles, sessions, ownership verification, rate limiting, CAPTCHA, or other security features during API-01. If one is genuinely required by an authoritative source, identify the conflict and request approval.

## PostgreSQL, Flask, React, and later-increment responsibility matrix

Provide a clear matrix assigning every approved behavior to one authoritative layer.

### PostgreSQL remains authoritative for

- persisted data, constraints, and uniqueness;
- current stored configuration, recurring hours, and table capacities;
- provisional availability derivation from current database facts;
- final booking-time validation;
- customer creation/reuse concurrency;
- newsletter mutation concurrency;
- fingerprint generation and exact-retry identity;
- same-customer overlap prevention;
- exclusive exact table allocation;
- transaction isolation, advisory locks, retryable database outcomes, and atomic commit/rollback;
- stable reservation identity and assigned-table facts.

### Flask will be responsible for in later increments

- request-shape validation;
- Unicode-aware normalization and syntax checks;
- confirmation-email equality checks;
- invoking only approved read paths and controlled database operations;
- bounded retry orchestration if placed in Flask by the frozen contract;
- mapping database results to the future API contract;
- operation-level time budgeting;
- safe technical logging and error containment;
- composing approved restaurant contact facts where their authoritative source is documented;
- returning nontechnical outcomes.

### React will remain non-authoritative

- it may collect input and present current server-provided hours, limits, availability, status, and outcomes;
- it must not own authoritative schedule, configuration, availability, allocation, validation, retry identity, or database integrity;
- disabling a button or holding client state is not concurrency protection.

### Later increments will decide

- REST paths, methods, payloads, status codes, and error envelopes;
- Flask architecture and implementation;
- React interaction and presentation;
- cross-layer integration and end-to-end performance validation.

## Non-executable unit-test inventory

For every operation, define unit-level design cases without writing tests. Include at least:

### Current hours and configuration/limits

- normal seven-day schedule;
- exact Monday-Saturday and Sunday closing rules;
- controlled alternate recurring schedule;
- incomplete or duplicate/unusable schedule state;
- normal five-setting configuration;
- invalid or missing singleton configuration;
- valid and invalid timezone state;
- 30 capacity-four tables and derived maximum party size 120;
- unexpected inventory count or invalid capacity state;
- prospective changes appearing in later reads without altering prior reservations.

### Daily provisional availability

- valid future date and party size;
- all legitimate aligned starts returned;
- unavailable starts retained and marked provisionally unavailable;
- weekday and Sunday latest-start boundaries;
- alternate hours and configuration;
- same-day lead-time boundary;
- advance-window boundaries;
- invalid party size, date, or local start context;
- no available combination;
- stale result explicitly treated as provisional;
- no persistent availability or candidate state.

### Newsletter-status lookup

- matching existing customer subscribed;
- matching existing customer unsubscribed;
- nonexistent customer;
- case-insensitive normalized name match;
- generic first- or last-name mismatch;
- omitted middle initial with stored value;
- blank stored middle initial and supplied value without mutation;
- conflicting populated middle initial;
- malformed or noncanonical input rejected before lookup;
- technical database failure producing indeterminate status;
- no contact/profile data returned and no mutation performed.

### Newsletter preference setting

- new matching identity with selected preference creates a subscribed customer;
- new identity with unselected preference creates no customer;
- existing matching customer subscribes;
- existing matching customer unsubscribes;
- repeated current-state request is idempotent;
- generic name mismatch;
- middle-initial conflict;
- unique-email race represented through the controlled operation;
- transient conflict retry eligibility;
- unexpected failure leaves no partial customer/preference state.

### Reservation creation and exact retry

- successful single-table booking;
- successful multi-table booking;
- differing existing phone produces success with notice and no overwrite;
- exact retry reconstructs the original confirmation;
- exact retry returns current newsletter state and makes no newsletter mutation;
- same customer overlapping request rejected;
- different customers may hold overlapping reservations when capacity permits;
- back-to-back reservations allowed;
- stale provisional availability followed by authoritative unavailable;
- party size above current derived maximum;
- invalid local time, UTC offset, date window, lead time, alignment, opening, or closing boundary;
- identity mismatch and middle-initial conflict;
- booking-linked subscribe, unsubscribe, and no-change;
- transient database conflict with bounded retry;
- retry exhaustion;
- timeout or connection loss before known commit;
- connection loss after commit followed by safe resubmission;
- unexpected failure returns no partial state;
- confirmation includes every approved business fact but no delivery claim.

### Health and readiness

- live process with ready database;
- live process with unavailable database;
- wrong or unsupported database target state relative to PostgreSQL 18.3;
- inaccessible approved schema or routines;
- unusable foundation population;
- readiness failure reveals no sensitive diagnostics;
- readiness performs no mutation.

## Non-executable PostgreSQL-integration test inventory

Map every operation to the exact database fixture state and approved database behavior it depends on. Include at least:

- normal initialized database;
- alternate recurring hours restored after the case;
- alternate permitted configuration restored after the case;
- modified table capacities and derived limits restored after the case;
- current customer states for match, mismatch, blank optional fields, and no customer;
- reservations and assignments producing free, partially occupied, full, overlap, and back-to-back cases;
- exact retry after deliberately losing or ignoring the first result;
- concurrent matching customer creation through preference and booking operations;
- booking-linked preference versus independent preference change;
- approved retryable PostgreSQL conflict outcomes;
- no direct application-role DML;
- no direct application-role reservation/assignment access where denied;
- routine execution through the approved application role;
- final state showing no duplicate customer, duplicate logical reservation, overbooking, or partial assignment;
- no persisted provisional availability, rejected candidate, retry, or random-selection data.

For each planned case, state:

- initial fixture state;
- operation invoked conceptually;
- approved PostgreSQL source or routine;
- expected operation category;
- expected persistent state;
- facts that must remain unchanged;
- later increment responsible for executable automation.

Do not rerun DB-07 as part of API-01 and do not write executable tests.

## Performance and freshness assessment

Assess the operation inventory against the approved DB-07 evidence without promising an unsupported response time.

State:

- which operations are read-only and expected to be relatively inexpensive;
- that daily availability and booking use exact database logic over no more than 30 Version 1 tables;
- that booking contention is coordinated by the approved restaurant-wide lock;
- that the accepted database-only p95 and contended-request observations are inputs to later end-to-end measurement, not Flask guarantees;
- that later API and integration increments must measure normalization, connection acquisition, bounded retries, serialization, network, Flask, and client costs in addition to PostgreSQL;
- that correctness and no-overbooking remain mandatory if the two-second expectation is exceeded under approved contention;
- which results are current snapshots and which must never be treated as durable promises.

Do not add caching, a queue, a hold system, a waitlist, an alternate allocator, or a new lock strategy during API-01.

## Traceability requirements

Provide matrices that demonstrate:

1. every SRS workflow and database-applicable field is covered by at least one operation;
2. roadmap API-01 requirements FR-02, FR-06 through FR-09, FR-15, FR-16, and FR-18 are covered;
3. roadmap API-01 nonfunctional requirements NFR-02, NFR-05, NFR-06, and NFR-09 are covered;
4. baseline items API-01 through API-07 are addressed without preempting API-02;
5. PRA-006 through PRA-025 and PRA-029 are covered;
6. every operation maps to an approved PostgreSQL read source or controlled routine;
7. every required Version 1 workflow has an operation path;
8. every operation has an approved requirement or technical-gate justification;
9. excluded requirements do not accidentally create operations.

For a requirement not directly applicable to API-01, state why it is satisfied by PostgreSQL, deferred to a named later increment, derived for presentation, or excluded. Do not mark it complete without rationale.

Use the actual SRS and rubric identifiers and wording found in the authoritative files. Do not invent requirement identifiers.

## Explicit Version 1 exclusions

The operation inventory must not include operations for:

- customer authentication, login, logout, registration, password reset, sessions, or verified ownership;
- customer profile retrieval, automatic form prefilling, or self-service contact updates;
- email-ownership verification;
- reservation lookup as an authenticated customer service;
- cancellation, modification, rescheduling, or no-show handling;
- administrative reservation management;
- table administration, activation/deactivation, adjacency, combinability, or customer-selected tables;
- waiting lists, queues, temporary holds, seat sharing, or seat-level assignment;
- availability, slot, or candidate persistence;
- holiday or exceptional-date schedules;
- closed weekdays, overnight service, or multiple daily service periods;
- configuration or schedule history;
- newsletter history or audit events;
- confirmation email or SMS delivery;
- payment, menu ordering, loyalty, or marketing analytics;
- reservation archive, purge, or history browsing;
- audit/history tables or generic unapproved audit operations;
- database reset, migration, seed, or administrative verification through Flask;
- exposing raw SQL, role management, or internal database diagnostics;
- more than 30 Version 1 restaurant tables.

Also list any operation considered and rejected during minimization, with the approved reason it is unnecessary, derived, internal, later, or excluded.

## Required API-01 deliverables

Create or update:

`docs/approved-design-artifacts/Cafe_Fausse_API01_Backend_Operation_Inventory.md`

The completed artifact must contain:

1. document title, version, status, date, author, and approval record;
2. executive summary;
3. authoritative-source and approved-baseline statement;
4. API-01 scope and explicit API-02 boundary;
5. initial repository-verification summary;
6. Version 1 workflow inventory;
7. minimum backend-operation catalogue;
8. minimization analysis, including grouped versus separate read operations;
9. complete per-operation specifications;
10. operation-to-PostgreSQL-contract mapping;
11. conceptual input provenance matrix;
12. Flask normalization and validation catalogue;
13. conceptual result-fact catalogue;
14. operation outcome and failure taxonomy;
15. retry, timeout, idempotency, and ambiguous-commit design boundary;
16. data-minimization, privacy, and safe-logging assessment;
17. authorization and out-of-scope statement;
18. PostgreSQL/Flask/React/later-increment responsibility matrix;
19. non-executable unit-test inventory;
20. non-executable PostgreSQL-integration test inventory;
21. performance and freshness assessment using the accepted DB-07 evidence;
22. SRS, rubric, PRA, baseline-API, roadmap, and PostgreSQL-contract traceability matrices;
23. explicit Version 1 exclusions and rejected-operation catalogue;
24. decisions deferred to API-02, API-03, API-04, and later React/integration increments;
25. DB-07 compatibility assessment;
26. unresolved issues, if any;
27. API-01 completion assessment;
28. API-01 approval checkpoint and the exact next increment it would authorize.

Use non-executable catalogues, matrices, decision tables, and explanatory prose. A small operation-flow diagram may be included if it adds clarity, but it must use Mermaid syntax compatible with the repository renderer. Avoid punctuation-heavy Mermaid message text that may cause parse errors. The prose and tables remain authoritative.

Do not change an approved artifact merely to restate API-01. Reference approved artifacts without rewriting their historical content.

## Completion criteria

API-01 is complete only when:

- every approved Version 1 user workflow maps to a minimum backend operation path;
- every operation has a justified approved source;
- current hours, configuration/limits, daily availability, customer newsletter-status lookup, newsletter preference setting, reservation creation/exact retry, and health/readiness are all covered;
- every operation maps to an authorized PostgreSQL read path or frozen controlled routine;
- no operation duplicates PostgreSQL authority or creates a new source of truth;
- conceptual inputs, validation, results, failures, retries, privacy, and tests are defined for every operation;
- the design can support React, mobile, and third-party clients through later REST design without trusting any client for integrity;
- the accepted DB-07 PostgreSQL 18.3 baseline and performance limitation are accurately preserved;
- no endpoint syntax, Flask implementation, React implementation, or excluded workflow has been introduced;
- all unresolved contradictions are explicitly escalated rather than silently resolved;
- the artifact clearly pauses for approval before API-02.

## Stop conditions

Stop and request approval if completing API-01 would require:

- changing the frozen PostgreSQL Contract for Flask version 1.0;
- changing a DB-03 schema decision;
- changing the DB-04 transaction, concurrency, retry, fingerprint, or allocation design;
- modifying an approved migration or controlled database operation;
- granting the Flask role new database privileges;
- adding a database routine, view, table, column, index, or write path;
- introducing a new business rule or Version 1 workflow;
- choosing a public REST path, HTTP method, status, payload, or error envelope to resolve an ambiguity;
- adding authentication, ownership verification, cancellation, modification, messaging, or administration;
- contradicting an authoritative SRS, rubric, PRA, approved design, or recorded DB-07 approval.

For any stop condition, report:

- the exact contradiction or missing decision;
- the authoritative sources involved;
- the affected required operation;
- why the frozen contract cannot satisfy it;
- the smallest proposed resolution;
- downstream compatibility and approval impact.

Do not silently choose.

## Final response and approval checkpoint

At completion, report:

- files created or changed;
- confirmation that `database/`, `backend/`, and `frontend/` implementation files were not changed;
- the final operation list;
- the PostgreSQL read path or controlled routine used by each operation;
- requirements and workflows covered;
- decisions deferred to API-02 and later increments;
- deviations from this prompt, if any;
- unresolved decisions requiring approval, if any;
- Git working-tree summary;
- the API-01 completion assessment.

End at this checkpoint:

> **API-01 approval is required before API-02 may begin. Approval authorizes only API-02 REST Contract Design. It does not authorize Flask implementation, React work, or changes to the approved PostgreSQL layer.**

Do not begin API-02.

