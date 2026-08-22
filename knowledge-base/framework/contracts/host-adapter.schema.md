# Host-adapter contract

One adapter per agent harness in `framework/hosts/`. An adapter states how that harness spells
the framework's concepts — nothing else. Capability claims carry the date they were verified.

Required sections:

| section | states |
|---|---|
| `## Mount points` | where the harness discovers agent definitions and skills |
| `## Binding frontmatter` | the frontmatter keys a binding needs, and their vocabulary (tool allowlists, permission maps, mode fields) |
| `## Dispatch primitives` | how a single agent, a named teammate, a deterministic pipeline and a task list are invoked |
| `## Model map` | framework tier (`cheap` / `standard` / `top`) → harness model identifier |
| `## Effort map` | framework effort (`low` / `medium` / `high` / `xhigh`) → harness field, plus clamping |
| `## Capability gaps` | what the harness cannot express, each with a verification date |
| `## Import syntax` | how a definition auto-loads another file, or `none` |
| `## File I/O` | where user-supplied input files arrive, or `none` |

Rules:

- The framework never names a harness outside `framework/hosts/**` and the bindings.
- Tier names in plans are always framework names; a harness model identifier appears only in
  a `## Model map`.
- A gap is a dated fact, not a permanent truth. Re-verify before relying on it.
- An adapter grants no permission posture. Whether an agent runs unattended is a project and
  operator decision, recorded with the project, never inherited from the framework.
