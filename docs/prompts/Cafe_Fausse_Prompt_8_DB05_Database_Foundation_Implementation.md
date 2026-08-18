# Prompt 8 - Implement the DB-05 PostgreSQL database foundation

Begin only **DB-05 - Database Foundation Implementation** of the approved least-to-most implementation roadmap.

This is the first code-generation increment. Work in the repository-connected Codex environment with the Cafe Fausse repository open.

## Authoritative sources

Use the following as authoritative, in this order:

1. `SRS(1).pdf`;
2. `Rubric(1).pdf`;
3. the approved Project Requirements Addendum version 2.2.1, including PRA-001 through PRA-029;
4. the approved DB-01 Persistent-Data Requirements Analysis version 1.2.1;
5. the approved DB-02 Conceptual Data Model version 1.2;
6. the approved DB-03 Logical PostgreSQL Schema and Integrity Design version 1.1;
7. the approved DB-04 Reservation Transaction and Concurrency Design version 1.1;
8. the approved least-to-most implementation roadmap version 1.1.1.

DB-01, DB-02, DB-03, and DB-04 are approved. Do not reopen or silently change their decisions unless implementation reveals a genuine contradiction or blocker.

## Increment boundary

Implement only the smallest reproducible PostgreSQL foundation authorized by DB-05:

- versioned database migrations;
- `customers`;
- `reservation_configuration`;
- `restaurant_operating_hours`;
- `restaurant_tables`;
- every approved DB-03 constraint for those four tables;
- the exact approved scalar configuration seed;
- the exact seven-row SRS recurring-hours seed;
- exactly 30 initial restaurant tables, each with capacity four;
- `pgcrypto` installation/readiness verification required by approved DB-04;
- foundation roles and privileges appropriate to the current increment;
- stable advisory-lock namespace/key documentation needed by later DB-06 implementation, without implementing booking operations;
- safe development/test reset and clean-rebuild tooling;
- database-focused automated tests and verification;
- database setup, execution, reset, and test documentation.

Do **not** implement DB-06. In particular, do not create or partially create:

- `reservations`;
- `reservation_table_assignments`;
- availability operations;
- reservation-creation functions or procedures;
- exact-retry operations;
- fingerprint generation or serialization;
- overlap or table-exclusivity enforcement;
- allocation or table-combination logic;
- random tie selection;
- booking advisory-lock acquisition;
- reservation transaction retry behavior;
- booking-linked newsletter transaction behavior.

DB-05 must end with a complete, tested foundation and no reservation implementation.

Do not implement Flask, Python application behavior, APIs, React, JSX, or end-to-end application flows. Python may be used only when it is the repository's established database tooling or test harness; it must not become application-layer implementation.

## Repository-first working rules

Before editing:

1. Inspect the repository structure, version-control status, `AGENTS.md` files, database tooling, dependency files, environment examples, container files, test conventions, and existing documentation.
2. Preserve unrelated user changes and do not overwrite or reformat unrelated files.
3. Reuse the repository's existing migration and test conventions when they exist.
4. If no migration convention exists, choose the smallest explicit, versioned PostgreSQL migration structure that supports deterministic clean rebuilds and is easy to run locally and in tests. Document the choice and rationale.
5. Do not substitute SQLite or another database for PostgreSQL.
6. Do not connect to, reset, or mutate any production or production-like database.
7. Do not add secrets, passwords, connection strings containing credentials, or generated database data to version control.
8. Do not commit, push, open a pull request, or begin a later roadmap increment.

Use PostgreSQL-native SQL for schema, seed, privilege, and verification artifacts. Keep environment orchestration minimal and consistent with the repository.

If the repository is missing a runnable PostgreSQL development/test environment, still create the complete implementation artifacts where possible, but report precisely what could not be executed. Do not claim tests passed when they were not run.

## Required DB-05 implementation decisions

Within the approved design, determine and document these technical implementation details:

- migration runner and file organization;
- forward migration and clean-rebuild approach;
- deterministic constraint names;
- safe seed/upsert behavior;
- development/test reset guard;
- database owner/migration role and ordinary runtime role approach, using repository conventions where available;
- the stable advisory-lock key namespace and collision-avoidance convention reserved for DB-06;
- bounded foundation lock/statement timeout defaults or configuration points, based on the available local environment;
- how `pgcrypto` availability is established and verified;
- how population invariants that ordinary row constraints cannot prove are checked during initialization and tests.

