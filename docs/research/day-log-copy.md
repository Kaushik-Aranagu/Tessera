# Day log copy, every state (board item 68)

For: Builder B (page), Core (`DayStory` fold), Design (mismatches). Date: 2026-10-16
Read with: `../design/day-log-page.md` (the spec, unchanged), `day-log-first.md`, `fixtures/day-log-days.md` on master, `shutdown-daylog-copy.md`, `tess-voice.md`, `undo-lines.md`, `late-night.md`, `day-boundary.md`, `settings-claude.md`, `../product/decisions.md`. Master eeec18c has no `DayStory`, `DayLine` or `Features/DayLog/` yet.

## Rules every line follows

- **The page draws, it never writes.** So in v1 there is no UNDO key on this page. Undo happens where the write happened ("Dentist taken back." on Home, "Set 3 taken back." in the workout) and the log just recounts.
- **Name the thing, then what happened, then one number.** Past tense, digits, units once, under 12 words, no "!", no em-dashes. Never: only, missed, not finished, behind, streak, should, again, late, great.
- **Trained** means at least one logged set (decision 6:44 PM). A workout with 0 sets gets no line, ever.
- **Times in the column** use master's `Format.clock`: "07:10", "21:40", 24 h, tabular. **Times inside a sentence** use L173's form: "9 am", "Saturday 3 pm". See mismatch M1.
- **Labels** are 16/700 uppercase: TODAY, WED 14, OCT 1 TO 4, ‹ HOME, ‹ DAYS. Dates follow the phone's locale order ("Nov 1", so "NOV 1").
- **Sets use ×** (decision 5:02 PM PT, master's receipts say "82.5 × 8"). Titles show exactly as stored ("Push Day A", "dal tadka"); the fold never changes case.
- **No colour means good or bad.** Dabs carry the class colour only. No red anywhere.

## Fixed words on the page

| Element | Copy |
|---|---|
| Review link line | The week · **Day log** · Notes |
| Home day label (second way in) | As Home has it: "Thursday afternoon" |
| Back word on the log | ‹ HOME |
| Back word on an object opened from a line | ‹ DAYS |
| Month title (Title 44/500) | October |
| Today's date label (ink) | TODAY |
| Past day label (`inkSecondary`) | WED 14 |
| Scrub numeral, one day | SUN over 11 |
| Scrub numeral, an empty run | OCT over 1–4 |
| VoiceOver, a line | "7:10 am, Push Day A, 52 minutes. Bench 82.5 by 8, PR." |
| VoiceOver, an empty run | "October 1 to 4, nothing logged" |

## Line forms (Core's, word for word)

| Kind | 1 | 2 | 3 or more |
|---|---|---|---|
| Workout, finished | Push Day A, 52 min. Bench 82.5 × 8. | | |
| Workout, finished with a PR | Push Day A, 52 min. Bench 82.5 × 8, PR. | | |
| Workout, sets but no finish | Pull Day A, 3 sets. Row 60 × 10. | | |
| Cook | Cooked carbonara, 35 min | | |
| Shop | Shopped, 1 item | Shopped, 14 items | |
| Captures | Added 1 task | Added 3 tasks, 2 groceries | |
| Dones | Done: call the bank | Done: water the plants, call mom | 5 tasks done |
| Ticks | Ticked 1 on Home | Ticked 6 on Lisbon packing | |
| Notes | Note: hotel ideas | 2 notes | |
| New thing | Saved dal tadka | New list: Lisbon packing | New routine: Push Day B |
| Tail (no time, no dab, 70%) | Also: 3 notes, 5 groceries, ticked 4 on Lisbon packing. | | |
| Planned rest day (no time, rest dab) | Rest day | | |

## The states

Each block is what the screen shows, top to bottom. Times are the column, then the text.

**1. A full day (past, Thu Oct 8, 31 records, cap of 6 lines).**
```
THU 8
06:50  Pull Day A, 61 min. Row 70 × 10.
08:30  4 tasks done
09:00  Added 7 tasks, 5 groceries
13:15  New list: Lisbon packing
17:40  Cooked omelette, 10 min
       Also: 3 notes, ticked 4 on Lisbon packing.
```
Captures are one line, tasks first (decision 4:30 PM PT), so "5 groceries" leaves the tail. No Tess line in v1 (slot A is 5b). In 5b, A5 sits under the date: "Full one. 31 things across 4 apps." (31 counts records; Core should count folded items instead.)

**2. A rest day (planned rest, Sun Oct 11).**
```
SUN 11
       Rest day
09:15  Added 3 tasks
18:05  Ticked 2 on Home
```
"Rest day" comes from the plan, not the op log (decision 4:30 PM PT), sits first with no time, and uses Design's rest dab. A rest day with nothing else shows "Rest day" alone. A day with no plan at all never says "Rest day" (`empty-states.md` row on the Training page). See M3.

**3. A late night past midnight (now Sat 01:30, still Friday's day until 04:00).**
```
TODAY
19:00  Cooked ramen, 40 min
23:20  Push Day B, 75 min. Incline 30 × 10, PR.
01:30  Note: watered the plants
```
TODAY stays on Friday's block until 04:00; no SAT 17 block exists yet. Lines sort by instant, so 01:30 is last. The workout from 23:20 to 00:35 belongs to the day it started. "watered plants yesterday" said at 01:30 dates the note Thursday and draws it on Thursday's block, at the time Tess gave it (`late-night.md` S8). At 04:00 the block relabels to FRI 16 without moving. No copy anywhere comments on the hour.

**4. Only captures (Tue Oct 13).**
```
TUE 13
08:05  Added 4 tasks, 3 groceries
14:55  3 notes
```
One line per kind, at the time of the first (rule 8). With 1 note it names it: "14:55 Note: gate B32, seat 14C". Captures never say "only" or compare to other days.

**5. An empty day.** Past, single: `THU 8` at 45%, no lines. Past run: `OCT 1 TO 4` at 45%. A run across months: `SEP 29 TO OCT 2`. Never a count of days. Empty today: `TODAY` alone at the bottom, no line under it.

**6. The first day ever (no records at all).**
```
TODAY
       Your days write themselves here.
```
21/400 at 55%, no dab, no time. It leaves with the first record, which inks in below the date. No empty days are drawn above the first day (days before first use don't exist, as on Review).

**7. A training day, not trained (Push Day A planned, 0 sets, other things done).**
```
WED 14
12:40  Done: call the bank
19:30  Cooked carbonara, 35 min
```
Nothing about the plan. No "Rest day" (the plan said train), no faint workout row, no 40% dab. With nothing else it is an empty day (state 5). A workout started and finished with 0 sets wrote "Push day, no sets, not saved." in the workout and leaves no line here.

**8. A missed day rolled on (Thu's Push Day A rolls to Fri, done Fri).**
```
THU 15        (empty, 45%)
FRI 16
07:10  Push Day A, 52 min. Bench 82.5 × 8.
```
`moveTask` and `rollForwardTasks` drop, so neither day says "moved" or "rolled". The workout line on Friday names the routine plainly.

**9. A day with an undone item (Mon Oct 5).** 11 sets with 3 taken back, a task made and deleted, 2 edits:
```
MON 5
18:20  Leg Day A, 48 min. Squat 102.5 × 5.
```
Undone and same-day cancelled records drop. Live, on today: when "Set 3 taken back." happens in the workout, the open log's line swaps its numbers like a value word (blur crossfade, 220 ms); when "Dentist taken back." empties "Added 1 task", the line fades out (220 ms) and comes back if redone. A destructive write (delete a note, finish the shop) keeps its 10 s UNDO where it was made; the log draws the committed state at once and redraws if UNDO lands. See M6.

**10. Travel and time zones (red-eye LA to New York, Mon Oct 26).**
```
MON 26        (read in LA)
07:30  Done: water the plants
21:40  Mobility, 35 min

MON 26        (same day, read in New York)
10:30  Done: water the plants
00:40  Mobility, 35 min
```
Every time prints in the phone's current zone, never a mix of zones (Product, 8:56 PM PT Oct 15). Times show in the phone's current zone (the `dst-travel.md` fallback until a zone is stored per record), so after landing the 21:40 PDT start reads "00:40", still on Monday's block (before 04:00). A day can look out of order by clock but sorts by instant. No "Travel day" in v1: it needs calendar or a stored zone (5b, A3 "Travel day. 3 things logged on the move."). DST fall back: both 01:30s read "01:30", in instant order, on the evening before.

**11. Today in progress (Thu, 18:10, a workout running).**
```
TODAY
07:10  Added 2 tasks
18:02  Push Day A, 4 sets
```
Running: no minutes, no top set, full training dab, no glow (running belongs to Now). New records ink in at the bottom; a Tess write gets the 2.8 s cobalt wash. On finish the line swaps to "Push Day A, 61 min. Bench 82.5 × 8."

**12. A past day vs today, same unfinished workout.** Past: "Pull Day A, 3 sets. Row 60 × 10." with its dab at 40%, no words about finishing. Today, still running: "Pull Day A, 3 sets", dab at 100%. If the 6 hour auto-finish ends it, the line turns into minutes.

## Tess line (slot A), for 5b only

Not in v1 (spec). When it lands: one line under the date, 21/400 cobalt, rows A1 to A9 from `shutdown-daylog-copy.md`, first match wins, frozen at Shutdown or 04:00. A10 ("Fills itself as you go.") is dropped in favour of state 6 and the silent empty today (M5). Undo from a past day (5b) follows the undo rule: preview "Set 3, bench 80 × 5, from Oct 12. PR goes back to 77.5." then "Set 3 from Oct 12 taken back." with UNDO for 10 s; refused as "Set 3 changed since. OPEN" (not day-log.md's "undid 1 thing from Oct 12", which names no thing).

## Mismatches with day-log-page.md, and proposed defaults

| # | Spec says | Conflicts with | Default |
|---|---|---|---|
| M1 | Column times "07:10" | `settings-claude.md` and L173 give "6:12 pm" for Tess times | Keep "07:10" in the column (master's `Format.clock`, as on the finish screen and Now's "Running since 21:40"; "11:40 pm" won't fit x 22 to 78). Use "9 am" only inside sentences. Product to confirm |
| M2 | "Push day, 4 sets, not finished" | `day-log.md` (never show what didn't happen), fixtures Day 3 | Drop "not finished"; the 40% dab carries it: "Pull Day A, 3 sets. Row 60 × 10." |
| M3 | No rest-day line | Decision 4:30 PM PT: a planned rest day shows "Rest day" from the plan | Add it: first row, no time, rest dab |
| M4 | "Row 70 x 10", "Push day" | Decision 5:02 PM PT ("×"); fixtures (titles as stored) | "Row 70 × 10", "Pull Day A" |
| M5 | First-ever line "Your days write themselves here." | Slot A's A10 "Fills itself as you go." | Keep Design's; retire A10 |
| M6 | Live inks new lines only | Undo and recounts change lines that exist | Value-word swap for a recount, 220 ms fade-out for a line that goes |
| M7 | Scrub numeral "1–4" (en dash) | Labels elsewhere say "OCT 1 TO 4" | Fine: no em-dash rule broken; keep the en dash at Numeral 80 for width |
| M8 | Day label "WED 14" | Runs across months; Core's rule 11 writes "Oct 1 to 4" | Page uppercases Core's text; cross-month run "SEP 29 TO OCT 2" |
| M9 | No "Also:" rule for which kinds tail | Fixture ambiguity 4 | Largest counts keep a line; the tail orders by first time |
