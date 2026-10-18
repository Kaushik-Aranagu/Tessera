# 81. The Notes front: first use, a Private note, a long list, and its side

**Kaushik's principle, in one line:** Notes is a list of his own words, one plain line each; a Private note is only ever "Private note", and the side groups the list by what it mentions.

Board `mockups/notes-81.png`, recording `recordings/notes-81.mp4` (16 s, Porcelain, ends on the Notes page), study `studies/notes-81.html` (`?play` records). Item E1 of the 8:08 PM refill. Builds on 57 (`notes-grammar.md`: the page, the note, the writing line, the empty page), 75 (`every-side.md` row 22), 76 (depth) and the copy pass. Nothing in 57 changes; this sheet adds states and the side word.

## The front (unchanged frame, 57)
- **Frame:** ‹ REVIEW at 58, Title 44 at 84, context line at 146, writing line at 200, hairline at 232, rows from 280 + 46k, Tess's band 736 to 820.
- **The side's word:** BY THING at the right of the context line, Label 13/700 ink, at x right 22. It is the word that always works (swipe-more.md). Context line text is unchanged, "23 notes, the latest yesterday" (29 characters).
- **Times** are the copy pass's: "now", "yesterday", "Tue", "Oct 12".

## The three states
1. **First use, empty.** Context "A place for loose thoughts", the writing line, then "Nothing written yet." at Body 21, 66% ink, where the first row goes. No art, no guilt, no count. Tess: `Say "note: bar felt heavy" and I'll keep it here.` (57's line, kept).
2. **A Private note row.** The row reads "Private note" in place of the note's first line, at 100% ink, like any note (no dimming), with its time like any note ("Tue"). Its words appear nowhere else: not in the context line, not in the side, not in Tess's line, not in VoiceOver. A tap opens it for him like any note (his own phone; Face ID gating is not drawn, see Unresolved). A mention inside it is not counted under a thing on the side.
3. **A long list.** 23 notes, one line each; a long first line wraps to two (74 tall), never cut. The page scrolls as one sheet: the writing line and hairline scroll away, the back word stays pinned with a fade under it, and rows melt into Tess's band at 736 (a 40 pt fade, nothing under her line). Pull down at the top opens the area index (73). No search field, no section headers, no seams. Tess: "Landlord and Bench press come up most." (two named; the phone's fact, from the same counts as the side).

## The side: BY THING (LINKS), as every-side.md row 22
Matched, not changed: kind LINKS, "swipe or word", glance "23" notes, the top thing "Landlord, 4", "5 private" (a count, never named), as in the table at the foot of every-side.md.
- **Way in:** the right edge (glance, then full side), or the word BY THING. Notes has no run, so the middle swipe also goes in (76). Left edge out. Up and down only read. Reduce Motion: 150 ms crossfade (MotionPolicy). `.selection` once at the full side, no haptic at the glance.
- **Glance** (right half from x 150): label BY THING, big "23" with "notes" at 56/21, "Landlord 4", "5 private" at 19, foot word ALL OF THEM, the front at 30% under it. "Landlord" is the one top thing; the glance names one, so "and N more" never applies to it.
- **Full side:** context "23 notes", NOTES at its right, ‹ NOTES back word. MENTIONED lists each thing with its count at the right, most first (a note that mentions two things counts under both: counts, not sums); a tap on a thing goes to that thing's page. NOT ABOUT A THING: "Notes on their own", 9. KEPT PRIVATE: one line, "Private note", 5; no words and nothing tappable behind it. No controls on the side.
- **Empty side:** no big fact, so the right edge opens straight to the full side, context "Nothing written yet", and "Nothing to group yet." Never a dead swipe.
- **Tess's line** on both stops: "Landlord comes up most, 4 times." (the phone's counts; Research fixture).

## Names, several at once
A row never shows a list of names (a mention is a word inside the note's own line, ink at 600, 57). Where names are listed in a sentence, the house rule holds: two named, three named, "and N more" from four. Tess's front line names two. A note's page lists its links under LINKS (57) and its side says "and N more" from four (every-side.md).

## Accessibility
- **VoiceOver order:** back, Notes (heading), the context line, BY THING (button), the writing line (text field), then one stop per row reading its text then its time ("Sleep is training too, yesterday"); a Private note reads "Private note, Tuesday". Then Tess's line. The side is also a custom action, "Show by thing", because the swipe is VoiceOver's own. A written note announces "Note kept."; UNDO is 10 s under VoiceOver (one app-wide slot).
- **Dynamic Type:** one column to Accessibility 3 and beyond. Rows wrap in full and the time drops to its own line under its row; the context line wraps and BY THING drops under it; Title scales. Tess's line stays within the band at three lines at most, and VoiceOver always has the whole line.
- Row targets are the full row height, at least 44 pt. The Private note is full ink, so its contrast is the page's own; its words say what it is, so colour never carries the meaning alone.

## Obsidian
Same frame: bg #121014, ink 245,242,236, context #B8A3FF, Tess #86B4FF. Drawn: the list with a Private note, and Accessibility 3.

## Rows for Notes acceptance
1. Empty page matches state 1; "Nothing written yet." and Tess's line only.
2. A Private note row reads exactly "Private note" plus its time; no words anywhere (row, context, side, Tess, VoiceOver, Spotlight).
3. A long list scrolls as one sheet, back word pinned, rows fade into the band at 736, nothing cut.
4. BY THING opens by right edge, middle swipe or the word; glance and full side as drawn; the empty side reads "Nothing to group yet."
5. The side's private line is a count with no tap behind it; "5 private" on the glance equals the private line.
6. No "at" before a time, no "…", no dots, cobalt only in Tess's lines.
7. Reduce Motion crossfades 150 ms; Dynamic Type one column.

## Asks per builder team
- **Builder B:** `NotesView` row with the Private note form; BY THING word and `SideHost` wiring; the long-list fade and pinned back word; the empty side.
- **Core:** the by-thing counts through the walls (names of things only; a Private note contributes only to the private count).
- **Research:** fixtures for "Landlord comes up most, 4 times." and "Landlord and Bench press come up most."

## Unresolved
1. Does a Private note open on a plain tap, or behind Face ID? Drawn as a plain tap.
2. Is a note's privacy a mark he sets in the note, or detected (a key-shaped or secret string, #422)? The row reads the same either way.
3. "Notes on their own" is Design's name for unlinked notes; Product to accept or give other words.