These are DB-05 technical choices. Record their rationale in the implementation report. Do not use them as permission to change the approved logical schema or business rules.

If any choice would require a new table, business column, extension other than approved `pgcrypto`, or a changed DB-03 type/key/constraint, stop and request approval before making that change.

## Exact foundation schema

Implement these exact approved logical tables and columns. Do not add generic timestamps, audit fields, status columns, active flags, history columns, or convenience duplicates.

### `customers`

Implement:

| Column | PostgreSQL representation | Nullability | Default/generation |
|---|---|---|---|
| `customer_id` | `BIGINT` identity | Not null | Database generated |
| `first_name` | `VARCHAR(100)` | Not null | No default |
| `middle_initial` | `VARCHAR(1)` | Nullable | `NULL` |
| `last_name` | `VARCHAR(100)` | Not null | No default |
| `email` | `VARCHAR(254)` | Not null | No default |
| `phone` | `TEXT` | Nullable | `NULL` |
| `newsletter_subscribed` | `BOOLEAN` | Not null | `FALSE` |

Required identity and integrity behavior:

- `customer_id` is the primary key and stable internal SRS Customer ID.
- `email` is the single stored canonical email and the unique business identity.
- Canonical email must be nonempty, trimmed, lowercase, no more than 254 characters, and unique.
- Do not add a raw-email column, normalized-email duplicate, `CITEXT`, or an expression-based second source of truth.
- `first_name` and `last_name` must preserve the approved display spelling, punctuation, and accents while enforcing the approved persisted form: trimmed/collapsed, 1-100 characters, and at least one alphabetic character.
- `middle_initial` must be null or one stored uppercase alphabetic character without a period.
- `phone` must be null or contain only digits, spaces, plus signs, parentheses, hyphens, and periods, with 7-15 digits total.
- `newsletter_subscribed` is the only persistent newsletter source of truth.
- Do not store confirmation email, normalized phone digits, authentication data, verification data, automatic-prefill data, newsletter history, or customer profile history.

Implement deterministic named constraints consistent with DB-03, including:

- `customers_pk`;
- `customers_email_uq`;
- `customers_first_name_ck`;
- `customers_middle_initial_ck`;
- `customers_last_name_ck`;
- `customers_email_canonical_ck`;
- `customers_phone_ck`.

Database checks are defense in depth. They must not pretend to replace later Flask Unicode-aware input normalization, complete email syntax validation, or customer-matching workflows. Use PostgreSQL checks that faithfully enforce the approved persisted form without rejecting approved punctuation or accents.

### `reservation_configuration`

Implement:

| Column | PostgreSQL representation | Nullability | Default |
|---|---|---|---|
| `configuration_id` | `SMALLINT` | Not null | `1` |
| `start_interval_minutes` | `SMALLINT` | Not null | `30` |
| `reservation_duration_minutes` | `SMALLINT` | Not null | `90` |
| `advance_booking_window_days` | `SMALLINT` | Not null | `60` |
| `same_day_lead_minutes` | `SMALLINT` | Not null | `120` |
| `restaurant_timezone` | `TEXT` | Not null | `America/New_York` |

Required integrity behavior:

- `configuration_id` is the primary key.
- Only singleton key value `1` is permitted, guaranteeing at most one current row.
- `start_interval_minutes` permits only `15`, `30`, or `60`.
- `reservation_duration_minutes` permits only `60`, `90`, or `120`.
- `advance_booking_window_days` permits inclusive values `1` through `365`.
- `same_day_lead_minutes` permits inclusive values `0` through `1440`.
- `restaurant_timezone` must be trimmed, nonempty, and reasonably bounded as technical text in the manner approved by DB-03.
- Valid IANA timezone membership must be verified against PostgreSQL-supported timezone names during initialization and tests; do not misrepresent a non-immutable catalogue lookup as an ordinary row check.
- Do not add configuration history, effective dates, version relationships, or copied configuration values elsewhere.

Implement deterministic named constraints consistent with DB-03, including:

- `reservation_configuration_pk`;
- `reservation_configuration_singleton_ck`;
- `reservation_configuration_interval_ck`;
- `reservation_configuration_duration_ck`;
- `reservation_configuration_window_ck`;
- `reservation_configuration_lead_ck`;
- `reservation_configuration_timezone_ck`.

