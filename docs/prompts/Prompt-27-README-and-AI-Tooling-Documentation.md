# Prompt 27 — Final README and AI-Tooling Documentation

Begin **Prompt 27 only** — the documentation phase from the approved Café Fausse Game Plan.

Do **not** begin Prompt 28.
Do **not** perform Firefox or Safari testing.
Do **not** modify production application behavior.
Do **not** modify database, Flask, React, test, dependency, configuration, or frozen verification artifacts unless this prompt explicitly authorizes the file.

The purpose of Prompt 27 is to close the two documentation gaps identified by the approved Prompt-26 audit:

- repository-root `README.md`;
- repository-root `ai-tooling.md`.

The approved Game Plan requires Prompt 27 to prepare these files using the **actual completed project**, and the rubric requires the repository to contain both.

---

## 1. Frozen pre-Prompt-27 checkpoint

The approved/frozen project checkpoint immediately before creation of this Prompt-27 prompt file is:

`97108195ea2914bb01e77404f0cd4cc9413154ab`

Commit subject:

`test(performance): approve and freeze Prompt 26A NFR verification`

At that checkpoint:

- Prompt 26 is **APPROVED AND FROZEN**;
- Prompt 26A is **APPROVED AND FROZEN**;
- NFR-1 performance evidence is **PASS**;
- NFR-2 newsletter performance evidence is **PASS**;
- NFR-2 reservation performance evidence is **PASS**;
- VM conclusion is **NO VM SCALING INDICATED**;
- Chrome verification is **PASS**;
- Edge verification is **PASS**;
- Firefox manual verification is still pending;
- Safari manual verification is still pending;
- NFR-7 is therefore not yet fully closed;
- Prompt 28 has not begun.

### Execution-baseline rule

This Prompt-27 file will be committed before Codex executes it.

Therefore, do **not** require execution HEAD to equal `97108195...`.

At execution time:

1. record the full current `HEAD`;
2. record full `origin/main`;
3. require `HEAD == origin/main`;
4. require the working tree and Git index to be clean;
5. verify current HEAD is a descendant of
   `97108195ea2914bb01e77404f0cd4cc9413154ab`;
6. verify the committed delta from `97108195...` to current HEAD contains only
   the committed Prompt-27 prompt artifact:

   `docs/prompts/Prompt-27-README-and-AI-Tooling-Documentation.md`

If those conditions are not true, stop with `BLOCKED` and report the discrepancy.

Treat the current clean committed HEAD that passes those checks as the
**Prompt-27 execution baseline**.

Use that execution baseline for the later Prompt-27 review diff so the already
committed Prompt-27 prompt file does not appear in its own review delta.

---

## 2. Authority and precedence

Use the current committed repository as the authoritative implementation and evidence state.

Read and follow, in precedence order:

1. repository-root `AGENTS.md` and applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. approved Project Requirements Addendum v2.2.1;
5. approved Game Plan / least-to-most roadmap;
6. approved/frozen PostgreSQL design, implementation, verification, and PostgreSQL Contract for Flask artifacts;
7. approved/frozen API artifacts through API-09;
8. approved/frozen React artifacts through REACT-06;
9. approved/frozen Prompt-25 full-integration verification;
10. approved/frozen Prompt-26 requirements/rubric audit;
11. approved/frozen Prompt-26A NFR-1/NFR-2 performance verification;
12. current source code, package/dependency manifests, configuration, existing layer READMEs, and all `TestInstructions.md` files;
13. this Prompt 27.

The SRS and rubric remain fixed authoritative requirements.

Do not weaken, reinterpret, or silently replace an explicit requirement.

Do not invent setup commands, configuration keys, version requirements, test outcomes, deployment capabilities, AI usage, asset provenance, browser results, or implementation decisions.

If repository evidence conflicts materially with a required statement, stop and report the conflict instead of documenting a false claim.

---

## 3. Prompt-27 scope

