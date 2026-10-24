# 234 Leftovers, sections, food from outside

Board: https://claude.ai/artifact/UpEmYdcVc3CgusiXEw8VMf (r49). Answers Kaushik's 7:58 PM Oct 23 Kitchen note. It builds on 231 (cooking), 232 (Pantry dial, pages, gestures) and 233. The coordinator's guardrails are folded in. Notes inner page moves to 235.

## Leftovers after Done cooking
- "Done cooking" (231) opens "Put leftovers away", rising from the bottom. The top row reads "Done cooking", with the dish on the right.
- Headline: a servings drum. Three 64 pt slots; the focus is Outfit 200 72 pt ink, the neighbours 30 pt ink2. It runs 0 to the servings made, without looping. It starts at made minus one ("of 4 made, 1 eaten"). Drag it or tap a neighbour; it snaps on a spring.
- Brief: "Dal keeps 3 days in the fridge." / "Tess reminds you Monday."
- Three fixed lines; a tap rolls each value vertically (kitchenText 600):
  - "Goes in": Fridge or Freezer.
  - "Good until": in the fridge, Tomorrow to Wednesday, defaulting to 3 days for cooked food. In the freezer, 1 to 3 months, defaulting to 2.
  - "Remind me": that morning at 10 AM, the day before at 10 AM, or Off.
- "about 380 cal a serving" (room only). Under it, a 13 pt preview of the notice text: "Dal in the fridge, eat by Monday." A private dish reads "Your leftovers".
- Foot: "Put in fridge" or "Put in freezer". At 0 the fields hide and the foot reads "Nothing left", giving "Dal, cooked. Nothing left over."
- Put: the screen sinks, the dial spins to that place, and the row lands under Leftovers with its name in the Kitchen colour for 1.4 s. Receipt "Dal, 3 servings in the fridge. Undo".
- Reminder: a local notification that obeys quiet hours (never 11 PM to 7 AM PT; a reminder for "tonight" moves to 8 PM). No calories in it.

## Sections in every place
- Each place's things sit in sections. A section name takes one 44 pt slot of the five per page (13 pt 600 kitchenText, bottom-aligned), and it repeats when a page starts mid-section.
  - Fridge: Leftovers, Dairy and eggs, Vegetables, Fruit.
  - Freezer: Cooked, Meat and fish, Vegetables, Bread.
  - Shelf: Dal and lentils, Grains and pasta, Snacks, Spices.
  - Counter: Fruit, Vegetables.
  - To get: For a recipe, Next shop.
- Leftovers come first. A row reads "Lasagna" / "2 servings, eat by Sunday". The day before it turns "eat by tomorrow" in kitchenText 600; on the day it reads "throw out today".
- Section line: "2 leftovers, 2 low". The Fridge brief leads with the most urgent leftover ("Throw out the fried rice today." / "Low on milk and eggs.").
- Gestures on a leftover:
  - Swipe right: one serving eaten and logged as a meal ("Lasagna, one serving eaten. Logged. Undo"). The last serving gives "finished".
  - On the throw-out day, swipe right means "Fried rice, thrown out. Undo".
  - Tap: reopens the put-away screen to change the servings or day, with foot "Keep it".
  - Swipe left (not now) and hold (pin) stay as in 232.
- Categories come from the thing (Tess files new ones; Add a thing asks nothing extra). A new thing with no category goes in the place's last section.

## Food from outside
- Opened from the Kitchen landing (a line under Recipes, "Ate out? Log it") or by telling Tess. Top row "From outside" with the time.
- The name is 30 pt 600 in the Kitchen colour, an editable line ("What was it?"). Under it, "Add a photo" (a photo or a menu shot); the photo stays on the phone ("Photo kept on this phone"). No food drawings.
- Estimate: "about" + Outfit 200 72 pt + "cal", then "32 g protein, 85 g carbs, 30 g fat" (16 pt). A 13 pt source line reads:
  - "Estimate made on this phone from the name and photo. Tap the number to type your own." (default)
  - "Estimate from Claude, from the name and photo. Logged in Sent." Only with asksClaude on under lab mode, and every call writes a sent-log row.
  - "You typed this number."
