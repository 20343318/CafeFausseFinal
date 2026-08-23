# Cafe Fausse database programmer test instructions

This optional, user-requested convenience workflow validates the approved
DB-05, DB-06, and DB-07 database increments in order. It is not required by the
SRS or rubric and is not an approved design authority.

DB-07 is approved. API-01 through API-04 were subsequently approved. This
database document does not authorize any API increment, and this correction
does not authorize API-05.

## Prerequisites and operator authorization

- Start Windows PowerShell 5.1 at the repository root. PowerShell 7 is also
  supported when available.
- PostgreSQL 18.3 must already be running and `pgcrypto` must be available.
- Use a PostgreSQL administrator capable of creating databases and roles.
- Confirm independently that the selected PostgreSQL cluster is disposable or
  otherwise approved for nonproduction database testing.

The harness restricts connections to `127.0.0.1` and verifies the exact port,
PostgreSQL version `180003`, `postgres` maintenance database, administrator,
server address, and recovery state. Those technical facts do not prove that a
cluster is nonproduction. Every command that may create or delete PostgreSQL
resources therefore requires this explicit operator-supplied value:

```powershell
$CafeNonProductionAuthorization = 'AUTHORIZED_NONPRODUCTION'
```

Do not set it until you have confirmed the selected cluster is nonproduction.
The harness has no permissive default and never supplies this authorization
for itself.

## Recommended complete command

Run from the repository root:

```powershell
& .\database\scripts\programmer_test.ps1 `
    -NonProductionClusterAuthorization $CafeNonProductionAuthorization
```

For a nondefault local port or administrator, specify both explicitly:

```powershell
& .\database\scripts\programmer_test.ps1 `
    -Port 5433 `
    -AdministratorRole cafe_local_admin `
    -NonProductionClusterAuthorization $CafeNonProductionAuthorization
```

If necessary, also add:

```powershell
-PsqlPath 'C:\Program Files\PostgreSQL\18\bin\psql.exe'
```

If neither `PGPASSWORD` nor `PGPASSFILE` is set, the script uses
`Read-Host -AsSecureString`. It temporarily places the resulting plaintext
password in `PGPASSWORD` in the current PowerShell process environment so the
PostgreSQL child tools can authenticate. The value is not echoed or written to
the repository, and `finally` restores `PGPASSWORD` to its exact prior value or
prior absence. It is not placed in a separate child PowerShell process.

An external secured `PGPASSFILE` remains optional. Do not configure both
`PGPASSWORD` and `PGPASSFILE`.

## Expected markers

A normal successful run includes:

```text
[HARNESS:AUTHORIZATION:PASS]
[HARNESS:TARGET:PASS]
[HARNESS:OWNERSHIP:PASS]
[HARNESS:DATABASE:PASS]
[HARNESS:PROVISIONER:PASS]
[HARNESS:ROLES:PASS]
[HARNESS:EXECUTION:PASS]
[HARNESS:CLEANUP-DATABASE:PASS]
[HARNESS:CLEANUP-ROLES:PASS]
[HARNESS:CLEANUP:PASS]
[HARNESS:COMPLETE:PASS]
```

Any ordinary failure prints `[HARNESS:<area>:FAIL]`, attempts ownership-proven
cleanup, restores the caller environment, and returns a failing PowerShell
error. PostgreSQL errors from intentional privilege, timeout, deadlock, and
division-by-zero tests are expected only when their enclosing test reports
`PASS`.

## What the complete command runs

The harness invokes the unchanged normative `database/scripts/test.ps1` gate
inside a generated database, followed by the final verifier:

1. DB-05 reset guard, fail-visible SQL, migrations 001-004, behavior tests,
   and runtime privilege denials.
2. Two clean DB-07 rebuilds, including the DB-06 migrations and baseline.
3. DB-06 behavior, privilege, and 20-iteration concurrency tests.
4. DB-07 behavior, 20-sample performance checks, and query-plan checks.
5. Final clean baseline rebuild and verification.
6. Ownership-proven database, role, membership, session, file, and environment
   cleanup.

