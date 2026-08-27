# Prompt 28 — Final Demonstration Plan

Begin **Prompt 28 only** — the final demonstration-planning phase from the approved Café Fausse Game Plan.

Do **not** perform the final recording.
Do **not** perform final submission actions.
Do **not** perform Firefox or Safari compatibility testing.
Do **not** modify production application behavior.
Do **not** modify database, Flask, React, dependency, configuration, or frozen verification artifacts.

The approved Game Plan requires Prompt 28 to create a **5–10 minute demonstration plan** that proves compliance with the rubric and specifies exactly what should be shown in the browser, application/Flask environment, and PostgreSQL.

---

## 1. Frozen pre-Prompt-28 checkpoint

The approved project checkpoint immediately before creation of this Prompt-28 prompt file is:

`55075fcf501a2e23651e2645a3260b9854af0b64`

Commit subject:

`docs: complete and approve Prompt 27 project documentation`

At that checkpoint:

- Prompt 26 is **APPROVED AND FROZEN**;
- Prompt 26A is **APPROVED AND FROZEN**;
- Prompt 27 is **APPROVED** and committed;
- NFR-1 performance evidence is **PASS**;
- NFR-2 newsletter performance evidence is **PASS**;
- NFR-2 reservation performance evidence is **PASS**;
- VM conclusion is **NO VM SCALING INDICATED**;
- Chrome verification is **PASS**;
- Edge verification is **PASS**;
- Firefox manual verification is still pending;
- Safari manual verification is still pending;
- NFR-7 is therefore not yet fully closed;
- final demo recording has not occurred;
- final submission actions have not occurred.

### Execution-baseline rule

This Prompt-28 file will be committed before Codex executes it.

Therefore, do **not** require execution HEAD to equal `55075fc...`.

At execution time:

1. record the full current `HEAD`;
2. record full `origin/main`;
3. require `HEAD == origin/main`;
4. require the working tree and Git index to be clean;
5. verify current HEAD is a descendant of
   `55075fcf501a2e23651e2645a3260b9854af0b64`;
6. verify the committed delta from `55075fc...` to current HEAD contains only the committed Prompt-28 prompt artifact:

   `docs/prompts/Prompt-28-Final-Demonstration-Plan.md`

If those conditions are not true, stop with `BLOCKED` and report the discrepancy.

Treat the current clean committed HEAD that passes those checks as the
**Prompt-28 execution baseline**.

Use that execution baseline for the Prompt-28 review diff so the already committed Prompt-28 prompt file does not appear in its own review delta.

---

## 2. Authority and precedence

Use the current committed repository as the authoritative implementation and evidence state.

Read and follow, in precedence order:

1. repository-root `AGENTS.md` and applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum v2.2.1;
5. approved Game Plan / least-to-most roadmap;
6. approved/frozen PostgreSQL artifacts and PostgreSQL Contract for Flask;
7. approved/frozen API artifacts through API-09;
8. approved/frozen React artifacts through REACT-06;
9. approved/frozen Prompt-25 full-integration verification;
10. approved/frozen Prompt-26 requirements/rubric audit;
11. approved/frozen Prompt-26A NFR-1/NFR-2 performance verification;
12. approved Prompt-27 `README.md` and `ai-tooling.md`;
13. existing `database/TestInstructions.md`, `backend/TestInstructions.md`, and `frontend/TestInstructions.md`;
14. existing demo-support documentation, including
    `docs/demo/Cafe_Fausse_FR17_Demo_Queries.md` if present;
15. actual current source code, scripts, configuration, and database schema;
16. this Prompt 28.

The SRS and rubric remain fixed authoritative requirements.

Do not invent functionality, commands, configuration, database fields, test results, browser results, presenter identities, repository links, asset licensing facts, or submission completion.

---

## 3. Prompt-28 scope

Prompt 28 may create only:

`docs/demo/Cafe_Fausse_Prompt28_Demonstration_Plan.md`

Do not create additional scripts, SQL files, screenshots, videos, PDFs, slide decks, staging files, test harnesses, or submission artifacts.

Do not modify:

- `README.md`;
- `ai-tooling.md`;
- `database/**`;
- `backend/**`;
- `frontend/**`;
- any `TestInstructions.md`;
- SRS;
- Rubric;
- PRA;
- Game Plan;
- Prompt-25 artifacts;
- Prompt-26 audit;
- Prompt-26A artifacts;
- Gallery assets;
- dependency manifests or lockfiles;
- environment/configuration files;
- GitHub settings or external repositories.

