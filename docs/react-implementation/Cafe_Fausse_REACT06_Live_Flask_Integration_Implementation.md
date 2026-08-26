# Cafe Fausse REACT-06 Live Flask Integration Implementation

**Status:** APPROVED AND FROZEN

**Increment:** REACT-06 / Prompt 24 - Live React-to-Flask Integration

**Date:** 2026-08-25

## 1. Baseline and approval state

Phase 0 began on `main` at full HEAD `1ac926a32892b213c04e9ea1821b8d06236acb06`. `HEAD`, `origin/main`, and `origin/HEAD` were aligned (`0/0`); the worktree and real Git index were clean; the index tree equalled HEAD tree `743c0702fc92a6beefc68f6da4785ae0373bf91f`; and approved REACT-05 commit `92e76910249eda01af51341d0c5bd449cc42b54e` was an ancestor. The baseline contained only the committed Prompt-24 input above that checkpoint. The REACT-05 report said `APPROVED AND FROZEN`, Prompt 24 was next, and no Prompt 25 work existed.

The approved/frozen scope includes SRS/rubric, PRA v2.2.1, roadmap v1.1.1, DB-01 through DB-07/Hard Gate 1, PostgreSQL Contract for Flask v1.1, API-01 through API-09/Hard Gate 2 and reconciliations, and REACT-01 through REACT-05. The prior user approval record was: `INT-01 integration strategy approved.` Independent final review now explicitly approves and freezes REACT-06 / Prompt 24 without authorizing Prompt 25.

Phase-0 verification passed all 141 frozen frontend tests. The approved API-09 workflow passed two complete cycles before editing; each cycle passed 458 unit/API tests, 62 PostgreSQL tests, the combined 520-test branch-aware coverage run, PostgreSQL 18.3 setup/verification, zero-row proof, repeatability, and guarded cleanup. The live route inventory remained exactly OP-01 through OP-07 and API-02 v1.0.2 remained exact.

## 2. Scope, exclusions, and changed paths

Implemented only Prompt 24: native-fetch OP-01 through OP-05, default live injection, environment-driven Vite `/api` proxy, Home server-authoritative current hours, focused adapter/configuration tests, disposable full-stack lifecycle, live API/database verification, Chrome/Edge CDP verification, instructions, and this report.

Created:

- `frontend/src/api/liveOperations.js` - production native-fetch adapter and safe public/protocol errors.
- `frontend/src/features/hours/CurrentHours.jsx` - live OP-01 Home hours with load/failure/retry and no fallback authority.
- `frontend/src/test/LiveOperations.test.js` - exact method/path/query/body, success, error, malformed-response, and transport tests.
- `frontend/src/test/CurrentHours.test.jsx` - server schedule authority and no-fallback retry tests.
- `frontend/src/test/LiveAppIntegration.test.jsx` - live App default and explicit injection tests.
- `frontend/src/test/ViteProxy.test.js` - proxy origin/configuration tests.
- `frontend/scripts/owned-live-integration.ps1` - marker-owned PostgreSQL/Flask/Vite lifecycle and guarded cleanup.
- `frontend/scripts/verify-live-integration.ps1` - OP-01 through OP-05, database-effect, error, capacity, exact-retry, privilege, and timing verifier.
- `frontend/scripts/verify-live-lifecycle-guards.ps1` - deterministic caller-environment, partial-start ownership, readiness rejection, refusal, and recovery verifier.
- `frontend/scripts/verify-live-browser.mjs` - dependency-free Chrome/Edge CDP live UI verifier.
- this report.

Changed:

- `frontend/src/App.jsx`, `frontend/src/api/operations.js` - production defaults now use live operations while injection remains.
- `frontend/vite.config.js` - environment-only Flask proxy target and task-owned optional Vite cache.
- `frontend/src/pages/HomePage.jsx` - uses `CurrentHours`.
- `frontend/src/layout/SiteFooter.jsx`, `frontend/src/pages/ReservationsPage.jsx` - remove static schedule claims and direct users to live hours/context.
- `frontend/src/test/msw/operationClient.js` - full-route MSW tests inject the production adapter.
- `frontend/src/test/AppRoutes.test.jsx` - awaits server-authoritative Home hours.
- `frontend/package.json` - adds only the `test:integration` script; no dependency/version change.
- `frontend/TestInstructions.md` - preserves REACT-04/05 material and adds bounded live startup, verification, failure/recovery, repeatability, and cleanup.

