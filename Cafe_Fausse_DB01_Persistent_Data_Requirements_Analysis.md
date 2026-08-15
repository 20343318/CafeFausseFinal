# Cafe Fausse DB-01 Persistent-Data Requirements Analysis

**Document version:** 1.0  
**Established:** 2026-08-14  
**Roadmap increment:** DB-01  
**Authoritative sources:** `SRS(1).pdf`, `Rubric(1).pdf`, Project Requirements Addendum 2.1 (PRA-001 through PRA-028), and the approved least-to-most implementation roadmap  
**Scope:** PostgreSQL persistent-data requirements only  
**Status:** Ready for DB-01 approval checkpoint  
**Code status:** No SQL or application code generated

## 1. Purpose and boundary

This analysis identifies the business facts PostgreSQL must preserve, the business configuration it must control, the values that are derived or transient, and the data explicitly excluded from Version 1. It does not finalize a conceptual model, physical entities, tables beyond the SRS minimum names, columns, data types, keys, constraints, indexes, migrations, transaction/locking mechanisms, Flask endpoints, or React components.

Candidate domain records and relationships are named only to organize requirements. Prompt 5 will decide the conceptual model; later prompts will decide logical and physical representation.

## 2. Classification and notation

| Code | Classification | Meaning |
|---|---|---|
| PBD | Persistent business data | Durable business fact that must survive process restarts and remain queryable until controlled reset. |
| PBC | PostgreSQL business configuration | Durable current operating rule controlled from PostgreSQL and applied prospectively. |
| DRV | Derived value | Calculated from authoritative persistent/configured/fixed inputs; not an independent source of truth. |
| TRN | Transient input/state | Needed only during validation, request processing, or UI interaction; not retained as business data. |
| FIX | Fixed Version 1 reference rule | Authoritative behavior/content fixed by SRS or addendum; no PostgreSQL configuration is required. |
| TID | Deferred technical implementation data | May be useful for implementation, performance, or operations, but its exact representation is deferred and is not a new business fact. |
| FE | Inactive future-enhancement data | Explicitly excluded from Version 1. |

Requirement references use SRS `FR-*` and `NFR-*`, rubric `RUB-*` from the baseline, and addendum `PRA-*` identifiers.

## 3. Source-of-truth assignments

| Domain | Version 1 source of truth | Important exclusion |
|---|---|---|
| Customer identity and contact | One persistent customer record identified by normalized email | No separate account/profile system and no duplicate customer per email |
| Current newsletter preference | Current Boolean value on the customer record | No subscriber list/table as a second source and no preference history |
| Reservation | One confirmed immutable reservation business record | No cancellation, modification, rescheduling, status lifecycle, or no-show record |
| Reservation occupancy | Immutable booked start plus immutable booked end/duration fact | Current duration configuration must not recalculate an existing reservation |
| Assigned tables | Persistent association of one reservation with one or more restaurant tables | No table sharing, partial assignment, customer-selected tables, or adjacency model |
| Restaurant table inventory | Exactly 30 Version 1 persistent table records with individual capacities | No additional active Version 1 tables |
| Reservation configuration | Current PostgreSQL business configuration values | No configuration history or effective-dated versions |
| Availability | Derived from current request, fixed/configured rules, retained reservations, and assigned tables | No independent availability ledger or stored slot-status record |
| Reservation retry identity | Database-generated, stored, versioned opaque fingerprint plus verification of its underlying reservation facts | No client-generated key and no newsletter/optional-customer data in the fingerprint |

## 4. Complete persistent-data inventory

### 4.1 Customer and newsletter data

