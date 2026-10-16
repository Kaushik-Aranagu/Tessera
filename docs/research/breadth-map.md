# Breadth map: a first version of every area

*Research lab, for Product and the Coordinator, 2026-10-15. Answers Kaushik's 19:37 "go breadthwise". Checked against origin/master at 5258866 (#124) by grepping the code, not PR titles. "Release" means a normal phone build reaches it from Home; "DEBUG" means only a launch flag or demo seed reaches it.*

## How to read reachability

- Release builds reach: Home (REVIEW · TODAY · TRAINING · KITCHEN in `Features/Home/HomeSpatialView.swift`), the workout, Plans, Exercise pages, Groceries, Recipes, Paste a recipe, Notes, The week (Review), Backups (a word at the foot of Review, `ReviewView.swift:216`), and Tess's corner soul with Write (`Features/Command/BottomChrome.swift`).
- DEBUG only: the launch flags `-notes`, `-review`, `-groceries`, `-backup`, `-soulGallery` (`App/TesseraApp.swift:44`), `-openLink`, `-tessScript`, `-queueScript`, and the demo seeds (`-demoKitchen`, `-demoNotes`, `-demoReview`, `-pasteDemo`). None of these hide a screen that release cannot reach some other way.
- Nothing on master exists for M3, M4, M5 or Build. The catalog (`SystemCatalog.Key`) has no body weight, habit, book, spend, chore or person class, and `Op` has no schema ops.

## Area by area

