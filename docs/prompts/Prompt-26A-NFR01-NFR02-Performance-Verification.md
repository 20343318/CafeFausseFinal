# Prompt 26A — NFR-1 / NFR-2 Performance Verification and VM Sizing Decision Gate

Begin Prompt 26A only.

This is a focused verification increment discovered by the approved Prompt-26
requirements/rubric audit.

Do NOT begin Prompt 27.
Do NOT begin Prompt 28.
Do NOT perform Firefox or Safari validation.
Do NOT scale or reconfigure the VM.
Do NOT modify production application behavior.

============================================================
1. REQUIRED STARTING CHECKPOINT
============================================================

The required committed starting checkpoint is:

aa275b3ac040f8991323ddf975508d84e9a77569

Commit subject:

docs(audit): approve and freeze Prompt 26 requirements traceability

Before doing any work, verify:

- branch is main;
- HEAD equals the full checkpoint above;
- origin/main equals the same checkpoint;
- working tree is clean;
- Git index is clean;
- Prompt 26 is recorded APPROVED AND FROZEN;
- Prompt 27 and Prompt 28 have not begun.

If any of those conditions is false, stop with:

BLOCKED

and report the exact discrepancy.

============================================================
2. PURPOSE
============================================================

Produce quantified full-stack evidence for the two remaining performance
requirements:

SRS NFR-1:
"The website should load within 3 seconds on a standard broadband connection."

SRS NFR-2:
"Form submissions (reservations and email sign-up) should be processed within
2 seconds."

This prompt must determine whether the CURRENT Café Fausse implementation
satisfies those thresholds in the current actual Codex/demo VM before the user
decides whether VM scaling is necessary.

This is verification work.

It is NOT authorization to redesign or optimize the application.

============================================================
3. AUTHORITY
============================================================

Read and follow, in precedence order:

1. repository-root AGENTS.md and any applicable nested AGENTS.md;
2. docs/SRS(1).pdf;
3. docs/Rubric(1).pdf;
4. approved Project Requirements Addendum v2.2.1;
5. approved Game Plan / least-to-most roadmap;
6. approved/frozen PostgreSQL artifacts and PostgreSQL Contract for Flask;
7. approved/frozen API artifacts through API-09;
8. approved/frozen React artifacts through REACT-06;
9. approved/frozen Prompt-25 full-integration verification;
10. approved/frozen Prompt-26 requirements/rubric audit;
11. existing TestInstructions.md files and existing guarded live-integration
    lifecycle helpers.

The SRS and rubric remain the fixed requirements.

Do not reinterpret an existing lower-layer timing result as final NFR-1 or
NFR-2 evidence unless it actually measures the required full-stack behavior.

Existing API/database timings may be used only as supporting diagnostic
evidence.

============================================================
4. USER-APPROVED PERFORMANCE VERIFICATION BASIS
============================================================

The following are approved TEST-METHODOLOGY decisions for this verification
increment.

They are NOT new product/business requirements and must not be added to the
Project Requirements Addendum.

A. Concurrency

Use exactly ONE concurrent user.

The final Café Fausse demonstration has one concurrent user.

Do not invent a multi-user NFR requirement.

Do not run concurrent load testing as part of the NFR-1/NFR-2 acceptance
measurement.

B. Environment

Test the actual current Codex/demo VM first.

Record the actual observed VM configuration rather than merely assuming it.

The expected current configuration is approximately:

- Windows Server 2025;
- 8 logical/assigned processors;
- 16 GB RAM.

If the actual values differ, report the actual values.

Also record at minimum:

- Windows version;
- processor count;
- total physical memory;
- available memory at test start;
- Node.js version;
- npm version;
- Python version;
- PostgreSQL version;
- Chrome version used for quantified browser performance;
- Flask version;
- React/Vite versions where readily available.

C. Network treatment

Do NOT apply artificial network throttling.

Do NOT invent a numerical definition for "standard broadband."

Do NOT select a DevTools "Fast 3G", "Slow 4G", Mbps, latency, or packet-loss
profile.

Use the actual unthrottled network path of the Codex/demo environment and
state that fact explicitly in the evidence.

This is the user-approved operational verification basis because the
authoritative SRS gives no numerical broadband profile.

D. CPU treatment

Do NOT apply artificial CPU throttling.

Do not intentionally run unrelated test suites or CPU-intensive workloads in
parallel with the measurements.

E. VM scaling

Do NOT scale the VM during this prompt.

