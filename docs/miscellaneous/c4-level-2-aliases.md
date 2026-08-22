# C4 Level 2 — with aliases

Same six internal parts as `docs/architecture-c4.md` Level 2, plus the three Level 1
externals so business names have a box. Aliases sit on every box; install-agnostic.

```mermaid
flowchart TB
  op["Central operator<br/>console operator"]
  team["Verification team<br/>Ofițer 1, Ofițer 2, Responsabil IER<br/>tenant officers"]

  rep[("Project reporting system<br/>MySMIS<br/>MySMIS export .xlsx")]
  risk[("Periodic risk reporting<br/>Anexa 3<br/>Anexa 3 semestrial .xlsx")]
  tool["Sampling tool used alongside<br/>IDEA<br/>external sampling tool<br/>human-run sampling"]

  subgraph sys["OIR Flow"]
    console["Operator console<br/>/console panel, console<br/>backend"]
    work["Organisation workspace<br/>/{tenant} panel, tenant app,<br/>organisation application<br/>backend"]
    docs["Document service<br/>doc engine, document engine"]
    store[("Records store<br/>PostgreSQL, schema-per-tenant store")]
    jobs[("Background work and short-term memory<br/>Redis, queue, cache, sessions")]
    mail["Notices<br/>mail, SMTP"]
  end

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

| C4 name | Aliases |
|---|---|
| Project reporting system | MySMIS, MySMIS export `.xlsx` |
| Periodic risk reporting | Anexa 3, Anexa 3 semestrial `.xlsx` |
| Sampling tool used alongside | IDEA, external sampling tool, human-run sampling |
| Operator console | `/console` panel, console, backend |
| Organisation workspace | `/{tenant}` panel, tenant app, organisation application, backend |
| Document service | doc engine, document engine |
| Records store | PostgreSQL, schema-per-tenant store |
| Background work and short-term memory | Redis, queue, cache, sessions |
| Notices | mail, SMTP |
| Central operator | console operator |
| Verification team (Ofițer 1, Ofițer 2, Responsabil IER) | tenant officers |

`backend` is the grouping alias for the Platform (Operator console + Organisation workspace);
it is listed on both panel boxes.
