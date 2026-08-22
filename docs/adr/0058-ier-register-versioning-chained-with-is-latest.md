# 0058 — IER register versioning: chained versions with a stored `is_latest`

- Status: accepted
- Date: 2026-08-20

## Context

OIRP-26 / OIRP-29: version the IER register with the same paradigm as AS-009
(`docs/tracker/2026-08-20-oirp-26-ier-register-intake.md`; plan assumptions §3,
approved 2026-08-20).

ADR-0030 already splits ROLE: evidence of an act is append-only; working state
and current-pointers are mutable. `risk_index_sources` / `risk_index_values`
are evidence (artifact, period, values). Consultation was a live join to the
current contract projection plus a read-time “latest” IER ordering — no stored
register version, no freeze.

## Decision

- Keep `risk_index_sources` (and their values) append-only evidence. Do not
  UPDATE them to flip a latest flag.
- Hold the IER register as mutable working state: `risk_register_versions` and
  `risk_register_entries`. No append-only trigger.
- Allocate a 1-based `version` (UNIQUE, CHECK ≥ 1). Chain with
  `previous_version_id` (nullable UNIQUE self-FK). Version 1 has no
  predecessor; every later version exactly one.
- Store `is_latest` as a NOT NULL boolean, held to at most one true row by a
  partial unique index. `snapshot(null)` and the default consult selection
  read the flag, never a version maximum.
- „Se clasează” is a flag flip to false: delete nothing, rewrite nothing on
  the classified version.
- One ingest is one act is one new version: retain the source, then
  `RiskRegisterVersionRepository::openFromSource` in one outer transaction
  (ADR-0033). Manual and Anexa 3 routes share that path. A refused overlap
  leaves zero new sources and zero new versions.
- Copy-on-open: with no previous version, snapshot live
  `projects` / `project_entity` / `entities`; otherwise copy the previous
  version’s entries. Then overlay IER from THIS source by CUI. Copied
  entities absent from the source keep the previous IER. SMIS entities that
  never had an IER stay NULL. IER CUIs with no SMIS stay on the source only
  — they never become entries.
- No mid-period contract-import hook. A SMIS added after this period’s ingest
  appears on the next `openFromSource`. Isolation is the stored snapshot, not
  a live join. An empty version list is an empty register.

Schema:
`database/migrations/tenant/2026_08_20_102400_create_risk_register_version_tables.php`.

## Consequences

- Second stored latest pointer (after ADR-0030). IER evidence stays
  append-only; current-register identity does not.
- Historical versions freeze: a later ingest cannot rewrite earlier entries.
- At-most-one, never exactly-one: zero latest is representable before the
  first ingest.