No backend source, database source, migration, schema, routine, role/grant definition, API contract/design, SRS, rubric, PRA, React design, frozen implementation report, package lock, or Gallery asset was changed. Prompt 25 and INT-06 through INT-09 remain excluded. No CORS, Axios, state/form/validation/browser-automation dependency, browser persistence, reset endpoint, authentication, admin UI, reservation lookup, cancellation, modification, table choice, delivery, or client idempotency key was added.

### 2.1 Independent-review correction pass

The complete REACT-06 review found four remaining defects. First, lifecycle actions changed managed process environment variables in the caller and did not restore their original presence/value. The cause was action-local mutation without a complete entry snapshot and outer `finally`; the helper now snapshots all twelve managed names, clears them before child configuration, and restores exact presence/value for every action outcome without serializing prior values. Second, Flask and full-environment startup could exhaust a readiness loop after observing a listener and still report success. The cause was that listener discovery and readiness were not independent required states; direct and proxied loops now require an explicit OP-07 `status:"ready"` Boolean before their success messages.

Third, Flask ownership was not durable until listener association completed, leaving a partial-start gap. The cause was writing Flask evidence only after listener discovery. The helper now writes `launcher_recorded` immediately after `Start-Process`, extends it to `listener_recorded` only after exact ancestry proof, and advances to `ready` only after direct OP-07 proof. Guarded cleanup validates exact PID/start/executable/command and listener ancestry, handles live or already-exited partial/complete records, refuses ambiguity, and does not delete the root until the exact chain is stopped or absent. Fourth, the live verifier lacked OP-04 identity-conflict mutations, OP-05 middle-initial conflict, and a distinguishing proof that exact OP-05 retry does not replay its newsletter mutation. Those cases now assert the frozen public envelope and direct PostgreSQL no-effect/current-state evidence through the approved test role.

A subsequent lifecycle review found that `Stop-ProvenProcess` discarded its already-proven process object, reacquired by PID, and killed the reacquired object. That created a PID-reuse race despite the earlier complete ownership proof. `Get-ProvenProcess` now retains the exact process object's safe handle with its in-memory proof, and `Stop-ProvenProcess` verifies the same PID/start/executable/handle identity and calls `Kill()` only on that same object. It never performs `Get-Process` reacquisition. An already-exited proven object is accepted without termination; unavailable or changed handle/identity fails safely and preserves ownership evidence.

## 3. Same-origin native-fetch design and exact mapping

`liveOperationClient` uses native `fetch`, relative same-origin paths, `cache:"no-store"`, JSON parsing, and exact API-02 bodies. The production bundle no longer imports `contractFixtures.js`; those fixtures remain test authority only. Components still consume operation methods rather than fetch.

| Operation | Browser mapping |
| --- | --- |
| OP-01 | `GET /api/v1/reservation-context` |
| OP-02 | `GET /api/v1/reservation-availability?local_date=<encoded>&party_size=<encoded>` with exactly those two values |
| OP-03 | `POST /api/v1/newsletter-status-queries`, exact identity JSON |
| OP-04 | `POST /api/v1/newsletter-preferences`, exact identity plus final Boolean |
| OP-05 | `POST /api/v1/reservations`, exact identity/contact, selected server start/offset, party size, and newsletter action |

Successful object JSON is returned unchanged. Contract errors become `PublicApiError` with the original HTTP status and complete `error.code`, message, `retryable`, `outcome_unknown`, and optional fields. Non-JSON/malformed/nonobject success or malformed error envelopes become client-local `ProtocolResponseError`; raw bodies, URLs, PII, stack traces, and transport detail are not logged or shown. Native read rejection remains a safe explicit read failure. Native OP-04/05 rejection or protocol loss remains conservatively outcome unknown because browser dispatch/commit cannot be proven. An actual valid Flask error envelope always controls retry/unknown behavior.

## 4. Vite proxy and no-CORS decision

Vite reads `CAFE_FAUSSE_FLASK_PROXY_TARGET` only in `vite.config.js`. The live workflow supplies `http://127.0.0.1:55004`; production browser code sees only `/api/...`. Invalid protocol/path/query/fragment targets fail configuration. `CAFE_FAUSSE_VITE_CACHE_DIR` places live-test cache under the disposable owned root. Neither variable uses the `VITE_` browser-exposure prefix.

No Flask CORS middleware or cross-origin browser URL was added. Local development is same-origin from the browser's perspective and proxies only `/api` to the configured Flask origin.

## 5. Home current-hours integration

