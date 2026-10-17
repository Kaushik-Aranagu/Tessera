# Page turn fixtures (sheets 90 and 91, decisions 12:46 PM Oct 17)

For: Builder A and Builder B (screens), Core (the pure page build), Design (two rulings below), QA. Docs only; nothing run. Written Sat Oct 17 from `design/pages-90.md` (rules 1 to 8, "The turn", "Settings: Page turn", "Whose swipe it is") and `product/decisions.md` 12:46 PM Oct 17. Master has no `PagedRun`, `PageTurn` or `Theme.Motion.pageTurn` yet (checked by grep on master), so every row below is **spec**, not traced code. Boards are on hold until Product boards them.

Vocabulary: a **group** is one named set of rows (an aisle, a week, a workout date); a **page** holds 6 rows or fewer; the **lead** is the row the screen is about; **own action** is a vertical swipe a thing owns (a number that steps, a dial).

## 1. The page build, a pure function of groups (Core, testable with no UI)

Input: groups in order, each with a word and a row count. Output: pages, each with its word or words and its rows. Test names are Swift Testing names to paste.

| Id | Groups in | Pages out | Why | Test name |
|---|---|---|---|---|
| PG01 | one group of 6 | 1 page, no rail, no peek | 6 or fewer is one page (rule 1) | `sixRowsIsOnePage` |
| PG02 | one group of 7 | 2 pages, the second keeps the word | past 6 it continues (rules 1, 2) | `sevenRowsSplitInTwo` |
| PG03 | one group of 0 | no page | an empty group draws nothing | `emptyGroupDrawsNoPage` |
| PG04 | PRODUCE 10 | PRODUCE 5, PRODUCE 5 | rule 2 "nearest even break" stands (R1 ruled); the board's 6+4 is redrawn by Design | `produceTenSplitsFiveFive` |
| PG05 | THIS WEEK 7, EARLIER 13 | THIS WEEK 4, THIS WEEK 3, EARLIER 5, EARLIER 4, EARLIER 4 (5 pages, 20 notes) | even split: 7 as 4+3, 13 as 5+4+4; none of the pages can merge (3+5 is over 6 only if two groups share, and 3+5 is 8) | `notesTwentySplitsEvenly` |
| PG06 | Set history: THU OCT 16 6, MON OCT 13 6 | 2 pages of 6 | exact fits never split (the board) | `twoFullGroupsTwoPages` |
| PG07 | A 2, B 3 | 1 page, two words, one hairline | small neighbours share, at most two groups (rule 2) | `smallNeighboursShareAPage` |
| PG08 | A 2, B 2, C 2 | A+B on page 1, C on page 2 | never three groups on a page | `neverThreeGroupsOnAPage` |
| PG09 | A 4, B 4 | 2 pages | merging must not exceed 6 rows | `mergeNeverPassesSixRows` |
| PG10 | A 6, B 1 | 2 pages | a full page does not absorb a neighbour | `fullPageDoesNotMerge` |
| PG11 | one group of 13 | 3 pages, none above 6 | the cap holds for any size | `thirteenRowsThreePagesAtMostSix` |
| PG12 | the lead row is in a group of 9 | the lead is on the page that holds it, counted in that page's 6 | rule 1 "the lead counts" | `leadCountsInItsPage` |
| PG13 | rows with a private title (Notes) | the page holds the row; its title reads "Private note", never its words | walls; sheet 90 Notes table | `privateRowKeepsLabelInPaging` |
| PG14 | a run of 6 rows, then one is added | becomes 2 pages without losing the reader's place | the rail appears at 7 | `addingSeventhRowAddsRail` |
| PG15 | page build run twice on the same input | identical output | pure function | `pageBuildIsDeterministic` |

**R1 (ruled, decisions 3:55 PM):** the written rule stands: a group over 6 splits into the fewest pages and the sizes differ by at most one, larger pages first (PRODUCE 10 is 5+5; 7 is 4+3; 13 is 5+4+4). Design redraws the 6+4 boards. The "larger first" tie order is my reading of the examples; confirm with Design for odd splits.

## 2. Rail, peek and pinned things

