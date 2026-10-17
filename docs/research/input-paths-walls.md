# Every way text gets into the app, checked against the three walls

For: Product's board, item AX. Owner: Research lab. Oct 16, 2026, read on origin/master f874295. No app code under
`App/`, `Features/`, `TesseraCore/` or `Widgets/` has changed since fbede70, which
[`walls-ui-test-spec.md`](walls-ui-test-spec.md) and [`fixtures/walls-ui-phrases.json`](fixtures/walls-ui-phrases.json)
were read on, so their line numbers still hold. Every phrase here is made up (hunter2, tacocat, 4417, "the fake store").

**The three walls**

| Wall | Where it lives | What it does |
|---|---|---|
| Key | `looksLikeClaudeKey` (`ClaudeKeyGuard.swift:13`) | A key-shaped string is never saved, logged or sent |
| Secret | `SecretWords.mentions` / `hasValue` / `isPrivateLine` (`SecretWords.swift`) | A secret phrase becomes a "Private note" or an ignored line; never leaves the grammar (`TessModel.swift:74`) |
| PrivateFacts | `PrivateFacts.isWalled` (`PrivateFacts.swift:9`) | Money and body phrases never go to Claude (`TessModel.swift:77-79`, `ClaudeTessModel.swift:54`). Product (decisions 1:15 pm): "Money with an amount stays private everywhere"; body facts on the Notes page or after "note:" go private |
| Claude gate | `AppModel.asksClaude` (`AppModel.swift:58-60`) wired at `AppModel.swift:135-143`; `ClaudeTessModel.isAvailable` (`:47-49`) and `run` (`:51-54`, never for `commitImmediately`) | Claude only for a capture miss, only with the switch on, a key saved, not paused, not a demo |

**Where text can land:** task, note, routine or ingredient titles; Home (task titles); the Day log
(`DayStory.swift:337-347`: "Done: <title>", "Note: <title>"); Tess's memory (`TessMemory+Turnover.swift:67`, yesterday's
Day log lines, secret words filtered but not PrivateFacts); the miss log `capture-misses.jsonl`
(`CaptureMissLog.swift:29-39`, refuses keys only; callers add the rest); op log summaries and receipts; Shortcuts and
Siri pickers (`Entities.swift:58-104`, routine titles); backups (the whole store, `BackupKeeper.swift:164`, so anything
titled with a value rides in every backup unmarked). Spotlight: nothing is indexed on master (no `CSSearchableIndex`,
no `IndexedEntity`).

## 1. The sweep

