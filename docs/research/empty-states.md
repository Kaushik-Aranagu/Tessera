# Empty states: every screen with no data

For: Core, Builder A, Builder B, Design. Board item 24. 2026-10-16. Research lab.
Code read: origin/master `2b1934a`, traced by hand (no simulator run). Voice rules from `docs/research/tess-voice.md`,
`TessVoice.violations` (`TesseraCore/Sources/TesseraTess/TessCapturing.swift:88`: one line, under 12 words, no "!", no
emoji, none of should, must, missed, streak, great, awesome, sorry, oops), `.claude/skills/tessera-design/SKILL.md`
("States" and "Copy & tone") and `docs/DESIGN_MOTION.md:42`. There is no `docs/design/` folder on master.

## In one line

Nothing crashes and nothing uses `ContentUnavailableView` (zero hits in `Features/`, `App/`, `Widgets/`). Every screen
already has its own plain line. The problems are smaller and come in four kinds: two lines saying the same thing,
counts that start from a whole week or month before the app existed, an empty state with no way forward, and a few
zero-item objects (a routine with no exercises, a workout with no sets, a recipe with no lines) that render as blank
space or a dead screen.

## What "empty" means on a fresh install

First launch is not empty for training. `prepareCatalog` (`TesseraCore/.../Engine/ObjectStore+Lifecycle.swift:16`)
installs the exercise library, the starter Push / Pull / Legs x 2 plan (`Catalog/StarterContent.swift`) and an empty
Groceries list. So on day one:

- Today shows the plan's next routine as the hero ("today's training", Push A, Start).
- Training shows that routine.
- Review, Plans, the exercise page, Notes, Groceries, Recipes and Backups have no data.

The Today and Training "nothing" branches are only reached if the plan is deleted or has no routines.

## Baseline rules used for the proposed lines

1. One line of plain words, under 12 words, then one fast path (a word with an arrow, or the existing key).
2. Say what is true now. Do not count days before the app or the plan existed.
3. No guilt, no reassurance that implies guilt ("and that's fine"), no "!".
4. One thing said once per screen. If the context line already says it, the body does not repeat it.
5. A zero-item object says what to add, not "0".

## Screen by screen

Owner key: **Core** (TesseraCore, Notes, Review, Groceries, Recipes, Backup), **A** (Workout, Exercise, Plans, Routine,
Widgets, DesignSystem), **B** (Home, Command, RootView, BottomChrome).

### Home: Today (Now, queue, ledger)

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| No plan, nothing scheduled, not trained | Hero "Nothing else is planned today." `Features/Home/NowPage.swift:108`, key "Look back at the week →" `:115`; under it the queue says "Nothing else today." `Features/Home/HomeQueue.swift:97` | Two lines saying the same thing. "else" is wrong when nothing was ever planned. The only action leads to a Review page that is also empty. | Hero: "Nothing planned today." Key: "Plan a day →" or "Ask Tess →" (opens Tess with "What's next?"). Hide the queue line when the hero is this empty hero. | B |
| All done today (trained, tasks finished) | DoneHero "trained this evening" `NowPage.swift:313`, the workout title, Tess's count line `:329`; queue "Nothing else today." `HomeQueue.swift:97` | Fine. This is the right "all done" state and differs from first launch, as it should. | Keep. | B |
| Starter plan, first launch | RoutineHero "today's training" `NowPage.swift:349`, Push A, Start, "5 EXERCISES" / "16 SETS" `:372-373`; queue "Nothing else today." | Fine. | Keep. | B |
| Routine with zero exercises (all slots removed in the routine editor) | RoutineHero with "0 EXERCISES" / "0 SETS" `NowPage.swift:372-373` and a live Start key `:367` | Start opens live mode with nothing to log (see Live workout). | Hide Start. Line: "Push A has no exercises yet." Key: "Add one →" (opens the routine editor). | B |
| Ledger (no suspended processes) | Nothing rendered (`NowPage.swift:38` ForEach over an empty list) | Fine; silence is right. | Keep. | B |
| Day strip, nothing scheduled | No visible text; VoiceOver "Friday, nothing planned" `Features/Home/DayStrip.swift:64` | Fine. | Keep. | B |

