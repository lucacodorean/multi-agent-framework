# CI host — GitLab

The live CI host (origin `evogit.evozon.com`). Gate set and what each gate proves:
`docs/architecture.md` § CI — gates. Local reproduction commands: `docs/runbook.md`.

- `.github/workflows/*` do NOT run on this remote. They are not the live host; leave them
  untouched and never read a result there as CI evidence.

## Wiring

- Root `.gitlab-ci.yml` is the entry file only: `workflow`, `stages`, `default`,
  `include`. It declares no job.
- Each gate is one file `infra/ci/gitlab/<gate>.gitlab-ci.yml`, pulled in by
  `include: local:`. Read or change a gate in its own file, without touching the entry
  file or another gate.
- Every gate file is a thin wrapper over its `infra/ci/*.sh` script, so the identical gate
  runs on a laptop. Gate logic never lives in YAML.
- No gate resolves a path into a runtime directory: the engine and seam gates build the
  engine image as `--file infra/shared/engine/Dockerfile infra/shared/engine`
  (`infra/ci/engine-suite.sh`, `infra/ci/seam-suite.sh`).

| job | stage | script | serialized |
|---|---|---|---|
| contract | test | `infra/ci/contract-lint.sh` | no |
| static-analysis | test | `infra/ci/static-analysis.sh` | no |
| env-contract | test | `infra/ci/env-contract.sh` | no |
| adr-citations | test | `infra/ci/adr-citations.sh` | no |
| engine | test | `infra/ci/engine-suite.sh` | `resource_group: oir-flow-docker` |
| platform | test | `infra/ci/platform-suite.sh` | `resource_group: oir-flow-docker` |
| seam | test | `infra/ci/seam-suite.sh` | `resource_group: oir-flow-docker` |
| images | build | `infra/ci/deploy-stack.sh` | `resource_group: oir-flow-docker` |

- Stages are `test` then `build`; `images` `needs` the seven test jobs. There is no deploy
  stage, no registry push, no required CI/CD variable, and no secret in the entry file or
  any included one.
- Pipelines run for merge-request events, for the default branch (`main`) and for
  `develop` (`workflow.rules` in the entry file); a post-merge push to either branch runs
  a pipeline of source `push`. Jobs default to `interruptible: true` with
  `auto_cancel.on_new_commit: interruptible`.
- `images` is branch-scoped by its own `rules:`: only a `push` pipeline on `develop` or
  `main`, never a merge-request pipeline — no matching rule means the job is absent from
  the pipeline. Every other gate runs unfiltered.
- Branch scoping is not path filtering; no gate filters by changed path
  (`docs/architecture.md` § CI — gates).
- No job runs, starts, or stops the preview runtime (`docs/topology/preview.md`).

## Runner

Operator task, not installed by this cut. When installing: shell executor on the same
Docker VM as the preview runtime, host `docker.sock` available, `concurrent = 1` in
`/etc/gitlab-runner/config.toml` so constant-name CI containers cannot destroy each other.
Never Docker-in-Docker; no `image:` default is set for that reason.
