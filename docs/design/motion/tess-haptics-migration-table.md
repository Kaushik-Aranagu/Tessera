# Haptics migration table: raw `.sensoryFeedback` sites to the map (board 65)

For Builder A. Code read at master `dd1f2835` (`git grep -n "\.sensoryFeedback("` outside `Haptics.swift`): **25 lines in 15
files**, one more than the audit's 24 (the audit merged two lines of `Paint.swift`). Every line is below, in file order. Rule
(sheet 38:66): always `.tesseraFeedback(<Haptic>, trigger:)`, never a raw `.sensoryFeedback`. Product defaults confirmed on #957:
a hold-to-start timer plays no completion haptic; a grocery row check is the map's light cue with no new case.

Key: **swap** = same sound, change only the modifier (no behavior change). **change** = the sound changes. **drop** = remove.
**new case** = none; every row maps to an existing case or to nothing.

## 1. Swap only (same value, route through the map)

| # | File:line | Today | Replace with | Moment |
|---|---|---|---|---|
| 1 | `DesignSystem/InkActions.swift:78` | `.selection` on `isPressed` (when true) | `.tesseraFeedback(.selection, trigger: configuration.isPressed)` with the same "new only" filter | Any ink word pressed |
| 2 | `DesignSystem/LookSentence.swift:69` | `.selection` on `taps` | `.tesseraFeedback(.selection, trigger: taps)` | Look word cycles |
| 3 | `DesignSystem/Paint.swift:307` | `.selection` on `completions`, `isTap && !isSilent` | `.tesseraFeedback(.selection, trigger: completions)` keeping the filter | Tap key completes |
| 4 | `Features/Backup/BackupView.swift:104` | `.selection` on `folderTaps` | `.tesseraFeedback(.selection, ...)` | Folder chosen |
| 5 | `Features/Command/BottomChrome.swift:130` | `.selection` on `opens` | `.tesseraFeedback(.selection, ...)` | Tess opens |
| 6 | `Features/Command/BottomChrome.swift:132` | `.decrease` on `undos` | `.tesseraFeedback(.undo, trigger: undos)` | UNDO (the one app-wide slot) |
| 7 | `Features/Command/CaptureParts.swift:141` | `.selection` on `isPressed` | `.tesseraFeedback(.selection, ...)` | Capture part pressed |
| 8 | `Features/Exercise/CarriageRail.swift:47` | `.selection` on `current` | `.tesseraFeedback(.selection, ...)` | Rail detent |
| 9 | `Features/Home/HomeQueue.swift:276` | `.selection` on `armed` | `.tesseraFeedback(.selection, ...)` | Swipe armed |
| 10 | `Features/Home/HomeQueue.swift:277` | light 0.5 on `holding` | `.tesseraFeedback(.pickedUp, trigger: holding)` | Row picked up |
| 11 | `Features/Home/HomeQueue.swift:291` | light on `moves` | `.tesseraFeedback(.notNow, trigger: moves)` | Not now |
| 12 | `Features/Home/ReviewPage.swift:312` | `.selection` on `taps` | `.tesseraFeedback(.selection, ...)` | Review tap |
| 13 | `Features/Plans/RoutineEditor.swift:92` | `.selection` on `haptic` | `.tesseraFeedback(.selection, ...)` | Routine editor tick (line 441 already uses the map) |

## 2. Change (the sound moves to the case the sheets name)

