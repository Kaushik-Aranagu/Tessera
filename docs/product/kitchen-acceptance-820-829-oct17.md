# Kitchen acceptance of #820, #822, #828, #829: static read

Static only, against origin/master 25ed4d9 (nothing built or run).

# Acceptance: #820, #822, #828, #829 (static read, master 25ed4d9)

Read only. Nothing built or run; no Swift toolchain. Diffs read with `git diff <merge>^1 <merge>` for 969b27a, faef05d, 8cc3b44, a889478. Checked against `docs/product/kitchen-gap-hunt-9-recipes-link-oct17.md` (G63, G64, G65, G69), `kitchen-acceptance-801-818-oct17.md`, `kitchen-acceptance-802-825-oct17.md`. "Covering test" means a test in the tree asserts it and I read the assertion; I did not run it. Paths are under `/home/user/Tessera`.

Short names: RLR = `TesseraCore/Sources/TesseraTess/RecipeLinkReader.swift`; RPL = `TesseraCore/Sources/TesseraTess/RecipePasteLink.swift`; RPLT = `TesseraCore/Tests/TesseraCoreTests/RecipePasteLinkTests.swift`; PR = `Features/Recipes/PasteRecipe.swift`; RP = `Features/Recipes/RecipePage.swift`; PD = `Features/Recipes/PortionDrum.swift`; LV = `Features/Lists/ListsView.swift`; LC = `Features/Lists/ListsCopy.swift`; LS = `Features/Lists/ListsShelf.swift`; LR = `TesseraCore/Sources/TesseraCore/Lists/ListRuns.swift`.

Verdict key: PASS, FAIL, NOT BUILT, NOT PROVABLE (needs a run or the phone).

## 1. PR #820 (969b27a): bad-network links stay on the shelf (G63, ER5) and a kept link loses its fragment and sensitive items (G64)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| A timeout, `cannotFindHost`, `dnsLookupFailed`, `cannotConnectToHost` read as offline, not "That site won't let me read it" | PASS | RLR:215-218 (`download` switch; also `internationalRoamingOff`, `callIsActive`) | `aBadNetworkKeepsTheLink` (RPLT:107, all four codes) |
| The link stays on the shelf and the line is "Recipe link, kept for later." | PASS | RPL:54-55 (`shelf?.keep` on `result.isOffline`); RLR:15 | `aBadNetworkKeepsTheLink` (RPLT:107-117; asserts `outcome.kept`, the line and the count) |
| The old test that fixed the wrong answer is flipped (`cannotFindHost` was "not offline") | PASS | RPLT:99-104 now uses `.badServerResponse` as not offline | `offlineIsTypedNotWorded` (RPLT:99) |
| The 15 s cap running out before the page answers is offline, not "Too big" | PASS | RLR:219-220 (`.cancelled where Task.isCancelled`); deadline at RLR:198-200 | no test (the stub cannot hold a request for 15 s) |
| The 15 s cap cutting a slow page mid-stream is offline, not "Too big" | PASS | RLR:248-250 (`Task.isCancelled ? .offline`) | no test |
| A real over-size page still says "Too big" | PASS | RLR:241-243 (3 MB), RLR:233-235 | existing size tests (not re-read) |
| Remove a link from the shelf only on a read, a paywall or a firm refusal (G63 fix text) | FAIL (low) | RPL:56-57 still removes on every non-offline result, so an odd server error (`badServerResponse`, `blocked`) also drops the kept link | no test |
| Fragment dropped from a kept link and from the saved source | PASS | RLR:335 (`parts.fragment = nil`); saved source goes through the same call at RLR:139 | `aKeptLinkLosesItsFragmentAndSensitiveItems` (RPLT:119; shelf only) |
| Name and password dropped from the URL, and a link that carries them is refused whole by `keep` | PASS | RLR:336-337; RPL:92 (guard before strip) | RPLT:84-97 (existing theory, unchanged) |
| Query names holding `pass`, `token`, `secret`, `sig`, `auth`, `session`, `jwt`, `email`, `key`, `code`, `sid`, `otp`, `nonce`, `credential` are dropped | PASS | RLR:318-319, RLR:343 | `aKeptLinkLosesItsFragmentAndSensitiveItems` (email, x_signature, id_token only) |
| A harmless-named item with an email or a long opaque value is dropped | PASS | RLR:322-326, RLR:344 | same test (the long `ref` value) |
| The saved `sourceURL` is stripped the same way | PASS (by read) | RLR:139 | no test (the test reads the shelf file, not a read result) |
| No harmless item is lost to the wider match | FAIL (low) | RLR:343 is a substring match: "author" holds `auth`, "design" holds `sig`, "inside" holds `sid`, "keyword" holds `key`; RLR:322-326 also drops any 24+ character letters-and-digits value, which a dated recipe slug can be. The saved source and the shelf key lose the item | no test |
| Links already on the shelf from before this PR | NOT BUILT (low) | RPL:101 strips the link before comparing, so an old stored entry that holds a fragment never matches and `remove` cannot take it off; `waiting()` (RPL:87) returns it unstripped | no test |

