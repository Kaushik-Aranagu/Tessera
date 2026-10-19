# Apple Watch: one-screen set logging with the crown (motion and feel)

DRAFT for Builder A and Design. Docs only. Huddle plan batch 9, behind the Settings switch "Watch (off)" (from the task brief; no repo doc names that switch yet). Order of work: sleep and resting heart rate first (reads only, no Watch app), set logging after. Anything not copied from a doc is marked (lab default).

Cite keys (`KEY:line`, docs/ paths): AW research/apple-watch.md; HK research/healthkit-reads.md; WK product/workouts.md; DEC product/decisions.md; K84 product/kitchen-cook-mode-accessibility-acceptance.md; TRN design/motion/tess-training-motion-lowpower-pass.md; RST design/motion/tess-rest-end-alert-and-closing-face.md; LAW design/motion/tess-live-activity-lockscreen-widget-motion.md; CCK design/motion/tess-cook-clock-lowpower-and-timer-end.md; HMT design/motion/tess-haptics-migration-table.md; MAT design/motion/tess-lowpower-reducemotion-matrix.md; AUD design/motion/tess-haptics-sheet-audit.md; WL research/fixtures/gap-hunt-26-widgets-live-activities.md; PVT design/motion/tess-picks.md.

## 0. Status and gates

- The app has no Watch target. `CLAUDE.md:14` says "iPhone only (no iPad, Mac or watch targets)"; `DEC:872` says "no Watch app yet"; `WK:121` lists Apple Watch logging under "Out of v1"; `AUD:37` calls the Watch rest end and Done/UNDO an "intended gap". This sheet is a planned stretch, not a build order.
- Gate before any of it (AW:68): one throwaway build that proves free-team install, HealthKit on the Watch target and the weekly re-sign are tolerable (AW:44-50: 7-day profiles, about 10 App IDs per 7 days, a Watch app and a Watch widget extension add two App IDs).
- First, with no Watch app: sleep and resting HR (`DEC:835`; HK:18-19), then W1 and W2 (`DEC:872`; AW:61-66). The Smart Stack rest activity with a `.small` family and a rest-end notification (AW:32-33) is the wrist surface until a Watch app exists.
- The switch "Watch (off)": off means no pairing prompt, no Watch-only copy anywhere in the phone app, no extra install work. On means the Watch app may open (lab default).

## 1. What the screen is (no cards, no diffused Tess)

One screen, no scrolling (WK:38). The current set sits at eye level, large: weight and reps as two numerals, the exercise name as one small line above (masked, section 6). Done sets are one thin stamped line above, upcoming one ghosted line below (WK:40). No card, no pill, no list rows, no soul or Tess glow: Tess speaks only as one plain cobalt line in the strip under the numerals (PVT:10-21 keeps her small; cobalt is her voice only, K84:8). Rest uses the same place: the numerals turn into the countdown (TRN:53) and a single horizon line along the lower edge drains (TRN:54).

## 2. Crown (lab default unless cited)

| State | Crown does | Feel |
|---|---|---|
| Set open | turns reps, one detent per rep, last time's reps as a ghost (WK:46; AW:39, 68) | the system's own crown detent is the only buzz; we add none (one haptic per moment, HMT:55; the phone's `.selection` per rep, TRN:32, is replaced by the crown's) |
| Weight | tap the weight numeral; the crown then turns weight on loadable detents for the gym's equipment (WK:46; TRN:30). A tap on reps gives the crown back | same: system detent only; `.plateOnOff` has no Watch version |
| Ends of the range | stops at the end; the numeral takes the system's end-stop | no haptic of ours (phone plays `.bound` once, TRN:31) |
| Rest | one detent up adds 15 s (WK:51: +15 is a drag on the dial, not a button); the "+15" label rises 10 pt over 900 ms (TRN:89) | system detent only |
| Rest, skip | swipe across the countdown; Go shows 0.9 s, the horizon leaves (TRN:88) | `.selection` equivalent (section 3) |
| Reduce Motion | the numeral lands in one step, no spring, no neighbours (TRN:30) | same |

Crown never logs. It only changes a number. Logging is always a deliberate touch (section 4).

## 3. Watch haptics, one per moment (all names lab default; feel each on a real Watch and swap names, never moments)

The phone map (`Haptics.swift` cases, HMT:59-60) has no Watch twin yet. watchOS offers `WKInterfaceDevice.current().play(_:)` with `.click`, `.directionUp`, `.directionDown`, `.success`, `.failure`, `.notification`, `.stop`, `.start`, `.retry`; SwiftUI `.sensoryFeedback` on watchOS covers fewer. Verify each with the `sosumi` or `xcode` MCP before building (CLAUDE.md rule). Route all through one `WatchHaptic` map, never a raw call (HMT:4).

