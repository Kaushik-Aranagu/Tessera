# 79. Builder briefs for sheets 77 and 78

One brief per Mac lead, drawn only from sheets 76 (`depth.md`), 77 (`sides-77.md`) and 78 (`pantry.md`). Nothing here is new design; where a sheet and this page differ, the sheet wins.

## Rules every lead holds
- Receipts name the thing first, then what happened ("Limes, in.", "Milk, on Groceries.", "Pantry, 6 added.").
- No "…" anywhere. Times read "7 pm", never "at 7 pm" before a time. Digits for counts. " · " only inside a pack size.
- UNDO is 4 s for a new add or entry, 10 s for a change; both 10 s under VoiceOver (one app-wide UNDO slot).
- No controls on a side (Pantry's one key is the only exception). Cobalt is Tess's voice only. Tess's one line is the same at glance and full.
- Reduce Motion: 150 ms crossfade through MotionPolicy. Private paste lines are only ever "ignored", never their words.

## Core: 0ak SideHost and the default object/class page side
**Scope**
- SideHost owns the horizontal zones: left edge 24 pt (out), right edge 32 pt (in: glance, then full), middle (along a run when the screen declares `run`, else in). Edge zones stop at 736; below that the pan is Tess's.
- A screen declares `run` (parent's ordered ids, or none) and `side` (one to four pages, each with a kind and a word). Facet words at 196, Label 13/700.
- Default object side DETAILS (LINKS + FACTS): where it is linked from, then every field the front does not show. Class page side ITS OBJECTS (LINKS): newest (3 named, "and N more"), most used (3), fields every one has.

**Read:** `depth.md` (map, order when zones overlap, A side with pages, For each team, BL calls); `sides-77.md` rows "A class page" and "Any other object", For each builder team.

**Rules that matter:** swipe right goes one step back; a run never wraps and its ends rubber-band with no haptic; `.selection` once on landing on the full side; no haptic at the glance; iOS full-content back swipe off on SideHost screens, left 24 pt through the system edge swipe (check the API name). Foot words: ALL LINKS (class), ALL FACTS (default object); DETAILS is a proposal.

**Acceptance**
- A pan starting at 736 or below never moves the host, even inside an edge zone.
- Left edge from a side lands on the front; from a front it leaves.
- A screen with a run: middle goes along, right edge goes in; no run: both go in.
- Run ends rubber-band and never wrap.
- The default object side lists no private field and names none (test it).
- The class side shows "and 35 more" from four objects.
- Context lines are 6 words or fewer; Reduce Motion crossfades 150 ms.

**Not in scope:** the individual screens' side content (Builders A and B), Tess's `sideTurned` motion beyond 75's, VoiceOver beyond the custom action named by the side's word.

## Builder B: Kitchen, Settings, Pantry
**Scope:** Groceries FOR WHAT; Recipe original COOKS; Paste WHAT I READ; The week WHAT LEAVES THE PHONE; Pantry front and side; the fifth index row.

**Read:** `sides-77.md` rows Groceries, Recipe original, Paste, The week, Plans, Copy notes; `pantry.md` The front, The side, The index, Rows for Kitchen's acceptance, UNDO lengths; `depth.md` Collections (Plans WEEK and MONTH as a run).

**Copy rules that matter**
- Group names read "TACOS, SUNDAY", not "Tacos · Thursday". A row for two cooks shows once with "also chili".
- Foot words: ALL LINKS (Groceries), THE WHOLE STORY (COOKS), ALL OF IT (Paste), ALL FACTS (week, Plans), ALL OF THEM (Pantry).
- Pantry hero "4 out, 2 low"; quiet "Nothing out", "Nothing yet". Receipts "Limes, in." (10 s UNDO, a change) and "Pantry, 6 added." (4 s UNDO, a new add).
- Pantry side shows "bought Sat" per line; USUALLY HAVE names up to three, from four "Rice, coffee and 2 more". Never summed, no nutrition, nothing red.

**Acceptance**
- Groceries side groups by cook, soonest first, then JUST BECAUSE and one USUALLY line.
- COOKS shows each time cooked newest first with how long; Tess's median line only from 2 cooks.
- Paste shows all 17 lines; a private or secret-looking line shows only a bar and "ignored"; a secret never reaches the side's text.
- The week shows counts by job, titles and counts only, no money of his.
- Pantry state word cycles in, low, out with one `.selection`, one UNDO, the digits just change (nothing counts up); a line that becomes in leaves the page.
- ADD N TO GROCERIES: N equals the glance's "to buy"; at 0 "Nothing out." and no key.
- The index has five rows (REVIEW, TODAY, TRAINING, KITCHEN, PANTRY), glass 700 tall, Pantry's line is the hero.

**Not in scope:** Core's host and the default/class sides, Ingredient.state and lastBoughtAt model work (Core), Review paging and THE DAYS (separate Builder B item in 76), the recipe peek, nutrition anywhere.

## Builder A: Training
**Scope:** Routines LAST TIMES (BEFORE); the exercise page's side with four pages (HISTORY, REP MAXES, MUSCLES, SETUP) and the routine's exercises as the run. Plans: THE PLAN side, and WEEK and MONTH as a run (sheets 76 and 77).

**Read:** `sides-77.md` row Routines, For each builder team; `depth.md` Collections, A side with pages, What changes (An exercise row), Research BL calls (bench numbers, HISTORY's "a best").

**Copy rules that matter**
- Routines lines newest first: "Push A, today" with how long, "Legs A, Wednesday  1 h 1 min". Glance foot THE WHOLE STORY; Tess "Push A, 4 times this month."
- Exercise glance: HISTORY, "82.5 × 7", "today, a best", "about 102 kg for 1"; foot ALL OF IT. A first session reads "the first time", never "a best". "best", never "record".
- REP MAXES: unlogged counts estimated, rounded to 2.5 kg, marked "estimated"; the 1-rep row is the e1RM to the whole kg.

**Acceptance**
- Routines page owns the swipe; a row swipe stays DROP.
- The middle on an exercise goes along the routine's exercises; the right edge opens the side; the front's context word is HISTORY.
- The four facet words sit at 196, current ink, rest at 40%, no dots; tapping a word goes to its page.
- The middle moves between pages 1:1 with a rubber band at the ends; no haptic between pages.
- Glance numbers match the Epley formula (82.5 × 7 gives about 102 kg for 1).
- ExerciseDigest flags any best, not only the top e1RM.
- The exercise window no longer takes every horizontal pan.

**Not in scope:** live workout lane (keeps its own run and peek), SideHost itself, Review.
