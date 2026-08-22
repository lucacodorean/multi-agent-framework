# Engineering principles

**Stub — this slot is empty and must be filled per project.**

This file is the project's `conventions.code_level` slot
(`framework/contracts/project-context.schema.md`). The framework mandates that the slot exists
and that every role points at it; it never supplies the content, because code-level discipline is
a property of the stack and the codebase, not of the framework.

## What belongs here

How one class, one method, one file is written. Naming, size and responsibility limits; state
and immutability; error and refusal vocabulary; transaction and locking discipline; extension
and inheritance rules; comment discipline; test discipline.

## What does not

- Module, boundary and dependency rules — those are `architecture-principles.md`, the
  `conventions.structural` slot.
- Anything the framework already states. A rule that holds for every project is a framework
  rule, and restating it here puts one rule in two files (FI-01).

## Rules for filling it

- Terse directives, imperative voice, one rule per line.
- Cite the code that demonstrates a rule by path; never paste the code (FI-01).
- At most one canonical example per convention.
- **Name the enforcement mechanism for each rule — the gate, test or construction that enforces
  it, or state plainly that nothing does (FI-22).** A rule claiming enforcement it does not have
  is worse than an unenforced one.
- Record the divergences the codebase actually contains. A principle the tree violates in nine
  places is documented as a divergence, not asserted as a rule.

## Who reads it

Every role charter cites it through `{{member.conventions}}`, and the code reviewer reports
against it. Until it is filled, that citation resolves to this stub — which is honest, and is
the reason the stub exists rather than the file being absent.
