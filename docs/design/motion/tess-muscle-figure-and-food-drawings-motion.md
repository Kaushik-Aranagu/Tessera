# The muscle figure, and the withdrawn food drawings (board 84)

Motion rows for the one pocket that stays after Design sheet 91's Oct 18 addendum (`docs/design/pockets-91.md` at commit `9fb7d9b1`, branch `claude/project-thread-b3tu3f`; Kaushik, 1:29 AM: "Muscle figure seems alright. The pan and other grocery things not that great."), plus a sweep of this folder for any motion row that assumed a drawn food stand-in. Source of the drawing: `docs/design/studies/muscle-figure.js` (front and back, left half drawn and mirrored, one path per stored muscle). Sheet 91 changes no app code; neither does this one. Lab defaults are marked *(lab default)* and listed in §6.

Ground rules: LP = RM = one 150 ms crossfade, no stagger, blur or travel; one haptic per moment; the figure is information, so it is **crisp**: no blur, no feather on the drawing, no glow, never a soft edge (Tess is the only soft thing in the app, sheet 91 round 2); the drawing never moves with the rows.

## 1. Exercise page, MUSCLES
Front and back figures, 166 x 365 each, under the muscle rows at full strength (22%, worked parts in the area colour). Both are always drawn, side by side: no flip, no rotate, no toggle.

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Arrive on MUSCLES | the page comes along the sibling pages (44 pt and a fade, 380 ms, `tess-sides-motion.md:20`); the outlines are part of the page and arrive with it; the worked parts dry in over 380 ms, opacity only (0 to the role's strength), all at once, no stagger and no blur *(lab default: a stagger would turn information into decoration)* | the page crossfades 150 ms with the parts already drawn | see below | none |
| Role strength | primary at full area colour, secondary at 70% (the same split as the rows' dabs, `exercise-page.md` row 24); not worked: bare outline | same | read in the rows | none |
| Tap a worked part | opens that muscle's page, the same way its row does (the shared open: 150 ms crossfade under RM); a 44 pt minimum target is centred on the part | same | the figure is not a control for VoiceOver (see below) | none (opening is not a landing) |
| Switch to another sibling page | the figures leave with the page: no separate exit | 150 ms | n/a | none |
| Muscles change (a Core edit to the exercise, or Undo of it) | the changed parts crossfade 260 ms; the rows move first, the figure follows in the same 260 ms | 150 ms | the rows announce | none (the edit owns the haptic) |
| An exercise with no stored muscles | no figure, no empty outline, no placeholder; the rows say "No muscles stored." | n/a | the line | none |
| Text size too large for the figure to clear the words | not drawn (sheet 91: no 24 pt clear, no figure); it leaves and returns with a 150 ms crossfade, never a resize animation | same | n/a | none |

- **VoiceOver:** the figure is hidden from VoiceOver and the rows carry every fact (role and muscle, in the rows' own words), so nothing is read twice *(lab default; sheet 91 hides pockets from VoiceOver except a photo, and a figure that repeats the rows adds nothing)*. Voice Control reaches a muscle by its row name.
- **Pigment:** the area colour comes from the look; a look change redraws the parts with the page's look crossfade and adds none of its own.

## 2. Routine
The small figure from sheet 88, one per page, bottom right, not drawn if the title wraps past x 280.

| Moment | Normal | RM / LP | VoiceOver | Haptic |
|---|---|---|---|---|
| Open a routine | the figure is part of the page: the worked parts dry in over 380 ms with the page's arrival, opacity only | 150 ms crossfade | hidden; the routine's exercises are listed in the rows | none |
| Add or remove an exercise | the worked parts that change crossfade 260 ms; the union of the routine's muscles; Undo reverses with the same 260 ms | 150 ms | the receipt is announced once ("Squat, added") | the add's own `.made`; the figure plays none |
| Page turn (sheet 90) | the pocket belongs to its page: it dissolves over 260 ms with the old page and dries in over 380 ms on the new one; it does not ride the rows or take a Rotate slot | 150 ms crossfade | n/a | none (R2) |
| Private workout or routine | **no figure**: plain ground, nothing in its place (sheet 88: never for a Private thing); the page does not reflow, because the pocket was never in the layout | n/a | n/a | n/a |
| Live workout | no pocket on a live workout (sheet 91 budget) | n/a | n/a | n/a |

## 3. The food drawings are gone: what to remove from a spec
Sheet 91's addendum withdraws every drawn food stand-in: the drawn pan on Recipe, the ingredient colour drawing, any drawing on Groceries, Pantry or Kitchen pages, the pigment patch and the widget wash. The remaining food pocket is **his own photo, or nothing**.

| Page | Now | Motion |
|---|---|---|
| Recipe | his photo, feathered, only when he has one; no photo: plain ground and nothing in its place (no patch, no "add a photo") | the photo dries in over plain ground in 380 ms (blur 5 to 0, saturation .6 to 1), no spinner and no grey box; the colour patch under it is withdrawn; RM and LP 150 ms crossfade; a page turn dissolves it 260 ms. No haptic. Hidden from VoiceOver except the photo itself, read once ("Photo of Sheet-pan paprika chicken") |
| Ingredient | no pocket, plain ground | none |
| Groceries, Pantry, Kitchen | no drawing (Groceries never had a pocket) | none |
| Private recipe | plain ground, as with any Private thing | none |

## 4. Sweep of this folder (checked at `a8c60260`)
No motion row in this folder assumes a drawn food stand-in. Read: `tess-notes-recipes-motion.md` (Recipe shelf, paste, page: no image, no pocket row), `tess-pantry-first-day-and-four-sides-motion.md` (no drawing on Pantry), `tess-groceries-lists-and-home-settings-lowpower.md` and `tess-live-activity-lockscreen-widget-motion.md` (the "wash" lines are Tess's cobalt ground, Home's bloom and the Live Activity sky, not food colour; none is a food widget wash). The one line that names the pockets is `tess-never-diffused-audit.md:21` ("The new imagery (sheet 88/91 pockets) must show her crisp and whole or not at all"): still true, and now it applies to the muscle figure and a recipe photo only.

## 5. Tests
1. The MUSCLES page and the Routine draw the figure with no blur, glow or soft edge, and the parts dry in with opacity only over 380 ms (150 ms under RM and LP).
2. Opening a muscle from the figure and from its row ends on the same page; neither plays a haptic.
3. Adding an exercise to a routine plays the add's `.made` once and nothing from the figure; Undo plays `.undo` once.
4. A Private routine and a live workout draw no figure and leave no gap; a recipe with no photo draws nothing and has no patch.
5. The figure is not in the accessibility tree; a recipe photo is, once.
6. Grep: nothing in the app draws a food stand-in (pan, ingredient colour picture, wash patch); `ObjectPocket` (`ObjectPlate` today) draws only a photo or the muscle figure.

## 6. Asks
1. **Product:** all worked parts dry in together with no stagger *(lab default)*; the 260 ms crossfade when muscles change.
2. **Design:** the figure hidden from VoiceOver because the rows say the same, and a worked part's tap opening the muscle page like its row *(lab defaults)*.
3. **Builder B (when built):** `ObjectPocket` draws only a photo or the figure, through `MotionPolicy`; the Recipe photo dries in over plain ground (no colour patch).
