# Item 131: App landing pages, combined spec (Oct 22)

Single source for builders. Combines the six per-app landing picks (Training, Kitchen,
Money, Notes, Lists, Routines) after the Design fixes of Oct 22 08:25. Builds on
app-character-127 (A fixed grammar, B levers, E accents, F landing contents). Where a
per-app page and this sheet differ, this sheet wins; tell Design.

## 1. Shared rules (every landing)
- Frame: Back word top left, title, one subtitle sentence, page content, one action word at
  the foot. 22 pt gutter. Title tap opens the app's index. Pull-down never opens a menu.
- Contents, each shown only when it has something (no "nothing here" bands):
  1. The app's sentence (one or two short sentences, the key word in the accent).
  2. Running: ink word into focus mode on the same step (Pick up, Go on, Cook, Open).
  3. Waiting on you: at most three lines, never shaming, no counts of what was missed.
  4. New: at most three lines, since he last looked.
  5. Doors: plain ink words into the app's places, services and libraries.
- Order and form are the app's own (section 2). No two apps share a lead form.
- Words: Figtree, sentence case everywhere (no caps kickers or caps actions). Numbers:
  Outfit, 300 below 28 pt, 200 from 28 pt up. Fractions with the frac feature.
- Actions and doors are ink words. Only the one action word carries the accent underline.
  No grey action words.
- Never: cards, pills, button shapes, lines between rows, coloured or filled dots,
  middle-dot separators, "..." truncation, page-edge glow, blurred patches, red amounts,
  the word "record" (say "best").
- One accent per app (table E of 127). Cobalt and violet are Tess's only. No app uses
  another app's accent, including look-alikes (amber next to Kitchen ochre).
