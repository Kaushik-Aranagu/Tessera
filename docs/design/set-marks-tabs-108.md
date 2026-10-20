# Set marks, the how-it-is-done sheet, the profile and one tab pattern (Design item 108)

Kaushik, 4:22 PM and 4:24 PM PT Oct 19. He dislikes the wave that counts sets, wants marks that carry more than a wave (reps, maybe weight) while only giving a sense of how much, exact numbers on a tap, a long press that shows how the exercise is done, calories adjusted to a profile, and tabs that put the current tab in the middle with neighbours smaller at the sides and no scrolling inside a tab. He picked "Own drawings" for the clips (coordinator, 4:28 PM): our own animations in the muscle-figure style, no third-party clips. Spec only until he picks the mark and the neighbour look.

Boards (source `studies/set-marks-tabs-108.html`, needs `studies/muscle-figure.js`, Porcelain):
- `mockups/set-marks-108.png`: marks A, B, C, each shown planned, mid-workout and done.
- `mockups/long-press-and-you-108.png`: the long-press sheet and the profile page.
- `mockups/tabs-108.png`: the tab pattern at rest, mid-swipe (crisp), mid-swipe (blurred variant), Muscles, How.
- `mockups/tabs-zones-108.png`: the swipe zones, and the same pattern in Settings > Review.

## 1. Set marks (replace the wave)
One mark per set, drawn in the routine's colour, reps and weight told by shape, never by a number.
- A, Tally: one tick per rep, tick height is the weight. Countable.
- B, Bars (RECOMMENDED): one bar per set, length is the reps, thickness is the weight. Reads as a quick sense of how much; the heaviest set of the exercise today is the thickest.
- C, Blocks: a column per set that grows a block per rep, wider when heavier.
Rules for all three:
- Planned sets are hairlines at the planned size (ink 25%). The set in progress is half drawn with the live seam colour at its end. A logged set fills with the routine colour. Over the target, the mark runs past the planned hairline; under, it stops short. No red, no check marks.
- No numbers in the mark. Tap a mark: its exact value shows in the detail line under the row as "82.5 x 8" (a lone line in `inkSecondary`, 16), and the mark rises 2 pt. Tap again or tap elsewhere to clear.
- Where marks live: the Training row (replacing the dashed strokes), live mode (replacing the wave), the exercise History tab (one row of marks per session).
- One haptic per logged set, as now. Reduce Motion: the mark appears filled with a 150 ms crossfade, no growth.
- VoiceOver: each mark reads "Set 2, 8 reps, 82.5 kilograms". A private workout shows marks without any values.
- Scale: row marks are 22 pt tall; live marks are 40 pt tall and span the width of the page.

## 2. The long press: how it is done
Long press on an exercise (row, live name or exercise page title) opens a glass sheet from the top with the page behind.
- Our own animation, in the approved muscle-figure style, sits first: a looping figure moving through the lift, the working muscles tinted. One animation per movement pattern (press, row, pull, squat, hinge, curl, raise, carry, core), tinted per exercise, not 72 separate drawings, unless Research and Core find a clean clip source. No slot for third-party clips.
- Under it: one cue in a plain line ("Elbows at 45 degrees, bar to the lower chest"), the kit (our own drawing of the bar, rack, bench, machine or dumbbell, nine pieces), the figure pair, and an estimate of calories for the planned sets.
- The calorie line is an estimate computed on the phone from the profile (below), worded "about 90 kcal for today's sets". If there is no profile yet the line is absent and a plain line asks for it. Research owns the equipment and MET library (batch 11), Product owns the calorie ruling. Health values never leave the phone.
- Reduce Motion: the animation holds on its mid frame; a tap steps frames.

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
1. A `SetMark` view with three styles behind `training.marks` (Bars default after his pick). Replace the wave in live mode, the Training row strokes and History.
2. Adopt Builder B's shared `PeekTabs` and `PageTurn` components for the exercise page (History, Rep maxes, Muscles, How) with no scrolling per tab; the Muscles tab shows the big figure pair and every muscle with its role.
3. The long-press sheet (after Research's library lands in batch 11): shell and slots now, content later.
## Builder B brief
1. Use `PeekTabs` on Settings > Review (Looks and day, Workout, Connected, Shown) with the switches in pages of six.
2. Add `tabs.neighbours` to the review switches (Crisp default, Blurred).

## Never
A number in a mark. A wave. A third-party clip. Soft patches as a default. A scroll inside a tab. Calories or weight anywhere but on the phone.