Do NOT change processor or memory allocation.

The purpose of this first run is to determine whether scaling is needed.

If a threshold is not met, perform only the limited diagnostics authorized
below and stop for user review before any VM change.

============================================================
5. TEST-TOOLING BOUNDARY
============================================================

Prefer the already-approved Prompt-24/Prompt-25 owned live-integration,
browser, process, PostgreSQL, environment-restoration, and cleanup mechanisms.

Do not weaken or duplicate their process-ownership safety rules.

Do not terminate a process based only on PID.

Do not delete a database, directory, profile, or process unless ownership is
proven according to the existing frozen lifecycle rules.

Do not modify frozen lifecycle helpers merely to make this test convenient.

No new npm, Python, browser, system, or PostgreSQL dependency may be added.

No browser installation is authorized.

Use the already-installed Chrome for quantified performance measurement.

Edge performance measurement is optional supporting evidence only; it is not
required for this Prompt-26A performance gate because browser compatibility is
tracked separately under NFR-7.

Firefox and Safari remain outside this prompt.

============================================================
6. AUTHORIZED PROJECT CHANGES
============================================================

Prompt 26A may create/update only narrowly necessary performance-verification
artifacts.

Preferred paths are:

frontend/scripts/verify-nfr-performance.ps1

frontend/scripts/verify-nfr-performance-browser.mjs

frontend/TestInstructions.md

docs/performance-verification/Cafe_Fausse_NFR01_NFR02_Performance_Verification.md

If an existing reusable test script makes one of the new scripts unnecessary,
do not create redundant tooling.

Do not modify:

- database production schema/migrations/routines;
- backend production Python/Flask source;
- frontend production React/JSX/CSS source;
- API contracts;
- PostgreSQL Contract for Flask;
- PRA;
- SRS;
- Rubric;
- frozen design/verification artifacts;
- Prompt-25 report/tooling except by invoking it;
- approved Prompt-26 audit;
- README.md;
- ai-tooling.md;
- package.json;
- package-lock.json;
- Python dependency manifests;
- Gallery assets;
- docs/demo/Cafe_Fausse_FR17_Demo_Queries.md;
- Prompt 27 or Prompt 28 artifacts.

If meaningful production modification appears necessary, STOP and report the
evidence. Do not implement the change.

============================================================
7. SERVER / APPLICATION STATE
============================================================

Use the existing guarded full-stack lifecycle to establish an owned test
environment equivalent to the approved live integration path:

browser -> React/Vite -> Flask -> PostgreSQL

The servers may be started and brought to READY before timing begins.

Server/process/database STARTUP TIME is not part of NFR-1 or NFR-2.

The user-facing application must already be healthy before measured samples
start.

Perform one unmeasured warm-up navigation/request sufficient to verify the
stack is healthy.

Do not use warm-up measurements as passing evidence.

All acceptance samples must then use the methodology below.

============================================================
8. NFR-1 — WEBSITE LOAD MEASUREMENT
============================================================

Measure all five required site routes by direct browser navigation:

- /
- /menu
- /reservations
- /about
- /gallery

Use FIVE measured iterations per route.

Total required NFR-1 measured samples:

25

Run samples sequentially.

Do not parallelize them.

------------------------------------------------------------
8.1 Cache treatment
------------------------------------------------------------

Use a WARM APPLICATION/SERVER but COLD BROWSER CACHE for every measured direct
navigation.

Before each measured navigation:

- clear the browser HTTP cache through the existing browser/CDP mechanism;
- clear ordinary test-owned browser storage where necessary to make the
  navigation repeatable;
- do not restart the application servers merely to manufacture a cold server.

Browser process startup time is excluded.

Server startup time is excluded.

------------------------------------------------------------
8.2 Timing boundary
------------------------------------------------------------

Measure from initiation of the browser navigation until BOTH of these are true:

1. the browser document load event has completed; and
2. the route's primary React content is rendered and visibly usable.

Use a browser monotonic timing source / Navigation Timing / CDP timing rather
than a human stopwatch.

For the reported elapsed value, use the later completion point.

Do not require unrelated user interaction after the page is already usable.

Do not wait for indefinitely deferred/lazy content that is not necessary for
the initially usable page.

Document the exact DOM/readiness condition used for each route.

------------------------------------------------------------
8.3 NFR-1 reporting
------------------------------------------------------------

For each route report:

- five individual elapsed times;
- minimum;
- median;
- maximum.

Also report the global maximum across all 25 samples.

