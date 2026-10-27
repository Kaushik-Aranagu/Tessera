# 88. Imagery: where it belongs, and where it does not

**Kaushik's ask (Oct 16, 8:21 PM PT), in one line:** "some images or whatever but aptly sitting for the pages where it makes sense".

Board `mockups/imagery-88.png` (matrix of every page, then twelve frames: Recipe with photo, Recipe fallback, MUSCLES in Porcelain, Obsidian and AX3, Ingredient, Routine, Review, Home, widget, Recipe in Obsidian, Live workout). Recording `recordings/imagery-88.mp4` (16 s: the wash arrives, the photo dries in over it in 380 ms, the muscle map fills, a tap on Triceps, an ingredient wash arrives). Study `studies/imagery-88.html` (`?play` records). The "photo" in the mock is a drawn stand-in and the figure is original vector artwork. Layered on the plein air look (living-colours.md, title-accent.md), never swapped for it.

## The rule
An image appears only where it carries **information** (the muscle map) or **identity** (a recipe's own photo, an ingredient's own colour), is on the phone, and is small. Never stock, never AI-drawn from his data, never clip-art, never decoration. Three kinds:
- **(a) His own photo.** A recipe's og-image, read once by Builder B's existing link fetch (`kitchen/link-fetch-us.md`) when he taps Save: one GET of that image URL, 2 MB cap, cropped to a 786 x 112 px band, stored on the recipe, never refetched. Or the camera or library, by holding the plate. Never sent to Claude, never in a widget, never in a "WHAT WAS SENT" job.
- **(b) A drawn information image.** The muscle map. Plate-loading, day-stroke and Review strokes already exist as drawings and stay as they are.
- **(c) A generative wash** keyed to the object's colour: three to five soft ellipses (turbulence-displaced edges, 5 pt blur) in the object's own pigment at 34% (Obsidian 26%, screen blend), a paper grain over it at 55%. Seeded by the object, so it is the same every time and costs nothing to draw.

## The plate (kinds a and c)
- **Geometry:** 393 x 56 at the top edge, full bleed, 6.6% of the height, opaque to y 34 and melting into the ground by 56. It is page content and scrolls away with the page. The back word at 58 and the title at 84 are untouched; no text ever sits on it. Never a hero banner.
- **Loading:** the wash is there at first paint (it is drawn, not fetched). A photo is already on the phone by then, so it dries in over the wash in **380 ms** on the house curve (opacity 0 to 1, blur 5 to 0, saturation .6 to 1); Reduce Motion is a 150 ms crossfade (MotionPolicy). No spinner, no grey box, no placeholder icon, no "add a photo" prompt. A failed or missing og-image is silence: the wash stays.
- **Private and wall rule:** a "Private" recipe or note shows no photo and no pigment (plain ground). The fetched image stays on the phone and out of backups (Product 8:37: it is re-fetchable; never for private items, never to Claude); the muscle table's drawing is app content. A progress photo (body fact) is never drawn on any page in this sheet, never on Home, Review, a widget, or in any prompt.
- **VoiceOver:** a wash is hidden. A photo is one image labelled "Photo of Sheet-pan paprika chicken, from budgetbytes.com", read right after the title.
- **Dynamic Type:** a plate is in points, not scaled; the title and rows move down under it as they grow. **Tess:** nothing here enters 686 to 820; the page's own fade (50 pt from 686) and her band work as before.

