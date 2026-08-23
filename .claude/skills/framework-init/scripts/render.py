#!/usr/bin/env python3
"""Write an instantiation from approved answers. Nothing here decides anything.

Everything this writes is either copied from a blank form, rendered from a template, or a value
a human approved. What it cannot place, it leaves as the form's own marked placeholder and
reports — because a placeholder the validator flags is recoverable, and an invented value is a
rule nobody agreed to.

Usage:  render.py --kb PATH --answers answers.json [--repo PATH] [--dry-run]

answers.json:
  {
    "values":   {"project.name": "...", "commands.test": "...", ...},   # contract key -> value
    "roster":   {"<member>": {"dispatched": true, "owns": "...", "carve_outs": "...",
                              "stack": "...", "verify": "...", "destructive": "...",
                              "duties": ["..."], "description": "...", "position": "..."}},
    "artifact_types": [{"type","path","writer","authorization","lifecycle","budget"}],
    "write_paths":    [{"path","budget"}],
    "glossary":       [{"term","language","meaning"}],
    "gates":          [{"name","proves","command","serialized"}],
    "runtimes":       [{"id","doc","boot","verify"}],
    "destructive":    ["operation needing an approved task", ...],
    "enforcement":    [{"convention","by"}],
    "outside_roster": [{"path","why"}],
    "read_gated":     [{"path","grant"}],
    "hosts":          ["claude-code", ...]        # omit to use every non-optional host
  }
"""
import json, re, shutil, sys
from pathlib import Path

REPORT = {"written": [], "filled": [], "unresolved": [], "skipped": [], "notes": []}


def note(msg):
    REPORT["notes"].append(msg)


def roster_members(fw: Path):
    out = []
    r = fw / "roster.md"
    if not r.is_file():
        return out
    for sec in re.split(r"^## ", r.read_text(), flags=re.M):
        if sec.startswith("Members"):
            for m in re.finditer(r"^\| `([a-z][a-z0-9-]*)` \| `roles/([a-z-]+)\.md` \| ([^|]+) \| ([^|]+) \|", sec, re.M):
                out.append({"name": m.group(1), "role": m.group(2),
                            "tier": m.group(3).strip(), "mandate": m.group(4).strip()})
    return out


def hosts(fw: Path, wanted):
    out = []
    for h in sorted((fw / "hosts").glob("*.md")):
        txt = h.read_text()
        optional = "Optional, and not built out" in txt
        if wanted is not None and h.stem not in wanted:
            continue
        if wanted is None and optional:
            REPORT["skipped"].append(f"host {h.stem}: declared optional and not built out")
            continue
        mount = re.search(r"\|\s*agent bindings\s*\|\s*`([^`]+)`", txt)
        fm = re.search(r"```yaml\n(.*?)```", txt, re.S)
        out.append({"id": h.stem, "mount": mount.group(1) if mount else None,
                    "frontmatter": fm.group(1) if fm else ""})
    return out


def fill_rows(text: str, values: dict, source: str):
    """Replace the value cell of any '| `key` | ... |' row whose key was answered."""
    def sub(m):
        key, cell = m.group(1), m.group(2)
        if key in values:
            REPORT["filled"].append(f"{source}: {key}")
            return f"| `{key}` | {values[key]} |"
        if "<" in cell:
            REPORT["unresolved"].append(f"{source}: {key}")
        return m.group(0)
    return re.sub(r"^\| `([a-z_][a-z0-9_.]*)` \|([^|]*)\|", sub, text, flags=re.M)


def fill_bullets(text: str, values: dict, source: str):
    """Replace the value of any '- `key`: <prompt>' bullet whose key was answered.

    A scalar does not always live in a table: runtimes.md states two of its keys as bullets, and
    fill_rows only reads table rows.
    """
    def sub(m):
        key = m.group(1)
        if key in values:
            REPORT["filled"].append(f"{source}: {key}")
            return f"- `{key}`: {values[key]}"
        if "<" in m.group(2):
            REPORT["unresolved"].append(f"{source}: {key}")
        return m.group(0)
    return re.sub(r"^- `([a-z_][a-z0-9_.]*)`: (.*)$", sub, text, flags=re.M)


def render_bullets(text: str, items, source: str, section: str):
    """Replace a '- <prompt>' line with one bullet per item, inside the named section."""
    if not items:
        return text
    parts = re.split(r"(?m)^(?=## )", text)
    for i, part in enumerate(parts):
        if part.startswith(f"## {section}"):
            lines = part.splitlines()
            for j, ln in enumerate(lines):
                if re.match(r"^- `?<[^<>]*>`?$", ln.strip()):
                    lines[j:j + 1] = [f"- {it}" for it in items]
                    REPORT["filled"].append(f"{source}: {len(items)} bullet(s)")
                    parts[i] = "\n".join(lines) + "\n"
                    return "".join(parts)
            note(f"{source}: no bullet prompt in '## {section}'; items not inserted")
            return text
    note(f"{source}: no '## {section}' section found; items not inserted")
    return text


