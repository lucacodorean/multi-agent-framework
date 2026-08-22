# Runbook

Commands verified by execution 2026-08-11 unless marked UNVERIFIED. Host needs Docker and
ddev (≥ 1.23.5 per `infra/ddev/bootstrap.sh`) — nothing else; every tool runs in a
container. What the runtimes contain: `docs/topology/local.md`,
`docs/topology/preview.md`. CI host wiring: `docs/ci/gitlab.md`.

## Environment up — DDEV (local)

- This clone: `ddev start`. The post-start hook (`infra/ddev/hooks/dev-install.sh`, wired
  by `.ddev/config.hooks.yaml`) leaves a login-ready install: composer install (if
  `vendor/` absent) → central migrate → `tenants:migrate` → `tenants:seed` →
  `DevTenantsSeeder` → `console:administrator` → `tenants:drift-check` (drift fails the
  start).
- `DevTenantsSeeder` is DDEV / `APP_ENV=local` only (published password `oirflow-dev`). It
  never runs on preview/staging. It never fails the boot — a declared slug it cannot use is
  skipped loudly (see Gotchas).
- Node assets are NOT covered by the hook: `ddev exec npm install --ignore-scripts &&
  ddev exec npm run build`.
- Regenerate `.ddev/` from source of truth: `infra/ddev/bootstrap.sh oir-flow laravel`
  (idempotent). UNVERIFIED this session.
- After any topology change verify by full boot: `ddev poweroff && ddev start` — never
  `ddev restart` (see Gotchas).
- Services, generated files, published ports and URLs: `docs/topology/local.md`.

## Environment up — preview (`oir-flow-preview`)

Operator path is `infra/deploy/up.sh` (never from CI, never `deploy-stack.sh`). Requires
`infra/deploy/.env` (copy from `.env.example`; fill secrets). Builds or reuses the two
preview images, then `compose up -d --wait`. Topology, image names, ports and TLS:
`docs/topology/preview.md`. Default path is additive — named volumes persist. Opt-in
`--reset-data` (after images are in place): `compose down --volumes` on project
`oir-flow-preview` (Postgres `db-data`, Redis `redis-data`; no image delete), then the
same login-ready bootstrap. Login-ready bootstrap inside `web`:

1. central `migrate --force`
2. `db:seed` (`DatabaseSeeder` — empty; does **not** create `console_users` or tenants)
3. `tenants:migrate` / `tenants:seed`
4. `db:seed --class=StagingTenantsSeeder` — tenants `oir-north-west`, `oir-south-west`
5. `console:administrator` from `CONSOLE_ADMIN_EMAIL` / `CONSOLE_ADMIN_NAME` /
   `CONSOLE_ADMIN_PASSWORD` (required; not from `DatabaseSeeder`)
6. `tenants:drift-check`

- Staging tenant passwords: `STAGING_SEED_PASSWORD` (`config('tenancy.staging_seed_password')`,
  empty default). Never `oirflow-dev`. `up.sh` refuses empty and that published secret.
- `StagingTenantsSeeder` runs only under `APP_ENV=staging`; not wired into
  `DatabaseSeeder`. `start-web.sh` migrates/seeds existing schemas on container start but
  does **not** run `StagingTenantsSeeder` or `console:administrator` — use `up.sh`.
- `APP_URL` is `https://…` and `SESSION_SECURE_COOKIE=true` in `infra/deploy/.env`.

## Daily commands

| task | command |
|---|---|
| Platform tests (Pest) | `ddev exec php artisan test` (narrow: `--filter=<name>`) |
| Engine tests | `cd engine && .venv/bin/python -m pytest` |
| Contract lint | `ddev contract-lint` |
| Style | `ddev exec vendor/bin/pint --test` (apply: drop `--test`) |
| Static analysis | `ddev exec vendor/bin/phpstan analyse` |
| Frontend | `ddev exec npm run dev` / `ddev exec npm run build` |
| DB shell | `ddev psql` (UNVERIFIED) |
| Redis shell | `ddev redis-cli` |
| Log tail | `ddev exec php artisan pail` (UNVERIFIED) |

