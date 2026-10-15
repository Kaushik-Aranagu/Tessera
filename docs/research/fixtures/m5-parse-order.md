# M5 parse order check

For: Core engine (`TessGrammar`, M5 Reading S4, Money S4, People P5, Upkeep U4). Research lab. Date: 2026-10-15.

This checks all 170 phrase rows in `reading.md` (40), `money.md` (50), `people.md` (40) and `upkeep.md` (40) against the parse order Product agreed at 4:10 PM PT (`../../product/decisions.md`, Research #135): notes, pasted recipes, relative sets, reading, money, people, comma sets, lifts, kitchen, upkeep, tasks.

Grammar facts come from a static read of `origin/master` at `1a9c218` (fetched 2026-10-15, "Merge pull request #141 from Kaushik-Aranagu/core/ranker"): `TessGrammar.swift` and `TessGrammar+Kitchen.swift`. Both files are unchanged since `5258866` and `e56c15e`, the commits the four fixture files were written against, so their "G:" and "K:" line numbers still hold. Nothing was run. There is no Swift toolchain here, so every result is a hand trace.

## How the check was done

**Master's order today** (G:52-91): note (G:55), pasted recipe (G:58), question guard (G:62), process rule (G:66), relative set (G:70), comma sets (G:73), named lift (G:76), kitchen (G:80), reschedule (G:83), reschedule-shape stop (G:87), task (G:90). Nil goes to the model.

**The agreed order with master's other rules kept in place.** The 4:10 PM order does not name the question guard, the process rule or reschedule. They stay where master has them:

1. note
2. pasted recipe
3. question guard
4. process rule (cook, workout, shop)
5. relative set
6. **reading**
7. **money**
8. **people**
9. comma sets
10. named lift
11. kitchen
12. **upkeep**
13. reschedule, then the reschedule-shape stop
14. task

**Each M5 rule is taken as its fixture file proposes it.** That means the slice table plus every rule and guard the file proposes: reading.md's guards (rows 7, 10, 16, 21, 23, 24, 36, 37, 40), money.md's M1 to M11, people.md's proposals (including the shop-run skip in row 35 and the `when's` lead word), and upkeep.md's proposals (including the narrowed `did`, the kitchen `fine` guard and the ingredient guard). Fixes the files hand to `TessDates` (`yesterday`, past mode, months, ordinals, 12-hour `at N`) and to the normaliser are taken as done, since they are not about order.

**Store.** The ship lists add each domain's fixtures to one shared eval store, so the trace uses the union: the books, the money contexts, the people (Mum, Sam, Ben, Rosemary, Ravi), the chores (Water plants, Clean bathroom, Laundry, Pay rent, Take out the bins, Top up the oil) and the open tasks ("Call mum", "Finish the report", "Clean the oven", "Do the ironing"). Where a result depends on this, the row says so.

**Question asked of every row.** With the rule slotted in, does an earlier rule now catch the phrase first, or does the M5 rule now catch a phrase a later rule should get? A row "changes" when its parse under the order is not its expected parse.

## Summary

| File | Rows | Same as expected | Changes |
|---|---|---|---|
| `reading.md` | 40 | 40 | 0 |
| `money.md` | 50 | 47 | 3 (rows 17, 25, 43) |
| `people.md` | 40 | 39 | 1 (row 40) |
| `upkeep.md` | 40 | 39 | 1 (row 38) |
| **Total** | **170** | **165** | **5** |

Money rows 38 to 40 are receipt photos (CM1). They never go through `TessGrammar.parse`, so order cannot change them; they are counted as unchanged.

Outside the 170 rows, four phrases from existing fixtures are stolen: spoken-normaliser rows 62 and 67, and grammar-misfires rows 12 and 32. Three more need a guard so they stay right (spoken row 54 with GC rows 44 and 45, and misfires rows 19 and 41). See "Cross-domain steals".

Why so few: `people.md` and `upkeep.md` already assumed this exact order (their open question 1). `reading.md` and `money.md` assumed reading and money in the same places; the order only adds people after money and upkeep after kitchen, and those two later rules see only what reading and money pass on.

## Rows whose parse changes

| File and row | Ctx | Phrase | Expected parse | Parse under the agreed order | Rule that wins | Proposed fix |
|---|---|---|---|---|---|---|
| money 17 (also Money eval 15) | C | `lunch with sam was 23 quid` | Model: Claude calls LogSpend 23 GBP, category lunch, "via Claude" | People binds "lunch with sam" (Sam resolves in the shared store). No date and no verb, so it gives people row 19's ambiguous ghost "Lunch with Sam: plan or done?" and waits for a tap. No spend | people (step 8) | **Narrower pattern.** The social-noun form (`coffee`, `lunch`, `dinner`, `drinks`, `call` + `with`) binds only when it starts the phrase and the names after `with` are followed by nothing, a date or time, or `and <person>`. Any other trailing word passes on. Also a guard: people never binds a phrase that holds a currency mark or word (`£ € $ ₹`, `quid`, `rs`, `eur`, `gbp`, `usd`, `inr`, `rupees`, `pounds` after a number). People row 39's note shows the risk: it says people would match "lunch with sam" inside a longer phrase |
| money 25 | I | `paid rent 650` | Model: LogSpend 650 after Money S1. No grammar write | Upkeep: `paid` is on the U4 verb list. With the shared store it is DoChore(Pay rent), note "650" (upkeep row 34). With money's own store (no chores) it is AddChore("Pay rent") then DoChore. Either way a chore, not a spend | upkeep (step 12) | **Tie-break, Product's 4:10 PM default.** "Does 'paid' work like 'spent'? Yes when an amount follows; if it names a chore, that chore is ticked in the same ghost row" (`ship-list-m5-money.md`, open question 4). So money claims `paid <amount> ...` and `paid <words> <amount>`: LogSpend, plus DoChore on a matching existing chore in one ghost batch. `paid rent` with no amount stays upkeep. This makes money 25 a grammar spend, and the expected column of money 25, upkeep 34 and upkeep 40 needs updating to "spend + chore tick" (those three rows predate the 4:10 default). If Product keeps upkeep's rule instead, update money 25 to "chore" and drop the money claim |
| money 43 | S | `1.20 milk` | Ambiguous: grocery line "1.20 milk" on top, spend 1.20 milk as the alternative. Waits for a tap | Groceries ["1.20 milk"], auto-commits after 2 s. The process rule's shop branch (G:120-128) runs at step 4, before money: the text has a number and `IngredientLine.parse` reads 1.2 as a leading amount (Q:122) | process rule, shop branch (step 4) | **Guard inside the process rule.** Rule M9 cannot live in money's slot, because the process rule always runs first. Put it in the shop branch of `parseForProcess`: a leading amount with exactly two decimals and no kitchen unit returns the ambiguous grocery line or spend parse. Money.md's own assumed order had the same gap |
| people 40 | I | `read sam's draft` | Model (it may make the task "Read Sam's draft" about Sam). No book | Reading binds `read X`. "sam's draft" is not a book, so the S4 table queues a new book "Sam's draft", or, with reading.md row 14's proposal, the ambiguous ghost "a task, or a book?". Either way a book is written or offered | reading (step 6) | **Guard on `read X`.** When X does not resolve to an existing book, reading binds only if X has no leading article (`the`, `a`, `an`, `my`, `our`), no possessive, and no word that resolves to a person, chore, list or open task. Then it is row 14's ambiguous ghost. Otherwise it passes on. New books still come from `queue X`, `to read X` and `reading X` |
| upkeep 38 | I | `read the gas meter` | Model. Not a book, not a chore | Reading binds `read X` as above: new book "The gas meter", or the row 14 ambiguous ghost | reading (step 6) | Same `read X` guard: the leading `the` makes it pass on. Upkeep, reschedule and task all miss (no verb on the list, no date), so the model gets it |

Rows checked and found unchanged where the order could have mattered:
- Reading rows 9, 10, 36 (live workout): relative sets and the process rule run first; reading yields bare numbers and bare `finished` while a workout is in front.
- Reading rows 15, 20, 37 and upkeep row 39 (`read dune thu`, `start push day`, `finished the report`, `finished the ironing`): reading passes; money, people and upkeep have nothing to bind (`read`, `start`, `finished` are not on the upkeep list), so they reach the task rule or the model as expected.
- Reading row 24 (`reading timer 30`): reading's `timer` guard passes it; money sees no money shape; lift fails on no reps; kitchen timer wins.
- Money rows 23 and 24 (`pay rent 650 fri`, `pay rent fri`): the Pay rent chore exists in the shared store, but `pay` is a plain verb with a day cue, so upkeep passes and the task rule takes them.
- Money row 26 (`spent the day at the beach sat`): money needs an amount, `spent` is not an upkeep verb, task wins.
- Money rows 27 to 31, 37 (sets): relative sets and lifts win; money's M3 guard passes `82.50 x 8`.
- Money rows 41 and 44: money's comma and `buy` guards pass them to kitchen.
- Money rows 45, 46 (`8.99 dune`, `p 12.50`): reading has no `<amount> <title>` form, so money takes the first; reading takes the second.
- People rows 6, 17, 18, 20, 21, 33: people runs before kitchen, so `parseCook` and `get` never see them.
- People row 35 (`ravi` at the shop): unchanged only because people.md puts its skip inside the process rule. If Core builds it only in `TessGrammar+People.swift`, the process rule (step 4) adds "ravi" to Groceries first, the same trap as money 43.
- Upkeep rows 12 to 14, 36 (`did ...`): unchanged once `did` is narrowed in the question guard; `did bench 80x8` reaches lifts before upkeep.
- Upkeep rows 18, 19, 30 (`watered plants sat`, `watered plants thu`, `pause chores till sun`): kitchen's `parseCook` finds no recipe and passes; upkeep runs before reschedule and task.
- Upkeep row 25 (`checked the oil, fine`): comma sets fail, and kitchen yields with the proposed `fine` guard and `checked` errand verb.
- Upkeep rows 34, 40: unchanged under upkeep.md's rule, but see the money 25 tie-break.

## Rows touched by the 4:30 PM `buy` decision

Product, 4:30 PM PT (`decisions.md`, Research #145): "buy" with a clearly non-food object is a task, not groceries. Food or household stays Groceries, and when the object is unclear Groceries stays the default. This amends People Decision 8. It is a kitchen change, not an order change, but four of the 170 rows start with `buy`:

| File and row | Phrase | Expected before | Under the 4:30 PM decision | Flag |
|---|---|---|---|---|
| people 32 | `buy lego for priya` | Groceries ["lego for priya"], by People Decision 8 | **Task "Buy lego for priya", Later.** Lego is a toy, so it is clearly non-food. No person link, because there is no Priya and `buy` is not a contact phrase | **Expected value changes.** Update the row. Kitchen needs a non-food check that knows it: `grammar-misfires.md` RC3's word list (rule 4) does not hold "lego", and the 3-word fallback would keep it on Groceries. Suggestion: an item that is not in the aisle guide or the ingredient book and is followed by `for <name>` is a gift, so a task. Check it against misfires row 70 (`buy flowers for mum`), which the decision's "unclear means Groceries" may keep on the list |
| people 28 | `buy present for mums birthday on the twentieth` | Task, Tue 20 Oct, about Mum | Same. The date already makes it a task, and "present" is non-food anyway | No change |
| people 34 | `buy rosemary` | Groceries ["rosemary"] | Same. Rosemary is food | No change (still the guard row) |
| money 44 | `buy milk 1.20` | Groceries ["milk 1.20"] | Same. Milk is food | No change |

No upkeep row starts with `buy`. The people 32 change comes from the decision, not from the parse order, so it is not counted among the 5 order changes.

## Cross-domain steals

The check covered `spoken-normaliser.md` (80 rows), `grammar-misfires.md` (298 rows, written at `0950ba7`, same grammar code; it landed during this check), the `grammar-collisions.md` test rows (55), and `lists-fixtures.md` part 2 (60 phrases). The Kitchen lead's 60 rows are inside `grammar-misfires.md` (rows 239 to 298).

`grammar-misfires.md` describes master today, so many of its "model now" rows are phrases an M5 rule is meant to take over (for example rows 1, 4 to 7, 11, 14, 15, 17, 31: upkeep and people check-ins). Those are planned takeovers, not steals. The table lists only rows where an M5 rule does something the row, or the M5 file, says it must not.

| Source and row | Phrase | Expected there | Under the agreed order | M5 rule | Proposed fix |
|---|---|---|---|---|---|
| spoken-normaliser 62 | `Spent 1250 at Tesco` | PASS: model asks "12.50 or 1250?" | LogSpend 1250. Money's S4 rule takes any whole number after `spent` | money | **Guard.** On a spoken capture, money returns the ambiguous ghost "12.50 or 1250?" when `spent` (or `paid`) is followed by a 4-digit whole number the transcriber wrote as digits, with no currency mark. This needs the normaliser's proposed `Spoken` struct to carry a "transcriber digits" flag, because the grammar cannot tell row 62 from row 65 (`Spent 1500 on petrol`, made by the normaliser, which must stay a spend). Typed input logs as typed |
| spoken-normaliser 67 | `Paid 120000 rs deposit` | Model: LogSpend 120000 INR | Upkeep: `paid` is on the verb list, so AddChore("Pay deposit") then DoChore with note "120000 rs" | upkeep | The money 25 tie-break fixes it: money claims `paid` + amount (a spend in INR, no chore matches). Until then, add a guard to upkeep: never create a chore when the phrase holds a currency mark or word |
| spoken-normaliser 54, GC rows 44 and 45 (`call mum thu`, `call mum at 7`) | `Call mum at 7pm` | Task "Call mum", today 19:00 | People's contact-task form binds and makes the same task about Mum, which is fine. But people.md row 13 proposes returning the open task "Call mum" instead of making a new one, and the shared store has that open task. Applied to a dated phrase, it would swallow the date | people | **Guard.** The open-task dedupe applies only to an undated contact task. With a day or time, people makes the dated task as P5 says |
| grammar-misfires 12 | `paid 40 for gas sat` | Spend (Money; the model now) | Upkeep: `paid` is on the verb list, so AddChore("Pay 40 for gas" or "Pay gas" with note "40") then DoChore on Sat 10 Oct | upkeep | The money 25 tie-break fixes it: money claims `paid 40 ...` as a spend of 40, note "gas", Sat 10 Oct (M3 does not fire: "for gas" is not a number) |
| grammar-misfires 32 | `did legs mon` | Model (a workout log) | Once `did` is narrowed in the question guard, nothing else claims it, and `did` is on the upkeep verb list: AddChore("Do legs") then DoChore on Mon 12 Oct | upkeep | **Guard.** `did X` binds only to an existing chore and never creates one. `did` is too general ("did legs", "did a 5k", "did my taxes"). Upkeep rows 12 to 14 all name existing chores, so none changes. The U4 table's "(or AddChore then DoChore)" for `did laundry` then goes to the model when no Laundry chore exists |
| grammar-misfires 19 | `had lunch with ravi wed` | A talk on Wed 14 Oct (the model now) | With the anchoring guard below, people passes (the phrase starts with `had`); RC2 sends it to the model. Without the guard, people would bind "lunch with ravi wed" as a task for Wed 21 Oct, a future plan for a past lunch | people | **Guard.** The social-noun form may start with `had`. Then it is a LogTalk dated the most recent past day, like a past contact verb |
| grammar-misfires 41 | `get mum a card` (at the shop) | Not groceries | Groceries ["get mum a card"]. The process rule's shop branch (step 4) runs before people | process rule, shop branch (step 4) | Same trap as money 43 and people 35: RC4 from `grammar-misfires.md` (the shop branch returns nil for a first word `buy`, `get`, `add`, `pick` or an errand verb) must land before people's `get <person>` can work at the shop |
| spoken-normaliser 37 | `Remind me to call Ravi tomorrow` | Task "Call Ravi", Fri | Task "Call Ravi", Fri (unchanged) | none | Guard for clarity: people never binds a phrase that starts with `todo`, `task` or `remind`, so the task rule keeps its title rules. Linking Ravi can come from `linkMentions` later |

No other steals were found:
- **Spoken-normaliser, the other 76 rows.** Sets (rows 1 to 23, 27 to 34, 72, 73) reach relative sets and lifts first, and money's M3 guard passes "N x M" phrases. Money rows 61, 64 to 66 and 68 are money as intended. Task and reminder rows reach the task rule (upkeep passes plain verbs with a day cue, as in row 51 `Pay the window cleaner Thursday`). Notes win at step 1.
- **`grammar-collisions.md` test rows.** Reading rows (`p 42 of 80`, `42` and `finished` with a workout and a book) resolve as intended. `start the chilli` and `start writing the report` pass reading (start binds only to an existing book). `dal for dinner monday` has no `with`, so people passes. `add 2.5` in a workout, `bbq: sausages, buns, ketchup` and `2 x 6 rolls` pass money through M1, the comma guard and M3.
- **`grammar-misfires.md`, the other rows.** Rows 33 to 37 stay tasks (`need`, `feed`, `weed`, `water` are plain verbs, and reading passes `read 40 pages sat` on its day cue). Bare clock rows reach people only for contact phrases (`call mum at 7`, `meet ravi at 6:30`, `lunch with ravi at noon`), which become the same dated tasks linked to the person. Row 99 `bins out at 10` stays a task because upkeep's `<noun> out` form never binds with a time. Row 191 `finished cooking` and row 22 `finished the report today` pass reading (no book). Row 207 `mum's birthday sat` at the shop is dated, so the shop branch passes and people links Mum. Row 212 `who's free sat` stays a question once `who`/`who's` join the leads. Kitchen rows 239 to 298: B1 `get mum a card` goes to people as a task about Mum, which agrees with the row. B15 `get the bins out` is safe only if upkeep's `<noun> out` form requires the whole rest of the phrase to resolve to a chore ("get the bins" does not). B14 `buy time with the landlord` has no social noun, so people passes. Part A stays kitchen: money's M1 and comma guards pass every row, and `3 lemons` in a workout has no money shape.
- **`lists-fixtures.md` part 2.** Row 15 `finish packing` is safe only if reading matches the word `finished` exactly, never `finish`. Row 13 `start packing` passes reading. Rows 1 and 60 (`films: dune, ...`) carry a colon, so people and money pass, and reading has no `<list>:` form.

## The final ordered rule list

Core can implement this as written. "Pass" means return nil so the next rule runs. "Hand off" means stop and send the phrase to the model now, the way the reschedule-shape stop does at G:87. Rules marked "unchanged" keep master's code.

1. **Note** (unchanged, G:154). `^note[:\s]` on the raw phrase.
2. **Pasted recipe** (unchanged, K:10).
3. **Question guard** (G:94). Lead words: `what`, `whats`, `what's`, `when`, `when's`, `whens`, `who`, `how`, `anything`, `everything`, `show`, `am i`, `have i`. `did` is a lead only before `i`, `you`, `we` or `tess`. A trailing `?` is always a question.
4. **Process rule** (G:102). Cook and workout branches unchanged. Shop branch gains three guards, checked before it adds a line:
   - a phrase that is exactly a person's name (`person(named:)`) and not an ingredient: no write, "Ravi? That's a person, not a grocery." (people 35);
   - a leading amount with exactly two decimals and no kitchen unit: the ambiguous parse, grocery line on top, spend as the alternative, no 2 s commit (money 43, M9);
   - a first word `buy`, `get`, `add`, `pick` or an errand verb: pass, so kitchen and people see it (`grammar-misfires.md` RC4; misfires row 41).
5. **Relative set** (unchanged, G:163). Only with `context.entry`.
6. **Reading** (`TessGrammar+Reading.swift`). Binds the S4 table and reading.md's rows. Guards:
   - `p N`, `pg N`, `page N` always bind, even with nothing reading ("No book open."). A bare `N` binds only when a book is the running process in Now, never while a workout is in front.
   - Never binds a phrase that contains `timer`. `reading N` needs N to be an exact book title. A title that is only a number and a time unit is not a title.
   - `read X`, when X is not an existing book: binds (row 14's ambiguous ghost) only if X has no leading article (`the`, `a`, `an`, `my`, `our`), no possessive, and no word that resolves to a person, chore, list or open task. Otherwise pass (people 40, upkeep 38). `queue X`, `to read X` and `reading X` may create a book.
   - `start X` and `started X` bind only to an existing book.
   - Matches the word `finished` exactly (never `finish`). `finished X` binds only when X is a book by exact title or every word. Bare `finished` binds only when a book is reading and `context.process` is nil or that book.
   - A day cue outside a matched title means pass, so the task rule takes it. A weekday inside a matched title is never a cue.
7. **Money** (`TessGrammar+Money.swift`), on the raw phrase, not `normalize`. Binds `spent <amount>`, `paid <amount> ...` and `paid <words> <amount>` (4:10 PM default: spend, plus DoChore on a matching existing chore in the same ghost batch), an amount first with a money shape (two decimals, a symbol or a currency word), and, while a total is awaited, `38.20`, `£38.20`, `total N`, `skip`, `no total`, and a bare whole number only when no workout runs. Guards:
   - M1: pass on a phrase that starts with `buy`, `get`, `groceries:`, `add`, `list:`, `note`, `todo`, `task`, `remind`, `p`, `pg`, `page`, `read`, `reading` or `finished`.
   - Pass on a comma outside the amount itself.
   - M3: pass when the amount is followed by `x N`, `for N` or a second number.
   - M4: "pounds" is GBP only after a money cue or a two-decimal amount with no reps.
   - M6: with a workout in front, only `total N` or a currency-marked amount answers a total.
   - M8 (if Product takes it): a money-shaped phrase with a future day cue and no task verb hands off. Without M8 it passes and the task rule takes it.
   - M10 and M11: refund words, or a second amount after the note, pass.
   - Spoken only: `spent` or `paid` followed by a 4-digit whole number the transcriber wrote as digits gives the ambiguous ghost "12.50 or 1250?" (spoken 62).
8. **People** (`TessGrammar+People.swift`). Binds birthdays, past contact verbs, contact tasks, social nouns with `with`, and `get <person>`, only when the argument resolves. Guards:
   - The phrase must start with the contact verb, the social noun (optionally after `had`), `get`, or the name of a birthday phrase. People never binds after `todo`, `task` or `remind`.
   - Social-noun form: the names after `with` must be followed by nothing, a date or time, or `and <person>`. Any other trailing word passes (money 17). After `had`, it is a LogTalk dated the most recent past day (misfires row 19).
   - Never binds a phrase with a currency mark or word, or a colon.
   - The open-task dedupe (`call mum` returns the open "Call mum") applies only when there is no day or time.
   - `get <person>` needs the person as the very next word (`get back to Sam` passes).
9. **Comma sets** (unchanged, G:202).
10. **Named lift** (unchanged, G:235).
11. **Kitchen** (K:17). Unchanged except: a comma list whose last item is `fine` or `ok` is never shopping, and `checked` joins the errand verbs (K:143) (upkeep 25). Under the 4:30 PM decision, `buy` with a clearly non-food object is a task (Later when undated); an unclear object stays Groceries (people 32 becomes a task, people 34 and money 44 stay Groceries). When Lists slice 8 lands, its `Name:` prefix goes between lifts and kitchen and its list verbs go right after kitchen, as `lists-fixtures.md` proposes; both fire only on an exact list name, so they take nothing from upkeep.
12. **Upkeep** (`TessGrammar+Upkeep.swift`). Binds the U4 table on the fixed verb list. Guards:
    - A day cue after a done verb is the most recent past day, today included. A future day cue passes to the task rule. A plain verb with a day cue passes.
    - `did X` binds only to an existing chore and never creates one (misfires row 32).
    - `<chore noun> out` binds only when the whole rest of the phrase resolves to an existing chore, and never with a day or time.
    - No new chore when the object resolves to an ingredient.
    - No new chore when the phrase holds a currency mark or word, and never `paid` plus an amount (money owns it under the 4:10 default; if Product keeps upkeep's rule, drop this line and money's `paid` claim together).
    - `<chore> every <weekday>` passes to the task rule.
    - An open task that matches beats a new chore.
13. **Reschedule** (unchanged, G:137), then the reschedule-shape stop (G:87).
14. **Task** (unchanged, G:352), with the shared `TessDates` work the fixtures ask for: `yesterday`, a past mode for done verbs, months, ordinals, and a 12-hour bare `at N`.

## Notes for Core

- **Three guards live inside the process rule, not in the M5 files.** Money's M9, People's shop skip and the misfire batch's RC4 can only work there, because the process rule runs at step 4. This is the most likely thing to get lost, since the ship lists describe the first two as part of their own slice.
- **Hand off versus pass.** Only M8 needs a hand off. Every other "goes to the model" row in the four files was traced through the later rules and still reaches the model (for example money 48 and 50, upkeep 16, reading 23).
- **Expected values to update once Product confirms the `paid` tie-break:** money 25, upkeep 34 and upkeep 40.
- **Expected value to update now, from the 4:30 PM `buy` decision:** people 32 (Groceries becomes a task).
- **Not about order, but found on the way.** The 4:10 PM Money defaults also differ from two money rows: row 49 (`spent 60 dinner split with sam` logs 60 in the fixture; the default logs his share, 30) and row 14 (`spent 20 chf taxi` logs an unmarked 20 in the fixture; the default sends codes beyond the four to the model). Money.md should be brought in line with the defaults before Core writes the Swift Testing rows.
