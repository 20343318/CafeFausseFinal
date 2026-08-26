# Cafe Fausse Prompt 25 Full Integration Verification

**Date:** 2026-08-26

**Status:** APPROVED AND FROZEN

**Authorized scope:** Prompt 25 full end-to-end verification only. Prompt 26 has not begun.

## 1. Baseline and authority

- Branch: `main`
- Prompt-25 starting checkpoint: `acd419a8942a10a1d646847a94b5a05aedad6841`
- Execution HEAD and `origin/main`: `6ec2ca3040755cb5cdbe8d55e067d2d08f2e5d4f`
- `acd419a` is an ancestor of execution HEAD; the only later commit is the Prompt-25 authorization.
- Independent ChatGPT review approved the Prompt-25 candidate represented by SHA-256 `ad377fd5d0050f41679f47f82610a284fe084c0a49df0906869f7b47fb554bef`.
- REACT-06 / Prompt 24 remains approved and frozen.
- The SRS, rubric, Project Requirements Addendum, roadmap, PostgreSQL contract, API contract, and REACT-01 through REACT-06 decisions were treated as authoritative and were not changed.

## 2. Prompt-25 scenario results

| # | Required scenario | Result | Evidence |
|---:|---|---|---|
| 1 | Valid newsletter signup through React reaches PostgreSQL | PASS | Chrome submitted the Home form; direct SQL returned exactly `1|Prompt|M|Twentyfive|t`. |
| 2 | Duplicate and invalid newsletter behavior | PASS | An identical UI save succeeded idempotently with one customer; mismatched confirmation email was blocked client-side without OP-04 dispatch; a direct invalid email received `422 validation_failed` and created no customer. |
| 3 | React dates and slots reflect server-authoritative rules | PASS | Date min/max, maximum party size, four policy facts, ordered slot values, and every enabled/disabled state matched the same live OP-01/OP-02 snapshots. |
| 4 | Approved setting change and restoration | PASS | `start_interval_minutes` changed `30 -> 60` through the approved PostgreSQL test writer; Flask and React slot behavior changed without source modification; `finally` restored `60 -> 30`, and the original slot sequence returned. |
| 5 | Valid React reservation reaches PostgreSQL | PASS | A party-of-6 browser booking produced reference `1`; direct SQL returned one customer, one reservation, two assignments, two distinct tables, and subscribed state: `1|1|2|2|t`. The sorted React-displayed table-number set and the PostgreSQL assignment set for that reservation matched exactly: `12,25`. |
| 6 | Assigned table cannot be reused by an overlapping reservation | PASS | A different customer booked the same interval; direct SQL found zero shared tables between the two overlapping reservations. The global overlapping shared-table query also returned zero. |
| 7 | Fully booked API and React behavior | PASS | Four controlled party-of-120 blockers made all 10 legitimate slots unavailable; OP-02 retained 10 all-false slots, React rendered 10 disabled slots plus its all-unavailable message, OP-05 returned `409 reservation_unavailable`, and the failed identity created no customer. |
| 8 | Manipulated slot rejected outside React controls | PASS | A valid server slot shifted by one minute received `422 validation_failed` with `starts_at_local/invalid_reservation_time`; direct SQL proved no customer mutation. |
| 9 | Customer identity and middle-initial conflicts | PASS | Browser-driven OP-03 and OP-04 paths displayed the frozen generic identity and middle-initial correction behavior; the originally stored customer remained `Prompt M Twentyfive`, subscribed, with one row. Existing live OP-05 conflict checks also passed with no reservation mutation. |
| 10 | Exact retry is idempotent and does not replay newsletter action | PASS | The browser allowed the first OP-05 response to commit, then simulated response loss. React showed a locked unknown-outcome state. OP-04 changed newsletter true to false. React made exactly two OP-05 attempts with a byte-identical body; the captured second response was HTTP `200` with `booking_result: "exact_retry"`. React displayed the recovered reservation, retained one customer/one reservation, and both the response and PostgreSQL returned current false: `1|1|t -> 1|1|f`. |
| 11 | Controlled transport failure and recovery | PASS | Frozen `StopFlask` produced React read failure, mutation-unknown, and locked snapshot states; guarded `StartFlask` plus explicit identical mutation/read retry produced both recovery states. |
| 12 | Direct PostgreSQL persistence/non-mutation evidence | PASS | Direct verifier-role SQL covered newsletter/customer state, reservation and assignment counts, reference agreement, configuration restore, failed-request nonmutation, exact retry, and zero shared-table overlap. Application-role direct reservation reads remained denied. |

All twelve Prompt-25 scenarios passed. No production implementation defect or frozen-contract violation was found in these scenarios.

