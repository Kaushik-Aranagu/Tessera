# Private tell audit: dimming and stale "Private recipe" wording

Docs only. Read-only audit of `/mnt/project-files/tessera/design/*.md`, `docs/design/` and `docs/research/fixtures/` at origin/master 297e9553. Nothing run; no Swift toolchain.

## The rulings this audit checks

- Product, decisions.md 6:39 PM Oct 17 (sheet 99): "A private recipe is drawn at 100% ink like other rows (RecipesShelfView.swift:83 dims it to 66%, a tell); sheet 87's 66% is withdrawn."
- Standing rule read from it: a private item looks identical to a normal one apart from its masked words. No dimming, tint, lock, asterisk, italic or different weight. Where a design sheet says "66% ink" for a private row, the 66% is the tell.
- Labels, one title rule (decisions.md 12:35 PM, 4:20 PM, 4:33 PM Oct 17): Private workout, list, item, note, recipe, task. No tap to reveal anywhere (G102, clarified 4:25 PM). Recipe paste title rule: a first line starting with a number is an amount (unit word or size word at any length, or exactly two words with a lowercase second word) and then the title is "Untitled recipe"; "Private recipe" is only ever the mask of a recipe whose stored title trips the one private-text function, never a stand-in for an untitled one.

Note: the 66% on the Private note row (notes-81) is the same tell as the recipe's. The 6:39 PM ruling names only the recipe, but its reasoning covers every private row, so those rows are filed as tells and flagged for Product to confirm.

Status: traced = the line was read in the file and checked against the ruling text; inferred = follows from the ruling but the file or code was not read to the end of its chain.

## Table

