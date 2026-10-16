# Tess: the picked ideas (board items 18 to 20)

Kaushik, 9:55 AM PT Oct 16, on the idea board (`tess-ideas.html`): "I like all of them… we should do all of them",
plus a small mouth "just a line… so it could get a little more expressive", and the same Tess "with different apps,
not just one app". Product logged the picks (decisions.md 9:58 AM) and set the order below, which is Builder A's PR
order. Every sheet plugs into the event contract (`tess-motion.md` §14): a view emits an event, the router decides,
the router owns every timer. Nothing here adds a model call; the screen-aware Tess stays parked
(`tess-aware-motion-notes.md`).

Rules that hold for every sheet:
- **Eyes off means no face.** The mouth lives under the same setting ("Tess has eyes"), default off (Product).
  An idea that uses the eyes keeps only its body part when they are off, and if it has no body part it does
  nothing. Each sheet says which.
- **Every area, the same way.** An idea is keyed to an event, never to a screen, so Home, Training, Review,
  Kitchen, Groceries, Habits, Notes and the later areas (Money, Reading, Upkeep, People) get it for free once they
  emit the event. The per-area table is in §20. The only exceptions are the "live things own their surface"
  pages (a live workout, cook mode, the Speak layer, a flight): there she does what each sheet says for `.live`.
- **One haptic per moment.** Only idea 3 has a haptic of hers. The rest add none.
- **Calm.** Each idea plays at most once for its trigger. None loops, none runs while she's carried, and none cuts
  a mode above it in §14's precedence.
- **Reduce Motion and Low Power** are listed per sheet. The blink always stays (§13).

Clips: `recordings/ideas/tess-idea-*.mp4` (Obsidian, 6 s or less). The values below are the clips' values
unless a line says otherwise.

---

## 18a. Lights that follow the page (idea 1) and she wakes with you (idea 2)

### Idea 1: the readers go to the words the ask touches
Kaushik's 8:53 note: "after it spreads the pattern is very predictive". The fix needs no model. The ask already
knows which things it reads or changes, so the readers go there.

