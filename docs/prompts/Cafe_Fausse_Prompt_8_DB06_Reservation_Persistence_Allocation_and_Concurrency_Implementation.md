# Prompt 8 - Implement DB-06 reservation persistence, allocation, and concurrency

Begin only **DB-06 - Reservation Persistence, Allocation, and Concurrency Implementation** of the approved least-to-most implementation roadmap.

This prompt continues the PostgreSQL implementation begun in DB-05. Work in the repository-connected Codex environment with the Cafe Fausse repository root open.

## Authoritative sources

Use the following as authoritative, in this order:

1. `docs/SRS.pdf`;
2. `docs/Rubric.pdf`;
3. the approved Project Requirements Addendum version 2.2.1, including PRA-001 through PRA-029;
4. the approved DB-01 Persistent-Data Requirements Analysis version 1.2.1;
5. the approved DB-02 Conceptual Data Model version 1.2;
6. the approved DB-03 Logical PostgreSQL Schema and Integrity Design version 1.1;
7. the approved DB-04 Reservation Transaction and Concurrency Design version 1.1;
8. the approved DB-05 database foundation implementation currently present in the repository, including its migrations, roles, initialization/reset tooling, tests, documentation, and completion evidence;
9. the approved least-to-most implementation roadmap version 1.1.1;
10. the repository-root `AGENTS.md` and any more specific applicable repository instructions.

DB-01 through DB-05 are approved. DB-05 was explicitly approved by Abdul on 2026-08-19. Do not reopen, replace, or silently change an approved decision or an approved DB-05 foundation artifact unless implementation exposes a genuine contradiction or blocker.

The repository implementation is authoritative for DB-05 technical details such as migration numbering, folder placement, role names, advisory-lock namespace documentation, timeout configuration points, test harness, and reset conventions. The approved design documents remain authoritative for business behavior and logical schema.

## Required initial repository audit

Before changing any file:

1. Read the applicable `AGENTS.md` instructions.
2. Inspect Git status and preserve unrelated user changes.
3. Identify the DB-05 migration sequence, schema namespace, role names, extension setup, seed/reset workflow, test framework, and documentation conventions.
4. Run or inspect the approved DB-05 verification command and confirm the foundation is in its approved state.
5. Confirm that DB-05 currently provides:
   - `customers`;
   - `reservation_configuration`;
   - `restaurant_operating_hours`;
   - `restaurant_tables`;
   - one configuration row;
   - seven approved weekday rows;
   - exactly 30 tables at capacity four;
   - total initial capacity 120;
   - `pgcrypto` readiness;
   - the approved role/privilege groundwork;
   - the stable advisory-lock key or namespace convention;
   - guarded nonproduction reset/rebuild tooling.
6. Confirm that `reservations` and `reservation_table_assignments` do not already exist as approved DB-05 objects.
7. Record the baseline test result before adding DB-06.

If the approved DB-05 implementation is incomplete, inconsistent with its approval record, or already contains a conflicting reservation implementation, stop and report the discrepancy. Do not overwrite it or improvise a second database architecture.

## Increment boundary

Implement only DB-06:

- the approved `reservations` table;
- the approved `reservation_table_assignments` table;
- their exact DB-03 keys, foreign keys, checks, defaults, referential actions, and indexes;
- authoritative read-only provisional availability derived from current PostgreSQL facts;
- one controlled authoritative booking operation implementing DB-04;
- database-generated version-1 reservation fingerprints;
- collision-safe exact retry;
- safe customer creation/reuse within booking;
- booking-linked newsletter preference behavior;
- same-customer overlap rejection;
- complete-interval free-table derivation;
- exact single-table and multi-table allocation;
- minimum-table-count and least-unused-capacity ranking;
- random selection only among equal best candidates;
- a restricted deterministic random test seam;
- approved PostgreSQL transaction, lock, role, timeout, and rollback behavior;
- controlled database writers or test/admin paths needed to prove configuration, schedule, capacity, and newsletter concurrency interaction;
- incremental migration, reset, documentation, database unit tests, and reproducible multi-session integration tests;
- preliminary DB-06 performance measurements required by DB-04, without claiming the later DB-07 performance gate.

Do not begin DB-07. Do not implement Flask, Python application services, REST endpoints, API payloads, HTTP status codes, React, JSX, browser behavior, or end-to-end application integration.

Python may be used only for the repository's database test harness, concurrent-session driver, migration orchestration, or verification tooling. It must not become the Flask application or duplicate authoritative PostgreSQL business logic.

## DB-05 preservation rules

DB-06 must extend the approved DB-05 migration chain. It must not rebuild the foundation from a new migration baseline.

- Add new forward migrations after the last approved DB-05 migration.
- Do not edit already approved migration bytes merely to make DB-06 easier.
- Do not rename, drop, recreate, or change approved DB-05 tables, columns, types, constraints, indexes, roles, seed rows, or advisory-lock conventions.
- Extend role grants only as needed for controlled DB-06 operations.
- Extend reset/rebuild logic in explicit dependency order.
- Preserve the exact configuration, hours, and table initialization.
- Reuse the existing `pgcrypto` installation/readiness mechanism.
- Reuse the existing nonproduction safety guard.
- Reuse the DB-05 test framework and naming conventions where practical.