### Home: Review page (the sibling page left of Today)

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| No training at all (first week) | "the week so far" `Features/Home/ReviewPage.swift:121`, hero "A quiet week so far" `:30`, seven empty ink rings, no Tess line (`:142`, `tessLine` returns nil) | On day one, six of the seven rings are days before the app existed. No way forward from the page. | Context: "the week so far". Hero: "Day one." when the first workout or install is today, else keep "A quiet week so far". Draw rings only from the install day. Add one line in Tess's colour: "Push A is up next." (taps through to Today). | B |
| Trained, all done today | "Four good days of seven" etc. | Fine. | Keep. | B |

### Home: Training page

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| No plan, no workout, not trained | "nothing on the plan today" `Features/Home/TrainingPage.swift:358`, "A rest day. It counts too." `:361`, "Browse exercises →" `:370` | With no plan at all this is not a rest day; calling it one is a small untruth. Browsing exercises is not the fast path to training. | Context: "no plan yet". Hero: "Pick a routine, or just log a set." Key: "Log a set →" (opens Tess prefilled "log "). Keep the rest-day copy only when a plan exists and today is planned as rest. | B |
| Trained, all done today | DoneTraining: "done this evening" `:265`, rows, Tess's line `:247`, "Pull A is next." `:253`; a skipped entry reads "not today" `:282` | Fine, and it differs from first launch as it should. | Keep. | B |

### Tess bar (BottomChrome)

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| Opened on Home, first launch | Question "What’s next?" `Features/Command/BottomChrome.swift:194`; fast paths empty because they only look at `model.session` and `tonightWorkout()` (`:198-214`) | Today's hero offers "Start Push A", but Tess offers nothing, because the routine is not yet a workout object. | Add `model.todaysRoutine()` as a fast path: "Start Push A". | B |
| A question with no data | "No logged sets for that yet." `:625` | Fine. | Keep. | B |
| "log bench 80x8" typed as a question on first launch | "No workout today to log into." `:652` | Today shows Push A, so this is wrong on day one. | Start today's routine and log into it, or say "Logged to a new workout." | B |

### Live workout and finish

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| Started from a routine with zero exercises | `WorkoutSession.currentEntry` is nil (`Features/Workout/WorkoutSession.swift:115`), so the subline is blank (`WorkoutParts.swift:106`), the strip is empty, and logging returns early (`WorkoutSession.swift:327`) | A dead screen: a dial and a key that do nothing. Needs a simulator check to confirm the exact look. | Do not allow Start on an empty routine (see Today). If it happens anyway: "Nothing in this one yet." with "Add an exercise →". | A |
| Finished with zero sets ("Finish here" in the running order, `Features/Workout/ExerciseStrip.swift:111`) | "Push A, done" `WorkoutFinishView.swift:38`, "12 min, 0 kg moved" `:67` | "0 kg moved" reads as a score. The zero-set workout also counts as a good day on Review, because `HomeData.trainingDates` takes any workout with `endedAt` (`Features/Home/HomeSpatialView.swift:375`). | Finish line: "Ended early. Nothing logged." Ask Core whether a zero-set workout should be dropped instead of saved (see open questions). | A (copy), Core (counting) |

### Exercise page

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| No history for this exercise | Summary "No best yet. The first logged set sets one." `Features/Exercise/ExercisePage.swift:129`; History "No sessions yet. The first set you log starts the history." `Features/Exercise/ExerciseViews.swift:106`; Tess "First time: start light, 8 reps." `Features/Exercise/ExerciseDigest.swift:120`; key "Log a set" `ExercisePage.swift:205` | Three lines about the same fact. The history line is 11 words and the summary line repeats "set". | Summary: "No sets yet." History window: "Your sessions land here." Keep Tess's "First time: start light, 8 reps." and the "Log a set" key. | A |
| Rep maxes tab, no history | Ten dashes `ExerciseViews.swift:186` plus "Warm-ups and sets over 12 reps don’t count here." `:200` | Ten empty slots and a rule about sets that do not exist. | Show one line instead of the grid: "Rep maxes fill in as you log." | A |
| Muscles tab, nothing linked | "No muscles linked yet." `ExerciseViews.swift:218` | Fine, but no way to fix it. | "No muscles linked yet. Ask Tess to add one." | A |

