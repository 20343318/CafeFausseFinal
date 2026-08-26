# Prompt 26 — Complete Requirements, Rubric, and Traceability Audit

Begin **Prompt 26 only** — the complete requirements/rubric traceability audit.

Do **not** begin Prompt 27 or Prompt 28.

## Current approved checkpoint

The required starting checkpoint is:

`659165d13496302dfac6ce5b94c15f0e1e5a983e`

Commit subject:

`test(integration): complete and approve Prompt 25 full-stack verification`

At the start of this prompt, verify:

- branch is `main`;
- `HEAD` equals the full checkpoint above;
- `origin/main` equals the same checkpoint;
- working tree is clean;
- Git index is clean;
- Prompt 25 is recorded **APPROVED AND FROZEN**;
- Prompt 26 is the next authorized increment.

If the repository does not match that state, stop with `BLOCKED` and report the exact difference.

---

# 1. Purpose

Perform the complete Phase-F audit required by the approved Café Fausse Game Plan.

The original Prompt-26 requirement is to build traceability:

`Requirement → PostgreSQL → Flask → React → automated test(s) → manual verification → demo evidence`

and classify every requirement as:

- **Fully satisfied**
- **Partially satisfied**
- **Not satisfied**
- **Not applicable**

The audit must determine the **current** state of compliance after the approved/frozen PostgreSQL, Flask/API, React, and Prompt-25 full-integration work.

Identify everything that currently prevents a **rubric score of 5**.

Recommend **only** the smallest changes or later required actions needed to close genuine gaps.

This is an **audit-only prompt**. Do not implement the recommended changes.

---

# 2. Authority and precedence

Use the current committed repository as the authoritative implementation/evidence state.

Read and apply, in this order:

1. repository-root `AGENTS.md` and any applicable nested `AGENTS.md`;
2. `docs/SRS(1).pdf`;
3. `docs/Rubric(1).pdf`;
4. the approved **Project Requirements Addendum v2.2.1**;
5. the approved least-to-most roadmap / Game Plan;
6. approved/frozen PostgreSQL design, implementation, verification, and PostgreSQL Contract for Flask artifacts;
7. approved/frozen API-01 through API-09 artifacts;
8. approved/frozen REACT-01 through REACT-06 artifacts;
9. the approved/frozen Prompt-25 full-integration verification report and committed Prompt-25 verification tooling;
10. the actual current source code, tests, `TestInstructions.md` files, package/configuration files, and repository documentation.

## Precedence rule

The SRS and rubric are fixed authoritative requirements.

The PRA, frozen designs, frozen contracts, and prior approvals may **clarify implementation of underspecified requirements**, but they may not silently override, weaken, or contradict explicit SRS/rubric wording.

If a previously approved implementation appears materially different from an explicit SRS/rubric requirement, do **not** assume that prior approval automatically resolves the discrepancy.

Audit the exact wording and implemented behavior and report the discrepancy explicitly.

Do not invent a supplemental requirement to make the implementation appear compliant.

---

# 3. Audit-only / no-change rule

Prompt 26 may create only the audit artifact and its uncommitted review diff.

Do not modify:

- PostgreSQL schema, migrations, routines, grants, configuration, tests, or `database/TestInstructions.md`;
- Flask/backend source, tests, API contracts, configuration, or `backend/TestInstructions.md`;
- React/JSX/CSS/JavaScript source, tests, build configuration, dependencies, or `frontend/TestInstructions.md`;
- SRS;
- Rubric;
- PRA;
- approved/frozen design or implementation reports;
- Prompt-25 artifacts;
- README;
- `ai-tooling.md`;
- Gallery source assets;
- package manifests or lockfiles.

Do not correct defects during this prompt.

If the audit finds a defect or gap, document it and identify the **earliest affected layer/prompt** needed to close it.

Prompt 27 owns final README and AI-tooling documentation.

Prompt 28 owns final demo preparation.

Manual Firefox/Safari verification occurs in a different capable environment and is not to be attempted on this Codex machine.

---

# 4. Evidence rules

Use evidence, not assumptions.

A requirement may be classified **Fully satisfied** only when the repository and approved/frozen evidence actually support the complete requirement.

For every compliance claim, cite concrete repository evidence such as:

- source path/component/module;
- database artifact/schema/routine;
- Flask route/service/gateway;
- React page/component;
- exact automated test file/test name or suite;
- approved verification report/section;
- existing manual/browser evidence;
- existing direct PostgreSQL evidence;
- planned demo evidence where the demo has not yet occurred.

