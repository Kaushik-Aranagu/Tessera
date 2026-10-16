# Home labels (build sheet for Builder B)

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

Every word on Home that does something, what it is in the ink-action language (`no-buttons.md`), and how it moves. The components exist since #108 (`PaintKey` as the stroke word, `InkLabelWordStyle` as the label word). This sheet is the per-label list. Recording: `recordings/home-labels.mp4` (source `studies/home-labels.html`):
- Start paints in, and a tap hands off to the workout.
- Resume, with a waiting ledger row and its RESUME label word.
- Finish is held to done, then the empty state's label word.

## The rules on Home
- **At most one stroke word per page:** the action of the moment. Everything else is a label word, a value word or a tappable hero.
- **Vermilion is for what runs:** Finish, Start, Resume and UNDO. Cobalt stays Tess's. No stroke on Home uses another colour.
- **A label word never carries an arrow** ("→"). The only arrow-like glyph in the app is the back word's "‹" (`back-word.md`).
- **Never `.textRole` on a stroke word's label.** `PaintKey` sets Title 34/500 itself.

## Every label
| Page | Word | Kind | Colour | Gesture | Meta beside it | File |
|---|---|---|---|---|---|---|
| Now, a task running | **Finish** | Stroke word | Vermilion | Hold 0.7s | "HOLD · 30 MIN LEFT" | `NowPage.swift:84` |
| Now, today's routine | **Start** | Stroke word | Vermilion | Tap | "5 EXERCISES" over "18 SETS" | `NowPage.swift:367` |
| Now, a workout running | **Resume** | Stroke word | Vermilion | Tap | "REST" over "1:22" (or "SET 2"), counting down | `NowPage.swift:400` |
| Now, the ledger (waiting processes) | **RESUME** | Label word, right-aligned on the row's first line | Vermilion | Tap. The whole row is the hit area; the word is the cue | none | `NowPage.swift:462` (now `Text("Resume")` in bodyStrong) |
| Now, nothing left | **LOOK BACK AT THE WEEK** | Label word, under "Nothing else is planned today." | Ink | Tap, zooms into the week | none | `NowPage.swift:115` (now "Look back at the week →") |
| Now, a proposal from Tess | The proposed row | Ghost row (wet cobalt dab, title, time label) | Cobalt | Tap to keep | its time as a label | `NowPage.swift:260-285`, unchanged |
| Training | **Start workout** / **Resume workout** | Stroke word | Vermilion | Tap | none | `TrainingPage.swift:85, 184`. Remove `.textRole(.bodyStrong)` at :186 |
| Training | **PLAN** | Label word | `inkSecondary` | Tap, opens the plan | none | `TrainingPage.swift:46, 145` (now "Plan →") |
| Today | TOMORROW / NEXT WEEK | Label word, revealed in the swipe track | Ink | Swipe left past it | none | `HomeQueue.swift:205-216`, unchanged |
| Kitchen | Groceries, Recipes | Tappable Title 34 words with their dab | Ink | Tap, zooms in | none | `HomeSpatialView.swift:203-218`, unchanged |
| Kitchen and Review | Paste a recipe, The week, Notes | Tappable words in a line, Body 21/600 | Ink | Tap, zooms in | none | `HomeLinkLine`, unchanged |
| Any page | Tess's UNDO | Label word | Vermilion | Tap | none | `BottomChrome.swift:134`, unchanged |
| Rail | REVIEW · TODAY · TRAINING · KITCHEN | Rail words with the carriage | Ink and secondary | Tap or swipe x | none | `PaintedRail`, unchanged |

## Motion
- **Arrival: the stroke paints in.** When the page settles, the word lands with the rest (rise 10pt, 360ms, house curve). Then its stroke paints in left to right under it (260ms, ease out), 80ms after the word lands. The meta fades in with the word. The stroke shouldn't be there before the word is.
- **Tap (Start, Resume, Start workout):** the stroke wets (scaleY 1.65 and back, 420ms) with `.selection`. Then the workout's dark ground rises from the bottom (420ms, house curve). Workout mode is a process, so it rises, never zooms.
- **Hold (Finish), as in `no-buttons.md`:**
  1. On touch-down the stroke empties to a 20% trace (140ms) with a light impact.
  2. It repaints left to right under the thumb over 0.7s, easing out.
  3. At the end, the tip blooms as a blot (scale 0.4 → 1.3 → 1, 260ms, settle spring), with `.impact(.medium, intensity: 0.8)`. That's the bloom from the #108 review, replacing the ×1.9 height.
  4. The hero strikes through (320ms), and Tess says "Done. Groceries for the week." with UNDO.
  5. Letting go early drains the paint back right to left (220ms).
- **Label words:** on touch, ink goes to full and a 1.5pt hairline draws under the word, left to right, 150ms. Then the action follows. `.selection` fires.
- **The time left under Finish** is the amber dry stroke on its own, draining from right to left. There's no track under it (audit row 7).
- **The ledger row:** a waiting process carries a 2pt vermilion seam over it, glowing at 45%. The title is 21/600, the step 18/400 secondary, and RESUME is on the right.
- **Reduce Motion:** strokes appear without painting in or wetting, and a hold fills with an opacity ramp. Haptics are unchanged.
