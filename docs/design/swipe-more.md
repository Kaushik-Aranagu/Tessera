# 71. Swipe for more: the map, and who owns a left swipe

**Kaushik's principle, in one line:** a little more of a page is one swipe away, wherever it helps, and never by taking a gesture the page already uses.

His ask (Oct 16, recipe pick): "swipe to show more details… wherever needed into other places as well". Sheet 69 set the house rule: a page one tap down may have one side page, opened by a left swipe or by a word, with the page's spine kept in view. This sheet does two things:
- It says which pages get a side page, and which already have their "more" on x.
- It settles who owns a left swipe, because several pages already use one: Home's TOMORROW, Groceries' remove (65), and the routine editor's DROP.

- Board: `mockups/swipe-more.png`. Left to right: who owns the swipe on the routine page, a row's own swipe mid-drag, and LAST TIMES.
- Recording: `recordings/swipe-more.mp4` (10.6 s). It shows four things in order: a row swipe is the row's (DROP rises, and released short it springs back), a swipe off the rows opens LAST TIMES with the name held in place, a right swipe comes back, and the word opens it too.
- Study: `studies/swipe-more.html`.

## Who owns a left swipe
The rules are checked in this order. The first one that matches wins.
1. **The left edge (the first 20 pt) is back.** `EdgeSwipeBack` always wins, on every page and side page. On a side page, the edge swipe comes back to the page first.
2. **Tess's band (736 to 820) is hers.** A pan that starts there is a stroke (motion lab 18b), never the page's.
3. **A row with its own swipe keeps it.** A swipe that starts on such a row is the row's: TOMORROW on Home, remove on Groceries and the lists, DROP on the routine editor.
4. **Otherwise the page's.** Anywhere else, such as the hero, the context line, the gaps between rows or the space under the last row, a left swipe past 60 pt opens the side page. A right swipe closes it.
5. **The word always works.** The side page's word sits at the right of the context line (or at the right of the key row, as on the recipe page) and opens it. The side page shows the way-back word in the same place. Nobody needs to know the gesture.

## The map
| Page | Its "more" | How |
|---|---|---|
| Recipe page (69) | INGREDIENTS, B's list with the used rows dimmed and the Groceries key | A side page, with the time stroke as its spine |
| Routine page (routine editor) | **LAST TIMES**, new on this sheet | A side page, with the name held in place as its spine |
| Exercise page | HISTORY · REP MAXES · MUSCLES | Already on x as sibling views, so no side page |
| A note | LINKS | Already on the page under the text, so no side page |
| Habits | None | By decision: only this week shows, with no history row and no best week (`habits.md`). Nothing hides behind a swipe either |
| Day log, Review week | Other days and weeks | x already moves by day or week, so no side page |
| Groceries and lists | None for now | Their rows own the swipe. A side page there (say, what he usually buys) is the Kitchen lead's call first |
| Settings, Backups, Receipts | None | Settings and money never hide behind a gesture |
| Tab pages (Home, Review, Training, Kitchen) | None | x on a tab page is the rail |
| A live workout, the finish screen, Speak, a flight | Never | Live things own their surface. A cook may peek at ingredients (69), because the recipe page is the cook |

## The spine
The spine is what keeps him oriented while the side page is open.
- A page with a vertical strip keeps the strip at the left edge, like the recipe page's time stroke and its bead.
- A page without one keeps its name in place, as the routine page does, and only the body slides.
- The body moves 44 pt left and fades. The side page comes in from 60 pt on the right, over 320 ms on the house curve, 40 ms behind the body. Under Reduce Motion it's a 200 ms crossfade.

## LAST TIMES (the routine page)
- **The word:** LAST TIMES (Label 16/700, `ink`) at the right of the context line ("5 exercises, about 55 min"). On the side page it reads EXERCISES in the same place.
- **The page:** "LAST 4 TIMES" as a label at 196, then one block per time, newest first, 20 pt apart:
  - the day at Body 21/600, "Thursday, Oct 15";
  - under it, one sentence at Body 21, `inkSecondary`: "5 of 5, 1,072 kg moved." It adds a best when one landed ("Bench 82.5 × 7, best.") and what was left out ("Cable fly left out.").
  The numbers keep no-break spaces around "×".
- **At most four times.** With fewer, show what there is. With none, the word is absent, so there's no empty side page.
- **A tap on a day** opens that workout's finished page (the zoom, as from the Day log).
- **Nothing is red, and nothing compares.** A short day reads only what happened. There is no "down from last time".

## For the builders
- **Builder A (routine editor):** add LAST TIMES under the rules above, so a left swipe that starts on an exercise row stays DROP. The data is the routine's finished workouts from the ledger (Core already has `nextRoutine` and the summaries). UI tests: a row swipe never opens the side page; a context-line swipe does; the word does.
- **Builder B (recipe page, 69):** apply rules 1 to 5 to the peek. A swipe on the recipe page's rows doesn't exist yet, so rule 4 covers the whole page above the band.
- **Core:** a `lastTimes(of: routine, limit: 4)` read with the counts, kg moved, bests and left-out exercises, all as plain facts. The words are the view's.
