# API-07 Implementation Report — Reservation Context and Availability

## Status and scope

API-07 implements only OP-01 current reservation context and OP-02 daily
provisional availability. It completed independent review and is approved and
frozen at Git checkpoint `2d45fc4` (`API-07 approved`). API-08, API-09,
reservation creation, React, integration, deployment, and PostgreSQL changes
were not started.

Baseline HEAD is `ddf800a1e7539d35d0168fa7820cedfdaa30f91a`. The approved
API-01 v1.0.2 and API-03 v1.0.3 reconciliation is present. Initial real-index
SHA-256 was
`0adfac19fa960b284d0983e068f94bd308bda015e8ab451ce9f260a441c2d7d4`.

## Approval checkpoint

- **API-07 approval status:** Approved.
- **Git checkpoint:** `2d45fc4` — `API-07 approved`.
- **Scope approved:** reservation context retrieval; provisional availability
  discovery; and the associated validation, services, gateways, serialization,
  error handling, and tests.
- **Verification summary:** focused API-07 tests passed; the complete backend
  suite passed; PostgreSQL integration and concurrency verification passed;
  and repeatable, restartable, ownership-validated cleanup verification passed.
- **Boundary confirmation:** API-08 has not started; React work has not started;
  no schema, migration, role, grant, or deployment changes were introduced;
  and there are no deviations from the approved API-07 contract.

## Corrected implementation boundary

- `GET /api/v1/reservation-context` accepts no query or body and returns the
  exact API-02 context schema.
- OP-01 uses one fresh `REPEATABLE READ READ ONLY` transaction per attempt.
  Its PostgreSQL access is limited to fixed projections from
  `cafe_fausse.reservation_configuration`,
  `cafe_fausse.restaurant_operating_hours`, and
  `cafe_fausse.restaurant_tables`, plus the approved database-clock
  expression using the configured timezone. It does not read
  `pg_catalog.pg_timezone_names` or any customer, reservation, or assignment
  relation.
- OP-01 validates the configured IANA timezone with Python `ZoneInfo`. It
  validates one permitted configuration, seven ordered weekday rows, exactly
  30 tables, zero nonpositive capacities, positive aggregate capacity, and
  coherent database-derived local date bounds without adding a relation.
- `GET /api/v1/reservation-availability` accepts exactly one `local_date` and
  one strict base-10 `party_size` query parameter and no body.
- OP-02 uses one fresh `REPEATABLE READ READ ONLY` transaction per attempt. It
  reads only the configured timezone and invokes the unchanged bound
  `cafe_fausse.provisional_availability(date, integer)` routine.
- OP-02 validates complete result shape, outcomes/details, ordering,
  uniqueness, timezone/local-time agreement, second precision, Boolean state,
  and an elapsed duration of exactly 60, 90, or 120 minutes. The duration
  check adds no foundation read. Unavailable rows and legitimate empty arrays
  are preserved.
- Shared reads retain maximum three attempts, a fresh lease/transaction per
  attempt, remaining-deadline guards, and the approved retry SQLSTATEs
  `55P03`, `40P01`, and `40001`. Mutation behavior was not changed.
- Public API-02 response envelopes, no-store headers, logging allowlists, and
  PII/internal-detail protections remain unchanged.

## Functional and PostgreSQL evidence

The corrected focused API-07 unit/gateway/service/API selection collected and
passed 75 tests in 0.32 seconds. It explicitly covers:

- OP-01 default and alternate hours/configuration/capacity snapshots;
- missing configuration, missing/duplicate weekday, invalid schedule,
  invalid timezone, wrong table count, nonpositive capacity, malformed
  projection, incoherent dates, read failure, exact transaction isolation,
  approved relation boundary, and no DML;
- OP-02 valid/missing/duplicate/unknown query shapes, calendar and party-size
  validation, weekday/Sunday/DST rows, unavailable and empty results, all
  three permitted durations, a rejected 75-minute result, duplicate/reversed
  results, safe retry ceilings, nonretryable failures, exact API envelopes,
  no-store behavior, and safe logs.

The PostgreSQL 18.3 suite contains 9 API-07 discovery tests and the complete
integration selection passed 53 tests. Real database evidence includes:

- default context and application-role read-only behavior;
- alternate recurring schedule, permitted scalar configuration, changed
  positive capacity and derived maximum party size, observed OP-01/OP-02
  effects, and exact restoration;
- incomplete foundation mapping to the generic service failure for both
  operations and exact restoration;
- free, partial, full, and back-to-back occupancy;
- 15-minute interval and 120-minute duration effects;
- same-day lead boundary and inclusive advance-window boundaries;
- application-role execution of the frozen routine;
- application-role denial of direct reservation and assignment reads;
- before/after customer/reservation/assignment counts proving no mutation;
- ordered complete schedules, all-unavailable schedules, controlled range
  mapping, repeated coherent reads, and concurrency.

The final two consecutive corrected-runner executions produced:

| Selection | First execution | Second execution |
|---|---:|---:|
| focused API-06 gateway/service/error/logging regression | 84 passed in 0.40 s | 84 passed in 0.36 s |
| unit/API | 376 passed in 1.27 s | 376 passed in 1.08 s |
| PostgreSQL integration/concurrency | 53 passed in 23.73 s | 53 passed in 21.69 s |
| complete coverage run | 429 passed in 22.38 s | 429 passed in 22.13 s |
| overall branch-aware coverage | 93% | 93% |
| complete runner wall time | 75.266 s | 69.882 s |

Both executions passed the configured coverage gate, independently removed
both owned sibling roots, left port 55446 with zero listeners, and restored
the prior presence and values of all 24 runner-managed process environment
variables before the next execution.

The controlled ordinary failure reached the PostgreSQL selection, produced
the one expected injected failure after 52 passing PostgreSQL tests, stopped
PostgreSQL, restored the environment, and removed both owned roots. Its fresh
immediate restart then passed 376 unit/API tests in 1.36 seconds, 53
PostgreSQL tests in 26.79 seconds, and all 429 tests in 24.21 seconds at 94%
coverage, with normal cleanup.

API-04 through API-06 unit, API, PostgreSQL, concurrency, retry/deadline,
logging/redaction, transaction certainty, and cleanup/disposal regressions are
included in every complete 429-test run.

## Runner-resource architecture correction and recovery evidence

- API-07 and its contained API-06 run now use independent shallow sibling
  roots: `CafeFausse-api07-tests` and
  `CafeFausse-api07-contained-api06-tests`. API-07 does not redirect inherited
  `TEMP/TMP` into its root and passes the sibling path explicitly.
- The contained runner records repository, task, phase, purpose, owner ID,
  canonical root, port, and database. PostgreSQL data, venv, pip cache,
  coverage, and process-temp resources are shallow siblings with ownership
  records written before resource creation.
- Routine pytest uses `PYTHONDONTWRITEBYTECODE=1`, removes inherited
  `PYTHONPYCACHEPREFIX`, disables pytest caching, and installs with pip
  `--no-compile`. Explicit compilation uses its own independent marker-owned
  sibling root.
- The operator removed the earlier ambiguous temporary tree. That manual action
  is not treated as ownership evidence and no historical marker was recreated.
  Clean preflight then proved both redesigned roots absent, no prior runner
  process, and zero port-55446 listeners.
- Focused live architecture validation observed the real pytest process and
  proved independent sibling roots, valid main and per-resource markers,
  shallow/non-nested venv and cache paths, no relevant reparse points, zero
  routine bytecode/pytest-cache artifacts, no pathological absolute-path
  mirroring, normal exit 0, independent root removal, and zero residual
  listeners.
- The actual API-07 to contained API-06 interruption test used the real runners.
  After both root markers, PostgreSQL 18.3 identity, and the sole port-55446
  listener were established, write-through evidence recorded held contained
  runner PID 15220 and postmaster PID 10484. Preparation returned the expected
  exit 86. Recovery reread and validated every marker, process relationship,
  executable, postmaster, and listener; it returned 0, terminated the held
  process, stopped PostgreSQL, removed both roots independently, and left zero
  port-55446 listeners.
- The controlled cleanup-failure run passed its 376 unit/API, 53 PostgreSQL,
  and 429 complete tests, stopped PostgreSQL, restored all 24 environment
  variables, then returned the expected nonzero result while preserving the
  valid outer marker. Read-only validation proved the contained root absent and
  port 55446 clear. Guarded `-CleanupOwnedRoot` recovery returned 0 and removed
  the exact outer root.
