# Live modes (Sheets 321 and on)

His 2:02 AM note (Oct 27): "we need do training mode (starting a workout and are doing the selected routine ... look
cooler and accurate and useful. Similarly cooking mode or shopping mode when getting groceries or something or
routines or such".

## The rule for every mode

A mode is the room's landing with each place given a live job. Nothing moves under a busy thumb: title top left,
band top right, keystone at 196, caption, sentence place, dial right, summary left, action word bottom left, Tess
bottom right. The dial holds the mode's steps, so they can be done in any order; the summary is the focused step's
ledger; the action word does the next thing with one tap, and the mode's end asks for a hold.

## Sheet 321: workout mode (Deck)

Reached by holding Start on the Deck.

| Place | Job in the mode |
|---|---|
| Title | The workout, "Push A" |
| Band | "12 min in", "3 of 5 lifts to go" |
| Keystone | The blackboard is the live set: the lift in chalk, its sets as "185×5" (the one you are on largest, done ones ticked), and the lifts along the bottom with ticks. During a rest: "Rest, then bench press", twelve chalk strokes for the rest, one wiped every ten seconds, and the time left in big chalk |
| Caption | "Drag the weight to change it"; at the end "Saved to the Deck, with every set" |
| Sentence place | "Set 2 of 3", 185 lb × 5 in the number face (unit at half size), "Bench press, 5 reps", "Last time 185 × 5, 5, 5". Drag up or down: 5 lb a step for the sets left, a light tick each step. During a rest: "Rest", the countdown rolling digit by digit, "Next, bench press, 185 lb × 5", "Tap to start now" |
| Dial | The lifts (Warm up, Bench, Press, Cable row, Triceps), each with the sets left. Turning picks the lift you do next |
| Summary | The focused lift's ledger: Set 1, Set 2, Set 3 with weight and reps; done in ink, the one you are on in the room colour, the rest slate; "Best 205, three weeks ago" |
| Action | Done (logs the set, starts the lift's rest, chalk dust falls); swipe for Rest (a rest now, or 30 s more), Lighter (10 lb off the sets left), Finish (hold). Undo 10 s on every log |
| Finish | Board: "Push A, done", minutes, sets and pounds, every lift ticked, any best. Sentence: "Finished, 41 min, 12 sets, about 9,795 lb". Done goes back to the Deck |

- Rests per lift: warm up 30 s, bench 2:30, press 2:00, row 1:30, triceps 1:00. When a lift's last set is logged, the
  dial turns itself to the next lift with sets left when the rest ends.
- Board check `t63.js` (paper and black): warm up, rest, auto-turn to Bench, drag weight, log, summary above the
  action, finish, no full stops, no page errors.
- For the builders: `WorkoutSession` (@Observable) holds lifts, sets done, phase (lift, rest, done) and rest end
  time; the Live Activity shows the rest countdown and the next set. The rest uses an end date, never a ticking
  counter, so it survives the lock screen. Workouts never go to Claude.

## Sheet 322: cooking mode and shopping mode (Galley)

Both start from the Galley's action word: Cook (Tacos, 25 min) and Shop (the list, aisle by aisle).

### Cooking

| Place | Job in the mode |
|---|---|
| Title, band | "Tacos"; "6 min in", "3 steps, about 19 min to eat" |
| Keystone | The ticket rail: the step you are on as the big ticket (its words, what it needs), and one ticket per pan timer that prints its time left. Several run side by side; a done timer reads "Ready" in wine. Tap a timer ticket to start it |
| Sentence place | "Step 2 of 5, 2:47 left", the step in a few words big enough to read from the stove ("Brown the chicken"), how ("Cumin and salt, leave it be"), and what's next or that Tess will say when. The whole place is a tap target for Next, so a knuckle works |
| Dial | The steps (Char, Brown, Soften, Brighten, Serve) with a running timer's time beside its name |
| Summary | The focused step's ingredients as a ledger (Chicken thighs 1 lb, Cumin 2 tsp), then its pan time |
| Action | Next (marks the step done, turns to the next, starts its timer); swipe for Timer (start, or 1 min more), Read (Tess says the step), Finish (hold). Undo 10 s |

### Shopping

| Place | Job in the mode |
|---|---|
| Title, band | "Groceries"; "7 of 11 to get", "4 aisles to go" |
| Keystone | The rail: the aisle you are in as a long receipt with what is left in it, and the Tonight ticket (what is for the tacos) |
| Sentence place | "Dairy, 2 of 4", the next thing big with its amount in the number face ("Milk 1 gal"), why it is on the list ("You are low", "For the tacos tonight"), and what comes after it in the aisle. Tap when it is in the basket |
| Dial | The aisles in store order with the count left in each |
| Summary | That aisle's list with amounts; got ones fade to ink2 |
| Action | Got; swipe for Not here (moves it to the end), Swap (Tess suggests one close), Pay (hold: everything bought goes into the Pantry) |

- Board check `t64.js` (paper and black): step 1 whole, Next starts the Brown timer, the summary is the step and
  stays above the action, shopping takes produce off and turns to Dairy, no full stops, no page errors.
- For the builders: timers are end dates (`Date`), shown with `Text(timerInterval:)`; the Live Activity holds the
  soonest timer. Aisle order is a field on each pantry place; the store order is learned from the order you tap Got.

## Sheet 323: routine mode (Watch)

Reached by holding Begin on the Watch ("the evening, 5 steps"). The woodland stays as the keystone, untouched (the
scene is locked); the mode lives in the places around it.

| Place | Job in the mode |
|---|---|
| Title, band | "Evening"; "1 of 5 tended", "about 32 min to bed" |
| Keystone | The woodland, as on the landing |
| Caption | "Tap the step when it is done" |
| Sentence place | One move at a time at an unhurried pace: "Stretch, 2 of 5", "Hips" big in the Watch colour, the cue ("Knee over ankle, breathe out"), and a soft countdown in the number face that rolls digit by digit ("1:58, then back"). Lines grow up from the ground the way the Watch's summary does. When a move's time runs out the next move comes by itself; a tap moves on early |
| Dial | The evening's steps (Tidy, Stretch, Read, Journal, Lights) with their minutes; a tended one turns green, one left for tomorrow turns slate |
| Summary | The focused step's moves with their times; done moves green, the one you are on in the Watch colour |
| Action | Next; swipe for Pause, Not tonight (skips the step; the streak is kept and nothing is lost), Finish (hold). Undo 10 s |
| Finish | "Tended, 5 of 5 steps", "Six days in a row now" |

- Board check `t65.js` (paper and black): opens on Tidy, tending Tidy turns to Stretch, the countdown runs, the next
  move comes by itself, no full stops, no page errors.
- For the builders: `RoutineSession` (@Observable) with step and move end dates; the Live Activity shows the move
  and its time left. Skipping never breaks a streak (the "nothing is lost" rule).

## Sheet 324: into a mode and back

The mode keeps every place, so the title does not fold away. Its letters change in place ("Deck" to "Push A",
"Galley" to "Tacos", "Watch" to "Evening"; shared letters slide, the rest leave up and rise in, sheet 309) and the Nav
word rises in beside it. Back runs the same morph the other way.

## Sheet 325: the modes, better designed and more useful (his 2:39 AM note)

"They don't feel as good or useful. I need them better designed and better fonts and better information."

**Type.** The sentence place is a scoreboard in every mode: an uppercase line in the room's face (16 pt, tracked)
with a quiet fact on its right edge, then the main thing at arm's-length size, then two lines of information.
- Deck: Barlow Condensed 96 pt numerals, "185 lb × 5", unit at a third.
- Galley: IBM Plex Sans Condensed bold 44 pt words ("Brown the chicken"), amounts in Outfit light.
- Watch: Figtree extra bold 44 pt for the move; the countdown in Outfit 22 pt rolls digit by digit.

**Workout, new information**
- **Plates on the bar.** The blackboard draws the bar with each side's plates to scale (45, 35, 25, 10, 5, 2.5 on
  a 45 lb bar) and writes "each side 45 + 25". Cable and machine lifts show the stack with the pin.
