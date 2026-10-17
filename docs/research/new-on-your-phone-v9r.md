# New on your phone: release 56dd028

Release 1 of release-on-merge. Everything below is new since a36b161, the build on your phone now.

- **Plan my day** is on Home from 8 am to 9 pm when you have tasks with no time. Swipe a row right to keep it, left to skip it, or hold "Start with ..." to keep them all. Nothing is saved until you keep it.
- **Times** read 12-hour everywhere, like "6:30 pm" and "7 pm": Home's list, the rest timer on the Lock Screen, the workout finish and Tess's lines.
- **Late nights** count on your day until 4 am. A workout from 11:40 pm to 12:50 am reads "Friday", and Training says "done tonight" or "done early this morning".
- **Lines after a change** name the thing first: "Bench press, moved to 3.", "Push A, taken back.", "Set 3 logged.", "Sets 2 to 4, 85 kg."
- **The Day log** says "best" when a set beats your best: "Push A, 52 min. Bench 82.5 × 8, best."
- **Review** counts tasks done and cooks on the day they happened, where you were, so your trip week reads right. A cook shows on the day it finished, with its length: "Cooked overnight oats, 6 h 55 min".
- **The Resume key's** ink line fills by each exercise's planned sets, not 3 for every exercise.
- **Tess** stretches once on Home the first time you open the app each day.
- **Siri** asks for Face ID before Add a Task, Tell Tess, Log a Set, Start and Finish. The Lock Screen's Done and UNDO still work without unlocking.
- **Siri keeps money and body facts private**: "weighed 82.2" to Add a Task saves a private note and says only "Private note, kept."
- **"paid rent 2100 fri"** is a private note on Friday, in the Ask bar and from Siri.
- **"feeling sick" and "unwell"** stay on the phone as private notes. "sick of this" stays plain.
- **A question with a secret** in the Ask bar, like "door code 4417?", saves nothing and answers "It's in your private notes."
- **"@Private note"** in a new note no longer links to a private note.
- **Private notes** in the Notes list show only "Private note" and the time, and VoiceOver reads only that.
- **VoiceOver** says what a hold key does, like "Finishes the workout", not "Touch and hold".
- **Not yet fixed:** a note written before a36b161 can still show its first line in the Day log.
- **Not yet fixed:** a private note or Tess memory opened through the object pages can still show its words, and a note that linked "@Private note" before this release still links to it.
- **Not yet fixed:** type secrets only into the Ask bar. The Groceries Add line and routine names don't hide them yet.
- **Not yet fixed:** "is 82.4 good?" in the Ask bar is saved as a task with the number in it. Swipe it to drop it.
- **Your data:** this release is still Catalog v9, so nothing you have changes.
- **Save a copy first:** Review, then The week, then Backups, SAVE A COPY. Save it outside the Backups folder and name it "Before a36b161".
- **The way back** is a36b161. It opens your data just as it does today.
- **Never install 7b321d2 again.**

## Team appendix: the full list

