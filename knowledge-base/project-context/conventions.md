> **UNFILLED STUB.** Every `<…>` below must be supplied before this context is usable. Keys,
> shapes and consumers: `framework/contracts/project-context.schema.md` § conventions.md. Blank form:
> `framework/templates/project-context/conventions.md`.

# Conventions and boundary

| key | value |
|---|---|
| `conventions.code_level` | `docs/conventions/engineering-principles.md` |
| `conventions.structural` | `docs/conventions/architecture-principles.md` |

Both slots exist and are stubs. The framework mandates the slots and never their content.

## Boundary

| key | value |
|---|---|
| `conventions.boundary.interface_paths` | <where published interfaces live> |
| `conventions.boundary.formats` | <interface description formats> |
| `conventions.boundary.error_model` | <the error shape every boundary answers with> |
| `conventions.boundary.versioning` | <where and how the interface version is stated> |

## Enforcement

`conventions.enforcement` — per convention, the gate, test or construction that enforces it, or
`nothing` (FI-22):

| convention | enforced by |
|---|---|
| <convention> | <gate/test/construction, or nothing> |
