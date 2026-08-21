# DB-07 PostgreSQL-only manual demonstration

Use only a disposable database named `cafe_fausse_dev*`, `cafe_fausse_test*`, or `cafe_fausse_demo*`. Set the variables shown in `database/README.md`, including `CAFE_FAUSSE_ALLOW_RESET=YES`; never use production data.

1. Run `database/scripts/rebuild.ps1`. Run `database/scripts/verify.ps1`; both must end with DB-07 success.
2. In `psql`, inspect `pg_extension`, `pg_namespace`, `pg_proc`, and `pg_indexes` using the commands in `database/README.md`. Confirm migrations 001–011 exist in lexical order in the repository.
3. Run `TABLE cafe_fausse.reservation_configuration;`. Expect exactly `(1,30,90,60,120,America/New_York)`.
4. Run `TABLE cafe_fausse.restaurant_operating_hours;`. Expect weekdays 1–6 `17:00–23:00` and weekday 7 `17:00–21:00`.
5. Run the inventory aggregate from `database/README.md`. Expect 30 tables, 4 minimum/maximum capacity, total 120.
6. Run the “Manual DB-06 demonstration” booking in `database/README.md` as `cafe_fausse_app`. Inspect the one customer, subscribed state, reservation, and assignment as `cafe_fausse_test`.
7. Repeat it unchanged to show `exact_retry`, the same reservation ID/interval/tables, and no duplicate row—this also simulates loss of the first successful response.
8. Choose a second slot and party size 8 to show a multi-table result. Use the returned sorted table array as the confirmation facts.
9. Book the same customer at the first reservation’s end to show back-to-back success; submit an overlapping start to show `same_customer_overlap`. Submit another customer at that overlap to show success when a different exclusive table remains.
10. In an isolated transaction set every table except one to capacity 1, book that last capacity, and submit a competing customer for `unavailable`; roll back or rebuild afterward.
11. Run `database/tests/db06_behavior_tests.sql`. Its five controlled failure stages prove rollback after customer insert, blank-field population, newsletter update, reservation insert, and partial assignment insert; it also covers all overlap shapes and prospective configuration/hour/capacity changes.
12. Run `database/scripts/concurrency_test.ps1 -Iterations 20`. It uses PostgreSQL-observed lock waits as barriers and includes identical, same-email, blank-field, last-table, writer, timeout, deadlock, and lost-response cases.
13. As `cafe_fausse_app`, call each of the three production routines successfully. Then run `database/tests/runtime_privilege_denials.sql` and `database/tests/db06_runtime_privilege_denials.sql` to demonstrate denied direct DML/DDL, reservation reads, helpers, writers, and test seams.
14. Run `database/verification/query_plans_db07.sql` for rollback-safe retained-history plan evidence.
15. Run `database/scripts/rebuild.ps1` again. Verify zero customers/reservations/assignments, reset identity state, and the exact initial configuration, schedule, and inventory.

For the complete repeatable form, run `database/scripts/test.ps1`; it performs the clean-build, reset, unit, privilege, concurrency, plan, measurement, and final-empty-baseline sequence without Flask.
