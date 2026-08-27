# Cafe Fausse NFR-1 / NFR-2 Performance Verification

**Status:** APPROVED AND FROZEN

**Measurement date:** 2026-08-26

**Baseline:** `000d8d4bdd9972d98c30cf2e886d33c3b137b86b`

**Run ID:** `b4b0ddd7b20149a1b10911aab83d36cd`

## 1. Result and approval checkpoint

- **NFR-1 PERFORMANCE EVIDENCE: PASS.** All 25 ordinary samples were at or below 3,000 ms. The global maximum was **782.601 ms** on `/`.
- **NFR-2 PERFORMANCE EVIDENCE: PASS.** All 10 newsletter samples and all 10 reservation samples were at or below 2,000 ms. The maxima were **81.925 ms** and **462.336 ms**, respectively.
- **VM conclusion: NO VM SCALING INDICATED.** Both SRS thresholds passed on the current VM. The short-interval CPU/memory observations are disclosed below, but no threshold failure occurred and Prompt-26A authorizes no VM change.
- **Performance portion of the pre-Prompt-27 gate: CLOSED.** This does not close the separate NFR-7 browser-verification work. Firefox and Safari remain pending manual verification in capable environments.
- **Approval checkpoint:** Independent ChatGPT review passed with no blocking findings, and user-authorized approval is recorded. Prompt-26A is **APPROVED AND FROZEN**. The frozen Prompt-26 audit is unchanged, and Prompt 27/Prompt 28 have not begun.

## 2. Authority, scope, and exclusions

The verification followed the repository `AGENTS.md`, `docs/SRS(1).pdf`, `docs/Rubric(1).pdf`, Project Requirements Addendum v2.2.1, approved least-to-most roadmap, frozen PostgreSQL and Flask contracts/artifacts, frozen React artifacts through REACT-06, frozen Prompt-25 integration evidence, frozen Prompt-26 audit, and the existing guarded live-integration lifecycle.

The scope was quantified Chrome evidence for NFR-1 and NFR-2 only. It did not modify production behavior, schema, transactions, contracts, source, dependencies, packages, assets, or the VM. It did not test Firefox or Safari and did not begin Prompt 27 or Prompt 28.

The exact SRS obligations are:

- NFR-1: "The website should load within 3 seconds on a standard broadband connection."
- NFR-2: "Form submissions (reservations and email sign-up) should be processed within 2 seconds."

The concurrency, sample counts, cache treatment, timing boundaries, and no-throttling choices below are an approved verification protocol. They are test-method decisions, not supplemental product requirements, and were not added to the Project Requirements Addendum.

## 3. Actual environment and operating basis

| Item | Observed value |
|---|---|
| Windows | Microsoft Windows Server 2025 Standard, version/build `10.0.26100` / `26100` |
| Logical processors | 8 |
| Physical memory | 8,588,820,480 bytes (8.00 GiB) |
| Available memory at test start | 1,171,509,248 bytes (1.09 GiB) |
| Node.js | `v24.15.0` |
| npm | `12.0.2` |
| Python | `3.14.6` |
| PostgreSQL server | `18.3` |
| Chrome | `151.0.7922.170` |
| Flask | `3.1.3` |
| React | `19.2.8` |
| Vite | `8.2.2` |

The observed memory is 8 GiB, not the approximately 16 GB anticipated by the prompt. Processor count matched the expected eight logical processors. The same configuration remained in place throughout; no CPU or memory scaling/reconfiguration occurred.

Exactly one browser user ran sequentially. The measurement used the actual unthrottled local VM path from Chrome to Vite, Flask, and PostgreSQL. No numeric definition was invented for "standard broadband," and no DevTools bandwidth, latency, packet-loss, or CPU throttle was applied. No unrelated project suite or intentional stress/load workload ran concurrently.

## 4. Stack preparation and timing protocol

The frozen owned lifecycle created a disposable PostgreSQL 18.3 cluster/database, applied and verified migrations 001-011, started Flask on `127.0.0.1:55004`, and started Vite on `127.0.0.1:5173`. Its status gate proved all processes, listeners, markers, direct Flask readiness, and Vite-proxied readiness. Owned headless Chrome then started with a dedicated profile and CDP endpoint. Server, process, database, and browser startup time was excluded.

One unmeasured Home navigation completed after readiness. It established the required warm application/server and was not used as passing evidence.

### NFR-1 boundary and cache treatment

Before every measured direct navigation, CDP `Network.clearBrowserCache` cleared Chrome's HTTP cache and `Storage.clearDataForOrigin` cleared test-origin cache storage, local storage, and session storage. The application/server remained warm. A monotonic Node/CDP interval began immediately before `Page.navigate` and ended only after both the CDP document load event and the route-specific visible React readiness condition had completed. The later point controlled the result. Navigation Timing was also captured for diagnostic support.

