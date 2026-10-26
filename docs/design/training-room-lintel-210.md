# 210 The Training room: the mosaic becomes a lintel (Oct 23, 11:40 AM PT)

Board: https://claude.ai/artifact/WqsDGCX3gdjG84xK4eG3Wa. Where the 206 doorway lands for Training. On by default.

## 1 The lintel
- The Home mosaic comes through the doorway and settles as a full-width pixel strip at the top of the room, 176 pt tall, under "Home" (top left, ink2).
- It shows twelve weeks of the picked lift's best (e1RM from TrainingLedger, weekly max) as a pixel ridge: a smooth-stepped landscape, never bars or a chart. Grid 4 pt, tile 3.3 pt.
- The ridge's top row is full Training accent; below it the fill starts 42% toward the page and fades down in steps. A few sparse pale tiles float just above the ridge.
- The bottom edge blends into the page over 9 rows in 1/16 Bayer steps (same idea as 202 Rev 3), never a hard line.
- On arrival, the column of the best week glints once (toward ink, 700 ms).

## 2 The page
- Under the lintel, right-aligned: the best line, "Bench best 205 lb, three weeks ago" (Outfit light number, words in ink2). Say "best", never "record".
- The sentence, right-aligned at 23 pt: "Push A tonight, / bench first, / at 6:15 pm." with the session name as the 205 keyword (600, 1.12x, accent underline).
- One plain line per lift: name left, "3 x 5 at 185 lb" right, and under it one ink ring per set (done sets in Training accent at 1.6 pt, the rest in the edge colour at 1.3 pt). Rings are never filled.
- "Start Push A" at the bottom, plain accent words.

## 3 Behaviour
- Tap a lift: it takes the accent and weight; the ridge re-forms for that lift column by column from left to right (9 ms per column, 260 ms per column, tiles shrink and regrow as they flip), then the best week glints. The best line changes with it. Tap the same lift again to return to the lead lift.
- Start: the ridge flattens into a level line with a slow ripple (the live-workout pulse); the sentence becomes the current set ("Bench, set 3 of 3, 185 lb for 5."); the button reads "End". This hands off to the existing live workout mode.
- Home: the lintel folds back into the Home mosaic (206 doorway in reverse).
- One light haptic on a lift pick; none on the morph.
- Reduce Motion: the ridge swaps plainly, no glint, no ripple.

## 4 Other apps (pattern for later sheets)
Every app's room gets a lintel in its accent: Kitchen a skyline of the week's dishes, Routines the day's hours as a tide line, Notes the latest page as written rows, Lists what is left as a falling line. Money's lintel shows shapes only, never amounts.

## 5 Privacy
- Private workouts: the room reads normally, but the Lock Screen and widgets show "Private workout" and no lifts. The lintel never appears in widgets for a private session.
- No health or body data in the lintel (lifting history only).

## Owners
- A: the lintel view (MosaicView in a strip mode), the morph, the room layout, the Start hand-off.
- Core: a TrainingLedger query for 12 weekly bests per exercise and the best week index.

## Reviewer guards
- The ridge must not read as bars or a chart: no axes, no labels, no gaps between columns.
- No filled set marks. "best", never "record".
- Fill stays light (42% toward the page at the top of the fill); no heavy colour.

## Reviewer conditions (coordinator relay, 11:33 AM)
1. No chart furniture: no axes, gridlines, tick labels, value labels or per-week bars. The one plain best line under the ridge carries its meaning. The Bayer edge reads as texture, never as stepped bars.
2. "best", never "record". Set marks stay ink rings. Fill stays light.
3. Coordinator ruling (11:33 AM): inside the Training room a private workout reads normally (section 5). Masking with ObjectPrivacy.shownLabel ("Private workout") applies on the Lock Screen, widgets, Tess and Claude lines, and backups; its ridge data never reaches any of those. e1RM is lifting data, not body data.
4. Reduce Motion: the re-form, the flatten and the fold-back home are all plain swaps.
5. The fill fades in whole-tile colour steps (each tile one solid colour), never an alpha ramp.

## Ruling: no back word (coordinator, Oct 23, 4:16 PM)
Kaushik asked why there is a back word at all. Rooms and Today show no "< Home" or "Home" word at the top. To go back, swipe from the left edge, which plays the doorway in reverse; VoiceOver escape also works. The space the word used goes to the lintel.
