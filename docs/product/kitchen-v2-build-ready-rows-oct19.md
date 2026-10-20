# Kitchen v2: build-ready acceptance rows (Oct 19)

Kitchen lead, for Product's Review section and the builders. Docs only: nothing built or run. Twelve features, engine rows first, then screens. Rows cite existing acceptance IDs (PE, PD, K44, MP-F, PS and so on) instead of repeating them, and spend new rows on what is missing. A row marked "inferred" is my reading, not a ruling. Drafted by three workers from the written sources, then merged and spot-read by me; it has had no QA read yet. Product ruled the 12 contradictions at 12:47 PM Oct 19 (defaults, reversible); the rulings are folded in below and listed at the end.

Every feature has a Review switch, default Off. In Builder B's ReviewChoices (#1096) the Kitchen rows named so far are cookTimerVoice, pantryState, canCookShelf and handsFreeCook, each Off or On. That makes row 20 (Cook timer voice) Off/On with default Off, not the "alert only / spoken" pair written in `kitchen-review-switches-oct19.md`. The other switches below are new rows for Product to number.

Groups: PS, CC, RL, AO (pantry family); WD, RG, LO, RE (week, lists, edit); PL, HF, LF, CN (cook mode, link, notes).

---
Docs only. Existing rows are cited, not rewritten. Master has no `PantryState`, `canCook` or `usuallyOutOf`.

## PS Pantry state
Already covered: engine PD/PB/PE01-PE29, pantry-acceptance Core 1-4; screens P1-P16, S1-S17, PW rows. G207 hero "Nothing out" = S11. Shared export = PE25-PE26.

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| PS-E1 | The iCloud folder copy holds no Ingredient pantry field, no op that wrote one, no `pantryBackfill` op (G206). | new test `theICloudCopyDropsPantryState`, BackupTests.swift | Core | PE25 |
| PS-E2 | The local backup keeps every pantry field and op (G206). | new test `theLocalBackupKeepsPantryState`, BackupTests.swift | Core | PS-E1 |
| PS-E3 | No path writes `state` without a shop clear, `FinishCooking`, a phrase or a tap; opening a page or a launch writes nothing. | new test `onlyFourEventsWriteState`, ShopClearsTests.swift | Core | PE15 |
| PS-E4 | Setting out (phrase aside) adds no Groceries row on its own; only "out of X" and a tap or swipe add. | new test `outByCookAddsNoRow`, CookingTests.swift | Core | P13 |
| PS-S1 | Switch Off: recipe page, Groceries, Pantry match today (P5). | walk: flip switch 21, open D1, Groceries | Builder B | switch 21 |
| PS-S2 | No state change gives more than one soft `.selection`; a no-op tie gives none (G178). | HapticMapTests.swift, new case | Builder B | S7 |
| PS-S3 | No red, notification, badge or drawn food image on any state surface. | walk + grep views for red, images | Design | PO05 |

Review switch: Pantry state, default Off, before/after: Off, Groceries and recipes as today / On, each ingredient reads in, low or out and planning skips in lines.
Ruled: screen words are In / Low / Out (engine value "in"), so switch 21's wording changes to match. State words are ink only (G175, PO01); drop ochre from S3 and S17.

## CC What can I cook
Already covered: W1-W10, PD22-PD30, PE02-PE04, PE07-PE08, PP08.

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| CC-E1 | A recipe is judged only when at least 60% of its non-staple lines have a known state and at least 3 lines are known (G209). | new test `canCookNeedsSixtyPercentAndThreeLines`, RecipeMathTests.swift | Core | PD22 |
| CC-E2 | Below the bar a recipe is listed after the judged ones as "N to check" (G209). | new test `belowTheBarListsAfterAsToCheck` | Core | CC-E1 |
| CC-E3 | The filter word stays grey until at least one recipe clears the bar, not on the first known state. | new test `oneKnownStateKeepsTheWordGrey` | Core | CC-E1, PE01 |
| CC-E4 | Staples never count toward the 60% or the floor. | new test `staplesNeverCountTowardTheBar` | Core | PD21 |
| CC-E5 | The filter never adds a row on its own. | grep AddGroceries callers (tap path = PE07) | Core | PE07 |
| CC-S1 | A private recipe reads "Private recipe" and a private ingredient "Private item" in the missing line; no tap reveals the name. | RecipesShelfTests.swift, new case | Builder B | W10, PE27 |
| CC-S2 | "N to check" rows sit below a hairline at 55% ink, no pill, no red. | walk: 2 judged, 3 below bar | Builder B | CC-E2 |
| CC-S3 | Tapping the greyed word speaks the empty line once, no haptic (PE02); a judged tap gives one soft `.selection`. | RecipesShelfTests.swift | Builder B | PE02 |

