# The Day log side line "3 of 4 came after 6 pm." (rule and fixture)

For: Core (the helper), Builder B (the Day log side). Owner: Research lab. Date: Oct 17, 2026 (Pacific).

Docs only. Nothing here was run: there is no Swift toolchain in this container. Read against origin/master 3d28740 (fetched Oct 17), with `git show` and `git grep` only. Every value is made up; placeholders are hunter2, tacocat, 4417 and 2100.

Product's ruling (decisions, 8:12 pm Oct 16, sheet 82, call 3): "3 of 4 came after 6 pm." is accepted as a rules line. Counts only, finished sessions only, at least 4 of them, the 4 am house day and a lowercase clock. Call 2 of the same entry: side facts name finished things only, never an unfinished workout. Research writes the rule and the fixture. Where the ruling is silent, this page proposes a default and lists it in section 5 for Product.

## 1. The rule in plain words

**What it says.** Of the sessions he finished in the window, how many started after 6 pm. One sentence: "{n} of {total} came after 6 pm." It is a counts-only line. It never names a session, a routine, an exercise, a weight, a body number or an amount.

**Which sessions count (the denominator).** A session counts when all of these hold:

1. It is a Workout object that is finished: `endedAt` is set and its op is committed (not undone, not deleted). An unfinished or still-running workout is not counted anywhere in the line, neither in the 4 nor in the 3 (ruling, call 2). A faint-row workout from a past day, never finished, is the same.
2. It has at least one logged working set. This follows the 6:44 pm Oct 16 ruling that "trained" means at least one logged set, everywhere. A session closed with no sets is not counted. (Proposal P3.)
3. Its start falls inside the window (below).
4. Two sessions on the same day both count. The line counts sessions, not days.

**The minimum.** At least 4 counted sessions in the window. Fewer than 4 gives nil: no line, no "0 of 3", no placeholder. The minimum is on the denominator (all counted sessions), not on the evening count.

**When the count is zero.** If none of the counted sessions started after 6 pm, the line is nil. A zero is never a fact on a side (the rule in `sides-77-lines.md` section 1, and `side-line-helpers.md` E6). (Proposal P4.)

**The window.** Proposal P1: the 28 house days ending with today's house day, today included. The window starts at the 4 am start of the day 27 days before today and ends at the 4 am after today's house day. The ruling does not name a window, so this is Product's to confirm (section 5, Q1). The fixture rows use it.

**Which time is read.** The session's start (`startedAt`), not its finish. This matches the Day log, which files a workout by its root's start (decisions 7:40 pm Oct 16: "a workout running past 4 am stays on the day it started"). The start is read as a wall clock in the zone stored on the session's op record (`OpRecord.zone`, the zone it was started in), and the device zone when none is stored (rows before v3). This is the same zone rule the Day log already uses to decide the day (decision 8:56 pm Oct 16, `DayStory.swift` `onDay`). (Proposal P2, Q2.)

**What "after 6 pm" means exactly.** The clock is read the way the app prints it. `HouseTime.clock` (`Format/HouseTime.swift:7`) shows hour and minute and drops the seconds, so 6:00:45 pm prints "6 pm". The test is therefore on minutes: a start counts when its wall-clock minute of day is greater than 18 x 60, which means 6:01 pm and later. A session that starts 6:00 pm, and one that starts 6:00:59 pm, are not "after 6 pm". A session that starts 6:01 pm is. The reason is that the line must never contradict the clock the screen shows next to it (a row that prints "6 pm" cannot be counted as "after 6 pm"). The edge is a proposal (P5, Q3).

**Where the day boundary matters.** The house day runs 4 am to 4 am (`TesseraDay`, `Engine/TesseraDay.swift:11`). It matters for two things only: which sessions fall inside the window, and which day a session belongs to. It does not change whether a start is "after 6 pm": that is a pure clock test on the start. So a session that starts 12:30 am Wednesday belongs to Tuesday's house day, and is not after 6 pm (12:30 am is before 6 pm on the clock). A session that starts 11:30 pm Tuesday is after 6 pm and belongs to Tuesday.

**Edge cases.**

