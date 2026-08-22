# CI — OIR Flow

Contract: `framework/contracts/project-context.schema.md` § ci.md. Rules:
`framework/rules/ci-gates.md`.

| key | value |
|---|---|
| `ci.host_doc` | `docs/ci/gitlab.md` (live host; `.github/workflows/*` do not run on that remote) |
| `ci.script_dir` | `infra/ci/` |
| `ci.lock` | `infra/ci/lock.sh` — exclusive host lock for gates running containers under constant names |
| `ci.forbidden_host_tools` | Node.js, npm, npx, Python, pytest, pip, PHP, composer; for deploy-stack also any `GITHUB_*`/`GITLAB_*` token |

## Gates

| name | proves | command | serialized |
|---|---|---|---|
| contract | the three contract files satisfy `.spectral.yaml` | `./infra/ci/contract-lint.sh` | no |
| engine | engine suite against the built image, plus the unconfigured-deployment probe | `./infra/ci/engine-suite.sh` | yes |
| platform | Pest against PostgreSQL and Redis, engine faked | `./infra/ci/platform-suite.sh` | yes |
| seam | bridge client against a live engine, including 401-vs-503 | `./infra/ci/seam-suite.sh` | yes |
| static-analysis | Pint and PHPStan/Larastan level 5 | `./infra/ci/static-analysis.sh` | no |
| env-contract | the two `.env.example` files and the compose anchor declare one key set, asserted both ways | `./infra/ci/env-contract.sh` | no |
| deploy-stack | the preview definition interpolates and both preview images build; the stack start is a named skip | `./infra/ci/deploy-stack.sh` | no |
| adr-citations | every `ADR-nnnn` named by tracked source resolves to a `docs/adr/` record | `./infra/ci/adr-citations.sh` | no |

- Composer download cache shared by the platform and seam gates: named volume
  `oir-flow-ci-composer-cache`, parallelism 6 (`infra/ci/composer-cache.sh`).
- Nothing lints shell, though every gate is one. Measured state and command:
  `docs/runbook.md` § Shell lint.
