# Prompt 17 --- Implement API-08 Reservation Creation

## Objective

Implement the next Flask backend increment: complete reservation
creation using the frozen PostgreSQL contract and the completed API-07
reservation discovery capability.

API-07 is approved and frozen.

Do not modify API-07 behavior unless a defect is discovered.

## Requirements Baseline

Use the following as authoritative sources:

-   SRS.pdf
-   Rubric.pdf
-   Approved Project Requirements Addendum
-   Completed API-07 contract
-   Current repository implementation

Maintain:

-   PostgreSQL → Flask → React implementation order.
-   Least-to-most implementation strategy.
-   Existing approved contracts and architectural decisions.

## Scope

Implement only API-08 reservation creation.

Include:

-   Reservation submission endpoint.
-   Customer creation/reuse behavior.
-   Reservation validation.
-   Table availability determination.
-   Random table assignment.
-   Transactional persistence.
-   Success and failure responses.

Do not implement:

-   React UI.
-   Newsletter changes.
-   Deployment changes.
-   Unapproved schema changes.
-   Later API phases.

## Reservation Creation Requirements

The implementation must:

1.  Accept reservation creation requests using the approved API
    contract.

2.  Validate:

    -   customer information;
    -   email format;
    -   phone rules;
    -   party size;
    -   requested reservation date/time;
    -   reservation slot validity.

3.  Independently validate the requested slot.

The backend remains authoritative even if a future React client only
displays valid slots.

4.  Determine availability using:

    -   configured reservation duration;
    -   existing reservations;
    -   approved table assignment rules.

5.  Assign a table randomly from available tables.

6.  Persist the reservation transactionally.

7.  Prevent:

    -   double booking;
    -   overlapping table assignments;
    -   inconsistent customer/reservation state.

8.  Return:

    -   successful reservation confirmation;
    -   appropriate failure responses.

## Database Requirements

Do not silently modify the approved PostgreSQL schema.

Use existing database contracts.

If implementation reveals a schema gap:

-   Stop.
-   Document the gap.
-   Explain the impact.
-   Present alternatives.
-   Obtain approval before changing the schema.

## Testing Requirements

Add or update automated tests.

### Unit tests

Cover:

-   validation;
-   service behavior;
-   customer handling;
-   table selection;
-   failure conditions.

### Integration tests

Cover:

-   successful reservation creation;
-   invalid requests;
-   unavailable slots;
-   full capacity;
-   rollback behavior;
-   PostgreSQL persistence;
-   concurrency and double-booking protection.

### TestInstructions.md

Update as required.

Maintain:

-   repeatable execution;
-   restart safety;
-   cleanup of created resources;
-   final cleanup verification.

## Completion Requirements

Before stopping:

Provide:

-   changed files;
-   implementation summary;
-   API contract changes, if any;
-   tests added or updated;
-   test execution results;
-   deviations from approved requirements;
-   unresolved risks.

Stop at the API-08 approval checkpoint.

Do not begin React work.
