# PeekTabs motion: the tab change, the blurred neighbours, Reduce Motion

Lab spec with Normal / Reduce Motion (RM) / Low Power (LP) columns. Docs only; Builder A and Builder B build from the rows. LP = RM everywhere (150 ms crossfade) unless a row says otherwise. Source sheet: Design item 108 (`design/set-marks-tabs-108.md` section 4; in the project files folder, mirror only). As built: `Features/Common/PeekTabs.swift` in #1137 (head 3bc201a5, not merged when this was written; cites are `PT:line` of that file's added lines, so re-check after it lands). Lab defaults are marked.

## What the build does today (PT)
- The words sit at fixed slots (`PeekTabsLayout.offset`, 0.27 of the width per step, two each side) and move only when `selection` changes, on the house spring (`Theme.Motion.house`, 0.42 s, bounce 0.12) through `.tesseraAnimation(value: selection)`.
- The page is a paging `ScrollView`; each page fades to 0.25 opacity while it leaves (`scrollTransition(.interactive)`). The words do not follow the finger.
- One `.selection` haptic on a change of `selection` (`tesseraFeedback(.selection, trigger: selection)`).
- Blur is a fixed 1.6 pt on neighbours unless Reduce Transparency or the "Tab neighbours: Crisp" switch.

## 1. The tab change (what moves)

| Moment | Normal | Reduce Motion | Low Power |
|---|---|---|---|
| Finger drags the page | the page follows the finger. The words follow too (lab default, sheet 108 says "slide, grow and darken into the middle while the page follows the finger"): with progress p from 0 to 1 across one page width, each word's x moves from its slot toward the next slot by p, its size and weight go 16 to 21 and 400 to 600 (the arriving word) or the reverse (the leaving word), its ink goes 38% to 100% or back, its blur goes 1.6 pt to 0 or back | the page does not slide: the finger swipe still changes tabs, but the pages swap by a 150 ms crossfade and the words by a 150 ms crossfade; nothing tracks the finger | same as RM |
| Finger lifts past halfway (or flings) | the words and page settle to the new tab on `Theme.Motion.snappy` (0.25 s), because it is direct manipulation (lab default; the as-built house spring is fine for a tap) | 150 ms crossfade | same as RM |
| Finger lifts before halfway | everything springs back to the old tab on the same curve; no haptic | crossfade back | same as RM |
| Tap on a neighbour word | the words slide to the new slots on the house spring, the page slides one or two pages (a tap two away skips the page between: no flash of the middle page) | 150 ms crossfade | same as RM |
| Tab bar (28 x 5 ink bar) | never moves: it stays under the middle word; only the word above it changes | same | same |
| First or last tab | the missing neighbour side is empty; a drag past the edge resists (the system's paging bounce) and plays nothing | same | same |

The bar and the middle position are fixed so the eye has one place to rest. The page's own content never scrolls inside a tab (sheet 108), so there is no vertical gesture to fight. On the tab row, a drag counts as a tab swipe only when it is more than 24 pt and more horizontal than vertical (PT: `DragGesture(minimumDistance: 24)` and the width/height check); on the page, the paging `ScrollView` decides, with no extra threshold of ours.

### Names that do not fit (QA note on #1142)
- Each neighbour keeps a minimum gap from the word nearer the middle (lab default: 12 pt between the end of one word and the start of the next, measured on the measured text widths, not the slots).
- When the gap would be smaller, the far neighbour on that side is dropped first (it fades out over 150 ms, in every mode), then the near one only if it still collides with the current word. The current name is never truncated.
- This is evaluated at rest and when the selection changes, not per frame while dragging; a word that appears or disappears during a drag does so by the 150 ms fade.
- Build check: the longest Review name next to its longest neighbour (for example "Looks and day" beside "Workout") on the smallest iPhone width fits with the gap, or drops the far neighbour.

## 2. The blur on the neighbours
- Value: 1.6 pt, ink 38% (sheet 108, Kaushik's pick). It is static at rest and animates only as part of a drag or a settle (section 1): the radius is a function of p, not a separate timeline.
- Crisp: under Reduce Transparency, or when the review switch `tabs.neighbours` is Crisp, the radius is 0 and the neighbours stay at 38% ink.
- Low Power: no live radius change (it costs a blur pass per word per frame); the resting radius is kept and the 150 ms crossfade swaps the words (lab default). Reduce Motion alone keeps the resting blur.
- A blurred word is never the target of a hover or focus ring; the focus ring, if any, uses the crisp middle word.

## 3. Haptics
- One `.selection` tick when the selected tab changes, at the moment it commits (finger lift past halfway, or a tap). Not one per tab crossed mid-drag, none for a snap-back, none at the edge bounce (one haptic per moment).
- A tap two tabs away is one tick. VoiceOver's adjust action is one tick (it is still a change of tab).

## 4. VoiceOver and Dynamic Type
- The row is one element: "Workout, tab 2 of 5" with the adjust action (increment goes forward). The value is read once when the tab changes; nothing is read per frame (PT: `PeekTabsCopy.spoken`).
- Focus stays on the tab row after an adjust; the page below is announced as the new tab's name only through the row's value, not twice.
- Accessibility sizes: only the current name shows, with "next: <name>" as a word under it. The name swaps by the 150 ms crossfade, no slide, in every mode (lab default; there are no neighbours to slide).

## 5. Build checks (camelCase, lab defaults)
1. `peekTabsWordsTrackTheFingerBetweenSlots` (Normal): at p = 0.5 the two words sit halfway between their slots, with half the size change and half the blur change.
2. `peekTabsSnapBackPlaysNoHaptic`, `peekTabsCommitPlaysOneSelectionTick`, `peekTabsTapTwoAwayPlaysOneTick`.
3. `peekTabsReduceMotionCrossfadesWordsAndPage` and `peekTabsLowPowerMatchesReduceMotion`: no position change in the words, no horizontal page slide, 150 ms.
4. `peekTabsReduceTransparencyDropsTheBlur` and `peekTabsCrispSwitchDropsTheBlur`.
5. `peekTabsLowPowerKeepsRestingBlurWithoutLiveRadius`.
6. `peekTabsAccessibilitySizeShowsOneNameAndNext`.
7. `peekTabsBarNeverMoves`.
8. `peekTabsLongestNamesKeepAGapOnSmallestPhone` and `peekTabsFarNeighbourDropsFirst` (section 1, names that do not fit).
9. Grep: no raw `withAnimation` or `.animation(` in `PeekTabs.swift` (only `tesseraAnimation` and `withTesseraAnimation`).

## Asks
- **Builder B:** the words do not follow the finger in #1137 (they move only when `selection` changes). The sheet's mid-swipe look needs the page's scroll progress (for example `onScrollGeometryChange` on the paging view) fed into `tabWord`. If that is too costly for this batch, ship as built and take section 1's first row as the next step; the as-built behavior is acceptable for Review.
- **Builder B:** under Reduce Motion the paging `ScrollView` still slides the page under the finger; sheet 108 wants a crossfade swap. If a crossfade swap cannot be done with the paging view, set the page transition to opacity only under RM (it is already opacity-only in `scrollTransition`) and accept the slide that the finger itself makes (lab default: the finger's own movement is direct manipulation, not decorative motion).
- **Design:** confirm the 0.25 s snappy settle after a drag and the Low Power rule that drops the live blur radius.
