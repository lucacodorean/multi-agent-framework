# Glossary — OIR Flow

Contract: `framework/contracts/project-context.schema.md` § glossary.md. Domain vocabulary, so
no framework file carries a domain term. Depth: `docs/architecture.md`,
`docs/document-engine-bridge.md`.

| term | language | meaning |
|---|---|---|
| dosar | ro | the case aggregate; four independent state dimensions written only by `DosarLifecycle` |
| CR / CP | ro | the sampling regimes the platform serves |
| esantion | ro | sample; the drawn subset a sampling package documents |
| nota justificativa (NJ) | ro | the generated justification document |
| Anexa 3 | ro | the semestrial input workbook |
| MySMIS | ro | the external system whose `.xlsx` export starts a case |
| IER / Indici Expunere la Risc | ro | risk-exposure indices; the register domain |
| Ofiter 1 / Ofiter 2 / Responsabil IER | ro | the three tenant-side attesting roles |
| Panoul de control | ro | the tenant panel dashboard |
| diffs_reproducere | ro | the engine's recomputation cross-check; non-empty means the platform raises |
| tenant | en | an OIR; one PostgreSQL schema, resolved from the first URL path segment |
| console / `/console` | en | the central operator panel; a console account grants nothing inside a tenant |
| drift check | en | assertion that every tenant schema carries the same migration set |
