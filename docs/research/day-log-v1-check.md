# Day log v1 sheet, checked against the acceptance pack (board item 111)

For: Design, Builder B, Core. Date: 2026-10-16 (written Oct 15, 9:15 PM PT; all times Pacific).
Sheet: `docs/design/day-log-v1.md` at **8ceb4e5** (branch `claude/project-thread-b3tu3f`, unchanged at its head ed44329),
with its board source `docs/design/studies/day-log-v1.html` and recording `recordings/day-log-turnover.mp4` (same commit).
Pack: `research/day-log-acceptance.md` (DL1 to DL71, K1 to K7). Also read: `day-log-copy.md`, `day-log-late-night.md`,
`day-log-first.md`, Design's `day-log-page.md` and `no-dots.md` (branch head), `product/decisions.md` (8:07, 8:56, 9:12 PM PT).
Read only, nothing run.

Calls this check holds the sheet to: days fold by TesseraDay (04:00) on the root item's own start time, in the zone on its
create record (`op.zone`); times print in the current zone (8:56 PM PT); no coloured bullet dots, colour arrives through
motion and moments, resting colour low-contrast (8:07 PM PT); **the faint row replaces the faint dab** (9:12 PM PT);
"×" on screen; Inter Tight, 16pt floor, no italics; undo names the thing then what happened, destructive writes keep a
10 s UNDO.

## What master has (origin/master 08bcf6b, Oct 15 9:10 PM PT)

- Still **no `DayStory`, `DayLine`, `DayLookup` or `Features/DayLog/`**: `git grep -i daystory origin/master` hits docs only.
  `Features/Workout/WorkoutFinishView.swift:95-98` has a private `dayLine` ("Thursday, 18:02 to 19:03"), the finish
  screen's own line, not the fold.
- Zone per record is in: `op.zone` column (`TesseraCore/Sources/TesseraCore/Model/TesseraDatabaseSchema.swift:52-55`,
  read back `:251`), `OpRecord.zone: String?` (`Model/Models.swift:549-552`), stamped once per record
  (`Actions/ActionEngine.swift:66-67`) from `TimeZone.autoupdatingCurrent` (`:36-38`).
- 04:00 day: `Engine/TesseraDay.swift:10` (`startHour = 4`), `:22-24` (`day(of:)`).
- Column clock: `App/AppClock.swift:47-50` (`Calendar.current`, `"%02d:%02d"`).
- Ink tiers: `DesignSystem/Theme.swift:300` (`inkSecondary`), `:313` (`inkTertiary`), `:340` (`restTint`).
- The planned `DayLine` (`day-log-first.md:98-99`) carries only `time: Date?`, `text`, `objectIDs`. Nothing tells the
  page a line is a past unfinished workout, a running one, the Rest day row or the "Also:" tail. See rows 10, 11, 23.

## Line by line

"L" is the sheet's line number at 8ceb4e5. "Board" rows are the drawing in `studies/day-log-v1.html` that L4 and L5 point to.