Verdicts: **walled** (every wall that applies holds), **leak** (a wall is skipped and the text lands somewhere it
shouldn't), **not built** (no entry on master). "Known" means a row already in the fixture.

| # | Path | Entry | Walls passed (or skipped) | Lands in | Verdict | Owner |
|---|---|---|---|---|---|---|
| 1 | **Groceries writing line** | `GroceriesView.swift:365`, `add()` `:199-203` | **Skips all three.** No key check in the view; `AddGroceries.apply` (`Groceries.swift:415-421`) takes any line `IngredientLine.parse` names (`Quantities.swift:135-254`, nil only when the name is empty) | An ingredient object and a grocery item named with the text, the receipt "Wifi password is hunter2, on Groceries" (`Groceries.swift:431-440`), the op summary "Added ..." (`:427-429`), Day log "Added N groceries", backups. A pasted key becomes an ingredient | **leak** (new; key and secret) | Builder B (view guard), Core (refuse in `AddGroceries`) |
| 2 | **Ask bar, ending "?"** (also "best", "pr") | `BottomChrome.swift:373`, `commit` `:508-509` | Key: yes (`:395-398`, `:471`, `:502`). Secret, PrivateFacts, router: **skipped**. `CommandInterpreter.run` (`CaptureParts.swift:167-188`) writes `CreateTask` with the phrase as title; `CreateTask.apply` (`TrainingActions.swift:426-434`) has no wall. "best"/"pr" phrases write nothing | Task title on Home, Day log "Done: Door code 4417?", memory line, backups | **leak** (known A06, A07) | Builder B 0v, Core 0ah |
| 3 | **Routines "Name it"** | `RoutinesPage.swift:108`, `make()` `:139-142` | **Skips all three.** `CreateRoutine` (`PlanActions.swift:5`) has no check | Routine title in Plans, Training, the Live Activity, the Shortcuts and Siri picker ("Start <routine>", `Entities.swift:58-104`), backups. A pasted key is kept as a title | **leak** (new; key and secret) | Builder A (view guard), Core (refuse in `CreateRoutine`) |
| 4 | **Speak** (Tess's mic) | `SpeechListener.swift:122-125` (on device, `addsPunctuation = true`); `finishListening` `BottomChrome.swift:619-659` calls the same `commit` (`:656`) | Same as rows 2 and 5. The recognizer adds "?" to a spoken question, so "what's my wifi password" lands as a task through row 2's branch. Audio stays on the phone (`requiresOnDeviceRecognition`, `:124`) | As rows 2 and 5 | **leak** (new path to row 2's fix) | Builder B 0v (same fix) |
| 5 | **Ask bar, plain: money or body with a day** | `BottomChrome.swift:509` to `AppModel.ask` (`:213-218`) to the router | Key, secret, Claude: yes. PrivateFacts: **skipped by the grammar.** `parseTask` (`TessGrammar.swift:513-543`) runs before `parseBodyFact` (`:141`) and checks nothing; the money check at `:116-120` only catches a currency sign or a leading spend word. "rent 2100 fri" and "todo rent 2100" become a task "Rent 2100"; "knee hurts tomorrow" becomes "Knee hurts" (read, not run) | Task title on Home, Day log "Done: Rent 2100", memory line, backups | **leak** (new) | Core (grammar) |
| 6 | **Ask bar, plain: money or body nothing reads** | as row 5 | Claude: walled (`TessModel.swift:77-79`). Miss log: **skipped**, `TessCaptureEngine.swift:58` checks key and secret, not PrivateFacts | `capture-misses.jsonl` | **leak** (known A10, A11, A12) | Core (one line at `:58`) |
| 7 | **Ask bar, "note:" with money or body** | as row 5; `parseNote` `TessGrammar.swift:334-339` | Secret: yes (`parseSecret` runs first, `:71`). PrivateFacts: **skipped**. `CreateNote` makes a plain note (`Notes.swift:111`) | Note titled "knee hurts", Day log "Note: knee hurts", memory line | **leak** (new; decisions 1:15 pm) | Core 0aa |
| 8 | **Ask bar, plain: on-device model step** | router `TessModel.swift:75-79` lets the phone's model read money and body | Claude: walled. Titles the model writes: **no PrivateFacts check** in `TessModelCapture` | A task like "Fake store $12" on a phone with Apple Intelligence (device dependent; the UI test runs grammar only) | **leak** (new, device dependent) | Core |
| 9 | **Notes page writing line** | `NotesView.swift:143`, `write()` `:118-127` | Key: yes (`:82-84`, `Notes.swift:107-109`). Secret: yes (`Notes.swift:111-113`). PrivateFacts and account lines: **skipped** | Plain note with the value in its title, Notes list, Day log, backups | **leak** (known N04, N05, N06) | Core 0aa |
| 10 | **Note editor, edit and heading (rename)** | `NoteEditor.swift:44` (heading), `:60` (body), save `:164` as `EditNote` | Key: yes (`NoteEditor.swift:132`, `Notes.swift:157`). Secret: yes, a secret added to a plain note makes it private (`Notes.swift:162-174`). PrivateFacts: **skipped** | A plain note retitled "knee hurts" or "Rent 2100" | **leak** (new) | Core 0aa |
| 11 | **Siri and Shortcuts: Add a Task** | `Intents.swift:130-145` | Key: yes (`:137`). Secret with a value: yes (`:140-142`). PrivateFacts: **skipped** (P14 not on master). Never calls a model | Plain task titled with the amount or body fact | **leak** (known S03, S04) | Core P14 |
| 12 | **Siri and Shortcuts: Tell Tess** | `Intents.swift:161-164`, the shared runtime (`TesseraApp.swift:35-37`) | Key, secret: yes (router). Claude: never (`commitImmediately`, `ClaudeTessModel.swift:53`). Inherits rows 5, 6, 7 and 8 | As rows 5 to 8; a miss logs with source "ghost row" | **leak** (inherits Core fixes; no fixture rows yet) | Core |
| 13 | **Live workout ask field** | `WorkoutParts.swift:356`, `WorkoutModeView.swift:275-280` to `model.ask` | Key: yes (`WorkoutParts.swift:363-369`, `:386`, `WorkoutModeView.swift:277`). No "?" branch here, so secrets reach the grammar. Inherits rows 5 to 8 | As rows 5 to 8 | **leak** (inherits Core fixes) | Core |
| 14 | **Paste a recipe** | `PasteRecipe.swift:67`, `save()` `:200-207` | Key: yes (`:119-121`). Secret lines: ignored and cut (`Recipes.swift:162-164`, `:174`); a secret first line is ignored too, so the title falls back to "Untitled recipe". Miss log: **PrivateFacts skipped** at `:205` | `capture-misses.jsonl` on a failed paste | **leak** (known P04) | Builder B |
| 15 | **Ask bar, plain: secret or key** | `BottomChrome.swift:373` | Key: `:395-398`, `:471`, `:502`, `TessModel.swift:69`. Secret: `TessGrammar.swift:71`, `:487-510`, router `TessModel.swift:74`, miss log `TessCaptureEngine.swift:58`. Claude: gate plus `ClaudeTessModel.swift:54` | "Private note" (title `SecretWords.title`), Day log "Private note" (`DayStory.swift:345-347`), memory skips it (`TessMemory+Turnover.swift:67`) | **walled** (A01 to A05, A08, A09) | |
| 16 | **Keyboard dictation into any field** | system mic key | Same as typing into that field (rows 1 to 15) | as that field | as that field | |
| 17 | **Settings, Claude key field** | `ClaudeSection.swift:247` | Anything not key-shaped is dropped (`:317-323`), never stored or logged; the key goes to the Keychain and the pasteboard is cleared (`:369-371`) | Keychain | **walled** | |
| 18 | **Offline Claude inbox (retry)** | `TessInbox.swift:29-30`, drain `:65` | Key, secret, PrivateFacts all checked on queue and on drain; `ClaudeTessModel.swift:54` again | Inbox object, then Claude | **walled** | |
| 19 | **Shortcuts: Log a Set, Start Routine, Finish, Undo** | `Intents.swift:9-115` | No free text is stored: numbers and entity picks; the entity string query only matches (`Entities.swift:23-47`, `:75-99`) | Sets and workouts | **walled** (no text) | |
| 20 | **Live Activity buttons** | `RestLiveActivity.swift:271`, `:317`, `:326`, `:328`; `RestIntents.swift:29-71` | Fixed actions, no text | Sets, rest timer | **walled** (no text) | |
| 21 | **Weight field** (workout) | `WeightField.swift:25`, `commit` `:64-72` | Decimal pad; only a parsed `Double` is kept | A weight | **walled** (no text) | |
| 22 | Plan my day edits | Core only: `PlanWording.swift:37-46`, `:118`, `:164` wall titles; no view or call in `App/` or `Features/` | Core walled | | **not built** | |
| 23 | Link fetch (recipe link) | Core only: `RecipeLinkReader.swift:102-110`, `:369` cut secret lines; nothing in the app calls it | Core cuts secrets; page text is not checked for PrivateFacts (third-party text) | | **not built** | |
| 24 | Share sheet / recipe import from another app | No share extension in `project.yml` | | | **not built** | |
| 25 | Lists entry | Core `Lists.swift` only; no Lists view | | | **not built** | |
| 26 | Habits | none | | | **not built** | |
| 27 | Review and Day log edits | `ReviewView.swift`, `ReviewWeek.swift` have no text field | | | **not built** | |
| 28 | Shutdown | none | | | **not built** | |
| 29 | RenameObject (generic rename) | only a comment at `RoutineEditing.swift:4`; no action or view. Note headings rename through row 10 | | | **not built** | |
| 30 | Home screen widgets | `TesseraWidgetsBundle.swift` holds the Live Activity only | | | **not built** | |
| 31 | Spotlight | no index | | | **not built** | |
| 32 | Deep links | `TesseraApp.swift:99-103` reads only the `workout` host; `-openLink` is a simulator launch flag | | | **walled** (no text) | |

**Count: 32 paths. 10 walled, 13 leak, 9 not built.** (Row 16 counts with the walled rows since it adds no path of
its own.)

### Two follow-ons that aren't entry paths

- **Memory copies the leaks.** `TessMemory+Turnover.swift:67` drops a Day log line with a secret word but not one with
  money or body, so row 2's "Done: Door code 4417?" is dropped, but row 5's "Done: Rent 2100" becomes a memory line.
  Nothing on master sends memory to Claude (`ClaudeTessModel.swift:152-156`), so it is a store leak, not a Claude
  leak. Owner Core: add `PrivateFacts.isWalled` there.
- **The engine has no last wall.** `CreateTask`, `CreateRoutine` and `AddGroceries` accept a key-shaped title;
  `CreateNote` and `EditNote` refuse one (`Notes.swift:107`, `:157`). One check in those three actions would close
  rows 1 to 3 for keys whatever the view does. Owner Core.

## 2. Leaks, worst first

1. **Groceries line** (row 1): no wall at all. A key, a door code or an amount becomes an ingredient and a receipt.
   Builder B, plus Core's refusal in `AddGroceries`.
2. **Routine name** (row 3): no wall at all, and the title surfaces in Siri and Shortcuts. Builder A, plus Core in
   `CreateRoutine`.
3. **Ask bar "?" and Speak** (rows 2 and 4): a secret with a value becomes a plain task. Builder B 0v plus Core 0ah;
   Speak needs no extra fix once `commit` stops routing "?" around Tess.
4. **Money or body with a day becomes a task** (row 5, inherited by rows 12 and 13): Core grammar. Run
   `parseBodyFact` and a PrivateFacts check before `parseTask`, or route a walled task title to a private note.
5. **On-device model titles** (row 8): Core.
6. **Notes page, note editor, "note:"** (rows 7, 9, 10): Core 0aa.
7. **Siri Add a Task** (row 11): Core P14.
8. **Miss log** (rows 6 and 14): Core at `TessCaptureEngine.swift:58`, Builder B at `PasteRecipe.swift:205`.

## 3. Proposed WallsUITests rows

Same shape as the fixture. New surfaces: `groceries`, `routineName`, `noteEditor`, `liveAsk`, `speak` (UI tests) and
`siriTellTess` (package, `WallsSiriTests`, like `siriAddTask`). `passesOnMaster` is read from the code, not run. Key rows
are `"phrase": null, "build": "KEY"` only; the test takes `ClaudeSection.fakeKey` in code, as the spec says.

Seams the new surfaces need (Builder B unless noted):

- `groceries`: launch with `-openLink groceries` if the route exists, else open Kitchen, Groceries; field label "Add to
  groceries" (`GroceriesView.swift:373`).
- `routineName` (Builder A): open Plans, Routines, tap "Make a routine", field "Name it".
- `noteEditor`: write N07's "buy milk" first, open it, type into the heading ("First line" prompt).
- `liveAsk` (Builder A): a running workout; the field prompt is "log bench 80x8, or ask".
- `speak`: `-speakScript` plays a fixed word list today (`BottomChrome.swift:590-592`). It needs to take the row's
  words, for example `-speakScript "what's my wifi password?"`, read through `LaunchFlags`.

```json
[
  {
    "id": "A20",
    "phrase": "rent 2100 fri",
    "surface": "askBar",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Private note",
    "lineMatch": "prefix",
    "passesOnMaster": false,
    "masterEvidence": "TessGrammar.swift:116-120 misses it (no currency sign, no leading spend word), so parseTask (:513-543) writes a task \"Rent 2100\". Claude wall holds.",
    "pending": "Core: PrivateFacts check before parseTask",
    "notes": "Money with an amount stays private everywhere (decisions 1:15 pm). The test also asserts no static text holds 2100."
  },
  {
    "id": "A21",
    "phrase": "knee hurts tomorrow",
    "surface": "askBar",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Private note",
    "lineMatch": "prefix",
    "passesOnMaster": false,
    "masterEvidence": "parseTask (TessGrammar.swift:513-543) runs before parseBodyFact (:141) and takes the day, so it is a task \"Knee hurts\".",
    "pending": "Core: parseBodyFact before parseTask (Product to confirm a dated body fact is a private note)",
    "notes": "Product ruled \"Book physio\" stays a task (12:54 pm); a symptom is not an errand."
  },
  {
    "id": "A22",
    "phrase": "rent 2100?",
    "surface": "askBar",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": false,
    "masterEvidence": "BottomChrome.swift:508-509 then CaptureParts.swift:184-188 write a task \"Rent 2100?\".",
    "pending": "Builder B 0v, Core 0ah",
    "notes": "A question never writes. Asserts no task row and no static text holding 2100 after the dry."
  },
  {
    "id": "A23",
    "phrase": "note: knee hurts",
    "surface": "askBar",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Private note, kept.",
    "lineMatch": "exact",
    "passesOnMaster": false,
    "masterEvidence": "parseNote (TessGrammar.swift:334-339) then CreateNote, which checks SecretWords only (Notes.swift:111): a plain note \"knee hurts\".",
    "pending": "Core 0aa",
    "notes": "Decisions 1:15 pm: body facts after \"note:\" go private."
  },
  {
    "id": "G01",
    "phrase": "wifi password is hunter2",
    "surface": "groceries",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": false,
    "masterEvidence": "GroceriesView.swift:199-203 and Groceries.swift:415-421 have no wall: an ingredient \"wifi password is hunter2\" and the receipt naming it.",
    "pending": "Builder B (view), Core (AddGroceries)",
    "notes": "Nothing is added. Asserts no static text holds hunter2. The line is Product's to word."
  },
  {
    "id": "G02",
    "phrase": null,
    "build": "KEY",
    "surface": "groceries",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": false,
    "masterEvidence": "No key check in GroceriesView or AddGroceries: the key becomes an ingredient and rides in backups.",
    "pending": "Builder B (view), Core (AddGroceries)",
    "notes": "Pasted, never typed. Field cleared, nothing added, nothing on screen holds the tail."
  },
  {
    "id": "G03",
    "phrase": "rent 2100",
    "surface": "groceries",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": false,
    "masterEvidence": "IngredientLine.parse (Quantities.swift:135) names it \"rent 2100\"; AddGroceries adds it.",
    "pending": "Builder B, Core",
    "notes": "Money with an amount stays private everywhere."
  },
  {
    "id": "G04",
    "phrase": "eggs, milk, 2 lemons",
    "surface": "groceries",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": true,
    "masterEvidence": "GroceriesView.swift:699-703 splits; Groceries.swift:415-421 adds three",
    "pending": null,
    "notes": "Control: three items appear."
  },
  {
    "id": "R01",
    "phrase": "door code 4417",
    "surface": "routineName",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": false,
    "masterEvidence": "RoutinesPage.swift:139-142 and CreateRoutine (PlanActions.swift:5) have no wall; the title shows in Plans and the Siri picker.",
    "pending": "Builder A (view), Core (CreateRoutine)",
    "notes": "No routine is made. Asserts no static text holds 4417."
  },
  {
    "id": "R02",
    "phrase": null,
    "build": "KEY",
    "surface": "routineName",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": false,
    "masterEvidence": "No key check on the Name it line.",
    "pending": "Builder A (view), Core (CreateRoutine)",
    "notes": "Pasted. Field cleared, no routine made."
  },
  {
    "id": "R03",
    "phrase": "Push day",
    "surface": "routineName",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": true,
    "masterEvidence": "RoutinesPage.swift:139-142",
    "pending": null,
    "notes": "Control: a routine named Push day appears."
  },
  {
    "id": "E01",
    "phrase": "knee hurts",
    "surface": "noteEditor",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": false,
    "masterEvidence": "NoteEditor.swift:164 saves EditNote with the heading as title; Notes.swift:162 checks SecretWords only.",
    "pending": "Core 0aa",
    "notes": "Typed as the heading of an open plain note. Back on the Notes page the row reads \"Private note\"."
  },
  {
    "id": "E02",
    "phrase": "wifi password is tacocat",
    "surface": "noteEditor",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": true,
    "masterEvidence": "Notes.swift:162-174 (a secret added to a plain note makes it private, title Private note)",
    "pending": null,
    "notes": "Typed into the body under the heading."
  },
  {
    "id": "E03",
    "phrase": null,
    "build": "KEY",
    "surface": "noteEditor",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": true,
    "masterEvidence": "NoteEditor.swift:132-136 takes the key out; EditNote refuses it (Notes.swift:157)",
    "pending": null,
    "notes": "Pasted into the body. The note keeps its old text."
  },
  {
    "id": "L01",
    "phrase": "door code 4417",
    "surface": "liveAsk",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Private note, kept.",
    "lineMatch": "exact",
    "passesOnMaster": true,
    "masterEvidence": "WorkoutModeView.swift:275-280 calls model.ask; TessGrammar.swift:71",
    "pending": null,
    "notes": "No \"?\" branch in the workout field."
  },
  {
    "id": "L02",
    "phrase": "$12 at the fake store",
    "surface": "liveAsk",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": false,
    "masterEvidence": "Same path as A10: TessCaptureEngine.swift:58 logs it.",
    "pending": "Core, same one-line fix as A10",
    "notes": "The line may carry the set example (TessModel.swift router)."
  },
  {
    "id": "K01",
    "phrase": "what's my wifi password?",
    "surface": "speak",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "It's in your private notes.",
    "lineMatch": "exact",
    "passesOnMaster": false,
    "masterEvidence": "SpeechListener.swift:125 adds punctuation; BottomChrome.swift:656 commits through :508-509, so a task.",
    "pending": "Builder B 0v (same fix as A06) and the -speakScript seam",
    "notes": "Played through -speakScript with the row's words; nothing is written."
  },
  {
    "id": "K02",
    "phrase": "door code 4417",
    "surface": "speak",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Private note, kept.",
    "lineMatch": "exact",
    "passesOnMaster": true,
    "masterEvidence": "BottomChrome.swift:656 then model.ask; TessGrammar.swift:71",
    "pending": null,
    "notes": "Needs the -speakScript seam to run."
  },
  {
    "id": "S06",
    "phrase": "door code 4417?",
    "surface": "siriAddTask",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Private note, kept.",
    "lineMatch": "exact",
    "passesOnMaster": true,
    "masterEvidence": "Intents.swift:140-142 (hasValue ignores the question mark)",
    "pending": null,
    "notes": "Siri twin of A07: no \"?\" detour here."
  },
  {
    "id": "S07",
    "phrase": "rent 2100 fri",
    "surface": "siriAddTask",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Private note, kept.",
    "lineMatch": "exact",
    "passesOnMaster": false,
    "masterEvidence": "Intents.swift:144 writes a plain task.",
    "pending": "Core P14",
    "notes": "Money word with an amount and no spend verb."
  },
  {
    "id": "T01",
    "phrase": "what's my wifi password?",
    "surface": "siriTellTess",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "It's in your private notes.",
    "lineMatch": "exact",
    "passesOnMaster": true,
    "masterEvidence": "Intents.swift:161-164 to the router; TessGrammar.swift:497-498",
    "pending": null,
    "notes": "Package test through TellTessIntent's capture call with commitImmediately."
  },
  {
    "id": "T02",
    "phrase": null,
    "build": "KEY",
    "surface": "siriTellTess",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "That looks like a Claude key. It goes in Review, under Claude.",
    "lineMatch": "exact",
    "passesOnMaster": true,
    "masterEvidence": "TessModel.swift:69-71",
    "pending": null,
    "notes": "Nothing written."
  },
  {
    "id": "T03",
    "phrase": "$12 at the fake store",
    "surface": "siriTellTess",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Didn't catch that.",
    "lineMatch": "exact",
    "passesOnMaster": false,
    "masterEvidence": "ClaudeTessModel.swift:53 never runs for Siri; TessCaptureEngine.swift:58 logs the miss.",
    "pending": "Core, same one-line fix as A10",
    "notes": "The test uses a store on disk so missLog is not nil."
  },
  {
    "id": "T04",
    "phrase": "rent 2100 fri",
    "surface": "siriTellTess",
    "expectPrivate": true,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": "Private note",
    "lineMatch": "prefix",
    "passesOnMaster": false,
    "masterEvidence": "Same grammar path as A20: a task \"Rent 2100\".",
    "pending": "Core: PrivateFacts check before parseTask",
    "notes": "Tell Tess twin of A20."
  },
  {
    "id": "P06",
    "phrase": "wifi password: tacocat4417\nIngredients\n1 cup red lentils\n2 cups water\nMethod\nSimmer for 20 min.",
    "surface": "paste",
    "expectPrivate": false,
    "expectNoClaude": true,
    "expectNotInMissLog": true,
    "expectLine": null,
    "lineMatch": null,
    "passesOnMaster": true,
    "masterEvidence": "Recipes.swift:162-164 ignores the first line too, so RecipeParser falls back to \"Untitled recipe\"; :174 cuts it from sourceText",
    "pending": null,
    "notes": "A secret as the first line never becomes the recipe's title."
  }
]
```
