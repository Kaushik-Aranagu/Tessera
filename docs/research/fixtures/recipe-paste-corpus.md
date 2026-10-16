# Recipe paste corpus (kitchen slices 2, 3 and 11)

Research lab, 2026-10-15. 30 pasted recipe texts with the parse we want from them, for `IngredientLineTests`, `RecipeParserTests` and the Paste a recipe screen. All texts are written for this file in the styles people actually paste (blog recipe cards, Notes, WhatsApp forwards, Instagram captions, Indian home cooking). None repeat `kitchen-seed-recipes.md`, the carbonara and quick dal in `RecipeTests.swift`, or the phrases in `kitchen-phrases.md`.

Checked against `TesseraCore/Sources/TesseraCore/Kitchen/` on `origin/master` at fcad46c (`RecipeParser.swift`, `Quantities.swift`, `Recipes.swift`). That checkout predates hotfix #80 (dd8f3ca), so "2 garlic cloves" as unit-after-name is assumed fixed, as `kitchen-acceptance.md` reports.

Added 2026-10-16 for Design's `docs/design/kitchen/us-shop.md` (7ac3df3): cases paste-31 to paste-35 (46 ingredient lines in US units: oz, lb, pint, fl oz, sticks, cans with pack sizes, fractions), checked by reading `origin/master` at 620878b. Each ingredient line carries a comment saying whether it passes or FAILS today. The "US merge check" section at the end checks Design's merge rows.

## Fixture format

One YAML block per case.

```yaml
id: paste-01                 # stable id for tests
shape: blog-story-card       # what kind of paste this is
raw: |                       # exactly what is pasted; `source` must equal it
  ...
expect:
  title: "..."               # ParsedRecipe.title ("Untitled recipe" when there is none)
  serves: 4                  # ParsedRecipe.serves (Int, lower bound of a range)
  activeMinutes: 15          # optional, only when the text states it
  totalMinutes: 45           # optional, only when the text states it
  ingredients:               # ParsedRecipe.ingredients, in order
    - {amount: 1, amountMax: null, unit: cup, name: toor dal, prep: washed, raw: "1 cup toor dal, washed"}
  steps:                     # ParsedRecipe.steps, in order
    - text: "..."            # numbering stripped
      durations: [[10, 12]]  # Step.timers in minutes, [low, high]
      mentions: [garlic]     # ingredient names the step names in full (works today)
      alsoMentions: [olive oil]  # ingredients named by a short form ("oil", "dal"); needs a new rule
notes: ...                   # why the case exists and what to watch
```

Conventions:
- `raw` in an ingredient is `IngredientLine.original`. Omitted fields are null; `toTaste` is false unless written.
- `unit` uses `KitchenUnit` raw values: g, kg, ml, l, tsp, tbsp, cup, clove, pinch, handful, bunch, can, slice, sprig, piece, stick, head. Units marked `# new` (oz, lb, pint, inch, knob, glug) are not in the enum today and are proposed.
- `section` (for "For the sauce:") and `packSize` (for "1 (14 oz) can") are proposed fields; `ParsedRecipe` has neither today.
- When one raw line holds several ingredients ("1 onion, 1 carrot"), the expectation lists one line per ingredient, all with the same `raw`.
- When metric and imperial are both written, the first is the amount and the other is ignored (it stays in `raw`).
- Stories, metadata, nutrition, tips and hashtags are neither ingredients nor steps. They are expected to be dropped (the text is kept in `source`).
- Fractions are written to three decimals (⅓ = 0.333).
- `alsoMentions` rule proposed for Core: a step mentions an ingredient by its last word or a clear short form ("oil" for olive oil, "dal" for toor dal) when no other ingredient in the recipe shares that word.

## Cases

### paste-01 Brown butter banana bread (blog story and recipe card)

```yaml
id: paste-01
shape: blog-story-card
raw: |
  Jump to Recipe
  The Best Brown Butter Banana Bread
  Every autumn my kitchen smells like this loaf. I started making it the year we moved into the flat with the tiny oven, and it has survived three moves, one toddler and a very honest mother-in-law.
  The trick is browning the butter. It takes five extra minutes and makes the whole loaf taste of toffee.
  Prep Time
  15 mins
  Cook Time
  1 hr
  Total Time
  1 hr 15 mins
  Servings
  10 slices
  Ingredients
  ▢ ½ cup unsalted butter
  ▢ 3 very ripe bananas, mashed (about 1 ½ cups)
  ▢ ⅔ cup light brown sugar
  ▢ 1 large egg
  ▢ 1 tsp vanilla extract
  ▢ 1 tsp baking soda
  ▢ ¼ tsp salt
  ▢ 1 ½ cups all-purpose flour
  Instructions
  Preheat the oven to 350°F (175°C) and grease a 9x5 loaf pan.
  Melt the butter over medium heat and cook, swirling, for 4-5 minutes until nutty and brown. Cool for 10 minutes.
  Mix the bananas, sugar, egg and vanilla into the butter.
  Stir in the baking soda, salt and flour until just combined.
  Bake for 55-65 minutes, until a skewer comes out clean. Cool in the pan for 15 minutes.
expect:
  title: "The Best Brown Butter Banana Bread"
  serves: 10
  activeMinutes: 15
  totalMinutes: 75
  ingredients:
    - {amount: 0.5, unit: cup, name: unsalted butter, raw: "▢ ½ cup unsalted butter"}
    - {amount: 3, name: bananas, prep: "very ripe, mashed", raw: "▢ 3 very ripe bananas, mashed (about 1 ½ cups)"}
    - {amount: 0.667, unit: cup, name: light brown sugar, raw: "▢ ⅔ cup light brown sugar"}
    - {amount: 1, name: egg, prep: large, raw: "▢ 1 large egg"}
    - {amount: 1, unit: tsp, name: vanilla extract, raw: "▢ 1 tsp vanilla extract"}
    - {amount: 1, unit: tsp, name: baking soda, raw: "▢ 1 tsp baking soda"}
    - {amount: 0.25, unit: tsp, name: salt, raw: "▢ ¼ tsp salt"}
    - {amount: 1.5, unit: cup, name: all-purpose flour, raw: "▢ 1 ½ cups all-purpose flour"}
  steps:
    - {text: "Preheat the oven to 350°F (175°C) and grease a 9x5 loaf pan.", durations: [], mentions: []}
    - {text: "Melt the butter over medium heat and cook, swirling, for 4-5 minutes until nutty and brown. Cool for 10 minutes.", durations: [[4, 5], [10, 10]], mentions: [], alsoMentions: [unsalted butter]}
    - {text: "Mix the bananas, sugar, egg and vanilla into the butter.", durations: [], mentions: [bananas, egg], alsoMentions: [light brown sugar, vanilla extract, unsalted butter]}
    - {text: "Stir in the baking soda, salt and flour until just combined.", durations: [], mentions: [baking soda, salt], alsoMentions: [all-purpose flour]}
    - {text: "Bake for 55-65 minutes, until a skewer comes out clean. Cool in the pan for 15 minutes.", durations: [[55, 65], [15, 15]], mentions: []}
notes: >
  The WordPress recipe-card shape. Today "Jump to Recipe" becomes the title, the story becomes steps, the
  split "Prep Time" / "15 mins" labels become ingredients, and the ▢ checkbox glyph is not stripped, so every
  ingredient has no amount. "very ripe" is not a size word.
```

### paste-02 Lemon garlic chicken thighs (blog, sections, Notes)

```yaml
id: paste-02
shape: blog-sections
raw: |
  Crispy Lemon Garlic Chicken Thighs
  Prep: 10 mins | Cook: 35 mins | Total: 45 mins
  Servings: 4 servings
  Ingredients
  For the chicken:
  8 bone-in, skin-on chicken thighs (about 2 lb / 900 g)
  1 tsp kosher salt
  ½ tsp black pepper
  1 tbsp olive oil
  For the pan sauce:
  4 cloves garlic, minced
  ½ cup chicken broth
  Juice of 1 lemon
  2 tbsp cold butter, cubed
  1 tbsp chopped parsley
  Instructions
  Pat the chicken dry and season with the salt and pepper.
  Heat the oil in a large oven-safe skillet. Lay the thighs skin-side down and cook without moving for 12-15 minutes until the skin is deep golden.
  Flip, then roast at 425°F for 15-20 minutes until the juices run clear. Move the chicken to a plate.
  Pour off most of the fat, add the garlic and cook for 30 seconds.
  Add the broth and lemon juice and simmer 3-4 min, then whisk in the butter off the heat.
  Spoon the sauce over the chicken and scatter with parsley.
  Notes
  Boneless thighs work too; cut the roasting time to 8-10 minutes.
  Leftovers keep for 3 days in the fridge.
expect:
  title: "Crispy Lemon Garlic Chicken Thighs"
  serves: 4
  activeMinutes: 10
  totalMinutes: 45
  ingredients:
    - {section: chicken, amount: 8, name: chicken thighs, prep: "bone-in, skin-on", raw: "8 bone-in, skin-on chicken thighs (about 2 lb / 900 g)"}
    - {section: chicken, amount: 1, unit: tsp, name: kosher salt, raw: "1 tsp kosher salt"}
    - {section: chicken, amount: 0.5, unit: tsp, name: black pepper, raw: "½ tsp black pepper"}
    - {section: chicken, amount: 1, unit: tbsp, name: olive oil, raw: "1 tbsp olive oil"}
    - {section: pan sauce, amount: 4, unit: clove, name: garlic, prep: minced, raw: "4 cloves garlic, minced"}
    - {section: pan sauce, amount: 0.5, unit: cup, name: chicken broth, raw: "½ cup chicken broth"}
    - {section: pan sauce, amount: 1, name: lemon, prep: juice, raw: "Juice of 1 lemon"}
    - {section: pan sauce, amount: 2, unit: tbsp, name: butter, prep: "cold, cubed", raw: "2 tbsp cold butter, cubed"}
    - {section: pan sauce, amount: 1, unit: tbsp, name: parsley, prep: chopped, raw: "1 tbsp chopped parsley"}
  steps:
    - {text: "Pat the chicken dry and season with the salt and pepper.", durations: [], mentions: [], alsoMentions: [chicken thighs, kosher salt, black pepper]}
    - {text: "Heat the oil in a large oven-safe skillet. Lay the thighs skin-side down and cook without moving for 12-15 minutes until the skin is deep golden.", durations: [[12, 15]], mentions: [], alsoMentions: [olive oil, chicken thighs]}
    - {text: "Flip, then roast at 425°F for 15-20 minutes until the juices run clear. Move the chicken to a plate.", durations: [[15, 20]], mentions: [], alsoMentions: [chicken thighs]}
    - {text: "Pour off most of the fat, add the garlic and cook for 30 seconds.", durations: [[0.5, 0.5]], mentions: [garlic]}
    - {text: "Add the broth and lemon juice and simmer 3-4 min, then whisk in the butter off the heat.", durations: [[3, 4]], mentions: [lemon, butter], alsoMentions: [chicken broth]}
    - {text: "Spoon the sauce over the chicken and scatter with parsley.", durations: [], mentions: [parsley], alsoMentions: [chicken thighs]}
notes: >
  One-line "Prep | Cook | Total" reads only the prep today, so total falls back to the sum of step timers.
  "Notes" is not a heading, so the two tips become steps 7 and 8 (with an 8-10 min timer). "Juice of 1 lemon"
  becomes an ingredient called "Juice of 1 lemon". The comma in "bone-in, skin-on" splits the name.
  Leading "cold" and "chopped" stay in the name.
```

### paste-03 Smoky black bean tacos (recipe card metadata, 1 (15 oz) can)

```yaml
id: paste-03
shape: blog-card-metadata
raw: |
  Smoky Black Bean Tacos
  Course: Main Course
  Cuisine: Mexican
  Keyword: easy tacos, vegetarian
  Prep Time: 10 minutes
  Cook Time: 15 minutes
  Total Time: 25 minutes
  Servings: 4
  Calories: 380kcal
  Author: Priya
  Ingredients
  1 tablespoon olive oil
  1 small red onion, diced
  2 cloves garlic, minced
  1 (15 oz) can black beans, drained and rinsed
  1 teaspoon smoked paprika
  1/2 teaspoon ground cumin
  1/4 cup water
  8 small corn tortillas, warmed
  1 avocado, sliced
  1/2 cup crumbled feta
  Lime wedges, for serving
  Instructions
  Heat the oil in a skillet over medium heat. Add the onion and cook 5 to 6 minutes until soft.
  Add the garlic, paprika and cumin and cook for 1 minute.
  Stir in the black beans and water and simmer 8-10 min, lightly mashing some of the beans.
  Fill the tortillas with the beans, avocado and feta and serve with lime wedges.
  Nutrition
  Calories: 380kcal | Carbohydrates: 52g | Protein: 14g | Fat: 14g
expect:
  title: "Smoky Black Bean Tacos"
  serves: 4
  activeMinutes: 10
  totalMinutes: 25
  ingredients:
    - {amount: 1, unit: tbsp, name: olive oil, raw: "1 tablespoon olive oil"}
    - {amount: 1, name: red onion, prep: "small, diced", raw: "1 small red onion, diced"}
    - {amount: 2, unit: clove, name: garlic, prep: minced, raw: "2 cloves garlic, minced"}
    - {amount: 1, unit: can, packSize: "15 oz", name: black beans, prep: drained and rinsed, raw: "1 (15 oz) can black beans, drained and rinsed"}
    - {amount: 1, unit: tsp, name: smoked paprika, raw: "1 teaspoon smoked paprika"}
    - {amount: 0.5, unit: tsp, name: ground cumin, raw: "1/2 teaspoon ground cumin"}
    - {amount: 0.25, unit: cup, name: water, raw: "1/4 cup water"}
    - {amount: 8, name: corn tortillas, prep: "small, warmed", raw: "8 small corn tortillas, warmed"}
    - {amount: 1, name: avocado, prep: sliced, raw: "1 avocado, sliced"}
    - {amount: 0.5, unit: cup, name: feta, prep: crumbled, raw: "1/2 cup crumbled feta"}
    - {name: lime wedges, prep: for serving, raw: "Lime wedges, for serving"}
  steps:
    - {text: "Heat the oil in a skillet over medium heat. Add the onion and cook 5 to 6 minutes until soft.", durations: [[5, 6]], mentions: [], alsoMentions: [olive oil, red onion]}
    - {text: "Add the garlic, paprika and cumin and cook for 1 minute.", durations: [[1, 1]], mentions: [garlic], alsoMentions: [smoked paprika, ground cumin]}
    - {text: "Stir in the black beans and water and simmer 8-10 min, lightly mashing some of the beans.", durations: [[8, 10]], mentions: [black beans, water]}
    - {text: "Fill the tortillas with the beans, avocado and feta and serve with lime wedges.", durations: [], mentions: [avocado, feta, lime wedges], alsoMentions: [corn tortillas]}
notes: >
  Course, Cuisine, Keyword, Calories and Author lines become ingredients today (short, no full stop), and the
  Nutrition block becomes two steps. "1 (15 oz) can black beans" reads as no unit and the name "can black beans".
```

### paste-04 Amma's poha (Notes, lowercase, name-first amounts)

