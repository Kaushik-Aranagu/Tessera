# Pasted text and fetched pages: secret words (board item 137)

For: Core (the paste/link SecretWords wall) and QA. Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Sibling of `secret-words.md` (item 134), which set the rule for typed and spoken lines.

The "master today" column is a hand trace of master bb7f082. Nothing was run. Every value below is a made-up placeholder: the numbers are not real accounts and no card number here is real or card-length.

**Summary:**
- On master there is no wall on a paste or a page. `SecretWords` is used on the paste screen only to keep a failed save out of the miss log (`PasteRecipe.swift:202`).
- A pasted recipe saves its whole text as `sourceText` (`Recipes.swift:169`), shown as "Original text" (`RecipePage.swift:341`). A wifi line at the bottom is saved with the recipe and rides in every backup.
- The paste screen calls no model and no Claude. The link reader does: L3 sends up to 24,000 characters of page text to Claude (`RecipeLinkReader.swift:146`, body at `:369`). `RecipeLinkReader` is not wired to a screen yet (only `RecipeLinkTests` calls it), so the wall can land before it ships.
- The matcher splits on spaces only (`SecretWords.swift:16`). In a multi-line paste, a secret word that starts a line is glued to the line before it ("salt\nwifi") and is missed. Most pasted secrets start a line.

## 1. The rule

| # | Part | Default proposed |
|---|---|---|
| PR1 | **What the wall does** | **Default proposed: cut the line, keep the recipe.** Each line with a secret word and a value is cut before anything reads, stores or sends the text. The rest is read as before |
| PR2 | **Refuse the whole paste** | Only for a Claude key (as today), or when nothing but secret lines and blank lines is left after the cut. Nothing is saved |
| PR3 | **Where it runs** | In core, one function for both paths. Paste: before `CreateRecipe.apply` stores `sourceText` and before the miss log. Link: right after `visibleText`, before L2, before `ClaudeRecipeReader.read`, and on the card text and the video description too |
| PR4 | **Line by line** | Split on newlines first, then on any whitespace. Fixes the glued-token miss |
| PR5 | **Value test for pasted text** | Stricter than captures, since recipes are full of small numbers: 3 or more digits, a token mixing letters with digits or symbols, 3 or more spoken digits, or any word after ":", "is" or "=". "code 3" has no value. "combo" and "combination" need a digit value |
| PR6 | **Tess's line** | "I left out 1 line that looked private." (counts are digits). For PR2: "Only private lines here. Nothing saved." She never repeats the value |
| PR7 | **The cut line** | Dropped. Not saved in `sourceText`, not a private note (see Q1). On the paste screen it paints as ignored with no ink, so he sees what was left out |

## 2. Thirty-one rows

