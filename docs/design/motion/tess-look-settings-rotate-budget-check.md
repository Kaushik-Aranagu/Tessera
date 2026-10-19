# Check: Look and Settings motion against the Rotate budget (board 78)

Checks sheet 93's page turn and row motion, and what the code does today, against the Rotate numbers in `tess-page-turn-motion.md:11,13`. Result: Rotate itself fits (460 ms at six rows); the motion around it does not, and three numbers have no ruling. Nothing here is a ruling; lab defaults are marked and go to Product in §6. Checked at master `ce2cd3a3` (code) and `decisions.md` to line 1053.

## 1. What the budget is
- **Source of the numbers:** `tess-page-turn-motion.md:13`, credited to Design (Oct 17, PM). `decisions.md:917` rules the Page turn row, its four words (Slide, Turn, Soften, Rotate), the Rotate slot model and the default (Turn); `decisions.md:925` rules R1 to R4 (R2 no haptic; R3 Low Power = Reduce Motion, a 150 ms crossfade). The 160 / 260 / 24 numbers themselves are **not in `decisions.md`**.
- **Per row slot, not per page.** Slot k leaves at 24k ms (lifts 14 pt and fades, 160 ms) and arrives at 80 + 24k ms from 40 pt below (260 ms). The page total is derived and never padded: 80 + 24(N-1) + 260 = **460 ms at N = 6**, 388 ms at N = 3. Max six rows. Curve `Theme.Motion.pageTurn` (.22, .8, .2, 1).
- **Stale numbers:** `pages-90.md:21` still says Rotate is 480 ms with a 34 ms stagger (withdrawn, `tess-page-turn-motion.md:13`). Sheet 93 has no timings, only "follows sheet 90" (`settings-93.md:12`).

## 2. Today in code
Nothing animates a Settings page turn: there is no page-turn code, no Settings screen shell and no `Theme.Motion.pageTurn` token on master (`tess-settings-motion.md:6`). What does move today:

| Motion | Number today | Against 460 ms | File:line |
|---|---|---|---|
| Look change on Review | `.easeInOut` 0.7 s (0.25 s asked under Reduce Motion, forced to 0.15 s by the policy) | over by 240 ms; not a row turn | `DesignSystem/LookSentence.swift:119` |
| Rest day open / close | `Theme.Motion.house`, spring 0.42 s bounce 0.12 | over 260 ms in; spring tail | `Features/Settings/RestDaySentence.swift:22,85` |
| Claude section rows | `house` springs; `easeOut` 0.18 s on the switch word | spring over 260 ms; 0.18 s fits | `Features/Settings/ClaudeSection.swift:112-115,191` |
| Claude remove fold | `easeInOut` 0.22 s | fits | `ClaudeSection.swift:380` |
| Claude month stroke | `easeOut` 0.5 s, once, a draw | 40 ms over; not a turn | `ClaudeSection.swift:438` |
| Review row entrance | `.smooth(0.28)`, 35 ms stagger (`Theme.Motion.stagger`), 14 pt rise | stagger 11 ms over Rotate's 24 | `DesignSystem/Editorial.swift:56-81`, `Theme.swift:583` |
| Review week marks | `house`, 50 ms per index | not a row turn | `ReviewView.swift:282` |

Spec only (no code, no number in any ruling): Settings arrival rows (10 pt rise, 40 ms apart, `tess-settings-motion.md:14`), the page-turn row opening (320 ms, `tess-finish-hero-settings-paging.md:19`), stepper and picker steps (none anywhere), the Look swatch on the Settings Looks page (none; `settings-place.md:26` has a 250 ms flood, ruled down to 150 ms under Reduce Motion).

Two stale lines found on the way: `Editorial.swift:57` says "25 ms stagger" while the code at `Theme.swift:583` uses 35 ms; and `LookSentence.swift:119` carries a dead 0.25 s Reduce Motion literal (the policy makes it 0.15 s).

## 3. What blows the budget (arithmetic)
| Case | Math | Verdict |
|---|---|---|
| Default word Turn | 190 + 38 x 5 + 440 = 820 ms at N = 6 | 360 ms over Rotate. Not Rotate, but it is the default, and on Settings the row being previewed sits on the page being turned |
| Rotate arrival built on the house spring | 0.42 s duration + tail, about 420 ms | 160 ms over the ruled 260. Rotate needs the fixed `pageTurn` curve, not a spring |
| Rotate staggered with `Theme.Motion.stagger` | 80 + 35 x 5 + 260 = 515 ms | 55 ms over |
| Rotate staggered with the Settings arrival's 40 ms | 80 + 40 x 5 + 260 = 540 ms | 80 ms over |
| Out then in, one after the other (no overlap) | 160 + 120 + 260 + 120 = 660 ms *(inferred)* | 200 ms over. The spec's 80 ms overlap is what holds 460 |
| Look change at 700 ms during a turn | outlasts the turn by 240 ms *(inferred)* | no ruling gives a Look change a budget |

