# Edit a logged set (v1 slice 8, steer)

For Builder A. This follows `no-buttons.md`: no context menu, no sheet, no shapes. Recording: `recordings/edit-set.mp4` (source `studies/edit-set.html`).

**The idea:** a logged stroke is the set. Tapping it puts the instruments back to what that set was. You change it with the same dial and drum, and saving repaints the stroke.

## Entering edit
- **Tap a logged stroke** (the hit area is 74×44 around each stroke). This replaces the long-press `contextMenu` in `LiveSetStrokes.swift`. That menu goes, and Undo lives only in the Tess horizon.
- **The stroke lifts:**
  - It rises 4pt.
  - It thickens from 9 to 13pt and wets: edges bleed about 1pt (220ms, house curve).
  - The other strokes dim to 30%.
  - Haptic: `.selection`.
- **The subline** cross-fades to "set 2, as logged: 80 × 8" in Tess's light cobalt (`#9DBFE6`).
- **The instruments go back to that set:**
  - The weight numeral rolls tabularly (columns stagger 30ms from the right, 460ms, down when the value drops and up when it rises).
  - The dial glides to the weight (520ms) and the plate maths cross-fades.
  - The reps drum springs to its reps.
- **The action:** the stroke word becomes "Save set 2" (a **tap**, not a hold) in **that set's paint**. The meta reads the live values ("80 × 8"). **CANCEL** appears as a label word at the right.
- While editing, the rest timer keeps running in the background. The Live Activity is unchanged.

## Changing and saving
- The dial and drum work as normal and the meta follows ("80 × 7").
- **Tap "Save set 2":**
  - The stroke word wets and dries.
  - The lifted stroke **drains** right to left (220ms), then **repaints** left to right (520ms, ease-out cubic) and settles back to 9pt at its place.
  - The others come back to full.
  - Everything rolls back to the current set's preset, and the subline reads "set 3 of 4, last was 80 × 7".
  - Haptic: a rigid impact. There is no `.success`, because that is kept for finishes.
- **Tess says** "Set 2 is 80 × 7 now." with **UNDO**. Undo restores the old values, and the stroke repaints once more.
- If the edit makes or unmakes a record, Tess says so in the same line: "Set 2 is 85 × 5 now, a new best." or "Set 2 is 80 × 7 now. That 5RM is back to 82.5." The light sweep plays only for a new best, as in slice 13.

## Leaving without saving
- Tap **CANCEL**, tap the same stroke again, or swipe to another exercise. The stroke settles without repainting and the instruments roll back.
- Tapping a **different** logged stroke switches edits directly.

## Removing a set
- In edit, a **REMOVE** label word in vermilion sits to the left of CANCEL.
- Tapping it drains the stroke away (right to left, then gone), and the strokes after it slide left 74pt (360ms, house). The set numbers and paints follow their new positions.
- Tess says "Set 2 removed." with UNDO.

## Accessibility and Reduce Motion
- Each logged stroke is a button: "Set 2, 80 kilograms by 8. Edit." In edit, the actions are Save, Cancel and Remove.
- Reduce Motion: no lift, wet, drain or roll. Values and paint cross-fade (200ms).
