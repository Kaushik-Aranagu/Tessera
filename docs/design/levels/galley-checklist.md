# Galley, Level 1 and Level 2: what to build, from the board

Written Oct 28 for Builder B. There's no Galley levels branch yet: the app's Galley doors still open the old full pages (Recipes, Pantry, Groceries). The contract is sheet 284 (`docs/design/levels-284.md`). The board is https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp v112: open the Galley, turn the dial, tap a door, then tap a row.

**Update, later on Oct 28:** Builder A's `ios/deck-levels` (a08a8a3d) already puts the Galley in the root shell (`GalleyRoomContent`). It has five doors and keeps the rail at both levels. Its level 1 is still a plain `.list`, the nav word reads "Galley", the door title takes the room color, and there is no level 2. Everything below still applies on top of that.

## Reuse the Deck's kit

Builder A's `ios/deck-levels` already has the shared pieces: the shell's level 2 route, the page title with across, `RankedPage` (the rank weights 1.7, 1.3, 1.08, 1, 0.94, 0.88, 0.84 and the title sizes), `ItemPage` (facts 1.2 : 1 : 1 over the body) and the siblings body. Build the Galley on those. Don't draw rows of your own. The fixes on `docs/design/levels/deck-checklist.md` (the foot per level, Tess at every level, per-door captions, units, settle) apply here too, so pick them up once Builder A lands them in the kit.

## The frame

- Title "Galley" stays put. The nav word reads "Doors" at level 1 and the door's name at level 2
- The keystone (the ticket rail) stays live and untouched at every level, with the same identity, so it never animates
- The Door title is the door's name (34 pt bold ink) over its line (15 pt ink 2). Across goes to the next door, and only the words flap
- Foot at level 1: "Add" with "to {door}", then "Ask" with "Tess about {door}". At level 2, the item's own verbs. Tess stays bottom-right everywhere

## Each door (level 1)

The first row is bold, in the room color mixed 58% with ink. The others are ink unless a state applies: goes out today or low is wine, new is gold. Values are Outfit Light at 0.82 of the title size, with the unit at half the value's size. A sub line shows only on rows taller than 40 pt.

1. **Tonight**
   - Line: "Tacos, 25 min, you have all 8". Caption: "Swipe a ticket up for its next page"
   - Rows:
     - Tacos: "25 min, char the tortillas first", value "7:00" (when you eat). It opens the Tacos page
     - Rice: "Leftover, goes out today", value "side", wine
     - Dishes: "7 waiting since lunch", value "7"
   - Facts: tonight's dish comes from the plan's slot. The rice needs leftovers, which have no class yet (see Needs from Core). The dishes need the Sink (sheet 388, already with Core). Leave a row out until its fact exists, and never fake one
2. **Pantry**
   - Line: "31 things, milk and eggs low". Caption: "Tickets on the rail are what you can cook"
   - Rows: one per place, in his order (`PantryPlaces.places()`). For example, Fridge: "Milk and eggs low", value "12" (things there), wine when anything there is low. Then Freezer "Chicken, peas, bread" 7, Shelf "Rice, lentils, tortillas" 9, Counter "Limes, onions" 3
   - The sub names the low things first, else the first three things
3. **Recipes**
   - Line: "4 you can make now". Caption: "A ticket prints for each one you can make"
   - Rows: the recipes, the ones you can make now first. Each value is the total minutes, with "min" as its unit
   - The sub is "{minutes} min, all {n} things here", or "need eggs" when short, from `RecipeStock`. "Use the rice" appears when it uses a leftover
4. **Groceries**
   - Line: "3 to get on the way". Caption: "Swipe right on a thing when it is in the bag"
   - Rows: the things to get, from `Groceries`. The sub is the amount or what it's for ("The usual, 1 gallon", "For tacos"). The value is the count ("12" for a dozen eggs)
5. **Leftovers**
   - Line: "Eat the rice today". Caption: "Leftovers print on the left of the rail"
   - Rows: Rice "Goes out today", value "Today", wine. Then Dal "Cooked Thursday", value "Fri" (the day it goes out)
   - This whole door needs a leftovers model in Core. Until then, the door opens its Page with "Nothing here yet", and never a made-up row

## The Tacos page (level 2)

- Item title: "Tacos", line "Tonight, 25 min, serves 2"
- Facts: "25" with "min" (time), "8" (of 8 here), "2" (serves). The first number is in the room color
- Body, kind **steps** (new, next to `SetsBody` in the kit):
  - numbered steps, one per recipe step;
  - each number is Outfit Light 24/24 in ink 3, 22 pt wide, with 14 pt between number and text;
  - each step's text is Figtree 17/24 in ink 2, with 9 pt above and below;
  - the current step is ink, weight 500, and its number is in the room color, weight 400;
  - tapping a step makes it the current one;
  - recipe steps keep their full stops, like documents
- Foot: "Cook" with "start the 25 min", then "Swap" with "for dal" (the next recipe you can make)
- Every other row opens the siblings body (the door's rows with this one in the room color) until it has a page of its own

## Needs from Core

- **Leftovers:** a class (what, cooked on, goes out on, from which Cook). The Tonight and Leftovers doors need it. Nothing on the board is drawn from a guess
- **The Sink** (sheet 388, already sent): the Dishes row's "7 waiting since lunch"
- "You can make now" and "need eggs" come from `RecipeStock`, and the places and their counts from `PantryPlaces`. Both exist