### Plans (Week, Month) and routine editor

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| Week, first launch on a Thursday | "this week, rolling on" `Features/Plans/WeekPage.swift:15`, hero "0 of 6\nsessions" `Features/Plans/PlanDigest.swift:109`, Mon to Wed shown as open days | The target counts days before the plan existed, so the week cannot be met from day one. | Count planned sessions from the plan's creation day: "0 of 3 sessions". Before the first session: "First session today." | A |
| Week, "Sets per muscle" with no training | Header `WeekPage.swift:23` and every muscle row at 0 over its range band (`PlanData.swift:60`) | A long list of zeros. | When every row is 0, one line instead: "Sets per muscle fill in after a workout." | A |
| Month, first launch mid-month | Hero "Session 1\nof 26" or "26 sessions\nplanned" `PlanDigest.swift:227`, built from a full-month rhythm (`MonthPage.swift:17-19`); Tess line hidden because last month is 0 (`PlanDigest.swift:232`) | 26 is not reachable on 16 October with a plan made today. That is a quiet guilt count. | Plan rhythm from the creation day: "Session 1 of 13". With no plan: "1 session this month" (already there, `:224`). | A |
| Plans with no plan object | Week hero "A fresh\nweek" `PlanDigest.swift:112`, Month "0 sessions\nthis month" `:224` | "0 sessions this month" reads as a score. | Month: "No sessions yet this month." | A |
| Routine editor, zero slots | "0 exercises, 0 sets. Tap one to change it." `Features/Plans/RoutineEditor.swift:106` | "Tap one" with none to tap. | "No exercises yet." and the existing "Add an exercise →". | A |

### Review screen (full week, opened from "The week")

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| Nothing done this week | "the week so far" `Features/Review/ReviewView.swift:149`, "A quiet week so far", seven rings, "Nothing finished yet, and that's fine." `:111`, no Tess line (`:117-126`), "Backups" `:214` | "and that's fine" reassures against a guilt nobody raised. No forward step. Its "good day" means anything finished, while the Home Review page means trained; the two can show different headlines on the same day. | Counts line: "Nothing finished yet this week." Tess line: "Push A is up next." when a plan exists. Pick one meaning of "good day" for both pages. | Core |

### Groceries

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| Empty list, first launch | Context "Nothing to get" `Features/Groceries/GroceriesView.swift:693`, title "Groceries", writing line placeholder "eggs, milk, 2 lemons" `:365`, then "Nothing to get." `:663` and "Tell me “milk, eggs”, or swipe a recipe's ingredients here." `:666` | "Nothing to get" twice. The hint is 11 words and names recipe swiping when there are no recipes. The writing line right above already shows the example. | Context: "Nothing to get". Drop the body title. One Tess line: "Add above, or send a recipe here." Show the recipe half only when a recipe exists. | Core |
| All struck (everything in the basket) | "All in the basket." `:663` with the basket fold | Fine, and it differs from first launch as it should. | Keep. | Core |
| Shop started on an empty list | Hold the title works (`:265`, `StartShop` has no guard, `TesseraCore/.../Kitchen/Shopping.swift:37`); shows "shopping, all in the basket" `:691` and a Done key | Starts a running process with nothing in it; it can then sit in the Today ledger. | Ignore the hold when the list is empty, or Tess: "Nothing on the list to shop for." | Core |

### Recipes and paste a recipe

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| No recipes ("Recipes" on the Kitchen page) | `RecipeView` falls through to `PasteRecipe()` (`Features/Recipes/RecipesEntry.swift:15-18`): "Paste a recipe and I'll read it." `Features/Recipes/PasteRecipe.swift:31`, placeholder "Ingredients, then the method. Any shape is fine." `:75` | Good line and a fast path. The Kitchen page also shows a separate "Paste a recipe" word, so day one has two ways into the same screen. | Keep the copy. Hide the extra "Paste a recipe" word while there are no recipes. | Core (copy), B (Kitchen page word) |
| A recipe with no ingredient or step lines (a paste that read nothing) | Empty ingredient column, "0 steps" `Features/Recipes/RecipePage.swift:98`, a live Cook key `:104` | Blank space and a zero count. | "Nothing read yet. Paste it again?" in place of the column, and hide Cook. | Core |
| Recipe "As pasted" with no source text | Empty text under "As pasted" `RecipePage.swift:330`; "Cooked: Not yet." `:316` | Blank section. "Not yet." is fine. | Hide "As pasted" when the source is empty. | Core |
| Recipe deleted while open | "This recipe is gone. Undo brings it back." `:133` | Fine. | Keep. | Core |

### Notes

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| No notes | Context "A place for loose thoughts" `Features/Notes/NotesView.swift:227`, hero "Notes", placeholder "Write something. @ links a thing." `:131`, then "Nothing written yet." `:214` and "Write above, or tell Tess “note: bar felt heavy”. @ links a note to a thing." `:217` | The second line is 15 words and repeats the placeholder's "@ links". | Keep "Nothing written yet." Second line: "Or tell Tess “note: bar felt heavy”." | Core |

