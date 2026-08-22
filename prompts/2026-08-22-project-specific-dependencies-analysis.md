# Project-specific dependency analysis — extracted multi-agent framework

**Produced by:** `prompts/2026-08-22-analyze-project-specific-dependencies.md` (file was empty; task
derived from its name + repo provenance).
**Consumed by:** `prompts/2026-08-22-create-the-framework-abstraction.md`.
**Analysed tree:** `/home/lucacodorean/Documents/agentic-framework` @ `099b10b` ("added the
extracted multi-agent system"), 162 tracked-or-new files, ~100.5k tokens of markdown
(`wc -w` × 4/3, the corpus's own metric).
**Reading discipline:** `docs/stories/as-reference/**` was NOT read (read-gated by
`docs/stories/README.md`, no `HISTORY-ACCESS:` grant); it is classified from its filenames and
the README that governs it only.

This document states what is portable, what is parameterizable, and what is OIR Flow. It makes
no abstraction decisions — it supplies the inputs for them.

---

## 0. What this repository actually is

A multi-agent operating system for one codebase, lifted out of that codebase. It contains the
**governance layer** (roster, ownership map, conventions, doc governance), the **agent layer**
(7 agent definitions × 2 hosts), the **skill layer** (4 skills + 8 reference files), the
**runtime/CI layer** (`infra/**`, 5,155 lines of shell/YAML), and the **instance corpus** (34
ADRs, 2 debt reports, 3 plans, 1 workflow script, backlog, stories, samples).

What it does **not** contain: the code all of that governs. `app/`, `tests/`, `database/`,
`contract/`, `engine/`, `config/`, `.ddev/`, `.github/`, `composer.json`, `phpunit.xml` are all
absent, while `CLAUDE.md` ch. 1–2 still assigns owners to every one of them. This asymmetry is
the single largest fact for the abstraction: **the corpus is written as claims about code that is
no longer present** (249 dangling path references — §5, H1).

Token weight by layer, so effort can be aimed:

| layer | tokens | verdict |
|---|---|---|
| skills (`.claude/skills/**`, 10 files) | 11,280 | mostly CORE |
| agent definitions (`.claude/agents/**`, 7) | 7,018 | TEMPLATE |
| agent definitions (`.opencode/agents/**`, 7) | 6,967 | HOST duplicate, stale |
| governance conventions (gov + orchestration + working-agreement + rules-of-engagement) | 2,997 | CORE+ |
| code/structure principles (engineering + architecture) | 3,648 | INSTANCE (stack pack) |
| `CLAUDE.md` | 1,044 | TEMPLATE |
| system docs (architecture, runbook, bridge, topology×2, ci) | 6,493 | TEMPLATE + INSTANCE |
| ADR set (34 records) | 15,534 | INSTANCE |
| ADR meta (README + template) | 903 | CORE+ |
| debt reports (2) | 15,170 | INSTANCE |
| plans (3) + workflow script (1) | 6,728 + 4,740 | INSTANCE (pattern is CORE) |
| stories (all) / stories meta only | 8,845 / 1,511 | INSTANCE / CORE+ |
| miscellaneous + e2e samples | 10,240 | INSTANCE |
| backlog + intake | 1,733 | CORE+ (shape) / INSTANCE (rows) |
| `infra/README.md` + `infra/**` | 1,973 + 5,155 lines | INSTANCE |

Mapping to the classification the prompt asks for:

| prompt class | verdict below | where it is answered |
|---|---|---|
| **Framework invariant** — belongs to the framework, stays | `CORE` | §1.1, and the invariants in §4 |
| **Project-context requirement** — needed by the framework, value depends on the project | `TEMPLATE` | §1.3, the catalogue in §2, the profile in §3 |
| **Configurable framework behavior** — hardcoded today, should become configurable | `CORE+` and `HOST` | §1.2, §1.4 (each with the exact lines to lift out) |
| **Legacy project artifact** — exists only because of the original project | `INSTANCE` | §1.5, §2 D11 |

Verdict vocabulary used throughout:

- **CORE** — portable as written, contains no project fact.
- **CORE+** — portable shape, carries a named handful of project lines to excise.
- **TEMPLATE** — generic structure, project-specific content; becomes template + profile.
- **INSTANCE** — OIR Flow only; keep as a worked example or leave behind.
- **HOST** — coupled to one agent harness (Claude Code / opencode / Grok), not to the project.

---

## 1. File-by-file classification

### 1.1 CORE — lift unchanged

| path | why it is portable |
|---|---|
| `.claude/skills/task-orchestrator/SKILL.md` | PLAN/DISPATCH modes, approval gate, wave protocol. 0 stack terms. Reads project docs at Step 0 instead of embedding them. |
| `.claude/skills/task-orchestrator/references/plan-template.md` | plan table, Source-column traceability rule, stable-ID rule. |
| `.claude/skills/task-orchestrator/references/dispatch-templates.md` | dispatch prompt, workflow runner, run manifest. |
| `.claude/skills/tracker-intake/SKILL.md` | items-not-tasks doctrine, quality gate, amendments, handoff gate. 0 stack terms. |
| `.claude/skills/tracker-intake/references/item-templates.md` | bug/feature/change blocks, ●/◐ gate fields, content mining. |
| `.claude/skills/tracker-intake/references/source-adapters.md` | Jira CSV/JSON/XML maps, status filter, dedup, key minting. |
| `.claude/skills/tracker-intake/references/intake-doc-template.md` | PLAN-mode directive, source-of-truth line, ordering rules. |
| `.claude/agents/docs-agent.md` | 0 stack terms; whitelist deliberately not restated, only pointed at. The best-abstracted file in the tree — use it as the model. |
| `.claude/statusline.sh` (394 lines) | 0 project references; pure Claude Code statusline. |
| `docs/adr/0000-template.md` | ADR skeleton. |
| `docs/_intake.md` (header only) | the append-only worker→docs channel. |

### 1.2 CORE+ — portable shape, excise the named lines

| path | project-specific content to lift out |
|---|---|
| `.claude/skills/docs-compaction/SKILL.md` | the `wc -w`×4/3 metric "ratified 2026-08-19"; "this corpus — Romanian diacritics"; the pointer to `docs/conventions/documentation-governance.md` budgets; `docs/archive/` as the archive path. → all become profile values. |
| `.claude/skills/user-stories-use-cases/SKILL.md` | `/mnt/user-data/uploads/` (a claude.ai upload path, inert in Claude Code — §5 H5); "Romanian to date" language assumption. |
| `.claude/skills/task-orchestrator/references/routing-defaults.md` | the Grok/Claude host-adapter table and `grok-4.5`/`grok-4.6` slugs are HOST, not project — but they belong in a host adapter file, not in the routing doctrine. |
| `docs/conventions/documentation-governance.md` | the whitelist path list, every token budget, and the "Removed documents" section are instance data around a portable charter (roles, worker rule, 3-line intake format, procedure, writing rules, new-topic rule, input-class rule). |
| `docs/conventions/working-agreement.md` | the destructive-op list (`ddev delete`, `tenants:migrate-fresh`, `ddev redis-flush`, `oirflow_test`, Redis DB 8/9) and the DDEV boot rule; the reporting + verification doctrine is portable. |
| `docs/conventions/orchestration.md` | roster names, `ddev contract-lint`, `docs/runbook.md` §-pointers; the operating model, tier-direction rules, Workflow-vs-Agent test, four workflow-trust rules and model/effort resolution order are portable. |
| `docs/conventions/rules-of-engagement.md` | § "The engine seam" is wholly INSTANCE; § "Boundary mechanics" is portable except the `config/`, `Storage/`, `app/RiskRegister` examples; § "Enforcement copies" is a CORE rule about harness duplication. |
| `docs/adr/README.md` | numbering/retirement/reservation discipline is portable; the 34-row index and the 0024-start history are instance. |
| `docs/stories/README.md`, `docs/stories/as-is/README.md`, `docs/stories/support/README.md` | the three-collection model, `AS-###` id discipline, story frontmatter, read-gate policy and write-authorization model are portable; the OIRP references and the closed-overlay narrative are instance. |
| `docs/backlog.md` (header + table shape) | one-line-per-item, never-reuse-an-id, renumber-notice discipline is portable; all rows are instance. |

### 1.3 TEMPLATE — generic structure, project content

| path | the template | the project content |
|---|---|---|
| `CLAUDE.md` | 7-chapter index-and-law shape: layout table → roster table → rules of engagement → working agreement → orchestration → environment → doc governance, each chapter naming its canonical doc | project name/description, the whole path→owner map, 5-member roster + tier order, carve-out list, stack versions |
| `.claude/agents/contract-owner.md` | boundary-owner + router role: own the interface files, publish before implement, review breaking-ness, route cross-tier, arbitrate, guard tier direction, + shared "Standing orders" + "Output" blocks | `contract/**`, OpenAPI 3.1/AsyncAPI 3.0/Spectral, `ddev contract-lint`, RFC 9457 |
| `.claude/agents/domain-engineer.md` | tier-2 implementer role | Laravel ^13.5 / PHP ^8.5 / Filament ^5 / Pest, `app/**`, the 9-item carve-out list, engine-bridge duty |
| `.claude/agents/data-engineer.md` | tier-3 persistence role | PostgreSQL 16 + Redis, `stancl/tenancy` schema-per-tenant, `tenants:drift-check`, `ddev psql` |
| `.claude/agents/platform-engineer.md` | tier-4 environment role | DDEV type laravel, PHP 8.5 nginx-fpm, PG 16, Redis noeviction, Node 22, python:3.12-slim + libreoffice-writer, 5 GitHub gates, `ddev poweroff && ddev start` |
| `.claude/agents/engine-engineer.md` | provider-bounded-context role beside the tiers | the entire 9-rule engine charter is OIR Flow's document engine |
| `.claude/agents/code-reviewer.md` | 3-lens read-only reviewer (SWE / AppSec / senior QA), no-write mandate, refute-your-own-finding rule, tracker-intake-shaped output, docs-agent handoff, 3-phase token budget (`3 × diff tokens`, floor 2k cap 60k) | `vendor/bin/pint`, `phpstan`, Spectral, schema-per-tenant IDOR phrasing, `docs/adr/` comment rule, `contract/` compatibility clause |
| `docs/architecture.md` | system doc shape: system → contract boundary → runtimes table → mechanism → layout tables → behaviour sequence → CI gate table, every claim citing a source path | 100% OIR Flow content |
| `docs/runbook.md` | runbook shape: per-runtime boot, daily command table, hook, test discipline, gate table, gotchas, each marked verified/UNVERIFIED | 100% DDEV/Laravel/OIR Flow |
| `docs/topology/local.md`, `docs/topology/preview.md`, `docs/ci/gitlab.md` | one-file-per-runtime and one-file-per-CI-host pattern (adding a runtime = one file + one table row) | DDEV, Compose preview, GitLab at `evogit.evozon.com` |

### 1.4 HOST — harness coupling, not project coupling

| path | coupling |
|---|---|
| `.claude/settings.json` | `defaultMode: bypassPermissions`, `skipDangerousModePermissionPrompt: true`, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, `model: opus`, `effortLevel: high`, `teammateMode: tmux`, `tui: fullscreen`, `theme: light`. Claude-Code-only keys; two of them disable permission prompts wholesale. |
| `CLAUDE.md` ch. 7 line `@docs/conventions/documentation-governance.md` | Claude Code auto-import syntax; inert text on any other host. |
| `.claude/agents/*.md` frontmatter `tools:` (only `code-reviewer` uses it) | Claude Code tool-allowlist field. |
| `.opencode/agents/*.md` frontmatter `mode: subagent`, `permission: edit: deny` | opencode fields; the equivalent of Claude's `tools:` line. |
| `.opencode/{package.json,package-lock.json,node_modules/}` | opencode runtime deps, 29 packages vendored into the repo. |
| `.claude/skills/task-orchestrator/references/routing-defaults.md` § Dispatch host adapter | tier→model mapping for Claude vs Grok; `reasoning_effort` quirks; `xhigh` clamping. |
| `.claude/workflows/*.js` | Claude Code `Workflow` script API (`meta`, `phase()`, `agent({schema, agentType, model, effort})`). |
| `docs/conventions/orchestration.md` § Model & effort, § Dispatch mechanics | names `Agent`, `SendMessage`, `TaskCreate`/`TaskList`, `Workflow`, worktree isolation, and the dated harness fact "`Agent` exposes `model` only" (2026-08-11). |

### 1.5 INSTANCE — OIR Flow only

| path | note |
|---|---|
| `docs/adr/0024…0058` (34 records, 15.5k tokens) | every record is a Laravel/PostgreSQL/tenancy/engine decision. Only 0024 (Workflow mandatory), 0026, 0027 (tracker as transit dir / input classes) encode framework rules. |
| `docs/debt/2026-08-18-OIRP-1.md`, `docs/debt/2026-08-21-session-improvements.md` (15.2k) | worked code-review outputs; valuable as format exemplars, worthless as content. |
| `.claude/plans/2026-08-2{0,1}-*.md` (3 files, 6.7k) | worked `task-orchestrator` PLAN outputs. |
| `.claude/workflows/session-improvements-oirp-21-23.js` (4.7k) | the only workflow script; its reusable half is the *pattern* (§4 I8). |
| `docs/document-engine-bridge.md` | the platform↔engine seam. |
| `docs/conventions/engineering-principles.md`, `docs/conventions/architecture-principles.md` (3.6k) | PHP/Laravel/Filament/Eloquent/Pest code law, down to advisory-lock ordinals and `fi-*` CSS classes. A stack pack, not framework core. |
| `docs/e2e-samples/import-contracte.md`, `docs/miscellaneous/**` (10.2k) | walkthroughs, C4 drafts, the Romanian project plan. |
| `docs/stories/as-reference/**` (8.1k, read-gated), `docs/stories/support/*.xlsx` (5 workbooks, 130KB) | historical stories + supplied domain data. |
| `docs/backlog.md` rows (BL-022…BL-040) | open project items. |
| `infra/**` (5,155 lines: 12 shell entrypoints, 8 GitLab YAML, DDEV stubs, 2 Compose stacks, 4 Dockerfiles, nginx/php-fpm/redis config) + `infra/README.md` | one project's runtime. The transferable ideas are extracted as §2 D5/D6. |

---

## 2. Dependency catalogue

Each entry: what binds, where, evidence, and the abstraction move.

### D1 — Project identity
- **Binds:** name "OIR Flow", slug `oir-flow`, DB `oirflow`/`oirflow_test`, tracker prefix `OIRP-`, Compose project `oir-flow-preview`, cache volume `oir-flow-ci-composer-cache`, container `ddev-oir-flow-engine`, host `evogit.evozon.com`, tenant slugs `oir-north-west`/`oir-south-west`/`oir-west`, dev password `oirflow-dev`.
- **Where:** 48 files. Density: `docs/debt/2026-08-18-OIRP-1.md` (35 hits), `.claude/workflows/*.js` (20), `docs/runbook.md` (13), `.claude/plans/*` (12/10/4), `infra/deploy/up.sh` (9).
- **Evidence:** `grep -rIc 'oir-flow\|oirflow\|OIR Flow\|OIRP-'`.
- **Move:** profile keys `project.name`, `project.slug`, `tracker.key_prefix`. Note: **`.claude/agents/**` and `.claude/skills/**` contain zero hits** — the harness layer is already free of project identity. The identity leak is in docs, infra, plans and workflows.

### D2 — Technology stack
- **Binds:** Laravel ^13.5, PHP ^8.5, Filament ^5, Pest, `stancl/tenancy` ^3.9, `spatie/laravel-permission` ^8.3, PostgreSQL 16, Redis 7.4.10 (`noeviction`), Node 22, Python ≥3.12 + FastAPI + uvicorn, libreoffice-writer, DDEV ≥1.23.5, Spectral, Pint, PHPStan/Larastan level 5, CaptainHook.
- **Where:** agent definitions carry it densely — `domain-engineer` 36 stack terms, `platform-engineer` 34, `data-engineer` 28, `engine-engineer` 18, `contract-owner` 12, `code-reviewer` 6, `docs-agent` 0. Skills: ≤1 each.
- **Evidence:** per-file term counts (`ddev|laravel|filament|pest|phpstan|pint|stancl|eloquent|artisan|composer|fastapi|python|php|spectral|openapi|postgres|redis|libreoffice|xlsx|docx`).
- **Move:** every agent definition splits into **role charter** (portable) + **stack pack** (per-project). The gradient above is the extraction order: `docs-agent` needs no work, `domain-engineer` needs the most.

### D3 — Ownership map
- **Binds:** `CLAUDE.md` ch. 1 (13-row layout table) and ch. 2 (6-row roster with a 9-entry carve-out list and per-file `config/` ownership).
- **Evidence:** every path named in ch. 1–2 except `infra/`, `.claude/`, `docs/`, `CLAUDE.md` is **absent from this tree** (17 missing: `.github`, `.ddev`, `app`, `tests`, `database`, `contract`, `engine`, `config`, `routes`, `resources`, `public`, `bootstrap`, `composer.json`, `phpunit.xml`, `phpstan.neon`, `captainhook.json`, `.env.example`).
- **Move:** the map is data, not prose. Profile supplies `members[].owns[]` / `.carve_outs[]`; the framework supplies the two invariants that make it work: *every path maps to exactly one owner*, and *tier membership follows what code does, not where it lives*. Both are portable rules stated in `CLAUDE.md` ch. 2 and `rules-of-engagement.md`.

### D4 — Tier model and the provider bounded context
- **Binds:** the 4-tier chain `contract-owner → domain-engineer → data-engineer → platform-engineer`, plus `engine-engineer` as a provider context *beside* the tiers reached only through one contract file; plus `code-reviewer` and `docs-agent` standing outside the order.
- **Where:** `CLAUDE.md` ch. 2, `docs/conventions/orchestration.md` § Tiers and direction (ASCII diagram), every agent's opening line ("second tier (contract → **domain** → data → platform)").
- **Move:** the *shape* (ordered tiers + N side contexts + 2 non-tier roles) is the framework's core topology and should be profile-driven (`tiers[]`, `side_contexts[]`). The *members* are project data. Decide whether "provider bounded context reached only through a published contract" is a first-class framework concept or an OIR Flow specialization (§6 Q4).

### D5 — Runtime topology
- **Binds:** DDEV local + Compose preview, `infra/ddev/` vs `infra/deploy/` vs `infra/shared/` split, `.ddev/` generated by `infra/ddev/bootstrap.sh`, verify-by-full-boot, `.env` volatility, engine has no hot reload.
- **Move:** the portable rules are: *one file per runtime under `docs/topology/`, adding a runtime costs one file plus one table row*; *runtime-agnostic inputs live once in a shared dir owned by no runtime*; *no runtime resolves a path into another runtime's directory*; *generated config is never hand-edited*; *verify a topology change by full boot, never restart*. Everything naming DDEV, Compose, uvicorn or Mailpit is instance.

### D6 — CI gate model
- **Binds:** 8 named gates (contract, engine, platform, seam, static-analysis, env-contract, deploy-stack, adr-citations); 12 scripts in `infra/ci/`; 8 thin GitLab YAML wrappers; `.github/workflows` declared non-live.
- **Move:** the portable rules are strong and should survive verbatim in spirit: **one script layer** (identical on laptop and CI host, YAML is a thin wrapper and never holds gate logic); **gates need Docker and nothing else** (no host npx/PHP/Python); **container-name-colliding gates serialize on a host lock**; **no gate filters by changed path — a gate that passes by absence is a defect**; **no gate starts/stops/deploys a runtime**; **a skipped stage must be a named skip, never a silent one**; **the env-contract gate asserts key sets both ways**. The gate *names* and their content are instance.

### D7 — Doc tree, whitelist, budgets
- **Binds:** the 14-entry allowed-write-path list and 11 per-file token budgets in `docs/conventions/documentation-governance.md`, plus the metric definition (`wc -w` × 4/3, ratified 2026-08-19).
- **Evidence:** whitelist names `docs/architecture-c4.md`, which does not exist; `docs/debt/` is listed twice; `docs/tracker/` and `docs/stories/as-is/` carry standing authorizations with named authorizing files.
- **Move:** the charter is CORE+; the path list and the budget numbers are profile data. Keep the mechanism intact: *the whitelist has exactly one canonical copy, and a path granted anywhere else is not a grant* — the `docs-agent` definition demonstrates this by pointing rather than restating, and `.opencode/agents/docs-agent.md` demonstrates the failure by restating (§5 H3).

### D8 — Artifact-type registry
- **Binds:** eight distinct doc artifact types with distinct write rules: ADR (`docs/adr/NNNN-slug.md`, ≤650 tokens, immutable, supersede-never-edit), story (`docs/stories/as-is/AS-###-slug.md`, frontmatter schema, delete-don't-tombstone), tracker intake (`docs/tracker/YYYY-MM-DD-<scope>-intake.md`, skill-authored, transit, never pruned), debt report (`docs/debt/YYYY-MM-DD-branch.md`, dated snapshot, retire-in-place, never rewrite a finding body), backlog (`docs/backlog.md`, one line per open item, ids never reused), intake channel (`docs/_intake.md`, append-only, drained-and-truncated), plan (`.claude/plans/`), workflow script (`.claude/workflows/`).
- **Move:** this registry is the framework's most valuable transferable asset after the skills. Abstract it as a table of `{path pattern, sole writer, authorization source, lifecycle class, budget}` — the lifecycle classes being **re-derivable/snapshot** (regenerate, never hand-edit) vs **non-re-derivable/sole-record** (write once, supersede, never regenerate) from ADR-0027, and **dated snapshot** (retire in place) from the debt rule.

### D9 — Domain language and locale
- **Binds:** Romanian throughout — `Panoul de control`, `Ofiter 1/2`, `Responsabil IER`, `dosar`, `esantion`, `nota justificativa`, `diffs_reproducere`, `NEPROVIZIONAT`, `TOPOLOGIE INCOMPLETĂ`; `APP_LOCALE=ro`; "Acceptance criteria in the input's language (Romanian to date)"; the `wc -c` warning about diacritics.
- **Move:** profile keys `docs.language`, `input.language`. Keep the portable rule from `as-is/README.md`: **acceptance criteria stay in the input's language**; framework prose stays in one declared language.

### D10 — Host harness coupling
- **Binds:** see §1.4. Two full copies of the roster exist (`.claude/agents/**`, `.opencode/agents/**`), and `rules-of-engagement.md` § Enforcement copies already names the resulting duty: "the harness owner keeps its copies in sync".
- **Move:** the framework must decide single-host or multi-host (§6 Q1). If multi-host, generate host copies from one role source + a host adapter descriptor (frontmatter field map, tool/permission vocabulary, model-slug map, effort-field support, dispatch primitives). Hand-maintained parallel copies have already drifted (§5 H3) — that is the empirical argument for generation.

### D11 — Instance corpus as worked examples
- **Binds:** ~57k tokens (57% of the corpus) is OIR Flow output: ADRs, debt reports, plans, the workflow script, e2e samples, miscellaneous, stories, backlog rows.
- **Move:** decide keep-as-`examples/` vs drop (§6 Q3). Recommendation: keep exactly one exemplar per artifact type (1 ADR, 1 debt report, 1 plan, 1 workflow script, 1 intake doc, 1 story), scrubbed or clearly fenced as example data, and drop the rest. That is ~6k tokens instead of 57k and preserves every format demonstration.

### D12 — Code-level and structural principle content
- **Binds:** `engineering-principles.md` + `architecture-principles.md` — 3.6k tokens of PHP/Laravel/Filament/Eloquent/Pest law (strict types, `final readonly`, advisory-lock ordinals, `insertOrIgnoreReturning` conflict targets, `fi-*` assertion rules, `Http::fake()` merge semantics).
- **Move:** these are a **stack pack**, addressed by the framework only structurally: the framework mandates *that* a project declares a code-level pack and a structural pack, each with a single canonical file, each pointed at (not restated) by every agent definition and by the reviewer. Their content is per-stack. Note the honest self-assessment already present in `architecture-principles.md` § What enforces this ("Nothing mechanically enforces this file… it holds by review and roster write permissions") — that candour is itself a portable convention: **name the enforcement mechanism when claiming enforcement**.

---

## 3. Project profile — the instantiation input

The abstraction needs one declarative input per project. Minimum key set, derived from D1–D12:

```yaml
project:
  name: "OIR Flow"                     # D1
  slug: oir-flow
  description: "multi-tenant CR/CP sampling platform"
  docs_language: en                    # D9
  input_language: ro
  tracker: { key_prefix: OIRP, host: jira }

topology:                              # D4
  tiers: [contract-owner, domain-engineer, data-engineer, platform-engineer]
  side_contexts:
    - { member: engine-engineer, reached_through: contract/engine.openapi.yaml }
  outside_order: [code-reviewer, docs-agent]

members:                               # D2, D3
  - name: domain-engineer
    tier: 2
    stack: [Laravel ^13.5, PHP ^8.5, Filament ^5, Pest]
    owns: ["app/**", "routes/**", "resources/**", "..."]
    carve_outs_to: { data-engineer: ["app/Tenancy/**", "..."] }
    verify: ["<test command>"]
    conventions: [docs/conventions/engineering-principles.md]

boundary:                              # D1, D2
  interface_paths: ["contract/**"]
  formats: [OpenAPI 3.1, AsyncAPI 3.0]
  lint: { tool: spectral, command: "<in-container command>" }
  error_model: RFC 9457
  versioning: semver in info.version

runtimes:                              # D5
  - { id: local, doc: docs/topology/local.md, boot: "<command>", verify: full-boot }
  - { id: preview, doc: docs/topology/preview.md, boot: "<command>" }
  shared_inputs_dir: infra/shared/

ci:                                    # D6
  host_doc: docs/ci/gitlab.md
  script_dir: infra/ci/
  gates: [{ name: contract, proves: "...", serialized: false }, ...]
  lock: infra/ci/lock.sh

docs:                                  # D7, D8
  metric: "wc -w * 4/3"
  sole_writer: docs-agent
  role_gate_line: "ROLE: docs-agent"
  worker_channel: docs/_intake.md
  write_paths: [ { path: docs/architecture.md, budget: 2800 }, ... ]
  artifact_types:
    - { type: adr, path: "docs/adr/NNNN-slug.md", budget: 650, lifecycle: immutable }
    - { type: story, path: "docs/stories/as-is/AS-###-slug.md", lifecycle: living }
    - { type: intake, path: "docs/tracker/YYYY-MM-DD-<scope>-intake.md", lifecycle: transit }
    - { type: debt, path: "docs/debt/YYYY-MM-DD-<branch>.md", lifecycle: dated-snapshot }
  read_gated: [ { path: docs/stories/as-reference/, grant: "HISTORY-ACCESS:" } ]

policy:                                # D5, and working-agreement
  never_push: true
  commit_only_on_request: true
  destructive_ops: ["<project's list>"]
  verify_against_real_services: true

hosts:                                 # D10
  - { id: claude-code, dir: .claude/, frontmatter: {tools: list}, effort_field: workflow-only }
  - { id: opencode,   dir: .opencode/, frontmatter: {mode: subagent, permission: map} }
  - { id: grok,       dir: .grok/,     model_map: {haiku: grok-4.5, sonnet: grok-4.5, opus: grok-4.6} }
```

Everything in §1.1–1.2 consumes this profile and nothing else. Everything in §1.3 is a template
rendered from it.

---

## 4. Invariants the abstraction must preserve

These are the framework's actual intellectual property. An abstraction that keeps the file
layout but loses these has kept nothing.

- **I1 — One canonical location.** Each rule lives in exactly one file; every other file points
  at it. Stated in `documentation-governance.md` § Writing rules and demonstrated by
  `docs-agent.md` refusing to restate the whitelist ("a second copy is a second thing to
  update and this one had already diverged").
- **I2 — Single doc writer, append-only worker channel.** Workers never write `.md`; their only
  channel is appending a 3-line `AFFECTS/CHANGE/SOURCE` entry to `docs/_intake.md`. Creating a
  summary/notes/handoff file is a task failure *even if the task succeeded*.
- **I3 — Role gate by exact line.** docs-agent authority exists only while the task prompt
  carries the literal line `ROLE: docs-agent`. No other phrasing qualifies.
- **I4 — Intake entries are claims, not commands.** The docs-agent verifies each against its
  SOURCE before merging; conflicts are cited for human decision, never resolved silently, never
  written into a doc as a marker.
- **I5 — Exhaustive, single ownership.** Every path maps to exactly one owner; git-ignored
  artifacts follow their source manifest's owner; tier membership follows what code does, not
  where it lives; `config/`-style dirs are owned per file.
- **I6 — Tier direction.** Requirements flow down only; a lower tier never edits a higher tier's
  files and never demands upward change directly; cross-tier needs travel as tasks through the
  boundary owner. A diff spanning two ownership areas is two tasks.
- **I7 — Contract-first.** No cross-member dependency without a published interface first;
  "implement first, spec later" is rejected; the interface file is the single source of the seam
  version.
- **I8 — Workflow trust rules.** `Workflow` is mandatory when members, order and gates are known
  before dispatch; `Agent` is the discovery exception, claimed at dispatch. Gate on evidence,
  never on a stage returning text (the `LANDED FILES:`/`landedFiles` requirement — "a stage
  claiming success with an empty landedFiles list is treated as a failed gate"); confirm plan
  mode ended before dispatching writers; know machine-wide serialization before parallelizing;
  green-by-absence is a defect — a skipped stage must be distinguishable from a passed one.
- **I9 — Model and effort at dispatch, not in definitions.** Agent definitions pin neither;
  resolution is dispatch override → frontmatter → inherit. Cheapest tier that can pass on the
  first try; escalate one tier after one same-tier retry; two-tier failure is a spec problem.
- **I10 — Items ≠ tasks.** Intake preserves source granularity and assigns no route/model/effort/
  wave; decomposition happens behind the orchestrator's approval gate. The word "task" never
  appears in an intake document, and the doc opens with a PLAN-mode directive so a normalized
  backlog can never be mistaken for an approved plan.
- **I11 — Two-stage approval.** PLAN always ends at an approval gate; DISPATCH only starts from
  an approved plan; never both in one uninterrupted pass. Scope discovered mid-run goes back
  through PLAN, never gets absorbed.
- **I12 — Traceability chain.** Source key survives from intake item → plan `Source` column →
  run manifest, so a closed-out run maps back to the item it came from. Minted keys are unique
  only within their document and are cited qualified (`<doc-stem>#ITEM-001`) outside it.
- **I13 — The reviewer owns nothing.** Read-only across the whole tree including `.md` and
  `docs/_intake.md`; never fixes what it finds, not even one line; findings emitted as fielded
  item blocks, never prose; "not being able to modify anything is the point". Findings travel
  verbatim to the docs-agent for persistence.
- **I14 — Refute before reporting.** Every finding names file, line and the reachable path;
  framework/package code counts as a guard and must be read, not assumed; a wrong finding costs
  more than a missed one.
- **I15 — Convention beats principle.** Where a general principle collides with an established
  codebase convention, the convention wins — flag the collision, never resolve it silently.
  Present in all 7 agent definitions.
- **I16 — Verify against reality.** Real services, not simulations; full boot after topology
  change; report failures as failures with output; name skipped steps as skipped.
- **I17 — Version-control discipline.** Never push; commit only on explicit request; destructive
  operations need an explicit user-approved task. Binds lead and members alike.
- **I18 — Budgets with an escape hatch.** Every doc file has a token budget under one declared
  metric; on overrun, compress first — and if fidelity cannot survive the cut, **report the
  overrun instead of forcing it**. Compaction's governing rule is the same: fidelity beats
  compression, conflicts are surfaced, nothing is hard-deleted.
- **I19 — Input classes decide regeneration.** Re-derivable input (export, query, API pull) is a
  snapshot: regenerate, never hand-edit. Non-re-derivable input (paste, verbal decision,
  screenshot) is a sole record: write once, supersede, never regenerate over. Dated snapshots
  (reviews) retire in place and their finding bodies are never rewritten.
- **I20 — New files need human authorization.** A new file in the doc tree requires an explicit
  human instruction naming it, except where governance records a standing authorization naming
  the authorizing file. Agents do not create doc files on their own judgement; workers may not
  even request one.
- **I21 — One harness dir per orchestrating agent.** `.claude/`, `.opencode/`, `.grok/` — outside
  the roster; no member writes them; each agent writes only its own.
- **I22 — Name the enforcement mechanism.** When a convention claims to be enforced, it names
  the gate/test/construction that enforces it — or states plainly that nothing does.

---

## 5. Extraction hazards

| id | hazard | evidence | consequence for the abstraction |
|---|---|---|---|
| H1 | **249 dangling path references.** The doc corpus is anchored to code that is absent: 115 into `app/`, 41 `tests/`, 32 `engine/`, 22 `database/`, 8 `config/`, 3 `contract/`, 3 `resources/`, 2 `public/`, 1 each `routes/`, `bootstrap/`, `infra/`. | resolved 377 unique path refs across all `.md` (excluding `as-reference/`); 249 do not exist | every citation-carrying claim in `architecture.md`, `runbook.md`, both principle docs, the ADRs and the debt reports is unverifiable in this tree. The framework's own rule "reference source files by path; never embed" produces exactly this failure when the referent is left behind. The abstraction must either drop the claim or move it into a fenced example. |
| H2 | **20 dangling doc references.** Deliberate (documented in governance § Removed documents): `docs/tenancy.md`, `team.md`, `orchestration.md`, `blueprint.md`, `user-stories.md`, `prerequisites.md`, `docs/legacy/`. Extraction casualties (undocumented): all 6 `docs/tracker/*-intake.md`, `docs/stories/as-is/AS-002`, `AS-019-…`, `AS-022-…`, `docs/architecture-c4.md`, `docs/adr/0039` (bare, no extension), `docs/archive/`. | `docs/tracker/` and `docs/stories/as-is/` are empty but for a README; whitelist names `architecture-c4.md`; `support/README.md` cites two tracker intakes and an `epic3.md` that exist nowhere | the tracker→plan→manifest traceability chain (I12) is broken at its first link. The abstraction should ship these directories empty-with-README (as here) and make the missing-referent case explicit rather than silent. |
| H3 | **Parallel roster copies have drifted.** `.opencode/agents/*` are a stale port: all 6 non-reviewer definitions lack the comment-discipline standing order; `docs-agent` inlines the whole whitelist in its `description` and body (directly violating I1) and cites ADR-0027 where `.claude` cites the governance §; `code-reviewer` swaps `SendMessage` delivery for final-response delivery and drops the comment-discipline lens. | `diff .claude/agents/X .opencode/agents/X` for all 7 | hand-maintained per-host copies drift within days. Generate host copies from one role source (§6 Q1). |
| H4 | **Permission posture is inherited silently.** `.claude/settings.json` sets `defaultMode: bypassPermissions` **and** `skipDangerousModePermissionPrompt: true` alongside `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. | file contents | a framework that ships this file makes every adopting project unattended-write-capable by default. Make it an explicit, documented choice, not a default. |
| H5 | **A skill points at a non-existent host path.** `user-stories-use-cases` Step 1 says to read uploads from `/mnt/user-data/uploads/` — a claude.ai path, absent in Claude Code CLI. | `SKILL.md` § Step 1 | host-specific I/O assumptions inside skills must move to the host adapter. |
| H6 | **A skill embeds a project ruling.** `docs-compaction` carries the metric "ratified 2026-08-19", the Romanian-diacritics rationale, `docs/archive/` and a pointer into the project's budget table. | `SKILL.md` §§ 1, 4 | the most portable-looking layer still leaks. Re-audit all four skills against the profile, not just the two obvious ones. |
| H7 | **The ADR index contradicts itself.** README prose: "0036–0054 are reserved, never issued… the pointer moved straight from 0035 to 0055". Tree: 19 accepted records numbered 0036–0054, all rowed in the same table. Separately, `0032-localize-human-facing-filament-routes.md` exists with no index row (known as BL-025). | `ls docs/adr` (34 records + template); index-coverage check | the ADR numbering discipline is portable, but do not carry this index over as an exemplar. Fix or drop. |
| H8 | **The whitelist has a duplicate and a phantom.** `docs/debt/` appears twice in § Allowed write paths; `docs/architecture-c4.md` is whitelisted but absent. | governance § Allowed write paths | the canonical list is the mechanism's single point of failure (I1) — the abstraction should validate it mechanically (every whitelisted path exists or is declared "may not exist yet"). |
| H9 | **Dated harness facts age silently.** `orchestration.md` § Model & effort pins "Harness mechanics (2026-08-11): `Agent` exposes `model` only; `Workflow`'s `agent()` exposes `model` and `effort`" as a load-bearing reason to prefer `Workflow`. | that section | host capability claims need a dated, re-verifiable home in the host adapter, not inside portable doctrine. |
| H10 | **Domain data rides along.** `docs/stories/support/` holds 5 real `.xlsx` workbooks (130KB) declared canonical over copies in absent test trees. | `support/README.md` | exclude from the framework; the *rule* (supplied material is sole-record, nobody writes it, copies derive from it) is portable. |

---

## 6. Open decisions — human input needed before abstraction

| id | question | why it blocks | default if unanswered |
|---|---|---|---|
| Q1 | Single-host (Claude Code) or multi-host (Claude + opencode + Grok)? | decides whether `.opencode/`/`.grok/` copies are generated from one source or dropped; H3 is the empirical argument for generation | generate from one source; ship the Claude host adapter, keep opencode/Grok adapters as declared-but-unbuilt |
| Q2 | Is the 4-tier + provider-context roster the framework's default shape, or fully data-driven (N members, N tiers)? | decides whether role charters are 7 files or a generator over `members[]` | data-driven, with the OIR Flow roster as the shipped example profile |
| Q3 | Keep the OIR Flow instance corpus (~57k tokens) as `examples/`, or drop it? | it is 57% of the corpus; keeping it wholesale defeats the token discipline the framework itself preaches | keep one exemplar per artifact type (~6k), drop the rest |
| Q4 | Is "provider bounded context reached only through a published contract" a first-class framework concept, or an OIR Flow specialization? | decides whether `engine-engineer` becomes a role template or an example | first-class concept, `engine-engineer` shipped as its example instantiation |
| Q5 | Do the stack-specific principle docs become per-stack packs shipped with the framework (a `php-laravel` pack), or stay entirely project-authored? | 3.6k tokens of proven code law is valuable; carrying it makes the framework stack-opinionated | project-authored; the framework mandates the slot and the pointing discipline only |
| Q6 | Does the framework mandate docs in one declared language with ACs in the input language (the current rule), or English-only? | affects the compaction metric, story format and every template | keep the current two-language rule (I9/D9) |
| Q7 | Does the framework carry `infra/**` at all, or only the CI/runtime *rules* (D5/D6)? | 5,155 lines of one project's shell is not a framework | rules only; `infra/**` becomes a documented pattern plus at most one skeleton gate script |

---

## 7. Handoff to `create-the-framework-abstraction`

What the next prompt receives from this document:

1. **A verdict per path** (§1) — CORE / CORE+ / TEMPLATE / INSTANCE / HOST, with the specific
   lines to excise for every CORE+ file.
2. **A dependency catalogue** (§2, D1–D12) — each with paths, evidence and an abstraction move.
3. **A profile schema** (§3) — the complete instantiation input; nothing outside it may be
   hardcoded in a CORE or TEMPLATE file.
4. **22 invariants** (§4) — the acceptance criteria for the abstraction. An abstraction is
   correct only if each one is still stated exactly once, in exactly one canonical file, and
   pointed at from everywhere it binds.
5. **10 hazards** (§5) — pre-existing defects in the corpus. Do not carry them forward, and do
   not use H3/H7/H8 files as format exemplars.
6. **7 open decisions** (§6) with defaults — proceed on the defaults if the human is silent, and
   state which default was taken.

Suggested first three moves for the abstraction (non-binding):

- Extract the **shared standing-orders block** — it is byte-repeated across all 7 agent
  definitions (contract-first / tier direction / never push / autonomous+faithful reporting /
  documentation worker / comment discipline / convention-wins) and is the single largest
  duplication in the harness layer. One source, rendered per member.
- Split each agent definition into `role.md` (portable charter, `Output` block included) +
  `stack.md` (project pack), using `.claude/agents/docs-agent.md` as the reference for how much
  a definition can point at instead of restate (D2 gradient: docs-agent 0 stack terms →
  domain-engineer 36).
- Move the whitelist, budgets, artifact-type registry and destructive-op list out of prose into
  the profile, and add a mechanical validator over them (answers H8 directly, and lets
  `docs-compaction` read budgets from data instead of from a doc it also rewrites).
