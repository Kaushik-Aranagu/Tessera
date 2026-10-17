# Key shapes on the recipe paste-link shelf: what is refused, stripped or stored (PR #845)

For: Core, Builder B, QA. Date: 2026-10-17 · Research lab
Subject: a pasted text or link that the Recipes shelf keeps for later (the offline "Recipe link, kept for later." path, `RecipeLinkShelf`, `recipe-links.json`) must never store or echo a Claude-key-shaped string. Format follows `capture-all-but-key.md`.
Code read: working tree of master in /home/user/Tessera. Nothing run, no key used. No key, key prefix or key-looking literal is in this file; every shape is built in the test (section 2).

## 1. How the path runs (what each row is traced against)

1. `PasteRecipe.swift` `onChange(of: text)` runs three things in this order: (a) `RecipePasteLink.isSecretLink(new) || PasteCopy.hasSecretLink(new)` (link with userinfo): line `RecipeLinkLine.secretLink`, box cleared, return; (b) `PasteKeyFilter.change` (`looksLikeClaudeKey(new)` then `PasteCopy.withoutKeys`, which is `withoutClaudeKeys` and then empties the text if anything key-shaped is left); (c) the brush read.
2. `looksLikeClaudeKey` (`ClaudeKeyGuard.swift`) matches the prefix case-insensitively anywhere in the text, with whitespace around its dashes, any dash U+2010 to U+2014 or U+2212, and with the last dash missing when a digit follows within 8 letters. `withoutClaudeKeys` cuts the prefix, the rest of that word, and long digit-bearing runs of 8+ characters after it that a line break or space split off.
3. `RecipePasteLink.bareLink` returns nil for any text that is not one whitespace-free https/http/www word, **or that looks key-shaped anywhere in it**. So a link with a key in it is never a link and never reaches `RecipeLinkShelf.keep`.
4. `RecipeLinkShelf.keep(url)` refuses userinfo, then stores `stripTracking(url).absoluteString`: fragment dropped, userinfo dropped, tracking and secret query names dropped, and any query **value** that contains "@", looks key-shaped or is a 24+ character opaque token dropped. It has **no key check of its own** on the path or on a query name.
5. Save: `PasteCopy.save` calls `duplicateLine` (echoes `existing.title`), then `CreateRecipe.apply`. `CreateRecipe` has **no key guard**: the title (`parsed.title`), `sourceText` (`SecretWords.cut` only, which cuts secret words, not keys), ingredient lines and steps are stored as given. The only key defence for a body paste is step 1(b) in the view. A refusal logs through `CaptureMissLog.record`, which drops key-shaped text whole.
6. The retry inbox (`TessInbox.add`) belongs to the capture path. The Paste screen never calls it; a pasted link goes to `RecipeLinkShelf` only. `TessInbox.add` has its own key check.

## 2. Test material (built in the test, nothing key-shaped in this file)

- `PFX` is the Claude key prefix, assembled in the test from its two halves and two dashes, exactly as `KeyShapeTests` does.
- `FILL` is 20 filler letters (lower-case `x`), `FILL40` is 40 of them, `FILLD` is `FILL` with one digit inside it (the digit matters for the tail cutter and the missing-dash shape).
- `KEY` is `PFX + FILL`. `HOST` is `example-kitchen.test`. `LINK(p)` is `https://HOST/` plus `p`.
- Expected words: **REFUSED(secretLink)** is the line "That link has a password in it. Paste the text instead." with the box cleared. **REFUSED(keyLine)** is `claudeKeyLine`, "That looks like a Claude key. It goes in Review, under Claude." **STRIPPED** means the key text is cut and the rest is kept. **STORED** means the text is written as is. Marks: **traced** = I read the path and know the result; **inferred** = reasoned from the regex or a neighbour, not followed end to end.

## 3. Rows

