# Screens inventory check (Research BD)

*Research, Oct 16. Checks Design sheet 75 (`every-side.md`) and its inventory (`screens-inventory.md`, written against master 73fa1a2) against origin/master a438262. Docs only. Rulings read: decisions 2:24 PM (on `claude/project-thread-tjn3bv`), and Product's 2:41 PM rulings as sheet 75 folds them in ("Rulings folded in", 2:45 PM). The 2:41 and 2:37 entries were not yet on master or any pushed branch when this was written, so this file follows sheet 75's summary of them. Paths are from the repo root; every line number was read on a438262.*

## Summary

| Count | What |
|---|---|
| 26 | Screens sheet 75 gives a side (rows 1 to 27, without 11; 1 and 2 share a row, and so do 14 and 15) |
| 26 | Of those, built on master |
| 0 | Of those, missing on master |
| 0 | Screens on master that already have a side page (every "x / side today" in the inventory still holds) |
| 4 | Places on master missing from the inventory or under-described (M1 to M4) |
| 3 | Inventory rows or claims that are stale or name something master does not do (S1 to S3) |
| 5 | Sides that break the old 10:00 AM house rule (4 tab pages and the live workout), all replaced by 2:24 and 2:41 |
| 4 | Private leaks a side would open if built as drawn (PL1 to PL4), plus 3 to watch |

Between 73fa1a2 and a438262 only six Swift files under `Features/` changed (`CaptureParts`, `NoteEditor`, `Receipts` (new, not a screen), `RoutineEditor`, `RoutinesPage`, `SwapPanel`, `WorkoutParts`). None adds or removes a screen. One inventory line reference moved (S1).

## How navigation works on a438262 (confirmed)

- One root stack: `App/RootView.swift:17` with `.navigationDestination(for: Route.self)` at :21, every route into `ObjectPage(route:)`.
- `Route` has three cases (`App/AppModel.swift:10-15`): `.object`, `.classDef`, `.routines`.
- `ObjectPage` picks the page at `Features/Objects/ObjectPage.swift:13-28`: exercise, routines, plan, routine, else generic.
- Home's five `HomeLink` covers: `Features/Home/HomeSpatialView.swift:161` (cover), :327-354 (the enum and destinations). Words at :195 (`.review, .notes` on the Review tab) and :378 (`.pasteRecipe` on Kitchen).
- The live workout cover: `App/RootView.swift:58`, its own stack at `Features/Workout/WorkoutModeView.swift:18`, routing every `Route` through `ObjectPage` at :22-23.
- `EdgeSwipeBack`: `RoutinesPage.swift:94`, `RoutineEditor.swift:92`, `ClaudeSection.swift:489`, `BackupView.swift:155`. Only these four, as the inventory says.
- Sheets: one, the live ask field (`WorkoutModeView.swift:156`).

## Every sheet 75 screen against master

"Side on master" is no for every row: no screen on master has a side page.

