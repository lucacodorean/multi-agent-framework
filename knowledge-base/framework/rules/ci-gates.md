# CI gates

Framework rule. Project values: `project-context/ci.md`.

## One script layer

- Every gate is a script in `{{ci.script_dir}}`, running identically on a developer machine and
  on the CI host. Gate logic never lives in CI configuration; a host configuration file is a
  thin wrapper over the script and nothing else.
- A gate needs the project's container runtime and nothing else. Tools resolved on the host
  behave differently per machine: `{{ci.forbidden_host_tools[]}}` are forbidden by name, each
  gate stating in its own header what it refuses.
- Gate tools are the project's own pinned dependencies, never a global or host binary.
- Host-agnostic is not reproducible. Where a gate's findings depend on a bundled ruleset, pin
  the image by digest and say so.

## Rules that make a gate mean something

- No gate filters by changed path. A gate that passes by absence is a defect.
- A skipped step is a named skip, never a silent one (FI-08).
- No gate starts, stops or deploys a runtime. Starting a runtime is an operator action.
- A gate asserting that two declarations agree asserts it in both directions; one direction
  alone passes trivially when a key is lost from the source.
- Gates that run containers under constant names take an exclusive host lock (`{{ci.lock}}`)
  and are never parallelized on one machine. Constant container names make concurrent runs
  destroy each other.
- A gate is a script too: state whether anything lints them, and if nothing does, say so
  (FI-22).

## The set

`{{ci.gates[]}}`, each with what it proves and its command. Local reproduction is the same
script; the CI host wiring is `{{ci.host_doc}}`.