### Backups

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| No copy made yet | "your history" `Features/Backup/BackupView.swift:42`, hero "Kept on this iPhone" `:46`, "The first copy is made when you leave the app today." `:275`, "Copies on this iPhone go if the app is deleted. A folder in iCloud Drive keeps them." `:78`, "Save a copy", "Restore" | The hero claims something is kept before any copy exists. Otherwise good, and "Save a copy" is the fast path. | Hero before the first copy: "No copy yet". Keep the rest. | Core |

### Object page (classes and objects with no data)

| State | What it shows now | Problem | Proposed | Owner |
|---|---|---|---|---|
| Untitled object, empty fields | "Untitled" `Features/Objects/ObjectPage.swift:223`, a dash for each empty field `:405`, sections hidden when empty (`:87`, `:236`, `:250`) | Fine as a data view. | Keep. | B (no team owns `Objects/` in the brief; B owns routing) |

### Screens not on master

There is no Lists screen, no Day log screen and no home-screen widget on master (`Widgets/` holds only the rest Live
Activity). Their empty lines are already drafted in `docs/research/shutdown-daylog-copy.md`,
`docs/research/widget-states.md` and `docs/product/lists-screens-acceptance.md`; check them against the rules above when
those screens land.

## First launch versus all done today

| Screen | First launch | All done today |
|---|---|---|
| Today | RoutineHero, Push A, Start (starter plan) | DoneHero, "trained this evening", Tess count line |
| Training | Push A routine plan | DoneTraining, "Pull A is next." |
| Review page | "A quiet week so far" over seven rings, six of them before install (fix) | Real count |
| Plans Week / Month | "0 of 6", "Session 1 of 26" from a whole week and month (fix) | Real counts |
| Groceries | "Nothing to get" twice (fix) | "All in the basket." |
| Tess bar on Home | No fast path (fix) | No fast path, correct |

The rest (Notes, Recipes, Exercise, Backups) have only one empty state.

## Count by team

| Team | Fixes | Items |
|---|---|---|
| Builder B | 7 | Today empty hero and its duplicate queue line; empty-routine Start; Review page first week and no forward line; Training "rest day" with no plan; Tess fast path for today's routine; "No workout today to log into." on day one; the extra Kitchen "Paste a recipe" word |
| Builder A | 9 | Zero-entry live workout; "0 kg moved" finish; exercise page triple line; rep maxes grid of dashes; muscles tab with no action; week count from plan start; month count from plan start and "0 sessions"; all-zero "Sets per muscle"; routine editor "Tap one" with none |
| Core | 8 | Review screen counts line and the two meanings of "good day"; Groceries double "Nothing to get" and recipe hint; empty shop; recipe with no lines; empty "As pasted"; Notes long second line; Backups hero before the first copy; whether zero-set workouts count as trained |

The rep maxes grid and the muscles tab can ship as one change.

## Worst case

A routine with no exercises. Today and Training still show a Start key with "0 EXERCISES", and Start opens live mode
with no current entry: no name, an empty strip, and a log key that returns early (`WorkoutSession.swift:327`). If he
then uses "Finish here", the finish screen says "0 kg moved" and that empty workout counts as a good day on Review. It
needs one simulator run to confirm how live mode looks, but every step is reachable through the routine editor.

The worst confirmed copy problem is Plans on a fresh install: "Session 1 of 26" in the middle of October sets a target
that could not be met, the opposite of "counts, not streaks".

## Open questions

1. Should a workout finished with zero sets be saved at all, or dropped with an Undo? If saved, should it count as a
   trained day on Review and Plans?
2. Do plan targets (week and month) count from the plan's creation day, or from install? Starter content and a
   user-made plan may want different answers.
3. Which "good day" does Review use: anything finished (Review screen) or trained (Home Review page)? Today they differ.
4. Should empty states get the breathing SF Symbol that `docs/DESIGN_MOTION.md:42` calls for, or stay text only as all
   of master does now? A shared `EmptyLine` in DesignSystem (Builder A) would keep the type, colour and fast-path word
   the same everywhere.
5. Should the starter plan stay as Kaushik's hard-coded PPL x 2? It is the reason Today and Training are never empty,
   so the "no plan" branches are close to dead code and get little testing.
6. Who owns `Features/Objects/` for copy? It is not in any team's list.
