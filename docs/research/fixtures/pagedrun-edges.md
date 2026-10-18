# PagedRun edge cases: sizes, caps, private rows, Dynamic Type, Low Power

For: Core (the pure page build), Builder B (`PagedRun`, Settings), QA. Docs only; nothing was built or run. Written Sat Oct 17 (PDT) against origin/master `b2048d91`. **`PagedRun` is not on master.** `git grep -il "pagedrun\|PageBuild" -- '*.swift'` returns nothing, and neither does `PageTurn` or `Theme.Motion.pageTurn`. So this list is worked from the spec: `design/pages-90.md` (rules 1 to 8, "Calls settled Oct 17"), `design/settings-93.md`, and the merged fixtures `docs/research/fixtures/page-turn.md` (PG, RL, TM, ST) and `docs/research/fixtures/sheets-93-94-95.md` (SP). Ids here are **PR** so they do not collide with PG, RL, TN, TM, ST, WS, SP or LV. A row that only repeats an earlier fixture says "per PG04" and adds the edge.

Status: **traced** means a master line does what the row says (file:line cited); **inferred** follows from the spec or from a neighbouring master line without a test; **gap** means master has nothing for it, or the spec leaves it undecided. Owners: Core, Builder B. Test names are Swift Testing names unless marked UI.

## The rule these rows test

Rule 1 and 2 of sheet 90 give one page-size function for a group of n rows: pages = ceil(n / 6), sizes differ by at most one, larger pages first. Worked: 7 is 4+3, 10 is 5+5, 11 is 6+5, 13 is 5+4+4, 19 is 5+5+5+4, 23 is 6+6+6+5, 24 is 6+6+6+6, 25 is 5+5+5+5+5. Only 7, 10 and 13 are written in the sheet; the others are the same rule applied, and the tie order ("larger first") is stated for odd splits only (pages-90 "Calls settled", Odd splits).

**Our reading, not the sheet's.** "Fewest pages, sizes differ by at most one, larger first" is Research's reading of sheet 90's "nearest even break". For 19, 23 and 25 the sheet is silent. Design must confirm 19 = 5+5+5+4, 23 = 6+6+6+5 and 25 = 5x5 before PR07 to PR10 become tests. Until then those four rows are provisional.

**Not for Core's first PR.** Rows marked "after ruling" (PR14, PR15, PR21, PR27, PR28, PR39, PR40, PR49) wait on Product or Design (Open 1 to 5). Keep them out of Core's first PR. Rows PR07 to PR10 also wait on the confirmation above.

## Rows

Columns: Id, Items in, Expected page sizes, Status, Owner, Test. "Master" is where code or the missing code is.

### A. Counts at the edges (one group unless stated)

| Id | Items in | Expected page sizes | Status | Owner | Test |
|---|---|---|---|---|---|
| PR01 | 0 | no page, no rail, no peek; nothing drawn (per PG03) | gap: no page build; `ListsView.swift:168` is a plain `ScrollView` | Core | `zeroItemsDrawNoPage` |
| PR02 | 1 | [1]; one page, no rail, no peek (rule 5) | gap | Core | `oneItemIsOnePageNoRail` |
| PR03 | 6 | [6]; the fit is exact, never split (per PG01, PG06) | gap | Core | `sixItemsIsOnePage` |
| PR04 | 7 | [4, 3]; the second page keeps the word; rail appears (per PG02, PG14) | gap | Core | `sevenItemsSplitFourThree` |
| PR05 | 11 | [6, 5]; fewest pages (2), sizes differ by one, larger first | inferred from rules 1 and 2; not written in the sheet | Core | `elevenItemsSplitSixFive` |
| PR06 | 13 | [5, 4, 4] (per PG05, PG11) | gap | Core | `thirteenItemsSplitFiveFourFour` |
| PR07 | 19 | [5, 5, 5, 4]; four pages, none above 6 | inferred; Design to confirm before this is a test | Core | `nineteenSplitsFiveFiveFiveFour` |
| PR08 | 23 | [6, 6, 6, 5]; four pages, three full | inferred; Design to confirm before this is a test | Core | `twentyThreeSplitsSixSixSixFive` |
| PR09 | 24 | [6, 6, 6, 6]; four full pages, no split loses a row (the Groceries example is 24 rows over several aisles, pages-90 table) | inferred | Core | `twentyFourItemsFourFullPages` |
| PR10 | 25 | [5, 5, 5, 5, 5]; ceil(25/6) is 5, so the fewest-pages rule gives five pages of five, not 6+6+6+6+1 | inferred; the sheet never tests 25; Design to confirm before this is a test | Core | `twentyFiveItemsFiveEvenPages` |
| PR11 | any n from 0 to 60 | sum of sizes equals n; max size 6; max minus min is at most 1 inside a group; sizes non-increasing | gap | Core | `everySizeKeepsSumCapAndOrder` |
| PR12 | same input twice (13, then 13) | identical output (per PG15) | gap | Core | `pageBuildIsDeterministic` |

