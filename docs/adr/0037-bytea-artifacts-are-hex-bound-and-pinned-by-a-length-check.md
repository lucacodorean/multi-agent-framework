# 0037 — bytea artifacts are hex-bound and pinned by a length CHECK

- Status: accepted
- Date: 2026-08-20

## Context

- Six tenant tables retain an artifact as `bytea` in the row rather than on a filesystem:
  `risk_index_sources`, `contract_import_artifacts`, `expense_ledger_versions`, `documents`,
  `package_parts`, `populatie_runs` (`fi_artifact`).
- Measured on this stack: a PHP string bound straight to a `bytea` parameter stores the bytes
  up to the FIRST NUL and discards the rest. An `.xlsx` is a ZIP full of NULs, so the naive
  write retains a few bytes that satisfy the not-null, non-empty, maximum-size and
  digest-shape checks and are then served as the original document.

## Decision

1. Every `bytea` artifact column carries a sibling `byte_length` column with the CHECK
   `byte_length = octet_length(<column>)`, beside a bounded
   `octet_length(<column>) BETWEEN 1 AND <maximum>`.
2. `byte_length` is computed in PHP by the writer and bound as its own parameter — never
   derived inside the statement from the column it is meant to check.
3. Writers bind the bytes through `decode(?, 'hex')` over `bin2hex()`; readers select
   `encode(<column>, 'hex')`. `PDO::PARAM_LOB` is the only other accepted binding and no
   writer uses it. Canonical example: `app/RiskRegister/Storage/RetainedSource.php`.

Rejected: bind the bytes directly and let the stored sha-256, recomputed on serve, catch the
corruption. It does catch it — years later, on a row in an append-only table that cannot be
corrected and whose original bytes are gone. Refusal at the insert is the only point where
the truncation is still recoverable.

## Consequences

- A new `bytea` column is incomplete without its length column, the CHECK, and a hex-bound
  writer and reader; a repair script or seeder cannot bypass any of them.
- A truncated write surfaces as SQLSTATE 23514 on `<table>_byte_length_matches`.
- Hex doubles the bytes on the wire in both directions — accepted at these artifact sizes.
