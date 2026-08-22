# Orchestration Plan: OIRP-21/OIRP-23 review follow-up

## Source

§ = the nine T4 findings from run `wf_dfd18f2d-0e6`, recorded in `.claude/runs/2026-08-21-session-improvements-manifest.md` (table + verbatim-scenario appendix). Predecessor plan: `.claude/plans/2026-08-21-session-improvements-plan.md`.

Step 0 docs: unchanged from the predecessor run — `CLAUDE.md` ch. 1–5, `docs/conventions/orchestration.md`, `documentation-governance.md`.

Human triage approved: **A** (fix the six in-diff findings) + **C** (record the findings in `docs/debt/`), with **D** folded into A — the three drift-hardening findings are fixed rather than backlogged, since each is minutes of work. **B** (the two pre-existing findings, REVIEW-001 and REVIEW-002) is explicitly NOT in this run: it goes through `tracker-intake` and its own PLAN.

## Assumptions & open questions

- **No ADR is authorized.** BL-034's two candidates stay held: the approval said "go ahead with the recommendation", which is not an instruction naming a record, and `documentation-governance.md` § New documentation topics requires the name. `docs/debt/` needs no such naming — the docs-agent definition is standing authorization for a dated review report.
- **REVIEW-006 carries a decision, not just a fix.** Vendor catches its own refusal in `EditRecord::getRedirectUrl()` to choose a post-save destination; our redirect escapes that catch. Landing on the Dashboard after a save by someone who just lost edit rights may be the *better* answer. The member decides and records which, with the vendor call site cited — restoring catchability is not assumed to be correct.
- **REVIEW-001 is not fixed and not planned here.** Filament's `AuthenticateSession` binds a session to the authenticated user's password hash, which would likely defeat the adoption scenario before anything is served. That makes reproduction the first task, not design, and it belongs to B.
- T5's BL-035 row is closed by T7's report; T8 updates it rather than leaving a stale row.

## Tasks

| ID | Task | Source | Route | Model | Effort | Depends on | Wave | Acceptance criteria | Routing rationale |
|----|------|--------|-------|-------|--------|-----------|------|--------------------|-------------------|
| T6 | Fix the three `EndDeactivatedSession` findings | OIRP-21 | agent (domain-engineer) | sonnet | medium | — | 1 | REVIEW-003: the ended session no longer carries `BindSessionToTenant::TENANT_ID_KEY`, proven by a test where a human deactivated in tenant A then authenticates in tenant B in the same session and is NOT refused by ADR-0045's 403. REVIEW-008: repeated interceptions do not stack toasts — one notice on the login page however many requests were intercepted. REVIEW-009: a forced termination is journalled through `app/Auth/SecurityEventLog.php` with a distinct event name, asserted by a test, and the entry names no secret. The notification still renders after the redirect (predecessor criterion 2 stays green). Pint + phpstan clean, full suite green. `docs/_intake.md` entry | Three small, well-specified changes to one file plus its test and the journal — standard work in a known pattern |
| T7 | Write the review report to `docs/debt/` | — | agent (docs-agent) | sonnet | medium | — | 1 | `docs/debt/2026-08-21-session-improvements.md` exists, named per governance, holding all nine findings with severity, scope (in-diff vs pre-existing), file:line and scenario, plus the five-surface disclosure sweep. Every claim carried over verbatim from the manifest appendix — the report is a dated snapshot, so nothing is re-judged or silently corrected. BL-035 updated to point at it. No ADR written | Docs writing against a recorded source; `docs/debt/` is standing-authorized, so no naming instruction is needed |
| T8 | Fix the three `app/Filament/Concerns/**` findings | OIRP-23 | agent (domain-engineer) | sonnet | medium | T6 | 2 | REVIEW-004: the redirect never targets the request's own page — guarded explicitly, not by accident of `Dashboard::canAccess()`, with a test that would fail if the guard were removed. REVIEW-005: the architecture test asserts, per page class and per gate the vendor exposes, that the RESOLVED method is the app trait's — trait presence is no longer what it checks. REVIEW-006: decided and recorded in the docblock, with the vendor call site cited and a test pinning whichever answer was chosen. Pint + phpstan clean, full suite green. `docs/_intake.md` entry | Same member, same shape as T6; medium effort because REVIEW-005 is a test-strength change and REVIEW-006 is a judgment call |
| T9 | Narrow re-review of the six fixed findings | OIRP-21, OIRP-23 | agent (code-reviewer) | opus | high | T6, T8 | 3 | Reviews ONLY the T6/T8 diff against the six findings, one verdict each: fixed / not fixed / fixed-with-new-problem. Re-checks that the predecessor run's invariants still hold — every 403 the first run marked keep still refuses, and no guest-reachable response changed. Does NOT re-review the whole feature and does NOT re-litigate REVIEW-001/002 | Adversarial verification of security-surface fixes, scoped tightly so the cost is a fraction of the first review |

## Waves

- **Wave 1** (parallel: 2): T6, T7 — different members, disjoint paths (`app/**` vs `docs/**`), so genuinely parallel
- **Wave 2** (parallel: 1): T8 — blocked on T6 (same member)
- **Wave 3** (parallel: 1): T9 — blocked on T6, T8

**Critical path: T6 → T8 → T9.** T7 is free wall-clock beside T6.

## Risks & escalation

- **REVIEW-005 is the criterion most likely to fail quietly.** A test that asserts resolved methods can itself be written to pass trivially. T9 checks the test, not just the code.
- **T6's REVIEW-003 fix must not break the notification.** Forgetting the tenant key and carrying the flash both ride on the same session; the predecessor's criterion 2 is re-asserted for that reason.
- **Nothing here touches REVIEW-001/002.** A stage that starts fixing them has left the plan and stops.
- No commit, no push.

## Approval

Dispatched on the human's "go ahead with the recommendation" for A + C + D. B is opened separately as intake. No ADR is written.
