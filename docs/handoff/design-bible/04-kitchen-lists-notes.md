# 04. Kitchen, Lists, Notes

Status as of Oct 24, 2026. Newer sheets win. Hard rules in the brief (type, no cards/pills/bars/rings/dots/underlines/lens, no "N of M", 10 s Undo, swipe right Done / left Not now, dials on landings only, fixed text slots, one action word bottom-left + Tess bottom-right, privacy) override anything below that disagrees. Where an older sheet line breaks a hard rule, it is marked SUPERSEDED here.

Owner of all three rooms' screens: Builder B. Engine: Core.

Shared Kitchen pieces (from handoff-kitchen-231-233): `PlaceDial`, `FocusWheel`, `ReceiptLine`, foot word, in `Features/Kitchen/KitchenParts.swift`.

---

## Shared grammar for these rooms

- **Receipt line.** One fixed 26 pt line above the foot, 15 pt ink2. Pattern: "Thing, what happened. Undo". Undo is in the room's small-text color at 600. It lasts 10 s, and the newest receipt replaces the line. It clips in from the top over 0.3 s. Older actions stay reversible from Tess's room, where they read "Reversed" (sheet 232).
- **Action word gestures** (page-palette-rule, sheet 230). The bottom-left word takes a tap. It also takes a drag left (stop/remove) or right (again/new). The word leans 18 pt at most. Past 56 pt it rolls to the option's name with a selection tick, and release commits with a .medium impact and a 10 s Undo. Left drags start 28 pt or more from the edge, so they never fight the back edge (0-24 pt). Each option is also an accessibilityAction. No menus.
- **Back** is the left edge swipe. A title tap opens the room index (sheet 224). Rooms show no "< Home" word (217 ruling).
- **Wheels** (230 FocusWheel). The focus sits in the first slot and the list loops. Drag tracks 1:1, a flick moves one row, and it snaps on a spring with one tick per row. It never springs back. The height ends on a row boundary (202 pt in a band, 392 pt full page), so no row is ever cut. Every row is ink2 or darker; size and weight carry distance. Depth blur sits on neighbours, never on the focus or its detail line. The blur turns off with the Settings > Look "Depth on wheels" switch (default On), Reduce Motion, Reduce Transparency and Low Power.
- **Dials** have 3 places: the focus plus one above and one below. They loop, with one haptic tick per place, and are VoiceOver adjustable ("Fridge, 8 things"). At AX3+ the dial shows the focus plus one neighbour. Since Oct 24 2:06 AM the Notes dial uses 48 pt slots with neighbour blur up to 1.8 pt. **Depth rule (Oct 24 2:08-2:22 AM): dials belong on LANDINGS only.** Deeper pages use other list forms. See open question 1 about the Pantry and Recipes dials.
- **Region rule.** A drag belongs to the region where it starts. A vertical drag in the headline moves the dial, and one in the body turns the page or wheel. Horizontal drags on a row are row actions. Any 3 pt move cancels a 0.5 s hold.
- **Privacy.** A private item shows its real name inside its room only. Everywhere else it shows its shownLabel: briefs, counts text, notices, widgets, the Live Activity, Siri, backups and Tess lines. Briefs are built on the phone from templates, never by Claude. Calories and macros show in the Kitchen room only, behind Settings "Show calories" (default On). They never appear on Home, widgets, notices, the Live Activity, the cooking brief, Claude lines, logs, the op log or backups.

---

# KITCHEN

### Palette (sheet 234 v5/v7, page-palette-rule, color-roles-241)
| Role | Light | Dark | Use |
|---|---|---|---|
| Kitchen accent (ochre/amber) | A8701F | C49A5E | Room name, big numbers, dial focus, action word |
| kitchenText | 93611A (4.9:1) | C49A5E (8.1:1) | Small Kitchen words: Cook now, Undo, Get it, Cooking |
| Slate | 34506F | A7BCD6 | Section names |
| Wine (kitchenWarn) | 9A2541 | EE8E9C | What needs you: low, eat by tomorrow, throw out today |
| Pine | 2F6450 | 8EC7AE | Fine leftover days. Since 234 v7 it is no longer used on Pantry |

- Kinds (color-roles-241): Pantry teal 1E6E77/84C3C9, Recipes clay 9C4B2C/E2A07F, Shopping ochre.
- Kitchen dark C49A5E was moved off D49A52 because that was 9.1 from Ember gold (sheet 221).
- No food drawings (design-no-food-drawings). A recipe image is only his own photo, or nothing.

## Kitchen landing (sheet 231) — LANDING OPEN

**Status.** The 231 landing body is built, but the landing itself is superseded. The design handoff says "Kitchen 231-234 ... all their landings are superseded by the landing work". The 46 pt reel was rejected at 11:45 PM Oct 23 (sheet 240). The plan is to bring the word wall (see Notes) to the other landings after the Notes door pages. Treat the elements below as the content the next Kitchen landing must carry, not as its layout. Kaushik still wants the brief sentence kept ("Tacos tonight. Lemon is short."), and while he is cooking the landing focuses on cook mode (rooms-feedback-oct23).