### `restaurant_operating_hours`

Implement:

| Column | PostgreSQL representation | Nullability | Default |
|---|---|---|---|
| `weekday` | `SMALLINT` | Not null | No default |
| `opens_at` | `TIME WITHOUT TIME ZONE` | Not null | No default |
| `closes_at` | `TIME WITHOUT TIME ZONE` | Not null | No default |

Required integrity behavior:

- `weekday` is the primary key and uses ISO values `1=Monday` through `7=Sunday`.
- The weekday range is limited to 1-7.
- At most one rule may exist for a weekday.
- `opens_at` and `closes_at` are restaurant-local recurring wall-clock boundaries.
- Opening must be strictly earlier than closing.
- Version 1 has exactly one same-day open period for every weekday.
- Do not add closed-day representation, overnight service, multiple daily periods, holiday exceptions, date-specific closures, or schedule history.

Implement deterministic named constraints consistent with DB-03, including:

- `restaurant_operating_hours_pk`;
- `restaurant_operating_hours_weekday_ck`;
- `restaurant_operating_hours_bounds_ck`.

The schema can limit possible weekday identities to seven but cannot declaratively prove that all seven rows exist. Initialization and tests must prove completeness.

### `restaurant_tables`

Implement:

| Column | PostgreSQL representation | Nullability | Default |
|---|---|---|---|
| `table_number` | `SMALLINT` | Not null | No default |
| `seating_capacity` | `INTEGER` | Not null | `4` |

Required integrity behavior:

- `table_number` is the stable SRS Table Number and primary key.
- Table number must be positive.
- Seating capacity must be positive.
- Exactly 30 Version 1 table rows are created by initialization.
- Initial table numbers are 1 through 30.
- Every initial table has capacity four.
- Initial derived total capacity is 120.
- Do not add a surrogate table ID, active/inactive state, adjacency, combinability, location, table-sharing, or capacity-total column.

Implement deterministic named constraints consistent with DB-03, including:

- `restaurant_tables_pk`;
- `restaurant_tables_number_ck`;
- `restaurant_tables_capacity_ck`.

The schema must validate each row but must not pretend a row-level check can guarantee exactly 30 rows. Seed/reset controls, privileges, initialization checks, and integration tests enforce that population invariant.

## Index requirements and redundancy

Implement only the foundation indexes required by approved DB-03.

PostgreSQL automatically creates indexes for:

- `customers.customer_id` through `customers_pk`;
- `customers.email` through `customers_email_uq`;
- `reservation_configuration.configuration_id` through its primary key;
- `restaurant_operating_hours.weekday` through its primary key;
- `restaurant_tables.table_number` through its primary key.

Do not create redundant manual indexes on those same keys. Do not add speculative indexes on newsletter state, configuration values, opening/closing times, or seating capacity.

The reservation, interval, fingerprint, and assignment indexes approved in DB-03 belong to DB-06 because their tables do not exist yet.

Produce an index verification test or catalogue query showing that each constraint-owned index exists and no duplicate foundation index was introduced.

## Seed and initialization data

Create deterministic, repeatable seed or initialization artifacts for the exact approved baseline.

### Scalar configuration seed

Create exactly one row:

| `configuration_id` | `start_interval_minutes` | `reservation_duration_minutes` | `advance_booking_window_days` | `same_day_lead_minutes` | `restaurant_timezone` |
|---:|---:|---:|---:|---:|---|
| 1 | 30 | 90 | 60 | 120 | `America/New_York` |

### Recurring-hours seed

Create exactly these seven rows:

| ISO weekday | Day | Opens | Closes |
|---:|---|---|---|
| 1 | Monday | 17:00 | 23:00 |
| 2 | Tuesday | 17:00 | 23:00 |
| 3 | Wednesday | 17:00 | 23:00 |
| 4 | Thursday | 17:00 | 23:00 |
| 5 | Friday | 17:00 | 23:00 |
| 6 | Saturday | 17:00 | 23:00 |
| 7 | Sunday | 17:00 | 21:00 |

PostgreSQL is the only authoritative source for these recurring hours. Do not copy authoritative hour constants into Flask or React.

### Restaurant-table seed

Create table numbers 1 through 30, each with `seating_capacity = 4`.

### Seed behavior

