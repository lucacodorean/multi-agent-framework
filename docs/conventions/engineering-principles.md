# Engineering principles

Code-level discipline: how one class, method or file is written. Structural and boundary
rules live in `docs/conventions/architecture-principles.md`.

Scope: PHP under the paths `phpstan.neon` analyses. `infra/**` PHP and the Python engine
sit outside every gate named here. `## Comments` is the one rule below binding every
language the roster writes, Python docstrings included.

## Enforced by a gate — point at it, do not exhort

- Style: Pint on the `laravel` preset. There is no `pint.json`; the preset is the standard.
- Types, undefined calls, dead branches: PHPStan/Larastan `level: 5` (`phpstan.neon`).
  Never pass `--level`, never lower it; an ignore is scoped by path and carries its reason.
- Both run in the static-analysis gate; invocation in `docs/runbook.md`.
- ADR citations in source: the adr-citations gate (`docs/architecture.md` § CI — gates).
- Nothing enforces `declare(strict_types=1)` (Pint's preset omits it), nor any rule below
  beyond that citation form.

## Class

- One reason to change. A name needing "And" — or `Manager`, `Helper`, `Util`, `Service`,
  `Handler` — is a split, not a name.
- Open every PHP file with `declare(strict_types=1);`. Untouched framework scaffold is the
  only exception in tree.
- A use case is one class named for its imperative verb with one public method of that verb:
  `app/Dosar/Sampling/ConfirmSampling::confirm`.
- Value object: `final readonly`, promoted public properties, private constructor, static
  named constructors that validate. Canonical: `app/RiskRegister/FiscalCode.php`.
- Use cases and adapters are `final` with `readonly` state; prefer class-level
  `final readonly`.
- A pure derivation is a static-only `final class` with no constructor:
  `app/Dosar/Determination/SampleSize.php`.
- Domain vocabulary is a backed string enum carrying its own labels and metadata:
  `app/Dosar/Documents/DocumentKind.php`.
- Keep Eloquent models thin — table constant, casts, relations, derived reads. Decisions
  live in the context class; a thin model is not a defect to fix.
- Each module owns its failure vocabulary in its own `Exceptions/` namespace.
- A refusal is a `final` `RuntimeException` with a private constructor, static named
  factories and `public readonly string $reasonCode`:
  `app/Dosar/Exceptions/DosarRefused.php`. Refusals in `Auth` and `Tenancy` predate
  `reasonCode`; new ones carry it.

## Method

- Inject every collaborator through the constructor. No `app()`, `resolve()`, `App::make`
  or `new` of infrastructure inside `app/Dosar/**`, `app/RiskRegister/**`,
  `app/Auth/**`. Boundary form: `architecture-principles.md` → Ports.
- Immutability by default: no setters, a change produces a new value
  (`app/Dosar/DosarState.php`).
- Fail fast: guard at the boundary, throw a named exception, never swallow a throwable to
  return an empty value.
- A method mutates or returns, not both; framework APIs are exempt.
- No chains through object internals; fluent builders are exempt.
- No magic strings or numbers — named constants or enums.
- Take the moment as an optional parameter defaulting to now
  (`app/Dosar/ExpensePopulationPreparation::prepare`). There is no clock port; bare `now()`
  in `app/Tenancy/**`, `app/Auth/**`, `app/RiskRegister/**` is the divergence, not the
  target.
- A fiscal code is a string; never rely on it being numeric.
- An array keyed by fiscal code is typed `array<array-key, …>`, never `array<string, …>`:
  PHP narrows an all-digit key to `int` as the map is built, so re-keying with a cast is a
  no-op. Cast only where a key becomes a value. No gate catches a breach, so a test asserts
  the element type (`tests/Feature/Tenancy/TenantRiskIndexStoreAdapterTest.php`).

## Transactions and locks

Doctrine: ADR-0033 (six rules, key derivation).

- Take an advisory key from `App\Enums\AdvisoryLock` and issue its `statement()` with
  `DB::statement()`, never `DB::select()` (the read PDO), as the transaction's first
  statement: `app/Auth/TenantUsers.php`.
- A refusal whose record must outlive it is its own act: commit the record, then throw
  (`app/Dosar/Sampling/ConfirmSampling.php`).
- Where a unique index already serializes the write, one `upsert()` replaces both the lock
  and `exists()` → `insert()`, a lost-insert window surfacing as a raw driver error.
  Write only the columns a re-save must change, keeping the first write's stamps:
  `app/Dosar/Verification/ClarificationDraft.php`.
- Where a re-save must change no column at all, `insertOrIgnore()`. Where the table carries a
  SECOND unique index whose violation must still surface, name the conflict target
  (`insertOrIgnoreReturning($values, $returning, $uniqueBy)`); an untargeted `on conflict do
  nothing` swallows that index too: `app/RiskRegister/ContractImportProjection.php`.
- Where two acts may assert DIFFERENT facts about a slot only one row may hold, converging on
  the unique index is wrong: lock the aggregate root before the act reads the slot, in an
  order derived from the data and never from the source document (ADR-0035):
  `app/RiskRegister/ProjectRegisterLock.php`. Take the parent resource before any row an
  `insert … on conflict do nothing` will touch — that statement waits on a conflicting
  uncommitted tuple, so it is a lock acquisition too.
- Translate a unique violation into a domain refusal only when the SQLSTATE is `23505` AND the
  driver message carries the index name QUOTED (another index's 23505 reports the offending
  values, which may spell that name unquoted); every other 23505 propagates. Run the insert in
  its own nested transaction, so the rollback stops at a savepoint and the refusal reaches a
  caller whose act transaction can still run a statement:
  `app/Dosar/Signature/SignatureCircuit.php`.
- An act whose log line states what committed returns a carrier and announces through a separate
  `announce*()` the caller runs after its own commit (`app/Dosar/DosarLifecycle.php`, called from
  `app/Dosar/ExpenseLedgerIntake.php`).
- Keep an entry-point form beside it — same writes, same refusals, announcing for itself — only
  for call sites with no transaction open; the twin the caller takes carries the `Deferred` suffix.
- A `catch` that rethrows unconditionally needs no savepoint: no statement follows it in the
  aborted transaction.
- `DeadlockException` extends `PDOException`, not `QueryException`: it escapes such a catch
  and fails the act.
- Initializing or ending tenancy with a transaction open on the default connection is
  refused (`app/Tenancy/RefuseTenancySwitchInsideTransaction.php`).

### Advisory-lock keys

Registry: `app/Enums/AdvisoryLock.php` — every allocated key, its invariant, its scope and the
statement taking it. The backing value IS the key, so two invariants sharing one is a boot
fatal rather than an assertion.

- Ordinals come from the contract-owner BEFORE implementation, never the call site; 5..65535
  are free. A `pg_advisory_xact_lock` literal absent from that enum is a defect.
- An act that can only raise the guarded count (`create`, `reactivate`, `activate`,
  `register`) takes no key.

## Extension

- Composition over inheritance. Inheritance only for a true is-a, one level deep, unless
  the framework requires more.
- Extend by a new implementation, not by editing stable code; prefer polymorphism over a
  type switch.
- Subtypes are drop-in: never throw "not implemented" in an override, never strengthen a
  precondition or weaken a postcondition.
- Depend on narrow interfaces. An implementation with an empty method means the interface
  is too fat.
- The class that aggregates an object creates it; add a factory only for complex or
  polymorphic creation.

## Comments

- Write a comment only where one is necessary or useful. Not by default, not one per class,
  not one per method.
- Keep it brief. One line where one line does.
- Earns a comment: why a thing is done, a constraint invisible from the code, a deliberate
  departure from a rule that otherwise binds.
- Earns none: restating the signature, narrating the next statement, or explaining what a
  well-named symbol already says.
- Type-carrying PHPDoc is not commentary. `@param`, `@return`, `@var`, `@property`,
  `@extends`, `@template`, `@phpstan-type` express types the native signature cannot and are
  read by the `level: 5` gate — keep them; trim only the prose beside them.
- A comment naming an ADR is gated on the citation half only (§ Enforced by a gate).
  Whether a comment earns its place, and whether it is brief, cannot be gated: the roster
  and code-reviewer definitions under `.claude/agents/` carry them by pointing here, and
  code-reviewer reports an unearned comment as a finding.

## Tests

- `Http::fake()` merges stubs and the first match wins: a second stub for the same operation
  never answers, so a test of two successive calls exercises one.
- Fake successive calls to one operation by keying the stub on the request — not a second
  stub, not a sequence — and refuse an input the stub does not know:
  `tests/Support/RiskRegister/ContractWorkbookFixture.php`.
- Provoke a mid-act failure with a collaborator that performs its real write and THEN throws
  (`tests/Support/Engine/FailingBusinessAuditTrail.php`): a double that writes nothing leaves
  nothing to roll back and passes with no transaction.
- A test file may not borrow global helpers from another test file — `php artisan test
  <path>` loads only the named file. Fixtures live in the file or `tests/Support/`.
- Assert a modal through `assertMountedActionModalSeeHtml()` on a `fi-*` class only a
  Filament component emits, never on a utility-class literal: no stylesheet defines one, so
  it passes against markup the panel renders unstyled
  (`tests/Feature/RiskRegister/ConsultRiskRegisterSurfaceTest.php`; rule:
  `architecture-principles.md` → Panel styling).

### Race and commit-order tests

- Two-process race: `Tests\Feature\Tenancy\SecondParty` drives the child. Release it at the
  read whose answer the act writes back, not at the transaction's first statement.
- Catch a lost update on the state machine by racing two moves each of which makes the other
  illegal, then asserting exactly one act was told "applied" — the surviving row proves nothing,
  since either winner leaves a state the table can reach
  (`tests/Feature/Tenancy/DosarTransitionConcurrencyTest.php`).
- Assert the loser's refusal positively, by its domain refusal class and `reasonCode` — never by
  "something was thrown". A racing act that died of a lock timeout or a driver error satisfies a
  count-the-winners assertion in either direction
  (`tests/Feature/Tenancy/DosarIdentityConcurrencyTest.php`).
- An invariant whose advisory key is scoped needs a second case: run the same act in a second
  tenant while the first tenant's act is still mid-transaction and require it to FINISH. A
  single-tenant case cannot see over-serialization
  (`tests/Feature/Tenancy/TenantRosterFloorConcurrencyTest.php`).
- Assert after-commit ordering with a `Log::listen()` listener recording, per line,
  `DB::transactionLevel()` and whether the announced row is already visible; expect the whole
  sequence at level 0 (`tests/Feature/Auth/TenantUsersTest.php`).

## Scope of work

- Implement what the requirement set asks: `docs/stories/as-is/`. No speculative
  abstraction, config flag or future-proofing.
- `RB-`, `US-` and `C-` identifiers cited across code and tests resolve to nothing in the
  active tree.
- Extract duplication after the third occurrence, or when it is semantic rather than
  coincidental.

## Self-check before completing a task

1. Does each new class have one reason to change, and a name needing no "And"?
2. Did every collaborator arrive by constructor — no `app()`, no `new` of infrastructure?
3. Is new state `readonly`, and does a change produce a new value?
4. Did I edit stable code where a new implementation would have done?
5. Did I add anything `docs/stories/as-is/` did not ask for — or a comment that earns no
   place?
6. `declare(strict_types=1);` present, refusal carrying a `reasonCode`, no magic number?
7. Do Pint and PHPStan pass locally (`docs/runbook.md`)?
8. Does a repeated fake key on the request, and does no value depend on an array key's type?
