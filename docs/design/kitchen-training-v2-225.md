# 225 Kitchen and Training v2 (Oct 23, 4:25 PM PT)

Board: https://claude.ai/artifact/6YgzmLzwoRCZwaDrjJ67yq. This answers Kaushik's 4:09 PM feedback: Kitchen better organized and more fun, Recipes smaller, cook mode focus, a better Pantry graphic, display options, and a more fun Training room. It follows 224 (fixed slots, one action word bottom left, Tess bottom right, no door rows) and the 4:16 PM ruling (no back word; the left edge goes Home). Lintels and accents follow 218, Kitchen A8701F / C49A5E and Training A8203F / CC4478 (dark moved from D04A6A, see fixes). Each display is a pick for him; the first option is the default until he picks.

## Shared frame
- Lintel 150 pt at the top, then the brief: a right-aligned two-line sentence in a fixed 60 pt slot (23 pt, 30 pt lines), with the keyword at 600 x1.12 in the accent. The brief uses 224 short forms.
- Doors are titles (28 pt, 600) with a fixed-width count at the right (15 pt, ink 2). Under each is a display with a fixed height; nothing inside it wraps beyond its slot.
- Foot: the action word bottom left (20 pt, 600, accent), Tess bottom right.

## Kitchen
- Lintel: the week's dinners as a pixel skyline, one building per night with tonight's lit by a glint. While cooking, pixel steam rises from tonight's building (Reduce Motion: none).
- Brief: "Tacos tonight, start at 6:05. Lemon is short."
- Pantry (104 pt display), count "2 out, 5 low". Options:
  - Mounds (default): one dither-density pixel mound per place, as dense as it's stocked, with the place name under it. This is the 221 lintel grammar, small.
  - Weighted words: the place names in one line, weighted by fullness (600 ink, 500 ink 2, 300 ink 3), then "Lemons and limes are out." and "Eggs, cheddar and pasta are low."
  - Punch card: one row per place, with the name at left; each thing is a 3 x 4 tile punch. A stocked thing is accent, a low thing is half ink 3, an out thing is an empty edge-tint punch.
- Recipes (104 pt). Options:
  - Week strip (default): the kit's word strip, today in the middle at 22 pt with its dinner under it, and neighbours at 16 pt in ink 3. Drag for the week; it snaps in 0.32 s.
  - Can cook now: the recipes you can make from what's home as one 2-line sentence; the ones a thing short are in ink 3, with one line naming the gap ("Pancakes is one short, milk.").
  - Tonight, then: "Tonight" then the dinner at 36 pt in the accent, then "Then pasta on Thursday, out on Saturday." and "Sunday is open."
- To get (56 pt), count "4 things": "Lemon, limes, milk, tortillas." and "On the way home, for tacos."
- Foot: Cook (or "Plan tonight" when nothing is planned).
- While cooking, the room becomes the stove:
  - The brief is "Tacos, step 3 of 7. Eat at 6:45."
  - The current step hangs from the kit's thread at 32 pt (two lines fixed), with the next two steps in ink 3 under it.
  - The timer is Outfit 200 at 64 pt with "left on the pan", and it is the thumb arc's number.
  - Pantry, Recipes and To get leave; the foot is Next step.

## Training
- Lintel: the 12-week ridge of the opening lift (218), with a glint on the best week.
- Brief: "Push A today, about 45 min. Bench opens at 185." The 185 is a pressed number: drag up or down in steps of 5 lb (VoiceOver adjustable).
- Session display (180 pt). Options:
  - The plates (default): the barbell in whole tiles, loaded for the opening weight, biggest plate innermost (45, 35, 25, 10, 5, 2.5 per side on a 45 bar). Plates of 25 and up are accent; smaller ones are accent mixed 45% to the page. Plates slide on in 110 ms steps and reload when the number changes. Under it: "Each side: 45, 25."
  - Muscle map: the approved Oct 18 figure in 6 pt tiles. Today's muscles are accent, earlier this week accent mixed 40%, rested is edge. Three coloured words at right serve as the key (Today, Earlier this week, Rested); there is no legend box. Under it: "Chest, shoulders and triceps today." This shows presence only, never a heat scale.
  - Set ladder: each lift on a 44 pt row with its scheme ("3 x 5") and its set rings (ink ring when done, edge ring when not). Under it: "Bench, then overhead, dips and fly."
- Then "Last time 185 for 5. Try 190?" (190 is a pressed number).
- Bests (56 pt), count "4 in 12 weeks": "Bench 205, three weeks ago." and "Overhead is 5 lb from a best."
- The week as set marks, M to S: an ink ring for a done day, an accent ring for today, an edge ring for a day ahead. Rings only, never filled.
- Foot: Start Push A.

## Privacy
- A private workout reads "Private workout" off the phone. Lifts and weights never reach widgets or the Lock Screen.
- Pantry items and recipes have no amounts in the brief.
- Short forms come from the on-device model only (224).

## Reviewer fixes (coordinator relay, 4:20 PM)
1. Skyline: every building stands the same height. Only the roofline shape varies (dome, tower top, flat with corners, gable, round, chimney, wave), within a band of 0.34 of the lintel span above a common 0.42 base, plus tonight's lit glint. Height never stands for a quantity.
2. Cook mode: the timer takes the sentence slot, right-aligned: "left on the pan" (17 pt, ink 2) and the time in Outfit 200 at 56 pt on a 60 pt line. "Tacos, step 3 of 7. Eat at 6:45." moves to the top of the thread as one fixed row. There is no thumb arc in cook mode; Next step holds the bottom left.
3. Private items (coordinator's ruling): inside the room they read normally. Masking applies outside it, including any brief that surfaces on Home and in Tess lines.
4. Muscle map uses a solid "earlier this week" tint: C87586 light and 7A2948 dark. Flat 2D only. Steam tiles are one solid tint (C9C3BA light, 5A5650 dark), and each tile appears and vanishes in a whole step.
5. Crimson dark: D04A6A is 11.1 from FF4A33 but only 8.5 from E5341C, so it fails. The new Training dark is CC4478: 13.5 from FF4A33, 11.0 from E5341C, 18.8 from Routines dark D79AA6, and at least 21 from every other dark accent. It has 4.67:1 contrast on black. Light A8203F is unchanged.
