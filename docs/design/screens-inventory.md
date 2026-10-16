# Tessera: every reachable screen on origin/master (73fa1a2, Oct 16 14:20 PT)

The code was read from `origin/master`. The design sheets were read from `claude/project-thread-b3tu3f`, which has no Swift changes against master. Paths are relative to the repo root.

How navigation works on master:
- `App/RootView.swift` holds one `NavigationStack(path: model.path)` with `HomeSpatialView` as its root. Every pushed route (`Route.object` / `.classDef` / `.routines`, `App/AppModel.swift:10-15`) goes through `ObjectPage(route:)`.
- `ObjectPage` hard-codes which routes get their own page (`Features/Objects/ObjectPage.swift:11-28`): exercise to `ExercisePage`, `.routines` to `RoutinesPage`, a plan to `PlansView`, a routine to `RoutineEditor`, and everything else to the generic class or object page.
- `HomeLink` screens (Groceries, Recipes, Paste a recipe, Notes, The week) are `fullScreenCover`s that zoom out of their word (`Features/Home/HomeSpatialView.swift:161-173, 327-354`). Each has its own NavigationStack, a "Close" label word, and swipe-down to close.
- The live workout is a `fullScreenCover` with its own NavigationStack (`RootView.swift:58`, `Features/Workout/WorkoutModeView.swift:18-30`).
- `EdgeSwipeBack` (left-edge pop) is attached only to RoutinesPage, RoutineEditor, ClaudeReceipts and BackupView.

Legend for the "x / side" column:
- **SIDE**: it has a side page.
- **X-SIB**: sibling views paged on x.
- **X-LANE**: x pages through items.
- **ROW**: a row-level swipe.
- **none**: no horizontal gesture of its own.

No screen on master has a "side page" in sheet 69/71/74's sense yet: no INGREDIENTS, LAST TIMES or THE DAY.

## Home / Today
| # | Screen | Files | How you reach it | Object / class | x / side today | Design sheet(s) |
|---|---|---|---|---|---|---|
| 0 | Home pager (container: painted rail of REVIEW · TODAY · TRAINING · KITCHEN, glass tab lens on hold) | `Features/Home/HomeSpatialView.swift` (`PaintedRail`, `deck`, lens) | Launch, or Tess double-tap (paint flood, `RootView.goHome`) | none | **X-SIB**: the four tab pages, `.scrollTargetBehavior(.paging)` at `HomeSpatialView.swift:89-105`. The rail can be held for the lens | home-v1, home-first-review (41/42 lens), area-index (73, which removes the rail; not built) |
| 1 | Today (Now) | `Features/Home/NowPage.swift`, `HomeLineHero.swift`, `HomeQueue.swift` | Tab page (default) | Task, Workout, Process (the Now ranker), and a rest day | **ROW**: queue rows swipe right = finish (strike) and left = TOMORROW / NEXT WEEK, past 120 pt (`HomeQueue.swift:199-231, 380-480`). The capture ghost row swipes left = drop (`NowPage.swift:453`). There is no side page; THE DAY is design-only | home-v1, today-on-home, home-first-review (41), home-labels, task-reward (38), m3-entry-points (26), evening-on-now (17), **today-side (74, THE DAY: not built)** |
| 2 | Plan my day (a state of Today) | `Features/Home/HomePlan.swift` (`PlanRows`), in `NowPage.swift:106` | Plan word on Today | Task (a day plan) | none of its own (the rows are plan rows) | plan-home (53), m4-steers |
| 3 | Task page | `Features/Objects/ObjectPage.swift` (generic `InstanceBody`) | Tap a queue row (`HomeQueue.swift:263`) or the hero (`HomeLineHero.swift:36`) | Task | none | object-model, m3-steers (class inspector) |
| - | Dead code: per-day stroke pager | `Features/Home/DayStrip.swift` (`HomeDayStrip`, `.paging` at :92) | **Not instantiated anywhere** | day | X-LANE (by day), unused | day-strip |

