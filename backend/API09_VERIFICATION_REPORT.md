# API-09 Flask Verification and Hard Gate 2 Report

Date: 2026-08-24

Status: independently reviewed, approved, and frozen. Hard Gate 2 is approved.

## 1. Baseline commit and approval state

Phase 0 began on branch `main` at
`b2b66bd8608839661795106746106608b772046d`. The worktree and real Git index
were clean, `HEAD` and `origin/main` were identical, and their ahead/behind
counts were `0/0`. The immediately preceding approved API-08 checkpoint is
recorded at `acfeefd`; the baseline commit adds only Prompt 18 above that
approved checkpoint.

The recorded approvals cover DB-01 through DB-07, PostgreSQL Hard Gate 1, the
PostgreSQL Contract for Flask, API-01 through API-08, and the API-08 contract
reconciliations. No material contradiction was found among the authoritative
sources, approval records, or committed implementation.

The API-09-authorized path set was declared before editing: API-09 tests and
runner, this report, `backend/README.md`, `backend/TestInstructions.md`, and the
required root review diff. Production Flask source and database artifacts were
excluded unless verification exposed a genuine already-approved-behavior
defect. None was found.

## 2. Scope and exclusions

This increment audited and exercised the completed Flask layer: all seven
operations, API-02 request/response behavior, the frozen application-role
database boundary, cross-operation customer-state behavior, concurrency,
rollback, retry, ambiguity, privacy, resource recovery, repeatability, and
performance. It added verification coverage and contributor instructions only.

It added no route, field, status, public error, workflow, dependency, business
rule, database object, privilege, allocation rule, or production behavior. It
did not begin React/JSX, frontend, browser/full-stack integration, deployment,
or any later roadmap increment.

## 3. Environment and exact dependency versions

Verification used Windows Server 2025 build 26100.33158, CPython 3.14.6 with
the GIL enabled, and a runner-owned PostgreSQL 18.3 disposable cluster.

Installed Python packages were: cafe-fausse-backend 0.1.0, Flask 3.1.3,
Werkzeug 3.1.8, Jinja2 3.1.6, MarkupSafe 3.0.3, itsdangerous 2.2.0, click
8.4.2, blinker 1.9.0, psycopg 3.2.13, psycopg-binary 3.2.13, psycopg-pool
3.2.8, pytest 9.1.1, pytest-cov 7.1.0, coverage 7.15.4, pluggy 1.6.0,
iniconfig 2.3.0, packaging 26.3, Pygments 2.21.0, typing_extensions 4.16.0,
tzdata 2026.3, pip 26.1.2, colorama 0.4.6, and setuptools 80.10.2.

The project has no configured formatter, linter, or static type checker, so no
such command was invented. PowerShell parsing, Python compilation, pytest,
branch coverage, database verification, and `git diff --check` are the
configured/appropriate static and execution checks.

## 4. Complete operation and route inventory

The blueprint exposes exactly the seven approved operations and no additional
business route:

| Operation | Method and route | Purpose |
| --- | --- | --- |
| OP-01 | `GET /api/v1/reservation-context` | current reservation context |
| OP-02 | `GET /api/v1/reservation-availability` | daily provisional availability |
| OP-03 | `POST /api/v1/newsletter-status-queries` | customer newsletter-status query |
| OP-04 | `POST /api/v1/newsletter-preferences` | newsletter-preference mutation |
| OP-05 | `POST /api/v1/reservations` | reservation creation/reconstruction |
| OP-06 | `GET /api/v1/health/liveness` | process liveness |
| OP-07 | `GET /api/v1/health/readiness` | bounded database readiness |

## 5. Unit-test results

The final collection contains 312 unit tests. All passed. Coverage includes
configuration, parsing, validation/normalization, identity/email/phone rules,
newsletter behavior, reservation discovery and creation, retry/certainty,
confirmation/DST serialization, error mapping, safe output, logging/redaction,
and pool lifecycle. No existing test was removed or weakened.

## 6. Flask API-contract results

