# Technology stack

The only place a language, framework or service version is stated. This project has almost no
stack: its product is documentation and shell, read by agents rather than executed by a runtime.

| key | value |
|---|---|
| `stack.languages` | Bash (the scripts under `framework/bin/`), POSIX `sh` (the git hooks, for portability), Markdown (everything else) |
| `stack.frameworks` | none |
| `stack.services` | none — nothing is deployed, nothing is stored |
| `stack.tooling.style` | none |
| `stack.tooling.static_analysis` | `bash -n` / `sh -n` syntax checks; no linter is installed, and nothing lints the scripts beyond that (FI-22) |
| `stack.tooling.test` | `framework/bin/validate-context.sh` — the seven checks are this project's test suite |
| `stack.tooling.contract_lint` | none — the contract is prose, checked by the validator rather than a schema linter |
