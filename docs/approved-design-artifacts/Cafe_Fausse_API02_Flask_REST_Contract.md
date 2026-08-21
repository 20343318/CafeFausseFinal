# Cafe Fausse API-02 Flask REST Contract

**Document version:** 1.0.1<br>
**Date:** 2026-08-21  
**Roadmap increment:** API-02 - Flask REST Contract  
**Status:** Approved<br>
**Author:** Codex, prepared for Abdul  
**Approval record:** Approved by Abdul on 2026-08-21. This approval authorizes only API-03 - Flask Architecture, Configuration, and Test Strategy. It does not authorize Flask implementation, API-04 or later increments, React work, integration work, or PostgreSQL changes.

## 1. Executive summary

This document is the complete Version 1 HTTP/JSON compatibility boundary for the seven operations approved in API-01. It selects seven endpoints under `/api/v1`, direct operation-specific success bodies, one safe error envelope, exact request and response fields, strict JSON validation, unambiguous restaurant-local and canonical time forms, JavaScript-safe reservation references, and explicit retry and ambiguity behavior.

PostgreSQL remains authoritative for current hours and configuration, provisional availability, customer state, booking validation, concurrency, allocation, persistence, and exact retry. The API exposes no database object names, SQL outcomes, fingerprints, customer identifiers, free-table facts, or reservation-query capability. This increment creates no executable specification or application code.

No source contradiction or database change is required. API-02 can therefore complete as a design phase gate and pause for approval before API-03.

## 2. Authority and accepted baseline

Sources were applied in the prompt's required order:

1. `docs/SRS(1).pdf`, read in full;
2. `docs/Rubric(1).pdf`, read in full;
3. `docs/approved-design-artifacts/Cafe_Fausse_Project_Requirements_Addendum.md`, version 2.2.1;
4. DB-01 version 1.2.1, DB-02 version 1.2, DB-03 version 1.1, and DB-04 version 1.1;
5. the implemented DB-05 through DB-07 migrations, reports, verification evidence, and approval records;
6. `database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, approved and frozen version 1.0;
7. `docs/approved-design-artifacts/Cafe_Fausse_API01_Backend_Operation_Inventory.md`, approved version 1.0.1;
8. the least-to-most roadmap version 1.1.1, Project Requirements Baseline version 1.0, and `AGENTS.md`.

Accepted without reopening: PostgreSQL 18.3 and `pgcrypto`; six approved business tables; four authorized foundation reads; three production routines; `READ COMMITTED` booking; database-owned concurrency, allocation, and retry fingerprinting; no more than three complete attempts for SQLSTATE `55P03`, `40P01`, and `40001`; exact retry by ordinary booking facts; no direct application reads of reservations or assignments; and the documented general-allocation and coarse-lock performance limitations.

API-01 defines exactly OP-01 through OP-07. OP-05 obtains confirmation display spelling only through the approved post-success `customers` read by canonical email, projecting stored first name, optional middle initial, and last name. Request casing is never the confirmation authority.

## 3. Scope and API-03 boundary

API-02 defines wire behavior only. It does not select Flask packages, modules, classes, application factory, validation library, PostgreSQL driver, pool, transaction wrapper, logging implementation, CORS, deployment topology, environment variables, numeric application deadlines, or backoff constants. It produces no Python, SQL, React, OpenAPI, JSON Schema, Postman, fixtures, or executable tests.

API-03 will select architecture, configuration, connection ownership, driver behavior, numeric deadline/timeouts, retry placement, logging/redaction implementation, and test strategy without changing this wire contract. API-04 through API-09 implement and verify it. React uses approved mocks only after its own phase begins; live React-to-Flask integration remains in the integration phase.

## 4. Initial repository verification

| Check | Evidence and result |
|---|---|
| Initial worktree | `git status --short --branch` returned only `## main...origin/main`; no pre-existing user change existed. |
| Instructions | Repository-root `AGENTS.md` was read; no more-specific applicable instruction was found. |
| Required artifacts | All authoritative paths listed in Section 2 exist with the stated versions. |
| API-01 approval | API-01 v1.0.1 records approval by Abdul on 2026-08-21 and authorizes only API-02. |
| API-01 integrity | It still defines OP-01 through OP-07 and the deterministic OP-05 post-success stored-name source. |
| DB-07 gate | `database/DB07_VERIFICATION_REPORT.md` records Hard Gate 1 approval by Abdul on 2026-08-20. |
| Frozen contract | `database/POSTGRESQL_CONTRACT_FOR_FLASK.md` is version 1.0, approved on 2026-08-20, and frozen. |
| Implementation match | Migrations 007-009 implement the three frozen signatures, outputs, outcomes, and grants; migrations 004 and 009 preserve the documented read/execute boundary. |
| Runtime privilege | `cafe_fausse_app` may read `customers`, `reservation_configuration`, `restaurant_operating_hours`, and `restaurant_tables`, and execute only the three production routines. Reservation/assignment reads, direct writes, sequences, DDL, helpers, writers, and test seams are denied. |
| Backend/frontend state | `backend/` and `frontend/` exist and contain no implementation. |
| Roadmap boundary | API-02 selects the REST contract; API-03 alone selects Flask architecture and test strategy after approval. |

No overlapping change, missing approval, implementation mismatch, privilege gap, or required PostgreSQL revision was found.

## 5. API-wide conventions

### 5.1 Versioning and naming

- `/api/v1` is the major compatibility prefix for every Version 1 endpoint, including health probes. A breaking removal, rename, type change, enum semantic change, or status-code change requires a new major path.
- Paths are lowercase kebab-case. Ordinary concepts use resource-oriented nouns; privacy-sensitive calculations use a `-queries` noun because they require a body but do not create business data.
- JSON properties use lower snake_case. Enum values and public error codes use lower snake_case. Boolean names describe the positive condition.
- Arrays use plural nouns and preserve the ordering specified by their schema.
- Dates end in `_date`; recurring local times end in `_at_local`; local date-times end in `_at_local`; canonical instants use `_at`; minute offsets end in `_minutes`.
- Public identifiers that originate as PostgreSQL `BIGINT` are decimal JSON strings. Bounded business quantities remain JSON integers. No customer identifier or fingerprint is public.
- Request fields not defined for an endpoint are rejected. Response consumers must ignore unknown response properties, but must not assume unknown enum values are meaningful; adding an enum value requires a compatible contract revision or a new major version.
- Omitted optional properties and explicit JSON `null` are not interchangeable. Unless a schema explicitly says nullable, `null` is invalid. Empty strings are invalid for every request string.

### 5.2 Media type and body rules

- Every response, including errors, uses `Content-Type: application/json; charset=utf-8`.
- Every `POST` endpoint requires a UTF-8 JSON object and `Content-Type: application/json`. Media-type parameters such as `charset=utf-8` are allowed. Other media types return `415 unsupported_media_type`.
- `GET` endpoints have no request body. OP-02 uses only its two documented query parameters; the other `GET` endpoints accept no query parameters.
- A missing required JSON body returns `400 request_body_required`; malformed JSON, a non-object top level, or a detectable duplicate object member returns `400 invalid_json`.
- Unknown or server-controlled request fields return `400 invalid_request`. This includes customer/reservation IDs, confirmation references, fingerprints, idempotency keys, end time, duration, table facts, capacity/configuration, availability assertions, or newsletter-history/current-state assertions.
- JSON numbers must be finite grammar-valid JSON numbers. Bounded integer fields reject strings, Booleans, fractions, exponent forms that do not denote an exact integer, NaN, and Infinity. No string-to-number or string-to-Boolean coercion occurs.
- Syntax and cross-field errors return `422 validation_failed` with safe field details. All validation is repeated authoritatively by Flask; current booking rules are then revalidated by PostgreSQL.

### 5.3 Success and error bodies

Successful responses use direct operation-specific bodies. There is no generic `data`, metadata, timestamp, request ID, link, or pagination wrapper because none has an approved consumer.

