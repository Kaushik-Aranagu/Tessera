# The pin page, checked line by line (Product item AK)

For: Product, coordinator. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

Checks `docs/research/new-on-your-phone-v9.md` (read from origin/master) against the code at exactly
a36b161b7294596848a319c0cc0fc50a3b25f2ee. "New" means the change is in `7b321d2..a36b161` (his phone has 7b321d2).
Code was read with `git show a36b161:path` and `git grep ... a36b161`; nothing was built or run. Evidence is
file:line at a36b161 unless marked otherwise.

## Counts

- Top section, T1 to T10: 8 true, 2 partly (T7, T9), 0 false.
- Appendix, A1 to A36: 28 true, 8 partly (A2, A5, A12, A14, A16, A17, A20, A29), 0 wholly false. One sub-claim is
  false outright: the " · 15 oz" pack size is never drawn on a Groceries row (inside A20 and T7).
- "Not new" sub-claims: US aisle names, and salt, oil and black pepper as staples, were already on 7b321d2.
- Built from: all 30 PRs (#341 to #498, plus #366 and #369) merge into a36b161 and none is in 7b321d2. Five code PRs
  in the pin are missing from the list (see "Built from").
- Things to try first: all five steps work as written at a36b161. Steps 3 and 4 change his real data; a short
  caution is suggested.

## Top section

| Id | Claim | Verdict | Evidence at a36b161 |
|---|---|---|---|
| T0 | Build a36b161, Catalog v9 | true | `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:350` (version 9; 7b321d2 has 5) |
| T1 | Home says one plain line per thing; the day word follows your 4 am day | true, new (#366, #369) | `Features/Home/HomeLineHero.swift:4-6, 57-93, 100-103`; `TesseraCore/Sources/TesseraCore/Home/HomeLines.swift:410-414` (HomeLineHero.swift is a new file) |
| T2 | Review is your week on one page; tap a day to read it | true, new (#348, #352) | `Features/Home/ReviewPage.swift:215-327`; `Features/Home/ReviewWeek.swift` (new file) |
| T3 | The live workout grows out of START, LOG on the key, "Push A, set 1 of 4" on top | true, new (#347, #381, #397) | `App/RootView.swift:59-63`; `Features/Home/TrainingPage.swift:71, 113-116`; `Features/Workout/WorkoutModeView.swift:630-634`; `Features/Workout/WorkoutParts.swift:201` |
| T4 | Routines: make, drag and drop them, pick ROLLS ON or FIXED DAYS | true, new (#341, #359, #363) | `Features/Plans/RoutinesPage.swift:6, 104-154, 158-186, 190-232` |
| T5 | Bests stay on their day; early finishes reach Apple Health | true, new (#344, #463) | `TesseraCore/Sources/TesseraCore/Actions/TrainingActions.swift:79`; `TesseraCore/Sources/TesseraCore/DayLog/DayStory.swift:536`; `App/Health/HealthExporter.swift:26-29` |
| T6 | Hold the tab row for a glass lens across the pages | true, new (#342) | `Features/Home/HomeSpatialView.swift:256-310, 474` |
| T7 | Groceries keep pack sizes and US aisles; salt, oil and pepper are staples | partly | Pack size is kept and splits rows (`TesseraCore/Sources/TesseraCore/Kitchen/Groceries.swift:98-99, 226-234`) but is never drawn: `Groceries.packSize(of:)` at `Groceries.swift:68-70` has no caller in `Features/`. US aisle names are unchanged since 7b321d2 (`Kitchen/Aisles.swift:5-10` at both commits). Salt, oil and black pepper were staples on 7b321d2 already; plain "pepper" is not a staple (`Aisles.swift:30-34`; test `KitchenHotfixTests.swift:94`) |
| T8 | Secret words, money and body facts never reach Claude; a Claude key in a note is refused | true, new (#422, #451, #471) | `TesseraCore/Sources/TesseraTess/ClaudeTessModel.swift:54`; `TesseraCore/Sources/TesseraCore/Tess/PrivateFacts.swift:9`; `Features/Notes/NotesView.swift:82-84`; `TesseraCore/Sources/TesseraCore/Notes/Notes.swift:107` |
| T9 | Not yet fixed: a private note shows its second line in Notes; older notes show in the Day log. Both fixed in the next build | partly | First sentence true: `Features/Notes/NotesView.swift:185-201, 290-292` (the row draws the body's second line for any note); `DayStory.swift:345-347` (only notes titled "Private note" are hidden; no mark-private pass exists, and `docs/product/pin-checklist.md:20` is unchecked). "Both are fixed in the next build" is not on master after a36b161 (only #403 and #504 merged since), so it is a promise, not a fact |
| T10 | Your data: nothing changes; save a copy first; never restore a copy from this build onto the old one | true | `TesseraCore/Sources/TesseraCore/Export/TesseraBackup.swift:213-214`; `docs/product/decisions.md:269` |

## Team appendix

| Id | Claim | Verdict | Evidence at a36b161 |
|---|---|---|---|
| A1 | Compared with 7b321d2, installed Oct 16, 9:57 am PT | true | `docs/product/decisions.md:318` (origin/master) |
| A2 | Every line below is in that build | partly | True once A12, A14, A16, A17 and A20 are reworded; as written, the drawn pack size (A20) is not in the build |
| A3 | Glass tabs: hold the row, a lens forms, pages shrink side by side, letting go opens the one under it, a tap still works | true, new (#342) | `Features/Home/HomeSpatialView.swift:222-240, 256-310, 474`; a hold with no slide is a cancel (commit 9281b0d) |
| A4 | Home lines ("Push A, paused at bench", "Tacos done"), nothing cut short, 4 am day word | true, new (#366, #369) | `HomeLines.swift:284, 291, 301`; `HomeLineHero.swift:21-26, 57-93, 100-103` |
| A5 | Review: a band each for training, tasks done and cooking, then the week's lines; tap a day; tap again for the week | partly | The cooking band shows only when something was cooked that week (`ReviewPage.swift:289`). A second tap on a day's training mark opens that workout instead of going back to the week (`ReviewPage.swift:267-272`); the day letters and other bands do go back (`ReviewPage.swift:322-327`), as does a tap anywhere else (`:315-318`) |
| A6 | START wakes the page, the plan sinks away, the live workout grows out of the first exercise | true, new (#347) | `TrainingPage.swift:71-72, 113-116, 146`; `RootView.swift:59-63` |
| A7 | Context line "Push A, set 1 of 4", name never cut, LOG on the key, last time said once, "Rest skipped. Set 3 is up." | true, new (#381, #397) | `WorkoutParts.swift:197-201, 249-251`; `WorkoutModeView.swift:621-634`; `Features/Workout/Instruments/RepsRow.swift:79`; `Features/Workout/WorkoutSession.swift:490`. On the workout's last set the line reads "Push A, last set" (`WorkoutParts.swift:198-199`) |
| A8 | Training's Tess line stays quiet when today's target is last time's | true, new (#397) | `Features/Home/TrainingPage.swift:346-349` |
| A9 | Routines: make from a writing line, hold and drag, swipe left to drop, ROLLS ON / FIXED DAYS, each routine's days | true, new (#341, #359, #363) | `RoutinesPage.swift:104-154, 158-186, 190-232`; `Features/Plans/RoutineEditor.swift:413-510` |
| A10 | Bests stay on the day you set them after a later session beats them | true, new (#344) | `TrainingActions.swift:79, 143`; `DayStory.swift:536-545`; `TesseraCore/Sources/TesseraCore/DayLog/WeekFacts.swift:177` |
| A11 | Apple Health gets workouts you finish early | true, new (#463) | `App/Health/HealthExporter.swift:26-29` |
| A12 | Trips: each workout, task and set stays on the day it had where you were; times Tess reads with no zone are taken in yours | partly | Workouts, sets, done tasks on Today and the Day log read each record's zone (`WorkoutSummary.swift:99-104`, `Tasks.swift:43-48`, `WeekFacts.swift:203-220`, `Features/Exercise/ExerciseViews.swift:131, 148`). Review's "Tasks done" and "Cooked" bands still count in the zone you are in now (`Features/Home/ReviewWeek.swift:53-65`; open as N1/R12 in `docs/research/trip-check.md`). No-zone times: `TesseraCore/Sources/TesseraTess/TessTools.swift:25` (#494) |
| A13 | Your typing one size under Tess's voice, in the Ask bar, Notes and paste | true, new (#353) | `DesignSystem/Editorial.swift:8`; `DesignSystem/Theme.swift:75`; `NotesView.swift:145` |
| A14 | Tess working: fades, twelve faint lights, gathers, says Done; "You'll see it first on the key check in Review, under Claude" | partly | The motion is real (`Features/Tess/SoulWork.swift:3, 22`; `Features/Tess/SoulRouter.swift:127-137`). Its only trigger in this build is the key check (`Features/Settings/ClaudeSection.swift:339-345`), which lives in `ReviewView` (`Features/Review/ReviewView.swift:225`). That page opens as a full-screen cover (`HomeSpatialView.swift:161-173, 351`) over RootView, where Tess is drawn (`App/RootView.swift:37`), so she is hidden while the check runs |
| A15 | Holding Tess with the mic off settles her back to rest | true, new (#446) | `Features/Command/BottomChrome.swift:597-605`; `SoulRouter.swift:79-80` |
| A16 | The tab lens no longer gets stuck after you leave one of Tess's questions unanswered | partly | The fix lets a waiting question go when Tess's chrome leaves the screen (`BottomChrome.swift:112, 535-542`). While a question waits on Home the lens is still refused by design (`SoulRouter.swift:156-170`) |
| A17 | "pay rent fri" makes a task again; "pull-ups" is known as an exercise | partly | Both true at a36b161 (`TesseraCore/Sources/TesseraTess/TessGrammar+Kitchen.swift:80-86`; `TessGrammar.swift:434`; test `PrivacyFollowupTests.swift:68-69`). "Again" is wrong for his phone: on 7b321d2 "pay rent fri" was already a miss (7b321d2 `TessGrammar.swift:110-114`, `TessGrammar+Kitchen.swift:80-85`) |
| A18 | Undo after an empty workout is wrapped up brings it back | true, new (#494) | `TesseraCore/Sources/TesseraCore/Processes/ProcessTable.swift:136-142`; `ProcessActions.swift` (`DiscardEmptyWorkout`) |
| A19 | Secret words (password, PIN, code, wifi) make a private note; the Day log says "Private note" | true, new (#422) | `TesseraCore/Sources/TesseraCore/Notes/SecretWords.swift:8-36`; `Notes.swift:111-116`; `DayStory.swift:345-347`. Notes written before this build are not marked (T9) |
| A20 | Groceries keep pack size (" · 15 oz"), two can sizes stay two rows, salt, oil and pepper are staples, "for serving" stays on the recipe, prep words like "diced" drop off, US aisle words | partly | Two sizes stay two rows: true (`Groceries.swift:226-234`; recipe lines now store `packSize`, `SystemCatalog.swift:305-306`). " · 15 oz" is never drawn (`Groceries.swift:68-70` has no caller; `Features/Groceries/GroceriesView.swift:427-428` draws quantity and name only), so the two rows both read "1 can diced tomatoes". Staples: salt, oil and black pepper were already staples on 7b321d2; new are kosher salt, canola and similar oils, and "salt and black pepper" lines (`Aisles.swift:30-43`); plain "pepper" is not one. "For serving": true (`Quantities.swift:146-150`, `Groceries.swift:323-324`). Prep words: true, but "diced" stays on a can ("diced tomatoes", `Quantities.swift:221-225`). Aisle names are unchanged since 7b321d2; new are US ingredient words such as scallion and broth (`Aisles.swift` diff). Recipes pasted before this build keep the old behavior until re-pasted (`docs/research/groceries-check.md`, new item 6) |
| A21 | Pasted recipes leave out any line that looks private, never saved | true, new (#454) | `TesseraCore/Sources/TesseraCore/Kitchen/Recipes.swift:162-174`; `Features/Recipes/PasteRecipe.swift:205`; `SecretWords.swift:66-109` |
| A22 | The cook clock isn't in this build | true | no cook clock or cook mode code under `App/`, `Features/` or `TesseraCore/Sources/` |
| A23 | The Claude cap reads $50 a month (it was $10) | true, new (#422) | `TesseraCore/Sources/TesseraTess/ClaudeKey.swift:87-90`; `ClaudeSection.swift:198-210, 467`; 7b321d2 `ClaudeSection.swift:191, 202` read $10 |
| A24 | Looks: Porcelain, Plein, Celadon, Lacquer recut; Plein flat warm paper; Obsidian unchanged | true, new (#367) | `DesignSystem/Looks.swift:67, 91, 100` |
| A25 | Siri's Add a Task refuses your Claude key; "door code" with a number becomes a private note | true, new (#457) | `TesseraCore/Sources/TesseraIntents/Intents.swift:135-145` |
| A26 | A Claude key typed or pasted into a note is refused; Tess says it goes under Claude | true, new (#471) | `NotesView.swift:65, 82-84`; `Features/Notes/NoteEditor.swift:132`; `Notes.swift:107, 156`; `TesseraCore/Sources/TesseraCore/Diagnostics/ClaudeKeyGuard.swift:6` |
| A27 | Secret words stay private notes; never reach Claude, Tess's memory or the miss log | true, new (#422) | `ClaudeTessModel.swift:54`; `TesseraCore/Sources/TesseraCore/Tess/TessMemory.swift:139`; `TessMemory+Turnover.swift:67`; `TesseraCore/Sources/TesseraTess/TessCaptureEngine.swift:58`; `TessInbox.swift:30` |
| A28 | Money and body facts never go to Claude even with "Tess asks Claude" on; Tess still reads them on the phone | true, new (#451, #471) | `PrivateFacts.swift:9`; `ClaudeTessModel.swift:54`; tests `MoneyWallTests.swift:65-77`, `PrivacyFollowupTests.swift:37-43` ("knee hurts" becomes "Private note, kept.") |
| A29 | Your data: Catalog v9 only adds fields; save a copy (Review > Backups, SAVE A COPY); rollback 7b321d2 over the top; don't restore a new copy onto 7b321d2; this build won't open a newer copy | partly | v9 also adds a new kind of thing, Memory (`SystemCatalog.swift:24, 254-263`, #356), whose turnover writes lines at launch (`App/AppModel.swift:336-339`). The path is Review page, then the "The week" link, then Backups (`HomeSpatialView.swift:195, 340, 351`; `ReviewView.swift:229-233`; `Features/Backup/BackupView.swift:128`). Rollback and newer-copy lines true (`docs/product/pin-checklist.md:53-55`; `BackupView.swift:256-257`; `TesseraBackup.swift:213-214`) |
| A30 | Try 1: hold the tab row and slide the lens | true | `HomeSpatialView.swift:256-310`. Refused only while Tess listens or a question waits (`SoulRouter.swift:167-170`) |
| A31 | Try 2: open Review and tap a day | true | `ReviewPage.swift:257, 322-327` |
| A32 | Try 3: start a workout, hold LOG for a set, then skip the rest | true | LOG is a 0.7 s hold (`WorkoutModeView.swift:624`); SKIP REST (`:646-652`); Tess then says "Rest skipped. Set 2 is up." (`WorkoutSession.swift:490`, `WorkoutParts.swift:249-251`). The set is real and lands in his history |
| A33 | Try 4: on Routines, switch to FIXED DAYS and give a routine its days | true | Training page ROUTINES (`TrainingPage.swift:214`), FIXED DAYS (`RoutinesPage.swift:158-186`), the routine's DAYS line (`RoutineEditor.swift:413-510`). This changes his real plan: on fixed days, routines with no days are skipped (`TesseraCore/Sources/TesseraCore/Training/PlanSchedule.swift:11-18`) |
| A34 | Try 5: in Notes, type "wifi password is tacocat4417", see it kept as a private note | true | Notes opens from the Review page's "Notes" link (`HomeSpatialView.swift:195`); `NotesView.swift:118-121` writes `CreateNote`; "wifi" before "password" and "is" counts (`SecretWords.swift:22-36`); the note is titled "Private note" (`Notes.swift:111-113`) and, being one line, has no second line to show (`NotesView.swift:290-292`) |
| A35 | Built from: the 28 PRs plus #366 (with #369) | true | all are first-parent merges in `7b321d2..a36b161` and ancestors of a36b161 (table below) |
| A36 | Not in this build: P14, the ", best" day story wording (still ", PR"), the pass that marks older notes private | true | `DayStory.swift:225` still writes ", PR"; no mark-private pass in `App/` or `TesseraCore/Sources/`; Siri's Add a Task checks the key and secret words only (`Intents.swift:135-145`) |

## Suggested rewrites

Each replaces the page's line as it stands.

**T7** (line 11)

> - **Groceries** keep each can's size, so two sizes stay two rows; kosher salt, more oils and "salt and black pepper" count as staples.

**T9** (line 13)

> - **Not yet fixed:** in the Notes list a private note still shows its second line, and a note written before this build can still show its first line in the Day log. Both fixes are planned for a later build.

**A2** (line 19): keep as is once A12, A14, A16, A17 and A20 are reworded.

**A5** (line 24)

> - **Review** is your week on one page: a band for training and one for tasks done (and one for cooking once you've cooked that week), then the week's lines. Tap a day to read just that day; tap its letter again, or anywhere else, for the week. While you read a day, its training mark opens that workout.

**A12** (line 33)

> - **Trips:** on your Oct 26 trip, each workout, set and done task stays on the day it had where you were, on Today and in the Day log. Review's task and cooking bands still count by the zone you're in. Times Tess reads with no zone are taken in yours.

**A14** (line 37)

> - **Tess working:** when she waits on Claude she fades and splits into twelve faint lights, then gathers and says Done. In this build only the Claude key check starts it, and that page covers Tess, so there is nothing to see yet.

**A16** (line 39)

> - **The tab lens** works again after you leave Home while one of Tess's questions is still waiting.

**A17** (line 40)

> - **"pay rent fri"** makes a task, and "pull-ups" is known as an exercise.

**A20** (line 47)

> - **Groceries** from a recipe keep each can's size, so a 14.5 oz and a 28 oz can stay two rows (the size isn't shown on the row yet). Kosher salt, more oils and "salt and black pepper" count as staples. "For serving" lines stay on the recipe. Prep words like "chopped" drop off, and US names like scallion and broth find their aisle. Recipes pasted before this build work the old way until you paste them again.

**A29** (line 63)

> **Your data.** Catalog v9 only adds: new fields, and Memory, the lines Tess keeps about you. Nothing you have is changed. Save a copy first (Review, then The week, then Backups, SAVE A COPY). If you need to go back, the rollback build is 7b321d2, installed over the top. Don't restore a copy saved on the new build onto 7b321d2. This build won't open a copy from a newer Tessera; it asks you to update first.

Optional cautions for the try list (both steps work as written):

> 3. Start a workout, hold LOG for a set you really did, then skip the rest.
> 4. On Routines, switch to FIXED DAYS and give a routine its days. Routines with no days are skipped, so give each one its days or switch back to ROLLS ON.

## Built from: ancestry check

Command per PR: `git log --oneline --first-parent 7b321d2..a36b161 | grep '#NNN '`, then
`git merge-base --is-ancestor <merge> a36b161`. Every merge below is also not an ancestor of 7b321d2.

| PR | Merge | Branch | Ancestor of a36b161 |
|---|---|---|---|
| #341 | 13a8819 | core/plan-days | yes |
| #342 | 484c8b7 | ios/tab-lens | yes |
| #344 | 2ea54fd | core/set-record | yes |
| #347 | 7bdf2f6 | ios/training-rise | yes |
| #348 | fa924c4 | core/week-facts | yes |
| #352 | 4bc7c48 | ios/review-week | yes |
| #353 | 6c89616 | ios/field-18 | yes |
| #359 | 6e29eae | ios/routines-days | yes |
| #363 | e9bfef0 | core/plan-days-2 | yes |
| #366 | 6047078 | ios/home-lines | yes |
| #367 | 0e128c1 | ios/looks-recut | yes |
| #369 | 21f406d | core/home-lines-2 | yes |
| #377 | 0bff60b | core/trip-zones | yes |
| #380 | 1698cf7 | core/kitchen-week | yes |
| #381 | c17ca66 | ios/live-workout | yes |
| #391 | abb6cec | ios/history-zone | yes |
| #397 | 732d72f | ios/live-followups | yes |
| #402 | dbc2557 | ios/soul-router | yes |
| #422 | 5af8f2c | core/secret-words | yes |
| #446 | 0eca9bb | ios/refused-hold | yes |
| #451 | bf2a4bb | core/money-wall | yes |
| #453 | cb7cc7d | ios/tess-working | yes |
| #454 | 234080a | core/paste-link-wall | yes |
| #457 | cf50bb0 | core/siri-task-wall | yes |
| #463 | b2fe432 | ios/health-finish-early | yes |
| #467 | e10b698 | ios/ask-left | yes |
| #471 | 68c9a19 | core/privacy-followups | yes |
| #475 | 76be1c0 | core/catalog-version-guard | yes |
| #494 | 06be7a5 | core/tess-riders | yes |
| #498 | a36b161 | core/no-backup-in-memory | yes (the pin itself) |

**Missing from the list.** These first-parent merges in `7b321d2..a36b161` change app or engine code but are not in
"Built from":

- **#356** (38466f1, core/tess-memory): TessMemory. It adds the Memory class to Catalog v9 and runs a turnover at
  every launch (`App/AppModel.swift:336-339`). The page relies on it ("Tess's memory", A27) and A29's "only adds
  fields" misses it. Add it.
- **#469** (bdf81cd, core/plan-pack-guards): Plan my day guards; private titles go to Claude as "task" or "busy"
  (`TesseraCore/Sources/TesseraTess/PlanWording.swift:38`). Privacy-relevant; add it.
- **#399** (0fc38b7, core/opzones-incremental): faster bests and zone reads behind the trip lines. Add it.
- **#487** (1d05b38, ios/fake-key-hygiene): the made-up key used for recordings, now built at run time in
  `Features/Settings/ClaudeSection.swift`. Nothing he sees changes; list it or say why not.
- **#405** (31ad677, core/appclock-pin): DemoData only, simulator-only. Fine to leave out.

The rest of the range is docs, scripts and CLAUDE.md (#489).

## Lines that must not be on the page

- **P14, Siri money and body facts:** not claimed. A25 says only that Add a Task refuses the key and files a secret
  as a private note, which matches `Intents.swift:135-145` (no `PrivateFacts` there). A28 is about Claude, and Siri's
  Add a Task never calls Claude.
- **", best" in the day story:** not claimed. A10 and T5 say bests stay on their day, which is the `wasRecord` flag;
  the page itself says the day story still reads ", PR" (`DayStory.swift:225`). Home's "Bench best." line is real
  (`HomeLines.swift:248-249`).
- **The pre-#422 private pass:** not claimed. T9 and the "Not in this build" sentence both say older notes are not
  marked. A19 and A27 hold for notes written on this build.

## The try list and the placeholder note

1. Hold the tab row: works. A hold with no slide puts the page back where it was.
2. Open Review and tap a day: works on the Review page (the leftmost page).
3. Start, LOG, skip rest: works. The key reads "LOG 82.5 × 8" (a 0.7 s hold), then SKIP REST, then Tess says
   "Rest skipped. Set 2 is up." The set is real.
4. FIXED DAYS: works from Training, ROUTINES, FIXED DAYS, then a routine's DAYS line. It changes his real plan.
5. "wifi password is tacocat4417" in Notes: works. "wifi" counts because "password" and "is" follow, the note is
   titled "Private note" in the list and the Day log, and as a one-line note it has no second line to leak. It is
   not refused as a key.
