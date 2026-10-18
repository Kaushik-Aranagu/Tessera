# Tess in motion (motion lab, sheet 1, with Design 51's fixes)

Kaushik (11:58 PM PT Oct 15): Tess should have life. Small dot eyes, maybe. She could move around the screen, not just the bottom; be dragged; move on her own while doing something. While working she should fade into very subtle, faded colours and split into lights that process, then come back together. Very subtle, never in the face.

This sheet is the vocabulary: what she may do, where, how fast, and with which haptic. It changes nothing about her form (`tess-soul.md`) and nothing about **Done, which stays exactly as built**. Product's order on `ops/board/motion.md`: eyes and idle, then roam and drag, then working, then the build sheet. This sheet carries all three with values; the build sheet for Builder A follows once Design has reviewed the look.

- Prototype: `motion/prototype/tess-motion.html` (a canvas port of `TessSoul.swift`, `SoulParameters.swift` and `SoulFrame.swift` at the 65% spread from `soul-explore.md`, plus the new states; `node record.mjs <scene> <look>` steps it at exactly 60 fps). Every number below is in the file, so Builder A can read the value next to the motion.
- Recordings (`recordings/tess-motion-*.mp4`, 60 fps, the caption strip under the phone names each beat and its haptic and isn't part of the app):
  - `tess-motion-eyes.mp4` (Obsidian), `tess-motion-eyes-light.mp4` (Porcelain), `tess-motion-eyes-close.mp4` (4× close-up)
  - `tess-motion-roam.mp4`, `tess-motion-roam-light.mp4`
  - `tess-motion-drag.mp4`
  - `tess-motion-work.mp4`, `tess-motion-work-light.mp4`, `tess-motion-work-close.mp4`
  - `tess-motion-think.mp4` (working with nothing to read)
  - `tess-motion-reduce-motion.mp4`

## The rules
1. **She never covers words.** Every place she goes is free ground: the margin after a row's last word, the ask band, the space under the last row. If the only free ground is too small for her (less than 56 × 44 pt), she stays home.
2. **Nothing on a page moves for her.** She fits the page; the page never fits her. The ask band (736 to 820) keeps its fixed height.
3. **Colour arrives through motion.** At rest she is the small idle soul as built. While she works her colour drains; the moment she's done it floods back through Done.
4. **Under a second for every change of state.** Fade 500 ms, split 900 ms, gather 820 ms, pick-up 180 ms, drop on the house spring. Only travel across the page (760 ms, the `SoulTravel` arc) and the work itself take longer, and the work is the thing he's waiting on anyway.
5. **One haptic per moment** (`task-reward.md`). Working has none; the tap when she's done is Done's own `.success`. Pick-up and drop have one each. Eyes and roam have none.
6. **Cobalt stays her voice.** The eyes are ink, the lights are her three pigments, nothing new is coloured.
7. **Done never changes.**

## 1. Eyes (a setting, off by default)
Two ink dots on the soul, so she has somewhere to look from. They are an option in Settings under Tess ("Tess has eyes: no."), off until he turns them on, because a face is a bigger claim than paint and he should choose it.

| | Value (soul scale 1; multiply by the drawn scale, 0.72 × 0.62 at Home idle) |
|---|---|
| Place | On the mean of the three main dabs, 3 pt above it, so they ride the dabs' own idle lift |
| Size | 3.2 × 3.5 pt ovals, 8.4 pt apart (centre to centre) |
| Colour | Always the dark one (Design 51): the look's `ink` on light looks, its `ground` on dark looks (Obsidian `#000000`, Lacquer `#140F1B`), at 82%, normal blend, drawn over the soul. On Obsidian they are two dark pupils in her glow, never glints |
| Blink | Lids close and open over 160 ms (height to 0.25 and back, ease-in-out). One blink every 3 to 8 s, random; one in five is a double (blink, 250 ms, blink) |
| Glance | The pair moves together, up to 3 pt sideways and 2.2 pt up or down, on a short spring (300 ms, bounce 0.05) |
| Where she looks | At her own line when she speaks (down-left for 1 s, then back). Toward a row she just changed or named (up, toward it, until the line leaves). Toward him (up, centred) while listening. Straight ahead otherwise |
| With the modes | Idle, listening, needs you, resting: shown. Thinking and working: shown while she's whole, gone when she splits. **Done: they fade out in 120 ms as it begins and back in 200 ms after it ends**, so Done plays exactly as built |
| Reduce Motion | The blink stays; no glance; the dots sit still |

At Home size they are two pinpricks, there and not there. That is the intent. The one dial is the 82% alpha, never the size.

## 2. Idle life (as built, plus one thing)
Idle stays the calm "needs you" lift (`SoulParameters.idle`): one dab at a time, 9 s period, satellites drifting, drawn at 0.62. The one addition: with eyes on, the glance gives idle a direction, and the lift reads as her looking up. No new idle motion; he already likes her at rest.

## 3. Roam
She goes to the thing she's about to change, works there, and comes home. She never wanders for its own sake: every move has a reason the line names ("Moving Push day to 18:00.").

| Beat | What happens | Time |
|---|---|---|
| Go | She leaves home on the `SoulTravel` arc (x on `0.55, 0, 0.15, 1`, y on `0.3, 0, 0.25, 1`) to the row's free ground: 40 pt after the row's last word, 6 pt above its baseline. The rows stay at 100% (Design 51: her being there plus the line is enough) | 760 ms |
| Work | The working state (section 5), small: the lights orbit within 20 × 12 pt of where she sits, no readers | as long as it takes |
| Done | Done plays in place, exactly as built, only when an 80 × 80 pt clear of words is free around her spot, the rows above and below included. Otherwise she flies home first (760 ms) and Done plays at home, then the line lands (Design 51) | 1.8 s |
| Home | The same arc back | 760 ms |

Where she may go, per page:
- **Home**: after any Next row's words; the space under the last row; the ask band. Never the hero, never the day stroke, never the nav words.
- **Training**: after a set row's reps; under the last set. Never over the weight reel or reps row while a workout is live (no roam in a live workout at all; `LiveTessCorner` keeps its fixed slot).
- **Kitchen / Groceries**: after an aisle row's words.
- **Any page while scrolling**: she rides the row she sits on. When that row's free ground leaves the page (its baseline passes y 130 under the nav, or y 700 above the band), she lets go and flies home on the arc, and doesn't come back until the next reason.
- **Never**: over text, over an ask's two words, over UNDO, in the Speak layer, during a flight from `task-reward.md`.

Roam is one thing in code: `TessSoul` gets a `place` (a point in the page) and goes there through `SoulTravel`, which already exists for the hand-off.

## 4. Drag
He can pick her up and put her where he wants her. It starts from a hold, so the tap (open), the double tap (Home) and the hold (talk) keep working as built (`BottomChrome.soulKey`):

| Beat | What happens | Haptic |
|---|---|---|
| Press | The swell as built (1.06, 130 ms). The 400 ms hold timer starts as built | none |
| Pick up | If the finger moves 10 pt before the hold timer fires, the timer is cancelled and this is a drag, not a talk. She grows to 1.22 over 160 ms, lifts to 44 pt above the fingertip over 180 ms (so the finger never hides her), her halo brightens 12% | `.impact(flexibility: .soft, intensity: 0.5)`, once |
| Carry | She follows the finger on `Theme.Motion.snappy`, sitting 44 pt above it. Her paint lags: each dab trails the motion by its own amount (vermilion 10 ms, cobalt 16, cadmium 22, satellites 26 to 34), capped at 14 pt, so she stretches a touch in the direction of travel and settles when the finger stops. Listening's bloom plays while carried (she's in his hand) | none |
| Drop | She settles at the nearest dock on the house spring (420 ms, bounce 0.12) and returns to size over 300 ms. A flick (release speed over 600 pt/s) projects the throw: the dock nearest the point 0.18 s ahead along the velocity | `.selection` |
| Docks | Two (Design 51): bottom-right (home, 346 / 779) and bottom-left (47 / 779). Side docks come back per page only where that page declares free ground. Her dock persists per page (`UserDefaults`, `tess.dock.<page>`) until he moves her again | |

