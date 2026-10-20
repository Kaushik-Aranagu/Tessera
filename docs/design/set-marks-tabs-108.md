# Set marks, the how-it-is-done sheet, the profile and one tab pattern (Design item 108)

Kaushik, 4:22 PM and 4:24 PM PT Oct 19. He dislikes the wave that counts sets, wants marks that carry more than a wave (reps, maybe weight) while only giving a sense of how much, exact numbers on a tap, a long press that shows how the exercise is done, calories adjusted to a profile, and tabs that put the current tab in the middle with neighbours smaller at the sides and no scrolling inside a tab. He first picked own drawings for the clips, then dropped them and chose the free Workout Guide art (section 2). He has picked the neighbour look (blurred) and the set mark (ink drops, section 1).

Boards (source `studies/set-marks-tabs-108.html`, needs `studies/muscle-figure.js`, Porcelain):
- `mockups/set-marks-108.png`: marks A, B, C, each shown planned, mid-workout and done.
- `mockups/long-press-and-you-108.png`: the long-press sheet and the profile page.
- `mockups/tabs-108.png`: the tab pattern at rest, mid-swipe (crisp), mid-swipe (blurred variant), Muscles, How.
- `mockups/tabs-zones-108.png`: the swipe zones, and the same pattern in Settings > Review.

## 1. Set marks (replace the wave)
PICKED: Kaushik, 12:51 AM Oct 20 (his Oct 19 5:51 PM PT), "Yes, this" on the ink-drop swarm with brush circles (Design shapes and ink, Motion lab motion). Clip `clips/set-marks-ink-108-v6-motion.mp4`, source `studies/set-marks-ink-108-v6-motion.html` (earlier rounds: bars, rings, dots, swarm, ink v1 to v5 are dropped; his words: dots too circular, motion too robotic, an inside drop makes no sense).
The mark is a few tiny ink drops that move like liquid and draw each set as one brush circle:
- Drops: five, radius 3.5 to 5 pt on the 390 pt stage, close together, drawn as liquid (they merge and part), crisp edges, no soft patches. Each has its own spring (natural frequency 11 to 16 rad/s, damping 0.34 to 0.54) and its own smooth noise, so nothing shares a timer or a path. Idle: they drift in noise about 13 pt around their homes. Colour: ink 20,24,31; a drop in motion is warmer (wet ink 216,67,42 drying to ink in about 1.1 s).
- Each rep is a soft pull together (slow ease-in, about 58% of the rep) and a quicker release with overshoot. Rep time 0.30 s; the last two reps run longer (0.52 s and 0.74 s) and tremble (1.9 pt noise at about 22 Hz, each drop on its own phase).
- When the set is logged one drop draws a calligraphic brush circle (radius 48 on the stage, wet at the tip and dry behind, tapered ends): closed circle = on target; open circle = short (the gap is the missing reps); a circle that overlaps itself = more than planned; a flare of nine rays with a few splatter drops (flare colour 229,72,44) = best, never "record". A heavier set draws a thicker stroke (5 to 10 pt). The circle then flies to its row slot and shrinks to row size. The row copy is the plain brush circle: no fill, no inside drop, no soft wash.
- Rest: the drops are reborn and drift again.
- No numbers in the mark. Tap a circle: its exact line shows under the row in `inkSecondary`, 16 ("Set 3: 85 kg x 9"), and the circle rises 2 pt; tap again or elsewhere to clear.
- Where it lives: live mode (replacing the wave; the drops are the live mark and the circles collect under them), the Training row (the circles replace the dashed strokes, 22 pt tall), the exercise History tab (one row of circles per session).
- One haptic per logged set, at the moment the circle closes. Reduce Motion: no drops; the finished circle appears with a 150 ms crossfade. Low Power: three drops, no goo blur, 30 fps. (Motion lab writes the rows.)
- VoiceOver: each circle reads "Set 2, 8 reps, 82.5 kilograms". A private workout shows circles without any values.
- Switch: `training.marks` is dropped; the ink mark is the only mark. Never a wave.

