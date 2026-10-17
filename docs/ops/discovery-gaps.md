# Discovery gaps (Tessera master 0924ff6c vs sheets 41-77, decisions to 5:47 PM PT Oct 16)

Method: read code under /tmp/tsr (Features, App, Widgets, DesignSystem, TesseraCore/Sources), the sheets named per item, and every board in ops/board. I dropped anything already boarded, including: SideHost and all drawn sides (Core 0ak, Builder B 0y, A 0p), area index and title accent (A 0p), Habits, Body weight, Money, Reading, Upkeep, People, Day log page, Settings page, Health words and private-field masks (Core 0ai, 0ah), Shutdown (0k, 0n), notifications and the cook timer Live Activity, LAST TIMES, accessibility rows, house copy sweep, backups "Seven are kept", the launch-flag guards, the audit-ui-bar rows. The app's privacy walls (SecretWords and PrivateFacts at TessCaptureEngine.swift:59-60, ClaudeTessModel.swift:54, TessInbox.swift:30/65, PlanWording.swift:37, RecipeLinkReader.swift:108/369, both CaptureMissLog callers) held up on a quick trace: no leak found. No key-shaped string was found in the repo (a regex scan for the Anthropic key shape matched no file); ClaudeKey.swift keeps the key in the Keychain only (ClaudeKey.swift:48).

The boards are saturated, so only 14 real gaps survived. Items 1 to 8 are confirmed code-versus-sheet contradictions or missing guards; items 9 to 14 are required-but-unbuilt things that no board line owns. Ranked by what Kaushik feels daily.

---

## 1. Finishing a task plays the wrong haptic, and on Home it can play two
- Owner: Builder B (Home), Core for the pattern API; QA verifies on device.
- Evidence: Home's row finish plays a raw `.impact(medium 0.8)` at HomeQueue.swift:279 (trigger bumped at HomeQueue.swift:432); the hero finish plays the same raw impact at NowPage.swift:118 (trigger NowPage.swift:313); and the soul adds a raw `.success` when Tess goes Done at TessSoul.swift:129 (doneCount, TessSoul.swift:97). So one finish can fire two different haptics. `Haptic.done` (the three-beat pattern, Haptics.swift:47/153) is only played for a finished workout (WorkoutModeView.swift:704). Sources: task-reward.md rule 3 ("one haptic per beat, one source per moment") and its Done table (`.selection` when armed, then the finish pattern); Haptics.swift:5 says views never use raw `.sensoryFeedback`.
- Done when finishing a task by swipe, by the hero key or by VoiceOver Done plays `.selection` at arm and exactly one `Haptic.done` at release, TessSoul's `.success` no longer fires for the same moment, and a unit test on the cue counts one `.done` per finish.

## 2. The capture "made" moment has the wrong haptic and the listening haptic is missing
- Owner: Builder B (BottomChrome, Ask Tess).
- Evidence: BottomChrome.swift:131 plays `.success` when the soul lights (`model.soul.isBright`), not `Haptic.made` (soft 0.6 at the landing, task-reward.md "Made" table, t=420). `.made` is played only at RoutinesPage.swift:153 and TrainingPage.swift:156. `Haptic.listening` and `Haptic.fleckReachesNow` are defined (Haptics.swift:13, 53) and never played (SpeechListener.swift has no haptic).
- Done when a typed or spoken capture that lands a task, note or grocery plays one `.made` at the landing and nothing else, listening start plays `.listening` once, and `.success` is gone from BottomChrome.

## 3. Raw `.sensoryFeedback` is scattered across about 25 sites, so "one haptic per moment" cannot be enforced
- Owner: Builder B with Builder A (DesignSystem), QA for the lint test (item 8).
- Evidence: raw calls at PasteRecipe.swift:137, RecipePage.swift:142, PortionDrum.swift:45, BottomChrome.swift:130-132, ReviewPage.swift:312, GroceriesView.swift:190/344/517, BackupView.swift:103, ExercisePage.swift:210, CarriageRail.swift:47, LookSentence.swift:69-70, CaptureParts.swift:141, InkActions.swift:78, RoutineEditor.swift:93, Paint.swift:306-310 (every PaintKey), HomeQueue.swift:265-266/279-280, NowPage.swift:118, TessSoul.swift:129. Haptics.swift:5 says all haptics go through `.tesseraFeedback` so "this map is the code"; source task-reward.md "The haptics map". Several are the same moment as a `Haptic` case (GroceriesView.swift:517 is `.aisleCleared`).
- Done when every moment is played through `.tesseraFeedback` with a `Haptic` case (adding cases where the map has a gap), and no `.sensoryFeedback(` remains in Features or DesignSystem outside Haptics.swift.

