# multi-agent framework

A project-agnostic multi-agent operating system for software work: role charters, framework
rules, generic skills, host adapters, and the templates that instantiate all of it against one
codebase.

- **Start here:** [`framework/README.md`](framework/README.md) — the core ↔ context contract,
  the ownership split, and the six steps to instantiate a project.
- **The law:** [`framework/rules/invariants.md`](framework/rules/invariants.md) — 23 invariants
  that every instantiation must preserve.
- **What varies per project:**
  [`framework/contracts/project-context.schema.md`](framework/contracts/project-context.schema.md)
  — every placeholder the core consumes, and who consumes it.
- **A worked instantiation:** [`examples/oir-flow/`](examples/oir-flow/) — read-only reference.

Validate a checkout or an instantiation with `framework/bin/validate-context.sh`.