def render_table(text: str, header_cells: int, rows, source: str, section: str = None):
    """Replace the placeholder row of one table, found by its section heading and cell count.

    Cell count alone is ambiguous: a form often has several two-column tables, and the first
    match is rarely the intended one. The heading disambiguates.
    """
    if not rows:
        return text
    if section:
        parts = re.split(r"(?m)^(?=## )", text)
        for i, part in enumerate(parts):
            if part.startswith(f"## {section}"):
                parts[i] = render_table(part, header_cells, rows, source)
                return "".join(parts)
        note(f"{source}: no '## {section}' section found; rows not inserted")
        return text
    lines = text.splitlines()
    for i, ln in enumerate(lines):
        # split on unescaped pipes: a cell may legitimately contain '\|'
        cells = [c for c in re.split(r"(?<!\\)\|", ln)[1:-1]] if ln.startswith("|") else []
        if len(cells) == header_cells and "<" in ln and "---" not in ln:
            lines[i:i + 1] = rows
            REPORT["filled"].append(f"{source}: {len(rows)} row(s)")
            return "\n".join(lines) + "\n"
    note(f"{source}: no placeholder row with {header_cells} cells found; rows not inserted")
    return text


def main():
    a = sys.argv[1:]
    def opt(flag, default=None):
        return a[a.index(flag) + 1] if flag in a else default
    kb = Path(opt("--kb", "knowledge-base")).resolve()
    dry = "--dry-run" in a
    ans = json.loads(Path(opt("--answers")).read_text()) if opt("--answers") else {}
    if not (kb / "framework").is_dir():
        print(json.dumps({"error": f"{kb} does not hold framework/"}, indent=2)); return 2
    fw, repo = kb / "framework", Path(opt("--repo", kb.parent)).resolve()
    values = ans.get("values", {})
    forms = fw / "templates" / "project-context"
    ctx = kb / "project-context"

    def write(path: Path, text: str):
        REPORT["written"].append(str(path.relative_to(repo)))
        if dry:
            return
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    # 1. context files, from the blank forms — the forms are the schema, so copy and fill
    ctx.mkdir(parents=True, exist_ok=True)
    for form in sorted(forms.glob("*.md")):
        target = ctx / form.name
        if target.is_file() and "<" not in target.read_text():
            REPORT["skipped"].append(f"{target.relative_to(repo)}: already filled, left alone")
            continue
        text = fill_bullets(fill_rows(form.read_text(), values, form.name), values, form.name)
        if form.name == "ci.md":
            text = render_table(text, 4, [
                "| {} | {} | `{}` | {} |".format(g["name"], g.get("proves", "—"),
                                                 g.get("command", "—"), g.get("serialized", "no"))
                for g in ans.get("gates", [])], "ci gates")
        if form.name == "runtimes.md":
            text = render_table(text, 4, [
                "| {} | {} | `{}` | {} |".format(r["id"], r.get("doc", "—"),
                                                 r.get("boot", "—"), r.get("verify", "—"))
                for r in ans.get("runtimes", [])], "runtimes")
        if form.name == "commands.md":
            text = render_bullets(text, ans.get("destructive", []), "destructive operations",
                                  "Destructive")
        if form.name == "conventions.md":
            text = render_table(text, 2, [f"| {e['convention']} | {e.get('by', 'nothing')} |"
                                          for e in ans.get("enforcement", [])], "enforcement",
                                section="Enforcement")
        if form.name == "ownership.md":
            text = render_table(text, 2, [f"| `{o['path']}` | {o.get('why', '—')} |"
                                          for o in ans.get("outside_roster", [])],
                                "outside the roster", section="Outside the roster")
        if form.name == "docs-policy.md":
            text = render_table(text, 2, [f"| `{r['path']}` | {r['grant']} |"
                                          for r in ans.get("read_gated", [])], "read-gated paths",
                                section="Read-gated paths")
            text = render_table(text, 2, [f"| `{w['path']}` | {w.get('budget','none')} |"
                                          for w in ans.get("write_paths", [])], "write paths",
                                section="Allowed write paths")
            text = render_table(text, 6, [
                "| {} | `{}` | {} | {} | {} | {} |".format(
                    t["type"], t["path"], t.get("writer", "—"), t.get("authorization", "—"),
                    t.get("lifecycle", "—"), t.get("budget", "none"))
                for t in ans.get("artifact_types", [])], "artifact types",
                section="Artifact types")
        if form.name == "glossary.md":
            text = render_table(text, 3, [f"| {g['term']} | {g.get('language','en')} | {g['meaning']} |"
                                          for g in ans.get("glossary", [])], "glossary")
        write(target, text)

    # 1b. sub-scaffolds inside the forms directory — the architecture directory is a directory
    # by design (project.architecture_dir), so it is copied whole rather than filled row-wise.
    for sub in sorted(d for d in forms.iterdir() if d.is_dir()):
        for form in sorted(sub.glob("*.md")):
            target = ctx / sub.name / form.name
            if target.is_file() and "<" not in target.read_text():
                REPORT["skipped"].append(f"{target.relative_to(repo)}: already filled, left alone")
                continue
            write(target, fill_rows(form.read_text(), values, f"{sub.name}/{form.name}"))

    # 2. per-member ownership, appended to the roster form's table where answers exist
    members = roster_members(fw)
    ro = ans.get("roster", {})
    if members and ro:
        rows, duties = [], []
        for m in members:
            r = ro.get(m["name"], {})
            if r.get("dispatched") is False:
                rows.append("| `{}` | — not dispatched: {} | — | — | — | — |".format(
                    m["name"], r.get("reason", "no ownership area in this project")))
                continue
            rows.append("| `{}` | {} | {} | {} | {} | {} |".format(
                m["name"], r.get("owns", "<owns>"), r.get("carve_outs", "—"),
                r.get("stack", "—"), r.get("verify", "—"), r.get("destructive", "—")))
            for d in r.get("duties", []):
                duties.append((m["name"], d))
        target = ctx / "ownership.md"
        text = target.read_text() if target.is_file() else (forms / "ownership.md").read_text()
        text = render_table(text, 6, rows, "roster ownership")
        if duties:
            block = ["", "## `member.duties` — beyond the charter", ""]
            for name in dict.fromkeys(n for n, _ in duties):
                block += [f"### {name}", ""] + [f"{i+1}. {d}" for i, (n, d) in
                                                enumerate([x for x in duties if x[0] == name])] + [""]
            text = text.rstrip() + "\n" + "\n".join(block)
        write(target, text)

    # 3. bindings — one per member per host, from the one template
    tpl = (fw / "templates" / "agent-binding.md.template").read_text()
    for host in hosts(fw, ans.get("hosts")):
        if not host["mount"]:
            note(f"host {host['id']}: no binding mount point declared; skipped"); continue
        for m in members:
            r = ro.get(m["name"], {})
            if r.get("dispatched") is False:
                REPORT["skipped"].append(f"{host['id']}/{m['name']}: not dispatched")
                continue
            b = tpl
            for k, v in {
                "kb.root": values.get("kb.root", f"{kb.name}/"),
                "member.name": m["name"], "member.role": m["role"],
                "member.role_summary": r.get("description", m["mandate"]),
                "member.owns_summary": r.get("owns", "the paths its member record names"),
                "member.use_when": r.get("use_when", "work inside its ownership area"),
                "member.not_owns_summary": r.get("not_owns", "another member's area"),
                "member.position_sentence": r.get("position", f"tier {m['tier']}"),
            }.items():
                b = b.replace("{{%s}}" % k, str(v))
            write(repo / host["mount"].replace("<member>", m["name"]), b)

    # 4. documentation directories and the intake channel, from the approved kinds
    for t in ans.get("artifact_types", []):
        p = t.get("path", "")
        if p.endswith("/") or "<" in p or "*" in p or "NNNN" in p or "YYYY" in p:
            d = kb / re.split(r"[<*]|NNNN|YYYY", p)[0].rstrip("/")
            if d.name:
                write(d / ".gitkeep", "")
        elif p:
            channel = fw / "templates" / "artifacts" / "intake-channel.md.template"
            if t.get("lifecycle") == "append-only" and channel.is_file():
                write(kb / p, fill_rows(channel.read_text(), values, "intake channel"))

    # 4b. directories the approved write paths declare — a declared path that does not exist is a
    #     finding, and the policy is the authority on which paths this project uses
    for w in ans.get("write_paths", []):
        p = w.get("path", "")
        if not p or "<" in p or "*" in p:
            continue
        if p.endswith("/"):
            write(kb / p.rstrip("/") / ".gitkeep", "")
        elif not (kb / p).exists() and "." not in Path(p).name:
            write(kb / p / ".gitkeep", "")

    # 5. the index-and-law file
    idx = fw / "templates" / "CLAUDE.md.template"
    if idx.is_file():
        text = idx.read_text()
        for k, v in values.items():
            text = text.replace("{{%s}}" % k, str(v))
        # A placeholder the context never supplies is left standing by design: the contract's
        # § Placeholders the context does not supply names the renderer and orchestrator classes.
        NOT_OURS_PREFIX = ("run.", "task.", "phase.", "plan.", "intake.")
        NOT_OURS = {"ruling", "member.reached_through", "member.role_summary",
                    "member.use_when", "member.position_sentence", "member.owns_summary",
                    "member.not_owns_summary"}
        left = sorted(k for k in set(re.findall(r"\{\{([a-z_][a-z0-9_.]*)\}\}", text))
                      if not k.startswith(NOT_OURS_PREFIX) and k not in NOT_OURS)
        if left:
            REPORT["unresolved"] += [f"index file: {k}" for k in left]
        write(repo / "CLAUDE.md", text)

    REPORT["next"] = [f"{kb.name}/framework/bin/validate-context.sh — it must pass",
                      f"{kb.name}/framework/bin/lock-core.sh lock — a fresh unit starts unlocked"]
    print(json.dumps(REPORT, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