| Id | Case | Expected | Test name |
|---|---|---|---|
| RL01 | one page | no rail, no peek | `singlePageDrawsNoRailOrPeek` |
| RL02 | 5 pages, on page 2 | five segments, the 2nd at 3 pt in the area colour, the others 2 pt | `railMarksCurrentPage` |
| RL03 | on the last page | no peek of a next page's word | `lastPageHasNoPeek` |
| RL04 | on a page that has a next | next page's word at 30% ink over a 14 pt hairline | `peekShowsNextWordAtThirtyPercent` |
| RL05 | any page | no "1 of 5" text, no dots, no scroll bar | `noPageCounterText` |
| RL06 | Notes, the writing line | does not turn with the page | `notesWritingLineStaysPinned` |
| RL07 | Groceries, the add field | stays pinned on every page | `addFieldStaysPinned` |
| RL08 | any screen, Tess's line | stays pinned and never diffuses or fades (decisions 12:46 PM) | `tessLineNeverDiffused` |
| RL09 | first page, swipe down | does not rubber-band; nothing moves | `noRubberBandAtFirstPage` |
| RL10 | last page, swipe up | does not rubber-band; nothing moves | `noRubberBandAtLastPage` |

## 3. Turning: gestures and the lead

| Id | Case | Expected | Test name |
|---|---|---|---|
| TN01 | vertical swipe up on plain text | next page | `swipeUpOnTextTurnsPage` |
| TN02 | vertical swipe down on plain text | previous page | `swipeDownOnTextTurnsBack` |
| TN03 | tap on the foot | next page | `tapFootTurnsPage` |
| TN04 | sideways swipe | the screen's side page (sheet 75), never a page turn | `sidewaysSwipeIsNeverAPageTurn` |
| TN05 | a row with a horizontal swipe (open or remove), swiped vertically | the page turns (sheets 75, 86) | `rowWithHorizontalSwipeStillTurnsVertically` |
| TN06 | a focused text field, vertical swipe | does not turn the page | `focusedFieldNeverTurnsPage` |
| TN07 | the lead changes page (a shop item is checked) | the page turns by itself to the new lead, once, with the chosen turn | `leadChangeTurnsOnce` |
| TN08 | the lead changes page twice quickly | at most one turn per change, no stacking; ends on the lead's page | `quickLeadChangesDoNotStack` |
| TN09 | the lead lands | exactly one `.selection` cue, no other haptic; checking the item keeps its own finish haptic, so the counts per moment are written in `haptic-moments.md` | `leadLandingFiresOneSelection` |
| TN10 | a user turn (swipe or tap), Rotate included | no haptic (R2 ruled); only the automatic lead turn (TN09) plays `.selection` | `userTurnPlaysNoHaptic` |
| TN11 | a slow drag in Rotate | rows follow the finger; lifting early settles back or forward by the same rule as a swipe | `rotateDragFollowsFinger` |
| TN12 | VoiceOver on | each page is one container read "Produce, page 1 of 2"; the rotor scroll action turns the page; the peek word is hidden | `pageContainerLabelsReadPageNumbers` |

**R2 (ruled, decisions 3:55 PM):** no haptic on a user page turn, Rotate included.

## 4. The four turns and Reduce Motion

| Id | Option | Spec to test (all through `Theme.Motion.pageTurn`, curve .22 .8 .2 1; never a literal) | Test name |
|---|---|---|---|
| TM01 | Slide | the whole page moves up in 520 ms | `slideTurnTakesFiveTwentyMs` |
| TM02 | Turn (default) | old rows lift 18 pt and fade top to bottom (260 ms, 24 ms stagger); new rows rise 34 pt (440 ms, 38 ms stagger, start at 190 ms); total 0.6 s; going back runs bottom to top | `turnOptionTimingAndOrder` |
| TM03 | Soften | 340 ms blur-out, 400 ms blur-in, overlapped | `softenTurnTiming` |
| TM04 | Rotate | rows rotate through N slots; top rows leave first, next rows arrive from the foot (480 ms, 34 ms stagger); title, context, section word and rail never move | `rotateKeepsChromeStill` |
| TM05 | Reduce Motion, any option | one 150 ms crossfade | `reduceMotionIsOneCrossfade` |
| TM06 | Low Power Mode | behaves as Reduce Motion: one 150 ms crossfade, whatever option is picked (R3 ruled); the Settings choice is kept | `lowPowerIsReduceMotion` |
| TM07 | Soften and the Tess line | Tess is never blurred even when the rows are; this conflicts with a full-screen blur if built carelessly | `softenNeverBlursTess` |
| TM08 | a turn interrupted by another turn | the second starts from the current state; no jump | `interruptedTurnContinues` |

**R3 (ruled, decisions 3:55 PM):** Low Power Mode = Reduce Motion.

## 5. The Settings row "Page turn"