- **Last time, same set** ("Last time 185 × 5, now +5 lb").
- **Estimated max** (Epley, weight × (1 + reps / 30)) beside the best.
- **Felt: Easy, Right, Hard**, asked during the rest. Easy adds 5 lb to the sets left and Hard takes 5 off, with a
  receipt. The summary ledger keeps the word beside each logged set.
- **The band is the clock:** time in (0:12) and "Done about 7:22".
- **During the rest,** the board says what to load next ("then bench 185, each side 45 + 25").
- **Finish** compares with the last Push A in pounds moved.

**Cooking, new information**
- **The heat** for the step on the right of the top line ("Medium high, a spoon of oil").
- **A doneness cue** ("Turn it when it lets go of the pan").
- **A running timer** gets its own line ("2:47 left on the chicken"); Ready turns wine.
- **The big rail ticket is the next step** ("Get ready: Soften", with its ingredients), so you prep while this one
  cooks.
- **Timer tickets** print their time in Outfit 30 pt.

**Shopping, new information**
- **Where the aisle is** ("Right by the doors").
- **How to pick it** ("Pick ones that give a little", "The date furthest out is at the back").
- **What's next in the aisle.**
- **The Tacos ticket** strikes off tonight's things as they go in the basket.

**Routine:** the step's total minutes sit on the right of the top line. The move is big and the countdown reads at a
glance.

