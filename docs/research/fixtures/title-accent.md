# Title accent: the progress table (Design 72, Round 2)

> **Checked against (Research BJ, Fri Oct 16, 2026, about 3:05 pm PT):** Design branch
> `origin/claude/project-thread-b3tu3f` at `1cab06a`. Sheet 72 `docs/design/title-accent.md` is last touched at
> `29a6093` (rulings, 2:30 pm), round 2 and `studies/title-progress.html` at `daefd76`, round 1 at `02654da`. Nothing
> on that branch after `29a6093` touches 72. The copies in `/mnt/project-files/tessera/design/` are identical to
> `29a6093`. Product: decisions.md 2:28 pm, 2:12 pm and the daily pins entry (Builder A 0p rides the first daily pin
> it is ready for). Design's 2:31 pm strike ruling is folded in (open question 7). Code refs re-pinned to
> origin/master `56dd028` where they moved.
>
> **Rows changed in this pass, and why:**
> - **Strike** (values table): now says the strike draws in the title's own `foregroundStyle` (Design 2:31 pm), sits
>   58% down the line box (the study's x-height), and dries with the title to 50% ink.
> - **Lean** (values table): the mix is in OKLab, as the study draws it (`color-mix(in oklab, ...)`).
> - **Done sequence** (values table, new row): the study's order at done: `p` to 1 over 300 ms, then the strike over
>   420 ms, then the 250 ms lift.
> - **Dry** (values table): the weight and the word dry too: `p` runs back to 0 over the same 2 s, so the dried title
>   is rest weight in 50% ink with the strike kept. It starts 900 ms after the lift.
> - **The word that matters** (rule above the main table, and the last column of T1, T2, T4, T6, T7, T9): sheet 72
>   colors the moment word after the comma ("bench set 1", "step 4"), not the thing's name. That contradicts the
>   table Product accepted at 2:28 pm, so both are shown and it is open question 10.
> - **0% column** (T1, T2, T4, T6, T7, T9): the word wears its color from the moment the thing starts (the study's
>   STARTED stage at 0 of 20 sets), not from the first logged set.
> - **Done word** (T1, T6, T7): the study's done hero reads "Push Day A, done" and "Paprika chicken, cooked"; the code
>   reads "Push A done" and "Paprika chicken done". Open question 11.
> - **T10** (Groceries hold): Design's ruling 2 says the strike draws at done; the old row had no strike. Open
>   question 12 for when "done" is.
> - **T1, open question 9, last test name:** the `"targetSets"` bug is fixed on master (#546, merge `8ccb150`;
>   NowPage.swift:214-218).
> - **Line refs:** NowPage.swift moved by up to 4 lines after #546 (T1, T5, T11, T13, plain rows).
> - **Copy:** US spelling ("color") throughout. Token names are unchanged.

Research BB for Product's board, Oct 16. Source sheet: Design 72 `title-accent.md`, Round 2 ("the whole title moves", his pick at 1:50 pm). Kaushik's rule (Oct 16, 1:32 pm): large-type titles get a subtle color or accent that can carry meaning; never a brush or underline behind the text, never over the top; heroes and Title 44 only.

**Rulings folded in:** Design 2:30 pm (sheet 72 at 29a6093, "Rulings on Research's fixture"): 1 no cobalt on tasks, 2 Groceries hold title goes Round 2 in green, 3 one 3 pt strike, 4 recipe title is Title 44 and Builder B's. Product 2:28 pm: the `"sets"`/`"targetSets"` bug is rider 0r for Builder A (now merged, #546). Design 2:31 pm: the strike takes the title's own `foregroundStyle` (open question 7).

Everything below was first read on origin/master at `73fa1a2` (merge of #541) and re-pinned to `56dd028` where 0p reads it. Paths are repo-relative; line numbers are origin/master's.

## The Round 2 values, as tokens

Round 2 has no tokens on master yet. The rows below name the tokens Builder A should add to `DesignSystem/Theme.swift` (proposed names, marked NEW) beside the existing ones, so no table row carries a literal.

| What | Token | Sheet value |
|---|---|---|
| Rest weight | NEW `Theme.TitleAccent.restWeight` | 500 (the live looks' Hero and Title weight, `.medium`, Theme.swift:226-228) |
| Done weight | NEW `Theme.TitleAccent.doneWeight` | 640 |
| Tracking at done | NEW `Theme.TitleAccent.tighten` | minus 0.012 em, so the width holds |
| Lean at done | NEW `Theme.TitleAccent.maxLean` | the title's ink leans 60% of the way to the area color, mixed in OKLab (the study's `color-mix(in oklab, ...)`), lean = 60% times `p` |
| The word's mix | NEW `Theme.TitleAccent.wordMix` | 72% area color, 28% ink, from the first step |
| The word for tasks | NEW `Theme.TitleAccent.inkWordWeight` | ink at 700 (tasks have no color, Design ruling 1) |
| Cap before done | NEW `Theme.TitleAccent.progressCap` | 0.85 |
| Strike | NEW `Theme.TitleAccent.strikeWidth` | 3 pt through the x-height (58% down the line box in the study), drawn left to right over 420 ms ease-out, wraps with the lines. Color: the title's own `foregroundStyle` at each moment, never its own color or alpha (Design 2:31 pm), so it is the full lean at done and 50% ink once dried |
| Done sequence | NEW `Theme.TitleAccent` timings | `p` from the cap to 1 over 300 ms, then the strike over 420 ms, then the lift (study `title-progress.html`, play mode) |
| Lift | NEW `Theme.TitleAccent.lift` | one 250 ms lift at done |
| Dry | `Theme.Motion.dry(reduceMotion:)` (Theme.swift:572) stretched by a NEW `Theme.TitleAccent.dry` | 900 ms after the lift, over 2 s: the color goes to quiet ink at 50% (`Theme.TitleAccent.driedInk`, NEW), the word goes to the same 50% ink, and `p` runs back to 0 so the weight returns to `restWeight`. The strike stays |
| Each step | `Theme.Motion.house` (Theme.swift:567) via `.tesseraAnimation` | 600 ms tween per step |

Area colors (sheet: no new colors, each look's light partner in Obsidian):

| Area | Token | Note |
|---|---|---|
| Training | `Theme.Colors.liveInk` (Theme.swift:332) | In live workout mode the ground is the workout palette, so the pair is `Theme.Colors.Workout.signal` over `WorkoutPaint.cream` (WorkoutPaint.swift:35) |
| Kitchen (cook, shop) | `Theme.Colors.health` (Theme.swift:420) | The recipe clock's lit step uses `now`, not health; see open question 4 |
| Today's tasks (task run, Plan my day) | `Theme.Colors.ink` only, no area color | Design ruling 1 (2:30 pm): Tess's cobalt comes off tasks and no new tasks ink. Tasks get weight, the strike, and the thing's word in ink at NEW `Theme.TitleAccent.inkWordWeight` (700) |
| Review | `Theme.Colors.context` (Theme.swift:412) | No progress title in Review today |

Read "0%", "50%" and "done" below as the title's `p` after the 0.85 cap: at 50% of the steps, `p` is 0.425, so the weight sits near 560 and the lean near 25%.

## Titles with progress

**The word that matters (open question 10).** Sheet 72 colors the moment word after the comma: the study wraps it as `<name>, <w>word</w>` ("bench set 1", "step 4", then "done" or "cooked"), and round 1's option 2 named "set 2" and "7 pm". The table Product accepted at 2:28 pm colored the thing's name instead. Ruled by Product 3:05 pm: the sheet's moment word gets the color, and 0p reads the same `plannedSets` as 0r. The last column keeps the 2:28 word after it for reference only. Either way the word wears its color from the moment the thing starts (`p` = 0 while running), not from the first logged step.

| # | Title (file:line) | Type | What counts as progress (source) | Exists today? | 0% | 50% | Done | The word that matters: sheet 72 (pick) / as accepted 2:28 pm |
|---|---|---|---|---|---|---|---|---|
| T1 | Home, running workout hero: "Push A, bench set 2" via `LineHero` and `HomeHeroText` (NowPage.swift:48, HomeLineHero.swift:72-76) | Hero 56, steps to Title 44 | Sets logged over planned sets: `progress(of:)` NowPage.swift:205-212, planned from `plannedSets` :214-218 | Yes. The `"targetSets"` fix (0r) is on master (#546, NowPage.swift:217). It counts every logged set, warm-ups included; the sheet says sets, so Research reads that as fine | `restWeight`, `Theme.Colors.ink`; the word at `wordMix` of `liveInk` from the start (the study's STARTED stage, 0 of 20 sets) | about 560, ink leaning about 25% to `liveInk`; the word at `wordMix` | `doneWeight`, `maxLean`, strike, lift, then dry to `driedInk` with the strike kept. The done words: the study reads "Push Day A, done", Home reads "Push A done" (HomeLines.swift:285); open question 11 | "bench set 2" / "Push A" |
| T2 | Training page title for a running workout (TrainingPage.swift:182, `.running` case at :196) | Title 44 | Same as T1 | Same as T1 | as T1 | as T1 | as T1; the `.done` case already reads "Push A done" (:197) | none: the running title is the name alone (`titleAndRoute`, TrainingPage.swift:192-199), so the whole title moves with no colored word / "Push A" |
| T3 | Live workout mode, exercise name (WorkoutParts.swift:36; 34 pt fallbacks at :37-38 are not Title 44) | Title 44 | Working sets of this exercise over its `targetSets`: `WorkoutProgress` (WorkoutProgress.swift:33-50) | Yes (per entry: `entry.orderedChildren` working sets vs `targetSets`) | `restWeight`, `WorkoutPaint.cream` | about 560, cream leaning about 25% to `Theme.Colors.Workout.signal`; name at `wordMix` of signal | `doneWeight`, strike, lift, dry; the lane then pages on, so the done state is seen mostly by swiping back. The 34 pt fallbacks follow the same `p` (Design to confirm, open question 5) | The exercise name, "Bench press" (the whole title is the name, so the word is the title) |
| T4 | Workout object page hero, `RevealingHero(text: title)` (ObjectPage.swift:329) | Hero 56 via `HeroText` | Same as T1 when the object is a running workout | Yes; `RevealingHero` has an unused `completion` strike in `live` at 2.5 pt (TextEffects.swift:98-106, StrikeRenderer :33-60) | as T1 | as T1 | as T1. Design ruling 3: one strike, Round 2's 3 pt replaces RevealingHero's unused 2.5 pt one | none (the object title has no moment word) / "Push A" |
| T5 | Planned workout: Home "Push A at 7 pm" (NowPage.swift:245 and :80, words HomeLines.swift:294-298), Training page `.routine`/`.scheduled` (TrainingPage.swift:194-195) | Hero 56 / Title 44 | None until started | n/a | Plain ink, `restWeight`, no word color (the sheet's "never color on a title with nothing in progress") | n/a | n/a | None until the first set lands; then it is T1 |
| T6 | Cook, recipe page title (RecipePage.swift:57-58). **Owner: Builder B** | Hero on master; becomes Title 44 per sheet 69 (Design ruling 4) | Steps done over steps: the cook process `resumePoint.index` (Cooking.swift:111, :145; RecipePage.swift:374-378 "Step 2 of 4") over `RecipeBook.steps` (RecipePage.swift:44) | Partly. Step index and count exist; the recipe clock (`RecipeClockView`) is not on master, so "done" is `FinishCooking` (Cooking.swift:190) | `restWeight`, ink; the word at `wordMix` of `health` from the start | about 560 leaning about 25% to `health`; the word at `wordMix` of `health` | Fires on hold DONE / `FinishCooking` only, never when the last timer ends | none: the page title is the name alone / "Paprika chicken" |
| T7 | Home, running or paused cook hero "Paprika chicken, step 3" (HomeLines.swift:303, facts :507-513) | Hero / Title 44 | `step` over `steps` on `HomeFact` (HomeLines.swift:24-26, :511) | Yes | as T6 | as T6 | as T6; Home then shows "Paprika chicken done" (HomeLines.swift:302); the study reads "Paprika chicken, cooked" (open question 11) | "step 3" / "Paprika chicken" |
| T8 | Shop, aisle hero while shopping (GroceriesView.swift:483-484, `AtTheShop`) | Hero 56 | Items struck in this aisle over the aisle's items at shop start | No. The aisle list drops struck items (`shoppingOrder`, Shopping.swift:8) and nobody keeps the aisle's starting count | `restWeight`, ink | aisle name leaning to `health` | The aisle folds away when empty (GroceriesView.swift:470), so done is the fold, not a strike. Recommend: no accent on aisles (open question 3) | The aisle name ("Produce") |
| T9 | Home, shop hero "Groceries, 9 left" (HomeLines.swift:304, facts :514-517) | Hero / Title 44 | Basket over basket plus left: `ListContents.done` (GroceriesView.swift:57) and `shoppingOrder().count` (Shopping.swift:14) | Yes (both counts exist; the total at shop start is basket plus left) | as T6 | as T6 | `FinishShop` (Shopping.swift:50), not "all in the basket"; at "all in the basket" `p` stays at the cap until he finishes | "9 left" / "Groceries" |
| T10 | Groceries page hero `ShopTitle` (GroceriesView.swift:309-315) | Hero 56 | The 0.7 s hold that starts the shop (:325) | Yes (the hold's `fill`, :302) | `restWeight`, ink | The whole title leans toward `health` and gains weight together as the hold fills; no split, no vermilion (Design ruling 2) | Hold lands: full weight and full lean in `health`, and the strike draws (Design ruling 2: "the strike draws at done"), then the view folds away as the shop starts. Open question 12 asks whether done is the hold or `FinishShop`. Letting go early drains back to ink, no strike | "Groceries" (the whole title is the name) |
| T11 | Now, a timed task running: `LineHero` with the task's title (NowPage.swift:220-236, hero words HomeLines.swift:300) | Hero / Title 44 | A single task has no count; time is shown by `DrainBar` (NowPage.swift:240) | No count source | Plain, `restWeight` | Plain | Hold Finish: strike, lift, dry. That is the only accent | The task's title, only at done |
| T12 | Task run (several kept tasks in a row) | Hero / Title 44 | Tasks finished over tasks in the run: `DayPlan.runs` (DayPlan.swift:60-77) gives the runs, `HomePlanModel.kept` (HomePlan.swift:23) the kept rows | No. Runs exist only inside the plan offer; there is no run object, no run title and no finished count. Not built | `restWeight`, `Theme.Colors.ink` | Plain ink, about 560; the first task's name in ink at `inkWordWeight` (Design ruling 1) | Last task finished: `doneWeight`, strike, lift, dry; no color at any point | The run's first task name, in ink at 700 (no run name exists; open question 6) |
| T13 | Plan my day hero "3 tasks, Push A at 6 pm" (`PlanHeroText`, NowPage.swift:556-569; words HomePlan.swift:215-222) | Hero 56, steps to Title 44 | Rows answered (kept or skipped) over rows: `kept` and `skipped` (HomePlan.swift:21-23, :146-167) | Yes, in memory only | `restWeight`, ink | Plain ink, about 560; "3 tasks" in ink at `inkWordWeight` (Design ruling 1) | Hold START WITH (`keepPlan`, HomePlan.swift:171) ends the plan hero at once (`state = .kept`), so done is never seen on this title. Recommend: weight only, no strike here; the strike belongs to the run (T12) | "3 tasks" (the plan's own name is its count; the workout clause stays ink) |

### VoiceOver, Reduce Motion, Dynamic Type (all rows)

- **VoiceOver:** color, weight and the strike are never the only cue. The label stays the title as written (`HomeHeroText` already sets `.accessibilityLabel(text)`, HomeLineHero.swift:83; `HeroText` at Editorial.swift:190). Add an `.accessibilityValue` with the count in words: "set 5 of 18", "step 3 of 6", "9 left", "2 of 3 rows". At done the value is "done". No announcement per step (the logged set already speaks); one at done only through the existing done line ("Paprika chicken, cooked.").
- **Reduce Motion:** per the sheet, each step lands without the tween, the strike appears whole, the lift is skipped, and the dry is a 200 ms crossfade. All through `MotionPolicy` (`withTesseraAnimation`, `Theme.Motion.dry(reduceMotion:)` returns nil).
- **Dynamic Type:** weight and lean are size-free. Tracking tightens in em, so it scales. The strike follows `Text.Layout` lines (StrikeRenderer already walks lines, TextEffects.swift:51) so it wraps at accessibility sizes. Hero is capped at xxxLarge (Editorial.swift:40); Title 44 goes to accessibility5. The `HeroText`/`HomeHeroText` fit is measured at 0.56 em per glyph (Editorial.swift:193, HomeLineHero.swift:86); at 640 the face is wider, so the width hold from `tighten` matters: test that a title that fits at 500 never drops to the next form at 640.
- **Contrast:** at `maxLean` and `wordMix` the sheet keeps every mix above 3:1 (large text). Increase Contrast: recommend the lean caps at 30% and the word mix stays.

## Titles that stay plain

No progress, so no color, no weight change, no strike (sheet: "never color on a title with nothing in progress").

| Title | File:line | Why plain |
|---|---|---|
| "Notes" | NotesView.swift:71-72 | A page name |
| "Nothing written yet." | NotesView.swift:236-237 | Empty state |
| Private notes, a note's object page | ObjectPage.swift:329 (non-process objects) | No count; never color private words |
| Review week hero | ReviewPage.swift:367 | A reading, not a process (Review's violet stays off titles until there is a Review count) |
| Review fitting hero | ReviewPage.swift:534-539 | Same |
| Settings, "Receipts" | ClaudeSection.swift:463-464 | A page name |
| Backup "Kept on this iPhone" / "Kept in two places" | BackupView.swift:51-53 | A state, not progress |
| "A restore is waiting" | BackupView.swift:210-211 | A state |
| "Routines" | RoutinesPage.swift:43-44 | Page name |
| Routine editor name | RoutineEditor.swift:122 | Editing, not doing |
| Exercise page name | ExercisePage.swift:102 | A reference page; bests live in rows, not the title |
| "Sets per muscle" | WeekPage.swift:23-24 | A chart heading |
| Plans headline | PlansView.swift:123-124 | A reading |
| Kitchen links "Groceries", "Recipes" | HomeSpatialView.swift:369-370 | Links |
| Groceries list aisle names (not shopping) | GroceriesView.swift:394-395 | Already at 85% ink; no shop running |
| "All in the basket." / "Nothing to get." | GroceriesView.swift:663-664 | Empty state |
| "Nothing else is planned today." | NowPage.swift:261-262 | Empty state |
| "A rest day. It counts too." | TrainingPage.swift:683 | Rest day |
| Recipe history title | RecipePage.swift:322-323 | One tap down, a list of past cooks |
| Paste recipe title line | PasteRecipe.swift:314-315 | Being written |
| Done workout hero "Push A done" (from a later visit) | HomeLines.swift:285 | Shows the dried state only (strike, `driedInk`), no new motion |
| Rest day hero | HomeLines.swift:284 | Nothing in progress |
| Tess's soul gallery | SoulGallery.swift:14, :47 | Debug page; also never in Tess's band |

## Edge cases

| # | Case | Expected |
|---|---|---|
| E1 | Paused workout ("Push A, paused at bench", HomeLines.swift:292) | Holds its `p` and the word color, no motion. The title does not dry while paused: paused is not done. Resume picks up with no replay |
| E2 | Workout with every set in but not finished ("Push A, all sets in", HomeLines.swift:290) | `p` = 0.85 cap. Done fires only on Finish |
| E3 | Extra sets past the plan | `p` stays at the cap; never over 1 |
| E4 | A set deleted or undone (UNDO on a logged set) | `p` steps back with the house tween; weight and lean fall back; no strike |
| E5 | Cook runs over (a timed step's timer ends) | HOLDS per the recipe clock rule (cook-mode-acceptance.md ruling 4; decisions.md 2:00 pm item 3): the title holds its `p`, nothing changes when a timer ends. "5 more minutes" changes nothing on the title |
| E6 | Cook paused | As E1 |
| E7 | Cook DONE then UNDO within 10 s | The strike retracts right to left (Reduce Motion: disappears), the dry is cancelled, the title returns to the cap state of the last step |
| E8 | Task run, a task finished then UNDO | The run's `p` steps back; if the run had struck, the strike retracts as E7 |
| E9 | Plan kept then "take back" (HomePlan.swift:186-194) | The plan hero returns at the lean it had before; no strike was drawn |
| E10 | Nov 1 fall-back (2 am repeats) | Progress is counts, never clock time, so nothing moves. A done title keeps its dried strike until his day ends at 4 am (DayLabel, HomeLineHero.swift:100); 4 am happens once on Nov 1, so the 25-hour day clears once. The recipe clock's bead is time-based but the title reads steps |
| E11 | 0 of 0: empty routine (`canStart` false, NowPage.swift:67), recipe with no steps (`steps` nil, HomeLines.swift:511), shop with an empty list, plan with no rows (`isShowing` false, HomePlan.swift:55) | `p` undefined, the title stays plain. Never divide by zero, never draw a strike for 0 of 0 |
| E12 | Shop finished with items still on the list | Done fires on `FinishShop`; `p` was below the cap; it jumps straight to done (one tween) |
| E13 | Theme switched mid-workout (`-theme`, or the day/night look change) | The mix recomputes from the new look's tokens without restarting the tween |
| E14 | Title steps from Hero 56 to Title 44 while in progress (fit changes on rotation of words, "set 9" to "set 10") | Weight and lean carry over; the strike, if drawn, redraws whole without the 420 ms grow |
| E15 | Two things running (a cook while a workout is paused) | Each title carries its own `p`; Home's hero is whichever is Now (NowPage.swift:45-62) |

## Swift Testing names for Builder A

Pure math in a new `TitleAccent` value type (inputs: done, total, isFinished; output: `p`, weight, lean, word mix, strike), so most tests run in `TesseraTests` without a view.

```swift
@Suite("Title accent (Design 72 R2)") struct TitleAccentTests {
    @Test func zeroOfTotalIsPlainInk()
    @Test func zeroOfZeroIsPlainAndNeverStrikes()
    @Test func theWordWearsItsColorFromTheStart()   // the moment word (Product 3:05 pm)
    @Test func halfwayIsCappedProgressTimesHalf()
    @Test func allStepsInHoldsAtCapUntilFinished()
    @Test func extraSetsNeverPassTheCap()
    @Test func finishedReachesDoneWeightAndFullLean()
    @Test func doneDriesToHalfInkAndKeepsTheStrike()
    @Test func undoAfterDoneRetractsTheStrike()
    @Test func undoneSetStepsProgressBack()
    @Test func pausedHoldsProgressAndDoesNotDry()
    @Test func cookTimerEndingDoesNotChangeTheTitle()
    @Test func cookDoneFiresOnFinishCookingOnly()
    @Test func shopDoneFiresOnFinishShopNotAllInTheBasket()
    @Test func planHeroGainsWeightButNeverStrikes()
    @Test func tasksNeverTakeColorOnlyInkAt700()
    @Test func groceriesHoldLeansWholeTitleToGreenWithNoSplit()
    @Test func oneStrikeOnlyThreePoint()
    @Test func plannedWorkoutStaysPlain()
    @Test func plainTitlesNeverTakeTheAccent()   // parameterized over the plain list
    @Test func reduceMotionStepsWithoutTweenAndDriesByCrossfade()
    @Test func accessibilityValueSaysTheCountInWords()
    @Test func doneWeightKeepsTheHeroFit()        // a title that fits at 500 fits at 640
    @Test func fallBackDayClearsTheStrikeOnceAt4am()
    @Test func workoutProgressReadsTargetSetsNotSlotSets() // 0r, fixed in #546 (NowPage.swift:217); keep as a guard
}
```

## Open questions for Product and Design

1. ~~Today's tasks in cobalt?~~ **Ruled (Design, 2:30 pm, sheet 72 at 29a6093):** cobalt comes off Today's tasks, no new tasks ink. A run stays plain ink: bolder as tasks are done, strike at done, the word that matters in ink at 700. Folded into T12, T13 and the area table.
2. ~~Groceries' vermilion hold-fill~~ **Ruled (Design, 2:30 pm):** the hold title moves to Round 2: the whole title leans to Kitchen's green, no split, no vermilion. Folded into T10.
3. **Aisle heroes while shopping:** no starting count per aisle, and the aisle folds when empty. **Recommend:** no accent on aisles; progress lives on Home's "Groceries, 9 left" (T9).
4. **Cook color:** the recipe clock lights steps in `now` (cadmium); the title would lean to `health`. Two colors on one page. **Recommend:** `health` on the title as the sheet says; the lit step's `now` is a moment and dries, so they rarely meet. Design to confirm on the clock's frame.
5. **Live workout mode:** the exercise name's 34 pt fallbacks (WorkoutParts.swift:37-38) are below Title 44. **Recommend:** same `p` on all three forms so the name never changes look when it wraps; the sheet's "Title 44 only" is about the role, not the fallback size.
6. **Task run title:** no run object or name exists. **Recommend:** park T12 until a run is a thing with a title; until then the single running task (T11) only strikes at Finish.
7. **Strike color (ruled, Design 2:31 pm):** the strike takes the title's own color at each moment (`currentColor` in the study, title-progress.html:33). At done it draws in the full lean and dries with the title to `driedInk`. It never gets its own color or alpha. In SwiftUI it uses the title's `foregroundStyle`.
8. **Looks with heavier rest weights** (Workshop hero `.bold`, Theme.swift:151; Schibsted `.black`, :195). **Recommend:** done weight is rest plus 140, capped at the face's maximum; on a face already at its heaviest, the lean and strike carry it alone.
9. ~~Fix first~~ **Ruled (Product, 2:28 pm): rider, Builder A 0r. Done:** #546 (merge `8ccb150`) reads `"targetSets"` through `NowPage.plannedSets` (NowPage.swift:214-218), 3 when an entry has none. 0p's `TitleAccent` should read the same `plannedSets`, so the key's ink line and the title never disagree.
10. **The word that matters: the moment or the name? (new, Research BJ)** Sheet 72 round 2 colors the word after the comma, the one that carries the moment ("Push Day A, <bench set 1>", "Paprika chicken, <step 4>", then "done" or "cooked"); round 1's option 2 says the same ("7 pm", "set 2", "3 sessions"). This table, accepted by Product at 2:28 pm, colored the thing's name for thing-first. The two disagree, so Research does not pick silently. **Pick: the sheet's moment word.** Thing-first is a rule about word order, and the name already leads; Kaushik approved the drawn board at 2:09 pm, which colors the moment. Titles that are the name alone (T2, T4, T6, and T3's exercise name) then have no colored word: the whole title moves and that is all. Needs Design and Product to confirm before 0p wires it; both forms sit in the last column so the switch is one line.
11. **Done words (new, Research BJ).** The study's done hero reads "Push Day A, done" and "Paprika chicken, cooked"; master reads "Push A done" (HomeLines.swift:285) and "Paprika chicken done" (:302), and the 2:23 pm comma form is "Push Day A done, bench best". **Pick: keep master's words.** Sheet 72 is about how the title looks, and the words are decided elsewhere; the study's comma is a drawing shortcut. Under open question 10's pick, "done" is the colored word at done. **Ruled by Design (BJ calls): keep master's done words for 0p; a look change carries no copy change, and the comma form would be its own copy PR.**
12. **When the Groceries hold title is done (new, Research BJ).** Design's ruling 2 says "the strike draws at done", but the hold title folds away as the shop starts, and the shop itself finishes much later (`FinishShop`, T9). **Pick: done is the hold landing.** Full weight and lean, the strike draws (420 ms), the lift, then the fold, so the hold reads finished for about 700 ms before the aisles come in. The shop's own progress stays on Home's "Groceries, 9 left" (T9). Design to confirm the fold waits for the strike. **Ruled by Design (BJ calls): done when the hold lands, then the strike and lift play, and the fold waits about 700 ms for the strike.**
