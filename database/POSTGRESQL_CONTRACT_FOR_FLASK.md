# PostgreSQL Contract for Flask v1.1

Status: Version 1.1 reconciles the approved API08-RC-01 classification decision on 2026-08-24; version 1.0 was approved by Abdul at DB-07 Hard Gate 1 on 2026-08-20. This is not a REST contract.

## Platform, namespace, and caller rules

- PostgreSQL 18.3 is the required, implemented, and verified Version 1 database version. `pgcrypto` is required; built-in `plpgsql` is also present. Compatibility with PostgreSQL 14-17 or any version other than 18.3 is outside this verified contract.
- Business objects live only in `cafe_fausse`. `cafe_fausse_owner`, `cafe_fausse_app`, and `cafe_fausse_test` are passwordless, non-login, non-superuser group roles.
- Production Flask code uses `cafe_fausse_app`, calls only the three production operations below, and does not reproduce allocation, overlap, exact-retry, fingerprint, or concurrency logic in process-local code.
- Each volatile operation owns its PostgreSQL transaction-level advisory locks. Call it at `READ COMMITTED`; do not place booking in another isolation level. A call may be the only statement in an explicit caller transaction or may run in autocommit. The caller must commit on a returned result and roll back after an exception before retrying.
- The caller may attempt no more than three complete transactions within one overall deadline for `55P03`, `40P01`, or `40001`, with short exponential backoff and jitter. An ordinary resubmission is safe after an ambiguous commit result.

## Production controlled operations

### `cafe_fausse.provisional_availability(date, integer)`

Parameters are `p_local_date date`, `p_party_size integer`. Result columns are:

| Field | PostgreSQL type | Meaning |
|---|---|---|
| `outcome` | `text` | `slots`, `invalid_request`, or `invalid_database_configuration` |
| `detail_code` | `text` | Nullable stable detail identifier |
| `local_start` | `timestamp without time zone` | Restaurant-local wall time |
| `starts_at` | `timestamp with time zone` | Canonical instant |
| `ends_at` | `timestamp with time zone` | Canonical instant using current duration |
| `available` | `boolean` | Provisional capacity state at statement time |

Stable details are `date_or_party_size_out_of_range`, `incomplete_foundation_population`, and `invalid_timezone`. A `slots` call returns every legitimate aligned start, including unavailable starts. It persists nothing, takes no booking lock, and promises neither capacity nor success; booking always revalidates.

### `cafe_fausse.set_newsletter_preference(text,text,text,text,boolean)`

Parameters are normalized `first_name`, nullable normalized `middle_initial`, `last_name`, canonical email, and subscribed Boolean. It returns `(outcome text, newsletter_subscribed boolean)`. Stable outcomes are `subscribed`, `unsubscribed`, `no_customer_no_change`, `invalid_request`, `customer_identity_mismatch`, and `middle_initial_conflict`. It serializes by canonical email. Unsubscribe for an unknown identity creates no row.

### `cafe_fausse.book_reservation(text,text,text,text,text,timestamp without time zone,smallint,integer,text)`

Parameters are normalized first name, nullable uppercase one-character middle initial, normalized last name, trimmed lowercase canonical email, nullable validated phone, restaurant-local start, selected UTC offset in minutes, party size, and newsletter action (`subscribe`, `unsubscribe`, or `no_change`). Flask remains responsible for full email syntax, confirmation-email matching, Unicode-aware request normalization, and request-shape validation.

Result columns are:

| Field | PostgreSQL type | Meaning |
|---|---|---|
| `outcome` | `text` | Stable database outcome |
| `detail_code` | `text` | Nullable stable reason |
| `reservation_id` | `bigint` | Database confirmation reference |
| `starts_at`, `ends_at` | `timestamp with time zone` | Immutable half-open interval `[start,end)` |
| `party_size` | `integer` | Immutable positive party size |
| `assigned_table_numbers` | `smallint[]` | Sorted, committed winning tables |
| `newsletter_subscribed` | `boolean` | Current authoritative preference |
| `phone_notice` | `boolean` | Existing populated phone differed and was not overwritten |
| `fingerprint_version` | `smallint` | Currently `1` |
| `reservation_fingerprint` | `bytea` | Database-generated SHA-256 retry candidate key |

Stable outcomes are `booked`, `booked_phone_notice`, `exact_retry`, `same_customer_overlap`, `customer_identity_mismatch`, `middle_initial_conflict`, `unavailable`, `invalid_request`, and `invalid_database_configuration`. Stable validation/readiness details are `requires_read_committed`, `invalid_normalized_input`, `configuration_row_count`, `operating_hours_population`, `restaurant_table_population`, `invalid_timezone`, `nonexistent_local_start`, `ambiguous_local_start`, `utc_offset_mismatch`, `date_outside_booking_window`, `insufficient_same_day_lead`, `start_before_opening`, `misaligned_start`, `end_after_closing`, `duration_or_party_size_out_of_range`, `no_capacity_sufficient_combination`, and `time_boundary_crossed_during_booking`.

