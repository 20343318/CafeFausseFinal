# Prompt 17C --- API-08 Implementation Correction

## Objective

Complete the API-08 implementation correction work after the approved
API-08 contract reconciliation checkpoint.

Approved reconciliation decisions:

-   API08-RC-01: deterministic distinction between caller-controlled
    party-size failures and server-controlled reservation-duration
    configuration failures.
-   API08-RC-02: OP-05 post-commit confirmation reconstruction may
    retrieve stored customer name components and current restaurant IANA
    timezone solely for API-02-compliant confirmation serialization.

Do not reopen these decisions unless a defect makes implementation
impossible.

## Authoritative Baseline

Use:

-   SRS.pdf
-   Rubric.pdf
-   Approved Project Requirements Addendum
-   Approved API-01 Backend Operation Inventory
-   Approved API-02 Flask REST Contract
-   Approved API-03 Flask Architecture, Configuration, and Test Strategy
-   Reconciled PostgreSQL contract
-   Current repository implementation

Maintain:

-   PostgreSQL → Flask → React implementation order.
-   Least-to-most implementation strategy.
-   Existing approved contracts and architecture.

## Scope

Implement only the remaining API-08 corrections:

1.  Stored customer name formatting.
2.  Flask error classification mapping.
3.  Confirmation local-time serialization.

Do not implement:

-   API-09.
-   React work.
-   Frontend changes.
-   Deployment work.
-   Unapproved schema changes.
-   Unrelated refactoring.

## Required Implementation Changes

### Stored Customer Name Formatting

Correct confirmation customer-name formatting to comply with API-02.

Requirements:

-   Use stored customer identity values.
-   Preserve stored spelling rules.
-   Render optional middle initial using the approved `X.` format.

Example:

-   stored middle initial: `M`
-   serialized customer name: `Ada M. Rivera`

Update affected tests.

### Error Classification Mapping

Consume the reconciled PostgreSQL outcomes.

Required behavior:

-   Caller-controlled invalid party size:
    -   PostgreSQL outcome: `invalid_request`
    -   HTTP response: `422 validation_failed`
-   Server-controlled invalid reservation duration:
    -   PostgreSQL outcome: `invalid_database_configuration`
    -   HTTP response: `503 service_unavailable`

Do not use request-based heuristics.

Do not change unrelated error mappings.

### Confirmation Local-Time Serialization

Update confirmation serialization to use authoritative restaurant
timezone information.

Requirements:

-   Use committed reservation instants as the source of truth.
-   Use the reconciled OP-05 authorized restaurant IANA timezone.
-   Calculate start and end local values independently using IANA
    timezone rules.
-   Do not use a submitted fixed UTC offset as the authoritative
    timezone.

Verify behavior across timezone offset transitions.

## Database Constraints

Do not change:

-   schema;
-   table definitions;
-   constraints;
-   roles;
-   grants;
-   routine signatures;
-   result shapes;
-   allocation logic;
-   retry behavior.

If any of these require modification, stop and report the gap.

## Testing Requirements

Update tests to prove:

-   middle-initial formatting;
-   party-size error mapping;
-   duration configuration error mapping;
-   timezone-aware confirmation serialization;
-   reservation creation integration behavior;
-   rollback;
-   retry;
-   concurrency protection.

Update TestInstructions.md only if execution procedures changed.

Maintain:

-   repeatable execution;
-   restart safety;
-   cleanup;
-   final cleanup verification.

## Completion Requirements

Before stopping, provide:

-   changed files;
-   implementation summary;
-   requirement traceability;
-   tests added or updated;
-   verification results;
-   deviations;
-   unresolved risks.

Confirm:

-   API-08 only was changed.
-   API-08 reconciliation decisions remain intact.
-   No React work started.
-   No unapproved schema or architectural changes introduced.

Stop at the API-08 correction verification checkpoint.

Do not declare API-08 approved.
