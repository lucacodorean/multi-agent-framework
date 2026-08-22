# 0029 — Preview Compose topology (build artifacts, not operated)

- Status: accepted
- Date: 2026-08-17

## Context

- Local runtime is DDEV (`infra/ddev/` → generated `.ddev/`). A second topology is needed
  for host-side image builds and a later preview stack.
- OIRP-INFRA-1 plan approval (`.grok/plans/2026-08-14-external-docker-compose-deploy.md`)
  authorizes this record. This cut is **test + image build only**: no live stack, no
  `compose up`, no GitLab deploy stage (T4–T7 deferred).

## Decision

- **DDEV remains local-only.** Do not replace or dual-boot DDEV with the preview project.
- **`infra/deploy/`** holds the preview Compose contract (`name: oir-flow-preview`),
  Dockerfiles, and `.env.example`. It is a **build-time image contract** in this cut; the
  stack is **not operated**.
- **Live CI host is GitLab** (root `.gitlab-ci.yml`): stages `test` then `build`; no
  `deploy` stage; no DinD; no registry push. Jobs are thin wrappers over `infra/ci/*.sh`.
- **`.github/workflows/*` are not the live host** on this remote; leave them untouched.
- **One script layer:** every gate (including `infra/ci/deploy-stack.sh`) is host-agnostic
  Docker-only. `deploy-stack.sh` does `compose config` + build engine/web images and
  **named-SKIPs** `compose up` of `oir-flow-preview`.
- **Engine unpublished** (`expose: 8000` only). Engine image COPYs `engine/`; platform
  image is official `php:8.5.7-fpm-bookworm` + nginx, uid 1000 `app`, listens on 8080
  (host `80:8080`). Not `ddev/ddev-webserver`.
- **Mailpit** is declared in Compose for a later cut; production SMTP path stays open
  (ADR-0010).
- **GitLab Runner install** is human ops; not required to land these files. When installed:
  shell executor, host `docker.sock`, `concurrent = 1`; never DinD.

## Consequences

- Operators build preview images via `./infra/ci/deploy-stack.sh` or
  `docker compose -f infra/deploy/compose.yaml --env-file infra/deploy/.env.example build`.
- `compose up` of `oir-flow-preview` is a later cut (T7); do not treat absence of a running
  stack as a gate failure or a gate pass by silence.
- Supersedes nothing; extends the dual-topology story beside DDEV.
