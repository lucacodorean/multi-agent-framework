# Conventions and boundary

| key | value |
|---|---|
| `conventions.code_level` | `docs/conventions/engineering-principles.md` |
| `conventions.structural` | `docs/conventions/architecture-principles.md` |

Both slots exist and are stubs. The framework mandates the slots and never their content; filling
them for this project needs a human instruction naming what belongs in them (FI-20).

## Boundary

The interface this project publishes is not an API — it is the contract between the core and any
project that consumes it.

| key | value |
|---|---|
| `conventions.boundary.interface_paths` | `framework/contracts/` — the project-context contract, the host-adapter contract, the agent-binding contract |
| `conventions.boundary.formats` | Markdown tables: key, shape, consumer |
| `conventions.boundary.error_model` | none — nothing here answers a request at runtime |
| `conventions.boundary.versioning` | **none — a known gap.** The unit carries no version, so a consumer cannot say which core it vendored, and a core change cannot be announced as a version. FI-07 asks interfaces to be versioned; this one is not. Recording it rather than inventing a scheme |

## Enforcement

`conventions.enforcement` — per convention, the mechanism, or `nothing` (FI-22):

| convention | enforced by |
|---|---|
| no project fact in a core file (FI-23) | `validate-context.sh` check 2, on every core file except the host adapters |
| every placeholder documented in the contract | check 1 |
| bindings stay thin and pin no model or effort (FI-09) | check 3 |
| every `framework/` and `project-context/` citation resolves | check 4 |
| no core file depends on a concrete example (FI-24) | check 5 |
| the core stays read-only (FI-25) | check 6 reports the layers; the filesystem lock, the `pre-commit` and `pre-push` hooks and the host `deny` rules enforce them |
| the example read-gate is stated where agents read it (FI-24) | check 6, on the instruction file |
| every extension is indexed (FI-26) | check 7 |
| the anchor resolves to where the unit sits (FI-27) | check 7 |
| one rule, one file (FI-01) | **nothing mechanical.** It holds by review, and it is the rule most often broken by good intentions |
| documentation budgets under `docs.metric` | **nothing** — counted by hand at the doc writer's invocation |
| terse, imperative writing | **nothing** — a matter of review |
