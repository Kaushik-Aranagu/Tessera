# Screen fast paths: one action per screen, two ways around it

For: Builder A, Builder B, Design, Product
Date: 2026-10-15 · Research lab
Reads with: "The screen is the resource" in `docs/design/no-buttons.md` (not on master yet: it is on branch `claude/project-thread-b3tu3f`, `fb77a8e`), `product/spatial-interaction.md` section 0, and `research/tess-discoverability.md`. Code: origin/master `8863357`.

**In one line.** Every screen on master already has one clear thing he does most, but most screens still carry a second key, a bar or a lasting instruction line, and the soul does the wrong job (a single tap goes home instead of opening Tess).

## How to read the table

- **Primary**: the one stroke word. **Fast paths**: at most two, chosen from gestures, ink words, y or z swipes, the Action button and App Intents.
- **Capture first**: what the opened Tess shows on that screen: her question, then the placeholder phrase. Every phrase parses on master (`TessGrammar.Parse` or the question path in `CommandInterpreter`).
- **Remove or demote**: file:line on master. "Keep holding" is always removed, because the word never changes during a hold (no-buttons.md, stroke word).

## Screens on master

| Screen (file) | Primary | Fast paths (max 2) | Capture first: question · placeholder | Remove or demote today |
|---|---|---|---|---|
| Root shell (`App/RootView.swift`) | None of its own; it hosts the soul | Double tap the soul goes to Today; edge swipe goes back up z | n/a | Single tap on the soul goes home (`RootView.swift:62` `goHome`, wired at `BottomChrome.swift:65`). Make it a double tap and give the single tap to Tess |
| Tess capture (`Features/Command/BottomChrome.swift`) | Say or write one phrase | Hold the soul to Speak; Return commits through the ghost | Comes from the screen below | Glass bar `:15`, `:26`; glass panel `:21`; outlined chips `:144-163` (a tap writes at once); the ✕ header row `:116` (closing becomes tap the page or swipe down); fixed placeholder `:123`; idle text "Ask Tess, or log a set" `:82` |
| Home pager (`Features/Home/HomeSpatialView.swift`) | Page between Review, Today and Training | Swipe x; tap a rail word | n/a | Rail underline is a rounded shape `:153` (fine as paint under 3pt radius). `dockClearance = 104` `:41` reserves room for a bar that is going away; drop to soul height |
| Today (`Features/Home/NowPage.swift`, `DayStrip.swift`) | Finish the current thing (hold), or Start or Resume when that is the hero | Hold the soul to Speak; swipe x to Training | "What's next?" · `dentist thu 3pm` in the morning, `milk, eggs, 2 lemons` 17:00 to 21:00, else `bench 80x8, or ask` | "Keep holding" `:93`; key shapes at `:92`, `:437`, `:471` become stroke words. The top `RunningSeam` (`RootView.swift:41-48`) shows while the Running hero already says the same thing |
| Review page (`Features/Home/ReviewPage.swift`) | Read the week (no write) | Swipe x back to Today; tap Tess's line to ask about it | "How was the week?" · `bench best?` | Nothing extra on screen. Day dabs are not tappable; leave that for later |
| Training (`Features/Home/TrainingPage.swift`) | Start workout (Resume when running) | Tap the hero to open the workout (z); "Plan →" (z) | "Which one today?" · `bench 80x8, or ask`; fast paths **Start Push Day A** · **Plan** | Keys `:85`, `:184` become stroke words. "Plan →" appears twice (`:45`, `:144`), one per state, fine. "Browse exercises →" `:367` stays (empty state only) |
| Object page (`Features/Objects/ObjectPage.swift`) | Read; tap a row to go deeper | Tap the path handle to go up z; edge swipe back | "Ask about it" · `note: …` (or `bench best?` on an exercise class) | `.padding(.bottom, 180)` `:46` is bar room; shrink with the soul |
| Exercise (`Features/Exercise/ExercisePage.swift`) | Log a set | Swipe x through History, Rep maxes, Muscles; tap a muscle to go up z (`:86`) | "Tell me a set" · `bench press 80x8` (prefilled name) | "Add to routine" menu `:222` sits beside the key as a second action: move it one layer down (open from the name, or Tess `add … to …` when it parses) |
| Plans: Week and Month (`Features/Plans/PlansView.swift`, `WeekPage.swift`, `MonthPage.swift`) | Tap today's dab to train (`WeekPage.swift:66`) | Swipe x Week to Month; tap a done dab to open that workout | "Ask about the plan" · `bench best?` | Rounded range bar `WeekPage.swift:195` becomes a brush band |
| Routine editor (`Features/Plans/RoutineEditor.swift`) | Change a slot (tap to unfold in place) | Edge swipe back; "Add an exercise →" `:53` | "What should change?" · no edit phrase parses yet, so offer `note: …` | Instruction line "Tap one to change it." `:106` goes to the hint ledger after 3 views. Undo `:124` only after a change (already right) |
| Live workout (`Features/Workout/WorkoutModeView.swift` and parts) | Log set (hold) | Hold the soul to Speak a set; Action button runs **Log a Set** (`App/AppIntentsPackageLink.swift`) | "Tell me a set" · `same, 8, or 80x8`; in rest `drop to 70 for 10` | "Keep holding" `:547`, `:578`; keys `:544-575` become stroke words; Tess glass bar `WorkoutParts.swift:252`, `:287`; ask sheet `WorkoutModeView.swift:120` with outlined field `WorkoutParts.swift:374`, `:392` (the soul's Write replaces it); weight alert `WeightDial.swift:133`; standing instruction "Tap or drag the dial right…" `WorkoutModeView.swift:400` to the hint ledger |
| Exercise strip and swap (`ExerciseStrip.swift`, `SwapPanel.swift`) | Reorder today (strip) or pick a swap | Pull down on the header; pull down on the name | Same as live workout | Glass `ExerciseStrip.swift:122`, lifted row fill `:169`, "Keep holding" `:111`, lasting hint `:103`; glass card `SwapPanel.swift:51`, picked-row fill `:89` |
| Workout finish (`Features/Workout/WorkoutFinishView.swift`) | Back to today | Swipe down (`:88`, already there) | "Anything to note?" · `note: bar felt heavy` | Second Tess glass bar on this screen (`WorkoutModeView.swift:85`); key `:78` becomes a cobalt stroke word |
| Notes list (`Features/Notes/NotesView.swift`) | Write a note | Tap a row to open it (z); Tess `note: …` from anywhere | "What's on your mind?" · `note: bar felt heavy` | Inline writing line `:74`, `:131` breaks "nothing is typed inline on the page" (spatial §0): move it into the soul's Write here |
| Note editor (`Features/Notes/NoteEditor.swift`) | Type | Edge swipe back (saves); return moves to the body | Soul stays closed while the keyboard is up | "Delete note" `:79` always on the page: move to one layer down (hold the row in the list) |
| Review screen (`Features/Review/ReviewView.swift`) | Read the week | Edge swipe back | As Review page | A second review next to `ReviewPage`, reachable only by `-review` (`App/TesseraApp.swift:50`). Pick one; make the other its z layer |
| Groceries (`Features/Groceries/GroceriesView.swift`) | Strike an item (tap); at the shop, Done shopping (hold) | Hold the title to start the shop (`:188`); Tess `shop` | "What do we need?" · `milk, eggs, 2 lemons`; at the shop `buy oat milk` | "Keep holding" `:92`; inline writing line `:62`, `:208` moves into the soul's Write |
| Recipe (`Features/Recipes/RecipePage.swift`, `RecipesEntry.swift`) | Cook | Swipe the ingredients left to send them to Groceries (`:74`); turn the portion drum | "Cook it when?" · `cook carbonara thu`, then `timer pasta 10` | "Recipes" text back word `:34`: edge swipe already does it |
| Paste recipe (`Features/Recipes/PasteRecipe.swift`) | Save recipe | Tap a line to cycle its reading | "Paste a recipe" · pasted text with an Ingredients heading (`.recipe`) | "Edit" `:237` beside Save: show it only after a misread is tapped |
| Soul gallery (`Features/Tess/SoulGallery.swift`) | DEBUG only | n/a | n/a | Leave as is |

## Notes

- Three screens offer a key and a second action side by side: Exercise (`Add to routine`), Paste recipe (`Edit`), Note editor (`Delete note`). Each second action has a natural layer one tap down.
- Lasting instruction lines (`RoutineEditor.swift:106`, `ExerciseStrip.swift:103`, `WorkoutModeView.swift:400`) should go through the same ledger as Tess hints (`TessHintLedger`, discoverability §5): shown 3 times, then gone.
- Routine editor is the one screen with no phrase that parses for its main job. Product should decide whether `add dips to Push A` is worth a grammar case.
- Notes, Groceries, Recipes and the Review screen are separate roots behind DEBUG flags (`App/TesseraApp.swift:46-56`). In a release build he cannot reach them, and the soul is not there. That is the biggest fast-path gap on master.
- Four pages reserve room for the old bar: `HomeSpatialView.swift:41` sets 104pt, `PlansView.swift:83` and `ExercisePage.swift:66` reuse it, and `ObjectPage.swift:46` pads 180pt. With only the soul at rest, about 60pt is enough, and each page gets the rest back.
- Placeholders and fast paths **fill the field and never submit**. Today a chip tap writes at once (`BottomChrome.swift:146-148`), so "log bench 82.5x8" can log a set he did not do.
- Fast paths come from the shared context ranker (`context-packing.md`), not a fixed list per screen. The table gives the default when the ranker has nothing better.
- Show at most one hint line with the placeholder, and retire it as discoverability §4 says (2 uses, or 3 days ignored).
- Hold actions keep their durations: 0.6s log, 0.7s finish, 0.8s workout finish. Only the label and the shape change.

## Across the app

### Home (Today), from anywhere
- **Master today:** a single tap on the soul floods paint and goes home; tapping again on Home returns to where he was (`RootView.swift:62-84`). Opening Tess needs a second target, the bar text (`BottomChrome.swift:78`).
- **Change:** keep the flood and the return trip, but on a **double tap**. The single tap opens Tess. Owner: Builder B.
- **In live workout** the soul sits in `WorkoutTessBar` (`WorkoutParts.swift:241`). A double tap there should minimise the cover (`isWorkoutPresented = false`) and land on Today. Then the chevron (`WorkoutModeView.swift:323`) can go. Owner: Builder A.
- **Kitchen and Notes:** Notes, Groceries and Recipes must become routes in the root `NavigationStack`, so the soul and the double tap exist there too. Until then they have no way home. Owners: Core for the screens, Builder B for the routes.
- **Fast path in:** from Tess, a reply that names a place ("Oat milk and eggs, on **Groceries**.") makes the place a value word you can tap.

### Back
- One gesture: the system edge swipe up the z stack (root stack at `RootView.swift:17`, the workout's own stack at `WorkoutModeView.swift:21`). Zoom pages already shrink back into the row they came from.
- No text back words. Remove "Recipes" (`RecipePage.swift:34`).
- Process screens go back by swiping down. The finish view already does (`WorkoutFinishView.swift:88`); live workout keeps its chevron until the soul double tap ships.

### Now (the running process)
- **Master has six ways back into a live workout:** the top seam (`RootView.swift:41`), the Running hero (`NowPage.swift:471`), Training's Resume (`TrainingPage.swift:85`), a ledger row (`NowPage.swift:521`), today's week dab (`WeekPage.swift:66`) and the Live Activity (`Widgets/RestLiveActivity.swift:79`).
- **Keep one cross-app path:** the lit top seam, tap it or pull down from it at any depth. Outside the app it is the Live Activity, whose +15 and Skip already use intents (`RestLiveActivity.swift:299-310`).
- **Hide the seam on Today** while the Running hero shows the same workout. Owner: Builder B.
- **Action button:** suggest **Tell Tess** as his default, because it takes sets, tasks and groceries by context. Before recommending it over **Log a Set**, check that `TellTessIntent` puts a bare `8` into the entry in focus. Shortcuts on master: Tell Tess, Log a Set, Undo Last Set, Start Workout, Finish Workout, Add Task (`App/AppIntentsPackageLink.swift`).

## Open questions for Product

- **Exercise page:** is "Log a set" really what he does most there, or does he mostly read the best set and trend? If reading wins, the stroke word can go and Tess's prefilled `bench press 80x8` is the logging path.
- **Cook mode:** "Cook" starts `StartCooking` (`RecipesEntry.swift:17`), but master has no cook-mode screen, so the primary action of the recipe page leads to no Now. The seam rule above should cover cooking once that screen exists.
- **Review:** keep `ReviewPage` on Home as the summary and make `ReviewView` its z layer (tap the headline), or retire one.

## The 5 cheapest changes, ranked

1. **Soul: single tap opens Tess, double tap goes to Today** (`BottomChrome.swift:65`, `:78`; `RootView.swift:62`). A gesture swap on code that exists. Owner: **Builder B**.
2. **Chips out, context placeholder in**: replace the three fixed chips (`BottomChrome.swift:144-163`) and the fixed placeholder (`:123`) with the screen's question, its placeholder phrase from the table, and at most two fast paths that fill, never submit. Owner: **Builder B** (phrase table from Core).
3. **Workout holds and lasting hints**: drop "Keep holding" (`WorkoutModeView.swift:547`, `:578`, `ExerciseStrip.swift:111`) and route the standing lines (`WorkoutModeView.swift:400`, `ExerciseStrip.swift:103`, `RoutineEditor.swift:106`) through a 3-view limit. Owner: **Builder A**.
4. **Shapes that are not paint**: the range bar (`WeekPage.swift:195`), the lifted row (`ExerciseStrip.swift:169`) and the picked row (`SwapPanel.swift:89`) lose their rounded fills. Owner: **Builder A**.
5. **Kitchen extras**: "Keep holding" on Done shopping (`GroceriesView.swift:92`), the "Recipes" back word (`RecipePage.swift:34`) and "Edit" beside Save (`PasteRecipe.swift:237`, show only after a tap on a line). Owner: **Core**.
