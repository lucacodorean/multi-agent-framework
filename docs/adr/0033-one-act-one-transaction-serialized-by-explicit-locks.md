# 0033 — One act, one transaction, serialized by explicit locks

- Status: accepted
- Date: 2026-08-19

## Context

Acts committed statement by statement: a mid-act failure left half an act written, and
queued mail and log lines ran whether or not the act committed. READ COMMITTED plus
read-then-write in PHP loses updates (ADR-0031 ruled one such site), and a swallowed
`QueryException` aborts the whole transaction — 25P02 thereafter.

## Decision — six rules

1. ONE ACT, ONE TRANSACTION, opened by the use-case class; entry points open none
   (`architecture-principles.md`). Nested repository transactions stay as
   SAVEPOINTs. `$attempts > 1` only where the closure is pure database work. Shape:
   `app/Dosar/ExpenseLedgerIntake.php`.
2. DATABASE IO ONLY INSIDE. Engine calls, parsing, rendering, hashing and filesystem moves
   before it; SMTP, dispatches, queued mailables, cache flushes and `SecurityEventLog` after
   it returns — never in a `finally` or model event inside it. A refusal's log line stays: it
   has no commit to follow.
3. LOCK THE AGGREGATE ROOT AS THE FIRST STATEMENT, THEN RECOMPUTE FROM WHAT THE LOCK RETURNED.
   `SELECT id FROM dosare WHERE id = ? FOR UPDATE`, before any read the act writes back; never
   from the model the page hydrated. No row means unknown aggregate, not "no lock needed".
   Order `dosare → documents → children`, parent before child. Reads take no lock.
4. A SWALLOWED `QueryException` NEEDS A SAVEPOINT: the failing statement in its own
   `DB::transaction()`, `catch` outside it.
5. READ COMMITTED STAYS; SERIALIZE WITH EXPLICIT LOCKS, NEVER AN ISOLATION LEVEL. Where no row
   represents the invariant, take the transaction-scoped advisory lock whose ordinal the
   registry allocates (`docs/conventions/engineering-principles.md`), first statement, on the
   transaction's own connection. `pg_advisory_xact_lock` only — never session-scoped
   `pg_advisory_lock` or `pg_advisory_unlock` in application code.
6. CROSS-CONNECTION ACTS ARE NOT ATOMIC. Provisioning and the central journal writes stay
   ordered-with-compensation. A lock belongs to the session that issued it, so a central
   invariant is guarded inside a transaction opened on the central connection.

## Key derivation

`SELECT pg_advisory_xact_lock(<invariant>, <scope>)`, two-int form only — disjoint from the
one-argument suite-run lock in `tests/Pest.php`. `invariant = 1330184192 + ordinal`
(`0x4F49` = 'OI'), one ordinal per invariant, table-allocated. `scope` = the tenant schema OID
`(SELECT oid::int4 FROM pg_namespace WHERE nspname = current_schema())`, or the literal `0`
for central. The OID, not the slug: `renameSlug()` renames the schema in place and the OID
survives, so a rename cannot split the key. Argument order is part of the key.

## Consequences

- ADR-0028's decision stands; its consequence line does not. Mail is off the create critical
  path: the mailable is queued, every connection carries `after_commit`, and `issue()` runs
  after `TenantUsers::create()` commits. A failure inside `issue()` leaves a committed account
  never mailed its link — unusable secret, `password_set_at` NULL; re-issuing it recovers.
- `ConvertNotaToPdf::convert()` is four sequential acts, not one: rule 2 forbids nesting acts
  that mail or log after their own commit. The one place rule 1 does not compose upward.
