# Agent-binding contract

A binding is the whole of an agent definition in a host directory. It is thin by construction:
it names a charter, a member record and a host, and states nothing they already state.

A binding MUST:

- carry the host's required frontmatter (`framework/hosts/<host>.md` § Binding frontmatter),
  with a `description` sufficient for the harness to route work to it;
- name exactly one charter from `framework/roles/`;
- name exactly one member record in `project-context/roster.md`;
- name `framework/roles/_standing-orders.md`;
- pin no model and no effort — both are assigned at dispatch
  (`framework/rules/orchestration.md` § Model and effort).

A binding MUST NOT:

- restate ownership paths, carve-outs, stack versions, commands, duties or budgets — those
  live in the member record and are read from there;
- state a rule that a charter or a framework rule already states;
- differ in substance from the binding for the same member on another host. Hosts differ in
  frontmatter, never in charter, member or standing orders.

Rendering: `framework/templates/agent-binding.md.template`.

Divergence between two hosts' bindings for one member is a defect in the renderer or the
template, never a local fix in one copy.
