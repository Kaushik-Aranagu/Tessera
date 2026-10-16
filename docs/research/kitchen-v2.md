# Kitchen v2 scouting: pantry light and recipe from a link

For: Kitchen lead, Core engine · 2026-10-15

## 1. Pantry that isn't a chore

**Why people drop pantry tracking.** The cost is entering and updating stock, not reading it. Grocy is the extreme case: a writer who tried it gave up because onions don't come in countable units, every recipe needed exact quantities and rules, and she bought different amounts than the app suggested ("the effort involved simply outweighs the benefits") [1]. Apps that last skip counts. Prepear's pantry is just a "things I always have" list that keeps staples off the shopping list, with a "still have it?" confirm [2]. Cooklang keeps a quantity file that it subtracts from the shopping list, which only works for people who will edit a file [3]. Pattern: once the app wants a number from you, you stop using it.

**Proposal: inference first, never a count.** Each `Ingredient` gets one inferred state, *in / low / out / unknown*, and a `lastBoughtAt`. Nothing asks the user anything.

| Event (already exists) | Inference |
|---|---|
| Grocery item checked or cleared after a shop (slices 6, 8) | its ingredient goes *in*, `lastBoughtAt = now` |
| `FinishCooking` (slice 5) | each non-staple ingredient used goes *low*; produce and fresh goes *out* |
| Staple flag (exists) | always *in* unless said otherwise |
| Time since `lastBoughtAt` passes its usual gap | *low* (rhythm, see below) |
| Ghost row "out of milk", "no eggs" | *out* and onto Groceries; "have rice" sets *in* |

**Running low from rhythm.** Once an ingredient has been bought 3 times, take the median gap between buys. Past 1.0x that gap it reads *low*; past 1.5x it is offered at the bottom of Groceries as a dim "usually by now" line, never auto-added.

**What can I cook.** Score each recipe by how many non-staple ingredients are *out* or *unknown*, ties broken by "not cooked lately". Show 0 missing first, then "1 missing: lemons". It is the shelf filter word already planned ("uses what's in the basket"), off by default.

**Smallest first version (engine, ~1 slice).** `state` + `lastBoughtAt` on `Ingredient`; the shop-clears-to-*in* and cook-marks-*low* rules; the "out of X" capture phrase; `RecipeMath.missing(recipe)` for the shelf. Leave rhythm for later, once there's purchase history to read. No pantry screen: state shows on the Ingredient page and as a dimmer weight on recipe lines you're out of. All of it undoable through the op log like any other write.

## 2. Recipe from a link, no model

**Coverage.** Google only shows recipe rich results for pages with schema.org `Recipe` markup, so nearly every food blog and big site ships it, mostly as JSON-LD (WordPress plugins like WP Recipe Maker and Yoast emit it) [4]. The open recipe-scrapers project parses JSON-LD, Microdata and RDFa, which confirms the same layer is the useful one across hundreds of sites [5].

**Field shapes to expect** [4]:
- `recipeIngredient`: array of plain strings, one per line. Feeds straight into the slice 2 line parser.
- `recipeInstructions`: one string, array of strings, array of `HowToStep` (`text`, optional `name`), or `HowToSection` (`name` + `itemListElement` of steps). Flatten sections into a heading line plus steps.
- `recipeYield`: number, "4 servings", or an array of both. Take the first integer.
- `totalTime` / `prepTime` / `cookTime`: ISO 8601 (`PT1H30M`).
- Gotchas: the Recipe may sit inside `@graph`, `@type` may be an array (`["Recipe","NewsArticle"]`), strings carry HTML entities and tags, a page can hold several JSON-LD blocks.

**Smallest first version.** Paste a URL in the ghost row or the paste surface. The main app fetches the HTML with `URLSession`, pulls each `<script type="application/ld+json">` block, finds the Recipe, and **writes it back out as plain text** ("Title / Serves 4 / Ingredients / ... / Method / ...") into the existing paste parser and paint-over screen. One code path. Keep the URL as `sourceURL` and the plain text as the verbatim source. No Recipe found: say "Couldn't read that page, paste the text instead." Skip microdata in v1 (rare now, add it if a site he uses needs it).

**Share sheet: v1.5, not v1.** A Share Extension that accepts web URLs (`NSExtensionActivationSupportsWebURLWithMaxCount`) is the nicest path. Even better, Safari's JavaScript preprocessing file hands the extension the page as Safari loaded it, so cookies, consent and login are already passed. Catch: getting the result into the app needs an App Group, which is an entitlement, and we have none (no paid account). Until then: Copy Link, then paste.

**Paywalls and consent walls.** EU cookie walls and bot checks (Cloudflare) can return a stub page to `URLSession`; NYT Cooking and similar may serve a cut-down page. Many still embed the JSON-LD because search engines need it. Don't fight it: no spoofed user agents, no cookie tricks, fall back to paste.

**Licensing and ethics.** US law: an ingredient list and simple directions aren't copyrightable; headnotes, stories and photos can be [6]. Keep it clean: store only the Recipe fields (no photos, no headnote), keep the source link visible on the recipe page, never re-share or publish, fetch only when he pastes a link (no crawling).

## Yes/no for Kaushik

1. **May Tessera fetch a web page when you paste a recipe link?** One request to that site, nothing else leaves the phone, no model. The ship list defers this pending a fetch policy. Pantry needs no decision.

## Sources

1. Digitec, "How I want to digitise the contents of my fridge and fail to do so": https://www.digitec.ch/en/page/how-i-want-to-digitise-the-contents-of-my-fridge-and-fail-to-do-so-39565
2. Prepear help, "How to use your pantry with your grocery list": https://help.prepear.com/hc/en-us/articles/360031261271-How-to-Use-Your-Pantry-With-Your-Grocery-List
3. Cooklang, Pantry management: https://cooklang.org/docs/use-cases/pantry/
4. Google Search Central, Recipe structured data: https://developers.google.com/search/docs/appearance/structured-data/recipe
5. recipe-scrapers (MIT): https://github.com/hhursev/recipe-scrapers
6. NYC Bar, "Secret Ingredients: How to Protect Recipes" (quotes the Copyright Office; Publications Int'l v. Meredith, 7th Cir. 1996): https://www.nycbar.org/wp-content/uploads/2023/05/20221024-SecretIngredientsHowtoProtectRecipes_FINAL_22.6.6.pdf
