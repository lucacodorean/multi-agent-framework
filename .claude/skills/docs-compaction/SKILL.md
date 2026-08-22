---
name: docs-compaction
description: Compact project documentation accumulated during development to reduce token usage in future sessions, while preserving all normative content (principles, rules, conventions, architectural decisions, workflows) with full fidelity. Use this skill whenever the user wants to shrink, trim, clean up, deduplicate, or reorganize project docs, the index-and-law file, decision records, convention files, or blueprints; complains about context bloat, token usage, or docs "getting too long"; or asks to prepare documentation for continued AI-agent work. Trigger even if the user doesn't say "compact" — phrases like "our docs are a mess", "CLAUDE.md is huge", "reduce context size", or "clean up the documentation before we continue" all apply.
---
 
# Documentation Compaction
 
Compress a project's accumulated documentation so future sessions spend fewer
tokens loading context — without losing a single rule, convention, or decision.
 
The core tension: compression saves tokens, but documentation exists to constrain
behavior. A rule that gets compressed into ambiguity is worse than a verbose one.
So the governing principle is: **when compression and fidelity conflict, fidelity
wins.** Every step below exists to enforce that.
 
## Scope
 
Operate on documentation loaded or referenced during development: the paths in
`{{docs.write_paths[]}}`, plus the project's index-and-law file, READMEs and agent
instruction files. Exclude source code, generated artifacts, and third-party docs.
Framework-core files (`knowledge-base/framework/**`) are out of scope: they are compacted by their
maintainers, not per project.
 
If the user names specific files, restrict to those. If not, discover the set
yourself in the inventory step and confirm it with the user before editing.
 
## Process
 
Work through these six steps in order. Do not skip the verify step — it is the
only thing that catches semantic loss introduced in step 3.
 
### 1. Inventory
 
List every documentation file with an approximate token count and a one-line
purpose. The metric of record is `{{docs.metric}}` — use no other, and read the
project's own note there before substituting a cheaper estimate. Budgets in
`{{docs.write_paths[]}}` are enforced against that metric. Flag duplicates, stale
files, and overlapping content. Present the inventory and the proposed scope before editing
anything — the user may know that some file is load-bearing for tooling or CI.
 
### 2. Classify content
 
Classify per section, not per file — most files mix categories.
 
- **Normative** — rules, constraints, conventions, principles, decision outcomes,
  workflows, invariants. Must survive with meaning fully intact.
- **Descriptive** — rationale, background, narrative, exploration history.
  Compress aggressively or archive.
- **Redundant / stale** — superseded decisions, duplicated rules, outdated
  references. Remove from active docs; archive.
When unsure whether something is normative, treat it as normative. The cost of
keeping a few extra lines is small; the cost of a lost constraint is a future
agent violating it.
 
### 3. Compact
 
Apply these transformations:
 
- **Rewrite normative content as terse directives.** Imperative voice, one rule
  per line. Zero semantic drift — rephrasing must not weaken, broaden, or narrow
  any rule. "Prefer X where sensible" and "always use X" are different rules;
  do not convert one into the other.
- **Keep at most one canonical example per convention.** Drop the rest. Pick the
  example that exercises the most edge cases.
- **Reference, don't embed.** Replace embedded code snapshots, schema dumps, and
  architecture descriptions with pointers to the source of truth (file paths,
  ADR IDs). Embedded copies rot; references don't.
- **Deduplicate.** Each rule lives in exactly one place; every other location
  points to it. If two copies of a rule differ subtly, that's a conflict — see
  step 4.
- **Collapse history into state.** Changelog-style narration ("we first tried X,
  then switched to Y because...") becomes a one-line current-state statement,
  with the rationale archived or referenced.
- **Merge fragmented files** where it reduces per-file overhead, but leave a
  pointer stub at any old path that other docs, tooling, or agent configs
  reference. A broken doc link in CI or an agent config is a regression.
### 4. Safety
 
- Move all removed content to `{{docs.archive_dir}}` (or an equivalent the user names).
  Never hard-delete — compaction should be reversible.
- If two rules conflict, do not resolve the conflict silently, even when one
  side looks obviously newer or better. Keep both, mark with `CONFLICT:`, and
  list them in the report for human decision. Silent resolution is how a
  compaction pass quietly changes project policy.
- Do not invent, infer, or "improve" rules. Compaction only. New content is
  limited to structural glue: headings, pointer stubs, the archive index.
### 5. Verify
 
This is the load-bearing step. Re-read the compacted active set as if you were a
fresh agent with no other context, and check that you could:
 
- follow every coding convention exactly as before,
- respect every architectural constraint,
- execute every documented workflow end to end,
- answer "why" questions at least by following a reference to archived rationale.
For each normative item identified in step 2, confirm it is still present and
unweakened in the active set. If anything normative now exists only in the
archive, restore it. If a compacted phrasing is ambiguous where the original was
not, revert that phrasing.
 
### 6. Report
 
Produce a compaction report containing:
 
- per file: before/after token estimate, and what was merged, archived, or
  removed, with a one-line reason;
- totals: overall before/after and percentage reduction;
- the list of `CONFLICT:` items awaiting decision;
- anything you were uncertain about, surfaced rather than decided unilaterally.
## Token budget (optional)
 
If the user gives a hard target ("active set under N tokens"), treat it as a
goal, not a license for lossy cuts. If the target is unreachable without
violating fidelity, report the floor you reached and what a further reduction
would cost — let the user make that trade.
 
If no target is given, don't force one. Report the achieved reduction and stop
when further compression would start trading away clarity.
 
## Hard constraints
 
- Zero loss of normative meaning. Fidelity beats compression, always.
- No new content beyond structural glue.
- Ambiguity and conflicts are surfaced, never silently resolved.
- Nothing is hard-deleted; the archive makes every change reversible.
