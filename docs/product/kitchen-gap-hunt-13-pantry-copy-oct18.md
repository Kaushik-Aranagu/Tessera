# Gap hunt 13: Pantry copy and private lines (static read, origin/master 6899613b, Oct 18)

Static read only. Nothing built or run. "inferred" marks a reading I did not see executed. No key printed or stored.

## Part A: string and private-path check

Pantry strings checked against the rules (US English, lowercase clocks, the banned words, money only with amount, receipts thing-first with "on"): PASS for every user-facing string in PantryCopy.swift, PantryView.swift, PantryFront.swift, PantryLedger.swift, PantryDayWord.swift.
Strings: "Pantry"; context "since today's shop / yesterday's / Saturday's / the Oct 3 shop" (PantryCopy.swift:14-23); hero "4 out, 2 low / Nothing out / Nothing yet" (PantryLedger.swift:72-79); headers OUT / LOW (PantryView.swift:65); empty "Clear a shop or finish a cook and this fills in." (:34); Tess "Tacos took the cilantro and limes." / "Tacos took 5 things." (:28-31); receipts "Milk, on Groceries." / "Milk, already on Groceries." / "Milk, in the basket." (PantryCopy.swift:37, PantryFront.swift:38-41); error "Didn't save that. Try again." (PantryView.swift:115); VoiceOver "Milk, out", hint "Opens Milk" (non-private only), action "Add to Groceries" (:145-152); "bought today/Sat" (PantryDayWord.swift). The banned word appears only as a Swift identifier (PantryView.swift:114), not copy. No money, clock or em-dash strings.

Single-function check (G105): FAIL. Pantry calls `ObjectPrivacy.isPrivateRecipeTitle` (PantryLedger.swift:100 and :166), which is the F3 wall (label + PrivateFacts.isPrivateTitle + EngineWall.isHealth, no titleWords; ObjectPrivacy.swift:60-63). The widest, `PrivateWords.isPrivateTitle` (PrivateWords.swift:33-38), is still internal; `ObjectPrivacy.isPrivateText` is still internal (ObjectPrivacy.swift:91). The 4:20/4:22/4:35/4:50 titleWords trims are not applied (PrivateWords.swift:28-30 still money + health + care words).

Path trace, ingredient name raw when private:
| Path | Verdict | file:line |
|---|---|---|
| Pantry line, VoiceOver label, hint | masked; no tap target (R12/G102 holds) | PantryView.swift:134-151 |
| Swipe receipt, "already" and "basket" lines, UNDO | masked via entry.label | PantryFront.swift:38-41, PantryView.swift:119 |
| Tess cook line | private recipe silent, private ingredient left out | PantryLedger.swift:97-103 |
| Hero count | counts private lines as a number (kept, P-F2) | PantryLedger.swift:72-79 |
| Ingredient used only by a private recipe | RAW on the page (G139) | PantryLedger.swift:146-169 |
| Ingredient page and Linked-from rows | RAW (G141) | ObjectPage.swift:256-264, ObjectPrivacy.swift:40-56 |
| Day log text | counts only ("N groceries"), PASS; its links open the raw object page (G141) | DayStory.swift:283-288, 343-346 |
| Memory/turnover filter | narrower wall (G142) | TessMemory+Turnover.swift:69-70 |
| Home | only the word "Pantry"; no Pantry line at all | HomeSpatialView.swift:376-387 |
| Widgets, Spotlight, Siri, Live Activity, Claude packs | no Pantry surface exists (grep) | n/a |

## Gaps (G139 onward)