Prompt 27 may create or modify only:

- `README.md`
- `ai-tooling.md`

Do not create additional Prompt-27 implementation, test, design, or verification files unless a genuine blocker makes one necessary and the user explicitly approves it first.

Do not modify:

- `database/**`;
- `backend/**`;
- `frontend/**`;
- any `TestInstructions.md`;
- SRS;
- Rubric;
- PRA;
- Game Plan;
- frozen design reports;
- frozen implementation/verification reports;
- Prompt-25 artifacts;
- Prompt-26 audit;
- Prompt-26A prompt/report/tooling;
- Gallery assets;
- package manifests;
- lockfiles;
- migrations;
- API contracts;
- environment/configuration files;
- Prompt 28 artifacts.

This is a documentation-only increment.

If documenting the actual project reveals a defect, broken command, incorrect existing layer documentation, or required missing implementation, record the blocker and stop. Do not repair another layer under Prompt 27.

---

## 4. Firefox/Safari deferral — mandatory wording discipline

The user has explicitly authorized Prompt 27 to proceed while Firefox and Safari compatibility evidence is still being gathered by other team members.

This is a **temporary workflow deferral**, not a waiver of SRS NFR-7.

The documentation must preserve the truthful current state:

- Chrome: PASS
- Edge: PASS
- Firefox: pending manual verification
- Safari: pending manual verification
- NFR-7: not yet fully closed

Do not state or imply that:

- all four required browsers have passed;
- NFR-7 is fully satisfied;
- every SRS requirement has final verification evidence;
- the project is ready for final submission solely because Prompt 27 is complete.

If browser results arrive later, they may be incorporated in a separately authorized final-readiness/update step.

Do not perform Firefox or Safari testing during Prompt 27.

---

## 5. Mandatory read-only repository inspection

Before writing documentation, inspect the actual repository deeply enough to make every instruction executable and truthful.

At minimum inspect:

- repository tree and root files;
- `.gitignore`;
- `database/README.md` if present;
- `database/TestInstructions.md`;
- database migration/bootstrap/configuration artifacts;
- PostgreSQL Contract for Flask;
- `backend/README.md` if present;
- `backend/TestInstructions.md`;
- backend dependency/configuration files;
- Flask application entry point and environment handling;
- `frontend/README.md` if present;
- `frontend/TestInstructions.md`;
- `frontend/package.json`;
- `frontend/package-lock.json`;
- Vite configuration;
- frontend environment-variable handling;
- existing guarded live-integration helpers;
- Prompt-25 integration report;
- Prompt-26 audit;
- Prompt-26A performance report;
- Gallery asset filenames and repository evidence about their provenance;
- current Git history sufficient to understand the least-to-most progression.

Use existing layer documentation as evidence, but verify commands and paths against actual committed files before copying them into the root README.

Do not copy stale prompt-number statements or obsolete commands.

---

# PART A — ROOT README.md

## 6. README purpose

Create a repository-root `README.md` that lets a competent reviewer or contributor understand the solution and run the actual Café Fausse project locally.

The rubric requires the private GitHub repository to include a README describing the solution, its design, and how to run it locally.

The approved Game Plan additionally requires the README to explain:

- project purpose;
- architecture;
- PostgreSQL configuration;
- configurable restaurant settings;
- Flask environment/setup;
- React setup;
- dependency installation;
- local execution;
- database initialization;
- running automated tests.

The README must be concise enough to use, but complete enough that the grader does not need to reconstruct setup from project history.

---

## 7. Required README structure

Use a clear professional structure. At minimum include the following content.

### 7.1 Project overview

Explain that Café Fausse is a responsive full-stack restaurant web application using:

- React with JSX;
- Flask/Python;
- PostgreSQL.

Summarize the user-facing capabilities without overselling:

- Home;
- Menu;
- Reservations;
- About Us;
- Gallery/lightbox;
- newsletter signup;
- server-authoritative reservation availability and creation;
- persistent PostgreSQL-backed customer/reservation/newsletter behavior.

