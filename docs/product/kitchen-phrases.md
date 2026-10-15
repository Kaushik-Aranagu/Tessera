# Kitchen and list phrases: expected results

*Kitchen lead, 2026-10-15. 50 phrases for Core's `KitchenCaptureTests` / `TessTests`. "Lists" rows depend on `ship-list-lists.md` slice 8 and can be skipped until it lands. Recipes assumed: "Spaghetti carbonara", "Chilli con carne", "Weeknight dal"; lists: Groceries, Packing; the running process noted where it matters.*

| # | Phrase | Expected | Today |
|---|---|---|---|
| 1 | buy milk | groceries ["milk"] | ok |
| 2 | buy milk and eggs | groceries ["milk", "eggs"] | ok |
| 3 | get 2 lemons | groceries ["2 lemons"] | ok |
| 4 | milk, eggs, 2 lemons | groceries, 3 lines | ok |
| 5 | eggs, bread and 2 lemons | groceries, 3 lines | ok |
| 6 | 500 g mince, onions | groceries, 2 lines | ok |
| 7 | groceries: kitchen roll | groceries ["kitchen roll"] | ok |
| 8 | add to groceries: oat milk | groceries ["oat milk"] | ok |
| 9 | buy present for mum fri | task "Buy present for mum", Friday | **fails** (acceptance fix 1) |
| 10 | get haircut thu 3pm | task "Get haircut", Thursday 15:00 | **fails** (fix 1) |
| 11 | call mum, dentist | not groceries (task or nothing) | **fails** (comma rule) |
| 12 | bench 80x8, 82.5x6 | lift sets, not groceries | **fails** (fix 2) |
| 13 | cook carbonara | start cooking Spaghetti carbonara | ok |
| 14 | make chilli | start cooking Chilli con carne | ok |
| 15 | cook carbonara thu | task "Cook spaghetti carbonara", Thursday, about the recipe | ok |
| 16 | carbonara friday 7pm | task, Friday 19:00, about the recipe | ok |
| 17 | dal tomorrow | task "Cook weeknight dal", tomorrow | ok |
| 18 | cook lasagne | nothing kitchen (no such recipe); falls to task "Cook lasagne" | check |
| 19 | make dentist appointment thu | task, not a cook | ok |
| 20 | cook carbonara (already cooking it) | resume the open cook, no second one | **fails** (fix 5) |
| 21 | timer pasta 10 | timer "Pasta", 10 min | ok |
| 22 | pasta timer 10 | timer "Pasta", 10 min | ok |
| 23 | 10 min timer | timer "Timer", 10 min | ok |
| 24 | timer 1 hour | timer "Timer", 60 min | ok |
| 25 | timer rice 12 minutes | timer "Rice", 12 min | ok |
| 26 | set a timer for 5 min | timer "Timer", 5 min | ok |
| 27 | timer 90 seconds | timer "Timer", 1.5 min | **fails** (seconds unsupported) |
| 28 | timer eggs (while cooking) | nothing (no length); no crash | check |
| 29 | timer sauce 20 (while cooking carbonara) | timer linked to the cook | ok |
| 30 | shop | start the shop | ok |
| 31 | at the shop | start the shop | ok |
| 32 | shopping | start the shop | ok |
| 33 | list: packing | new list "Packing" | ok |
| 34 | new list films | new list "Films" | ok |
| 35 | list | nothing | check |
| 36 | (pasted recipe with "Ingredients" heading) | recipe ghost, "N ingredients, M steps." | ok |
| 37 | (pasted recipe with no heading) | not a recipe through the ghost row; use the Paste surface | ok |
| 38 | note: dal needed more salt @[Weeknight dal] | note linked to the recipe | ok |
| 39 | buy | nothing | check |
| 40 | get | nothing | check |
| 41 | packing: charger, socks | add 2 items to Packing | Lists slice 8 |
| 42 | add charger to packing | add "charger" to Packing | Lists slice 8 |
| 43 | add milk to groceries | groceries ["milk"] | Lists slice 8 |
| 44 | run packing | start a run of Packing | Lists slice 8 |
| 45 | pack | start a run of Packing (the only list starting "pack") | Lists slice 8 |
| 46 | reset packing | uncheck all on Packing (reusable) | Lists slice 8 |
| 47 | pick from films | pick one open item from Films | Lists slice 8 |
| 48 | what should I watch | nothing in grammar-only Tess (no guessing) | Lists slice 8 |
| 49 | todo buy bulbs | task in Later (todo wins over buy) | check |
| 50 | buy milk tomorrow | task "Buy milk", tomorrow (dated buy is a task) | **fails** (fix 1) |