The final collection contains 146 Flask API tests. All passed. API-09 extracts
and explicitly classifies all 36 API-02 JSON examples: 3 request examples, 17
success-response examples, and 16 error-response examples. Each example has
executable Flask evidence. The three request bodies are submitted verbatim to
their contract-defined routes and their normalized service calls and defined
results are checked. Response/error examples are produced through actual routes
with deterministic service/database/health/failure seams and compared with the
contract example. All three request bodies are submitted verbatim and 31 of 33
response bodies compare exactly. The two illustrative validation examples
exercise the route and compare the normative envelope,
code, flags, field, and field-code semantics because API-02 expressly labels
the examples non-executable and its normative field catalogue owns the exact
caller-guidance text.

The test independently parses the complete Section 10 public error catalogue
and proves its 19 codes, HTTP statuses, retryable flags, and outcome-unknown
flags exactly equal the production `ERRORS` registry, with neither omissions
nor additions. It does not rely on a second hard-coded allowed-code set.

Existing API tests passed for route/method, query versus JSON location,
content type, GET bodies, unknown fields/parameters, null/omitted semantics,
validation ordering, success bodies, errors and statuses, retryable and
outcome-unknown flags, cache controls, malformed JSON, unsupported media type,
405 responses, and safe 500/503 handling. Representative leakage sentinels
for SQL, drivers, roles, hosts, paths, credentials, stack text, and private
exception detail remained absent from public responses.

## 7. PostgreSQL integration results

The final guarded integration selection contains 62 PostgreSQL tests. All
passed against PostgreSQL 18.3 through the application role. They cover current
and alternate reservation configuration, operating hours, availability state,
same-day/advance-window boundaries, capacity, overlap/back-to-back behavior,
DST dates, newsletter identity and persistence semantics, reservation
allocation/persistence/reconstruction, health checks, and zero-row cleanup.

Five new cross-operation cases prove: newsletter signup is enriched/reused by
a later reservation; a reservation-created customer can change newsletter
state without changing its reservation; an exact reservation retry does not
replay newsletter mutation; status queries are read-only; a capacity failure
rolls back linked customer/newsletter work; and concurrent shared-customer
flows converge without duplicates.

## 8. Concurrency and integrity results

Seven tests are explicitly marked PostgreSQL concurrency tests, with additional
concurrency assertions in existing integration coverage. Repeated complete
gates passed concurrent same-email newsletter creation, conflicting preference
updates, capacity/table competition, same-customer overlap, and exact
reservation retry. The database retained one normalized customer, no duplicate
logical reservation, no shared overlapping table assignment, no partial
assignment state, and only the approved last-committed newsletter result.

The approved restaurant-wide locking/allocation strategy was observed, not
redesigned.

## 9. Rollback, retry, and ambiguity results

Unit, API, and PostgreSQL tests passed for `55P03`, `40P01`, and `40001`
technical retry, attempt/deadline guards, fresh transaction/lease behavior,
excluded timeout classes, conclusive rollback, uncertain commit/cleanup,
`outcome_unknown`, and exact OP-05 reconstruction. The cross-operation
full-capacity test proves failed reservation work leaves the existing customer
preference and blocking reservation unchanged. Exact retry returns the current
committed newsletter state without replaying a reservation-side preference.

## 10. Privacy and redaction results

Safe-logging and API error tests passed with sentinel names, email addresses,
confirmation email, phone, password, host, connection, SQL, and internal
exception text. Static review confirmed production logging uses an allowlisted
safe event layer, suppresses psycopg-pool propagation, excludes raw request
values and identifiers, and limits SQLSTATE logging to approved retry classes.
Public responses expose only API-02-authorized confirmation and error fields;
customer IDs, fingerprints, database roles, connection details, filesystem
paths, tracebacks, and secrets are not exposed.

## 11. Resource lifecycle and recovery results

Normal and failed paths returned or discarded leases as required; pool close is
idempotent; every guarded run stopped its child server, restored the prior
presence/value of 24 process environment variables without displaying values,
and removed owned clusters, roles, rows, caches, coverage, bytecode, and temp
artifacts.

The complete workflow passed twice consecutively. A controlled test failure
returned nonzero, cleaned resources, and was followed immediately by the
successful two-pass workflow. A controlled generated-artifact cleanup failure
returned nonzero only after the then-current complete suite passed, preserved its marker-owned
root, and the explicit recovery command removed that exact root. An actual
held runner/PostgreSQL interruption state exited with code 86; guarded recovery
stopped the recorded server and removed the owned root. A second interrupted
state with an intentionally mismatched owner ID was refused without deletion;
after byte-for-byte marker restoration, guarded cleanup succeeded.