Do not treat a design document alone as proof that an implementation requirement is satisfied.

Do not treat an automated test name alone as proof; inspect enough of the test/implementation or frozen verification evidence to establish what it verifies.

Do not claim manual evidence that was not actually performed.

Do not convert planned Prompt-27/Prompt-28 work into completed evidence.

## Frozen verification evidence

Reuse the approved/frozen PostgreSQL, API-09, React, REACT-06, and Prompt-25 verification results.

Do **not** rerun the expensive database/backend/frontend/end-to-end suites merely to repeat frozen evidence.

If a required compliance conclusion genuinely cannot be made from committed evidence, record an **evidence gap**.

You may use inexpensive read-only/static inspection commands where useful.

Do not start PostgreSQL, Flask, Vite, or browsers for Prompt 26 unless a specific evidence gap makes that absolutely necessary; if so, stop and request approval before starting a live environment.

---

# 5. Status classification rules

Use exactly these compliance statuses:

## Fully satisfied

The complete authoritative requirement is implemented and supported by sufficient evidence.

## Partially satisfied

Some but not all of the requirement is implemented/evidenced, or a required manual/documentation/submission element is still outstanding.

## Not satisfied

The required implementation/evidence is absent or contradicts the requirement.

## Not applicable

Use only when the authoritative requirement genuinely does not apply to this project/state.

Every `Not applicable` classification must include a concrete justification.

Do not use `Not applicable` merely because work is planned for Prompt 27, Prompt 28, or manual validation.

---

# 6. Distinguish four kinds of open items

Every open item must be assigned exactly one primary category:

1. **Implementation defect/gap**
   - application/database/API/UI behavior or structure does not satisfy a requirement.

2. **Verification/evidence gap**
   - implementation may satisfy the requirement, but required proof is incomplete.

3. **Documentation gap**
   - implementation exists, but required README/AI/deployment/user-facing documentation is incomplete or not yet finalized.

4. **Demo/submission/manual-action gap**
   - application implementation is not defective, but required manual browser validation, recorded demonstration, repository collaborator setup, identity/submission action, or other user-performed submission evidence is still outstanding.

Do not misclassify a manual/demo gap as a production-code defect.

---

# 7. Mandatory SRS functional-requirement audit

Audit every SRS functional requirement **FR-1 through FR-18 individually**.

The matrix must contain at least these columns:

| Requirement | Exact SRS obligation | PostgreSQL | Flask | React | Automated tests | Manual verification | Demo evidence | Status | Gap / rationale |

Do not merge multiple FRs into a single status row.

For content requirements, verify the actual required content, not merely the existence of a page.

At minimum inspect:

- exact Home contact information and hours;
- exact Menu categories, items, descriptions, and prices;
- required reservation fields;
- valid/available slot behavior;
- random-table requirement and the total of 30 tables;
- success/full messages;
- exact Café Fausse history;
- founder biographies and dining/food/local-sourcing commitments;
- Gallery required image categories;
- lightbox;
- exact awards and reviews;
- newsletter validation and persistence;
- required PostgreSQL customer/reservation data;
- Flask insertion, availability, assignment, confirmation/error behavior.

---

# 8. Mandatory strict SRS/database/reservation reconciliation

Perform an explicit strict-language reconciliation for requirements whose implemented normalized model or approved supplemental behavior may not look identical to the simple SRS wording.

At minimum examine:

## FR-17 / rubric database structure

The SRS/rubric describes, at minimum:

- a Customers table containing customer ID, customer name, email, phone, newsletter signup;
- a Reservations table containing reservation ID, customer ID, time slot, table number.

The implemented design may normalize names, time intervals, and reservation-to-table assignments.

For each SRS field, show:

| SRS-required fact | Actual authoritative storage location | Equivalent business fact preserved? | Evidence | Compliance conclusion |

Do not automatically mark this fully satisfied simply because the normalized schema was previously approved.

Determine whether the implemented normalized representation actually satisfies the requirement's business obligation, and identify any strict-schema conflict if one remains.

## FR-8 / FR-18 / rubric random table assignment

The SRS/rubric requires assignment of a random available table from a total of 30 tables.

The approved implementation may support capacity-aware combined-table assignment.

Audit:

- whether exactly 30 bookable tables exist;
- whether assignment remains randomized where required;
- whether a reservation may receive multiple tables;
- whether this still satisfies or materially changes the explicit SRS/rubric obligation;
- the evidence supporting the conclusion.

Do not rewrite the SRS to match the implementation.

If the supplemental combined-table model creates a genuine conflict with explicit wording, report it as a gap requiring user decision rather than hiding it.

---

# 9. Mandatory SRS non-functional and interface/deployment audit

Audit individually:

- NFR-1 — website load within 3 seconds on standard broadband;
- NFR-2 — reservation/newsletter form submissions within 2 seconds;
- NFR-3 — intuitive/easy navigation;
- NFR-4 — consistent, visually appealing brand design;
- NFR-5 — reservation integrity / prevention of double or over booking;
- NFR-6 — user-friendly failure handling;
- NFR-7 — Chrome, Firefox, Safari, Edge compatibility;
- NFR-8 — desktop/tablet/smartphone responsiveness;
- NFR-9 — modular, well-documented maintainable code.

Also audit the explicit external-interface/deployment obligations:

- React + JSX UI;
- CSS using Flexbox or Grid;
- Flask API;
- PostgreSQL;
- HTTP/HTTPS client/server communication as applicable to the implemented/local deployment;
- RESTful API integration;
- local or web-server deployability;
- README deployment instructions covering environment setup, dependency installation, and database configuration.

## Performance evidence caution

Do not claim NFR-1 or NFR-2 from unrelated timing evidence.

For NFR-1, distinguish actual website-load evidence from API timing.

For NFR-2, distinguish ordinary form-submission end-to-end timing from isolated lower-layer timing.

If the existing evidence does not establish the exact requirement, classify it as partial/evidence-pending rather than inventing a pass.

---

# 10. Browser/manual-validation decision

Preserve the approved Prompt-25 browser verification scope:

- Chrome — automated/live evidence exists;
- Edge — automated/live evidence exists;
- Firefox — deferred to manual validation in a Firefox-capable environment;
- Safari — deferred to manual validation in a Safari-capable environment.

The SRS requirement for Chrome, Firefox, Safari, and Edge remains unchanged.

Therefore:

- do not install browsers;
- do not attempt Firefox/Safari on this Windows environment;
- do not claim four-browser validation;
- classify NFR-7 according to the evidence actually available;
- record Firefox/Safari as a **manual verification/evidence gap**, not automatically as a production defect.

State exactly what must later be manually checked in Firefox and Safari to close the requirement.

---

# 11. Mandatory PRA audit

Audit **every approved PRA requirement in Project Requirements Addendum v2.2.1 individually**.

Create a PRA traceability matrix with at least:

| PRA ID | Requirement summary | PostgreSQL authority | Flask/API | React | Automated evidence | Manual evidence | Status | Notes |

Do not reconstruct PRA requirements from chat history when the committed approved PRA is available.

If a PRA is superseded, inactive, future-only, or explicitly excluded from Version 1, state that from the authoritative PRA/frozen artifacts and justify the classification.

Do not treat an optional/future enhancement as a missing Version-1 requirement.

---

# 12. Mandatory score-5 rubric audit

Audit every score-5 criterion independently.

At minimum include:

- all minimum five pages built with React/JSX;
- all SRS requirements implemented;
- excellent UI/UX;
- appropriate Flexbox/Grid use;
- all required forms correctly implemented and working;
- Flask + PostgreSQL correctly integrated with React for reservations and newsletter;
- demo includes all required elements;
- demo directly shows reservation/newsletter effects in PostgreSQL;
- sophisticated reservation logic;
- AI code-generation/tooling documentation.

Also audit the rubric's submission/presentation obligations separately, including as applicable:

- approximately 5–10 minute demo;
- presenter visible on-screen;
- government-issued ID shown as required;
- presenter states name;
- group requirements only if applicable;
- do not use “Invite People” for sharing;
- Google Drive recording link;
- PDF containing repository link(s);
- private repository contains required source;
- `README.md`;
- `ai-tooling.md`;
- `quantic-grader` collaborator;
- staging file only if applicable.

Do not claim user-performed submission actions are complete unless committed/project evidence proves them.

Do not request, store, or expose identity-document details in the repository.

---

# 13. AI-tooling and README treatment

Prompt 27 has not begun.

Audit the current repository state honestly.

If final required README content or `ai-tooling.md` is absent/incomplete, classify the corresponding rubric/deployment requirement as currently open.

