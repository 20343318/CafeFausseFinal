# Cafe Fausse API-06 implementation report

## Baseline, authority, and Phase 0 readiness

- Starting full baseline commit: `c7945c45a230b5cf23ae16cba1c491a52bd9fbfe`.
- Approved API-05 parent: `a5b86e22518b64eec4970806c220daa804739bc6`.
- At Phase 0, `main`, `origin/main`, and `origin/HEAD` resolved to the full
  baseline, the worktree and real index were clean, and the only baseline
  difference from the approved API-05 parent was the API-06 implementation
  prompt.
- The mandatory Phase 0 status `READY - API-06` was issued before any edit.
- No superseding contract, incompatible parent, or unauthorized prerequisite
  was found during the original Phase 0. A later blocker-correction review
  identified `backend\.api06-correction-compile`; Codex subsequently confirmed
  that it created this directory during API-06 compilation, establishing its
  provenance for the exact cleanup documented below.

The authoritative material read before implementation was:

- `docs/SRS(1).pdf` and `docs/Rubric(1).pdf`;
- `docs/approved-design-artifacts/Cafe_Fausse_Project_Requirements_Addendum.md`;
- the approved API-01 operation inventory, API-02 Flask REST contract, and
  API-03 architecture/configuration/test strategy;
- `database/POSTGRESQL_CONTRACT_FOR_FLASK.md`, the routine migration and
  privilege migration, the database runbook, and DB-06/DB-07 reports;
- the approved API-04 and API-05 implementation reports;
- the current backend source, tests, metadata, README, and test runbook; and
- `docs/prompts/Cafe_Fausse_Prompt_15_API06_Independent_Newsletter_Preference_Management.md`.

The production-path audit found that OP-04 required one new route, validator,
service, gateway, and their common typed-result/dependency/serialization/error
extensions. The accepted retry service already expressed the approved
certainty-aware retry protocol, so `services/retry.py` remained unchanged.
The shared parser, configuration, pool, timing, logging/redaction, health,
OP-03 route/service/gateway, database artifacts, frontend, and approved design
artifacts required no change.

## Requirement and contract traceability

API-01 OP-04 maps to exactly `POST /api/v1/newsletter-preferences`. The body
allowlist is `first_name`, optional `middle_initial`, `last_name`, `email`,
`confirmation_email`, and strict JSON Boolean `subscribed`. It accepts no
phone, customer ID, reservation field, query parameter, or unknown member.
Parsing remains in the accepted shared parser. Identity validation and
normalization compose the accepted OP-03 rules; the immutable mutation command
contains normalized identity plus the requested Boolean and deliberately
contains neither confirmation email nor phone.

The gateway calls only this fixed parameterized projection:

```text
SELECT outcome, newsletter_subscribed
FROM cafe_fausse.set_newsletter_preference(%s, %s, %s, %s, %s)
```

It runs through `cafe_fausse_app`, performs no direct DML, and decodes exactly
one two-column row. Every routine outcome and result/state invariant is
allowlisted. The accepted routine remains the sole business and concurrency
authority.

### Exact public mapping

| Routine or technical outcome | HTTP | Exact public body semantics |
|---|---:|---|
| `subscribed` | 200 | `{"result":"set","subscribed":true}` |
| `unsubscribed` | 200 | `{"result":"set","subscribed":false}` |
| `no_customer_no_change` | 200 | `{"result":"no_customer_no_change","subscribed":false}` |
| `customer_identity_mismatch` | 409 | `customer_identity_conflict`, generic identity message, `retryable:false`, `outcome_unknown:false` |
| `middle_initial_conflict` | 409 | `middle_initial_conflict`, generic conflict message, `retryable:false`, `outcome_unknown:false` |
| `invalid_request` | 422 | `validation_failed` with deterministic ordered allowlisted fields and no submitted/stored values |
| conclusively known non-commit after permitted retry is unavailable/exhausted | 503 | `temporary_failure`, `retryable:true`, `outcome_unknown:false` |
| commit status cannot be established | 503 | `newsletter_preference_outcome_unknown`, `retryable:true`, `outcome_unknown:true`, and the exact identical-resubmission instruction |

HTTP validation errors retain the API-02 exact envelope and ordered field
entries. Success and conflict responses disclose no customer existence beyond
the approved outcome, and no response exposes stored identity, phone,
reservation data, customer ID, SQL, SQLSTATE, retry count, or internal detail.

## Transaction, deadline, retry, and certainty behavior

