# 241 Color roles, app-wide (his 11:53 PM Oct 23: "not monotonic", every screen)

The rule: every page uses 3-4 colors at once, and each one means something. Color goes on type and fine lines only (no fills, cards, pills or dots).

## 1. Who wears what
- **Room accent:** the room title, the primary action word, and the focused item when it has no kind.
- **Kind color:** a kind or category wears its own color on its name, its count, its focused items, its page title and its action word.
  - A kind that belongs to another room wears that room's accent (Shopping = Kitchen ochre, Body = Training blue, Watch and read = Notes violet).
  - Every other kind takes a color from the shared kinds set: teal, clay, gold, slate.
- **State colors**, the same in every room:
  - done, logged, paid, in stock, a gain: **go green**;
  - late, due, overdue, expiring, a warning: **wine**;
  - best, new, starred: **gold**;
  - planned, private, later, and small-caps labels: **slate**.
- **Ink and ink2** carry the text; ink3 is for rest and disabled.
- **Money exception:** in Money, done or paid uses the room's sage, not go green (the two are only ΔE00 5.3 apart in dark).

## 2. Tokens (light / dark)
Each token is checked on paper F7F5F1 and on pure black 000000. The script is in scratchpad c241/check.py.

| Token | Light | Dark | Contrast light | Contrast dark | Min ΔE76 from Ember |
|---|---|---|---|---|---|
| training | 0B62AE | 8FB0EE | 5.7 | 9.6 | 27 |
| kitchen | 93611A | C49A5E | 4.9 | 8.1 | 39 |
| lists | 5E6B1F | B5BE7A | 5.4 | 10.6 | 42 |
| routines | 8E4A78 | D59AC4 | 5.7 | 9.2 | 39 |
| notes | 5B3FB8 | B9A9E0 | 6.8 | 9.8 | 25 |
| money sage | 3F7A62 | 8DBFA7 | 4.6 | 10.1 | 69 |
| go | 25803D | 8FC9A0 | 4.6 | 11.0 | 64 |
| gold (NEW values) | 7E6A1E | D9C27A | 4.9 | 12.0 | 32 |
| slate | 34506F | A7BCD6 | 7.6 | 10.8 | 45 |
| wine | 9A2541 | EE8E9C | 7.1 | 9.0 | 25 |
| teal (new) | 1E6E77 | 84C3C9 | 5.4 | 10.6 | 61 |
| clay (new) | 9C4B2C | E2A07F | 5.6 | 9.6 | 48 |

- Every token reaches 4.5:1 or more in both themes.
- Ember is #3433D6 #D6266E #F2B21B / #9A98FF #FF5C9A #FFD24A. Every token sits ΔE76 25 or more away from it.
- Gold moved from 8A6A10/E2C26A to 7E6A1E/D9C27A to clear Ember gold under ΔE2000 too, and to sit further from Kitchen ochre.

## 3. Kinds palettes per room
- **Lists:**
  - All lists: olive (the accent);
  - Shopping: kitchen ochre;
  - Trips: teal;
  - Home: clay;
  - People: gold;
  - Watch and read: notes violet.
  - Lenses: Going takes the kind's color, Due soon wine, Done green, Halfway gold, All ink.
- **Notes:**
  - All: violet;
  - Ideas: gold;
  - Journal: clay;
  - Reading: teal;
  - Work: slate;
  - notes linked to a list: olive.
- **Routines:**
  - Mornings: gold;
  - Evenings: slate;
  - Body: training blue;
  - Home: clay;
  - Mind: teal;
  - Borrowed: each one wears its source room's accent.
- **Kitchen:**
  - Pantry: teal (on hand go, low wine);
  - Recipes: clay;
  - Shopping: ochre (the accent).
- **Training whats** (board v18):
  - Routines: go green;
  - Exercises: gold;
  - Programs: slate;
  - Goals: training blue.
  - This week: today is blue, done days green (with a green strike), planned days slate.
  - Gains are green; best and new are gold.
- **Money:**
  - Bills: clay;
  - Subscriptions: teal;
  - Income and paid: sage (the accent);
  - Savings: gold;
  - Late: wine.
  - No amounts are ever colored as good or bad.

## 4. Checks for every page
- Count the colors on screen: 3 or 4, never 1, never 5 or more.
- If a page reads in one color, give its kinds or states their role colors before adding anything new.
- Never color decoration. Only words, numbers and the one fine line a page is allowed.

## Boards
- Lists v8: https://claude.ai/artifact/9JBnr8TytGTnKtnnyXjdik
- Training v19: https://claude.ai/artifact/PFDdUde9cLtYA1G6Qjrpwp

## Big type (his 12:07 AM Oct 24)
"The large text grabs attention, and all of it in blue, looking the same, is the problem on any page."
- Rule: on any page, the 2-4 biggest type elements (title, hero name, stat numbers, focus word) never share one color. Each one takes the color of its meaning:
  - the title takes the room accent;
  - a hero name takes its kind or split;
  - a stat takes what it measures (streak gold, gains and done green, sessions ink);
  - a wheel's focus word takes its kind color.
- The action word may share the room accent with the title. They sit at opposite ends of the page.
- Vary weight and size between them too: e.g. a 600 title, a 200 light stat number, a 600 hero at a different size.
- QA check: screenshot the page, list its big-type elements, and fail it if two adjacent ones share a color.
- Training splits (new tokens), light / dark:
  - Push, clay 9C4B2C / E2A07F
  - Pull, teal 1E6E77 / 84C3C9
  - Legs, plum 8A4570 / D69CC0
  - All pass 4.5:1, are ΔE00 ≥ 11 from Ember, and are ≥ 25 from training blue.
- Training board v20 changes:
  - Landing: Push A in clay, the streak "5" in gold, +10 lb in green, Pull A in teal.
  - This week: today's row takes its split color.
  - Library: the focused routine takes its split; the what dial keeps its colors.
  - Plan page and Done page: Push A in clay.
  - Titles and action words stay blue.

## Lists kinds v9 (his 12:07 AM "combinations not good")
- The old set (ochre, clay, gold and olive together) read muddy. It's now one family:
  - Warm: the olive room accent and Kitchen ochre (Shopping).
  - Cool: Trips steel 2F6A8F / 8DBAD6, Home teal 1E6E77 / 84C3C9, Watch and read lavender 6A5E8C / B4A9D6.
  - Complement: People plum 8A4570 / D69CC0.
- Lists' small-caps labels go to ink2, because steel sits too close to slate. Slate stays only on "Private".
- "Halfway" is in ink, not gold.
- Note: Notes violet 5B3FB8 is only ΔE00 6.1 from Ember 3433D6 (CIE76 was used earlier). Flag it for the Notes round.