## 2. The long press: how it is done
Long press on an exercise (row, live name or exercise page title) opens a sheet with the page behind. Kaushik dropped our drawn animations ("super bad") and chose the free Workout Guide line art (Everkinetic, CC BY-SA 4.0), built in #1140: three frames per exercise played 1, 2, 3, 2 with a 150 ms crossfade, drawn in the ink colour (template images), 240 pt high; Reduce Motion holds the middle frame. 15 of the 72 use a sibling motion. The picture source is swappable, so a richer set can go in front later.
- Under the picture, as empty slots until content lands: one cue in a plain line, the kit drawing, the figure pair and a calorie line (only with the Calories burned switch On).
- A sibling motion gets one quiet line "Similar motion" in `inkSecondary` (low, next PR).
- Credits are not on exercise pages. One plain About page at the foot of Settings carries one line per source (sheet 109).

## 3. The profile ("You")
Four sentences with values as words he can tap: weight, height, age, how he trains. Weight can come from Health (store only). Used for the calorie estimate only. Never in backups, op log, export, Claude payloads, logs or widgets (his 2:42 PM rule).

## 4. One tab pattern, app-wide
- The tab you are on sits in the middle at 21 pt, 600. Neighbours sit at the sides at 16 pt, ink 38%, crisp. A 28 x 5 ink bar sits under the current one. Mid-swipe the words slide, grow and darken into the middle while the page follows the finger.
- PICKED (Kaushik, 4:38 PM Oct 19, card): blurred neighbours (1.6 pt blur, dimmed), a deliberate exception to his Oct 17 12:46 PM no-soft-patches rule for tab words only. Review switch `tabs.neighbours` keeps Crisp as the other choice; default is Blurred. Under Reduce Transparency the blur drops to crisp dimmed.
- No scrolling inside a tab. Each tab fits one screen; if the content does not fit, it is split into more tabs by what groups naturally. Exercise tabs: History, Rep maxes, Muscles, How. Settings > Review: Looks and day, Workout, Kitchen, Connected, Shown (pages of six switches, each page named; Kitchen holds the cook timer voice, pantry state, CAN COOK shelf and hands-free cook rows).
- Swipe zones stay apart: above the tab row the middle swipe goes along the routine (next exercise); on the tab row and the page under it the swipe goes between tabs; the left edge (24 pt) goes back and the right edge (32 pt) goes in to what it knows, as in sheets 75 and 76.
- Reduce Motion: neighbours change by a 150 ms crossfade; the page cuts with the same crossfade.
- Accessibility: the tab row is a tab list; each tab reads its name and "2 of 4"; AX Dynamic Type stacks the neighbours off and shows only the current name with a "next: name" line.

## Product rulings folded in (decisions.md, 4:25 PM and 4:27 PM Oct 19)
- Marks: Product's words are height = reps, tone = load. Bars and Blocks keep reps as the long side; if Kaushik picks Bars, weight is carried by thickness and tone together (heavier sets draw darker) so both readings agree. Tap shows sets, reps and load.
- The calorie line shows only when the review switch "Calories burned" is On; the default is Off, so the sheet at rest has no calorie line.
- Profile ("Me"): weight (current), height, birth year, sex; every one optional, plain words, "That stays on this phone." It declares its side swipe like every screen.
- Clips: none. Our own short animation per exercise (start and end pose, 72 exercises, top lifts first) and 9 equipment drawings. Kaushik asked for one sample first: `clips/bench-press-sample-108.mp4`; the other 71 wait for his yes.

## Builder A brief
1. A `SetMark` view for the ink-drop swarm and brush circle (section 1, with Motion lab's v6 study as the reference for the spring values). Replace the wave in live mode, the Training row strokes and History. No `training.marks` switch.
2. Adopt Builder B's shared `PeekTabs` and `PageTurn` components for the exercise page (History, Rep maxes, Muscles, How) with no scrolling per tab; the Muscles tab shows the big figure pair and every muscle with its role.
3. The long-press sheet is #1140; add the "Similar motion" line for siblings.
## Builder B brief
1. Use `PeekTabs` on Settings > Review (Looks and day, Workout, Connected, Shown) with the switches in pages of six.
2. Add `tabs.neighbours` to the review switches (Blurred default, Crisp).

## Never
A number in a mark. A wave. A third-party clip. Soft patches as a default. A scroll inside a tab. Calories or weight anywhere but on the phone.
