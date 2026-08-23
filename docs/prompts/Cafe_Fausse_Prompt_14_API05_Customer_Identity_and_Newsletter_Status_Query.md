# Revised Prompt 14 - API-05 Customer Identity and Newsletter-Status Query

Implement API-05 only: the read-only customer-identity and newsletter-status query defined by the approved Flask design.

Do not begin API-06 or any later Flask increment. Do not implement React.

## Approval state

The following work is approved, committed, and closed:

- DB-01 through DB-07;
- the frozen PostgreSQL Contract for Flask;
- API-01 through API-04;
- the post-approval DB-05-through-DB-07 programmer-test-harness hardening.

The working tree is clean at the start of this increment.

This prompt authorizes API-05 only. It does not authorize:

- newsletter preference mutation;
- customer creation or modification;
- reservation-slot discovery;
- reservation creation;
- API-06 through API-09;
- React work;
- database design or implementation changes;
- deployment work.

## Authoritative sources and precedence

Use the repository's current committed artifacts. Do not reconstruct approved behavior from earlier chat messages.

Read and apply, in this order:

1. Root `AGENTS.md` and current project instructions.
2. `SRS.pdf` and `Rubric.pdf` as the fixed authoritative baseline.
3. The approved Project Requirements Addendum.
4. The frozen PostgreSQL Contract for Flask.
5. The approved API-01 backend-operation inventory.
6. The approved API-02 Flask REST contract.
7. The approved API-03 Flask architecture, configuration, ownership, and test strategy.
8. The approved API-04 implementation report and current Flask foundation.
9. Current backend and database setup/testing documentation.

The exact API-02 contract controls API-05's route, method, request fields, response fields, HTTP statuses, public error codes, retry indicators, unknown or indeterminate-state representation, and examples.

Do not invent alternative fields, routes, statuses, or response shapes.

If these sources conflict or an API-05 behavior remains materially unspecified, stop and request approval. Do not silently resolve a new business rule.

## Phase 0 - Mandatory read-only verification

Before modifying anything:

1. Read all authoritative artifacts listed above.
2. Inspect:
   - the complete backend source tree;
   - the complete backend test tree;
   - `backend/README.md`;
   - `backend/TestInstructions.md`;
   - `backend/pyproject.toml`;
   - the database objects and privileges exposed by the frozen PostgreSQL contract;
   - recent Git history and current Git status.
3. Record the full current HEAD commit as the API-05 review baseline.
4. Confirm that the working tree is clean.
5. Identify the exact API-05 operation identifier, route, schema, status codes, and error mappings from the approved API-02 contract.
6. Confirm how the API-04 application factory registers the API-05 route.
7. Confirm the approved API-05 production-file ownership map.
8. Confirm that API-05 can be implemented without changing the database or an approved design artifact.
9. Identify all test-created resources and the existing backend-test cleanup mechanism.
10. Report either:
    - `READY - API-05`, followed by the verified scope and then continue; or
    - `BLOCKED`, followed by the exact conflict or missing approval, and make no changes.

Stop if unrelated changes overlap API-05 files or if route activation requires an unapproved production path.

## API-05 objective

Implement the approved, read-only operation for:

- validating and normalizing customer identity input;
- determining whether the identity represents:
  - a new customer;
  - an exact match for an existing customer; or
  - a generic identity mismatch;
- returning the existing customer's current newsletter status when the approved contract permits it;
- representing database or infrastructure uncertainty exactly as specified by API-02.

This lookup will support the future reservation and newsletter forms. It must have no persistence side effects.

## Approved identity rules

Implement the exact approved identity rules, including:

- normalized email uniquely identifies one customer;
- first and last names are required;
- middle initial is optional;
- phone number is optional;
- optional fields use the omission rules defined by API-02;
- names are trimmed and internal whitespace is collapsed as approved;
- email validation and normalization follow the approved contract;
- phone normalization is transient and digit-only for comparison;
- customer matching uses normalized email and the approved name-comparison rules;
- a conflicting name or other required identity component produces the approved generic mismatch behavior;
- existing customer data is never silently overwritten;
- confirmation-email input is validated as required by the approved contract;
- confirmation email is transient and is never persisted, logged, returned, or passed unnecessarily into the database layer.