| Phone case (cite) | Moment | Watch call |
|---|---|---|
| `.setLogged` rigid (TRN:51) | set seats | `.directionUp` |
| `.newBest` (TRN:62, 68) | a best, instead of `.setLogged`, never both | `.success` |
| `.repsBeatLast` once per set (TRN:32) | reps pass last time | `.click` once |
| `.selection` (TRN:88, 89) | skip, +15 by swipe | `.click` |
| `.undo` (TRN:72) | UNDO | `.directionDown` |
| `.timeUp` heavy (TRN:79) | rest end, seen live | `.notification` |
| `.done` (TRN:104) | finish | `.stop` |
| `.notSaved` (HMT:59) | write did not save | `.failure` |
| rest start, Go flip, closing face, Always-On wake | none (RST:13, 43) | none |

## 4. Moments

| Moment | Normal | Reduce Motion and Low Power (same, D5) | Haptic and sound |
|---|---|---|---|
| Set logged | one tap on the set's numerals. The stroke paints in over 700 ms and the bead lands (TRN:51); the numerals turn to the countdown over 320 ms (TRN:53); the horizon draws over 500 ms (TRN:54); Tess line "Set 3 logged. 80 x 5." holds 4 s with UNDO (TRN:55) | stroke whole, 150 ms fade; countdown 150 ms (TRN:51, 53); horizon 150 ms (TRN:54); the line has no slide (TRN:55) | `.setLogged` row once; no sound |
| Rest begins | countdown on the same place; the horizon drains once a second (TRN:83) | steps once a second (TRN:83) | none; phone schedules the notification (RST:13) |
| +15 | horizon grows, label rises 10 pt over 900 ms (TRN:89); the notification is rescheduled in the same write (RST:14) | label fades in place (TRN:89) | crown detent; none of ours |
| Skip | Go shows 0.9 s, horizon leaves (TRN:88); notification cancelled (RST:15) | fade | `.selection` row |
| Rest end, Watch in front | flips at the second boundary of `restEndsAt` (TRN:93); "Go" rises | "Go" fades in 150 ms (TRN:85) | `.timeUp` row once, no sound |
| Next set | rises to eye level, prefilled, already at the target (WK:51) | 150 ms crossfade (lab default) | none |
| PR | stroke paints in cadmium, same 700 ms (TRN:68); quiet word "beats 5RM" beside the set before it (WK:82); Tess line "New best: 85 x 5." 4 s with UNDO (TRN:70). The light sweep is sheeted and unbuilt (TRN:69): skip it on the Watch. At most one celebration per exercise per session (WK:84) | static cadmium under-stroke for 2 s (TRN:69) | `.newBest` row once, instead of `.setLogged` |
| UNDO (4 s for a new capture, K84:10) | the stroke and line leave together (TRN:72) | fade | `.undo` row once, never with `.selection` (HMT:55) |
| Last set logged | numerals give way to the closing line "<title>, ready to finish", no countdown, no keys (RST:43) | same swap, 150 ms | none |
| Finish | hold 0.8 s fills (TRN:103); cross to the summary over 400 ms ease-out (TRN:104); UNDO 10 s "<title>, back on." (TRN:108). Finish from the wrist is an Ask | fade | `.done` row once, or `.newBest` when the last set was a best (TRN:104) |
| Write cannot reach the phone | the set is kept on the Watch and sent later; a quiet "on watch" word shows until it lands (WK:7 "Nothing is ever lost", lab default) | same word | none; only a write that truly fails plays `.notSaved` row and reads "Didn't save that. Try again." (`product/kitchen-gap-hunt-16-cook-recipe-lowpower-voiceover-oct17.md:75`) |

## 5. Always-On (dimmed) and Low Power

