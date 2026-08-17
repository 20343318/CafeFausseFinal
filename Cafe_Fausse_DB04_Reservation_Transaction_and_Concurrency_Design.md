# Cafe Fausse DB-04 Reservation Transaction and Concurrency Design

**Document version:** 1.0  
**Established:** 2026-08-17  
**Roadmap increment:** DB-04  
**Authoritative sources:** `SRS(1).pdf`, `Rubric(1).pdf`, Project Requirements Addendum 2.2.1 (PRA-001 through PRA-029), approved DB-01 Persistent-Data Requirements Analysis 1.2.1, approved DB-02 Conceptual Data Model 1.2, approved DB-03 Logical PostgreSQL Schema and Integrity Design 1.1, and approved Least-to-Most Implementation Roadmap 1.1.1  
**Scope:** Reservation transaction and concurrency behavior only  
**Status:** Complete - awaiting approval  
**Code status:** No SQL or application code generated

## 1. Executive summary

DB-04 selects a correctness-first PostgreSQL design with these principal decisions:

1. **Authoritative booking transaction:** customer resolution, exact-retry recognition, overlap checks, allocation, optional contact population, booking-linked newsletter mutation, reservation creation, and every assignment occur in one database transaction.
2. **Isolation:** booking uses PostgreSQL `READ COMMITTED` plus an exclusive transaction-scoped advisory lock for the single Version 1 restaurant booking domain.
3. **Coordination:** every booking and every controlled change to reservation configuration, recurring hours, or table capacity must acquire that same restaurant lock before reading or changing authoritative booking facts. The lock is released automatically at commit or rollback.
4. **Customer concurrency:** a second transaction-scoped advisory lock derived from canonical email serializes creation/reuse and newsletter writes for that email. An existing customer row is then locked before matching or mutation.
5. **Lock order:** restaurant booking lock; configuration row; all seven operating-hours rows in weekday order; all 30 restaurant-table rows in table-number order; canonical-email lock; existing customer row; reservation/assignment reads and writes. Dedicated newsletter transactions acquire only the email lock and customer row, in that order.
6. **Availability:** displayed availability is a read-only snapshot and never reserves inventory. Booking repeats all validations after obtaining the restaurant lock.
7. **Retry identity:** PostgreSQL generates a version-1 SHA-256 fingerprint with `pgcrypto` from an unambiguous canonical serialization of only resolved customer ID, canonical start instant, and party size. Fingerprint lookup is non-unique and every match is verified against the underlying tuple. The DB-03 unique tuple remains the ultimate duplicate backstop.
8. **Allocation:** free tables are derived for the complete half-open interval. An exact meet-in-the-middle algorithm minimizes table count, then unused capacity, then randomly chooses an equal-best candidate. Only the winner is persisted.
9. **Atomicity:** a new booking either commits one customer resolution, one reservation, and a complete capacity-sufficient assignment set, including any booking-linked newsletter change, or leaves none of those attempted changes.
10. **Recovery:** transient lock/deadlock failures receive bounded full-transaction retries. An ambiguous post-commit outcome is resolved by ordinary resubmission, which returns the existing reservation and current newsletter state without replaying the newsletter action.

The restaurant-wide lock intentionally permits only one authoritative booking decision at a time. With 30 tables and a short in-database operation, this is the least complex design that gives an explainable proof against double booking, same-customer write skew, and partial multi-table assignment. DB-06 must measure rather than assume compliance with the SRS two-second submission expectation.

## 2. Scope and DB-03 compatibility assessment

This design uses the six DB-03 tables without changing them:

- `customers`;
- `reservation_configuration`;
- `restaurant_operating_hours`;
- `restaurant_tables`;
- `reservations`;
- `reservation_table_assignments`.

It preserves every approved column, type, primary key, foreign key, unique constraint, check constraint, and index. It does not add a table, column, copied interval, status, availability row, candidate row, audit value, or configuration relationship.

The design requires later implementation objects and controls, not logical-schema changes:

- one conceptual database booking operation;
- one stable restaurant-booking advisory-lock key;
- one canonical-email advisory-lock derivation;
- the `pgcrypto` extension for SHA-256 digest generation;
- database roles that prevent ordinary callers from bypassing the authoritative operations;
- test-only deterministic access to the allocation tie-rank selector.

These items implement DB-03; they do not alter its six-table logical design. No DB-03 change or new business rule is required.

## 3. Selected isolation and concurrency-control strategy

### 3.1 Primary selection

| Design element | Selection |
|---|---|
| Booking isolation | `READ COMMITTED` |
| Booking coordinator | Exclusive transaction-scoped PostgreSQL advisory lock for the one Version 1 restaurant booking domain |
| Customer coordinator | Transaction-scoped advisory lock derived from canonical email, followed by a customer-row lock when the row exists |
| Configuration/hours/capacity consistency | Shared row locks taken after the restaurant lock; all controlled writers use the same restaurant lock |
| Table conflict protection | Restaurant lock serializes the final free-table decision and assignment commit; table rows are read/locked in ascending number before selection |
| Release | Automatic on transaction commit or rollback |
| Direct access control | Application and test callers invoke controlled database operations; ordinary roles receive no unrestricted reservation/customer/configuration DML path |

The restaurant lock must be acquired in a statement that performs no business read. Any wait completes before later `READ COMMITTED` statements take their snapshots. Consequently, a booking that acquires the lock after another booking commits sees that committed booking during its later revalidation.

### 3.2 Correctness proof

The proof depends on four facts:

1. At most one transaction that can make a booking allocation decision holds the restaurant lock.
2. The holder derives customer overlap and free tables only after obtaining the lock and from currently committed rows.
3. The holder keeps the lock through reservation and assignment writes and through commit or rollback.
4. The next booking holder re-reads the committed facts before deciding.

Therefore two overlapping requests cannot both observe the same table as free and commit it. They cannot pass a same-customer overlap check concurrently either. A multi-table winner is decided and persisted while no competing booking can change the reservation/assignment set.

Customer creation and newsletter updates are separately serialized per canonical email. This covers interaction with the independent newsletter operation, which does not need the restaurant lock.

### 3.3 Alternatives considered

| Alternative | Strength | Reason not selected for Version 1 |
|---|---|---|
| `READ COMMITTED` with only selected-table row locks | Allows more parallelism. | A multi-table request must choose a set before it knows which rows to lock. Concurrent requests can make incompatible choices or write-skew across overlapping candidate sets unless a more complex protocol is proved. |
| `REPEATABLE READ` alone | Stable snapshot. | PostgreSQL repeatable read does not by itself prevent every predicate/write-skew conflict involved in “no overlapping assignment exists.” |
| `SERIALIZABLE` with retry | PostgreSQL detects serialization anomalies and can protect predicate-based decisions. | Correct but produces an additional retry/error model and is harder to demonstrate. The 30-table Version 1 system does not need its higher concurrency. |
| `SERIALIZABLE` plus the coarse lock | Strong defense in depth. | The serializable layer is redundant when all authoritative booking decisions are already serialized and controlled writers follow the same protocol. |
| Exclusion constraints/range indexes | Strong declarative overlap protection. | DB-03 deliberately stores occupancy only on `reservations`, while the table identity is on assignments. A direct exclusion design would require copied interval data or a redesigned relation, changing approved DB-03. |
| Transaction-scoped advisory locks per table | Can allow disjoint bookings concurrently. | Candidate generation and random choice occur before the winning set is stable. Proving deadlock-free retries across intersecting multi-table candidates is disproportionately complex. |
| Per-customer lock only | Protects same-customer overlap. | Does not protect different customers competing for the same tables. |
| Process-local mutex | Simple in one process. | Does not coordinate multiple Flask workers, application servers, mobile/third-party callers, or direct database sessions. |