Record Prompt 27 as the planned least-to-most closure step.

Do not create or modify README or `ai-tooling.md` in Prompt 26.

---

# 14. Demo treatment

Prompt 28 has not begun.

The audit must distinguish:

- implementation capability already demonstrated during engineering verification;
- manual demo evidence that can be reused/planned;
- the actual final recorded rubric demonstration, which has not yet occurred.

Do not classify the final demo as complete merely because Prompt 25 proved backend database effects.

Create a concise **Prompt-28 demo-evidence input list** containing only evidence/behaviors that the final demo must show to close currently open rubric rows.

Do not write the full demo script; Prompt 28 owns that.

---

# 15. Content, asset, and licensing audit

Inspect the final committed site and approved asset/provenance evidence.

Audit:

- all SRS-required Gallery image categories;
- exact awards and reviews;
- required founder/history content;
- image quality/use;
- whether source/provenance/licensing requirements applicable to the used assets are documented sufficiently.

Do not invent provenance or licensing facts.

If provenance cannot be established from repository/approved evidence, record it as an open documentation/submission risk and identify the smallest required closure action.

Do not replace or regenerate images.

---

# 16. Do not invent admin requirements

The SRS lists administrators/managers in User Characteristics, but that alone does not automatically create an admin UI, authentication, reservation-management, or content-management implementation requirement.

Do not mark absent admin functionality as a gap unless another explicit SRS/rubric/PRA requirement actually mandates it.

Likewise, preserve approved Version-1 exclusions such as cancellation/modification/rescheduling/authentication/admin features unless an explicit authoritative requirement contradicts those exclusions.

---

# 17. Score-5 blocker register

Create a prioritized blocker/gap register.

For each open item include:

| ID | Requirement(s) | Category | Current evidence | Why not fully satisfied | Smallest closure | Earliest affected layer/prompt | User action needed? | Score-5 impact |

Use priorities:

- **P0 — score-5 blocker / explicit SRS or rubric requirement**
- **P1 — material verification/documentation risk**
- **P2 — non-blocking improvement**

Do not list optional enhancements as P0.

For every proposed closure, identify whether it belongs to:

- PostgreSQL;
- Flask/API;
- React;
- integration verification;
- Prompt 27 documentation;
- Prompt 28 demo preparation;
- external manual browser validation;
- user submission action.

If closing a gap would require changing an approved business rule or frozen contract, state that explicitly and stop short of designing the change.

---

# 18. Requirement-to-evidence master matrix

Create one consolidated master matrix following the Game Plan structure:

`Requirement → PostgreSQL → Flask → React → automated test(s) → manual verification → demo evidence`

It must cover:

- SRS FR-1 through FR-18;
- SRS NFR-1 through NFR-9;
- explicit SRS interface/deployment obligations;
- every approved PRA;
- score-5 rubric criteria;
- material presentation/submission obligations.

For rows that do not legitimately involve a layer, use `N/A — <reason>` rather than forcing artificial traceability.

Use exact paths/test names/report sections where practical.

---

# 19. Traceability consistency checks

Cross-check the final matrix against prior frozen traceability claims.

Identify:

- requirements previously claimed satisfied but not supported by current evidence;
- requirements implemented but missing from prior traceability;
- tests that claim coverage of a requirement they do not actually verify;
- duplicate or conflicting sources of truth;
- stale documentation that could mislead Prompt 27 or Prompt 28;
- frozen design statements that were planning-only but might be mistaken for implementation evidence.

Do not modify historical frozen artifacts during this audit.

Record historical inconsistencies as audit findings.

---

# 20. Required audit artifact

Create exactly one project audit document:

`docs/requirements-audit/Cafe_Fausse_Prompt26_Requirements_Rubric_Traceability_Audit.md`

Mark it:

`PROPOSED — NOT YET APPROVED`

The artifact must include at minimum:

1. baseline/checkpoint;
2. authority and precedence;
3. audit methodology and status definitions;
4. SRS FR-1 through FR-18 matrix;
5. strict FR-17 database reconciliation;
6. strict FR-8/FR-18 random-table reconciliation;
7. SRS NFR-1 through NFR-9 matrix;
8. external-interface/deployment audit;
9. browser/manual-validation status;
10. complete PRA matrix;
11. score-5 rubric matrix;
12. submission/presentation-obligation matrix;
13. README/AI-tooling status;
14. demo-evidence status;
15. content/asset/provenance status;
16. master requirement-to-evidence matrix;
17. traceability consistency findings;
18. prioritized blocker/gap register;
19. least-to-most closure recommendations;
20. requirements that are fully satisfied;
21. requirements that remain partial/not satisfied;
22. any contradictions requiring user approval;
23. Prompt-26 completion assessment;
24. explicit approval checkpoint.