```yaml
id: paste-04
shape: notes-terse-indian
raw: |
  Poha (amma's way)

  poha 2 cups - thick one
  1 onion chopped
  1 green chilli
  handful peanuts
  1/2 tsp rai
  pinch of hing
  1/4 tsp haldi
  8-10 curry leaves
  salt as per taste
  sugar 1 tsp
  lemon
  coriander for top

  wash poha in a strainer, just 2-3 times, keep aside 5 min
  oil, peanuts fry till crunchy, take out
  rai, hing, curry leaves, chilli, then onion till soft
  haldi + salt + sugar, then poha, mix gently
  cover 2 mins on low
  peanuts, lemon, coriander on top
expect:
  title: "Poha (amma's way)"
  serves: null
  ingredients:
    - {amount: 2, unit: cup, name: poha, prep: thick one, raw: "poha 2 cups - thick one"}
    - {amount: 1, name: onion, prep: chopped, raw: "1 onion chopped"}
    - {amount: 1, name: green chilli, raw: "1 green chilli"}
    - {amount: 1, unit: handful, name: peanuts, raw: "handful peanuts"}
    - {amount: 0.5, unit: tsp, name: rai, raw: "1/2 tsp rai"}
    - {amount: 1, unit: pinch, name: hing, raw: "pinch of hing"}
    - {amount: 0.25, unit: tsp, name: haldi, raw: "1/4 tsp haldi"}
    - {amount: 8, amountMax: 10, name: curry leaves, raw: "8-10 curry leaves"}
    - {name: salt, toTaste: true, raw: "salt as per taste"}
    - {amount: 1, unit: tsp, name: sugar, raw: "sugar 1 tsp"}
    - {name: lemon, raw: "lemon"}
    - {name: coriander, prep: for top, raw: "coriander for top"}
  steps:
    - {text: "wash poha in a strainer, just 2-3 times, keep aside 5 min", durations: [[5, 5]], mentions: [poha]}
    - {text: "oil, peanuts fry till crunchy, take out", durations: [], mentions: [peanuts]}
    - {text: "rai, hing, curry leaves, chilli, then onion till soft", durations: [], mentions: [rai, hing, curry leaves, onion], alsoMentions: [green chilli]}
    - {text: "haldi + salt + sugar, then poha, mix gently", durations: [], mentions: [haldi, salt, sugar, poha]}
    - {text: "cover 2 mins on low", durations: [[2, 2]], mentions: []}
    - {text: "peanuts, lemon, coriander on top", durations: [], mentions: [peanuts, lemon, coriander]}
notes: >
  How family recipes live in Notes. No headings, so line shape decides: today "oil, peanuts fry till crunchy, take out",
  "cover 2 mins on low" and "peanuts, lemon, coriander on top" read as ingredients (short, no full stop). The blank
  line between the blocks is the strongest signal and is thrown away. "2-3 times" must not become a timer.
  Name-first amounts, "handful peanuts" and "pinch of hing" without an article, "as per taste", and prep with no comma
  all fail today.
```

### paste-05 Friday pasta bake (Notes bullets, 2 × 400g tins)

```yaml
id: paste-05
shape: notes-bullets
raw: |
  Friday pasta bake
  Serves 4-6

  • 500g rigatoni
  • 1 tbsp olive oil
  • 400g Italian sausages, skins off
  • 1 red chilli, finely chopped
  • 2 × 400g tins chopped tomatoes
  • 150g mozzarella, torn
  • 40g parmesan, grated
  • Small bunch basil

  How to:
  1) Boil the rigatoni for 2 minutes less than the packet says. Drain.
  2) Fry the sausage meat in the oil for 8-10 mins, breaking it up.
  3) Add the chilli and tomatoes, simmer 15 min.
  4) Mix in the pasta, top with mozzarella and parmesan.
  5) Bake at 200C/180C fan for 20 mins until bubbling. Scatter over the basil.
expect:
  title: "Friday pasta bake"
  serves: 4
  ingredients:
    - {amount: 500, unit: g, name: rigatoni, raw: "• 500g rigatoni"}
    - {amount: 1, unit: tbsp, name: olive oil, raw: "• 1 tbsp olive oil"}
    - {amount: 400, unit: g, name: Italian sausages, prep: skins off, raw: "• 400g Italian sausages, skins off"}
    - {amount: 1, name: red chilli, prep: finely chopped, raw: "• 1 red chilli, finely chopped"}
    - {amount: 2, unit: can, packSize: "400 g", name: chopped tomatoes, raw: "• 2 × 400g tins chopped tomatoes"}
    - {amount: 150, unit: g, name: mozzarella, prep: torn, raw: "• 150g mozzarella, torn"}
    - {amount: 40, unit: g, name: parmesan, prep: grated, raw: "• 40g parmesan, grated"}
    - {amount: 1, unit: bunch, name: basil, prep: small, raw: "• Small bunch basil"}
  steps:
    - {text: "Boil the rigatoni for 2 minutes less than the packet says. Drain.", durations: [], mentions: [rigatoni]}
    - {text: "Fry the sausage meat in the oil for 8-10 mins, breaking it up.", durations: [[8, 10]], mentions: [], alsoMentions: [Italian sausages, olive oil]}
    - {text: "Add the chilli and tomatoes, simmer 15 min.", durations: [[15, 15]], mentions: [], alsoMentions: [red chilli, chopped tomatoes]}
    - {text: "Mix in the pasta, top with mozzarella and parmesan.", durations: [], mentions: [mozzarella, parmesan]}
    - {text: "Bake at 200C/180C fan for 20 mins until bubbling. Scatter over the basil.", durations: [[20, 20]], mentions: [basil]}
notes: >
  "2 minutes less than the packet says" is relative, not a timer; expected none (today it gives 2 min, a known
  limit, not a blocker). "How to:" is not a heading and becomes an ingredient today; the numbered steps still read
  right because "1) " marks them. "2 × 400g tins" and "Small bunch basil" (no article, unit after a size word) fail.
```

### paste-06 Tzatziki (no headings, "a few sprigs")

```yaml
id: paste-06
shape: no-headings
raw: |
  Tzatziki
  1 cucumber
  300 g Greek yoghurt
  1 small garlic clove, grated
  1 tbsp olive oil
  1 tbsp lemon juice
  A few sprigs of dill, chopped
  Pinch of salt
  Grate the cucumber, squeeze out as much water as you can and tip it into a bowl.
  Stir in the yoghurt, garlic, oil, lemon juice and dill, then season with the salt.
  Chill for at least 30 minutes so the garlic mellows.
expect:
  title: "Tzatziki"
  serves: null
  ingredients:
    - {amount: 1, name: cucumber, raw: "1 cucumber"}
    - {amount: 300, unit: g, name: Greek yoghurt, raw: "300 g Greek yoghurt"}
    - {amount: 1, unit: clove, name: garlic, prep: "small, grated", raw: "1 small garlic clove, grated"}
    - {amount: 1, unit: tbsp, name: olive oil, raw: "1 tbsp olive oil"}
    - {amount: 1, unit: tbsp, name: lemon juice, raw: "1 tbsp lemon juice"}
    - {unit: sprig, name: dill, prep: chopped, raw: "A few sprigs of dill, chopped"}
    - {amount: 1, unit: pinch, name: salt, raw: "Pinch of salt"}
  steps:
    - {text: "Grate the cucumber, squeeze out as much water as you can and tip it into a bowl.", durations: [], mentions: [cucumber]}
    - {text: "Stir in the yoghurt, garlic, oil, lemon juice and dill, then season with the salt.", durations: [], mentions: [garlic, lemon juice, dill, salt], alsoMentions: [Greek yoghurt, olive oil]}
    - {text: "Chill for at least 30 minutes so the garlic mellows.", durations: [[30, 30]], mentions: [garlic]}
notes: >
  "A few sprigs of dill, chopped" has 6 words and no leading amount, so it reads as a step today; parsed as an
  ingredient it becomes amount 1, name "few sprigs of dill". "a few" has no number: amount stays null.
```

### paste-07 Pan steak for two (method as one paragraph)

```yaml
id: paste-07
shape: no-headings-paragraph
raw: |
  Pan steak for two
  2 ribeye steaks, about 2.5 cm thick
  1 tbsp vegetable oil
  30 g butter
  2 sprigs thyme
  2 garlic cloves, bashed
  flaky salt and black pepper
  Take the steaks out of the fridge 30 minutes before cooking and season well. Get a heavy pan smoking hot, add the oil and sear the steaks for 2 minutes a side for medium rare. Add the butter, thyme and garlic and baste for 1 minute more. Rest for 5 minutes, then slice against the grain.
expect:
  title: "Pan steak for two"
  serves: null
  ingredients:
    - {amount: 2, name: ribeye steaks, prep: "about 2.5 cm thick", raw: "2 ribeye steaks, about 2.5 cm thick"}
    - {amount: 1, unit: tbsp, name: vegetable oil, raw: "1 tbsp vegetable oil"}
    - {amount: 30, unit: g, name: butter, raw: "30 g butter"}
    - {amount: 2, unit: sprig, name: thyme, raw: "2 sprigs thyme"}
    - {amount: 2, unit: clove, name: garlic, prep: bashed, raw: "2 garlic cloves, bashed"}
    - {name: flaky salt and black pepper, raw: "flaky salt and black pepper"}
  steps:
    - text: "Take the steaks out of the fridge 30 minutes before cooking and season well. Get a heavy pan smoking hot, add the oil and sear the steaks for 2 minutes a side for medium rare. Add the butter, thyme and garlic and baste for 1 minute more. Rest for 5 minutes, then slice against the grain."
      durations: [[30, 30], [2, 2], [1, 1], [5, 5]]
      mentions: [butter, thyme, garlic]
      alsoMentions: [ribeye steaks, vegetable oil]
notes: >
  Control case: should pass today (after #80). Steps are paragraphs, so this is one step with four timers. Cook
  mode may later want to split long paragraphs by sentence; that is a screen decision, not a parse one.
  "Serves" is implied by the title only, so serves stays null.
```

### paste-08 Guacamole (all prose, no ingredient lines)

```yaml
id: paste-08
shape: prose-only
raw: |
  Guacamole
  Mash 2 ripe avocados with a fork, leaving it a bit chunky.
  Stir in half a red onion, very finely chopped, a handful of chopped coriander, 1 deseeded green chilli and the juice of 1 lime.
  Season with salt, taste, and add more lime if it needs it.
expect:
  title: "Guacamole"
  serves: null
  ingredients: []
  steps:
    - {text: "Mash 2 ripe avocados with a fork, leaving it a bit chunky.", durations: [], mentions: []}
    - {text: "Stir in half a red onion, very finely chopped, a handful of chopped coriander, 1 deseeded green chilli and the juice of 1 lime.", durations: [], mentions: []}
    - {text: "Season with salt, taste, and add more lime if it needs it.", durations: [], mentions: []}
notes: >
  Control case: should pass today. Pulling ingredients out of prose is AI parsing, which is deferred. The Paste
  screen should say "No ingredients, three steps." and let tap-to-cycle mark words as ingredients.
```

### paste-09 Buttermilk pancakes (ranges and unicode fractions)

```yaml
id: paste-09
shape: ranges-fractions
raw: |
  Buttermilk Pancakes
  Makes about 12 pancakes
  INGREDIENTS
  1 ½ cups all-purpose flour
  2–3 tbsp sugar
  1 tsp baking powder
  ½ tsp baking soda
  ¼–½ tsp salt
  1⅓ cups buttermilk
  1 egg
  3 tbsp melted butter, plus more for the pan
  1⁄2 tsp vanilla (optional)
  METHOD
  Whisk the flour, sugar, baking powder, baking soda and salt together.
  Whisk the buttermilk, egg, melted butter and vanilla in a jug, then pour into the dry ingredients and stir until just combined. Rest the batter 5-10 minutes.
  Cook ¼ cup of batter at a time for 2–3 minutes, until bubbles form, then flip and cook 1-2 min more.
expect:
  title: "Buttermilk Pancakes"
  serves: null
  ingredients:
    - {amount: 1.5, unit: cup, name: all-purpose flour, raw: "1 ½ cups all-purpose flour"}
    - {amount: 2, amountMax: 3, unit: tbsp, name: sugar, raw: "2–3 tbsp sugar"}
    - {amount: 1, unit: tsp, name: baking powder, raw: "1 tsp baking powder"}
    - {amount: 0.5, unit: tsp, name: baking soda, raw: "½ tsp baking soda"}
    - {amount: 0.25, amountMax: 0.5, unit: tsp, name: salt, raw: "¼–½ tsp salt"}
    - {amount: 1.333, unit: cup, name: buttermilk, raw: "1⅓ cups buttermilk"}
    - {amount: 1, name: egg, raw: "1 egg"}
    - {amount: 3, unit: tbsp, name: butter, prep: "melted, plus more for the pan", raw: "3 tbsp melted butter, plus more for the pan"}
    - {amount: 0.5, unit: tsp, name: vanilla, prep: optional, raw: "1⁄2 tsp vanilla (optional)"}
  steps:
    - {text: "Whisk the flour, sugar, baking powder, baking soda and salt together.", durations: [], mentions: [sugar, baking powder, baking soda, salt], alsoMentions: [all-purpose flour]}
    - {text: "Whisk the buttermilk, egg, melted butter and vanilla in a jug, then pour into the dry ingredients and stir until just combined. Rest the batter 5-10 minutes.", durations: [[5, 10]], mentions: [buttermilk, egg, butter, vanilla]}
    - {text: "Cook ¼ cup of batter at a time for 2–3 minutes, until bubbles form, then flip and cook 1-2 min more.", durations: [[2, 3], [1, 2]], mentions: []}
notes: >
  "1⁄2" uses U+2044 FRACTION SLASH, which recipe sites emit; `clean` does not handle it, so the name becomes "⁄2 tsp
  vanilla". "Makes about 12 pancakes" is a yield, not servings: serves null, and today it becomes an ingredient.
  A `makes` field (12) is worth adding. "(optional)" is dropped with the parenthetical today; keep it as prep.
  Leading "melted" stays in the name today.
```

### paste-10 Chocolate chip cookies (US cups, c., T and t, sticks)

```yaml
id: paste-10
shape: cups-spoons
raw: |
  Brown sugar chocolate chip cookies
  yield: 24 cookies
  2 1/4 c. all-purpose flour
  1 t baking soda
  1 t salt
  1 c. (2 sticks) butter, softened
  3/4 c granulated sugar
  3/4 c packed brown sugar
  2 large eggs
  2 t vanilla
  2 c. chocolate chips
  Heat oven to 375°F.
  Whisk flour, soda and salt in a bowl.
  Beat butter and both sugars until creamy, about 3 minutes, then beat in the eggs and vanilla.
  Stir in the flour mixture, then the chocolate chips.
  Drop rounded T of dough onto ungreased sheets and bake 9-11 min. Cool on the sheet 2 min.
expect:
  title: "Brown sugar chocolate chip cookies"
  serves: null
  ingredients:
    - {amount: 2.25, unit: cup, name: all-purpose flour, raw: "2 1/4 c. all-purpose flour"}
    - {amount: 1, unit: tsp, name: baking soda, raw: "1 t baking soda"}
    - {amount: 1, unit: tsp, name: salt, raw: "1 t salt"}
    - {amount: 1, unit: cup, name: butter, prep: softened, raw: "1 c. (2 sticks) butter, softened"}
    - {amount: 0.75, unit: cup, name: granulated sugar, raw: "3/4 c granulated sugar"}
    - {amount: 0.75, unit: cup, name: brown sugar, prep: packed, raw: "3/4 c packed brown sugar"}
    - {amount: 2, name: eggs, prep: large, raw: "2 large eggs"}
    - {amount: 2, unit: tsp, name: vanilla, raw: "2 t vanilla"}
    - {amount: 2, unit: cup, name: chocolate chips, raw: "2 c. chocolate chips"}
  steps:
    - {text: "Heat oven to 375°F.", durations: [], mentions: []}
    - {text: "Whisk flour, soda and salt in a bowl.", durations: [], mentions: [salt], alsoMentions: [all-purpose flour, baking soda]}
    - {text: "Beat butter and both sugars until creamy, about 3 minutes, then beat in the eggs and vanilla.", durations: [[3, 3]], mentions: [butter, eggs, vanilla]}
    - {text: "Stir in the flour mixture, then the chocolate chips.", durations: [], mentions: [chocolate chips], alsoMentions: [all-purpose flour]}
    - {text: "Drop rounded T of dough onto ungreased sheets and bake 9-11 min. Cool on the sheet 2 min.", durations: [[9, 11], [2, 2]], mentions: []}
notes: >
  "c" and "c." are not cup today, so four lines get no unit and names like "c. all-purpose flour". "yield: 24
  cookies" fails `servesCount` (trailing word) and becomes an ingredient; expected serves null, makes 24.
  "both sugars" is ambiguous between two sugars, so no short-form mention. Leading "packed" should be prep.
```

### paste-11 Sunday ragu (metric and imperial mixed)

