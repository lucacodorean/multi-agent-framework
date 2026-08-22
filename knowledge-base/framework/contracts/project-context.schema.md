# Project-context contract

Every placeholder the framework core consumes, the file that supplies it, and the core files
that read it. A placeholder absent from `project-context/**` is an incomplete instantiation;
a project fact stated in a core file instead of here is a core defect. Both are checked by
`framework/bin/validate-context.sh`.

Notation: `{{a.b}}` scalar · `{{a.b[]}}` list · `{{a.b[].c}}` field of each list entry.

## `project-context/project.md` — identity

| placeholder | shape | consumed by |
|---|---|---|
| `{{project.name}}` | human name | `CLAUDE.md.template`, all roles |
| `{{project.slug}}` | kebab-case; the only identifier infra may derive names from | `CLAUDE.md.template` |
| `{{project.description}}` | one line | `CLAUDE.md.template` |
| `{{project.docs_language}}` | the language documentation is written in | `docs-compaction`, `documentation-governance` |
| `{{project.input_language}}` | the language requirement inputs arrive in; acceptance criteria stay in it | `user-stories-use-cases`, `doc-artifact-registry` |
| `{{project.tracker.host}}` | tracker product, or `none` | `tracker-intake` |
| `{{project.tracker.key_prefix}}` | issue-key prefix, or `none` → keys are minted | `tracker-intake`, `task-orchestrator` |
| `{{project.repo.default_branch}}` | branch a review diffs against | `code-reviewer` role |
| `{{kb.root}}` | where this knowledge base sits in the host repository — the anchor every file outside the unit cites (FI-27). Stated here once, and restated in the host's instruction file so an agent can resolve it without opening the context | the host's mounted skills, the repository index |

## `project-context/roster.md` — members and topology

| placeholder | shape | consumed by |
|---|---|---|
| `{{roster.tiers[]}}` | ordered member names, highest tier first | `orchestration`, all roles |
| `{{roster.side_contexts[]}}` | `{member, reached_through}` — provider contexts beside the tiers | `orchestration`, `provider-context` role |
| `{{roster.outside_order[]}}` | members standing outside the tier order | `orchestration` |
| `{{member.name}}` | roster name; also the binding filename and `subagent_type` | `agent-binding.md.template` |
| `{{member.role}}` | id of a `framework/roles/*.md` charter | `agent-binding.md.template` |
| `{{member.tier}}` | position in `roster.tiers[]`, or `side` / `outside` | `tier-member` role |
| `{{member.owns[]}}` | writable path globs | all roles, `rules-of-engagement` |
| `{{member.carve_outs[]}}` | `{path, owner}` — paths inside `owns[]` belonging to another member | `rules-of-engagement` |
| `{{member.stack[]}}` | technologies this member works in | `tier-member`, `provider-context` roles |
| `{{member.duties[]}}` | numbered project duties beyond the charter | all roles |
| `{{member.verify[]}}` | commands proving this member's work, by key from `commands.md` | `working-agreement` |
| `{{member.conventions[]}}` | convention files binding this member | all roles |
| `{{member.destructive[]}}` | destructive operations specific to this member | `working-agreement` |

## `project-context/stack.md` — technology

| placeholder | shape | consumed by |
|---|---|---|
| `{{stack.languages[]}}` | language + version floor | `tier-member` role, `code-reviewer` |
| `{{stack.frameworks[]}}` | framework + version constraint | `tier-member` role |
| `{{stack.services[]}}` | data stores, brokers, external services + pins | `runtime-topology` |
| `{{stack.tooling.style}}` | style tool, or `none` | `code-reviewer` |
| `{{stack.tooling.static_analysis}}` | analyser + level, or `none` | `code-reviewer` |
| `{{stack.tooling.test}}` | test framework | `code-reviewer` |
| `{{stack.tooling.contract_lint}}` | interface linter, or `none` | `boundary-owner` role |

## `project-context/commands.md` — how work is verified

Keys are fixed; values are the project's. Every value runs where the project says tools run
(`{{commands.runner_prefix}}`), never on assumptions about the host.