| # | File:line | Today | Replace with | Why |
|---|---|---|---|---|
| 14 | `Features/Command/BottomChrome.swift:131` | `.success` on `soul.isBright` (every capture commit, any kind) | `.tesseraFeedback(.made, ...)`; `.done` when the phrase finished something ("x done"); `.undo` is row 6 | 38:112, fixture haptic-moments rows 15, 19-23. Keep the "lit only" filter. Capture-miss route and walled phrases play the same `.made` (one haptic, receipts unchanged). |
| 15 | `Features/Recipes/PasteRecipe.swift:199` | `.success` on `saved?.id` | `.tesseraFeedback(.made, ...)` | 38:113 |
| 16 | `Features/Exercise/ExercisePage.swift:210` | `.success` on `added` | `.tesseraFeedback(.made, ...)` | Adding to a routine is a made object; fixture says "decide made" and this is the decision |
| 17 | `Features/Home/HomeQueue.swift:290` | medium 0.8 on `finishes` | `.tesseraFeedback(.done, trigger: finishes)` | 38:110 |
| 18 | `Features/Home/NowPage.swift:119` | medium 0.8 on `finishes` (hero finish) | `.tesseraFeedback(.done, ...)` | 38:110 |
| 19 | `DesignSystem/LookSentence.swift:70` | medium 0.8 on `pins` | `.tesseraFeedback(.pinned, trigger: pins)` | 38:97 (default intensity, not 0.8) |
| 20 | `Features/Groceries/GroceriesView.swift:581` | medium on `current.aisle` (every aisle change) | New event, not a move: fire `.tesseraFeedback(.aisleCleared, ...)` when a check leaves its aisle with no open row (no such event exists today; it is new logic in `GroceriesView`). That check's own light cue (row 21) is not played: one moment, one haptic. Nothing on a plain aisle change. | 38:93: the cue is "aisle cleared", not "aisle changed". Lists reset already plays `.aisleCleared` (`ListsView.swift:319`). |
| 21 | `Features/Groceries/GroceriesView.swift:209` | light on `landed` (row check strike lands) | `.tesseraFeedback(.notNow, trigger: landed)` as the map's light cue; no new case | Product default on #957 (G247: check is the light cue) |
| 22 | `DesignSystem/Paint.swift:308` | medium 0.8 on any hold completes (`!isSilent`) | Stop playing in the key. The owner of each hold plays its case through `tesseraFeedback`: hero finish `.done` (see 18), plan kept `.made` (`NowPage.swift:192`), Lists reset `.aisleCleared` (`ListsView.swift:631`, already plays), cook timer hold none (Product default). Mark every hold `isSilent` and delete the line. | A key cannot know its moment |
| 23 | `DesignSystem/Paint.swift:306` | light on `isPressing`, non-tap holds | Delete | Press-start ticks on LOG, FINISH and the cook hold have no row in the map; one haptic per moment |
| 24 | `Features/Groceries/GroceriesView.swift:402` | rigid on `started` (shop start) | Delete | Fixture: a shop start plays 0; `.done` is only for the finish (`GroceriesView.swift:211` already) |

## 3. Drop

| # | File:line | Today | Action | Why |
|---|---|---|---|---|
| 25 | `Features/Tess/TessSoul.swift:143` | `.success` on `doneCount` | Delete the line | 38:111. The soul plays no haptic; every Done already has its owner's cue. This is the double buzz on a set (2), a best (2, 1.2 s apart) and a finish (2). |

## 3b. The UNDO word (added after QA and Ops, #960)

| # | File:line | Today | Replace with | Why |
|---|---|---|---|---|
| 26 | `Features/Command/CaptureParts.swift:141`, `DesignSystem/InkActions.swift:78` | the UNDO word is a pressed ink word, so its press plays `.selection` in addition to `BottomChrome.swift:132`'s `.decrease`: two ticks | Row 1 and row 7 swap to `.tesseraFeedback(.selection, ...)` for every ink word **except UNDO**: give the style a `silent` flag the UNDO word sets, so its press plays nothing and the single haptic is `.tesseraFeedback(.undo, trigger: undos)` (row 6). | One moment, one haptic (38:32, :52, :76: UNDO is `.decrease` only). Tests: UNDO plays `.undo` once and never `.selection` with it. |

## 4. Cases nothing plays yet (not raw sites, listed so none is forgotten)

`.listening` (start of listening, `BottomChrome` listener start), `.fleckReachesNow`, `.notSaved` (the one soft `.warning` when a write
did not save), and `.timeUp` for a kitchen timer (cook clock spec, #946). These are new call sites, not migrations.

## 5. Order and checks

1. First PR: row 25, then 14-18 (the double-buzz and the success/medium family). These are the ones he feels.
2. Second PR: 1-13 (pure swaps), then 19-24.
3. After rows 22-23, check every `PaintKey` caller: each hold that finishes a moment now needs its owner's `tesseraFeedback`, or it goes silent by design. The list: `NowPage.swift:223` (hero finish `.done`), `NowPage.swift:192` (plan kept `.made`), `ListsView.swift:631` (reset, already plays `.aisleCleared`), `GroceriesView.swift:673` (Clear the basket, ruled `.success`), `BackupView.swift:210` (Restore hold: no case in the map; default none, it ends in a full reload; Product to rule), `WorkoutModeView.swift:628` and `:669` (already silent), the cook timer hold (silent).
4. Test: `git grep -n "\.sensoryFeedback(" -- App DesignSystem Features Widgets Shared` returns only `Haptics.swift`. A snapshot test on the `Haptic` call table: capture commit `.made` once, "x done" `.done` once, UNDO `.undo` once and never `.selection` with it, set logged one haptic, finish one haptic.
5. Quiet hours and Low Power: `.timeUp`, his own touches and the `.warning` play; Tess-initiated landings (`.made` from a spoken or typed capture is his own touch; a plan that lands by itself is not) follow quiet hours once `Haptic` carries an origin. That origin field is separate work (cook clock spec).