- Always-On drops everything that moves. Rest keeps the word and the time, still "Ready 6:26 pm", no ticking, no horizon, no washes (AW:34; LAW:27, 30). The set at eye level shows its two numerals in dim ink and nothing else. System timers draw seconds for free (`Text(timerInterval:)`, LAW:17); we draw no tick of our own (LAW:18).
- Wrist raise or crown touch back to full: 150 ms crossfade (lab default); no haptic, no glint (TRN:87 plays none on return after T0).
- Watch screens have no continuous timeline of ours: no glint, no breath (lab default; the phone's glint and breath stop in Low Power, TRN:34-35). So Low Power only changes the 150 ms crossfade rule (MAT:3). Watch has its own cached `isReduced`; `PowerState.swift` is phone-only and does not exist yet (MAT:7).
- Reduce Motion: the system flag; every `.tesseraAnimation` equivalent resolves to the 150 ms crossfade (MAT:8, RST:3).

## 6. Private exercise masking

- The exercise name passes the one private-text function before it reaches any Watch surface; a walled name reads "Private exercise" (RST:48; WL:105). The same masked string feeds the VoiceOver label, the button label and anything Siri reads (WL:106).
- The workout title reads "Private workout" on the closing line: "Private workout, ready to finish" (RST:48).
- The rest notification never carries an exercise name: title "Timer", body "Rest is up" (RST:22).
- Complication and Smart Stack faces follow the same function; the Watch app never caches the raw name in its own store (lab default).

## 7. Handoff with the phone's Live Activity (no doubled alert)

One alert path stays: a local notification scheduled by the phone at `restEndsAt`; the Live Activity carries no alert (RST:9, 26). The Watch mirrors that notification only when the phone is locked (AW:33).

| Case | Who rings | Rule |
|---|---|---|
| Watch app in front, seen live within 2 s | Watch, `.timeUp` row once | the Watch app tells the phone "seen live"; the phone cancels the notification (RST:17). If the cancel is late, the Watch's notification delegate presents nothing while the app is in front (lab default) |
| Phone in front, Watch on the wrist | phone `.timeUp` once (TRN:85) | the Watch app is not in front, so it plays nothing |
| Both in front (rare) | phone only (lab default) | the Watch app yields |
| Phone locked, Watch app away | the mirrored notification, one tap on the wrist | no in-app haptic anywhere (RST:16) |
| Wrist raised after T0 | Go already showing | `.timeUp` only within 2 s of T0, otherwise none (TRN:87) |
| Smart Stack activity | flips to Go by `staleDate`, silent | the activity and the Watch app read the same absolute `restEndsAt`, so they flip together (LAW:18) |
| Notifications off | no ring | the flip is the only signal (RST:18) |
| Quiet hours 23:00 to 07:00 | his own rest rings at any hour (RST:19) | Watch set and rest haptics are his touches and play (TRN:6) |

A set logged on the Watch writes through the phone's op log and moves the same rest countdown and notification as a phone log (RST:14). Set source gets a `watch` value (WK:29 lists hold, dial, lock screen, Tess): an Ask.

## 8. VoiceOver and Dynamic Type

- Set: "<masked exercise>, set 3 of 5, 80 kilograms, 5 reps" with the action "Log set". Rest: value changes only at whole-minute and last-minute boundaries (CCK:29). UNDO label "Undo", held 10 s under VoiceOver (K84:10, K84:57).
- Log receipt announced once, high priority, focus does not move (K84:57 pattern). Rest end: no announcement of ours; the notification reads "Timer, Rest is up" (RST:20).
- Text sizes scale the numerals; the crown still turns the same value at every size (lab default).

## 9. Build checks (camelCase, lab default names)

1. `watchSetLogPlaysExactlyOneHaptic` (`.setLogged` row, or `.newBest` on a best, never both; TRN:113 for the phone).
2. `watchCrownAddsNoSecondHaptic`: turning reps plays only the system detent.
3. `watchRestEndSeenLiveCancelsNotification` and `watchRestEndLateWristRaiseHasNoHaptic` (2 s rule).
4. `watchRestNotificationNotDoubledWithPhone`: one ring across phone, Watch and Smart Stack.
5. `watchPrivateExerciseReadsPrivateExercise` (drawn, spoken and in the notification).
6. `watchAlwaysOnDropsHorizonKeepsWordAndTime`.
7. `watchReducedMotionIsOneCrossfade`; `watchLowPowerStopsNoTimelineBecauseNoneExists`.
8. `watchUndoWithinFourSecondsRestoresSet`; `watchFinishHoldPlaysDoneOnce`.
9. `watchSetKeptWhenPhoneUnreachableIsNotLost`.
10. Grep: no raw `WKInterfaceDevice` `play(` outside the haptic map; no `withAnimation` or `.animation(` in the Watch target outside the policy.

## Asks

- **Builder A (decision, blocks everything):** this needs a new watchOS target (plus, for faces, a Watch widget extension). That contradicts `CLAUDE.md:14` today and spends two more free-team App IDs (AW:49). Run the throwaway build first (AW:68). Also decide: one `WatchHaptic` map file, Watch-side `isReduced`.
- **Product:** does the Watch app finish a workout, or only the phone (TRN:103 is a hold)? Tap or a short hold to log on the wrist (AW:68 says tap; the phone holds 0.7 s, TRN:44)? Is the "Watch (off)" switch the only gate?
- **Core:** add source `watch` to Set (WK:29); queue-and-send for sets made while the phone is out of reach.
- **Design:** confirm the haptic name map (section 3) on a real Watch, and the crown owning +15 during rest (section 2).
