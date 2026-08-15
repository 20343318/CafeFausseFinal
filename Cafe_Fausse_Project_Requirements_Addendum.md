# Cafe Fausse Project Requirements Addendum

**Addendum version:** 2.1  
**Established:** 2026-08-13  
**Last updated:** 2026-08-14  
**Relationship to baseline:** Supplements but may not contradict `SRS(1).pdf`, `Rubric(1).pdf`, or the Project Requirements Baseline  
**Change control:** Only explicitly approved decisions become active addendum requirements

## 1. Purpose

This document is the controlled record for supplemental business rules, refinements, constraints, and design decisions approved during implementation. Unresolved questions and optional ideas do not become active requirements without explicit approval.

## 2. Precedence and change rules

1. `SRS(1).pdf` and `Rubric(1).pdf` remain fixed and authoritative.
2. This addendum may clarify a gap but may not contradict, remove, or weaken an explicit SRS or rubric requirement.
3. Later explicit approval of a Prompt 1 decision takes precedence over its original recommendation or earlier proposed wording.
4. Each active entry records approval, configuration classification, affected requirements, rationale, implementation-layer impact, and verification impact.
5. Revisions preserve history: an entry is superseded or withdrawn, not silently overwritten.
6. Configurable business rules are preferred over hard-coded values when the authoritative documents do not mandate a literal value.
7. Future enhancements are inactive for Version 1 and require separate approval before implementation.
8. Exact PostgreSQL schema, Flask endpoint, and React component designs remain deferred to later prompts.

## 3. Status definitions

| Status | Meaning |
|---|---|
| Approved | Active project requirement or decision |
| Superseded | Replaced by a later approved entry |
| Withdrawn | Explicitly removed from active supplemental scope without altering authoritative requirements |
| Future enhancement — inactive | Recorded for possible later consideration; not approved or in scope for Version 1 |

## 4. Previously approved entries

### PRA-001 - Strict technology implementation order

| Field | Value |
|---|---|
| Type | Implementation constraint |
| Status | Approved |
| Approved by/date | Abdul, Prompt 0, 2026-08-13 |
| Decision | Implementation order is strictly PostgreSQL -> Flask REST API -> React/JSX UI -> integration. |
| Affected requirements | All DB, API, UI, INT, testing, and delivery work |
| Rationale | Establishes controlled dependency order and prevents later layers from driving premature implementation. |
| Verification | Work plan, commits/checkpoints, and gate reviews show that each layer's applicable requirements and tests are completed before the next layer begins. |

### PRA-002 - Least-to-most implementation strategy

| Field | Value |
|---|---|
| Type | Delivery strategy |
| Status | Approved |
| Approved by/date | Abdul, Prompt 0, 2026-08-13 |
| Decision | Within the strict technology order, implement the smallest verifiable requirement subset first, then add dependent behavior and complexity incrementally. |
| Affected requirements | All implementation phases |
| Rationale | Reduces complexity and exposes requirement or integration issues early. |
| Verification | Each phase uses incremental acceptance gates and preserves passing tests as capabilities are added. |

### PRA-003 - Testing throughout implementation

| Field | Value |
|---|---|
| Type | Quality constraint |
| Status | Approved |
| Approved by/date | Abdul, project instruction in effect on 2026-08-13 |
| Decision | Include unit and integration testing throughout implementation, even though the rubric does not expect significant testing. |
| Affected requirements | Database, Flask, React, integration, and NFR verification |
| Rationale | Protects behavior and traceability throughout incremental development. |
| Verification | Applicable tests accompany each implemented increment and are recorded in the traceability matrix. |

### PRA-004 - Authoritative-baseline control

| Field | Value |
|---|---|
| Type | Requirements governance |
| Status | Approved |
| Approved by/date | Abdul, Prompt 0, 2026-08-13 |
| Decision | Treat the supplied SRS and rubric as fixed authoritative documents; do not contradict explicit requirements. Implementation gaps require approval before becoming supplemental requirements. |
| Affected requirements | Entire project |
| Rationale | Prevents scope drift and silent assumptions. |
| Verification | Every implemented behavior traces to SRS, rubric, or an approved PRA entry. |

### PRA-005 - Configurable supplemental business rules

| Field | Value |
|---|---|
| Type | Design constraint |
| Status | Approved |
| Approved by/date | Abdul, project instruction in effect on 2026-08-13 |
| Decision | Prefer configurable business rules over hard-coded values when the SRS/rubric does not mandate the literal value. |
| Affected requirements | Reservation policy, validation, operational limits, and environment configuration |
| Rationale | Enables refinement without repeated code changes while preserving mandated values such as the total of 30 tables. |
| Verification | Approved variable rules are centralized in configuration and covered by tests. |

## 5. Prompt 1 approved supplemental requirements

All entries in this section were explicitly approved by Abdul in the Prompt 1 decision conversation on 2026-08-14. “Exact approved requirement” reflects the final approved interpretation and supersedes any earlier recommendation or draft wording for the same Prompt 1 ID.

### PRA-006 - Reservation start-time interval

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-01 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | Reservation start times shall align to a configurable interval. The default is 30 minutes. Permitted interval values are 15, 30, or 60 minutes. Flask shall generate and enforce aligned slots; React shall consume the slots supplied by Flask. |
| Default / validation | 30 minutes; permitted values 15, 30, 60 |
| Classification / control | Configurable; PostgreSQL business configuration |
| Rationale | Makes the valid-slot rule deterministic. |
| SRS / rubric refined | SRS date/time and valid/available-slot requirements; rubric sophisticated reservation logic and backend integration. |
| PostgreSQL impact | Persist the approved interval; exact schema deferred. |
| Flask/API impact | Generate and enforce aligned slots. |
| React/UI impact | Offer only API-supplied aligned starts. |
| Unit-test impact | Test every permitted value and reject misaligned or unsupported values. |
| Integration-test impact | Verify UI/API consistency after configuration change. |
| Demo / documentation | Demonstrate default 30-minute slots and document allowed values. |
| Dependencies | PRA-005, PRA-009, PRA-025 |

