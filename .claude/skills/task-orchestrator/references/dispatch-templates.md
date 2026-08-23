# Dispatch templates

Four formats: the agent dispatch prompt, the deterministic task checklist, the pipeline script,
and the run manifest.

A checklist and a pipeline script are not the same thing. A checklist is one task whose steps are
mechanical — no agent judgment mid-flight. A pipeline script is several members whose order and
gates were known before dispatch (`{{kb.root}}/framework/rules/orchestration.md` § Deterministic
pipelines).

## 1. Agent dispatch prompt (agent-route tasks)

One block per task. **Self-contained is the whole point**: the receiving agent has zero context beyond this prompt, so anything it needs — file paths, conventions, doc references — goes in the block. When spawning subagents directly, this is the subagent prompt; when emitting for parallel sessions, this is what the user pastes.

```markdown
## [T4] [Task title]
**Tier:** standard · **Effort:** medium · **Wave:** 2 · **Depends on:** T1 (done) · **Source:** KEY | —

### Context
[Why this task exists, in 2–4 lines. What the project is, what wave 1 produced that this builds on.]

### Inputs
[Exact file paths, branch names, doc sections, prior task outputs. Nothing implied.]

### Deliverables
[The output contract: exactly which files/artifacts, where, in what format.]

### Acceptance criteria
[Checkable statements. The dispatcher will verify these, not re-read your reasoning.]

### Constraints
[Project conventions that bind this task — coding standards, SOLID/GRASP conventions doc, branch/worktree rules, "do not touch X". Reference the governing doc by path.]

### Effort guidance
[Required. Expand the approved effort (low / medium / high / xhigh) into behavior — e.g. medium: "explore at most two approaches, self-review against each acceptance criterion." On hosts with no native effort field this is the only budget the child sees.]

### Report back
When done, report: status (pass/fail per acceptance criterion), files changed, anything discovered that is out of scope (report it — do not do it).
```

## 2. Deterministic task checklist (workflow-route tasks)

Deterministic tasks execute as a strict checklist — no agent judgment mid-flight. Execute in order; verify each step's expected result before the next.

```markdown
## [T1] [Task title] — workflow
**Executor:** direct (this session) | `cheap` agent

| # | Step | Command / action | Expected result | On failure |
|---|------|------------------|-----------------|-----------|
| 1 | ...  | `...`            | [checkable]     | stop & report \| retry once \| skip-safe |

Post-conditions: [what must be true after all steps — verified explicitly at the end]
```

If any step's "expected result" can't be stated mechanically, the task was misclassified — stop, re-route it as agent-route, and flag the change in the manifest.

## 3. Pipeline script (several members, order known before dispatch)

Canonical shape: `{{kb.root}}/framework/templates/workflow-script.js.template`. Read it and fill
it — the shape is not restated here, because one shape in two files is one of them going stale
(FI-01). Emit it only on a host whose adapter names a pipeline primitive
(`{{kb.root}}/framework/hosts/<host>.md` § Dispatch primitives); where none is named, fall back to
waves of agent dispatches and say so in the manifest.

What you fill, and from where:

| in the template | from |
|---|---|
| `run.name`, `run.branch`, `run.description` | the approved plan and the branch this run works on |
| `phase.title`, `phase.detail` | one entry per wave, titles matching the `phase()` calls |
| `task.id`, `task.title`, `task.short`, `task.body`, `task.acceptance` | the task's row and dispatch block |
| `task.tier`, `task.effort`, `task.effort_guidance` | the approved routing — framework tier names, never a host model id (FI-09) |
| `member.name` | the owning member's binding name, from `project-context/ownership.md` |
| `plan.document`, `intake.document` | the paths the plan and the intake document were written to |
| `ruling` | a boundary-owner ruling this run must respect, or drop the line |
| `project.name`, `project.description`, `conventions.code_level`, `docs.worker_channel` | the project's context |

Leaving one of these standing in an emitted script is a failed dispatch, not a placeholder: the
agent reading it has no way to resolve it.

## 4. Run manifest

The live state of a dispatch. Create it when dispatch starts; update it as results land; it is the close-out artifact.

```markdown
# Run manifest: [plan title] — [date]

**Plan:** [path/link to approved plan] · **Wave protocol:** [auto-continue / gated]

| ID | Task | Source | Route | Tier | Effort | Status | Result notes |
|----|------|--------|-------|-------|--------|--------|--------------|
| T1 | ...  | KEY \| — | workflow | cheap | low | done | all steps passed |
| T4 | ...  | KEY \| — | agent | standard→top | med→high | done | escalated after 2 failures: [reason] |

**Status values:** pending · dispatched · done · failed · re-routed

## Wave log
- Wave 1 [done]: T1 ✓, T2 ✓, T3 ✓ — [one-line summary]
- Wave 2 [in progress]: T4 dispatched, T5 dispatched

## Deviations
[Escalations, re-routes, discovered out-of-scope work (sent back to PLAN), contract deviations. If none: "None."]
```

The manifest must make cost legible after the fact: every escalation and re-route is visible, so the routing defaults can be tuned from real runs.

**Source** is copied verbatim from the approved plan's Source column and is never re-derived at dispatch time. It is the manifest's only link back to the tracker: without it, a closed-out run cannot be written back to the issues it came from.
