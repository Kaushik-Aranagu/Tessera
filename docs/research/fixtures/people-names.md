# People names that are also words

For: Core engine (`TessGrammar+People.swift`, M5 People P5, plus the kitchen, money, reading and upkeep guards it touches). Research lab, board item 21. Date: 2026-10-16.

40 capture phrases that use a person's name which is also an ordinary word (Will, Rose, Mark, Bill, Sky, Basil, June, Honey, Sage, Olive, Ginger, May). Each row gives the parse on master now, the parse expected under the agreed M5 order, and a guard where a row could write a wrong person or a wrong grocery item.

## Sources and method

- **Code.** A static read of `origin/master` at `db049cb` (fetched 2026-10-16, "Merge pull request #154"). That includes the #153 hotfix (`82c51d9`: bare hours, passed times to tomorrow, past-tense logs as dated notes, non-food `get`/`buy` as tasks, questions, shop run). "G:" is `TessGrammar.swift` (which also holds `TessDates`), "K:" is `TessGrammar+Kitchen.swift`, "A:" is `TesseraCore/Kitchen/Aisles.swift`, "Q:" is `TesseraCore/Kitchen/Quantities.swift`, all at `db049cb`. There is no Swift toolchain here. Nothing was run; every result is a hand trace.
- **Order.** The agreed M5 order (`decisions.md`, 4:10 PM PT) with master's other rules kept in place, as listed in `m5-parse-order.md` ("The final ordered rule list"), and every guard that file proposes. Fixes it hands to `TessDates` (months, ordinals, `yesterday`, past mode) are taken as done.
- **Decisions applied.** 4:26 PM (bare hours; past logs as dated notes until Upkeep and People land), 4:30 PM (`buy` with a clearly non-food object is a task; unclear stays Groceries), 4:34 PM (`paid` plus an amount is Money), 4:41 PM (time forms), and the People ship list's Decisions 4 and 8.
- **People fixtures.** Also read: `people.md`, `people-and-upkeep.md`, `ship-list-m5-people.md`, and `grammar-misfires.md` rows 128 to 157 (Olive, Basil, Honey, Ginger, Candy, Pepper). Rows here do not repeat those.

**Clock.** Thu 15 Oct 2026, 18:00 Europe/London, the same as the other fixture files.

**Store.** The shared eval store from `m5-parse-order.md` (chores Water plants, Clean bathroom, Laundry, Pay rent, Take out the bins, Top up the oil; open tasks "Call mum", "Finish the report", "Clean the oven", "Do the ironing"; the book Dune), plus four people: **Will, Rose, Mark, Bill**. No person called Sky, Basil, June, Honey, Sage, Olive or Ginger. No recipe whose title holds any of these words. No exercise does either (checked `ExerciseSeed.swift`).

**Contexts.** I: idle. W: live workout, Bench Press in focus, last set 80 x 8. S: a shop run of Groceries is going.

**Facts about master that most rows depend on.**
- There is no people grammar and no Person class. A bare name links nothing; notes link `@Name` only.
- `TessDates` (G:458-647) has weekdays, `today`, `tonight`, `tomorrow`, `tmrw`, clock times and `at N`. `pastDay` (G:583) adds `yesterday`, `last night`, `this morning` for past logs only. No month names, no day numbers, no ordinals in `find`. So `may` and `june` are never dates on master.
- The #153 past-log rule (G:197-206) runs after lifts and before kitchen: a first word that is a past verb (G:185-194) plus a day gives a note dated that past day.
- A task needs a date or `todo`/`task`/`remind` (G:431). With neither, the phrase goes to the model.
- `buy`/`get` (K:40-57): a gift shape `<word> a|an|some <thing>` (K:164), a person word from a fixed family list (K:160), an errand verb, or a service word (K:167) makes a single item a task for Later. Anything else is Groceries. `get` also needs `isGettable` (K:180-187: 3 words or fewer, or food-like).
- At the shop (G:129-146), a phrase of 4 words or fewer with no date and no number goes on Groceries.
- The aisle guide (A:47-90) knows basil, rosemary, sage, ginger (produce), honey (dry goods) and olive (tins). It reads the last word of a longer name (A:27-35).

