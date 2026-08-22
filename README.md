# multi-agent framework

A project-agnostic multi-agent operating system for software work: role charters, framework
rules, generic skills, host adapters, and the templates that instantiate all of it against one
codebase. It ships as one vendorable directory.

- **The unit:** [`knowledge-base/`](knowledge-base/) — copy it into a host repository, keep the
  name, update it whole. Start at its
  [README](knowledge-base/README.md).
- **The law:**
  [`knowledge-base/framework/rules/invariants.md`](knowledge-base/framework/rules/invariants.md)
  — the invariants every instantiation preserves.
- **What varies per project:**
  [`knowledge-base/framework/contracts/project-context.schema.md`](knowledge-base/framework/contracts/project-context.schema.md)
  — every placeholder the core consumes, and who consumes it.
- **The project's knowledge:** [`knowledge-base/docs/`](knowledge-base/docs/) — conventions,
  decision records, tracker intake, review reports and stories.
- **The instantiation:** [`knowledge-base/project-context/`](knowledge-base/project-context/) —
  nine files resolving every placeholder the core consumes. Stubs today: fill them and the
  framework governs the project.

The core is read-only by design: `knowledge-base/framework/bin/lock-core.sh` installs and
reports the enforcement. Validate a checkout with
`knowledge-base/framework/bin/validate-context.sh`.
