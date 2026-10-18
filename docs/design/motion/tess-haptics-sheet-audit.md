# Haptics: design sheets 12 to 62 against the map in code (board 64)

Status: lab audit, read-only against code at master `e8757a6f`. The map is `enum Haptic` in `DesignSystem/Haptics.swift`
(19 cases; `.done` is the Core Haptics three-beat with a `.success` fallback). Where a sheet and the map disagree, the map
wins (Product, Oct 17). Sheet 38 (`task-reward.md`, "The haptics map") is the sheet that agrees with the code; it is the
reference, and every other sheet below is measured against it.

Scope: kitchen 12, 13; Design items 14 to 62 that name a haptic. Counts, merged by claim: about 74 match, 13 mismatch,
5 have no case, 7 are ambiguous. Sheets with no haptic line (19, 22, 23, 25, 32, 39, 40, 43, 45, 47, 52, 53, 62) are not listed.

## 1. Sheet lines to correct (the map wins)

Each row is a sheet line that names the wrong haptic. The fix is to the sheet wording, not to the code, unless the last column says so.

| # | Sheet:line | Moment | Sheet says | Map says | Code today |
|---|---|---|---|---|---|
| M1 | kitchen/12-cook-mode:47 | A kitchen timer ends | `.notificationOccurred(.success)` | `.timeUp` (heavy 0.9), same as rest end; sheet 38:91 agrees | Not built. `.timeUp` plays only for the workout rest end (`WorkoutModeView.swift:140`). Build `.timeUp`, never `.success`. Plays in Low Power and quiet hours (his own timer). |
| M7 | evening-on-now:49 | Hold "Done for today" | `.success` | `.done` (38:94) | Not built |
| M8 | shutdown:42 | Hold 0.7 s closes the day | `.success`, "§7's one exception" | `.done` | Not built |
| M9 | habits-grammar:25, :53 | Habit check-in | `.impact(medium, 0.8)` | `.done` (38:71 lists the habit check-in) | No call site; if built on the hold key it would play the raw 0.8 impact |
| M10, M11 | live-workout:31, :32 | Workout finish | `.success` | `.done`; `.newBest` replaces it on a best | Follows the map (`WorkoutModeView.swift:706`) |
| M12 | live-workout:32, :35 | The stamp seats | "heavy impact" | `.setLogged` (rigid); heavy 0.9 is `.timeUp` | Follows the map (`:202`, `:207`) |
| M13 | notes-grammar:44 | A note row lands | `.light` ("light" is not a case) | `.made` | Today `.success`, raw, `BottomChrome.swift:131`, matching neither |
| M5, M6 | body-weight-page:36, m3-entry-points:19 | Weigh-in receipt lands | `.impact(.light)` | LOG is `.selection`; "the receipt gets none" (38:96) | No call site |
| M14 | task-reward:99 (and fixture haptic-moments:44) | The never line | "No `.error` or `.warning` anywhere" | `.notSaved` is `.warning`, the one soft cue when a write did not save | No caller yet |

Two sheet-only wordings to carry with the above: the book-finish hold (money-reading-grammar:54, :69) and the chore-finish
hold (upkeep-people-grammar:22, :38, :83) say `.impact(medium, 0.8)`. Both are finishes; both become `.done` (see section 3).

## 2. Sheet lines with no case in the map

| # | Sheet:line | Moment | Sheet says | Lab call |
|---|---|---|---|---|
| M2 | kitchen/12-cook-mode:36 | Each cook step swipe | medium impact per step | No cue. The page turn is its own motion; the step change is announced by the line, not a tap. Drop the sentence. |
| M3 | kitchen/12-cook-mode:41 | Hold 0.6 s on the timer key | `.impact(.medium, 0.8)` | A hold that starts a timer is not a finish. Ruling needed (default below): no new case; the hold-begin light tick stays, the completion plays nothing and the bead's arrival is the cue. |
| M4 | kitchen/13-groceries:28 | Grocery row check, strike lands | light impact at the strike's end | Raw today (`GroceriesView.swift:209`) and equal by value to `.notNow`. Default: add no case; route through `tesseraFeedback` as the light check cue Product ruled (G247). |
| M15 | watch-quick-wins:17, :18 | Watch rest end, Done/UNDO | system notification tap, Watch's own button | Intended gap. Nothing to build. |

Default for M3, flagged for Product: the hold-to-start has no completion haptic, because a start is not a finish and
one haptic per moment is the rule. Say the word and it becomes `.selection`.