| Route | Exact usable-state condition |
|---|---|
| `/` | Visible `Café Fausse` H1 and rendered live server-sourced current-hours content |
| `/menu` | Visible `Menu` H1 and all four menu-category sections rendered |
| `/reservations` | Visible `Reservations` H1, date control, and server-authoritative ready status rendered |
| `/about` | Visible `About Us` H1 plus story and founders sections rendered |
| `/gallery` | Visible `Gallery` H1 and at least five gallery image controls rendered |

Document load completion was required for every route. Indefinitely deferred/lazy content not needed for initial usability was not added to the condition.

### NFR-2 boundary

Each form was prepared before timing. The monotonic interval began immediately before CDP dispatched the actual left-button press/release on the enabled submit button. It ended only after both the authoritative mutation response body had completed and the final React success state was rendered.

For newsletter samples, preparation included unique fictional identity data, an ordinary status lookup, and a selected subscribe choice. The final condition required HTTP `200`, result `set`, the mutation response complete, `aria-busy=false`, and the visible "Newsletter preference saved" outcome.

For reservation samples, every iteration navigated through the ordinary Reservations UI, waited for the server-authoritative context, selected `2026-08-27`, requested availability for party size four, selected an enabled server-returned slot, and completed a unique fictional customer identity before timing. The final condition required HTTP `201`, booking result `created`, the mutation response complete, and the visible `Reservation confirmed` heading. All ten were ordinary creations with references 1 through 10; no exact retry substituted for a creation.

## 5. NFR-1 measurements

All values are milliseconds. Samples ran sequentially in the order shown.

| Route | Iteration 1 | Iteration 2 | Iteration 3 | Iteration 4 | Iteration 5 | Minimum | Median | Maximum |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `/` | 497.982 | 603.828 | 782.601 | 695.518 | 761.039 | 497.982 | 695.518 | 782.601 |
| `/menu` | 406.480 | 503.101 | 740.001 | 254.764 | 282.675 | 254.764 | 406.480 | 740.001 |
| `/reservations` | 402.021 | 558.489 | 463.955 | 371.017 | 489.822 | 371.017 | 463.955 | 558.489 |
| `/about` | 364.683 | 316.123 | 602.602 | 425.007 | 472.573 | 316.123 | 425.007 | 602.602 |
| `/gallery` | 425.459 | 334.589 | 348.128 | 376.768 | 280.368 | 280.368 | 348.128 | 425.459 |

The global maximum across all 25 samples was **782.601 ms on `/` iteration 3**. Every sample was at or below 3,000 ms; therefore **NFR-1 PERFORMANCE EVIDENCE: PASS**.

## 6. NFR-2 measurements

All values are milliseconds. The descriptive p95 uses nearest-rank calculation; with ten samples it equals the maximum and is not an SRS acceptance percentile.

| Newsletter iteration | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Elapsed | 81.925 | 35.324 | 32.588 | 33.311 | 34.165 | 35.254 | 36.595 | 34.843 | 36.114 | 34.239 |

| Newsletter minimum | Median | Descriptive p95 | Maximum |
|---:|---:|---:|---:|
| 32.588 | 35.049 | 81.925 | 81.925 |

All ten newsletter samples were successful ordinary mutations and were at or below 2,000 ms. **Newsletter NFR-2 evidence: PASS.**

| Reservation iteration | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Elapsed | 375.844 | 349.683 | 327.510 | 420.294 | 434.981 | 404.422 | 390.513 | 462.336 | 381.469 | 388.290 |

| Reservation minimum | Median | Descriptive p95 | Maximum |
|---:|---:|---:|---:|
| 327.510 | 389.401 | 462.336 | 462.336 |

All ten reservation samples were successful ordinary creations and were at or below 2,000 ms. **Reservation NFR-2 evidence: PASS.** Therefore **NFR-2 PERFORMANCE EVIDENCE: PASS** for both required forms.

## 7. Threshold failures, outliers, and diagnostics

No ordinary acceptance sample exceeded its threshold. The prompt's failure/outlier diagnostic rerun procedure was therefore not triggered, and no extra stress testing was manufactured.

Before the completed acceptance run, two non-acceptance tooling attempts occurred. The sandboxed launch was rejected by PostgreSQL's restricted-token behavior and its partial owned cluster was removed. The next attempt completed routes/newsletters but the new verifier expected the database-layer label `booked` instead of the frozen API label `created`; it rejected the first valid HTTP `201` creation and emitted no acceptance JSON. The verifier-only assertion was corrected without changing production source, and the owned database was removed before the complete run. Neither attempt supplied a threshold failure or a discarded slow sample.

## 8. CPU, memory, and paging observations

Lightweight OS CPU-tick and free-memory snapshots bracketed each of 45 samples. Aggregate observed CPU was 21.600% minimum, 60.473% median, and 99.638% maximum. Available physical memory was 906,895,360 bytes (0.84 GiB) at the measurement-period boundary and reached a sampled minimum of 348,377,088 bytes (0.32 GiB). The maximum derived used physical memory was 8,240,443,392 bytes (7.67 GiB).

