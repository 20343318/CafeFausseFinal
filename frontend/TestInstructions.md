# Café Fausse Frontend Test Instructions

Sections 1-16 preserve the REACT-04/05 frontend-only and mocked-flow procedures. Sections 17-18 preserve the bounded REACT-06 / Prompt-24 live React-to-Flask integration workflow. Sections 19-20 add the Prompt-25 full-integration gate without changing the frozen lifecycle. Both live workflows are repeatable after success, ordinary failure, or interruption and use only a disposable nonproduction PostgreSQL 18.3 cluster. Run commands from `frontend/` unless a step says otherwise.

## 1. Prerequisites

- Windows PowerShell 5.1 or PowerShell 7+
- Node.js `v24.15.0`
- npm `11.12.1`
- A current browser for manual checks
- No running process already using ports `5173` or `4173`; the owned-process helper refuses to claim or terminate an existing listener

The selected package engines are satisfied by Node `v24.15.0`. Safari cannot be verified on Windows and remains deferred to manual validation in a Safari-capable environment.

## 2. Install the locked dependencies

Use the lockfile rather than updating package versions:

```powershell
npm ci
```

Confirm the exact direct dependency tree and audit result:

```powershell
npm ls --depth=0
npm audit --audit-level=low
```

Expected audit result for this increment: `found 0 vulnerabilities`.

## 3. Start, identify, and stop an owned development server

```powershell
.\scripts\owned-vite-process.ps1 -Action Start -Kind dev
.\scripts\owned-vite-process.ps1 -Action Status -Kind dev
```

Open `http://127.0.0.1:5173/`. The helper starts Vite on the documented port and writes durable ownership evidence to `.tmp-react22-verification\processes\dev.json`: owner/schema, process kind, PID, UTC process creation time, Node executable path, frontend working directory, Vite entry point, and port. Keep that marker for the entire run.

Stop only through the guarded helper:

```powershell
.\scripts\owned-vite-process.ps1 -Action Stop -Kind dev
```

Before stopping anything, the helper requires the marker identity, PID, creation time, executable, Vite command line, working directory, and port to match the live process. It removes the marker after a proven-owned stop or after proving that a valid marker is stale. It refuses to start when port `5173` is already occupied and never searches for or broadly kills Node, npm, Chrome, Edge, or unrelated processes.

## 4. Build and preview production output

```powershell
npm run build
.\scripts\owned-vite-process.ps1 -Action Start -Kind preview
.\scripts\owned-vite-process.ps1 -Action Status -Kind preview
```

Open `http://127.0.0.1:4173/`. Stop it with:

```powershell
.\scripts\owned-vite-process.ps1 -Action Stop -Kind preview
```

Preview ownership is recorded independently in `.tmp-react22-verification\processes\preview.json` using the same proof requirements. Vite preview supports these application routes for local verification; a deployed static host must rewrite unknown non-asset SPA paths to `index.html` so direct browser requests work.

## 5. Focused, mocked-flow, and full automated tests

Shell, routes, static content, and responsive navigation:

```powershell
npm run test:shell
```

Gallery discovery, ordering, rendering, and lightbox:

```powershell
npm run test:gallery
```

All Prompt-22 frontend tests:

```powershell
npm test
```

Reservation validation, context, availability, staleness, customer fields, immutable submission, public error mapping, recovery, and confirmation:

```powershell
npm run test:reservations
```

Standalone newsletter validation, 400 ms debounce, stale/dirty lookup guards, final Boolean mutations, conflicts, pending locks, and unknown-outcome recovery:

```powershell
npm run test:newsletter
```

Full-route OP-01 through OP-05 flows through MSW's exact frozen paths and response shapes:

```powershell
npm run test:mocked-flows
```

The debounce test alone uses Vitest fake timers; stale-response correctness uses sequence and exact-snapshot assertions. All other form tests use real timers and user-visible role/name/label/status/focus assertions. No test requires a live Flask or PostgreSQL process.

Coverage for statements, branches, functions, and lines:

```powershell
npm run coverage
```

Review the terminal summary and, when useful, open `coverage/index.html`. Coverage is diagnostic; there is no arbitrary 100% threshold.

## 6. Manual five-route and direct-navigation check

With preview running, visit each URL directly and by primary navigation:

- `http://127.0.0.1:4173/`
- `http://127.0.0.1:4173/menu`
- `http://127.0.0.1:4173/reservations`
- `http://127.0.0.1:4173/about`
- `http://127.0.0.1:4173/gallery`
- `http://127.0.0.1:4173/not-a-page`

Confirm one meaningful H1 and the correct document title on every route, `aria-current="page"` on the active primary link, a friendly not-found page, browser Back/Forward behavior, and a working direct refresh.

Using browser accessibility tools or the accessibility tree, explicitly verify on every route:

- one `header`/banner landmark;
- one labelled `nav` landmark named `Primary` containing the canonical five links;
- one `main` landmark and no duplicate main region;
- one `footer`/contentinfo landmark;
- exactly one meaningful route H1;
- `aria-current="page"` only on the active primary-navigation link.

On Gallery, open the lightbox and confirm it is exposed as a modal dialog named `Enlarged Gallery image`, references useful descriptive content, and retains its keyboard/focus behavior from Section 9. These checks are semantic conformance evidence, not a WCAG certification claim.

## 7. Responsive navigation and accessibility check

At widths below 1024 px, confirm the Menu button starts collapsed, reports `aria-expanded`, opens the canonical five links, and moves focus to Home. Tab and Shift+Tab must follow normal document order. Escape must close and return focus to Menu. Selecting a route must close the disclosure and focus the new H1. At 1024 px and wider, confirm inline navigation and no mobile disclosure.

Use keyboard only to verify the skip link is the first focusable control, all actions have visible teal focus, and no information depends only on hover or color.

