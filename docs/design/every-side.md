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
4. **The way there** follows 71's order: the left edge is back, Tess's band is hers, and a row's own swipe stays the row's; otherwise a left swipe past 60 pt opens the side. The word always works. **When x is already taken** (sibling views on x, the live workout's exercise lane, paging by day or week), the word is the only way, and x keeps its job.
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
| 7 | Plans WEEK · MONTH | THE PLAN (FACTS): what it is, how it progresses | word only | x is the siblings |
| 8 | An exercise | YOUR SETUP (FACTS): his notes, the bar | word only | x is HISTORY · REP MAXES · MUSCLES. Drawn |
| 9 | A workout (finished or planned) | THE SETS (PARTS) | swipe or word | Becomes its own page, no longer the generic one. Drawn |
| 10 | Live workout | the running order, as it is now (AHEAD) | pull down, as built | Rule 7: it's already its side |
| 12 | Workout finish | THE SETS (PARTS) | word | Swipe down still drops into today |
| 13 | Kitchen tab | THE WEEK'S COOKS (AHEAD), 74; PANTRY later | swipe or word | |
| 14, 15 | Groceries, and at the shop | FOR WHAT (LINKS): each thing under the cook it's for | swipe or word; a peek at the shop | REMOVE (65) keeps the row swipe |
| 16 | A recipe | INGREDIENTS (PARTS), 69 | swipe or word | The ingredient column's send-to-Groceries swipe becomes the side's one key, ADD N TO GROCERIES, so the page owns the swipe |
| 17 | Recipe original | COOKS (BEFORE): each time cooked, how long | swipe or word | |
| 18 | An ingredient | PER 100 G (FACTS), and where it's used | swipe or word | His calorie example. Drawn |
| 19 | Paste a recipe | WHAT I READ (PARTS): every line, kept or ignored | swipe or word | |
| 20 | Review tab | THE MONTH (AHEAD and BEFORE): the weeks zoomed out | word only once x moves by week (46) | |
| 21 | The week (interim Settings) | WHAT LEAVES THE PHONE (FACTS): this month's Claude calls by job, titles and counts only | swipe or word | Controls stay on the front |
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
- Day log: THE DAY, by word, because x moves by day.
- Shutdown: TOMORROW (AHEAD), as a peek.

## Tess on the side (AI)
1. **Her line:** one line in the band on every side, computed by the phone ("You buy it about every 9 days.", "Moved twice. Today's the day."). When "Tess asks Claude" is on, Claude may reword it, under Home's line caps and the AI-5 rubric. The rules line shows first, and Claude's words land wet and dry.
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
- **Motion lab:** one side motion for every screen, with Reduce Motion as a 200 ms crossfade.
- **Builders:** adopt it per screen as Product boards it. Builder A owns Training, the live workout and the looks. Builder B owns Home, Kitchen, Review, Notes and Settings.

## Two stops: the glance, then the full side (his ask, Oct 16, 2:33 PM PT)
"Half screen, which has more concise information… if we pull it further, we get more information."
- Board: `mockups/side-glance.png` (render `studies/every-side.html?glance`). Left to right: the front, stop 1, stop 2, and a note's glance. The recording `recordings/every-side.mp4` is now 21 s. It goes front, glance, full, glance, front, first on an ingredient and then on a note.
- **Stop 1, the glance:** a swipe past 60 pt that's let go before half the width settles here.
  - The glance takes the right half: from x 150, below the context line (186) to above Tess's band. Its left edge is a 34 pt fade into the ground, with no line and no card.
  - The front stays in place under it at 30%, so its left half still reads.
  - It holds the side's label, then the one number or name that matters at Hero 56 (with a unit at 21), then at most two more facts at Body 19. Its word sits at the foot ("ALL FACTS", "ALL LINKS").
  - Lists in a glance follow the copy rule: a count first, then two or three named, and "and N more" from four.
- **Stop 2, the full side:** pull on past half the width, or tap the glance's word. The glance fades into the full side, and the front leaves as in 71.
- **Back:** a swipe right goes back one stop at a time. The left edge is still back to the page before (rule 4).
- **Motion:** each stop settles on the house spring over 380 ms, with no haptic for the glance and one `.selection` at the full side. Under Reduce Motion, each stop is a 200 ms crossfade.
- **Every side declares its glance:** what goes on it, by kind.
  - FACTS: the top number.
  - PARTS: the count and the top part.
  - BEFORE: the last time.
  - AHEAD: the next thing.
  - LINKS: the count and the names.
  - A side too small for two stops opens straight to the full side.
- **Tess's line** shows at both stops, and it's the same line.