### B. Odd splits across several groups

| Id | Items in | Expected page sizes | Status | Owner | Test |
|---|---|---|---|---|---|
| PR13 | THIS WEEK 7, EARLIER 13 (Notes, 20) | [4, 3, 5, 4, 4], five pages; 3 + 5 = 8 so no merge (per PG05) | gap | Core | `notesTwentySplitsEvenly` |
| PR14 | A 7, B 2 | [4, 3] with the 3 possibly sharing with B (3 plus 2 is 5 rows), two groups, so the tail of A may share with B. The sheet merges "small neighbouring groups", not a tail of a split group | gap, undecided; after ruling, not for Core's first PR (see Open 3) | Core, Design | `splitTailMayShareWithNeighbour` (after ruling) |
| PR15 | A 11, B 1 | [6, 5, 1] or [6, 5+1 merged]; same open question as PR14 | gap, undecided; after ruling, not for Core's first PR | Core, Design | same as PR14 |
| PR16 | A 6, B 7 | [6, 4, 3]; a full page never absorbs a neighbour (per PG10) | gap | Core | `fullPageDoesNotMerge` |
| PR17 | A 3, B 3, C 3, D 3 | [3+3, 3+3] if merged; four pages if each stays named. Settings uses this exact shape | gap, contradiction (SP03) | Core, Design | `namedPagesAreNotMerged` |
| PR18 | the lead is inside a 19-group | the lead sits on the page that holds it and counts in that page's 6; the 5+5+5+4 sizes do not move to favour it (per PG12) | gap | Core | `leadDoesNotChangePageSizes` |

### C. Settings: four pages of six or fewer (sheet 93)

Sheet 93 as written: Tess (3 rows), Your day (3), Looks (3), Data (3). The four pages are authored named groups; the first row of the table below is the sheet, the others are its limits.

| Id | Items in | Expected page sizes | Status | Owner | Test |
|---|---|---|---|---|---|
| PR19 | Settings as sheet 93 | [3, 3, 3, 3]; four pages, words Tess, Your day, Looks, Data (per SP01, SP02). Master has no `SettingsView`; Settings is a stack of sentences at the foot of Review | gap: `Features/Review/ReviewView.swift:219-240`, `TesseraCore/Sources/TesseraCore/Settings/TesseraSettings.swift:5-38` | Builder B | `settingsHasFourPagesInOrder` |
| PR20 | Settings with six rows on every page | [6, 6, 6, 6]; the largest legal Settings, 24 rows, four pages, none above 6 | gap | Builder B | `settingsMaxFourSixRowPages` |
| PR21 | Settings, one page grows to 7 (an open row adds a row) | the page does not split into 4+3 and make a fifth page; an in-place expansion is not a row (SP41, SP50) | gap, undecided; after ruling, not for Core's first PR (see Open 2) | Design | n/a |
| PR22 | Settings, page 1 has 3 rows and page 2 has 3 | stay two pages; the page build is not run on authored pages, or runs with a never-merge flag (SP03) | gap | Core | `settingsGroupsAreNotMergedByPageBuild` |
| PR23 | Settings, the Page turn row = Rotate | no row slots declared, so Rotate falls back to Turn; no error line (per ST05, SP43) | gap | Builder B | `rotateOnSettingsFallsBackToTurn` |
| PR24 | Settings, last page, swipe up; first page, swipe down | no rubber-band, nothing moves (per RL09, RL10, SP64) | gap | Builder B | `settingsEdgePagesDoNotRubberBand` |
| PR25 | Settings, any page | rail has four segments; no "1 of 4" text (RL02, RL05, SP42, SP61) | gap | Builder B | `settingsRailHasFourSegments` |

### D. The four-page cap and overflow

Sheet 93 says "one scroll of 5 pages at most under sheet 90's rules; here 4 pages of 6 or fewer". Sheet 90 states no cap for any run. The cap applies to Settings only, as far as the spec reads, and it is stated as 5, not 4.

