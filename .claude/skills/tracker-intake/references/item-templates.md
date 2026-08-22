# Item templates

Every item = the **common block** + its **type block**. Fields marked ● are gate fields: an item missing any of them fails the quality gate and moves to *Needs clarification* with the missing fields named. Fields marked ◐ are expected: when absent, the item still passes but carries an inline `⚠ missing:` note. Plain fields are optional; absent means `—`.

The gate is mechanical — a field is present or it is not. Thin-but-present content passes with an inline `⚠ thin:` note. Never invent content to fill a field.

## Common block (all types)

```markdown
### KEY — [type] Title exactly as in the tracker
- **Source:** KEY (link if available) · reporter: name or team · created: YYYY-MM-DD · updated: YYYY-MM-DD
- **Priority signal:** severity / priority as stated by the source
- **Component(s):** affected components or areas
- **Relations:** blocks … · blocked by … · parent … · amends … · supersedes … · relates …
```

- ● Source key, ● Title, ● Type (`bug` / `feature` / `change`).
- Titles are preserved **verbatim** (whitespace-trimmed only). Rewriting titles breaks diff stability and back-mapping to the tracker.
- Priority signal is copied as stated (`S2 / P1`, `High`, …). It is routing *input* for the orchestrator — never translate it into a model, effort, or route.
- Relations use source keys only. Omit relation kinds that don't apply.

## Bug

```markdown
- **Environment:** where it reproduces (env, version, browser/OS as relevant)
- **Repro steps:**
  1. …
- **Expected:** …
- **Actual:** …
- **Evidence:** logs, screenshots, error IDs (reference, don't inline large blobs)
```

- ● Repro steps, ● Expected vs. actual, ● Severity (in priority signal).
- ◐ Environment.
- One bug = one defect. A ticket describing two unrelated defects stays **one item** (tracker granularity is preserved) but gets a `⚠ compound: describes N distinct defects — consider splitting in the tracker` note. Splitting into work units is the orchestrator's decomposition job; splitting the *ticket* is the tracker owner's job.

## Feature

```markdown
- **Story / problem statement:** As a …, I want …, so that … (or a plain problem statement)
- **Acceptance criteria:**
  - [ ] …
- **Out of scope:** explicit exclusions, if stated
```

- ● Story or problem statement, ● Acceptance criteria.
- ◐ Component(s).
- Acceptance criteria must be checkable statements. Restated wishes ("works well", "is fast") pass the mechanical gate but get `⚠ thin: AC not mechanically checkable`.

## Change

For increments over something previously stated — scope changes, revisions, "actually, make it do X instead".

```markdown
- **Amends:** KEY (or supersedes: KEY) — what prior statement this modifies
- **Delta:** what changes relative to the prior statement — additions, removals, modifications
- **Acceptance criteria:** for the changed behavior, if stated
```

- ● Amends/supersedes link, ● Delta.
- ◐ Acceptance criteria.
- The delta states only the difference. Duplicating the predecessor's full content creates two competing statements of intent — exactly the ambiguity intake exists to remove.
- A change whose predecessor cannot be identified (no link, no recognizable reference) fails the gate: `missing: amends target`.

## Content mining

Real content hides in the wrong fields. While normalizing:

- Mine comment threads for repro steps, AC, and decisions; attribute mined content: `(from comment, author, date)`.
- Flatten tracker markup (Jira wiki markup, ADF, HTML) to plain markdown.
- Strip noise: status transition history, watcher/vote lists, sprint churn, automation chatter, "+1" comments.
- Conflicting statements (description says X, later comment says Y): the latest authored statement wins, with a `⚠ conflict:` note naming both sources.
