# QA: Tess model layer T2, PR #106 (head 2c52c7b)

*Repo maintainer (QA), 2026-10-15 20:02 UTC. Static read.* **Merge after the install, with T2-1 fixed.**

- **T2-1 (should-fix): failed tool calls leave orphaned pending ops.**
  - `TessTools.createList` always calls `addItems`, which throws "no items to add" on an empty array. The common call ("new list packing", `items: []`) therefore performs `CreateList` as a pending op and then throws. Its record never reaches `TessToolRecorder`, so it is never committed or discarded (the same orphan B4 fixed for sets).
  - `TessTools.run` doesn't roll back records already performed when a later step throws. This affects createList with items, and addToList with done items.
  - Fix: allow empty items in createList. In `run`, discard (if pending) or undo the records performed so far when the tool throws. Add a test for createList with no items.
- T2-2 (note): compared with #84's allow-list, the on-device model no longer gets logBodyWeight, startShop, createRoutine or createPlan. Those phrases now depend on the grammar alone.
- Fine:
  - Name resolution throughout.
  - No destructive or clock-driven tools.
  - Strict schemas (closed objects, nullable optionals).
  - answerQuery is read-only through `TessToolAnswer`.
  - T1's route stamping still applies.
