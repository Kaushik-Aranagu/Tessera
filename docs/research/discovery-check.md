# Discovery check (master a8c3e6e, 48 commits after 0924ff6c)

Result: all 14 items are already boarded. The 5:51 pm "DISCOVERY items" decisions put them on the lanes below, so the Product lead dropped nothing. None is fixed. One is partly stale (item 9). Evidence below is current master, checked read-only.

| # | Item | Status | Board line (file, first words) | Evidence on master now | Owner |
|---|------|--------|--------------------------------|------------------------|-------|
| 1 | Finish haptic wrong or doubled | boarded as ios-b D1 | board/ios-b.md:163 "(D1) One haptic per finish on Home: HomeQueue.swift:279 and NowPage..." | Still true. HomeQueue.swift:280 raw impact, NowPage.swift:118 raw impact, TessSoul.swift:129 raw `.success`. `Haptic.done` is used only by the workout finish. Lines moved by 1. | Builder B |
| 2 | Made and listening haptics | boarded as ios-b D2 | board/ios-b.md:164 "(D2) Capture landing plays Haptic.made, not .success..." | Still true. BottomChrome.swift:131 `.success`. `.listening` and `.fleckReachesNow` have no caller (SpeechListener.swift has no haptic). | Builder B |
| 3 | About 25 raw `.sensoryFeedback` | boarded as ios-b D4, ios-a D1, qa D1 | board/ios-b.md:166 "(D4) Raw .sensoryFeedback calls (about 25 sites) move onto Haptic cases..." | Still true: 31 call lines in Features and DesignSystem (Paint.swift:306-308, LookSentence.swift:69-70, InkActions.swift:78, BottomChrome.swift:130-132, GroceriesView.swift:190/344/517 and the rest). Count is 31 lines, not 25. | Builder B and A |
| 4 | No-dots sweep | boarded as ios-b D3 and ios-a D2 | board/ios-b.md:165 "(D3) The no-dots sweep (his 8:07 PM Oct 15 rule): PaintDab still sits..." | All 7 sites remain: NotesView.swift:140, NoteEditor.swift:80, GroceriesView.swift:173/436, PasteRecipe.swift:366, CaptureParts.swift:51, ExerciseViews.swift:245. | Builder B, A |
| 5 | `try? perform` says done | boarded as core D1, ios-a D4, research BZ | board/core.md:258 "(D1) A failed write must never say done: about 50 try? model.engine.perform sites..." | Still true; now 60 matches in Features and App. NowPage.swift:314, GroceriesView.swift:233/247/278, RoutineEditor.swift:201, WorkoutSession.swift:368. | Core |
| 6 | Widgets, Lock Screen, snippets absent | boarded as ios-a D3, core D3, design D4 | board/ios-a.md:111 "(D3) Home Screen widgets, Lock Screen accessories and Siri snippets do not exist..." | Still true. Widgets/TesseraWidgetsBundle.swift:7 holds only `RestLiveActivity()`. Old numbered line ios-a.md:74 ("8. M4 slice 10, widgets and snippets, pulled forward") is a second, stale owner of the same work. | Builder A |
| 7 | Siri intents cannot read or touch groceries | boarded as core D2 | board/core.md:259 "(D2) Siri intents that read and that touch Groceries: ..." | Still true. TesseraIntents/Intents.swift has 7 intents, none for groceries or reading. AppIntentsPackageLink.swift:15-26 has six phrases. | Core |
| 8 | No house-rules lint | boarded as qa D1, core D5 | board/qa.md:31 "DISCOVERY items for QA (decisions 5:51): (D1) HouseRulesTests, one static suite..." | Still true. No HouseRules file in TesseraTests or TesseraUITests. | QA |
| 9 | Private notes in iCloud copy, page silent | boarded as ios-b D8, design D2 | board/ios-b.md:170 "(D8) Backups says what a copy holds (decisions 5:51: everything, private notes, weight..." | Page still silent (no wording in Features/Backup/BackupView.swift). The Research question is answered: everything is included. Only the one line and Design's wording remain. Stale: "Research (decide)" is no longer open. | Builder B, Design |
| 10 | Quiet failures have no surface | boarded as ios-b D7 | board/ios-b.md:169 "(D7) One quiet line on Backups listing any daily copy, Health export or miss log..." | Still true. BackupKeeper.swift:49-60 tracks daily-copy failures only. | Builder B |
| 11 | Miss log file protection | boarded as core D4 | board/core.md:260 "(D4) Hardening: capture-misses.jsonl and the Tess memory file share one file-protection class..." | Still true. TessMemory.swift:595 has `.completeFileProtection`. CaptureMissLog.swift:45-74 uses `createFile` and `write` with none. | Core |
| 12 | Flight beats and fleck unbuilt | boarded as ios-b D6, motion, design D3 | board/ios-b.md:168 "(D6) Task-reward flight beats: made words fly into their Next slot and the done fleck..." | Still true. "fleck" appears only in Haptics.swift:12-13, 48. | Builder B |
| 13 | Shop finish and aisle haptics | boarded as ios-b D5 | board/ios-b.md:167 "(D5) Groceries: finishing a shop plays .done once with a one-line receipt and UNDO..." | Still true. `finishShop` (GroceriesView.swift:276-283) uses `_ = try?` and bumps `finished` with no haptic or line. Raw haptics at :190/:344/:517. `Haptic.aisleCleared` (Haptics.swift:39) has no caller. toggleShop is now :265-274. | Builder B |
| 14 | No "What was sent" list | boarded as ios-b D9, design D1 | board/ios-b.md:171 "(D9) A "What was sent" list under the Claude section: job names and counts for 30 days..." | Still true. No such screen; HomePlan.swift:26 only shows a one-time plan line. | Design, then B |