This is a **demonstration-planning documentation increment**, not an implementation increment.

If preparing the demonstration uncovers a real defect or missing required capability, record it as a blocker and stop. Do not repair it under Prompt 28.

---

## 4. Rubric presentation obligations that the plan must cover

The final demonstration plan must reflect the actual rubric requirements, including:

- recording duration around **5–10 minutes**;
- presenter(s) visible on-screen while the screen demonstration is recorded;
- each required site page and navigation between them;
- newsletter email signup;
- correctly functioning reservation system;
- **actual effects of newsletter signup and reservation operations on the backend PostgreSQL database**;
- database effects shown directly in PostgreSQL, **not merely through a site administration page**;
- discussion of implementation decisions;
- presenter identity/name obligations;
- group presentation obligations when applicable.

The project is a group project with three members.

Do not invent the three names.

Use explicit editable placeholders such as:

- `TEAM_MEMBER_1`
- `TEAM_MEMBER_2`
- `TEAM_MEMBER_3`

The final plan must remind the team that:

- all group members must be visibly present during the recording;
- all members must speak at least once;
- each group member must present a government-issued ID to the camera with name and picture clearly visible/legible;
- each group member must state their name;
- only one member ultimately submits the group project.

Do not perform or claim those actions in Prompt 28.

---

## 5. Firefox/Safari deferral and recording-readiness gate

The user explicitly authorized Prompt 27 and Prompt 28 planning to proceed while Firefox and Safari manual compatibility evidence is being gathered by team members.

This remains a **workflow deferral**, not a waiver of SRS NFR-7.

The Prompt-28 plan must state the current evidence truthfully:

- Chrome: PASS
- Edge: PASS
- Firefox: pending manual verification
- Safari: pending manual verification
- NFR-7: not yet fully closed

The plan may be prepared now.

However, the plan must include a **final recording readiness gate**:

> Do not treat the project as fully SRS-ready for the final submission recording until the pending Firefox and Safari results have been received and reviewed. If either browser reveals a material SRS defect, stop final recording/submission and correct/reverify the defect first.

Do not perform Firefox or Safari testing during Prompt 28.

Do not state that all SRS requirements are fully verified while those results remain pending.

---

## 6. Mandatory read-only repository inspection

Before writing the demo plan, inspect enough of the current repository to make every demo instruction executable and truthful.

At minimum inspect:

- root `README.md`;
- root `ai-tooling.md`;
- Prompt-25 full-integration report;
- Prompt-26 traceability audit;
- Prompt-26A performance report;
- current PostgreSQL schema/migrations relevant to customers, newsletter state, reservations, reservation-to-table assignments, restaurant configuration, and table configuration;
- current Flask startup/configuration documentation;
- current React/Vite startup/configuration documentation;
- existing guarded live-integration/lifecycle helpers;
- existing `TestInstructions.md` files;
- current five React routes/pages;
- current newsletter and reservation form behavior;
- current Gallery/lightbox behavior;
- current responsive verification evidence;
- `docs/demo/Cafe_Fausse_FR17_Demo_Queries.md` if present;
- exact local ports/URLs used by the current project;
- exact safe database query/connection commands suitable for a human demo;
- exact safe cleanup/reset approach for demo-created data, if one exists.

Use read-only/static inspection.

Do not start PostgreSQL, Flask, Vite, or a browser merely to create the plan.

If an exact command cannot be established without live execution, document the uncertainty and stop rather than inventing the command.

---

# PART A — DEMONSTRATION STRUCTURE

## 7. Target duration and pacing

Create a timed demonstration plan targeting approximately **8 minutes**, while remaining comfortably within the rubric's 5–10 minute range.

The plan must contain:

- an estimated time for every segment;
- cumulative elapsed time;
- presenter assignment placeholder;
- what appears on screen;
- what the presenter says;
- what evidence the segment proves;
- corresponding rubric/SRS evidence mapping.

Build in a small buffer so normal navigation or speaking delays do not push the demo over 10 minutes.

Do not create an artificially dense script that requires rushed narration.

---

## 8. Presenter/team opening

Include a short opening that satisfies the group recording obligations without consuming excessive demo time.

Use placeholders for each team member.

Specify:

