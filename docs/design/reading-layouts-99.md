# 99. Reading layouts: one type layout for each kind of content

**Kaushik (Oct 18):** "We will need to find different layouts and designs based on what we are showing. Like the lists or paragraphs or notes or exercises details and so on." Built from Research's inventory (`research/fixtures/reading-layouts-inventory.md`, 123 rows). It sits on 86 C and 89 and adds no new font and no new size. Docs only: nothing here ships until Builder A or B takes a row.

## The finding in one line
The app has the right scale (16, 18, 21, 44, 56) but spends it badly. Three screens (Groceries, Home/Now, Exercise) carry 5 sizes at once, 18 and 34 are typed as literals in 13 places, the SF system font leaks in at two, and running text has three tokens (voice, body, field) for one job.

## A. Rulings (inventory section 5)
| # | Question | Ruling | Why |
|---|---|---|---|
| 1 | 18 and 34 | **18 is sanctioned** for two jobs only: text you type, and the one detail line under a lead. **34 is retired for words** (section heads fold to 16 strong, or to 44 when it is the screen's one title). 34 stays only as the third step of the long-hero step-down (56, 44, 34) and as a numeral. 17 is deleted. | 18 already carries every typing field and Tess's second line. 34 words are what push Home to 3 headings of different weight. |
| 2 | One running-text token | **`read`** = 21 regular, line height 28 pt, ink. `voice` stays only for Tess lines (21, cobalt). `body` becomes an alias of `read`. `field` (18) stays for typing only. | Same size, three wrap behaviours today. One token wraps the same everywhere. |
| 3 | Dynamic Type | `read` and `voice` scale to AX3 on rows and to AX5 on paragraphs; hero numerals cap at xxxLarge; at AX1 and up every kind drops to one column with the side below. 16 pt floor stays. | Matches type-and-motion tiers; ends the uncapped `voice`. |
| 4 | Reading width | **Paragraphs: 330 pt maximum, left aligned, ragged right** (about 34 characters at 21). Rows: gutter to gutter, one line. Tess: 270 pt as now. Above AX2 no cap. | Gutter to gutter is fine for one-line rows and wrong for sentences. |
| 5 | Numerals | Four roles: **21** inline, **28** row, **44** page, **56** hero. 24 and 26 fold to 28; 34 to 44 except the step-down. **80 (weight) and the reps/RPE instruments stay free** on the live workout ground only, never on a page you read. 72: Builder A confirms it is the same instrument as 80 before folding. | Numbers are the exercise page's voice, so they keep a ladder, not a free size. |
| 6 | SF system font | **Not allowed.** TrainingPage.swift:606 becomes 16 strong; ObjectPage.swift:488 becomes `read`. | One typeface. |
| 7 | Line rules | Rows: `lineLimit(1)` for names, 2 for lines you read, never 3 in a list. Wrapping is allowed only in a paragraph. At AX the one-line rows wrap to 2, never truncate a name. | Matches the existing Pantry, Recipe, Plans, Week, Exercise AX switches. |

## B. The layouts (each kind at most 3 sizes; colour from 86 C, area colour on the lead word only)

### 1. Notes: a paragraph you read, then edit
- Read view first (today a note opens straight in its editor at 18). Title **44** bold, key word first. Body **21** `read`, 330 pt column, 14 pt between paragraphs, no rules.
- Tap anywhere on the body to edit; the same words, same column, now at **18** `field` with the cursor. Size drops 3 pt on edit and settles back on leave in the house spring (150 ms crossfade under Reduce Motion).
- Sizes: 44 / 21 / 16 (the date, label strong). Lists of notes: one line each at 21, the first words of the body in 16 muted, hairline between.

### 2. Lists: short rows, one size
- Every item is **21** one line, tap to tick (strike through, one haptic). Heading is the list name at **44**; no hero tier inside a list. The Lists shelf stops ranking names by hero/title/body; its tier shows as the colour stage, not the size (inventory #7).
- Count and context: one 16 line under the title. Sizes: 44 / 21 / 16.
- Groceries: aisle name **16 strong** in the area colour (not 56 hero); in shop mode only, the aisle may rise to **44**. The 18 provenance line becomes the one detail line, shown only on the lead row.

### 3. Exercise detail: numbers first, then cues
- Order on the page: name 44; **today's number** at 56 (`titleNumber`); then three 28 row numerals (best, last, e1RM) with 16 labels under; then cues as `read` 21 in a 330 pt column; history below as rows of 21 date + 28 number.
- Sizes: 56 / 28 / 21, with 16 for labels. 44 appears only when the name is long and the hero steps down. 5 sizes today becomes 4 counting labels; the 44 name and 56 number never share a row.
- History date column: 92 pt fixed becomes the width of "Mon 12 Oct" at the current size, so AX does not clip.

### 4. Recipe steps: one step a screen
- Reading a recipe: ingredients as rows (`read` 21, amount 600 weight, left), then steps numbered with a **28** numeral in the left margin and the step in `read` 21, 330 pt column. The 18 numeral margin goes.
- Cook mode (no view exists; `cookModeReady = false`): one step at a time, step in **28 regular** (the one time body text rises), the step number and total in 16, one ink word "Next" at the bottom. A timer in a step shows as a 44 numeral beside it. Swipe sideways to turn (the page-turn setting from 90 applies).
- Sizes: 44 / 28 / 21 / 16 in the recipe, 28 / 44 / 16 in cook mode.

### 5. Paragraphs: Settings, Backup, Tess explaining
- Heading 44 (not 56 hero), then sentences in `read` 21, 330 pt, 20 pt between blocks, the action as an ink word. Section words 16 strong. Backup: drop the 56 head and the 44 "A restore is waiting" (it becomes 21 strong, tess colour). 4 sizes becomes 3: 44 / 21 / 16.

### 6. Receipts and the sent log
- Receipts (cleanest page today): keep 16 back / 44 head / 21 lines. Rule: the thing is named first, the amount second.
- Sent log (spec only): each send is a row: time in 16 (no "at"), what was sent in `read` 21 one line, tap to open the payload in plain `read` (full words, 330 pt). Masked sends read "Private workout" etc. at 100% ink. Sizes 44 / 21 / 16.
- Undo lines stay in the Tess band; they are `voice` 21, one line, no new layout.

### 7. Habits (no view yet; follows 85)
- Rows of 21, check on the right as an ink word, no streak. Heading 44. Sizes 44 / 21 / 16.

## C. Screens to refit, in order (Builder A takes training, Builder B the rest)
1. Groceries 5 to 3; Home/Now 5 to 3 (18 context goes into the 16 or the lead row's single detail line).
2. Exercise page 5 to 4 with the number ladder.
3. Backup 4 to 3; Lists shelf tiers become colour.
4. Remove the 13 `voice(size: 18)` / `voice(size: 34)` / `voice(size: 16)` literals and the two SF fonts by tokens: `read`, `field`, `label`, `titleNumber`.
5. Notes read view and cook mode are new work; Product slots them.

## D. Never
- A fourth size on a screen, or a size that is not 16, 18 (typing and the one detail line), 21, 28, 44, 56.
- The SF system font; italics; a pill or card around a paragraph.
- Truncating a name at AX; wrapping a list row to 3 lines.
- A faded or diffused Tess; a band at the top; new images in a reading layout.
- A literal size where a token exists.

## E. Not verified
Plein sizes only (Workshop and Machined not read); characters per line are estimates; no rendering run. Cook mode, Habits and the sent log are drawn as rules, not as built screens.
