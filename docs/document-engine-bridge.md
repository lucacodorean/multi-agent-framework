# Document-engine bridge

The platform ↔ document-engine seam. Owner: contract-owner; provider `engine/**`
(engine-engineer), consumer `app/Engine/**` (domain-engineer). Not repeated here:
topology, `ENGINE_KEY`, engine layout, CI gates (`docs/architecture.md`); commands
(`docs/runbook.md`); shapes and error bodies (`contract/engine.openapi.yaml`).

## Seam rule

- PHP never touches an Office file: every `.xlsx`/`.docx`/`.pdf` operation goes through
  the engine over HTTP (`app/Engine/EngineClient.php`).
- Consume the engine through the contract only, never by reading engine source.

## Engine properties, by construction

Definitions in `docs/architecture.md`. What the seam adds:

- Stateless — per-request temp workspace deleted in `finally` (`engine/app/deps.py`).
- Tenancy-unaware — the correlation reference is for logging only; never branch on it.
- Non-authoritative — it computes, it does not decide; the platform persists,
  cross-checks or discards every returned value.
- Loud on failure — bad input stops the call with an explicit problem body; never a
  guess, never a silent empty document.

## Operations

As-built inventory: the `engine/app/main.py` docstring; a deployment's served set is
`GET /health` → `capabilities[]` (`pdf-convert` only with a backend; `health` never
listed). Tokens are per operation, never per profile: read the 501.

| Operation | Purpose | Status |
|---|---|---|
| `GET /health` | liveness + capability probe | served; the only unauthenticated operation |
| `POST /export/inspect` | export identity + structure; no FI, no filtering | served, fixture-provisional (`engine/app/export_inspect.py`) |
| `POST /populatie/process` | Modul A: population filtering, FI file, counting report, line traceability, acquisition problems | served |
| `POST /anexa3/parse` | parse the semestrial Anexa 3 into entities and index values | served, specimen-backed (`engine/app/anexa3.py`) |
| `POST /tabular/parse` | header-keyed parse for register ingest, in three profiles | served for `contracte-finantare`; `associations` and `ier-list` answer the operation's 501, naming the profile (`engine/app/routes/tabular.py`) |
| `POST /nj/generate` | Modul B: render the NJ `.docx` plus its recomputation | served |
| `POST /pdf/convert` | `.docx` → fixed-form PDF, headless | served; 503 `pdf-backend-absent` with no backend |
| `POST /esantion/verify` | count + structure-check results against the platform's `expected` sizes | served, optional sample lines |

## Exchange

- Files travel as HTTP bytes both directions. Every POST is `multipart/form-data` (file
  part(s) plus JSON `Form` parts); a file+JSON response has exactly one JSON part named
  `result` (`app/Engine/MultipartResponseParser.php`).
- Send `X-Engine-Key` on every operation except `GET /health`; refuse platform-side when
  unset. No user identity crosses the seam.
- Errors are RFC 9457 on `application/problem+json`; branch on `type` only
  (`engine/app/problems.py`, `app/Engine/ProblemMapper.php`).
- Send `X-Correlation-Id` verbatim (`app/Engine/CorrelationId.php`): `{tenant-key}:{dosar-id}`
  for a call that serves a dosar, an opaque UUID v4 for the health probe and any call made
  outside a dosar. Never omit the tenant key (dosar ids are per-schema sequences).
- Timeouts per operation in `config/engine.php`; `convertPdf` gets the longest plus an
  engine-side `params.timeout`, refused unless strictly smaller
  (`app/Engine/EngineConfiguration.php`).
- Retry only on transport failure (`ConnectionException`), never after an explicit engine
  answer (`app/Engine/EngineClient.php`).
- Only `convertPdf` is queued (`app/Dosar/Documents/Jobs/ConvertNotaToPdfJob.php`);
  other hops run inline. A queued call carries the tenant key and re-initialises tenant
  context in the worker before persisting any artifact.

## Audit return

- Every operation except `GET /health` returns `auditEvents[]`; the contract's
  `EngineHealth` schema forbids it (`additionalProperties: false`); the engine stores
  nothing.
- Persist them tenant-locally, append-only, via `App\Engine\Audit\BusinessAuditTrail`
  (tenant migration `…101600_create_audit_trail_table.php`). Never central.
- The dosar id is optional (a hop outside a dosar records none); the correlation id is
  not (`audit_trail_engine_requires_correlation`).

## Correctness guards

- NJ reproduction diff: platform-determined values travel in the `/nj/generate` `context`;
  the engine returns `diffsReproducere` (camelCase on the seam). Never adopt an engine
  number as a correction. The diff covers the three sample values; risk class and
  percentage are checked separately, non-blocking (`engine/vendor/modul_b_nj/context.py`).
- Filter two documented exceptions first — the three sample fields while `sectiuneD` is
  true, and entries with empty `valoareFurnizata`
  (`app/Engine/Nj/DiffsReproducereFilter.php`). A surviving diff is an invariant
  violation: refuse generation and discard the `.docx`, which carries Modul B's numbers
  (`app/Dosar/Documents/GenerateNotaJustificativa.php`).
- Sample verification: `/esantion/verify` counts against `expected` and never revises it;
  verdict `incomplete` or `mismatch` rejects the sampling package and blocks the lifecycle
  transition (`app/Dosar/Sampling/ConfirmSampling.php`).

## Stays platform-side

Sampling instruction generation · all state (dosare, versions, determinations, audit,
register) · all tenancy · all authorization · the signature circuit · archiving ·
notifications · the determination of population, subpopulations and sample sizes.

Under `contracte-finantare` the engine returns cells verbatim and decides nothing further:
splitting the composite `PARTENERI-CUI` cell, RB-09 canonicalization
(`app/RiskRegister/FiscalCode.php`) and the lider / partener quality are the platform's.

## Versioning

- `contract/engine.openapi.yaml` is authoritative for the seam. The engine emits no
  generated `/openapi.json` (`engine/app/main.py`); a second description of this boundary
  is a defect.
- Keep the platform pin equal to the published version at all three sites
  (`config/engine.php`, `EngineClient::CONTRACT_VERSION`, and the config fixture in
  `tests/Unit/Engine/EngineConfigurationTest.php`); `ContractVersionPinTest` reads the
  contract and compares.
- Version numbers and their sources: `docs/architecture.md`.
