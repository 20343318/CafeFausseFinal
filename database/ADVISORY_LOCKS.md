# DB-06 advisory-lock namespace reservation

This document reserves identifiers only. DB-05 does not acquire a booking or
customer advisory lock and does not implement a booking operation.

## Two-key advisory-lock convention

Later controlled operations must use PostgreSQL's transaction-scoped two-key
advisory-lock family (`pg_advisory_xact_lock(integer, integer)`). Keeping a
separate first key for each lock family prevents a restaurant lock from ever
aliasing an email-derived lock.

| Lock family | First key (namespace) | Second key |
|---|---:|---:|
| Restaurant-wide booking/configuration coordination | `1128682322` (`0x43465352`, ASCII `CFSR`) | `1` |
| Canonical-customer-email coordination | `1128678733` (`0x4346454D`, ASCII `CFEM`) | DB-06 deterministic signed 32-bit derivation from the canonical lowercase email |

DB-06 must define and test the exact canonical-email byte serialization and
signed 32-bit derivation before it acquires the email lock. Different emails
may theoretically collide in a 32-bit advisory key; that only causes safe
over-serialization. The distinct first keys prevent cross-family collision.

## Required ordering and coordination

The approved DB-04 order remains:

1. restaurant-wide transaction lock;
2. configuration row;
3. operating-hours rows in weekday order;
4. restaurant-table rows in table-number order;
5. canonical-email transaction lock;
6. matching customer row;
7. reservation and assignment work added by DB-06.

Random table selection never controls lock acquisition order. Once controlled
writers exist, configuration, operating-hours, and table-capacity writers must
obtain the restaurant-wide lock before reading or changing coordinated facts.

DB-05 migration and test sessions use bounded `lock_timeout=5s` and
`statement_timeout=60s`. DB-06 must select and measure its shorter booking
operation deadline and bounded retry policy without changing this namespace.