| Case | Rule |
|---|---|
| Spans midnight (starts 11:30 pm Tue, ends 12:40 am Wed) | Counts as after 6 pm. It belongs to Tuesday's house day. The finish time is only used to know it is finished. |
| Starts before 4 am, in the small hours (12:30 am Wed) | Belongs to Tuesday's house day. Not after 6 pm. Counted in the denominator. |
| Finishes at 3:59 am vs 4:00 am | No difference to the line. Start decides the day and the evening test; a finish 4:00 am does not move the session onto the next house day (7:40 pm ruling). |
| Starts 3:59 am vs 4:00 am | Matters only at the window's first edge: 3:59 am on the first window day belongs to the day before the window and is out; 4:00 am is in. |
| Start 6:00 pm exactly | Not after 6 pm (minute test above). Counted in the denominator. |
| Start 6:01 pm | After 6 pm. |
| Nov 1 fall-back night | Wall clock, not elapsed time. 1:30 am happens twice (1:30 am PDT, then 1:30 am PST); both read "1:30 am", both belong to Saturday Oct 31's 25-hour house day, neither is after 6 pm. 6 pm on Nov 1 is PST (UTC-8), a different offset from 6 pm on Oct 31 (PDT, UTC-7); the test reads the wall hour, so both are 6 pm. |
| Unfinished or running | Left out of both numbers. |
| Closed by the 6-hour wrap-up (actor `system`) | Proposal: counts if it has logged sets, because it is finished with `endedAt` set. Q4. |
| Undone, deleted | Left out. Only committed, non-deleted records count. |
| Private title | The title is never read, so a private routine or a workout named hunter2 gives the same line as any other. |
| Body or money facts in the same session | Never read. No weight, no body measure, no amount. |

**What the line looks like.** `"{n} of {total} came after 6 pm."` with plain digits, lowercase "pm", no "at", one stop at the end. It fits the detail slot (at most 14 words and 80 characters, one sentence ending in a stop, no "?" or "!"; `HomeLines.fitsDetail`, `HomeLines.swift:194`): this is 7 words and 23 characters for a one-digit pair. It is built from the counts by the caller; the helper returns two integers and nil, never a string (`side-line-helpers.md` shared rules). The "6 pm" in the sentence is the fixed threshold spelled the house way (`HouseTime.clock` of an 18:00 date gives "6 pm"), so a test can build it from `HouseTime` instead of a literal.

## 2. The helper this needs (proposal, for Core)

No helper exists on master (section 4). Proposed shape, small and in the neighbors' style:

```swift
@MainActor public struct EveningShare {
    public init(store: ObjectStore, calendar: Calendar = .current)
    /// nil when under 4 finished sessions in the window, or when none started after 6 pm.
    public func count(endingOn now: Date, days: Int = 28) -> (evening: Int, total: Int)?
}
```

Reads: Workout `startedAt`, `endedAt`, the op record's `zone`, the set count (`WorkoutSummary` or `lookup.workout(_:)` gives `sets`), `isDeleted`, `state == .committed`. Day math through `TesseraDay`. Never reads a title, a note or a set weight. The Day log page formats the sentence.

## 3. Fixture

"Now" is Saturday Oct 17, 2026, 9:00 am PDT (UTC-7) unless a row says otherwise. Window rule P1, so the window runs from Sun Sep 20, 4:00 am to Sun Oct 18, 4:00 am. Every session is a finished Workout with logged sets, started and finished in the zone shown, unless the row says otherwise. Session time is written "start to finish".

Shared sets used by the rows:

- **E3** (three evening sessions): Mon Oct 12, 6:30 pm to 7:25 pm. Wed Oct 14, 7:10 pm to 8:05 pm. Fri Oct 16, 6:15 pm to 7:10 pm.
- **M1** (one morning session): Thu Oct 15, 6:45 am to 7:30 am.
- **E4** (four evening sessions): E3 plus Thu Oct 15, 7:40 pm to 8:30 pm.

