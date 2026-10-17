# D1 + D2 spec: HouseRulesTests lint and perform fault-injection plan

Drafted by QA, static (no Swift toolchain). Core lands and runs it (core.md D5); nothing merges without test.sh on a Mac. Counts below are from origin/master ab7d3bf, so Core can calibrate the first run.

## D1. HouseRulesTests (static lint over Features/**/*.swift)

Test target: TesseraTests (app), reads source files through `#filePath`, walks up to the repo root, enumerates `Features/`. Skip lines starting with `///` or `//`, and string-free comment text, so only code and string literals are checked. Each rule fails with file:line and the rule name. Exceptions live in one `allowed` table (file, line text contains, reason), so a new exception is a visible diff.

| # | Rule | Fails on | Master today | Calibration |
|---|---|---|---|---|
| H1 | One haptic vocabulary | raw `.sensoryFeedback(` | 21 hits (BackupView:103, BottomChrome:130-132, CaptureParts:141, CarriageRail:47, ExercisePage:210, GroceriesView:190, ...) | `Haptic` and `.tesseraFeedback` exist (DesignSystem/Haptics.swift). Master would fail until each is migrated. Land the lint with a baseline list of today's 21 files-and-lines and shrink it, or fail only on NEW hits. Recommend baseline plus a "baseline may only shrink" assertion. |
| H2 | No PaintDab beside a Text | a `PaintDab(` within 3 lines of a `Text(` in the same view body | 13 PaintDab uses (ReviewPage:294/401/420/422, GroceriesView:173/436, ExerciseViews:245, CaptureParts:51, ...) | Needs a human read of what the rule means (paint as the label's marker vs a dab beside a word). Ask Design for the exact statement before coding; start as a report-only test that prints hits. |
| H3 | No SF Symbols in Features | `Image(systemName:` and `systemImage:` | 2 hits, the two boarded exceptions: ObjectPage.swift:444 (arrow.right) and WorkoutParts.swift:57 (Swap within the movement) | Put exactly these two in `allowed` with reason "boarded". Line numbers drift, so match on file plus the symbol name ("arrow.right", "arrow.left.arrow.right"). |
| H4 | Type floor 16 | `.font(.system(size: N` with N < 16 | 0 under 16 (TrainingPage:600 is 16, ObjectPage:444 is 17) | Also cover `Font.system(size:` and `.custom(_, size:` with N < 16; fixed sizes only, not Theme tokens. |
| H5 | No em dash in a string | U+2014 inside a string literal | about 11 hits, all but a few are the lone placeholder "—" (ExercisePage:144/146, ExerciseViews:188, ObjectPage:172/174/410) plus comments (ignored) | The lone "—" is a deliberate empty-value placeholder, so either allow the exact literal `"—"` or board a swap to "none". Ask Product (copy rule in product-decisions-ux.md) which. Any other em dash in a string fails. |

Also worth adding in the same file (cheap, from house rules): H6 a literal "…" in a user-facing string (RecipeLinkReader.swift:22 today, in TesseraCore/Sources/TesseraTess, so scan that folder as well); H7 the word "record" in a string next to a personal best; H8 `ProcessInfo` / `CommandLine` outside LaunchFlags.swift, AppClock.swift:18, DemoData.swift:14 (Theme.swift:282 today is a hit).

Self-test: include one `@Test` that feeds each rule a tiny bad snippet and a good snippet, so the lint itself cannot silently match nothing (a lint that finds zero files must fail).

## D2. Fault-injection tests for the perform helper

Subject: `ActionEngine.perform` (TesseraCore/Sources/TesseraCore/Actions/ActionEngine.swift:44, :78, `performErased` :85), called about 64 times from Features with `try?` (CaptureParts:194, ExercisePage:241, GroceriesView:203/233/247/256/268/270, BackupKeeper:123, ...). The risk is a failed write that the UI treats as done (haptic, receipt or UNDO shows, nothing saved).

Plan, one test per call-site family (family = the helper a screen calls, not each line):
1. Seam: a test engine whose store throws on the Nth write (inject at ObjectStore or the op-log write; Core picks the seam). Assert after a throw: the in-memory graph equals the pre-call graph (no half write), no OpRecord receipt, no UNDO slot taken.
2. Families: capture (note/task create, CaptureParts:194 and its "Couldn't save that." branches :195/:202), groceries (AddGroceries, CheckListItem, ClearDoneItems, StartShop/SuspendProcess), exercise/routine (AddSlot, CreateRoutine), backup (BackupKeeper.pick), settings writes, Tess actions through `perform(named:arguments:by:)` (bad JSON, unknown name).
3. Per family assert the three outcomes: (a) throws once, view state shows the failure line and not the success line; (b) no haptic cue played (HapticCue record, DesignSystem/Haptics.swift:69); (c) retry after the fault clears succeeds and writes exactly one op.
4. Atomicity case: an action that writes two objects, fault on the second write, expect none persisted.
5. Run under `scripts/test.sh --package-only` for the engine half; the view half (a, b) needs the app target.

## D3 (device check, Mac session)
One haptic per finish: finish a workout, a task, a shop and Shutdown on the phone with the haptic log on; expect exactly one cue each (`Haptic.done`). Needs Builder B's change landed first.

## Open questions for Product/Design
H2's exact meaning; H5's treatment of the lone "—" placeholder; whether H1 uses a baseline list or migrates the 21 hits first.

## Rulings folded in (Product decisions 5:57 PM PT Oct 16)
- H1: shrink-only baseline of today's 21 hits; the migration to `.tesseraFeedback` lowers it to zero, and the test asserts the baseline never grows.
- H2: report-only first. Wording from no-dots.md Tokens: no PaintDab before or after text; data marks only.
- H5: the lone "\u2014" placeholder IS an em dash and goes (an empty value drops out, or reads "none" where a cell must show something). The lint allows no em dash in any string, no exceptions table. Builder work: ExercisePage:144/146, ExerciseViews:188, ObjectPage:172/174/410 must change before H5 can be strict (or sit in a shrink-only baseline like H1).
- H6 (ellipsis): Design's call; keep as report-only until ruled.
- H7 ("record" for a best) and H8 (ProcessInfo/CommandLine outside LaunchFlags, AppClock:18, DemoData:14): approved, strict from day one (Theme.swift:282 must be fixed or baselined first).
