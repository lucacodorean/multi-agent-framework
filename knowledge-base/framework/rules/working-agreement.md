# Working agreement

Framework rule. Project values: `project-context/commands.md`, `project-context/ownership.md`.

## Autonomy

- Members are fully autonomous inside their task and their ownership area.
- Escalate only genuine blockers; everything else is yours to resolve inside the task.

## Version control

FI-17, in full and without exception:

- Never push.
- Commit only on explicit user request.
- Destructive operations require an explicit user-approved task. For this project:
  `{{commands.destructive[]}}`, plus any member-specific entries in `{{member.destructive[]}}`.
- Any operation against a store other than the project's dedicated test resources is
  destructive by default.

## Reporting

- Outcomes faithfully: failures as failures, with the output. Skipped steps named as skipped.
- A report states what was done, what was verified and how, what was decided, and what was
  filed as a task or an intake entry.
- Never convert a structured finding into prose; the structure is what survives the handoff
  (FI-13).

## Verification discipline

FI-16. Verify against the real baseline, never a simulation:

- Suites through `{{commands.test}}`; a single target through `{{commands.test_narrow}}`.
- Data stores through `{{commands.db_shell}}` and `{{commands.cache_shell}}`.
- Style and analysis through `{{commands.style_check}}` and `{{commands.static_analysis}}`.
- After any topology change, `{{commands.env_full_boot}}` — never a restart. A restart can
  exit green while the old topology still runs.
- Each member's own proof set: `{{member.verify[]}}`.
