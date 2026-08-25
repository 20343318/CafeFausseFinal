# Prompt 24 — Live React-to-Flask Integration

Implement Prompt 24 only: connect the approved/frozen Café Fausse React UI to
the approved/frozen Flask API and verify controlled browser-to-PostgreSQL behavior.

This is the revised and resequenced version of the original Game Plan
"Connect React to Flask" prompt.

Do not begin Prompt 25.

This increment is the integration implementation immediately following the
approved/frozen REACT-05 / Prompt 23 mocked reservation and newsletter UI.

Use a least-to-most implementation order inside this prompt:

1. integration environment and contract alignment;
2. native-fetch production operation adapter;
3. live OP-01/current-hours integration;
4. live OP-03/OP-04 newsletter integration;
5. live OP-02 reservation-availability integration;
6. live OP-05 reservation integration;
7. live error/recovery and PostgreSQL-effect verification;
8. integration regression, timing, restartability, and cleanup.

Do not bypass an earlier stage merely because a later stage appears easy.

If a frozen backend, database, API, or React defect prevents a later stage,
stop with BLOCKED rather than changing an already-frozen layer without approval.


# Approval state

The following are approved, committed, pushed, and frozen:

- SRS and Rubric baseline;
- Project Requirements Addendum v2.2.1;
- PostgreSQL DB-01 through DB-07 and Hard Gate 1;
- PostgreSQL Contract for Flask;
- Flask API-01 through API-09 and Hard Gate 2;
- API08-RC-01 and API08-RC-02;
- REACT-01;
- REACT-02;
- REACT-03;
- REACT-04;
- REACT-05 / Prompt 23.

The approved REACT-05 implementation commit is:

92e76910249eda01af51341d0c5bd449cc42b54e

The actual execution baseline is expected to be a later clean commit containing
only the committed Prompt-24 input after that REACT-05 checkpoint.

During Phase 0, record the actual full HEAD rather than assuming its hash.

The user has explicitly approved:

"INT-01 integration strategy approved."

That approval fixes the following technical integration decisions for Prompt 24.


# Approved INT-01 integration strategy

## INT01-01 — same-origin browser/API connection

Production React must call Flask with native fetch using same-origin relative
API paths, for example:

/api/v1/reservation-context
/api/v1/reservation-availability
/api/v1/newsletter-status-queries
/api/v1/newsletter-preferences
/api/v1/reservations

Do not embed an absolute Flask hostname, machine name, IP address, or port in
production browser source.

Do not add Axios or another HTTP client.


## INT01-02 — local development proxy

Local development uses the Vite development server to proxy /api requests to
the locally running Flask service.

The Flask proxy target must be supplied by environment/configuration rather
than hard-coded into production or committed machine-specific configuration.

Use the smallest clear development-only environment/configuration mechanism
consistent with the current Vite setup.

Do not expose the Flask origin to browser application code merely to configure
the development proxy.

Do not add Flask CORS solely for local Version-1 development.

Browser calls must remain relative /api/... calls.


## INT01-03 — test/database isolation

Live Prompt-24 integration verification must use the existing disposable,
nonproduction PostgreSQL 18.3 testing infrastructure and the approved Flask
application-role boundary.

Do not run Prompt-24 mutation tests against a production or production-like
database.

Do not grant the application direct reservation/assignment read or business
DML privileges.

Privileged database inspection is permitted only through existing approved
test/verifier infrastructure for integration evidence.


## INT01-04 — seed/reset

Do not create a browser-accessible, Flask, or production reset endpoint.

Use or minimally extend existing approved database/backend test initialization,
fixture, verifier, and cleanup mechanisms to create deterministic integration
state.

Any controlled settings/hours/capacity/data modification used by testing must
be test-owned and restored or removed afterward.


## INT01-05 — owned process/resource lifecycle

Prompt-24 verification may coordinate disposable PostgreSQL, Flask, Vite, and
locally installed browsers.

Every database, process, listener, profile, marker, temporary directory, or
generated artifact created for testing must have durable task ownership.

Never stop or delete a process/resource whose ownership is ambiguous.

Ambiguous ownership must cause cleanup refusal and visible failure.

Final cleanup must remove every Prompt-24-created object and prove the expected
ports/resources are absent.


# Authoritative sources and precedence

Use the current committed repository as the authoritative implementation state.

