# A calmer Ask Tess capture (build sheet, Kaushik's 6:45 PM correction)

Kaushik said the capture surface's type is too big and too cluttered. He wants it neat, calm and peaceful. This sheet takes the surface in `Features/Command/BottomChrome.swift` down one tier everywhere, removes three things, and gives it more air. The behaviour doesn't change: tap the soul, then Speak, Write or Show, then Return, a 2s drying line, and the commit.

Recording: `recordings/calm-capture.mp4` (source `studies/calm-capture.html`, drawn in Porcelain): open, Write, type "bench 82.5x8", Return, Tess answers.

## What changes
| Part | Today | Calm |
|---|---|---|
| Mode words (Speak, Write, Show) | Title 34/500 (`modeFont`) | **Body 21/500**. The active word is ink; the other two are `inkSecondary` (60%) |
| Mode rows | `rowHeight` about 64 | **48pt** |
| Mode dabs | 22×18 | **16×14** |
| The question line | Body 21/500 cobalt, one of three lines, shown while typing too | **Body 21/400** (`Theme.voice`), `tess`, one line, shown on the mode layer only. "What's on your mind?" everywhere, or "Tell me a set." in a workout. "Log it, ask, or note it." goes: it's a command list |
| Fast paths | up to two value words at Body 21 with " · " | **at most one, as a label word** (16/700 uppercase, `inkSecondary`, `lineLimit(1)`, truncating at the tail), e.g. "START PUSH DAY A", 12pt under the question. **"Today" is dropped** (a double tap on the soul already goes home), so a page with no workout shows no fast path |
| Typed text | Title 34/500 | **Body 21/400 ink** |
| Placeholder | "log 82.5×8, or ask" | **"Write anything"** at `inkSecondary`, set with `TextField(prompt:)` so its colour is a token. Not `inkTertiary`, which is 34pt and up only (themes.md) |
| Suggestions under the line ("log bench 82.5x8 · bench best?") | always shown | **removed** |
| The wash | the ground at 95%, 470pt, cobalt warmth in the corner | **the ground at 96%, 380pt, fully opaque from 22% of its height, with no cobalt warmth.** The page under it blurs 1.5pt and drops to 50% |
| The page behind | recedes | recedes less: scale 0.985 |

## Motion, calmer
- **Modes rise** with less bounce: the spring goes from damping 0.68 to **0.85** (response 0.46). The x-slide of the words drops from 24pt to **0**: they fade in place, and only the dabs rise out of the soul. The stagger stays 40ms.
- **The soul** swells to 1.06 on open (it was 1.14 at the peak), with no second beat.
- **The question and the fast path** fade in 220ms after the tap (300ms, house curve). Nothing else moves.
- **Write:** the other two modes, the question and the fast path fade out (200ms). Then the writing line draws from the right (420ms), as today.
- **Commit:** the drying line stays as it is. The ghost text is Body 21/400 at `inkSecondary`. Then the whole surface fades back into the soul (220ms), and Tess answers beside it in cobalt with **UNDO**.
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

## Research's capture check (#189, `docs/research/capture-type.md`): these win
- **Every Tess line is Body 21/400** (`Theme.voice`): the question, the reply beside the soul and the miss line. Nothing on the surface is 500 except the mode words.
- **Mode words** use `textRole(.bodyStrong)`, not a new `modeFont`, so tracking and line height match the tier. Today's `rowHeight` is 70; it becomes 48.
- **The miss line is just "Didn't catch that."** It has no example command, so it's one line (`TessModel.swift:68`).
- **UNDO** is Label 16/700 in full `liveInk` (themes.md). The 0.85 multiplier goes.
- **Show, when it's built:** one label word naming the kind ("PHOTO", "PDF") above the ghost, then the same reply and UNDO. No filename at Body size.
- **Every opacity is a token:** `ink`, `inkSecondary`, `tess` or `liveInk`. The literals 0.55, 0.75, 0.6, 0.45 and 0.85 all go.

## Addendum (16 Oct, 1:08 AM PT): his typing smaller than her voice
Kaushik's phone review: the Ask Tess text is too big. The installed build already had the typed text at Body 21 (f917b00), so the field needs a smaller role. The rule: **his typing sits one step under her voice**, so what he writes never out-sizes what she says.

| Element | Was | Now |
|---|---|---|
| Typed text | Body 21/400 ink | **Field 18/400 ink**, a new role in `Theme` (`field`: Inter Tight 18, regular, line height 1.33, `textStyle: .callout` so Dynamic Type scales it with the rest) |
| Placeholder "Write anything" | Body 21 `inkSecondary` | **Field 18** `inkSecondary` |
| The ghost text at commit | Body 21/400 `inkSecondary` | **Field 18** `inkSecondary`; the drying line sits 5pt under it instead of 7 |
| The question line ("What's on your mind?") | Body 21/400 `tess` | unchanged, Body 21 |
| Tess's reply beside the soul, the miss line | Body 21/400 `tess` | unchanged, Body 21 |
| Mode words (Speak, Write, Show) | Body 21/500 | unchanged |
| The fast path label | Label 16/700 | unchanged |

- 18 keeps the 16pt floor and the scale's steps (16, 18, 21, 34, 44, 56 are each about 1.15× to 1.6× apart); 17 would be a size with no neighbour.
- The same Field 18 goes wherever he types in a line: the Notes writing line and a note's first line, the recipe paste, the `LiveAskField` in a workout, the Settings key field. A note's body (long text) also reads at Field 18. Tess's lines everywhere stay Body 21.
- Builder B: `Theme.Type.field`, `BottomChrome.swift` (`surface`, `writing`), `WritingLine` in `NotesView.swift`, `NoteEditor.swift`, `PasteRecipe.swift`, `LiveAskField`, `ClaudeSection.swift`'s key line. One tiny PR, then the capture recording re-cut.

