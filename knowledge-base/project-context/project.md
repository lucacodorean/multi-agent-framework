# Project identity

Contract: `framework/contracts/project-context.schema.md` § project.md.

| key | value |
|---|---|
| `project.name` | <human name> |
| `project.slug` | <kebab-case; the only identifier infra derives names from> |
| `project.description` | <one line> |
| `project.docs_language` | <language documentation is written in> |
| `project.input_language` | <language requirement inputs arrive in> |
| `project.tracker.host` | <tracker product, or `none`> |
| `project.tracker.key_prefix` | <issue-key prefix, or `none` → keys are minted> |
| `project.repo.default_branch` | <branch a review diffs against> |
| `project.architecture_dir` | <directory holding the architecture description, one file per area> |
| `kb.root` | <path to this knowledge base in the host repository; the anchor outside files cite (FI-27)> |