### 3.4 Advisory-lock protocol and database authority

Advisory locks are cooperative PostgreSQL locks. Their correctness is enforced operationally by placing the booking logic in one controlled database operation and restricting direct table mutation for ordinary roles. Development concurrency tests call the same operation from independent sessions. Administrative configuration operations also follow the published lock protocol.

A privileged session that deliberately bypasses both the database operation and role restrictions is outside ordinary Version 1 workflows, just as a superuser could bypass other application controls. DB-05 and DB-06 must verify the intended roles cannot bypass the operation.

## 4. Exact transaction boundary

### 4.1 Included in one new-booking transaction

- acquire concurrency locks;
- read and validate the complete current configuration, seven-day recurring schedule, and 30-table inventory;
- interpret the requested restaurant-local start unambiguously;
- derive immutable `ends_at`;
- revalidate window, lead, alignment, hours, duration, and capacity;
- resolve or provisionally create the customer;
- validate customer name and optional-field rules;
- generate the fingerprint;
- detect exact retry or fingerprint collision;
- reject a different same-customer overlap;
- derive free tables;
- select the exact ranked winner;
- apply permitted blank middle-initial/phone population for a new booking;
- apply subscribe/unsubscribe/no-change behavior for a new booking;
- insert one reservation;
- insert all assignments in ascending table-number order;
- assert final completeness, capacity, identity, and exclusivity postconditions;
- commit.

Any failure before commit rolls back every mutation made by the attempt, including a newly created customer or optional-field/newsletter update.

### 4.2 Excluded from the transaction

- React state and submit disabling;
- prior availability results;
- confirmation-email comparison, which Flask completes before the transaction;
- API response mapping and user-facing wording;
- delivery of email or SMS;
- persistent availability, holds, queues, or candidates;
- later configuration administration details.

### 4.3 Exact-retry transaction boundary

An exact retry obtains the same locks and validates identity, then returns the existing reservation, assignments, interval, party size, and current newsletter state. It performs no contact, newsletter, reservation, or assignment mutation. The read-only result commits normally so the locks are released cleanly.

## 5. Transaction inputs and normalization boundary

Flask supplies these already normalized values to the database operation:

| Input | Boundary rule |
|---|---|
| First name | Unicode-aware trim/collapse completed; display spelling retained; 1-100 and letter rule validated |
| Middle initial | Omitted or one uppercase alphabetic character without period |
| Last name | Same normalization and validation as first name |
| Canonical email | Trimmed lowercase canonical value, no more than 254 characters |
| Phone | Omitted or validated display value; normalized digits available transiently for comparison |
| Selected start | Restaurant-local date/clock selection represented as an unambiguous instant, with sufficient local components/offset for database round-trip validation against the current configured timezone |
| Party size | Integer |
| Newsletter action | Exactly subscribe, unsubscribe, or no change |

The database recomputes or resolves all authoritative identities and booking facts. No caller supplies customer ID, reservation ID, fingerprint, end time, duration, table number, candidate set, availability flag, configuration value, or newsletter history.

Confirmation email is compared to canonical email by Flask and is never passed as persistent data.

## 6. Deterministic lock order

### 6.1 Booking order

1. Begin transaction.
2. Acquire the transaction-scoped restaurant-booking advisory lock.
3. Lock/read the singleton `reservation_configuration` row.
4. Lock/read all `restaurant_operating_hours` rows in ascending `weekday` order.
5. Lock/read all `restaurant_tables` rows in ascending `table_number` order.
6. Acquire the canonical-email transaction-scoped advisory lock.
7. Lock the matching `customers` row when present, or create the new row while the email lock is held.
8. Read reservations and assignments needed for retry/overlap/availability.
9. Insert the reservation, then assignment rows in ascending `table_number` order.
10. Commit or roll back; PostgreSQL releases all locks.

The production random choice is made only after all restaurant-table rows have been read/locked in deterministic order. It never changes lock order.

### 6.2 Other operation order

| Operation | Required order |
|---|---|
| Independent newsletter preference | Canonical-email advisory lock; matching customer row; update/commit |
| Customer/newsletter creation | Canonical-email advisory lock; lookup; insert or row lock; match/update/commit |
| Configuration update | Restaurant-booking advisory lock; configuration row; validate/update/commit |
| Recurring-hours update | Restaurant-booking advisory lock; weekday rows in ascending order; validate/update/commit |
| Table-capacity update | Restaurant-booking advisory lock; all affected table rows in ascending table number; validate/update/commit |

A dedicated newsletter transaction never attempts to acquire the restaurant lock after obtaining an email lock. Configuration operations never acquire customer locks. This removes the lock-order cycle that would otherwise permit a deadlock.

### 6.3 Deadlock and timeout handling

- Deterministic ordering makes expected deadlocks exceptional.
- A PostgreSQL-detected deadlock aborts one full transaction and is a retryable technical conflict.
- Lock acquisition uses a bounded database lock timeout selected during DB-05/DB-06 deployment design. Timeout is not “unavailable”; it is a transient technical result.
- A caller retries only from the transaction beginning, re-acquiring locks and re-reading every authoritative value.
- Exhausted attempts return a safe temporary-failure outcome; no partial state remains.

## 7. Provisional availability design

### 7.1 Read-only operation

Availability uses one short read-only consistent snapshot, preferably one database statement or a read-only `REPEATABLE READ` transaction. It does not obtain the restaurant booking lock and holds no lock after returning.

Within the snapshot it:

1. requires exactly one valid configuration row;
2. requires seven valid operating-hours rows;
3. requires exactly 30 restaurant-table rows with positive capacities;
4. validates the requested restaurant-local date and integer party size;
5. derives the current restaurant-local date/time from database time and configured timezone;
6. applies the inclusive advance window and same-day lead time;
7. retrieves the requested weekday opening and closing boundaries;
8. generates every start aligned to the current interval from opening onward;
9. derives each end with the current duration;
10. keeps only starts whose complete interval ends at or before close;
11. derives tables with no overlapping assignment for each interval;
12. marks the slot available if an exact capacity-sufficient combination exists;
13. returns every legitimate aligned start with provisional available/unavailable state.

It persists no slot, availability, free table, candidate combination, or random outcome.

### 7.2 Why revalidation is mandatory

The read snapshot can become stale immediately after it ends. Another booking may commit, or configuration/hours/capacity may change before submission. The booking operation therefore treats the selected start as a request, never as a promise, and repeats all authoritative checks while holding the restaurant lock.

## 8. Authoritative booking-validation order

The following order controls DB-06 implementation:

1. Flask rejects malformed or non-normalizable input before database work.
2. Begin a `READ COMMITTED` database transaction.
3. Set bounded transaction/lock timing controls.
4. Acquire the exclusive restaurant-booking transaction lock before any business read.
5. Lock and read the singleton configuration row.
6. Lock/read all seven weekday rows in weekday order and verify identities 1 through 7.
7. Lock/read all restaurant tables in table-number order and verify exactly 30 positive-capacity rows.
8. Validate the configured timezone against the database-supported timezone catalogue.
9. Capture authoritative database wall-clock time after lock acquisition.
10. Round-trip the requested start through the configured timezone, rejecting a nonexistent, ambiguous, offset-inconsistent, or otherwise noncanonical local instant.
11. Derive `ends_at` from `starts_at` plus the current approved duration.
12. Revalidate the local date, inclusive advance window, same-day lead, start alignment, opening boundary, and end-at-or-before-close boundary.
13. Revalidate approved duration, positive party size, and party size no greater than the sum of all current table capacities.
14. Acquire the canonical-email lock.
15. Resolve the customer by canonical email. If absent, insert one provisional row; if present, lock it.
16. Validate first/last name matching. Determine, but do not yet apply, permissible blank middle-initial/phone population. Record a nonblocking notice condition for a differing existing phone.
17. Generate fingerprint version 1 inside PostgreSQL from resolved customer ID, canonical start, and party size.
18. Search fingerprint-version/fingerprint candidates and compare every candidate's underlying tuple.
19. Search the unique underlying tuple as a compatibility/race backstop. If found, return exact retry without applying planned contact or newsletter changes.
20. If not a retry, reject any different reservation for this customer whose half-open interval overlaps the request.
21. Derive tables free for the complete interval from current tables, assignments, and parent reservations.
22. Run the exact candidate algorithm. If no candidate exists, return authoritative unavailable/full.
23. Randomly choose one equal-best candidate and sort its table numbers ascending for persistence.
24. Recheck database wall-clock rules if the transaction has crossed a lead/window boundary while waiting or calculating.
25. Apply permitted middle-initial/phone population for this new booking path only.
26. Apply subscribe, unsubscribe, or no-change to the customer for this new booking path only.
27. Insert one reservation with database-generated ID, resolved customer, immutable interval/party size, and generated fingerprint/version.
28. Insert all winning assignment rows in ascending table-number order.
29. Assert in-transaction postconditions: one reservation, one-or-more unique assignments, assigned capacity covers party size, no other overlap on selected tables, no different same-customer overlap, and exact stored fingerprint facts.
30. Commit.
31. Only after commit success may Flask return the captured confirmation outcome. If commit outcome is ambiguous, Flask does not guess; ordinary resubmission invokes exact-retry recovery.

The sequence differs slightly from the prompt's illustrative order because optional customer/contact mutation is deliberately deferred until after exact-retry and availability decisions. This is necessary to prove that an exact retry and an unavailable request make no customer/contact/newsletter change.

## 9. Customer creation and reuse under concurrency

### 9.1 New canonical email

- The email advisory lock makes “no customer exists” stable against other conforming customer/newsletter operations for that email.
- A new customer is inserted inside the booking transaction with validated name, optional fields, and the required Boolean default.
- Newsletter action is applied only after the booking has an eligible table winner.
- If booking later fails, insertion and any preference change roll back.
- The unique email constraint is a final backstop. If an unexpected concurrent writer wins despite the protocol, the current transaction is restarted and resolves the committed row rather than exposing a unique-constraint error.

### 9.2 Existing canonical email

With the customer row locked:

| Input condition | Transaction behavior |
|---|---|
| First/last match case-insensitively after approved normalization | Continue |
| First/last mismatch | Reject generically; no mutation |
| Middle initial omitted | Preserve stored value |
| Stored middle initial blank and supplied valid value | Plan population only on successful new booking |
| Both populated and equal | Continue unchanged |
| Both populated and conflict | Reject; no mutation |
| Phone omitted | Preserve stored value |
| Stored phone blank and supplied valid phone | Plan population only on successful new booking |
| Stored phone differs by normalized digits | Preserve stored value; booking may continue with a notice condition |

No path becomes a general profile-update operation.

### 9.3 Concurrent scenarios

| Scenario | Resolution |
|---|---|
| Two bookings for same new email | Restaurant lock serializes them. The first may create and book; the second resolves the customer and becomes exact retry, overlap conflict, or a later nonoverlapping booking. |
| Booking versus newsletter-only signup | Both contend on the email lock. The later holder sees the earlier committed customer/state. Matching identity proceeds; conflicting identity rejects. |
| Two blank-field population attempts | Email/customer locks serialize them. The first committed valid value becomes stored; the second preserves it if equal, rejects a conflicting middle initial, or preserves differing phone with notice. |
| Unique-email conflict from a nonconforming writer | Constraint prevents duplication. The booking rolls back/restarts, re-resolves, and applies normal identity rules. |

### 9.4 Last-committed newsletter behavior

The email lock is held until commit. A later newsletter or booking transaction reads the state committed by the earlier holder and may set its requested final Boolean. Therefore the last transaction to obtain the lock and commit its valid update supplies the final state, matching PRA-021.

## 10. Fingerprint generation and exact retry

### 10.1 Version-1 fingerprint specification

| Item | Decision |
|---|---|
| Algorithm | SHA-256 |
| PostgreSQL capability | `pgcrypto` digest capability |
| Stored form | Raw 32-byte digest in DB-03 `BYTEA` |
| Semantic version | `fingerprint_version = 1` |
| Business inputs | Resolved positive decimal `customer_id`; canonical UTC `starts_at`; positive decimal `party_size` |
| Excluded | Name, email text, middle initial, phone, newsletter state/action, tables, end, duration, configuration, hours |

Version 1 serializes the three values as UTF-8 fields in the fixed order customer, start, party. Each field is encoded as an ASCII decimal byte-length, a colon, and its canonical value. Fields are separated by a single ASCII vertical bar. Length-prefixing prevents ambiguous concatenation.

Canonical values are:

- customer ID: unsigned base-10 digits with no sign or leading zeros;
- start: UTC ISO-8601 form `YYYY-MM-DDTHH:MM:SS.ffffffZ`, with exactly six fractional-second digits;
- party size: unsigned base-10 digits with no sign or leading zeros.

The semantic version selects this serialization and algorithm; it is not a fourth business input. Any future version must retain tuple-first compatibility for previously stored reservations. DB-04 selects no future algorithm.

### 10.2 Lookup and collision order

1. Generate the current version and fingerprint.
2. Use the non-unique fingerprint index to retrieve all same-version candidates.
3. Compare `customer_id`, `starts_at`, and `party_size` for each candidate.
4. A full tuple match is an exact retry.
5. A fingerprint match with different tuple values is a collision only and is ignored for equality and mutation.
6. If the fingerprint candidates contain no tuple match, query the DB-03 unique underlying tuple. This protects future version transitions and unexpected concurrent insert races.
7. If the tuple exists, return it as the one logical reservation; otherwise continue as a new request.

### 10.3 Exact-retry result

An exact retry returns:

- existing `reservation_id`;
- existing `starts_at`, `ends_at`, and `party_size`;
- every existing assigned table number;
- current `customers.newsletter_subscribed`.

It creates no row, changes no contact field, ignores submitted newsletter action for mutation, and does not reconstruct the newsletter state from the original booking.

### 10.4 Concurrent identical requests

The restaurant lock makes the second request wait for the first transaction's commit or rollback. After a commit it finds the existing tuple and returns exact retry. After a rollback it may proceed as the original booking. The unique underlying tuple independently guarantees that at most one equivalent reservation can commit.

## 11. Same-customer overlap

For existing interval `[a_start, a_end)` and proposed `[b_start, b_end)`, overlap is:

`a_start < b_end` and `b_start < a_end`.

Exact retry is evaluated first. A non-retry is rejected if any retained reservation for the same customer satisfies this predicate.

| Shape | Result |
|---|---|
| Same start, different party size | Different identity; overlaps; reject |
| Proposed start inside existing | Reject |
| Proposed interval contains existing | Reject |
| Proposed interval contained by existing | Reject |
| Proposed end equals existing start | Allow, subject to availability |
| Proposed start equals existing end | Allow, subject to availability |
| Old past interval with no overlap | Does not block; row remains retained |