| ID / data item | Business meaning and authoritative source | Required/default/approved validation | Classification and source of truth | Lifecycle, identity, and relationships | PostgreSQL responsibility and future consumers |
|---|---|---|---|---|---|
| CUS-01 Customer identifier | Stable identity required by SRS Customers and Reservations minimum fields. Sources: FR-17, FR-18; PRA-019. | Required for every persisted customer; generated representation deferred. | PBD; customer record. | Unique and immutable; one customer may have zero or many reservations. Retained until controlled reset under PRA-028. | PostgreSQL generates/preserves it and uses it for reservation and retry relationships. Flask needs it internally; React does not need database identity unless an approved contract later exposes a safe reference. |
| CUS-02 First name | Required component of SRS Customer Name. Sources: FR-06, FR-17; PRA-019, PRA-023. | Required; trimmed/collapsed; 1-100 characters; at least one letter; display punctuation/accents preserved; case-insensitive matching. | PBD; customer record. | Participates in existing-customer match with normalized email and last name. Not silently overwritten. Retained until reset. | PostgreSQL preserves authoritative display value and supports matching/integrity. Flask validates/matches; React collects/displays. |
| CUS-03 Middle initial | Optional structured component of SRS Customer Name. Sources: PRA-019, PRA-023. | Optional; one alphabetic character with optional input period; stored uppercase without period. Existing empty may be populated; omission preserves; conflicting populated value rejected. | PBD when supplied; customer record. | Not customer identity and excluded from reservation fingerprint. Retained once populated until reset; no general profile-update feature. | PostgreSQL preserves authoritative value and supports approved conflict behavior. Flask validates; React collects optionally. |
| CUS-04 Last name | Required component of SRS Customer Name. Sources: FR-06, FR-17; PRA-019, PRA-023. | Required; same 1-100, trimming, letter, display, and case-insensitive matching rules as first name. | PBD; customer record. | Participates in match with normalized email and first name. Not silently overwritten. Retained until reset. | PostgreSQL preserves value and supports matching/integrity. Flask validates/matches; React collects/displays. |
| CUS-05 Canonical email | Required customer identity and marketing address. Sources: FR-06, FR-15 to FR-18; PRA-019 to PRA-021, PRA-023. | Required for every persisted customer; trimmed; syntactically valid; maximum 254 characters; canonical lowercase; one customer per normalized email. | PBD; customer record; primary business identity key. | Unique across customers; immutable through Version 1 workflows; retained even after unsubscribe. One customer may have many reservations. | PostgreSQL enforces authoritative uniqueness/canonical value. Flask validates/matches; React collects twice but receives safe outcomes only. |
| CUS-06 Confirmation email input | Second entry used to reduce typing errors. Sources: PRA-019, PRA-023. | Required on reservation and dedicated newsletter forms; normalized entries must match. | TRN; no persistent source. | Exists only during client/backend validation; never retained as duplicate customer data, confirmation data, or log content. | PostgreSQL has no business-storage responsibility. Flask revalidates; React collects and compares for usability. |
| CUS-07 Phone number | Optional reservation contact information required by the SRS minimum Customers fields. Sources: FR-06, FR-17; PRA-019, PRA-023. | Optional; allowed characters digits/spaces/plus/parentheses/hyphens/periods; 7-15 digits. New or existing blank may be populated; omission preserves; differing existing value is not silently overwritten. | PBD when supplied; customer record. | Not identity and excluded from fingerprint. Retained until reset. No dedicated profile-update workflow. | PostgreSQL preserves the approved contact value and supports integrity/comparison. Flask validates and applies update rules; React collects optionally. |
| CUS-08 Normalized phone comparison value | Canonical digit form used to compare phone inputs. Source: PRA-023. | Derived from CUS-07 when present; exact stored-versus-computed representation deferred. | DRV or TID; never an independent business value. | Follows the phone value; not unique and not identity. | PostgreSQL may derive/support efficient comparison later. Flask needs comparison semantics; React need not receive it. |
| CUS-09 Current newsletter status | Current subscribe/unsubscribe preference required by SRS Newsletter Signup. Sources: FR-15 to FR-17; PRA-019 to PRA-021. | Required Boolean for a persisted customer. New selected creates customer with true; new unselected creates no record. Existing state may be set true/false; repeated sets succeed. | PBD; customer record is the only source of truth. | Mutable independently; last committed valid write wins. Unsubscribe sets false but retains customer. Reservation-linked change is atomic only for a new successful booking; exact reservation retry never reapplies newsletter action. | PostgreSQL stores/returns authoritative current state and preserves concurrency semantics. Flask exposes lookup/set behavior; React synchronizes checkbox/display. |
| CUS-10 Submitted newsletter action | User intent `subscribe`, `unsubscribe`, or no change during a request. Sources: PRA-019 to PRA-021, PRA-027. | Explicit request state; not part of reservation fingerprint. | TRN; outcome becomes CUS-09, not a history record. | Applied idempotently. On a newly committed reservation, applied atomically; on exact reservation retry, ignored for mutation and current CUS-09 is returned. | PostgreSQL processes it transactionally but does not retain it as an event. Flask conveys intent; React or future clients submit it. |
| CUS-11 Customer created/updated timestamps | Potential technical metadata for diagnostics/maintenance. No authoritative business requirement mandates it. | Optional technical design decision; defaults/constraints not approved. | TID. | If adopted later, must not become subscription-history or profile-audit functionality. | Prompt 6 may decide whether technical timestamps are justified. Flask/React have no current business need for them. |

### 4.2 PostgreSQL reservation configuration and fixed schedule

| ID / data item | Business meaning and authoritative source | Required/default/approved validation | Classification and source of truth | Lifecycle, identity, and relationships | PostgreSQL responsibility and future consumers |
|---|---|---|---|---|---|
| CFG-01 Start-time interval | Alignment spacing for legitimate reservation starts. Source: PRA-006. | Required current value; default 30 minutes; allowed 15, 30, 60. | PBC. | Mutable prospectively; existing reservations unchanged under PRA-026. No history required. | PostgreSQL stores/validates current setting. Flask generates/revalidates slots; React displays only API-supplied slots. |
| CFG-02 Reservation duration | Complete table-occupancy duration for new reservations. Sources: PRA-007, PRA-009, PRA-013, PRA-026. | Required current value; default 90 minutes; allowed 60, 90, 120; no separate turnover buffer. | PBC for new bookings plus an immutable booked occupancy fact per confirmed reservation. | Mutable prospectively. A change never recalculates existing reservations. No configuration history required. | PostgreSQL stores current setting and preserves each booked occupancy interval. Flask calculates new slot/end validity; React displays authoritative start/end. |
| CFG-03 Maximum advance-booking window | Inclusive future calendar-date limit. Source: PRA-010. | Required current value; default 60 days; allowed 1-365. | PBC. | Mutable prospectively; affects new availability/booking requests only. | PostgreSQL stores/validates it. Flask calculates date bounds in restaurant time; React uses returned bounds/validation. |
| CFG-04 Same-day minimum lead time | Minimum time between authoritative current time and same-day start. Source: PRA-011. | Required current value; default 120 minutes; allowed 0-1440. | PBC. | Mutable prospectively; existing bookings unchanged. | PostgreSQL stores/validates it. Flask applies authoritative clock; React displays resulting availability. |
| CFG-05 Restaurant timezone | IANA zone governing reservation rules and display. Source: PRA-012. | Required current value; default `America/New_York`; valid IANA identifier. | PBC. | Relatively fixed; changes apply prospectively and must not reinterpret stored reservation instants. No history required. | PostgreSQL stores current zone and supports unambiguous reservation facts. Flask calculates/displays restaurant-local values; React renders those values regardless of browser zone. |
| FIX-01 Weekly operating hours | Monday-Saturday 5:00 PM-11:00 PM; Sunday 5:00 PM-9:00 PM. Sources: FR-02; PRA-008, PRA-009. | Required exactly as SRS. | FIX; not PostgreSQL business configuration in Version 1. | Stable Version 1 rule. No holiday/exception records. | PostgreSQL need not store it as business data. Flask applies the fixed schedule; React displays hours and returned slots. |
| CFG-06 Configuration history/effective dates | Historical versions of settings. Sources: FE-016. | Not approved for Version 1. | FE. | No records or reservation-to-version relationship. | Excluded. Current configuration plus immutable booked facts are sufficient. |