## 4. The no-dots rule (Kaushik, 8:07 PM Oct 15) is not applied in Notes, Groceries, Paste, capture and the Exercise page
- Owner: Builder B (Notes, Groceries, Recipes, capture), Builder A (Exercise page).
- Evidence: `PaintDab` still sits before or beside text at NotesView.swift:140 (writing-line dab; notes-grammar.md says drop it and no-dots.md row 41), NoteEditor.swift:80 (a dab before every link), GroceriesView.swift:436 (sage dab at the row end; no-dots.md row 39 wants the recipe's first word in inkSecondary, "PASTA" or "2 RECIPES"), GroceriesView.swift:173 (struck items fly as dabs), PasteRecipe.swift:366, CaptureParts.swift:51 (dab behind the capture word), ExerciseViews.swift:245 (a dab before each exercise row name). no-dots.md Tokens: "Retire PaintDab in rows. Keep the type for data marks only ... never before or after text." No board line carries this sweep (the only no-dots mentions on the ios boards are one audit sentence and the Review habit mark). Review's week dabs (ReviewPage.swift:294/420, MonthPage.swift:162) are data marks and stay.
- Done when no `PaintDab` is drawn adjacent to text outside data marks, PaintDab's doc line says so, and each touched screen has its recording or UI-test row from no-dots.md.

## 5. A failed write still says "done": about 50 `try? model.engine.perform` sites ignore the result
- Owner: Core (a `perform` helper returning a result plus Tess's failure line), Builder B and Builder A (call sites), QA (fault-injection test).
- Evidence: NowPage.swift:311-318 bumps `finishes` and speaks "Done. Next one is up." even when the action threw and `record` is nil; GroceriesView.swift:233 and :247 check and uncheck with `_ = try?` and animate success regardless; RoutineEditor.swift:201 returns nil and the caller still shows its line; WorkoutSession.swift:368 swallows a failed `LogNextSet` (a lost set in the gym is the worst case). 52 sites in Features and App. Principle: Tess's line and the data never disagree.
- Done when a failing store (an injected throw) makes the finish, grocery check, set log and routine edit each show one plain line ("Didn't save. Try again.") with no reward animation or haptic, with a test per call-site family.

## 6. Home Screen widgets, Lock Screen accessories and Siri snippets do not exist; only the rest Live Activity ships
- Owner: Builder A (Widgets), Core (a shared snapshot of Home's line), Design reviews.
- Evidence: Widgets/TesseraWidgetsBundle.swift:7 holds only `RestLiveActivity()`. widget-states.md and lockscreen.md draw every Home Screen, Lock Screen and snippet state with HomeLines copy (board item 54 done). The only build mention is a stale numbered line, ios-a.md:74 ("8. M4 slice 10 ... pulled forward"), which no lane has pulled. Both entitlements already carry `group.com.kaushikaranagu.tessera` (Widgets/TesseraWidgets.entitlements, App/Tessera.entitlements) and Looks.swift:121 uses the group. Principle: Tess's line and Home never disagree, on every surface.
- Done when a small and a medium widget plus rectangular and inline Lock Screen accessories render the HomeLines hero for running, resting, rest day, all quiet and day closed, read the active look from the App Group, and a test fails if a widget line differs from `HomeLines.line` for the same fact.

## 7. The Siri intents cannot read anything or touch Groceries, Cooking or Notes
- Owner: Core (TesseraIntents), Builder A (shortcut phrases), QA (walls rows).
- Evidence: TesseraIntents/Intents.swift defines only LogSet, LogNextSet, UndoLastSet, StartRoutine, FinishWorkout, CreateTask and TellTess; App/AppIntentsPackageLink.swift:15-26 registers six phrases, none about groceries, a cook or today. widgets-and-snippets.md "Snippets (Siri, Shortcuts, the Action button)" requires answers as snippets, and task-reward.md treats Siri as a first-class capture path. No snippet intent exists.
- Done when "What's next in Tessera" answers with Home's line and "Add oat milk to groceries in Tessera" writes a grocery through the engine, both pass the same walls as the Bar, and each shows a snippet in the baseline language.

## 8. Nothing keeps the house rules from drifting back (dabs, raw haptics, system symbols, small text)
- Owner: QA.
- Evidence: items 3 and 4 slipped past many reviews; TesseraTests and TesseraUITests have no static-rule suite, and audit-ui-bar.md was done by hand.
- Done when one `HouseRulesTests` fails on a raw `.sensoryFeedback(`, a `PaintDab` next to `Text`, `Image(systemName:` or `systemImage:` in Features (known exceptions ObjectPage.swift:435 and WorkoutParts.swift:57 are already boarded), a `.font(.system(size:` below 16, and an em dash in a string.

## 9. PRIVACY: private notes ride into the iCloud Drive backup folder and the Backups page never says so
- Owner: Research (decide), Design (one line), Builder B (BackupView).
- Evidence: `isPrivate` is named "Stays on this phone" (SystemCatalog.swift:264), but BackupKeeper (BackupKeeper.swift:11-13) copies the whole database to Documents/Backups and to a chosen iCloud Drive folder; BackupView.swift has no wording about private notes, body weight or money. every-side.md row 25 promises the side "WHAT'S IN ONE" shows what a copy holds. It stays out of Claude but leaves the phone to his own iCloud.
- Done when Product rules whether private notes, body weights and money entries are in the iCloud copy, the Backups page says so in one line (or the copy leaves them out), and a test covers whichever is decided.

## 10. Quiet failures (daily copy, Health export, miss log) have no surface
- Owner: Builder B.
- Evidence: HealthExporter swallows errors (boarded only as a counts-only line to come); `CaptureMissLog.record` "Never throws ... is skipped" (CaptureMissLog.swift:36-60) and Backups shows only daily-copy failures (BackupKeeper.swift:34-60). A full disk would stop the log and the Health copy silently.
- Done when one quiet line on Backups lists any copy, Health export or log that failed since its last success and clears itself on the next success.

## 11. PRIVACY (low): capture-misses.jsonl has no explicit file protection
- Owner: Core.
- Evidence: CaptureMissLog.swift:40-66 writes up to 2,000 raw phrases (200 characters each) with no `.completeFileProtection`; TessMemory.swift:595 sets it for the memory file. The log is already walled and excluded from device backup, so this is hardening only.
- Done when the miss log and the Tess memory file use the same protection class and a test asserts the attribute on the created file.

## 12. The task-reward flight beats are unbuilt: made words flying into Next, and the done fleck
- Owner: Builder B (Home), Motion lab (reference), QA.
- Evidence: task-reward.md "Made" (words fly to the sorted slot in Next, 420 ms, rows part 46 pt) and "Done" (a fleck leaves the strike end and arcs to its target). `Haptic.fleckReachesNow` exists (Haptics.swift:13) with no animation or caller; `grep -i fleck` in Features and DesignSystem finds only the enum. Not named in any board line apart from the 0p title work.
- Done when a made task's words visibly fly into their Next slot and a finished task shows the settled strike plus the fleck beat (or Design formally drops the fleck), each with the one haptic from items 1 and 2 and a Reduce Motion variant.

## 13. Groceries: finishing the shop and checking items give no named line or map haptic
- Owner: Builder B (Groceries), Kitchen for the line.
- Evidence: GroceriesView.swift:212-243 strikes, sinks and records `CheckListItem` with no line; only clearing the basket speaks (GroceriesView.swift:260). The landing uses a raw light impact (:190) and aisle cleared a raw medium impact (:517, `Haptic.aisleCleared` unused). `Haptic.done` is documented for "the shop finished" (Haptics.swift:7), but toggleShop (GroceriesView.swift:265-274) plays nothing and says nothing; groceries-tess.md keeps Groceries quiet but finishing a shop is a done moment.
- Done when finishing a shop plays `.done` once with a one-line receipt and UNDO, the last item of an aisle plays `.aisleCleared`, and an item check stays silent in words but plays its one tap from the map.

## 14. PRIVACY: no screen lets Kaushik check what actually left the phone
- Owner: Design, then Builder B.
- Evidence: every-side.md row 21 gives the week page a side "WHAT LEAVES THE PHONE" (this month's Claude calls by job, titles and counts only), but no screen on master lists what was sent (Features/Plans/Receipts.swift covers Tess actions; ClaudeSection.swift has the key and the spend, no per-job list).
- Done when a "What was sent" list (job names and counts, no text) under the Claude section shows the last 30 days by job, and a walls test proves a walled phrase never appears in it.

---

## Summary
Fourteen real gaps, because the boards already carry the big designed-but-unbuilt areas. Top five by daily feel: (1) task finish plays the wrong and sometimes doubled haptic, (2) the capture landing and listening haptics are wrong or missing, (3) about 25 raw haptic sites bypass the one-haptic map, (4) dabs remain in Notes, Groceries, Paste, capture and the Exercise page against the 8:07 PM no-dots call with no board line to sweep them, (5) about 50 `try?` writes can show "done" for something that did not save, including a gym set. After those: unowned widget, Lock Screen and Siri snippet surfaces, a missing house-rules lint, and three PRIVACY items. No key-shaped string was found.