Seed behavior must be deterministic and safe for the documented use case. A repeated approved initialization should either converge to the exact baseline or fail clearly when unexpected state would otherwise be overwritten. Do not silently erase legitimate data.

The test/reset workflow must verify:

- one and only one configuration row with key 1;
- a valid `America/New_York` timezone in the running PostgreSQL installation;
- exactly seven operating-hours rows with weekday values 1-7 and exact SRS boundaries;
- exactly 30 restaurant-table rows numbered 1-30;
- every initial capacity equals four;
- derived total capacity equals 120;
- no reservation or assignment table exists during DB-05.

## `pgcrypto` readiness

Approved DB-04 selected SHA-256 through PostgreSQL's standard `pgcrypto` extension for later DB-06 fingerprint generation.

In DB-05:

- add the versioned migration or environment-readiness step needed to establish `pgcrypto` in approved development/test deployments;
- verify that the extension is installed and that the required digest capability is available;
- document any elevated migration privilege required;
- fail clearly with actionable setup guidance if the deployment role cannot install the extension;
- do not implement reservation fingerprints, canonical serialization, or digest calls against reservation data yet;
- do not add another extension.

If the repository targets a managed PostgreSQL service where extension creation is environment-owned, keep the migration/readiness behavior explicit and portable; do not conceal the dependency.

## Roles and privileges

Implement the smallest role/privilege foundation that supports later enforcement without creating passwords or environment-specific secrets in the repository.

Use existing repository role names and conventions when present. If none exist, choose clear technical names and document them.

At minimum distinguish conceptually between:

- a migration/owner capability that can create schema objects, extensions when permitted, and controlled deployment objects;
- an ordinary application/runtime capability that cannot alter schema, disable constraints, change ownership, or bypass future controlled booking operations;
- a test/migration capability appropriate to isolated development/test databases.

For DB-05:

- grant only the access actually needed by the current foundation and future controlled operations;
- prevent ordinary runtime use from deleting the singleton configuration row, weekday rows, or restaurant-table inventory through unrestricted direct mutation;
- prevent ordinary runtime use from altering schema or seed structure;
- keep controlled future configuration/hours/capacity writers compatible with the DB-04 restaurant-wide lock protocol;
- do not grant superuser-like privileges;
- do not embed `CREATE ROLE ... PASSWORD` secrets or environment credentials;
- do not create reservation-operation execute grants because those operations do not exist until DB-06.

If PostgreSQL role creation is intentionally environment provisioning rather than an ordinary transactional migration, separate it cleanly and document its required execution context.

Automated tests must verify the important privilege boundaries using non-owner roles when the environment supports role testing. If role creation cannot run in the available environment, provide repeatable verification instructions and clearly report the limitation.

## Advisory-lock and timeout readiness

DB-04 approved a later `READ COMMITTED` booking transaction using:

- one transaction-scoped restaurant-wide advisory lock; and
- one per-canonical-email transaction-scoped advisory lock.

DB-05 must document a stable, deterministic advisory-lock namespace/key convention that DB-06 can implement without collisions between these two lock families. It may define constants or derivation documentation in database technical documentation or migration-adjacent metadata, but it must not create a lock table or implement booking lock acquisition.

Document:

- the reserved restaurant-wide lock identity;
- the separate namespace for canonical-email lock derivation;
- how later DB-06 key derivation avoids accidental overlap between namespaces;
- that random table selection never controls lock order;
- that controlled configuration, operating-hours, and table-capacity writers must share the restaurant-wide coordination protocol once those writers exist.

Select or expose bounded lock/statement timeout defaults appropriate to development/test verification only if the current repository already has a clean database-configuration location. Otherwise document the required configuration point for DB-06 rather than adding an application configuration system prematurely.

Do not implement DB-04's booking transaction, customer-email locking behavior, bounded retry loop, or transaction outcome classes in DB-05.

## Migration design

Create a clear, versioned migration sequence with explicit dependencies. The sequence must at least establish:

1. required schema namespace and `pgcrypto` readiness, consistent with repository conventions;
2. the four DB-05 foundation tables;
3. all approved foundation constraints and constraint-owned indexes;
4. required roles/privileges or a clearly separated environment-provisioning artifact;
5. exact baseline seed/initialization data;
6. verification that the initialized database satisfies the DB-05 population invariants.

