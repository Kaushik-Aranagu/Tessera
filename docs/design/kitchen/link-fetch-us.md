# A recipe from a link, redrawn for US sites (Design item 32)

`kitchen-v2.md` L1 to L3, redrawn under today's rules: the page top (`day-seams.md` S4), Tess beside the soul with UNDO under her line (S1), the ink line, no dots and nothing coloured at rest (`no-dots.md`, `sweep-19.md`), and amounts as written for a US kitchen (`us-shop.md`). Where this sheet and `kitchen-v2.md` L differ, this sheet wins; L carries a pointer. Failure cases follow Research's brief (`docs/research/recipe-link-fetch.md` §4); only the wording changed, so every line fits Tess's two lines.
- Board: `../mockups/link-fetch.png` (source `../studies/link-fetch.html`). Four takes, each at its end: a recipe card read from budgetbytes.com, allrecipes.com blocking the read, a Substack post with no recipe card that Claude reads, and an NYT Cooking paywall with the ingredients read.
- Recording: `../recordings/link-fetch.mp4` (44s, 60fps). The four takes in order: reading, the brush pass, a save with UNDO, and each failure.

## The page
The paste screen (sheet 11) on the look's own ground. No new screen.

| y | Element |
|---|---|
| 58 | **‹ KITCHEN**, the back word. From the share sheet or a ghost row it's still ‹ KITCHEN |
| 84 | **Paste a recipe** in Title 44 (S4). Once a recipe is read, **the recipe's name takes the title** (blur out 160ms, in 300ms on the house curve). A name wider than 346pt drops to Title 34, then wraps to 2 lines at 34. There's no separate promoted title in the list |
| 150 | Empty: **"A recipe's text, or its link."** in Body 21 `inkSecondary`, a quiet line (`empty-states.md`). With a link: **the link line**, host at 21/600 `ink`, path at 21/400 `inkSecondary`, one line, truncated at the tail. Once read: **FROM BUDGETBYTES.COM** in labels |
| 196 | Empty: **PASTE**, a label word on the ink line (16/700). After a failure: **the writing line** (below) |
| 182 → | **The recipe**, Body 21, 30pt apart. The source's own heads ("Ingredients", "Method", "Preparation") are label words in `inkSecondary`, 36pt apart. The amount is a 600 word, prep after a comma and a pack size after a dot are `inkSecondary` (`us-kitchen-pages.md` §1). Step numerals sit in the margin at x 20, labels in `inkSecondary` |
| last line + 40 | **Save recipe**, an ink-line word (Title 34 on the line, kitchen sage lens `rgba(18,147,106,.75)`). It follows the list and always ends above 720. A long recipe scrolls under the fixed top and fades out at 720, with Save recipe riding its end |
| 736 → 820 | Tess's band. Nothing on the page enters it |

**PASTE** keeps the build note from `kitchen-v2.md`: `PasteButton` drawn as the label word, or the edit-menu paste with a plain label word. Never a capsule.

## Reading
- The link lands at 150 (from 10pt below, blur 3 to 0, 300ms). A soft cadmium wash sweeps across it and loops (140pt, 1.4s, multiply, blur 5). No spinner. Reduce Motion: the link line breathes from 100% to 70%.
- Tess: "Reading budgetbytes.com…". A long host can take her second line ("Reading / sundaysupper.substack.com…"); past that the host truncates in the middle.

## When it reads (L1 recipe card, L2 the page's text)
1. The link line lifts away (up 30, scale 0.8, 300ms). The title becomes the recipe's name and FROM HOST sets in at 150.
2. The lines land from 182, fading up 6pt, 30ms apart.
3. **The brush pass** (sheet 11, redrawn for no dots):
   - Amounts get a cadmium under-stroke drawn left to right, which dries to 35% (`Theme.Motion.dry`).
   - Names arrive in sage and dry to `ink` over 700ms. There's no sage dab and no dot left behind.
   - Durations get a cadmium tick, and step numerals fade in at the margin.
4. Tess counts what she found: "Seven ingredients, three steps, two timers." When the page held several recipes: "Read the first of 3 recipes on that page."
5. **Save recipe** appears 40pt under the last line. A tap runs the sheen along its line. Then Tess says "Chili mac saved." with **UNDO** under it (10s). UNDO says "Chili mac taken back." and the page returns to the read recipe, unsaved.
- The recipe keeps its link: on its page, one level down, "From **budgetbytes.com**", with the host as a value word that opens Safari.