Read and apply, in this order:

1. repository-root AGENTS.md and any applicable nested AGENTS.md;
2. docs/SRS(1).pdf;
3. docs/Rubric(1).pdf;
4. approved Project Requirements Addendum v2.2.1;
5. approved least-to-most implementation roadmap v1.1.1;
6. approved/frozen PostgreSQL design and implementation artifacts;
7. frozen database/POSTGRESQL_CONTRACT_FOR_FLASK.md;
8. approved/frozen API-01 through API-09 artifacts;
9. especially the current approved API-02 Flask REST Contract;
10. backend/API09_VERIFICATION_REPORT.md;
11. current committed backend implementation and backend/TestInstructions.md;
12. database/TestInstructions.md and existing database test infrastructure;
13. approved/frozen REACT-01 architecture;
14. approved/frozen REACT-02 Reservation and Newsletter UX;
15. approved/frozen REACT-03 Visual System and React Test Strategy;
16. approved/frozen REACT-04 implementation report;
17. approved/frozen REACT-05 implementation report;
18. current committed frontend implementation and frontend/TestInstructions.md;
19. this Prompt 24.

Use actual repository filenames and current approved versions discovered during
Phase 0.

Do not reconstruct requirements from old chat text.

Do not weaken or reinterpret a frozen contract merely because live integration
would be easier another way.

If authoritative artifacts materially conflict, stop with BLOCKED and report
the exact conflict.


# Phase 0 — mandatory read-only baseline verification

Before modifying anything:

1. Record:
   - current branch;
   - full HEAD;
   - upstream relation;
   - recent relevant Git history;
   - git status;
   - Git-index state.

2. Confirm:
   - worktree is clean;
   - HEAD includes approved REACT-05 commit
     92e76910249eda01af51341d0c5bd449cc42b54e;
   - REACT-05 is documented APPROVED AND FROZEN;
   - Prompt 24 is committed and is the next authorized prompt;
   - nothing from Prompt 25 has started.

3. Verify the existing backend:
   - still exposes exactly OP-01 through OP-07;
   - still matches frozen API-02;
   - passes its existing focused/full tests before integration changes;
   - has no unapproved route or privilege change.

4. Verify the current frontend:
   - passes the complete REACT-05 suite before changes;
   - retains the frozen dependency versions and package-lock;
   - retains the operation-injection boundary;
   - currently has no production/live Flask adapter.

5. Extract the CURRENT exact API-02 definitions for:
   - OP-01 GET /api/v1/reservation-context;
   - OP-02 GET /api/v1/reservation-availability;
   - OP-03 POST /api/v1/newsletter-status-queries;
   - OP-04 POST /api/v1/newsletter-preferences;
   - OP-05 POST /api/v1/reservations.

6. Confirm exact:
   - request locations;
   - request fields;
   - methods;
   - success statuses;
   - response fields;
   - error-envelope structure;
   - public error codes;
   - retryable;
   - outcome_unknown;
   - no-store behavior.

7. Inspect existing:
   - Vite configuration;
   - frontend/src/api/;
   - operation injection/default client;
   - frontend scripts;
   - backend startup/configuration procedure;
   - backend process ownership helpers;
   - disposable PostgreSQL test harness;
   - application-role setup;
   - database test verifier/reset procedures;
   - current TestInstructions files.

8. Identify actual ports/environment names currently used by approved backend
   and test procedures. Do not invent a second backend startup convention merely
   for Prompt 24.

9. Record exact current baseline test counts before changing files.

If the repository is dirty, approval is missing, package-lock unexpectedly
differs, or the live API differs materially from frozen API-02, stop:

BLOCKED


# Part A — preserve frozen architecture and scope

Do not redesign REACT-05.

Preserve:

- five routes;
- shell/navigation;
- Gallery/lightbox;
- Home/Menu/About content;
- visual tokens;
- responsive behavior;
- accessibility behavior;
- reservation component boundaries;
- standalone Home newsletter placement;
- 400 ms newsletter lookup behavior;
- stale-response protection;
- immutable mutation snapshots;
- error/retry/outcome-unknown UX;
- confirmation behavior;
- guarded browser-process helper;
- existing tests.

Components must continue to consume operation methods rather than calling fetch
directly.

Production HTTP transport must live behind the existing operation boundary.

Do not add:

- Axios;
- React Query/TanStack Query;
- Redux/Zustand;
- form libraries;
- validation libraries;
- browser automation frameworks;
- CORS middleware;
- persistence in localStorage/sessionStorage/IndexedDB;
- service workers;
- caching;
- reservation lookup;
- cancellation/modification/rescheduling;
- table selection;
- authentication;
- admin UI.

Do not change dependency versions.

If a dependency change appears necessary, stop for approval.


# Part B — production native-fetch operation adapter

Create the smallest production adapter needed for OP-01 through OP-05.

A preferred organization is a small file under frontend/src/api/, but preserve
existing repository conventions if an equally small approved structure already
exists.

Requirements:

1. Production application startup/default operation injection must use the live
   adapter.

2. Existing tests must remain able to inject mock/MSW operation clients.

3. Mock fixtures must not become production authority.

4. The production bundle must not import mock contract fixtures merely to
   determine business outcomes.

5. Use native fetch only.

6. Use only same-origin relative paths.

7. OP-02 query values must be URI encoded and use only:
   - local_date;
   - party_size.

8. OP-03/OP-04/OP-05 must send the exact frozen JSON bodies and
   Content-Type: application/json.

9. Do not add client-generated:
   - customer IDs;
   - reservation IDs;
   - table choices;
   - fingerprints;
   - idempotency keys;
   - duration;
   - end time;
   - availability assertions;
   - capacity facts;
   - restaurant timezone.

10. A successful HTTP response returns the exact parsed public response needed
    by the existing operation boundary.

11. A contract-defined non-success response must preserve:
    - HTTP status;
    - error.code;
    - error.retryable;
    - error.outcome_unknown;
    - fields and field codes where supplied.

12. React must continue branching on stable contract semantics rather than API
    message text.

13. Malformed/non-JSON/unexpected protocol responses are integration defects.
    Do not reinterpret them as a customer validation/business outcome.

14. Do not leak raw response bodies, PII, URLs containing PII, stack traces,
    or internal transport details into the UI or browser console.


# Part C — transport-failure semantics

Preserve frozen REACT-02 behavior when native fetch itself fails.

For OP-01, OP-02, and OP-03:

- transport failure is a read failure;
- it is safe for the user to explicitly repeat the read;
- do not automatically retry;
- later snapshots may differ.

For OP-04 and OP-05:

- a native-fetch rejection after attempting dispatch does not prove the
  mutation did not reach Flask;
- therefore use the existing conservative mutation-outcome-unknown UX unless
  the client can actually prove dispatch never occurred;
- do not fabricate a Flask/public API error code to represent a browser-local
  transport event;
- keep transport classification client-local;
- retain the exact immutable mutation snapshot for explicit recovery;
- do not automatically retry;
- do not claim failure when commit certainty is unknown.

An actual HTTP response from Flask always uses the authoritative API-02
retryable/outcome_unknown classification.

Do not infer commit state from HTTP timing alone.


# Part D — development Vite proxy

Configure Vite development integration so browser /api requests proxy to the
approved locally running Flask target.

Requirements:

- target supplied by development environment/configuration;
- no production absolute API URL;
- no machine-specific committed path;
- no credentials in frontend configuration;
- no CORS requirement for normal local development;
- proxy only the intended /api namespace;
- preserve ordinary Vite history fallback/static routes;
- do not proxy Gallery/static assets to Flask.

If the target is absent, behavior must fail clearly or leave the proxy
unconfigured; do not silently target an unrelated server.

Document the exact environment variable/configuration name selected.


# Part E — live OP-01 and Home current hours

Connect OP-01 first.

Reservations:

- use live Flask reservation context;
- retain all REACT-05 loading, blocked, retry, date-bound, policy, timezone,
  duration, interval, and maximum-party behavior;
- do not use mock context as production fallback.

Home:

- CurrentHours must consume live OP-01 hours;
- PostgreSQL/Flask is authoritative for current hours;
- do not continue presenting a hard-coded schedule as authoritative current
  hours after integration;
- on live context failure, show the frozen nontechnical unavailable/retry
  experience rather than fabricating current hours.

Do not calculate current restaurant business rules from browser time.

Verify a controlled test-owned recurring-hours/configuration change is reflected
through OP-01 without React source-code modification, then restore the test
state.


# Part F — live OP-03 and OP-04 newsletter integration