**Not cooking (231 as built):**
- Top row: "Kitchen" and the day word.
- Headline: "Tonight you could make", then the dish in a 46 pt reel clipped to a 52 pt slot (REJECTED as a headline), then "25 min, you have all 8 things" and "another". Swipe up or "another" rolls to the next makeable dish. Tap the name to open the recipe.
- Brief from a phone template: "Eggs and milk run out first. Spinach wants using by Sunday."
- Pantry: three Outfit 200 44 pt numbers with the fixed labels "on hand", "low" (Kitchen) and "to get". They count up on arrival; VoiceOver reads the final values. A tap opens Pantry.
- Recipes lines: "You can make 4 now" (opens Recipes on Ready now), "Pasta on Thursday", "Dal, last made Tuesday", and "Ate out? Log it" (234).
- Foot: "Cook" (opens the Recipes wheel on Ready now), with Tess.
- Rejected: the separate Cook page (superseded by Recipes Ready now, 231 drift fix). Jars, heap and ink blooms (242 round 1). The paragraph, fine-line drawing and contents page (240: "drawings are the worst").

## Cooking (cook mode): the landing taken over (231, 233 v5, 229)
- Cook now rises from the bottom.
- Top row: "Cooking" in kitchenText.
- Dish name (opens the recipe), then the step line, then the step title 26 pt in a 58 pt two-line slot, bottom-aligned.
- Step timer: 72 pt Outfit 200 with one word ("garlic"). With no step timer it shows the soonest running timer; with none, the step's note.
- Brief: "Then: zest the lemons." On the last step: "Last step. Enjoy it."
- Timers: plain lines, soonest first, max 3 (229: name 16 pt, time Outfit 300 28 pt, "and N more" past three). A finished timer reads "Garlic is ready" in kitchenText, and the big number goes Kitchen "0:00 ready". It fires a local notification or Live Activity alert, with sound following the silent switch.
- Below, in ink3: "Pantry 24 on hand, 3 low" and "Pasta on Thursday".
- Foot: "Next step", then "Done cooking" on the last step. Done opens Leftovers (234). The receipt is "Lemon pasta, cooked. Pantry took 6 things. Undo".
- 229 extras still valid: the step hangs from a 1.2 pt edge thread, and the next two steps show as "Then ..." in ink3. Next step clips the old step upward with a 10 pt rise.
- Unconfirmed: 229's bead (a 4.5 pt ring breathing ±0.9 pt over 2.4 s) may now fall under "no rings".
- Hands-free (104, 229): "Say Next, Back, Repeat or How long". It runs on the device only and keeps no audio. "Listening" shows only while the mic is on. It asks for mic permission in context the first time, and turns off on leaving cook mode or after 2 min of quiet. It never handles money or private items.
- Private recipe: the notification and Live Activity read "Your dish" / "Timer done". Timer notification title is "Timer", body "<label> is done." (G217).
- "Step 2 of 6" is an N of M counter, which the hard rule bans. Replace it (open question 2).
- **Several dishes (sheet 132, older, logic only):** one merged queue on one clock, planned backward from the serve time. One next step for one pair of hands. The dish word sits small above the step, and dishes never get their own colors. "On the stove" holds max 3 timers. There is one warning line in ink2, a plan spine before starting, and "Change the plan" / "I am behind" (Serve at 7:10, holds warm 10 more, 5 more minutes; nothing shames). Its visuals (progress strip, ochre underline, "< Kitchen", bars) are SUPERSEDED. Redraw it in the 231 grammar. It sits behind switches multiDishCook and serveTimeAlign (default Off).

## Pantry (sheet 232, sections 234 v3-v8)
**Purpose:** what is in the house, by place.

**Layout top to bottom:**
1. Top row: "Pantry". On the right, "5 to get", which jumps the dial to To get.
2. Headline 196 pt (140 pt in the 237 v2 tighter spec): the place dial over To get, Fridge, Freezer, Shelf, Counter.
   - Focus: 44 pt Figtree 600 Kitchen, with its count in Outfit 200.
   - Neighbours: 26 pt ink2, with counts in Outfit 300.
