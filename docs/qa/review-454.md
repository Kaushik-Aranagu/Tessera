# QA review: #454 paste/link secret wall (Core, Research 137)

Head checked: `9607aca` (core/paste-link-wall, 1 commit). `git merge-tree` against master 20f0a16 is clean, and #451 doesn't touch these files. Static review only; Core reports 447 package and 137 app tests green.

**Verdict: PASS.**

## The four asks
- **Pasted recipes.** In `CreateRecipe.lines(of:corrections:)` (Recipes.swift:161-164), every `SecretWords.isPrivateLine` line becomes `.ignored` after the corrections are applied, so a re-read can't turn it back into an ingredient or a step. `sourceText` is saved from `SecretWords.cut(parsed.source)` (:173-174). A private first line can't become the title either: the title comes only from a `.title` line (RecipeParser.swift:83-84), and the override already made that line ignored, so the recipe falls back to "Untitled recipe". The test also checks that no object anywhere holds the value, and a paste made only of private lines throws, so nothing is saved.
- **Link results.** `RecipeLinkReader.read` wraps `readUnscreened` and cuts every returned text: the card, the page words, the video description and Claude's reply (RecipeLinkReader.swift:101-111). The L3 page text is cut before the trim, the estimate and the reserve. A page that is only private lines is never sent (:368-372).
- **Saved links.** `stripTracking` drops password, pass, pwd, token, key, auth, sig, session, access_token, apikey and api_key (:283-293). The test sends `?password=hunter2` and gets the clean URL back. The link test reads the actual request body sent to Claude and checks that CHEF4417, tacocat, the account number and hunter2 are all absent, and that the recipe words are present.
- **Near-misses P21-P31.** 14 pass rows are in `nearMissesPassUnchanged`. I traced several by hand: "PIN the dough", "pin bones", "Use code 3 oven setting", "Account for resting time: 10 min", "Spice combination: cumin" and "password-protected PDF".

**Also changed for captures:** `SecretWords.tokens` now splits on any whitespace, and the word list gains "pw" and "pwd". Both changes widen the capture wall from #422 slightly; neither narrows it. Example: "pw for gym locker 4417" now becomes "Private note, kept." Product should know, but no new line is added.

## What he sees (Design)
On the paste screen a private line now draws as an ignored line: his own text in `inkTertiary`, through the existing `.ignored` case (PasteRecipe.swift:333-337). No new copy is added, and PR6's "I left out 1 line that looked private." is not in this PR. Kitchen's paste-hardening acceptance (docs/product/paste-hardening-acceptance.md) says a paste-screen change needs a recording, so Design should get a short clip of a paste with a wifi line. Controls 7, 8, 16, 22 and 28 aren't touched by this diff.

## Lows (non-blocking)
- L1, a dead tap: tapping a private line on the paste screen cycles its correction, but the override keeps it ignored, so nothing changes on screen. Either skip the tap on private lines or say why (PR6's note would cover it).
- L2, over-cuts in recipe text (safe, but the line is lost from the recipe):
  - "Spice combination: 1 tsp cumin, 1 tsp coriander" is cut, because combination plus ":" plus a digit counts as a value.
  - "Pin: secure the roll with a toothpick" is cut, because ":" plus any word counts as a value for pin or code.
  - The PR5 rule ("code 3" passes) covers only the no-colon form.
- L3: a page whose visible text has no line breaks is cut whole if any secret is in it. Claude is then never asked and the link reads "noRecipe". This fails safe.
- L4: failed link results still carry the unstripped `url` as `sourceURL` (RecipeLinkReader.swift:108-121). Nothing saves a failed link today. If that changes, strip it there too.
- L5: `secretQueryItems` doesn't include `code`, the OAuth return code. Add it if links from sign-in flows are ever saved.
