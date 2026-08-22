# 0056 — Activation link bound to the login address by a signed marker

- Status: accepted
- Date: 2026-08-20

## Context

The guest password-setup link (ADR-0028) named an account by id alone. Moving a pending
account's login address before the link is used left the old link live: it still set the
password of the account now reachable at a different mailbox, and the platform had no way to
tell that the address on file and the address the link was mailed to had diverged. A token
table would need its own expiry and cleanup; the link is meant to carry its own validity
(ADR-0028) with nothing persisted.

## Decision

- The link carries `issued`, a signed query parameter holding
  `hash_hmac('sha256', "{id}|{email}", app.key)` — a marker over the address the link was
  minted for (`TenantUserActivation::marker()`).
- `ChoosePassword` recomputes the marker from the account's live row on arrival and refuses
  unless it matches (`hash_equals`). A marker that no longer matches renders ADR-0055's
  account-state page.
- `TenantUserActivation::url()` is the only minter of this route for every caller, including
  the console's `PasswordSetupLink`, so a second minter cannot forget the marker.
  `$validityDays` is a required parameter with no default — the two callers' windows
  (`TenantUserActivation::VALIDITY_DAYS`, `PasswordSetupLink::VALIDITY_DAYS`, both 7 today)
  stay independent constants that a shared default could not silently couple.
- The guest route refuses a correctly signed link that carries no marker at all — fail closed.
  Nobody can forge a marker-less link past the signature, but a future minter could omit one,
  and a link that skips the check is a credential no address change can revoke. The
  requirement is scoped to the guest route (`ChoosePassword::$fromSignedLink`, set from
  whether the `{user}` route parameter is present); the authenticated route has no link and no
  marker to check, and names its visitor by session instead.
- `TenantUsers::update()` re-issues the activation link, after the commit, whenever it moves
  the address of an account with `password_set_at` still NULL — the same act that retires the
  link the old address held.

## Consequences

- Moving a pending account's address revokes every activation link in flight, console link
  included, with no token table and nothing to expire.
- The marker is a pure function of the current address: moving it away and back within the
  validity window re-validates every link minted for that address. Revocation holds only
  while the address stays changed — a residual property of the stateless design, not a defect.
- The console's link is not reserved for the tenant's originally bootstrapped administrator —
  `PasswordSetupLink::findPendingAdministrator()` follows the earliest row still holding the
  Administrator role, which can become a later account once the bootstrapped row is demoted.
  ADR-0028's "for the originally bootstrapped administrator only" no longer holds; this record
  supersedes it on that point.
- A future guest route sharing this page must set `$fromSignedLink` correctly or inherit a
  silent bypass of the marker check.
