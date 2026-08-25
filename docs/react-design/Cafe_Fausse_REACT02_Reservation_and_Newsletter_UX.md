# Cafe Fausse REACT-02 Reservation and Newsletter UX Design

**Status:** APPROVED AND FROZEN

**Increment:** REACT-02 / roadmap UI-02

**Date:** 2026-08-24

**Scope:** Design only; no React, JSX, CSS, JavaScript, TypeScript, package, test, toolchain, or live-integration work

**Next authorized increment:** Prompt 21 - complete UI/UX and React test strategy

## 1. Baseline and approval state

Phase 0 was performed read-only before this artifact was created.

| Check | Result |
|---|---|
| Branch | `main` |
| Full HEAD | `82adaddf7e235b8556a3cdcd260c4e0ac305b66c` |
| Remote relation | `HEAD`, `origin/main`, and `origin/HEAD` identify the same commit; ahead/behind is `0/0` |
| REACT-01 | Commit `82adadd` records `REACT-01 approved`; the artifact is `APPROVED AND FROZEN` and authorizes Prompt 20 |
| API-09 / Hard Gate 2 | Approved and frozen at `73dbd68b6c3edd6d7aae3afb233eb4727e8cf1e2` and preserved in current history |
| React implementation/build tooling | None found |
| Initial worktree/index | The real Git index was unchanged. The only worktree item was the user-supplied untracked Prompt 20 file; it is treated as the explicit input for this task and remains unmodified. |

The approved REACT-01 boundaries are preserved: `ReservationsPage`, `ReservationFeatureBoundary`, `ReservationContextBoundary`, `AvailabilityArea`, `CustomerAndReservationFormArea`, `ReservationReviewArea`, `ReservationFeedback`, `ReservationConfirmationView`, and reusable `NewsletterPreferences`. No authoritative-source conflict or new business-rule ambiguity was found.

## 2. Authoritative sources reviewed

Applied in required precedence order:

1. repository-root `AGENTS.md` (no nested `AGENTS.md` exists);
2. `docs/SRS(1).pdf`, all seven pages;
3. `docs/Rubric(1).pdf`, all nine pages;
4. Project Requirements Addendum v2.2.1, especially PRA-006 through PRA-025 and PRA-029;
5. least-to-most roadmap v1.1.1, especially UI-02 and its UI-03 boundary;
6. `database/POSTGRESQL_CONTRACT_FOR_FLASK.md` v1.1 and applicable frozen database authority;
7. API-01 Backend Operation Inventory v1.0.3;
8. API-02 Flask REST Contract v1.0.2;
9. API-03 Flask Architecture, Configuration, and Test Strategy v1.0.4;
10. approved API-07 context/availability implementation report;
11. approved API-08 reservation implementation report and reconciliations;
12. API-09 / Hard Gate 2 verification report;
13. approved/frozen REACT-01 architecture and Gallery analysis;
14. current route, validation, response, and serialization code only to confirm frozen public behavior;
15. Prompt 20.

The SRS requires a time slot, number of guests, customer name, email, optional phone, validity/availability checking, success/full feedback, and newsletter signup. Approved supplemental rules refine customer name into required first/last plus optional middle initial and require confirmation email in both forms.

## 3. Reservation interaction model

### 3.1 Recommended pattern

Use one progressive form with three visibly grouped sections and an inline review summary, not a route-changing wizard or ceremonial stepper:

1. **Choose a date and party size** - enabled only after OP-01 succeeds.
2. **Choose a time** - populated only by OP-02; all returned slots remain visible.
3. **Your details and newsletter preference** - may be filled while a slot remains selected.
4. **Review and reserve** - a compact summary and one submission control, not a separate required page.

This pattern keeps context visible, supports browser/mobile reading order, permits correction without Back/Next state loss, and avoids inventing a business requirement to complete unrelated steps. Progressive disclosure may collapse explanatory copy but must not unmount or discard entered values.

### 3.2 UX state catalogue

| State | Visible experience | Enabled actions / transition |
|---|---|---|
| First load / context loading | Page heading, brief reservation explanation, context skeleton, one polite loading status | Navigation remains usable; booking controls unavailable until OP-01 resolves |
| Context blocked | Nontechnical context-load failure; no fabricated hours/date bounds/capacity | Explicit “Try again” repeats OP-01; static site navigation/contact content remains usable |
| Context ready / inputs incomplete | Current restaurant-local timezone label, date bounds, policy summary where helpful, date and party controls | User supplies valid date and party size |
| Availability ready to request | Current valid date/party summarized; no old times shown as current | “Check availability” calls OP-02 |
| Availability loading | Current request key shown; prior result removed or clearly marked stale and noninteractive | Suppress duplicate request; changing date/party invalidates this request |
| Slot selection | Every returned legitimate slot in API order; available selectable, unavailable visible/nonselectable | Selecting an available slot reveals/completes details and review regions |
| Customer information | Structured fields, inline guidance, reservation summary | Valid identity makes OP-03 eligible; values may be entered before lookup completes |
| Newsletter synchronization | Explicit `not checked`, `checking`, `matched`, `not found`, `conflict`, or `indeterminate` status beside checkbox | Current-identity result may initialize an untouched checkbox; deliberate user choice is never overwritten |
| Submission ready | Review shows selected API facts and entered identity; disabled guidance is cleared | One “Reserve table” action invokes OP-05 |
| Submission pending | Submitted snapshot retained; fields and mutation control locked; progress announced | No second submission or edits until result is classified |
| Confirmation | Distinct `ReservationConfirmationView` using only OP-05 facts | Return Home or start a new reservation |
| Recoverable known error | In-place alert and field/section guidance; useful input preserved | Correct, refresh, or explicitly retry as dictated by public code/flags |
| Outcome unknown | Prominent distinct warning; exact submitted snapshot retained and locked for safe recovery | Explicitly resubmit the same request; do not claim failure or invent lookup |

