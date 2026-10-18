# Notes and Recipes (outside cook mode): motion (board 80)

The two areas the Low Power matrix marked "not specced" (`tess-lowpower-reducemotion-matrix.md` Notes and Recipes rows; `tess-ruling-index.md` H16 "GAP"). Cook mode, the clock page, the bead and the peek are `tess-cook-clock-lowpower-and-timer-end.md` and `recipe-clock.md`; this sheet ends at the COOK key. Rulings are cited as `DEC:<line>` (local `decisions.md`); sheets are `notes-grammar.md` (NG), `notes-81.md` (N81), `lists-recipes-87.md` (L87), `recipe-layouts.md` (RL). Lab defaults are marked *(lab default)* and listed in §7. Code checked at master `fd0a0dc7` plus #984.

Ground rules (all in force): LP = RM = one 150 ms crossfade, no stagger, blur or travel; one haptic per moment through `tesseraFeedback`; UNDO is 4 s for a new write, 10 s for a change, a flat 10 s under VoiceOver, one app-wide slot (DEC:243); the shared Tess line sits above the key row with UNDO at its right; a private thing reads "Private note" / "Private recipe" / "Private item" through the one private-text check (G105) and moves exactly like a normal one; receipts name the thing first.

## 1. Notes
Today `Features/Notes` has no haptic, no receipt and no UNDO anywhere, and deleting dismisses at once with no line (`NoteEditor.swift:178-183`).

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Focus the writing line | the hairline inks in from the left over 320 ms in `tess` (NG); code draws it on the 0.42 s house spring (`NotesView.swift:160-168`) | the hairline appears | the field is labeled | none ruled for the draw. NG rule 7's `.selection` "when the ink line draws" is dropped: his own tap on a field already gets the keyboard, and one haptic per moment *(lab default)* |
| Write (Return) | the words fly from the line to slot 1 over 420 ms on the house curve; rows below make room by 46 pt; the line drains; the time arrives "now" in `tess` and dries to `inkSecondary` over 2 s; the context line rolls. Code today: a top push (`NotesView.swift:100-101`), no flight | rows crossfade, the line appears, the time still dries (opacity only) | "Note kept." announced; UNDO available flat 10 s | **`.made` once**, his touch (the map and audit M13; NG's `.light` has no case). Tess-initiated writes (Siri, a routed capture) play none |
| Receipt | "Note, kept." / "Private note, kept." with UNDO **4 s** (DEC:277) | 150 ms fade | spoken | none; UNDO `.undo` alone |
| Edit text | every keystroke writes (autosave every 800 ms, `NoteEditor.swift:156`); DONE above the keyboard; nothing flies | same | normal text field | none while typing |
| Leaving an edited note | **one** Tess line on leaving: "Note, saved." with UNDO **10 s** (a change); a per-save line would flood the one slot *(lab default)* | 150 ms | spoken once | none |
| Open a note | grows out of its row: the page fades 380 ms, context and body draw in, words settle at 128 ms; back is the reverse; no push from the right (NG). Code: `.navigationTransition(.zoom)` (`NotesView.swift:18,98`) is the nearest | row crossfades to the page, opacity only | focus moves to the title | none |
| Delete | DELETE NOTE ink-line word (tap, not a hold); Tess "Bar felt heavy on set 3, deleted." (plain note named by its first 8 words) with UNDO **10 s**; "Private note, deleted." | 150 ms fade | the line is announced high priority and never moves focus; UNDO flat 10 s; Magic Tap does not undo | none on delete (delete is not a landing); UNDO `.undo`. UNDO line: "Thing is back." / "Private note is back." (DEC:233, 1029 #5) |
| Private note | row reads "Private note" at 66% ink plus the time; **same height** as a plain row with the preview line reserved empty (DEC:1029 #1); a plain tap opens it, no Face ID; the editor shows raw text, not a "reveal" (#2) | same | "Private note, Tuesday" | same as a plain note, to the frame |
| Empty / long | empty: "Nothing written yet." and Tess `Say "note: bar felt heavy" and I'll keep it here.`; long list wraps to two lines at most and fades 40 pt into the Tess band (N81) | opacity only | list announced with its count | none |

Gaps in the code against NG/N81, for the build: the writing line's PaintDab and the NoteSeam hairlines are dropped (no dots, no seams: `NotesView.swift:140-142,222-231`); rows are one line, not two (`:190-201`); the editor has one text, not a separate heading (`NoteEditor.swift:46-60`); the private row is shorter than its neighbours (`:186`); `justWritten` is never cleared (`:55,:122`), so the new-row time probably dries only once *(inferred)*; the empty copy at `:239` differs from the sheet's Tess line.

## 2. Recipe shelf and paste
| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Shelf | rows enter with the shared first-visit entrance (35 ms stagger, 14 pt rise, first six); private row "Private recipe" at 66% plus the day, same height; context "38 recipes, 2 private" | opacity only | private rows read the same | none |
| Side (BY THING) | right-edge side; 1:1 settle | 150 ms crossfade | the side is a page | `.selection` once at the full side |
| Paste a page (reading wait) | a brush pass reveals the card line by line: band `.smooth` 0.6 to 0.9 s, lines `.smooth(0.28)` (`PasteRecipe.swift:222-242`, raw `withAnimation` at `:234,:239`: move onto the policy) | everything appears at once; with LP the same, one 150 ms crossfade *(lab default; code already does this for RM)* | the finished card is announced once, not line by line | none while reading |
| Reading wait, link | the line "Reading nytimes.com." and the button reads "Reading"; nothing on the page moves; no constellation (`PasteRecipe.swift:248-250`) | same | the line is announced | none |
| Claude hand-off | the line says Claude when something leaves the phone (G7); runs only on his tap, no self-retry (DEC:63) | same | spoken | none. Wording: the ruling's "Asking Claude to read the recipe." (DEC:522) differs from the code's "No recipe card there. Asking Claude." (`RecipeLinkReader.swift:19`): Product to pick |
| Save | the Save bar rises (`.move(bottom)+opacity`, `:147`); receipt "Carbonara, on Recipes." with UNDO **4 s** | fade | spoken; UNDO flat 10 s | **`.made` once** (migration row 15). Today a raw `.success` at `PasteRecipe.swift:199`. Private: "Private recipe, on Recipes." |
| Duplicate | "Weeknight dal is already on Recipes." in plain ink, no UNDO | fade | spoken | none (DEC:911) |
| Failure | "Didn't save that. Try again." | fade | spoken | one soft `.notSaved`, once, never on repeat (DEC:911) |
| Kept link lines | "Recipe link, kept for later." / "kept until Claude is back." / "kept. Check the Claude key in Settings." once, no UNDO | fade | spoken | none |
| Retry ("Read 1 waiting") | a tap reads it; tapping a failed line retries: the line dims to 60% in 150 ms, then the result (the shape of `tess-pantry-lean-notice-motion.md:32-35`) *(lab default)* | same | hint "Tries the read again" | one `.notSaved` on a second failure, never twice in a second |

## 3. Recipe page (outside cook)
| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Portion drum ("serves 4") | amounts roll 220 ms with a 15 ms stagger (`numericText`, `RecipePage.swift:381-383`); resize updates rows in place, receipt "Pasta, 2 servings." never "added" (DEC:550) | no coast, no snap, no tick of its own; amounts crossfade 150 ms | one adjustable element | `.selection` per step with a **40 ms floor** (25 a second) and the landing tick always; today `PortionDrum.swift:56` ticks on every change with no floor and `:79` is a raw `.animation` *(this drum is the money drums' fourth sibling, DEC:1001, 1041)* |
| Add to Groceries (left swipe, until the peek ships) | the row slides off `.smooth(0.36)` (`RecipePage.swift:295-304`); receipt "Tacos, 7 added." UNDO **10 s** (DEC:887) | 150 ms easeOut | announced; UNDO flat 10 s | `.made` (`:189`); UNDO `.undo` |
| Add all / nothing to add | "Tacos, nothing to add." plain, no UNDO | fade | spoken | none |
| Metric flip | snappy, rows crossfade (`:426-430`) | 150 ms | spoken | `.selection` |
| Original page | opens from the name; no animation today (`:453-511`); with the Page turn word, the page turns that word (default Turn) *(lab default; Product to confirm)* | 150 ms crossfade | a page | none |
| Private recipe | the page reads "Private recipe" and ingredient rows "Private item", including VoiceOver (DEC:995); **no reveal**: the title does not open on tap and the "Shows it" hints go (`RecipePage.swift:81,471`, G102 DEC:935) | same | same | same to the frame |
| COOK key | `cookModeReady = false` (`RecipePage.swift:13`): no key, clock or peek yet. The hand-off into the cook is Builder B's; the clock page is Builder A's (DEC:1063) | | | |

## 4. Where the code differs from the rulings (for the build)
Notes: no haptic, receipt, UNDO or delete line; top push instead of the 420 ms flight; dab, seams and two-line rows still drawn; separate heading field. Recipes: raw `.success` on save (`PasteRecipe.swift:199`); raw `withAnimation` at `PasteRecipe.swift:234,239` and `PortionDrum.swift:79`; the drum has no 40 ms floor or landing rule; a private title reveals on tap and ingredient rows are not masked as "Private item" on the original page; the left-swipe add is still live though the peek replaces it.

## 5. Quiet hours
Everything here is his own touch (a note, a paste, a drum step, an add), so every haptic plays in LP and in quiet hours. Tess-initiated: a note or recipe written by a routed capture or Siri plays none; the Claude-read result line appears with words only after 23:00; no retry of a kept link runs by itself (DEC:63).

## 6. Tests
1. A note write plays `.made` once and nothing else; UNDO plays `.undo` alone; delete plays nothing but its UNDO; editing plays nothing while typing.
2. One "Note, saved." line on leaving an edited note, not one per autosave.
3. A private note and a plain note share a row height; no word of a private note's text is in the row, receipt, announcement or Spotlight.
4. Recipe save plays `.made` once, never `.success`; a failed save plays one `.notSaved`, never twice in a second; a duplicate plays none.
5. The portion drum caps at 25 ticks a second, always ticks on the landing amount, and is one path under RM and LP.
6. A private recipe never reveals on tap; ingredient rows read "Private item" in the original page and in VoiceOver.
7. Grep: no raw `.sensoryFeedback` or `withAnimation` in `Features/Notes` or `Features/Recipes`.

## 7. Asks
Product ruled 1 to 5 below "yes" at 1:15 AM Oct 18 (DEC:1073): `.made`, one "Note, saved." on leaving, the portion drum on the money-drum rules, the link-wait line is DEC:522's "Asking Claude to read the recipe." (the code string changes), and the left-swipe add stays until the peek exists. The private-title reveal at `RecipePage.swift:81,471` is boarded as a Builder B fix. The list is kept as the record.

1. **Product:** the note write haptic is `.made` (lab default; NG's `.light` has no case). Confirm.
2. **Product:** one "Note, saved." line on leaving an edited note (10 s UNDO), not one per autosave. Confirm, and confirm no haptic on delete besides UNDO.
3. **Product:** the portion drum follows the money drums' rules (40 ms floor, landing tick, no coast).
4. **Product:** link-wait wording, DEC:522 "Asking Claude to read the recipe." against the code's "No recipe card there. Asking Claude."; and whether the original page uses the Page turn word.
5. **Product:** keep the left-swipe add until the INGREDIENTS peek exists (lab default: yes).
6. **Design:** `notes-grammar.md:44` says `.light` (map: `.made`); `no-dots.md` row 41 and the NG dab line agree with dropping the dab.
7. **Builder B (when built):** everything in §4, and the build order for the private title (no reveal) first, since it breaks a ruling today.
