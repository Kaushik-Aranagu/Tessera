# 90. Pages: six rows a page, turned by a vertical swipe

**Kaushik on sheet 89 (Oct 17, 12:29 PM PT):** still too much information. Fewer items per page, and instead of one continuous scroll, "multiple page scrolling effect, it just transitions from one page to another." He asked Design to think of better ways to put the information together. This replaces sheet 89's lead-row card; the lead row, the one column and the section budget from 89 still apply inside a page.

Board `mockups/pages-90.png`, recording `recordings/pages-90.mp4` (24 s: Groceries, Notes and Set history each paging on their own beat; below, the three turns side by side), study `studies/pages-90.html` (`?play` records; click a phone's lower half, scroll or use the arrow keys to turn a page; `?reduce` shows Reduce Motion). Nothing in the app changes yet.

## The rules
1. **A page holds six rows or fewer** (the lead counts). Past six the list continues on the next page.
2. **A page follows the data's groups.** One group is one page and its name is the page's one word (aisle, week, workout date). A group of more than six splits at the nearest even break (10 = 5+5, never 6+4); odd splits put the larger pages first (7 = 4+3, 13 = 5+4+4); the later pages keep the word. Small neighbouring groups may share a page, at most two groups, so two section words, one hairline (sheet 89's budget).
3. **Turn with a vertical swipe or a tap on the foot.** Sideways stays the screen's side page (sheet 75), so paging and the side swipe never compete. A page never rubber-bands past its first or last.
4. **One page is drawn at a time.** At the foot a hair of the next page's word at 30% ink over a 14 pt hairline says there is more; no scroll bar, no "1 of 5" text, no dots.
5. **The rail:** a 2 pt vertical rule on the right edge, one segment per page, the current one in the area colour at 3 pt. It is the only page indicator. A list of one page draws no rail and no peek.
6. **Pinned things stay pinned.** The writing line on Notes, the add field on a list and Tess's line do not turn with the page; writing is never a page away.
7. **The lead row** is drawn on the page that holds it; when the lead changes page (a shop item checked) the page turns by itself to the new lead with the same turn, once, and the one soft haptic in the map (.selection) plays on landing.
8. **Copy:** nothing added. The context line still says the count ("24 to get"); the page is its own proof.

## The turn: four options, a Settings choice (Kaushik, 12:46 PM: he likes A, B and C as options, and added D)
- **A Slide:** the whole page slides up 520 ms. Familiar, and it moves the whole screen.
- **B Turn (recommended):** rows of the old page lift 18 pt and fade top to bottom (260 ms, 24 ms stagger), rows of the new page rise 34 pt into place in the same order (440 ms, 38 ms stagger, starting at 190 ms). The section word crossfades with its rows. The eye stays on the rows. Total 0.6 s. Going back runs bottom to top.
- **C Soften:** 340 ms blur-out and 400 ms blur-in, overlapped. Calm, but nothing says which way you went.
- **D Rotate (his idea):** the list defines N row slots up front; a swipe up rotates the rows through those slots (top rows leave first, the next page's rows arrive from the foot with the same ripple, 480 ms, 34 ms stagger) while the title, context, section word and rail never move, so it feels like turning a page and stays one page. A slow drag follows the finger.
- **Default is B Turn.** All four are a Settings choice (below).
- **Reduce Motion:** every option becomes one 150 ms crossfade.
- Motion goes through `MotionPolicy` as a new `Theme.Motion.pageTurn` (curve .22, .8, .2, 1), never a literal.

## How the three screens read paged
| Screen | Pages | Pinned | Notes |
|---|---|---|---|
| Groceries, 24 | PRODUCE 5, PRODUCE 5, DAIRY 5, PANTRY 6, FROZEN 3 | add field | the lead is Bananas; amounts stay in the side FOR WHAT |
| Notes, 20 | THIS WEEK 5, THIS WEEK 2 with EARLIER 3, EARLIER 5, EARLIER 5 | the writing line | a private note reads "Private note" |
| Set history, 12 | THU OCT 16 (6, best set leads), MON OCT 13 (6) | none | Obsidian shown |

## For builders (not built; Product boards it)
`PagedRun(groups:, pinned:)` replaces `RunList` for any run of 7 or more rows; a run of 6 or fewer is one page and draws no rail. Page build is a pure function of the groups (testable, no UI): split groups over six, merge small neighbours up to two groups, return pages. `PageTurn` is the one transition, with the A, B or C option behind `ThemeConcept`. VoiceOver: each page is one container, "Produce, page 1 of 2", and the rotor's scroll action turns the page; the peek word is hidden from VoiceOver.

## Settings: Page turn
One row in Settings, four words (Slide, Turn, Soften, Rotate); the chosen one in ink with "on" after it ("Turn, on"), the rest in secondary ink, like Reusable. Picking one plays that turn once on a preview line ("Groceries, 24 to get.") so he can feel it. Default Turn.

## Whose swipe it is (Kaushik, 12:46 PM)
A vertical swipe on a thing that owns one does that thing's own action, defined by what the thing is: a number that steps (weight, reps, a quantity) adds or takes one step; a dial or slider moves its own value. A swipe on anything else (plain text, a section word, the empty page) turns the page. A row that opens or removes keeps its horizontal swipe (sheets 75 and 86), so vertical turns the page there. A focused field never turns the page. Builders: a screen declares its page slots (N rows) and, per element, an optional vertical action; the page-turn recogniser only starts if no such action claims the touch. Nothing declares a vertical swipe by default.

## Open question
None blocking: all four turns ship. Say if Turn should not be the default.

## Calls settled Oct 17 (Research #879 fixtures)
- **R1** The written rule wins: the nearest even break; boards redrawn (PRODUCE is 5+5).
- **R2** A user page turn plays no haptic. Turning is navigation, not a moment; Rotate included.
- **R3** Low Power Mode behaves like Reduce Motion for the page turn (the 150 ms crossfade).
- **R4** Re-picking the word already chosen in Settings does not replay the preview.
- **Odd splits** put the larger pages first (7 = 4+3, 13 = 5+4+4).
