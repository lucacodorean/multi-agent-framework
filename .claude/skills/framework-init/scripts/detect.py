#!/usr/bin/env python3
"""Scan a repository and propose what a project context can say about it.

Emits JSON on stdout with four sections:

  unit       where the knowledge base is, its version, what it declares
  derived    values read off a file, each with the file that proves it
  assumed    values nobody stated but that are safe defaults, marked so they are easy to correct
  decisions  what this script refuses to guess, as questions for a human

The refusals are the point. Everything in `decisions` is a judgement that encodes intent, and a
plausible guess there becomes a rule every future agent obeys. See references/human-gates.md.

Usage:  detect.py [repo-root] [--kb PATH]
"""
import json, os, re, subprocess, sys
from pathlib import Path

# Manifests, task runners, runtime and CI markers. Kept here rather than in the skill's prose so
# the skill itself names no ecosystem: a framework that mentions one stack has assumed it.
MANIFESTS = [
    ("package.json", "JavaScript/TypeScript"), ("composer.json", "PHP"),
    ("pyproject.toml", "Python"), ("requirements.txt", "Python"), ("setup.py", "Python"),
    ("go.mod", "Go"), ("Cargo.toml", "Rust"), ("Gemfile", "Ruby"),
    ("pom.xml", "Java"), ("build.gradle", "Java/Kotlin"), ("build.gradle.kts", "Java/Kotlin"),
    ("mix.exs", "Elixir"), ("pubspec.yaml", "Dart"), ("Package.swift", "Swift"),
    ("*.csproj", ".NET"), ("*.sln", ".NET"),
]
RUNTIME_MARKERS = [
    ("docker-compose.yml", "container topology"), ("docker-compose.yaml", "container topology"),
    ("compose.yml", "container topology"), ("compose.yaml", "container topology"),
    ("Dockerfile", "container image"), (".devcontainer", "dev container"),
    ("Procfile", "process types"), ("Vagrantfile", "virtual machine"),
    ("k8s", "orchestration manifests"), ("kubernetes", "orchestration manifests"),
    ("helm", "orchestration charts"), ("terraform", "infrastructure definitions"),
]
CI_MARKERS = [
    (".github/workflows", "GitHub Actions"), (".gitlab-ci.yml", "GitLab CI"),
    ("Jenkinsfile", "Jenkins"), (".circleci", "CircleCI"),
    ("azure-pipelines.yml", "Azure Pipelines"), (".drone.yml", "Drone"),
    ("bitbucket-pipelines.yml", "Bitbucket Pipelines"),
]
# Script names that usually mean the same thing across ecosystems.
COMMAND_HINTS = {
    "test": ("commands.test", ["test", "tests", "spec", "check", "pytest", "phpunit", "jest", "vitest"]),
    "lint": ("commands.style_check", ["lint", "style", "format", "fmt", "pint", "prettier", "rubocop"]),
    "analyse": ("commands.static_analysis", ["analyse", "analyze", "typecheck", "types", "stan", "mypy", "tsc"]),
    "install": ("commands.dependency_install", ["install", "setup", "bootstrap", "deps"]),
    "up": ("commands.env_up", ["up", "start", "serve", "dev", "run"]),
}
SKIP_DIRS = {".git", "node_modules", "vendor", "venv", ".venv", "target", "dist", "build",
             "__pycache__", ".idea", ".vscode", ".mypy_cache", ".pytest_cache"}


def sh(args, cwd):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=15).stdout.strip()
    except Exception:
        return ""


def find_unit(root: Path, explicit=None):
    """The unit is a directory holding framework/. Convention is knowledge-base/ at the root."""
    if explicit:
        p = Path(explicit)
        return p if (p / "framework").is_dir() else None
    for cand in [root / "knowledge-base", root]:
        if (cand / "framework").is_dir():
            return cand
    for cand in sorted(root.iterdir()) if root.is_dir() else []:
        if cand.is_dir() and cand.name not in SKIP_DIRS and (cand / "framework").is_dir():
            return cand
    return None


