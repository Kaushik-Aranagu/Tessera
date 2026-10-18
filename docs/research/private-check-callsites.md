# Private-text check call sites (audit on master b2048d91)

Docs only. Nothing built or run. Source rule: decisions.md, the entry stamped "5:40 PM Oct 17" (= 3:28 PM PT per the
clock correction), item G105: ONE private-text function, the widest wall everywhere (receipts, UNDO, Tess lines,
screens, export): health words + secret words + money + body facts + title words ("dentist", "therapy", "clinic").
Trimmed by the 4:22 PM and 4:35 PM entries (stamped; no money words, no food-ish or unit words in titleWords).

## What exists
- master: no function named in the ruling as one check. `ObjectPrivacy.isPrivateText(_:lastWeightKg:)`
  (ObjectPrivacy.swift:91, internal) exists but is the NARROW check (secret words + `PrivateFacts.isWalled`). It has no
  title words and no medicines. Its twin `PrivateWords.isPrivateText` (PrivateWords.swift:21) wraps it.
  Titles today go through four different compositions (below).
- PR #890 (head 39809068, not merged; branch claude/... G105 commits 5052707f, cb360086, 39809068) adds the real one,
  named `ObjectPrivacy.isPrivateTitle(_:lastWeightKg:)` plus `ObjectPrivacy.titleWords`. It rewires
  `isPrivateRecipeTitle`, `isPrivateWord`, `PrivateWords.isPrivateTitle` (so `PrivateWords.titleWords` and
  `routineTitle` follow), HomeLines.swift:599, Groceries.swift:645, Lists.swift:282 and TessCaptureEngine.swift:244 and
  :384. It does not touch the rows marked straggler. Name note: the ruling and the task say "isPrivateText"; #890
  calls the one check `isPrivateTitle`. Pick one name before more call sites land (resolved, open question 1).

The four old compositions, all different:
1. `PrivateWords.isPrivateTitle` = narrow + moneyWords/healthWords + medicine (export, routines).
2. `PrivateFacts.isPrivateTitle` = secret title + secret words + walled (tasks, Siri, Home recipe line).
3. `EngineWall.isHealth` alone (items, groceries).
4. `isPrivateRecipeTitle` = 2 + medicine (recipes, lists, kitchen screens).

## Call sites

Status: straggler = still on an old composition after #890 (or not masked at all), covered = #890 moves it onto the one
check by changing a function it calls or the line itself, ok = a different job (outbound wall, not a title), or
already correct. Line numbers are master.