Because every new booking performs this check while holding the restaurant lock through commit, two nonidentical overlapping requests from one customer cannot both pass.

## 12. Table availability and exclusive occupancy

A table is free only if no assignment for that `table_number` joins to a reservation satisfying the half-open overlap predicate against the requested interval.

The derivation uses current `restaurant_tables`, `reservation_table_assignments`, and immutable parent `reservations.starts_at`/`ends_at`. It does not copy intervals into assignments.

| Interval relationship | Table state |
|---|---|
| Partial overlap | Busy |
| Requested interval contains existing | Busy |
| Requested interval contained by existing | Busy |
| Identical interval | Busy |
| Existing ends at requested start | Free |
| Requested ends at existing start | Free |
| Retained past reservation with ended interval | Free for a later nonoverlapping interval |

Different customers may hold overlapping reservations only when their final assigned table sets are disjoint and each reservation has sufficient capacity. Unused seats on an assigned table are unavailable to all overlapping requests.

## 13. Exact multi-table candidate algorithm

### 13.1 Inputs

- ascending list of currently free `(table_number, seating_capacity)` pairs;
- positive requested party size.

Unavailable tables are removed before candidate processing.

### 13.2 Exact meet-in-the-middle method

With at most 30 tables:

1. Split the ascending free-table list into two halves of at most 15 tables each.
2. Enumerate every subset of each half, including empty, recording table count, capacity sum, and ascending table-number tuple. Each half has at most 32,768 subsets.
3. Group the second-half subsets by table count and capacity sum, retaining their deterministic table-number order and group counts.
4. For candidate table count `k` from 1 through the number of free tables:
   - combine each first-half subset with compatible second-half groups whose counts sum to `k`;
   - find the smallest combined capacity at least party size using the grouped/sorted capacity sums;
   - stop at the first `k` for which at least one capacity-sufficient combination exists.
5. The first successful `k` is the exact minimum table count.
6. The smallest qualifying combined capacity for that `k` is the exact least waste; waste equals combined capacity minus party size.
7. Count every distinct pair of half-subsets that attains both optima without materializing a potentially huge full candidate list.
8. Choose one tie rank, then walk the deterministic grouped representation to reconstruct exactly that winning full subset.
9. Sort the winning table numbers ascending and persist only those assignments.

This method is exhaustive, not heuristic. Its bounded subset enumeration is practical for 30 tables even when all capacities are identical. It also avoids materializing all equal combinations; for example, it can count and select among a very large set of equal 15-of-30 combinations.

### 13.3 No candidate

If no `k` yields capacity at least party size, the authoritative booking result is unavailable/full. No reservation, assignment, planned customer-field population, or booking-linked newsletter mutation commits.

## 14. Random tie selection and deterministic test seam

PostgreSQL selects a production tie rank only after table count and capacity waste are fixed. Every equal-best combination corresponds to one rank in deterministic table-number order and has a nonzero selection opportunity. Production uses PostgreSQL's built-in random facility to choose the rank; random values never influence lock order.

Testability is separated from production behavior:

- the pure candidate selector conceptually accepts a tie-rank value;
- the production booking wrapper always supplies a database-generated random rank;
- database unit tests may invoke a test-only wrapper/role that supplies fixed ranks;
- the public booking operation and Flask never accept a rank or seed;
- no seed, rank, candidate, or random history is stored.

Deterministic tests prove every rank reconstructs an eligible equal-best combination and that out-of-range ranks fail. A nonblocking statistical smoke test may observe repeated production choices, but correctness tests must not depend on probabilistic frequency thresholds.

## 15. Configuration, schedule, and capacity consistency

The restaurant lock and row locks create a coherent decision set:

- a booking locks and reads the singleton configuration;
- it locks and validates all seven hours rows;
- it locks and validates all 30 table rows/capacities;
- it retains those locks through commit/rollback;
- controlled updates obtain the same restaurant lock first.

Thus an update either commits before the booking lock is acquired, in which case booking sees and revalidates the new state, or waits until after booking commits, in which case the booking uses the coherent pre-change state.

No configuration, schedule, or capacity update modifies an existing reservation interval, party size, fingerprint, or assignment. Changes remain prospective.

## 16. Newsletter behavior inside booking

| Booking path | Newsletter behavior |
|---|---|
| New reservation + subscribe | Set final Boolean true only after an eligible winner exists; commit with reservation/assignments |
| New reservation + unsubscribe | Set final Boolean false under the same atomic rule |
| New reservation + no change | Preserve current value |
| Exact retry | Ignore submitted action for mutation; return current stored value |
| Booking failure | Roll back any attempted change |
| Independent concurrent update | Email/customer locks serialize writes; later committed valid set wins |

The booking response uses the newsletter state produced or observed while its transaction holds the customer lock. No history or reservation snapshot is added.

## 17. Atomic persistence postconditions

### 17.1 New booking

Immediately before commit the transaction asserts:

- exactly one resolved customer;
- exactly one new reservation;
- one or more unique assignments;
- assigned-capacity sum is at least party size;
- every selected table was free over the complete interval at the serialized decision point;
- no other overlapping reservation exists for the same customer;
- stored fingerprint/version matches the specified three inputs;
- DB-03 exact identity is unique;
- all assignments refer to the new reservation and current tables;
- contact/newsletter effects equal the approved new-booking rules.

Any failed assertion raises a database operation failure and rolls back the entire transaction.

### 17.2 Exact retry

- no new business row;
- no customer/contact/newsletter mutation;
- existing reservation and all assignments returned;
- current newsletter state returned.

## 18. Transaction retry policy

### 18.1 Internal retries

| Outcome | Internal retry? | Rule |
|---|---:|---|
| Deadlock victim | Yes | Restart complete transaction |
| Lock timeout | Yes, if operation deadline permits | Restart after bounded backoff |
| Serialization failure | Yes, though not expected under selected isolation | Restart complete transaction |
| Unique-email race | Yes | Restart and re-resolve customer |
| Exact-identity unique race | Resolve, not blindly repeat insert | Restart/lookup; return exact retry only after tuple verification |
| Connection failure before known commit | No blind continuation | Discard connection; caller may resubmit ordinary data |
| Validation/business conflict/unavailable | No | Return classified outcome |

The default principle is a small bounded number of full-transaction attempts, recommended as three total attempts, subject to one overall operation deadline. Backoff uses short exponential delay with jitter. DB-06 may tune timing from measured tests without changing the bounded principle.

Every retry re-acquires locks, re-reads configuration/hours/tables/customer state, regenerates the fingerprint, and reruns overlap/allocation. No partial transaction is resumed.

### 18.2 Newsletter replay safety

If a prior attempt actually committed but its response was lost, resubmission becomes exact retry before newsletter mutation. Therefore the original action is not applied again and cannot overwrite a later independent preference change.

### 18.3 Exhaustion

After bounded attempts or the overall deadline, Flask receives a retryable technical outcome. It returns a safe temporary-failure/retry result and logs diagnostic details without claiming the reservation failed if commit status is genuinely unknown.

## 19. Failure and rollback matrix

