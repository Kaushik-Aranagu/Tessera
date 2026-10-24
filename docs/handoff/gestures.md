# Gestures handoff (Oct 24, 7:57 AM PT)

For whoever picks up the gesture work next. Kaushik asked for stable, consistent, easier touches app-wide: fewer
accidental touches and swipes. Nothing below was compiled or run in the cloud container (no Swift toolchain); every
claim of "works" is from reading code and hand-checking arithmetic.

## State of the PRs

| PR | Branch | Head | What it is |
|----|--------|------|------------|
| #1389 | `claude/project-thread-c4gbv9` | merged as 2627119 | The policy: `GestureTuning`, `GestureKit` modifiers, about 30 sites moved, `gesture-policy.md`, `GestureStabilityUITests` |
| #1390 | `claude/project-thread-c4gbv9` | 3247958c | QA follow-ups: Tasks Done swipe UI test, name-pull axis check, `allowsFlick: false` for the ghost-row drop (no Undo), `SwipeToRemove` no flash-back, distance-change table |
| #1391 | `claude/project-thread-c4gbv9-home-regions` | 546aca8c | Home: removes the page-level drag that made the mosaic a hidden control for the one-thing list; adds `homeOneThing` identifier and value; mosaic swipe UI test |
| #1393 | `claude/project-thread-c4gbv9-element-swipe` | 03a5332d | A single swiped element turns on either axis (`GestureTuning.elementTurn`, `SwipeAxes`); one-thing tap and hold UI tests; doc sections. Stacked on #1391 |

Merge order: #1391 first, then #1393 (retarget its base to master; GitHub does it when #1391's branch is deleted).
#1390 is independent of both but shares `GestureStabilityUITests.swift` and `gesture-policy.md` with them, so expect a
trivial append conflict in whichever merges second. QA passed #1390, #1391 and #1393 on reading. Only the coordinator
merges.

Known wrong text in #1393's description: it mentions `.elementSwipe(axes:arm:onTurn:)` in `GestureKit.swift`. That
modifier was never added; Home's one thing calls `GestureTuning.elementTurn` directly. The doc was corrected, the PR
body was not.

## The policy (full text in `docs/design/gesture-policy.md`)

- A drag starts at 10 pt (`dragStart`). A tap tolerates 10 pt of slop. Axis lock at 12 pt, horizontal wins at 1.5x,
  pagers at 2.0x. A single element needs the dominant axis to lead 1.3x, so a diagonal turns nothing.
- A row swipe arms at 96 pt (72 pt to undraw, 8 pt hysteresis), commits on release, or on a flick (500 pt/s and 28 pt
  travel). Taking the swipe back at lift cancels it (350 pt/s reverse). Rows with no real Undo pass
  `allowsFlick: false`.
- The system back edge (0 to 24 pt) is never taken by a row or pager. Action words start at least 28 pt from the left.
- After a wheel or rail lets go, taps are ignored for 120 ms (`TapHoldoff`).
- Undo lasts 10 s everywhere. Swipe right is Done, left is Not now.
- Each region owns its own touches. A parent gesture never decides for a child's region (the #1391 bug).
- A single swiped element takes both axes (left or up next, right or down previous) unless the axes mean different
  things. Dials, wheels and rails are excluded. Inside a scroll view it uses a high-priority gesture; taps and holds
  inside it use simultaneous gestures.
- Animate only through `MotionPolicy`. No lens or glass on swipers (Kaushik).
- Code: `TesseraCore/Sources/TesseraCore/Gesture/GestureTuning.swift` (pure, tested), `DesignSystem/GestureKit.swift`
  (`rowSwipe`, `pageSwipe`, `pullGesture`). Tests: `GestureTuningTests.swift`, `TesseraUITests/GestureStabilityUITests.swift`
  (QA rule G13: a plain tap reaches its button in every list that has a hold or drag).
- CI's premerge check rejects `ProcessInfo`, `UserDefaults`, `LaunchFlags`, `#if DEBUG` and similar in app code. The
  rail hold-off therefore uses `CACurrentMediaTime()`.

## Still unverified (nothing was run)

1. **Compile.** Core needs `swift test` in `TesseraCore/`, then `scripts/test.sh`. Hand-checked tests: the whole
   `GestureTuningTests.swift` including `aRowWithNoUndoNeverCommitsOnAFlick` and the three element-turn tests.
2. **UI tests, all unrun.** Wiggle, plain tap and diagonal drag across six rooms; Tasks Done swipe (#1390; it reaches
   Tasks through the apps list, so it needs Builder B's apps-list tap fix #1392, and it lacks the permission-ask
   helper that `launchApp` gives #1391); the mosaic swipe (#1391); one-thing tap opens and 0.9 s hold on a task shows
   Undo (#1393). The hold test relaunches and walks up to 7 things looking for a task, so it is the most likely to be
   flaky.
3. **On a device.** The thing most worth a thumb: a vertical swipe on Home's one thing. It already turned on four
   directions before this work (sheet 220), so if it fails on the phone the cause is likely a competing drag (page
   scroll or the apps list), not the gesture. Also check that a vertical drag that starts on the one thing no longer
   scrolls the page (accepted cost).
4. **Distances Design may want to tune** in `GestureTuning` (table in the policy doc): 96 pt arms, Measure step 28 pt,
   EffortHandle 56 pt, StepStack 10 pt start. These were set by the policy and stand until Kaushik says otherwise.
5. **Left alone on purpose:** `AppsListSlot.swift` (Builder B's hot-fix; move its wheel onto `GestureTuning` once that
   lands), `RowPressDrag` in HomeQueue, the instruments (weight reel, reps, RPE), the doorway DIY back swipes.

## Not mine, but asked in the same breath

Kaushik also wants a Home layout pass (cramped at the top, too much space at the bottom, one-thing type and content,
the sign and mosaic) and the weather words to animate more visibly (sunny: light reflecting; cloudy: a little clouded;
windy: the words drift). That is design work for the Design lead and Builder B; I did not start it.

## Next steps, in order

1. Core compiles and runs #1391, then #1393, then #1390. QA re-reads any fix.
2. Merge #1391, retarget #1393, merge, then #1390.
3. Thumb test on the phone (item 3 above). Then the apps-list wheel onto `GestureTuning`.
