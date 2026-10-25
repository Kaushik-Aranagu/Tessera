# 82. Day log: empty, first day, and its side (E2)

**Kaushik's principle, in one line:** an empty log is not a failure and a first entry is not an event: the page keeps its frame, says one quiet thing, and then looks like every other day.

Board `mockups/daylog-82.png` (12 phones, Porcelain and Obsidian), recording `recordings/daylog-82.mp4` (Porcelain: empty, Tess writes the first entry and its wash dries, the day fills, the glance, the full side), study `studies/daylog-82.html` (`?play` records). Builds on `day-log-v1.md` (the first day, DL50 and DL67), `day-log-page.md`, `empty-states.md`, `every-side.md` (row "Day log: THE DAY, by word"), `no-dots.md`. Nothing here contradicts them; where it adds, it says so.

## The three fronts
- **Truly empty (first use):** the frame as in `day-log-page.md`: back word, "October" (Title 44), the side word THE DAY, TODAY in `ink` at the bottom, and under it "Your days write themselves here." (Body 21/400 `inkSecondary`). No dots, no streak, no empty days above (a log with no records has no past to list), no count, no guilt line, no Try line (the page fills itself), no line from Tess.
- **First day, one entry:** the quiet line fades (220 ms) and the entry rises 10 pt under TODAY (360 ms, 3 pt blur clearing), "18:40 Done: call the bank". The page now looks like a normal day with one line: no "first", no "Day 1", no praise. If Tess wrote it, her 2.8 s cobalt wash sits behind the text band and dries (no-dots.md). The quiet line never returns once any record exists, even a day later with nothing new.
- **A normal day, for comparison:** TODAY with four lines, WED 14 above in the quiet tier, TUE 13 as a 45% label. Identical type, the x 86 text column, the 64 pt foot. The first day is this page early.

## The side: THE DAY
- **Matches every-side.md** ("Day log: THE DAY, by word, because x moves by day"): the word THE DAY at the right of the title row (13/700, .08em, `inkSecondary`, y 104) opens it. **Proposal:** the right edge (last 32 pt, above 736) opens it too, since the window scrolls on y and the margin scrub is the left 80 pt; the word stays the guaranteed way. The middle never opens it. Product rules on the edge.
- **Facet:** FACTS for the day in view (today when the page opens).
- **Glance (stop 1):** right half from x 150. Label THE DAY, big fact "4 things" (lines of the day, 56 plus 21 unit), two named at 19 ("Push Day A", "Dal tadka"), "and 2 more" (named up to three, "and N more" from four), foot word ALL OF TODAY. One entry reads "1 thing" with the line named. Empty reads only "Nothing yet." (19, ink): no big fact, no zero, no foot word.
- **Full side (stop 2):** back word stays ‹ TODAY, Title "Thursday", context line "4 things" in `context` with DAY LOG at its right. Groups by kind, labels 13/700: TRAINED (name, "52 min, 9 sets"), COOKED, TASKS (Done 1, Added 2). Rows 40 pt, figures at 19 `inkSecondary`, tabular. Groups with nothing are absent. Money and weight never appear (a money or body question is "That stays on this phone."); a private note counts as "Private note" and never by its words. No chart, no comparison with other days.
- **Tess's line (side only):** computed on the phone, one line, under Home's caps: "3 of 4 came after 6 pm." With 1 entry or none she says nothing, and a first is not hers to announce. On the front she says nothing in any state, as `empty-states.md` has it.

## Access
- **VoiceOver:** empty: "Today. Your days write themselves here." (the quiet line is plain text, nothing like "empty" added). An entry reads "6:40 pm, Done: call the bank." The side is a custom action "Show the day" on the page and the word THE DAY is a button; nothing depends on an edge pan. Glance reads "The day, 4 things, Push Day A, Dal tadka, and 2 more." Full side: group labels are headings, each row "Push Day A, 52 minutes, 9 sets". A new first entry is announced once, as its line, after the quiet line is removed.
- **Dynamic Type (AX3 drawn):** times move above their text, text 32/38, TODAY label 20, the title 56; nothing truncates and the window scrolls with today still at the bottom. The glance's big fact stays 56 and its unit drops under it from AX1. Side rows go to one column, figure under the name.
- **Reduce Motion:** the quiet line and the first entry crossfade over 150 ms, the side is a 150 ms crossfade, haptics unchanged.
- **Obsidian:** ink 245,242,236 on #121014, quiet text at `inkSecondary`, the Tess wash #86B4FF at 16%. Nothing glows.

## Rows for Builder B's acceptance
1. A log with no records draws TODAY and the quiet line only; no past labels, no count.
2. The first record removes the quiet line and renders as a normal line, with no extra word or haptic beyond the line's own.
3. The quiet line never returns once any record exists.
4. THE DAY opens by word, by the right edge (if ruled), and by the VoiceOver action; empty shows "Nothing yet." only.
5. The glance count equals the lines of the day in view; "and N more" only from four.
6. Tess speaks on the side only, and not at 0 or 1 entries.
7. AX3: times above text, nothing truncates.

## Never
Dots, a streak, "Day 1", "first", "welcome", "no entries", "0 things", a guilt or nudge line, a Try line here, a count of empty days, money or weight on the side, red.

## Unresolved
1. Right edge as well as the word (proposed above).
2. Whether the side's facts may name the faint (unfinished) workout; drawn here with finished things only.
3. Tess's side line is a proposal ("3 of 4 came after 6 pm."); Research to give the rule set.
