# Builder B handoff: Kitchen landing, Pantry, Recipes wheel (231-233)

Boards: landing https://claude.ai/artifact/P8MtexZsp5T39K6X5PSZnr, Pantry https://claude.ai/artifact/PnzKN8FtQ2MrLqyTBYsTcM, Recipes https://claude.ai/artifact/VFPghmqdCM8mJrA1c2zY1T. Sheets 231, 232, 233 in this folder win on any doubt.

## Part 1: shared pieces, no new data
Files: Features/Landing/KitchenLanding.swift, Features/Kitchen/PantryView.swift, Features/Recipes/RecipesShelfView.swift + RecipePage.swift, Features/Kitchen/Cook/. Build these shared pieces first, in Features/Kitchen/KitchenParts.swift:
- Colors (AppAccents): kitchen A8701F light / C49A5E dark for names and big numbers. Small Kitchen words (Cook now, Undo, low, Get it) use kitchenText 93611A light (4.9:1) / C49A5E dark.
- PlaceDial (used by Pantry and Recipes). It has three 64 pt slots in a 196 pt headline. The focus is 44 pt Figtree 600 in kitchen with its count in Outfit 200 ink. Neighbours are 26 pt, weight 400, ink2, with counts in Outfit 300. It loops. Drag tracks 1:1 and snaps on a spring; a flick moves exactly one place; a tap on a neighbour centres it. One light haptic per place. VoiceOver: adjustable, "Fridge, 8 things". At AX3+ show the focus plus one neighbour, and the slot grows one line.
- FocusWheel (the 230 wheel). Rows 38 pt. The focus sits in the FIRST slot, and the list loops: scrolling moves the next item up into focus and the old one goes round to the back. Drag tracks 1:1, a flick moves one row, it snaps on a spring, one tick per row. Tap a non-focused row to bring it to the top; tap the focused row to open it. No spring-back. The height always ends on a row boundary (202 pt in a band, 392 pt full page). Every row is ink2 or darker; size and weight carry distance.
- ReceiptLine: one fixed 26 pt line above the foot, 15 pt ink2. Pattern "Thing, what happened. Undo" with Undo in kitchenText 600. 10 s; the newest replaces the line. Clip-in from the top, 0.3 s.
- Foot: one action word bottom-left (19 pt 600 kitchen), Tess bottom-right. Left edge goes back; a title tap opens the room index (224).
- Reduce Motion lands everything in one step. No cards, bars, dots, fades or food drawings.

## Part 2: Kitchen landing (231)
Not cooking:
- Top row: "Kitchen", day word.
- Headline: "Tonight you could make", then the dish in a 46 pt reel in kitchen, clipped to a 52 pt slot. Then "25 min, you have all 8 things" and "another". "another", or a swipe up on the name, rolls to the next makeable dish, and its line wipes in after. A tap on the name opens the recipe page.
- Brief (on-phone template): "Eggs and milk run out first. Spinach wants using by Sunday."
- Pantry band: three Outfit 200 44 pt numbers with fixed labels "on hand", "low" (kitchen) and "to get". They count up on arrival; VoiceOver reads the final values. A tap opens Pantry.
- Recipes lines: "You can make 4 now" opens Recipes on Ready now; "Pasta on Thursday"; "Dal, last made Tuesday".
- Foot "Cook" opens the Recipes wheel on Ready now.

Cooking (Cook now on any recipe; the view rises from the bottom):
- Top row "Cooking" in kitchenText.
- Dish name (opens the recipe), "Step 2 of 6", step title 26 pt in a 58 pt two-line slot, bottom-aligned.
- Step timer 72 pt Outfit 200 with one word ("garlic"). With no step timer it shows the soonest running timer; with none, the step note.
- Brief: "Then: zest the lemons." Last step: "Last step. Enjoy it."
- Timers as plain lines, soonest first, max 3. A finished timer reads "Garlic is ready" in kitchenText, and the big number goes kitchen "0:00 ready". Local notification plus Live Activity; sound follows the silent switch.
- Below in ink3: "Pantry 24 on hand, 3 low", "Pasta on Thursday".
- Foot "Next step", then "Done cooking", then landing receipt "Lemon pasta, cooked. Pantry took 6 things. Undo".
- Private recipe: shownLabel in the reel, rows, notification and Live Activity ("Your dish", "Timer done").

