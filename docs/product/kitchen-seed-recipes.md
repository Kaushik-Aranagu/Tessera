# Kitchen seed recipes

*Kitchen lead, 2026-10-15. Ten everyday recipes, written in our own words, so the kitchen isn't empty on day one. Each block between the `text` fences is exactly what gets pasted into `CreateRecipe(text:)`: the title, "Serves", "Total time", an "Ingredients" heading, then a "Method" heading. They lean towards high-protein weeknight food to suit the training side. Install them as starter content (like the PPL plan), user-deletable and never reinstalled once deleted. They also make a parser test set: every line should read cleanly.*

```text
Chicken and broccoli stir-fry
Serves 2
Total time: 20 min
Ingredients
2 chicken breasts, sliced
1 head broccoli, cut into florets
1 red pepper, sliced
3 cloves garlic, sliced
1 tbsp ginger, grated
3 tbsp soy sauce
1 tbsp honey
1 tbsp sesame oil
150 g basmati rice
Method
Cook the rice in plenty of water for 12 minutes, then drain.
Heat the sesame oil in a wok and fry the chicken for 5 minutes until browned.
Add the broccoli, pepper, garlic and ginger and stir-fry for 4 minutes.
Stir in the soy sauce and honey, bubble for 1 minute and serve on the rice.
```

```text
Chilli con carne
Serves 4
Total time: 50 min
Ingredients
500 g beef mince
1 onion, chopped
2 cloves garlic, crushed
1 red pepper, diced
2 tsp chilli powder
1 tsp ground cumin
400 g chopped tomatoes
400 g kidney beans, drained
2 tbsp tomato puree
300 ml beef stock
Method
Brown the mince in a large pan for 8 minutes, then lift it out.
Soften the onion, garlic and pepper in the same pan for 5 minutes.
Stir in the chilli powder and cumin for 1 minute.
Return the mince, add the tomatoes, puree and stock and simmer for 30 minutes.
Add the kidney beans and simmer for 5 minutes more.
```

```text
Overnight oats
Serves 1
Total time: 5 min
Ingredients
60 g oats
150 ml milk
100 g greek yogurt
1 tbsp honey
80 g blueberries
Method
Stir the oats, milk, yogurt and honey together in a jar.
Cover and chill overnight.
Top with the blueberries in the morning.
```

```text
Shakshuka
Serves 2
Total time: 30 min
Ingredients
1 onion, sliced
1 red pepper, sliced
2 cloves garlic, sliced
1 tsp smoked paprika
1 tsp ground cumin
400 g chopped tomatoes
4 eggs
50 g feta, crumbled
a handful of parsley
Method
Soften the onion and pepper in a wide pan for 8 minutes.
Add the garlic, paprika and cumin and cook for 1 minute.
Pour in the tomatoes and simmer for 10 minutes until thick.
Make four hollows, crack in the eggs, cover and cook for 6 minutes.
Scatter over the feta and parsley.
```

```text
Salmon rice bowl
Serves 2
Total time: 25 min
Ingredients
2 salmon fillets
150 g basmati rice
1 avocado, sliced
1 cucumber, diced
2 spring onions, sliced
2 tbsp soy sauce
1 tsp sesame oil
1 lime
Method
Cook the rice for 12 minutes, then drain and keep warm.
Roast the salmon at 200C for 12 minutes.
Mix the soy sauce, sesame oil and the juice of the lime.
Flake the salmon over the rice with the avocado, cucumber and spring onions, then spoon over the dressing.
```

```text
Tomato and basil pasta
Serves 2
Total time: 20 min
Ingredients
200 g spaghetti
2 cloves garlic, sliced
400 g cherry tomatoes, halved
2 tbsp olive oil
30 g parmesan, grated
a handful of basil
Method
Boil the spaghetti for 10 minutes.
Warm the olive oil and garlic in a pan for 2 minutes.
Add the tomatoes and cook for 6 minutes until they collapse.
Toss with the drained pasta, parmesan and basil.
```

```text
Egg fried rice
Serves 2
Total time: 15 min
Ingredients
300 g cooked rice
3 eggs, beaten
150 g frozen peas
3 spring onions, sliced
2 tbsp soy sauce
1 tbsp vegetable oil
Method
Heat the oil in a wok and scramble the eggs for 1 minute, then push them aside.
Add the rice and peas and stir-fry for 4 minutes.
Stir in the soy sauce and spring onions.
```

```text
Chicken traybake
Serves 4
Total time: 50 min
Ingredients
8 chicken thighs
600 g potatoes, cut into chunks
2 red onions, cut into wedges
1 lemon, quartered
4 sprigs rosemary
2 tbsp olive oil
Method
Heat the oven to 200C.
Toss everything in a roasting tin with the olive oil.
Roast for 45 minutes, turning once, until the chicken is golden.
```

```text
Lentil soup
Serves 4
Total time: 40 min
Ingredients
200 g red lentils
1 onion, chopped
2 carrots, chopped
2 sticks celery, chopped
1 tsp ground cumin
1 l vegetable stock
1 lemon
Method
Soften the onion, carrots and celery for 8 minutes.
Add the cumin and lentils and stir for 1 minute.
Pour in the stock and simmer for 25 minutes.
Blend until smooth and finish with the juice of the lemon.
```

```text
Protein pancakes
Serves 1
Total time: 15 min
Ingredients
1 banana
2 eggs
40 g oats
30 g protein powder
100 g greek yogurt
50 g raspberries
Method
Blend the banana, eggs, oats and protein powder into a batter.
Cook small pancakes in a non-stick pan for 2 minutes a side.
Serve with the yogurt and raspberries.
```

## Parser notes from writing these

- "2 sticks celery" has no "stick" unit; it reads as amount 2, name "sticks celery". Add `stick` to `KitchenUnit`.
- "1 head broccoli" has the same issue: add `head`.
- "Roast at 200C for 12 minutes": only "12 minutes" should become a timer; "200C" must not. Worth a test.
- "300 g cooked rice" should link to the ingredient Rice with "cooked" as prep, the same rule as size words in acceptance fix 4.
