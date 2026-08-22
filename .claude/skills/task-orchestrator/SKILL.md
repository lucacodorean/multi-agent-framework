---
name: task-orchestrator
description: Plan and dispatch AI-agent work. Given any input § (a goal, spec, blueprint, RFP section, feature request, bug list, or document), break it down into discrete tasks with an assigned model tier and effort level per task, and present the plan for approval. Given an approved task list, dispatch it — deterministic steps run as a strict workflow, open-ended tasks go to agent teams / subagents — always respecting the orchestration model defined in the project's own documentation. Use this skill whenever the user asks to break work down into tasks, plan work for agents, assign models or effort, dispatch or execute a task list, orchestrate a delivery, or pastes a plan and says "run this" — even if they don't use the word "orchestrate".
---

# Task Orchestrator

Turn unstructured intent into a routed, approvable task plan (PLAN mode), and turn an approved task plan into executed work (DISPATCH mode). The unit of currency throughout is the **task**: independently dispatchable, with its own inputs, output contract, acceptance criteria, model tier, and effort level.

## Mode detection

- Input is a goal, spec, document, or otherwise unstructured intent → **PLAN**
- Input is an already-structured task list, or an approved plan from earlier in this conversation → **DISPATCH**
- An explicit user instruction always wins over detection.
- "§" (or similar placeholder) marks the payload: treat the pasted/attached content that accompanies it as the input, not the surrounding instruction.

Never run both modes in one uninterrupted pass. PLAN always ends at an approval gate; DISPATCH only starts from an approved plan.

## Step 0 — Read the orchestration docs (both modes, always first)

The project's own rules are the authority on *how* orchestration works; this skill's defaults apply only where they are silent. Before planning or dispatching, look for and read:

- `knowledge-base/framework/rules/orchestration.md` and `knowledge-base/framework/rules/invariants.md` — the framework rules
- `project-context/roster.md`, `project-context/commands.md`, `project-context/ci.md` — who owns what, how work is verified, what serializes
- `knowledge-base/framework/hosts/<host>.md` — the dispatch primitives, model map and effort map of the host being called
- the repository's index-and-law file (`CLAUDE.md`, `AGENTS.md`) and any file the user points at as "the orchestration model"

Those rules may override any default in this skill: model routing, effort taxonomy, parallelism limits, wave protocol, agent roles, handoff and report formats, branch or working-copy conventions, and whether waves auto-continue or gate on the user. When a project rule and a skill default conflict, the project rule wins — note the override in the plan so the user can see it was honored.

If no project rules are reachable (e.g., pure chat context without a repo), say so in one line and proceed with the defaults below.

## PLAN mode

Given §, produce a plan the user can approve, edit, or reject.

1. **Clarify only if blocking.** At most one round of questions, and only for ambiguities that would change the task breakdown itself. Reasonable assumptions go in the plan's "Assumptions" section instead — the approval gate exists precisely so the user can correct them cheaply.

2. **Decompose into tasks.** Each task must be:
    - Independently dispatchable — a fresh agent with only the task prompt can complete it
    - Contract-shaped — explicit inputs, deliverables, and acceptance criteria
    - Sized to one focused agent session — not so large it needs mid-flight re-planning, not so small the dispatch overhead exceeds the work. Merge trivial siblings; split anything with an "and then" in its acceptance criteria.

3. **Classify the route per task:**
    - **workflow** — deterministic: the steps are enumerable up front and success is mechanically checkable (file transforms, scripted builds, migrations, renames, format conversions, config changes)
    - **agent** — requires judgment: design, implementation choices, debugging, writing, anything where two competent runs could legitimately differ

4. **Assign model and effort per task** using the routing defaults in `references/routing-defaults.md` (read it before assigning), as overridden by project docs. Every assignment carries a one-line rationale — the user is approving the routing economics, not just the task list.

5. **Build dependency waves.** Group tasks into waves where everything inside a wave can run in parallel. Respect the parallelism limit from the docs (default: 6 concurrent agents). Keep the critical path visible.

6. **Emit the plan** using `references/plan-template.md`. Write it as a markdown artifact/file when in a file-capable environment (it becomes the run's source of truth), inline otherwise.

7. **Stop at the approval gate.** Present the plan and ask for approval or edits. Do not dispatch, pre-dispatch, or "get a head start" in the same turn. On edit requests, revise the plan and return to the gate.

## DISPATCH mode

Given an approved task list, execute it.

**Precondition check:** If the list arrives without route/model/effort assignments (e.g., pasted from elsewhere), fill the gaps using the PLAN assignment rules, mark every filled cell as `(inferred)`, and show the completed table for a quick confirm before dispatching — the user must never discover routing decisions after the fact.

1. **Re-read the orchestration docs** (Step 0). Dispatch mechanics — wave gating, report formats, worktree/branch conventions — come from there first.

2. **Route each task:**
    - **workflow route (deterministic):** Execute the steps exactly, in order, verifying the expected result after each step (see the workflow runner template in `references/dispatch-templates.md`). No improvisation: if a "deterministic" task turns out to need judgment mid-flight, stop it, re-classify it as agent-route, and flag the change rather than silently winging it.
    - **agent route:** Dispatch to agents with the task's assigned model and effort, resolved through `references/routing-defaults.md` → **Dispatch host adapter**. Spawn per wave, one agent per task, respecting the parallelism limit and any role model from the docs. Always expand Effort guidance in the prompt. If the host rejects the native field, mark the forfeit in the manifest. If no subagent tooling exists, emit **dispatch-ready prompt blocks** from `references/dispatch-templates.md`.

3. **Maintain the run manifest** (template in `references/dispatch-templates.md`): per-task status (`pending / dispatched / done / failed / re-routed`), updated as results land. In a file-capable environment, keep it as a file next to the plan.

4. **Wave protocol.** Default: waves auto-continue within the approved plan, with a short report at each wave boundary. Stop and return to the user when:
    - a task fails its acceptance criteria after one escalation (see routing defaults),
    - an output deviates from its contract, or
    - new work is discovered that isn't in the approved plan — scope changes go back through PLAN, never get quietly absorbed.
      Project docs may change this default (e.g., gate on the user at every wave).

5. **Close out** with a final manifest: what ran where, on which model/effort, what passed, what was escalated or re-routed, and any residual work.

## Reference files

- `references/routing-defaults.md` — model tiers, effort, dispatch host adapter (Claude vs Grok), escalation. Read before assigning or filling routing.
- `references/plan-template.md` — the exact plan output format. Read before emitting a plan.
- `references/dispatch-templates.md` — agent dispatch prompt, workflow runner, run manifest formats. Read before dispatching.