def unit_facts(unit: Path, root: Path):
    """What the unit declares about itself — the derivations the skill must not duplicate."""
    fw = unit / "framework"
    forms = fw / "templates" / "project-context"
    out = {
        "path": str(unit.relative_to(root)) if unit != root else ".",
        "anchor": f"./{unit.relative_to(root)}/" if unit != root else "./",
        "version": (fw / "VERSION").read_text().strip() if (fw / "VERSION").is_file() else None,
        "context_files": sorted(p.name for p in forms.glob("*.md")) if forms.is_dir() else [],
        "members": [], "hosts": [], "artifact_kinds": [],
    }
    roster = fw / "roster.md"
    if roster.is_file():
        block = re.split(r"^## ", roster.read_text(), flags=re.M)
        for sec in block:
            if sec.startswith("Members"):
                for m in re.finditer(r"^\| `([a-z][a-z0-9-]*)` \| `roles/([a-z-]+)\.md` \| ([^|]+) \|", sec, re.M):
                    out["members"].append({"name": m.group(1), "charter": m.group(2), "tier": m.group(3).strip()})
    hosts = fw / "hosts"
    if hosts.is_dir():
        for h in sorted(hosts.glob("*.md")):
            txt = h.read_text()
            mount = re.search(r"\|\s*agent bindings\s*\|\s*`([^`]+)`", txt)
            out["hosts"].append({"id": h.stem, "binding_path": mount.group(1) if mount else None,
                                 "optional": "Optional, and not built out" in txt})
    reg = fw / "rules" / "doc-artifact-registry.md"
    if reg.is_file():
        sec = reg.read_text().split("## Standard kinds")
        if len(sec) > 1:
            for m in re.finditer(r"^\| ([^|`][^|]*?) \| `([^`]+)` \| `([a-z-]+)` \|([^|]*)\|([^|]*)\|", sec[1], re.M):
                out["artifact_kinds"].append({"kind": m.group(1).strip(), "path": m.group(2),
                                              "lifecycle": m.group(3), "budgeted": m.group(5).strip()})
    return out


def scan(root: Path, unit: Path):
    derived, assumed = [], []

    def add(target, key, value, evidence):
        target.append({"key": key, "value": value, "evidence": evidence})

    # --- identity
    name = root.name
    add(assumed, "project.name", name, f"the repository directory is named {name}")
    add(assumed, "project.slug", re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-"),
        "derived from the directory name; a project may prefer another")
    head = sh(["git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"], root)
    if head:
        add(derived, "project.repo.default_branch", head.split("/")[-1], "git: origin/HEAD")
    else:
        # The branch you happen to be on is not the branch reviews diff against. Guessing it
        # would put a wrong value where a reviewer will trust it, so this is an assumption.
        cur = sh(["git", "branch", "--show-current"], root)
        cands = [b.strip().lstrip("* ") for b in sh(["git", "branch", "--format=%(refname:short)"], root).splitlines()]
        likely = next((b for b in ("main", "master", "trunk", "develop") if b in cands), cur)
        if likely:
            add(assumed, "project.repo.default_branch", likely,
                f"origin/HEAD is not set locally; picked from the local branches ({', '.join(cands[:6]) or 'none'})")
    add(assumed, "project.docs_language", "English", "no other language was detected in the tree")

    # --- stack, from whatever manifests exist
    langs, manifests = [], []
    for pattern, lang in MANIFESTS:
        hits = list(root.glob(pattern)) if "*" in pattern else ([root / pattern] if (root / pattern).exists() else [])
        for h in hits:
            manifests.append(h.name)
            if lang not in langs:
                langs.append(lang)
    if langs:
        add(derived, "stack.languages", ", ".join(langs), ", ".join(sorted(set(manifests))))
    else:
        add(derived, "stack.languages", "none — no dependency manifest found",
            "no recognised manifest at the repository root")

    # --- commands, from task runners
    found = {}
    # A script name is not a command. Record how each runner is actually invoked, so the value
    # can be run rather than interpreted.
    for manifest, invoke in (("package.json", "npm run {}"), ("composer.json", "composer {}")):
        f = root / manifest
        if f.is_file():
            try:
                for s in (json.loads(f.read_text()).get("scripts") or {}):
                    found[s] = (f"{manifest} scripts", invoke.format(s))
            except Exception:
                pass
    for runner, pat, invoke in (("Makefile", r"^([a-zA-Z][\w-]*):", "make {}"),
                                ("justfile", r"^([a-zA-Z][\w-]*):", "just {}"),
                                ("Taskfile.yml", r"^  ([a-zA-Z][\w-]*):", "task {}")):
        f = root / runner
        if f.is_file():
            for m in re.finditer(pat, f.read_text(), re.M):
                found.setdefault(m.group(1), (runner, invoke.format(m.group(1))))
    for _, (key, names) in COMMAND_HINTS.items():
        for target in names:
            hit = next((k for k in found if k.lower() == target or k.lower().startswith(target + ":")), None)
            if hit:
                where, script = found[hit]
                add(derived, key, script, f"{where}: {hit}")
                break

    # --- runtimes and gates: presence only. What they contain is topology, and topology is a
    #     decision about how the project is run, not a fact about its files.
    runtimes = [(n, d) for n, d in RUNTIME_MARKERS if (root / n).exists()]
    add(derived, "runtimes", f"{len(runtimes)} marker(s)" if runtimes else "none",
        ", ".join(f"{n} ({d})" for n, d in runtimes) or "no runtime marker at the repository root")
    gates = [(n, d) for n, d in CI_MARKERS if (root / n).exists()]
    add(derived, "ci.gates", f"{len(gates)} host(s)" if gates else "none",
        ", ".join(f"{n} ({d})" for n, d in gates) or "no CI configuration found")

    # --- the tree, as raw material for the ownership question only
    tops = sorted(p.name + "/" for p in root.iterdir()
                  if p.is_dir() and p.name not in SKIP_DIRS and not p.name.startswith(".")
                  and p != unit)
    return derived, assumed, tops


