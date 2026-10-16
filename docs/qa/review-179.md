# Review #179 (merged cc9cb3b) — Today queue polish: PASS (not in tonight's install)

Static review only, against review-151 (Q1/Q2, S1-S3).

## Q1/Q2 and S1 still hold
#179 doesn't touch RowPressDrag, the pager-idle gate, `grab`/`rowGrabbed`, or the `.onDisappear` S1 fix. The
gesture path is unchanged.

## Changes
- The time is now its own column, trailing in the row's ZStack (alignment .trailing). It stays still while the
  title travels and fades over the first 40 pt of a drag. The accessibility label still includes the time. OK.
- finish() no longer snaps `drag` to 0, so the title stays where the finger left it (capped at 20 pt) while the
  strike completes. The row leaves 600 ms later. OK.
- Rail titles: `.lineLimit(1).fixedSize()`. OK.
- HomeSpatialView ignores the pager's first offsets until it reaches the remembered page, so the rail doesn't
  flash PAST/REVIEW on launch. OK.

## Lows
- P1 HomeSpatialView.swift:107: `settled` only flips when an offset lands within 0.01 of `remembered`. If the
  restored ScrollPosition ever doesn't apply (the pager opens on another page), the rail's progress stays frozen
  until the user happens to swipe onto the remembered page. Fix: also set `settled = true` on
  `onScrollPhaseChange` leaving `.idle` (a real user swipe).
- P2 HomeQueue.swift:321: the title's 64 pt trailing room is fixed, while the time is Label 16/700 and scales with
  Dynamic Type. At large sizes, or with a long clock string, the title runs under the time. Fix: `@ScaledMetric`
  for the 64, or reserve the width with a hidden copy of the time text.
- P3: if the finish op fails (`try?`), the row stays struck and offset, now without the drag reset. This predates
  #179 and is hard to hit.
