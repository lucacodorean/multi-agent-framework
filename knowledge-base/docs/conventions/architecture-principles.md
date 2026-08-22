# Architecture principles

**Stub — this slot is empty and must be filled per project.**

This file is the project's `conventions.structural` slot
(`framework/contracts/project-context.schema.md`). The framework mandates that the slot exists
and that every role points at it; it never supplies the content.

## What belongs here

How modules, boundaries and dependencies relate. How the codebase is organized and by what
principle; which direction dependencies run; what each module publishes and what stays internal;
where ports are declared and where implementations are bound; what an entry point may and may
not do; how persistence and state are shaped; where delivery concerns stop.

## What does not

- Class and method-level discipline — that is `engineering-principles.md`, the
  `conventions.code_level` slot.
- The boundary between members, and the interface contract itself — those are framework rules
  plus `project-context/conventions.md`, and are not restated here (FI-01).

## Rules for filling it

- Terse directives, imperative voice, one rule per line.
- Cite the code that demonstrates a rule by path; never paste it.
- **Name the enforcement mechanism for each rule (FI-22).** Structural rules are the ones most
  often assumed to be enforced by tooling that does not exist — if nothing checks imports, say
  so, and say what holds the rule instead: review, write permissions, or construction.
- Record divergences explicitly, with the path that diverges.

## Who reads it

Every role charter cites it through `{{member.conventions}}`, and the code reviewer judges
separation of concerns against it. Until it is filled, that citation resolves to this stub.
