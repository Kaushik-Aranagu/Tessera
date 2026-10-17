# New on your phone: release 14

On your phone now: release 8 (e149e66). Next to install: release 13 (bbadf141), which waits only on the phone being
reachable. Release 14 is everything on master since 13, so install 13's page first; this page is only what 14 adds.
Read Sat Oct 17 from the PR diffs (GitHub) and git history. Nothing was built or run. Exact lines are quoted only
where the code has them.

PRs 864, 866 and 867 are merged and already on master. PRs 564, 868, 871, 884 and 886 are open: everything marked
"if merged" below only appears if that PR lands before release 14 is cut.

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

## Notes for the walk

- **Merged versus open.** Merged: #864, #866, #867. Open: #564 (18 commits, conflicts cleared, mergeable_state clean at
  read), #868, #871, #884, #886. The whole merged range since 13 (bbadf141) is 52 commits, 18 merges; every other
  merge is Research or Ops docs, so release 14 on master alone changes the app only through #864, #866, #867.
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
