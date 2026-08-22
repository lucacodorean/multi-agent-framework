# Architecture decision records

Template: `0000-template.md`. One decision per file, numbered sequentially.

Numbering starts at **0024**: ADRs 0001–0023 predate the 2026-08-11 documentation
re-initialization and were removed from the tree with `docs/legacy/` (recover from git
history if needed). Code comments still cite them by number; those IDs are never reused.
A removed decision that still binds must be re-derived from code and re-recorded here
before being cited as active. 0034 was deleted on 2026-08-20; its number is retired
under the same rule. 0036–0054 are reserved, never issued, by human ruling of 2026-08-20 —
the pointer moved straight from 0035 to 0055 that day; the gap is not nineteen lost
records.

| # | title | status |
|---|---|---|
| [0024](0024-workflow-mandatory-for-deterministic-orchestration.md) | Workflow is mandatory for deterministic multi-member orchestration | accepted |
| [0025](0025-contract-file-is-the-single-source-of-the-seam-version.md) | The contract file is the single source of the seam version | accepted |
| [0026](0026-docs-tracker-is-a-whitelisted-generated-artifact-path.md) | `docs/tracker/` is a whitelisted generated-artifact path | accepted; regenerate-clause superseded by 0027 |
| [0027](0027-docs-tracker-is-a-transit-directory.md) | `docs/tracker/` is a transit directory | accepted; whitelist-boundary clause retired by human ruling 2026-08-20, not by an ADR — write paths are canonical in `docs/conventions/documentation-governance.md` § Allowed write paths |
| [0028](0028-tenant-user-activation-by-mailed-link.md) | Tenant-user activation by mailed single-use link | accepted; mail-timing consequence corrected by 0033; "bootstrapped administrator only" retired by 0056 |
| [0029](0029-preview-compose-topology.md) | Preview Compose topology (build artifacts, not operated) | accepted |
| [0030](0030-contract-import-versioning-chained-with-a-stored-is-latest.md) | Contract-import versioning: chained versions with a stored `is_latest` | accepted |
| [0031](0031-lock-the-import-document-row-before-recounting.md) | Lock the import document row before recounting it | accepted |
| [0033](0033-one-act-one-transaction-serialized-by-explicit-locks.md) | One act, one transaction, serialized by explicit locks | accepted |
| [0035](0035-lock-the-aggregate-root-where-a-slot-holds-one-row.md) | Lock the aggregate root where only one row may hold a slot | accepted |
| [0036](0036-tenant-migrations-mirror-enum-values-instead-of-importing.md) | Tenant migrations mirror enum values instead of importing the class | accepted |
| [0037](0037-bytea-artifacts-are-hex-bound-and-pinned-by-a-length-check.md) | bytea artifacts are hex-bound and pinned by a length CHECK | accepted |
| [0038](0038-no-package-row-level-tenant-scoping-under-schema-isolation.md) | No package row-level tenant scoping under schema isolation | accepted |
| [0039](0039-pin-the-permission-cache-to-the-in-process-array-store.md) | Pin the permission cache to the in-process array store | accepted |
| [0040](0040-redis-tenant-isolation-without-redistenancybootstrapper.md) | Redis tenant isolation without RedisTenancyBootstrapper | accepted |
| [0041](0041-tenant-search-path-is-the-tenant-schema-and-extensions.md) | The tenant search_path is the tenant schema and `extensions` | accepted |
| [0042](0042-flush-the-tenant-cache-tag-set-at-the-lifecycle-transition.md) | Flush the tenant cache tag set at the lifecycle transition | accepted |
| [0043](0043-redact-a-setup-link-that-reaches-the-journal.md) | Redact a setup link that reaches the journal, never refuse the write | accepted |
| [0044](0044-no-environment-guard-on-the-console-bootstrap-command.md) | No environment guard on the console bootstrap command | accepted |
| [0045](0045-bind-the-session-to-the-tenant-at-authentication.md) | Bind the session to the tenant at authentication | accepted |
| [0046](0046-empty-the-permission-cache-on-both-edges-of-a-tenancy-switch.md) | Empty the permission cache on both edges of a tenancy switch | accepted |
| [0047](0047-password-rules-make-no-outbound-call.md) | Password rules make no outbound call | accepted |
| [0048](0048-engine-connection-comes-from-the-environment.md) | The engine connection comes from the environment | accepted |
| [0049](0049-hand-written-byte-safe-multipart-response-parser.md) | Hand-written, byte-safe multipart response parser | accepted |
| [0050](0050-engine-audit-records-name-files-logically.md) | Engine audit records name files logically | accepted |
| [0051](0051-no-dependency-for-a-checks-convenience.md) | No dependency for a check's convenience | accepted |
| [0052](0052-two-tenant-scoped-login-limiters.md) | Two tenant-scoped login limiters, both checked before either is spent | accepted |
| [0053](0053-no-filament-tenancy-and-persistent-tenancy-middleware.md) | No Filament tenancy; the tenancy middleware are persistent | accepted |
| [0054](0054-assert-tenant-uniformity-and-isolation-never-trust-them.md) | Assert tenant uniformity and isolation; never trust them | accepted |
| [0055](0055-two-page-refusal-split-on-link-disclosure.md) | Two-page refusal split on what the signed link already discloses | accepted; collapse rule scoped to the setup route only by 0057 |
| [0056](0056-activation-link-bound-to-login-address.md) | Activation link bound to the login address by a signed marker | accepted |
| [0057](0057-reset-route-names-its-already-used-cause.md) | Reset route names its already-used cause | accepted |
| [0058](0058-ier-register-versioning-chained-with-is-latest.md) | IER register versioning: chained versions with a stored `is_latest` | accepted |
