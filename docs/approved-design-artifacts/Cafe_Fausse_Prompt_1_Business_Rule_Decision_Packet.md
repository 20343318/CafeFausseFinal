# Cafe Fausse Prompt 1 - Business Rule Decision Packet

**Version:** 1.0  
**Date:** 2026-08-13  
**Stage:** Requirements discovery before database design  
**Authority:** `SRS(1).pdf` and `Rubric(1).pdf` remain fixed and authoritative  
**Decision status:** Every option and recommendation in this document is unapproved  
**Implementation status:** No code or database design has been generated  

## 1. Purpose and decision control

This packet identifies operational business rules that the SRS does not define precisely enough for deterministic implementation. It provides alternatives and recommendations, but it does not modify the Project Requirements Addendum. Approved choices will be formalized only when Prompt 2 is invoked.

The decision IDs in this packet are discussion identifiers. Prompt 2 will assign stable Project Requirements Addendum IDs to approved requirements.

## 2. Explicit SRS requirements that must be preserved

| ID | Explicit requirement | Implementation consequence that cannot be contradicted |
|---|---|---|
| SRS-FR-02 | Hours are Monday-Saturday, 5:00 PM-11:00 PM, and Sunday, 5:00 PM-9:00 PM. | Reservation rules must use these opening and closing hours. |
| SRS-FR-06 | Reservation input includes date/time slot, number of guests, customer name, email, and optional phone. | All required data must be accepted; phone must remain optional. |
| SRS-FR-07 | The selected time slot must be valid and available. | Both validity and availability require deterministic definitions and backend enforcement. |
| SRS-FR-08 | When available, the backend assigns a random table from 30 total tables. | Exactly 30 tables must be represented; assignment must retain a genuine random element among eligible available tables. |
| SRS-FR-09 | Booking produces a success message; a fully booked slot produces an error. | Both outcomes must be implemented and testable. |
| SRS-FR-15 | Newsletter signup validates proper email format. | Email validation cannot be omitted. |
| SRS-FR-16 | Newsletter emails are stored in the backend database. | Successful signups must persist. |
| SRS-FR-17 | PostgreSQL contains at least Customers and Reservations tables with the specified minimum fields. | Supplemental modeling may add fields/tables but may not remove the minimum structures. |
| SRS-FR-18 | Flask inserts new customers, checks availability, randomly assigns an available table, and returns confirmation/error messages. | Supplemental duplicate rules must still insert a customer when no matching customer exists. |
| SRS-NFR-02 | Form submissions should complete within 2 seconds. | Chosen rules should remain proportional and performant. |
| SRS-NFR-05 | Data integrity must prevent double or over-booking. | Final design must include transactionally safe integrity protection. |
| SRS-NFR-06 | Failures should be handled in a user-friendly manner. | Invalid, duplicate, unavailable, and system-failure outcomes need clear behavior. |
| SRS-UI | Reservation time may be selected by dropdown or time picker. | A controlled list of valid slots is allowed; free-form time entry is not required. |

The rubric additionally expects “sophisticated reservations logic” for the score-5 target and direct demonstration of database effects. It does not define “sophisticated,” so the approved rules and their integrity tests should provide the evidence without unnecessary enterprise complexity.

## 3. Decision summary

