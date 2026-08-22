# User stories

## Layout

`docs/stories/` contains three collections:

- `as-is/` — the living story collection: current intent, tracked as inputs
  arrive and work is orchestrated. Written only by the docs-agent, readable by
  every agent. See `docs/stories/as-is/README.md`.
- `as-reference/` — historical material, kept for reference only. See
  `docs/stories/as-reference/README.md` for its contents and how to read it.
- `support/` — material supplied with an input, cited as evidence by the
  documents that specify it. Written by nobody, readable by every agent. See
  `docs/stories/support/README.md`.

`as-reference/` is not a specification: it holds no power and governs no
implementation. It is not writable — by any role, for any task. Consult it
only when the user asks for it with a `HISTORY-ACCESS:` grant in the task
prompt; resolve any disagreement with the code or with the task's input in
favour of the code or the input.

There is no inbound story channel. The overlay model — Prototype B and C layered
onto A to derive an as-is specification — is closed; it is neither pending nor
future work. Former Prototype A/B source trees lived under `docs/legacy/` and
were removed; recover them from git history if needed.