- A same-invocation marker-mismatch test created valid ownership evidence,
  changed only the owner ID, and proved cleanup refusal with exit 1. It restored
  the original marker byte-for-byte, revalidated it, and guarded cleanup then
  returned 0. No preexisting resource was adopted.

## Final static, cleanup, and repository verification

- Windows PowerShell 5.1 parsing passes for corrected `run_api06.ps1`,
  `run_api07.ps1`, and all 39 PowerShell blocks in `TestInstructions.md`.
- Python compilation produced 127 `.pyc` files exclusively beneath a separate
  sibling `%TEMP%\CafeFausse-api07-compilation` root whose marker was durably
  written and reread before compilation. Cleanup revalidated the marker,
  containment, and absence of reparse points, restored both changed Python
  environment variables, removed the exact root, and verified absence.
- Static relation checks confirmed OP-01 references exactly the three approved
  Cafe Fausse foundation relations and no `pg_timezone_names`, customer,
  reservation, assignment, or DML path.
- The OP-02 gateway still has one exact bound routine call and no added
  foundation read.
- Final task-resource inspection found both runner roots and the compilation
  root absent, no API-06/API-07 runner process, and zero listeners on port
  55446. `git diff --check` passes, staged paths are zero, and the real Git
  index SHA-256 remains
  `0adfac19fa960b284d0983e068f94bd308bda015e8ab451ce9f260a441c2d7d4`.

## Exact changed paths

The complete API-07 working state contains these 27 paths relative to baseline
HEAD:

1. `backend/API07_IMPLEMENTATION_REPORT.md`
2. `backend/README.md`
3. `backend/TestInstructions.md`
4. `backend/src/cafe_fausse/application.py`
5. `backend/src/cafe_fausse/db/availability_gateway.py`
6. `backend/src/cafe_fausse/db/context_gateway.py`
7. `backend/src/cafe_fausse/dependencies.py`
8. `backend/src/cafe_fausse/http/blueprint.py`
9. `backend/src/cafe_fausse/http/error_handlers.py`
10. `backend/src/cafe_fausse/http/responses.py`
11. `backend/src/cafe_fausse/http/routes/reservation_availability.py`
12. `backend/src/cafe_fausse/http/routes/reservation_context.py`
13. `backend/src/cafe_fausse/serialization/__init__.py`
14. `backend/src/cafe_fausse/serialization/reservation.py`
15. `backend/src/cafe_fausse/services/reservation_availability.py`
16. `backend/src/cafe_fausse/services/reservation_context.py`
17. `backend/src/cafe_fausse/services/results.py`
18. `backend/src/cafe_fausse/validation/__init__.py`
19. `backend/src/cafe_fausse/validation/reservation.py`
20. `backend/tests/api/test_health.py`
21. `backend/tests/api/test_reservation_discovery.py`
22. `backend/tests/integration/test_reservation_discovery_postgresql.py`
23. `backend/tests/run_api06.ps1`
24. `backend/tests/run_api07.ps1`
25. `backend/tests/unit/test_reservation_gateways.py`
26. `backend/tests/unit/test_reservation_services.py`
27. `backend/tests/unit/test_validation_reservation.py`

## Unresolved provenance and cleanup limitations

The exact ignored path `backend/src/cafe_fausse_backend.egg-info` is present.
The initial Phase 0 audit did not record this ignored path, so durable evidence
does not establish whether it predated API-07 or was first created by an early
editable-install attempt in this cycle. It is preserved as ambiguously owned;
this report does not claim complete repository-artifact cleanup. No correction
command used an editable install. Independent review must treat this provenance
limitation explicitly rather than infer ownership from the directory name,
contents, timestamps, or location.

All resources durably proven to have been created by the corrected API-07
verification were removed. The complete-review diff's size, SHA-256, path
enumeration, temporary-index apply verification, and byte-identical
regeneration are reported alongside the generated artifact; embedding the
artifact's digest in its own included report would be self-referential.

API-07 is approved and frozen at commit `2d45fc4`. Work remains stopped at the
API-07 approval checkpoint; API-08 has not started.