| file:line | old check | surface | should call instead | status | owner |
|---|---|---|---|---|---|
| TesseraCore/.../Tess/ObjectPrivacy.swift:23 | PrivateWords.isPrivateTitle (routineTitle) | Done hero, UNDO, Live Activity, live workout line | ObjectPrivacy.isPrivateTitle (same via PrivateWords) | covered by #890 | Core |
| TesseraCore/.../Tess/ObjectPrivacy.swift:42 | private-text narrow (note title, body) | ObjectPage, Home, side facts masks of notes | none (notes: Private note only when flagged or secret/money/body words, 4:50 PM) | ok (4:50 PM ruling) | Core |
| TesseraCore/.../Tess/ObjectPrivacy.swift:47 | private-text narrow (memory title, rule) | ObjectPage, memory lists | none (memory keeps its own wall, 4:22 PM) | ok (4:22 PM ruling) | Core |
| TesseraCore/.../Tess/ObjectPrivacy.swift:50-51 | PrivateFacts.isPrivateTitle (task) | task rows, links, ObjectPage | none (tasks keep their own rules: 4:20 PM item 3, 4:22 PM, 4:50 PM item 7) | ok (tasks keep own rules) | Core |
| TesseraCore/.../Tess/ObjectPrivacy.swift:54,60-62 | isPrivateRecipeTitle (PrivateFacts + EngineWall) | recipe label everywhere | the one check | covered by #890 | Core |
| TesseraCore/.../Tess/ObjectPrivacy.swift:88 | narrow + EngineWall.isHealth (isPrivateWord) | list names, Tess lines | the one check | covered by #890 | Core |
| TesseraCore/.../Tess/PrivateFacts.swift:14-15 | PrivateFacts.isPrivateTitle (definition) | all task callers below | none (tasks keep their own rules; keep as is) | ok (tasks keep own rules) | Core |
| TesseraCore/.../Export/PrivateWords.swift:21-23,28-35 | titleWords, isPrivateTitle (definitions) | export, backup, routines | forward to ObjectPrivacy | covered by #890 | Core |
| TesseraCore/.../Export/PrivateWords.swift:104,107,173-174 | isPrivateText / isPrivateTitle in labels(in:) | export mask of titles and words | one check for object words as well (174 uses narrow text on every word) | covered by #890 (107,173); straggler (104,174) | Core |
| TesseraCore/.../Export/PrivateWords.swift:213,252 | PrivateWords.isPrivateText (summaryIsPrivate, op summaries) | export op log and "What was sent" lines | the one check | needs Product's word because the op log keeps raw names (4:20 ruling; 4:35 "no widening to op log") | Core |
| TesseraCore/.../Export/TesseraExport.swift:147-178 | PrivateWords.labels/summaryIsPrivate/structural | shared export file | none (uses PrivateWords; follows rows above) | ok | Core |
| TesseraCore/.../Export/TesseraBackup.swift:64,65,95 | PrivateWords.labels/historyLabels | backup leave-out-private | none (same) | ok | Core |
| TesseraCore/.../Training/WorkoutSummary.swift:45 | PrivateWords.isPrivateTitle + routineLabel (doneLine) | Home Done line, UNDO | ObjectPrivacy.routineTitle | covered by #890 (via PrivateWords) | Core |
| TesseraCore/.../Training/WorkoutSummary.swift:92 | none: `title: store.displayTitle(of: workout)` stored raw | WorkoutSummary.title feeds HomeLines fact(done:), WeekFacts:96, Siri/widgets | mask once at the root (4:14 PM entry named it "shownTitle(of:)"; no such function on master) | straggler | Core |
| TesseraCore/.../DayLog/WeekFacts.swift:96 | none: `routinesDone.append(summary.title)` raw | week facts, Home week line | masked title from the root fix above | straggler | Core |
| TesseraCore/.../Home/HomeLines.swift:505 | none: `HomeFact(title: summary.title)` raw (the ~15 Home lines) | Home Today lines | masked title from the root fix | straggler | Core |
| TesseraCore/.../Home/HomeLines.swift:595,599 | ObjectPrivacy.label, PrivateFacts.isPrivateTitle + EngineWall | Home cook/recipe line | one check | covered by #890 | Core |
| TesseraCore/.../DayLog/DayStory.swift:474-482 | none for lists, routines, tasks (only cook/recipe via cookTitle) | Day log rows ("Private list" per 4:20 PM, O1) | ObjectPrivacy.label plus routineTitle for any object | straggler | Core |
| TesseraCore/.../Kitchen/Groceries.swift:365 | SecretWords.isSecretListLine only | grocery row created from list | one check | straggler | Core |
| TesseraCore/.../Kitchen/Groceries.swift:561 | isPrivateRecipeTitle | groceries from recipe | one check | covered by #890 | Core |
| TesseraCore/.../Kitchen/Groceries.swift:645-647 | EngineWall.isHealth (+ "Private item") | add-grocery receipt | one check | covered by #890 | Core |
| TesseraCore/.../Kitchen/Recipes.swift:194 | isPrivateRecipeTitle | recipe save | one check | covered by #890 | Core |
| TesseraCore/.../Kitchen/Cooking.swift:333 | isPrivateRecipeTitle | cook receipt | one check | covered by #890 | Core |
| TesseraCore/.../Lists/Lists.swift:145 | isPrivateWord | new list receipt | one check | covered by #890 | Core |
| TesseraCore/.../Lists/Lists.swift:282,307-311 | EngineWall.isHealth (isPrivateItem, shownTitle) | list item receipts, UNDO (many callers 347-402, ListPick 117-123) | one check | covered by #890 | Core |
| TesseraCore/.../Lists/ListReuse.swift:202 | isPrivateWord | list copy receipt | one check | covered by #890 | Core |
| TesseraCore/.../Lists/ListRuns.swift:17-20 | isPrivateWord, "Private list" | list run lines | one check | covered by #890 | Core |
| TesseraCore/.../Processes/ProcessTable.swift:156 | isPrivateWord, "Private list" string | process table row | one check | covered by #890 | Core |
| TesseraCore/.../Notes/Notes.swift:116,132-133,142,172 | Notes.isPrivateText (secret + walled), SecretWords.mentions | note capture and edit | none (a note is "Private note" only when flagged or holding secret/money/body words, no titleWord check; 4:50 PM) | ok (4:50 PM ruling) | Core |
| TesseraCore/.../Notes/SecretWords.swift:152 | SecretWords.mentions (isSecretListLine) | list lines | none (a secret-word primitive) | ok | Core |
| TesseraCore/.../Tess/SideFacts.swift:32,48,59,95 | SecretWords + isWalled / isMoneyShaped; ObjectPrivacy.label | what goes to Claude (side facts) | none for 32,48 (outbound wall); label ok | ok | Core |
| TesseraCore/.../Tess/TessMemory+Turnover.swift:69-70 | SecretWords + isWalled | memory turnover | none (outbound wall) | ok | Core |
| TesseraCore/.../Tess/TessMemory.swift:142 | SecretWords.mentions | memory remember | none (secret primitive) | ok | Core |
| TesseraCore/.../Home/TessLineCheck.swift:107,252 | SecretWords.mentions, PrivateFacts.isWalled | checking Tess-written lines | none (outbound line check, own title-word allowance) | ok | Core |
| TesseraCore/.../Home/HomeDonePack.swift:90 | SecretWords + isWalled | done pack for Claude | none (outbound wall) | ok | Core |
| TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:59-60 | SecretWords + isWalled | capture-miss log gate | none (outbound wall) | ok | Core |
| TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:244,384 | EngineWall.isHealth -> isPrivateWord | "Private item, already on Groceries." | one check | covered by #890 | Core |
| TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:246,389,403 | hand-built "Private item" string | grocery receipts | ObjectPrivacy label constant | straggler (string only) | Core |
| TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:319-323 | PrivateFacts.isPrivateTitle, SecretWords.title | task capture receipt (privateTaskLine) | none (tasks keep their own rules) | ok (tasks keep own rules) | Core |
| TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:341 | hand-built "Private note, kept." string | note receipt | SecretWords.title + ", kept." | straggler (string only) | Core |
| TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:408,416,475 | ObjectPrivacy.label; isPrivateWord + "Private list" string | recipe and list capture receipts | label constant / one check | covered by #890 (475, 408, 416); string literal at 475 straggler | Core |
| TesseraCore/Sources/TesseraTess/TessTools.swift:337 | isPrivateWord ("that") | Tess tool reply | one check | covered by #890 | Core |
| TesseraCore/Sources/TesseraTess/TessGrammar.swift:516, TessGrammar+Privacy.swift:19 | SecretWords.mentions | grammar route for secrets | none (secret primitive, pre-route) | ok | Core |
| TesseraCore/Sources/TesseraTess/TessInbox.swift:30,65 | SecretWords + isWalled | inbox gate to Claude | none (outbound wall) | ok | Core |
| TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift:468 | PrivateFacts.isWalled | ingredient lines to Claude | none (outbound wall) | ok | Core |
| TesseraCore/Sources/TesseraTess/ClaudeTessModel.swift:140-141, TessModel.swift:95-96 | SecretWords + isWalled | request wall | none (outbound wall) | ok | Core |
| TesseraCore/Sources/TesseraTess/PlanWording.swift:25,40,47,177,190,314-326 | pack titleWords (a different set), "Private ..." label list, SecretWords + isWalled | planner wording check | none (name clash only: local `titleWords`) | ok | Core |
| TesseraCore/Sources/TesseraIntents/Intents.swift:180,205 | PrivateFacts.isPrivateTitle | Siri / Shortcuts task receipt and hidden flag | task keeps PrivateFacts; items, lists, recipes, workouts use the one check. Split already made by core/g105b (221d7444, no PR yet) | ok (tasks keep own rules); split in flight on core/g105b | Core |
| TesseraCore/Sources/TesseraIntents/Entities.swift:84,91,102 | none: RoutineEntity(title: routine.title) raw; search matches raw title | Siri/Spotlight routine name and search (7th site of #881) | routineTitle for display; search must not reveal a private routine by title | straggler | Core |
| Features/Workout/WorkoutSession.swift:31 | ObjectPrivacy.routineTitle | live workout, Live Activity (RestActivityController:75), WorkoutParts:178, WorkoutModeView:93,116 | one check (via routineTitle) | covered by #890 | Builder A |
| Features/Objects/ObjectPage.swift:54,256,304,332,434 | ObjectPrivacy.label | ObjectPage hero, children, links | none for routines: label() has no workout/routine branch (#881 extra site ObjectPage:260) | straggler (routine hero raw) | Builder A or B (ObjectPage is unassigned) |
| Features/Command/CaptureParts.swift:189-190 | SecretWords.mentions + isWalled | capture bar gate | none (outbound wall) | ok | Builder B |
| Features/Kitchen/CookModeCopy.swift:72 | isPrivateRecipeTitle | cook mode copy | one check | covered by #890 | Builder B |
| Features/Kitchen/PantryLedger.swift:100,166-168 | isPrivateRecipeTitle + "Private item" string | pantry rows | one check, label constant | covered by #890; string straggler | Builder B |
| Features/Lists/ListsShelf.swift:97 | isPrivateRecipeTitle + "Private list" string | lists shelf | one check, label constant | covered by #890; string straggler | Builder B |
| Features/Recipes/PasteRecipe.swift:567-568,592 | SecretWords + isWalled; isPrivateRecipeTitle | paste capture gate | 567-568 none (paste wall); 592 one check | ok (567); covered by #890 (592) | Builder B |
| Features/Recipes/RecipePage.swift:584,616-618 | isPrivateRecipeTitle; shownTitle | recipe page | one check | covered by #890 | Builder B |
| Features/Recipes/RecipesShelf.swift:39 | isPrivateRecipeTitle | recipes shelf | one check | covered by #890 | Builder B |
| Features/Groceries/GroceriesWall.swift:40 | SecretWords.isSecretListLine / mentions | Groceries wall reason (.secret) | one check for the mask reason | straggler | Builder B |
| Features/Groceries/ShopTrip.swift:12,19,53 | isPrivateRecipeTitle, "Private item" string | shop trip rows | one check, label constant | covered by #890; string straggler | Builder B |
| Widgets/, Shared/, App/ | no check, no masking code found | widgets and any widget timeline | n/a: widgets read through Core (RestActivity uses session.shownTitle) | ok | Builder A |

## Counts (rows, not call lines; a row with mixed status is counted in each)

Rows: 61. By primary status (recounted from the table after QA review 915): straggler 10, needs Product's word 1
(the export op-summary row, PrivateWords.swift:213 and :252), covered by #890 26, ok 24. Straggler plus needs-word is 11.
The 7 rows that moved to ok are the task, note and memory rows that the rulings keep on their own rules (see Summary).
Some rows are mixed (the label function moves with #890 but a hard-coded "Private item" or "Private list" string stays);
they are listed under their main status and the string note is in the cell.

## Summary
- #890 fixes the title path: one public `ObjectPrivacy.isPrivateTitle`, and the recipe, word, routine, Home recipe line,
  grocery and list-item checks all reach it. Most screens (Features/Kitchen, Recipes, Lists, Groceries) are covered
  with no edit because they already call `isPrivateRecipeTitle`.
- Top stragglers, in order of user-visible risk:
  1. Routine titles stored raw at the root: WorkoutSummary.swift:92, which feeds HomeLines.swift:505 (~15 Home
     lines), WeekFacts.swift:96 and the Done pack. `shownTitle(of:)` named on 4:14 PM does not exist on master.
  2. DayStory.swift:474 (`title(of:)`) masks only cook/recipe; a private list or routine reads raw in the Day
     log (G75/G104, O1).
  3. Siri: Entities.swift:84/:91/:102 shows and searches a private routine by raw title (the Intents.swift task
     read-back is ruled ok).
  4. ObjectPage routine hero: `label()` has no workout/routine branch (ObjectPrivacy.swift:36-56, ObjectPage.swift:256).
  5. Export: PrivateWords.swift:104 and :174 still call the narrow `isPrivateText` on field words. The op summaries at
     :213 and :252 need Product's word first: the op log keeps raw names (4:20 ruling, 4:35 "no widening to op log"), so
     only displayed text masks.
  6. Hard-coded "Private item" / "Private list" / "Private note" literals in 8 places (see table); one
     label constant each would stop drift.
- Not stragglers (ruled): tasks keep their own rules (decisions 4:20 PM item 3, 4:22 PM, 4:50 PM item 7), so
  ObjectPrivacy.swift:50-51, PrivateFacts.swift:14-15, TessCaptureEngine.swift:319-323 and the Intents.swift:180/205 task
  read-back stay on `PrivateFacts.isPrivateTitle`. A note is "Private note" only when flagged or when it holds secret,
  money or body words, with no titleWord check (4:50 PM correction), so ObjectPrivacy.swift:42,47 and Notes.swift:116 are
  ok; memory keeps its own wall (4:22 PM).
- In flight: core/g105b (commit 221d7444, no PR yet) already splits the Siri read-back (Intents.swift:205: task keeps
  PrivateFacts; items, lists, recipes, workouts use the one check) and covers the PantryLedger and ingredient rows. Do
  not re-assign these.
- Widgets and Live Activities: no masking code of their own in Widgets/, Shared/ or App/. The rest Live Activity gets
  `session.shownTitle`, which goes through `routineTitle`, so it is covered once #890 lands. A widget that shows a
  routine from Core (none found on master) would inherit the WorkoutSummary root bug.
- "ok" rows are outbound walls (what may go to Claude) and secret-word primitives. They intentionally do not use title
  words: "dentist" is a private title but not a reason to refuse sending a grocery phrase.

## Open questions and rulings
1. Name (resolved as a naming note): the live name on #890's head is `ObjectPrivacy.isPrivateTitle` (Product's later
   entries and Core's branch use it too). The ruling's "isPrivateText" is the narrower internal
   `ObjectPrivacy.isPrivateText` (ObjectPrivacy.swift:91). Recommend renaming that narrow one (for example
   `isWalledText`) in a later Core PR so the two are not confused.
2. Should the Siri, Day log and other straggler fixes ride on #890 (one more commit) or a follow-up Core PR? They are
   all Core; none need UI. The Siri task split is already on core/g105b.
3. Notes and memories: ruled. The 4:50 PM correction says a note is "Private note" only when flagged or holding
   secret, money or body words, with no per-titleWord check; memory keeps its own wall (4:22 PM). No change to those rows.
4. Outbound walls (SideFacts, TessInbox, PlanWording, ClaudeTessModel): assumed answer is that they stay on secret +
   walled only, because the rulings never widen outbound.
5. Owners follow the team split in the project notes: Builder A has training, workout, widgets and Live Activities; Builder B has Home, the ask slot (Command), Groceries, Recipes, Lists and Kitchen week. ObjectPage is not named for either. Every straggler fix except the literal-string ones in Features (Builder B) is in Core.
6. Op log keeps the raw title by ruling (4:20 PM O3); this audit did not count op payloads as masking sites. The export
   op-summary rows (PrivateWords.swift:213, :252) wait on Product's word for that reason.
