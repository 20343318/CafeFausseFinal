\# Cafe Fausse Repository Instructions



\## Project architecture



Cafe Fausse is implemented incrementally in this order:



1\. PostgreSQL database

2\. Flask REST API

3\. React frontend

4\. End-to-end integration



Primary directories:



\- `docs/` contains requirements, approved designs, roadmap documents, and implementation prompts.

\- `database/` contains PostgreSQL migrations, initialization, reset, verification, and database tests.

\- `backend/` contains the Python Flask application and backend tests.

\- `frontend/` contains the React application and frontend tests.



\## Authoritative documentation



Before implementing a roadmap increment, read:



\- `docs/SRS.pdf`

\- `docs/Rubric.pdf`

\- the applicable documents under `docs/approved-design-artifacts/`

\- the applicable implementation prompt under `docs/prompts/`



Approved design artifacts are authoritative and must not be modified unless the current task explicitly requests a documentation revision.



\## Increment boundaries



\- Implement only the roadmap increment explicitly authorized by the current prompt.

\- Do not begin later database, Flask, React, or integration increments.

\- Do not silently change approved requirements, schema decisions, or transaction decisions.

\- If implementation requires changing an approved decision, stop and request approval.

\- Do not add unapproved features, tables, columns, dependencies, or business rules.



\## Working practices



\- Inspect the repository and Git status before making changes.

\- Preserve unrelated existing changes.

\- Follow existing repository conventions when they are present.

\- Keep PostgreSQL artifacts under `database/`.

\- Keep Python Flask application code under `backend/`.

\- Keep React code under `frontend/`.

\- Add or update tests for every implementation change.

\- Run the relevant tests before reporting completion.

\- Report tests that could not be executed and explain why.

\- Do not claim an increment complete when required verification has not run successfully.

\- Do not connect to or reset a production database.

\- Do not place passwords, credentials, API keys, or secrets in the repository.

\- Do not commit, push, or create a pull request unless explicitly instructed.



\## Completion reporting



At the end of an implementation task, report:



\- files added or changed;

\- the purpose of each file;

\- commands required to set up and run the implementation;

\- tests executed and their results;

\- unresolved issues or deviations;

\- the current roadmap approval checkpoint.



