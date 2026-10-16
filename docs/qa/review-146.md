# Review #146 (merged 5b0262e, head b483655) — PASS

Static review only. Rides the fuller build.

## Master consistency
The branch was cut from 0950ba7, before #147. `git diff ed6298e origin/master -- '*.swift' project.yml` is exactly
#146's own five files, and ed6298e is an ancestor of master, so nothing from #147 was dropped. Master tip is now cb2f6c0
(#149, docs only).

## Remove set mid-rest (WorkoutSession+Edit.swift:55)
- Removing the set that owns the running rest (undoable or lastSeated) clears restEndsAt and restNote, then
  refreshAfterExternalWrite (bumps loggedCount, so the Live Activity updates) and persistRest. Matches undoLast. OK.
- Removing an older set leaves the rest running, which is correct.
- The test covers both the in-memory and the reloaded session. Good.

## Soul corner (LiveTessCorner)
- W4 closed: `holdsLine` keeps "Hold to finish" on the finish screen; other lines still fade after 4 s.
- W5 closed: `.id(shownLine)` is gone; a new line cross-fades with `.contentTransition(.opacity)`.
- W6 closed: hit testing is off when both callbacks are nil, and the hint, button trait and Go to Today action are
  dropped.

## Lows
- W7 (low, Design call) LiveTessCorner.swift:73: with `TapGesture(count: 2).exclusively(before: TapGesture())`, a single
  tap's swell now waits out the double-tap window (about 0.3 s). The old DragGesture swelled on touch-down, so a single
  tap now feels slower. Fix if Design minds: bring back a touch-down swell through `simultaneousGesture` while keeping
  the exclusive taps for the actions.
- W8 (low) WorkoutSession.swift:30,40: restEndsAt and restNote lost `private(set)`. A small `endRest()` on the session
  would keep the setters private. Tidy-up only.
