# Runtime topology

Framework rule. Project values: `project-context/runtimes.md`.

- One file per runtime under the project's topology directory. Adding a runtime costs one file
  plus one row in the project's architecture doc — nothing else changes.
- The system description is independent of which runtime is up. A claim that holds only in one
  runtime belongs in that runtime's file.
- Inputs more than one runtime reads live once in `runtimes.shared_inputs_dir`, owned by no
  runtime. No runtime holds a copy, and no runtime resolves a path into another runtime's
  directory.
- `runtimes.generated_dirs` are generated. Edit the source, re-run the generator, never
  hand-edit the copy.
- Verify a topology change by a full boot of that runtime (`commands.env_full_boot`), never
  a restart (FI-16).
- Bring-up is reproducible from a fresh clone to a working install by one documented command.
  A manual step introduced into that path is a bug.
- Environment files that the tooling rewrites are volatile: durable configuration belongs in
  the project's committed configuration, never in a file a boot regenerates.
- Every runtime states its service pins. A floating tag is a topology defect.
