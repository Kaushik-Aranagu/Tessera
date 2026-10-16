# Review: #507 core/clock-format (board 0q, time-words sweep)

QA, Oct 16 2026, ~1:25 PM PT. Head **9ac58f4**, one commit, merges cleanly onto master. Static review.

## Verdict: FIX FIRST (one layout item on Home's queue); the engine side is PASS

### Engine: correct
- `HouseTime.clock` (Format/HouseTime.swift) is the one 12-hour form: "6:30 pm", "7 pm", "12:05 am", "12 pm".
  - `DayStory.sentenceTime`, `DayStoryClock.sentenceTime`, `NowPicker.clock` (NowRanker.swift:335, "Running since 6:02 pm" and "at 6:30 pm") and `Format.clock` (AppClock.swift:48) all call it.
  - `DayStoryClock.shortTime` is gone. The hero now reads "Tacos at 7 pm" (TW17).
- TW26: `TessMemory.when` names his day ("on Oct 16" for 12:30 am Oct 17), formatted in the calendar's zone (TessMemory.swift:90-93).
- TW27: the weekday in the cook pattern comes from his day (TessMemory+Turnover.swift:190).
- TW29: `TessDates.nextDate` counts from `TesseraDay.day(of: now)` (TessGrammar.swift:742-746).
  - At 1 am Friday, "thu" with no time lands at the next whole hour (2 am Friday), by the existing weekday-today rule at :683-690.
  - At 1 am Friday, "thu 3pm" is past, so it goes to next Thursday 3 pm.
  - In the afternoon, "thu" is next Thursday. The tests pin the no-time and afternoon cases.
- TW28 is unchanged, as Q5 ruled ("today" at 1 am means Friday).

### FIX FIRST: Home queue's time column was sized for "20:30"
- HomeQueue.swift:221 reserves `timeRoom = 64` pt (scaled), and the title pads 64 pt on the right (:368).
- The time is `.textRole(.label)` (:375-376). In the house themes that is a 16 pt label, often mono and uppercase (Theme.swift:165-166, 200-201, 231). At 16 pt mono:
  - "8:30 PM" (7 characters) is about 70 pt.
  - "10:30 PM" (8 characters) is about 80 pt with tracking.
- Both are wider than 64 pt. On a title long enough to reach the right edge, the time column now overlaps the title's last words. Today's demo has "Read Designing Data-Intensive Applications" at 9:10 pm, so it will show.
- A smaller point: `.label` themes uppercase it, so the queue reads "8:30 PM" while every sentence reads "8:30 pm". Design should say which they want there. `.textCase(nil)` on that one Text, or the `.data` role (it skips the uppercase), keeps it lowercase.
- Fix (Builder B's file; Core can carry it here or Builder B can ship it alongside):
  - Size `timeRoom` for the widest time, about 88 pt scaled, or measure "10:30 pm" with the same role.
  - Or lay the time out in the HStack instead of a fixed pad.
  - Then check the clip at "Read Designing Data-Intensive Applications 9:10 pm".

## What he sees (for Design)
- **Home queue, right column:** "8:30 pm" / "9:10 pm" in place of "20:30" / "21:10" (HomeQueue.swift:375). This is the layout item above.
- **Now page proposed line:** "Stretch & mobility … 8:30 pm" (NowPage.swift:340), plus its VoiceOver label (:394).
- **Home hero:** "Tacos at 7 pm" (was "at 7").
- **Now picker why-lines:** "Running since 6:02 pm", "at 6:30 pm" (were 24-hour).
- **Workout finish:** "Friday, 6 pm to 7:02 pm" (WorkoutFinishView.swift:97).
- **Object page date values:** "Thu 6:30 pm" (ObjectPage.swift:418).
- **Day strip VoiceOver:** "Now 6:30 pm." (DayStrip.swift:127).
- **Tess memory lines:** after midnight they name his day ("on Oct 16").
- Widgets and the Live Activity don't use these and are unchanged.

## Lows
- **R1** At 1 am, "call mom thu" becomes a task at 2 am, inside quiet hours (23:00-07:00). This rule came before this PR (the weekday-today rule). TW29 just makes it reachable after midnight. Product may want the no-time case to snap to 7 am (the end of quiet hours) instead.
- **R2** `hourToday` (TessGrammar.swift:642) still compares wall dates (`isDate(_:inSameDayAs: now)`), so at 1 am Friday "thu 9" doesn't get the today hour rule. It is harmless: 9 resolves to 9 am Thursday, which is past, so it lands next Thursday at 9 am. It's worth noting for the sweep.