No API-09/API-07 owned root, contained API-06 root, PostgreSQL listener, child
runner, generated repository cache, or changed process environment remained.
No production or production-like database was contacted or modified.

## 12. Performance methodology and results

The test uses the real Flask test client, real application dependency graph,
application role, and disposable local PostgreSQL 18.3 database. Each case has
5 excluded warm-up requests followed by 30 sequential measured requests at
load/concurrency level 1. `perf_counter_ns` measures whole in-process Flask
request latency. Percentiles use nearest rank. Each sample resets only the
business data needed for deterministic independence, and setup/cleanup is not
timed.

The final successful runner's two recorded samples were:

| Request | p50 ms | p95 ms | p99/max ms |
| --- | ---: | ---: | ---: |
| OP-03 newsletter status | 2.095 / 2.768 | 3.752 / 4.111 | 3.933 / 4.303 |
| OP-04 newsletter preference | 2.513 / 3.299 | 4.893 / 6.380 | 6.158 / 6.589 |
| OP-01 reservation context | 2.224 / 2.816 | 4.415 / 4.142 | 4.691 / 4.416 |
| OP-02 reservation availability | 289.615 / 313.636 | 316.111 / 355.644 | 317.910 / 356.082 |
| OP-05 reservation creation | 315.173 / 350.715 | 352.891 / 493.340 | 366.749 / 498.588 |
| OP-05 exact retry | 305.429 / 371.688 | 336.773 / 472.128 | 347.235 / 473.295 |
| OP-05 validation failure | 0.400 / 0.443 | 0.523 / 0.745 | 0.535 / 1.089 |

The `/` separates the integration-selection and branch-coverage execution of
the same timing test. Each number is therefore independently backed by 30
measured requests. OP-01/02/03 use the approved 2,000 ms read deadline;
OP-04/05 retain the approved 15,000 ms mutation deadline, 500 ms pool-acquire
bound, PostgreSQL 3 s lock timeout, and bounded retry rules. Timings are
end-to-end within Flask and PostgreSQL but exclude HTTP/network/browser costs;
the test cannot rigorously isolate database time from Flask time. The sub-2 ms
validation-failure samples demonstrate the non-database path is small but are
not used as a formal component decomposition.

## 13. NFR-02 assessment

Ordinary uncontended newsletter and reservation form API behavior met the SRS
two-second processing expectation with large margin in every measured sample;
the largest listed ordinary p99/max was 498.588 ms. This is backend/API
evidence, not an absolute service-level guarantee. Frozen allocation locking,
bounded retries, and contention can approach their approved longer database
limits. Browser rendering, external network latency, production load, and
full-stack form timing remain deferred to the later React/integration phase.
No unresolved material API-layer NFR-02 issue was observed.

## 14. SRS traceability

- Reservation form processing: OP-01/02/05 verify PostgreSQL-backed context,
  validity/availability, random eligible allocation among the 30-table seed,
  and exact success/error output.
- Newsletter processing: OP-03/04 verify email/identity validation and durable
  customer newsletter state.
- NFR-02: Section 13 records measured backend submission timing and its boundary.
- NFR-05: constraints, atomic routines, rollback, retry, and concurrency tests
  preserve data integrity.
- NFR-06: API-02 validation envelopes provide safe, actionable public errors.
- Maintainability/modularity: routes, services, gateways, validation,
  serialization, observability, and configuration remain separated.

## 15. Rubric traceability

The backend evidence supports the rubric's complete reservation/newsletter
requirements, correct Flask/PostgreSQL integration, durable database effects,
and sophisticated availability/allocation/concurrency logic. The React form
presentation and full end-to-end browser behavior are intentionally not claimed
at this gate and remain future roadmap work.

## 16. Project Requirements Addendum traceability

Approved Addendum v2.2.1 requirements PRA-006 through PRA-029 are exercised by
the API/API-PostgreSQL suites: independent newsletter mutation, generic status
matching, shared normalized customer identity, transient confirmation email,
strict validation, current database configuration, provisional availability,
authoritative atomic booking, random eligible allocation, same-customer and
table overlap prevention, exact retry/reconstruction, uncertainty mapping,
independent IANA-timezone instant conversion, privacy, and health behavior.
No addendum decision was altered.

