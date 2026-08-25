# Café Fausse Frontend Test Instructions

These instructions cover the REACT-04 / Prompt-22 static React application and Gallery increment. They are repeatable after success, failure, or Ctrl+C. Run commands from `frontend/` in PowerShell unless a step says otherwise.

## 1. Prerequisites

- Windows PowerShell 5.1 or PowerShell 7+
- Node.js `v24.15.0`
- npm `11.12.1`
- A current browser for manual checks
- No running process already using ports `5173` or `4173`; the owned-process helper refuses to claim or terminate an existing listener

The selected package engines are satisfied by Node `v24.15.0`. Safari cannot be verified on Windows and remains deferred to the Safari-capable Prompt-25 checkpoint.

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

## 5. Focused and full automated tests

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

## 11. Browser record

Record the actual browser version, OS, tested routes/viewports, result, and defects for Chrome, Edge, and Firefox when installed. Do not claim Safari on Windows. Prompt 22 locally verified Chrome `151.0.7922.170` and Edge `151.0.4129.101`; Firefox was not installed; Safari remains deferred.

## 12. Guarded interruption recovery and ownership refusal

- After a terminal, browser, or machine interruption, do not stop a PID based only on its number or port. From `frontend/`, run `Status` for the recorded kind, inspect the reported ownership evidence, and then run `Stop`. A valid stale marker is removed without terminating anything. A missing, malformed, mismatched, or incomplete marker is ambiguous and causes the helper to refuse cleanup.
- If a port is occupied with no proven marker, leave that process untouched. Resolve ownership outside this procedure or choose not to run the server; never use `Stop-Process`/`taskkill` by process name, a blanket PID search, or any command that kills all Node, npm, Chrome, or Edge processes.
- If interrupted during a synthetic-asset check, remove only the named `test-auto-discovery.WEBP` fixture.
- Rerun `npm ci`, the relevant focused test, and `npm run build`; every command is safe to repeat.
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

## 13. Final cleanup — always run last

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
foreach ($relative in @('coverage', 'dist', '.vite', '.tmp-react22-verification')) {
  if (Test-Path -LiteralPath $relative) { throw "Cleanup assertion failed; path remains: $relative" }
}
if (Test-Path -LiteralPath $fixtureRelative) { throw 'Cleanup assertion failed; discovery fixture remains.' }
foreach ($path in $protectedPaths) {
  if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $protectedHashes[$path]) { throw "Protected file changed during cleanup: $path" }
}
git status --short
```

The final recursive removal is permitted only after guarded process cleanup succeeds and only for the exact repository-local `.tmp-react22-verification` directory owned by this procedure. If ownership is ambiguous, stop and investigate instead of deleting metadata or terminating a process. Cleanup targets never include `src`, tests, configuration, `package.json`, `package-lock.json`, `node_modules`, committed Gallery assets, or user-owned files. A normal implementation checkout may still show the intentional Prompt-22 source/document changes; it must show no generated coverage, build, ownership marker/log, screenshot, profile, or temporary asset output.
