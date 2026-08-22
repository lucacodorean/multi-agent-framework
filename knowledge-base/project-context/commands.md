# Commands

Keys are fixed; values are this project's. Verified by execution 2026-08-22 unless marked
UNVERIFIED. Paths are knowledge-base-relative (FI-27); run them from the repository root with
the `knowledge-base/` prefix.

| key | command |
|---|---|
| `commands.runner_prefix` | none — commands run on the host; there is no container |
| `commands.dependency_install` | none — the unit has no dependencies. The opencode harness carries its own (`npm install --prefix .opencode`, UNVERIFIED) |
| `commands.env_up` | none — nothing to start |
| `commands.env_full_boot` | none — there is no runtime to boot |
| `commands.test` | `knowledge-base/framework/bin/validate-context.sh` |
| `commands.test_narrow` | `knowledge-base/framework/bin/validate-context.sh <context-dir>` |
| `commands.style_check` | none |
| `commands.static_analysis` | `bash -n knowledge-base/framework/bin/*.sh` and `sh -n knowledge-base/framework/bin/githooks/*` |
| `commands.contract_lint` | none |
| `commands.db_shell` | none |
| `commands.cache_shell` | none |

## Core protection

Not verification commands — the enforcement layers of FI-25. State:
`knowledge-base/framework/bin/lock-core.sh` (`status` / `lock` / `unlock`).

## Destructive — explicit user-approved task required

`commands.destructive`:

- Unlocking the core and editing `framework/**`. A human act: `lock-core.sh unlock` lifts the
  filesystem bit, and the host `deny` rule still refuses the write, by design.
- `git push` — refused by the pre-push hook unless `FRAMEWORK_PUBLISH=1` says the release of a
  core change is intended.
- Rewriting history on a branch that has been pushed.
- Deleting anything under `docs/` or `project-context/`: both are sole records of work, not
  regenerable artifacts.
