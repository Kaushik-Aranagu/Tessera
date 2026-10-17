# Kitchen gap hunt 9: Recipes link reading and recipe page

*Static read of master 3c0f80a (Oct 17). Nothing built or run. "Verified" means read at the file and line given; "inferred" means it follows from the code and needs one run. PRs read: link reading #807 (3cb3210) and #810 (9739fa3); recipe page #803 (bdf22a0) and #808 (3c0f80a, recipe send G58). #811 is not merged and skipped. Files: `TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift` (RLR), `RecipePasteLink.swift` (RPL), `Features/Recipes/RecipePage.swift` (RP), `PortionDrum.swift` (PD), `PasteRecipe.swift`, `RecipesEntry.swift`, `TesseraCore/Sources/TesseraCore/Kitchen/{Recipes,Groceries,RecipeParser,RecipeImport}.swift`, tests `RecipePasteLinkTests`, `RecipeLinkTests`, `RecipeContextTests`, `RecipeSendTests`. Compared with `kitchen-gap-hunt-8-recipes-oct17.md` (G51 to G61) and `kitchen-acceptance-782-793-oct17.md`, plus `kitchen-error-states-acceptance.md` (ER1, ER5, ER14). G1 to G61 are not repeated.*

## What these PRs do to the open rows

| Row | State on master 3c0f80a |
|---|---|
| G54 link on Paste | **Still open.** #807 and #810 are Core only. `RecipePasteLink`, `RecipeLinkReader` and `RecipeLinkShelf` have no caller in `Features/` or `App/` (`grep` finds only tests). A pasted link is still one title line on the Paste screen. The Core half (read, offline keep, credential refusal, 50-link cap, Claude switch) is done and tested; the wire and the lines are not. |
| G57 drum stops at 12 | **Closed by #803** (`PD:13-15`, range 1 to twice the written size, 12 to 48; VoiceOver bounds use the same range). New crash risk on the same line: see G62. |
| G58 swipe to Groceries | **Closed by #808** for the three clauses it names (failure springs back with a line, "nothing to add" with no UNDO, per-row stop with a VoiceOver "Add to Groceries"). Residuals: G66, G67, G68, G70. |
| G59 title, "Untitled recipe", same paste twice | **Untouched.** |
| G60 context line | **Closed by #803** ("1 h 35 min", months, "last year", year on the Cooked list). Small residual in G72. |

## Summary

| ID | One line | Sev | Owner |
|---|---|---|---|
| G62 | A written size or time near the integer limit crashes the recipe page every time it opens | blocker | Core, Builder B |
| G63 | Link read: a timeout or a DNS failure says "That site won't let me read it" and drops the kept link; the 15 s cap says "Too big" | important | Core |
| G64 | A kept or saved link still carries its fragment and sensitive-looking query items | important | Core |
| G65 | "Recipe link, kept for later." has no door: nothing reads the shelf, nothing erases it | important | Builder B, Core |
| G66 | Swiping a recipe that is already on Groceries again says "7 added." for no change, with a fresh UNDO | important | Core, Builder B |
| G67 | The send's UNDO lives in page state: leave the page and it is gone, with no line left behind | important | Builder B |
| G68 | VoiceOver: every ingredient row offers "Add to Groceries", and each adds the whole recipe | important | Builder B |
| G69 | Dynamic Type: fixed 92 pt amount, two-line names, fixed drum, and a page that does not scroll | important | Builder B |
| G70 | The failed send has no warning haptic, no retry and not the ER14 private form | low | Builder B |
| G71 | A link read drops a private title line silently, so another line can become the title | low | Core |
| G72 | Small: "12 months ago", raw animations off MotionPolicy, and the clauses no test reaches | low | Builder B |

## Rows

### G62. A huge serves or time crashes the recipe page on every open

