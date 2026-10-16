# Notes on the new grammar (Design item 57)

**Kaushik's principle, in one line:** one plain line per thing, the detail one tap down, nothing cut and nothing decorated; a note is his own words kept exactly, and the page is a list of them.

Draws the Notes page and a note under sheet 41's one-line grammar (`home-first-review.md`), `no-dots.md` (rows 41 and B8), `back-word.md` (rows 13 and 17), the `calm-capture.md` addendum (Field 18 for what he types) and the one-base rule (`looks-recut.md`). Return saves (#343) is kept as the write gesture.

- Board: `mockups/notes-grammar.png` (source `studies/notes-grammar.html`): the page, writing, written, a note (Obsidian), writing a note (Obsidian), the empty page.
- Recording: `recordings/notes-grammar.mp4` (14 s), Porcelain: tap the writing line, type, Return lands the row, tap the row, write the rest, DONE, ‹ NOTES.

## The page
| y | Element |
|---|---|
| 58 | **‹ REVIEW**, Label 16/700 `inkSecondary`, the guillemet (back-word.md row 13, replacing "Close") |
| 84 | **Notes** at Title 44 |
| 146 | **The context line** in `context`, Body 21: the count and the latest, "3 notes, the latest yesterday"; after a write "4 notes, the latest just now"; "A place for loose thoughts" when empty. The only resting colour on the page |
| 200 | **The writing line** at Field 18/400, 346 wide: the prompt "Write something. @ links a thing." at `inkSecondary`; his words in ink. **No dab** (no-dots.md row 41) |
| 232 | **The hairline** under it, ink at 12%. On tap it **inks in** from the left over 320 ms in `tess` (the ink line), and the keyboard rises with it. It is the only line on the page |
| 280 + 46k | **One row per note**, newest first, Body 21 ink, 280 wide, one line (a long first line wraps to two, 74 tall; never cut). Its **time** at the right, Label 16/600 `inkSecondary`, 22 pt from the edge ("now", "yesterday", "Tue", "12 Oct"). **No seams** between rows; the pitch is the rhythm |
| 736 to 820 | **Tess's band**, fixed, the soul at (323, 759); her line beside it at 270 wide, UNDO under it in `liveInk`. Hidden under the keyboard while he writes |

**Mentions** in a row ("@Bench press") are the thing's name in ink at 600 (a value word), never cobalt and never underlined: a tap on the word goes to the thing, a tap on the row opens the note. Cobalt stays Tess's voice.

**Return writes** (#343): his words leave the writing line and land in the first row slot (200 → 280, Field 18 → Body 21) over 420 ms on the house curve while the rows below make room (46 pt), the ink line drains to the hairline, the prompt returns, and the row's time arrives as "now" in `tess` and **dries to `inkSecondary` over 2 s** (B8). The context line rolls to the new count. One `.light` impact at the landing. He can keep typing: the keyboard stays.

## A note
| y | Element |
|---|---|
| 58 | **‹ NOTES** (back-word.md row 17) |
| 84 | **The context line** in `context`, Body 21: "edited Tuesday, about Bench press" (the thing it links); "edited just now" after a write; "written Oct 12" when never edited |
| 128 | **The text**, Field 18, 346 wide: the first line at 600 is the note's name on the page; the rest at 400, ink at 88%, 6 pt under it. One text, no heading field: Return is a new line, and the first line is whatever he wrote first |
| after the text + 44 | **LINKS** as a label, then each linked thing as an ink value word on its own Body 21 line (a tap goes there). Absent when nothing is linked |
| + 80 | **DELETE NOTE** as an ink-line word (the painted lens under it). A tap deletes; Tess: "Bar felt heavy on set 3, deleted." with UNDO for 10 s (the undo rule: name the thing, then what happened) |
| above the keyboard | **DONE** at the right, Label 16/700 ink, 12 pt above the keyboard, only while the keyboard is up. It ends writing; the note is already kept (every keystroke writes). ‹ NOTES also ends it |

The note **grows out of its row**: the row's words hold their place while the page fades (380 ms), the context line and the body draw in under them, and the words settle at 128 as the first line at 600. Back is the reverse. No push from the right.

## Rules kept
1. **One base** per look: the page and the note stand on the look's ground; no sheet, no card, no inset field. The Obsidian phones on the board are the same frame on the dark base.
2. **No dots, no dab, no seams, no hairlines between rows.** The one hairline is the writing line, and it only shows ink while he writes.
3. **Resting colour only on the context line.** Rows are ink; times are `inkSecondary`; mentions are ink at 600. Cobalt arrives with a moment (the ink line, the new time) and dries.
4. **Nothing cut, no "…".** A long row wraps to a second line; a long note scrolls; the first line on the page is the whole first line.
5. **The empty page** keeps the frame: the writing line in place, "Nothing written yet." at Body 21 `inkSecondary` where the first row would be, and Tess's line in her band: "Say "note: bar felt heavy" and I'll keep it here."
6. **Field 18** for his words while they are his writing (the line, the note's text); Body 21 once they are a row on the page.
7. **Haptics,** one per moment: `.light` when the row lands, `.selection` when the ink line draws, the record pattern never; `.success` nowhere here.
8. **Reduce Motion:** the row crossfades into its slot, the ink line appears, the time still dries (opacity only).

## For Builder B
- `NotesView.swift`: drop `PaintDab` from `WritingLine` (the hairline inks in instead); `NoteRow` as one Body 21 line (first line) with the time at Label 16/600, `.data` role for the time only (B8); remove `NoteSeam`; the context line at 146 from `NotesCopy`; `NotesEmpty` with the line at 280 and Tess's line in the band.
- `NoteEditor.swift`: one `TextEditor` at Field 18 with the first line at 600 (no heading `TextField`); the context line at 84 in `context`; links as ink words under LINKS; "Delete note" becomes the `DELETE NOTE` ink-line word with the UNDO line; DONE above the keyboard; back word ‹ NOTES with `EdgeSwipeBack()`.
- Every clip ends inside the app, on the Notes page.
