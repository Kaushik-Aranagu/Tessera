# Recipe and Ingredient plate: acceptance (Design sheet 88, Product 8:37 PM Oct 16)

*Kitchen lead, 2026-10-17. The Recipe page carries a 393x56 pt plate: a wash in Kitchen green, with the recipe's own photo drying in over it. The Ingredient page carries the wash only. Rows cover Kitchen's part; the muscle map is Builder A's. The camera photo on the plate waits (new stored data type, needs its own decision after he sees the plate), so hold-the-plate is not built.*

## What is built, by owner

- **Builder B:** `ObjectPlate` (wash, photo layer, mask, grain); the og-image read once at Save through the existing link fetch (2 MB cap, cropped to the band); the Kitchen medium widget wash.
- **Core:** `Recipe.photo` stored as a file on the object, `Ingredient.colour` with Research's colour table (about 60 foods), Private objects skip the plate, the image stays out of backups.

## Rows

| # | Pass when |
|---|---|
| P1 | A recipe saved from a link with an og-image shows the photo on the plate: the wash is at first paint, the photo dries in over it in 380 ms (150 ms crossfade under Reduce Motion); no spinner, grey box or placeholder icon at any point |
| P2 | The image is fetched once, at Save, by the link fetch: one GET of the image URL, 2 MB cap (a 3 MB image gives the wash, not an error), cropped to the 786 x 112 px band, and never refetched on open |
| P3 | A recipe with no image, a failed image fetch or a typed recipe shows the wash fallback, tinted by the first three ingredient lines in the recipe's own order, skipping a staple such as salt or oil (Research's table marks them), with no quantity maths and nothing repeated |
| P4 | A recipe marked Private, or one that holds a secret word, shows plain ground: no photo, no pigment; making a recipe Private removes the stored photo |
| P5 | The fetched image is on the phone only: not in a backup or export, not sent to Claude (the `asksClaude` gate and the recipe reader never see it), and a restore from backup shows the wash until the recipe is saved again from its link |
| P6 | The Ingredient page shows the wash only, in the ingredient's own colour from the table (his pick overrides; unknown food falls to Kitchen green); no photo kind exists for an ingredient |
| P7 | Pale foods (milk, flour, sugar, rice, garlic, yogurt, cauliflower; luminance above 0.85) are shaded toward ink by 12% before the 34% wash so the plate still reads as a plate |
| P8 | The wash is the same every time for the same recipe (seeded by the object) and costs no fetch; Obsidian uses 26% with screen blend |
| P9 | VoiceOver hides the wash and reads a photo as one image after the title: "Photo of Sheet-pan paprika chicken, from budgetbytes.com"; the Ingredient plate is hidden |
| P10 | Dynamic Type does not scale the plate; the title and rows move down under it as text grows, and Tess's band and the page's fade are unchanged |
| P11 | The Kitchen medium widget carries a 10 pt wash on its top edge and never a photo; small and quiet widgets are plain; tinted and clear modes drop it |
| P12 | No image appears on Groceries, Pantry, Lists, Paste, cook mode or any Kitchen side; the plate is the only Kitchen image |
| P13 | Never summed, never private: nothing on the plate carries nutrition, a price or a note (`never-sums-audit.md`) |

## Open for Product (not blocking the rows above)

1. A recipe whose link has no og-image but whose page has other images shows the wash; the app never picks a body image. Confirm that is wanted.
2. The photo can go stale if the source page changes it; since the app never refetches, a re-save from the link is the only refresh. Fine for v1.
