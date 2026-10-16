# Review #151 (merged 927608d) — Home swipe hotfix: Q1/Q2 CLOSED, GO for the build

Static review only. Checked against Q1/Q2 in review-116.md.

## Q1 (page swipe could finish or move a task): closed
- QueueRow's DragGesture is gone. The new RowPressDrag (HomeQueue.swift) is a UILongPressGestureRecognizer:
  0.2 s, allowableMovement 8, cancelsTouchesInView false. A moving finger fails it before it begins, so a flick
  always belongs to Home's paging ScrollView.
- It is disabled while the pager isn't idle (`onScrollPhaseChange` → `homePagerIdle`). Once a press lands, the
  row reports `homeRowGrab(true)`, and both the Home pager and the queue window go `scrollDisabled`, so the drag
  belongs to the row alone.
- Finishing needs 140 pt of deliberate travel (was 40% of 250). Moving still needs 120 pt.
- The real-touch XCUITest covers both a flick (pages, no UNDO, the task stays) and a press-then-drag (finishes).
  It is in the new TesseraUITests scheme, which scripts/test.sh does not run, so it needs one manual run on the Mac.

## Q2 (state only reset in onEnded): closed
`.cancelled` and `.failed` → `holding = false` → onChange → `settle()` resets drag, strike and armed. commit()
clears holding on every path.

## Should-fix (small, not blocking)
- S1 HomeQueue.swift QueueRow: if a row leaves the view tree while it is held (the queue refreshes, a ranker
  re-pick, a minute tick that drops it), onChange never fires `grab(false)`. `rowGrabbed` would then stay true and
  leave Home's pager and the queue scroll-disabled until relaunch. The trigger is rare, but the failure is a dead
  Home. Fix: `.onDisappear { if holding { grab(false) } }` on the row.

## Lows
- S2: resting a finger on a row for 0.2 s before scrolling the queue vertically grabs the row (the scroll is
  disabled, and only x is tracked), so that scroll does nothing. It then settles harmlessly. The fix is to fail
  the drag when |dy| > |dx| after `.began`.
- S3: a 0.2 to 0.5 s press with no drag also triggers `.onTapGesture` (it opens the row). That matches UIKit
  feel, but worth noting for Design.