Use the browser contrast inspector to spot-check the frozen REACT-03 token pairs in their rendered contexts: white text on wine `#7A2432` and active wine `#5E1724`; teal focus `#0B6E75` against near-white `#FFFCF6`; success `#2F6B4F`, warning `#8A5A00`, and error `#A1262D` against the near-white surface; disabled text `#5B554F` on `#DDD5CA`; espresso `#211A17` on selected `#E6D5B8`; and unavailable text/state treatment on `#E5E1DB`. Confirm state meaning is also conveyed through text, symbols, and native semantics rather than color alone. Record the browser-reported ratios and any defect; do not infer or claim WCAG certification from spot checks.

## 8. Gallery discovery and metadata checks

The automated discovery fixture tests all lower-, upper-, and mixed-case variants of `.webp`, `.jpg`, `.jpeg`, `.png`, and `.avif`; unsupported `.svg` and `.gif`; synthetic no-metadata inclusion; orphan metadata; fallback alt text; duplicate normalized names; and the complete frozen ordering algorithm.

To manually demonstrate add-file discovery without editing a registry, create both the fixture and durable proof that this run owns it:

```powershell
$fixtureRelative = 'assets/gallery/test-auto-discovery.WEBP'
$fixturePath = [IO.Path]::GetFullPath($fixtureRelative)
$fixtureMarker = [IO.Path]::GetFullPath('.tmp-react22-verification/discovery-fixture.json')
if (Test-Path -LiteralPath $fixturePath) { throw 'Discovery fixture path already exists; refusing to overwrite it.' }
git ls-files --error-unmatch -- $fixtureRelative 2>$null
if ($LASTEXITCODE -eq 0) { throw 'Discovery fixture path is tracked; refusing to overwrite a project asset.' }
New-Item -ItemType Directory -Path (Split-Path $fixtureMarker) -Force | Out-Null
Copy-Item -LiteralPath 'assets/gallery/gallery-cafe-interior.webp' -Destination $fixturePath -ErrorAction Stop
$proof = @{ owner = 'CafeFausse-REACT04-discovery-test'; path = $fixturePath; sha256 = (Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash }
[IO.File]::WriteAllText($fixtureMarker, ($proof | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
```

Restart the dev server or rebuild, then confirm the new image appears after metadata-backed images with fallback alt `Test auto discovery`. Leave the proof marker in place until final cleanup removes and verifies the fixture.

Never modify or remove the five project source assets for this test.

## 9. Gallery lightbox check

Open the first, a middle, and the final tile. Confirm focus enters Close; the background is inert; page scrolling is locked; Tab/Shift+Tab remain within the dialog; visible Previous/Next controls are bounded and do not wrap; Left/Right Arrow works; Escape and Close restore the exact opener; captions and position are readable; and the contained image does not crop. The automated suite separately verifies one-image and image-load-failure behavior.

## 10. Reduced motion, zoom, and reflow

In browser developer tools:

1. Emulate `prefers-reduced-motion: reduce` and confirm transitions become immediate.
2. Check `320×568`, `390×844`, `768×1024`, `1280×800`, and `1440×900`.
3. Check 200% and 400% browser zoom; the layout must reflow without horizontal page scrolling.
4. At each size, inspect image crops, logical source order, 44×44 px targets, text wrapping, focus visibility, and the lightbox controls.
5. Where the installed browser/device emulator supports it, check representative phone and tablet layouts in both portrait and landscape orientation and record the actual viewport dimensions.

With reduced motion active, open/close the mobile menu and Gallery lightbox and confirm animation/transition duration is effectively immediate without removing functionality. At both 200% and 400% zoom, repeat navigation, Gallery, lightbox, and Home feature checks; record reflow and any horizontal overflow. These are targeted human checks, not a WCAG certification.

## 11. Manual mocked reservation flow

With the dev server running, open `http://127.0.0.1:5173/reservations`. The default project-owned mock offers the complete contract example schedule only for the exact key `local_date=2026-09-12` plus `party_size=4`; changing either member returns a deterministic empty schedule rather than reusing the example or calculating slots in React.

1. Confirm the initial loading status is replaced by the authoritative mock context, native date `min`/`max`, party maximum, timezone, current policy, and seven hours rows.
2. Enter `2026-09-12` and `4`, activate **Check availability**, and confirm ten slots appear in API order; unavailable entries remain visible and disabled.
3. Select `5:00 PM–6:30 PM`; confirm native checked semantics and visible **Selected** text.
4. Enter fictional values `Ada`, optional `M.`, `Rivera`, `ada.rivera@example.com`, matching confirmation email, and optional `+1 (202) 555-0198`. Wait at least 400 ms and confirm the matched mocked status.
5. Review the returned date/time/party and newsletter action. Activate **Reserve table** once and confirm the pending lock appears before the distinct confirmation view.
6. Confirm the view exposes only the public reference, stored display name, returned restaurant-local interval, returned canonical UTC `starts_at` and `ends_at` instants, party, assigned table numbers, authoritative newsletter state, restaurant contact, and optional safe phone notice. It must not derive/convert these interval values or expose email, phone value, internal IDs, capacity, fingerprint, or delivery claims.
7. Activate **Make another reservation** and confirm a fresh active form. Change date or party after loading a schedule and confirm slots/selection are invalidated while customer details are preserved.

The deterministic Ada fixture matches only case-insensitive full first/last identity for `ada.rivera@example.com`; omitted middle initial is permitted, `M`/`M.` matches, differing first/last returns `customer_identity_conflict`, and another supplied initial returns `middle_initial_conflict`. OP-04 existing-customer true/false always returns `result:"set"`; unknown true returns `set/true`; unknown false returns `no_customer_no_change/false`. OP-05 uses stored fixture spelling and server fixture interval/preference facts: Ada `no_change` preserves subscribed, while subscribe/unsubscribe return their authoritative final Boolean.