## When Claude reads it (L3)
- Only after L1 and L2 fail, and only when Settings says **Tess asks Claude: yes**. With no, L3 never runs and the page goes straight to "No recipe on that page. Paste the text instead."
- Tess: "No recipe card there. Asking Claude." **Three wisps** rise above the soul for as long as the request is out. This replaces the 22×14 cloud outline.
- The recipe streams in as a ghost, line by line, in wet cobalt breathing at 0.5 to 0.66, like every ghost. The title becomes the name as it arrives.
- The brush pass marks it. Tess: "Claude read it. Check it, then save."
- **Save recipe** dries the ghost to `ink` top-down (50ms per line), and the wisps fade. Then "Lemon pasta saved." with UNDO.
- Ink means the page's own words; wet cobalt means Claude's reading, until he saves.

## When it can't read it
Nothing is written, and there's no modal or error code. The link stays where it is. The **writing line** is a 0.5pt cobalt rule drawn left to right (420ms) with a caret, ready for pasted text.

| Case | What stays | Tess (each fits 2 lines) |
|---|---|---|
| Blocked (401, 403, 429, a bot check) | The link line, the writing line at 196 | "That site won't let me read it. Paste the text instead." |
| Paywall, ingredients read | The ingredients, read and marked; the writing line under the steps head | "The steps are paywalled. Paste them below." |
| Paywall, nothing read | The link line, the writing line | "That page is paywalled. Paste the text instead." |
| No recipe found (Claude off, or Claude found none) | The link line, the writing line | "No recipe on that page. Paste the text instead." |
| Claude timed out (20s) | The link line, the writing line | "Claude didn't answer in time. Paste the text instead." |
| Claude paused at the monthly cap | The link line, the writing line | "Claude's paused until Nov 1. Paste the text instead." |
| A video with a recipe in its description | The description, read and marked | "Read the video's description: 9 ingredients." |
| A video that links to a recipe site | The link line | "The video links to **budgetbytes.com**. Read that?" The host is a value word; a tap starts Reading on it |
| A video with nothing written | The link line, the writing line | "No written recipe in that video. Paste one instead." |
| Offline | The link line at 45% | "You're offline. I'll read it when you're back." It waits in `TessInbox` and comes back as a ghost recipe, never saved by itself |
| Too big or odd | The link line, the writing line | "Too big to read safely. Paste the text instead." |

## US sites in the study
Examples for the board and fixtures, not promises about any site; Research's fixtures decide what each one really returns.
- **A recipe card (L1):** budgetbytes.com, seriouseats.com, and most WordPress recipe-card blogs.
- **Blocks a read:** allrecipes.com is drawn as the blocked case.
- **No recipe card (L2, then L3):** a Substack post or a blog that writes the recipe as prose.
- **Paywall:** cooking.nytimes.com, with the ingredients read and the steps behind the wall.
- **Video:** YouTube, with a recipe or a link in its description.
- Amounts arrive as written ("1 lb ground beef", "1 can diced tomatoes · 15 oz", "½ lb elbow macaroni"), per `us-shop.md`. Nothing converts on read.

## Owners
- **Builder B:** the paste screen (`Features/Recipes/`): the S4 top with the name taking the title, the quiet empty line and PASTE, the link line and its wash, FROM HOST at 150, heads as label words, the redrawn brush pass, Save recipe as an ink-line word, the writing line, the wisps, and every Tess line beside the soul with UNDO under it.
- **Core:** L1 to L3 and each failure case mapped to its line, L3 skipped when the Claude setting is no, the "several recipes" count, and US amounts and pack sizes kept as written on read.

## For Research
These lines were shortened from `kitchen-v2.md` and the brief to fit two lines. Please check the wording:
1. "Got 12 ingredients. The steps are behind the site's paywall; paste them below." is now "The steps are paywalled. Paste them below." (the ingredients are on the page, so the count is dropped).
2. "That page is behind a paywall. Paste the recipe text instead." is now "That page is paywalled. Paste the text instead."
3. "Couldn't find a recipe on that page. Paste the text instead." is now "No recipe on that page. Paste the text instead."
4. "Couldn't read that page, and Claude is paused until 1 Nov. Paste the text instead." is now "Claude's paused until Nov 1. Paste the text instead." (US date order).
5. "That's a video without a written recipe. Paste the ingredients if you have them." is now "No written recipe in that video. Paste one instead."
6. "There were 3 on the page; I read the first." is now "Read the first of 3 recipes on that page." and replaces the count line.
7. New: "Claude didn't answer in time. Paste the text instead." (from Product's Plan my day timeout) and "Chili mac taken back." for UNDO.
