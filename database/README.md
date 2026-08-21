# Cafe Fausse PostgreSQL layer through DB-07

DB-07 was explicitly approved by Abdul at Hard Gate 1 on 2026-08-20. The next
authorized increment is API-01, a design-only backend operation inventory, but
it must not begin without a separate instruction. Flask implementation,
REST-contract design, API-02 or later increments, React work, and changes to the
approved PostgreSQL Contract for Flask v1.0 remain unauthorized.

This directory preserves the approved DB-05 PostgreSQL foundation and extends
it with DB-06 reservation persistence, provisional availability, authoritative
booking, exact table allocation, transaction locking, hardened role boundaries,
guarded reset tooling, and the DB-07 verification and Hard Gate 1 evidence.

## Prerequisites

- PostgreSQL 18.3. This is the required, implemented, and verified Version 1
  database version; compatibility with other PostgreSQL versions is outside
  the verified Version 1 contract.
- `psql` on `PATH`, or `CAFE_FAUSSE_PSQL` set to its executable path.
- An isolated database whose name matches
  `cafe_fausse_dev*`, `cafe_fausse_test*`, or `cafe_fausse_demo*`.
- A database administrator for the one-time passwordless group-role and
  `pgcrypto` provisioning. Managed services may require an environment owner
  to enable the trusted `pgcrypto` extension first.

Do not target production or production-like data. The scripts never choose a
default database: `PGDATABASE` is required and its actual connected name is
checked before reset.

## Environment

Use [`.env.example`](.env.example) as a list of variable names. Load values in
your shell; do not commit `.env`, `PGPASSWORD`, or credential-bearing URLs.

PowerShell example:

```powershell
$env:PGHOST = 'localhost'
$env:PGPORT = '5432'
$env:PGDATABASE = 'cafe_fausse_dev'
$env:PGUSER = 'your_local_postgres_role'
$env:CAFE_FAUSSE_ENVIRONMENT = 'development'
$env:CAFE_FAUSSE_ALLOW_RESET = 'YES'
```

If password authentication is required, set `PGPASSWORD` only in the local
shell or use a properly secured PostgreSQL password file outside the repo.

## File layout and migration order

