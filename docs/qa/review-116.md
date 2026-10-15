# QA: Today on Home queue swipes, PR #116 (master 0f183ae)

*Repo maintainer (QA), 2026-10-15 22:10 UTC. Static read of Features/Home/HomeQueue.swift (QueueRow.swipe).* **NO-GO for the phone until Q1 is fixed. Install 34665f0 instead, or hotfix first.**

## Q1 (blocker, touches real data): a Home page swipe that starts on a row can finish or move that task
- The row uses `.gesture(DragGesture(minimumDistance: 12, coordinateSpace: .global))` inside HomeSpatialView's horizontal `.paging` ScrollView. There is no coordination with the pager.
- The only guards are `startLocation.x > 24` and horizontal dominance (`|dx| > 1.4·|dy|`). A page swipe passes both: it is horizontal, and it starts anywhere, not only at the edges. The comment "Edge swipes page Home" is a wrong assumption, because the paging ScrollView pages on any horizontal drag.
- Thresholds are low compared with a page swipe:
  - Finish fires at 100 pt right (`strikeSpan 250 × doneThreshold 0.4`).
  - Move fires at 120 pt left.
  - A normal page flick covers both.
  - A right drag only shifts the row by `drag * 0.04`, so he wouldn't even see it arming while the page moves.
- What happens depends on how SwiftUI arbitrates the row's DragGesture against the ScrollView's pan, which is untested by hand:
  - If both run (the usual iOS 18+ behavior for a child DragGesture in a ScrollView), swiping right from TODAY to REVIEW over a row pages **and** commits `SetTaskDone(by: .user)` 600 ms later. Swiping left to TRAINING over a row moves the task to tomorrow or next week.
  - If the row wins, Home can't be paged from the queue area at all. Every page attempt there becomes a finish or a move.
- Either way, it's a committed write on his real tasks. The only way back is the Undo line, which fades.

Fix (smallest safe first):
1. Gate on the pager. Have HomeSpatialView publish `onScrollPhaseChange` into the environment (for example `homeIsPaging`). In the row, skip `onChanged` and make `onEnded` a no-op whenever the phase isn't `.idle`, or whenever the page offset moved during the drag.
2. Arm deliberately. Use `LongPressGesture(minimumDuration: 0.2).sequenced(before: DragGesture(...))` so that a quick flick always pages and a press-then-slide finishes. Alternatively, require `predictedEndTranslation` and the translation to agree, and raise finish to at least 140 pt.
3. Test it on the phone or the simulator with a real drag, not the `-queueScript` (which sets state directly and bypasses the gesture).

## Q2 (should-fix): a cancelled drag leaves the row half-struck
`drag`, `strike` and `armed` are `@State` and only reset in `onEnded`. When the system cancels the gesture (the scroll view takes over, an incoming call, the app goes to the background), `onEnded` doesn't run. The row stays offset and partly struck, with `armed` true. Use `@GestureState` for the live drag, or reset on `onChange(of: isActive)`.

## Low
- Q3: `move()` uses `Calendar.current` and `AppClock.now` for "next week" at 09:00 local. For a dated row it passes `nil`, which presumably means "tomorrow, same time" inside MoveTask. Check that the meaning of `nil` is documented.
- `brighten()` now honors Reduce Motion (closes the #113 low).