## 3. Live/browser evidence

- Frozen lifecycle guard: PASS. Exact-handle termination, readiness, caller-environment restoration, launcher-only recovery, refusal on malformed/mismatched ownership, and cleanup all passed.
- Existing live Vite -> Flask -> PostgreSQL verifier: PASS.
  - OP-01 maximum: 32.943 ms
  - OP-02 maximum: 450.879 ms
  - OP-03 maximum: 11.337 ms
  - OP-04 maximum: 22.928 ms
  - OP-05 maximum: 455.325 ms
- Focused Chrome full-integration verifier: PASS.
- Chrome `151.0.7922.170`: full Prompt-25 scenario execution passed.
- Edge `151.0.4129.107`: live Home hours, newsletter save/conflict, availability, reservation confirmation, email withholding, and 390 px/desktop overflow smoke passed.
- The SRS browser compatibility requirement remains unchanged. Firefox was not installed, so automated execution was out of scope on this Windows host and validation is deferred to manual testing in a Firefox-capable environment. Safari is unavailable on Windows, so validation is deferred to manual testing in a Safari-capable environment. No Firefox or Safari result, four-browser automated pass, or removal of either browser from the SRS requirement is claimed.

## 4. Automated regression results

### PostgreSQL

- The frozen live environment performed clean DB-05, DB-06, and DB-07 rebuild/verification successfully on every lifecycle start.
- API-09 PostgreSQL selection: 61 of 62 passed. The only failure was the exact unchanged known baseline-pre-existing test and failure mode documented by Prompt 25:
  - `test_free_partial_full_and_back_to_back_occupancy_are_provisional_and_nonmutating_after_cleanup`
  - `StopIteration` while locating `full_start_text`
- Authoritative environment review found that `database/TestInstructions.md`, `database/README.md`, `database/scripts/programmer_test.ps1`, and the normative `database/scripts/test.ps1` require PostgreSQL `18.3`, `pgcrypto`, an isolated local database, an administrator, and explicit independent nonproduction authorization. The harness additionally enforces version `180003`, `postgres`, loopback address/port, the named administrator, and non-recovery mode. None specifies or checks a locale, collation, or provider. The approved DB-05 report records that its historical execution used ICU, but does not establish ICU as a requirement; the DB-06/DB-07 reports, SRS, rubric, and approved designs specify none.
- The unchanged complete `database/scripts/programmer_test.ps1 -Mode Complete` gate passed against an explicitly authorized disposable PostgreSQL `18.3` cluster initialized with PostgreSQL's normal Windows defaults, without `--no-locale` and without an ICU request. Exact facts were server version `18.3` / `180003`, UTF-8 encoding, libc provider (`datlocprovider = c`), and `English_United States.1252` for both `datcollate` and `datctype`; `postgres` and `template0` matched. The frozen `É` fixture was one character/two UTF-8 bytes and matched both `[[:alpha:]]` and `[[:upper:]]`.
- Exact terminal markers were `[HARNESS:AUTHORIZATION:PASS]`, `[HARNESS:TARGET:PASS]`, `[HARNESS:RECOVERY:PASS]`, `[HARNESS:OWNERSHIP:PASS]`, `[HARNESS:DATABASE:PASS]`, `[HARNESS:PROVISIONER:PASS]`, `[HARNESS:ROLES:PASS]`, `[HARNESS:EXECUTION:PASS]`, `[HARNESS:CLEANUP-DATABASE:PASS]`, `[HARNESS:CLEANUP-ROLES:PASS]`, `[HARNESS:CLEANUP:PASS]`, and `[HARNESS:COMPLETE:PASS]`; exit code was `0`. The gate included the DB-05 regression, two complete DB-07 rebuilds, 75 DB-06 concurrency scenario iterations, 20-sample DB-07 measurements, query plans, final empty-baseline rebuild, and final DB-07 verification.
- Cleanup queries returned `0|0|0|marker_exists=false`: zero generated harness databases, zero run-specific harness roles, zero fixed Cafe Fausse roles on the fresh cluster, and no harness ownership marker. The owned server then stopped and its data, logs, and ownership root were removed. This proves ICU is not required for the frozen fixture. The earlier `C`-locale cluster differed because POSIX character classes under `C` do not classify `É` as alphabetic even with UTF-8 encoding; the Windows libc locale does. No ICU, libc, hard-coded-locale, or locale/provider-preflight requirement was introduced.

### Flask/API