def decisions(tops, unit_info):
    """Every entry here is a decision, not a value. See references/human-gates.md."""
    members = ", ".join(m["name"] for m in unit_info["members"]) or "the roster"
    return [
        {"gate": "ownership map", "blocking": True,
         "question": f"Which member owns each of these paths, and which members own nothing here? Candidates: {', '.join(tops) or 'no top-level directories'}. Members: {members}.",
         "why": "Layout is evidence of intent, not a statement of it. Ownership decides who may change what, which is a team decision (FI-05).",
         "recommendation": "Propose a map from the tree, name the carve-outs you are unsure about, and leave members with no real area empty and undispatched."},
        {"gate": "interfaces and versioning", "blocking": False,
         "question": "Which files are published interfaces — promised to a consumer and changed only deliberately — and how is a version stated on them?",
         "why": "A scan can find serialized shapes; it cannot tell a promise from an internal detail. That distinction is the boundary (FI-07).",
         "recommendation": "If nothing is published, say none — an admitted gap beats an invented scheme a consumer would trust."},
        {"gate": "convention slots", "blocking": False,
         "question": "Where do this project's code-level and structural rules already live, if anywhere — a style guide, a wiki page, repeated review comments?",
         "why": "A convention is what the team decided, not what the code currently does. Inferred from three occurrences it outlaws the fourth, better approach.",
         "recommendation": "Point the two slots at existing documents, or leave the stubs describing what belongs in each."},
        {"gate": "domain vocabulary", "blocking": False,
         "question": "Which domain terms should a newcomer be given, and what does each mean in one line? Do requirements arrive in a different language than the docs are written in?",
         "why": "Frequent identifiers are extractable; their meaning to the business is not, and a wrong glossary teaches every agent the wrong word.",
         "recommendation": "An empty glossary is fine. Only record terms someone confirms."},
        {"gate": "destructive operations", "blocking": True,
         "question": "Which commands must never run without explicit approval — data deletion, environment teardown, force-pushing, anything against shared resources?",
         "why": "Whether an operation is destructive depends on what it touches here and what the team considers recoverable. No script can tell those apart.",
         "recommendation": "Record the answer verbatim. An empty list means nothing is classified as destructive, which the working agreement relies on."},
        {"gate": "documentation budgets", "blocking": False,
         "question": "Which documentation kinds do you want budgeted, at roughly what size, and do you want a tolerance for small overruns?",
         "why": "Deriving budgets from current file sizes ratifies today's sprawl and then becomes the target the doc writer compresses toward.",
         "recommendation": f"Start from the {len(unit_info['artifact_kinds'])} kinds the registry suggests; only the ones marked budgeted need a number."},
    ]


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    kb = next((sys.argv[i + 1] for i, a in enumerate(sys.argv) if a == "--kb"), None)
    root = Path(args[0] if args else ".").resolve()
    if not root.is_dir():
        print(json.dumps({"error": f"{root} is not a directory"}), file=sys.stderr)
        return 2
    unit = find_unit(root, kb)
    if unit is None:
        print(json.dumps({"error": "no knowledge base found — a directory holding framework/. "
                                   "This skill instantiates a vendored unit; it does not fetch one."}, indent=2))
        return 1
    info = unit_facts(unit, root)
    derived, assumed, tops = scan(root, unit)
    print(json.dumps({
        "repo": str(root), "unit": info,
        "derived": derived, "assumed": assumed,
        "top_level": tops,
        "decisions": decisions(tops, info),
        "note": "decisions[] are refusals, not gaps. Ask; do not fill them in.",
    }, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
