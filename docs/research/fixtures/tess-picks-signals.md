# Fixture: signal rows for Tess's picks, ideas 1 to 4 (Product board item I)

**For:** Builder A (the look, PRs 18a and 18b), Core (events), QA. **Owner:** Research lab. **Date:** Oct 16, 2026.
Read at origin/master, traced by hand, nothing run. Sources: `docs/design/motion/tess-picks.md` (TP) 18a, 18b, 18c, §20;
`tess-motion.md` (TM) §6, §13, §14; `docs/ai/soul-signals.md` (SS); `decisions.md` 9:58 AM and AQ6;
`fixtures/soul-ask-claude.md` (SAC, working tree); `Features/Tess/SoulRouter.swift` (SR). Days come from the synthetic
year (`fixtures/year-of-data.md` §3: PPL Mon to Sat at 7:15 am or 6 pm, Sunday rest, about 4 tasks a day, 2 shops and
3.5 cooks a week). Times are Pacific. Titles are placeholders.

**Rules every row obeys.** Ideas reuse inferences the app already makes (no model call to decide a move). One haptic per
moment: only idea 3 has one of hers; the done row keeps its own `.done` tick. The mouth never frowns at him and dips
(−0.35, 1.2 s) only for her own `claudeFailed`. Flow is SoulEvent → `SoulRouter.handle` → state; no view sets a mode.
Area signals come from Core's pure `HomeFact` diff, at most one event per change (SS §1). "Eyes" means "Tess has eyes",
default off; with it off there is no face and no mouth.

## Idea 1: lights that follow the page (`askClaude(kind, touched:)`)

| # | Moment | Trigger | Expected look | Master today |
|---|---|---|---|---|
| 1.1 | Mon Oct 12, 7:40 am, Home, he pulls Plan my day | `askClaude(.plan, touched: [Push A, 12:15 pm, Call the bank])` | working; readers hop 340 ms, dwell 380 ms on those three words in that order, loop until done; dock lights drift on seeded noise | not built: `PlanWording.swift:432` has no caller; `SoulEvent.askClaude` has no payload (SR:22) |
| 1.2 | Same ask, 7:43 am, Claude times out | `claudeFailed` | readers stop, lights gather 820 ms, she rests; eyes on: mouth −0.35 for 1.2 s; line "Claude didn't answer in time. Here's your usual plan." | gather built (SR:91, SR:192); no mouth; no plan emitter |
| 1.3 | Sat May 23, 5:40 pm, Kitchen, a recipe link the card and text both miss | `askClaude(.recipeLink, touched: [8 ingredient lines, 6 steps])` | readers visit the draft's lines in page order, skipping lines off screen | not built (SAC A5, `RecipeLinkReader.swift:347` latent) |
| 1.4 | Mon Oct 12, 8:10 am, Review opens the week story | `askClaude(.weekStory, touched: [the week's handles])` | readers on Review's lines in line order | not built (SAC A8) |
| 1.5 | Thu Oct 15, 9:05 pm, a capture miss goes to Claude | `askClaude(.capture, touched: [])` | fewer than two words on screen: TM §5 sweep fallback, no hops | not built: capture sends only `.sent` (`BottomChrome.swift:478`) |
| 1.6 | Thu Oct 15, 12:30 pm, key Test in Settings | `askClaude(.keyCheck, touched: [])` | fallback sweep; Done on works | built, bare event: `ClaudeSection.swift:332`, `:338`; router gives working on Home (SR:133) |
| 1.N1 | Reduce Motion on, 1.1 | same event | TM §13 crossfade to the working grade, no readers, no noise | working look not built |
| 1.N2 | Low Power on, 1.1 | same event | six lights held still, no readers, 30 fps | no Low Power path in the router; `TessSoul.swift:83` reads the flag only |
| 1.N3 | Eyes off (default), 1.1 | same event | unchanged: idea 1 has no eye part; only the 1.2 mouth dip goes | n/a |
| 1.N4 | Tue Oct 13, 6:20 pm, live workout, "swap to dips" misses | `.liveAsk` on the `.live` router | corner thinks; no readers, no split, nothing on Home | `WorkoutModeView.swift:276`; SR:130 keeps live at thinking |
| 1.N5 | Thu Oct 15, 11:40 pm, Home lines would reword in the background | none | nothing: he isn't waiting, and it is quiet hours (SAC ★ default) | not built |

