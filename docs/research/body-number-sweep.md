# Bare body numbers: every path to PrivateFacts, checked for the 2:56 band

For: Product's board, item BK, for Core 0ai. Owner: Research lab. Oct 16, 2026, read on origin/master 56dd028
(#544, core/command-walls, merged). This extends [`input-paths-walls.md`](input-paths-walls.md) (AX, 32 paths on
f874295) rather than redoing it; the AX row each path came from is in the last column. Walls UI rows BN01 to BN10 are
in [`walls-ui-test-spec.md`](walls-ui-test-spec.md) section 12. Every phrase here is made up.

**The decision (Product, 2:56 pm, Core 0ai).** "is 82.4 good?" is walled. A bare number within 10% of his last logged
weight is a body fact even with no day word. With no weight logged, a bare decimal is walled only next to a body word
(weight, weigh, kg, lb, body fat, BMI). Traps that stay plain: "is 3.5 good?", "is 120 good?" with a last weight of 82,
"rate this 8.5", and set notation like "bench 82.5 x 5". For a last weight of 82 kg the band is 73.8 to 90.2 kg,
inclusive.

**What master does today.** `PrivateFacts.isBodyShaped` (`PrivateFacts.swift:81-109`) takes only the phrase. A bare
decimal is walled only when every other word is a day word (`:105-111`), so "82.4?" is walled and "is 82.4 good?" is
not ("good" is not in `dayWords`, `:63-64`). A whole number with no unit is never walled by that branch. "weight" sits in
`dayWords`, not `weighWords` (`:61`), and "bmi" is in no list, so BN04 ("my weight is 82.4, good?") is plain.

## 1. Where body weight lives

Nowhere as a number. There is no body weight class, action or field on master or on any branch (no `LogBodyWeight`,
`BodyWeight` or `bodyMass` read in any Swift file on any of the 222 remote branches).

- **Private notes, today.** A weigh-in typed to Tess ("82.4 this morning", "weighed 82.2") is a body fact, so
  `parseBodyFact` (`TessGrammar+Privacy.swift:52-56`) files it as `CreateNote(body:, isPrivate: true)`
  (`TessCaptureEngine.swift:304-310`). The number survives only as text in the note's `body` field, under the title
  "Private note" (`Notes.swift:116-122`). This is the only place a "last logged weight" can be read from on master.
- **M3 body weight entry, not built.** `LogBodyWeight` is specified in `fixtures/body-weight.md` (M850 onward,
  "Body weight logged. 82.4 kg.") and owned by Core 0ac HW13 and Builder A 0m (`docs/ops/board/core.md:175-177`,
  `ios-a.md:33`). Decisions 1:58 pm (4): "82.4 this morning" becomes a body weight entry only when within 10% of his
  last weight.
- **Apple Health, not built.** `HealthExporter.swift:42` asks to share workouts only and reads nothing. Decisions
  2:11 pm (3): Health weights stay in memory only, never in Tessera's store. TesseraCore has no HealthKit, so a Health
  weight would have to be handed in from the app.
- **The test seam.** Section 12 says `-wallsSeedPrivate` "writes one body weight entry". There is no such entry type,
  so until M3 lands the seam can only write a private note such as "82 kg this morning".

## 2. The paths

**Through?** = does the path reach `isBodyShaped` (directly or through `isWalled` / `isPrivateTitle`).
**Weight in reach?** = does the call site already hold the store, the engine or a `TessContext`, so a last-weight
lookup or a context field needs no new signature on any function between the entry and PrivateFacts.

Verdicts: **covered** (through, and the weight is in reach: a one-argument change at the call line once PrivateFacts
takes the weight), **threading** (through, but a function in between needs a new parameter), **bypass** (never
reaches PrivateFacts), **no text**, **not built**.