### 4.3 Restaurant table inventory and capacity

| ID / data item | Business meaning and authoritative source | Required/default/approved validation | Classification and source of truth | Lifecycle, identity, and relationships | PostgreSQL responsibility and future consumers |
|---|---|---|---|---|---|
| TBL-01 Table identifier/number | Stable identity of each physical bookable table and the SRS Table Number for single-table bookings. Sources: FR-08, FR-17, FR-18; PRA-016, PRA-018. | Required and unique for each Version 1 table; exact representation deferred. | PBD; restaurant-table inventory. | Exactly 30 table records in Version 1. A table may be assigned to many reservations over nonoverlapping intervals. Retained/recreated until controlled reset. | PostgreSQL preserves table identity and assignment relationships. Flask allocates; React receives assigned numbers only after success. |
| TBL-02 Seating capacity | Maximum seats at one table. Sources: PRA-015 to PRA-018. | Required positive seating count; initial value 4 for every table. Exact upper technical bound deferred. | PBD with business-configurable value per table. | Relatively fixed. Prospective changes affect new calculations only; existing reservations/assignments remain unchanged. | PostgreSQL stores each capacity. Flask derives party bounds and eligible combinations; React receives dynamic maximum/availability, not editable capacities. |
| TBL-03 Version 1 table count | Number of current bookable tables. Sources: FR-08, FR-17, FR-18; PRA-016. | Exactly 30. | FIX/DRV: mandated count verified from current inventory, not a separate independently editable setting. | Remains 30 in normal Version 1 operation. More than 30 is FE-013. Controlled reset re-creates the 30. | PostgreSQL initialization/verification must produce exactly 30. Flask uses inventory; React need not receive the literal count except through confirmation/approved display. |
| TBL-04 Total restaurant capacity | Sum of current capacities of all 30 Version 1 tables. Sources: PRA-015, PRA-017. | Initial value 120; changes when TBL-02 changes. | DRV from table inventory. | Recalculated for new validation; not historical and not independent. | PostgreSQL must support authoritative derivation. Flask returns party-size bound; React displays/validates provisionally. |
| TBL-05 Maximum party size | Largest theoretically valid party size. Sources: PRA-015, PRA-023. | Minimum party 1; maximum equals TBL-04; initially 120. | DRV; same authoritative value as total configured capacity, not separate configuration. | Recalculated prospectively. Does not guarantee a specific slot. | PostgreSQL supports derivation; Flask validates/returns it; React presents the bound. |
| TBL-06 Table bookable/active flag | Possible mechanism for future expansion or disabling tables. No Version 1 approval requires it. | Not required; exactly 30 present tables are bookable. | TID/FE depending purpose. | Adding inactive/active management would introduce unapproved lifecycle behavior. | Do not require it in DB-01. Prompt 5/6 must not use it to activate more than 30 without approval. |
| TBL-07 Physical adjacency/combinability | Whether tables can physically be combined. Source: FE-012. | Not defined or required. | FE. | No records/relationships. | Excluded; any capacity-eligible exclusive combination may be considered. |

### 4.4 Reservation and exclusive assignment data