Do not claim admin/authentication/cancellation/modification features that are not part of Version 1.

### 7.2 Architecture

Describe the actual architecture and request flow, for example conceptually:

`Browser / React → Flask REST API → PostgreSQL`

But derive exact implementation details, directories, ports, entry points, configuration ownership, and helper scripts from the repository.

Explain the separation of responsibilities:

- PostgreSQL owns persistent business data, configurable restaurant rules, integrity/concurrency enforcement, and reservation allocation primitives;
- Flask owns API validation/orchestration and the frozen REST boundary;
- React owns presentation and interaction while Flask remains authoritative for server-side validity/availability.

Do not imply React is a security or integrity authority.

### 7.3 Repository layout

Provide a compact tree/table describing important top-level directories and files.

Include at least the database, backend, frontend, documentation, root README, and `ai-tooling.md`.

Do not list every historical artifact.

### 7.4 Prerequisites / verified environment

State the actual prerequisite software based on committed tooling and documentation.

Differentiate clearly between:

- **required/supported prerequisites derived from repository configuration**; and
- **the verified development/test environment**.

Prompt-26A measured the project on:

- Windows Server 2025;
- 8 logical processors;
- 8.00 GiB RAM;
- PostgreSQL 18.3;
- Python 3.14.6;
- Flask 3.1.3;
- Node 24.15.0;
- npm 12.0.2;
- React 19.2.8;
- Vite 8.2.2;
- Chrome 151.0.7922.170.

Do not convert the VM CPU/RAM values or exact browser version into new minimum requirements.

Do not assert support for untested operating systems.

Use exact dependency versions/ranges from committed manifests where those are authoritative.

### 7.5 Dependency installation

Give the exact repository-supported commands for:

- Python/Flask dependencies;
- Node/React dependencies;
- PostgreSQL prerequisites where applicable.

Use existing actual commands.

Do not invent a new package manager, virtual-environment convention, or dependency installation flow.

If multiple supported paths genuinely exist, distinguish them.

### 7.6 PostgreSQL initialization and configuration

Explain the actual database initialization/bootstrap/migration sequence using committed scripts and the existing safe instructions.

Include:

- how to initialize the local database;
- expected application role/configuration handling;
- required authorization/safety constraints for disposable/non-production helpers where relevant;
- how changeable restaurant settings are represented.

Do not expose secrets.

Do not put real passwords in README.

Do not instruct users to bypass ownership or non-production safeguards.

### 7.7 Configurable restaurant settings

Document the actual configurable reservation/business settings from the approved implementation.

Examples from the approved project include settings such as:

- reservation start-time interval;
- reservation duration;
- maximum advance-booking window;
- same-day minimum lead time;
- restaurant timezone;
- per-table capacity.

Inspect the current configuration schema/data and approved artifacts for exact names, defaults, permitted ranges/values, and ownership.

Do not invent settings.

Do not make an explicit SRS constant configurable in documentation if the implementation does not do so.

Explain that availability and permitted reservation times are derived from server-authoritative configuration.

### 7.8 Flask setup

Document:

- actual Python environment/setup;
- actual configuration/environment variables;
- actual backend start command;
- health/readiness behavior where useful;
- how Flask connects to PostgreSQL.

Use exact current names and commands.

Do not expose secret values.

### 7.9 React setup

Document:

- Node/npm installation expectations;
- `npm` dependency installation command;
- actual frontend development/build commands;
- actual environment variable(s), such as API/base URL configuration, only if they exist;
- local Vite execution.

Use current committed commands.

### 7.10 Running the full application locally

Provide one recommended local development path.

Where possible, prefer the existing guarded/approved helper workflow rather than creating a new orchestration approach.

If the ordinary developer workflow requires separate PostgreSQL, Flask, and Vite terminals, document that accurately.