Checks t63, t64 and t65 are updated for the new structure and pass in paper and black.

For the builders: the scoreboard is one `ModeSentence` view with `title`, `trailing`, `main` (numerals or words) and
two info lines. Plate math is a pure function in TesseraCore (`plates(perSide:bar:inventory:)`) so the Live Activity
and the watch can share it.

## Sheet 326: the modes on the lock screen

A mode keeps going when the phone locks.

- **Dynamic Island:** the room's word on the left in the room's face (Bench, Chicken, Dairy, Hips) and the one
  number that counts on the right in Outfit, rolling digit by digit.
- **Live Activity:** three lines, as in the sentence place. The top line is in the room colour, lifted 38% toward
  white so it reads on the lock screen: "Rest, then bench", "Brown the chicken", "Dairy, the back wall", "Stretch, 2
  of 5". The middle line holds the big thing on the left (1:46, 2:44, Milk, Hips) and the next thing on the right
  ("185 lb × 5, each side 45 + 25", "Chicken, onions 6:00 after", "1 gal, then eggs, yogurt", "1:53, then back"). The
  bottom line is one quiet fact.
- **Privacy:** a private workout shows only "Rest", the time, and "Private workout". No lift, weight or set count
  reaches the lock screen.
- Board: Deck app list, "Lock screen, live"; tap the panel or the words under it to see each mode. Check `t66.js`
  finds no clipped line and no page errors.
- For the builders: ActivityKit `ContentState` per mode, with `Text(timerInterval:)` for every countdown so it runs
  while the app sleeps. Weights are training data, not body data; a workout marked private sends no lift names or
  weights to the activity.

## Sheets 327-329: the modes take the whole screen (his 2:59 AM note and his pick, 3:04 AM)

"All of them need improvement." He picked whole screen over keeping the landing places. Sheets 321-325 above are
superseded where they describe layout. Their information (plates, effort, heat, doneness, where and how to pick)
carries over.

**The shared rule.** For the length of a mode, the whole screen is the room's material, printed in the room's face.
- **Order on the screen:** it reads top to bottom: what this is, the one big thing, the facts that serve it.
- **The bottom third belongs to the thumb:** the verb bottom left in the room colour at 44 pt, and the steps (lifts,
  steps, aisles) down the right edge above Tess. Tap one to jump.
- **Gestures:** swipe up anywhere does the verb.
- **Top line:** the room's name top left goes back, and the clock or count sits top right.
- **Undo:** the receipt sits just above the thumb zone.

**327 Workout, the whole blackboard.**
- **Material:** slate texture full bleed, everything in chalk (Barlow Condensed). Big chalk keeps a fine edge (stroke
  capped at 2.4 pt) so it doesn't read as a sticker outline.
- **Top:** "Push A" in chalk blue, the clock and "done about 10:32", and "hold to finish" under it.
- **Middle:**
  - The lift.
  - The weight at 170 pt with "lb" and "× 5" in blue.
  - The bar with each side's plates to scale.
  - "Each side 45 + 25".
  - Sets 1-3, ticked with their felt word.
  - Last time and estimated max.
- **Rest:** the time at 178 pt, the chalk strokes wiping every ten seconds, what to load next, and "How did it feel:
  Easy, Right, Hard" at 40 pt.
- **Gestures:** drag the weight up or down; swipe across to change lift; swipe up to log, with the chalk dust falling.

**328 Cooking and shopping, the whole ticket.**
- **Material:** cream ticket paper full bleed under the rail and its clip, printed in IBM Plex Sans Condensed. It
  stays paper in the black look, like the real thing.
- **Cooking:**
  - "Tacos for 2".
  - The step number in Outfit at 104 pt, with the heat on its right ("Medium high, a spoon of oil").
  - The instruction at 46 pt, up to two lines, balanced.
  - How, then "Done when" and the cue.
  - "Needs" with dotted leaders to each amount.
  - "Timers", with a running timer in bold rolling Outfit; tap one to start it.