Do not strengthen, weaken, or extend these rules based on preference. If a comparison rule is unclear in the approved artifacts, stop for approval.

## Strict request validation

Apply the API-02 contract exactly for:

- JSON content type;
- malformed JSON;
- top-level JSON type;
- required fields;
- optional fields;
- omitted versus null values;
- string types;
- length limits;
- whitespace handling;
- email syntax;
- email-confirmation matching;
- middle-initial validation;
- phone validation;
- unknown fields;
- empty values.

Validation failures must use the approved public error envelope, error codes, field-error structure, and HTTP statuses.

Do not echo sensitive values in error messages.

## Read-only behavior and side-effect prohibition

API-05 must not:

- create a customer;
- update customer identity;
- change newsletter status;
- create a newsletter action;
- create a reservation;
- generate a reservation retry identity;
- acquire or assign tables;
- update timestamps as an incidental lookup effect;
- persist confirmation email;
- persist a normalized transient phone value;
- write test or diagnostic state through a production path.

Prove through automated tests that every API-05 outcome is read-only, including:

- new customer;
- exact existing match;
- identity mismatch;
- invalid request;
- database error;
- indeterminate infrastructure state.

API-06 will own newsletter preference mutation and is not authorized by this prompt.

## PostgreSQL access requirements

PostgreSQL remains authoritative for customer state.

The customer gateway must:

- use only the database objects and privileges allowed by the frozen PostgreSQL contract;
- query the approved customer source only;
- avoid reservation and reservation-assignment reads;
- use parameterized SQL;
- return typed internal results;
- expose no database row, customer identifier, fingerprint, SQL detail, or internal exception to the public API;
- use the API-04 connection, readiness, timeout, retry, exception, logging, and resource-release infrastructure;
- avoid adding an independent retry policy;
- release database resources on every path;
- avoid duplicating PostgreSQL-owned business authority in Flask.

Do not change:

- migrations;
- PostgreSQL functions or procedures;
- views;
- tables;
- indexes;
- roles;
- privileges;
- provisioning;
- reset scripts;
- database test scripts;
- the frozen PostgreSQL contract.

## Privacy and enumeration resistance

Public behavior must not reveal more customer-state information than the approved API-02 contract permits.

In particular:

- use the approved generic mismatch behavior;
- do not reveal which identity component mismatched;
- do not expose whether a particular email exists except through the contract's authorized result;
- do not expose customer IDs;
- do not expose normalized values or fingerprints;
- do not return SQL, driver, pool, platform, or contract details;
- do not log confirmation email, raw identity values, phone numbers, credentials, or database results containing personal data.

Preserve API-04 correlation and safe diagnostic logging behavior.

## Implementation boundaries

The approved API-05 production ownership is limited to:

- `backend/src/cafe_fausse/validation/common.py`
- `backend/src/cafe_fausse/validation/identity.py`
- `backend/src/cafe_fausse/services/newsletter_status.py`
- `backend/src/cafe_fausse/db/customer_gateway.py`
- `backend/src/cafe_fausse/http/routes/newsletter_status.py`
- the approved common serializer location, only if API-02/API-03 assigns it to API-05.

Also authorized:

- corresponding API-05 unit, API, and PostgreSQL integration tests;
- API examples required by the approved design;
- `backend/TestInstructions.md`;
- `backend/README.md`, only where needed for accurate API-05 usage or test guidance;
- `backend/API05_IMPLEMENTATION_REPORT.md`.

Do not expand production ownership. If an additional production file is technically required, stop before editing and identify:

- the exact file;
- why it is required;
- why the approved architecture did not already provide the extension point;
- the smallest proposed change.

Do not add a runtime dependency or lower an existing test, coverage, lint, or type-checking threshold.

## Required automated tests

Add focused, deterministic tests at the approved layers.

### Validation and normalization tests

Cover at least:

- valid required identity;
- first-name and last-name trimming;
- internal name-whitespace collapsing;
- approved name-case behavior;
- valid and invalid middle initials;
- omitted optional middle initial;
- omitted optional phone;
- phone digit normalization for comparison;
- invalid phone values;
- valid and invalid email syntax;
- approved email normalization;
- matching and nonmatching confirmation email;
- confirmation email remaining transient;
- missing fields;
- null fields;
- non-string fields;
- empty or whitespace-only values;
- overlength values;
- unknown fields;
- malformed JSON;
- non-object JSON;
- wrong or missing JSON content type.

### Service tests

Cover at least:

- new customer;
- exact existing-customer match;
- existing customer without a phone number;
- lookup with an omitted optional phone;
- every approved identity-mismatch category;
- the same generic public mismatch result regardless of which identity component differs;
- current subscribed state;
- current unsubscribed state;
- indeterminate database result;
- retryable infrastructure failure;
- nonretryable platform or contract failure;
- no preference mutation;
- no customer creation or update;
- no confirmation-email propagation to persistence.

### Gateway tests

Cover at least:

- correct authorized query;
- parameterized inputs;
- absent customer;
- one exact matching customer;
- mismatch inputs;
- nullable optional values;
- correct result mapping;
- connection and cursor release;
- timeout and exception translation through the API-04 infrastructure;
- no write statement;
- no reservation or assignment-table access;
- no customer ID leakage above the internal boundary.

### API tests

Cover at least:

- exact method and route;
- exact success responses from API-02;
- exact new-customer behavior;
- exact existing-match behavior;
- exact generic mismatch behavior;
- strict validation failures;
- unsupported method behavior;
- wrong media type;
- malformed request;
- retryable and nonretryable infrastructure mappings;
- unknown or indeterminate state;
- correlation behavior;
- no internal-detail leakage;
- no customer-ID exposure;
- no side effects.

### PostgreSQL-backed integration tests

Use PostgreSQL 18.3 and cover at least:

- new customer lookup;
- exact existing match;
- subscribed and unsubscribed status;
- no-phone identity;
- each meaningful mismatch class;
- normalized-input behavior;
- no confirmation-email persistence;
- zero database mutation for every lookup result;
- preservation of preexisting records;
- cleanup after success;
- cleanup after an injected test failure;
- immediate repeat execution.

Use the approved database contract and test infrastructure. Do not weaken or bypass production privileges to make an integration test pass.

## Regression requirements

Run all preexisting backend tests, including API-04 foundation tests.

Verify that API-05 does not change:

- application startup;
- health or readiness behavior;
- common response envelopes;
- correlation identifiers;
- database failure classification;
- retry deadlines;
- connection cleanup;
- existing public behavior.

Do not modify an existing test merely to accommodate an unintended behavior change.

## `backend/TestInstructions.md`

Update `backend/TestInstructions.md` at this increment.

It must remain user-requested programmer-convenience documentation rather than an SRS, rubric, or design authority.

Document:

- prerequisites;
- PostgreSQL 18.3 requirement;
- exact working directory;
- environment setup without exposing credentials;
- the single recommended complete-test command;
- focused API-05 unit, API, and PostgreSQL integration commands;
- resources created during testing;
- resources preserved;
- ordinary-failure behavior;
- how to restart after interruption;
- how to repeat testing in the same PowerShell session;
- how to repeat testing in a new PowerShell session;
- expected success indicators;
- expected cleanup indicators;
- how to verify that no test-created resource remains;
- when ambiguous ownership requires stopping instead of deleting anything.

The tests and instructions must be repeatable and restartable.

The final test step must clean up all test-created resources, as applicable, including:

- test customers and newsletter-state fixtures;
- test databases or schemas;
- temporary PostgreSQL roles or memberships;
- temporary files and directories;
- passfiles or temporary credential material;
- changed process environment variables;
- generated result artifacts not intended for source control;
- child processes.

Cleanup must:

- run through a reliable `finally`-style path after success and ordinary failure;
- remove only resources whose test ownership is proven;
- preserve preexisting databases, roles, records, files, processes, and environment values;
- restore changed environment variables to their exact prior value or prior absence without displaying them;
- report cleanup failures prominently;
- return a nonzero status if tests or cleanup fail;
- support safe recovery on the next invocation after an interruption;
- never claim cleanup succeeded while a test-owned resource remains.

Prefer the existing accepted backend/database test-harness mechanisms. Extend them minimally for API-05. Do not redesign the accepted database harness or modify `database/TestInstructions.md`.

## Documentation and examples

Update API examples only from the exact API-02 contract.

Examples must include, where the approved contract defines them:

- new-customer lookup;
- exact existing match;
- generic mismatch;
- validation failure;
- indeterminate or retryable failure.

Examples must not contain real credentials or personal data and must not expose customer IDs or internal database details.

## Verification gate

After implementation:

1. Run Windows PowerShell 5.1 parsing for affected PowerShell scripts and every PowerShell block in `backend/TestInstructions.md`.
2. Run Python syntax or compilation checks.
3. Run configured formatting, linting, and type checks.
4. Run API-05 unit tests.
5. Run API-05 API tests.
6. Run API-05 PostgreSQL integration tests against PostgreSQL 18.3.
7. Run the complete existing backend suite.
8. Run the existing coverage command and enforce its existing threshold.
9. Perform two consecutive complete executions using the documented programmer workflow.
10. Demonstrate restart after one controlled API-05 test failure.
11. Verify exact cleanup after success and injected failure.
12. Verify preservation of preexisting database resources and environment state.
13. Verify that no test-created database row, database, schema, role, membership, file, directory, passfile, process, environment change, or generated artifact remains.
14. Confirm final Git status contains no generated test artifacts.
15. Run `git diff --check`.
16. Confirm that no database, frontend, approved-design, API-01-through-API-04, or API-06-plus artifact changed.
17. Confirm that only authorized API-05 paths changed.

If a required tool is unavailable, report the exact limitation. Do not claim a check passed unless it ran successfully.

## Implementation report

Create:

- `backend/API05_IMPLEMENTATION_REPORT.md`

Include:

- starting baseline commit;
- authoritative artifacts used;
- exact API-05 operation and requirement traceability;
- scope and exclusions;
- production files changed;
- test and documentation files changed;
- validation and normalization behavior;
- identity-match behavior;
- privacy and enumeration protections;
- PostgreSQL interaction;
- proof of no persistence side effects;
- error mapping;
- test commands;
- unit, API, integration, and combined test counts;
- coverage result;
- two-run repeatability results;
- restart and failure-cleanup results;
- final cleanup evidence;
- static-verification results;
- PostgreSQL version evidence;
- warnings, deviations, or unresolved issues;
- confirmation that API-06 and React were not started;
- the API-05 approval checkpoint.

Report actual results only. Counts and changed-path lists must match the final repository state.

## Review diff

Generate a complete task-only diff from the recorded Phase 0 baseline through the final uncommitted API-05 state.

Name it:

- `CafeFausse_API05_COMPLETE.diff`

The diff must:

- be generated from the exact full baseline commit;
- include committed-baseline-to-current uncommitted API-05 changes;
- contain only authorized API-05 source, tests, documentation, and report paths;
- be byte-preserving Git unified-diff output;
- be valid UTF-8 and not UTF-16;
- exclude generated test artifacts;
- exclude database and frontend paths;
- include no credentials or secrets.

Report:

- diff path;
- byte size;
- encoding;
- included paths;
- SHA-256.

Do not add the diff to Git.

## Completion response

At completion, report:

- Phase 0 findings;
- exact changed paths;
- implementation summary;
- contract and requirement traceability;
- every command run;
- all test counts and results;
- coverage;
- PostgreSQL version;
- consecutive-run results;
- restart and injected-failure results;
- final cleanup evidence;
- preservation evidence;
- diff metadata;
- Git status;
- unresolved issues or deviations;
- confirmation that API-06 and React were not started;
- the API-05 approval checkpoint.

Do not commit, push, amend, rebase, tag, or create a pull request.

Stop at the API-05 review checkpoint and wait for explicit approval.