Keep schema migration and development sample data distinct when the repository's tooling supports that separation. The five scalar configuration values, seven operating-hours rows, and 30 restaurant tables are required business initialization, not optional demo content.

Support one of the following, selected consistently with the repository:

- reliable migration rollback plus forward replay; or
- a documented clean-database rebuild from versioned migrations when destructive down migrations would be unsafe or misleading.

Do not promise reversibility for an extension or role operation when the environment cannot safely guarantee it. Document the exact policy.

Every migration and seed artifact must be deterministic, noninteractive, and fail on unexpected errors. Do not hide failed statements or continue after an integrity failure.

## Development/test reset and rebuild

Provide a controlled reset/reinitialization workflow for designated nonproduction environments only.

The workflow must:

- require an explicit development/test safety guard;
- refuse to run against an environment identified as production or otherwise not explicitly designated for reset;
- operate only on the intended Cafe Fausse database/schema;
- rebuild from versioned migrations and required initialization data;
- restore the one configuration row, seven SRS hours rows, and 30 capacity-four tables;
- leave the database in a state that passes all DB-05 verification;
- use explicit object/dependency handling rather than broad destructive commands against an unresolved database or filesystem target;
- anticipate that later DB-06 reset logic will delete assignment and reservation data before customer/foundation state, without creating those objects now.

Do not write production data-retention or purge behavior. Controlled nonproduction reset is the only deletion-oriented workflow in this increment.

## Automated database test plan and implementation

Create executable database-focused tests using the repository's established test framework. If none exists, choose a minimal repeatable approach appropriate for PostgreSQL and document it.

Tests must use an isolated disposable development/test database, not production. Each test or suite must establish a known state and avoid ordering dependence.

Cover at least the following.

### Migration and rebuild

- clean database migration succeeds;
- clean rebuild succeeds repeatedly;
- migrations fail visibly on errors;
- all four and only the four DB-05 business tables exist;
- no `reservations` or `reservation_table_assignments` table exists;
- expected constraint names and definitions exist;
- expected primary-key/unique indexes exist;
- no redundant foundation index exists;
- `pgcrypto` and required digest capability are available;
- required roles/grants are present where environment-supported.

### Customer integrity

- valid customer insertion succeeds;
- `customer_id` is database-generated and unique;
- missing first name, last name, email, or newsletter state is rejected;
- default newsletter state is false;
- current newsletter state can be set to true or false without deleting the customer;
- canonical lowercase email is accepted;
- uppercase, outer-whitespace, empty, or over-254-character persisted email is rejected;
- duplicate canonical email is rejected;
- first and last names at valid boundaries are accepted;
- blank, whitespace-only, over-100-character, or letterless first/last names are rejected;
- display punctuation and accents permitted by the approved rules are preserved;
- null middle initial succeeds;
- one normalized uppercase alphabetic middle initial succeeds;
- lowercase, punctuation, multi-character, or empty-string middle initial is rejected according to the approved nullable representation;
- null phone succeeds;
- permitted phone formatting with 7-15 digits succeeds;
- disallowed characters, fewer than 7 digits, or more than 15 digits are rejected;
- no confirmation-email, newsletter-history, raw-email, normalized-phone, authentication, profile, or audit column exists.

### Configuration integrity

- the exact default singleton row exists;
- a second configuration row is rejected;
- deletion protection or privilege controls preserve the required row for the ordinary runtime role;
- every allowed interval and duration value is accepted;
- every disallowed interval and duration value is rejected;
- advance-window boundaries 1 and 365 are accepted and values outside them rejected;
- lead-time boundaries 0 and 1440 are accepted and values outside them rejected;
- trimmed nonempty timezone text is required;
- the seeded `America/New_York` value exists in the running PostgreSQL timezone catalogue;
- alternate permitted configuration values can be installed in an isolated test and restored by reset;
- no configuration history/effective-date object exists.

### Operating-hours integrity

- exactly seven seeded rows exist;
- weekday identities are exactly 1 through 7;
- Monday-Saturday are 17:00-23:00;
- Sunday is 17:00-21:00;
- duplicate weekday is rejected;
- weekday outside 1-7 is rejected;
- null boundaries are rejected;
- opening equal to or later than closing is rejected;
- controlled alternate same-day recurring hours can replace test data without changing schema or application logic;
- reset restores the exact SRS schedule;
- no holiday, exceptional-date, closed-day, overnight, multi-period, or schedule-history object exists.