| # | What he pastes or the page holds | Verdict | Must never reach | Master today |
|---|---|---|---|---|
| P1 | Notes-app recipe, last line "wifi: TacoNet / tacocat24" | Cut the line | Claude, model, `sourceText`, miss log | Saved in `sourceText` (`Recipes.swift:169`). Miss-log guard misses it: "\nwifi" is one token (`SecretWords.swift:16`) |
| P2 | Share-sheet paste ending "door code 4417" | Cut the line | same | Saved in `sourceText`. Guard catches it ("code" isn't first on its line) |
| P3 | Shared family recipe note: "Grandma's iPad PIN 0420" | Cut the line | same | Saved in `sourceText`. Guard catches it |
| P4 | Dictated then pasted, own line: "Passcode is one two three four" | Cut the line | same | Saved. Guard misses it (line-initial word) |
| P5 | Notes dump: chili recipe, then "netflix password hunter2" | Cut the line | same | Saved. Guard catches it |
| P6 | Email signature under a recipe: "Conf line 555-0100, PIN: 7781" | Cut the line | same | Saved. Guard catches it ("pin", ":", value) |
| P7 | "Costco member # 1112 2233 4455" | Cut the line (new word, PL4) | same | No secret word. Saved, and miss-logged on a failed save |
| P8 | "Gift card code: X7Q2-PLMN-4417" | Cut the line | same | Saved. Guard catches it |
| P9 | Fetched grocery receipt page: "Account #: 0000 1234 5678" | Cut the line (PL4) | Claude, stored text | No secret word. If no card and no text recipe, L3 sends it to Claude (`RecipeLinkReader.swift:146`) |
| P10 | Fetched page, footer built from a `<div>`: "Member account 0000 1234 5678" | Cut the line (PL4) | Claude | Only real `<footer>` tags are stripped (`RecipeImport.swift:137`). This reaches Claude at L3 |
| P11 | Fetched page, inside `<footer>`: "Your order PIN: 4417" | Cut the line | Claude | Already stripped by `visibleText` (`RecipeImport.swift:137`). Safe today by luck of markup |
| P12 | Pasted link `https://example.com/r/7?password=hunter2` | Cut the item from the stored source URL | stored source, Claude | `stripTracking` keeps it (`RecipeLinkReader.swift:272`). One token, so no match |
| P13 | Pasted link `...?token=abc123XYZ&utm_source=feed` | Cut the item | stored source | `utm_source` dropped, `token` kept |
| P14 | Text that opens with the Claude key prefix | Refuse whole paste (PR2) | everything | Refused and cleared ✓ (`PasteRecipe.swift:119-123`) |
| P15 | "Bank PIN 0420 / alarm code 9912 / wifi: TacoNet tacocat24", no recipe | Refuse whole paste | everything | Save throws. Guard catches "pin", so no miss log ✓ |
| P16 | Video description: "Use code CHEF4417 for 10% off" | Cut the line (harmless: a promo line is never a step) | Claude, stored text | Video path (`RecipeLinkReader.swift:116`), not traced further |
| P17 | "WiFi - TacoNet pw tacocat24" | Cut the line (adds "pw", PL4) | same | No match: "wifi" needs ":" or "is", "pw" isn't a word |
| P18 | "alarm code 9 9 1 2" | Cut the line | same | Guard catches it |
| P19 | "garage 4417" (no secret word) | Passes. **Not caught**, listed so QA doesn't expect it | none | Saved, as for any line |
| P20 | "Book a table, zip code 94110 delivery only" | Cut the line. Matches `secret-words.md` S16: one matcher, and this line is page furniture, never a step or an ingredient, so the cut costs the recipe nothing | Claude | Saved / sent at L3 |
| P21 | Near-miss: "PIN the dough to the board with two forks" | **Passes unchanged** (no value) | none | `mentions` true, `hasValue` false. Only effect: a failed save isn't miss-logged |
| P22 | Near-miss: "Remove the pin bones from the salmon" | **Passes** | none | Same as P21 |
| P23 | Near-miss: "Use code 3 oven setting (fan)" | **Passes** (PR5: one digit is no value) | none | `hasValue` true: any digit counts (`SecretWords.swift:52`). The capture rule would cut a real step |
| P24 | Near-miss: "Account for resting time: 10 min" | **Passes** ("account" needs "#", "no." or "number" and 4+ digits) | none | Passes ("account" isn't a word) |
| P25 | Near-miss: "Pinch of salt" | **Passes** (whole words) | none | Passes ✓ |
| P26 | Near-miss: "2 cups spinach" | **Passes** | none | Passes ✓ |
| P27 | Near-miss: "A combination of spices: cumin, coriander" | **Passes** ("combination" needs a digit value, PR5) | none | `mentions` true, no value ✓. But "Spice combination: cumin" has a value after ":" today |
| P28 | Near-miss: marketing page "Sign up for our promo code!" | **Passes**. No value, so nothing private. A promo with a value (P16) is cut | none | No value ✓ |
| P29 | Near-miss: "Download the password-protected PDF" | **Passes** | none | "password-protected" is one token ✓. "password protected PDF" also passes: no value |
| P30 | Near-miss: "Pair with a Pinot noir" | **Passes** | none | Passes ✓ |
| P31 | Near-miss: "Step 4: cook code" | **Passes** ("code" is last, no value) | none | Passes ✓ |

Near-misses that must pass unchanged: P21 to P31, eleven rows. QA: paste P1 to P18 into the Simulator, save, then search `sourceText`, each ingredient's `original`, the miss log, the export JSON and a spy Claude request body for tacocat, hunter2, 4417, 0420, 7781, 9912 and 1234 5678. Every search must come back empty.

## 3. Gaps for Core

| # | Gap | Where | Default proposed | Owner |
|---|---|---|---|---|
| PL1 | No wall on paste or page text | `CreateRecipe.apply` (`Recipes.swift:169`), `RecipeLinkReader.read` (`:146`) | A core `SecretWords.cut(_:)` returning the kept text and the cut count. Both paths call it first (PR3) | Core |
| PL2 | Tokens split on spaces only, so a line-initial secret word is missed in any multi-line text | `SecretWords.swift:16` | Split on newlines, then all whitespace (PR4). Also helps the Ask bar guard (`TessModel.swift:74`) | Core |
| PL3 | Any digit is a value, so "code 3" would be cut | `SecretWords.swift:52` | PR5 for pasted and fetched text. Captures keep R3 | Core |
| PL4 | No words for accounts, members, cards or "pw" | `SecretWords.words` | Add "pw", "pwd", and "account", "acct", "member", "membership", "card" when followed by "#", "no." or "number" and 4+ digits | Core |
| PL5 | Stored source URL keeps secret query items | `stripTracking` (`RecipeLinkReader.swift:272`) | Also drop password, pass, pwd, token, key, auth, sig, session | Core |
| PL6 | No Tess line for a cut or a refusal | `RecipeLinkLine`, `PasteCopy` | PR6 lines | Core, Design |
| PL7 | No test proves Claude never sees a secret | `RecipeLinkTests` | P9, P10, P12, P13 with a stub session that fails if the request body holds a placeholder | QA |

## 4. One question for Product

Q1. Should a cut line become a private note? ★No, it is dropped. He pasted a recipe, not a note, and his source app still has the line. Tess says one line was left out. Yes: the cut line is saved as a private note, titled "Private note" (as in item 134).