3. Brief: two template lines, e.g. "Low on milk and eggs. Spinach wants using by Sunday." Freezer: "All good in here." To get: "Feta makes Shakshuka work."
4. Body (234 v4-v8): two packed section columns, 16 pt gap, each 232 pt tall.
   - Section name: 14 pt Figtree 600 in all small caps, tracking 0.015 em, slate, with a 1 pt hairline under it and the count right-aligned in Outfit 300. This is the one sentence-case exception, for labels only.
   - Things: 17 pt ink, sentence case.
   - Rows: 28 pt with the value beside the name, 34 pt with the value below. Sections sit 18 pt apart.
   - Value beside: 10.5 pt Light ink2. Value below: 8 pt Light, +0.03 em, on a 12 pt line, ink2 (see open question 4).
   - **Low lives in the name.** A low thing's name turns wine 500; the word "low" is gone. VoiceOver still says "Milk, low".
   - Packing: sections are taken in queue order from the entry section (the first with something low or near its day). Each column first-fits later whole sections into its leftover space. Only the first section in a column may split, with an "N more, swipe" tail. A header never sits alone at the bottom. Every column keeps at least one section to fill, so two sections always use both columns.
   - "Next: Produce" is a 13 pt right-aligned tappable line above the columns.
5. Receipt line, then the foot "Add a thing" ("Say it or type it. Tess puts it in the right place."), then Tess.

**Sections (max 4 per place):**
- Fridge: Leftovers, Dairy and eggs, Meat and fish, Produce.
- Freezer: Cooked, Meat and fish, Vegetables, Bread.
- Shelf: Dal and lentils, Grains and pasta, Snacks, Spices.
- Counter: Fruit, Vegetables.
- To get: For a recipe, Next shop.

**Gestures:**
- Swipe right (90 pt; 70 pt inside a column) means used up. The row slides off, its name arcs up to "to get", and the count rolls: "Milk, used up. On To get. Undo". On To get, swipe right means got it: "Feta, got it. Back in the fridge."
- Swipe left means not now: "Spinach, not now. Asks again tomorrow."
- Tap toggles in and low: "Butter, low. Add to To get  Undo". Tapping "Add to To get" puts it on Next shop. Tap does nothing on To get rows.
- Hold 0.5 s pins it, at most 3 per place, at the top of its own section: "Three pins already. Unpin one first."
- The column swipe works on the headers or the space under a column's last thing. A column part-way through a section continues it. A finished column takes the next queued sections. With none, it stays; when nothing can move, the columns nudge 10 pt (a haptic only under Reduce Motion). Back history holds 6 steps.
- A drag within 20 pt of the left edge is always back.

**Motion:** a dial change brings the columns in from the dial's direction, each clipping open with a 28 pt spring rise, 60 ms apart. Section moves slide inside each column's clip.

**States:**
- Large type: one column from the first accessibility size.
- Private: real name in the room only.
- Empty place: "All good in here."

**Rejected:**
- The v2 two-row section strip.
- Section names inside the paged list.
- Pine values (v7).
- The cupboard lintel and pixel columns (221; pixels are Home only).
- "1 of 2" page counters (banned N of M).

## Leftovers (sheet 234)
- "Done cooking" opens "Put leftovers away", which rises from the bottom.
- Headline: a servings drum. Focus Outfit 200 72 pt, neighbours 30 pt ink2. It runs 0 to the servings made, with no loop, and starts at made minus 1.
- Fixed rolling lines:
  - "Goes in": Fridge or Freezer.
  - "Good until": fridge defaults to 3 days; freezer 1-3 months, default 2.
  - "Remind me": that morning 10 AM, the day before, or Off. It obeys quiet hours (11 PM-7 AM). The notice reads "Dal in the fridge, eat by Monday." with no calories, and "Your leftovers" for a private dish.
- Foot: "Put in fridge" or "Put in freezer". At 0 servings it reads "Nothing left".
- A leftover row reads "Lasagna" with "2 left, by Sunday". The day before it turns wine; on the day it reads "throw out today".
- Swipe right on a leftover always means one serving eaten and logged as a MealEntry: "Lasagna, one serving eaten. Logged. Undo".
- Tap reopens the put-away screen. Past its day the foot reads "Throw out".

**Food from outside** (234): opened from "Ate out? Log it" or by telling Tess.
- Name: 30 pt 600 Kitchen. There is an optional photo, which stays on the phone with complete file protection and never goes to Photos or backups.
- Estimate: "about" + 72 pt Outfit 200 + "cal", then the macros line, then a source line: on-device (the default), typed, or Claude. Claude is used only under asksClaude plus lab mode, with a sent-log row.
- "You ate" rolls from None yet to All of it.

## Recipes (sheet 233 v5, the current pick)
**Layout top to bottom:**
1. Top row: "Recipes" on the left, "5 to get" on the right.
2. Lens dial: Ready now, One short, Planned, All, with counts.
3. Brief, e.g. "Fried rice is the quickest, 20 min. Lemon pasta uses the lemons."
4. Section line, right-aligned: "7 you can make now, quickest first".
5. FocusWheel, quickest first, with pins first. "New recipe" in kitchenText is part of the loop.
   - Focused row: 28 pt 600 ink, with two 15 pt ink2 one-line slots that clip in.
     - Line 1: "5 min, about 350 cal a serving".
     - Line 2: "lemons, spaghetti and 4 more", with use-first items in kitchenText 600. It may instead read "needs feta" or "milk low".
   - Other rows: name plus "20 min" on the right ("min" at 0.62 size), 17 pt next to the focus, then 15 pt.
