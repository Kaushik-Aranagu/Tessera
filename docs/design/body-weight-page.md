# The Body weight page, redrawn (Design item 29)

> **The ask (item 35):** the waiting weigh-in follows `one-ask.md`: the ghost reads "Body weight **82.4** kg" with no question mark, and Tess asks "82.4 kg as today's weight?" with KEEP · NOT NOW (replacing T1's "Tap to keep it."). Tapping the ghost still keeps it.

`body-weight-and-habits.md` §1, redrawn under today's rules: the page top (`day-seams.md` S4), one context line directly above the hero (`sweep-19.md`), nothing coloured at rest (`no-dots.md`), and Tess beside the soul (S1). Copy is Research's `m3-lines.md` §1 to §3 (master), units come from settings, and D12 follows Product's live-workout rule. Where this sheet and §1 differ, this sheet wins; §1 carries a pointer.
- Board: `mockups/body-weight.png` (source `studies/body-weight.html`). It shows the page from Training in kg, a bare "82.4" waiting, the page from Review in lb in Obsidian just after a keep, and "82.4" said mid-workout.
- Recording: `recordings/body-weight.mp4` (12s, 60fps). "82.4" waits as a ghost. A tap dries it, the dab drops onto the stroke and the trend rolls from 78.2 to 78.4. Then UNDO takes it back.

## The page
| y | Element |
|---|---|
| 58 | The back word: **‹ TRAINING** from the BODY WEIGHT link word, or **‹ REVIEW** from Review's weight line (`back-word.md` row 25). "bw trend" asked of Tess opens it with ‹ TODAY (row 29) |
| 84 | **Body weight**, Title 44 (S4) |
| 150 | **The context line**, in `context`, up to 2 lines: "78.1 yesterday, 0.3 kg less than last week" (B4 to B10). It's the one line directly above the hero, so it's the page's context line |
| 212 | **The trend** as the hero: Numeral 80 Light, tabular, one decimal, with the unit at 21 on its baseline |
| 304 | **TREND** in labels |
| 330 → 560 | **The stroke:** the trend, Sep 3 to today, a 4pt line in `ink` at 55%. The entries are small marks (8×6) at the rest tint. **Nothing is sage at rest.** An entry outside the range (the 87.4 typo) is pinned at the top edge, with its value in labels beside it. It's never red |
| 572 | "SEP 3" on the left and **TODAY** on the right, in labels |
| 612 | **The change line** in Body 21 **`inkSecondary`** (it sits under the hero, so it isn't the context line): "1.2 kg less since Sep 3" (B11 to B13) |
| 652 | **The ghost**, when a weight waits (below) |
| 736 → 820 | Tess's band. Nothing on the page reaches it |

**Copy:** `m3-lines.md` B1 to B16 and T1 to T16 as written. Past tense and digits, the unit once per line, "less" or "more", no goal, no colour for direction, no praise.

**Empty (B1):** the page keeps its frame (‹ TRAINING, Body weight). "No weigh-ins yet." sits at y 150 in `inkSecondary` (`empty-states.md`: quiet lines rest in `inkSecondary`, not `context`), with the writing line at y 198 and its placeholder "bw 78.4". There's no hero, no TREND, no stroke, and Tess says nothing. One entry shows the hero and one mark over TODAY (B2), and the stroke comes with a second day.

## A weigh-in on the page
- **A bare "82.4"** (30 to 250 kg, nothing running) closes Tess's Write and waits on this page:
  - The ghost line sets in at y 652: "Body weight **82.4** kg?" at Title 34 in wet cobalt, breathing (0.5 to 0.66), with the number as a 600 value word. It drops 8pt with a 3pt blur clearing on the settle spring (420ms).
  - When it's more than 3 kg off the trend, "4.2 KG ABOVE TREND" sits under it in labels at 700 (T2).
  - A wet cobalt mark waits 20pt above today's place on the stroke. Tess says "Tap to keep it." beside the soul (T1).
- **Tap the ghost:**
  1. The words dry from cobalt into ink, left to right (700ms), as every ghost does.
  2. The ghost lifts away (320ms). The mark drops 20pt onto the stroke (settle spring, 420ms) in `health`, wet, and dries to the rest tint over `Theme.Motion.dry`. That's the one moment of colour.
  3. The stroke's last stretch draws to the new trend (500ms, house curve), capped at 2 kg a step, so 78.2 becomes 78.4. The numeral rolls. The context line swaps through a blur to "82.4 this morning, 4.2 above trend", and the change line updates.
  4. Tess says "Body weight logged. 82.4 kg, 4.2 above trend." with **UNDO** under it (T4), or "Body weight logged. 82.4 kg." within 3 kg (T3). `.impact(.light)` on the landing.
- **UNDO** says "Body weight taken back." The mark drains, the stroke and numeral roll back, and nothing comes back as a ghost.
- **Tap the value word** to open the weight reel at 82.4 (0.1 kg detents) and fix a typo before keeping. **Swipe the ghost away** to drop it. Nothing is written and Tess says nothing (T5).
- The first, second, same-day, after-a-gap and past-entry lines are T7 to T12 as written.
- From Today, the same weigh-in waits as the first row of Next instead (`m3-entry-points.md`).

## Units from settings
- The page reads the unit from the settings object (`SettingsStore`), the same place Training's weights will read it. Until Core adds the unit field (Settings' UNITS is plain text for now), it's kg.
- **In lb,** every number on the page and every Tess line converts with one decimal: the trend "172.8 lb", the context line "181.7 this morning, 9.3 above trend", the change line "2.2 lb less since Sep 3", and Tess "Body weight logged. 181.7 lb, 9.3 above trend." The "above trend" threshold stays 3 kg (6.6 lb). The bare-number range becomes 66 to 550 (D11).
- Entries are stored in kg as written, so switching units never changes a stored value; only what's shown.
- The axis and the stroke don't change shape between units. Only the numbers do.

## In a workout: D12
Product's standing rule (7:24 PM S701, kept at 7:34 PM) decides it:
- **Only "bw 82.4" or "weighed 82.4" logs body weight mid-workout.** It logs as T13, with Tess's line beside the soul, and the set screen doesn't change.
- **A bare number mid-workout is never a weigh-in.** It goes through the live-workout guard, like any other number said or written during a set. The guard decides what it becomes (reps from 1 to 50, a set, an ask, or the model), and Q10 holds: no yes/no asks.
- **One place the guard can land,** drawn on the board's fourth phone: "82.4" close to the last weight comes back as a set ghost snapped to the nearest loadable weight, "**82.5** kg × 8" in wet cobalt with "SNAPPED FROM 82.4" in labels under it. A tap keeps it ("Set 4 logged. 82.5 × 8.", T14) and a swipe drops it. It's an example of the guard's look, not a rule this page sets.

## Owners
- **Builder A:** the page (`Features/Training/BodyWeight…`): the S4 top, the context line, the stroke and marks in ink at rest, the ghost and its keep at y 652, units from settings, the empty state, and the set ghost's look and SNAPPED label wherever the guard lands on a set. This replaces the DEBUG-only page.
- **Core:** the unit read from `SettingsStore` (with kg until the field exists), the lb conversion and the 66 to 550 range (D11), D12: a bare number mid-workout goes through the live-workout guard and is never a weigh-in; only "bw" or "weighed" logs body weight, and the BODY WEIGHT link word's and Review weight line's destinations.
- **Builder B:** Review's weight line opens this page with ‹ REVIEW.