No approved migration, schema rule, allocation behavior, locking behavior,
privilege assertion, concurrency iteration count, or performance sample count
is weakened.

## Created, preserved, and removed resources

Each run records a generated run ID in:

```text
%TEMP%\CafeFausse-db-test-harness\ownership.json
```

The marker is written before PostgreSQL resources. A run may then create:

- `cafe_fausse_test_harness_<run-id>` with an exact run-ID database comment;
- one unique `cafe_fausse_harness_<run-id>` NOLOGIN provisioning role with an
  exact run-ID and provisioning-state comment;
- exact direct membership edges involving that unique provisioning role;
- any missing approved fixed NOLOGIN roles, tagged with the run ID;
- the Cafe Fausse schema, routines, test data, and baseline inside the generated
  database;
- a temporary provisioning wrapper and short-lived `psql` processes.

Cleanup drops the generated database, then removes only exactly tagged roles
and exact direct membership edges involving the unique provisioning role. It
preserves the PostgreSQL server, maintenance database, administrator, every
preexisting or ambiguous database and role, every unrelated direct membership
and grant-option state, all repository files, and all caller environment
variables.

## Restart recovery and ambiguous ownership

The next invocation validates a retained marker and compares it with durable
database comments, role comments, exact role attributes, and exact direct
`pg_auth_members` edges. Matching run-owned leftovers are recovered before a
new run starts.

Use the same host, port, administrator, and authorization to recover without
running tests:

```powershell
& .\database\scripts\programmer_test.ps1 `
    -Mode CleanupOnly `
    -NonProductionClusterAuthorization $CafeNonProductionAuthorization
```

There is a small interval after `createdb` succeeds and before the database
comment is installed. The same live invocation can clean that database because
it retains an in-memory successful-creation fact. After process termination,
an administrator-owned database with a blank comment is ambiguous. Recovery
refuses to delete it; its generated-looking name and owner are not sufficient
durable proof.

For an ambiguous recovery:

1. stop and retain the marker;
2. inspect `ownership.json` without editing it;
3. independently inspect `pg_database.datdba`,
   `shobj_description(oid, 'pg_database')`, relevant role comments, direct
   `pg_auth_members` rows, and `pg_stat_activity.application_name`;
4. determine from external evidence whether the resource belongs to this run;
5. manually resolve or install missing ownership evidence only when that fact
   is independently established, then rerun `CleanupOnly`.

Malformed markers, unexpected owners, blank or mismatched durable comments,
unexpected role attributes or memberships, untagged role-name collisions, and
unexpected sessions cause refusal rather than deletion. Never delete the
marker first while PostgreSQL resources may remain.

## Diagnostic subsets

These isolated modes use the same authorization, ownership, recovery, and
cleanup model:

```powershell
& .\database\scripts\programmer_test.ps1 -Mode DB05 `
    -NonProductionClusterAuthorization $CafeNonProductionAuthorization
& .\database\scripts\programmer_test.ps1 -Mode DB06 `
    -NonProductionClusterAuthorization $CafeNonProductionAuthorization
& .\database\scripts\programmer_test.ps1 -Mode DB07 `
    -NonProductionClusterAuthorization $CafeNonProductionAuthorization
```

These are diagnostics only and do not replace the complete ordered gate.

## Harness safety validation

Maintainers can run all authorization, tagging-gap, role and membership race,
session recovery, hanging-child, outer-abort, failure-injection, preservation,
and two-run repetition checks:

```powershell
& .\database\scripts\programmer_test_safety.ps1 `
    -NonProductionClusterAuthorization $CafeNonProductionAuthorization
```

`-SkipCompleteRuns` is for harness development only and is insufficient for
release evidence. Full success ends with:

```text
[HARNESS-TEST:COMPLETE-RUN-1:PASS]
[HARNESS-TEST:COMPLETE-RUN-2:PASS]
[HARNESS-TEST:PREEXISTING-STATE:PASS]
[HARNESS-TEST:GIT-ARTIFACTS:PASS]
[HARNESS-TEST:COMPLETE:PASS]
```
