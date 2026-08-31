# AI Tooling Used for Cafe Fausse

This project used ChatGPT and OpenAI Codex as AI-assisted development tools. Git, PostgreSQL, Python, Node/npm, PowerShell, browsers, editors, and test frameworks were ordinary development tools and are not presented as AI code-generation tools. No percentage of AI-generated code is estimated.

## ChatGPT

ChatGPT was used to:

- analyze the fixed SRS and rubric and identify underspecified business rules;
- propose alternatives for explicit user approval and help record the approved supplemental requirements;
- maintain the dependency-ordered, least-to-most implementation plan;
- prepare detailed, scope-constrained execution prompts for Codex;
- review Codex outputs and review diffs independently;
- identify corrections, blockers, and places where a requirement had to be distinguished from a design or test-method choice; and
- generate the approved behind-the-scenes Gallery image later committed as `frontend/assets/gallery/gallery-behind-the-scenes.webp`.

ChatGPT did not directly commit repository changes.

## OpenAI Codex

Codex was used in the local repository to:

- inspect repository state and authoritative project artifacts;
- implement approved PostgreSQL, Flask, and React increments;
- create and run unit, integration, concurrency, full-stack, and performance verification;
- create guarded test, process-ownership, recovery, and cleanup tooling;
- update technical and test documentation; and
- generate review-diff artifacts for independent inspection.

Codex changes were left unstaged for review. Codex was not given authority to stage, commit, or push project changes; those Git actions remained under user control.

No repository evidence or approved project history establishes use of Cursor, Claude Code, GitHub Copilot, or another AI code-generation tool on Cafe Fausse, so none is claimed here.

## Least-to-most AI-assisted workflow

The project followed this sequence:

1. Establish the SRS and rubric as the fixed authoritative baseline.
2. Identify operational business rules that the supplied documents left underspecified.
3. Obtain explicit user decisions and record the approved Project Requirements Addendum.
4. Design, implement, test, review, approve, and freeze PostgreSQL.
5. Design, implement, test, review, approve, and freeze Flask and its REST boundary.
6. Design, implement, test, review, approve, and freeze React.
7. Run guarded full-stack integration verification.
8. Perform a requirements/rubric traceability audit.
9. Measure and approve the remaining NFR-1/NFR-2 performance evidence.
10. Prepare the final repository documentation.
11. Prepare the final demonstration later; that work has not begun.

Major increments used explicit approval checkpoints and frozen contracts before dependent layers proceeded. This kept React from redefining Flask validity, Flask from reproducing PostgreSQL integrity rules, and later work from silently reopening approved decisions.

## What worked well

- Small, dependency-ordered increments made review and fault isolation manageable.
- Explicit PostgreSQL-to-Flask and Flask-to-React contracts reduced cross-layer ambiguity.
- Detailed prompts constrained Codex to the approved increment and protected frozen files.
- Repeatable tests and the three layer-specific `TestInstructions.md` runbooks reduced regression and cleanup risk.
- Unstaged Git review diffs gave ChatGPT and the user an independently inspectable change set before commit.
- Automated tests plus human review caught implementation, verification, and evidence gaps before checkpoints were frozen.
- Central PostgreSQL business configuration allowed approved policy changes to propagate without hard-coded React or Flask rule changes.
- AI assistance accelerated repetitive implementation, test construction, static inspection, and evidence preparation while the user retained requirements and Git authority.
- Browser testing of Chrome, Edge, Firefox, and Safari all rendered the website fully and passed reservation testing.

## Limitations and corrective iterations

- Detailed prompts reduced ambiguity but did not eliminate implementation or verification mistakes; several generated scripts and evidence flows required correction and reruns.
- Baseline handling required explicit ancestry and delta checks when an execution prompt was itself committed after the prior approved checkpoint.
- Process and cleanup safety needed durable ownership evidence, command/ancestry checks, and fail-safe refusal rather than PID-only termination.
- Independent review was needed to distinguish actual SRS/rubric obligations from implementation designs and test methodology.
- One frozen API-09 PostgreSQL selection retains its documented accepted baseline `StopIteration` result even though the standalone complete PostgreSQL programmer gate passed; AI-generated summaries therefore cannot safely collapse evidence to all tests pass.
These limitations are why generated work was treated as a review candidate rather than accepted automatically.

## Human review and verification controls

- The SRS and rubric remained fixed and authoritative.
- Supplemental business rules required explicit user approval before implementation.
- Work proceeded PostgreSQL -> Flask -> React -> full-stack integration.
- Codex edits remained unstaged until independent review; the user controlled staging, commits, and pushes.
- Review diffs were generated relative to recorded clean baselines and checked in isolated copies before handoff.
- Unit, API, PostgreSQL integration, concurrency, React component, mocked-flow, live full-stack, and performance checks were run throughout the project.
- Manual browser, responsive, keyboard, lightbox, and form checks were used where human observation was appropriate.
- `database/TestInstructions.md`, `backend/TestInstructions.md`, and `frontend/TestInstructions.md` preserve repeatable, restartable, and guarded cleanup workflows.
- Approved checkpoints froze contracts and prevented silent changes to earlier layers.

The observable artifacts, tests, review diffs, and approval records were used as the basis for verifying and accepting project changes.

## Image-generation disclosure

The committed behind-the-scenes Gallery image, `frontend/assets/gallery/gallery-behind-the-scenes.webp`, was AI-generated during the Cafe Fausse project. The four originally supplied project images are assignment-provided assets and are not claimed to be AI-generated.
