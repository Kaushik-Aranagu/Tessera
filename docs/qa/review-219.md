# Review #219: day boundary for Builder B (15f2d86, head bc9731b)

Builder B changed 10 files (+89/-89), plus a recording. This is a static review against Core's TesseraDay (#187/#191) and the past-day flags (#201).

**Verdict: PASS. R4 is closed.** There's one test-coverage gap (D7) and one change in meaning (D8) for Design to know about. Nothing here is a bug.

## Checked
- **R4 / Review marks:**
  - `lastDays` uses `TesseraDay.today`. `marks` compares day keys (midnights) against `TesseraDay.today`.
  - So at 01:00 Saturday, an untrained Friday is still today. It gets no mark, or rest if Core says rest. It is never a miss.
  - `DayDabs.isToday` uses the same key.
- **The midnight trap:** day keys are midnights, and under the 04:00 rule a midnight belongs to the *previous* day. `planMarks` gets around this by asking `ledger.week(containing:)` at noon of the key. That's correct.
  - Both sides use Monday-first weeks: `WeekReview.mondayFirst` for the de-duplication, and TesseraDay forcing `firstWeekday = 2` in the ledger. So a rolling 7-day window that spans two plan weeks computes both weeks. I traced Thu→Wed: Thu–Sun come from week A, and Mon–Wed from week B.
- **Core flags:**
  - Past empty days show rest when `isRest`, and the miss ring only when `wasDue`.
  - Past days with neither flag show no mark. Those are weeks with no rhythm (no plan, or perWeek 0), where a miss can't be known.
  - Today shows rest only when `isRest` or `restToday`. Days ahead show nothing.
  - The first-use gate runs first, so days before he started get no mark. That covers my F2 from #201.
  - The full Review's `WeekDabs` falls back to `.planned`, not `.open`.
- **B1:** QueueRow "next week" goes to 09:00 on his day seven days on: `start(of:)` gives 04:00, +7 days, +5 h. MoveTask now gets `time: AppClock.now`, which closes D4 from #187.
- **B2:** Home lanes key on `TesseraDay.day(…after:)` and filter by each item's own day. The workout spans come from `ledger.finishedWorkouts(onDay:)`.
- **B3:** `SpokenTime`. At 01:00 Saturday, a 14:00 Saturday item reads "tomorrow at two". I checked this: `adding(days: 1)` lands on Sun 01:00, which is Saturday's day.
- **B4:** a DayStrip item running past midnight on the same logical day extends to hour 24+, capped at 28. The display still clamps at 23.
- **Late-night #5:** "today's workout" is the same logical day, not ±12 h, so a workout left open last night isn't tonight's.
- **#13:** BottomChrome speaks `processNotes` once and then clears them. This assumes there is one BottomChrome on screen; two instances could both speak on the initial value. I believe there is only one.
- **HomeDataTests:** the lanes test now asserts logical-day membership.

## HomeRestDayTests: what the rewrite (-28/+22) still covers

| Old case | Now |
|---|---|
| Kept plan, today rest (`restToday`) | Covered (`resting[3] == .rest`) |
| Thin week: empty past days open | Covered as a mapping (`wasDue` → `.open`). The "which days" decision now lives in Core's `pastEmptyDaysSayRestOrDue` |
| R1: Monday trained, empty Tue/Wed, Thursday | Mapping only. Core decides which day is rest. **See D8** |
| R2: a double-session day counts once | **Not covered anywhere now (D7)** |
| Before first use: none | Covered |
| New: R4 at 01:00 | Covered (`late[3] == .planned`) |

- **D7 (test gap):** R2 was the bug where a double-session Monday counted as two days toward the week. The logic now sits in Core: `before` counts done *days* (TrainingLedger `wasDue`). But no Core test pins it, and the app test only checks `.trained(2)`.
  - Fix: add a Core row. Use perWeek 3, two sessions on Monday, now Thursday. Assert that Tuesday is `isRest` and Wednesday is `wasDue`, the same as with one session. With two sessions counted, `before` would be 2 and the spread would shift.
- **D8 (meaning change, for Design):** with perWeek 6, Monday trained and nothing on Tuesday or Wednesday, the old test put the rest on **Wednesday** and the ring on Tuesday. Core's "that morning" rule now gives:
  - **Tuesday rest**: the day after a trained day, with 5 days left for 5 sessions.
  - **Wednesday ring**: 5 due over 5 days, so every day was due.
  - Both are defensible, and the new one follows the plan as it looked each morning. Design should know the ring moved to the later day.

## Low
- **D9:** `HomeData.lanes` asks `model.schedule(around: day)` with a midnight key for the yesterday and tomorrow lanes. If `schedule(around:)` is a calendar-day window, items from 00:00 to 03:59 after that midnight belong to the lane but might not be fetched. Check that the window covers through 04:00 of the next day. I didn't trace AppModel.schedule's window.
