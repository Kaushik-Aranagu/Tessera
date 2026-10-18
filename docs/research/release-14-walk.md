# New on your phone: release 14

On your phone now: release 8 (e149e66). Next to install: release 13 (bbadf141), which waits only on the phone being
reachable. Release 14 is everything on master since 13, so install 13's page first; this page is only what 14 adds.
Read Sat Oct 17 from the PR diffs (GitHub) and git history. Nothing was built or run. Exact lines are quoted only
where the code has them.

PRs 864, 866 and 867 are merged and already on master. PRs 564, 868, 871, 884, 885, 886 and 890 are open (re-read Sun Oct 18, none merged, every head SHA below unchanged
since the first read except the two new ones): everything marked "if merged" below only appears if that PR lands
before release 14 is cut.

## Pick one and lists
- **Pick one closes with VoiceOver.** The two-finger scrub closes the pick. A tap outside during the short pause
  between picks now stays closed, instead of reopening.
  Try: hold a Pick one list, lift an item, tap outside right after swiping to pick again.
- **The page dims whole.** While a pick is up, the done fold dims with the rest, and VoiceOver cannot read the page
  behind it.
- **The fold drains from full ink.** Resetting a done fold no longer starts with a dim flash; the strike shortens
  right to left.
- **Copy a list (if merged, #871).** Type "copy packing for lisbon". You get a new list with Packing's items, all open.
  The line reads "Packing, Lisbon, new list." (the new list is named "Packing, Lisbon"). Say it again and it opens
  that list: "Packing, Lisbon, already a list."
  Try: type "copy packing for lisbon", then UNDO.
- **Two lists match (if merged, #871).** "copy trip for lisbon" with Trip one and Trip two says "More than one list like
  trip." and writes nothing. A word that is not one of your lists is not a copy ("copy the report to dad" stays a task).
- **Three starter lists (if merged, #871).** Gym bag, Leaving the house and Packing appear once, reusable, items open.
  Delete one and it stays gone.
- **A list name with a secret word or a key is refused** (if merged, #871), for new lists and copies alike.
- **Copy without the phrase (merged, #866).** The copy exists in the engine and the day log ("New list:"), but nothing
  you can type reaches it in this build unless #871 lands.

## Recipes
- **A name with a number stays a name (if merged, #886).** Pasting "30-Minute Dal" or "7 Layer Dip" gives a recipe
  with that title. "2 eggs", "1/2 cup flour" and "200g flour" are still ingredients.
  Try: paste a recipe whose first line is "7 Layer Dip".
- **Pasted twice, medicine in the name (if merged, #868).** It reads "Private recipe is already on Recipes." and the
  medicine word never shows or gets logged.
- **Rescued animation.** The recipe send now follows the house motion setting (Reduce Motion respected).

## Tess and your private things
- **Questions with a secret go to Tess's walls (if merged, #564).** "door code 4417?" becomes a private note or
  gets "It's in your private notes." It is never a plain task on Home, the Day log or a backup.
- **Money or body questions** ("was $12 too much?", "is my bp 140 too high?") answer "That stays on this phone." and
  save nothing.
- **A pasted recipe that cannot be read** no longer puts a money or body line in the miss log.
- **Too long (if merged, #884).** A phrase over 600 characters says "That's too long to send. Say it shorter." and
  never leaves the phone.
- **Timers stay home (if merged, #884).** A phrase about a timer, or a cook phrase said while a cook is running
  ("8 mins", "step 3", "stop the rice"), is never sent to Claude. The gate is narrowed to cook phrases only
  (decisions 3:38 PM PT and 4:20 PM PT (6), Core's next PR); an unrelated phrase mid-cook ("call mom half 7") goes
  the normal route, and a dropped cook phrase keeps the line "Didn't catch that." and is not logged. This bullet
  and row W27 describe #884 as built until that PR lands, then change.
- **Clocks are not money (if merged, #884).** "dinner at 7.30" is a time. "rent at 7.30" is still money.
- **Stone is a body fact (if merged, #884).** "Eleven stone four" and "12 st 3" stay private.

## Private rows and titles (if merged, #885 and #890)
- **A private row never opens (if merged, #885).** On Groceries (list, SHOP mode and basket) and on a list page, a
  private row always reads "Private item". One tap strikes it like any other row; nothing shows its words. VoiceOver
  says "Puts it in the basket" (Groceries) or "Checks it off" (a list), never "Shows it".
  Try: put "advil" on Groceries, tap the row.
  Not covered: the recipe page still lets a tap show a private recipe title (see W38).
- **One check for private titles (if merged, #890).** "Dentist cake" reads "Private recipe" on every screen, in Tess's
  lines and in a shared export. "blood orange", "hearts of palm", "energy drink", "sleep tea", "Dr Pepper", "Rent car"
  and "flour 5 kg" stay as typed. A plain task "dentist" stays raw on Home.
  Try: paste a recipe titled "Dentist cake".

## Quietly safer
A stored number that is NaN, infinite or past 1e15 now reads as no value everywhere, so no screen can crash on it.

## Not on screen
Starter lists need an app launch to appear (if #871). The test-only flags in #564 (`-wallsSpy`, `-wallsSeedPrivate`)
do nothing on the phone.

---

# Walk table (QA and Builder A)

Status: **traced** means read in the PR diff of this file or its test; **inferred** means from the PR text only.
Merged rows are on master now. Open rows carry "if merged" and the head SHA read.

| Row | PR | Where to look | He should see | He must NOT see | Status | Rider |
|---|---|---|---|---|---|---|
| W1 | #864 merged (350ac0a) | Any screen reading a stored number: routine editor rep range, a task's length, Prefill, rest weekday | Nothing changes for normal numbers (12 reads 12) | A crash or trap on a NaN, infinity or huge stored value | traced (`FieldValue.numericValue` guard, tests in ObjectModelTests) | none |
| W2 | #864 | Groceries after two shops | Two shop clears counted after the second shop | Stale count (cache) | traced (ShopClearsTests, package only) | none |
| W3 | #866 merged (88e1395) | Day log after a copy | "New list: Lisbon" | The source's private title; a "New list" line for a repeat | traced (DayStoryTests) but unreachable from the UI without #871 | none |
| W4 | #866 | Typing "copy packing for lisbon" in the Ask bar | on master alone: no copy (no grammar rule); Tess falls through as before | A new list | inferred (grammar rule only in #871) | none |
| W5 | #867 merged (f656f2b) | Pick one list, VoiceOver on, two-finger scrub | The pick closes | The pick staying open | traced (`.accessibilityAction(.escape)` in ListsPick.swift); needs device or simulator with VoiceOver | none |
| W6 | #867 | Pick one: swipe to pick again, tap outside inside 200 ms | Stays closed | A new pick opening | traced (`guard picking != nil`) | none |
| W7 | #867 | List page while a pick is up | Done fold dimmed to 14% with the page; page hidden from VoiceOver | A bright done fold | traced (opacity, blur, `accessibilityHidden` moved after safeAreaInset) | none |
| W8 | #867 | Reset a done fold | Full ink text, strike shortens right to left | A dim flash at the start | traced (`FoldDrainRenderer`); Mac-only visual check | none |
| W9 | #867 | Hold on Pick one name; send a recipe to Groceries | Animations follow Reduce Motion | Motion with Reduce Motion on | traced (`withTesseraAnimation`) | none |
| W10 | #871 open (34fc965), if merged | Ask bar: "copy packing for lisbon" (starters installed) | "Packing, Lisbon, new list." and a list "Packing, Lisbon" with 11 open items; UNDO removes it | A list named plain "Lisbon" (the PR text says "Lisbon, copied from Packing."; the diff and tests say otherwise) | traced (StarterListsTests) | none |
| W11 | #871 | Same phrase again | "Packing, Lisbon, already a list." and still one such list | A second copy | traced | none |
| W12 | #871 | "copy trip for lisbon" with Trip one and Trip two | "More than one list like trip." and nothing written | A new list | traced | none |
| W13 | #871 | "copy costco for lisbon", "copy the report to dad" | Read as before (task or miss) | "no list called costco" | traced (test asserts it is NOT said; the PR text says otherwise) | none |
| W14 | #871 | Siri or Shortcuts "copy packing for lisbon" | No copy | A new list | traced (`commitImmediately` guard) | none |
| W15 | #871 | Lists after first launch | Gym bag (10 items, 3 sections), Leaving the house (6), Packing (11), reusable, all open; none re-added after delete | Duplicates of a list he already named Packing | traced (StarterLists.swift, tests); app launch path needs a Mac build | none |
| W16 | #871 | Create or copy a list named with a secret word ("wifi password zebra99") or a key shape | Refused | The name on screen or in the log | traced | none |
| W17 | #871 | Day log for a copied private list | "New list: Private list" | The secret title | traced (DayStoryTests) | none |
| W18 | #564 open (7219247), if merged | Ask bar: "door code 4417?" | "It's in your private notes."; no task row with 4417 on Home, Day log or in a backup | A plain task with the value | traced (BottomChrome.commit, fixture A06/A07) | R19 (same PR; see W19) |
| W19 | #564 | Ask bar: "was $12 too much?" and "is my bp 140 too high?" | "That stays on this phone." and nothing saved | A private note or task | traced (fixture A20/A21) | R19 |
| W20 | #564 | Ask bar: "is 82.4 good?" near his last weight | No Claude call and no Home task with the number (code is in e149e66 since #627) | The number in a task | inferred for the screen; code traced via fixture BN rows in the PR | **R19** (proof WallsUITests BN01 to BN11 rides this PR; row stays open until it merges) |
| W21 | #564 | Paste an unreadable recipe holding a money or body line | Nothing in the miss log | The amount in `misses.jsonl` | traced (`PasteRecipe.save` guard, fixture) | none |
| W22 | #564 | Notes page: body, money, account lines | Private note rows | Plain notes titled with the fact | inferred (fixture `pending` cleared for "Core 0aa"; code not in this diff, may already be on master) | R6 is a different item (N15 launch pass): do not tick R6 from this |
| W23 | #564 | Ask bar with an Ask bar key shape | "That looks like a Claude key. It goes in Review, under Claude." | The key echoed | traced (existing line; fixture text updated) | none |
| W24 | #564 | Phone build, any launch | No `-wallsSpy`, no `walls.probe`, no seeded private note | Any of them | traced (all behind `#if DEBUG` and `LaunchFlags`) | none |
| W25 | #868 open (b574dec), if merged | Paste "Ibuprofen tea" twice on Recipes | "Private recipe is already on Recipes." | The word "Ibuprofen"; a miss log line | traced (PasteCycleTests); a non-medicine title still reads "<title> is already on Recipes." | none |
| W26 | #884 open (5665c60), if merged | Ask bar: a phrase over 600 characters | "That's too long to send. Say it shorter." and no Claude call | The phrase logged as a miss | traced (ClaudeRouteTests) | none |
| W27 | #884 | Timer phrases; cook phrases while a cook runs (any phrase, as #884 is built; narrowed to cook phrases by 3:38 PM PT) | Handled on the phone only | A Claude call (Receipts row) | traced (MoneyWallTests) | none |
| W28 | #884 | "dinner at 7.30" vs "rent at 7.30" vs "coffee 7.30 today" | Clock; money; money | "dinner at 7.30" walled as money | traced | none |
| W29 | #884 | "Eleven stone four", "12 st 3", "I'm 11 stone 4"; "bring a stone for the wall" | First three walled as body; last plain | Stone words sent to Claude | traced | R19 is the bare-number case, a different rule: do not tick |
| W30 | #884 | "move dentist to 7" with no such task | "Didn't catch that" prefix, no records | A guessed task | traced | none |
| W31 | #884 | Review, Claude receipts | No walled phrase word in any row | A word of a walled phrase | traced (test); screen read inferred | none |
| W32 | #886 open (5bbd506), if merged | Paste "30-Minute Dal", "7 Layer Dip", "5 Spice Chicken", "3 Cheese Pasta Bake" | Title kept | "Untitled recipe" | traced (RecipeTests) | none |
| W33 | #886 | Paste first lines "2 eggs", "1/2 cup flour", "200g flour", "2 Tbsp butter", "1. Preheat the oven" | Untitled recipe (quantity or step, not a title) | An ingredient as the title | traced | none |
| W34 | #885 open (339ebeb), if merged | Groceries list, then SHOP mode: a private row ("advil") among plain ones | Reads "Private item"; one tap strikes it into the basket; the basket also reads "Private item" | The words "advil" at any point; a first tap that does nothing | traced (`shopTap` now calls `check`; ShopTripTests `aPrivateRowAlwaysReadsPrivateItem`); screen check needs a simulator | none |
| W35 | #885 | VoiceOver on a private Groceries row and a plain one | Both hint "Puts it in the basket" | A hint "Shows it" | traced (GroceriesView `GroceryRow`) | none |
| W36 | #885 | A list page holding "advil": tap the row; VoiceOver hint | Reads "Private item"; the tap strikes it at once; hint "Checks it off" | A first tap that only reveals; "Shows it" | traced (`ListPage.tap` guard removed, hint literal) | none |
| W37 | #885 | Private row, then leave the page, lock the phone, end SHOP mode, come back | Still "Private item", no state to reset | Words shown after any of those | traced (`revealed`, `tap`, `end()` and the scenePhase and onDisappear hooks deleted) | none |
| W38 | #885 | Recipes: a recipe with a private title (e.g. "Ibuprofen tea"), hero and detail page | Per decisions 4:20 PM item (7) and 4:25 PM: always "Private recipe", no tap shows it, no "Shows it" hint | A tap that shows the title | **gap**: head 339ebeb changes four files (GroceriesView, ShopTrip, ListsView, ShopTripTests) and not RecipePage; on master `titleShown` is at RecipePage.swift:31 and :457, "Shows it" at :81 and :471 | none (Builder B, new PR) |
| W39 | #890 open (3980906), if merged | Paste "Dentist cake" (ingredients and a step), then look at Recipes, Home, the add-to-Groceries line, a shared export | "Private recipe" in every place | The word "Dentist" on a screen, a Tess line or in the file | traced (PrivacyParityTests `aRecipeCalledDentistCakeIsPrivateOnTheScreenAndInTheExport`) | none |
| W40 | #890 | Titles "blood orange", "hearts of palm", "energy drink", "sleep tea", "Dr Pepper", "Rent car", "flour 5 kg", "ground beef 2 lb", "pain au chocolat", "recovery shake", "Weight Watchers chili" | Stay as typed everywhere | "Private" on any of them | traced (PrivacyParityTests `aPlainTitleIsPlainEverywhere`; decisions 4:22 PM and 4:35 PM) | none |
| W41 | #890 | List items or Groceries lines "dentist", "therapy ideas", "lexapro", "rent 2100", "take melatonin", "paid 40 for gas"; Tess's line after adding | Row and line read "Private item"; "Private item, already on Groceries." on a repeat | The word in a receipt, UNDO line or Tess line | traced (`AddGroceries.shown`, `AddListItem.isPrivateItem`, TessCaptureEngine now ask `ObjectPrivacy.isPrivateWord`) | none |
| W42 | #890 | Home with a plain task "dentist"; a note "dentist friday" | Task raw (tasks keep their own rules). Note per decisions 4:50 PM item (1): "Private note" only if flagged or it holds a secret, money or body word, not on the word "dentist" alone | A titleWords check on notes | inferred (the diff touches no task or note code; PR text and 4:50 PM agree) | none |
| W43 | #890 | Titles "slept badly", "sleepy time tea", "drained tuna" | Per decisions 4:50 PM item (2): "sleepy time tea" and "drained tuna" stay raw (tired and burnout still mask) | "Private" on "drained tuna" | **gap**: head 3980906 subtracts 13 words from `TessMemoryScreen.healthWords` and "slept", "sleepy", "drained" are not among them (TessMemory.swift:101-105 holds all three) | none (Core) |
| W44 | #890 | Titles "dentists" and "dentist-appt" | Per 4:50 PM item (3): "dentists" masks, "dentist-appt" stays raw | "dentists" raw | **gap** for the plural: matching is an exact token (`PrivateFacts.words` then `titleWords.contains`), so "dentists" does not match; "dentist-appt" stays one token and is raw (as ruled) | none (Core) |
| W45 | #890 | List item or recipe "Dr. Patel", "Dr Patel", "Dr Pepper" | Per 4:50 PM item (5): first two mask, "Dr Pepper" stays raw | "Dr Patel" raw | **gap**: head removes bare "dr" from the set and adds no phrase rule; "Dr Pepper" is right, the other two read raw | none (Core builds the phrase rule) |
| W46 | #890 | Siri read-back of a list, routine or workout named "Dentist cake" or "dentist"; "5 kg flour" as a Groceries line | Per 4:50 PM items (6) and (7): Siri goes through the one check; a unit amount never masks a grocery item | The raw name in Siri's line | **gap** for Siri (Intents.swift is not in the diff); "flour 5 kg" is traced raw, "5 kg flour" inferred | none (Core) |
| W47 | #890 | Shared export of a task "Pay the therapist" and a weigh-in note | Task title masked (health title word); weigh-in note masked | The word "therapist" in the file | traced (PrivateWordsTests now use "Pay the therapist"; `PrivateWords.titleWords` delegates to `ObjectPrivacy.titleWords`) | none; note "Pay Dr Lee" no longer masks as a title (bare "dr" removed), see W45 |
| W48 | #886 open (5bbd506), if merged | Paste first lines "3 eggs benedict", "7 Up Cake", "2 Eggs", "5 Spice", "5-Ingredient Chili", "2-3 eggs", "1 14.5 oz can" | Per decisions 4:20 PM item (1) and 4:25 PM: "3 eggs benedict" and "7 Up Cake" are titles; "2 Eggs", "5 Spice", "2-3 eggs", "1 14.5 oz can" are amounts; "5-Ingredient Chili" a title | "Untitled recipe" over "3 eggs benedict" | **gap** for "3 eggs benedict": at head the second word is lowercase, so `startsWithAmount` returns true and the title is lost; the other six read as ruled except "1 14.5 oz can", which is inferred (depends on `IngredientLine.parse`) | none (Core) |
| W49 | #884 open (5665c60), if merged | Start a cook, then say "call mom half 7"; then "8 mins" | Per decisions 3:38 PM and 4:20 PM item (6): "call mom half 7" takes the normal route; "8 mins" stays on the phone, a dropped cook phrase reads "Didn't catch that." and is not logged | "call mom half 7" blocked from Claude while cooking | **gap**: at head any phrase is kept off Claude while a cook runs (the `cooking` flag has no phrase test); the not-logged rule is inferred (no miss-log code in the diff) | none (Core, next PR) |
| W50 | #884 | "dinner at 7.30", "dentist by 4.15", "dinner 7.30", "coffee 4.50" | Per decisions 5:30 PM: first two are clocks; the last two are prices and walled as money | "dinner 7.30" read as a clock | traced (regex clears only "at" or "by" before a clock-shaped number, and only when no money word is present) | none |
| W51 | docs | Survivor check, tap-to-reveal copy | Zero live promises of reveal or "Shows it" | A spec row that still promises reveal | **gap**: see "Tap-to-reveal survivors" below | Research or Product (docs) |


## Notes for the walk

- **Merged versus open.** Merged: #864, #866, #867. Open: #564 (18 commits, conflicts cleared, mergeable_state clean at
  read), #868, #871, #884, #885, #886, #890. W34 to W51 were added Sun Oct 18 for #885 (339ebeb) and #890
  (3980906) and for the rulings of 3:38 PM, 4:20 PM, 4:22 PM, 4:25 PM, 4:35 PM, 4:50 PM and 5:30 PM Oct 17.
  Re-read Oct 18: #564 7219247, #868 b574dec, #871 34fc965, #884 5665c60, #886 5bbd506, all still open and unchanged. The whole merged range since 13 (bbadf141) is 52 commits, 18 merges; every other
  merge is Research or Ops docs, so release 14 on master alone changes the app only through #864, #866, #867.
- **Rulings that change the walk.** (a) Tap-to-reveal is removed on all four surfaces (4:20 PM item 7, 4:25 PM): #885
  does three of them (W34 to W37); the recipe page is W38. (b) One title rule (4:20 PM item 1, 4:25 PM): #886 matches
  it except "3 eggs benedict" (W48); the hyphen-to-letter exemption and "2-3 eggs" as an amount match. (c) The one
  private-text check with trimmed title words (4:22 PM, 4:35 PM, 4:50 PM): #890 matches 4:22 and 4:35 (W39, W40)
  and misses three of the 4:50 PM items (W43 to W46). (d) Clock rule (5:30 PM): #884 matches (W50). (e) Cook gate
  narrowed (3:38 PM): not yet in #884 (W49, and the note on W27). 4:20 PM reached the repo copy of decisions.md only
  by reference: docs/product/decisions.md ends at line 943 here, the project copy at line 965 holds the 4:20 PM to
  4:50 PM entries.
- **#885 and #890 together.** `ShopTrip.isPrivate` calls `ObjectPrivacy.isPrivateRecipeTitle`, which #890 reroutes
  through the one check. With #885 alone a Groceries row masks by the old rule; with both, "dentist" and "therapy"
  rows mask on Groceries too. Walk W34 with and without #890 (inferred from the two diffs; not run).
- **Mac-only checks, added.** #885 is SwiftUI (W34 to W37: simulator, VoiceOver for W35 and W36). #890 and #886 are
  package tests only (`swift test` in TesseraCore, 912 and 911 per their text).
- **#866 and #871 disagree with their own PR text.** #866's body promises "Lisbon, copied from Packing." (merged
  code prints exactly that). #871 changes it to "Packing, Lisbon, new list." and names the copy "Packing, Lisbon".
  Walk to the diff, not the PR text. If #871 does not merge, #866 stays unreachable from the UI.
- **Mac-only checks.** #864 and #871 touch app files (`AppModel.swift`), so they need an app build. #867 is
  SwiftUI and VoiceOver (W5 to W9): simulator or device only. #564's WallsUITests runs about 12 minutes on a
  simulator and needs `scripts/test.sh --app-only`. #868's test is app-target and compiles for the device per its text.
  Starter lists (W15) need a launch on a Mac simulator and then the phone. None of this was done here.
- **Riders.** Only R19 ties in: #564 carries its WallsUITests BN01 to BN11 proof, which the riders checklist says
  keeps R19 open until it merges. R2, R6 and R13 are untouched by these PRs. R12 rides release 13.
- **Order.** Install 13 first (its page: `new-on-your-phone-r13.md`); release 14 has no rollback notes of its own
  and keeps the same Step 0 copy rule as the riders checklist.

## Tap-to-reveal survivors (gap, W51)

Read Oct 18 from master 6899613b: `grep -rn` over docs/ for "Shows it", "tap to reveal", "tap-to-reveal", "until he
taps that row", "until tapped", "Double tap to show" and "first tap reveals", with matches that mean something else
dropped ("shows it in grams", "until he taps Save", "double tap to show all areas"). Nothing was edited.
"reveal" alone was searched too: every other hit is plain English (reveal a secret to Claude, progressive
disclosure) or a ruling that removes the behaviour. The rows below are the survivors; the code survivors are listed
last because #885 does not remove them.

**Live specs and acceptance rows that still promise a reveal or "Shows it" (stale since G102):**
- docs/product/kitchen-refill8-acceptance.md:8, :26, :28 (K51, "masked until he taps that row"), :45 (VoiceOver
  "Private item. Double tap to show."), :216 (same hint in the copy list)
- docs/product/kitchen-refill7-acceptance.md:183 (K46.24), :254 (F4)
- docs/product/kitchen-refill9-lane1-acceptance.md:178 ("row reveals per K51.2")
- docs/product/kitchen-week-of-use-script.md:91 (K51 "private rows tap-to-reveal on the trip")
- docs/product/kitchen-acceptance-752-756-758-oct17.md:120 ("Private recipe, button, Shows it")
- docs/product/kitchen-acceptance-760-761-763-764-oct17.md:120 (13.8, PASS on "until tapped")
- docs/product/kitchen-lists-screen-walk-oct17.md:106, :108 ("Private item" until tapped)
- docs/product/kitchen-gap-hunt-11-recipes-groceries-oct17.md:80, :83, :101, :105, :145, :154 (the G102 finding
  itself; :80 and :83 describe the pre-G102 build, :101 to :105 are the ruling request)
- docs/product/kitchen-gap-hunt-12-pantry-v2-spec-oct17.md:290 (R12 question, answered by 4:30 PM "R12 follows G102")
- docs/research/fixtures/pantry-v2.md:23 (describes `revealed` and "Shows it" as still on master), :207, :320 (the
  removal task)
- docs/research/decisions-vs-master-oct17.md:23, :39 (row 5, "UNBUILT-KNOWN")

**Decision text and board history (superseded; keep, but a reader can miss the later ruling):**
- docs/product/decisions.md:11 (5:16 AM, "tap that row to reveal"), :19 (5:00 AM), :63 (3:09 AM item 4), :935
  (the G102 ruling that supersedes them). The 4:20 PM and 4:25 PM entries are not in this copy (it ends at line 943).
- docs/ops/board/design.md:87, :94, :103, :105, :106 (PASS rows on #760, #752, #735, #732 quoting "Shows it")
- docs/ops/board/kitchen.md:58, docs/ops/board/core.md:330, docs/ops/board/ios-b.md:222 (K51 and G37 lanes)
- docs/qa/review-732.md:13, docs/qa/review-735.md:4 (review text of the reveal behaviour)
- docs/research/fixtures/decisions-328-332-338.md (lines 3, 12, 15, 25, 32, 34, 37, 49, 70 to 78, 85 to 99, 328):
  this file is the removal spec, so it names the old behaviour on purpose.

**In code on master, not docs (outside this check, listed so W38 and W35 have lines):**
Features/Recipes/RecipePage.swift:81 and :471 ("Shows it"), :31 and :457 (`titleShown`);
Features/Lists/ListsView.swift:364 and Features/Groceries/GroceriesView.swift:526 go away with #885.
