# 91. Pockets, round 2: crisp drawings and a real figure (replaces 88's top plate)

**Round 2 (Kaushik, 12:46 PM Oct 17):** the muscle figure "looks super bad ... not nice or accurate" (redrawn below, in proportion, from anatomical charts) and the soft colour patches "look like a diffused, dead Tess". Nothing is blurred any more: **Tess is the only soft, blurred thing in the app.** A pocket is now a crisp drawing (fine line, one flat colour) or his own photo. No pocket on Groceries (sheet 88 said none; round 1 added it wrongly). The figure's source is `studies/muscle-figure.js` (front and back, one path per stored muscle, left half drawn and mirrored). Everything below about size, strength, place and loading still stands, with "patch" read as "drawing".

**Kaushik on sheet 88 (Oct 17, 12:31 PM PT):** "I don't want like a band at the top ... very faded images in small section which make it look good, especially where it doesn't feel too cluttered ... I don't like the banner thing."

Board `mockups/pockets-91.png`, recording `recordings/pockets-91.mp4` (16 s: the recipe's dish and the ingredient's colour dry in, the muscle figure arrives, Groceries turns Produce, Dairy, Pantry, Frozen and each page's patch turns with it), study `studies/pockets-91.html`. The "photo" is a drawn stand-in. Nothing in the app changes yet.

## What changes from sheet 88
The 393 x 56 plate at the top edge is **withdrawn** everywhere. Sheet 88's rule (an image only where it carries information or identity, on the phone, never stock, never AI-drawn from his data, never for Private things or progress photos, never Claude) stays. Only the shape and place change.

## The pocket
- **Size:** at most 160 x 160 pt (5% of the screen), feathered on every side, never a line, card or circle.
- **Strength:** 14% to 18% in Porcelain, 12% to 16% in Obsidian; the muscle figure 22% with worked parts in the area colour.
- **Place:** the largest empty rectangle the page has, bottom right by default, at least 24 pt from any word. If a longer title or a bigger text size would reach it, it is simply not drawn. Never at the top, never behind a title or number.
- **Belongs to its page:** when the page turns (sheet 90) the old pocket dissolves over 260 ms and the new one dries in over 380 ms; it does not move with the rows.
- **Loading:** a photo, if there is one, dries in over a colour patch in 380 ms (blur 5 to 0, saturation .6 to 1); no spinner, no grey box, no "add a photo". Reduce Motion: 150 ms crossfade.
- **Budget:** one pocket per page. Not on Home, a live workout, a widget, a Private thing (plain ground), or a progress photo.
- **VoiceOver:** hidden, except a photo, read once ("Photo of Sheet-pan paprika chicken").

## Where it lives
| Page | Pocket |
|---|---|
| Recipe | his photo, or a patch of its first three ingredients' colours, at the foot of the ingredient list, bleeding off the right edge |
| Ingredient | its own colour (the phone's colour table), right of the quiet lines |
| Exercise MUSCLES | front and back figures, each 166 wide (166 x 365), under the rows, at full strength: it is information, not decoration |
| Routine | the same small figure as before (sheet 88), not drawn if the title wraps past x 280 |

## For builders (not built; Product boards it, Builder B for `ObjectPlate`)
Rename `ObjectPlate` to `ObjectPocket(object:, page:)`: seed wash by object, feathered radial mask, 160 pt cap, an `emptiestRect` from the page's laid-out rows (nil if none 24 pt clear), 380 ms dry-in through `MotionPolicy`. Grain is dropped; the wash alone reads. Core's `Recipe.photo` and `Ingredient.colour` asks are unchanged.

## Open question for Kaushik (a picture)
Is this faded enough, and small enough? The clip's top row shows Recipe, Ingredient and Muscles; the lower left shows Groceries turning pages. If yes, the pockets go to builders after the page-turn pick.

## Kaushik on round 2 (Oct 18, 1:29 AM PT): the figure stays, the food drawings go
His words: "Muscle figure seems alright. The pan and other grocery things not that great."
- **Approved:** the muscle figure (front and back, `studies/muscle-figure.js`) on the Exercise MUSCLES page and the Routine. It is no longer waiting on his word.
- **Withdrawn:** every drawn food stand-in. That is the drawn pan on Recipe, the ingredient colour drawing on Ingredient, and any drawing on Groceries, Pantry or Kitchen pages. A page about food shows no drawing.
- **What a Recipe pocket is now:** only his own photo, feathered as above, when he has one. With no photo the page has plain ground and nothing in the pocket's place. No stand-in, no patch, no "add a photo".
- **Ingredient:** no pocket (plain ground). The phone's colour table still exists for Core, but it is not drawn as a picture.
- **Reversible:** if he wants a food drawing later, it starts from his photo or his reference, not from a made-up stand-in.
- The table above ("Where it lives") reads with these changes: Recipe = his photo or nothing, Ingredient = nothing, Exercise MUSCLES and Routine = the figure.
