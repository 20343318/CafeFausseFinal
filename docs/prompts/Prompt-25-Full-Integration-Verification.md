# Prompt 25 — Full End-to-End Integration Verification

Begin Prompt 25 — full end-to-end integration verification only.

The frozen starting checkpoint is:

`acd419a8942a10a1d646847a94b5a05aedad6841`

REACT-06 / Prompt 24 is APPROVED AND FROZEN.

Continue treating the Café Fausse SRS, rubric, approved Project Requirements Addendum, frozen PostgreSQL contracts, frozen Flask/API contracts, frozen REACT-01 through REACT-06 artifacts, and approved INT-01 integration strategy as authoritative.

Do not introduce or silently infer a supplemental requirement.

Do not redesign frozen contracts merely because another implementation appears preferable.

## Objective

Perform the Prompt-25 end-to-end verification required by the approved roadmap using the complete application:

PostgreSQL → Flask → React

Use the existing approved test infrastructure and REACT-06 owned lifecycle/browser verification mechanisms wherever applicable. Do not create a competing integration framework unless an actual blocker makes the frozen mechanism unusable.

Verify at minimum:

1. A valid newsletter signup through the React UI reaches PostgreSQL with the expected customer/newsletter state.
2. Duplicate and invalid newsletter behavior matches the frozen Flask/API contract and produces the expected user-facing behavior.
3. Reservation dates and slots exposed through React reflect the server-authoritative approved configuration and restaurant rules.
4. Changing an approved configurable reservation setting changes application behavior without source-code modification, then restoring the setting restores the original behavior.
5. A valid reservation submitted through React reaches PostgreSQL with the correct customer, reservation, and table-assignment effects.
6. The resulting reservation prevents prohibited overlapping use of its assigned table according to the frozen database/API rules.
7. Fully booked conditions produce the frozen API behavior and appropriate React behavior.
8. An invalid or manipulated reservation slot submitted outside normal React controls is rejected by Flask, proving that React is not the integrity boundary.
9. Required customer-identity and middle-initial conflict behavior remains consistent end to end.
10. Exact reservation retry behavior remains idempotent and does not replay the booking-linked newsletter action.
11. Controlled transport failure and recovery produce the expected React failure/recovery states.
12. PostgreSQL effects are verified directly where persistence or non-mutation is part of the expected outcome.

## Regression verification

Run the appropriate existing automated suites and focused live integration checks for:

- PostgreSQL;
- Flask/API;
- React;
- live React → Flask → PostgreSQL integration.

Do not require unrelated duplication of tests already conclusively covered by frozen lower-layer gates; reuse their suites and add only the focused Prompt-25 scenarios needed to establish end-to-end behavior.

The unchanged API-09 PostgreSQL test:

`test_free_partial_full_and_back_to_back_occupancy_are_provisional_and_nonmutating_after_cleanup`

has already been independently shown to fail at the frozen pre-REACT-06 baseline with the same `StopIteration` failure mode. If that exact unchanged failure recurs, report it as the known baseline-pre-existing failure rather than treating it as a Prompt-25 regression. Any different failure requires investigation.

## Environment ownership and cleanup

Preserve the frozen REACT-06 lifecycle requirements.

Any disposable PostgreSQL, Flask, Vite, or browser process/resource created during Prompt-25 verification must use the approved ownership, readiness, exact-process termination, refusal-on-ambiguous-ownership, and cleanup mechanisms.

Do not terminate unrelated processes or use PID-only ownership.

Testing must be restartable.

Update the applicable `TestInstructions.md` only where Prompt 25 adds or changes repeatable verification instructions. Its final test step must remove all objects, files, databases, processes, profiles, listeners, and other disposable resources created by the verification.

## Failure handling

This prompt is a verification gate first.

If any Prompt-25 scenario fails:

1. capture the exact failure;
2. classify the earliest affected architectural layer;
3. determine whether the behavior violates a frozen requirement/contract or exposes an actual implementation defect;
4. report the proposed smallest correction and its impact.

Do not make an architectural change or alter a frozen contract without stopping for approval.

You may correct a narrowly scoped implementation/test defect only when the correction unquestionably restores an existing frozen requirement without changing its meaning. If there is any ambiguity, stop and ask for approval.

Do not add optional features or begin Prompt 26.

## Scope protection

Do not implement cancellation, modification, rescheduling, table-selection UI, administrative functionality, or other functionality outside the approved project scope.

Do not alter dependencies or `frontend/package-lock.json` unless an actual Prompt-25 blocker requires it and approval is obtained first.

Do not stage, commit, or push.

## Deliverables

At completion report:

- all Prompt-25 scenarios executed;
- pass/fail result for each;
- PostgreSQL evidence for required persistence/non-mutation cases;
- automated suite results;
- browser/live-integration results;
- any known baseline-pre-existing failure separately from Prompt-25 regressions;
- any defects found and corrections made;
- exact changed-path inventory;
- confirmation that frozen contracts were not changed;
- `git diff --check`;
- staged-path count;
- HEAD and `origin/main`;
- cleanup results;
- confirmation that Prompt 26 has not begun.

Keep Prompt 25 status:

PROPOSED — NOT YET APPROVED

Stop after reporting the implementation/verification results for independent review.
