#!/usr/bin/env python3
"""Docs index check. Stdlib only; reads files under docs/, nothing else.

Usage: python3 -B -I scripts/ops/docs_index_check.py [repo_root]

1. MISSING-INDEX path: a docs/**/*.md (not under docs/recordings or docs/screenshots)
   that is neither linked nor named (by relative path or bare file name) in docs/README.md
   or in any docs/*/README.md.
2. BROKEN-LINK file:line target: a relative markdown link in docs/ whose file does not exist.
Prints only paths, line numbers and link targets. Exit 1 if any BROKEN-LINK, else 0.
"""
import re
import sys
from pathlib import Path
from urllib.parse import unquote

SKIP = ("docs/recordings/", "docs/screenshots/")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    docs = root / "docs"
    files = sorted(p for p in docs.rglob("*.md") if not p.relative_to(root).as_posix().startswith(SKIP))
    indexes = [docs / "README.md"] + sorted(docs.glob("*/README.md"))
    text = ""
    for ix in indexes:
        if ix.is_file():
            text += "\n" + ix.read_text(encoding="utf-8", errors="replace")
    missing = [p for p in files if p.name != "README.md" and p.relative_to(docs).as_posix() not in text and p.name not in text]
    broken = []
    for p in files:
        rel = p.relative_to(root).as_posix()
        in_fence = False
        for n, line in enumerate(p.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if line.lstrip().startswith("```"):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for m in LINK_RE.finditer(line):
                t = m.group(1)
                if re.match(r"^([a-z][a-z0-9+.-]*:|#|/)", t, re.I):
                    continue
                path = unquote(t.split("#")[0].split("?")[0])
                if path and not (p.parent / path).exists():
                    broken.append(f"BROKEN-LINK {rel}:{n} {t}")
    for p in missing:
        print("MISSING-INDEX", p.relative_to(root).as_posix())
    for b in broken:
        print(b)
    print(f"summary: {len(files)} docs, {len(missing)} MISSING-INDEX, {len(broken)} BROKEN-LINK")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
