# 247 Notes door pages (draft v2, Oct 24 4:30 PM PT; not yet approved)
Board: https://claude.ai/artifact/S4dqsoynjdQMRQsV9EPW5z (v4). Builds on 246 (landing).

His rules (2:08-2:22 AM):
- The dial is for landings ONLY. Deeper pages use another list form.
- ONE FIXED BLOCK on every door page (his 2:19 AM): the word wall is always x 24-378, y 140-272 (354 x 132 pt, about 60% of the landing's band). The list always starts at y 300 on every door. Nothing below moves from door to door.
- Font sizes are NOT constant across doors (his 2:22 AM): each door's words are sized to fill that exact block.
- No gaps, ever. No row of words all one size if a mixed one fits (his 2:22 AM).

Door wall algorithm:
- Each note once, newest first. Each gap between neighbouring notes is one of three things: the same stack (2-3 small titles stacked, each sized to the stack's width, so a row mixes sizes with no notch), the next brick in the row, or the next row. All 3^(n-1) choices are tried (up to 10 items).
- Every row meets both edges exactly. The whole wall may then scale by at most 8% (glyphs and spacing together, uniform) so the last row meets the block's bottom edge.
- Score: closest to no scale; a newer row is never smaller than the one under it; neighbouring rows differ by 25% or more; rows of 3+ equal words cost the most, rows of 2 equal words cost some. No word under 13 pt.
- Small doors: if titles alone can't fill the block, a two-word title may break into its words (stacked or across rows, never side by side, both in the note's one colour). Then, still short: the note's day and its detail line join as ink-2 fillers, always smaller than every title, never two fillers side by side.
- Tap a word: focuses that note in the list.

Page: back word "Notes" top-left (room colour), door name Figtree 700 34 pt in its colour, one line (16 pt ink 2), the block, the list at 300, the action word bottom-left per door (New note, New idea, Ask Tess, Record, New private note, Restore).

List, pick "Ledger": left column 84 pt names the group only where it starts (room colour, 13 pt small caps): Today, Yesterday, This week, Earlier; Mentions groups by kind. Titles are sized by how new they are, so lines never read all one size: Today 21, Yesterday 18, This week 17, Earlier 16 (Figtree 600; Mentions 19 for the top three, 16 after). When at the right (13 pt ink 2); one short line under (14 pt ink 2), cut at a whole word, no "...". Tap a note: it opens in place (title +3 pt, body 16 pt, meta 13 pt).
- From Tess reads as her voice (his 2:22 AM): no "Tess said" title. A small line "About <b>Run plan</b>" (13 pt, ink 2, the subject in ink 700) with the when at the right, then her own sentence in Newsreader, Tess blue, sized by group (Today 22, then 19, 18, 17); the open one shows all her words at +3 pt.
Alternative "Pages": four notes a page, title 22 pt 700, two lines under; "Older"/"Newer" word or a sideways swipe; no counters.
Voice memos show length in Outfit (units at half size) and the transcript start. Private: locked until Face ID ("Unlock"); several are counted ("3 private notes"), never "Private note" repeated.
Going in: the landing's words that belong to the door stay and re-pack; the rest dissolve. Moments as on the landing (no pile).