The ask band's line always starts at x 24, so when she docks bottom-left the line, its lens, the two ask words and UNDO move to the right of her (x 96). That is the only thing that moves for her, and it moves once, with her drop, not while she's carried; the band keeps 736 to 820.

A press that moves less than 10 pt before 400 ms is still the hold-to-talk. A press that moves after the hold fired is still the "drag left to cancel" as built. Nothing changes for the gestures he knows.

## 5. Working: fade, split, process, gather
What he described most. The state replaces nothing in the table: `thinking` stays the per-dab pulse for a thought that takes under a second (a local parse, a Foundation Models answer). **Working** is for anything that takes longer and that he waits on: Claude being asked, Plan my day, a link fetch, a photo read. The router already knows which is which (`missesGoToClaude`, the link reader, the plan wording).

| Beat | What happens | Time | Values |
|---|---|---|---|
| Fade | Her colour drains: saturation 1.45 to 0.62, contrast to 1.0, opacity to 90%, the halo to 0. She is still whole and still breathing | 500 ms, ease-in-out | `SoulLook` lerp |
| Split | The six dabs loosen outward on short arcs into a constellation beside her line, and six hidden children (two per main dab, the parent's paint) fade up as they leave their parent, so she becomes twelve faint lights. Each light leaves 30 to 80 ms after the last (the three mains, then the satellites 30 ms apart, the children last, 80 ms apart; as the prototype and #453 build it) | 900 ms per light, `0.4, 0, 0.2, 1` | 12 lights, 11 to 15 pt radius, blur 5, alpha 0.55 (readers 0.42), parent's pigment, same blend as the soul. One light, the cobalt child, stays within 8 pt of her dock the whole time, so the corner is never empty (Design 51) |
| Process | The constellation: each light on its own slow Lissajous loop (periods 4.4 to 9.7 s, 10 to 34 pt amplitude) round a point 10 pt left and 7 pt up of home, so they cross and mix without ever lining up. Each breathes ±14% at its own rate. **Readers:** when there is something on the page she is reading (Plan my day: the Next rows; a link: the pasted text; a photo: nothing, so no readers), three lights (cobalt leading, vermilion and cadmium 90 ms and 180 ms behind, 1.5 pt lower) leave the constellation and scan under each row, left to right then back, 13 pt under the baseline, like a finger under a line. 5.4 s for five rows, then back into the constellation. They never cross the words' own baseline. Readers only under rows she's reading (Next rows, pasted text): never under the hero, never under an ask's two words | as long as it takes | |
| Gather | The readers fly home first (820 ms, `0.55, 0, 0.15, 1`); the constellation follows 140 ms later (680 ms), staggered 25 ms. The children fade out in the last 40% of their flight into their parent. Every light lands on its dab within the same 60 ms | 820 ms | |
| Colour | Floods back from 300 ms into the gather over 550 ms, so she is fully herself the moment Done begins | | |
| Done | Exactly as built, with its own `.success`. Then the line | 1.8 s | |

While working: no haptic, no sound, nothing on the page moves, the line says what she's doing in cobalt ("Planning your day.", "Asking Claude.", "Reading the recipe."). If the work fails, no Done: the lights gather, her colour returns over the same 550 ms, and the line says what happened ("Claude didn't answer in time.").

Working out on a row (section 3): the same fade, split and gather, with the constellation at 55% amplitude and no readers, because the thing she's reading is under her.

In a live workout: never. `LiveTessCorner` keeps thinking's pulse at its fixed size.

**Beside a repaint** (`living-colours.md`, `TessSoul.repaint(to:)`): a repaint only starts when she's idle, so it never starts while she works, roams, is carried, or during Done. If a repaint is in flight (the 2.8 s pool-and-dry) when work begins, the work wins: the new pigments are already hers from the pool's first frame, so the fade starts at once and the wet swell dries inside the fade's 500 ms instead of its own 2.8 s. Nothing waits on paint drying. The eyes don't change for a repaint.

**On light grounds** (Porcelain, Celadon) the lights multiply; at 11 to 15 pt crossings stay to two lights at a time, and Design checked Porcelain is not muddy at 0.55.

## 6. Her beat in a reward (board item 6, added 1:30 AM PT Oct 16)
`task-reward.md` owns the done pattern and its haptics; after Design 41 the fleck arcs to the day label. This adds only what the soul herself does in it, under the one-haptic rule: she plays none, the moment's haptics are the row's and the bloom's.

| t (ms) | Her part | Values |
|---|---|---|
| 0 (let go) | **Her eyes glance at the row** he struck (eyes on; 300 ms spring, up and toward it). Nothing else of her moves: the fleck is leaving, and a beat now would be two things at once | glance x −3, y −2.2 at soul scale 1 |
| 520 (the fleck lands, the label blooms) | **Her beat.** The brighten as written (1 to 1.12, settle spring, saturation up) now carries a **small gather**: the three satellites pull in to 55% of their offset over 180 ms and release over 320 ms on the settle spring, so she takes one breath in. Saturation lifts +0.3 at the gather and dries back over 900 ms. **One blink** at the landing (160 ms), then the eyes return to straight ahead at 940 | gather 180 / 320 ms; sat 1.45 → 1.75 → 1.45 |
| 940 | **Dry.** Everything of hers is back at rest; the bloom's own 900 ms fade is the last thing on the page. Under 1 s, as item 6 asks | |

- **Done's pour never plays for his win.** The 1.8 s pour, swell and splash is hers, for work she finished; a task he finished gets the small beat, so the two never read alike. `TessSoul.Mode` gains no case: the beat is a 940 ms overlay on whatever mode she's in (idle, usually), driven by `.tesseraFeedback(.done)`'s moment, not by a mode change.
- **Done from elsewhere** (said or written, the hero's finish, a habit, the last set, the shop): the fleck leaves the soul instead of a strike (`task-reward.md`), so her beat plays **at 0**, as the fleck leaves, and nothing at 520. The glance goes to the thing if it's on screen, else to her own line.
- **The last row of the day:** the same beat; the whole stroke's bloom is the page's, not hers.
- **Made** (words fly into the soul when Next isn't on screen): the take beat 1 → 1.1 → 1 as written, with one blink as they land. Plan kept: nothing from her.
- **In a live workout:** the last set's done plays the beat in `LiveTessCorner` at its fixed size, gather and blink only, no glance.
- **Reduce Motion:** no gather and no glance; the brighten is a 200 ms crossfade; the blink stays. The haptics stay, beat for beat, as `task-reward.md` says.
- Recording: `recordings/tess-motion-reward.mp4` (and `-light`): swipe right on "Call the bank", armed, let go, the fleck to "Thursday night", the bloom, her beat; the caption names each haptic and whose it is.

## 7. Living colour in motion (board item 7, added 1:50 AM PT Oct 16)
Design 48 (`living-colours.md`, with its addendum) owns the palettes, the nudges, the cadence and how a change arrives. This section records it beside her other motion and settles the values Builder A needs for `TessSoul.repaint(to:)`.

| Beat | What happens | Values |
|---|---|---|
| The pool | Each dab, 120 ms after the last in the order **cool, warm, bright** (cobalt, vermilion, cadmium), pools its new pigment from its centre outward over 900 ms on the house curve. In the canvas: the new wash is drawn with its gradient radius growing from 0 to the dab's edge while the old wash thins under it (opacity 1 → 0 over the same 900 ms), so the pool's edge is as soft as the dab and nothing is ever clipped | order 1, 0, 2; stagger 120 ms; 900 ms `0.3, 0, 0.2, 1` |
| Wet | While it pools the dab swells to 1.12 and brightens by 20% (not a third: three washes screened together blow out to white at a third on dark looks). **Light looks lift the core and mid alpha; dark looks lift only the mid, the core never** (Design 58). Kiln's dark triplet is the deepened one from `living-colours.md` d2145ec (`#7C8BF2 #EB7A5C #E9B14E`). Blur unchanged | swell 1.12, lift 0.2 (mid only on dark), in over 250 ms |
| Dry | The swell and the lift settle back over the rest of 2.8 s from the dab's start. The halo (dark looks) takes the new warm pigment the moment that dab's pool completes | dry ends at start + 2.8 s |
| Nothing else | No haptic, no line, no sound. Her eyes don't change. The page's text, her voice colour, UNDO, Done, the Lock Screen and the icon never follow | |

- **Only when idle**, as Design 48 says, so a repaint never starts while she works, roams, is carried, or during Done. The one overlap is a repaint in flight when work begins, and **work wins**: the pigments are hers from the pool's first frame, the pool finishes inside the fade's 500 ms, and the wet swell dries in the same 500 ms. The recording shows it: a capture lands 600 ms into the return to Today.
- **Done's colour is fixed.** The pour, the splash ring (`context`) and its haptic never take a palette. A Done after a repaint plays in the new pigments only because the dabs are the new pigments; nothing in Done itself changes.
- **Drag and roam after a repaint:** nothing special; she carries whatever pigments she has.
- **Reduce Motion:** a 600 ms crossfade of the three pigments (Design 48), no swell.
- Recordings: `recordings/tess-motion-colour.mp4` (Obsidian) and `-porcelain`, `-plein`, `-lacquer`, `-celadon`: Today → Lagoon (morning) → Kiln (evening) → Ember (a best, with "Bench best today." staying cobalt) → Today, then the capture mid-pool and Done. She is drawn at 1.35× so the pool can be seen; the values are the same at Home size.

## 8. While she listens or asks (board item 8, added 2:45 AM PT Oct 16)
`speak.md` and `one-ask.md` own these moments; Design 41's band rule holds (nothing on a page moves for her slot, 736 to 820). This records how the new vocabulary sits inside them, with the values Builder B needs in `BottomChrome` and Builder A in `TessSoul`.

| Moment | As built (`speak.md`, `one-ask.md`) | What the lab adds |
|---|---|---|
| **Speak from the surface** | Tap her, tap Speak; she travels to (196, 698) on the settle spring and becomes the listening bloom (×1.4), breathing with the mic level between ×1.4 and ×1.55; "Listening" at 470 in cobalt; the words as heard rise out of a 6 pt blur; a 1.2 s pause ends it; the ghost dries 3 s on the surface; then everything gathers back into the soul (220 ms) and the page comes forward | Eyes up, toward him, from the moment she blooms; **no blink while she listens** (a blink reads as a missed word). One blink as the pause ends. No roam, no drag, no repaint, no split while she listens: he is talking |
| **Hold her at rest** (the fast path) | After 400 ms she swells in place to ×1.4 and breathes with the level; the words stream right-aligned above her; let go sends; drag left cancels | The same eyes as above. The 10 pt drag threshold (section 4) only counts **before** the 400 ms; after the hold fires, movement is `speak.md`'s cancel, never a drag |
| **A Claude call out** (a miss, `missesGoToClaude`) | "Asking Claude." in her line | She gathers to the corner first (220 ms, as built) and only then fades and splits: **the work state never starts from the bloom**. No readers (there is nothing on the page to read; the words have gone). Done, then the line with UNDO |
| **The wait beside a one-ask** | The question in her line, the two ink words under it; her breath slows from 3.2 s to 4.8 s and she leans 4 pt toward her line; no glow, no colour, no haptic | Eyes on the two words (glance x −3, y +1.3 at soul scale 1) for the whole wait. **No roam, no split, no repaint while an ask waits**; a drag is allowed and the ask's words move with her dock, once, as section 4 says. On the tap: the ask's own `.selection`, one blink, the lean and the breath return over 300 ms |
| **Leaving an ask** | The ask folds; Tess says nothing | The lean and breath return the same 300 ms; no blink (nothing was answered) |
| **In a live workout** | The hold in `LiveTessCorner`, swell in place; asks are a choice or open only | No eyes glance in the corner; the same breath and lean are the whole wait |

- **Breath while listening is the mic, not time.** The ×1.4 to ×1.55 range maps the level (0 to 1) directly, smoothed over 120 ms (`.animation(.easeOut(duration: 0.12), value: listener.level)` as built). Nothing else of hers moves with the level; the eyes hold still.
- **One slot, one thing:** the ask, UNDO, the Heard line and the hint never share the band; the vocabulary adds nothing to the band.
- Reduce Motion: no travel to the bloom (she blooms in the corner), no lean, crossfades as built; the eyes hold.
- Recording: `recordings/tess-motion-ask.mp4` (Obsidian) and `-light`: Speak from the surface, the hold then a Claude call, and a one-ask wait answered by a tap.

## 9. Outside the app: widgets, the Lock Screen, Live Activities (board item 9, added 3:20 AM PT Oct 16)
Design 54 (`widget-states.md` addendum) and Design 36 (`lockscreen.md`) own every face outside the app; this section says where the soul is in them. The short answer: **she is not drawn outside the app.** A widget is her line with nowhere to tap down; a Live Activity is one number and one action on Cobalt sky; the Island is the system's black. Drawing her there would make her an icon (Design 54: no dots, dabs, pills or icons anywhere), and a still soul on a timeline that can't breathe reads as a dot. What is hers out there is her voice: the words, and the cobalt the sky is made of.

| Surface | What is hers | What moves | What never happens |
|---|---|---|---|
| **Home Screen widgets** (small, medium, large; tinted and clear) | The line, written by the phone's `HomeLines.widgetLine` | Only the system's: words push in from below, numbers `.numericText()` | No dabs, no eyes, no state. A widget never shows working, thinking or Done: a timeline that updates while the phone works keeps its last entry and the result pushes in when it lands. The action's ink line is the only accent |
| **Lock Screen accessories** (rectangular, circular, inline) | The line, then the time; the circular's one word | Nothing, except `Text(timerInterval:)` | No ring, no tick, no dab (54) |
| **Live Activities** (rest, cook, focus) | The sky: the cobalt wash top left is her voice colour as a ground, not her body. The words are hers | The horizon drains (the system's `ProgressView`); on Go the word pushes in and the washes warm to cadmium and vermilion over 1.4 s, the vermilion glow breathes behind the tick (36). The cook flare, the focus timer | No dabs, no eyes, no split, no gather, no beat. The Go warming is the face's own motion, **not her reward beat**: no haptic from us (the alert is N2's or the activity's, never both), nothing of the 520 ms pattern. The 60 s "All 22 sets in." face fills the horizon and nothing blooms |
| **The Island** | Words and the time | The countdown; the compact tick | Nothing of her, in every look |
| **Notifications** | Tess's one line each (36) | None | No image attachment of her, ever: a picture of the dabs beside "Tessera" is an icon |
| **The app icon** | Nothing: the icon is the system's (`app-icon.md`, #330) | None | Living colour never reaches it (section 7) |

### The return: the one moment that is hers
When a face brings the app forward (a tap on a Live Activity, a notification, its UNDO, a widget), she is **at her dock, at rest**, as the page comes in on the system's transition; she does not arrive, travel or bloom. The return line (`lockscreen.md`, Builder B: "Set 4 logged." with UNDO) draws into her band like any line of hers, 300 ms out of a 4 pt blur, and she gives it the glance from section 6 (spring 300 ms, x −3, y +1.3 at scale 1), eyes back after 420 ms, no blink. That is the whole return.
- **No beat, no colour, no haptic of hers for what happened while the app was closed.** The Done on the face was the face's moment and it is over; the words carry it. A best logged from the Live Activity reaches him as Home's line ("Push A done, a bench best.") and she treats it as any line: a glance. Replaying a beat for a moment he didn't see her in is a badge, and badges are on 36's Never list.
- If the phone is still working when the app opens (a Claude call started from a Shortcut, Plan my day from the widget's intent), she is already in the working state at the dock, from section 5's fade, with no split-in: the split happened off screen, so she is drawn mid-constellation at the frame the app appears, and gathers when the work lands. Nothing of hers starts from the transition.
- A widget tap that opens a page other than Home (Pull A opens the routine) finds her where that page's rule puts her (the pages table below): at her dock, at rest.
- Reduce Motion: the glance is already a spring under 300 ms and stays; nothing else is there to reduce.

### What the extension must not contain
`TessSoul`, `SoulRenderer`, `SoulParameters` and `SoulFrame` stay in the app target. The widget extension and the Live Activity draw with the shared `DesignSystem` pieces 54 names (`InkLine`, the type tiers, the look's ground from the App Group) and nothing of the soul; the review check is that the extension's target membership has no `Features/Tess/` file. Living colour's palette (`SoulPalette.look(_:living:)`) is not written to the App Group: outside the app the only cobalt is the sky's and the ink's.

- Recording: `recordings/tess-motion-outside.mp4` (Obsidian) and `-light`: the rest face's last seconds and Go on the Lock Screen (Cobalt sky in both looks, nothing of her), then the tap, the app coming forward with her at rest, the return line and her glance.
- Always-On: the activity's still face (36) has no washes and nothing ticking; in the app, nothing of hers runs in the background (the budget section: `TimelineView` paused).

## 11. The soul on the recut looks (board item 11, #367 / Design 43, added 3:35 AM PT Oct 16)
Design 43 recut Porcelain, Plein, Celadon and Lacquer (Obsidian unchanged) and said the soul keeps her shape and draws her three dabs from each look's `tess`, `live` and `now`. This section records what that does to every value above, look by look, with the recut tables on master (`Looks.swift` at 0e128c1) and `SoulPalette.look`'s rule as it stands.

| | Porcelain | Plein | Celadon | Obsidian | Lacquer |
|---|---|---|---|---|---|
| Her three dabs (cobalt, the warm, the bright: `tess`, `live`, `now`) | #2450D8 #E2432A #F0A500 | **#2A4FA8 #B9452B #C98E1B** (indigo, rust, ochre) | **#2C59BE #D94B2E #CF9418** | #86B4FF #FF5B3A #FFC23D | **#8FB5FF #F0583A #E9B64A** |
| Blend | multiply | multiply | multiply | screen | screen |
| Wash stops (core / mid) | 0.58 / 0.42 (pale) | **0.58 / 0.42 (pale, new)** | 0.58 / 0.42 (pale) | 0.8 / 0.6 | 0.8 / 0.6 |
| Halo (`live` centre / `context` at 55%) | 0.08 / 0.05 | **0.08 / 0.05 (new)** | 0.08 / 0.05 | 0.22 / 0.14 | 0.22 / 0.14 |
| Done's ring and the pages' flecks (`context`) | **#5A3DAF** | **#7D4E6E** | **#3A6584** slate | #B7A6E0 | **#D9A6B8** rose |
| Eyes (section 1: ink on light, ground on dark) | **#121016** | **#26201E** | **#0C1E19** | #000000 | **#130A0D** |
| The field under her dock | flat | flat (the washes and grain are gone) | the glaze foot: 6% ink over the bottom 260 pt | flat | the shade: #050203 at 75% by the foot; the specular band crosses mid-page, never the band 736 to 820 |
| Living colour's resting centre (section 7's "today") | the dabs above | the dabs above | the dabs above | unchanged | the dabs above |

- **Plein changes the most, and by rule, not by hand.** `SoulPalette.look` picks the pale stops for any look whose field is `pigmentBloom` or `glaze`; #367 made Plein's field `pigmentBloom`, so Plein's soul moved from the full stops (0.8 / 0.6, halo 0.16 / 0.10) to the pale ones with no line of soul code touched. The lab checked both on the new paper (#F3EDE2): the full stops multiply to a brown hole at her centre, the pale ones keep the three pigments readable, so the rule's answer is the right one. `-theme plein-washes` keeps the old field and so the old full stops; that is correct too, it is the look he is comparing against. **Design to confirm on the clips**; if Plein wants a touch more body than Porcelain, the lever is the core stop alone (0.58 → 0.64), never the halo.
- **The warm dab is no longer vermilion everywhere.** On Plein it is rust (#B9452B) and the bright is ochre; the readers in section 5 ("cobalt + vermilion + cadmium") are the look's three paints, whatever their names: cobalt reads first, the warm second, the bright third. The reward beat's +0.3 saturation and the wet lift are relative, so they hold.
- **Lacquer's foot.** The work constellation at the dock sits over the deepened shade, where screen-blended lights at 0.55 read a shade brighter than on the ground above; nothing changes, the field is under her, never over her (a field layer is the ground, `ThemeLayers.swift`). The bottom-left dock (47, 779) is in the same shade. The specular band (−24°, 150 pt, 5%) crosses the rows mid-page: roam targets on it are fine, 5% is below what a reader scan or a dab can be confused with.
- **Celadon's foot.** The glaze pool (6% ink over 260 pt) is under both docks; multiply dabs over a ground 6% darker are the same dabs. Done's ring is now slate (#3A6584) not grey-blue; it reads cooler against the jade, which is the point of 43.
- **A look switch and a repaint never run together.** 43's flood (`PaintFlood`, 700 ms from the soul) is the look arriving; section 7's pool is a palette arriving. A switch cancels any repaint in flight (the new look's "today" is the resting centre, the switch lands on it) and no repaint starts until the flood has landed and dried (700 ms + section 7's 2.8 s). During the flood the eyes hold (no blink, no glance) and she keeps her mode: a switch during work keeps the constellation and recolours it as the flood passes.
- **Nothing else moves.** Timings, curves, haptics, the budget, Reduce Motion, the page rules: all as above. The one Obsidian recording is still the reference; the four others are re-rendered on the recut tables.
- Board: `recordings/tess-motion-looks.png` (five rows, one per look: at rest, the work constellation with the readers, Done). Recordings on the recut tables: `tess-motion-work-light.mp4` (Porcelain), `-work-plein`, `-work-celadon`, `-work-lacquer`, and `tess-motion-colour-porcelain/-plein/-celadon/-lacquer.mp4` re-rendered (section 7's "today" moved with the tokens).

## 12. A full minute of Home at rest, with the idle budget (board item 12, added 3:50 AM PT Oct 16)
Most of her life is this minute: he opened the app and is reading. The test of the vocabulary is that a minute at rest contains nothing but breath and a blink, and costs almost nothing.

**What the minute contains** (`recordings/tess-motion-minute.mp4`, Obsidian, 60 s at 60 fps, deterministic blinks):
| | In 60 s | Period |
|---|---|---|
| Chrome breath (`BottomChrome`, scale 1 to 1.08) | about 19 | 3.2 s |
| Halo breath (idle row: scale 0.8 to 1, opacity 0.6 to 1) | about 8 | 7 s |
| The mains' lift | about 7 | 9 s, delays 0 / −6 / −3 |
| The satellites' drift | 5 / 8 / 6 | 11 / 7.5 / 9 s |
| Blinks (section 1) | 7 to 15, about one in five a double | every 3 to 8 s, 160 ms each |
| Glances, roam, repaints, lines, haptics, sound | **0** | a glance needs something to appear; roam needs a change; a repaint is at most 3 a day after 2 h idle |

Nothing on the page moves, and nothing of hers is owed to the page. There is no "she gets bored" state: no stretch, no look-around, no wander, no sleep. A soul that performs for an empty minute is a screensaver; the life he asked for is that she is *there*, breathing, and answers when something happens. The built `resting` row (12 to 15 s periods) stays what it is for: Shutdown and the quiet hours, not a timeout.

**The idle budget** (the numbers the build is held to, on the device, Release):
- **Tick rate 30 fps** for idle, listening-at-rest and resting, as built (`TimelineView(.animation(minimumInterval: 1/30))`); a blink is 5 of those frames, which is enough for a 160 ms close-and-open (closed on frame 3). The eyes add two unblurred ellipse fills to the frame, nothing to the tick.
- **Under 2 ms a frame** for the whole soul draw at rest (six dabs, halo, ring: nine blurred fills, blur ≤ 9) on iPhone 17, which is under 6% of one performance core at 30 fps and lets the GPU stay in its low state. The group grade (saturation, contrast) is constant at rest, so the compositor caches it.
- **No layout.** At rest she is an `offset` and a `scaleEffect` on a 240 × 240 canvas; nothing invalidates the page, and `TessSoul.body` is not re-evaluated by the tick (the timeline's `context.date` is read inside the canvas, not in `body`).
- **Energy Low** for the whole minute in Instruments, and the app's share in Settings › Battery at or under Messages' the next morning (the check kit's §4).
- **Off screen is off.** Another app, the Lock Screen, or the soul scrolled under a sheet: the timeline pauses; no frame is drawn that no one sees. She never drops to a lower tick at rest because the screen has been still (auto-lock does that), and never stops breathing while visible: a still soul reads as dead (section 1 of `tess-soul.md`).

**How QA checks it** (`tess-motion-check.md`, the "Minute" row): the build's blinks are random, so the minute is compared by count and cadence, not frame by frame: 7 to 15 blinks, every gap 3 to 8 s, at least one double, each blink 160 ms ± 1 frame at 30 fps; the soul crop's mean SSIM against the clip over any 10 s window ≥ 0.92 (breath and drift are periodic, so the windows match without alignment); zero frames in which anything outside the soul crop changed.

## 13. Reduce Motion and Low Power, state by state (board item 13, added 4:05 AM PT Oct 16)
Two switches, two different reasons. **Reduce Motion** is his accessibility setting: motion itself is the problem, so travel, blur-in and swell go and crossfades take their place; the soul is still (the build's `paused: reduceMotion` timeline, the mode shown by position and size; **never by opacity, grade or halo: decisions D4/G225, Oct 17**). **Low Power Mode** (`ProcessInfo.isLowPowerModeEnabled`, with `NSProcessInfoPowerStateDidChange`) is the phone's battery: motion is fine, cost is not, so everything keeps its shape at a lower tick with the expensive layers dropped. Master has no Low Power path yet; this is it. With both on, Reduce Motion wins (nothing moves, so there is nothing left to cheapen).

| State | As designed (sections above) | Reduce Motion | Low Power |
|---|---|---|---|
| **Idle** (section 2, 12) | breath 3.2 s, lift, drift, halo breath, 30 fps | still frame of idle; **the breath is opacity only** (0.85 to 1 over 3.2 s, no scale, no travel); the blink stays (Design, 11-13 pass) | unchanged motion at **20 fps**; halo breath held at its mean (0.9 / 0.8) so the frame is one fill cheaper; blinks stay |
| **Eyes** (1) | blink 160 ms, glance spring 300 ms | **the blink stays** (160 ms, no travel: not motion in Apple's sense); no glance, the dots sit still | blink stays (5 frames at 30, 3 at 20 are enough); glance stays (it is an offset, not a redraw) |
| **Roam** (3) | `SoulTravel` 760 ms, works beside the row, rides the scroll | no travel: she stays home, the line names the row | **no roam**: she stays at the dock; the line names the row; the work state runs at the dock (the readers' canvas is the one thing that leaves hers, and it is the first cost to drop) |
| **Drag** (4) | pick up, carry with paint lag, drop on the house spring, flick | 200 ms crossfade to the dock on release; no carry lag, no grow | unchanged (a drag is an `offset` on the view; the lag is six fills she already draws); the carry bloom's breath held at its mean |
| **Working** (5) | fade 500 ms, split 900 ms into 12 lights, readers, gather 820 ms, colour back, Done | **shown by position and size only (G225, D4):** 200 ms crossfade to the loosened pose, the three mains 1.5× from the centre, the satellites held at their idle places; **opacity 1, grade and halo exactly as at rest**; 200 ms back; Done its still frame | fade and gather unchanged; **six lights, not twelve** (the six children never leave the dabs); **no readers**; constellation at **30 fps** (not 60); the colour returns over the same 550 ms; Done as built |
| **Thinking** (as built) | per-dab pulse at 60 | still, shown by size | 30 fps |
| **Listening** (8) | bloom ×1.4 to ×1.55 with the mic level, travel to (196, 698) | blooms in the corner, no travel; eyes hold | unchanged but the level smoothing at 30 fps; travel stays (an offset) |
| **A one-ask wait** (8) | breath 4.8 s, 4 pt lean | no lean; the breath still | lean stays; 20 fps as idle |
| **Done** (as built) | pour, swell, splash, relax 1.8 s + `.success` | its still frame, 1.8 s, `.success` | unchanged (1.8 s once; cheapening Done changes Done) |
| **Reward beat** (6) | glance, gather 180 / 320 ms, brighten 1.12, one blink | no gather, no glance; the brighten is a 200 ms crossfade; the blink stays | unchanged (940 ms, six fills) |
| **Repaint / living colour** (7) | three pools 120 ms apart, 900 ms, wet swell, dry 2.8 s | one 600 ms crossfade of the pigments, no swell | **deferred**: no repaint starts in Low Power (the palette waits for the next idle after Low Power ends); a repaint in flight finishes at 30 fps |
| **Look switch flood** (11) | `PaintFlood` 700 ms from the soul | 250 ms crossfade (as built) | unchanged (one pass, 700 ms) |
| **Outside the app** (9) | nothing of her; the return glance | the return glance stays (a spring under 300 ms) | nothing to change; the widget timeline is the system's |
| **Haptics** | one per moment | unchanged, beat for beat | unchanged (a haptic costs nothing worth a dead moment) |

**The Low Power rules, in four lines**
1. Tick: idle and resting 20 fps, every other mode 30 fps, never 60. The constellation and the listening bloom are the two that notice; both still read (the split's 900 ms is 27 frames).
2. Layers: no readers' canvas, no children (six lights), halo breath held. That is at most 9 blurred fills a frame in any mode, against 14 in full.
3. Nothing leaves the dock: no roam. Drag stays (his hand, not hers), the Done in place rule is moot.
4. Nothing new starts that only beautifies: no repaint. Everything that answers him (listening, working, Done, the beat, the lines) keeps its timing exactly, so Low Power never changes what a moment *means*, only how much it costs.

The switch is read once per frame from a cached flag (the notification updates it); a change mid-state is applied at the next mode change, never mid-animation (a constellation that halves its lights mid-split reads as a glitch).

- Recordings: `recordings/tess-motion-low-power.mp4` (Obsidian): the working state in Low Power, six lights, no readers, 30 fps, beside the full one in `tess-motion-work.mp4`; `tess-motion-reduce-motion.mp4` stays the Reduce Motion reference. The simulator can't set Low Power; QA checks it on the device with the flag forced through `-lowPower` (simulator-only `LaunchFlags`, and a real toggle on the phone).

## 14. The event contract (board item 14, added 4:30 AM PT Oct 16)
Today eleven places write `AppModel.tessMode` directly (`BottomChrome` nine times, `RootView`'s double tap, Settings' key check) and the workout keeps its own copy in `WorkoutModeView.play`. The sections above add working, roam, the beat, repaint, eyes, drag, the return glance, Low Power and the lens on top of that. So that Builder A wires her **once**: views emit an *event*, one router turns events into her state, and the table below is the whole contract. Nothing else may set a mode.

**The shape** (`SoulEvent` → `SoulRouter.handle(_:)` → `SoulState`): a state is a mode (as built) plus four overlays that can ride on a mode: `beat` (section 6), `roam` (a place, section 3), `carried` (section 4), `repaint` (section 7). The workout's `LiveTessCorner` runs the same router with `page = .live`, which the pages table makes roam-free and glance-free.

| Event | Emitted by | Soul state | Notes |
|---|---|---|---|
| `appeared` / `closed` (the surface closes, a line fades after 4 s, the app comes forward) | `BottomChrome`, `RootView` | **idle**, or **resting** 23:00 to 06:00 | as built (`restingOrIdle`) |
| `returnLine(text)` (a line from a face, a notification, the 04:00 roll: `processNotes`) | `BottomChrome.say` | idle + the glance | section 9; no beat |
| `tessOpened` (tap her, "log bench " from another screen) | `BottomChrome.opened` | **listening** | as built |
| `draft(isEmpty)` | the text field | listening / idle | as built |
| `sent(text)` (the ghost dries) / `heard(words)` | `BottomChrome` | **thinking** | as built; local grammar only |
| `dryCancelled` | a tap on the ghost | listening | as built |
| `committed(local)` | `BottomChrome.commit` | idle + brighten | as built: **not Done** ("`.done` would multiply its dabs into mud") |
| `askClaude(kind)` (Claude call, Plan my day, link fetch, photo read) | the router, from `commit`, `ClaudeSection.check`, Shortcuts | **working(reading:)** | section 5; readers only on a page with declared ground; from the bloom only after the 220 ms gather |
| `claudeDone` / `claudeFailed` | the same | gather → **Done** / gather → idle + the line | section 5 |
| `speak(hold:)` | Speak tap, the 400 ms hold | **listening** (×1.4, breath on the mic) | section 8; at (196, 698) from the surface, in place from a hold |
| `heardNothing` | the listener | idle | as built |
| `setLogged` / `newBest` | the workout | **Done** / thinking 1.2 s → Done | as built (`play`) |
| `liveAsk` → `liveAnswered` | the workout's ask field | thinking → Done | as built |
| `swapped`, `topSetAccepted`, `workoutGathered` | the workout | **Done** | as built |
| `taskDone(row)` (swipe, hero, habit, Groceries) | `QueueRow`, hero, habits, Groceries | current mode + **beat** at 520 ms | section 6; Done's pour never |
| `doneElsewhere` (a Done that played off screen) | the ledger on foreground | beat at 0 | section 6 |
| `rowChanged(rect)` (a change to a row that names a place) | the page, through its free-ground preference | **roam** to the place, then the work or Done there | section 3; never while listening, asked, carried or in Low Power |
| `scrolled(dy)` | the page | roam rides, releases at y 130 / 700 | section 3 |
| `goHome` (double tap) | `RootView` | **Done** → flood → idle after 900 ms | as built |
| `held`, `pickedUp(10 pt)`, `carried(point)`, `dropped(dock)`, `flicked(v)` | `BottomChrome`'s gesture | listening-at-rest / **carried** / the dock | section 4 |
| `askWaiting(words)` / `askAnswered` / `askLeft` | one-ask | idle + the lean, breath 4.8 s / the return 300 ms | section 8 |
| `lookSwitched` | `ThemeStore` | current mode, flood 700 ms; eyes hold; repaint cancelled | section 11 |
| `paletteChosen(palette)` | the living-colour rule table | **repaint** overlay, idle only | section 7; deferred while anything else runs or in Low Power |
| `lensHeld` / `lensReleased` | `HomeSpatialView` | current mode, pinned to the dock; readers home | section 15 |
| `shutdown`, `quietHours` | Core's scheduler | **resting** | as built |
| `backgrounded` / `foregrounded` | the scene phase | paused / the mode it left, mid-animation never (working resumes at full constellation) | section 9 |
| `lowPower(on)` | `ProcessInfo` | applied at the next mode change | section 13 |
| `reduceMotion` | the environment | the still table | section 13 |

**Who wins when two arrive together** (the router's order; higher beats lower, and a one-shot in flight is not cut except by the first row):
1. **His touch on her**: `held`, `pickedUp`, `speak(hold:)`. Cuts anything, including Done, with the 400 ms blend; a drag ends roam and work's readers at once (the constellation stays at the dock, then follows the carry). The cut never takes back what already happened: the `.success` that played stays played and the receipt line stays in the band (the line is the record; the pour was only the celebration) (Design, 14-15 pass).
2. **Listening.** No roam, drag threshold only before the hold fires, no split, no repaint, no beat while she listens (a Done arriving while he talks waits and plays as the beat when she returns).
3. **An ask waiting.** Holds the lean; a `taskDone` during the wait beats at once (it is his), `rowChanged` waits.
4. **Done in flight** (1.8 s): a second Done inside it becomes a beat at 0; `askClaude` inside it queues and starts at the end; `rowChanged` waits.
5. **Working**: `taskDone` beats on the constellation; `rowChanged` is noted and the roam happens at gather if the place is still there; `paletteChosen` waits; a second `askClaude` joins the running one (one constellation, the later `claudeDone` ends it).
6. **Thinking** (local, under 2 s): everything queues behind it except a beat.
7. **Beat** (940 ms overlay): never blocks; two beats inside 940 ms merge into one.
8. **Roam**: a new `rowChanged` retargets on the same arc from where she is; `lensHeld` sends her home.
9. **Repaint**: anything above cuts it, drying inside 500 ms.
10. **Idle / resting.**

Two rules that make it one wire: **views never set a mode** (a view that needs her sends an event; the test is a grep for `tessMode =` outside the router), and **the router is the only timer** (`play`'s 1.8 s, `say`'s 4 s, the beat's 940 ms, the flood's 900 ms all live there, so two timers can't race).

## 15. During the glass-tab hold and swipe (board item 15, Design 42 / #342, added 4:40 AM PT Oct 16)
#342 built Design 42: hold the tab row 260 ms and a Liquid Glass lens forms, the four pages shrink to 78% on a near-black ground with the neighbours live at 55%, slide and the pages follow 1:1 with a `.selection` tick per word, let go and the page under the lens opens (480 ms), the lens melts into the ink line (280 ms). She is on the chrome layer (`RootView`'s overlay), not in the deck, so the pages shrink around her and she stays where she is, at full size, over the darkened ground.

- **She stays put and keeps breathing.** The lens is him navigating; it is not an event of hers. No glance at the lens or his finger (a soul that follows his finger is a cursor), no roam, no change of mode, no haptic of hers: the ticks are the lens's. The band 736 to 820 holds; the deck's bottom edge (852 × 0.78 from the centre, about 758 at the deck's foot) is above her, so nothing of the pages crosses her.
- **If she was working when the hold starts,** the readers go home inside the shrink's 360 ms (they live on a page, and the page is leaving) on the gather curve; the constellation stays at the dock and keeps working; the result lands as Done at the dock, on whatever page he let go on. She never reads on a shrunk page or a neighbour at 55%.
- **If she was out on a row (roam),** the hold sends her home on the same 760 ms arc; a Done owed to that row plays at home.
- **Carried:** a lens can't form while she is carried (the hold on the tab row is a second finger: ignored while `carried`), and a touch on her while the lens is up is ignored. One hand, one thing.
- **Listening or an ask waiting:** the tab row's hold is refused (the Speak layer and an ask own the page, section 8); a plain tap on a tab still works as built.
- **Release:** nothing of hers moves for the page growing back; if the page he opened declares free ground and a `rowChanged` was queued (section 14, rule 5), the roam starts after the 480 ms grow, never during it.
- **Reduce Motion:** the pages crossfade and the lens still forms (42 rule 7); she does nothing, as above. Low Power: the same.
- Recording: `recordings/tess-motion-lens.mp4` (Obsidian): the hold from Today, the slide to TRAINING with a tick, the release; then the same hold while she is reading the rows, the readers coming home inside the shrink.

## Timing and easing, in one place
| | Curve | Duration |
|---|---|---|
| Travel across the page (roam go and home) | `SoulTravel` arc as built | 760 ms |
| Split | `0.4, 0, 0.2, 1` | 900 ms (readers 1.1 s) |
| Gather | `0.55, 0, 0.15, 1` | 820 ms (constellation 680 ms) |
| Fade / flood | ease-in-out | 500 / 550 ms |
| Pick up | ease-out | 180 ms |
| Drop | house spring 0.42 s, bounce 0.12 (flick: 0.55 s, bounce 0.14) | |
| Eyes blink / glance | ease-in-out / spring 0.3 s, bounce 0.05 | 160 ms / 300 ms |
| Reward beat (gather in / out) | ease-out / settle spring | 180 / 320 ms, dry 900 ms |
| Repaint pool / wet / dry | house curve / ease-out / house | 900 ms per dab, 120 ms apart / 250 ms / 2.8 s in all |
| Mode blends | `SoulBlend` 400 ms, as built | |
| Return from a face (section 9) | the system's app transition; her glance, spring 0.3 s | 300 ms, eyes back at 420 ms; no beat |

## Haptics (under `task-reward.md`'s rule)
| Moment | Haptic | Owner |
|---|---|---|
| Picked up | `.impact(flexibility: .soft, intensity: 0.5)`, once at 10 pt | BottomChrome (B) |
| Dropped at a dock | `.selection` | BottomChrome (B) |
| Working done | Done's own `.success` (already in `TessSoul`), nothing extra | TessSoul (A) |
| Roam, eyes, split, gather, fail, her reward beat | none | |

Two new `Haptic` cases (`.soulPickUp`, `.soulDrop`) in `DesignSystem/Haptics.swift`; nothing plays twice for one moment. In quiet hours the pick-up and drop still play (they're under his finger).

## Reduce Motion
- Nothing travels. Roam: she stays home and the line still names the row. Drag: she jumps to the dock with a 200 ms crossfade. Eyes: the blink stays, no glance. The breath is opacity only, 0.85 to 1 over 3.2 s, no scale: a still soul reads as dead (section 1), and an opacity breath and a 160 ms blink are not motion in Apple's sense (Design, 11-13 pass).
- Working: a 200 ms crossfade to the loosened pose with the three main dabs 1.5× from the centre and the satellites at their idle places; **group opacity stays 1, the colour grade and the halo do not change** (G225, D4); a 200 ms crossfade back when done. Done is its still frame as built. The working fade of the full version (500 ms, live motion) is unchanged.
- Haptics stay, beat for beat.

## Performance budget
- **60 fps** on iPhone 17 with the page under her scrolling. The soul is one `Canvas` in a `drawingGroup`, as built. Twelve blurred lights cost about the same as the six dabs plus the drip and ring today (each is one radial fill with a layer blur). Rule: never more than 14 blurred layers per frame, blur radius capped at 9.
- Travel and drag are `offset` animations on the view, not redraws: the canvas keeps its 240 × 240 size and moves. The readers are the one thing that leaves the canvas: they draw in their own small `Canvas` (the page's width × 60 pt, moving with them), so the main canvas never grows to the page.
- **Battery**: idle and resting tick at 30 fps as built; the constellation ticks at 60 only while working, which is bounded by the 20 s Claude timeout. Nothing animates when the app is in the background or the soul is off screen (`TimelineView` paused). A working state longer than 20 s drops to 30 fps.
- If Builder A finds the twelve-light frame over 4 ms on the device, drop the six children first (six lights still read as a split), then the readers' trail.

## What this does not decide
- Whether the eyes are on by default. Recommendation: off, so he turns them on and finds out if he likes a face on her.
- The Metal shader route (Research): this sheet works in the `Canvas` she has today. If Builder A moves her to a shader later, the values carry over unchanged.
- The palette (`soul-explore.md`, `living-colours.md`). The spread is 65% in the app now (#330: the home offsets live in `Features/Tess/SoulFrame.swift`), and the prototype matches; a `?spread=` and `?look=` on the prototype URL show any other.

## Design's reviews
**Items 5 to 7 (Design 58, 2:33 AM PT Oct 16): pass.** Two changes taken into section 7: Kiln's dark triplet deepened 8%, and on dark looks only the mid alpha lifts while wet. The two page rules (a page declares its free ground; live things own their surface) are also in `tess-motion-build.md`.

**Items 1 to 4 (item 51, 12:48 AM PT Oct 16)**
Pass, with the fixes now folded in above: eyes always the dark pigment; constellation at 0.55 with the cobalt child kept at the dock; readers kept, only under rows she reads; two docks; no row dimming on roam; Done in place only with an 80 × 80 clear; the bottom-left dock moves the whole band's words once. No second Design pass on the values, only on Builder A's recording. The build sheet is `tess-motion-build.md`.

## Where she may go on the other pages (added 1:10 AM PT Oct 16)
The rules above were written against Home. The same seven rules hold everywhere; this is what they come to on the pages that have changed since (`training-mode.md` for Design 44 and #337, `review-week.md` for 46, `tess-knows.md` for 49). Both docks (bottom-right home, bottom-left) exist on every page, since the band at 736 to 820 is hers on all of them; a bottom-left dock moves the band's words to x 96 the same way on each.

| Page | Roam | Readers while working | Drag | Notes |
|---|---|---|---|---|
| **Training at rest** (the plan as lanes, 300 + 72k) | To a lane only in the gap between the exercise name's end and its target at the right, 40 pt after the name, 6 above its baseline, and only if that gap is 56 pt or wider ("Bench press" to "82.5 × 8" is; a long name on a narrow phone isn't, so she stays home). Never on the strip at 0, never on the Start mark at 236, never on the set strokes under a name | None: the strokes under each name are the content, and a glint under them would read as a set. The constellation only, at her dock | Yes | Paused is at rest for her. Trained today: same, the lanes are dry |
| **Training, live** (`LiveTessCorner`) | Never. Her slot is fixed and small; she keeps thinking's pulse | None | No: the corner isn't draggable, and a hold there is the set ask | Eyes: shown in the corner, no glance (nothing to look at but the set) |
| **Training, the second line** (#337) | Her line on this page is the band's line; the second line is the page's own words, not hers, so she never goes to it and it never moves for her | | | |
| **Review** (the week as bands) | Never into the bands: every column is a mark, and the columns align by the day letters alone, so there is no free ground between 240 and 660. She may go beside THE WEEK'S LINES (660 on) only when a line is the thing she's changing, which Review doesn't do today. So: home. Reading a day (the tap) changes nothing for her | Under THE WEEK'S LINES' three lines (or the tapped day's four), when she's reading the week ("what was my best this week" through Claude). Never under the bands | Yes | Her line here is forward-looking and only when she has one; the readers are the one sign she's reading |
| **Routines, a routine's days** | To a routine row's free ground after its second line's words, as a Home row. Never over the unfolded day words | None (local) | Yes | |
| **What I know** (49) | Never. This page is her voice already, and both of its motions end at her: the forget's flecks drift to the soul, and a new fact arrives under the drying line. The flecks go to wherever she's docked (bottom-left too), on the same reversed hand-off arc | None: "what do you know" is local (thinking), and Claude's `remember` lands as the page shows, not as a read | Yes | FORGET EVERYTHING ends the scroll and the page fades over its last 50 pt above the band, so a drop never lands on it |
| **Settings** | Never (a page of his values; `settings-place.md`) | None | Yes | |
| **Day log, Kitchen, Groceries** | As Home rows: after a row's words, 40 pt, 6 above the baseline, 56 × 44 free | Under the rows she's reading (a pasted recipe's lines; the aisle rows when she sorts them) | Yes | Cook mode: never, like a live workout |

- Recording: `recordings/tess-motion-pages.mp4` (Obsidian) and `-light` (Porcelain), 36 s: Home after 41, Training at rest, Review's week, Kitchen; each opens with a lab overlay (dashed, not in the app) of her free ground, then she goes to one allowed spot, works, Done in place, home. On Review she stays home and the readers scan THE WEEK'S LINES.

Two general rules this adds:
- **A page's free ground is the page's to declare.** Each page reports its rects through a preference (`tess-motion-build.md`); a page that reports none gets no roam and no readers, only the constellation at the dock. That's the safe default for every page not in this table.
- **Live things own their surface.** A live workout, cook mode, the Speak layer and a flight from `task-reward.md`: she stays put and does only what she does today.
