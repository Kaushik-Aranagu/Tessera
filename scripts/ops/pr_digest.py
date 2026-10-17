#!/usr/bin/env python3
"""One-table digest of open PRs. Stdlib only; reads files, nothing else.

Usage: python3 scripts/ops/pr_digest.py prs.json [verdicts.txt]

prs.json: list of {number,title,head_sha,mergeable_state,labels, files?}
  files (optional): list of paths (strings) or of {filename} objects, used for KIND.
verdicts.txt: saved output of scripts/ops/verdicts.py (lines like "  #305  PASS  8fa70a6  qa.md").
A verdict is "stale" when its sha is missing or differs from the PR head sha7.
KIND: docs = every file under docs/ or *.md; scripts = every file under scripts/ or
docs/ too (no app code); code = anything else; ? = no files list.
"""
import json
import re
import sys

LINE = re.compile(r"^\s*#(\d+)\s+(PASS|FIX FIRST)\s+(\S+)")


def kind(files):
    if not files:
        return "?"
    paths = [f if isinstance(f, str) else f.get("filename", "") for f in files]
    if all(p.startswith("docs/") or p.endswith(".md") for p in paths):
        return "docs"
    if all(p.startswith(("docs/", "scripts/")) or p.endswith(".md") for p in paths):
        return "scripts"
    return "code"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    with open(sys.argv[1], encoding="utf-8") as f:
        prs = json.load(f)
    verdicts = {}
    if len(sys.argv) > 2:
        with open(sys.argv[2], encoding="utf-8") as f:
            for line in f:
                m = LINE.match(line)
                if m:
                    verdicts[int(m.group(1))] = (m.group(2), m.group(3))
    rows = [("PR", "HEAD", "QA VERDICT", "MERGEABLE", "KIND")]
    for pr in sorted(prs, key=lambda p: p["number"]):
        head = (pr.get("head_sha") or "")[:7] or "-"
        v = verdicts.get(pr["number"])
        if not v:
            q = "none"
        elif v[1] == "-":
            q = f"{v[0]} (no sha: stale)"
        elif head.startswith(v[1][:7]):
            q = f"{v[0]} @ {v[1][:7]}"
        else:
            q = f"{v[0]} @ {v[1][:7]} (stale)"
        rows.append((f"#{pr['number']}", head, q, pr.get("mergeable_state") or "?", kind(pr.get("files"))))
    w = [max(len(r[i]) for r in rows) for i in range(5)]
    for r in rows:
        print("  ".join(c.ljust(w[i]) for i, c in enumerate(r)).rstrip())


if __name__ == "__main__":
    main()