- all three cameras visible;
- each member briefly states name;
- each member shows government-issued ID clearly enough to satisfy the rubric;
- each member speaks at least once during the overall presentation;
- one member introduces Café Fausse and the stack:
  `React/JSX → Flask/Python → PostgreSQL`.

Do not put real ID numbers, birth dates, addresses, or other sensitive ID data into the written plan.

The plan should tell presenters to show only what the rubric requires to the camera.

---

## 9. Required browser demonstration

The browser portion must explicitly show all required pages and important functionality.

At minimum include:

### Home

Show:

- Café Fausse landing page;
- shared navigation;
- responsive/visual quality;
- required restaurant information visible in the implemented page.

### Menu

Show:

- Menu route/page;
- representative category/content;
- navigation continuing to work.

Do not read every menu item aloud.

### About Us

Show:

- About Us route/page;
- representative required history/founder/mission/dining content.

### Gallery

Show:

- Gallery route/page;
- responsive image grid;
- required Gallery content;
- click/open one image in the lightbox;
- demonstrate at least one meaningful lightbox interaction such as next/previous and/or close;
- return cleanly to page.

### Reservations

Show the complete real workflow:

1. choose an allowed date;
2. retrieve/display server-authoritative slots;
3. show selectable availability;
4. select a slot;
5. enter valid customer/party information;
6. submit;
7. show successful confirmation;
8. preserve the confirmation/reservation identifier needed to correlate the PostgreSQL query.

Also demonstrate **unavailable/full behavior** without wasting time or corrupting persistent state.

Use the safest existing proven mechanism from current project evidence.

If the most reliable rubric-proof method is a preconditioned demo slot/database state established before recording, document exactly how to prepare it.

Do not invent a new application feature solely to make the demo easier.

Do not alter production source code to stage the demonstration.

### Newsletter signup

Show:

1. real newsletter form;
2. valid name/email entry;
3. successful submission state;
4. value needed to correlate the PostgreSQL row/state.

Use a unique demo-safe email that can be identified in PostgreSQL.

The written plan may use a pattern such as an editable placeholder, but do not hard-code a real team member's personal email.

---

# PART B — DIRECT POSTGRESQL EVIDENCE

## 10. Direct database proof is mandatory

The rubric explicitly requires showing the effect of reservation and newsletter operations **on the database itself**, not through an application admin screen.

The plan must provide exact, repository-correct PostgreSQL commands/queries for the human presenter to show.

The database segment must demonstrate at minimum:

### Newsletter effect

Using the email submitted in the browser, query the actual customer/newsletter state and show that PostgreSQL persisted the signup.

Use the actual schema/column names.

Do not invent a separate newsletter table if the implementation stores newsletter state on the customer record.

### Reservation effect

Using the just-created reservation/customer identifiers or email plus reservation facts, query PostgreSQL and show:

- reservation row;
- associated customer;
- selected date/time;
- party size where actually stored;
- table assignment.

If the authoritative implementation uses normalized
`reservation_table_assignments`, show that normalized relation directly.

Also show a compact joined/aggregated query that makes the assigned table number(s) easy for a grader to understand.

Reuse the existing approved FR-17 demo query documentation where appropriate rather than creating contradictory SQL.

### Correlation

The demo script must tell the presenter how to correlate what the browser showed with the exact PostgreSQL rows.

Avoid ambiguous queries such as "latest row" when a unique email, reservation ID, confirmation identifier, or other deterministic key is available.

---

## 11. Database before/after evidence

Design the shortest convincing proof.

Where practical, show:

1. a concise pre-operation query proving the unique demo email/reservation does not yet exist;
2. perform the browser operation;
3. rerun the query and show the new/updated persisted state.

If the implemented newsletter behavior updates an existing customer rather than inserts a new one, tailor the before/after query accordingly.

Do not claim an insert if the actual operation is an update.

The written plan must explain the expected database effect for both the "new person" and "existing customer preference" possibilities only if both are relevant to the chosen demo data.

Prefer a deterministic **new demo identity** unless repository rules make another path safer.

---

# PART C — UNAVAILABLE/FULL RESERVATION BEHAVIOR

## 12. Demonstrate fully booked/unavailable behavior safely

The Game Plan requires Prompt 28 to include unavailable/full behavior.

The demo plan must establish a deterministic way to show it.

Inspect existing Prompt-25/full-integration evidence and helper capabilities.

Prefer, in order:

1. an existing safe demo/test preparation mechanism that can place one target slot into a fully booked state;
2. an already documented controlled nonproduction preparation/reset process;
3. a pre-recording setup step performed against an explicitly disposable/local demo database.

Do **not** recommend manually corrupting or bypassing application constraints.

Do **not** use destructive SQL against an ambiguous or production database.

The actual browser demonstration should show that a full/unavailable slot is either:

- rendered non-clickable/unavailable as implemented; or
- produces the correct user-facing requirement-compliant behavior when the server reports it unavailable.

Flask/server authority must remain intact.

The plan must include how the demo environment is restored/cleaned afterward.

---

# PART D — RESPONSIVE / ARCHITECTURE / CONFIGURABILITY

## 13. Responsive design evidence

The final plan must show responsive design without spending too much time.

Use the current verified browser/developer-tool approach.

Demonstrate at least:

- normal desktop layout;
- one mobile or narrow viewport state;
- responsive navigation/layout behavior;
- a page where Grid/Flexbox adaptation is obvious.

The rubric mentions mobile-emulator testing as an option, not a mandatory specific tool.

Do not claim Firefox/Safari verification from a Chrome emulator.

---

## 14. Key implementation decisions

Include a short architecture/business-rule segment.

Explain only actual approved decisions.

At minimum cover:

- PostgreSQL → Flask → React separation of responsibility;
- PostgreSQL-backed configurable restaurant/business rules;
- Flask as server-authoritative validator/orchestrator;
- React presenting valid/available slots rather than accepting arbitrary reservation time;
- normalized reservation-to-table assignment;
- exclusive table occupancy for the reservation interval;
- configurable examples such as start-time interval, duration, advance window, same-day lead time, timezone, and per-table capacity, using exact actual names/defaults only after repository inspection.

Keep this brief enough for the 5–10 minute constraint.

Do not turn the demo into an architecture lecture.

---

## 15. Demonstrate configurability efficiently

The Game Plan asks the demo to mention key configurable-business-rule decisions.

The final plan must decide whether the recording should:

- **show** one safe configuration query/value and explain that behavior is server-driven; or
- simply **discuss** configurability while pointing to PostgreSQL settings,

based on what fits safely within the time limit.

Do not change a configuration value during the final recording unless the existing approved reset/test workflow makes the change and restoration deterministic and fast.

Prompt-25 already contains engineering evidence that changing an approved configurable setting changes behavior without source-code modification.

The final demo need not repeat every engineering test if a concise configuration view and explanation better serves the rubric.

---

# PART E — TESTING, PERFORMANCE, AND AI ASSISTANCE

## 16. Automated testing mention

Include a brief segment or narration stating that the project used layered automated verification:

`PostgreSQL → Flask/API → React → full-stack → performance`

Reference the existing `TestInstructions.md` and verification reports.

Do not rerun the suites during the 5–10 minute presentation unless there is a compelling rubric reason.

Do not spend presentation time scrolling through large test logs.

Do not claim "all tests pass" if the frozen evidence contains an accepted baseline anomaly.

---

## 17. Performance evidence mention

Include only a concise optional/brief mention of the approved performance result if it helps demonstrate NFR compliance:

- NFR-1 PASS;
- worst recorded page-load sample: 782.601 ms;
- NFR-2 newsletter PASS; worst: 81.925 ms;
- NFR-2 reservation PASS; worst: 462.336 ms;
- measured for one concurrent user on the actual unthrottled demo/verification VM;
- no VM scaling indicated.

These are recorded verification results, not universal guarantees.

Do not consume substantial demo time reproducing performance measurements.

---

## 18. AI-assisted implementation mention

Include a brief truthful mention that:

- ChatGPT assisted with requirements/rubric analysis, least-to-most planning, prompt generation, review, and selected image generation;
- OpenAI Codex assisted with repository inspection, implementation, testing, guarded verification tooling, and documentation;
- AI-generated work was independently reviewed and tested before approval;
- Git staging/commit/push authority remained with the user.

Point to `ai-tooling.md`.

Do not claim unsupported AI tools or estimate a percentage of AI-generated code.

---

# PART F — EXACT DEMO ENVIRONMENT

## 19. Browser/application/PostgreSQL screen plan

The final document must contain a compact **window/terminal layout plan** so the presenter is not improvising during recording.

Specify exactly which windows/tabs should be prepared before recording, using actual current project commands and ports.

At minimum plan for:

1. browser on Café Fausse Home;
2. terminal/window for the Flask/application environment;
3. terminal/window for PostgreSQL/`psql`;
4. optional VS Code/document window only if needed for architecture/testing evidence.

Avoid showing secrets, passwords, `.env` contents, personal tokens, or unnecessary private paths on screen.

If a command prompts for a database password, recommend a secure existing local mechanism supported by the project rather than placing the password in the plan.

---

## 20. Exact startup/preflight instructions

Provide a concise pre-recording checklist with repository-verified commands for:

- confirming correct Git checkpoint;
- confirming working tree is clean;
- starting/initializing the local PostgreSQL environment safely;
- starting Flask;
- starting React/Vite;
- confirming expected URLs;
- preparing unique demo identities;
- preparing the deterministic full/unavailable scenario;
- opening `psql` with the correct safe connection;
- confirming no stale demo rows/processes will interfere;
- confirming camera/microphone/screenshare are ready.

Do not invent commands.

Prefer existing guarded repository helpers when they are actually appropriate for a human interactive demo.

Clearly distinguish automated-verification helpers from ordinary human-run application startup.

---

## 21. Repeatability and cleanup

The final demo plan must be restartable if the recording has to be attempted again.

Include:

- how to choose a fresh unique demo email/reservation identity for each attempt;
- how to reset only the controlled demo/full-slot preparation;
- how to shut down only processes owned by the demo workflow;
- how to remove/reset demo-created database state using an already approved safe nonproduction mechanism, if supported;
- if direct per-row cleanup is intentionally prohibited by the approved data-retention design, say so and use the approved controlled reset approach instead;
- a final verification that no disposable/demo-owned processes or resources remain.

Do not introduce a new deletion API.

Do not tell the user to execute unguarded destructive SQL.

---

# PART G — RUBRIC MAPPING / TALK TRACK

## 22. Rubric-to-demo evidence matrix

The plan must contain one concise matrix:

| Demo segment | What is shown | Rubric/SRS obligation proved | PostgreSQL/Flask/React evidence | Presenter |

At minimum map:

- all five required pages;
- navigation;
- newsletter form;
- reservation workflow;
- unavailable/full behavior;
- direct newsletter DB effect;
- direct reservation DB effect;
- Gallery/lightbox;
- responsive design;
- implementation decisions;
- configurable business rules;
- testing;
- AI tooling;
- group identity/speaking requirement.

Do not pretend that a demonstration segment proves Firefox/Safari compatibility if it does not.

---

## 23. Presenter talk track

Provide a practical presenter talk track, not merely topics.

For each timed segment include:

- screen action;
- 1–3 concise sentences the presenter can say;
- expected visible result;
- fallback if the expected result is not visible.

Keep the spoken text natural and short.

Do not write a word-for-word 10-minute essay.

Use `TEAM_MEMBER_1`, `TEAM_MEMBER_2`, `TEAM_MEMBER_3` placeholders and ensure each member has at least one spoken segment.

---

## 24. Failure/abort rules during the actual recording

The plan must explicitly say when to stop and restart rather than talk through a broken demo.

Examples:

- Flask/React/PostgreSQL not healthy before recording;
- unexpected stale demo data prevents deterministic proof;
- reservation creation fails;
- newsletter persistence cannot be shown directly;
- full/unavailable behavior is not deterministic;
- PostgreSQL query does not correlate with browser result;
- any secret/private credential becomes visible;
- recording loses a required presenter's camera or audio;
- final duration is outside the required 5–10 minute range.

Provide recovery guidance using only existing safe restart/reset mechanisms.

---

# PART H — FINAL RECORDING/SUBMISSION HANDOFF

## 25. Recording readiness checklist

At the end of the plan include a checklist whose status can be filled in manually.

It must include:

- [ ] Prompt 28 plan approved
- [ ] final committed project checkpoint recorded
- [ ] working tree clean
- [ ] Chrome result available
- [ ] Edge result available
- [ ] Firefox result received/reviewed
- [ ] Safari result received/reviewed
- [ ] NFR-7 closed or any failure corrected/reverified
- [ ] all three group members available
- [ ] all three cameras/microphones verified
- [ ] IDs ready for required on-camera verification
- [ ] each member assigned at least one speaking segment
- [ ] demo-safe unique customer/newsletter identity prepared
- [ ] deterministic unavailable/full scenario prepared
- [ ] direct PostgreSQL queries rehearsed
- [ ] browser/Flask/PostgreSQL windows arranged
- [ ] secrets/private data hidden
- [ ] cleanup/reset procedure ready
- [ ] expected duration rehearsed within 5–10 minutes

