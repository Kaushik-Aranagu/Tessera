# CopyList receipt, Speak, Plan my day and Day log: Low Power and Reduce Motion pass (board item 62)

> VoiceOver rows, the Plan hold rows and the Speak ghost under VoiceOver are superseded by `tess-day-screens-motion-pass.md` (board 70, after Product's 9:56 PM rulings on #961).

For: Builder A (Speak, haptics, soul wiring, flag), Builder B (Home, Plan my day, Lists), Design (Day log values), QA, Product (three rulings, end of sheet). Written Oct 17, PM (Pacific). Read from the code on master (master as of this evening; file:line below) against `speak.md`, `plan-home.md`, `m4-steers.md` section 6, `day-log-page.md`, `day-log-v1.md`, `daylog-82.md`. Static read, nothing run. A first read of the code was done by a read-only helper agent and spot-checked by me (SpeakLayer:49 and 53, BottomChrome:130-132 and 653, HomePlan:307, PantryView:104).

**Rules used.** D5: Low Power (LP) = Reduce Motion (RM) for screens, the soul keeps her own LP form (30 fps, six lights, no readers, full opacity). `isReduced` is the one flag (RM or LP, cached, `NSProcessInfoPowerStateDidChange`; gap hunt 16 G219): none of the three flows reads LP today, so every LP row below is new. The reduced number is the policy's 150 ms. His own touches play their haptics in LP and in quiet hours; Tess's own landings follow quiet hours (9:18 PM Oct 17). One haptic per moment, always through `tesseraFeedback`, never a raw `.sensoryFeedback`.

## A. CopyList receipt (51)
Built from `tess-groceries-finish-copylist-motion.md` item 47 and Design's sheet 102 (as relayed), with the LP column added.

| Moment | Normal | RM and LP | Haptic |
|---|---|---|---|
| Receipt "Packing, Lisbon, new list." (private: "Private list, new list.") | 240 ms fade, 8 pt rise, in the one UNDO slot, 10 s | 150 ms fade, no rise | `.made`, once, his action, plays in quiet hours |
| Tap the receipt: the copy opens | the house list-opening zoom out of the line, 420 ms | 150 ms crossfade (Product: the zoom is a crossfade in LP, G247) | none |
| UNDO ("Lisbon, taken back.") | the copy leaves the shelf with the 320 ms line close-up; if its page is open it closes with the back transition first, then the copy goes | 150 ms fade for both, same order | `.undo`, once |
| No title accent on a list copy; never opens by itself; the original list untouched; no flight between lists | same | same | none |

**Dependency (G250, blocker).** Today Lists draws no Tess line at all, so this receipt and its UNDO cannot be seen; the shared Tess line on every full-screen layer (`tess-groceries-lists-and-home-settings-lowpower.md`) must land first.

## B. Speak
Code facts: hold 400 ms (`BottomChrome:252`), pause 1.2 s, silence 5 s, cap 60 s (`SpeechListener:51-53`) all match `speak.md`. The voice dry is one value, 3.0 s (RM 0.8 s), for every listen (`BottomChrome:653`).

| Moment | Normal (sheet; code where it differs) | RM and LP | Haptic |
|---|---|---|---|
| Soul touch-down | swell 1.06 over 130 ms (`BottomChrome:247`) | no swell | `.selection` once (raw today, `BottomChrome:130`) |
| Hold starts listening (400 ms) | bloom x1.4, breathes with the level to x1.55; level scale animates 120 ms (raw `.animation`, `SpeakLayer:53`, not RM-gated) | RM: still bloom at **x1.2** (sheet; code holds 1.4: fix); LP: the soul's LP form, level smoothed at 30 fps, mic samples consumed at no more than 20 per second (today about 43, `SpeechListener:129-132`) | `.listening` once at the moment listening begins (the map has it, unused). Touch-down `.selection` stays: two moments 400 ms apart |
| Other words fold | 200 ms fade (code: the house spring, ~420 ms: fix to the sheet) | 150 ms crossfade | none |
| Words as heard | each word rises from a 6 pt blur (code: opacity 0.2 s, not RM-gated, `SpeakLayer:49`) | each word fades in, no blur, 150 ms | none |
| Tidying (fillers squeeze, 320 ms; the clean sentence in ink with the destination word) | built nowhere: the filler cut is instant and the ghost is `inkSecondary` with no destination word (`SpeakLayer:19`, `SpeechListener:236`) | crossfade 150 ms | none |
| Ghost dries (cobalt line drains right to left) | 3 s for a voice listen, **2 s for a set in a live workout** (the workout hold flow is not built: no numeral ghost, no 250 ms word fade) | RM: 0.8 s (0.6 s in a workout) as the sheet says. **LP keeps the full window** with the drain drawn in four steps (about 0.75 s each), because LP is about cost and a shorter window is less time to correct a mishearing. One line for Product below | none |
| Commit (everything gathers into the soul, 220 ms; the page comes forward) | spring 0.42/0.9 close, no 220 ms gather (`BottomChrome:518`) | 150 ms crossfade | `.made` once for a capture (today a raw `.success` on every brighten, `BottomChrome:131`: the map says `.success` is Done's); his action |
| UNDO tap | Tess's line "Milk, taken back."-style, 10 s | same | `.undo` once. Today the UNDO word also plays `.selection` (`CaptureParts:141`) and `.decrease` (`BottomChrome:132`): one moment, one haptic, so the word plays only `.undo` |
| Refusal line (mic off etc.) | house spring in; line in cobalt with one ink word that still works | 150 ms fade | none (information; `.notSaved` is for a write that did not save) |
| Cancel (drag left off the soul, or tap the veil) | nothing saved, no line | same | none |

Raw literals to route through the policy (code): `SpeakLayer:49` and `:53`; `BottomChrome:76`, `:87`, `:272`, `:482`, `:654`; the hand-gated ones in `CaptureParts:74-96` and `Paint.swift:296`, `:324`, `:342`, `:350` and `:396` can stay if the flag feeds them.

## C. Plan my day
Code facts: Claude wording is off (`AppModel.planWordingReady = false`, `AppModel.swift:64`), so only the rules plan shows; `HomePlan.swift` never calls `soul.handle(.askClaude)`, so Tess does not work while a plan is requested; the cloud mark with three wisps, the 07:00 pull and row editing are not built. The pieces that exist match the sheet: hold START WITH 0.7 s (the `duration: 0.7` at the call site, `NowPage.swift:192`), the ink dry of a kept row (700 ms spring, time +250 ms, `HomePlan:362-367`), the breathing rows (0.5 to 0.66, `HomePlan:342`), skip plan silent.

| Moment | Normal | RM and LP | Haptic |
|---|---|---|---|
| Plan offered | rules plan drawn at once, entrance on first visit (`NowPage:33-45`); silent on purpose (plan-home) | opacity only 150 ms | none |
| Rows breathing | one `TimelineView` per row at 30 fps, up to five (`HomePlan:307`) | still at the Reduce Motion value (0.6, `HomePlan.swift:342`): LP gets the RM value the code already uses; normal power: one shared timeline for all rows, not five | none |
| Keep a row (swipe right, past 120 pt) | row dries to ink: title 700 ms spring, time +250 ms | one 150 ms ink fade, no stagger | `.made` once (the map documents it for "a plan is kept", `Haptics.swift:8`; not called today) |
| Skip a row (swipe left) | row slides off, queue closes up 320 ms (code: 250 + 420 ms: align) | 150 ms fade | none |
| Skip the plan (swipe the hero left) | house spring; silent | 150 ms fade | none |
| Hold START WITH (keep the plan), 0.7 s | line empties to a 0.9 pt trace at 35%, repaints left to right with a bead; hero lifts away (-24 pt, blur, 320 ms) and the first item rises into the hero (480 ms house) | fill without thickening, no bead, hero and first item crossfade 150 ms | one `.made` on completion however many rows it keeps (ruled 9:58 PM Oct 17); the press-begin tick and the raw medium 0.8 go (migration table rows 22 and 23); the hold keeps only the visible rows (see `tess-day-screens-motion-pass.md`) |
| Claude call out | **not wired.** Spec: Tess enters the working state when the request starts (`soul.handle(.askClaude)`), gathers when it lands (tess-motion section 5); three wisps rise off her, VoiceOver "Sent to Claude" | RM: no wisps; she works by position and size at full opacity (item 57). LP: the soul's LP form (six lights, 30 fps) and no wisps | none |
| Reply lands (words from Claude) | titles slide to place on the settle spring 520 ms, key words crossfade (blur 4 to 0, 420 ms), VIA CLAUDE fades in | one 150 ms crossfade of titles, words and the line | none (silent by the sheet) |
| Failure ("Claude didn't answer in time. Here's your usual plan.") | Tess's line, 4 s | 150 ms fade | none |
| UNDO after a row keep | code holds 10 s; the sheet says 4 s (`HomeQueue:51`) | same | `.undo` |

## D. Day log (screen not built; spec for the build, LP and RM added)
Day log has no screen on master (only Core: `DayStory`, `OpZones`, `WeekFacts`; and Review's week lines). Values below are the sheets'; the reduced column is the new part. Quiet hours: nothing here is a Tess landing, so no haptic changes; haptics are only the two the sheet allows.

| Moment | Normal (`day-log-page.md`, `day-log-v1.md`, `daylog-82.md`) | RM and LP | Haptic |
|---|---|---|---|
| Enter from the Review word | hairline draws under the word 150 ms; Review lifts (x1.06, blur 3, fade, 380 ms); the log grows from the word (0.94 to 1, 420 ms) | hairline stays; 150 ms crossfade between the pages, no zoom | `.selection` once |
| Lines arrive (open on today at the bottom) | rise 10 pt, 40 ms apart, 360 ms each | 150 ms fade together, no rise, no stagger | none |
| Month title swap, running numbers | blur crossfade 220 ms | 150 ms crossfade, no blur | none |
| Tap a line | hairline 150 ms; object page reveals from the row 440 ms house | 150 ms crossfade | `.selection` once |
| Margin scrub (left 80 pt) | lines dim to 30% in 200 ms, a numeral (80 Light) beside the finger, release settles 320 ms, numeral fades 220 ms | dim and release are 150 ms crossfades; the numeral appears without travel | `.selection` per day passed, `.impact(.light)` per week boundary; ticks capped at 25 per second with the landing tick always played (the drum rule) |
| Live record (a new line at the bottom) | inks in: rise 10 pt, 360 ms, 3 pt blur clearing on the first entry of a day | 150 ms fade | none |
| Tess writes a line | 2.8 s cobalt wash behind the text, dries to its tier | no wash: the text crossfades to its tier colour in 150 ms | none |
| Taken back elsewhere | line fades 220 ms, returns on redo | 150 ms | none |
| 04:00 turnover | nothing moves; the label crossfades TODAY to WED 21 (220 ms, ink to inkSecondary), 260 ms later the new TODAY | the same labels at 150 ms, no blur | none |
| First day | quiet line fades 220 ms; first entry rises | 150 ms crossfade | none |
| THE DAY side | glance and full side; RM 150 ms crossfade | same | the side's own `.selection` |

Note: RM sheets give 220 ms for the turnover and blur swaps; under the policy every reduced form is 150 ms, which is what this table uses.

## E. What goes to Builder A and Builder B
1. One `isReduced` flag, read by every row above (G219). 2. Replace raw `.sensoryFeedback` in these flows with `tesseraFeedback` and add the quiet-hours gate for Tess-origin haptics (origin on `Haptic`, G249). 3. Wire Plan my day to the soul (`.askClaude` on request, gather on result). 4. Fix the Speak gaps: workout dry 2 s and 0.6 s, tidying, 200 ms fold, RM bloom 1.2, 220 ms gather. 5. One shared timeline for the plan rows. Tests: `speakCommitPlaysMadeNotSuccess`, `undoWordPlaysOneHaptic`, `micSamplesAtMostTwentyPerSecondInLowPower`, `planRowsShareOneTimeline`, `planKeepPlaysMadeOnce`, `lowPowerKeepsTheDryWindow`, `listeningStartPlaysListeningHaptic`, `dayLogScrubTicksCapped`.

## Three rulings for Product (one line each, defaults stand if you say nothing)
1. **Speak dry window in Low Power:** keep the full 3 s (stepped drain) instead of the RM 0.8 s? Lab default: yes.
2. **Capture commit haptic:** `.made` (the map's word for something landing) instead of today's `.success`? Lab default: yes.
3. **Plan row-keep UNDO:** 10 s (a change, as coded) instead of the sheet's 4 s? Lab default: 10 s.