Do not mark Prompt 26 approved.

---

# 21. Prompt-26 completion assessment

At the end, answer these questions explicitly:

1. Is every SRS functional requirement fully satisfied?
2. Is every SRS NFR fully satisfied?
3. Are all explicit interface/deployment requirements fully satisfied?
4. Is every approved Version-1 PRA requirement fully satisfied?
5. Is every score-5 implementation criterion fully satisfied?
6. Which score-5 requirements remain open only because Prompt 27 has not been completed?
7. Which remain open only because Prompt 28/final submission has not been completed?
8. Which remain open because Firefox/Safari manual evidence is deferred?
9. Are there any actual implementation defects?
10. Are there any SRS/rubric-versus-frozen-design contradictions?
11. Are there any missing user decisions?
12. What is the exact least-to-most sequence for closing all P0/P1 gaps?
13. Is Prompt 27 safe to begin after the audit is approved, or must an earlier layer be reopened first?

If an earlier implementation layer must be reopened, do not authorize Prompt 27 yet.

---

# 22. Git restrictions

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
- create/delete tags;
- modify pull requests.

Preserve the real Git index and repository history.

The only project path Codex may create/modify for Prompt 26 is:

`docs/requirements-audit/Cafe_Fausse_Prompt26_Requirements_Rubric_Traceability_Audit.md`

The review `.diff` artifact is temporary/review-only and must not be committed.

---

# 23. Static verification before stopping

Before reporting completion:

1. confirm baseline HEAD remained unchanged;
2. confirm `origin/main` remained unchanged;
3. confirm staged path count is zero;
4. confirm the only project working-tree path created/changed by Prompt 26 is the audit document;
5. confirm no database/backend/frontend implementation/test/configuration file changed;
6. confirm no frozen artifact changed;
7. confirm no dependency/package/lockfile changed;
8. run `git diff --check`;
9. confirm Prompt 27 and Prompt 28 have not begun;
10. confirm no live test environment/process/database/browser was started by Prompt 26, unless separately approved due to a specific evidence gap.

---

# 24. Independent review artifact

Create:

`Prompt26-review-candidate.diff`

The artifact must represent the complete Prompt-26 project change relative to checkpoint:

`659165d13496302dfac6ce5b94c15f0e1e5a983e`

It should contain only:

`docs/requirements-audit/Cafe_Fausse_Prompt26_Requirements_Rubric_Traceability_Audit.md`

Do not stage the audit document to create the diff.

Validate the review artifact without altering the real Git index.

Report:

- filename;
- byte size;
- SHA-256;
- encoding;
- BOM status;
- represented path count;
- exact path list;
- clean isolated apply result;
- applied-copy byte match;
- reverse-apply result;
- baseline restoration result;
- validation-residue status.

The `.diff` artifact itself must not be included inside its own diff and must not be committed.

---

# 25. Final Codex response

Lead with one of:

- `READY FOR PROMPT-26 INDEPENDENT REVIEW`
- `BLOCKED`

Report concisely:

- baseline full HEAD;
- audit artifact path;
- overall SRS status summary;
- overall PRA status summary;
- overall rubric score-5 readiness summary;
- number of Fully satisfied / Partially satisfied / Not satisfied / Not applicable rows by major matrix;
- P0/P1/P2 gap counts;
- actual implementation defects, if any;
- strict FR-17 reconciliation conclusion;
- strict random-table reconciliation conclusion;
- browser/manual status;
- README/AI-tooling status;
- demo/submission status;
- asset/provenance status;
- any user decisions required;
- whether an earlier implementation layer must be reopened;
- whether Prompt 27 appears safe to begin after Prompt-26 approval;
- `git diff --check`;
- staged count;
- HEAD;
- `origin/main`;
- changed-path list;
- review-diff metadata;
- confirmation no stage/commit/push;
- confirmation Prompt 27/28 not begun.

Stop for independent ChatGPT review and explicit user approval.

Do **not** approve Prompt 26 yourself.
Do **not** begin Prompt 27.
Do **not** begin Prompt 28.
