# Documentation policy

Contract: `framework/contracts/project-context.schema.md` § docs-policy.md. Rules:
`framework/rules/documentation-governance.md`, `framework/rules/doc-artifact-registry.md`.

| key | value |
|---|---|
| `docs.sole_writer` | <member name> |
| `docs.role_gate_line` | <exact line granting the role> |
| `docs.worker_channel` | <append-only intake file> |
| `docs.metric` | <token metric and how it is counted> |
| `docs.archive_dir` | <where compaction moves removed content> |
| `docs.budget_grace` | <tokens a file may exceed its budget by before it is a finding; `0` for none> |

## Allowed write paths — canonical, one copy

`docs.write_paths`:

| path | budget |
|---|---|
| <path> | <tokens, or none> |

## Artifact types

`docs.artifact_types`:

Start from `framework/rules/doc-artifact-registry.md` § Standard kinds, then keep, rename or drop
each one. This table is canonical for the project; the registry only suggests.

| type | path pattern | writer | authorization | lifecycle | budget |
|---|---|---|---|---|---|
| <type> | <pattern> | <member> | human-per-file \| standing:<path> \| none | <lifecycle from the registry> | <tokens or none> |

## Read-gated paths

`docs.read_gated`:

| path | grant |
|---|---|
| <path> | <exact grant string required in the task prompt> |
