# Review guide refresh: what's new since 34665f0

*Research, 2026-10-15, 6:15 PM Pacific. Proposed items for Product to fold into `product/review-session.md`.
Checked against master `3f124ee` (merged 6:06 PM Pacific). 34665f0 is an ancestor of master.*

**Range:** 55 merged PRs from #116 to #169. 18 change app or engine code; 37 are docs only (Research
fixtures #135 to #169, Kitchen and Product sheets #119, #123, #125, #127, #129, #133, #137, #140, #142, #144,
#148, #152). The last code PR is #151 (927608d, 4:46 PM Pacific). Everything after it is docs, so any install
from 927608d to 3f124ee is the same app. QA's ask stands: run `scripts/test.sh` (full run, since TesseraCore
changed) on the install commit, plus one manual run of the new TesseraUITests scheme for the Home swipe (#151).

Of the 18 code PRs, 4 have nothing to try on the phone: #141 (Now ranker; no app code calls it yet), #128
(library variants and the zero-sessions rule; engine only), and the engine halves of #122 and #132 (see
"Not in this build").

## Proposed items (daily use first)

Numbers are new; "Guide" says where each fits in the current list. Times are Pacific.

| # | PR | Area | The one thing to try | Expected result | Guide |
|---|----|------|----------------------|-----------------|-------|
| 1 | #116, #151 | Home, Today | On Today, rest a finger still on a row in Next or Later for a moment, then drag it right. | The name strikes through, the row holds briefly and leaves. Tess says "Done. *title*." with UNDO in vermilion. UNDO brings it back. | New, after 1 |
| 2 | #151 | Home, Today | Flick quickly left or right across the same rows, without pausing first. | Home pages to Review or Training. No task is finished or moved and Tess says nothing. | New |
| 3 | #116 | Home, Today | Press still on a row, then drag it left. | A timed task: "Moved to tomorrow." An untimed one: "Moved to next week." Both with UNDO. | New |
| 4 | #109 | Workout | Log two sets. Tap set 1's stroke, turn the dial or drum, then tap "Save set 1". | The other strokes dim while editing. Tess: "Set 1 is 80 × 7 now." (your numbers), with UNDO. Tapping the same stroke again leaves edit. | Extends 2 |
| 5 | #146 | Workout | Log a set and, while its rest counts down, tap that set's stroke and tap REMOVE. | Tess: "Set N removed." The rest countdown stops (also on the Lock Screen). | Extends 3 |
| 6 | #121 | Workout | During a rest, swap the exercise (pull down on its name), then kill the app and reopen. | Resume takes you back with the rest still counting, not reset. | Extends 4, 5 |
| 7 | #134, #146 | Workout | Tap Tess's soul in the bottom-right corner. Then close it and double tap her. | Tap: a writing line with CLOSE as a word. Double tap: back to Today, where Now shows Resume (the workout keeps running). No glass Tess bar any more. On the last set, "Last one. Hold to finish." stays until you finish. | Extends 1 |
| 8 | #122 | Workout | Only when it happens in real use: start an exercise where last time every set hit the top of the range. | On set 1, the line under it reads "Up 2.5 kg from last time" (your step), not the old "Every set hit ... so +2.5 kg". | Extends 2 |
| 9 | #153 | Tess capture | Type "coffee at 7" before 7 PM. (After 7 PM, try "coffee at 11".) | Before 7 PM: "Coffee, today 7 pm." A bare 1 to 6 means PM; 7 to 11 means the next one that hasn't passed today, else tomorrow morning. | Drop gap |
| 10 | #153 | Tess capture | Type "watered plants sat". | Saved as a note dated last Saturday, not a task: "Noted for Saturday." | Drop gap |
| 11 | #153 | Tess capture | Type "get a haircut", then "get coffee". | "Get a haircut, in Later." lands as a task. Coffee goes to Groceries: "Coffee, on the list." | New, beside 8 |
| 12 | #117, #153 | Tess capture | Type "are we out of milk". | No ghost row is saved. Questions (a "?", or starting with "is" or "are") are never filed as tasks or items. | New, beside 8 |
| 13 | #118, #124, #131 | Groceries | Kitchen, then Groceries. Type "3 egg" on the "Add" line. Then hold the "Groceries" title about 0.7 s, and tap items to strike them. | "3 eggs" files under its aisle. The hold fills the title with vermilion and starts the shop: the aisle you're in is the big word, with "then *next aisle*" peeking. A struck item drops a dab into "N in the basket" at the bottom. An emptied aisle folds away and the next rises. | Replaces 9 |
| 14 | #124, #131 | Groceries | **Basket-clearance check.** Mid-shop, tap the basket, hold "Clear the basket", then tap UNDO. | Tess: "Cleared N from the basket." with UNDO; UNDO puts them all back in the basket. Then finish with the "Done" hold key: it clears the basket and ends the shop. Tell us if the UNDO line ever shows a line from somewhere else (QA K3). | Replaces 9's "Done shopping" |
| 15 | #118, #124, #126 | Review | On Review, scroll to the foot and tap "Backups". Go back once with "‹ Review", once with an edge swipe. Then edge swipe on Review itself. | Backups opens inside Review. Both ways back work. The edge swipe on Review does nothing and nothing freezes. | Extends 10 |
| 16 | #120 | Review, Backups | Only if a Tessera copy is in Files: tap Restore and pick it, then tap "Keep what's here". | First a question: "Replace everything with the copy from *day*?" with a hold key. "Keep what's here" changes nothing. Don't hold Replace on the phone. | Extends 10 |

## Not in this build (named in the task, not on master)

- **Rest-day line on Now.** The engine answer is merged (#132, and #141 ranks it), but no app code calls
  it. The Home hookup is on branch `ios/now-rank`, unmerged. On the phone Now still offers the next routine on
  a rest day. The week page only spreads rest days when the plan has "Sessions a week" set, and nothing sets
  it, so expect no visible change there either.
- **Review week fix** (session count, rest dab, miss ring). Not on master.
- **Empty states** (`EmptyLine`, "Push day, no sets, not saved."). Not on master. A zero-set finish still
  saves as before.
- **Undo lines** ("Set 3 taken back"). Not on master. Old words remain, for example the routine editor's
  "Undone." and Siri's "Last set removed."
- **4 AM day** (`TesseraDay`). Not on master. Days still cut at midnight, so late-night "tomorrow" and Now
  after midnight behave as before. Don't test past midnight yet.
- The "back word" did land: it is the "‹ Review" on Backups (#124), item 15.

## Drop these known gaps from the guide

- "Tapping a logged set to fix it comes with #109." It's in: items 4 and 5.
- "Some typed phrases still land wrong, especially past tense ... or a bare hour ..." Replace it with the
  narrower gaps below (QA review-153, still open):
  - "buy a lightbulb" or "get a cake" can land as a task instead of Groceries (G9).
  - "tonight" with no time, said after 8 PM, lands tomorrow at 8 PM (G11).
  - "move dentist to 3pm" can land the task in the past (G10).
  - A name ending in -ed can read as a past log: "Ahmed bday sat" becomes a note (G12).
- Keep: voice (Speak says "comes next"), cook mode not built.

## Other changes worth one line in the guide

- UNDO is now a vermilion word everywhere (Home, workout, Groceries) (#147).
- Holds land as one medium clunk; the stroke bloom is softer (#109). Fits Look and feel item 2.
- Item 9's "Done shopping" stroke no longer exists; it is now the "Done" hold key (item 14).