```yaml
id: paste-11
shape: metric-imperial
raw: |
  Sunday ragu
  Serves 6
  Ingredients
  2 tbsp olive oil
  1 onion, 1 carrot and 1 celery stick, finely diced
  500 g (1 lb) beef mince
  250 g / 9 oz pork mince
  150 ml (2/3 cup) red wine
  2 x 400 g tins chopped tomatoes
  2 tbsp tomato purée
  1 pint (570 ml) beef stock
  2 bay leaves
  Method
  Soften the onion, carrot and celery in the oil over a low heat for 15 minutes.
  Turn up the heat, add both minces and brown for 8-10 minutes.
  Pour in the wine and bubble for 2 minutes.
  Add the tomatoes, purée, stock and bay leaves. Simmer, lid ajar, for 1½ hours, stirring now and then, until thick.
expect:
  title: "Sunday ragu"
  serves: 6
  ingredients:
    - {amount: 2, unit: tbsp, name: olive oil, raw: "2 tbsp olive oil"}
    - {amount: 1, name: onion, prep: finely diced, raw: "1 onion, 1 carrot and 1 celery stick, finely diced"}
    - {amount: 1, name: carrot, prep: finely diced, raw: "1 onion, 1 carrot and 1 celery stick, finely diced"}
    - {amount: 1, unit: stick, name: celery, prep: finely diced, raw: "1 onion, 1 carrot and 1 celery stick, finely diced"}
    - {amount: 500, unit: g, name: beef mince, raw: "500 g (1 lb) beef mince"}
    - {amount: 250, unit: g, name: pork mince, raw: "250 g / 9 oz pork mince"}
    - {amount: 150, unit: ml, name: red wine, raw: "150 ml (2/3 cup) red wine"}
    - {amount: 2, unit: can, packSize: "400 g", name: chopped tomatoes, raw: "2 x 400 g tins chopped tomatoes"}
    - {amount: 2, unit: tbsp, name: tomato purée, raw: "2 tbsp tomato purée"}
    - {amount: 1, unit: pint, name: beef stock, raw: "1 pint (570 ml) beef stock"}   # new unit
    - {amount: 2, name: bay leaves, raw: "2 bay leaves"}
  steps:
    - {text: "Soften the onion, carrot and celery in the oil over a low heat for 15 minutes.", durations: [[15, 15]], mentions: [onion, carrot, celery], alsoMentions: [olive oil]}
    - {text: "Turn up the heat, add both minces and brown for 8-10 minutes.", durations: [[8, 10]], mentions: [], alsoMentions: [beef mince, pork mince]}
    - {text: "Pour in the wine and bubble for 2 minutes.", durations: [[2, 2]], mentions: [], alsoMentions: [red wine]}
    - {text: "Add the tomatoes, purée, stock and bay leaves. Simmer, lid ajar, for 1½ hours, stirring now and then, until thick.", durations: [[90, 90]], mentions: [bay leaves], alsoMentions: [chopped tomatoes, tomato purée, beef stock]}
notes: >
  `durations(in:)` does not clean unicode fractions, so "1½ hours" gives no timer at all today (and "1 1/2 hours"
  would give 2 hours). "250 g / 9 oz" leaves "/ 9 oz pork mince" as the name. "pint" is not a unit. A line with
  three ingredients links only the first. "both minces" maps to two ingredients; fine to leave unlinked.
```

### paste-12 Chickpea coconut curry (US can sizes)

```yaml
id: paste-12
shape: can-sizes
raw: |
  Chickpea coconut curry
  Serves 4
  Ingredients
  1 tbsp coconut oil
  1 onion, diced
  1 tbsp curry powder
  1 (14 oz) can chickpeas, drained and rinsed
  1 (13.5 oz) can full-fat coconut milk
  1 (15-ounce) can diced tomatoes
  2 big handfuls baby spinach
  1/2 lime
  Directions
  Cook the onion in the coconut oil for 5-7 minutes.
  Add the curry powder and stir 30 seconds.
  Add the chickpeas, coconut milk and tomatoes. Simmer 15-20 minutes.
  Wilt in the spinach, squeeze over the lime and serve with rice.
expect:
  title: "Chickpea coconut curry"
  serves: 4
  ingredients:
    - {amount: 1, unit: tbsp, name: coconut oil, raw: "1 tbsp coconut oil"}
    - {amount: 1, name: onion, prep: diced, raw: "1 onion, diced"}
    - {amount: 1, unit: tbsp, name: curry powder, raw: "1 tbsp curry powder"}
    - {amount: 1, unit: can, packSize: "14 oz", name: chickpeas, prep: drained and rinsed, raw: "1 (14 oz) can chickpeas, drained and rinsed"}
    - {amount: 1, unit: can, packSize: "13.5 oz", name: coconut milk, prep: full-fat, raw: "1 (13.5 oz) can full-fat coconut milk"}
    - {amount: 1, unit: can, packSize: "15 oz", name: diced tomatoes, raw: "1 (15-ounce) can diced tomatoes"}
    - {amount: 2, unit: handful, name: baby spinach, prep: big, raw: "2 big handfuls baby spinach"}
    - {amount: 0.5, name: lime, raw: "1/2 lime"}
  steps:
    - {text: "Cook the onion in the coconut oil for 5-7 minutes.", durations: [[5, 7]], mentions: [onion, coconut oil]}
    - {text: "Add the curry powder and stir 30 seconds.", durations: [[0.5, 0.5]], mentions: [curry powder]}
    - {text: "Add the chickpeas, coconut milk and tomatoes. Simmer 15-20 minutes.", durations: [[15, 20]], mentions: [chickpeas, coconut milk], alsoMentions: [diced tomatoes]}
    - {text: "Wilt in the spinach, squeeze over the lime and serve with rice.", durations: [], mentions: [lime], alsoMentions: [baby spinach]}
notes: >
  The US "1 (14 oz) can" shape: today the unit regex stops at "(", the parenthetical is removed afterwards, and the
  name becomes "can chickpeas" with no unit. "2 big handfuls" puts a size word before the unit, so the name becomes
  "handfuls baby spinach". "rice" in step 4 is not an ingredient and must not create one.
```

### paste-13 Chicken katsu curry (sections, "To serve:")

```yaml
id: paste-13
shape: sauce-sections
raw: |
  Chicken katsu curry
  Serves 2
  For the curry sauce:
  1 tbsp vegetable oil
  1 onion, chopped
  2 garlic cloves, crushed
  1 carrot, chopped
  1 tbsp mild curry powder
  1 tbsp plain flour
  400 ml chicken stock
  1 tsp honey
  1 tbsp soy sauce
  For the chicken:
  2 chicken breasts, butterflied
  2 tbsp plain flour
  1 egg, beaten
  60 g panko breadcrumbs
  Oil, for shallow frying
  To serve:
  Steamed rice
  Pickled ginger
  Method
  For the sauce, fry the onion, garlic and carrot in the oil for 10 mins until soft.
  Stir in the curry powder and flour for 1 min, then whisk in the stock, honey and soy. Simmer 15-20 min and blend.
  Dip the chicken in flour, then egg, then panko.
  Shallow fry for 4-5 minutes each side until golden and cooked through. Rest 2 min, slice and serve on rice with the sauce and ginger.
expect:
  title: "Chicken katsu curry"
  serves: 2
  ingredients:
    - {section: curry sauce, amount: 1, unit: tbsp, name: vegetable oil, raw: "1 tbsp vegetable oil"}
    - {section: curry sauce, amount: 1, name: onion, prep: chopped, raw: "1 onion, chopped"}
    - {section: curry sauce, amount: 2, unit: clove, name: garlic, prep: crushed, raw: "2 garlic cloves, crushed"}
    - {section: curry sauce, amount: 1, name: carrot, prep: chopped, raw: "1 carrot, chopped"}
    - {section: curry sauce, amount: 1, unit: tbsp, name: curry powder, prep: mild, raw: "1 tbsp mild curry powder"}
    - {section: curry sauce, amount: 1, unit: tbsp, name: plain flour, raw: "1 tbsp plain flour"}
    - {section: curry sauce, amount: 400, unit: ml, name: chicken stock, raw: "400 ml chicken stock"}
    - {section: curry sauce, amount: 1, unit: tsp, name: honey, raw: "1 tsp honey"}
    - {section: curry sauce, amount: 1, unit: tbsp, name: soy sauce, raw: "1 tbsp soy sauce"}
    - {section: chicken, amount: 2, name: chicken breasts, prep: butterflied, raw: "2 chicken breasts, butterflied"}
    - {section: chicken, amount: 2, unit: tbsp, name: plain flour, raw: "2 tbsp plain flour"}
    - {section: chicken, amount: 1, name: egg, prep: beaten, raw: "1 egg, beaten"}
    - {section: chicken, amount: 60, unit: g, name: panko breadcrumbs, raw: "60 g panko breadcrumbs"}
    - {section: chicken, name: oil, prep: for shallow frying, raw: "Oil, for shallow frying"}
    - {section: to serve, name: rice, prep: steamed, raw: "Steamed rice"}
    - {section: to serve, name: pickled ginger, raw: "Pickled ginger"}
  steps:
    - {text: "For the sauce, fry the onion, garlic and carrot in the oil for 10 mins until soft.", durations: [[10, 10]], mentions: [onion, garlic, carrot], alsoMentions: [vegetable oil]}
    - {text: "Stir in the curry powder and flour for 1 min, then whisk in the stock, honey and soy. Simmer 15-20 min and blend.", durations: [[1, 1], [15, 20]], mentions: [curry powder, honey], alsoMentions: [plain flour, chicken stock, soy sauce]}
    - {text: "Dip the chicken in flour, then egg, then panko.", durations: [], mentions: [egg], alsoMentions: [chicken breasts, plain flour, panko breadcrumbs]}
    - {text: "Shallow fry for 4-5 minutes each side until golden and cooked through. Rest 2 min, slice and serve on rice with the sauce and ginger.", durations: [[4, 5], [2, 2]], mentions: [rice], alsoMentions: [pickled ginger]}
notes: >
  "For the ..." headings work today, but sections are not kept. "To serve:" is not a heading and becomes an
  ingredient named "To serve:". "oil" appears twice (vegetable oil, Oil): step 1's "the oil" should go to vegetable
  oil by section, which is a nice-to-have. "For the sauce, fry ..." in the method must stay a step (it does: too long).
  The same ingredient twice (plain flour) must make two lines and one Ingredient.
```

### paste-14 Roast veg (Notes, salt & pepper next to sweet peppers)

```yaml
id: paste-14
shape: salt-and-pepper
raw: |
  roast veg
  3 peppers (mixed colours), in chunks
  2 courgettes, sliced into half moons
  1 red onion, wedges
  1 aubergine, cubed
  3-4 tbsp olive oil
  1 tsp dried oregano
  salt & pepper
  chilli flakes, to taste
  balsamic, to finish (optional)
  Oven 220C / 200C fan.
  Toss everything except the balsamic with the oil, oregano and a good pinch of salt & pepper.
  Roast 35-40 mins, shaking the tray halfway.
  Drizzle with balsamic before serving.
expect:
  title: "roast veg"
  serves: null
  ingredients:
    - {amount: 3, name: peppers, prep: in chunks, raw: "3 peppers (mixed colours), in chunks"}
    - {amount: 2, name: courgettes, prep: sliced into half moons, raw: "2 courgettes, sliced into half moons"}
    - {amount: 1, name: red onion, prep: wedges, raw: "1 red onion, wedges"}
    - {amount: 1, name: aubergine, prep: cubed, raw: "1 aubergine, cubed"}
    - {amount: 3, amountMax: 4, unit: tbsp, name: olive oil, raw: "3-4 tbsp olive oil"}
    - {amount: 1, unit: tsp, name: dried oregano, raw: "1 tsp dried oregano"}
    - {name: salt, toTaste: true, raw: "salt & pepper"}
    - {name: black pepper, toTaste: true, raw: "salt & pepper"}
    - {name: chilli flakes, toTaste: true, raw: "chilli flakes, to taste"}
    - {name: balsamic, prep: "to finish, optional", raw: "balsamic, to finish (optional)"}
  steps:
    - {text: "Oven 220C / 200C fan.", durations: [], mentions: []}
    - {text: "Toss everything except the balsamic with the oil, oregano and a good pinch of salt & pepper.", durations: [], mentions: [balsamic, salt], alsoMentions: [olive oil, dried oregano, black pepper]}
    - {text: "Roast 35-40 mins, shaking the tray halfway.", durations: [[35, 40]], mentions: []}
    - {text: "Drizzle with balsamic before serving.", durations: [], mentions: [balsamic]}
notes: >
  "salt & pepper" with no amount means seasoning to taste: two staples, salt and black pepper, which groceries skip.
  Today it is one ingredient "salt & pepper" (a new object that is not a staple, so it lands on the grocery list),
  and the mention matcher links step 2 to the sweet "peppers" because the step contains the word "pepper". The bare
  word "pepper" next to "peppers" must never link the sweet peppers.
```

### paste-15 Dal tadka (Indian, whistles, "Tadka:" sub-heading)

```yaml
id: paste-15
shape: indian-dal
raw: |
  Dal Tadka
  Serves 4
  Ingredients
  1 cup toor dal, washed and soaked 30 min
  3 cups water
  1/2 tsp haldi
  Salt as per taste
  Tadka:
  2 tbsp ghee
  1 tsp jeera
  a pinch of hing
  2 dry red chillies
  1 inch ginger, finely chopped
  4-5 garlic cloves, chopped
  1 onion, finely chopped
  1 tomato, chopped
  1/2 tsp Kashmiri red chilli powder
  2 tbsp chopped coriander
  Method
  Pressure cook the dal with water, haldi and salt for 3 whistles on medium flame. Let the pressure drop on its own, about 10 minutes.
  Whisk the cooked dal until smooth. Add hot water if it is too thick.
  Heat ghee in a kadai. Add jeera and let it splutter, then hing and red chillies for a few seconds.
  Add ginger, garlic and onion and fry 4-5 min till golden.
  Add tomato and chilli powder, cook 3-4 minutes till soft and mushy.
  Pour the tadka over the dal, simmer 2 min, garnish with coriander.
expect:
  title: "Dal Tadka"
  serves: 4
  ingredients:
    - {amount: 1, unit: cup, name: toor dal, prep: washed and soaked 30 min, raw: "1 cup toor dal, washed and soaked 30 min"}
    - {amount: 3, unit: cup, name: water, raw: "3 cups water"}
    - {amount: 0.5, unit: tsp, name: haldi, raw: "1/2 tsp haldi"}
    - {name: Salt, toTaste: true, raw: "Salt as per taste"}
    - {section: tadka, amount: 2, unit: tbsp, name: ghee, raw: "2 tbsp ghee"}
    - {section: tadka, amount: 1, unit: tsp, name: jeera, raw: "1 tsp jeera"}
    - {section: tadka, amount: 1, unit: pinch, name: hing, raw: "a pinch of hing"}
    - {section: tadka, amount: 2, name: dry red chillies, raw: "2 dry red chillies"}
    - {section: tadka, amount: 1, unit: inch, name: ginger, prep: finely chopped, raw: "1 inch ginger, finely chopped"}   # new unit
    - {section: tadka, amount: 4, amountMax: 5, unit: clove, name: garlic, prep: chopped, raw: "4-5 garlic cloves, chopped"}
    - {section: tadka, amount: 1, name: onion, prep: finely chopped, raw: "1 onion, finely chopped"}
    - {section: tadka, amount: 1, name: tomato, prep: chopped, raw: "1 tomato, chopped"}
    - {section: tadka, amount: 0.5, unit: tsp, name: Kashmiri red chilli powder, raw: "1/2 tsp Kashmiri red chilli powder"}
    - {section: tadka, amount: 2, unit: tbsp, name: coriander, prep: chopped, raw: "2 tbsp chopped coriander"}
  steps:
    - {text: "Pressure cook the dal with water, haldi and salt for 3 whistles on medium flame. Let the pressure drop on its own, about 10 minutes.", durations: [[10, 10]], mentions: [water, haldi, Salt], alsoMentions: [toor dal]}
    - {text: "Whisk the cooked dal until smooth. Add hot water if it is too thick.", durations: [], mentions: [water], alsoMentions: [toor dal]}
    - {text: "Heat ghee in a kadai. Add jeera and let it splutter, then hing and red chillies for a few seconds.", durations: [], mentions: [ghee, jeera, hing], alsoMentions: [dry red chillies]}
    - {text: "Add ginger, garlic and onion and fry 4-5 min till golden.", durations: [[4, 5]], mentions: [ginger, garlic, onion]}
    - {text: "Add tomato and chilli powder, cook 3-4 minutes till soft and mushy.", durations: [[3, 4]], mentions: [tomato], alsoMentions: [Kashmiri red chilli powder]}
    - {text: "Pour the tadka over the dal, simmer 2 min, garnish with coriander.", durations: [[2, 2]], mentions: [coriander], alsoMentions: [toor dal]}
notes: >
  The core Indian case. "3 whistles" is a pressure-cooker count, not a duration: no timer (a whistle counter is a
  cook-mode idea for later). "Tadka:" inside the ingredients becomes an ingredient today. "Salt as per taste" and
  "1 inch ginger" fail. The mention matcher misses "dal" for "toor dal", which is the dish's main ingredient.
```

