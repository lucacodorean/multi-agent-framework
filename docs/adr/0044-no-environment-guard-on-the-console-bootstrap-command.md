# 0044 — No environment guard on the console bootstrap command

- Status: accepted
- Date: 2026-08-20

## Context

- `console_users` has exactly one writing surface, the console panel at `/consola`, and that
  panel authenticates against `console_users`. An empty roster locks everybody out of the very
  page that fills it — a fresh checkout, a restored environment and a first production install
  are each a console nobody can reach.
- `console:administrator` (`app/Console/Commands/ConsoleAdministrator.php`) is the only way in.
  It is idempotent on the address exactly as stored, so an install hook can re-run it.
- `console_users` has no `password_set_at` column
  (`database/migrations/2026_07_28_000100_create_console_users_table.php`), so a console account
  is created WITH its secret or not at all. ADR-0028's mailed-link answer does not transfer.

## Decision

- The command carries NO environment guard and no production confirmation. It runs in every
  environment, production included.
- No seeder creates a console operator. `Database\Seeders\DatabaseSeeder` stays empty.
- Every operator is a named person, registered through `App\Auth\ConsoleAdministrators`, which
  journals the act to the lifecycle journal.
- Re-running is non-destructive: an existing account keeps its stored secret unless
  `--password` is passed, and re-offering the secret it already has is not a rotation.

## Alternatives rejected

- GUARD THE COMMAND TO NON-PRODUCTION. Production is the one place where a locked-out console
  cannot be repaired by any other means the application offers; a guard turns the recovery tool
  off precisely where recovery has no alternative.
- SEED A BOOTSTRAP ACCOUNT. A seeded operator is a shared credential with a name nobody owns,
  while the lifecycle journal attributes every console act to a named person.

## Consequences

- Console access is only as strong as shell access to a deployment. No application-level
  control narrows that, and none is added.
- A later admin surface for `console_users` does not retire this command: it stays the recovery
  path, so it must keep working without the panel.
- `--password` lands in shell history; the interactive prompt is the default and is raised only
  where a secret is genuinely required.
