# Day log v1: the acceptance states, drawn (Design item 14)

This sheet is for Builder B's Day log page. It's drawn to Research's `day-log-acceptance.md` (item 104) and adds the visual answer for each Page row there. `day-log-page.md` stands for entry, layout and the margin scrub, **with the changes below**.
- Board: `mockups/day-log-v1.png` (source `studies/day-log-v1.html`), Porcelain. It has four phones: late night, travel and the fall-back night, the rest day and the faint row, and the first day.
- Recording: `recordings/day-log-turnover.mp4`, the 04:00 turnover.

## Changes to `day-log-page.md`
1. **No dabs** (`no-dots.md`, Kaushik 8:07 PM). A line is the time, then the text. The text column moves from x 98 to **x 86** (64pt time column).
2. **The faint row replaces the faint dab.** Product's 7:34 call said "the faint dab carries it" for a workout never finished. With no dabs, **the line's text rests in `inkSecondary`**: "Pull Day A, 3 sets. Row 60 × 10." It adds no words ("not finished" stays out, per 7:34) and no mark (per 8:07). The minutes being absent already says it. Running today, the same line is in `ink` (DL58, DL60).
3. **Sets never break.** Put a no-break space either side of × ("82.5 × 8"), so a wrapped line never leaves "× 10" alone at the start of a line.
4. **Lines sort by instant.** The column never re-sorts by its text.

## The states (acceptance Page rows)
| State | Drawing | Checks |
|---|---|---|
| **Late night** (now Thu 22 00:45) | The block is still **TODAY** in `ink`. Its lines run "19:05 Added 2 tasks", "23:20 Push Day B, 5 sets" (running, `ink`), "00:31 Note: hotel ideas". Times after midnight print as they are, with no seam and no "after midnight" words. | DL3, DL45 |
| **The 04:00 turnover** | 1. The label crossfades **TODAY → WED 21** in place (blur crossfade, 220ms, and it turns from `ink` to `inkSecondary`). Nothing moves. 2. 260ms later the window eases up 64pt (420ms, house curve) and a new empty **TODAY** rises 10pt into the gap (360ms). No sound, no haptic, no line about the hour. | DL46 |
| **Travel** (read in New York) | MON 26: "10:30 Done: water the plants", "00:40 Mobility, 35 min", "04:30 Note: seat 14C, no sleep". Times are in the current zone and sorted by instant, so 10:30 sits above 00:40. That's right, and there's no zone tag and no "Travel day". | DL11 to DL13, DL57 |
| **Fall-back night** | SAT 31: two lines both at "01:30" ("Note: hall light out", "Done: bins"), as two rows in instant order. The workout reads "90 min". | DL14 to DL16 |
| **The "Rest day" row** | The first row of the day, **no time**, text "Rest day" at 21/400 in `inkSecondary`. Other lines follow as usual. No dab, no stroke. | DL31, DL42, DL43 |
| **The faint row** | A past unfinished workout: text in `inkSecondary` ("Pull Day A, 3 sets. Row 60 × 10."). The time keeps its usual tier. | DL22, DL60, DL64 |
| **The "Also:" tail** | No time, text at 70% ink, wrapping. Opens nothing. | DL30 |
| **Empty runs** | "TUE 27 TO FRI 30" in labels at 45%, one row. A single empty day: "THU 8". | DL49 |
| **The first day** | "TODAY" in `ink` at the bottom, and under it "Your days write themselves here." at 21/400 and 55%. When the first record lands, it rises in under the date as the line fades (220ms). | DL50, DL67 |

## Never
Dabs, a zone tag, a "travel" word, a seam at midnight, counts of empty days, red, "not finished".

## Owners
Everything here is Builder B's (`Features/DayLog/`). The fold, the day and the zone are Core's (`DayStory`), per the acceptance pack.
