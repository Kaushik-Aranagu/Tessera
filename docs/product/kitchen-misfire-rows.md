# Kitchen rows for the grammar misfire sweep

*Kitchen lead, 2026-10-15 (part C added 2026-10-17). For Research's `fixtures/grammar-misfires.md`, so Core's grammar fix batch can't break the kitchen. Part A has 40 phrases that must stay kitchen (groceries, timer, cook, recipe); part B has 20 that look like groceries but aren't. Recipes assumed: "Spaghetti carbonara", "Chilli con carne", "Weeknight dal". No live workout unless noted. "groceries [..]" means items added to the one grocery list.*

## A. Must stay kitchen (40)

| # | Phrase | Expected |
|---|---|---|
| A1 | buy milk | groceries ["milk"] |
| A2 | get oat milk | groceries ["oat milk"] |
| A3 | milk, eggs, bread | groceries, 3 lines |
| A4 | 2 lemons, a bunch of coriander | groceries, 2 lines |
| A5 | buy 500 g chicken thighs | groceries ["500 g chicken thighs"] |
| A6 | get 6 eggs and butter | groceries ["6 eggs", "butter"] |
| A7 | groceries: bin bags | groceries ["bin bags"] |
| A8 | add to groceries: kitchen roll | groceries ["kitchen roll"] |
| A9 | buy chalk | groceries ["chalk"] (Household); a lift name must not win |
| A10 | buy bench scraper | groceries ["bench scraper"]; "bench" must not become Bench Press |
| A11 | get squat rack hooks | groceries; not a Squat set |
| A12 | buy press n seal | groceries ["press n seal"]; not a press lift |
| A13 | buy curl cream | groceries ["curl cream"]; not a curl |
| A14 | 2 tins tomatoes, pasta, parmesan | groceries, 3 lines |
| A15 | buy coffee beans 1 kg | groceries ["coffee beans 1 kg"] |
| A16 | get bananas x6 | groceries ["bananas x6"]; "x6" is not reps |
| A17 | buy 3 x 400 g tins chickpeas | groceries, 1 line; not sets x reps |
| A18 | buy sun cream | groceries; "sun" is not Sunday |
| A19 | buy sat nav charger | groceries; "sat" is not Saturday |
| A20 | buy cake candles wed | **task**, Wednesday (a dated buy stays a task); listed here so the date rule is tested next to A18-A19 |
| A21 | get tonic water | groceries; "ton" is not a date |
| A22 | buy tomorrow's bread | groceries ["bread"]; *also accept* a dated task "Buy bread" tomorrow (decision: groceries wins) |
| A23 | timer pasta 10 | timer "Pasta", 10 min |
| A24 | 10 min timer | timer, 10 min |
| A25 | timer 90 sec | timer, 90 s |
| A26 | rice timer 18 | timer "Rice", 18 min |
| A27 | dough rest timer 45 | timer "Dough rest", 45 min |
| A28 | cook carbonara | starts cooking Spaghetti carbonara |
| A29 | make dal | starts cooking Weeknight dal |
| A30 | cook chilli | starts cooking Chilli con carne |
| A31 | carbonara thursday | dated task "Cook Spaghetti carbonara", Thursday, linking the recipe |
| A32 | cook dal tonight | dated task tonight, linking Weeknight dal |
| A33 | make chilli sat | dated task Saturday, linking Chilli con carne |
| A34 | shop | starts the shop |
| A35 | out of milk | groceries ["milk"]; with Pantry state (slice P) it also sets milk out, receipt "Milk, out. On Groceries." (`kitchen-v2-acceptance.md` P13) |
| A36 | need eggs | groceries ["eggs"] |
| A37 | we're out of coffee | groceries ["coffee"]; same state rule as A35 |
| A38 | buy 1 (400 g) tin coconut milk | groceries, 1 line, pack size kept out of the name (after Paste hardening) |
| A39 | buy milk during a live workout | groceries; not a set, even with `context.entry` set |
| A40 | 3 lemons during a live workout | groceries ["3 lemons"]: a number followed by a known ingredient is never a relative set (a bare "3" still is) |

## B. Look like groceries, aren't (20)