| Path | Purpose |
|---|---|
| `provisioning/001_foundation_roles.sql` | Creates or validates passwordless owner, runtime, and test group roles and grants database-local capabilities. |
| `reset/001_drop_foundation_schema.sql` | Revalidates the nonproduction guard, deletes DB-06 dependants in FK order, and drops only the fixed `cafe_fausse` schema. |
| `migrations/001_pgcrypto_and_schema.sql` | Installs/verifies `pgcrypto` SHA-256 and creates the owned schema. |
| `migrations/002_foundation_tables.sql` | Creates the four exact DB-03 foundation tables and 20 named constraints. |
| `migrations/003_baseline_seed.sql` | Inserts the singleton configuration, seven SRS hours, and tables 1-30 at capacity four; fails if invariants differ. |
| `migrations/004_foundation_privileges.sql` | Grants runtime read-only access and isolated test DML while withholding direct runtime mutation and DDL. |
| `migrations/005_reservation_tables_and_indexes.sql` | Adds the exact approved reservation and table-assignment schema, constraints, and access-path indexes. |
| `migrations/006_reservation_internal_helpers.sql` | Adds fingerprint, timezone, email-lock-key, and exact meet-in-the-middle allocation helpers. |
| `migrations/007_availability_and_controlled_writers.sql` | Adds provisional availability, newsletter preference, and lock-compatible test/admin writers. |
| `migrations/008_authoritative_booking.sql` | Adds the authoritative booking transaction, restricted deterministic seam, and rollback injection points. |
| `migrations/009_reservation_privileges.sql` | Grants only controlled operations to runtime and reserves direct persistence/test seams for the test role. |
| `migrations/010_default_function_privileges.sql` | Corrects the owner-wide future-function default so `PUBLIC` receives no implicit execute privilege. |
| `migrations/011_allocator_exact_fast_paths.sql` | Adds measured, semantics-preserving one-table and all-tables exact allocator fast paths. |
| `verification/verify_db05.sql` | Verifies schema, columns, constraints, five constraint-owned indexes, extension, roles, and exact populations. |
| `verification/verify_db06.sql` | Verifies the six-table schema, 31 constraints, 12 indexes, routines, hardened ownership/grants, and committed invariants. |
| `verification/verify_db07.sql` | Verifies DB-07 default privileges with a rollback-only future-function probe and final population/integrity facts. |
| `verification/query_plans_db07.sql` | Collects rollback-safe `EXPLAIN (ANALYZE, BUFFERS, SETTINGS)` evidence using 200 retained-history rows. |
| `tests/db05_behavior_tests.sql` | Exercises valid and invalid writes transactionally and rolls business-row changes back. |
| `tests/runtime_privilege_denials.sql` | Uses the ordinary runtime role and proves five prohibited writes/DDL operations fail. |
| `tests/db06_behavior_tests.sql` | Exercises allocation, DST, availability, booking, retry, customer, newsletter, and rollback behavior. |
| `tests/db06_runtime_privilege_denials.sql` | Proves the runtime cannot bypass controlled DB-06 operations or invoke test seams. |
| `tests/db07_behavior_tests.sql` | Regresses the two exact allocator fast paths and the unchanged general path. |
| `scripts/concurrency_test.ps1` | Runs barrier-synchronized, database-observable multi-session races repeatedly. |
| `scripts/performance_test.ps1` | Reports DB-07 minimum/p50/p95/p99/maximum database-path measurements, group completion, individual concurrent-request latency, and contention outcomes. |
| `scripts/*.ps1` | Locates `psql`, enforces targeting, rebuilds, verifies, and runs the full suite. |
| `ADVISORY_LOCKS.md` | Documents the implemented collision-separated lock namespaces and email key derivation. |
| `DB05_IMPLEMENTATION_REPORT.md` | Records technical decisions, traceability, exclusions, and the approval checkpoint. |
| `DB06_IMPLEMENTATION_REPORT.md` | Records DB-06 traceability, concurrency, rollback, privileges, measurements, and approval checkpoint. |
| `DB07_VERIFICATION_REPORT.md` | Records the final audit, catalogues, evidence, traceability, defects, limitations, and phase-gate assessment. |
| `POSTGRESQL_CONTRACT_FOR_FLASK.md` | Freezes the versioned database-facing contract for later approved Flask design work. |
| `DB07_MANUAL_DEMONSTRATION.md` | Gives a repeatable PostgreSQL-only Hard Gate 1 demonstration. |

Migrations are intentionally psql-native and contain no migration metadata
table, because DB-05 does not authorize an additional persistent table. A
clean rebuild applies lexically sorted versioned files. Reapplying a migration
to an existing schema fails visibly; the guarded clean rebuild is the supported
replay policy. Extension and cluster roles are not automatically removed.

## Create an isolated database

As a PostgreSQL administrator, create an empty nonproduction database. This is
the only database-creation command; the repository scripts do not create or
drop databases.

```powershell
createdb cafe_fausse_dev
```

Set the environment variables above, then run:

```powershell
pwsh -File database/scripts/rebuild.ps1
```

On Windows PowerShell 5.1, use `powershell` instead of `pwsh`.

The sequence is:

1. validate environment and actual database name;
2. provision/validate the three passwordless group roles;
3. drop only `cafe_fausse` after both script and SQL guards pass;
4. apply migrations `001` through `004` and run the unchanged DB-05 verifier;
5. apply migrations `005` through `011` with `ON_ERROR_STOP`;
6. run the DB-06 and DB-07 verification queries.

The seed uses ordinary inserts. It never overwrites unexpected state: replay
without a clean rebuild fails on existing schema/keys, while the documented
guarded rebuild returns the exact approved baseline.

## Verify and test

Read-only verification of an existing DB-07 build:

```powershell
pwsh -File database/scripts/verify.ps1
```

Full automated suite, including the complete DB-05 checkpoint regression, two
DB-07 clean rebuilds, behavior and privilege tests, 20 critical concurrency
iterations, measurements, query plans, and a final empty-baseline rebuild:

```powershell
pwsh -File database/scripts/test.ps1
```

The intentional division-by-zero check and expected permission-denied attempts
print PostgreSQL `ERROR` lines. The runner treats those exact failures
as passing evidence and still exits zero only when the entire suite succeeds.

The behavior test runs in a transaction and rolls back its customer and
configuration changes. The full test script is destructive only to the fixed
`cafe_fausse` schema in the explicitly authorized nonproduction database.

Individual DB-06 evidence commands are:

```powershell
pwsh -File database/scripts/concurrency_test.ps1 -Iterations 20
pwsh -File database/scripts/performance_test.ps1 -Samples 20
```

Both require the same reset guard because they delete test rows. Concurrency
uses explicit PostgreSQL lock-wait observations as barriers. Performance data
is a local database contribution measurement, not a full-stack two-second
guarantee.

To reproduce the exact approved DB-05 checkpoint without applying DB-06:

```powershell
pwsh -File database/scripts/rebuild.ps1 -ThroughMigration 004_foundation_privileges.sql
```

## Controlled operations

The ordinary application role can execute these PostgreSQL entry points:

- `provisional_availability(date, integer)` returns authoritative instants and
  provisional capacity flags for aligned local slots. It does not reserve.
- `book_reservation(text,text,text,text,text,timestamp,smallint,integer,text)`
  performs the complete booking transaction. Newsletter action is
  `subscribe`, `unsubscribe`, or `no_change`.
- `set_newsletter_preference(text,text,text,text,boolean)` serializes by
  canonical email and updates the one authoritative newsletter Boolean.

Booking returns a stable outcome/detail, reservation identity and interval,
sorted assigned table numbers, current newsletter state, phone notice, and
fingerprint version/bytes. The test role additionally receives deterministic
tie-rank and failure-stage seams plus lock-compatible configuration writers.
Those seams are denied to the application role and `PUBLIC`.

Fingerprint version 1 hashes UTF-8 bytes of this length-prefixed serialization:

```text
<len>:<customer_id>|<len>:<UTC YYYY-MM-DDTHH:MM:SS.ffffffZ>|<len>:<party_size>
```

The allocator enumerates exact subsets with a meet-in-the-middle algorithm,
minimizes table count first and unused capacity second, and randomly selects
only among equal best candidates. Tests can select a one-based equal-best rank.

Later Flask code owns the approved retry loop: no more than three complete
attempts inside one overall deadline, restarting after retryable `55P03`,
`40P01`, or `40001` failures with short exponential backoff and jitter.

## Manual inspection

Connect with `psql`, then run:

```sql
\dn+ cafe_fausse
\dt+ cafe_fausse.*
\d+ cafe_fausse.customers
\d+ cafe_fausse.reservation_configuration
\d+ cafe_fausse.restaurant_operating_hours
\d+ cafe_fausse.restaurant_tables
\d+ cafe_fausse.reservations
\d+ cafe_fausse.reservation_table_assignments
\df+ cafe_fausse.provisional_availability
\df+ cafe_fausse.book_reservation

SELECT extension.extname, extension.extversion, namespace.nspname AS extension_schema
FROM pg_extension AS extension
JOIN pg_namespace AS namespace ON namespace.oid = extension.extnamespace
WHERE extension.extname = 'pgcrypto';
-- scripts/verify.ps1 executes a schema-qualified 32-byte SHA-256 readiness probe.

TABLE cafe_fausse.reservation_configuration;
TABLE cafe_fausse.restaurant_operating_hours;
SELECT count(*) AS table_count,
       min(table_number) AS first_table,
       max(table_number) AS last_table,
       min(seating_capacity) AS minimum_capacity,
       max(seating_capacity) AS maximum_capacity,
       sum(seating_capacity) AS total_capacity
FROM cafe_fausse.restaurant_tables;

SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'cafe_fausse'
ORDER BY tablename, indexname;
```