- **Shopping:**
  - The aisle and where it is.
  - The thing at 64 pt with its amount in Outfit.
  - Why it's on the list, and a Tip on how to pick it.
  - "In this aisle" with dotted leaders, got ones struck through.
  - "After this", with the next aisle and where it is.
  - The top line counts what's left and tonight's taco things.

**329 Routine, the whole evening.**
- **Material:** a dusk gradient that darkens with every step tended, so by Lights it's night.
- **The move:** the step and move count, the move in Figtree extra bold at 84 pt (shrinks to fit, never cut), and the
  cue in Newsreader italic (Tess's voice).
- **Breath guide:** "breathe in" and "breathe out" widen and narrow (4 s in, 6 s out). It's only words, so there's no
  ring.
- **Countdown:** the time left in Outfit at 96 pt, rolling and clipped. The step's moves are listed with their times.
- **Bottom:** Next, with "pause" and "not tonight" under it.

**Checks.** `t67.js` replaces t63-t65. In paper and black it checks:
- workout from the warm up, the rest, Easy adding 5 lb, and finish;
- cooking turns to Brown whole and starts its timer;
- shopping from limes to Dairy;
- routine from Tidy to Stretch;
- no cut line, no full stop, no page error.

For the builders: each mode is a full-screen cover over the room (`.fullScreenCover`), with no system chrome but the
status bar. The landing stays underneath, so Back is the room. The Live Activity (sheet 326) is unchanged.

## Sheet 330: a mode grows out of the keystone

Starting a mode opens the room's keystone to the whole screen. The blackboard, the ticket or the dusk sky grows
from the 354 x 182 slot at y 196 to full bleed in 560 ms, on a soft spring (cubic-bezier .22, .9, .24, 1). It
starts a touch brighter and settles. The thing you were looking at becomes the place you work in. The rest of the
landing steps back the usual way. With Reduce Motion it's a plain cut. For the builders: a `matchedGeometryEffect`
from the keystone to the cover's background, with content fading in after 200 ms.

## Sheet 331: plates slide on and off

When the weight changes (a drag, Easy or Hard, Lighter), the bar on the blackboard changes the way you would load it.
- A plate added drops onto the sleeve from about 54 pt above and settles.
- A plate taken off slides out past the end of the bar and fades, the way you strip it.
- The plates that stay don't move. Each move takes 320 ms with an ease-out.
- With Reduce Motion the bar just redraws.

For the builders: diff the per-side plate lists from the inside out; only the changed tail animates.

## Sheet 332: a pen stroke for Got it

On the shopping ticket, the thing you just got is struck through by a pen.
- The stroke is a single 1.6 pt line drawn left to right in 300 ms, at a slight angle (−0.6°), like a hand stroke.
- The words fade to 42% after the stroke has crossed them.
- Earlier got lines stay struck and quiet.
- With Reduce Motion the line is simply there.

For the builders: an overlay `Path` with `.trim(from:0,to:p)` animated on insert.

## Sheet 333: the printer feeds when a timer is done

When a pan timer reaches zero in cooking mode, the ticket printer feeds: the paper drops 30 pt, overshoots 4 pt and settles in five steps (a ticket rail, not a spring), with one short buzz.

- A line prints at the very top of the ticket in the alert red (#8C2F39), 20 pt bold caps, over a dashed tear line: "Chicken ready, off the heat". It names the food from the timer (`tn`), not the step.
- Tap the line to clear it. Doing the next step (swipe up or the verb) also clears it.
- Only one alert shows; a second timer that finishes replaces it and feeds again.
- The alert line is 28 pt tall and pushes the ticket down, so nothing overlaps.
- Test: t67 paper and black green; AL.png shows the fed ticket.

## Sheet 334: the ticket tears off when you pay

The last "Pay" in shopping mode tears the list off the rail instead of swapping it.

- The old ticket lifts away up and to the left (18 pt left, 70 pt up, 5° anticlockwise from its top-left corner) and fades out over 440 ms, easing in like a hand pulling it.
- The paid ticket then prints from the rail: it starts 40 pt up, overshoots 4 pt and settles in six steps over 560 ms, 220 ms after the tear starts, so the two never sit on top of each other for long.
- One short double buzz as it tears.
- Reduce Motion: no tear, the paid ticket simply replaces the list.
- Test: t67 paper and black green; ptr.js shows one torn copy mid-tear and none after.

## Sheet 335: Lights dims the room

The last routine step, Lights ("Phone away"), turns the screen down with it.

- Over that step's minute the dusk sky and the words dim together to 62% brightness, following the countdown (linear, 0.3 s between ticks so it never steps).
- The "Evening tended" screen stays at that dimmer level: the evening ends quiet, not with a bright screen.
- Every line stays readable at the dim level (checked in DM2.png); the verb and Undo keep their colour.
- Reduce Motion keeps the dimming (it is light, not motion).
- Test: t67 paper and black green; pdim.js reads --dim 0 on Tidy, 0.53 halfway through Lights, 1 when tended.

## Sheet 336: a new best is written in chalk

When a logged set's estimated max (Epley) beats the lift's best, the board says so during the rest.

- Top right of the rest screen, level with "Rest": "new best, est. 216 lb" in the accent chalk, 24 pt, written on left to right over 720 ms (a clip that widens, like a hand writing it). Reduce Motion: it is simply there.
- A longer buzz pattern than a normal log (6, 50, 6, 50, 12 ms), once.
- The line clears when the rest ends. A later set only writes it again if it beats the new best.
- The Done board lists what beat its best this session ("New best, bench est. 216 lb") or says "No new bests, steady work". It no longer shows a fixed line.
- Test: t67 paper and black green; ppr.js logs bench 185 × 5 (est. 216 over best 212) and reads S.pr 216, newBest 216.

## Sheet 337: Serve puts the ticket on the spike

The last "Serve" in cooking mode files the ticket away the way a kitchen does, then prints the summary.

- The finished ticket is pulled up into the rail clip: it narrows and flattens toward the clip (scale 0.18 wide, 0.06 tall, origin the clip at top centre), rises 24 pt and fades over 400 ms, easing in.
- 300 ms in, the "Eat" summary prints down out of the same rail, revealed top to bottom in eight steps over 620 ms.
- One short buzz (10 ms) as the ticket goes up.
- Reduce Motion: the summary simply replaces the ticket.
- This differs from the shopping tear (334) on purpose: a shopping list is torn off and thrown away, a cooked order is spiked.
- Test: t67 paper and black green; psp.js shows one spiked copy mid-way and none after, S.fin 1.

## Sheet 338: the rest is wiped off the board

When the rest ends (timer out, tap, or Start now), the board is wiped clean instead of swapped.

- The rest board stays as it was on the right of an eraser band. The band sweeps left to right across the whole board in 460 ms (ease in-out), slightly slanted (36 pt lean top to bottom). The next lift is already written behind it on the left.
- The band trails a faint chalk haze, 66 pt wide at 7% white, which fades out over the last fifth of the sweep.
- No sound, no buzz beyond the existing end-of-rest tick.
- Reduce Motion: no wipe, the next lift simply appears.
- On the phone: snapshot the rest layer into an image at end of rest and mask it with the moving band, so the live lift layer underneath keeps updating.
- Test: t67 paper and black green; pwp.js freezes the clock mid-wipe (WP1.png: next lift on the left, rest board on the right, haze at the edge).

## Sheet 339: "not here" shows where the item went

Tapping "not here, ask me later" in shopping mode moves the item to the end of its aisle, and the list shows the move instead of jumping.

- The rows of "In this aisle" slide up to their new places, 340 ms, cubic-bezier(.2,.8,.2,1) (FLIP from their old positions).
- The skipped row lifts out (hidden, 6 pt up) and settles into the last place once the others have moved, 440 ms, fading in over the second half. Rows never cross or overlap.
- The receipt line still says "Limes, later in this aisle" with no undo (it is not a loss).
- Reduce Motion: the list simply reorders.
- Test: t67 paper and black green; psk.js order goes Limes, Cilantro, Peppers to Cilantro, Peppers, Limes with three row animations.

## Sheet 340: holding writes "hold to finish" over

The workout's "hold to finish" (top right) now shows the hold as it happens.

- While the finger is down, the same words are written over in the accent chalk, left to right, across the 600 ms hold. Let go early or move more than 10 pt and the overwrite clears; the hold is cancelled.
- When it completes, the workout finishes as before (Done board). No bar, ring or extra mark: the words are the progress.
- Reduce Motion: the overwrite does not run; the hold still works.
- Test: t67 paper and black green; phd.js (HD1.png, halfway: "hold to" in accent, "finish" still chalk grey); phd2.js holds with a real pointer and reaches Done.
