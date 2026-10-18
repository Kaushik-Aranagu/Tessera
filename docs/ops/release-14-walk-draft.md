# Release 14 walk (DRAFT, post-install)
Rules (pin-release, next-build-walk): runs after install, never blocks; a FIX FIRST becomes a roll-forward fix in the next release; known rows never fail it.
Release SHA: UNVERIFIED (not named in the gate table; heads below are the table's, #917 is a candidate). Mark each step PASS / FIX FIRST.
Default: Porcelain, phone. Each step needs a private/test item; never type a real key (use the fixture fake).

## Owed from pin-walk-next
1. #662 Home stroke (static only). Home, bottom band (y about 760).
   Do: swipe sideways from the band; tap Review's foot link at that height; scroll vertically from that height; stroke across Tess; pan from the ask bar across her.
   See: sideways moves Home; foot link opens Review; vertical still scrolls; Tess stroke works; the ask-bar pan is NOT a stroke.
   PASS / FIX FIRST. If SoulStrokeHomeUITests failed on the first simulator run: revert #662 (not a walk result).
2. #786 Lists swipe to remove. Kitchen > Lists, open a list.
   Do: swipe a row left to remove; then swipe the page sideways.
   See: row removes with its receipt and UNDO; the side swipe still changes page; the two do not fight.
   PASS / FIX FIRST.
3. #806 Lists reusable/reset. Kitchen > Lists, a reusable list.
   Do: hold the fold; then side swipe; then row swipe. Reset the list.
   See: the hold does not fight either swipe. Reset plays .aisleCleared: UNVERIFIED (waits on Builder B's next PR; may be absent in 14).
   PASS / FIX FIRST.

## Release 14 items
4. #885 Groceries and Lists, private rows. Kitchen > Groceries, add "dentist"; also on a list.
   Do: tap the row once.
   See: row reads "Private item" (never the words); one tap strikes it at once, no reveal step; UNDO brings it back.
   PASS / FIX FIRST.
5. #890 one private-title check. Groceries, then Recipes.
   Do: add "Blood orange" to Groceries; open a recipe titled "Dentist cake".
   See: "Private item" and "Private recipe" (expected, widest wall). A plain task "dentist" still reads "Dentist" (Product has not ruled; not a fail).
   PASS / FIX FIRST.
6. #895 mask sweep. Rename a routine to "Knee rehab day"; start and finish it. Look at Home, Day log, History.
   See: "Private workout" everywhere he can read; Claude Home-done line must not name it. Op-log summaries masked: UNVERIFIED (review-895 FIX FIRST 22f38e8a closed, head not re-read here).
   PASS / FIX FIRST.
7. #912 recipe and object pages. Kitchen > Recipes, a private recipe; its original page; an ingredient or list item object page.
   Do: tap the title; open the original.
   See: title stays masked, no tap-to-show; object page shows only the masked label, no fields or notes.
   PASS / FIX FIRST.
8. #913 kept links. Kitchen > Recipes shelf, kept links.
   Do: Read a link; Remove another.
   See: row shows host only (no path, "www." dropped). Read opens Paste with the link. Remove speaks "host, removed." with no UNDO (known low, not a fail).
   PASS / FIX FIRST.
9. #917 Pantry. Kitchen > Pantry, rows in low and out.
   See: state words are plain ink (no ochre); OUT bold with ring, LOW semibold, readable in Porcelain and Obsidian. Interim until areaLean lands (known row).
   PASS / FIX FIRST. Only if #917 is in the release.
10. #871 copy phrase and starter lists. Tess ask bar, then Kitchen > Lists.
   Do: say "copy packing for lisbon"; then "copy keys for mum".
   See: receipt "Packing, Lisbon, new list."; repeat "Packing, Lisbon, already a list."; starters Packing, Gym bag and one more appear once, with no second "Packing" if he already had one; "copy keys for mum" must NOT answer "no list called ...".
   PASS / FIX FIRST.
11. #886 recipe parser. Paste a recipe, first line "3 eggs benedict", then "1. Preheat the oven", then "2 large eggs".
   See: "3 eggs benedict" is the title; a numbered step is never the title; "2 large eggs" still reads as a title (known low, Product ruled it must not; Core's next PR).
   PASS / FIX FIRST.
12. #884 capture-miss lows. Tess ask bar.
   Do: type "dentist by 4.15"; paste a phrase over 600 characters; while a cook timer runs say "8 mins".
   See: first is not read as money; long phrase gets a fixed refusal line, nothing written; cook phrases without "timer" may still reach Claude (known partial, narrowing is a later PR). Refusal wording: UNVERIFIED.
   PASS / FIX FIRST.
13. #564 question walls. Tess ask bar.
   Do: ask "was $12 too much?" and "is 82.4 good?".
   See: "That stays on this phone." (decisions 2:30); a private note or "Didn't catch that." is a FIX FIRST. Head 72192473 PASS; this exact wording is UNVERIFIED.
   PASS / FIX FIRST.

## No walk (engine or test only)
- #868 paste duplicate lows: no UI change (copy tail shared, test only).
- Docs PRs #911, #915, #916, #918, #919, #920, #921: no walk.
- core/g105b (221d7444): no PR yet; not in 14.
