# Motion for every side (lab, board REFILL 2, items 1 to 4)

Builds on sheet 75 (every screen has a side, two stops), sheet 76 (along, side pages, edge zones) and tess-picks §20.
One host, one motion: every side below rides `SideHost`, so none has a motion of its own. This sheet fixes only the
parts that differ by side, and the values are lab defaults for Design to overrule.

## The shared motion (from 75 and 76, restated once)
| What | Value |
|---|---|
| Into the glance, into the full side, along a run, between a side's pages | The body moves 1:1 under the thumb and settles on the house spring over 380 ms. The leaving page keeps a soft edge shadow above 736 |
| Her glance | `sideTurned`: eyes only, 0.4 toward the incoming content over 380 ms, then ahead over 300 ms. Only into stop 1 and back onto the front |
| Her line | Lands when stop 1 settles (420 ms) and is the same line at stop 2 |
| Haptic | One `.selection` on landing on the full side. None for the glance, a page, along, or a run's end |

## Per side
| Side | Page entry | Glance's one big fact | Run end |
|---|---|---|---|
| THE SETS (a workout) | The sets arrive with the page, no stagger | The count of sets (Hero 56), no count-up | Not a run |
| PER 100 G (an ingredient) | The table arrives with the page | The top number, e.g. "165", with its unit "kcal" at 21 | Not a run |
| An exercise's four pages: HISTORY, REP MAXES, MUSCLES, SETUP | Along the pages: 44 pt and a fade, 380 ms. The facet word changes between ink and 40% with a 150 ms crossfade. Nothing else moves | HISTORY's last set ("82.5 × 7") | After SETUP, and before HISTORY, the body rubber-bands: 1:1 under the thumb with 0.35 resistance, at most 24 pt, back on the house spring over 380 ms. It never wraps. No haptic |
| WHERE IT'S MENTIONED (a note) | The links arrive with the page | The count of places | Not a run |
| ITS STORY (a task) | The events arrive with the page, newest first | The last event, one line | Not a run |
| WHAT'S IN ONE (a backup) | The contents arrive with the page | The size or the count, Hero 56 | Not a run |
| Review THE DAYS | Along the weeks in the middle: 44 pt and a fade. The seven days are one block | "5 of 7 days" | The first and last week rubber-band as above, never wrap |

- **Nothing counts up and nothing staggers.** A glance's big fact arrives with the glance, blurred in over 300 ms as every value word does (§5). A count that changes while a side is open just changes, with no animation (Design's ruling, sheet 77 sync); it never rolls. Paste's WHAT I READ lines show all at once. The shop peek on Groceries follows 75's rule 7, and Groceries' FOR WHAT never moves a row between cooks while it is open (a row shared by two cooks shows once under the soonest).
- **Run end versus her peek:** a run's or a page's end sends her nothing. Only vertical scrolling to a page's last row is idea 9's `reachedEnd`.
- **Cover page entries:** on entering a side's second and later pages the facet word moves, the body does not carry the title or the back word (the spine holds), and Tess's band holds still.

## Private labels ("Private note", "Note kept private")
The soul stays exactly as on any other label. There is no reveal animation, no glance toward the label, no pause, no extra beat, and `sideTurned` plays the same as on a side with nothing private, so her motion can never tell anyone a hidden thing is there. The label text arrives with the same 300 ms blur as any value word. Counts of private notes are counted, never named. Test: a side with private entries and one without produce identical router events.

## Reduced-motion and Low Power variants
| What | Reduce Motion | Low Power |
|---|---|---|
| Into the glance, full side, along, between pages | A 200 ms crossfade, no 1:1 slide settle (the drag still follows the thumb while it is down) | The same as Reduce Motion for the settle only; the drag keeps its spring |
| Edge zones | The same zones and rules; no edge shadow | The same as normal |
| Run-end bump | No bump: the body stops at the end and nothing moves | Normal |
| Facet word | A 150 ms crossfade, as normal | Normal |
| The soul | `sideTurned` plays nothing. She holds §13's still frame with the opacity breath and the blink | `sideTurned` plays nothing; the idle tick is 30 fps (§13) |
| Her line | Lands at the same time with a 200 ms crossfade, no blur | Normal |

## Haptics for the new surfaces (one per moment)
- Landing on a full side: one `.selection` (75). Nothing for the glance, a page, along, a run's end, the facet word, a tap on the glance's word.
- A side's one key (ADD N TO GROCERIES, 75 rule 6): its own existing success haptic, once. The side's `.selection` never doubles it, because the key is pressed on a side that has already landed.
- The soul adds none (§1, 18b's `.soulStroke` is the only haptic of hers).
- For "releases 1 to 5": any new surface not named here gets no haptic until its sheet names one moment for it.
