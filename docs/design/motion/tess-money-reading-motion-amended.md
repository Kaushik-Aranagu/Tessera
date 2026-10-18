# Money dial and Reading motion, rewritten against the amended ship lists (board 68)

Replaces the Money and Reading rows of board 49 (`tess-drums-and-release14-walk.md`, section 49), which predate hunt 19 and
tonight's rulings. Source of truth for what is being built: `docs/product/ship-list-m5-money.md` and `ship-list-m5-reading.md`
with their "Amendments, Oct 17 9:45 pm PDT" (hunt 19, G289 to G311, as carried by Kitchen on #961), the design sheets
`money-dial.md`, `money-pages.md`, `reading.md` and `money-reading-grammar.md`, and the haptic map in `DesignSystem/Haptics.swift`
(the map wins). Money and Reading have no code on master (`Features/Money` and `Features/Reading` do not exist), so this is a
spec for the build, with no code column. Where a number is the lab's, it is marked (lab) for Design to overrule.

Rules used: Low Power = Reduce Motion (one shared flag, 150 ms crossfade); one haptic per moment, always through
`tesseraFeedback`; his own touches play in Low Power and quiet hours; Tess-initiated landings follow quiet hours and make no
sound or haptic; one app-wide UNDO slot (4 s new, 10 s change, 10 s under VoiceOver); a private thing looks and moves identically
to any other; the thing comes first in every receipt.

## 1. The shared drum (Money whole units, Money cents, Reading page)

All three are siblings of the weight reel. One model, parameters per drum.

| | Money whole units | Money cents | Reading page |
|---|---|---|---|
| Row pitch | 100 pt | 60 pt | 100 pt |
| Tracks the finger | yes | yes | yes |
| Coast after a flick (normal) | ease-out cubic, about 620 ms | same cubic, drag with momentum | ease-out cubic, about 900 ms |
| Tick | `.selection` per number | `.selection` per step | `.selection` per page |
| Writes on release | nothing until Log | nothing until Log | `SetBookPage` |

Shared rules:

| Rule | Normal | Reduce Motion / Low Power |
|---|---|---|
| Tick floor | a tick no closer than 30 ms to the last (the weight reel's `WeightReel.swift:183` floor); skipped ticks are dropped, never queued; the tick on the landing number always plays. Supersedes board 49's 40 ms: the three drums now feel like the reel. | same floor; ticks only while his finger moves it |
| Coast | as the table | **none**: the drum stops where his finger lifts; it never turns on its own and never ticks on its own (amendment 4) |
| Settle | 90 ms snap to the row, house spring, no overshoot, no extra tick | none; the row is already aligned at lift |
| Edge mask | rows fade to 25% (14% for the Reading neighbours, `money-reading-grammar` row 220) | same |
| Live follow | "Log £38.20" and the context line's number change in place, no roll, no count-up | same |
| Private | amount and page are the screen's own data and show in full on its own page; the motion is identical | same |

Under VoiceOver a drum is one adjustable element ("Pounds, 38", "Pence, 20", "page 142 of 612"). An increment or decrement
changes the value with no animation and no haptic of ours (VoiceOver speaks it, G305). VoiceOver lands on the typed field when
the instrument opens; focus moves there on open and nothing slides to get there.

## 2. Money: the receipt total instrument

| Moment | Normal | Reduce Motion / Low Power | Haptic |
|---|---|---|---|
| The question appears at the shop's finish | the Groceries page folds away and one question stays: "Total?" with the dial. This is his own act (`FinishShop`), so it shows once, now. | the Groceries page crossfades to the Total question, 150 ms (G289, G291) | none (the finish already played `.done`, `GroceriesView.swift:211`) |
| The same question on Now ("Groceries total?") | text swap on the Now line, the house content swap | same | none, no sound. **Quiet hours:** `NowPicker` does not place it 23:00 to 07:00 (G292); a morning re-ask is Product's call. |
| Tap Now to open the instrument | the Now line grows into the title, the rest of Home fades back | 150 ms crossfade | none |
| Drums turn | as section 1 | as section 1 | `.selection` per number / per step |
| Tap the numeral to type | the numeral becomes a field in place at the same size, decimal pad; no animation of ours beyond the caret | same | none |
| Currency cycle (tap the word) | none, €, £, $, ₹ roll 380 ms, stored as chosen, never converted | swap with a 150 ms fade | `.selection` once per tap |
| Tap "41.60" (last shop's total) | both drums travel to it, 420 ms ease-out (lab); the tick on the landing only | drums jump, one tick | `.selection` once |
| **Log** (tap the sage "Log £38.20") | the instrument folds up (scale 0.96, up 20 pt, fade, 360 ms); the next Now rises in its place; Tess's one line appears with UNDO: **"Groceries total, 38.20, logged."**; the soul gives one reward beat | fold is a 150 ms fade; the line appears with no slide; soul still frame | **`.made`** once (soft 0.6). Retires `.impact(medium, 0.8)`: a log is a made object, not a finish, and the hold-complete 0.8 is gone from the app (haptics migration table, rows 18 and 22). |
| **Skip** (the label word under the dial) | the same fold, 360 ms; Tess: **"Groceries total, skipped."** with UNDO for 10 s | 150 ms fade | none |
| UNDO of Log or Skip (within 10 s) | the line leaves; "Groceries total, 38.20, taken back." or "Groceries total is back." The total question returns to Now; the instrument does not reopen by itself. | same, fade | `.undo` once |
| New spend by phrase ("spent 12.40 lunch") | a ghost row, commits after 2 s or on tap; Tess: **"12.40 lunch, logged."** with UNDO (4 s). The thing comes first: "€20 taxi, logged." (G302) | no slide | the capture's own `.made` once; nothing extra here |
| Masked spend | reads "Private spend" everywhere except its own page and the Month page; same fold, same timings, same haptic. Amounts stay off Home, Review and the Day log (counts only). | same | same |
| Delete a spend | a named action "Delete 12.40 lunch" on the row and the page, 10 s UNDO ("12.40 lunch is back."); the drag-left delete still folds the page back, 320 ms | 150 ms fade | `.undo` on UNDO only |

Under VoiceOver the 2 s ghost row does not commit by timer; it waits for a tap or an action (G308), so no commit animation runs
on its own. The Log word is an adjustable-plus-action pair: label, value ("12 dollars 40"), named action "Log"; Skip is named
"Skip the Groceries total".

### Month page and spend page (the pages behind the instrument)

| Moment | Normal | Reduce Motion / Low Power | Haptic |
|---|---|---|---|
| A spend lands while the page is open | the lines under today make room (40 pt, 360 ms); the new line rises in at the top of today; its amount arrives in `tess` pigment and dries to ink over 2 s; the count rolls like a value word | the line appears in ink at once; the count swaps | none (the capture had its own) |
| Swipe up on the month line | the line lifts away (up 40 pt, fade, 340 ms) and becomes the label "OCTOBER · 41 SPENDS"; the ledger rises line by line (26 pt, 440 ms, 30 ms stagger) | 150 ms crossfade, no stagger | none |
| Pinch out to the previous month | 460 ms zoom | 150 ms crossfade | none |
| Open a spend | the amount grows in place into the hero (24/600 to 80 Light, 520 ms, ease-out cubic); the ledger steps back | the hero crossfades, 150 ms | none |
| Retag a spend | up to four recent words slide in (300 ms, 40 ms stagger); one tap swaps the word with the value-word blur | the words appear in place; the swap fades 150 ms | `.selection` once on the swap |
| Large type (accessibility sizes) | one column: the day numeral on its own line above the amount and word; the line is one combined element ("Oct 15, lunch, 12 dollars 40"); same rise and stagger | same as RM | none |

Dates and clocks read through the house clock: "lunch, Thu Oct 15, 1:10 pm", never "13:10" (G306).

## 3. Reading

| Moment | Normal | Reduce Motion / Low Power | Haptic |
|---|---|---|---|
| The evening slot on Now | from 7 pm to 11 pm, only when nothing is running; the text swaps with the Now line's house content swap. At 11 pm it gives Now back the same way. It never lands at night (G292). | same swap | none, no sound |
| RESUME (tap the title) | the title stays and rises 68 pt into the hero, 460 ms house curve; Home blurs back; the seam lights vermilion, drawn left to right, 520 ms; the drum lands at eye level and **one glint** sweeps the numeral, 760 ms, once | 150 ms crossfade; the seam appears whole; the glint becomes a **150 ms highlight on the page number** (amendment 4) | normal: none. RM/LP: `.selection` once, in place of the glint. One haptic for the arrival either way. |
| After resume, VoiceOver | focus moves to the page value; "Dune, page 142" is announced once (G311) | same | none |
| Turn the page drum | section 1 | section 1 | `.selection` per page |
| Release the drum | `SetBookPage`; Tess: **"Dune, p 168."** with UNDO (10 s, a change) | no slide | none beyond the ticks |
| **Finished** (hold 0.6 s) | the word empties to a 20% trace and repaints left to right; the tip blooms; `FinishBook`; the writing line "One line on it?" opens (1 pt cobalt line); typed text is a cobalt ghost that dries to ink over 600 ms on Return; Tess: **"Dune, finished: slow start, great end."** | the fill is linear; the bloom is a 150 ms fade; the review dries in 150 ms | **`.done`** once at the bloom. Retires `.impact(medium, 0.8)`: finishing a book is a finish (map: task, hero, habit, workout, shop, shutdown, now book). |
| Finished under VoiceOver | a named action "Finish Dune" only, no default double-tap (G304): it finishes without the hold fill and opens the review line | no animation | `.done` once |
| The book flies to FINISHED (shelf) | its line flies from the hero into the top of FINISHED, 620 ms ease-out cubic, the finished lines below step down on the settle spring | the line fades out and in place; no flight | none |
| Set aside | one calm word; Tess: **"Dune, set aside."** with UNDO (10 s) | fade | none (not a finish and not `.notNow`) |
| UNDO of any Reading action | the line leaves: "Dune, taken back." The UNDO key reads "Undo Dune". | fade | `.undo` once |
| New book by phrase ("read Dune") | the ghost row arrives as the last NEXT line, rising 10 pt; Tess: **"Dune, in the queue."** (4 s UNDO) | fade, no rise | the capture's own `.made` |
| Tap a finished title | its review line fades in under it, 220 ms | 150 ms | none |
| Shelf at large type | one column; the page sits under the title; the finish flight lands in the same column | fade | none |
| Spoken forms | "page 142 of 612, started 9 days ago"; the drawn "P 142" is never spoken | | |

### A private book

A private book reads **"Private book"** wherever it is masked (shelf, ledger, Now, Home), and its review line shows on the book
page only (G303). Motion is identical: the same resume, the same flight, the same haptics. The one mechanical detail: a flight
starts with a 120 ms crossfade of its label to whatever the destination shows. For a plain book the two labels are the same
words, so nothing visible happens; for a masked book the hero's title becomes "Private book" in the first 120 ms of the flight.
It is the same timing either way, so a private book does not move differently.

## 4. Low Power and the Claude retry inbox (both areas)

Under Low Power the retry inbox pauses and resumes on power OK or his tap, and automatic Claude calls (`readWaiting`, when
wired) do not run (amendment 6, G293). A phrase he types himself is a call he asked for and still runs. This is state, not
motion: nothing animates when the inbox pauses or resumes, no line appears, no haptic. If a paused call matters to him, the
existing "waiting" receipt is the only sign.

## 5. Differences from board 49 (so Design and Builder B see what changed)

1. Tick floor 30 ms (the reel's), was 40 ms.
2. Log plays `.made`, was `.impact(medium, 0.8)`; Finished plays `.done`, was `.impact(medium, 0.8)`. Both match the haptic map and the migration table.
3. Reduce Motion and Low Power are one: no coast, no snap, no tick on its own, 150 ms crossfades; was "RM only".
4. The resume glint under Reduce Motion is a 150 ms highlight plus `.selection`, was `.selection` alone.
5. Receipts begin with the thing ("12.40 lunch, logged.", "Dune, p 168."); Skip and Delete have a 10 s UNDO; the Finish key is a named action under VoiceOver.
6. Quiet hours: the Groceries total slot and the Reading evening slot never land 23:00 to 07:00 and make no sound or haptic.

## 6. Tests the build should carry

1. A 40-number flick plays at most one tick per 30 ms and always ticks on the landing number; a drag under Reduce Motion or Low Power never ticks after the finger lifts.
2. Drums in Low Power: no coast, no settle snap.
3. Log plays `.made` once; Skip plays nothing; UNDO plays `.undo` once and never a `.selection` with it (the UNDO word must not be a pressed ink word that ticks, see the migration table's UNDO note).
4. Finished plays `.done` once, at the bloom, and not twice with the soul (the raw `.success` at `TessSoul.swift:143` must be gone first).
5. A resume under Reduce Motion plays one `.selection` and no glint; normal plays the glint and no haptic.
6. Every capture line, receipt and UNDO answer begins with the thing (G302).
7. The Groceries-total slot is absent 23:00 to 07:00 and present at 22:59; the Reading slot is absent before 7 pm and from 11 pm.
8. A masked spend and a masked book produce the same animation timeline as an unmasked one (a recorded frame-time test, label text aside).
9. Under VoiceOver the ghost row does not commit on a timer; the UNDO window is 10 s for every action.
10. At accessibility type sizes the ledger and the shelf are one column and every line is one combined element.

## 7. Asks

- Design: the `.made` for Log (was a medium impact in `money-dial.md`) and `.done` for Finished (was in `reading.md` and `money-reading-grammar.md` row 480); both sheets say `.impact(medium, 0.8)` and are the ones to correct. The lab does not edit them.
- Product: confirm (lab) defaults: the Log haptic is `.made`; set aside plays nothing; the drums to "41.60" travel 420 ms.
