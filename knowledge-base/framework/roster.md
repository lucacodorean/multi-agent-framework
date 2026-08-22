# Standing roster

The team every project starts from. Membership, role and tier position are framework facts — the
same shape holds whatever the project builds. What each member *owns* is not: paths, stack,
duties and proof commands come from `project-context/ownership.md`, keyed by the names below.

Additional members are added by an extension, never by editing this file (FI-26). An extension
adding a member supplies its charter, its row, and where it sits in the tier order.

## Tier order

```
contract-owner        the boundary; source of truth
   ↓
domain-engineer  ──►  engine-engineer — a provider bounded context beside the tiers,
   ↓                  reached only through its published interface
data-engineer
   ↓
platform-engineer
```

Requirements flow down only; constraints come back up as tasks through the boundary owner
(FI-06). `code-reviewer` and `docs-agent` stand outside the order entirely.

## Members

| member | charter | tier | mandate |
|---|---|---|---|
| `contract-owner` | `roles/boundary-owner.md` | 1 | Owns every published interface and the error model on it. Routes cross-tier work, arbitrates provider and consumer disputes, allocates globally unique identifiers before implementation. Routes; never implements. |
| `domain-engineer` | `roles/tier-member.md` | 2 | Owns the product's rules: use cases, state transitions, entry points, the consumer half of every outbound interface, and the tests over them. |
| `data-engineer` | `roles/tier-member.md` | 3 | Owns stored state and its shape: schemas, migrations, seed data, adapters behind ports the tier above declares, cache and queue topology. |
| `platform-engineer` | `roles/tier-member.md` | 4 | Owns the environment: runtimes, images, service pins, bootstrap, gates and root tooling. Makes the environment boring so no other member thinks about it. |
| `engine-engineer` | `roles/provider-context.md` | side | Owns a provider bounded context — a service that exists so the consumer never performs some class of work itself. Stateless, unaware of the consumer's partitioning, reached only through its published interface. |
| `code-reviewer` | `roles/code-reviewer.md` | outside | Reviews what others wrote. Owns nothing, writes nothing, fixes nothing. |
| `docs-agent` | `roles/docs-agent.md` | outside | The sole documentation writer, invoked at orchestration checkpoints under the role gate. |

A project needing none of a member leaves its ownership empty and does not dispatch it. A
project needing two of one tier adds the second by extension.

## What the project supplies

Per member, in `project-context/ownership.md`: `owns`, `carve_outs`, `stack`, `verify`,
`conventions`, `destructive`, and numbered `duties` beyond the charter. Every path in the
repository maps to exactly one member (FI-05), and ownership follows what code does, not where
it lives.

## What binds every member

`roles/_standing-orders.md`, and the channels in `rules/agent-communication.md`. Bindings are
rendered per host from `templates/agent-binding.md.template`
(`contracts/agent-binding.contract.md`).