## Page by page
| Page | Decision | Which, and where |
|---|---|---|
| **Recipe** | Image | Photo over a Kitchen-green wash on the plate. Fallback is the wash with the recipe's three main ingredients as pigment (paprika, sweet potato, lemon). |
| **Exercise, MUSCLES page of the side (76)** | Image | Kind b. Context at 138 "Chest, shoulders, triceps" and BENCH PRESS at its right; FRONT and BACK figures 138 x 300 centred at y 186 to 486, FRONT and BACK words at 13/700 under them; rows from 530 (Chest "primary", Front shoulders and Triceps "half a set each", 40 pt apart). Ink at 22%, worked regions in the train colour at 72%, half-set regions at 36%. A tap on a row takes its region wet (to 90%) and dries it back over 1.2 s with one `.selection`. No table and no Claude answer: "Nothing known yet." and no figure. Tess is silent here. |
| **Routine** | Image | The same drawing at 76 tall right of the title (x 286 to 371, y 80 to 156), the union of its slots' muscles, so Push A shows chest, shoulders and triceps at a glance. A title that wraps past x 280 or any AX size drops it. Labelled "Works chest, shoulders and triceps". |
| **Ingredient page** | Image | Kind c only, the ingredient's own colour from a phone table (about 60 foods; his own pick overrides; unknown falls to Kitchen green). No photo kind exists. Decorative, hidden. |
| **Widgets** | Wash only | The Kitchen medium widget carries a 10 pt wash on its top edge (6% of 169). Never a photo (extensions never read photos); small and quiet widgets are plain; tinted and clear modes drop it. |
| **Review** | None added | The week's strokes are the picture. A plate above them would be a second set of strokes. |
| **Home** | None | The hero already carries colour (title ink fills, Tess's palette). A plate would be a third voice, at the one place with the most to say. |
| **Live workout** | None | One glance, sweaty hands, sun. The set strokes are the picture and vermilion means live. |
| Exercise front, Pantry, Groceries, Note, Day log, Plans, Settings, area index (73), empty states, Lock Screen and Live Activities | None | Rows, words and strokes already say it. A swatch per Pantry row would be an icon. Groceries is read in a shop. A Note is words, and Private is only ever "Private note". Day log has its day stroke. Settings states walls and must not blur them. Empty states are a quiet line; drawing emptiness is decoration. Live Activities stay Cobalt sky. |
| **Body weight, progress photo** | Later, one page | Not drawn. If built: one page under Body weight, nowhere else, dated label, a copy holds it, nothing leaves the phone. |

## The muscle figure
Original vector, viewBox 120 x 260, left half drawn and mirrored. Front: traps, delts, chest, arms, forearms, abs, obliques, hips, quads, adductors (the inner-thigh strip beside the quads, same stroke and fill, area colour at its usual opacity), calves; back: traps, rear delts, lats, arms (triceps), forearms, low back, glutes, hamstrings, calves. Each region is a closed path with a 0.8 stroke at ink 28% and a fill at ink 4.5%. The muscle table is the phone's (Research's fixtures); a Claude-filled row keeps "From Claude, Oct 16" (every-side.md rule) and the figure reads the same table. Obsidian: ink 245,242,236, fill the dark train colour at 72%. VoiceOver reads one element ("Bench Press works chest, front shoulders and triceps. Chest is primary.") and the rows below carry the detail; regions are not separate stops. At AX3 the figures shrink to 220 tall, the context becomes "Chest and 2 more", rows stack name over role, and the page scrolls under its fade.

## Muscle label map
The phone stores 18 muscle names. The figure and the rows show plain US words. The stored name never changes; only what is shown does. One row on the MUSCLES page per stored muscle the exercise works, in the shown name.

| Stored name | Shown name | Front figure draws | Back figure draws |
|---|---|---|---|
| Chest | Chest | Chest | none |
| Front Delts | Front shoulders | Shoulder cap | none |
| Side Delts | Side shoulders | Shoulder cap | Shoulder cap |
| Rear Delts | Rear shoulders | none | Shoulder cap |
| Triceps | Triceps | none | Back of the arm |
| Biceps | Biceps | Front of the arm | none |
| Forearms | Forearms | Forearm | Forearm |
| Lats | Lats | none | Lats |
| Upper Back | Upper back | Upper trapezius, the neck line | Upper trapezius |
| Lower Back | Lower back | none | Lower back |
| Abs | Abs | Abs | none |
| Obliques | Obliques | Obliques | none |
| Glutes | Glutes | none | Glutes |
| Quads | Quads | Front of the thigh | none |
| Hamstrings | Hamstrings | none | Hamstrings |
| Adductors | Inner thighs | Inner-thigh strip beside the quads | none |
| Abductors | Outer hips | Hips | Glutes, outer edge |
| Calves | Calves | Calves | Calves |

Rules: the figure draws every muscle in the table, so nothing worked is ever left off the drawing. Where two stored names share one drawn region (Front and Side Delts on the front), both light it. A row for Adductors reads "Inner thighs". VoiceOver and the Routine line use the shown names ("Works chest, shoulders and triceps" folds the 3 shoulder names into "shoulders"; the MUSCLES rows keep them apart).

## Asks per builder team
- **Builder B:** `ObjectPlate` (wash, photo layer, mask, grain), the og-image read at Save, the Kitchen widget wash.
- **Builder A:** `MuscleFigure` (front and back, worked map, row tap) on the MUSCLES page and the Routine title.
- **Core:** `Recipe.photo` as a file on the object, `Ingredient.colour` field and the colour table, Private objects skip the plate.
- **Research:** the muscle fixtures for the 30 exercises he uses; the ingredient colour table.

## Unresolved
RULED 8:37: Routine mini map yes; his own camera photo on the plate WAITS (a new stored data type; Product decides after he sees the plate), so hold-the-plate is not built in v1; Research supplies the ingredient colour table and muscle fixtures.

## Plate rules added after Research's colour table (Oct 16, 8:32 PM PT)
- **Kitchen green** is `#12936A` (the kit token), the end of the fallback chain.
- **Pale foods** (milk, flour, sugar, rice, garlic, yogurt, cauliflower; any hex with luminance above 0.85) keep their own hue but are shaded toward ink by 12% before the 34% wash, so the plate still reads as a plate. No other floor.
- **Recipe fallback wash** takes the first three ingredient lines in the recipe's own order (the author lists the main ones first); no quantity maths, nothing repeated, and a pantry staple such as salt or oil is skipped (Research's table marks them).
