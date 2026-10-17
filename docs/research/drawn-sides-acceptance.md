# Drawn sides: acceptance rows (Research BQ)

*Research, Oct 16 to 17. Docs only. One gate per drawn side, so every builder pull request after Core 0ak (SideHost) has its rows ready. Read against origin/master cde6d54 (no SideHost on master or on any remote branch: `git log --all -S"struct SideHost"` finds nothing). Every value is made up; placeholders are hunter2, tacocat and 4417.*

**Sources, and how a row cites them.**
- `D2:37`, `D2:40`, `D2:41`, `D2:44`, `D2:45`, `D2:56`, `D2:59`, `D4:46`, `D4:55` are Product's entries in `product/decisions.md` on the shared folder (lines 33, 29, 37, 25, 23, 19, 17, 11 and 7 as of this writing). `D2:11` is the Health round trip entry (line 63).
- `ES:n` is Design's `every-side.md` line n, and `DE:n` is `depth.md` line n, both at ee1b0d6 (the same text as the shared folder; e9efac4 set the Reduce Motion fade to MotionPolicy's 150 ms).
- `KS n` is the Kitchen lead's `product/kitchen-sides-acceptance.md` row n.
- Fixture rows are reused, not copied: `SL-`/`GL-` (`fixtures/side-lines.md`), `DP` (`fixtures/depth-76.md`, with Design's rulings at its end), `SH` (`sidehost-review-checklist.md`), `PL1` to `PL4` (`screens-inventory-check.md`), `PM` (`fixtures/private-field-mask.md`), and the food table (`food-table-usda.md`, `fixtures/food-table-20.json`). GL-7 and GL-15 are superseded by DP and are not used.

**Setup for the simulator rows.** iPhone 17 (402 by 874 pt), launched with `-demo -demoTime 18:10 -resetDemo`, so "today" is Friday Oct 16, 2026 at 6:10 pm and this week is Oct 12 to 18. Launch flags work on the simulator only (`App/LaunchFlags.swift`). "Glance" is stop 1 and "full side" is stop 2 (D2:37). "Right edge in" means a pan that starts in the last 32 pt, above Tess's band (DE:15). "Middle" means a pan that starts between the edge zones (DE:16).

## Summary

| Side | Screen (sheet 75 #) | Owner | Glance: big fact, small 1, small 2 | Pages | Rows |
|---|---|---|---|---|---|
| THE SETS (PARTS) | A workout, and Workout finish (9, 12) | Builder A (Training lane; see Q13) | "20" *sets*, "Bench Press 82.5 × 7", "5 exercises" | 1 | 13 |
| PER 100 G (FACTS) | An ingredient (18) | Builder B (Kitchen lane; Core bundles the table; see Q13) | "121" *kcal*, "19.7 g protein", "4.1 g fat", source line under it | 1 | 13 |
| HISTORY, REP MAXES, MUSCLES, SETUP (FACTS) | An exercise (8) | Builder A 0p rollout (D2:59) | "82.5" *× 7*, "today, a best", "about 102 kg for 1" | 4 | 15 |
| WHERE IT'S MENTIONED (LINKS) | A note (23) | Builder B 0y | "3" *places*, "Tile quotes", "Weekend plan" | 1 | 11 |
| ITS STORY (BEFORE) | A task (3) | Builder B 0y; Core 0am move count | "2" *moves*, "made Tuesday", "in Plan my day" | 1 | 12 |
| WHAT'S IN ONE (FACTS) | Backups (25) | Builder B 0y | "4 am" *last one*, "7 kept", "Never your Claude key." | 1 | 11 |
| THE DAYS (PARTS) | Review tab (20) | Builder B 0y (D2:59) | "5" *of 7 days*, "Wednesday, 6 tasks", "2 to go" | 1 | 12 |
| **Total** | | | | | **87** |

## Every drawn-side pull request also runs these

These are SideHost's own rows. A drawn side passes only when they pass on that side, so each builder runs them once on the side they add, and doesn't rewrite them here.

| What | Rows (reused) | From |
|---|---|---|
| Glance geometry: right half from x 150, 34 pt fade, front at 30%, label, Hero 56 big fact, two Body 19 small facts, the word at the foot, no haptic | SH1 | D2:37; ES:90-93 |
| Full side: past half width or tap the foot word; one `.selection`, the only tick | SH2, SH3 | D2:37; ES:95, DE:39 |
| Step back one stop at a time; left edge goes straight to the front | SH4, DP45, DP46, DP52 | D2:37; DE:14 |
| Tess's band: a pan at or below the band is hers | SH6, DP67 | ES:16 (rule 4); DE map |
| Tess's line is the same at both stops, lands at 420 ms | SH7 | ES:105 |
| `sideTurned` only into stop 1 and back to the front | SH8 | ES:121 |
| No controls on a side | SH9 | D2:41 (a); ES:18 |
| Empty small fact left out; no big fact opens straight to the full side; "and N more" from four | SH10, SH11, SH12 | ES:94, ES:157 |
| No Claude from any side or glance; receipts count unchanged; rewording off | SH21, SH22, SH23 | D2:40 (3), (4); D2:41 (a) |
| Reduce Motion: each stop is a 150 ms crossfade, no Tess glance | SH29 | ES:97; DE:53 |
| VoiceOver: glance label, big fact with its unit, small facts, word as a button; escape one stop at a time | SH30, SH31, DP56, DP77 | DE:52 |
| Largest text size: wraps, never clips; big fact drops to Title 44 | SH32, DP10 | DE:54 |
| The screen declares a side in the registry | SH37 | D2:41 (c) |

---

## 1. Workout: THE SETS (Builder A)

**What it reads on master.** A workout opens on the generic page (`Features/Objects/ObjectPage.swift:216-274`), whose Contents rows show only "N logged" per entry (`:294-300`). Counts come from `TrainingLedger.summary(of:)` (`TesseraCore/Sources/TesseraCore/Training/WorkoutSummary.swift:42-76`): working sets only, since warm-ups and sets with no weight drop out in `loggedSet` (`Training/TrainingLedger.swift:265-273`). Bests come from the same summary (`records`, `:47-68`), at most one per exercise. Nothing on master picks a top set across a whole workout (Q2). The finish screen is `Features/Workout/WorkoutFinishView.swift:13`, and its swipe down drops into today (`:88-92`).

**Fixture W1, Push Day A, today 5:02 pm to 5:54 pm.** Bench Press: a warm-up 40 × 10, then 82.5 × 7, 80 × 8, 80 × 8, 80 × 6 (82.5 × 7 is a best, as in DP12). Overhead Press 4 sets at 50 × 8. Incline Dumbbell Press, Triceps Pushdown and Lateral Raise, 4 sets each. That makes 20 working sets in 5 exercises, with one best.

| ID | Steps | Expected | Source | Reuses |
|---|---|---|---|---|
| SA-SETS-1 | Glance. Review, tap today, tap Push Day A (the workout's page). Right edge in, let go before half width | The label THE SETS. Big "20" *sets*. Small 1 "Bench Press 82.5 × 7" (4 / 20), the top set (Q2). Small 2 "5 exercises" (2 / 11). Foot word ALL SETS (Q1). Tess's line in the band: "20 sets in 52 min, one new best." The warm-up is not counted | ES:137; D2:37 | GL-8, SL-WK1, SH1 |
| SA-SETS-2 | Workout finish. Finish W1 in the live workout, wait for the totals, tap the word THE SETS in the context line | The same glance as SA-SETS-1, opened by the word only (the finish has no side swipe). A swipe down from the finish's front still drops into today (`WorkoutFinishView.swift:88-92`), and a swipe down never opens the side | ES:43 (row 12) | GL-8 |
| SA-SETS-3 | Full side. From SA-SETS-1, pull past half width | Five exercises in the workout's order, each with its sets in logged order ("82.5 × 7", "80 × 8"). The warm-up shows as "warm-up 40 × 10" and isn't counted. The best set carries the word "best". One `.selection` | ES:41 (row 9: "becomes its own page, no longer the generic one"); ES:95 | SH2 |
| SA-SETS-4 | The best word. Search the side's strings and VoiceOver labels | "best" only. Never "Record" (the Set field's name, `Catalog/SystemCatalog.swift:162`), never "PR", never "record" | side-lines.md rule 4 | SH28 |
| SA-SETS-5 | Pages. Look under the title on the full side | No facet row: THE SETS is one page. There are no dots and no counter | DE:34 (facet words only for a side with pages) | |
| SA-SETS-6 | Run end. On the full side, swipe left in the middle by 120 pt. Then turn on Reduce Motion and do it again | It rubber-bands and springs back over 380 ms. There's no page after it and it never wraps. No haptic. Under Reduce Motion nothing moves and nothing fades | DE:28-29, DE:38; DE:69 | DP35, DP39 |
| SA-SETS-7 | No run on the front. On W1's front, swipe left in the middle (x 200) by 80 pt | There's no run, so the middle goes in, to the glance (a workout isn't one of a run; Q14) | DE:16 | DP34 |
| SA-SETS-8 | Private. Give W1 the notes "left knee sore, see Dr. Lin". Seed private memory O1 (PM fixture) with `evidence` linking W1. Add a Pull-up entry (`bodyweightPlus`) with +10 kg × 6. Open both stops | No note words on either stop ("knee", "Lin"). No memory appears on THE SETS at all (Linked from is the front's, masked as PM3). The pull-up reads "+10 kg × 6", and no body weight or "kg" body number appears anywhere | D2:41 (a); D2:45; D4:46 (3) | PM3, SL-E3, SL-E4 |
| SA-SETS-9 | Empty: all skipped. Finish a workout with 0 sets logged, all 5 entries skipped. Right edge in | No glance (a zero isn't a big fact). The full side opens straight away and lists the 5 exercises, each "skipped". Tess's band is empty | ES:157 | GL-E4, SL-WK3, SH11 |
| SA-SETS-10 | Planned workout. Open Saturday's planned Legs A (not started; 5 entries, 15 target sets). Right edge in | The glance shows the planned parts: big "15" *sets planned*, small 1 "Back Squat 3 × 5", the first entry's target, small 2 "5 exercises" (Q3). Tess: "Legs A, last done 6 days ago." The page's Start workout key stays on the front | ES:41 ("finished or planned"); ES:18 | SL-WK2 |
| SA-SETS-11 | One item. A workout with one set, Bench Press 60 × 8 | Big "1" *set* (singular). Small 1 "Bench Press 60 × 8". Small 2 "1 exercise" | ES:157 | |
| SA-SETS-12 | Top set rule. A workout whose only sets are 40 × 15 (no set eligible for e1RM, `TrainingLedger.swift:86`) on two exercises | Small 1 names the heaviest set by weight, then reps, earlier exercise on a tie (Q2) | Q2 | DP17 |
| SA-SETS-13 | Live surfaces. (a) During a live workout, swipe left on the exercise lane. (b) In the live cover, open the workout's page through a path word and open its side | (a) The lane keeps x, and the live side is the running order, with no Tess line. (b) A page pushed over the live surface isn't live: THE SETS opens with both stops, as in SA-SETS-1 | ES:19 (rule 7); D2:45 (Design's note) | SH33, SH34, SL-X1 |

## 2. Ingredient: PER 100 G (Builder B, Kitchen lane)

**What it reads on master.** An ingredient opens on the generic page through `RecipeDepth` (`Features/Recipes/RecipePage.swift:298-311`), from the recipe line's link at `:255`. A line with no ingredient link opens the Recipe Line itself (`line.ingredient?.id ?? line.id`), which gets the default side, not PER 100 G. The Ingredient class holds only `aisle` and `isStaple` (`Catalog/SystemCatalog.swift:280-284`). There's no food table on master: "kcal" appears only in the memory screen's body words (`Tess/TessMemory.swift:105-108`). "Where it's used" is `RecipeBook.recipes(using:)` (`Kitchen/Recipes.swift:88-94`).

**The table rules** (`food-table-usda.md` §2 and §4; KS 2): one row per ingredient key, five values per 100 g. kcal comes from FDC nutrient 1008 only, never 2047 or 2048. A row holds one ingredient's values only and is never summed. A missing key is absent, and a missing value stays absent.

**Fixture.** Chicken thigh (FDC 173627): 121 kcal, 19.7 g protein, 0.00 g carbohydrate, 4.12 g fat, 0.0 g fibre, used in Tacos and Chicken curry.

| ID | Steps | Expected | Source | Reuses |
|---|---|---|---|---|
| SA-PER-1 | Glance. Recipes, Tacos, tap "chicken thigh", right edge in | The label PER 100 G. Big "121" *kcal*. Small 1 "19.7 g protein". Small 2 "4.1 g fat" (one decimal; Q8). The source line "USDA FoodData Central" sits under the glance. Foot word ALL FACTS. Carbohydrate and fibre are not on the glance | ES:142; KS glances (PER 100 G) | GL-13 |
| SA-PER-2 | Full side | Five values per 100 g in this order: kcal, protein, carbohydrate, fat, fibre, with "0 g carbohydrate" and "0 g fibre" shown (a zero is a value here). Then the source line. Then where it's used: "Tacos", "Chicken curry", by short name | ES:48 (row 18); KS 2 | |
| SA-PER-3 | All 20 keys. Run `everyFixtureKeyMatchesTheBundleWithinRounding` and open three more keys on the simulator (olive oil, rice, peanut butter) | Each row matches `food-table-20.json` (kcal within 0.5, grams within 0.005). Olive oil: big "884" *kcal*, small 1 "0 g protein", small 2 "100 g fat" | KS 2.1 | food-table tests |
| SA-PER-4 | kcal source. Read the bundle's build check for KS 2.1b (Core names the test) and its script | Every row's kcal is nutrient 1008. No row takes 2047 or 2048, silently or otherwise | KS 2.1b; food-table-usda.md §2 | |
| SA-PER-5 | Never summed. Open the Tacos recipe front and its INGREDIENTS side, Groceries, Review, Home and the Kitchen tab. Search the strings for "kcal", "calorie" and "protein" | No screen shows a total per recipe, day, shop or serving. No amount times the row ("200 g chicken thigh, 242 kcal" never appears). Only PER 100 G shows these numbers, one ingredient at a time | ES:155; KS 2.4; D2:44 (intake is a body fact) | W1 (screens-inventory-check) |
| SA-PER-6 | A missing key. Open "stock" (a mix, so no row) used in Chili | No glance: the right edge opens straight to the full side, which shows only where it's used ("Chili"). Nothing says a row is missing, and there's no dash, "none" or "unknown" | KS 2.2; food-table-usda.md §2 rule 5 | GL-E3 |
| SA-PER-7 | A missing value. A test-double row with no fibre value | The fibre line is absent on the full side. It doesn't read "0 g", a dash or "none". The other four show | task brief; ES:157 | GL-E1 |
| SA-PER-8 | Pages. Look under the title | No facet row; one page | DE:34 | |
| SA-PER-9 | Run end. On the full side, swipe left in the middle by 120 pt. On the front, swipe left in the middle by 80 pt. Repeat under Reduce Motion | Full side: rubber-band, no wrap, no haptic. Front: there's no run (Q14), so the middle goes in, to the glance. Under Reduce Motion the run end doesn't move or fade, and the way in is a 150 ms crossfade | DE:16, DE:28, DE:38, DE:69 | DP35, DP39 |
| SA-PER-10 | Private. Name a recipe "Lin's low-sodium plan" so its title fails `PrivateFacts.isPrivateTitle`, using chicken thigh. Open both stops on chicken thigh | Where it's used reads "Tacos", "Chicken curry", then "Private recipe", never its title (Q10). Tess's line holds no nutrition number and no title. Nothing goes to Claude | D2:41 (a); D2:45 (private label) | SL-I4, KS 2.5 |
| SA-PER-11 | No Claude fill. Turn "Tess asks Claude" on and open "stock" (no row) three times | No ask is made, no Tess Call is written, and receipts don't change. The fill in KS 2.3 waits for the BD4 eval and Kaushik's yes | D2:40 (3), (4) | SH21, SH22 |
| SA-PER-12 | Empty. Type "za'atar" on Groceries (a new ingredient, no table row, no recipe) and open it | No glance. The full side shows one quiet line (Q16; pick "Not in a recipe yet."). Tess's band is empty | ES:157; ES:20 (rule 8) | SL-I3, GL-E10 |
| SA-PER-13 | Tess's line. Rice with buys on Sep 12, 21, 30 and Oct 9; paprika in 3 recipes and no buys | Rice: "You buy it about every 9 days." (needs Core 0am's cadence). Paprika: "In 3 of your recipes." Neither carries kcal, protein or any number from the table | D2:44 (5) | SL-I1, SL-I2, SL-I4, SH26 |

## 3. Exercise: HISTORY, REP MAXES, MUSCLES, SETUP (Builder A, 0p rollout)

**What it reads on master.** `ExercisePage` takes only the exercise class, so it can't know its routine's run (`Features/Exercise/ExercisePage.swift:7-8`). HISTORY, REP MAXES and MUSCLES are a paging window in the middle of the page that takes every horizontal pan (`Features/Exercise/ExerciseViews.swift:39-49`). HISTORY shows only the last 5 sessions (`ExerciseDigest.swift:70`, `Training/ExerciseOverview.swift:23`, `recent: 5`). Its best flag is set only for the best-e1RM session (`ExerciseDigest.swift:84`). REP MAXES is a 1RM to 10RM grid with a dash where nothing was logged, and has no estimates (`ExerciseViews.swift:185-196`, `TrainingLedger.swift:84`). MUSCLES is primary then secondary, without repeats (`ExerciseDigest.swift:61-66`). SETUP has no view, and no file in `Features/Exercise/` reads the exercise's `notes` (PL1).

**Fixture.** Bench Press from Push Day A, with DP12's sessions: today 82.5 × 7 and 80 × 8; Mon 80 × 8; Oct 9 80 × 7; Oct 6 77.5 × 8. The best e1RM is 101.75. Equipment: Olympic bar (`barWeight` 20 kg). Class notes: "Third hole" and "left knee sore, locker code 4471".

| ID | Steps | Expected | Source | Reuses |
|---|---|---|---|---|
| SA-EX-1 | Glance. Push Day A, tap Bench Press, right edge in | The label HISTORY. Big "82.5" *× 7*. Small 1 "today, a best". Small 2 "about 102 kg for 1". Foot word ALL OF IT. Tess: "About 102 kg for 1, estimated." The front's context word is HISTORY | DE:36, DE:45; DE:64 | DP12, DP43 |
| SA-EX-2 | Facet words. Pull to the full side | One row of four words under the title at 196: HISTORY, REP MAXES, MUSCLES, SETUP, in Label 13/700 at .08em, 20 pt apart. The current one is ink and the rest are at 40%. No dots, no underline. Tapping a word goes to its page with no haptic | DE:34, DE:39 | DP36, DP51 |
| SA-EX-3 | HISTORY page. Give Bench Press 23 sessions | Every session, newest first, each with its date, set count and top set, scrolling vertically. Not only the last 5 (master's `recent: 5`). A subclass session (Paused bench press) is included | DE:16 (up and down reads) | DP25, DP23 |
| SA-EX-4 | REP MAXES page | 1 to 10 reps. Logged: 7 reps "82.5 kg", 8 reps "80 kg". Estimated from 101.75 and marked "estimated": 1 rep "102 kg" (the glance's figure; Q7), 2 "95 kg", 3 "92.5 kg", 4 "90 kg", 5 "87.5 kg", 6 "85 kg", 9 "77.5 kg", 10 "77.5 kg" (rounded to 2.5 kg). No dash anywhere | DE:64 (Research BL Q1 ruling) | DP12 |
| SA-EX-5 | MUSCLES page | The catalog's primary muscles first, then the secondary ones not already listed, by name. Facts only, no controls. No muscle is filled by Claude | DE:45; D2:40 (3) | |
| SA-EX-6 | SETUP page | Equipment "Olympic bar, 20 kg", rest "3 min" (barbell default 180 s), reps "8 to 12", progression, then the notes screened line by line: "Third hole" shows, and the other line is counted as "1 line kept private" and never shown | DE:45; D2:44 (PL1 must-fix) | SH16, GL-E8 |
| SA-EX-7 | Pages run end. On SETUP, swipe left in the middle. On HISTORY, swipe left three times | SETUP rubber-bands and never wraps to HISTORY. The routine's run doesn't move. From HISTORY, three swipes land on REP MAXES, MUSCLES and SETUP in turn, each word going ink as its page lands, with no haptic | DE:35, DE:38-39 | DP35, DP36 |
| SA-EX-8 | Step back through pages. On MUSCLES, swipe right four times | REP MAXES, then HISTORY, then the glance, then the front: one step each, and a long swipe never skips | D2:37; DE:14 | DP48, DP49 |
| SA-EX-9 | Routine run end. On Bench Press (first of five) swipe right in the middle. On Lateral Raise (last) swipe left | Both rubber-band, with no wrap and no haptic. The back word PUSH DAY A holds still. From the exercise library (no routine), the middle goes in instead | DE:28-29; D2:59 | DP31, DP32, DP33, DP34 |
| SA-EX-10 | The old window. Pan left starting at x 385 in the middle of the page | The glance opens. On master the window takes the pan and shows REP MAXES; this row fails until the window is gone | DE:70 | DP70 |
| SA-EX-11 | Reduce Motion. Repeat SA-EX-7 and SA-EX-9 | Moving between pages is a 150 ms crossfade. At a page end or run end nothing moves and nothing fades | DE:53, DE:69 | DP39, DP55 |
| SA-EX-12 | Private. Today's workout notes "left knee sore, see Dr. Lin". Pull-up (`bodyweightPlus`) with +10 kg × 6 | No note words on the glance, HISTORY or any page. SETUP shows only screened lines (SA-EX-6). The pull-up shows added load only, never his body weight. A walled line is never the big fact | D2:41 (a); D2:44; D4:46 (3) | DP22, SL-E3, SH16 |
| SA-EX-13 | Empty. An exercise never done (Zercher squat) | No glance: the right edge opens straight to the full side on HISTORY, with its empty line. REP MAXES has no rows and one empty line, with no estimates and no dashes. MUSCLES and SETUP still show their facts. Tess's band is empty | ES:157 | DP16 |
| SA-EX-14 | Bests. (a) One session ever, today 60 × 8. (b) Today 90 × 3, a rep-max best that isn't an e1RM best | (a) "today, the first time", never "a best". (b) "today, a best", which needs the ExerciseDigest change (master flags e1RM only, `ExerciseDigest.swift:84`) | DE:68 | DP15, DP19 |
| SA-EX-15 | VoiceOver. On the full side, focus the facet row; escape three times | Each facet word is a button. Escape steps back one stop (full side, glance, front), not one page. The body is adjustable along the routine ("Lateral raise", with no wrap) | DE:52 | DP41, DP56 |

## 4. Note: WHERE IT'S MENTIONED (Builder B, 0y)

**What it reads on master.** A note opens in `NoteEditor` (`Features/Notes/NoteEditor.swift:7`), whose front already lists its own outgoing links (`:33`, `:75-82`). The side is the other direction: `ObjectStore.backlinks(to:)` (`Engine/ObjectStore.swift:287-289`, live sources only). A private note never links from its words (`Notes/Notes.swift:119-123`), and `resolve` never targets a private note (`:41-46`, PL4 closed).

**Fixture N1, "Garage ideas".** It's mentioned by the notes "Tile quotes" (edited today) and "Weekend plan" (edited Wednesday), and by the task "Call the tiler" (`about`, made Monday).

| ID | Steps | Expected | Source | Reuses |
|---|---|---|---|---|
| SA-MEN-1 | Glance. Notes, open Garage ideas, right edge in (above the keyboard; the editor is not focused) | The label WHERE IT'S MENTIONED. Big "3" *places*. Small 1 "Tile quotes", small 2 "Weekend plan", newest edit first (Q17). Foot word ALL LINKS. Tess: "Mentioned in 3 places." | ES:147; ES:53 | GL-18, SL-N4 |
| SA-MEN-2 | Four or more. Add two more notes that mention it | Big "5" *places*. Small 1 "Tile quotes". Small 2 "Weekend plan and 3 more" (the second name is kept) | ES:94, ES:147; D2:44 (6) | GL-E6, SH12 |
| SA-MEN-3 | Full side | One row per source: "Tile quotes", "Weekend plan", "Call the tiler". Each row opens its source. The note's own links are not repeated here (they stay under the text on the front) | ES:53 (row 23) | SH13 |
| SA-MEN-4 | A source goes. Delete "Weekend plan", come back, open the side | Big "2" *places*. The deleted note is gone from both stops on the next revision | `ObjectStore.swift:287-289` | |
| SA-MEN-5 | Pages | No facet row; one page | DE:34 | |
| SA-MEN-6 | Run end. Full side, swipe left in the middle. Front, swipe left in the middle above the text. Repeat under Reduce Motion | Full side: rubber-band, no wrap, no haptic. Front: no run, so the middle goes in. Under Reduce Motion nothing moves or fades at the end. Typing and text selection in the editor aren't affected by the side's pan | DE:16, DE:28, DE:69 | DP35, DP39 |
| SA-MEN-7 | Private source by title. Make a task "Reset bank pin" (`about` Garage ideas), and seed an old pre-#422 note "wifi password is hunter2 @Garage ideas" (no `isPrivate`, PM16) | Both stops read "Private task" and "Private note" in place of those titles, and no stop holds "bank", "pin", "wifi" or "hunter2". The count includes them ("5" *places*). Opening a row opens the masked page (PM7, PM16) | D2:45 (private label); D2:41 (a) | PM7, PM16, SL-D4 |
| SA-MEN-8 | "@Private note" in a plain note. Write "see @Private note" in Tile quotes | It links nothing. No private note gains a mention, so no side reaches a private note through a link | D2:44 (PL4) | SH20 |
| SA-MEN-9 | A private note's own side. Open a private note (O3, "wifi password is hunter2") in Notes, right edge in | It can't be mentioned, so it has 0 places: no glance, straight to the full side's empty line. Tess's band is empty. No word of its body is on the side | ES:156; D2:41 (a) | SL-N5 |
| SA-MEN-10 | Empty. A new note "Paint colors" that nothing mentions | No glance. The full side shows one line (Q16; pick "Nothing mentions it yet."). Tess's band is empty | ES:157 | GL-E3, SL-N6 |
| SA-MEN-11 | No Claude. With "Tess asks Claude" on, open both stops on N1 and on O3 | No Claude call and no Tess Call. A note is never a public class, so no ask-about-this either | D2:40 (4) | SH21, SH22 |

## 5. Task: ITS STORY (Builder B, 0y; Core 0am counts the moves)

**What it reads on master.** A task opens on the generic page (`ObjectPage.swift:216-274`), masked to "Private task" for a private title once Core 0ai lands (PM7). Its story is in the op log: `OpRecord.action`, `actorRaw` and `createdAt` (`Model/Models.swift:503-526`), with actors `user`, `tess`, `intent` and `system` (`Actions/Op.swift:4-13`). A hand move is `moveTask` (`Tasks/Tasks.swift:93-95`). The nightly roll writes `rolledFrom` and `rolls` (`Catalog/SystemCatalog.swift:209-210`) by `.system`. **Plan my day's keep is the same `MoveTask` by `.user`** (`Features/Home/HomePlan.swift:149`, `:177`), so on master a keep and a hand move can't be told apart (Q4). No helper counts a task's moves yet (Core 0am).

**Fixture T1, "Call the plumber".** Made Tuesday 9:12 am. Moved by hand Wednesday and Thursday (2 `moveTask` by `.user`). Rolled 1 night by itself (Thursday into today). Kept in Plan my day today for 2 pm. `about` links Kitchen sink (a plain note).

| ID | Steps | Expected | Source | Reuses |
|---|---|---|---|---|
| SA-STORY-1 | Glance. Home queue, tap Call the plumber, right edge in | The label ITS STORY. Big "2" *moves*. Small 1 "made Tuesday". Small 2 "in Plan my day" (Q4). Foot word ALL OF IT (Q1). Tess: "Moved twice, and today's the day." | ES:131; ES:35 | GL-2, SL-T1, SH24 |
| SA-STORY-2 | Full side | His story, oldest first (Q15): "Made Tuesday, 9:12 am." "Moved to Wednesday." "Moved to Thursday." "Rolled into today." "Planned in Plan my day for 2 pm." "About Kitchen sink." Times are 12-hour lowercase. Kitchen sink opens its page | ES:35 ("made, moved, planned, linked"); D2:44 (3) | SL-T2 |
| SA-STORY-3 | Rolls aren't moves. Add 2 `rollForwardTasks` ops by `.system` | Still "2" *moves*. Rolls show only as "rolled" in the story, never as misses and never counted as moves | D2:44 (3) | SH25, SL-T2 |
| SA-STORY-4 | A keep isn't a move. Keep T1 in Plan my day a second time | Still "2" *moves*. The story gains "Planned in Plan my day for ..." (Q4) | Q4 | |
| SA-STORY-5 | Whose moves. Move T1 once through Tess ("move the plumber to friday") and once through Siri | Each counts as his move (Q5), so "4" *moves*. A `.system` op never counts | D2:44 (3) | SH25 |
| SA-STORY-6 | Small 2 fallback. A task never kept in Plan my day, with `about` Carbonara | Small 2 is "about Carbonara". With no link and no plan, small 2 is left out | ES:131; ES:157 | GL-E1 |
| SA-STORY-7 | Pages | No facet row; one page | DE:34 | |
| SA-STORY-8 | Run end. Full side, swipe left in the middle. Front, swipe left in the middle. Repeat under Reduce Motion | Full side: rubber-band, no wrap, no haptic. Front: no run, so the middle goes in. Under Reduce Motion nothing moves or fades at the end | DE:16, DE:28, DE:69 | DP35, DP39 |
| SA-STORY-9 | Private. Tasks "Reset bank pin" (secret word), "Take Advil 400mg" (after 0ac slice 2) and "Weigh in 82.4" (a body number, D4:46). Each moved twice. Open both stops | The front is masked to "Private task" (PM7). The side is count only: big "2" *moves*, no small facts, no dates, times, plan or links, and its full side reads "Private task" with "Moved twice." only. Tess's band is empty (Q6), so "today's the day" never tells a date the front hides | D2:45; D2:44 (PL2 fix); D4:46 (1); D2:56 | PM7, SL-T4 (superseded; Q6), SH17 |
| SA-STORY-10 | Private link. A plain task with `about` a private note (O3) | The story reads "About Private note". The row opens the masked page | D2:45 | PM5 |
| SA-STORY-11 | Empty. A task made today at 9:12 am, never moved | No glance (0 moves isn't a big fact). The full side has one line, "Made today, 9:12 am." Tess's band is empty | ES:157 | GL-E4, SL-T3 |
| SA-STORY-12 | Done. Mark T1 done at 5:40 pm | The story ends "Done today, 5:40 pm." The glance's big fact is still "2" *moves* | ES:35 | |

## 6. Backups: WHAT'S IN ONE (Builder B, 0y)

**What it reads on master.** `BackupView` (`Features/Backup/BackupView.swift:10`) is pushed from The week and borrows the edge back swipe (`:155`). The newest copy's date is `BackupKeeper.latestLocal` (`Features/Backup/BackupKeeper.swift:155`). A copy's `Info` holds `createdAt`, `appVersion`, `migrations` and `restoredAt`, with no counts of what's inside (`TesseraCore/.../Export/TesseraBackup.swift:14-27`). Copies are kept for 7 days (`writeRolling`, `:120`). The front says "Seven are kept." even when fewer copies exist (`BackupView.swift:353`), so the glance must count the files, not repeat the front (Q11).

**Fixture.** 7 rolling copies; the newest was written today at 4:00 am. It holds 214 workouts, 38 notes (5 private), 61 tasks, 12 recipes and 9 memories (2 that stay on this phone).

| ID | Steps | Expected | Source | Reuses |
|---|---|---|---|---|
| SA-BAK-1 | Glance. Review, The week, Backups, right edge in | The label WHAT'S IN ONE. Big "4 am" *last one*. Small 1 "7 kept". Small 2 "Never your Claude key." Foot word ALL FACTS. Tess: "The last one ran at 4 am, 7 kept." | ES:149; ES:55 | GL-20, SL-B1 |
| SA-BAK-2 | Full side | What a copy holds, as counts by kind from the newest copy, read-only (Q11): "214 workouts", "38 notes, 5 private", "61 tasks", "12 recipes", "9 memories, 2 stay on this phone", then "your looks and rest day". Then what never goes in: "Never your Claude key", "never the folder's access", "never Health's weights" | ES:55; D2:11 (3) (Health weights in memory only) | |
| SA-BAK-3 | An older copy. Set the newest copy to Thursday at 4:00 am | Big "Thursday" *last one*, in the front's day words ("yesterday" when it was yesterday, `BackupView.swift:350-352`; Q12) | Q12 | |
| SA-BAK-4 | Fewer copies. Leave 3 copies in the folder | Small 1 "3 kept", never "7 kept" | Q11 | |
| SA-BAK-5 | No controls. Look for Save a copy, Restore, the folder word and Stop using it on both stops | None are on the side. Restore and every control stay on the front | ES:18 (rule 6); ES:55 | SH9 |
| SA-BAK-6 | Pages | No facet row; one page | DE:34 | |
| SA-BAK-7 | Run end and the edge. Full side, swipe left in the middle. Then from the front, pan right from x 2 | Full side: rubber-band, no wrap, no haptic. Under Reduce Motion nothing moves or fades. From the front, the edge pan pops to The week once, one gesture with `EdgeSwipeBack`, never a pop plus a step | DE:28, DE:69; DE:14 | DP72, DP39 |
| SA-BAK-8 | Private. With the fixture's private notes and memories, read every string on both stops, and grep the side's files for key handling | Private things are counts only ("5 private", "2 stay on this phone"). No title, body or rule. No part of any key, and no key-shaped placeholder, is printed or logged; the only key words are "Never your Claude key." | D2:41 (a); D2:45; ES:156 | SH17, PM5 |
| SA-BAK-9 | Empty. A fresh install with no copy yet | No glance. The full side shows what a copy will hold, with no counts, and the three "never" lines. Tess's band is empty. The front keeps "The first copy is made when you leave the app today." | ES:157 | SL-B2, GL-E3 |
| SA-BAK-10 | After a restore. Restore Thursday's copy, relaunch, wait for tonight's copy | The full side adds "From a restore on Thursday." from `restoredAt`, so a smaller count reads as expected, not a loss | `TesseraBackup.swift:18-19` | |
| SA-BAK-11 | No Claude. "Tess asks Claude" on; open both stops | No call, no Tess Call; receipts unchanged | D2:40 (3) | SH22 |

## 7. Review: THE DAYS (Builder B, 0y)

**What it reads on master.** Review computes only the current week (`Features/Home/ReviewPage.swift:233`) and has no paging. The week data has what each day needs (`Features/Home/ReviewWeek.swift`), and first use is computed at `ReviewPage.swift:225-229`. The older `ReviewView` side (`Features/Review/ReviewView.swift:10`) is not the page sheet 76 changes. Design's rulings (DE:67): a day counts when it has a session, a task done or a cook (notes don't), "N to go" shows only on this week, the fullest day has the most tasks done, and the foot word is ALL DAYS.

| ID | Steps | Expected | Source | Reuses |
|---|---|---|---|---|
| SA-DAYS-1 | Glance. Review (this week, DP1's data), right edge in | THE DAYS, big "5" *of 7 days*, "Wednesday, 6 tasks", "2 to go", ALL DAYS at the foot. Tess: "Wednesday was your fullest day." | DE:44, DE:67 | DP1, DP43 |
| SA-DAYS-2 | A past week. Swipe right in the middle once, then right edge in | Oct 5 to 11: "5" *of 7 days*, "Tuesday, 4 tasks", and no "to go" | DE:67 | DP2, DP47 |
| SA-DAYS-3 | Full side | Seven lines, Monday first, one each: "Wednesday, Pull A and Row, 6 tasks". A day ahead reads "nothing yet". Four or more sessions read "Pull A, Row and 2 more" | DE:44; ES:94 | DP7 full, DP8 full, DP44 |
| SA-DAYS-4 | Pages | No facet row; one page | DE:34 | |
| SA-DAYS-5 | Week run end. On this week, swipe left in the middle. On the first week, swipe right | Both rubber-band; no week after this one, no wrap, no dot row, no haptic. A flick moves one week only | DE:28-29; D2:59 | DP26, DP28, DP29, DP30 |
| SA-DAYS-6 | Side run end. On the full side, swipe left in the middle | Rubber-band; the week run waits until the front | DE:35 ("only the nearest run moves") | DP35 |
| SA-DAYS-7 | Reduce Motion. Repeat SA-DAYS-5 and step one week | Ends: nothing moves or fades. A week step is a 150 ms crossfade | DE:53, DE:69 | DP39 |
| SA-DAYS-8 | Zones. Pan left from x 385 and from x 360; pan right from x 12, x 23 and x 25 | x 385 opens the glance; x 360 goes along. x 12 and x 23 go out; x 25 goes along | DE:14-16 | DP58 to DP63 |
| SA-DAYS-9 | Private. DP7's week: Wednesday holds "Call Dr. Lin about results" (done) and a private note | Counts only: "Wednesday, 6 tasks". No task title, no note word, on either stop. The private note doesn't count as a day's thing | D2:41 (a); DE:67 | DP7, DP7 full |
| SA-DAYS-10 | Empty. Aug 31 to Sep 6 (he was away), and this week with nothing yet through today | No glance in either case: the full side opens straight away with seven lines. Tess's band is empty | ES:157 | DP5, DP4 note |
| SA-DAYS-11 | VoiceOver. Review body, swipe up and down; rotor Actions | "Week of Oct 12 to 18" with the end sound at this week; the custom action "Show the days" opens the side, and "Show the week" returns | DE:52 | DP40, DP57 |
| SA-DAYS-12 | Stale lines. Search the side's strings for "month" | THE MONTH is gone: no "in October" line (SL-M1 and GL-15 are superseded by THE DAYS) | D2:59 | Q18 |

---

## Open questions (Research's pick in each)

- **Q1. Foot words.** Design names ALL FACTS, ALL LINKS, ALL OF IT (a side with pages) and ALL DAYS. *Pick:* THE SETS ALL SETS; PER 100 G and WHAT'S IN ONE ALL FACTS; WHERE IT'S MENTIONED ALL LINKS; ITS STORY ALL OF IT; the exercise ALL OF IT; THE DAYS ALL DAYS. Design to confirm ALL SETS and ITS STORY's word.
- **Q2. THE SETS' top set.** Nothing on master picks one across a workout. *Pick:* the eligible set with the highest e1RM in the workout (the Set class's own formula); with no eligible set, the heaviest by weight then reps; on a tie, the earlier exercise. The exercise is named in full ("Bench Press 82.5 × 7", 4 / 20, under the context cap); Design's "Bench" was the mock's short form.
- **Q3. A planned workout's glance.** Row 9 says "finished or planned", but a planned workout has 0 logged sets. *Pick:* its planned parts: "15" *sets planned*, the first entry's target, "5 exercises". The alternative is no glance (straight to the full side).
- **Q4. Plan my day's keep looks like a hand move.** On master both are `moveTask` by `.user` (`HomePlan.swift:149`, `:177`). *Pick:* Core gives the keep its own action name (for example `keepPlannedTask`, wrapping `MoveTask`) in 0am, and the story counts it as "planned", not as a move. Until then, SA-STORY-4 fails by design.
- **Q5. Whose moves count.** SH26 (cadence) counts `.user` only. For a task, a move asked through Tess or Siri is still his ask. *Pick:* `.user`, `.tess` and `.intent` count; `.system` never does.
- **Q6. A private task's side.** SL-T4 gives "Moved twice, and today's the day." for "Reset bank pin", but 2:45 now hides the task's dates on the front, and "today" tells one. *Pick:* count only ("2" *moves*), no small facts and an empty band. SL-T4 is superseded.
- **Q7. REP MAXES for 1 rep.** Design lists "1 rep 102 kg" but also says estimates round to 2.5 kg, which would give 102.5. *Pick:* the 1-rep row is the e1RM figure itself, shown as on the glance (102 kg, estimated), so the side shows one number for "for 1"; every other estimate rounds to 2.5 kg (9 and 10 reps both read 77.5 kg, which is correct).
- **Q8. Gram rounding.** KS 2.1 says the side shows "4.12 g fat", and `food-table-usda.md` §4 says the side may show kcal whole and grams to one decimal. *Pick:* kcal whole, grams to one decimal ("4.1 g fat"), and tests compare against the stored value. The Kitchen lead to confirm, since this changes 2.1's wording.
- **Q9. KS 2.3 against 2:40.** The Kitchen acceptance has Claude fill a missing row; 2:40 (3) and (4) hold every side's Claude use until the BD4 eval and Kaushik's yes. *Pick:* the PER 100 G pull request ships with no fill at all (SA-PER-11). KS 2.3 is a later row.
- **Q10. A private recipe in "where it's used".** Recipes have no private flag and no private label in 2:45. *Pick:* a recipe whose title fails `SecretWords.mentions` or `PrivateFacts.isPrivateTitle` reads "Private recipe", the 2:45 pattern, counted and never named.
- **Q11. Where Backups' counts come from.** `Info` has none. *Pick:* a Core helper reads the newest copy read-only (as `userOps(at:)` does, `TesseraBackup.swift:186-192`), so the side tells what a copy holds, not the live store, and "N kept" counts the files. The front's fixed "Seven are kept." (`BackupView.swift:353`) is a separate front fix for Builder B.
- **Q12. Backups' big fact on an older copy.** "4 am" alone would be wrong on Saturday for Thursday's copy. *Pick:* the time when the copy is from today; else "yesterday" or the weekday, as the front words it.
- **Q13. Owners.** 0y boards the note, task and Backups sides; 2:59 boards Review (B) and the exercise (A). THE SETS and PER 100 G aren't boarded by name. *Pick:* THE SETS goes to Builder A (Training lane, ES:85) and PER 100 G to Builder B (Kitchen lane), with Core building the food table bundle from the FDC CSV first (KS 2, food-table-usda.md §4). Product to board both.
- **Q14. Runs on these screens.** Sheet 76 names runs for days, weeks, a routine's exercises, Plans and a side's pages. *Pick:* a workout, an ingredient, a note, a task and Backups have no run, so the middle goes in on their fronts. A recipe's ingredients are not a run for now.
- **Q15. ITS STORY's order.** *Pick:* oldest first, as a story reads. The glance's big fact already gives the count.
- **Q16. Empty full-side lines.** *Pick:* "Not in a recipe yet." (PER 100 G) and "Nothing mentions it yet." (WHERE IT'S MENTIONED). Design and copy-pass to word them.
- **Q17. Order of WHERE IT'S MENTIONED.** *Pick:* newest edit first, as `NoteList.notes(about:)` sorts (`Notes/Notes.swift:22-27`).
- **Q18. THE MONTH lines.** SL-M1, SL-M2 and GL-15 describe THE MONTH, which 2:59 dropped. *Pick:* THE DAYS' line is "Wednesday was your fullest day." (DP1), and SL-M1 and SL-M2 are superseded with GL-15.

## Master findings (cde6d54)

- No SideHost, side declaration or zones anywhere on master or the remote branches.
- **A workout has no top set across exercises.** `WorkoutSummary` counts sets and bests only (`Training/WorkoutSummary.swift:42-76`). A set with no weight isn't counted (`TrainingLedger.swift:268`), so a pull-up logged with reps only drops out of "20 sets".
- **The generic workout front prints the workout's notes** (`ObjectPage.swift:232-234`), so "left knee sore, see Dr. Lin" shows on the front today. THE SETS must not repeat it; the front itself is outside the 2:45 mask, which covers private objects only.
- **No food table exists**, and the Ingredient class has only `aisle` and `isStaple` (`SystemCatalog.swift:280-284`). A recipe line with no ingredient link opens the Recipe Line page, not the ingredient (`RecipePage.swift:255`), so it gets the default side and never PER 100 G.
- **The exercise page** shows only 5 sessions (`ExerciseDigest.swift:70`), flags only e1RM bests (`:84`), prints a dash for an empty rep max (`ExerciseViews.swift:188`), has no SETUP view, and its window takes every horizontal pan (`:39-49`).
- **Plan my day's keep is a `.user` `moveTask`** (`HomePlan.swift:149`, `:177`), the same as a hand move (Q4).
- **Backups' `Info` has no counts** (`TesseraBackup.swift:14-27`), and the front always says "Seven are kept." (`BackupView.swift:353`).
- PL4 stays closed (`Notes/Notes.swift:41-46`). Review still computes only the current week (`ReviewPage.swift:233`).
