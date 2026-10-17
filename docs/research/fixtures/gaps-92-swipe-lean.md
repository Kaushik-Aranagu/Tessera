# Whose-swipe and areaLean fixtures (sheet 92, sections 1 and 2)

For: Builder A and Builder B (screens), Core (resolver and stepping logic), Design and Product (questions at the end), QA. Docs only; nothing was built or run (no Swift toolchain). Written Sat Oct 17 from `design/gaps-92.md` sections 1 and 2, `design/pages-90.md` ("Whose swipe it is"), `design/every-side.md` (sheet 75), `design/sides-77.md`, `design/money-dial.md`, `design/area-motion-97.md`, and master at `24ae561b` (read with the worktree at origin/master).

Status words: **traced** means I read the master line and it does what the row says; **inferred** means the row follows from a sheet or from code I did not read in full; **gap** means master has nothing for it (not built) or contradicts it. Every `file:line` below was opened and read. Sheets 73 and 75: sheet 75 is `every-side.md`; there is no file for sheet 73 in the design folder (not found), so its rules are not used here; the sideways rule comes from sheet 75, `pages-90.md` and the page-turn fixtures TN04/TN05.

Cross-reference, not duplicated: the vertical-swipe rows of `docs/research/fixtures/page-turn.md` section 6 (WS01 to WS14) already pin the general rule: WS08 (own action on a single page), WS09 (mid-drag ownership), WS10 (stepping floor), WS11 (edge zones), WS13 (undeclared never claims), WS14 (innermost owner). Rows here are the per-screen instances plus the cross-cutting rules, with the id prefix **SW** (swipe, this file) so they never collide. Where a row only restates a WS row on a named screen, it says "see WS09" and adds the screen input. Paging itself (PG, RL, TN, TM ids) is not repeated.

Vocabulary: **own action** is a vertical swipe an element owns (a drum, a stepper, a dial). **Plain** means text with no own action: an item's words, a step's text, a section word, the gap between rows, the empty page. **Turn** means the page turn of sheet 90. **Stop** means the small stop an element at its limit plays (see SW30).

## 1. State of master for the three screens (what the rows below rest on)

| Screen | What master has today | Evidence |
|---|---|---|
| Paging (all) | Not built. No `PagedRun`, `PageTurn`, `pageTurn` or page-slot declaration anywhere in Swift on master (grep over `*.swift`: zero hits). A page is a plain `ScrollView`. | `Features/Lists/ListsView.swift:168` (list page `ScrollView`), `Features/Recipes/RecipePage.swift:37` (`ScrollView { page }`) |
| Lists, row | The whole row is one `Button` that checks the item. There is no check circle and no quantity stepper; the quantity is a bold word in the row's text. | `ListsView.swift:352` (`row`), `:354` (`Button { tap(item) }`), `:355` (`item.quantity.map`) |
| Lists, row swipe | Left swipe removes: `simultaneousGesture(DragGesture(minimumDistance: 24))` that only acts when the move is leftward and wider than tall, so a vertical drag falls through to the scroll view. | `Features/Lists/ListsSwipe.swift:35-39`, applied at `ListsView.swift:254` |
| Lists, pick-one hold | 0.6 s long press on the list's pick word, only when the list is pick-one. | `ListsView.swift:214` |
| Lists, section word | Plain `Text(title)`, header trait, no gesture. | `ListsView.swift:246-250` |
| Lists, add field | `TextField` with `@FocusState writing`. | `ListsView.swift:158`, `:408` |
| Recipe, portion drum | A real vertical `ScrollView` with `scrollTargetBehavior(.viewAligned)`, range 1 to at least 12, capped by `RecipeLimits.serves`; `.selection` haptic per detent; VoiceOver `accessibilityAdjustableAction` steps one and clamps to the range. | `Features/Recipes/PortionDrum.swift:71` (scroll), `:85` (viewAligned, limitBehavior .never), `:56` (haptic), `:60-67` (adjustable), `:14-19` (range) |
| Recipe, page | Outer `ScrollView { page }`; the ingredient column carries a left-swipe send-to-Groceries `DragGesture(minimumDistance: 24)` attached with `simultaneousGesture`. | `RecipePage.swift:37`, `:116`, `:129`, `:258-259` |
| Recipe, timer number | Not built. Only copy exists for timers ("Simmer is done."). No stepping number view. | `Features/Kitchen/CookModeCopy.swift:5`, `:27`, `:47` (copy only) |
| Money dial | Not built. No Money feature folder, no `LogShopTotal`, no `ShopReceipt` in app code; the sheet `money-dial.md` is the only spec. The only dial in code is the weight dial's stepping logic in Core. | `TesseraCore/Sources/TesseraCore/Training/Dial.swift:26` (`snap`), `:31` (`step(from:by:)`, clamps to the first and last detent) |

Consequence: the first scroll-versus-drum conflict is already real on Recipe (a vertical `ScrollView` drum inside a vertical page `ScrollView`, `PortionDrum.swift:71` inside `RecipePage.swift:37`). SwiftUI nests them by hit-testing the inner scroll first; that is the behaviour SW10 and SW11 pin. I did not run it, so the claim "the drum wins today" is **inferred** from how nested scroll views resolve.

## 2. Whose swipe: one row per element and per gesture

Columns: input in plain words; expected outcome (exact); master today; status; owner; test. Test names are Swift Testing names (logic, pure) or XCUITest names (marked UI). "Resolver" means the pure function Core owns that, given the touch's start point and the declared elements, returns who owns the touch: `none` (turn), or an element id (SW rows 40 to 44 pin it).