Overlap check on the ruled numbers: the last of six rows leaves at 24 x 5 = 120 ms and finishes at 280 ms; its arrival starts at 200 ms, 80 ms before the leave ends. The first arrival (80 ms) starts before the first leave (160 ms) ends. That overlap is the design, not a bug.

## 4. Reduce Motion and Low Power
| | Ruled | Today |
|---|---|---|
| Reduce Motion | every page-turn word is one 150 ms crossfade, no stagger, blur or travel (R3; `tess-page-turn-motion.md:3`) | works: `MotionPolicy` turns every animation into a 0.15 s `easeOut` (`MotionPolicy.swift:6,10-14`). Look change is 150 ms in effect |
| Low Power | the same as Reduce Motion (R3) | **not read** by `MotionPolicy`; only `TessSoul.swift:109` reads it. Look, Settings and entrances run full motion at Low Power |

The Low Power gap is the one real defect: until `MotionPolicy` reads it (through `App/PowerState.swift`, the one allowed reader), a Rotate turn built today would run in full at Low Power. This is Builder A's flag PR already boarded; nothing new is asked, only that Settings does not ship before it.

## 5. Lab defaults for the numbers nobody ruled
All marked *(lab default)*; Product confirms or changes in §6.
1. **The 460 ms is the ceiling for the Rotate turn only.** Row motion elsewhere on Settings gets its own ceiling: **260 ms, no spring tail** (the same as a Rotate arrival), so no row on a page ever takes longer than a row arriving in a turn.
2. **One stagger on Settings: 24 ms** (`Theme.Motion.rotateStagger`, new), for both the page turn and the arrival rows. Review's 35 ms entrance stagger stays on Review.
3. **Settings arrival rows:** 10 pt rise, 24 ms apart, 260 ms each, `pageTurn` curve (replaces the 40 ms in `tess-settings-motion.md:14`).
4. **Page-turn row opening its four words:** 260 ms (was 320 ms).
5. **Stepper and picker step:** the number or word crossfades in 120 ms, no travel; a held vertical swipe steps at the drum cap of 25 ticks a second (40 ms floor).
6. **Look swatch on the Settings Looks page:** the ground floods in **250 ms** (`settings-place.md:26`); Reduce Motion and Low Power 150 ms. **Review's Look sentence keeps 700 ms**: it is a moment of its own, not a row turn. No Look change plays during a page turn; the second waits until the turn ends.
7. **Month stroke:** 500 ms stays; it is a draw once, not row motion.
8. **Default word Turn at 820 ms** is accepted for Pages without a previewed setting; on the Page-turn row itself, each word previews once at its own timing (R4, no replay on re-pick).

## 6. Asks
1. **Product:** is 160 / 260 / 24 (at most 460 ms) the ceiling for the Rotate turn only (lab default), or for all Look and Settings motion?
2. **Product:** confirm §5 items 2 to 6 (one 24 ms stagger on Settings, 260 ms row ceiling, 120 ms step crossfade, 250 ms Looks flood, Look change waits for the turn).
3. **Product:** log 160 / 260 / 24 in `decisions.md` next to line 917; today the numbers live only in a lab sheet.
4. **Design:** sheet 90's Rotate line (`pages-90.md:21`, 480 ms / 34 ms) is superseded; fix it.
5. **Builder A (when Settings is built):** `Theme.Motion.pageTurn` and `rotateStagger` tokens; fix the `Editorial.swift:57` comment (25 vs 35 ms); drop the dead 0.25 s literal at `LookSentence.swift:119`; `MotionPolicy` reads Low Power before Settings ships.

## 7. Tests
1. A six-row Rotate turn measures 460 ms +/- one frame; a three-row turn 388 ms; never padded.
2. Under Reduce Motion and under Low Power every word is one 150 ms crossfade with no stagger.
3. No Settings row motion outlasts 260 ms (the Claude, Rest day and page-turn-row springs are replaced or capped).
4. With Haptics on, a user page turn plays nothing (R2).
5. A Look change tapped mid-turn starts when the turn ends.
