# Prompt 18 — API-09 Flask Verification and Hard Gate 2

## Objective

Execute API-09 only: the complete Flask/backend verification gate for Café Fausse.

API-08 is approved, committed, pushed, and frozen.

API-09 introduces **no new business capability**. Its purpose is to verify the completed Flask layer end-to-end against the approved requirements, PostgreSQL contract, REST contract, architecture, and all API-04 through API-08 implementation increments, and to produce the evidence required for **Hard Gate 2** before any React implementation begins.

Do not begin React, frontend, deployment, or later integration work.

---

## Approval state

The following are approved, committed, pushed, and closed:

- DB-01 through DB-07;
- PostgreSQL Hard Gate 1;
- the frozen PostgreSQL Contract for Flask;
- API-01 Backend Operation Inventory;
- API-02 Flask REST Contract;
- API-03 Flask Architecture, Configuration, and Test Strategy;
- API-04 Flask Foundation and PostgreSQL Connectivity;
- API-05 Customer Identity and Newsletter Status Query;
- API-06 Newsletter Preference Mutation;
- API-07 Reservation Context and Availability;
- API-08 Reservation Creation;
- API08-RC-01 and API08-RC-02 reconciliation decisions;
- all previously approved test-harness/repeatability/cleanup behavior.

The repository must begin API-09 from the clean committed API-08-approved checkpoint.

This prompt authorizes **verification, narrowly justified verification-support corrections, and verification documentation only**.

It does not authorize a new user-facing capability.

---

## Authoritative sources and precedence

Use the current committed repository as the authoritative implementation state.

Read and apply, in this order:

1. repository-root `AGENTS.md` and any applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum version 2.2.1;
5. approved DB-01 through DB-07 design, implementation, verification, and Hard Gate 1 evidence;
6. `database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, including the approved API-08 reconciliation;
7. approved API-01 Backend Operation Inventory;
8. approved API-02 Flask REST Contract;
9. approved API-03 Flask Architecture, Configuration, and Test Strategy;
10. approved API-04 through API-08 implementation reports;
11. current backend implementation and tests;
12. `backend/README.md`;
13. `backend/TestInstructions.md`;
14. approved least-to-most implementation roadmap;
15. this Prompt 18.

Use actual repository filenames and recorded approval versions found during Phase 0.

Do not reconstruct or override approved behavior from old chat text.

If an authoritative source conflicts materially with another approved source or the committed implementation, stop and report the contradiction instead of inventing a resolution.

---

## Fixed API-09 boundary

API-09 is a verification/gate increment.

### In scope

- complete Flask/backend requirements audit;
- complete API-02 REST-contract conformance verification;
- complete PostgreSQL integration verification through the approved application-role boundary;
- cross-operation regression testing for OP-01 through OP-07;
- unit, API, PostgreSQL integration, concurrency, retry, rollback, ambiguity, privacy/redaction, resource-cleanup, and performance evidence;
- verification of the SRS form-processing expectation using the approved measurement boundaries;
- repeatability/restartability verification;
- manual backend verification guidance;
- traceability evidence;
- correction of genuine defects found during verification, only when the correction remains fully inside already approved Flask/API behavior;
- narrowly necessary test or verification-harness improvements;
- API-09 implementation/verification report;
- updates to backend documentation when required by verified behavior or test procedure.

### Out of scope

Do not:

- add any new endpoint, request field, response field, public error code, workflow, or business rule;
- add cancellation, reservation modification, waitlist, authentication, administration, payment, messaging, or other unapproved capability;
- change PostgreSQL schema, tables, columns, constraints, indexes, routines, routine signatures, result shapes, roles, grants, allocation rules, locking model, or retry semantics;
- change approved API-01/API-02/API-03 behavior merely to make tests pass;
- change the Project Requirements Addendum;
- begin React/JSX implementation;
- add Node.js/React dependencies;
- begin deployment architecture;
- perform full-stack/browser integration work assigned to later phases.

If a defect requires any prohibited change, stop and report the blocker for approval.

---

## Phase 0 — Mandatory read-only repository verification

Before modifying anything:

1. Read all authoritative sources listed above.
2. Record:
   - current branch;
   - full HEAD commit hash;
   - recent relevant Git history;
   - working-tree status.
3. Confirm:
   - working tree is clean;
   - API-08 approval is recorded;
   - API-08 is committed and pushed;
   - current branch is aligned with the expected project baseline.
4. Inventory the current Flask package, tests, verification runners, README, TestInstructions, implementation reports, and database test infrastructure.
5. Confirm the seven approved operations remain exactly:
   - OP-01 current reservation context;
   - OP-02 daily provisional availability;
   - OP-03 customer newsletter-status query;
   - OP-04 newsletter-preference mutation;
   - OP-05 reservation creation/reconstruction;
   - OP-06 liveness;
   - OP-07 readiness.
6. Confirm no unapproved route or business capability exists.
7. Confirm current API-02 routes/methods/schemas/error inventory from the approved contract.
8. Confirm current PostgreSQL role/routine/read boundary from the frozen database contract.
9. Confirm current test runner ownership/cleanup safeguards.
10. Identify the exact API-09-authorized path set before any change.

If the worktree is unexpectedly dirty, an approval is missing, or the committed API-08 state materially differs from the approved records, stop and report the issue.

---

## Verification requirements

### 1. Complete unit-test verification

Run the complete backend unit suite.

Verify coverage for at least:

- configuration;
- request parsing;
- validation and normalization;
- identity rules;
- email confirmation handling;
- phone normalization/comparison;
- newsletter status;
- newsletter preference semantics;
- reservation context;
- provisional availability;
- reservation creation;
- retry/idempotency;
- certainty/ambiguity handling;
- confirmation reconstruction;
- timezone/DST serialization;
- error translation;
- safe response construction;
- logging/redaction;
- pool/resource lifecycle.

No existing test may be weakened or deleted merely to obtain a pass.

---

### 2. Complete Flask API-contract verification

Verify every approved endpoint against API-02.

Cover:

- exact route;
- exact method;
- exact accepted request location;
- JSON/content-type rules;
- GET body rules;
- query parameter rules;
- unknown field/parameter rejection;
- required/optional/null/omitted semantics;
- field validation;
- exact success schemas;
- exact public error envelope;
- exact HTTP statuses;
- retryable and outcome-unknown flags;
- no-store/cache behavior where specified;
- method-not-allowed behavior;
- malformed JSON;
- unsupported media type;
- safe 500/503 behavior;
- no SQL, role, schema, driver, stack, filesystem, host, credential, or internal-detail leakage.

Where API-02 contains authoritative examples, use them as contract-test inputs rather than inventing divergent examples.

---

### 3. OP-01 — Reservation context

Verify:

- current recurring operating hours come from PostgreSQL;
- current interval, duration, booking window, same-day lead, timezone, capacity, and derived limits are correct;
- SRS/default seed state is correct;
- controlled alternate configurations are reflected without source-code modification;
- no Flask hardcoding becomes business authority;
- malformed/incomplete database foundation fails safely.

---

### 4. OP-02 — Daily provisional availability

Verify:

- all legitimate aligned slots are returned;
- unavailable slots remain represented as required by API-02;
- empty/free, partially occupied, and fully occupied days;
- party-size capacity boundary;
- current interval/duration changes;
- current operating-hours changes;
- same-day lead boundary;
- advance-window boundaries;
- back-to-back reservations;
- partial/full overlapping occupancy;
- DST-relevant dates;
- ordering and duplicate/impossible-result validation;
- no mutation or direct unauthorized reservation/assignment read.

Flask remains authoritative for validating submitted API values, while PostgreSQL remains authoritative for business availability.

---

### 5. OP-03 — Newsletter status

Verify:

- normalized email/customer identity behavior;
- exact existing match;
- new/not-present behavior;
- generic mismatch behavior;
- confirmation email remains transient;
- no persistence side effect;
- no customer enumeration beyond approved contract exposure;
- database/internal identifiers are not exposed;
- resource cleanup on all paths.

---

### 6. OP-04 — Newsletter preference mutation

Verify:

- valid newsletter signup persists;
- newsletter-only customer creation uses the approved Customers source of truth;
- no placeholder identity data;
- exact duplicate signup is idempotent;
- case/whitespace duplicate is idempotent;
- existing reservation customer can subscribe;
- approved unsubscribe/preference behavior remains intact;
- same-state repeats succeed;
- new-unselected behavior follows the approved addendum;
- concurrent creation for one normalized email yields one customer;
- approved mismatch behavior;
- last-committed-write-wins for conflicting valid preference updates;
- timeout/ambiguous mutation retry behavior;
- authoritative committed state is returned;
- transaction rollback leaves no partial state.

---

### 7. OP-05 — Reservation creation

Verify the complete approved API-08 behavior, including:

- strict input validation;
- customer creation/reuse;
- stored identity consistency;
- independent slot validation;
- party-size validation;
- configured duration behavior;
- authoritative availability;
- random eligible table allocation;
- single and combined table assignment behavior;
- no overlapping/shared assignment;
- same-customer overlap prevention;
- exact retry reconstruction;
- fingerprint/retry behavior remains PostgreSQL-owned;
- atomic persistence;
- rollback;
- concurrency;
- known failure vs. outcome-unknown behavior;
- post-commit confirmation reconstruction;
- stored middle initial formatting as `X.`;
- committed start/end instants converted independently using current restaurant IANA timezone;
- API08-RC-01 outcome mapping;
- API08-RC-02 narrowly authorized confirmation read;
- no direct Flask allocation logic.

---

### 8. OP-06 / OP-07 health

Verify:

- liveness performs no database work;
- readiness performs only approved bounded read-only checks;
- readiness does not mutate business state;
- unavailable/misconfigured database produces safe readiness failure;
- no detailed infrastructure leakage;
- startup does not require successful business database access merely to construct the Flask process;
- pool/lifecycle behavior remains bounded and leak-free.

---

## Cross-operation regression requirements

Verify that interactions among operations preserve the approved shared customer source of truth.

At minimum:

1. newsletter-only signup → later reservation enriches/reuses the same normalized customer;
2. reservation-created customer → later newsletter preference update changes only newsletter state;
3. newsletter preference changes never alter or release reservations;
4. reservation exact retry does not replay newsletter mutation;
5. newsletter status query is read-only;
6. reservation failure/rollback does not partially create/update unrelated customer state;
7. dedicated newsletter mutation is transactionally independent from reservation creation;
8. no operation bypasses the approved PostgreSQL role/routine boundary.

---

## Concurrency and integrity verification

Use PostgreSQL 18.3 and the approved application-role boundary.

Verify repeatedly:

- concurrent newsletter-only creates for one normalized email;
- concurrent preference updates;
- concurrent reservations competing for capacity;
- same-customer overlapping reservation attempts;
- multiple requests competing for the same table inventory;
- exact retry under concurrency;
- no duplicate customer;
- no duplicate logical reservation;
- no shared overlapping table assignment;
- no partial reservation/assignment state;
- no lost or inconsistent committed newsletter state beyond the approved last-commit rule.

Do not redesign the approved restaurant-wide locking/allocation strategy because of contention evidence.

---

## Performance verification

API-09 owns the Flask-layer performance gate defined by the approved roadmap and API-03.

Measure representative API behavior using the approved Windows Server / CPython 3.14.x / PostgreSQL 18.3 environment actually present in the repository/test platform.

At minimum measure representative successful:

- newsletter status query;
- newsletter preference mutation;
- reservation context;
- reservation availability;
- reservation creation.

Also measure relevant failure/retry paths when practical.

Document:

- exact environment;
- methodology;
- warm-up;
- sample/iteration counts;
- concurrency/load level;
- p50;
- p95;
- p99 where meaningful;
- operation deadline/timeout interaction;
- database versus Flask contribution where evidence supports separation.

### NFR-02 interpretation

The SRS states that reservation and email-signup form submissions should be processed within two seconds.

Do not silently redefine this as an absolute guarantee.

Use API-09 to provide backend/API evidence and explicitly distinguish:

- ordinary successful behavior;
- approved known database allocation limits;
- contention cases;
- later full-stack/browser/network costs that remain deferred.

If ordinary uncontended newsletter or reservation API behavior materially fails the two-second expectation, investigate and classify the cause.

Do not alter approved correctness/concurrency semantics merely to force a timing pass.

Any material unresolved NFR-02 issue must be recorded for Hard Gate 2 rather than hidden.

---

## Privacy, security, and redaction verification

Audit tests and representative runtime output for:

- raw customer names;
- raw email addresses;
- confirmation email;
- phone values;
- normalized identity values;
- customer IDs;
- reservation fingerprints;
- SQL;
- SQLSTATE where publicly prohibited;
- database role names where prohibited;
- connection strings;
- passwords/secrets;
- filesystem paths;
- stack traces;
- internal exception text.

Verify approved public responses expose only contract-authorized information.

Verify logs retain enough operational utility without leaking prohibited PII/secrets.

---

## Resource lifecycle and failure recovery

Verify:

- every acquired database connection is returned or safely discarded;
- failed connection return/disposal is handled according to the approved certainty/resource model;
- pool shutdown is idempotent;
- repeated app/test cycles do not leak listeners/processes/connections;
- ordinary test failure still triggers cleanup;
- interrupted test runs can be safely recovered using marker ownership;
- malformed/mismatched ownership evidence causes refusal, not deletion;
- environment variables modified by tests are restored exactly;
- disposable PostgreSQL test clusters/databases/directories are removed;
- repository caches/coverage/bytecode/temp artifacts are absent after final cleanup.

---

## TestInstructions.md requirements

Update `backend/TestInstructions.md` for the final Flask/API-09 gate.

It must remain repeatable and restartable for a repo contributor.

Include or verify clear human steps for:

- environment/setup;
- focused tests;
- complete unit tests;
- complete API tests;
- PostgreSQL integration tests;
- concurrency tests;
- performance verification;
- complete API-09 workflow;
- rerun in same session;
- rerun in a new session;
- ordinary-failure recovery;
- interruption recovery;
- cleanup verification.

The final step must remove **all API-09-owned resources** created during testing.

Do not instruct users to delete ambiguous or non-owned resources.

---

## Required API-09 documentation

Create:

`backend/API09_VERIFICATION_REPORT.md`

Update `backend/README.md` and `backend/TestInstructions.md` only as necessary.

The report must contain:

1. baseline commit and approval state;
2. scope and exclusions;
3. environment and exact dependency versions;
4. complete operation/route inventory;
5. unit-test results;
6. Flask API-contract results;
7. PostgreSQL integration results;
8. concurrency/integrity results;
9. rollback/retry/ambiguity results;
10. privacy/redaction results;
11. resource lifecycle/recovery results;
12. performance methodology and results;
13. NFR-02 assessment;
14. SRS traceability;
15. rubric traceability;
16. Project Requirements Addendum traceability;
17. PostgreSQL-contract conformance;
18. API-01/API-02/API-03 conformance;
19. defects found and corrections made;
20. known limitations;
21. unresolved blockers/risks;
22. manual backend demonstration/verification guidance;
23. Hard Gate 2 completion assessment;
24. explicit next-stage boundary.

Do not modify prior approved implementation reports except where an explicit factual correction is necessary and separately reported.

---

## Verification execution gate

After any allowed corrections, perform a complete final pass.

At minimum:

1. parse affected PowerShell scripts and PowerShell blocks in TestInstructions;
2. run Python syntax/compilation checks with generated artifacts confined to owned temporary storage;
3. run configured formatting/lint/type checks, or accurately report if none are configured;
4. run complete unit tests;
5. run complete Flask API tests;
6. run complete PostgreSQL integration tests;
7. run concurrency/integrity tests repeatedly;
8. run focused rollback/retry/ambiguity tests;
9. run privacy/redaction checks;
10. run performance measurements;
11. run the complete API-09 programmer workflow twice consecutively;
12. demonstrate ordinary failure followed by cleanup and successful restart;
13. demonstrate interruption/recovery;
14. demonstrate malformed/mismatched ownership refusal;
15. verify exact environment restoration;
16. verify no owned processes/listeners/resources remain;
17. verify no generated repo artifacts remain;
18. verify no production or production-like environment was modified;
19. run `git diff --check`;
20. verify Git index/history was not modified by testing;
21. verify changed paths remain inside API-09-authorized scope.

Use guarded nonproduction PostgreSQL authorization consistent with the already approved test harness.

Do not weaken ownership or cleanup guards.

---

## Defect handling

If verification finds an implementation defect that can be corrected entirely within already approved API behavior:

1. correct the smallest responsible implementation area;
2. add/strengthen regression tests;
3. rerun focused tests;
4. rerun affected integration tests;
5. rerun the complete final gate;
6. record the defect, cause, correction, and evidence.

Do not ask for approval for an ordinary implementation defect already covered by approved requirements.

Stop and ask for approval if correction would require:

- a new business rule;
- a new API field/route/status/error;
- a changed PostgreSQL contract;
- a schema/routine/role/grant change;
- a changed concurrency/allocation rule;
- a changed approved architecture;
- React/frontend work.

---

## Review artifact

At completion generate:

`CafeFausse_API09_COMPLETE.diff`

for independent ChatGPT review.

The artifact must represent the complete API-09 change set relative to the clean approved API-08 baseline.

Requirements:

- include all API-09 changes;
- exclude unrelated changes;
- do not stage or commit the diff;
- do not modify the real Git index to generate it;
- verify the patch applies cleanly to an export of the API-08 baseline;
- report exact baseline commit;
- report exact path;
- report SHA-256;
- report byte size;
- report changed-path count;
- list every changed path.

The diff artifact itself must not be committed.

---

## Git restrictions

Do not:

- stage;
- commit;
- push;
- reset;
- clean;
- stash;
- rebase;
- merge;
- cherry-pick;
- switch branches;
- create/delete tags;
- open or modify pull requests.

Preserve user changes and repository history.

---

## Completion criteria — Hard Gate 2 readiness

API-09 is ready for explicit approval only if:

- all seven approved operations conform to API-02;
- all required Flask unit/API/PostgreSQL integration tests pass;
- concurrency and data-integrity behavior passes;
- newsletter behavior is fully verified;
- reservation context/availability/creation behavior is fully verified;
- retry, rollback, ambiguity, confirmation, and DST behavior passes;
- privacy/redaction checks pass;
- resource/recovery/cleanup checks pass;
- repeatability is demonstrated;
- backend performance evidence is documented honestly;
- NFR-02 status is explicitly assessed;
- traceability is complete;
- no blocking defect remains;
- no unapproved database, API-contract, architecture, React, deployment, or business-rule change was introduced.

If all criteria pass, state:

> API-09 — Flask Verification and Hard Gate 2 is complete and ready for independent review. Completion does not equal approval. Explicit Hard Gate 2 approval is required before React/JSX implementation begins.

Do **not** declare Hard Gate 2 approved yourself.

---

## Completion response

Lead with the API-09 result.

Report:

- Phase 0 result;
- baseline commit;
- changed paths;
- defects found/corrected;
- complete unit/API/integration/concurrency test counts;
- coverage;
- repeatability results;
- cleanup/recovery results;
- privacy/redaction result;
- performance results and NFR-02 assessment;
- traceability status;
- known limitations;
- unresolved issues;
- review-artifact metadata;
- Git status;
- confirmation that no React, frontend, deployment, or unapproved database/API work began;
- exact Hard Gate 2 checkpoint statement.

Stop there.