If a DB-05 migration must genuinely be corrected rather than extended, stop and request approval with the exact reason, affected object, compatibility impact, and proposed remediation.

## Exact DB-03 reservation schema

Implement the approved logical schema exactly. Do not add convenience or audit data.

### `reservations`

| Column | PostgreSQL representation | Nullability | Default/generation |
|---|---|---|---|
| `reservation_id` | `BIGINT` identity | Not null | Database generated |
| `customer_id` | `BIGINT` | Not null | No default |
| `starts_at` | `TIMESTAMP WITH TIME ZONE` | Not null | No default |
| `ends_at` | `TIMESTAMP WITH TIME ZONE` | Not null | No default |
| `party_size` | `INTEGER` | Not null | No default |
| `fingerprint_version` | `SMALLINT` | Not null | `1` |
| `reservation_fingerprint` | `BYTEA` | Not null | Generated only by the authoritative database booking operation |

Required constraints and behavior:

- `reservation_id` is the primary key, SRS Reservation ID, and stable confirmation reference.
- `customer_id` references `customers.customer_id` and may not be null.
- Foreign-key update and delete actions are restrict/no action, consistent with approved retention.
- `starts_at` and `ends_at` are immutable canonical instants.
- Occupancy is the half-open interval `[starts_at, ends_at)`.
- `ends_at` must be strictly later than `starts_at`.
- Elapsed duration must be exactly 60, 90, or 120 minutes.
- `party_size` must be a positive integer.
- `fingerprint_version` must be positive and defaults to 1.
- `reservation_fingerprint` must be nonempty bytes.
- `(customer_id, starts_at, party_size)` is unique and remains the collision-safe exact-retry business identity.
- The fingerprint itself must remain non-unique.
- Existing reservation identity, owner, interval, party size, fingerprint version, and fingerprint are immutable in ordinary Version 1 operation.

Use deterministic constraint names consistent with DB-03:

- `reservations_pk`;
- `reservations_customer_fk`;
- `reservations_interval_ck`;
- `reservations_duration_ck`;
- `reservations_party_size_ck`;
- `reservations_fingerprint_version_ck`;
- `reservations_fingerprint_ck`;
- `reservations_exact_identity_uq`.

Do not add reservation status, cancellation, modification, rescheduling, no-show, created/updated timestamps, configuration snapshots, schedule snapshots, newsletter snapshots, assigned-capacity snapshots, delivery fields, idempotency-request rows, or audit/history columns.

### `reservation_table_assignments`

| Column | PostgreSQL representation | Nullability | Default |
|---|---|---|---|
| `reservation_id` | `BIGINT` | Not null | No default |
| `table_number` | `SMALLINT` | Not null | No default |

Required constraints and behavior:

- Composite primary key `(reservation_id, table_number)`.
- `reservation_id` references `reservations.reservation_id` with restrict/no action behavior.
- `table_number` references `restaurant_tables.table_number` with restrict/no action behavior.
- Each reservation-table pair occurs once.
- No assignment exists independently of both parents.
- Assignment rows contain no copied interval, capacity, ranking, random choice, unused-seat count, or candidate data.
- There is no independent assignment identifier.

Use deterministic constraint names consistent with DB-03:

- `reservation_table_assignments_pk`;
- a clear deterministic name for the reservation foreign key;
- a clear deterministic name for the restaurant-table foreign key.

Do not use cascading deletion for convenience. Controlled nonproduction reset must delete assignment rows explicitly before reservations.

## Exact DB-03 index implementation

Implement only the approved nonredundant indexes:

| Index | Columns | Unique | Purpose |
|---|---|---:|---|
| `reservations_fingerprint_lookup_idx` | `fingerprint_version`, `reservation_fingerprint` | No | Retry candidate lookup while allowing collisions |
| `reservations_customer_interval_idx` | `customer_id`, `starts_at`, `ends_at` | No | Same-customer overlap and ownership/time lookup |
| `reservations_interval_idx` | `starts_at`, `ends_at` | No | Global interval/date scans for availability |
| `reservation_table_assignments_table_idx` | `table_number`, `reservation_id` | No | Table-first assignment lookup |

Do not duplicate indexes automatically owned by:

- `reservations_pk`;
- `reservations_exact_identity_uq`;
- `reservation_table_assignments_pk`.

Do not add GiST, range, exclusion, partial, covering, status, or speculative indexes unless a measured DB-06 blocker proves one necessary. Such an index must not change DB-03 semantics. If it would alter the approved design or enforcement mechanism, stop and request approval.

## Authoritative database operations

Implement a small set of controlled PostgreSQL operations using the least complex built-in mechanism consistent with the repository. PostgreSQL SQL and PL/pgSQL functions or procedures are permitted. Do not duplicate the booking transaction across multiple public entry points.

At minimum provide conceptual operations for:

1. read-only provisional availability;
2. authoritative reservation booking;
3. independent newsletter preference interaction needed to enforce DB-04's email-lock protocol;
4. controlled configuration, operating-hours, and table-capacity writes or restricted test/admin equivalents needed to prove that approved prospective changes coordinate with booking.