### PRA-007 - Reservation duration and occupancy

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-02 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | Every reservation shall have one configured occupancy duration. The default is 90 minutes. Permitted values are 60, 90, or 120 minutes. The duration covers the complete table-occupancy period; Version 1 has no separate turnover buffer. |
| Default / validation | 90 minutes; permitted values 60, 90, 120 |
| Classification / control | Configurable; PostgreSQL business configuration |
| Rationale | Enables deterministic closing-time and overlap validation. |
| SRS / rubric refined | SRS availability and prevention of double/overbooking; rubric sophisticated reservation logic and integration. |
| PostgreSQL impact | Persist duration and support occupancy calculations. |
| Flask/API impact | Derive end time and validate complete occupancy. |
| React/UI impact | Display authoritative start/end where appropriate. |
| Unit-test impact | Test permitted values, derived end times, closing boundaries, and overlap. |
| Integration-test impact | Verify duration changes propagate through API availability and UI display. |
| Demo / documentation | Demonstrate the default 90-minute period and document alternatives. |
| Dependencies | PRA-006, PRA-009, PRA-013 |

### PRA-008 - Valid reservation calendar dates

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-03 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | All calendar days are potentially reservable under the SRS weekly hours: Monday-Saturday 5:00 PM-11:00 PM and Sunday 5:00 PM-9:00 PM. A date remains subject to the advance-booking window, same-day lead time, closing-time rule, and table availability. Version 1 has no holiday or exceptional-closure calendar. |
| Default / validation | Weekly hours fixed by SRS; dependent limits remain authoritative. |
| Classification / control | Fixed Version 1 behavior based on SRS hours |
| Rationale | Defines date eligibility without altering the required weekly schedule. |
| SRS / rubric refined | SRS restaurant-hours and valid-slot requirements; rubric complete SRS functionality and sophisticated reservation logic. |
| PostgreSQL impact | No Version 1 exceptional-date data required. |
| Flask/API impact | Apply weekday hours and all dependent rules. |
| React/UI impact | Permit only dates that Flask can authoritatively validate. |
| Unit-test impact | Test each weekday, Sunday hours, date/window boundaries, and absence of holiday exceptions. |
| Integration-test impact | Verify date selection and returned daily slots follow the same schedule. |
| Demo / documentation | Demonstrate weekday/Sunday differences and document the Version 1 limitation. |
| Dependencies | PRA-010, PRA-011, PRA-012 |

### PRA-009 - Earliest and latest reservation start

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-04 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | The earliest start is the applicable SRS opening time. A reservation must finish no later than closing. The latest start is derived from closing time, configured duration, and interval; it is not an independent setting. With defaults, the last start is 9:30 PM Monday-Saturday and 7:30 PM Sunday. |
| Default / validation | Default-derived last starts 9:30 PM and 7:30 PM; end must be at/before close. |
| Classification / control | Derived behavior |
| Rationale | Prevents after-close occupancy and avoids inconsistent duplicate settings. |
| SRS / rubric refined | SRS restaurant-hours and valid-slot requirements; rubric complete functionality and sophisticated reservation logic. |
| PostgreSQL impact | No independent latest-start value. |
| Flask/API impact | Generate only starts whose full duration fits. |
| React/UI impact | Display API-supplied starts; accept no arbitrary times. |
| Unit-test impact | Test opening, exact closing, one interval late, and Sunday boundaries. |
| Integration-test impact | Verify duration/interval changes alter the last displayed and accepted start consistently. |
| Demo / documentation | Demonstrate and explain the derived default last starts. |
| Dependencies | PRA-006, PRA-007, PRA-008 |

### PRA-010 - Maximum advance-booking window

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-05 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | Reservations may be requested from the restaurant-local current date through 60 calendar days in advance, inclusive. The window is configurable from 1 through 365 days. Same-day requests remain subject to lead time. |
| Default / validation | 60 days; permitted 1-365; inclusive restaurant-local dates. |
| Classification / control | Configurable; PostgreSQL business configuration |
| Rationale | Bounds inventory exposure and makes date validation deterministic. |
| SRS / rubric refined | SRS reservation date and valid-slot requirements; rubric working form and sophisticated reservation logic. |
| PostgreSQL impact | Persist the booking-window setting. |
| Flask/API impact | Calculate and enforce authoritative date bounds. |
| React/UI impact | Restrict date selection for usability; Flask remains authoritative. |
| Unit-test impact | Test today, final allowed date, past dates, and one day beyond. |
| Integration-test impact | Verify React and Flask agree at boundaries and after configuration change. |
| Demo / documentation | Demonstrate the 60-day boundary and document configurability. |
| Dependencies | PRA-012 |

### PRA-011 - Same-day minimum lead time

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-06 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | Same-day reservations are allowed only when the requested start is at least the configured minimum lead time after authoritative restaurant-local server time. The default is 120 minutes; permitted range is 0-1440 minutes. |
| Default / validation | 120 minutes; permitted 0-1440. |
| Classification / control | Configurable; PostgreSQL business configuration |
| Rationale | Defines deterministic same-day availability. |
| SRS / rubric refined | SRS date/time and valid/available-slot requirements; rubric working form and sophisticated reservation logic. |
| PostgreSQL impact | Persist the lead-time setting. |
| Flask/API impact | Evaluate against authoritative restaurant-local time. |
| React/UI impact | Reflect API availability; client time is not authoritative. |
| Unit-test impact | Test exact lead boundary, one minute short, zero, maximum, and controlled-clock cases. |
| Integration-test impact | Verify client-time manipulation cannot bypass Flask validation. |
| Demo / documentation | Demonstrate same-day allowed/blocked examples. |
| Dependencies | PRA-010, PRA-012 |

