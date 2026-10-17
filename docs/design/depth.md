# One way to show more (Design item 76)

**Kaushik's ask, Oct 16, 2:45 PM PT:** make the two stops a design principle. Allow swiping through when a side has several pages of information. Decide horizontal or vertical. A side makes no sense when a screen is one of a collection of things, so find an elegant way through that.

- Study: `studies/depth.html`. Board `mockups/depth.png`. Recording `recordings/depth.mp4` (25 s, Porcelain). The recording goes along Review's weeks and back, then in to the glance and the full side. On Bench press it goes in to the glance and the full side, through the four pages with a rubber band at the end, then back to the front.
- This sheet builds on 75 (every screen has a side, two stops) and 73 (the index). It changes 75's rule 4 and rows 7, 8 and 20 (folded into `every-side.md`).

## The answer in one line
Horizontal moves between things and goes deeper. Vertical only reads. Each part of the screen has one job, everywhere.

## The map
| Where the pan starts | What it does | Always? |
|---|---|---|
| **The left edge** (the first 24 pt) | **Out.** From a side, it lands on the front. From a front, it goes back to where you came from, as iOS does | Every screen |
| **The right edge** (the last 32 pt) | **In.** A little goes to the glance, further goes to the full side (75's two stops) | Every screen. It's the one way in that never changes |
| **The middle** | **Along**, when the screen is one of a run: the next day, the week before, the next exercise, or the side's next page. When there's no run, it goes **in**, as the edge does (75's left swipe past 60 pt) | Every screen |
| **Up and down** | **Reading.** It scrolls one page and never moves between things | Every screen |
| **Pull down at the top** | **Everything**: the index of areas (73) | Every page but a live one, which keeps its own pull (rule 7 in 75) |
| **Tess's band** (736 and below) | Hers | Every screen |

**The order, when zones overlap** (motion lab, on 1cab06a): Tess's band wins first. A pan that starts at 736 or below is hers, even inside an edge zone, because the right edge's last 32 pt (x 361 to 393) overlaps her home at (346, 779) and her 64 pt hit area. The edges come next, then the middle. The edge zones stop at 736.

**Swipe right always goes one step back the way you came.** From the full side it goes to the glance, and from the glance to the front. On a side's second page it goes to the first. Along a run, it goes to the one before. The left edge skips all of that: from a side it lands on the front, and from a front it leaves.

## Collections: one of a run
A screen that's one of a run (a week in Review, an exercise in a routine, a day) doesn't lose its side. The side is about *this* member: this week's days, this exercise's history. So the run takes the middle, and the side takes the right edge.
- **Along keeps the name.** The area name or back word and the title's place hold still. Only the body moves, 1:1 under the thumb, and it settles on the house spring over 380 ms. The leaving page keeps a soft shadow on its edge, so the two pages read as paper, not as a cut. The shadow stops above 736, so it never darkens her band.
- **The ends of a run** rubber-band. There's no dot row and no counter: the context line already names where you are ("Oct 12 to 18").
- **The run is the parent's order.** Days run by day, weeks by week, and exercises in the routine's order. A run never wraps around.
- **Live surfaces keep theirs.** The live workout's exercise lane is its own run, and its side is still a peek (75, rule 7).

## A side with pages
A side can hold up to four pages, when one page would be too long or mixes kinds.
- **The facet words** sit in a row under the title at 196: Label 13/700, .08em, 20 pt apart. The current one is ink and the rest are at 40%. There are no dots and no underline. Tapping a word goes to its page.
- **Inside the side, the middle moves through the pages,** 1:1 with a rubber band at the ends. The run outside (the next exercise) waits until you're back on the front. Only the nearest run moves.
- **The glance** shows the first page's big fact and two small ones. Its word at the foot is ALL OF IT.
- **Each page keeps 75's rules:** no controls, one kind, and Tess's line in the band.
- **Ends:** hitting the end of a run or of a side's pages rubber-bands and tells Tess nothing. Her `reachedEnd` peek comes only from scrolling to a page's last row.
- **Haptics:** one `.selection` on landing on the full side (75), and none between pages. The facet word's change is the signal.

## What changes on the built screens
| Screen | Before (75) | Now |
|---|---|---|
| **Review tab** (row 20) | THE MONTH, word only once x moved by week | The middle goes along the weeks (46's paging, now drawn). The right edge opens **THE DAYS** (PARTS): this week's seven days, one line each ("Wednesday, Pull A and Row, 6 tasks"). The glance reads THE DAYS, "5 of 7 days", "Wednesday, 6 tasks", "2 to go". THE MONTH is dropped. Zooming out is the run, not a side |
| **An exercise** (row 8) | YOUR SETUP, word only, with HISTORY, REP MAXES and MUSCLES as sibling views on x | The middle goes along the routine's exercises. The right edge opens one side with four pages: **HISTORY, REP MAXES, MUSCLES, SETUP**. The front's context word is HISTORY. The glance reads HISTORY, "82.5 × 7", "today, a best", "about 102 kg for 1". Tess's line: "About 102 kg for 1, estimated." |
| **Plans WEEK, MONTH** (row 7) | THE PLAN, word only | WEEK and MONTH are a run, so the middle goes between them. The right edge opens THE PLAN, and the word still works |

Every other row of 75 is unchanged. A screen with no run keeps both ways in, the middle and the edge.

## Motion and access
- **Motion** (for the motion lab): along and in share the house spring (380 ms). Tess's `sideTurned` plays on the way in to the glance and on the way back to the front only (75). It never plays along a run or between pages.
- **VoiceOver:** the run is an adjustable element on the body ("Week of Oct 12 to 18. Swipe up or down for another week."). The side is a custom action named by its word ("Show the days"), and the facet words are buttons. Nothing depends on an edge pan.
- **Reduce Motion:** along, in and between pages are each a 150 ms crossfade (MotionPolicy).
- **Dynamic Type:** facet words wrap to a second row before they shrink. The glance's big fact drops to Title 44 when it won't fit on one line at Hero 56.

## For each team
- **Core (0ak SideHost):** the host owns the three horizontal zones. It needs the left edge (24 pt), the right edge (32 pt) and the middle, which is along when the screen declares a run, else in. The edge zones win over a row's own swipe only when the pan starts inside them. The edge zones stop at 736: below that, the pan is Tess's. A screen declares `run` (its parent's ordered ids, or none) and `side` (one or more pages, each with a kind and a word).
- **Builder A:** the exercise page's sibling views move into its side's pages, and x goes to the routine's run. Plans' WEEK and MONTH become a run.
- **Builder B:** Review pages by week in the middle (46) and gets THE DAYS on the right edge. It replaces the Review row in 74 ("None") and THE MONTH in 75.
- **Product:** board it with 0ak. The Review and exercise rows ride after 0ak like the other drawn sides.
- **Research:** add fixtures for the glance on THE DAYS and on the exercise's HISTORY to BD2. Add a run-end test (the last week rubber-bands and never wraps).

## Research BL calls (Oct 16, 4:50 PM PT; fixtures/depth-76.md)
- **Bench numbers come from the formula.** The estimate is master's Epley (SystemCatalog.swift:357): 82.5 × 7 gives about 102 kg for 1. REP MAXES shows the best logged weight at each rep count, and a count with no logged set is estimated from that figure, rounded to 2.5 kg and marked "estimated" ("3 reps, 92.5 kg, estimated"). The 1-rep row is the e1RM itself, to the whole kg, so it matches the glance ("1 rep, 102 kg, estimated"; Research BQ). The study is fixed to match.
- **The left edge:** the map table rules. From a side it goes to the front, and from a front it leaves.
- **iOS's full-content back swipe** (a right swipe anywhere goes back) is off on screens the SideHost holds, so the middle keeps its step back. The SideHost owns the left 24 pt through the system's own edge back swipe. Core checks the API name.
- **THE DAYS:** a day counts when it has a session, a task done or a cook. Notes don't count. "N to go" shows only on the current week. The fullest day is the one with the most tasks done. The foot word is ALL DAYS.
- **HISTORY's "a best"** is any best, including a rep-max best. That needs a small change to ExerciseDigest, which today flags only the top e1RM. A first session reads "the first time", never "a best".
- **A run's end:** no haptic. Under Reduce Motion nothing moves or fades there.
- **Known on master:** the exercise window takes every horizontal pan (ExerciseViews.swift:38-49) until Builder A moves those views into the side. Review pages only the current week (ReviewPage.swift:233) until Builder B's paging lands.
