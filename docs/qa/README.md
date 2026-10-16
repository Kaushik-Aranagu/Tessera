# QA reviews

One static review per merged PR (no Swift toolchain on the QA side, so every review is read and hand-traced, not run). Each opens with the verdict; findings carry an ID (for example K11, Q9, R3) that later reviews close.

- `review-N.md`: the review of PR #N (`review-N-M.md` covers two PRs).
- `review-master-*.md`: a range of master commits read together.
- `regression.md`, `grammar-trace.md`, `*-flow.md`: standing checklists and traces.

From #251 on, reviews land here in the repo as well as in the project's shared folder, so the Mac sessions can read them.
