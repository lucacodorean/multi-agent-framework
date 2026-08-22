# 0052 — Two tenant-scoped login limiters, both checked before either is spent

- Status: accepted
- Date: 2026-08-20

## Context

- `RateLimiter` is handed a cache repository when its provider boots, long before any tenant is
  initialized, so limiter keys never pass through the tagged wrapper that isolates tenant cache
  entries. Every limiter key is global.
- Filament's default login key is `sha1(component|method|ip)`: it names neither the tenant nor
  the account. This is a THROTTLE-BUDGET defect, not an isolation leak — no tenant data crosses;
  what one organization can do is spend another's budget and lock it out.
- An OIR is an office reaching the platform through one public address.

## Decision

`App\Filament\Auth\Pages\Login` throttles on TWO keys, both minted by `App\Tenancy\TenantKeyspace`
and never concatenated by hand — a hand-built key that forgets the tenant segment is still a
valid GLOBAL key, so the mistake yields no error and no log line:

1. per identifier, `login:{identifier}`, Filament's own attempt count, 900-second window;
2. per source address, `login-ip:{ip}`, 60 attempts, 900-second window.

- CHECK BOTH BUDGETS BEFORE SPENDING EITHER: guard the address budget first, let Filament check
  and spend the per-identifier one, spend the address budget last. A successful login clears the
  address key.
- The identifier comes from unvalidated form state — the point is to bucket attempts before any
  credential is checked — normalized as `Illuminate\Foundation\Auth\ThrottlesLogins` normalizes
  it, so case and diacritics cannot buy a second budget.
- A missing tenant is an exception, never a fallback to a global bucket.
- The per-identifier attempt COUNT stays Filament's. This page fixes the key and the window only.

## Alternatives rejected

- ONE WIDER LIMITER. A sprayer trying each account once lands in a different bucket every time
  and trips nothing.
- PARITY THRESHOLDS FOR THE TWO. One institution behind one egress address would lock itself out
  through the front door.
- REIMPLEMENT `authenticate()` to reach the window. It forks Filament's multi-factor, timebox
  and event-firing logic into this file to change one integer.

## Consequences

- A control scoped to a SHARED resource is spent by legitimate traffic unless every non-attack
  path is excluded from it. A per-account limiter can afford to be naive; a per-address one
  cannot — a THIRD limiter inherits that obligation.
- `rateLimit()` ignores the `$decaySeconds` its caller passes: a deliberate narrowing, safe only
  while `authenticate()` is the sole rate-limited method on this page.
- `LOGIN_THROTTLE_ENABLED` off is a TRUE BYPASS (`App\Support\LoginThrottle`): neither limiter is
  read, hit or thrown from, so the two counters cannot disagree when it is flipped back on.
