# QA review: #634 Core, keepPlannedTask off the model tool list, no "at" in the move receipt

Head 055d96b. Static, low risk. Merge-tree clean. Closes my #605 low and part of the no-"at" audit.

- `ActionDescriptor.isOfferedToModel` (default true); KeepPlannedTask sets false. `ActionRegistry.offered` filters; `catalog` and `toolDefinitionsJSON` use it; `descriptors` still holds it so decoding and the op log work. Test: not in catalog or tool names, still decodes, moveTask still offered.
- MoveTask.receipt drops "at": "Call mom, tomorrow 6:30 pm" and "Call mom, Oct 29 6:30 pm"; ReceiptTests updated. Matches Product 5:11 PM and 6:36 PM.
- Remaining no-"at" hits are in qa/audit-no-at-copy-oct17.md (Home/Now/Live Activity); Tasks.swift:213 (DayStoryClock sentence) is the one this PR fixes.

Verdict: PASS at 055d96b.
