# Documentation governance — moved

Pointer stub. Other documents, ADRs, agent configs and CI scripts cite this path, so it stays.

- Rules (roles, worker rule, intake format, doc-writer charter, procedure, writing rules,
  budgets, new-topic rule): `framework/rules/documentation-governance.md`.
- Artifact lifecycles and identifier discipline: `framework/rules/doc-artifact-registry.md`.
- Project values — allowed write paths and their budgets, the token metric, artifact types,
  read-gated paths, removed documents: `project-context/docs-policy.md` (§ Allowed write paths
  is the only copy of the whitelist).
= "multi-agent-framework"): catalogue what in this extracted harness is bound to OIR Flow, formatted so the sibling prompt's agent can genericize it. If that reading is wrong, the §-structure survives a re-aim; the evidence gathering doesn't need redoing.

What the analysis contains (7 sections, all claims path-cited and machine-verified where possible):

1. Per-path verdicts — CORE / CORE+ / TEMPLATE / INSTANCE / HOST across all 162 files, with the exact lines to excise from each CORE+ file.
2. Dependency catalogue D1–D12 — identity, stack, ownership map, tier model, runtime, CI gates, doc whitelist/budgets, artifact-type registry, language, host coupling, instance corpus, stack principle packs.
3. A profile schema — the single declarative input the abstraction should render everything from.
4. 22 invariants — the framework's actual IP, stated as acceptance criteria for the abstraction.
5. 10 hazards — pre-existing defects not to carry forward.
6. 7 open decisions with defaults.
7. Handoff contract + three suggested first moves.

The findings that most shape the abstraction:

- The harness layer is already project-clean; the docs layer is not. .claude/agents/** and .claude/skills/** contain zero occurrences of oir-flow|oirflow|OIR Flow|OIRP-. Stack coupling, however, is steeply graded: domain-engineer 36 stack terms, platform-engineer 34, data-engineer 28, engine-engineer 18, contract-owner 12, code-reviewer 6, docs-agent 0. That gradient is the extraction order, and docs-agent.md is the reference for how much a definition can point at instead of restate.
- 249 of 377 unique path references resolve to nothing — 115 into app/, 41 tests/, 32 engine/, 22 database/. The corpus is written as verifiable claims about code that was left behind, so architecture.md, runbook.md, both principle docs, 34 ADRs and 2 debt reports are unverifiable in this tree.
- The parallel roster copies have already drifted. All 6 non-reviewer .opencode/agents/* lack the comment-discipline standing order; its docs-agent inlines the whole whitelist (violating the framework's own one-canonical-copy rule, which .claude's copy explicitly obeys and explains). That is the empirical case for generating host copies rather than hand-keeping them.
- 57% of the corpus (~57k of ~100.5k tokens) is instance output — ADRs, debt reports, plans, the workflow script, samples, stories. Keeping one exemplar per artifact type costs ~6k and loses no format demonstration.

I wrote the deliverable into prompts/ rather than docs/ deliberately: docs/** is governed by the documentation-governance whitelist and writable only by the docs-agent, and this artifact is prompt output, not project documentation.

✻ Worked for 8m 3s

※ recap: Goal is to genericize this extracted multi-agent framework off OIR Flow; I finished the dependency analysis and wrote it to prompts/2026-08-22-project-specific-dependencies-analysis.md. Next: confirm my derived reading, since both prompt files are empty, then run the abstraction prompt. (disable recaps in /config)

❯ Use the generated report for @prompts/2026-08-22-create-the-framework-abstraction.md
Read prompts/2026-08-22-create-the-framework-abstraction.md (93 lines)