| Id | Items in | Expected page sizes | Status | Owner | Test |
|---|---|---|---|---|---|
| PR26 | Settings at 24 rows | exactly four full pages; at Settings' 4-page limit, no overflow (not a general cap) | inferred | Core | `settingsAt24RowsFillsFourPages` |
| PR27 | Settings at 25 rows | overflow past Settings' 4 pages (not a general cap). Candidate A: a fifth page of 1 (6+6+6+6+1, breaks "fewest pages equal"). Candidate B: five pages of 5 (the plain rule, PR10). Candidate C: the cap holds and the last page takes 7 (breaks rule 1). Rule 1 forbids C | gap, undecided; after ruling, not for Core's first PR (see Open 1) | Core, Design | `overflowPastCapKeepsRuleOne` (after ruling) |
| PR28 | Settings gets a 5th group | five pages is within "5 pages at most" in sheet 93 but outside "4 pages"; which one is the cap | gap, undecided; after ruling, not for Core's first PR (see Open 1) | Design | n/a |
| PR29 | cap overflow while the reader is on page 4 | the reader stays on page 4; pages 4 and 5 re-split and the rail gains a segment without a turn | gap | Builder B | `capOverflowKeepsReadersPage` |
| PR30 | overflow items are private | counted by the same rule; no private item is dropped silently | gap | Core | `overflowNeverDropsPrivateItems` |

### E. Private items count toward the six

A private row is a row. It takes one of the six slots, shows its label ("Private note", "Private item", "Private recipe" masks), and never moves a page boundary because of its text length or its mask.

| Id | Items in | Expected page sizes | Status | Owner | Test |
|---|---|---|---|---|---|
| PR31 | 6 items, 2 private | [6]; private rows count 1 each, one page | gap | Core | `privateRowsCountTowardSix` |
| PR32 | 7 items, 3 private | [4, 3], same sizes as 7 plain items; the mask does not change the split (per PG13) | gap | Core | `privateItemsDoNotChangeSplit` |
| PR33 | 12 items, all private | [6, 6]; every row reads "Private ..." and nothing else; page container label is the group word, never a private title | gap | Core | `allPrivateStillTwoPages` |
| PR34 | a private row is the lead | counted in that page's 6; drawn with its mask | inferred (PG12, PG13) | Core | `privateLeadCountsInItsPage` |
| PR35 | a private note | the row text is the label "Private note"; master already does this outside its own page | traced: `Features/Notes/NotesView.swift:289`, `Features/Objects/ObjectPage.swift:51`, `TesseraCore/Sources/TesseraCore/Catalog/SystemCatalog.swift:218`, `TesseraCore/Sources/TesseraCore/Export/PrivateWords.swift:5` | Builder B | `privateRowKeepsLabelInPaging` |
| PR36 | a private item hidden from VoiceOver | the page container reads "Produce, page 1 of 2"; the private row reads its label only | gap | Builder B | `privatePageReadsLabelsOnly` (UI) |
| PR37 | a note is made private while its page shows | it keeps its slot and page; only its text changes to the label (the mask is a text change, not a count change) | inferred | Core | `togglingPrivateDoesNotRepage` |

### F. Dynamic Type

Rule 1 counts rows, not height. Master has no paging, so every row here is a gap. The spec's only Dynamic Type statement for a paged screen is SP30 (Settings at accessibility sizes: the value drops under the name, the page scrolls inside its 3 rows).

| Id | Items in | Expected page sizes | Status | Owner | Test |
|---|---|---|---|---|---|
| PR38 | 7 items at the default size | [4, 3] | gap | Core | per PR04 |
| PR39 | 7 items at AX5 (largest accessibility size) | [4, 3] unchanged; the page build never reads the type size; page content scrolls inside its page if 4 rows do not fit | gap, undecided; after ruling, not for Core's first PR (see Open 4) | Core, Design | `pageSizesIgnoreDynamicType` |
| PR40 | 6 items at AX5 | [6]; one page, still no rail, even if the six rows do not fit the screen; the page scrolls | gap, undecided; after ruling, not for Core's first PR (see Open 4) | Builder B | `sixItemsAtAX5StayOnePage` (UI) |
| PR41 | Settings at AX3 | four pages of 3; the value stacks under the name; no truncation (SP30) | gap | Builder B | `settingsRowStacksValueAtAccessibilitySizes` (UI) |
| PR42 | rail and peek at AX5 | rail stays 2 pt (3 pt current) on the right edge; the peek word at 30% ink over a 14 pt hairline is not scaled into the page; hidden from VoiceOver | gap | Builder B | `railAndPeekIgnoreTypeSize` (UI) |
| PR43 | the foot tap target at AX5 | the foot stays a turn target of at least 44 pt tall | gap | Builder B | `footTapTargetStaysFortyFour` (UI) |
| PR44 | Dynamic Type changes while a page is showing | the reader stays on the same page; sizes do not recompute | inferred from PR39 | Builder B | `typeSizeChangeKeepsPage` (UI) |

