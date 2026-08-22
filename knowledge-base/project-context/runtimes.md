# Runtimes

Rules: `framework/rules/runtime-topology.md`.

**None.** This project has no runtime: the unit is read by agents, not executed. There is
nothing to boot, nothing to pin, and no topology to verify by full boot.

| id | doc | boot | verify |
|---|---|---|---|
| — | — | — | — |

- `runtimes.shared_inputs_dir`: none
- `runtimes.generated_dirs`: `.claude/agents/`, `.opencode/agents/` — rendered from
  `framework/templates/agent-binding.md.template` against `framework/roster.md`. Never hand-edit
  one copy; regenerate both, or the hosts drift (FI-26 note in
  `framework/contracts/agent-binding.contract.md`).

A consuming project fills this file with its own runtimes; the framework's own emptiness here is
a property of the framework, not a template default.
