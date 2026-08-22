# Routing defaults

Project documentation overrides everything here. These defaults exist so routing is consistent when the docs are silent.

## Cost posture

Assign the **cheapest tier that can meet the task's acceptance criteria on the first pass**. Routing up "to be safe" burns budget; routing down and failing burns budget *and* wall-clock time on the retry. The acceptance criteria are the routing input — vague criteria make routing a guess, which is a signal to tighten the criteria, not to default to the top tier.

## Model tiers

Use framework tier names (`cheap` / `standard` / `top`) in plans, never host model identifiers.
The host adapter maps them at DISPATCH (`framework/hosts/<host>.md` § Model map). Project rules
override the table.

| Tier | Route to it when the task is... | Typical examples |
|---|---|---|
| **cheap** | Mechanical, pattern-following, low ambiguity; success is obvious | Renames, boilerplate, config edits, format conversions, applying a documented convention, running/verifying scripted steps, simple lookups and summaries |
| **standard** | Standard skilled work inside known patterns | Feature implementation against a clear spec, writing tests, well-scoped refactors, integrations with documented APIs, docs writing, code review of routine changes |
| **top** | Ambiguous, cross-cutting, novel, or expensive-to-get-wrong | Architecture and interface design, decomposing vague requirements, root-cause debugging, security-sensitive changes, cross-cutting refactors, anything whose failure invalidates downstream tasks |

Two useful asymmetries:

- **Workflow-route tasks rarely need more than `cheap`** — determinism already removed the judgment.
- **Tasks on the critical path or with many dependents** justify one tier higher than their content alone suggests: their failure cost includes everyone waiting on them.

## Effort levels

Effort is the task's thinking/verification budget, orthogonal to tier (a `cheap` task can warrant high effort if verification is fiddly; a `top` task exploring options may run medium).

| Effort | Meaning |
|---|---|
| **low** | Single pass, no exploration. Do the thing, check the obvious. |
| **medium** | Some exploration of alternatives, self-review of the output against the acceptance criteria before reporting done. |
| **high** | Extended reasoning: consider multiple approaches, adversarially self-review (what would make this wrong?), verify against every acceptance criterion explicitly. |
| **xhigh** | Same job as high, more reasoning budget, on hosts that expose it (`framework/hosts/<host>.md` § Effort map). Not a default. Needs a one-line rationale. |

Defaults: `cheap`→low, `standard`→medium, `top`→high. `xhigh` is never a default. Deviations need the one-line rationale in the plan.

## Escalation rule

When a task fails its acceptance criteria:

1. Retry **once** on the same tier with the failure evidence appended to the prompt.
2. If it fails again, escalate **one tier** (and effort to at least medium) and note the escalation in the run manifest. If the task is already `top` / high, escalate effort to `xhigh` where the host exposes it before surfacing.
3. If it fails on the escalated tier (or `xhigh`), stop and surface to the user — a task failing across two tiers is usually a spec problem, not a capability problem.

Never silently escalate to the top tier on first failure; the manifest must show what escalations actually cost.

## Dispatch host adapter

Plans stay portable: they carry framework tier and effort names only. DISPATCH resolves each
cell against the **host being called**, not the lead session, through that host's adapter:

- `framework/hosts/<host>.md` § Model map — tier → host model identifier.
- `framework/hosts/<host>.md` § Effort map — effort → host field, and how `xhigh` clamps.
- `framework/hosts/<host>.md` § Capability gaps — what the host cannot express.

Rules that hold on every host:

- Always pass the host's effort field where one exists; omitting it can silently select the
  host's own default, which may be higher than the plan approved.
- Always fill the prompt's Effort guidance as well — on a host with no effort field it is the
  only budget the child sees.
- If a call rejects the effort field, drop the field, keep the prompt line, and mark the
  forfeit in the manifest.
- A host identifier never appears in a plan, a manifest or a dispatch prompt: only in an
  adapter.
