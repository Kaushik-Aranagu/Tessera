# M4 screen steers ("My day, connected")

One paragraph or so per Feature screen in `docs/product/ship-list-m4.md` (Product's copy: `tessera/product/ship-list-m4.md`), at the weight of `m3-steers.md`. Rough is fine; the UI bar is not optional: Inter Tight tiers, nothing under 16pt, no italics, no cards, pills or stock lists, painterly ground with hairline seams, directional entrances. Plan my day and Shutdown are **Now on Home**, not separate screens, so they reuse `today-on-home.md`'s queue, gestures and haptics.

## 6 · Plan my day (rules only), with 10b · the energy check-in
At 08:00 the plan becomes Now. It's a state of TODAY, not a card or a sheet.
- **Now line:** "this morning". **Hero** is the day in one sentence: "Three meetings, four hours free". The context line under the hero is the body: "slept 6h40" (21/400; "no sleep data" when Health has nothing).
- **The day stroke tells the time you have.** Calendar events paint onto the dashed rest-of-day guide as short ink segments at their times (ink 55%, 6pt, round caps). Free time stays dashed. This is the Tiimo lesson, time you can see, in the stroke you already know.
- **Energy** (10b) sits in one line under the context line: "Energy" at 21/400, then the **rep drum** (`RepsDrum`, 1 to 5, centre numeral 48 Light), with the value's word under the centre in labels: FLAT · LOW · OKAY · GOOD · BRIGHT. It's optional; the plan below is already filled for 3. Setting it re-flows the plan live: at 2 or below, the third line slides out (fades and the queue closes up, 320ms), and Tess's line in cobalt says "Short night. Two things, and a lighter top set."
- **The plan** is up to 3 **ghost rows** in the queue window (cobalt, wet, as in Tess captures), but they don't dry on a timer. **Swipe right accepts** a line: it dries into ink and its dab flies to its slot on the day stroke (the same flight as "tomorrow", landing at its time). **Swipe left skips** it: it fades and the queue closes up. Rows untouched when you start count as accepted.
- **The one control** is a cobalt `PaintKey`, 220×58 at y 452: "Start with **Call the dentist**" (the name in 600). Holding it (0.6s) makes that item Now. The plan's hero sentence lifts away and the item rises into the hero (the promotion motion). That's the end; the whole flow is under a minute.
- Skipping the whole plan: swipe the hero left (the plan only; it has no strike). It drops back to normal Today until tomorrow.

## 7 · Shutdown
At 21:00 Shutdown becomes Now, and the ground turns to **evening**: the paint washes shift to violet and vermilion over 1.2s, the same ground the day stroke ends in.
- **Now line:** "this evening". **Hero** is counts only: "Four tasks, one workout, cooked once". Never what didn't happen.
- **Rolling on:** a labels line, "GOING TO TOMORROW", then unfinished items as rows in the queue window, each with a small cobalt dab (going with you). **Tap a row to keep it off tomorrow:** the dab drains out, and the row reads "to Later" in labels at the right. Tap again to put it back. There's no checkbox and no red.
- **One optional line:** "Tomorrow, first:" as a writing line at 21/400 (50% placeholder). It's the one line for the Day log too.
- **The control:** an ink `PaintKey`, "Shutdown complete", hold 0.7s.
- **The living moment:** the day stroke paints the rest of its length to the vermilion end (700ms), the rolled rows' dabs fly off to tomorrow one after another (80ms stagger), the hero is replaced by "Done for today." at Hero 56/500, Tess plays `done`, and `.success` plays. This is the one exception to "no success on Home", because a day is a bigger finish than a task. After it, Now reads "tomorrow, first: …" quietly until morning.

## 5 · Day log (Time Machine)
- **Entry is z from the day:** tap the day label on Home ("Thursday afternoon") and the stroke zooms into the Day log, landing on today. The x lane on the stroke still pages yesterday and tomorrow on Home; the Day log is the deep version.
- **y is time:** today at the bottom, the past above. Pull down to go back, like reading up a thread.
- **A day** is a block with no frame. The date is a Title word in the margin ("Thu 15"), like aisle words. Then:
  - **Your line,** if there is one, at Title 34/500, as typed. It's the largest thing on the day.
  - **The headline:** finished things and firsts, joined with " · ", at 21/500 ("Push day, PR on bench · carbonara").
  - **The count line:** 21/400 at 70% ("4 tasks · 2 notes").
  - **The quiet line** in labels at 45%: "SLEPT 7H10 · 3 MEETINGS · ENERGY 4".
- **The paint spine:** each headline item has its area-colour dab at x 22, so scrolling the log shows a column of colour, a painted history of your weeks. No chart.
- **Empty runs** collapse to one row in labels at 45%: "OCT 3 TO 6". No count of empty days.
- **Undo from there:** tap a headline item and it gets an ink underline. Ask Tess shows the preview sentence in cobalt ("Removes bench 80 × 5 from Oct 12. Your PR goes back to 77.5"), with a vermilion "Undo" on the right. Tapping it runs the strike on that item, and today's block gains "undid 1 thing from Oct 12" in the count line. If the item has changed since, the preview says "Changed since. Open it" and tapping zooms to the object.
- **Later:** the right-edge rail scrubber (a light tick per day, a firmer one per week).

## 8 · Focus block and body double
- **Start:** "focus on the deck 25" through Tess, or on any task's object page, a "Focus" key with the duration as a word that cycles 25 / 50 on tap (the Settings grammar). Hold 0.6s to start.
- **It's a process, so it's Now:** the lit seam runs on the top edge; the hero is the task; the key reads "Done" (hold); the meta beside it reads "18 MIN / LEFT".
- **The timer is a horizon line** at y 204, just under the day stroke: a 2.5pt cream-on-ink stroke burning left to right (cook mode's timers), with no numerals ticking on screen.
- **The body double is Tess's soul.** While a block runs, the soul in the Ask Tess bar slows to one breath every 6s (scale 0.5 ↔ 0.56) and her line says "I'm here." That's all she does. **At halfway**, she asks once, "Still on the deck?", with two words on the right: **Yes** (ink) and **Switch** (vermilion). When the app is closed, a local notification asks the same.
- **The wrap-up:** when the time ends, the horizon flares cadmium (cook mode's flare). Tess says one line ("Twenty-five minutes on the deck."), with "Add a line" in cobalt to write the Day log line. Finishing the task itself is still the hold (or a swipe right in the queue).
- **Live Activity:** the rest activity's layout and Cobalt sky mood (`live-activity.md`). The left column is the task name at 21/600, then the horizon as `ProgressView(timerInterval:countsDown:)` (cream tint, 2.5pt tall) with `Text(timerInterval:)` in labels. The bottom row has one control, **Done**. No +15 or Skip. Give it a stale date at the block's end plus 15 minutes, so a forgotten block doesn't sit on the Lock Screen.

## 11 · Visible memory ("What Tess knows")
- **Entry:** ask Tess "what do you know", or from Settings ("Tess remembers **12 things**"; the number is the link).
- **Hero:** "What I know about you" (Title 44, in Tess's voice). Then the facts, each as **a sentence at 21/400 with its value words tappable** in ink 600, exactly as in Settings: "You train **Monday, Wednesday, Friday**." "Your **left shoulder** gets sore on overhead pressing." Under each, its source at 18 in context colour ("from 6 workouts", "you said so on Oct 9").
- Tapping a value word opens its instrument or a ghost-row edit, with Undo. **Swipe left to forget,** with **FORGET** as the destination word.
- **The living moment:** a forgotten fact's sentence breaks into cobalt pigment that drifts down into the soul (the hand-off motion, reversed), and the soul takes one slow breath. A fact Tess has just learned arrives with the glyph reveal and a cobalt wash that fades over 2.8s, as everything Tess changes does.
- Groups are Title words in the margin (Training, Kitchen, Days), never cards or sections with headers.
