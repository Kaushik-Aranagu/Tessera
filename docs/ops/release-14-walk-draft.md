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
   Do: add "dentist" and "Blood orange" to Groceries; open a recipe titled "Dentist cake".
   See: "dentist" reads "Private item" and "Dentist cake" reads "Private recipe" (expected, widest wall); "Blood orange" stays raw (the stays-raw check after the 4:22 PM trim, #890 parity test). A plain task "dentist" still reads "Dentist" (Product has not ruled; not a fail).
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
   See: state words are plain ink (no ochre); OUT bold with ring, LOW semibold, readable in Porcelain and Obsidian. Plain ink is the end state; areaLean only on caps labels and the index line.
   PASS / FIX FIRST. Only if #917 is in the release.
10. #871 copy phrase and starter lists. Tess ask bar, then Kitchen > Lists.
   Do: say "copy packing for lisbon"; then "copy keys for mum".
   See: receipt "Packing, Lisbon, new list."; repeat "Packing, Lisbon, already a list."; starters Packing, Gym bag and one more appear once, with no second "Packing" if he already had one; "copy keys for mum" must NOT answer "no list called ...".
   PASS / FIX FIRST.
11. #886 recipe parser. Paste a recipe, first line "3 eggs benedict", then "1. Preheat the oven", then "2 large eggs".
   See: "3 eggs benedict" is the title; a numbered step is never the title; "2 large eggs" still reads as a title (known low, Product ruled it must not; Core's next PR).
   PASS / FIX FIRST.
12. #884 capture-miss lows. Tess ask bar.
   Do: type "dentist by 4.15"; paste a phrase over 600 characters.
   See: first is not read as money; long phrase gets a fixed refusal line, nothing written; the refusal reads "That's too long to send. Say it shorter." Not walkable on this release: the cook-running rule (nothing goes to Claude while a cook runs, TessModel.swift:100-107) has no cook to run, since RecipePage.cookModeReady is false and master has no cook view; it stays a code check until cook mode lands.
   PASS / FIX FIRST.
13. #564 question walls. Tess ask bar.
   Do: ask "was $12 too much?" and "is 82.4 good?".
   See: "That stays on this phone." (decisions 2:30); a private note or "Didn't catch that." is a FIX FIRST. Head 72192473 PASS; this exact wording is UNVERIFIED.
   PASS / FIX FIRST.

## No walk (engine or test only)
- #868 paste duplicate lows: no UI change (copy tail shared, test only).
- Docs PRs #911, #915, #916, #918, #919, #920, #921: no walk.
- core/g105b (221d7444): no PR yet; not in 14.

## Motion feel (added by the motion lab, Oct 17 PM; quick looks after the numbered steps, never blocks)
M1. Haptic sanity. Finish one task or one workout: the haptic map says ONE done pattern (three quick rising taps), or ONE `.success` if the workout set a new best; never two buzzes, never a heavy medium thud. KNOWN until Builder A's migration PR (haptics-migration-table rows 17, 18, 25) is in the release: a task finish buzzes twice (raw medium 0.8 plus the soul's `.success`, TessSoul.swift:143), and a logged set and a finish do too; that is a known row, not a fail. FIX FIRST only if the release claims the migration and a finish still buzzes twice. Pantry row tap opens the object page, no haptic, no state change, no ochre (a private row opens nothing). (Source: Motion lab, 9:45 PM PT Oct 17; the migration rows are UNVERIFIED by Ops.)
M2. Soul sanity. On any screen she blinks and breathes at rest; for a private item or private workout she does nothing different (no glance, pause or beat). With Reduce Motion on she should stay at full strength (no dimming); KNOWN until the soul fix PR (she fades to a loosened frame today, TessSoul.swift:155-160), not a fail. FIX FIRST if she reacts to a private thing.
M3. Low Power. With Low Power on, FIX FIRST only if the release contains the Low Power flag PR (G219); until then Low Power does nothing to screens and sides (KNOWN, MotionPolicy.swift:5-11 reads Reduce Motion only) and the zoom ignores Reduce Motion too (G269). When the PR is in: a quick crossfade (about 150 ms), no sliding or zoom; Tess keeps her own Low Power look (slower, fewer lights); haptics still play for his own touches.
M4. Rest end (needs a workout). Log a set, let the rest run out with the app in front: ONE heavy buzz (`.timeUp`) at 0, Go appears; note whether a sound plays (not a fail, the in-app haptic and the Live Activity alert can both fire). Skip a rest: no heavy buzz. KNOWN until Core's rest-end notification (N2) lands: with the phone locked the Live Activity flips to Go silently; not a fail. Lock-screen part UNVERIFIED.
M5. UNDO. Finish a task, tap UNDO (a finished task's UNDO window is 10 s). KNOWN until the UNDO style is silenced: UNDO plays two ticks today (press `.selection` plus `.decrease`, CaptureParts.swift:141 and BottomChrome.swift:132); not a fail. Target: one light decreasing tick only.
(The cook timer end is not walkable: no cook view in release 14, UNVERIFIED.)
(The #662 stroke tick, #786/#806 swipes and #871 copy are already steps 1, 2, 3 and 10 above.)
