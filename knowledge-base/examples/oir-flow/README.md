# Example instantiation — OIR Flow

One worked instantiation of the framework core, kept as reference. **Read-only**: nothing here
is authoritative, nothing here is maintained, and no rule here binds a new project. The
framework is `framework/`; this directory only shows what filling it in looks like.

FI-24 governs how an agent may use this directory: it binds nothing, it is never precedent, no
convention is derived from it, and it is read only when the task names it. Where it disagrees
with a framework rule, the example is stale and the rule wins.

| path | what it demonstrates |
|---|---|
| `project-context/` | all nine context files, filled — the complete resolution of `framework/contracts/project-context.schema.md` |
| `CLAUDE.md` | the index-and-law file rendered from `framework/templates/CLAUDE.md.template` |
| `.claude/agents/`, `.opencode/agents/` | seven bindings per host, rendered from one template against one roster — thin by construction (`framework/contracts/agent-binding.contract.md`) |
| `.claude/plans/` | a plan produced by `task-orchestrator` in PLAN mode |
| `.claude/workflows/` | a deterministic pipeline with evidence gates and per-stage schemas (FI-08) |
| `docs/adr/` | one decision record — the immutable lifecycle |
| `docs/conventions/engineering-principles.md`, `architecture-principles.md` | the two project-owned convention slots the framework mandates but never fills |
| `docs/conventions/*.md` (the four stubs) | how a project points at a framework rule instead of copying it (FI-01) |
| `docs/_intake.md` | the append-only worker channel (FI-02) |

No review report is kept here — the format lives in
`framework/templates/artifacts/review-report.md.template`.

Paths cited inside these files point at the OIR Flow tree (`app/`, `engine/`, `contract/`,
`infra/`, `database/`) and do not resolve here. That is expected: this is an example, not a
project.