- API-09 static checks: PASS; four runner scripts and 49 backend instruction blocks parsed, and Python sources compiled in owned temporary storage.
- Unit/API selection: 458 of 458 passed.
- PostgreSQL selection: 61 of 62 passed, with only the exact known baseline failure above.
- Performance test completed and remained below two seconds; representative maxima were 320.227 ms for OP-02, 297.608 ms for OP-05 creation, and 303.492 ms for OP-05 exact retry.
- API-09 guarded cleanup: PASS; cluster, database, roles, rows, generated files, server, and environment changes were removed.

### React

- `npm run test:integration`: 21/21 passed.
- `npm run test:reservations`: 40/40 passed.
- `npm run test:newsletter`: 19/19 passed.
- `npm run test:mocked-flows`: 25/25 passed.
- `npm test`: 162/162 passed across 15 files.
- First sandboxed coverage attempt: 160 passed and two unchanged 5-second async tests timed out after npm reported user-prefix access denials. Both tests had passed immediately beforehand.
- Sandbox-free `npm run coverage` rerun: 162/162 passed; 93.93% statements, 88.90% branches, 91.00% functions, and 96.66% lines.
- `npm run build`: PASS; Vite 8.2.2 transformed 112 modules.
- `npm audit --audit-level=low`: PASS; zero vulnerabilities.
- Locked direct dependency inventory matched `package.json`/`package-lock.json`; neither file changed.

## 5. Verification defects corrected

No production source was corrected.

The new Prompt-25 browser verifier initially contained two test-only synchronization/semantics defects:

1. It could observe a previous newsletter success before a very fast duplicate request completed. It now waits for durable panel replacement, request-count advancement, and final authoritative state.
2. It checked an input's own `disabled` property even though the frozen UI locks it through a disabled parent fieldset. It now checks the browser-effective `:disabled` state.

Independent review then identified three evidence/cleanup gaps in the proposed Prompt-25 candidate. The new verifier now captures and asserts the authoritative second OP-05 response (`200` / `booking_result: "exact_retry"`), directly compares the sorted React and PostgreSQL assigned-table sets, and the final cleanup instructions now invoke the frozen guarded live-integration cleanup before absence assertions. These changes only strengthen the new verifier and its test instructions. The complete focused Prompt-25 run passed afterward.

## 6. Changed paths and contract protection

| Path | Purpose |
|---|---|
| `frontend/scripts/verify-full-integration-browser.mjs` | Browser-driven Prompt-25 UI scenarios using the existing owned CDP browser process. |
| `frontend/scripts/verify-full-integration.ps1` | Focused orchestration, API assertions, privileged direct PostgreSQL evidence, controlled configuration, capacity, retry, and transport recovery checks. |
| `frontend/TestInstructions.md` | Repeatable Prompt-25 execution, regression, browser limitation, locale evidence, and final cleanup instructions. |
| `docs/integration-verification/Cafe_Fausse_Prompt25_Full_Integration_Verification.md` | This execution record. |

No backend production source, frontend production source, migration, schema, database routine, role/grant, API contract, approved design artifact, dependency, package manifest, package lock, or Gallery asset changed. Frozen contracts were not changed.

## 7. Setup and execution entry points

Follow `frontend/TestInstructions.md` Sections 17-20. The focused command, after the frozen owned environment and browser are started, is:

```powershell
& .\frontend\scripts\verify-full-integration.ps1 `
  -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' `
  -Browser chrome `
  -CdpPort 9341
```

The standalone PostgreSQL gate must follow `database/TestInstructions.md` against an explicitly approved nonproduction PostgreSQL 18.3 cluster. No ICU requirement is established. The Flask/API gate remains:

```powershell
& .\backend\tests\run_api09.ps1 `
  -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
```

## 8. Cleanup and checkpoint

- Browsers were stopped through exact ownership markers; profiles and markers were removed.
- Vite and Flask were stopped through proven process objects.
- Disposable PostgreSQL databases, roles, rows, server, data, logs, and ownership roots were removed.
- After a controlled ordinary verifier failure left the proven-owned Chrome and PostgreSQL -> Flask -> Vite environment live, the complete Section-20 block passed from a fresh PowerShell session and removed those resources through the frozen guarded helpers. A second fresh-session execution passed idempotently with the resources already absent.
- Coverage, production build output, Vite cache, browser roots, and PDF inspection scratch files were removed.
- Ports `55435`, `55442`, `55004`, `5173`, `4173`, `9331`, `9332`, `9341`, and `9342` were closed.
- API-07/API-06, live-integration, browser, and database-harness temporary roots were absent.
- Staged path count: zero.
- Prompt 26 has not begun.

**Approval checkpoint:** Prompt 25 is APPROVED AND FROZEN. The standalone PostgreSQL regression gate is resolved by the unchanged complete pass above. The twelve focused scenarios passed, while API-09 retains only its prompt-authorized baseline failure.
