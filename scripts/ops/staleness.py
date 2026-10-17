#!/usr/bin/env python3
"""Board and memory staleness check. Stdlib only; reads stdin and files, nothing else.

Usage: git log --oneline | python3 scripts/ops/staleness.py [file.md ...]

1. Board: lines in docs/ops/board/*.md that sit under **Now:**, **Next:** or **Later:**
   (an open item) and name #n, where git log shows PR n merged ("Merge pull request #n"
   or a squash subject ending "(#n)"). Another bold-led line (e.g. **Done:**) closes the section.
2. Size: every .md path given as an argument over 3000 bytes (memory files).
Exit code 1 when anything is flagged, 0 when clean.
"""
import re
import sys
from pathlib import Path

LIMIT = 3000
MERGED_RE = re.compile(r"Merge pull request #(\d+)\b|\(#(\d+)\)\s*$")
OPEN_RE = re.compile(r"^\W*\*\*(Now|Next|Later)\b", re.I)
HEAD_RE = re.compile(r"^\W*\*\*\w")


def merged_prs(text):
    out = set()
    for line in text.splitlines():
        m = MERGED_RE.search(line)
        if m:
            out.add(int(m.group(1) or m.group(2)))
    return out


def stale_lines(path, merged):
    flagged = []
    is_open = False
    for i, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if OPEN_RE.match(line):
            is_open = True
        elif HEAD_RE.match(line) or line.startswith("#"):
            is_open = False
        if is_open:
            if "(merged #" in line:  # already marked by its board owner
                continue
            hit = sorted({int(n) for n in re.findall(r"#(\d+)\b", line)} & merged)
            if hit:
                flagged.append((i, hit, line.strip()[:90]))
    return flagged


def main():
    root = Path(__file__).resolve().parents[2]
    merged = merged_prs(sys.stdin.read()) if not sys.stdin.isatty() else set()
    problems = 0
    if not merged:
        print("note: no merged PRs read from stdin (pipe `git log --oneline`); board check skipped")
    else:
        for p in sorted((root / "docs/ops/board").glob("*.md")):
            for i, hit, snip in stale_lines(p, merged):
                problems += 1
                print(f"STALE {p.relative_to(root)}:{i}: open item names merged "
                      + ", ".join(f"#{n}" for n in hit) + f" | {snip}")
    for arg in sys.argv[1:]:
        p = Path(arg)
        if p.suffix != ".md" or not p.is_file():
            print(f"skip {arg}: not an .md file")
            continue
        size = p.stat().st_size
        if size > LIMIT:
            problems += 1
            print(f"BIG {arg}: {size} bytes (limit {LIMIT})")
    print(f"{problems} flagged.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
