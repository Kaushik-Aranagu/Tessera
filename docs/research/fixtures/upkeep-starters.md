# Upkeep starter chores

For: Product (board item 19), Core (`TessGrammar+Upkeep.swift`, U1 and U4) and Builder B (Upkeep page, screen 6). Research lab. Date: 2026-10-15.

25 household chores for one person renting an apartment in the US, on Pacific time (the city is unknown, so no row depends on one), each with a default interval, the reason for it, the phrase that logs it and one alternative, the expected parse, and a check against the agreed M5 parse order. They are offered once, at first run, as a pick list. One more chore, Bleed the radiators (row 26), is not on the pick list: it is offered on its own, once, in October or November. Nothing here is seeded silently: a chore exists only if he picks it, accepts the offer, or later logs it with a phrase. All ten questions and the three radiator calls are closed below; nothing is left for Product.

Sources: `fixtures/upkeep.md`, `fixtures/m5-parse-order.md` (its final ordered rule list and guards are taken as built), `fixtures/grammar-misfires.md` (RC1, RC2, RC3, RC5), `../product/ship-list-m5-upkeep.md` (approved 19:11, the fixed verb list, decisions 1 to 7), `ship-list-m5-upkeep-draft.md`, `people-and-upkeep.md`, and `../product/decisions.md` (4:10 PM parse order, 4:26 PM sweep calls, 4:30 PM `buy`, 4:34 PM `paid`). Grammar facts are a hand trace of `TessGrammar.swift` ("G:") and `TessGrammar+Kitchen.swift` ("K:") on `origin/master` at `6cc61ec`. Both files last changed in `ae0d936`, so the line numbers in `m5-parse-order.md` and `upkeep.md` still hold. Nothing was run; there is no Swift toolchain here.

## Setup for the traces