The production booking operation must be the sole ordinary-runtime path that inserts reservations or assignment rows. The ordinary application role must not receive unrestricted direct DML on reservations, assignments, or protected customer/configuration facts.

Where an operation uses elevated ownership privileges, harden it appropriately:

- fixed safe `search_path`;
- schema-qualified object references;
- least-privilege ownership;
- explicit revocation from `PUBLIC`;
- execute grants only to intended roles;
- no dynamic SQL unless strictly necessary and safely parameterized;
- no caller-controlled object names;
- no secrets or embedded credentials.

Choose and document stable database outcome identifiers for later Flask mapping. They are internal database/application semantics, not HTTP statuses or user-facing wording. The outcome set must distinguish at least:

- newly booked success;
- exact-retry success;
- authoritative unavailable/full;
- same-customer overlap;
- customer identity mismatch;
- middle-initial conflict;
- success with differing-phone notice condition;
- request/business validation failure;
- invalid database configuration/readiness;
- retryable technical conflict;
- unexpected failure.

Do not finalize Flask response objects or API contracts.

## Normalized booking input boundary

The authoritative booking operation must accept only the normalized business inputs approved by DB-04:

- first name;
- optional middle initial;
- last name;
- canonical lowercase email;
- optional phone display value and any transient comparison representation genuinely needed by the approved implementation;
- selected restaurant-local date/start represented unambiguously enough to validate and reproduce one canonical instant under the current restaurant timezone;
- party size;
- newsletter action: subscribe, unsubscribe, or no change.

Define and document the exact PostgreSQL routine parameter types needed to represent these inputs without designing an HTTP payload.

Confirmation email is a transient later-Flask validation field and must not be accepted as persistent database data.

Do not accept caller-supplied:

- `customer_id`;
- `reservation_id`;
- fingerprint or fingerprint version;
- `ends_at`;
- duration;
- table number or table combination;
- availability result;
- configuration value;
- random seed or tie rank through the production operation;
- newsletter history value.

The database must resolve or derive authoritative identifiers, end time, fingerprint, current settings, free tables, and winning assignments.

## Selected transaction and locking behavior

Implement DB-04's approved primary strategy exactly:

- isolation level: `READ COMMITTED` for authoritative booking;
- one exclusive transaction-scoped PostgreSQL advisory lock for the Version 1 restaurant booking domain;
- one transaction-scoped advisory lock derived from canonical email;
- deterministic row locks and reads;
- lock release only at commit or rollback;
- bounded lock/statement timeouts through the approved DB-05 configuration point;
- no process-local mutex;
- no optimistic reliance on request timing, one worker, or the previously displayed availability result.

Use the stable advisory-lock keys or namespaces approved and documented in DB-05. Do not invent a competing key scheme. If the approved DB-05 key material is missing or ambiguous, stop and request approval before implementing a different convention.

### Deterministic booking lock order

The implementation must follow this order:

1. begin transaction;
2. establish bounded transaction timing controls;
3. acquire the transaction-scoped restaurant booking advisory lock in a statement that performs no business read;
4. lock/read the singleton configuration row;
5. lock/read all operating-hours rows in ascending weekday order;
6. lock/read all restaurant-table rows in ascending table-number order;
7. acquire the canonical-email advisory lock;
8. resolve and lock the matching customer row, or create the provisional customer while the email lock is held;
9. read retry, overlap, reservation, and assignment facts;
10. insert one reservation;
11. insert assignment rows in ascending table-number order;
12. assert postconditions;
13. commit or roll back.

Production randomness must never affect lock order.

Dedicated newsletter preference writes acquire the canonical-email lock and then the customer row. They must not obtain the restaurant lock afterward.

Controlled configuration, hours, and capacity writes acquire the restaurant lock before locking/updating their target rows. They do not acquire customer locks.

## Authoritative booking order

Implement the following complete behavior. If a safe implementation needs a minor internal rearrangement, document and prove it preserves every DB-04 rule.