### PRA-012 - Restaurant timezone and clock authority

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-07 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | Cafe Fausse reservation rules and displayed times use the IANA timezone `America/New_York`. The timezone is a PostgreSQL business setting. Server/database time is authoritative. Development machines and browsers may remain in any system timezone; React displays restaurant-local time, and persisted times support unambiguous timezone-aware behavior. |
| Default / validation | `America/New_York`; valid IANA timezone identifier. |
| Classification / control | Configurable PostgreSQL business setting; fixed server-authority behavior. |
| Rationale | Makes date/time behavior consistent across machines and daylight-saving changes. |
| SRS / rubric refined | SRS restaurant-hours, date/time, and valid-slot requirements; rubric complete functionality and integration quality. |
| PostgreSQL impact | Persist timezone and support unambiguous time values; types deferred. |
| Flask/API impact | Calculate rules in restaurant-local time and return unambiguous values. |
| React/UI impact | Render restaurant-local time regardless of browser zone. |
| Unit-test impact | Use a controlled clock for standard time, daylight time, and transitions. |
| Integration-test impact | Verify clients and servers in other timezones produce identical restaurant-local results. |
| Demo / documentation | State timezone and show that host/browser timezone need not change. |
| Dependencies | PRA-008, PRA-010, PRA-011 |

### PRA-013 - Reservation overlap boundary

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-08 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | Occupancy uses half-open intervals `[start, end)`. Two reservations overlap when each starts before the other ends. Back-to-back reservations are allowed when one starts exactly when the other ends. The rule applies to every assigned table. No separate turnover buffer is added. |
| Default / validation | Endpoint contact is not overlap. |
| Classification / control | Fixed application behavior |
| Rationale | Removes boundary ambiguity and permits predictable back-to-back seating. |
| SRS / rubric refined | SRS availability and prevention of double/overbooking; rubric sophisticated reservation logic and direct database effects. |
| PostgreSQL impact | Support overlap protection for every assigned table; mechanism deferred. |
| Flask/API impact | Use the same predicate for availability and final booking. |
| React/UI impact | Present Flask availability; no client overlap authority. |
| Unit-test impact | Test partial, complete, containing, contained, identical, and endpoint-touching intervals. |
| Integration-test impact | Verify no assigned table can participate in overlapping committed reservations. |
| Demo / documentation | Demonstrate rejected overlap and accepted back-to-back booking. |
| Dependencies | PRA-007, PRA-018 |

### PRA-014 - Duplicate and retry-safe reservation handling

| Field | Value |
|---|---|
| Prompt 1 source | P1-RSV-09 |
| Status / approval | Approved; Abdul, revised interpretation, 2026-08-14 |
| Exact approved requirement | A normalized customer email may not hold any overlapping reservation, using the complete occupancy interval. An exact retry of a successful reservation returns the existing confirmation without a duplicate; a different overlapping request for that email is rejected. Different customers may overlap only when sufficient exclusive tables are available. React disables submit while the API request is pending. Success opens a distinct confirmation view; an error/unavailable result keeps the user on the form. Flask and PostgreSQL remain authoritative. |
| Default / validation | Identity is normalized email; overlap uses PRA-013; retry equivalence must be deterministic. |
| Classification / control | Fixed application behavior |
| Rationale | Prevents accidental duplicates and customer self-conflicts without blocking legitimate simultaneous customers. |
| SRS / rubric refined | SRS success/full behavior and prevention of double/overbooking; rubric working forms, sophisticated logic, and integration. |
| PostgreSQL impact | Support concurrency-safe duplicate/overlap integrity; structure deferred. |
| Flask/API impact | Distinguish exact retry from conflicting overlap and revalidate transactionally. |
| React/UI impact | Disable repeated submit; navigate only on success; preserve form on failure. |
| Unit-test impact | Test normalization, exact/changed retry, overlap/non-overlap, and pending-submit state. |
| Integration-test impact | Test double-click and concurrent requests produce one logical booking and stable confirmation. |
| Demo / documentation | Demonstrate double-click protection, safe retry, and same-customer overlap rejection. |
| Dependencies | PRA-013, PRA-018, PRA-019, PRA-025 |

### PRA-015 - Party-size bounds and derived restaurant capacity

| Field | Value |
|---|---|
| Prompt 1 source | P1-CAP-01 |
| Status / approval | Approved; Abdul, revised Option C, 2026-08-14 |
| Exact approved requirement | Party size is an integer from 1 through total configured seating capacity, derived as the sum of capacities of the 30 current bookable tables. Parties may receive multiple tables. The derived maximum is theoretical; actual slot availability depends on tables free for the complete interval. Maximum party size is not a separate setting. |
| Default / validation | Minimum 1; initial derived maximum 120 under PRA-017. |
| Classification / control | Derived from PostgreSQL business data |
| Rationale | Keeps the maximum consistent with actual configured inventory. |
| SRS / rubric refined | SRS number of guests, 30-table availability, and full-slot behavior; rubric sophisticated logic and database integration. |
| PostgreSQL impact | Derive total from current table records. |
| Flask/API impact | Validate bound and find eligible free-table combinations. |
| React/UI impact | Display dynamic bound; Flask revalidates. |
| Unit-test impact | Test 0, 1, maximum, maximum plus one, and non-integers. |
| Integration-test impact | Verify capacity changes alter derived maximum and availability consistently. |
| Demo / documentation | Show initial 120 maximum and distinguish it from slot availability. |
| Dependencies | PRA-016, PRA-017, PRA-018 |

### PRA-016 - Thirty persistent bookable tables

| Field | Value |
|---|---|
| Prompt 1 source | P1-CAP-02 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | Version 1 contains exactly 30 bookable tables, as required by the SRS. Each is persistent PostgreSQL business data with its own capacity. The data model may avoid making 30 a permanent schema maximum, but adding tables beyond 30 is not active Version 1 behavior. |
| Default / validation | Exactly 30 active bookable tables in Version 1. |
| Classification / control | Fixed Version 1 count; PostgreSQL business data. |
| Rationale | Preserves the literal table-count requirement while permitting future schema evolution. |
| SRS / rubric refined | SRS total of 30 tables and table assignment; rubric integrated PostgreSQL database and direct database effects. |
| PostgreSQL impact | Store 30 identifiable table records; schema deferred. |
| Flask/API impact | Treat only the 30 current tables as inventory. |
| React/UI impact | No customer inventory administration. |
| Unit-test impact | Verify initialization produces exactly 30 bookable table records. |
| Integration-test impact | Verify assignment and capacity calculations use only the Version 1 inventory. |
| Demo / documentation | Show 30 database-backed tables; distinguish model extensibility from active behavior. |
| Dependencies | PRA-004 |