| # | Screen | Built on master (file:line) | x today on master | Sheet 75 side | Old 10:00 rule |
|---|---|---|---|---|---|
| 1 | Today | `Features/Home/NowPage.swift:6`; queue row swipes `Features/Home/HomeQueue.swift:199-256`; ghost row drop `NowPage.swift:453` | ROW | THE DAY (AHEAD), swipe or word | Conflict: tab page |
| 2 | Plan my day | `Features/Home/HomePlan.swift`, a state of `NowPage` | none | shares THE DAY | Conflict: tab page state |
| 3 | A task | generic `InstanceBody`, `Features/Objects/ObjectPage.swift:215` | none | ITS STORY (BEFORE) | ok |
| 4 | Training tab | `Features/Home/TrainingPage.swift:7` | none | THE WEEK (AHEAD) | Conflict: tab page |
| 5 | Routines | `Features/Plans/RoutinesPage.swift:7`; reached at `TrainingPage.swift:214`; DROP row swipe `RoutinesPage.swift:281-343` | ROW | LAST TIMES per routine | ok |
| 6 | A routine | `Features/Plans/RoutineEditor.swift:9`, routed at `ObjectPage.swift:21-25` | none | LAST TIMES (BEFORE) | ok (two taps down; see Q3) |
| 7 | Plans WEEK · MONTH | `Features/Plans/PlansView.swift:7`, paging at :54 | X-SIB | THE PLAN (FACTS), word only | ok |
| 8 | An exercise | `Features/Exercise/ExercisePage.swift:7`; siblings `Features/Exercise/ExerciseViews.swift:8-9`, paging :49 | X-SIB | YOUR SETUP (FACTS), word only | ok |
| 9 | A workout | generic `InstanceBody`, `ObjectPage.swift:215`; Start workout at :268-273 | none | THE SETS (PARTS) | ok |
| 10 | Live workout | `Features/Workout/WorkoutModeView.swift:11`; lane `Features/Workout/WorkoutParts.swift:71`; name pull :78-85 | X-LANE | the running order, as built | Conflict in name only: sheet 75 says its pull-down running order already is its side |
| 12 | Workout finish | `Features/Workout/WorkoutFinishView.swift:12`; swipe down :87 | none | THE SETS (PARTS), word | ok |
| 13 | Kitchen tab | `KitchenPage`, `HomeSpatialView.swift:357-383` | none | THE WEEK'S COOKS (AHEAD) | Conflict: tab page |
| 14 | Groceries | `Features/Groceries/GroceriesView.swift:13` | none (tap to strike; REMOVE not built) | FOR WHAT (LINKS) | ok |
| 15 | At the shop | `AtTheShop`, `GroceriesView.swift:471`, used at :73; hold the title :460 | none | FOR WHAT as a peek | ok (live, peek per rule 7) |
| 16 | A recipe | `Features/Recipes/RecipePage.swift:11`; column swipe `sendGesture` :170-200 | the column's left swipe | INGREDIENTS (PARTS) | ok |
| 17 | Recipe original | `RecipeOriginal`, `RecipePage.swift:314`, routed by `RecipeDepth` :298-311 | none | COOKS (BEFORE) | ok |
| 18 | An ingredient | generic page through `RecipeDepth`, `RecipePage.swift:308`; link at :255 | none | PER 100 G (FACTS) | ok |
| 19 | Paste a recipe | `Features/Recipes/PasteRecipe.swift`; entry `Features/Recipes/RecipesEntry.swift:30-43` | none | WHAT I READ (PARTS) | ok |
| 20 | Review tab | `Features/Home/ReviewPage.swift:218` | none (no week paging) | THE MONTH, word only "once x moves by week" | Conflict: tab page |
| 21 | The week (interim Settings) | `Features/Review/ReviewView.swift:10`; Claude section embedded; Backups link :229-235 | none | WHAT LEAVES THE PHONE (FACTS) | ok |
| 22 | Notes | `Features/Notes/NotesView.swift:8`, own stack :14-20 | none | BY THING (LINKS) | ok |
| 23 | A note | `Features/Notes/NoteEditor.swift:7`, pushed at `NotesView.swift:16-18` | none | WHERE IT'S MENTIONED (LINKS) | ok |
| 24 | Claude receipts | `ClaudeReceipts`, `Features/Settings/ClaudeSection.swift:444`; links :151, :194 | none | BY JOB (FACTS) | ok |
| 25 | Backups | `Features/Backup/BackupView.swift:10` | none | WHAT'S IN ONE (FACTS) | ok |
| 26 | A class page | `ClassBody` in `ObjectPage.swift` (class route at :35-38) | none | ITS OBJECTS (PARTS) | ok |
| 27 | Any other object | `InstanceBody`, `ObjectPage.swift:215-272` | none | the default side | ok |

Not given a side by sheet 75, correctly (rule 2, overlays): #0 the Home pager (a container whose four pages each have their own row), #11 the running order (`Features/Workout/ExerciseStrip.swift:68`), #28 the capture veil, #29 Speak, the swap panel and the live ask sheet.

