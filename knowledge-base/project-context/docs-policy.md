> **UNFILLED STUB.** Every `<…>` below must be supplied before this context is usable. Keys,
> shapes and consumers: `framework/contracts/project-context.schema.md` § docs-policy.md. Blank form:
> `framework/templates/project-context/docs-policy.md`.

# Documentation policy

Rules: `framework/rules/documentation-governance.md`; lifecycles:
`framework/rules/doc-artifact-registry.md`.

| key | value |
|---|---|
| `docs.sole_writer` | <member name> |
| `docs.role_gate_line` | <exact line granting the role> |
| `docs.worker_channel` | <append-only intake file> |
| `docs.metric` | <token metric and how it is counted> |
| `docs.archive_dir` | <where compaction moves removed content> |

## Allowed write paths — canonical, one copy

`docs.write_paths`:

| path | budget |
|---|---|
| <path> | <tokens, or none> |

Until this table is filled, the directories under `docs/` are an intended shape and not an
authorized whitelist — a file written there is unauthorized, not merely undocumented (FI-20).

## Artifact types

`docs.artifact_types`:

| type | path pattern | writer | authorization | lifecycle | budget |
|---|---|---|---|---|---|
| <type> | <pattern> | <member> | human-per-file \| standing:<path> \| none | <lifecycle> | <or none> |

## Read-gated paths

`docs.read_gated`:

| path | grant |
|---|---|
| <path> | <exact grant string required in the task prompt> |
