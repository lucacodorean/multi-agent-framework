# 0028 — Tenant-user activation by mailed single-use link

- Status: accepted
- Date: 2026-08-14

## Context

- Tenant administrators add login accounts at `/{tenant}/utilizatori`.
- An earlier path let the administrator set a temporary password (`password_set_at` NULL)
  and forced a first-login change. That secret still traveled through the administrator.
- The human must be the only party who ever knows their own secret. The console bootstrap
  path already mails a signed setup URL (`PasswordSetupLink`); tenant-admin create did not.
- Plan approval for OIRP-1 (`OIRP-2` / `OIRP-4`) is the human instruction for this record.

## Decision

- Utilizatori create accepts name, email and US-002 role only (`TenantUsers::create`).
- Create writes an unusable random password hash, `is_active` true, `password_set_at` NULL;
  then mails a 7-day single-use signed URL to ChoosePassword's guest route
  (`TenantUserActivation`).
- The human chooses the secret on that page. Login fails until `password_set_at` is set.
- Do not collect or display a password on create/edit. Do not use an admin-set temporary
  secret as the first-login credential.
- `PasswordSetupLink` remains the console path for the originally bootstrapped
  administrator only; it is not the tenant-admin create channel.

## Consequences

- Mail delivery is on the create critical path (same transaction as the row).
- Activation and later password reset share signed-URL construction but different pages and
  windows (reset: `TenantPasswordReset`, 60 minutes, requires a chosen secret).
- Supersedes the admin-set initial-password issuance model for tenant-admin create.
