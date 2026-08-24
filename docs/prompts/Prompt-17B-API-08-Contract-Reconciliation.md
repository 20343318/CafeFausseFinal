# Prompt 17B — API-08 Contract Reconciliation

## Objective

Reconcile the approved Café Fausse backend/database contracts needed to resolve API-08 blockers 2 and 3.

This prompt authorizes contract/design-artifact reconciliation only.

Do not correct the API-08 implementation yet.

## Approved Reconciliation Decisions

### API08-RC-01 — Duration versus party-size classification

Revise the frozen PostgreSQL booking contract so that:

- an invalid server-controlled reservation duration is classified as `invalid_database_configuration`;
- caller-controlled party-size failures remain classified as `invalid_request`.

Preserve the existing result shape unless a change is strictly required.

Do not broaden this decision beyond the minimum contract/routine semantic change needed to make Flask's API-02 mapping deterministic.

### API08-RC-02 — Authoritative restaurant timezone for confirmation

Authorize OP-05's existing post-commit read-only confirmation reconstruction to retrieve only:

- stored `first_name`;
- stored `middle_initial`;
- stored `last_name`;
- current `reservation_configuration.restaurant_timezone`.

The timezone may be used only to serialize the authoritative committed reservation start and end instants into API-02-compliant restaurant-local datetimes.

Do not move business-time authority into Flask.

Do not add reservation, assignment, availability, or unrelated configuration reads.

## Authoritative Baseline

Use:

- `SRS.pdf`
- `Rubric.pdf`
- approved Project Requirements Addendum
- approved API-01 backend operation inventory
- approved API-02 Flask REST contract
- approved API-03 Flask architecture/configuration/test strategy
- frozen PostgreSQL contract for Flask
- current database migrations and privileges
- current API-08 implementation only as evidence of the reconciliation need

Preserve the PostgreSQL → Flask → React implementation order and least-to-most workflow.

## Required Reconciliation Work

Update only the approved design/contract/database artifacts required to implement API08-RC-01 and API08-RC-02 coherently.

### For API08-RC-01

Reconcile:

- the PostgreSQL booking routine semantics;
- the PostgreSQL contract consumed by Flask;
- any approved API artifact clauses that describe the affected booking outcome/detail mapping;
- database tests that prove the revised classification.

The final contract must make these cases deterministic:

- invalid caller-controlled party size → `invalid_request`;
- invalid server-controlled reservation duration → `invalid_database_configuration`.

Do not change unrelated booking outcomes/details.

### For API08-RC-02

Reconcile API-01/API-03 and any directly dependent contract text so OP-05 explicitly permits the existing post-commit read-only confirmation transaction to obtain:

- stored name components; and
- current restaurant IANA timezone.

Preserve the existing transaction boundary:

- the booking mutation transaction still contains only the authoritative booking routine;
- confirmation reconstruction remains post-commit and read-only.

Existing PostgreSQL privileges may be reused if already sufficient.

Do not add or broaden privileges unless required; if a privilege change is unexpectedly necessary, stop and report the gap instead of implementing it.

## Blocker 1

Do not correct the stored middle-initial formatting defect in this prompt.

That defect is already governed by the approved API contract and will be corrected during the subsequent API-08 implementation-fix prompt.

## Testing and Verification

Update database/contract verification only as needed for this reconciliation.

Verify at minimum:

- invalid server-controlled duration returns the newly approved server-failure classification;
- invalid party size retains the caller-error classification;
- no unrelated booking-result semantics changed;
- OP-05's authorized post-commit read scope is limited to stored name components plus current restaurant timezone;
- no schema change is introduced unless explicitly required by an approved reconciliation;
- no React or later-phase work occurs.

Update `TestInstructions.md` only if the reconciliation changes a repeatable verification procedure.

All tests must remain restartable and clean up any objects they create.

## Scope Restrictions

Do not:

- correct API-08 Flask implementation code;
- correct the middle-initial formatting defect;
- begin API-09;
- begin React work;
- redesign the reservation system;
- change unrelated PostgreSQL contracts;
- introduce unrelated schema, migration, role, grant, or deployment changes.

If either approved reconciliation cannot be implemented without materially broader changes than described above, stop and report the conflict before modifying those broader areas.

## Completion Report

Before stopping, report:

- files changed;
- exact approved artifacts reconciled;
- exact PostgreSQL contract/routine semantic changes;
- tests added or updated;
- verification results;
- whether schema, roles, grants, or result shapes changed;
- whether any unresolved contract gap remains;
- whether the repository is ready for the subsequent API-08 correction prompt.

Stop at the API-08 reconciliation approval checkpoint.

Do not begin API-08 correction work.