| ID / data item | Business meaning and authoritative source | Required/default/approved validation | Classification and source of truth | Lifecycle, identity, and relationships | PostgreSQL responsibility and future consumers |
|---|---|---|---|---|---|
| RSV-01 Reservation identifier | Stable identity required by SRS and usable as the stable confirmation reference. Sources: FR-17; PRA-024. | Required and unique; generated representation and public exposure decision deferred. | PBD; reservation record. | Immutable; retained until controlled reset. One reservation belongs to one customer and has one or more assigned tables. | PostgreSQL generates/preserves it. Flask returns a safe confirmation reference; React displays it. Whether a separate public token is technically justified is deferred. |
| RSV-02 Customer relationship | Identifies the customer holding the reservation. Sources: FR-17, FR-18; PRA-014, PRA-019. | Required; exactly one customer per reservation. | PBD relationship. | Reservation cannot exist without its customer. One customer may have zero or many reservations. | PostgreSQL maintains referential integrity and overlap checks. Flask resolves customer; React supplies identity inputs, not the relationship key. |
| RSV-03 Canonical start instant | Beginning of the booked occupancy interval. Sources: FR-06, FR-17; PRA-006, PRA-008 to PRA-014. | Required; unambiguous timezone-aware fact; aligned to interval; valid date/hours/window/lead. Exact PostgreSQL type deferred. | PBD; reservation record. | Immutable after confirmation. Retained until reset. Combined with customer and party size for fingerprint. | PostgreSQL preserves/comparisons use the canonical instant. Flask validates/converts/displays New York time; React submits an API-defined value. |
| RSV-04 Immutable booked end/duration fact | End boundary of the confirmed half-open interval, or an equivalent immutable snapshot of booked duration sufficient to reproduce it. Sources: PRA-007, PRA-009, PRA-013, PRA-026. | Required persistent fact for each reservation; default-created bookings use current 90-minute configuration. Exact choice between stored end and stored duration snapshot is deferred. | PBD fact; displayed end may be DRV from start plus snapshot. | Immutable. Later duration changes cannot alter it. Reservation interval is `[start,end)`. | PostgreSQL must reproduce/enforce the original interval permanently. Flask returns authoritative end; React displays it. |
| RSV-05 Party size | Number of guests requiring capacity. Sources: FR-06; PRA-015, PRA-023, PRA-027. | Required integer; 1 through derived maximum at booking; actual assignment must have sufficient free capacity. | PBD; reservation record. | Immutable in Version 1. Included in fingerprint. Retained until reset. | PostgreSQL preserves/validates it and allocation capacity. Flask submits/returns it; React collects/displays. |
| RSV-06 Fingerprint algorithm version | Version label for deterministic reservation fingerprint semantics. Source: PRA-027. | Required for a persisted fingerprint; initial algorithm version `v1` as a semantic label, exact representation deferred. | PBD/TID supporting business retry identity. | Immutable per reservation; no Version 1 regeneration on optional customer changes. | PostgreSQL associates version with fingerprint verification. Flask/React need not interpret it. |
| RSV-07 Opaque reservation fingerprint | Deterministic retry lookup derived from customer ID, canonical start, and party size. Sources: PRA-014, PRA-027. | Required for successful reservation; database-generated; opaque; newsletter/name/email/phone/tables/end/config excluded. Equality must be verified against underlying facts. | PBD technical reservation identity; PostgreSQL source. | Immutable; retained with reservation until reset. Equivalent request returns existing reservation. Different party size produces different identity and same-customer overlap rejection. | PostgreSQL generates/stores/verifies it. Flask returns consistent retry result to any client. React/mobile/third parties never generate it; successful response may include it. |
| RSV-08 Reservation-created timestamp | Possible technical fact for diagnostics or ordering. Not required by SRS/addendum for business behavior. | Optional technical decision; exact need/default deferred. | TID. | If adopted, immutable and retained with reservation, but not a status/history system. | Prompt 6 may decide based on maintainability/diagnostics. No current React business need. |
| RSV-09 Reservation status | Cancellation/no-show/modification lifecycle state. Sources: PRA-022; FE-005 to FE-008. | No status is required solely for Version 1; every confirmed reservation is treated as active for its own interval. | FE/TID excluded as an active business requirement. | No customer lifecycle transitions. Past intervals cease blocking through time comparison. | Do not require a status field or state machine in DB-01. |
| RSV-10 Cancellation/modification data | Reason, token, cancellation time, rescheduled link, released assignments. Sources: PRA-022; FE-005, FE-006. | Not approved. | FE. | No records or relationships. | Excluded. |

### 4.5 Reservation-to-table assignment data

| ID / data item | Business meaning and authoritative source | Required/default/approved validation | Classification and source of truth | Lifecycle, identity, and relationships | PostgreSQL responsibility and future consumers |
|---|---|---|---|---|---|
| ASN-01 Reservation-table association | Records every table assigned to a confirmed reservation. Sources: FR-08, FR-17, FR-18; PRA-013, PRA-018. | At least one per reservation; one table appears at most once within a reservation; all assignments commit together. | PBD relationship/association concept; exact entity/table representation deferred. | Many-to-many over time: reservation has one or more tables; table has zero or many nonoverlapping reservations. Immutable until controlled reset. | PostgreSQL persists all assignments and enforces atomicity/exclusivity. Flask returns assigned numbers after success; React displays them in confirmation. |
| ASN-02 Assignment occupancy interval | Interval during which an assigned table is exclusive. Sources: PRA-013, PRA-018, PRA-026. | Exactly the parent reservation's immutable `[start,end)`; no separate turnover buffer. | DRV from RSV-03/RSV-04, not duplicated independent business data. | Follows reservation; overlapping participation prohibited; endpoint-touching allowed. | PostgreSQL joins/derives interval for conflicts. Flask uses authoritative availability; React receives only slot status/confirmation. |
| ASN-03 Assigned-capacity total | Sum of capacities of assigned tables at allocation time. Sources: PRA-015, PRA-018. | Must cover party size when booking. Existing reservation remains valid after later capacity changes. | DRV during allocation; no approved historical snapshot required. | Used to select/validate new assignment; not retained as independent source. | PostgreSQL calculates during atomic allocation. Flask need not reimplement; React must not see internal capacity details. |
| ASN-04 Unused assigned seats | Assigned capacity minus party size. Source: PRA-018. | Minimized after minimizing table count; unused seats remain unavailable to others. | DRV. | Exists only for candidate ranking/explanation; no seat-sharing records. | PostgreSQL calculates candidates. Flask/React need not persist or expose it. |
| ASN-05 Candidate tie/random selection data | Equally suitable combinations and random tie choice. Sources: FR-08, FR-18; PRA-018. | Random only after minimum table count and least unused seats. | DRV/TRN; selected assignments become ASN-01. | Candidate sets disappear after transaction. A technical test hook/seed may be considered later but is not business history. | PostgreSQL supplies authoritative candidate/selection behavior; Flask calls it; React does not calculate or select. |