### PRA-017 - Individually configurable table capacities

| Field | Value |
|---|---|
| Prompt 1 source | P1-CAP-03 |
| Status / approval | Approved; Abdul, Prompt 1 approval, 2026-08-14 |
| Exact approved requirement | Each table capacity is individually configurable PostgreSQL business data. Initially, every one of the 30 tables has capacity 4, yielding total capacity/maximum party size 120. Capacity changes automatically affect derived totals and table eligibility. |
| Default / validation | 4 seats per table; positive seating count, with exact database range deferred. |
| Classification / control | Configurable; PostgreSQL business data. |
| Rationale | Supports heterogeneous capacities while keeping Version 1 initialization simple. |
| SRS / rubric refined | SRS 30-table inventory and availability; rubric sophisticated logic and PostgreSQL integration. |
| PostgreSQL impact | Persist capacity per table and initialize all 30 to 4. |
| Flask/API impact | Read current capacities for validation/assignment. |
| React/UI impact | Use Flask-derived limits; no customer capacity editing. |
| Unit-test impact | Test initial total, individual edits, invalid capacity, and recalculation. |
| Integration-test impact | Verify a capacity change alters party limits and slot availability. |
| Demo / documentation | Show 30 x 4 and the derived total. |
| Dependencies | PRA-015, PRA-016 |

### PRA-018 - Exclusive multi-table assignment

| Field | Value |
|---|---|
| Prompt 1 source | P1-CAP-04 |
| Status / approval | Approved; Abdul, revised Option B with exclusivity condition, 2026-08-14 |
| Exact approved requirement | A reservation may receive one or more tables. Select a combination by: minimum number of tables; then least unused seating; then random choice among equally suitable combinations. Every assigned table is exclusive for the complete interval. Unused seats cannot be shared, and no assigned table can join another overlapping reservation. Assignment commits atomically, all-or-none. No eligible combination means unavailable/full. Customers do not select tables. Version 1 does not model adjacency/combinability. |
| Default / validation | Priority order above; randomness only for ties; full-interval exclusivity. |
| Classification / control | Fixed behavior using PostgreSQL table business data. |
| Rationale | Extends assignment to larger parties while minimizing fragmentation and preventing table sharing. |
| SRS / rubric refined | SRS random assignment, singular Table Number minimum, availability, and no double/overbooking; rubric sophisticated reservation logic and database effects. |
| PostgreSQL impact | Persist every assigned table and protect atomic overlap; representation deferred. |
| Flask/API impact | Find/prioritize/randomize eligible combinations and commit atomically. |
| React/UI impact | No table selection; reveal assigned numbers only after success. |
| Unit-test impact | Test single/multiple tables, minimum count, least waste, random ties, exclusivity, and no combination. |
| Integration-test impact | Test concurrent attempts, all-or-none commit, and absence of shared assigned tables. |
| Demo / documentation | Demonstrate single- and multi-table bookings and explain additive Table Number interpretation. |
| Dependencies | PRA-007, PRA-013, PRA-015, PRA-016, PRA-017 |

### PRA-019 - Customer identity, structured name, and synchronized newsletter preference

| Field | Value |
|---|---|
| Prompt 1 source | P1-CUS-01 |
| Status / approval | Approved; Abdul, complete revised rule, 2026-08-14 |
| Exact approved requirement | Customer name is stored as required first name, optional middle initial, and required last name; collectively they satisfy the SRS Customer Name. Reservation and newsletter forms require matching email/confirmation email. Customers are identified by normalized email and matched by normalized first/last name; phone is not identity. Email/name mismatch is rejected generically; names are never silently overwritten. For existing customers, omitted middle initial preserves stored data, an empty value may be populated, and conflicting populated values are rejected. Phone is optional/reservation-only: new or existing-blank may be populated; omission preserves; a differing existing phone is not overwritten, though booking may proceed with a notice that profile changes are unsupported. One customer exists per normalized email. After valid identifying fields, React performs a debounced asynchronous lookup and synchronizes the newsletter checkbox to stored state. Reservation and dedicated preferences forms may independently subscribe/unsubscribe. A reservation-linked preference change persists only with successful booking. No authentication is included. |
| Default / validation | Email trim/lower canonicalization; name trim/collapse/case-insensitive match while preserving display characters; confirmation email not stored; details in PRA-023. |
| Classification / control | Fixed behavior; Customers is PostgreSQL business data. |
| Rationale | Prevents duplicate customer records and silent identity changes while keeping the displayed preference consistent. |
| SRS / rubric refined | SRS Customer Name, Email, Phone, Newsletter Signup, reservation form, and newsletter form; rubric working forms, UI/UX, and integration. |
| PostgreSQL impact | One customer per normalized email with structured name, optional phone, and newsletter state. |
| Flask/API impact | Normalize/match identity, return generic mismatch, supply status lookup, and apply booking-linked preference atomically. |
| React/UI impact | Collect structured name/confirmed email, synchronize state, and prevent stale lookup overwrite. |
| Unit-test impact | Test normalization, mismatch, middle-initial rules, phone rules, duplicate email, and stale lookup handling. |
| Integration-test impact | Test new/existing paths, asynchronous synchronization, and reservation-linked preference atomicity. |
| Demo / documentation | Demonstrate structured names, duplicate prevention, synchronized checkbox, subscribe/unsubscribe, and absence of authentication. |
| Dependencies | PRA-014, PRA-020, PRA-021, PRA-023, PRA-025 |

### PRA-020 - Customers as newsletter source of truth

