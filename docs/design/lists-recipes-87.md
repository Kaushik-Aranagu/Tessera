# 87. Lists and Recipes, the front: empty, one, long, and a Private recipe

**Kaushik's principle, in one line:** one plain line per thing; a private recipe is only ever "Private recipe"; taking a thing away is one gesture with one line and a way back.

Board `mockups/lists-recipes-87.png`, recording `recordings/lists-recipes-87.mp4` (17 s, Porcelain: Recipes scroll past a Private recipe, the right edge opens glance then full side, left edge back, then Groceries removes Rice with UNDO), study `studies/lists-recipes-87.html` (`?play` records). Item E6 of the 8:08 PM refill. Builds on 9 to 12 (`kitchen/lists-9-12.md`, amended by `sweep-19.md`), 65 (`list-remove.md`), 73, 75/76 (`every-side.md`, `depth.md`), 77 (`sides-77.md`), 81 (`notes-81.md`). **Type is in a token block at the top of the study CSS** (`--ty-*`), current Tessera values, so sheet 86's options can swap in without redrawing.

## What the two fronts are
- **Recipes** is the class page of Recipe (every-side.md row 26, sheet 77 "A class page"); there is no other recipe list (screens-inventory #16). Frame: ‹ KITCHEN at 58, Title 44 at 84, context at 146 with the side word ITS OBJECTS at its right, rows from 232, newest first, name Body 21 and the day added at the right (Label 16/600, 66%).
- **Lists** is the shelf of sheet 9, in the sweep-19 frame (Title "Lists", no LISTS label). Tiers kept: the running list at Hero 56 with its state word in `live` ("RUNNING, 9 LEFT": the comma replaces the banned " · "), two at 34, the rest at 21 and 75%. **Groceries is always on the shelf** (9.6), so "empty" means no other list.

## The states
| State | Lists | Recipes |
|---|---|---|
| Empty | Context "Just Groceries"; Groceries at 56 "NOTHING TO GET"; one quiet line "No other lists yet."; Tess `Say "new list: packing" and I'll start it.` | Context "None yet"; "No recipes yet." at 66%; Tess `Paste a link or a page and I'll read it.` No art, no guilt |
| One | "2 lists, Packing running": Packing 56, Groceries 34; Tess "Packing has 9 left." | "1 recipe", one row "Tacos, Tue"; Tess "Tacos, cooked 2 times." |
| Long | 9 lists, scrolls as one sheet under a pinned back word, fading into Tess's band at 736 (40 pt) | 38 recipes, one line each; a name over 30 characters wraps to two, never cut; Tess "Chili is the one you cook most." |
| Private | (a list's name is his own words; see Unresolved) | The row reads **"Private recipe"** at 66% (names are ink) with its day. Context counts it: "38 recipes, 2 private" |

A private recipe's name appears nowhere: not the row's context, the side, Tess's lines (she says "Private recipe" if one is the top), VoiceOver, Spotlight or the index. No Claude call for it (every-side.md PER 100 G rule). A tap opens it on his phone like any row.

## Sides (each screen declares one)
- **Recipes: ITS OBJECTS (LINKS), matching sheet 77.** Right edge, or the word. Glance: "38" *recipes* (the class's plural; 77 wrote "objects"), "Newest, Dal", "Most used, Chili", foot ALL LINKS. Full side: context "38 recipes", NEWEST (3 named, "and 35 more"), MOST USED with "4 cooks", EVERY RECIPE HAS ("Servings, time, from"), and **KEPT PRIVATE: "Private recipe", 2**, no words, nothing tappable behind it. Tess on both stops: "Chili is the one you cook most." Empty: the right edge opens straight to "Nothing to show yet." One recipe: no "most used" line under 2 cooks.
- **Lists: ON THEM (PARTS), proposed** (every-side.md has no row for the shelf). Glance: "9" *lists*, "Packing 9 left", "Groceries 14 to get", foot ALL OF THEM. Full side: RUNNING, OPEN, REUSABLE, EMPTY, one line each with its count; a tap opens the list; no controls. Only Groceries: the right edge opens straight to "Nothing else to show yet." Tess on both stops: "Packing has 9 left."
- **Swipes:** rows on both fronts have no swipe of their own, so left edge out, right edge in (glance then full side), the middle also goes in (76); up and down read; pull down at the top opens the area index (73). Reduce Motion: every stop a 150 ms crossfade (MotionPolicy); `.selection` once at the full side.

## Removing an item ("Rice, removed.")
As sheet 65 and Product NE11/AQ15, drawn on a list page (Groceries), the same on Packing: swipe left, REMOVE rises in `live` at 60 pt, commits past 96, the rows close up, the count rolls ("9 to get" to "8 to get"), Tess "Rice, removed." with UNDO under her line. **UNDO is 10 s** (a change; 10 s under VoiceOver), one app-wide slot; UNDO returns the row wet and Tess says "Rice, back on Groceries." Never a hold, a red row, a confirm or a trash can. Shelf and recipe rows are not removed by swipe; removing a list or recipe is its own page's act (not drawn here).

## Accessibility
- **VoiceOver:** back, title (heading), context, side word (button), then one stop per row reading name then day ("Private recipe, Wednesday"); a list row carries custom actions Check off and Remove (Remove announces "Rice, removed."); each side is also a custom action ("Show its objects", "Show on them"). Then Tess's line.
- **Dynamic Type AX3:** one column; Title 58; names wrap in full; the context wraps and the side word drops under it; the day drops under its row; Tess at most 3 lines; rows at least 44 pt.
- **Obsidian:** bg #121014, ink 245,242,236, context #B8A3FF, Tess #86B4FF, `live` #FF7D62; the Private recipe stays at 66% of ink (6.9 to 1).
- **Reduce Motion:** crossfades 150 ms for stops and the row leaving.

## Rows for acceptance
1. Each empty state is one quiet line plus Tess's line; nothing guilt, dotted or counted.
2. A Private recipe reads exactly "Private recipe" plus its day, in row, context count, side, Tess and VoiceOver.
3. Long lists scroll as one sheet, back word pinned, fade into the band, nothing cut.
4. Recipes' side matches 77 with a private count line; Lists' side as drawn; empty sides never dead.
5. Removing says "Rice, removed." with 10 s UNDO; no "at" before a time, no "…", cobalt only for Tess.

## Unresolved
1. **Lists' side kind and word (ON THEM, PARTS) and Tess's phrase "new list: packing"** are proposals; Core owns the grammar.
2. every-side.md row 26 says ITS OBJECTS is PARTS, sheet 77 says LINKS; drawn as 77. On Recipes' own front the word could read MOST COOKED instead.
3. Does a list or a list item get a private label ("Private item") when PrivateFacts walls it? Drawn only for recipes.
4. Sheet 86 may change type steps; only the token block should need to change.
