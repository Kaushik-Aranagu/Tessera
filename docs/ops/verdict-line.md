# Verdict line

One line per verdict, in the QA board entry and at the top of each `docs/qa/review-N.md` addendum:

```
PR #n PASS|FIX FIRST at <sha7>: <findings or none>
```

- `PASS` or `FIX FIRST` in capitals; those are the only two words the script reads.
- `<sha7>` is the first 7 characters of the PR head you read. A re-check gets a new line with the new head; the newest line wins.
- Findings are short rows by id (`F1`, `S2`, `L3`), the same ids the review file uses. Write `none` when there are none.
- Design uses the same line with `Design` ahead of the verdict only when QA and Design differ: `PR #n Design FIX FIRST at <sha7>: ...`.

`python3 scripts/ops/verdicts.py` lists the latest verdict per PR from `docs/ops/board/qa.md` and `docs/qa`.

## Examples (from real board entries)

```
PR #305 PASS at 252708c: S1 closed, phrase kept on any .asked
PR #342 FIX FIRST at fc42d69: F1 cancelled touch freezes Home, F2 hold with no slide changes page
PR #547 PASS at 34359e1: none
```
