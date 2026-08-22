---
name: user-stories-use-cases
description: Assess any provided input (requirements documents, RFPs, tenders, briefs, feature descriptions, meeting notes, emails, transcripts, or pasted text) and produce a structured Markdown deliverable containing user stories and use cases derived from it. Use this skill whenever the user shares information and wants user stories, use cases, a backlog, acceptance criteria, or a requirements breakdown from it — including phrasings like "turn this into user stories", "extract use cases", "write stories from this doc", "build a backlog from this", "what are the use cases here", or "story-map this input". Trigger even if the user only says "analyze this input for stories" or shares a document and asks for structured requirements output.
---

# User Stories & Use Cases from Input

Transform arbitrary input (documents, notes, descriptions, transcripts) into a rigorous, traceable Markdown deliverable: an assessment of the input, a set of well-formed user stories with acceptance criteria, and structured use cases.

## Core principles

These matter more than the templates:

1. **Traceability over invention.** Every story and use case must trace back to something in the input. Never silently invent requirements. When a story is a reasonable inference rather than an explicit statement, mark it `(inferred)` and note the reasoning. When the input demands something be true for the system to work but doesn't say it, record it as an assumption.
2. **Assess before extracting.** Read the whole input first. Identify actors, goals, scope boundaries, and — critically — what is *missing or ambiguous*. A deliverable that flags five sharp open questions is worth more than one that papers over gaps with plausible fiction.
3. **Stories and use cases serve different purposes.** User stories are units of deliverable value (backlog-ready, INVEST-checked). Use cases are interaction contracts (actor–system dialogues with flows and failure paths). Do not collapse one into the other; cross-link them instead.
4. **The output is Markdown. Always.** All deliverable content — headings, tables, IDs, flows — is plain Markdown. No HTML, no other formats, unless the user explicitly overrides.
## Workflow

### Step 1 — Ingest the input

- If the input is pasted text, use it directly.
- If files were uploaded, read them from wherever this host delivers them (`framework/hosts/` § File I/O; on a filesystem host that is the path the user names). Extract text from binary document formats as needed.
- If multiple sources are provided, treat them as one corpus but track which source each item came from.
- If the user references input that isn't actually present (no paste, no file), say so and ask for it — don't fabricate.
### Step 2 — Assess

Build a mental (and then written) model of:

- **Domain & intent** — what is this system/feature/process for?
- **Actors** — every human role and external system that interacts. Distinguish primary actors (initiate interactions) from secondary (respond/support).
- **Goals** — what each actor wants to accomplish.
- **Scope** — what's clearly in, what's clearly out, what's undetermined.
- **Constraints** — technical, legal, performance, integration constraints stated in the input.
- **Gaps & ambiguities** — contradictions, undefined terms, missing flows, unstated business rules. Collect these as open questions with a note on why each matters.
### Step 3 — Derive user stories

