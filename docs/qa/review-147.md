# Review #147 (master 70dbddd, head ed6298e) — PASS

Static review only (no Swift toolchain here). Rides the fuller build.

## Ranker follow-ups (from review-141)
- N1 closed: `area(of:)` checks task, note, groceries, kitchen, then training words; setTaskDone no longer reads as training.
- N2 closed: `pick(at:next:plan:sessionsPerWeek:incumbent:calendar:)` fills `lastAction` and `daysAway`.
- N4 closed: `fits(_:_:)` takes the passed calendar.
- N5 closed: `hasWorkoutUnderway` scans process records (workout subject, no endedAt, started today).
- N3 open on purpose (R39).
- Note for the Home hookup (E5, Builder B): the incumbent hold only works if Home passes the current Now as `incumbent`.

## Info.plist question
No commit needed. The only project.yml change is `INFOPLIST_KEY_NSHealthShareUsageDescription`, a build setting
Xcode merges at build time. xcodegen writes App/Info.plist only from `info: properties`, which did not change.

## Other changes
- CheckListItem `time:` (Groceries passes AppClock.now, so -demoTime stays consistent). OK.
- ObjectPage "New subclass" goes through `store.createClass`. OK.
- Undo words use InkLabelWordStyle(live); Backups link hairline gone; NBSP in folder sentence. OK.
- Groceries: all animations now go through withTesseraAnimation (MotionPolicy rule met). Peek swaps with BlurFade.

## Lows
- G8 (low) GroceriesView.swift ShopTitle: `held` is set before `onHold()` and never reset. Normally fine because
  ShopTitle unmounts when shopping starts, so state resets. If `StartShop` throws (`try?` swallows it), shopping stays
  false and the title stays fully vermilion until the page is rebuilt. Fix: reset `held`/`fill` in `.onAppear`, or
  only set `held` when the shop actually started.
