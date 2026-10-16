# Day log v1: the acceptance states, drawn (Design item 14)

This sheet is for Builder B's Day log page, with three asks of Core. It's drawn to Research's `day-log-acceptance.md` (item 104) and fixed to Research's check of it (`research/day-log-v1-check.md`, item 111). `day-log-page.md` stands for entry, layout and the margin scrub, and it's now amended to match (no dabs, the x 86 column, the copy).
- Board: `mockups/day-log-v1.png` (source `studies/day-log-v1.html`), Porcelain. It has six phones, and **each phone is one read in one zone**:
  1. Late night.
  2. Travel, read in New York.
  3. The fall-back night, read in Los Angeles.
  4. A rest day, the faint row, an empty day and an untrained day.
  5. The 6-line cap.
  6. The first day.
- Recording: `recordings/day-log-turnover.mp4`. It shows the 04:00 turnover with a workout still running.

## The rules this sheet sets
1. **No dabs** (`no-dots.md`, Kaushik 8:07 PM). A line is the time, then the text. The text column is at **x 86** (a 64pt time column). The margin scrub stays the left 80pt.
2. **Two tiers, both tokens:**
   - `ink` is for live text: today's date and the lines of finished things.
   - `inkSecondary` is for quiet text: every time, past dates, the **Rest day** row, **the faint row** and the **"Also:"** tail.
   - Empty days and runs are labels at 45%.
   - Times use `inkSecondary`, not `inkTertiary`, because tertiary is for text at 34pt and up. The quiet rows sharing one tier is intended. They're told apart by place and form: Rest day is first and has no time, the tail is last and starts "Also:", and the faint row has a time.
3. **The faint row replaces the faint dab** (Product 9:12 PM). A past workout that was never finished has its text in `inkSecondary` ("Pull Day A, 3 sets. Row 60 × 10."). It gets no words ("not finished" stays out) and no mark.
4. **A running line is `ink` wherever its block is** (DL70), including a block relabelled at 04:00.
   - Its text is Core's running form, which is shorter: it drops the top set ("Push Day B, 5 sets", DL3, DL58, DL60).
   - The numbers swap like a value word as sets land (blur crossfade, 220ms, DL54).
   - Nothing on this page glows; running belongs to Now.
5. **Core adds `DayLine.kind`** (finished, running, unfinished, rest, tail), so the page picks a tier without reading the text. This is Research's P4 and K8. Without it the faint row and the running line can't be built.
6. **Sets never break.** Core's text keeps plain spaces around ×. Builder B swaps in no-break spaces when drawing (" × " becomes NBSP×NBSP), so "× 10" never starts a line. Research's P7.
7. **Lines sort by instant.** The page never re-sorts.