## Idea 2: she wakes with you (`firstOpenOfDay`)

| # | Moment | Trigger | Expected look | Master today |
|---|---|---|---|---|
| 2.1 | Mon Oct 12, 7:05 am, first open, eyes on | `firstOpenOfDay` | lids at 0.25 for 1.0 s, open over 400 ms; stretch at 1.5 s (22% wider, 2% shorter, 600 + 700 ms); blink at 3.4 s; mouth at rest | not built: `.foregrounded` exists (SR:32, SR:93) but nothing emits it; `TesseraApp.swift:80` never calls the soul |
| 2.2 | Same, eyes off | `firstOpenOfDay` | the stretch only | not built |
| 2.3 | Sun Oct 11 (rest day), 9:30 am, first open | `firstOpenOfDay` | full wake; a rest day changes nothing | not built |
| 2.4 | Mon Oct 12, 12:10 pm, second open | `foregrounded` | nothing: one wake per day | not built |
| 2.5 | Wed Sep 30, 7:15 am, first open lands in the live workout (Lock Screen) | `firstOpenOfDay`, skipped | nothing; the day counts as woken, so the 12 pm open is plain too | not built |
| 2.N1 | Thu Oct 15, 6:40 am, first open (quiet hours) | none | idea 5's sleep wake, not idea 2; the 7:20 am open is the wake | not built; rest ends at 06:00 on master (SR:72), sheet wants 07:00 |
| 2.N2 | Reduce Motion or Low Power, 2.1 | `firstOpenOfDay` | no stretch; eyes open by 200 ms crossfade (eyes off: nothing) | not built |
| 2.N3 | First open via a notification's speak action, or with an ask waiting | skipped | his moment wins; no wake, day counts as woken | not built |

## Idea 3: stroke her (band pan across her)

| # | Moment | Trigger | Expected look | Master today |
|---|---|---|---|---|
| 3.1 | Mon Oct 12, 8:30 am, Home idle, pan x 280 → 392 at y 779 in 350 ms | stroke | one `.soulStroke` tick on entry; ripple 1.6 s; eyes along (1, 0); blink 50 ms after lift; mouth +0.5 for 900 ms | not built: no gesture in `BottomChrome`; no `.soulStroke` in `Haptics.swift:7` |
| 3.2 | Same, a second stroke 1.0 s later | stroke | ripple restarts, no second tick | not built |
| 3.3 | Sat May 23, 6:05 pm, recipe page, band pan x 380 → 270 across her | stroke | as 3.1; sheet 69's peek does not open | not built |
| 3.4 | Same, eyes off | stroke | ripple and tick, no blink or mouth | not built |
| 3.5 | Reduce Motion on | stroke | no ripple; one blink (eyes on) and the tick | not built |
| 3.6 | Low Power on | stroke | ripple at 30 fps, tick | not built |
| 3.N1 | Pan that starts on her | drag or hold | not a stroke, no tick (TM §4) | drag and hold as built |
| 3.N2 | Mon Oct 12, 7:41 am, during 1.1 (working), or an ask waiting | none | refused; the pan goes to what is under it | `isAskWaiting` SR:52, `isWorking` SR:187 exist; no stroke |
| 3.N3 | Tue Oct 13, 6:25 pm, live workout corner | none | not a stroke target | n/a |

## Idea 4: she wears the day (`taskDone`, `thingFinished`, counted)