For deterministic failure branches, run the focused/MSW tests above. Their injected handlers cover field/code validation invalidation, identity/middle conflicts, overlap, unavailable, explicitly retryable versus non-retryable reads, known temporary failure, confirmation reconstruction, ambiguous outcome, transport ambiguity, and exact-retry recovery. A non-retryable classified read/mutation exposes no identical retry action. Unclassified OP-04/OP-05 transport loss remains conservatively outcome unknown because Prompt 23 has no production dispatch-proof signal; Prompt 24 owns any later transport classification. The default browser mock intentionally provides ordinary fixture flows and does not add URL switches or hidden production behavior solely to force failures.

Client name validation counts the normalized 100-character limit in Unicode code points, not UTF-16 code units; first/last/middle controls therefore omit native `maxLength` where it would reject supplementary-plane letters. Middle initial remains one Unicode letter with optional period. The frozen email profile permits a valid single-label domain such as `ada@localhost`; invalid dot-atom, empty/invalid domain labels, edge hyphens, whitespace, comments, quoted locals, and domain literals remain rejected. The focused validation suite is the deterministic evidence for these boundaries.

## 12. Manual Home newsletter flow

Open `http://127.0.0.1:5173/#newsletter` and confirm this is the only full standalone newsletter form. Use fictional values and matching emails. Confirm untouched fields show no initial errors, blur shows linked field errors, email mismatch reads **Email addresses must match.**, and corrected values revalidate. With `ada.rivera@example.com`, wait 400 ms for a matched subscribed status; with another valid address, confirm not found. Change the checkbox while lookup is pending and confirm the late status never overwrites the deliberate choice.

Save checked and unchecked final states. Confirm pending fields/actions lock and OP-04 success replaces the older OP-03 status copy: matched unsubscribe must show only **Current preference: not subscribed**, not-found subscribe must show only **Current preference: subscribed**, and unchecked unknown identity must show successful **no new customer was created** plus current not-subscribed state. The focused and MSW suites provide restartable known-failure, stale-lookup, conflict, outcome-unknown, and identical-recovery evidence.

## 13. Reservation/newsletter accessibility and responsive checks

At `320×568`, `390×844`, `768×1024`, `1280×800`, and `1440×900`, check both forms for no horizontal page scrolling, date/party reflow, 1/2/3/4 slot columns, identity reflow, readable review/alerts/confirmation, source order, and 44 px controls. At 200% and 400% zoom in a 1280 px browser, repeat the forms and confirm narrow-layout reflow without horizontal page scrolling.

Using keyboard only, complete each form; verify persistent labels and Required/Optional text, native date/number/radio/checkbox semantics, unavailable disabled states, visible focus, error-summary focus and links, selected-slot invalidation focus, polite pending/status announcements, prominent outcome-unknown alert/recovery, and confirmation heading focus. Inspect `aria-invalid`, descriptions, `aria-busy`, alert/status distinctions, and non-color-only state text in browser accessibility tools. This is targeted evidence, not a WCAG certification claim.

## 14. Browser record

Record the actual browser version, OS, tested routes/viewports, result, and defects for Chrome, Edge, and Firefox when installed. Do not claim Safari on Windows. Prompt 22 locally verified Chrome `151.0.7922.170` and Edge `151.0.4129.101`; Firefox was not installed and remains deferred to manual validation in a Firefox-capable environment; Safari remains deferred to manual validation in a Safari-capable environment.

The supported Windows headless/CDP procedure does not require a ChatGPT browser connection or an automation dependency. Use the guarded helper so every run owns an exact profile below `.tmp-react23-verification\browsers\profiles`, verifies its requested CDP port is free, and durably records owner `CafeFausse-REACT05-browser-verification`, schema, browser type, PID, UTC creation time, exact installed executable, exact canonical profile, CDP port, URL, and creation time below `.tmp-react23-verification\browsers\markers` before testing:

```powershell
.\scripts\owned-browser-process.ps1 -Action Start -Browser chrome -CdpPort 9331 -StartUrl 'http://127.0.0.1:5173/reservations' -WindowSize '1280,900'
.\scripts\owned-browser-process.ps1 -Action Status -Browser chrome -CdpPort 9331
# Run CDP/browser-executed JavaScript and close normally through CDP Browser.close.
.\scripts\owned-browser-process.ps1 -Action Stop -Browser chrome -CdpPort 9331
```

Use `-Browser edge` and a different verified-free port for Edge. `Status`, `Stop`, and `Cleanup` consume the durable marker rather than guessing ownership. A live recorded PID is accepted only when creation time, executable, exact profile command-line association, and CDP port association all match. Cleanup also refuses to remove evidence while any process still uses the profile or the recorded CDP port is open. A stale marker for an already-exited owned browser is safe only when no process uses its profile and its port is closed. Malformed, mismatched, missing-field, misplaced-profile, or unclaimed-profile evidence is preserved and fails cleanup for investigation. Never terminate Chrome/Edge from process name, PID alone, or port alone; never remove a generic/user profile.

The independent-review correction pass locally reverified Chrome `151.0.7922.170` at reservation layouts `390×844` and `1280×800`, confirmation widths `320×568`, `390×844`, `768×1024`, `1280×800`, and `1440×900`, Home newsletter at `1280×800`, and a 400%-equivalent 320 CSS px reflow. It exercised exact date+party fixture isolation, matched/no-change booking preference, authoritative standalone unsubscribe, unknown false/no-customer behavior, and local plus canonical confirmation intervals. Edge `151.0.4129.101` repeated the same fixture/confirmation/newsletter smoke at narrow and desktop sizes with no horizontal overflow. Repeat these checks after form/layout changes rather than treating the recorded versions as permanent.

## 15. Guarded interruption recovery and ownership refusal

