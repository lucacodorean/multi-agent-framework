# Working agreement

Canonical depth behind `CLAUDE.md` ch. 4. The four core rules live there; this file holds
what they mean in this repository.

## Destructive operations (explicit user-approved task required)

- `ddev delete`, Docker volume or database drops.
- `tenants:migrate-fresh`; `tenants:rollback` against shared data.
- `ddev redis-flush`.
- Any operation against a schema or store other than the dedicated test resources
  (`oirflow_test`, Redis DBs 8/9 — `phpunit.xml`).

## Reporting

- Outcomes faithfully: failures as failures, with output; skipped steps named as skipped.
- Escalate only genuine blockers; everything else is yours to resolve inside your task.

## Verification discipline

- Verify against the real baseline, not simulations: migrations against DDEV PostgreSQL
  (`ddev psql`), Redis via the real service (`ddev redis-cli`), engine behavior via the
  black-box HTTP suite (`engine/tests/`).
- After topology changes, verify by full boot: `ddev poweroff && ddev start` — never
  `ddev restart` (`docs/runbook.md` → Gotchas).
