Yes. With your latest refinements, I would consolidate the project around four principles:

**fixed SRS/rubric → approved supplemental requirements → configurable business rules → incremental implementation with tests.**

I also agree with your reservation-time control idea. The React reservation form should **not allow arbitrary time entry**. It should present only valid/available dates and time slots obtained from the application's reservation rules/API. That makes the configuration problem much cleaner: users never get an opportunity to submit an unsupported interval in normal UI use. The backend should still validate submitted values because client-side controls cannot be treated as a security or integrity boundary.

For the gallery, **please upload the actual images, not merely their filenames**, but you do not need to upload them yet. The best time is before we begin the React UI/design phase. Actual images will let me account for aspect ratios, orientations, resolution, logical grouping, alt text, gallery layout, and lightbox behavior. The SRS explicitly requires high-resolution Gallery imagery and a lightbox.

Below is the consolidated plan I recommend using from beginning to end.

**1. Project governing rules**

These should control everything we do.

**Fixed authoritative requirements**

SRS.pdf and Rubric.pdf remain the authoritative baseline documents.

We **do not change an explicit SRS requirement** merely because another approach seems preferable.

The SRS explicitly establishes React/JSX, Flask, PostgreSQL, responsive Flexbox/Grid, reservations, newsletter signup, and the principal website pages.

The rubric encourages AI-assisted development and grades the resulting functionality and quality rather than requiring a particular proportion of manually written code.

**Supplemental requirements**

Where the SRS is silent or insufficiently precise for deterministic implementation, we identify the gap and present alternatives.

You choose the rule.

The approved decision is recorded in a:

**Project Requirements Addendum**

For example:

-   reservation interval = 30 minutes;
-   reservation duration = 90 minutes;
-   advance-booking window = 60 days.

These become project requirements without altering the supplied SRS.

**Configuration rule**

Changeable **restaurant/business policies** should ordinarily be configurable rather than hard-coded.

Examples:

-   reservation interval;
-   reservation duration;
-   maximum advance-booking period;
-   reservation cutoff rules;
-   party-size limits if we introduce them.

My default preference will be:

**PostgreSQL configuration/data → business-operational settings**

**Flask configuration/environment → technical/deployment settings**

Explicit SRS constants should not be made configurable in a way that permits violating the SRS.

**Reservation-time UI rule**

The user should not type an arbitrary reservation time.

The eventual reservation UI should work conceptually like:

**choose date → application obtains valid/available slots → display selectable slots → user chooses one**

For example, if configured for 30-minute intervals:

-   5:00 PM
-   5:30 PM
-   6:00 PM
-   6:30 PM
-   …

If configured for 15 minutes:

-   5:00 PM
-   5:15 PM
-   5:30 PM
-   5:45 PM
-   …

Only legitimate slots should appear.

Flask must nevertheless independently validate every submitted slot.

**2. Testing is now part of the implementation scope**

I strongly agree with adding it.

Even though the rubric says extensive testing is not expected, nothing prevents us from having a sensible automated test suite; in fact, it will make AI-assisted incremental development much safer. The project instructions say significant testing is not expected, rather than prohibiting it.

I recommend testing **throughout**, not bolting it on at the end.

Our cycle should become:

**design small capability → implement → unit test → integration test where applicable → verify → proceed**

Conceptually, I would expect:

-   **Database tests/verification** — schema, constraints, transactions, collision/overlap behavior.
-   **Flask unit tests** — validation and business/service logic.
-   **Flask API integration tests** — endpoint + PostgreSQL behavior.
-   **React component tests** — forms, states, controls, rendering.
-   **React/API integration tests** — frontend behavior with API responses.
-   **Final end-to-end verification** — reservation and newsletter operations reaching PostgreSQL.

For Python/Flask, pytest is the natural choice. For React, we'll choose the appropriate React testing tooling when we establish the frontend environment.

We will also keep tests **proportional to an academic project** rather than trying to build a production-scale QA framework.

**3. Recommended architecture sequence**

Your original order remains unchanged:

**Phase A — Requirements and planning**

↓

**Phase B — PostgreSQL**

↓

**Phase C — Flask REST API**

↓

**Phase D — React/JSX**

↓

**Phase E — End-to-end integration**

↓

**Phase F — Rubric/SRS/Addendum compliance audit**

↓

**Phase G — Documentation and demonstration**