## Phrase rows

Columns: **Master now** is the trace on `db049cb`. **Expected** is the parse under the agreed order with the guards in `m5-parse-order.md` and the decisions above. **Guard** is the rule that stops a wrong person or a wrong grocery item; "none" when the row needs no new guard. **Person missing** says what changes if that name is not in his People list ("same" when nothing changes).

### Contact and social phrases

| # | Ctx | Phrase | Master now | Expected | Guard | Person missing |
|---|---|---|---|---|---|---|
| 1 | I | `coffee with will thu` | Task "Coffee with will", today 19:00, no link. Kitchen `parseCook` (K:104) finds no recipe; the task rule takes it; `thu` on a Thursday with no time is the next whole hour (G:562-566) | People social-noun form: task "Coffee with will", today 19:00, about [Will]. "Coffee with Will, today 7 PM." | None. `will` sits after `with`, so it is read as a name, never the modal | Will missing: the same task, not linked (as master). Never a new person |
| 2 | I | `call bill` | Model. No date, so the task rule misses (G:431) | People contact task: "Call bill", Later, about [Bill]. "Call Bill, in Later." | None | Bill missing: model, unchanged ("call priya" rule). Also covers "call (about the) bill" |
| 3 | I | `call will thu` | Task "Call will", today 19:00, no link | Task "Call will", today 19:00, about [Will] | None | Will missing: same task, not linked |
| 4 | I | `lunch with rose and mark sat` | Task "Lunch with rose and mark", Sat 17 Oct 09:00, no link. `sat` at the end counts as a day (K:191-199) | Task "Lunch with rose and mark", Sat 17 Oct 09:00, about [Rose, Mark]. No split on `and` inside a contact phrase | Social-noun guard: the names after `with` must be followed by nothing, a date, or `and <person>` | Mark (or Rose) missing: `and mark` is not `and <person>`, so people passes and it is a plain task with no links. No partial link, no new person |
| 5 | I | `drinks with sky at 9` | Task "Drinks with sky", today 21:00. `drinks` is a PM cue (G:477, G:535) | Same task, not linked. Sky is not a person, and a future social phrase never creates one | None | (Sky is not in the list.) If Sky is added: same task, about [Sky] |
| 6 | I | `dinner with basil fri` | Task "Dinner with basil", Fri 16 Oct 09:00, no link. Not groceries, not a cook | Same. Never Groceries ["basil"], never a cook task | People runs before kitchen (Decision 8: a contact phrase decides) | (Basil is not in the list.) If Basil is added: same task, about [Basil] |
| 7 | I | `saw rose yesterday` | Note "Saw rose", Wed 14 Oct 12:00, no link. #153 past log: `saw` is a past verb, `yesterday` from `pastDay` (G:591) | LogTalk([Rose], "Saw @Rose", Wed 14 Oct). Rose reads "talked Wed". "Saw Rose, Wed 14 Oct. Noted." | None with Rose | Rose missing: P5 offers the ambiguous ghost "New person: Rose?" or "Note: saw rose", waiting for a tap. Proposed: when the unknown name is typed lower case and is an ordinary word, put the note on top. Nothing is written before the tap either way |
| 8 | I | `called mark sat` | Note "Called mark", Sat 10 Oct 12:00, no link (past log, G:197) | LogTalk([Mark], "Called @Mark", Sat 10 Oct). No open "Call mark" task, so no completion | None with Mark | Mark missing: ambiguous ghost as row 7, note on top. Master's dated note is the right fallback |
| 9 | I | `texted will` | Model. The past log needs a day (G:200) | LogTalk([Will], "Texted @Will", now). "Texted Will. Noted." | None with Will | Will missing: ambiguous ghost "New person: Will?" or "Note: texted will", note on top |
| 10 | I | `see june at 7` | Task "See june", today 19:00. Bare 7 on today: 07:00 passed, 19:00 is next (G:541-552) | Same task, not linked | **Month guard:** a month word counts only with a day number right next to it. `june at 7` is not 7 June | (June is not in the list.) If June is added: same task, about [June] |
| 11 | I | `get will from the station` | Model. Four words, no food word, so `isGettable` fails (K:186) and kitchen returns nil (K:46-47); no date | People `get <person>` form: task "Get will from the station", Later, about [Will] | `get <person>` needs the person as the very next word | Will missing: model, as master (matches misfires row 150) |
| 12 | I | `get rose some flowers` | Task "Get rose some flowers", Later. Gift shape (K:164) | Same task, about [Rose] | None | Rose missing: same task, not linked (as master) |
| 13 | I | `get honey` | Groceries ["honey"] (honey is dry goods, A:70) | Groceries ["honey"] | **Bare `get <name>` guard:** `get <person>` binds only when something follows the name (a gift shape, `from`, `to`, `back`). A bare `get <name>` where the name is an ingredient stays kitchen | (Honey is not in the list.) If Honey is added (a pet name), without the guard people would make the task "Get honey" about Honey: a wrong person. With the guard: Groceries, same as now |