Expected clean DB-07 baseline: one configuration row `(1,30,90,60,120,
America/New_York)`; weekdays 1-6 at `17:00-23:00`; weekday 7 at
`17:00-21:00`; table numbers 1-30, every capacity four, total 120; five
foundation indexes plus seven DB-06 indexes; and empty `customers`,
`reservations`, and `reservation_table_assignments` tables.

## Manual DB-06 demonstration

In `psql`, the following chooses a currently valid future slot and books it as
the ordinary application role. Repeating the statement demonstrates
`exact_retry` with the same reservation ID.

```sql
SET ROLE cafe_fausse_app;
WITH chosen_slot AS MATERIALIZED (
    SELECT
        availability.local_start,
        (
            EXTRACT(epoch FROM (
                availability.local_start
                - (availability.starts_at AT TIME ZONE 'UTC')
            )) / 60
        )::smallint AS utc_offset_minutes
    FROM generate_series(CURRENT_DATE + 1, CURRENT_DATE + 45, INTERVAL '1 day') AS day(local_date)
    CROSS JOIN LATERAL cafe_fausse.provisional_availability(day.local_date::date, 4)
        AS availability
    WHERE availability.available
    ORDER BY availability.local_start
    LIMIT 1
)
SELECT booked.*
FROM chosen_slot
CROSS JOIN LATERAL cafe_fausse.book_reservation(
    'Manual', NULL, 'Guest', 'manual-guest@example.com', '202-555-0199',
    chosen_slot.local_start, chosen_slot.utc_offset_minutes,
    4, 'subscribe'
) AS booked;
RESET ROLE;
```

Inspect direct effects using the isolated test role (the application role is
intentionally denied these reads):

```sql
SET ROLE cafe_fausse_test;
SELECT * FROM cafe_fausse.customers WHERE email = 'manual-guest@example.com';
SELECT r.*, a.table_number
FROM cafe_fausse.reservations AS r
JOIN cafe_fausse.reservation_table_assignments AS a
  ON a.reservation_id = r.reservation_id
WHERE r.customer_id = (
    SELECT customer_id FROM cafe_fausse.customers
    WHERE email = 'manual-guest@example.com'
)
ORDER BY r.reservation_id, a.table_number;
RESET ROLE;
```

Use `book_reservation_test` with one of the documented failure stages in an
isolated test database to demonstrate statement-level rollback, then confirm
that its customer email, reservation, and assignments are absent. The complete
five-stage proof is automated in `tests/db06_behavior_tests.sql`. Run the
two-session lock demonstration with `concurrency_test.ps1`; it records the
database-observable barrier, both outcomes, and final invariants. Finally run
the guarded rebuild and `verify.ps1` to restore and confirm the empty baseline.

## Role model

- `cafe_fausse_owner`: non-login schema owner/migration capability. The
  provisioning administrator becomes a member; no password is created.
- `cafe_fausse_app`: non-login ordinary runtime capability. It can read current
  foundation facts and execute only the three production operations above. It
  cannot directly read reservation persistence, mutate tables, invoke test
  seams, truncate, create, alter, or drop.
- `cafe_fausse_test`: non-login isolated test capability with foundation DML
  and identity-sequence access, DB-06 persistence DML, controlled writers, and
  restricted seams, but no schema ownership or superuser powers.

Deployment login roles are environment provisioning, not repository secrets.
They can be granted membership in the appropriate group role outside these
scripts.

## Population invariants and boundaries

Row checks can prove valid values but cannot prove that a table always contains
one configuration row, all seven weekdays, or exactly 30 restaurant tables.
DB-05 therefore uses fail-fast initialization, withheld runtime mutation,
guarded clean rebuild, catalog verification, and automated tests for those
population invariants. IANA timezone membership is similarly checked against
`pg_timezone_names` during initialization and verification rather than placed
in a misleading row-level check.

PostgreSQL enforces persisted canonical form, reservation integrity, exact
retry identity, interval exclusivity through the controlled transaction, and
complete capacity-sufficient assignments. Later Flask work remains responsible
for full email syntax, Unicode-aware request normalization, and the bounded
caller retry loop. Flask, React, and end-to-end integration remain explicitly
deferred pending the applicable approval gates.