## 17. PostgreSQL-contract conformance

The application role remains limited to `SELECT` on the four foundation tables
(`customers`, `reservation_configuration`, `restaurant_operating_hours`, and
`restaurant_tables`) and `EXECUTE` on exactly the three production routines
`provisional_availability`, `set_newsletter_preference`, and
`book_reservation`. It has no reservation/assignment-table read, direct DML,
sequence, helper, test-routine, DDL, or role-management privilege. The booking
mutation transaction contains only the `book_reservation(...)` call. After that
transaction commits, OP-05 may perform the separately authorized read-only
confirmation reconstruction. That read may retrieve only the stored
`first_name`, `middle_initial`, and `last_name` components plus the current
`reservation_configuration.restaurant_timezone`; the timezone is used solely
for API-02-compliant local serialization. Flask performs no
reservation/assignment or allocation query.

## 18. API-01, API-02, and API-03 conformance

API-01's seven-operation inventory is unchanged and complete. API-02 v1.0.2's
routes, methods, request locations, schemas, error inventory, cache behavior,
and examples passed. API-03 v1.0.4's package boundaries, configuration,
application/pool lifecycle, deadline/retry policy, transaction ownership,
health behavior, safe logging, deterministic seams, and marker-owned test
strategy remain intact. No production architectural dependency was added.

## 19. Defects found and corrections made

No production implementation defect was found, so no production Flask or
database file was changed. Verification-support gaps were closed by adding
executable evidence for every API-02 example and exact contract-to-production
error-inventory closure, five cross-operation PostgreSQL tests,
repeatable timing evidence, terminal timing summaries, the API-09 orchestration
runner, and final contributor instructions.

## 20. Known limitations

- Performance evidence is local, sequential, in-process Flask test-client data;
  it excludes browser, HTTP server, network, TLS, proxy, and production-load
  effects.
- The suite validates approved contention behavior but does not establish a
  production throughput or tail-latency service-level objective.
- Database and Flask contributions are not separately instrumented by the
  performance test.
- Coverage is branch-aware and measured at 90%; the project defines no enforced
  numeric coverage threshold.
- No formatter, linter, or type-checker configuration exists.
- React forms and full-stack/browser verification remain intentionally deferred.

## 21. Unresolved blockers and risks

No blocking API-09 defect, contradiction, privacy issue, cleanup leak, or
material ordinary-path NFR-02 issue remains. Residual performance and browser
risks are the explicitly deferred limitations above. API-09 and Hard Gate 2
passed independent final review and received explicit approval.

## 22. Manual backend demonstration and verification guidance

From the repository root, create the backend virtual environment and install
`backend[test]` as documented in `backend/README.md`. Run focused unit/API
selections from `backend`, then invoke the guarded workflow:

```powershell
& '.\backend\tests\run_api09.ps1' `
  -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
```

The workflow parses PowerShell, compiles Python into owned temporary storage,
runs two complete guarded PostgreSQL gates, checks the diff, verifies unchanged
HEAD/index, and removes owned resources. `backend/TestInstructions.md` contains
the exact same/new-session, controlled-failure, cleanup-failure, interruption,
ownership-refusal, recovery, and final absence checks. Never point the runner at
a production or production-like database, and never manually delete an
ambiguous root.

## 23. Hard Gate 2 completion assessment

All seven operations conform; 312 unit, 146 API, and 62 PostgreSQL integration
tests pass; seven explicitly marked concurrency tests pass; the complete 520-test
branch-coverage run reports 90%; two consecutive complete workflows pass;
controlled failure, cleanup failure, interruption, ownership refusal, and exact
recovery pass; privacy, contract, role-boundary, cleanup, performance, and
traceability evidence is complete. API-09 passed independent final review;
Hard Gate 2 is explicitly approved and frozen.

## 24. Explicit next-stage boundary

API-09 — Flask Verification and Hard Gate 2 passed independent final review
and is approved and frozen. This approval authorizes the next React/JSX
increment according to the approved roadmap. This documentation-only closeout
does not itself begin React/frontend implementation.
