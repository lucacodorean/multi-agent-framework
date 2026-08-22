# 0035 — Lock the aggregate root where only one row may hold a slot

- Status: accepted
- Date: 2026-08-20

## Context

- `project_entity_one_lider_per_project` admits one lider per project and is checked per
  statement. At READ COMMITTED a rival's uncommitted row is invisible, so two acts both read
  "this project has no lider" and both write one.
- Everywhere else in `app/RiskRegister/**` the two acts assert the SAME fact and converging on
  a unique index is the answer. Here they assert DIFFERENT liders: the loser met the index and
  reached the officer as a raw driver error, its whole import rolled back.
- ADR-0033 rules 3 and 5 answer a read-then-write race with an aggregate-root lock or an
  advisory key. Neither had been applied to the register's intake paths.

## Decision

1. Where two acts may assert DIFFERENT facts about a slot only one row may hold, take the
   aggregate root FIRST. Converging on the unique index is wrong: which assertion survives is
   a rule, and a rule needs something to decide about.
2. `app/RiskRegister/ProjectRegisterLock.php` locks every project an act will touch before the
   act reads the slot, in ascending cod SMIS — a total order derived from the DATA, never from
   the source file's order. A deadlock arrives as `DeadlockException`, which extends
   `PDOException` and escapes every `QueryException` catch in that namespace.
3. Lock projects before entities. `insert … on conflict do nothing` waits on a conflicting
   uncommitted tuple, so it is a lock acquisition too; the two resource classes are always
   taken in one order.
4. On the far side of the lock each path applies its OWN rule, differing by the authority of
   its source:
   - contract import — the ministry workbook REPLACES the incumbent; the newest file wins;
   - association import — a supplementary CSV KEEPS the incumbent and reports the line
     `IgnoredLineReason::SECOND_LEADER`;
   - manual registration — a human at the keyboard is REFUSED, the holder named.

## Consequences

- Three serialization mechanisms stand side by side: convergence on a unique index where the
  ruled outcome IS convergence; the aggregate-root lock where the ruled outcome is a rule; an
  advisory key where no row represents the invariant. ADR-0033 rules 3 and 5 are unchanged.
- A fourth write path takes its lider rule from its source's authority, not from the index.
- Entity rows are still created in the source file's order — an open deadlock window filed in
  `docs/backlog.md`.
