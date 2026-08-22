# 0031 — Lock the import document row before recounting it

- Status: accepted
- Date: 2026-08-19

## Context

- `TenantContractImportRepository::refreshDocumentState()` re-reads a contract-import
  document's items and entity names, recomputes `pending_decision_count` and `in_lucru` in
  PHP, and writes them back — only inside the decision transaction (`decide()`,
  `decideEntityName()`). Store: ADR-0030.
- Two officers on one document is designed for. Unserialized at READ COMMITTED each
  decision computes from a snapshot excluding the other's uncommitted answer and the second
  UPDATE overwrites the first: answering a document's last two exceptions at once leaves
  `pending_decision_count = 1` and `in_lucru = true` with nothing pending.
- Nothing complains: the CHECK `in_lucru = (pending_decision_count > 0)` holds for the
  wrong number, and with nothing left to answer nothing recounts — the document stays open
  and no surface can clear it.
- Reproduced by `tests/Feature/Tenancy/ContractImportConcurrencyTest.php` and its helper:
  two processes, the second released at the statement that takes the first's snapshot, its
  wait confirmed in `pg_stat_activity`.

## Decision

- Take the document's row lock as the FIRST statement of the recount, before reading the
  items and names: at READ COMMITTED every statement takes a fresh snapshot, so a second
  decider blocks there and reads afterwards with the first answer committed. Keep it though
  that row is UPDATEd later — the UPDATE's own lock sits on the wrong side of the read.
- Recount only inside the decision transaction: outside one the lock ends with its
  statement and this is a plain read.
- Do not recompute the counts in SQL inside the writing UPDATE. Rejected on MEASUREMENT,
  PostgreSQL 16.14: a two-session probe here — each answering one of two items, then
  `UPDATE doc SET pending = (SELECT count(*) FROM items WHERE NOT answered)` — blocked the
  second, which wrote 1 where 0 was true. A blocked updater re-evaluates against the updated
  version of the row it updates, seeing concurrent effects there only, not on other rows
  (PostgreSQL 16 § 13.2.1, READ COMMITTED); every count here comes from other rows. It also
  moves the domain's definition of pending (`pendingExceptions()`, `isPending()`) into SQL.

## Consequences

- Decisions on one document serialize from the recount to commit (cost: the docblock);
  different documents never meet, and no read path locks.
- Deleting the lock passes every other test and the CHECK constraint; only the concurrency
  test sees the regression.