### G. Low Power Mode = Reduce Motion

R3 (pages-90, "Calls settled Oct 17"): Low Power Mode behaves like Reduce Motion for the page turn, one 150 ms crossfade, whatever the Settings word; the choice is kept. Master reads Reduce Motion in many places and Low Power in exactly one (Tess's soul); `MotionPolicy.resolve` takes only `reduceMotion`.

| Id | Items in | Expected page sizes | Status | Owner | Test |
|---|---|---|---|---|---|
| PR45 | Low Power on, any page turn, Turn chosen | one 150 ms crossfade, same as Reduce Motion (per TM06) | gap: `DesignSystem/MotionPolicy.swift:8` resolves `reduceMotion` only; Low Power is read only for Tess at `Features/Tess/TessSoul.swift:109` (`ProcessInfo.processInfo.isLowPowerModeEnabled`) | Builder B | `lowPowerIsReduceMotion` |
| PR46 | Low Power on, Slide, Soften, Rotate each | all three also become the 150 ms crossfade | gap | Builder B | `lowPowerCrossfadesEveryOption` |
| PR47 | Low Power on, Settings row | still reads the user's word ("Soften, on"); the choice is not rewritten | gap | Builder B | `lowPowerKeepsSettingsChoice` |
| PR48 | Low Power on, picking a word in Settings | the preview is the 150 ms crossfade (per ST06) | gap | Builder B | `lowPowerPreviewIsCrossfade` |
| PR49 | Low Power turns on while a turn is playing | the turn in flight finishes; the next turn uses the crossfade (per TM08 for interruption) | gap, undecided; after ruling, not for Core's first PR (see Open 5) | Builder B | `lowPowerMidTurnThenFades` |
| PR50 | Low Power turns off while a crossfade is playing | the crossfade finishes; the next turn uses the chosen word | inferred | Builder B | `lowPowerOffRestoresChosenTurn` |
| PR51 | Low Power on, Reduce Motion off | crossfade; the page sizes are untouched, only the turn changes | gap | Core | `lowPowerNeverChangesPageSizes` |
| PR52 | Low Power on, a lead change turns the page by itself | the automatic turn is the 150 ms crossfade, once (per TN07), no haptic (TN09) | gap | Builder B | `lowPowerLeadTurnFadesOnce` |
| PR53 | Low Power on, Rotate chosen, a screen with no slots | falls back to Turn, then to crossfade; no error line | gap | Builder B | `lowPowerRotateFallbackFades` |
| PR54 | Low Power and Reduce Motion both on | one 150 ms crossfade, not two; no double speed-up | gap | Builder B | `lowPowerPlusReduceIsOneFade` |

## Count

54 rows: PR01 to PR54. Status: traced 1 (PR35), inferred 10, gap 43 (undecided ones are marked in the table and listed below).

## Open: what the spec leaves undecided

1. **The cap.** The user's brief says "4-page cap". Sheet 93 says "5 pages at most ... here 4 pages of 6 or fewer"; sheet 90 has no cap. What happens at 25 items (PR10, PR27) and with a fifth Settings group (PR28) is not written. The plain rule gives five pages of five. Needs Design.
2. **A page that grows by expansion** (Settings Look five names, clocks, four turn words; PR21, SP50). Is an open row a row for the six? The spec says rows, but says nothing about open rows.
3. **Tail merge.** May the 3 of a 4+3 split share a page with a small neighbour (PR14, PR15)? Sheet 90 merges "small neighbouring groups", which are groups, not split tails. A tail that merges would put two words on a page that sheet 90's own Notes board shows ("THIS WEEK 2 with EARLIER 3").
4. **Dynamic Type and the six.** Rule 1 counts rows; at accessibility sizes six rows may not fit one screen. No rule says the count shrinks (4 a page at AX5) or that the page scrolls inside. SP30 says Settings scrolls inside its 3 rows; the general run is silent (PR39, PR40).
5. **Low Power changing mid-turn** (PR49) and whether Low Power is read once per turn or once per launch (Tess's soul reads it at the start of a mode, `TessSoul.swift:65`).
6. **The Notes board disagrees with the rule.** Sheet 90's table for Notes, 20 reads "THIS WEEK 5, THIS WEEK 2 with EARLIER 3, EARLIER 5, EARLIER 5". The rule (R1, odd splits) gives THIS WEEK 4+3 and EARLIER 5+4+4 (PR13). The board predates the odd-split call; Design to redraw.