After OP-01 works, connect newsletter operations.

Verify through the actual Vite proxy -> Flask -> PostgreSQL path:

OP-03:
- known matched identity;
- not_found identity;
- current Boolean;
- identity conflict;
- middle-initial conflict where applicable;
- no persistence side effect;
- stale/400 ms/dirty-choice behavior remains React-owned and unchanged.

OP-04:
- unknown identity + subscribed:true creates the approved customer/preference
  state;
- matched customer can change true -> false and false -> true;
- same-state request remains safe/idempotent;
- unknown identity + false produces the exact approved
  no_customer_no_change behavior;
- identity conflicts remain safe;
- returned Boolean is authoritative.

Use unique Prompt-24 test-owned identities.

Do not use a real person's information.

Verify PostgreSQL effects using only approved privileged test/verifier
procedures, never by broadening the Flask application role.

Verify no confirmation email, phone value, or unnecessary PII is persisted
outside approved fields.


# Part G — live OP-02 availability integration

Connect live availability only after the live context path is proven.

Verify:

- exact local_date/party_size query;
- API order is preserved;
- every returned legitimate slot is rendered;
- unavailable slots remain visible and disabled;
- empty/free/partially unavailable/fully unavailable controlled scenarios
  where current existing fixtures make them deterministic;
- no slot generation or sorting moves into React;
- no client capacity calculation;
- no table choice;
- date/party edits still invalidate prior availability;
- stale response suppression still works;
- a later availability snapshot can differ legitimately.

Use controlled, test-owned PostgreSQL state.

Where a deterministic full/unavailable scenario requires fixture setup, use
existing approved test/database mechanisms rather than adding production
backdoors.


# Part H — live OP-05 reservation integration

After OP-02 is proven, connect OP-05.

Verify a complete browser-driven reservation through:

React
-> Vite same-origin /api proxy
-> Flask
-> approved PostgreSQL application role
-> PostgreSQL booking routine
-> Flask public confirmation
-> React ReservationConfirmationView.

Verify:

- selected server slot facts are submitted unchanged;
- required structured customer fields;
- email confirmation;
- optional phone;
- exact newsletter_action;
- duplicate-click suppression;
- immutable snapshot;
- Flask/PostgreSQL final authority;
- created response;
- public reservation reference remains a JSON string;
- stored display spelling is authoritative;
- local and canonical interval facts come from Flask;
- assigned public table number(s) come from Flask;
- current newsletter Boolean comes from Flask;
- no internal IDs/fingerprint/capacity/allocation detail appears in UI.

Using privileged TEST verification only, prove the successful request produced
the expected:

- customer state;
- reservation row;
- one-or-more reservation-table assignment rows;
- newsletter state where applicable.

Do not query reservation/assignment tables through the production Flask
application role.


# Part I — reservation failure and recovery integration

Exercise representative live failures using safe controlled test data.

At minimum verify where deterministically inducible:

- validation_failed from Flask;
- customer_identity_conflict;
- middle_initial_conflict;
- reservation_overlap;
- reservation_unavailable;
- service/temporary failure where existing approved test seams permit it;
- fully unavailable state through OP-02;
- transport/read failure;
- mutation transport ambiguity.

For reservation_unavailable:

- selected slot clears;
- stale availability is invalidated;
- user refreshes/reselects;
- identical OP-05 retry is not offered.

For reservation_overlap:

- preserve useful customer data;
- require another time;
- expose no existing reservation details.

For a mutation transport failure:

- retain/lock the exact snapshot;
- present outcome unknown;
- do not claim failure;
- after Flask is safely restored, explicit identical recovery resubmits exactly
  the original body.

A recovery repeat may legitimately produce either:

- a successful new result if the first request never committed; or
- exact_retry if it committed and confirmation was lost.

Do not force one outcome artificially.

Do not create a reservation-query endpoint.

Do not add new backend fault-injection behavior unless an existing approved
test-only seam already provides it.

If a rare API-02 server outcome cannot be safely induced live without changing
the frozen backend, retain its existing exhaustive mocked coverage and report
the live limitation accurately rather than weakening the backend boundary.


# Part J — exact retry and duplicate-effect proof

Perform at least one controlled exact ordinary OP-05 resubmission using the
same approved booking facts.

Verify:

- second successful reconstruction uses API-02's exact_retry behavior where the
  frozen backend returns it;
- no second logical reservation is created;
- no duplicated table assignments are created;
- booking-linked newsletter action is not replayed after exact retry;
- returned current newsletter state remains authoritative.

Use database evidence only through approved test-verifier authority.

Do not generate or expose a client idempotency key.


# Part K — cross-layer integration testing

Add the smallest useful automated frontend/integration coverage without adding
a browser automation framework.

At minimum add/update tests for:

1. live-adapter exact methods/paths/query/body behavior;
2. success JSON handling;
3. API-02 error-envelope preservation;
4. malformed/protocol-failure handling;
5. safe read transport failure;
6. conservative OP-04 transport ambiguity;
7. conservative OP-05 transport ambiguity;
8. production App defaulting to live operations while tests remain injectable;
9. Vite proxy configuration behavior;
10. Home CurrentHours server-authority behavior.

Preserve all 141 REACT-05 tests.

Do not replace exhaustive mocked error-state tests with fragile live tests.

Live cross-layer verification may use the existing guarded PowerShell/CDP
procedures and locally installed browsers without adding Playwright, Cypress,
Selenium, Puppeteer, or another framework.


# Part L — full-stack PostgreSQL verification environment

Use the approved disposable PostgreSQL 18.3 test infrastructure.

The integrated environment must establish, in order:

1. test-owned disposable PostgreSQL;
2. approved database migrations/seed/reset state;
3. approved Flask application-role credentials/configuration;
4. Flask process;
5. OP-07 readiness proof;
6. Vite process configured to proxy /api to that Flask instance;
7. browser verification.

Record exact process/resource ownership.

Do not place passwords in:

- command history where avoidable;
- committed files;
- screenshots;
- logs;
- browser-visible environment;
- review artifacts.

Use existing secure test credential procedures.

The application must connect through the existing least-privilege role.


# Part M — database-effect evidence

For test-owned identities and reservations, verify direct PostgreSQL effects
through the approved test verifier/admin boundary.

At minimum capture factual evidence for:

Newsletter:
- unknown subscribed:true -> one customer with true preference;
- later false -> same customer preference false;
- unknown false -> no customer created.

Reservation:
- one customer;
- one logical reservation;
- required assignment row(s);
- no duplicate logical reservation after exact retry;
- no overlapping/partial assignment caused by the test.

Do not expose test-only internal IDs in the customer UI merely because the
integration harness can inspect them.


# Part N — integration timing evidence

Collect descriptive cross-layer timing for representative successful live:

- OP-01;
- OP-02;
- OP-03;
- OP-04;
- OP-05.

Record:

- environment;
- measurement method;
- small representative sample count;
- observed timings;
- whether any ordinary operation exceeded two seconds.

Do not claim final NFR-01/NFR-02 compliance from Prompt 24.

Final performance/compatibility acceptance remains the later verification gate.

If a live ordinary form mutation materially exceeds the SRS two-second
expectation, report it as a risk/defect; do not weaken correctness,
transactions, locking, or allocation to force a timing pass.


# Part O — browser verification

Perform practical live full-stack verification using locally installed browsers
already available.

At minimum use Chrome and Edge if still installed.

Verify live:

- Home CurrentHours;
- Home newsletter;
- Reservations context;
- availability;
- fully unavailable state where controlled;
- reservation success;
- confirmation;
- representative ordinary error;
- transport/read failure;
- mutation outcome-unknown/recovery;
- no horizontal overflow introduced by live content.

Use representative 390 px and desktop width at minimum for changed live
behavior.

Do not claim Safari was tested on Windows.

Actual Safari evidence remains required before Prompt 25 approval in a
Safari-capable environment.

Do not add a browser automation dependency.


# Part P — frontend/TestInstructions.md

Update frontend/TestInstructions.md for Prompt 24.

Preserve all existing REACT-04/05 instructions and safeguards.

Add a clearly bounded live-integration section covering:

- prerequisites;
- PostgreSQL 18.3 test environment;
- test/demo isolation;
- backend configuration;
- Flask start/readiness;
- Vite proxy environment;
- Vite start;
- live Home current-hours verification;
- live newsletter verification;
- live availability verification;
- live reservation verification;
- PostgreSQL-effect verification;
- error/network/recovery verification;
- focused integration tests;
- complete frontend test suite;
- coverage;
- build;
- npm audit;
- timing evidence;
- Chrome/Edge checks;
- rerunning in the same shell;
- rerunning in a fresh shell;
- recovery after ordinary failure;
- recovery after interruption;
- ownership mismatch/refusal behavior;
- final cleanup.