| ID | Case | Input sessions | Expected | Test name | Owner |
|---|---|---|---|---|---|
| DL1 | The ruling's example | E3 + M1 | "3 of 4 came after 6 pm." | `daylogSideLineThreeOfFour` | Core |
| DL2 | Under the minimum | E3 only (3 finished) | nil | `daylogSideLineNilUnderFourFinished` | Core |
| DL3 | An unfinished one does not fill the minimum | E3 + one Thu Oct 15, 7:40 pm, never finished (no `endedAt`) | nil | `daylogSideLineUnfinishedDoesNotCount` | Core |
| DL4 | An unfinished one is not in the 3 or the 4 | E3 + M1 + one Sat Oct 17, 7:40 am, still running | "3 of 4 came after 6 pm." | `daylogSideLineIgnoresRunningWorkout` | Core |
| DL5 | All of them | E4 | "4 of 4 came after 6 pm." | `daylogSideLineAllEvening` | Core |
| DL6 | None of them: nil, not "0 of 4" | Mon Oct 12 6:45 am to 7:30 am; Tue Oct 13 7:00 am to 7:50 am; Wed Oct 14 6:50 am to 7:40 am; Thu Oct 15 6:45 am to 7:30 am | nil | `daylogSideLineZeroEveningIsNil` | Core |
| DL7 | One in five | M1 + Mon Oct 12 6:50 am to 7:40 am; Tue Oct 13 7:05 am to 7:55 am; Wed Oct 14 6:55 am to 7:45 am; Fri Oct 16 7:20 pm to 8:10 pm | "1 of 5 came after 6 pm." | `daylogSideLineOneOfFive` | Core |
| DL8 | Start at exactly 6:00 pm is not after | Mon Oct 12 6:00 pm to 6:55 pm; Tue Oct 13 7:00 pm to 7:50 pm; Wed Oct 14 7:30 pm to 8:20 pm; Thu Oct 15 8:00 pm to 8:50 pm | "3 of 4 came after 6 pm." | `daylogSideLineSixPmExactlyIsNotAfter` | Core |
| DL9 | Start 6:00:45 pm prints "6 pm", so not after | Same as DL8, with the first start 6:00:45 pm | "3 of 4 came after 6 pm." | `daylogSideLineSecondsFollowThePrintedMinute` | Core |
| DL10 | Start 6:01 pm is after | Same as DL8, with the first start 6:01 pm to 6:56 pm | "4 of 4 came after 6 pm." | `daylogSideLineSixOhOneIsAfter` | Core |
| DL11 | Spans midnight, counts as evening | Tue Oct 13, 11:30 pm to Wed Oct 14, 12:40 am; Mon Oct 12 7:00 pm to 7:50 pm; Thu Oct 15 8:00 pm to 8:50 pm; Fri Oct 16 6:45 am to 7:35 am | "3 of 4 came after 6 pm." | `daylogSideLineSpanningMidnightCountsByStart` | Core |
| DL12 | Starts in the small hours: previous house day, not evening, still counted | Wed Oct 14, 12:30 am to 1:20 am (belongs to Tue Oct 13); E3 | "3 of 4 came after 6 pm." | `daylogSideLineSmallHoursStartIsNotEvening` | Core |
| DL13 | Finish 3:59 am | Tue Oct 13, 10:30 pm to Wed Oct 14, 3:59 am; E3 | "4 of 4 came after 6 pm." | `daylogSideLineFinishAtThreeFiftyNine` | Core |
| DL14 | Finish 4:00 am gives the same line | Tue Oct 13, 10:30 pm to Wed Oct 14, 4:00 am; E3 | "4 of 4 came after 6 pm." (the same as DL13; the session stays on Tuesday) | `daylogSideLineFinishAtFourAmSameAsBefore` | Core |
| DL15 | Window edge, 3:59 am is the day before the window | Sun Sep 20, 3:59 am to 4:45 am (house day Sat Sep 19, out); E3 + M1 | "3 of 4 came after 6 pm." (the early one is not counted) | `daylogSideLineWindowStartsAtFourAm` | Core |
| DL16 | Window edge, 4:00 am is inside | Sun Sep 20, 4:00 am to 4:50 am (house day Sun Sep 20, in); E3 + M1 | "3 of 5 came after 6 pm." | `daylogSideLineFourAmStartIsInsideWindow` | Core |
| DL17 | Now before 4 am still reads as yesterday's house day | Now is Sat Oct 17, 2:00 am PDT (house day Fri Oct 16); E3 + M1 | "3 of 4 came after 6 pm." (window ends at Sat Oct 17, 4:00 am) | `daylogSideLineNowBeforeFourAmUsesYesterday` | Core |
| DL18 | Fall-back night: both 1:30 am passes are small-hours starts | Now is Mon Nov 2, 9:00 am PST (UTC-8), window from Tue Oct 6 4:00 am. Sat Oct 31 1:30 am PDT (8:30Z) to 2:20 am PDT; Sun Nov 1 1:30 am PST (9:30Z) to 2:20 am PST; Fri Oct 30 7:00 pm to 7:50 pm; Sun Nov 1 6:30 pm to 7:20 pm | "2 of 4 came after 6 pm." | `daylogSideLineFallBackNightWallClock` | Core |
| DL19 | Fall-back: 6 pm Nov 1 is PST, and exactly 6 pm is still not after | Now is Mon Nov 2, 9:00 am PST. Sun Nov 1 6:00 pm PST (2:00Z Nov 2) to 6:50 pm; Sat Oct 31 6:30 pm PDT to 7:20 pm; Fri Oct 30 7:00 pm PDT to 7:50 pm; Thu Oct 29 7:30 pm PDT to 8:20 pm | "3 of 4 came after 6 pm." | `daylogSideLineSixPmAfterFallBack` | Core |
| DL20 | Fall-back: a session across the repeated hour is read by its start | Sat Oct 31 10:30 pm PDT to Sun Nov 1 1:15 am PST (the second pass); E3 | "4 of 4 came after 6 pm." | `daylogSideLineAcrossRepeatedHour` | Core |
| DL21 | Two sessions in one day both count | Tue Oct 13 6:30 am to 7:15 am and 7:30 pm to 8:15 pm; Wed Oct 14 6:40 am to 7:30 am; Fri Oct 16 8:00 pm to 8:50 pm | "2 of 4 came after 6 pm." | `daylogSideLineCountsSessionsNotDays` | Core |
| DL22 | A deleted or undone session is left out | E3 + one Thu Oct 15 7:40 pm to 8:30 pm that was deleted | nil (3 counted) | `daylogSideLineDeletedDoesNotCount` | Core |
| DL23 | A session with no logged sets is not trained | E3 + one Thu Oct 15 7:40 pm to 7:42 pm closed with 0 sets | nil (3 counted) | `daylogSideLineNoSetsDoesNotCount` (P3, Q5) | Core |
| DL24 | Closed by the 6-hour wrap-up counts if it has sets | E3 + Thu Oct 15, 6:30 pm, closed by `system` (12:30 am) with 17 sets | "4 of 4 came after 6 pm." (proposal P6, Q4) | `daylogSideLineWrapUpWithSetsCounts` | Core |
| DL25 | Started in another zone, read in its stored zone | E3 + Thu Oct 15, 9:00 pm EDT (6:00 pm PDT, zone America/New_York stored) | "4 of 4 came after 6 pm." under P2; "3 of 4" if the device zone were read (P2, Q2) | `daylogSideLineReadsStoredZone` | Core |
| DL26 | A private title and a secret word change nothing | E3 + M1, with one session titled "hunter2 push" and its routine named "tacocat" | "3 of 4 came after 6 pm." (identical to DL1; no title in the line) | `daylogSideLineNeverReadsTitles` | Core |
| DL27 | Money and body facts in the sessions change nothing | E3 + M1, with a Private note "rent 2100 fri" and a body weight of 82.4 kg logged that week | "3 of 4 came after 6 pm." (identical to DL1) | `daylogSideLineNeverReadsBodyOrMoney` | Core |
| DL28 | The copy rules hold | The output of DL1 and DL5 | Passes `HomeLines.fitsDetail`; no "at" before a time; lowercase "pm"; no em-dash, no ellipsis, no "?" or "!"; no "record" or "PR"; contains no title | `daylogSideLineCopyRules` | Core |
| DL29 | The Day log page shows the line only when non-nil, as a side line | DL1 data, and DL2 data | DL1: the line shows under the Day log side; DL2: no line, no blank row | `daylogSideLineShowsOnlyWhenNonNil` | Builder B |
| DL30 | VoiceOver reads the sentence as is | DL1 data | The label is "3 of 4 came after 6 pm." (no 24-hour time, no "at") | `daylogSideLineVoiceOverLabel` | Builder B |