Do not check pending items automatically.

---

## 26. Submission actions remain outside Prompt 28

The rubric also requires later external submission actions, including the recording link and PDF/repository/collaborator/group submission requirements.

Prompt 28 must **list these as post-demo handoff items only**.

Do not:

- upload a video;
- create a Google Drive link;
- create the final PDF;
- invent GitHub repository URLs;
- invite `quantic-grader`;
- change GitHub repository privacy;
- inspect other team members' repositories;
- claim the group submission occurred.

The user will handle those external actions separately after the demo is ready.

---

# PART I — STATIC VERIFICATION / REVIEW GATE

## 27. Prompt-28 plan accuracy checks

Before declaring Prompt 28 ready for review, statically verify:

- every referenced repository path exists;
- every Markdown link resolves where applicable;
- every startup command matches current committed instructions/scripts;
- every local URL/port is accurate;
- every environment-variable name is accurate;
- every PostgreSQL table/column/query is accurate;
- demo SQL uses deterministic correlation keys;
- full/unavailable preparation uses an approved nonproduction-safe mechanism;
- no secrets are embedded;
- no presenter names are invented;
- no GitHub URLs are invented;
- no Firefox/Safari pass is claimed;
- no final submission is claimed;
- no staging environment is invented;
- no unimplemented feature appears in the script;
- no destructive cleanup bypasses approved safeguards;
- estimated timing totals remain between 5 and 10 minutes with a reasonable buffer.

Do not start the live application solely to perform these checks.

---

## 28. Prompt-28 status

Prompt 28 remains:

`PROPOSED — NOT YET APPROVED`

until independent ChatGPT review and explicit user approval.

Do not approve Prompt 28 yourself.

Do not perform the final recording.

Do not perform final submission actions.

---

## 29. Git restrictions

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

Leave only the authorized demo-plan document unstaged.

The repository ignores `*.diff`; do not force-add the review artifact.

---

## 30. Review diff

Generate:

`Prompt28-review-candidate.diff`

relative to the **Prompt-28 execution baseline** established in Section 1.

The review diff must represent exactly:

`docs/demo/Cafe_Fausse_Prompt28_Demonstration_Plan.md`

Do not include:

- the committed Prompt-28 prompt file;
- the review diff inside itself;
- any unrelated path.

Validate the review artifact in an isolated temporary clone/worktree without altering the real index.

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
- validation residue result;
- real staged count.

Clean all temporary validation resources before stopping.

---

## 31. Final Codex response

Lead with exactly one of:

`READY FOR PROMPT-28 DEMONSTRATION-PLAN REVIEW`

or

`BLOCKED`

Then report concisely:

- Prompt-28 execution baseline HEAD;
- `origin/main`;
- demo-plan path;
- target duration and calculated total;
- number of timed demo segments;
- whether all five required pages are covered;
- whether navigation is covered;
- whether Gallery/lightbox is covered;
- whether newsletter signup is covered;
- whether successful reservation is covered;
- whether unavailable/full behavior is covered;
- whether direct PostgreSQL newsletter effect is covered;
- whether direct PostgreSQL reservation/table-assignment effect is covered;
- whether responsive behavior is covered;
- whether architecture/configurable-business-rule discussion is covered;
- whether automated testing and AI-assisted implementation are covered;
- whether all three group-member speaking/ID obligations are represented with placeholders;
- exact startup/preflight commands statically verified;
- exact PostgreSQL demo queries statically verified;
- repeatability/cleanup procedure status;
- Chrome/Edge status;
- Firefox/Safari pending status;
- NFR-7 status;
- final recording readiness-gate status;
- external submission actions status;
- exact changed/created paths;
- staged count;
- complete working-tree status;
- `git diff --check` result;
- review-diff filename, byte size, SHA-256, path count, and validation results.

Explicitly confirm:

- no production source changed;
- no database/backend/frontend `TestInstructions.md` changed;
- no dependency/package/lockfile changed;
- no Gallery asset changed;
- no SRS/Rubric/PRA/frozen artifact changed;
- no Firefox/Safari testing occurred;
- no live application stack was started;
- no final recording occurred;
- no external submission action occurred;
- nothing was staged, committed, or pushed.

STOP for independent ChatGPT review.
