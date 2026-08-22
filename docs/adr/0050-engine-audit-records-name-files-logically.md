# 0050 — Engine audit records name files logically

- Status: accepted
- Date: 2026-08-20

## Context

- The engine is stateless: it has nowhere durable to write a trail, so it returns one in the
  response as the contract's `auditEvents[]` (`AuditEvent` in `contract/engine.openapi.yaml`).
  Those records leave the engine and outlive the call they describe.
- Every call works inside a per-request temporary directory that is removed in a `finally`
  block, before the response reaches its reader.
- The vendored prototype modules were a workstation tool and record the absolute paths they
  worked on, which name that directory.

## Decision

- Every audit record and every warning the engine returns names a file by its LOGICAL name —
  the client's upload filename, or the convention-named output — and never by a workspace path.
- Registration is request-scoped: `track_workspace()` declares the directory,
  `name_file()` binds a workspace path to the name the caller knows it by, keeping only the final
  component of client-supplied input. Engine-named outputs need no binding: their basename IS
  the logical name.
- Normalization happens ONCE, on the way out, in `to_audit_events()` and `warnings_text()`
  (`engine/app/audit.py`).
- The vendored files stay untouched; the collecting logger is substituted in their namespaces.
- A bare workspace directory leaves as `(workspace)`. An absolute path under the system temp
  root embedded in text the engine did not compose is reduced to its basename as a last resort.

## Alternatives rejected

- RETURN THE PATHS AS RECORDED. The reader would keep a reference to a directory that no longer
  exists — noise in a record that is kept as evidence.
- PATCH THE VENDORED MODULES to record logical names. The vendored prototype is kept verbatim;
  editing it forfeits that property for a formatting concern.

## Consequences

- A route that writes into a workspace must call `track_workspace()`, and `name_file()` for
  every client-supplied file, or its records leave carrying paths.
- `AuditEvent.detail` is open (`additionalProperties: true`), so this is a change of value, not
  of shape: no contract version is involved.
- Guards: `test_the_audit_trail_names_files_logically_never_by_engine_path` in
  `engine/tests/test_populatie.py` and `engine/tests/test_nj.py`.
