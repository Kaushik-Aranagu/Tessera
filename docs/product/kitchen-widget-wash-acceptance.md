# K24: Kitchen widget wash rows

*Kitchen lead, 2026-10-17*

Sources: sheet 88 (Widgets row; wash kind c), recipe-plate-acceptance P6-P8, P11, P12, ingredient-colours.md. Code check: Widgets/ holds only the rest Live Activity; no Kitchen widget exists yet, so rows are build targets for Builder B. Kitchen acceptance has no widget line; these rows add it.

| ID | Case | Expected | Source |
|---|---|---|---|
| KW-W1 | Medium, Porcelain (light), planned cook | 10 pt wash on the top edge only (6% of 169 high), 3 to 5 soft ellipses at 34%, grain at 55%, opaque to the first part and melting into the ground; nothing below it is washed | P11, sheet 88 |
| KW-W2 | Medium, Obsidian (dark) | Same shape at 26% with screen blend; ink 245,242,236 text stays AA | P8 |
| KW-W3 | Medium, tinted mode | Wash dropped; accent-tinted text and ground only | P11 |
| KW-W4 | Medium, clear mode | Wash dropped; no pigment layer | P11 |
| KW-W5 | Small widget | Plain ground, no wash, light and dark | P11 |
| KW-W6 | Quiet widget | Plain ground, no wash, light and dark | P11 |
| KW-W7 | Medium, empty (no planned cook) | No wash, plain ground, one quiet line. Default taken: "Nothing planned" (no widget copy exists in code); no button, no drawing of emptiness | sheet 88 empty states |
| KW-W8 | Private recipe planned | Plain ground, no pigment, no recipe title. Ruled (Design, Oct 17): the only copy is "Private recipe, 7 pm." (lowercase time, no "at"); with no time, "Private recipe, today." or "Private recipe, tonight."; replaces the bare "Private" | sheet 88 wall rule |
| KW-W9 | Wash colour | First three ingredient lines in the recipe's own order, staples skipped (butter, flour, sugar, olive oil, black pepper; salt, oil, water, pepper by key), no quantity maths, nothing repeated; pale foods shaded 12% toward ink; unknown falls to Kitchen green #12936A | sheet 88, table |
| KW-W10 | Same every time | Seeded by the object (recipe id); two renders, two reloads and two devices give the same pixels | P8 |
| KW-W11 | Reload | A timeline reload does not re-tint or re-seed; the wash changes only when the planned recipe changes | P8 |
| KW-W12 | No photo | The widget never reads or shows a recipe photo; the extension has no access to the stored image; a recipe with a photo shows the wash | sheet 88, P11 |
| KW-W13 | No network | The widget makes no fetch of any kind; the wash is drawn from the colour table copy and the seed. Default taken: table ships as a shared resource, not fetched | sheet 88 |
| KW-W14 | Text size | No text under 16 pt at any size. Default taken: no text sits on the wash band | brief |
| KW-W15 | Dynamic Type | Wash stays 10 pt (points, not scaled); text moves down and clips cleanly at AX3, nothing overlaps the band | sheet 88 |
| KW-W16 | Reduce Transparency | Wash drawn as an opaque 34% flat mix on the ground, no blur or blend, no grain. Default taken | brief |
| KW-W17 | VoiceOver | Wash hidden; the widget reads the recipe title and time only ("Private recipe, 7 pm." for a private cook, KW-W8) | sheet 88 |
| KW-W18 | Scope | No other Kitchen widget, Lock Screen or Live Activity carries a wash (P12) | P12 |

## Open, defaults taken
- Empty copy "Nothing planned" and private copy "Private recipe, 7 pm." (KW-W7, KW-W8, ruled): no code to match yet.
- Reduce Transparency flat mix: sheet 88 is silent.
- "Done" means KW-W1 to W4 and W7 captured as light, dark and empty screenshots, with W5, W6 and W8 plain.
- Obsidian screen blend may not render in widgets; if not, use a pre-blended colour at 26%. Default taken.
