# 0024 — Workflow is mandatory for deterministic multi-member orchestration

- Status: accepted
- Date: 2026-08-11

## Context

Multi-member work reaches the roster through two dispatch paths: the `Agent` tool and the
`Workflow` tool (`CLAUDE.md` ch. 5). They are not equivalent.

- Two authoritative-looking instruction channels exist — the task board and the message
  channel. A member acts on the one visible to it, so ordering requested by message is not
  enforced. A pipeline stage enforces sequence structurally; a message only asks for it.
- The `Agent` tool exposes `model` only; per-stage `effort` exists solely in `Workflow`'s
  `agent()`. Hand-dispatch cannot implement the per-task effort half of the model & effort
  policy.
- Ownership records name a role; task assignment resolves that role to an instance. Nothing
  keeps them in step, and a workflow-spawned member is often unaddressable from outside the
  workflow.
- A hand-dispatched sequence leaves no structural record of what did not run: a skipped
  stage, a never-claimed task, and a stage that ran and passed are indistinguishable
  afterwards.

## Decision

- Use `Workflow` whenever the members, their order and their gates are known before
  dispatch. Hand-sequencing that work with `Agent` + `SendMessage` is a defect.
- Dispatch by `Agent` only for genuine discovery — where each brief depends on what the
  previous one found — and claim the exception in one sentence at dispatch.
- Treat hybrid as the normal shape: scout with `Agent`, pipeline the known work with
  `Workflow`.
- Route a finding destined for a workflow-spawned member as a task, which survives an exited
  reader; never as a message.
- State the forfeit when an `Agent` dispatch gives up an intended effort assignment.

## Consequences

- Sequence, gates and per-stage effort become enforceable rather than remembered.
- The script becomes the record of what was supposed to run, making a skipped stage
  distinguishable from a passed one.
- Scripting costs authoring effort up front; discovery work must be claimed out loud instead
  of defaulted into.
- The operative rules live in `docs/conventions/orchestration.md`; this record holds only
  the rationale. Supersede this ADR rather than editing it.