| Decision ID | Topic | Recommended option | Recommended control | Blocks deterministic database analysis? |
|---|---|---|---|---|
| P1-RSV-01 | Start-time interval | B - 30 minutes | PostgreSQL business setting | Yes |
| P1-RSV-02 | Reservation duration | B - 90 minutes | PostgreSQL business setting | Yes |
| P1-RSV-03 | Valid calendar dates/closures | A - all seven days under SRS hours; no blackout feature in core scope | Fixed SRS behavior | Yes |
| P1-RSV-04 | Latest start/closing behavior | A - reservation must finish by closing | Derived fixed behavior | Yes |
| P1-RSV-05 | Advance-booking window | B - 60 days | PostgreSQL business setting | Yes |
| P1-RSV-06 | Same-day lead time | C - 120 minutes | PostgreSQL business setting | Yes |
| P1-RSV-07 | Restaurant timezone and authoritative clock | A - America/New_York; server/database time is authoritative | PostgreSQL business setting + fixed enforcement | Yes |
| P1-CAP-01 | Party-size range | B - 1 to 8 guests | PostgreSQL business settings | Yes |
| P1-CAP-02 | Table-capacity model | B - capacity-aware 30-table inventory | PostgreSQL business data | Yes |
| P1-CAP-03 | Table-capacity distribution | B - 10 two-seat, 12 four-seat, 6 six-seat, 2 eight-seat tables | PostgreSQL seed/business data | Yes |
| P1-CAP-04 | Availability and random assignment | B - capacity-fit, no overlap, random among all eligible tables | Fixed behavior | Yes |
| P1-RSV-08 | Overlap boundary and turnover | A - half-open intervals; no separate buffer | Fixed behavior | Yes |
| P1-RSV-09 | Duplicate reservation submission | B - one customer/start; exact retry returns existing confirmation | Fixed behavior + database integrity | Yes |
| P1-CUS-01 | Duplicate customer handling | B - case-insensitive normalized email identifies/reuses customer | Fixed behavior + database uniqueness | Yes |
| P1-NEW-01 | Newsletter-only subscriber storage | A - use Customers; allow name/phone to be empty until reservation | Fixed data rule | Yes |
| P1-NEW-02 | Duplicate newsletter signup | A - idempotent success; no duplicate row | Fixed behavior + database uniqueness | Yes |
| P1-CAN-01 | Cancellation/modification | A - outside core Version 1 scope | Fixed scope boundary | Yes, for lifecycle assumptions |
| P1-VAL-01 | Customer field validation/normalization | A - proportional fixed limits and normalization | Fixed behavior | Yes, for column constraints |
| P1-MSG-01 | Confirmation/error contents | B - structured confirmation and categorized errors | Fixed behavior | No; needed before API/UI design |
| P1-UI-01 | Reservation selection sequence | B - party size + date, then API-provided slots | Fixed interaction behavior | Yes if capacity-aware availability is approved |

## 4. Reservation scheduling decisions

### P1-RSV-01 - Reservation start-time interval

**Why necessary:** The SRS requires a selectable time slot but does not state which start times exist. Availability, indexes, API responses, UI choices, and near-closing behavior cannot be deterministic without an interval.

**Alternatives:**

- **A - 15 minutes:** Most flexible; creates many choices and more overlap combinations.
- **B - 30 minutes:** Balanced flexibility and simplicity for a fine-dining academic application.
- **C - 60 minutes:** Simplest, but may be unnecessarily restrictive.

**Recommendation:** **B - 30 minutes.** This supports useful choices without producing an excessive slot list.

**Configuration:** Configurable PostgreSQL business setting. Recommended allowed values: 15, 30, or 60 minutes. Recommended default: 30. Flask reads and enforces it; React never calculates an independent interval.

**Impact:** PostgreSQL stores the setting; Flask generates and validates aligned starts; React displays returned slots. A change must alter behavior without source modification.

**Tests:** Allowed/rejected setting values; slot alignment; first/last slot; changed-setting behavior; manipulated off-interval submission rejection.

### P1-RSV-02 - Reservation duration

**Why necessary:** A single start timestamp cannot determine overlap unless the occupied duration is known.

**Alternatives:**

- **A - 60 minutes:** High turnover, possibly short for fine dining.
- **B - 90 minutes:** Balanced default for this restaurant type and project complexity.
- **C - 120 minutes:** Realistic for long fine-dining service but significantly reduces capacity.

**Recommendation:** **B - 90 minutes.** Treat this as the full table-occupancy period, including ordinary turnover; do not add a second cleanup buffer initially.

**Configuration:** Configurable PostgreSQL business setting. Recommended allowed values: 60, 90, or 120 minutes. Recommended default: 90.

**Impact:** PostgreSQL must support start/end interval reasoning; Flask calculates the occupied end and availability; React may display duration but must not calculate authoritative availability.

**Tests:** Each permitted duration; rejected values; overlap/no-overlap boundaries; changed-setting behavior; last-start calculation.

### P1-RSV-03 - Valid calendar dates and closures

**Why necessary:** The SRS gives hours for every day but does not define holidays, exceptional closures, or whether every calendar date is reservable.

