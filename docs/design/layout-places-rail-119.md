# Item 119: the places rail on other screens

Kaushik, Oct 22: "use it on other screens and apps where it fits". The rail is the Pantry
drum (sheet 118 section 6): a left column of places you drag through, the open place's
rows on the right. Stills: mockups/drum-fit-119.png.

## When it fits (all four)
1. 3 to 8 parallel groups the person thinks of as places or kinds, each with a short name.
2. Each group is a plain list of one-line rows (name left, one number or time right).
3. He moves between groups often, and one group at a time is the right amount of page.
4. No photos and no drawings in the rows.

## When it does not
- One list (Today, Now): nothing to drag through.
- Live workout, cook mode: the page is one task; no rail.
- Review: already tabs.
- Groups with 2 or fewer, or more than 8: use plain sections.
- Rows that need the full width (a note's body, a recipe's steps): rail on the index only.

## Ranked (my pick first)
1. TRAINING > PLAN. Places = Push A, Pull A, Legs, Upper; right = the routine's exercises,
   Outfit kg numbers. Best fit: four to six routines, each a clean list, and he flips
   between them every session. Drag count rolls in the subtitle ("5 exercises").
2. NOTES. Places = Today, Ideas, Trip, Work (his notes grouped by what they are about);
   right = note titles with the first line. Needs the grouping to exist (note folders);
   until then the rail waits.
3. MONEY. Places = Spending, Bills, Saving, Cash; right = amounts. Fits visually; money
   never goes to Claude, so no Claude row here. Only after Money screens ship.
4. RECIPES only if it stays plain text (Saved, Cooked, To try; name left, time right).
   No photos in the rows, else it breaks rule 4.

## Same rules as the Pantry drum
Focus place 1.18, far 0.74, ink 100% to 34%, no blur. Right half slides 46 pt per place
and fades. One selection haptic per place passed. Spring snap, flick by velocity. Reduce
Motion and Low Power: 150 ms crossfade, tick kept. VoiceOver: adjustable, says the place
and its count. All motion through MotionPolicy. Left edge of the places = the 22 pt gutter.
One shared RailPage view builds all of them; each screen only supplies places and rows.

## Order
Builder B builds the rail inside Pantry first. When it is judged from real stills, lift it
to RailPage and give Builder A Training > Plan. Nothing else is built before then.

## 9. It is the template for hierarchical lists (Kaushik, Oct 22)
The dial rail is the standard template for any list with more than one level of
organisation. Three levels, always in this order:
1. PLACE (the dial, left): the top group. Fixed slots, loops, focus bigger.
2. SECTION (section word, right, small ink-secondary): the second group inside a place
   (Fresh, Dairy; Door, Shelves, Drawer). Plain words, no lines.
3. ROW: name left, one number or time right.
A pinned first place (To get, Inbox) sits above the dial in colour when one place is used
far more than the rest. A fourth level is a sheet on the row, never another column.
Build it once as RailPage (places, sections, rows in; selection and swipe actions out);
every screen with two or more levels uses it, and a plain list stays plain.
Layout is the dial of sheet 118 section 7, not the moving drum.

## 10. Variations by use case (same dial, different job)
Same three levels and the same dial; what changes is what the places are and what the
pinned place and the right half do.
- Pantry: places = Fridge, Freezer, Shelf, Counter; pinned = To get. Swipe moves an item
  between places. (built first)
- Training > Plan: places = routines; pinned = today's routine (hot colour, "Today").
  Sections = muscle groups; rows = exercises with the last weight. Swipe right on a row =
  swap it.
- Notes: places = what they are about; pinned = Today. Right half = titles with a first
  line; no sections.
- Money: places = Spending, Bills, Saving, Cash; pinned = the one that is due, with its
  amount. Sections = week; rows = amounts. No Claude row.
- Recipes: places = Saved, Cooked, To try; pinned = Tonight's recipe. Plain text only.
- Groceries by aisle (when it exists): places = aisles in the order he walks the shop;
  pinned = Needed now; rows tick off in place.
Each use case gets its own sheet when it is built; RailPage takes a pinned place, a
section style (words or none) and a swipe set as parameters, nothing else.

## 11. The pinned title as a second knob (Kaushik, Oct 22)
Where a list has one more dimension, the pinned word above the dial becomes a selector.
It picks WHICH set of places the dial turns through; the dial still picks the place.
- Gesture: swipe sideways on the pinned word, or tap it. The word slides out and the next
  slides in (MotionPolicy, 150 ms with Reduce Motion), the dial's places swap in place
  (labels cross-fade, slots do not move), one selection haptic. The next word shows
  faint to the right of the pinned word (ink 30%) so the knob can be found.
- Training: pinned = the routine (Push A, Pull A, Legs, Upper). Dial = that routine's
  muscle groups or exercises (Chest, Shoulders, Triceps); right half = the sets and last
  weights. Today's routine is the one it opens on, in the hot colour.
- Pantry: pinned = To get | Pantry. On To get the dial is the aisles; on Pantry it is the
  places (Fridge, Freezer, Shelf, Counter).
- Money: pinned = the month; dial = Spending, Bills, Saving, Cash.
- Use it only when the pinned word has 2 to 6 values; otherwise the pinned word stays a
  single pinned place as in section 9.
- VoiceOver: the pinned word is adjustable (swipe up and down), says "Routine, Push A".

## 12. Pinned place and knob as two independent things (Kaushik, Oct 22)
A page may have both: a pinned place (section 9) AND a knob (section 11). They do not
depend on each other.
- Pinned place: one place above the dial that is used most (To get, Today). Opens by tap.
- Knob: a separate word that picks the set of places the dial turns through. It sits on
  the title line under the page title, right side, ink-secondary, same sideways swipe.
- Both can be set at once: Training = pinned Today, knob = routine, dial = muscle groups.
  Pantry = pinned To get, knob = none, dial = places. Money = pinned Due, knob = month.
- A page uses neither, one, or both; RailPage takes each as an optional parameter.

## 13. What each knob is, per screen (draft for Kaushik)
Rule: the PINNED place is the one thing used most; the KNOB is a filter, range or kind
with 2 to 6 values and a default; the DIAL is the places. The knob choice is remembered per
screen. A knob never holds places and a place never holds a filter.
| Screen          | Pinned          | Knob (values)                      | Dial                     | Rows                         |
| Training Plan   | Today           | Routine (Push A, Pull A, Legs...)  | Muscle groups            | Exercises, last weight       |
| Training Log    | Best            | Range (Month, 3 months, Year)      | Exercises                | Sessions, weight x reps      |
| Pantry          | To get          | Show (All, Low, Soon)              | Fridge, Freezer, Shelf.. | Items, amount                |
| Groceries       | Now             | Shop (the shops he uses)           | Aisles in shop order     | Items, quantity              |
| Recipes         | Tonight         | Meal (Dinner, Lunch, Breakfast)    | Saved, Cooked, To try    | Recipes, time                |
| Money           | Due             | Month                              | Spending, Bills, Saving  | Amounts (never to Claude)    |
| Notes           | Today           | Kind (Notes, Lists, Links)         | Topics                   | Titles, first line           |
| Habits          | Today           | Range (Week, Month)                | Habits                   | Days done                    |
| Reading         | Now reading     | Year                               | Reading, Next, Done      | Books, pages                 |
| Body            | Latest          | Range (Month, 3 months, Year)      | Weight, Waist, Sleep     | Values (never to Claude)     |
| People          | Reach out       | none                               | Circles (Family, Friends)| People, last contact         |
Build order: Training Plan, Pantry, Groceries, Recipes (all four already have stills).