| Field | Value |
|---|---|
| Prompt 1 source | P1-NEW-01 |
| Status / approval | Approved; Abdul, revised Option A, 2026-08-14 |
| Exact approved requirement | `Customers` is the single source of truth for current newsletter status; no separate subscriber store exists in Version 1. The dedicated newsletter preferences form remains and requires first name, optional middle initial, last name, email, confirmation email, and explicit checkbox. New+selected creates a complete customer; new+unselected creates no record. A matching existing customer may set true/false without altering name, phone, or reservations. Mismatch is rejected generically. Unsubscribe retains the customer. Both forms reuse identity/preference rules. Booking-linked changes are atomic with booking; dedicated changes are independent. Repeating current state succeeds idempotently. Version 1 stores current state only. |
| Default / validation | Boolean current state; new-unselected creates no record; existing-unselected retains false. |
| Classification / control | Fixed behavior; PostgreSQL customer business data. |
| Rationale | Prevents divergent subscription stores while retaining dedicated signup and preference management. |
| SRS / rubric refined | SRS newsletter signup, proper email storage, and Customers Newsletter Signup field; rubric working forms, backend integration, and database effects. |
| PostgreSQL impact | Keep authoritative Boolean on customer; no history store. |
| Flask/API impact | Reuse identity/preference rules and return authoritative state. |
| React/UI impact | Retain dedicated preferences form and reservation checkbox. |
| Unit-test impact | Test all new/existing true/false paths, mismatch, idempotency, and unrelated-data preservation. |
| Integration-test impact | Verify both forms update the same customer source of truth without duplicates. |
| Demo / documentation | Demonstrate both preference paths and direct database effects. |
| Dependencies | PRA-019, PRA-021 |

### PRA-021 - Concurrent and retry-safe newsletter preference updates

| Field | Value |
|---|---|
| Prompt 1 source | P1-NEW-02 |
| Status / approval | Approved; Abdul, revised Option A, 2026-08-14 |
| Exact approved requirement | Newsletter submissions set a final Boolean state and are idempotent. Same-state repeats succeed. Concurrent creates for one normalized email yield one customer; conflicting name gets generic mismatch. For concurrent valid preference updates, last committed write wins. Successful responses return authoritative state and React synchronizes. Booking-linked changes commit/roll back with booking; dedicated updates are independent. New-unselected creates no record; existing-unselected retains false. Timed-out submissions may be retried safely. Email-ownership verification is not Version 1. |
| Default / validation | Boolean set semantics; normalized-email uniqueness; last-committed-write-wins. |
| Classification / control | Fixed application/transactional behavior. |
| Rationale | Makes preference handling predictable under repeats, timeouts, and concurrency. |
| SRS / rubric refined | SRS newsletter storage; rubric working forms, backend/database integration, and demonstrable data effects. |
| PostgreSQL impact | Enforce one customer and transactional final state. |
| Flask/API impact | Retry-safe set semantics; return committed state. |
| React/UI impact | Replace local state with successful authoritative response. |
| Unit-test impact | Test repeats, mismatch, timeout retry, and returned authoritative state. |
| Integration-test impact | Exercise concurrent create/update and reservation commit/rollback coupling. |
| Demo / documentation | Demonstrate idempotency and document last-commit behavior. |
| Dependencies | PRA-019, PRA-020 |

### PRA-022 - No reservation cancellation or modification in Version 1

| Field | Value |
|---|---|
| Prompt 1 source | P1-CAN-01 |
| Status / approval | Approved; Abdul, revised rule, 2026-08-14 |
| Exact approved requirement | Version 1 has no customer-facing reservation cancellation, modification, or rescheduling UI/API. A saved reservation remains active and blocks every assigned table for its entire interval. Multi-table reservations cannot be partially cancelled/modified. Newsletter unsubscription is independent. Development reset/manual cleanup is not a customer feature. No reservation status/control field is required solely for Version 1 cancellation behavior. |
| Default / validation | All committed Version 1 reservations remain active for availability. |
| Classification / control | Fixed Version 1 behavior. |
| Rationale | Keeps unrequested lifecycle functionality out of scope while making availability deterministic. |
| SRS / rubric refined | SRS reservation storage and availability; rubric complete SRS functionality and sophisticated reservation logic. |
| PostgreSQL impact | No cancellation/status design mandated; bookings occupy inventory. |
| Flask/API impact | No customer cancellation/modification endpoint. |
| React/UI impact | No customer cancellation/modification control. |
| Unit-test impact | Verify saved reservations always block all assigned tables for their intervals. |
| Integration-test impact | Verify newsletter operations never release or modify reservations. |
| Demo / documentation | Document limitation; keep reset steps development-only. |
| Dependencies | PRA-013, PRA-018, PRA-020 |

### PRA-023 - Authoritative input and business validation

| Field | Value |
|---|---|
| Prompt 1 source | P1-VAL-01 |
| Status / approval | Approved; Abdul, revised Option B, 2026-08-14 |
| Exact approved requirement | React provides immediate validation; Flask revalidates authoritatively. First/last names: required, trim/collapse, 1-100 characters, at least one letter, case-insensitive matching, display punctuation/accents preserved. Middle initial: optional one alphabetic character with optional period, stored uppercase without period. Email+confirmation: required both forms, trim, valid syntax, maximum 254, lowercase canonical, must match, confirmation not stored. Phone: optional reservations only, allowed digits/spaces/plus/parentheses/hyphens/periods, 7-15 digits, normalized digits for comparison, with PRA-019 update rules. Party size: integer 1 through derived maximum. Reservation revalidation uses current configured timezone, window, lead, interval, hours, duration, closing, capacity, exclusivity, and same-customer-overlap rules. Newsletter preference is Boolean; valid identity triggers async status retrieval. Stale responses cannot overwrite newer input. Submit is disabled while pending. User errors are nontechnical. |
| Default / validation | Current defaults: New York, 60 days, 120 minutes, 30-minute starts, 90-minute duration, and initial capacity 120; exact async debounce timing deferred. |
| Classification / control | Fixed validation plus approved PostgreSQL business configuration. |
| Rationale | Provides consistent defense-in-depth validation across UI and authoritative backend. |
| SRS / rubric refined | All SRS form fields, valid/available slots, email storage, and no-overbooking; rubric working forms, UI/UX, sophisticated logic, and integration. |
| PostgreSQL impact | Enforce appropriate canonical data integrity; exact constraints deferred. |
| Flask/API impact | Normalize/revalidate and return safe field/business errors. |
| React/UI impact | Immediate accessible feedback, stale-response protection, pending state. |
| Unit-test impact | Apply boundary/equivalence tests to every field and configured rule. |
| Integration-test impact | Verify React validation cannot bypass authoritative Flask validation. |
| Demo / documentation | Demonstrate valid/invalid submissions and configuration boundaries. |
| Dependencies | PRA-006 through PRA-021, PRA-024, PRA-025 |

