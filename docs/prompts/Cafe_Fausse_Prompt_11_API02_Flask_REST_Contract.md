# Prompt 11 - Design the Flask REST contract

Begin only **API-02 - Flask REST Contract** of the approved least-to-most implementation roadmap.

Work in the repository-connected Codex environment with the Cafe Fausse repository root open. Convert the approved API-01 backend operation inventory into one complete, stable, implementation-neutral HTTP/JSON contract that later Flask and React increments can implement without inventing fields, outcomes, business rules, or database access paths.

This is a design and phase-gate increment. Do not implement Flask, React, or PostgreSQL.

Do not begin API-03 or any later increment.

## Authoritative sources

Use the following as authoritative, in this order:

1. `docs/SRS(1).pdf`;
2. `docs/Rubric(1).pdf`;
3. the approved Project Requirements Addendum version 2.2.1, including PRA-001 through PRA-029;
4. the approved DB-01 Persistent-Data Requirements Analysis version 1.2.1;
5. the approved DB-02 Conceptual Data Model version 1.2;
6. the approved DB-03 Logical PostgreSQL Schema and Integrity Design version 1.1;
7. the approved DB-04 Reservation Transaction and Concurrency Design version 1.1;
8. the approved DB-05 through DB-07 implementation, verification, completion, and Hard Gate 1 evidence in the repository;
9. `database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, the approved and frozen PostgreSQL Contract for Flask version 1.0;
10. `docs/approved-design-artifacts/Cafe_Fausse_API01_Backend_Operation_Inventory.md`, approved API-01 Backend Operation Inventory version 1.0.1;
11. the approved least-to-most implementation roadmap version 1.1.1;
12. the Project Requirements Baseline version 1.0 when needed for baseline API and rubric identifiers;
13. the repository-root `AGENTS.md` and any more-specific applicable repository instructions.

DB-01 through DB-07 and API-01 are approved. API-01 version 1.0.1 was explicitly approved by Abdul on 2026-08-21. Do not reopen or silently change its seven-operation inventory, operation responsibilities, PostgreSQL mappings, normalization rules, retry principles, exclusions, or accepted DB-07 limitations unless a genuine contradiction prevents a safe REST contract.

The current repository is authoritative for exact approved artifact paths, operation identifiers, database routine signatures, stable database outcomes, result shapes, grants, and approval records. Locate and read the actual repository files before designing the contract.

## Accepted baseline

Treat the following as approved baseline facts, not API-02 defects or reasons to repeat earlier increments:

- PostgreSQL 18.3 is the sole required and verified Version 1 PostgreSQL target.
- `pgcrypto` and the frozen PostgreSQL Contract for Flask version 1.0 remain required.
- The application role may read only the four approved foundation tables and execute only the three approved production routines.
- Flask may not directly read reservations or reservation-table assignments, perform direct business-table writes, reproduce allocation, or generate retry fingerprints.
- API-01 version 1.0.1 defines exactly seven conceptual operations:
  1. obtain current reservation context;
  2. obtain daily provisional availability;
  3. look up customer newsletter status;
  4. set newsletter preference;
  5. create or reconstruct a reservation;
  6. check process liveness; and
  7. check service readiness.
- OP-05 uses the frozen booking routine and, only after a successful booked, booked-with-phone-notice, or exact-retry result, performs the approved minimal customer read by canonical email for stored first name, optional middle initial, and last name.
- Confirmation display spelling comes from that stored-name read, not resubmitted casing.
- Exact retry uses ordinary booking facts, returns the existing reservation, and does not replay contact or newsletter mutation.
- The accepted database performance evidence is not a Flask or end-to-end guarantee. General exact allocation has measured database p95 around 1.14-1.27 seconds, and approved coarse-lock contention can exceed two seconds.
- Full validation of the SRS two-second form expectation remains assigned to later Flask and integration performance gates.

## API-02 objective

Define the complete external REST contract for the seven approved API-01 operations, including:

- stable API versioning convention;
- exact HTTP methods;
- exact paths;
- request locations and exact serialized field names;
- request and response JSON structures;
- scalar, object, array, nullable, optional, and enumerated types;
- field normalization and validation semantics visible to callers;
- calendar-date, recurring-local-time, local-date-time, UTC-offset, and canonical-instant representations;
- success response variants;
- a common safe error envelope;
- stable public error codes;
- HTTP status codes;
- retryability and ambiguous-outcome signals;
- exact-retry representation;
- privacy and exposure boundaries;
- health and readiness representation;
- contract-schema and contract-to-database test cases;
- complete traceability to API-01 and authoritative requirements.

The approved contract must be sufficient for:

- later Flask architecture and implementation;
- later React development against mocks without a live backend;
- future mobile or third-party clients that follow the same HTTP contract;
- contract tests that distinguish new success, exact retry, validation, mismatch, overlap, unavailable capacity, temporary technical failure, and unknown booking outcome.

## Hard scope boundary

API-02 may create or update only the API-02 design artifact and narrowly necessary documentation references. It must not change `database/`, `backend/`, or `frontend/` implementation files.

Do not generate or select:

- Flask or Python code;
- SQL, migrations, routines, views, indexes, grants, or database fixes;
- React, JSX, JavaScript, TypeScript, CSS, components, hooks, or state management;
- package manifests, libraries, dependencies, framework extensions, or database drivers;
- Flask module layout, classes, services, repositories, decorators, or application factory design;
- connection-pool implementation;
- transaction-wrapper implementation;
- numeric application deadlines, driver timeouts, lock timeouts, or backoff constants not already frozen by PostgreSQL;
- logging framework, log format, correlation implementation, or telemetry vendor;
- CORS, proxy, deployment hostnames, TLS termination, environment variables, containers, or hosting;
- authentication, authorization middleware, sessions, tokens, accounts, CAPTCHA, or rate limiting;
- executable OpenAPI, Swagger, JSON Schema, Postman, tests, fixtures, or scripts;
- executable unit, integration, concurrency, browser, or end-to-end tests;
- API-03 architecture or any implementation increment;
- new business operations, PostgreSQL access paths, persistent facts, or Version 1 features.

Non-executable JSON request and response examples are required because they clarify the wire contract. Human-readable schema catalogues and examples are allowed. Do not produce generated server/client code or a machine-executed specification during API-02.

## Required initial read-only repository verification

Before creating or modifying the API-02 artifact:

1. Read the applicable `AGENTS.md` instructions.
2. Inspect Git status and preserve every unrelated user change.
3. Locate and read all authoritative sources listed above.
4. Confirm the exact approved filenames and versions present in the repository.
5. Confirm that API-01 version 1.0.1 is recorded as approved by Abdul on 2026-08-21.
6. Confirm that API-01 still contains the seven approved operations and the deterministic OP-05 customer-name source.
7. Confirm that DB-07 and the PostgreSQL Contract for Flask version 1.0 remain approved and frozen.
8. Verify the implemented PostgreSQL routine signatures, stable outcomes, and result columns against the frozen contract without changing the database.
9. Inspect the application role's read and routine-execution privileges relevant to each API-01 operation.
10. Inspect `backend/` only to establish whether unapproved Flask implementation exists. Do not edit it.
11. Inspect the roadmap boundary between API-02 and API-03.
12. Record the initial working-tree state and repository paths used as evidence.

If API-01 approval is absent, the approved API-01 content differs materially from version 1.0.1, the frozen PostgreSQL contract is missing or inconsistent with implementation, a required route would need a database change, or the working tree contains overlapping unexplained changes, stop and report the exact blocker. Do not invent a replacement operation or contract.

## Required endpoint coverage

Define one REST endpoint for each approved operation unless a different endpoint count is strictly necessary to represent the approved operation without ambiguity. Any split or grouping must be justified and must not create a new business operation.

The contract must include recognizable endpoint coverage for:

1. **OP-01 - Current reservation context**
   - seven recurring weekday schedules;
   - current reservation interval and duration settings;
   - advance-window and same-day-lead settings;
   - restaurant timezone;
   - current restaurant-local reservable-date bounds;
   - current maximum party size;
   - only the public aggregate facts needed by clients.

2. **OP-02 - Daily provisional availability**
   - requested restaurant-local date and party size;
   - every legitimate aligned start for the day;
   - available and unavailable slot states;
   - unambiguous proposed start/end representations;
   - explicit provisional/non-guaranteed meaning.

3. **OP-03 - Customer newsletter-status lookup**
   - normalized customer identity input plus transient confirmation email;
   - matching subscribed/unsubscribed state;
   - no-customer/not-applicable result;
   - generic identity conflict;
   - safe indeterminate technical result;
   - no profile or contact exposure.

4. **OP-04 - Set newsletter preference**
   - normalized identity input plus transient confirmation email;
   - explicit desired Boolean state;
   - new subscribed customer, existing subscribed/unsubscribed customer, idempotent current state, and new-unselected/no-customer result;
   - generic identity conflict and safe retry behavior.

5. **OP-05 - Create or reconstruct reservation**
   - normalized reservation/customer input;
   - transient confirmation email;
   - optional phone;
   - selected restaurant-local start represented with an explicit UTC offset;
   - party size;
   - booking-linked newsletter action of subscribe, unsubscribe, or no change;
   - new booking, booked-with-phone-notice, and exact-retry success;
   - complete confirmation representation;
   - same-customer overlap, unavailable capacity, validation, mismatch, temporary failure, and ambiguous-outcome recovery.

6. **OP-06 - Process liveness**
   - minimal process-local liveness only;
   - no database claim or diagnostic inventory.

7. **OP-07 - Service readiness**
   - minimal ready/not-ready representation;
   - database-backed readiness without exposing secrets or detailed internals;
   - no mutation or DB-07 re-execution.

Do not add endpoints for content that is static/UI-only unless an authoritative requirement and API-01 explicitly require a backend operation.

## Endpoint-selection requirements

For each endpoint, select and justify:

- HTTP method;
- stable route path;
- API versioning placement;
- whether inputs appear in the path, query string, or JSON body;
- success status code for every success variant;
- whether repeated identical requests are safe or idempotent;
- whether the endpoint may be cached and, if so, under what non-authoritative semantics;
- whether the operation is intended for an unauthenticated public client or infrastructure supervisor;
- whether an endpoint should be excluded from public navigation/documentation while still remaining minimally accessible for infrastructure;
- content type and character encoding;
- request and response body presence;
- privacy rationale for keeping personally identifiable values out of URLs, query strings, logs, and cache keys.

Apply HTTP semantics accurately:

- use a safe retrieval method only for side-effect-free operations;
- do not place names, email addresses, confirmation email, phone, or booking details in a URL or query string;
- use a mutation method whose semantics accurately represent setting a final newsletter Boolean;
- distinguish a newly created reservation from reconstruction of an existing exact retry without treating the retry as another creation;
- do not use an HTTP method as a substitute for PostgreSQL concurrency protection;
- do not invent a client-generated idempotency key.

Compare reasonable route/method alternatives only where a genuine decision exists. Choose the least complex consistent convention and apply it uniformly.

## API naming and versioning conventions

Define a compact, consistent convention for:

- API version prefix;
- plural resource or operation-oriented path segments;
- lowercase path spelling;
- JSON property naming;
- public error-code naming;
- enum-value naming;
- Boolean naming;
- array and collection naming;
- date/time property suffixes;
- identifiers serialized for JavaScript safety;
- omission versus explicit `null`;
- empty string treatment;
- unknown/extra request fields;
- response-field stability.

Avoid RPC-style endpoint proliferation where ordinary resource semantics are clear, but do not force misleading resource semantics onto health checks or the exact API-01 operations.

Do not version internal PostgreSQL object names into the public contract. The API version is an HTTP compatibility boundary, not the database migration number.

## Common request rules

Define common rules for every JSON request:

- accepted media type;
- UTF-8 JSON expectation;
- object body requirement;
- behavior for malformed JSON;
- behavior for missing body;
- behavior for unsupported media type;
- behavior for unknown fields;
- behavior for duplicate JSON member names if the parser exposes them;
- distinction among omitted, `null`, and empty string;
- no coercion of strings to integers or Booleans where it could hide invalid input;
- no acceptance of NaN, Infinity, fractional party size, or non-JSON numeric values;
- field-specific maximum lengths;
- normalized values used for database calls;
- confirmation email being required where approved, compared after normalization, never returned, never logged, and never persisted;
- safe response when a request contains forbidden server-controlled facts.

Do not choose a JSON parsing or validation library during API-02.

## Customer identity field contract

Define exact request-field names, JSON types, presence/nullability, length limits, normalization meaning, and validation outcomes for:

- first name;
- optional middle initial;
- last name;
- email;
- confirmation email;
- optional reservation-only phone.

Preserve these approved semantics:

- first and last names are required, trimmed, internal whitespace collapsed, 1-100 characters, and contain at least one Unicode letter;
- display spelling, punctuation, and accents are preserved;
- matching is case-insensitive after approved normalization;
- middle initial is optional, permits one alphabetic character with an optional period in input, and normalizes to one uppercase character;
- omitted middle initial preserves stored state;
- a supplied middle initial may populate a blank stored value only inside an approved mutating operation;
- conflicting populated middle initials are rejected;
- email is required, trimmed, lowercased canonically, valid syntax, and no more than 254 characters;
- email confirmation is required in the reservation and newsletter user-facing workflows and must equal the normalized email;
- confirmation email is transient and must not appear in responses or logs;
- phone is optional and accepted only for booking;
- phone permits only approved characters and contains 7-15 digits;
- omitted phone preserves stored state;
- a supplied phone may populate a blank stored value on successful new booking behavior;
- a differing populated phone is not overwritten and may produce a successful notice;
- phone and middle initial are not identity keys;
- no customer ID may be accepted or exposed.

Select one stable public representation for optional middle initial and phone. Explain exactly how omission, `null`, and empty string are handled so later clients cannot accidentally request a profile change.

## Reservation-context response contract

Define the complete OP-01 response schema.

At minimum, determine and justify the representation of:

- restaurant timezone as a valid IANA identifier;
- ISO weekday 1 through 7;
- local opening and closing times;
- reservation start interval in minutes;
- reservation duration in minutes;
- maximum advance window in calendar days;
- same-day minimum lead in minutes;
- current restaurant-local minimum reservable date;
- inclusive maximum reservable date;
- maximum party size;
- any restaurant address/phone facts required for consistent later confirmation or display.

Decide whether total capacity is necessary to expose. Prefer the smallest public response; maximum party size is required, but table-level capacities and unnecessary internal aggregates must not be exposed.

Define array ordering, weekday completeness, and behavior when configuration, timezone, schedule, or inventory is unusable. Do not fabricate defaults or hardcode the SRS schedule as an independent Flask source.

## Provisional-availability contract

Define the OP-02 request and response in full.

The request must contain only:

- restaurant-local calendar date; and
- party size.

The response must:

- include every legitimate aligned start returned by PostgreSQL;
- preserve available and unavailable entries;
- identify the requested local date and current timezone context as needed;
- represent each proposed start/end unambiguously;
- make clear that availability is provisional and not a hold or guarantee;
- define deterministic slot ordering;
- avoid customer, reservation, assigned/free table, table-combination, candidate, ranking, random, fingerprint, and unnecessary capacity data;
- distinguish a valid day with every slot unavailable from an invalid request or unusable configuration;
- permit React to display legitimate slots without generating arbitrary times.

Define whether no legitimate starts yields an empty successful collection or an approved failure, based on the current Version 1 recurring-hours model. Do not invent closed-day, holiday, overnight, or multiple-service-period behavior.

## Newsletter-status lookup contract

Define OP-03 as a privacy-sensitive, side-effect-free operation.

The contract must:

- keep all identity values out of the URL and query string;
- accept only the approved identity and confirmation facts;
- return the minimum state needed to synchronize the checkbox;
- distinguish an exact existing match, no customer, generic identity mismatch, middle-initial conflict where externally appropriate, validation failure, and technical indeterminacy;
- avoid exposing stored names, email, phone, customer ID, reservations, or the cause/value behind a generic mismatch;
- define whether an indeterminate lookup is represented as an error response or a successful response with an indeterminate state;
- support the approved rule that booking may continue with newsletter action set to no change after lookup indeterminacy;
- remain non-cacheable where caching could expose or stale customer preference data.

Choose public semantics that do not accidentally turn this endpoint into account discovery, profile retrieval, or ownership verification. Explain the privacy tradeoff of distinguishing no customer from mismatch because the approved workflow requires both operational outcomes.

## Newsletter-preference contract

Define OP-04 in full.

The request must contain:

- approved identity and confirmation fields; and
- an explicit desired newsletter Boolean.

The response must represent:

- final authoritative newsletter state for a matching or newly created customer;
- successful idempotent repetition;
- new-unselected/no-customer behavior;
- generic identity mismatch;
- middle-initial conflict where externally appropriate;
- validation failure;
- temporary technical failure;
- ambiguous mutation outcome and safe resubmission if the result is unknown.

Select HTTP semantics that accurately represent setting a final Boolean state. Do not introduce subscribe/unsubscribe event resources, history, messaging, customer IDs, or a second newsletter source of truth.

## Reservation-creation and exact-retry contract

Define OP-05 in full.

### Request

The request may contain only:

- approved first, optional middle, and last name fields;
- canonicalizable email and transient confirmation email;
- optional validated phone;
- the selected restaurant-local start in the approved unambiguous representation;
- explicit selected UTC offset;
- party size;
- booking-linked newsletter action: subscribe, unsubscribe, or no change.

The request must not accept:

- customer ID;
- reservation ID or confirmation reference;
- fingerprint or idempotency key;
- table number or requested table;
- calculated end time or duration;
- availability Boolean or slot status;
- configuration, timezone, hours, capacity, or derived maximum;
- assigned tables, candidate combinations, rank, or random value;
- newsletter history or original newsletter state.

### Success variants

Define distinct wire semantics for:

- newly created booking;
- newly created booking with differing-phone notice;
- exact retry returning an existing booking.

Determine whether the HTTP status, response body, or both distinguish a new creation from an exact retry. Exact retry is a success, not a conflict and not another creation.

The confirmation representation must include:

- stable reservation confirmation reference;
- authoritative stored customer display name from the approved post-success customer-name read;
- restaurant-local start and end;
- unambiguous canonical start and end if needed by clients;
- party size;
- all assigned table numbers in deterministic ascending order;
- current authoritative newsletter state;
- differing-phone notice when applicable;
- restaurant address and phone required by the SRS/PRA;
- an explicit absence of any email/SMS delivery claim.

PostgreSQL `BIGINT` confirmation references must be serialized safely for JavaScript clients. Evaluate and document string serialization rather than assuming all values are safe JSON numbers.

Do not expose database fingerprint/version, customer ID, stored phone, free tables, candidates, capacities, database outcome/detail strings, or unrelated customer facts.

### Failure and recovery variants

Define public behavior for:

- request validation failure;
- customer identity mismatch;
- middle-initial conflict where appropriate;
- same-customer overlapping reservation;
- authoritative no-capacity/unavailable result after stale provisional availability;
- invalid or unusable database configuration;
- retryable database conflict after bounded internal attempts;
- operation timeout;
- database unavailable;
- unexpected internal failure;
- connection loss or commit ambiguity where the booking may have committed.

An ambiguous outcome must not state that the booking definitely failed. The response must give a safe ordinary-resubmission path. Resubmission uses the same normal booking request; no client key is introduced.

## Date and time wire contract

Select one exact, consistent representation for each temporal category:

- restaurant-local calendar date;
- recurring restaurant-local opening/closing time;
- selected restaurant-local booking start;
- explicit selected UTC offset;
- canonical reservation start/end instants;
- restaurant-local confirmation start/end;
- restaurant timezone identifier.

At minimum, decide and justify:

- RFC 3339/ISO 8601 profile and precision;
- whether seconds are always present;
- whether fractional seconds are prohibited or normalized;
- whether canonical instants use `Z` or an explicit numeric offset;
- how the selected local wall time and offset reach Flask without browser/host timezone reinterpretation;
- offset sign convention and permitted range;
- how nonexistent and ambiguous daylight-saving local times are reported;
- whether the response includes both canonical and restaurant-local forms;
- how React avoids converting restaurant-local values through the browser timezone;
- inclusive/exclusive date-bound meaning;
- half-open reservation interval meaning;
- back-to-back endpoint behavior.

Do not allow an unzoned timestamp to be interpreted using the Flask host timezone. Do not make React calculate authoritative offsets, duration, end time, or valid starts independently.

## Identifier and number serialization

Define exact wire types and ranges for:

- reservation confirmation reference;
- ISO weekday;
- party size;
- table number;
- interval/duration/lead minutes;
- advance days;
- UTC offset minutes;
- Boolean values.

Explicitly address JavaScript's safe-integer limit for PostgreSQL `BIGINT`. No public customer identifier or database fingerprint exists.

Do not coerce numeric strings for bounded business integers unless the contract explicitly defines a string representation for identifier safety.

## Common success-envelope decision

Determine whether successful responses use:

- direct resource/operation-specific bodies; or
- a small common success envelope.

Select one approach and apply it consistently. Avoid wrappers that add no semantic value. If metadata is included, every item must have a justified consumer.

Do not include server timestamps, request IDs, pagination, links, debug data, database versions, or generic metadata merely because other APIs commonly do so. Add a field only when an approved requirement or necessary protocol behavior justifies it.

## Common error envelope

Define one safe, stable error envelope for all endpoints.

At minimum, determine whether it contains:

- stable public error code;
- nontechnical human-readable message;
- optional field-specific validation details;
- retryable Boolean;
- outcome-unknown Boolean or equivalent ambiguity signal;
- optional safe operation context;
- optional transient request-correlation value, if justified without exposing it as business data.

For every error member, define:

- exact JSON name and type;
- required/optional/nullability rules;
- meaning;
- when it appears;
- whether clients may branch on it;
- privacy and logging implications.

Field-validation details must identify only caller-visible request fields and safe validation rules. They must never disclose stored customer values, SQL, relation/routine names, database outcome/detail strings, SQLSTATE, stack traces, connection data, credentials, locks, retry counts, or internal exception types.

Do not use free-form message text as the only machine-readable error signal.

## Public error-code and HTTP-status catalogue

Create a complete mapping from every approved operation outcome to:

- stable public error or success variant;
- HTTP status code;
- error-envelope presence;
- retryable value;
- outcome-known versus outcome-unknown state;
- safe caller action;
- public message intent;
- internal PostgreSQL source outcome/detail where applicable;
- redacted logging classification for later implementation.

Cover at least:

- malformed JSON;
- unsupported media type;
- missing request body;
- unknown or forbidden request fields;
- field-format and cross-field validation;
- no customer/no change;
- identity mismatch;
- middle-initial conflict;
- same-customer overlap;
- unavailable/full after revalidation;
- invalid database configuration;
- database unavailable;
- bounded retry exhaustion;
- timeout before a known result;
- ambiguous commit/result;
- unexpected failure;
- route not found;
- method not allowed;
- service not ready.

Distinguish validation, conflict, unavailable capacity, temporary service failure, and unknown mutation outcome. Do not expose frozen database detail strings directly merely because they are stable internally.

Explain any use of 200, 201, 204, 400, 404, 405, 409, 415, 422, 500, 503, or other selected status. Avoid status-code proliferation and select the smallest semantically accurate set.

## Exact-retry and idempotency contract

Define caller-visible retry semantics for each endpoint.

Preserve these rules:

- OP-01, OP-02, OP-03, OP-06, and OP-07 are side-effect free and safely repeatable, though snapshots can change;
- OP-04 sets a final Boolean and is safely repeatable;
- OP-05 does not accept a client-generated idempotency key;
- clients recover from an unknown booking result by resubmitting the same ordinary reservation facts;
- PostgreSQL exact retry verifies the approved underlying tuple and returns the existing reservation;
- exact retry performs no customer/contact/newsletter mutation;
- current newsletter state is returned;
- a retry after rollback may create a booking or return a current business outcome such as unavailable;
- the API must not label an ambiguous outcome as a definitive failure;
- the frozen database permits no more than three complete attempts for `55P03`, `40P01`, and `40001` within one overall operation deadline;
- API-03 selects implementation placement, numeric deadline, backoff values, and driver behavior.

Decide whether a safe public retry indicator, ambiguity indicator, or retry guidance belongs in the error envelope. Decide whether `Retry-After` is useful or unjustified without inventing a queue or guaranteed recovery time.

## Cache and privacy behavior

For every endpoint, define the contract-level cache policy and rationale.

At minimum:

- customer identity/status, preference mutation, booking, and technical readiness must not be stored in shared caches;
- personally identifiable values must not appear in URLs or cache keys;
- provisional availability and current context may become stale and must never be treated as booking guarantees;
- exact cache headers and infrastructure configuration may be implemented later, but the semantic requirement must be explicit;
- browser history must not receive names, email, phone, or booking request bodies through URLs;
- successful booking responses contain personal and reservation information and require appropriate non-cache semantics;
- liveness/readiness expose only minimal state.

## Authentication, authorization, and exposure boundary

Version 1 intentionally has no customer authentication or verified ownership. Define which endpoints are:

- unauthenticated public workflow endpoints; and
- infrastructure-oriented liveness/readiness endpoints.

The contract must not imply that an unauthenticated client may:

- retrieve arbitrary customer profiles;
- list or look up reservations;
- change contact information generally;
- cancel, modify, or reschedule reservations;
- select or administer tables;
- administer hours or configuration;
- invoke reset, migration, verification, or test helpers;
- view internal diagnostics.

Do not invent authorization headers, API keys, tokens, sessions, login, verification, or administration during API-02. Deployment-level restriction of readiness exposure may be selected later; the wire body must remain minimal either way.

## Database-to-HTTP mapping

Provide a complete mapping for every database-backed endpoint showing:

- API-01 operation;
- exact authorized foundation read or frozen routine;
- database inputs derived from request fields;
- database output fields consumed internally;
- public response fields produced;
- database outcomes/details translated to safe public outcomes;
- database fields intentionally withheld;
- transaction/retry boundary;
- behavior on connection loss or unknown commit;
- confirmation-name post-success read where applicable.

Preserve these restrictions:

- public clients never see PostgreSQL schema, relation, routine, role, SQLSTATE, fingerprint, or detail-code names;
- direct reservation and assignment reads remain prohibited;
- the booking routine remains the confirmation reconstruction path;
- Flask does not independently determine free tables, allocate tables, compare fingerprints, or adjudicate overlap;
- no new database query contract, routine, view, grant, or write path is introduced.

## Response examples

Provide clearly labeled non-executable JSON examples for every endpoint and every materially different response variant.

At minimum include examples for:

- current reservation context;
- partial daily availability with both available and unavailable slots;
- valid day with every legitimate slot unavailable;
- newsletter lookup: subscribed, unsubscribed, no customer, mismatch, indeterminate;
- newsletter preference: new subscribed, existing unsubscribed, idempotent result, new-unselected/no customer, conflict;
- reservation: newly booked single-table;
- reservation: newly booked multi-table;
- reservation: booked with differing-phone notice;
- reservation: exact retry;
- reservation: same-customer overlap;
- reservation: stale/unavailable;
- reservation: field validation failure;
- reservation: temporary retryable failure;
- reservation: ambiguous outcome with safe-resubmit guidance;
- liveness success;
- readiness success and not-ready;
- common malformed-body, unsupported-media, and unexpected-error responses.

Use illustrative values consistent with the SRS restaurant, `America/New_York`, Version 1 hours, and 30-table model. Examples must conform exactly to the declared schemas and must not contain real personal data.

## Contract-schema catalogue

Provide a complete catalogue of reusable wire schemas and endpoint-specific schemas.

For every field, record:

- JSON property name;
- type;
- format;
- required, optional, or conditionally present;
- nullable or non-null;
- permitted values/range;
- normalization;
- semantic source;
- returned/request-only/internal-only classification;
- example;
- validation error behavior;
- privacy classification.

At minimum catalogue:

- customer identity input;
- reservation context;
- weekday hours;
- availability request;
- availability slot;
- newsletter-status lookup request/result;
- newsletter-preference request/result;
- booking request;
- confirmation customer name;
- reservation confirmation;
- phone notice;
- health/readiness result;
- validation-field error;
- common error envelope.

Remove every unused, redundant, derived-but-unneeded, or internally sensitive field.

## Non-executable contract unit-test plan

Define contract-level test cases without writing tests.

For every endpoint, cover:

- accepted method/path/media type;
- rejected method/path/media type where relevant;
- required and optional fields;
- `null`, omission, empty string, wrong type, boundary length, and unknown fields;
- response schema for every success variant;
- response schema for every error category;
- HTTP status mapping;
- public error-code stability;
- absence of prohibited fields;
- cache/privacy semantics;
- representative Unicode names and confirmation matching;
- identifier and numeric boundary serialization;
- date/time and offset representation;
- all-slot availability ordering and unavailable flags;
- multi-table confirmation ordering;
- exact-retry representation;
- ambiguous-outcome retry guidance;
- current newsletter-state representation;
- liveness versus readiness distinction.

Include explicit cases for:

- PostgreSQL `BIGINT` reservation reference above JavaScript's safe-integer limit;
- optional middle and phone omission versus `null`/empty input;
- UTC offsets around daylight-saving boundaries;
- nonexistent and ambiguous restaurant-local starts;
- every database stable outcome mapped to exactly one safe public result;
- database detail codes not leaking into public bodies;
- confirmation email absent from responses and diagnostic examples;
- no customer/reservation/table internals in availability or lookup responses.

## Non-executable contract-to-database integration plan

For every endpoint, map contract cases to the required PostgreSQL fixture and result.

Include at least:

- normal context from one configuration, seven weekday rows, and 30 tables;
- alternate recurring hours and permitted configuration reflected without contract changes;
- changed positive table capacities reflected only through current maximum party size and availability;
- daily availability with free, partial, full, and back-to-back fixtures;
- matching and nonexistent customer lookup;
- generic customer identity and middle conflict;
- new subscribe, existing subscribe/unsubscribe, idempotent set, and new-unselected/no customer;
- concurrent same-email preference/create behavior mapped to one HTTP result per request;
- new single-table and multi-table booking;
- differing-phone success notice;
- exact retry with different accepted request casing returning stored display spelling;
- same-customer overlap;
- different-customer overlap with sufficient capacity;
- stale availability followed by authoritative unavailable;
- retryable PostgreSQL conflict and retry exhaustion;
- connection loss before/during/after commit and safe resubmission;
- invalid database configuration;
- database unavailable;
- app-role privilege denials preventing bypass;
- liveness independent of database availability;
- readiness dependent on approved PostgreSQL prerequisites.

For each case, define:

- initial fixture state;
- HTTP request variant;
- API-01 operation;
- PostgreSQL source/routine;
- database outcome;
- expected HTTP status and body schema;
- expected persistent state;
- facts withheld from the client;
- later increment responsible for executable automation.

Do not run DB-07 or write executable tests during API-02.

## Manual contract review cases

Define a human review checklist proving that:

- a React developer can construct every required request without knowing PostgreSQL details;
- a React developer can render every required success, pending-recovery, unavailable, and error state without inventing fields;
- legitimate slots come only from the API;
- unavailable slots are present and distinguishable;
- customer status lookup cannot retrieve a profile;
- exact retry is distinguishable from a new booking but remains success;
- single-table and multi-table confirmations use one schema;
- all table numbers appear in ascending order;
- confirmation shows no delivery claim;
- public errors are nontechnical and do not leak stored identity mismatch causes;
- ambiguous booking outcome never claims definitive failure;
- names, email, phone, and booking data never appear in URLs;
- no response exposes free tables, candidates, fingerprints, SQL, SQLSTATE, or database detail codes;
- no cancellation, modification, authentication, administration, messaging, or unapproved operation appears;
- API-03 can implement the contract without choosing new wire behavior.

## Performance and payload assessment

Assess the contract without promising unsupported latency.

Define:

- which payloads are expected to be small and bounded;
- the maximum logical slot collection based on permitted hours and intervals without hardcoding one seed count as a protocol limit;
- why no pagination is needed for seven weekdays, 30-table-derived limits, or one day's slots;
- why table candidates and internal capacity details are omitted;
- how contract overhead should be measured later in addition to the approved database evidence;
- which operations may be retried within one later-defined deadline;
- how the accepted coarse-lock contention limitation is represented as safe temporary or retryable behavior rather than a correctness failure;
- why no streaming, queue, asynchronous job, hold, or polling workflow is justified in Version 1.

Do not define numeric Flask or network performance guarantees beyond the approved requirements and accepted limitations.

## Traceability requirements

Provide matrices showing:

1. every API-01 operation maps to exactly one justified endpoint or an explicitly justified split;
2. every endpoint maps to an approved API-01 operation;
3. every request/response field maps to an approved operation fact or protocol necessity;
4. every database outcome maps to one safe public result;
5. every public error code maps to at least one approved outcome and has a defined HTTP status;
6. every SRS external/communication-interface requirement is addressed;
7. SRS FR-02, FR-06 through FR-09, FR-15, FR-16, and FR-18 are covered;
8. SRS NFR-06 and relevant NFR-02/NFR-05/NFR-09 implications are preserved;
9. PRA-012, PRA-014, PRA-019 through PRA-025, and PRA-029 are covered;
10. baseline API-01 through API-07 and relevant rubric requirements are covered without claiming implementation;
11. every field needed by later React flows is present;
12. every prohibited internal field is absent;
13. every choice deferred to API-03 or later has a named destination.

Use actual identifiers and wording found in the repository sources. Do not invent requirement IDs.

## Explicit Version 1 exclusions

Do not define endpoints, request fields, response fields, actions, or links for:

- authentication, login, logout, registration, passwords, sessions, or verified ownership;
- customer profile retrieval, automatic prefill, or general contact updates;
- email verification;
- reservation lookup by confirmation reference;
- reservation listing, cancellation, modification, rescheduling, or no-show handling;
- reservation or table administration;
- customer-selected tables;
- table activation, adjacency, combinability, sharing, or seat assignment;
- temporary holds, waitlists, queues, or asynchronous booking jobs;
- availability, candidate, retry, or random-history persistence;
- holiday/date-specific schedules;
- closed recurring days, overnight service, or multiple daily periods;
- configuration, hours, or table-capacity administration;
- schedule/configuration/newsletter history;
- confirmation email or SMS delivery;
- payments, menus, ordering, loyalty, or analytics;
- audit/history feeds;
- archive or purge;
- database migration, rebuild, reset, seed, verification, performance, or test helpers;
- SQL, schema, role, extension, version diagnostics beyond minimal readiness;
- pagination, search, filtering, sorting controls, or generic CRUD endpoints that no approved workflow needs;
- client-supplied customer IDs, reservation IDs, fingerprints, idempotency keys, table choices, end times, duration, availability assertions, or configuration values.

List any endpoint or field considered and rejected, with the approved reason it is unnecessary, derived, internal, privacy-sensitive, excluded, or assigned to a later increment.

## Required API-02 deliverable

Create or update:

`docs/approved-design-artifacts/Cafe_Fausse_API02_Flask_REST_Contract.md`

The completed artifact must contain:

1. document title, version, status, date, author, and approval record;
2. executive summary;
3. authoritative-source and approved-baseline statement;
4. API-02 scope and API-03 boundary;
5. initial repository-verification summary;
6. selected API naming and versioning conventions;
7. endpoint catalogue for every API-01 operation;
8. endpoint-selection and minimization rationale;
9. common HTTP and JSON rules;
10. complete request schema for every endpoint;
11. complete success-response schema for every endpoint and variant;
12. exact date/time and UTC-offset wire contract;
13. identifier and numeric serialization rules;
14. customer identity and optional-field semantics;
15. complete reservation-context representation;
16. complete-slot provisional-availability representation;
17. newsletter-status and preference representations;
18. booking and exact-retry request/confirmation representations;
19. liveness and readiness representations;
20. common safe error envelope;
21. public error-code and HTTP-status catalogue;
22. database-outcome/detail to HTTP mapping;
23. retry, idempotency, timeout, and ambiguity semantics;
24. cache, privacy, exposure, and redaction rules;
25. authorization/out-of-scope statement;
26. operation-to-endpoint and field-source matrices;
27. complete non-executable JSON examples;
28. complete field-level wire-schema catalogue;
29. non-executable contract unit-test plan;
30. non-executable contract-to-database integration-test plan;
31. manual contract-review checklist;
32. performance and payload assessment;
33. SRS, rubric, PRA, baseline-API, API-01, and PostgreSQL-contract traceability matrices;
34. explicit Version 1 exclusions and rejected endpoint/field catalogue;
35. decisions deferred to API-03 and later API/React/integration increments;
36. DB-07 and API-01 compatibility assessment;
37. unresolved issues, if any;
38. API-02 completion assessment;
39. API-02 approval checkpoint and exact next increment authorized.

Use non-executable schema catalogues, tables, decision matrices, and explanatory prose. JSON examples may use fenced `json` blocks. A compact flow diagram may be included only if it materially improves understanding and uses Mermaid syntax compatible with the repository renderer. Keep prose and tables authoritative.

Do not change API-01 or another approved artifact merely to restate API-02. Reference approved historical artifacts without rewriting them.

## Completion criteria

API-02 is complete only when:

- every approved API-01 operation has one stable HTTP path and method or a rigorously justified split;
- a later React client can discover hours/limits, request every legitimate daily slot, synchronize newsletter state, set newsletter preference, submit/retry a booking, render complete confirmation, and handle every approved failure without inventing a field or rule;
- a later Flask implementation can map every request to exactly one approved operation and authorized PostgreSQL path;
- all request/response field names, types, formats, optionality, nullability, ranges, and enum values are explicit;
- all date/time/offset representations are unambiguous and restaurant-timezone safe;
- PostgreSQL `BIGINT` confirmation references are JavaScript safe;
- exact retry is successful and distinct from new creation without a client key;
- ambiguous booking outcomes support safe ordinary resubmission without claiming failure;
- every internal database outcome/detail is mapped to a safe public result;
- the common error envelope and status catalogue cover every operation outcome;
- availability exposes every legitimate slot and no internal allocation/customer/reservation data;
- customer lookup exposes no profile or mismatch cause;
- no personally identifiable request value appears in URLs;
- no endpoint or field duplicates PostgreSQL authority or creates a new source of truth;
- no Flask architecture, implementation, React implementation, or excluded workflow has been introduced;
- accepted PostgreSQL 18.3 and performance limitations are accurately preserved;
- unresolved contradictions are explicitly escalated;
- the artifact pauses for approval before API-03.

## Stop conditions

Stop and request approval if completing API-02 would require:

- changing the approved API-01 operation inventory or version 1.0.1 decisions;
- changing the frozen PostgreSQL Contract for Flask version 1.0;
- changing a DB-03 schema or DB-04 transaction/concurrency decision;
- modifying a migration, routine, grant, database result shape, stable database outcome/detail, or read privilege;
- adding a database query, view, routine, table, column, index, or write path;
- introducing a new business operation or Version 1 workflow;
- adding authentication, ownership verification, cancellation, modification, messaging, administration, holds, queues, or history;
- selecting Flask architecture, dependencies, numeric application timeouts, logging implementation, CORS, or deployment topology to resolve a wire ambiguity;
- exposing PII or internal database facts contrary to approved privacy boundaries;
- contradicting the SRS, rubric, PRA, approved roadmap, DB-07, or API-01.

For any stop condition, report:

- exact contradiction or missing decision;
- authoritative sources involved;
- affected API-01 operation and proposed endpoint;
- why the approved layers cannot support a safe contract;
- smallest proposed resolution;
- compatibility, migration, testing, and approval impact.

Do not silently choose.

## Final response and approval checkpoint

At completion, report:

- files created or changed;
- confirmation that `database/`, `backend/`, and `frontend/` implementation files were not changed;
- final endpoint list with methods and paths;
- API versioning convention;
- common success and error-envelope decisions;
- date/time and identifier representations;
- HTTP status and public error-code summary;
- exact-retry and ambiguous-outcome behavior;
- operation-to-PostgreSQL mapping summary;
- privacy and exposure decisions;
- requirements and workflows covered;
- decisions deferred to API-03 and later increments;
- deviations from this prompt, if any;
- unresolved decisions requiring approval, if any;
- Git working-tree summary;
- API-02 completion assessment.

End at this checkpoint:

> **API-02 approval is required before API-03 may begin. Approval authorizes only API-03 Flask Architecture, Configuration, and Test Strategy. It does not authorize Flask implementation, React work, integration work, or changes to the approved PostgreSQL layer.**

Do not begin API-03.