| | |
|---|---|
| Trigger | `askClaude(kind, touched:)`. `touched` is the list of objects the job reads or changes, in the order the job uses them (the pack builder returns them and `ClaudeClient` passes them on; they never leave the phone: Plan my day = the rows it moves or names; a recipe read = the lines it parses; Review's week = the lines it reads) |
| Where the readers go | The page maps each touched object to the rect of its words (the title, and the time if the job changes a time) through the same free-ground preference as §3. A word off screen is skipped. |
| Path | Hop 340 ms on the house curve with a 10 pt arc up, then dwell 380 ms, sweeping ±45% of the word's width. The order is the job's order, not top to bottom, and she never visits the same word twice in a row. After the last word she starts over at the first, which is fine because the list is different on every ask. |
| Fallback | Fewer than two touched words on screen: §5's sweep of the rows she reads, as built. |
| Dock lights | The constellation drifts on seeded noise (three summed sines per light, periods 3.5 to 9.5 s, about ±1 pt), seeded per working state, so no two runs match. |
| Eyes | None of its own. The eyes are gone while she is split (§1). Eyes off: the same. |
| `.live` | Never. There are no readers on a live page. |
| Reduce Motion | §13's crossfade. No readers. |
| Low Power | No readers (§13). The noise freezes, so the six lights hold still. |
| Test | Given `touched` = [Push A, 12:15 pm, Call the bank], the readers' first three dwells are on those rects in that order. Two working states in a row with the same `touched` produce different dock-light paths (the seed differs). |

### Idea 2: she wakes with you
| | |
|---|---|
| Trigger | `firstOpenOfDay`: the first foreground of the day (`AppClock`'s 04:00 boundary) that lands outside quiet hours (23:00 to 07:00). The router emits it from `foregrounded` and keeps "woke on" per day. A foreground in quiet hours is idea 5's wake, not this one, and doesn't count the day as woken. |
| What she does | Her eyes are closed (lids at 0.25) for 1.0 s after the page arrives, then open over 400 ms, ease-out. At 1.5 s comes one stretch: the mains spread 22% wider and about 20% shorter (x × s, y × (2 − 0.98 s), s 1 → 1.22) over 600 ms, ease-in-out, then back over 700 ms on the house curve. One blink follows at 3.4 s. The mouth stays at rest. |
| Skipped when | The first open lands in a live workout, in Speak (a notification's speak action), or with an ask waiting. In those cases his moment wins, and the day counts as woken. |
| Eyes off | The stretch only. |
| Reduce Motion | No stretch. The eyes open with a 200 ms crossfade. |
| Low Power | The same as Reduce Motion. |
| Haptic | None. |
| Test | Two foregrounds on one day give one wake. Foregrounds at 03:59, 05:30 and 07:01 give one wake, at 07:01. |

## 18b. Stroke her (idea 3) and she wears the day (idea 4)

### Idea 3: stroke her
| | |
|---|---|
| Gesture | A pan that **starts outside her** 64 pt hit area, inside the band (736 to 820), crosses her and leaves the other side within 700 ms, travelling at least 40 pt. Because it starts off her, it can never be her tap, her hold or her drag (§4). **A pan that starts in the band is always hers; page swipes (sheet 69's peek, swipe for more) start above 736**, so a stroke never opens a page's peek. |
| What she does | A ripple runs through the paint: each dab is offset by 4 pt × e^(−2.6 k) × sin(0.25 × its x from her centre − 16 k), and y by 0.6 of that on a cosine, for 1.6 s. One blink lands 50 ms after the finger leaves. The eyes look along the stroke (1, 0) while it crosses. The mouth gives a small curve (+0.5) for 900 ms. |
| Haptic | One soft tick as the finger enters her: `.impact(flexibility: .soft, intensity: 0.3)`. A new case, `.soulStroke`. |
| Repeats | A second stroke within 1.6 s restarts the ripple with no second tick. |
| Refused while | She is working, listening, carried, or an ask is waiting. The pan then belongs to whatever is under it. |
| Eyes off | The ripple and the tick. |
| `.live` | No. The corner is not a stroke target. |
| Reduce Motion | No ripple. One blink and the tick. |
| Low Power | The ripple at 30 fps. |
| Test | A pan starting on her is not a stroke (it stays drag or hold). A pan from x 280 to x 392 across y 779 in 350 ms is a stroke, with one tick. On the recipe page, a band pan from x 380 to x 270 that crosses her is a stroke and doesn't open the peek. |

### Idea 4: she wears the day
| | |
|---|---|
| Trigger | `taskDone` in any area (§20's table), counted per day from 04:00. Things undone within their UNDO window don't count. |
| What she does | Each done adds +0.10 to her saturation, applied at that done's beat (§6, at 520 ms), and the beat carries an extra +0.25 that dries away. **Capped at +0.40** (four dones), so a big day never gets loud. The cap is reached gently: it is +0.10 per done up to four, then nothing. |
| Resets | At 04:00, over the first idle minute, never as a visible step. |
| Where | Everywhere she is drawn, `.live` included, because it is her paint and not a motion. |
| Eyes off | The same. It has no eye part. |
| Reduce Motion | The same (colour isn't motion). |
| Low Power | The same. |
| Living colour | It multiplies the day's palette (§7). It doesn't replace it. |
| Not in the clip | In `tess-idea-wear.mp4` the done rows leave holes in the list. That's the prototype only: Home's done stays as built, so builders don't copy it. |
| Test | Five dones give +0.40. An undone done gives +0.00. At 04:00 she is back to +0.00. |

## 18c. The mouth (board item 19)
A single short stroke under the eyes: a line that turns with the moment, never a cartoon face. Kaushik: "maybe a
small mouth or just a line… straight, curvy… so it could get a little more expressive". Clip:
`recordings/ideas/tess-idea-mouth.mp4` (idle, listening, thinking, her line, rest, with a magnifier, since at Home
size it is a pinprick like the eyes).

| | Value (soul scale 1; multiplied by the drawn scale, like the eyes) |
|---|---|
| Place | Centred under the eyes: the main dabs' mean + 2.6 pt down. It rides the eyes' glance at 70%. |
| Size | 5.6 pt wide, 1.1 pt stroke, round caps. |
| Colour | The eyes' dark pigment at **70%** (the eyes are 82%), so the eyes always lead. |
| Shapes | One curve with three dials. `curve` is the middle's drop, 1.7 pt at +1 (a small smile), and its ends lift 0.5 pt. `tilt` raises only the right corner, 0.9 pt at +1; the left never drops. `open` rounds it into a soft o, 2.7 × 2.8 pt filled. |
| Down | `curve` goes down only to −0.35, and only for a miss of her own (`claudeFailed`, 1.2 s, then back to rest). **Never a frown at him**: not on UNDO, not on a skipped set, not on a missed habit, not at night. |

| State | curve | tilt | open | Eyes |
|---|---|---|---|---|
| Idle / resting | +0.2 | 0 | 0 | ahead |
| Listening | 0 | 0 | 0.75 | up at him |
| Thinking (local) | +0.2 | +0.4 (curious, never a smirk) | 0 | aside, toward her line |
| Working | gone with the eyes when she splits | | | |
| Her line shown (a reply) | +1.0 for 1.5 s, then relaxes over 600 ms | 0 | 0 | at her line |
| Done | gone with the eyes (120 ms out, 200 ms back), so Done plays as built | | | |
| Her beat (§6) | +1.0 for the beat's 940 ms | 0 | 0 | blink |
| An ask waiting | +0.3 | +0.4 (curious) | 0 | at her line |
| `claudeFailed` | −0.35 for 1.2 s | 0 | 0 | ahead |
| Asleep (idea 5) | 0, 4.4 pt wide | 0 | 0 | closed |
| Rest clock (idea 10) | **still** (Product): it holds whatever it was | | | on the clock |

- Transitions: every change of shape takes 250 ms, ease-in-out. The mouth never animates on its own, never loops
  and never talks.
- Setting: the mouth comes with "Tess has eyes" (Product: no mouth without eyes). There is no separate switch for
  now. If he wants eyes without a mouth later, that's a second row under the same heading.
- `.live`: shown, at rest, idle shape only. Live things own their surface.
- Reduce Motion: shapes change with a 150 ms crossfade, no glance offset.
- Low Power: the same as Reduce Motion.
- Build: `SoulMouth` beside `SoulEyes`, drawn in the same overlay and from the same frame (`SoulEyes.centre(of:)` + 2.6 ×
  scale). The router exposes `expression: SoulExpression` (curve, tilt, open), derived from mode plus overlays,
  so no view picks a face. Test: every mode maps to its row above, and no event other than `claudeFailed` produces
  a corner below the middle.

## 18d. Sleep (idea 5), she watches what you hold (idea 6), the rest clock (idea 10)

### Idea 5: she sleeps at night
| | |
|---|---|
| When | Quiet hours, 23:00 to 07:00 (Product's quiet hours). Before this, as-built `resting` started at 23:00 and ended at 06:00, so this sheet moves her wake to **07:00** to match quiet hours. |
| What she does | Lids at 0.25 and no blink. Her clock runs at 0.45× (breath and drift slow). Saturation −0.35, scale 0.92. The mouth is flat and narrow. |
| When he opens the app | The **right eye opens first** (250 ms after the page arrives, over 350 ms, glancing 0.4 left and 0.3 up), and the left follows 2.4 s later over 400 ms. Over 1.2 s her clock comes back to 1×, and saturation and scale return over 1.5 s. She stays awake while he's in the app. Left alone for 60 s, she drifts back to sleep over 3 s. |
| Not a wake | Opening at night is not idea 2's wake. Idea 2 waits for the first open after 04:00 that is outside quiet hours. |
| Eyes off | The slow breath, the colour and the size only. |
| `.live` | Never. A live workout at night is awake. |
| Reduce Motion | The same values, with no clock slow-down (her clock is already paused) and crossfades instead of eye opens. |
| Low Power | The same. |
| Test | At 23:30, opening the app opens the right eye first. At 06:59 she is asleep; at 07:00 she is not. |

### Idea 6: she watches what you hold
| | |
|---|---|
| Trigger | `rowLifted(rect)` / `rowMoved(rect)` / `rowDropped` from any reorderable list (§20). |
| What she does | The eyes follow the held row's centre: x −1 (toward the list), y clamped to (row y − her y) / 600. On the drop, one blink 200 ms after, then back ahead over 300 ms. |
| Mouth | At rest. |
| Eyes off | Nothing. |
| Refused while | Working (she's split) or carried. |
| Reduce Motion | No glance (§1). Nothing. |
| Test | While a row is held at y 400, the eyes' y look is −0.63. After the drop, one blink. |

### Idea 10: she watches the rest clock (Product: eyes only)
| | |
|---|---|
| Trigger | `.live` page, rest timer in its last 10 s: `restEnding(rect)`. |
| What she does | **Eyes only**: they move to the timer (−1, −1) over 300 ms and stay there. At Go they come back over 300 ms, with one blink at Go + 100 ms. There is no lean (the clip's 4 pt lean is cut), and no colour, sound, haptic, ask or mouth change. |
| Eyes off | Nothing. |
| Why it's allowed | It is his own timer, and her eyes are the only thing that moves (Product's narrow exception to "she never looks around in a live workout"). |
| Reduce Motion | Nothing. |
| Test | `restEnding` changes the gaze and nothing else on the router's state. |

## 18e. Nudge (idea 7), she hears you type (idea 8), the peek (idea 9)

### Idea 7: a nudge before the next thing
| | |
|---|---|
| Trigger | `upcoming(rect)`: 10 minutes before anything with a clock time (a task, an event, a workout, a habit with a time), emitted by Core's scheduler once per item. |
| What she does | One lean of 4 pt toward the item's row (0.6 x, 0.8 y), out over 400 ms ease-out, held 1.3 s, back over 500 ms on the house curve. The eyes go to the row, with one blink at the end. The mouth is at rest. |
| Where | Only when the app is open and the item's row is on screen. Otherwise nothing: it's not a notification. |
| Quiet hours | Never. |
| Eyes off | The lean only. |
| `.live` | Never. |
| Reduce Motion | Eyes only, no lean. With eyes off too, nothing. |
| Low Power | The same as Reduce Motion. |
| Test | One `upcoming` per item. A second emit for the same item does nothing. |

### Idea 8: she hears you type
| | |
|---|---|
| Trigger | `wordTyped` from the capture field (a space or punctuation after a letter), while listening. |
| What she does | One pulse: scale +0.06 over 80 ms, back over 250 ms. There's no glow or haptic. |
| Mouth | At rest. It never mouths his words (18c: the mouth never talks). |
| Rate | At most one pulse per 180 ms. Faster typing merges pulses, so it never reads as a typing indicator. |
| Eyes off | The pulse only. |
| Reduce Motion | No pulse. Nothing. |
| Low Power | Pulses at most every 400 ms. |
| Test | Four words typed within 300 ms give at most two pulses. |

### Idea 9: she peeks at the end of a list
| | |
|---|---|
| Trigger | `reachedEnd`: the page's scroll reaches its last row (within 8 pt) once per page visit. |
| What she does | She rises 5 pt over 350 ms ease-out, holds 1.6 s, and comes down over 500 ms on the house curve. The eyes look up at 0.5 x / 1 y in step, with one blink at the top. |
| Not while | Roaming, working, carried, or with an ask waiting. |
| Eyes off | The rise only. |
| `.live` | Never. |
| Reduce Motion | Nothing. |
| Test | Two scrolls to the end in one visit give one peek. Leaving and coming back gives another. |

## 18f. She sits under the glass (idea 11), last
| | |
|---|---|
| Input | `CMMotionManager` device attitude at 30 Hz, low-passed (0.15), only while the app is foreground, her page is on screen, and **neither Reduce Motion nor Low Power is on** (Product). |
| What she does | The mains shift up to ±2 pt x and ±1.4 pt y, and the satellites ×1.7 of that. The eyes look ±0.6 / ±0.4 the same way, and the mouth follows the eyes. |
| Off when | Carried, working, listening, `.live`, Speak, cook mode, or the phone flat on a table (attitude within 3° of flat for 2 s): nothing to look under. |
| Battery | Motion updates stop with her `TimelineView`. Energy log run (a) of the check kit has to stay Low with it on. |
| Test | With Reduce Motion on, no motion manager is started. |

---

## 20. One signal map, every area (with AI architecture)
The map lives in AI architecture's `docs/ai/soul-signals.md` (#418): one pure Core diff over the `HomeFact`s every
area already reports, at most one §14 event per change, and the size of the moment (finished, best, ticked,
started, done elsewhere, night) decides the reaction, never the area. There are no model calls, and no private signal
(money amounts, notes, people, health) moves her. The lab's review asked for three changes there:
- His own start is not a roam. Only a start made by her or from elsewhere is.
- The pour only plays on a live surface. A finish seen from a page is the full beat.
- It adds the rows these picks need.

The picks add these events, which come from views and not from the diff:

| Event | Emitted by, in every area | Idea |
|---|---|---|
| `askClaude(kind, touched:)` | every Claude call; `touched` comes from the pack builder through `ClaudeClient`, stays on the phone, and is never sent to Claude (soul-signals.md) | 1 |
| `firstOpenOfDay` | the router, from `AppClock`'s 04:00 boundary, outside quiet hours | 2 |
| pan across her | `BottomChrome`'s band (every page has the band) | 3 |
| `taskDone`, `thingFinished` (counted) | the diff above | 4 |
| `rowLifted / rowMoved / rowDropped` | every reorderable list: Home, Routines, Groceries, Habits, Kitchen week | 6 |
| `upcoming(id)` | Core's scheduler, once per timed item | 7 |
| `wordTyped` | the capture field | 8 |
| `reachedEnd` | every scrolling page | 9 |
| `restEnding` | the live workout only | 10 |
| `sideTurned(direction)` | the one `SideHost` (sheet 75), on the move into stop 1 (right) and the move that lands on the front (left), never between stop 1 and stop 2 | side |

`sideTurned` (sheet 75, every screen has a side): eyes only, 0.4 toward the incoming content over 380 ms on the house
spring, then ahead over 300 ms; the mouth follows at 70%. She and the band are part of the spine and never move with the
body. Only when she's idle or roaming; nothing with eyes off, under Reduce Motion or in `.live`. Her side line lands
when stop 1 settles (420 ms). No haptic of hers; stop 2's `.selection` is the side's. Reference
`recordings/picks/tess-pick-side.mp4`. Test: a `sideTurned` while working, listening or asking leaves the router's
state unchanged; stop 1 to stop 2 emits nothing.

## Build order and rows
Builder A, one PR per sheet, in this order: 18a, 18b, 18c (mouth), 18d, 18e, 18f. Each PR carries its router
events, tests and a clip recorded per the check kit, and the lab checks it frame by frame (item 16). Builder B
adds emitters in its areas (§20) as each PR lands. Core adds `touched` from each pack builder (18a), `upcoming` and `firstOpenOfDay`
(18a, 18e) and moves resting's end to 07:00 (18d).
