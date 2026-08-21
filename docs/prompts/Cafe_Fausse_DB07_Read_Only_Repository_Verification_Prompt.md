# DB-07 read-only repository verification prompt

Perform a read-only repository verification before beginning DB-07.

Do not modify files, create files, apply migrations, reset databases, install dependencies, generate artifacts, or begin DB-07 implementation.

Repository root: `CafeFausse/`

Use these exact case-sensitive paths:

- `AGENTS.md`;
- `docs/SRS(1).pdf`;
- `docs/Rubric(1).pdf`;
- `docs/approved-design-artifacts/`;
- `docs/prompts/Cafe_Fausse_Prompt_9_DB07_PostgreSQL_Verification_and_Phase_Gate.md`;
- `database/`;
- `backend/`;
- `frontend/`.

DB-01 through DB-06 are approved. DB-05 was explicitly approved by Abdul on 2026-08-19. DB-06 was explicitly approved by Abdul on 2026-08-20.

## Accepted repository-history notes

Treat the following as accepted historical facts, not inconsistencies, warnings, blockers, or reasons to rename or modify files:

1. The approved DB-05 and DB-06 prompt filenames and headers both call themselves “Prompt 8.” Their DB-05/DB-06 increment identifiers, implementations, reports, and approval records distinguish them.
2. The roadmap cites Project Requirements Addendum version 2.2 in two places, while the authoritative addendum header and downstream approved artifacts use 2.2.1. Version 2.2.1 is the regenerated downloadable copy of materially unchanged 2.2 content and is authoritative.
3. DB-05 and DB-06 implementation reports may retain pre-approval wording such as “ready” or “paused at approval checkpoint.” Abdul’s later explicit approvals supersede that historical wording.
4. Prompt filenames in this repository do not contain document-version suffixes. Prompt 9 is correctly named `Cafe_Fausse_Prompt_9_DB07_PostgreSQL_Verification_and_Phase_Gate.md`; do not require `_v1.0` in its filename or an internal Prompt 9 document-version declaration.
5. DB-06's preliminary concurrency evidence used fewer repetitions than DB-07 requires, and its preliminary performance evidence does not yet contain every DB-07 percentile and lock-wait measurement. These are intended DB-07 verification tasks, not prerequisites that must already be complete before DB-07 can begin.

## Verification work

Verify the following without changing the repository or any database:

1. Read `AGENTS.md` and identify every instruction applicable to DB-07.
2. Inspect Git status and report tracked modifications, staged changes, untracked files, branch, and upstream synchronization state.
3. Confirm that these authoritative sources exist:
   - `docs/SRS(1).pdf`;
   - `docs/Rubric(1).pdf`;
   - Project Requirements Addendum version 2.2.1;
   - DB-01 Persistent-Data Requirements Analysis version 1.2.1;
   - DB-02 Conceptual Data Model version 1.2;
   - DB-03 Logical PostgreSQL Schema and Integrity Design version 1.1;
   - DB-04 Reservation Transaction and Concurrency Design version 1.1;
   - approved DB-05 implementation and completion evidence;
   - approved DB-06 implementation and completion evidence;
   - least-to-most implementation roadmap version 1.1.1.
4. Locate Prompt 9 at its exact unversioned path and confirm that it:
   - begins only DB-07;
   - uses `docs/SRS(1).pdf`, `docs/Rubric(1).pdf`, approved artifacts, and `AGENTS.md`;
   - recognizes DB-01 through DB-06 as approved;
   - defines DB-07 as PostgreSQL Hard Gate 1;
   - permits only evidence-driven, forward-only corrections within approved DB-03 and DB-04 decisions;
   - preserves approved migration bytes and order;
   - prohibits Flask, REST, React, and later roadmap work;
   - requires PostgreSQL Contract for Flask v1.0;
   - stops for explicit approval before API-01;
   - does not refer to a nonexistent DB-08 increment.
5. Inspect the DB-05 and DB-06 repository implementation sufficiently to confirm that Prompt 9 has identifiable subjects to verify, including:
   - migration history;
   - PostgreSQL schemas, extensions, and roles;
   - seed, initialization, and reset tooling;
   - the six approved business tables;
   - constraints, indexes, routines, and privileges;
   - provisional availability and authoritative booking operations;
   - exact retry, allocation, and concurrency controls;
   - database unit and behavior tests;
   - multi-session integration tests;
   - performance tooling;
   - implementation documentation and completion evidence.
6. Check for genuinely inconsistent names, paths, versions, approval statements, or references across Prompt 9, `AGENTS.md`, the roadmap, and approved artifacts, excluding the accepted repository-history notes above.
7. Confirm that no repository instruction would cause Prompt 9 to begin Flask, change an approved DB-03/DB-04 decision silently, or edit approved migration history improperly.
8. Identify any missing repository artifact or instruction that would prevent DB-07 from running safely.
9. Identify runtime prerequisites that DB-07 must establish before executing database-changing verification, including:
   - an isolated nonproduction PostgreSQL target;
   - safe connectivity;
   - required role and extension provisioning authority;
   - PostgreSQL executable discovery;
   - required environment variables and reset safety guard.
10. Treat unset database environment variables, an unselected isolated test database, or `psql` being absent from `PATH` as pre-execution setup items rather than repository-readiness blockers when:
    - repository tooling can discover PostgreSQL;
    - Prompt 9 requires safe isolated setup before database mutation; and
    - no evidence indicates that only a production database is available.
11. Treat those runtime items as blockers only if no safe supported way exists to satisfy them before DB-07 execution.
12. Do not run migrations, seed/reset commands, database tests, concurrent tests, performance tests, or any command that can mutate a database. You may identify the commands Prompt 9 should run later.
13. Do not correct any problem during this verification.

## Required report

Return a concise report containing:

- repository and Git-state summary;
- applicable `AGENTS.md` instructions;
- authoritative-source verification;
- approved-artifact and version verification;
- DB-05 implementation evidence found;
- DB-06 implementation evidence found;
- Prompt 9 path and scope verification;
- genuine inconsistencies not covered by the accepted repository-history notes;
- DB-07 runtime setup items;
- missing repository prerequisites;
- blockers;
- nonblocking warnings;
- final result: `READY FOR DB-07`, `READY WITH WARNINGS`, or `NOT READY`.

Use these classifications:

- `READY FOR DB-07`: Prompt 9, approved sources, implementation evidence, and repository instructions are present and internally usable; runtime setup can safely occur when DB-07 begins.
- `READY WITH WARNINGS`: no blocker exists, but one or more nonblocking repository or environment matters should be recorded for DB-07.
- `NOT READY`: a required repository artifact is missing, Prompt 9 is materially inconsistent with approved decisions, approved migration history appears compromised, or no safe supported nonproduction execution path exists.

Do not return `NOT READY` solely because runtime environment variables are currently unset, a nonproduction target has not yet been selected, or PostgreSQL is not on `PATH`, provided those conditions can be safely resolved at the beginning of DB-07.

Do not return `NOT READY` because DB-07 still needs to increase concurrency repetitions, collect complete query plans and timing percentiles, separate lock-wait evidence, evaluate the database performance budget, or correct a proven implementation defect within Prompt 9's approved forward-only policy. Those are purposes of DB-07 itself.

If the result is `READY FOR DB-07` or `READY WITH WARNINGS` with no blocking issue, stop and wait for me to instruct you to execute Prompt 9.

Do not begin DB-07 during this verification.