Notes on the rows:

- DL8 to DL10 are the three-row test of the exact 6 pm edge. If Product rules that 6:00 pm counts (Q3), DL8 becomes "4 of 4" and DL9 follows it.
- DL13 and DL14 must be equal; a test can run them together.
- DL18: the 1:30 am PST pass has UTC 9:30Z on Nov 1 and the 1:30 am PDT pass 8:30Z. The wall clock reads "1:30 am" for both, and both are before 6 pm. Sat Oct 31 1:30 am PDT belongs to Fri Oct 30's house day; Sun Nov 1 1:30 am PST belongs to Sat Oct 31's. The two evening starts bring it to 2 of 4. (`dst-nov-1.md` traces the same night for the other clock math.)
- The 28-day window means the DST rows from DL18 on look back to Oct 6. Nothing in them depends on the 25-hour day, because only the start's wall clock and the window edges are read.

## 4. What passes on master

Read on origin/master 3d28740. Short answer: no row passes, because nothing builds this line.

- `git grep` for "came after", "after 6", "EveningShare" and any evening count in `*.swift` finds no helper and no string. The only "after 6" hits are about the 6-hour wrap-up (`WrapUpUndoUITests.swift`) and a grammar case.
- `DayStory.lines(for:on:calendar:lookup:now:isRestDay:)` (`DayLog/DayStory.swift`) folds the op log into lines for one day. Its `DayLookup.workout(_:)` returns `(title, startedAt, endedAt, sets)`, which has everything the helper needs, but nothing counts across days.
- `WeekFacts` counts trained days, not sessions and not hours (`WeekFacts.swift:42`, `trainedDays`); it is not a base for this.
- `TesseraDay` (`Engine/TesseraDay.swift`) gives the 4 am day, `start(of:)`, `end(of:)`, `interval(of:)`, and reads the wall hour, so the window edges (DL15 to DL17) and the 25-hour day (DL18 to DL20) have their base. It is not tested for this line.
- `HouseTime.clock` (`Format/HouseTime.swift:7`) prints "6 pm" lowercase with no zero minutes; it is the right clock for any time near this line. It has no threshold test and nothing calls it for "after 6 pm".
- `OpRecord.zone` exists (the Day log already reads it in `DayStory.lines`), so DL25's stored zone is available.