Home renders all seven OP-01 rows and the returned IANA timezone. Loading is announced. Failure displays the frozen nontechnical unavailable/retry panel and explicitly says no schedule was assumed. Static schedule claims were removed from Home, Reservations introduction, and the shared footer; Reservations continues to render the complete live OP-01 context.

The live verifier changed Monday test hours from `17:00-23:00` to `18:00-22:00` through the approved test writer, observed the exact change through Vite -> Flask -> PostgreSQL, and restored `17:00-23:00`. Chrome and Edge both rendered the restored seven-day schedule without source changes.

## 6. Live newsletter integration

Through the actual proxy and application role, OP-03 returned `not_found`, then `matched/true` after OP-04; returned authoritative Boolean; produced both identity conflict codes; and persisted no lookup side effect. OP-04 created unknown subscribed true, changed true -> false -> true, accepted same-state true, and returned `no_customer_no_change/false` for unknown false with zero created customer. Live OP-04 `customer_identity_conflict` and `middle_initial_conflict` each returned HTTP 409 with the exact frozen code, `retryable:false`, and `outcome_unknown:false`; privileged before/after evidence proved neither conflict changed the customer count or authoritative newsletter state. Unique fictional `prompt24-*-[GUID]@example.test` identities were used.

Chrome and Edge each completed Home newsletter creation and displayed an identity conflict. No confirmation email or extra profile field was persisted. The database has no `confirmation_email` column. The UI stores no PII or snapshot in URL/history/web storage and prints none to the console.

## 7. Live availability and reservation integration

OP-02 used exact `local_date`/`party_size`, retained API canonical order, and returned/rendered all ten legitimate slots. A clean date was free. One real reservation produced a deterministic party-120 partial scenario (three unavailable and remaining available slots). Test-owned full-capacity reservations produced ten visible unavailable slots; the identical unavailable booking returned API-02 `reservation_unavailable` with `retryable:false/outcome_unknown:false`. React retained slot generation, order, capacity, and table authority on the server.

Chrome and Edge each drove the complete React form through Vite, Flask, the application role, PostgreSQL booking routine, public response, and `ReservationConfirmationView`. Selected server start/offset and structured customer fields were submitted; optional phone and newsletter intent were exercised. The confirmation displayed stored name, decimal-string reference, returned local/canonical interval, party, assigned public table number(s), authoritative newsletter Boolean, and contact facts while withholding submitted email, phone, internal IDs, fingerprint, capacity, and allocation detail. Both browsers measured `scrollWidth === clientWidth` at 390 px and desktop.

The automated live run created one customer, one logical reservation, and one assignment. A distinct OP-05 middle-initial conflict returned HTTP 409 with exact `middle_initial_conflict`, `retryable:false`, and `outcome_unknown:false`, and the reservation count remained unchanged. For distinguishing non-replay evidence, the original immutable OP-05 body created a reservation with `newsletter_action:"subscribe"`; OP-04 then authoritatively changed that same customer to false; the exact original serialized OP-05 body was proven unchanged and resubmitted. It returned `200/exact_retry`, the same reference, and confirmation `newsletter_subscribed:false`; database evidence `1|1|1|1|f` proved one customer, one logical reservation, one assignment, one distinct assignment, and current newsletter false. Thus retry neither created duplicate reservation/assignment data nor replayed the booking-linked subscribe mutation. A shared-table overlap verifier query returned zero. The application login's attempted direct reservation read failed with permission denied; no grant changed.

## 8. Live failures, recovery, and exact retry

Live error evidence includes `validation_failed`, `customer_identity_conflict`, `middle_initial_conflict`, `reservation_overlap`, `reservation_unavailable`, fully unavailable OP-02, Home read transport failure, and OP-04 browser transport ambiguity. Frozen mocked/component/backend suites retain exhaustive temporary/service, confirmation-unavailable, rare outcome-unknown, staleness, unavailable refresh/reselection, and reservation recovery coverage where safely inducing a live frozen-backend seam was not appropriate.

For transport evidence, only the proven-owned Flask launcher/listener stopped while PostgreSQL, Vite, Chrome, and durable markers remained. Home showed no fabricated schedule and an explicit safe read retry. An OP-04 dispatch while Flask was already stopped produced a browser-local connection-refused/proxy protocol failure; the UI conservatively displayed outcome unknown, retained the exact immutable snapshot, locked the form, made no failure claim, and offered no automatic retry. This run does **not** claim actual post-dispatch commit ambiguity. After owned Flask readiness returned, the explicit same-preference action succeeded and the OP-01 retry restored hours.

## 9. Isolation, lifecycle, restartability, and cleanup

