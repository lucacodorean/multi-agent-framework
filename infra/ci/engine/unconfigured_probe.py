"""Assert what an engine deployment does when `ENGINE_KEY` was never set.

Deliberately NOT part of `engine/tests/`: it asserts a property of a **deployment**, and the
in-process cases proving the same behaviour skip once the suite is pointed at a container. An
engine with no shared secret is unservable but alive — every guarded operation answers 503, not
401 (no credential could succeed against nothing), while `GET /health` stays 200 `degraded`.

Usage:  python unconfigured_probe.py http://engine:8000
"""
from __future__ import annotations

import email.message
import json
import sys
import urllib.error
import urllib.request

#: Every operation the contract guards — the four served and the three stubs. Kept in
#: step with engine/tests/test_security.py::GUARDED_OPERATIONS; a path missing here is a
#: path nobody checks.
GUARDED_OPERATIONS = (
    "/populatie/process",
    "/nj/generate",
    "/pdf/convert",
    "/export/inspect",
    "/anexa3/parse",
    "/tabular/parse",
    "/esantion/verify",
)

#: The published `Problem.type` registry (contract 0.3.0). Transcribed from the contract,
#: never imported from the application: a check that imports the constant it is checking
#: passes on a typo shared with the implementation.
SHARED_SECRET_ABSENT = "urn:oir-flow:engine:problem:shared-secret-absent"

TIMEOUT_SECONDS = 30


class ProbeFailure(AssertionError):
    """One deployment-visible expectation did not hold."""


def _request(url: str, method: str) -> tuple[int, email.message.Message, bytes]:
    """Perform one HTTP call, treating an error status as a result rather than a raise.

    The headers are returned as the `HTTPMessage` itself, NOT as a dict: uvicorn emits
    header names lowercase, and `dict(headers)` would turn a case-insensitive lookup into
    a case-sensitive one that silently misses `Content-Type`.
    """
    request = urllib.request.Request(url, method=method)
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            return response.status, response.headers, response.read()
    except urllib.error.HTTPError as error:  # 4xx/5xx are expected answers here
        return error.code, error.headers, error.read()


def _check(condition: bool, message: str) -> None:
    if not condition:
        raise ProbeFailure(message)


def check_health_is_degraded_but_alive(base_url: str) -> None:
    """Alive and answering, and saying plainly that it is not configured."""
    status, _, raw = _request(f"{base_url}/health", "GET")
    _check(status == 200, f"GET /health answered {status}, expected 200 — liveness is not configuration")
    body = json.loads(raw)
    _check(
        body.get("status") == "degraded",
        f"GET /health reports status={body.get('status')!r}, expected 'degraded'",
    )
    # A degraded engine WITH a conversion backend is degraded for exactly one reason:
    # the shared secret. A null backend would mean the image lost libreoffice-writer —
    # a different defect that must not hide behind this one.
    _check(
        body.get("pdfBackend") is not None,
        "GET /health reports pdfBackend=null: the image lost its conversion backend, "
        "which is a different failure from the missing shared secret this probe asserts",
    )


def check_guarded_operation_is_unservable(base_url: str, path: str) -> None:
    """503 and the branchable type — not 401, and not a bare 500."""
    status, headers, raw = _request(f"{base_url}{path}", "POST")
    _check(status == 503, f"POST {path} answered {status}, expected 503")
    content_type = headers.get("Content-Type", "")
    _check(
        content_type.startswith("application/problem+json"),
        f"POST {path} answered content-type {content_type!r}, expected application/problem+json",
    )
    body = json.loads(raw)
    _check(body.get("status") == 503, f"POST {path} problem body says status={body.get('status')!r}")
    _check(
        body.get("type") == SHARED_SECRET_ABSENT,
        f"POST {path} problem type is {body.get('type')!r}, expected {SHARED_SECRET_ABSENT!r} — "
        "the type URI is what a consumer branches on",
    )
    _check(
        "ENGINE_KEY" in body.get("detail", ""),
        f"POST {path} detail does not name ENGINE_KEY: {body.get('detail')!r} — "
        "the prose is what tells the operator which variable to set",
    )


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: {argv[0]} <engine-base-url>", file=sys.stderr)
        return 2
    base_url = argv[1].rstrip("/")

    failures: list[str] = []
    checks = [("GET /health", lambda: check_health_is_degraded_but_alive(base_url))]
    checks += [
        (f"POST {path}", lambda path=path: check_guarded_operation_is_unservable(base_url, path))
        for path in GUARDED_OPERATIONS
    ]

    # Every check runs even after one fails: a single report beats bisecting one
    # assertion per CI run.
    for label, check in checks:
        try:
            check()
        except ProbeFailure as failure:
            failures.append(f"  {label}: {failure}")
            print(f"FAIL {label}")
        else:
            print(f"ok   {label}")

    if failures:
        print(f"\n{len(failures)} of {len(checks)} deployment checks failed:", file=sys.stderr)
        print("\n".join(failures), file=sys.stderr)
        return 1

    print(f"\nall {len(checks)} unconfigured-deployment checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
