# Cafe Fausse Project Requirements Addendum

**Addendum version:** 1.0  
**Established:** 2026-08-13  
**Relationship to baseline:** Supplements but may not contradict `SRS(1).pdf`, `Rubric(1).pdf`, or the Project Requirements Baseline  
**Change control:** Only explicitly approved decisions become active addendum requirements

## 1. Purpose

This document is the controlled record for supplemental business rules, refinements, constraints, and design decisions approved during implementation. Unresolved questions and optional ideas remain in the baseline until approval; they do not enter this addendum as active requirements.

## 2. Precedence and change rules

1. `SRS(1).pdf` and `Rubric(1).pdf` remain fixed and authoritative.
2. This addendum may clarify a gap but may not contradict, remove, or weaken an explicit SRS or rubric requirement.
3. Each active entry must record approval, affected requirements, rationale, and verification impact.
4. Revisions preserve history: an entry is superseded or withdrawn, not silently overwritten.
5. Configurable business rules are preferred over hard-coded values when the authoritative documents do not mandate a literal value.
6. Optional enhancements require explicit scope approval before they are activated here.

## 3. Status definitions

| Status | Meaning |
|---|---|
| Approved | Active project requirement/decision |
| Superseded | Replaced by a later approved entry |
| Withdrawn | Explicitly removed from active supplemental scope without altering authoritative requirements |

## 4. Approved entries

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

## 5. Decision record template

Use the following structure for each future approval:

### PRA-XXX - Short title

| Field | Value |
|---|---|
| Type | Business rule / refinement / constraint / design decision / optional enhancement |
| Status | Approved / Superseded / Withdrawn |
| Approved by/date | Name, approval reference, date |
| Decision | Exact, testable approved statement |
| Affected requirements | Requirement and decision IDs |
| Configuration | Configurable parameter/default, or “not applicable” |
| Rationale | Why the decision was selected |
| Verification | Tests, inspection, or demonstration evidence |
| Supersedes | Earlier PRA ID, or “none” |

## 6. Change log

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-08-13 | Established addendum governance and recorded five already-approved project constraints. No unresolved business rule or optional enhancement was approved. |

