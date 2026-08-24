# Prompt 16A — API-07 Contract Reconciliation Before Implementation

API-07 Phase 0 correctly identified a conflict among approved artifacts. The following correction is now approved.

Do **not** implement API-07 yet. First reconcile the approved API documentation and Prompt 16, then stop for review.

## Approved correction

For OP-02 (`GET /api/v1/reservation-availability`):

1. Keep the frozen PostgreSQL routine unchanged:
   `cafe_fausse.provisional_availability(date, integer)`

2. Keep the API-02 public REST contract unchanged.

3. Revise API-01 and API-03 only as necessary so OP-02 may, within **one `REPEATABLE READ READ ONLY` transaction/snapshot**:
   - read only `reservation_configuration.restaurant_timezone`;
   - call `cafe_fausse.provisional_availability(date, integer)`;
   - use that timezone identifier only to serialize the exact API-02 response.

4. OP-02 remains prohibited from:
   - any other foundation-table read;
   - direct reads of reservations or reservation assignments;
   - DML;
   - Flask-side availability calculations;
   - alternate availability SQL/routines;
   - changing the frozen PostgreSQL contract.

5. Preserve all existing API-03 read retry/deadline rules:
   - maximum three attempts;
   - fresh lease/transaction for each retry;
   - approved read-only retry behavior;
   - existing cleanup/disposal rules.

6. Update the committed Prompt 16 so its OP-02 database-access instructions match this approved correction:
   - replace `READ COMMITTED READ ONLY` with `REPEATABLE READ READ ONLY`;
   - permit the same-transaction read of only `reservation_configuration.restaurant_timezone`;
   - retain the unchanged call to `cafe_fausse.provisional_availability(date, integer)`;
   - retain all other API-07 scope restrictions.

## Files authorized for this correction

Modify only:

- the approved API-01 Backend Operation Inventory artifact;
- the approved API-03 Flask Architecture, Configuration, and Test Strategy artifact;
- the committed Prompt 16 markdown file under `docs/prompts`.

Do not modify:

- API-02;
- the frozen PostgreSQL Contract for Flask;
- database schema/routines/privileges;
- backend production code;
- tests;
- React/frontend;
- API-08/API-09 artifacts;
- unrelated documentation.

If the actual repository paths differ, identify the exact existing paths but do not create duplicate artifacts.

## Versioning and traceability

Preserve existing document history and formatting.

Increment the affected approved-design artifact versions minimally and document the reason:

`API-07 OP-02 timezone/snapshot reconciliation`

Do not rewrite unrelated sections.

Prompt 16 should clearly reference the corrected artifact versions.

## Git and ownership safeguards

- Preserve the real Git index.
- No staging, commit, push, reset, clean, stash, rebase, merge, branch, tag, or PR operations.
- Do not create temporary repository artifacts.
- Any temporary resource required for verification must follow the standing Durable Ownership and Cleanup Rule.

## Verification

After editing:

1. Show the exact changed paths.
2. Show concise before/after text for the OP-02 rule in API-01, API-03, and Prompt 16.
3. Verify API-02 is unchanged.
4. Verify `database/POSTGRESQL_CONTRACT_FOR_FLASK.md` is unchanged.
5. Verify no source code or test files changed.
6. Run `git diff --check`.
7. Verify the real Git index is unchanged.

## Completion checkpoint

Do not resume API-07 implementation.

Stop and report:

- corrected artifact versions;
- exact changed paths;
- concise reconciliation summary;
- verification results;
- Git-index preservation.

Wait for independent review and explicit authorization before executing revised Prompt 16.
