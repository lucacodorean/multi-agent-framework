# Dispatch templates

Three formats: the agent dispatch prompt, the workflow runner, and the run manifest.

## 1. Agent dispatch prompt (agent-route tasks)

One block per task. **Self-contained is the whole point**: the receiving agent has zero context beyond this prompt, so anything it needs — file paths, conventions, doc references — goes in the block. When spawning subagents directly, this is the subagent prompt; when emitting for parallel sessions, this is what the user pastes.

```markdown
## [T4] [Task title]
**Model:** sonnet · **Effort:** medium · **Wave:** 2 · **Depends on:** T1 (done) · **Source:** KEY | —

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

## 2. Workflow runner (workflow-route tasks)

Deterministic tasks execute as a strict checklist — no agent judgment mid-flight. Execute in order; verify each step's expected result before the next.

```markdown
## [T1] [Task title] — workflow
**Executor:** direct (this session) | haiku agent

| # | Step | Command / action | Expected result | On failure |
|---|------|------------------|-----------------|-----------|
| 1 | ...  | `...`            | [checkable]     | stop & report \| retry once \| skip-safe |

Post-conditions: [what must be true after all steps — verified explicitly at the end]
```

If any step's "expected result" can't be stated mechanically, the task was misclassified — stop, re-route it as agent-route, and flag the change in the manifest.

## 3. Run manifest

The live state of a dispatch. Create it when dispatch starts; update it as results land; it is the close-out artifact.

```markdown
# Run manifest: [plan title] — [date]

**Plan:** [path/link to approved plan] · **Wave protocol:** [auto-continue / gated]

| ID | Task | Source | Route | Model | Effort | Status | Result notes |
|----|------|--------|-------|-------|--------|--------|--------------|
| T1 | ...  | KEY \| — | workflow | haiku | low | done | all steps passed |
| T4 | ...  | KEY \| — | agent | sonnet→opus | med→high | done | escalated after 2 failures: [reason] |

**Status values:** pending · dispatched · done · failed · re-routed

## Wave log
- Wave 1 [done]: T1 ✓, T2 ✓, T3 ✓ — [one-line summary]
- Wave 2 [in progress]: T4 dispatched, T5 dispatched

## Deviations
[Escalations, re-routes, discovered out-of-scope work (sent back to PLAN), contract deviations. If none: "None."]
```

The manifest must make cost legible after the fact: every escalation and re-route is visible, so the routing defaults can be tuned from real runs.

**Source** is copied verbatim from the approved plan's Source column and is never re-derived at dispatch time. It is the manifest's only link back to the tracker: without it, a closed-out run cannot be written back to the issues it came from.