Reference existing backend/database TestInstructions where appropriate rather
than copying privileged database procedures inaccurately.

Do not weaken their ownership safeguards.


# Part Q — required final cleanup

The LAST step of the documented live integration workflow must clean up every
Prompt-24-created object.

It must:

1. stop only the proven-owned browser processes;
2. verify recorded browser profile processes and CDP ports are gone;
3. stop only the proven-owned Vite process;
4. stop only the proven-owned Flask process;
5. invoke the approved guarded database/backend cleanup for the Prompt-24
   disposable PostgreSQL environment;
6. remove only Prompt-24-owned:
   - profiles;
   - markers;
   - temporary files;
   - logs;
   - screenshots/evidence not intentionally retained;
   - coverage;
   - dist;
   - Vite cache;
   - integration harness output;
   - disposable database files/resources;
7. restore environment variables modified by testing;
8. verify expected Vite/Flask/CDP/PostgreSQL test listeners are closed;
9. verify no test-created customer/reservation/database remains;
10. verify package.json, package-lock.json, committed Gallery assets, source
    files, and user resources are preserved;
11. finish with a clean generated-artifact/resource check.

If ownership is ambiguous, FAIL instead of deleting or terminating.


# Part R — implementation report

Create:

docs/react-implementation/
Cafe_Fausse_REACT06_Live_Flask_Integration_Implementation.md

Mark it:

PROPOSED — NOT YET APPROVED

Use:

Increment: REACT-06 / Prompt 24 — Live React-to-Flask Integration

Include at minimum:

1. actual baseline full HEAD;
2. approval state;
3. approved INT-01 strategy and approval record;
4. exact changed/created paths;
5. explicit scope/exclusions;
6. same-origin/native-fetch design;
7. Vite proxy/environment decision;
8. no-CORS rationale;
9. live adapter structure;
10. exact OP-01 through OP-05 mapping;
11. transport/error classification;
12. Home CurrentHours integration;
13. live newsletter integration;
14. live availability integration;
15. live reservation integration;
16. exact-retry integration;
17. PostgreSQL-effect evidence;
18. test/demo isolation;
19. startup order;
20. process/resource ownership;
21. automated tests;
22. complete frontend regressions;
23. backend/database regressions actually run;
24. cross-layer timing evidence;
25. Chrome/Edge live evidence;
26. TestInstructions updates;
27. restartability/interruption evidence;
28. cleanup evidence;
29. requirements/rubric/PRA/API/React traceability;
30. known limitations;
31. Safari deferral to Prompt 25;
32. asset provenance/licensing checkpoint remains INT-08;
33. Prompt 25 exclusion;
34. approval status.

Do not declare REACT-06/Prompt 24 approved.


# Part S — scope restrictions

Prompt 24 may modify frontend integration/test/documentation files needed for
the approved live connection.

Do NOT modify frozen backend/database behavior merely to make integration pass.

Specifically do not change without a new explicit approval:

- PostgreSQL schema;
- PostgreSQL migration semantics;
- routines/signatures;
- roles/grants;
- allocation rules;
- locking/concurrency rules;
- retry/idempotency semantics;
- Flask routes;
- Flask methods;
- API request/response fields;
- public error codes;
- API statuses;
- Flask transaction behavior;
- backend validation semantics;
- SRS;
- Rubric;
- PRA;
- approved/frozen design artifacts;
- Gallery source assets;
- dependency versions.

If live integration exposes a genuine backend/database/API defect, document the
exact evidence and stop with BLOCKED instead of editing that frozen layer.

Narrow integration-only test-harness reuse/configuration is allowed when it
does not alter production authority or frozen behavior.


# Part T — explicit future exclusions

Do not begin Prompt 25.

Do not perform or claim:

- final React verification gate;
- final four-browser acceptance;
- Safari acceptance;
- final NFR performance compliance;
- INT-06 concurrency gate;
- INT-07 final performance/compatibility gate;
- INT-08 final documentation/provenance/deployment completion;
- INT-09 demonstration/submission;
- final requirements/rubric acceptance.

