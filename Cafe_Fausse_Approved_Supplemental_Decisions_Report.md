# Cafe Fausse Approved Supplemental Decisions Report

**Report date:** 2026-08-27

**Last amended:** 2026-09-02 for PRA-030

**Status:** Informational summary of approved decisions

**Controlling record:** `Cafe_Fausse_Project_Requirements_Addendum.md`

## 1. Purpose

The Software Requirements Specification (SRS) and Rubric remain the authoritative project sources. Where those documents were silent or left implementation-significant behavior underspecified, the team obtained explicit decisions and recorded them in the **Cafe Fausse Project Requirements Addendum (PRA)**.

This report consolidates the active decisions in PRA-001 through PRA-030 for convenient review. It does not replace the SRS, Rubric, or PRA, and it does not create new requirements. If this summary conflicts with the controlling PRA, the controlling PRA governs, subject to the SRS and Rubric.

## 2. Where the decisions were documented

The decisions are maintained in:

- `Cafe_Fausse_Project_Requirements_Addendum.md`

The project deliberately does not place version numbers in filenames because Git provides file version history. An internal document-version value such as `2.3`, if retained in the document metadata, identifies document content and is not part of the repository filename. This unversioned-filename convention applies to every project file that previously used a version number in its filename.

The controlling addendum contains the decision identifier, approval provenance, exact approved requirement, defaults and validation rules, rationale, SRS/rubric refinement, implementation impacts, test impacts, demonstration notes, and dependencies.

## 3. Governing status

- Only explicitly approved PRA entries are active.
- PRA-001 through PRA-030 are the approved decision set summarized below.
- SRS and Rubric requirements are not weakened or superseded by the PRA.
- Items labeled as future enhancements in the PRA are inactive unless separately approved.
- Technical designs may implement an approved rule, but may not silently change its business meaning.

## 4. Approved supplemental decisions

### 4.1 Project governance and delivery strategy

#### PRA-001 — Architecture sequence

Implement and verify the solution in the strict sequence **PostgreSQL → Flask REST API → React/JSX → end-to-end integration**. Each layer must have stable, testable contracts before the next depends on it.

#### PRA-002 — Least-to-most implementation

Within each architectural layer, build the smallest verifiable foundation first and add behavior incrementally. Avoid broad, speculative implementation before the prerequisite contract is stable.

#### PRA-003 — Testing throughout implementation

Testing is part of implementation rather than an end-only activity. Unit, integration, and end-to-end verification are added and run at the layer where the relevant behavior becomes testable.

#### PRA-004 — Authority and approval control

The SRS and Rubric are the governing baseline. Missing or ambiguous business behavior must be identified and explicitly approved before it is treated as an active requirement. No prompt or implementation may invent requirements.

#### PRA-005 — Configuration preference

Where an approved supplemental business rule can reasonably vary, prefer PostgreSQL-backed configuration over duplicated hard-coded values, while preserving any SRS-mandated initial or default value.

### 4.2 Reservation scheduling, availability, and retry behavior

#### PRA-006 — Reservation start interval

Reservation starts use a configurable interval. The default is **30 minutes**; permitted values are **15, 30, or 60 minutes**.

#### PRA-007 — Reservation duration

Reservation duration is configurable. The default is **90 minutes**; permitted values are **60, 90, or 120 minutes**. Version 1 adds no separate turnover buffer.

#### PRA-008 — Reservable calendar days

Every calendar day is potentially reservable under the recurring weekly schedule. Version 1 has no holiday or date-specific closure/exception behavior unless separately approved.

#### PRA-009 — Opening and closing boundaries

A reservation may start at opening. The latest valid start must align to the configured interval and allow the full configured duration to end by closing. With the approved defaults, the last start is **9:30 PM Monday–Saturday** and **7:30 PM Sunday**.

#### PRA-010 — Advance booking window

The advance booking window is configurable and measured using restaurant-local dates. The default is **60 days**, inclusive; the permitted range is **1–365 days**.

#### PRA-011 — Same-day lead time