### 4.6 Availability and validation data

| ID / data item | Business meaning and authoritative source | Required/default/approved validation | Classification and source of truth | Lifecycle, identity, and relationships | PostgreSQL responsibility and future consumers |
|---|---|---|---|---|---|
| AVL-01 Availability request date | Date for which slots are requested. Sources: FR-06, FR-07; PRA-008, PRA-010 to PRA-012, PRA-025. | Required request input; restaurant-local; within inclusive current-through-window dates. | TRN. | Exists for one availability request; no availability history. | PostgreSQL supplies settings/inventory/reservations; Flask validates/calculates; React collects. |
| AVL-02 Availability request party size | Party used to evaluate table combinations. Sources: FR-06, FR-07; PRA-015, PRA-023, PRA-025. | Required request integer 1 through current derived maximum. | TRN; becomes RSV-05 only after successful booking. | Exists for request; changing it invalidates selected slot. | PostgreSQL evaluates capacity; Flask validates; React collects. |
| AVL-03 Legitimate daily start slots | Every interval-aligned start that fits hours and ends by close. Sources: PRA-006 to PRA-012, PRA-025. | Derived from date, fixed schedule, interval, duration, lead, window, and timezone. | DRV; not persisted slot rows. | Recomputed per request/current clock/configuration. | PostgreSQL provides config and conflict data; exact calculation allocation between PostgreSQL/Flask is designed later. Flask returns list; React renders all. |
| AVL-04 Slot availability flag | Whether at least one exclusive capacity-sufficient table combination is currently free. Sources: FR-07 to FR-09; PRA-015, PRA-018, PRA-025. | Boolean per derived slot/party request; provisional until booking revalidation. | DRV; not persisted. | Recomputed from retained reservations/assignments; may become stale immediately. | PostgreSQL authoritatively supports revalidation. Flask returns provisional flag; React enables/disables accordingly. |
| AVL-05 Free-table set | Current tables having no overlapping assignment for the requested half-open interval. Sources: PRA-013, PRA-018. | Derived for a request; back-to-back is free. | DRV/TRN. | Transaction/request scoped; never a durable free/busy status. | PostgreSQL derives under booking concurrency rules. Flask requests result; React never receives the internal set before confirmation. |
| AVL-06 Eligible table combinations | Capacity-sufficient combinations from the free-table set. Sources: PRA-015, PRA-018. | Rank by minimum table count, then least unused seats, then random tie. | DRV/TRN. | Request/transaction scoped. Only winning associations persist. | PostgreSQL derives/selects authoritatively. Flask/React do not duplicate logic. |
| AVL-07 Total/maximum capacity display value | Current theoretical maximum party size returned for UI validation. Sources: PRA-015, PRA-017, PRA-023. | Derived from TBL-04; initially 120. | DRV. | Recomputed after table-capacity change. | PostgreSQL supports calculation; Flask exposes safe value; React displays it. |
| AVL-08 Latest valid start | Closing time minus current duration aligned to interval. Sources: PRA-009. | Default 9:30 PM Monday-Saturday and 7:30 PM Sunday. | DRV; not independent configuration or storage. | Recomputed prospectively after duration/interval changes. Existing starts unchanged. | Flask/DB logic later derives; React consumes slots. |
| AVL-09 Same-customer overlap result | Whether the resolved customer's retained reservation intervals overlap the requested interval. Sources: PRA-013, PRA-014. | Overlap uses half-open predicate; exact retry is handled first/consistently; different overlap rejected. | DRV from customer/reservations/fingerprint. | Request scoped. | PostgreSQL enforces authoritative result; Flask maps safe conflict; React displays nontechnical message. |
| AVL-10 Authoritative current time | Server/database clock used for same-day rules. Sources: PRA-011, PRA-012. | Current unambiguous instant converted to restaurant-local time. | TRN/DRV; not business history. | Read per validation. Controlled clock fixture needed in tests. | PostgreSQL/Flask authority boundary is designed later; browser clock is never authoritative. |

### 4.7 Retry and confirmation assembly

