# Kitchen drawn stand-in sweep (Oct 18)

*Kitchen lead, docs only. Trigger: Kaushik, 1:29 AM PT Oct 18, "Muscle figure seems alright. The pan and other grocery things not that great." Product logged it in `decisions.md` (1:30 AM entry, end of file): every drawn food stand-in is WITHDRAWN. The Recipe pocket is his own photo or nothing; an Ingredient has no pocket; no drawing on Groceries, Pantry or Kitchen pages. Design source: `/mnt/project-files/tessera/design/imagery-88.md` (sheet 88, images where they fit), `pockets-91.md`, `pocket-rules-96.md`.*

Scope: Kitchen-owned docs in `docs/product/` (kitchen-*.md except the gap-hunt files, recipe-plate, groceries-*, grocery-capture-miss, meal-plan-groceries, cook-mode-*, first-week and first-use files). `decisions.md` and the gap-hunt files are untouched. Row ids are unchanged and nothing is renumbered. Where a row only existed to describe the drawing it now says WITHDRAWN and keeps its id. Searched for: pan, pot, skillet, icon, glyph, picture, image, plate, pocket, stand-in, placeholder, drawing, illustration, silhouette, sketch, art, wash, pigment, swatch, emoji, symbol, thumbnail. No Pantry or Groceries Kitchen doc expected a food drawing; the hits are the Recipe plate wash and the Ingredient wash.

## Edits (line numbers are after the edit)

| file:line | Old wording (short) | New wording (short) |
|---|---|---|
| recipe-plate-acceptance.md:3 | Recipe plate is a Kitchen green wash with his photo over it; Ingredient carries the wash | Amended: his photo from the link or no plate at all; no placeholder; Ingredient has no plate or pocket; "wash" reads "no plate" |
| recipe-plate-acceptance.md:7 | Builder B: ObjectPlate (wash, photo layer, mask, grain) | photo layer only; wash, mask, grain withdrawn |
| recipe-plate-acceptance.md:8 | Core: Ingredient.colour with the colour table | `Ingredient.colour` and table no longer needed for any plate |
| recipe-plate-acceptance.md:14 (P1) | wash at first paint, photo dries in over it | nothing drawn until the photo is there; photo dries in |
| recipe-plate-acceptance.md:15 (P2) | a 3 MB image gives the wash | gives no plate |
| recipe-plate-acceptance.md:16 (P3) | no image or failed fetch shows the wash tinted by the first three ingredients | shows no plate at all: no wash, no pigment, no placeholder |
| recipe-plate-acceptance.md:17 (P4) | plain ground: no photo, no pigment | no photo, no plate |
| recipe-plate-acceptance.md:18 (P5) | a restore shows the wash | shows no plate |
| recipe-plate-acceptance.md:19 (P6) | Ingredient page shows the wash in its own colour | Ingredient page has no plate and no pocket |
| recipe-plate-acceptance.md:20 (P7) | pale foods shaded 12% before the wash | WITHDRAWN, nothing to shade |
| recipe-plate-acceptance.md:21 (P8) | wash seeded by the object, same every time | WITHDRAWN; photo stored once, no refetch |
| recipe-plate-acceptance.md:22 (P9) | VoiceOver hides the wash; Ingredient plate hidden | no image stop without a photo; Ingredient has no plate |
| recipe-plate-acceptance.md:24 (P11) | Kitchen medium widget carries a 10 pt wash | marked WITHDRAWN (Product ruled, Oct 18; see Rulings in 1) |
| recipe-plate-acceptance.md:25 (P12) | no image on Groceries, Pantry...; the plate is the only Kitchen image | no image and no drawing; the Recipe's own photo is the only Kitchen image |
| recipe-plate-acceptance.md:27-31 (P14, P15, P16, P18) | failure gives the wash fallback / the wash | gives no plate |
| recipe-plate-acceptance.md:36 (Open 1) | no og-image shows the wash | shows no plate |
| kitchen-refill5-acceptance.md:34 | wash is 34% of pigment, grain 55% | wash withdrawn, photo only |
| kitchen-refill5-acceptance.md:38 (K30.1) | No art, no wash, no plate, no placeholder icon | adds no pocket, no drawing |
| kitchen-refill5-acceptance.md:39 (K30.2) | Plate shows Kitchen green wash at 34%, grain 55% | No plate: no wash, no colour, no drawing |
| kitchen-refill5-acceptance.md:40 (K30.3) | wash tinted by paprika, sweet potato, lemon | no plate and no ingredient-colour pigment |
| kitchen-refill5-acceptance.md:41 (K30.4) | wash already there at first paint | nothing drawn at first paint |
| kitchen-refill5-acceptance.md:44, :45 (K30.7, K30.8) | shows the wash / the wash, silence | shows no plate / no plate, silence |
| kitchen-refill5-acceptance.md:47 (K30.10) | wash at 26% screen blend; pale-food shading | no wash in either theme; pale-food rule withdrawn |
| kitchen-refill5-acceptance.md:49 (K30.12) | no photo, no pigment, no wash | no photo, no plate |
| kitchen-refill5-acceptance.md:51 (K30.14) | one with only a wash; wash hidden | one with no photo; no plate, no stop |
| kitchen-refill5-acceptance.md:52 (K30.15) | Ingredient page carries a wash only | Ingredient page has no plate or pocket; widget wash open for Product |
| kitchen-refill7-acceptance.md:28 (K43.2) | the plate is the Kitchen green wash (K30.2) | there is no plate |
| kitchen-error-states-acceptance.md:20 (ER15) | Nothing: wash fallback | Nothing: no plate, no drawn fallback |
| kitchen-first-week-script.md:187 | Plate, wash and photo rows need a link recipe with an image | wash rows are withdrawn |
| kitchen-first-use-empty-states.md:27 | No plate, no wash, no placeholder icon | adds "or drawing" |
| kitchen-widget-wash-acceptance.md:3 | (none) | WITHDRAWN banner over KW-W1, W2, W9 to W13, W15, W16, W18 (Product ruled, Oct 18; see Rulings in 1) |