1. Begin one authoritative transaction attempt.
2. Set the approved bounded timeout controls.
3. Acquire the restaurant transaction advisory lock before any business read.
4. Lock and read the current configuration row.
5. Lock/read all seven operating-hours rows in ascending weekday order and verify exact identities 1 through 7.
6. Lock/read all 30 restaurant-table rows in ascending table-number order and verify positive capacities.
7. Validate the configured timezone against PostgreSQL-supported timezone names.
8. Capture authoritative database wall-clock time after obtaining the restaurant lock.
9. Convert and round-trip the requested local start under the current timezone, rejecting nonexistent, ambiguous, offset-inconsistent, or otherwise noncanonical local input.
10. Derive immutable `ends_at` from `starts_at` plus the current configured duration.
11. Revalidate local date, inclusive advance window, same-day lead, interval alignment, opening boundary, and complete end-at-or-before-close boundary.
12. Revalidate approved duration, positive party size, and party size no greater than the current derived total capacity.
13. Acquire the canonical-email advisory lock.
14. Resolve the customer by canonical email, creating one provisional customer if absent or locking the existing row if present.
15. Apply approved name matching and determine, but do not yet apply, optional middle-initial/phone population.
16. Generate fingerprint version 1 inside PostgreSQL.
17. Search fingerprint candidates and compare underlying facts.
18. Search the unique underlying tuple as a compatibility and race backstop.
19. If an exact retry exists, return it with all assignments and current newsletter state without contact or newsletter mutation.
20. If not a retry, reject any different same-customer overlapping reservation.
21. Derive all tables free for the complete requested interval.
22. Generate and rank exact capacity-sufficient candidates.
23. If none exists, return authoritative unavailable/full with no attempted mutation remaining.
24. Randomly choose one equal-best candidate and sort its table numbers ascending.
25. Recheck time-sensitive rules if lock wait or calculation crossed a lead/window boundary.
26. Apply permitted blank optional-field population for this new successful booking path only.
27. Apply subscribe, unsubscribe, or no-change for this new successful booking path only.
28. Insert one reservation with generated identity and fingerprint facts.
29. Insert every winning assignment in ascending table-number order.
30. Assert final transaction postconditions.
31. Commit and return the committed database outcome required for later Flask handling.

An exact retry and an unavailable request must not mutate customer contact or newsletter state.

## Customer creation and reuse

Implement DB-04's approved rules inside the booking transaction.

### New canonical email

- Create at most one customer while holding the email advisory lock.
- The customer is provisional until the booking commits.
- A failed or unavailable booking leaves no newly created customer.
- The unique canonical-email constraint remains the backstop.
- A unique-email race from a conforming or nonconforming concurrent writer must be classified and safely re-resolved without exposing a raw database error as a business outcome.

### Existing canonical email

- First and last names must match case-insensitively after approved normalization.
- Mismatch rejects generically and changes nothing.
- Omitted middle initial preserves the stored value.
- Blank stored middle initial may be populated only on a successful new booking.
- Conflicting populated middle initial rejects and changes nothing.
- Omitted phone preserves stored data.
- Blank stored phone may be populated only on a successful new booking.
- A differing existing phone is not overwritten; booking may continue with a notice condition.
- No operation becomes a general profile-update workflow.

### Newsletter behavior

- New reservation plus subscribe sets the final Boolean true atomically.
- New reservation plus unsubscribe sets it false atomically.
- No-change preserves current state.
- Exact retry ignores submitted newsletter action for mutation and returns current state.
- Booking failure rolls back any attempted preference change.
- Independent preference updates use the email/customer lock order and preserve last-committed-write-wins behavior.
- No newsletter history, event, snapshot, or second source of truth may be added.

## Fingerprint implementation

Implement DB-04 version 1 exactly.

| Item | Required implementation |
|---|---|
| Algorithm | SHA-256 |
| Capability | Existing DB-05 `pgcrypto` digest support |
| Stored representation | Raw 32-byte `BYTEA` |
| Semantic version | `fingerprint_version = 1` |
| Inputs | Resolved `customer_id`, canonical UTC `starts_at`, `party_size` only |

Canonical version-1 serialization:

- fixed field order: customer, start, party;
- UTF-8 bytes;
- each field encoded as ASCII decimal byte length, colon, canonical value;
- fields separated by one ASCII vertical bar;
- customer ID: unsigned base-10 digits, no sign or leading zeros;
- start: UTC `YYYY-MM-DDTHH:MM:SS.ffffffZ`, exactly six fractional-second digits;
- party size: unsigned base-10 digits, no sign or leading zeros.

The semantic version selects the algorithm and serialization. It is not an additional business input.

Do not include name, email text, middle initial, phone, newsletter state/action, table assignments, end, duration, configuration, or operating hours.

### Collision-safe lookup order

1. Generate version and fingerprint.
2. Retrieve every same-version candidate from the non-unique fingerprint index.
3. Compare `customer_id`, `starts_at`, and `party_size` for each candidate.
4. A complete tuple match is exact retry.
5. A fingerprint match with different tuple values is a collision only and does not establish equality or mutation.
6. If no candidate tuple matches, query the unique underlying tuple.
7. Return an existing tuple as exact retry; otherwise continue as a new booking.

An exact retry returns the existing reservation identity, immutable interval, party size, assignments, and current newsletter state. It creates or updates nothing.

Provide deterministic tests for serialization bytes, UTC rendering, six fractional digits, length prefixes, version behavior, non-unique fingerprint storage, tuple verification, and collision handling. A collision test may use a restricted test fixture or internal test seam; do not weaken production integrity or claim a naturally discovered SHA-256 collision.

## Same-customer overlap

After exact-retry handling, reject a different reservation for the same customer when:

`existing.starts_at < requested.ends_at` and `requested.starts_at < existing.ends_at`.

Test and enforce:

- identical start with different party size rejects as overlap, not retry;
- proposed start inside existing rejects;
- proposed interval containing existing rejects;
- proposed interval contained by existing rejects;
- identical interval with nonmatching identity rejects;
- proposed end equal to existing start is allowed, subject to capacity;
- proposed start equal to existing end is allowed, subject to capacity;
- retained past nonoverlapping reservations do not block;
- concurrent nonidentical overlapping requests for the same customer cannot both commit.