| Case | Classification | Commit/rollback | Internal retry | Safe resubmit | Persistent state and later Flask duty |
|---|---|---|---:|---:|---|
| Malformed input before transaction | Validation failure | No transaction | No | After correction | None; map field error |
| Missing/duplicate/invalid configuration | Environment/configuration failure | Rollback | No | Not until repaired | None; log and return safe temporary failure |
| Incomplete operating-hours schedule | Environment/configuration failure | Rollback | No | Not until repaired | None; log failed readiness |
| Unexpected table count | Environment/configuration failure | Rollback | No | Not until repaired | None; do not book from partial inventory |
| Invalid timezone | Environment/configuration failure | Rollback | No | Not until repaired | None; safe technical outcome |
| Date outside window | Validation failure | Rollback/read-only | No | With valid date | None; map business validation |
| Insufficient same-day lead | Validation failure/unavailable | Rollback/read-only | No | With later start | None; refresh slots |
| Misaligned start | Validation failure | Rollback | No | With supplied legitimate slot | None |
| Start before open | Validation failure | Rollback | No | With valid start | None |
| End after close | Validation failure | Rollback | No | With valid start | None |
| Party size outside derived maximum | Validation failure | Rollback | No | With valid party size | None |
| Email/name mismatch | Business identity conflict | Rollback | No | Only with matching identity | No mutation; generic safe outcome |
| Middle-initial conflict | Business identity conflict | Rollback | No | Only with matching value | No mutation |
| Differing existing phone | Success with notice condition if all else succeeds | Commit booking | No | Yes | Stored phone unchanged; Flask later supplies approved notice |
| Exact retry | Success-existing | Commit read-only | No | Yes | Existing rows only; current newsletter returned |
| Fingerprint collision, tuple differs | Continue normal flow | Depends on later result | No | Yes | Collision alone changes nothing |
| Same-customer overlap | Business conflict | Rollback | No | With nonoverlapping request | No attempted mutation |
| No free capacity-sufficient combination | Unavailable/full | Rollback | No | Yes after refreshed availability | No attempted mutation remains |
| Unique-email race | Retryable technical race | Rollback/restart | Yes | Yes | At most other committed customer; re-resolve |
| Exact-identity unique conflict | Retry candidate/race | Rollback/restart and verify | Yes | Yes | At most one reservation; never infer equality from hash alone |
| Concurrent table conflict | Normally serialized; timeout if wait exceeds bound | Rollback/retry | Yes within bound | Yes | No overbooking; refresh if later unavailable |
| Deadlock | Retryable technical conflict | PostgreSQL rollback | Yes | Yes | None from victim transaction |
| Serialization failure | Retryable technical conflict | PostgreSQL rollback | Yes | Yes | None from failed transaction |
| Lock timeout | Retryable technical conflict | Rollback | Bounded | Yes | None |
| Unexpected database error | Unexpected failure | Rollback | Only if explicitly classified transient | Yes, using retry identity | None from failed transaction; log safely |
| Failure after customer insertion | Unexpected/injected failure | Rollback | Test-dependent | Yes | New customer removed |
| Failure after optional-field population | Unexpected/injected failure | Rollback | Test-dependent | Yes | Original customer fields restored |
| Failure after newsletter update | Unexpected/injected failure | Rollback | Test-dependent | Yes | Prior newsletter state restored |
| Failure after reservation insertion | Unexpected/injected failure | Rollback | Test-dependent | Yes | No reservation remains |
| Failure after one/more assignments | Unexpected/injected failure | Rollback | Test-dependent | Yes | No reservation or assignments remain |
| Connection loss before commit begins | Unknown to Flask but transaction rolls back when session ends | Rollback expected | No same connection retry | Yes | Exact retry/new booking resolves actual state |
| Connection loss during commit | Ambiguous network outcome | Database may commit or roll back | Do not guess | Yes | Resubmission returns existing or safely books anew |
| Connection loss after commit | Committed but response lost | Commit | No mutation replay | Yes | Exact retry returns existing confirmation/current newsletter |

## 20. Network ambiguity recovery

After a timeout or lost connection, React, mobile, or a third-party client resubmits ordinary reservation data. The database resolves the canonical email/customer, regenerates the fingerprint, and verifies the unique tuple.

- If the original committed, the replay returns the one reservation and its assignments.
- If the original rolled back, the replay may create a new booking after current validation.
- If availability changed after rollback, the replay may return unavailable.
- If newsletter state changed independently after the original commit, exact retry returns the current state and ignores the replayed action.

No client-generated idempotency key or fingerprint is required.

## 21. PostgreSQL-versus-Flask responsibility matrix

| Rule/capability | PostgreSQL | Flask | Derived/display/excluded |
|---|---|---|---|
| Customer/email uniqueness | Constraint plus email/customer locks | Canonicalizes and maps outcome | React provisional only |
| Unicode name/email/phone format | Declarative defense in depth | Authoritative request normalization/format validation | Confirmation email transient |
| Customer matching/population rules | Row lock and atomic persistence | Supplies normalized comparisons and maps notice/conflict | No profile workflow |
| Current configuration/hours/tables | Authoritative rows and locks | Invokes operation; may expose safe reads later | React owns no constants |
| Current database time/timezone conversion | Authoritative validation | Supplies unambiguous normalized start and maps error | Browser clock non-authoritative |
| Fingerprint | Generates, stores, indexes, collision-verifies | Never generates; returns mapped outcome | Client need not retain it |
| Exact retry | Candidate lookup plus tuple verification | Resubmits ordinary data/maps confirmation | Newsletter action not replayed |
| Same-customer overlap | Checks under restaurant lock | Maps business conflict | React cannot enforce |
| Free-table determination | Derived under restaurant lock | Does not duplicate final allocation | Availability response is provisional |
| Candidate ranking/random winner | Exact database operation | No table choice | Candidates/random history not stored |
| Atomic reservation/assignments/newsletter | One database transaction | Opens/commits transaction and handles bounded retries | React submit disable is UX only |
| Transient database conflicts | Emits classified failure | Performs bounded retry/backoff and logs | User gets nontechnical result |
| Commit ambiguity | Durable tuple/fingerprint recovery | Treats as unknown and permits safe resubmit | No false success/failure claim |
| Response/message/API contract | Supplies classified data only | Defined in later API increments | Outside DB-04 |

## 22. PostgreSQL capability and extension assessment

| Capability | Built in/extension | DB-05/DB-06 impact |
|---|---|---|
| `READ COMMITTED` transactions | Built in | Establish transaction and rollback discipline |
| Transaction-scoped advisory locks | Built in | Define stable restaurant key and canonical-email key derivation; document protocol |
| Row locks | Built in | Lock configuration/hours/tables/customer in deterministic order |
| Half-open timestamp comparisons | Built in | Implement strict start-before-other-end predicate; no range column required |
| Identity, unique, check, FK enforcement | Built in | Implement approved DB-03 DDL |
| Random choice | Built in | Production tie-rank generation after deterministic ranking |
| SHA-256 digest | `pgcrypto` extension | DB-05 installs/verifies extension; DB-06 generates 32-byte fingerprints |
| Exception/error signaling | Built in | Database operation emits stable internal outcome classes; API mapping later |
| Lock/statement timeout | Built in | Configure bounded values and test them |
| Database roles/privileges | Built in | Prevent ordinary callers from bypassing controlled write operations |

`pgcrypto` is justified because core PostgreSQL has no equally clear built-in SHA-256 digest for arbitrary canonical bytes. It adds one standard trusted extension and no table-schema change. The fingerprint is not used as proof of equality or as a secret.

No GiST index, range column, exclusion constraint, trigger, queue, or lock table is required.

## 23. Transaction sequence diagrams

### 23.1 Successful new single-table reservation

