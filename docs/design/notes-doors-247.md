# 247 Notes door pages (draft v3, Oct 25 5:20 AM PT; not yet approved)
Board: https://claude.ai/artifact/S4dqsoynjdQMRQsV9EPW5z (v5). Owner: Builder B. Builds on 246 (landing). Supersedes 247 v2 where they differ: his Codex-era choices (2:45-8:35 AM Oct 24, digest `docs/handoff/codex-chat-oct24.md`) win.

## His rules
- 2:08 AM: the dial is for landings only. Door pages use another form (the Folio).
- 2:19 AM: one fixed block on every door page, same place and size on every door; the list section starts at the same y on every door.
- 2:22 AM: font sizes are not constant across doors; each door's words are sized to fill the block exactly. No row of words all one size if a mixed one fits.
- Codex era: band fixed at 354 x 124 pt. Too few words: repeat words in other colors and sizes. The lower section is the Folio, a real page curl (horizontal curls left, vertical folds top to bottom) while the band stays. Areas gather notes across doors. Turn words name the neighbour notes by title. A "Titles" word opens a searchable title list. A small card per note. An open note shows title, updated date, content, then Areas. The areas pane is glass (translucent, no border, no rim): an exception he asked for. No diagonal arrows.

## Page (402 x 874 pt frame, 24 pt gutters)
- y 44: back word ("Notes", or "All notes" inside an area), 15 pt Figtree 600, room color, 44 pt target.
- y 58: door or area name, Figtree 700 34 pt, in its color. One line under, 16 pt ink 2 ("7 notes across 5 doors.", "38 notes, the newest an hour ago.").
- Band: x 24-378, y 140-264 (354 x 124). The word wall (below).
- y 292: header row, 13 pt small caps ink 2 ("Newest first", or "7 notes in Home") left; "Titles" 15 pt 600 room color right.
- Folio: x 24-378, y 324-726 (354 x 402). Three cards a page.
- y 734: turn words, 15 pt 600: left names the previous page's last note, right names the next page's first note, by title. Nothing shows on the first or last side. No counters, no arrows.
- Bottom left: the door's action word (New note, New idea, Ask Tess, Record, New private note, Restore). Tess bottom right.

## Word wall (band)
- Same packer as v2: each note once, newest first; every gap is same stack, next brick or next row; all 3^(n-1) tried (n <= 10); rows meet both edges; uniform scale within 8% so the last row meets the bottom.
- Score: nearest no scale; a newer row never smaller; neighbouring rows differ 25% or more; rows of 3+ equal words cost most, rows of 2 cost some; no word under 13 pt.
- Too few titles to fill: titles repeat (second pass, color shifted 7 steps along the palette so a repeat never matches its first copy, a different size by the packer). Fillers and split titles from v2 are dropped.
- Tap a word: the Folio turns to that note's page and the card lifts (260 ms).

## Folio
- Card: title 18 pt Figtree 700, when right 13 pt ink 2; one line 15 pt ink 2 cut at a whole word; area words 13 pt 600 in each area's color at the card's foot. Card ground is room-tinted (color-mix 6%), radius 18, no border, no shadow. Tap opens the note in place of the Folio (band stays).
- Turn: drag on the Folio. The axis locks after 8 pt: sideways curls the page from the right edge (fold line tilt 22 sin(pi t)), vertical folds from the bottom (tilt 16). The front is clipped at the fold; the flap shows the page's back (gradient, crease line) and a contact shadow falls on the page under. Past one third it turns; else it springs back. Turn words and taps turn it too: 720 ms ease-out cubic. Pointer capture only after the axis locks, so taps on cards still work.
- Reduce Motion / Low Power: cross-fade 200 ms, no curl.

## Titles
- Tap "Titles": the Folio area becomes a search field (Figtree 600 22 pt, room color caret) and every title in this door or area, newest first, 18 pt 600 with when at right; typing filters live. "Done" closes. Tap a title: opens that note.

## Open note
- Title (door's name position stays; note title 30 pt 700), "Updated Sunday." 16 pt ink 2, content 17/26 pt (Tess notes in Newsreader 20/28 Tess blue), detail 14 pt ink 2, then "Areas" 15 pt 600 room color followed by its area words in their colors. Action word becomes "Edit".
- Tap "Areas": the glass pane opens just under it: every area with its count (Outfit 13 pt ink 2), 17 pt 600 in its color; the note's areas bold. Background blur 16 pt, saturate 1.5, translucent ground, no border or rim. Tap toggles; tap outside closes.

## Areas
- Areas: Home, Kitchen, Trip, Work, Family, Health, Writing, Errands (palette c1, c9, c4, c10, c7, c6, c3, c2; none within dE00 10 of Ember). A note can carry several. Tap an area word anywhere: an area page opens with the same layout (back word "All notes", "7 notes across 5 doors."), its wall and Folio gather notes from every door.

## Private
- Private door shows titles on the phone after Face ID; off the phone they're counted ("3 private notes").

## Rejected
- v2 Ledger and Pages lists (replaced by the Folio). Fillers (day/detail words) in the wall. The dial on door pages.

## Open
- Folio card count per page: 3 (recommended) or 4.
