# Routing defaults

Project documentation overrides everything here. These defaults exist so routing is consistent when the docs are silent.

## Cost posture

Assign the **cheapest tier that can meet the task's acceptance criteria on the first pass**. Routing up "to be safe" burns budget; routing down and failing burns budget *and* wall-clock time on the retry. The acceptance criteria are the routing input — vague criteria make routing a guess, which is a signal to tighten the criteria, not to default to the top tier.

## Model tiers

Use tier names (`haiku` / `sonnet` / `opus`) in plans, never host slugs (`grok-4.5`, `grok-4.6`, a Claude alias). The host adapter below maps those names at DISPATCH. Project docs override the table.

| Tier | Route to it when the task is... | Typical examples |
|---|---|---|
| **haiku** | Mechanical, pattern-following, low ambiguity; success is obvious | Renames, boilerplate, config edits, format conversions, applying a documented convention, running/verifying scripted steps, simple lookups and summaries |
| **sonnet** | Standard skilled work inside known patterns | Feature implementation against a clear spec, writing tests, well-scoped refactors, integrations with documented APIs, docs writing, code review of routine changes |
| **opus** | Ambiguous, cross-cutting, novel, or expensive-to-get-wrong | Architecture and interface design, decomposing vague requirements, root-cause debugging, security-sensitive changes, cross-cutting refactors, anything whose failure invalidates downstream tasks |

Two useful asymmetries:

- **Workflow-route tasks rarely need more than haiku** — determinism already removed the judgment.
- **Tasks on the critical path or with many dependents** justify one tier higher than their content alone suggests: their failure cost includes everyone waiting on them.

## Effort levels

Effort is the task's thinking/verification budget, orthogonal to tier (a haiku task can warrant high effort if verification is fiddly; an opus task exploring options may run medium).

| Effort | Meaning |
|---|---|
| **low** | Single pass, no exploration. Do the thing, check the obvious. |
| **medium** | Some exploration of alternatives, self-review of the output against the acceptance criteria before reporting done. |
| **high** | Extended reasoning: consider multiple approaches, adversarially self-review (what would make this wrong?), verify against every acceptance criterion explicitly. |
| **xhigh** | Extra High on hosts that expose it (Grok 4.6). Same job as high, more reasoning budget. Not a default. Needs a one-line rationale. |

Defaults: haiku→low, sonnet→medium, opus→high. `xhigh` is never a default. Deviations need the one-line rationale in the plan.

## Escalation rule

When a task fails its acceptance criteria:

1. Retry **once** on the same tier with the failure evidence appended to the prompt.
2. If it fails again, escalate **one tier** (and effort to at least medium) and note the escalation in the run manifest. On Grok that also remaps the model (sonnet → opus is 4.5 → 4.6). If the task is already opus / high on 4.6, escalate effort to `xhigh` before surfacing.
3. If it fails on the escalated tier (or `xhigh`), stop and surface to the user — a task failing across two tiers is usually a spec problem, not a capability problem.

Never silently escalate to the top tier on first failure; the manifest must show what escalations actually cost.

## Dispatch host adapter

Plans stay portable. DISPATCH resolves each cell against the **host being called**, not the lead session.

On Grok, cheaper work is a cheaper model: haiku and sonnet → `grok-4.5`; opus → `grok-4.6`. Effort is still `reasoning_effort`. Grok 4.5 has no `xhigh` (low / medium / high only) — clamp `xhigh` → `high` and note it.

| Plan tier | Claude `model` | Grok `model` |
|---|---|---|
| **haiku** | host haiku alias | `grok-4.5` |
| **sonnet** | host sonnet alias | `grok-4.5` |
| **opus** | host opus alias | `grok-4.6` |

| Plan effort | Claude `Workflow.agent()` | Grok 4.6 `agent()` / `parallel()` | Grok 4.5 | Claude `Agent` / Grok `spawn_subagent` if no effort field |
|---|---|---|---|---|
| **low** | `effort: low` | `reasoning_effort: "low"` | same | prompt Effort guidance; `prompt-only` |
| **medium** | `effort: medium` | `reasoning_effort: "medium"` | same | same |
| **high** | `effort: high` | `reasoning_effort: "high"` | same | same |
| **xhigh** | clamp to `high`; note in manifest | `reasoning_effort: "xhigh"` | clamp to `high`; note | prompt says xhigh; `prompt-only` |

- Always pass Grok `reasoning_effort`. grok-4.6's host default is Extra High; omitting the field is a silent upgrade to `xhigh`.
- Always fill the prompt's Effort guidance as well.
- If a call rejects `reasoning_effort` / `effort`, drop the field, keep the prompt line, and mark the forfeit in the manifest.