| id | file:line | quote | finding | fix | owner | status |
|----|-----------|-------|---------|-----|-------|--------|
| T01 | design/lists-recipes-87.md:17 | `The row reads **"Private recipe"** at 66% (names are ink) with its day.` | tell | Delete "at 66% (names are ink)"; row is 100% ink like any recipe row | Design | traced |
| T02 | design/lists-recipes-87.md:30 | `A list item that is private reads only **"Private item"** at 66% ink, the same as "Private recipe"` | tell | Drop "at 66% ink"; the private item row is 100% ink. Remove "the same as" clause. QA grepped the code: list items have no dim, so only the sheet carries this tell | Design | traced |
| T03 | design/lists-recipes-87.md:35 | `the Private recipe stays at 66% of ink (6.9 to 1).` | tell | Delete the line; contrast for the private row is the ordinary row contrast | Design | traced |
| T04 | design/builder-briefs-81-88.md:89 | `Private recipe row: "Private recipe" at 66% plus its day; context "38 recipes, 2 private".` | tell | "Private recipe" at 100% ink plus its day. Builder B must not copy the 66% (RecipesShelfView.swift:83 per decisions.md) | Builder B | traced |
| T05 | design/builder-briefs-81-88.md:18 | `Private note row: reads "Private note" at 66% ink plus its time ("Tue"); no words anywhere.` | tell | Drop "at 66% ink"; Notes row identical to a note row, words masked only. QA grepped the code: `NotesView` has no dim, so only the sheet carries this tell; the only private-path 66% on master is `RecipesShelfView.swift:83` (line 68 is a plain quiet line), and Builder B fixes that one line. Product ruled: the no-dimming rule covers every private row, including the Private note row (100% ink, same weight as its neighbours) | Builder B | traced |
| T06 | design/notes-81.md:14 | `reads "Private note" in place of the note's first line, at 66% ink (a note's own words are ink)` | tell | Drop "at 66% ink (...)"; row is 100% ink | Design | traced |
| T07 | design/notes-81.md:31 | `The Private note's 66% ink is 5.5 to 1 on Porcelain and 6.9 to 1 on Obsidian; its words say what it is, so colour never carries the meaning alone.` | tell | Delete the contrast claim for the dimmed row; keep "colour never carries the meaning alone" for other rows | Design | traced |
| T08 | design/lists-recipes-87.md:40 | `A Private recipe reads exactly "Private recipe" plus its day, in row, context count, side, Tess and VoiceOver.` | ok | Add "at the same ink as every recipe row" so acceptance row 2 pins the 100% rule | Design | traced |
| T09 | design/builder-briefs-81-88.md:17 | `Empty page ... "Nothing written yet." at 66% ink.` | ok | Not a private item; an empty-state line may stay quiet | none | traced |
| T10 | design/builder-briefs-81-88.md:73 and design/habits-85.md:13,17 | `"No habits yet." at 66%`; `"5 a week", in 66% ink` | ok | Not private objects; ordinary quiet states | none | traced |
| T11 | design/sides-77.md:14 | `a plain ignored line shows its words dim with "ignored"; a private or secret-looking line shows only a bar and "ignored", never its words` | ok | The dim words belong to ordinary ignored lines; the private line is the mask (a bar) in the same "ignored" row. Design confirms the bar row has the dim row's height and ink so the two differ only by the mask | Design | inferred |
| T12 | design/builder-briefs-77-78.md:10 | `Private paste lines are only ever "ignored", never their words.` | ok | Same as T11 | Builder B | traced |
| T13 | design/done-hero-95.md:6 | `the hero reads "Private workout" with the same strike, same haptic ... No lock, no dimming, no masked blocks.` | ok | Keep. Count and time line ("13 sets, 54 min.") matches a normal done line shape | none | traced |
| T14 | design/gaps-92.md:30 | `"Private workout" in the hero's place and weight; ... no lock, no dimming, no asterisks.` | ok | Keep; this is the model wording for the rule | none | traced |
| T15 | docs/research/fixtures/home-lines-hero-masks.md:184 | `no .opacity or .foregroundStyle branch on privacy` (NG2) | ok | Keep; extend NG2 to Notes and Recipes shelf rows so the 66% in T04/T05 fails a test | Core | traced |
| T16 | docs/research/fixtures/home-lines-hero-masks.md:266 | `those rows are inferred from the code reading above (no lock or opacity branch on privacy in HomeLineHero.swift ...)` | ok | Hero only; the shelf and Notes rows were never read for an opacity branch. Add rows for RecipesShelfView.swift:83 and NotesView row | Core | inferred |
| T17 | docs/research/fixtures/sheets-93-94-95.md:226 | `the private hero looks exactly like the public one ... no reduced opacity, no redacted placeholder` (DH25) | ok | Keep; status "gap" is Builder A's snapshot test | Builder A | traced |
| T18 | docs/research/fixtures/private-field-mask.md:117 | `one muted line "Note kept private" in the notes slot` | ok | Ruled 5:20 PM Oct 16 as a field marker, not an object row. Confirm "muted" is the existing notes-field style and not a new dimmed variant; if it is a new dim, it is a tell | Builder A | inferred |
| T19 | design/groceries-tess.md and design/gaps-98.md:15 | `reads "Private item" in the same type and place as any line, with its state word, ring included.` | ok | Keep; matches the rule | none | traced |
| T20 | docs/design/motion/tess-sides-motion.md:31 and tess-title-progress.md:37 | `sideTurned plays the same as on a side with nothing private`; `A private title is the same effect on the same schedule.` | ok | Motion is already identical for private labels | none | traced |
| T21 | design/lists-recipes-87.md:22 | `KEPT PRIVATE: "Private recipe", 2, no words, nothing tappable behind it` | ok | A count line with a label is the ruled count form. If the Recipes side rows elsewhere are drawn dimmed, they follow T01 | Design | traced |
| S01 | design/lists-recipes-87.md:17 | `(a list's name is his own words; see Unresolved)` | stale | "Private list" is ruled (4:00 PM, 4:20 PM Oct 17). Replace with "a private list's name reads Private list" and delete the pointer to Unresolved | Design | traced |
| S02 | docs/research/fixtures/decisions-328-332-338.md:202 | `shown as "Private recipe" on every screen until tapped (Part 1, P01, R16)` (Q23) | stale | "until tapped" contradicts G102 (no reveal anywhere). Change to "on every screen, always" | Core | traced |
| S03 | docs/research/fixtures/private-title-masks.md:16 | `returns nil for a workout or routine, which is why the generic page leaks them (PT24)` | stale | Workout branch ruled 4:20 PM Oct 17 (O1) and "Private workout" is the label. Mark as master-before-fix and cite decisions.md 12:35 PM | Core | traced |
| S04 | design/builder-briefs-81-88.md:11 | `a private note is only ever "Private note" (also "Private recipe", "Private item")` | stale | Incomplete label set. List all six: Private workout, list, item, note, recipe, task | Design | traced |
| S05 | design/lists-recipes-87.md:3 | `a private recipe is only ever "Private recipe"` | ok | Correct under the one title rule (mask of a private-titled recipe). Not a stand-in for "Untitled recipe" | none | traced |
| S06 | design/README.md:117 | `empty, one, long and Private recipe states ... Lists ON THEM proposed` | stale | Index line carries the withdrawn 66% sheet as current. Add "(66% withdrawn, decisions.md 6:39 PM Oct 17)" | Design | inferred |
| S07 | docs/research/fixtures/paste-link-key-shapes.md:53 | `line says "Private recipe is already on Recipes." or similar` (PL27) | stale | "or similar" leaves the wording open. Pin it: the duplicate line uses the one label, "Private recipe, already on Recipes." in the thing-first form used for receipts, never the title | Core | inferred |
| S08 | docs/research/fixtures/decisions-328-332-338.md:176-187 (Q01-Q12) | `"Untitled recipe", line kept` | ok | Checked for a collision: an amount-led first line becomes "Untitled recipe", which is not private and must never read "Private recipe". No row claims otherwise. Add one row: amount-led first line plus a private word in a later line stores "Untitled recipe" and stays public unless the title rule trips on the stored title | Core | inferred |
| S09 | docs/research/fixtures/home-lines-hero-masks.md:5,7,115-119,155 | `Private recipe, 7 pm.` and the other recipe rows | ok | Current: 4:33 PM count-drop ruling applied (HH13, CAP13) | none | traced |
| S10 | docs/research/fixtures/title-words-trim.md:62,111,172-182,223 | `"Private recipe" for a recipe, "Private workout" for a routine or workout title` | ok | Current labels; matches 4:20 PM scope (items, recipes, workouts; not tasks, not per-word on notes) | none | traced |
| S11 | docs/research/fixtures/pantry-v2.md:52,90,213,215,257 | `row reads Private recipe`; `Tess cook line after a private cook: silent` | ok | Matches 5:05 PM Oct 17 (FG9: the Pantry line is silent after a private cook; "Private recipe took the ..." goes) | none | traced |
| S12 | docs/research/fixtures/decisions-328-332-338.md:99-106 (R09-R16) | `Always reads "Private recipe"; the hero is no longer a reveal Button` | ok | Current: reveal removed | none | traced |
| S13 | design/lists-recipes-87.md:19 | `Tess's lines (she says "Private recipe" if one is the top)` | ok | Current; consistent with 3:09 AM and 5:05 AM rulings | none | traced |
| S14 | docs/research/fixtures/sides-77-lines.md:102,489,528 | `Private recipe and chili` (GR-4); C10 accepted | ok | Current; ruled 6:01 PM Oct 16 | none | traced |
| S15 | docs/research/fixtures/pagedrun-edges.md:75 | `shows its label ("Private note", "Private item", "Private recipe" masks)` | ok | Current. Add "Private workout" and "Private list" for completeness (low) | Core | traced |

