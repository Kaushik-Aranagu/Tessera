# 75. Every screen has a side

**Kaushik's principle, in one line:** a screen is one unit, and every screen declares its own side: the other side of the same thing, one swipe away.

His words (Oct 16, 2:20 PM PT): "we'll have screen as… a logical definition of a unit, and every screen is associated with a side swipe… it gets to define its own side swipe… everything has its own… that's the design UI design architecture, the design principle". For now every screen has to have one. He wants every team asked and AI worked in.
- Board: `mockups/every-side.png`. Six sides, one of each kind, plus the kinds table.
- Recording: `recordings/every-side.mp4` (12 s, Porcelain). An ingredient turns to its PER 100 G, then a note turns to WHERE IT'S MENTIONED, with the same gesture and the same spine.
- Study: `studies/every-side.html`. Inventory: `screens-inventory.md` (29 built screens on master 73fa1a2, what each does on x today, and where sheet 71 and the code disagree).

This sheet replaces sheet 71's "which pages get a side page" and Product's 10:00 AM rule (decisions 2:24 PM). Sheet 71's gesture order and motion stand. Sheet 74 (THE DAY) is the first side under this rule.

## The rule
1. **A screen is a unit.** It has a **front**, the thing you came for, and a **side**, the other side of the same thing. The side is never another place. It's the same object, or the same view, turned over.
2. **Every screen declares exactly one side.** For now this is required: a screen without one fails review. An overlay isn't a screen (the capture veil, Speak, the running order, the swap panel). The screen under it keeps its side.
3. **The side has a kind** (below), a word, and a way-back word. The word sits at the right of the context line and names the side. On the side, the same place names the front.
4. **The way there** follows 71's order: the left edge is back, Tess's band is hers (a pan that starts at or below 736 is always hers, tess-picks 18b, so a side swipe starts above 736), and a row's own swipe stays the row's; otherwise a left swipe past 60 pt opens the side. The word always works. **The right edge always goes in** (76, `depth.md`): a pan that starts in the last 32 pt opens the side on every screen. When the screen is one of a run (paging by day or week, a routine's exercises), the middle goes along the run and the right edge is the way in. The live workout's exercise lane keeps x, and its side stays a peek (rule 7).
5. **The spine:** the back word and the title stay put, and only the body moves (71's motion). A page with a strip keeps its strip.
6. **No controls on a side.** A side holds facts and links, plus at most its own one key when the side is about acting on its facts (ADD 4 TO GROCERIES on INGREDIENTS). Settings and money keep every control on the front, and their side only explains.
7. **Live things don't leave their surface.** A live screen's side is a peek over it (69's INGREDIENTS during a cook), never a page that takes the live surface away.
8. **Every side ends with Tess's line** in her band: one fact the phone counted about this thing. A side with nothing worth saying leaves the band empty, and the line is never filler.

## The kinds
| Kind | What it holds | Example |
|---|---|---|
| FACTS | What the thing is, beyond the front | an ingredient's PER 100 G; an exercise's SETUP; what a backup holds |
| PARTS | What it's made of | a workout's sets; a recipe's INGREDIENTS; what a paste read |
| BEFORE | Its past | a routine's LAST TIMES; a task's story; a recipe's cooks |
| AHEAD | What comes next | THE DAY; Training's THE WEEK; a plan's weeks |
| LINKS | What it's tied to | where a note is mentioned, and what it mentions |

## Every built screen, and its side
| # | Screen | Side (kind) | How | Notes |
|---|---|---|---|---|
| 1, 2 | Today, and Plan my day (a state of it) | THE DAY (AHEAD), 74 | swipe or word | Row swipes keep finish and TOMORROW |
| 3 | A task | ITS STORY (BEFORE): made, moved, planned, linked | swipe or word | Drawn |
| 4 | Training tab | THE WEEK (AHEAD), 74 | swipe or word | |
| 5 | Routines | LAST TIMES per routine (BEFORE): one line each, "Push A, Thursday" | swipe or word | A swipe on a row stays DROP |
| 6 | A routine | LAST TIMES (BEFORE), 71 | swipe or word | The code has no row swipe here, so the page owns the swipe |
| 7 | Plans WEEK, MONTH | THE PLAN (FACTS): what it is, how it progresses | right edge or word | WEEK and MONTH are a run in the middle (76) |
| 8 | An exercise | HISTORY, REP MAXES, MUSCLES, SETUP: one side with four pages (76) | right edge or word | The middle goes along the routine's exercises. Drawn in 76 |
| 9 | A workout (finished or planned) | THE SETS (PARTS) | swipe or word | Becomes its own page, no longer the generic one. Drawn |
| 10 | Live workout | the running order, as it is now (AHEAD) | pull down, as built | Rule 7: it's already its side |
| 12 | Workout finish | THE SETS (PARTS) | word | Swipe down still drops into today |
| 13 | Kitchen tab | THE WEEK'S COOKS (AHEAD), 74: planned cooks by day, "N to buy" each | swipe or word | Pantry is its own area, with its own front and side (OUT AND LOW, drawn after a week of v1) |
| 14, 15 | Groceries, and at the shop | FOR WHAT (LINKS): each thing under the cook it's for | swipe or word; a peek at the shop | REMOVE (65) keeps the row swipe |
| 16 | A recipe | INGREDIENTS (PARTS), 69 | swipe or word | The ingredient column's send-to-Groceries swipe becomes the side's one key, ADD N TO GROCERIES, so the page owns the swipe |
| 17 | Recipe original | COOKS (BEFORE): each time cooked, how long | swipe or word | |
| 18 | An ingredient | PER 100 G (FACTS), and where it's used | swipe or word | His calorie example. Drawn |
| 19 | Paste a recipe | WHAT I READ (PARTS): every line, kept or ignored | swipe or word | |
| 20 | Review tab | THE DAYS (PARTS): this week's seven days, one line each (76) | right edge or word | The middle goes along the weeks (46). THE MONTH is dropped |
| 21 | The week (interim Settings) | WHAT LEAVES THE PHONE (FACTS): the last 30 days' Claude calls by job (sheet 80) | swipe or word | Controls stay on the front |
| 22 | Notes | BY THING (LINKS): notes grouped by what they mention | swipe or word | Private notes are counted, never named |
| 23 | A note | WHERE IT'S MENTIONED (LINKS) | swipe or word | Drawn. Its own links stay under the text |
| 24 | Claude receipts | BY JOB (FACTS): the month split by job | swipe or word | |
| 25 | Backups | WHAT'S IN ONE (FACTS) | swipe or word | Drawn. Restore stays on the front |
| 26 | A class page | ITS OBJECTS (PARTS) | swipe or word | |
| 27 | Any other object | **the default side**: LINKS plus every field the front doesn't show (FACTS) | swipe or word | Every new class gets a side for free, and a class can declare its own |

**Designed but not built:** each gets its side when it's built.
- Habits: HOW IT COUNTS (FACTS). Only this week shows, with no history (Product's rule).
- Body weight: HOW IT'S MEASURED (FACTS). It stays on the phone.
- Money: WHERE IT CAME FROM (LINKS), the receipts. Controls stay on the front.
- A book: YOUR NOTES (LINKS).
- A person: LAST TIMES (BEFORE).
- A chore: LAST TIMES (BEFORE).
- Day log: THE DAY, by the word and from the right edge (sheet 82, ruled 8:12 PM): the scrub owns the left 80 pt and the window scrolls on y only, so the right edge is free.
- Shutdown: TOMORROW (AHEAD), as a peek.

## Tess on the side (AI)
1. **Her line:** one line in the band on every side, computed by the phone ("You buy it about every 9 days.", "Moved twice, due today."). When "Tess asks Claude" is on, Claude may reword it, under Home's line caps and the AI-5 rubric. The rules line shows first, and Claude's words land wet and dry.
2. **Ask about this:** opening the ask slot on a side makes this thing the subject. "What can I swap this for?" on Bench press, or "Is this enough protein?" on Ground beef. The ask carries the object's id and class, never its private fields.
3. **Facts Claude may fill:** only public facts about a named thing, such as a food's nutrition or an exercise's muscles. They fill only when the phone's table has no row, are kept on the object with their source shown ("From Claude, Oct 16"), and are asked once. Without Claude, the side is complete without that row.
4. **Never:** a private note's words, money, or body facts reach Claude from a side. Every side goes through the walls (SecretWords, PrivateFacts) the same way the Bar does.

## For each team
- **Core:** a side is declared per screen. Two ways are proposed:
  - (a) `ViewDef` gains a `role` (front, side) and a `kind`, so a class declares its side as data, and the default object side comes from the class's fields and links;
  - (b) a `ScreenSide` protocol each Swift screen adopts, with the word, the kind, the content and Tess's line.
  
  One `SideHost` gives every screen the gesture, the spine and the motion once. A test fails any screen in the registry that doesn't declare a side.
- **Product:** board the rollout after the pins: the host and the default side first, then the screens by owner. Rule on Habits, Settings and money (the draft gives each a side that holds only facts).
- **Kitchen:** FOR WHAT, PER 100 G (the food table's source), COOKS, and PANTRY's place on the Kitchen tab.
- **AI architecture and Research:** Tess's side line (a job with caps, fixtures and an eval), ask-about-this, and when facts Claude may fill are allowed.
- **Motion lab:** one side motion for every screen, with Reduce Motion as a 150 ms crossfade (MotionPolicy).
- **Builders:** adopt it per screen as Product boards it. Builder A owns Training, the live workout and the looks. Builder B owns Home, Kitchen, Review, Notes and Settings.

## Two stops: the glance, then the full side (his ask, Oct 16, 2:33 PM PT)
"Half screen, which has more concise information… if we pull it further, we get more information."
- Board: `mockups/side-glance.png` (render `studies/every-side.html?glance`). Left to right: the front, stop 1, stop 2, and a note's glance. The recording `recordings/every-side.mp4` is now 21 s. It goes front, glance, full, glance, front, first on an ingredient and then on a note.
- **Stop 1, the glance:** a swipe past 60 pt that's let go before half the width settles here.
  - The glance takes the right half: from x 150, below the context line (186) to above Tess's band. Its left edge is a 34 pt fade into the ground, with no line and no card.
  - The front stays in place under it at 30%, so its left half still reads.
  - It holds the side's label, then the one number or name that matters at Hero 56 (with a unit at 21), then at most two more facts at Body 19. Its word sits at the foot: ALL FACTS (PER 100 G, Backups), ALL LINKS, ALL SETS, ALL DAYS, THE WHOLE STORY (a task), and ALL OF IT for a side with pages (Research BQ). Empty lines: "Not in a recipe yet." and "Nothing mentions it yet."
  - Lists in a glance follow the copy rule: a count first, then two or three named, and "and N more" from four.
- **Stop 2, the full side:** pull on past half the width, or tap the glance's word. The glance fades into the full side, and the front leaves as in 71.
- **Back:** a swipe right goes back one stop at a time. The left edge is still back to the page before (rule 4).
- **Motion:** each stop settles on the house spring over 380 ms, with no haptic for the glance and one `.selection` at the full side. Under Reduce Motion, each stop is a 150 ms crossfade (MotionPolicy).
- **Every side declares its glance:** what goes on it, by kind.
  - FACTS: the top number.
  - PARTS: the count and the top part.
  - BEFORE: the last time.
  - AHEAD: the next thing.
  - LINKS: the count and the names.
  - A side too small for two stops opens straight to the full side.
- **Tess's line** shows at both stops, and it's the same line.

## Rulings folded in (Oct 16, 2:45 PM PT)
- **Product (decisions 2:41):**
  - Habits, Settings and money get sides that hold facts only.
  - A side never shows a private fact its front hides, and nothing on a side goes to Claude except what rule 3 of Tess's part allows.
  - The recipe column swipe becomes INGREDIENTS' key.
  - From the SideHost PR (Core 0ak) on, any new or changed screen without a side fails review. Existing screens get theirs in rollout order: 0ak, then 74's tab sides, then the drawn ones, then the rest.
- **Kitchen** (`product/kitchen-sides-acceptance.md`):
  - **FOR WHAT** groups by cook, soonest first, with "Just because" and "Usually" groups. A row shared by two cooks shows once, with "also dal". Tess: "7 for 2 cooks, 3 just because."
  - **PER 100 G** comes from USDA FoodData Central (public domain), bundled, with the source shown. **Nothing ever sums these** (no totals per recipe, day or shop), because intake is a body fact. A Claude fill sends the ingredient key only, once per key, never for a private recipe and never with "Tess asks Claude" off, and NOT NOW is remembered.
  - **COOKS** lists one line per cook, newest first. Tess: "Cooked 4 times, about 45 min." (the median; empty under 2).
  - **INGREDIENTS'** key is ADD N TO GROCERIES with "Chicken, 7 added." and a 10 s UNDO, absent at 0.
  - **THE WEEK'S COOKS:** Tess says "3 cooks this week, 8 to buy."
- **Motion lab:**
  - Tess and her band hold still as the body moves; she's part of the spine.
  - She glances, eyes only: `sideTurned(direction)`, 0.4 toward the incoming content over 380 ms on the house spring, then back over 300 ms, with the mouth at 70%. It plays only on the move into stop 1 (right) and on the move that lands back on the front (left), never between stop 1 and stop 2. It plays only when she's idle or roaming, and never with eyes off, under Reduce Motion or in `.live`. It comes from the SideHost, not from each screen.
  - Her side line lands when stop 1 settles, at 420 ms (40 + 380).
  - There's no haptic for a side opening. Stop 2's `.selection` is the only tick.

## Every glance: one big fact and two small (for Research BD2's fixtures)
The big fact is Hero 56 with its unit at 21. The small facts are Body 19, at most two. Words follow copy-pass.

| Screen | Big fact | Small fact 1 | Small fact 2 |
|---|---|---|---|
| Today: THE DAY | "4" *to go* | "6 done" | the next thing: "Stretch, 8:30 pm" |
| A task: ITS STORY | "2" *moves* | "made Tuesday" | "in Plan my day" (or the linked thing) |
| Training: THE WEEK | "3" *of 6 sessions* | the next one: "Legs A, Saturday" | the last one: "Push A, today" |
| Routines: LAST TIMES | the routine done last: "Push A" | "today" | the next due: "Pull A, Tuesday" |
| A routine: LAST TIMES | the last day: "Thursday" | "5 of 5, 1,072 kg moved." | "4 times this month" |
| Plans: THE PLAN | "4" *days a week* | the split: "Push Pull Legs" | "on fixed days" |
| An exercise: HISTORY (76) | "82.5" *× 7* | "today, a best" | "about 102 kg for 1" |
| A workout or finish: THE SETS | "20" *sets* | the top set: "Bench 82.5 × 7" | "5 exercises" |
| Kitchen: THE WEEK'S COOKS | "3" *cooks* | the next, in Home's words: "Tacos tonight, 2 to buy." | "8 to buy" this week |
| Groceries: FOR WHAT | "7" *for 2 cooks* | the cooks: "Tacos and chili" | "3 just because" |
| A recipe: INGREDIENTS | "7" *to buy* | "4 on Groceries already" | the key: ADD 7 TO GROCERIES (one number in both places; at 0, "Nothing to buy." and no key) |
| Recipe original: COOKS | "4" *times* | the last: "Thursday, 46 min" | "about 45 min" |
| An ingredient: PER 100 G | "215" *kcal* | "18.6 g protein" | "15 g fat", with the source line under the glance ("USDA FoodData Central") |
| Paste: WHAT I READ | "14" *lines kept* | "3 ignored" | the source: "nytimes.com" |
| Review: THE DAYS (76) | "5" *of 7 days* | "Wednesday, 6 tasks" | "2 to go" |
| The week: WHAT LEAVES THE PHONE | "38 calls" *in 30 days* | "Today's lines, 21" | "Titles, counts, recipe text" (sheet 80) |
| Notes: BY THING | "23" *notes* | the top thing: "Landlord, 4" | "5 private" |
| A note: WHERE IT'S MENTIONED | "3" *places* | the first named | the second named, or "and N more" from four |
| Claude receipts: BY JOB | the top job: "Home lines" | "$1.10" | "21 calls" |
| Backups: WHAT'S IN ONE | "4 am" *last one* | "7 kept" | "Never your Claude key." |
| A class page: ITS OBJECTS | "38" *objects* | the newest | the most used |
| Any other object | its most-used field's value | its next field | "linked from N" |

Notes:
- **Money:** "$3.20" is the receipts' own Claude cost, already shown on The week, and isn't his money.
- **No sums of body facts:** the ingredient row is per 100 g of food, never his intake.
- **Private notes** are counted, never named.
- **Empty values:** a small fact with no value is left out. A glance with no big fact opens straight to the full side.

## Research's inventory check (#561, Oct 16, 2:55 PM PT)
- **Four more routes, same rule:** the pages inside the live workout's cover, the generic pages inside the Recipes cover, and Paste's second stack are the same screens as above, so each keeps its own side wherever it's pushed. A side opened inside a live cover follows rule 7 (a peek).
- **A private Tess memory on the generic object page:** the default side shows no private field and names nothing (Product 2:41: a side never shows a private fact its front hides).
- **Tess's lines** are in `docs/research/fixtures/side-lines.md`. One sentence each: "Moved twice, due today."
