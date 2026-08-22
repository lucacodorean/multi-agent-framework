# Walkthrough

A run end to end, and the failure modes worth recognizing.

## The shape of a good run

1. **Locate and read.** Find the unit, read the contract, the blank forms, the roster, the
   registry, the host adapters. Report the core version — a consumer that cannot say which core
   it vendored has nothing to compare against later.
2. **Detect.** `scripts/detect.py <repo-root>` emits a proposal and a list of refusals. Read the
   refusals as a checklist of questions, not as gaps to fill in yourself.
3. **Propose.** Three sections — derived with evidence, assumed, needs a decision. Every derived
   value cites its file.
4. **Gate.** Stop. Wait. Re-present if edited.
5. **Apply.** `scripts/render.py` with the answers. Context files, bindings per host, doc
   directories, intake channel, index-and-law file.
6. **Verify.** The validator must pass. Then lock the core.
7. **Report.** Derived / assumed / decided / still placeholder, and the validator's final line.

## Failure modes

**Rendering before the gate.** The most damaging one, because the files look finished and nobody
re-reads them. If the gate has not happened, nothing is written — including the parts that seem
uncontroversial.

**Inventing a tier.** A repository with no persistence does not need a data member. Filling that
row with "the ORM directory" creates an owner for something nobody owns, and the tier order then
implies a boundary that does not exist. Leave it empty; the roster permits it.

**A convention inferred from a pattern.** Three files doing something the same way is not a
decision. Written into the conventions slot it becomes a rule the reviewer enforces against the
fourth file, whose author had a reason.

**Overwriting an instantiation.** If the context is already filled, the ownership map in it was
someone's decision. Fill gaps or start over, but only on an explicit instruction, and say which
you are doing.

**Editing the core to make init work.** `framework/**` is read-only and enforced. If
initialization appears to need a core change, either the initialization is wrong or the core has
a defect. Both are worth saying out loud; neither is worth working around.

**Passing the validator by weakening it.** Findings are the definition of done. A check adjusted
to accept the current state has removed the only thing that would have caught the next mistake.

## When the repository is unusual

- **A monorepo with several deployables.** Ask whether each is a member's area or whether the
  whole thing is one tier with internal structure. Both are defensible; only a human knows
  which.
- **No runtime, no gates, no persistence** — a documentation or library repository. Most members
  end up empty and undispatched, and the result is still a correct instantiation. Say so plainly
  in the report rather than padding it.
- **An existing agent setup from somewhere else.** Do not merge it silently. Report what is
  there, and let a human decide whether the roster replaces it, coexists with it, or wraps it as
  an extension.
- **The unit vendored somewhere other than the conventional path.** Record the anchor as the
  path it actually sits at. Files outside the unit cite that anchor, so getting it wrong breaks
  every one of them at once — and the validator's anchor check will say so.