Startup order is disposable PostgreSQL 18.3 -> approved migrations/seed/verify -> app/verifier login mapping -> Flask launcher -> direct OP-07 `status:"ready"` -> Vite proxy -> proxied OP-07 `status:"ready"` -> browsers. Durable ownership records repository/root/ports/database, PostgreSQL PID/start/executable/data path/listener, Flask state/readiness plus launcher/listener PID/start/executable/command/parent/intermediate ancestry, and existing Vite/browser helper evidence. Ports are the established backend/frontend test conventions: 55435, 55004, 5173, 9331, and 9332.

The corrected lifecycle guard used sentinel values for alternating managed variables and made the others originally absent. It verified exact presence/value restoration, without displaying values, after successful Start/Status/StopFlask, ordinary failure, guarded startup recovery, direct/proxied readiness rejection, ownership refusal, Cleanup, and final recovery. The twelve names were `CAFE_FAUSSE_ENVIRONMENT`, `CAFE_FAUSSE_ALLOW_RESET`, `CAFE_FAUSSE_PSQL`, `CAFE_FAUSSE_FLASK_PROXY_TARGET`, `CAFE_FAUSSE_VITE_CACHE_DIR`, `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PGPASSFILE`, and `PGSSLMODE`. The same workflow then started from a fresh PowerShell process and proved direct plus proxied readiness.

The launcher-only controlled seam failed immediately after durable exact launcher evidence and before listener association. Its marker remained `launcher_recorded` with readiness false and no listener fields. Guarded recovery proved and stopped the exact launcher, preserved the already-running PowerShell caller through its retained process object/handle without creating or later terminating a disposable sentinel, observed no orphan, and removed the owned root only after recovery. Separate direct and proxy seams kept real listeners open while rejecting their readiness result: direct failure retained `listener_recorded`/readiness false for recovery; full proxy failure never emitted the environment-ready message and completed guarded cleanup. Full cleanup now preflights PostgreSQL, Flask, and Vite ownership before stopping any layer. Malformed JSON, a mismatched owner, a mismatched launcher creation time, and disconnected listener ancestry each caused Cleanup to refuse before any PostgreSQL, Flask, or Vite stop; restoring the exact evidence then allowed safe cleanup. The focused guard also parsed the termination function, proved it contains no `Get-Process` PID reacquisition, required the retained safe-handle proof and same-object `Kill()`, and exercised exact-object listener/launcher stops in the complete lifecycle. Already-exited launchers/listeners are accepted only when their complete recorded identity is absent and their associated ports/descendants are clear. Missing/incomplete/mismatched evidence, disconnected ancestry, multiple/foreign listeners, or a port without its recorded chain is preserved and refused.

Final cleanup stopped and removed Chrome PID/profile/CDP 9331 and Edge PID/profile/CDP 9332, Vite, Flask, and PostgreSQL only after ownership proof. It rebuilt the disposable database and proved `0|0|0`, stopped PostgreSQL, removed the test database with its cluster, roles, logs, Vite cache, browser profiles/markers, and owned root, and verified ports were closed. The helper's outer restoration guard returned the caller's exact prior environment presence/value after final cleanup. The API-09 runner independently completed two clean setup/cleanup passes.

## 10. Automated tests and regressions

- Focused live adapter/App/proxy/CurrentHours: 4 files, 21 tests passed.
- Focused lifecycle guard: exact-handle/no-PID-reacquisition inspection plus all success/failure/restoration, launcher-only recovery, readiness rejection, and malformed-ownership refusal cases passed.
- Reservation/validation: 2 files, 40 tests passed.
- Standalone newsletter: 1 file, 19 tests passed.
- Contract fixture/MSW route flows: 2 files, 25 tests passed.
- Complete frontend: 15 files, 162 tests passed; all 141 frozen REACT-05 tests remain.
- Coverage: statements 93.93% (712/758), branches 88.90% (561/631), functions 91.00% (182/200), lines 96.66% (609/630).
- Production build: passed, Vite 8.2.2, 112 modules transformed.
- `npm audit --audit-level=low`: `found 0 vulnerabilities`.
- Static parsing: all five frontend PowerShell scripts and all 25 PowerShell blocks in `frontend/TestInstructions.md` passed; the Node CDP script parsed/executed successfully.
- Final backend/database gate: API-09 passed two consecutive complete cycles. Each passed 458 unit/API, 62 PostgreSQL, and combined 520-test coverage, with PostgreSQL 18.3 verification and owned zero-row cleanup.