Release 56dd02889727e2dec8adf249eda7e9fb320e363e (master at the #544 merge, 2:55 pm PT Fri Oct 16), compared with
a36b161b7294596848a319c0cc0fc50a3b25f2ee (Catalog v9, on his phone). First release under release-on-merge (decisions
3:03 pm, item 4). Read by hand from `git log --first-parent a36b161..56dd028` (60 merges) and each app merge's diff;
nothing was built or run. File:line is at 56dd028. 14 merges touch app or engine code: #403, #504, #507, #508,
#512, #529, #534, #544, #546, #547, #548, #551, #552, #558. The other 46 are docs, QA reviews or scripts (#502,
#509, #511 are scripts/ai) and never trigger a release.

QA's readiness line (`ops/board/qa.md:7`, 3:07 pm) calls 56dd028 CLEAR, with QA PASS at each app PR's merged head:
#403 15160e0, #504 7f37de8, #507 90c9833, #508 ed30430, #512 04eda7c, #529 ffaa0b2, #534 dfe5801, #547 34359e1,
#548 3179952, #551 5c22981, #558 02c59a0, #546 84ad7dc, #552 4af772e, #544 6a04f07 (plus master merge f4028cc).

**Your data.** No catalog or migration change: `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:350` reads
`version: 9`, and `git diff a36b161 56dd028 -- TesseraCore/Sources/TesseraCore/Model TesseraCore/Sources/TesseraCore/Catalog`
touches only `Models.swift` (3 lines: `OpRecord.receipt` at `Models.swift:522`, a plain Swift property with no
`didSet`, documented "Spoken only: never stored"). `TesseraDatabaseSchema.swift` is unchanged; its migrations are still
v1, v2, v3 (`:36`, `:70`, `:77`). Step 0: SAVE A COPY outside Backups, named "Before a36b161", and checked; the a36b161
copy is never deleted (decisions 3:03 pm, item 2). Builder A installs in place. The way back is a36b161, installed
over the top; both are Catalog v9, so it opens his data with no launch note. Never 7b321d2, never anything older
than a36b161.

### Merged in this release

**Home and Plan my day**
- **Plan my day as a state of Home** (#529): `Features/Home/HomePlan.swift` (new). The offer opens 8 am to 9 pm
  (`HomePlan.swift:74`), only with no workout running, no unfinished ledger and no timed task within 15 minutes
  (`Features/Home/NowPage.swift:33-35`, `planNow` at `:34`). Rows swipe right to keep (one `MoveTask` with UNDO) or left to skip
  (nothing written); the hold "Start with <first>" keeps the rest, "Plan kept. <first> is up." with a 10 s UNDO
  (`HomePlan.swift:146`, `:171-198`, line at `:186`; `NowPage.swift:189-202`). Swiping the hero left spends the offer until tomorrow.
  Claude wording is OFF: `App/AppModel.swift:64` `planWordingReady = false`, checked at `HomePlan.swift:115`, so no
  call is made and "Via Claude" never shows. `TessVoice.say(takeBack:)` gives the plan a 10 s UNDO
  (`Features/Home/HomeQueue.swift`; `Features/Command/BottomChrome.swift:731-742`). Demo data adds three undated tasks
  (`Features/Demo/DemoData.swift`, simulator only).
- **Resume key progress** reads `targetSets` (R17; #546): `NowPage.swift:208`, `:214-218`.

**Time words**
- **One 12-hour house time** (#507): `TesseraCore/Sources/TesseraCore/Format/HouseTime.swift:6`, used by
  `App/AppClock.swift:48` (`Format.clock`, so Home's queue no longer reads "08:15"), `HomeLines.swift:273` ("Tacos at
  7 pm"), `NowRanker.swift:336` ("since 6:02 pm"), `DayStory.swift` `sentenceTime`. Home queue time sits on the
  title's first baseline (`HomeQueue.swift:345-378`, baseline at `:348`, time at `:369`).
- **His 4 am day for weekdays and memory** (#507): `TessMemory.swift:93`, `TessMemory+Turnover.swift:190`,
  `TessGrammar.swift:754` ("thu" said at 1 am Friday is today).
- **Builder A's time words** (#546): `Shared/HouseClock.swift` (new, shared with the widget);
  `Widgets/RestLiveActivity.swift:243` (Always-On "Ready at 6:26 pm"); `Features/Workout/WorkoutFinishView.swift:97`,
  `:101` ("Friday, 11:40 pm to 12:50 am", weekday of his day); `Features/Home/TrainingPage.swift:316`, `:663`
  ("done early this morning" 4 to 7 am, "done tonight" 9 pm to 4 am).

**Receipts, thing first**
- **App receipts** (#547): `Features/Plans/Receipts.swift:8`, `:30` (routine edits: "Bench press, added.", ", swapped
  in.", ", moved to 3.", ", removed."); UNDO lines "Push A, taken back." (`RoutineEditor.swift:222`,
  `RoutinesPage.swift:274`); "Set 3 logged." (`Features/Workout/WorkoutParts.swift:244`); swap panel "Sets 2 to 4,
  85 kg." (`SwapPanel.swift:121`); Ask bar log "Bench press 82.5 × 8, logged. e1RM 105." (`CaptureParts.swift:239-243`).
- **Engine receipts for Tess's fallbacks** (#512): `EngineAction.swift:15-19`; tasks "Call mom, tomorrow at 6:30 pm",
  ", in Later" (`Tasks.swift:144-160`), ", done" / ", open again" (`TrainingActions.swift:484`); lists "Films, made",
  "Eggs, added to Packing", ", got" (`Lists.swift:97`, `:151`, `:191`); groceries "Oat milk and eggs, on Groceries"
  (`Groceries.swift:434`). Read by `ClaudeTessModel.swift:129` and `TessModelCapture.swift:44`.

**Training and Review**
- **Day log best** (#504): `DayStory.swift:225` ends ", best."; Review's tapped day still reads "Bench best"
  (`Features/Home/ReviewWeek.swift:112`). Built when shown, so older days read "best" too.
- **Review by where it happened** (R11, trip bands; #552): `ReviewWeek.swift:55-58` reads
  `WeekFactsBuilder.tasksDoneByDay()` / `cooksByDay()` (`WeekFacts.swift:202`, `:215`, each item's own zone); The week
  page's total and good days use the same count (`Features/Review/ReviewView.swift:83-92`). A cook files on its finish
  day in the finish's zone, with "6 h 55 min" style length (`DayStory.swift:242-253`, length at `:250`).

**Privacy**
- **Siri shares the Bar's privacy rule** (R7 P14, R2 HW13 in part, R3 HW9; #534): `TesseraIntents/Intents.swift:156-176`
  (Add a Task runs `TessGrammar.privateParse`, `TessGrammar+Privacy.swift:18-41`; a private note answers "Private note,
  kept.", a private task title "Task added."); Tell Tess answers "Saved." for private words (`Intents.swift:196-201`);
  empty Add a Task asks "What's the task?" (`:151`). Face ID on Log a Set, Start, Finish, Add a Task, Tell Tess
  (`:11`, `:114`, `:135`, `:183`, and `:91`); Lock Screen Done and UNDO exempt (`:40-41`, `:68-69`).
- **Sick words with the slang mask** (R1 HW19; #534): `PrivateFacts.swift:55-59` (CR1 mask), `:72-75` ("sick",
  "unwell"), `:86-88`.
- **Body before dated log** (R4 HW11; #534): `TessGrammar.swift:132-139`. "paid rent 2100 fri" is a private dated note
  (F6; `TessGrammar.swift:116-127`, `TessGrammar+Privacy.swift:39-40`). Money and body skip the miss log
  (`TessCaptureEngine.swift:60`).
- **Pasted key** (#534): split keys come out whole (`ClaudeKeyGuard.swift:9`); the Notes key line stays until his next
  edit (`Features/Notes/NoteEditor.swift:28`, `:136-146`).
- **The command interpreter's walls** (Core 0ah; #544): a "?" phrase with a secret answers "It's in your private
  notes.", money or body "That stays on this phone.", saving nothing; otherwise a private note
  (`Features/Command/CaptureParts.swift:184-199`). Paste Recipe's miss log skips money and body
  (`Features/Recipes/PasteRecipe.swift:206`).
- **"@Private note" never resolves to a private note** (R8 Core half, PN-MENTION; #551):
  `TesseraCore/Sources/TesseraCore/Notes/Notes.swift:42-46`. Links are written when a note is saved
  (`Notes.swift:118-122`), so a link made before this release stays until that note is edited.
- **Private note rows** (R5 N13; #508): `Features/Notes/NotesView.swift:289` and the row's combined VoiceOver label.

**Tess**
- **Tess wakes with him** (#558): first foreground of his 4 am day on Home, once (`Features/Tess/SoulRouter.swift:223`,
  key `tess.wokeOn` `:79`); a 4 s wake (`SoulWake.swift:7`) with one stretch, none under Reduce Motion or Low Power
  (`TessSoul.swift`). Lids only matter with eyes, which stay off. Leaving the app now sends `.backgrounded`
  (`App/TesseraApp.swift:86`) and a cold launch counts as a foreground (`App/AppModel.swift:155`). An ask during the
  gather waits for it (`SoulRouter.swift:165`, `:250`).
- **Tess's eyes, inert** (R10; #403): only the simulator's `-tessEyes` flag turns them on (`App/AppModel.swift:117-120`);
  nothing on the phone does.

**Accessibility**
- **Hold-key hints say the result** (#546): `DesignSystem/Paint.swift` `PaintKey.hint`; "Finishes the workout"
  (`ExerciseStrip.swift:112`, `WorkoutModeView.swift:668`), "Logs the set" (`WorkoutModeView.swift:627`), "Keeps the
  plan" (`NowPage.swift:191`), "Finishes the task" (`NowPage.swift:226`), "Finishes the shop", "Clears the basket"
  (`GroceriesView.swift:132`, `:607`), "Restores this backup" (`BackupView.swift:197`).

**Nothing he can see**
- #548: one code comment in `Features/Workout/WorkoutParts.swift` loses a literal. No behavior change.

### Still open at 56dd028 (his "Not yet fixed" lines)
- **N15 (R6):** `DayStory.swift:349-353` prints "Note: <title>" for a note not marked private; no launch pass marks
  pre-#422 notes. Core 0aa.
- **Private-field mask (R18), with R8's Builder B half:** `Features/Objects/ObjectPage.swift` is unchanged since
  a36b161: `:227-228` heading and class line, `:342-360` PropertyList prints every field, `:255-262` Linked from names
  the source. Plus pre-release stored mention links (above). Core 0ai.
- **Other boxes:** no `SecretWords`, `PrivateFacts` or key check in `Features/Groceries`, `Features/Plans` or
  `Groceries.swift` `AddGroceries` (`:403`); routine "Name it" is `RoutinesPage.swift:141`. Ask bar and Siri are walled.
- **Bare-number body wall (R19):** "is 82.4 good?" is not body-shaped (`PrivateFacts.swift:104-108`), so the "?" route
  (`BottomChrome.swift:509`) reaches `CaptureParts.swift:200-204` and saves a task "Is 82.4 good?". Core 0ai; #564
  (BottomChrome answer, QA PASS bf0ba93) is open, not in this release.

### Not in this release (riders from next-build-v9r.md section 0)
- R6 N15 (Core 0aa)
- R8 Builder B half (ObjectPage), folded into R18
- R12 SAVE A COPY "Before update <day>" (Core 0af; `BackupKeeper.swift:170` still "Tessera-<day>")
- R13 Backups-folder warning (B 0t)
- R14 DST DS8 / DS29 / DS36 (Core 0ag), due before the Oct 31 night
- R15 Review foot line out of Tess's band (B 0x)
- R16 Routines Tess line and "Add an exercise" out of the band (A 0q)
- R18 private-field mask (Core 0ai)
- R19 bare-number body wall (Core 0ai)
- R2 in part: Siri says "Private note, kept.", not "Body weight logged."
- Also not in: #407 (v10), #564, #553 (FIX FIRST), F1 to F4, F7 to F9, F12, the eyes setting.

**Things to try first**
1. Between 8 am and 9 pm with an undated task, open Home: swipe one plan row right, then UNDO.
2. In ROUTINES, drag an exercise to third in Push A, then UNDO: "Bench press, moved to 3.", then "Push A, taken back."
3. In the Ask bar, type "door code 4417?": "It's in your private notes." and nothing new in Notes or Home.
4. Open Review, The week: the task and cook counts match the Day log.

### Gates for release 56dd028

QA PASS at each merged head (`ops/board/qa.md:7`, RELEASE GATE: CLEAR). Design PASS, from Design's own verdict log: #403, #504, #507, #508 and #512 (Design's #320-#512 run), #529 at ffaa0b2, #534 at d45600e, #544 at 6a04f07, #546 at 84ad7dc, #547 at 34359e1, #551 at 5c22981, #552 at 4af772e, #558 at 02c59a0 (plus Lab PASS, SSIM 0.959). #548 only rewords a code comment. Design's walk of what's new runs after the install (decisions 3:03), and any fix rides the next release.