**Alternatives:**

- **A - All seven days using the SRS hours; no exceptional-closure feature in core scope.**
- **B - Add configurable blackout/closure dates.** More realistic but adds an entity, API logic, UI behavior, and tests not required by the SRS.
- **C - Weekdays/weekends only.** Contradicts the explicit Sunday hours and is therefore not acceptable.

**Recommendation:** **A.** Every calendar date within the approved booking window is potentially valid, subject to SRS hours, lead time, and availability. Treat exceptional closures as a future supplemental enhancement.

**Configuration:** Fixed SRS behavior. Opening hours may be represented as data for clean design, but accepted baseline values must remain the SRS values.

**Impact:** No closure table is required in the minimum database model; Flask determines valid dates from the booking window; React disables out-of-window dates.

**Tests:** Each weekday; Sunday-specific hours; booking-window boundaries; past dates; proof that no day is silently treated as closed.

### P1-RSV-04 - Earliest/latest start and behavior near closing

**Why necessary:** The SRS states opening/closing hours but not whether a reservation may start immediately before closing and continue after closing.

**Alternatives:**

- **A - Must finish by closing:** earliest start is opening; latest start is the last aligned slot whose calculated end is no later than closing.
- **B - May start through closing:** allows service after advertised closing and makes the hours misleading.
- **C - Configurable post-closing grace period:** flexible but adds an unrequested policy.

**Recommendation:** **A.** With the recommended 30-minute interval and 90-minute duration, the latest start would be 9:30 PM Monday-Saturday and 7:30 PM Sunday.

**Configuration:** Fixed derived behavior based on the explicit SRS hours plus approved interval/duration; no independent latest-start value.

**Impact:** Flask generates only starts that can finish by closing; React only presents those starts; PostgreSQL does not need a duplicate latest-start setting.

**Tests:** Opening boundary; exact closing boundary; starts that would end after closing; Monday-Saturday and Sunday cases; alternate duration/interval values.

### P1-RSV-05 - Maximum advance-booking window

**Why necessary:** Without a limit, the API and UI would accept dates indefinitely into the future.

**Alternatives:**

- **A - 30 days:** Simple and conservative.
- **B - 60 days:** Practical middle ground and already contemplated in the game plan.
- **C - 90 days:** More customer flexibility but more future inventory exposure.

**Recommendation:** **B - 60 calendar days.** Define the window inclusively from the restaurant-local current date, subject to same-day lead time.

**Configuration:** Configurable PostgreSQL business setting. Recommended integer range: 1-365 days; default 60.

**Impact:** Flask publishes and enforces the maximum date; React limits its date selector; PostgreSQL stores the setting.

**Tests:** Today/window-end inclusion; one day beyond rejection; month/year boundaries; setting changes without code changes.

### P1-RSV-06 - Same-day booking restriction/minimum lead time

**Why necessary:** “Valid” is undefined for a start only minutes away. A precise rule prevents inconsistent UI/API decisions.

**Alternatives:**

- **A - No same-day reservations:** Simplest but restrictive.
- **B - Any future aligned slot:** Easiest for demos but operationally permissive.
- **C - Minimum lead time:** Allow same-day reservations only when the start is sufficiently far in the future.

**Recommendation:** **C - 120 minutes before the reservation start.** This is reasonable for fine dining and remains easy to test through controlled clocks/fixtures.

**Configuration:** Configurable PostgreSQL business setting in minutes. Recommended range: 0-1,440; default 120.

**Impact:** Flask compares authoritative restaurant-local time to the requested start; React hides ineligible slots; PostgreSQL stores the value.

**Tests:** Exact cutoff accepted; one minute inside cutoff rejected; before/after opening; future dates unaffected; controlled server clock rather than browser clock.

### P1-RSV-07 - Restaurant timezone and authoritative current time

**Why necessary:** The restaurant is in Washington, DC, while customers and servers may be elsewhere. Date boundaries, lead time, and daylight-saving behavior otherwise vary by machine.

**Alternatives:**

- **A - Restaurant-local timezone; server/database clock authoritative.**
- **B - Customer browser timezone:** Incorrect for restaurant operating hours.
- **C - Raw UTC shown to users:** Technically consistent but poor UX and inconsistent with advertised local hours.