6. Foot word follows the focus: Cook now / Get it / Get 2 things / New recipe.

**Interactions:**
- Tap the focused recipe to open the recipe page. Tap another row to bring it up.
- Tap the focused lens for the full-page list (392 pt wheel). Back is the left edge only.
- "Have" follows the level rule: in or low counts as have.

**Recipe page:**
- Name.
- "25 min, serves 2, about 520 cal each".
- Up to 5 ingredient lines, otherwise four plus "and 3 more". Missing things show "to get"/"low" in kitchenText.
- Fixed line "Keep at the top": Pinned/No. Pin lives here, because a hold would pick up the wheel.
- Fixed line "Plan for": a tap rolls No day, then Monday to Sunday, with "Shakshuka, planned for Monday. Undo".
- The foot follows the recipe.

**Rejected:**
- v1-v2 paged rows with per-row action words ("too cluttered").
- v3 timetable (kept only as an alternative view).
- Hold-to-pin.
- A spring-back wheel.

## Groceries
Groceries is not a separate list. It is Pantry **To get** (237 ruling); the Home Shopping face reads To get.

Still-valid logic from groceries-tess (47):
- The phone sorts by aisle.
- A planned meal's missing lines land with "for tacos" under them: "Tacos, 2 added. Undo".
- Claude's only job is matching a row to a recipe ingredient. It comes as one ask ("Scallions, for tacos?" Keep / Not now), never during shopping.
- "Usually" words come from his own check-off history, max 4.
- Groceries never notifies.
- "+" pack-first amounts ("1 can + 15 oz").

Its visuals (‹ KITCHEN, Title 44, wet cobalt ghosts, USUALLY caps) are SUPERSEDED. Remove gesture: see list-remove under Lists.

## Recipe from a link (kitchen/link-fetch-us 32, 231 fix 5, 233 fix 6)
- Order: L1 recipe card, then L2 the page's text, both fetched and parsed on the phone. L3 is Claude, only after both fail, with asksClaude on and his ask, logged in Sent, and skipped when Claude is paused at the cap.
- The New recipe brief reads "Tell Tess, type it, or paste a link." Its line: "A link is fetched from its site, read on the phone."
- Nothing is saved until Save. "Chili mac saved." comes with a 10 s Undo, and the recipe keeps "From budgetbytes.com".
- Failure copy, each in Tess's two lines, ending "Paste the text instead.":
  - "That site won't let me read it."
  - "The steps are paywalled. Paste them below."
  - "That page is paywalled."
  - "No recipe on that page."
  - "Claude didn't answer in time."
  - "Claude's paused until Nov 1."
  - "You're offline. I'll read it when you're back."
  - "Too big to read safely."
  - Several recipes on a page: "3 recipes on that page. I read the first."
- Visual layer (cobalt wash, sage brush pass, ‹ KITCHEN, Title 44) is SUPERSEDED. Redraw in the 231/233 grammar (unconfirmed, not yet drawn).

---

# LISTS

## Palette (237, color-roles-241 "Lists kinds v9")
- Olive accent 5E6B1F / B5BE7A: dial focus, focused list, list title, actions, check strike.
- Wine 9A2541 / EE8E9C: due only ("Fri", "due Friday", the count of a list due soon). Used sparingly (his 10:25 PM).
- Kind colors (v9, one family):
  - Shopping: Kitchen ochre.
  - Trips: steel 2F6A8F/8DBAD6.
  - Home: teal 1E6E77/84C3C9.
  - People: plum 8A4570/D69CC0.
  - Watch and read: lavender 6A5E8C/B4A9D6.
- v9 moved small-caps labels to ink2, because steel is too close to slate. Slate stays only on "Private".
- Halfway is ink.
- Board v9 https://claude.ai/artifact/9JBnr8TytGTnKtnnyXjdik is NOT yet reviewed. He called v8 "slightly okay, combinations not good".

## Lists page (sheet 237 v2/v3) — LANDING OPEN
**Kinds row** (v3): the top 42, 38 pt tall, one kind at a time.
- It shows the current kind, 17 pt Semibold ink, with its count at 15 pt in the accent.
- Each kind is a full-width page. It follows the finger 1:1 with a 0.3x rubber band, commits past 22% or on a flick of 0.5 pt/ms or more, and gives a selection tick.
- Kinds: All lists, Shopping, Trips, Home, People, Watch and read.
- It is a shared component, also for Notes, Kitchen and Money.
- SUPERSEDED in v3/v5: the "1 of 6" counter (N of M ban), and the glass lens and the v5 iris slab. The lens was rejected at 10:51 PM Oct 23: "I don't want that lens effect at all". Never re-offer it.