| ID / data item | Business meaning and authoritative source | Required/default/approved validation | Classification and source of truth | Lifecycle, identity, and relationships | PostgreSQL responsibility and future consumers |
|---|---|---|---|---|---|
| CNF-01 Stable confirmation reference | Reference displayed after successful booking and on exact retry. Source: PRA-024. | Required. The SRS Reservation ID can satisfy it; whether to expose that identifier directly or derive a separate safe public reference is deferred. | PBD from RSV-01 or TID derived from it. | Stable for reservation lifetime. | PostgreSQL supplies stable reservation identity. Flask returns safe reference; React displays. |
| CNF-02 Confirmation customer name | Structured customer values assembled for display. Source: PRA-024. | Required display; uses authoritative CUS-02 to CUS-04. | DRV; no duplicate confirmation snapshot required. | Reflects retained customer value; no Version 1 general name modification. | PostgreSQL supplies customer values; Flask formats; React displays. |
| CNF-03 Confirmation start/end | Booked restaurant-local interval. Sources: PRA-012, PRA-024, PRA-026. | Required; New York display; original interval immutable. | DRV display from RSV-03/RSV-04 and timezone rules. | Stable booking facts despite later configuration changes. | PostgreSQL supplies facts; Flask converts/formats; React displays. |
| CNF-04 Confirmation party size | Booked guest count. Source: PRA-024. | Required; authoritative RSV-05. | PBD reused, not duplicated. | Immutable. | PostgreSQL supplies; Flask returns; React displays. |
| CNF-05 Confirmation assigned tables | All table numbers assigned. Source: PRA-024. | Required one or more; authoritative ASN-01/TBL-01. | PBD relationship reused, not duplicated. | Immutable. | PostgreSQL supplies; Flask returns; React displays only after success. |
| CNF-06 Confirmation newsletter state | Customer's current authoritative newsletter state. Sources: PRA-024, PRA-027. | Required display when available; exact retry returns current CUS-09 and does not replay newsletter action. | PBD reused/DRV response; no reservation snapshot/history. | May differ from state at original booking after independent preference change. | PostgreSQL supplies current state; Flask returns; React displays. |
| CNF-07 Restaurant address and phone | SRS contact details included in confirmation. Sources: FR-02; PRA-024. | Fixed address `1234 Culinary Ave, Suite 100, Washington, DC 20002`; phone `(202) 555-4567`. | FIX; no PostgreSQL persistence requirement. | Stable SRS content. | Flask/React may use shared fixed content; no business database duplication required. |
| CNF-08 Email/SMS delivery status | Whether confirmation was delivered externally. Sources: PRA-024; FE-011. | No delivery occurs and no claim may be made. | FE; no persistent data. | No events/status. | Excluded. |

## 5. Candidate relationships and cardinalities

These relationships organize requirements only; they do not finalize entities or schema:

| Relationship | Required cardinality and rule | Sources |
|---|---|---|
| Customer to reservation | One customer may hold zero or many reservations; each reservation belongs to exactly one customer. | FR-17, FR-18; PRA-014, PRA-019 |
| Reservation to restaurant table | Each confirmed reservation has one or more assigned tables; each table may serve zero or many reservations over time, but never overlapping reservations. | FR-08, FR-17, FR-18; PRA-013, PRA-018 |
| Reservation to assignment | Every assigned table is recorded exactly once for the reservation; all assignments commit or roll back together. | PRA-018 |
| Customer to newsletter preference | Exactly one current Boolean state per persisted customer; no separate subscriber record set. | FR-15 to FR-17; PRA-020, PRA-021 |
| Configuration to reservations | One current configuration set governs many new availability/booking calculations; existing reservations retain their original occupancy facts and do not depend on historical configuration records. | PRA-005 to PRA-012; PRA-026 |
| Restaurant table to capacity | Each of exactly 30 current tables has exactly one current capacity value. | PRA-016, PRA-017 |
| Reservation to fingerprint | Each confirmed reservation has one database-generated versioned fingerprint; an equivalent request resolves to the existing reservation after underlying-fact verification. | PRA-014, PRA-027 |

## 6. Uniqueness, identity, lifecycle, and retention rules

### 6.1 Uniqueness and identity

1. Normalized email uniquely identifies one customer.
2. First and last names must match the customer found by normalized email; they are not independent unique keys.
3. Middle initial and phone are neither identity keys nor fingerprint inputs.
4. Each restaurant table has a unique stable identifier/number.
5. Each reservation has a unique stable identifier/reference.
6. Each reservation-table pair appears no more than once.
7. A table may not participate in overlapping reservation assignments.
8. The versioned reservation fingerprint is generated from customer ID, canonical start, and party size. A hash match must be verified against those underlying facts.
9. The same customer may not hold a different overlapping reservation, even if sufficient tables remain.
10. Back-to-back occupancy is allowed because intervals are half-open.

### 6.2 Lifecycle

1. A customer is created by a successful reservation or a new selected newsletter preference. New-unselected newsletter input creates no record.
2. Customer first/last name cannot be silently updated. Middle initial and phone follow their approved limited populate/preserve/reject rules.
3. Newsletter status can change independently and idempotently; unsubscribe retains the customer.
4. A confirmed reservation is immutable in Version 1 and remains associated with all assigned tables for its original interval.
5. Table capacity/configuration changes apply only to new calculations; existing reservations are not recalculated or invalidated.
6. Past reservations remain stored but cease affecting availability because their intervals have elapsed.
7. No automatic deletion, archive, anonymization, cancellation, rescheduling, or no-show transition occurs.
8. Controlled reset/reinitialization may delete designated development, test, or demonstration data and recreate a known configuration. It is not a customer workflow.

### 6.3 Retention

