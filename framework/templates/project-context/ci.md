# CI

Contract: `framework/contracts/project-context.schema.md` § ci.md. Rules:
`framework/rules/ci-gates.md`.

| key | value |
|---|---|
| `ci.host_doc` | <doc describing the live CI host> |
| `ci.script_dir` | <the one script layer> |
| `ci.lock` | <host-lock mechanism, or `none`> |
| `ci.forbidden_host_tools` | <tools a gate must never resolve on the host> |

## Gates

| name | proves | command | serialized |
|---|---|---|---|
| <name> | <what it proves> | <command> | yes/no |
