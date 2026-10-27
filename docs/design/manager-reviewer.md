# Design manager and reviewer (Kaushik approved Oct 22, 7:21 PM PDT)

Rounds: one per 30 min on Sonnet, none from 11 PM to 7 AM PT.

## Manager
- Each tick a Haiku helper rewrites design/backlog-summary.md: every queued item (number, switch, lane,
  tier, state: queued / in build / in review / on phone / held), read from README.md, the sheets and
  build-order-193.md. It only summarises; it decides nothing.
- Design (Sonnet medium) reads the summary and decides what to merge, cut and order, then edits
  build-order-193.md.
- Once a day at 7 AM PT: a deeper pass over the whole backlog on Opus high (merge twins, cut what no
  longer fits the look or the privacy walls, re-tier before the next build batch).

## Reviewer
Before a round goes to the builders, a Haiku (or Sonnet low) helper checks its sheet against the rules
below and returns a list of breaks. Design fixes them. Design does its own short adversarial pass only
when the helper flags the round or it touches walls or money: try to break it (what leaks, what
fades, what blames).

### Rules checklist
1. Look: no cards, pills, filled or coloured dots, caps, middle dots, "..." truncation, fades or blurred
   edges; sentence case; 16 pt floor; text roles; Figtree words, Outfit numbers; "best" never "record";
   time as "1 hr 35 min"; house clock am/pm.
2. Accents: only from 127 (Training C4472A/EE6A4C, Kitchen A8701F/E0A458, Money 3F7A62/8DBFA7, Notes
   5B3FB8/B9A9E0, Lists 5E6B1F/B5BE7A, Routines A4505F/D79AA6, Tasks ink). Cobalt and violet are Tess's
   only. A8 link underline is 1 pt, never on the text. Vermilion is Undo only.
3. Motion: only through MotionPolicy; house spring; Reduce Motion = 150 ms crossfade; one haptic per
   moment (tick = picking, soft = marked, rigid = finished).
4. Privacy: walled titles, money amounts, health, calendar, body, calories never reach Claude, backups,
   logs, widgets or Spotlight; private reads "Private ..." in plain ink; Siri never sends; AI is on-device
   unless asksClaude; no new Claude use without it.
   (Send side superseded by Kaushik's Oct 27 11:59 AM ruling, docs/product/decisions.md; the backup, log, widget and screen walls stay.)
5. Tone: no guilt, streaks, counts of misses, "overdue" or "late"; offers not orders; Tess never faded;
   never an orb or skin for Tess; no Body weight page.
6. Process: each item has a lane, a Review switch default Off (or says it is a rule sheet), a Core fact
   or a note that none is needed, and an Undo for anything it writes.