### Birthdays

| # | Ctx | Phrase | Master now | Expected | Guard | Person missing |
|---|---|---|---|---|---|---|
| 14 | I | `rose's birthday 12 may` | Model. The lift rule reads 12 as a weight with no reps (G:300); no months in `TessDates` | SetBirthday(Rose, 5, 12) and task "Rose's birthday" Wed 12 May 2027, about [Rose]. "Rose's birthday, 12 May. On your list for Wed 12 May." | `may` is a month only next to a day number | Rose missing: AddPerson("Rose") plus the same, one undo (Decision 4). A birthday phrase is one of the three ways a person is created |
| 15 | I | `june's birthday june 3` | Model (lift: 3 with no reps; no months) | AddPerson("June"), SetBirthday(June, 6, 3), task "June's birthday" Thu 3 Jun 2027 | **Possessive guard:** a word with `'s` is never a month. Only the second `june`, next to `3`, is the date | (June is not in the list.) If June is added: no AddPerson, the rest the same |
| 16 | I | `mark's birthday party sat` | Task "Mark's birthday party", Sat 17 Oct 09:00, no link | Same task, about [Mark]. Mark's birthday unchanged (a birthday needs a day and a month) | None | Mark missing: plain task, no link, no new person (no day and month) |

### Gifts, groceries and bare names

