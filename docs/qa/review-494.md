# Review: #494 core/tess-riders (QA T1, P1)

QA, Oct 16 2026, ~1:05 PM PT. Head **c0b8dcb**, one commit, merges cleanly onto master. Static review.

## Verdict: PASS

### T1: a model time with no zone is read in his zone
- `[String: Any].date(_:in:)` (TessTools.swift:357-363) tries strict `.iso8601` first, so a `Z` or an offset reads as written. A time with no zone falls back to `ISO8601FormatStyle(timeZone: calendar.timeZone)`; before this change the fallback read it as GMT.
- The calendar is threaded through `TessTools.run(..., calendar:)` from both callers:
  - Claude: `ClaudeTessModel.swift:89`, `request.context.calendar`.
  - On-device: `CatalogTool` `TessModelCapture.swift:25, 153`, `context.calendar`.
- Both date tools use it: `createTask` (:120) and `rescheduleTask` (:142).
- Test `aTimeWithNoZoneIsReadInHisZone`: "2026-10-21T15:00:00" in America/Los_Angeles is 3 pm local. "…15:00:00Z" is 1_792_594_800, which I checked is 2026-10-21 15:00 UTC.
- The context line still carries no offset (the second half of my T1 suggestion). That's fine now: what the model reads and what it writes are both local.

### P1: undoing an empty wrap-up brings the process back
- New `DiscardEmptyWorkout` (ProcessActions.swift:194-226) runs `EndProcess(.wrappedUp)` and then `DeleteObject` in one transaction, so one op record holds both changes. `ProcessTable.swift:139` now performs that one action, and the Note's UNDO holds that record.
- `DayBoundaryTests`: after the wrap-up, `process(for:)` is nil. After undo, the workout is back and its process is `.suspended`. So the orphan that caught later sets can't form any more.
- It is deliberately not in `ActionRegistry.descriptors` or the decode table. That keeps it off Tess's tools, the Claude schema and App Intents, so it stays system-only. Undo replays the record and doesn't decode by name (ActionEngine.swift:142).

## What he sees (for Design)
- **No new copy.** The note "Push A, no sets, not saved." and its 10 s UNDO are unchanged.
- **One changed receipt line.** The op record's summary is now "Push A, no sets, not saved" (`DiscardEmptyWorkout.summary`). Before, there were two records: the process end and the delete. Anywhere that lists op summaries (Day log, Receipts, history) shows that one line in their place.
- **Behavior.** After UNDO, the workout comes back suspended, so it shows with Resume wherever a suspended workout shows. Tasks Tess or Claude create from a time with no zone now land at the hour he said, instead of 7 hours early in PDT.

## Lows (not pin blockers)
- **R1:** The second half of the P1 fix isn't in. `LogExercise.activeWorkout` (TrainingActions.swift) still picks a workout that has no open process. An orphan from a build before this one (one he made with UNDO on 7b321d2) would still catch sets. Rare, but one guard would close it.
- **R2:** `DiscardEmptyWorkout` is marked `isDestructive: true` but nothing reads that for system actions. Harmless.
