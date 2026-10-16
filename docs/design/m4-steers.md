# M4 screen steers ("My day, connected")

> **Sweep 16 Oct (item 19):** parts of this sheet are amended by `sweep-19.md` (no dots, one base, the context line). Where they differ, `sweep-19.md` wins.

One paragraph or so per Feature screen in `docs/product/ship-list-m4.md` (Product's copy: `tessera/product/ship-list-m4.md`), at the weight of `m3-steers.md`. Rough is fine; the UI bar is not optional: Inter Tight tiers, nothing under 16pt, no italics, no cards, pills or stock lists, painterly ground with hairline seams, directional entrances. Plan my day and Shutdown are **Now on Home**, not separate screens, so they reuse `today-on-home.md`'s queue, gestures and haptics.

## 6 · Plan my day, with 10b · the energy check-in
Rewritten 16 Oct to Research 95 (`research/plan-my-day-flow.md`, #240) and Product's answers to it (decisions 8:38 PM PT). This version wins over the 15 Oct text, and over `recordings/plan-and-shutdown.mp4`, which is kept only for history. New recording: `recordings/plan-my-day.mp4` (source `studies/plan-my-day.html`), Porcelain.

**When it shows.** The plan is a state of TODAY on Now, never a card or a sheet. It's offered once per 4 AM day, from 08:00 (or his first open after it) until 21:00, and only when the rules plan has at least one task. It takes Now only in its place in Now's order:
1. **A running workout, cook or focus block keeps Now.** There is no offer while a workout runs. When it ends, the plan is offered the next time Home shows, without that workout.
2. **A timed task within 15 minutes keeps Now.** The plan waits until it's done or past.
3. **On a rest day, "Rest day" stays the hero,** with the next routine a tap away. The plan's rows and START WITH arrive under it in the queue window, and the plan has no hero sentence of its own.
4. **Otherwise the plan is Now.**

**Pulling it early.** From 07:00 he can pull the plan before the offer. The Now line reads "this morning · **plan**", where **plan** is a value word (Body 21/600 ink), and saying or writing "plan my day" does the same. A pull while a workout runs gets one Tess line, "Push A is under way, until about 8:05 am.", and leaves Now alone. After he skips the whole plan, only asking brings it back that day.

**On the build's Home frame (item 30, Product's density call 16 Oct 10:25 PM).** This block wins over the y values implied below, and the recording `recordings/plan-my-day.mp4` and board `mockups/plan-my-day.png` are redrawn to it.
- **Home's top stays fixed:** the tabs, the day label ("Friday morning") and the day stroke, with meetings as ink segments at 55%. The plan lives under it, from the context line at 246.
| y | Element |
|---|---|
| 246 | "this morning" in `context` |
| 280 | The hero in Title 44, up to 2 lines: "Three meetings, four hours free" |
| 392 | "slept 6h40" in `inkSecondary` on the left. Energy on the right on the same line: "Energy", the drum's numeral at Title 34 Light, and its word as a label (OKAY). It's the same `RepsDrum`, one row |
| 448 | START WITH in labels. **VIA CLAUDE** sits on the same line, right-aligned, in `ink` (it taps to the receipt) |
| 474 | The first item at Title 34 in cobalt on the ink line |
| 530 | Claude's sentence in `tess`, at most 2 lines: "Landlord reply first, then physio, then the report." |
| under it, once | **The first time a plan comes via Claude**, one line in `inkSecondary`: "Sends your task and event titles, never notes or places." (Product, 10:29 PM). It never shows again after that plan |
| 600 → 720 | The plan's rows, 46pt apart, title and time only |
- **At most 5 rows on Home, and only rows that end above y 720,** so no row ever sits under Tess's band (736 to 820). The rest wait one pull away, counted by a label word in the next slot: "2 MORE". With Claude's sentence that's 3 rows, and on the first time it's 1 row and "2 MORE".
- **Pull up** on the plan: the column scrolls up under the fixed top until START WITH sits at about 242. Each row then shows Claude's line under it ("20 min, while the morning is quiet.") at 72pt apart. Let go and it settles back on the settle spring. **Claude's per-row lines live only in the pulled view;** on Home a row is its title and time.
- Keeping a row, the hold on START WITH and the promotion are as below. Tess's lines sit beside the soul with UNDO under them.

**The page (Porcelain, Thu 15 Oct fixture d01).**
- **Now line:** "this morning".
- **Hero**, the day in one sentence, Title 44/500. With the calendar read, it may count meetings and free time: "Three meetings, four hours free". **Without the calendar, it counts tasks and the workout only:** "Three tasks, Push A at 6 pm". It never says free, clear or open then.
- **The context line** is sleep, and only once Health read has been granted from its own ask: "slept 6h40" at 21/400 `inkSecondary`. Before that there's no line at all, and the plan never asks for Health.
- **The day stroke** (6pt, `ink-line.md`) shows meetings as short ink segments at their times, at 55%, **only when the calendar is read.** Otherwise the stroke is as on any morning.
- **Energy (10b)** is one optional line under the context line: "Energy" at 21/400 `inkSecondary`, then the rep drum (`RepsDrum`, 1 to 5, numeral 48 Light) with its word under it as a label (FLAT · LOW · OKAY · GOOD · BRIGHT). It's logged for the Day log only. **It never changes the plan, and Tess says nothing about it.** Light days come from C1 to C3 (`light-day.md`), never from sleep or energy.
- **The one action** at y 450: the label START WITH, and under it the first item's name at Title 34 on the **ink line** in cobalt (`ink-line.md`, 2.5pt at 75%).
- **Up to 3 plan rows** in the queue window. Each title is Body 21/500 in wet cobalt, breathing (0.5 to 0.66), with its time at the right as a value word. **There's no dab before the words** (`no-dots.md`). The rows don't dry on a timer, and nothing is written by showing them.

**Claude words it (slice 6b).** The rules plan draws at once, in plain words, so there is never a wait.
- While the call is out, the **cloud mark** rises off the soul (`claude-settings.md`: three cobalt wisps), and VoiceOver says "Sent to Claude". Nothing else moves, and the plain words stay readable.
- When the reply lands, usually in 2 to 5s, the words cross-fade in place (blur 4pt → 0, 420ms, house curve):
  - The start line under START WITH becomes Tess's sentence: "Landlord reply first, then physio, then the report."
  - Rows may reorder inside the run, sliding to their new places on the settle spring.
  - Each row gets Claude's line under its title at 21/400 `inkSecondary`: "15 min, a quick one to open with."
  - **VIA CLAUDE** sits once as a label word under the start line (it taps to the receipt, as in `claude-settings.md`). It stands for the whole plan, so three rows don't repeat it. Each row's VoiceOver label ends "Via Claude".
- **Once he has touched the plan** (any swipe, edit, time change or the hold), a reply that lands later is dropped, and its cost still counts. A reply after 20s is dropped too.
- **When Claude can't word it,** the rules plan stays exactly as it is, the wisps go, and one quiet Tess line shows, at most one per plan:
  - Offline, an invalid reply, or a paused account: "Here's your usual plan."
  - No answer in 20s: "Claude didn't answer in time. Here's your usual plan." (the one timeout wording, `claude-settings.md` C15; replaces M18's "Claude timed out.")
  - Busy after one retry: "Claude is busy. Here's your usual plan."
  - At the cap: "Claude paused until Nov 1. Here's your usual plan."
  - A bad key: "That key didn't work. Paste it again?"
  - No key, Claude off, or the use-2 gate not yet passed: no line and no wisps.

**What he does with it.**
- **Swipe right keeps a row.** The words dry from cobalt into ink, left to right (700ms clip sweep), and the time follows 250ms later. **The moment:** the row's slot on the day stroke paints in at its time, wet in cobalt, and dries to ink over `Theme.Motion.dry`. Tess says "Reply to landlord, 8 am." with UNDO (4s). UNDO says "Reply to landlord taken back." and the row goes back to a wet ghost.
- **Swipe left skips a row.** It fades and the queue closes up (320ms). No line and no UNDO, because nothing was written.
- **Tap a row's words to edit it.** A 1pt cobalt writing line draws under the row (260ms), the words blur out, and the keyboard rises with the text ready. Return keeps it a ghost with the new words, re-parsed so "30 min" becomes its length, and the run repacks. If it now runs into a fixed block, the last row in the run slides out as a skip. Tess says "**Book physio, 30 min.**" (name first). Claude is not called again.
- **Tap a row's time** to open the time drum. The drum skips times inside fixed blocks, and Tess says nothing; the row shows the change.
- **Hold START WITH (0.7s,** the same hold as Finish). The ink line empties to a 0.9pt trace at 35% and repaints left to right, and the bead swells at the tip (`ink-line.md`).
  - It keeps every row he hasn't skipped, as one named transaction, and makes the first item Now. That's his act, so fixture N7 reads "never committed without his tap or hold".
  - The plan's hero lifts away and the item rises into the hero (the promotion motion).
  - Tess says "**Plan kept. Reply to landlord is up.**" with UNDO for **10s**. UNDO says "Plan taken back.", and the rows and START WITH come back as ghosts.
  - If the first item is a workout, it becomes Now's routine hero with its own Start word. The hold never starts a workout.
- **Skip the whole plan:** swipe the hero left. It drops back to normal Today with no line and nothing written. The offer is spent until tomorrow's 08:00.

**Silent on purpose:** drawing the plan, a reply landing, a time change, a skipped row, skipping the plan, and setting energy.

**VoiceOver:** a row reads "Proposed: Reply to landlord, 8 am. Via Claude." with the hint "Swipe right to keep, left to skip" and the actions Keep, Skip, Edit, Change time. Times in labels use am and pm. START WITH reads "Start with Reply to landlord" with the hint "Touch and hold".

**Reduce Motion:** cross-fades for the reword, the dry, the reorder and the promotion. No wisps (VoiceOver still says "Sent to Claude"). The hold fills without thickening, and there's no bead.

## 7 · Shutdown
At 21:00 Shutdown becomes Now. **The ground does not change** (one base; the evening is only the day stroke reaching its vermilion end). The hero holds at most two counts, the rest go to its label line, and the handoff and what follows until 04:00 are drawn in `evening-on-now.md` (item 17), which wins over this section where they differ.
- **Now line:** "this evening". **Hero** is counts only: "Four tasks, one workout, cooked once". Never what didn't happen.
- **Rolling on:** a labels line, "GOING TO TOMORROW", then unfinished items as rows in the queue window at Body 21 in `ink`, with **TOMORROW** as a label in the time column. There's no dab (`no-dots.md`). **Tap a row to keep it off tomorrow:** TOMORROW is struck through (2.5pt, `ink-line.md`) and **LATER** sets in beside it. Tap again to put it back. There's no checkbox and no red.
- **One optional line:** "Tomorrow, first:" as a writing line at 21/400 (50% placeholder). It's the one line for the Day log too.
- **The action:** the label "WHEN YOU'RE DONE", and under it "Shutdown complete" as a stroke word on the ink line in the look's `context` paint (not the old plum literal). Hold 0.7s, with the ink-line hold and bead.
- **The living moment:** the day stroke paints the rest of its length to the vermilion end (700ms), the rolled rows' TOMORROW words lift off toward the day stroke's end, one after another (80ms stagger), the hero is replaced by "Done for today." at Hero 56/500, Tess plays `done`, and `.success` plays. This is the one exception to "no success on Home", because a day is a bigger finish than a task. After it, Now reads "tomorrow, first: …" quietly until morning.

## 5 · Day log (Time Machine)
Recording: `recordings/day-log.mp4` (source `studies/day-log.html`): reading back up the week, undoing one moment from Monday, and today's count line noting it.
- **Entry is z from the day:** tap the day label on Home ("Thursday afternoon") and the stroke zooms into the Day log, landing on today. The x lane on the stroke still pages yesterday and tomorrow on Home; the Day log is the deep version.
- **y is time:** today at the bottom, the past above. Pull down to go back, like reading up a thread.
- **A day** is a block with no frame. The date sits in the margin in labels, on two lines ("WED" / "14"; today reads "TODAY" in ink). The content hangs at x 94:
  - **Your line,** if there is one, at Title 34/500, as typed. It's the largest thing on the day.
  - **The headline:** finished things and firsts, joined with " · ", at 21/500 ("Push day, PR on bench · carbonara").
  - **The count line:** 21/400 at 70% ("4 tasks · 2 notes").
  - **The quiet line** in labels at 45%: "SLEPT 7H10 · 3 MEETINGS · ENERGY 4" (sleep only once Health read is granted, meetings only with the calendar).
- **The paint spine:** under each date, one continuous 3pt margin stroke whose colour shifts by segment, one segment per headline item, at the rest tint (`no-dots.md`). Scrolling the log shows a quiet column of colour in the margin, a painted history of your weeks. No dabs and no chart.
- **Empty runs** collapse to one row in labels at 45%: "OCT 3 TO 6". No count of empty days.
- **Undo from there:** tap a headline item and it gets an ink underline. Tess shows the preview sentence by her soul in cobalt, at most two lines ("Removes bench 80 × 5. PR back to 77.5."), with a vermilion "Undo" on the right. Tapping it runs the strike on that item, and today's block gains "undid 1 thing from Oct 12" in the count line. If the item has changed since, the preview says "Changed since. Open it" and tapping zooms to the object.
- **Later:** the right-edge rail scrubber (a light tick per day, a firmer one per week).

## 8 · Focus block and body double
- **Start:** "focus on the deck 25" through Tess, or on any task's object page, a "Focus" key with the duration as a word that cycles 25 / 50 on tap (the Settings grammar). Hold 0.6s to start.
- **It's a process, so it's Now:** the lit seam runs on the top edge; the hero is the task; the key reads "Done" (hold); the meta beside it reads "18 MIN / LEFT".
- **The timer is a horizon line** at y 204, just under the day stroke: a 2.5pt cream-on-ink stroke burning left to right (cook mode's timers), with no numerals ticking on screen.
- **The body double is Tess's soul.** While a block runs, the soul in her corner slows to one breath every 6s (scale 0.72 ↔ 0.8) and her line says "I'm here." That's all she does. **At halfway**, she asks once, "Still on the deck?", with two words on the right: **Yes** (ink) and **Switch** (vermilion). When the app is closed, a local notification asks the same.
- **The wrap-up:** when the time ends, the horizon flares cadmium (cook mode's flare). Tess says one line ("Twenty-five minutes on the deck."), with "Add a line" in cobalt to write the Day log line. Finishing the task itself is still the hold (or a swipe right in the queue).
- **Live Activity:** the rest activity's layout and Cobalt sky mood (`live-activity.md`). The left column is the task name at 21/600, then the horizon as `ProgressView(timerInterval:countsDown:)` (cream tint, 2.5pt tall) with `Text(timerInterval:)` in labels. The bottom row has one control, **Done**. No +15 or Skip. Give it a stale date at the block's end plus 15 minutes, so a forgotten block doesn't sit on the Lock Screen.

## 11 · Visible memory ("What Tess knows")
Recording: `recordings/tess-knows.mp4` (source `studies/tess-knows.html`): swiping left to forget the shoulder fact, its pigment draining into the soul, the rest closing up as measured, and a new fact arriving glyph by glyph under a fading cobalt wash.
- **Entry:** ask Tess "what do you know", or from Settings ("Tess remembers **12 things**"; the number is the link).
- **Hero:** "What I know about you" (Title 44, in Tess's voice). Then the facts, each as **a sentence at 21/400 with its value words tappable** in ink 600, exactly as in Settings: "You train **Monday, Wednesday, Friday**." "Your **left shoulder** gets sore on overhead pressing." Under each, its source at 18 in context colour ("from 6 workouts", "you said so on Oct 9").
- Tapping a value word opens its instrument or a ghost-row edit, with Undo. **Swipe left to forget,** with **FORGET** as the destination word.
- **The living moment:** a forgotten fact's sentence breaks into cobalt pigment that drifts down into the soul (the hand-off motion, reversed), and the soul takes one slow breath. A fact Tess has just learned arrives with the glyph reveal and a cobalt wash that fades over 2.8s, as everything Tess changes does.
- Groups are Title words in the margin (Training, Kitchen, Days), never cards or sections with headers.