If an existing owned live-integration helper is appropriate for verification rather than normal development, label it as verification tooling rather than pretending it is the only run method.

Document actual default/local addresses and ports only after confirming them.

### 7.11 Database initialization vs. disposable verification environments

Clearly distinguish:

- ordinary/local project database initialization; and
- disposable owned verification environments used by automated integration/performance scripts.

Do not tell ordinary users to use destructive test cleanup against an ambiguous database.

Preserve all non-production authorization requirements from existing test instructions.

### 7.12 Automated and manual testing

Explain the layered test strategy and point to:

- `database/TestInstructions.md`;
- `backend/TestInstructions.md`;
- `frontend/TestInstructions.md`.

Give concise, verified commands for the principal repeatable suites when appropriate.

Explain the least-to-most testing pattern:

`unit/component → PostgreSQL/API integration → React integration → full-stack verification → performance verification`

Do not claim every historical run is expected to be perfectly green if frozen evidence documents an accepted known baseline anomaly.

Do not silently hide known accepted baseline behavior.

Avoid dumping every historical test count into the README; link to the relevant verification artifacts where useful.

### 7.13 Performance verification

Summarize the approved Prompt-26A result accurately:

- NFR-1 PASS;
- worst measured page-load sample 782.601 ms;
- newsletter NFR-2 PASS; worst 81.925 ms;
- reservation NFR-2 PASS; worst 462.336 ms;
- one concurrent user;
- unthrottled actual demo/verification VM;
- no VM scaling indicated.

Clearly label these as recorded verification results, not universal performance guarantees.

Link to the committed performance verification report.

### 7.14 Browser/responsive status

State:

- responsive desktop/tablet/mobile behavior has committed verification evidence;
- Chrome PASS;
- Edge PASS;
- Firefox pending manual verification;
- Safari pending manual verification.

Do not claim final NFR-7 closure.

### 7.15 Local deployment status

The rubric permits either localhost or staging.

The current project uses the local/localhost path unless repository evidence shows otherwise.

Do not invent a staging deployment.

If there is no staging server, state that the project is run locally for the demonstration environment.

Do not create `staging.md` unless separately authorized.

### 7.16 Gallery assets / provenance

Document only facts supported by repository evidence:

- the original project supplied image assets are project-provided assets for this assignment;
- `gallery-behind-the-scenes.webp` was AI-generated during the Café Fausse project.

Do not invent an external source, photographer, license name, URL, or royalty-free claim for the supplied assets.

The rubric itself permits AI-generated additional images.

If current repository evidence supports a more precise provenance statement, use it.

### 7.17 Useful documentation links

Link to the most useful committed docs rather than forcing reviewers through the full history.

Candidates include:

- SRS/rubric location;
- database/backend/frontend TestInstructions;
- PostgreSQL Contract for Flask;
- Prompt-25 integration verification;
- Prompt-26 traceability audit;
- Prompt-26A performance verification.

Keep the README user-oriented rather than turning it into a project diary.

---

# PART B — ai-tooling.md

## 8. Rubric obligation

Create root `ai-tooling.md`.

The rubric requires a document that outlines what AI code-generation tools were used and how.

The approved Game Plan requires it to document:

- AI tools actually used;
- how they were used;
- the least-to-most development approach;
- what AI assistance worked well;
- what did not;
- how generated work was reviewed/tested.

Do not claim tools or activities that did not occur.

Do not estimate a percentage of AI-generated code.

Do not imply that AI output was accepted without human review.

---

## 9. Approved factual AI-usage basis

The following high-level facts are approved project history and may be documented.

### ChatGPT

ChatGPT was used for activities including:

- requirements and rubric analysis;
- identifying underspecified business rules;
- proposing alternatives for user approval;
- maintaining the least-to-most development sequence;
- generating detailed Codex execution prompts;
- reviewing Codex outputs and review diffs;
- identifying corrections and blockers;
- helping distinguish authoritative requirements from implementation/test methodology;
- generating at least the approved behind-the-scenes Gallery image used by the project.