### paste-16 Chana masala (Hinglish, numbered steps with timers)

```yaml
id: paste-16
shape: indian-step-timers
raw: |
  Chana masala (Punjabi style)
  Serves 3-4
  Ingredients
  1 cup kabuli chana, soaked overnight
  2 tej patta
  1 tsp salt
  2 tbsp oil
  1 tsp jeera
  2 onions, finely chopped
  1 tbsp ginger garlic paste
  2 tomatoes, pureed
  1 tsp haldi
  1 tsp dhaniya powder
  1 tsp lal mirch powder
  2 tsp chana masala
  1 tsp kasuri methi, crushed
  1/2 tsp amchur
  Fresh dhaniya, for garnish
  Steps
  1. Pressure cook chana with tej patta, salt and 3 cups water: 1 whistle on high, then 15-20 min on low.
  2. Heat oil, add jeera. When it crackles add onions and fry 8-10 min till golden brown.
  3. Add ginger garlic paste, saute 1 min.
  4. Add tomato puree and all the dry masalas except kasuri methi. Bhuno 5-7 min till oil separates.
  5. Add the chana with its water. Simmer 10-12 min, mashing a few chanas to thicken the gravy.
  6. Finish with kasuri methi and fresh dhaniya.
expect:
  title: "Chana masala (Punjabi style)"
  serves: 3
  ingredients:
    - {amount: 1, unit: cup, name: kabuli chana, prep: soaked overnight, raw: "1 cup kabuli chana, soaked overnight"}
    - {amount: 2, name: tej patta, raw: "2 tej patta"}
    - {amount: 1, unit: tsp, name: salt, raw: "1 tsp salt"}
    - {amount: 2, unit: tbsp, name: oil, raw: "2 tbsp oil"}
    - {amount: 1, unit: tsp, name: jeera, raw: "1 tsp jeera"}
    - {amount: 2, name: onions, prep: finely chopped, raw: "2 onions, finely chopped"}
    - {amount: 1, unit: tbsp, name: ginger garlic paste, raw: "1 tbsp ginger garlic paste"}
    - {amount: 2, name: tomatoes, prep: pureed, raw: "2 tomatoes, pureed"}
    - {amount: 1, unit: tsp, name: haldi, raw: "1 tsp haldi"}
    - {amount: 1, unit: tsp, name: dhaniya powder, raw: "1 tsp dhaniya powder"}
    - {amount: 1, unit: tsp, name: lal mirch powder, raw: "1 tsp lal mirch powder"}
    - {amount: 2, unit: tsp, name: chana masala, raw: "2 tsp chana masala"}
    - {amount: 1, unit: tsp, name: kasuri methi, prep: crushed, raw: "1 tsp kasuri methi, crushed"}
    - {amount: 0.5, unit: tsp, name: amchur, raw: "1/2 tsp amchur"}
    - {name: dhaniya, prep: "fresh, for garnish", raw: "Fresh dhaniya, for garnish"}
  steps:
    - {text: "Pressure cook chana with tej patta, salt and 3 cups water: 1 whistle on high, then 15-20 min on low.", durations: [[15, 20]], mentions: [tej patta, salt], alsoMentions: [kabuli chana]}
    - {text: "Heat oil, add jeera. When it crackles add onions and fry 8-10 min till golden brown.", durations: [[8, 10]], mentions: [oil, jeera, onions]}
    - {text: "Add ginger garlic paste, saute 1 min.", durations: [[1, 1]], mentions: [ginger garlic paste]}
    - {text: "Add tomato puree and all the dry masalas except kasuri methi. Bhuno 5-7 min till oil separates.", durations: [[5, 7]], mentions: [tomatoes, kasuri methi, oil]}
    - {text: "Add the chana with its water. Simmer 10-12 min, mashing a few chanas to thicken the gravy.", durations: [[10, 12]], mentions: [], alsoMentions: [kabuli chana]}
    - {text: "Finish with kasuri methi and fresh dhaniya.", durations: [], mentions: [kasuri methi, dhaniya]}
notes: >
  Mostly a control: headings, numbered steps and Hindi names should read today. Watch "chana" (kabuli chana) next to
  "chana masala" (a spice blend): a short-form rule must link "chana" to kabuli chana, never to the masala. Water is
  named only inside a step, so it is not an ingredient. "1 whistle" is not a timer.
```

### paste-17 Jeera rice (Notes, Hinglish steps)

```yaml
id: paste-17
shape: indian-notes-hinglish
raw: |
  Jeera rice
  1 cup basmati rice (soak 20 min)
  1½ cups water
  1 tbsp ghee
  1 tsp jeera
  1 tej patta
  2-3 laung
  1 small piece dalchini
  salt to taste

  Wash rice 3 times and soak 20 min, drain.
  Ghee mein jeera, tej patta, laung, dalchini, 30 sec.
  Rice daal ke 1 min bhuno, then water and salt.
  Boil, then cover and cook on lowest flame 12-15 min.
  Switch off and keep covered 5 min. Fluff with fork.
expect:
  title: "Jeera rice"
  serves: null
  ingredients:
    - {amount: 1, unit: cup, name: basmati rice, prep: soak 20 min, raw: "1 cup basmati rice (soak 20 min)"}
    - {amount: 1.5, unit: cup, name: water, raw: "1½ cups water"}
    - {amount: 1, unit: tbsp, name: ghee, raw: "1 tbsp ghee"}
    - {amount: 1, unit: tsp, name: jeera, raw: "1 tsp jeera"}
    - {amount: 1, name: tej patta, raw: "1 tej patta"}
    - {amount: 2, amountMax: 3, name: laung, raw: "2-3 laung"}
    - {amount: 1, unit: piece, name: dalchini, prep: small, raw: "1 small piece dalchini"}
    - {name: salt, toTaste: true, raw: "salt to taste"}
  steps:
    - {text: "Wash rice 3 times and soak 20 min, drain.", durations: [[20, 20]], mentions: [], alsoMentions: [basmati rice]}
    - {text: "Ghee mein jeera, tej patta, laung, dalchini, 30 sec.", durations: [[0.5, 0.5]], mentions: [ghee, jeera, tej patta, laung, dalchini]}
    - {text: "Rice daal ke 1 min bhuno, then water and salt.", durations: [[1, 1]], mentions: [water, salt], alsoMentions: [basmati rice]}
    - {text: "Boil, then cover and cook on lowest flame 12-15 min.", durations: [[12, 15]], mentions: []}
    - {text: "Switch off and keep covered 5 min. Fluff with fork.", durations: [[5, 5]], mentions: []}
notes: >
  "daal ke" is Hindi for "after adding", not lentils; it must not link a dal ingredient (none here, but keep it in
  mind for alias rules). A parenthetical that is an instruction ("soak 20 min") is dropped today; keeping it as prep
  is better. "1 small piece dalchini" puts a size word before the unit, so the name becomes "piece dalchini".
```

### paste-18 Palak paneer (Indian food blog, story, "Print Recipe")

```yaml
id: paste-18
shape: indian-blog
raw: |
  Palak Paneer Recipe | Restaurant Style
  Published on March 3 · 4 comments
  Palak paneer was the first dish I learnt to make after leaving home. This version keeps the spinach bright green by blanching it quickly and cooling it in ice water.
  Print Recipe
  Prep Time: 15 mins
  Cook Time: 25 mins
  Servings: 3 people
  Ingredients
  For the palak puree
  1 bunch palak (about 250 g), washed
  1-2 green chillies
  For the gravy
  2 tbsp oil or ghee
  1 tsp jeera
  1 onion, finely chopped
  1 tsp ginger garlic paste
  1 tomato, chopped
  ¼ tsp haldi
  ½ tsp garam masala
  200 g paneer, cut into cubes
  2 tbsp cream (optional)
  Salt to taste
  Instructions
  Blanch the palak in boiling water for 2 minutes, then plunge into ice water.
  Blend the palak with the green chillies to a smooth puree.
  Heat oil in a pan, add jeera and let it crackle. Add onion and saute 5-6 minutes until golden.
  Add ginger garlic paste and saute 1 minute. Add tomato and haldi and cook 3-4 minutes.
  Add the palak puree and garam masala and simmer 5 minutes.
  Add paneer and cream and simmer 2-3 minutes more. Check salt.
expect:
  title: "Palak Paneer"
  serves: 3
  activeMinutes: 15
  totalMinutes: 40
  ingredients:
    - {section: palak puree, amount: 1, unit: bunch, name: palak, prep: washed, raw: "1 bunch palak (about 250 g), washed"}
    - {section: palak puree, amount: 1, amountMax: 2, name: green chillies, raw: "1-2 green chillies"}
    - {section: gravy, amount: 2, unit: tbsp, name: oil or ghee, raw: "2 tbsp oil or ghee"}
    - {section: gravy, amount: 1, unit: tsp, name: jeera, raw: "1 tsp jeera"}
    - {section: gravy, amount: 1, name: onion, prep: finely chopped, raw: "1 onion, finely chopped"}
    - {section: gravy, amount: 1, unit: tsp, name: ginger garlic paste, raw: "1 tsp ginger garlic paste"}
    - {section: gravy, amount: 1, name: tomato, prep: chopped, raw: "1 tomato, chopped"}
    - {section: gravy, amount: 0.25, unit: tsp, name: haldi, raw: "¼ tsp haldi"}
    - {section: gravy, amount: 0.5, unit: tsp, name: garam masala, raw: "½ tsp garam masala"}
    - {section: gravy, amount: 200, unit: g, name: paneer, prep: cut into cubes, raw: "200 g paneer, cut into cubes"}
    - {section: gravy, amount: 2, unit: tbsp, name: cream, prep: optional, raw: "2 tbsp cream (optional)"}
    - {section: gravy, name: Salt, toTaste: true, raw: "Salt to taste"}
  steps:
    - {text: "Blanch the palak in boiling water for 2 minutes, then plunge into ice water.", durations: [[2, 2]], mentions: [palak]}
    - {text: "Blend the palak with the green chillies to a smooth puree.", durations: [], mentions: [palak, green chillies]}
    - {text: "Heat oil in a pan, add jeera and let it crackle. Add onion and saute 5-6 minutes until golden.", durations: [[5, 6]], mentions: [jeera, onion], alsoMentions: [oil or ghee]}
    - {text: "Add ginger garlic paste and saute 1 minute. Add tomato and haldi and cook 3-4 minutes.", durations: [[1, 1], [3, 4]], mentions: [ginger garlic paste, tomato, haldi]}
    - {text: "Add the palak puree and garam masala and simmer 5 minutes.", durations: [[5, 5]], mentions: [palak, garam masala]}
    - {text: "Add paneer and cream and simmer 2-3 minutes more. Check salt.", durations: [[2, 3]], mentions: [paneer, cream, Salt]}
notes: >
  Indian food blogs put "Recipe | Restaurant Style" in the title; strip " Recipe" and anything after "|". The
  byline, story and "Print Recipe" become steps or ingredients today. Total is prep plus cook (15 + 25) when no
  total is given; today cook time is read and thrown away. "oil or ghee" stays one ingredient for now.
```

### paste-19 Aloo paratha (WhatsApp forward, amounts after names)

```yaml
id: paste-19
shape: indian-whatsapp
raw: |
  *Aloo Paratha* 🫓
  (makes 6)

  *Dough*
  Atta - 2 cups
  Salt - 1/2 tsp
  Oil - 1 tbsp
  Water - as needed

  *Filling*
  Aloo - 4 medium, boiled & mashed
  Hari mirch - 2, finely chopped
  Adrak - 1 inch, grated
  Jeera powder - 1 tsp
  Amchur - 1/2 tsp
  Hara dhaniya - handful, chopped
  Namak - swaad anusar

  Atta, salt, oil mix karo, water thoda thoda daal ke soft dough. Cover 20 min rest.
  Filling ke sab ingredients mix karo.
  Dough ki 6 balls, each ball mein filling bhar ke seal karo, roll gently.
  Tawa garam karo, paratha dono side 1-2 min, ghee laga ke crisp hone tak.
expect:
  title: "Aloo Paratha"
  serves: null
  ingredients:
    - {section: dough, amount: 2, unit: cup, name: Atta, raw: "Atta - 2 cups"}
    - {section: dough, amount: 0.5, unit: tsp, name: Salt, raw: "Salt - 1/2 tsp"}
    - {section: dough, amount: 1, unit: tbsp, name: Oil, raw: "Oil - 1 tbsp"}
    - {section: dough, name: Water, raw: "Water - as needed"}
    - {section: filling, amount: 4, name: Aloo, prep: "medium, boiled & mashed", raw: "Aloo - 4 medium, boiled & mashed"}
    - {section: filling, amount: 2, name: Hari mirch, prep: finely chopped, raw: "Hari mirch - 2, finely chopped"}
    - {section: filling, amount: 1, unit: inch, name: Adrak, prep: grated, raw: "Adrak - 1 inch, grated"}   # new unit
    - {section: filling, amount: 1, unit: tsp, name: Jeera powder, raw: "Jeera powder - 1 tsp"}
    - {section: filling, amount: 0.5, unit: tsp, name: Amchur, raw: "Amchur - 1/2 tsp"}
    - {section: filling, amount: 1, unit: handful, name: Hara dhaniya, prep: chopped, raw: "Hara dhaniya - handful, chopped"}
    - {section: filling, name: Namak, toTaste: true, raw: "Namak - swaad anusar"}
  steps:
    - {text: "Atta, salt, oil mix karo, water thoda thoda daal ke soft dough. Cover 20 min rest.", durations: [[20, 20]], mentions: [Atta, Salt, Oil, Water]}
    - {text: "Filling ke sab ingredients mix karo.", durations: [], mentions: []}
    - {text: "Dough ki 6 balls, each ball mein filling bhar ke seal karo, roll gently.", durations: [], mentions: []}
    - {text: "Tawa garam karo, paratha dono side 1-2 min, ghee laga ke crisp hone tak.", durations: [[1, 2]], mentions: []}
notes: >
  The family-group forward: WhatsApp bold asterisks, an emoji, "Name - amount" lines, and Hindi "swaad anusar"
  (to taste). Today the title keeps "* 🫓", "(makes 6)" and "*Dough*" become ingredients, and every "Name - amount"
  line has no amount. Expected serves null, makes 6. Bold lines like "*Dough*" are section labels. "ghee" in step 4
  is not in the list; do not invent it.
```

### paste-20 Masala chai (Notes, tiny)

```yaml
id: paste-20
shape: indian-notes-small
raw: |
  Masala chai (2 cups)
  1 cup water
  1 cup milk
  2 tsp chai patti
  2 tsp sugar, or to taste
  2-3 elaichi, crushed
  ½ inch adrak, grated
  1 laung (optional)
  Boil water with adrak, elaichi and laung for 2 to 3 minutes.
  Add chai patti, boil 1 min till colour comes.
  Add milk and sugar. Bring to a boil and simmer 2-3 min, it will rise, watch it.
  Strain into cups.
expect:
  title: "Masala chai"
  serves: 2
  ingredients:
    - {amount: 1, unit: cup, name: water, raw: "1 cup water"}
    - {amount: 1, unit: cup, name: milk, raw: "1 cup milk"}
    - {amount: 2, unit: tsp, name: chai patti, raw: "2 tsp chai patti"}
    - {amount: 2, unit: tsp, name: sugar, toTaste: true, raw: "2 tsp sugar, or to taste"}
    - {amount: 2, amountMax: 3, name: elaichi, prep: crushed, raw: "2-3 elaichi, crushed"}
    - {amount: 0.5, unit: inch, name: adrak, prep: grated, raw: "½ inch adrak, grated"}   # new unit
    - {amount: 1, name: laung, prep: optional, raw: "1 laung (optional)"}
  steps:
    - {text: "Boil water with adrak, elaichi and laung for 2 to 3 minutes.", durations: [[2, 3]], mentions: [water, adrak, elaichi, laung]}
    - {text: "Add chai patti, boil 1 min till colour comes.", durations: [[1, 1]], mentions: [chai patti]}
    - {text: "Add milk and sugar. Bring to a boil and simmer 2-3 min, it will rise, watch it.", durations: [[2, 3]], mentions: [milk, sugar]}
    - {text: "Strain into cups.", durations: [], mentions: []}
notes: >
  "(2 cups)" in the title is the yield; read it as serves 2 and drop it from the title. "or to taste" leaves prep
  "or" today. "½ inch" fails on the unit. A good first paste for the demo: short, two timers.
```

