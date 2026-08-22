# 0049 — Hand-written, byte-safe multipart response parser

- Status: accepted
- Date: 2026-08-20

## Context

- There is no multipart RESPONSE parser in Laravel or Guzzle. PHP parses multipart on the way
  IN, for requests, and that machinery is not reachable from a client.
- The engine answers document operations with `multipart/form-data`, building the body by hand
  in `engine/app/multipart.py`.
- Payloads are binary. A `.docx` is a ZIP container: one multibyte-aware function applied to it
  corrupts the officer's document silently, which is the worst available failure mode.

## Decision

- `App\Engine\MultipartResponseParser` walks the body itself and is BYTE-SAFE BY CONSTRUCTION:
  `strpos`/`substr`/`strlen` only — no `mb_*` function, no regex, no assumption that a payload
  is text. Header NAMES are ASCII by RFC 9110, so lower-casing a header name is the single
  permitted exception.
- Structural rules come from the contract's encoding decision and are checked in
  `MultipartResponse::of()`, not in the parser: every part named, exactly one `result`, `result`
  without a filename.
- RFC 5987's `filename*` wins over the ASCII `filename` when both are present.
- The residual risk is ACCEPTED, not worked around: a payload containing the literal bytes
  `CRLF--<the boundary of that very response>` would mis-split.

## Alternatives rejected

- ADOPT A GENERAL MULTIPART LIBRARY. None parses a response, and a text-oriented one reintroduces
  exactly the multibyte handling this parser exists to avoid.
- DEFEND AGAINST BOUNDARY COLLISION IN THE CONSUMER. Choosing a boundary the payload does not
  contain is the producer's job — the engine derives it from a uuid4 — and scanning for a safe
  boundary is not available to a consumer that only receives the body.

## Consequences

- Any change here is byte-level work. Introducing a multibyte function or a regex over payload
  bytes is a defect, whatever it shortens.
- This parser and `engine/app/multipart.py` are the two halves of one encoding; changing either
  is a seam change and needs the contract's agreement.
- Guard: `tests/Unit/Engine/MultipartResponseParserTest.php`.