| Rows | On master |
|---|---|
| DL1 to DL28 (helper and sentence) | Not built. No helper, no sentence, no test. |
| DL29, DL30 (page) | Not built. No side declaration or SideHost on master either (`drawn-sides-acceptance.md`, Research BQ), so these wait on Core 0ak. |

Result: 0 of 30 pass. A good first test to write is DL1, DL2 and DL10, because they fix the shape, the minimum and the exact edge.

## 5. Open questions for Product

1. **Window (Q1).** The ruling gives no window. Proposal P1 is the last 28 house days, today included. A side on the Day log might instead mean the week on screen (then 4 sessions in one week is a lot) or the whole history. Which?
2. **Zone (Q2).** Is "after 6 pm" read in the zone the session was started in (P2, matches how the Day log picks the day), or in the zone the phone is in now (matches how the Day log prints times, 8:56 pm Oct 16)? On a trip these give different counts (DL25).
3. **The exact edge (Q3).** Does a start 6:00 pm count? Proposal: no, and 6:01 pm is the first that does, so the line never contradicts the printed "6 pm". If Product prefers the plain "6 pm or later" reading, say so and DL8 and DL9 flip.
4. **Wrap-up closes (Q4).** A workout the app closed after 6 hours idle (actor `system`) has an end. Does it count as finished? Proposal P6: yes, if it has logged sets. If he must have pressed Finish himself, say so.
5. **Sessions with no sets (Q5).** Proposal P3: not counted, following the 6:44 pm Oct 16 "trained" ruling. Confirm.
6. **Zero evening (Q6).** Proposal P4: nil instead of "0 of 4". Or is a "none came after 6 pm" sentence wanted? That would be a different line.
7. **The mirror.** Is there a morning line ("3 of 4 came before 8 am")? Not in the ruling, so not here.

## Rulings

Product ruled at 8:19 pm (decisions 8:19): all six proposals above are yes as written, and there is no morning mirror line. No row is open.