## On master, missing from the inventory (M)

- **M1. Any page pushed inside the live workout cover.** The inventory lists only the exercise page there. The live stack routes every `Route` through `ObjectPage` (`WorkoutModeView.swift:22-23`), so a class page, a workout page or a routine editor can also sit over the live lane (through the path words on the exercise page). Each would carry its normal side; rule 7 says a live screen's side is a peek. It needs a ruling whether a page pushed over the live surface counts as live (Q2).
- **M2. Generic pages pushed inside the Recipes cover.** `RecipeDepth` sends anything that isn't a recipe to `ObjectPage` (`RecipePage.swift:298-311`), and that page's "Linked from" rows push further (`ObjectPage.swift:254-263`). So #26 and #27 are also reachable inside the Recipes cover, not only from the root stack. Same side, no new screen; worth one line in the inventory so the SideHost is tested inside that stack too.
- **M3. Paste to saved recipe.** `PasteRecipeView` pushes `RecipePage` with `navigationDestination(item:)` (`RecipesEntry.swift:36-38`), a second stack for #16. The inventory mentions it in passing; it matters for the side because #16's swipe must work in both stacks.
- **M4. A private Tess memory on the generic page.** `TessMemory` objects (`SystemCatalog.swift:254-265`, with `isPrivate` "Stays on this phone" at :264) reach #27 through the class tree. The generic front already prints every field (`PropertyList`, `ObjectPage.swift:342-360`), including a private memory's `rule`. That is a front issue, not a side one, but the default side inherits it (PL2).

## Inventory claims that are stale or name what master doesn't do (S)

- **S1.** "DROP lives on the Routines page rows (`RoutinesPage.swift:310-335`)". On a438262 the row is `RoutinesPage.swift:281-343` (the comment at :281, the gesture at :329, the accessibility action at :343). The claim stands; only the lines moved.
- **S2.** Row 20's "word only once x moves by week (46)" describes design: master has no week paging on Review (the inventory says so itself). Until 46 is built, x on Review is free, so the side could take the swipe too. Sheet 75 should say "swipe or word until 46 lands".
- **S3.** `HomeSpatialView.swift:27`'s doc comment still says "three sibling pages on x, REVIEW · TODAY · TRAINING", but `Page` has four cases (:31-32, with KITCHEN). The inventory is right; the comment is stale. A Builder B fix, not a side issue.

No inventory row names a screen that doesn't exist on master. The seven "Not on master" rows (Habits, Body weight, Money, Reading, Upkeep and People, Day log, Shutdown) are correct: there is no Habit, BodyWeight, Money, Book, Chore or Person key in `SystemCatalog.Key` (`TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:12-25`), and `DayStory` (`TesseraCore/Sources/TesseraCore/DayLog/DayStory.swift`) has no view. `HomeDayStrip` (`Features/Home/DayStrip.swift:77`, paging :92) is still never used.

## The house rule

The 10:00 AM rule ("a page one tap down may have one side page; never a tab page or a live workout") was replaced at 2:24 PM ("every screen has a side", Kaushik 2:20), and 2:41 set the rollout order. Under the old rule, 5 of sheet 75's sides would conflict: Today (with Plan my day), Training, Kitchen and Review are tab pages, and the live workout is live. These are no longer conflicts. Rule 7 keeps the spirit for live screens: the live workout's side is its running order, and the shop's is a peek.

One overlap is left to check: rule 4 says that when x is taken, the word is the only way. On master that is #7 (X-SIB), #8 (X-SIB), #10 (X-LANE) and #16 (the column swipe, which 2:41 moves onto the side's key). Today's queue rows, the Routines rows and the ghost row keep their row swipes, so on #1 and #5 the page swipe must start off a row (sheet 75 rows 1 and 5 already say this).

## Private leaks