PR verdict: accepted. Rows that miss: removal rule broader than the gap asked (RPL:56-57), the wider match over-strips (RLR:343), old shelf entries are not cleaned (RPL:101), the two 15 s paths have no test.

Gap status: G63 closed (wording, keep, 15 s cap; the narrow removal rule is the only residual). G64 closed for new keeps and saved sources; legacy entries and over-strip are the residuals.

## 2. PR #822 (faef05d): "Read 1 waiting", the shelf's waiting-link line (G65)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| The words are "Read 1 waiting" / "Read 3 waiting" | PASS | PR:524-526 (`PasteCopy.readWaiting`) | `waitingLinksReadAsACount` (PasteCycleTests.swift:48) |
| The word shows only with an empty box, nothing reading, and at least one link waiting | PASS (by read) | PR:54 | no view test |
| The count is the number of kept links | PASS | PR:55 (`waitingLinks.count`) | `waitingLinksReadAsACount` (wording only) |
| A tap reads the oldest link; nothing reads by itself | PASS | PR:55-58 (`waitingLinks.first`; the shelf is oldest first, RPL:87) | `offlineKeepsTheLinkUntilHisTap` (RPLT:46; Core half) |
| The list refreshes when the page shows and after each read, so a read link leaves the count | PASS (by read) | PR:146-150; the removal itself is RPL:56-57 | `offlineKeepsTheLinkUntilHisTap` (shelf empties after a read) |
| The word never prints a link (count only) | PASS | PR:55 | no test |
| VoiceOver: hint "Reads the oldest link kept for later" | PASS | PR:61 | no test |
| Dynamic Type and Reduce Motion on the word | NOT PROVABLE | PR:56 (`.labelWord` style, `.entrance(1)`) | no test |
| Tapping fills the box with the link and also starts the brush pass on that text | NOT PROVABLE | PR:56-57 sets `text` (fires `onChange(of: text)` at PR:152-170, which calls `read()` at PR:206) and `readLink` guards a second read at PR:231 | no test |
| A door that lists links, so he can pick one, read it or remove it | NOT BUILT | PR:54-62 offers only the oldest, one at a time; nothing removes a single kept link | no test |
| `erase()` wired to the erase-everything path | NOT BUILT | RPL:108; no caller in `Features/` or `App/` (grep is empty) | Core only: `theShelfHoldsFiftyAndErases` (RPLT:131) |
| Offline keep does not empty the box (ER1, open row from the 802-825 acceptance) | FAIL (open) | PR:260-263 (`text = ""` when `outcome.kept`); softened because the waiting word now brings the link back, but the clause is not met | no test |
| The kept-for-later line (and the password refusal line) goes away once he pastes something else | FAIL (open) | `linkLine` is cleared only at PR:250 and PR:269; not touched by this PR | no test |
| A read dropped by an edit leaves nothing on the shelf | NOT PROVABLE (open) | RPL:54-55 keeps before the view's guard at PR:246-250 | no test |

PR verdict: accepted for the "Read 1 waiting" line. Rows that miss: single-link remove and `erase()` (G65 stays partly open), ER1 box emptying, line staleness.

Gap status: G65 partly closed (a door to read the oldest waiting link exists on Paste; no remove one, no erase, not on the Recipes shelf). Secret-link line staleness: open, unchanged. Offline keep empties the box (ER1): open.