- **Gap.** `RecipeBook.serves` converts the stored number with `Int.init` (traps outside Int range), `PortionDrum.range` multiplies the written size by 2 (traps on overflow), and `RecipeCopy.duration` does `Int(minutes.rounded())` (traps on a huge or non-finite value). Nothing caps serves or time on the page and link paths; the 1 to 100 and 1 to 1440 limits exist only for Claude's reply.
- **Repro.** (1) A page whose recipe card says a yield of 9223372036854775807 (the parser reads the first number of the yield, `RecipeImport.swift:102-105`; the paste regex does the same, `RecipeParser.swift:129-135`, `Int(match.1)` succeeds up to that limit), or a total time of P99999999999999999D (`RecipeImport.swift:113-120`, no cap). (2) Save it and open the recipe: the stored number becomes a Double (`Recipes.swift:181`), `serves` traps (`Recipes.swift:62`), and so does the drum range or the duration. The recipe cannot be opened again, and there is no delete on the page.
- **Evidence.** `Recipes.swift:62`, `Recipes.swift:181-188`; `PD:14` (`2 * (written ?? 0)`; #803's test stops at 5000, `RecipeContextTests.swift:14`); `RP:585` (`Int(minutes.rounded())`); `RecipeImport.swift:102-120`; contrast the Claude-only bounds at `RLR` `outputIsUnsafe` (`serves` 1 to 100, `minutes` 1 to 1440). Inferred: the exact trap needs one run; the unchecked conversions are verified.
- **Severity.** Blocker for that recipe (a crash loop from web content), rare in practice.
- **Owner.** Core (clamp serves to 1 to 100 and time to 1 to 1440 in the parser, card reader and `CreateRecipe`), Builder B (saturating conversions in `serves`, `PD.range`, `duration`).
- **Fix.** Clamp at the three entry points and use `Int(exactly:)` or a clamp on every Double to Int read; add a test with 9223372036854775807 and with 1e20 minutes.

### G63. Link failures that are not "offline" are worded and kept wrongly

- **Gap.** Only `notConnectedToInternet`, `networkConnectionLost` and `dataNotAllowed` are offline. A timeout, `cannotFindHost`, `dnsLookupFailed` and `cannotConnectToHost` (what a Wi-Fi with no internet gives) fall to `default` and say "That site won't let me read it. Paste the text instead." The link is then taken off the shelf (`shelf?.remove`). ER5 rules the timeout as "Recipe link, kept for later." with the link kept. A hard 15 s cut mid-stream reads "Too big to read safely." (`Task.isCancelled ? tooBig`). #810 added `isOffline` and a test that pins `cannotFindHost` as not offline.
- **Repro.** (1) Join a Wi-Fi with no internet, or a slow page. (2) Read a link: "That site won't let me read it", and a link kept earlier is gone from the shelf; a slow stream reads "Too big".
- **Evidence.** `RLR:213-221` (switch with `default`), `RLR:245`, `RLR:196-203` (15 s deadline); `RPL:53-58` (remove on any non-offline result); `RecipePasteLinkTests.swift:103-104` (pins `.cannotFindHost` as not offline); `kitchen-error-states-acceptance.md` ER5.
- **Severity.** Important (wrong copy on the most common bad-network case, and a kept link is lost).
- **Owner.** Core.
- **Fix.** Treat `.timedOut`, `.cannotFindHost`, `.dnsLookupFailed`, `.cannotConnectToHost` and a deadline cancel as offline (keep, "Recipe link, kept for later."); remove from the shelf only on a read, a paywall, or a firm refusal; change the pinned test.

### G64. A kept or saved link still carries its fragment and sensitive-looking query items

- **Gap.** `stripTracking` removes `utm_*`, four click ids and a short list of secret names, but not the fragment, and not names such as `secret`, `signature`, `code`, `jwt`, `id_token`, `sid`, `email`, `passwd`. The result is written to `recipe-links.json` (`keep`) and returned as `sourceURL` for the recipe's source. #807's QA fixed credentials before the host only.
- **Repro.** (1) Paste a link such as a shared-recipe URL ending in a fragment that holds a token, or with an `email=` item. (2) Go offline and read it: the full link, fragment and item included, is written beside the store.
- **Evidence.** `RLR:312-326` (`secretQueryItems`, `stripTracking`; `URLComponents.fragment` is never cleared); `RPL:91-96` (`keep`); `RecipePasteLinkTests.swift:84-97` (only user and password are tested).
- **Severity.** Important (a file at rest and a saved source keep what the link's owner meant to hide); low likelihood.
- **Owner.** Core.
- **Fix.** Drop the fragment, and keep only an allow-list of path plus a small known query set (or drop the whole query when the host is not a known recipe site); test a fragment token and an `email=` item.

### G65. "Recipe link, kept for later." has no door, and the shelf has no eraser

- **Gap.** Offline keeps a link, and the line promises it is "kept for later", but nothing in `Features/` or `App/` lists the shelf, reads a waiting link on his tap, or calls `erase()`. Combined with G54 (no wire), the promise is Core-only. `erase()` was added in #810 "for anything that erases everything" and has no caller, so a future erase-all would leave the URLs behind unless it is wired.
- **Repro.** (1) Once G54 is wired, read a link offline. (2) Come back online: no screen offers the kept link; there is no way to remove it.
- **Evidence.** `grep RecipeLinkShelf Features App` is empty; `RPL:105-108` (`erase`), `RPL:87-89` (`waiting`); `kitchen-error-states-acceptance.md` ER1 ("reads only on his tap").
- **Severity.** Important once G54 lands; ship the wire and the door together so the line is true.
- **Owner.** Builder B (waiting row on the shelf or Paste, tap to read, a way to clear), Core (call `erase()` from the erase-everything path and any backup export list).
- **Fix.** One row per waiting link on Recipes ("Read" and "Remove", host only, never the whole URL), and wire `erase()`.

### G66. Swiping a recipe that is already on Groceries again says "7 added."

- **Gap.** `AddRecipeToGroceries` takes the recipe's old share off first, then adds it again, and counts `made` against a `before` set taken after that removal. The page then reads the count as new rows. Swiping twice at the same size says "Tacos, 7 added." both times with a fresh 10 s UNDO, though nothing changed, and rows he edited or partly joined are rebuilt. The page's own "7 to buy, on Groceries" line shows the rows are there.
- **Repro.** (1) Swipe the column on Tacos: "Tacos, 7 added." (2) Wait out the UNDO, swipe again (or use the VoiceOver action): "Tacos, 7 added." again.
- **Evidence.** `Groceries.swift:374-394` (remove then re-add), `:394-395` (`before` after removal), `:424-427` (`made`); `RP:236-240`, `RP:111-112`; `RecipeSendTests` has no second-send case. Inferred: needs one run to see the count.
- **Severity.** Important (wrong receipt, hidden rebuild).
- **Owner.** Core (compute `made` against the list before the removal, so an unchanged re-add is "nothing to add"), Builder B (the line).
- **Fix.** Count new rows against the pre-removal list; a same-size re-add with the same rows writes nothing and says "Tacos, nothing to add." with no UNDO; add the twice-in-a-row test.

### G67. The send's UNDO is page state and vanishes when the page closes

- **Gap.** The receipt and UNDO sit in `@State sent` for 10 s. Tap "Recipes" or Close inside that window and the UNDO is gone with no line left anywhere. The announcement was spoken once. Failed and nothing lines go through `TessVoice` (they survive); the added line, the only one with an UNDO, does not.
- **Repro.** (1) Swipe the column: "Tacos, 7 added." with UNDO. (2) Tap Close within a few seconds; open Groceries: seven rows, no way to take them back from the receipt.
- **Evidence.** `RP:100-104`, `RP:249-263`; `RP:240-247` (the other outcomes use `TessVoice.shared.say`); `RP:156-157` (no carry on disappear).
- **Severity.** Important (receipt without UNDO after leaving; the acceptance form is "UNDO 10 s" wherever he goes).
- **Owner.** Builder B.
- **Fix.** Hand the added line and its UNDO to the shared Tess line (as Pantry and Lists do) so UNDO survives navigation, or keep the page's line and also post it.

### G68. VoiceOver: each ingredient row's "Add to Groceries" adds the whole recipe

- **Gap.** #808 put `Button("Add to Groceries", action: onAdd)` inside every row's `accessibilityActions`, and `onAdd` is the whole-recipe send. On "2 cups flour" the action reads as adding flour; it adds all seven lines (and, with G66, rebuilds them). The container also has the same action. The rotor now lists the action once per row.
- **Repro.** (1) VoiceOver on, focus the flour row, open actions. (2) "Add to Groceries" adds every line.
- **Evidence.** `RP:340-345` (per row), `RP:350-352` (container).
- **Severity.** Important (the label promises one line, the effect is the recipe).
- **Owner.** Builder B.
- **Fix.** Keep the action on the "Ingredients" container only, named "Add all to Groceries"; keep "Show in metric" on the rows. Add a test for the label.

### G69. Dynamic Type: fixed widths and a page that does not scroll

- **Gap.** The amount column is a fixed 92 pt, names stop at two lines, the hero stops at three lines and scales to 60%, and the drum is a fixed 72 pt wide, 52 pt per row (`textRole(.titleNumber)` in a fixed frame). Only the ingredient list scrolls; the hero, the context line, the "N to buy" line, the step count and the key sit in a fixed stack. At the largest accessibility sizes the list gets a sliver and "1 1/2 tbsp" wraps or clips.
- **Repro.** (1) Settings, Accessibility, Larger Text at the largest size. (2) Open a recipe with 10 ingredients: the list is a few lines tall, amounts wrap in 92 pt, long names are cut at two lines.
- **Evidence.** `RP:319` (`frame(width: 92)`), `RP:327` (`lineLimit(2)`), `RP:185-186`, `RP:50-146` (the VStack), `RP:89-92`; `PD:21-23`, `PD:74`; no Dynamic Type test in `RecipeContextTests` or `RecipeSendTests`.
- **Severity.** Important (the Dynamic Type clause in CLAUDE.md).
- **Owner.** Builder B.
- **Fix.** `ScaledMetric` for the amount width, no line limit on names, put the whole page in one scroll at accessibility sizes (drum above the list), scale the drum's pitch; add an AX3 screenshot to the phone checks.

### G70. The failed send: no warning haptic, no retry, not the ER14 private form

- **Gap.** ER14 rules one warning haptic, "tap line retries", and "Private recipe didn't save. Try again." for a private recipe. #808 says "Didn't save that. Try again." for every recipe, once, with no haptic and a line that cannot be tapped; the column springs back, so a retry is a second swipe. The private line is safe (no title), but it is not the ruled form.
- **Repro.** (1) Make the add fail (a deleted Groceries list). (2) Swipe: the column springs back, one line, no haptic.
- **Evidence.** `RP:475` (`.failed("Didn't save that. Try again.")`), `RP:241-246`; `RecipeSendTests.swift:42-47`; `kitchen-error-states-acceptance.md` ER14.
- **Severity.** Low (the failure is now visible, which was the blocker in G58).
- **Owner.** Builder B.
- **Fix.** Pass `isPrivate` into the failure line, fire the warning haptic, and make the line a retry; extend `aRefusalSaysDidntSave` for a private title.

### G71. A link read drops a private title line silently

- **Gap.** `RecipeLinkReader.read` cuts private lines from the whole recipe text, including the title line the card or Claude wrote. If the title is the private line, the cut text starts at the first ingredient; the paste parser takes the first non-empty line as the title unless it opens with an amount (G59). The recipe saves under an ingredient name or "Untitled recipe", and Tess gives no sign anything was cut.
- **Repro.** (1) Read a link whose recipe is titled with a secret word or a body fact. (2) The text arrives without its title line; the title becomes the first name-first ingredient. Inferred: depends on `SecretWords.cut` treating that title as a private line.
- **Evidence.** `RLR:109-120` (`SecretWords.cut` on `text`), `RecipeParser.swift:53-54`, `:109`; contrast `Recipes`' "Private recipe" rule (`ObjectPrivacy.isPrivateRecipeTitle`).
- **Severity.** Low.
- **Owner.** Core.
- **Fix.** Keep the title line when only the title is private (it becomes a "Private recipe" on save) and cut the lines under it; say "1 line left out" in the read line when anything is cut.

### G72. Small residuals and untested clauses

- **"12 months ago".** `relative` uses `days / 30` below 365, so 360 to 364 days reads "12 months ago" and day 365 reads "last year". `RP:594-606`; `RecipeContextTests.swift:25-34` tests 3, 40, 94 and 400 only. Fix: switch to "last year" at 330 days or use the calendar's month difference; add 59, 60, 364 and 365.
- **Raw animations.** `PD:75` (`.animation(.easeOut)`), `RP:249` (`withAnimation`) and `RP:317` (`.animation` with a delay) bypass `MotionPolicy` (`.tesseraAnimation`, `withTesseraAnimation`); the drum's fade ignores Reduce Motion. Fix: route all three.
- **Untested clauses.** The view-level promises of #808 have no test: the column returns on failure and on "nothing", the swipe's `sent == nil` guard (the VoiceOver path has none, so a second send replaces the first UNDO), the 10 s hold, the announcement. `RecipeSendTests` covers `RecipeCopy.send` only. `RecipePasteLinkTests` has no test for a timeout, a mid-stream cancel, a fragment, or a page with an ingredient-only card and no steps (it falls to L2 and L3 and can end as "No recipe on that page" though the card had ingredients; `RLR:142-149`, inferred).
- **Owner.** Builder B (first three), Core (the last).

## Order of work

1. G62 first (a crash from web content), then G63 and G64 (Core, small, testable).
2. G54 wire, G65 and G63 go together so "kept for later" is true on screen (Builder B with Core).
3. G66 and G67 before anyone relies on the swipe's receipt; G68 and G69 are VoiceOver and Dynamic Type passes on one file (`RecipePage.swift`).
4. G70 to G72 as lows.

*Wording note: no key-shaped text in this file; the repro for G62 and G64 uses numbers and URL shapes only.*
