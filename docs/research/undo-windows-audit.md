# Undo windows audit (Product item X)

Traced by hand on `origin/master` at `d3494d0` (Merge #481). No build was run; line numbers are master's.
For: Core, Builder A, Builder B, Design (copy), Product.

**The rules checked.** AQ15 (`docs/product/decisions.md:150`): a new capture gets a 4 s UNDO; anything that removes or
changes something already there gets 10 s. Destructive writes (delete a note, finish the shop) keep 10 s
(`decisions.md:309`). Silent writes stay silent (checking a grocery, note autosave, starting a workout). F2: LOG AND
FINISH gets 10 s and takes back the set and the finish together ("Push A, back on.", `decisions.md:138`). Lines name the
thing first; the undo answers "X, taken back." and "Undone." goes (`decisions.md:311`, Research #158 `undo-lines.md`).
New ruling, 12:39 pm Oct 16: every UNDO stretches to 10 s while VoiceOver is on. (`accessibility.md:171` B11 proposed
12 s; the ruling supersedes it.)

**Headline.** 19 surfaces: 2 pass, 14 fail, 3 not built. No code on master reads VoiceOver state
(`UIAccessibility.isVoiceOverRunning` or `accessibilityVoiceOverEnabled` appear nowhere), so the 12:39 pm ruling is
unmet on every built surface. No surface says "X, taken back." after its own UNDO; only Siri does.

Columns: Now = window today (T = `Task.sleep` timer, D = date check, none = UNDO stays until the next change).
Exp = expected by rule. VO = VoiceOver stretch. Ops = what one UNDO takes back and whether it is an exact op-log
reversal (ids, links, order, dates come back through `ActionEngine.undo`, `ActionEngine.swift:141`; every caller
drops the `.partial` outcome, so a partial undo looks whole). Line = thing-first check.

| Id | Action | Window set at | Now | Exp | VO | Ops | Line | Overall |
|---|---|---|---|---|---|---|---|---|
| X1 | Home queue swipe done | `HomeQueue.swift:34` (said at `:452`) | 10 T | 10 | no | one SetTaskDone, exact | "Call Mum, done." pass; undo says nothing, fail | FAIL |
| X2 | Now page done | `HomeQueue.swift:34` (said at `NowPage.swift:196`) | 10 T | 10 | no | one SetTaskDone, exact | "Done. Next one is up." fail | FAIL |
| X3 | Task move (tomorrow, next week) | `HomeQueue.swift:34` (said at `:473`) | 10 T | 10 | no | one MoveTask, exact | "Moved to tomorrow." fail | FAIL |
| X4 | Set log, live workout | `LiveTessCorner.swift:40` (UNDO leaves with the line) | 4 T | 4 | no | one set (an edit first, `WorkoutSession+Edit.swift:93`), exact | set undo says nothing; edit undo "Set 2 is back as it was." | FAIL |
| X5 | Workout finish | `WorkoutSession.swift:433` (LOG AND FINISH only) | 10 D; hold finish: none | 10 | no | finish + set, two reversals; the Health workout is not deleted (no undo hook in `App/Health/`) | "Push A, back on." pass | FAIL |
| X6 | Routines page: make, move, drop, mode | `RoutinesPage.swift:255` | none | 4 make, 10 others | no | make = two ops undone together, exact | "Taken back." fail | FAIL |
| X7 | Routine editor | `RoutineEditor.swift:215` | none | 10 | no | the last change only, exact | "Undone." fail | FAIL |
| X8 | Groceries clear basket | `HomeQueue.swift:34` (said at `GroceriesView.swift:260`) | 10 T | 10 | no | one ClearDoneItems, exact | "Cleared 3 from the basket." fail | FAIL |
| X9 | Recipe to Groceries (swipe) | `RecipePage.swift:193` | 4 T | 4 (10 if a meal plan add) | no | one AddRecipeToGroceries, exact | "12 to buy, in Groceries" fail | FAIL |
| X10 | Recipe paste save | `PasteRecipe.swift:216` (page leaves after 2 s) | 2 T | 4 | no | one CreateRecipe, exact | "Carbonara saved." pass; undo says nothing | FAIL |
| X11 | Notes: delete note | `NoteEditor.swift:170` | no UNDO | 10 | no | DeleteObject, no way back on screen | none | FAIL |
| X12 | Lists reset, put away, remove row (NE11) | not built (no `Features/Lists/`) | n/a | 10 | n/a | n/a | "Rice, removed." drawn | NOT BUILT |
| X13 | Tess capture receipts | ghost `AppModel.swift:175` (2 s) + UNDO `AppModel.swift:276` (4 s after commit); line `BottomChrome.swift:720` (4 s) | about 6 T | 4 | no | every op from one phrase, exact (`AppModel.swift:298`) | reply lines vary; undo says nothing | FAIL |
| X14 | Overnight wrap-up ("Push A, no sets, not saved.") | `HomeQueue.swift:34` (said at `BottomChrome.swift:138`) | 10 T | 10 | no | the wrap-up only, though the line is joined with the 4 am roll line | thing first pass; one UNDO under two things | FAIL |
| X15 | Siri / Shortcuts "Undo Last Set" | `Intents.swift:66` | none (any time in an open workout) | n/a | n/a | one set; a multi-set phrase gets a new DeleteObject, not a reversal (`ActionEngine.swift:200`) | "Set 3 taken back." pass | PASS |
| X16 | Live Activity undo | not built (`Shared/RestIntents.swift` has no undo intent) | n/a | 4 | n/a | n/a | n/a | NOT BUILT |
| X17 | Memory forget, forget everything | engine only: `TessMemory.swift:287`, redaction sweep `> 10` at `:380`; no page on master | n/a | 10 | n/a | one delete, exact until the sweep redacts | "Gym days, forgotten." pass | NOT BUILT |
| X18 | Backup: restore; stop using the folder | restore: staged until next open, "Cancel restore" (`BackupView.swift:218`); folder `BackupView.swift:291` | restore none; folder 10 T | 10 | no | folder: bookmark put back, outside the op log; restore: the old store kept in Backups | "Copies stay on this iPhone only now." fail; "The folder is back." pass | FAIL |
| X19 | Settings: remove Claude key | `ClaudeSection.swift:381` | 10 T | 10 | no | deferred Keychain delete, outside the op log | "Claude key removed." / "Claude key is back." pass | PASS (VO aside) |

X19 and X15 pass on window and line; X19 is already 10 s, so the VoiceOver stretch changes nothing there.
X4 counts as a fail for its lines only. Other settings changes (Tess asks Claude, Looks) have no UNDO; they are
reversed by doing them again, like the other silent writes.

## Cross-checks

- **One constant: no.** 4 s is hard-coded at `HomeQueue.swift:34`, `AppModel.swift:276`, `BottomChrome.swift:720`,
  `LiveTessCorner.swift:40`, `WorkoutModeView.swift:119`, `RecipePage.swift:193`; 10 s at `HomeQueue.swift:34`,
  `WorkoutSession.swift:433`, `BackupView.swift:291`, `ClaudeSection.swift:381`, `TessMemory.swift:380`. The
  VoiceOver stretch needs one `UndoWindow.seconds(for:)` that all of them read.
- **Backgrounding and lock.** Every window is a `Task.sleep` or a date check, so it keeps running while the app is
  backgrounded or the screen is locked; nothing pauses. Back after 10 s, the UNDO is gone. Settings goes further: it
  completes the key removal at once on background (`ClaudeSection.swift:108`, QA C2), cutting the window short.
- **Reduce Motion.** No window changes with it (correct). The voice ghost's dry time drops from 3 s to 0.8 s
  (`BottomChrome.swift:651`), so the swipe-away chance before a spoken capture commits is shorter.
- **The 4 am turn.** X14 puts one UNDO under the joined roll and wrap-up lines; it reverts only the wrap-up. A Home
  note open across 4 am still reverts its own op exactly (op-log), but the line can now say "tomorrow" about today.
  The memory sweep reads `Date.now`, not `AppClock`, so it ignores `-demoTime`.
- **Two undos racing.** `BottomChrome.canUndo` and `undo()` (`BottomChrome.swift:728-744`) prefer `TessVoice.note`:
  with a Home done (10 s) still open, a new capture shows its own line while UNDO reverts the Home task. That breaks
  "an UNDO key always reverts what its line names". A second Home action replaces the first note, so the first UNDO
  is lost quietly. Routines (X6, X7) keep UNDO with no window, so it can reach a change made long ago, after other
  writes; the guarded replay skips changed ops and nobody reads the `.partial` outcome.
- **Haptics, one per moment.** Good: Home note undo `.decrease` (`BottomChrome.swift:132`), workout `.undo`
  (`WorkoutModeView.swift:204`), Routines `.undo`. Missing: capture undo (the `else` branch never bumps `undos`),
  Groceries' own UNDO (`GroceriesView.swift:640`), Backup, Settings. Wrong: Routine editor plays `.selection`. Likely
  wrong (unverified): `RecipePage.swift:142` and `PasteRecipe.swift:137` fire `.success` on any trigger change,
  so an UNDO (and the 4 s expiry on the recipe page) plays a success tap.

## Top fails

1. **VoiceOver stretch missing everywhere** (X1 to X10, X13, X14, X18): one shared window constant that reads
   VoiceOver, plus an announcement of the line. Core for the constant, then each builder wires it.
2. **Capture UNDO hijacked by a Home note** (X13 race): Builder B (`BottomChrome.swift:728`).
3. **No "X, taken back." line after any in-app UNDO**; "Undone." and "Taken back." still ship (X6, X7): Builder A for
   training, Builder B for Home and Groceries.
4. **Notes delete has no UNDO** (X11) and hold-to-finish has none (X5): Builder B, Builder A.
5. **Undoing a finish leaves the Health workout** (X5): Core (`App/Health/HealthExporter.swift`).
6. **Thing-last lines** on Now, task move, basket clear, recipe send (X2, X3, X8, X9): Builder B, Design for copy.
7. **Windows off rule**: paste 2 s (X10), capture about 6 s (X13), Routines open-ended (X6, X7): Builder B, Builder A.
8. **One UNDO under two lines at 4 am** (X14): Core (`ProcessTable` notes) and Builder B.

## Questions for Product

1. Should a window pause while the app is backgrounded or the screen is locked, or keep counting as today?
2. Does Settings' early commit on background (QA C2) stand under the VoiceOver ruling?
3. Recipe to Groceries: 4 s as a new add, or 10 s like a meal plan add ("Tacos, 2 added.", groceries-ai-acceptance)?
4. Does a capture's 4 s count from the line or from the ghost drying (today about 6 s from the line)?
5. Siri's "Undo Last Set" has no window; keep it that way?
6. Does plain hold-to-finish get the 10 s UNDO too, or only LOG AND FINISH?
7. Unsure points: X14's split behaviour at 4 am and the recipe `.success` haptic need a run on the simulator.