- Each attempt obtains and later returns a bounded pool lease, enters the real
  Psycopg connection context, starts an explicit READ COMMITTED transaction,
  installs a remaining-budget statement timeout, dispatches the controlled
  routine once, and validates its row. Normal connection-context exit commits;
  exceptional exit rolls back automatically. A retry therefore receives a
  fresh lease and transaction rather than reusing failed transactional state.
- Deadline checks occur before lease acquisition, after acquisition, before
  routine dispatch, after decoding, and before commit. An exhausted or
  sub-millisecond budget is not rounded up and does not dispatch the routine.
- The approved 15-second mutation correctness deadline and existing maximum
  three attempts are unchanged. Pool wait, database time, retry delay, and
  attempt count are accumulated through the accepted retry engine.
- Only `55P03`, `40P01`, and `40001` are mutation-retry SQLSTATEs, and only
  when non-commit/rollback is conclusive. Pre-dispatch dependency failures are
  known not to have mutated. A nonretryable confirmed rollback maps to the
  known temporary path without an unsafe retry.
- Receive, commit, or commit-status failure after dispatch is outcome unknown
  unless non-commit is proven. Outcome-unknown failures are never retried.
- An uncertain connection is closed and returned to the pool only for discard
  when that close succeeds. If close/disposal itself fails, the still-open
  unsafe lease is withheld from `putconn()` rather than entering the normal
  reusable return path. A failed rollback is always recorded as cleanup
  failure even when the later close succeeds. Rollback and close failure is
  recorded by the same safe Boolean. The original operation error remains the
  primary cause, cleanup text is discarded, retry is forbidden when rollback
  cannot be established, and certainty is classified conservatively.
- A normal reusable connection is returned with `putconn()`. If pool return
  fails, the gateway attempts direct close/disposal and retains a non-public
  cleanup Boolean even when COMMIT was already positively confirmed. That
  post-commit cleanup failure neither changes known-committed certainty nor
  permits a retry or replay. A pending mutation or contract failure remains
  primary, with its original certainty and retry classification unchanged.
- Programming/protocol/result-shape defects are typed contract failures rather
  than business outcomes. Expected business outcomes remain typed values.

## Data behavior and concurrency

Real PostgreSQL tests proved that a new `true` request creates exactly one
customer, a new `false` request creates none, and existing matched identities
transition in either direction. Repeating either state is idempotent. Existing
identity, phone, reservations, and table assignments remain unchanged.
Identity and middle-initial conflicts do not mutate. Concurrent identical
new-customer requests converge on one customer. Coordinated opposing writes
produce the last committed state. A concurrent identity conflict remains a
conflict without overwriting identity. A simulated lost response after a real
commit returns the outcome-unknown envelope, and resubmitting the identical
request converges safely.

The app login successfully invoked the controlled routine and direct customer
DML was denied. Lock-timeout, known no-dispatch, confirmed rollback,
rollback-uncertain, commit-uncertain, retry, invariant, and original-error
preservation paths were exercised without a production failure switch or
privilege relaxation.

### Certainty-evidence classification

- **Unit/test-double evidence:** connection-context doubles automatically
  commit on success and roll back on exception. They prove rollback-fails /
  close-succeeds, rollback-and-close-both-fail, original-cause preservation,
  pool-return failure after confirmed commit, fallback-close success and
  failure, withholding an unsafe still-open lease after rollback or commit
  uncertainty, pending mutation/contract-error preservation, cleanup-Boolean
  propagation through the service, no retry after uncertainty or post-commit
  cleanup failure, unchanged public envelopes, and
  PII/SQL/driver/connection/cleanup-text exclusion from logs.
- **Organic PostgreSQL evidence:** the disposable PostgreSQL 18.3 cluster
  executes the real controlled routine, real role boundary, idempotency and
  concurrency tests. Holding an ACCESS EXCLUSIVE table lock organically
  produces `55P03` through the production gateway. It maps to known temporary
  failure and leaves no mutation.
- **Controlled test-only adapter evidence:** the frozen single-key READ
  COMMITTED routine cannot organically generate deterministic `40P01` or
  `40001`. A cursor adapter therefore injects those SQLSTATEs, plus a
  deterministic `55P03`, exactly at the routine-dispatch boundary. The tests
  still use the production service/gateway, real pool leases, real BEGIN and
  statement-timeout work, and real Psycopg automatic rollback. Each failed
  lease is IDLE before return; the next attempt obtains a new lease/context.
  These tests prove all three classifications, rollback-before-retry,
  three-attempt maximum, and remaining-deadline guard without claiming the
  injected states are organic PostgreSQL failures.