Do not add:

- authentication;
- customer accounts;
- admin functionality;
- cancellation;
- modification/rescheduling;
- waitlist;
- payment;
- messaging;
- confirmation email/SMS;
- table selection;
- newsletter topics/history;
- reservation lookup.


# Part U — Git restrictions

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

Preserve the real Git index.

Leave all Prompt-24 implementation changes unstaged for independent review.

Review/test artifacts must not be staged or committed.


# Part V — verification gate

Before reporting completion:

1. Parse every changed PowerShell script and every added/changed PowerShell
   block in frontend/TestInstructions.md.

2. Run the complete pre-existing frontend suite and prove no REACT-05
   regression.

3. Run focused live-adapter tests.

4. Run focused Home/current-hours tests.

5. Run focused newsletter tests.

6. Run focused availability tests.

7. Run focused reservation/recovery tests.

8. Run complete frontend tests.

9. Run coverage and report:
   - statements;
   - branches;
   - functions;
   - lines.

10. Run production build.

11. Run npm audit --audit-level=low.

12. Run the applicable complete backend regression suite or the approved
    equivalent necessary to prove integration configuration did not regress
    Flask.

13. Run applicable PostgreSQL verification needed to prove the disposable
    integration environment is correct.

14. Start the complete disposable full-stack environment.

15. Verify OP-07 readiness.

16. Verify live Home OP-01/current-hours.

17. Verify live OP-03/OP-04 newsletter workflow.

18. Verify live OP-02 availability workflow.

19. Verify live OP-05 reservation workflow.

20. Verify controlled PostgreSQL effects.

21. Verify exact retry/no duplicate logical effect.

22. Verify representative live error paths.

23. Verify a read transport failure.

24. Verify a mutation transport-ambiguity/recovery path without falsely
    claiming actual commit ambiguity if that was not induced.

25. Record descriptive cross-layer timing.

26. Perform Chrome live verification.

27. Perform Edge live verification.

28. Execute the complete final cleanup.

29. Prove cleanup/restartability by rerunning the integration environment after
    a clean shutdown.

30. Demonstrate recovery from an interrupted/partially completed integration
    run using durable ownership evidence.

31. Demonstrate malformed/mismatched ownership evidence is refused without
    deleting or stopping unrelated resources.

32. Verify no Prompt-24 process/listener/profile/test database remains.

33. Verify environment variables changed by testing were restored.

34. Verify frontend/package-lock.json is unchanged.

35. Verify no backend/database/API/frozen-design/Gallery-source artifact was
    unintentionally changed.

36. Verify production source contains:
    - native fetch;
    - relative /api paths;
    - no production absolute Flask target;
    - no CORS workaround;
    - no PII browser persistence.

37. Run git diff --check.

38. Verify the real Git index is unchanged.

39. Verify staged paths = 0.

40. Verify HEAD remains the Phase-0 baseline.

41. Confirm nothing was committed or pushed.

Do not silently skip a required check.

If a required check cannot run, state exactly why and do not report it as
passed.


# Completion response

Lead with exactly one of:

READY FOR REACT-06 LIVE INTEGRATION REVIEW

or

BLOCKED

If ready, report concisely:

- baseline full HEAD;
- Phase-0 result;
- exact changed/created paths;
- INT-01 integration configuration summary;
- native-fetch adapter summary;
- Vite proxy/environment summary;
- explicit no-CORS confirmation;
- Home live-current-hours result;
- live OP-03 result;
- live OP-04 result;
- live OP-02 result;
- live OP-05 result;
- exact-retry result;
- PostgreSQL-effect evidence summary;
- live error/recovery summary;
- transport ambiguity result;
- focused test counts;
- full frontend test count;
- backend regression result;
- PostgreSQL verification result;
- coverage;
- production build;
- npm audit;
- Chrome live result;
- Edge live result;
- timing measurements;
- TestInstructions/restartability result;
- final cleanup evidence;
- package-lock status;
- scope-integrity result;
- git diff --check result;
- Git-index hash/status;
- staged-path count;
- HEAD;
- implementation-report path and PROPOSED status;
- known limitations/deferred Safari evidence;
- confirmation nothing was staged, committed, or pushed.

Do not generate an independent-review diff unless requested after ChatGPT
reviews the completion report.

Do not begin Prompt 25.
