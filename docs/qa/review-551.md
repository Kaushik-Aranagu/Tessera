# QA review: #551 0ad PN-MENTION (Core)

Head reviewed: 5c22981 (merge-tree on master clean). Static review. **PASS**

- `NoteList` mention lookup now skips any object with `isPrivate == true` (Notes.swift:42-46), so "@Private note"
  links nothing. This closes M1 from review-508. The test checks there is no "about" link and that `mentions` is empty.
- Low **R1**: a link made before this PR to a private note stays in place. One-time cleanup is Core's call, and
  nothing new can be made.
- Low **R2**: the load-sensitive Day-log timing failure isn't #551's (this diff touches only Notes.swift and one
  test). The wall-clock budgets live in ScaleTests (`ContinuousClock.measure`, ScaleTests.swift:30-168; inferred
  that this is the one). They belong on Core's board as a flaky test to make robust, either behind `--scale`, or
  measuring work rather than wall time, or with a bound that holds under a parallel run. Never skip it.