```mermaid
sequenceDiagram
    participant F as Flask caller
    participant B as PostgreSQL booking operation
    participant D as PostgreSQL tables
    F->>B: Normalized booking request
    B->>B: Begin; restaurant lock; authoritative validation
    B->>D: Resolve/lock customer; verify no retry or overlap
    B->>D: Derive free tables and one-table winner
    B->>D: Apply allowed customer/preference changes
    B->>D: Insert reservation and one assignment
    B->>B: Assert postconditions; commit
    B-->>F: Committed confirmation facts
```

### 23.2 Successful new multi-table reservation

```mermaid
sequenceDiagram
    participant F as Flask caller
    participant B as PostgreSQL booking operation
    participant D as PostgreSQL tables
    F->>B: Normalized larger-party request
    B->>B: Lock and revalidate current rules/inventory
    B->>D: Resolve customer; check retry and overlap
    B->>D: Derive free set; exact rank; choose tie
    B->>D: Insert one reservation
    loop Winning tables in number order
        B->>D: Insert assignment
    end
    B->>B: Verify capacity/completeness; commit
    B-->>F: Confirmation with every table
```

### 23.3 Exact retry after lost response

```mermaid
sequenceDiagram
    participant F as Flask caller
    participant B as PostgreSQL booking operation
    participant D as PostgreSQL tables
    F->>B: Resubmitted ordinary data
    B->>B: Acquire locks; resolve customer; generate fingerprint
    B->>D: Find candidates and verify underlying tuple
    D-->>B: Existing reservation and assignments
    B->>D: Read current newsletter state
    B->>B: Commit with no mutation
    B-->>F: Existing confirmation and current preference
```

### 23.4 Same-customer conflicting overlap

```mermaid
sequenceDiagram
    participant F as Flask caller
    participant B as PostgreSQL booking operation
    participant D as PostgreSQL tables
    F->>B: Different overlapping request
    B->>B: Lock and validate; resolve customer
    B->>D: Fingerprint/tuple is not exact retry
    B->>D: Check retained customer intervals
    D-->>B: Overlap found
    B->>B: Roll back
    B-->>F: Classified business conflict
```

### 23.5 Concurrent requests for overlapping capacity

```mermaid
sequenceDiagram
    participant A as Flask request A
    participant B as PostgreSQL coordinator
    participant C as Flask request B
    A->>B: Acquire restaurant lock
    C->>B: Wait for restaurant lock
    B-->>A: Validate, allocate, commit; release
    B-->>C: Lock granted after A commit
    C->>B: Re-read and revalidate current assignments
    B-->>C: Allocate disjoint capacity or return unavailable
```

### 23.6 Failure after partial in-transaction work

```mermaid
sequenceDiagram
    participant F as Flask caller
    participant B as PostgreSQL booking operation
    participant D as PostgreSQL tables
    F->>B: Normalized booking request
    B->>D: Create/populate customer; change preference
    B->>D: Insert reservation and first assignment
    D-->>B: Injected or unexpected failure
    B->>B: Roll back entire transaction; release locks
    B-->>F: Classified failure; no partial state
```

## 24. Database unit-test plan

| Test group | Non-executable cases and expected result |
|---|---|
| Half-open overlap | Partial left/right, contains, contained, identical all overlap; both endpoint-touch cases do not |
| Hours and configuration | Every permitted interval/duration/window/lead; missing/duplicate invalid state; timezone catalogue validation |
| SRS boundaries | Monday-Saturday 5 PM/11 PM and Sunday 5 PM/9 PM; exact close accepted, one interval late rejected |
| Alternate weekly hours | Different same-day weekday hours change generated starts without code change; seven-row requirement retained |
| Party bounds | 0 rejected; 1 accepted; current total accepted if combination exists; total+1 rejected |
| Capacity derivation | Sum current 30 rows; never use a stored total |
| Single-table eligibility | Capacity sufficient and interval free produces one-table candidate |
| Multi-table eligibility | No single sufficient but exact multi-table combinations exist |
| Minimum table count | Any sufficient smaller-cardinality combination outranks all larger sets |
| Least waste | Within minimum count, smallest sufficient capacity wins |
| Equal ties | Every retained candidate has identical count/waste; non-best candidate never selected |
| Deterministic seam | Each fixed tie rank reconstructs the expected sorted combination; invalid rank rejected |
| Random smoke | Repeated production choices remain within equal-best set and more than one tie can be observed without a flaky frequency assertion |
| No combination | Returns unavailable and persists nothing |
| Same customer | Different overlap rejected; different nonoverlap accepted; different party at same start rejected |
| Different customers | Overlapping intervals may succeed with disjoint table sets |
| Exact retry | Same tuple returns one ID and assignments; no new row or preference mutation |
| Changed party | Not retry; same-start overlap rejected |
| Fingerprint collision | Same bytes/different tuple not equality; legitimate nonoverlap continues |
| Serialization/version | Canonical byte sequences and SHA-256 expected values are stable; excluded inputs do not change version-1 digest |
| Customer creation/reuse | One canonical email; matching reuse; mismatched name rejection |
| Optional fields | Omission preserves; blank population only on successful new booking; conflicting middle rejected; differing phone preserved with notice condition |
| Newsletter | Subscribe/unsubscribe/no-change commit with new booking; forced failure restores prior state; retry never mutates |
| Atomic assignments | One and many insert all-or-none; duplicate pair blocked; injected partial failure leaves zero |
| No derived persistence | No availability, candidate, random, waste, or free/busy row is created |
| Retention | Past reservations remain and do not block later intervals |
| Prospective changes | Current changes affect later bookings while existing interval/party/assignments remain identical |

## 25. Concurrent integration-test plan

All tests use independent PostgreSQL sessions, explicit synchronization barriers, a clean known seed, bounded timeouts, and repeated runs. A pause is a test-harness checkpoint inside the controlled operation; it creates no production business state.

