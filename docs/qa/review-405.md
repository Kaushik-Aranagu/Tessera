# QA review: #405 Core DemoData clamp (03:00 to 04:00 failures)

Head `0316672` on master 0fc38b7. Trial merge is clean. One file changes: Features/Demo/DemoData.swift. This is a static review.

## Verdict: PASS

- `seedToday` now schedules today's demo workout at `min(anchor + 50 min, end of day − 5 min)` (DemoData.swift:201-205). `TesseraDay().end(of:)` is 04:00 on the next calendar day (TesseraDay.swift:40-43), so from 03:10 to 04:00 the workout stays on his day, and `tonightWorkout()` finds it.
- **It can't run on the phone.** Both callers go through `DemoData.prepare`: TesseraApp.swift:30, and the RootView preview at :100. `prepare` returns at once unless `allowed && LaunchFlags.allowed` (DemoData.swift:18). `LaunchFlags.allowed` is false outside `targetEnvironment(simulator)`, whatever the build configuration. A caller can narrow it but never widen it, and `seedToday` is private. There are no raw ProcessInfo reads beyond the default argument that `prepare` already had.
- Nothing is written outside the demo store. There's no schema or catalog change.

## Low
- L1: from 03:55 to 04:00 the clamp lands at 03:55, a few minutes in the past, so Home may read it as just started rather than coming up. The demo only.