## 4. OP-01 initial context UX

`ReservationContextBoundary` calls `GET /api/v1/reservation-context` once on reservation-page entry. It accepts no body or query.

### 4.1 Facts React may use

- fixed SRS address and phone returned in `restaurant`;
- `restaurant_timezone`;
- seven ordered `weekday_hours` entries;
- `start_interval_minutes`, `reservation_duration_minutes`, `advance_window_days`, and `same_day_lead_minutes`;
- inclusive `minimum_local_date` and `maximum_local_date`;
- current `maximum_party_size`.

OP-01 does **not** return a current time or timestamp. React therefore must not display a fabricated server-current clock or derive authoritative restaurant time from the browser. The database-clock-derived minimum date is the authoritative earliest date. The timezone may be named in date/time guidance, and the returned hours/policy may be summarized, but business eligibility still comes from OP-02/OP-05.

### 4.2 Loading, success, and failure

- Reserve stable layout space with text-line/control skeletons marked non-content. Announce “Loading reservation options” once; do not announce every skeleton change.
- On success, replace the skeleton atomically and announce “Reservation options are ready.” Do not move focus automatically if the user has navigated elsewhere.
- On `503 service_unavailable`, transport failure, or unexpected known read failure, show one inline alert and “Try again.” Booking controls remain unavailable because authoritative bounds and maximum are missing.
- Static page heading, restaurant introduction, ordinary navigation, and fixed contact presentation remain usable. Do not show hard-coded SRS/default dates, hours, capacity, or policy as though they are current booking authority.
- A successful retry replaces the failure and restores the normal first-control focus order; focus remains on the retry control unless the user activates a “Continue to form” shortcut.

## 5. Date-selection UX

- Use a labelled calendar-date control, never a combined free-text date/time field. Set its inclusive minimum and maximum from OP-01 without converting through the browser timezone.
- Dates before `minimum_local_date` and after `maximum_local_date` are unavailable. Prefer visibly disabled calendar dates where the eventual control supports them; never silently accept them. Hidden dates are less informative and are not preferred.
- The label includes “Reservation date”; helper text says dates follow the restaurant’s local timezone and states the returned inclusive range in readable form.
- Keyboard users must be able to reach, open, navigate, select, and leave the date control. Screen-reader text identifies the range and restaurant-local meaning.
- On smartphones, invoke an appropriate date-oriented input experience without creating a time keyboard or arbitrary time entry.
- A browser-native date control is acceptable only if Prompt 21 verifies usable constraint, label, error, and keyboard behavior in Chrome, Firefox, Safari, and Edge. Inconsistent disabled-date presentation is a Prompt-21 component/tooling concern, not permission to change the server rules.
- When date changes, immediately clear the selected slot, mark any availability response stale, remove it from submission eligibility, and keep customer fields. Any in-flight OP-02 result for the old key is ignored. The user explicitly requests availability for the new valid date.

## 6. Party-size UX

- Minimum is `1`; maximum is the current OP-01 `maximum_party_size`. Do not display or infer 30 tables, per-table capacity, table combinations, or a separate total-capacity rule.
- Recommend a labelled integer numeric control with mobile numeric input affordance and optional accessible increment/decrement controls. A very long select is not preferred because the public maximum may be large and configurable.
- Accept only a whole-number UI value inside the current 1-to-maximum range. Client messages are immediate usability feedback; OP-02 and OP-05 revalidate authoritatively.
- Helper text reports “Enter a whole number from 1 to [current maximum]” without explaining how the maximum was derived.
- Keyboard entry, increment/decrement, text scaling, and mobile virtual keyboard must remain usable. Preventing invalid keystrokes must not trap correction or reject valid contract input.
- When party size changes, clear the selected slot, invalidate current availability, ignore any old in-flight result, preserve customer fields, and require a new OP-02 request. Never assume a slot remains available for the new party.

## 7. Availability request UX

`AvailabilityArea` calls exactly `GET /api/v1/reservation-availability?local_date=<YYYY-MM-DD>&party_size=<base-10 integer>` with the two allowed query parameters and no body.

- Trigger with an explicit “Check availability” control once both inputs are client-valid and current OP-01 exists. After a date/party edit, label it “Update times” or equivalent. This reduces surprise and unnecessary requests while still making the required refetch explicit.
- On activation, clear any selected slot, mark the prior response noncurrent/noninteractive, show a loading state in the slot region, and announce the requested date/party.
- Suppress another request for the identical key while it is pending. No polling or periodic refresh exists.
- Give every request a monotonically increasing sequence and exact raw input snapshot. Only the latest sequence whose date/party still match current controls may update UI state. Cancellation may be used later as an optimization, but ignoring stale completion is mandatory.
- A date/party edit during flight invalidates the request immediately; its eventual success or error is ignored and must not move focus or overwrite a newer result.
- OP-02 read failures have no mutation uncertainty. Do not auto-loop retries. Show an explicit retry using the same current key when `retryable:true` or after a network read failure; the user may also change inputs.
- Never synthesize missing times, infer closed periods, filter by browser time, or calculate capacity locally.

## 8. Slot presentation and selection UX

### 8.1 Complete schedule

