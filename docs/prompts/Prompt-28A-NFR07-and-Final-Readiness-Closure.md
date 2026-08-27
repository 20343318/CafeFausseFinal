# Prompt 28A — NFR-7 and Final-Readiness Closure

Begin **Prompt 28A only** — a narrowly scoped post-Prompt-28 documentation/readiness closure step.

This is **not** a new implementation phase and does **not** change the approved Café Fausse Game Plan, SRS, Rubric, PRA, frozen architecture, API contracts, PostgreSQL schema, Flask behavior, React behavior, dependencies, or tests.

The purpose is to incorporate the newly approved Firefox/Safari manual compatibility results, close NFR-7 truthfully, update final-demo readiness documentation, and produce a final repository-side readiness assessment before the human recording/submission steps.

Do **not** perform Firefox or Safari testing.
Do **not** start the application stack.
Do **not** perform the final recording.
Do **not** perform any external submission action.
Do **not** stage, commit, or push.

---

## 1. Frozen starting checkpoint

The approved repository checkpoint immediately before Prompt 28A is:

`1255fad1316159d79dfb4bd041fc62949fe30ec7`

Commit subject:

`docs(demo): approve Prompt 28 demonstration plan`

At this checkpoint:

- Prompt 26 is approved/frozen;
- Prompt 26A is approved/frozen;
- Prompt 27 is approved and committed;
- Prompt 28 is approved and committed;
- NFR-1 is PASS;
- NFR-2 newsletter is PASS;
- NFR-2 reservation is PASS;
- Chrome is PASS;
- Edge is PASS;
- Firefox and Safari were previously documented as pending;
- the user has now explicitly approved the manual Firefox and Safari test results;
- therefore the authoritative current result for this Prompt 28A is:
  - Chrome: PASS
  - Edge: PASS
  - Firefox: PASS — manual, user-approved
  - Safari: PASS — manual, user-approved
  - NFR-7: CLOSED / satisfied
- no exact Firefox browser version, Safari browser version, operating-system version, device model, or raw manual-test log has been supplied in the current evidence;
- do not invent any of those details.

### Execution-baseline rule

This Prompt-28A prompt file will be committed before Codex executes it.

At execution time:

1. record the full current `HEAD`;
2. record full `origin/main`;
3. require `HEAD == origin/main`;
4. require the real working tree and Git index to be clean;
5. verify current HEAD is a descendant of
   `1255fad1316159d79dfb4bd041fc62949fe30ec7`;
6. verify the committed delta from `1255fad...` to execution HEAD contains only:

   `docs/prompts/Prompt-28A-NFR07-and-Final-Readiness-Closure.md`

If any condition fails, stop with `BLOCKED`.

Treat the resulting clean committed HEAD as the **Prompt-28A execution baseline**.

---

## 2. Authority and precedence

Read and follow, in precedence order:

1. repository-root `AGENTS.md` and applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum v2.2.1;
5. approved Game Plan;
6. approved/frozen PostgreSQL artifacts and PostgreSQL Contract for Flask;
7. approved/frozen API artifacts through API-09;
8. approved/frozen React artifacts through REACT-06;
9. approved/frozen Prompt-25 integration verification;
10. approved/frozen Prompt-26 requirements/rubric audit;
11. approved/frozen Prompt-26A performance verification;
12. approved Prompt-27 `README.md` and `ai-tooling.md`;
13. approved Prompt-28 demonstration plan;
14. the user-approved manual Firefox/Safari result stated in this prompt;
15. actual current repository content;
16. this Prompt 28A.

The SRS and Rubric remain fixed authoritative requirements.

Do not reinterpret or weaken them.

---

## 3. Authorized scope

Prompt 28A may create or modify only these paths:

1. `README.md`
2. `docs/demo/Cafe_Fausse_Prompt28_Demonstration_Plan.md`
3. `docs/browser-verification/Cafe_Fausse_NFR07_Manual_Browser_Verification.md`
4. `docs/final-readiness/Cafe_Fausse_Final_Readiness_Review.md`

Do not modify `ai-tooling.md` unless a real factual contradiction makes it necessary. If so, STOP and report the issue rather than editing it under this prompt.

Do not modify:

- `database/**`;
- `backend/**`;
- `frontend/**`;
- any `TestInstructions.md`;
- SRS;
- Rubric;
- PRA;
- Game Plan;
- Prompt-25 report;
- Prompt-26 audit;
- Prompt-26A artifacts;
- frozen PostgreSQL/API/React artifacts;
- dependency/package/lock files;
- Gallery assets;
- environment/configuration files;
- GitHub settings;
- any external repository.

If a production or test defect is discovered, report it and stop. Do not repair it here.

---

## 4. NFR-7 evidence treatment

The SRS requires compatibility with:

- Chrome;
- Firefox;
- Safari;
- Edge.

The repository already contains approved Chrome and Edge evidence.

The new authoritative manual result is user-approved:

- Firefox: PASS — manual
- Safari: PASS — manual