### Restaurant-table integrity

- exactly 30 seeded rows exist;
- table numbers are exactly 1 through 30;
- every seeded capacity is four;
- derived total capacity is 120;
- duplicate table number is rejected;
- zero or negative table number is rejected;
- zero or negative capacity is rejected;
- controlled alternate positive capacity can be used in an isolated test and reset restores the baseline;
- ordinary runtime privileges cannot silently add a 31st table or remove an initialized table;
- no active flag, adjacency, combinability, location, total-capacity, or maximum-party-size column exists.

### Privilege and safety behavior

- ordinary runtime capability cannot alter/drop schema objects;
- ordinary runtime capability cannot disable or bypass approved constraints;
- required read access for future application integration is available;
- prohibited direct foundation mutation is rejected as designed;
- reset refuses an environment that lacks the explicit nonproduction guard;
- no role password or credential is stored in repository artifacts.

Use direct catalogue verification where appropriate, but test behavior rather than relying only on matching SQL source text.

## Manual verification

Provide exact, non-destructive commands for a reviewer to:

1. create or start an isolated PostgreSQL development/test environment;
2. apply migrations from a clean database;
3. apply required initialization data;
4. inspect the four foundation tables, columns, defaults, constraints, and indexes;
5. verify `pgcrypto` readiness;
6. verify the singleton configuration values;
7. verify all seven SRS operating-hours rows;
8. verify 30 tables at capacity four and total capacity 120;
9. run the automated database tests;
10. perform the guarded reset and rerun verification.

Commands must be copyable, must not expose credentials, and must identify any required environment variables through a safe example file.

## Documentation requirements

Create or update database documentation that explains:

- prerequisites and supported PostgreSQL version discovered from the project environment;
- required environment variables without secret values;
- exact folder placement and purpose of every DB-05 file;
- migration order and execution commands;
- initialization/seed behavior;
- guarded reset/rebuild behavior;
- test commands;
- role/privilege model;
- `pgcrypto` deployment requirement;
- advisory-lock namespace reserved for DB-06;
- population invariants and why they are verified rather than represented by misleading row constraints;
- SRS and PRA traceability;
- DB-05 exclusions and DB-06 handoff.

Do not duplicate the full approved design documents. Link or refer to them and document only what implementers and reviewers need to operate and verify this increment.

## Source-of-truth and normalization safeguards

Verify that the implementation preserves one authoritative logical home for every DB-05 fact:

| Fact | Sole authoritative home |
|---|---|
| Customer identity and structured name | `customers` |
| Canonical email and optional phone | `customers` |
| Current newsletter Boolean | `customers.newsletter_subscribed` |
| Current five scalar reservation settings | `reservation_configuration` |
| Current recurring weekly hours | `restaurant_operating_hours` |
| Individual table identity and current capacity | `restaurant_tables` |

Do not persist derived total capacity, maximum party size, latest start, slot lists, availability, candidate combinations, or duplicate display/configuration values.

The DB-05 implementation must remain in at least third normal form and must not add an unnecessary entity, column, identifier, index, or extension.

## PostgreSQL-versus-later-layer boundary

DB-05 PostgreSQL is authoritative for:

- entity identity;
- canonical persisted email uniqueness;
- required values and simple domain limits;
- the current newsletter Boolean field;
- permitted scalar configuration values;
- the current recurring schedule rows and same-day boundaries;
- table identities and positive capacities;
- migrations, seeds, constraints, indexes, privileges, and all-or-nothing statements;
- initialization and population verification;
- `pgcrypto` readiness.

Later Flask work remains responsible for:

- request-format and full email-syntax validation;
- Unicode-aware normalization before persistence;
- case-insensitive customer-name matching;
- optional middle-initial and phone populate/preserve/conflict workflows;
- user-facing messages;
- API contracts and application orchestration.

DB-06 remains responsible for:

- reservation and assignment schema objects;
- booking and provisional-availability database operations;
- fingerprint generation and collision-safe retry handling;
- customer creation/reuse concurrency behavior during booking;
- same-customer overlap and table exclusivity;
- multi-table allocation and random ties;
- transaction locks, retries, rollback, and concurrency tests.

React is non-authoritative and outside this increment.

