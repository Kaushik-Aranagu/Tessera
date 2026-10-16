# One way Tess asks (Design item 35)

Every on-screen ask follows one pattern: the set asks, the dated lift, "81 for how many reps?", the radiators, the calendar ask and the weigh-in ghost. It sits where Tess already speaks (`day-seams.md` S1) and uses the ink-word language (`no-buttons.md`, `ink-line.md`). Q10 holds: there are no yes/no asks in a live workout. Where an earlier sheet draws an ask differently, this sheet wins; the sheets keep their own words.
- Board: `mockups/one-ask.png` (source `studies/one-ask.html`), Porcelain. It shows the six asks in the one form.
- Recording: `recordings/one-ask.mp4` (28s). His phrase raises a choice, the wait, a tap answers, the next ask waits for UNDO to go, leaving answers "not now", and saying the answer works too.

## The ask
- **Where:** Tess's line beside the soul, trailing, 270pt wide, in cobalt Body 21, at most 2 lines, ending with "?". It's the same slot on every screen: Home, a page, the live workout. Nothing on the page moves to make room, and the ask never leaves Tess's band (736 to 820).
- **The two ink words:** under the question, where UNDO sits, trailing, 30pt apart: label words at 16/700 in `ink`. **Always exactly two.** The likelier answer comes first.
  - A **choice** names both answers: "2 SETS · 2 KG", "KG · REPS".
  - A **yes-or-later** ask names the doing word, then the leaving word: "LOG · NOT NOW", "CONNECT · NOT NOW". **Every ask that writes a record uses LOG**; KEEP means holding on to something already there. The radiators keep their own pair, "KEEP IT · NO RADIATORS", because the second answer is final.
  - An **open** ask ("81 for how many reps?", "Bench 3 × 8 at what weight?") offers its two likeliest answers, picked by Core: the last value for that lift and the plan's value, or the last value and one step from it when they're the same ("8 · 10", "80 KG · 82.5 KG").
  - No value words inside the question any more. The build's "2 × 10: **2 sets**, or **2 kg**?" with tappable words in the line becomes a plain question with the two words under it, so every ask is tapped in the same place.
- **The words in the question** are Research's and Core's as they stand (`tess-voice.md`, the grammar's ask lines).

## Answering
- **Tap a word:** the ink line draws under it (150ms, house curve) with `.selection`. The other word fades (200ms). The question blurs out and Tess's answer takes the line, with UNDO under it when it wrote something ("Logged bench 2 × 10 at 80." · UNDO).
- **Say or type the answer** and it's the same as the tap: a word from either answer ("sets", "kilos", "log", "not now", "keep it"), or any value for an open ask ("8", "82.5").
- **A ghost on the page is part of its ask.** The weigh-in waits as a ghost at y 652, "Body weight **82.4** kg" (no question mark now), and Tess asks "82.4 kg as today's weight?" with LOG · NOT NOW. Tapping the ghost is LOG, and swiping it away is NOT NOW. After LOG, Tess says "82.4 kg logged for today." with UNDO, and UNDO says "82.4 kg taken back." Tess's old "Tap to keep it." (T1) becomes this ask. **The weigh-in ghost never shows during a live workout** (Q10): a weigh-in said mid-workout follows D12 in `body-weight-page.md`.

## The wait
- An ask waits until it's answered or he leaves. It has no timer.
- **Nothing dries while it waits.** A ghost tied to the ask stays wet and breathing (0.5 to 0.66), and nothing commits by itself.
- **The soul shows the wait, quietly:** its breath slows from 3.2s to 4.8s and it leans 4pt toward her line. No glow, no colour, no haptic.
- VoiceOver reads the question, then "2 sets, button. 2 kg, button." Reduce Motion: crossfades, no lean.

## Leaving
**Leaving is "not now", and it writes nothing.** Leaving means changing tab or page, saying or typing something that isn't an answer, or the app going to the background.
- The ask folds (blur out, 200ms), and Tess says nothing.
- His own new phrase replaces the ask (the engine already drops it, QA C2).
- **Each ask comes back only by its own rule:**
  - The set ask, the dated lift and the open asks never come back. He says it again if he meant it.
  - The radiators come back the next day (Oct 1 to Nov 30, until answered).
  - The calendar ask comes back at the next first open of Plan my day.
  - The weigh-in ghost stays on the page until 04:00. From Today it waits as Next's first row (`body-weight-page.md`).

## One at a time
- **Only one ask shows.** An ask and an UNDO line never share the slot: an ask waits for the UNDO to go (or for the 10s to end).
- **Who goes first:** an ask from his own phrase, then a live-workout ask, then an ask the app raises (the calendar, the radiators). An app ask never interrupts: it waits until the slot is empty, and it never shows during a live workout or in quiet hours (23:00 to 07:00).
- If an app ask is still waiting when its moment passes (he left Plan my day or Upkeep), it's dropped for now and comes back by its rule.

## In a live workout (Q10)
- **No yes/no asks.** Only a choice ("81: KG · REPS", "10 × 8: 10 SETS · +10 KG") or an open ask with its two likeliest answers ("81 for how many reps?" · 8 · 10).
- A dated lift said mid-workout ("bench 80 × 8 Monday") isn't asked there. It waits and asks on Today when the workout finishes.
- The statements Product set for Q10 ("Say the set, like 85 × 8.", "Skip is on the workout screen.") are lines, not asks: no ink words.
- Saying the answer is the usual way mid-set, so the open ask's two words are a convenience, not the only path.

## Never
A sheet, a modal or an alert for an ask; two asks at once; an ask over an UNDO; a timer that answers for him; a yes/no in a live workout; colour or dots on the ink words; an ask in quiet hours that he didn't start.

## Owners
- **Builder B:** the ask slot in `BottomChrome` for every ask: the question, the two ink words under it, the tap with its ink line, the fold on leaving, the queue (one at a time, waiting for UNDO), the soul's wait, the weigh-in ghost as part of its ask, and moving the set ask's answers out of the line.
- **Builder A:** the live-workout asks in the same slot (`LiveTessCorner`), and the ghost on the Body weight page.
- **Core:** every ask exposes its question and two answers (`TessCapture.asking`, including the open asks' two likeliest values), spoken and typed answers to any ask, a new phrase dropping the ask, the dated lift held until the workout ends, and each app ask's come-back rule.