Same-day reservations are allowed only when the requested start is at least the configured lead time after authoritative restaurant-local server time. The default is **120 minutes**; the permitted range is **0–1440 minutes**.

#### PRA-012 — Restaurant timezone and clock authority

Reservation rules and displayed times use the IANA timezone **`America/New_York`**. The timezone is PostgreSQL-backed business configuration. Server/database time is authoritative; React displays restaurant-local time regardless of the browser or development-machine timezone.

#### PRA-013 — Overlap boundary

Occupancy uses half-open intervals **`[start, end)`**. Endpoint-touching reservations are allowed; two reservations overlap when each begins before the other ends. The rule applies to every assigned table, with no additional turnover buffer.

#### PRA-014 — Duplicate and retry-safe reservation handling

A normalized customer email may not hold overlapping reservations. An exact retry of a successful booking returns the existing confirmation without creating a duplicate; a different overlapping request for the same customer is rejected. Other customers may overlap only when sufficient exclusive tables remain. React disables submission while pending, opens confirmation only on success, and preserves the form on errors; Flask and PostgreSQL remain authoritative.

### 4.3 Table inventory, capacity, and assignment

#### PRA-015 — Party-size bounds and derived capacity

Party size is an integer from **1** through the total configured seating capacity of the 30 current bookable tables. The maximum is derived rather than separately configured. The initial theoretical maximum is **120**, but a specific time slot may be unavailable even when the requested party size is within that bound.

#### PRA-016 — Thirty persistent bookable tables

Version 1 contains exactly **30 active bookable tables** stored as identifiable PostgreSQL business data. The schema may permit future evolution, but adding more than 30 tables is not active Version 1 behavior.

#### PRA-017 — Individually configurable table capacities

Each table has an individually configurable capacity in PostgreSQL. All 30 tables initially have capacity **4**, producing the initial total capacity of **120**. Capacity changes affect derived totals and eligibility prospectively.

#### PRA-018 — Exclusive multi-table assignment

A reservation may receive one or more tables. Eligible combinations are ranked by:

1. Minimum number of tables.
2. Least unused seating.
3. Random selection among otherwise equal combinations.

Every assigned table is exclusive for the entire reservation interval. Unused seats cannot be shared, assignments commit atomically, and customers do not choose tables. Version 1 does not model table adjacency or combinability. If no eligible combination exists, the slot is unavailable/full.

### 4.4 Customer identity and newsletter behavior

#### PRA-019 — Customer identity and synchronized preference

Customer name is stored as required first name, optional middle initial, and required last name. Reservation and newsletter forms require email and confirmation email. A customer is identified by normalized email and matched using normalized first/last name; phone is not identity. Identity mismatches are rejected generically and existing names are not silently overwritten.

For existing customers, an omitted middle initial preserves stored data, an empty stored value may be populated, and conflicting populated values are rejected. Phone is optional and reservation-only; it may populate a new or blank value but does not silently overwrite a different existing value. There is one customer per normalized email.

After valid identity input, React performs a debounced asynchronous lookup and synchronizes the newsletter checkbox to the stored state. Reservation-linked preference changes commit only with a successful booking. A dedicated preference form can independently subscribe or unsubscribe. Version 1 includes no authentication.

#### PRA-020 — Customers as newsletter source of truth

`Customers` is the single source of truth for current newsletter status; Version 1 has no separate subscriber store. The dedicated form collects structured name, email and confirmation, plus an explicit checkbox. A new selected customer is created; a new unselected submission creates no record. A matching existing customer may set the preference true or false without changing other customer or reservation data. Unsubscription retains the customer. Repeating the current state succeeds idempotently, and only current state—not preference history—is stored.

#### PRA-021 — Concurrent and retry-safe preference updates

Newsletter updates set a final Boolean state and are idempotent. Concurrent creates for one normalized email produce one customer; conflicting identity data produces a generic mismatch. For concurrent valid updates, the last committed write wins. Responses return authoritative state and React synchronizes to it. Booking-linked changes share the booking transaction; dedicated changes are independent. Timed-out requests may be retried safely. Version 1 does not verify email ownership.

### 4.5 Reservation lifecycle, validation, messages, and UI

