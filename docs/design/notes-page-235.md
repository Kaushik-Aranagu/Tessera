# 235 Notes inner page (board https://claude.ai/artifact/NRrJv7zKSUADwCGFw6tiQr)

Builds on 226 (landing) and 228 (Notes elements). Owner: Builder B (Notes).

## Palette (3 colors + ink, his 8:58 PM rule)
- Violet accent 5B3FB8 / B9A9E0 (6.8:1 on paper, 9.8:1 on black): the dial focus, the focused note title, the note page title, actions.
- Slate section labels 34506F / A7BCD6: small-caps "Note" / "Private" on the note page.
- Sienna 8A4B2A / E0A47F (6.2:1 / 9.8:1; ΔE from Ember 17 light / 10 dark): "fresh today" only, meaning ages under 24 h and the word "today".
- Everything else is ink / ink2. No underlines.

## List
- Dial 232 spec with lenses This week, Pinned, Private, All (loops). Focus 44 pt Semibold violet, neighbors 26 pt.
- Brief from templates on the phone, for example "6 notes this week, 2 pinned. Trip packing changed 2 h ago." A private note's name in the brief is shownLabel off the phone; inside the room it is the real name.
- Section line, right aligned at 13 pt ink2: "10 notes, pinned first, then newest first".
- Depth wheel, 228 pt band, loops:
  - Focus at the top slot: the title in violet Semibold at 26 pt, fitted down to 21 pt and then cut at whole words, with a small trailing word dropped and never "...".
  - Detail line 1 at 13 pt ink2: "today, 2 h ago, 36 words, pinned, private", with "today" in sienna.
  - Detail line 2: the first words in Newsreader italic 15 pt, whole words only, with a small trailing word dropped.
  - Other rows are 17 pt, stepping to 15 pt, ink2, with the age right aligned (sienna under 24 h). Depth blur is 0.65 pt at one row and 1.0 pt at two or more; none under Reduce Motion, Reduce Transparency or Low Power.
  - A row that would be cut at the band's bottom is hidden.
  - Tap the focused note to open it; tap another to bring it up.
- Order: pinned first, then newest first. Pins are capped at 3.

## Note page (slides from the right; back by the left edge)
- Header: the lens on the left; on the right "Today, 2 h ago" (sienna "Today") or "Edited 3 days ago".
- Title in violet, fitted 28 pt down to 21 pt and then whole words. Meta line: a slate small-caps "Note" or "Private" label, then "29 words, kept at the top" (singular "1 word").
- Body in Newsreader 19/26, paged vertically in 286 pt pages, with "1 of 2" at the right.
- Fixed lines "Keep at the top" and "Private", each with a Yes / No value that rolls on tap. Receipts: "Gift ideas, kept at the top. Undo", "Three kept at the top already. Unpin one first."
- Private note: a line under the switch reads 'Off the phone this reads "Private note": the Notes landing, notices, widgets, Siri and backups.'
- Foot: "Write" starts typing and becomes "Done". Saving stamps the note "just now" only when the text changed, with the receipt "Gift ideas, saved. Undo".

## Action word gestures (his 9:21 PM rule; spec in 230)
- List "Write": tap = new note; drag right = "Private note" (a new private note).
- Note page "Write": drag left = "Delete note" (back to the list with "X, deleted. Undo" for 10 s); drag right = "New note".
- While typing, "Done": drag left = "Put back" (discards the edits, "Changes, put back.").
- The word leans 18 pt at most. Past 56 pt it rolls to the option with a selection tick; release commits with a .medium impact. Each option is also an accessibilityAction.

## Privacy
- A private note's title and words appear only inside the Notes room. The landing headline, notices, widgets, Live Activity, Siri, Tess/Claude lines and backups use shownLabel ("Private note").
- Ordinary note text goes to Claude only with asksClaude on under lab mode, with a sent-log row. Private note text never goes (v2).

## v2, reviewer notes with the coordinator's rulings (Oct 23, 9:31 PM)
- Title fit stays: 28 to 21 pt on the page and 26 to 21 pt in the wheel focus (his 9:11 PM rule). The first-words line and the body text never shrink.
- Depth blur: never on the focused row or its first-words line. One switch, Settings > Look > "Depth on wheels" (default On), turns it off everywhere. It is also off under Reduce Motion, Reduce Transparency and Low Power.
- PRIVATE NOTE TEXT NEVER GOES TO CLAUDE, under lab mode too, unless he says otherwise himself. Ordinary notes go only with asksClaude on, each with a sent-log row.
- Private note bodies stay out of backups, like calories. A restore brings back a "Private note" stub with no words. The note page's private line adds: "Its words stay on this phone."
- Delete: the 10 s Undo, plus 7 days in a fifth lens "Recently deleted" (op log). That lens shows only when it holds something. Its rows read "Gift ideas, deleted 2 d ago"; tap to bring one back ("Gift ideas, back. Undo"). After 7 days a note is gone.
- Left drags on the action word start at the word, 28 pt or more from the edge, so they never fight the back edge (0 to 24 pt).
- Typing autosaves about every 2 s of quiet, and on leaving the page or the app, so killing the app keeps the draft. "Saved" receipts come only from Done. "Put back" returns to the text as it was when the note was opened. While typing, the body scrolls instead of paging; paging comes back on Done.

## v3, Oct 23 10:25 PM (his picks, relayed by the coordinator)
- SUPERSEDES the v2 line above: under lab mode, private note text MAY go to Claude ("Claude gets to see anything... for now"), each send with a sent-log row, and asksClaude still gates it. He may tighten this later. Everything else stays: off the phone the title reads shownLabel, private bodies stay out of backups (stub on restore).
- Blur stays on every wheel, behind "Depth on wheels".
- Pink and wine may be used, but sparingly.