| # | Moment | Trigger | Expected look | Master today |
|---|---|---|---|---|
| 4.1 | Mon Oct 12, 8:15 am, "Call the bank" ticked | `taskDone` (task fact leaves Home done) | beat at 520 ms with +0.25 that dries; day level +0.10; row keeps its own `.done` tick, Tess adds none | not built: no `SoulSignals` diff; facts at `HomeLines.swift:6`, `:476` |
| 4.2 | Mon Oct 12, 7:15 am to 8:05 am, Push A finished (6 pm on 35% of days) | `workoutGathered` on `.live`, `thingFinished` counted | Done as built in the corner; +0.10 (now +0.20 after 4.1) | Done built (`WorkoutModeView.swift:102`); no count |
| 4.3 | Tue Oct 13, 6:30 pm, cook mode, step 3 → 4 | `taskDone` (`step` +1) | +0.10 shown on `.live` too (paint, not motion) | not built |
| 4.4 | Thu Oct 15, 7:50 pm, 5th done (grocery row) | `taskDone` | beat plays; level stays at +0.40 cap | not built |
| 4.5 | Fri Oct 16, 4:00 am | day boundary | back to +0.00 over the first idle minute, never a step | not built |
| 4.6 | Thu Oct 15, 7:15 am, a best on Bench inside Push A | `newBest` (not `taskDone`) | thinking 1.2 s then Done; no extra count until the workout finishes | built: `WorkoutModeView.swift:202`, SR:140 |
| 4.7 | Wed Sep 30, 7:30 am, Siri ticks two tasks; he opens at 8 am | `doneElsewhere` | +0.20, one beat at foreground | not built |
| 4.N1 | Mon Oct 12, 8:16 am, UNDO on 4.1 within its window | none | +0.00; mouth stays (never a frown at him) | not built |
| 4.N2 | Tue Oct 13, 6:10 pm, a set logged | `setLogged` | Done as built; no count (a set is not a part ticked, SS §2) | `WorkoutModeView.swift:202` |
| 4.N3 | Tue Oct 13, 6:45 pm, kitchen timer ends | none for Tess | his `.timeUp` only; no count, no beat | Haptic `.timeUp` built |
| 4.N4 | Mon Mar 2 (sick week), a missed workout, a missed habit | none | nothing; she never reacts to stopping | n/a |
| 4.N5 | Reduce Motion, Low Power, eyes off | `taskDone` | level still rises (color, not motion); swell under Low Power keeps TM §13 timing | not built |

## Gaps

| # | Gap | Default proposed | Owner |
|---|---|---|---|
| G1 | `SoulEvent` lacks `askClaude(kind, touched:)`, `firstOpenOfDay`, `taskDone`, `thingFinished`, `doneElsewhere` | add per SS §4 step 2, route in SR's one switch | Builder A (look), Core (emit) |
| G2 | No `SoulSignals.events(from:to:op:)` diff, so ideas 4 and 4.7 have no source | Core's pure diff, one event per change, tagged ops skipped | Core |
| G3 | No `foregrounded` emitter and no per-day "woke on" in the router | emit from `TesseraApp`'s scenePhase `.active`; router keeps the day | Builder A |
| G4 | Rest ends at 06:00 (SR:72); picks want 07:00 | move with 18d | Core, Builder A |
| G5 | `claudeFailed` can't say whose miss (SAC G4) | `claudeFailed(mine:)`; mouth dips only when mine | Core, Builder A |
| G6 | No `.soulStroke` haptic; band has no stroke recogniser | add case at `.impact(flexibility: .soft, intensity: 0.3)` | Builder A |
| G7 | Idea 4 in quiet hours: TP is silent (a done at 11:40 pm) | count it, no wet +0.25 swell while resting | Builder A |
| G8 | Idea 3 while asleep (idea 5): TP doesn't refuse it | answer his touch like CL9 (ripple, tick), then sleep again | Builder A |

★ **Builder A / Product:** idea 2's trigger and test use the 04:00 boundary (a wake at 4:01 am), but idea 5 says the
wake waits for the first open outside quiet hours (7:00 am). Which wins? Default proposed: 7:00 am, and the 04:01 test
becomes 06:59 (no wake) and 07:01 (one wake).

**Ruled (Product, decisions.md 12:13 PM PT):** idea 2's wake is the first open at or after 7 am. G7 and G8 stand as defaults unless the motion lab objects. Gaps are on Core 0f and Builder A 0c.
