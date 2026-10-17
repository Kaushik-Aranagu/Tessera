# Private-title masks: one row per display site (PT1 to PT44)

*Research, Oct 17, 2026. For Core, Builder A and Builder B. Written from QA's sweep (`qa/review-private-title-sweep-oct17.md`, master 47365b08, static, in project files not master) and re-read by hand on origin/master 47365b0 (Merge #874). Every line number below was checked on that commit and matches the sweep. Nothing was built or run. Every input is made up.*

**The ruling.** Mask at source; only the live typing field shows raw. A read-only surface gets its words from a masked source (so every screen, VoiceOver label, Siri line and receipt downstream is masked at once). The one place the raw title shows is a field he is typing into (today `TextField("Name it", ...)` at `Features/Plans/RoutinesPage.swift:103`). No screen is exempt for being his own routine (decision 12:40 pm, as the sweep quotes it), so the routine pages need the rule too.

## 1. The masking functions that exist

| Function | Where | Returns | Use for |
|---|---|---|---|
| `ObjectPrivacy.routineTitle(_:in:)` | `TesseraCore/Sources/TesseraCore/Tess/ObjectPrivacy.swift:22` | `ObjectPrivacy.routineLabel` ("Private workout") when `PrivateWords.isPrivateTitle` holds (secret word, money, body fact, medicine, or a care word such as rehab or physio), else the title | A routine's title, or a workout's (a workout is created with its routine's title, `PlanActions.swift:124`) |
| `WorkoutSummary.doneLine(in:)` | `Training/WorkoutSummary.swift:43-47` | Done line with the title masked | Already masked; the model for the others |
| `WorkoutSession.shownTitle` | `Features/Workout/WorkoutSession.swift:30-31` | `routineTitle(workout.title, ...)` | The one masked session title; reuse it for any running session |
| `ListContents.shownName(of:in:)` | `TesseraCore/Sources/TesseraCore/Lists/ListRuns.swift:19` | "Private list" (`privateListLabel`, :17) | A list's name |
| `AddListItem.shownTitle(_:store:)` | `TesseraCore/Sources/TesseraCore/Lists/Lists.swift:310` | "Private item" (`privateItemLabel`, :307) | A list item's title |
| `ObjectPrivacy.label(of:in:classes:)` | `ObjectPrivacy.swift:30` | "Private note", "Private task", "Private memory", "Private recipe", or nil | A note, task, memory or recipe; returns nil for a workout or routine, which is why the generic page leaks them (PT24) |
| `ObjectPrivacy.isPrivateWord(_:in:)` | `ObjectPrivacy.swift:84` | Bool | A free word he typed that a line would echo |

"Private routine" is **not** a literal anywhere in code (`git grep -F` finds none). The label for a routine's title is "Private workout" (`ObjectPrivacy.routineLabel`, decision 12:35 pm on #849). Ruled (Product, decisions 4:20 PM Oct 17, O1): routines read "Private workout" too, one label everywhere.

## 2. Trap inputs (words only; seed these, then run every row)

- **T1, a routine called after a medicine.** A routine whose title is just a medicine name, then the same name with a dose word. Expect "Private workout" everywhere, and the same title still searchable by its owner only in the typing field.
- **T2, a workout titled with a body weight.** A routine or workout titled "Weigh in" followed by a weight with a decimal and a unit, and a second titled with only a number that equals his last weigh-in (the last-weight match in `PrivateFacts`). Expect "Private workout".
- **T3, a list titled with a rent amount.** A list named "Rent" followed by a four-digit amount. Expect "Private list"; its items follow the item rule (a rent item is "Private item" only if it trips the item test).
- **T4, a care word.** A routine titled with a rehab or physio word and no number. Caught only by `PrivateWords.titleWords`, so a row that uses `PrivateFacts.isPrivateTitle` alone misses it.
- **T5, a secret word.** A routine whose title holds a pin or code word and digits.
- **T6, the control.** A plain "Push Day A". Must read as typed on every row (the mask must not be over-eager).
- **T7, case and spacing.** T1 typed in capitals with extra spaces; a mask that compares raw strings misses it.
- **T8, the search side.** Searching Shortcuts for the medicine word must not list the routine by its raw title (PT9).

Each row's "Traps" column names which of these to run. All rows also run T6.

## 3. The table

Status: **traced** means I read the line on 47365b0 and saw the raw title (or the masking call). **inferred** means I read the source and the data path but not every caller. Owner: Core is `TesseraCore/Sources/...`; Builder A is Home, Now and Command; Builder B is Plans, Objects, Review, Training and the Live Activity files.

| # | Site (file:line) | Shows today for a private-titled object | Expected | Mask function at source | Swift Testing name | Status | Owner | Traps |
|---|---|---|---|---|---|---|---|---|
| PT1 | `DayPlan.Block` built in `workoutBlock`, `TesseraCore/.../Tasks/DayPlan.swift:306` (struct at :12) | Raw: `title: workout.title` | "Private workout" | `ObjectPrivacy.routineTitle` where `PlanInput.Workout` is built (the block cannot reach the store); or add a shown title to the input | `dayPlanWorkoutBlockTitleIsMaskedForPrivateRoutine` | traced | Core | T1 T2 T4 |
| PT2 | `DayPlan` skipped workout, `DayPlan.swift:243` and :267 (`notPlanned`) | Raw: `workoutSkipped = workout.title`, then listed in `notPlanned` | "Private workout" | same as PT1 (once at `PlanInput.Workout`) | `dayPlanNotPlannedWorkoutIsMaskedWhenNoFit` | traced | Core | T1 T2 |
| PT3 | `DayStory` finished workout line, `DayLog/DayStory.swift:236` | Raw: "\(workout.title), N min..." | "Private workout, N min..." | `ObjectPrivacy.routineTitle` on `workout.title` (lookup is already store-backed) | `dayStoryFinishedLineMasksPrivateRoutineTitle` | traced | Core | T1 T2 T4 T5 |
| PT4 | `DayStory` running workout line, `DayStory.swift:240` | Raw | "Private workout, N sets" | same | `dayStoryRunningLineMasksPrivateRoutineTitle` | traced | Core | T1 T2 |
| PT5 | `DayStory` unfinished workout line, `DayStory.swift:243` | Raw | "Private workout, N sets..." | same | `dayStoryUnfinishedLineMasksPrivateRoutineTitle` | traced | Core | T1 T2 |
| PT6 | `ScheduleItem` for tonight's workout, `App/AppModel.swift:564` (struct :18) | Raw: `title: workout.title`; feeds Home and Now lists (HomeQueue.swift:74, NowPage.swift:470) | "Private workout" | `ObjectPrivacy.routineTitle(workout.title, in: store)` inside `buildSchedule` | `scheduleItemForTonightsWorkoutIsMaskedWhenRoutineIsPrivate` | traced | Builder A | T1 T2 T4 |
| PT7 | `ScheduleItem` for a task, `AppModel.swift:558` | Raw `task.title`; a task is stored as "Private task" only when the engine wall rewrote it (medicine reminder), so a task typed through another path with a rent amount stays raw | "Private task" | `ObjectPrivacy.label(of:in:classes:)` then fall back to the title | `scheduleItemForTaskWithMoneyTitleReadsPrivateTask` | inferred | Builder A | T3 (rent-shaped task) |
| PT8 | `RoutineEntity` built from a stored routine, `TesseraIntents/Entities.swift:84` | Raw: `title: routine.title`; the entity's `DisplayRepresentation` (:66) prints it in Shortcuts and Siri pickers | "Private workout" | `ObjectPrivacy.routineTitle` (needs `@MainActor`, already inside `MainActor.run`) | `routineEntityTitleIsMaskedForPrivateRoutine` | traced | Core | T1 T2 T4 |
| PT9 | `RoutineQuery.entities(matching:)`, `Entities.swift:91` | Filters on the raw `$0.title`, so typing the medicine word finds the routine and proves it exists | Match on the shown (masked) title only | filter over masked entities | `routineQueryDoesNotMatchPrivateRoutineByRawTitle` | traced | Core | T8 T1 |
| PT10 | `RoutineQuery.suggestedEntities`, `Entities.swift:102` | Raw titles of every routine (spotlight-widgets-privacy P3: the App Shortcut lists them in Spotlight) | "Private workout" per private routine | same as PT8 | `suggestedRoutineEntitiesAreMasked` | traced | Core | T1 T2 T4 |
| PT11 | `RoutineEntity.init`, `Entities.swift:69-71` | Stores whatever title it is handed | The one chokepoint: mask here so PT8, PT10 and PT12 cannot regress | `ObjectPrivacy.routineTitle` at the call sites; init stays dumb | `routineEntityNeverHoldsRawPrivateTitle` | inferred | Core | T1 T7 |
| PT12 | `StartWorkoutIntent` dialog, `TesseraIntents/Intents.swift:108` | Raw: "\(routine.title) started. N exercises." spoken by Siri | "Private workout started. N exercises." | `routine.title` already masked by PT8, or `routineTitle` here | `startWorkoutIntentDialogMasksPrivateRoutineTitle` | traced | Core | T1 T2 T4 |
| PT13 | `NowPage` Resume key label, `Features/Home/NowPage.swift:52` | Raw: `session.workout.title` | "Resume Private workout" | `session.shownTitle` (`WorkoutSession.swift:30`) | `nowResumeKeyUsesShownTitleForPrivateRoutine` | traced | Builder A | T1 T2 |
| PT14 | `NowPage` Resume accessibility label, `NowPage.swift:54` | Raw (VoiceOver reads it) | "Resume Private workout" | `session.shownTitle` | `nowResumeAccessibilityLabelMasksPrivateRoutine` | traced | Builder A | T1 T2 |
| PT15 | `NowPage` Resume for a ledger process, `NowPage.swift:60` and :62 | Raw: `fact.title` from `HomeFact` (a workout fact is built from `summary.title`, `HomeLines.swift:505`) | "Resume Private workout" | mask where the fact is built (PT36) so :60, :62 and the Home line follow | `nowLedgerResumeKeyMasksPrivateWorkoutFact` | traced | Builder A | T1 T2 |
| PT16 | `NowPage` anyway key, `NowPage.swift:74-76` | Raw: `next.title` from `ScheduleItem` (label and "Starts ... anyway" hint) | "Start Private workout" | follows PT6 | `nowStartAnywayKeyFollowsMaskedScheduleItem` | inferred | Builder A | T1 |
| PT17 | `NowPage` start-a-routine key label, `NowPage.swift:299` | Raw: `routine.title` | "Start Private workout" | `ObjectPrivacy.routineTitle(routine.title, in: model.store)` | `nowStartRoutineKeyMasksPrivateRoutineTitle` | traced | Builder A | T1 T2 T4 |
| PT18 | `NowPage` start-a-routine accessibility label, `NowPage.swift:300` | Raw | "Start Private workout" | same | `nowStartRoutineAccessibilityLabelMasksPrivateRoutine` | traced | Builder A | T1 T2 |
| PT19 | `CaptureParts` return-to-workout label, `Features/Command/CaptureParts.swift:158` | Raw: "\(session.workout.title) is running. Return to workout" | "Private workout is running. Return to workout" | `session.shownTitle` | `captureReturnLabelMasksPrivateRoutine` | traced | Builder A | T1 T2 |
| PT20 | `CaptureParts` exercise not in workout, `CaptureParts.swift:229` | Raw: "<exercise> isn't in \(workout.title)." (spoken and receipt-logged) | "<exercise> isn't in Private workout." | `ObjectPrivacy.routineTitle(workout.title, in: store)` | `captureNotInWorkoutLineMasksPrivateRoutine` | traced | Builder A | T1 T2 |
| PT21 | `BottomChrome` back-to key, `Features/Command/BottomChrome.swift:298` | Raw: "Back to \(session.workout.title)" | "Back to Private workout" | `session.shownTitle` | `bottomChromeBackToKeyMasksPrivateRoutine` | traced | Builder A | T1 T2 |
| PT22 | `BottomChrome` start key, `BottomChrome.swift:304` | Raw: "Start \(workout.title)" | "Start Private workout" | `ObjectPrivacy.routineTitle` | `bottomChromeStartKeyMasksPrivateRoutine` | traced | Builder A | T1 T2 T4 |
| PT23 | `ReviewView` workouts section, `Features/Review/ReviewView.swift:200` | Raw: `ReviewLine(title: workout.title, ...)` | "Private workout" | `routineTitle` where `ReviewWeek.compute` builds `workouts` (:49) | `reviewWorkoutLineMasksPrivateRoutineTitle` | traced | Builder B | T1 T2 T4 |
| PT24 | `ObjectPage` hero for a workout or routine object, `Features/Objects/ObjectPage.swift:260` | Raw: `privateLabel ?? object.title`; `ObjectPrivacy.label` returns nil for a workout, so no label | Hero "Private workout" (class line built from the label, no properties) | extend `ObjectPrivacy.label(of:...)` with a workout branch that calls the routine rule | `objectPrivacyLabelCoversWorkoutWithPrivateTitle` | traced | Core | T1 T2 T4 |
| PT25 | `ObjectPage` "Used in" row, `ObjectPage.swift:155` | Raw: `ObjectRow(title: item.workout.title, ...)`; hint "Opens <title>" | "Private workout"; hint "Opens Private workout" | `routineTitle` | `exerciseUsedInRowMasksPrivateRoutineTitle` | traced | Builder B | T1 T2 |
| PT26 | `ObjectPage` "Used in" grouping key, `ObjectPage.swift:189` | Raw key `session.workout.title`; two different private routines stay separate rows (fine), but a masked label as key would merge them | Group by workout id or raw key, show masked | keep the raw key for grouping, mask only what is drawn (note: grouping by the masked label would merge two private routines, wrong) | `exerciseUsedInGroupsPrivateRoutinesSeparatelyButShowsLabel` | traced | Builder B | T1, two private routines |
| PT27 | `RoutinesPage` moved receipt and undo, `Features/Plans/RoutinesPage.swift:217` and :218 | Raw: "\(routine.title) moved." and take-back | "Private workout moved." | `routineTitle` | `routinesMovedReceiptMasksPrivateRoutine` | traced | Builder B | T1 T2 |
| PT28 | `RoutinesPage` drop receipt, `RoutinesPage.swift:239` | Raw `routine.title` into `Receipt.dropped` and `backOnPlan` | "Private workout" | `routineTitle` | `routinesDropReceiptMasksPrivateRoutine` | traced | Builder B | T1 T2 |
| PT29 | `RoutinesPage` routine row, `RoutinesPage.swift:287` | Raw `Text(routine.title)` | "Private workout" | `routineTitle` | `routinesRowMasksPrivateRoutineTitle` | traced | Builder B | T1 T2 T4 T5 |
| PT30 | `RoutinesPage` row hint, `RoutinesPage.swift:336` | Raw: "Opens \(routine.title)" | "Opens Private workout" | `routineTitle` | `routinesRowHintMasksPrivateRoutine` | traced | Builder B | T1 T2 |
| PT31 | `RoutinesPage` "Name it" field, `RoutinesPage.swift:103` | Raw, by design: the live typing field | Stays raw while typing; once saved, every other row masks | none (the one allowed raw site) | `routinesNameFieldIsOnlyRawSiteAndRowMasksAfterSave` | traced | Builder B | T1 T2 |
| PT32 | `RoutineEditor` hero, `Features/Plans/RoutineEditor.swift:121` | Raw `HeroText(text: routine.title)`; the sweep says this needs the rule or an explicit ruling. Per the ruling above: mask (O2 asks where he renames) | "Private workout" | `routineTitle` | `routineEditorHeroMasksPrivateRoutineTitle` | traced | Builder B | T1 T2 T4 |
| PT33 | `RoutineEditor` add-sheet title, `RoutineEditor.swift:139` | Raw: "Add to \(routine.title)" | "Add to Private workout" | `routineTitle` | `routineEditorAddSheetTitleMasksPrivateRoutine` | traced | Builder B | T1 |
| PT34 | `RoutineEditor` say(), `RoutineEditor.swift:188` | Raw `routine.title` into take-back receipts | "Private workout, taken back." | `routineTitle` | `routineEditorReceiptsMaskPrivateRoutine` | traced | Builder B | T1 T2 |
| PT35 | `RoutineEditor` schedule words, `RoutineEditor.swift:492` | Raw: `line(to: routine.title)` and `receipt(routine.title, next)` | "Private workout on Mondays and Thursdays." | `routineTitle` | `routineEditorScheduleReceiptMasksPrivateRoutine` | traced | Builder B | T1 T2 |
| PT36 | `PlanData.routine(of:store:)`, `Features/Plans/PlanData.swift:102` | Raw: linked routine's title, else the workout's | "Private workout" | `ObjectPrivacy.routineTitle` inside this one helper | `planDataRoutineOfWorkoutMasksPrivateTitle` | traced | Builder B | T1 T2 |
| PT37 | `HomePlan` hero, `Features/Home/HomePlan.swift:223` | Raw: "N tasks, \(workout.title), 6 pm" (source is `DayPlan.Block`, PT1) | "N tasks, Private workout, 6 pm" | follows PT1; also mask here until PT1 lands | `homePlanHeroFormsMaskPrivateWorkoutBlock` | traced | Builder A | T1 T2 |
| PT38 | `ReviewWeek` day log fallback line, `Features/Home/ReviewWeek.swift:114` | Raw: "\(workout.title) done, <best> best." | "Private workout done, ..." | `routineTitle` | `reviewWeekDayLogLineMasksPrivateWorkoutTitle` | traced | Builder A | T1 T2 |
| PT39 | `ReviewWeek` day heading forms, `ReviewWeek.swift:173` and :174 | Raw `workout.title` twice | "Private workout" | `routineTitle` | `reviewWeekHeadingFormsMaskPrivateWorkoutTitle` | traced | Builder A | T1 T2 |
| PT40 | `TrainingPage` hero title and route, `Features/Home/TrainingPage.swift:194-197` | Raw in all four cases; the done case reads "\(summary.title) done" although `WorkoutSummary.doneLine(in:)` exists | "Private workout"; "Private workout done" | `routineTitle`; reuse `doneLine(in:)` | `trainingHeroTitleMasksPrivateRoutineInAllFourStates` | traced | Builder B | T1 T2 T4 |
| PT41 | `TrainingPage` key labels, `TrainingPage.swift:235`, :237, :241 | Raw: "Start \(routine.title)", "Start \(workout.title)", "Resume \(session.workout.title)" | "Start Private workout", "Resume Private workout" | `routineTitle` / `session.shownTitle` | `trainingKeyLabelsMaskPrivateRoutine` | traced | Builder B | T1 T2 |
| PT42 | `TrainingPage` hero hint (:189) and tess line (:328) | Hint "Opens \(title)" and "\(titleAndRoute.0) running. ..." both come from the raw hero title | "Opens Private workout"; "Private workout running. ..." | follows PT40 | `trainingHeroHintAndTessLineMaskPrivateRoutine` | traced | Builder B | T1 T2 |
| PT43 | Live Activity, `Features/Workout/LiveActivity/RestActivityController.swift:75` and `Widgets/RestLiveActivity.swift:42` | **Masked**: attributes take `session.shownTitle`. Not on the sweep's leak list; the fixture pins it | "Private workout" on the Lock Screen and Island | `session.shownTitle` (already) | `restActivityAttributesCarryMaskedTitle` (exists in `TesseraTests/WorkoutSessionTests.swift:30`; add the T4 case) | traced | Builder B | T1 T2 T4 |
| PT44 | Home and Lock Screen widgets | None exist: `Widgets/TesseraWidgetsBundle.swift` holds only the Live Activity (also `spotlight-widgets-privacy.md` P5). The sweep lists no widget | n/a; if one is added, it reads a masked source | `routineTitle` | `widgetBundleHoldsOnlyTheLiveActivity` (a guard so a new widget forces this row) | traced | Builder B | none |

## 4. Sites not in the sweep that I found

1. **`ObjectPage.swift:260`, the generic page hero for a workout or routine** (PT24). `ObjectPrivacy.label(of:...)` only has note, memory, task and recipe branches, so a workout or routine object opened from any route prints its raw title as the hero and in the class line (:262). This is the same bug as the Used-in row, one level up.
2. **`HomeLines.swift:505`, `HomeLines.fact(done:)`** copies `summary.title` (raw) into `HomeFact.title`; `HomeLines.line(for:)` then prints it in about 15 lines (:230-281, e.g. "\(fact.title) done."). Masking once at :505 masks Home, Now (PT15) and the ledger resume key. The sweep names only the `NowPage` end of this.
3. **`WeekFacts.swift:96`**, `routinesDone.append(summary.title)`: the week story's routine list takes the raw summary title. Inferred (I did not trace where `routinesDone` is printed).
4. **`WorkoutSummary.title`** (`Training/WorkoutSummary.swift:12`) is a raw public property, and only `doneLine(in:)` masks it. Every raw read of `summary.title` is a leak risk; a `shownTitle(in:)` beside `doneLine(in:)` would give callers one call. Core's decision.
5. **`AppModel.title(of:)`, `App/AppModel.swift:498-503`**, returns `object(id)?.title` for a route; it feeds back-button labels ("Back to <title>", `RoutineEditor.swift:102`) and the breadcrumb. A private routine's title shows there on the next screen.
6. **`Features/Exercise/ExercisePage.swift:223`**, `Button(routine.title)` in the "add to routine" menu: raw routine titles in a menu.
7. **`TesseraCore/.../Actions/PlanActions.swift:124`** creates the workout with `title: routine.title`, so a private routine's title is copied into every workout and into the op log. A mask at read time covers display; the log copy stays raw. Ruled (Product, 4:20 PM, O3): the op log KEEPS the raw title, because masking it would break undo and restore; anything the log shows him (summary, receipt, Day log) masks.
8. **`RoutinesPage.swift:47`, :187, :190 and `TrainingPage.swift:207`** print `plan.title` (a plan, not a routine). A plan titled with a body weight is the same trap. Not covered by `routineTitle`; no plan-title mask exists. Inferred.
9. **`ReviewView.swift:74, :132, :187`** print put-away item titles (tasks). A task is masked only if the engine wall rewrote it; a money-shaped task title from another path is raw. Same gap as PT7.
10. **`NowPage.swift:197` and :232** ("Start with \(first.title)", "Finish \(task.title)") print task titles raw; same task gap.
11. **Spotlight and App Shortcuts**: the parameterized shortcut lists routine titles (spotlight-widgets-privacy P3). That is PT10 viewed from the system side; the test there must run through the entity, not the screen.

## 5. Open questions

- **O1 (ruled).** One label, "Private workout", for routines and workouts. No "Private routine".
- **O2.** The sweep says the routine's own pages need the rule or an explicit ruling. This doc rules mask (PT29 to PT35). If Product wants the editor hero raw because he is renaming there, PT32 changes to "raw only while the title field is focused".
- **O3 (ruled).** The op log keeps the raw title; anything it shows him masks.

## 6. What I could not trace

- Where `ReviewWeek.compute` (`ReviewView.swift:49`) and the Review "Workouts" section get `workout.title` beyond :200, so PT23's best mask point is a guess.
- Whether `PlanInput.Workout` is built in the app or in Core, so PT1's mask point (build the input, or add a shown-title field) is unconfirmed.
- Where `WeekFacts.routinesDone` (item 3 above) and `HomeFact.title` for non-workout kinds are printed.
- The `TrainingPage` states at :259 ("\(next.title) tomorrow") and the `HomeSpatialView` use of schedule items (`HomeSpatialView.swift:614`); both read masked sources only if PT6 lands, not verified.
- Whether `ReviewWeek.swift` counts as one file with `ReviewView.swift`'s `ReviewWeek` struct: the sweep's `ReviewWeek.swift:114,173,174` is in `Features/Home/`, and the struct at `Features/Review/ReviewView.swift:29` is a different type with the same name. I treated them as two sites (PT23 and PT38/39).
- No test was run, so no test name above is confirmed to compile; only PT43's existing test is real.