## The states
| State | Drawing | Checks |
|---|---|---|
| **Late night** (now Thu 22 00:45) | The block is still **TODAY** in `ink`: "19:05 Added 2 tasks", "23:20 Push Day B, 5 sets" (running, `ink`, short form). Times after midnight print as they are, with no seam. The board's third line, "00:31 Note: flight check-in", is illustrative (Research's P6 decides whether DL3 gains it). | DL3, DL45 |
| **The 04:00 turnover** | **Nothing moves** (DL46). The label crossfades **TODAY → WED 21** in place (blur crossfade, 220ms; `ink` to `inkSecondary`). 260ms later a new **TODAY** crossfades into the **foot**, a 64pt space the window always keeps under today's block (the soul's corner sits beside it). The page re-anchors only the next time it opens. A workout still running stays on WED 21, in `ink`, still counting. No sound, no haptic, no line about the hour. **Reduce Motion:** the same, without the blur. | DL46, DL70, DL36 |
| **Travel**, read in New York on Tue 27 | SUN 25 is empty. MON 26: "10:30 Done: water the plants", "00:40 Mobility, 35 min", "04:30 Note: seat 14C, no sleep". TODAY: "06:55 Added 2 tasks". All times are in the current zone, so 10:30 sits above 00:40. That's correct: no zone tag and no "Travel day". | DL11 to DL13, DL57 |
| **The fall-back night**, read in Los Angeles | WED 28 TO FRI 30 is empty. SAT 31: "20:00 Cooked dal tadka, 50 min", "00:50 Push Day B, 90 min. Bench 82.5 × 8.", then two separate "01:30" lines in instant order. **TODAY** stands alone with no line under it. | DL14 to DL16, DL49 |
| **The Rest day row** | First row of the day, **no time**, "Rest day" at 21/400 in `inkSecondary`. No dab, no stroke. | DL31, DL42, DL43 |
| **The faint row** | MON 12: "06:55 Pull Day A, 3 sets. Row 60 × 10." with the text in `inkSecondary`. | DL22, DL60, DL64 |
| **An untrained day** | WED 14: "12:40 Done: call the bank", "19:30 Cooked carbonara, 35 min". No plan line, no workout line, no Rest day. | DL51 |
| **The 6-line cap** | THU 8: six lines, then the tail "Also: 3 notes, ticked 4 on Lisbon packing." (no time, `inkSecondary`, wraps, opens nothing). **The tail appears only past the cap.** | DL30, DL41 |
| **Empty days and runs** | Labels at 45%, one row each, never a count:<br>- a single day: "TUE 13"<br>- a run: "WED 28 TO FRI 30", "FRI 9 TO SAT 10"<br>- a run across months: "SEP 29 TO OCT 2"<br>- **TODAY** alone with nothing under it<br>QA checks the 45% labels for contrast on Porcelain and the dark looks (16/700 isn't large text). | DL39, DL49 |
| **The first day** | "TODAY" in `ink` at the bottom, and under it "Your days write themselves here." (21/400, 55%). When the first record lands, it rises in under the date as the line fades (220ms). | DL50, DL67 |

## The rest of the page rows (pointers and the no-dab answers)
- **The ways in** (DL32, DL33): Review's link line "The week · **Day log** · Notes", and Home's day label ("Thursday afternoon"). Both are in `day-log-page.md`, with no dab or dot anywhere on either.
- **Back words** (DL34): ‹ TODAY or ‹ REVIEW on the page, by the way he came in (`day-seams.md` S3), ‹ DAY LOG on an object opened from a line (`back-word.md` row 23).
- **The month title** (DL35): "October", Title 44/500.
- **Date labels** (DL36): TODAY in `ink`, past days in `inkSecondary`.
- **The scrub numeral** (DL37): `day-log-page.md` ("SUN" over "11", "OCT" over "1–4").
- **VoiceOver** (DL38, DL39):
  - A line reads its time as a sentence and × as "by": "7:10 am, Push Day A, 52 minutes. Bench 82.5 by 8, PR."
  - A run reads "October 1 to 4, nothing logged".
  - The faint row reads exactly as its text, with no "unfinished" added.
- **A set taken back** (DL54): only the numbers change, as a value word (blur crossfade, 220ms). Nothing else moves.
- **Something taken back elsewhere** (DL55): "Dentist taken back." on Home fades its line out here (220ms), and it comes back on redo.
- **A destructive write elsewhere** (DL56): the undo line and its 10s UNDO stay where the change was made. The log draws the committed state at once and redraws if UNDO lands. **There's no UNDO key on this page.**
- **A Tess write** (DL58): her 2.8s cobalt wash sits **behind the text band** of the new line, as `no-dots.md` does for Home rows, then dries to the line's tier. There's no dab for it to land on.

## Never
Dabs or dots, a zone tag, a "travel" word, a seam at midnight, counts of empty days, red, italics, an UNDO key, two zones in one read. And DL40's words: "not finished", only, missed, behind, streak, should, again, late, great.

## Owners
- **Builder B** owns the page (`Features/DayLog/`).
- **Core** owns the fold, the day and the zone (`DayStory`, `DayLookup`), plus `DayLine.kind` and the running short form.
- **Research** owns the pack's P1 to P8 (the faint row, the Rest day row, no dabs, DL46's wording, DL3's fixture).
