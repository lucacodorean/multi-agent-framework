# Documentation intake

Append-only. Workers: append doc-impact entries below the line, using the format in
`docs/conventions/documentation-governance.md`. The docs-agent verifies against SOURCE,
merges, and truncates. Never edit above the line.

---

## [2026-08-22] framework/project-context split
- AFFECTS: docs/architecture.md
- CHANGE: the repository now carries a project-agnostic framework core (`framework/`) and a project-context layer (`project-context/`) that resolves its placeholders; the layout table has no row for either, and `docs/conventions/{documentation-governance,orchestration,rules-of-engagement,working-agreement}.md` are now pointer stubs to `framework/rules/` plus `project-context/`
- SOURCE: framework/README.md, framework/contracts/project-context.schema.md, CLAUDE.md ch. 1
- AFFECTS: docs/adr/README.md
- CHANGE: the index prose declares 0036–0054 "reserved, never issued" while its own table lists nineteen accepted records with those numbers, all present in tree; 0032 has a record file and no index row
- SOURCE: docs/adr/0036..0054*.md, docs/adr/0032-localize-human-facing-filament-routes.md, docs/adr/README.md