At the earlier environment snapshot, `C:\pagefile.sys` had 15,360 MiB allocated, 3,763 MiB current use, and 6,904 MiB recorded peak use; Windows reported 12,159,766,528 bytes free across paging files. These counters show a memory-constrained host and existing page-file use, but they do not prove active paging during a particular sub-second sample. Short sample-level CPU percentages are also volatile. Despite transient high CPU and low available memory, every ordinary full-stack result retained substantial threshold margin. No observed external workload was identified and no VM change was made.

## 9. Reconciliation with prior evidence

- DB-07 measured PostgreSQL-local availability around 342-434 ms p50/p95 and ordinary booking paths ranging from roughly 347 ms fast-path p50 to 1,265 ms general-allocation p95, including local process/connection overhead. It also documented multi-user contention above two seconds. Prompt-26A's approved one-user browser reservation results (327.510-462.336 ms) are consistent with an ordinary four-person fast allocation and do not reinterpret the prior concurrency evidence.
- API-09's later Prompt-25 rerun recorded maxima of 320.227 ms for OP-02, 297.608 ms for OP-05 creation, and 303.492 ms for exact retry. Those lower-layer timings excluded final browser rendering.
- REACT-06 recorded sequential Vite-path maxima of 11.221 ms for OP-04 newsletter and 484.971 ms for OP-05 reservation. It explicitly classified them as descriptive rather than final NFR evidence.
- Prompt-25 recorded live maxima of 22.928 ms for OP-04 and 455.325 ms for OP-05 but did not time submit dispatch through final React state. Prompt-26A's newsletter maximum of 81.925 ms and reservation maximum of 462.336 ms include that missing browser boundary and are materially consistent with the earlier diagnostic values.
- No prior artifact supplied qualifying NFR-1 page-load evidence. The 25 cold-browser-cache navigation samples in this report close that evidence gap under the approved protocol.

No material conflict with earlier ordinary-path evidence was found. Isolated database/API results remain supporting diagnostics, not substitutes for these acceptance measurements.

## 10. Tooling, repeatability, and cleanup

Prompt-26A created or changed only:

| Path | Purpose |
|---|---|
| `frontend/scripts/verify-nfr-performance-browser.mjs` | CDP navigation, browser/UI mutation, full timing, cardinality, and lightweight system observations |
| `frontend/scripts/verify-nfr-performance.ps1` | Baseline protection, owned lifecycle/browser orchestration, environment inventory, result validation, and guarded cleanup entry points |
| `frontend/TestInstructions.md` | Repeatable/restartable Prompt-26A method, prerequisites, result location, interruption recovery, and final cleanup |
| `docs/performance-verification/Cafe_Fausse_NFR01_NFR02_Performance_Verification.md` | Approved and frozen quantified evidence and decision gate |

The measurement command and final cleanup commands are in `frontend/TestInstructions.md` section 21. They reuse frozen ownership markers and refuse ambiguous deletion/termination. Temporary result JSON is intentionally not retained after this report is populated.

**Final cleanup result: PASS.** The frozen helper stopped owned Chrome, but its PowerShell strict-mode scalar edge appeared while checking the now-exited profile users. The new Prompt-26A wrapper accepted that recovery path only after revalidating the exact frozen marker identity and expected paths, proving the recorded Chrome process absent, proving zero processes referenced the profile, and proving the CDP port closed. It then removed only the exact owned profile/marker and empty parent roots. The frozen lifecycle subsequently removed the owned Vite and Flask processes, all test rows/roles/database/cluster data/logs/cache, and its ownership root. The Prompt-26A temporary result JSON/root was removed. `[PROMPT26A:BROWSER-SCALAR-EDGE-RECOVERY:PASS]` and `[PROMPT26A:CLEANUP:PASS]` were emitted. A subsequent clean-state cleanup/absence check passed idempotently.

## 11. Preservation and next gate

Firefox and Safari were explicitly deferred and untouched. No Firefox/Safari browser process or result was produced. NFR-7 remains factually separate and pending.

The approved/frozen Prompt-26 audit remained untouched. The committed Prompt-26A prompt remained untouched. No production source, dependency/package/lockfile, approved artifact, contract, migration, Gallery asset, Prompt-27 artifact, or Prompt-28 artifact changed.

The performance portion of the pre-Prompt-27 gate is **CLOSED** by the passing NFR-1/NFR-2 evidence. The overall gate is not claimed closed because Firefox/Safari manual verification remains pending under the frozen workflow.

**Final approval record:** Independent ChatGPT review passed, and the user-authorized approval is recorded. NFR-1, NFR-2 newsletter, and NFR-2 reservation performance evidence are PASS; the performance portion of the pre-Prompt-27 gate is CLOSED; and the measured evidence indicates NO VM SCALING. Firefox/Safari compatibility remains separately pending manual verification, so NFR-7 is not declared fully closed and Prompt 27 remains **NOT YET SAFE TO BEGIN** until that outstanding compatibility gate is handled according to the frozen workflow. Do not begin Prompt 27 or Prompt 28 from this checkpoint.