Do not claim ChatGPT directly committed repository changes.

### OpenAI Codex

Codex was used in the local development repository for activities including:

- repository inspection;
- implementation of approved PostgreSQL, Flask, and React increments;
- unit/integration/full-stack verification;
- creation and execution of guarded test/cleanup tooling;
- performance measurement;
- documentation updates;
- generation of review-diff artifacts for independent inspection.

Do not claim Codex had authority to stage, commit, or push project changes.

Git staging, commits, and pushes remained under user control.

### Other tools

Do not add Cursor, Claude Code, Copilot, or any other AI tool unless repository evidence or explicit user-provided facts establish actual use on Café Fausse.

Ordinary development tools such as VS Code, Git, PostgreSQL, Python, Node/npm, browsers, PowerShell, and test frameworks should not be mislabeled as AI code-generation tools.

---

## 10. Least-to-most AI-assisted workflow

Explain the actual development pattern accurately.

At a high level:

1. establish fixed SRS/rubric baseline;
2. identify underspecified business rules;
3. obtain explicit user decisions and record approved supplemental requirements;
4. design/implement/test/freeze PostgreSQL;
5. design/implement/test/freeze Flask/API;
6. design/implement/test/freeze React;
7. run full-stack integration verification;
8. run requirements/rubric traceability audit;
9. close performance evidence;
10. prepare final documentation;
11. prepare final demo later.

Explain that major increments used explicit approval checkpoints and frozen contracts before proceeding to dependent layers.

Do not describe Prompt 28 as completed.

---

## 11. What worked well

Document evidence-based benefits, such as:

- decomposition into small dependency-ordered increments;
- explicit contracts between PostgreSQL, Flask, and React;
- detailed prompts constrained Codex scope;
- repeatable tests and `TestInstructions.md` reduced regression risk;
- review diffs enabled independent inspection before commit;
- automated tests plus human approval caught issues before freezing;
- configurable business rules reduced hard-coded policy changes;
- AI accelerated repetitive implementation and verification work while preserving human decision authority.

Write this as project experience, not marketing copy.

---

## 12. What did not work well / limitations

Be candid but concise.

Truthful themes that may be documented include:

- detailed AI prompts did not eliminate implementation mistakes;
- some generated scripts/verification flows required corrective iterations;
- baseline/checkpoint handling required care when prompt files themselves were committed;
- cleanup/process ownership needed explicit safeguards rather than trusting PID-only termination;
- AI sometimes needed independent review to distinguish a real requirement from a test-methodology or design choice;
- browser coverage is environment-dependent; Firefox/Safari evidence remains external/manual at this point.

Do not invent failures that are not evidenced.

Do not disparage tools.

Frame this as why review/test gates were necessary.

---

## 13. Human review and verification controls

Explain the actual governance approach:

- SRS/rubric fixed as authoritative;
- user approval required for supplemental business rules;
- PostgreSQL → Flask → React order;
- Codex changes left unstaged for review;
- review diffs generated and independently inspected;
- automated unit/integration/full-stack tests run throughout;
- manual/browser verification used where appropriate;
- `TestInstructions.md` maintained for repeatable/restartable verification and cleanup;
- user retained Git staging/commit/push authority;
- frozen checkpoints prevented silent reopening of earlier contracts.

Do not expose private chain-of-thought or internal model reasoning.

Document observable workflow and controls only.

---

## 14. Image-generation disclosure

Include a concise disclosure that the committed behind-the-scenes Gallery image was AI-generated during the Café Fausse project.

Do not claim the originally supplied project assets were AI-generated.

Do not invent a model/version, prompt text, legal license, or generation date unless committed evidence supports it.

---

# PART C — DOCUMENTATION QUALITY / VERIFICATION

## 15. Documentation accuracy checks

Before declaring Prompt 27 ready for review, verify every README command against committed files.

