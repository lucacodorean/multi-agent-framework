# 0025 — The contract file is the single source of the seam version

- Status: accepted
- Date: 2026-08-11

## Context

The platform ↔ engine seam version was declared in six places: `info.version` in
`contract/engine.openapi.yaml`, four code sites (`config/engine.php` `contract_version`
and its header comment, `App\Engine\EngineClient::CONTRACT_VERSION`,
`engine/app/settings.py` `CONTRACT_VERSION`), and one clause in `docs/architecture.md`.
Engine module docstrings and test names restate it further as prose.

- A bump of the contract to 0.4.1 left all five copies stale, and no gate turned red.
- One test asserted a hardcoded literal against the pin beside it
  (`tests/Feature/Dosar/Sampling/SamplingPathTest.php`); such a test moves with the copy it
  guards, so it can never observe drift from the contract. The config mirror's only mention
  was an inert fixture key (`tests/Unit/Engine/EngineConfigurationTest.php`) that covered
  nothing. The engine pin had no test at all.
- The engine build version (`engine/pyproject.toml`, cited separately in
  `docs/architecture.md`) is a different version axis and is not governed here.
- A verification pass found no production code path that reads any of the pins.

## Decision

- `info.version` in `contract/engine.openapi.yaml` is the single source of the seam
  version. Every other occurrence is a copy and is subordinate to it.
- Documentation names the address and the invariant; it never embeds the number. Cite the
  file that holds the version instead of restating the value.
- A code pin that must mirror the contract is enforced by a test that reads
  `contract/engine.openapi.yaml` and compares. A test asserting a hardcoded literal against
  a constant is not enforcement and does not count as coverage of a pin.

## Consequences

- Drift becomes detectable at the gate rather than by inspection.
- Contract-reading tests couple the platform and engine suites to the contract file's
  presence and parseability.
- Whether the three code pins become load-bearing (read at runtime) or are deleted as
  documentation living in code is OPEN; this ADR does not decide it.
- Supersede this ADR rather than editing it.
