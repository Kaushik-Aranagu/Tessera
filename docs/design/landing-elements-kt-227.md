# 227 Landing elements, Kitchen and Training (Oct 23, 5:40 PM PT)

**APPROVED by Kaushik, 5:40 PM PT Oct 23 ("yep they look good"), with the reviewer fixes below. Training accent cobalt 0B62AE light / 3B8CF2 dark as shown.**

Board: https://claude.ai/artifact/2EvzL9R6A49E46tEf4XvtF. The elements of the 226 layout, in type and fine lines only (his 4:27 PM ask: no pixel art outside the Home mosaic). Motion goes through MotionPolicy. Nothing fades; things arrive by a clip or a slide. Reduce Motion: each change lands in one step. For his review.

## 1 The loaded bar (Training headline)
- One side of the bar, from the centre out: shaft (2.4 pt, ink 3), inner collar (5 x 16 pt), sleeve line (1.5 pt ink), plates biggest first, outer collar (6 x 14 pt), sleeve end.
- Plates per side on a 45 lb bar, chosen from 45, 35, 25, 10, 5, 2.5. Heights are 118, 104, 90, 66, 52 and 40 pt; widths are 16, 14, 12, 8, 6 and 5 pt; gaps are 3 pt. Plates 25 and up are drawn in accent; smaller plates in ink 2. Outlines are 1.8 pt with no fill and a 3 pt radius.
- The opening weight sits at 80 pt in Outfit 200. It's a pressed number (222): drag 14 pt per 5 lb step; it's VoiceOver adjustable, and the arrow keys step it on the board.
- Reload: the plates that stay keep their place. A leaving plate slides off past the sleeve end (0.22 s, clipped there). A new plate slides on from the sleeve end (spring 0.34 s, damping 0.8, 70 ms apart). The outer collar rides out to the new last plate. Each plate gives a soft tick.
- "Each side: 45, 25." updates in its fixed slot. With no plates it reads "The bar alone."

## 2 Kitchen's start line (Kitchen headline, right side)
- The minutes to start: Outfit 300 at 30 pt plus "min". Under them, one 84 pt fine line: an accent part of 2 pt, round cap, sized minutes left / 60, with the rest drawn in edge at 1.5 pt. Once a minute it shortens from the right (0.4 s ease).
- More than an hour away: no line, only "at 6:05" (20 pt, ink 2). At start: "Start now" in accent, and the action word Cook gets one 222 nudge. More than 10 min late: "Started?" in ink 3, with no line.
- Cook mode: the timer takes this place (225 fix 2).

## 3 Arrival (after the 206 doorway wave)
- Headline: clipped open from the baseline up (0.42 s spring). A number counts to its value in 6 steps of 60 ms, with the digits changing in place. A word is revealed left to right (0.36 s).
- The second headline line follows at +80 ms, left to right.
- Brief: at +120 ms, each line is clipped open left to right in 4 steps of 70 ms.
- Body: at +240 ms, each line is clipped open from its top (0.24 s), 30 ms apart.
- Leaving plays the reverse at 0.6x, then the doorway runs back.

## 4 Two columns, paging
- 24 pt lines, six per page, 22 pt gutter. The column titles stay put. Each column's last line is a summary in ink 3 ("and 38 at home", "6 you can cook", "and 31 more").
- Turn (222 page turn): both columns move as one. Old lines slide 22 pt toward the swipe and are clipped at their column edge. New lines come in from 22 pt the other way, 0.26 s spring, 30 ms apart. A swipe past 40 pt on the body turns the page.
- "1 of 2" sits in ink 3 under the columns, only when there's more than one page.
- At AX3 the columns stack and page as one list (226).

## Reviewer fixes (coordinator relay, 5:34 PM)
- Drift removed: Kitchen has no shortening line, since that was a countdown bar. The minutes are a number only: "at 6:05" (more than an hour away), "38 min" (digits change in place once a minute), "Start now" in accent, and "Started?" in ink 3 when more than 10 min late. Rule: any line in a landing is a fixed length and changes only colour or weight.
1. Page turns are vertical: swipe up for the next page, down for the previous one, past 40 pt. Old lines slide 22 pt up and clip at the body's edge; new lines rise in from 22 pt below. Horizontal swipes stay with the rows (Done, Not now).
2. Plate reload: one soft tick per reload, not one per plate.
3. Empty states (226): Notes reads "Notes stay on this phone unless you ask Tess." In lab mode, Claude sees a note only when he asks Tess. Routines' quiet day has the action word "Start" plus the next routine ("Start stretch").
4. Arrival finishes in about 0.6 s. VoiceOver gets the final number immediately; the count is visual only.
