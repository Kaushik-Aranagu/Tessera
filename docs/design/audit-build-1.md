# Design audit, build 1 (master 012c53a)

Tonight's build checked against the baseline Kaushik set at 19:37: ink actions (`no-buttons.md`), Tess in her corner, no button shapes, type from `docs/design/type-and-motion.md`, and motion only through `MotionPolicy`.

**Sources.** A code sweep of `App/` and `Features/` on master 012c53a (shapes, stock controls, modals, raw animation, type sizes), plus these recordings: `today-queue-swipes`, `tess-soul-write`, `20-backups-back-word`, `21-backups-swipe-k1` and `22-groceries-followup-60fps`. Workout, Exercise, Plans, Notes, Recipes and the object pages have no recording since the cut, so their rows come from code. A tour recording has been asked for (`23-audit-tour.mp4`), and those rows will be checked against it.

**What already holds.**
- The sweep found no type under 16pt, no italics, no stock `List`, `Form`, `Toggle` or `Picker`, and no system colours.
- Home Now and Today read as the baseline: the hero task, "Finish" as a held stroke word, and Tess's line with a vermilion UNDO.
- The Review hero sentence and its day dabs hold, and misses show as rings, never red.
- Backups has the first real back word ("‹ REVIEW").
- Groceries' aisle fold is sequenced.

## Ranked polish list
Ranked by how much each row breaks the baseline on a screen he uses daily. Rows 1, 3, 4 and 11 are call sites `no-buttons.md` already lists that haven't landed yet.

| # | Screen | What's wrong | Change | File | Owner |
|---|---|---|---|---|---|
| 1 | Workout, typing a weight | A system alert box ("Weight", a text field, Set and Cancel) | Edit in place. The 80 Light numeral becomes the field with the decimal pad, and a cobalt writing line draws under it. "Goes to the nearest weight the gym can load." is the context line. Return commits, and the numeral rolls to the loaded weight | `Workout/Instruments/WeightDial.swift:133` | Builder A |
| 2 | Workout, typed ask | A stock sheet (84pt detent) holding an outlined rounded field and a "Close" word | Use Tess's Write layer from #107 on the dark ground: a writing line and caret over a veil, with no sheet and no outline. Swipe down or tap the soul to close | `Workout/WorkoutModeView.swift:122`, `Workout/WorkoutParts.swift:380-399` | Builder A |
| 3 | Workout, Tess | A dark glass rounded bar holds the soul and her line | Put the soul in its corner with her line right-aligned beside it, as on Home, and drop the bar. Already queued as the soul swap | `Workout/WorkoutParts.swift:252` | Builder A |
| 4 | Workout, swap | A glass card, and a picked option fills a cobalt rounded rect | As `no-buttons.md` already specifies: the panel becomes `.veil(edge: .bottom)`, and the picked name goes to full cream as a 3pt cobalt seam paints in at its left edge. No fill | `Workout/SwapPanel.swift:51, 89` | Builder A |
| 5 | Exercise page | "Add to routine" opens a system menu | Make it a label word. Tapping lifts one line of routine names above it, like People's @ pick line, ending in "new routine" in cobalt | `Exercise/ExercisePage.swift:221` | Builder A |
| 6 | Home, Training page | The "Start workout" stroke word's label carries `.textRole(.bodyStrong)` | Remove it; the stroke word sets its own type (the #108 rule) | `Home/TrainingPage.swift:186` | Builder B |
| 7 | Home, Now | The amber time-left stroke runs over a full-width 2pt ink track, so it reads as a progress bar | Drop the track and let the stroke dry from full to nothing on its own | `Home/NowPage.swift:183-185` | Builder B |
| 8 | Home and Review | Every `PaintDab` comes out the same rounded blob, so the Today rows and the week read as pills (today-queue-swipes at 0.5s, 21-backups at 0.5s) | Give `PaintDab` more seeded wobble per instance and a soft multiply edge, so no two dabs match | `PaintDab` (Home queue rows, `ReviewView.swift:248`, `ReviewPage.swift:166`) | Builder B |
| 9 | Motion | `withAnimation` and `.animation` outside `MotionPolicy`, so Reduce Motion isn't one switch | Route them through `withTesseraAnimation` / `.tesseraAnimation` | `Command/BottomChrome.swift:52, 63, 171, 176, 365, 366, 388`, `Tess/PaintFlood.swift:26-27` (Builder B); `Groceries/GroceriesView.swift:207-225` (Core) | Builder B, Core |
| 10 | Undo across screens | Plain-text Undo buttons, each styled differently. The paste screen's is cobalt, but UNDO is vermilion only | Use the vermilion UNDO label word everywhere (`InkLabelWordStyle(color: live)`), as BottomChrome does | `Recipes/RecipePage.swift:212`, `Recipes/PasteRecipe.swift:227` (Core); `Plans/RoutineEditor.swift:124` (Builder A) | Core, Builder A |
| 11 | Workout, running-order strip | Glass with 34pt bottom corners | `.veil(edge: .top)`, as `no-buttons.md` specifies. The lifted row while dragging stays | `Workout/ExerciseStrip.swift:123` | Builder A |
| 12 | Every stacked page | System back buttons on the root stack and on the Review, Notes, Groceries and Recipes stacks | The back word pattern, generalised from Backups' "‹ REVIEW". Design is writing this sheet next (board Next 2) | `App/RootView.swift:17`, each feature's `NavigationStack` | Builder B, then all |
| 13 | Tess capture | The #107 follow-ups are still open: tap latency from the double tap, the "Double tap twice" a11y hint, no feedback from Speak and Show, and her line not capped at 270 | As sent with the #107 review | `Command/BottomChrome.swift` | Builder B |
| 14 | Groceries | The #131 notes: the veil shows Dairy through Tess's line, the hold fill snaps back to ink before the fold, and the peek line overlaps itself as it changes | As sent with the #131 review | `Groceries/GroceriesView.swift` | Core |
| 15 | Backups | "a folder you choose" breaks across two lines | Join it with non-breaking spaces so the phrase drops whole to line two | `Backup/BackupView.swift` | Core |
| 16 | Review | A hairline rule above BACKUPS | Remove it and leave 40pt of space | `Review/ReviewView.swift` | Core |

## Kept on purpose
- **Rest's "Skip rest" with +15 and SKIP under it** (`WorkoutModeView.swift:568-581`): this is as `no-buttons.md` drew it, matching the Live Activity.
- **The context menu "Swap within the movement"** on the exercise name: it's a hidden twin of the visible path, and fine as it is.
- **Week page muscle ranges** (`WeekPage.swift:195`): still owed from `no-buttons.md` (a 14pt brushstroke band with rough ends, not a rect), but it's a data mark, so it ranks below everything above.

## Waiting on the tour recording
Check these against `23-audit-tour.mp4`, then add rows:
- Workout: log a set, rest, and editing a set.
- Plans: week, month and the routine editor.
- Notes.
- The recipe shelf.
- Object pages and the class inspector.
- One widget.
