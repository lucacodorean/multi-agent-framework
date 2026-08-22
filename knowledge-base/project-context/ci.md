# CI

Rules: `framework/rules/ci-gates.md`.

| key | value |
|---|---|
| `ci.host_doc` | none — no CI host is wired; the gate runs on a developer machine |
| `ci.script_dir` | `framework/bin/` |
| `ci.lock` | none — the single gate starts no container and owns no constant-name resource |
| `ci.forbidden_host_tools` | none — the gate uses only `git` and POSIX text tools, so there is nothing whose host version could change its findings |

## Gates

`ci.gates`:

| name | proves | command | serialized |
|---|---|---|---|
| context | the seven checks: contract completeness, core purity (FI-23), binding thinness (FI-09), reference integrity, example isolation (FI-24), core protection (FI-25), anchors (FI-26, FI-27) | `framework/bin/validate-context.sh` | no |

One gate, one script, no wrapper — the shape `ci-gates.md` requires, at the smallest size it can
take. Nothing lints the gate itself; it is checked by `bash -n` by hand
(`commands.static_analysis`).