## Explicit Version 1 and DB-05 exclusions

Do not add or implement:

- reservation or assignment tables in this increment;
- authentication or authorization profiles;
- verified customer profiles or email ownership verification;
- automatic form prefilling;
- general customer profile-update workflows;
- newsletter subscription history or audit events;
- confirmation-email persistence;
- reservation cancellation, modification, rescheduling, status, no-show, archive, or purge behavior;
- administrative reservation management;
- availability, slot, free/busy, hold, queue, or candidate tables;
- fingerprint, retry, allocation, overlap, or booking operations;
- holiday/date-specific hours, closed recurring weekdays, overnight hours, multiple service periods, or schedule history;
- configuration history or effective dating;
- table active/inactive state, adjacency, combinability, sharing, or seat-level data;
- email/SMS delivery state;
- generic audit columns or history tables;
- Flask, API, React, or end-to-end integration code.

## Traceability requirements

Provide a concise implementation traceability matrix covering at least:

- SRS FR-02, FR-07, FR-16, FR-17, and FR-18;
- SRS NFR-05 and NFR-09;
- PRA-005 through PRA-012;
- PRA-015 through PRA-017;
- PRA-019 through PRA-021;
- PRA-029;
- approved DB-03 foundation tables, columns, constraints, defaults, and indexes;
- approved DB-04 `pgcrypto`, role, advisory-lock namespace, and environment-readiness handoff items.

For each item identify the implementing file/object and the automated or manual verification evidence. Mark later reservation-dependent behavior as DB-06 rather than falsely claiming DB-05 completion.

## Required deliverables

At completion, provide all of the following in the repository:

- versioned PostgreSQL migration files;
- foundation schema objects for the four approved tables;
- all approved foundation constraints and nonredundant indexes;
- `pgcrypto` readiness implementation and verification;
- exact scalar configuration, recurring-hours, and 30-table initialization artifacts;
- role/privilege artifacts or clearly separated provisioning instructions;
- stable DB-06 advisory-lock namespace/key documentation;
- guarded development/test reset and clean-rebuild artifacts;
- database unit tests;
- clean-database integration/rebuild verification;
- setup, migration, initialization, reset, and test instructions;
- DB-05 implementation report and traceability matrix;
- an explicit list of everything deferred to DB-06.

## Required final response

When implementation and verification are complete, report:

1. DB-05 implementation summary;
2. files added or changed, with each file's purpose;
3. exact migration and initialization sequence;
4. exact setup, reset, and test commands;
5. implemented tables, columns, constraints, indexes, roles, and extension readiness;
6. seed verification results for one configuration row, seven operating-hours rows, 30 tables, and capacity 120;
7. automated test results, including counts and any skipped or unexecuted tests;
8. manual verification performed;
9. source-of-truth and normalization confirmation;
10. SRS, rubric, PRA, DB-03, and DB-04 traceability summary;
11. repository status summary limited to this increment's changes;
12. unresolved blockers or deviations, if any;
13. DB-05 completion assessment;
14. DB-05 approval checkpoint.

Do not claim DB-05 complete if required migrations, initialization, safety guards, or tests are missing or unverified. Do not claim the PostgreSQL phase complete; DB-06 and DB-07 remain.

## Stop conditions

Stop and request approval rather than choosing silently if:

- an authoritative source contradicts the approved DB-03 schema;
- implementation requires changing an approved table, column, type, key, nullability, default, constraint, or index decision;
- a new table, business fact, extension, trigger, history structure, or active/inactive behavior appears necessary;
- the repository already contains a conflicting database implementation whose treatment would be destructive or ambiguous;
- safe nonproduction targeting for reset cannot be established;
- a proposed role model would make the approved later DB-06 operation impossible or would expose unrestricted ordinary writes.

Ordinary technical choices squarely within DB-05 should be implemented, tested, and documented without reopening approved business decisions.

## Completion and next increment

DB-05 is complete only when a clean PostgreSQL development/test database can be created reproducibly, all four foundation tables and approved constraints are present, exact initialization data is verified, `pgcrypto` readiness is proven, role/reset safeguards are documented and tested where possible, and all required foundation tests pass.

Present the result for explicit DB-05 approval.

Approval of DB-05 would authorize only **DB-06 - Reservation Persistence, Allocation, and Concurrency Implementation**. Do not begin DB-06 in this prompt.