You may report p95 descriptively if the calculation is clearly identified,
but no percentile is an SRS acceptance criterion because the SRS specifies no
percentile.

NFR-1 acceptance for this verification:

PASS only if every ordinary measured NFR-1 sample is <= 3000 ms.

If any ordinary measured sample exceeds 3000 ms:

- do not hide or discard it;
- follow the limited failure-diagnostic procedure below;
- do not declare NFR-1 PASS merely because an average or percentile is below
  three seconds.

============================================================
9. NFR-2 — FULL-STACK FORM-SUBMISSION MEASUREMENT
============================================================

NFR-2 must be measured through the actual browser/UI and actual full stack.

Do not use isolated Flask or PostgreSQL timings as the primary acceptance
measurement.

Measure BOTH:

A. standalone newsletter signup;
B. successful reservation creation.

Use TEN measured successful submissions for each form.

Total required NFR-2 acceptance samples:

20

Run them sequentially with exactly one user.

Do not parallelize them.

Use unique, clearly test-owned identities/data so each ordinary mutation is
valid and deterministic.

Do not expose test PII beyond the normal existing verification conventions.

------------------------------------------------------------
9.1 Newsletter timing boundary
------------------------------------------------------------

Start timing immediately before the actual browser user-action dispatch that
submits the valid newsletter form.

End timing when:

- the authoritative mutation response has completed; AND
- the final user-visible successful newsletter outcome is rendered.

The measured path must therefore include:

React -> Vite/live frontend path -> Flask -> PostgreSQL -> Flask response ->
React final rendered outcome.

Do not stop the timer merely when the HTTP request is sent.

------------------------------------------------------------
9.2 Reservation timing boundary
------------------------------------------------------------

For each reservation sample:

- obtain a server-authoritative valid date/slot through the ordinary UI flow;
- use a valid party size and unique test-owned customer identity;
- complete the form before timing begins.

Start timing immediately before the actual browser user-action dispatch that
submits the reservation.

End timing when:

- the authoritative reservation mutation response has completed; AND
- the final successful reservation confirmation is rendered.

The measured interval must include the actual full-stack reservation mutation
and final React state.

Do not include the user's preceding time spent:

- selecting a date;
- waiting before clicking;
- typing customer information;
- choosing an already-returned slot.

Those are not form-processing time.

Do not replace a normal creation sample with an exact-retry sample.

Exact-retry timings may be recorded descriptively if useful but are not part
of the required ten ordinary successful reservation samples.

------------------------------------------------------------
9.3 NFR-2 reporting
------------------------------------------------------------

For newsletter and reservation separately report:

- ten individual elapsed times;
- minimum;
- median;
- p95, clearly labeled descriptive;
- maximum.

NFR-2 acceptance for this verification:

PASS only if every ordinary measured successful form-submission sample is
<= 2000 ms.

If any ordinary measured sample exceeds 2000 ms:

- do not hide or discard it;
- follow the limited failure-diagnostic procedure;
- do not declare NFR-2 PASS merely because an average or percentile is below
  two seconds.

============================================================
10. ORDINARY-RUN CONDITIONS
============================================================

During measured samples:

- one user only;
- sequential execution only;
- no artificial network throttling;
- no artificial CPU throttling;
- no unrelated project test suite running concurrently;
- no intentional stress/load workload;
- application servers already ready;
- same current VM configuration throughout the run.

Record enough system state to identify obvious environmental interference.

At minimum capture reasonable observations of:

- CPU utilization during the measurement period;
- available/used memory;
- obvious paging/memory pressure if observable without adding tools.

Do not introduce heavy monitoring that materially changes the test.

============================================================
11. FAILURE / OUTLIER PROCEDURE
============================================================

If every sample is within its SRS threshold, do NOT manufacture additional
stress testing.

Record PASS and proceed to cleanup/reporting.

If one or more ordinary samples exceed the relevant threshold:

1. Preserve every original result.
2. Verify there was no accidental parallel test process or leftover
   test-owned workload.
3. Verify the application and database are healthy.
4. Perform ONE diagnostic rerun of only the failing scenario under the same
   approved methodology.
5. Record both the original and diagnostic rerun.

If the diagnostic rerun still materially exceeds the threshold, gather only
lightweight evidence sufficient to distinguish among:

- frontend/browser/resource loading cost;
- Flask/API processing cost;
- PostgreSQL/database allocation cost;
- CPU saturation;
- memory pressure/paging;
- test-environment interference;
- unknown.

