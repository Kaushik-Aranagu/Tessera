# SideHost review checklist (Research BF)

*Research, Oct 16. For QA to run on Core 0ak (SideHost plus the default object side). Read against origin/master 64ffb93. Docs only. Each row passes or fails. "Decision" cites `product/decisions.md` by entry time (the file on the shared folder: 2:41 PM at line 21, 2:37 PM at :17, 2:40 PM at :13, 2:44 PM at :9, 2:45 PM at :7). "Sheet 75" is `design/every-side.md` (Design 25b385e, the two-stop addendum 254f6d5). Fixture IDs (SL-, GL-) are in `docs/research/fixtures/side-lines.md`; leak IDs (PL1 to PL4) are in `docs/research/screens-inventory-check.md`. Test names are the ones to look for in the PR; a row whose test is missing fails unless the simulator step passes and the PR names its own test.*

Setup for the simulator rows: iPhone 17, launch with `-demoTime 18:10 -resetDemo`. Open a generic object page (Home, then the class tree, then an Equipment object such as "Rack"). "Swipe left" means a pan that starts above y 736 (sheet 75 rule 4, every-side.md:16).

## The two stops

| ID | Do | Expect | From |
|---|---|---|---|
| SH1 | On the generic page, swipe left about 100 pt and let go before half the width (201 pt on iPhone 17). | Stop 1, the glance: it fills the right half from x 150, below the context line (186) to above Tess's band. Its left edge is a 34 pt fade, with no line and no card. The front stays in place under it at 30%. It shows the side's label, one big fact (Hero 56, unit at 21), at most two small facts (Body 19), and the side's word at its foot ("ALL FACTS" or "ALL LINKS"). No haptic. | 2:37; every-side.md:90-93, :97 |
| SH2 | From the front, swipe left past half the width. | Stop 2, the full side. The front leaves as in sheet 71; the back word and title stay put (the spine). One `.selection` haptic, the only one. | 2:37; every-side.md:17, :95, :97, :123 |
| SH3 | At stop 1, tap the word at its foot. Then, separately, use the word at the right of the context line from the front. | The glance fades into the full side. The context-line word opens the side; on the side, the same place names the front. | 2:37; every-side.md:15, :95 |
| SH4 | At stop 2, swipe right. Swipe right again. | First swipe lands on stop 1 (the glance), not the front. Second lands on the front. One stop at a time, never two. | 2:37 |
| SH5 | At stop 1 and at stop 2, start the pan at the left edge. | The left edge is back to the page before, from either stop. | 2:37; every-side.md:96 |
| SH6 | Start a left pan at or below y 736. | Tess's band takes it; no side opens. | every-side.md:16 |
| SH7 | Look for `sideLineIsTheSameAtBothStops`. On the simulator, compare the band at stop 1 and stop 2. | The same one line at both stops. It lands when stop 1 settles, at 420 ms. | every-side.md:105, :122; side-lines.md 6 |
| SH8 | Watch Tess while moving front, stop 1, stop 2, stop 1, front. | Her `sideTurned` glance plays only on the move into stop 1 and on the move that lands back on the front, never between the stops, and comes from the SideHost (not each screen). | every-side.md:121 |
| SH9 | Read the side's content. | No control on a default side: facts and links only, no key. | 2:41 (a); every-side.md:18 |

## The glance's edge cases

| ID | Do | Expect | From |
|---|---|---|---|
| SH10 | Look for `glanceLeavesOutEmptySmallFact` (GL-E1, GL-E2). On the simulator, use an object with one shown field and no backlinks. | A small fact with no value is left out: no blank row, no dash, no "none". With both empty, the big fact stands alone. | every-side.md:157 |
| SH11 | Look for `glanceWithoutBigFactOpensFullSide` (GL-E3, GL-E4, GL-E10). On the simulator, use an object with no hidden fields and no links. | No glance. The swipe opens straight to the full side. A zero is never the big fact. A swipe right from that side goes to the front (there is no stop 1 to land on). | every-side.md:104, :157 |
| SH12 | Look for `glanceListsUseAndNMoreFromFour` (GL-E6). Give an object 5 backlinks, then 3. | With 5: a count, then names, and the second slot reads "Tile quotes and 3 more" (the name is kept). With 3 or fewer: names only, no "and N more". | 2:44 (6); every-side.md:94, :147 |