**Dial (v2 tighter):**
- 46 pt rows, focus 40 pt, neighbours 16 pt (0.4x) with blur.
- Dial 140 pt tall at top 84. Brief at 236. Wheel at 294, 310 pt tall.
- Lenses per kind:
  - All: Going / Due soon / Done / All.
  - Shopping: To get / Due soon / Got it all / All.
  - Trips: To pack / Due soon / Packed / All.
  - Home: Going / Due soon / Fixed / All.
  - People: To call / Due soon / Called / All.
  - Watch and read: Up next / Halfway / Finished / All.

**Brief:** "19 things left across 7 lists. Before the trip is due Friday."

**Wheel:**
- Header: small caps "Your lists" with "7 lists, due first".
- Focus: name in olive Semibold, 26 pt fitted down to 21 pt, then whole words.
- Detail 1: 13 pt, "5 of 9 left, due Friday" (due in wine Medium).
- Detail 2: 15 pt ink2, the next open things as whole items.
- Others: 17 then 15 pt ink2. Blur 0.65 / 1.0 pt.
- Order: due soon first, then most recently touched.

**Action word** names the kind: Start fresh / Start a run / Pack a bag / Start a project / Start a call list / Save a pick. Drag right gives "Private list".

## A list (237)
- It slides in from the right; back is the left edge.
- Header: the lens on the left, "5 of 9 left" or "All done" on the right.
- Title: olive, fitted 28 pt down to 21 pt. Meta: small caps "List"/"Private", then "9 things, due Friday".
- Rows: 40 pt at 19 pt. Open things first, then a "Done" label, then checked things in ink2 with a 1 pt olive strike. A due day shows at 13 pt wine.
- Check: tap, or swipe right past 70 pt. The strike draws left to right over 260 ms with a .medium impact. It stays struck for 1.5 s; each new check restarts the wait, so a run of taps drops together. Reduce Motion waits 0.6 s. Tapping a struck thing before it drops takes it back.
  - Receipts: "Passports, done. Undo", or "Before the trip, all done. Undo" on the last one.
- Swipe left: Not now. The thing moves to the end of the open things.
- Tap a done thing: "Passports, back on the list. Undo".
- More than 400 pt of rows pages vertically (drop the "1 of 2").
- Add: a new line opens at the top with an olive caret, and the word becomes "Done". Return adds the line and opens the next one. It autosaves on tap-away or Esc.
- "Add" dragged left: "Clear done", giving "Cleared 5 done. Undo". Cleared things are recoverable from the op log for 7 days. With nothing done: "Nothing done to clear."
- "Add" dragged right: "Uncheck all".

**Privacy:** "Private list" off the room. Under lab mode, private list things MAY go to Claude, gated by asksClaude with a sent-log row (his 10:25 PM).

## List remove (list-remove, item 65; Product NE11)
- Remove is one gesture with one Tess line and Undo. It is never a tap (tap is the check), never a hold, never a red row, trash can or confirm.
- The phrase form: "remove rice from groceries" gives "Rice, removed."
  - Not on the list: "No rice on Groceries."
  - Two matches: "2 rows match. Swipe the one to remove."
- Undo: "Ground beef, back on Groceries."
- A removed row never counts as checked.
- CONFLICT: the sheet's left swipe with REMOVE rising at 60 pt and committing at 96 pt predates the Oct 23 rule (left = Not now). Under today's rules remove has no row swipe. Use the phrase, or "Clear done" on the action word, plus the VoiceOver action "Remove". Open question 5.
- Rejected: Lists room lintel as a falling stepped line of tiles (217; pixels are Home only), and ink check rings (rings banned).

---

# NOTES

## Palette
- Room color is **plum 8A4570 / E3A3CB**, used on the 246 landing. Violet 5B3FB8 is retired: it was ΔE00 6.1 from Ember. Confirming plum is still open.
- Doors' meaning colors:
  - All notes: ink.
  - Ideas: room.
  - From Tess: "Tess blue" (see open question 6).
  - Voice memos: room.
  - Pinned: gold 7E6A1E/D9C27A.
  - Mentions: ink.
  - Private: slate.
  - Archive: ink2.
- 235's sienna 8A4B2A/E0A47F for "fresh today" stands for the inner page (unconfirmed after 246).

## Notes landing (sheet 246) — APPROVED Oct 24, 1:54 AM PT
Board v4: https://claude.ai/artifact/1mSPKcxhvQB4pFU2tmQZkx. Repo PR #1413. Supersedes 226, the 235 landing parts, 240 and 242 rounds 1-5.

