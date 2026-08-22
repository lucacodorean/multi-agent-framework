# 0043 — Redact a setup link that reaches the journal, never refuse the write

- Status: accepted
- Date: 2026-08-20

## Context

- The tenant lifecycle journal is central and append-only: `App\Models\TenantLifecycleEvent`
  refuses updates and deletes. A credential written into a row can be neither revoked nor
  removed.
- A setup link is a signed, credential-bearing URL mailed to a designated contact. The journal
  records who asked, when and to which address — never the link (recorded as ADR-0009, removed
  2026-08-11).
- `reason` is free text written by whoever caught a failure, so it crosses a tier boundary
  unvalidated. The likeliest carrier is the failed-send path, where the link exists, is still
  valid, and reached nobody.

## Decision

- The caller strips the link. `App\Tenancy\TenantLifecycleJournal::withoutSetupLink()` is a
  backstop on the writing side, not the control.
- The backstop matches only the markers a signed setup URL cannot avoid — `signature=`, the
  canonical `setare-parola/` segment, and historical `set-password/` — and replaces the match
  with the visible marker `TenantLifecycleJournal::REDACTED_LINK`, in the operator's language.
  URLs in general are kept: an SMTP host inside a transport error is evidence.
- A `preg_replace` returning null is engine failure, not a non-match: redact the whole reason.
- Every redaction logs a warning naming the tenant and the operation.

Rejected: refuse the write, throwing when a link is detected. Refused: it destroys the only
record that a minted, still-valid credential never arrived, trading a small leak for a silent
one. Also rejected: truncate the reason at the match, which leaves a broken sentence and no
sign that anything was removed.

## Consequences

- A journal row is never lost to redaction; it may carry the marker in place of text.
- The warning, not a failure, is the signal that a caller's own strip is missing.
- A new setup-link route segment must be added to the backstop pattern in the same change.
