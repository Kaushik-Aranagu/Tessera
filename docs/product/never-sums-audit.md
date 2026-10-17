# The never-sums audit: nothing in Kitchen ever totals nutrition

*Kitchen lead, 2026-10-17 (decisions 2:36 PM Oct 16). A food's facts are public facts about the food. The moment the app adds them up (per recipe, per day, per week, per shop) it becomes intake, which is a body fact and walled (`private-health-words.md` BW88). So no screen, line, widget, receipt or Claude call in Kitchen ever sums, averages, ranks or compares nutrition. The only nutrition on the phone is one ingredient's own PER 100 G row on its side.*

## One rule

Nutrition numbers (kcal, protein, carbohydrate, fat, fibre) exist in exactly one place, the PER 100 G side of one Ingredient (`kitchen-sides-acceptance.md` §2). Nothing reads them anywhere else. A screen that could total them shows no nutrition at all.

## A row per screen that could total nutrition

| # | Screen | Pass when |
|---|---|---|
| N1 | Groceries (list and its side) | No kcal, protein or any nutrition word on the page, the count line, a row, the receipt or Tess's line. The FOR WHAT side groups by recipe and never shows nutrition |
| N2 | Recipe page and ingredient peek | The peek reads need against have in words and counts to buy only. No per-serving, per-recipe or "per portion" nutrition line. Changing servings changes amounts, never a nutrition figure |
| N3 | Cook mode and the recipe clock | Steps, timers and the ingredient strip show no nutrition. FinishCooking records the cook (a duration, a date) and never an intake |
| N4 | Kitchen week and its side (THE WEEK'S COOKS) | Lists the cooks and the next cook in Home's words. No weekly or daily total, no "balance", no ranking of days |
| N5 | The PER 100 G side | Shows one ingredient only, rounded for display per row 2.1c. No second ingredient, no "used in N recipes" nutrition, no total of anything. A recipe that holds the ingredient is a name, never a sum |
| N6 | Pantry | States (in, low, out, unknown) and dates only. No nutrition on a line, the counts line or the side |
| N7 | Home, widgets, Live Activity, Spotlight, App Intents | No Kitchen surface carries a nutrition number. A Home line about a cook names the cook and the clock, nothing about food values |
| N8 | Tess (Ask Tess, receipts, spoken lines) | Asked "how many calories is this recipe / today / this week", Tess says plainly she doesn't add food up and offers the one ingredient's side. She never computes an answer, in text or spoken |
| N9 | Claude | No prompt, pack snapshot or fill call carries a nutrition number or a total. The fill call (sheet 75 §3) asks for one named food's row and carries the ingredient key only, as `kitchen-sides-acceptance.md` §2 limits it |
| N10 | Exports and backups | Backups and any export hold the bundled rows only as the table, never a derived figure for a recipe, a day or a shop |

## How it's proved (Core, Builder B)

1. **Code:** one reader of the food table exists, behind the Ingredient side. A test fails the build if any other module imports it (a grep-style test over the app target), so a total can't be added by accident.
2. **Fixture:** the tacos recipe with six ingredients that all have rows; every screen in N1 to N7 is read through its accessibility tree and no nutrition word or number from the six rows appears anywhere but on the chicken's own side.
3. **Tess:** the three questions in N8 each get the plain refusal; none returns a number.
4. **Pack snapshot:** the AI-12 snapshot and the fill call are dumped in a test; neither contains a nutrition field.

## If someone asks for a total

It is a new decision for Kaushik, not a Kitchen default. Product records it; the walls (BW88) and this page change in the same PR.
