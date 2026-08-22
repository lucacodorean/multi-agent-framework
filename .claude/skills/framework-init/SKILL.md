---
name: framework-init
description: Stand up the multi-agent knowledge base in a repository — fill its project context, render the roster's agent bindings for every host, create the documentation tree, and verify the whole thing with the validator. Use this whenever someone wants to set up, initialize, bootstrap, instantiate, adopt, onboard or vendor the framework into a project, wire the agents up for a new codebase, or fill in project-context; and also when they describe the goal without naming it — "get the agents working on this repo", "point the framework at my project", "why can't I dispatch domain-engineer here", "the context files are all stubs". Reach for it too when a validator run reports missing context files, unrendered bindings, or an undeclared documentation policy, since those are the symptoms of an uninitialized or half-initialized unit.
---

# Framework init

Turn a vendored knowledge base into a working one: a filled context, dispatchable agents, a
documentation tree, and a green validator.

The work splits cleanly in two, and keeping the halves apart is what makes this trustworthy:

- **Mechanical** — the file set, the team, the host wiring, the stack, the commands. All of it is
  derivable from something that already exists, so derive it and show your work.
- **Judgement** — who owns which paths, what the interfaces are, what conventions bind the code,
  what the domain words mean. A wrong guess here does not produce a bad file; it produces a rule
  every future agent in this repository will obey. So propose, cite evidence, and let a human
  decide.

Run in two phases, always in this order: **PROPOSE**, then a gate, then **APPLY**. Never fold
them into one pass. The framework's own orchestration works this way for the same reason — the
gate is where a human corrects an assumption cheaply, before it becomes a rule.

## Step 0 — locate the unit and read what it already declares

Find the knowledge base. It is a directory holding `framework/`, and the convention is
`knowledge-base/` at the repository root. If it is absent, stop and say so: this skill
instantiates a vendored unit, it does not fetch one. Point at the unit's own README for the
copy step.

Then read, because everything below derives from these and nothing should be invented that one
of them already answers:

| read | to learn |
|---|---|
| `framework/contracts/project-context.schema.md` | every key a context must supply, its shape, and which core file consumes it |
| `framework/templates/project-context/` | the context file set — one blank form per file, and the forms you will fill |
| `framework/roster.md` | who exists, the tier order, each member's mandate |
| `framework/rules/doc-artifact-registry.md` § Standard kinds | the documentation kinds, their suggested paths and lifecycles |
| `framework/hosts/*.md` | per host: the mount points, the binding frontmatter, the model and effort maps |
| `framework/rules/invariants.md` | the rules the result must satisfy — this is the acceptance criteria, not background reading |

Check whether the unit is already instantiated: a context whose values are filled rather than
`<placeholders>`. If it is, do not overwrite it. Report what exists and ask whether to fill only
the gaps or to start over — silently replacing someone's ownership map is the worst thing this
skill could do.

## Step 1 — PROPOSE

Run `scripts/detect.py <repo-root>`. It scans the repository and emits a JSON proposal: the
languages and frameworks it found, the commands it can see, whether there are runtimes and
gates, and — importantly — a list of things it refuses to guess. Read
`references/human-gates.md` before turning that into questions.

Then write the proposal up for a human, in three sections:

**Derived, with evidence.** Every value, and the file it came from. `test: <command>` is only
worth reading if it says which file that command was found in — a proposal without evidence
cannot be checked, so it gets rubber-stamped, which defeats the gate.

**Assumed, worth a glance.** Values you are confident about but that nobody stated: a default
branch, a docs language, whether a member is dispatched. Mark them so they are easy to correct
and easy to ignore.

**Needs a decision.** The judgement calls, as concrete questions with your recommendation and
the evidence for it. Never a bare "what conventions do you use?" — that invites a shrug. Ask
"three of these directories look like separate deployables; should each be a member's ownership
area, or is this one tier?" and say what you would pick.

Ask the decisions in one batch, not one at a time. A person answering ten questions in one pass
holds the whole shape in mind; the same ten questions spread over ten turns get inconsistent
answers.

## Step 2 — the gate

Present the proposal and stop. Do not write a single file before someone approves — not the
"obvious" ones, not to save a round trip. Everything this skill writes becomes law for every
later agent, and the gate is the only place a human sees it as a whole.

If they edit the proposal, re-present it. If they answer some decisions and defer others, that
is fine: an unanswered decision leaves its value as a marked placeholder, and the validator will
say so. Half-instantiated and honest beats fully-instantiated and invented.

## Step 3 — APPLY

Run `scripts/render.py` with the approved answers. It writes:

- the context files, from the blank forms, with every approved value in place;
- one binding per roster member per host, from the binding template and that host's frontmatter;
- the documentation directories the approved kinds need, and the intake channel;
- the repository's index-and-law file, from its template, including the anchor and the core
  prohibition.

Then, in this order, because each step depends on the previous one holding:

1. `framework/bin/validate-context.sh` — it must pass. A finding is not a note to pass on; it
   is the instantiation not being finished. Fix and re-run.
2. `framework/bin/lock-core.sh lock` — a fresh copy of the unit starts unlocked, because a
   filesystem bit is not carried by version control. Locking is part of initializing, not an
   afterthought.
3. Report: what was derived, what was assumed, what a human decided, what is still a marked
   placeholder, and the validator's final line.

## What never gets inferred

Canonical in `references/human-gates.md`, with the reasoning for each. In short: ownership,
interfaces, conventions, domain vocabulary, destructive operations, budgets. If you find
yourself about to write one of those from a pattern you noticed in the code, that is exactly the
moment to ask instead.

## Working style

- **Cite or drop it.** Every derived value names its source file. A value you cannot source is
  an assumption, and belongs in the assumption list where it can be seen.
- **Empty is a legitimate answer.** A repository with no runtime, no gates, or no persistence
  says so — the roster explicitly permits a member with no ownership, and an honest gap reads
  better than a plausible fiction. Do not invent a data tier to fill a row.
- **The blank forms are the schema.** Do not hand-write a context file from memory of what the
  fields are; copy the form and fill it, so a field added to the framework appears here too.
- **Never touch the core.** `framework/**` is read-only, enforced (FI-25). If initializing seems
  to need a core change, the change is wrong or the core is — say which, and stop.

## Reference files

- `references/human-gates.md` — what must not be inferred, why, and how to ask about each. Read
  before writing the proposal.
- `references/walkthrough.md` — a worked run end to end, and the failure modes worth knowing.
  Read if the sequence above leaves anything ambiguous.