| Scenario | Initial database state | Transaction A | Transaction B and barrier | Permitted outcomes | Required final state and evidence |
|---|---|---|---|---|---|
| Identical concurrent requests | No customer or reservation for the request | Obtain restaurant lock; complete writes; pause immediately before commit | Submit identical request after A holds lock; verify B waits; release A | A commits new booking; B returns exact retry, or B proceeds as new only if A was deliberately rolled back | One customer, one reservation, complete winner; both successes share confirmation ID; no preference replay |
| Different requests, same new email | No customer; two nonoverlapping valid starts | Obtain lock; create provisional customer; pause before commit | Submit same email/matching name at other start while A is paused; release A | Both may commit serially if second remains valid | One customer and two reservations; no duplicate email; each has complete assignments |
| Matching versus mismatching names | No customer or one known canonical customer | Submit valid canonical email/name and pause while holding relevant lock | Submit same email with conflicting name at barrier; then release A | Valid A may commit; conflicting B must reject after it sees committed identity | One customer with valid name; zero mutation from mismatch; B has no reservation |
| Last-table competition | Overlap interval has exactly one sufficient free table | Submit customer A and pause before booking commit | Submit different customer B after A holds restaurant lock; release A | Exactly one new reservation; later request unavailable | Last table appears in one new assignment only; losing customer has no partial booking state |
| Competing single-table requests | Several tables exist but preloaded reservations leave capacity for one additional single-table booking | Submit first overlap request; pause before commit | Submit second different-customer request; verify wait; release A | One commit and one unavailable | No table overlap; one complete reservation; no loser reservation/assignment |
| Competing multi-table requests with partial candidate overlap | Free tables form intersecting candidates but can satisfy only one party | Select/prepare one multi-table winner; pause before commit | Submit second multi-table request while A holds lock; release A | At most one commits | Winner has every required assignment and sufficient capacity; loser has none; no shared table |
| Single-table versus multi-table competition | One scarce table participates in the best candidates for both requests | Submit single-table request and pause before commit; repeat test with multi-table request as A | Submit the other request at barrier; release A | Serial result determined by first commit and remaining disjoint capacity | Both commit only with disjoint winner sets; otherwise later request unavailable; never partial |
| Same-customer different overlapping requests | Existing matching customer; no conflicting reservation initially | Submit first request and pause before commit | Submit nonidentical overlapping request for same customer; release A | At most one commits | Exactly one overlapping reservation for customer; second classified overlap, not exact retry |
| Concurrent back-to-back requests | Sufficient capacity; B starts exactly at A end | Submit earlier interval and pause before commit | Submit endpoint-touching interval; release A | Both may commit, including same table if ranking selects it after A commit | Predicate evidence shows endpoint contact only; each reservation complete |
| Stale provisional availability | Read-only availability reports target open | Book enough target capacity and commit | Submit previously displayed slot only after availability response and while/after A commits | B commits only with remaining disjoint sufficient combination; otherwise unavailable | Final assignments prove booking-time revalidation; no persisted slot state |
| Booking versus table-capacity change | Known capacities and no reservation at target | Booking acquires restaurant lock, reads old capacities, pauses; repeat with updater first | Capacity updater attempts same lock and waits; then reverse order with updater committing before B booking | Booking commits entirely under old state before update, or observes/revalidates new state | Existing booking interval/assignments unchanged; no mixed capacity decision; later derived totals match update |
| Booking versus recurring-hours change | Target valid under one schedule and invalid/different under alternative | Booking locks/reads old hours and pauses; repeat with updater first | Hours updater waits, then reverse order and commit update before booking | Booking uses coherent pre-change schedule or observes new schedule and succeeds/rejects accordingly | No mixed opening/closing values; previously committed reservation unchanged |
| Booking versus scalar-configuration change | Target differs under duration/interval/window/lead/timezone alternative | Booking locks/reads old singleton and pauses; repeat with updater first | Updater waits on restaurant lock; reverse order and commit new setting before booking | Booking uses one complete old or new configuration set | Stored interval has one approved duration; boundary outcomes match the observed configuration |
| Booking newsletter versus dedicated preference update | Existing matching customer with known Boolean | Booking obtains restaurant then email/customer locks, applies action, pauses before commit; repeat order | Dedicated update attempts email lock and waits; reverse order in second run | Both valid operations commit serially | Final Boolean equals later committed set; booking and assignments remain intact; no history row |
| Failure after customer creation | No customer | Create provisional customer, then inject failure at barrier | Observer/session B waits for rollback, then queries or safely retries | A rolls back; B may book normally afterward | No A customer/reservation/assignment remains; B sees clean state |
| Failure after customer-field population | Existing customer with blank optional field | Populate field provisionally, then inject failure | B waits on email lock, then reads customer after rollback | A rolls back | Optional field remains original blank value; B observes no partial update |
| Failure after newsletter update | Existing customer with known Boolean | Change Boolean provisionally, then inject failure | B waits, then reads/updates after rollback | A rolls back | Original Boolean restored until any valid B commit |
| Failure after reservation insertion | Valid customer and winner | Insert reservation, then inject before assignments | B waits for restaurant lock and queries/retries after rollback | A rolls back; B may proceed | No A reservation or assignments; exact identity free unless B commits |
| Failure after partial assignment insertion | Multi-table winner | Insert reservation and first assignment, then inject failure | B waits, then queries/retries after rollback | A rolls back; B may proceed | Zero A reservation and zero A assignments; no table remains blocked by partial work |
| Forced deadlock | Test-only unrelated lock resources available; clean booking state | Hold test lock X, then request Y around controlled call | Hold Y, then request X at barrier | PostgreSQL aborts a victim; bounded retry may later commit one/both nonconflicting operations | Victim has no partial state; outcome classified deadlock/retry; business invariants hold |
| Lock timeout | Valid request; short test lock timeout | Hold restaurant lock beyond B timeout, then commit or roll back | Start B after A lock confirmed; allow B timeout | A outcome independent; B retries within budget or exhausts as technical failure | B is never labeled business unavailable solely due to timeout; no partial B state |
| Connection loss after commit | No exact reservation initially | Commit booking, then cut connection before response delivery | Resubmit identical ordinary data after A commit confirmed by harness | A commit remains; B exact-retry success | One reservation; same confirmation; current newsletter returned; replay action ignored |
| Repeated clean runs | Reset to exact SRS/configuration/30-table baseline before each run | Execute each A script with controlled random/test rank | Execute each paired B script at documented barrier | Only scenario-permitted outcomes across all iterations | Row counts, unique keys, overlap joins, assignment completeness, capacity coverage, and classified outcomes always pass |

For every row, evidence includes both session outcomes, committed row counts, duplicate-email and exact-identity checks, a join proving no table has two overlapping reservations, and checks that each committed reservation has one-or-more assignments and sufficient capacity under the test's locked booking state.

## 26. Performance and explainability

### 26.1 SRS two-second expectation

No benchmark is claimed in DB-04. Likely costs are:

- waiting for the restaurant lock during contention;
- customer/email lock contention;
- retained-history overlap scans;
- meet-in-the-middle subset enumeration;
- transaction startup/commit and network latency.

The lock-protected work must exclude UI work, remote calls, email delivery, logging transport, and user think time. Flask must normalize input before beginning the database transaction.

### 26.2 Measurements for DB-06/DB-07

- uncontended single-table booking;
- uncontended worst-case multi-table booking;
- exact retry;
- same-customer conflict;
- unavailable/full result;
- two, five, and representative burst concurrent submissions;
- lock wait and lock-hold duration separately;
- candidate enumeration time with 30 equal and heterogeneous capacities;
- retained-history query plans and timings;
- p50/p95/p99 end-to-end database-operation time under defined local hardware.

Correctness takes priority. If measured contention threatens the target, a finer mechanism requires a separately reviewed DB-04 revision and proof; it must not be substituted silently.

### 26.3 Academic demonstration

The strategy is explainable in a short presentation:

1. show two sessions requesting the same scarce capacity;
2. show one waiting on the PostgreSQL restaurant lock;
3. commit the first;
4. show the second revalidating and returning unavailable or selecting disjoint tables;
5. inspect reservations/assignments directly to prove no overlap;
6. inject a failure after partial work and show complete rollback;
7. retry a lost-response booking and show the same confirmation ID.

## 27. SRS and rubric traceability

| Source requirement | DB-04 treatment |
|---|---|
| SRS FR-02 | Reads and locks the PostgreSQL-backed Monday-Saturday and Sunday recurring schedule used for every booking decision. |
| SRS FR-06 | Uses normalized start, party size, customer name/email, and optional phone as transaction inputs. |
| SRS FR-07 | Provisional availability and locked booking revalidation enforce valid/available intervals. |
| SRS FR-08 | Exact ranking ends in random selection among equal best tables from the 30-table inventory. |
| SRS FR-09 | New success and exact retry supply stable confirmation; no candidate yields full/unavailable. |
| SRS FR-15/FR-16 | Booking-linked newsletter state is atomic on the authoritative Customer row. |
| SRS FR-17 | Uses approved Customers, Reservations, and assignment representation without changing fields. |
| SRS FR-18 | Customer insert/reuse, availability, random assignment, and outcome are defined as authoritative database behavior invoked by Flask. |
| SRS NFR-02 | Defines performance measurements and bounded lock/retry behavior; makes no unsupported guarantee. |
| SRS NFR-05 | Restaurant lock, email lock, unique constraints, atomic transaction, and rollback prevent double/overbooking and partial state. |
| SRS NFR-06 | Failures are classified for safe Flask handling and technical logging. |
| SRS NFR-09 | Deterministic order, matrices, tests, and capability rationale support maintainability. |
| Rubric - all SRS requirements | Database behavior directly covers the reservation and newsletter effects applicable to DB-04. |
| Rubric - integrated Flask/PostgreSQL | PostgreSQL owns decisions; Flask owns normalization, retries, and later API mapping. |
| Rubric - direct database effects | Customer, preference, reservation, and all assignments are inspectable after commit/rollback. |
| Rubric - sophisticated reservation logic | Multi-table exact optimization, random ties, retry collision safety, concurrency proof, and rollback are explicit. |

