# 77. The rest of the sides

Sheet 75 declared a side for every screen and drew some. This sheet draws the eight it left, each as a glance (right half from x 150, one big fact and two small, the foot word) and the full side, on the front's spine.

- Board: `mockups/sides-77.png`. Recording: `recordings/sides-77.mp4` (37 s, Porcelain): each side goes front, glance, full, then back one stop at a time, ending on a front. Study: `studies/sides-77.html` (`?play` records).
- Rules held: no controls on a side, Tess's one line in her band at both stops (the same line), digits, "and N more" from four, context lines of 6 words or fewer, cobalt for Tess only. Reduce Motion: each stop a 150 ms crossfade (MotionPolicy), as in 75.

## The sides
| Screen | Side (kind) | Full side holds | Glance (big / small / small / foot) | Tess |
|---|---|---|---|---|
| Groceries | FOR WHAT (LINKS) | Groups by cook, soonest first: "TACOS, SUNDAY", "CHILI, TUESDAY", then "JUST BECAUSE" and one USUALLY line ("Rice and butter"). A row for two cooks shows once, with "also chili" | 7 *for 2 cooks* / "Tacos and chili" / "3 just because" / ALL LINKS | "7 for 2 cooks, 3 just because." |
| Routines | LAST TIMES (BEFORE) | One line each, newest first: "Push A, today" with how long, "Legs A, Wednesday  1 h 1 min" | Push A / "today" / "Pull A, Tuesday" / THE WHOLE STORY | "Push A, 4 times this month." |
| Recipe original | COOKS (BEFORE) | Each time cooked, newest first, with how long ("46 min", "6 h 55 min" from 60 min) | 4 *times* / "Thursday, 46 min" / "about 45 min" / THE WHOLE STORY | "Cooked 4 times, about 45 min." (median; none under 2) |
| Paste a recipe | WHAT I READ (PARTS) | All 17 lines in order. Kept lines plain; a plain ignored line shows its words dim with "ignored"; a private or secret-looking line shows only a bar and "ignored", never its words | 14 *lines kept* / "3 ignored" / "nytimes.com" / ALL OF IT | "14 of 17 lines kept." |
| The week (Settings) | WHAT LEAVES THE PHONE (FACTS) | The last 30 days' Claude calls by job (Today's lines 21, Plan my day 9, Your week 5, Recipe reading 3), each with what it sends in titles and counts; then rule 10's line. No money of his | "38 calls" *in 30 days* / "Today's lines, 21" / "Titles, counts, recipe text" (sheet 80) / ALL FACTS | "Today's lines made 21 of 38 calls." |
| Plans | THE PLAN (FACTS) | What it is (split, 4 a week, fixed days) and how it progresses (rolls on, primary 1 and secondary ½, under a range stays neutral) | 4 *days a week* / "Push Pull Legs" / "on fixed days" / ALL FACTS | "Session 11 of 26 this month." |
| A class page (Recipes) | ITS OBJECTS (LINKS) | Newest (3 named, "and 35 more"), most used (3), the fields every one has | 38 *objects* / "Newest, Dal" / "Most used, Chili" / ALL LINKS | "Chili is the one you cook most." |
| Any other object (Dune) | DETAILS, the default side (LINKS + FACTS) | Where it is linked from, then every field the front doesn't show (pages, started, added, from). No private field, none named | Reading / "412 pages" / "linked from 3" / ALL FACTS | "Reading since Oct 2." |

## Copy notes and calls for Product
- **Group names** read "TACOS, SUNDAY", not "Tacos · Thursday": copy-pass rule 8 bans " · " outside a pack size. Say if the Kitchen ruling should win.
- **Foot words** use the Research BQ set: THE WHOLE STORY for the two BEFORE sides, ALL OF IT for Paste (no ALL LINES in the set), ALL FACTS for the default object. DETAILS (the default side's word) is a proposal.
- **No money on the glance** (sheet 80, decisions 7:28): the big fact is "38 calls" in 30 days; the receipts' cost stays on the spend line only.
- Dune and Recipes are examples of an object and a class; the fixtures should vary them.

## For each builder team
- **Core (SideHost):** declare all eight sides, and the default object side from the class's fields not on the front plus its links; test that a private field never appears on it.
- **Builder B (Kitchen, Settings):** Groceries FOR WHAT (grouped by cook, "also" on shared rows), Recipe original COOKS, Paste's WHAT I READ (bar for private lines, count of kept and ignored) and The week's WHAT LEAVES THE PHONE.
- **Builder A (Training):** Routines LAST TIMES (the page owns the swipe; a row swipe stays DROP) and Plans THE PLAN after WEEK and MONTH become a run.
- **Kitchen:** the cook's name and day on each Groceries group, and the median for COOKS.
- **Research:** glance fixtures for the eight rows, and a test that a secret-looking paste line never reaches the side's text or Claude.