### PRA-024 - Confirmation, error messaging, and technical logging

| Field | Value |
|---|---|
| Prompt 1 source | P1-MSG-01 |
| Status / approval | Approved; Abdul, revised Option B with logging modification, 2026-08-14 |
| Exact approved requirement | Reservation success shows a distinct confirmation with reference, customer name, restaurant-local start/end, party size, all assigned tables, final newsletter state, and restaurant address/phone. Do not claim email/SMS delivery. Exact retry returns the confirmation. Full/stale availability refreshes slots; same-customer overlap, mismatch, validation, network ambiguity, newsletter lookup failure, and unexpected failures receive appropriate handling. Lookup failure shows indeterminate status; booking may proceed without changing preference and lookup may retry. Dedicated preference updates confirm authoritative state. Ambiguous network booking supports safe retry. User messages are friendly/nontechnical and accessible. Flask logs detailed backend technical errors; ordinary validation is not necessarily a technical error. React errors may be logged to the browser console. Logs must not unnecessarily expose customer information, confirmation-email values, secrets, or credentials. |
| Default / validation | Restaurant-local display; no delivery claim; minimized log data. |
| Classification / control | Fixed behavior; Flask technical logging configuration; React browser-console logging. |
| Rationale | Supports usable recovery and troubleshooting while separating safe user messages from technical diagnostics. |
| SRS / rubric refined | SRS success/full messages and application quality; rubric UI/UX, working forms, integration, and demonstration. |
| PostgreSQL impact | Supply committed confirmation data; do not store confirmation-email duplicate. |
| Flask/API impact | Return safe structured outcomes and log/redact backend errors. |
| React/UI impact | Accessible confirmation/recovery; optional console logging for UI errors. |
| Unit-test impact | Test message mapping, confirmation completeness, log redaction, and no false delivery claim. |
| Integration-test impact | Exercise stale/full/mismatch/timeout/lookup and unexpected backend failures. |
| Demo / documentation | Demonstrate friendly errors/confirmation and document log handling. |
| Dependencies | PRA-012, PRA-014, PRA-018 through PRA-023, PRA-025 |

### PRA-025 - Availability-first reservation UI and authoritative revalidation

| Field | Value |
|---|---|
| Prompt 1 source | P1-UI-01 |
| Status / approval | Approved; Abdul, revised Option B with all-slot display modification, 2026-08-14 |
| Exact approved requirement | Flow: party size; New York date; Flask availability request; slot selection; structured customer details; async newsletter synchronization; review/submit; Flask revalidation; confirmation or in-place failure. Flask returns every legitimate aligned start for the date/party size that fits SRS hours and ends by close, marking each available/unavailable; same-day lead failures may display unavailable. React displays the full daily schedule: available slots selectable; unavailable disabled and visibly distinguished without color alone and with accessible state. React accepts no arbitrary times, calculates no authoritative availability/table assignment, offers no table choice, and promises no tables before success. Date/party change invalidates selection/refetches. Newsletter lookup failure permits booking without preference change. Submit is disabled pending. Success opens confirmation; failure preserves form/refreshes as appropriate. Every displayed result is provisional and Flask-revalidated. Slot responses expose no customer/reservation details, table assignments, or unnecessary capacity internals. |
| Default / validation | Uses current business configuration; accessible/mobile-responsive; Flask authoritative. |
| Classification / control | Fixed application behavior with Flask/PostgreSQL data. |
| Rationale | Gives a useful visual daily inventory view while preserving authoritative revalidation. |
| SRS / rubric refined | SRS reservation form, valid/available slot, success/full behavior, and no-overbooking; rubric React UI, Flexbox/Grid UX, working forms, responsiveness, and integration. |
| PostgreSQL impact | Supply rule/inventory data only through Flask. |
| Flask/API impact | Return all legitimate starts/status and revalidate selected slot. |
| React/UI impact | Accessible schedule, invalidation/pending/stale states, and failure-state preservation. |
| Unit-test impact | Test state transitions, disabled slots, invalidation, stale requests, and accessibility semantics. |
| Integration-test impact | Test stale availability followed by authoritative rejection, refresh, and recovery. |
| Demo / documentation | Demonstrate full schedule, disabled unavailable slots, stale-slot handling, and responsiveness. |
| Dependencies | PRA-006 through PRA-019, PRA-023, PRA-024 |

## 6. Prompt 4 approved supplemental requirements

### PRA-026 - Prospective configuration changes and repeatable reinitialization

| Field | Value |
|---|---|
| Prompt 4 source | P4-LIF-01 |
| Status / approval | Approved; Abdul, Option A with demonstration/reinitialization notes, 2026-08-14 |
| Exact approved requirement | A confirmed reservation retains its originally booked occupancy interval, party size, and exclusive table assignments. Later reservation-configuration or table-capacity changes apply prospectively to subsequent availability calculations and reservations; they do not recalculate, invalidate, or alter existing reservations. Seating configuration is relatively fixed in Version 1. For academic demonstration, development, or testing, designated nonproduction reservation data may be deleted through controlled reset and reinitialization procedures before restarting with a changed seating configuration. Later PostgreSQL deliverables shall provide repeatable initialization, seed, reset, and verification procedures. |
| Default / validation | Existing confirmed reservation facts are immutable; configuration changes affect new calculations only. Reset/reinitialization is restricted to designated development, test, or demonstration data. |
| Classification / control | Fixed lifecycle behavior plus PostgreSQL business configuration and controlled development/test tooling. |
| Rationale | Prevents configuration changes from creating retroactive overlaps or invalid assignments while supporting repeatable academic demonstrations. |
| SRS / rubric refined | SRS reservation persistence, availability, and data integrity; rubric direct database effects and sophisticated reservation logic. |
| PostgreSQL impact | Preserve the booked occupancy facts and assignments of every confirmed reservation; later deliverables provide safe repeatable initialization/reset procedures. |
| Flask/API impact | Apply current configuration to new availability and booking operations without rewriting existing reservations. |
| React/UI impact | No customer-facing reset or configuration-management control; confirmed reservation details remain stable. |
| Unit-test impact | Test that configuration changes do not change existing reservation occupancy or assignments. |
| Integration-test impact | Test prospective changes and clean nonproduction reset/reinitialization from a known state. |
| Demo / documentation | Document and rehearse repeatable demo reset/seed procedures; do not present reset as a customer feature. |
| Dependencies | PRA-007, PRA-013, PRA-016 to PRA-018, PRA-022 |