- Render `slots` exactly in the API-provided canonical order. Do not resort or omit entries.
- Present a labelled list/grid inside a `fieldset`/group. Each available slot is a radio-like single-choice control; each unavailable slot occupies the same visual sequence position and says “Unavailable” in text as well as styling.
- Available controls support Tab entry and standard single-selection keyboard behavior. The selected control has checked semantics, a visible non-color-only marker, and a summary beneath the group.
- Unavailable entries are nonselectable and carry disabled/unavailable semantics plus visible text; they remain perceivable to screen-reader and visual users even if disabled controls are skipped by tab order.
- Labels show the server-provided restaurant-local start. They may also show the server-provided `ends_at_local` as “start-end”; React never computes an end or duration. The group states “Restaurant local time” and may show the OP-02 timezone identifier.
- Preserve `starts_at_local` and `utc_offset_minutes` from the selected OP-02 item exactly for OP-05. Never create or convert them through the browser timezone.

### 8.2 Cardinality and refresh cases

| API result | UX |
|---|---|
| `slots: []` | “No reservation times are offered for this date and party size.” This is a valid empty schedule, not an error. Offer date/party change. |
| All slots `available:false` | Keep every slot visible and disabled; announce that all offered times are currently unavailable; offer date/party change and explicit refresh. |
| One available slot | Show it normally without auto-selection. |
| Many slots | Use a wrapping grid at roomy widths and one/two-column or list layout on narrow screens; source order and reading order remain identical. |
| Refresh retains selection and slot is still available | Do not auto-reselect after a deliberate refresh; the prior selection was provisional and must be deliberately confirmed again. |
| Refresh removes or disables selected slot | Clear selection, focus/announce the slot-region message, preserve other fields, and require a new choice. Never auto-select another time. |

Loading replaces the active slot controls with a labelled busy region or stable skeleton so stale times cannot be submitted. It must not hide the fact that a refresh is occurring.

## 9. Customer information form UX

Group fields under “Your details” with explicit persistent labels and visible “Required”/“Optional” text:

| UI field | Requirement and input guidance | Autofill / mobile guidance |
|---|---|---|
| First name | Required; 1-100 after approved trim/collapse; must contain a Unicode letter | `given-name` |
| Middle initial | Optional; one alphabetic character, optional period accepted | `additional-name`; short text input |
| Last name | Required; same approved name rules as first | `family-name` |
| Email | Required; approved ordinary address profile, maximum 254 | `email`, email keyboard |
| Confirm email | Required; normalized equality with Email | Do not intentionally autofill from primary; never block paste |
| Phone | Optional; approved punctuation, 7-15 digits, max 32 display characters | `tel`, telephone keyboard; no SMS promise |
| Party/date/time | Read-only review of current selected inputs/OP-02 slot, not editable duplicate fields | Edit links return focus to owning control |
| Newsletter | Checkbox plus synchronization status described in Section 11 | Never presented as authentication or ownership verification |

- Validate format when a touched field loses focus and on submission; do not show errors on untouched initial fields. Clear an error when the corrected value is revalidated.
- After invalid submit, show a concise error summary linked to fields, then focus the summary. Field messages remain programmatically associated and appear in API field order where returned.
- Client normalization mirrors only approved behavior for usability. It must not reject display punctuation/accents or other Flask-valid values.
- Preserve every useful field after 4xx/5xx known failure, stale capacity, status failure, and outcome uncertainty. Success alone clears the active form after the confirmation snapshot is safely rendered.

## 10. Email-confirmation UX

- Check both email fields independently for the approved syntax. Once both are nonempty, compare them after the approved trim-and-lowercase normalization. Recheck on either blur, every subsequent edit, status-lookup eligibility, and form submission.
- Mismatch copy: “Email addresses must match.” Associate it with Confirm email and include it in the submit error summary.
- `confirmation_email` is included in the exact OP-03, OP-04, and OP-05 JSON bodies. It is not merely client-side validation: Flask compares it transiently, then discards it before database access/persistence and never returns it.
- If primary Email changes after confirmation exists, retain the confirmation value so the user can see/correct the mismatch; do not silently copy or clear it. Immediately invalidate any newsletter lookup and prevent a new lookup/submission until equality is restored.
- Do not add delivery verification, domain ownership, double opt-in, or case-sensitive matching.

## 11. Newsletter synchronization inside reservation flow

### 11.1 Eligibility and states

OP-03 becomes eligible only when first name, optional middle initial if present, last name, Email, and Confirm email are all client-valid and the normalized emails match. Phone, party, date, and slot are not lookup inputs. Use a short debounce after identity editing plus blur/settled-input initiation; exact timing belongs to Prompt 21.

| Status | Checkbox and guidance | Reservation consequence |
|---|---|---|
| Not eligible | Initially unchecked but explicitly labelled “Status not checked”; untouched intent is `no_change` | Submit only when all other eligibility exists; no newsletter change |
| Checking | Keep checkbox operable but show that stored status is being checked; snapshot identity and current user-edit version | If untouched, submission uses `no_change` until a current result arrives; deliberate choice is retained but not silently committed while lookup is unresolved |
| `matched` | If checkbox is untouched, synchronize it to returned `subscribed`; announce current status. If user already edited, retain the user value and state that it will be requested with booking. | Untouched synchronized state may use `no_change`; deliberate checked/unchecked maps to `subscribe`/`unsubscribe` |
| `not_found` | If untouched, show unchecked and “No existing newsletter preference was found.” A deliberate prior choice remains unchanged. | Untouched uses `no_change`; deliberate state maps to subscribe/unsubscribe |
| Identity or middle conflict | Do not reveal stored facts. Keep user inputs; associate generic conflict with identity group/middle field as applicable. | Correct identity before booking; OP-05 would otherwise reject the same conflict |
| `newsletter_status_indeterminate` / network read failure | Show indeterminate status and retry. Preserve any deliberate checkbox display but clearly state it will not be applied unless lookup succeeds. | Booking may proceed only with `newsletter_action:"no_change"`; lookup success is not required |

### 11.2 Stale and deliberate-choice protection