| ID | Path | Entry (file:line) | Calls PrivateFacts today | Weight in reach? | 2:56 band after 0ai (only `isBodyShaped` changed) | Verdict | AX |
|---|---|---|---|---|---|---|---|
| BK1 | **Ask bar, ending "?"** (and phrases with "best") | `BottomChrome.swift:374` field, `commit` `:501`, split `:509-510`, `CommandInterpreter.run` `CaptureParts.swift:167` | `isWalled` at `CaptureParts.swift:190` (since #544) | Yes: `model.store` | Applies once `:190` passes the weight. Today "is 82.4 good?" is not walled, so it becomes the task "Is 82.4 good?" (`:200-201`) on Home. Walled, it answers "That stays on this phone." (`:192`) and saves nothing. **This is BN01 to BN10's surface, and it never calls Claude** (see pick 5) | covered | 2 |
| BK2 | **Ask bar, plain: router gate** | `BottomChrome.swift:510` to `AppModel.ask` `AppModel.swift:236-241` to `TessCaptureEngine.capture` `:28` to `TessRouter.run` | `isWalled` at `TessModel.swift:77` (skips the Claude route) | Yes: `engine`, `request.context` | Applies if the weight rides in `TessContext` or the router looks it up. Only decides "no Claude"; the grammar and the phone's model still read the phrase | covered | 5, 6 |
| BK3 | **Ask bar, plain: grammar files a body fact privately** | `TessGrammar.parse` `TessGrammar.swift:62`; `walledLog` `:136-138`; `parseTaskOrBodyFact` `:158-160`; `parseBodyFact` `TessGrammar+Privacy.swift:52-53` | `isBodyShaped` at `TessGrammar+Privacy.swift:53` | Yes: `TessGrammar` holds `store`; `context` is passed to `parse` | Applies. "how's 76 looking" becomes a private note instead of a task. A "?" phrase returns nil before this (`:82`), so a question is never filed, only walled from Claude (BK2) | covered | 5 |
| BK4 | **Task read-back in Tess's line** | `TessCaptureEngine.swift:298-303` (`.task` case) | `isPrivateTitle` at `:300` | Yes: `engine`, `context` | Applies: "Task added for Fri." instead of the title | covered | new |
| BK5 | **Capture miss log** | `TessCaptureEngine.swift:58-63` | `isWalled` at `:60` | Yes: `engine`, `context` | Applies: a walled miss is not written to `capture-misses.jsonl` | covered | 6 |
| BK6 | **Speak** (Tess's mic) | `SpeechListener.swift:122`; `finishListening` `BottomChrome.swift:619`, `commit(clean)` `:658` | As BK1 to BK5 (same `commit`) | Yes | Inherits BK1 to BK5. The recognizer adds "?" to a spoken question, so "is eighty two point four good" lands on BK1 | covered | 4 |
| BK7 | **Live workout ask field** | `WorkoutParts.swift:361`, `WorkoutModeView.swift:275-280` to `model.ask` | As BK2 to BK5 (no "?" branch here) | Yes; `context.entry` is the exercise in focus | Inherits BK2 to BK5. **This is where a bare-number question really reaches Claude today**: the grammar returns nil for a question (`TessGrammar.swift:82`) and the router sends it on. Over-wall risk: the bar weight is often inside his band (see pick 6) | covered | 13 |
| BK8 | **Siri and Shortcuts: Tell Tess** | `Intents.swift:197` (capture pipeline, `commitImmediately`) | As BK2 to BK5, plus `isPrivateTitle(phrase)` at `Intents.swift:199` for the read-back | Yes: `runtime.engine` | Applies at both. Claude never runs for Siri (`ClaudeTessModel.swift:53`), so the band only changes what is filed and said back ("Saved.") | covered | 12 |
| BK9 | **Siri and Shortcuts: Add a Task** | `CreateTaskIntent.add` `Intents.swift:160-177` | `isBodyShaped` via `privateParse` (`TessGrammar+Privacy.swift:30`); `isPrivateTitle` at `Intents.swift:174` | Yes: `engine` | Applies: a bare number in the band becomes a private note ("Private note, kept.") | covered | 11 |
| BK10 | **Claude route, second wall** | `ClaudeTessModel.run` `ClaudeTessModel.swift:51` | `isWalled` at `:54` | Yes: `engine`, `request.context` | Applies | covered | 18 |
| BK11 | **Claude retry inbox** (queue and drain) | `TessInbox.add` `TessInbox.swift:25-30`; drain `:60-66` | `isWalled` at `:30` and `:65` | Yes: `store` / `engine` | Applies at both; a phrase queued before 0ai is dropped on drain | covered | 18 |
| BK12 | **Paste a recipe: miss log** | `PasteRecipe.swift:67` editor, `save()` `:200-207` | `isWalled` at `:206` | Yes: `model.store` | Applies to the miss line only (see BK21 for what is saved) | covered | 14 |
| BK13 | **Plan my day: what goes to Claude** | `HomePlan.swift:113-118` to `PlanPack.init` (`PlanWording.swift:51`), `packTitle` `:41-46`, `otherNames` `:164` | `isWalled` via `PlanPack.isPrivate` at `PlanWording.swift:37-39` | **No.** `PlanPack.init` and `isPrivate` are pure (titles only) | Needs `PlanPack.init(..., lastWeightKg:)` and a static `isPrivate(_:lastWeightKg:)`. Wording is off today (`HomePlan.swift:115`, `planWordingReady`), so no call is made yet. A task already titled "Is 82.4 good?" (BK1 today) would go as "task" once threaded | threading | 22 |
| BK14 | Ask bar "?" pre-check (**branch only**, `ios/question-walls` bf0ba93, not merged) | `BottomChrome.swift:509-513` on the branch | `isWalled` in the view | Yes: `model` | Applies once passed the weight; sends a walled "?" phrase to Tess instead of `CommandInterpreter` | covered (not counted) | new |
| BK15 | **On-device model writes** | `TessModelCapture.swift:9` (`LanguageModelSession` `:27`); the router lets it read walled phrases (`TessModel.swift:78-79`) | None on the titles it writes | Engine at write time | No. 0ai's engine wall (decisions 2:06 pm) is where this gets a check | bypass | 8 |
| BK16 | **Notes page writing line** | `NotesView.swift:143`, `write()` `:118-127` to `CreateNote` (`Notes.swift:84`) | None (secret words only, `Notes.swift:111`) | `model.store` | No: "82.4 is good?" becomes a plain note titled with the number. Core 0aa | bypass | 9 |
| BK17 | **Note editor, heading and body** | `NoteEditor.swift:46`, `:62`, `save()` `:162-172` to `EditNote` (`Notes.swift:141`) | None | `model.store` | No. Core 0aa | bypass | 10 |
| BK18 | **Ask bar "note:"** | `parseNote` `TessGrammar.swift:345-350`, run at `:74` before any body check | None | `store` | No: "note: 82.4 this morning" is a plain note today. Core 0aa | bypass | 7 |
| BK19 | **Groceries Add line** | `GroceriesView.swift:365`, `add()` `:199-203` to `AddGroceries` (`Groceries.swift:403`, apply `:415`) to `AddListItem` (`Groceries.swift:243`) | None | `model.store` | No. 0ai's engine wall plus Builder B 0w | bypass | 1 |
| BK20 | **Routines "Name it"** | `RoutinesPage.swift:110`, `make()` `:141-144` to `CreateRoutine` (`PlanActions.swift:5`) | None | `model.store` | No. 0ai engine wall plus Builder A 0o. The name shows in Siri's picker and the Live Activity, which never call `isPrivateTitle` | bypass | 3 |
| BK21 | **Paste a recipe: what is saved** | `PasteRecipe.swift:200-202` to `CreateRecipe` (`Recipes.swift:122`) | None on title or lines (secret lines are cut, `Recipes.swift:162-174`) | `model.store` | No | bypass | 14 |
| BK22 | **Tess memory: RememberFact** | `RememberFact` `TessMemory.swift:171`, screen `TessMemoryScreen.refusal` `:135`, called at `:226`; reached through the action registry (`ActionRegistry.swift:113`) by the model and Claude tools | None: its own `healthWords` / `healthValueWords` lists (`TessMemory.swift:104-107`) | Engine at write time | No. A measured value with a unit or weigh word is refused by its own screen; a bare number with no health word is not | bypass | follow-on |
| BK23 | **Memory turnover** (yesterday's Day log lines) | `TessMemory+Turnover.swift:67` (secret words), `:104` (`TessMemoryScreen.refusal`) | None | `engine` | No: "done is 82.4 good" from BK1's task would become a memory line. Core 0ac | bypass | follow-on |
| BK24 | **Model and Claude tool writes** | `TessTools.swift:178` (`CreateList`), `:207` (`CreateRecipe`), `:314` (`AddListItem`) | None at the write; the phrase was gated at BK2 / BK10 | Engine | No. Claude only sees a phrase that passed BK10, so the band at BK10 covers Claude; the phone's model is BK15 | bypass | new |
| BK25 | **Backup restore** | `BackupView.swift:173-175`, `restore(from:)` `:239` | None (the whole store comes back as it was) | n/a | No. Restores titles as saved; the weight lookup would read the restored store | bypass | new |
| BK26 | **RenameObject** | `TrainingActions.swift:492`; no caller in `App/` or `Features/` | None | Engine | No; dormant. Decisions 2:22 pm: a generic rename never retitles a private note | bypass | 29 |
| BK27 | Workout weight field | `WeightField.swift:25`, `commit` `:64-72` | n/a, a `Double` only | | Must never be walled: it is the bar | no text | 21 |
| BK28 | Settings, Claude key | `ClaudeSection.swift:247` (SecureField) | n/a | | | no text | 17 |
| BK29 | Shortcuts: Log a Set, Start Routine, Finish, Undo | `Intents.swift:9-131` | n/a, numbers and picks | | | no text | 19 |
| BK30 | Live Activity buttons | `RestLiveActivity.swift`, `RestIntents.swift` | n/a | | | no text | 20 |
| BK31 | Deep links | `TesseraApp.swift:103` (`onOpenURL`, `workout` host only) | n/a | | | no text | 32 |
| BK32 | Keyboard dictation into any field | system mic key | As that field | | As that field | no text | 16 |
| BK33 | Recipe link fetch | `RecipeLinkReader.swift` (Core only; no caller in the app) | | | | not built | 23 |
| BK34 | Share sheet import | no extension in `project.yml` | | | | not built | 24 |
| BK35 | Lists page | Core `Lists.swift:73`, `:102` only; no view | | | Items arrive through BK19 and BK24 today | not built | 25 |
| BK36 | Habits | no class, action or view | | | | not built | 26 |
| BK37 | Shutdown | only `DayPart.shutdown` (`HomeLines.swift:275`) and a haptic | | | | not built | 28 |
| BK38 | Search | no `.searchable`, no search field | | | | not built | new |
| BK39 | Spotlight and Home Screen widgets | no index; widgets bundle holds the Live Activity only | | | | not built | 30, 31 |
| BK40 | Set notes | no note field on a set | | | | not built | new |
| BK41 | Exercise and custom names | `RoutineEditor.swift` picks from the library; no name field | | | | not built | new |
| BK42 | Task title edit | no field; tasks are titled only at capture | | | | not built | new |
| BK43 | **Body weight entry itself** (the band's source) | M3 `LogBodyWeight` (`fixtures/body-weight.md`), Health read (ios-a 0m) | | | Not built; see section 1 | not built | new |

## 3. Count

**43 paths** (BK1 to BK43; BK14 is on an open branch and is not counted below).

| Verdict | Count | Paths |
|---|---|---|
| Covered (weight in reach at the call line) | **12** | BK1 to BK12 |
| Needs threading (a new parameter in between) | **1** | BK13 Plan my day |
| Bypasses PrivateFacts | **12** | BK15 to BK26 |
| No text | 6 | BK27 to BK32 |
| Not built | 11 | BK33 to BK43 |
| Branch only | 1 | BK14 |

"Covered" still means a change at each call line. If 0ai changes only the body of `isBodyShaped` and keeps its
one-argument signature, **no path gets the band**: no caller hands it a weight, and no weight exists in the store
outside private note text. There are 13 call sites on master that reach `isBodyShaped`: `CaptureParts.swift:190`,
`PasteRecipe.swift:206`, `Intents.swift:174`, `:199`, `ClaudeTessModel.swift:54`, `PlanWording.swift:38`,
`TessCaptureEngine.swift:60`, `:300`, `TessGrammar+Privacy.swift:30`, `:53`, `TessInbox.swift:30`, `:65`,
`TessModel.swift:77`. (`TessGrammar.swift:138`, `TessGrammar+Privacy.swift:33`, `:46` and `TessGrammar+Kitchen.swift:86`
are money only.)

**Branches.** No branch is named for 0ai (`git branch -r` has nothing matching `0ai`). Wall branches:
`core/command-walls`, `core/money-wall`, `core/paste-link-wall`, `core/siri-task-wall` and `core/weightless-f2` are all
merged into master. `ios/question-walls` (bf0ba93) is open: it adds BK14 and the `-wallsSpy` probe, and has no
last-weight code. `ios/routines-band` (open) adds no wall to "Name it".

## 4. Picks for Core 0ai (smallest change first)

1. **A weight parameter, no default.** `isBodyShaped(_:lastWeightKg: Double?)`, and the same on `isWalled` and
   `isPrivateTitle`. Leaving out a default makes the compiler list all 13 call sites, so none is missed (a default of
   nil would compile and quietly skip the band). The function stays pure, so BN01 to BN10 run as package tests with no
   store.
2. **Put the weight in `TessContext`.** Add `lastWeightKg: Double?` to `TessContext` (`TessCapturing.swift:12`) and
   fill it once per phrase in `TessCaptureEngine.capture` (`TessCaptureEngine.swift:29-31`), the way `process` is
   filled. That covers BK2 to BK8, BK10 and the inbox drain (BK11) with no new signatures. The other covered sites
   (`CaptureParts.swift:190`, `PasteRecipe.swift:206`, `Intents.swift:174`, `TessInbox.swift:30`) call the store lookup
   once. Only `PlanPack.init` (BK13) needs a new parameter.
3. **One store lookup in TesseraCore**, for example `BodyWeight.lastKg(in: ObjectStore) -> Double?`. Until M3 lands it
   reads the newest private note whose body is a weigh-in (a number from 30 to 250 kg with a weigh word, a body unit,
   or only day words; never a note with a vital, medicine, symptom or "slept"). When `LogBodyWeight` lands it reads
   that instead, and the app can hand in a Health weight held in memory (decisions 2:11 pm (3)). The engine wall
   (BK15, BK19, BK20) can call the same lookup from the transaction's store.
4. **The rule, inside `isBodyShaped`** (after the `isTraining` guard at `PrivateFacts.swift:83`, which already keeps
   BN10 plain). With a weight, any number from 0.9x to 1.1x inclusive is a body fact when it carries no unit other
   than kg, lb or kilos. Clock times are already removed by `withoutTimes`. Two decimals are already money. With no
   weight, a decimal next to a body word is walled. That needs "weight" moved into the body-word check (today it is a
   day word, `:64`) and "bmi" added (0ac slice 2 also adds it). Keep the "82.4?" control (BN03) through the existing
   day-word branch.
5. **Fix BN01 to BN10's assertion before they gate.** On the Ask bar, a phrase ending "?" goes to
   `CommandInterpreter` and never to `model.ask` (`BottomChrome.swift:509-510`, on master and on
   `ios/question-walls`), so the `-wallsSpy` Claude count is 0 on master for BN01, BN02 and BN04 too. Wrapped in
   `XCTExpectFailure`, they would fail for "no failure". Assert what the Ask bar actually does: walled rows show "That
   stays on this phone." (`CaptureParts.swift:192`) and no Home row holds the number; plain rows add the task. Or run
   the Claude half on the `liveAsk` surface (BK7), where a question does reach Claude. Seed the last weight as a private
   note ("82 kg this morning") until a body weight entry exists.
6. **Two over-wall traps for Product** (not in the 2:56 decision). (a) Mid-workout, the bar weight is often inside his
   band: "is 80 good?" with bench in focus would be walled from Claude (the grammar and the phone's model still read
   it). One answer is to skip the band when `context.entry` is set or the phrase names an exercise. (b) Numbers with
   other units inside the band, such as "is 80 min too long?", "75 g protein ok?" and "85% good?", should stay plain;
   pick 4's "no other unit" rule covers them. Also, he logs in kg only today (there is no lb setting on master), so a
   pound weight ("is 181 good?") falls outside a kg band until D11's lb setting exists.

Not for 0ai, but on the same paths: Notes (BK16 to BK18) are Core 0aa, memory (BK22, BK23) is Core 0ac, and the
engine wall itself (BK15, BK19 to BK21, BK24) is 0ai's main job (decisions 2:06 pm, `fixtures/engine-wall.md`).