- After a terminal, browser, or machine interruption, do not stop a PID based only on its number or port. From `frontend/`, run `Status` for the recorded kind, inspect the reported ownership evidence, and then run `Stop`. A valid stale marker is removed without terminating anything. A missing, malformed, mismatched, or incomplete marker is ambiguous and causes the helper to refuse cleanup.
- For an interrupted Prompt-23 browser run, read the browser type/port from the marker filename under `.tmp-react23-verification\browsers\markers`, then run `.\scripts\owned-browser-process.ps1 -Action Status -Browser <chrome|edge> -CdpPort <recorded-port>` followed by guarded `Stop`. If validation fails, preserve the marker/profile and investigate; never delete evidence to make cleanup proceed.
- If a port is occupied with no proven marker, leave that process untouched. Resolve ownership outside this procedure or choose not to run the server; never use `Stop-Process`/`taskkill` by process name, a blanket PID search, or any command that kills all Node, npm, Chrome, or Edge processes.
- If interrupted during a synthetic-asset check, remove only the named `test-auto-discovery.WEBP` fixture.
- Rerun `npm ci`, the relevant focused reservation/newsletter/MSW test, the full suite, and `npm run build`; every command is safe to repeat.
- Do not use `npm update` or edit the lockfile to recover a failed run.

To demonstrate refusal without risking another process, create an intentionally non-owned preview marker that points at the current PowerShell process, verify `Stop` fails, and prove the current shell remains alive:

```powershell
$state = '.tmp-react22-verification\processes'
New-Item -ItemType Directory -Path $state -Force | Out-Null
$fixturePath = Join-Path $state 'preview.json'
if (Test-Path -LiteralPath $fixturePath) { throw 'A preview marker already exists; do not overwrite ownership evidence.' }
$fixture = @{ schema_version = 1; owner = 'NOT-OWNED'; kind = 'preview'; process_id = $PID; start_time_utc = (Get-Process -Id $PID).StartTime.ToUniversalTime().ToString('O'); executable_path = (Get-Process -Id $PID).Path; working_directory = (Get-Location).Path; vite_entry = 'NOT-OWNED'; port = 4173 }
[IO.File]::WriteAllText($fixturePath, ($fixture | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
$refused = $false
try { .\scripts\owned-vite-process.ps1 -Action Stop -Kind preview } catch { $refused = $true }
if (-not $refused) { throw 'Guard failure: the non-owned marker was accepted.' }
if (-not (Get-Process -Id $PID -ErrorAction SilentlyContinue)) { throw 'Guard failure: the non-owned process was terminated.' }
Remove-Item -LiteralPath $fixturePath -Force
```

The final `Remove-Item` is allowed only because this exact procedure created that exact fixture in the current run. Never delete an ambiguous marker of unknown origin merely to make cleanup proceed.

## 16. Final cleanup — always run last

From `frontend/`, run the following as one PowerShell procedure. It stops only processes whose ownership the helper proves, refuses ambiguous ownership, validates a discovery fixture before deleting it, fails on removal errors, verifies generated resources and ports are absent, and protects package/source/Gallery inputs. The final `git status` is deliberately the last repository-state check.

```powershell
$ErrorActionPreference = 'Stop'
$frontendRoot = [IO.Path]::GetFullPath((Get-Location))
$protectedPaths = @('package.json', 'package-lock.json') + @(git ls-files -- 'assets/gallery/*')
$protectedHashes = @{}
foreach ($path in $protectedPaths) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Protected file is missing before cleanup: $path" }
  $protectedHashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}

.\scripts\owned-vite-process.ps1 -Action Cleanup
.\scripts\owned-browser-process.ps1 -Action Cleanup

$browserOwnershipRoot = [IO.Path]::GetFullPath('.tmp-react23-verification/browsers')
if (Test-Path -LiteralPath $browserOwnershipRoot) { throw 'Verified browser ownership cleanup did not complete; preserving Prompt-23 evidence.' }

$fixtureRelative = 'assets/gallery/test-auto-discovery.WEBP'
$fixturePath = [IO.Path]::GetFullPath($fixtureRelative)
$fixtureMarker = [IO.Path]::GetFullPath('.tmp-react22-verification/discovery-fixture.json')
if (Test-Path -LiteralPath $fixturePath) {
  git ls-files --error-unmatch -- $fixtureRelative 2>$null
  if ($LASTEXITCODE -eq 0) { throw 'Refusing to delete a tracked Gallery asset.' }
  if (-not (Test-Path -LiteralPath $fixtureMarker -PathType Leaf)) { throw 'Discovery ownership proof is missing; refusing deletion.' }
  $proof = Get-Content -LiteralPath $fixtureMarker -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($proof.owner -cne 'CafeFausse-REACT04-discovery-test' -or [IO.Path]::GetFullPath([string]$proof.path) -ine $fixturePath) { throw 'Discovery ownership proof is ambiguous; refusing deletion.' }
  if ((Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash -cne [string]$proof.sha256) { throw 'Discovery fixture content changed; refusing deletion.' }
  Remove-Item -LiteralPath $fixturePath -Force -ErrorAction Stop
  if (Test-Path -LiteralPath $fixturePath) { throw 'Discovery fixture removal failed.' }
}

$processState = [IO.Path]::GetFullPath('.tmp-react22-verification/processes')
if (Test-Path -LiteralPath $processState) { throw 'Owned-process markers/logs remain after guarded cleanup.' }

foreach ($relative in @('coverage', 'dist', '.vite')) {
  $target = [IO.Path]::GetFullPath($relative)
  if (-not $target.StartsWith($frontendRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe cleanup target: $target" }
  if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop }
  if (Test-Path -LiteralPath $target) { throw "Generated directory remains after cleanup: $target" }
}

foreach ($relative in @('.tmp-react23-verification', 'mock-reports', 'test-results')) {
  $target = [IO.Path]::GetFullPath($relative)
  if (-not $target.StartsWith($frontendRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe Prompt-23 cleanup target: $target" }
  if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop }
  if (Test-Path -LiteralPath $target) { throw "Prompt-23 generated resource remains after cleanup: $target" }
}

function Test-LocalPortOpen([int]$Port) {
  $client = [Net.Sockets.TcpClient]::new()
  try { $attempt = $client.ConnectAsync('127.0.0.1', $Port); return $attempt.Wait(300) -and $client.Connected }
  catch { return $false }
  finally { $client.Dispose() }
}
foreach ($port in @(5173, 4173)) {
  if (Test-LocalPortOpen $port) { throw "Port $port remains open after owned-process cleanup." }
}

$tempRoot = [IO.Path]::GetFullPath('.tmp-react22-verification')
if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction Stop }
foreach ($relative in @('coverage', 'dist', '.vite', '.tmp-react22-verification', '.tmp-react23-verification', 'mock-reports', 'test-results')) {
  if (Test-Path -LiteralPath $relative) { throw "Cleanup assertion failed; path remains: $relative" }
}
if (Test-Path -LiteralPath $fixtureRelative) { throw 'Cleanup assertion failed; discovery fixture remains.' }
foreach ($path in $protectedPaths) {
  if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $protectedHashes[$path]) { throw "Protected file changed during cleanup: $path" }
}
git status --short
```