**Recommendation:** **A**, with `America/New_York` as the restaurant timezone inferred from the explicit Washington, DC address. Store instants consistently and display reservation times in restaurant local time.

**Configuration:** PostgreSQL business setting using a valid IANA timezone identifier; recommended default `America/New_York`. Flask/server time is authoritative; browser time is not.

**Impact:** Date-window and lead-time logic use one timezone; React labels times as restaurant local; database design later chooses appropriate timestamp types.

**Tests:** Server located in another timezone; day-boundary cases; daylight-saving dates; rejection based on server rather than manipulated client time.

## 5. Party size, table inventory, and availability

### P1-CAP-01 - Party-size restrictions

**Why necessary:** Number of guests is required, but the SRS gives no minimum/maximum and no explanation of how it affects table assignment.

**Alternatives:**

- **A - Informational only:** Accept any positive number and treat all tables identically. Simplest, but guest count does not meaningfully affect availability.
- **B - Capacity-aware range of 1-8 guests:** Supports realistic table suitability without table-combination complexity.
- **C - Larger parties and combined tables:** More realistic but materially expands assignment and concurrency logic.

**Recommendation:** **B - minimum 1, maximum 8, no table combinations in Version 1.**

**Configuration:** PostgreSQL business settings for minimum and maximum party size. Defaults 1 and 8. Maximum may not exceed the largest active table capacity unless table-combination behavior is later approved.

**Impact:** Reservations must persist guest count; Flask validates it and filters suitable tables; React collects party size before retrieving capacity-aware slots.

**Tests:** Minimum/maximum accepted; zero, negative, non-integer, and above-maximum rejected; table-capacity filtering.

### P1-CAP-02 - Whether restaurant tables have capacities

**Why necessary:** “Number of guests,” “all seats,” “30 tables,” and “available table” can describe either uniform tables or capacity-aware tables.

**Alternatives:**

- **A - 30 interchangeable tables:** One reservation occupies one table regardless of party size.
- **B - 30 persistent tables with seating capacities:** A table is eligible only if it can hold the party.
- **C - Seat-pool capacity without individual table suitability:** Conflicts with random assignment of a specific table and is not recommended.

**Recommendation:** **B.** It gives guest count operational meaning, supports credible availability, and provides strong evidence of sophisticated reservation logic without combining tables.

**Configuration:** PostgreSQL business data (30 table records with capacity), not Flask configuration. The SRS-mandated total remains exactly 30.

**Impact:** A restaurant-table entity and capacity attribute are needed; Flask queries eligible available tables; React must know party size before slot discovery.

**Tests:** Exactly 30 active tables; capacity suitability; different availability for small/large parties; no assignment to an undersized table.

### P1-CAP-03 - Initial 30-table capacity distribution

**Why necessary:** If capacity-aware tables are approved, deterministic setup and full-capacity tests require exact capacities.

**Alternatives:**

- **A - All 30 tables seat four:** Very simple but less useful for varied party sizes.
- **B - Mixed inventory:** 10 two-seat, 12 four-seat, 6 six-seat, and 2 eight-seat tables (30 total, 120 seats).
- **C - Another owner-approved distribution.**

**Recommendation:** **B.** It supports the recommended 1-8 party range and realistic capacity differences while remaining understandable in the demo.

**Configuration:** PostgreSQL development/business seed data. Individual tables and capacities may be data-managed later, but the initial approved distribution should be repeatable.

**Impact:** Database seed/model; API availability by party size; UI slot results vary by guest count.

**Tests:** Counts per capacity; total equals 30; full-capacity scenarios for multiple party sizes; repeatable seed behavior.

### P1-CAP-04 - Definition of table availability and random assignment pool

**Why necessary:** The SRS requires a random available table but does not define “available” or the eligible random pool.

**Alternatives:**

- **A - No overlap only; ignore capacity.** Suitable only if tables are interchangeable.
- **B - Active table, sufficient capacity, and no overlapping reservation; choose randomly among every eligible table.**
- **C - Prefer the smallest sufficient capacity, then randomize within that capacity class.** More operationally efficient but narrows the SRS random pool through an added optimization.