**Frame:** 402x874 pt, 24 pt gutters.
1. "Notes" at y 54, Figtree 700 40 pt, room color. No "doors" label (his last tweak).
2. One line under it, Figtree 16 ink2, e.g. "Three new today, one from Tess."
3. **Word wall**: x 24-378, y 180-400 (220 pt, a quarter of the screen, centred on the Home mosaic slot, so the mosaic hands its place to the words).
4. **Doors dial**: y 432-576, 32 pt under the wall.
5. Line at y 612, Figtree 15 ink2 with the title in ink 600: "You last wrote in <Title>, an hour ago." He asked for this to be rephrased; final wording is unconfirmed. Private notes use shownLabel.
6. "New note" bottom-left (28 pt from the edge, 44 pt target), Tess bottom-right. No lines, cards or fills.

### Word wall engine (246; 242 rounds 4-6; word-wall-rules)
**Words.** The user's note titles, weighted by pinned, recent, due and opened often. Private notes never appear.

**Type.**
- CAPITALS, Figtree 900, letter-spacing -0.01 em.
- "Sharpened": a same-color outline stroked behind each glyph, at 3.5% of the font size, with mitred joins, for crisper corners.
- Line box = cap height only, with 3 pt gaps between every brick on all sides, so rows read as solid bricks.
- Nothing under 13 pt.

**Justified rows that solve their own height.** Every row meets both edges (x 24 and 378) exactly. With a = advance width per pt of size and C = cap-height ratio:
- Single word brick width = a/C·h.
- A stack of n small words, each sized to fill the brick width: width = (h - (n-1)·3) / (C·Σ(1/aᵢ)).
- A two-word name stacked on two lines, same color and size: width = a_max/C·(h-3)/2.
- Each row follows a brick pattern (B S / S B S / B B S / S B / B S B). Big words come from the top of the importance list, and stacks from the bottom, paired by length. Bricks are added until the row passes its target width, then h is solved (bisection) so the row meets both edges exactly.

**Notch fillers.** The notch beside a stacked name's shorter line is filled by one of:
- 1-3 small words stacked to its exact height, in other colors (Tetris L/J shapes);
- two words side by side at the name's size.

Repeats are allowed, but only of words not already on the wall. If nothing fits, the name goes flat on one line and the wall re-packs.

**Stretch and gaps (his rule).**
- Letters are never spaced unevenly, and there are no gaps.
- A word may stretch at most 8%, glyphs and spacing together and uniform (lengthAdjust spacingAndGlyphs).
- A row that can't reach both edges is rejected, never squeezed.
- The wall is packed at row-height scales 0.70-1.40 in 0.02 steps (36 tries). It keeps the largest scale whose leftover height is under 8 pt and spreads that leftover into the row gaps.

**Colors.** 12 per look, assigned by index·5 mod 12, so neighbours never match. This is the one exception to 3-4 colors.
- Light: B5452B 1E6E77 7A5A12 5A3F8E 2F6A8F 8A4570 3F6B2A 9A2541 0F766E 92400E 1F4E8C 1D1B19.
- Black: F09A7E 84C3C9 E2C26A B4A3E6 8DBAD6 E3A3CB A9D48A F08E9C 5FD0C0 F0B07A 9DB8F0 F1EEE9.
- Open question 7: B5452B and F09A7E have not been checked against the ΔE00 10 Ember rule.

**Tap a word** to open that note.

**Moments** (his 1:46 AM timing; slower, so there is time to read and tap):
- Every 5 s, one word does one of:
  - flip: rotateX 360, 0.8 s;
  - jumble: letters scramble and settle left to right like the Home departure board, 0.8 s;
  - dissolve: noise/turbulence displacement out and back, 1.3 s.
- Every 40 s a new word swaps in and the wall re-packs: bricks glide to their new places on a 0.65 s spring.
- Every 2 min there is one whole-wall moment, alternating: a diagonal flip wave, or dissolve everything and rebuild with new words.
- **No pile.** "Not needed, remove it, forget it" (2:02 AM). On entry the bricks glide into place 22 ms apart.
- Reduce Motion: no moments, and swaps cross-fade.