| ID | Paste or stored thing (built in the test) | Expected | Result today | Mark |
|---|---|---|---|---|
| PL01 | `KEY` alone as the whole paste | REFUSED(keyLine); box empty; nothing on the shelf, no recipe, no miss log | matches: `withoutKeys` leaves "", `refusedKey` shows the key line | traced |
| PL02 | `KEY` upper-cased as the whole paste | same as PL01 | matches: guard is `(?i)` | traced |
| PL03 | `KEY` in mixed case (alternating case across the prefix and fill) | same as PL01 | matches | traced |
| PL04 | `LINK("recipes/" + KEY)`: key inside the URL path | REFUSED(keyLine); the key and the rest of that word are cut, leaving `https://HOST/recipes/`; nothing kept | `bareLink` is nil (key-shaped), so no shelf write; filter cuts, leaves a plain host-and-path link in the box that he can still tap Read on. Key never stored | traced |
| PL05 | `LINK("chili?id=" + KEY)`: key as a query value | REFUSED(keyLine); cut leaves `https://HOST/chili?id=`; shelf holds nothing for this paste | same route as PL04. If it were passed to `keep` directly, `stripTracking` drops the value (`looksSensitive`) | traced |
| PL06 | `LINK("chili?" + KEY + "=1")`: key as a query **name** | REFUSED(keyLine); shelf empty | paste route is clean (cut). A direct `RecipeLinkShelf.keep(url)` keeps it: the name is not a secret name and only values are checked | traced (paste route), gap G1 (direct keep) |
| PL07 | `LINK("chili#" + KEY)`: key in the fragment | REFUSED(keyLine) on paste; if ever kept, fragment already dropped | paste route cut; `keep` drops every fragment (`parts.fragment = nil`), so STRIPPED even without the guard | traced |
| PL08 | `"https://" + KEY + "@" + "HOST/chili"`: key as userinfo (user part) | REFUSED(secretLink); box cleared; not echoed | step 1(a) wins before the key filter: the line is secretLink, not the key line. Key never stored | traced |
| PL09 | `"https://user:" + KEY + "@HOST/chili"`: key as the password | REFUSED(secretLink) | same as PL08 | traced |
| PL10 | `KEY + "@HOST/chili"` with no scheme | REFUSED(keyLine); cut leaves "" or the host part only | not link-shaped (no https/www prefix), so (a) does not fire; the key filter cuts the word whole including the "@host/chili" tail (the tail is part of the same word) | inferred |
| PL11 | `LINK("chili/")` then a line break, then `KEY` | REFUSED(keyLine); `https://HOST/chili/` kept in the box | whitespace makes it not a bare link; the filter cuts the key and its tail; the box then holds one bare link again | traced |
| PL12 | `LINK("chili/" + PFX_first_half)`, a line break, `PFX_second_half + FILL`: prefix split across the break between dash and next half | REFUSED(keyLine) | regex allows `\s*` around the dash, so the split prefix is caught and the tail cutter takes the fill | traced |
| PL13 | key whose filler is split by a line break after the prefix: `PFX + 10 filler letters + digit`, break, `10 more filler letters` | REFUSED(keyLine); second half cut too | tail cutter removes a following 8+ run only when it contains a digit (`(?=\S*\d)`): here the digit is in the first half, so the second half (no digit) **stays in the box** as a stray run of letters. No key prefix, but part of the fill is left | traced; gap G2 |
| PL14 | same as PL13 but the digit sits in the second half only | REFUSED(keyLine) | `PFX` + first half is cut with its word; the second half has the digit and is 8+, so it goes | traced |
| PL15 | `PFX`, two spaces, then `FILLD` (extra spaces between prefix and fill) | REFUSED(keyLine) | prefix match cuts the prefix and `\S*`; `FILLD` (digit, 8+) follows after `\s+`, so it goes too | traced |
| PL16 | prefix with a space inserted after its first dash, then `FILL` (KS06 shape) | REFUSED(keyLine) | `\s*` after the first dash catches it | traced |
| PL17 | prefix without its final dash, then `FILLD` (KS07 shape) | REFUSED(keyLine) | caught only when a digit follows within 8 letters; with `FILL` (no digit) it is **not** caught | traced; gap G3 for the no-digit form |
| PL18 | prefix with a space **inside** a half (a break between its first two letters, or inside the middle word) | REFUSED(keyLine) | regex allows whitespace only around dashes, not inside the first half or the middle word: **not caught**, key stays in the box and can reach a title or the shelf | traced (regex read); gap G4 |
| PL19 | prefix with a zero-width space or soft hyphen between letters (paste from a web page) | REFUSED(keyLine) | not whitespace in the regex, **not caught** | inferred; gap G4 |
| PL20 | key percent-encoded inside a link path (the dashes as the encoded dash) | stored encoded, or refused | `looksLikeClaudeKey` does not decode, so the link is a normal bare link and `keep` stores the encoded path as written | inferred; gap G5 |
| PL21 | recipe body paste where the **title line** holds `KEY` ("Chili" + space + `KEY`) | STRIPPED: title becomes "Chili"; a refusedKey line shows | filter cuts before the brush reads; saved title is the cut text | traced |
| PL22 | recipe body paste where an **ingredient line** holds `KEY` ("2 cups beans " + `KEY`) | STRIPPED: line saved as "2 cups beans"; key line shows | same filter. Cut comes before `CreateRecipe`, so ingredient, `sourceText` and step text carry no key | traced |
| PL23 | the same body paste saved by calling `PasteCopy.save` or `CreateRecipe` directly (no view, no filter) | REFUSED or STRIPPED; nothing stored | `CreateRecipe.apply` has no key guard: title, ingredient name, step and `sourceText` are **STORED** with the key. `SecretWords.cut` does not cut keys | traced; gap G6 |
| PL24 | a page read from a link whose text (title or ingredient line) holds `KEY`, landing in the box via `readLink` | STRIPPED in the box; line says key goes in Review | the recipe text is assigned to `text`, so `onChange` runs the same filter. Separately `sendable` drops key lines before a Claude call | traced for the box; inferred for the fetched `ParsedRecipe` fields (no key guard in the reader's own output; only the view cuts) |
| PL25 | page `<title>` holds `KEY` and the page is kept offline | nothing stored (the shelf stores links only) | `RecipeLinkShelf` writes the URL string only; no title is ever stored there | traced |
| PL26 | saved title: an existing recipe whose title holds `KEY` (created before the filter, or by another route) | the title masked in every echo | `RecipeCopy.shownTitle` masks only private titles; a key in a non-private title shows in the row, the receipt (`savedTitle`) and Tess's lines | traced; gap G7 |
| PL27 | "already on Recipes" duplicate line, existing title holds `KEY`, same text pasted again | line says "Private recipe is already on Recipes." or similar, never the key | `duplicateLine` (view and Core copy) echoes `existing.title` unless it is walled/private; a key in the title is **echoed** | traced; gap G7 |
| PL28 | "already on Recipes" duplicate line for a normal title, new paste holds `KEY` | STRIPPED key; line names the old recipe | the key is cut first, so the compared text has no key; the line holds only the old title | traced |
| PL29 | miss log: a refused save whose paste holds `KEY` | no line written | `CaptureMissLog.record` returns on `looksLikeClaudeKey(trimmed)`; the paste is dropped whole | traced |
| PL30 | miss log: refused save, paste holds a key shape that `looksLikeClaudeKey` misses (PL18, PL19 shapes) | no line, ideally | the guard misses it, the paste is **logged** with the near-key in `capture-misses.jsonl` | traced; gap G4 |
| PL31 | retry inbox: a pasted link or recipe with `KEY` | never queued | the Paste screen does not call `TessInbox`; nothing is queued from here. For a capture phrase, `TessInbox.add` refuses key-shaped text | traced |
| PL32 | retry inbox: `TessInbox.add` with a phrase that holds a PL18 shape | refused | `add` uses the same guard, so it is queued | traced; gap G4 |
| PL33 | whole paste is `KEY` while "Tess asks Claude" is off or the phone is offline | REFUSED(keyLine); no "kept for later" line | the filter runs on every change, before any read; nothing is kept and no network is touched | traced |
| PL34 | the offline line after a key-in-link paste: `RecipePasteLink.read` is never reached | no "Recipe link, kept for later." for a key-shaped paste | `bareLink` is nil, so the Read button is not drawn for the raw paste; after the cut a clean link may be tapped and kept (PL04) | traced |
| PL35 | link kept on the shelf from a tap, later read again after relaunch, shelf file holds an old entry written before the key rule | the entry is masked or removed on load | `waiting()` returns whatever the file holds; no key check on load, and the Paste screen shows the host, not the whole path | inferred; gap G8 |
| PL36 | key as the only host label: `https://` + `KEY` + `.test/chili` | REFUSED(keyLine); cut leaves "https://" | key-shaped, so not a bare link; filter cuts the word whole (host included) | inferred |
| PL37 | redirect: a kept link redirects to a final URL whose path or query holds `KEY` | final URL never stored | the shelf keeps the **pasted** link (`keep(link)` in `RecipePasteLink.read`), not the final URL; `sourceURL` goes through `stripTracking` but its path is unchecked, so a key in a redirected path could reach a saved recipe's source link | inferred; gap G9 |

Counts: 37 rows. Inferred: 6 (PL10, PL19, PL20, PL35, PL36, PL37). Traced: 31. Rows where today's result differs from the expected outcome: PL06 (direct keep), PL13, PL17 (no digit), PL18, PL19, PL20, PL23, PL26, PL27, PL30, PL32, PL35, PL37.

## 4. Gaps and owners

| Gap | What | Owner | Suggested fix |
|---|---|---|---|
| G1 | `RecipeLinkShelf.keep` has no key check; a key-shaped query name, or a path key, is stored if `keep` is called without the paste route | Core | `keep` refuses `looksLikeClaudeKey(link.absoluteString)`, one line |
| G2 | tail cutter removes the next run only when it holds a digit; a split fill with no digit leaves letters behind | Core | decide: cut any 8+ run right after a cut key, or accept (prefix is gone, so the remainder is not a key) |
| G3 | missing-last-dash shape is caught only with a digit within 8 letters | Core (decision, `KeyShapeTests` KS07 says digit-bearing) | keep, or widen with a length test |
| G4 | prefix with whitespace inside a half, zero-width or soft-hyphen characters, or fullwidth letters is not caught; the miss log and inbox use the same guard | Core | fold ignorable characters and compatibility forms before the match in `looksLikeClaudeKey` and `withoutClaudeKeys` |
| G5 | percent-encoded key shapes in a link are not decoded | Core | match on the decoded string as well |
| G6 | `CreateRecipe` stores a key-shaped title, ingredient or step when called without the view | Core | guard in `CreateRecipe.apply` (refuse, or `withoutClaudeKeys` on `parsed.source` and title) |
| G7 | duplicate line and `shownTitle` echo a key-shaped existing title | Core (`duplicateLine`), Builder B (`RecipeCopy.shownTitle`, `savedTitle`) | mask a key-shaped title like a private one |
| G8 | old shelf file entries are not re-checked on load | Core | filter in `waiting()` |
| G9 | a redirected final URL is not key-checked before it becomes a source link | Core (`RecipeLinkReader`) | run `stripTracking` plus the key check on `sourceURL` |
| B1 | After a key-in-link cut the box holds a clean link and the key line shows; confirm the copy ("goes in Review") does not read as an error on a clean link | Builder B | read-only check on the line and Read button |
| B2 | Tap-target and line for PL08/PL09 (key as userinfo) shows the password line, not the key line | Builder B | confirm this is the wanted line |

## 5. Swift Testing names Core can paste

All tests build `PFX`, `FILL`, `KEY` in the test (see `KeyShapeTests` for the pieces). Suite: `PasteLinkKeyShapeTests` in `TesseraCore/Tests/TesseraCoreTests/`.

```swift
@Test func aKeyAsTheWholePasteIsNeverALinkOrKept()               // PL01 to PL03 (lower, upper, mixed case)
@Test func aKeyInALinkPathIsNeverALinkOrKept()                    // PL04
@Test func aKeyInAQueryValueIsNeverALinkOrKept()                  // PL05
@Test func aKeyAsAQueryNameIsNeverKept()                          // PL06, fails today (G1) until keep() checks
@Test func aKeyInAFragmentIsNeverKept()                           // PL07
@Test func aKeyAsLinkUserinfoIsRefusedWithThePasswordLine()       // PL08, PL09
@Test func aKeyAfterALineBreakIsCutAndTheLinkSurvives()           // PL11
@Test func aKeyPrefixSplitByABreakIsCaught()                      // PL12
@Test func aSplitFillWithoutADigitLeavesNoPrefix()                // PL13, PL14
@Test func extraSpacesInsideTheKeyAreCaught()                     // PL15, PL16
@Test func aKeyMissingItsLastDashIsCaughtWithADigit()             // PL17
@Test func aKeyWithAnInnerSpaceOrZeroWidthCharacterIsCaught()     // PL18, PL19, fails today (G4)
@Test func aPercentEncodedKeyInALinkIsCaught()                    // PL20, fails today (G5)
@Test func aKeyInATitleLineIsCutBeforeTheRecipeIsSaved()          // PL21, in TesseraTests via PasteKeyFilter
@Test func aKeyInAnIngredientLineIsCutBeforeTheRecipeIsSaved()    // PL22
@Test func createRecipeNeverStoresAKeyShapedTitleOrSource()       // PL23, fails today (G6)
@Test func aKeyInAFetchedPageTitleNeverReachesTheBox()            // PL24
@Test func theShelfFileHoldsLinksOnly()                           // PL25
@Test func aKeyShapedExistingTitleIsMaskedInTheDuplicateLine()    // PL26, PL27, fails today (G7)
@Test func theDuplicateLineNeverEchoesThePastedKey()              // PL28
@Test func theMissLogDropsAKeyShapedPaste()                       // PL29
@Test func theMissLogDropsEveryKeyShapeTheGuardCatches()          // PL30 (same fixture list as KeyShapeTests)
@Test func theInboxIsNeverFedByThePasteScreen()                   // PL31
@Test func offlineAndClaudeOffStillRefuseAKey()                   // PL33
@Test func aKeyShapedPasteNeverShowsTheKeptForLaterLine()         // PL34
@Test func aWaitingEntryWithAKeyIsDroppedOnLoad()                 // PL35, fails today (G8)
@Test func aRedirectedSourceLinkIsKeyChecked()                    // PL37, fails today (G9)
```

Assertions to reuse in each: the shelf file text, `sourceText`, every record title, the miss-log file text and the returned line contain no `looksLikeClaudeKey` match and none of `FILL`.

## 6. Rows I could not trace (end to end)

- PL10 (key plus "@host" with no scheme): the cut result depends on whether `\S*` stops at "@"; I read the regex, not a run.
- PL19 (zero-width and soft-hyphen shapes): how SwiftUI's TextField delivers those characters was not read.
- PL20 (percent-encoded key): I did not follow the URL loader; stored form inferred from `absoluteString`.
- PL24, fetched-field part: the `ParsedRecipe` fields a page fills outside the box (title and `sourceURL`) were not followed through `readLink` to a save.
- PL35 (old shelf file entries): file migration history not read.
- PL36 (key as the host label): inferred from `safeURL`. PL37 is now traced: `RecipeLinkReader` follows up to 5 redirects through `RedirectGuard` (RecipeLinkReader.swift:616), which checks each hop only with `safeURL`, never with the key check, so G9 stands.
- B1 and B2 in section 4: copy and layout, not code.