## 28. PRA-001 through PRA-029 traceability

| PRA | DB-04 treatment |
|---|---|
| PRA-001 | Remains in PostgreSQL design; no Flask/React implementation begins. |
| PRA-002 | Selects the simplest provably correct Version 1 coordination strategy. |
| PRA-003 | Defines database unit and concurrent integration tests. |
| PRA-004 | Every behavior traces to SRS, rubric, approved PRA, or approved DB-03. |
| PRA-005 | Reads current database configuration; no duplicate constants. |
| PRA-006 | Revalidates interval alignment from current configuration. |
| PRA-007 | Derives and stores immutable end from current approved duration. |
| PRA-008 | Uses all-seven schedule completeness and requested weekday current hours; no exceptions. |
| PRA-009 | Enforces open and end-at/before-close; latest start remains derived. |
| PRA-010 | Applies inclusive current-date through configured-window rule. |
| PRA-011 | Applies lead against database wall clock after lock acquisition. |
| PRA-012 | Validates database timezone and unambiguous canonical instant. |
| PRA-013 | Uses strict half-open overlap and allows endpoint contact. |
| PRA-014 | Exact retry precedes different same-customer overlap; concurrency is database-protected. |
| PRA-015 | Derives maximum and candidate capacity from all current tables. |
| PRA-016 | Requires exactly 30 locked/validated current table rows. |
| PRA-017 | Uses each current table capacity and coordinates capacity changes. |
| PRA-018 | Exact minimum-count/least-waste/random-tie assignment commits all-or-none and exclusively. |
| PRA-019 | Email/customer locks enforce identity, matching, optional-field, and atomic preference rules. |
| PRA-020 | Mutates only `customers.newsletter_subscribed`; no second source/history. |
| PRA-021 | Email lock gives retry-safe final-state and last-committed-write behavior. |
| PRA-022 | No cancellation/status path; retained reservations continue to govern their intervals. |
| PRA-023 | Flask normalizes; PostgreSQL revalidates current booking facts and integrity. |
| PRA-024 | Classified outcomes support confirmation, retry, stale/full recovery, and safe technical logging later. |
| PRA-025 | Availability is provisional; booking does not trust displayed status. |
| PRA-026 | Locks give coherent current settings; changes are prospective and existing rows unchanged. |
| PRA-027 | Specifies database SHA-256 fingerprint, three-input serialization, collision verification, and retry newsletter nonmutation. |
| PRA-028 | Past rows remain; time comparison rather than deletion controls availability. |
| PRA-029 | Locks/reads PostgreSQL weekly hours and coordinates prospective changes without Flask/React constants. |

## 29. Explicit Version 1 exclusions

DB-04 introduces none of the following:

- cancellation, modification, rescheduling, or reservation statuses;
- temporary holds, queues, waiting lists, or provisional reservations;
- customer-selected or preferred tables;
- table/seat sharing;
- adjacency, combinability, floor plans, or seat-level assignment;
- active/inactive table state or more than 30 Version 1 tables;
- holiday/date-specific exceptions, closed weekdays, overnight service, or multiple daily periods;
- configuration, schedule, newsletter, customer, or reservation history/audit;
- email/SMS confirmation or delivery state;
- persistent availability, candidates, ranking, waste, seeds, or random outcomes;
- archive, purge, anonymization, or customer deletion;
- authentication, verified ownership, or administrative reservation management.

## 30. Decisions deferred to later increments

### 30.1 DB-05

- actual DDL for approved foundation tables/constraints/indexes;
- installation verification for `pgcrypto`;
- roles and privileges;
- stable advisory-lock key constants/derivation documentation;
- foundation migrations, seed/reset, and environment-readiness checks;
- exact bounded timeout defaults after local environment measurement.

### 30.2 DB-06

- executable reservation/assignment DDL and indexes from DB-03;
- concrete database booking and availability operations;
- canonical serialization/digest implementation;
- meet-in-the-middle implementation and production random tie-rank generation;
- deterministic test wrapper/role;
- database outcome identifiers;
- unit and multi-session integration tests;
- measured bounded retry/backoff tuning.

### 30.3 DB-07 and later Flask/React increments

- performance/query-plan evidence and hard PostgreSQL gate;
- Flask endpoint paths, payloads, status codes, transaction driver, logging, and message mapping;
- React state, submission, refresh, confirmation, and recovery implementation;
- live end-to-end integration and presentation evidence.

## 31. Unresolved decisions requiring approval

No unresolved business rule, logical-schema contradiction, or implementation-blocking ambiguity was discovered.

The following are DB-04 technical decisions presented for approval in this artifact:

- `READ COMMITTED` plus restaurant-wide transaction advisory lock;
- per-canonical-email transaction advisory lock;
- deterministic row/lock order;
- SHA-256 via `pgcrypto` and the version-1 serialization;
- exact meet-in-the-middle allocation;
- random tie-rank selection with a non-public deterministic test seam;
- three-total-attempt bounded retry principle;
- requirement that controlled configuration/hours/capacity writers share the restaurant lock;
- database-role restriction against bypassing authoritative operations.

## 32. DB-04 completion assessment and approval checkpoint

| DB-04 criterion | Result |
|---|---|
| Transaction boundary selected | Complete |
| Isolation and concurrency mechanism selected | Complete |
| Lock scope/order/release defined | Complete |
| Provisional versus authoritative availability separated | Complete |
| Coherent configuration/hours/capacity reads proved | Complete |
| Customer creation/reuse races resolved | Complete |
| Fingerprint algorithm/serialization/version selected | Complete |
| Exact retry/collision handling proved | Complete |
| Same-customer overlap protected | Complete |
| Table exclusivity under concurrency proved | Complete |
| Exact multi-table ranking designed | Complete |
| Random tie and deterministic test seam designed | Complete |
| Newsletter atomicity and concurrent interaction defined | Complete |
| Rollback and network ambiguity defined | Complete |
| Retry policy bounded | Complete |
| Unit and concurrent integration tests planned | Complete |
| Performance measurement plan defined | Complete |
| DB-03 compatibility verified | Complete; no schema change |
| SRS/rubric/PRA traceability complete | Complete |
| Version 1 exclusions preserved | Complete |
| SQL/application code avoided | Complete |
| Unresolved blocker | None |

DB-04 version 1.0 is complete and ready for Abdul's approval.

Approval of DB-04 authorizes **DB-05 - Database Foundation Implementation** only. DB-05 will implement customers, scalar configuration, recurring operating hours, exactly 30 initialized tables, foundation constraints/roles, `pgcrypto` readiness, seed/reset/rebuild verification, and foundation tests. It will not yet implement reservations, assignments, allocation, or booking concurrency; those remain DB-06.

Do not begin DB-05 until DB-04 is explicitly approved.

No SQL or application code was generated.