**Recommendation:** **B.** It is capacity-aware while remaining closest to the SRS requirement for random assignment.

**Configuration:** Fixed business behavior. Table active/capacity values are PostgreSQL data; overlap uses approved duration.

**Impact:** PostgreSQL must support efficient eligible-table queries and integrity; Flask performs/coordinates random selection transactionally; React receives slots that have at least one eligible table for the selected party size.

**Tests:** Eligibility; random result always belongs to eligible set; unavailable/undersized/overlapping tables excluded; zero eligible tables returns full; concurrency protection later in Prompt 7.

### P1-RSV-08 - Overlap boundary and turnover buffer

**Why necessary:** A deterministic overlap rule must state whether one reservation may start exactly when another ends and whether extra turnaround time is required.

**Alternatives:**

- **A - Half-open occupancy interval `[start, end)`; back-to-back allowed; configured duration includes ordinary turnover.**
- **B - Add a separate configurable buffer after each reservation.** More realistic but adds policy and reduces availability.
- **C - Treat touching intervals as overlapping.** Equivalent to an undefined buffer and difficult to explain.

**Recommendation:** **A.** Reservation A ending at 7:00 PM does not overlap Reservation B starting at 7:00 PM. No separate buffer is added in core scope.

**Configuration:** Fixed behavior. Reservation duration remains configurable.

**Impact:** Database exclusion/transaction design and Flask availability must use the same boundary semantics; React is indirectly affected through returned slots.

**Tests:** Partial containment; enclosing interval; identical interval; start-at-existing-end accepted; end-at-existing-start accepted; one-minute overlap rejected.

### P1-RSV-09 - Duplicate reservation submissions

**Why necessary:** Double-clicks, retries, or repeated submissions can create two reservations for the same customer and start time, even if different tables remain available.

**Alternatives:**

- **A - Allow duplicates until capacity is exhausted:** Simple but poor UX and wasteful.
- **B - One reservation per customer per start time:** An exact repeat returns the existing confirmation; a changed repeat conflicts and asks the user to review the booking.
- **C - Require an API idempotency key:** Strong retry behavior but adds client/API complexity beyond the assignment.

**Recommendation:** **B.** It is understandable, demonstrable, and can be backed by database integrity.

**Configuration:** Fixed behavior. Customer identity depends on P1-CUS-01.

**Impact:** Database uniqueness and lookup; Flask distinguishes exact retry from conflicting duplicate; React prevents double submit and handles existing/conflict responses.

**Tests:** Double-click/retry; same email with same start; same email with different start; different email with same start; concurrent duplicates.

## 6. Customer and newsletter decisions

### P1-CUS-01 - Duplicate customer handling and customer reuse

**Why necessary:** The SRS says to insert new customer records but does not define repeat customers. Always inserting duplicates harms integrity; over-aggressive matching can merge different people.

**Alternatives:**

- **A - Always create a customer for every reservation:** Literal and simple, but produces duplicates.
- **B - Case-insensitive normalized email identifies a customer:** Insert when new; otherwise reuse and update current nonblank contact data.
- **C - Match on email plus name or phone:** Reduces some mistaken merges but creates ambiguity when one value changes.

**Recommendation:** **B.** Trim/lowercase email for uniqueness. When reusing a customer, update name and a provided phone to the latest nonblank values; an omitted phone does not erase an existing phone. A true newsletter opt-in is never reset by a reservation submission.

**Configuration:** Fixed behavior enforced through PostgreSQL case-insensitive uniqueness/normalized value and Flask service logic.

**Impact:** Customer email becomes the stable lookup key; database supports reuse; API consistently returns one customer identity; UI need not expose identity logic.

**Tests:** New email inserts; case/whitespace variants reuse; changed name/phone update; omitted phone preserved; newsletter true preserved; concurrent first use of same email.

### P1-NEW-01 - Storage model for newsletter-only visitors

**Why necessary:** The newsletter form requires only email, while the SRS minimum Customers table also contains name and phone. A newsletter-only visitor cannot provide all reservation customer data.

**Alternatives:**

