# Review #187 (merged dc8d1d2) — Core's 04:00 day: PASS (not in tonight's install)

Static review against research/day-boundary.md and late-night.md (scenes S1-S11, the "Still wrong" table and the
open-question defaults). DST: TesseraDay reads the wall-clock hour, so the 23 h and 25 h days need no special
case, and both are pinned in TesseraDayTests.

## 1. rollForward now runs (late-night #1): no unwanted rolls found
- It's called from tidyProcesses (launch and every foreground) with AppClock.now. It is idempotent per day: once
  a task is moved, `logicalDay(startsAt) == today`, so later foregrounds do nothing, and `rolls` counts once per
  day. The precheck runs no op when nothing needs moving.
- Small hours: at 00:00-03:59 the logical day is still yesterday, so a Fri 23:00 task isn't rolled at 01:00 Sat. A
  task captured at 01:00 for "today 3pm" (Sat 15:00) is a future logical day, so nothing rolls it.
- A "2am" task made the evening before belongs to that logical day and rolls by exactly one day. That is
  consistent.
- First run on the phone: every undone dated task from earlier days moves to today at its own time (rolls = 1).
  Those were already listed as carried in Today, so Today doesn't visibly fill up. Expect one Tess line
  ("Carried N tasks into today.") on the first open after install, once #13 (Builder B) shows processNotes.
- Product note, not a bug: a past one-off event he never ticked ("coffee with ravi at 7") is a task, so it rolls
  for 7 days. That's the agreed "missed day rolls on" rule.
- D1 (low): the roll is an op by `.system` and becomes the newest entry in history. On the first foreground after
  04:00, a history-based Undo would take back the roll, not his last action. Worth checking that the Undo word
  skips `.system` ops.

## 2. Zero-set close (late-night #4, S10): matches
`ProcessTable.wrapUp` only runs for suspended workout processes idle at least 6 h. If no entry has a live set
(orderedChildren filters deleted sets), it gives `EndProcess(.wrappedUp)` plus `DeleteObject(workout)` and "Closed
Push A, nothing was logged", so no trained day is saved. A live or recently used session is never touched, and
planned workouts have no process, so they're never in `tidy`.
- D2 (low): it's two ops, so it takes two Undo steps to fully bring back the empty workout. That's acceptable for an
  empty workout.

## 3. TessGrammar dates against the regression rows: all match
- S3 at 01:00 Sat: "today 3pm" gives Sat 15:00; "tomorrow 3pm" gives logical Fri + 1, so Sat 15:00; "tonight" gives
  Sat 20:00. The reply names the weekday from 00:00 to 03:59 (fix #9), so it no longer says "tomorrow" for
  "today".
- S2/G11: 20:00-23:29 "tonight" is the next whole hour today. At 23:45 it's Sat 20:00 (open-question 2 default).
- S4 at 00:30, "remind me tomorrow at 9": Sat 09:00 (not hour-today, so 9 is AM), and the reply ends "On Now then."
  (fix #2).
- S5 bare hours are unchanged and right.
- Past logs: "yesterday" and weekday look-back now count from the logical today (at 00:40 Sat, yesterday =
  Thursday, as the doc comment says).
- The model path (C5) tells the model "it is still Friday" from 00:00 to 03:59.

## Other fixes checked
- #6: local-time backup names (`yyyy-MM-dd`, `yyyy-MM-dd'T'HHmmss`).
- #10: 00:00-03:59 ranks as `.late`.
- Ledger: workouts are filed by the day they started, and the cache is keyed by zone (open-question 7 default).
- Week, month and Review windows use 04:00 edges.

## Lows
- D3 WorkoutSummary.swift `finishedWorkouts(on:)`: `date == startOfDay(date) ? date : day(of:)` reads a moment
  exactly at 00:00:00 as a day key (calendar day), not the previous logical day. Real clocks almost never hit that
  exactly, but `-demoTime 00:00` does. A separate `on dayKey:` overload would make it explicit.
- D4: MoveTask now takes `time:`, but HomeQueue.swift:406 and ReviewView.swift:298 don't pass AppClock.now yet
  (late-night #11, not claimed by this PR). That only matters for -demoTime demos.
- D5 TessTools "this month" uses calendar month edges (midnight) while "today" and "this week" use 04:00. That's
  off by at most 4 h at a month boundary.
- Still open from late-night (not in this PR's claims): #5 (a left-open workout offered as next day's), #7, #8, #12
  (Builder A, Live Activity "Go" all night), #13 (Builder B, show processNotes), #14-16.