| # | Sheet text (L) | DL IDs | Verdict | Fix | Owner |
|---|---|---|---|---|---|
| 1 | L1 title "Day log v1: the acceptance states, drawn" | none | sheet only | None. | Design |
| 2 | L3 "adds the visual answer for each Page row there" | DL32 to DL39, DL54 to DL56, DL58, DL70 | differs | Not every Page row is drawn (see rows 31 to 39). Draw them or say "the late night, travel, rest and first-day rows". | Design |
| 3 | L3 "`day-log-page.md` stands ... with the changes below" | DL22, DL40, DL58, DL64, DL66 | differs | `day-log-page.md` still says "Push day, 4 sets, not finished", "Row 70 x 10" (its line 32), "dab at 40%" (line 28), a running line with "dab ... full strength" (line 47) and a Tess wash with no place to land now there's no dab (line 42). The four changes don't strike these. Add them to the changes list or fix `day-log-page.md`. | Design |
| 4 | L4 board phone 2: "travel and the fall-back night" on one phone, read in New York | DL11, DL14, DL57, K1 | differs | One read in one zone can't show MON 26 in New York times (10:30, 00:40, 04:30) and SAT 31 in LA times (20:00, 00:50, 01:30, 01:30). Read in New York, SAT 31 would print 23:00, 03:50, 04:30, 04:30. This is the "never a mix of zones" case DL57 forbids. Split it into two phones, or caption it as two reads. | Design |
| 5 | L4 board phone 3: WED 14 shows "07:10 Push Day A, 52 min. Bench 82.5 × 8, PR." with an "Also:" tail under 2 lines | DL30, DL41, DL51 | differs | WED 14 is the pack's untrained day (DL51: 12:40 done, 19:30 carbonara, no workout line). The tail only appears past the 6-line cap (DL30, DL41), so a 3-line day has none. Use another date, and either 6 lines plus the tail or no tail. | Design |
| 6 | L4 board phone 2: empty run "TUE 27 TO FRI 30" | DL49 | differs | In LATE Day 5 Tue 27 has "06:55 Added 2 tasks", so it isn't empty in the same story. Use "WED 28 TO FRI 30" or the pack's "OCT 1 TO 4". | Design |
| 7 | L5 recording: the turnover block holds "02:10 Note: hotel ideas" under WED 21 | DL4, DL46 | differs | Phone 1 has the same note at 00:31. DL4 puts "hotel ideas" at Fri 02:10 on THU 22. Align on 00:31, or rename the note so it doesn't read as DL4's. | Design |
| 8 | L8 "No dabs" (8:07 PM PT): time, then text | DL22, DL30, DL31, DL40, DL50, DL58, DL60 | differs (pack) | Sheet matches 8:07 and `no-dots.md` (Day log row). The pack still says "dab at 40%" (DL22, DL60), "rest dab" (DL31), "full training dab" (DL58), "dab 100%" (DL60). Pack change P1 to P3. | Research |
| 9 | L8 text column at x 86, 64pt time column | none | sheet only | Build it. The margin scrub stays the left 80pt (`day-log-page.md`), so it ends before the text at x 86. | Builder B |
| 10 | L9 the faint row: past unfinished workout, text in `inkSecondary`, no words, no mark | DL22, DL60, DL64; 9:12 | differs (pack, Core) | Sheet matches 9:12 PM PT word for word. Pack DL22, DL60, DL64 still say the dab carries it (P1). The page can't tell a past unfinished workout from a finished one: `DayLine` has no state, and reading "min." out of the text is fragile. Core adds a field such as `state: .finished / .running / .unfinished`. | Core, Research |
| 11 | L9 "Running today, the same line is in `ink` (DL58, DL60)" | DL58, DL60, DL70 | differs | The running text isn't "the same line": DL60's running form drops the top set ("Pull Day A, 3 sets"). DL70 also has a running workout on a past block (SAT 24 at Sun 04:10), so "today" is the wrong test. It should read "while running, wherever its block is, the line is in `ink`". Core's state field (row 10) makes it buildable. | Design, Core |
| 12 | L10 no-break space either side of × | DL20, DL21, DL41, DL66 | sheet only | The pack's exact strings use plain spaces. Builder B swaps " × " for NBSP×NBSP at render, so Core's text and its tests stay as written. VoiceOver still reads "by" (DL18, DL38). Pack note P7. | Builder B |
| 13 | L11 lines sort by instant, never by text | DL14, DL16, DL57; pack rules | match | Core sorts on `Date`. Builder B never re-sorts. | Core, Builder B |
| 14 | L16 late night: TODAY in `ink`, "19:05 Added 2 tasks", "23:20 Push Day B, 5 sets" running in `ink` | DL3 | match | None. | Builder B |
| 15 | L16 third line "00:31 Note: hotel ideas" | DL3, DL4 | sheet only | Not in DL3's fixture, whose Wed 21 lines are 19:05 and 23:20 only. It does fold to Wed 21 by the 7:40 rule. Either mark it as illustrative or add it to DL3 (P6). Rename it (row 7). | Design, Research |
| 16 | L16 "Times after midnight print as they are, no seam, no 'after midnight' words" | DL45, DL46, DL40 | match | None. | Builder B |
| 17 | L17 turnover step 1: label crossfades TODAY to WED 21 in place, 220ms blur, `ink` to `inkSecondary`, nothing moves | DL46, DL36 | match | Through `MotionPolicy` (`.tesseraAnimation`). | Builder B |
| 18 | L17 turnover step 2: 260ms later the window eases up 64pt (420ms), new empty TODAY rises 10pt (360ms) | DL46 | differs | DL46 says "without moving". The sheet's relabel doesn't move, but the window then shifts 64pt. Fine by intent; the pack wording needs to allow it (P5). No Reduce Motion form is given: add "crossfade, no ease or rise" per `day-log-page.md` line 48. The case of a running workout across 04:00 (DL70) isn't drawn: its line stays on the relabelled block, in `ink`. | Design, Research |
| 19 | L17 "No sound, no haptic, no line about the hour" | DL46 | match | None. | Builder B |
| 20 | L18 travel read in New York: "10:30 Done: water the plants", "00:40 Mobility, 35 min", "04:30 Note: seat 14C, no sleep"; 10:30 above 00:40; no zone tag, no "Travel day" | DL11, DL12, DL13, DL57, DL69 #7 | match | Core: the day comes from the root's create record `op.zone` (`Models.swift:549-552`), nil meaning the calendar's zone; times print in the current zone. Needs `DayLookup.dayZone` and `dayTime` (K6). | Core |
| 21 | L19 fall-back: two "01:30" rows in instant order, workout "90 min" | DL14, DL15, DL16 | match | Board also draws DL16's "20:00 Cooked dal tadka, 50 min" (but see row 4 on the zone). | Core, Builder B |
| 22 | L20 "Rest day": first row, no time, 21/400 | DL31, DL42, DL43, DL65 | match | None. | Builder B |
| 23 | L20 "Rest day" in `inkSecondary`, no dab, no stroke | DL31; COPY state 2 | differs (pack) | Sheet follows 8:07. Pack DL31 says "Page: rest dab" (P2). The board draws it with the faint row's class, so the Rest day row, the faint row and the "Also:" tail (70% ink) all rest at about the same tier. Design says whether that's intended. Rest day and the tail both have `time == nil`, so the page needs a kind on `DayLine` to pick 21/400 `inkSecondary` against 70% ink (row 10's field). | Design, Core |
| 24 | L21 faint row: "The time keeps its usual tier" | DL22, DL60 | sheet only | Pack is silent. `day-log-page.md` gives the time as `inkSecondary` at 75%. The board uses 50% ink. Builder B uses one token (`inkTertiary` or `inkSecondary`), not a literal. Design says which one. | Design, Builder B |
| 25 | L22 "Also:" tail: no time, 70% ink, wraps, opens nothing | DL30 | match | None ("no dab" in DL30 is now moot). | Builder B |
| 26 | L23 empty runs: "TUE 27 TO FRI 30" at 45%, one row; single "THU 8" | DL49, DL39 | differs | Covers 2 of DL49's 4 cases. Not drawn: the cross-month run "SEP 29 TO OCT 2" and an empty TODAY alone at the bottom. VoiceOver "October 1 to 4, nothing logged" (DL39) isn't mentioned. Labels at 45% ink are 16/700, which isn't large text, so QA checks contrast on Porcelain and the dark looks. | Design |
| 27 | L24 first day: TODAY in `ink` at the bottom, "Your days write themselves here." 21/400 at 55%; the first record rises in as the line fades (220ms) | DL50, DL67 | match | "No days drawn above it" holds on the board. | Builder B |
| 28 | L27 "Never": dabs, zone tag, travel word, midnight seam, counts of empty days, red, "not finished" | DL40, DL49, DL57 | match | It could also list italics and DL40's banned words (only, missed, behind, streak, should, again, late, great). | Design |
| 29 | L30 owners: the page is Builder B's (`Features/DayLog/`); fold, day and zone are Core's (`DayStory`) | pack Layer column | match | Core also owns the line state from rows 10, 11 and 23. | Core |
| 30 | Board type: Inter Tight, times 16/600 tabular, labels 16/700, text 21/400, no italics | DL40 | match | None. | Builder B |
| 31 | (not on sheet) Review link "The week · Day log · Notes"; Home's "Thursday afternoon" | DL32, DL33 | pack only | Design draws the two ways in under no-dots, or points to `day-log-page.md`. | Design |
| 32 | (not on sheet) back words ‹ HOME, ‹ DAYS | DL34 | pack only | Board shows ‹ HOME only. | Design |
| 33 | (not on sheet) month title "October", Title 44/500 | DL35 | pack only | On the board but not checked. Point to `day-log-page.md`. | Design |
| 34 | (not on sheet) scrub numeral SUN over 11, OCT over 1–4 | DL37 | pack only | Point to `day-log-page.md` or draw it. | Design |
| 35 | (not on sheet) VoiceOver for a line and an empty run | DL38, DL39 | pack only | Sheet should state the VoiceOver forms (sentence time "7:10 am", "by" for ×). | Design, Builder B |
| 36 | (not on sheet) live recount: "Set 3 taken back." swaps the numbers (220ms blur) | DL54 | pack only | With no dab, say whether anything else changes. | Design |
| 37 | (not on sheet) "Dentist taken back." fades the line out (220ms), back on redo | DL55 | pack only | Draw it or point to `day-log-copy.md` M6. | Design |
| 38 | (not on sheet) destructive write elsewhere: the undo line names the thing then what happened, UNDO 10 s; the log redraws, no UNDO on the log | DL56 | pack only | Sheet should restate "no UNDO key on this page". | Design |
| 39 | (not on sheet) Tess write gets the 2.8 s cobalt wash | DL58 | pack only | With no dab, say where the wash sits (behind the text band, as `no-dots.md` does for Home rows), then it dries to ink. | Design |

**Counts:** 39 rows. 13 match, 12 differ (2 of them only because the pack is stale: rows 8 and 23), 5 sheet only, 9 pack only.

## DL tests the sheet doesn't cover

- **Page layer, not drawn or not stated:** DL32, DL33, DL34, DL35, DL37, DL38, DL39, DL54, DL55, DL56; DL58's wash and its
  running line (only cited); DL70 (running past 04:00 on a past block); DL49's cross-month run and empty TODAY; DL41's
  6-line cap (the board contradicts it, row 5); DL51 (the board's WED 14 contradicts it, row 5).
- **Core only, which the sheet doesn't need to draw:** DL1, DL2, DL4 to DL10, DL17 to DL21, DL23 to DL29, DL40 (text
  half), DL44, DL47, DL48, DL52, DL53, DL59, DL63, DL66, DL68, DL69, DL71. DL18 and DL63 (VoiceOver) are Core text that
  Builder B reads out, so they also count under row 35.
- **5b, not gating:** DL61, DL62.

## Changes the pack needs (applied Oct 15, 11:25 PM PT, after Kaushik's yes)

All eight are now in `day-log-acceptance.md`, and the COPY items in `day-log-copy.md`. P6 took Research's default: the sheet's "00:31 Note" is illustrative and stays out of DL3.

- **P1, the faint row (9:12 PM PT).** DL22: "Page: dab at 40%" becomes "Page: the faint row, text in `inkSecondary`, no
  mark". DL60: past "(dab 40%)" becomes "(faint row)", today "(dab 100%)" becomes "(`ink`)". DL64's clause becomes
  "the faint row carries it (9:12 PM PT, replacing 7:34's faint dab)".
- **P2, the Rest day row.** DL31: "Page: rest dab" becomes "Page: no time, 21/400 `inkSecondary`, no dab".
- **P3, no dabs (8:07 PM PT).** Rules paragraph: "dabs carry the class colour only" becomes "no dabs on the Day log".
  DL58: "full training dab, no glow" becomes "`ink`, no mark, no glow; a Tess write gets the 2.8 s cobalt wash behind
  its text". DL30 and DL50 "no dab" can stay (still true). Add 8:07 and 9:12 to the source map.
- **P4, the line state.** Add a K8: `DayLine` needs a kind or state (finished, running, unfinished, rest, tail) so the
  page picks the tier without parsing text. Add a Core test, for example `pastUnfinishedWorkoutIsMarkedUnfinished`,
  and a Page check for DL70 (a running line on a past block stays `ink`).
- **P5, DL46 wording.** "Relabels without moving" becomes "relabels in place; the window may then ease up 64pt for the
  new TODAY" (Design's turnover). Add a Reduce Motion expectation.
- **P6, DL3 fixture.** Decide whether the sheet's "00:31 Note" joins DL3. If it does, the expected Wed 21 lines gain
  `00:31  Note: ...` and "No Thu 22 lines" stays.
- **P7, no-break spaces.** One line under "Rules every expected line assumes": Core's text uses plain spaces around ×,
  and the page swaps in no-break spaces when it draws.
- **P8, stale pointers.** "What master has" cites 68ad34c; master is now 08bcf6b, still with no `DayStory`. DL71's
  "until a zone is stored ... known issue" reads as live; mark it as met (K4).
- **Pack-adjacent (COPY, for Research):** `day-log-copy.md` still says "Dabs carry the class colour only" (line 14),
  "rest dab" (state 2 and line forms), "full training dab" (state 11) and "dab at 40%" (state 12, M2). Fold these into
  the same pass as P1 to P3.