## Part 3: Pantry (232)
- Top row: "Pantry"; right "5 to get", which jumps the dial to To get and rolls its number.
- Headline: PlaceDial over To get, Fridge, Freezer, Shelf, Counter.
- Brief: two template lines, e.g. "Low on milk and eggs." / "Spinach wants using by Sunday." Freezer: "All good in here."
- Section line 13 pt ink2: "2 low, 1 to use soon"; right "1 of 2".
- Body: five 44 pt rows per page in a fixed 220 pt slot. Name 17 pt ink. Right side 15 pt: amount ("half", "1 bunch"), "low" in kitchenText 600, or "by Sunday". Pinned rows first, name 600, "pinned, ".
- Pages turn vertically, one per gesture, on a spring. A drag belongs to the region it starts in.
- Swipe right 90 pt = used up. The row slides off and collapses, its name arcs up to "to get", and the number rolls. Receipt "Milk, used up. On To get. Undo". On To get, swipe right = got it: "Feta, got it. Back in the fridge."
- Swipe left = not now: "Spinach, not now. Asks again tomorrow."
- Tap = in/low toggle: "Eggs, running low. Undo". Does nothing on To get.
- Hold 0.5 s = pin, max 3 ("Three pins already. Unpin one first."). Any 3 pt move cancels the hold.
- Foot "Add a thing": "Say it or type it. Tess puts it in the right place." Receipt "Basil, added to the fridge. Undo".
- Private items: the real name in the room only, never in the brief, counts text, notices, widgets, Siri or backups.

## Part 4: Recipes (233 v5) and accept checks
- Top row: "Recipes", right "5 to get".
- PlaceDial lenses: Ready now, One short, Planned, All, with counts.
- Brief: "Fried rice is the quickest, 20 min. Lemon pasta uses the lemons."
- Section line right-aligned: "7 you can make now, quickest first".
- FocusWheel quickest first, pins first, "New recipe" (kitchenText) in the loop.
  - The focused row is 28 pt 600 ink, with two 15 pt ink2 one-line detail slots that clip in. Line 1: "5 min, about 350 cal a serving". Line 2: "lemons, spaghetti and 4 more", with use-first items in kitchenText 600; or "needs feta"; or "milk low".
  - Other rows are the name plus a right column "20 min", where "min" is 0.62 of the number's size. 17 pt next to the focus, then 15 pt.
- A tap on the focused lens = full-page list (wheel 392 pt); back by the left edge only.
- The foot follows the focus: "Cook now", "Get it", "Get 2 things" (receipt "Feta and mascarpone, on To get. Undo") or "New recipe" ("Tell Tess, type it, or paste a link."). A link is fetched and parsed on the phone.
- Recipe page: name, "25 min, serves 2, about 520 cal each", up to five ingredient lines (else four plus "and 3 more"), missing items "to get"/"low" in kitchenText.
  - Fixed line "Keep at the top": Pinned/No, "Overnight oats, pinned. Undo".
  - Fixed line "Plan for": a tap rolls No day, Monday to Sunday, "Shakshuka, planned for Monday. Undo".
- Calories are computed on the phone, shown in the Kitchen room only, behind Settings "Show calories" (On). Never in Home, widgets, notices, Live Activity, the cooking brief, Claude lines, logs or backups.

Accept checks:
1. Each dial flick moves exactly one place and loops.
2. The wheel never shows a cut row, and the focus is always the top slot.
3. A vertical drag in the body never moves the dial.
4. Every receipt matches the pattern and Undo restores state for 10 s.
5. Small Kitchen words measure 93611A 4.5:1 or better.
6. With Reduce Motion, nothing animates.
7. A private item's name never appears outside the room (check the notification, Live Activity and brief).
8. Calories are absent from every surface but the room.
9. AX3: dial plus one neighbour, wheel 3 rows, detail one line.
