# Soul signals: one reaction per kind of moment, in every area

For: Tess motion lab, Builder A (the router), Core (the diff). Owner: AI architecture team, with the motion lab.
Product's board, motion.md item 20. Date: Oct 16, 2026 (Pacific).

Kaushik asked that Tess react the same way in every area. Today only the workout and the capture surface send her events. Every other area changes without her noticing, so she reacts to a set but not to a cooked dinner or a finished shop. This sheet maps the signals the phone **already computes** to the events of the motion lab's contract (`docs/design/motion/tess-motion.md` §14). **There are no new model calls.** Claude is never asked how she should move. The screen-aware Tess stays parked (`docs/ai/parked.md`).

_Amended Oct 19: with "Tess reads the screen" on, a small model may pick the move; default Off; she never waits on it. See `design/motion/tess-reads-the-screen-motion.md`._

## 1. The one source: Home's facts, diffed

Every area that has a "thing" already reports it to Home as a `HomeFact`: workout, cook, shop, task and rest, each with a `kind`, a `state` (planned, running, paused, done), `step` of `steps`, `records`, `toBuy` and `endedAt` (`TesseraCore/Home/HomeLines.swift`). So the router doesn't need a hook in each feature. It needs one diff.

**`SoulSignals.events(from: old, to: new, op:)`** (Core, pure, unit-tested): this compares the facts before and after a store change, keyed by `id`, and returns at most **one** event per change. Home's model calls it on every store change and passes the result to `soul.handle(_:)`. Areas that already send their own events (the workout, the capture surface) keep them. The screen tags the op it sent an event for, and the diff skips a tagged op, so a slow store write can never react twice. The op's origin (his touch, an ask, Siri, a widget, the scheduler) is also what tells a start he made from one he didn't.

## 2. The map

One rule decides the reaction: **how big the thing is, never which area it's in.**

| Kind of moment | Signal the phone already has (diff of `HomeFact`) | Event (§14) | What he sees |
|---|---|---|---|
| **A whole thing finished** (workout, cook, shopping trip, a book) | `state` becomes `.done` on a workout, cook or shop fact; a book's position reaches its last page | `thingFinished` (`workoutGathered` on the workout's corner, as built); the router picks by page | on a live page (the workout's corner, cook mode's corner) **Done**, the pour; seen from any other page **the beat** at full gather (§6: Done's pour never plays for a done row) |
| **A best inside it** | `records` grows (`set.wasRecord` already sets it) | `newBest` | thinking 1.2 s, then Done, in place of the plain Done (never both) |
| **One part ticked** (a task, a habit, a grocery row, a cook step, a shopping row) | a task fact leaves Home as done; `step` moves forward; `toBuy` or items-left goes down | `taskDone` | the **beat** (940 ms), no pour |
| **Something started, not by his hand** | `state` goes from planned to running, and the op came from an ask (Plan my day), Siri, a widget or the scheduler | `rowChanged(rect)` | **roam** to that row (§3); never in Low Power, listening or carried |
| **Something he started** | the same change from his own touch, or a start that opens a live surface (a workout, cook mode) | none | nothing: his finger is already there, and live things own their surface |
| **Coming up** | Core's scheduler, 10 min before anything with a clock time, once per item | `upcoming(id)` | the nudge (motion lab idea 7, `tess-picks.md`) |
| **First open of the day** | `AppClock`'s 04:00 boundary, outside quiet hours | `firstOpenOfDay` | she wakes with him (idea 2) |
| **She's working on something** | a Claude job running, with `touched: [ObjectID]`, the objects it reads or changes in the order it uses them | `askClaude(touched:)` | lights that follow the page (idea 1) |
| **Something waiting came back** | `state` goes from paused to running | none | nothing: he's already there |
| **Paused or left** | running becomes paused, or a fact drops off unfinished | none | nothing. She never reacts to stopping |
| **Done while he wasn't looking** (Siri, a widget, the 6 h auto-finish) | any row above whose change came in while the app was in the background | `doneElsewhere` | the beat at foreground, once for the lot |
| **A line from her** (the week's lines at Sunday 04:00, the day roll) | `WeekFacts` or `DayStory` turnover | `returnLine` | idle + the glance |
| **Today's colour** | the living-colour rule table's pick (AI-14) | `paletteChosen` | the repaint, idle only |
| **Night** | Shutdown 21:00, quiet hours 23:00 to 07:00 (Core's scheduler) | `shutdown`, `quietHours` | resting |

**Areas with no "thing".** A spend that is logged, a note that is saved and a person who is added all send `committed`, the same brighten as a capture. Logging a spend never gets more than that, because she doesn't celebrate spending. A bill marked paid is a task, so it beats like any other done task. Body weight and anything from Health never move her at all. Lens facts and `TessMemory` don't move her yet: glancing at a changed Home line is a later idea, and noticed lines belong to the parked agent.

**`touched` on a job.** `TessJob` is a static descriptor, so `touched` rides on the call: the pack builder returns the object ids it packed, in the order it uses them, and `ClaudeClient` hands them to `askClaude`. It lists only objects already in that pack, it stays on the phone, and it is never sent to Claude. Jobs with no objects (the key check) send an empty list.

## 3. Rules that keep it one Tess

- **One event per moment.** This matches the one-haptic rule (`task-reward.md`). When a change fits two rows, the higher row wins (finished beats ticked, a best beats finished), and the router's order (§14) settles anything left.
- **Same size, same reaction.** A cooked dinner is the same size as a finished workout. A ticked grocery row is the same size as a ticked task.
- **The phone decides.** Every row comes from counts and states already on the phone. Claude's lines, the pack and the switch play no part, and with "Tess asks Claude" off she reacts exactly the same.
  _Amended Oct 19: with "Tess reads the screen" on, a small model may pick the move; default Off; she never waits on it. See `design/motion/tess-reads-the-screen-motion.md`._
- **No private signal moves her.** The diff reads only `HomeFact` fields, which hold titles, states, counts and times, the same promise Settings makes.
- **Demo days react too.** The diff doesn't care where the data came from, so the demo recording shows the same moments.

## 4. Owners and order

1. **Core:** `SoulSignals.events(from:to:op:)` with a test per row of the map (planned→running by his hand and by an ask, step +1, done, records +1, done in the background, a pause producing nothing, a tagged op producing nothing); `upcoming` and `firstOpenOfDay` from the scheduler and `AppClock`; `touched` from each pack builder through `ClaudeClient`.
2. **Builder A:** add `taskDone`, `thingFinished`, `doneElsewhere`, `rowChanged`, `paletteChosen`, `upcoming`, `firstOpenOfDay` and `askClaude(touched:)` to `SoulEvent` and route them per §14, with `thingFinished` pouring only on a live page. Home's model calls the diff; the workout and the capture surface tag the ops they react to.
3. **Motion lab:** passed the map with these changes (Oct 16); records the reel: one finished cook seen from Home and in cook mode, one ticked grocery row, one task, one best. View-level events (row lift, move and drop, reaching the end, a word typed, rest ending) are in the lab's `tess-picks.md`, not here.
