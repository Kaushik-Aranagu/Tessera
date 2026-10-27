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
