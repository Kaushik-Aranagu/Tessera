# 233 Recipes page

Board: https://claude.ai/artifact/VFPghmqdCM8mJrA1c2zY1T (r48). It opens from the Kitchen landing's Recipes lines and from Cook (231). It uses the same grammar as the Pantry page (232): the 226 bands, a dial with 3 places, and 5 rows per page.

## Bands
- **Top row:** "Recipes" on the left and "5 to get" on the right. The count rolls when a thing goes onto To get.
- **Headline:** a dial of ways to look, which loops: Ready now (6), One short (3), Planned (2), All (10). The focus is 44 pt, weight 600, in the Kitchen colour, with its count in Outfit 200. The neighbours are 17 pt ink 2. Dragging tracks 1:1 and snaps on a spring. A flick moves one place, and tapping a neighbour centres it.
  - VoiceOver treats it as one adjustable element and reads, for example, "Ready now, 6 recipes".
- **Brief:** built on the phone from templates. It picks the most useful line.
  - Ready now: "Fried rice is the quickest, 20 min. Lemon pasta uses the lemons."
  - One short: "Feta makes Shakshuka work. Milk is low for pancakes."
  - Planned: "Pasta on Thursday. Tacos on Saturday, 3 things short."
- **Section line (ink 2):** "6 you can make now", "3 need one thing" or "This week". When there's more than one page, "1 of 2" shows on the right.
- **Rows:** 44 pt, five per page, turned vertically one page per gesture.
  - Each row has the name, then the minutes and what you have ("25 min, all 8" or "30 min, 6 of 7"), then a 72 pt action slot.
  - Planned rows show the day.
  - Action word: "Cook now" when you have everything, "Get feta" when one thing is short (it puts feta on To get), and "3 short" in ink 2 otherwise.
  - Action words use 93611A at weight 600.
- **Receipt line:** Undo for 10 s. Examples: "Cooking Lemon pasta. Undo" and "Feta, on To get. Undo".
- **Foot:** "New recipe". Its brief reads "Tell Tess, paste a link, or type it in." A pasted link is fetched and parsed on the phone (231 rule).

## Gestures
- **Cook now:** a hairline draws under the word, left to right, then cooking starts and the Kitchen landing becomes the cooking view (231).
- **Tap a name:** opens the recipe page (231), which slides in from the right. The left edge goes back. Its foot word follows the recipe: Cook now, Get feta, or Add to To get. Missing things show in 93611A as "to get" or "low".
- **Hold a name for 0.5 s:** pins it to the top, three at most, with "Lemon pasta, pinned. Undo". Any movement cancels the hold.
- **Regions:** a drag belongs to the region where it starts. A vertical drag in the headline moves the dial, and one in the body turns the page.
- Recipe rows have no horizontal swipes. Cook now and Get are the only row actions.

## Rules kept
- No cards, bars, dots or fades.
- Reduce Motion lands everything in one step.
- Names sit in a fixed one-line slot; Tess shortens past 18 characters.
- Private recipes show their real name in the room only (232 ruling), and never in the brief, notices, Live Activity or Siri.

## Reviewer fixes (Oct 23, 7:19 PM PT)
1. **Action slot:** three states, all 72 pt: "Cook now", "Get it" and "2 short". The row is two lines: the name at 17 pt, then an info line at 13 pt ink 2 that names the gap ("30 min, needs mascarpone", "20 min, all 6, eggs low", "25 min, all 8"). This keeps names whole. At AX sizes the slot may grow by one line.
2. **Cook now:** cooking starts on the tap. The 0.2 s underline draws once, as confirmation only. A private recipe uses shownLabel in the receipt, notification and Live Activity.
3. **Receipts with 10 s Undo:** "Mascarpone, on To get. Undo", "Lemon pasta, pinned. Undo", "Cooking Lemon pasta. Undo". The newest receipt replaces the line (232 rule).
4. **What you have:** the 161 level rule applies (coordinator ruling): an item that is in or low counts as have, and an out item doesn't. The info line says when something is low ("all 8, eggs low"), so a ready recipe never turns out to be one short.
5. **Planning (coordinator ruling):** happens on the recipe page. A fixed line "Plan for" is followed by the day in the Kitchen text shade. Each tap rolls to the next day (No day, then Monday to Sunday), with a receipt "Shakshuka, planned for Monday. Undo". This feeds Planned and the landing's "Pasta on Thursday". The foot stays one word.
6. **Private items and links:** private items follow 232. The New recipe brief reads "Tell Tess or type it in. A link is fetched from its site, read on the phone."
7. **Gestures:** the same region rule as 232. VoiceOver actions are Cook now, Get it and Pin, and the dial is an adjustable element.

## v3 (his 7:21 PM: "recipe lists can be better"): the timetable
- The list becomes a timetable. Minutes run down a 44 pt left column in Outfit 300 at 24 pt, quickest first. A repeated minute is left blank, the way a departures board does it. Pins still come first.
- Each row has two lines, its name (17 pt) and what goes in it (13 pt, ink 2, three things). Anything that wants using first comes first, in the Kitchen text shade at 600 ("**lemons**, spaghetti, butter"; "**spinach**" on Dal). A low thing reads "milk low". A recipe that's one thing short reads "needs **feta**".
- The section line reads "Cook in **30 min**, 5 fit". Tapping the time steps it through 15, 20, 30, 45 and any time. Recipes that won't fit drop to ink 2, name and minutes both.
- Rows no longer each carry an action word. Tapping a recipe opens it in place, from 44 to 80 pt on a spring, and its action line wipes in: "Cook now" (or "Get it" / "2 short"), then "Recipe" (opens the full page), then "serves 2". Only one row is open at a time, and tapping it again closes it.
- Hold still pins it (three at most, Undo). Pages still turn vertically.
- Brief for Ready now: "Dal uses up the spinach. Oats take 5 min."