Review switch: Can cook shelf, default Off, before/after: Off, the shelf keeps QUICK, NOT LATELY, FROM THE BASKET / On, CAN COOK replaces FROM THE BASKET and greys until a recipe clears 60% (floor 3).
Ruled: Can cook is the Recipes shelf's third filter word (backlog and W1 win); switch 22 only gates it. W7 is reworded to follow G209: judged recipes first, below-bar ones after, "N to check" only when something is known. CC-S2's hairline is inferred.

## RL Running low by rhythm (USUALLY)
Already covered: K44.1-K44.16, groceries-ai sec 4 rows 7, Pantry S5-S6, PW09-PW11, PW17, P10.

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| RL-E1 | Due window is 0.85 U to 2 U after the last buy, not the backlog's 1.5x. | new test `dueFromPointEightFiveU`, GroceryTests.swift | Core | Research 20-week fixture |
| RL-E2 | Buys older than 56 days do not count toward the 3. | new test `buysPastFiftySixDaysDoNotCount` | Core | RL-E1 |
| RL-E3 | Reads `checkedAt` history only; works with Pantry state Off. | new test `usuallyWorksWithPantryOff` | Core | switch 21 |
| RL-E4 | One quiet mark per shop run; a new buy clears it (`usualSkippedAt`). | covered by K44.5-K44.6 | Core | |
| RL-S1 | The same names show at the foot of Groceries and on Pantry, same order, same cap 4. | new test `usuallyIsOneListOnBothPages`, PantryFrontTests.swift | Builder B | S5, K44.2 |
| RL-S2 | A walled name reads "Private item" on both pages, no reveal. | K44.8, walk | Builder B | |
| RL-S3 | A tap gives one soft haptic and the receipt; nothing is added without the tap. | HapticMapTests.swift + K44.12 grep | Builder B | K44.4 |

Review switch: Usually line (new, inferred), default Off, before/after: Off, Groceries and Pantry end with no USUALLY line / On, up to 4 names he buys on a rhythm show at the foot.
Ruled: USUALLY is 21/400 at 55% on Groceries, label USUALLY; the Pantry label is USUALLY HAVE (backlog look; keeps the 3-size limit). "Oat milk, not now." stands (Product, Oct 19).

## AO Store aisle order
Only the backlog line and K46.4 ("no per-store order in v1") exist. Gate: only if he says a shop's order feels wrong.

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| AO-E1 | A finished shop records its aisle order as the order of first `checkedAt` per aisle. | new test `checkOffOrderGivesAisleOrder`, ShoppingTests.swift | Core | FinishShop |
| AO-E2 | An item moves only when checked off in the same relative place in 2 of his last 3 shops (ruled Oct 19). | new test `orderNeedsTwoOfThree` | Core | AO-E1 |
| AO-E3 | Learning moves aisles, never an item's learned aisle (K36.6 stays). | new test `aisleOrderLeavesItemAislesAlone` | Core | K36.6 |
| AO-E4 | One learned order serves every shop (no shop object); with nothing learned, the default walk order holds (ruled Oct 19). | new test `noLearnedOrderKeepsDefault` | Core | AO-E2 |
| AO-E5 | No shop name or order leaves the phone (pack, Claude, shared export). | ExportTests.swift + groceries-ai row 5 | Core | |
| AO-S1 | Groceries, the trip hero and "then X" all read the learned order. | walk: K46.1 with a learned fixture | Builder B | AO-E2 |
| AO-S2 | A re-order slides once on open (`.tesseraAnimation`; Reduce Motion crossfades), no receipt or haptic (inferred). | walk | Builder B | AO-S1 |