| Data | Version 1 retention |
|---|---|
| Customer | Retain through normal operation, including after unsubscribe; remove only through controlled nonproduction reset. |
| Current newsletter status | Retain with customer and overwrite with the latest committed Boolean state; no event history. |
| Reservation and assignments | Retain through normal operation, including after the interval passes; remove only through controlled nonproduction reset. |
| Reservation fingerprint | Retain for the reservation lifetime to support exact retry. |
| Current configuration/table capacities | Retain current values; no version history. Controlled reinitialization may restore known defaults. |
| Availability/candidate/slot data | Do not retain; recompute. |
| Confirmation-email input | Do not retain. |

## 7. SRS minimum-field mismatch and additive-refinement analysis

| Mismatch | Required resolution | Why additive rather than contradictory |
|---|---|---|
| Number of Guests appears on the SRS reservation form but not its minimum Reservations fields. | Persist party size with each reservation. | It preserves information required to validate capacity and demonstrate the SRS form; no required field is removed. |
| SRS Customer Name is singular; approved name is structured. | Preserve first name, optional middle initial, and last name as the collective Customer Name. | Structured components retain the full required concept and improve deterministic matching. |
| SRS Time Slot is singular; approved occupancy has start and end/duration. | Preserve start plus an immutable booked end/duration fact. | It makes the SRS time slot operational and prevents overlap; it does not change the selected start. |
| SRS Table Number is singular; approved reservations may require multiple tables. | Preserve one or more specific table assignments. A single-table booking still has one table number. | Multi-table capability extends capacity while maintaining the SRS's concrete table assignment. |
| SRS assumes 30 tables but provides no table-inventory or capacity fields. | Persist exactly 30 current table identities and individual capacities, initially four. | It operationalizes the required 30-table availability model without activating more tables. |
| SRS does not identify configurable interval/duration/window/lead/timezone data. | Persist the five approved current business settings. | The SRS leaves these rules undefined; configuration makes its validity/availability requirements deterministic. |
| SRS newsletter signup may suggest a subscriber list, but Customers already includes Newsletter Signup. | Keep the current Boolean only on the customer and retain the dedicated form. | It satisfies signup/storage while preventing contradictory duplicate sources and additively supports unsubscribe. |
| SRS does not define retry correlation. | Persist a database-generated opaque fingerprint and version with the reservation. | It strengthens confirmation and double-booking protection without changing the visible booking requirements. |
| SRS does not explicitly require stable confirmation details beyond success. | Use authoritative reservation/customer/assignment data to assemble the approved confirmation. | It provides evidence and user clarity without duplicating business facts. |
| SRS is silent on retention/reset. | Retain normal-operation data and provide controlled nonproduction reset/reinitialization later. | It preserves reliable storage and demonstration evidence while adding repeatability, not customer-facing deletion. |

## 8. Data required by key reservation behaviors

### 8.1 Availability

Authoritative availability requires:

- requested restaurant-local date and party size (transient);
- current authoritative time (transient);
- fixed weekly hours;
- current interval, duration, window, lead-time, and timezone configuration;
- exactly 30 table identities and capacities;
- retained reservation immutable intervals;
- retained reservation-table assignments;
- half-open overlap rule;
- derived free-table and capacity-sufficient combinations.

Availability status itself must not be persisted. It is provisional and must be recomputed/revalidated when booking commits.

### 8.2 Exclusive multi-table assignment

Authoritative assignment requires:

- immutable party size and requested interval;
- current table identities/capacities;
- current overlapping assignments;
- derived free-table set;
- derived combinations ranked by minimum number of tables, then minimum unused seats, then random tie selection;
- persistent winning reservation-to-table associations committed all-or-none.

No seat-level allocation, sharing, adjacency, partial assignment, or customer selection data is required.

### 8.3 Exact retry safety

Authoritative retry handling requires:

- resolved customer identifier;
- canonical reservation start;
- party size;
- fingerprint algorithm version;
- stored opaque fingerprint;
- stored reservation and assignments for existing-confirmation reconstruction;
- verification that stored customer/start/party facts match after fingerprint lookup.

Names, email text, middle initial, phone, newsletter action/status, end time, configuration, and assigned tables are not fingerprint inputs. On exact retry, newsletter mutation is not replayed; current customer newsletter state is returned.

## 9. Technical data decisions deferred to later prompts

The following do not represent unresolved business requirements and must not be finalized in DB-01:

- exact conceptual entities and whether configuration is one record or several;
- exact tables, columns, PostgreSQL data types, keys, constraints, indexes, and naming conventions;
- representation of normalized email/name/phone comparison values;
- representation of the immutable booked end/duration fact;
- exact fingerprint/hash algorithm, storage format, algorithm-version representation, and collision-verification mechanism;
- whether the SRS Reservation ID is exposed directly or mapped to a separate safe public confirmation reference;
- whether technical created/updated timestamps are justified;
- exact maximum database capacity value beyond the approved positive-seat requirement;
- transaction isolation, locking, allocation implementation, and random tie testability;
- reset/reinitialization script structure, safety guards, fixtures, and commands;
- exact division of slot calculation between PostgreSQL and Flask;
- performance-oriented materialization or indexing, if any.

## 10. Data explicitly excluded from Version 1