The final recursive removals are permitted only after guarded process cleanup succeeds and only for the exact repository-local test-owned directories named by this procedure. If ownership is ambiguous, stop and investigate instead of deleting metadata or terminating a process. Cleanup targets never include `src`, tests, configuration, `package.json`, `package-lock.json`, `node_modules`, committed Gallery assets, or user-owned files. A normal implementation checkout may still show intentional Prompt-23 source/test/document changes; it must show no generated coverage, build, ownership marker/log, screenshot, profile, mock report, or temporary asset output.

## 17. REACT-06 / Prompt-24 live integration workflow

This section is integration-only. It does not authorize production data, a reset endpoint, CORS, a backend/database behavior change, or Prompt 25. Prerequisites are the versions in the backend/database instructions: Windows PowerShell, PostgreSQL 18.3 at `C:\Program Files\PostgreSQL\18`, CPython 3.14.6, the existing `backend\.venv`, Node 24.15.0/npm 11.12.1, locked frontend dependencies, and locally installed Chrome/Edge. Review [backend/TestInstructions.md](../backend/TestInstructions.md) and [database/TestInstructions.md](../database/TestInstructions.md) before operating their privileged test boundaries.

The lifecycle helper uses the already documented backend convention: disposable PostgreSQL `127.0.0.1:55435`, Flask `127.0.0.1:55004`, and Vite `127.0.0.1:5173`. It creates only `cafe_fausse_test_api04`, the application deployment login `cafe_fausse_api04_login`, and test verifier login `cafe_fausse_prompt24_verifier` inside its disposable cluster. Flask runs as the approved `cafe_fausse_app` group role; direct reservation/assignment reads remain denied. Vite receives `CAFE_FAUSSE_FLASK_PROXY_TARGET=http://127.0.0.1:55004` and a task-owned cache directory only in its launcher environment. Browser source still calls relative `/api/...` paths and never sees the Flask target.

Every lifecycle action snapshots the caller process's presence and exact value for `CAFE_FAUSSE_ENVIRONMENT`, `CAFE_FAUSSE_ALLOW_RESET`, `CAFE_FAUSSE_PSQL`, `CAFE_FAUSSE_FLASK_PROXY_TARGET`, `CAFE_FAUSSE_VITE_CACHE_DIR`, `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PGPASSFILE`, and `PGSSLMODE`; clears those inherited values before configuring child tools; and restores the snapshot in `finally`. This applies after success, ordinary failure, guarded startup cleanup, `Stop`/`Cleanup`, `StartFlask`, and `StopFlask`. A previously absent variable is absent again, and a present value is restored byte-for-byte. Prior values, including secrets, are never written to markers, logs, output, reports, or browser configuration.

From the repository root, start in strict order and prove OP-07 through the proxy:

```powershell
& .\frontend\scripts\owned-live-integration.ps1 -Action Start -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\owned-live-integration.ps1 -Action Status -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

`Start` refuses an existing root or occupied PostgreSQL/Flask/Vite port. Its durable temporary marker records the exact repository/root, ports, database, postmaster PID/start/executable, and Vite marker path. Immediately after `Start-Process` succeeds for Flask, it records state `launcher_recorded`, readiness false, and the exact launcher PID/start/executable/command fragment before listener discovery. Once ancestry proves the child listener, the marker advances to `listener_recorded` with listener PID/start/executable/parent and any intermediate launcher chain. Only an explicit direct OP-07 body with `status:"ready"` advances the marker to `ready`; then Vite starts, and only an explicit proxied OP-07 `status:"ready"` permits the final environment-ready message. Listener existence is never readiness.

`Status`, `StopFlask`, `StartFlask`, `Stop`, and `Cleanup` consume that evidence. Launcher-only, later-associated listener, complete pair, and already-exited exact records are handled without PID-, port-, or process-name-only stopping. After PID/start/executable/command/ancestry proof, the helper retains that exact process object's safe handle and terminates only through the same proven object; it never reacquires a process by PID for termination. Exit is accepted through that object, while a missing/invalid handle or changed in-memory start/executable/handle identity refuses termination. Missing required fields, invalid state/readiness combinations, changed PID creation time/executable/command, disconnected ancestry, listener ownership mismatch, multiple listener owners, or a port/listener without the recorded process chain is ambiguous: cleanup refuses, preserves the marker/root, and terminates nothing. The ownership root is removed only after the recorded Flask launcher/listener chain is proven stopped or absent, Vite is proven stopped, PostgreSQL is reset/stopped, and final ports/rows are clear.

Run the deterministic lifecycle guard from a fresh PowerShell process. It statically rejects any PID reacquisition inside `Stop-ProvenProcess` and requires same-object safe-handle termination, then exercises that path through real guarded stops. It also uses sentinel present values plus originally absent variables without printing their values; verifies restoration after every action; uses that existing PowerShell caller as the unrelated-process sentinel without creating or later terminating a disposable process; injects a test-only launcher interruption immediately after durable ownership; proves guarded recovery removes that launcher and root while preserving the caller through its retained process object/handle; rejects direct/proxied listeners whose OP-07 result is not accepted as `ready`; and proves malformed or mismatched evidence refuses all stopping before restoring the exact marker for safe cleanup:

```powershell
& .\frontend\scripts\verify-live-lifecycle-guards.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Run the automated cross-layer verifier. It uses unique fictional `@example.test` identities, the actual Vite proxy, Flask, approved app role, PostgreSQL routines, and privileged verifier role. It covers live current hours plus a restored controlled schedule change; OP-03 not-found/matched/conflicts/read-only behavior; OP-04 create/toggle/same-state/unknown-false plus both identity conflicts with no mutation; ordered free/partial/full availability; OP-05 created/validation/both identity conflicts/overlap/unavailable behavior; assignment integrity; app-role denial; and five representative timing samples per operation (additional OP-03/04 samples arise from state transitions). Its exact-retry sequence creates an OP-05 `subscribe` reservation, changes the authoritative preference to false through ordinary OP-04, resubmits the byte-equivalent original OP-05 snapshot, and proves `200/exact_retry`, the same reference, one logical reservation, no duplicate assignments, and false in both PostgreSQL and the returned confirmation. It does not add an idempotency key or replay the booking-linked newsletter mutation:

```powershell
& .\frontend\scripts\verify-live-integration.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

An ordinary failed verifier is safe to rerun in the same shell or a fresh shell. At entry it deletes only the stable `prompt24-%@example.test` namespace, in foreign-key order, through `cafe_fausse_test`. The final environment cleanup still performs the approved full reset, proves `0|0|0` customers/reservations/assignments, and destroys the disposable cluster. Do not replace this with broad SQL or use the Flask application login for evidence.

For live Chrome and Edge, start exact isolated profiles, run the CDP verifier, and retain both markers until the final browser cleanup:

```powershell
& .\frontend\scripts\owned-browser-process.ps1 -Action Start -Browser chrome -CdpPort 9331 -StartUrl 'http://127.0.0.1:5173/' -WindowSize '1280,900'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
node .\frontend\scripts\verify-live-browser.mjs happy 9331 chrome
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& .\frontend\scripts\owned-browser-process.ps1 -Action Start -Browser edge -CdpPort 9332 -StartUrl 'http://127.0.0.1:5173/' -WindowSize '1280,900'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
node .\frontend\scripts\verify-live-browser.mjs happy 9332 edge
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The browser verifier exercises Home live current hours, Home newsletter subscribe and identity conflict, Reservations context/availability, browser-driven successful reservation and confirmation, PII withholding, and 390 px/desktop horizontal-overflow checks. It adds no browser automation dependency. Safari is not available on Windows and remains deferred to manual validation in a Safari-capable environment; do not claim Safari or final four-browser acceptance.

Exercise a real read transport failure and a conservative mutation-ambiguity UI without claiming the attempted mutation actually reached Flask. `StopFlask` stops only the proven launcher/listener pair; PostgreSQL and Vite remain owned. In this controlled connection-refused case the browser cannot prove dispatch, so the UI conservatively retains and locks the exact snapshot. Restore Flask and explicitly recover:

```powershell
& .\frontend\scripts\owned-live-integration.ps1 -Action StopFlask -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
node .\frontend\scripts\verify-live-browser.mjs failure 9331 chrome
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& .\frontend\scripts\owned-live-integration.ps1 -Action StartFlask -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
node .\frontend\scripts\verify-live-browser.mjs recovery 9331 chrome
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The recovery resends exactly the retained OP-04 body and explicitly retries OP-01. Depending on an actual future ambiguous network break, the mutation recovery may observe a new success or already-current success. This workflow intentionally does not claim a lost post-commit response was induced. Rare API-02 server failure seams not safely available through the frozen live backend remain covered by the exhaustive mocked frontend tests and backend integration tests.

For interruption recovery, rerun `Status`. If the exact marker proves a stale/partial owned environment, use `Cleanup`; if validation fails, preserve the root and investigate. A launcher-only record is recoverable only after exact PID/start/executable/command proof; cleanup waits for a late listener, associates it only through proven ancestry, and stops only the exact chain. A malformed/mismatched launcher or listener record is never guessed around. The lifecycle guard above is the repeatable ownership-refusal, partial-start, already-exited, readiness, restoration, cleanup, and fresh-shell restartability evidence.

Run focused and complete checks after live verification:

```powershell
Set-Location frontend
npm run test:integration
npm run test:reservations
npm run test:newsletter
npm run test:mocked-flows
npm test
npm run coverage
npm run build
npm audit --audit-level=low
Set-Location ..
& .\backend\tests\run_api09.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Record the actual test counts, coverage percentages, build modules, audit result, live timing JSON, browser versions/results, and any unavailable check. Prompt 24 timing is descriptive and does not claim final NFR-01/NFR-02 compliance.

## 18. Prompt-24 final cleanup - always the last live step

Stop browsers before Vite/Flask/PostgreSQL. Every helper refuses ambiguous ownership. The environment stop resets the database, proves zero business rows, stops only recorded processes/listeners, removes its temporary logs/cache/marker/data, and restores the exact caller presence/value for every managed environment variable even when cleanup fails. Ownership evidence is not deleted before ownership is proven, and the final procedure removes every Prompt-24-created database, login/role (with its disposable cluster), process, listener, profile, marker, log, cache, build/coverage output, and temporary root.