- Fixed lines:
  - "You ate" rolls None yet, A quarter, Half, Three quarters, All of it. It defaults to None yet, so by default the food goes in the fridge.
  - "The rest goes in" defaults to "Fridge, until Sunday" (2 days for takeout); a tap switches to the freezer. At All of it the line reads "Left over" / "Nothing".
  - "Counts toward today": "about 410 cal" or "nothing yet".
- Foot: "Put in fridge" when nothing eaten yet, otherwise "Log meal". Receipts: "Chicken pad thai, in the fridge. Undo"; "Chicken pad thai, logged. Rest kept. Undo"; "Chicken pad thai, logged. Undo". Outside leftovers read in quarters ("half, eat by Sunday").

## Rules kept
- Calories and macros show in the Kitchen room only, behind "Show calories". Never on Home, widgets, notices, the Live Activity, the cooking brief, Claude lines, logs or backups.
- Private items show their real name in the room only.
- Receipt pattern with 10 s Undo, where the newest replaces the line.
- One foot word, with Tess on the right. The left edge goes back (Esc on the board).
- No cards, bars, dots, fades or food drawings. Reduce Motion lands everything in one step.

## Data for Core
- **FoodItem.category** (string from a per-place list) and **Place.sections** (ordered category list per place).
- **Leftover**:
  - source (recipe id or meal id), madeOn
  - servingsLeft (int) for cooked food, or portionLeft (quarters, 1 to 4) for outside food
  - place (fridge or freezer) and throwOutOn (date)
  - reminder (that morning, day before, off), plus a notification id
  - Eating a serving writes a MealEntry.
- **MealEntry**:
  - when, source (cooked or outside), title (private-aware), photoRef (on the phone only, never in backups)
  - portion eaten
  - estimate: cal, protein, carbs, fat, plus estimateSource (device, typed or Claude) and sentLogId when it came from Claude
  - leftoverId
- Calorie and macro fields stay out of backups and logs.

## Reviewer fixes (Oct 23, 8:11 PM PT), with coordinator rulings
1. **Swipe right always means one serving eaten**, logged as a meal with 10 s Undo. Older eats are reversible from Tess's room, where they read "Reversed". On the last day the row still reads "throw out today" in kitchenText 600 as the prompt. A tap reopens Put leftovers away, which reads "Fried rice is past its day. Throw it out, or give it a new day." Its foot is "Throw out", giving "Fried rice, thrown out. Undo". Rolling Good until to a new day turns the foot back to "Keep it". The reminder line and notice preview hide on a past day. Swipe left stays Not now.
2. **Claude estimates stay** (coordinator ruling: lab mode is his pick, and he asked for photo and menu estimates). They're gated by asksClaude plus lab mode, with a sent-log row. Strict mode gives on-device or typed only.
3. **Notifications:** the reminder is cancelled when the leftover is eaten, thrown out or moved. It follows the lock-screen preview setting (the text hides when previews are off), quiet hours hold, and it carries no calories.
4. **Photos:** kept in app storage only with complete file protection. Never saved to the Photos library, and never in widgets, backups or Tess's lines.
5. **Backups:** a MealEntry is backed up without calories, macros or the photo, and private titles appear only as shownLabel.
6. **Op log:** calories and macros stay out of the op log, in a local-only side table keyed by MealEntry id. Undo restores from that table on the phone.

## v2 (his 8:36 PM: "sections we could do two rows... horizontal swipes"): the section strip
- This replaces the section names inside the paged list. Under the brief sits a fixed 52 pt strip, two rows of 26 pt in two columns, so a place has at most four sections. Each cell shows the name (15 pt) and its count (Outfit 300).
- The section you're in is kitchenText 600, underlined. The others are ink2. A count turns kitchenText 600 when something in that section is low or near its day.
- A sideways drag (40 pt) that starts on the strip moves to the next or previous section, without looping. A tap on a name goes straight there. The list slides across on a spring, and Reduce Motion lands it in one step. VoiceOver reads it as tabs; the arrow keys move between them.
- **Region rule (coordinator):** a drag belongs to where it starts. On the strip it changes the section; on a thing it stays used up (right) or not now (left); on the dial it changes the place. Vertical drags on the list turn pages.
- The list shows one section at a time, four 44 pt rows a page (176 pt), with "1 of 2" under it on the right. The old section line is gone, since the strip carries the counts.
- After a put-away or an outside meal, the page lands on Leftovers with the new row lit.