Every error uses:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "One or more fields need attention.",
    "retryable": false,
    "outcome_unknown": false,
    "fields": [
      {
        "field": "party_size",
        "code": "out_of_range",
        "message": "Party size is outside the current allowed range."
      }
    ]
  }
}
```

`code`, `message`, `retryable`, and `outcome_unknown` are always present and non-null. `fields` is present only for caller-correctable request validation and is a nonempty array. `retryable:true` means resubmitting the same complete request, unchanged, is an appropriate recovery action; it does not merely mean that some different request could be attempted. `retryable:false` means identical resubmission is not the prescribed recovery, including when the caller must correct fields, refresh state, or choose another slot. Clients branch on `code`, `retryable`, `outcome_unknown`, and field `code`, never on message text. Messages are nontechnical and may be revised without changing meaning. No correlation value is exposed in Version 1.

## 6. Endpoint catalogue and selection rationale

| API-01 | Method and path | Inputs | Success | Repeat/cache/exposure rationale |
|---|---|---|---|---|
| OP-01 | `GET /api/v1/reservation-context` | None | `200` | HTTP-safe, side-effect free, repeatable snapshot. Public workflow endpoint. Not authoritative when cached; Version 1 requires no-store semantics. |
| OP-02 | `GET /api/v1/reservation-availability` | Query: `local_date`, `party_size` | `200` | HTTP-safe calculation. Inputs contain no PII and are suitable for the query string. Repeatable but snapshots can differ; no-store and never a hold. |
| OP-03 | `POST /api/v1/newsletter-status-queries` | JSON identity body | `200` | Side-effect free at the application level, but POST keeps PII out of URLs, history, query logs, and cache keys. Identical repetition is safe. No-store. |
| OP-04 | `POST /api/v1/newsletter-preferences` | JSON identity plus final Boolean | `200` | The body identifies the customer and desired final state, so POST accurately targets the preference operation without pretending the URI identifies one customer's resource. Repeating the same request is application-level idempotent. PII stays out of the URI. No-store. |
| OP-05 | `POST /api/v1/reservations` | JSON ordinary booking facts | `201` new; `200` exact retry | POST creates a reservation when none exists. Exact retry reconstructs an existing result and is not another creation. No client key. No-store. |
| OP-06 | `GET /api/v1/health/liveness` | None | `200` | Process-local, HTTP-safe, repeatable infrastructure endpoint. Excluded from customer navigation. No database claim or diagnostics. |
| OP-07 | `GET /api/v1/health/readiness` | None | `200` ready; `503` not ready | Read-only infrastructure endpoint, excluded from customer navigation. Minimal database-backed state, no DB-07 rerun or diagnostics. |

`POST` for OP-03 is chosen over `GET` solely to prevent identity values from entering URLs. OP-04 also uses body-based POST because identity is absent from the URI; application-level final-state semantics, rather than the HTTP method itself, make identical repetition safe. A separate subscribe/unsubscribe action resource is rejected because OP-04 sets one current Boolean. A reservation retry or lookup route is rejected because OP-05 exact retry uses the same ordinary request. Health paths remain operation-oriented because resource CRUD would be misleading.

All endpoints are unauthenticated in Version 1. OP-01 through OP-05 are public workflows. OP-06 and OP-07 are infrastructure-oriented and should not appear in customer navigation or public product documentation; deployment-level reachability restrictions are deferred and do not alter these bodies.

## 7. Shared customer input contract

| Property | JSON type | Presence/null | Limit and accepted form | Normalization and meaning | Error/privacy |
|---|---|---|---|---|---|
| `first_name` | string | Required; non-null | 1-100 Unicode characters after normalization; at least one Unicode letter | Trim outer whitespace, collapse each internal whitespace run to one space, preserve display spelling/punctuation/accents; compare case-insensitively | `validation_failed`; PII, request-only except composed confirmation name |
| `middle_initial` | string | Optional; if present non-null | One Unicode alphabetic character, optionally followed by one period; maximum input length 2 | Trim, remove optional period, uppercase to one character. Omission preserves stored state or matches either state in lookup | Empty/`null` invalid; PII |
| `last_name` | string | Required; non-null | Same as `first_name` | Same as `first_name` | `validation_failed`; PII |
| `email` | string | Required; non-null | Maximum 254 characters after trim; one RFC 5322 addr-spec without display name, comments, surrounding whitespace, or domain literal | Trim and lowercase the entire accepted address; DNS ownership/delivery is not verified | PII, request-only; never returned |
| `confirmation_email` | string | Required; non-null | Same syntax/length as `email` | Normalize identically and require equality to normalized `email`; discard before database access | Secret-like transient PII; never returned, logged, cached, or persisted |
| `phone` | string | OP-05 only; optional; if present non-null | Maximum 32 characters; only digits, spaces, `+`, `(`, `)`, `-`, `.`; 7-15 digits | Trim outer whitespace; preserve accepted display spelling; compare transient digit-only form | Empty/`null` invalid; PII; never returned |

Name character limits count Unicode code points after trimming/collapse. The contract does not impose a display-changing Unicode normalization form. Email accepts an ordinary addr-spec: one nonempty local part and one nonempty domain separated by one `@`; the local part uses RFC dot-atom characters with no leading, trailing, or consecutive dot; domain labels contain letters, digits, or interior hyphens and are dot-separated. Quoted local parts, comments, whitespace, address literals, and display-name wrappers are rejected. API-03 may select an implementation library only if it enforces this profile.

Omission is the sole public representation of “not supplied” for `middle_initial` and `phone`. `null` and `""` never mean clear, preserve, or no change. A supplied middle initial may populate a stored blank only in OP-04/OP-05; a populated conflict is rejected. A supplied phone may populate a stored blank only on a newly successful OP-05 booking; a differing populated phone is preserved and produces a success notice. Neither field is an identity key. No customer ID is accepted or returned.

## 8. Date, time, identifier, and number contract

### 8.1 Temporal representations

| Category | Wire form | Rules |
|---|---|---|
| Restaurant-local date | `YYYY-MM-DD` | Exact proleptic-Gregorian calendar date; no time or zone. OP-01 bounds are inclusive. |
| Recurring local time | `HH:MM:SS` | 24-hour time, seconds required and `00` in Version 1; no date, offset, or fractions. |
| Selected local start | RFC 3339 date-time with numeric offset, e.g. `2026-09-12T17:00:00-04:00` | Seconds required; fractional seconds and `Z` prohibited. It carries restaurant wall time and the selected offset without browser/host reinterpretation. |
| Explicit selected offset | `utc_offset_minutes` integer | Local time equals UTC plus this value. Range `-840` through `840`; it must equal the offset embedded in `starts_at_local` and a valid mapping in the current restaurant timezone. |
| Canonical instant | `YYYY-MM-DDTHH:MM:SSZ` | UTC `Z`, seconds required, no fractional seconds. |
| Restaurant-local response date-time | RFC 3339 date-time with numeric offset | Seconds required, no fractions; produced by the server from the authoritative instant and restaurant timezone. |
| Timezone | IANA identifier string | Current database value, initially `America/New_York`; never a browser or Flask-host timezone. |

OP-02 returns `starts_at_local` and `utc_offset_minutes`; OP-05 requires the client to send those exact selected facts. Flask validates their internal agreement and passes the local wall value plus offset to PostgreSQL. React does not invent a start, compute an offset/end/duration, or convert the local display through the browser timezone.

Nonexistent local starts return `422 validation_failed` with field code `nonexistent_local_time`. Ambiguous local starts return field code `ambiguous_local_time`; an offset mismatch returns `utc_offset_mismatch`. The database remains authoritative. Reservations use half-open intervals `[starts_at, ends_at)`, so a start equal to a prior end is back-to-back and not overlapping.

### 8.2 Numeric and identifier types

| Value | JSON type and range |
|---|---|
| `reservation_reference` | Decimal string matching `[1-9][0-9]*`, value at most `9223372036854775807`; never a JSON number |
| `iso_weekday` | Integer 1-7 |
| `party_size` | Integer >=1 and <= current `maximum_party_size`; protocol ceiling `2147483647` |
| `table_number` | Integer 1-32767; assigned values are current PostgreSQL table numbers |
| `start_interval_minutes` | Integer enum 15, 30, 60 |
| `reservation_duration_minutes` | Integer enum 60, 90, 120 |
| `advance_window_days` | Integer 1-365 |
| `same_day_lead_minutes` | Integer 0-1440 |
| `utc_offset_minutes` | Integer -840 through 840 and valid for the selected instant/timezone |
| All flags | JSON Boolean only; strings and integers are rejected |

## 9. Endpoint request and success schemas

### 9.1 OP-01 current reservation context

`GET /api/v1/reservation-context` accepts no body or query parameters.

| Response property | Type | Required/null | Meaning/source |
|---|---|---|---|
| `restaurant` | object | Required/non-null | Fixed SRS contact facts. |
| `restaurant.address` | string | Required/non-null | `1234 Culinary Ave, Suite 100, Washington, DC 20002`. |
| `restaurant.phone` | string | Required/non-null | `(202) 555-4567`. |
| `restaurant_timezone` | string/IANA | Required/non-null | Current PostgreSQL configuration. |
| `weekday_hours` | array of 7 objects | Required/non-null | Exactly weekdays 1-7 in ascending order. |
| `weekday_hours[].iso_weekday` | integer 1-7 | Required/non-null | ISO Monday=1 through Sunday=7. |
| `weekday_hours[].opens_at_local` | local time | Required/non-null | Current recurring opening. |
| `weekday_hours[].closes_at_local` | local time | Required/non-null | Current recurring closing. |
| `reservation_policy` | object | Required/non-null | Current public scalar rules. |
| `reservation_policy.start_interval_minutes` | integer enum | Required/non-null | Current aligned-start interval. |
| `reservation_policy.reservation_duration_minutes` | integer enum | Required/non-null | Current new-booking duration. |
| `reservation_policy.advance_window_days` | integer 1-365 | Required/non-null | Current inclusive window size. |
| `reservation_policy.same_day_lead_minutes` | integer 0-1440 | Required/non-null | Current same-day lead. |
| `reservable_date_range` | object | Required/non-null | Database-clock-derived restaurant-local bounds. |
| `reservable_date_range.minimum_local_date` | local date | Required/non-null | Inclusive current restaurant-local date. |
| `reservable_date_range.maximum_local_date` | local date | Required/non-null | Inclusive configured maximum. |
| `maximum_party_size` | integer >=1 | Required/non-null | Sum of current positive capacities across exactly 30 tables. |

Total capacity is not separately exposed because it equals the required maximum party size. Table rows, capacities, and count are withheld. If configuration, timezone, all seven schedules, or exactly 30 positive-capacity rows are unusable, the endpoint returns `503 service_unavailable`; it never fabricates SRS defaults.

### 9.2 OP-02 daily provisional availability

`GET /api/v1/reservation-availability?local_date=2026-09-12&party_size=4`

The query must contain exactly one `local_date` and one `party_size`; repeated, missing, blank, or extra parameters are invalid. `party_size` is base-10 digits with no sign, leading plus, decimal, exponent, or surrounding whitespace, then parsed as the bounded integer above.

| Response property | Type | Required/null | Meaning |
|---|---|---|---|
| `local_date` | local date | Required/non-null | Echo of the validated requested restaurant-local date. |
| `party_size` | integer | Required/non-null | Echo of validated party size. |
| `restaurant_timezone` | IANA string | Required/non-null | Timezone used for the snapshot. |
| `provisional` | Boolean, always `true` | Required/non-null | Explicitly means no hold or guarantee. |
| `slots` | array | Required/non-null | Every legitimate aligned start, including unavailable entries, ordered by canonical `starts_at` ascending. |
| `slots[].starts_at_local` | offset local date-time | Required/non-null | Restaurant-local proposed start. |
| `slots[].utc_offset_minutes` | integer | Required/non-null | Authoritative offset to echo in OP-05. |
| `slots[].starts_at` | canonical instant | Required/non-null | Proposed canonical start. |
| `slots[].ends_at_local` | offset local date-time | Required/non-null | Restaurant-local proposed end. |
| `slots[].ends_at` | canonical instant | Required/non-null | Proposed canonical end. |
| `slots[].available` | Boolean | Required/non-null | Provisional capacity-sufficient state at snapshot time. |

A valid day with all slots unavailable returns `200` with every slot and all flags false. A valid, usable one-period weekday that yields no legitimate starts returns `200` with `slots: []`; it is distinct from request/configuration failure. No customer, reservation, free/assigned table, combination, capacity, ranking, random, or fingerprint fact appears.

### 9.3 OP-03 newsletter status lookup

`POST /api/v1/newsletter-status-queries` accepts exactly the shared identity fields except `phone`.

| Response property | Type | Presence/null | Meaning |
|---|---|---|---|
| `status` | enum `matched`, `not_found` | Required/non-null | Exact identity match or no customer for canonical email. |
| `subscribed` | Boolean | Required only when `status=matched`; non-null | Current authoritative preference snapshot. Omitted for `not_found`. |

Identity mismatch and middle conflict use errors, not success bodies. Technical indeterminacy is `503 newsletter_status_indeterminate`, `retryable:true`, `outcome_unknown:false`; because this operation cannot commit, “indeterminate” means the current state could not be read. Booking may continue only with `newsletter_action:"no_change"` and lookup may be retried.

Distinguishing `not_found` from an existing-email mismatch creates limited account-discovery risk. It is retained because PRA-019/PRA-025 require distinct workflow behavior. The request requires full name plus matching confirmation email, returns no profile facts, proves no identity ownership, is never cached, and must not be presented as account verification.

### 9.4 OP-04 set newsletter preference

`POST /api/v1/newsletter-preferences` accepts the shared identity fields except `phone`, plus:

| Property | Type | Presence/null | Meaning |
|---|---|---|---|
| `subscribed` | Boolean | Required/non-null | Desired final authoritative state. |

Success body:

| Property | Type | Required/null | Meaning |
|---|---|---|---|
| `result` | enum `set`, `no_customer_no_change` | Required/non-null | `set` covers new, changed, and already-current state; `no_customer_no_change` is an unknown identity set to false with no row created. |
| `subscribed` | Boolean | Required/non-null | Final authoritative state (`false` for `no_customer_no_change`). |

All success variants return `200`. The frozen routine does not expose whether `set` created, changed, or idempotently retained a row; the public contract deliberately does not invent that discriminator. New subscribed, existing subscribed/unsubscribed, and same-state repetition are all fully represented by final authoritative state. An unknown identity set to false is distinguishable because the routine explicitly returns that outcome.

An unknown mutation result returns `503 newsletter_preference_outcome_unknown` with both flags true. The caller safely resubmits the same complete POST body; application-level final-state semantics make that recovery idempotent.

### 9.5 OP-05 create or reconstruct reservation

`POST /api/v1/reservations` accepts exactly the shared identity fields, optional `phone`, and:

| Property | Type | Presence/null | Meaning |
|---|---|---|---|
| `starts_at_local` | offset local date-time | Required/non-null | Selected OP-02 restaurant-local start including numeric offset. |
| `utc_offset_minutes` | integer -840..840 | Required/non-null | Must agree with the date-time suffix and configured timezone mapping. |
| `party_size` | integer | Required/non-null | Requested guests; current PostgreSQL rules remain authoritative. |
| `newsletter_action` | enum `subscribe`, `unsubscribe`, `no_change` | Required/non-null | Booking-linked intent. Use `no_change` after indeterminate lookup or when no reliable preference choice exists. |

Customer ID, reservation reference, fingerprint/key, end/duration, timezone, table data, availability state, and configuration are forbidden.

Success body:

| Property | Type | Required/null | Meaning |
|---|---|---|---|
| `booking_result` | enum `created`, `exact_retry` | Required/non-null | Whether this response confirms a new commit or reconstructs an existing exact reservation. |
| `confirmation` | object | Required/non-null | Complete authoritative confirmation. |
| `confirmation.reservation_reference` | decimal string | Required/non-null | JavaScript-safe stable PostgreSQL reservation ID. |
| `confirmation.customer_name` | string | Required/non-null | Display name composed from stored first/optional middle/last values read after success. |
| `confirmation.starts_at_local` | offset local date-time | Required/non-null | Restaurant-local committed start. |
| `confirmation.ends_at_local` | offset local date-time | Required/non-null | Restaurant-local committed exclusive end. |
| `confirmation.starts_at` | canonical instant | Required/non-null | Committed start instant. |
| `confirmation.ends_at` | canonical instant | Required/non-null | Committed end instant. |
| `confirmation.party_size` | integer | Required/non-null | Committed immutable party size. |
| `confirmation.assigned_table_numbers` | array of integers | Required/non-null/nonempty | Every committed table, strictly ascending with no duplicates. |
| `confirmation.newsletter_subscribed` | Boolean | Required/non-null | Current authoritative state returned by booking. |
| `confirmation.restaurant` | object | Required/non-null | Fixed SRS contact facts. |
| `confirmation.restaurant.address` | string | Required/non-null | Fixed SRS address. |
| `confirmation.restaurant.phone` | string | Required/non-null | Fixed SRS phone. |
| `phone_notice` | object | Present only for a new booking whose differing stored phone was preserved | Safe notice; absent otherwise, including exact retry. |
| `phone_notice.code` | enum `stored_phone_preserved` | Required when object appears | Stable branch value. |
| `phone_notice.message` | string | Required when object appears | Nontechnical notice that supplied phone was not saved; never reveals stored phone. |

Database `booked` and `booked_phone_notice` map to `201` and `booking_result:"created"`; the latter includes `phone_notice`. Database `exact_retry` maps to `200` and `booking_result:"exact_retry"`. Exact retry is success, uses the original reservation/assignments and current newsletter state, performs no contact/newsletter mutation, and never includes a phone notice replay.

After the booking transaction has committed successfully, or after an exact retry has established that the reservation already exists, Flask performs the separate authorized customer-name read needed to assemble `confirmation.customer_name`. If that read fails or cannot return the required stored name, the API returns `503 reservation_confirmation_unavailable` with `retryable:true` and `outcome_unknown:false`. The reservation is known to exist; only the complete confirmation is unavailable. The caller resubmits the same ordinary booking request, which safely reaches exact retry and reconstructs the confirmation when the read succeeds. This result is distinct from `reservation_outcome_unknown`, where the booking commit itself is uncertain.

The response contains no email, confirmation email, phone value, customer ID, fingerprint/version, database outcome/detail, free/candidate/capacity facts, or delivery field. Its presence is the display confirmation; it does not claim email or SMS was sent.

### 9.6 OP-06 and OP-07 health

`GET /api/v1/health/liveness` returns `200`:

```json
{"status":"live"}
```

It performs no database access and makes no readiness claim.

`GET /api/v1/health/readiness` returns `200`:

```json
{"status":"ready"}
```

When the approved PostgreSQL target, extension/object privileges, or foundation facts are unavailable or unusable, readiness returns `503 service_not_ready` in the common error envelope. It exposes no failed check, server version, extension, schema, role, connection, configuration, row count, SQL, or diagnostic. It performs only the API-01 approved read-only check, never migrations, reset, seed, `verify.ps1`, performance work, test booking, or a mutating routine.

## 10. Public status and error catalogue

| Public code/result | HTTP | Envelope | Retryable / unknown | Applies and safe caller action | Internal source; logging class |
|---|---:|---|---|---|---|
| Direct read/set success | 200 | No | - / - | Render current result; repeat if a newer snapshot is needed | Successful OP-01/02/03/04/06/07 or OP-04 `subscribed`, `unsubscribed`, `no_customer_no_change`; routine outcome is not logged as an error |
| New reservation | 201 | No | - / - | Render confirmation | `booked` or `booked_phone_notice`; business success |
| Exact retry | 200 | No | - / - | Render reconstructed confirmation | `exact_retry`; business success-existing |
| `invalid_json` | 400 | Yes | false / false | Correct malformed/non-object/duplicate-member JSON | Parser/request-shape rejection; ordinary validation, no technical details |
| `request_body_required` | 400 | Yes | false / false | Send the required object body | Missing OP-03/04/05 body; ordinary validation |
| `invalid_request` | 400 | Yes | false / false | Remove unknown/forbidden/duplicate query fields or correct request shape | Flask request-shape rejection; ordinary validation |
| `route_not_found` | 404 | Yes | false / false | Correct the path | Router; coarse access log only |
| `method_not_allowed` | 405 | Yes | false / false | Use documented method | Router; include an appropriate `Allow` header later without changing JSON |
| `unsupported_media_type` | 415 | Yes | false / false | Send `application/json` | Request media type; ordinary validation |
| `validation_failed` | 422 | Yes | false / false | Correct listed fields and resubmit | Flask rules; availability `invalid_request`; booking `invalid_request` and safe validation details; ordinary validation |
| `customer_identity_conflict` | 409 | Yes | false / false | Correct identity entries; do not infer stored values | Database `customer_identity_mismatch`; business conflict, PII-redacted |
| `middle_initial_conflict` | 409 | Yes | false / false | Correct or omit the submitted initial where valid | Database `middle_initial_conflict`; business conflict, stored value withheld |
| `reservation_overlap` | 409 | Yes | false / false | Choose a nonoverlapping time | Database `same_customer_overlap`; business conflict, existing reservation withheld |
| `reservation_unavailable` | 409 | Yes | false / false | Refresh OP-02 and choose another slot; do not repeat the identical booking request | Database `unavailable`, including no capacity-sufficient combination or boundary crossed; business unavailable, internals withheld |
| `newsletter_status_indeterminate` | 503 | Yes | true / false | Retry lookup, or book with `no_change` | OP-03 database/timeout failure; operational error, PII-redacted |
| `temporary_failure` | 503 | Yes | true / false | Retry the complete request later | Known rollback/no commit: database unavailable, known timeout, or exhausted bounded `55P03`/`40P01`/`40001`; redacted technical log |
| `newsletter_preference_outcome_unknown` | 503 | Yes | true / true | Resubmit the identical POST body | Connection/result loss where OP-04 may have committed; ambiguity log, PII-redacted |
| `reservation_confirmation_unavailable` | 503 | Yes | true / false | Resubmit the identical ordinary booking request to reconstruct the known reservation confirmation | Booking commit or exact retry is known; separate post-commit stored-name read failed; operational error, PII-redacted |
| `reservation_outcome_unknown` | 503 | Yes | true / true | Resubmit the identical ordinary POST body; it may create or exact-retry | Connection/result loss where OP-05 may have committed; ambiguity log, PII-redacted |
| `service_unavailable` | 503 | Yes | true / false | Retry later; caller cannot repair service configuration | OP-01/02/05 invalid database configuration or unusable foundation; internal detail withheld |
| `service_not_ready` | 503 | Yes | true / false | Infrastructure retries readiness later | OP-07 dependency/foundation check; only coarse internal failed-check logging |
| `internal_error` | 500 | Yes | false / false | Show a generic failure; a mutation with uncertainty must use an outcome-unknown code instead | Unexpected failure with known noncommit/no mutation; detailed but redacted internal log |

`400` is limited to syntax and request shape. `422` means syntactically valid input failed caller-visible field or cross-field validation. `409` means a known current business conflict or authoritative capacity loss. `503` means dependency/readiness/transient failure or explicitly unknown mutation result. `500` is reserved for an unexpected known-outcome server defect. `204` is not used because every successful mutation must return authoritative state. `Retry-After` is not defined because Version 1 has no queue or reliable recovery time.

| Frozen routine stable outcome | One public result |
|---|---|
| Availability `slots` | `200` AvailabilityResult, including an empty slot array when legitimate |
| Availability `invalid_request` | `422 validation_failed` |
| Availability `invalid_database_configuration` | `503 service_unavailable` |
| Preference `subscribed`, `unsubscribed` | `200 {result:"set", subscribed:<authoritative Boolean>}` |
| Preference `no_customer_no_change` | `200 {result:"no_customer_no_change", subscribed:false}` |
| Preference `invalid_request` | `422 validation_failed` |
| Preference `customer_identity_mismatch` | `409 customer_identity_conflict` |
| Preference `middle_initial_conflict` | `409 middle_initial_conflict` |
| Booking `booked` | `201 booking_result:"created"` |
| Booking `booked_phone_notice` | `201 booking_result:"created"` plus PhoneNotice |
| Booking `exact_retry` | `200 booking_result:"exact_retry"` |
| Successful booking/exact retry followed by failed stored-name read | `503 reservation_confirmation_unavailable`; reservation existence is known |
| Booking `same_customer_overlap` | `409 reservation_overlap` |
| Booking `customer_identity_mismatch` | `409 customer_identity_conflict` |
| Booking `middle_initial_conflict` | `409 middle_initial_conflict` |
| Booking `unavailable` | `409 reservation_unavailable` |
| Booking `invalid_request` | `422 validation_failed` when caller-correctable, otherwise `503 service_unavailable` for a server-controlled inconsistency |
| Booking `invalid_database_configuration` | `503 service_unavailable` |

Database validation details map only to safe public field codes:

| Internal booking/availability detail | Public result |
|---|---|
| `date_or_party_size_out_of_range` | `422 validation_failed` on `local_date` and/or `party_size` |
| `invalid_normalized_input`, `duration_or_party_size_out_of_range` | `422 validation_failed` on the applicable caller field; server-controlled duration failure becomes `service_unavailable` |
| `nonexistent_local_start` | `422`, `starts_at_local/nonexistent_local_time` |
| `ambiguous_local_start` | `422`, `starts_at_local/ambiguous_local_time` |
| `utc_offset_mismatch` | `422`, `utc_offset_minutes/utc_offset_mismatch` |
| `date_outside_booking_window` | `422`, `starts_at_local/date_outside_booking_window` |
| `insufficient_same_day_lead` | `422`, `starts_at_local/insufficient_same_day_lead` |
| `start_before_opening`, `misaligned_start`, `end_after_closing` | `422`, `starts_at_local/invalid_reservation_time` |
| `no_capacity_sufficient_combination`, `time_boundary_crossed_during_booking` | `409 reservation_unavailable` |
| `requires_read_committed`, configuration/population details, `invalid_timezone` | `503 service_unavailable`; no detail leaks |

Every stable database outcome/detail therefore maps to one public result. Public bodies never repeat PostgreSQL literal names.

## 11. Retry, idempotency, timeout, and ambiguity semantics

- OP-01, OP-02, OP-03, OP-06, and OP-07 do not mutate state and are safely repeatable; a later snapshot may differ.
- OP-04 sets a final Boolean and is safely repeatable. A repeated success may not reveal whether the prior call committed, because the frozen routine exposes only final state.
- OP-05 accepts no idempotency key, confirmation reference, fingerprint, or retry endpoint. A client repeats the same normalized ordinary booking facts after `reservation_outcome_unknown`.
- If the prior OP-05 call committed, PostgreSQL returns `exact_retry`; if it rolled back, the repeated call is freshly evaluated and may create, conflict, or be unavailable. Exact retry does not replay phone, middle-initial, or newsletter mutation.
- After `reservation_confirmation_unavailable`, the reservation is known to exist and `outcome_unknown` is false. Repeating the identical OP-05 request is appropriate because exact retry reconstructs the reservation and permits another stored-name read.
- `reservation_unavailable` has `retryable:false`: repeating the identical booking request is not the recovery action. The client refreshes OP-02 and submits a different booking request only after selecting another available slot.
- The later Flask implementation may automatically retry only complete transactions that fail with the three frozen retryable SQLSTATE classes, no more than three total attempts within one overall deadline. It rolls back before each retry and re-reads current facts.
- A timeout or error with a known rollback uses `temporary_failure` and `outcome_unknown:false`. Any loss during a mutation where commit cannot be proven uses the operation-specific outcome-unknown code. An unknown outcome is never described as a definitive failure.
- API-03 selects numeric deadlines, driver classification, backoff/jitter values, and placement without altering these public signals.

## 12. Cache, privacy, exposure, and redaction rules

All Version 1 responses semantically require no-store behavior. API-03/04 will select exact headers consistent with that requirement. This avoids stale authority, shared-cache exposure, booking-confirmation storage, and probe caching. OP-01/02 could theoretically support short revalidation caching, but Version 1 deliberately prefers one uniform no-store rule; neither response is ever a booking guarantee.

Names, email, confirmation email, phone, booking facts, and newsletter state never appear in paths or queries. OP-02 query values are non-PII. Browser history therefore receives no personal or booking request body. Request and success/error bodies containing PII are not cache keys and must be redacted from technical logs. Confirmation email is never logged in any form. Public error fields name only caller-visible properties and rules.

Unauthenticated Version 1 access does not prove identity or ownership and grants no profile retrieval, reservation lookup/listing, cancellation, modification, rescheduling, table choice, administration, reset, verification, or diagnostics. OP-03 exposes only the workflow-minimum matched preference/no-customer distinction. Health bodies expose only `live`, `ready`, or a generic not-ready envelope.

## 13. Database-to-HTTP mapping

| Operation/endpoint | Authorized source and inputs | Internal output consumed | Public result | Withheld and boundary |
|---|---|---|---|---|
| OP-01 context | One read-only snapshot from `cafe_fausse.reservation_configuration`, all `cafe_fausse.restaurant_operating_hours`, aggregate `cafe_fausse.restaurant_tables`, and database clock | Five settings, seven rows, timezone, row count/capacity sum, local date bounds | Section 9.1 | No table rows/count/capacities or SQL. Side-effect free; connection loss is known nonmutation. |
| OP-02 availability | `cafe_fausse.provisional_availability(date, integer)` from validated `local_date`, `party_size` | `outcome`, `detail_code`, local/canonical start/end, provisional flag | Section 9.2 or mapped error | Outcome/detail, reservations, assignments, candidates, capacity withheld. One read-only statement; repeat after connection loss. |
| OP-03 lookup | Authorized `cafe_fausse.customers` read by canonical email, projecting first/middle/last and Boolean | Existence, safe name/middle comparison, current Boolean | `matched`/`not_found` or conflict/indeterminate | No stored values, email, phone, ID, reservations. One read-only snapshot. |
| OP-04 preference | `cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)` from normalized first, nullable middle, normalized last, canonical email, and `subscribed` | `outcome`, `newsletter_subscribed` | `set` or `no_customer_no_change`; mapped conflicts/errors | Confirmation email and database outcome withheld. One controlled transaction; bounded full-attempt retry; connection loss can be unknown. |
| OP-05 booking | `cafe_fausse.book_reservation(text,text,text,text,text,timestamp without time zone,smallint,integer,text)` at `READ COMMITTED`; after its commit is known, and only for `booked`, `booked_phone_notice`, or `exact_retry`, read `cafe_fausse.customers` by canonical email for stored first/middle/last | Stable outcome/detail; reservation ID; canonical interval; party; sorted tables; newsletter; phone notice; internal fingerprint fields; then stored display-name parts | `201 created`, `200 exact_retry`, notice, mapped booking error, or `503 reservation_confirmation_unavailable` if the separate name read fails | Fingerprint, outcome/detail, customer ID/contact, free/candidate/capacity facts withheld. Routine call is one transaction; name read is separate and read-only after known success. A failed name read leaves reservation existence known and supports identical resubmission; unknown booking commit remains `reservation_outcome_unknown`. No reservation/assignment query. |
| OP-06 liveness | No PostgreSQL | Process can answer | `200 {status:"live"}` | No diagnostics or dependency claim. |
| OP-07 readiness | Approved read-only connection/catalog/privilege and four-foundation checks | Ready/not-ready internal Boolean | `200 ready` or generic `503 service_not_ready` | No server/schema/extension/role/version/check detail. No mutation or full verifier. |

Flask never derives free tables, allocates, compares fingerprints, adjudicates overlap, directly writes business tables, or directly reads reservations/assignments. No new PostgreSQL access path is introduced.

## 14. Non-executable JSON examples

Examples are illustrative contract data, not fixtures or executable tests. All personal values are fictitious.

### 14.1 Current context

```json
{
  "restaurant": {
    "address": "1234 Culinary Ave, Suite 100, Washington, DC 20002",
    "phone": "(202) 555-4567"
  },
  "restaurant_timezone": "America/New_York",
  "weekday_hours": [
    {"iso_weekday": 1, "opens_at_local": "17:00:00", "closes_at_local": "23:00:00"},
    {"iso_weekday": 2, "opens_at_local": "17:00:00", "closes_at_local": "23:00:00"},
    {"iso_weekday": 3, "opens_at_local": "17:00:00", "closes_at_local": "23:00:00"},
    {"iso_weekday": 4, "opens_at_local": "17:00:00", "closes_at_local": "23:00:00"},
    {"iso_weekday": 5, "opens_at_local": "17:00:00", "closes_at_local": "23:00:00"},
    {"iso_weekday": 6, "opens_at_local": "17:00:00", "closes_at_local": "23:00:00"},
    {"iso_weekday": 7, "opens_at_local": "17:00:00", "closes_at_local": "21:00:00"}
  ],
  "reservation_policy": {
    "start_interval_minutes": 30,
    "reservation_duration_minutes": 90,
    "advance_window_days": 60,
    "same_day_lead_minutes": 120
  },
  "reservable_date_range": {
    "minimum_local_date": "2026-08-21",
    "maximum_local_date": "2026-10-20"
  },
  "maximum_party_size": 120
}
```

### 14.2 Partial daily availability

The ten rows below are the complete Saturday schedule for the illustrated seed settings, not a truncated sample.

```json
{
  "local_date": "2026-09-12",
  "party_size": 4,
  "restaurant_timezone": "America/New_York",
  "provisional": true,
  "slots": [
    {"starts_at_local":"2026-09-12T17:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-12T21:00:00Z","ends_at_local":"2026-09-12T18:30:00-04:00","ends_at":"2026-09-12T22:30:00Z","available":true},
    {"starts_at_local":"2026-09-12T17:30:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-12T21:30:00Z","ends_at_local":"2026-09-12T19:00:00-04:00","ends_at":"2026-09-12T23:00:00Z","available":true},
    {"starts_at_local":"2026-09-12T18:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-12T22:00:00Z","ends_at_local":"2026-09-12T19:30:00-04:00","ends_at":"2026-09-12T23:30:00Z","available":false},
    {"starts_at_local":"2026-09-12T18:30:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-12T22:30:00Z","ends_at_local":"2026-09-12T20:00:00-04:00","ends_at":"2026-09-13T00:00:00Z","available":false},
    {"starts_at_local":"2026-09-12T19:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-12T23:00:00Z","ends_at_local":"2026-09-12T20:30:00-04:00","ends_at":"2026-09-13T00:30:00Z","available":true},
    {"starts_at_local":"2026-09-12T19:30:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-12T23:30:00Z","ends_at_local":"2026-09-12T21:00:00-04:00","ends_at":"2026-09-13T01:00:00Z","available":true},
    {"starts_at_local":"2026-09-12T20:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T00:00:00Z","ends_at_local":"2026-09-12T21:30:00-04:00","ends_at":"2026-09-13T01:30:00Z","available":true},
    {"starts_at_local":"2026-09-12T20:30:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T00:30:00Z","ends_at_local":"2026-09-12T22:00:00-04:00","ends_at":"2026-09-13T02:00:00Z","available":false},
    {"starts_at_local":"2026-09-12T21:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T01:00:00Z","ends_at_local":"2026-09-12T22:30:00-04:00","ends_at":"2026-09-13T02:30:00Z","available":true},
    {"starts_at_local":"2026-09-12T21:30:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T01:30:00Z","ends_at_local":"2026-09-12T23:00:00-04:00","ends_at":"2026-09-13T03:00:00Z","available":true}
  ]
}
```

### 14.3 Valid Sunday with every slot unavailable

```json
{
  "local_date": "2026-09-13",
  "party_size": 120,
  "restaurant_timezone": "America/New_York",
  "provisional": true,
  "slots": [
    {"starts_at_local":"2026-09-13T17:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T21:00:00Z","ends_at_local":"2026-09-13T18:30:00-04:00","ends_at":"2026-09-13T22:30:00Z","available":false},
    {"starts_at_local":"2026-09-13T17:30:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T21:30:00Z","ends_at_local":"2026-09-13T19:00:00-04:00","ends_at":"2026-09-13T23:00:00Z","available":false},
    {"starts_at_local":"2026-09-13T18:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T22:00:00Z","ends_at_local":"2026-09-13T19:30:00-04:00","ends_at":"2026-09-13T23:30:00Z","available":false},
    {"starts_at_local":"2026-09-13T18:30:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T22:30:00Z","ends_at_local":"2026-09-13T20:00:00-04:00","ends_at":"2026-09-14T00:00:00Z","available":false},
    {"starts_at_local":"2026-09-13T19:00:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T23:00:00Z","ends_at_local":"2026-09-13T20:30:00-04:00","ends_at":"2026-09-14T00:30:00Z","available":false},
    {"starts_at_local":"2026-09-13T19:30:00-04:00","utc_offset_minutes":-240,"starts_at":"2026-09-13T23:30:00Z","ends_at_local":"2026-09-13T21:00:00-04:00","ends_at":"2026-09-14T01:00:00Z","available":false}
  ]
}
```

### 14.4 Newsletter lookup variants

Request:

```json
{"first_name":"Ada","middle_initial":"m.","last_name":"Rivera","email":"ADA.RIVERA@EXAMPLE.COM","confirmation_email":"ada.rivera@example.com"}
```

Subscribed and unsubscribed:

```json
{"status":"matched","subscribed":true}
```

```json
{"status":"matched","subscribed":false}
```

No customer:

```json
{"status":"not_found"}
```

Mismatch and indeterminate:

```json
{"error":{"code":"customer_identity_conflict","message":"The submitted identity details do not match.","retryable":false,"outcome_unknown":false}}
```

```json
{"error":{"code":"newsletter_status_indeterminate","message":"Newsletter status could not be checked right now. You may retry, or continue a booking without changing it.","retryable":true,"outcome_unknown":false}}
```

### 14.5 Newsletter preference variants

Request:

```json
{"first_name":"Ada","middle_initial":"M","last_name":"Rivera","email":"ada.rivera@example.com","confirmation_email":"ada.rivera@example.com","subscribed":true}
```

New subscribed, existing subscribed, and idempotent subscribed all return:

```json
{"result":"set","subscribed":true}
```

Existing unsubscribed returns:

```json
{"result":"set","subscribed":false}
```

New-unselected/no-customer returns:

```json
{"result":"no_customer_no_change","subscribed":false}
```

Conflict:

```json
{"error":{"code":"middle_initial_conflict","message":"The submitted middle initial conflicts with the existing identity details.","retryable":false,"outcome_unknown":false}}
```

### 14.6 Reservation request and success variants

Request:

```json
{
  "first_name": "Ada",
  "middle_initial": "M.",
  "last_name": "Rivera",
  "email": "ada.rivera@example.com",
  "confirmation_email": "ada.rivera@example.com",
  "phone": "+1 (202) 555-0198",
  "starts_at_local": "2026-09-12T17:00:00-04:00",
  "utc_offset_minutes": -240,
  "party_size": 4,
  "newsletter_action": "subscribe"
}
```

New single-table (`201`):

```json
{
  "booking_result":"created",
  "confirmation":{
    "reservation_reference":"9007199254740993",
    "customer_name":"Ada M. Rivera",
    "starts_at_local":"2026-09-12T17:00:00-04:00",
    "ends_at_local":"2026-09-12T18:30:00-04:00",
    "starts_at":"2026-09-12T21:00:00Z",
    "ends_at":"2026-09-12T22:30:00Z",
    "party_size":4,
    "assigned_table_numbers":[7],
    "newsletter_subscribed":true,
    "restaurant":{"address":"1234 Culinary Ave, Suite 100, Washington, DC 20002","phone":"(202) 555-4567"}
  }
}
```

New multi-table (`201`) uses the same schema:

```json
{
  "booking_result":"created",
  "confirmation":{
    "reservation_reference":"9007199254740994",
    "customer_name":"Lin Okafor",
    "starts_at_local":"2026-09-12T19:00:00-04:00",
    "ends_at_local":"2026-09-12T20:30:00-04:00",
    "starts_at":"2026-09-12T23:00:00Z",
    "ends_at":"2026-09-13T00:30:00Z",
    "party_size":10,
    "assigned_table_numbers":[3,12,24],
    "newsletter_subscribed":false,
    "restaurant":{"address":"1234 Culinary Ave, Suite 100, Washington, DC 20002","phone":"(202) 555-4567"}
  }
}
```

New booking with differing-phone notice (`201`):

```json
{
  "booking_result":"created",
  "confirmation":{
    "reservation_reference":"9007199254740995",
    "customer_name":"Ada M. Rivera",
    "starts_at_local":"2026-09-14T17:00:00-04:00",
    "ends_at_local":"2026-09-14T18:30:00-04:00",
    "starts_at":"2026-09-14T21:00:00Z",
    "ends_at":"2026-09-14T22:30:00Z",
    "party_size":4,
    "assigned_table_numbers":[18],
    "newsletter_subscribed":true,
    "restaurant":{"address":"1234 Culinary Ave, Suite 100, Washington, DC 20002","phone":"(202) 555-4567"}
  },
  "phone_notice":{"code":"stored_phone_preserved","message":"The reservation was created, but the phone number already on file was kept."}
}
```

Exact retry (`200`) returns the original confirmation and stored name spelling:

```json
{
  "booking_result":"exact_retry",
  "confirmation":{
    "reservation_reference":"9007199254740993",
    "customer_name":"Ada M. Rivera",
    "starts_at_local":"2026-09-12T17:00:00-04:00",
    "ends_at_local":"2026-09-12T18:30:00-04:00",
    "starts_at":"2026-09-12T21:00:00Z",
    "ends_at":"2026-09-12T22:30:00Z",
    "party_size":4,
    "assigned_table_numbers":[7],
    "newsletter_subscribed":true,
    "restaurant":{"address":"1234 Culinary Ave, Suite 100, Washington, DC 20002","phone":"(202) 555-4567"}
  }
}
```

### 14.7 Reservation failure/recovery variants

Same-customer overlap:

```json
{"error":{"code":"reservation_overlap","message":"This customer already has a reservation that overlaps the selected time.","retryable":false,"outcome_unknown":false}}
```

Stale/full capacity:

```json
{"error":{"code":"reservation_unavailable","message":"The selected time is no longer available. Refresh availability and choose another time.","retryable":false,"outcome_unknown":false}}
```

Field validation:

```json
{"error":{"code":"validation_failed","message":"One or more fields need attention.","retryable":false,"outcome_unknown":false,"fields":[{"field":"starts_at_local","code":"utc_offset_mismatch","message":"The selected time and UTC offset do not agree."}]}}
```

Temporary known failure:

```json
{"error":{"code":"temporary_failure","message":"The reservation could not be processed right now. Please retry shortly.","retryable":true,"outcome_unknown":false}}
```

Known reservation but unavailable confirmation after the post-commit name read:

```json
{"error":{"code":"reservation_confirmation_unavailable","message":"The reservation exists, but its complete confirmation could not be prepared. Resubmit the same reservation details to recover it.","retryable":true,"outcome_unknown":false}}
```

Ambiguous outcome:

```json
{"error":{"code":"reservation_outcome_unknown","message":"The reservation result could not be confirmed. Resubmit the same reservation details to recover safely.","retryable":true,"outcome_unknown":true}}
```

### 14.8 Health and common protocol errors

Liveness and readiness success:

```json
{"status":"live"}
```

```json
{"status":"ready"}
```

Readiness failure:

```json
{"error":{"code":"service_not_ready","message":"The service is not ready.","retryable":true,"outcome_unknown":false}}
```

Malformed body, unsupported media type, and unexpected error:

```json
{"error":{"code":"invalid_json","message":"The request body is not valid JSON.","retryable":false,"outcome_unknown":false}}
```

```json
{"error":{"code":"unsupported_media_type","message":"This endpoint requires application/json.","retryable":false,"outcome_unknown":false}}
```

```json
{"error":{"code":"internal_error","message":"An unexpected error occurred.","retryable":false,"outcome_unknown":false}}
```

Preference ambiguity and unusable service use the same common shape:

```json
{"error":{"code":"newsletter_preference_outcome_unknown","message":"The newsletter preference result could not be confirmed. Resubmit the same preference.","retryable":true,"outcome_unknown":true}}
```

```json
{"error":{"code":"service_unavailable","message":"The service cannot process this request right now.","retryable":true,"outcome_unknown":false}}
```

## 15. Complete wire-schema catalogue

Sections 7-9 are normative field definitions. This catalogue closes the field-level classification in one index. “Public” means returned; “request” means accepted only; “internal” means documented solely to show that it is withheld.

### 15.1 Requests and shared identity

| Schema/property | Type/format | Required/null/permitted | Normalization; source; classification | Example; invalid behavior; privacy |
|---|---|---|---|---|
| Identity.`first_name` | string/Unicode | Required, non-null, 1-100, letter required | Trim/collapse; caller; request | `Ada`; 422; PII |
| Identity.`middle_initial` | string/Unicode letter plus optional period | Optional, non-null, input max 2 | Trim/remove period/uppercase; caller; request | `M.` -> `M`; 422; PII |
| Identity.`last_name` | string/Unicode | Required, non-null, 1-100, letter required | Trim/collapse; caller; request | `Rivera`; 422; PII |
| Identity.`email` | string/email | Required, non-null, <=254 | Trim/lowercase; caller; request | `ada@example.com`; 422; PII |
| Identity.`confirmation_email` | string/email | Required, non-null, <=254, must match | Normalize then discard; caller; request-only | `ada@example.com`; 422; transient sensitive PII |
| Booking.`phone` | string/phone | Optional, non-null, <=32, approved chars, 7-15 digits | Outer trim, digit comparison transient; caller; request-only | `+1 (202) 555-0198`; 422; PII |
| Availability.`local_date` | string/date query | Required once, non-null | Parse without zone conversion; caller; request | `2026-09-12`; 400 shape or 422 value; non-PII |
| Availability.`party_size` | integer query | Required once, 1..current max | Strict base-10 parse; caller; request | `4`; 400 shape or 422 range; non-PII |
| Preference.`subscribed` | Boolean | Required/non-null | No coercion; caller final intent; request | `true`; 422; preference PII |
| Booking.`starts_at_local` | string/offset date-time | Required/non-null, seconds, no fractions/Z | Validate wall time, embedded offset, timezone; selected OP-02 fact; request | `2026-09-12T17:00:00-04:00`; 422; booking PII |
| Booking.`utc_offset_minutes` | integer | Required/non-null, -840..840 | Must match suffix/timezone; selected OP-02 fact; request | `-240`; 422; booking PII |
| Booking.`party_size` | integer | Required/non-null, 1..current max | No coercion; caller then DB authoritative; request | `4`; 422; booking data |
| Booking.`newsletter_action` | enum string | Required/non-null; `subscribe`, `unsubscribe`, `no_change` | Exact lower-case enum; caller; request | `no_change`; 422; preference PII |

### 15.2 Context and availability responses

| Schema/property | Type/format | Required/null/permitted | Source/classification | Example; privacy |
|---|---|---|---|---|
| Context.`restaurant` | object | Required/non-null | Fixed SRS; public | See 14.1; public content |
| Restaurant.`address` | string | Required/non-null/exact fixed value | SRS FR-02; public | `1234 Culinary Ave...`; public |
| Restaurant.`phone` | string | Required/non-null/exact fixed value | SRS FR-02; public | `(202) 555-4567`; public |
| Context.`restaurant_timezone` | string/IANA | Required/non-null/current valid value | Configuration; public | `America/New_York`; public configuration |
| Context.`weekday_hours` | array/7 WeekdayHours | Required/non-null/exactly 7/ordered 1..7 | Operating-hours rows; public | See 14.1; public configuration |
| WeekdayHours.`iso_weekday` | integer | Required/non-null/1..7 | Weekday row; public | `1`; public |
| WeekdayHours.`opens_at_local` | string/local time | Required/non-null | Weekday row; public | `17:00:00`; public |
| WeekdayHours.`closes_at_local` | string/local time | Required/non-null | Weekday row; public | `23:00:00`; public |
| Context.`reservation_policy` | object | Required/non-null | Configuration; public | See 14.1; public configuration |
| Policy.`start_interval_minutes` | integer enum | Required/non-null/15,30,60 | Configuration; public | `30`; public |
| Policy.`reservation_duration_minutes` | integer enum | Required/non-null/60,90,120 | Configuration; public | `90`; public |
| Policy.`advance_window_days` | integer | Required/non-null/1..365 | Configuration; public | `60`; public |
| Policy.`same_day_lead_minutes` | integer | Required/non-null/0..1440 | Configuration; public | `120`; public |
| Context.`reservable_date_range` | object | Required/non-null | DB clock + configuration; public | See 14.1; public snapshot |
| DateRange.`minimum_local_date` | string/date | Required/non-null/inclusive | DB clock/timezone; public | `2026-08-21`; public snapshot |
| DateRange.`maximum_local_date` | string/date | Required/non-null/inclusive | DB clock/window; public | `2026-10-20`; public snapshot |
| Context.`maximum_party_size` | integer | Required/non-null/>=1 | Sum of 30 capacities; public aggregate | `120`; public snapshot |
| AvailabilityResult.`local_date` | string/date | Required/non-null | Validated request; public | `2026-09-12`; non-PII |
| AvailabilityResult.`party_size` | integer | Required/non-null | Validated request; public | `4`; non-PII |
| AvailabilityResult.`restaurant_timezone` | string/IANA | Required/non-null | Current configuration; public | `America/New_York`; public |
| AvailabilityResult.`provisional` | Boolean | Required/non-null/always true | Protocol necessity; public | `true`; public |
| AvailabilityResult.`slots` | array/AvailabilitySlot | Required/non-null/0..logical daily maximum | Frozen routine, sorted start; public | See 14.2; public |
| Slot.`starts_at_local` | string/offset date-time | Required/non-null | Routine instant + timezone; public | `...17:00:00-04:00`; public |
| Slot.`utc_offset_minutes` | integer | Required/non-null | Derived from authoritative instant/timezone for echo; public | `-240`; public |
| Slot.`starts_at` | string/UTC instant | Required/non-null | Routine `starts_at`; public | `...21:00:00Z`; public |
| Slot.`ends_at_local` | string/offset date-time | Required/non-null | Routine end + timezone; public | `...18:30:00-04:00`; public |
| Slot.`ends_at` | string/UTC instant | Required/non-null | Routine `ends_at`; public | `...22:30:00Z`; public |
| Slot.`available` | Boolean | Required/non-null | Routine provisional state; public | `false`; public snapshot |

### 15.3 Newsletter, booking, and health responses

| Schema/property | Type/format | Required/null/permitted | Source/classification | Example; privacy |
|---|---|---|---|---|
| Lookup.`status` | enum | Required/non-null; `matched`, `not_found` | Customer read + protocol; public | `matched`; privacy-sensitive result |
| Lookup.`subscribed` | Boolean | Required for matched; otherwise omitted | Customer current state; public | `true`; preference PII |
| Preference.`result` | enum | Required/non-null; `set`, `no_customer_no_change` | Routine outcome mapping; public | `set`; privacy-sensitive result |
| Preference.`subscribed` | Boolean | Required/non-null | Routine authoritative state; public | `false`; preference PII |
| BookingSuccess.`booking_result` | enum | Required/non-null; `created`, `exact_retry` | Routine outcome mapping; public | `created`; booking data |
| BookingSuccess.`confirmation` | Confirmation object | Required/non-null | Approved confirmation composition; public | See 14.6; PII/booking data |
| Confirmation.`reservation_reference` | decimal string | Required/non-null/1..BIGINT max | Routine reservation ID; public | `9007199254740993`; booking identifier |
| Confirmation.`customer_name` | string | Required/non-null | Stored-name post-success read, composed first + optional ` X.` + last | `Ada M. Rivera`; PII |
| Confirmation.`starts_at_local` | offset date-time | Required/non-null | Committed instant + timezone; public | See 14.6; booking data |
| Confirmation.`ends_at_local` | offset date-time | Required/non-null | Committed instant + timezone; public | See 14.6; booking data |
| Confirmation.`starts_at` | UTC instant | Required/non-null | Routine; public | See 14.6; booking data |
| Confirmation.`ends_at` | UTC instant | Required/non-null | Routine; public | See 14.6; booking data |
| Confirmation.`party_size` | integer | Required/non-null/>=1 | Routine; public | `4`; booking data |
| Confirmation.`assigned_table_numbers` | array/integer | Required/non-null/nonempty/sorted unique | Routine sorted array; public | `[3,12,24]`; booking data |
| Confirmation.`newsletter_subscribed` | Boolean | Required/non-null | Routine current state; public | `true`; preference PII |
| Confirmation.`restaurant` | Restaurant object | Required/non-null | Fixed SRS; public | See 14.6; public content |
| BookingSuccess.`phone_notice` | PhoneNotice object | Conditional/new phone-notice only; non-null | Routine Boolean mapped; public | See 14.6; privacy-sensitive notice |
| PhoneNotice.`code` | enum | Required with notice; `stored_phone_preserved` | Protocol mapping; public | fixed enum; no stored value |
| PhoneNotice.`message` | string | Required with notice | Safe presentation intent; public | See 14.6; no phone value |
| Health.`status` | enum | Success only; `live` or `ready` per endpoint | Process/readiness result; public | `live`; non-sensitive |

### 15.4 Error and internal-only fields

| Schema/property | Type/format | Required/null/permitted | Source/classification | Example; privacy/error behavior |
|---|---|---|---|---|
| ErrorEnvelope.`error` | object | Required/non-null on every error | Protocol | See Section 10; safe |
| Error.`code` | public enum | Required/non-null/Section 10 | Safe mapping; public | `validation_failed`; stable branch value |
| Error.`message` | string | Required/non-null/nonempty | Safe presentation intent; public | Nontechnical; not stable for branching |
| Error.`retryable` | Boolean | Required/non-null | Whether identical complete request resubmission is an appropriate recovery action; public | `true`; false when correction, refresh, or different selection is required |
| Error.`outcome_unknown` | Boolean | Required/non-null | Mutation ambiguity; public | `false`; safe |
| Error.`fields` | array/FieldError | Optional; nonempty when present | Flask validation; public | Only request-visible fields; safe |
| FieldError.`field` | enum of endpoint request property names | Required/non-null | Caller-visible input; public | `party_size`; no stored/internal field |
| FieldError.`code` | lower-snake-case validation enum | Required/non-null | Safe rule mapping; public | `out_of_range`; stable branch value |
| FieldError.`message` | string | Required/non-null | Safe presentation intent; public | Nontechnical; no stored value |
| DB `outcome`, `detail_code` | text | Internal only | Frozen database contract | Never serialized |
| DB `customer_id`, stored email/phone | database fields | Internal only | PostgreSQL | Never serialized |
| DB fingerprint/version | binary/smallint | Internal only | PostgreSQL retry authority | Never accepted or serialized |
| Free tables/candidates/capacities/rank/random | derived internals | Internal only | PostgreSQL allocation | Never serialized |

## 16. Non-executable contract unit-test plan

No test is created in API-02. Later API increments automate these cases.

| Group | Contract cases and required assertions |
|---|---|
| Common protocol | Each documented method/path accepted, including body-based `POST /api/v1/newsletter-preferences`; `PUT` on that path is 405 and the obsolete singular path is 404; other wrong methods use 405 with the envelope; unknown paths use 404; GET body/query extras are rejected; JSON media type is accepted; missing body is 400; malformed/non-object/detectable duplicate member is 400; unsupported type is 415; unknown and forbidden fields are 400; all errors have four required members and no diagnostics. Every `retryable:true` case permits identical resubmission; every case requiring correction, refresh, or a different slot has `retryable:false`. |
| Strict values | Required/optional/null/empty/wrong-type cases for every field; no Boolean/numeric coercion; fractional/exponent-loss/NaN/Infinity rejected; exact boundary lengths; unknown enum rejected; response consumers ignore additive properties. |
| Unicode identity | Trim/collapse and representative accented/non-ASCII-letter names preserve display; case-insensitive matching; punctuation-only names fail; middle omission differs from null/empty; optional period normalizes; email confirmation matches after normalization; confirmation email absent from all responses/examples/log models. |
| OP-01 | Exactly seven ordered weekdays, five current policy facts, inclusive date bounds, valid IANA zone, fixed contact facts, derived max; missing/invalid population gives generic 503; no total/table inventory. |
| OP-02 | Only two query fields; date/party boundaries; every legitimate slot exactly once in canonical order; unavailable retained; all-false and empty valid arrays are 200; provisional true; no arbitrary/customer/reservation/table/candidate/capacity field. |
| OP-03 | Subscribed, unsubscribed, not-found, generic mismatch, middle conflict, validation, and indeterminate schemas/statuses; lookup changes no data and returns no profile/contact/ID. |
| OP-04 | POST true/false set, new selected, existing transition, same-state repetition, new false/no-customer, generic/middle conflict, temporary failure, and ambiguity; the same body safely repeats at application level despite POST not being HTTP-idempotent; no created/updated/history discriminator. |
| OP-05 success | 201 single/multi-table created, 201 phone notice, 200 exact retry; one confirmation schema; ascending unique tables; stored display name; current newsletter; no delivery claim/contact/fingerprint; reference `9007199254740993` remains a string. |
| OP-05 time | Seconds required, fractions/Z rejected for local input; suffix-offset integer agreement; DST standard/daylight offsets; nonexistent/ambiguous starts; canonical Z response; end/duration never accepted; back-to-back endpoints allowed. |
| OP-05 failures | Validation 422, identity/middle/overlap/unavailable 409 with distinct codes, service/temporary 503, failed post-commit name read as `503 reservation_confirmation_unavailable` with known outcome, booking commit ambiguity as distinct `reservation_outcome_unknown`, and unexpected 500 only when noncommit known. Assert unavailable is not retryable, confirmation-unavailable supports identical resubmission/exact reconstruction, every database stable outcome/detail maps exactly once, and detail never leaks. |
| OP-06/07 | Liveness succeeds without database; readiness depends on approved checks; ready 200 and generic not-ready 503; neither returns versions, components, diagnostics, or customer facts. |
| Cache/privacy | Every endpoint has no-store semantics; no PII in paths/query/cache keys; PII-bearing bodies and confirmation are protected; error/log examples contain no raw identity, confirmation email, phone, SQL, SQLSTATE, or credentials. |

## 17. Non-executable contract-to-database integration plan

“Automation” names the later roadmap owner; API-02 executes none of these cases.

| Fixture / HTTP variant | Operation and PostgreSQL source/result | Expected HTTP/body | Expected persistent state | Withheld / automation |
|---|---|---|---|---|
| One config, weekdays 1-7, 30 x capacity 4; GET context | OP-01 foundation snapshot | 200 Context, max 120 | Unchanged | Table rows/count hidden; API-04/07, API-09 |
| Alternate valid recurring hours/config | OP-01 reads changed rows | 200 same schema, changed values/bounds | Unchanged | No hard-coded seed; API-07/09 |
| Changed positive table capacities | OP-01 aggregate | 200 only changed max; OP-02 later reflects capacity | Unchanged | Individual/total duplicate hidden; API-07/09 |
| Missing config/hour/table or invalid timezone | OP-01/OP-07 foundation checks | Public 503 service unavailable/not ready | Unchanged | Exact failed invariant hidden; API-04/07/09 |
| Empty/free/partial/full/back-to-back reservations; GET availability | OP-02 frozen routine `slots` | 200 complete ordered flags, including all false | Unchanged | Reservations/assignments/free tables hidden; API-07/09 |
| Matching subscribed/unsubscribed customer; POST lookup | OP-03 customer projection | 200 matched Boolean | Unchanged | Stored identity/contact hidden; API-05/09 |
| No canonical customer; POST lookup | OP-03 read no row | 200 not_found | Unchanged | No profile inference beyond approved result; API-05/09 |
| Same email with first/last mismatch or populated middle conflict | OP-03 comparison | 409 generic or middle code | Unchanged | Stored difference hidden; API-05/09 |
| POST new true preference | OP-04 routine `subscribed` | 200 set/true | One customer true | Created discriminator hidden; API-06/09 |
| Existing true/false transition or same-state | OP-04 `subscribed`/`unsubscribed` | 200 set/final Boolean | One row, final Boolean | Prior state/history hidden; API-06/09 |
| Unknown identity set false | OP-04 `no_customer_no_change` | 200 no_customer_no_change/false | No row | No customer ID; API-06/09 |
| Concurrent same-email preference/create | OP-04 controlled routine | One defined result per request, each 200 or safe mapped conflict | One canonical customer; last valid commit wins | Locks/attempts hidden; API-06/09 |
| New party 4 with one winning table | OP-05 `booked` + name read | 201 created, one table | One reservation + one assignment | Candidate/fingerprint hidden; API-08/09 |
| New party requiring several tables | OP-05 `booked` + name read | 201 created, ascending array | One reservation + complete assignments | Capacity/rank hidden; API-08/09 |
| Existing differing phone | OP-05 `booked_phone_notice` | 201 created + safe notice | Booking commits; stored phone unchanged | Both phone values hidden; API-08/09 |
| Same ordinary retry with different accepted casing | OP-05 `exact_retry` + stored-name read | 200 exact_retry, same reference/name/interval/tables | No new/mutated booking/contact/newsletter | Fingerprint hidden; API-08/09 |
| New booking commit or exact retry succeeds, then separate stored-name read fails | OP-05 known successful routine/commit followed by failed authorized customer projection | 503 reservation_confirmation_unavailable, retryable true, outcome unknown false; identical resubmission later returns exact-retry confirmation | Known reservation and assignments remain committed; no replayed contact/newsletter mutation | Stored identity/read failure hidden; API-08/09 |
| Same customer different overlapping request | OP-05 `same_customer_overlap` | 409 reservation_overlap | No attempted mutation | Existing reservation hidden; API-08/09 |
| Different customer overlap with sufficient disjoint capacity | OP-05 `booked` | 201 created | Both complete, no shared table overlap | Allocation internals hidden; API-08/09 |
| OP-02 available, intervening booking fills capacity, then OP-05 | OP-05 `unavailable` | 409 reservation_unavailable | Intervening booking only | Stale/free facts hidden; API-08/09 |
| Forced `55P03`/`40P01`/`40001`, then success or exhaustion | OP-04/05 full-attempt retry | Success or 503 temporary_failure | Exactly committed successful state or none | SQLSTATE/attempt count hidden; API-03/06/08/09 |
| Connection loss before work | Any DB operation | 503 known temporary/indeterminate lookup | No mutation | Connection details hidden; API-04/09 |
| Connection loss during/after OP-04 commit | OP-04 | 503 preference outcome unknown; identical resubmit reaches final 200 | Zero/one correct customer, final requested Boolean | Commit mechanics hidden; API-06/09 |
| Connection loss during/after OP-05 commit | OP-05 | 503 reservation outcome unknown; resubmit creates or exact-retries | Exactly one reservation identity and complete assignments | Commit/fingerprint hidden; API-08/09 |
| App role attempts direct DML/reservation read/helper | Privilege denial | No public bypass route; endpoint maps only its authorized operation result | No unauthorized state | SQLSTATE/object names hidden; API-09 |
| Database down | OP-01-05/07 | Read/mutation-safe 503; liveness still 200 | No known mutation unless explicitly ambiguous | Host/credential hidden; API-04/09 |
| Correct PostgreSQL 18.3/extension/signatures/grants/population | OP-07 | 200 ready | Unchanged | Details hidden; API-04/09 |

Each automated integration case must record initial fixture state, exact request, operation/source, database result, HTTP status/schema, final state, withheld facts, and responsible increment as shown. Tests use isolated nonproduction databases and never weaken the app-role boundary.

## 18. Manual contract-review checklist

- [ ] A React developer can build all requests and render all success, unavailable, pending-recovery, and error states without PostgreSQL knowledge.
- [ ] Legitimate starts come only from OP-02; all unavailable starts remain present and distinguishable.
- [ ] Changing date/party invalidates the prior client selection; OP-05 still revalidates authoritatively.
- [ ] OP-03 returns no profile and does not imply ownership verification.
- [ ] Exact retry is visibly successful and distinct from a new `201` without another route or key.
- [ ] Single- and multi-table confirmations use one schema and ascending table numbers.
- [ ] Confirmation shows stored name spelling, restaurant contact facts, and no email/SMS delivery claim.
- [ ] Mismatch errors never reveal which stored value differed.
- [ ] Unknown booking outcome never claims failure and explicitly supports ordinary resubmission.
- [ ] A failed post-commit name read reports a known existing reservation with `reservation_confirmation_unavailable`, not `reservation_outcome_unknown`, and identical resubmission reconstructs it.
- [ ] `retryable` means the same request is appropriate; unavailable capacity is false because recovery requires refresh and another slot.
- [ ] No PII or booking body value appears in a URL.
- [ ] No response exposes free tables, candidates, capacities, fingerprints, SQL, SQLSTATE, schema, routines, roles, or detail codes.
- [ ] No cancellation, modification, authentication, administration, messaging, hold, queue, or history operation appears.
- [ ] API-03 can implement the contract without choosing new wire behavior.

## 19. Performance and payload assessment

Context is bounded to seven weekdays and a small fixed set of scalars. Lookup/preference/health responses are constant-size. A confirmation contains one name, one interval, and at most the current 30 assigned table numbers. For opening `O`, same-day closing `C`, duration `D`, and interval `I`, the logical slot count is `max(0, floor((C - O - D) / I) + 1)`. Under the approved same-day-hours model, minimum 60-minute duration, and minimum 15-minute interval, the derived upper bound is 92 starts; this is an assessment bound, not a hardcoded response validator. The contract does not treat the seed's ten weekday or six Sunday rows as a protocol limit.

Pagination, streaming, queues, jobs, holds, polling, or asynchronous booking are unjustified. One-day slots, seven weekday rules, and at most 30 assignments are small. Candidate combinations and capacity internals are omitted because they are potentially much larger, have no client use, and belong to PostgreSQL.

Later API-09 and integration work must measure normalization, validation, connection acquisition, retry/backoff, transaction execution, name read, serialization, Flask scheduling, network, and browser handling in addition to DB-07 evidence. General database allocation p95 around 1.14-1.27 seconds and coarse-lock contention beyond two seconds remain accepted limitations, not public latency guarantees. Contention appears as correct success/business outcome or safe temporary failure, never weakened integrity. The SRS two-second form expectation remains for later full-stack validation.

## 20. Operation, endpoint, and field-source traceability

### 20.1 Bijective operation-to-endpoint map

| API-01 operation | Sole endpoint | Justification |
|---|---|---|
| OP-01 current context | `GET /api/v1/reservation-context` | One coherent current discovery resource. |
| OP-02 daily availability | `GET /api/v1/reservation-availability` | Safe date/party calculation; no PII. |
| OP-03 newsletter lookup | `POST /api/v1/newsletter-status-queries` | Body protects identity values. |
| OP-04 set preference | `POST /api/v1/newsletter-preferences` | Body identifies the customer; final-state behavior is application-level idempotent. |
| OP-05 create/reconstruct | `POST /api/v1/reservations` | New resource or exact reconstruction from ordinary facts. |
| OP-06 liveness | `GET /api/v1/health/liveness` | Process-local technical operation. |
| OP-07 readiness | `GET /api/v1/health/readiness` | Separate database-backed technical operation. |

Every endpoint maps to exactly the operation in its row; there is no split, grouping, or additional operation.

### 20.2 Field-source matrix

| Wire fact group | Approved source or protocol necessity | Consumer |
|---|---|---|
| Identity, confirmation email, phone | FR-06/15; PRA-019/023; API-01 normalized inputs | OP-03/04/05 and later forms |
| Local date/party | FR-06/07; PRA-015/025 | OP-02 slot discovery |
| Local start/offset/action | PRA-012/021/023/025 and frozen booking signature | OP-05 authoritative submission |
| Hours/policy/date bounds/max party | OP-01 foundation facts; PRA-006-012/015-017/029 | Home/reservation controls |
| `provisional`, slots, available | OP-02 frozen output plus necessary non-guarantee signal | Full daily schedule |
| Lookup matched/not-found/subscribed | OP-03 minimum workflow state | Checkbox synchronization |
| Preference final state/result | OP-04 routine output | Dedicated form confirmation |
| Booking result/reference/name/interval/party/tables/newsletter | OP-05 routine + approved post-commit name read + PRA-024 | Confirmation/recovery; name-read failure uses known-reservation recovery |
| Fixed restaurant address/phone | SRS FR-02/PRA-024 | Context and confirmation |
| Phone notice | Frozen `phone_notice` + PRA-019 | Successful non-overwrite notice |
| Error code/message/fields/retry/unknown | NFR-06/PRA-024 and protocol branching/recovery necessity | All clients |
| Health status | API-01 OP-06/07 minimum state | Infrastructure |

No other field is needed by the approved React workflows. Internal fields listed in Section 15.4 are deliberately absent.

## 21. Requirements traceability

### 21.1 SRS and external-interface coverage

| SRS requirement | API-02 coverage |
|---|---|
| FR-02 address, phone, hours | Fixed contact fields and database-backed seven-day Context hours; confirmation repeats contact facts. |
| FR-06 reservation form facts | OP-02 date/party and OP-05 structured identity/email/optional phone/start/party fields. |
| FR-07 valid and available slot | OP-02 full provisional schedule; OP-05 mapped authoritative validation/unavailable result. |
| FR-08 random table from 30 | OP-05 returns only committed sorted assigned table numbers; allocation/random choice remains frozen inside PostgreSQL. |
| FR-09 success or full/error | 201/200 confirmation, 409 unavailable, and safe common errors. |
| FR-15 validated newsletter form | Shared exact email/identity validation and OP-03/04. |
| FR-16 newsletter database storage | OP-04 final authoritative Boolean and booking-linked OP-05 action, with no duplicate source. |
| FR-18 Flask customer/availability/allocation/result logic | Each endpoint maps to the authorized PostgreSQL source; Flask invokes/maps without reproducing authority. |
| NFR-02 two-second forms | No unsupported contract promise; later API-09/INT-07 measurement preserves DB-07 limitations. |
| NFR-05 integrity/no overbooking | OP-02 is explicitly provisional; OP-05 alone invokes locked authoritative booking; no bypass field/path exists. |
| NFR-06 user-friendly failures | Stable nontechnical error envelope, exact identical-resubmission meaning for `retryable`, and distinct conflict/unavailable/temporary/known-confirmation-failure/unknown-booking outcomes with recovery guidance. |
| NFR-09 modular/documented | Versioned bounded schemas, mappings, test plans, traceability, and deferrals. |
| SRS 3.3.2 software interfaces | Defines the Flask-facing HTTP/JSON contract while PostgreSQL remains the data system. |
| SRS 3.3.3 communication interfaces | Versioned REST-style HTTP paths, methods, JSON media type, statuses, and error semantics. HTTPS termination remains deployment work. |

Static FR-01, FR-03 through FR-05, and FR-10 through FR-14 require no backend operation. UI/load/browser/responsive NFRs remain React/integration responsibilities and are not claimed complete.

### 21.2 PRA coverage

| PRA | Contract treatment |
|---|---|
| PRA-001 to PRA-004 | Preserves ordered, least-to-most, tested, authoritative design and stops before implementation. |
| PRA-005 to PRA-011 | Context exposes current PostgreSQL interval/duration/window/lead/hours/date limits; availability/booking revalidate them. |
| PRA-012 | Exact IANA, local date/time, canonical instant, and explicit offset contract; browser/host timezone cannot reinterpret input. |
| PRA-013 | Half-open confirmation intervals and back-to-back behavior. |
| PRA-014 | Exact retry is 200 success from ordinary facts; different same-customer overlap is 409. |
| PRA-015 to PRA-018 | Dynamic maximum, full-slot status, and one-or-more sorted assigned tables with allocation internals withheld. |
| PRA-019 | Structured identity, confirmation, optional-field omission, limited population/non-overwrite notice, no auth/profile. |
| PRA-020 | One Boolean current state; no subscriber/history resource. |
| PRA-021 | Body-based POST with application-level final-state idempotency, booking action enum, and concurrency-safe retry/ambiguity representation. |
| PRA-022 | No cancellation/modification/rescheduling endpoint or field. |
| PRA-023 | Strict server validation/normalization and current PostgreSQL revalidation; no coercion. |
| PRA-024 | Complete confirmation, no delivery claim, safe messages, redaction, stale/full/ambiguity handling, and explicit recovery when the separate post-commit stored-name read cannot assemble confirmation. |
| PRA-025 | Availability-first flow, every legitimate slot, unavailable flags, provisional signal, no arbitrary times/table choice, refresh recovery. |
| PRA-026 to PRA-028 | Current values remain prospective; exact retry newsletter separation and normal retention remain internal; no history/reset customer API. |
| PRA-029 | Seven current hours come from PostgreSQL; no Flask/React authoritative schedule constants or exception model. |

### 21.3 Baseline API and rubric coverage

| Identifier | API-02 disposition |
|---|---|
| Baseline API-01 | Flask remains the required later backend; no implementation is claimed. |
| Baseline API-02 | Reservation/newsletter REST paths, methods, JSON schemas, statuses, and errors are complete. |
| Baseline API-03 | OP-02/05 accept required facts and map controlled customer/validation/allocation/persistence results. |
| Baseline API-04 | OP-03/04 validate and expose only current newsletter behavior. |
| Baseline API-05 | Timing measurement remains later; contract payload/retry limits avoid unsupported promises. |
| Baseline API-06 | Common nontechnical errors and safe caller actions cover every approved outcome. |
| Baseline API-07 | Database and future React consumers have one stable compatibility boundary. |
| RUB-01 all SRS requirements | Every API-applicable SRS requirement is mapped; static/UI/deployment requirements are explicitly deferred. |
| RUB-05 working forms | Contract supplies all reservation/newsletter inputs, pending-recovery results, and confirmation fields required by later forms. |
| RUB-06 Flask/PostgreSQL/React integration | Exact authorized database mapping and stable mocks prevent client/server invention or bypass. |
| RUB-07 database effects/sophisticated logic | OP-04/05 preserve current-state mutation, exact allocation, multi-table results, exact retry, and future direct-database demonstration. |
| RUB-02 to RUB-04, RUB-08 to RUB-15 | React presentation or submission/delivery obligations; no API endpoint justified. |

### 21.4 Outcome and public-code closure

Section 10 maps every stable PostgreSQL availability, preference, and booking outcome/detail plus protocol, router, dependency, timeout, retry-exhaustion, post-commit confirmation assembly failure, booking ambiguity, readiness, and unexpected-failure categories. Each public error code has one HTTP status and fixed retry/unknown semantics. `reservation_confirmation_unavailable` means existence is known; `reservation_outcome_unknown` means commit is uncertain. No database literal is public.

The later client fields required for discovery, full-slot display, checkbox synchronization, preference confirmation, review/submit, exact-retry recovery, complete confirmation, phone notice, stale/full refresh, and health supervision are all present. The prohibited database, profile, contact, allocation, configuration-control, and delivery fields are all absent.

## 22. Explicit Version 1 exclusions and rejected contract elements

No endpoint, action, field, or link is defined for authentication/login/logout/registration/password/session/verified ownership; customer profile/prefill/general contact update; email verification; reservation lookup/list/cancel/modify/reschedule/no-show; reservation/table/configuration/hours administration; customer-selected tables; active/adjacent/combinable/shared tables or seats; holds/waitlists/queues/jobs; availability/candidate/retry/random history; holidays/date exceptions/closed recurring days/overnight/multiple periods; newsletter/configuration/schedule history; confirmation email/SMS; payments/menu ordering/loyalty/analytics; audit/archive/purge; database migration/reset/seed/verification/performance/test helpers; SQL/schema/role/extension diagnostics; pagination/search/filter/sort; or generic CRUD.

| Considered element | Rejected reason |
|---|---|
| Separate hours or limits endpoint | OP-01 approved grouping is one freshness/failure boundary. |
| Context plus availability | Different inputs, cost, freshness, and guarantee semantics. |
| `GET` newsletter lookup with query identity | Would expose PII in URLs/history/logs/cache keys. |
| Subscribe/unsubscribe event routes | Would imply history/events rather than one current Boolean. |
| Separate reservation retry/lookup | Contradicts ordinary-resubmission exact retry and would require a public identifier/key input. |
| Client idempotency key/fingerprint/reference input | PostgreSQL owns retry identity; identifiers are not lookup authority. |
| End/duration/timezone/availability/table choice in booking | Derived/current/internal authority; accepting it would duplicate or bypass PostgreSQL. |
| Customer ID/profile fields | Privacy-sensitive, no authentication or workflow need. |
| Total capacity/table inventory/free tables/candidates/rank/random | Redundant or internal allocation evidence; maximum party size and final assignments suffice. |
| Created/updated/idempotent preference discriminator | Frozen routine exposes final state, not prior-row history; client does not need the distinction. |
| Delivery status/link | PRA-024 and FE-011 exclude email/SMS delivery. |
| Combined liveness/readiness | Would make a live-but-database-unready service lie or expose diagnostics. |
| Pagination/streaming/async booking | Collections are bounded and booking is one synchronous controlled operation. |

## 23. Decisions deferred after API-02

| Destination | Deferred decisions |
|---|---|
| API-03 | Flask module/application design, validation/serialization library, database driver/pool, configuration loading, connection/transaction wrapper, numeric deadlines/timeouts/backoff/jitter, retry placement, exact no-store headers, logging framework/format/redaction implementation, test framework/fixtures. |
| API-04 | Executable common errors, liveness/readiness, connectivity, configuration, logging, and foundational tests. |
| API-05 | Executable identity normalization and OP-03. |
| API-06 | Executable OP-04 and preference timing/concurrency evidence. |
| API-07 | Executable OP-01/02 and schedule/time/DST fixtures. |
| API-08 | Executable OP-05, confirmation, retry, ambiguity, and transactional tests. |
| API-09 | Complete contract conformance, database integration, redaction, performance, and Flask phase gate. |
| React/UI | Components, state, debounce/stale-response suppression, exact user wording, accessibility/focus, presentation, and mocks conforming to this contract. |
| Integration/deployment | Base URL, CORS/proxy/TLS/host topology, readiness reachability, live composition, browser/network measurements, full NFR-02 acceptance, and final demonstration. |

No deferred implementation choice may change a field, path, method, status, code, time form, retry signal, privacy rule, or PostgreSQL authority without an approved API-02 revision.

## 24. DB-07 and API-01 compatibility assessment

| Frozen element | API-02 assessment |
|---|---|
| Seven API-01 operations | Exactly seven endpoints, bijectively mapped; no new operation. |
| Four foundation reads/three routines | Used exactly as inventoried; no new query, routine, view, grant, or write path. |
| OP-05 stored-name source | Preserved after each successful committed database result; request casing never drives confirmation. A failed separate read maps to known-outcome `reservation_confirmation_unavailable` and identical exact-retry reconstruction. |
| PostgreSQL 18.3/`pgcrypto` | Preserved as readiness/internal deployment facts, not diagnostic response fields. |
| `READ COMMITTED`, locks, allocation | Kept entirely inside the approved database/caller transaction boundary. |
| Fingerprint/exact retry | No client key; 200 exact-retry success from ordinary facts; fingerprint withheld. |
| Retry classes/three-attempt maximum | Preserved; numeric deadline/backoff remain API-03. |
| Direct reservation/assignment denial | Preserved; confirmation comes from routine output only. |
| General allocation/coarse-lock performance limitations | Accurately retained; no new latency guarantee. |
| Privacy/exclusions | Profile, mismatch cause, internals, admin, cancellation, messaging, and history remain absent. |

No API-01 decision, PostgreSQL signature/result/grant, DB-03 schema, or DB-04 transaction decision changes.

## 25. Unresolved issues and deviations

No unresolved contradiction, missing business decision, privilege gap, database change, or approval blocker remains. The design choices assigned to later increments in Section 23 are deliberate implementation deferrals, not wire ambiguities.

There is no deviation from Prompt 11. API-02 changes only this design artifact. It does not modify `database/`, `backend/`, `frontend/`, API-01, or another approved artifact, and it creates no executable schema or test.

## 26. API-02 completion assessment

| Criterion | Assessment |
|---|---|
| Every API-01 operation has one stable method/path | Complete |
| Later React can build all workflows without inventing fields/rules | Complete |
| Later Flask maps every request to one approved operation/source | Complete |
| Field names/types/formats/optionality/nullability/ranges/enums | Complete |
| Date/time/offset and half-open semantics unambiguous | Complete |
| PostgreSQL `BIGINT` reference JavaScript-safe | Complete: decimal string |
| New booking versus exact retry | Complete: 201 `created` versus 200 `exact_retry` |
| Unknown mutation outcome and safe resubmission | Complete |
| Known booking with failed post-commit confirmation-name read | Complete: 503 `reservation_confirmation_unavailable`, retryable true, outcome unknown false |
| `retryable` identical-request semantics | Complete; authoritative unavailable is false and requires refreshed/different input |
| Every stable database outcome/detail safely mapped | Complete |
| Common error envelope/status catalogue complete | Complete |
| Availability returns every legitimate slot and no internals | Complete |
| Lookup returns no profile or stored mismatch cause | Complete |
| No PII in URLs or cache keys | Complete |
| No duplicate source of truth/database bypass | Complete |
| Health/readiness minimal and distinct | Complete |
| Contract/unit/integration/manual review plans complete | Complete |
| SRS/rubric/PRA/baseline/API-01 traceability complete | Complete |
| Version 1 exclusions and later deferrals recorded | Complete |
| PostgreSQL 18.3/performance limitations preserved | Complete |
| Flask/React/SQL implementation avoided | Complete |
| Unresolved blockers | None |

API-02 version 1.0.1 is approved by Abdul as of 2026-08-21. No implementation increment has begun.

### 26.1 Version record

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-21 | Established the complete proposed API-02 HTTP/JSON contract. |
| 1.0.1 | 2026-08-21 | Corrected OP-04 to body-based `POST /api/v1/newsletter-preferences`; added known-reservation recovery for failed post-commit confirmation-name reads; defined `retryable` as identical-request recovery and made `reservation_unavailable` non-retryable. No API-01, PostgreSQL, Flask implementation, or Version 1 business rule changed. |

## 27. Approval checkpoint

| Item | Value |
|---|---|
| Current increment | API-02 - Flask REST Contract |
| Current status | Approved by Abdul on 2026-08-21 |
| Approver | Abdul |
| Approval effect | Authorizes only API-03 - Flask Architecture, Configuration, and Test Strategy |
| Not authorized | Flask implementation, API-04 or later work, React, integration, or PostgreSQL changes |

> **API-02 approval is required before API-03 may begin. Approval authorizes only API-03 Flask Architecture, Configuration, and Test Strategy. It does not authorize Flask implementation, React work, integration work, or changes to the approved PostgreSQL layer.**