- Group stories into **epics** when there are more than ~6 stories; otherwise a flat list is fine.
- Assign sequential IDs: `US-001`, `US-002`, …
- Use the canonical format: **As a** [actor], **I want** [capability], **so that** [benefit]. If the input genuinely has no discernible benefit for a story, that's a gap — flag it rather than inventing one.
- Every story gets **acceptance criteria** — concrete, testable conditions. Default to a bullet list; use Given/When/Then (Gherkin) when the behavior is conditional or stateful, or when the user asks for it.
- Sanity-check each story against **INVEST** (Independent, Negotiable, Valuable, Estimable, Small, Testable). Split stories that are too big; merge fragments that aren't independently valuable.
- Assign **priority** using MoSCoW (Must/Should/Could/Won't) based on signals in the input (words like "must", "critical", "nice to have", phase/milestone mentions). If the input gives no priority signal, mark priority as `TBD` — do not guess.
- Tag inferred stories: append `(inferred)` to the title and add one line explaining the inference.
### Step 4 — Derive use cases

Write use cases for the significant actor–system interactions (typically the Must/Should stories and anything with non-trivial flow logic). Not every story needs a use case; simple CRUD stories usually don't.

- Assign IDs: `UC-001`, `UC-002`, …
- Use a structured (Cockburn-style) format per use case:
    - **Name** — verb phrase from the primary actor's perspective
    - **Primary actor**
    - **Stakeholders & interests** (only when non-obvious)
    - **Preconditions**
    - **Trigger**
    - **Main success scenario** — numbered steps, alternating actor intent and system response
    - **Extensions / alternate flows** — numbered as branch points off the main flow (e.g., `3a.`, `3b.`)
    - **Postconditions** (success guarantees)
    - **Related stories** — the `US-xxx` IDs this use case realizes
- Failure and edge paths belong in extensions. If the input says nothing about a failure mode that obviously exists (payment declined, upload fails, session expires), add the extension and mark it `(inferred)`, or raise it as an open question if the correct behavior is genuinely unknowable.
### Step 5 — Produce the Markdown deliverable

Use the output structure below. Deliver as a `.md` file in the output directory when file creation is available (present it to the user); otherwise render the same Markdown inline in the response.

## Output structure

ALWAYS use this template (omit sections that are genuinely empty, keep the order):

```markdown
# User Stories & Use Cases: [Derived Title]
 
## 1. Input Assessment
### 1.1 Summary
[2–4 sentences: what the input describes and its apparent purpose.]
 
### 1.2 Actors
| Actor | Type | Description / Goal |
|---|---|---|
| ... | Primary / Secondary / External system | ... |
 
### 1.3 Scope
**In scope:** ...
**Out of scope:** ...
**Undetermined:** ...
 
### 1.4 Assumptions
[Numbered list. Things treated as true that the input does not state. A-001, A-002, …]
 
### 1.5 Open Questions
[Numbered list. Q-001, Q-002, … Each with a one-line note on why it matters / what it blocks.]
 
## 2. User Stories
[Optionally grouped under `### Epic: [name]` headings.]
 
### US-001: [Short title]
**As a** [actor], **I want** [capability], **so that** [benefit].
**Priority:** Must | Should | Could | Won't | TBD
**Acceptance criteria:**
- [criterion]
- [criterion]
**Source:** [quote fragment, section ref, or "(inferred: reason)"]
 
## 3. Use Cases
 
### UC-001: [Name]
- **Primary actor:** ...
- **Preconditions:** ...
- **Trigger:** ...
- **Main success scenario:**
  1. ...
  2. ...
- **Extensions:**
  - 2a. [condition]: [handling]
- **Postconditions:** ...
- **Related stories:** US-001, US-004
 
## 4. Traceability Matrix
| Story | Use Case(s) | Source in input |
|---|---|---|
| US-001 | UC-001 | §2.1 / "quoted fragment" |
```

## Calibration by input quality

- **Rich, detailed input** (formal spec, RFP): extract comprehensively; the deliverable may be long. Keep the traceability matrix — it's most valuable here.
- **Sparse input** (a two-line feature idea): produce the few stories the input supports, mark the rest of the structure with explicit gaps, and lead with open questions. Do not inflate two lines into a fictional 20-story backlog. Offer to expand once questions are answered.
- **Conversational input** (meeting notes, transcripts): requirements will be scattered and contradictory. Resolve contradictions by recency when the input shows a decision superseding an earlier one; otherwise flag the contradiction as an open question.
- **Input in another language**: assess in `{{project.input_language}}`, write the deliverable in `{{project.docs_language}}`, and keep acceptance criteria in the input's language (`framework/rules/documentation-governance.md`). Keep domain terms from the source where translation would lose precision — `project-context/glossary.md` holds them.
## Interaction notes

- If the user answers open questions in a follow-up, update the deliverable in place: convert answered Q-items into stories/criteria/assumptions, keep IDs stable, and append new IDs rather than renumbering.
- If the user asks for "just stories" or "just use cases", produce only that section plus the assessment (the assessment is what makes the extraction defensible — keep it unless told to drop it).
- Honor explicit format overrides (e.g., "acceptance criteria in Gherkin", "no MoSCoW, use P0–P3"), but the deliverable stays Markdown.