Use existing browser/network timing, existing logs, existing lower-layer
performance evidence, and operating-system observations where practical.

Do NOT:

- change production source;
- change database algorithms;
- change transaction/concurrency semantics;
- change timeouts merely to make a result pass;
- disable correctness checks;
- change cache policy;
- add dependencies;
- scale the VM.

============================================================
12. VM-SCALING DECISION OUTPUT
============================================================

The report must make one of these evidence-based conclusions:

A. NO VM SCALING INDICATED

Use when NFR-1 and NFR-2 both pass on the current VM.

B. VM SCALING MAY BE WORTH TESTING

Use only when a persistent threshold failure is accompanied by credible
evidence of CPU or memory resource pressure.

Do not guess the exact amount of CPU/RAM needed.

State that VM sizing requires a separate user-approved rerun.

C. VM SCALING IS NOT THE FIRST INDICATED ACTION

Use when the evidence points primarily to application/database/frontend/test
behavior rather than machine resource pressure.

D. INCONCLUSIVE

Use when the available evidence cannot reasonably distinguish the cause.

Do NOT modify the VM during this prompt.

The user will decide separately whether to test a larger VM.

============================================================
13. EXISTING PERFORMANCE EVIDENCE
============================================================

Read and reconcile prior evidence, including at minimum:

- DB-07 performance evidence;
- API-09 performance evidence;
- REACT-06 cross-layer timing evidence;
- Prompt-25 full-stack timing evidence;
- Prompt-26 audit conclusions.

Prior evidence may support diagnosis and consistency checking.

It does NOT replace the new measurements.

In particular:

- isolated database/API timing does not establish NFR-1;
- isolated database/API timing does not by itself establish full browser
  NFR-2;
- prior descriptive timings must not be silently promoted into final
  compliance evidence.

If a new measurement materially conflicts with old evidence, report the
difference rather than selecting whichever result looks better.

============================================================
14. REPEATABILITY / TestInstructions.md
============================================================

Update frontend/TestInstructions.md with a clearly identified Prompt-26A
performance-verification section.

It must be usable by a repository contributor and be:

- repeatable;
- restartable;
- safe after ordinary failure;
- safe after interrupted execution;
- explicit about required environment;
- explicit about the one-user/no-throttling methodology;
- explicit about NFR-1 timing;
- explicit about NFR-2 timing;
- explicit about result locations;
- explicit about final cleanup.

The final step of the instructions must remove ALL test-owned resources
created by Prompt 26A, including as applicable:

- disposable database/cluster resources;
- test-owned reservation/customer/newsletter rows;
- owned Flask/Vite processes;
- owned browser process/profile;
- temporary timing/result files;
- generated build/cache/test artifacts not intentionally retained;
- temporary environment-variable changes;
- temporary directories.

The cleanup must NOT remove:

- source files;
- committed documentation;
- committed Gallery assets;
- user files;
- unrelated databases;
- unrelated processes;
- ambiguous resources.

After cleanup verify absence of Prompt-26A-owned resources.

Use existing ownership proofs and cleanup helpers wherever possible.

============================================================
15. REQUIRED VERIFICATION REPORT
============================================================

Create:

docs/performance-verification/Cafe_Fausse_NFR01_NFR02_Performance_Verification.md

Mark it initially:

PROPOSED — NOT YET APPROVED

Include at minimum:

1. baseline full commit;
2. authority;
3. scope and exclusions;
4. exact SRS NFR-1 and NFR-2 obligations;
5. explanation that test-methodology decisions are verification protocol, not
   supplemental product requirements;
6. actual VM hardware;
7. actual software/browser/database versions;
8. network/no-throttling basis;
9. CPU/no-throttling basis;
10. one-concurrent-user basis;
11. server warm-up procedure;
12. NFR-1 cache methodology;
13. NFR-1 timing boundary;
14. all 25 NFR-1 individual measurements;
15. route min/median/max;
16. global NFR-1 maximum;
17. NFR-1 conclusion;
18. NFR-2 timing boundary;
19. all 10 newsletter measurements;
20. newsletter min/median/p95/max;
21. all 10 reservation measurements;
22. reservation min/median/p95/max;
23. NFR-2 conclusion;
24. any threshold failures/outliers;
25. diagnostic rerun evidence if applicable;
26. system CPU/memory observations;
27. comparison with DB-07/API-09/REACT-06/Prompt-25 timing evidence;
28. VM-scaling conclusion;
29. exact test tooling created/changed;
30. TestInstructions.md update;
31. cleanup result;
32. Firefox/Safari explicitly deferred and untouched;
33. Prompt-26 audit remains frozen and untouched;
34. Prompt-27 readiness implications;
35. explicit approval checkpoint.