- Track an identity request sequence, exact identity input snapshot, and a monotonic newsletter user-edit version.
- An OP-03 response may initialize the checkbox only if it is latest, its identity snapshot still matches, and the user-edit version has not changed since request start.
- Any deliberate checkbox interaction marks the control dirty. A late result may update the informational server-status baseline but must never overwrite the displayed user choice.
- Identity edits invalidate the server-status snapshot and launch a later eligible lookup. Preserve a deliberate user choice and explain that it applies to the currently entered identity; do not silently discard it.
- After an indeterminate result, preserve but do not apply a deliberate choice through booking until a successful current lookup establishes a reliable preference path. The user may retry lookup or continue booking with no change.
- OP-05’s successful `confirmation.newsletter_subscribed` replaces all local/server-baseline assumptions and is the displayed final state.

## 12. Standalone `NewsletterPreferences` UX

### 12.1 Placement and control choice

Recommend one dedicated, spacious section on Home, with a compact footer link to that section rather than duplicating the full identity form on every page. This resolves placement as a UX choice without adding a sixth page.

Use the approved explicit checkbox rather than a switch or two-button pair. A checkbox communicates an opt-in Boolean, works with ordinary forms, and maps directly to OP-04 `subscribed`. Label it “Subscribe me to the Café Fausse newsletter”; helper text makes clear that clearing it saves an unsubscribe preference. No topics, frequency, history, or delivery promise is offered.

### 12.2 Flow

1. Collect required first name, optional middle initial, required last name, Email, and Confirm email using Section 9/10 rules.
2. When identity becomes eligible, perform debounced OP-03 status lookup with the same stale/user-edit guards as Section 11.
3. If matched and untouched, synchronize the checkbox. If not found and untouched, leave it unchecked. A user edit always wins over a late lookup.
4. “Save newsletter preference” posts exactly those identity fields plus explicit Boolean `subscribed` to OP-04. OP-04 remains authoritative even if a prior lookup was skipped or stale.
5. While OP-04 is pending, lock the submitted snapshot and mutation control; suppress duplicate submission. On `200`, replace local state with returned `subscribed` and announce the authoritative final state.

`result:"no_customer_no_change", subscribed:false` means the requested final state is false and no new customer was created; present this as successful “You are not subscribed” state, not an error. Unsubscribe never claims customer deletion. A matching existing customer may subscribe/unsubscribe without changing profile or reservations.

If status lookup is indeterminate, the user may still make an explicit final choice and submit OP-04 because that mutation is authoritative. The Save action itself confirms the currently displayed checkbox state; the UI first warns that existing status could not be loaded. Identity/middle conflicts preserve input and reveal no stored value.

For `newsletter_preference_outcome_unknown`, keep the exact submitted identity and Boolean snapshot, state that the result is unknown, and offer only an explicit identical resubmission until resolved or deliberately abandoned. A repeat safely converges to the requested final Boolean. Do not automatically retry a mutation.

## 13. Reservation submission eligibility

Enable OP-05 submission only when:

- OP-01 context is successfully loaded;
- selected date and integer party size remain within the current client snapshot;
- an OP-02 response exists for exactly that date/party key;
- one currently returned slot with `available:true` is deliberately selected;
- required first/last names, Email, and Confirm email pass approved client validation;
- optional middle/phone are either omitted or client-valid;
- emails match after approved normalization;
- newsletter action is one of `subscribe`, `unsubscribe`, or `no_change`; indeterminate lookup forces `no_change`;
- no reservation mutation is pending; and
- no unresolved outcome-unknown recovery snapshot already owns the workflow.

The disabled submit control is accompanied by a live-updated checklist or concise helper naming the first incomplete area (for example, “Choose an available time”); it is not the only way validation is communicated. On attempted submit through keyboard/browser behavior, focus the error summary rather than silently doing nothing. Client eligibility is usability only; Flask/PostgreSQL revalidate every fact.

## 14. Reservation submission behavior

### 14.1 Exact request snapshot

OP-05 receives the approved customer fields, optional `phone`, selected OP-02 `starts_at_local` and `utc_offset_minutes`, selected `party_size`, and `newsletter_action`. React sends no date duplicate, end, duration, timezone, availability flag, capacity, table, customer/reservation ID, reference, fingerprint, or idempotency key.

On activation:

- re-run client validation and verify the selected slot still belongs to the current OP-02 key;
- capture one immutable submitted snapshot;
- disable the submit control and fields that could change that snapshot;
- show “Reserving your table…” and an accessible polite status;
- ignore double-click/Enter repeats while pending; and
- do not clear data or optimistically promise success.

### 14.2 Results

- `201 created` and `200 exact_retry` both transition to the distinct confirmation view. Exact retry is successful reconstruction, not a duplicate or warning.
- `422 validation_failed` preserves all data, maps safe field errors, focuses the summary, and invalidates/refetches availability when a returned time/date/party field shows that the selected server facts are no longer acceptable.
- Identity/middle conflict preserves data and focuses the affected identity region without exposing stored values.
- `reservation_overlap` preserves customer fields, clears the selected slot, and asks the user to choose a different time; no automatic alternative.
- `reservation_unavailable` clears selection, refreshes OP-02 for the same date/party once as an explicit recovery action, and returns focus to the availability message/slot region.
- Known `temporary_failure` or `service_unavailable` preserves the exact snapshot and offers explicit retry only where the public `retryable` flag permits. No automatic mutation retry occurs in React.
- A transport failure during OP-05 is treated conservatively as potentially unknown unless the client can prove the request was never dispatched. The UX uses the outcome-unknown recovery rather than asserting failure.

## 15. Public API error-to-UX mapping

React branches on operation, `code`, `retryable`, `outcome_unknown`, and field codes, never on mutable API message text.

