# infra/ — runtime sources and CI gates

Owned by platform-engineer; this file is the docs-agent carve-out (`CLAUDE.md` ch. 2).
`infra/shared/` runtime-agnostic inputs · `infra/ddev/` local · `infra/deploy/` preview ·
`infra/ci/` gates · `infra/hooks/` commit-time hooks.

Not restated here: runtimes — `docs/topology/local.md`, `docs/topology/preview.md` ·
commands — `docs/runbook.md` · gates — `docs/architecture.md` § CI — gates · CI host —
`docs/ci/gitlab.md`.

## Host-agnostic tooling

Host prerequisites and the in-container rule: `CLAUDE.md` ch. 6; thin YAML wrappers:
`docs/ci/gitlab.md`. Each gate names in its own header what it forbids on the host — between
them Node.js, npm, npx, Python, pytest, pip, PHP, composer, and for deploy-stack any
`GITHUB_*`/`GITLAB_*` token.

- A host `npx` is forbidden by name for contract linting: it lints with whatever the
  developer's machine resolved (`infra/ci/contract-lint.sh`).
- Host-agnostic is not reproducible. CI pins Spectral **by image digest** — findings depend on
  the bundled rulesets, not the CLI alone — while `ddev contract-lint` runs `npx` in the web
  container: host-agnostic, not a full pin (`infra/ddev/commands/web/contract-lint`). They
  agree on errors and warnings, differ on infos; the ratchet counts warnings only.
- Gate tools are the project's own pinned composer dev-dependencies, never a global or host
  binary (`infra/ci/static-analysis/run-analysis.sh`).
- All seven gate entrypoints share ONE `REPO_ROOT` idiom — assign, then bare `readonly` — so
  a failing `cd` is not masked; the reasoning is recorded once, in `infra/ci/env-contract.sh`.
  Nothing lints shell; measured state and command: `docs/runbook.md` § Shell lint.

## Known DDEV behaviours

- `.env` volatility: `docs/runbook.md` § Gotchas. dotenv is immutable both ways — a key in
  `.env` beats a `config/**` default, a container variable beats `.env` — so anything that
  must survive the rewrite goes through `web_environment` (`infra/ddev/bootstrap.sh`).
- Mailpit runs in the web container, SMTP `1025`, unconfigured by us
  (`infra/ddev/config.stub.yaml`). CI runs no queue daemon and must drain the queue itself.
- Add-on overwrites run **after** `ddev add-on get`, never before (`infra/ddev/bootstrap.sh`);
  the copy and its `#ddev-generated` marker: `docs/topology/local.md` § Generation. The image
  pin uses `ddev dotenv set`, never an edit of the add-on's compose file.
- `ddev config` rewrites `.ddev/config.yaml` and has no flag for `hooks` or
  `web_extra_daemons`; DDEV merges every `.ddev/config.*.yaml`, so those live in their own
  files and survive a re-bootstrap. The scripts they name stay in `infra/` and run from the
  `/var/www/html` bind mount, never copied.
- The engine compose service declares no `image:` key on purpose: a name Compose can resolve
  is a name it will try to pull, and this one exists in no registry.

## The restart cycle

Rule and failure mode: `docs/runbook.md` § Gotchas.

- After the cycle assert both: Redis answers `maxmemory-policy noeviction`, the engine
  container reaches `healthy`. Moving a pinned image version requires both.
- `queue:work` holds the application in memory and runs old code after an edit, so the
  development daemon is `queue:listen` (`infra/ddev/daemons/queue-worker.sh`).

## Isolation

- "Internal only" means no published surface. It does not mean unreachable.
- The engine publishes nothing in either runtime: `docs/topology/local.md` § Exposure,
  `docs/topology/preview.md` § Rules.
- DDEV attaches the container to the shared `ddev_default` network, and on Linux the host
  routes into Docker bridge subnets — its IPs answer from the host shell and other DDEV
  projects. Controls are `ENGINE_KEY` and the VM firewall; real isolation is network policy at
  deploy time (`infra/ddev/docker-compose.engine.yaml`).
- CI images, containers and networks are named distinctly from the DDEV project's, so a gate
  cannot touch a running dev project — but those names are constants, so two runs of one gate
  are destructive, not merely racy: the second's up-front `cleanup` deletes the first's
  containers mid-test (`infra/ci/lock.sh`). Which gates serialize: `docs/runbook.md` § CI
  gates.
- Take the lock **before** defining `cleanup` and its `trap`: a waiting process owns no
  containers and would delete those of the run it queues behind. The lock serializes a file,
  not a copy.

## The bind-all-interfaces decision

The project's host ports must be reachable from outside the development VM
(`infra/ddev/config.stub.yaml`). Two settings, not interchangeable, both applied by bootstrap:

| setting | scope | where |
|---|---|---|
| `bind_all_interfaces: true` | this project's host ports | `.ddev/config.yaml`, committed |
| `router_bind_all_interfaces` | the shared router, 80/443 | `~/.ddev/global_config.yaml`, host-global |

- A clone on another machine gets the router setting only by running bootstrap.
- Postgres publishes at a stable port so external clients need not read a dynamically
  assigned one; ports and the cross-runtime collision: `docs/topology/local.md` § Exposure,
  `docs/topology/preview.md` § Rules.
- Protection is the VM firewall, nothing in this repository. Development-only; revisit before
  any deployment, as for the development queue daemon (`infra/ddev/daemons/queue-worker.sh`).
