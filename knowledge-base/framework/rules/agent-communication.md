# Agent communication

Framework rule. Who may say what to whom, and through which channel. A need travelling by any
other route is a defect, however convenient.

Payload formats are canonical elsewhere and are not restated here (FI-01); this file fixes the
channels.

## The channels

| channel | from → to | carries | payload defined in |
|---|---|---|---|
| **requirement** | any member → boundary owner → owning member | a scoped task naming the published interface version it builds against | `rules/orchestration.md` § Contract-first sequence |
| **constraint** | lower tier → boundary owner | something blocking a higher tier, for arbitration | same |
| **doc impact** | any worker → the doc writer | one verified fact a document does not say, or says wrongly | `rules/documentation-governance.md` § Doc-impact entry format |
| **review** | reviewer → lead → doc writer | fielded finding blocks, unchanged in transit | `roles/code-reviewer.md` § Output |
| **report** | member → lead | what changed, what was verified with its actual output, what was decided, what was filed | `roles/_standing-orders.md` § Output |
| **checkpoint** | lead → doc writer | the drain instruction, opening with the role-gate line | `rules/documentation-governance.md` § Role gate |
| **escalation** | member → lead → human | a genuine blocker, and nothing else | `rules/working-agreement.md` |

Which primitive carries a channel on a given host — a dispatch, a message, a pipeline stage, a
final response — is a host fact: `hosts/`.

## Rules holding on every channel

- **No side channels.** Editing another member's files, leaving a note in code, or renaming
  something to signal an opinion are not communication. They are boundary violations (FI-06).
- **A message is not an interface.** Agreeing something in a task does not publish it. If two
  members will depend on it, it exists in the interface first (FI-07).
- **The doc channel is append-only and one-way.** A worker appends; only the doc writer drains
  and truncates. No worker edits an existing entry, and no worker answers another through it
  (FI-02).
- **Structured payloads travel unchanged.** A finding, an item, an entry is data in transit.
  Summarizing, reordering or prose-ifying it destroys what the next stage consumes (FI-13).
- **A report is input to verification, never a substitute for it.** The lead verifies against
  the published interface and the project's own proofs before relaying anything as done.
- **Claims carry evidence.** "It passed" names the command and its actual output; a finding
  names file, line, and the path that reaches it (FI-14, FI-16).
- **Silence is not delivery.** A member dispatched in the background delivers through its
  channel as its final act. Going idle without delivering loses the work.
- **One task, one owner.** A need spanning two ownership areas is two tasks, each to its owner —
  never one task crossing a boundary (FI-06).

## Documentation is the shared surface

Members do not read each other's working state. They read the documentation tree and the
published interfaces, which is why the doc channel matters more than it looks: it is the only
route by which a fact one member learned reaches the others. A worker who fixes a document
instead of filing the fact has bypassed the one channel that would have told everyone (FI-02).