But each implementation layer gets a verification gate:

**design → approve → implement → test → freeze contract → next layer**

That is the least-to-most strategy I would use.

**4. Master instruction to reuse throughout the project**

You can prepend this to major prompts:

Use SRS.pdf and Rubric.pdf as the fixed authoritative baseline requirements for the Café Fausse project.

Also use all supplemental requirements and design decisions that I have explicitly approved and that are recorded in the Project Requirements Addendum.

Do not contradict, weaken, replace, or reinterpret an explicit SRS or rubric requirement.

Where implementation requires a business rule that the SRS does not explicitly define, identify the gap, present reasonable alternatives and a recommendation, and obtain my approval before treating the decision as a project requirement.

Supplemental business rules that may reasonably change should be configurable rather than hard-coded where practical.

Prefer PostgreSQL configuration/data for changeable restaurant/business rules and Flask configuration/environment variables for technical/deployment configuration.

For reservations, the React UI should present only valid reservation dates/times generated from the approved reservation rules rather than allowing arbitrary time entry. Flask must independently validate submitted values.

Use a least-to-most implementation strategy.

Implement only the requested stage and do not prematurely implement later architectural layers.

Add appropriate unit and integration tests as each capability is implemented.

Preserve previously approved interfaces and architectural decisions unless a defect or newly approved supplemental requirement requires a change.

Maintain traceability from:

**SRS/Rubric → Project Requirements Addendum → PostgreSQL → Flask → React → automated verification → demo evidence.**

**PHASE A — Requirements and planning**

**Prompt 0 — Establish the project baseline**

Read Rubric.pdf and SRS.pdf completely.

Do not generate code.

We are developing the Café Fausse application using:

1.  PostgreSQL database
2.  Python Flask REST API
3.  React with JSX UI

Implementation order is strictly:

**PostgreSQL → Flask API → React/JSX UI → integration**

I want to use a least-to-most implementation strategy.

Treat the supplied SRS and rubric as fixed authoritative documents.

Establish a separate **Project Requirements Addendum** for supplemental business rules, refinements, constraints, and design decisions that I approve during implementation.

Analyze the project and produce:

-   functional requirements inventory;
-   non-functional requirements inventory;
-   PostgreSQL requirements;
-   Flask/backend requirements;
-   React/UI requirements;
-   integration requirements;
-   deployment/documentation requirements;
-   rubric/demo requirements;
-   requirements requiring further operational definition;
-   initial traceability structure.

Distinguish among:

-   explicit SRS requirements;
-   explicit rubric requirements;
-   implementation decisions that must still be made;
-   optional enhancements.

Do not implement anything.

**Prompt 1 — Discover underspecified business rules**

This should happen **before database design**.

Review the SRS specifically for operational/business rules that must be resolved before deterministic implementation.

Do not generate code and do not silently choose values.

First identify requirements that are explicitly defined by the SRS and therefore must be preserved.

Then identify important implementation details the SRS does not define.

Pay particular attention to:

-   reservation start-time intervals;
-   reservation duration;
-   valid reservation dates;
-   earliest and latest reservation start;
-   behavior near restaurant closing;
-   maximum advance-booking window;
-   same-day booking restrictions, if any;
-   party-size restrictions, if any;
-   definition of table availability;
-   overlapping reservations;
-   duplicate customer handling;
-   duplicate newsletter signup handling;
-   cancellation behavior if implementation requires it;
-   any other rule needed for deterministic behavior.

For each unspecified item:

1.  explain why the decision is necessary;
2.  provide reasonable alternatives;
3.  recommend an option;
4.  identify whether it should be configurable;
5.  recommend PostgreSQL configuration, Flask configuration, or fixed behavior;
6.  identify database/API/UI impact;
7.  identify tests that will eventually be needed.

Do not add any choice to the Project Requirements Addendum until I approve it.

This is where we would discuss your **15-minute vs. 30-minute reservation-slot** decision and 60/90/120-minute duration.

**Prompt 2 — Record approved supplemental requirements**

After you decide the outstanding rules:

Record all business-rule decisions I have approved in the **Project Requirements Addendum**.

Do not generate code.

Give every supplemental requirement a stable ID.

For each requirement record:

-   requirement ID;
-   description;
-   initial/default value;
-   whether configurable;
-   permitted values or validation constraints where appropriate;
-   source/decision rationale;
-   SRS requirements it refines;
-   expected database impact;
-   expected Flask impact;
-   expected React impact;
-   expected testing impact.

Verify that none conflict with an explicit SRS or rubric requirement.

**Prompt 3 — Build the least-to-most roadmap**

Using the SRS, rubric, and approved Project Requirements Addendum, create the complete least-to-most implementation roadmap.

Do not generate code.

Keep the required architecture order:

**PostgreSQL → Flask → React → integration**

Divide each architectural phase into small independently testable increments.

For every increment provide:

-   objective;
-   requirements addressed;
-   dependencies;
-   artifacts produced;
-   unit tests required;
-   integration tests required;
-   manual verification where useful;
-   completion criteria;
-   approval checkpoint.

Avoid unnecessary enterprise complexity.

**PHASE B — PostgreSQL**

**Prompt 4 — Derive the persistent data requirements**

Begin only the PostgreSQL phase.

Do not write SQL.

Determine every piece of persistent data required by:

-   SRS;
-   rubric where applicable;
-   Project Requirements Addendum.

Analyze:

-   customers;
-   reservations;
-   newsletter subscribers;
-   restaurant tables;
-   configurable reservation settings;
-   reservation start/end information;
-   number of guests;
-   table availability.

Identify entities, attributes, required/optional values, relationships, cardinalities, uniqueness rules, and lifecycle rules.

Identify any mismatch between UI-required information and the SRS's stated minimum database fields.

Recommend the smallest normalized model that supports all approved requirements.

Do not generate SQL.

The SRS, for example, requires Number of Guests in the form even though the minimum Reservations table description does not explicitly list it, so this analysis matters.

**Prompt 5 — Design the conceptual database model**

Using the approved persistent-data analysis, create the conceptual data model.

Do not generate SQL.

Define:

-   entities;
-   attributes;
-   relationships;
-   cardinalities;
-   business constraints.

Explain how configurable restaurant business rules will be represented.

Explain how table availability and overlapping reservations will be determined using the approved reservation duration.

Map each major entity and relationship to the appropriate SRS or Project Requirements Addendum IDs.

**Prompt 6 — Design the logical PostgreSQL schema**

Convert the conceptual model into an approved logical PostgreSQL schema.

Do not generate SQL.

Define:

-   tables;
-   columns;
-   PostgreSQL data types;
-   primary keys;
-   foreign keys;
-   unique constraints;
-   check constraints;
-   nullability;
-   defaults;
-   indexes.

Define any configuration/settings table required for changeable restaurant policies.

Explain which rules are enforced by PostgreSQL and which remain Flask responsibilities.

Identify how the schema prevents invalid or inconsistent reservations.

**Prompt 7 — Design reservation transaction/concurrency behavior**

Using the approved database schema, design reservation creation transactionally.

Do not generate code.

Explain how the application will:

-   accept an approved start slot;
-   calculate the occupied reservation interval;
-   identify tables without overlapping reservations;
-   randomly choose an available table;
-   prevent two simultaneous requests from obtaining the same table;
-   create or reuse customer data;
-   save the reservation;
-   detect lack of availability;
-   roll back failed operations.

Explicitly address concurrent reservation requests.

Prefer database integrity protection where practical.

Identify database unit/integration tests required.

The SRS requires random assignment among 30 tables and protection against double/overbooking.

**Prompt 8 — Implement PostgreSQL**

First code-generation prompt.

The database design is approved.

Implement only the PostgreSQL layer.

Do not generate Flask or React code.

Create the database artifacts needed to:

-   initialize the schema;
-   establish all tables;
-   establish configuration data;
-   enforce constraints;
-   establish relationships;
-   establish indexes;
-   support transactionally safe reservations;
-   provide appropriate development seed data.

Also create the database-focused automated verification appropriate to this layer.

Do not change the approved schema silently.

Provide:

-   file list;
-   file purpose;
-   exact folder placement;
-   execution sequence;
-   database setup instructions;
-   test instructions;
-   traceability summary.

**Prompt 9 — PostgreSQL verification gate**

Audit the completed PostgreSQL implementation.

Do not begin Flask.

Verify with automated tests or repeatable verification:

-   valid configuration values;
-   invalid configuration values;
-   customers;
-   newsletter storage;
-   reservations;
-   foreign keys;
-   unique/check constraints;
-   overlapping reservations;
-   duplicate-booking protection;
-   available-table determination;
-   full-capacity behavior;
-   rollback behavior;
-   concurrent booking integrity.

Correct defects.

Then define and freeze the **database contract** that Flask may rely upon.

**PHASE C — Flask REST API**

**Prompt 10 — Derive backend operations**

Begin the Flask phase.

Do not generate code.

Using the frozen PostgreSQL contract, identify every backend operation required.

Include:

-   obtaining valid reservation dates/times;
-   obtaining available slots;
-   reservation creation;
-   newsletter signup;
-   required validation;
-   business configuration retrieval where needed.

For each operation define:

-   input;
-   validation;
-   business rule;
-   database interaction;
-   output;
-   expected failure cases;
-   unit-test needs;
-   integration-test needs.

**Prompt 11 — Design the Flask REST contract**

Design the REST API for the approved backend operations.

Do not generate code.

For each endpoint specify:

-   HTTP method;
-   route;
-   request;
-   validation;
-   response;
-   HTTP status codes;
-   expected errors;
-   database interaction;
-   associated requirement IDs.

The React reservation UI should be able to request legitimate reservation dates/time slots rather than calculating arbitrary time choices itself.

Do not create endpoints that are not justified by requirements.

The SRS explicitly expects Flask API endpoints and RESTful client/server communication.

**Prompt 12 — Design Flask architecture and test structure**

Design the Flask project architecture.

Do not generate code.

Keep clear separation among:

-   application/configuration;
-   routes;
-   validation;
-   services/business logic;
-   PostgreSQL access;
-   error handling.

Also define the pytest structure for:

-   service/unit tests;
-   validation tests;
-   API tests;
-   PostgreSQL integration tests.

Keep the project structure understandable and proportional to the assignment.

**Prompt 13 — Implement Flask foundation**

Implement the Flask foundation only.

Do not implement React.

Include:

-   application startup;
-   environment/configuration;
-   PostgreSQL connectivity;
-   common response/error behavior;
-   route structure;
-   testing infrastructure.

Add tests proving that Flask starts correctly and communicates with the development/test PostgreSQL environment.

**Prompt 14 — Implement reservation-slot discovery**

Implement the smallest reservation capability first: determining valid and available reservation slots.

Use the configurable approved business rules.

The API should expose only valid reservation opportunities based on:

-   restaurant hours from the SRS;
-   approved reservation interval;
-   approved reservation duration;
-   existing bookings;
-   approved advance-booking rules.

Add unit tests for the slot-calculation logic and integration tests against PostgreSQL.

Do not implement React.

**Prompt 15 — Implement reservation creation**

Implement complete reservation creation.

It must:

-   independently validate the selected slot;
-   validate customer/reservation input;
-   calculate reservation occupancy;
-   determine valid table availability;
-   randomly assign an available table;
-   prevent overlapping/double bookings;
-   persist data transactionally;
-   return success or appropriate failure.

Add unit and API/database integration tests for normal, boundary, invalid, unavailable, and concurrency-related cases.

Do not implement React.

**Prompt 16 — Implement newsletter signup**

Implement newsletter signup.

Include:

-   email validation;
-   persistence;
-   duplicate behavior;
-   error behavior.

Add unit tests and PostgreSQL-backed API integration tests.

Do not implement React.

**Prompt 17 — Flask verification gate**

Audit the complete Flask layer against the SRS, Project Requirements Addendum, and frozen PostgreSQL contract.

Run the automated test suite.

Verify:

-   slot generation;
-   configurable reservation intervals;
-   configurable reservation duration;
-   valid/invalid reservation submissions;
-   full capacity;
-   overlap protection;
-   newsletter behavior;
-   transaction rollback;
-   response consistency.

Correct defects.

Then freeze the **React-facing API contract**.

**PHASE D — React/JSX**

**Before this phase: upload the gallery images**

This is where I'd ask you to upload the actual files.

Ideally upload **all supplied gallery images**, keeping their original filenames. If there are many, a ZIP is convenient.

The actual images are better than names because we can determine:

-   landscape vs. portrait;
-   reasonable crop behavior;
-   image quality;
-   appropriate grouping;
-   thumbnail treatment;
-   lightbox behavior;
-   descriptive alt text.

**Prompt 18 — Analyze gallery assets and design React architecture**