### PRA-027 - Database-generated reservation fingerprint and retry separation

| Field | Value |
|---|---|
| Prompt 4 source | P4-RTY-01 |
| Status / approval | Approved; Abdul, final simplified fingerprint interpretation, 2026-08-14 |
| Exact approved requirement | PostgreSQL generates and stores a deterministic, versioned, opaque reservation fingerprint from the resolved customer identifier, canonical reservation start timestamp, and party size. Middle initial, phone, name text, email text, newsletter status/action, assigned tables, reservation end, and current configuration values are excluded. A matching fingerprint is a lookup aid; PostgreSQL shall also verify the underlying customer, start, and party-size facts before treating a request as an exact retry. An equivalent retry returns the existing reservation confirmation and current authoritative newsletter state without reapplying or changing the newsletter action contained in the retry. A same-customer overlapping request with a different party size or other nonmatching reservation identity is rejected under the same-customer overlap rule. Clients do not generate the fingerprint. The successful response may return it with the stable confirmation reference. |
| Default / validation | Versioned fingerprint inputs: customer identifier + canonical start + party size. Hash/fingerprint collision must not alone establish equality. |
| Classification / control | Persistent technical reservation identity generated authoritatively by PostgreSQL; fixed retry behavior. |
| Rationale | Provides deterministic UI-independent retry safety while separating mutable newsletter preference and optional customer fields from reservation identity. |
| SRS / rubric refined | SRS reservation confirmation, persistence, and double/overbooking prevention; rubric sophisticated logic, integration, and direct database effects. |
| PostgreSQL impact | Generate, persist, and verify the opaque fingerprint and return the existing reservation for an exact retry. |
| Flask/API impact | Expose consistent retry behavior to React and future mobile/third-party clients without moving fingerprint logic into clients. |
| React/UI impact | Clients submit ordinary reservation data and never generate the fingerprint; an exact retry displays the existing confirmation and current newsletter state. |
| Unit-test impact | Test stable equivalent fingerprints, excluded-field changes, party-size differences, collision verification, and newsletter nonmutation on retry. |
| Integration-test impact | Test lost-response retry, replay after newsletter changes, mobile/third-party-equivalent requests, and same-customer conflicting overlap. |
| Demo / documentation | Demonstrate a safe retry with no duplicate reservation and document the client-independent rule. |
| Dependencies | PRA-014, PRA-019 to PRA-021, PRA-023 to PRA-025, PRA-026 |

### PRA-028 - Version 1 retention until controlled reset

| Field | Value |
|---|---|
| Prompt 4 source | P4-RET-01 |
| Status / approval | Approved; Abdul, Option A, 2026-08-14 |
| Exact approved requirement | During normal Version 1 operation, customer, reservation, and table-assignment records are retained indefinitely until a controlled development, test, or demonstration reset. Past reservations cease affecting availability because their occupancy intervals have ended, not because their records are deleted. Newsletter unsubscription retains the customer record with current newsletter status set to false. Version 1 performs no automatic deletion, archival, anonymization, or retention-period purge. Controlled reset/reinitialization is not a customer feature and must target designated nonproduction data. |
| Default / validation | Retain records during normal operation; delete only through controlled nonproduction reset/reinitialization. |
| Classification / control | Fixed Version 1 data-lifecycle behavior. |
| Rationale | Keeps the academic project deterministic, preserves database demonstration evidence, and avoids unapproved retention/archive complexity. |
| SRS / rubric refined | SRS persistent customer/reservation storage and availability; rubric direct database-effect demonstration and reproducible application behavior. |
| PostgreSQL impact | No automatic purge/archive mechanism; time-bounded availability ignores elapsed intervals while records remain queryable. |
| Flask/API impact | No customer deletion, archive, or retention-management operation. |
| React/UI impact | No deletion/archive control; newsletter unsubscribe only changes current preference. |
| Unit-test impact | Test that past reservations remain stored but do not block future intervals and that unsubscribe retains the customer. |
| Integration-test impact | Verify retained history, current availability, and controlled reset/reinitialization isolation. |
| Demo / documentation | Document normal retention and safe demo/test reset procedures. |
| Dependencies | PRA-020, PRA-022, PRA-026 |

## 7. Decision-to-Addendum crosswalk

### 7.1 Prompt 1 decisions

| Prompt 1 decision | Addendum ID |
|---|---|
| P1-RSV-01 | PRA-006 |
| P1-RSV-02 | PRA-007 |
| P1-RSV-03 | PRA-008 |
| P1-RSV-04 | PRA-009 |
| P1-RSV-05 | PRA-010 |
| P1-RSV-06 | PRA-011 |
| P1-RSV-07 | PRA-012 |
| P1-RSV-08 | PRA-013 |
| P1-RSV-09 | PRA-014 |
| P1-CAP-01 | PRA-015 |
| P1-CAP-02 | PRA-016 |
| P1-CAP-03 | PRA-017 |
| P1-CAP-04 | PRA-018 |
| P1-CUS-01 | PRA-019 |
| P1-NEW-01 | PRA-020 |
| P1-NEW-02 | PRA-021 |
| P1-CAN-01 | PRA-022 |
| P1-VAL-01 | PRA-023 |
| P1-MSG-01 | PRA-024 |
| P1-UI-01 | PRA-025 |

