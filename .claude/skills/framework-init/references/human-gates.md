# Human gates

Six things this skill must not infer, why each one resists inference, and how to ask about it so
the answer is usable.

The common thread: these are not values, they are *decisions*. A value can be read off a file
and checked. A decision encodes what someone intends, and the code is evidence of intent at
best. Getting one wrong does not produce a wrong file — it produces a rule every agent in the
repository will follow, cited as authority, until someone notices.

---

## 1. The ownership map

**Why it resists.** Directory layout is evidence of intent, not a statement of it. Two projects
with identical trees can have different boundaries, because a boundary is about who is allowed
to change what, and that is a team decision. The framework's own rule says ownership follows
what code does, not where it lives — which is precisely the judgement a scan cannot make.

**How to ask.** Propose a map with reasoning, do not ask an open question. Show the top-level
directories, say which member you would give each to and why, and name the cases you are unsure
about. Ask specifically about:

- a directory that looks like two concerns sharing a tree;
- a mechanism that lives inside one member's area but behaves like another's — the carve-out
  case, and the one most often missed;
- whether a member with no obvious area should be left empty rather than given something
  marginal. Empty and undispatched is a legitimate, common answer.

**If deferred.** Leave the map as marked placeholders. Do not dispatch a member whose ownership
is unknown: it will either do nothing or touch anything.

---

## 2. Interfaces and their versioning

**Why it resists.** You can find files that look like interface definitions. You cannot tell
which of them are *published* — promised to a consumer, changed only deliberately — and which
are internal detail that happens to be serialized. That distinction is the whole point of the
boundary, and it exists only in someone's head until they say it.

**How to ask.** Name the candidates and ask which are promises. Then ask how a version is
stated and where, because an interface nobody versions cannot be depended on, and the framework
will otherwise record `none` and be right to.

**If deferred.** `none` is honest and the validator accepts it. An invented versioning scheme is
worse than an admitted gap, because a consumer will trust it.

---

## 3. The two convention slots

**Why it resists.** A convention is what the team decided, not what the code currently does.
Inferring "this codebase uses pattern X" from three occurrences produces a rule that outlaws the
fourth, better approach — and the reviewer will then enforce it. The framework mandates the two
slots and deliberately never fills them for exactly this reason.

**How to ask.** Do not ask people to enumerate their conventions from memory; they will produce
platitudes. Ask instead where the rules already live — a style guide, a wiki page, review
comments people keep repeating, an existing document — and offer to point the slots at those, or
to leave stubs describing what belongs in each. Filling them is project work with its own
lifecycle; it is not part of standing the framework up.

**If deferred.** Leave the stubs. Every role charter will point at a file that explains what
should be there, which is honest and self-explaining.

---

## 4. Domain vocabulary

**Why it resides with people.** Domain terms are the ones an outsider cannot derive and a
newcomer most needs. A scan can extract frequent identifiers; it cannot say what they mean to
the business, which of two near-synonyms is the real one, or which word is a legacy name nobody
should use again.

**How to ask.** Offer the frequent non-obvious identifiers you found and ask which are domain
terms worth defining, and what they mean in one line. Ask whether inputs and requirements arrive
in a different language than the documentation is written in — the framework tracks those
separately because acceptance criteria stay in the input's language.

**If deferred.** An empty glossary is fine. A wrong glossary teaches every future agent the
wrong word.

---

## 5. Destructive operations

**Why it resists.** Whether an operation is destructive depends on what it touches in *this*
project, and on what the team considers recoverable. A command that wipes a scratch database is
routine; the same command against shared data is an incident. No script can tell those apart.

**How to ask.** Ask directly: which commands must never run without explicit approval? Prompt
with the categories rather than a blank — data deletion, environment teardown, force-pushing,
anything against shared or production resources — and record what they say verbatim.

**If deferred.** Say so loudly in the report. This is the one gap with a blast radius: the
working agreement requires an approved task for destructive operations, and an empty list means
nothing is classified as one.

---

## 6. Documentation budgets

**Why it resists.** A budget is a judgement about how much a reader should have to hold at once.
Deriving it from current file sizes just ratifies today's sprawl, and once written it becomes the
number the doc writer compresses toward.

**How to ask.** Offer the framework's own suggestion — which kinds are budgeted at all, from the
artifact registry — and propose round numbers with the reasoning ("an index the whole team reads
every session; a decision record small enough to read in full"). Ask whether they want a
tolerance for small overruns, since the framework supports one.

**If deferred.** Leave the kinds that are budgeted marked, and note that the budget check will
skip what carries no number. Nothing breaks; the discipline is simply not yet on.

---

## Asking well

- **One batch.** Someone answering these together holds the shape in mind. The same questions
  spread over ten turns get inconsistent answers, and the inconsistency lands in a file that
  agents then obey.
- **A recommendation with every question.** "I would give this to the data tier because it holds
  migrations — correct me" gets a decision. "What should own this?" gets a pause.
- **Evidence, always.** Name the file that made you think so. It lets a person disagree quickly,
  which is the entire value of the gate.
- **Take an answer literally.** If someone says a member owns nothing, write nothing. Do not
  improve on it.
