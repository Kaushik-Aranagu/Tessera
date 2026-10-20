# Kitchen v2 looks (Design item 114)

From Kitchen's list (Oct 19) over `docs/product/kitchen-v2-build-ready-rows-oct19.md`. Every feature here is behind its own Review switch, default Off (sheet 110 grammar). House rules hold on all of it: ink words, no cards, no pills, no icons, never red, no drawn food, one soft haptic, Reduce Motion = 150 ms crossfade, VoiceOver reads each line as one sentence, a private recipe or item reads "Private recipe" or "Private item". Type sizes stay 16 / 21 / 44.

## 1. Week strip (WD-S1), on Plans' WeekPage
- One row per day, Monday to Sunday, by the 4 AM day. The day word on the left in `inkSecondary` 16 ("Mon"), the dinner in ink 21 ("Tacos"). A day with no cook has only its day word. One hairline under the strip, none between rows.
- A skipped plan reads "Tacos, skipped" in `inkSecondary` (no strike: the strike means done). A done plan strikes through (the usual rule). A private plan reads "Private recipe".
- The foot: one key word, "Add the week to Groceries", `labelWord`, 44 pt. Nothing reaches Groceries until he taps it. Receipt in Tess's band: "Week, 5 added." with UNDO for 4 s. With every plan already added: "Week, nothing to add." with no UNDO. The key greys (55% ink) when there is nothing to add.
- Switch: "Week strip is **off**." (Kitchen page).

## 2. Repeats word (RG-S2), on a Groceries row
- A weekly item shows one quiet word at the right edge of its row: "weekly", `inkSecondary` 16. No pill, no icon, no colour.
- Set by speaking ("milk every week", receipt "Milk, every week." UNDO 10 s). Tap the word to clear it: receipt "Milk, not every week." UNDO 10 s.
- When the shop is finished a weekly item comes back as an open row; it keeps the word. A private item keeps "Private item" and the word.
- Switch: "Repeat items are **off**."

## 3. Listening mark (HF-S5), on the cook page (proposed)
- While hands-free is on and the phone is listening: one word "Listening" in `inkSecondary` 16 sits in the quiet line under the step, with its hairline breathing between 40% and 90% ink over 1.6 s. No microphone icon, no colour, no Tess face change.
- Not listening (the switch is on but the page is not showing, or mic blocked): nothing is drawn. If the mic is refused the usual refusal line shows and touch works.
- A heard word is answered in Tess's band by the usual line ("Step 3.", "Timer, 8 min."); the "Listening" word does not flash.
- Reduce Motion: the hairline stays at 65% (no breath). Low Power: the same, static.
- VoiceOver: no announcement for the mark; the replies are announced.
- Switch: "Hands-free cooking is **off**."

## 4. Note line (CN-S1, CN-S2), and the Finish line
- The recipe page: under the title block, one line in `context` 21: "Last time: less salt." (the newest note since the last cook; gone after the next cook finishes). A private note reads "Private note". No label above it, no hairline of its own.
- Cook mode, first step only: the same line above the step text in `inkSecondary` 16. From step 2 it is gone.
- Finish: under "<title>, ready to finish" an optional writing line, placeholder "Note for next time" (Field 18, `inkSecondary` placeholder). Empty by default; Finish works with it empty and adds no step. It feeds `FinishCooking(note:)`. Voice "note: less salt" writes the same note.
- Notes never go to Claude and never change the lines.
- Switch: "Cook notes on the recipe are **off**."

## 5. Edit a recipe in place (RE): the FIX word, gesture, handle, refusal
- Opening: the recipe page shows one word "FIX" at the top right, `labelWord` 44 pt, `inkSecondary` (the same place as "Edit" elsewhere). A long press on the recipe title does the same, with one selection haptic. VoiceOver: "Fix recipe".
- In the edit state the page is the same page: lines and step texts become writing fields in place (ink 21, one hairline under the field being edited), the title stays. Two words at the foot, 44 pt: "Keep" and "Not now" (as in the Remix editor).
- Step handle: the step number is the handle. Touch and hold 0.3 s lifts the row 2 pt with one selection haptic; drag up or down; release drops it with the same haptic. No grip is drawn. In the edit state the numbers read at 100% ink and the step text at 55% until it is touched. A drop that does not move the row gives no haptic.
- Return in a step splits it; delete at the start joins it to the one above.
- Refusal when every line is set to ignore: the Keep word stays, Tess's line reads "Nothing saved: every line is ignored." The recipe is unchanged. No dialog.
- A private recipe's receipt reads "Private recipe, fixed."
- Switch: "Fixing a recipe is **off**."

## 6. VoiceOver for the second lane (PL-S3, PL-S4)
- The current step reads first: "Step 3 of 7, stir the sauce, 4 minutes left." Then the other lane, after a pause: "Meanwhile, rice, step 2 of 4, 9 minutes left."
- Next moves within the current track only, as drawn: "Next, step 4 of 7."
- A proposed second lane (from Claude) is drawn with a faint ink bracket at 25% beside the step block, never cobalt, and its words read "Proposed". The keep receipt: "Kept for this recipe." with UNDO.
- Switch: "Steps run in parallel are **off**."

## 7. Also, from the same pages
- CAN COOK (CC-S2): the recipes below the 60% bar sit under a hairline in a block headed by one line "2 to check" in `inkSecondary` 16; the rows below it are ink at 55%. A tap on the greyed CAN COOK word speaks the empty line once, no haptic.
- Aisle order (AO-S2): when the learned order differs, the aisle headings slide to the new order once on open, with the snappy curve (0.25 s) through MotionPolicy. No receipt, no haptic. Reduce Motion: a 150 ms crossfade.

## Never
A pill, an icon, a coloured dot, a drawn food image, a red word, a dialog, more than one haptic per moment, a switch that names what is not built.