| Area | On master (release unless marked) | Specced, not built | Smallest first version still needed | Owner |
|---|---|---|---|---|
| v1 Workouts | Slices 1 to 16, 18, 19: live mode and instruments (`Features/Workout/`), Exercise page with rep maxes (`ExerciseDigest.swift`), swaps, routine editor, week and month (`Features/Plans/`), double progression (`Progression.swift`), Health write (`App/Health/HealthExporter.swift`), edit set (#109). #122 engine (RemoveSlot, rest days, "Up X kg") is engine-only, not on screen yet | 17 voice; 14 Prefill fix; #122 screen hookup; Watch W1, W2 | **Already usable.** Nothing blocks a first version; finish the #122 hookup (Builder A Next 4) | Builder A, Core |
| Home and M2 Run my day | Engine 1 to 7 (`TesseraCore/Tasks/`, `Notes/`, `Processes/`). Today on Home with swipes (#116, `HomeQueue.swift`), task finish moment, Notes v0 (10), Review v0 (14), a day strip with lanes (`DayStrip.swift`, 11 partly). Now still reads `AppModel.currentTask`, not a ranker | 11 tasks on the strip (finish), 12 full ledger, 13 day full warning; rest-day override and `rank()` | **Already usable.** Land QA's #116 swipe hotfix, then M2 11 | Builder B, Core |
| Kitchen cooking | Engine 1 to 5, 9 (`TesseraCore/Kitchen/`: `StartCooking`, `StartKitchenTimer`, `FinishCooking`). Recipe page with portion drum (10) and Paste (11) (#86, `Features/Recipes/`). The Cook key starts a cook and shows a "Cooking" line; there is no cook screen, so timers and Finish have no UI | 12 cook mode (no `Features/Cooking/`), 14 shelf, paste hardening, meal plan to groceries | **Kitchen 12, rough:** one step at a time, timers as horizon lines in the app, Finish writes the Cook. Lock Screen timers and the idle rule can follow | Core (screen too, per board) |
| Groceries | Engine 1, 6, 7, 8 and screen 13 (`Features/Groceries/GroceriesView.swift`, #58, #118, #124): aisles, ink strike, basket fold, shop by aisle | Kitchen v2 backlog only | **Done.** Nothing needed for a first version | Core, Kitchen lead |
| Lists | Kitchen slice 1 only (`TesseraCore/Lists/Lists.swift`: CreateList, AddListItem, Check, Move, RenameListSection, ClearDoneItems) and the "list: packing" phrase. Release can create a list by typing it, **but no screen shows it** | Lists 1 to 8 engine (no rename, archive, `AddListItems`, reset, `StartListRun`, pick); screens 9 to 12 (no `Features/Lists/`) | **Lists 1, 3, then screens 9 and 10** (shelf and a list page, strike and sink reused from Groceries) | Core engine, Builder B screens |
| M3 Make it mine | Nothing. `createClass` exists only as an internal store helper (`ObjectStore+Lifecycle.swift:42`), not an action | All 12 slices | **M3 1 (body weight, capture plus rough trend page), 2 (habits engine), 12 (Settings, rough).** Then 3, 6, 10 for Build | Core engine; screens unassigned (suggest Builder A) |
| M4 My day, connected | Nothing. No EventKit; HealthKit is write-only (v1 slice 19); no Plan my day, Shutdown, Day log | All slices 1 to 12, 6b, 10b | **M4 2 (Health read), 1 (calendar), 6 (Plan my day, rules), 7 (Shutdown)** as Now cards | Core engine; Now cards Builder B |
| Reading | Nothing (no book class; "Book" appears only in a doc comment) | Slices 1 to 7 | **Reading 1, 2, 4, then screens 5 (book page) and 6 (resume from the ledger)** | Core engine, Builder B screens |
| Money | Nothing (no spend class, no `Money/`) | Slices 1 to 7 | **Money 1, 2, 4, then screen 7 (month page).** Receipt total (3, 5) later | Core engine, Builder B screens |
| Upkeep | Nothing (no chore class, no `Upkeep/`) | Slices 1 to 7; needs M3 2 | **M3 2, then Upkeep 1, 2, 4, then screen 6 (upkeep page)** | Core engine, Builder B screens |
| People | Nothing (no person class; notes already link with @) | Slices 1 to 8 | **People 1, 2, 3, then screen 7 (People page).** Birthdays (4) later | Core engine, Builder B screens |
| Build | Tess model layer T1 and T2 only (`TesseraTess/TessModel.swift`, `TessTools.swift`, on-device route in `TessModelCapture.swift`). No T3 (no Keychain, no URLSession), no schema ops, no validator | A1 to A5; T3 | **A1, A2, A3, A4** (the spec's own v1). A5 later | Core; A4 screen unassigned (suggest Builder A) |

## Top gaps, by Kaushik's priority order

1. **Lists:** the engine half exists and lists can be created, but he can never see one. Cheapest area to turn on.
2. **M3 Make it mine:** nothing at all, and Upkeep and Build both wait on it.
3. **M4 My day, connected:** nothing at all; it also needs phone testing (calendar and Health permissions).

Reading, Money, Upkeep, People and Build are also empty, but each M5 engine is about an afternoon.

## Dependencies that set the order

- Engine before screens in every area (all M5 lists say "screen after slice N").
- Lists 1 before M3 10 (the List shape creates a Lists `List`). Lists 1 also before Lists screens 9 and 10.
- M3 2 (Habit) before Upkeep 1 (Chore is a child of Habit).
- Build A1 to A3 after M3 3, 6, 10 and model-layer T1 to T3. T1 and T2 are merged; T3 needs Kaushik's Claude key.
- Backups are merged (#112, #114, #120, #124), so new classes are covered by the daily copy with no extra work.
- Not blocking any first version: photo field, Show mode, the ranker, Watch, paste hardening, widgets.
- **Entry points:** every new area needs one Home word. `HomeLink` in `HomeSpatialView.swift` is the place (Builder B). Without it a finished screen is DEBUG-only in practice.

## Suggested order (soonest first version of every area)

Each wave is about a day. Core is the bottleneck, since every new area starts with engine work, so screens move off Core wherever they can.

| Wave | Core (engine) | Builder A | Builder B |
|---|---|---|---|
| 0 (in flight) | QA E3/E4, rest-day override | Tess soul in the workout, persistRest fix, #122 hookup | #116 swipe hotfix, then M2 11 day strip |
| 1 | **Lists 1 and 3** (small; housekeeping and lists from text) | **Kitchen 12 cook mode, rough** (engine already merged; suggest moving the screen from Core to A, A already owns the instruments) | Rest day on Now; Home words ready for new areas |
| 2 | **M3 1 body weight and M3 2 habits** | **M3 12 Settings, rough** (then S1 Claude key slots in here later) | **Lists 9 shelf and 10 list page**, plus a "Lists" Home word |
| 3 | **M4 2 Health read, M4 1 calendar** | M3 1 body weight page, rough; habit rows | Lists 11 item opened (after Lists 2, which Core can slip into wave 2 or 3) |
| 4 | **M4 6 Plan my day (rules) and M4 7 Shutdown** | Kitchen 14 shelf (gives Recipes a real front page) | Plan my day and Shutdown as Now cards |
| 5 | **Reading 1, 2, 4, then Money 1, 2, 4** | Reading screens 5 and 6 (suggest A, to spread M5 screens) | Money screen 7, Home words for Reading and Money |
| 6 | **Upkeep 1, 2, 4, then People 1, 2, 3** | People screen 7 | Upkeep screen 6, Home words for Upkeep and People |
| 7 | **M3 3, 6, 10; T3 once the key arrives** | M3 6 class inspector, rough | M3 10 starting shapes UI |
| 8 | **Build A1, A2, A3** | Build A4 ghost class page | Polish and phone feedback |

After wave 8 every area has a first version. Waves 5 and 6 can move ahead of 3 and 4 if the calendar and Health permissions stall on the phone, since M5 needs no permissions.

## What runs in parallel

- **Builder A** has no hard wait on Core from wave 1: cook mode, Settings, and the kitchen shelf all sit on merged engines. Its M5 and Build screens wait on Core's slice of the wave before.
- **Builder B** waits only on Lists 1 and 3 (wave 1) for the Lists screens, and on M4 6 and 7 for the Now cards. Its Home words for new areas can be stubbed ahead of the screens.
- **Core** runs one engine area per wave without waiting on either builder. M5 engines do not depend on each other, except Upkeep on M3 2, so any one of Reading, Money or People can fill a gap.
- **Not parallel:** Build A1 to A3 (needs M3 3, 6, 10 plus T3), Upkeep (needs M3 2), M3 10 (needs Lists 1).

## Two calls for Product

1. Move the cook mode screen (Kitchen 12) from Core to Builder A, so Core's queue goes to new-area engines. The engine is already on master.
2. Give some M5 screens to Builder A (Reading 5, 6 and People 7). Today all M5 screens sit on Builder B, behind its Home and Lists work.
