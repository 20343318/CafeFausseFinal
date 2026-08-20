# DB-06 advisory-lock namespaces

DB-05 reserved these identifiers. DB-06 now acquires them through controlled
`SECURITY DEFINER` operations.

## Two-key advisory-lock convention

Later controlled operations must use PostgreSQL's transaction-scoped two-key
advisory-lock family (`pg_advisory_xact_lock(integer, integer)`). Keeping a
separate first key for each lock family prevents a restaurant lock from ever
aliasing an email-derived lock.

| Lock family | First key (namespace) | Second key |
|---|---:|---:|
| Restaurant-wide booking/configuration coordination | `1128682322` (`0x43465352`, ASCII `CFSR`) | `1` |
| Canonical-customer-email coordination | `1128678733` (`0x4346454D`, ASCII `CFEM`) | Signed 32-bit value derived below from the canonical lowercase email |

The second email key is derived by SHA-256 hashing the canonical email's UTF-8
bytes, interpreting digest bytes 0-3 as one unsigned big-endian 32-bit integer,
then mapping values at or above `2^31` to the equivalent two's-complement signed
integer by subtracting `2^32`. The implementation is
`cafe_fausse.canonical_email_lock_key(text)` and is test-role-only. Different
emails may theoretically collide; that causes safe over-serialization. The
distinct first keys prevent cross-family collision.

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

Migration and test sessions use `lock_timeout=5s` and
`statement_timeout=60s`. Controlled DB-06 operations tighten those transaction
settings to `lock_timeout=3s` and `statement_timeout=15s`. Later Flask code must
make at most three full attempts within one overall deadline for retryable
`55P03`, `40P01`, and `40001` failures; it must not resume a failed transaction.
