# Notes, tasks and lists: the edges (board item 132)

For: Core. Owner: Research lab. Date: Oct 16, 2026 (Pacific).

Traced by hand against master at 21f406d, not run. 30 lines he would type that sit between a note, a task, a list
item and a grocery row, each with where it should land and where it lands today.

## Setup for every row
- Home, nothing running (no workout, cook or shop), no entry in focus. Fri Oct 16, 6:10 PM PT.
- Lists that exist: Groceries (milk not on it) and Packing. A Tacos recipe exists (demo store).
- "Model" below means `parse` returned nil: the on-device model reads it, then Claude if "Tess asks Claude" is on,
  else "Didn't catch that." A line nothing writes also goes into the capture-miss log (`TessCaptureEngine.capture`;
  only a Claude key is kept out of it).
- Parse order (`TessGrammar.parse`): wake word, `parseNote`, pasted recipe, `isQuestion`, `parseForProcess`, in-focus
  sets, comma sets, `parseLiftAndErrand`, `parseDatedLift`, `parseLift`, money and bare-set guards, `parsePastLog`,
  `parseKitchen`, `parseReschedule`, `parseTask`.
- Placeholders only. "hunter2" stands in for a password. No real secret is written here.
- Already covered elsewhere, so only referenced: misfires 230 and 288, A202, A273 (`grammar-misfires.md`,
  `grammar-regression.md`), lists 59 (`lists-fixtures.md`), V-R1 to V-R13 (`new-feature-phrases.md`).

