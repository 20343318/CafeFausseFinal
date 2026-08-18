# Cafe Fausse DB-05 database foundation

This directory implements only DB-05. It creates the `cafe_fausse` PostgreSQL
schema, the four approved foundation tables, exact required initialization,
`pgcrypto` readiness, passwordless group roles, guarded reset tooling, and
database-focused verification. Reservation and assignment objects belong to
DB-06 and are intentionally absent.

## Prerequisites

- PostgreSQL 14 or newer; DB-05 was developed against PostgreSQL 18.3.
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
| `reset/001_drop_foundation_schema.sql` | Revalidates the nonproduction guard and drops only the fixed `cafe_fausse` schema. |
| `migrations/001_pgcrypto_and_schema.sql` | Installs/verifies `pgcrypto` SHA-256 and creates the owned schema. |
| `migrations/002_foundation_tables.sql` | Creates the four exact DB-03 foundation tables and 20 named constraints. |
| `migrations/003_baseline_seed.sql` | Inserts the singleton configuration, seven SRS hours, and tables 1-30 at capacity four; fails if invariants differ. |
| `migrations/004_foundation_privileges.sql` | Grants runtime read-only access and isolated test DML while withholding direct runtime mutation and DDL. |
| `verification/verify_db05.sql` | Verifies schema, columns, constraints, five constraint-owned indexes, extension, roles, and exact populations. |
| `tests/db05_behavior_tests.sql` | Exercises valid and invalid writes transactionally and rolls business-row changes back. |
| `tests/runtime_privilege_denials.sql` | Uses the ordinary runtime role and proves five prohibited writes/DDL operations fail. |
| `scripts/*.ps1` | Locates `psql`, enforces targeting, rebuilds, verifies, and runs the suite. |
| `ADVISORY_LOCKS.md` | Reserves collision-separated lock namespaces for DB-06 without acquiring locks. |
| `DB05_IMPLEMENTATION_REPORT.md` | Records technical decisions, traceability, exclusions, and the approval checkpoint. |

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
4. apply migrations `001` through `004` with `ON_ERROR_STOP`;
5. run the complete verification query.

The seed uses ordinary inserts. It never overwrites unexpected state: replay
without a clean rebuild fails on existing schema/keys, while the documented
guarded rebuild returns the exact approved baseline.

## Verify and test

Read-only verification of an existing DB-05 build:

```powershell
pwsh -File database/scripts/verify.ps1
```

Full automated suite, including a refused reset, an intentional fail-visible
SQL error, two clean rebuilds, constraint tests, and runtime-role denial tests:

```powershell
pwsh -File database/scripts/test.ps1
```

The intentional division-by-zero check and the five expected permission-denied
attempts print PostgreSQL `ERROR` lines. The runner treats those exact failures
as passing evidence and still exits zero only when the entire suite succeeds.

The behavior test runs in a transaction and rolls back its customer and
configuration changes. The full test script is destructive only to the fixed
`cafe_fausse` schema in the explicitly authorized nonproduction database.

## Manual inspection

Connect with `psql`, then run:

```sql
\dn+ cafe_fausse
\dt+ cafe_fausse.*
\d+ cafe_fausse.customers
\d+ cafe_fausse.reservation_configuration
\d+ cafe_fausse.restaurant_operating_hours
\d+ cafe_fausse.restaurant_tables

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

Expected baseline: one configuration row `(1,30,90,60,120,
America/New_York)`; weekdays 1-6 at `17:00-23:00`; weekday 7 at
`17:00-21:00`; table numbers 1-30, every capacity four, total 120; five
constraint-owned indexes; no `reservations` or
`reservation_table_assignments` table.

## Role model

- `cafe_fausse_owner`: non-login schema owner/migration capability. The
  provisioning administrator becomes a member; no password is created.
- `cafe_fausse_app`: non-login ordinary runtime capability. It can use the
  schema and read current foundation facts, but cannot insert/update/delete,
  truncate, create, alter, or drop them. DB-06 may grant only `EXECUTE` on its
  future controlled operations.
- `cafe_fausse_test`: non-login isolated test capability with foundation DML
  and identity-sequence access, but no schema ownership or superuser powers.

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

PostgreSQL enforces persisted canonical form and simple integrity. Later Flask
work remains responsible for full email syntax and Unicode-aware input
normalization/matching. DB-06 remains responsible for reservation and
assignment tables, availability, fingerprints, advisory-lock acquisition,
allocation, exclusivity, and transaction retries.