| Operation(s) / HTTP / public code | Flags | Preserve / highlight / availability | Recovery and navigation |
|---|---|---|---|
| OP-02/03/04/05; 400 `invalid_json`, `request_body_required`, `invalid_request`; 415 `unsupported_media_type` | false / false | Preserve form; no user field assumption unless safe field details exist (they do not here) | Present generic form-service error; no identical retry button; treat as integration defect for later diagnostics |
| Any route; 404 `route_not_found`, 405 `method_not_allowed` | false / false | Preserve any local form | Generic unavailable experience; no customer correction or retry loop; route/method is implementation defect |
| OP-02/03/04/05; 422 `validation_failed` | false / false | Preserve; map `fields` to controls and summary. Date/party/start errors invalidate current availability/selection where applicable | User corrects fields; no blind identical retry |
| OP-03/04/05; 409 `customer_identity_conflict` | false / false | Preserve; highlight identity group generically, never stored value | Correct entered identity; keep slot unless OP-05 separately indicates availability loss |
| OP-03/04/05; 409 `middle_initial_conflict` | false / false | Preserve; highlight middle initial and identity summary | Correct or omit where valid; no stored-value hint |
| OP-05; 409 `reservation_overlap` | false / false | Preserve customer data; clear selection; existing reservation hidden | Choose another time; do not auto-move or offer cancellation |
| OP-05; 409 `reservation_unavailable` | false / false | Preserve details; clear selection; refresh OP-02 | Choose from refreshed availability; identical OP-05 retry is not offered |
| OP-03; 503 `newsletter_status_indeterminate` | true / false | Preserve identity and deliberate preference; no field highlight | Explicit status retry, or reservation continues with `no_change`; navigation not discouraged |
| OP-04/05; 503 `temporary_failure` | true / false | Preserve exact submitted snapshot; no field highlight; availability refresh not intrinsically required | Known no-commit/rollback: explicit identical retry; ordinary navigation warning only if abandoning entered data |
| OP-04; 503 `newsletter_preference_outcome_unknown` | true / true | Preserve and lock exact identity/Boolean snapshot | Distinct unknown alert; explicitly resend same preference; discourage navigation/edit until resolved; no automatic retry |
| OP-05; 503 `reservation_confirmation_unavailable` | true / false | Preserve and lock exact booking snapshot; do not refresh slot because reservation is known to exist | Say reservation exists but confirmation is unavailable; identical resubmit reconstructs; discourage different submission |
| OP-05; 503 `reservation_outcome_unknown` | true / true | Preserve and lock exact booking snapshot; no availability refresh before recovery | Distinct unknown alert; identical resubmit may create/exact-retry; discourage navigation/change; no lookup endpoint |
| OP-01/02/05; 503 `service_unavailable` | true / false | OP-01 blocks form; OP-02 preserves date/party; OP-05 preserves snapshot | Explicit retry later; never fabricate configuration or claim booking failure if transport certainty is absent |
| OP-07; 503 `service_not_ready` | true / false | Infrastructure only | Never customer-page content or customer navigation |
| Any; 500 `internal_error` | false / false | Preserve form; no field highlight | Generic known-outcome error; no technical detail or contract-unsupported identical-retry promise |
| OP-04/05 transport loss without a classified API body | conservatively unknown after possible dispatch | Preserve/lock exact mutation snapshot | Use operation-specific unknown recovery; never say “failed” merely because the network response was lost |

Unless a row explicitly says to discourage navigation, the UI does not trap or warn beyond the ordinary risk of abandoning unsaved form data. Navigation is specifically discouraged while an OP-04/OP-05 outcome-unknown snapshot is unresolved and while a known reservation awaits confirmation reconstruction; these states need the captured identical request for safe recovery. Slot availability refresh occurs only for the date/party/time cases identified above, and identity highlighting occurs only for safe caller-visible validation or conflict semantics.

The UI never exposes SQL, SQLSTATE, roles, table/capacity internals, pools/connections, stack traces, exceptions, fingerprints, or hidden identity values.

## 16. Ambiguous/outcome-unknown UX

Outcome uncertainty is a distinct blocking resolution panel, not ordinary red error styling.

- Heading: “We could not confirm the reservation result” (or newsletter equivalent), never “Reservation failed.”
- Explain briefly that the request may already have been saved and that resending the same details is the safe recovery.
- Preserve a private in-memory immutable snapshot of the exact submitted ordinary request. Show a human-readable summary but not confirmation email, canonical identifiers, or internal facts.
- Primary action is “Retry the same reservation” / “Resend the same preference.” It submits the captured body unchanged. Do not rebuild it from editable controls.
- Lock or hide ordinary mutation controls while this snapshot is unresolved. A secondary “Leave unresolved” action may return to navigation only after a warning that the result is still unknown; do not claim cancellation.
- Do not poll, automatically resubmit, invent a reservation lookup, accept a reference/fingerprint, refresh away the selected slot, or encourage repeated clicks.
- An OP-05 retry that returns `created` or `exact_retry` opens confirmation. Other authoritative responses are handled by their code without pretending the original result is known beyond what the response establishes.
- `reservation_confirmation_unavailable` uses a similar retry panel but explicitly says the reservation **is known to exist**; it is not outcome unknown.

## 17. Fully booked and availability-change UX

| Situation | Required distinction and recovery |
|---|---|
| One unavailable slot among others | Keep it visible/nonselectable with “Unavailable”; other available slots remain selectable |
| All legitimate slots unavailable | Keep full schedule visible; announce all offered times are unavailable; offer date/party change or explicit refresh |
| Selected slot unavailable on refresh | Clear it, announce removal, focus slot-region message, require deliberate new selection |
| Capacity lost during OP-05 | `reservation_unavailable`: preserve details, clear slot, refresh same-key OP-02, require new selection; no automatic retry/move |
| Temporary OP-02 failure | Keep date/party, show read retry; do not display stale slots as current and do not infer full status |
| Temporary known OP-05 failure | Keep exact snapshot; offer explicit identical retry only when `retryable:true`; do not conflate with capacity or unknown outcome |

