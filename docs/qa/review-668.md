# Review #668 (Core: per-call ghost budget)

Head 9f87bd29, merge-tree clean against master d9a2601e. Package-only, no screen change. Design not needed.

**Verdict: QA PASS.**

- `TessTools.run(budget:)` throws the cap line at budget 0, cuts the `lines` and `items` arrays to the budget before the tool runs, and takes back any record past the budget after (pending are discarded, others undone). Those two keys are the only record-writing arrays in the tool set (`about` links objects and writes no records), so nothing else needs the cut.
- Both callers pass the remaining budget: the Claude path `max - records.count` (the loop guard keeps it at 1 or more) and the on-device path `max - recorder.records.count`. The Claude path's own `trim` stays as a backstop; the double check is harmless.
- `createList` with items counts the list record itself in the budget, so a full list loses its last item rather than going over. Fine.
- The new test runs one 15-line call, checks count and pending ghosts match, then budget 2 and budget 0 (throws).
- Low: the test covers `lines` only; an `items` case (addToList) would complete it.
