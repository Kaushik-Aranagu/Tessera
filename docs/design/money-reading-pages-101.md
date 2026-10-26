# 101. Money and Reading fronts under the paged-rows rule, sides declared

Product's refill item 3 (Oct 17, 7:40 PM PT). Applies sheet 90 (six rows a page, vertical swipe turns, sideways is the side) to `money-pages.md` and `reading.md`. Spec only; no study. Nothing here contradicts those two docs except where it says so.

## Money
**The month page is page 0.** "October, logged" with its one sentence is not a list, so it draws no rows and no peek rule beyond the hair of the first ledger word at 30% ink. A vertical swipe on it (plain text, so it turns the page) goes to the first ledger page. This replaces the old "swipe up lifts the month line" with the same motion read as a page turn: the month line lifts (-40 pt, fade) into the label "OCTOBER · 41 SPENDS" and the ledger page rises, in the chosen Page turn style (sheet 90).
**The ledger pages by day.** One day is one group and its day word ("THU 15") is the page's one word. A day over six spends splits at the nearest even break (sheet 90 rule 2); small neighbouring days share a page, at most two (two day words, one hairline). Newest first. Amounts stay tabular, right-aligned in the 104 pt column, never red; the day numeral at 34 Light stays in the margin. The rail appears from page 1; the month page counts as its first segment.
**Whose swipe.** The amount dial and the date chip own their vertical swipe (dial rolls, chip steps a day, absorbing at the limit with `.bound`, sheet 92 s1). On a spend page the hero amount does not own vertical: a swipe up there turns to the page of sentences ("Typed as spent 12.40 lunch." and the rest), which is page 2 of 2 for that spend. Swipe left on the hero still deletes (with UNDO). Pinch out/in between months is unchanged.
**Empty month:** one page, no rail: "October: nothing logged yet", Tess's cobalt line. Same as before.
**Side (declared): WHERE IT CAME FROM.** The word at the right of the context line, Label 13/700 ink. A glance of facts only: the shops and lists the month's spends came from, each a link ("Groceries, 5:40 shop"). No totals by word on the side (those are on the front), no controls, no money from Claude. A month with none from a shop: "Nothing came from a shop." The Money dial page declares none of its own: the dial owns vertical, and sideways is the same side as the month page.

## Reading
**The shelf pages by its three groups.** Page word is the group: READING (the book or two he is in; always its own page, Title 44/500 with "P 88" in Label tier), NEXT (oldest first, 28/500, 38 pt lines), FINISHED (newest first, 24/400 at 45% ink, 34 pt lines). A group over six splits as sheet 90 says (10 = 5+5); later pages keep the word. A shelf of six or fewer in total is one page and draws no rail. Type sizes per group stay as in `reading.md`, so a page of NEXT still reads quieter than READING.
**No counts.** The rail has no numerals, the context line has none, there is no "1 of 3". The peek is a hair of the next group word at 30% ink, nothing else. This keeps `reading.md`'s "never a count" rule: a rail segment is not a count.
**Whose swipe.** On the shelf, titles are plain text: a vertical swipe turns the page; a tap opens the book; holding nothing else. On the book page the page drum owns vertical (it coasts, ticks `.selection`, and absorbs at page 1 and the last page with `.bound`, sheet 92 (c)). The "one level deeper" sentences (author, pages, review) are page 2 of the book page, reached by a vertical swipe that starts anywhere except the drum. Finished (hold 0.6 s) and SET ASIDE are unchanged and unaffected by paging.
**A book finishing** still flies from its hero to the top of FINISHED; the destination page turns to meet it with the Page turn style (150 ms crossfade under Reduce Motion), once, with the existing bloom haptic and no extra one for the turn (sheet 90 R2).
**Empty shelf:** one page, no rail, Tess's cobalt line "Tell me what you're reading."
**Side (declared): WHEN.** The shelf's side word, Label 13/700 ink. A glance of dates, facts only: "Piranesi, started Oct 3" and finished titles with their finish date ("Dune, Oct 14"), newest first, paged like the front (six rows). Words not counts: the glance line reads "Last finished Dune." The book page keeps the object default side DETAILS (links and fields, sheet 77). A private book title or review reads "Private note" style: "Private item", never its words.

## For builders (not built)
- Both screens feed `PagedRun(groups:, pinned:)` from sheet 90; Money's pinned item is nothing (the dial is on its own page), Reading's is nothing. A run of six or fewer rows is one page, no rail.
- Rail neutral (ink 3 pt current, inkSecondary 2 pt others), area colour only in the text: Money and Reading take the colour of the area they are opened from (sheet 92 s2).
- Test: Money with 41 spends over 9 days gives day pages of at most 6; Reading with 14 finished gives 5+5+4; VoiceOver says the page word then the rows ("Thursday 15, 4 spends"), and the rail is not read.

## Drum haptics: Motion lab's default confirmed (Oct 17, 8:20 PM PT)
- Every drum-like control (the money dial, the date chip, the book page drum) ticks `.selection` per step, **capped at 25 ticks a second**; ticks past the cap are dropped, not queued.
- **The landing tick always plays**, even inside the cap, so the settle on the final value is always felt once.
- A hit at a limit plays `.bound` once per push (sheet 92 (c)), not per frame. Reduce Motion changes the coasting, not the ticks.
- This is one gesture (a continuous drag or flick), so it stays inside the one-haptic-per-moment rule; the ticks are the gesture's texture, the landing is its moment.