Do not add a copied range column or exclusion constraint that changes approved DB-03.

## Free-table derivation

A restaurant table is free only when no row in `reservation_table_assignments` for that table joins to a parent reservation whose immutable interval overlaps the entire requested interval under the approved half-open predicate.

Use only:

- `restaurant_tables`;
- `reservation_table_assignments`;
- `reservations`.

Do not persist free/busy state, remaining capacity, candidate tables, interval copies, or availability ledgers.

Verify partial overlap, complete overlap, containing, contained, identical, and endpoint-touching relationships. Different customers may hold overlapping reservations only when their final assigned table sets are disjoint. Unused seats on an assigned table cannot be shared.

## Exact allocation algorithm

Implement DB-04's exact meet-in-the-middle algorithm for at most 30 free tables. Do not substitute greedy allocation, first-fit, heuristic pruning, or exhaustive materialization of every full candidate combination.

Required behavior:

1. Start from the ascending free-table list of `(table_number, seating_capacity)`.
2. Split it into two ascending halves of at most 15 tables.
3. Enumerate every subset of each half, including empty, recording count, capacity sum, and ascending table-number tuple.
4. Group or order second-half subsets by table count and capacity sum while retaining deterministic table-number ordering and tie counts.
5. Search candidate table count from 1 upward.
6. Stop at the first count with one or more capacity-sufficient combinations; this is the exact minimum table count.
7. Within that count, find the smallest combined capacity at least party size; this is the exact least waste.
8. Count every distinct equal-best combination without persisting or unnecessarily materializing a huge candidate set.
9. Select one valid tie rank.
10. Reconstruct the corresponding winning subset deterministically.
11. Sort winning table numbers ascending for persistence.
12. Persist only the winning assignments.

The implementation must remain exact with identical or heterogeneous capacities and technically reasonable with 30 tables. It must return unavailable/full if no eligible combination exists.

### Random tie selection and test seam

- Production chooses a random rank only after minimum count and least waste are fixed.
- Every equal-best candidate must have a nonzero selection opportunity.
- Random values never influence lock acquisition or assignment insert order.
- The production operation never accepts a client-supplied seed or rank.
- A restricted test-only wrapper or internal role may supply a fixed valid rank.
- The test seam must not be executable by the ordinary application role.
- Reject out-of-range test ranks.
- Persist no seed, rank, candidate, rejected candidate, waste, or random history.

Correctness tests must be deterministic. A statistical production smoke test may be supplemental but cannot replace proof that each rank maps to one eligible equal-best combination.

## Provisional availability operation

Implement a read-only operation that uses one consistent snapshot, preferably one database statement or a short read-only `REPEATABLE READ` transaction.

It must:

1. read and validate the singleton configuration;
2. read and validate the complete seven-day schedule;
3. read and validate exactly 30 positive-capacity restaurant tables;
4. validate the requested local date and party size;
5. derive current restaurant-local date/time using database time and configured timezone;
6. apply the inclusive advance window and same-day lead;
7. obtain the requested weekday's opening and closing boundaries;
8. generate every start aligned from opening using the current interval;
9. derive each proposed end from current duration;
10. retain starts that end at or before close;
11. derive free tables for each complete interval;
12. mark available only when an exact capacity-sufficient combination exists;
13. return every legitimate aligned start with provisional available/unavailable state.

It must not:

- obtain or retain the restaurant booking lock after returning;
- create holds or promises;
- persist slots, availability, free tables, candidates, rankings, or random outcomes;
- perform production random winner selection merely to decide Boolean availability.

Booking must ignore the earlier availability result and repeat all authoritative checks under the booking lock.

## Configuration, schedule, and capacity consistency

Implement or extend controlled write operations, or restricted test/admin equivalents, so approved changes to configuration, recurring hours, and table capacities acquire the same restaurant advisory lock before row locks and writes.

Prove through tests that a booking either:

- commits completely using a coherent pre-change state; or
- observes the fully committed changed state and revalidates.

It must never mix old/new values. Existing reservations and assignments must remain unchanged after later configuration, schedule, or capacity changes.

Do not introduce configuration/schedule history, effective dates, reservation snapshots, active tables, or new schedule behaviors.

## Atomic postconditions

Before a new booking commits, prove or assert:

- exactly one resolved customer;
- exactly one new reservation;
- one or more unique assignments;
- combined assigned capacity covers party size;
- every assigned table was free over the complete interval at the serialized decision point;
- no different overlapping reservation exists for the same customer;
- stored fingerprint/version matches the approved three-input serialization;
- exact identity is unique;
- every assignment references the new reservation and a current table;
- optional contact and newsletter effects match the approved new-booking rules;
- no partial candidate, customer, preference, reservation, or assignment state exists.

Any failed postcondition rolls back the full transaction.

Exact retry has different postconditions:

- no new business row;
- no contact or newsletter mutation;
- existing reservation and all assignments returned;
- current authoritative newsletter state returned.

## Failure classification and rollback

Implement and test stable database classifications for at least:

- invalid/missing/duplicate configuration;
- incomplete operating-hours schedule;
- unexpected table count;
- invalid timezone;
- date outside booking window;
- insufficient same-day lead;
- misaligned start;
- start before opening;
- end after closing;
- party size outside derived maximum;
- customer name/email mismatch;
- middle-initial conflict;
- differing existing phone notice;
- exact retry;
- fingerprint collision without tuple equality;
- same-customer overlap;
- no free capacity-sufficient combination;
- unique-email race;
- exact-identity unique race;
- lock timeout;
- deadlock victim;
- serialization failure if encountered;
- unexpected database error;
- injected failure after customer insertion;
- injected failure after optional-field population;
- injected failure after newsletter update;
- injected failure after reservation insertion;
- injected failure after partial assignment insertion;
- connection loss before commit;
- ambiguous connection loss during commit;
- connection loss after commit followed by retry.

For each classification, tests and documentation must state whether it is success, unavailable, business conflict, validation failure, retryable technical conflict, or unexpected failure; whether it commits or rolls back; whether an external full-transaction retry is safe; and what persistent state may remain.

Do not catch and convert errors in a way that accidentally commits partial work. Transaction-level errors must preserve PostgreSQL rollback semantics.

## Retry boundary

The database operation implements one complete authoritative transaction attempt. Deadlock, lock timeout, connection failure, and other transaction-level conflicts may require the later Flask caller to restart the full operation.

DB-06 must:

- emit or preserve stable retryable classifications;
- provide a database-focused concurrent test driver capable of bounded retries;
- use the DB-04 principle of at most three total attempts within one overall deadline for test/measurement scenarios;
- use short exponential backoff with jitter in the test driver where needed;
- restart from the beginning and re-read every authoritative fact;
- never resume a failed transaction;
- never implement an unbounded retry loop;
- never reapply a newsletter action after an earlier ambiguous commit, because ordinary resubmission must become exact retry.

Do not implement Flask retry orchestration in DB-06. Document the required later caller behavior.

## Role and privilege completion

Extend the approved DB-05 least-privilege model so:

- the migration/owner role owns or can deploy DB-06 objects;
- the ordinary application role can execute approved public database operations and perform required read-only access only;
- the ordinary application role cannot insert/update/delete reservation or assignment rows directly;
- the ordinary application role cannot bypass customer matching, booking locks, overlap checks, allocation, or newsletter atomicity;
- the ordinary application role cannot call deterministic random test seams or injected-failure hooks;
- test-only roles can exercise deterministic and failure-injection seams only in isolated test databases;
- `PUBLIC` receives no unintended function execution or table mutation privilege;
- configuration/hours/capacity mutation is restricted to controlled operations/roles that follow the restaurant lock protocol.

Provide executable privilege tests from non-owner sessions where the environment supports them.

## Migration and reset requirements

Add deterministic versioned DB-06 migrations in dependency order:

1. create `reservations` after `customers`;
2. create `reservation_table_assignments` after `reservations` and `restaurant_tables`;
3. create approved indexes;
4. create internal helpers and controlled public operations;
5. apply hardened ownership and grants;
6. extend verification objects/scripts as appropriate.

No production reservation rows are seeded. Reservation/customer combinations used for tests belong only to isolated test fixtures.

Extend guarded nonproduction reset/rebuild behavior so it:

- deletes assignments before reservations;
- then follows the approved DB-05 dependency order;
- restores the exact DB-05 configuration, seven hours, and 30 capacity-four tables;
- leaves no test customer or reservation data;
- preserves the production safety guard;
- rebuilds from the complete versioned migration chain;
- passes the full DB-05 plus DB-06 verification suite.

Do not use broad destructive filesystem or database targets. Do not alter production retention behavior.

## Database unit tests

Implement deterministic database-focused tests covering at least:

### Schema and integrity

- clean migration from approved DB-05 to DB-06;
- complete clean rebuild from zero;
- DB-05 regression suite still passes;
- exact reservation/assignment columns, types, nullability, defaults, keys, checks, foreign keys, and referential actions;
- expected indexes and no redundant indexes;
- direct ordinary-role DML is denied;
- no unapproved tables/columns/extensions exist.

### Temporal and availability behavior

- every half-open overlap shape;
- endpoint-touching/back-to-back intervals;
- SRS Monday-Saturday and Sunday closing boundaries;
- controlled alternate recurring hours;
- interval alignment 15/30/60;
- duration 60/90/120;
- advance-window and same-day lead boundaries;
- timezone and DST nonexistent/ambiguous local inputs;
- party-size bounds and derived total capacity;
- stale provisional availability does not guarantee booking;
- no availability/candidate rows persist.

### Allocation

- one-table eligibility;
- multi-table eligibility;
- minimum-table-count priority;
- least-unused-capacity priority;
- exact behavior with heterogeneous capacities;
- every equal-best deterministic tie rank;
- production random result always belongs to the equal-best set;
- out-of-range test rank rejection;
- no eligible combination;
- no shared unused seats;
- only winning assignments persist.

### Customer and retry behavior

