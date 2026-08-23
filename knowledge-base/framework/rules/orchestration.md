# Orchestration

Framework rule. Project values: `project-context/ownership.md`, `project-context/ci.md`. Harness
spellings: `framework/hosts/`.

## Operating model

- The lead session decomposes each request and routes by ownership. The path → owner map is
  `project-context/ownership.md` (FI-05).
- Route build work through the roster. The lead builds directly only for trivial single-file
  edits, reading, reporting and answering questions.
- One member, discovery-shaped work → a single agent dispatch, `subagent_type` = the member's
  binding name.
- Several members, shape emerging as it goes → named teammates plus messages, tracked as tasks.
- Several members, shape known before dispatch → a deterministic pipeline (FI-08).
- The lead integrates, verifies against the published interface version, and reports. A
  member's report is input to verification, never a substitute for it.
- Every run ends with a doc checkpoint dispatched to `docs.sole_writer` (FI-02).
- Which channel any need travels through — requirement, constraint, doc impact, review, report,
  checkpoint, escalation — is `rules/agent-communication.md`. There are no others.

## Tiers and direction

`roster.tiers` in order, highest first. `roster.side_contexts` sit beside the
tiers, each reached only through its `reached_through` interface.
`roster.outside_order` stand outside the order entirely.

- FI-06 governs direction. A constraint that blocks a higher tier is raised as a task to the
  boundary owner, who arbitrates; a ruling worth keeping becomes a decision record.

## Contract-first sequence

1. The boundary owner changes the interface and lints it (`commands.contract_lint`).
2. The boundary owner opens one scoped task per affected member, each citing the published
   interface version.
3. Members build to that version. Defects return as tasks; an implementation never diverges
   from the published interface to make itself work (FI-07).

## Deterministic pipelines

- The test is whether members, order and gates were known before dispatch — not task count and
  not size. Three known tasks are a pipeline; one task with an unknown follow-up is not.
- Open-ended dispatch is justified only by genuine discovery — each brief depends on what the
  previous one found — and is claimed at dispatch.
- Hybrid is the normal shape: scout open-ended, pipeline the known work.
- Pipeline artifacts live under the orchestrating agent's own harness directory (FI-21).
- Isolate working copies whenever two members of the same tier mutate files in parallel;
  serialize instead when they would touch the same paths.
- The four rules that make a pipeline trustworthy are FI-08. Gate on an explicit landed-files
  block; a stage claiming success with an empty list is a failed gate.
- Serialization that binds the machine (`ci.lock`, single-suite locks) binds pipeline
  stages too. Know it before parallelizing.

## Dispatch mechanics

- Give a single-member dispatch a stable name; continue it by message instead of respawning.
- Stand a named member down explicitly before spawning a replacement. Idle is not stood down.
- Members run in the background; the lead is notified and relays results.
- Encode timing and resource constraints as task dependencies, never as prose in a description.

## Model and effort

FI-09. Framework tiers are `cheap`, `standard`, `top`; framework efforts are `low`, `medium`,
`high`, `xhigh`. A harness identifier appears only in a `## Model map`
(`framework/contracts/host-adapter.schema.md`).

- Default: inherit from the lead session.
- Mechanical, well-specified work → a cheaper tier and/or `low`.
- Interface design, breaking-change review, arbitration, root-cause debugging → inherit the
  tier, raise the effort.
- Verification and adversarial stages → inherit the tier, the highest effort the stage merits.
- A dispatch that cannot express an intended effort says so at dispatch. Which host can
  express what: `framework/hosts/` § Effort map.
- A role that consistently warrants a non-default assignment gets it pinned in that member's
  binding frontmatter — nowhere else.
