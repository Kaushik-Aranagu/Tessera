# Tess in motion: the build sheet (Builder A)

The one sheet Builder A builds from. Design reviewed `tess-motion.md` (item 51, pass with fixes, all folded into that sheet), so the values there are final; Design's next look is at Builder A's own recording. Builder A builds motion after Design 44, 42 and 43.

## Order
1. Eyes, as a setting. Smallest change, his first ask.
2. Working (fade, split, process, gather). The one he described most.
3. Drag with docks. Touches `BottomChrome`'s gesture, so it needs the gesture tests.
4. Roam. Needs each page to say its free ground, so it comes last and page by page (Home first).

## Where the code goes
| Piece | File | Owner |
|---|---|---|
| Eyes: draw, blink, glance; `TessSoul.eyes: Bool` | `Features/Tess/TessSoul.swift` (drawn after the canvas, normal blend, `ink` on light looks and `ground` on dark ones) | A |
| "Tess has eyes" line | Settings › Tess (`SettingsStore`, key `tess.eyes`, default no) | B writes the line, A reads it |
| Working: `Mode.working(reading: [CGRect]?)`; the twelve lights, fade, split, gather | `SoulParameters.swift` (a `working` row), `SoulFrame.swift` (six children, the constellation, readers), `TessSoul.swift` (the readers' canvas) | A |
| Which asks are `working` vs `thinking` | the router: Claude, Plan my day, link fetch, photo read are working; everything local stays thinking | Core |
| Drag: 10 pt pick-up from the hold, carry, two docks, flick, `tess.dock.<page>`; the band's line, lens, ask words and UNDO shift to x 96 on a bottom-left drop | `Features/Command/BottomChrome.swift` (`soulKey` gesture), `DesignSystem/Haptics.swift` (`.soulPickUp`, `.soulDrop`) | B (gesture), A (soul) |
| Roam: `TessSoul.place`, free-ground rects per page, ride-and-release on scroll, the 80 × 80 clear test before Done in place | `SoulTravel` as built; each page's view reports free ground through a preference | A (Home, Training), B (Home rows, Kitchen) |
| Reward beat: a 940 ms overlay (gather, brighten, blink) on the current mode, started by `.tesseraFeedback(.done)`'s moment at 520 ms (at 0 when the fleck leaves the soul) | `TessSoul.swift` (`beat()`), called from QueueRow / hero / habits / Groceries (B) and the workout finish (A) | A, with B's call sites |
| Repaint (`living-colours.md`, item 7 in `tess-motion.md`): per-dab pool (new wash radius 0 → edge, old wash opacity 1 → 0, 900 ms, cool/warm/bright 120 ms apart), wet swell 1.12 and alpha lift 0.2 (core and mid on light looks, mid only on dark), dry by 2.8 s; folds into the working fade when work starts | `TessSoul.repaint(to:)`, `SoulPalette.look(_:living:)`, `SoulRenderer.dab` draws two washes while a pool runs | A |
| Outside the app (section 9): nothing of the soul in the widget extension or the Live Activity; on a return from a face she is at her dock at rest and gives the return line one glance (no beat, no haptic); if work is still running when the app opens she is drawn mid-constellation with no split-in | `TessSoul.swift` (the glance on a return line; `Mode.working` entered without the split when the app becomes active mid-work); the extension's target membership (no `Features/Tess/` file); nothing of `SoulPalette` in the App Group | A, with B's return-line call |
| Recut looks (section 11): nothing to build for the dabs, `SoulPalette.look` already reads the recut tokens and its pale rule now covers Plein; a look switch cancels a repaint in flight and holds the eyes and the mode for the flood's 700 ms; no repaint until the flood has dried | `TessSoul.swift` (`repaint(to:)` cancelled by `ThemeStore` changes; eyes hold during `PaintFlood`) | A |
| Low Power (section 13): a cached `lowPower` flag from `ProcessInfo` + `NSProcessInfoPowerStateDidChange`; tick 30 fps in every mode (DEC:1069 item 3; the older 20 fps idle is superseded); six lights, no readers, halo breath held; no roam, no repaint; applied at the next mode change | `TessSoul.swift` (`minimumInterval` from the flag; `SoulFrame` children skipped; readers' canvas not created), `TessSoul.place` refuses roam, `repaint(to:)` defers; `LaunchFlags` `-lowPower` for the simulator | A |
| The event contract (section 14): `SoulEvent`, `SoulRouter.handle(_:)`, `SoulState` (mode + beat / roam / carried / repaint overlays); every `tessMode =` outside the router goes; the workout's `play` becomes events on the same router with `page = .live`; all timers in the router | new `Features/Tess/SoulRouter.swift`; `AppModel.tessMode` becomes `soul: SoulState` written only by the router; `BottomChrome`, `RootView`, `ClaudeSection`, `WorkoutModeView` emit events | A (router, soul), B (the chrome's and pages' emitters), Core (which asks are `working`) |
| The glass lens (section 15): `lensHeld` sends readers and a roam home, pins her to the dock, refuses a second touch; `lensReleased` releases a queued roam after the 480 ms grow; the lens is refused while listening, an ask waits or she is carried | `HomeSpatialView` (`holdLens` / `releaseLens` emit; `held` guard on listening / ask / carried), the router | A |

## Values
`tess-motion.md` sections 1 to 5 and its timing table are the values; Design 51's fixes are already in them. In short: eyes 3.2 × 3.5 pt, 8.4 apart, dark pigment 82%, blink 160 ms every 3 to 8 s; working fade 500 ms to saturation 0.62, split 900 ms into twelve lights at 0.55 (readers 0.42, cobalt child stays within 8 pt of the dock), gather 820 ms, colour back over 550 ms, then Done as built; drag pick-up at 10 pt (soft 0.5), 44 pt above the finger, lag capped 14 pt, drop on the house spring (`.selection`), two docks; roam on the `SoulTravel` arc 760 ms, rows stay 100%, Done in place only with an 80 × 80 clear.

## Two rules every page follows (Design 58)
- **A page declares its free ground.** Each page reports its rects through a preference; a page that reports none gets no roam and no readers, only the constellation at the dock. That is the safe default for every page not in `tess-motion.md`'s table.
- **Live things own their surface.** A live workout, cook mode, the Speak layer and a flight from `task-reward.md`: she stays put and does only what she does today.

## Frame and battery budget
- 60 fps on iPhone 17 with the page scrolling under her; one `Canvas` in a `drawingGroup`; never more than 14 blurred layers a frame, blur capped at 9.
- Readers draw in their own 393 × 60 canvas that moves with them; the main canvas stays 240 × 240.
- Idle and resting at 30 fps as built; working at 60, dropping to 30 after 20 s; everything paused off screen and in the background.
- Measure: Instruments Core Animation FPS on the device during `work` with Home scrolling; CPU under 12% on one core while working; no frame over 4 ms. If over: drop the six children first, then the readers' trail.

## Reduce Motion
As `tess-motion.md`: nothing travels; 200 ms crossfades; eyes still; haptics stay.

## Acceptance for the PR (Design, 14-15 pass)
The one-wire rules of `tess-motion.md` section 14 are the PR's gate, checked by grep before anything is recorded:
- `rg "tessMode\s*=" --type swift` outside `Features/Tess/SoulRouter.swift` returns nothing (views emit events; they never set a mode).
- `rg "Task.sleep" Features/Tess Features/Command/BottomChrome.swift Features/Workout/WorkoutModeView.swift` finds soul timers only in the router (the 1.8 s one-shot, `say`'s 4 s, the beat's 940 ms, the flood's 900 ms, the drop's dock save).

## Tests (TesseraTests)
- Reduce Motion: the timeline is not paused but ticks at 30 fps for the opacity breath (0.85 to 1, 3.2 s) and the blink; no scale, no travel, no glance.
- Eyes: blink cadence stays in 3 to 8 s over 1000 samples; a double happens about one in five; eyes hidden during `.done` and back after 1.8 s + 200 ms.
- Working: at t = 0.5 s the look's saturation is 0.62 ± 0.02; every light's distance from its dab is under 1 pt at gather + 820 ms; with `reading: nil` no reader leaves the constellation; the mode blend into `.done` starts only after gather + 820 ms.
- Drag: a press that moves under 10 pt and lasts 400 ms still starts the listener; one that moves 10 pt before 400 ms cancels the hold timer and starts a drag; a tap still opens; a double tap within 260 ms still goes Home; drop picks the nearest dock; a flick over 600 pt/s projects 0.18 s ahead; the dock persists per page.
- Roam: she never goes where the free-ground rect is under 56 × 44; a row scrolled past y 130 releases her within one frame; no roam while `onWorkoutGround`; Done plays at home when the 80 × 80 clear fails.
- Drag: only two docks; a bottom-left drop moves the line, lens, ask words and UNDO to x 96 in one step and the band stays 736 to 820.
- Haptics: exactly one per pick-up and one per drop; none for split, gather, roam or eyes; working done plays only Done's `.success`.
- Reward: the beat ends within 940 ms of its start; no haptic from `TessSoul` during it; Done's one-shot never starts from a task's done; in a live workout the beat has no glance.
- Listening and asks: no blink while `listener.state != .idle`; no roam, split or repaint while an ask waits or she listens; the work state after a send starts only after the 220 ms gather; the eyes return from the ask words within 300 ms of the tap or the fold.
- Repaint: pool order is cobalt, vermilion, cadmium 120 ms apart; each dab's pool is complete at start + 900 ms and dry at start + 2.8 s; Done's ring colour is unchanged after a repaint; Reduce Motion crossfades in 600 ms.
- Repaint: a repaint in flight when `.working` begins dries within 500 ms; no repaint starts while working, roaming, carried or in Done.
- The contract: no `tessMode =` outside `SoulRouter` (a source grep in the test); each event in section 14's table maps to its state; the precedence list holds pairwise (his touch cuts Done, a Done during listening becomes a beat on return, a second Done inside 1.8 s is a beat, `rowChanged` during working roams at gather, two beats inside 940 ms merge, `paletteChosen` while anything runs is deferred).
- The lens: `lensHeld` during working brings the readers home within 360 ms and keeps the constellation at the dock; during roam she is home within 760 ms; a lens never forms while carried, listening or an ask waits; her mode, haptics and eyes are unchanged by hold, slide, tick and release.
- Low Power: with the flag on, the working frame has six lights and no readers; the timeline's interval is 1/20 in idle and 1/30 working; `place` returns the dock; no repaint starts; Done's duration and the beat's are unchanged; a flag change during `.working` takes effect only at the next mode change.
- A minute at rest: over 60 s of `.idle` the soul posts no haptic, no line and no mode change; the timeline ticks at 30 fps and `TessSoul.body` is evaluated once; blink count 7 to 15 with gaps 3 to 8 s.
- Recut looks: `SoulPalette.look(.plein)` uses the pale stops (0.58 / 0.42) and halo 0.08 / 0.05; a look switch during a repaint ends the repaint within one frame and no repaint starts for 3.5 s after the switch; no blink while a `PaintFlood` runs.
- Outside the app: a return line from a face (`lockscreen.md`'s UNDO lines) triggers the glance and no beat, no haptic; the app becoming active while `.working` enters the mode at full constellation with no split animation; the widget and Live Activity targets contain no `TessSoul`, `SoulRenderer`, `SoulParameters` or `SoulFrame` source (a build-settings test or a review check); the App Group snapshot carries no living-colour palette.

## Recording for QA
The `recordings/tess-motion-*.mp4` clips are the reference; QA records the same scenes on the simulator (`-demoTime 07:42 -theme obsidian`) and Design compares beat for beat.
