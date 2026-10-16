# Next build's phone script (board item 118)

For: QA, to fold into `install-day-script.md` for the build after 7b321d2. Owner: Research lab.
Date: Oct 16, 2026 (Pacific). Read on master 484c8b7 and open PRs #347 (training rise) and #353 (Field 18).

The script follows the install-day script's shape: one row per step, and one expected line per row, so each row is pass or fail. About 6 minutes on the phone.

**What the build carries:**

| Area | Source | State |
|---|---|---|
| 42, the glass tabs | #342 | merged |
| 44 part two | #347 | open |
| Ask Tess sizes | #353 | open |
| AI-1 Home lines | Builder B's Home PR on `HomeLines` | no PR yet |

Run each group only if its PR is in the install commit (QA checks with `git merge-base --is-ancestor`). A group whose PR isn't in is skipped, not failed.

## Glass tabs (#342, Design 42)

| # | Do | Expect | Result |
|---|---|---|---|
| G1 | On Today, swipe left slowly to Training, then let go halfway and swipe back. | The page moves 1:1 under his finger. The ink line stretches from TODAY toward the next word and snaps back on release. The words never move. | [ ] P [ ] F |
| G2 | Hold the tab row for about a quarter second. | A glass pill rises under his finger with one tick. The pages shrink, and the neighbours show live at either side, dimmer. The ink line fades while the pill is up. | [ ] P [ ] F |
| G3 | Still holding, slide along the row through every word, then come back to the start. | One tick per word, never a buzz. The word under the pill swells, and the pages slide with his finger. | [ ] P [ ] F |
| G4 | Let go on TRAINING. | The pages grow back, the pill melts into the ink line under TRAINING, and Training is open. | [ ] P [ ] F |
| G5 | Hold the row, don't slide, let go. | Cancel: the same return, the same page, no tick on release (#342 "a hold with no slide is a cancel"). | [ ] P [ ] F |
| G6 | Hold, then slide your finger off the bottom of the screen. | The pill lets go as if released over the last word under it; nothing stays stuck (#342 "cancelled touches let go"). | [ ] P [ ] F |
| G7 | Settings > Accessibility > Motion > Reduce Motion on, then repeat G2 and G4. Turn it off. | No shrink or melt: a plain fade between pages. The tick still comes. | [ ] P [ ] F |

## Training, part two (#347, Design 44)

| # | Do | Expect | Result |
|---|---|---|---|
| T5 | On a training day, on Training, tap START. | The rest of the plan sinks back and fades. The workout opens out of the first exercise's lane, not from the bottom of the screen. | [ ] P [ ] F |
| T6 | Tap START, then swipe to another tab before the workout opens. Come back to Training. | The plan is whole again: nothing sunk, START still there (QA L1). | [ ] P [ ] F |
| T7 | Finish the workout on the evening before his rest weekday, then look at Training. | The Start mark reads **REST DAY TOMORROW** as a label with no ink line. This replaces the old T3 "known gap" row. | [ ] P [ ] F |
| T8 | On a night before a training day, look at Training after finishing. | **PULL A TOMORROW** (the routine the plan lands on), a label with no ink line. | [ ] P [ ] F |
| T9 | Tap ROUTINES. Then swipe back from the left edge (not the back word). | The routines page opens with **‹ TRAINING** top left (no system chevron). The edge swipe brings him back to Training. | [ ] P [ ] F |
| T10 | On Training, watch Tess's line when it is long (say something she answers in two lines). | It wraps to two lines, never ends in "…", and the plan line under it doesn't move. | [ ] P [ ] F |

## Ask Tess sizes (#353, Field 18)

| # | Do | Expect | Result |
|---|---|---|---|
| F1 | Open Ask Tess and type "call mom at 6". | What he types is a step smaller than Tess's own line above it. It is clearly his, and hers reads louder. The drying line sits just under his words. | [ ] P [ ] F |
| F2 | Notes: start a note, type a first line, then a body. | The same smaller size for the first line and the body as for Ask Tess. | [ ] P [ ] F |
| F3 | Settings, CLAUDE, the key field (just tap in, don't type the key), then the amount. | The key field uses the same size. The receipts page's back word reads **‹ SETTINGS**. | [ ] P [ ] F |
| F4 | Settings > Display & Brightness > Text Size to the largest, then repeat F1. | His text and Tess's line both grow, and nothing is cut. Set the size back. | [ ] P [ ] F |

## Home lines (AI-1, once Builder B's Home PR is in)

The expected words come from `HomeLines` on master (#334). See `fixtures/home-lines-day.md` for the full day.

| # | Do | Expect | Result |
|---|---|---|---|
| A1 | Morning, a training day, nothing started: look at Today. | The hero is the routine's name, "Push A", with **today** above it. Nothing ends in "…" and there is no " · ". | [ ] P [ ] F |
| A2 | After 17:00, the same. | **this evening** above "Push A". | [ ] P [ ] F |
| A3 | Start the workout, log 2 sets on the first exercise, close it from the workout. | Hero "Push A, paused at bench", with **paused just now** above (after a minute: "paused 1 min ago"). | [ ] P [ ] F |
| A4 | Finish it. | Hero "Push A done", with **done at** *the time* above, for example "done at 8:05 pm". One tap down: "*n* exercises, *n* sets." plus ", 1 new best." if he set one. | [ ] P [ ] F |
| A5 | After midnight, before 04:00, look at Today. | The same "Push A done" and the same time. His day hasn't turned. | [ ] P [ ] F |
| A6 | Plan a cook ("cook tacos tonight") with 2 grocery rows for it. | Hero "Tacos today" before 17:00 and "Tacos this evening" after (see G8 in the day fixture). Above it: **2 to buy**. | [ ] P [ ] F |
| A7 | Rest day morning. | Hero **Rest day**, with the weekday above it. | [ ] P [ ] F |
| A8 | Largest text size, then A4. | The hero steps down to two lines, and nothing is cut. | [ ] P [ ] F |

Known gaps, so they're noted rather than failed (from `fixtures/home-lines-day.md`):
- A finished cook leaves Home (G1).
- A paused shop still says "at the store" (G2).
- The workout row says "record" while SO FAR says "best" (G3).

## Not checkable on the Simulator

- G2-G4: the glass and the ticks need the phone.
- F1: the size difference is clear on the Simulator, but the feel needs the phone.
- A5: needs the clock past midnight. Use `-demoTime 00:40` on the Simulator; the phone just needs a late night.