## 3. PR #828 (8cc3b44): Lists put-away on screen (G9)

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| The shelf reads `shelf()`, not `lists()`, so a put-away list leaves it | PASS | LS:37 (`contents.shelf()`); `shelf()` is LR:259-262 | `aFinishedTripListIsPutAway` (ListsShelfTests.swift:110) |
| The shelf's context count and Tess line use shelf rows only | PASS (by read) | LS:56-62 (built from `rows`) | no test of the count |
| The put-away word at the foot, only once something has been put away | PASS | LV:59-71 (`if shelf.awayCount > 0`); `awayCount` is LS:39 | `aFinishedTripListIsPutAway` (asserts `awayCount == 1`; no test that 0 hides it) |
| The foot word is 21 pt at 45% ink, 44 pt target, "Put away" never "Archived" | PASS (by read) | LV:61-66 | no test |
| VoiceOver: "Put away, 2" with the hint "Lists set aside for later" | PASS | LV:68-69 | no test |
| Finishing a plain list with nothing open speaks "Packing, Lisbon put away." with UNDO 10 s | PASS (by read) | LV:476-478 (reads `result.output.putAway`); the words are `LC.putAway` LC:65-67 with the list title as the name; the UNDO hold is 10 s when an UNDO is given (`HomeQueue.swift:45-51`) | `putAwayReadsThingFirst` (ListsCopyTests.swift:92; "Packing" only, not the finish path) |
| That finish path is covered | NOT PROVABLE | LV:476-480 | no test (the view method is not under test) |
| After the put-away line the page closes back to the shelf | PASS (by read) | LV:479 (`dismiss()`) | no test |
| The put-away words show "Private list" for a walled list | PASS (by read) | name comes from `shownName` at LV:155 into LV:477; `shownName` is LS:95-97 | no test of the put-away line; the shelf row mask is covered by the existing private-row test (ListsShelfTests.swift:100-107) |
| "Put away" option word while a run is open, calling `PutAwayListRun` | PASS | LV:393-403 (shown only `if running`); caller LV:486-498 | no test |
| That option's line: "Packing put away. 3 in the basket." with UNDO | PASS (by read) | LV:496 with `result.output` as the basket count (LR:213-218 returns `basketCount`); LC:65-67 | `putAwayReadsThingFirst` (ListsCopyTests.swift:92, both forms) |
| A failed put-away says "Didn't save that. Try again." | PASS (by read) | LV:487-490 | no test |
| The put-away page: plain names, newest first, one opens its list, private ones masked | PASS (by read) | LV:629-667 (`ListContents.putAway()` newest first, LR:243-257; `shownName` at LV:648); route LV:14 | no test |
| Running a put-away list again brings it back with its rows | PASS (Core); NOT PROVABLE (screen) | LR:57-62 (Core); screen path is open the list from the put-away page, then Run it | `ListPutAwayTests.swift` (Core; not re-read per case) |
| Removing the last open row does not put a list away; only finishing does | PASS (by read) | the only put-away trigger is `FinishListRun` (LR:120-123) | no test of a remove |
| The finished name "sinks into" the foot word | NOT BUILT | LV:478-479 only dismisses; no motion toward the foot | no test |
| UNDO of a put-away is reachable after the page closes | NOT PROVABLE | the line goes to the shared Tess line (LV:477, LV:496) | no test |
| A put-away list run counts as bought (basket credited to the pantry or buy cadence) | NOT BUILT (open) | `PantryLedger`/`BuyCadence` unchanged; grep for `putAway` in `BuyCadence.swift` is empty | no test |
| `lists()` callers elsewhere still show put-away lists | NOT PROVABLE (low) | `TesseraCore/Sources/TesseraTess/TessTools.swift:332`, `Lists.swift:107` use `lists()`; intent not checked | no test |

PR verdict: accepted. Rows that miss: the sink motion is not built, no test drives the finish or put-away paths, and the bought credit is still open.

Gap status: G9 on screen closed for the words, the shelf split, the foot word, the option word, the put-away page and the `PutAwayListRun` caller (all of the 802-825 "Still open 7" items except the sink). Partly overall: sink motion and bought credit remain.

## 4. PR #829 (a889478): Dynamic Type on the recipe page (G69)

