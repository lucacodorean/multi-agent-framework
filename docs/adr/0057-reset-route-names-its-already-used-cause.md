# 0057 — Reset route names its already-used cause

- Status: accepted
- Date: 2026-08-20

## Context

`TenantPasswordReset::sendLink()` mints a reset link only for an account that
already exists, is active, and already holds a secret. Whoever holds a
correctly signed reset link has therefore already been told all three facts
by the link's existence. A marker mismatch (the account reset its password
since the link was minted) adds only that the secret moved — not any of the
three facts ADR-0055 refuses to disclose on the sibling setup route, where the
account is PENDING and "this account is now active" is genuinely new
information.

## Decision

`ResetPassword::resettableUser()` (`app/Filament/Auth/Pages/ResetPassword.php`)
splits its refusals:

- Reachability refusals stay collapsed and nameless — account absent,
  deactivated, never past activation, or no marker on the URL — bare 404, for
  the same reason ADR-0055 collapses them on the setup route.
- A marker mismatch is named: `refuseAsSpent()` renders
  `resources/views/auth/password-reset-spent.blade.php` through
  `auth.refusal-layout`, 404, heading "Link folosit", message "Linkul de
  resetare a parolei nu mai este valid. Parola a fost deja resetata folosind
  acest link."
- The mismatch check runs after the reachability block, not folded into it:
  `TenantPasswordReset::marker()` refuses to compute for an account whose
  `password_set_at` is null, which the reachability block is what rules out.

This scopes ADR-0055's collapse rule to the setup route; the reset route
diverges by this decision.

## Consequences

- The message asserts the password was reset *using this link*. A marker
  mismatch cannot distinguish that from a reset performed with a newer link
  or by any other path, so the sentence can be false in a way the reader
  cannot detect.
- The two sibling routes now answer the same user action differently by
  design. This is a deliberate split, not the unowned drift `docs/backlog.md`
  BL-024 described; BL-024 is narrowed to the remaining, undecided divergence
  (the expired page).
- Pinned by `tests/Feature/Auth/TenantPasswordResetTest.php`: "it refuses a
  used reset link, naming the cause", "it refuses the submit of a reset link
  spent after the form was opened", "it keeps every reachability refusal on
  the reset route collapsed and nameless".