For `duration_or_party_size_out_of_range`, the outcome is the deterministic discriminator: a caller-controlled party size below one or above current total capacity returns `invalid_request`; an invalid server-controlled `reservation_duration_minutes` returns `invalid_database_configuration`. The result columns and detail vocabulary are unchanged.

`exact_retry` is verified against `(customer_id, starts_at, party_size)` after the non-unique fingerprint lookup. It returns the original interval and assignments plus the current newsletter state, and performs no customer/contact/newsletter mutation. Thus response loss after commit is recovered by the same ordinary request without a client key. A differing populated phone returns `booked_phone_notice`; it does not overwrite the stored phone.

## Persistence and temporal contract

- ISO weekday is 1 Monday through 7 Sunday. Recurring local hours are authoritative. `America/New_York` is the initial timezone; DST ambiguity/nonexistence is resolved or rejected using the submitted offset.
- `starts_at`/`ends_at` are canonical instants; overlap is `existing.starts_at < proposed.ends_at AND proposed.starts_at < existing.ends_at`. Endpoint contact is allowed.
- Reservation duration is copied only as the immutable interval implied by start/end; later configuration changes are prospective. Capacity and assignment winners are read from current authoritative tables at booking; no capacity copy is stored.
- Confirmation reconstruction uses the booking result. The app role is deliberately denied direct reads of `reservations` and `reservation_table_assignments`; no separate application query contract is exposed in v1.0.

## Privilege boundary

`cafe_fausse_app` has schema `USAGE`, read access to the four foundation tables, and `EXECUTE` only on the three production operations. It has no direct table mutation, reservation/assignment read, sequence, DDL, reset, deterministic-rank, failure-injection, internal-helper, or configuration-writer capability. `PUBLIC` has no schema/object execution path, including for future owner-created functions. Test seams belong only to `cafe_fausse_test` in an isolated database.

## Lifecycle, readiness, and performance

- Rebuild: `database/scripts/rebuild.ps1`; read-only catalog/readiness verification: `database/scripts/verify.ps1`; full gate: `database/scripts/test.ps1`.
- The rebuild requires explicit nonproduction `PGDATABASE`, `CAFE_FAUSSE_ENVIRONMENT`, and `CAFE_FAUSSE_ALLOW_RESET=YES`. It applies migrations lexically and restores one configuration row, seven hours rows, and 30 capacity-four tables.
- Reference measurements are in `DB07_VERIFICATION_REPORT.md`. The proposed database contribution budget is p95 below 1,000 ms for uncontended production booking and availability on the DB-07 reference host, excluding caller/network time. The fast-path and ordinary-result cases meet it, but measured production bookings that require the general exact equal-capacity or heterogeneous-capacity allocator do not (p95 1,265.04 ms and 1,135.29 ms). The proposal therefore is not met by every production allocation path and is not an approved guarantee.
- The coarse restaurant-wide booking lock intentionally prioritizes Version 1 correctness over throughput. Measurements distinguish whole-group completion from individual child-process lifetime. Five-request contention has exceeded two seconds in recorded runs, and the eight-request burst exceeded two seconds in both group and individual p95 in the targeted rerun. This accepted Version 1 limitation requires later full-stack validation. Lock wait is separately bounded at 3 seconds and is a retryable technical failure, not a latency success.

Changing an operation signature, result shape, stable outcome/detail, grant expectation, temporal meaning, retry rule, or transaction semantic requires an explicitly approved PostgreSQL Contract revision. Hard Gate 1 approval does not authorize such a change. This contract defines no endpoint, HTTP, JSON, CORS, Flask architecture, or UI decision.

## Approval record

Abdul explicitly approved this PostgreSQL Contract for Flask v1.0 as part of DB-07 Hard Gate 1 on 2026-08-20. That approval includes the documented database performance envelope, the general exact-allocation p95 measurements, and the accepted coarse-lock contention limitation. Complete validation of the two-second form-submission expectation remains assigned to the later Flask and full-stack integration performance gates.

Version 1.1 applies the explicitly approved API08-RC-01 reconciliation on 2026-08-24. It changes only the outcome paired with `duration_or_party_size_out_of_range` for an invalid server-controlled reservation duration, from `invalid_request` to `invalid_database_configuration`. Caller-controlled party-size failures remain `invalid_request`; no signature, result column, detail identifier, schema, role, grant, lock, allocation, retry, or other outcome semantic changes.

The approval authorizes only API-01, a design-only backend operation inventory, after a separate instruction. It does not authorize Flask implementation, REST-contract design, API-02 or later increments, React work, or changes to this approved contract.
