# Core fix brief — core `2026-08-23.1`

Findings from instantiating core `2026-08-23.1` into a Symfony application (PennyPact,
2026-08-23). Five defects, all in the framework core or its shipped skill scripts, none fixable
from a consuming repository (FI-25).

**How to use this file.** It is a task brief, not documentation. Copy it into the framework's own
repository, hand it to a session there, and work through the defects in order — D1 and D2 are in
one function and are best done together. Every line quotes the text to match, so line numbers
drifting does not matter.

This is deliberate core maintenance, so it follows the procedure in that repository's
`CLAUDE.md` § 0 and nothing else:

```sh
knowledge-base/framework/bin/lock-core.sh unlock
# ... edit ...
knowledge-base/framework/bin/validate-context.sh
FRAMEWORK_UNLOCK=1 git commit ...
knowledge-base/framework/bin/lock-core.sh lock
```

Publishing is a separate act from committing: every engineer and every vendored copy downstream
inherits a core change, so `FRAMEWORK_PUBLISH=1 git push` only when the release is intended and
announced. D1 changes what the validator reports on **every** repository using this core — treat
it as a release, not an edit.

---

## D1 — check 1's placeholder scan matches nothing, and passes silently

**Severity: high.** The guarantee "every placeholder a core file consumes is documented in the
contract" has never been enforced, on any repository, and the check prints its pass line anyway.
FI-08's rule that green-by-absence is a defect applies to the validator itself.

**File:** `knowledge-base/framework/bin/validate-context.sh`, line 109.

```sh
done < <(core_files | xargs grep -ho '{{[a-z_][A-Za-z0-9_.\[\]]*}}' 2>/dev/null | sort -u)
```