```powershell
& .\frontend\scripts\owned-browser-process.ps1 -Action Stop -Browser chrome -CdpPort 9331
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\owned-browser-process.ps1 -Action Stop -Browser edge -CdpPort 9332
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\owned-live-integration.ps1 -Action Stop -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\owned-browser-process.ps1 -Action Cleanup
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\owned-vite-process.ps1 -Action Cleanup
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

After coverage/build evidence is recorded, remove only their exact generated directories and empty helper parents, then prove listeners, the integration root, packages, assets, HEAD, and index state:

```powershell
$ErrorActionPreference = 'Stop'
$repository = [IO.Path]::GetFullPath((Get-Location)).TrimEnd('\')
$frontend = Join-Path $repository 'frontend'
$protected = @('frontend\package.json', 'frontend\package-lock.json') + @(git ls-files -- 'frontend/assets/gallery/*')
$hashes = @{}
foreach ($path in $protected) { $hashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
foreach ($relative in @('coverage', 'dist')) {
    $target = [IO.Path]::GetFullPath((Join-Path $frontend $relative))
    if (-not $target.StartsWith($frontend + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe generated target: $target" }
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
}
foreach ($relative in @('.tmp-react22-verification', '.tmp-react23-verification')) {
    $target = [IO.Path]::GetFullPath((Join-Path $frontend $relative))
    if (Test-Path -LiteralPath $target) {
        if (@(Get-ChildItem -LiteralPath $target -Force).Count -ne 0) { throw "Nonempty helper root remains: $target" }
        Remove-Item -LiteralPath $target -Force
    }
}
function Test-Prompt24Port([int]$Port) {
    $client = [Net.Sockets.TcpClient]::new()
    try { $attempt = $client.ConnectAsync('127.0.0.1', $Port); return $attempt.Wait(300) -and $client.Connected }
    catch { return $false }
    finally { $client.Dispose() }
}
foreach ($port in @(55435, 55004, 5173, 4173, 9331, 9332)) {
    if (Test-Prompt24Port $port) { throw "Prompt-24 listener remains: $port" }
}
$ownedRoot = Join-Path ([IO.Path]::GetTempPath()) 'CafeFausse-prompt24-integration'
if (Test-Path -LiteralPath $ownedRoot) { throw "Prompt-24 integration root remains: $ownedRoot" }
foreach ($path in $protected) {
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $hashes[$path]) { throw "Protected file changed during cleanup: $path" }
}
git diff --check
git diff --cached --name-only
git rev-parse HEAD
git status --short
```

The package lock must match `HEAD`, staged paths must be zero, and HEAD must remain the Phase-0 baseline. If any cleanup proof fails, report the exact remaining resource and do not delete or terminate it by guesswork.

## 19. Prompt-25 full-integration verification

Prompt 25 reuses the exact REACT-06 PostgreSQL, Flask, Vite, browser, verifier-role, ownership, readiness, guarded termination, and cleanup mechanisms from Sections 17-18. It adds no reset endpoint, second server framework, dependency, application privilege, production route, or browser profile convention. Run from the repository root.

Start and validate the frozen owned environment, then run its existing cross-layer verifier:

```powershell
& .\frontend\scripts\owned-live-integration.ps1 -Action Start -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\owned-live-integration.ps1 -Action Status -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\verify-live-integration.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Start a task-owned Chrome profile and run the focused Prompt-25 verifier:

```powershell
& .\frontend\scripts\owned-browser-process.ps1 -Action Start -Browser chrome -CdpPort 9341 -StartUrl 'http://127.0.0.1:5173/' -WindowSize '1280,900'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\verify-full-integration.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION' -Browser chrome -CdpPort 9341
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The focused verifier uses fictional `prompt25-*@example.test` identities and verifies:

- browser newsletter creation, identical duplicate success, client-invalid non-dispatch, API `422 validation_failed`, identity and middle-initial conflicts, one PostgreSQL customer, and authoritative subscribed state;
- React date/policy/party bounds and ordered enabled/disabled slots against the same live OP-01/OP-02 responses;
- a controlled `start_interval_minutes` change through the approved PostgreSQL test writer, visible changed React/Flask behavior without source edits, and exact setting/behavior restoration in `finally`;
- a browser-created reservation whose confirmation reference, customer, newsletter state, reservation, and sorted assigned-table-number set match direct PostgreSQL evidence;
- a different-customer overlapping booking with disjoint assigned tables and a global zero shared-table-overlap invariant;
- a one-minute manipulated slot rejected by Flask as `422 validation_failed` / `invalid_reservation_time` with no customer mutation;
- complete 120-person slot exhaustion, OP-02 all-false behavior, disabled/all-unavailable React behavior, OP-05 `409 reservation_unavailable`, and no failed-attempt customer mutation;
- deterministic post-commit response loss, React's locked unknown-outcome state, an intervening dedicated unsubscribe, exactly two OP-05 attempts with a byte-identical retry body, the authoritative second response's frozen HTTP `200` plus `booking_result: "exact_retry"`, one reservation, and no replay of booking-linked subscribe;
- frozen `StopFlask`/`StartFlask` transport failure and explicit React read/mutation recovery using the existing browser verifier.

Run an Edge live happy-path smoke without duplicating the direct PostgreSQL scenarios:

```powershell
& .\frontend\scripts\owned-browser-process.ps1 -Action Start -Browser edge -CdpPort 9342 -StartUrl 'http://127.0.0.1:5173/' -WindowSize '1280,900'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
node .\frontend\scripts\verify-live-browser.mjs happy 9342 edge-prompt25
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

The SRS browser compatibility requirement remains unchanged. For Prompt-25 automation on the current Windows host, Chrome and Edge are verified. Firefox is not installed, so its automated execution is out of scope here and validation is deferred to manual testing in a Firefox-capable environment. Safari is unavailable on Windows, so validation is deferred to manual testing in a Safari-capable environment. Do not claim four-browser automated verification or describe Firefox or Safari as removed from the SRS requirement.

Before running the lower-layer gates, stop the live environment in dependency order so its dedicated PostgreSQL port is free:

```powershell
& .\frontend\scripts\owned-browser-process.ps1 -Action Stop -Browser chrome -CdpPort 9341
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\owned-browser-process.ps1 -Action Stop -Browser edge -CdpPort 9342
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\frontend\scripts\owned-live-integration.ps1 -Action Stop -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Run the full regression gates. The database programmer harness is the PostgreSQL gate; API-09 is the Flask/API plus application-role PostgreSQL gate; the frontend commands are the React gate:

The database programmer harness must target a separately confirmed nonproduction PostgreSQL 18.3 cluster as required by [database/TestInstructions.md](../database/TestInstructions.md). No approved artifact establishes a required locale or locale provider: the DB-05 report records that its historical verification used ICU, while the Prompt-25 complete programmer gate passed unchanged with PostgreSQL's Windows-default libc provider and `English_United States.1252` collation/character classification. Do not substitute the REACT-06 lifecycle cluster: its frozen `--no-locale` setup selects the `C` locale, whose character classification rejects the frozen DB-05 `É` alphabetic boundary fixture. This evidence introduces no ICU, libc, hard-coded-locale, or locale/provider-preflight requirement; do not weaken the fixture. Supply the database harness's documented port, administrator, and credential source when they differ from its defaults.

```powershell
& .\database\scripts\programmer_test.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& .\backend\tests\run_api09.ps1 -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location frontend
npm run test:integration
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm run test:reservations
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm run test:newsletter
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm run test:mocked-flows
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm run coverage
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm run build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
npm audit --audit-level=low
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location ..
```

If the unchanged API-09 PostgreSQL test `test_free_partial_full_and_back_to_back_occupancy_are_provisional_and_nonmutating_after_cleanup` alone fails with the already-recorded `StopIteration` while locating `full_start_text`, record it separately as the frozen baseline-pre-existing failure. Any other failure, changed test, changed failure mode, or leaked resource requires investigation.

## 20. Prompt-25 final cleanup and absence proof - always the last test step

Run this after recording test, coverage, build, audit, live timing, browser, API-09, and database results. Run it even when any earlier Prompt-25 command fails or is interrupted; after an interruption, open a fresh PowerShell session at the repository root and run the complete block. It first invokes only the frozen guarded ownership helpers: browser cleanup, then the owned PostgreSQL -> Flask -> Vite integration cleanup when its exact ownership root exists, then standalone Vite cleanup. Each helper refuses destructive action when ownership cannot be proven. The block then removes only exact repository-local generated outputs and proves the integration root, browser ownership root, dedicated listeners, generated outputs, package files, Gallery assets, Git index, and repository diff state.

```powershell
$ErrorActionPreference = 'Stop'
$repository = [IO.Path]::GetFullPath((Get-Location)).TrimEnd('\')
$frontend = Join-Path $repository 'frontend'
$protected = @('frontend\package.json', 'frontend\package-lock.json') + @(git ls-files -- 'frontend/assets/gallery/*')
$hashes = @{}
foreach ($path in $protected) { $hashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }

function Test-Prompt25Port([int]$Port) {
    $client = [Net.Sockets.TcpClient]::new()
    try { $attempt = $client.ConnectAsync('127.0.0.1', $Port); return $attempt.Wait(300) -and $client.Connected }
    catch { return $false }
    finally { $client.Dispose() }
}

& .\frontend\scripts\owned-browser-process.ps1 -Action Cleanup
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$ownedRoot = Join-Path ([IO.Path]::GetTempPath()) 'CafeFausse-prompt24-integration'
if (Test-Path -LiteralPath $ownedRoot) {
    & .\frontend\scripts\owned-live-integration.ps1 -Action Cleanup -NonProductionClusterAuthorization 'AUTHORIZED_NONPRODUCTION'
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
elseif ((Test-Prompt25Port 55435) -or (Test-Prompt25Port 55004) -or (Test-Prompt25Port 5173)) {
    throw 'A frozen live-integration listener exists without its exact ownership root; refusing destructive cleanup.'
}

& .\frontend\scripts\owned-vite-process.ps1 -Action Cleanup
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

foreach ($relative in @('coverage', 'dist', '.vite')) {
    $target = [IO.Path]::GetFullPath((Join-Path $frontend $relative))
    if (-not $target.StartsWith($frontend + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "Unsafe generated target: $target" }
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
}
foreach ($relative in @('.tmp-react22-verification', '.tmp-react23-verification', 'mock-reports', 'test-results')) {
    $target = [IO.Path]::GetFullPath((Join-Path $frontend $relative))
    if (Test-Path -LiteralPath $target) {
        if (@(Get-ChildItem -LiteralPath $target -Force).Count -ne 0) { throw "Nonempty helper/generated root remains: $target" }
        Remove-Item -LiteralPath $target -Force
    }
}
foreach ($port in @(55435, 55004, 5173, 4173, 9341, 9342)) {
    if (Test-Prompt25Port $port) { throw "Prompt-25 listener remains: $port" }
}
if (Test-Path -LiteralPath $ownedRoot) { throw "Full-integration ownership root remains: $ownedRoot" }
$browserRoot = Join-Path $frontend '.tmp-react23-verification\browsers'
if (Test-Path -LiteralPath $browserRoot) { throw "Browser ownership/profile root remains: $browserRoot" }
foreach ($relative in @('coverage', 'dist', '.vite', '.tmp-react22-verification', '.tmp-react23-verification', 'mock-reports', 'test-results')) {
    if (Test-Path -LiteralPath (Join-Path $frontend $relative)) { throw "Generated path remains: $relative" }
}
foreach ($path in $protected) {
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $hashes[$path]) { throw "Protected file changed during cleanup: $path" }
}
git diff --check
git diff --cached --name-only
git rev-parse HEAD
git rev-parse origin/main
git status --short
```

The staged-path list must be empty. The only status entries should be the intentional Prompt-25 verification paths. If ownership is ambiguous, stop and preserve the evidence; do not terminate a PID, remove a profile/root, or drop a database by inference.
