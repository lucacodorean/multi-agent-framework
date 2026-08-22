# 0047 — Password rules make no outbound call

- Status: accepted
- Date: 2026-08-20

## Context

- Every form that accepts a password uses `Password::default()`, so the rule set is defined
  once, in `App\Providers\AppServiceProvider::definePasswordRules()`.
- `Illuminate\Validation\Rules\Password::uncompromised()` makes an outbound HTTPS call to the
  Have I Been Pwned range API on every submit.
- The platform handles institutional data and no egress policy has been stated for its
  deployments.

## Decision

- The shared rule set is a minimum length of 12 with letters, mixed case and numbers, and
  nothing that leaves the process. `uncompromised()` stays absent.
- A validation rule may not introduce a deployment's first unannounced outbound dependency.
  Adding egress is a policy decision taken outside the code, not a hardening tweak taken inside
  a validator.
- Password rules live in that one method. A page or form that defines its own rule set is
  wrong: a second definition disagrees with this one the first time either changes.

## Alternatives rejected

- ENABLE `uncompromised()`. It is a real improvement to password quality and was refused on the
  egress ground alone, not on cost or latency.
- CALL THE BREACH API OUT OF BAND, AFTER LOGIN. Same new outbound dependency, and it moves the
  refusal away from the moment the secret is chosen.

## Consequences

- A breached but conforming password is accepted.
- Turning the check on is a one-line change once an egress policy exists; what unblocks it is
  that policy, not a code review.
- Raising the strength bar means editing this method, never adding a rule at a call site.
