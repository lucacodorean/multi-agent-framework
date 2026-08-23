# Commands

Contract: `framework/contracts/project-context.schema.md` § commands.md. Keys are fixed; values
are the project's. Mark any value not verified by execution as UNVERIFIED.

| key | command |
|---|---|
| `commands.runner_prefix` | <how a command reaches the execution environment; empty if bare> |
| `commands.dependency_install` | <install declared dependencies> |
| `commands.env_up` | <bring the default runtime up, or `none`> |
| `commands.env_full_boot` | <the full-boot verification a topology change requires, or `none`> |
| `commands.test` | <run the whole suite> |
| `commands.test_narrow` | <run one target> |
| `commands.style_check` | <or `none`> |
| `commands.static_analysis` | <or `none`> |
| `commands.contract_lint` | <or `none`> |
| `commands.db_shell` | <or `none`> |
| `commands.cache_shell` | <or `none`> |

## Destructive — explicit user-approved task required

`commands.destructive`:

- <operation>