#### PRA-022 — No cancellation or modification in Version 1

Version 1 has no customer-facing reservation cancellation, modification, or rescheduling UI/API. A committed reservation remains active and blocks all assigned tables for its interval. Multi-table reservations cannot be partially modified or cancelled. Newsletter unsubscription is independent. Controlled development/test/demo cleanup is not a customer feature.

#### PRA-023 — Authoritative validation

React provides immediate validation and Flask revalidates authoritatively. Approved field rules include:

- First and last names: required; trimmed/collapsed; **1–100 characters**; at least one letter; case-insensitive matching; display punctuation and accents preserved.
- Middle initial: PRA-023 originally allowed an optional period on input; PRA-030 supersedes only that allowance. The active request rule is optional input of exactly one alphabetic character, maximum length one, with no period. Lowercase may normalize uppercase, storage remains uppercase without a period, and read-only names may display the initial with or without a period.
- Email and confirmation: required on both forms; trimmed; valid syntax; maximum **254 characters**; lowercase canonical value; values must match; confirmation is not stored.
- Phone: optional on reservations; approved punctuation is allowed; **7–15 digits**; normalized to digits for comparison; update behavior follows PRA-019.
- Party size: integer from 1 through the current derived maximum.
- Newsletter preference: Boolean, synchronized after valid identity lookup.

Reservation submission is revalidated against the current timezone, booking window, lead time, start interval, operating hours, duration, closing boundary, capacity, table exclusivity, and same-customer overlap rules. Stale asynchronous responses cannot overwrite newer input, submission is disabled while pending, and user-facing errors are nontechnical.

#### PRA-024 — Confirmation, errors, and logging

Successful reservations display a distinct confirmation containing the reference, customer name, restaurant-local start/end, party size, all assigned tables, final newsletter state, and restaurant address/phone. The application must not claim email or SMS delivery. Exact retries return the same reservation confirmation.

Full/stale availability, customer overlap, identity mismatch, validation failure, ambiguous network result, newsletter lookup failure, and unexpected failure have appropriate recovery behavior. A newsletter lookup failure shows indeterminate status but may allow booking without changing the preference. User messages are friendly, nontechnical, and accessible. Flask records technical diagnostics while minimizing/redacting customer data and excluding confirmation-email values, secrets, and credentials; React errors may be logged to the browser console.

#### PRA-025 — Availability-first UI with authoritative revalidation

The reservation flow is: party size → New York date → Flask availability request → slot selection → structured customer details → newsletter synchronization → review/submit → Flask revalidation → confirmation or in-place failure.

Flask returns every legitimate aligned start for the selected date and party size, marking each available or unavailable. React displays the full daily schedule; available slots are selectable, while unavailable slots are disabled and distinguished accessibly without relying on color alone. React accepts no arbitrary times, computes no authoritative availability or table assignment, offers no table choice, and promises no tables before success. Date or party-size changes invalidate and refetch selection. Every displayed result is provisional until Flask revalidates it. Availability responses expose no customer/reservation details, table assignments, or unnecessary capacity internals.

### 4.6 Persistent-data lifecycle and operating hours

#### PRA-026 — Prospective configuration and repeatable reinitialization

Confirmed reservations retain their original occupancy interval, party size, and exclusive table assignments. Later reservation-configuration or table-capacity changes affect subsequent calculations and reservations only; they do not recalculate, invalidate, or alter existing bookings. Controlled reset/reinitialization may delete designated nonproduction data for development, testing, or demonstration. Such reset tooling is not customer functionality.

#### PRA-027 — Database-generated reservation fingerprint

PostgreSQL generates and stores a deterministic, versioned, opaque reservation fingerprint from the resolved customer identifier, canonical reservation start timestamp, and party size. It excludes name/email text, middle initial, phone, newsletter state/action, assigned tables, reservation end, and current configuration values. A fingerprint match is only a lookup aid; PostgreSQL also verifies the underlying facts to guard against collisions.

An equivalent retry returns the existing confirmation and current authoritative newsletter state without replaying the retry's newsletter action. Clients do not generate the fingerprint.