**Cause.** In a POSIX bracket expression a backslash is a literal character, not an escape. So
`[A-Za-z0-9_.\[\]]` is scanned as: open the class, take `A-Z a-z 0-9 _ . \ [ \`, and close it at
the **first** `]`. The trailing `]` then falls outside the class as a literal, and the `*` binds
to that literal rather than to the class. The pattern reduces to:

    {{  [a-z_]  <exactly one class char>  ]*  }}

which matches only a two-character placeholder followed by zero or more `]`. Nothing in the core
is shaped like that, so the loop reads an empty stream and `undocumented` stays 0.

**Why it was not caught by hand.** Testing it interactively can pass while the script fails. Many
shells alias or shim `grep`; ugrep, for one, accepts `\]` inside a bracket expression as an
escaped `]` and matches correctly. `xargs grep` execs the real binary and ignores the shim.
Verified on GNU grep 3.11:

```sh
S='{{project.name}} {{docs.write_paths[]}}'
printf '%s\n' "$S" | /bin/grep -o '{{[a-z_][A-Za-z0-9_.\[\]]*}}'   # no output
printf '%s\n' "$S" | /bin/grep -o '{{[a-z_][]A-Za-z0-9_.[]*}}'     # both placeholders
```

Use `/bin/grep` explicitly when checking this, or the result means nothing.

**Fix.** Place `]` first inside the bracket expression — the POSIX way to include a literal `]` —
and drop the backslashes:

```sh
done < <(core_files | xargs grep -ho '{{[a-z_][]A-Za-z0-9_.[]*}}' 2>/dev/null | sort -u)
```

`grep -oE '\{\{[a-z_][]A-Za-z0-9_.[]*\}\}'` behaves identically if ERE is preferred. Keep
whichever, but keep `]` first.

### D1 is not finished by that one line — read this before committing it

With the pattern fixed the scan finds 95 distinct placeholders in the core, and reports **26 as
undocumented**. Exactly 2 of those are real (they are D3 below). The other 24 are false
positives, because the check's premise is wrong: it assumes every `{{…}}` in a core file is a
project-context placeholder. There are three namespaces, and only the first is the contract's.

| namespace | filled from | filled when | example |
|---|---|---|---|
| project context | `project-context/**` via the contract | at instantiation | `{{commands.test}}` |
| binding render inputs | the instantiation's answers, via `agent-binding.md.template` | when bindings are rendered | `{{member.role_summary}}` |
| dispatch-time variables | the orchestrator, via `workflow-script.js.template` | at dispatch | `{{task.id}}` |

`member.*` straddles the first two: `{{member.name}}`, `{{member.role}}`, `{{member.owns[]}}` are
contract keys, while `{{member.role_summary}}`, `{{member.owns_summary}}`, `{{member.use_when}}`,
`{{member.not_owns_summary}}` and `{{member.position_sentence}}` are binding render inputs that no
context file supplies. A check that cannot tell them apart cannot be trusted either way.

The full 26, classified — reproduce it in your own tree with the snippet at the end:

- **Real (D3):** `{{project.architecture_doc}}`, `{{project.runbook_doc}}`.
- **Binding render inputs** — `templates/agent-binding.md.template`: `{{member.role_summary}}`,
  `{{member.owns_summary}}`, `{{member.use_when}}`, `{{member.not_owns_summary}}`,
  `{{member.position_sentence}}`.
- **Dispatch-time variables** — `templates/workflow-script.js.template`: `{{task.id}}`,
  `{{task.title}}`, `{{task.short}}`, `{{task.body}}`, `{{task.tier}}`, `{{task.effort}}`,
  `{{task.effort_guidance}}`, `{{task.acceptance}}`, `{{run.name}}`, `{{run.branch}}`,
  `{{run.description}}`, `{{phase.title}}`, `{{phase.detail}}`, `{{intake.document}}`,
  `{{plan.document}}`, `{{ruling}}`.
- **Prose about placeholders, not placeholders** — `{{placeholder}}` in `framework/README.md`,
  `{{placeholders}}` in `framework/README.md` and `rules/invariants.md`.
- **Spelled differently from the contract** — `{{member.reached_through}}` in
  `roles/provider-context.md`; the contract documents it as a field of
  `{{roster.side_contexts[]}}` (`{member, reached_through}`), so it is documented in substance and
  invisible to a literal `grep -F`.

**Recommended resolution.** Give the two non-context namespaces a declared home, then have check 1
consult those homes as well as the schema — one canonical location each, so a lookup stays a
single lookup (FI-01):

1. Document the five binding render inputs in `framework/contracts/agent-binding.contract.md`.
   That contract already governs the binding template; the inputs belong to it, not to the
   project-context contract.
2. Document the dispatch-time variables where the workflow template can point at them — a section
   of that template's own header, or a small contract beside it. They are the orchestrator's, and
   no project supplies them.
3. In check 1, resolve a placeholder against `$SCHEMA` **or** those two files before reporting it.
4. Decide what to do about the prose cases. Either accept them (they are in files that state
   rules about placeholders) or exclude `framework/README.md` and `rules/invariants.md` from the
   scan and say in a comment why.
5. Only then does `{{member.reached_through}}` need a decision: either spell it as a field lookup
   in the contract or accept the substance match.

Do not ship the regex fix on its own. It converts a silent false pass into 26 findings, 24 of
which are noise, and a validator that cries wolf gets ignored — which is worse than the silence
it replaces.

---

## D2 — the set-agreement confirmation can never print

**Severity: low, but it hides whether the check ran.** Same function, lines 83–102 of
`validate-context.sh`. Four occurrences of this shape:

```sh
      grep -qF "## \`project-context/$f\`" "$SCHEMA" \
        || note "  $f has a blank form and no section in the contract — its keys are undocumented"; setfail=1
```

`;` terminates the `||` list, so `setfail=1` runs **unconditionally** on every iteration. After
any non-empty loop `setfail` is 1, and line 102 —

```sh
    [ "$setfail" -eq 0 ] && echo "  $(printf '%s\n' $declared | wc -l) context files: blank forms, contract sections and instantiation agree"
```

— never fires whenever a context is present. Observed: a fully valid instantiation reports `PASS`
and never prints the line confirming that the blank forms, the contract sections and the
instantiation agree. The check does run and does report real disagreements; only its
all-clear is unreachable.

**Fix.** Brace each body so the assignment is part of the failure branch, in all four places:

```sh
      grep -qF "## \`project-context/$f\`" "$SCHEMA" \
        || { note "  $f has a blank form and no section in the contract — its keys are undocumented"; setfail=1; }
```

The two loops using `[ -f … ] || note …; setfail=1` need the same treatment.

---

## D3 — two project-context keys the contract does not document

**Severity: medium.** Masked entirely by D1.

`framework/templates/CLAUDE.md.template` consumes both:

- line 29 — `Canonical: {{project.architecture_doc}}. Ownership: …`
- line 58 — `Canonical: {{project.runbook_doc}} — every command, per runtime, …`

and `framework/templates/workflow-script.js.template` line 34 consumes `{{project.runbook_doc}}`
again. Neither key appears in `framework/contracts/project-context.schema.md` § project.md, and
neither has a row in `framework/templates/project-context/project.md`. So a project instantiated
from the blank forms cannot supply them, and `render.py` leaves both literal in the rendered
`CLAUDE.md` unless the values are passed in by hand — which is what we had to do here.

**Fix.** Add both in the same change, contract and blank form together, as § 3 of that
repository's `CLAUDE.md` requires ("a new placeholder is added to the contract in the same change
that first consumes it" — here, the change that admits it was already consumed).

Contract, § `project-context/project.md` — two rows:

```
| `{{project.architecture_doc}}` | the document that is canonical for repository layout and system shape, or `none` | `CLAUDE.md.template` |
| `{{project.runbook_doc}}` | the document holding every command with its verification status, or `none` | `CLAUDE.md.template`, `workflow-script.js.template` |
```

Blank form `framework/templates/project-context/project.md` — two rows:

```
| `project.architecture_doc` | <canonical document for layout and system shape, or `none`> |
| `project.runbook_doc` | <canonical document for commands and their verification status, or `none`> |
```

Both accept `none`: a project may legitimately have neither, and the templates read better with
an explicit `none` than with an unresolved placeholder.

---

## D4 — `render.py` parses each host's binding frontmatter and never applies it

**Severity: medium. Not under the FI-25 lock** — `.claude/skills/framework-init/scripts/render.py`
sits at a host mount point and is framework-owned but writable. Fix it in the same release so the
core and its tooling agree.

`hosts()` extracts the frontmatter block from each host adapter:

```python
fm = re.search(r"```yaml\n(.*?)```", txt, re.S)
out.append({"id": h.stem, "mount": …, "frontmatter": fm.group(1) if fm else ""})
```

`"frontmatter"` is never read again — step 3 renders every host from
`templates/agent-binding.md.template` verbatim. The template carries the Claude Code frontmatter
(`name:` + `description:`), so opencode bindings render without the `mode: subagent` that
`framework/hosts/opencode.md` § Binding frontmatter declares **required for a dispatched member**.
The seven opencode bindings in this repository had to be patched by hand after rendering.

**Fix.** Merge the host's declared frontmatter into the rendered binding in step 3 — take the keys
the host declares, drop the ones its adapter marks "omit" (`model:`, so FI-09 is not violated),
and keep the body from the template. Adding `mode: subagent` unconditionally for opencode would
work today and breaks at the next host; reading it from the adapter is the point of having
adapters.

Worth checking in the same pass: `render.py` writes bindings to `repo / host["mount"]` and never
prefixes citations with `kb.root`, so a rendered binding cites `framework/roles/…` from the
repository root, where it does not resolve. Bindings live outside the unit and must cite the
anchor (FI-27). We rewrote all fourteen by hand.

---

## D5 — `dated-snapshot` has no mechanism for a superseding measurement

**Severity: low. Design gap, not a bug** — found by trying to obey the rule rather than by
reading it.

**File:** `knowledge-base/framework/rules/doc-artifact-registry.md` § Lifecycles, the
`dated-snapshot` row.

The rule is right about what it protects: a finding body records what was believed when the
judgement was made, and correcting it destroys that record. But it names no way to supersede a
finding whose *measurement* was simply wrong, and a review report is exactly where a mechanical
count gets written down.

**How it surfaced.** A review report here recorded 94 distinct placeholders where the verified
number is 95. The count is incidental to the finding — the defect is that the scan collects zero —
but it is still wrong in a document someone will cite. Under the rule as written the doc writer
correctly refused to touch the body, appended a dated addendum carrying a "Held, not applied"
note, and left the correction sitting in the doc-impact channel as an entry nothing can action.
That is the rule working, and it still leaves a wrong number in the tree and an undrainable entry
in an append-only channel.

The kind's standing authorization would normally resolve it — commission a second dated report
that measures afresh — but that only works where a review is due. A one-number correction does not
justify a second review, and the channel has nowhere else to put it.

**Fix — pick one, and state it in the row so the next writer does not have to reason it out:**

1. **A correction is additive, not a rewrite.** Say explicitly that a superseding measurement is
   recorded as a dated addendum that names the finding it corrects, and that the original body
   stays. This is what the writer improvised here; blessing it costs one sentence and makes the
   improvisation reproducible.
2. **A finding may carry a status line.** The row already permits retiring a finding in place by
   adding a status line and bumping the date. Extend that to `superseded-by:` pointing at the
   addendum or the later report.
3. **Leave it, and say so.** State that a wrong measurement is not correctable and that the
   channel entry stays until the next report of that kind. Defensible, but then FI-04's "an entry
   you cannot verify is not an entry you discard" needs to admit an entry that is verified, true,
   and permanently unactionable — which is a strange thing for the channel to hold.

Option 1 is the smallest change that closes both halves — the wrong number and the stuck entry.

---

## Verifying the fixes

Run from the framework repository root, with the core unlocked:

```sh
KB=knowledge-base
/bin/grep -o '{{[a-z_][]A-Za-z0-9_.[]*}}' $KB/framework/templates/CLAUDE.md.template   # D1: non-empty
$KB/framework/bin/validate-context.sh                                                  # D1+D2+D3
```

Check 1 must print, on a valid instantiation: the placeholder line, the supplied-keys line, **and**
the set-agreement line that D2 unblocks. Then re-derive the classification to confirm nothing new
is undocumented:

```sh
cd knowledge-base
SCHEMA=framework/contracts/project-context.schema.md
LIST=$( { find framework -type f \( -name '*.md' -o -name '*.template' \) | /bin/grep -v '^framework/templates/' ; find framework/templates -type f ; } )
/bin/grep -ho '{{[a-z_][]A-Za-z0-9_.[]*}}' $LIST | sort -u | while read -r ph; do
  /bin/grep -qF "$ph" "$SCHEMA" || { printf '%-34s' "$ph"; /bin/grep -l -F "$ph" $LIST | tr '\n' ' '; echo; }
done
```

Every line it prints is either a real gap or a namespace that still needs a declared home.

For D4, render an instantiation for both hosts and check the opencode copies:

```sh
/bin/grep -L '^mode: subagent' .opencode/agents/*.md    # must print nothing
```