The later exact-handle termination correction reran the changed-script parser, all 25 frontend instruction blocks, the complete lifecycle guard, live OP-01 through OP-05/PostgreSQL verifier, Chrome/Edge smoke, controlled transport failure/recovery, 21 focused integration tests, all 162 frontend tests, coverage, build, and audit successfully. Its lifecycle guard statically and dynamically confirmed same-object termination and safe already-exited handling. The final API-09 rerun was attempted twice: both attempts passed all 458 unit/API tests and 61 of 62 PostgreSQL tests, then the unchanged frozen `test_free_partial_full_and_back_to_back_occupancy_are_provisional_and_nonmutating_after_cleanup` failed with `StopIteration` while locating its computed `full_start_text` slot. Both attempts completed guarded PostgreSQL/environment cleanup. No backend/database correction was made because that reproducible current-environment failure is outside REACT-06 and unrelated to the process-handle change; the earlier two-cycle API-09 pass above remains the last complete passing backend gate evidence.

One deliberately invalid execution ran the full frontend suite and coverage concurrently; CPU contention caused existing 5-second interaction tests to time out. Their focused groups passed immediately before, and the required sequential full and coverage runs both passed 162/162. The concurrent result is not used as gate evidence.

## 11. Cross-layer timing and browser evidence

Environment: Windows Server 2025 host, local Vite 8.2.2 -> Flask 3.1.3 -> application role -> disposable PostgreSQL 18.3. `System.Net.Http.HttpClient` measured end-to-end request/response elapsed time through Vite. Samples were representative and sequential; setup/reset was excluded.

| Operation | Samples | Min ms | Average ms | Max ms |
| --- | ---: | ---: | ---: | ---: |
| OP-01 | 5 | 8.316 | 9.026 | 10.667 |
| OP-02 | 5 | 355.501 | 375.768 | 410.604 |
| OP-03 | 6 | 8.093 | 9.183 | 11.693 |
| OP-04 | 8 | 8.064 | 8.934 | 11.221 |
| OP-05 | 6 | 345.738 | 391.511 | 484.971 |

No measured ordinary operation exceeded two seconds. These descriptive samples do not establish final NFR-01/NFR-02 compliance or the later concurrency/performance gate.

Locally installed headless Chrome 151.0.7922.170 and Edge 151.0.4129.101 both passed live Home hours, newsletter creation/conflict, availability, reservation success/confirmation, email withholding, and 390 px/desktop overflow. Chrome additionally passed real read-failure, conservative outcome-unknown/locked snapshot, explicit identical mutation recovery, and read recovery. Safari was not tested on Windows and is deferred to Prompt 25. This is practical changed-behavior evidence, not final four-browser or WCAG acceptance.

## 12. Traceability, limitations, and checkpoint

Traceability: SRS FR-02, FR-06 through FR-09, FR-15 through FR-18, NFR-02, NFR-05, NFR-06, NFR-08, and NFR-09; rubric React/Flask/PostgreSQL integration and direct database effects; PRA-006 through PRA-025 and PRA-029; PostgreSQL Contract for Flask; API-02 OP-01 through OP-05/error/no-store/privacy rules; REACT-01 CurrentHours/operation boundary; REACT-02 async/error/recovery UX; REACT-03 live hours/visual/test strategy; and frozen REACT-04/05 implementation boundaries.

Known limitations and deferrals:

- Actual lost-response-after-possible-commit ambiguity was not safely induced; connection-refused conservative handling and exact explicit recovery were verified accurately.
- Rare live server temporary/confirmation-unavailable seams were not added to the frozen backend; exhaustive existing mocked/backend coverage remains.
- Timing is descriptive, not final performance compliance.
- Safari/final four-browser acceptance, final React gate, INT-06 through INT-09, deployment, final documentation/provenance, and demonstration remain Prompt 25 or later.
- Asset provenance/licensing remains the INT-08 checkpoint; no asset changed.

**Approval checkpoint:** REACT-06 / Prompt 24 passed independent final review and is **APPROVED AND FROZEN**. The approved complete review artifact is `REACT06-review-final-approved-candidate.diff` (157,046 bytes; SHA-256 `F38E351B829417F78A55B3894EFFB97CD39EBB6E243709391339910FF73B4CB0`; 21 represented paths comprising 10 tracked modifications and 11 new files). All identified REACT-06 blockers are closed. The unchanged API-09 PostgreSQL `StopIteration` failure was independently reproduced at baseline with the same failure mode and is not a REACT-06 regression. The approval finalization commit excludes every review diff and does not begin Prompt 25.