| # | Ctx | Phrase | Master now | Expected | Guard | Person missing |
|---|---|---|---|---|---|---|
| 17 | I | `buy rose a card` | Task "Buy rose a card", Later. Gift shape (K:164) | Same task, about [Rose]. Proposal: people's `get <person>` gift form also takes `buy <person> a/an/some X` (people does not claim `buy` today, so the link is a gap) | None | Rose missing: same task, not linked (as master) |
| 18 | I | `buy rose` | Groceries ["rose"] | Groceries ["rose"]. Tess names the list. No person link (Decision 8: `buy` without a contact phrase keeps its kitchen meaning; 4:30 PM: unclear stays Groceries) | Guard row: a bare `buy <name>` never links a person | Same |
| 19 | I | `buy flowers for rose` | **Groceries ["flowers for rose"]**. No gift, service or person word fires (K:158-177) | Task "Buy flowers for rose", Later, about [Rose] | **Gift guard (proposed in `m5-parse-order.md` for people 32):** after `buy`, an item that is not in the aisle guide or the ingredient book and is followed by `for <existing person>` is a gift, so a task | Rose missing: Groceries ["flowers for rose"], as master and misfires row 70 (`buy flowers for mum`): an unknown name leaves the object unclear, so Groceries stays |
| 20 | I | `buy basil for rose` | Groceries ["basil for rose"] | Groceries ["basil for rose"]. Never a task, never about Rose | Gift guard fires only when the item is not food. Basil is produce (A:52) | Same |
| 21 | I | `buy sage green paint` | **Groceries ["sage green paint"]**. No non-food word fires; the aisle guide misses (last word `paint`) | Task "Buy sage green paint", Later (4:30 PM: paint is clearly non-food) | **Non-food list:** add paint and DIY words (paint, brush, screws, bulb, batteries) to the K:167 list. Never let the first word (`sage`, an aisle word) decide | Same (Sage is not a person anyway) |
| 22 | I | `basil and tomatoes` | Model. No comma, so neither comma sets (G:74) nor the comma list (K:59) run; no prefix, no date | Proposal (gap): Groceries ["basil", "tomatoes"]. Today the model gets it, which is safe | **And-list guard:** a bare `X and Y` with no comma is groceries only when every item reads as food (RC8's `allSatisfy`), so `rose and mark` never is | Same. Even with a Basil person it stays groceries (Decision 8) |
| 23 | I | `basil, olive and rose` | **Groceries ["basil", "olive", "rose"]**. One food item is enough (K:146); `splitItems` splits on `and` (K:203) | Model. With RC8 (`allSatisfy`) "rose" is not food, so the list is not shopping | **Comma-list person guard:** an item that is exactly a person's name and not an ingredient blocks the list (pass to the model). Needed until RC8 lands; harmless after | Rose missing: model under RC8; before RC8, groceries with "rose" as a line, as master |
| 24 | S | `rose` | **Groceries ["rose"]** (G:141-146) | No write. "Rose? That's a person, not a grocery." | Shop guard from `m5-parse-order.md` step 4: a phrase that is exactly a person's name and not an ingredient is not a line | Rose missing: Groceries ["rose"], as master (could be roses, so fine) |
| 25 | S | `will` | **Groceries ["will"]** | No write. "Will? That's a person, not a grocery." | Shop guard as row 24. Proposed extra: a single function word (`will`, `may`, `can`, `should`, `must`, `so`, `ok then`) is never a line | Will missing: master writes Groceries ["will"], a wrong item. With the function-word guard: "Didn't catch that." |
| 26 | S | `ginger` | Groceries ["ginger"] (produce, A:48) | Groceries ["ginger"] | The shop guard skips only names that are not ingredients | Same. If Ginger is added as a person: still Groceries |

### Money and bills

| # | Ctx | Phrase | Master now | Expected | Guard | Person missing |
|---|---|---|---|---|---|---|
| 27 | I | `pay the bill` | Model. `pay` is a plain verb; no date | Model. Money: no amount, pass. People: `pay` is not a contact verb. Upkeep: plain verb, pass | Guard row: `the` before the name means not a person | Same |
| 28 | I | `paid bill sat` | Note "Paid bill", Sat 10 Oct 12:00 (#153 past log; `paid` is a past verb, G:186) | Note "Paid bill", Sat 10 Oct 12:00. Money: no amount, pass. Upkeep must not make a chore from a person's name | **Upkeep person guard:** never AddChore when the whole object is exactly a person's name. **Order note:** the #153 past log sits before kitchen (G:81), so under the agreed order it catches every dated done-verb phrase before upkeep (step 12). It must move to just before reschedule and task, as the fallback the 4:26 PM call meant it to be | Bill missing: AddChore("Pay bill") then DoChore at Sat 10 Oct, "Paid bill. How often?" (once the past log moves) |
| 29 | I | `paid bill 20` | Model. Lift: 20 as a weight, no reps (G:300); no day for the past log | LogSpend 20, note "bill", category "bill", now (4:34 PM: `paid` plus an amount is Money). No chore matches, so no tick. No person link (Later) | None. A spend is true whoever got the money | Same |
| 30 | I | `paid will back 15` | Model | Model. A repayment is not a spend, and Money has no transfers | **Money guard:** `paid <words> <amount>` passes when the first word after `paid` is a person or the words hold `back`. Without it: LogSpend 15, note "will back", a wrong write | Same (the `back` word covers it) |
| 31 | I | `bill 45 due fri` | Task "Bill 45 due", Fri 16 Oct 09:00. 45 is not a clock (G:644) | Same. Money: no money shape and a future day, pass. People: a name first with no contact form, pass | Guard row: a name as the first word never binds people without a contact form | Same |
| 32 | I | `spent 12.40 lunch with will` | Model (lift: 12.4 with no reps) | LogSpend 12.40, note "lunch with will", category "lunch". No talk logged. Money runs before people | None | Same |
| 33 | I | `lunch with will was 14 quid` | Model | Model (Claude may call LogSpend 14 GBP) | Social-noun trailing guard and the currency guard from `m5-parse-order.md` (money 17). Without them: "Lunch with Will: plan or done?" | Will missing: people never binds; model. Same result |

### Modals, months, verbs, training and reading

| # | Ctx | Phrase | Master now | Expected | Guard | Person missing |
|---|---|---|---|---|---|---|
| 34 | I | `will do laundry sat` | Task "Will do laundry", Sat 17 Oct 09:00 | Task "Will do laundry", Sat 17 Oct 09:00, never about Will. Upkeep: `will` is not on the verb list, and a plain verb with a future day passes | **Modal guard:** a name as the first word, followed by a verb, is the modal. People never links it, and a later mention pass must not either. See open question 3 on dropping "will" from the title | Same |
| 35 | I | `may need to move gym fri` | Task "May need to move gym", Fri 16 Oct 09:00. The reschedule shape needs `move` first (G:151) | Same | Month guard (row 10): `may` with no day number next to it is not a date | Same |
| 36 | I | `june 12 dentist` | Model. No months; lift: 12 as a weight, no reps | Task "Dentist", Sat 12 Jun 2027 09:00 (with the month fix in `TessDates`) | Month next to a day number is a date, never a name, even if June is a person | Same. If June is added: still a date |
| 37 | W | `mark set 3 as warmup` | Model. Not a relative set (G:218-241); lift: 3 as a weight, no reps | Model (gap: no set-kind phrase). Never LogTalk, never a set | Guard row: a name as the first word never binds people without a contact form | Same |
| 38 | W | `bench 80x8 with mark` | Model. Lift reads 80 x 8 but `resolveExercise("bench with mark")` needs every word in a name, so it fails (G:394-401) | Proposal (gap): set 80 x 8 on Bench Press in focus; `with <person>` at the end is dropped as a training partner (a link is Later) | **Lift companion guard:** drop `with <name>` only when the name resolves to a person. Never Bench Press from a person's name | Mark missing: model, as master |
| 39 | I | `read to rose` | Model | Model. Reading's `read X` guard: X holds a word that resolves to a person, so it passes. People: `read` is not a contact verb | Reading guard from `m5-parse-order.md` (people 40) | Rose missing: reading binds the ambiguous ghost "a task, or a book?" for "To rose". It waits for a tap. `to` cannot join the article list, because titles start with it ("To the Lighthouse") |
| 40 | I | `read the will` | Model | Model. `read X` with a leading `the` passes | Guard row: an article before the name means not a person | Same |

## Counts

- **On master now:** 17 rows already give the expected result (5, 6, 10, 13, 18, 20, 26, 27, 28, 30, 31, 33, 34, 35, 37, 39, 40). 8 rows write the right thing without the person link (1, 3, 4, 7, 8, 12, 16, 17). 10 rows go to the model where the grammar should act (2, 9, 11, 14, 15, 22, 29, 32, 36, 38). **5 rows write a wrong grocery item** (19, 21, 23, 24, 25). Master writes no wrong person, because it has no people at all.
- **Wrong writes the agreed order would add without new guards:** 4 rows. Row 28 (upkeep makes a chore "Pay bill" from a person's name), row 30 (Money logs a repayment as a spend "will back"), row 13 (if Honey is ever added, `get honey` becomes a task about a person), row 33 (an ambiguous people ghost on a spend; already covered by `m5-parse-order.md`).
- **Rows that change when the person is missing:** 18 (1, 2, 3, 4, 7, 8, 9, 11, 12, 14, 16, 17, 19, 24, 25, 28, 38, 39). Five more change if a name not in the list is added (5, 6, 10, 13, 15).
- **Order finding:** the #153 past-log rule sits ahead of kitchen and upkeep (G:80-83). Under the agreed order it must move after upkeep, or upkeep never sees dated done verbs (row 28, and `watered plants sat` too).

## Proposed guards

1. **Bare `get <name>`** (row 13). `get <person>` binds only when something follows the name. A bare `get <name>` that is an ingredient stays kitchen.
2. **Possessive and month** (rows 10, 14, 15, 35, 36). A month word is a date only next to a day number, and a word with `'s` is never a month.
3. **Gift with `for <person>`** (rows 19, 20). After `buy`, a non-food item followed by `for <existing person>` is a task about them. Food stays Groceries.
4. **Non-food words** (row 21). Add paint and DIY words to the K:167 list.
5. **Comma-list person item** (row 23). An item that is exactly a person's name and not an ingredient blocks the list. RC8 covers it later.
6. **Shop function words** (row 25). `will`, `may` and similar single words are never a grocery line, person or not.
7. **Upkeep person object** (row 28). Never AddChore when the object is exactly a person's name.
8. **Past-log placement** (row 28). Move the #153 past-log rule after upkeep, before reschedule and task.
9. **Money repayment** (row 30). `paid <person> ...` and any `paid ... back` pass to the model.
10. **Modal and first-word names** (rows 31, 34, 37). A name as the first word never binds people without a contact form, and never links later.
11. **Unknown lower-case name-words** (rows 7 to 9). With no such person, the "New person" offer goes under the note, not on top.
12. **Lift companion** (row 38). `with <person>` at the end of a set is dropped only when the name resolves.

## Swift Testing stubs

In `TesseraCore/Tests/TesseraTessTests/PeopleNameWordTests.swift`, one `@Test(arguments:)` table per group, with the store from this file:

- `contactPhrasesLinkNameWords()` rows 1 to 12
- `bareGetNameStaysKitchen()` row 13, with and without a Honey person
- `birthdayMonthsAndPossessives()` rows 14 to 16
- `buyGiftForPersonIsTask()` rows 17 to 21
- `andListsNeedAllFood()` rows 22, 23
- `shopRunSkipsPeopleAndFunctionWords()` rows 24 to 26
- `paidBillIsNotAChoreForAPerson()` row 28
- `pastLogRunsAfterUpkeep()` row 28 without Bill, plus `watered plants sat`
- `paidBackIsNotASpend()` row 30
- `billPhrasesNeverLinkBill()` rows 27, 29, 31
- `spendWithPersonStaysMoney()` rows 32, 33
- `modalWillAndMayAreNotPeopleOrMonths()` rows 34, 35
- `monthDayNumberIsADate()` row 36
- `nameFirstInWorkoutIsNotASetOrTalk()` row 37
- `liftCompanionDropsPerson()` row 38
- `readToPersonIsNotABook()` rows 39, 40
- `personMissingVariants()` every row in the "Person missing" column, run with Will, Rose, Mark and Bill removed

## Open questions

1. **Roses at the shop.** With a Rose in People, `rose` at the shop writes nothing (row 24). Should it instead offer the line with "Rose is a person" and wait for a tap, so he can still buy roses?
2. **`buy <person> a X`.** Should people link the person in `buy rose a card` (row 17), the way `get mum a card` will?
3. **Modal "will" in titles.** Should `will do laundry sat` become "Do laundry", Sat (row 34), or keep his words? Default here: keep his words.
4. **Lower-case name-words.** When the name is unknown, should a lower-case ordinary word (`saw rose`) ever be offered as a new person (rows 7 to 9)? Default here: yes, but under the note.
5. **And-lists without commas.** Should `basil and tomatoes` be groceries when every item is food (row 22), or stay with the model?
6. **Spends paid to a person.** `paid bill 20` logs a spend with category "bill" (row 29). With Bill in People, is that the right category, or should a payee that is a person send it to the model?
7. **Training partners.** Is `with mark` after a set worth a link from the workout to Mark (row 38), or should it just be dropped?