#### PRA-028 — Version 1 retention

During normal Version 1 operation, customer, reservation, and table-assignment records are retained indefinitely until a controlled nonproduction reset. Past reservations stop affecting availability because their intervals have elapsed, not because records are deleted. Newsletter unsubscription retains the customer with preference set to false. Version 1 performs no automatic deletion, archival, anonymization, or retention-period purge.

#### PRA-029 — PostgreSQL-backed weekly operating hours

The recurring weekly schedule is authoritative PostgreSQL business data. Initial and normal Version 1 seed values must exactly match the SRS:

- Monday–Saturday: **5:00 PM–11:00 PM**
- Sunday: **5:00 PM–9:00 PM**

Flask reads the current schedule for slot generation, closing validation, and client delivery rather than duplicating the hour values as business constants. React displays API-supplied hours and consumes API-supplied availability. Controlled test/demo data may use an alternate recurring schedule without changing business logic, but reset tooling must restore the SRS baseline. Changes apply prospectively. Version 1 has no holiday, date-specific exception, or schedule-history behavior unless separately approved.

#### PRA-030 — One-character middle-initial request input

Middle initial is optional. Request input, when supplied, is exactly one alphabetic character with maximum length one and no period. Lowercase may normalize to uppercase, and the stored value remains uppercase without a period. Invalid request input uses `Enter one letter.` where a field message is documented. Read-only full-name text may continue to display the initial with or without a period. PRA-030 supersedes only PRA-023 / P1-VAL-01's optional-period request allowance; every other PRA-023 rule remains active.

## 5. Approved defaults and boundaries at a glance

| Area | Approved value or rule |
|---|---|
| Start interval | 30 minutes by default; allowed 15/30/60 |
| Duration | 90 minutes by default; allowed 60/90/120 |
| Turnover buffer | None in Version 1 |
| Advance window | 60 days inclusive by default; allowed 1–365 |
| Same-day lead | 120 minutes by default; allowed 0–1440 |
| Timezone | `America/New_York`; server/database authoritative |
| Overlap | Half-open `[start, end)`; endpoint touching allowed |
| Bookable tables | Exactly 30 in Version 1 |
| Initial table capacity | 4 each |
| Initial derived capacity | 120 |
| Assignment | Minimum tables, then least waste, then random tie-break |
| Operating hours | Mon–Sat 5 PM–11 PM; Sun 5 PM–9 PM |
| Cancellation/modification | Not available in Version 1 |
| Data retention | Retained during normal operation until controlled nonproduction reset |
| Holiday/date exceptions | Not active in Version 1 |

## 6. Items intentionally excluded from the active decision set

The controlling PRA contains a Future Enhancements section. Those entries are recorded for traceability but are **inactive and unapproved** unless a later explicit approval activates them. They must not be represented as current SRS, Rubric, or Version 1 requirements.

Examples of out-of-scope areas include functionality such as customer reservation cancellation/modification, authentication, historical newsletter tracking, automated data-retention processing, and holiday/date-specific scheduling unless separately approved. This sentence is a scope reminder, not an activation of any future enhancement.

## 7. Traceability summary

| Decision range | Origin | Subject |
|---|---|---|
| PRA-001–PRA-005 | Project governance | Authority, sequencing, incremental delivery, testing, configuration |
| PRA-006–PRA-025 | Prompt 1 approvals | Reservation, capacity, identity, newsletter, validation, UI, messaging |
| PRA-026–PRA-028 | Prompt 4 approvals | Configuration lifecycle, retry identity, retention |
| PRA-029 | Prompt 5 approval | PostgreSQL-backed operating-hours authority |
| PRA-030 | User-approved amendment | One-character middle-initial request input; supersedes only P1-VAL-01's optional-period allowance |

## 8. Review conclusion

Yes, the project documented the decisions needed because the SRS and Rubric were silent or underspecified. The controlled source is `Cafe_Fausse_Project_Requirements_Addendum.md`. Git provides its version history, so no version number belongs in the filename. The 30 active PRA decisions are summarized in this report without activating future enhancements or changing frozen implementation conclusions.
