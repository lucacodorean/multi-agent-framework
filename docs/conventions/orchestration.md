# Orchestration model

Canonical depth behind `CLAUDE.md` ch. 5. The six core rules live there; this file holds
the mechanics.

## Operating model

- The lead (interactive session) decomposes each request and routes by ownership; path →
  owner map: `CLAUDE.md` ch. 1–2.
- Route most build work through the roster. The lead builds directly only for trivial
  single-file edits, reading/reporting, or answering questions.
- Single member → `Agent`, `subagent_type` = a `.claude/agents/` roster name
  (contract-owner, domain-engineer, data-engineer, engine-engineer, platform-engineer).
- Multi-member, shape emerging as it goes → named teammates + `SendMessage`, tracked with
  `TaskCreate`/`TaskList`.
- Multi-member, shape known before dispatch → `Workflow`.
- The lead integrates, verifies against the published contract version, and reports; a
  member's report is input to verification, not a substitute for it.
- The docs-agent checkpoint includes `docs/stories/as-is/` (`documentation-governance.md`;
  format in `docs/stories/as-is/README.md`).

## Tiers and direction

```
contract  (contract-owner)      boundary; source of truth
   ↓
domain    (domain-engineer) ──► engine (engine-engineer): provider bounded context
   ↓                            beside the tiers, reached only through
data      (data-engineer)       contract/engine.openapi.yaml
   ↓
platform  (platform-engineer)
```

- Requirements flow downward only. A lower tier never edits a higher tier's files and never
  demands upward change directly.
- Cross-tier work routes through contract-owner as tasks/messages; the routed member answers
  inside its own ownership area. A diff spanning two ownership areas is two tasks
  (`rules-of-engagement.md`).
- A constraint that blocks a higher tier is raised as a task to contract-owner, who
  arbitrates; significant rulings become ADRs.

## Contract-first sequence

1. contract-owner updates `contract/` and lints it (`ddev contract-lint`).
2. contract-owner opens scoped tasks for the affected members, each citing the published
   contract version.
3. Members build to that version. Defects go back as tasks — an implementation never
   diverges from the spec to make it work.

## Deterministic workflows

- `Workflow` is mandatory whenever members, order and gates are known before dispatch;
  hand-sequencing that work with `Agent` + `SendMessage` is a defect.
- The test: were members, order and gates known before dispatch — not task count, not size.
  Three known tasks are a workflow; one task with an unknown follow-up is not.
- `Agent` is the exception, justified only by genuine discovery — each brief depends on what
  the previous one found — and claimed at dispatch: "this is discovery work, so Agent."
- Hybrid is the normal shape: scout with `Agent`, pipeline the known work with `Workflow`.
- Workflow artifacts live under the orchestrating agent's own harness directory (`.claude/`,
  `.grok/` — one per agent name).
- Worktree isolation whenever two members of the same tier mutate files in parallel;
  serialize instead when they would touch the same paths.

Four rules that make a workflow trustworthy:

1. Gate on evidence, never on a stage returning text — require a `LANDED FILES:` block.
2. Confirm plan mode has ended before dispatching agents expected to write; permission mode
   is inherited and not overridable per dispatch.
3. Machine-wide serialization binds the platform suite and the CI gate scripts alike —
   know the constraint before parallelizing stages: `docs/runbook.md` § Test-suite
   discipline and § CI gates.
4. Green by absence: a skipped stage must be distinguishable from a passed one; the script
   is itself the record of what was supposed to run.

## Dispatch mechanics

- Give a single-member `Agent` dispatch a stable `name`; continue it via `SendMessage`
  instead of respawning.
- Stand a named member down explicitly before spawning a replacement — idle is not stood
  down.
- Members run in the background; the lead is notified on completion and relays results.
- Encode timing and resource constraints as task dependencies, never as prose in the
  description.

## Model & effort

Agent definitions pin no model and no effort; resolution is dispatch override → frontmatter
→ inherit from the lead session. The lead assigns per dispatched task.

- Default: inherit.
- Mechanical, well-specified work (version bumps, renames, scripted sweeps) → smaller model
  and/or `effort: low`.
- Contract design, breaking-change review, arbitration, debugging → inherit model, raise
  effort.
- Verification and adversarial stages → inherit model, the highest effort the stage merits.
- Harness mechanics (2026-08-11): `Agent` exposes `model` only; `Workflow`'s `agent()`
  exposes `model` and `effort`. Per-stage effort is reachable only through `Workflow` — a
  reason to prefer it. An `Agent` dispatch that forfeits an intended effort assignment says
  so at dispatch.
- A role consistently warranting a non-default assignment gets it pinned in that member's
  frontmatter.

Version-control discipline binds lead and members alike: `CLAUDE.md` ch. 4 /
`working-agreement.md`.
