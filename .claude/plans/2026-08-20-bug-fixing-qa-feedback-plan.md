# Orchestration Plan: QA feedback on branch `bug-fixing`

## Source

§ = `docs/tracker/2026-08-20-bug-fixing-qa-feedback-intake.md` (4 ready items: OIRP-19, OIRP-24, OIRP-33, OIRP-34), produced by `tracker-intake` from `prompts/2026-08-20-bug-fixing-based-on-qa-feedback.md`.

Step 0 docs read: `CLAUDE.md` ch. 1–5, `docs/conventions/orchestration.md`, `rules-of-engagement.md`, `working-agreement.md`, `documentation-governance.md`, `docs/runbook.md` § Test-suite discipline.

Doc rules that override skill defaults:

- **`Workflow` is mandatory here**, not `Agent` + `SendMessage`: members, order and gates are all known before dispatch (`orchestration.md` § Deterministic workflows). It is also the only route that carries per-stage `effort` — an `Agent` dispatch would forfeit every effort cell in the table below.
- **Same-path serialization over parallelism.** T2, T3 and T4 all mutate `app/Filament/Auth/Pages/ChoosePassword.php`, so they run in sequence; worktree isolation applies only where same-tier members write disjoint paths in parallel (`orchestration.md` § Deterministic workflows).
- **Workers never write `.md`**; each implementing stage ends by appending a doc-impact entry to `docs/_intake.md`, and one docs-agent checkpoint drains it (`documentation-governance.md`).
- **No commits, no pushes** (`CLAUDE.md` ch. 4). Every stage leaves its work in the tree.
- Plan artifacts live under `.claude/` — this file (`orchestration.md` § Deterministic workflows).

## Assumptions & open questions

Resolved by the human, and load-bearing for the breakdown:

- **Two pages, split on what the URL already reveals** (OIRP-24, OIRP-33's second note). `expires` is a plain query parameter on the signed link (`UrlGenerator.php:373`, `:504-512`), so its holder can compute expiry offline and a dedicated expiry message discloses nothing. Account state cannot be computed offline, so it stays collapsed:
  - **Page A — expired.** Valid signature, `expires` passed. 403 with a Romanian expiry message, decided before any `users` lookup.
  - **Page B — unavailable.** Unknown account, inactive account, already-used link, session authenticated as a different account. 404, one constant body, cause never disclosed. This is the enumeration-critical surface: those four causes must be indistinguishable from each other.
  - Invalid/tampered signature keeps today's stock 403 and is untouched — it never reaches the page, so it leaks nothing (`FirstLoginTest.php:100-105` stays green).
- **Rule extraction reaches both pages** (OIRP-34): the new `App\Rules` class is wired into `ResetPassword` (the gap § names) *and* `ChoosePassword`, replacing its inline closure.
- **The ADR decision is stood down.** `ADR-0036` and `ADR-0037` are not created in this run and approving this plan authorizes no doc-tree file. The rulings behind Page A/Page B and behind activation-link invalidation are recorded only as `docs/_intake.md` entries until that conversation happens; T6 is held for it.

Assumptions made instead of asking:

- **OIRP-33's "Actual results" is factually wrong and the plan builds the Expected result anyway.** The activation URL carries `{tenant}` + user id only (`TenantUserActivation.php:35-42`), so today an email change leaves the old link *valid* for the rest of its 7 days rather than invalidating it. T3 therefore implements link invalidation as new work, not as a regression fix, and closes a live exposure the ticket did not know it had.
- **Mechanism for T3 is the member's call**, but the obvious precedent is `TenantPasswordReset::marker()` (`app/Auth/TenantPasswordReset.php:45-63`) — a signed query parameter derived from state that an email change moves.
- **OIRP-34 note3 is already satisfied** (`lang/ro/validation.php:104,117-119,231`; `APP_LOCALE=ro`), so it is folded into T4 as a verification criterion rather than a task of its own.
- **The sibling closure-options selects are out of scope.** `DosarResource.php:152` and `TenantResource.php:342` carry OIRP-19's exact pattern over enum constants, but § says "Refer only to the changes requested". Flagged, not fixed.
- The OIRP-25 behaviour already shipped on the *reset* route (`ValidatePasswordResetSignature`, its specific expiry message) is a different route and stays untouched.

Open, non-blocking:

- `lang/**` appears in no row of the `CLAUDE.md` ch. 2 roster, which claims every path maps to exactly one owner. No stage in this plan writes it, so it does not block — worth an intake entry for the docs checkpoint.

## Tasks

| ID | Task | Source | Route | Model | Effort | Depends on | Wave | Acceptance criteria | Routing rationale |
|----|------|--------|-------|-------|--------|-----------|------|--------------------|-------------------|
| T1 | Make the „Rol" select open without a Livewire round trip | OIRP-19 | agent (domain-engineer) | sonnet | low | — | 1 | `Select::make('role')` receives a plain array, not a Closure; `->preload()` gone; a Pest test asserts the role component's `hasDynamicOptions()` is `false`; the `unique` message is retained and reads „Adresa de autentificare trebuie să fie unică."; pint + phpstan clean | Diff is fully specified in the intake; low effort. sonnet not haiku because the repo enforces comment discipline, strict types and phpstan on first pass |
| T2 | Two refusal pages on the password-set route: expired, and a collapsed everything-else | OIRP-24 | agent (domain-engineer) | opus | high | — | 1 | Expired signature renders Page A (403, Romanian expiry message) without querying `users`; unknown account, inactive account, already-used link and wrong-session all render Page B (404) byte-identical to each other; invalid signature keeps its stock 403; the middleware follows `ValidatePasswordResetSignature`'s two-step shape (`hasCorrectSignature` → `signatureHasNotExpired`); `FirstLoginTest.php:107-115` and `TenantUserActivationTest.php:192-208` re-pointed at Page A, `FirstLoginTest.php:117-127` and `TenantUserActivationTest.php:175-190` at Page B; reset route (OIRP-25) unchanged; pint + phpstan clean | Security-sensitive: the Page B collapse across four causes is the invariant, and a fix that satisfies the page but not the middleware looks green while still leaking |
| T3 | Re-issue the activation link on email change and invalidate the old one | OIRP-33 | agent (domain-engineer) | opus | high | T2 | 2 | `TenantUsers::update()` issues a fresh link to the new address when the account still has `password_set_at` NULL and the address changed; the pre-change link no longer sets a password; the spent link renders T2's constant page; no re-issue when the address is unchanged or the password is already set; pint + phpstan clean | Auth-surface change that mints and revokes credentials-bearing URLs; the ticket's stated premise is wrong, so the member must build from the corrected model, not the report |
| T4 | Extract "must differ from current password" into `App\Rules` and wire both pages | OIRP-34 | agent (domain-engineer) | sonnet | medium | T3 | 3 | New rule class under `App\Rules`; used by `ResetPassword` and by `ChoosePassword` in place of its inline closure; a reset submitted with the current password is rejected with exactly „Parola nouă trebuie să fie diferită de parola actuală."; existing ChoosePassword coverage re-pointed and still green; a failing `min`/`letters`/`mixedCase`/`numbers` renders Romanian on both pages; pint + phpstan clean | Extraction against a fixed spec and a fixed message — standard work in a known pattern; medium effort because it touches a page with existing coverage |
| T5 | Adversarial review of the auth changes | OIRP-24, OIRP-33, OIRP-34 | agent (code-reviewer) | opus | high | T1, T2, T3, T4 | 4 | Reviews the full working-tree diff; reports findings as tracker-intake bug items; explicitly answers whether Page B's four causes are distinguishable by body, status, headers or timing, and whether any link revoked by T3 remains usable | Adversarial stage on credential-bearing surfaces — `orchestration.md` § Model & effort puts verification at the highest effort the stage merits |
| T6 | **HELD — not dispatched in this run.** Docs checkpoint: drain intake, record whatever the ADR conversation rules | — | agent (docs-agent) | sonnet | medium | T5, ADR decision | — | Deferred pending the ADR discussion. Scope on resumption: drain and truncate `docs/_intake.md`, update `docs/stories/as-is/`, and write only the ADRs that conversation authorizes by name | Docs writing against verified sources — sonnet/medium per the routing table; docs-agent is the sole doc writer |

## Waves

- **Wave 1** (parallel: 2): T1, T2 — disjoint paths, so both run under worktree isolation per `orchestration.md`
- **Wave 2** (parallel: 1): T3 — blocked on T2 (same file, and it must inherit T2's refusal surface)
- **Wave 3** (parallel: 1): T4 — blocked on T3 (same file)
- **Wave 4** (parallel: 1): T5 — blocked on T1–T4
- T6 is **held** outside the run, pending the ADR conversation.

**Critical path: T2 → T3 → T4 → T5.** T1 is free wall-clock beside T2. The depth is forced by three items landing in `ChoosePassword.php`; nothing in the plan shortens it without risking a lost edit.

The run therefore ends with `docs/_intake.md` holding unmerged entries from T1–T4. That is the expected end state, not an incomplete run — workers are required to file there and forbidden to write anything else (`documentation-governance.md`), and those entries are the verified source material the ADR discussion will draw on.

Note on verification: `tests/Pest.php` holds a machine-wide PostgreSQL advisory lock, so concurrent suite runs queue rather than collide (`docs/runbook.md:80-88`). Wave 1's two stages are safe; they will simply serialize at the test step.

## Risks & escalation

- **T2 is the task most likely to need a second pass, and the one whose failure is worst.** The split makes the easy half easier and leaves the hard half unchanged: Page A has a working precedent to copy, but Page B still has to collapse four causes that arise in two different places — the `signed` middleware and the page's own guards. A fix that renders Page B from the page and lets the middleware answer differently looks green and still leaks. T5 exists largely to catch that. Standard escalation: one retry on opus/high with the failure evidence, then surface — there is no tier above it.
- **T3 depends on T2's surface existing.** If T2 is re-routed or rejected at review, T3's "spent link renders Page B" criterion has nothing to point at; T3 then blocks and returns to PLAN rather than inventing a surface.
- **T5 may generate new work.** Findings that are not in this plan go back through PLAN as a fresh intake — `orchestration.md` and the DISPATCH protocol both refuse silent scope absorption.
- **T1 carries no cross-task risk.** Worst case is a wasted sonnet run on a specified diff.
- Nothing here commits or pushes; a bad wave is recovered with `git checkout`.

## Approval

Approving this plan authorizes a **single `Workflow` run** dispatching **T1–T5** on the listed models and effort levels, wave by wave, auto-continuing between waves with a short report at each boundary, and stopping early on any of the three conditions above.

It authorizes **no documentation work**: T6 is held, no ADR is created, and no `.md` outside `docs/_intake.md` is written by any stage.

No commit and no push will be made. Reply with edits, or approve to dispatch.
