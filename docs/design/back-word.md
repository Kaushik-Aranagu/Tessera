# The back word (build sheet)

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

Just enough to build. Replaces every system back button and the "Close" word on Home's covers. Recording: `recordings/back-word.mp4` (source `studies/back-word.html`): Push Day A, then Bench press, then Tuesday; back once by tapping the word, then once by the edge swipe. Core's "‹ REVIEW" on Backups (#123, #126) is the first instance; this sheet makes it the rule.

## The rule
**The title you leave becomes the way back.** Every page you drill into (z) carries one back word at the top, naming the page you came from. Home's pages are siblings on x and never get one; the rail is their way around. Tess's double tap still goes Home from anywhere.

## The word
- **Where:** y 58, x 22, in the space system back buttons used. It is the first thing on the page; a page's own path or label line moves under it or goes.
- **Type:** Label 16/700 uppercase, letter-spacing 0.08em, `inkSecondary`; cream at 60% on the dark workout ground. "‹ " leads it, set in the same style (U+2039, not an SF Symbol chevron).
- **Text:** the name of the page you came from, not its hero sentence: "‹ PUSH DAY A", "‹ BENCH PRESS", "‹ RECIPES". Covers opened from Home say "‹ HOME". Truncate at the tail past about 22 characters.
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
- **The pusher names the way back.** The page that pushes passes its own short name along with the route; the pushed page reads it for its back word. A page reached some other way (a link from Tess, a widget) says "‹ HOME".
- Hide the system back button on every pushed page (`.navigationBarBackButtonHidden()`, toolbar hidden) and keep `EdgeSwipeBack` in the background, as Backups does.
- **The flight crosses two pages,** so the zoom transition can't carry it on its own. Run it in an overlay above the `NavigationStack`: read the hero's frame through an anchor preference before the push, animate a `Text` copy from that frame to the back word's frame, then show the real back word. If that isn't ready in the first pass, ship the word fading in from 6pt right while the hero fades, and do the flight next. The word itself must not wait for the flight.
- Motion goes through `MotionPolicy` only.

## Where it applies
| Screen | Back word | File | Owner |
|---|---|---|---|
| Object pages on the root stack (classes, exercises, routines, any object) | The pusher's name; "‹ HOME" from Home's pages | `App/RootView.swift:17-30`, `Features/Objects/ObjectPage.swift:300-322` | Builder B (root stack), Core (ObjectPage) |
| The object page's class path ("… / Exercise / Bench") | Moves into the class line under the hero, where the parent class stays a tappable handle (`relation: .up`). The top line is only the way back | `Features/Objects/ObjectPage.swift:308-321` | Core |
| Home covers: Groceries, Recipes, Paste a recipe, Notes, The week | "‹ HOME" at top left, replacing "Close" at top right. Swipe down from the top still dismisses into the word that opened it | `Features/Home/HomeSpatialView.swift:106-116` | Builder B |
| Backups | "‹ REVIEW" (already there); switch to `BackWord` | `Features/Backup/BackupView.swift:31-40` | Core |
| Recipe page | "‹ RECIPES" (sheet 10's path line becomes the back word) | `Features/Recipes/RecipePage.swift` | Core |
| Ingredient page | "‹ DAL TADKA", or "‹ GROCERIES" when reached from a held item | `Features/Recipes/RecipePage.swift:246`, `Features/Groceries/GroceriesView.swift` | Core |
| A note | "‹ NOTES" | `Features/Notes/NotesView.swift:14-18` | Core |
| Exercise page from a workout | "‹ WORKOUT", cream at 60% on the dark ground | `Features/Workout/WorkoutModeView.swift:18-21` | Builder A |
| Exercise, routine and plan pages pushed from Training | "‹ TRAINING", then each pusher's name deeper in | Through the root stack | Builder A (pages), Builder B (stack) |

## Not in this sheet
- **A history of where you've been** (hold the back word to list the last few pages): only if pages go deeper than three in real use.
- **Workout mode itself** is a running process, not a z page. It keeps its strip and leaves by its own gesture.