### paste-21 Hyderabadi chicken dum biryani (Indian, three sections, long waits)

```yaml
id: paste-21
shape: indian-sections
raw: |
  Hyderabadi chicken dum biryani
  Serves 5
  Total time: 2 hours (plus 2 hours marinating)

  For the marinade:
  750 g chicken, curry cut
  1 cup thick dahi
  1½ tbsp ginger garlic paste
  1 tsp Kashmiri chilli powder
  ½ tsp haldi
  1 tsp biryani masala
  Juice of ½ lemon
  1 tsp salt
  For the rice:
  2 cups basmati rice, soaked 30 minutes
  8 cups water
  1 tbsp salt
  2 tej patta, 4 laung, 4 elaichi
  For layering:
  2 onions, thinly sliced and fried golden (birista)
  ¼ cup mint leaves
  ¼ cup coriander leaves
  A pinch of saffron in 3 tbsp warm milk
  3 tbsp ghee

  Method
  Mix the chicken with everything for the marinade and leave for 2 hours, or overnight in the fridge.
  Boil the water with the salt and whole spices. Add the rice and cook 5-6 minutes until 70% done, then drain.
  Spread the chicken in a heavy pot. Layer half the birista, mint and coriander, then the rice, then the rest.
  Drizzle over the saffron milk and ghee. Seal the lid with dough or foil.
  Cook on high for 5 minutes, then on the lowest heat for 35-40 minutes (dum).
  Rest 10 min before opening. Mix gently from the sides.
expect:
  title: "Hyderabadi chicken dum biryani"
  serves: 5
  totalMinutes: 120
  ingredients:
    - {section: marinade, amount: 750, unit: g, name: chicken, prep: curry cut, raw: "750 g chicken, curry cut"}
    - {section: marinade, amount: 1, unit: cup, name: dahi, prep: thick, raw: "1 cup thick dahi"}
    - {section: marinade, amount: 1.5, unit: tbsp, name: ginger garlic paste, raw: "1½ tbsp ginger garlic paste"}
    - {section: marinade, amount: 1, unit: tsp, name: Kashmiri chilli powder, raw: "1 tsp Kashmiri chilli powder"}
    - {section: marinade, amount: 0.5, unit: tsp, name: haldi, raw: "½ tsp haldi"}
    - {section: marinade, amount: 1, unit: tsp, name: biryani masala, raw: "1 tsp biryani masala"}
    - {section: marinade, amount: 0.5, name: lemon, prep: juice, raw: "Juice of ½ lemon"}
    - {section: marinade, amount: 1, unit: tsp, name: salt, raw: "1 tsp salt"}
    - {section: rice, amount: 2, unit: cup, name: basmati rice, prep: soaked 30 minutes, raw: "2 cups basmati rice, soaked 30 minutes"}
    - {section: rice, amount: 8, unit: cup, name: water, raw: "8 cups water"}
    - {section: rice, amount: 1, unit: tbsp, name: salt, raw: "1 tbsp salt"}
    - {section: rice, amount: 2, name: tej patta, raw: "2 tej patta, 4 laung, 4 elaichi"}
    - {section: rice, amount: 4, name: laung, raw: "2 tej patta, 4 laung, 4 elaichi"}
    - {section: rice, amount: 4, name: elaichi, raw: "2 tej patta, 4 laung, 4 elaichi"}
    - {section: layering, amount: 2, name: onions, prep: thinly sliced and fried golden, raw: "2 onions, thinly sliced and fried golden (birista)"}
    - {section: layering, amount: 0.25, unit: cup, name: mint leaves, raw: "¼ cup mint leaves"}
    - {section: layering, amount: 0.25, unit: cup, name: coriander leaves, raw: "¼ cup coriander leaves"}
    - {section: layering, amount: 1, unit: pinch, name: saffron, raw: "A pinch of saffron in 3 tbsp warm milk"}
    - {section: layering, amount: 3, unit: tbsp, name: milk, prep: warm, raw: "A pinch of saffron in 3 tbsp warm milk"}
    - {section: layering, amount: 3, unit: tbsp, name: ghee, raw: "3 tbsp ghee"}
  steps:
    - {text: "Mix the chicken with everything for the marinade and leave for 2 hours, or overnight in the fridge.", durations: [[120, 120]], mentions: [chicken]}
    - {text: "Boil the water with the salt and whole spices. Add the rice and cook 5-6 minutes until 70% done, then drain.", durations: [[5, 6]], mentions: [water, salt], alsoMentions: [basmati rice]}
    - {text: "Spread the chicken in a heavy pot. Layer half the birista, mint and coriander, then the rice, then the rest.", durations: [], mentions: [chicken], alsoMentions: [mint leaves, coriander leaves, basmati rice]}
    - {text: "Drizzle over the saffron milk and ghee. Seal the lid with dough or foil.", durations: [], mentions: [saffron, milk, ghee]}
    - {text: "Cook on high for 5 minutes, then on the lowest heat for 35-40 minutes (dum).", durations: [[5, 5], [35, 40]], mentions: []}
    - {text: "Rest 10 min before opening. Mix gently from the sides.", durations: [[10, 10]], mentions: []}
notes: >
  "For layering:" does not start with "for the ", so it becomes an ingredient today. "2 tej patta, 4 laung, 4 elaichi"
  becomes tej patta with prep "4 laung, 4 elaichi". "Juice of ½ lemon" and "saffron in 3 tbsp warm milk" keep the
  whole phrase as the name. Salt appears twice in two sections: two lines, one Ingredient. The 2 hour marinade is
  outside the stated total and should not be added to it.
```

### paste-22 Simple roast chicken (numbered method, two oven stages)

```yaml
id: paste-22
shape: step-timers-numbered
raw: |
  Simple roast chicken
  Serves 4
  Ingredients
  1 whole chicken (1.6-1.8 kg)
  1 lemon, halved
  1 head garlic, halved across
  4 sprigs thyme
  30 g soft butter
  1 kg potatoes, peeled and halved
  2 tbsp olive oil
  Method
  1. Heat the oven to 220C. Take the chicken out of the fridge 30-45 minutes before.
  2. Stuff the lemon, garlic and thyme into the cavity and rub the butter all over the skin.
  3. Parboil the potatoes for 8 minutes, drain and toss with the olive oil.
  4. Roast the chicken for 20 min, then turn the oven down to 190C and add the potatoes.
  5. Roast for 50-60 min more, until the juices run clear. Rest for 15 minutes before carving.
expect:
  title: "Simple roast chicken"
  serves: 4
  ingredients:
    - {amount: 1, name: chicken, prep: whole, raw: "1 whole chicken (1.6-1.8 kg)"}
    - {amount: 1, name: lemon, prep: halved, raw: "1 lemon, halved"}
    - {amount: 1, unit: head, name: garlic, prep: halved across, raw: "1 head garlic, halved across"}
    - {amount: 4, unit: sprig, name: thyme, raw: "4 sprigs thyme"}
    - {amount: 30, unit: g, name: butter, prep: soft, raw: "30 g soft butter"}
    - {amount: 1, unit: kg, name: potatoes, prep: peeled and halved, raw: "1 kg potatoes, peeled and halved"}
    - {amount: 2, unit: tbsp, name: olive oil, raw: "2 tbsp olive oil"}
  steps:
    - {text: "Heat the oven to 220C. Take the chicken out of the fridge 30-45 minutes before.", durations: [[30, 45]], mentions: [chicken]}
    - {text: "Stuff the lemon, garlic and thyme into the cavity and rub the butter all over the skin.", durations: [], mentions: [lemon, garlic, thyme, butter]}
    - {text: "Parboil the potatoes for 8 minutes, drain and toss with the olive oil.", durations: [[8, 8]], mentions: [potatoes, olive oil]}
    - {text: "Roast the chicken for 20 min, then turn the oven down to 190C and add the potatoes.", durations: [[20, 20]], mentions: [chicken, potatoes]}
    - {text: "Roast for 50-60 min more, until the juices run clear. Rest for 15 minutes before carving.", durations: [[50, 60], [15, 15]], mentions: []}
notes: >
  Control for step timers: numbered steps, oven temperatures that must not become timers, and two timers in one
  step. Only gaps: leading "whole" and "soft" stay in the name, so "whole chicken" and "soft butter" become new
  ingredients that do not merge with chicken and butter on the grocery list.
```

### paste-23 Overnight focaccia ("Step 1" on its own line)

```yaml
id: paste-23
shape: step-labels
raw: |
  Overnight focaccia

  INGREDIENTS
  500g strong white bread flour
  7g sachet fast-action yeast
  10g fine sea salt
  400ml lukewarm water
  4 tbsp extra virgin olive oil, plus extra for the tin
  Flaky salt and rosemary, for the top

  METHOD
  Step 1
  Mix the flour, yeast, salt and water into a shaggy dough. Cover and leave for 15 mins.
  Step 2
  Pour 2 tbsp of the oil over the dough and do 4 sets of stretch and folds, 15 minutes apart.
  Step 3
  Cover and chill for 12-24 hrs.
  Step 4
  Tip into an oiled 23 x 33 cm tin and leave to rise somewhere warm for 2-3 hours, until doubled.
  Step 5
  Dimple with oily fingers, drizzle with the rest of the oil and scatter with flaky salt and rosemary. Bake at 230C for 20-25 minutes.
expect:
  title: "Overnight focaccia"
  serves: null
  ingredients:
    - {amount: 500, unit: g, name: strong white bread flour, raw: "500g strong white bread flour"}
    - {amount: 7, unit: g, name: fast-action yeast, prep: sachet, raw: "7g sachet fast-action yeast"}
    - {amount: 10, unit: g, name: fine sea salt, raw: "10g fine sea salt"}
    - {amount: 400, unit: ml, name: water, prep: lukewarm, raw: "400ml lukewarm water"}
    - {amount: 4, unit: tbsp, name: extra virgin olive oil, prep: plus extra for the tin, raw: "4 tbsp extra virgin olive oil, plus extra for the tin"}
    - {name: flaky salt, prep: for the top, raw: "Flaky salt and rosemary, for the top"}
    - {name: rosemary, prep: for the top, raw: "Flaky salt and rosemary, for the top"}
  steps:
    - {text: "Mix the flour, yeast, salt and water into a shaggy dough. Cover and leave for 15 mins.", durations: [[15, 15]], mentions: [water], alsoMentions: [strong white bread flour, fast-action yeast, fine sea salt]}
    - {text: "Pour 2 tbsp of the oil over the dough and do 4 sets of stretch and folds, 15 minutes apart.", durations: [[15, 15]], mentions: [], alsoMentions: [extra virgin olive oil]}
    - {text: "Cover and chill for 12-24 hrs.", durations: [[720, 1440]], mentions: []}
    - {text: "Tip into an oiled 23 x 33 cm tin and leave to rise somewhere warm for 2-3 hours, until doubled.", durations: [[120, 180]], mentions: []}
    - {text: "Dimple with oily fingers, drizzle with the rest of the oil and scatter with flaky salt and rosemary. Bake at 230C for 20-25 minutes.", durations: [[20, 25]], mentions: [flaky salt, rosemary], alsoMentions: [extra virgin olive oil]}
notes: >
  BBC-style "Step 1" lines on their own: `stripNumbering` needs text after the number, so today each label becomes
  its own step and the recipe has 10 steps. A bare "Step N" line should start the next step. "7g sachet" leaves
  "sachet" in the name. "salt" in step 1 should go to fine sea salt, not flaky salt (the short form is shared, so by
  the proposed rule it links neither; fine). A 12-24 hour timer must be allowed (the timer cap is 24 h).
```

### paste-24 Red wine short ribs (fractional and worded durations)

```yaml
id: paste-24
shape: step-timers-fractions
raw: |
  Red wine short ribs
  Serves 4
  Prep 20 min · Cook 3½ hours
  Ingredients
  1.5 kg beef short ribs
  1 tbsp plain flour
  2 tbsp oil
  1 onion, 1 carrot, roughly chopped
  2 tbsp tomato paste
  375 ml (half a bottle) red wine
  500 ml beef stock
  3 sprigs thyme
  Method
  Season the ribs, dust with flour and brown them in the oil in batches, about 10 minutes in all.
  Soften the onion and carrot for 5 minutes, then stir in the tomato paste for 90 seconds.
  Pour in the wine and bubble for half an hour until reduced by half.
  Add the stock and thyme, cover and braise at 160C for 2½-3 hours, until the meat falls off the bone.
  Skim the fat and boil the sauce for a few minutes until glossy.
expect:
  title: "Red wine short ribs"
  serves: 4
  activeMinutes: 20
  totalMinutes: 230
  ingredients:
    - {amount: 1.5, unit: kg, name: beef short ribs, raw: "1.5 kg beef short ribs"}
    - {amount: 1, unit: tbsp, name: plain flour, raw: "1 tbsp plain flour"}
    - {amount: 2, unit: tbsp, name: oil, raw: "2 tbsp oil"}
    - {amount: 1, name: onion, prep: roughly chopped, raw: "1 onion, 1 carrot, roughly chopped"}
    - {amount: 1, name: carrot, prep: roughly chopped, raw: "1 onion, 1 carrot, roughly chopped"}
    - {amount: 2, unit: tbsp, name: tomato paste, raw: "2 tbsp tomato paste"}
    - {amount: 375, unit: ml, name: red wine, raw: "375 ml (half a bottle) red wine"}
    - {amount: 500, unit: ml, name: beef stock, raw: "500 ml beef stock"}
    - {amount: 3, unit: sprig, name: thyme, raw: "3 sprigs thyme"}
  steps:
    - {text: "Season the ribs, dust with flour and brown them in the oil in batches, about 10 minutes in all.", durations: [[10, 10]], mentions: [oil], alsoMentions: [beef short ribs, plain flour]}
    - {text: "Soften the onion and carrot for 5 minutes, then stir in the tomato paste for 90 seconds.", durations: [[5, 5], [1.5, 1.5]], mentions: [onion, carrot, tomato paste]}
    - {text: "Pour in the wine and bubble for half an hour until reduced by half.", durations: [[30, 30]], mentions: [], alsoMentions: [red wine]}
    - {text: "Add the stock and thyme, cover and braise at 160C for 2½-3 hours, until the meat falls off the bone.", durations: [[150, 180]], mentions: [thyme], alsoMentions: [beef stock]}
    - {text: "Skim the fat and boil the sauce for a few minutes until glossy.", durations: [], mentions: []}
notes: >
  "Prep 20 min · Cook 3½ hours" has no colon or "time", so `timeLine` skips it and it becomes a step with a 20 min
  timer. "2½-3 hours" gives [180, 180] today (only "3 hours" matches) and "half an hour" gives nothing. Worded
  durations to support: "half an hour", "an hour", "a minute", "a couple of minutes". "a few minutes" stays no timer.
```

### paste-25 Mushroom risotto (knob, glug, "Do it like this")

