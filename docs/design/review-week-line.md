# Review's week line with habits and weight (Design item 15)

This sheet is for Builder B's Review. It's drawn to Product's 8:07 PM call ("Review with habits and weight") and Research's `fixtures/review-m3.md`, with the habit threads from `no-dots.md`.
- One screen holds all three asks: the week line, a paused habit, and too few weigh-ins. The fixture is R10 with 2 weigh-ins added.
- Board: `mockups/review-week-line.png` (source `studies/review-week-line.html`), in Porcelain and Obsidian on the same week.
- Recording: `recordings/review-week-line.mp4`. It shows a Read check-in, then the third weigh-in bringing the weight clause into the week line.

## The page, top to bottom (y in pt)
| y | Element |
|---|---|
| 58 | **‹ HOME** |
| 146 | "the week so far": Body 21/400 in **`inkSecondary`** (not `context`: no resting colour on text, per the #241 review) |
| 180 | **Hero**, unchanged (Hero 56/500, `review-sentence.md`): "One session / this week" |
| 310 | **The week line**: Body 21/400 in `ink`, up to 2 lines, with 2 lines reserved so nothing below jumps. "Cook 3 of 4, Read 4 of 5." **Each clause holds together** (no-break spaces inside "Read 4 of 5" and "weight down 0.2 kg"), so a wrap falls only after a comma. With no clauses, there's no line, and the space closes up. |
| 382 | **Day dabs**, unchanged (`rest-dab.md`): trained dabs rest at the rest tint, with the rest stroke and the faint ring |
| 420 | **Day letters.** In a paused week, the open days (no dab, before today) set their letters to 58% of `inkSecondary`. That's the only sign of the pause in the dab row: no strike, no mark. |
| 470, 530, 590 | **Up to 3 habits**, 60pt each. The label is Label 16 `inkSecondary` ("COOK · 3 OF 4"), and 28pt under it is the **painted thread** (3pt rough stroke, the class pigment at the rest tint, consecutive days joined, a gap meaning nothing, future days blank). |
| 654 | **The weight line**: Body 21/400 in `inkSecondary`, "Weight 78.2 kg, 2 weigh-ins this week." With 0 weigh-ins this week there's no line. |
| 708 | **The link line**: "The week · Day log · Notes" (Body 21/600 ink, `HomeLinkLine`) |
| 744 | **SETTINGS** as a label word (item 16, `settings-place.md`) |

## The three cases
1. **The week line** follows Research's clause rules exactly:
   - Habits come first, rule habits before manual ones.
   - The weight clause comes last.
   - "down" and "up" are never coloured.
   - It's never the hero.
2. **A paused habit** (Gym):
   - It's left out of the week line.
   - Its label reads "GYM · PAUSED THIS WEEK".
   - A day ticked before the pause stays painted, per A7.
   - The paused week's open day letters dim.
   - VoiceOver: "Gym, paused this week. Tuesday done."
3. **Too few weigh-ins** (fewer than 3 days this week):
   - The week line has no weight clause.
   - The weight line still reads, with its count ("2 weigh-ins this week").
   - There's no nudge and no "not enough".

## The moments (recording)
- **A check-in:**
  1. Today's stretch of the Read thread paints on wet from the previous day (500ms, house curve), in full pigment.
  2. 300ms later, the count swaps like a value word in both places: "READ · 3 → 4 OF 5" and "Read 3 → 4 of 5" in the week line (blur crossfade, settle spring).
  3. Tess says "Read, 4 of 5 this week." once.
  4. The stretch dries to the rest tint over `Theme.Motion.dry`.
- **A target met** (G8, from `habits-first-use.md`): the count is ink at rest, always. Only in the moment the target is met does it take colour: "READ · 5 OF 5" swaps as above and the "5" blooms in the habit's pigment, then dries back to `inkSecondary` over `Theme.Motion.dry`. The week's painted thread gets the **brushstroke** behind it (6pt at the rest tint, Monday to today, 700ms), and that stroke is the lasting reward. No colour stays on the count, no `.success` haptic, no confetti. Tess says "Read done for the week." once.
- **The third weigh-in:**
  1. Tess says "Body weight logged. 78.1 kg."
  2. The weight line swaps to "Weight 78.1 kg, 3 weigh-ins this week."
  3. ", weight down 0.2 kg" fades into the week line (blur 4 → 0, 420ms). It wraps to the reserved second line if it needs to.
- **Reduce Motion:** crossfades only, and the stretch appears already dry.

## Never
Dots, a streak, red, "missed", a coloured count at rest, a nudge for weigh-ins, a coloured "down", a fourth habit on this page (it goes to the full Review and the Habits page).

## Owner
Builder B (`ReviewPage.swift`, `ReviewView.swift`). The week line clauses, the weigh-in count and the paused flag come from Core's ledgers.