Treat this as sufficient to close NFR-7 at the project level.

However, maintain evidence quality honestly:

- do not invent exact Firefox/Safari versions;
- do not invent operating systems;
- do not invent device models;
- do not invent timestamps for the actual manual test runs;
- do not invent screenshots, logs, test cases, or team-member names;
- do not claim Codex executed those browsers;
- do not call them automated results.

Use wording such as:

`PASS — manual verification performed outside the Codex Windows environment; result explicitly approved by the user. Exact browser/OS versions were not supplied in the retained project evidence.`

If current repository content contains a more precise user-approved record, use that instead.

---

## 5. Create NFR-7 manual verification record

Create:

`docs/browser-verification/Cafe_Fausse_NFR07_Manual_Browser_Verification.md`

It must include:

- purpose;
- SRS NFR-7 requirement;
- prior state:
  - Chrome PASS
  - Edge PASS
  - Firefox pending
  - Safari pending;
- current state:
  - Chrome PASS
  - Edge PASS
  - Firefox PASS — manual, user-approved
  - Safari PASS — manual, user-approved;
- evidence provenance:
  - Chrome/Edge from existing approved repository verification;
  - Firefox/Safari from user-approved external manual verification;
- explicit statement that Codex did not execute Firefox or Safari;
- explicit statement that exact Firefox/Safari browser/OS versions are not in the retained evidence unless repository evidence proves otherwise;
- conclusion: NFR-7 CLOSED / satisfied;
- no implication that external submission actions are complete.

Do not add unsupported detail merely to make the record look more complete.

---

## 6. Update README browser status only where needed

Inspect current root `README.md`.

Update only statements that are now stale because Firefox/Safari were previously pending.

At minimum ensure the final browser status is truthful:

- Chrome: PASS
- Edge: PASS
- Firefox: PASS — manual
- Safari: PASS — manual
- NFR-7: satisfied/closed

Where useful, link to the new NFR-7 verification record.

Do not rewrite unrelated README sections.

Do not change setup commands, dependencies, architecture, performance figures, database instructions, or test instructions unless a direct stale browser-status reference requires a tiny contextual adjustment.

Do not claim exact Firefox/Safari versions.

---

## 7. Update approved Prompt-28 demonstration plan

Modify:

`docs/demo/Cafe_Fausse_Prompt28_Demonstration_Plan.md`

only where necessary to replace stale pending-browser/readiness text.

Preserve:

- 5–10 minute requirement;
- target timing;
- all timed segments;
- direct PostgreSQL evidence;
- reservation/full scenario;
- responsive demonstration;
- architecture/configuration discussion;
- group identity/speaking requirements;
- external submission handoff requirements;
- safety/repeatability/cleanup instructions.

Update browser status to:

- Chrome: PASS
- Edge: PASS
- Firefox: PASS — manual
- Safari: PASS — manual
- NFR-7: closed

Update the former Firefox/Safari recording-readiness gate so it no longer says those two browser results are pending.

Do **not** automatically mark unrelated human preflight items complete.

The plan must still require, before recording:

- all three group members available;
- cameras/microphones ready;
- IDs ready;
- speaking assignments confirmed;
- demo-safe identities prepared;
- deterministic full/unavailable scenario prepared;
- PostgreSQL queries rehearsed;
- secrets/private data hidden;
- clean/repeatable demo environment;
- expected duration rehearsed within 5–10 minutes.

The browser gate is closed; the human/demo preflight checklist still exists.

---

## 8. Create final readiness review

Create:

`docs/final-readiness/Cafe_Fausse_Final_Readiness_Review.md`

This is the current authoritative repository-side readiness snapshot after Prompt 28A.

It must distinguish among three concepts:

### A. Implementation/SRS readiness

State whether all implementation-side SRS requirements now have approved implementation or verification evidence.

Use the approved/frozen Prompt-26 reconciliation decisions and later closures.

Do not reopen frozen FR-17 or random-table decisions unless current authoritative artifacts actually identify a still-open blocker.

Record:

- NFR-1 PASS;
- NFR-2 PASS;
- NFR-7 CLOSED;
- Chrome/Edge/Firefox/Safari status;
- Prompt 27 documentation complete;
- Prompt 28 demo plan complete.

### B. Recording readiness

Determine whether the **technical/browser gate** is now open.

It should be open if repository inspection finds no other approved technical blocker.

But do not claim the team has already completed human preflight actions that the repository cannot prove.

Use a status such as:

`TECHNICAL RECORDING GATE: OPEN`

while retaining a manual preflight checklist for cameras, IDs, presenters, demo identities, environment startup, rehearsal, and duration.

If repository evidence shows another technical blocker, use `BLOCKED` instead and explain it.

### C. Submission completion

Clearly state that the project is **not yet submitted** and that these rubric actions remain external/manual until the user reports completion:

- record the 5–10 minute presentation;
- all group members visible;
- all group members speak at least once;
- each member states name;
- each member presents government-issued ID as required;
- upload/share recording via Google Drive link using the rubric-prescribed method;
- do not use “Invite People” as the sharing mechanism;
- prepare the required PDF;
- include each group member's GitHub repository link in the PDF;
- ensure each private repository contains required source, README, and `ai-tooling.md`;
- add `quantic-grader` as collaborator to each required private repo;
- complete/sign/upload the required final Group Project Agreement page;
- only one group member submits on behalf of the group.

Do not claim any of these occurred unless evidence exists.

Do not invent the three team-member names or repository URLs.

---

## 9. Final readiness matrix

In the final-readiness review include a compact matrix with at least:

| Area | Requirement/evidence | Current status | Remaining action | Owner/type |

Cover:

- five React pages/navigation;
- newsletter;
- reservation;
- direct PostgreSQL effects;
- Gallery/lightbox;
- responsive design;
- NFR-1;
- NFR-2;
- NFR-7;
- README;
- ai-tooling;
- Prompt-28 demo plan;
- recording;
- group visibility/speaking/ID/name;
- Google Drive link;
- PDF;
- repository link(s);
- `quantic-grader`;
- private repo/source;
- Group Project Agreement;
- one-member submission rule.

Use `Complete`, `Ready`, `Pending manual`, `Pending external`, or similar truthful states.

---

## 10. No live verification in Prompt 28A

Prompt 28A is documentation/readiness closure only.

Do not:

- start PostgreSQL;
- start Flask;
- start Vite;
- start browsers;
- rerun tests;
- rerun performance measurements;
- execute Firefox/Safari;
- install software;
- scale the VM.

Use approved/frozen evidence and static repository inspection only.

If live execution becomes necessary to resolve a genuine contradiction, stop and ask for authorization.

---

## 11. Static consistency audit

Before review, verify:

- no repository document still incorrectly says Firefox is pending;
- no repository document still incorrectly says Safari is pending;
- no repository document still incorrectly says NFR-7 is open because of Firefox/Safari;
- historical/frozen reports may retain their original historical state and must not be edited merely to remove old wording;
- README current-state section is updated;
- Prompt-28 current readiness section is updated;
- new NFR-7 record is internally consistent;
- final-readiness report is internally consistent;
- no exact Firefox/Safari version/OS was invented;
- no final recording is claimed;
- no submission action is claimed;
- no team-member name or repository URL is invented;
- all Markdown links added by this prompt resolve;
- `git diff --check` passes;
- staged count is zero.

When searching for stale `pending` text, distinguish intentionally historical/frozen evidence from current-state documentation.

Do not modify frozen historical artifacts.

---

## 12. Review artifact

Generate ignored review artifact:

`Prompt28A-final-readiness-review-candidate.diff`

relative to the **Prompt-28A execution baseline**.

It may represent only:

- `README.md`
- `docs/demo/Cafe_Fausse_Prompt28_Demonstration_Plan.md`
- `docs/browser-verification/Cafe_Fausse_NFR07_Manual_Browser_Verification.md`
- `docs/final-readiness/Cafe_Fausse_Final_Readiness_Review.md`

Do not include the committed Prompt-28A prompt file inside the review diff.

Do not stage files to generate the diff.

Validate in an isolated temporary clone/worktree without altering the real index.

Report:

- filename;
- byte size;
- SHA-256;
- strict UTF-8 status;
- BOM status;
- represented path count;
- exact path list;
- clean isolated apply result;
- applied-copy byte match result;
- reverse/baseline restoration result;
- `git diff --check` result;
- validation-residue status;
- real staged count;
- complete real working-tree status.

Clean temporary validation resources before stopping.

---

## 13. Git restrictions

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

The user retains Git control.

---

## 14. Final Codex response

Lead with exactly one of:

`READY FOR PROMPT-28A FINAL-READINESS REVIEW`

or

`BLOCKED`

Then report concisely:

- execution baseline HEAD;
- `origin/main`;
- browser matrix;
- NFR-7 conclusion;
- whether exact Firefox/Safari versions/OS are known or intentionally unrecorded;
- README update status;
- Prompt-28 plan update status;
- NFR-7 evidence-record status;
- final-readiness review path;
- implementation/SRS readiness conclusion;
- technical recording-gate conclusion;
- human preflight status;
- external submission status;
- exact remaining external/manual rubric actions;
- exact changed/created paths;
- `git diff --check`;
- staged count;
- complete working-tree status;
- review-diff metadata and validation results.

Explicitly confirm:

- no production source changed;
- no test files changed;
- no `TestInstructions.md` changed;
- no dependency/package/lock file changed;
- no frozen report changed;
- no SRS/Rubric/PRA/Game Plan changed;
- no Gallery asset changed;
- no Firefox/Safari testing occurred;
- no application stack was started;
- no final recording occurred;
- no external submission action occurred;
- nothing was staged, committed, or pushed.

STOP for independent ChatGPT review and explicit user approval.
