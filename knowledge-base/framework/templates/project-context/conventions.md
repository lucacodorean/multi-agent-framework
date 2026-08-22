# Conventions and boundary

Contract: `framework/contracts/project-context.schema.md` § conventions.md.

| key | value |
|---|---|
| `conventions.code_level` | <project file holding class/method-level discipline> |
| `conventions.structural` | <project file holding module/dependency discipline> |

The framework mandates these two slots and never their content.

## Boundary

| key | value |
|---|---|
| `conventions.boundary.interface_paths` | <where published interfaces live> |
| `conventions.boundary.formats` | <interface description formats> |
| `conventions.boundary.error_model` | <the error shape every boundary answers with, or `none`> |
| `conventions.boundary.versioning` | <where and how the interface version is stated, or `none`> |

## Enforcement

`conventions.enforcement` — per convention, the gate, test or construction that enforces it, or
`nothing` (FI-22):

| convention | enforced by |
|---|---|
| <convention> | <gate/test/construction, or nothing> |