### 7.2 Prompt 4 decisions

| Prompt 4 decision | Addendum ID |
|---|---|
| P4-LIF-01 | PRA-026 |
| P4-RTY-01 | PRA-027 |
| P4-RET-01 | PRA-028 |

## 8. Authoritative-document compatibility findings

No approved supplemental requirement contradicts the SRS or rubric. These interpretations control:

1. **Table Number versus multiple tables:** the SRS singular Table Number is preserved for a single-table booking. PRA-018 additively permits one or more specific assigned table numbers when combined capacity is required. Exact schema representation is deferred.
2. **Customer Name versus structured fields:** first name, optional middle initial, and last name collectively satisfy the SRS Customer Name requirement.
3. **Exactly 30 tables versus extensibility:** Version 1 has exactly 30 bookable tables. A schema that could later support more does not activate more than 30.
4. **Newsletter signup versus preferences:** the dedicated form still supports signup. Existing-customer unsubscribe and reservation-form preference management are additive; `Customers` remains the source of truth.
5. **Random assignment:** single-table selection remains random among equally suitable choices. Multi-table minimum-count and least-waste criteria precede random tie-breaking to avoid needless fragmentation.
6. **Displayed availability:** React's display does not weaken Flask/PostgreSQL authority; every booking is revalidated.

## 9. Remaining unresolved decisions

No genuinely ambiguous operational or persistent-data business rule remains among the approved Prompt 1 and Prompt 4 decisions. These deliberately deferred technical-design decisions belong to later prompts:

- exact PostgreSQL tables, columns, types, keys, constraints, indexes, configuration representation, and multi-table assignment structure;
- exact transaction, concurrency-control, locking, and idempotency mechanisms;
- exact Flask paths, methods, status codes, payloads, error codes, service boundaries, and logging framework;
- exact React components, routing, state management, debounce/on-blur timing, and visual styling;
- exact test frameworks, fixtures, controlled clock, and deployment topology.

They must continue to honor PRA-001 through PRA-028.

## 10. Future enhancements — inactive and unapproved for Version 1

These are not active supplemental requirements and shall not be implemented without later explicit approval.

| FE ID | Future enhancement | Version 1 status / notes |
|---|---|---|
| FE-001 | Authentication | Inactive; no customer authentication in Version 1. |
| FE-002 | Verified customer profiles | Inactive; could permit secure profile/contact maintenance. |
| FE-003 | Automatic form prefilling | Inactive; expected to depend on authentication/verified profiles. |
| FE-004 | Email-ownership verification | Inactive; future flow may use a time-limited validation link. Expiry, single-use, resend, and unverified-state rules remain undefined. |
| FE-005 | Reservation cancellation | Inactive; secure authorization and atomic release rules would be required. |
| FE-006 | Reservation modification/rescheduling | Inactive; authorization, atomic reassignment, and conflict rules would be required. |
| FE-007 | No-show handling | Inactive; statuses, timing, operations, and reporting remain undefined. |
| FE-008 | Administrative reservation management | Inactive; roles, authentication, authorization, audit, and actions remain undefined. |
| FE-009 | Holiday or exceptional-closure configuration | Inactive; Version 1 uses only the SRS weekly schedule. |
| FE-010 | Subscription-history/audit events | Inactive; Version 1 stores current newsletter state only. |
| FE-011 | Confirmation email or SMS | Inactive; Version 1 displays confirmation and never claims a message was sent. |
| FE-012 | Physical table adjacency/combinability | Inactive; Version 1 has no floor-plan constraint. |
| FE-013 | More than 30 active bookable tables | Inactive; model extensibility does not change the Version 1 count. |
| FE-014 | Customer self-service contact updates | Inactive; Version 1 does not silently overwrite differing stored identity/contact values. |
| FE-015 | Retroactive configuration changes | Inactive; would recalculate or alter existing reservations after configuration changes and requires new conflict rules. |
| FE-016 | Effective-dated configuration history | Inactive; would retain configuration versions and associate reservations with effective versions for auditing. |
| FE-017 | Production retention, archival, anonymization, and deletion policies | Inactive; Version 1 retains data until controlled nonproduction reset. |

## 11. Decision record template

### PRA-XXX - Short title

| Field | Value |
|---|---|
| Type | Business rule / refinement / constraint / design decision |
| Status | Approved / Superseded / Withdrawn |
| Approved by/date | Name, approval reference, date |
| Exact approved requirement | Exact, testable approved statement |
| Initial/default value | Value, or not applicable |
| Permitted values / validation | Constraints, or not applicable |
| Classification / control | Configurable / derived / fixed; PostgreSQL business data/configuration / Flask technical configuration / fixed application behavior |
| Rationale | Why selected |
| Refines | SRS, rubric, and decision IDs |
| PostgreSQL impact | Required effect without premature schema design |
| Flask/API impact | Required effect without premature endpoint design |
| React/UI impact | Required effect without premature component design |
| Unit-test impact | Required test categories |
| Integration-test impact | Required cross-layer tests |
| Demo/documentation impact | Required evidence/explanation |
| Dependencies | Other approved requirement IDs |
| Supersedes | Earlier PRA ID, or none |

## 12. Change log

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-13 | Established addendum governance and recorded five already-approved project constraints. No unresolved business rule or optional enhancement was approved. |
| 2.0 | 2026-08-14 | Preserved PRA-001 through PRA-005; added PRA-006 through PRA-025 from all final Prompt 1 approvals; added the complete crosswalk, compatibility findings, deferred technical decisions, and a separate inactive Future Enhancements register. Obsolete/superseded Prompt 1 proposals were not recorded as active requirements. |
| 2.1 | 2026-08-14 | Added PRA-026 through PRA-028 from approved Prompt 4 decisions governing prospective configuration changes, database-generated reservation fingerprints, retry/newsletter separation, Version 1 retention, and repeatable nonproduction reset/reinitialization. Added FE-015 through FE-017 as inactive future enhancements. |
