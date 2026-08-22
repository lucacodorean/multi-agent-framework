# Glossary

This project's domain is the framework itself, so its vocabulary is the framework's own. Terms
appear here so no core file has to define one in passing.

| term | language | meaning |
|---|---|---|
| knowledge base | en | the vendorable unit: core, context, docs, extensions. One directory, copied whole into a consuming repository |
| core | en | `framework/**` — the project-agnostic half. Read-only to every agent (FI-25) |
| context | en | `project-context/**` — the values the core consumes, one file per concern |
| contract | en | `framework/contracts/project-context.schema.md` — every placeholder, its shape, and which core file reads it |
| placeholder | en | `{{a.b}}` in a core file, resolved from exactly one contract entry |
| anchor | en | `{{kb.root}}` — where the unit sits in the host repository, cited by files outside it (FI-27) |
| charter | en | a role's job description in `framework/roles/`, shared by every member holding that role |
| binding | en | the thin per-member file a harness discovers; names a charter, the roster and the member record, and nothing else |
| standing roster | en | `framework/roster.md` — who exists, the tier order, each mandate. A framework fact, not a project one |
| channel | en | one of the seven routes a need may travel (`framework/rules/agent-communication.md`). There are no others |
| extension | en | an addition beside the core that adds or narrows but never restates (FI-26) |
| invariant | en | a numbered rule in `framework/rules/invariants.md`, cited as `FI-nn`. The acceptance criteria for every change |
| standing authorization | en | a named file that permits a whole class of documents, so deterministic paths need no per-file human instruction (FI-20) |
| read gate | en | a grant string a task prompt must carry before a path may be read at all |
| lift and restore | en | removing a host `deny` entry to do deliberate core work and putting it back in the same change, on the record. The alternative — a write form the matcher does not recognize — is the violation FI-25 names |