## The rows
| # | He types | Expected landing | Tess line | Master today (traced, rule that fires) | Verdict |
|---|---|---|---|---|---|
| E1 | ideas for mom's birthday | New list "Ideas for mom's birthday" (empty, ready for items) | New list: Ideas for mom's birthday. | No rule: no date, no "list:", not a buy. Model | misfire (model) |
| E2 | milk | Grocery row "Milk" (the decision: a bare name joins an existing row, so a second "milk" says it's already on) | Milk, on the list. | At Home no rule reads a bare item (only `parseForProcess` does, while shopping). Model | misfire (model) |
| E3 | milk eggs | Two grocery rows: Milk, Eggs (dictation drops the comma) | 2 things on the list. | No comma, so the bare comma list rule skips it. Model | misfire (model) |
| E4 | packing list for the trip | Packing already exists: open it, nothing new. With no Packing list: new list "Packing for the trip" | Packing has 6 things. | "list:" and "new list" are anchored at the start; no date. Model | misfire (model) |
| E5 | trip packing: charger, passport | Items Charger, Passport on Packing (the heading names the list) | Charger and passport, on Packing. | Comma list rule: parts "trip packing: charger", "passport"; neither is a known aisle or ingredient, so not shopping. Model. The one-item form is misfire 288 | misfire (model) |
| E6 | remember the wifi password is hunter2 | A note, kept as typed, on the phone. Never memory, never sent to Claude, never in the miss log | Noted. Passwords stay in Notes, on the phone. | No rule ("remember" is not "remind"). Model, so with Claude on the password is sent. If nothing writes, the phrase lands in the miss log file. Memory refuses it only by luck: the "2" is an unlicensed number; "…is tacocat" would be kept. The bare "wifi password is hunter2" traces the same | misfire (model, privacy) |
| E7 | call mom | Task "Call mom" in Later (P800: no day is Later) | Call mom, in Later. | `parseTask` needs a date or todo/task/remind. Model | misfire (model) |
| E8 | call mom tomorrow | Task "Call mom", Sat | Call mom, tomorrow 9 am. | `parseTask`: "tomorrow" found, no time, 9:00 (time default per `reminders.md`) | ok |
| E9 | buy a birthday card | Task "Buy a birthday card" in Later (a card is clearly not food) | Buy a birthday card, in Later. | buy rule, `notGroceries("a birthday card")` false: "a" is excluded from the gift shape and "card" is not in the services words. Groceries row "a birthday card" | misfire (wrong write) |
| E10 | get gas | Task "Get gas" in Later (US for petrol) | Get gas, in Later. | get rule, `isGettable` true, `notGroceries` has "petrol" but not "gas". Groceries row "gas" | misfire (wrong write) |
| E11 | pick up dry cleaning | Task in Later. Same as A202 | Pick up dry cleaning, in Later. | "pick up" is only read before "for groceries". Model | misfire (model) |
| E12 | trash night is tuesday | A note "Trash night is Tuesday" (a fact, not a due date). Upkeep may adopt it later | Noted. | `parseTask`: "tuesday" is a date, title is what's left. **Task "Trash night is", Tue Oct 20 9 am** | misfire (wrong write) |
| E13 | gift ideas: lego, socks | List "Gift ideas" (new if none) with Lego, Socks | New list: Gift ideas, 2 things. | Comma list: "gift ideas: lego" and "socks" aren't shopping. Model. "gift ideas: lego, chocolate" would put "gift ideas: lego" on Groceries (chocolate is pantry) | misfire (model) |
| E14 | list of movies to watch | New list "Movies to watch" | New list: Movies to watch. | "list:" needs the colon. Model | misfire (model) |
| E15 | dune to read | Reading queue "Dune" once Reading ships; until then an item on a "To read" list | Dune, on To read. | No rule ("to" is under three letters, so no lift either). Model | misfire (model) |
| E16 | fix the faucet | Task "Fix the faucet" in Later | Fix the faucet, in Later. | `startsWithErrand` knows "fix" but only guards comma lists and the shop. Model | misfire (model) |
| E17 | dentist | Task "Dentist" in Later (one Undo if wrong) | Dentist, in Later. | No rule. Model | misfire (model) |
| E18 | need lightbulbs | Grocery row "Lightbulbs" (household, unclear stays Groceries) | Lightbulbs, on the list. | "need" is in `notPast`, so no log; no buy rule for "need". Model | misfire (model) |
| E19 | out of coffee | Grocery row "Coffee". The "we're" form is A273 | Coffee, on the list. | No rule. Model | misfire (model) |
| E20 | costco run sat | Task "Costco run", Sat | Costco run, tomorrow 9 am. | `hasDate` true ("sat" is last), so no kitchen reading; `parseTask` | ok |
| E21 | the plumber said 3 weeks | A note, kept as typed | Noted. | `parseLiftAndErrand` tries "the plumber said 3": no exercise. "3" alone is not a time without "at". Model (which may make a task due in 3 weeks) | misfire (model) |
| E22 | book flights | Task "Book flights" in Later | Book flights, in Later. | No date, no todo. Model | misfire (model) |
| E23 | passport expires 2027 | A note, kept as typed | Noted. | "2027" is not a clock time; no date. Model | misfire (model) |
| E24 | add charger to packing | Item "Charger" on Packing. Same shape as misfire 230 | Charger, on Packing. | The "add … to" rule only knows groceries and shopping list. Model (`addToList` exists there) | misfire (model) |
| E25 | remove milk | Milk taken off Groceries, with UNDO for 10 s | Milk, removed. | No rule, and the model has no remove or uncheck tool. Model, then "Didn't catch that." or a wrong write | misfire (model) |
| E26 | https://www.nytimes.com/2026/10/14/travel/kyoto.html | A note holding the link as pasted. No fetch, nothing sent | Noted. | One word: every lift and set rule skips it; no date. Model, so with Claude on the link is sent. `RecipeLinkReader` is not wired into capture | misfire (model) |
| E27 | todo: taxes | Task "Taxes" in Later | Taxes, in Later. | `parseKitchen` returns nil for "todo"; `parseTask` explicit | ok |
| E28 | shopping list: rice, beans | Grocery rows Rice, Beans | 2 things on the list. | "shopping:" needs the colon right after "shopping". Comma list: "shopping list: rice" is shopping (last word rice). **Groceries rows "shopping list: rice" and "beans"** | misfire (wrong write) |
| E29 | parking spot 4B | A note, kept as typed (memory refuses places anyway) | Noted. | "4b" is not a time; no exercise. Model | misfire (model) |
| E30 | groceries for tacos | Tacos' missing ingredients on Groceries ("Tacos, 2 added." per the receipt rule). No Tacos recipe: ask | Tacos, 2 added. | "groceries:" needs a colon; "… for groceries" must end the line. Model | misfire (model) |

**Count:** 3 ok, 27 misfires. 4 are wrong writes by the grammar (E9, E10, E12, E28). 23 fall to the model, and 2 of
those send something private or useless to Claude when the switch is on (E6, E26).

## Gaps
| # | Where | Proposed default | Owner |
|---|---|---|---|
| NE1 | `TessMemory.refusal` (TesseraCore/Tess/TessMemory.swift) | Add `.looksLikeSecret`: password, passcode, pin, wifi, code, combo, ssn, social security, account number. Line: "I don't keep passwords." Today only the Claude key prefix is refused | Core (AI-8 before `remember` ships) |
| NE2 | `TessGrammar.parse`, right after `parseNote` | A line with a secret word (NE1's set) and "is" or ":" becomes a note on the phone, as typed. It never reaches the model step, never Claude, and `capture` keeps it out of the miss log like a Claude key | Core |
| NE3 | `parseKitchen`, before `parseCook` | A bare line of 1 to 3 words where every word is a known aisle word or ingredient (`looksLikeGroceries`) is Groceries, split on spaces ("milk eggs"). Anything else stays with the model | Core, Kitchen to confirm |
| NE4 | `parseKitchen` buy/get regex | Add "need", "out of", "we're out of", "we need". The same `notGroceries` check applies, so "need a haircut" is a task | Core |
| NE5 | `parseKitchen` list regex | A new list from "X list", "list of X", "X list for Y", "ideas for X", "X ideas". The name drops "list" and "list of". If a list with that name exists, open it and make nothing | Core, Lists |
| NE6 | `parseKitchen` comma rule | "Heading: a, b": the part before the colon is never an item. "shopping list" or "grocery list" means Groceries; a name that matches a list adds there; else a new list with the items | Core |
| NE7 | `parseKitchen` "add … to" rule | "add X to <list>" and "X on <list>" add to any list by name (reuse `TessTools.Call.list(named:)`). An unknown list name goes to the model | Core |
| NE8 | `parseTask` | An errand verb first (`startsWithErrand`, plus "pick up" and "book") with no date is a task in Later. A bare single noun ("dentist") stays with the model | Core, Product to confirm |
| NE9 | `notGroceries` services words | Add US words: gas, card, stamps, dry cleaning. Unclear still stays Groceries | Core |
| NE10 | `parseTask` | "X is/are <day>" ("trash night is tuesday") is a fact: a note, never a task titled "Trash night is". "Dentist is tuesday" too: Product picks note or task | Product, then Core |
| NE11 | Lists.swift and TessTools | No remove action. Add a remove (soft delete, UNDO 10 s) for "remove X", "take X off", "X off the list", grammar and tool | Core |
| NE12 | `TessGrammar.parse` | A line that is only a link becomes a note with the link as pasted. Nothing fetched, nothing sent. Recipe links wait for `RecipeLinkReader` to be wired | Core |
| NE13 | On-device model prompt | Plain statements with no verb to do ("passport expires 2027", "parking spot 4B", "the plumber said 3 weeks") prefer `createNote`, never a task due later. No grammar rule: too broad | AI |
| NE14 | `parseKitchen` | "groceries for <recipe>" adds that recipe's missing ingredients. No such recipe: ask "No Tacos recipe yet. Paste one?" | Kitchen |
| NE15 | Reading (M5) | "<title> to read" goes to the Reading queue. Until Reading ships, a "To read" list item | Product |

## Top 3
1. NE1 and NE2: a password typed to Tess goes to Claude and the miss log today, and memory refuses it only by luck.
2. NE3 and NE4: the most typed lines ("milk", "milk eggs", "need lightbulbs") miss at Home.
3. NE6 and NE9: real wrong writes he would see on Groceries ("shopping list: rice", "gas", "a birthday card").

## Product's and Design's answers (Oct 16)

- NE11 is decided (Product dce3675): "remove X" soft-deletes the row, Tess says "Milk, removed." and UNDO lasts 10 s. E25 above now expects that line.
- Design 65 (66550d4) adds two phrase answers for QA:
  - "remove rice" with no rice row: "No rice on Groceries."
  - "remove rice" when 2 rows match: "2 rows match. Swipe the one to remove."