Counts: boarded 14 (item 9 partly stale), new 0, now fixed 0, stale evidence 1 (item 9), line numbers shifted 2 (items 1, 13).

## Missed by the discovery run
1. Finishing a workout swallows errors. WorkoutSession.swift:619 and :621 use `try? ... FinishWorkoutEarly/FinishWorkout`, and WorkoutSession+Edit.swift:38 and :52 swallow edits and deletes. Item 5 names only LogNextSet. Owner: Core (perform helper), Builder A.
2. A literal color bypasses the theme: HomeSpatialView.swift:255 `Color(red: 10 / 255, ...)`. Not in the HouseRulesTests list. Owner: Builder B, QA adds the rule.
3. The Lock Screen set was never covered by the stale-line rule for widgets: ios-a.md:74 still reads as an open numbered item while D3 owns the work, so two lines can drift. Owner: Product lead (retire ios-a.md:74).
4. HouseRulesTests lacks two rules the house already states: no `Capsule` or rounded-rectangle button (no-buttons rule; see HomeSpatialView.swift:476, 11 `RoundedRectangle` uses in Features need a button-versus-shape triage) and no `withAnimation`/`.animation` outside MotionPolicy (DesignSystem/Editorial.swift:77, Paint.swift:123/296). Owner: QA.
5. Item 13's undo: FinishShop has no UNDO window wired, though Core's UndoWindow (ios-a 0i) covers other finishes. Owner: Builder B.

## Boarded but needs a sharper done-when
- ios-b D2 and D6: "listening start plays `.listening` once" and "flight beats" have no test or recording named. Add a cue-count test and a Reduce Motion clip.
- ios-b D3: "no PaintDab next to text" needs a named allowed list (Review week dabs, MonthPage.swift:162) so QA's rule does not flag data marks.
- ios-b D7: "failed since last success" needs a storage place and a clearing test.
- core D2: "same walls as the Bar" should cite the walls fixture rows.
- ios-a D3: needs the widget kinds and the test that a widget line equals `HomeLines.line`, as the item text had.
- ios-b D8: now decided; reword to "add one line and a test that the copy holds private rows".