Assumed sizes: body 17 pt at the default, 28/33/40/47/53 pt at AX1 to AX5 (scale about 1.65 to 3.1); iPhone 17 width 402 pt, 22 pt gutter (`Theme.Spacing.gutter`) leaves about 358 pt. These are my arithmetic, not a measurement.

| Clause | Verdict | file:line | Covering test |
|---|---|---|---|
| At accessibility sizes the whole page is one scroll (hero, context, drum, list, step count) | PASS (by read) | RP:34-38; other sizes keep the old layout, RP:39-41 | no test |
| The ingredient list is not nested in its own scroll at AX sizes; the drum sits above it | PASS (by read) | RP:101-108 | no test |
| Non-AX sizes keep the list scroll beside the drum | PASS | RP:109-117 | no test |
| The hero name is not shrunk and has no line limit at AX sizes | PASS | RP:214-215 | no test |
| The hero text role stops growing at the largest ordinary size (the role caps at XXXL by design) | PASS (not a G69 miss; noted) | `DesignSystem/Editorial.swift:40` | no test |
| Ingredient names are no longer cut at two lines | PASS | RP:355-358 (limit removed) | no test |
| The amount column scales with Dynamic Type | PASS | RP:331 (`ScaledMetric`, relative to body), RP:350 | no test |
| The amount column leaves the name a usable width at every size | FAIL (AX4, AX5; weak at AX3) | RP:350 is still a fixed-width frame, only scaled. About 152/179/217/254/287 pt at AX1 to AX5 leaves the name about 198/171/133/96/63 pt, which is two or three characters a line at AX5. In the AX layout the list has the full row, so the row should stack amount over name instead (inferred; needs a run) | no test |
| No fixed frames left on the page | FAIL | scaled frames remain: RP:350 (amount), PD:35, PD:75, PD:85 (drum); RP:121 (`columnWidth` for the sent line) is a measured width | no test |
| The drum scales: width, row pitch, three rows shown, mask follows | PASS (by read) | PD:23-25 (`ScaledMetric` relative to title), PD:84-85 | no test |
| The drum's digits scale with the frame | PASS (by read) | PD:73 uses `textRole` (title/body relative scaling) | no test |
| The drum at AX5 fits above the list in the one scroll (about 300 pt tall) | NOT PROVABLE | PD:85, RP:103-105 | no test |
| The list scrolls at the largest sizes | PASS (via the page scroll) | RP:35 | no test |
| VoiceOver: drum stays one adjustable "Serves" element; list keeps one stop per row and the single "Add all to Groceries" | PASS | PD:54-63 and RP:368-380 unchanged | existing `RecipeSendTests` (not re-read) |
| VoiceOver reading order: drum now comes before the list at AX sizes (list then drum at other sizes) | NOT PROVABLE | RP:103-105 vs RP:110-117 | no test |
| The sent line still lands on the departing column at AX sizes | NOT PROVABLE | RP:119-123 sits at the ZStack top, now over the drum in the AX layout | no test |
| Swipe to send still works inside the page scroll (horizontal-dominance guard) | NOT PROVABLE | RP:107, RP:246 | no test |
| Reduce Motion: nothing new animates | PASS | the diff adds only layout branches; RP:348 and the house animations already honor it | no test |
| Reduce Motion: the drum row highlight honors it | FAIL (pre-existing, G72 residual) | PD:76 is a raw `.animation(.easeOut(duration: 0.16))` outside `MotionPolicy` | no test |
| Switching text size live keeps the page's state and does not replay the entrance | NOT PROVABLE | RP:34-41 swaps the container (`ScrollView` or not) | no test |
| A Dynamic Type check exists (test or AX3 phone screenshot) | NOT BUILT | no Dynamic Type assertion in `RecipeContextTests` or `RecipeSendTests`; gap fix asked for an AX3 screenshot | no test |

PR verdict: row that misses: the amount column is still a (scaled) fixed frame, so the name gets a sliver at AX4 and AX5. Everything else in the G69 fix text is built (page scroll, drum scale, no two-line cut, hero).

Gap status: G69 partly closed.

## Gap summary

