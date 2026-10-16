# QA review 264: calm capture (#264)

Merge cc1da97, head f917b00, 12 files (+152/-107, plus docs/recordings/calm-capture.mp4). Static review; no toolchain here.

**Verdict: PASS.** No reverts against the first parent. No blockers.

## What it does
- **Calmer capture surface** (BottomChrome.swift):
  - The open veil is now material at 35% plus paper at 50%.
  - The wash is 380 pt, opaque from 22% of its height, with no cobalt warmth.
  - The soul swells 1.06 instead of 1.35. Mode rows are 48 pt in `bodyStrong` with smaller dabs, and the spring is damped to 0.85.
  - There is one question ("Tell me a set." in a workout, else "What's on your mind?") and at most one fast path (Back to / Start). "Today" and the two typed suggestions are gone.
  - The field prompt is "Write anything", and the drying ghost reads in `inkSecondary`.
  - The dry line is 2.5 pt and drains right to left (`1 - drying`, leading anchor).
- **SQ8 set-count ask in the UI**:
  - After a non-question capture, `model.pendingSetAsk` turns the line beside the soul into "2 × 10: **2 sets**, or **2 kg**?" with two `valueWash` answer words (BottomChrome.swift:138-158).
  - A tap calls `AppModel.answer(_:)`, which goes through `TessCaptureEngine.answer` and the shared `land(_:)`, so ghost rows and drying behave exactly like a capture (AppModel.swift:171-184).
  - A new open clears it (`opened()`), and the engine also drops the ask on the next phrase unless that phrase answers it (TessCaptureEngine.swift:31-36). The UI and the engine can't disagree on a logged set.
- **Closes review-246 R3:** "Reinstalled?" now counts every non-system op over the last 2000 (BackupView.swift:70). Before, it counted only `.user` ops over the last 50.
- **Closes review-246 L4:** `BackupKeeper.forget()` clears the folder failure note.
- **Undo copy** follows the undo rule (name the thing, then what happened): "Stretch & mobility, done." (HomeQueue.swift:451, NowPage.swift:196).
- **Smaller fixes:**
  - The Claude section line without a key now reads "No Claude key on this phone. Paste one to let Tess ask Claude."
  - The `PasteRecipe` dry animation now honours Reduce Motion; before, it was hard-wired to `false`.
  - A trained day's dab lands wet and then dries to its rest tint (`TrainedMark`, no-dots).
  - Today's wet tip keeps the stroke's own gradient instead of amber.
  - RestHero's two small lines are in `inkSecondary`.
- **UITest:** the HomeQueue row match now also requires ":" in the label, so it can't match the "Stretch & mobility, done." line.
- **APIs exist on master:** `.valueWash`, `.labelWord`, `Theme.Colors.restTint`, `Theme.Motion.dry`, `TessSetCountAsk.setsAnswer` / `kilogramsAnswer`. The `Tessera.TessVoice` qualifier is needed now that BottomChrome imports TesseraTess.

## The coordinator's two notes
- **`ValueWordStyle` is unused** (BottomChrome.swift:642). Confirmed: nothing references it after the fast paths moved to `.labelWord`. **Low, C1:** delete it.
- **Recording frame rate:** I measured it with ffprobe. 724 of 734 frame gaps are 17.3 ms, which is about 58 fps while anything moves. The 10 longer gaps (35 to 380 ms) are still moments, because the Simulator recorder writes a frame only when the screen changes. There are no dropped frames during the motion. **Pass.**

## Lows
- **C1:** delete the unused `ValueWordStyle`.
- **C2:** `answerAsk` calls `say(line)` even when the engine has already dropped the ask, which leaves a blank line for 4 s. This can happen when a phrase from Siri or a widget lands between the ask and the tap: `answer` then returns `line: ""` (TessCaptureEngine.swift:94). Fix: guard `!line.isEmpty`, or check `pendingSetAsk` before drawing.
- **C3:** while a set-count ask is drawn, it takes the place of every other line beside the soul, including a Home "…, done." line and its UNDO. That is fine inside a workout. Outside one, the ask only arises with an exercise in focus, so it's rare, but `setAsk` should also clear when the workout ends.
- **C4:** "Reinstalled?" counts settings ops, while Core's `userOps` doesn't. Once SettingsStore writes the look as a `.user` op (Builder B's next item), a look tap on a fresh install will hide the line. Fix: exclude the settings class, to match `userOps`.
- **C5:** the dated-lift ask ("Bench 80 × 8 for Monday?") still shows only as a spoken line, with no LOG / NOT NOW words. This is already queued for Builder B after #251.