- new-customer success and rollback;
- existing-customer reuse;
- name mismatch;
- middle-initial omit/populate/conflict;
- phone omit/populate/differing notice;
- newsletter subscribe/unsubscribe/no-change atomicity;
- exact retry creates no rows and performs no mutation;
- changed party size is not exact retry and overlaps when applicable;
- fingerprint canonical serialization and version;
- non-unique fingerprint collision with underlying tuple comparison;
- unique underlying tuple backstop;
- current newsletter state returned after independent change and exact retry.

### Atomicity and failure injection

- failure after customer creation leaves no customer;
- failure after optional-field population restores prior value;
- failure after newsletter update restores prior state;
- failure after reservation insert leaves no reservation;
- failure after one or more assignment inserts leaves neither reservation nor assignments;
- every committed reservation has one or more capacity-sufficient assignments;
- no partial assignment set is observable.

Test-only failure injection must be unavailable to production roles and must not add persistent business fields.

## Reproducible multi-session integration tests

Implement a deterministic concurrent-session harness using the existing repository test conventions. Use explicit barriers or database-observable synchronization, not timing-only sleeps.

Cover at least:

- two identical requests submitted concurrently;
- two different requests for the same new canonical email;
- concurrent matching and mismatching customer names;
- two different customers competing for the same last table;
- competing single-table requests;
- competing multi-table requests with partially overlapping candidate sets;
- single-table versus multi-table competition;
- two different overlapping requests by the same customer;
- concurrent back-to-back requests;
- stale provisional availability followed by booking;
- booking versus table-capacity change;
- booking versus recurring-hours change;
- booking versus scalar-configuration change;
- booking-linked newsletter update versus independent preference update;
- unique-email conflict backstop;
- exact-identity conflict backstop;
- forced deadlock or equivalent retryable conflict;
- lock timeout;
- each injected partial-work failure;
- connection loss after commit followed by ordinary resubmission;
- repeated clean runs from reset.

For every concurrent scenario, record:

- initial database state;
- session A and session B steps;
- synchronization point;
- permitted commit outcomes;
- returned database outcome classes;
- required final row counts and relationships;
- proof of no duplicate customer;
- proof of no duplicate exact reservation;
- proof that no table is assigned to overlapping reservations;
- proof that each committed reservation has a complete capacity-sufficient assignment set;
- proof that losing/failed transactions leave no partial state.

Run each critical concurrency scenario repeatedly enough to demonstrate reproducibility. Report the iteration count; do not claim proof from one lucky run.

## Performance and explainability measurements

DB-06 must collect preliminary measurements without claiming the final DB-07 gate or an unsupported two-second guarantee.

Measure at least:

- uncontended single-table booking;
- uncontended worst-case multi-table booking;
- exact retry;
- same-customer conflict;
- unavailable/full outcome;
- two and five concurrent submissions;
- restaurant-lock wait time and lock-hold time where observable;
- allocation time with 30 equal capacities;
- allocation time with representative heterogeneous capacities;
- retained-history overlap/access-path behavior.

Report environment details and p50/p95 where the harness can collect meaningful repeated samples. Preserve correctness over speculative optimization. If results reveal a serious blocker, report it for DB-07 or request a DB-04 revision rather than silently changing the approved concurrency mechanism.

The implementation should remain demonstrable academically: two sessions, one restaurant lock, revalidation after the first commit, direct inspection of assignments, injected rollback, and lost-response exact retry.

## Manual verification

Provide exact non-destructive commands for a reviewer to:

1. migrate an approved DB-05 database forward to DB-06;
2. rebuild a clean isolated database through all migrations;
3. inspect reservation/assignment schema, constraints, indexes, routines, ownership, and grants;
4. create a valid single-table reservation through the controlled operation;
5. create a valid multi-table reservation;
6. demonstrate back-to-back occupancy;
7. demonstrate same-customer overlap rejection;
8. demonstrate exact retry returning the same confirmation;
9. inspect customer, reservation, assignment, and newsletter effects after commit;
10. inject a test-only failure and prove complete rollback;
11. run a two-session conflict and prove no overlapping table assignment;
12. run the full unit and concurrency test suites;
13. run guarded reset and confirm the exact DB-05 baseline plus empty reservation state.

Commands must be copyable, avoid credentials, and operate only on a designated development/test database.

## Documentation and traceability

Update database documentation with:

- every DB-06 file and purpose;
- migration order;
- exact schema objects, constraints, indexes, routines, and grants;
- authoritative booking and provisional-availability inputs/outputs;
- stable internal outcome identifiers;
- advisory-lock order and key reuse from DB-05;
- fingerprint serialization specification;
- allocation algorithm and deterministic test seam;
- reset and test commands;
- retry boundary for later Flask;
- performance evidence;
- DB-05 compatibility assessment;
- explicit DB-07 and Flask/React deferrals.

Provide a concise traceability matrix covering:

- SRS FR-02, FR-06 through FR-09, FR-15 through FR-18;
- SRS NFR-02, NFR-05, NFR-06, and NFR-09;
- rubric PostgreSQL integration, direct database effects, and sophisticated reservation logic;
- PRA-001 through PRA-029 as applicable;
- every DB-03 reservation/assignment schema decision;
- every DB-04 locking, validation, fingerprint, retry, overlap, allocation, randomization, newsletter, rollback, and testing decision;
- DB-05 migration/role/extension/lock-key dependencies.