- One exemption: `bind_all_interfaces` cannot publish the engine, which declares no `ports:`
  (§ Isolation).

## infra/hooks/ — the env contract

Git commit-time scripts, wired through `captainhook.json`. Distinct from
`infra/ddev/hooks/` (DDEV lifecycle) and `infra/ci/` (CI gates): a hook here may read one
runtime's inputs and write another runtime's contract, which a runtime directory never does.
Commands: `docs/runbook.md` § Commit hooks and § CI gates.

`infra/hooks/sync-preview-env.sh` is the single enforcement engine for the chain root `.env`
→ root `.env.example` → `infra/deploy/.env.example` → the `x-platform-environment` anchor.
Two links call it and there is deliberately no second implementation: the pre-commit hook in
sync mode from the volatile root `.env`, and the `env-contract` gate as `--check --source
.env.example` from the tracked template, CI having no root `.env`.

- Sync adds a missing key to all THREE targets and stages them; additive only, never rewrites
  an existing line, never writes the source, exits 0 silently with no root `.env`. `--check`
  modifies and stages nothing and exits non-zero on drift.
- A secret-looking key name or a `ddev` value lands empty — `KEY=` in an example file,
  `${KEY:-}` in the anchor. No secret value reaches a committed file.
- Three exemption lists hold every rule, each entry naming its reason, all in that script:
  `EXCLUDED_KEYS` (root keys the preview drops — preview targets only, never root
  `.env.example`), `PREVIEW_ONLY_KEYS` (preview keys DDEV supplies another way),
  `ANCHOR_EXEMPT_KEYS` (deploy-example keys with a verified non-container consumer).
- Both directions are asserted and neither is key-set equality: forward alone is satisfied
  trivially by a source that has LOST a key.

## Deployment constraints

Preview is the deployment target; services, ports, TLS, configuration and rules are canonical
in `docs/topology/preview.md`, the operator sequence in `docs/runbook.md`. Where ADR-0029 and
`infra/deploy/compose.yaml` disagree, follow the compose file and `infra/deploy/up.sh`.

- CI never ups. `infra/ci/deploy-stack.sh` runs `compose config` plus both image builds and
  names the skipped `compose up` on stdout; a silent skip would read as a pass. No push, no
  registry, no `oir-flow-preview` lifecycle.

Binding on any future deployment:

- Eviction is server-wide, so the logical-DB split does not protect queued jobs; under memory
  pressure the escape hatch is a second Redis for the cache, never a relaxed policy. Policy
  and its TTL consequence: `docs/architecture.md` § Tenancy (Redis keyspaces).
- `REDIS_QUEUE_RETRY_AFTER` must exceed `queue:work --timeout=360` or a running `convertPdf`
  job is released; `MAIL_MAILER` stays `smtp`, never `log` (`infra/deploy/.env.example`).

## engine — the document-engine service

The platform tier owns the container; `engine/**` belongs to engine-engineer and is never
edited from `infra/` (`CLAUDE.md` ch. 2). The image and every choice inside it is
`infra/shared/engine/Dockerfile`; read its header first.

- Cold build ~47 s; budget timeouts against that (`infra/ci/engine-suite.sh`).
- Build context is the directory holding the dependency lock, never the repository root,
  because `COPY requirements.txt` is context-relative: bootstrap assembles Dockerfile + lock
  into `.ddev/engine-build/`, CI builds `--file infra/shared/engine/Dockerfile
  infra/shared/engine` (`docs/topology/local.md` § Generation, `docs/ci/gitlab.md`).
- `infra/shared/engine/requirements.txt` is one runtime-agnostic lock, fully pinned including
  transitives; the dev extra is absent because the container only serves. Regeneration: its
  own header.
- Local bind-mounts, preview bakes. Locally the image carries the runtime only and `engine/` is
  bind-mounted read-only, so an engine edit needs no rebuild — and no reload
  (`infra/ddev/docker-compose.engine.yaml`, `docs/runbook.md` § Gotchas).
  `infra/deploy/engine/Dockerfile` differs only in `COPY engine/ /app/engine/` and reads the
  same lock from the root context.
- CI consequence: both engine gates build, never pull, from that Dockerfile and bind-mount
  `engine/` at run time exactly as the topology does (`infra/ci/engine/container.sh`); test
  tooling is layered into a second, CI-only image so the serving container stays
  byte-identical to the developer's (`infra/ci/engine/Dockerfile.test`); the read-only suite
  mount forces `pytest -p no:cacheprovider`; the image builds twice per pipeline (no shared
  layer cache) under tags distinct per gate and from the DDEV project's.
- Access path is `http://engine:8000` from any project container; connection and key defaults
  are in `docs/topology/local.md` § Engine connection and auth, guard behaviour in
  `docs/architecture.md` § Contract boundary. Unset or empty `ENGINE_KEY` does not disable the
  check — CI asserts that against a container started without it
  (`infra/ci/engine/unconfigured_probe.py`) — and the preview default is empty, deliberately
  not the development key.
- `ENGINE_PDF_TIMEOUT` defaults to 120 s; a call may lower it via `params.timeout`. Liveness is
  the contract's own unauthenticated `GET /health`, probed inside the container with stdlib
  `urllib` (`python:*-slim` has no curl). No mount is shared with `web` — the seam is bytes
  over HTTP. Bootstrap installs the service only if `engine/` exists.