## v3 (his 8:41 PM): two section columns. This replaces the v2 strip
- The body holds two columns side by side, one section each, with a 16 pt gap. Each column has a 30 pt header (name 15 pt 600 kitchenText, count Outfit 300 ink2). Below it are four 48 pt rows: the name at 17 pt, and under it an 11 pt value line (his 8:44 PM: "a few points smaller") in ink2, or kitchenText 600 when it's low or near its day. A column opens on the first section with something low or near its day, paired with the next section.
- Leftover value lines use a short form that fits the column: "2 left, by Sunday", "half left, by Sunday", "throw out today", "2 left, until Dec 12".
- **The swipe rule (his words).** One sideways swipe moves every column on:
  - A column with more things shows its next set. Its last row reads "2 more, swipe" in ink2.
  - A column that has shown everything takes the next unshown section.
  - With no next section, it stays.
  - Swiping back returns to the previous state.
  - When nothing can move, the columns nudge 10 pt and settle. Changed columns slide across inside their own clip, 60 ms apart.
  - A 13 pt line under the columns says what's next: "Next: Meat and fish, Produce".
- **Where the column swipe lives (coordinator's region rule, my pick).** It works on the column headers and on the space under a column's last thing. A sideways swipe that starts on a thing stays a row action: right is used up or eaten, left is not now, with a 70 pt threshold in the narrower column. A trackpad's sideways scroll also moves the columns.
- Fridge sections are now Leftovers, Dairy and eggs, Meat and fish, Produce (fruit and vegetables). There are at most 4 per place, and anything uncategorized goes in the last one.
- Kept from the v2 rulings: pins sit at the top of their own section and count in its rows, with 3 per place and no Pinned section. VoiceOver reads each header with words ("Dairy and eggs, 5, 2 low"), and the headers' column moves are VoiceOver actions (Next, Back). At AX3 and above, one column shows at a time and the same swipe rule applies. Each place remembers its columns for the session.

### v3 reviewer fixes (8:45 PM), with coordinator rulings
1. **His swipe model stays** (coordinator): a column with more things shows its next set, a finished column takes the next section, and with none it stays. The back history holds at most 6 steps.
2. **A second way to move:** tapping the "Next: Meat and fish, Produce" line advances, on a 44 pt hit area. A drag that starts within 20 pt of the left edge is the back gesture and never moves the columns. The swipe stays confined to the headers and the space under the last thing.
3. **Names:** the short form starts past 18 characters in a column.
4. **Large type:** one column from the first accessibility size, not from AX3.
5. **Entry:** if the first section with something low is the last one, the pair is the last two sections, so the low one is always on screen.
6. **Reduce Motion:** the nudge when nothing can move becomes a light haptic only.
7. **Pins:** pins sit at the top of their own section and count in its four rows (3 per place). A section with 3 pins and more things pages past them: page one has the pins and "N more, swipe".
8. **Row swipes:** they keep the 70 pt threshold, and the slide stays inside the column's clip.

## v4 (his 8:46 and 8:47 PM): packed columns and 9 pt subtext
- **Packing:**
  - Each column is 232 pt tall. A section takes a 26 pt header plus 44 pt per thing.
  - Sections are taken in order, starting with the entry section (the first with something low or near its day, wrapping round). A column takes the next section in the queue. It then fills its leftover space with any later section that fits whole (first fit), so short sections stack: Leftovers 2 and Meat and fish 2 share a column.
  - A section too long for an empty column shows what fits, then "N more, swipe".
  - Only the first section in a column may split, and a header never sits alone at the bottom.
- **Swipe step:** a column part-way through a section continues it, then packs more sections after it. A finished column packs the next queued sections. With nothing queued, it stays.
- **Next line:** it moves above the columns (13 pt, right-aligned, 30 pt, tappable): "Next: Produce", or "Next: the rest of Dairy and eggs".
- **After a put-away or a logged meal,** the columns rebuild from Leftovers.
- **Rows:** 44 pt rows, with the name 17 pt on 22 pt lines. The value line is 9 pt on 13 pt lines, tracking 0.02em (his "a couple of more points smaller"). 9 pt is under Apple's 11 pt guideline for body copy, so the phone keeps it at 9 pt only at the default text size and scales it with Dynamic Type from there. Ink2 at 9 pt measures 6.3:1, and kitchenText 600 measures 4.9:1.

## v5 (his 8:58 PM): four colors, distinct section names, transitions, two sections use both columns
- **Page palette (his "3 or 4 colors in a page", for every room).** Kitchen:
  - Kitchen amber A8701F / C49A5E for the place and action words.
  - Slate 34506F / A7BCD6 for section names: 7.6:1 on paper, 10.8:1 on black.
  - Wine 9A2541 / EE8E9C for what needs you (low, eat by tomorrow, throw out today, and a section's count when it holds one): 7.1:1 and 9.0:1.
  - Pine 2F6450 / 8EC7AE for leftover days that are fine: 6.3:1 and 10.9:1.
  - All sit at ΔE 13 or more from Ember and 11 or more from Kitchen amber. In dark they sit near other rooms' accents (ΔE 4 to 7), which is acceptable inside a room because rooms never share a screen. Ink stays for things, and ink2 for quiet values.
- **Section names vs things.** A section name is 16 pt Figtree 600 in all small capitals (a deliberate exception to sentence case, for labels only), tracking 0.06em, slate. It has a 1 pt edge hairline under it, the count right-aligned in Outfit 300, and a 26 pt slot. Things stay 17 pt ink, sentence case. So name and thing differ in case, size, colour, weight and the hairline.
- **Transitions.** A dial change brings the columns in from the dial's direction: each column clips open with a 28 pt spring rise, 60 ms apart, and the Next line clips in after. Section moves keep the sideways slide inside each column's clip. Reduce Motion lands in one step.
- **Packing rule.** When a column would stack sections, it leaves at least one section for every column still to fill. So two sections always take both columns (To get: For a recipe | Next shop), and stacking happens only when there are more sections than columns.
- **Underlines.** No decorative underlines anywhere. Underline is for linked words only.

## v6 (his 9:06 PM): low by the name, values to the side, tighter rows
- **Low reads from the name itself.** A low thing's name turns wine (kitchenWarn), weight 500, and the "low" word is gone. A leftover at "eat by tomorrow" or "throw out today" also gets a wine name. VoiceOver still says "Milk, low".
- **Values to the side when they fit.** The phone measures name (17 pt) + 8 pt + value (12 pt). If that fits the column, the value sits on the right on the same line ("Butter  half", "Salmon  1 fillet"). Otherwise it drops to a 9 pt line below the name. Value colours: ink2 for amounts, pine 500 for fine leftover days, wine for near or past days.
- **Spacing.**
  - One-line rows are 28 pt and two-line rows 36 pt (his 9:09 PM: tighter within a section; the swipe and tap hit area is the whole row, and at AX sizes rows grow with the text).
  - Sections sit 18 pt apart.
  - The "N more, swipe" row is 26 pt.
  - Packing uses each row's real height, so Dairy and eggs (5) now fits whole.
- **Section titles.** 14 pt all small caps, 600, tracking 0.015em (was 16 pt / 0.06em), slate with the hairline.

## v7 (his 9:12 and 9:13 PM): quiet value lines, the To get nudge
- **Value lines are always quiet.** Ink2 at Figtree 300, never the name's colour and never bold. The status lives in the name (wine when low or near its day), and the value only gives the detail. Pine is no longer used on this page, which leaves amber, slate and wine plus ink.
- **To get nudge.** When a tap turns a thing low, the receipt reads "Butter, low. Add to To get  Undo". "Add to To get" puts it on Next shop and rolls the "to get" count, giving "Butter, on To get. Undo". If it's already on To get, the receipt says "Already on To get." Swipe right (used up) still sends it straight to To get.

## v8 smaller subtext (his 9:18 PM)
- Value line beside the name: 10.5 pt Light (300), tracking +0.01 em, ink2. Below the name: 8 pt Light, tracking +0.03 em, ink2, on a 12 pt line.
- Rows: 28 pt beside, 34 pt below (was 36). "N more, swipe" tail 8 pt.
- Side fit measures the value at 10.5 pt Light.