I have supplied the project gallery images.

Do not generate React code.

Inspect the supplied image assets and design the React page/component architecture for the complete site.

Address:

-   Home;
-   Menu;
-   Reservations;
-   About Us;
-   Gallery;
-   newsletter signup;
-   navigation;
-   responsive layout;
-   Gallery lightbox;
-   reusable components.

For the Gallery, recommend appropriate categorization, thumbnail behavior, aspect-ratio handling, accessible alt text, and lightbox behavior based on the actual supplied assets.

Map every page/component to SRS and supplemental requirements.

**Prompt 19 — Design reservation UX**

Design the React reservation user experience.

Do not generate code.

The user must not enter an arbitrary reservation time.

Design a flow such as:

**select valid date → retrieve available slots from Flask → display selectable time slots → select slot → enter customer/party information → submit reservation**

Define:

-   date control behavior;
-   available-slot presentation;
-   unavailable/loading states;
-   validation;
-   confirmation;
-   fully booked behavior;
-   server/network failure behavior;
-   mobile behavior.

Ensure Flask remains authoritative for validity and availability.

**Prompt 20 — Design UI/UX and React test strategy**

Complete the UI/UX design before coding.

Define page layouts, responsive behavior, shared navigation, styling strategy using Flexbox/Grid, accessibility considerations, forms, Gallery behavior, and API interaction states.

Also define the React test plan for:

-   navigation;
-   reservation controls;
-   slot rendering;
-   validation;
-   loading/success/error states;
-   newsletter signup;
-   Gallery lightbox.

Do not generate code.

**Prompt 21 — Implement static React application**

Implement the React/JSX shell and static pages first.

Include:

-   navigation;
-   Home;
-   Menu;
-   About Us;
-   Gallery;
-   reusable layout;
-   responsive styling.

Implement the Gallery using the supplied assets, including the required lightbox.

Do not connect reservation/newsletter forms to Flask yet.

Add appropriate component tests.

**Prompt 22 — Implement reservation and newsletter UI**

Add the Reservations and Newsletter forms.

For reservations:

-   provide the date selector;
-   display API-compatible slot-selection UI;
-   do not permit arbitrary time entry;
-   add party/customer inputs;
-   implement validation and loading/success/error states.

Do not connect to the live Flask API yet unless mocked/test responses are required for component testing.

Add React tests.

**Prompt 23 — Connect React to Flask**

Connect the React UI to the frozen Flask API.

Implement:

-   available-slot retrieval;
-   reservation submission;
-   newsletter submission;
-   loading behavior;
-   validation errors;
-   full-slot behavior;
-   server errors;
-   network failures.

Add integration-oriented frontend tests where practical.

Verify that successful requests produce the expected PostgreSQL records.

**Prompt 24 — React verification gate**

Audit the React application against all UI-related SRS, rubric, and Project Requirements Addendum requirements.

Run the React test suite.

Verify:

-   five required pages;
-   navigation;
-   Gallery/lightbox;
-   reservation date/slot controls;
-   no arbitrary-time entry;
-   responsive layouts;
-   newsletter form;
-   reservation form;
-   loading/success/error states;
-   browser compatibility considerations;
-   Flexbox/Grid usage.

Correct defects before end-to-end validation.

The SRS specifically requires responsive desktop/tablet/mobile design and compatibility with Chrome, Firefox, Safari, and Edge.

**PHASE E — End-to-end verification**

**Prompt 25 — Full integration test plan and execution**

Perform end-to-end application verification.

Use the complete automated database, Flask, and React test suites plus focused integration scenarios.

Verify at minimum:

-   valid newsletter signup reaches PostgreSQL;
-   duplicate/invalid newsletter handling;
-   available reservation slots reflect configuration;
-   changing an approved configurable reservation setting changes behavior without source-code modification;
-   valid reservation reaches PostgreSQL;
-   reservation blocks overlapping use of the assigned table;
-   fully booked conditions are handled correctly;
-   invalid/manipulated reservation slot submissions are rejected by Flask even if bypassing the React UI;
-   user-facing errors are appropriate.

Report failures before making architectural changes.

That manipulated-slot test is important: the calendar/slot control improves UX, but the backend must still be authoritative.

**PHASE F — Requirements/rubric audit**

**Prompt 26 — Complete traceability audit**

Perform a complete requirements audit using:

1.  Rubric.pdf
2.  SRS.pdf
3.  the approved Project Requirements Addendum

Build a matrix:

**Requirement → PostgreSQL → Flask → React → automated test(s) → manual verification → demo evidence**

Classify each requirement:

-   fully satisfied;
-   partially satisfied;
-   not satisfied;
-   not applicable.

Identify anything preventing a score of 5 under the rubric.

Recommend only the changes required to close those gaps.

The top rubric score explicitly requires all SRS requirements, excellent UI/UX, working forms, integrated Flask/PostgreSQL functionality, database effects, and AI-development documentation.

**PHASE G — Documentation**

**Prompt 27 — README and AI-tooling documentation**

Using the actual completed project, prepare the final documentation required by the assignment.

Ensure README.md explains:

-   project purpose;
-   architecture;
-   PostgreSQL configuration;
-   configurable restaurant settings;
-   Flask environment/setup;
-   React setup;
-   dependency installation;
-   local execution;
-   database initialization;
-   running automated tests.

Prepare ai-tooling.md documenting:

-   AI tools actually used;
-   how they were used;
-   the least-to-most development approach;
-   what AI assistance worked well;
-   what did not;
-   how generated work was reviewed/tested.

Do not claim activities that did not occur.

Both files are specifically required by the project instructions.

**PHASE H — Demo preparation**

**Prompt 28 — Build the demonstration script**

Create a 5–10 minute demonstration plan that proves compliance with the rubric.

Include:

-   all required pages;
-   navigation;
-   Gallery and lightbox;
-   newsletter signup;
-   reservation slot selection;
-   successful reservation;
-   unavailable/full behavior;
-   actual PostgreSQL changes for newsletter and reservation operations;
-   responsive design;
-   key architecture and configurable-business-rule decisions;
-   brief mention of automated testing and AI-assisted implementation.

Specify exactly what should be shown in the browser, Flask/application environment, and PostgreSQL.

Map each segment to rubric criteria.

The rubric explicitly requires demonstrating the actual backend database effects rather than merely showing an administration screen.

**When you invent or tighten another unspecified rule**

Use this anytime during development:

**Prompt 29 — Supplemental requirement impact analysis**

I want to add this project requirement:

**[requirement]**

Do not implement it yet.

First determine whether the SRS already explicitly defines the issue.

If it does, preserve the SRS requirement and identify any conflict in my proposed rule.

If the SRS is silent, assign the proposal a Project Requirements Addendum ID.

Determine:

-   why the rule is needed;
-   whether it should be configurable;
-   appropriate initial/default value;
-   permitted values/constraints;
-   PostgreSQL impact;
-   Flask impact;
-   React impact;
-   unit-test impact;
-   integration-test impact;
-   documentation/demo impact.

Identify the earliest architectural layer requiring modification and give me the least-to-most sequence for implementing the change.

Do not change code until I approve the analysis.

**Final workflow at a glance**

The consolidated sequence is therefore:

**0. Baseline requirements**  
→ **1. Discover missing operational rules**  
→ **2. Approve/add supplemental requirements**  
→ **3. Implementation roadmap**

**PostgreSQL**

**4. Persistent-data analysis**  
→ **5. Conceptual model**  
→ **6. Logical schema**  
→ **7. Transaction/concurrency design**  
→ **8. Implement + tests**  
→ **9. Verify/freeze**

**Flask**

**10. Backend operations**  
→ **11. REST contract**  
→ **12. Architecture/tests**  
→ **13. Foundation**  
→ **14. Slot availability**  
→ **15. Reservation creation**  
→ **16. Newsletter**  
→ **17. Verify/freeze**

**React**

**Upload actual supplied images**  
→ **18. Asset + component analysis**  
→ **19. Reservation UX**  
→ **20. UI/test design**  
→ **21. Static site + Gallery**  
→ **22. Forms**  
→ **23. Flask integration**  
→ **24. React verification**

**Completion**

**25. Full integration testing**  
→ **26. Requirements/rubric audit**  
→ **27. Documentation**  
→ **28. Demo preparation**

And whenever you add a new business rule:

**29. Impact analysis → your approval → resume at earliest affected layer.**

This gives you a stable, incremental development path where every new piece builds on something already designed and tested, while still leaving room for you to tighten the business rules the SRS intentionally or unintentionally leaves open.
