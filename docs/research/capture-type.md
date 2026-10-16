# Capture surface type audit (board item 58)

Kaushik: the Ask Tess capture surface type is too big and too cluttered; he wants it neat, calm and peaceful. This audits every text element on origin/master (`77ec470`) against the four tiers in `docs/design/type-and-motion.md` and compares a calmer set with Design's `docs/design/calm-capture.md` (branch `claude/project-thread-b3tu3f`). Read only; nothing in the repo was changed.

Code: `Features/Command/BottomChrome.swift` (BC), `Features/Home/NowPage.swift` (NP), `Features/Workout/WorkoutParts.swift` (WP), `TesseraCore/Sources/TesseraTess/` (TT). Plein scale on master: Title 44/500 (-3.5%), Body 21/500 (`textRole(.body)` keeps the spec weight, 500), Label 16/700 uppercase +8%. `Theme.voice` is 21/400.

## States used below
- **Idle**: surface closed, the soul alone in the corner (`resting`, BC:120).
- **Listening**: soul tapped, surface open on the mode layer (the soul's mode is `.listening`, BC:363). Speak itself is not built; tapping it closes and says "Speak comes next." (BC:258).
- **Typing**: Write tapped, the write layer (BC:240, 267).
- **Ghost**: Return pressed, the 2 s drying line (BC:382), then the ghost row on Home after the commit (NP:278).
- **Miss**: Tess wrote nothing and says so.
- **File**: Show / file capture. Not built on master (Show says "Show comes next."), so it is listed as a placeholder for the photo/file work in `capture-modes.md`.

## Every text element on master
| # | Element | file:line | Size / weight | Colour token | Lines | Shows when |
|---|---|---|---|---|---|---|
| 1 | Reply / launch note beside the soul | BC:125-130 | Body 21/**500** (`textRole(.body)`) | `tess` | 2, max 270pt wide | Idle, after any reply, 4 s (BC:441) |
| 2 | UNDO | BC:134-135, style BC:550 | Label 16/700 upper | `live` (vermilion) at 0.85 | 1 | Idle while `lastCapture` (4 s) or a Home undo exists |
| 3 | Question: "What's next?" / "Log it, ask, or note it." / "Tell me a set." | BC:190-195, 220-222 | Body 21/**500** | `tess` | none set | Listening **and** typing (it is outside the `layer` check) |
| 4 | Fast path 1: "Start Push Day A" / "Back to Push Day A" | BC:198-210, 229-230, style BC:571 | Body 21/600 | `ink` 1.0 | none set | Listening, when a workout is on or running |
| 5 | Separator " · " | BC:227 | Body 21/500 | `ink.opacity(0.75)` (not a token) | 1 | Listening, two fast paths |
| 6 | Fast path 2: "Today" | BC:211-212 | Body 21/600 | `ink` | none | Listening, on any pushed page |
| 7-9 | Mode words Speak, Write, Show | BC:482-486, font BC:324 | **Title 34/500**, no title tracking | active `ink`, others `ink.opacity(0.55)` (not a token) | 1 | Listening (folded to 0 height in typing) |
| 10 | Typed text | BC:271-273 | **Title 34/500** (`modeFont`) | `ink` | 1 | Typing |
| 11 | Placeholder "log 82.5×8, or ask" | BC:271 | **Title 34/500** | system placeholder grey (not a token) | 1 | Typing, empty draft |
| 12 | Suggestion "log bench 82.5x8" | BC:304-314 | Body 21/400, `minimumScaleFactor(0.8)` so down to **16.8** | `ink` at 0.6 literal | 1 | Typing and ghost, always |
| 13 | Separator " · " | BC:308 | Body 21/500 | `ink.opacity(0.6)` literal | 1 | Typing and ghost |
| 14 | Suggestion "bench best?" | BC:304-314 | as 12 | as 12 | 1 | Typing and ghost |
| 15 | Ghost text (the typed words, dimmed) | BC:273 | Title 34/500 | `ink.opacity(0.45)` (not a token) | 1 | Ghost, 2 s |
| 16 | Ghost row title on Home | NP:292-295 | Body 21/400 (`Theme.voice`) | `tess`, breathing 0.5-0.66 | 1 | Ghost, 2 s after commit |
| 17 | Ghost row time "21:30" | NP:297-300 | Label 16/700 | `tess` | 1 | same |
| 18 | Miss line "Didn't catch that. Try "bench 80 x 8"." | TT/TessModel.swift:68, TessModelCapture.swift:41, 51; shown as #1 | Body 21/500 | `tess` | 2 (wraps at 270pt) | Miss |
| 19 | Grammar misses: "I don't know "x" yet.", "No workout today to log into.", "Couldn't save that." | BC:625, 632, 650-659 | as #1 | `tess` | 2 | Miss (question path) |
| 20 | Workout field (`LiveAskField`) text and placeholder "log bench 80x8, or ask" | WP:321-323 | **Title 34/500** (`InkWordType`) | `Paint.cream` | 1 | Typing in a live workout |
| 21 | Workout "Close" | WP:329 | Label 16/700 | `Paint.secondary` | 1 | same |

## Count of simultaneous text elements
| State | Master | Calm (proposed) |
|---|---|---|
| Idle | 0 (1-2 with a launch note and UNDO) | 0 |
| Listening | up to **7**: question, 2 fast paths + dot, 3 mode words (5 at Today with a workout) | **5**: question, 1 fast path, 3 modes (4 with no workout) |
| Typing | **5**: question, typed text or placeholder, 2 suggestions + dot | **1**: typed text or placeholder |
| Ghost (drying) | **5**: question, ghost text, 2 suggestions + dot | **1**: ghost text |
| Ghost row (after commit) | 4: reply, row title, row time, UNDO | 4, same elements, quieter reply weight |
| Miss | 1, but two lines with an example command inside | 1, one line |
| File | not built (1: "Show comes next.") | 1 to 2 when built (see below) |

## What breaks the tiers or crowds the surface
Worst first.
1. **Typed text and placeholder at Title 34/500** (BC:272, WP:322). Title is for object names and section words; a sentence being typed at 34 is the single loudest thing and why the surface reads big. The same font drives the mode words.
2. **Suggestions under the line** (BC:302-318). Three text runs that never change, shown even while drying, at an off-tier size (`minimumScaleFactor(0.8)` gives 16.8pt, neither 21 nor 18) and literal opacities. They are example commands, which the calm sheet bans.
3. **The question stays up while typing** (BC:219-222). It doubles the placeholder and pushes the writing line down.
4. **Two fast paths with a dot** at 21/600 full ink (BC:223-233): as heavy as the mode words. "Today" duplicates the soul's double tap.
5. **Tess speaks at 500, not 400** (BC:127, 221). The tier table says Tess and context lines are Body 400. The ghost row already uses `Theme.voice` (400), so the same voice has two weights.
6. **Opacities that are not tokens**: 0.55 (BC:484), 0.75 (BC:227), 0.6 literal (BC:308, 314), 0.45 (BC:273), 0.85 inside `InkLabelWordStyle` (BC:557), and the system placeholder grey. Tokens are `inkSecondary` 0.6 and `inkTertiary` 0.38.
7. **Miss lines carry an example command** ("Try "bench 80 x 8"."), which wraps to two lines at 270pt.
8. **No line limits** on the question and fast paths: a long workout name can wrap to a second line above the modes.
9. Mode words set with `.font` (BC:483), not `textRole`, so they miss the tier tracking and line height.

## Calmer set, compared row by row with calm-capture.md
| Element | Calm proposal (size / weight / token / lines) | calm-capture.md | Agree? |
|---|---|---|---|
| Mode words | Body 21/500 via `textRole(.bodyStrong)`; active `ink`, others `inkSecondary`; 1 line; 48pt rows | Body 21/500, ink / inkSecondary, 48pt | **Agree.** 48pt keeps the 44pt touch floor. Use `textRole`, not a new `modeFont`, so tracking matches |
| Mode dabs | 16×14 | 16×14 | Agree |
| Question | Body 21/**400** (`Theme.voice`), `tess`, 1 line, listening only | "unchanged", says it reads "What's on your mind?" | **Disagree on facts and weight.** Master has three questions, not that one, and sets it at 500. Use 400 like every Tess line. Keep "Tell me a set." in a workout; use one calm line elsewhere and drop "Log it, ask, or note it." (it is a command list) |
| Fast path | One only, Label 16/700 upper via `InkLabelWordStyle`, `inkSecondary`, 1 line, truncate tail; workout only | At most one, label word, inkSecondary, 12pt under the question | **Agree,** plus: drop the "Today" path entirely (double tap on the soul already does it), so a pushed page with no workout shows no fast path. Add `lineLimit(1)`; uppercase long workout names get wide |
| Separator dots | Gone | Gone (one fast path) | Agree |
| Typed text | Body 21/400 `ink`, 1 line | Body 21/400 ink | Agree |
| Placeholder | "Write anything", Body 21/400, `inkTertiary`, set with `TextField(prompt:)` so the colour is a token | "Write anything" at inkTertiary | Agree. Note `inkTertiary` is documented as "finished / inert things only"; a placeholder is inert, so fine, but say so in the token comment |
| Question while typing | Fades out | Fades out (200ms) | Agree; master shows it, so this is a real code change, not a restyle |
| Suggestions | Removed | Removed | Agree |
| Ghost text while drying | Body 21/400 at `inkSecondary` | "stays as it is" | **Disagree.** Master's ghost is the 34pt font at 0.45 (no token). Once the text is 21/400, dim it to `inkSecondary` so it stays readable during the 2 s cancel window |
| Reply beside the soul | Body 21/400 (`Theme.voice`), `tess`, 2 lines, 270pt | "Tess answers in cobalt" (weight not stated) | Agree on cobalt; add the 400 weight, which master does not use |
| UNDO | Label 16/700, keep `live` vermilion | "with UNDO" (colour not stated) | No conflict. Keep vermilion: it is the only key on screen and must be found inside 4 s. Drop the 0.85 multiplier for full token colour |
| Ghost row on Home | Unchanged (21/400 `tess`, Label time) | Not covered | Gap in the sheet; master already fits the tiers |
| Miss line | One line, no example: "Didn't catch that." Body 21/400 `tess` | Not covered | **Gap.** The "Never: example commands" rule should cover misses too (TessModel.swift:68). The miss log already records the phrase, so the hint is not needed |
| File (Show) | When built: a single 16/700 label naming the file kind ("PHOTO", "PDF") above the ghost, then the same reply + UNDO. No filename at Body size | Not covered | Gap; flag for the capture-modes build so it starts calm |
| Workout `LiveAskField` | Body 21/400 `Paint.cream`, placeholder "Write anything" in cream at 0.38, Close stays Label | Same type and placeholder | Agree |
| Wash, page behind, motion | No type impact | 96%, 380pt, no cobalt warmth; damping 0.85; no x-slide | Agree; out of scope here. Note master's spring is response 0.48, not the 0.46 the sheet implies, and `rowHeight` is 70, not "about 64" |

## For Builder B
- Touch: `modeFont` (BC:324, remove or make Body), `ModeRow` (BC:482-487), `surface` (BC:219-233: question weight, `layer == .modes` around the question, one fast path, no "Today"), `writing` (BC:271-318: font, prompt, delete the suggestions HStack, ghost opacity), `resting` (BC:125-128: `Theme.voice`), `InkLabelWordStyle` (drop 0.85), `LiveAskField` (WP:321-322).
- Tess core: shorten the miss line in `TessModel.swift:68` to "Didn't catch that."; `TessModelCapture.swift` already says only that.
- After the change no text on the surface is above 21pt, and every colour is `ink`, `inkSecondary`, `inkTertiary`, `tess` or `live`.
