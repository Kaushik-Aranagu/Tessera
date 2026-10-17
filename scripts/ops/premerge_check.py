#!/usr/bin/env python3
"""Merge pre-checks from the coordinator's merge recipe, run on a unified diff.

Usage: git diff --unified=0 --no-color BASE...HEAD | python3 scripts/ops/premerge_check.py [--kind auto|docs|code|scripts]

Reads the diff on stdin and never touches the network, the shell or the repo. Prints findings as
file:line plus a rule name, never the matched text. Exit 0 = clean (REPORT lines allowed), 1 = STOP.
The tree-equality check lives in scripts/ops/tree_check.sh (it needs git).
"""
import argparse
import re
import sys

# Built from pieces so this file carries no key prefix literal itself.
KEY_PREFIX = "sk" + "-ant-"
KEY_RE = re.compile(re.escape(KEY_PREFIX) + r"[A-Za-z0-9_\-]{20,}")
KEY_ASSIGN_RE = re.compile(r"(?i)(api[_-]?key|secret|token)\s*[:=]\s*[\"'][A-Za-z0-9_\-]{24,}[\"']")
BARE_PREFIX_RE = re.compile(re.escape(KEY_PREFIX))
DATA_SAFETY = ["ProcessInfo", "CommandLine", "LaunchFlags", "UserDefaults", "FileManager", "SceneStorage", "#if DEBUG"]
PY_FORBIDDEN = re.compile(r"\b(subprocess|os\.system|socket|requests|pickle)\b|\b(exec|eval)\(")
PY_IMPORT = re.compile(r"^\s*(?:import|from)\s+([A-Za-z_][\w.]*)")
PIN_RE = re.compile(r"(?i)(^|\W)(PIN|only[- ]SHA)\b")
ALLOWED_ONLY_SHA = "Only a named pin or release SHA installs: never master by itself, never any other commit."


def parse(diff):
    """Yield (path, status, [(line_no, text, added)]) per file."""
    files, cur, new_line = [], None, 0
    for raw in diff.splitlines():
        if raw.startswith("diff --git "):
            cur = {"path": raw.split(" b/", 1)[-1], "status": "M", "added": [], "removed": []}
            files.append(cur)
        elif cur is None:
            continue
        elif raw.startswith("new file mode"):
            cur["status"] = "A"
        elif raw.startswith("deleted file mode"):
            cur["status"] = "D"
        elif raw.startswith("rename from"):
            cur["status"] = "R"
        elif raw.startswith("@@"):
            m = re.search(r"\+(\d+)", raw)
            new_line = int(m.group(1)) if m else 0
        elif raw.startswith("+++") or raw.startswith("---"):
            continue
        elif raw.startswith("+"):
            cur["added"].append((new_line, raw[1:]))
            new_line += 1
        elif raw.startswith("-"):
            cur["removed"].append(raw[1:])
    return files


def kind_of(files):
    paths = [f["path"] for f in files]
    if paths and all(p.startswith("docs/") for p in paths):
        return "docs"
    if paths and all(p.startswith(("docs/", "scripts/")) for p in paths):
        return "scripts"
    return "code"


def is_test(path):
    return "Tests/" in path or path.endswith(("Tests.swift", "Test.swift"))


def check(files, kind):
    stops, reports = [], []
    if kind == "docs":
        for f in files:
            if not f["path"].startswith("docs/"):
                stops.append((f["path"], 0, "docs-only: file outside docs/"))
    for f in files:
        p = f["path"]
        for n, text in f["added"]:
            if KEY_RE.search(text) or KEY_ASSIGN_RE.search(text):
                stops.append((p, n, "secret: key-like value"))
            elif BARE_PREFIX_RE.search(text):
                bucket = reports if (kind == "code" and re.search(r"contains|hasPrefix", text)) or is_test(p) else stops
                bucket.append((p, n, "secret: bare key prefix literal (reword in docs; report-only in a refusal check)"))
        if kind == "code" and p.endswith(".swift"):
            for n, text in f["added"]:
                for pat in DATA_SAFETY:
                    if pat in text:
                        hit = (p, n, "data-safety: added " + pat)
                        (reports if is_test(p) or pat != "ProcessInfo" else stops).append(hit)
        if kind == "code" and re.search(r"(?i)migrat|schema|catalog", p) and (f["removed"] or f["status"] == "D"):
            reports.append((p, 0, "migrations: lines removed or file deleted; confirm additive only"))
        if kind in ("docs", "scripts"):
            pin_old = [l for l in f["removed"] if PIN_RE.search(l)]
            pin_new = [l for l in f["added"] if PIN_RE.search(l[1])]
            for _, text in pin_new:
                if text.strip() == ALLOWED_ONLY_SHA:
                    continue
                if pin_old:
                    stops.append((p, 0, "pin: PIN or only-SHA line changed; must be byte-identical"))
                    break
            else:
                pass
        if p.endswith(".py") and p.startswith("scripts/") and p != "scripts/ops/premerge_check.py":  # its own rule text names the banned calls
            if f["status"] == "D":
                continue
            for n, text in f["added"]:
                m = PY_FORBIDDEN.search(text)
                if m and not text.lstrip().startswith(("#", '"', "'")):
                    stops.append((p, n, "scripts: forbidden " + (m.group(1) or m.group(2))))
                if "urllib" in text and not text.lstrip().startswith("#"):
                    reports.append((p, n, "scripts: urllib (Claude callers only: api.anthropic.com, no redirects)"))
                im = PY_IMPORT.match(text)
                if im and im.group(1).split(".")[0] in {"requests", "subprocess", "socket", "pickle"}:
                    stops.append((p, n, "scripts: forbidden import " + im.group(1)))
    return stops, reports


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kind", default="auto", choices=["auto", "docs", "code", "scripts"])
    args = ap.parse_args()
    files = parse(sys.stdin.read())
    if not files:
        print("STOP: empty diff on stdin")
        return 1
    kind = kind_of(files) if args.kind == "auto" else args.kind
    stops, reports = check(files, kind)
    print("kind=%s files=%d" % (kind, len(files)))
    for p, n, why in reports:
        print("REPORT %s:%d %s" % (p, n, why))
    for p, n, why in stops:
        print("STOP %s:%d %s" % (p, n, why))
    print("RESULT " + ("STOP" if stops else "CLEAN"))
    return 1 if stops else 0


if __name__ == "__main__":
    sys.exit(main())