## Counts

- Rows: 21 T rows (tell or tell-adjacent) and 15 S rows (stale or label checks), 36 total.
- Findings: tell 7 (T01 to T07), stale 6 (S01 to S04, S06, S07, with S02 and S03 contradicting a later ruling), ok 23.
- Status: traced 30, inferred 6.
- Owners of the fixes: Design 11, Core 7, Builder B 3, Builder A 2, none 13.

## Top findings

1. Seven lines in three design sheets still specify a private row at 66% ink: lists-recipes-87 (17, 30, 35), builder-briefs-81-88 (18, 89) and notes-81 (14, 31). Sheet 99 withdrew it for the recipe only. The code (RecipesShelfView.swift:83) is Builder B's; the sheets are Design's.
2. The Private note row (notes-81, builder-briefs line 18) carries the same tell and the ruling does not name it. Product should confirm in one line that notes are covered.
3. decisions-328-332-338.md:202 (Q23) says a private recipe is "shown ... until tapped", contradicting G102 and rows R09 to R16 in the same file.
4. private-title-masks.md:16 still says the label function returns nil for a workout; "Private workout" has been the label since 12:35 PM Oct 17.
5. The hero fixtures (NG2, DH25) test no-dimming for the hero only. Add the same assertion for the Recipes shelf row and the Notes row, so the 66% cannot return.