**Order** (decisions.md 4:10 PM, with master's other rules kept in place, as `m5-parse-order.md` lists it): 1 note, 2 pasted recipe, 3 question guard, 4 process rule, 5 relative set, 6 reading, 7 money, 8 people, 9 comma sets, 10 named lift, 11 kitchen, 12 upkeep, 13 reschedule and the reschedule-shape stop, 14 task. Nil goes to the model.

**Upkeep guards used** (from `m5-parse-order.md` rule 12 and the 4:34 PM decision):
- `did X` only ticks an existing chore. It never creates one.
- `paid` plus an amount is Money's: a spend, plus DoChore on a matching existing chore in the same ghost row. `paid <chore>` with no amount stays upkeep.
- A day cue after a done verb is the most recent past day, today included. A plain verb with a day cue goes to the task rule.
- `<chore noun> out` binds only when the rest of the phrase resolves to an existing chore, and never with a day or time.
- No new chore when the object resolves to an ingredient, or when the phrase holds a currency mark or word.
- An open task that matches beats a new chore; if a chore and an open task both match, both happen in one ghost batch.
- New chores only from the fixed verb list: watered, cleaned, did, paid, changed, washed, emptied, took out, hoovered, vacuumed, mowed, descaled, dusted, mopped, swept, ironed, defrosted, topped up, fed.

**Clock and store.** Thu 15 Oct 2026, 18:00 in the phone's zone (America/Los_Angeles for him), as in `upkeep.md`. Amounts are dollars. *Product, 9:01 PM PT: starters still assume a London flat (council tax, hard London water, council recycling); Research 107 re-bases them on a US home.* Context idle. The store holds all 25 starters as if he picked every one, and Bleed the radiators as if he accepted the autumn offer, none logged yet, plus the open tasks "Clean the oven" and "Do the ironing" from the shared eval store. Rows that depend on a chore or task being there say so.

**Matching words.** `chore(named:)` (U1): exact name, then every word said is a whole word of the name, trailing "s" dropped, with articles (`the`, `a`, `my`, `our`) dropped first (`upkeep.md` row 3). The chore names below are written so that the object he says is inside the name ("Vacuum the apartment", not "Vacuum").

## The 25 starters

Grouped as the pick list shows them. "Off list" means the logging verb is not on the fixed U4 list (see proposed guard S2).

| # | Chore (name, verb) | Default interval | Why that interval |
|---|---|---|---|
| | **Kitchen** | | |
| 1 | Clean the kitchen (cleaned) | 7 days | Counters, stovetop and sink for one person cooking most nights get grim in about a week |
| 2 | Take out the trash (took out) | 4 days | A one-person kitchen trash can fills in a few days, and food waste smells before the week is out |
| 3 | Take out the recycling (took out) | 7 days | Cans, cartons and boxes build up slower than trash, and local pickup is usually weekly or every other week |
| 4 | Clean the fridge (cleaned) | 30 days | A monthly wipe-out is when the forgotten half-onion and old jars get found |
| 5 | Clean the oven (cleaned) | 90 days | Grease bakes on slowly; a deep clean each season is what most people actually manage |
| 6 | Defrost the freezer (defrosted) | 180 days | Ice builds up over months in a small freezer; twice a year keeps the drawers sliding |
| 7 | Descale the kettle (descaled) | 30 days | Scale builds up in a kettle used every day; monthly keeps it clear, and he can stretch it if his water is soft |
| 8 | Change the water filter (changed) | 30 days | Pitcher filter cartridges are rated for about four weeks |
| 9 | Clean the washing machine (cleaned) | 30 days | A monthly hot empty cycle and a detergent drawer rinse stop the musty smell |
| | **Rooms** | | |
| 10 | Vacuum the apartment (vacuumed) | 7 days | Dust and crumbs show on an apartment's floors within a week |
| 11 | Mop the floors (mopped) | 14 days | Hard floors in a kitchen and bathroom need it less often than vacuuming |
| 12 | Dust the apartment (dusted) | 14 days | Shelves and the TV stand look dusty after about two weeks |
| 13 | Clean the bathroom (cleaned) | 7 days | Toilet, sink and shower are the one room cleaning guides all put weekly |
| 14 | Descale the shower head (descaled) | 90 days | Mineral scale blocks the jets slowly; a few times a year keeps the spray even |
| 15 | Empty the vacuum (emptied) | 14 days | A bagless vacuum's bin fills after a couple of runs |
| | **Laundry and bed** | | |
| 16 | Laundry (did) | 7 days | One person makes about one load of clothes a week |
| 17 | Change the bed sheets (changed) | 14 days | Weekly is the textbook answer; every two weeks is what most people living alone do |
| 18 | Change the towels (changed) | 7 days | Bath towels stay damp in a small apartment and start to smell after a week |
| 19 | Iron shirts (ironed) | 7 days | A week's work shirts, done in one go |
| | **Plants** | | |
| 20 | Water the plants (watered) | 7 days | Most houseplants in a heated apartment dry out in about a week (the U4 fixture uses 7 too) |
| 21 | Feed the plants (fed) | 30 days | Liquid feed is usually monthly in spring and summer; he can pause it in winter |
| | **Bills and checks** | | |
| 22 | Pay rent (paid) | 30 days | Rent is monthly. Pick it only if he pays by hand, not on autopay |
| 23 | Pay the water bill (paid) | 30 days | Many renters pay water (often with sewer and trash) to the city or the landlord, monthly or every other month. Pick it only if he pays by hand. Same chore as `upkeep.md` row 40's "Pay water bill" (articles are ignored when matching) |
| 24 | Change the furnace filter (changed) | 90 days | Many apartments' furnace or AC units take a 1-inch filter rated for about 90 days. Pick it only if the unit is his to look after; some landlords change it |
| 25 | Test the smoke alarm (tested, off list) | 30 days | Fire departments say press the test button once a month |

Left out on purpose, as not a real thing for one person renting an apartment: mowing, gutters, the car, the garden, rotas, rooms as objects.

**Replaced for a US renter (Research 107).** Row 23 was Pay council tax, which renters in the US do not pay; it is now Pay the water bill, matching `upkeep.md` row 40. Row 24 was Send meter readings; it is now Change the furnace filter. Meter readings were the weakest starter for him: US utilities read the meter themselves (most by smart meter), so a renter has nothing to send, while a furnace or AC filter is a real recurring job in many US apartments. The `read the gas meter` trace stays below as a named phrase (model, never a book or a chore); S2 still has `tested` and `bled` to log, and S6 still covers `read`, `put`, `set` and `cut`. Rows 2, 10 and 15 use US names (trash, vacuum); the grammar evidence is unchanged in shape.

### Offered in autumn, not on the pick list

**Decided (Product, 9:01 PM PT):** offered once in October or November, never offered again if declined, and S7 taken. This confirms the 8:56 PM PT lean and replaces the 4:50 PM PT entry in `../product/decisions.md` that put Bleed the radiators under "more" on the pick list.

| # | Chore (name, verb) | Default interval | Why that interval |
|---|---|---|---|
| 26 | Bleed the radiators (bled, off list) | 365 days | Air collects in hot-water radiators over the summer while the heat is off; bleeding once, as the heat comes on, is the usual advice |

- **Why offered, not seeded.** Whether he has radiators at all is unknown. Many US apartments heat with forced air or electric baseboards, which need no bleeding, so the chore is asked about once and he can decline it.
- **Where it shows.** Not in the first 10 and not under "15 MORE". The pick list stays at 25 (10 plus 15 MORE, Design's `upkeep-people-first.md`). It is offered as its own Tess line, once.
- **When the offer shows.** The first time he opens the Upkeep page on a local date from 1 Oct to 30 Nov (his 4 AM day, phone's zone). If that open is the first run, the offer follows Keep N or SKIP, never on the same screen as the pick. On the fixture clock (Thu 15 Oct) it shows now. Outside the window nothing is offered; he can still say it once he has it.
- **Group.** Rooms, for the page's grouping once kept. It has no pick-list group because it is never on the list.
- **Accepting** writes one `AddChore(Bleed the radiators, bled, 365)` with no check-in, undoable, like a pick. It then reads "never logged" and does not drift to Now until the first log (closed question 2): the offer itself is the autumn nudge.
- **Due date rule.** After the first log, due is last log plus 365 days, a plain interval like every other chore. Logging it in autumn keeps it in autumn; there is no calendar anchor after the offer (4:50 PM PT: seasonal chores are plain intervals, paused by hand).
- **Declining** writes nothing, and it is never offered again (Product, 9:01 PM PT), as with the pick list and with deleted starters never being reinstalled.
- **Done word** is `bled`. It is off the fixed list, so it logs the chore only once it exists (S2) and can never create it.

## Phrases, parses and collision checks

"Logs it" is the main phrase; "Alt" is the alternative. The parse is the expected one under the agreed order. "Clear" in the collision column means the phrase was walked through all 14 rules and only upkeep binds.

| # | Logs it | Alt | Expected parse | Collision check against the agreed order |
|---|---|---|---|---|
| 1 | `cleaned the kitchen` | `cleaned kitchen` | DoChore(Clean the kitchen), 15 Oct | Clear. No numbers (no lift), no comma, kitchen rule (K:17) has no `buy`/`get`/`list:`/timer prefix and `parseCook` needs `cook`/`make` or a date (K:104). The word "kitchen" is not a kitchen-rule trigger |
| 2 | `took out the trash` | `trash out` | DoChore(Take out the trash) for both | Main: clear. Alt: upkeep's `<noun> out` form; "trash" resolves only to this chore (the recycling chore has no "trash"), so it binds. `trash out thu` and `trash out at 10` stay tasks (noun form never binds with a day or time; misfires row 99 and `upkeep.md` rows 8, 9 and 21 show the same shapes with "bins"). `took the trash out` needs the particle-last proposal (`upkeep.md` row 8). **Plain verb `take trash out`**: no date, so the task rule (G:369) needs a date and returns nil; model. `take trash out thu`: task "Take trash out", today 19:00. Never a check-in |
| 3 | `took out the recycling` | `recycling out` | DoChore(Take out the recycling) | Clear. `did the trash` must not tick this chore: "trash" is not a word of its name, so it does not |
| 4 | `cleaned the fridge` | `did the fridge` | DoChore(Clean the fridge) | Clear. Alt: `did` is no longer a question lead before "the" (rule 3); `did X` ticks the existing chore. Without the picked chore, `did the fridge` goes to the model, never a new chore. **Plain verb `clean the fridge`**: no date, model; `clean the fridge sat` is task "Clean the fridge", Sat 17 Oct 09:00. In a comma list (`clean the fridge, trash out`) `clean` is an errand verb (K:143), so kitchen passes and the phrase goes on; upkeep has no comma split, so the model gets it. `cleared out the fridge` (`cleared` off list) goes to the model |
| 5 | `cleaned the oven` | `did the oven` | DoChore(Clean the oven) **and** SetTaskDone("Clean the oven") in one ghost batch, because the open task also matches | Clear of other rules. This is the "both match" case from the U4 rules. If he did not pick the chore, it is SetTaskDone only, no new chore (U4 eval 9) |
| 6 | `defrosted the freezer` | `did the freezer` | DoChore(Defrost the freezer) | Clear. The ingredient guard is the one to watch: `defrosted the chicken` must make no chore (`upkeep.md` row 16). "freezer" is not an ingredient or aisle word (Aisles.swift lists "frozen pea" and so on, not "freezer") |
| 7 | `descaled the kettle` | `descaled kettle` | DoChore(Descale the kettle) | Clear. Bare `descaled` matches two chores (7 and 14): see guard S3. Spoken "de-scaled" misses the verb list (`upkeep.md` row 2) |
| 8 | `changed the water filter` | `changed water filter` | DoChore(Change the water filter) | Clear. `changed the filter` now matches this chore and row 24 by word and by verb: ambiguous ghost (S3). "water" is a staple in `AisleGuide.staples` but not in the aisle guide map, and kitchen sees no prefix or comma. The ingredient guard could fire if he has a recipe ingredient "water" and `find` matches "water filter" by word; it should match only the whole object. `water filter every 6 months` (`upkeep.md` row 27) is wrong for a pitcher filter; the default here is 30 days |
| 9 | `cleaned the washing machine` | `did the washing machine` | DoChore(Clean the washing machine) | Clear. "washing" is not "washed", so the Laundry chore is not touched. `did the washing` (laundry slang) has no chore with "washing" in reach except this one: it would tick Clean the washing machine by word, so the S4 family table maps it to Laundry (closed question 3) |
| 10 | `vacuumed` | `vacuumed the apartment` | DoChore(Vacuum the apartment) for both | Main has no object: binds by verb to the only chore whose verb is vacuumed (`upkeep.md` row 10 proposal, there with `hoovered`). **Trap:** `hoovered` is on the fixed list but is not this chore's verb, so alone it would make a new chore "Hoover"; the S4 family table logs it to Vacuum the apartment instead |
| 11 | `mopped the floors` | `mopped` | DoChore(Mop the floors) | Clear. `mopped the kitchen` makes a second chore "Mop the kitchen" ("kitchen" is not in "Mop the floors"); acceptable under closed question 3 ("How often?") |
| 12 | `dusted` | `dusted the apartment` | DoChore(Dust the apartment) | Clear, same verb-only binding as row 10 |
| 13 | `cleaned the bathroom` | `cleaned bathroom` | DoChore(Clean the bathroom) | Clear. `cleaned the bathroom wed` is a check-in on Wed 14 Oct (misfires row 14, RC2 makes the task rule pass it, upkeep takes it first) |
| 14 | `descaled the shower head` | `descaled the shower` | DoChore(Descale the shower head) | Clear. "shower" alone matches only this chore. Bare `descaled`: guard S3 |
| 15 | `emptied the vacuum` | `emptied the vacuum bin` | DoChore(Empty the vacuum) | **Collision inside upkeep.** "vacuum" is also a word of "Vacuum the apartment". Matching on words alone would tick the vacuuming chore. Guard S1 (the verb must match) sends it to Empty the vacuum. Alt: "bin" is not in "Empty the vacuum", so word matching fails and a new chore "Empty the vacuum bin" is made with "How often?" (closed question 3) |
| 16 | `did laundry` | `did the laundry` | DoChore(Laundry) | Rule 3 narrowing makes `did` a question lead only before `i`, `you`, `we`, `tess`. `did 2 loads of laundry` keeps "2 loads" as the note (lift fails, no reps). `did a wash` and `put a wash on` go to the model (`did X` never creates; `put` is not on the list, and the reschedule shape needs `to`/`till`/`until`). `washed clothes` makes a new chore "Wash clothes": see guard S4 |
| 17 | `changed the sheets` | `changed the bed` | DoChore(Change the bed sheets) for both | Clear; both words are in the name. **Plain verb `change bed sheets`**: no date, model; `change bed sheets sun` is task "Change bed sheets", Sun 18 Oct 09:00. `buy bed sheets` is a task under the 4:30 PM `buy` decision (clearly non-food), never Groceries and never a chore. `get new sheets` is still Groceries ["new sheets"] on master (K:155 three-word fallback); under closed question 10 it becomes a task. `washed the sheets` makes a new chore "Wash the sheets" under S1: see guard S4 |
| 18 | `changed the towels` | `changed towels` | DoChore(Change the towels) | Clear. `changed` is a very general verb: `changed my mind`, `changed the plan`, `changed the meeting to fri` would all make chores today. See guard S5 |
| 19 | `ironed shirts` | `did the ironing` | Main: DoChore(Iron shirts). Alt: SetTaskDone("Do the ironing") only | Main: clear. Alt: `did X` needs an existing chore; "ironing" is not a word of "Iron shirts" (no stemming), so no chore; the open task "Do the ironing" matches by every word and wins. Without that open task, alt goes to the model. `finished the ironing` stays with the model (`upkeep.md` row 39) |
| 20 | `watered the plants` | `watered plants` | DoChore(Water the plants) | Clear. U4 eval 1. **Plain verb `water plants`**: no date, every rule misses, model; `water plants sun` is task "Water plants", Sun 18 Oct (U4 eval 5). `watered plants sat` is Sat 10 Oct (misfires row 1, the 4:10 PM Core batch). `plants fine` and `plants every 10d` now match two chores (20 and 21): guard S3 |
| 21 | `fed the plants` | `fed plants` | DoChore(Feed the plants) | **Collision inside upkeep.** "plants" is a word of "Water the plants" too. Words alone would tick watering. Guard S1 picks Feed the plants by its verb. `fed` is on RC2's past-verb list, so with a day (`fed the plants sun`) the task rule passes and upkeep logs Sun 11 Oct. `feed the plants sun` stays a task (RC2's `feed` exception) |
| 22 | `paid rent` | `paid rent 1850` | Main: DoChore(Pay rent). Alt: LogSpend $1,850 (default currency, dollars), note "rent", **plus** DoChore(Pay rent) in one ghost row | Main: money (rule 7) needs an amount, so it passes; upkeep binds. Alt: money claims `paid <words> <amount>` (4:34 PM). `rent paid` is noun-first: DoChore(Pay rent) under closed question 4 (no amount, so money passes). `pay rent fri` is a task (money row 24). Spoken "paid rent eighteen fifty" must not become 18.50 (`upkeep.md` row 34, normaliser rule 8) |
| 23 | `paid the water bill` | `paid water bill 42.50` | Main: DoChore(Pay the water bill). Alt: LogSpend $42.50, note "water bill", plus DoChore(Pay the water bill) | Same as row 22. Alt is `upkeep.md` row 40's phrase; under 4:34 PM this replaces its "chore only". **Collision inside upkeep:** "water" is also a word of Water the plants and Change the water filter; S1 (verb `paid`) leaves only this chore. The ingredient guard must not fire on "water" (a staple word): the object is the whole "water bill". **Plain verb `pay the water bill`**: no date, model; `pay the water bill fri` is task "Pay the water bill", Fri 16 Oct 09:00. `pay` is an errand verb (K:143), so `pay the water bill, trash out` is not groceries. Without the picked chore, `paid the water bill` makes the chore "Pay the water bill" with "How often?"; with 42.50 it is a spend only, no new chore (no new chore when a currency or amount is in the phrase) |
| 24 | `changed the furnace filter` | `changed furnace filter` | DoChore(Change the furnace filter) | Clear of other rules: no numbers, no comma, no kitchen prefix; "furnace" is not an ingredient or aisle word. **Collision inside upkeep:** `changed the filter` matches this chore and row 8 by word and by verb, so S1 cannot split them: ambiguous ghost (S3). `changed the AC filter`: "AC" is not a word of the name, so it makes a new chore "Change the AC filter" with "How often?" (closed question 3). `changed` is general, so S5 applies. **Plain verb `change the furnace filter sat`**: task, Sat 17 Oct 09:00 |
| 25 | `tested the smoke alarm` | `smoke alarm fine` | Main: DoChore(Test the smoke alarm), only with guard S2. Alt: ChoreFine(Test the smoke alarm) | Main: `tested` is off list, so model without S2. RC2's `\p{L}{3,}ed` past-verb check makes the task rule pass `tested the smoke alarm sat`, so with S2 upkeep logs Sat 10 Oct. Alt: the fine form binds, and for this check chore "fine" counts as done (closed question 5), so it logs a check-in too. **Time-cue collision:** RC1's am cue list has `alarm`, so the plan `test the smoke alarm at 7` becomes 07:00 tomorrow, not 19:00 today. Propose: the am cue is `alarm` only after `wake`, `set` or `my` |
| 26 | `bled the radiators` | `bled radiators` | DoChore(Bleed the radiators), 15 Oct, for both, only once the offer is accepted (S2) | Clear: no numbers (no lift), no comma, no kitchen prefix, no contact verb, no amount. `bled` is off the fixed list, so S2 is the only way in. `bled the radiator` matches too (trailing "s" dropped). Without the chore: model, never a new chore |
| 26 | `radiators done` | | DoChore(Bleed the radiators), 15 Oct | Noun-first log (closed question 4): existing chore only, never with a day or time |

Count: 25 starters with 50 phrases, plus the offered row 26 with 3 phrases (53 in all). Rows 7, 8, 10, 14, 15, 16, 17, 18, 20, 21, 23, 24, 25 and 26 lean on a new guard from the list below (S1 to S7) for at least one of their phrases or near-misses. The `hoovered` trap in row 10 is a near-miss, not one of the 50. Every other phrase is clear once the `m5-parse-order.md` guards are in. The plain verbs with no day go to the model by design.

### Row 26 traps

| Phrase | Store | Expected parse | Why |
|---|---|---|---|
| `bled the radiators` | offer declined or not yet shown | Model. No chore | `bled` is not on the fixed list, so it never creates (Decision 6) |
| `radiators done` | offer declined | Model. No chore | Noun-first logs only an existing chore |
| `bleed the radiators` | any | Model | Plain verb, no day |
| `bleed the radiators sat` | any | Task "Bleed the radiators", Sat 17 Oct 09:00 | `bleed` is on RC2's exception list, so it stays a task, which is right |
| `bled the radiators sun` | chore kept | **Today: task "Bled the radiators", Sun 18 Oct 09:00 (misfire).** With S7: DoChore(Bleed the radiators), Sun 11 Oct | RC2's past-verb regex needs three letters before `-ed`, and `bled` is not on its irregular list, so the task rule takes it. S7 adds it |
| `radiators done sun` | chore kept | Task "Radiators done", Sun 18 Oct 09:00 | Noun-first never binds with a day, as `trash out thu` stays a task |
| `radiators fine` | chore kept | ChoreFine(Bleed the radiators), not done | Not a check chore, so Decision 4 holds (closed question 5) |
| `bled the brakes` | any | Model. No chore | No existing chore matches and `bled` cannot create |

## The six named phrases, traced

| Phrase | Trace | Result |
|---|---|---|
| `read the gas meter` | 1 to 5 miss. 6 reading: `read X`, X not a book, leading "the": pass. 7 money: M1 passes `read`. 8 people: no contact verb. 9 to 11 miss (no comma, no numbers, no kitchen prefix, no date). 12 upkeep: `read` not on the list. 13 no reschedule shape. 14 no date | Model. Never a book, never a new chore |
| `water plants` | All rules miss; the task rule needs a date (G:369) | Model. With a day, a task (U4 eval 5) |
| `change bed sheets` | Same as above; `change` is not a done verb | Model. With a day, a task |
| `clean the fridge` | Same. `clean` is an errand verb only inside comma lists | Model. With a day, a task |
| `take trash out` | Same. The noun-out form needs the phrase to start with the chore noun | Model. With a day, a task |
| `pay the water bill` | Money: no `paid`/`spent`, no amount first. Upkeep: `pay` is a plain verb | Model. With a day, a task (money row 23 shape) |

The model is fine for these: a plain verb with no day is usually a note to self, and the model can ask "Done, or a reminder?" Nothing in the grammar should guess.

## Proposed guards for upkeep (new, beyond `m5-parse-order.md`)

- **S1. A specific verb must match the chore's verb.** When the verb is not `did`, an existing chore matches only if its stored verb is the same verb. Without this, `fed the plants` ticks Water the plants and `emptied the vacuum` ticks Vacuum the apartment. `did X`, the noun-out form and the fine form match on words only.
- **S2. An existing chore's own verb logs it, even off the fixed list.** The fixed list (Decision 6) limits which verbs can create a chore. A picked starter brings its own verb (`tested`, and `bled` for row 26), and that verb should log that chore. Creation still uses the fixed list only.
- **S3. More than one match is an ambiguous ghost, not a guess.** Bare `descaled` (kettle or shower head), `changed the filter` (water or furnace), `plants fine` and `plants every 10d` (water or feed): the ghost row shows both and waits for a tap, with no 2 s commit, like `m5-parse-order.md`'s other ambiguous rows.
- **S4. Verb families for chores.** `hoovered` logs a `vacuumed` chore, `washed clothes` and `did a wash` log Laundry, `washed the sheets` logs Change the bed sheets, `emptied the trash` logs Take out the trash. Proposal: a short family table (vacuum/hoover, wash/launder, change/wash for sheets and towels, empty/take out for trash), checked only against existing chores, never to create one.
- **S5. `changed` creates nothing when it reads as a decision.** No new chore when the object is a word on a short list (`mind`, `plan`, `plans`, `password`, `name`, `job`) or when `to` or `into` follows the object (`changed the meeting to fri`). The second also stops a past day being read from what is really a reschedule.
- **S6. Same-spelling verbs never log with a day cue.** `read`, `put`, `set`, `cut`: with a day the phrase passes to the task rule; with no day it logs only an existing chore.
- **S7. Add `bled` to RC2's irregular past verbs** (`grammar-misfires.md` RC2), so `bled the radiators sun` is a check-in on Sun 11 Oct, not a task. `bleed` stays on the exception list. **Taken (Product, 9:01 PM PT).**

## The pick moment

At first run of Upkeep (the first time he opens the Upkeep page, not app launch), the page is empty and Tess's one cobalt line asks: "What do you keep up with? Pick any." Under it, the 25 starters stand in the page's own column as faint lines in the five groups above, each with its interval in small type ("every 7 days"). A tap darkens a line to full ink; a second tap lets it fade back. Nothing is written while he picks. Done writes one `AddChore(name, verb, interval)` per picked line in a single undoable batch, with no check-in, so each new chore reads "never logged" and does not drift to Now until he logs it once. Skip, or leaving the page, writes nothing, and the list is not shown again; he can still make any chore by saying it ("watered plants"). A starter he deletes later is never reinstalled, as with the starter lists. This keeps the setup cost (a quit reason in `people-and-upkeep.md`) to one optional screen.

For the look, follow the Upkeep page steer in `../../product/ship-list-m5-upkeep.md` (Design steers, screen 6: one typographic column, no checklist, no cards) and Design's `../../design/upkeep.mp4`. Closed: Design's `../../design/upkeep-people-first.md` sets the pick state (unpicked 400 `inkSecondary`, picked 600 `ink` with a 240 ms ink sweep from the left, no ticks or dots) and a "Keep N" stroke word that writes the batch.

## Questions (all closed)

Closures 1, 3, 4, 5, 7, 8, 9 and 10 are Product's 4:50 PM PT calls in `../product/decisions.md` ("Upkeep starter calls"). Upkeep code to cite: none yet. `origin/master` at `68ad34c` (Oct 15, 8:55 PM PT) has no `TessGrammar+Upkeep.swift` and no chore model, so these rows are the spec Core starts from.

1. **Closed (Product, 4:50 PM PT): take guards S1 to S6.** S7 (`bled`, from row 26) is taken too (Product, 9:01 PM PT). Was: **Guards S1 to S6.** Take all six? S1 and S3 fix real wrong ticks in this list (rows 15, 21, and the two-chore fine and interval rows). S2 decides whether rows 24 and 25 can be logged by the grammar at all.
2. **Closed (Design, `upkeep-people-first.md`): picked chores read "never logged" and do not drift to Now until the first log.** Was: **Never logged and drifting.** A picked chore has an interval but no check-in. Default proposed: it never drifts to Now until the first log, so the morning after first run is not 25 chores at age "never". Or should its age start from the day he picked it?
3. **Closed (Product, 4:50 PM PT): the default below.** A new chore only from the fixed list, with "How often?"; `did the washing` is Laundry through the S4 family table. Was: **Second chores from near-misses.** `mopped the kitchen`, `emptied the vacuum bin`, `did the washing`: make a new chore, tick the near one, or ask? Default proposed: a new chore only from the fixed list with "How often?" (as now), and `did the washing` goes in the S4 family table as Laundry rather than ticking Clean the washing machine.
4. **Closed (Product, 4:50 PM PT): yes.** A chore noun then its past verb or `done` logs an existing chore, never creates one, never with a day or time. So `rent paid` is DoChore(Pay rent) and `radiators done` logs row 26. Was: **Noun-first logs.** `rent paid`, `bins done`, `sheets changed`. Should a chore noun followed by its past verb (or `done`) log it, like the noun-out form, with the same "existing chore only, never with a date" limits?
5. **Closed (Product, 4:50 PM PT): "fine" counts as done for check chores.** Among the starters that is now Test the smoke alarm only (Send meter readings left the list, see row 24). Every other chore, Bleed the radiators included, keeps Decision 4. Was: **Smoke alarm: done or fine?** For a test, "smoke alarm fine" means the test was done. Should the fine form count as done for chores whose job is a check (alarm, meters), or keep Decision 4 for all chores?
6. **Closed (Design, `upkeep-people-first.md`): 10 starters show first in the five groups, and a "15 MORE" word unfolds the rest in place.** **Closed (Product, 9:01 PM PT): Bleed the radiators is not on the list.** It is row 26, a yearly chore (365 days, `bled`) offered once in the autumn window (1 Oct to 30 Nov), never seeded, and never offered again if declined; see "Offered in autumn". This replaces the 4:50 PM PT entry that put it under "more", and Design's 10 plus 15 MORE replaces that entry's "12 plus more"; the pick list stays at 25. Design's first-ten list uses the old names; read Take out the bins as Take out the trash, Hoover the flat as Vacuum the apartment, and Pay council tax as Pay the water bill (same rows, same intervals). Was: **The list itself.** 25 is long for one screen. Keep all 25 in five groups, or show the 12 most common (rows 1, 2, 10, 13, 16, 17, 20, 22 and four more) with "more" one tap away? Add Bleed the radiators (365 days, `bled`, off list)?
7. **Closed (Product, 4:50 PM PT): rent and council tax stay as starters he can skip.** For a US renter this reads as rent and the water bill (row 23). Was: **Bills paid by standing order.** Rent and council tax are usually automatic. Keep them as starters (only useful if he pays by hand), or move them to Money's recurring spends later?
8. **Closed (Product, 4:50 PM PT): plain intervals, paused by hand.** Feed the plants is plain 30 days; Bleed the radiators is plain 365 after its first log. No season field. Was: **Seasonal intervals.** Feed the plants is really "monthly in spring and summer". Use the existing pause, or a season field later? Default proposed: plain 30 days; he snoozes or pauses it.
9. **Closed (Product, 4:50 PM PT): `alarm` stops being an am cue** (all of it, wider than the narrowing proposed in row 25). `test the smoke alarm at 7` is 19:00 today. Was: **`alarm` as an am cue.** Narrow RC1's am cue so `test the smoke alarm at 7` reads 19:00 today?
10. **Closed (Product, 4:50 PM PT): `get new sheets` is a task**, under the 4:30 PM non-food rule, so the non-food check covers `get` as well as `buy`. Was: **`get new sheets`.** RC3's blockers keep it on Groceries. Is that right under the 4:30 PM spirit (household linen is not groceries), or should the non-food check cover `get` too?

## Swift Testing stubs

In `TesseraCore/Tests/TesseraCoreTests/`, beside `GrammarRulesTests`, with the clock and store above.

- `UpkeepStarterTests.starterListHas25ChoresWithIntervals()`
- `UpkeepStarterTests.noStarterIsSeededAtLaunch()`
- `UpkeepStarterTests.pickingWritesOneAddChorePerPickInOneUndoBatch()`
- `UpkeepStarterTests.pickedChoreHasNoCheckInAndReadsNeverLogged()`
- `UpkeepStarterTests.skipWritesNothingAndListIsNotShownAgain()`
- `UpkeepStarterTests.deletedStarterIsNeverReinstalled()`
- `UpkeepStarterTests.neverLoggedChoreDoesNotDriftToNow()`
- `UpkeepStarterGrammarTests.starterPhrasesLogTheirChore(_:)` (parameterized over the 50 starter phrases)
- `UpkeepStarterGrammarTests.plainVerbWithNoDayGoesToModel(_:)` (`water plants`, `change bed sheets`, `clean the fridge`, `take trash out`, `pay the water bill`)
- `UpkeepStarterGrammarTests.plainVerbWithDayIsTask(_:)` (the same five with a day)
- `UpkeepStarterGrammarTests.readTheGasMeterIsNotABookOrAChore()`
- `UpkeepStarterGrammarTests.paidWithAmountIsSpendPlusChoreTick()` (rows 22 and 23 alt)
- `UpkeepStarterGrammarTests.paidWithoutAmountTicksChoreOnly()`
- `UpkeepStarterGrammarTests.didOnlyTicksAnExistingChore()`
- `UpkeepStarterGrammarTests.fedThePlantsDoesNotTickWatering()`
- `UpkeepStarterGrammarTests.emptiedTheVacuumDoesNotTickVacuuming()`
- `UpkeepStarterGrammarTests.hooveredLogsTheVacuumChore()` (S4 family, no new chore "Hoover")
- `UpkeepStarterGrammarTests.changedTheFilterWithTwoFilterChoresIsAmbiguous()`
- `UpkeepStarterGrammarTests.paidWaterBillDoesNotTickWaterThePlants()`
- `UpkeepStarterGrammarTests.bareDescaledWithTwoChoresIsAmbiguous()`
- `UpkeepStarterGrammarTests.plantsFineWithTwoPlantChoresIsAmbiguous()`
- `UpkeepStarterGrammarTests.cleanedTheOvenTicksChoreAndCompletesTask()`
- `UpkeepStarterGrammarTests.didTheIroningCompletesTaskNotChore()`
- `UpkeepStarterGrammarTests.changedMyMindMakesNoChore()`
- `UpkeepStarterGrammarTests.changedTheMeetingToFriMakesNoChore()`
- `UpkeepStarterGrammarTests.offListVerbLogsItsOwnChore()` (`tested the smoke alarm`, `bled the radiators`)
- `UpkeepStarterGrammarTests.sameSpellingVerbWithDayIsTask()` (`read the meters sun`)
- `UpkeepStarterGrammarTests.testSmokeAlarmAt7IsEvening()`
- `UpkeepStarterGrammarTests.trashOutWithTimeIsTask()`
- `UpkeepStarterTests.radiatorsAreNotOnThePickList()` (the list is 25)
- `UpkeepStarterTests.radiatorsOfferShowsOnceFromOct1ToNov30()` (local date, phone's zone)
- `UpkeepStarterTests.declinedRadiatorsOfferIsNeverShownAgain()`
- `UpkeepStarterTests.acceptingRadiatorsWritesOneAddChoreWith365Days()`
- `UpkeepStarterGrammarTests.bledTheRadiatorsLogsOnlyAKeptChore(_:)` (`bled the radiators`, `bled radiators`, `radiators done`, and the same with the offer declined)
- `UpkeepStarterGrammarTests.bledWithDayIsCheckInNotTask()` (`bled the radiators sun`, with S7)
- `UpkeepStarterGrammarTests.bleedWithDayIsTask()` (`bleed the radiators sat`)
- `UpkeepStarterGrammarTests.nounFirstDoneLogsExistingChore()` (`rent paid`, `trash done`, `radiators done`)
- `UpkeepStarterGrammarTests.fineCountsAsDoneForCheckChores()` (`smoke alarm fine`)
