# A calmer Ask Tess capture (build sheet, Kaushik's 6:45 PM correction)

Kaushik said the capture surface's type is too big and too cluttered. He wants it neat, calm and peaceful. This sheet takes the surface in `Features/Command/BottomChrome.swift` down one tier everywhere, removes three things, and gives it more air. The behaviour doesn't change: tap the soul, then Speak, Write or Show, then Return, a 2s drying line, and the commit.

Recording: `recordings/calm-capture.mp4` (source `studies/calm-capture.html`, drawn in Porcelain): open, Write, type "bench 82.5x8", Return, Tess answers.

## What changes
| Part | Today | Calm |
|---|---|---|
| Mode words (Speak, Write, Show) | Title 34/500 (`modeFont`) | **Body 21/500**. The active word is ink; the other two are `inkSecondary` (60%) |
| Mode rows | `rowHeight` about 64 | **48pt** |
| Mode dabs | 22×18 | **16×14** |
| The question line | Body 21 cobalt | unchanged: one line, "What's on your mind?" |
| Fast paths | up to two value words at Body 21 with " · " | **at most one, as a label word** (16/700 uppercase, `inkSecondary`), e.g. "START PUSH DAY A", 12pt under the question |
| Typed text | Title 34/500 | **Body 21/400 ink** |
| Placeholder | "log 82.5×8, or ask" | **"Write anything"** at `inkTertiary` (38%) |
| Suggestions under the line ("log bench 82.5x8 · bench best?") | always shown | **removed** |
| The wash | the ground at 95%, 470pt, cobalt warmth in the corner | **the ground at 96%, 380pt, fully opaque from 22% of its height, with no cobalt warmth.** The page under it blurs 1.5pt and drops to 50% |
| The page behind | recedes | recedes less: scale 0.985 |

## Motion, calmer
- **Modes rise** with less bounce: the spring goes from damping 0.68 to **0.85** (response 0.46). The x-slide of the words drops from 24pt to **0**: they fade in place, and only the dabs rise out of the soul. The stagger stays 40ms.
- **The soul** swells to 1.06 on open (it was 1.14 at the peak), with no second beat.
- **The question and the fast path** fade in 220ms after the tap (300ms, house curve). Nothing else moves.
- **Write:** the other two modes, the question and the fast path fade out (200ms). Then the writing line draws from the right (420ms), as today.
- **Commit:** the drying line and the ghost stay as they are. Then the whole surface fades back into the soul (220ms), and Tess answers beside it in cobalt with **UNDO**.
- Reduce Motion: fades only.

## Layout (from the bottom)
- The soul stays at (346, 788).
- Mode rows sit right-aligned at y 620, 668 and 716.
- The question is at y 542, and the fast path at y 580.
- With Write open, the writing line sits at y 718, from x 22 to 368, and the text sits on it. The keyboard pushes the writing line up; nothing else is on screen.

## Never
- More than one fast path.
- Example commands under the line.
- Any word on the surface at Title size.
- A dab bigger than 16×14.

## Owner
Builder B, in `Features/Command/BottomChrome.swift` (`surface`, `writing`, `modeFont`, `ModeRow`, `CaptureWash`). `LiveAskField` in the workout gets the same type and placeholder.