Every edited row carries "(drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18)" or the banner naming it. Count: 7 files, 37 table lines edited or marked (the table above groups a few adjacent rows), 18 diff hunks.

Checked and left alone because they already say "none": kitchen-first-use-empty-states.md:62 (no illustration), :94 (no drawing of emptiness), :146 (no illustration anywhere); kitchen-sides-acceptance.md:88 (no empty-state art); kitchen-refill6-lane1-acceptance.md:144 and the "plain ground, no wash" Private/empty rows (K32.5 to K32.7, K38.4, K41.2, K41.5, K41.7, K61.28, KW-W5 to KW-W8), which stay true. kitchen-seed-recipes.md "pan" lines are cooking steps, not drawings. kitchen-refill6-lane1-acceptance.md:113 "checklist glyphs" are characters in pasted text. kitchen-refill8-acceptance.md:157 "a photo of a plate" is a test photo.

## Ambiguity needing Product (all three ruled below)

1. **The Kitchen medium widget wash.** `kitchen-widget-wash-acceptance.md` (KW-W1, W2, W9 to W13, W15, W16, W18) and `recipe-plate-acceptance.md` P11 and `kitchen-refill5-acceptance.md` K30.15 draw a 10 pt wash tinted by the recipe's first three ingredient colours. That is an ingredient-pigment drawing, but a widget is not a "Kitchen page". I held the rows (banner, no deletion) instead of ruling. Default if Product says withdrawn: the widget is plain ground always, KW-W9 to W13 and W15 to W16 are struck, KW-W3, W4, W18 stay as "no wash".
2. **The Kitchen mark** on the Dynamic Island (`kitchen-refill6-lane2-acceptance.md:141` K41.10) is an app mark, not food; left alone.
3. **Colour table and `Ingredient.colour`.** With the Ingredient wash gone, `docs/research/fixtures/ingredient-colours.md` has no consumer. Product decides whether Core still adds the field (my edit to recipe-plate:8 says it is not needed for any plate).

## Still drawing a stand-in (cite only, not edited)

Non-Kitchen docs:
- `docs/research/fixtures/ingredient-colours.md:3` (for ObjectPlate wash), `:24` (pale-food shading before the wash), `:26` (Recipe fallback wash), `:104`, `:105`.
- `docs/ops/board/ios-b.md:182` (8:37 IMAGES: plate with "wash fallback").
- `docs/ops/board/design.md:86`, `:88`, `:92` (ObjectPlate review lines: seeded ellipses, pigment).
- Design folder (outside the repo): `/mnt/project-files/tessera/design/imagery-88.md:23` (Recipe fallback wash of three ingredients), `:26` (Ingredient colour wash), `:27` (widget wash), `:15` (wash at first paint); `pockets-91.md:24` (Recipe patch of ingredient colours), `:25` (Ingredient own colour); `pocket-rules-96.md:5` (a crisp drawing is allowed; now food drawings are not).

Code:
- `Features/Objects/ObjectPlate.swift:8` (struct ObjectPlate: wash, seeded blobs, pigments default `[PlateWash.kitchenGreen]` at `:21`, blobs at `:76-79`).
- `Features/Objects/PlateWash.swift:5` (enum PlateWash: seed, blobs, pigments, kitchenGreen).
- `TesseraTests/PlateWashTests.swift:7` (tests the wash).
- Nothing outside those three files calls ObjectPlate or PlateWash today (grep across `*.swift`), so no Recipe, Ingredient, Groceries or Pantry screen draws a stand-in yet; the risk is Builder B wiring it. Brief for Builder B: ObjectPocket for a Recipe is photo only, nil otherwise; no Ingredient pocket.
- No `Image(systemName:)` or `systemImage` food glyph found in `Features/Groceries`, `Features/Kitchen`, `Features/Recipes`, `Features/Lists`.

## Rulings in (Product, Oct 18)

1. Widget wash withdrawn too; the Kitchen widget is plain ground. Widget rows KW-W1, W2, W9 to W13, W15, W16, W18, recipe-plate P11 and K30.15 now read WITHDRAWN.
2. Ingredient.colour: no readers and no new writes; the column stays (additive migrations). `docs/research/fixtures/ingredient-colours.md` is Research's file and still reads "For: Builder B (ObjectPlate wash)"; Product marks it withdrawn there (not in this PR).
3. The Dynamic Island Kitchen mark (K41.10) stays.
4. Dead code deletion (ObjectPlate, PlateWash, PlateWashTests) is boarded for Builder B.