- **Controlled real-resource uncertainty adapters:** one adapter raises after
  the real routine/result but permits real automatic rollback (known
  non-commit); one closes the real connection before rollback can be confirmed
  (outcome unknown); and one raises only after real context commit (lost commit
  acknowledgement, outcome unknown). Unknown cases make one attempt only.
  Identical later submission converges whether the first transaction actually
  rolled back or committed.

## Privacy and observability

OP-04 logs only the existing safe request metadata, operation name, status,
timings, correlation ID, and bounded retry metadata. Commands mark identity
and requested state as non-repr. Logs and public responses contain no names,
emails, confirmation values, phone, IDs, credentials, SQL text, or SQLSTATE.
Cache-prevention and content-policy headers remain uniform. Conflict and
failure bodies are generic and preserve the approved enumeration boundary.
The gateway and service retain `cleanup_failed` through both successful-result
and technical-error boundaries. Confirmed-success cleanup failure is reported
by the production service observer, while terminal technical errors retain the
existing handler reporting. Both use only the constant allowlisted
`retry_class=mutation_cleanup_failure`. No cleanup status or detail is added
to the public response. `observability/redaction.py` remained unchanged.

## Changed files

Production (14):

- `backend/src/cafe_fausse/application.py`
- `backend/src/cafe_fausse/db/exceptions.py`
- `backend/src/cafe_fausse/db/newsletter_gateway.py`
- `backend/src/cafe_fausse/dependencies.py`
- `backend/src/cafe_fausse/http/blueprint.py`
- `backend/src/cafe_fausse/http/error_handlers.py`
- `backend/src/cafe_fausse/http/responses.py`
- `backend/src/cafe_fausse/http/routes/newsletter_preferences.py`
- `backend/src/cafe_fausse/serialization/__init__.py`
- `backend/src/cafe_fausse/serialization/common.py`
- `backend/src/cafe_fausse/services/newsletter_preferences.py`
- `backend/src/cafe_fausse/services/results.py`
- `backend/src/cafe_fausse/validation/__init__.py`
- `backend/src/cafe_fausse/validation/newsletter.py`

Tests and runner (7):

- `backend/tests/api/test_health.py`
- `backend/tests/api/test_newsletter_preferences.py`
- `backend/tests/integration/test_newsletter_preferences_postgresql.py`
- `backend/tests/run_api06.ps1`
- `backend/tests/unit/test_newsletter_gateway.py`
- `backend/tests/unit/test_newsletter_preference_service.py`
- `backend/tests/unit/test_validation_newsletter.py`

Documentation and report (3):

- `backend/README.md`
- `backend/TestInstructions.md`
- `backend/API06_IMPLEMENTATION_REPORT.md`

No database, frontend, approved-design, API-07-plus, dependency metadata, or
unrelated path changed. The approved API-05 report was not modified.

## Verification results

Formal platform evidence was PostgreSQL 18.3 and standard GIL-enabled 64-bit
CPython 3.14.6 on the approved Windows Server environment.

Focused test results:

- validation: 20 passed;
- gateway, service, error-handler, and safe-logging runner tier: 84 passed;
- newsletter-preference service: 19 passed;
- gateway/connection-context certainty adapter: 30 passed;
- Flask OP-04 API: 30 passed;
- focused API-04/API-05 non-PostgreSQL regressions: 196 passed.

Every complete runner execution independently ran:

```powershell
& .\backend\tests\run_api06.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
```

- unit/API tier: 301 passed, 44 deselected;
- PostgreSQL integration tier: 44 passed, 301 deselected;
- combined current backend suite: 345 passed;
- final combined branch coverage: 93-94% (`1395` statements, `398` branches);
- other clean runs reported 93-94% due timing-dependent pool lifecycle branch
  execution;
- `pyproject.toml` configures branch coverage and has no numeric `fail_under`,
  so no numeric threshold existed to lower or bypass.

The PostgreSQL tier included all API-04 and API-05 real-database regressions
and the complete OP-04 integration/concurrency file. The complete suite
included all current unit, API, and PostgreSQL tests. The runner's final query
proved `0|0|0` customers/reservations/assignments before destroying the owned
database, roles, memberships, sessions, and cluster.

Two consecutive corrected-state complete executions passed all 345 tests;
their final combined pytest phases took 15.09 and 14.74 seconds and each ended
in `API06 CLEANUP PASS`. The immediate restart after controlled failure also
passed all 345 tests; its final combined pytest phase took 14.84 seconds.

### Workflow safety evidence

