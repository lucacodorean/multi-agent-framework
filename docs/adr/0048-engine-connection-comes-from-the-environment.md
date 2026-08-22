# 0048 — The engine connection comes from the environment

- Status: accepted
- Date: 2026-08-20

## Context

- The central `engine_endpoints` table exists
  (`database/migrations/2026_07_28_000400_create_engine_endpoints_table.php`) with a model
  (`app/Models/EngineEndpoint.php`) that no code reads.
- `config/engine.php` sources the address, the credential and the per-operation budgets from
  environment variables injected into the container by the runtime, not from `.env` edits.
- The unauthenticated health probe is the one engine call that has to work while the rest of a
  deployment is still coming up.

## Decision

- The engine connection is sourced from the ENVIRONMENT. `engine_endpoints` stays unread.
- `App\Engine\EngineConfiguration` is constructible from a plain array and by nothing else: no
  container lookup, no database access, one factory (`fromArray()`). That constraint is the
  decision in executable form — it is what stops the bypass from decaying into a hybrid.
- Connection validation happens there, once. The 1..600 second timeout bound mirrors the
  `engine_endpoints_timeout_bounded` CHECK, so the two possible sources of a budget cannot
  disagree about what a legal one is. Every violation raises `EngineNotConfigured` before any
  HTTP call exists, and is never dressed up as an engine outcome.
- Giving the table a surface means adding a `::fromEndpoint()` beside `fromArray()`; every
  caller stays untouched.

## Alternatives rejected

- READ THE ENDPOINT ROW AT CALL TIME. It drags the central database connection into the
  transport layer and into the health probe, and buys nothing while nothing populates the table.
- RESOLVE THE CONFIGURATION FROM THE CONTAINER INSIDE THE CLIENT. It hides which source is in
  use and makes the no-database property untestable.

## Consequences

- Moving the engine is a deployment change, not a data change; there is no admin surface for it,
  and a missing key is a deployment fact rather than a code change.
- The table's reproducibility purpose — which engine answered a given dosar — is not served
  while it stays unread.
- `tests/Unit/Engine/EngineConfigurationTest.php` exercises the class framework-free and fails
  the moment a container lookup appears.