- **A - Store newsletter-only visitors in Customers:** Email is required/unique; name and phone may be empty until a later reservation; newsletter flag is true.
- **B - Use a separate Newsletter Subscribers table:** Clean separation, but the required Customers newsletter field then duplicates or must derive state.
- **C - Insert placeholder names:** Preserves non-null name but stores false data and is not acceptable.

**Recommendation:** **A.** It is the smallest model aligned with the SRS’s Customers fields. A later reservation enriches the same email-identified record.

**Configuration:** Fixed data/lifecycle rule.

**Impact:** Customer name and phone must permit absence for newsletter-only records; Flask upserts by email; React newsletter form remains email-only as required.

**Tests:** Newsletter-only insert; later reservation enriches same customer; reservation-created customer can later subscribe; no placeholder data.

### P1-NEW-02 - Duplicate newsletter signup behavior

**Why necessary:** Repeated signups may otherwise create duplicate records or confusing errors.

**Alternatives:**

- **A - Idempotent success:** Keep one customer/subscription state and return the same generic success response.
- **B - Return a specific “already subscribed” response:** Informative but reveals stored subscription status.
- **C - Store every submission:** Creates duplicates and is not recommended.

**Recommendation:** **A.** Normalize email, preserve one record, set newsletter signup true, and return a user-friendly generic success whether newly or previously subscribed.

**Configuration:** Fixed behavior plus database uniqueness.

**Impact:** Database has one normalized email/customer; Flask performs insert-or-update/idempotent handling; React shows a consistent success state.

**Tests:** New signup; exact duplicate; case/whitespace duplicate; simultaneous duplicates; invalid email; existing reservation customer subscribes.

## 7. Lifecycle, validation, messaging, and UI decisions

### P1-CAN-01 - Cancellation and modification behavior

**Why necessary:** If cancellation exists, availability must distinguish active/canceled reservations and define release timing. The SRS does not request cancellation or modification.

**Alternatives:**

- **A - Exclude cancellation/modification from core Version 1:** Every saved reservation remains availability-blocking.
- **B - Add cancellation only:** Requires identity/authorization, status, API, UI, and tests.
- **C - Add cancellation and modification:** Largest scope expansion.

**Recommendation:** **A.** Treat cancellation, modification, and no-show management as optional future enhancements. This avoids inventing an unsupported customer-management workflow.

**Configuration:** Fixed scope boundary, not a setting.

**Impact:** Minimum schema need not support public cancellation behavior; Flask/React expose no cancellation operation. A future request must use the supplemental-requirement impact process.

**Tests:** No cancellation endpoints/controls; saved reservations continue blocking their intervals; requirements audit confirms the feature is not required.

### P1-VAL-01 - Customer input validation and normalization

**Why necessary:** The SRS requires basic email validation but does not define field lengths, whitespace, phone syntax, or normalization. Database columns and API behavior need bounded deterministic rules.

**Alternatives:**

- **A - Proportional fixed rules:** Name trimmed, 1-100 characters when required; email trimmed, syntactically valid, maximum 254 characters, case-insensitive for identity; phone optional, trimmed, 7-20 characters using digits, spaces, `+`, parentheses, hyphens, or periods.
- **B - Minimal nonempty checks:** Simpler but weak and inconsistent.
- **C - Strict international standards/libraries for all fields:** More robust but excessive for the assignment and may reject reasonable input.

**Recommendation:** **A.** Party size must also be an integer within the approved bounds. Flask is authoritative; React mirrors the rules for immediate feedback.

**Configuration:** Fixed validation behavior. These are technical safety bounds rather than restaurant policies; detailed error wording is fixed in the API contract later.

**Impact:** Database lengths/nullability; Flask validation/normalization; React field limits and inline feedback.

**Tests:** Boundary lengths; whitespace-only name; valid/invalid email; case normalization; absent/valid/invalid phone; server validation when client controls are bypassed.

### P1-MSG-01 - Reservation confirmation and error information

**Why necessary:** The SRS requires confirmation/error messages but not their contents. API and UI contracts need predictable outcomes.

**Alternatives:**

- **A - Generic success/error only:** Meets the narrow wording but is difficult to verify and less useful.
- **B - Structured confirmation and categorized errors:** Confirmation includes reservation ID, restaurant-local date/time, party size, and assigned table; errors distinguish validation, duplicate/conflict, fully booked, and temporary server/network failure without exposing internals.
- **C - Add confirmation email/SMS:** Not required and expands scope.