- Each app has exactly one allowed line kind (its signature line). No second line kind.
- Sentences are computed on the phone from fixed templates. Walled titles, money values
  and actions, health, body and calorie facts never reach Claude, logs, backups or widgets.
  (Send side superseded by Kaushik's Oct 27 11:59 AM ruling, docs/product/decisions.md; money tools are offered to Claude as they exist since his 12:28 PM Oct 27 card answer (today logSpend; the rest have no tool yet) (each change pending with 10 s Undo, "Reversed"; room agents have no money tools); the backup, log, widget and screen walls stay.)
- Motion only through MotionPolicy; Reduce Motion is a plain crossfade or appear.

## 2. Per app (v2, Kaushik's picks Oct 22 08:56 AM PDT; record artifact P5nUSTJ2ygJUvfABSDGet2)
APPROVED v2: Kaushik, Oct 22 11:19 AM PDT ("now these look all right, especially the layout"). Build now.
Modes: none for Training, Kitchen and Routines (his pick); none drawn for Money, Notes and
Lists (he chose none). No app has a mode in v2.

| App | Accent (dark / light) | Lead form (v2) | Numbers | Signature line |
|---|---|---|---|---|
| Training | hot red #EE6A4C / #C4472A | today's session in words, then the week as set marks | one, in the sentence; a band only inside a program | set marks |
| Kitchen | ochre #E0A458 / #A8701F | two large doors, Pantry and Recipes, each with its summary under it | only ones that answer (dinners covered, to get) | level line |
| Money | sage #8DBFA7 / #3F7A62 | one sentence, one total on the decimal line, the doors | one, the month so far | total rule |
| Notes | violet #B9A9E0 / #5B3FB8 | search-and-write line over the things field, then margin sentences | none | link underline |
| Lists | olive #B5BE7A / #5E6B1F | lists as lines that fill with ink; the lead list shows its items left as large words | left of total, small | the filling line |
| Routines | dusk rose #D79AA6 / #A4505F | the running step in large words, then one line per routine | plain counts, usual start and length (after 7 runs) | the Thread (in the runner) |

### Training (mix of A and C, no big number)
His note: the big number "is not that relevant, more like choosing the weight you're
working with". So the working weight never leads the landing.
- Sentence first, hot key word: "Push A today, about 45 min. Bench opens at 82.5."
  The one number lives inside it.
- Then the action: "Start Push A" (hot underline), place word Gym or Home on the right.
- Then the week as set marks (seven rings, done filled with ink, today open in hot).
- Inside a program only: the block band from C under the week: weeks as set marks
  ("Strength block, week 3 of 8"), the week's job in one line, and the block target.
- Doors: Plan, Library, Log, Stats as ink words, each with a short value word.

### Kitchen (mix of B and C; A becomes Cook mode)
His note: A is a cooking-mode layout; he likes B and C; ways into Pantry and Recipes are
a key part of the layout; the rest is summary.
- One sentence: "Tacos tonight, start at 6:05. Lemon is short."
- Pantry, as a large door word (title weight). Under it, from B: the level lines per place
  (Fridge, Freezer, Shelf, Counter), "2 use soon" and "7 to get", and, when it answers,
  "covers 4 dinners".
- Recipes, as a second large door word. Under it, from C: this week as plain rows, today
  in full ink with its start time, open days faint ("Open").
- While a cook runs, one line above both doors: "Cooking tacos, 8 min left. Go on" into
  Cook mode. A's time spine (now, start, eat) is drawn inside Cook mode, not here.
- Foot action: Cook (ochre underline) when a meal is planned today, else Plan a meal.

### Money (B, one sentence)
- Sentence of two or three short clauses: "Nothing is late. Rent is due Friday, and
  October is running a little under September." Trends are clauses, never figures.
- One total rule, then "October so far" with the total on the decimal line.
- Doors: Due, Spending, Bills, Saving, Cash, Owed. Payday and Trip pages sit behind
  their words, not on the landing.

### Notes (mix of A and C, no numbers)
His note: C's search or categories menu, made better, with A; B looks like a calendar.
- Top: one line that is both search and write: "Search or write. @ links a thing."
  Typing filters the things field below in place; Return writes a note.
- The things field (from C) is the categories menu: the things he writes about as words,
  size by how much he writes, no counts. Tap a word to open it; Loose and Private sit
  at the end of the field as quieter words.
- Under it, A's margin sentences: Running, Waiting, New, each one or two lines with an
  underlined link word ("Link them", "Make it a thing").
- No numbers anywhere on the page.

### Lists (mix of A and C)
- The lead list (the one due soonest or running) shows A's form: its next items left as
  large words ("Socks, underwear, charger, passport"), "6 left of 24" small, Resume.
- Every other list is C's line that fills: the list's name in large type, filled with
  ink from the left by the share done, one short line under it ("3 to get, new from
  Tacos"). The fill is the strike-and-count signature in one stroke.
- Doors: Shelf, Reusable, Picks, Runs.

### Routines (B, one step, no modes)
- While a routine runs: "Morning is running", the step in large words ("Shoes on"),
  "4 min on this step", Pick up (rose underline).
- Below: one line per routine with plain counts and its usual start and length:
  "Morning, 14 days, usually 6:40, 22 min". Counts show after 7 runs; nothing can fall
  (no streaks, no missed).
- Quiet day: the top is "Nothing is running" and the three most used routines as
  Start words.
- Browse at the foot opens the index.

## 2b. Keep every element feature (Kaushik, Oct 22 11:19 AM PDT)
His words: keep "whatever the other features we had earlier, like swipe the numbers up to
edit and all" while taking v2's layout, accents and soul. v2 changes the landing layout
only; it removes no interaction. Before replacing any screen, the builder lists the
gestures and behaviours of the screen being replaced and carries each one over. QA checks
the list. Known features that must survive (not exhaustive):
- Numbers are instruments: swipe a number up or down to step it (minutes value word, set
  weight and reps, servings drum, amount dial and shop total), tap to type.
- Unit swipe converts in place (kg and lb, cups and grams); money converts with "about".
- Set marks: liquid ink drops and brush circles, one haptic at close; tap shows the set.
- Title tap opens the app's index; pull-down never opens a menu; long press opens the
  detail sheet; back word top left.
- Receipts in the Tess corner with Undo for 10 s; Tess orb stays whole, never covers a
  value.
- Rail pages keep the looping places dial, pinned place and knob (sheets 118, 119, 123).
- Place knob Gym or Home, Try today, Swap in or Just today, Busy (sheets 128, 129).
- Live Activities, haptics per app (127), MotionPolicy, Reduce Motion, Dynamic Type to AX5.
- Review switches in Settings for opinions; sample data never touches the real store.
- Privacy walls exactly as before.

## 2c. Routines: Browse (the index) and the rail row (Oct 22, for Builder A)
Fills Product's gap G2 (product/routines-landing-build-sheet-oct22.md). Browse at the foot
and a tap on the title both open this page. It is a rail page (sheets 119, 123) in dusk
rose, the same frame as every other rail page.

Rail row (add to sheet 123, between Habits and Reading):
- Pinned: Today, the routines he usually runs today, in usual-start order.
- Knob: Kind (All, Daily, Workouts). Default All, remembered.
- Dial: time of day (Morning, Midday, Evening, Night, Any time). Loops, focus bigger.
- Rows: one routine per line, its name in ink and a plain value on the right.
- Opens: on Today when anything is left today, else on the place of the next usual start.

```
 < Routines
 Routines                                   All          <- title, knob word on the right
 Your routines, by the time you run them.               <- subtitle, ink 2
 Today                                                  <- pinned, dusk rose
   Midday                                               <- dial: places, loops
 Evening    Push A       usually 6:15 pm             <- focused place, bigger;
            Wind-down    6 steps                        its rows on the right
   Night
   Any time
                                         New routine    <- the write word, stays at the foot
```
- Row values: after 7 runs "{n} days, usually {start}, {length}"; before that "{n} steps".
  No streaks, no missed, nothing can fall (section 2, Routines).
- Tap a row opens the routine page (its steps). A workout routine opens Training's
  workout page, never a copy.
- Swipe right on a row is Start (rail rule): it opens the runner at step 1, or Pick up if
  that routine is already running. Swipe left: nothing yet (Product Q1 default).
- Long press opens the detail sheet (usual start, length, steps, Kind) as on every page.
- Kind: Daily = routines with a usual time; Workouts = Training's routines (Push A).
  A routine may sit in both All and its kind; Kind never holds places.
- A place with nothing in it stays on the dial at ink 30% and, focused, reads
  "Nothing at night yet." with no button. Writing is never in the rail: "New routine" is
  the one write word at the foot, ink, no underline (the landing's one rose underline is
  not on this page; Start lives on the rows).
- Private routine: "Private routine" in place of its name, everywhere.
- Words: Today, All, Daily, Workouts, Morning, Midday, Evening, Night, Any time, New
  routine. Sentence case. Time as "22 min", "1 hr 5 min".
- Keep every rail feature (section 2b): looping dial, pinned place, knob swipe and tap,
  MotionPolicy, Reduce Motion crossfade, AX5 (rows stack the value under the name).

## 2d. Lists: the rail, and the Reusable, Picks and Runs views (Oct 22, for Builder B)
Fills Product's Lists gaps (product/notes-lists-landing-build-sheet-oct22.md section 8).
Lists stays its own app (ruling: Notes and Lists stay two pages), so it gets its own rail
row instead of riding Notes' Kind knob. Olive #B5BE7A dark / #5E6B1F light. The signature
is the filling line (section 2, Lists): a list's name filled with ink by the share done.
Shelf, Reusable and Picks are one rail page opened on a different knob value; Runs is a
plain history page, not a rail.

Rail row (add to sheet 123, after Notes):
- Pinned: Now, the list running or due soonest (the landing's lead list).
- Knob: Kind (All, Reusable, Picks). Shelf opens it on All, Reusable on Reusable, Picks
  on Picks. Remembered per door.
- Dial: what the lists are about, from their @links like Notes (Trip, Home, Training,
  Kitchen), then Loose. Loops, focus bigger; 3 to 8 places, the rest under Loose.
- Rows: one list per line, its name as a filling line, a short value under it.
- Opens: on Now when a list runs, else on the place of the most recently touched list.
- Groceries is not here: it is To get inside Pantry (sheet 118). Private lists read
  "Private list".

### Shelf (knob All)
```
 < Lists
 Lists                                      All          <- knob word on the right
 Everything you keep track of.
 Now          Packing                                    <- pinned, olive; filling line
              6 left of 24, Resume
   Home
 Trip         Packing          6 left of 24              <- focused place, rows right
              Day bag          all done
   Kitchen
   Loose
                                          New list       <- write word at the foot
```
- Row: the name in large type filled with ink from the left by the share done, the value
  small under it: "6 left of 24", "all done", "3 to get, new from Tacos".
- Tap opens the list page (sheet 94). Swipe right: Resume or Start, as the landing's lead.
  Long press: the detail sheet (Kind, the @link, Reset rule).

### Reusable (knob Reusable)
Lists that are used again and again (Packing, Gym bag, Morning bag).
```
 Packing                                                 <- the filling line
 6 left of 24, last run Oct 12
 Gym bag
 all done. Reset it for next time                        <- T-L12, ink 2; "Reset" ink word
```
- The value says how far this run is and when it last ran: "6 left of 24, last run
  Oct 12"; a full list reads "all done. Reset it for next time" (Product T-L12).
- Swipe right is Reset: every item opens, the fill drains right to left (MotionPolicy;
  Reduce Motion: it simply empties), a new run starts, receipt "Packing, reset." with Undo
  10 s. The finished run goes to Runs.
- No streaks, no "missed", no count of runs on this page.

### Picks (knob Picks)
Pick-one lists (Films, Dinners out, Books next).
```
 Films                                                   <- no fill: picks are never "done"
 12 to pick from, picked Dune on Oct 18
 Dinners out
 7 to pick from
```
- Picks have no fill (nothing is done); the name is plain ink at the same size.
- Value: "{n} to pick from", then the last pick and its day when there is one.
- Swipe right is Pick one: the pick moment of sheet 87 (page dims to 14%, one item rises
  large, "Keep it" or "Another"). Tap opens the list to add or remove.

### Runs (its own page, not a rail)
Every finished or reset run of a reusable list, newest first, grouped by month words.
```
 < Lists
 Runs
 Each time you used a list again.
 October
 Packing                  Oct 12        24 of 24        <- a short filling line per run
 Gym bag                  Oct 9         10 of 11
 September
 Packing                  Sep 3         22 of 24
```
- One line per run: list name, the day, "{done} of {n}". Under the name a thin filling
  line shows the share done. No totals, no averages, no streaks, nothing red.
- Tap a run opens what was left that time, read only ("Charger and passport were left").
- Private lists: "Private list" and no item words.
- Empty: "Runs show here after you reset a list." in ink 2, no button.

Words: Now, All, Reusable, Picks, Runs, Loose, left of, all done, Reset it for next time,
to pick from, picked, Pick one, Keep it, Another, New list. Sentence case.
Keep every feature (section 2b and sheet 94): paste preview, ghost row, sections, the pick
moment, reusable Reset, quantity swipe on a row, the fold, rail dial and knob, AX5 (the
value moves under the name, nothing cut).

## 3. Build order
1. A shared LandingPage frame (frame, the bands, empty-band rule, sentence slot).
2. Each app's lead form as its own view on that frame, in the order the app screens ship.
3. Sentence templates per app, on the phone, with a unit test for each case.

Sources: Kaushik's picks record P5nUSTJ2ygJUvfABSDGet2; drawings mockups/landing-v2-131.png;
app-character-127. v1 of this sheet (lead forms before his picks) is superseded.
