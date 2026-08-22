> **UNFILLED STUB.** Every `<…>` below must be supplied before this context is usable. Keys,
> shapes and consumers: `framework/contracts/project-context.schema.md` § project.md. Blank form:
> `framework/templates/project-context/project.md`.

# Project identity

| key | value |
|---|---|
| `project.name` | <human name> |
| `project.slug` | <kebab-case; the only identifier infrastructure derives names from> |
| `project.description` | <one line> |
| `project.docs_language` | <language documentation is written in> |
| `project.input_language` | <language requirement inputs arrive in> |
| `project.tracker.host` | <tracker product, or `none`> |
| `project.tracker.key_prefix` | <issue-key prefix, or `none` → intake mints keys> |
| `project.repo.default_branch` | <branch a review diffs against> |
| `project.architecture_doc` | <path, once it exists> |
| `project.runbook_doc` | <path, once it exists> |
| `kb.root` | `knowledge-base/` |

`kb.root` is filled: it is a property of this repository's layout, not of the project. It is the
anchor every file outside the unit cites (FI-27), and the host's instruction file restates it.