## Training
| # | Screen | Files | How you reach it | Object / class | x / side today | Design sheet(s) |
|---|---|---|---|---|---|---|
| 4 | Training tab (workout at rest, running with RESUME, done, empty) | `Features/Home/TrainingPage.swift` | Tab page | Workout, Routine, Plan | none (the lanes are vertical; tap an exercise to open its page with `.jump`, :678) | training-mode (44), live-workout (56) |
| 5 | Routines (a plan's routines) | `Features/Plans/RoutinesPage.swift` | "Routines" word on the Training tab (`TrainingPage.swift:214`) | Plan to Routine | **ROW**: swipe a row left = **DROP** (`RoutinesPage.swift:310-335`). Hold 0.35 s to reorder (:193-205). Edge swipe back | training-mode (44, "Routines"), swipe-more (71) |
| 6 | Routine page / editor | `Features/Plans/RoutineEditor.swift` (+ the inline `ExerciseLibraryList`, :366) | Tap a routine row, or the Training title for today's routine | Routine to Slot to Exercise | **none**. There is no row swipe here: you drop a slot by tapping to open it and choosing "take it out". Edge swipe back only. LAST TIMES is design-only | routine-editor, training-mode (44), **swipe-more (71, LAST TIMES: not built)** |
| 7 | Plans: WEEK · MONTH | `Features/Plans/PlansView.swift`, `WeekPage.swift`, `MonthPage.swift`, `PlanData.swift`, `Features/Exercise/CarriageRail.swift` | `ObjectPage` routes a Plan object or the Plan class here (`ExerciseRouting.plan`). In practice you reach it through the class tree (path or Subclasses on a generic page). No Home word opens it | Plan, Workout | **X-SIB**: WEEK / MONTH paged with a carriage (`PlansView.swift:38-55`). **Missing from sheet 71's map** | plans, sweep-19 |
| 8 | Exercise page | `Features/Exercise/ExercisePage.swift`, `ExerciseViews.swift`, `ExerciseDigest.swift`, `ExercisePaint.swift` | Tap an exercise on the Training lanes, the live-workout name (`WorkoutParts.swift:31`), or a class row | Exercise (a ClassDef subclass, e.g. Bench Press) | **X-SIB**: HISTORY · REP MAXES · MUSCLES (`ExerciseViews.swift:36-50`) | exercise-page, swipe-more (71: "already on x") |
| 9 | Workout page (scheduled or finished workout) | `Features/Objects/ObjectPage.swift` (generic) | Tap a Review dab (`ReviewPage.swift:269`), a Plans week/month dab, an exercise history row, the Training title when scheduled or done, or a week line | Workout | none. No bespoke "finished workout" page exists; it's the generic object page | object-model (sheets 71/74 assume a "finished page") |
| 10 | Live workout | `Features/Workout/WorkoutModeView.swift`, `WorkoutParts.swift` (`ExerciseLane`), `LiveSetStrokes.swift`, `ExerciseStrip.swift`, `Instruments/*`, `LiveTessCorner.swift`, `WorkoutSession*.swift` | START on Training (rises from the lane), the RunningSeam at the top edge, Tess ("start…"), a resume | Workout, Exercise Entry, Set | **X-LANE**: the exercise lane, `.viewAligned(.alwaysByOne)` (`WorkoutParts.swift:71`). Pull down on the name = swap panel (:76-93). Pull down on the context line = running order (`WorkoutModeView.swift:364`). Rest horizon drag. Never a side page (71) | workout-v1, live-workout (56), set-block, live-polish, edit-set, voice-gym, plate-stack |
| 11 | Running order (drop-down sheet over the workout) | `Features/Workout/ExerciseStrip.swift` (`RunningOrderSheet`) | Tap or pull down the context line or seam | Workout entries | hold-drag reorder, swipe up to close | workout-v1 (strip), live-workout |
| 12 | Workout finish | `Features/Workout/WorkoutFinishView.swift` | The last set, or Finish in the running order | Workout (summary) | swipe down = drop into today (:87) | workout-v1 ("Finishing"), watch-quick-wins (W1) |
| - | (inside the live cover) the exercise page, forced dark | the same as #8, through `WorkoutModeView`'s stack | Tap the exercise name | Exercise | as #8 | live-workout |
| - | (partial surfaces) swap panel, effort handle, live ask field (84 pt sheet) | `SwapPanel.swift`, `WorkoutParts.swift` (`EffortHandle`, `LiveAskField`) | Pull the name; type to Tess | — | — | workout-v1, one-ask |

## Kitchen
| # | Screen | Files | How you reach it | Object / class | x / side today | Design sheet(s) |
|---|---|---|---|---|---|---|
| 13 | Kitchen tab | `HomeSpatialView.swift:357-383` (`KitchenPage`) | Tab page | none (Groceries, Recipes and Paste words) | none. THE WEEK'S COOKS is design-only | kitchen/, today-side (74: not built) |
| 14 | Groceries | `Features/Groceries/GroceriesView.swift` | The "Groceries" word on Kitchen (full-screen cover) | List / List Item, Ingredient | **none**. Rows are tap-to-strike into the basket fold. **The REMOVE swipe (65) is not on master** | kitchen/13-groceries, kitchen/us-shop, list-remove (65: not built), groceries-tess (47), kitchen-week (67) |
| 15 | Groceries: at the shop (live mode) | `GroceriesView.swift` (`AtTheShop`) | Hold the Groceries title | Process (shop), List Item | none | kitchen/13-groceries, kitchen/us-shop |
| 16 | Recipe page (with an inline "Cooking, step n of m" state; there is no separate cook mode) | `Features/Recipes/RecipePage.swift`, `RecipesEntry.swift` (`RecipeView`), `PortionDrum.swift` | The "Recipes" word on Kitchen. **There is no recipe list: it opens the first recipe**, or Paste when none exist. Also after Paste → Save | Recipe, Recipe Line, Cook | **A left swipe is already taken**: swipe the ingredient column left = send to Groceries (`RecipePage.swift:170-200`). That conflicts with sheet 71's claim that the recipe rows have no swipe. INGREDIENTS side is design-only | kitchen/10-11-recipe-page-and-paste, kitchen/us-kitchen-pages (28), recipe-layouts (45), **recipe-clock (69: side not built)**, kitchen/12-cook-mode (not built) |
| 17 | Recipe original + cook history | `RecipePage.swift:314` (`RecipeOriginal`) | Tap the recipe name | Recipe, Cook | none | kitchen/10-11 |
| 18 | Ingredient page | the generic `ObjectPage` through `RecipeDepth` (`RecipePage.swift:298`) | Tap an ingredient | Ingredient | none | object-model |
| 19 | Paste a recipe | `Features/Recipes/PasteRecipe.swift`, `RecipesEntry.swift` (`PasteRecipeView`) | The "Paste a recipe" word on Kitchen, or Recipes with no recipes | Recipe (draft) | none | kitchen/10-11, kitchen-v2, kitchen/link-fetch-us (32) |

## Review
| # | Screen | Files | How you reach it | Object / class | x / side today | Design sheet(s) |
|---|---|---|---|---|---|---|
| 20 | Review tab (the week: day letters, bands, lines; tap a day to read it in place) | `Features/Home/ReviewPage.swift`, `ReviewWeek.swift` | Tab page | Workout, Task, Cook (the week) | **none**. This week only, read a day by tap. **No x paging by week** on master, although 71/74 say "x already moves by week (46)" | review-week (46), review-week-line (15), rest-dab |
| 21 | The week (old Review v0; also the interim Settings: LOOK sentence, the Claude section, the Backups word) | `Features/Review/ReviewView.swift`, `Features/Settings/ClaudeSection.swift` (embedded), `DesignSystem/LookSentence.swift` | The "The week" word at the Review tab's foot (full-screen cover) | the week, Settings | none | m3-steers, claude-settings, themes, settings-place (16: what it should become) |

## Notes
| # | Screen | Files | How you reach it | Object / class | x / side today | Design sheet(s) |
|---|---|---|---|---|---|---|
| 22 | Notes | `Features/Notes/NotesView.swift` (`NotesIndex`) | The "Notes" word at the Review tab's foot (full-screen cover) | Note | none | notes-grammar (57), m3-steers |
| 23 | A note (editor, with links below) | `Features/Notes/NoteEditor.swift` | Tap a note row (zoom) | Note | none. Links sit under the text, and 71 says it never gets a side page | notes-grammar (57), swipe-more (71) |

## Habits; Money / Reading / Body (and Upkeep, People, Day log, Shutdown)
| # | Screen | Files | Status |
|---|---|---|---|
| - | Habits page, a habit | none | **Not on master.** There is no Habit class in `SystemCatalog` (keys at `SystemCatalog.swift:13-24`). Design: habits, habits-grammar (59), body-weight-and-habits §2a |
| - | Body weight page | none | **Not on master**, and no BodyWeight class. Design: body-weight-page (29), body-weight-and-habits |
| - | Money month, ledger, a spend, receipt total | none | **Not on master**, and no Money class. Design: money-dial, money-pages, money-reading-first, money-reading-grammar (60) |
| - | Reading shelf, a book | none | **Not on master**, and no Book class. Design: reading, money-reading-grammar (60) |
| - | Upkeep, chore, People, person | none | **Not on master.** Design: upkeep, people, upkeep-people-first, upkeep-people-grammar (61) |
| - | Day log | none | **Not on master** (Core has `DayLog/DayStory.swift`, but there's no view). Design: day-log-page, day-log-v1 (14) |
| - | Shutdown | none | **Not on master.** Design: shutdown (34), shutdown-grammar (63) |

## Settings / system
| # | Screen | Files | How you reach it | Object / class | x / side today | Design sheet(s) |
|---|---|---|---|---|---|---|
| 24 | Claude receipts | `Features/Settings/ClaudeSection.swift:444` (`ClaudeReceipts`) | "Receipts", or the month's dollars, inside the Claude section on The week | Tess Call | none (edge swipe back) | claude-settings |
| 25 | Backups | `Features/Backup/BackupView.swift` | The "Backups" word at the foot of The week | export / backup | none (edge swipe back) | settings-place (16, the BACKUPS part) |
| 26 | Generic class page (path, properties, subclasses, "Used in", "New subclass") | `Features/Objects/ObjectPage.swift` (`ClassBody`) | The path words on any object or exercise page (`.up`), Subclasses rows | any ClassDef (Thing, Activity, Exercise, Strength Exercise, Barbell Lift, Muscle, Note…) | none | object-model, m3-steers (class inspector) |
| 27 | Generic object page (fallback for every object without its own page) | `ObjectPage.swift` (`InstanceBody`) | `ObjectHandle` refs, backlinks, the rows above | Muscle, Equipment, Process, List, Cook… | none | object-model |
| - | A dedicated Settings page, What Tess knows | none | **Not on master** (design: settings-place 16, settings-eyes 70, tess-knows 49) |
| - | DEBUG only: Soul gallery | `Features/Tess/SoulGallery.swift` | `-soulGallery` launch flag | — | — | tess-soul |

## Tess surfaces
| # | Screen | Files | How you reach it | Object / class | x / side today | Design sheet(s) |
|---|---|---|---|---|---|---|
| 28 | Capture veil: Speak · Write · Show, the Write line, her reply and the ghost row | `Features/Command/BottomChrome.swift`, `CaptureParts.swift` | Tap the soul (bottom-right) on any page | Task, Note, Set, List Item… (captures) | swipe down on the wash = close (`BottomChrome.swift:80`) | no-buttons, calm-capture, one-ask, show-and-hints (Show isn't built: words only) |
| 29 | Speak layer (listening, voice ghost, Heard line, refusal) | `Features/Command/SpeakLayer.swift`, `SpeechListener.swift` | Tap Speak, or hold the soul | the same | none | speak, voice-gym |
| - | Corner soul, paint flood home, the soul in the live workout | `Features/Tess/TessSoul.swift`, `PaintFlood.swift`, `Features/Workout/LiveTessCorner.swift` | always present; double-tap = Home | — | — | tess-soul, living-colours, soul-explore |

Lock Screen and widgets are left out, as asked (`Widgets/RestLiveActivity.swift`, `Shared/Rest*`).

**Counts of built, reachable screens:**
- Home/Today: 3, plus the pager.
- Training: 9 (plus two in-cover sub-surfaces).
- Kitchen: 7.
- Review: 2.
- Notes: 2.
- Habits, Money, Reading and Body: 0.
- Settings/system: 4.
- Tess: 2.
- **Total: 29**, plus the pager.

## Where sheet 71's swipe map and master disagree
1. **DROP** lives on the **Routines page** rows (`RoutinesPage.swift:310-335`), not on the routine editor. On master, the routine editor has no row swipe, so LAST TIMES there would not collide with a row swipe at all.
2. **Groceries' REMOVE (65)** is not on master; Groceries rows are tap-only.
3. **The recipe page already uses a left swipe**: the ingredient column swipes to Groceries. Sheet 71 says it has "no row swipe yet", so the INGREDIENTS side page must resolve this.
4. **Review has no week paging** and there is **no Day log**, so the "x already moves by day or week" rows describe design, not code.
5. **Plans WEEK · MONTH** already has x siblings, and sheet 71's map doesn't list it.
6. `HomeDayStrip` (paging by day) exists but nothing uses it.
7. The "finished workout page" that LAST TIMES and THE DAY taps should open is the generic object page today.

## ViewDef: can a class declare multiple views?
Yes in the model, but nothing uses it.

`TesseraCore/Sources/TesseraCore/Model/Models.swift`:
```swift
441 /// A saved presentation of a class's objects (list, board, calendar…).
443 public final class ViewDef: TesseraModel, AttachableModel {
444     public enum Layout: String, Codable, CaseIterable, Sendable {
445         case list, board, calendar, gallery
446     }
454     public var name: String {
458     public var layoutRaw: String {
462     public var sortIndex: Int = 0 {
466     public var filterData: Data? {
470     public var classDef: ClassDef? {
```
`Models.swift:123`, on ClassDef: `public internal(set) var views: [ViewDef]? = []` (the inverse, so a class has 0…n views, ordered by `sortIndex`).

SQL table: `TesseraDatabaseSchema.swift:60-62`, with columns `viewDef(id, name, layout, sortIndex, filterData, classID)`. It's loaded at :254-262. There's a legacy SwiftData mirror at `TesseraLegacyStore/LegacyViewDef.swift:7-28`, with the same fields.

What it has:
- a name, a layout kind (list, board, calendar, gallery), an order, an opaque filter blob, and the owning class.

What it lacks:
- **No role.** Nothing marks a view as main, side, sibling or widget.
- **No per-field selection or display spec.** FieldDef has no display or role property either (`Models.swift:150-240`).
- **No link to an object page or a gesture.** It describes "a presentation of a class's **objects**", meaning a collection view, not a facet of one object's page.

Usage:
- No ViewDef is ever created. The SystemCatalog and packages seed none, export ignores them, and no view in `Features/` reads `classDef.views`.
- Which page a route gets is hard-coded in `ObjectPage.swift:11-28` and `ExerciseRouting.swift:9-30`.
- Today's x-siblings are ad-hoc Swift enums: `HomeSpatialView.Page` (:31), `PlansView.Page` (:11), `ExerciseViews.Sibling` (:8). Each is drawn with `CarriageRail` or `PaintedRail` plus a `.paging` ScrollView.

Declaring "side" views through the model would therefore need:
- a role (for example `main | sibling | side`), or a kind beyond the 4 layouts;
- possibly a scope ("object page" vs "class collection");
- a registry that maps a ViewDef to a SwiftUI renderer.

The table and relationship are already there to carry this.