| Id | Case | Expected | Test name |
|---|---|---|---|
| ST01 | fresh install | Turn is chosen; the row reads "Turn, on" with the other three in secondary ink | `defaultPageTurnIsTurn` |
| ST02 | pick Soften | the row reads "Soften, on"; the preview line "Groceries, 24 to get." plays the Soften turn once | `pickingPlaysPreviewOnce` |
| ST03 | pick the same word again | the preview does not replay (R4 ruled) | `repickDoesNotReplayPreview` |
| ST04 | the choice | stored as a setting; survives restart; included in backups; not in the op log as user text | `pageTurnSettingPersists` |
| ST05 | pick Rotate on a screen with no row slots | falls back to Turn on that screen, no error line | `rotateWithoutSlotsFallsBackToTurn` |
| ST06 | Reduce Motion on, pick any word | the choice is kept; the preview is the 150 ms crossfade | `reduceMotionPreviewIsCrossfade` |
| ST07 | the row's words | US English, capitalized once, no quotes, no em-dash | `pageTurnRowCopy` |
| ST08 | migration | no catalog change; additive setting only | `pageTurnIsAdditiveSetting` |

**R4 (ruled, decisions 3:55 PM):** re-picking the same word does not replay the preview.

## 6. Whose swipe it is (decisions 12:46 PM)

Rule: a vertical swipe on a thing that owns one does that thing's action; anywhere else it turns the page. Nothing declares a vertical swipe by default; a screen declares page slots and, per element, an optional vertical action; the page-turn recogniser starts only if no such action claims the touch.

| Id | Where | Swipe up on it | Swipe up on its neighbour | Test name |
|---|---|---|---|---|
| WS01 | a set's weight number on the live workout | adds one step | turns the page (if paged) | `weightNumberOwnsVerticalSwipe` |
| WS02 | a set's reps number | adds one rep | turns the page | `repsNumberOwnsVerticalSwipe` |
| WS03 | a grocery quantity | adds or takes one step | turns the page | `quantityOwnsVerticalSwipe` |
| WS04 | a dial or slider (Settings) | moves its own value | turns the page | `dialOwnsVerticalSwipe` |
| WS05 | a section word | turns the page | n/a | `sectionWordTurnsPage` |
| WS06 | the empty page area | turns the page | n/a | `emptyAreaTurnsPage` |
| WS07 | a row that opens or removes | turns the page (its swipe is horizontal) | n/a | `openRowTurnsPage` |
| WS08 | a number whose screen is a single page | steps; no page exists to turn | n/a | `ownActionOnSinglePage` |
| WS09 | a drag that starts on a number and drifts onto plain text | stays the number's action for the whole touch | n/a | `touchOwnerDoesNotChangeMidDrag` |
| WS10 | down vs up on a stepping number | up adds, down takes one step; the floor is respected (no negative weight or reps) | n/a | `steppingNumberFloor` |
| WS11 | a stepping number at 60 pt from the screen edge | the edge zones in `depth-76.md` (24 pt out, 32 pt in) still belong to the side swipe | n/a | `edgeZonesWinOverNumbers` |
| WS12 | a stepping number on a private row | the same action; the label stays "Private ..." | n/a | `privateRowKeepsStepping` |
| WS13 | any element with no declaration | never claims a vertical touch | n/a | `undeclaredElementsNeverClaimTouch` |
| WS14 | two nested owners (a number inside a dial) | the innermost owner claims | n/a | `innermostOwnerClaims` |

## 7. Pockets (sheet 91 r2), the part that touches paging

| Id | Case | Expected | Test name |
|---|---|---|---|
| PK01 | the page turns | the old pocket dissolves over 260 ms, the new one dries in over 380 ms; it does not move with the rows | `pocketDissolvesAndDries` |
| PK02 | Reduce Motion | the pocket swaps with the same 150 ms crossfade | `pocketFollowsReduceMotion` |
| PK03 | Groceries | no pocket at all (decisions 12:46 PM) | `groceriesHasNoPocket` |
| PK04 | any pocket | crisp drawing or his own photo, never blurred | `pocketIsNeverBlurred` |
| PK05 | Soften option with a pocket | rows blur, the pocket does not | `softenDoesNotBlurPocket` |

## 8. Gaps and owners

- **Nothing is built.** Core: `PageBuild` (pure, section 1) and its tests. Builder B: `PagedRun` for Groceries, Notes, Lists. Builder A: Set history. Motion lab: the page-turn motion spec is on its board (item 26); the builders read it when it lands.
- **Design rulings:** R1 to R4 are ruled (decisions 3:55 PM) and applied above. Open: the tie order for odd splits.
- **Not ruled and not in the sheet:** what a page does when a row is removed or added while it is showing (PG14 covers add; remove is open), and the "Rotate" slot count per screen (the sheet says the list defines N).
- **Checks that need the simulator later:** TM02 timing, TN11 drag feel, WS09 mid-drag ownership, VoiceOver rotor (TN12).
