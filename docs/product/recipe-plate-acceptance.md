# Recipe and Ingredient plate: acceptance (Design sheet 88, Product 8:37 PM Oct 16)

*Kitchen lead, 2026-10-17 (P14-P19 added K10). **Amended Oct 18 (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18): the Recipe plate is his own photo from the link or nothing at all; no wash, no pigment and no placeholder stands in when there is no photo. An Ingredient has no plate or pocket. Every row below that says "wash" reads "no plate".** Originally: the Recipe page carried a 393x56 pt plate: a wash in Kitchen green, with the recipe's own photo drying in over it. The Ingredient page carried the wash only. Rows cover Kitchen's part; the muscle map is Builder A's. The camera photo on the plate waits (new stored data type, needs its own decision after he sees the plate), so hold-the-plate is not built.*

## What is built, by owner

- **Builder B:** `ObjectPlate` (photo layer only; wash, mask and grain withdrawn, Kaushik 1:29 AM Oct 18); the og-image read once at Save through the existing link fetch (2 MB cap, cropped to the band); the Kitchen medium widget wash (open for Product, see `kitchen-standin-sweep-oct18.md`).
- **Core:** `Recipe.photo` stored as a file on the object, `Ingredient.colour` with Research's colour table (about 60 foods), Private objects skip the plate, the image stays out of backups; `Ingredient.colour` and the colour table are no longer needed for any plate (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18).

## Rows

| # | Pass when |
|---|---|
| P1 | A recipe saved from a link with an og-image shows the photo; until it is there nothing is drawn (no wash), and the photo dries in in 380 ms (150 ms crossfade under Reduce Motion); no spinner, grey box or placeholder icon at any point (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18) |
| P2 | The image is fetched once, at Save, by the link fetch: one GET of the image URL, 2 MB cap (a 3 MB image gives no plate, not an error), cropped to the 786 x 112 px band, and never refetched on open |
| P3 | A recipe with no image, a failed image fetch or a typed recipe shows no plate at all: no wash, no ingredient-colour pigment, no placeholder drawing (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18) |
| P4 | A recipe marked Private, or one that holds a secret word, shows plain ground: no photo, no plate; making a recipe Private removes the stored photo |
| P5 | The fetched image is on the phone only: not in a backup or export, not sent to Claude (the `asksClaude` gate and the recipe reader never see it), and a restore from backup shows no plate until the recipe is saved again from its link |
| P6 | The Ingredient page has no plate and no pocket: no wash, no colour patch, no photo kind exists for an ingredient (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18) |
| P7 | WITHDRAWN (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18): there is no wash to shade, so the pale-food rule (was: luminance above 0.85 shaded 12% toward ink) has nothing to apply to |
| P8 | WITHDRAWN (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18): no seeded wash exists; the photo, when there is one, is stored once and costs no refetch |
| P9 | VoiceOver reads a photo as one image after the title: "Photo of Sheet-pan paprika chicken, from budgetbytes.com"; with no photo there is no image stop; an Ingredient has no plate |
| P10 | Dynamic Type does not scale the plate; the title and rows move down under it as text grows, and Tess's band and the page's fade are unchanged |
| P11 | OPEN FOR PRODUCT (widget wash is ingredient pigment; `kitchen-standin-sweep-oct18.md`): the Kitchen medium widget carries a 10 pt wash on its top edge and never a photo; small and quiet widgets are plain; tinted and clear modes drop it |
| P12 | No image and no drawing appears on Groceries, Pantry, Lists, Paste, cook mode or any Kitchen side; the Recipe's own photo is the only Kitchen image (drawn stand-in withdrawn, Kaushik 1:29 AM Oct 18) |
| P13 | Never summed, never private: nothing on the plate carries nutrition, a price or a note (`never-sums-audit.md`) |
| P14 | Image fetch fails (timeout, 404, 5xx, offline, DNS error): the recipe still saves and shows no plate (P3). No error line, no retry loop and no second request; Tess says nothing about the image. A re-save from the link is the only refresh |
| P15 | A huge image: the fetch reads at most 2 MB and stops (a `Content-Length` over the cap, or a body that runs past it, is dropped without downloading the rest); the recipe saves with no plate. An image under 2 MB whose decoded size is absurd (over 16 megapixels) is refused the same way before it is decoded, so a small file cannot exhaust memory |
| P16 | A non-image content type (`text/html`, `application/json`, `text/plain`, or no type at all) gives no plate. SVG is not rendered (`image/svg+xml` gives no plate); only JPEG, PNG, WebP and HEIC are decoded, and a file that claims `image/jpeg` but fails to decode gives no plate |
| P17 | A recipe that is Private at Save, or whose page text holds a secret word, never requests the image URL at all (not "fetched and hidden"): the test asserts zero image requests. Making a recipe Private later deletes the stored photo (P4) and a later re-save does not fetch |
| P18 | The image request goes through the same link-fetch guard as the page: https only, at most 5 redirects (RULED, Product Oct 17 8:40 AM, matching ER2 and the code), no cookies or credentials, no private-network addresses, a 10 s timeout, `api.anthropic.com` never involved. A private-address or non-https og-image URL gives no plate |
| P19 | The og-image URL is stored nowhere but the object's source link; it appears in no log, receipt, Tess line or backup, and the fetched bytes are not sent to Claude (P5) |

## Open for Product (not blocking the rows above)

1. A recipe whose link has no og-image but whose page has other images shows no plate; the app never picks a body image. Confirm that is wanted.
2. The photo can go stale if the source page changes it; since the app never refetches, a re-save from the link is the only refresh. Fine for v1.
3. P15's 16 megapixel ceiling, P18's 5 redirects (ruled) and 10 s timeout are Kitchen's defaults, taken from the link fetch guard; Core or Builder B adjusts them only to match the guard they share.