```yaml
id: paste-25
shape: prose-quantities
raw: |
  Mushroom risotto
  for 2
  You'll need
  a knob of butter
  a glug of olive oil
  1 banana shallot, finely chopped
  250 g chestnut mushrooms, sliced
  150 g risotto rice
  a small glass of white wine (about 100 ml)
  750 ml hot vegetable stock
  a good handful of grated parmesan
  Do it like this
  Melt the butter with the oil and sweat the shallot for 5 minutes.
  Add the mushrooms and cook until golden, 6-8 minutes.
  Stir in the rice for a minute, then the wine, and let it bubble away.
  Add the stock a ladle at a time, stirring, for 18-20 minutes until creamy.
  Off the heat, beat in the parmesan and rest 2 minutes.
expect:
  title: "Mushroom risotto"
  serves: 2
  ingredients:
    - {amount: 1, unit: knob, name: butter, raw: "a knob of butter"}   # new unit
    - {amount: 1, unit: glug, name: olive oil, raw: "a glug of olive oil"}   # new unit
    - {amount: 1, name: banana shallot, prep: finely chopped, raw: "1 banana shallot, finely chopped"}
    - {amount: 250, unit: g, name: chestnut mushrooms, prep: sliced, raw: "250 g chestnut mushrooms, sliced"}
    - {amount: 150, unit: g, name: risotto rice, raw: "150 g risotto rice"}
    - {amount: 100, unit: ml, name: white wine, prep: a small glass, raw: "a small glass of white wine (about 100 ml)"}
    - {amount: 750, unit: ml, name: vegetable stock, prep: hot, raw: "750 ml hot vegetable stock"}
    - {amount: 1, unit: handful, name: parmesan, prep: grated, raw: "a good handful of grated parmesan"}
  steps:
    - {text: "Melt the butter with the oil and sweat the shallot for 5 minutes.", durations: [[5, 5]], mentions: [butter], alsoMentions: [olive oil, banana shallot]}
    - {text: "Add the mushrooms and cook until golden, 6-8 minutes.", durations: [[6, 8]], mentions: [], alsoMentions: [chestnut mushrooms]}
    - {text: "Stir in the rice for a minute, then the wine, and let it bubble away.", durations: [[1, 1]], mentions: [], alsoMentions: [risotto rice, white wine]}
    - {text: "Add the stock a ladle at a time, stirring, for 18-20 minutes until creamy.", durations: [[18, 20]], mentions: [], alsoMentions: [vegetable stock]}
    - {text: "Off the heat, beat in the parmesan and rest 2 minutes.", durations: [[2, 2]], mentions: [parmesan]}
notes: >
  The worst case for headings: "You'll need" switches to ingredients, but "Do it like this" is not a known method
  heading, so all five steps are parsed as ingredients today (e.g. name "Melt the butter with the oil and sweat the
  shallot for 5 minutes."). Fix idea: in ingredients mode, a line that starts with a verb and ends with a full stop,
  or is longer than 10 words, flips to steps. "a knob of", "a glug of", "a small glass of" and "a good handful of"
  all fail. When the only measurable amount is in parentheses, use it.
```

### paste-26 Chia pudding (everything on one line)

```yaml
id: paste-26
shape: notes-one-line
raw: |
  Chia pudding: 3 tbsp chia seeds, 1 cup almond milk, 1 tsp maple syrup, pinch of cinnamon. Stir, wait 5 min, stir again, fridge 2 hrs or overnight. Top with berries.
expect:
  title: "Chia pudding"
  serves: null
  ingredients:
    - {amount: 3, unit: tbsp, name: chia seeds, raw: "3 tbsp chia seeds"}
    - {amount: 1, unit: cup, name: almond milk, raw: "1 cup almond milk"}
    - {amount: 1, unit: tsp, name: maple syrup, raw: "1 tsp maple syrup"}
    - {amount: 1, unit: pinch, name: cinnamon, raw: "pinch of cinnamon"}
  steps:
    - {text: "Stir, wait 5 min, stir again, fridge 2 hrs or overnight.", durations: [[5, 5], [120, 120]], mentions: []}
    - {text: "Top with berries.", durations: [], mentions: []}
notes: >
  How a quick note gets written. Today the single line becomes the title and `parse` returns nil (no ingredients or
  steps), so `CreateRecipe` throws. Minimum bar: never fail a paste; return the title and one step. Full bar: split
  on "Title:" and read the comma list up to the first full stop as ingredients. Here `raw` on an ingredient is the
  fragment, since the line is shared.
```

### paste-27 Easy hummus (numbered ingredients with full stops)

```yaml
id: paste-27
shape: blog-numbered-ingredients
raw: |
  Easy Hummus
  Ingredients:
  1. 1 can (400g) chickpeas, drained, liquid saved.
  2. 3 tbsp tahini.
  3. 1 garlic clove.
  4. Juice of 1 lemon.
  5. 2 tbsp olive oil, plus extra to serve.
  6. ½ tsp ground cumin.
  7. Salt.
  Directions:
  1. Blitz the chickpeas, tahini, garlic, lemon juice and cumin in a food processor for 1 minute.
  2. With the motor running, add 3-4 tbsp of the chickpea liquid until smooth and creamy, about 2 minutes more.
  3. Season with salt, spoon into a bowl and drizzle with the oil.
expect:
  title: "Easy Hummus"
  serves: null
  ingredients:
    - {amount: 1, unit: can, packSize: "400 g", name: chickpeas, prep: "drained, liquid saved", raw: "1. 1 can (400g) chickpeas, drained, liquid saved."}
    - {amount: 3, unit: tbsp, name: tahini, raw: "2. 3 tbsp tahini."}
    - {amount: 1, unit: clove, name: garlic, raw: "3. 1 garlic clove."}
    - {amount: 1, name: lemon, prep: juice, raw: "4. Juice of 1 lemon."}
    - {amount: 2, unit: tbsp, name: olive oil, prep: plus extra to serve, raw: "5. 2 tbsp olive oil, plus extra to serve."}
    - {amount: 0.5, unit: tsp, name: ground cumin, raw: "6. ½ tsp ground cumin."}
    - {name: Salt, raw: "7. Salt."}
  steps:
    - {text: "Blitz the chickpeas, tahini, garlic, lemon juice and cumin in a food processor for 1 minute.", durations: [[1, 1]], mentions: [chickpeas, tahini, garlic, lemon], alsoMentions: [ground cumin]}
    - {text: "With the motor running, add 3-4 tbsp of the chickpea liquid until smooth and creamy, about 2 minutes more.", durations: [[2, 2]], mentions: [chickpeas]}
    - {text: "Season with salt, spoon into a bowl and drizzle with the oil.", durations: [], mentions: [Salt], alsoMentions: [olive oil]}
notes: >
  In ingredients mode the list number is read as the amount: "1. 1 can ..." becomes amount 1 with the name ". 1 can
  chickpeas". Strip "N." / "N)" list markers in ingredients mode before reading the amount, and drop a trailing full
  stop. "Salt." keeps the stop today, so its key never matches "salt" in step 3. "3-4 tbsp" in a step is not a timer.
```

### paste-28 Crispy baked wings (no title)

```yaml
id: paste-28
shape: no-title
raw: |
  1 kg chicken wings, tips removed
  1 tbsp baking powder
  1 tsp salt
  80 g butter
  120 ml hot sauce
  1 tbsp honey
  Dry the wings really well, toss with the baking powder and salt and spread on a rack.
  Bake at 120C for 30 min, then turn up to 220C and bake 40-45 min more, turning halfway.
  Melt the butter with the hot sauce and honey, toss the wings and serve straight away.
expect:
  title: "Untitled recipe"
  serves: null
  ingredients:
    - {amount: 1, unit: kg, name: chicken wings, prep: tips removed, raw: "1 kg chicken wings, tips removed"}
    - {amount: 1, unit: tbsp, name: baking powder, raw: "1 tbsp baking powder"}
    - {amount: 1, unit: tsp, name: salt, raw: "1 tsp salt"}
    - {amount: 80, unit: g, name: butter, raw: "80 g butter"}
    - {amount: 120, unit: ml, name: hot sauce, raw: "120 ml hot sauce"}
    - {amount: 1, unit: tbsp, name: honey, raw: "1 tbsp honey"}
  steps:
    - {text: "Dry the wings really well, toss with the baking powder and salt and spread on a rack.", durations: [], mentions: [baking powder, salt], alsoMentions: [chicken wings]}
    - {text: "Bake at 120C for 30 min, then turn up to 220C and bake 40-45 min more, turning halfway.", durations: [[30, 30], [40, 45]], mentions: []}
    - {text: "Melt the butter with the hot sauce and honey, toss the wings and serve straight away.", durations: [], mentions: [butter, hot sauce, honey], alsoMentions: [chicken wings]}
notes: >
  Control: should pass today. A paste that starts with an amount has no title. The Paste screen should then ask for
  a name (Tess could offer "Chicken wings" from the first ingredient) rather than save "Untitled recipe" silently.
```

### paste-29 One-pan lemon orzo (Instagram caption, emoji)

```yaml
id: paste-29
shape: instagram-caption
raw: |
  🍋 ONE-PAN LEMON ORZO 🍋
  Ready in 25 minutes and only one pan to wash 🙌 Save this for later!!

  INGREDIENTS 👇
  ✨ 1 tbsp butter
  ✨ 1 shallot, minced
  ✨ 1 cup orzo
  ✨ 2 ½ cups chicken stock
  ✨ zest + juice of 1 lemon
  ✨ 2 handfuls spinach
  ✨ ⅓ cup parmesan

  HOW TO 👇
  1️⃣ Melt the butter and soften the shallot, 2 mins.
  2️⃣ Toast the orzo 1 min, then add the stock.
  3️⃣ Simmer 10-12 min, stirring often, till the orzo is tender.
  4️⃣ Stir in the lemon, spinach & parmesan. Done!!

  #orzo #onepot #easydinner #weeknightdinner
expect:
  title: "ONE-PAN LEMON ORZO"
  serves: null
  totalMinutes: 25
  ingredients:
    - {amount: 1, unit: tbsp, name: butter, raw: "✨ 1 tbsp butter"}
    - {amount: 1, name: shallot, prep: minced, raw: "✨ 1 shallot, minced"}
    - {amount: 1, unit: cup, name: orzo, raw: "✨ 1 cup orzo"}
    - {amount: 2.5, unit: cup, name: chicken stock, raw: "✨ 2 ½ cups chicken stock"}
    - {amount: 1, name: lemon, prep: zest + juice, raw: "✨ zest + juice of 1 lemon"}
    - {amount: 2, unit: handful, name: spinach, raw: "✨ 2 handfuls spinach"}
    - {amount: 0.333, unit: cup, name: parmesan, raw: "✨ ⅓ cup parmesan"}
  steps:
    - {text: "Melt the butter and soften the shallot, 2 mins.", durations: [[2, 2]], mentions: [butter, shallot]}
    - {text: "Toast the orzo 1 min, then add the stock.", durations: [[1, 1]], mentions: [orzo], alsoMentions: [chicken stock]}
    - {text: "Simmer 10-12 min, stirring often, till the orzo is tender.", durations: [[10, 12]], mentions: [orzo]}
    - {text: "Stir in the lemon, spinach & parmesan. Done!!", durations: [], mentions: [lemon, spinach, parmesan]}
notes: >
  Emoji everywhere: today the title keeps 🍋, "INGREDIENTS 👇" and "HOW TO 👇" are not headings, every ✨ line has no
  amount, keycap numerals (1️⃣) are not stripped, and the hashtag line becomes an ingredient. Strip emoji and
  symbols at line edges before anything else, treat "Ready in N minutes" as total time, and drop hashtag-only lines.
  Keep the title's case as written; the screen can soften all-caps.
```

### paste-30 Victoria sponge (UK and US dual units with slashes)

```yaml
id: paste-30
shape: metric-imperial-slash
raw: |
  Victoria sponge
  Cuts into 8 slices
  Prep: 20 minutes
  Bake: 20-25 minutes
  For the sponge
  200g/7oz caster sugar
  200g/7oz softened butter
  4 eggs, beaten
  200g/7oz self-raising flour
  1 tsp baking powder
  2 tbsp milk
  For the filling
  100g/3½oz butter, softened
  140g/5oz icing sugar, sifted
  170g jar good-quality strawberry jam
  Method
  Heat oven to 190C/170C fan/gas 5. Butter two 20cm sandwich tins and line with baking paper.
  Beat the sugar, butter, eggs, flour, baking powder and milk together until smooth, about 2 mins.
  Divide between the tins and bake for about 20 mins until golden and springy.
  Cool in the tins for 5 mins, then on a rack.
  Beat the butter and icing sugar for the filling until fluffy, then sandwich the cakes with it and the jam.
expect:
  title: "Victoria sponge"
  serves: 8
  activeMinutes: 20
  totalMinutes: 45
  ingredients:
    - {section: sponge, amount: 200, unit: g, name: caster sugar, raw: "200g/7oz caster sugar"}
    - {section: sponge, amount: 200, unit: g, name: butter, prep: softened, raw: "200g/7oz softened butter"}
    - {section: sponge, amount: 4, name: eggs, prep: beaten, raw: "4 eggs, beaten"}
    - {section: sponge, amount: 200, unit: g, name: self-raising flour, raw: "200g/7oz self-raising flour"}
    - {section: sponge, amount: 1, unit: tsp, name: baking powder, raw: "1 tsp baking powder"}
    - {section: sponge, amount: 2, unit: tbsp, name: milk, raw: "2 tbsp milk"}
    - {section: filling, amount: 100, unit: g, name: butter, prep: softened, raw: "100g/3½oz butter, softened"}
    - {section: filling, amount: 140, unit: g, name: icing sugar, prep: sifted, raw: "140g/5oz icing sugar, sifted"}
    - {section: filling, amount: 170, unit: g, name: strawberry jam, prep: good-quality, raw: "170g jar good-quality strawberry jam"}
  steps:
    - {text: "Heat oven to 190C/170C fan/gas 5. Butter two 20cm sandwich tins and line with baking paper.", durations: [], mentions: [butter]}
    - {text: "Beat the sugar, butter, eggs, flour, baking powder and milk together until smooth, about 2 mins.", durations: [[2, 2]], mentions: [butter, eggs, baking powder, milk], alsoMentions: [self-raising flour]}
    - {text: "Divide between the tins and bake for about 20 mins until golden and springy.", durations: [[20, 20]], mentions: []}
    - {text: "Cool in the tins for 5 mins, then on a rack.", durations: [[5, 5]], mentions: []}
    - {text: "Beat the butter and icing sugar for the filling until fluffy, then sandwich the cakes with it and the jam.", durations: [], mentions: [butter, icing sugar], alsoMentions: [strawberry jam]}
notes: >
  "200g/7oz" fails the unit lookahead (a slash follows "g"), so the name becomes "g/7oz caster sugar". "Cuts into 8
  slices" and "Bake: 20-25 minutes" become ingredients today. "Butter" as a verb in step 1 links butter; acceptable.
  "sugar" in step 2 is shared by caster and icing sugar, so no short-form link. Leading "softened" should be prep.
  Total is prep plus the top of the bake range.
```

### paste-31 Weeknight turkey chili (US blog card, lb, cans with pack sizes)