| placeholder | purpose |
|---|---|
| `{{commands.runner_prefix}}` | how a command reaches the project's execution environment; empty if it runs bare |
| `{{commands.dependency_install}}` | install declared dependencies |
| `{{commands.env_up}}` | bring the default runtime up |
| `{{commands.env_full_boot}}` | the full-boot verification a topology change requires |
| `{{commands.test}}` / `{{commands.test_narrow}}` | full suite / single target |
| `{{commands.style_check}}` · `{{commands.static_analysis}}` · `{{commands.contract_lint}}` | gate tools, or `none` |
| `{{commands.db_shell}}` · `{{commands.cache_shell}}` | real-service verification entry points, or `none` |
| `{{commands.destructive[]}}` | every operation requiring an explicit user-approved task |

## `project-context/runtimes.md` — where it runs

| placeholder | shape | consumed by |
|---|---|---|
| `{{runtimes[]}}` | `{id, doc, boot, verify}` — one entry per runtime | `runtime-topology` |
| `{{runtimes.shared_inputs_dir}}` | dir for inputs more than one runtime reads, owned by no runtime | `runtime-topology` |
| `{{runtimes.generated_dirs[]}}` | `{path, generated_by}` — never hand-edited | `runtime-topology` |

## `project-context/ci.md` — gates

| placeholder | shape | consumed by |
|---|---|---|
| `{{ci.host_doc}}` | doc describing the live CI host | `ci-gates` |
| `{{ci.script_dir}}` | the one script layer every gate lives in | `ci-gates` |
| `{{ci.gates[]}}` | `{name, proves, command, serialized}` | `ci-gates`, `orchestration` |
| `{{ci.lock}}` | the host-lock mechanism serializing colliding gates, or `none` | `ci-gates` |
| `{{ci.forbidden_host_tools[]}}` | tools a gate must never resolve on the host | `ci-gates` |

## `project-context/docs-policy.md` — documentation regime

| placeholder | shape | consumed by |
|---|---|---|
| `{{docs.sole_writer}}` | the one member that writes documentation | `documentation-governance` |
| `{{docs.role_gate_line}}` | exact line granting that authority in a task prompt | `documentation-governance`, `docs-agent` role |
| `{{docs.worker_channel}}` | the append-only file every other agent reports doc impact to | `documentation-governance`, all roles |
| `{{docs.metric}}` | the token metric of record, and how it is counted | `documentation-governance`, `docs-compaction` |
| `{{docs.archive_dir}}` | where compaction moves removed content | `docs-compaction` |
| `{{docs.write_paths[]}}` | `{path, budget}` — the canonical whitelist, one copy, here | `documentation-governance` |
| `{{docs.artifact_types[]}}` | `{type, path_pattern, writer, authorization, lifecycle, budget}` | `doc-artifact-registry` |
| `{{docs.read_gated[]}}` | `{path, grant}` — paths needing an explicit grant to read | `documentation-governance` |

## `project-context/conventions.md` — boundary and code discipline

| placeholder | shape | consumed by |
|---|---|---|
| `{{conventions.code_level}}` | project file holding class/method-level discipline | all roles, `code-reviewer` |
| `{{conventions.structural}}` | project file holding module/dependency discipline | all roles, `code-reviewer` |
| `{{conventions.boundary.interface_paths[]}}` | where published interfaces live | `boundary-owner` role |
| `{{conventions.boundary.formats[]}}` | interface description formats | `boundary-owner` role |
| `{{conventions.boundary.error_model}}` | the error shape every boundary answers with | `boundary-owner` role |
| `{{conventions.boundary.versioning}}` | where and how the interface version is stated | `boundary-owner`, `rules-of-engagement` |
| `{{conventions.enforcement}}` | per convention: the gate, test or construction enforcing it — or `nothing` | `rules-of-engagement` |

## `project-context/glossary.md` — domain vocabulary

| placeholder | shape | consumed by |
|---|---|---|
| `{{glossary[]}}` | `{term, language, meaning}` | every agent reading project input |

Free-form beyond that shape. The framework reads no term from it; it exists so no core file
has to carry one.