| Excluded data/function | Reason/source |
|---|---|
| Authentication credentials, password hashes, sessions, roles | FE-001; authentication inactive |
| Verified-profile and email-verification tokens/history | FE-002, FE-004 |
| Automatic-prefill profile metadata | FE-003 |
| Cancellation/modification/rescheduling status, tokens, reasons, history | FE-005, FE-006; PRA-022 |
| No-show status/history | FE-007 |
| Administrative users/actions/audit | FE-008 |
| Holiday/exception closure dates | FE-009; PRA-008 |
| Newsletter subscription event/history/audit records | FE-010; PRA-020 |
| Confirmation email/SMS delivery addresses, messages, or delivery status | FE-011; PRA-024 |
| Table adjacency/combinability/floor-plan data | FE-012; PRA-018 |
| More than 30 active Version 1 tables | FE-013; PRA-016 |
| General customer contact-update history | FE-014; PRA-019 |
| Retroactive reservation/configuration recalculation data | FE-015; PRA-026 |
| Effective-dated configuration versions | FE-016; PRA-026 |
| Production retention/archive/anonymization/deletion policy records | FE-017; PRA-028 |
| Independent availability ledger or preallocated slot rows | Availability is derived and revalidated |
| Separate newsletter subscriber source | PRA-020; Customers is authoritative |
| Confirmation-email duplicate | PRA-019, PRA-023; transient validation only |

## 11. Requirements traceability

| Requirement group | Persistent/configured/derived data contribution |
|---|---|
| FR-06 | Customer structured name/email/optional phone, reservation start, party size; confirmation email transient |
| FR-07 | Configuration, schedule, reservation intervals, assignments, derived availability |
| FR-08 | Exactly 30 table identities/capacities, derived eligible combinations, persistent winning assignments |
| FR-09 | Reservation identity/fingerprint and assembled confirmation/failure outcomes |
| FR-15 to FR-16 | Customer canonical email, current newsletter Boolean, transient confirmation email/action |
| FR-17 | Customer and reservation minimum business facts, additively structured/related as documented |
| FR-18 | Customer relationship, availability inputs, assignments, confirmation facts |
| NFR-02 | Current configuration and data/index design later support timing; no new business data required |
| NFR-05 | Immutable intervals, assignments, fingerprint, uniqueness/exclusivity, atomic behavior later |
| NFR-06 | Safe response/log behavior; no technical error data is required as business persistence |
| NFR-09 | Traceable definitions and later data dictionary/migrations; optional technical metadata deferred |
| PRA-006 to PRA-012 | Five PostgreSQL settings, fixed hours, and derived date/time boundaries |
| PRA-013 to PRA-018 | Immutable half-open intervals, table capacity/inventory, derived availability, exclusive assignments |
| PRA-019 to PRA-021 | Customer identity, structured name, optional phone, single authoritative current newsletter state |
| PRA-022 to PRA-025 | Immutable active reservations, validation inputs, confirmation assembly, provisional slot display |
| PRA-026 | Prospective configuration behavior and controlled repeatable reset requirement |
| PRA-027 | Versioned database fingerprint, exact retry, and newsletter separation |
| PRA-028 | Retention through normal operation and no automatic purge/archive |
| RUB-01, RUB-05 to RUB-07 | Complete SRS data, working forms, full-stack integration, direct database effects, sophisticated logic |

## 12. Future PostgreSQL, Flask, and React information needs

| Consumer | Required information from this inventory |
|---|---|
| PostgreSQL implementation | Durable customer/reservation/table/configuration/assignment/fingerprint facts; derivation inputs; integrity/lifecycle rules; reset baseline. |
| Flask API | Current limits/timezone; customer match and newsletter state; daily derived slot statuses; authoritative booking/confirmation/retry outcomes; current newsletter state on retry. |
| React/JSX | Dynamic party maximum; restaurant-local date/time and full slot list; validation outcomes; async newsletter state; reservation confirmation reference, start/end, party size, all table numbers, and current newsletter state. |
| Demonstration/testing | Known 30 x 4 initialization; repeatable customers/reservations; direct queries showing newsletter and reservation effects; controlled conflicts; safe reset/reinitialization. |

## 13. Remaining unresolved persistent-data requirements

No genuinely unresolved persistent-data business requirement remains after approval of:

- P4-LIF-01, recorded as PRA-026;
- P4-RTY-01, recorded as PRA-027;
- P4-RET-01, recorded as PRA-028.

The items in Section 9 are intentionally deferred technical design choices, not business-rule ambiguities and not authorization to add scope.

## 14. DB-01 completion assessment and approval checkpoint

### Completion assessment

| DB-01 criterion | Result |
|---|---|
| Customers and structured names covered | Complete |
| Canonical email, confirmation email, and optional phone classified | Complete |
| Current newsletter source of truth and lifecycle covered | Complete |
| All approved PostgreSQL settings covered | Complete |
| Exactly 30 tables and individual capacities covered | Complete |
| Reservation start/end/party/fingerprint covered | Complete |
| One-or-more exclusive assignments covered | Complete |
| Availability and derived values separated from persistence | Complete |
| Uniqueness, lifecycle, retention, and reset covered | Complete |
| SRS minimum-field mismatches reconciled | Complete |
| Future-enhancement data excluded | Complete |
| Traceability established | Complete |
| Conceptual/logical/schema decisions avoided | Complete |
| SQL/application code avoided | Complete |

### Approval checkpoint

DB-01 is **ready for user review and approval**. Approval authorizes Prompt 5 / DB-02 conceptual data modeling. It does not approve a PostgreSQL schema, SQL, migrations, transaction mechanism, Flask contract, or React design.

No SQL or application code was generated.