### 2a. Lists (a list page)

| Id | Element | Gesture and input | Expected outcome | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|---|
| SW01 | A row's check (the row is a button; sheet calls it the check circle) | tap on the check | the item checks (strike, moves to done fold) | traced: `ListsView.swift:354` | traced | Builder B | `tapOnRowChecksItem` (existing behaviour; UI `ListsCheckRowUITests`) |
| SW02 | A row's check | vertical swipe up or down starting on the check | no check, no own action (a check has no vertical action, "tap only"); the page turns | row is a `Button`; a drag over a `Button` in a `ScrollView` scrolls today; no paging, so nothing turns | gap | Builder B | `swipeOnCheckTurnsPageNotChecks` (UI) |
| SW03 | A row's check | short, slow press then 10 pt vertical drift, then lift | still no check (movement beyond the tap slop cancels the tap); the page turn recogniser decides by the swipe rule | inferred: SwiftUI `Button` cancels on movement | inferred | Builder B | `driftingTapDoesNotCheck` (UI) |
| SW04 | Pick-one hold (list is pick-one) | press and hold 0.6 s on the pick word, no movement | the pick starts | traced: `ListsView.swift:214` | traced | Builder B | `holdOnPickWordStartsPick` (UI) |
| SW05 | Pick-one hold | press, then drag 8 pt or more vertically before 0.6 s | the hold cancels (no pick); the touch is plain; the page turns | `onLongPressGesture` default maximum distance 10 pt cancels it (inferred, not run); no paging | inferred | Builder B | `verticalDragCancelsPickHoldAndTurns` (UI) |
| SW06 | Pick-one hold | hold 0.6 s so the pick starts, then drag up without lifting | the pick owns the touch to the end; the page does not turn (cross-cut SW20) | not built (pick sheet is a separate overlay, `ListsPick.swift:66`) | gap | Builder B | `startedPickHoldKeepsTouchToEnd` (UI) |
| SW07 | Pick-one hold on a list that is not pick-one | hold 0.6 s | nothing (guard `isPickOne`); plain, so a vertical drag turns | traced: guard at `ListsView.swift:215-216` | traced | Builder B | `holdOnNonPickListDoesNothing` |
| SW08 | Quantity stepper (the spec names one; master has none) | swipe up starting on the quantity number, quantity 3 | quantity 4; one detent haptic is NOT added here (the stepper reuses the check's own finish rules; Open Q4); page does not turn | not built: quantity is text at `ListsView.swift:355`, no gesture | gap | Builder B (view), Core (step and floor) | `quantityStepsUpOnSwipeUp` |
| SW09 | Quantity stepper | swipe down starting on the quantity number, quantity 3 | quantity 2; page does not turn | not built | gap | Builder B, Core | `quantityStepsDownOnSwipeDown` |
| SW10 | Quantity stepper | swipe down on quantity 1 | quantity 1 stays (floor is 1; "0" would remove the item, and a swipe never removes); small stop (SW30); page does not turn | not built | gap | Core | `quantityFloorIsOneAndAbsorbs` |
| SW11 | Quantity stepper | swipe down on a row with no quantity | nothing steps; the row has no stepper to own the touch, so it is plain and the page turns | not built | gap | Builder B | `rowWithoutQuantityIsPlain` |
| SW12 | Quantity stepper on a private row | swipe up on the number | steps as normal; the row still reads "Private item" (see WS12) | not built; the privacy mask exists: `ShopTrip.privateLabel` is read at `ListsView.swift:365` | gap | Builder B | `privateRowKeepsStepping` (covers Lists; WS12 covers workout) |
| SW13 | An item's words | swipe up or down starting on the words | the page turns | no paging | gap | Builder B | `swipeOnItemWordsTurnsPage` (UI) |
| SW14 | An item's words | swipe left starting on the words | the row's Remove swipe, not a turn (sideways never turns, TN04/TN05) | traced: `ListsSwipe.swift:38-40` requires leftward and wider than tall | traced | Builder B | `leftSwipeOnWordsRemovesNotTurns` (existing: `TesseraTests/ListsRemoveTests.swift`) |
| SW15 | A section word | swipe up or down starting on it | the page turns (see WS05) | section word is a bare `Text`, `ListsView.swift:246-250`; no paging | gap | Builder B | `swipeOnSectionWordTurnsPage` (UI) |
| SW16 | The gap between rows | swipe up or down in the gap | the page turns (see WS06) | no paging | gap | Builder B | `swipeInRowGapTurnsPage` (UI) |
| SW17 | The add field (focused) | swipe up or down starting on the field while the keyboard is up | no turn; the touch belongs to the field (caret/selection) | `TextField` at `ListsView.swift:408`; no paging, so nothing to guard yet | gap | Builder B | `focusedAddFieldNeverTurns` (see TN06) |
| SW18 | The add field (not focused) | swipe up starting on the field | the page turns; a tap focuses it | no paging | gap | Builder B | `unfocusedAddFieldIsPlain` |
| SW19 | The done fold word | swipe up or down | turns the page; tap folds; hold resets or clears | tap and hold are traced at `ListsView.swift:736-737`; turn is a gap | gap | Builder B | `swipeOnFoldWordTurnsPage` (UI) |

### 2b. Recipe

| Id | Element | Gesture and input | Expected outcome | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|---|
| SW20 | Portion drum | swipe up starting on the drum, serves 4, written size 4 | the drum scrolls to the next number; serves 5 (the drum moves with the finger, snaps to the nearest number); `.selection` once per detent; page does not turn | traced as a scroll: `PortionDrum.swift:71`, `:85`, `:56`; "page does not turn" is inferred (nested scroll) | inferred | Builder A or B (Recipe owner: B per `RecipePage`) | `drumScrollOwnsVerticalSwipe` (UI) |
| SW21 | Portion drum | swipe down, serves 1 | the drum stays on 1; small stop; page does not turn (cross-cut SW30) | `scrollTargetBehavior(.viewAligned(limitBehavior: .never))` stops at the first row; but a SwiftUI nested scroll view at its edge passes the remaining drag to the outer scroll view (chaining), so the page would move; inferred, not run | gap | Builder B | `drumAtFloorAbsorbsSwipeDown` (UI) |
| SW22 | Portion drum | swipe up, serves at the top of its range (`PortionDrum.range(written:)` upper bound) | stays; small stop; no turn | same chaining risk; range at `PortionDrum.swift:14-19` | gap | Builder B | `drumAtCeilingAbsorbsSwipeUp` (UI) |
| SW23 | Portion drum, disabled (recipe has no size, shows "-") | swipe up on the dash | nothing steps; the dash is plain; the page turns | the dash is a bare `Text` (`PortionDrum.swift:35`), no gesture | inferred | Builder B | `disabledDrumIsPlain` |
| SW24 | Portion drum | drag that starts on a drum number and drifts sideways onto the ingredient column | stays the drum's touch to the end; the ingredient column's left-swipe send must not start | column send gesture is `simultaneousGesture` at `RecipePage.swift:116`, `:129`; it could fire alongside; inferred | gap | Builder B | `drumTouchDoesNotSendIngredients` (UI) |
| SW25 | Timer number (steps minutes) | swipe up on the minutes number of a timer set to 8 | 9; page does not turn | not built (copy only, `CookModeCopy.swift:5`) | gap | Builder B (view), Core (step) | `timerMinutesStepUp` |
| SW26 | Timer number | swipe down at 1 minute | stays 1 (floor 1; a timer at 0 would be "done"); small stop; no turn | not built | gap | Core | `timerMinutesFloorAbsorbs` |
| SW27 | Timer number while the timer runs | swipe up or down on the number | Open Q5: does it step the running timer or is it locked? Until ruled, the fixture expects it is not an own action while running (plain), and the running timer reads only | not built | open | Design | `runningTimerNumberIsNotAStepper` (pending ruling) |
| SW28 | Step text | swipe up or down on a step's text | the page turns | no paging | gap | Builder B | `swipeOnStepTextTurnsPage` (UI) |
| SW29 | Ingredient names | swipe up or down on an ingredient name | the page turns (a tap zooms it, tap on the name shows original text: `RecipePage.swift:9-10`); a left swipe on the column sends all to Groceries (`RecipePage.swift:256-259`) and never turns | tap and left swipe traced; turn is a gap | gap | Builder B | `swipeOnIngredientNameTurnsPage` (UI) |
| SW29b | Section words (INGREDIENTS, STEPS) | swipe up or down on them | the page turns | no paging | gap | Builder B | `swipeOnRecipeSectionWordTurnsPage` (UI) |

### 2c. Money dial (the Groceries total instrument)

The whole instrument is not built; every row is a **gap** whose spec is `design/money-dial.md` plus gaps-92 section 1. "Amount dial" is the pair of drums (whole units at 96, cents at 56); "date chip" is the chip that steps a day (gaps-92 names it; `money-dial.md` as read has no date chip, see Open Q6).

| Id | Element | Gesture and input | Expected outcome | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|---|
| SW30M | Whole-units drum | swipe up, drum at 38 | rolls to 39 (drag tracks the finger, flick coasts about 620 ms, `.selection` per number); page does not turn | not built | gap | Builder B (view), Core (value) | `wholeDrumRollsOnSwipeUp` |
| SW31M | Whole-units drum | swipe down at 0 | stays 0; small stop; no turn | not built | gap | Core | `wholeDrumFloorAbsorbs` |
| SW32M | Cents drum | swipe up at 99 | stays 99, does NOT carry to the whole drum (Open Q7); small stop; no turn | not built | gap | Core | `centsCeilingAbsorbsNoCarry` |
| SW33M | Amount, typed in place (the numeral became a field) | swipe on the field | focused field never turns and never rolls | not built | gap | Builder B | `typedAmountIsFocusedFieldNeverTurns` |
| SW34M | Date chip | swipe up on it, chip reads today | steps a day (direction up = later or earlier is Open Q8); cannot pass today if the spec forbids future dates (Open Q8) | not built | gap | Core | `dateChipStepsOneDay` |
| SW35M | Date chip at its limit | swipe in the limiting direction | stays; small stop; no turn | not built | gap | Core | `dateChipAtLimitAbsorbs` |
| SW36M | The line's words ("In no currency. Last shop was 41.60.") | swipe up or down on plain words | the page turns, if the instrument has more than one page; it is one page on the sheet, so nothing turns (see WS08) | not built | gap | Builder B | `singlePageInstrumentHasNoTurn` |
| SW37M | The currency word | tap | cycles none, euro, pound, dollar, rupee, rolled 380 ms; a vertical swipe on it is plain | not built | gap | Builder B | `currencyWordIsTapOnly` |
| SW38M | The month word / empty page | swipe up or down | the page turns (only where a month page has pages) | not built | gap | Builder B | `emptyMoneyPageTurns` (UI) |
| SW39M | SKIP, "Log" words | swipe on them | plain; taps only | not built | gap | Builder B | `logAndSkipWordsAreTapOnly` |

### 2d. The resolver (Core, pure, no UI)

Input: the touch's first point and each declared element's frame and kind (`none`, `stepper(floor, ceiling)`, `drum`, `dial`, `focusedField`). Output: `turn`, or `owner(id)`.

| Id | Input | Expected | Test |
|---|---|---|---|
| SW40 | first point inside a stepper frame | `owner(stepper)` | `resolverPicksStepperUnderTouch` |
| SW41 | first point outside every declared frame | `turn` | `resolverTurnsOnPlainPoint` |
| SW42 | first point in two frames (number inside a dial) | the innermost (see WS14) | `resolverPicksInnermost` |
| SW43 | a focused field anywhere on screen, first point on plain text | `none` for the turn: the page never turns while a field is focused, even on plain text? Open Q9; the sheet says "a focused field never turns it", read narrowly as touches that start on the field | `resolverFocusedField` (pending Q9) |
| SW44 | an undeclared element | never claims (see WS13) | `resolverIgnoresUndeclared` |

## 3. Cross-cutting rules

| Id | Rule | Input | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|---|
| SW50 | An element that took the first 8 pt keeps the gesture to the end | touch starts on the portion drum, moves 8 pt up, then 200 pt up over plain step text | the drum keeps the touch; the page does not turn; the drum scrolls to its end and absorbs (SW21/SW22) | not built; the 8 pt threshold is a spec number; the existing row-swipe uses 24 pt minimum distance (`ListsSwipe.swift:36`, `RecipePage.swift:259`) | gap | Core (ownership state), Builder B | `touchOwnerIsFixedAfterEightPoints` (extends WS09 with the 8 pt number) |
| SW51 | First 8 pt: before ownership is decided | touch starts on plain text, moves 7 pt up, lifts | no turn (a turn needs the swipe recogniser's own threshold; 7 pt is a nudge); no element took anything | not built | gap | Core | `sevenPointNudgeTurnsNothing` |
| SW52 | The 8 pt is measured from touch-down to the first sample past 8 pt, in the dominant axis | touch moves 6 pt sideways then 9 pt up | counts as vertical (total vertical beyond 8); the owner is decided at the first sample where either axis passes 8 pt, and a mostly-horizontal start belongs to sideways rules | not built | gap | Core | `eightPointOwnerUsesDominantAxis` |
| SW53 | Not handing over mid-gesture, the other way | touch starts on plain text and drifts onto a drum | the page recogniser keeps it; the drum never takes a touch it did not start on | not built | gap | Core | `plainTouchNeverMovesToDrum` |
| SW54 | An element at its limit absorbs | stepper at its floor, swipe in the limiting direction, any distance | value unchanged; one small stop (SW60); page unchanged; no rubber-band of the page | not built | gap | Core, Builder B | `limitAbsorbsWithoutTurning` |
| SW55 | Absorb is per touch, not sticky | at the floor, swipe down (absorbed), lift, swipe up | the second swipe steps up normally | not built | gap | Core | `absorbDoesNotLatch` |
| SW56 | Absorb applies only to the limiting direction | stepper at the floor, swipe up | steps up | not built | gap | Core | `awayFromLimitStillSteps` |
| SW57 | Focused field never turns | any screen, field focused (keyboard up), vertical swipe starts on the field | no turn; same as TN06 | `@FocusState` exists at `ListsView.swift:158`; no paging | gap | Builder B, Builder A | `focusedFieldNeverTurnsPage` (see TN06; rows SW17 and SW33M apply it) |
| SW58 | Sideways is never a turn | any element, swipe starts horizontal | the side page or the row action, never a turn (TN04, TN05) | traced for Lists: `ListsSwipe.swift:38-39` | traced for the row swipe | Builder B | `sidewaysNeverTurnsOnOwnedElements` |
| SW59 | Edge zones | stepper at 60 pt from the screen edge | the edge zones of `depth-76.md` still win (WS11) | `EdgeSwipeBack` exists at `Features/Backup/EdgeSwipeBack.swift:7`, used `ListsView.swift:297`, `RecipePage.swift:218` | inferred | Builder B | `edgeZonesWinOverNumbers` (see WS11) |
| SW60 | The small stop | element at its limit gets a swipe | the number does a 2 pt nudge back (spring through `MotionPolicy`, never a literal curve), no haptic (page-turn fixtures TN09/TN10: one haptic per moment; a stop is not a moment); Reduce Motion: no nudge, the value just holds | not built; Design has not drawn the stop (Open Q2) | open | Design, then Builder B | `stopPlaysThroughMotionPolicyWithoutHaptic` (pending Q2) |
| SW61 | Reduce Motion on the stop | Reduce Motion on, element at limit | no movement, no haptic | not built | gap | Builder B | `stopHonoursReduceMotion` |

### VoiceOver

| Id | Case | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| SW70 | Portion drum under VoiceOver | one adjustable element "Serves, 4"; swipe up and down with one finger increments and decrements by one, clamped to the range | traced: `PortionDrum.swift:57-67` (`accessibilityElement(children: .ignore)`, label "Serves", value, adjustable action clamps with `min`/`max`) | traced | Builder B | `portionDrumAdjustableClamps` (extend `RecipeContextTests`) |
| SW71 | Portion drum at the floor under VoiceOver | decrement at serves 1 | stays 1 (clamp), VoiceOver is not told to turn the page; no stop animation required | traced: `PortionDrum.swift:64` | traced | Builder B | `adjustableDecrementAtFloorHolds` |
| SW72 | Quantity stepper under VoiceOver | adjustable "Rice, quantity 3"; increment 4, decrement 2, floor 1 | not built | gap | Builder B | `quantityAdjustableAction` |
| SW73 | Timer number under VoiceOver | adjustable "Simmer, 8 minutes"; increment and decrement step one minute, floor 1 | not built | gap | Builder B | `timerAdjustableAction` |
| SW74 | Money drums under VoiceOver | "Pounds, 38" and "Pence, 20", each adjustable (sheet text) | not built | gap | Builder B | `moneyDrumsAreAdjustable` |
| SW75 | Page turn under VoiceOver | NOT the adjustable action: the Scroll gesture (three-finger swipe) and the rail turn the page; the page container reads "Produce, page 1 of 2" (TN12) | not built | gap | Builder B | `scrollGestureTurnsPageNotAdjustable` (see TN12) |
| SW76 | An element with both own action and a page | the adjustable action steps the element, never turns; the page element has no `.adjustable` trait of its own, so the two cannot clash on one focus | not built | gap | Builder B | `pageContainerIsNotAdjustable` |
| SW77 | The rail under VoiceOver | the rail is one element "Page 2 of 5" with a Scroll action; it is the second way to turn (the sheet says "the rail") | not built | gap | Builder B | `railIsAnAccessibleTurnControl` |
| SW78 | Switch Control, Voice Control | every own action has a named action as well as the swipe: "Increase", "Decrease" on steppers, so a swipe-only path never exists (same lesson as `.accessibilityAction(named: "Remove")`, `ListsSwipe.swift:23`) | partly traced: Remove and Skip exist (`ListsSwipe.swift:23`, `ListsPick.swift:89`); steppers not built | gap | Builder B | `everyOwnActionHasANamedAction` |

## 4. areaLean: the colour table and the rule

### 4a. Definition

`areaLean(area, look)` returns one colour per area and appearance, used only as the resting colour of four things. The sheet says "a 72% mix with ink". Two readings exist and the contrast results differ (section 4d):

- **Reading A (the table is the result):** the hex in the table is already the final lean colour; `areaLean` returns it directly. Evidence for: the Porcelain values equal master's own tokens (`liveInk` is `#C23A22` for Training, `health` is `#12936A` for Kitchen, `context` is `#5A3DAF` for Review, in `DesignSystem/Looks.swift:54-56`), i.e. Design picked existing pigments.
- **Reading B (the table is the pigment):** `areaLean = 72% pigment + 28% ink`, computed with ink = the look's `ink` token (Porcelain `#121016`, Obsidian `#F5F2EC`, `Looks.swift:54`, `:62`). Evidence for: the same recipe is already in code for Pantry: `ochre.mix(with: Theme.Colors.ink, by: 0.28)` ("72% ochre, 28% ink", `Features/Kitchen/PantryColour.swift:17`), and sheet 97 says the labels "mix from `ink` to `areaLean`".

This fixture writes the rows so either reading passes; the test pins the reading once ruled (Open Q1). Mix math used in 4d: channel = round(0.72 x pigment + 0.28 x ink), per sRGB byte. Note: SwiftUI's `Color.mix(with:by:)` defaults to a perceptual (Oklab) space, so its output will differ from this byte arithmetic by a few units per channel; the test compares with a tolerance of 3 per channel, or Core does the mix in sRGB bytes on purpose (Open Q10).

### 4b. The table

| Area | Porcelain | Obsidian | Master token it equals today |
|---|---|---|---|
| Training | `#C23A22` | `#FF7D62` | Porcelain equals `liveInk` (`Looks.swift:55`); Obsidian `liveInk` is `#FF7A5C`, not `#FF7D62` (differs) |
| Kitchen | `#12936A` | `#52D3A3` | Porcelain equals `health` (`Looks.swift:55`); Obsidian `health` is `#3FD49A`, not `#52D3A3` (differs) |
| Review | `#5A3DAF` | `#B8A3FF` | Porcelain equals `context` (`Looks.swift:54`); Obsidian `context` is `#B7A6E0`, not `#B8A3FF` (differs) |
| Today | none | none | Tess's cobalt is hers; Porcelain `tess` `#2450D8`, Obsidian `#86B4FF` must never be returned for an area |

Other looks (Plein, Lacquer, Celadon) are not given values by the sheet: **gap**, Open Q3. The Obsidian values come from boards drawn on bg `#121014` (see `calm-89.md` line 67, `lists-recipes-87.md` line 35), while master's Obsidian ground is `#000000` (`Looks.swift:61`).

### 4c. Where it may be used, and where never

| Use | Allowed | Detail |
|---|---|---|
| Caps labels (the area's caps label on a page, e.g. a page's small caps word) | yes | full lean colour |
| The title's key word | yes | resting stop of the title progress effect, not its end (sheet 97) |
| The lead numeral | yes | full lean colour |
| The section hairline | yes, at 34% opacity | lean colour at 34%; sheet 97 animates it 60 ms after the label colour |
| Rows (row text, row backgrounds, strikes, check marks) | never | rows stay ink |
| Notes (note text, note body) | never | ink |
| Fills (washes, bars, buttons, backgrounds, the Obsidian bloom) | never | |
| Dots (state dots, bullets, rail dots) | never | the product also has `no-dots.md`; the rail is not a dot (RL05) |
| Tess (her line, her soul, her words) | never | cobalt is hers |
| Pantry state words | yes, and only as Kitchen's lean | replaces `PantryColour` (below) |
| Today | no area colour at all | Today's pages use plain ink |
| A page opened from an area (Lists, Notes, Habits, Money, Reading) | takes that area's lean | from Home it takes Today's ink (`Theme.Colors.ink`), which means no lean colour |
| A page turn | never changes the colour | sheet 97: "colour never changes with the page turn (sheet 90) because the area has not changed" |
| Moving between areas by the side swipe | the colour travels with the name | sheet 97; nothing else recolours |

Pantry in master: `Features/Kitchen/PantryColour.swift:4-17` holds `light = 0xA4601A` and `dark = 0xE3A857` and `stateWord = ochre.mix(with: ink, by: 0.28)`, used once at `Features/Kitchen/PantryView.swift:196`. The sheet removes the ochre; the state word takes Kitchen's `areaLean` ("the same 72% mix", so under Reading B the mix is Kitchen pigment, not ochre, and under Reading A it is `#12936A` / `#52D3A3` directly). Master has no `areaLean` function, no `Area` type carrying a colour, and no Theme token for any of this (grep of `*.swift` for `areaLean`: only the comment at `PantryColour.swift:4`): **gap**.

### 4d. Contrast of the label usage (plain arithmetic, shown)

Formula (WCAG 2.x): linearize each sRGB channel c/255 with `c <= 0.04045 ? c/12.92 : ((c+0.055)/1.055)^2.4`; L = 0.2126 R + 0.7152 G + 0.0722 B; ratio = (L_light + 0.05) / (L_dark + 0.05). Small caps text needs 4.5:1. Hairlines, fills and the large lead numeral need only 3:1, so the table judges the small caps label only; the title key word and the lead numeral are large text (3:1).

Worked example, Kitchen Porcelain `#12936A` on white: R 18 gives 0.0060, G 147 gives 0.2918, B 106 gives 0.1441. L = 0.2126 x 0.0060 + 0.7152 x 0.2918 + 0.0722 x 0.1441 = 0.0013 + 0.2087 + 0.0104 = 0.2204. Ratio = (1.0 + 0.05) / (0.2204 + 0.05) = 1.05 / 0.2704 = **3.88**. The mix (Reading B): R 18, G round(0.72 x 147 + 0.28 x 16) = 110, B round(0.72 x 106 + 0.28 x 22) = 82, so `#126E52`; its channels linearize to 0.0060, 0.1559 and 0.0844, so L = 0.0013 + 0.1115 + 0.0061 = 0.1189 and the ratio is 1.05 / 0.1689 = **6.22**. The other rows were computed with the same formula in a short Python script (no Swift involved); both Kitchen Porcelain figures were also checked by hand above.

| Area, look | Ground | Reading A: hex used directly | Reading B: 72% pigment + 28% ink | Small caps (4.5:1) |
|---|---|---|---|---|
| Training, Porcelain | `#FFFFFF` | `#C23A22` = 5.35 | `#912E1F` = 8.03 | A passes, B passes |
| Kitchen, Porcelain | `#FFFFFF` | `#12936A` = **3.88** | `#126E52` = 6.22 | **A FAILS 4.5:1**, B passes |
| Review, Porcelain | `#FFFFFF` | `#5A3DAF` = 7.72 | `#463084` = 10.41 | both pass |
| Training, Obsidian | `#121014` | `#FF7D62` = 7.53 | `#FC9E89` = 9.36 | both pass |
| Kitchen, Obsidian | `#121014` | `#52D3A3` = 10.10 | `#80DCB7` = 11.57 | both pass |
| Review, Obsidian | `#121014` | `#B8A3FF` = 8.76 | `#C9B9FA` = 10.63 | both pass |
| Training, Obsidian | `#000000` (master ground) | 8.36 | 10.39 | both pass |
| Kitchen, Obsidian | `#000000` | 11.21 | 12.84 | both pass |
| Review, Obsidian | `#000000` | 9.72 | 11.80 | both pass |
| ink alone, for reference | Porcelain `#121016` on white 18.89; Obsidian `#F5F2EC` on `#121014` 16.93 | | | |

Result: **one pair is under 4.5:1 for small caps text: Kitchen on Porcelain under Reading A (3.88).** It passes at 3:1 for large text (the lead numeral, the title key word) and for the 34% hairline, but not for the small caps label. Under Reading B every pair passes. Also: the 72% mix on Obsidian moves toward the light ink, so Obsidian leans lighter and more neutral than the table value; the table value is the saturated one. Other looks are not computed because the sheet gives them no value.

Note: a caps label drawn at 50% opacity during the 320 ms arrival (sheet 97) passes through lower ratios by design; the contrast rows apply to the resting state only.

### 4e. Testable rows for areaLean

All are pure (Core or `DesignSystem` logic, no UI), except those marked UI.

| Id | Case | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| AL01 | Training, Porcelain | resolves to `#C23A22` (A) or `#912E1F` within 3 per channel (B) | no resolver | gap | Core / DesignSystem | `areaLeanTrainingPorcelain` |
| AL02 | Training, Obsidian | `#FF7D62` (A) or `#FC9E89` (B) | no resolver | gap | same | `areaLeanTrainingObsidian` |
| AL03 | Kitchen, Porcelain | `#12936A` (A) or `#126E52` (B) | no resolver | gap | same | `areaLeanKitchenPorcelain` |
| AL04 | Kitchen, Obsidian | `#52D3A3` (A) or `#80DCB7` (B) | no resolver | gap | same | `areaLeanKitchenObsidian` |
| AL05 | Review, Porcelain | `#5A3DAF` (A) or `#463084` (B) | no resolver | gap | same | `areaLeanReviewPorcelain` |
| AL06 | Review, Obsidian | `#B8A3FF` (A) or `#C9B9FA` (B) | no resolver | gap | same | `areaLeanReviewObsidian` |
| AL07 | Today, either look | returns nil (no lean); the caller falls back to `Theme.Colors.ink` | no resolver | gap | same | `areaLeanTodayIsNone` |
| AL08 | Today never returns cobalt | `areaLean(.today)` never equals `Theme.Colors.tess` in any look | `tess` at `Theme.swift:408-409` | gap | same | `todayLeanIsNeverTess` |
| AL09 | Every area x each of the five looks | the function is total: it returns a value for the three non-Today areas on Plein, Lacquer and Celadon too (derivation ruled in Q3), never crashes or returns Porcelain's value by accident on a dark look | `Looks.all` has five (`Looks.swift:91`) | gap | same | `areaLeanDefinedForEveryLook` |
| AL10 | Dark look returns the Obsidian column; light look the Porcelain column | by `Look.isDark` | `isDark` exists (`Looks.swift:53`, `:61`) | traced (the flag) | same | `areaLeanFollowsLookDarkness` |
| AL11 | Contrast, small caps | for every area and look, contrast of the label colour against the look's ground is at least 4.5:1; fails today for Kitchen Porcelain under Reading A | no check | gap | Core | `areaLeanLabelContrastAtLeastFourPointFive` (the test should compute with the formula above, so it fails loudly if Design changes a hex) |
| AL12 | Contrast, large text | lead numeral and title key word at least 3:1 | no check | gap | Core | `areaLeanLargeTextContrastAtLeastThree` |
| AL13 | Hairline at 34% | the section hairline is the lean colour at opacity 0.34, not a separate token | hairline today is `ink.opacity(0.14)` (`Theme.swift:395-397`) | gap | Builder A / B | `sectionHairlineIsLeanAtThirtyFourPercent` |
| AL14 | Mix definition (Reading B only) | `mix72(pigment, ink)` per channel equals `round(0.72 x p + 0.28 x i)` within 3 | the same recipe, with a different base, is at `PantryColour.swift:17` | gap | Core | `seventyTwoPercentMixMatchesArithmetic` |
| AL15 | Pantry state word | `PantryColour.stateWord` is gone; the state word equals `areaLean(.kitchen)` in the current look; `0xA4601A` and `0xE3A857` appear nowhere in app code | `PantryColour.swift:11-12` still defines both; used at `PantryView.swift:196` | gap | Builder B (Pantry owner) | `pantryStateWordIsKitchenLean` |
| AL16 | Pantry, no second hue | a pantry state differs from another by its word and position only: assert the colour of every pantry state word is the same value | `PantryView.swift:196` single use | inferred | Builder B | `pantryStatesShareOneColour` |
| AL17 | Opened-from rule, Lists | Lists opened from Kitchen (Groceries side) takes Kitchen lean; opened from Home takes ink | no origin context is passed to Lists in master (not found in `ListsView.swift`) | gap | Builder B | `listsLeanFollowsOriginArea` |
| AL18 | Opened-from rule, Notes, Habits, Money, Reading | same table: origin area gives its lean; Home gives ink (Today) | same | gap | Builder A / B | `notesHabitsMoneyReadingLeanFollowsOrigin` |
| AL19 | Opened from two places in turn | the same page re-opened from a different area recolours (the origin is read at open, not cached from the first open) | none | gap | Builder B | `leanIsReadAtOpenNotCached` |
| AL20 | Side swipe between areas | the colour travels with the name over the 420 ms word roll; nothing else recolours | not built | gap | Builder A | `leanTravelsWithAreaName` (UI) |
| AL21 | Page turn | colour is identical before and after a turn | not built | gap | Builder B | `pageTurnNeverRecolours` (UI) |
| AL22 | Arrival | caps label, key word and lead numeral mix from ink to lean over 320 ms (`Theme.Motion.house`); hairline fades to 34% over 420 ms, 60 ms later; Reduce Motion: one 150 ms crossfade, all together; no haptic | not built | gap | Builder A | `leanArrivalTiming`, `leanArrivalReduceMotion` |

### 4f. Negative rows (each forbidden use pinned)

Each is a test that finds the colour where it must not be. Implementation hint: render the view's token tree or, where views are opaque, assert on the model that feeds the colour (a `ColourRole` enum with `.lean` allowed only for four roles).

| Id | Forbidden use | Expected | Master today | Status | Owner | Test |
|---|---|---|---|---|---|---|
| AN01 | A row's text, strike or check | ink only, never lean | rows use `Theme.Colors.ink` (`ListsView.swift:359`) | traced | Builder B | `rowsNeverUseLean` |
| AN02 | A note's text or its tag | ink or secondary only | not checked | inferred | Builder B | `notesNeverUseLean` |
| AN03 | A fill (wash, bar, button, background, bloom, the done fold) | no `areaLean` as fill colour | none yet | inferred (nothing uses it) | Builder A / B | `leanIsNeverAFill` |
| AN04 | A dot (state dot, bullet, rail dot) | no dot is lean; the rail segment uses the "area colour" per RL02 of page-turn fixtures, which is a rail not a dot: Open Q11 whether the rail's current segment may use lean | the page-turn fixture RL02 says "in the area colour" | conflict, see Q11 | Design | `railSegmentColourRuling` (pending Q11) |
| AN05 | Tess (her line, soul, words, the thinking bloom) | `Theme.Colors.tess` only | `Theme.swift:408` | traced for the token | Builder A | `tessIsNeverLean` |
| AN06 | Today | no lean anywhere on Today pages | n/a | gap | Builder A | `todayHasNoLean` |
| AN07 | A page opened from Home | uses ink, not any area's lean | n/a | gap | Builder B | `fromHomeUsesTodayInk` |
| AN08 | The Pantry ochre | not present in the app target after the pass | `PantryColour.swift:11-12` | gap | Builder B | `noOchreLiteralRemains` |
| AN09 | Lean on a label that is not one of the four uses (e.g. a caps word on a row, a button word) | ink or the role's own colour | n/a | inferred | Builder A / B | `leanOnlyInFourRoles` |
| AN10 | Lean at the wrong opacity | hairline is 34% exactly; labels, key word and numeral are 100% at rest | n/a | gap | Builder A / B | `leanOpacitiesAreFixed` |

## Gaps by owner

**Core**
- The pure touch-owner resolver (SW40 to SW44) and the 8 pt ownership rule (SW50 to SW53).
- Step logic with floors and ceilings for quantity (floor 1), timer minutes (floor 1), whole and cents drums, date chip (SW08 to SW10, SW25 and SW26, SW30M to SW35M). Reuse the shape of `WeightDial.step(from:by:)`, which already clamps (`Dial.swift:31`).
- `areaLean(area, look)` as a pure function with a colour-resolver test per area and look (AL01 to AL10, AL14), and the contrast helper (AL11, AL12, using the formula in 4d).

**Builder A**
- The Training and Review pages of the lean pass (AL20, AL22, AN05, AN06), Today having none; side-swipe colour travel.
- Set history paging gestures where it has an own action (live workout numbers are in WS01 and WS02 of the page-turn fixtures).

**Builder B**
- Lists: quantity stepper (does not exist), declare plain versus owned elements, focused add field guard (SW02 to SW19).
- Recipe: portion drum limit absorption (SW21, SW22, SW24 are likely real bugs once paging lands because nested scroll views chain), timer number (SW25 to SW27), plain step and ingredient text (SW28, SW29).
- Money dial: the whole instrument (SW30M to SW39M).
- Accessibility named actions and adjustable parity (SW72 to SW78).
- Remove `PantryColour` ochre and take Kitchen's lean (AL15, AL16, AN08); Lists, Notes, Habits, Money, Reading origin-area lean (AL17, AL18, AL19).

**Design**
- The small stop (SW60): what it looks like, how far, which curve (through `MotionPolicy`).
- Lean values for Plein, Lacquer, Celadon (AL09); Reading A or B; the rail colour (Q11).

## Open questions for Design and Product

1. **Is the table the final colour or the pigment?** "A 72% mix with ink" plus a hex per area reads both ways. Under the final-colour reading Kitchen Porcelain `#12936A` is 3.88:1 on white and fails 4.5:1 for small caps labels. Under the pigment reading everything passes. Which is it, and if it is the final colour, what is the Kitchen small-caps colour on Porcelain?
2. **What does "its own small stop" look like?** Distance, curve, whether it is a nudge of the number or of the whole element, and Reduce Motion behaviour. This fixture assumes no haptic (one haptic per moment); confirm.
3. **Plein, Lacquer, Celadon:** what is each area's lean there? The sheet names only Porcelain and Obsidian; `Looks.all` has five looks (`Looks.swift:91`).
4. **Does the Lists quantity stepper exist as a feature?** Gaps-92 names "the quantity stepper (step up and down)" on a list page, but a list item's quantity is today only text (`ListsView.swift:355`). Is the stepper new, or do Groceries' steppers (`GroceriesView.swift:489`, `:662`, `:777` handle the count) apply to Lists too? Does it give any haptic on a step?
5. **Running timer:** can the timer's number be swiped while the timer runs, or only before it starts?
6. **Money date chip:** `money-dial.md` as read has no date chip; gaps-92 names one. Where does it sit and what is its range (can it pass today)?
7. **Cents carry:** does the cents drum carry into the whole drum at 99 to 00 (rolling like an odometer) or absorb at 99? The sheet's rule says an element at its limit absorbs, which implies no carry.
8. **Date chip direction:** swipe up steps later or earlier?
9. **Focused field:** "a focused field never turns it": only for touches that start on the field, or for any touch on the screen while a field is focused (keyboard up)? Fixture SW43 depends on it.
10. **Mix space:** is the 72% mix done in sRGB bytes or in the system's perceptual mix? They differ by a few units; the tests need one answer or a tolerance.
11. **The rail:** page-turn fixture RL02 says the current segment is "in the area colour"; the lean rule says never on dots or fills. Is a 3 pt rail segment allowed to take the lean (it is not a label, key word, numeral or hairline), or is it ink?
12. **Obsidian ground:** the boards use `#121014` for Obsidian; master's Obsidian ground is `#000000` (`Looks.swift:61`). The contrast passes on both; which is the truth for tests?
13. **Obsidian tokens:** the table's Obsidian hexes (`#FF7D62`, `#52D3A3`, `#B8A3FF`) differ from master's Obsidian `liveInk`, `health`, `context` (`#FF7A5C`, `#3FD49A`, `#B7A6E0`). Should `areaLean` be new tokens or should the Obsidian palette change to match?
14. **Sheet 73:** there is no `73` file in the design folder; if it holds extra whose-swipe rules, they are not in this fixture.