Full local dev loop alternative: `composer dev` runs serve + queue + pail + vite
concurrently (`composer.json`; UNVERIFIED — DDEV daemons already cover serve/queue).

## Commit hooks (CaptainHook)

`captainhook.json` registers a `pre-commit` hook; run-mode `docker`, so every action runs
in the DDEV web container through `ddev exec`. What the actions do: `infra/README.md`
§ infra/hooks/ — the env contract.

- Existing clone: no install step — `.git/hooks/*` are in place and dispatch to
  `ddev exec vendor/bin/captainhook`.
- Fresh clone: `ddev exec vendor/bin/captainhook install` (UNVERIFIED).
- Run the hook without committing: `ddev exec vendor/bin/captainhook hook:pre-commit`.
- `config.verbosity` stays `verbose`: below it CaptainHook swallows an action's stdout and
  the committer never sees what the action changed.
- The same engine runs as the `env-contract` gate in `--check` mode, which modifies and
  stages nothing — safe to run while another member is editing the tree.

## Test-suite discipline

- One platform-suite run per machine: `tests/Pest.php` takes a PostgreSQL session
  advisory lock inside the suite, whatever invoked it; a concurrent run waits, and
  half-written tenant schemas from an aborted run are the thing to check when tests fail
  strangely. This is not the gate machine lock below — different mechanism, different
  scope.
- Tests touch only dedicated resources: database `oirflow_test`, Redis DBs 8/9
  (`phpunit.xml`) — never the dev `db`.
- Eight concurrency tests each start a second PHP process and hold two sessions on
  `oirflow_test`: the seven in `tests/Feature/Tenancy/` driven by
  `Tests\Feature\Tenancy\SecondParty`, plus
  `tests/Feature/Auth/ConsoleRosterFloorConcurrencyTest.php`, which carries its own copy of
  the protocol. The child takes its connection from the parent's environment, never from
  `.env`, and refuses to act outside the scratch database. Both sessions set
  `lock_timeout = '30s'`, so a lock never released fails the test instead of wedging the
  machine's one suite slot; a child still running is terminated.
- Not every case waits on a lock. A case whose two acts assert the SAME fact converges on a
  unique index and neither session blocks. A case proving a RULE instead — two acts asserting
  DIFFERENT liders, both surviving — asserts the child was `blocked` at the rendezvous, which
  is what separates a serialized act from a lucky interleaving
  (`tests/Feature/Tenancy/ContractImportProjectionConcurrencyTest.php`).
- `after_commit` is inert under the suite: `phpunit.xml` sets `QUEUE_CONNECTION=sync` and the
  `sync` connection carries no `after_commit` key. A test of that guarantee selects the
  application default (`database`) and points it at the central connection, whose
  `public.jobs` is the only queue table migrated. `Mail::fake()` cannot prove it — it records
  at the mailer, before any queue connection is chosen.

## Tenant operations (existence verified via `php artisan list`)

`tenants:list` · `tenants:provision` · `tenants:migrate` · `tenants:seed` · `tenants:run`
· `tenants:drift-check` · `tenants:rollback`. Destructive — explicit user-approved task
only: `tenants:migrate-fresh`, `ddev redis-flush`.

## CI gates (Docker only; one script layer)

Local repro is the scripts under `./infra/ci/` — the same scripts the CI host runs
(wiring: `docs/ci/gitlab.md`; what each gate proves: `docs/architecture.md`).

| gate | command |
|---|---|
| contract | `./infra/ci/contract-lint.sh` |
| engine | `./infra/ci/engine-suite.sh` |
| platform | `./infra/ci/platform-suite.sh` |
| seam | `./infra/ci/seam-suite.sh` |
| static-analysis | `./infra/ci/static-analysis.sh` |
| env-contract | `./infra/ci/env-contract.sh` |
| deploy-stack (build) | `./infra/ci/deploy-stack.sh` |
| adr-citations | `./infra/ci/adr-citations.sh` |