## 18. Reservation confirmation UX

`ReservationConfirmationView` uses only OP-05 public output.

- Move focus to a page-level “Reservation confirmed” heading and announce success once.
- State whether the API returned `created` or `exact_retry` only in friendly terms; exact retry can say “Your existing reservation was recovered.”
- Present a definition-list/card with stored `customer_name`, `reservation_reference`, server-provided `starts_at_local`, `ends_at_local`, `party_size`, every `assigned_table_number`, authoritative `newsletter_subscribed`, restaurant address, and phone.
- Label times “Restaurant local time.” Do not convert through browser timezone or recompute the end. The offset-bearing server values remain the source.
- Assigned table numbers are public and required by PRA-024, so display all returned values; do not expose capacities, allocation candidates, or selection logic.
- Show `phone_notice` when returned, using its safe meaning; do not reveal either phone value.
- Do not display email/phone input, customer ID, canonical fingerprint, SQL/database facts, or claim email/SMS delivery.
- Primary action: “Return home.” Secondary: “Make another reservation,” which starts a fresh form without modifying the confirmed reservation. No cancel/change/reschedule control exists.
- Confirmation is transient no-store workflow data. Keep it in active application memory/history state only as later architecture permits; do not persist PII in local storage. A browser refresh/direct visit with no confirmation state must explain that reservations cannot be retrieved here and offer Home/new reservation, not invent a GET endpoint.

## 19. State ownership and invalidation model

### 19.1 Ownership

| Class | Minimal state |
|---|---|
| Server-authoritative | OP-01 context; current-key OP-02 response; OP-03 status baseline; OP-04 authoritative preference result; OP-05 confirmation/error semantics |
| User-entered/selected | Date; party size; selected slot ID/facts; first/middle/last; email; confirmation email; phone; deliberate newsletter checkbox/intention |
| Transient UI | Loading/pending flags; touched/errors; request sequence and snapshots; newsletter user-edit version; current alerts; availability staleness; immutable mutation recovery snapshot; confirmation presentation state |

Do not duplicate context limits, slot availability, or confirmation facts into independently editable state. A selected slot references one item in the current OP-02 response and preserves only the exact submission facts it supplies.

### 19.2 Invalidation rules

| Event | Clear/invalidate | Preserve |
|---|---|---|
| Date changes | OP-02 response, selected slot, availability errors/request key, submit eligibility | Party and customer fields |
| Party changes | Same as date change | Date and customer fields |
| Selected slot becomes unavailable | Selected slot and eligibility | Date/party, full refreshed schedule, customer fields |
| Name/email/confirmation identity changes | OP-03 baseline/result and pending request authority; start new sequence when eligible | Reservation selection and deliberate newsletter choice; mark choice as applying to current entered identity |
| Late OP-03 completion | Ignore if sequence/snapshot stale; never overwrite dirty checkbox | Current identity/choice |
| Ordinary OP-05 failure | Only state required by code (for example slot on unavailable) | Useful form data and submitted facts |
| OP-05 outcome unknown | Freeze exact submitted body as recovery owner | All human-readable form data; no ordinary edits until resolve/abandon warning |
| OP-05 success | End pending/unknown state; create confirmation from response | Confirmation facts only; active form may reset after transition |
| OP-04 success | Replace displayed preference baseline/value with returned Boolean; clear dirty/pending | Identity fields may remain for acknowledgement |

## 20. Async and staleness model

No data-fetching/state library is selected.

| Operation | Trigger / duplicate suppression | Stale condition / edit invalidation | Retry and pending controls |
|---|---|---|---|
| OP-01 | Reservation-page entry; one current request; suppress concurrent duplicate | Page lifecycle superseded or later OP-01 sequence exists | Explicit read retry; booking controls disabled while missing/pending |
| OP-02 | Explicit Check/Update availability with valid date/party | Sequence or exact date/party snapshot no longer current | Explicit read retry; slot controls busy/noninteractive; no polling |
| OP-03 | Debounced eligible identity snapshot | Sequence, any identity field, or user-edit version changed | Explicit retry on indeterminate; checkbox choice protected; reservation may use `no_change` |
| OP-04 | Explicit Save preference with immutable identity/Boolean body | Mutation results are never discarded merely because local edits would differ; edits are locked pending | Suppress duplicate; no auto retry; identical explicit retry for retryable/unknown result |
| OP-05 | Explicit Reserve with immutable validated body | Mutation results are never treated as stale; fields are locked pending | Suppress duplicate; no auto retry; exact captured-body recovery where contract says retryable |

Read cancellation is optional optimization; sequence/snapshot checking is the correctness rule. Mutation cancellation in the browser does not prove server cancellation and never changes outcome semantics.

## 21. Responsive and mobile UX

- Keep the same logical order on smartphone, tablet, and desktop: context -> date/party -> slots -> details/newsletter -> review/submit -> feedback.
- Smartphone: stack date and party controls; use full-width Check availability; show slots in a one/two-column touch-friendly grid; stack all identity fields; keep error text adjacent; place submit after review rather than as a floating control obscured by the keyboard.
- Tablet: date/party may share a row; slots may use additional columns; identity fields may pair only where labels/errors retain reading order.
- Desktop: constrain line length; date/party and related summary may share space; slot grid and form remain in DOM/source order rather than visual reordering.
- Email and confirmation may be side-by-side only when both labels, full values, and error messages fit; otherwise stack. Phone stays with identity/contact fields; newsletter checkbox follows identity so its lookup dependency is clear.
- Alerts appear before the affected region and a summary may remain near submit. Outcome-unknown/confirmation uses a single-column readable card across sizes.
- Controls need comfortable touch targets and spacing; exact metrics and breakpoints belong to Prompt 21. Virtual keyboard appearance must not hide the active field/error or cause horizontal scrolling.