## 3. Ambiguous lines and the lab's reading

| Sheet:line | Question | Reading |
|---|---|---|
| live-workout:32 | "the record pattern" | `.newBest` (`.success`), in place of the stamp, never both (38:81). Reword to "the new-best cue". |
| live-workout:32 | `.selection` "per load" | The weight reel detent, `.selection` (38:86). |
| shutdown:53 | UNDO of Shutdown: "No `.success`" | Plays `.undo` (`.decrease`), once, like any UNDO. Say so. |
| tess-knows:56 | "UNDO and the haptic stay" | The one `.selection` of the forget gesture is not replayed; UNDO plays `.undo`. |
| 38:32, :52, :76 | Does an UNDO word also play `.selection`? | No. UNDO is `.undo` alone (one haptic per beat). Check at the call site: a tap-key UNDO would add `.selection` on top (`Paint.swift:307`). |
| lockscreen:53 | "No buzz in quiet hours" | A notification, not a `Haptic`. System sound and vibration follow the notification's own quiet setting. |
| money-reading-grammar:54, upkeep-people-grammar:22 | Finish holds | `.done`. |

## 4. Cases in the map that nothing plays

| Case | Sheet | State |
|---|---|---|
| `.listening` | 38:79 | Never played; listener start (`BottomChrome.swift` ~:599) plays nothing |
| `.fleckReachesNow` | 38:40, :72 | Never played |
| `.notSaved` | Haptics.swift:7-8 | No caller |
| `.timeUp` for a kitchen timer | 38:91, 12:47 | Not built (rest end only) |
| `.soulPickUp`, `.soulDrop` | none | Do not exist anywhere. `.soulStroke` exists and plays (`SoulStroke.swift:125`). |

## 5. Raw `.sensoryFeedback` call sites (24 in 15 files)

Sheet 38:66 says never a raw `.sensoryFeedback`. Thirteen of the 24 equal the map's value and only bypass the vocabulary;
eleven differ from the map for that moment.

Differ from the map (the build owes these, sheet 38 "Changes to what's built"):

| File:line | Today | Should be |
|---|---|---|
| `BottomChrome.swift:131` | `.success` on every capture commit | `.made`; `.done` for an "x done" phrase |
| `PasteRecipe.swift:199` | `.success` | `.made` |
| `ExercisePage.swift:210` | `.success` on add to routine | `.made` |
| `TessSoul.swift:143` | `.success` on `doneCount` | remove (the soul plays none) |
| `HomeQueue.swift:290`, `NowPage.swift:119` | medium 0.8 on a finish | `.done` |
| `Paint.swift:308` | medium 0.8 on any hold completes | per caller: finish `.done`, plan kept `.made`, cook timer hold per M3 |
| `LookSentence.swift:70` | medium 0.8 on pin | `.pinned` (default intensity) |
| `Paint.swift:306` | light on hold begin | no case (see M3) |
| `GroceriesView.swift:209` | light on row check | route through the map (M4) |
| `GroceriesView.swift:402` | rigid on shop start | none (fixture: start plays 0) |

Equal by value, only bypass: `Paint.swift:307`, `LookSentence.swift:69`, `InkActions.swift:78`, `RoutineEditor.swift:92`,
`CaptureParts.swift:141`, `BottomChrome.swift:130` and `:132`, `ReviewPage.swift:312`, `HomeQueue.swift:276`, `:277`, `:291`,
`BackupView.swift:104`, `CarriageRail.swift:47`, and the aisle fold `GroceriesView.swift:581` (also wrong in trigger: it fires on
any aisle change, not only when an aisle clears; `.aisleCleared` is correct at `ListsView.swift:319`).

## 6. Tests the build should carry

1. A grep test: no `.sensoryFeedback(` outside `Haptics.swift`.
2. A moment table test: each row of sheet 38's map has exactly one caller, or is listed here as unbuilt.
3. Kitchen timer end plays `.timeUp` once, in Low Power and in quiet hours; two timers within 600 ms play it once.
4. Capture commit plays `.made` once and never `.success`; "x done" plays `.done` once.
5. UNDO plays `.undo` once and never `.selection` with it.

## 7. Asks

- Product: confirm the M3 default (hold-to-start timer has no completion haptic) and the M4 default (check strike routes through the map as a light cue, no new case).
- Design: the sheet wording fixes in section 1 and section 3 are in Design's files; the lab does not edit them. Product asked the lab to carry the 12-cook-mode correction: M1 above is that correction.