| # | Severity | file:line | Gap | One-line fix | Owner |
|---|---|---|---|---|---|
| G139 | blocker | PantryLedger.swift:146-169; PantryLedgerTests.swift:123-136 | A finished private-recipe cook writes state (E8, correct) but its ingredients then list by their real names under OUT and LOW ("Limes", "Ground beef" from "Wifi code lasagna"), while Tess stays silent for K89.1. The test pins only the hero count. Rule "an ingredient used only by private recipes is itself private" (core.md 5:16, PP07/M7) is unbuilt. | Make Entry.isPrivate true when every recipe line using the ingredient belongs to a private recipe; add `anIngredientUsedOnlyByPrivateRecipesIsPrivate` | Core engine |
| G140 | important | PantryLedger.swift:100,166; PrivateWords.swift:28-38; ObjectPrivacy.swift:91 | Pantry does not use the one widest function (G105): it uses F3 (no titleWords), so "Dentist" or "therapy" items print raw. Adopting F6 as it stands would over-mask "Blood orange", "Energy drink", "Rent car", "Sleep tea" (PP14) because the trims are not applied. | Apply the trims, make one public function, swap both Pantry call sites to it | Core engine |
| G141 | important | ObjectPage.swift:256-264,304,332,434; ObjectPrivacy.swift:40-56 | Ingredient page (and list item/list pages reached from Day log links and Linked-from) prints the raw title and the class line "object Advil : Ingredient"; `label(of:)` has no ingredient branch (same as GH11 G103). Pantry itself never links a private line, but Recipes and Groceries do. | Add ingredient, list item and list branches to `label(of:)` using the one function, label "Private item" | Core engine (label), Builder B screen (page) |
| G142 | important | TessMemory+Turnover.swift:69-70; HomeLines.swift:593-600 | Memory/turnover filter checks only secret words and `isWalled` (no health, no titleWords); Home's cook title is a hand-rolled copy of F3. A "Cooked <health or care title>" line can reach a memory line. | Replace both with the one function | Core engine |
| G143 | low | PantryView.swift:113-119; Groceries.swift:644-647 | One swipe has two walls and two receipt sources: Pantry speaks `PantryCopy.added(entry.label)` (F3) while the engine receipt/summary masks by `isHealth` or `AddListItem.kept`. Where they disagree, the stored summary and the spoken line differ (inferred). | Speak the engine receipt or share the one function | Core engine |
| G144 | low | PantryLedger.swift:99,104; PantryCopy.swift:28 | Tess line uses the full recipe title, not `shortName` (P-F3), so long titles make "Chicken tikka masala (weeknight) took the ...". | Pass `RecipeCopy.shortName` of the masked title | Builder B screen |
| G145 | low | PantryLedger.swift:103 | Tess line lowercases every name ("parmesan", "worcestershire sauce") while receipts keep the stored case. | Rule one casing for Tess lines | Product ruling |
| G146 | low | PantryLedger.swift:102; PantryCopy.swift:30 | Private ingredients are dropped from the names and the count, so "Tacos took 5 things." when 6 were used, or "took the limes." when limes and a private item were used. | Count private items in the number, never name them | Product ruling |
| G147 | low | PantryLedger.swift:52-62 | Private rows tie on the label "Private item" with no id tie-break, so their order can shuffle; their aisle sort position leaks a category (inferred). | Sort private rows last in a state by id | Builder B screen |
| G148 | low | PantryLedger.swift:166 | `BodyWeight.lastKg` runs once per ingredient on every body refresh. | Read it once per `facts()` pass | Builder B screen |
| G149 | low | HomeSpatialView.swift:376-387 | S2/S13 say Home's Pantry line is the hero verbatim; Home shows only the word "Pantry". Not built. | Build it or strike the sentence ("never a Home offer" argues for striking) | Product ruling |
| G150 | low | PantryDayWord.swift (no caller outside tests) | "bought Sat" and VoiceOver "bought Saturday" are unused; when the ingredient page uses them they sit under the G141 mask. | Wire after G141, with a private-page test | Builder B screen |
| G151 | low | PantryCopyTests.swift; PantryFrontTests.swift | No test for: private row VoiceOver label `Private item, out` (PW18/PP05, label built inline in the view), `noPantrySurfaceCarriesAWalledName`, `pantryOpSummariesAreMasked`, plural masking word, the 4:50 boundaries (PP14, PP17), a private Tess line with only private names. | Move the label to `Entry.spoken` and add the six tests | Builder B screen |
| G152 | low | PantryView.swift:134-136 | G102 says "one tap strikes it"; that is Groceries. A Pantry private line has no tap and nothing to strike (R12). The prompt's wording mixes the two. | Product to confirm: Pantry private line = no tap target, swipe still adds | Product ruling |

Counts: 14 gaps (G139-G152): 1 blocker (G139), 3 important (G140, G141, G142), 10 low (G143-G152).
Top 5: G139, G140, G141, G142, G146.

## Part B: Groceries lows after #885

#885 has NOT landed on origin/master (no commit or merge named 885; head is #905). Marked WAITS ON FOLLOW-UP; open lows still on master:

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| GH11 G106 op summaries store raw titles ("Took <recipe> off groceries") | WAITS ON FOLLOW-UP (still open) | Groceries.swift:607; Lists.swift:347 | no test |
| GH11 G107 recipe-to-Groceries row skips the Add-line wall | WAITS ON FOLLOW-UP | Groceries.swift:365,506 (per doc, not re-read) | no test |
| GH11 G108 UNDO of a 3+ add names only the first | WAITS ON FOLLOW-UP (still open: receipt at Groceries.swift:682-687) | BottomChrome.swift:763-767 | no test |
| GH11 G105 check receipt masked by health only | WAITS ON FOLLOW-UP | Lists.swift:346-357 | no test |
| 774/776/779 price before a unit: "milk 3.49 gallon at costco" lands | WAITS ON FOLLOW-UP | kitchen-acceptance-774-776-779-oct17.md:114 | no test (per doc) |
| 826/832 `lastAdded` static shared state | WAITS ON FOLLOW-UP (not found on master; maybe already fixed, inferred) | grep finds none | no test |
| G102 reveal removal (not low, but same screen) | WAITS ON FOLLOW-UP (still on master) | ShopTrip.swift:15,24,43; GroceriesView.swift:526 | tests assert the reveal |

## Still open
G139-G152; the ten-function privacy wall (G105) and titleWords trims; G102 reveal removal on Groceries, Lists, Recipes; Pantry state words, usually-have, side key, Pantry grammar (not built).

## Phone only
VoiceOver on a Pantry line (children .ignore over a NavigationLink may drop its button action; NOT PROVABLE here), swipe feel and haptic, UNDO 4 s vs 10 s timing, Dynamic Type at AX sizes, Reduce Motion.