Review switch: Learned aisle order, default Off, before/after: Off, aisles in the fixed walk order / On, aisles in the order he walked this shop.
Ruled (Product, decisions.md 6:00 PM Oct 19): one learned order for all shops, no shop object; an item moves only when checked off in the same relative place in 2 of his last 3 shops; switch Off. So AO-E4 (per shop) is replaced by one order for all shops, and AO-E2's 2-of-3 bar is a ruling. Open: resetting a learned order is not ruled.

---

*Docs only, nothing run. Sources: `kitchen-v2-backlog.md`, `kitchen-v2-scope.md`, `meal-plan-groceries-acceptance.md` (MP, KW rulings #499), `kitchen-refill6-lane1-acceptance.md` (K38), `groceries-ai-acceptance.md` sec 3-4, `recipe-edit-acceptance.md`, `lists-acceptance.md` sec 4. Product ruled leftovers and recurring into v2 behind their own switches.*

## WD. Week of dinners (strip on Plans' `WeekPage`)
Covered: plan adds rows on capture (groceries-ai sec 3), skip (K38.9-11), no reset (K38.12), DONE closes plan (MP-F1-F7), empty week (K38.1-5).

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| WD-E1 | The strip lists each dated cook task Mon-Sun by the 4 AM day, skipped ones as "Tacos, skipped" | new test, `GroceriesWeekTests.swift` | Core | KW ruling 1 |
| WD-E2 | ADD THE WEEK runs `AddRecipeToGroceries` only for plans with no `groceriesAddedAt`; added plans are untouched | new test, same file | Core | MP "only once" |
| WD-E3 | One op, one receipt "Week, 5 added." and one UNDO 4 s removes exactly those rows | new test | Core | WD-E2 |
| WD-E4 | Every plan already added: "Week, nothing to add.", no op, no UNDO | new test | Core | WD-E2 |
| WD-E5 | A skipped or done plan is never added by the tap | new test | Core | KW ruling 1 |
| WD-S1 | Strip uses `WeekPage` layout, ink words, no cards, no food drawings; private reads "Private recipe" | walk: plan 3 cooks, open strip | Builder B, Design | WD-E1 |
| WD-S2 | Nothing reaches Groceries until he taps the key | walk: open strip, check Groceries count | Builder B | WD-E2 |
| WD-S3 | Never red, no "overdue"; one soft haptic on the add; Reduce Motion crossfade; VoiceOver reads day as heading | walk + K38.22-24 | Builder B | WD-S1 |

Review switch: Week strip, default Off, before/after: Off: plans show on the week side only. On: a Mon-Sun strip with one key to add the week to Groceries.

Ruled: a cook on another day still closes the plan (KW ruling 4 wins); MP-F3 is reworded. Open: rows land on capture already, so the key only matters for plans linked later; is it wanted? "Week" as the receipt's thing word is inferred.

## RG. Recurring groceries (flag on list item)
Covered: USUALLY suggestions (groceries-ai sec 4, R rules); Groceries not reusable (lists sec 4).

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| RG-E1 | A Groceries item gains a `repeats` flag (weekly); no new class, no catalog class | new test, `GroceryTests.swift` | Core | catalog field |
| RG-E2 | Only his tap sets or clears the flag; one op, UNDO 10 s | new test | Core | RG-E1 |
| RG-E3 | `FinishShop` clears a checked flagged item, then puts it back open, inside the same op | new test, `ShopClearsTests.swift` | Core | RG-E1 |
| RG-E4 | An unchecked flagged item stays one row; never a duplicate | new test | Core | RG-E3 |
| RG-E5 | A flagged item never also shows in USUALLY | new test | Core | R |
| RG-E6 | A private item keeps "Private item" when it comes back | new test, `GroceriesWallTests.swift` | Core | RG-E3 |
| RG-S1 | "milk every week" flags milk; receipt "Milk, every week." UNDO 10 s | walk: type it on Add line | Builder B | RG-E2 |
| RG-S2 | A flagged row shows one quiet word, no pill, no icon, never red | walk | Builder B, Design | RG-E1 |

Review switch: Repeat items, default Off, before/after: Off: a bought item leaves with the shop. On: an item marked every week comes back after the shop ends.

Ruled: setting the flag counts as his tap; each return shows with a 10 s UNDO (add to RG-E3 and RG-S1 checks). Open: intervals other than weekly.

## LO. Leftovers and cook double
Ruling #499 (KW19, A9): leftovers OUT of the week plan. Product ruled 12:47 PM Oct 19 that it ships as "Cook double" scaling plus one undated Later task, behind its own Review switch (default Off), which stays inside KW ruling 5; so LO-E1 to LO-S2 are build rows now, not gated on his ask, and K38.19 changes only when the switch is On. The feature may only: scale the cook and add one Later task. It never makes a plan, never shows on the strip or week side, never adds rows, keeps no portion count in Pantry.

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| LO-E0 | With the switch Off, "cook double chili" is not read (K38.19) | existing K38.19 test against master | Core | none |
| LO-E1 | "cook double chili" starts the cook at 2x serves via `RecipeMath.scaled` | new test, `CookingTests.swift` | Core | switch On |
| LO-E2 | On DONE, one Later task "Chili leftovers, 2 portions" with no date | new test | Core | LO-E1, MP-F1 |
| LO-E3 | That task is not a plan: no share, no rows, not on strip, not counted in "Cook 2 of 4" | new test | Core | LO-E2 |
| LO-E4 | Abandoned cook makes no task | new test | Core | LO-E2 |
| LO-E5 | Private recipe: task reads "Private recipe leftovers" | new test | Core | LO-E2 |
| LO-S1 | DONE receipt "Chili, done. Leftovers on Later." one UNDO 10 s restores both | walk | Builder A | LO-E2 |
| LO-S2 | Doubled amounts roll on the cook page; adding them to Groceries needs his tap | walk | Builder A | LO-E1 |

Review switch: Cook double, default Off, before/after: Off: "cook double" is not understood. On: it doubles the cook and puts a leftovers task on Later.

Open: portion count = extra serves, inferred; receipt wording inferred.

## RE. Recipe edit in place
Covered: `recipe-edit-acceptance.md` Core 1-6, Builder B 1-5.

| ID | Clause | How checked | Owner | Depends on |
|---|---|---|---|---|
| RE-E1 | A rename updates the short name; strip, Home, "for tacos" lines and count line follow | new test, `RecipeTests.swift` | Core | Core 1 |
| RE-E2 | A private recipe's receipt reads "Private recipe, fixed." | new test, `PrivateRecipeCookTests.swift` | Core | Core 1 |
| RE-E3 | Edit while a cook runs: running step list unchanged until DONE | new test, `CookingTests.swift` | Core | Core 3 |
| RE-E4 | Save with every line marked ignore is refused; recipe unchanged | new test | Core | Core 1 |
| RE-S1 | Drag on a step number reorders; one `.selection` | walk: drag step 3 above 2 | Builder B | Core 3 |
| RE-S2 | Return inside a step splits it; delete at start joins | walk | Builder B | Core 3 |
| RE-S3 | Edited line never red; Dynamic Type AX one column; VoiceOver names "Edit line" | walk | Builder B | B5 |

Review switch: Fix a recipe, default Off, before/after: Off: no FIX word; paste again to change a recipe. On: FIX opens the recipe to change lines and steps.

Open: (1) FIX word and long-press gesture await Design. (2) RE-E4 refusal wording not written.

---

Cited: PS = `parallel-steps-acceptance.md`, CM = `cook-mode-acceptance.md`, K84 = cook-mode accessibility, N21-N26/D01 = `kitchen-cook-gate-rows-oct17.md`, P = `recipe-plate-acceptance.md`. House rules hold on every row (one UNDO, never red, one soft haptic, "Private recipe", no key-shaped fixtures).

## PL Parallel steps (nothing built; PS1-PS14 stand)
| ID | Clause | How checked | Owner | Depends |
|---|---|---|---|---|
| PL-E1 | Only the 7 cue phrases at a step's start open a track, and only beside a host waiting 5 min or more | PS8, PS9; new `cueOpensTrackOnlyWithHost` in `RecipeTracksTests.swift` (new) | Core | - |
| PL-E2 | "drain", "remove from the oven", "when the timer goes" or the host's subject closes that track; the next step starts at the join | PS6; new `closersJoinTheTrack` | Core | E1 |
| PL-E3 | One start-minute function feeds clock and cook mode; D1-D3 give PS1, PS2, PS7, PS12 numbers exactly | new `vectorsMatchClockSteps` | Core | E1 |
| PL-E4 | No cue and no kept pair gives today's one-lane minutes | new `noCueIsTodaysClock` | Core | E3 |
| PL-E5 | Proposal: step texts and waits only, at most 3 checked pairs, never mid-cook, only with Claude on, keyed, online, under cap | PS11; new `proposalPackAndChecks` | Core | E3 |
| PL-E6 | A kept pair is stored on that recipe only, one op, one UNDO | new `keptPairPerRecipeUndoes` | Core | E5 |
| PL-S1 | Two lanes drawn only where tracks overlap; never three | PS1, PS7 walk | Builder A | E3 |
| PL-S2 | Two cook lines, two timers, NEXT within current track | PS3, PS4, PS5 | Builder A | E3 |
| PL-S3 | VoiceOver reads the other track after the current step; words proposed | new walk | Design | S2 |
| PL-S4 | Proposal bracket is faint ink, not cobalt; keep receipt words proposed | PS11 walk | Design, Builder A | E5 |

Review switch: Parallel steps, default Off, before: one lane, steps one after another as today / after: "meanwhile" steps run on a second lane with their own timer.
Open: VoiceOver words for the second line; do proposals also need "Tess asks Claude" (inferred yes).

## HF Hands-free cook mode
Ground: listening is tap or hold today (`SpeechListener.swift`, on-device, 1.2 s pause, 60 s cap). Cook grammar reads only "next", "next step", "done", "finished", "done with that" (`TessGrammar.swift:255`), replying "Step N." or "<title>, done." (`TessCaptureEngine.swift:445`).

Word set (minimal = next, back, timer):
| Word | Phrases | Action | Reply | Status |
|---|---|---|---|---|
| next | next, next step | step +1 in current track | "Step N." (code) | written |
| back | back, go back | step -1, never below 1 | "Step N." | proposed |
| timer | "8 mins", "pasta 10", "timer bread 8" | timer | "Timer, 8 min." / "Pasta, 10 min." | written N21, N22 |
| stop | stop the rice | stop that timer | existing stop line | written N25 |
| how long left | same | read only | not written | N24 |
| step N | step 3 | go to step | not written | N26 |
Left out: undo (works today), pause/resume, "5 more" (CM 3, 4), "finished cooking" (N23).

| ID | Clause | How checked | Owner | Depends |
|---|---|---|---|---|
| HF-E1 | Every word above is read on the phone; Claude spy 0 | `cook_*` tests named in N21-N26; new `cook_backGoesToPreviousStep` in `TessTests.swift` | Core | G423 (#884 route) |
| HF-E2 | A held phrase with no local reading says "Didn't catch that.", no retry, no haptic | D01 | Core | E1 |
| HF-E3 | Over 600 characters: "That's too long to send. Say it shorter." | G423 rows | Core | E1 |
| HF-E4 | With no running cook the words take the normal route | N21-N26 off row | Core | E1 |
| HF-E5 | "back" on step 1 and any word after Finish change nothing | new `cook_backStopsAtStepOne` | Core | E1 |
| HF-S1 | Listening runs only while the cook page shows and the switch is on; ends with the awake rule G218 (inferred) | new walk | Builder A | E1 |
| HF-S2 | Audio and words never leave the phone; no language means the refusal line, touch still works | `SpeechListenerTests.swift`; refusal lines walk | Builder A | - |
| HF-S3 | Cancel during the first mic ask leaves no live listen | G447 (#1060), `SpeechListenerTests.swift` | Builder A | - |
| HF-S4 | A voice step moves like the Next key | K84.17 | Builder A | S1 |
| HF-S5 | A listening mark on the cook page; look proposed | new walk | Design | S1 |

Review switch: Hands-free cook mode, default Off, before: you touch the Next key / after: you say "next", "back" or a timer.
Ruled: hands-free "back" approved; its reply is plain "Step N." (status: approved, still to be written in grammar). Done by voice says "<title>, cooked."; Builder A changes `TessCaptureEngine.swift:452`. Open: always-on listen vs a tap per phrase; replies spoken or shown only; "how long left" and "step 3" reply words.

## LF Link fetch L2 and L3
Ground: L2 and L3 already run in `RecipeLinkReader.swift` with a regex text reader; `kitchen-v2-scope.md` calls L1-L3 shipped. Rows cover the gap to the backlog.
| ID | Clause | How checked | Owner | Depends |
|---|---|---|---|---|
| LF-E1 | Dropped by ruling 9: the regex reader in `RecipeImport` stays; no SwiftSoup, no new target (`TesseraCore` keeps GRDB only) | `Package.swift` read | Core | - |
| LF-E2 | Text read prefers WPRM, Tasty, then article/main; drops nav, comments, share, ads | `aPageWithNoCardIsReadFromItsText`; new `visibleTextDropsChrome` in `TesseraImportTests` (new) | Core | E1 |
| LF-E3 | "10 minutes mins" and "Prep: 10 M" read as 10 | new case in `RecipeTests.swift` | Core | - |
| LF-E4 | Page text gives a recipe only with 2 to 80 ingredients and 1+ step | new `pageTextOver80IsRejected` | Core | E2 |
| LF-E5 | piperhaywood (#9) and Substack read by text; #4 paywall and #10 video lines show | curl fixtures, `swift test` | Core | E2 |
| LF-E6 | Claude only after L1 and L2 fail, on, keyed, online, under cap | `claudeReadsOnlyWhenAllowedAndUnderTheCap`, `theClaudeStepChecksTheSwitchItself` | Core | - |
| LF-E7 | Claude's reply is parsed as text (code wins, ruling 9) and shown as a pending ghost; the app sets `sourceURL`, `sourceText` | new `claudeReadIsPendingGhost` (today text, line 603) | Core | T2/T3 |
| LF-E8 | 24,000 characters, private lines cut, page orders ignored | `recipeReaderCapsPageBytesAndOutput`, `privateLinesNeverReachClaude`, `recipeReaderIgnoresPageInstructions` | Core | - |
| LF-S1 | Cadmium wash, "Reading <host>.", no spinner; Claude's ghost streams cobalt, dries on Save | walk | Builder B | E7 |
| LF-S2 | Every failure keeps the link and opens a writing line; no modal, no code | `blockedAndPaywalledSayWhatToDo`, walk | Builder B | - |

Review switch: Link reader v2, default Off, before: today's page reader / after: the second reader and Claude's read (what each is today is a contradiction, below).
Ruled: where code exists, code wins and the backlog text is updated: regex reader in RecipeImport (so LF-E1 SwiftSoup/TesseraImport is dropped), Claude's reply parsed as text (LF-E7 follows code), user agent "Tessera/1 (iPhone; personal recipe import)", the link kept and read on his tap, code's blocked and paywall wording.

## CN Cook notes into the recipe
Ground: @recipe is a backlink (`NoteList.notes(about:)`); `FinishCooking(note:)` exists but Finish has no note field (CM).
| ID | Clause | How checked | Owner | Depends |
|---|---|---|---|---|
| CN-E1 | A recipe's notes are Notes linking it plus its cooks' notes, newest first (inferred) | new `recipeNotesGatherBoth` in `RecipeTests.swift` | Core | - |
| CN-E2 | The newest note since the last cook shows until the next cook finishes (proposed) | new `noteShowsUntilNextCook` | Core | E1 |
| CN-E3 | A private note shows "Private note", no reveal | new test | Core | E1 |
| CN-E4 | Notes never go to Claude and never scale or edit lines | PL-E5 pack test; new `notesNeverScale` | Core | E1 |
| CN-S1 | The note line on the recipe page, in ink; place proposed | new walk | Design, Builder B | E2 |
| CN-S2 | Cook mode's first step shows the same line (proposed) | new walk | Builder A | S1 |

Review switch: Cook notes on the recipe, default Off, before: notes live in COOKS and backlinks / after: the newest note shows on the recipe page.
Ruled: add an optional "Note for next time" line on cook Finish (empty by default, no extra step) feeding `FinishCooking(note:)`; voice "note: less salt" also works. Add rows CN-S3 (the line is empty by default and adds no step; Finish with it empty is today's Finish) and CN-E5 (voice "note: less salt" writes the same note; walled text stays on the phone). Open: which notes count (all, or "next time" ones).
---

## Contradictions between sources: rulings

Product ruled all 12 at 12:47 PM Oct 19 (defaults, reversible), folded into the sections above.

1. **CAN COOK**: the Recipes shelf's third filter word; switch 22 only gates it.
2. **W7**: reworded to follow G209.
3. **USUALLY**: 21/400 at 55% on Groceries, label USUALLY; Pantry label USUALLY HAVE.
4. **Pantry colour**: ink only; ochre dropped from S3 and S17.
5. **State words**: In / Low / Out; switch 21 wording changes to match.
6. **Leftovers**: ship as Cook double plus one undated Later task, own switch, default Off.
7. **Recurring groceries**: setting the flag is his tap; each return has a 10 s UNDO.
8. **Which cook closes a plan**: a cook on another day still closes it (KW ruling 4); MP-F3 reworded.
9. **Link fetch**: code wins; backlog text is updated.
10. **Done by voice**: "<title>, cooked."; Builder A changes `TessCaptureEngine.swift:452`.
11. **Cook notes**: optional "Note for next time" line on Finish feeding `FinishCooking(note:)`; voice "note: less salt" also works.
12. **Hands-free**: "back" approved, reply plain "Step N."

## Looks: Design sheet 114 (Kitchen v2 looks)

Design item 114 (`design/kitchen-v2-114.md`, Oct 19) draws these screen rows. Rows keep their ids; the sheet gives the look and the wording.

| Rows | Sheet 114 section | What it fixes |
|---|---|---|
| WD-S1, WD-S3 | 1 Week strip | one row per day, "Tacos, skipped" in secondary ink with no strike, key "Add the week to Groceries", receipt "Week, 5 added." UNDO 4 s |
| RG-S1, RG-S2 | 2 Repeats word | quiet word "weekly" at the row's right; tap clears, "Milk, not every week." UNDO 10 s |
| HF-S5 | 3 Listening mark | the word "Listening" with a breathing hairline, no mic icon; static under Reduce Motion and Low Power |
| CN-S1, CN-S2 | 4 Note line | "Last time: less salt." on the recipe page and the first cook step; optional "Note for next time" line on Finish |
| RE-S1 to RE-S3 | 5 FIX | top-right word FIX or long press on the title; step number is the drag handle (hold 0.3 s); refusal "Nothing saved: every line is ignored." |
| PL-S3, PL-S4 | 6 Second lane | "Meanwhile, rice, step 2 of 4, 9 minutes left."; proposal bracket at 25% ink, read as "Proposed" |
| CC-S2 | 7 Also | "2 to check" block under a hairline, rows at 55% ink |
| AO-S2 | 7 Also | headings slide once on open, 240 ms; 150 ms crossfade under Reduce Motion |

Switch wording on the Kitchen page (sheet 114): "Week strip is off.", "Repeat items are off.", "Hands-free cooking is off.", "Cook notes on the recipe are off.", "Fixing a recipe is off.", "Steps run in parallel are off." Accepted switch ids (Product, Oct 19, all default Off): weekStrip, repeatItems, cookDouble, parallelSteps, cookNotes, fixRecipe, usuallyLine, aisleOrder.
