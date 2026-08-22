# Rules of engagement

Framework rule. The boundary mechanics between members. Project values:
`project-context/conventions.md`, `project-context/ownership.md`.

## The three that bind everything

1. Contract-first across members: no cross-member dependency without an agreed interface,
   schema or API definition published before implementation (FI-07).
2. Tier direction holds between members (FI-06).
3. Cross-tier work coordinates through the boundary owner as tasks or messages — never by
   directly editing another member's files.

## Boundary mechanics

- Publish before building: every cross-member interface — path, payload, event, error shape —
  exists in `{{conventions.boundary.interface_paths[]}}` before implementation, described in
  `{{conventions.boundary.formats[]}}`.
- Version the interface, not the file: `{{conventions.boundary.versioning}}`. A prose-only
  correction leaves the version unchanged, so consumer pins do not move for a change no
  consumer can see.
- One error model on every boundary: `{{conventions.boundary.error_model}}`, enforced by
  `{{stack.tooling.contract_lint}}`.
- Ownership follows behaviour, not location (FI-05). A mechanism living inside another
  member's directory tree is carved out to the member that owns the mechanism; the carve-out
  list is part of the member record, never inferred.
- A container directory whose files serve different owners is owned per file, never as a
  directory.
- Ports and adapters: the consuming module declares the port and owns its failure vocabulary;
  the adapter implements it and raises only the exception types the port declares. Consuming
  code calls the port, never the adapter. The binding between them lives in the composition
  root, and the concrete adapter is named nowhere else.
- Enforcement is claimed only where it exists (FI-22). Per convention:
  `{{conventions.enforcement}}`.

## Provider bounded contexts

A `{{roster.side_contexts[]}}` member is not a tier of the system. For each:

- It is reached only through its `reached_through` interface; no other path in exists.
- It implements only what that interface publishes. A generated schema is not the interface;
  drift from the published document is the provider's defect.
- It decides nothing the consumer owns. It computes and returns; a recomputation is a
  cross-check, and a non-empty difference is the consumer's error to raise.
- Correlation identifiers passed to it are opaque: stamp them onto logs and returned records,
  never parse or branch on them.
- Needs it has of its own container or environment travel as tasks to the member that owns
  them; it owns the application inside, never the provisioning around it.

## Harness copies

Each orchestrating agent enacts the roster in its own harness directory (FI-21). Bindings are
rendered from one template against one member record
(`framework/contracts/agent-binding.contract.md`) — never hand-maintained per host. Divergence
between two hosts' bindings for one member is a renderer defect.
