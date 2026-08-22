# 0051 — No dependency for a check's convenience

- Status: accepted
- Date: 2026-08-20

## Context

- `engine/pyproject.toml` declares the engine's whole dependency surface: the HTTP layer, the
  two validated readers, the multipart parser, and pytest with httpx as extras. A container
  builds the environment from that manifest alone.
- A developer virtualenv holds more than the manifest declares, so a test can import a library
  the engine does not depend on and still pass locally.
- The build-consistency check in `engine/tests/test_build_consistency.py` needs exactly one
  scalar out of the published contract: `info.version` of `contract/engine.openapi.yaml`.

## Decision

- The manifest is the ENVIRONMENT CONTRACT. No dependency is added to it for a check's
  convenience; a check that needs a library the engine does not need is the wrong check.
- The contract's `info.version` is read by a narrow scan anchored on the top-level `info:` key,
  which REFUSES rather than guesses: the document holds other `version:` lines — an example
  payload and a schema property — so a first-match scan would be right today by ordering luck.
- A second test guards the reader itself, asserting the scalar it returns is semver; without it
  the equality it feeds could pass for the wrong reason.
- Paths resolve from the test file's own location, not the invocation directory, so the check
  holds in the CI container too (`infra/ci/engine-suite.sh`).

## Alternatives rejected

- ADD PyYAML AND PARSE THE DOCUMENT. It would pass in a developer virtualenv and fail in an
  environment built strictly from the manifest — the check would be testing the virtualenv.
- COMPARE AGAINST A COPY OF THE VERSION HELD ENGINE-SIDE. The contract file is the sole source
  of the seam version (ADR-0025); a check between two copies observes nothing.

## Consequences

- The scan is coupled to the document's layout: `info.version` must stay a scalar directly under
  a top-level `info:` key, and moving it breaks the check loudly rather than silently.
- Build-consistency checks live flat in `engine/tests/`. The earlier `tests/build/` home is
  matched by `engine/.gitignore`'s `build/` rule, and a check that exists on one disk gates
  nothing.