**Recommendation:** **B.** Do not add email/SMS notifications unless separately approved.

**Configuration:** Fixed behavior; exact JSON/status design belongs to Prompt 11 and exact UI copy to the React design phase.

**Impact:** Database supplies identifiers; Flask returns structured results; React displays accessible success/error states.

**Tests:** Required confirmation fields; full-slot message asks for another time; field-specific validation; duplicate/conflict; internal errors do not leak implementation details.

### P1-UI-01 - Controlled time selection and capacity-aware sequence

**Why necessary:** The SRS allows a dropdown/time picker but does not state whether arbitrary time entry is allowed. Capacity-aware availability also requires party size before slot discovery.

**Alternatives:**

- **A - Free date/time entry, validated after submission:** Simplest UI but poor experience and permits unsupported choices.
- **B - Select party size and date, request valid/available slots from Flask, then select one returned slot:** Prevents ordinary unsupported input while retaining backend authority.
- **C - Select date/time before party size:** Works only if displayed availability ignores table capacity and may fail after party size is entered.

**Recommendation:** **B.** This confirms the reservation-time control described in the game plan. Flask must still reject manipulated or stale submissions.

**Configuration:** Fixed interaction behavior. Slot interval/duration/window/lead time remain PostgreSQL business settings.

**Impact:** PostgreSQL supports capacity-aware availability; Flask slot discovery accepts date and party size; React sequence becomes party size -> date -> returned slots -> customer details -> submit.

**Tests:** No arbitrary time entry; changing party size refreshes slots; loading/empty/error states; stale slot rejected at submission; direct manipulated API request rejected.

## 8. Items intentionally deferred to later prompts

These do not need a Prompt 1 business-rule choice unless the user wants to tighten them now:

| Item | Planned resolution stage | Reason for deferral |
|---|---|---|
| Exact PostgreSQL tables, columns, types, keys, indexes, and constraints | Prompts 4-6 | These are data-model/logical-design decisions after business rules are approved. |
| Transaction isolation, locking, exclusion constraints, retry details | Prompt 7 | Concurrency design depends on the approved schema and overlap rules. |
| REST paths, methods, JSON shapes, and HTTP status codes | Prompts 10-11 | These depend on the frozen PostgreSQL contract. |
| React visual design, breakpoints, and component structure | Prompts 18-20 | These belong to the React phase after the API is frozen. |
| Holiday closures/blackout dates | Future Prompt 29 if desired | Optional enhancement under recommended P1-RSV-03. |
| Confirmation email/SMS, waitlist, accounts, admin reservation management | Future Prompt 29 if desired | Not required by SRS/rubric. |

## 9. Recommended approval sequence

### Batch A - Reservation calendar and time rules

- P1-RSV-01 through P1-RSV-08
- P1-UI-01

### Batch B - Party size, table inventory, and duplicates

- P1-CAP-01 through P1-CAP-04
- P1-RSV-09

### Batch C - Customer, newsletter, lifecycle, validation, and messaging

- P1-CUS-01
- P1-NEW-01 through P1-NEW-02
- P1-CAN-01
- P1-VAL-01
- P1-MSG-01

## 10. Response template

Choices may be approved, modified, rejected, or deferred individually. For example:

```text
Batch A
P1-RSV-01: Approve B (30 minutes)
P1-RSV-02: Approve C (120 minutes)
P1-RSV-03: Approve recommendation
P1-RSV-04: Approve recommendation
P1-RSV-05: Modify - use 90 days
P1-RSV-06: Need more explanation
P1-RSV-07: Approve recommendation
P1-RSV-08: Approve recommendation
P1-UI-01: Approve recommendation
```

Alternatively:

```text
Approve Batch A exactly as recommended.
```

An approval response authorizes requirements recording during Prompt 2; it does not authorize database design or code generation.

## 11. Prompt 1 completion status

The SRS requirements have been preserved, operational gaps have been identified, alternatives and recommendations have been supplied, and database/API/UI/testing impacts have been traced. No recommendation has been approved, implemented, or added to the Project Requirements Addendum.