| Gap or row | State | Why |
|---|---|---|
| G63 | Closed | RLR:215-220, 248-250; test RPLT:107. Residual: RPL:56-57 removal rule, no test for the 15 s paths |
| G64 | Closed for new keeps and sources | RLR:335-344; test RPLT:119. Residuals: over-strip (RLR:343), old entries (RPL:101) |
| G65 | Partly closed | "Read 1 waiting" (PR:54-62) reads the oldest on his tap; no remove one, no `erase()` caller |
| G9 on screen | Closed except the sink motion | LV:59-71, 393-403, 476-498, 629-667; LS:37-39 |
| G69 | Partly closed | RP:34-41, 101-117, PD:23-25 built; amount column RP:350 still fixed |
| Secret-link line staleness | Open | `linkLine` cleared only at PR:250, PR:269 |
| Offline keep empties the box (ER1) | Open | PR:260-263 |
| "Packing, nothing to reset." | Open | LR-side throw still `nothing checked on` (`Lists.swift:460`, `ListReuse.swift:85`); no spoken line |
| "Packing isn't running." | Open | LR:116 and LR:218 still developer strings |
| Put-away counts as bought | Open | no reader credits the basket |
| Shared 4320 cap | Open | `RecipeLimits.swift:8` still 1 to 1440; RLR:483 and RP:620 still literals |

## Still open

1. G69: stack the amount over the name at accessibility sizes (RP:350); add an AX3 and AX5 phone check or a test; the drum highlight at PD:76 needs `MotionPolicy` and Reduce Motion.
2. G65: remove one waiting link, an `erase()` caller on the erase-everything path (RPL:108), and the same door on the Recipes shelf.
3. ER1: offline keep still empties the box (PR:260-263).
4. Line staleness: clear `linkLine` when the box changes to anything that is not a refused link (PR:250, PR:269); the kept-for-later line now stands beside "Read 1 waiting".
5. A read dropped by an edit still leaves the link on the shelf (RPL:54-55 before PR:246-250).
6. G63 residual: only a firm refusal should remove a kept link (RPL:56-57); add tests for the 15 s paths (RLR:219-220, 248-250).
7. G64 residual: tighten the substring match (RLR:343) and the long-value rule (RLR:322-326); clean or match legacy shelf entries (RPL:101); test the saved `sourceURL`.
8. G9: the sink motion into the foot word; tests that drive the finish path (LV:476-480), the option word (LV:486-498) and the put-away page (LV:629-667); put-away counts as bought.
9. Lists spoken errors: "Packing, nothing to reset." and "Packing isn't running." (Core strings, LR:116, LR:218, `Lists.swift:460`, `ListReuse.swift:85`).
10. One shared limits constant and the 4320 cap (`RecipeLimits.swift:8`, RLR:483, RP:99, RP:620, PD range).

## Phone only

1. Settings, Accessibility, Larger Text at AX3, AX4, AX5: open a recipe with a long ingredient name and "1 1/2 tbsp". Check the name is readable beside the amount, the drum sits above the list, the whole page scrolls and the hero wraps.
2. At AX5 swipe the list left to send it to Groceries: the sent line should read over the departing list, not hide behind or over the drum; VoiceOver reads hero, context, drum, then Ingredients.
3. Change the text size while a recipe is open: state and the portion size survive and the entrance does not replay.
4. Reduce Motion on: turn the drum; the highlight should not animate (it will, PD:76).
5. Join a Wi-Fi with no internet, read a pasted link: "Recipe link, kept for later." shows, the box clears, "Read 1 waiting" appears. Come back online, tap it: the recipe reads and the word goes. Paste a slow page and wait 15 s: same line, not "Too big".
6. Paste a normal recipe right after the kept line: check whether the kept line still stands over it (expected: it does).
7. Keep a link whose address ends in a fragment: confirm the shelf file shows the link with no fragment and no email-like item.
8. Lists: run a list, check everything, tap Done on a plain list "Lisbon": "Lisbon put away." with UNDO for 10 s, the page closes, the shelf shows "Put away" at the foot. Open it, Run it: it returns. Watch for a sinking motion (none is built).
9. While a run is open tap the Put away option word with 3 items checked: "Packing put away. 3 in the basket." and UNDO.
10. Name a list so the wall calls it private, finish it: the line must say "Private list put away." and the put-away page must list it as "Private list".