| # | Phrase | Expected |
|---|---|---|
| B1 | get mum a card | task "Get mum a card" (a gift errand, not groceries) |
| B2 | buy present for mum fri | task "Buy present for mum", Friday |
| B3 | get haircut | task "Get haircut" |
| B4 | get car washed | task "Get car washed" |
| B5 | buy train tickets | task "Buy train tickets" |
| B6 | get flu jab | task "Get flu jab" |
| B7 | buy flowers for Anu saturday | task, Saturday (dated buy stays a task) |
| B8 | get milk on the way home tomorrow | task "Get milk on the way home", tomorrow (dated) |
| B9 | gifts: mug for anu | list Gifts ["mug for anu"] (Lists slice 8) |
| B10 | packing: charger | list Packing ["charger"] |
| B11 | errands: return parcel thu | list Errands, item dated Thursday |
| B12 | get back to Sam | task "Get back to Sam" |
| B13 | get ready for gym | task "Get ready for gym" |
| B14 | buy time with the landlord | task (not groceries) |
| B15 | get the bins out | task "Get the bins out" |
| B16 | buy new trainers | task "Buy new trainers" (not a food or household item) |
| B17 | get a new phone case | task |
| B18 | buy a birthday cake for dad sun | task, Sunday |
| B19 | note buy milk | note "buy milk" (the note rule beats everything) |
| B20 | remind me to buy milk at 6 | task "Buy milk", 18:00 |

**Rule of thumb these rows encode:** `buy`/`get` goes to groceries only when the object reads as food or household and there is no date. A gift, a service, a person or an event makes it a task. A named list prefix always wins. B16 and B17 depend on the aisle words; if Core's `looksLikeGroceries` can't tell, a task is the safer miss, because a wrong grocery line is noisier than a task he can retype.

## C. Prices, walls and receipts (added 2026-10-17, Kitchen K3)

*Against decisions 2:09 (price strip), 2:22 (money test), 8:13 ("Private item") and the thing-first receipts (#538, #541, #638). A price never stays on a row, in a note or in a receipt; packs and amounts keep their numbers. "Groceries receipt" is "<Thing>, on Groceries." and a list receipt is "<Thing>, added to <List>".*

| # | Phrase | Expected |
|---|---|---|
| C1 | milk $4 | groceries ["milk"]; receipt "Milk, on Groceries."; no price kept anywhere |
| C2 | buy milk 4.99 | groceries ["milk"]; "4.99" is a price (decimal), stripped |
| C3 | 2 for $5 avocados | groceries ["avocados"]; the deal wording is dropped with the price |
| C4 | buy 2 lb chicken | groceries ["2 lb chicken"]; a pack/amount keeps its number |
| C5 | buy 14 oz can tomatoes | groceries ["14 oz can tomatoes"]; amounts are not prices |
| C6 | 6 eggs | groceries ["6 eggs"]; a bare number with a unit noun is plain (2:22 money test) |
| C7 | rent 2100 fri | no grocery row; private dated note; the Bar says the private line, never the amount |
| C8 | $40 at costco | no grocery row; private dated note (a line that is only money) |
| C9 | pay rent 2100 fri | task "Pay rent", Friday; amount stripped; receipt "Pay rent, Friday." |
| C10 | paid rent 2100 fri | private dated note (past tense), not a task |
| C11 | buy lemons 3 | groceries, the 3 kept as a count ("lemons 3" or "3 lemons"); never money (no sign, under 3 digits, no money verb) |
| C12 | bought shoes 120 | private note (money verb next to a bare number), not a task and not groceries |
| C13 | errands: ibuprofen | list Errands ["ibuprofen"] stays an item (meds stay items on lists); the Bar line is "Private item, on Errands."; never sent to Claude |
| C14 | packing: passport 1234567 | list Packing; the line shows "Private item", the number never appears in any text, receipt or Home line |
| C15 | buy milk, door code 4417 | the whole phrase goes to the walls first: private note, "Private note"; no grocery row, nothing sent to Claude |
| C16 | out of milk $4 | groceries ["milk"] with state out; the price is stripped as in C1; receipt "Milk, out. On Groceries." |

**C11 note:** the row is a trap for the money test. If Core reads "lemons 3" as money, that is a fail; the pass is any grocery line that keeps the 3 as a count and shows no money wording.
