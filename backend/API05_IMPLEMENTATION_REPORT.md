# API-05 implementation report

## Review baseline and approval state

- Phase 0 baseline: `e9a26344eccac769597a9baaa4232f5ddc838074`
- Baseline short subject: `Prompt 14`
- Phase 0 result: `READY - API-05`, followed by a production-ownership pause.
- The user approved the ten-path shared-foundation expansion before any of
  those paths was changed.
- Implementation date: 2026-08-22 (America/Los_Angeles).
- Current checkpoint: API-05 implementation complete and stopped for review.
  No commit, push, amend, rebase, tag, or pull request was performed.

The baseline working tree was clean. Phase 0 confirmed OP-03 can use the
frozen migration-004 `customers` SELECT privilege without a database change.
It also confirmed that route registration and production construction needed
the subsequently approved shared-foundation expansion.

## Authoritative artifacts used

The implementation used root `AGENTS.md`, `docs/SRS(1).pdf`,
`docs/Rubric(1).pdf`, the approved Project Requirements Addendum, the frozen
`database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, the approved API-01 operation
inventory, API-02 REST contract, API-03 Flask architecture/configuration/test
strategy, `backend/API04_IMPLEMENTATION_REPORT.md`, Prompt 14, the current
backend/database test instructions, and the current source, tests, migrations,
privileges, history, and status. Approved design artifacts were read-only.

## Operation and requirement traceability

| Requirement | API-05 implementation and proof |
|---|---|
| Operation | OP-03, exactly `POST /api/v1/newsletter-status-queries`; no alias or automatic OPTIONS route. |
| Input | Exact OP-03 identity fields: required first/last/email/confirmation email and optional middle initial. `phone` is correctly rejected by OP-03, while the approved shared phone normalizer is unit-tested for later identity reuse. |
| Protocol | Common parser enforces JSON media type/UTF-8, nonempty object body, no query, strict JSON, nested/top-level duplicate detection, finite JSON numbers, and the endpoint allowlist. |
| Validation | Names trim/collapse whitespace, preserve spelling, enforce 1-100 Unicode code points and a Unicode letter; middle initial normalizes to one uppercase letter; email implements the approved dot-atom/domain-label profile and lowercase canonical form; confirmation is normalized, compared, and discarded. |
| Matching | Canonical email selects at most one row. First/last names compare case-insensitively. Omitted middle matches stored blank or populated; supplied middle matches stored blank or the same populated value; a differing populated value is a separate middle conflict. |
| Success | Exact `200 {"status":"not_found"}` or `200 {"status":"matched","subscribed":<Boolean>}`. |
| Privacy | Confirmation never enters the typed identity or database layer. SQL projects no ID, email, phone, reservation, or assignment fact. Responses/logs contain no submitted/stored identity, DB row, SQL, SQLSTATE, or correlation ID. |
| Read-only authority | One parameterized `customers` projection in an explicit read-only transaction, bounded by the remaining OP-03 deadline and statement timeout. No production DML exists in API-05. |
| Technical handling | Existing bounded retry machinery is reused. Safe read acquisition/connection and approved transient classes can retry within the overall deadline; timeout/exhaustion becomes the exact known-outcome OP-03 503. Contract shapes remain a generic 500 defect. |
| Regression | Added API-05/API-04 coexistence coverage and ran all preexisting liveness, readiness, common-error, lifecycle, retry, safe-logging, and real PostgreSQL connectivity tests on every complete workflow. |

## Exact public error mapping

| Trigger | HTTP/code | Exact handling |
|---|---|---|
| Malformed, non-UTF-8, duplicate-member, nonfinite, or non-object JSON | `400 invalid_json` | Typed `ProtocolError` is translated by the common handler. |
| Empty body | `400 request_body_required` | Typed `ProtocolError`; no route-owned envelope. |
| Query, unknown field, oversized body, or other forbidden shape | `400 invalid_request` | Typed `InvalidRequest` or common 413 translation. |
| Missing/wrong media type or non-UTF-8 charset | `415 unsupported_media_type` | Typed `ProtocolError`. |
| Field/cross-field rule failure | `422 validation_failed` | Validator returns safe `FieldError` values ordered `first_name`, `middle_initial`, `last_name`, `email`, `confirmation_email`, then rule order. |
| Stored first/last mismatch | `409 customer_identity_conflict` | Typed exhaustive result serialized by the common serializer; stored difference withheld. |
| Supplied/stored populated middle mismatch | `409 middle_initial_conflict` | Typed exhaustive result; stored initial withheld. |
| Read dependency/timeout outcome unavailable | `503 newsletter_status_indeterminate` | Typed service exception translated centrally with safe OP-03 timing/log metadata. |

The route performs parse -> validate -> injected service -> typed serialization.
It does not translate protocol or technical exceptions itself. The common
handlers own exception-to-envelope translation, so no common error policy was
moved into the OP-03 adapter.

## Final production scope audit

Every approved production path was required and changed; there are no
authorized-but-unused production paths. “Shared expansion” means a narrowly
extended API-04 shared-foundation file under the user's supplemental approval.

| Exact path | Action | Ownership | Reason and maximum change used |
|---|---|---|---|
| `backend/src/cafe_fausse/application.py` | modify | shared expansion | Construct only the OP-03 gateway/service with existing pool/retry settings and classify only the approved route as OP-03 for request/retry logs. |
| `backend/src/cafe_fausse/dependencies.py` | modify | shared expansion | Add only the injected `NewsletterStatusOperation` dependency. |
| `backend/src/cafe_fausse/http/blueprint.py` | modify | shared expansion | Register only `POST /api/v1/newsletter-status-queries`. |
| `backend/src/cafe_fausse/http/parsing.py` | modify | shared expansion | Add only common API-02 POST-object protocol parsing required by OP-03. |
| `backend/src/cafe_fausse/http/responses.py` | modify | shared expansion | Add only OP-03/protocol codes, validation fields, and typed projection rendering while preserving health responses. |
| `backend/src/cafe_fausse/http/error_handlers.py` | modify | shared expansion | Translate only typed protocol failures and OP-03 indeterminate reads through the common error boundary. |
| `backend/src/cafe_fausse/services/results.py` | modify | shared expansion | Add only `CustomerIdentity`, exhaustive `NewsletterStatusOutcome`, and invariant-checked `NewsletterStatusResult`. |
| `backend/src/cafe_fausse/db/exceptions.py` | modify | shared expansion | Add only safe read exception classification/timing, including classifying an expired post-acquisition deadline as a non-retryable read unavailability; no mutation certainty behavior. |
| `backend/src/cafe_fausse/validation/__init__.py` | create | shared expansion | Side-effect-free package declaration with only intentional API-05 validation exports. |
| `backend/src/cafe_fausse/serialization/__init__.py` | create | shared expansion | Side-effect-free package declaration with only intentional API-05 serializer exports. |
| `backend/src/cafe_fausse/validation/common.py` | create | API-05 owned | Typed validation result/field errors and deterministic field/rule ordering only. |
| `backend/src/cafe_fausse/validation/identity.py` | create | API-05 owned | Approved identity/email/middle/phone normalization only. |
| `backend/src/cafe_fausse/services/newsletter_status.py` | create | API-05 owned | Read-only OP-03 orchestration over existing retry machinery and typed indeterminate result only. |
| `backend/src/cafe_fausse/db/customer_gateway.py` | create | API-05 owned | One fixed parameterized read-only customer projection, strict shape mapping, timings, and resource release only. |
| `backend/src/cafe_fausse/http/routes/newsletter_status.py` | create | API-05 owned | Thin OP-03 HTTP adapter only. |
| `backend/src/cafe_fausse/serialization/common.py` | create | API-05-owned approved common serializer | Pure typed OP-03 projection into exact API-02 success/conflict responses only. |

No other production file changed. Specifically, API-04 health services,
gateway, pool, retry implementation, logging/redaction implementation,
configuration, package root, and route package initializer did not change.

## Tests and documentation changed

| Path | Purpose |
|---|---|
| `backend/tests/unit/test_validation_identity.py` | Identity, Unicode/name, middle, email, confirmation, phone, ordering, and invariant cases. |
| `backend/tests/unit/test_newsletter_status_service.py` | Every typed result, read retry/deadline behavior, timing accumulation, exhaustion, contract failure, and no mutation/confirmation propagation. |
| `backend/tests/unit/test_customer_gateway.py` | Fixed SQL/projection, parameters, row mapping, optional-middle semantics, release, timing/error translation, post-acquisition deadline exhaustion with zero cursor work, positive bounded timeout, and prohibited access. |
| `backend/tests/api/test_newsletter_status.py` | Exact route/method/wire contract, protocol/validation ordering, conflict/indeterminate/defect mapping, privacy/logging, and API-04 coexistence/lifecycle regression. |
| `backend/tests/integration/test_newsletter_status_postgresql.py` | Real app-role lookup outcomes, normalization, lock failure, zero mutation, collision-resistant absent lookup, preexisting same-email fixture preservation, fixture ownership cleanup, and controlled workflow failure. |
| `backend/tests/api/test_health.py` | Expected route catalogue now includes only the approved OP-03 route; all API-04 health assertions remain intact. |
| `backend/tests/run_api05.ps1` | Marked disposable PostgreSQL 18.3 workflow, task-root-only Python artifacts, environment snapshot/restore, three tiers, coverage, zero-row proof, ordinary/cleanup failure injection, independent finalization, and reliable cleanup. |
| `backend/README.md` | Exact OP-03 usage/results and recommended runner. |
| `backend/TestInstructions.md` | Prerequisites, exact working directory, focused/complete commands, resources, repeat/restart/failure behavior, cleanup and ownership checks. |
| `backend/API05_IMPLEMENTATION_REPORT.md` | This traceability, scope, evidence, and review checkpoint. |

## Test data, side effects, and preservation proof

Production SQL contains only `SET TRANSACTION READ ONLY`, local
`statement_timeout`, and the fixed parameterized customer SELECT. Immediately
after pool acquisition the gateway recomputes the overall deadline. A zero or
sub-millisecond usable budget raises the typed read-unavailability result before
opening a transaction or cursor; a positive budget becomes a bounded integer
statement timeout. Unit tests prove zero cursor/transaction calls, connection
context release, technical-indeterminate classification, and normal execution
with a positive bounded timeout. No independent retry policy was added.

Unit tests also assert absence of write statements, customer IDs, phone,
reservation, and assignment access. PostgreSQL integration tests snapshot all
customer, reservation, and assignment rows before/after each outcome. The
absent-customer test chooses an unused UUID-based address after a read-only
collision check and never prepares its state with `DELETE`. A dedicated
collision case inserts an owned preexisting fixture, proves candidate selection
does not adopt or remove it, and cleans it by its returned `customer_id` plus
email. Test fixture cleanup only deletes rows whose returned identifiers prove
that invocation inserted them.

The disposable database begins and ends with `0|0|0` customer/reservation/
assignment rows. A separately created preexisting sentinel row is preserved
while an API-05-owned failure fixture is removed. The outer runner removes its
database, two generated logins/memberships, marked cluster, server process, and
all task-owned Python artifacts on success, ordinary failure, and controlled
cleanup failure. It never connects to or resets production.

All Python-generated runner resources are confined to the exact marker-owned
`%TEMP%\CafeFausse-api05-tests\artifacts` directory: virtual environment,
pytest cache, coverage data, bytecode cache, and pip cache. Dependencies are
installed directly rather than through an editable project install, so the
runner does not create repository package metadata. It never scans or deletes
repository `.venv`, `.pytest_cache`, `.coverage*`, `__pycache__`, or
`*.egg-info` paths. An existing exact task root is recoverable only when its
marker text matches the expected port/database ownership tuple; an absent,
ambiguous, or mismatched marker causes refusal before deletion.

Finalization independently attempts working-directory recovery,
PostgreSQL/process cleanup, generated-artifact cleanup, cluster-root cleanup,
environment restoration, and postcondition checks. Errors are collected rather
than raised from an early cleanup phase. The original test failure is printed
first; cleanup failures are separate and prominent; any such failure returns
nonzero and suppresses the cleanup-pass marker. Environment restoration checks
all 19 captured variables for exact prior presence/value without printing
values and still runs after an earlier cleanup failure.

## Commands and actual verification results

Primary commands executed from the repository root (or `backend` where shown):

```text
git status --short
git log -5 --oneline
git diff --check
C:\Python314\python.exe -m compileall -q backend\src backend\tests
PowerShell Parser.ParseFile(backend\tests\run_api05.ps1)
PowerShell Parser.ParseInput(each powershell block in backend\TestInstructions.md)
backend\tests\run_api05.ps1
backend\tests\run_api05.ps1 -InjectFailure
backend\tests\run_api05.ps1 -InjectCleanupFailure
```

Actual final-state results:

- Focused post-acquisition/mapping selection: 4 passed (expired acquisition
  budget, positive bounded statement timeout, service indeterminate mapping,
  and exact API `503 newsletter_status_indeterminate` mapping). Its isolated
  temporary environment was removed.
- Complete runner unit/API selection: 202 passed, 22 deselected. This includes
  all preexisting backend unit/API regressions and the deterministic gateway
  cases for an acquisition-consumed deadline and a positive bounded budget.
- PostgreSQL integration: 22 passed, 202 deselected.
- Combined: 224 passed.
- Coverage: 94% on the first final consecutive execution and 95% on the
  second because the background pool branch completed during that run.
  The configured coverage report has no numeric `fail_under`; no threshold was
  lowered or added.
- Consecutive complete executions: pass, pass; each independently rebuilt,
  verified, tested, proved zero rows, stopped PostgreSQL, restored 19 captured
  environment variables, and removed its cluster/generated files.
- Controlled failure: exactly the opted-in
  `test_it_dbapi_op03_controlled_programmer_workflow_failure` failed; 202
  unit/API and the other 21 integration cases passed. The runner returned
  nonzero and its cleanup passed.
- Restart after controlled failure: all 224 passed, zero-row proof passed, and
  cleanup passed.
- Controlled cleanup failure: all 224 tests and zero-row proof passed before
  the generated-artifact cleanup injection; cluster/process cleanup, later
  root cleanup, exact restoration of all 19 environment variables, and final
  absence checks still ran. The runner reported the cleanup error separately,
  omitted `API05 CLEANUP PASS`, returned 1, and left no task root or listener.
- Preexisting-resource sentinels: a repository `backend\.venv`, pytest cache,
  `.coverage`, `.coverage.*`, bytecode cache, and `.egg-info` sentinel were all
  byte-for-byte unchanged by a complete run (six before/after SHA-256 matches).
  The runner's 19-variable caller environment was also restored exactly.
- Preexisting-customer preservation: the PostgreSQL collision test proves an
  existing same-email fixture is neither selected as the absent-test identity,
  deleted, nor adopted; exact whole-table snapshots remain equal.
- Static checks: PowerShell 5.1 parsed the runner and all 27 PowerShell blocks;
  CPython 3.14.6 `compileall` passed; `git diff --check` passed. The project
  config defines no formatter, linter, or type-checker command, so none was
  available to run and no threshold was changed.
- Platform evidence exercised by integration: Windows Server 2025, standard
  GIL-enabled CPython 3.14.6, PostgreSQL 18.3 (`server_version_num=180003`),
  Flask 3.1.3, Psycopg 3.2.13, Psycopg Pool 3.2.8, pytest 9.1.1, pytest-cov
  7.1.0, and active role `cafe_fausse_app`.

The runner uses the exact PostgreSQL 18 `psql.exe` path to avoid the accepted
database script's PowerShell version-discovery ambiguity, and a non-secret
`local-trust-placeholder` is supplied only at the explicit manager-credential
test boundary.

## Final cleanup and exclusions

Final checks found no `%TEMP%\CafeFausse-api05-tests`, API-05-created database,
role, membership, process, listener on port 55445, row, environment change, or
generated repository artifact. A preexisting repository `.venv`, coverage,
pytest cache, bytecode, or package-metadata path is not evidence of leakage and
must remain untouched; sentinel runs proved exact preservation. The runner's
successful, ordinary-failure, and cleanup-failure paths reported the marked
root absent and exact prior environment presence/values restored without
displaying values.

No database file, migration, privilege, frontend/React file, approved design
artifact, API-06-through-API-09 route/result/dependency, or Git history changed.
API-06 and React were not started. There are no unresolved implementation
issues or approved-contract deviations.

## Approval checkpoint

API-05 is implemented, verified, uncommitted, and stopped at the API-05 review
checkpoint. Explicit approval is required before any later increment or commit.