## v4 (his 7:25 PM: "use one which fits well here", "a little too cluttered"): the 230 wheel, my pick
The board shows both views, Wheel (pick) and Timetable (v3, with the reviewer's v3 fixes). They're switched by the words above the board.
- The body is the 230 session wheel. Recipes run quickest first, with pins on top. The focused recipe is the only one with detail. Its name is 28 pt 600 ink, and under it a 15 pt ink 2 line wipes in: "25 min, **lemons**, spaghetti, butter" (use-first items in 93611A 600; "needs **feta**"; "milk low"). Its minute leaves the right column.
- Every other recipe is a name and its minute: 17 pt ink 2 next to the focus, then 15 pt. Size and weight carry the distance, and every row stays ink 2 or darker (230 ruling).
- Gestures follow 220 and 230. Hold and scroll tracks 1:1, a flick moves exactly one row, and the wheel snaps on a spring with one tick per row. Tapping another row centres it. Tapping the focused name opens the recipe page.
- The foot's one action word follows the focused recipe: "Cook now", "Get it", or "2 short" (inactive). The last row of the wheel is "New recipe" in the Kitchen text shade. When it is focused, its line reads "Tell Tess, type it, or paste a link." and the foot reads "New recipe".
- The section line reads "7 you can make now, quickest first". The dial and brief are unchanged. Receipts and Undo stay as in v2. VoiceOver reads the wheel as a list and offers the actions Cook now, Open recipe and Pin.

### v3 reviewer fixes (kept for the Timetable view)
The body stays fixed at 220 pt, and the rows below an open row slide under the clip. Turning the page closes the open row. A recipe that doesn't fit the time has its minute left blank as a second signal. The open row's only action word is "Cook now"; "Recipe" was dropped, and holding "serves 2" steps it with the 222 drum. A tap on a closed row opens it, a tap on the name in an open row opens the recipe page, and a second tap closes the row.

### v4 reviewer fixes (7:28 PM), 233 closed
1. **No spring-back.** The wheel stays where he leaves it. When the page reopens, it goes back to the first pinned recipe, or the quickest one if nothing is pinned.
2. **Foot word.** It is "Get it" when one thing is short and "Get 2 things" when more are short. Both put the items on To get, with the receipt "Feta and mascarpone, on To get. Undo" for 10 s.
3. **Detail line.** It has a fixed one-line slot and a short form, e.g. "lemons, spaghetti and 2 more". Under Reduce Motion it appears in one step.
4. **Pinning (coordinator ruling).** Pin from the recipe page, not by holding, because a hold picks up the wheel. The recipe page has a fixed "Keep at the top" line that reads Pinned or No, with "Overnight oats, pinned. Undo". Pinning is also a VoiceOver action. The recipe page shows up to five ingredient lines; past that it shows four plus "and 3 more".
5. **VoiceOver and AX3.** VoiceOver reads the wheel as a list, giving each row's name, minutes and detail. At AX3 the wheel shows 3 rows.

## v5 (his 7:54 PM: "this is looking better")
- **Focus at the top, list loops.** The focused recipe sits in the first slot, where the list starts. Scrolling brings the next recipe up into that slot and highlights it, and the one that was there goes round to the back of the list. "New recipe" is part of the loop. The wheel ends on a row boundary (202 pt here, 392 pt full page), so no row is cut.
- **Focused detail, two lines.** Line 1: "5 min, about 350 cal a serving". Line 2: what goes in it. Calories are worked out on the phone (coordinator ruling) and appear inside the Kitchen room only, on the focused row and the recipe page ("about 520 cal each"). They never go on Home, widgets, notices, the Live Activity, backups or logs.
- **Units.** The right column reads "20 min", with "min" at 0.62 of the number's size.
- **Section line.** Right-aligned: "7 you can make now, quickest first".
- **Dial.** The neighbours grow from 17 to 26 pt, so "All" and "One short" read clearly. The Pantry (232) dial gets the same change.
- **Full list.** Tapping the lens in focus ("Ready now") turns the page into that full list. The lens name and count sit at the top, and the wheel runs down to the foot. The left edge goes back (title tap stays the index, 224).
- **Cook now.** It cooks whatever is highlighted. The cooking mode from 231 rises up from the bottom: the dish, "Step 1 of 5", the step title, the timer at 72 pt and the next step in the brief. The foot reads "Next step", and "Done cooking" on the last step, followed by "Lemon pasta, cooked. Pantry took 6 things. Undo".
- **Tap.** Tapping the highlighted recipe opens its recipe page. Tapping any other row brings it to the top.

### v5 reviewer fixes (7:58 PM)
1. **AX3 and above:** the dial shows the focus plus one neighbour, and its slot grows by one line. This applies to Pantry (232) and Recipes alike.
2. **Detail lines:** each is a single line in a fixed slot. The ingredient short form names two things, then the count of the rest: "lemons, spaghetti and 4 more". The calorie line never wraps. At AX sizes the focused row keeps one detail line (minutes and calories) and the ingredients move to the recipe page.
3. **Calories:** a Settings switch, "Show calories", ships On. Calories stay out of Tess's Claude lines, notices, widgets, the Live Activity, the cooking brief, logs and backups.
4. **Full list:**
   - Back is the left-edge swipe only. A title tap stays the room index (224).
   - It moves one row per drag or flick and snaps; there is no free scroll, and a long flick still moves one row. This is the 230 wheel, which counts as paging by rows.
   - The foot word follows the focused recipe: Cook now, Get it, Get 2 things, or New recipe on its row.
