# Plan my day on the new Home (Design item 53)

**Kaushik's principle, in one line:** Home says one plain line per thing and never cuts text; the plan is a state of that same Home, not a page on top of it.

Redraws `m4-steers.md` section 6 (Plan my day, Research 95 and Product's 8:38 PM answers) in sheet 41's grammar on the 60 pt higher frame (`home-first-review.md`), for Builder B. Section 6 stands for everything not named here: when the plan shows, pulling it early, Claude's call and its failure lines, keep, skip, edit, the time drum, the hold, skipping the plan, VoiceOver and Reduce Motion. What changes is the frame, the lines and where Claude's words live.
- Board: `mockups/plan-home.png` (source `studies/plan-home.html`): the offer, Claude's words landed, the first time, kept, the planned workout paused (Obsidian), and the no-calendar two-line hero (Obsidian).
- Recording: `recordings/plan-home.mp4` (16 s), Porcelain: the offer in plain words, the wisps, Claude's order sliding in with VIA CLAUDE and her line, a swipe right drying one row, the hold on START WITH, and the first item rising into the hero.

## The frame
| y | Element |
|---|---|
| 78 | The tabs |
| 138 | The day label, Body 21: "Friday morning" |
| 186 | The context line in `context`: the time, and sleep when Health has been granted: "this morning, slept 6h40". Without Health: "this morning". (Home lines caps: ≤ 6 words, 32 chars) |
| 220 | **The hero is the day:** "Four hours free" with the calendar read; "Three tasks, Push A at 6" without it (never free, clear or open then). The 41 fitting form: Hero 56 if it fits 346 pt, else Title 44, else two lines of 44 (+50 below). "Four hours free" sits at 44 |
| 296 | **The key: START WITH, then the first item**, a label word with the ink line under it: `START WITH REPLY TO LANDLORD`. A **hold** (0.7 s) keeps the plan, the Finish grammar on the line. It never starts anything |
| 388 | **Plan** at Title 34 where Next sits, with **VIA CLAUDE** as a label word right-aligned on its baseline once Claude's words have landed (it taps to the receipt). Before that, nothing on the right |
| 440 + 46k | **The rows:** the title in Body 21/500 wet cobalt, breathing (0.5 to 0.66), the time at the right as a value word in the same cobalt. One line per row; a long title wraps (74). No dab, no line under it, no second line |
| the next slot | **"2 MORE"** as a label word when rows don't fit. At most five rows, and only rows that end above 720. A two-line hero costs one row; a wrapped row costs one |
| 736 to 820 | Tess's band, fixed. **Claude's sentence is her line**, not a line on the page: "Landlord reply first, then physio." (at most two lines at 270 wide; Core trims the clause to fit) |

- **The first time a plan comes via Claude**, Research's sentence takes one row slot at 16 `inkSecondary`, two lines: "Sends your task and calendar titles, never notes, places or health." It sits under the rows, after the MORE word, and never shows again.
- **Energy (10b) and sleep's detail move to the pulled view.** Pull up on the plan and the column scrolls under the fixed top (as section 6), with "slept 6h40" and the energy drum at its head and Claude's line under each row ("20 min, while the morning is quiet."). On Home a row is its title and time, nothing else.
- **Silent on purpose,** as before: drawing the plan, the reply landing, a time change, a skip, skipping the plan.

## Claude's words landing
- The rules plan draws at once in plain words, wet. While the call is out the cloud mark's three wisps rise off the soul; nothing else moves.
- When the reply lands: the **titles slide to their new slots** on the settle spring (520 ms); the slot times stay where they are, because the slots are the day. The key's words cross-fade to the new first item (blur 4 → 0, 420 ms). VIA CLAUDE fades in beside Plan. Tess says the order.
- Per-row lines from Claude live only in the pulled view (section 6 already says so).

## Keeping and the hold
- **Swipe right keeps a row:** the title dries from cobalt into ink left to right (700 ms clip sweep), the time follows 250 ms later. Tess: "Reply to landlord, 8 am." with UNDO (4 s). With the day stroke gone from Home (41 §4), the slot paints on the stroke one tap down, unseen; on Home the dry is the moment.
- **Hold START WITH:** the line empties to a 0.9 pt trace at 35% and repaints left to right over the hold. On commit:
  1. the day's hero lifts away (−24 pt, blur, 320 ms);
  2. the first item **rises into the hero** (Title 44, 480 ms, house) and the context line becomes its time: "this morning, 8 am";
  3. the key becomes 41's workout key, `START PUSH A`, with its full line: **the planned workout's progress line.** Before the workout it's full ink; paused, a 22% track filled to the share of sets done (`RESUME PUSH A`); done, the key goes and the row in Next reads "Push A done". The hold never starts the workout;
  4. Plan becomes Next, VIA CLAUDE goes, the kept rows close up one slot and dry to ink;
  5. Tess: "Plan kept. Reply to landlord is up." with UNDO (10 s). UNDO brings the plan state back as it was.
- If the first item **is** the workout, the key reads `START WITH PUSH A` (the hold) until the plan is kept, then `START PUSH A` (a tap, 44's Start). The words tell the two apart; the line is the same line.

## Rest day, no calendar, a late pull
- **Rest day:** "Rest day" stays the hero (section 6 rule 3) and the plan's key, Plan word and rows sit under it in the same slots; there's no START PUSH A to displace.
- **No calendar:** the hero counts tasks and the workout: "Three tasks, Push A at 6", two lines of 44, so four rows and "1 MORE".
- **A pull after the offer is spent** draws the same state; the hero then says what's left: "Two hours free".

## For Builder B
- `PlanState` on Home: `offered`, `worded` (VIA CLAUDE, the order), `kept`. The rows are the Next rows with a `ghost` flag (wet cobalt, breathing) and the swipe gestures from section 6; `startKey` takes the plan's word and the hold, then hands back to the workout key with its `progress`.
- The hero's fitting form and the five-row cap are 41's existing rules; the plan adds the MORE word and the one-time privacy slot.
- Core: the plan's first item, the slot times, the trimmed clause for Tess's line, and the receipt behind VIA CLAUDE are unchanged from section 6.

## Owners
- **Builder B:** Home's plan state, the rows, the hold and the promotion.
- **Core:** the plan, Claude's call and its clause.
- **AI architecture:** the words Claude returns (home-lines caps apply to the hero and context line).