For each requirement identify the implementing object/file and automated or manual evidence. Do not mark later Flask, React, end-to-end, or DB-07 work complete.

## Explicit exclusions

Do not add or implement:

- Flask application code, endpoints, payloads, or HTTP statuses;
- React or JSX code;
- DB-07 final verification report/gate;
- cancellation, modification, rescheduling, status, or no-show workflows;
- temporary holds, queues, waiting lists, or provisional reservations;
- customer-selected/preferred tables;
- table or seat sharing;
- adjacency, combinability, floor plans, or seat-level assignment;
- active/inactive table state or more than 30 Version 1 tables;
- holiday/date exceptions, closed weekdays, overnight service, or multiple daily periods;
- configuration, schedule, newsletter, customer, reservation, or allocation history/audit;
- confirmation email/SMS delivery or delivery status;
- persistent availability, slot, free/busy, candidate, rank, seed, waste, or random-outcome data;
- archive, purge, anonymization, or production deletion behavior;
- authentication, verified ownership, automatic prefilling, or administrative reservation management;
- a client-generated idempotency key or fingerprint;
- a second confirmation-reference column;
- copied reservation intervals or capacities in assignments;
- unapproved extensions, range columns, exclusion constraints, triggers, or lock tables;
- generic audit timestamps.

## Required DB-06 deliverables

At completion, the repository must contain:

- incremental versioned DB-06 migrations;
- exact `reservations` and `reservation_table_assignments` schema objects;
- approved constraints, foreign-key actions, and indexes;
- controlled provisional-availability operation;
- controlled authoritative booking operation;
- SHA-256 fingerprint serialization and generation;
- collision-safe exact-retry implementation;
- same-customer overlap and free-table derivation;
- exact meet-in-the-middle allocation;
- production random tie selection and restricted deterministic test seam;
- booking-linked customer/newsletter atomicity;
- controlled concurrency-compatible writer/test paths;
- completed role and privilege grants;
- extended guarded reset/rebuild tooling;
- database unit tests;
- reproducible multi-session integration tests;
- preliminary performance evidence;
- updated database setup/test documentation;
- DB-06 implementation report and traceability matrix.

## Required final response

When implementation and verification are complete, report:

1. DB-06 implementation summary;
2. files added or changed and each file's purpose;
3. migration sequence from approved DB-05 and from a clean database;
4. implemented schema, constraints, indexes, routines, roles, and grants;
5. authoritative booking/availability operation signatures at the PostgreSQL level;
6. fingerprint and allocation implementation summary;
7. exact commands for setup, migration, reset, unit tests, concurrency tests, and manual verification;
8. DB-05 baseline regression result;
9. database unit-test results;
10. concurrent integration-test results and iteration counts;
11. rollback/failure-injection evidence;
12. privilege-boundary evidence;
13. preliminary performance measurements and environment;
14. direct database evidence that no overlapping table assignments or partial reservations committed;
15. SRS, rubric, PRA, DB-03, DB-04, and DB-05 traceability summary;
16. unresolved blockers, deviations, skipped tests, or environment limitations;
17. repository Git status limited to this increment's changes;
18. DB-06 completion assessment;
19. DB-06 approval checkpoint.

Do not claim DB-06 complete if required migrations, operations, privilege controls, reset behavior, or tests are missing or unexecuted. Do not claim the PostgreSQL phase complete; DB-07 remains.

## Stop conditions

Stop and request approval before proceeding if:

- any authoritative source contradicts approved DB-03 or DB-04;
- DB-06 requires changing an approved DB-05 migration or foundation object;
- an approved table, column, type, key, constraint, index, or referential action must change;
- a new business table/column, extension, trigger, lock table, copied interval, range/exclusion design, or status/history structure appears necessary;
- the DB-05 advisory-lock key convention is missing, ambiguous, or unsafe;
- the available PostgreSQL version or privileges cannot support required `pgcrypto`, advisory locks, routines, or role hardening;
- safe deterministic concurrency tests cannot be isolated from non-test data;
- implementing a requirement would begin Flask, React, DB-07, or an excluded feature;
- the repository contains conflicting user changes that cannot be safely preserved.

Ordinary technical choices squarely within DB-06 should be implemented, tested, and documented without reopening approved business decisions.

## Completion and next increment

DB-06 is complete only when:

- the approved reservation and assignment schema is reproducibly migrated;
- authoritative availability and booking operations implement DB-04;
- exact retry, overlap, allocation, concurrency, newsletter atomicity, and rollback behavior are proven;
- the ordinary application role cannot bypass those operations;
- all DB-05 and DB-06 tests pass from a clean isolated database;
- repeated concurrent tests show no conflicting or partial committed state;
- existing reservations remain unchanged after prospective configuration, hours, or capacity changes;
- all required evidence and documentation are present.

Present the result for explicit DB-06 approval.

Approval of DB-06 would authorize only **DB-07 - PostgreSQL Verification and Phase Gate**. Do not begin DB-07, Flask, or React in this prompt.