- Controlled ordinary failure: the 84 focused and 301 unit/API tests passed;
  the explicit test-only integration injection produced 1 expected failure
  after 43 other
  integration tests passed, returned nonzero, retained that test failure as
  primary, restored all 19 environment variables, stopped PostgreSQL, removed
  the root/artifacts, and left no listener. An immediate complete restart then
  passed all 345 tests.
- Controlled cleanup failure: all 345 tests and 93% coverage passed; generated
  artifact cleanup was explicitly failed, returned nonzero, and later cluster
  removal, environment restoration, and postcondition checks still ran. The
  exact owned root was absent afterward.
- Interrupted recovery: an interrupted execution temporarily retained its
  exact valid-marker root. Immediate recovery attempts refused a locked owned
  extension instead of forcing deletion; delayed original cleanup removed the
  root, after which a complete 345-test run passed and cleaned normally.
- Ownership refusal: the same root with a mismatched marker returned nonzero;
  its sentinel file retained the same SHA-256 and bytes and the root was not
  deleted.
- Collision preservation: an independently marked PostgreSQL 18.3 cluster on
  port 55447 held preexisting database
  `cafe_fausse_test_api06_lookalike` and a sentinel row. Both survived a
  same-session recovery run and an immediate new-PowerShell-session run, then
  the independently owned collision cluster was removed by its own exact
  marker cleanup.
- Repository preservation: preexisting `.venv`, cache, `.coverage`,
  `__pycache__`, `.egg-info`, ordinary file, and directory sentinels (seven
  files across five directories) retained their exact lengths and SHA-256
  hashes across those runs. The demonstrator removed only the sentinels it had
  created after re-verification.
- Same-email collision: integration tests snapshotted an existing customer and
  related phone/reservation/assignment data, performed OP-04, and proved all
  non-newsletter data unchanged before exact restoration.
- Environment/process cleanup: every completed or controlled-failure runner
  path restored the prior presence and
  value of all 19 touched process variables without printing values. Final
  checks found neither marker-owned runner temp root, owned child
  process/listener on 55446 or 55447, passfile, virtual environment, cache,
  coverage file, bytecode, nor runner-generated repository artifact.

### Timing evidence

Eight sequential successful OP-04 requests were measured against the live
disposable PostgreSQL 18.3 cluster over loopback. They covered create, update,
and repeated same-state operations. End-to-end Flask test-client measurements
were minimum 3.881 ms, median 5.039 ms, and maximum/p95 231.859 ms; the first
request included pool warm-up. Safe application logs independently reported
request elapsed values from 3.286 to 228.904 ms, pool wait from 0.783 to 8.376
ms, and database time from 2.165 to 219.905 ms. All were under the SRS
two-second measurement target. This is uncontended local evidence, not a
guarantee for contended requests. The frozen 15-second correctness deadline
and contention behavior were not changed or hidden.

### Static and scope verification

- Windows PowerShell 5.1 parsing passed for `run_api06.ps1` and all 34
  PowerShell blocks in `backend/TestInstructions.md`.
- CPython 3.14.6 compilation passed for all backend production and test
  modules with bytecode confined to and removed from an exact task cache.
- No formatter, linter, or type checker is configured in `pyproject.toml` or
  repository automation; this was reported rather than inventing a command.
- A temporary Git index containing the exact complete 24-path API-06 state
  passed `git diff --cached --check`. Cached-apply verification reproduced the
  identical tree, and the generated preflight diff was strict UTF-8 without a
  BOM.
- The real index remained unchanged from Phase 0 with no staged paths. The
  review diff is untracked.
- Direct final checks found no runner-owned PostgreSQL resource, listener,
  process, temporary root, repository cache, bytecode, venv, or metadata.
- Codex explicitly established that it generated
  `backend\.api06-correction-compile` during API-06 compilation. After exact
  canonical-path and root/descendant reparse-point checks, only that directory
  was removed and its absence was verified. The real Git index retained its
  correction-cycle SHA-256 throughout the cleanup.

## Warnings, deviations, and approval checkpoint

The connection-disposal implementation blockers are corrected without an
approved-contract deviation. A still-open unsafe lease is not returned to the
pool when uncertainty disposal fails. Codex's explicit ownership statement
resolved the `backend\.api06-correction-compile` provenance blocker, and the
exact Codex-generated directory has been safely removed. No retroactive marker
or name/timestamp inference was used.

The timing figures are intentionally limited to the required uncontended
local evidence and do not redefine the approved deadline.

API-06 remains the current unapproved review increment pending independent
acceptance. API-07, React, and end-to-end integration were not started.