`deploy-stack.sh` validates `infra/deploy/compose.yaml` against
`infra/deploy/.env.example` and builds the preview engine + web images. It **named-SKIPs**
`compose up`. Operator boot is `infra/deploy/up.sh` only — never from CI, and not while a
pipeline that uses host Docker may run. Equivalent manual image build from repo root:

```
docker compose -f infra/deploy/compose.yaml --env-file infra/deploy/.env.example build
# or single images (tags must match compose: web image is oir-flow-preview-web):
docker build -f infra/deploy/engine/Dockerfile -t oir-flow-preview-engine .
docker build -f infra/deploy/platform/Dockerfile -t oir-flow-preview-web .
```

The platform and seam gates share one persistent composer download cache: named Docker
volume `oir-flow-ci-composer-cache` mounted at `/composer-cache` in the runner, download
parallelism capped at 6 (`infra/ci/composer-cache.sh`). Force a cold run with
`docker volume rm oir-flow-ci-composer-cache` — nothing else on the host has to be cleaned.
The cache holds downloads only; a changed `composer.lock` misses it and downloads.

Gate serialization (canonical): a gate script that runs containers under constant names
takes an exclusive host lock through `infra/ci/lock.sh` — engine, platform, seam. Never
parallelize them on one machine. `deploy-stack` and `env-contract` take no such lock —
`env-contract` starts no container and owns no constant-name resource. CI-host equivalent:
`docs/ci/gitlab.md`.

## Shell lint

Not a gate (`docs/architecture.md` § CI — gates); run it by hand. The glob must expand on the
host — passed literally it exits 2 and checks nothing:

```
docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable \
  $(printf '/mnt/infra/ci/%s ' $(cd infra/ci && ls *.sh))
```

Measured 2026-08-19: 9 findings, 4 of the 7 gate entrypoints clean. Open deliberately —
SC2155 on `CI_APP_KEY_BYTES` (`platform-suite.sh`, `seam-suite.sh`), SC1091 on unfollowed
`source` in the engine/platform/seam gates. `infra/hooks/sync-preview-env.sh` is clean;
`infra/ddev/**` and `infra/deploy/up.sh` are UNMEASURED, and a lint gate scoped wider than
`infra/ci/` needs that measurement first.

## Gotchas

- `.env` is VOLATILE: `ddev start`/`restart` rewrite keys in it. Durable config belongs in
  `config/**`, `.env.example`, or `.ddev/config.local.yaml` (`.env.example` header).
- The engine has NO hot reload: uvicorn runs without `--reload`
  (`infra/shared/engine/Dockerfile`), source bind-mounted read-only — an edited engine keeps
  answering stale (e.g. a false 501) until its container restarts. For an engine-SOURCE-only
  change that is `docker restart ddev-oir-flow-engine`, which leaves web/db/redis up; a
  topology change still needs the full boot above.
- `ddev start` ends every boot with `NEPROVIZIONAT oir-north` and a `TOPOLOGIE INCOMPLETĂ`
  summary, and still exits 0. This is the expected standing state, not a defect and not a
  failed boot: `oir-north` was renamed to `oir-north-west`, so the slug is spent while its
  tenant is absent, and re-provisioning it needs a human-approved full purge.
  `DevTenantsSeeder` pre-checks each declared slug and skips a refusal instead of throwing,
  journalling nothing. Human ruling 2026-08-17: the declared list stays as it is, so the
  local topology is two tenants — `oir-north-west` and `oir-west` — until that is revisited.
- `ddev restart` can exit green while containers still run the old topology — always
  poweroff/start after topology changes (`.claude/agents/platform-engineer.md`, measured).
- Redis runs `noeviction`: a cache write without TTL is memory that is never reclaimed
  (`infra/shared/redis/redis.conf`).
- `ddev exec` runs at the container path mirroring your host cwd — run repo-root commands
  from the repo root.
