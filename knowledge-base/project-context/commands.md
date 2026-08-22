> **UNFILLED STUB.** Every `<…>` below must be supplied before this context is usable. Keys,
> shapes and consumers: `framework/contracts/project-context.schema.md` § commands.md. Blank form:
> `framework/templates/project-context/commands.md`.

# Commands

Keys are fixed; values are the project's. Mark anything not verified by execution as UNVERIFIED,
with the date it was last run.

| key | command |
|---|---|
| `commands.runner_prefix` | <how a command reaches the execution environment; empty if bare> |
| `commands.dependency_install` | <> |
| `commands.env_up` | <> |
| `commands.env_full_boot` | <the full-boot verification a topology change requires> |
| `commands.test` | <> |
| `commands.test_narrow` | <> |
| `commands.style_check` | <or `none`> |
| `commands.static_analysis` | <or `none`> |
| `commands.contract_lint` | <or `none`> |
| `commands.db_shell` | <or `none`> |
| `commands.cache_shell` | <or `none`> |

## Destructive — explicit user-approved task required

`commands.destructive`:

- <operation>
