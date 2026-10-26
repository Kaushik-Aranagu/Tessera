# Upkeep and People on the new grammar (Design item 61)

**Kaushik's principle, in one line:** one plain line per thing, the detail one tap down, nothing cut and nothing decorated; a chore is a name and its age, a person is a name and when.

Redraws `upkeep.md`, `people.md` and `upkeep-people-first.md` (which keep the engine, Research's starters and fixtures, the never-lists and the ask) under sheet 41's one-line grammar, `no-dots.md`, the one-base rule, `empty-states.md` and `back-word.md` (rows 26 and 27). Upkeep keeps its one invention: **height is staleness.** Everything else that made these pages different goes.

- Board: `mockups/upkeep-people-grammar.png` (source `studies/upkeep-people-grammar.html`): Upkeep, a chore landing done, a chore one tap down (Obsidian), People, a person (Obsidian), the first-run pick.
- Recording: `recordings/upkeep-people-grammar.mp4` (12 s), Porcelain: hold Clean the bathroom (the line fills in sage over 0.6 s), it sinks to the foot on the settle spring with TODAY as its value and dries while Tess says "Clean the bathroom, done. Was 21 days, usually 14." with UNDO and the context line turns to "Thursday, all in time"; tap Water the plants, the chore grows out of its line; flick the drum from every 7 to every 10, the context line follows, "Water the plants, every 10 days." with UNDO; ‹ UPKEEP back, the plants line sits lower (6 of 10 now) and Pay rent makes room.

## Upkeep
| y | Element |
|---|---|
| 58 | **‹ REVIEW** (back-word.md row 26: Reading · Money · Upkeep · People on Review's second link line) |
| 84 | **Upkeep** in Title 44 |
| 146 | **Context line** in `context`, Body 21, at most 32 characters: "Thursday, 1 past its time", "Thursday, all in time", "Thursday, 2 past their time". Nothing else on the page is coloured at rest |
| 200 | **NOW** as a label word (Label 16/700, ink) on a hairline at 228 (1.5 pt, ink 12%). The hairline is staleness 1: a chore on it is at its usual interval |
| 244 to 580 | **One Body 21 line per chore, placed by staleness.** Staleness s = days since done ÷ usual interval; y = 244 + (1 − s) × 336, so a chore just done sits at the foot (580) and one at its interval sits on the hairline (244). Past 1 it stacks under the hairline, stalest first; at the foot it stacks upward. Lines never come closer than 46. The name in ink at the left, the age at the right as a value (Label 16/600 `inkSecondary`, tabular): "21 DAYS", "6 DAYS", "TODAY". **The age is the value; "usually" lives one tap down.** The age never turns red or amber; there is no bar, no weight change, no pale ink for the fresh ones |
| 630 | **NO RHYTHM YET** as a label word, then one line per never-logged chore in `inkSecondary` at 400, 32 apart (Laundry, Take out the trash). A chore leaves it with its first log and takes its place by staleness |
| 686 to 736 | The page fades over its last 50 pt (sheet 60's rule) so the band's ground is clear |
| 736 to 820 | **Tess's band.** Her line right 71, width 270, in `tess`; **UNDO** under it in `liveInk` for 10 s |

**Hold a name (0.6 s) to log it done:** the name fills in `health` left to right (background-clip, as the stroke word repaints), `.impact(medium, 0.8)` at the fill's end. Then the line **sinks to the foot on the settle spring** (`cubic-bezier(.3,1.3,.5,1)`, 760 ms); the foot chores close up 46 each (500 ms, the house curve); the age fades out at its old place and **TODAY** fades in at the foot; name and value dry from `health` to ink over 2 s. Tess: "Clean the bathroom, done. Was 21 days, usually 14." with UNDO (the thing first, then what happened, then the fact, Product 8e55cd9). The context line crossfades (blur 4, 180/380 ms) to its new count. UNDO lifts the line back up to its old place on the same spring, the age with it, and Tess says "Clean the bathroom, taken back."

**What goes:** the Title 34 names, the ink gradient from stale to fresh, the age line under each name, the two weights, the margin numerals, the seams, the "·" between "21 days" and "usually 14", the NOW label at 150 (day-seams.md S4 is closed by this frame: the label is a group word at 200, in the content). What stays: the never-list (no vermilion, no red, no filling bar, no "overdue", no dot), chores never run, the radiator ask of `upkeep-people-first.md` (it comes after KEEP or SKIP, under the context line as a Body 21 line with KEEP IT and NO RADIATORS as ink-line words), the VoiceOver order stalest first with "Clean the bathroom, 21 days, usually 14" as the line's label and done and fine as actions.

## A chore, one tap down
Grows out of its line (scale .94 → 1 from the line's left, 420 ms); ‹ UPKEEP is the reverse.

| y | Element |
|---|---|
| 58 | **‹ UPKEEP** (row 27) |
| 84 | **The name** in Title 44, wrapping to two lines if it must (the context line then sits at 200 and everything under it moves 54 down) |
| 146 | **Context line** in `context`: "descaled 25 days ago, usually every 60", "watered 6 days ago, usually every 7". Plain words, no " · " |
| 264 | **The day drum:** "every **60** days", the number at 96/300 tabular, the words at 34/300 in `inkSecondary`; the neighbours (59, 61) at 14% ink 78 above and below. A flick changes the interval (`.selection` per step); the context line follows on the settle (blur crossfade), Tess: "Descale the kettle, every 70 days." with UNDO. Reduce Motion: the drum steps |
| 456 | **THE LAST FEW TIMES** as a label word |
| 492 | **The rhythm as rules:** one 6 pt rule per past gap, 1.6 pt per day, 10 apart, ink 55%; the open gap as a 2 pt dashed rule at 38% (the data mark; `no-dots.md` rule 2) |
| 512 | Its label: "58, 62, 47 DAYS, 25 SO FAR" |
| 572 | **The verb as an ink-line word** (DESCALED, WATERED, PAID, CLEANED; a hold of 0.6 s logs it, the same fill and haptic as on the page) with **FINE** beside it as a plain label word (a tap says it is not due: the open gap resets, nothing is logged, Tess "Descale the kettle, fine for now." with UNDO) |
| 652 | **DELETE CHORE** as an ink-line word (a hold; Tess "Descale the kettle, deleted." with UNDO 10 s) |

Nothing else: no history list, no "next due" date, no streak. The rules are the history.

## People
| y | Element |
|---|---|
| 58 | **‹ REVIEW** (row 26) |
| 84 | **People** in Title 44 |
| 146 | **Context line:** "Mom's birthday Sunday", "Sam on Tuesday", "Nothing coming up" (≤ 32 characters; a birthday within 14 days beats the last talk) |
| 200 on | **One Body 21 line per person, most recently talked first, 40 apart.** The name in ink at the left; at the right the value: when. A birthday within 14 days wins ("BIRTHDAY SUN"); else the last talk, today's weekday within 7 days ("TUE"), then the date ("OCT 9", "SEP 20"). People never mentioned sit at the end in `inkSecondary` at 400 with no value. **Nobody fades for being quiet, and nothing counts the quiet** |
| 686 to 736 | The fade |

**What goes:** the paragraph of names, the margin birthday in Body ("Mom, Sun"), the 50% ink for the never-mentioned (it is `inkSecondary` now, the same as every quiet line in the app), avatars, circles, counts. What stays: `people.md`'s @ in the editors, aliases one level deeper, the long-press on a mention to say which Rosemary.

## A person, one tap down
| y | Element |
|---|---|
| 58 | **‹ PEOPLE** (row 27) |
| 84 | **The name** in Title 44 |
| 146 | **Context line:** "talked Tue, birthday **Mar 12**". The birthday is a value word in ink (tap to set; a wheel, `.selection` per step); "no birthday yet" when unset |
| 200 on | **Mentions, one per line under month words.** OCTOBER, SEPTEMBER as label words (32 under each the first line, 16 between months); each mention on one Body 21 line, the person's name in it at 600, the day at the right as the value ("OCT 13"). Contact lines ("Called Sam about the flat", "Lunch with Sam") in ink; plain mentions ("Asked Sam for a plumber", "Sam's book arrived") in `inkSecondary`. Newest first. A mention that will not fit its line wraps to 74 tall, the day on the first line |
| after the last month + 20 | **DELETE PERSON** as an ink-line word (a hold; Tess "Sam, deleted. The mentions stay in the log." with UNDO). Aliases sit above it one level deeper, as `people.md` draws them |

Tap a mention: the line fades and the day it came from opens, the mention set in weight (people.md). No edit on the person page; a mention is edited where it was written.

## First run: the pick
| y | Element |
|---|---|
| 146 | **Context line:** "First time here" |
| 200 on | **Research's starters under group words** (KITCHEN, ROOMS, LAUNDRY AND BED, PLANTS), one Body 21 line per starter with its usual interval as the value ("7 DAYS", "4 DAYS", "30 DAYS"). Unpicked in `inkSecondary` at 400; **tap to pick:** the ink sweeps in from the left (240 ms), the line goes to 600, a faint `neutral` wash blooms and dries. Tap again to unpick. "9 MORE" as a label word after the last group opens the rest |
| after the list + 60 | **KEEP 4** as an ink-line word at the right, counting live on the settle spring; **SKIP** as a plain label word at the left. KEEP writes one `AddChore` per pick in one undoable batch; Tess: "4 chores, kept. Tell me when you do one." with UNDO (thing first, replacing `upkeep-people-first.md`'s "Keeping 5."). SKIP opens the empty Upkeep ("No chores yet.", `empty-states.md`) |
| 736 to 820 | Tess, before any pick: "What do you keep up with? Pick any." |

The pick is a scrolling page with the fade; the board shows it scrolled to its end. The radiator ask comes only after KEEP or SKIP, never beside the pick.

## Empty
"No chores yet." and "No one yet." as one Body 21 line at 200 in `inkSecondary`, the frame otherwise the same (`empty-states.md`). The NOW hairline is not drawn until there is a chore. The first chore arrives at the foot (TODAY) or on the hairline if he says "I clean the bathroom every two weeks" (Core's call where it lands: default the hairline, so it asks to be done).

## Rules kept
1. **One base** per look; the Obsidian phones are the same frame.
2. **No dots, no seams, no rows.** NOW, NO RHYTHM YET, the months and the pick groups are label words; the only colours at rest are the context line and the rules on the chore page.
3. **Nothing cut.** A long name wraps its line (74 tall, the value on the first line); the context line is written to fit.
4. **Height is staleness, and only height.** No ink gradient, no weight, no colour says how late a chore is. The never-list stands: no vermilion, no red, no amber, no bar, no "overdue", no count of the quiet.
5. **Haptics,** one per moment: the hold's impact, `.selection` per drum step and per pick, nothing for the sink or the dry.
6. **Reduce Motion:** the fill is a 200 ms crossfade to `health`, the sink is a fade out and in at the foot, the drum steps, the pages crossfade.
7. **Tess's lines** name the thing first: "Clean the bathroom, done.", "Water the plants, every 10 days.", "Sam, deleted.", "4 chores, kept." Counts in her lines are unbreakable ("4&nbsp;chores").

## For Product (two copy calls)
- The done receipt "Clean the bathroom, done. Was 21 days, usually 14." replaces `upkeep-people-first.md`'s "Cleaned bathroom. Was 21 days, usually 14." (thing first, 8e55cd9).
- The pick's receipt "4 chores, kept. Tell me when you do one." replaces "Keeping 5. Tell me when you do one."
- The People value: a birthday within 14 days wins over the last talk ("BIRTHDAY SUN" on Mom's line even if he talked to her yesterday).

## For Builder B
- `Features/Upkeep/`: `UpkeepPage` as `ChoreLine`s placed by `staleness` between the NOW hairline (244) and the foot (580) with the 46 pt minimum and the upward stack at the foot; `NO RHYTHM YET` lines; the hold-to-log fill, sink and dry; `ChorePage` with the Title 44, the context line, the day drum, the rhythm rules, the verb and FINE as `InkLabelWord`s, `DELETE CHORE`; ‹ REVIEW and ‹ UPKEEP with `EdgeSwipeBack()`. The old `UpkeepPage` tiers, gradient and age lines go.
- `Features/People/`: `PeoplePage` as `PersonLine`s with the when value; `PersonPage` with the birthday value word, mentions under month labels, `DELETE PERSON`; ‹ REVIEW and ‹ PEOPLE.
- The first-run pick as a scrolling list of `StarterLine`s with the fade, KEEP N and SKIP.
- Every clip ends inside the app.
