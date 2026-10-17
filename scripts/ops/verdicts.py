#!/usr/bin/env python3
"""Latest QA verdict per PR, as a table. Stdlib only; reads files, nothing else.

Usage: python3 scripts/ops/verdicts.py [repo_root]

Sources:
  docs/ops/board/qa.md  running log; later text = newer, so the last match per PR wins.
  docs/qa/*.md          one review per file; the last verdict in a file wins.
When a PR appears in both, the board entry wins (it is the running log).
Only the two words PASS and FIX FIRST count; other verdicts (GO, NO-GO, lowercase
"pass") are listed as unparsed so a person can decide.
"""
import re
import sys
from pathlib import Path

SHA = r"(?=[0-9a-f]*\d)[0-9a-f]{7,40}"
SHA_RE = re.compile(r"\b(" + SHA + r")\b")
# "#305 FIX FIRST: ...", "#312 at 8fa70a6 PASS", "#547 receipts PASS 34359e1"
BOARD_RE = re.compile(r"#(\d{1,5})\b([^#;.]{0,90}?)\b(PASS|FIX FIRST)\b")
VERDICT_RE = re.compile(r"\b(PASS|FIX FIRST)\b")


def sha_near(before, after):
    m = SHA_RE.search(before) or SHA_RE.search(after[:40])
    return m.group(1)[:7] if m else "-"


def scan_board(path):
    text = path.read_text(encoding="utf-8", errors="replace")
    found = []
    for m in BOARD_RE.finditer(text):
        after = text[m.end():m.end() + 40]
        after = re.split(r"[;#]|\. ", after)[0]
        found.append((int(m.group(1)), m.group(3), sha_near(m.group(2), after), path.name))
    return found


def scan_review(path, unparsed):
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    title = lines[0] if lines else ""
    nums = re.findall(r"#(\d{1,5})\b", title) or re.findall(r"(?<![\d])(\d{2,5})(?![\d])", path.stem)
    head = "-"
    found = []
    saw_verdict_word = False
    for line in lines:
        hm = re.search(r"\bhead[ :]+`?(" + SHA + r")", line) or re.search(r"\bat `(" + SHA + r")`", line)
        if hm:
            head = hm.group(1)[:7]
        if not re.search(r"verdict|addendum|re-?check|re-?read|re-?review", line, re.I):
            continue
        saw_verdict_word = True
        vm = VERDICT_RE.search(line)
        if not vm:
            continue
        sm = SHA_RE.search(line)
        sha = sm.group(1)[:7] if sm else head
        in_line = re.findall(r"#(\d{1,5})\b", line)
        targets = in_line if len(nums) > 1 and in_line else nums
        if len(targets) != 1 and not (len(nums) > 1 and in_line):
            targets = nums if len(nums) == 1 else []
        for n in targets:
            found.append((int(n), vm.group(1), sha, path.name))
    if not found:
        why = "no PASS/FIX FIRST verdict line" if saw_verdict_word else "no verdict line"
        if len(nums) > 1:
            why += " naming one PR (multi-PR file)"
        unparsed.append((path.name, why))
    return found


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[2]
    unparsed = []
    latest = {}
    for pr, v, sha, src in (e for p in sorted((root / "docs/qa").glob("*.md"))
                            if p.name != "README.md" for e in scan_review(p, unparsed)):
        latest[pr] = (v, sha, src)
    board = root / "docs/ops/board/qa.md"
    if board.exists():
        for pr, v, sha, src in scan_board(board):
            latest[pr] = (v, sha, src)
    else:
        unparsed.append(("docs/ops/board/qa.md", "missing"))
    print(f"{'PR':>6}  {'VERDICT':<9} {'SHA':<8} SOURCE")
    for pr in sorted(latest):
        v, sha, src = latest[pr]
        print(f"{'#' + str(pr):>6}  {v:<9} {sha:<8} {src}")
    print(f"\n{len(latest)} PRs found; {sum(1 for x in latest.values() if x[1] == '-')} without a sha.")
    for name, why in unparsed:
        print(f"could not parse: {name} ({why})")


if __name__ == "__main__":
    main()