## 22. Accessibility UX

- One form with semantic `fieldset`/`legend` groups for reservation choices, time selection, identity, and newsletter preference. Review is a semantic summary, not duplicated editable controls.
- Every field has an explicit label; Required/Optional is conveyed in text and programmatically, not by an asterisk alone. Instructions precede the related control or are connected with descriptions.
- Inline errors are associated with their fields. Invalid submit creates a linked summary, focuses it, then lets users activate links to fields. Do not move focus for validation that occurs during ordinary typing.
- Loading/busy regions announce context, availability, newsletter lookup, and mutation changes once with appropriate polite status. Errors and unknown outcomes use alert semantics; avoid repeated announcements.
- Slot group has a clear label, restaurant-local-time instruction, checked semantics, disabled/unavailable semantics, and color-independent text/shape. Full schedules remain readable by keyboard and assistive technology.
- Availability refresh announces result count/state and any removed selection. Focus moves only when action is needed, such as a selected slot disappearing.
- Newsletter status text is associated with the checkbox. A dirty user choice is announced as retained when a status result arrives; lookup failure explains the `no_change` booking path.
- Disabled submit has adjacent explanation; users are not expected to infer incompleteness from disabled styling alone.
- Pending mutation locks are conveyed with `aria-busy`/status semantics. Confirmation focuses its heading; outcome unknown focuses its alert heading and provides one unambiguous recovery action.
- Keyboard-only users can complete every control and retry path. State never depends on hover, gesture, or color alone.
- This is an interaction design, not a claim of WCAG certification or verified conformance level.

## 23. Proposed UX copy inventory

Unless marked as a contract fact, every entry below is **PROPOSED UX COPY - PRESENTATIONAL**. Implementation may refine wording without changing code/flag semantics.

| Situation | Proposed wording | Contract meaning preserved |
|---|---|---|
| Context loading | “Loading reservation options…” | OP-01 pending |
| Context load failure | “Reservation options are unavailable right now. Try again.” | Known OP-01 read/service failure; no fallback authority |
| Availability loading | “Checking times for [date] and [party]…” | OP-02 pending/provisional |
| Availability failure | “We couldn’t load times right now. Try again.” | Read can safely repeat; not “fully booked” |
| Empty schedule | “No reservation times are offered for this date and party size.” | Valid `slots:[]` |
| Fully unavailable day | “All offered times are currently unavailable. Choose another date or party size, or refresh.” | All returned slots retained/false |
| Slot unavailable | “Unavailable” | Nonselectable API false state |
| Selected slot lost | “Your selected time is no longer available. Please choose another.” | Clear selection; no auto replacement |
| Validation summary | “Please review the fields below.” | `validation_failed`; follow field codes |
| Email mismatch | “Email addresses must match.” | Approved normalized equality |
| Identity conflict | “The entered identity details don’t match our records. Review your name and email.” | Generic conflict; stored facts withheld |
| Newsletter checking | “Checking your current newsletter preference…” | OP-03 pending |
| Newsletter indeterminate | “We couldn’t check your newsletter status. Retry, or continue your reservation without changing it.” | OP-03 retryable; booking `no_change` |
| Reservation pending | “Reserving your table…” | OP-05 pending; no success promise |
| Reservation success | “Your reservation is confirmed.” | OP-05 created/exact retry success |
| Exact retry | “Your existing reservation was recovered.” | `booking_result:exact_retry` |
| Reservation unavailable at submit | “That time is no longer available. Review the refreshed times and choose another.” | 409; refresh, no identical retry |
| Reservation known temporary failure | “We couldn’t process the reservation right now. Your details are preserved.” | Known outcome; follow `retryable` |
| Reservation outcome unknown | “We could not confirm the reservation result. Retry the same details to recover safely.” | Unknown may have committed; no failure claim |
| Confirmation unavailable | “Your reservation exists, but we couldn’t prepare the complete confirmation. Retry the same details to recover it.” | Known reservation; confirmation read failed |
| Newsletter save success true | “Your newsletter preference is saved: subscribed.” | OP-04 returned true |
| Newsletter save success false | “Your newsletter preference is saved: not subscribed.” | OP-04 returned false; no deletion claim |
| Newsletter save failure | “We couldn’t save your newsletter preference right now. Your choice is preserved.” | Known OP-04 failure |
| Newsletter outcome unknown | “We could not confirm the newsletter update. Resend the same preference to resolve it.” | OP-04 outcome unknown |

API-provided safe messages may be displayed as supporting detail, but behavior never branches on their text and friendlier wording never changes `retryable` or `outcome_unknown` meaning.

## 24. Requirements, API, and REACT-01 traceability

