# Undo lines: every write, what it says, what Undo does

Board item 23. Traced by hand on `origin/master` at `2b1934a` (Merge #157). No build was run. Line numbers are
master's.

For: Core, Builder A, Builder B, Design (copy).

## How undo works today (the engine)

- Every typed action runs through `ActionEngine.perform` (`TesseraCore/.../Actions/ActionEngine.swift:41`) and
  becomes one `OpRecord` with its ops, actor and a one-line `summary(in:)`. The summary is computed after the action
  ran.
- `undo(record)` (`ActionEngine.swift:137`) replays the inverse ops, guarded: an op whose data changed since is
  skipped and reported as `.partial(skipped:)`. Then `record.state = .undone`. No caller on master reads the
  outcome, so a partial undo looks like a full one.
- `discard(record)` (`:109`) is undo for a pending ghost. `commit` and `commitExpired` (`:101`, `:115`) make a ghost
  final and fire observers.
- Observers (`:87`) fire on commit only. Nothing fires on undo. Apple Health hangs off this
  (`App/Health/HealthExporter.swift:16`).
- `Transaction.delete` (`Transaction.swift:84`) soft-deletes the object and its children; `ObjectStore.restore`
  (`ObjectStore.swift:64`) brings back only children deleted in the same instant. Links are rows on the object and
  come back with it; backlinks already skip deleted sources (`ObjectStore.swift:281`). So the engine itself leaves no
  dangling links. Everything that leaks is outside the store: timers, Live Activity, in-memory session state, Health,
  and lines on screen.
- Some writes skip the op log on purpose (rest bookkeeping, `WorkoutSession+Rest.swift:40`) or by accident
  (`store.createClass`, `ObjectPage.swift:136`).

There are seven Undo controls on master, each wired separately:

| Control | File | Undoes | Says after |
|---|---|---|---|
| Tess's UNDO beside the soul | `Features/Command/BottomChrome.swift:109` | `TessVoice.note.undo`, else the last capture | nothing (note cleared, `.decrease` haptic) |
| Tess's UNDO on Groceries | `Features/Groceries/GroceriesView.swift:640` | `TessVoice.note.undo` | nothing |
| Routine editor Undo | `Features/Plans/RoutineEditor.swift:187` | the last editor change | "Undone." |
| Live workout Undo | `Features/Workout/WorkoutSession+Edit.swift:94`, `WorkoutSession.swift:401` | last edit, else last held set | edit: "Set 3 is back as it was."; set: nothing |
| Paste recipe Undo | `Features/Recipes/PasteRecipe.swift:203` | the save | nothing (back to "Save recipe") |
| Recipe "to buy" Undo | `Features/Recipes/RecipePage.swift:191` | the send to Groceries | nothing |
| Siri / Shortcuts "Undo Last Set" | `TesseraCore/Sources/TesseraIntents/Intents.swift:66` | newest record that created a set in an open workout | "Last set removed." / "No set to undo." |

## 1. Every write path on master

47 write paths (demo seeding under `-demo*` left out). "Line" is the exact text shown or spoken. "Undo" is what a
person can actually reach.

### Training (Builder A)

| # | Path | Writes at | Line | Undo |
|---|---|---|---|---|
| 1 | Hold to log a set | `Features/Workout/WorkoutSession.swift:333` (`LogNextSet`) or `:336` (`LogSet`) | rest: "Set 3. 80 × 8." or "New best: 85 × 5. e1RM 99." (`WorkoutParts.swift:153-156`); after rest "Logged." (`:186`) | Live Undo, `WorkoutSession.swift:404`. Clears rest, bests, top-set check, refills the dial. Says nothing: the line falls back to the next-set line. |
| 2 | Live Activity Done | `Shared/RestIntents.swift:35` relay, `LiveActivity/LiveWorkout.swift:24` then path 1 with `source: .lockScreen` | Live Activity face only | Same as 1, in the app |
| 3 | Edit a logged set | `WorkoutSession+Edit.swift:38` (`EditSet`) | "Set 2 is 85 × 6 now." (`:42`) | Live Undo `:96`, "Set 2 is back as it was." (`:98`) |
| 4 | Remove a logged set | `WorkoutSession+Edit.swift:52` (`DeleteObject`) | "Set 3 removed." (`:54`) | Live Undo `:96`, "Set 3 is back as it was." Bests removed at `:66` are not put back. |
| 5 | Swap exercise for today | `WorkoutSession.swift:499` (`SwapEntryExercise`) | "Bench stays in the plan." (`WorkoutParts.swift:169`) | None. Live Undo undoes the previous set instead (see B4). |
| 6 | Hold to finish | `WorkoutSession.swift:562` (`FinishWorkout`) / `:560` (`FinishWorkoutEarly`) | Core summary line, e.g. "5 of 5 exercises, 16 sets, 1 record." (`WorkoutModeView.swift:82`) | None (`undoable = nil`, `:566`) |
| 7 | Rest +15 / Skip (screen or Live Activity) | `WorkoutSession.swift:427-446`, saved by `WorkoutSession+Rest.swift:40` outside the op log | "+15. Drag again for more." / "Skipped. Set 4 is up." | None, by design |
| 8 | Skip set (Live Activity) | `WorkoutSession.swift:158`, in memory only (`skipped` dict) | none | None; lost on relaunch |
| 9 | Start a routine | `App/AppModel.swift:526` (Now, Training page), `Features/Plans/WeekPage.swift:70` | none (the live cover opens) | None |
| 10 | Start a planned workout | `AppModel.swift:440` (`StartWorkout`) | none | None |
| 11 | Routine editor: add, swap, sets, reps, earlier, later | `Features/Plans/RoutineEditor.swift:172` via `:180, :182, :240-253` | `summary + "."`: "Added bench press to the routine.", "Swapped in Dips.", "Bench Press: 3 × 8-12.", "Moved Bench Press to 2." | Editor Undo `:189`, "Undone." |
| 12 | Routine editor: Take out | `RoutineEditor.swift:257` (`DeleteObject`, not `RemoveSlot`) | "Deleted Bench Press." | Editor Undo, "Undone." |
| 13 | Exercise page: Add to routine | `Features/Exercise/ExercisePage.swift:241` (`AddSlot`) | none (success haptic only) | None |

### Home, Tess and the command layer (Builder B)

| # | Path | Writes at | Line | Undo |
|---|---|---|---|---|
| 14 | Now: finish the hero task | `Features/Home/NowPage.swift:161` (`SetTaskDone`) | "Done. Next one is up." or "Done. Groceries for the week." (`:166`) | Tess UNDO, silent |
| 15 | Queue: swipe right to finish | `Features/Home/HomeQueue.swift:371` | "Done. Dentist." (`:375`) | Tess UNDO, silent |
| 16 | Queue: swipe left, not now | `HomeQueue.swift:390` (`MoveTask`) | "Moved to tomorrow." / "Moved to next week." (`:394`) | Tess UNDO, silent |
| 17 | Resume a process | `AppModel.swift:264` (`ResumeProcess`) | none | None (fine: it is navigation) |
| 18 | Tess capture, grammar route (ghost, dries in 2 s) | `App/AppModel.swift:161` into `TesseraTess/TessCaptureEngine.swift:78-183` | see the capture table below | Ghost: tap commits (`NowPage.swift:285`), swipe drops (`:289`, task ghosts on Now only). After: Tess UNDO, `AppModel.swift:223`, silent |
| 19 | Tess capture, on-device model route | `TesseraTess/TessModelCapture.swift:24` via `TessTools.run` (`TessTools.swift:46`) | the model's own line if it passes `TessVoice.violations`, else `record.summary` with no full stop (`:44`) | Same as 18 |
| 20 | Command questions route, "log bench 80x8?" | `BottomChrome.swift:663` (`session.logSet`) | "Logged bench press 80 × 8 · e1RM 99." (`:666`) | None in the bar (`lastCapture` is nil); the live Undo holds it |
| 21 | Command questions route, anything else ending "?" | `BottomChrome.swift:631` → `AppModel.capture(title:)` (`:133`, a pending `CreateTask` 4 h out) | "Drying. Swipe to drop it." (`:634`) | Swipe on Now, then Tess UNDO |
| 22 | Ask Tess inside the live workout | `Features/Workout/WorkoutModeView.swift:238` → path 18 | the capture line (`askReply`) | None reachable (see B6) |

Capture lines (path 18, `TessCaptureEngine.swift`):

| Parse | Action | Line |
|---|---|---|
| lift (`:82`) | `LogExercise` | "Bench 3 x 10 at 80. Added to today." |
| set (`:93`) | `LogSet` | "Set 3. 80 x 8." / "Same again, logged." / "Drop set. 60 x 10." |
| several sets (`:58`) | `LogSet` × n | "3 sets logged." |
| task (`:107`) | `CreateTask` | "Dentist, Thursday 3 pm." / "Dentist, in Later." |
| note (`:111`) | `CreateNote` | "Noted." / "Noted, linked." / "Noted for Friday." |
| groceries (`:133`) | `AddGroceries` | "Milk, on the list." / "3 things on the list." |
| cook later (`:137`) | `CreateTask` | "Carbonara, tomorrow 7 pm." |
| cook now (`:143`) | `StartCooking` | "Cooking carbonara." |
| timer (`:148`) | `StartKitchenTimer` | "Pasta, 10 min." |
| list (`:152`) | `CreateList` | "New list: Packing." |
| shop (`:155`) | `StartShop` | "Shopping, 9 left." |
| reschedule (`:159`) | `MoveTask` | "Dentist, Friday 3 pm." |
| next step (`:164`) | `GoToCookStep` | "Step 3." |
| done cooking (`:168`) | `FinishCooking` | "Carbonara, done." |
| recipe (`:174`) | `CreateRecipe` | "9 ingredients, 5 steps, 2 timers." |
| failure (`:216`) | none | "Didn't save that. Sets must be 1 to 20." / "Didn't save that. Tap to retry." |

### Notes, Groceries, Recipes, Backup, engine (Core)

| # | Path | Writes at | Line | Undo |
|---|---|---|---|---|
| 23 | Write a note | `Features/Notes/NotesView.swift:109` (`CreateNote`) | none (the row inks in) | None |
| 24 | Edit a note (autosave, 0.8 s) | `Features/Notes/NoteEditor.swift:142` (`EditNote`) | none | None (each pause is its own record) |
| 25 | Delete a note | `NoteEditor.swift:151` (`DeleteObject`), then dismiss | none | None |
| 26 | Add groceries | `Features/Groceries/GroceriesView.swift:203` | none | None |
| 27 | Check an item | `GroceriesView.swift:233` | none (dab arcs into the basket) | None (tap it in the basket to uncheck) |
| 28 | Uncheck from the basket | `GroceriesView.swift:247` | none | None |
| 29 | Clear the basket | `GroceriesView.swift:256` (`ClearDoneItems`) | "Cleared 3 from the basket." (`:260`) | Tess UNDO on Groceries `:642`, silent |
| 30 | Start / pause the shop | `GroceriesView.swift:270` / `:268` | none (seam appears) | None |
| 31 | Finish the shop | `GroceriesView.swift:278` (`FinishShop`, clears the basket) | none | None |
| 32 | Save a pasted recipe | `Features/Recipes/PasteRecipe.swift:187` | "Carbonara saved." (`:223`) | Undo for 2 s, `:204`, silent, then the page moves on |
| 33 | Send a recipe to Groceries | `Features/Recipes/RecipePage.swift:173` | "12 to buy, in Groceries" (`:208`) | Undo for 4 s, `:192`, silent |
| 34 | Cook a recipe | `RecipePage.swift:147` (`StartCooking`) | none | None |
| 35 | Stage a restore | `Features/Backup/BackupView.swift:219` | "What's here now is kept in Backups, so this can be undone." (`:221`) | "Cancel restore" `:172`, "Cancelled. Nothing will be replaced." |
| 36 | Apply a restore at launch | `TesseraCore/.../Export/TesseraBackup.swift:183` | launch note "Restored from your backup. What was here before is kept in Backups, so you can restore it again." (`:233`) | Restore the "Before-restore" copy by hand |
| 37 | Idle suspend | `TesseraCore/.../Processes/ProcessTable.swift:90`, from `AppModel.swift:250` | none | n/a (bookkeeping) |
| 38 | Put away after idle | `ProcessTable.swift:104` | "Put two things away. They're in Later." (`:112`) into `AppModel.processNotes`, which nothing shows | None |
| 39 | 6-hour workout wrap-up | `ProcessTable.swift:124-125` (`FinishWorkout` then `EndProcess`, two records) | "Saved Push A, 3 of 5 exercises" (`:128`), never shown | None |
| 40 | Resume the live workout on foreground | `AppModel.swift:247` | none | n/a |
| 41 | New subclass | `Features/Objects/ObjectPage.swift:136` (`store.createClass`, no op) | none | Impossible: not in the op log |
| 42 | Apple Health export (side effect) | `App/Health/HealthExporter.swift:16` on `finishWorkout` commits | none | Not reversible from the app |

### App Intents (Core, `TesseraCore/Sources/TesseraIntents/Intents.swift`)

| # | Intent | Writes at | Dialog | Undo |
|---|---|---|---|---|
| 43 | Log a Set | `:28` (`LogExercise`) | `"\(record.summary)."`: "Logged bench press 1×8 at 80 kg." | "Undo Last Set" |
| 44 | Log Next Set | `:50` (`LogNextSet`) | "Logged 82.5 × 8." / "No workout running." | "Undo Last Set" |
| 45 | Undo Last Set | `:66` (`undoLatestSet`) | "Last set removed." / "No set to undo." | none (no redo) |
| 46 | Start a Workout | `:87` (`StartRoutine`) | "Pull A started. 5 exercises." | None |
| 47 | Finish Workout | `:105` | "Finished. 6 of 6 exercises." | None |
| (48) | Add a Task | `:124` (`CreateTask`) | `"\(record.summary)."`: "Added “Dentist”." | None |
| (49) | Tell Tess | `:143` (capture, committed at once) | the capture line | None (no ghost in Siri, and no undo phrase except for sets) |

Rows 48 and 49 reuse paths 18 and the task action, so the count stays at 47 distinct paths. `AppModel.finish(taskID:)`
(`:430`) and `AppModel.endWorkout()` (`:448`) also write but nothing calls them.

## 2. Mismatches

### Wording (17)

| # | Where | What disagrees |
|---|---|---|
| W1 | Undo Last Set intent (`Intents.swift:69`) vs Live Activity design vs live remove (`+Edit.swift:54`) | "Last set removed." vs "Set 3 taken back" (widget-states C6) vs "Set 3 removed." Three phrasings, and the Siri one doesn't name the set. |
| W2 | Routine editor Undo (`RoutineEditor.swift:193`) | "Undone." names nothing. |
| W3 | Routine editor Take out (`:257`) | The word on the key is "Take out"; the line is DeleteObject's "Deleted Bench Press." Core's `RemoveSlot` already says "Removed Bench Press". |
| W4 | Routine editor lines | "Added bench press to the routine." (lowercase) next to "Moved Bench Press to 2." (title case) in the same slot. |
| W5 | Log a Set intent | "Logged bench press 1×8 at 80 kg." vs Tess "Bench 8 reps at 80. Added to today." for the same phrase. "1×8" for one set. |
| W6 | Log Next Set intent | "Logged 82.5 × 8." vs Live Activity and live screen "Set 4. 82.5 × 8." The set number is lost. |
| W7 | Add a Task intent | "Added “Dentist”." vs Tess "Dentist, Thursday 3 pm." |
| W8 | Tess lines vs drawn lines (C4) | "80 x 8" in every Tess capture line, "80 × 8" on the live screen, the Live Activity, intents. |
| W9 | Clear basket | Screen: "Cleared 3 from the basket." Op log summary (Review, process trail): "Cleared Groceries". |
| W10 | Done lines | Home "Done. Dentist." vs Core summary "Done: Dentist" vs Now "Done. Next one is up.", which names the next thing while UNDO reverts the last one. |
| W11 | Finish lines (C5, C10) | Intent "Finished. 6 of 6 exercises." vs live "5 of 5 exercises, 16 sets, 1 record." vs wrap-up "Saved Push A, 3 of 5 exercises" (no full stop, never shown). |
| W12 | Backup stage (`BackupView.swift:221`) | Says "can be undone" but there is no Undo; the real control is "Cancel restore", and after launch it's a manual restore. |
| W13 | Recipe gone (`RecipePage.swift:133`) | "This recipe is gone. Undo brings it back." No screen deletes a recipe and no Undo control reaches one. |
| W14 | Model route fallback (`TessModelCapture.swift:44`) | Falls back to `record.summary` with no full stop ("Added milk"), off the house voice. |
| W15 | Command log line (`BottomChrome.swift:666`) | "Logged bench press 80 × 8 · e1RM 99." uses a mid-dot and lowercase name; no other line does. |
| W16 | "Drying. Swipe to drop it." (`BottomChrome.swift:634`) | Only Now draws a task ghost; on any other page there is nothing to swipe. |
| W17 | Silent undos | Six of seven Undo controls say nothing afterwards. tess-voice.md example: "That set is gone. Undo brings it back." has no matching after-undo line. |

### Behaviour (16)

| # | What happens | Where |
|---|---|---|
| B1 | **Siri / Shortcuts "Undo Last Set" during a live workout** removes the set from the store but never tells `WorkoutSession`: the rest countdown and the Live Activity keep running for a set that is gone, "New best" stays in `bests` and the finish summary, the dial does not refill, and the live Undo still points at the dead record. It also undoes the whole record: after "3x10 bench 80" it removes all 3 sets, and the workout too if that phrase started it, while saying "Last set removed." | `Intents.swift:66`, `ActionEngine.swift:168` |
| B2 | Bar Undo of a captured set: `undoLastCapture` only bumps `loggedCount`, so the rest timer and Live Activity started by `seatCaptured` keep counting. Tess's reply ("Set 3. 80 x 8.") stays on screen after Undo for the rest of its 4 s. | `AppModel.swift:223-234`, `BottomChrome.swift:101` |
| B3 | The bar's line and its Undo can point at different things. The line shows `reply` first; Undo acts on `voice.note.undo` first. Capture something, then swipe a Home task done within 4 s: the line still shows the capture, and Undo reopens the task. | `BottomChrome.swift:101, 109-117` |
| B4 | Live Undo after a swap undoes the previous set (in the previous exercise) and jumps back to it. The swap is not tracked; `undoable` survives it. The comment says "the latest action first". | `WorkoutSession.swift:496-525`, `+Edit.swift:94` |
| B5 | Live Undo after a set logged elsewhere (Siri Log Next Set, Shortcuts) removes the set before it: `undoable` is stale and `canUndo` only checks its state. | `WorkoutSession.swift:395` |
| B6 | A set typed through Ask Tess in the live workout has no reachable Undo: `seatCaptured` clears `undoable`, and the bar's Undo sits under the full-screen cover. Its ghost stroke has no drop gesture either. | `WorkoutSession.swift:375`, `WorkoutModeView.swift:238` |
| B7 | Finish early never reaches Apple Health: the exporter matches only the `finishWorkout` action name, and early finishes log `finishWorkoutEarly`. And because observers fire on commit only, undoing any finish would leave the Health workout behind. | `HealthExporter.swift:17` |
| B8 | Writes with no undo at all, several destructive: delete a note (dismisses, silent), finish the shop (clears the basket, silent), start a routine or workout, finish a workout, add groceries, check items, add to routine from the Exercise page, start cooking. | rows 6, 9, 10, 13, 23-31, 34 |
| B9 | New subclass bypasses the op log, so it can never be undone or shown in history. | `ObjectPage.swift:136` |
| B10 | Skip set lives only in memory: gone on relaunch, no op, no undo. | `WorkoutSession.swift:158` |
| B11 | System writes are silent: the put-away and wrap-up notes go into `processNotes`, which no view reads. The wrap-up is two records (`FinishWorkout`, then `EndProcess`), so undoing one would leave the other. | `ProcessTable.swift:96-129`, `AppModel.swift:252` |
| B12 | No caller reads `ReplayOutcome`. A partial undo (some ops skipped as conflicts, e.g. undo "Cleared 3" after one item was re-added) says nothing and looks complete. | every Undo control |
| B13 | Undo windows disagree: Tess 4 s, capture 4 s, paste 2 s then the page leaves, recipe send 4 s, routine editor until the next change, live set until the next set, Siri reaches 300 records back. | table above |
| B14 | "Moved to tomorrow." on a task carried over from yesterday lands at 00:00 tomorrow: `MoveTask` bases on the start of today, not the task's time of day. It also reads `.now`, so `-demoTime` is ignored. | `TesseraCore/.../Tasks/Tasks.swift:117-119` |
| B15 | Dropping a ghost leaves Tess's line ("Dentist, Thursday 3 pm.") up for the rest of 4 s. Ghosts that are not tasks (groceries, notes, timers, cooking) have no surface to drop them; they just dry. | `AppModel.swift:210`, `NowPage.swift:286` |
| B16 | Take out in the routine editor uses `DeleteObject`, so siblings keep a gap in `sortIndex`; `RemoveSlot` closes up and has the right line. Undo itself is fine. | `RoutineEditor.swift:257` |

The worst is B1: the one undo built for the Lock Screen and Siri leaves a live rest timer and Live Activity for a
deleted set, keeps a PR that no longer exists, and can delete three sets and a workout while saying one set.

## 3. One rule

**Name the thing, then what happened to it. Undo answers with the same name and "taken back".**

- Every write that changes something a person can see gets one line from `TessVoice`, and every line that offers
  UNDO is about the record that UNDO reverts. No line, no UNDO; no UNDO without a line after it.
- The name is the person's word for it: "Set 3", "Dentist", "Milk", "Carbonara", "3 items". Digits, "×" for sets on
  every surface (VoiceOver reads "times").
- After Undo, the line is `<same name> taken back.` If something can't come back with it, say so in the same line:
  "Push A taken back. Health keeps its copy."
- If undo was partial: `<name> partly taken back. <what stayed> changed since.`

This keeps tess-voice.md's rules (one line, past tense, digits, under 12 words) and settles C6 in favour of "taken
back", which names the set. A small Core change makes it cheap: add a `noun(in:)` to `EngineAction` so the summary,
the UI line and the undo line come from one place, and have `TessVoice.say(record:)` build both.

### Before and after

| # | Before | After | Owner |
|---|---|---|---|
| W1, B1 | "Last set removed." | "Set 3 taken back." (and for a multi-set record: "3 bench sets taken back.") | Core (intent), Builder A (session must react) |
| W1 | "Set 3 removed." then, on Undo, "Set 3 is back as it was." | "Set 3 removed." then "Set 3 is back." (undoing a removal brings it back, so "taken back" would read wrong; edits keep "Set 2 is back as it was.") | Builder A |
| W2 | "Undone." | "Bench Press taken back." / "Move taken back." (the name from the record) | Builder A |
| W3 | "Deleted Bench Press." | "Took out Bench Press." (use `RemoveSlot`, change its summary to match the key) | Builder A, Core |
| W4 | "Added bench press to the routine." | "Added Bench Press." | Core |
| W5 | "Logged bench press 1×8 at 80 kg." | "Bench, 1 × 8 at 80. Added to today." | Core |
| W6 | "Logged 82.5 × 8." | "Set 4. 82.5 × 8." | Core |
| W7 | "Added “Dentist”." | "Dentist, Thursday 3 pm." / "Dentist, in Later." | Core |
| W8 | "Set 3. 80 x 8." (Tess) | "Set 3. 80 × 8." | Core (TesseraTess) |
| W9 | summary "Cleared Groceries" | "Cleared 3 from the basket." in both | Core |
| W10 | "Done. Next one is up." | "Dentist done. Next one is up." | Builder B |
| W10 | summary "Done: Dentist" | "Dentist done." (Home: "Done. Dentist." becomes "Dentist done.") | Core, Builder B |
| W11 | "Finished. 6 of 6 exercises." / "Saved Push A, 3 of 5 exercises" | "Push A finished. 6 of 6 exercises, 22 sets." / "Push A wrapped up. 3 of 5 exercises." | Core |
| W12 | "What's here now is kept in Backups, so this can be undone." | "Restore waiting for next open. Cancel restore takes it back." | Core |
| W13 | "This recipe is gone. Undo brings it back." | "Carbonara was deleted." (until a delete with UNDO exists) | Core |
| W14 | "Added milk" (fallback) | "Milk, on the list." (the grammar's line for the same action) | Core |
| W15 | "Logged bench press 80 × 8 · e1RM 99." | "Set 3. 80 × 8. e1RM 99." | Builder B |
| W16 | "Drying. Swipe to drop it." | "Dentist, 10 pm. Swipe it on Now to drop it." or drop the ghost and use UNDO | Builder B |
| W17 | (silent after UNDO, Home) | "Dentist taken back." | Builder B |
| W17 | (silent after UNDO, capture) | "Bench, 3 sets taken back." (replace `reply`, don't leave it) | Builder B |
| W17 | (silent after UNDO, Groceries) | "3 items taken back." | Core |
| W17 | (silent after Paste Undo) | "Carbonara taken back." | Core |
| W17 | (silent after "to buy" Undo) | "12 to buy taken back." | Core |
| W17 | (silent after live set Undo) | "Set 3 taken back." (then the set line) | Builder A |
| B11 | (put-away and wrap-up notes never shown) | "Put 2 things away. They're in Later." shown once in Tess's line | Builder B |
| B12 | (partial undo, silent) | "3 items partly taken back. Milk changed since." | Core (outcome), each UNDO owner |

### Behaviour fixes by owner

| Owner | Fix |
|---|---|
| Core | `undoLatestSet` returns the set ids it removed and how many; the intent says the count and the set number (B1). `ActionEngine` notifies observers on undo too, with the record's state, so the app and Health can react (B1, B2, B7). `HealthExporter` also matches `finishWorkoutEarly` (B7). Route `createClass` through an action (B9). `MoveTask` keeps the time of day and takes the app clock (B14). Wrap-up as one record (B11). Return `ReplayOutcome` to callers that show a line (B12). |
| Builder A | `WorkoutSession` listens for undo of any record that touched its workout and clears rest, `lastSeated`, `bests` and the top-set check, then refreshes the Live Activity (B1, B2, B5). Track the swap as the latest undoable action (B4). Give typed sets in live mode the live Undo instead of clearing it (B6). Skip set as an op, or say it's for this session only (B10). Take out through `RemoveSlot` (B16). HealthExporter is in `App/Health`; ownership to confirm. |
| Builder B | One owner for the bar's line and its UNDO: make the capture reply a `TessVoice` note carrying its records, so line and UNDO can't diverge (B3), Undo replaces the line (B2), and a dropped ghost clears it (B15). Show `processNotes` once (B11). |
| Core (Notes, Groceries, Recipes) | UNDO lines for note delete, finish shop, add groceries (B8). One Undo window: 4 s everywhere, through `TessVoice` (B13). |

## Open questions

1. "Taken back" or "undone" as the house word? This file assumes "taken back" (widget-states C6 and the Live
   Activity design use it). The routine editor says "Undone." today.
2. Should the Siri "Undo Last Set" remove one set even when the record logged three, or the whole phrase? Today it is
   the whole record. One set is what the name promises; the whole record is what the op log can do in one step.
3. Which writes deserve no line at all? Checking a grocery item, autosaving a note and starting a workout are silent
   today and probably should stay so (tess-voice rule 7). If silent, should they still be undoable from the bar?
4. Should undoing a finish delete the Health workout (needs `HKHealthStore.delete`) or keep it and say so?
5. The `docs/design/` folder the code cites (`edit-set.md`, `no-buttons.md`, `live-activity.md`, `today-on-home.md`)
   is not on master or in the shared design folder. Where do the Undo-state strings for the Live Activity live?
6. Who owns `App/Health/HealthExporter.swift` and `App/AppModel.swift`'s capture code: Builder A, Builder B or Core?
7. Is a 4 s window right for destructive writes (delete a note, finish the shop)? A longer window, or the op log's
   history on the object page, may suit them better than the bar.