```yaml
id: paste-31
shape: us-blog-card-cans
raw: |
  Weeknight Turkey Chili
  Servings: 6
  Prep Time: 10 minutes
  Total Time: 45 minutes
  Ingredients
  1 tbsp olive oil
  1 lb ground turkey
  1 yellow onion, diced
  3 cloves garlic, minced
  2 (15 oz) cans kidney beans, drained and rinsed
  1 (14.5 oz) can fire-roasted diced tomatoes
  1 8 oz can tomato sauce
  2 tbsp chili powder
  ¾ tsp ground cumin
  1 cup low-sodium chicken broth
  ½ cup shredded cheddar, for topping
  Instructions
  Heat the oil in a large pot over medium-high heat. Add the turkey and onion and cook 6-8 minutes, breaking up the meat.
  Add the garlic, chili powder and cumin and cook 1 minute.
  Stir in the beans, tomatoes, tomato sauce and broth. Simmer 25-30 minutes.
  Serve topped with the cheddar.
expect:
  title: "Weeknight Turkey Chili"
  serves: 6
  activeMinutes: 10
  totalMinutes: 45
  ingredients:
    - {amount: 1, unit: tbsp, name: olive oil, raw: "1 tbsp olive oil"}   # passes today
    - {amount: 1, unit: lb, name: ground turkey, raw: "1 lb ground turkey"}   # new unit. FAILS today: no unit, name "lb ground turkey"
    - {amount: 1, name: yellow onion, prep: diced, raw: "1 yellow onion, diced"}   # passes today
    - {amount: 3, unit: clove, name: garlic, prep: minced, raw: "3 cloves garlic, minced"}   # passes today
    - {amount: 2, unit: can, packSize: "15 oz", name: kidney beans, prep: drained and rinsed, raw: "2 (15 oz) cans kidney beans, drained and rinsed"}   # FAILS today: no unit, name "cans kidney beans"
    - {amount: 1, unit: can, packSize: "14.5 oz", name: fire-roasted diced tomatoes, raw: "1 (14.5 oz) can fire-roasted diced tomatoes"}   # FAILS today: no unit, name "can fire-roasted diced tomatoes"
    - {amount: 1, unit: can, packSize: "8 oz", name: tomato sauce, raw: "1 8 oz can tomato sauce"}   # FAILS today: amount 1, no unit, name "8 oz can tomato sauce"
    - {amount: 2, unit: tbsp, name: chili powder, raw: "2 tbsp chili powder"}   # passes today
    - {amount: 0.75, unit: tsp, name: ground cumin, raw: "¾ tsp ground cumin"}   # passes today
    - {amount: 1, unit: cup, name: chicken broth, prep: low-sodium, raw: "1 cup low-sodium chicken broth"}   # amount and unit pass; name "low-sodium chicken broth" today (gap 8)
    - {amount: 0.5, unit: cup, name: cheddar, prep: "shredded, for topping", raw: "½ cup shredded cheddar, for topping"}   # amount and unit pass; name "shredded cheddar", prep "for topping" today (gap 8)
  steps:
    - {text: "Heat the oil in a large pot over medium-high heat. Add the turkey and onion and cook 6-8 minutes, breaking up the meat.", durations: [[6, 8]], mentions: [], alsoMentions: [olive oil, ground turkey, yellow onion]}
    - {text: "Add the garlic, chili powder and cumin and cook 1 minute.", durations: [[1, 1]], mentions: [garlic, chili powder], alsoMentions: [ground cumin]}
    - {text: "Stir in the beans, tomatoes, tomato sauce and broth. Simmer 25-30 minutes.", durations: [[25, 30]], mentions: [tomato sauce], alsoMentions: [kidney beans, chicken broth]}
    - {text: "Serve topped with the cheddar.", durations: [], mentions: [cheddar]}
notes: >
  The three US can shapes side by side: "2 (15 oz) cans", "1 (14.5 oz) can" and the no-parentheses "1 8 oz can".
  Today the unit regex (`Quantities.swift:135`) needs a letter right after the amount, so "(" and "8" both stop it,
  the parenthetical is dropped afterwards (`Quantities.swift:145`) and the pack word stays in the name. On
  Groceries that makes an ingredient called "Can fire-roasted diced tomatoes", which the aisle guide files under
  Produce (last word "tomato", `Aisles.swift:33`) instead of Cans and jars. "tomatoes" in step 3 is shared by the
  diced tomatoes and the tomato sauce, so no short-form link. "mentions: [tomato sauce]" and "[cheddar]" only work
  once the names are fixed.
```

### paste-32 TJ's sheet pan gnocchi (Notes, no headings, oz, pint, bag, half a stick)

```yaml
id: paste-32
shape: us-notes-pack-sizes
raw: |
  TJ's sheet pan gnocchi
  serves 3
  1 (12 oz) bag frozen cauliflower gnocchi
  2 (15 oz) cans chickpeas, drained and patted dry
  1 pint cherry tomatoes
  8 oz cremini mushrooms, halved
  1/2 stick butter, melted
  2 tbsp olive oil
  1 1/2 tsp italian seasoning
  4 oz goat cheese
  fresh basil to serve
  Toss everything except the cheese and basil on a sheet pan.
  Roast at 425°F for 20-25 min, flipping halfway.
  Crumble over the goat cheese and basil.
expect:
  title: "TJ's sheet pan gnocchi"
  serves: 3
  ingredients:
    - {amount: 1, unit: bag, packSize: "12 oz", name: frozen cauliflower gnocchi, raw: "1 (12 oz) bag frozen cauliflower gnocchi"}   # "bag" is new and not in Design's unit list (open). FAILS today: no unit, name "bag frozen cauliflower gnocchi"
    - {amount: 2, unit: can, packSize: "15 oz", name: chickpeas, prep: drained and patted dry, raw: "2 (15 oz) cans chickpeas, drained and patted dry"}   # FAILS today: no unit, name "cans chickpeas"
    - {amount: 1, unit: pint, name: cherry tomatoes, raw: "1 pint cherry tomatoes"}   # new unit. FAILS today: no unit, name "pint cherry tomatoes"
    - {amount: 8, unit: oz, name: cremini mushrooms, prep: halved, raw: "8 oz cremini mushrooms, halved"}   # new unit. FAILS today: no unit, name "oz cremini mushrooms"
    - {amount: 0.5, unit: stick, name: butter, prep: melted, raw: "1/2 stick butter, melted"}   # passes today
    - {amount: 2, unit: tbsp, name: olive oil, raw: "2 tbsp olive oil"}   # passes today
    - {amount: 1.5, unit: tsp, name: italian seasoning, raw: "1 1/2 tsp italian seasoning"}   # passes today
    - {amount: 4, unit: oz, name: goat cheese, raw: "4 oz goat cheese"}   # new unit. FAILS today: no unit, name "oz goat cheese"
    - {name: basil, prep: fresh, raw: "fresh basil to serve"}   # passes today ("to serve" is dropped, `Quantities.swift:111`)
  steps:
    - {text: "Toss everything except the cheese and basil on a sheet pan.", durations: [], mentions: [basil], alsoMentions: [goat cheese]}
    - {text: "Roast at 425°F for 20-25 min, flipping halfway.", durations: [[20, 25]], mentions: []}
    - {text: "Crumble over the goat cheese and basil.", durations: [], mentions: [goat cheese, basil]}
notes: >
  A Trader Joe's style Notes paste with no headings, so every line goes by its shape (`RecipeParser.swift:143`).
  "1 pint cherry tomatoes" is a dry pint, a basket, not 473 ml: the quick flip in Design's us-shop.md must not
  turn it into millilitres. The parser can't tell a dry pint from a liquid one, so the simplest rule is that a
  pint never flips. "bag" is how TJ's sells
  frozen gnocchi, but Design lists only can and stick as pack words; it's an open question for Design whether bag,
  jar and box join. "425°F" must stay in the step text as written and never start a timer.
```

### paste-33 Flaky buttermilk biscuits (cups, a stick, a split amount)

```yaml
id: paste-33
shape: us-cups-sticks
raw: |
  Flaky Buttermilk Biscuits
  Makes 8
  Ingredients
  2 cups all-purpose flour
  1 tbsp baking powder
  ½ tsp baking soda
  1 tsp kosher salt
  1 stick (8 tbsp) cold unsalted butter, cubed
  ¾ cup + 2 tbsp buttermilk
  2 tbsp butter, melted, for brushing
  Instructions
  Heat the oven to 450°F.
  Whisk the flour, baking powder, baking soda and salt. Cut in the cold butter until pea-sized.
  Stir in the buttermilk until just combined, pat to 1 inch thick and cut 8 biscuits.
  Bake 12-15 minutes, then brush with the melted butter.
expect:
  title: "Flaky Buttermilk Biscuits"
  serves: 8   # "Makes 8" reads as serves today; gap 13 proposes a separate makes field
  ingredients:
    - {amount: 2, unit: cup, name: all-purpose flour, raw: "2 cups all-purpose flour"}   # passes today
    - {amount: 1, unit: tbsp, name: baking powder, raw: "1 tbsp baking powder"}   # passes today
    - {amount: 0.5, unit: tsp, name: baking soda, raw: "½ tsp baking soda"}   # passes today
    - {amount: 1, unit: tsp, name: kosher salt, raw: "1 tsp kosher salt"}   # passes today
    - {amount: 1, unit: stick, name: unsalted butter, prep: "cold, cubed", raw: "1 stick (8 tbsp) cold unsalted butter, cubed"}   # amount and unit pass; name "cold unsalted butter" today (gap 8)
    - {amount: 0.75, unit: cup, name: buttermilk, raw: "¾ cup + 2 tbsp buttermilk"}   # FAILS today: 0.75 cup, name "+ 2 tbsp buttermilk"
    - {amount: 2, unit: tbsp, name: buttermilk, raw: "¾ cup + 2 tbsp buttermilk"}   # proposed second line; missing today
    - {amount: 2, unit: tbsp, name: butter, prep: "melted, for brushing", raw: "2 tbsp butter, melted, for brushing"}   # passes today
  steps:
    - {text: "Heat the oven to 450°F.", durations: [], mentions: []}
    - {text: "Whisk the flour, baking powder, baking soda and salt. Cut in the cold butter until pea-sized.", durations: [], mentions: [baking powder, baking soda, butter], alsoMentions: [all-purpose flour, kosher salt]}
    - {text: "Stir in the buttermilk until just combined, pat to 1 inch thick and cut 8 biscuits.", durations: [], mentions: [buttermilk]}
    - {text: "Bake 12-15 minutes, then brush with the melted butter.", durations: [[12, 15]], mentions: [butter]}
notes: >
  The US baking shape: cups and spoons, butter by the stick with its tablespoons in parentheses (dropped, as the
  convention says for a second system), and a split amount "¾ cup + 2 tbsp". The proposal writes the split as two
  lines with the same raw, the way several ingredients on one line are written, so Groceries shows
  "¾ cup + 2 tbsp buttermilk" by Design's merge rule and nothing is converted. "1 inch" must not read as a
  duration. "butter" in step 2 means the cold unsalted butter; linking the full-name "butter" line is acceptable.
```

### paste-34 Lemon ricotta pasta (Notes, fl oz, ⅓, "for 4")

```yaml
id: paste-34
shape: us-notes-fluid-ounces
raw: |
  lemon ricotta pasta
  for 4
  1 lb rigatoni
  1 cup whole milk ricotta
  ½ cup grated parmesan, plus more to serve
  1/4 cup (2 fl oz) pasta water
  4 fl oz heavy cream
  1 lemon, zested and juiced
  ⅓ cup toasted pine nuts
  ¼ tsp red pepper flakes
  6 oz baby spinach
  Boil the rigatoni 10-12 minutes, saving 1 cup of the cooking water.
  Stir the ricotta, parmesan, cream, lemon and pepper flakes in a big bowl.
  Toss in the hot pasta, spinach and a splash of pasta water until glossy. Top with the pine nuts.
expect:
  title: "lemon ricotta pasta"
  serves: 4
  ingredients:
    - {amount: 1, unit: lb, name: rigatoni, raw: "1 lb rigatoni"}   # new unit. FAILS today: no unit, name "lb rigatoni"
    - {amount: 1, unit: cup, name: whole milk ricotta, raw: "1 cup whole milk ricotta"}   # passes today
    - {amount: 0.5, unit: cup, name: parmesan, prep: "grated, plus more to serve", raw: "½ cup grated parmesan, plus more to serve"}   # amount and unit pass; today name "grated parmesan", prep "plus more" (gap 8, and "to serve" is cut)
    - {amount: 0.25, unit: cup, name: pasta water, raw: "1/4 cup (2 fl oz) pasta water"}   # passes today (the fl oz is in parentheses and dropped)
    - {amount: 4, unit: fl oz, name: heavy cream, raw: "4 fl oz heavy cream"}   # new unit, two words. FAILS today: no unit, name "fl oz heavy cream"
    - {amount: 1, name: lemon, prep: zested and juiced, raw: "1 lemon, zested and juiced"}   # passes today
    - {amount: 0.333, unit: cup, name: pine nuts, prep: toasted, raw: "⅓ cup toasted pine nuts"}   # amount and unit pass; name "toasted pine nuts" today (gap 8). Shows "0.33 cup" today, Design wants "⅓ cup"
    - {amount: 0.25, unit: tsp, name: red pepper flakes, raw: "¼ tsp red pepper flakes"}   # passes today
    - {amount: 6, unit: oz, name: baby spinach, raw: "6 oz baby spinach"}   # new unit. FAILS today: no unit, name "oz baby spinach"
  steps:
    - {text: "Boil the rigatoni 10-12 minutes, saving 1 cup of the cooking water.", durations: [[10, 12]], mentions: [rigatoni]}
    - {text: "Stir the ricotta, parmesan, cream, lemon and pepper flakes in a big bowl.", durations: [], mentions: [parmesan, lemon], alsoMentions: [whole milk ricotta, heavy cream, red pepper flakes]}
    - {text: "Toss in the hot pasta, spinach and a splash of pasta water until glossy. Top with the pine nuts.", durations: [], mentions: [pasta water, pine nuts], alsoMentions: [baby spinach]}
notes: >
  Fluid ounces both ways: inside parentheses (dropped, passes) and as the unit itself. The unit regex reads one
  word (`Quantities.swift:135`), so "fl oz" needs a two-word lookup; if Core only adds "oz", "4 fl oz" still
  fails, and if it strips "fl" the cream becomes 4 oz of weight, which Design forbids merging with oz. "⅓" parses
  (0.333) but `kitchenNumber` only draws ¼ ½ ¾ (`RecipeMath.swift:61-65`), so it reads "0.33 cup" on screen.
  "1 cup of the cooking water" in step 1 is not an ingredient. Mentions of rigatoni, parmesan and pine nuts work
  only once the names are fixed.
```

### paste-35 Sheet pan chicken and potatoes (lb, lbs, pound, 16oz, "1 lb 4 oz")

```yaml
id: paste-35
shape: us-weights
raw: |
  Sheet Pan Chicken and Potatoes
  Serves 4
  Ingredients
  1 1/2 lb boneless skinless chicken thighs
  2 lbs baby potatoes, halved
  1 pound green beans, trimmed
  16oz broccoli florets
  1 lb 4 oz butternut squash, cubed
  3 tbsp olive oil
  1 tsp garlic powder
  ½ tsp smoked paprika
  Instructions
  Heat the oven to 425°F.
  Toss everything with the oil and spices on two sheet pans.
  Roast 35-40 minutes, stirring once, until the chicken reaches 165°F.
expect:
  title: "Sheet Pan Chicken and Potatoes"
  serves: 4
  ingredients:
    - {amount: 1.5, unit: lb, name: chicken thighs, prep: "boneless, skinless", raw: "1 1/2 lb boneless skinless chicken thighs"}   # new unit. FAILS today: 1.5, no unit, name "lb boneless skinless chicken thighs"
    - {amount: 2, unit: lb, name: baby potatoes, prep: halved, raw: "2 lbs baby potatoes, halved"}   # FAILS today: no unit, name "lbs baby potatoes"
    - {amount: 1, unit: lb, name: green beans, prep: trimmed, raw: "1 pound green beans, trimmed"}   # FAILS today: no unit, name "pound green beans"
    - {amount: 16, unit: oz, name: broccoli florets, raw: "16oz broccoli florets"}   # FAILS today: 16, no unit, name "oz broccoli florets"
    - {amount: 1, unit: lb, name: butternut squash, prep: cubed, raw: "1 lb 4 oz butternut squash, cubed"}   # FAILS today: 1, no unit, name "lb 4 oz butternut squash"
    - {amount: 4, unit: oz, name: butternut squash, prep: cubed, raw: "1 lb 4 oz butternut squash, cubed"}   # proposed second line; missing today
    - {amount: 3, unit: tbsp, name: olive oil, raw: "3 tbsp olive oil"}   # passes today
    - {amount: 1, unit: tsp, name: garlic powder, raw: "1 tsp garlic powder"}   # passes today
    - {amount: 0.5, unit: tsp, name: smoked paprika, raw: "½ tsp smoked paprika"}   # passes today
  steps:
    - {text: "Heat the oven to 425°F.", durations: [], mentions: []}
    - {text: "Toss everything with the oil and spices on two sheet pans.", durations: [], mentions: [], alsoMentions: [olive oil]}
    - {text: "Roast 35-40 minutes, stirring once, until the chicken reaches 165°F.", durations: [[35, 40]], mentions: [], alsoMentions: [chicken thighs]}
notes: >
  Every way a US recipe writes a weight: "lb", "lbs", "pound", "16oz" attached, and the compound "1 lb 4 oz".
  "lb", "lbs", "pound" and "pounds" all read as `lb`; "oz", "ounce" and "ounces" as `oz`; attached forms already
  reach the unit check because the amount regex stops at the letters. The compound is written as two lines with
  the same raw (as paste-33's split cup), and on Groceries they roll to "1¼ lb" under Design's merge rule.
  "165°F" is a temperature, not a timer.
```

