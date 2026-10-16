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
| Repaint beside working | `TessSoul.repaint(to:)` folds its swell into the fade when work starts | A |

## Values
`tess-motion.md` sections 1 to 5 and its timing table are the values; Design 51's fixes are already in them. In short: eyes 3.2 × 3.5 pt, 8.4 apart, dark pigment 82%, blink 160 ms every 3 to 8 s; working fade 500 ms to saturation 0.62, split 900 ms into twelve lights at 0.55 (readers 0.42, cobalt child stays within 8 pt of the dock), gather 820 ms, colour back over 550 ms, then Done as built; drag pick-up at 10 pt (soft 0.5), 44 pt above the finger, lag capped 14 pt, drop on the house spring (`.selection`), two docks; roam on the `SoulTravel` arc 760 ms, rows stay 100%, Done in place only with an 80 × 80 clear.

## Frame and battery budget
- 60 fps on iPhone 17 with the page scrolling under her; one `Canvas` in a `drawingGroup`; never more than 14 blurred layers a frame, blur capped at 9.
- Readers draw in their own 393 × 60 canvas that moves with them; the main canvas stays 240 × 240.
- Idle and resting at 30 fps as built; working at 60, dropping to 30 after 20 s; everything paused off screen and in the background.
- Measure: Instruments Core Animation FPS on the device during `work` with Home scrolling; CPU under 12% on one core while working; no frame over 4 ms. If over: drop the six children first, then the readers' trail.

## Reduce Motion
As `tess-motion.md`: nothing travels; 200 ms crossfades; eyes still; haptics stay.

## Tests (TesseraTests)
- Eyes: blink cadence stays in 3 to 8 s over 1000 samples; a double happens about one in five; eyes hidden during `.done` and back after 1.8 s + 200 ms.
- Working: at t = 0.5 s the look's saturation is 0.62 ± 0.02; every light's distance from its dab is under 1 pt at gather + 820 ms; with `reading: nil` no reader leaves the constellation; the mode blend into `.done` starts only after gather + 820 ms.
- Drag: a press that moves under 10 pt and lasts 400 ms still starts the listener; one that moves 10 pt before 400 ms cancels the hold timer and starts a drag; a tap still opens; a double tap within 260 ms still goes Home; drop picks the nearest dock; a flick over 600 pt/s projects 0.18 s ahead; the dock persists per page.
- Roam: she never goes where the free-ground rect is under 56 × 44; a row scrolled past y 130 releases her within one frame; no roam while `onWorkoutGround`; Done plays at home when the 80 × 80 clear fails.
- Drag: only two docks; a bottom-left drop moves the line, lens, ask words and UNDO to x 96 in one step and the band stays 736 to 820.
- Haptics: exactly one per pick-up and one per drop; none for split, gather, roam or eyes; working done plays only Done's `.success`.
- Repaint: a repaint in flight when `.working` begins dries within 500 ms; no repaint starts while working, roaming, carried or in Done.

## Recording for QA
The nine `recordings/tess-motion-*.mp4` clips are the reference; QA records the same scenes on the simulator (`-demoTime 07:42 -theme obsidian`) and Design compares beat for beat.
