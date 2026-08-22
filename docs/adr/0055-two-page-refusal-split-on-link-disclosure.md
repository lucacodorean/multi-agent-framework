# 0055 — Two-page refusal split on what the signed link already discloses

- Status: accepted
- Date: 2026-08-20

## Context

The guest password-setup route (`/{tenant}/setare-parola/{user}`) refuses a signed link for
several distinct reasons: a tampered signature, an expired signature, an unknown or inactive
account, an account that already chose a secret, a link whose address marker no longer names
the account, a marker-less link, or a session authenticated as someone else. A single
undifferentiated 404 for all of them is safe but throws away information the visitor already
has; a distinct message per cause is an account-enumeration oracle for causes the visitor does
not already have.

## Decision

Split refusals into exactly two pages, on what the URL already discloses to whoever holds it:

- **Expiry names its cause.** `expires` is a plain, unsigned query parameter of the link; its
  holder can already read it and compare against the current time offline. Naming expiry in
  the response discloses nothing the holder could not compute themselves. Answered by
  `ValidatePasswordSetupSignature` as 403, before the route reaches the account.
- **Every refusal that turns on account state collapses to one constant body.** Account
  existence, activity, whether a secret was already chosen, marker mismatch (address moved),
  missing marker, and signed-in-as-someone-else are all facts about server-side state the link
  cannot disclose on its own. Telling them apart would let a stale link's holder learn things
  about the account it never told them. Answered by `ChoosePassword::refuseAsUnavailable()` as
  one 404 with one view, `auth.password-setup-unavailable`, through one call site.
- Order signature-then-expiry: `URL::hasCorrectSignature()` runs before
  `URL::signatureHasNotExpired()`, so a forged `expires` cannot buy the friendlier page.
- The account-state page never redirects, including to the tenant-scoped panel root — a
  redirect target can itself be a channel back to a real vs. unreal tenant.

## Consequences

- Adding a new account-state refusal cause never earns it a new message; it joins the existing
  constant body through `refuseAsUnavailable()`.
- The invariant that all account-state causes are byte-identical (status, body, headers,
  cookie names) is pinned by an equality assertion across causes, not by repeating one
  literal per test.
- The sibling reset route (`ValidatePasswordResetSignature`) does not follow this split — it
  still throws a framework-minimal 403 on expiry. Harmonising the two is unowned work
  (`docs/backlog.md`).
- A future minter that skips the marker, or a future refusal cause that is tempted to say more,
  breaks this decision silently unless it routes through the same one call site.