## Likely parser gaps on master (for Core)

Ordered by how many cases they break. Case numbers are `paste-NN`.

1. **Imperial and Indian units are missing.** No `oz`, `lb`, `pint`, `inch`, `c`/`c.`, `knob`, `glug`. Breaks 10, 11, 15, 19, 20, 25, 30. Slash duals ("200g/7oz", "250 g / 9 oz") fail the unit lookahead and leave the alternate in the name (11, 30).
2. **Can and pack sizes.** "1 (14 oz) can X", "1 (15-ounce) can", "2 x 400 g tins", "2 × 400g tins", "7g sachet", "170g jar" all end with the pack word in the name and no unit (3, 5, 11, 12, 23, 27, 30). Proposed `packSize`.
3. **Blog and social noise is read as recipe.** "Jump to Recipe" becomes the title; stories, bylines, "Print Recipe", Course/Cuisine/Calories/Author, Nutrition and Notes blocks, and hashtags become steps or ingredients; ▢, ✨, emoji and keycap numerals are not stripped (1, 2, 3, 18, 29). Strip edge symbols first; add an "ignore" class of lines.
4. **Unknown headings and section labels.** "Do it like this", "How to:", "INGREDIENTS 👇", "Tadka:", "To serve:", "For layering:", "*Dough*", "Notes", "Nutrition", and bare "Step 1" lines (5, 13, 15, 19, 21, 23, 25, 29). In paste-25 every step is stored as an ingredient. A short line ending in ":" or wrapped in `*` should be a section label; in ingredients mode a long or verb-first sentence should flip to steps. Sections are not kept (`ParsedRecipe` has no section).
5. **Durations with fractions or words.** `durations(in:)` does not clean unicode fractions: "1½ hours" gives nothing and "2½-3 hours" gives 3 hours; "1 1/2 hours" would give 2 hours. "half an hour" and "a minute" give nothing (11, 24, 25).
6. **Recipe card times.** Split label lines ("Prep Time" / "15 mins"), one-line "Prep | Cook | Total" (only prep read), "Prep 20 min · Cook 3½ hours" (no colon), "Bake:", "Ready in 25 minutes"; cook time is read and thrown away instead of feeding total (1, 2, 18, 24, 29, 30).
7. **Short-form mentions.** Mentions match the full ingredient key only, so "dal" never links toor dal, "oil" never links olive oil, "flour" never links plain flour. Most cases have at least one. And "salt & pepper" in a step links the sweet "peppers" (14).
8. **Leading prep words.** Only size words move to prep. Missing: chopped, melted, softened, soft, cold, packed, whole, thick, very ripe, full-fat (2, 9, 10, 12, 15, 21, 22, 30). These make new Ingredient objects that never merge on the grocery list.
9. **Name-first and article-free amounts.** "Atta - 2 cups", "sugar 1 tsp", "poha 2 cups - thick one", "handful peanuts", "pinch of hing", "Small bunch basil", "1 onion chopped" (no comma) (4, 5, 19).
10. **Indian "to taste".** "as per taste" and "swaad anusar" are not read; "2 tsp sugar, or to taste" leaves prep "or" (4, 15, 19, 20).
11. **"Juice of 1 lemon" and compound lines.** "Juice of", "zest + juice of", "saffron in 3 tbsp warm milk", "1 onion, 1 carrot and 1 celery stick", "2 tej patta, 4 laung, 4 elaichi", "salt & pepper" keep the whole phrase as one name (2, 11, 14, 21, 24, 27, 29).
12. **List markers and full stops in ingredients mode.** "1. 1 can ..." reads the list number as the amount; trailing full stops stay in names (27). U+2044 fraction slash ("1⁄2") is not converted (9).
13. **Serves and yield variants.** "Makes about 12", "yield: 24 cookies", "(makes 6)", "Cuts into 8 slices", a "(2 cups)" title suffix (9, 10, 19, 20, 30). Worth a separate `makes` field.
14. **No-heading short steps.** Short imperative lines without a full stop ("cover 2 mins on low") read as ingredients (4). A one-line paste returns nil and `CreateRecipe` throws (26).
15. **Not a timer.** Relative ("2 minutes less than the packet says", 5) and counts ("3 whistles", 15, 16) should not start timers. Whistles give none today, which is right; the relative one gives 2 min.

Passing today or nearly (controls): 7, 8, 16 (except mentions), 22 (except leading prep words), 28.

## US merge check (2026-10-16, master 620878b)

Design's merge rows from `docs/design/kitchen/us-shop.md` (commit 7ac3df3, "Merging on Groceries"), checked by reading `origin/master` at 620878b. Nothing was run (no Swift toolchain here). Where the request and Design differ, Design wins: Design keeps a volume and a weight of the same thing as **one row** joined with "+" ("1 lb + 2 cups spinach"), not two rows.

How master merges, in short. A grocery item is keyed by its **Ingredient object**, found by name (`Groceries.swift:147-150`, `Ingredients.swift:20-24`), and the name comes from `IngredientLine.parse`. Each item keeps a list of shares (amount and unit), and `GroceryShare.quantity` (`Groceries.swift:78-120`) adds grams with kilos, millilitres with litres, unitless counts together, and any other unit only with itself, then joins the groups with " + ". So for a US line the parse decides everything: `oz`, `lb`, `pint` and `fl oz` are not units (`Quantities.swift:5-8`, `37-51`), the unit regex reads one word that starts right after the amount (`Quantities.swift:135`), and the unknown word stays at the front of the name ("8 oz spaghetti" is 8 of an ingredient called "oz spaghetti").

| Rule (Design) | Example (typed on Groceries, or two recipes) | Today on master | Result | Evidence |
|---|---|---|---|---|
| (a) Same unit adds: ounces | "8 oz spaghetti" + "8 oz spaghetti" | One item called "oz spaghetti" with quantity "16" and no unit. A new Ingredient "Oz spaghetti" is made, apart from any "Spaghetti" | **FAIL** | No `oz` unit, `Quantities.swift:37-51`; unit regex `Quantities.swift:135`; unitless shares sum as a count, `Groceries.swift:92-94`, `111-112`; ingredient made from the name, `Ingredients.swift:29-38` |
| (a) Same unit adds: pounds | "1 lb ground turkey" + "1 lb ground turkey" | Item "lb ground turkey", quantity "2", no unit | **FAIL** | As above. "lbs" and "pound" fail the same way (paste-35) |
| (a) Cups add as cups | "1 cup rice" + "½ cup rice" | One item "rice", "1½ cups" | **PASS** | `.cup` goes to the per-unit group, `Groceries.swift:95-99`; drawn by `quantityText`, `RecipeMath.swift:46-56`, ½ glyph `RecipeMath.swift:58-68` |
| (a) Cans add as cans | "1 can coconut milk" + "1 can coconut milk" | One item "coconut milk", "2 cans" | **PASS** | "can"/"cans"/"tin"/"tins" are `.can`, `Quantities.swift:48`; per-unit group, `Groceries.swift:95-99` |
| (a) Cans with a pack size | "1 (13.5 oz) can coconut milk" + "1 can coconut milk" | Two items: "can coconut milk" (quantity "1") and "coconut milk" ("1 can"). "1 (14.5 oz) can diced tomatoes" also lands in Produce | **FAIL** | "(" stops the unit regex, `Quantities.swift:135`; parenthetical dropped after, `Quantities.swift:145`; aisle by last word "tomato", `Aisles.swift:28-35` |
| (a) Sticks add as sticks | "1 stick butter" + "½ stick butter" | One item "butter", "1½ sticks" | **PASS** | `.stick` exists, `Quantities.swift:49`; per-unit group, `Groceries.swift:95-99` |
| (b) Ounces roll into pounds from 16 oz | "8 oz spaghetti" + "8 oz spaghetti" should show "1 lb"; "12 oz" + "12 oz" should show "1½ lb" | "16" on "oz spaghetti"; no roll | **FAIL** | No oz or lb; the only rolls are grams to kilos and millilitres to litres at 1000, `Groceries.swift:103-110` |
| (c) Volume never merges with weight (metric weight and cups) | "200 g flour" + "1 cup flour" | One item "flour", "200 g + 1 cup". Nothing converted | **PASS** | Grams in the mass group, cups in their own, joined with " + ", `Groceries.swift:86-88`, `95-99`, `119` |
| (c) Volume never merges with weight (US) | "1 lb spinach" + "2 cups spinach" should be one row "1 lb + 2 cups spinach" | Two items: "lb spinach" ("1") and "spinach" ("2 cups"). Not converted, but split | **FAIL** (safe: no wrong sum) | Name "lb spinach" makes a second Ingredient, `Quantities.swift:135`, `Ingredients.swift:29-38`; item key is the ingredient, `Groceries.swift:147-150` |
| (c) Fluid ounces never merge with ounces of weight | "4 fl oz heavy cream" + "4 oz heavy cream" should be one row "4 fl oz + 4 oz heavy cream" | Two items: "fl oz heavy cream" ("4") and "oz heavy cream" ("4") | **FAIL** (safe: no wrong sum) | "fl" is not a unit and the regex reads one word, `Quantities.swift:135`; "fl oz" in parentheses ("1/4 cup (2 fl oz) pasta water") is dropped and passes, `Quantities.swift:145` |
| (c) Cups and millilitres stay apart | "1 cup milk" + "250 ml milk" | One item "milk", "250 ml + 1 cup". Not converted | **PASS** | Only ml and l join the volume group, `Groceries.swift:89-91`; cups stay in the per-unit group |
| (d) Metric never merges with US | "500 g ground beef" + "1 lb ground beef" should be one row "500 g + 1 lb" | Two items: "ground beef" ("500 g") and "lb ground beef" ("1") | **FAIL** (safe: no wrong sum) | As (c) US: the unknown "lb" stays in the name |
| Spoons stay apart | "1 tbsp cumin" + "1 tsp cumin" | One item "cumin", "1 tbsp + 1 tsp". Not converted | **PASS** | Each spoon is its own per-unit group, `Groceries.swift:95-99` |
| Fractions show as fractions (½ ⅓ ⅔ ¼ ¾ ⅛) | "⅓ cup pine nuts" + "⅓ cup pine nuts" | "0.67 cup"; a single "⅓ cup" shows "0.33 cup". ½, ¼ and ¾ (and "0.5 cup") show as glyphs | **FAIL** for ⅓ ⅔ ⅛; PASS for ½ ¼ ¾ | `kitchenNumber` knows only ¼ ½ ¾, `RecipeMath.swift:61-65`, else two decimals, `RecipeMath.swift:70` |
| "tin" and "tins" show as can | "1 tin chickpeas" + "1 can chickpeas" | One item "chickpeas", "2 cans" | **PASS** | `Quantities.swift:48`; drawn from the raw value "can", `RecipeMath.swift:52` |

### For Core

1. **Add the US units** (Design's gap 1): `oz` (oz, ounce, ounces) and `lb` (lb, lbs, pound, pounds) as mass, `fl oz` (fl oz, fl. oz, fluid ounce, fluid ounces) and `pint` (pint, pints, pt) as volume, and `quart` if Design keeps it. "fl oz" is two words, so the unit check after the amount must try a two-word unit before the one-word regex at `Quantities.swift:135`, or "4 fl oz" keeps failing. Every row marked FAIL above that is not about pack sizes or fractions comes from this one gap.
2. **Keep the US units out of the metric sums.** `GroceryShare.quantity` puts every `.gram`/`.kilogram` share into one gram total through `metricFactor` (`Groceries.swift:86-88`). If oz and lb get a `metricFactor` (for the quick flip) and join that case, "500 g + 1 lb" becomes "954 g", a conversion Design forbids. Give oz and lb their own group: add oz to oz, lb to lb, and oz with lb as ounces (16 oz to 1 lb), then show pounds from 16 oz. Fluid ounces get their own group too, never the ounce group.
3. **The roll needs a display rule for odd totals.** 16 oz is "1 lb" and 24 oz is "1½ lb", but 18 oz is 1.125 lb and `kitchenNumber` would draw "1.13 lb" (`RecipeMath.swift:70`). Proposal: roll to lb only when the total lands on a whole, ¼, ½ or ¾ pound, else keep ounces ("18 oz"). Design to confirm.
4. **Make the item one row for mixed systems.** Once the units parse, "1 lb spinach" and "2 cups spinach" share the Ingredient and become one row with " + ", as Design wants. No extra merge code is needed; the existing join at `Groceries.swift:119` already does it.
5. **Pack sizes** (gap 2): read "1 (14.5 oz) can X", "2 (15 oz) cans X" and "1 14.5 oz can X" into amount, `.can`, `packSize` and name. Open question for Design: do "1 can · 15 oz" and "1 can · 29 oz" of chickpeas add to "2 cans", or stay as "1 can · 15 oz + 1 can · 29 oz"? Adding them loses what to buy.
6. **Fraction glyphs:** extend `kitchenNumber` to ⅓ ⅔ ⅛ (and decide whether ⅜ ⅝ ⅞ show as glyphs or decimals).
7. **Rounding when a recipe is resized:** `RecipeMath.round` sends every unknown unit to whole numbers (`RecipeMath.swift:30-31`); the compiler will force a case for the new units. Proposal: oz to whole ounces, lb to a quarter, fl oz to whole, pint to a half.
8. **Split and compound amounts** ("¾ cup + 2 tbsp buttermilk", "1 lb 4 oz squash") are read as one amount today with the rest in the name. Proposal in paste-33 and paste-35: two lines with the same raw, which the merge then shows as Design wants.

## Design's answers (2026-10-16, `kitchen/us-kitchen-pages.md` §6, be98105)

Design settled the four questions above: bag, jar, box, bottle and carton are pack words beside can and stick; same-size cans add and different sizes stay separate rows; a pint stays a pint (only the recipe page's flip shows ml); "bucks" means USD (`money.md` row 62). Traced on `origin/master` at the commit this section landed on; `Quantities.swift` has the same unit table as `620878b` (`words`, can, tin and stick only; a parenthetical is dropped from the name).

| # | Line or pair | Target | Today on master | Status |
|---|---|---|---|---|
| U1 | `1 bag spinach (6 oz)` | {amount: 1, unit: bag, packSize: "6 oz", name: spinach} | amount 1, no unit, name "bag spinach"; the "(6 oz)" is dropped as a note (Quantities.swift, the parenthetical rule), so the pack size is lost | **FAIL** |
| U2 | `1 jar marinara (24 oz)` | {amount: 1, unit: jar, packSize: "24 oz", name: marinara} | as U1: name "jar marinara" | **FAIL** |
| U3 | `1 carton chicken broth (32 fl oz)` | {amount: 1, unit: carton, packSize: "32 fl oz", name: chicken broth} | as U1: name "carton chicken broth" | **FAIL** |
| U4 | `2 (15 oz) cans chickpeas` + `1 (15 oz) can chickpeas` | one row "3 (15 oz) cans chickpeas" | the unit regex stops at "(", so no unit; both names read "cans chickpeas" and "can chickpeas", so two rows, each with no unit | **FAIL** |
| U5 | `1 (14.5 oz) can diced tomatoes` + `1 (28 oz) can diced tomatoes` (mixed sizes) | two rows: "1 (14.5 oz) can" and "1 (28 oz) can", never "2 cans" | both read amount 1, no unit, name "can diced tomatoes" (the size is dropped), so the merge adds them to one row "2" with no unit and no size: **a wrong sum** | **FAIL (wrong merge)** |
| U6 | `1 can (14.5 oz) diced tomatoes` + `1 can (14.5 oz) diced tomatoes` | one row "2 (14.5 oz) cans diced tomatoes" | unit can, name "diced tomatoes", size dropped: "2 cans diced tomatoes". Right count, size lost | partial |
| U7 | `1 pint cherry tomatoes` | {amount: 1, unit: pint, name: cherry tomatoes}; never 473 ml on Groceries | no unit, name "pint cherry tomatoes" | **FAIL** |

**For Core.** U5 is the one wrong sum in the US rows: once pack size is read, it must be part of the merge key (same name, same unit, same pack size), and a size-less can never merges with a sized one. U1 to U3 need the five new pack words and the pack size read from either place, before the unit (`1 (6 oz) bag`) or after the name (`1 bag spinach (6 oz)`).