These are sides that would show a private fact (a private note's title or body, a money amount, body weight, a health word, a secret word) that the front of the same object hides. 2:41 says a side never does.

| # | Side | What would leak | Where (master) | Fix |
|---|---|---|---|---|
| PL1 | An exercise: YOUR SETUP, and its glance's "first setup word" | His free-text `notes` on the exercise. The exercise page never shows them (no `notes` read in `Features/Exercise/`; only the class page prints a prototype's notes at `ObjectPage.swift:81`). A line like "left knee sore, locker code 4471" holds a health word and a secret word. | `notes` field, `SystemCatalog.swift:57` | Screen each line of the notes with `SecretWords.mentions` (`Notes/SecretWords.swift:34`) and `PrivateFacts.isWalled` (`Tess/PrivateFacts.swift:17`). Show the lines that pass. Count the others ("1 line kept private") and never show them. Never use a walled line as the glance's big fact, and never let "Ask about this" carry it. |
| PL2 | Any other object: the default side ("every field the front doesn't show"), and its glance's "most-used field's value" | For a bespoke front that hides fields, the default side would print them: a private note's `body` (`SystemCatalog.swift:216`, `isPrivate` :220), a private memory's `rule` (:258, :264), a cook's `note` (:320). | `PropertyList` prints every field but `notes` (`ObjectPage.swift:348`) | The default side skips any object with `isPrivate == true` or the title `SecretWords.title` (it shows the count only). For every other object it drops any value that fails `SecretWords.mentions` or `PrivateFacts.isWalled`. A Core test runs every catalog field through it. |
| PL3 | A class page: ITS OBJECTS, and its glance's "the newest" and "the most used" | On the Note or Memory class, the newest object can be a private note or a private memory. The title reads "Private note", but the glance would name it and open it. | `ClassBody`, `ObjectPage.swift` | Private objects count but are never "the most used". The newest slot shows the private label, never the title (Product 2:45 amended 2:55 pm, over this pick). The glance says "38 objects", then "5 private" when any are. |
| PL4 | A note: WHERE IT'S MENTIONED, from the other side | Private notes never link from their words (`Notes/Notes.swift:111-119`; `EditNote` clears links when a note turns private, :165-166). But mention lookup resolves by title (`Notes.swift:41-43`), so "@Private note" in a plain note links to the oldest private note, and that plain note's own links (under its text) name and open it. | `NoteList.resolve`, `Notes.swift:41-43` | `resolve` skips objects with `isPrivate == true`. Then no side can reach a private note through a link. |

To watch (not leaks today):
- **W1. PER 100 G and kcal.** The food table is public, and Kitchen rules that nothing ever sums it (intake is a body fact). "kcal" is in the memory screen's body words (`Tess/TessMemory.swift:105-108`). Tess's side line on an ingredient must never carry a nutrition number, so the line can never trip that screen (see side-lines.md SL-I4).
- **W2. WHAT I READ.** Ignored lines are listed. A pasted line with a secret word is shown on the paste front (he typed it), so nothing is hidden. But the side should count such a line, not quote it, the way `PasteRecipe.swift:204-206` keeps it out of the miss log.
- **W3. WHAT LEAVES THE PHONE and BY JOB.** A `Tess Call` stores the job, the model, tokens, cost and outcome, but no phrase (`SystemCatalog.swift:225-233`). Dollars are the receipts' own Claude cost, already on the front (`ClaudeSection.swift:194`, :467). Nothing leaks. Keep it that way: no phrase field is ever added to a call.

## Open questions

- **Q1.** Do the 2:41 and 2:37 entries land in `decisions.md` on master as sheet 75 summarizes them? This file follows the sheet's summary.
- **Q2.** Is a page pushed over the live workout (M1) live under rule 7, so that its side is a peek? Or does it get its full side?
- **Q3.** Two taps down (the routine, an ingredient, receipts, backups) was outside the old rule's "one tap down". 2:24 makes it moot. Confirm that no depth limit is left.
- **Q4.** Should Review's side (S2) take the swipe until 46 is built?
