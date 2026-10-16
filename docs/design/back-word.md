# The back word (build sheet)

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

Just enough to build. Replaces every system back button and the "Close" word on Home's covers. Recording: `recordings/back-word.mp4` (source `studies/back-word.html`): Push Day A, then Bench press, then Tuesday; back once by tapping the word, then once by the edge swipe. Core's "‹ REVIEW" on Backups (#123, #126) is the first instance; this sheet makes it the rule.

## The rule
**The title you leave becomes the way back.** Every page you drill into (z) carries one back word at the top, naming the page you came from as it reads on screen (item 24 table below). Home's pages are siblings on x and never get one; the rail is their way around. Tess's double tap still goes Home from anywhere.

## The word
- **Where:** y 58, x 22, in the space system back buttons used. It is the first thing on the page; a page's own path or label line moves under it or goes.
- **Type:** Label 16/700 uppercase, letter-spacing 0.08em, `inkSecondary`; cream at 60% on the dark workout ground. "‹ " leads it, set in the same style (U+2039, not an SF Symbol chevron).
- **Text:** the name of the page you came from, not its hero sentence: "‹ PUSH DAY A", "‹ BENCH PRESS", "‹ RECIPES". Covers opened from Home name the Home page they rose from: "‹ TODAY", "‹ REVIEW", "‹ TRAINING" or "‹ KITCHEN", as the tabs read (`day-seams.md` S3). Nothing on screen is called Home. Truncate at the tail past about 22 characters.
- **Touch:** ink goes to 100%, a 1.5pt hairline draws under it left to right (150ms, house curve), and `.selection` fires. The hit target is at least 44pt tall and 12pt wider than the text each side. No shape, ever.
- **Accessibility:** a button labelled "Back to Push Day A". `.accessibilityAction(.escape)` pops, so the two-finger scrub works.

## Motion (the living moment)
**Going in.** The new page grows out of the tapped row: it's revealed from the row's band outward (clip from the row's rect to full, 460ms, house curve) and rises from a quarter of the distance at scale 0.96. Meanwhile:
- The parent's hero flies up into the new back word. A text copy travels from the hero's frame (56/500) to the back word's text frame (16/700) along the house curve over 440ms. It's fully ink until 55% of the way, then fades as the real back word fades in from 50%, shifted 6pt right.
- The parent's own back word slides 16pt left and fades out (220ms).
- The parent recedes: scale 0.94, blur 2, fades out.

**Going back by the word.** The reverse: the back word grows back into the parent's hero (440ms; the copy is visible from 40%), the page closes back into its row band (420ms), and the parent comes forward from scale 0.94 and blur 2. The parent's back word returns from 16pt left, 160ms in.

**Going back by the edge swipe.** It's interactive and keeps working through `EdgeSwipeBack` (the K1 fix).
- The page follows the finger.
- The parent comes forward with it, from scale 0.94, blur 2 and opacity 0 to scale 0.97, blur 1 and opacity 0.6 at the release point.
- The back word swells toward its hero, up to 1.25 at the release point.
- Past 35% of the width, or on a flick, the page slides off to the right (280ms) and the word finishes its flight into the hero. Short of that, everything springs back on the settle spring.

**Reduce Motion:** no flight and no reveal. Pages crossfade (200ms), and the back word crossfades with them.

## Build notes
- Make one shared view, `BackWord(title:action:)`, in `DesignSystem/` (Builder A), so every screen uses the same view.
- **The pusher names the way back.** The page that pushes passes its own short name along with the route; the pushed page reads it for its back word. A page reached some other way (a link from Tess, a widget) says "‹ TODAY".
- Hide the system back button on every pushed page (`.navigationBarBackButtonHidden()`, toolbar hidden) and keep `EdgeSwipeBack` in the background, as Backups does.
- **The flight crosses two pages,** so the zoom transition can't carry it on its own. Run it in an overlay above the `NavigationStack`: read the hero's frame through an anchor preference before the push, animate a `Text` copy from that frame to the back word's frame, then show the real back word. If that isn't ready in the first pass, ship the word fading in from 6pt right while the hero fades, and do the flight next. The word itself must not wait for the flight.
- Motion goes through `MotionPolicy` only.

## Where it applies: every screen (item 24, `day-seams.md` S3)
**The word names the page you go back to, as its door or tab reads on screen.** Home's tab pages read TODAY, REVIEW, TRAINING and KITCHEN. A cover or page opened from a word reads that word ("The week" gives ‹ THE WEEK, "Day log" gives ‹ DAY LOG). An object reads its own title. Nothing says HOME, because nothing on screen is called Home. A page reached from outside (a Tess link, a widget, Spotlight, a notification) reads ‹ TODAY, and the word takes it there.

The pusher passes its short name with the route, and the pushed page shows it. One shared `BackWord(title:action:)` in `DesignSystem/` (Builder A) draws them all. Status: **built** means the screen exists on master and needs the word; **planned** means apply the word when the screen is built.

| # | Screen | Reached from | Back word | Where in code | Status | Owner |
|---|---|---|---|---|---|---|
| 1 | The shared view | | `BackWord(title:action:)`: Label 16/700 `inkSecondary`, "‹ " lead, tail-truncated past 22 characters | new, `DesignSystem/` | built (to add) | Builder A |
| 2 | Any object page (task, routine, workout, plan, recipe object) | Now or the queue on Today | ‹ TODAY | `NowPage.swift:104, :439`, `HomeQueue.swift:260` push into `App/RootView.swift:21` | built | Builder B (stack), Core (`ObjectPage.swift:300-322`) |
| 3 | Plan, routine, workout and past-workout pages | Training | ‹ TRAINING | `TrainingPage.swift:53, :68, :152, :167, :231` | built | Builder A (pages), Builder B (stack) |
| 4 | A class page (Exercise, Bench press as a class) | An object's class line | The object's title ("‹ BENCH PRESS") | `ObjectPage.swift:70, :222` | built | Core |
| 5 | The object's class path ("… / Exercise / Bench") | | Moves into the class line under the hero. The top line is only the back word | `ObjectPage.swift:308-321` | built | Core |
| 6 | Exercise page | A live workout's exercise name | The workout's name as its strip reads it ("‹ PUSH A"), in `inkSecondary` on the look's ground (one base) | `WorkoutModeView.swift:22`, `WorkoutParts.swift:48` | built | Builder A |
| 7 | Exercise page | Training, or a routine or plan page | The pusher's title ("‹ TRAINING", "‹ PUSH DAY A") | root stack | built | Builder A |
| 8 | A past workout | An exercise page's history | ‹ BENCH PRESS (the exercise) | `ExerciseViews.swift:117` | built | Builder A |
| 9 | A workout day | The plan's Week or Month | The plan's name ("‹ PPL × 2") | `WeekPage.swift:108`, `MonthPage.swift:132` | built | Builder A |
| 10 | Groceries | Kitchen | ‹ KITCHEN, replacing "Close" | `HomeSpatialView.swift:141-148` | built | Builder B |
| 11 | Recipes | Kitchen | ‹ KITCHEN, replacing "Close" | `HomeSpatialView.swift:141-148`, `RecipesEntry.swift` | built | Builder B |
| 12 | Paste a recipe | Kitchen | ‹ KITCHEN, replacing "Close" | `HomeSpatialView.swift:141-148`, `RecipesEntry.swift:30-40` | built | Builder B |
| 13 | Notes | Review's link line | ‹ REVIEW, replacing "Close" | `HomeSpatialView.swift:164` | built | Builder B |
| 14 | The week (the full Review) | Review's link line | ‹ REVIEW, replacing "Close" | `HomeSpatialView.swift:164`, `ReviewView.swift` | built | Builder B |
| 15 | A recipe | Recipes, or a saved paste | ‹ RECIPES | `RecipePage.swift:56, :138`, `RecipesEntry.swift:36` | built | Core |
| 16 | An ingredient | A recipe's line, or a held grocery item | The recipe's name ("‹ DAL TADKA"), or ‹ GROCERIES | `RecipePage.swift:255`, `GroceriesView.swift` | built | Core |
| 17 | A note | Notes | ‹ NOTES | `NotesView.swift:15-16` | built | Core |
| 18 | Backups | The week's foot, until Settings lands | ‹ THE WEEK (it reads "‹ Review" today) | `BackupView.swift:31-40` | built | Core |
| 19 | Receipts | The week's Claude lines, until Settings lands | ‹ THE WEEK | `ClaudeSection.swift:209` | built | Builder B |
| 20 | Settings | SETTINGS at Review's foot | ‹ REVIEW | `settings-place.md` | planned | Builder B |
| 21 | Receipts | $1.20 or RECEIPTS in Settings | ‹ SETTINGS | `settings-place.md` | planned | Builder B |
| 22 | Day log | Today's day label, or Review's link line | ‹ TODAY or ‹ REVIEW, by the way in | `day-log-v1.md` | planned | Builder B |
| 23 | An object opened from a Day log line | The Day log | ‹ DAY LOG (was ‹ DAYS) | `day-log-v1.md` DL34 | planned | Builder B |
| 24 | Habits | The Habits word on Today's foot line | ‹ TODAY | `body-weight-and-habits.md` | planned | Builder B |
| 25 | Body weight | The weigh-in on Now, or Review's weight line | ‹ TODAY or ‹ REVIEW, by the way in | `body-weight-and-habits.md` | planned | Builder B |
| 26 | Money, Reading, Upkeep, People | Review's second link line | ‹ REVIEW | `money-reading-first.md`, `upkeep-people-first.md` | planned | Builder A (Money, Reading), Builder B (Upkeep, People) |
| 27 | A spend, a book, a chore, a person | Their area page | The area's title ("‹ MONEY", "‹ READING", "‹ UPKEEP", "‹ PEOPLE") | those sheets | planned | as row 26 |
| 28 | Lists | Kitchen | ‹ KITCHEN | `kitchen/lists-9-12.md` | planned | Builder B |
| 29 | Any page opened from outside | A Tess link, a widget, Spotlight, a notification | ‹ TODAY | `App/RootView.swift` | built (to add) | Builder B |

**No back word:** Home's four tab pages (siblings on x; the tabs are their way around), the live workout and cook mode (running processes that leave by their own gesture, `WorkoutParts.swift:338` keeps its Close until that's drawn), Plan my day (a layer on Now), and Tess's capture.

## Not in this sheet
- **A history of where you've been** (hold the back word to list the last few pages): only if pages go deeper than three in real use.
- **Workout mode itself** is a running process, not a z page. It keeps its strip and leaves by its own gesture.
