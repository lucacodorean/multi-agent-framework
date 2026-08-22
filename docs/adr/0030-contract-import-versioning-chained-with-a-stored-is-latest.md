# 0030 — Contract-import versioning: chained versions with a stored `is_latest`

- Status: accepted
- Date: 2026-08-18

## Context

Q-003, ruled verbatim: „ultimul import este sursa de adevăr, iar setul anterior se
clasează (add version support, chained, app must render latest version)", completed by
„version control should ensure also «is_latest» flag per record basis where version is
present" (`docs/tracker/2026-08-18-oirp-8-contract-import-ruled-intake.md`).

- "Versioned ⇒ append-only" is not this tree's rule. Six tenant tables carried `version`
  before this change; two — `sampling_packages`, `risk_class_intervals` — carry no
  append-only trigger. The tree splits by ROLE: evidence of an act is append-only; working
  state and "which one is current" pointers are mutable, on their own row.
- "Latest" was a read-time projection everywhere:
  `TenantRiskIndexSourceRepository::latestIndexEntries()` orders on `valid_from`,
  `valid_to`, `ingested_at`, `id` descending. No stored latest pointer existed.
- The existing chain is a per-owner sequence number only: `expense_ledger_versions` has no
  predecessor key.

## Decision

- Allocate the version once per import document — 1-based, monotonic per tenant — and carry
  it on every owner-scoped row it asserts.
- "Chained" means BOTH representations: the ordinal (`version`, UNIQUE, CHECK ≥ 1) and the
  chain (`previous_import_id`, a nullable UNIQUE self-FK). Version 1 has no predecessor,
  every later version exactly one.
- Store `is_latest` as a NOT NULL boolean on every row carrying a version, held to at most
  one per owner by a partial unique index on the true value — the form at
  `project_entity_one_lider_per_project` and `engine_endpoints_single_active`. Render from
  the flag, never from a version comparison.
- „Se clasează" is a flag flip to false: delete nothing, rewrite nothing. A superseded row
  keeps its version and its link to its import, readable behind `risk-register.access`.
- Apply the role split: the retained workbook (`contract_import_artifacts`) is append-only
  by trigger; the document, its items and its entity names are mutable working state:
  demoting the flag is an UPDATE.

Schema: `database/migrations/tenant/2026_08_18_102300_create_contract_import_tables.php`.

## Consequences

- The tree's first STORED latest pointer; every other "latest" stays a read-time
  projection, so correctness now rests on the adapter, not on an ordering.
- At-most-one, never exactly-one: "zero latest" is legal — an owner whose only line is
  invalid carries the flag nowhere.