| Requirement / authority | UX component or interaction | Server authority | Client usability responsibility | Deferred work |
|---|---|---|---|---|
| SRS FR-06 | Progressive form; slot, party, structured name, email/confirmation, optional phone | Flask validates exact request | Labels, grouping, immediate feedback, preservation | Prompt 21 tests/visuals; Prompt 23 implementation |
| SRS FR-07 | OP-01/02 discovery and OP-05 final submit | Validity/availability always Flask/PostgreSQL | Show only API slots; selection/current-key guards | Prompts 23-24 implementation/integration |
| SRS FR-08 / FR-18 | Submission and confirmation | PostgreSQL allocates from approved inventory | No table choice/promise; show public assigned numbers after success | Integration proof later |
| SRS FR-09 | Confirmation, unavailable, error, unknown states | OP-05 result/code/flags | Distinct accessible success/recovery; preserve data | Prompt 23 implementation |
| SRS FR-15/16 | Reservation checkbox and Home `NewsletterPreferences` | OP-03 status; OP-04/05 persistence | Validate, synchronize, protect deliberate choice, show authoritative result | Prompts 23-24 |
| SRS FR-17/18 | Customer/reservation effects | Frozen backend/database | Never expose or reproduce persistence/allocation | Integration/demo later |
| NFR-02 | Pending/progress without false timeout claims | API timing and final full-stack measurement | Suppress duplicate mutation; responsive feedback | UI-09/INT-07 measurement |
| NFR-03/04 | One progressive form, concise states/copy | N/A | Intuitive sequence and consistent feedback | Prompt 21 visual system |
| NFR-05 | Provisional wording and final revalidation | PostgreSQL integrity/transactions | Never make availability authoritative | Integration concurrency proof |
| NFR-06 | Error map, unknown recovery, data preservation | Safe public errors/flags | Accessible, nontechnical recovery | Prompt 23 tests/implementation |
| NFR-07/08 | Native-semantic controls and responsive ordering | N/A | Keyboard/mobile/browser-ready design | Prompt 21 exact matrix/breakpoints |
| NFR-09 | Existing feature boundaries and minimal state model | N/A | Modular responsibilities, no redundant authority | Prompt 21 test/architecture detail |
| Rubric working forms/UI/UX | Complete reservation/newsletter flows | Frozen Flask operations | Clear forms, feedback, responsive/accessibility behavior | UI-03 onward; no compliance claimed now |
| PRA-006-013, 015-018, 029 | Date/party/slot display | OP-01/02/05 current rules, time, capacity, allocation | Consume returned bounds/slots; no calculations/table selection | UI/API integration later |
| PRA-014 | Pending lock, distinct confirmation, preserved failures | Exact retry and overlap authority | Double-submit prevention and correct transition | Prompt 23 |
| PRA-019-021 | Structured identity and preference sync | OP-03/04/05 identity/current Boolean | Debounce, dirty guard, final authoritative sync | Prompt 23 |
| PRA-022 | No cancellation/change | No endpoint exists | No controls or claims | Preserved exclusion |
| PRA-023 | Immediate accessible validation | Flask revalidates | Contract-compatible client feedback/stale guards | Prompt 23 |
| PRA-024 | Confirmation/error/ambiguity | OP-05 public facts and safe codes | Complete confirmation, friendly recovery, no delivery claim | Prompt 23/24 |
| PRA-025 | Availability-first full schedule | OP-02 full ordered schedule; OP-05 final authority | All slots visible, unavailable disabled, invalidation/refetch | Prompt 23/24 |
| OP-01 / `ReservationContextBoundary` | Initial context and booking enablement | All returned context facts | Skeleton, retry, no fake fallback | Prompt 23 mock implementation |
| OP-02 / `AvailabilityArea` | Explicit request and slot group | Ordered provisional response | Current-key/stale guard and selection | Prompt 23 |
| OP-03 / customer/newsletter boundary | Debounced status synchronization | Minimal status/conflict/indeterminate | Never overwrite user edit | Prompt 23 |
| OP-04 / `NewsletterPreferences` | Explicit final Boolean save | Authoritative returned state | Lock, retry, unknown resolution | Prompt 23 |
| OP-05 / review/feedback/confirmation | Booking/reconstruction | Final transaction and confirmation facts | Snapshot, map errors, safe identical recovery | Prompt 23 |
| Approved REACT-01 | All named boundaries retained | API ownership map frozen | Adds detailed interaction/state responsibilities only | Prompt 21 visual/test design; Prompt 22+ code |

This is design traceability only; no implementation compliance is claimed.

## 25. Decisions deferred to Prompt 21

- React/build framework, router, network and state/data libraries;
- CSS architecture, palette, typography, spacing, exact component appearance;
- exact breakpoint values and browser/device matrix;
- final native-versus-custom date-control implementation after compatibility review;
- exact debounce durations, skeleton styling, motion, and touch-target metrics;
- unit/component/E2E tools, detailed test IDs, package versions, and build scripts.

Prompt 21 must support the UX invariants here: current-key request handling, dirty-choice protection, mutation snapshot recovery, accessible slot/alert/focus behavior, and responsive source order. It may not change the frozen API or invent business rules.

## 26. Unresolved ambiguities and preserved gaps

No business-rule ambiguity or authoritative conflict blocks review.

- API-02 OP-01 exposes authoritative date bounds and timezone but no current-clock field. This design uses only the returned date bounds and does not fabricate a clock.
- Browser-native date-control consistency is a Prompt-21 compatibility decision; it does not change allowed dates.
- Exact presentational wording remains proposed and may change without changing public code/flag semantics.
- The approved REACT-01 content gaps remain untouched: behind-the-scenes imagery, detailed founder biography content, and asset provenance/licensing. They are outside REACT-02 form UX scope and remain tracked.

## 27. Approval status

**APPROVED AND FROZEN.**

REACT-02 / UI-02 passed independent review on 2026-08-24. The reservation and newsletter UX design documented here is approved and frozen.

The approved UX boundary explicitly preserves these rules:

- Flask/PostgreSQL remain authoritative for reservation validity, availability, allocation, persistence, retry semantics, and newsletter/customer state;
- arbitrary reservation-time entry remains prohibited;
- all legitimate OP-02 slots remain visible, and unavailable slots remain nonselectable;
- stale newsletter-status results must never overwrite a deliberate user choice; and
- outcome-unknown handling and identical-request recovery are approved as documented.

Prompt 21 - complete UI/UX and React test strategy - is now authorized. This approval does not authorize React implementation, live integration, or changes to the frozen backend, API, database, or REACT-01 design.