**Rejected on the way** (don't re-offer):
- Archivo condensed: wanted the Figtree/Bricolage feel.
- Bricolage 84% width: Figtree won in round 6.
- Plain Figtree, Plus Jakarta Sans 800, Urbanist 900.
- Third-screen (300 pt) and full-page bands: the quarter band won.
- Uneven letter spacing to fill.
- Pile-and-tidy, toss, and the tilted pile.
- Tide ("doesn't have anything").
- Ink-only with top-5 colored: he wants as many colors as possible.
- Round 3's subtitles under words.

### Doors dial (246)
- The app dial: 3 places, **48 pt slots** (64 before; same type size), loops, haptic tick per door, spring settle.
- Focus: name Figtree 700 21 pt x1.32 in its meaning color, with the count in Outfit 400 at about half size, ink2.
- Neighbours: smaller, ink2, **depth blur up to 1.8 pt**, none under Reduce Motion or Low Power.
- Order: All notes, Ideas, From Tess, Voice memos, Pinned, Mentions, Private, Archive.
- Right of the focus: "Newest <when>" (13 pt ink2), then its 3 newest titles (16 pt, the first at 700), which rise 6 pt into place when the focus changes. Private shows one line, "3 private notes", never "Private note" repeated.
- Drag vertically to turn. Tap the focus to open the door; tap a neighbour to turn to it.
- Rejected:
  - the spine shelf of door names (1:40 AM; he liked the column idea, so keep it for another place);
  - plain "Recent" + 2-column "Doors" rows ("too basic");
  - a "Doors" section label.

## Notes door pages: his Codex-era decisions (2:45-8:35 AM PT Oct 24) WIN over 247 v2
247 v2 (below) was written from his 2:08-2:22 AM notes, before he kept designing with Codex. Where they differ, these later decisions hold, and 247 must be reconciled to them before anyone builds (source: `docs/handoff/codex-chat-oct24.md` §1):
- **Band:** the Notes word wall, a FIXED block on every door page. Codex's prototype used 354 x 124 pt (247 v2 says 354 x 132; use 124 unless he says otherwise). Word spacing 3 or 5 pt, "fine either way". Landing effects apply (flip, departure scramble, dissolve).
- **Too few words:** repeat words in other colors and sizes (his rule). This replaces 247 v2's split-names-and-fillers fallback.
- **Areas (tags):** a note may touch several areas; tapping an area gathers every related note across doors. A key Notes feature.
- **Lower section = Folio:** the section under the band turns like a real flexible page while the band stays fixed. Horizontal swipes curl the page left; vertical swipes fold it top to bottom. Backside visible, a crease, a soft contact shadow, shallow curl, firm bound edge, a little corner lift (Codex used the Grabfold WebGL page curl as reference). This replaces the "ledger" list as the pick.
- **Neighbours by name:** no "Previous note / Next note"; the turn words name the neighbouring notes by title.
- **Titles overlay:** the small heading above the preview (a "Titles" word) opens a searchable overlay of every note title.
- **Lower section shows a small card per note** (his ask, an exception to "no cards" for this place); opening a note shows its own full page without the band (voice memo: duration, areas, transcript).
- **Open note order:** title, updated date, then the content directly. Areas come after the content as a control that opens a small pane sized to its contents.
- **Areas pane is glass (his ask, exception to "no lens or glass" for this pane only):** translucent, thin, refractive, NO border, NO bright rim, the text behind faintly visible. Selecting an area opens that area's list.
- **No diagonal arrow glyphs anywhere.**

## Notes door pages (sheet 247) — DRAFT v2, not approved, to be reconciled with the section above
Board v4: https://claude.ai/artifact/S4dqsoynjdQMRQsV9EPW5z.
- **One fixed block on every door page:** the wall is always x 24-378, y 140-272 (354x132 pt). The list always starts at y 300. Nothing below moves from door to door.
- Font sizes vary per door so each door's words fill that exact block. No gaps. No row of all-equal sizes if a mixed row fits.
- **Door wall algorithm:**
  - Each note once, newest first. Each gap between neighbours is one of: same stack (2-3 titles each sized to the stack width), next brick, or next row. All 3^(n-1) choices are tried, up to 10 items.
  - Every row meets both edges. The whole wall may scale ≤ 8% uniformly so the last row meets the bottom.
  - Score:
    - closest to no scale;
    - a newer row is never smaller than the row under it;
    - neighbouring rows differ by 25% or more;
    - rows of 3+ equal words cost most, rows of 2 equal words some;
    - nothing under 13 pt.
  - Small doors: a two-word title may break into stacked words (never side by side, one color). If it is still short, the note's day and detail join as ink2 fillers, smaller than every title, never two side by side.
  - Tap a word to focus that note in the list.
- **Page:**
  - Back word "Notes" top-left in the room color.
  - Door name Figtree 700 34 pt in its color, then one 16 pt ink2 line.
  - The block, then the list at 300.
  - Action word per door: New note, New idea, Ask Tess, Record, New private note, Restore.
- **List ("Ledger", the pick):**
  - An 84 pt left column names each group only where it starts, in the room color at 13 pt small caps: Today, Yesterday, This week, Earlier. Mentions groups by kind.
  - **Titles are sized by recency:** Today 21, Yesterday 18, This week 17, Earlier 16 (Figtree 600). Mentions: 19 for the top three, then 16.
  - The when sits at the right, 13 pt ink2. Under it, one 14 pt ink2 line cut at a whole word, with no "...".
  - Tap a note to open it in place (title +3 pt, body 16 pt, meta 13 pt).
- **From Tess** reads as her voice. There is no "Tess said" title. A small line reads "About **Run plan**" (13 pt ink2, the subject in ink 700) with the when, then her sentence in **Newsreader**, in Tess's color, sized Today 22, then 19, 18, 17. The open one shows all her words at +3 pt.
- Voice memos: length in Outfit, units at half size, plus the start of the transcript.
- Private: locked until Face ID ("Unlock"), and counted ("3 private notes").
- Going in: the landing's words that belong to the door stay and re-pack; the rest dissolve. Moments as on the landing, with no pile.
- Alternative (not picked): "Pages", four notes a page with an "Older"/"Newer" word or a sideways swipe.
- Unconfirmed: the sheet header says "Oct 24 4:30 PM PT" while the depth rules are 2:08-2:22 AM. That is likely 2:30 AM.

## Note page (sheet 235, the parts not superseded)
- Header: lens on the left; on the right "Today, 2 h ago" or "Edited 3 days ago".
- Title in the room color (was violet), fitted 28 pt down to 21 pt, then whole words. Meta: small-caps "Note"/"Private" in slate, then "29 words, kept at the top".
- Body: Newsreader 19/26, paged in 286 pt pages. Unconfirmed: Newsreader is now reserved for Tess's words, so the user's own note body may need Figtree. The 247 open-in-place uses 16 pt.
- Fixed lines "Keep at the top" and "Private" (Yes/No rolls on tap). Max 3 kept.
- Foot: "Write", which becomes "Done".
  - Drag left: "Delete note". It goes into "Recently deleted" for 7 days.
  - Drag right: "New note".
  - While typing, "Done" dragged left: "Put back".
- Autosave every 2 s of quiet.
- Private:
  - shownLabel off the phone.
  - Body kept out of backups; a restore brings back a stub.
  - Under lab mode private text MAY go to Claude, with asksClaude and a sent-log row (v3, his 10:25 PM).
- SUPERSEDED: the 235 dial and wheel list (now the 246 landing and 247 ledger), violet, and "1 of 2".
- Also SUPERSEDED: 217 note-as-tile-rows lintel, 81, notes-grammar 57 (cobalt, Title 44).

## Landing studies that led here
- **240** (Oct 24 12:00 AM), board https://claude.ai/artifact/XJrBPpMjnuFCyvTjpp4CgY. All REJECTED at 12:07 AM:
  - A: paragraph prose with bold door words.
  - B: fine-line drawing with labelled doors ("the worst").
  - C: contents page of ranked words.
  - Its system rules (one statement of now, 3-6 doors, no list rows) still describe what a landing must do.
- **242 rounds:**
  - Round 1 (U7CbdSZGtjH6f7Qh5M13ZA): strings, chimes, swarm, jars, heap, ink. All rejected; strings and chimes "too bad", swarm "too much".
  - Round 2 (24SMi8GxcoMFmMdtHwr99f): kinetic type: tossed/tidied, weighted words, tide, standing words. Rejected.
  - Round 3 (HgDEZfib4Xw9BiafqyVydt): the word band. **Liked**: "the first landing idea he liked".
  - Round 4 (M9JKaR55a6rRFdiBcH2sYU): packed wall, 12 colors.
  - Round 5 (CTm3h1DfeUV3nUADP8Vf6N): capitals, L/J stacks.
  - Round 6 (1mSPKcxhvQB4pFU2tmQZkx): became 246.
- Next: use the wall on other landings (Kitchen, Lists and Routines are all open).

---

## Open questions and contradictions
1. Pantry (232) and Recipes (233) are deeper pages, but they use 3-place dials. The Oct 24 depth rule says dials go on landings only. Redraw them, or treat them as half-landings?
2. Banned "N of M" counters still sit in current sheets: cooking "Step 2 of 6", Pantry/Notes/Lists "1 of 2", the lists "5 of 9 left" detail, and the kinds row "1 of 6".
3. Kitchen and Lists landings are superseded but not redesigned. The word wall is the expected base.
4. Pantry value line at 8 pt Light (234 v8) is below the 13 pt wall minimum and the 10 pt units minimum. 9 pt was already flagged under Apple's 11 pt guideline.
5. list-remove's left-swipe REMOVE conflicts with left = Not now.
6. 246/247 say "Tess blue" for From Tess, but Tess's color is Ember FF5A26/FF6B3D. Which color is it?
7. Plum 8A4570 is the Notes room color (246), the Lists People kind (v9), and the Training Legs split. The light wall palette also includes 8A4570, and B5452B/F09A7E look close to Ember. They need a ΔE00 check.
8. Notes "Newsreader only for Tess" conflicts with the 235 note body in Newsreader 19/26 and the 235 first-words line in Newsreader italic.
9. 229's cook "bead" ring and 132's progress strip/bars may break the no-rings/bars rule.
10. 247's date "4:30 PM" looks wrong; it is probably 2:30 AM.
11. 234 v5 "slate section names with hairline" vs. 241 v9 "small-caps labels go to ink2" (Lists only?). Kitchen keeps slate (unconfirmed).
