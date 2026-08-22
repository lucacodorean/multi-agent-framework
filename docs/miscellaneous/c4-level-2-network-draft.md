# C4 Level 2 — network overlay (draft)

Draft. Same six internal parts as `docs/miscellaneous/c4-level-2-aliases.md`. Overlay
only: SaaS on one centralized VM in the OIR organisation; reachability from inside the
organisation and via VPN; routing table at OIR organisation level. No addresses, ports,
or other hosting invent.

```mermaid
flowchart TB
  inside["Access from inside the organisation"]
  vpn["Access via VPN"]

  op["Central operator<br/>console operator"]
  team["Verification team<br/>Ofițer 1, Ofițer 2, Responsabil IER<br/>tenant officers"]

  rep[("Project reporting system<br/>MySMIS<br/>MySMIS export .xlsx")]
  risk[("Periodic risk reporting<br/>Anexa 3<br/>Anexa 3 semestrial .xlsx")]
  tool["Sampling tool used alongside<br/>IDEA<br/>external sampling tool<br/>human-run sampling"]

  subgraph org["OIR organisation"]
    rt["Routing table"]

    subgraph vm["Centralized VM<br/>SaaS"]
      subgraph sys["OIR Flow"]
        console["Operator console<br/>/console panel, console<br/>backend"]
        work["Organisation workspace<br/>/{tenant} panel, tenant app,<br/>organisation application<br/>backend"]
        docs["Document service<br/>doc engine, document engine"]
        store[("Records store<br/>PostgreSQL, schema-per-tenant store")]
        jobs[("Background work and short-term memory<br/>Redis, queue, cache, sessions")]
        mail["Notices<br/>mail, SMTP"]
      end
    end
  end

  inside --> rt
  vpn --> rt
  rt --> vm

  op -->|"uses"| console
  team -->|"uses"| work
  rep -->|"claimed-expenses export"| work
  risk -->|"half-yearly risk figures"| work
  work -->|"sample instruction"| tool
  tool -->|"drawn sample and evidence"| work
  console -->|"organisations and lifecycle"| store
  work -->|"cases, files, decisions"| store
  work -->|"file in, finished papers out"| docs
  work -->|"slow tasks"| jobs
  work -->|"turn notices"| mail
  jobs -->|"document work"| docs
  jobs -->|"finished result"| store
```

Logical parts sit on the one VM. Not a `docs/topology/` runtime; does not amend
`docs/architecture.md`.
