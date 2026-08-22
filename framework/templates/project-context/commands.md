# Commands

Contract: `framework/contracts/project-context.schema.md` § commands.md. Keys are fixed; values
are the project's. Mark any value not verified by execution as UNVERIFIED.

| key | command |
|---|---|
| `commands.runner_prefix` | <how a command reaches the execution environment; empty if bare> |
| `commands.dependency_install` | |
| `commands.env_up` | |
| `commands.env_full_boot` | |
| `commands.test` | |
| `commands.test_narrow` | |
| `commands.style_check` | |
| `commands.static_analysis` | |
| `commands.contract_lint` | |
| `commands.db_shell` | |
| `commands.cache_shell` | |

## Destructive — explicit user-approved task required

`commands.destructive`:

- <operation>