At minimum check:

- referenced paths exist;
- Markdown links resolve within the repository where applicable;
- commands use current filenames;
- environment-variable names match source/configuration;
- database initialization commands match committed scripts;
- package installation commands match manifests;
- start/build/test commands exist;
- local URLs/ports are accurate;
- no secrets are embedded;
- no placeholder team names/URLs remain;
- no staging deployment is claimed without evidence;
- no Firefox/Safari pass is claimed;
- no Prompt 28 completion is claimed;
- no nonexistent feature is documented;
- no invented asset license/source is documented.

Use inexpensive static/read-only checks.

Do not start PostgreSQL, Flask, Vite, or a browser merely to validate documentation unless a specific command cannot be verified any other way. If live execution genuinely appears necessary, stop and ask permission first.

---

## 16. Testing-documentation treatment

Prompt 27 is documentation-only.

Do not modify the three layer `TestInstructions.md` files.

The root README must point contributors to the existing layer-specific repeatable/restartable test instructions.

Do not create a fourth test framework or root test harness.

If the existing instructions reveal a documentation inconsistency that makes README accuracy impossible, stop and report it rather than silently changing frozen test instructions.

---

## 17. Known/accepted verification state

Use frozen evidence accurately.

Do not state generic phrases such as:

- "all tests pass";
- "all browsers supported and verified";
- "fully production-ready";
- "all requirements closed";

unless the evidence actually establishes them.

Preserve known accepted limitations/deferrals.

In particular:

- Firefox/Safari evidence remains pending;
- final demonstration remains Prompt 28;
- external GitHub/Drive/PDF/collaborator/group submission administration remains later manual work;
- Prompt 27 does not complete those actions.

---

## 18. Group-submission boundary

This is a group project of three, but team-specific submission administration remains intentionally deferred.

Do not:

- invent team-member names;
- invent repository URLs;
- invent GitHub collaborator state;
- claim `quantic-grader` has been invited;
- create or inspect other team-member repositories;
- prepare the final PDF;
- create Drive links;
- claim final submission.

Those remain later manual/external actions.

README and `ai-tooling.md` should document the current repository only.

---

# PART D — REVIEW ARTIFACT / STOP GATE

## 19. Prompt-27 status

Prompt 27 remains:

`PROPOSED — NOT YET APPROVED`

until independent ChatGPT review and explicit user approval.

Do not write approval/frozen status into `README.md` or `ai-tooling.md`.

Do not approve Prompt 27 yourself.

Do not begin Prompt 28.

---

## 20. Git restrictions

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

Leave `README.md` and `ai-tooling.md` unstaged for independent review.

The repository ignores `*.diff`; do not force-add the review artifact.

---

## 21. Review diff

Generate:

`Prompt27-review-candidate.diff`

relative to the **Prompt-27 execution baseline** established in Section 1.

The review diff must represent exactly:

- `README.md`
- `ai-tooling.md`

If one of those files unexpectedly existed at execution baseline, represent its actual tracked modification rather than fabricating a new-file diff.

Do not include:

- the committed Prompt-27 prompt file;
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
- staged count.

Clean all temporary validation resources before stopping.

---

## 22. Final Codex response

Lead with exactly one of:

`READY FOR PROMPT-27 DOCUMENTATION REVIEW`

or

`BLOCKED`

Then report concisely:

- Prompt-27 execution baseline HEAD;
- `origin/main`;
- exact changed/created paths;
- README sections completed;
- `ai-tooling.md` sections completed;
- whether every documented setup/run/test command was verified against committed repository files;
- whether any live stack was started;
- Chrome/Edge status;
- Firefox/Safari pending status;
- NFR-7 status;
- Prompt-26 and Prompt-26A frozen-artifact preservation;
- Prompt-28 status;
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
- no Prompt 28 work began;
- nothing was staged, committed, or pushed.

STOP for independent ChatGPT review.
