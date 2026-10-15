# Paste hardening: acceptance (Core)

*Kitchen lead, 2026-10-15. One row per gap in Research's `docs/research/fixtures/recipe-paste-corpus.md` (gaps 1-15), plus Core's board done-line. Pass means every corpus case the gap names parses as its `expect:` block in `RecipeParserTests` / `IngredientLineTests`. Controls 7, 8, 16, 22 and 28 must stay passing. No UI changes are expected; if the paste screen changes, it needs a recording.*

| Gap | What | Cases | Pass when |
|---|---|---|---|
| 1 | oz, lb, pint, c, fl oz, alternates in brackets | 2, 9, 10, 12 | Units parse; "(this is about 200ml/7fl oz)" is kept out of the name |
| 2 | Pack sizes | 3, 11, 27 | "1 (14 oz) can tomatoes" gives amount 1, `packSize` "14 oz", unit can, name tomatoes |
| 3 | Blog noise | 1, 5, 18, 29 | "Jump to Recipe", "Print", Course/Cuisine lines and ▢ are ignored |
| 4 | Unknown headings and section labels | 5, 13, 15, 19, 21, 23, 25, 29 | "Do it like this", "Tadka:", "*Dough*", "Notes", "Step 1" read as headings or sections. **paste-25: every step is a step**. Ingredient `section` kept |
| 5 | Worded and fractional durations | 11, 24, 25 | "1½ hours" = 90, "2½-3 hours" = 150 (lower bound), "1 1/2 hours" = 90, "half an hour" = 30, "a minute" = 1, "twenty minutes" = 20 |
| 6 | Recipe card times | 1, 2, 18, 24, 29, 30 | Split label lines, "Prep \| Cook \| Total", no-colon forms, "Ready in 25 minutes" all read; cook time feeds total when total is missing |
| 7 | Short mentions, salt & pepper | 14 + most | "salt & pepper" never links peppers; "dal" links toor dal, "oil" links olive oil when unambiguous |
| 8 | Leading prep words | 2, 9, 10, 12, 15, 21, 22, 30 | chopped, melted, softened, cold, packed, whole, thick, very ripe, full-fat move to prep |
| 9 | Name-first and article-free | 4, 5, 19 | "Atta - 2 cups", "sugar 1 tsp", "pinch of hing", "1 onion chopped" parse |
| 10 | Indian "to taste" | 4, 15, 19, 20 | "as per taste", "swaad anusar" read as to taste; "or to taste" leaves no stray "or" |
| 11 | Juice of, compound lines | 2, 11, 14, 21, 24, 27, 29 | "Juice of 1 lemon" gives lemon with prep juice; "1 onion, 1 carrot and 1 celery stick" gives 3 lines |
| 12 | List markers, full stops, ⁄ | 9, 27 | "1. 1 can" amount is 1 can; trailing full stops dropped; U+2044 converts |
| 13 | Serves and yield variants | 9, 10, 19, 20, 30 | "Makes about 12", "yield: 24 cookies", "(makes 6)" read (a `makes` field is fine) |
| 14 | Short steps, one-line paste | 4, 26 | "cover 2 mins on low" is a step; a one-line paste gives a recipe (or a clear Tess line), never a throw that shows nothing |
| 15 | Not a timer | 5, 15, 16 | "2 minutes less than the packet says" and "3 whistles" start no timer |
| New | WPRM and Archana's Kitchen | link brief §2c | "10 minutes mins" = 10; "Prep: 10 M" = 10 on a time line only |

**Blocking for merge:** gaps 1, 2, 3, 4 and 5 (they break basic pastes and grocery merging). The rest can ride a follow-up if they're not done, listed in the PR.

**Regression:** `kitchen-phrases.md` rows still pass, and the seed recipes in `kitchen-seed-recipes.md` parse unchanged.