## The default object side

| ID | Do | Expect | From |
|---|---|---|---|
| SH13 | Open stop 2 on the generic page. | LINKS (what it's linked from and what it links to) plus every field the front doesn't show. Nothing the front already shows is repeated. | 2:41 rollout; every-side.md:57 |
| SH14 | Look for a Core test of the most-used field. Fixture: field A edited 6 times 40 days ago, field B edited 2 times in the last 10 days, field C never. | The glance's big fact is B's value (edited most in the last 30 days, counted from the op log). Small 1 is the next field; small 2 is "linked from N". The PR states its tie rule. | 2:44 (7); every-side.md:151 |
| SH15 | Tess's line on the default side (SL-O1, SL-O2, SL-L1). | "Linked from 3 things." with 3 backlinks; an empty band at 0. An empty band is correct, never filler. | every-side.md:20; side-lines.md 2 |

## The four leaks (must-fixes in 0ak)

| ID | Do | Expect (the exact fix) | From |
|---|---|---|---|
| SH16 | PL1. Look for a Core function that screens an exercise's `notes` line by line, and its test (`walledSetupLineStaysOffTheGlance`, GL-E8). Fixture notes: "Third hole" / "left knee sore, locker code 4471". | Each line runs through `SecretWords.mentions` (`Notes/SecretWords.swift:34`) and `PrivateFacts.isWalled` (`Tess/PrivateFacts.swift:17`). Lines that pass show; the rest are counted ("1 line kept private") and never shown. A walled line is never the glance's big fact and never reaches any ask. `notes` is `SystemCatalog.swift:57`. | 2:44; PL1 |
| SH17 | PL2. Look for the default side's filter and a Core test that runs every catalog field through it. Fixtures: a private note (`body`, :216, `isPrivate` :220), a cook's `note` (:320). | An object with `isPrivate == true`, or titled `SecretWords.title`, gets a count only on its side: no field values, no title. For every other object, any value that fails `SecretWords.mentions` or `PrivateFacts.isWalled` is dropped. | 2:44; PL2 |
| SH18 | PL2, the Tess memory case. Open a private Tess memory (`isPrivate` "Stays on this phone", `SystemCatalog.swift:264`) on the generic page through the class tree; open both stops. | The side shows no private field (`rule`, :258) and names nothing. This holds on its own: it must not depend on Core 0ai's front mask (2:45), which may land before or after 0ak. | 2:45; every-side.md:161 |
| SH19 | PL3. Look for `glanceNeverNamesAPrivateObject` (GL-E9). Open the Note class page's side with 12 notes, the newest private. | Private objects count, and the newest slot shows the private label ("Private note"), never the title (2:45 amended 2:55, over PL3). They are never "the most used". The glance reads "12 objects", "Private note" as the newest, and "5 private" when any are private. | 2:44; PL3; 2:45 amended 2:55 |
| SH20 | PL4. Read `Notes.swift` `resolve` on the PR branch; run `aPrivateNoteIsNeverAMentionTarget` (`SecretWordsTests.swift:166`). | `resolve` skips objects whose `isPrivate` is true. Already on master at `Notes/Notes.swift:42-46` (5c22981, #551); the PR must not undo it. "@Private note" in a plain note links nothing, so no side reaches a private note through a link. | 2:44; PL4 |

## No Claude from any side or glance

| ID | Do | Expect | From |
|---|---|---|---|
| SH21 | In the PR branch, search the diff from origin/master for `ClaudeTessModel`, `ClaudePlanWording`, `ClaudeRecipeReader`, `asksClaude` and `planWording`. Then for each SideHost or side file, `grep -n "import TesseraTess"` and trace every symbol it uses. | No hit in any SideHost, side or glance file, and no call path from them to `ClaudeTessModel` (`TesseraTess/ClaudeTessModel.swift:9`), `ClaudePlanWording` (`TesseraTess/PlanWording.swift:418`), `ClaudeRecipeReader` (`TesseraTess/RecipeLinkReader.swift:327`) or `AppModel.asksClaude` (`App/AppModel.swift:58`). | 2:41 (a); 2:40 (3) |
| SH22 | With "Tess asks Claude" on, note the count on Claude receipts. Open both stops on 10 different objects, including a note and a Tess memory. Check receipts again. | The count is unchanged. No `Tess Call` object is made. | 2:40 (3) |
| SH23 | Look for `rewordingIsOffByDefault`. Search the PR for an "Ask about this" entry on a side. | Tess's line is the phone's rules line; rewording is off. No ask-about-this ships in 0ak: the per-class opt-in (2:40 (3), (4)) waits for the BD4 eval and Kaushik's yes. | 2:40 (3), (4); side-lines.md 1 |

## Lines, moves, cadence, habits

| ID | Do | Expect | From |
|---|---|---|---|
| SH24 | Look for `sideLineFitsHomeDetailCap`, `sideLineNeverRepeatsOwnTitle`, `designTwoSentenceLineIsRefused`. | Every line is one sentence under `HomeLines.fitsDetail` (14 words, 80 characters, ends in a stop, no ". " inside), like "Moved twice, due today.". The line never leads with or repeats the page's own title (no thing-first on a side). | 2:44 (1), (2) |
| SH25 | Look for `taskStoryCountsHandMovesNotNightlyRolls` (SL-T1, SL-T2). Fixture: a task with 2 `moveTask` ops by `.user` and 2 `rollForwardTasks` ops (run `by: .system`, `Tasks/RollForward.swift:103`). | Moves = 2. Rolls never count as moves and are never shown as misses; they show only as "First planned {day}". | 2:44 (3) |
| SH26 | Find the Core cadence helper and its tests (`ingredientCadenceNeedsThreeBuys`, SL-I1, SL-I5). Fixture: buys on Sep 12, 21, 30 and Oct 9 as `checkListItem` ops, the item linked by `about` to Rice, the rows deleted at the shop's end. Add one `.system` op on the same item. | It reads the op log (the rows are gone), counts only his own ops (`.user`, `Actions/Op.swift:6`), never `.system` ones, and gives "You buy it about every 9 days." With 2 buys: empty. | 2:44 (3), (5) |
| SH27 | Look for a test of a body-named habit. Fixture: a habit "Weigh in", done 4 of 7 days, with a value logged. | Its side and glance show the count only ("4 of 7 days this week."), never the value, never "kg". | 2:44 (4) |
| SH28 | Look for `exerciseLineSaysBestNeverRecord`, `sideLineTimesAreTwelveHourLowercase`. | "best", never "record" or "PR"; times like "8:30 pm"; weights in kg. | side-lines.md 1 rule 4 |

## Reduce Motion, VoiceOver, Dynamic Type

| ID | Do | Expect | From |
|---|---|---|---|
| SH29 | Turn on Reduce Motion. Go front, stop 1, stop 2, stop 1, front. Grep the side files for `withAnimation(` and `.animation(`. | Each stop is a 200 ms crossfade, no spring, no slide. Tess's glance does not play. Every animation goes through `MotionPolicy` (`.tesseraAnimation`, `withTesseraAnimation`). | 2:37; every-side.md:97, :121; CLAUDE.md |
| SH30 | VoiceOver on. From the front, use the side's accessibility action (or the context-line word) to open stop 1. | Focus lands on the glance's label. The big fact reads as one element with its unit ("4 to go"), then the small facts, then the word as a button. The dimmed front is not focusable at stop 1. Escape (two-finger scrub) goes back to the front. | 2:37; CLAUDE.md |
| SH31 | VoiceOver on, at stop 2. | Every fact and link reads in order; Tess's line is read once. Escape goes to stop 1, then to the front: one stop at a time, as the swipe. | 2:37 |
| SH32 | Largest accessibility text size; open both stops. | The big fact and small facts wrap or scale without clipping; the glance still fits its half or opens straight to stop 2. | CLAUDE.md |

## Live covers and other stacks

| ID | Do | Expect | From |
|---|---|---|---|
| SH33 | Start a workout. On the live surface itself, swipe left over the exercise lane; pull the name down. Look for `liveWorkoutHasNoSideLine` (SL-X1). | x stays the lane. The live side is the running order by pull down, as built, a peek over the live surface. No Tess line. | every-side.md:19, :42; 2:45 |
| SH34 | In the live cover, open an exercise, then a path word to a class page or a generic object (pushed through `WorkoutModeView.swift:22-23`). Open its side. | The pushed page is not live: its normal side, both stops, as in SH1 to SH5. Not a peek. Closing it returns to the live surface unchanged. | 2:45 |
| SH35 | In the Recipes cover, open a recipe, then an ingredient (generic, `RecipePage.swift:308`), then a "Linked from" row. Open the side on each generic page. | The default side works in this stack, both stops, the same as on the root stack. | every-side.md:160 |
| SH36 | Paste a recipe and save it, so `RecipePage` is pushed through `RecipesEntry.swift:36`. Swipe left there. | Same behavior as the recipe in the Recipes cover: a side if the PR gives one, else nothing changes from master. No crash, no second gesture. | every-side.md:160 |

## Review rule

| ID | Do | Expect | From |
|---|---|---|---|
| SH37 | Find the registry test that fails a screen with no side. List the screens the PR adds or changes. | Each added or changed screen declares a side (the generic page at least). Screens the PR doesn't touch are on a named waiting list and don't fail. Overlays are exempt: capture veil, Speak, the running order, the swap panel, the live ask sheet. | 2:41 (c); every-side.md:18, :80 |
| SH38 | Add a throwaway screen to the registry with no side, run the test, then remove it. | The test fails, naming the screen. | 2:41 (c) |

## How to run

1. `git fetch origin` and check out the 0ak branch. Run `scripts/test.sh`; it must end "All green".
2. Run SH21 and the test-name rows (SH7, SH10 to SH12, SH14, SH16 to SH20, SH23 to SH28, SH33, SH37, SH38) from the test log and the diff.
3. Run the simulator rows with `-demoTime 18:10 -resetDemo` on iPhone 17: SH1 to SH6, SH8, SH9, SH13, SH15, SH18, SH22, then SH29 to SH36 with Reduce Motion, VoiceOver and the largest text size turned on in turn.
4. Mark each row pass or fail with one line of evidence. Any fail in SH16 to SH23 blocks the merge.

**38 rows (SH1 to SH38).**

## Where master or the fixtures already disagree

- **Reduce Motion length.** `MotionPolicy.reducedMotionFade` is 0.15 s (`DesignSystem/MotionPolicy.swift:6`); sheet 75 asks for a 200 ms crossfade per stop (every-side.md:97). SH29 fails unless the PR sets 200 ms for the side or Design accepts 150 ms.
- **The generic front prints private fields.** `PropertyList` prints every field but `notes` (`Features/Objects/ObjectPage.swift:342-348`, used at :237 and :89), so a private memory's `rule` shows on the front. Ruled at 2:45 as Core 0ai's rider, not 0ak; SH18 checks the side holds on its own.
- **SL-H2 is stale.** The fixture keeps a "Weigh in" habit's band empty; 2:44 (4) says count only. SH27 follows 2:44.
- **GL-22 and Q7 are stale.** The fixture reads "most used" as the field most often set across the class; 2:44 (7) says edited most in the last 30 days. SH14 follows 2:44.
- **PL4 is closed on master** (`Notes/Notes.swift:42-46`, 5c22981). SH20 checks it stays.
