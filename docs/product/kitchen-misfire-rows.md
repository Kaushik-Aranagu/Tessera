# Kitchen rows for the grammar misfire sweep

*Kitchen lead, 2026-10-15. For Research's `fixtures/grammar-misfires.md`, so Core's grammar fix batch can't break the kitchen. Part A has 40 phrases that must stay kitchen (groceries, timer, cook, recipe); part B has 20 that look like groceries but aren't. Recipes assumed: "Spaghetti carbonara", "Chilli con carne", "Weeknight dal". No live workout unless noted. "groceries [..]" means items added to the one grocery list.*

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
| A35 | out of milk | groceries ["milk"] (until pantry P exists) |
| A36 | need eggs | groceries ["eggs"] |
| A37 | we're out of coffee | groceries ["coffee"] |
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