Do not mark this report approved.

============================================================
16. NFR STATUS RULES
============================================================

Do not change the frozen Prompt-26 audit during this prompt.

Instead, the new performance report supplies later evidence.

If NFR-1 passes under this approved verification protocol, report:

NFR-1 PERFORMANCE EVIDENCE: PASS

If it does not, report:

NFR-1 PERFORMANCE EVIDENCE: FAIL

or:

INCONCLUSIVE

as supported by the measurements.

Do the same separately for NFR-2.

Do not claim NFR-7 completion.

Firefox and Safari remain pending manual user verification.

============================================================
17. PROMPT-27 READINESS
============================================================

Do not begin Prompt 27.

At the end report whether the PERFORMANCE portion of the pre-Prompt-27 gate is:

- CLOSED;
- PARTIALLY CLOSED;
- or OPEN.

Do not claim the entire Prompt-27 gate is closed while Firefox/Safari manual
verification remains pending unless the approved workflow explicitly permits
that later deferral.

Keep the browser-verification status factually separate from NFR-1/NFR-2.

============================================================
18. GIT RESTRICTIONS
============================================================

Do not:

- stage;
- commit;
- push;
- reset;
- clean;
- stash;
- rebase;
- merge;
- cherry-pick;
- switch branches;
- create/delete tags.

Preserve the real Git index.

Leave all Prompt-26A project changes unstaged for independent review.

The repository ignores *.diff files; do not force-add a review diff.

============================================================
19. FINAL VERIFICATION
============================================================

Before stopping:

1. verify all required NFR-1 samples were captured;
2. verify all required NFR-2 samples were captured;
3. verify measurements used the approved one-user/no-throttling basis;
4. verify no VM scaling occurred;
5. verify no Firefox/Safari testing occurred;
6. verify no production source changed;
7. verify no dependency/package/lockfile changed;
8. verify Prompt-26 audit remained untouched;
9. verify Prompt 27 and Prompt 28 did not begin;
10. execute the updated Prompt-26A TestInstructions sufficiently to demonstrate
    repeatability/restartability;
11. run final guarded cleanup;
12. verify all Prompt-26A-owned resources are gone;
13. verify intentional performance-verification documentation/test tooling
    remains;
14. run git diff --check;
15. verify staged count is zero;
16. report complete git status.

============================================================
20. INDEPENDENT REVIEW ARTIFACT
============================================================

Generate an ignored review artifact:

Prompt26A-performance-review-candidate.diff

It must represent the complete Prompt-26A project delta relative to:

aa275b3ac040f8991323ddf975508d84e9a77569

It may represent only the authorized Prompt-26A paths actually required.

Do not include the .diff file inside itself.

Do not stage files to generate it.

Validate it using an isolated temporary clone/worktree mechanism that does
not alter the real index.

Report:

- filename;
- byte size;
- SHA-256;
- strict UTF-8 status;
- BOM status;
- represented path count;
- exact represented paths;
- clean isolated apply result;
- applied-copy byte match result;
- reverse/baseline restoration result;
- git diff --check result;
- validation-residue result;
- staged count.

Temporary validation resources must be removed before stopping.

============================================================
21. FINAL CODEX RESPONSE
============================================================

Lead with exactly one of:

READY FOR PROMPT-26A PERFORMANCE REVIEW

BLOCKED

Then report concisely:

- baseline HEAD;
- origin/main;
- actual VM CPU/RAM configuration;
- actual relevant software/browser versions;
- NFR-1 result;
- NFR-1 worst measured time and route;
- NFR-2 newsletter result and worst time;
- NFR-2 reservation result and worst time;
- any diagnostic rerun;
- CPU/memory observations;
- VM-scaling conclusion;
- exact changed/created paths;
- TestInstructions status;
- cleanup status;
- Firefox/Safari status;
- Prompt-26 frozen-artifact preservation;
- Prompt-27 readiness;
- staged count;
- complete working-tree status;
- review-diff byte size and SHA-256.

Do not stage, commit, or push.

Do not scale the VM.

Do not modify production behavior.

Do not begin Prompt 27.

Do not begin Prompt 28.

STOP for independent ChatGPT review.
