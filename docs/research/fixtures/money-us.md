# Money fixtures, US

For: Core (M5 Money slices 1 to 4: `MoneyAmount.parse`, `LogSpend`, `LogShopTotal`, `TessGrammar+Money.swift`) and Builder A (Money screens: the amount dial, the spend page, the month page). Owner: Research lab. Date: Oct 16, 2026 (Pacific). Board item 129.

These are 30 rows for how Kaushik will log spending in the US: receipts, "at Trader Joe's", tips, sales tax, unit prices that are never spends, refunds, Venmo, rent and card subscriptions. They add to `money.md` (rows 1 to 62) and never repeat one; where a US row confirms an older row, the last column names it. Traced by hand against `origin/master` at `2190dcf`, not run. There is still no Money code on master: no `Spend` class, no `LogSpend`, no money tool in `TessTools`.

## How to read the tables

**Rules that bind (decisions.md and the Oct 22 defaults).**
- Currency comes only from a symbol or word said ($, €, £, ₹, "bucks"). Never from the phone's region or zone, so "costco 212.37" has no currency even in California. Nothing is converted or summed across currencies.
- A shop name stays in the text, kept whole ("trader joe's", shown "Trader Joe's"); an "at X" shop leaves the category empty (10:14 PM PT).
- A bare "38" answers "Groceries total?" only while that ask is on screen and no workout runs (Q6 default).
- "paid" works like "spent" when an amount follows (Q7 default, and 4:34 PM PT).
- A split logs his half: "split 60 with Sam" logs 30 with "split, 60 total" in the text (Q8 default).
- A unit price is never a spend (M12, 10:14 PM PT).
- Money stays on the phone. No money phrase or spend goes to Claude, for capture or for memory (8:21 PM PT).
- Tess never grades spending: no "a lot", no "over", no red, no budget words.

**Tess lines.** Name first, then what happened (tess-voice rule 1, M33): the spend is named as it shows on its page, amount then word ("6.25 coffee, logged."). With a shop said: "$38.20 at Trader Joe's, logged." UNDO says "{same name} taken back." Digits, US format ("$4.99"), the amount as typed, no ellipsis. The "1st this month" ordinal (Decision 5) is left off, as in `money.md`. An ask is a short statement with a "?" and two ink words.

**Kinds.** spend, refund (money back, never a negative spend and never netted against spends), recurring (a spend that repeats). Refunds and recurring are Later in the ship list, so rows with those kinds are proposals (gaps MU8, MU9).

**Clock and contexts.** Fri Oct 16, 2026, 6:10 PM PT. "sat" in a spend is Sat Oct 10; "sat" in a task is Sat Oct 17; "mon" is Mon Oct 19. Contexts as `money.md`: **I** idle, **A** a shop ended 1 h ago and "Groceries total?" is on screen, **S** a shop running, **P** a receipt photo (OCR rows split by `/`), **C** idle with a Claude key saved and "Tess asks Claude" on.

**Master today.** "G:" is `TessGrammar.swift`, "K:" is `TessGrammar+Kitchen.swift` at `2190dcf`. **Miss** means the grammar returns nil and `TessRouter` (`TessModel.swift:67-93`) hands the phrase to the on-device model, whose tools can only log a set, write a task, a note or a grocery line (`TessTools.swift:88-232`); then to Claude when C holds (`ClaudeTessModel.swift:45` checks only the key, the switch and the pause); then "Didn't catch that." The money guard (G:109-113) misses on purpose for a phrase that starts with spent, spend, paid, pay, cost, bought or a sign and a digit. `isMoney` (K:79-84) strips a sign-amount-slash-word unit price before looking for a sign.

## Rows

### Shop totals and receipts

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US1 | A | `38` | spend (shop total) · 38 · typed "38" · no currency · "Groceries" · Oct 16, linked to the list and the shop | "Groceries, 38, logged." | Miss. No total ask exists yet (slice 3), and "38" with no entry matches no rule | 34 (now Q6 default) |
| M-US2 | A | spoken "Thirty eight twenty." | spend (shop total) · 38.20 · typed "38.20" · none · "Groceries" | "Groceries, 38.20, logged." | Miss. Outside a workout spoken numbers stay words (`BottomChrome.swift:632` runs `TessSpoken.numbers` only with a session), so the grammar sees "thirty eight twenty" | SN 61 |
| M-US3 | P with A | Receipt `COSTCO WHOLESALE #0423 / KS WATER 24PK 4.99 / INSTANT SAVINGS 1.50- / SUBTOTAL 198.40 / TAX 13.97 / **** TOTAL 212.37 / VISA XXXX 212.37 / CHANGE 0.00` | Ask, dial at 212.37, high confidence (subtotal plus tax equals it). Tap: spend (shop total) · 212.37 · typed "212.37" · none · "Groceries, Costco" | "Costco, 212.37?" then "Groceries, 212.37, logged." | No receipt OCR on master | 38, 57 |
| M-US4 | P with I | Receipt `BAR ROSA / SUBTOTAL 53.50 / TAX 4.87 / TOTAL $58.37 / 18% 10.51 / 20% 11.67 / 22% 12.84 / TIP ____ / TOTAL ____` | Ask, dial at 58.37, low confidence (a blank tip line). He turns it to what he paid; release: spend · as released · USD · "Bar Rosa" | "Bar Rosa, $58.37 plus tip?" | No receipt OCR on master | 57 |

### Everyday spends, word first

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US5 | I | `trader joes 38.20` | spend · 38.20 · "38.20" · none · "trader joes" · Oct 16 | "38.20 trader joes, logged." | Miss. No exercise word, no day. Under approved M7 it stays a model row after Money (MU1) | 53 (locale guard) |
| M-US6 | I | `costco 212.37` | spend · 212.37 · "212.37" · none · "costco" | "212.37 costco, logged." | Miss, as M-US5 | 42 (M7) |
| M-US7 | I | `uber 23.40` | spend · 23.40 · "23.40" · none · "uber" | "23.40 uber, logged." | Miss, as M-US5. "uber" is no exercise word | 7 |
| M-US8 | I | `coffee 6.25` | spend · 6.25 · "6.25" · none · "coffee" | "6.25 coffee, logged." | Miss, as M-US5 | 2 |
| M-US9 | I | `coffee 6.25 today` | spend · 6.25 · none · "coffee" · Oct 16 ("today" leaves the text) | "6.25 coffee, logged." | **Wrong write:** task "Coffee 6.25", today. No verb or leading sign, so the guard passes; `TessDates.find` reads "today" (G:556) and `parseTask` (G:461) takes it | 11, 21 |
| M-US10 | I | `trader joe's 38.20 sat` | spend · 38.20 · none · "trader joe's" · Sat Oct 10 | "38.20 trader joe's, logged. Sat Oct 10." | **Wrong write:** task "Trader joe's 38.20", Sat Oct 17. The guard only covers a leading verb or sign; `parseCook` finds no recipe; `parseTask` takes "sat" | 54 (fixed only for a leading "spent" or "$") |

### Tips and sales tax

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US11 | I | `dinner 64 plus tip 13` | spend · 77 · typed "64 plus tip 13" · none · "dinner, tip 13" | "77 dinner, logged. 64 plus 13 tip." | Miss. Under approved M11 (second number) it stays a model row (MU5) | 50 (M11) |
| M-US12 | I | `dinner 64 tip 20%` | Ask. LOG: spend · 76.80 · typed "64 tip 20%" · none · "dinner, tip 20%". 64 ONLY: spend 64 | "Dinner 64 plus 20% tip, 76.80?" | Miss | none |
| M-US13 | I | `shirt 24.99 plus tax` | spend · 24.99 · "24.99" · none · "shirt, plus tax". Tess never adds a guessed tax rate | "24.99 shirt, logged." | Miss | none |
| M-US14 | I | `tax 3.10` | Ask. LOG: spend · 3.10 · none · "tax". NOT NOW: nothing | "3.10 tax, its own spend?" | Miss | none |

### Unit prices, never spends

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US15 | I | `$4.99/lb` | No write | "$4.99/lb is a price. Nothing logged." | Miss. `isMoney` strips the unit price (K:82), so the guard passes; nothing else claims it. The model step may still write a note or grocery line | 58 |
| M-US16 | S | `2 for $5` | No write: no spend, no grocery line, never 2 x 5 | "2 for $5 is a price. Nothing logged." | Miss: the shop rule skips money (G:236); the bare-set rule needs digits after "for". Line "Didn't catch that. Try "milk, eggs"." | 59 |
| M-US17 | I | `bananas 0.19 each` | No write ("each" is a unit price) | "0.19 each is a price. Nothing logged." | Miss. Under approved S4 it would log 0.19 bananas only if word-first were allowed (MU1, MU7) | 58 |

### Refunds

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US18 | I | `refund 19.99 amazon` | refund · 19.99 · "19.99" · none · "amazon" · Oct 16 | "19.99 back from amazon, logged." | Miss | 47 (Later until MU8) |
| M-US19 | I | `got 19.99 back from amazon yesterday` | refund · 19.99 · none · "amazon" · Thu Oct 15 | "19.99 back from amazon, logged. Thu Oct 15." | **Wrong write:** note "Got 19.99 back from amazon", Oct 15 12:00. "got" is a past verb (G:287) and `pastDay` reads "yesterday" (G:658) | 48 (M10) |

### People: Venmo and splits

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US20 | I | `venmo sam 30 for pizza` | spend · 30 · "30" · none · "venmo sam, pizza". The link to Sam is Later | "30 to Sam for pizza, logged." | Miss. No exercise in "venmo sam pizza" | 49 |
| M-US21 | I | `sam venmoed me 30` | refund · 30 · none · "from sam, venmo" | "30 back from Sam, logged." | Miss. "sam" is not a past verb, so no note | none (MU8) |
| M-US22 | I | `dinner 84.60 split with sam` | spend · 42.30 · typed "84.60" · none · "dinner, split, 84.60 total" | "42.30 dinner, logged. Your half of 84.60." | Miss | 49 changes: Q8 default logs the half |

### Rent and cards

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US23 | I | `paid rent 2400` | spend · 2400 · "2400" · none · "rent". Ticks a "rent" chore in the same ghost row if one exists | "2400 rent, logged." | Miss (guard G:110, leading "paid") | 25 (now decided) |
| M-US24 | I | `pay the apple card bill mon` | task "Pay the apple card bill", Mon Oct 19 9:00 AM. Not money: no amount | "Pay the apple card bill, Monday." | **Lost task:** miss. `isMoney` is true for a leading "pay" with no amount (K:83), so the guard drops it | 24 (regressed) |
| M-US25 | I | `paid apple card 1,240.18` | Ask. A card bill pays off spends already logged, so it isn't one by default. LOG: spend 1240.18 · "apple card bill". NOT A SPEND: nothing | "Apple Card bill, 1,240.18. Log it as a spend?" | Miss: comma sets find no lift, then the guard | 15 (grouping) |

### Subscriptions

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US26 | I | `netflix 15.49 monthly` | recurring · 15.49 · "15.49" · none · "netflix" · every month from Oct 16. The next one waits as a ghost row on Nov 16, never logged by itself | "15.49 netflix, logged. Every month." | Miss | none (MU9) |
| M-US27 | I | `spotify $11.99/mo on apple card` | recurring · 11.99 · "$11.99/mo" · USD · "spotify, apple card" · monthly. The card stays in the text | "$11.99 spotify, logged. Every month." | Miss. `isMoney` strips "$11.99/mo" as if it were a unit price (K:82) | 58 (M12 too wide) |
| M-US28 | I | `$12.99/mo` | Ask, nothing logged yet | "$12.99 a month, for what?" | Miss | none |

### Privacy and questions

| # | Ctx | He says | Expected record or ask | Tess line | Master today | Confirms |
|---|---|---|---|---|---|---|
| M-US29 | C | `lunch with sam was 18 bucks` | spend · 18 · "18 bucks" · USD · "lunch with sam", by the on-device model only. Zero Claude requests | "18 bucks lunch with sam, logged." | **Sent to Claude:** the on-device model has no spend tool, so the router passes the phrase to Claude. Any money miss does the same while C holds | 17, 61 (eval 15 conflicts) |
| M-US30 | C | `how much did i spend at costco this month` | No write. Answered on the phone from the ledger, as a count, never a judgement | "Costco, 1 spend in October: 212.37." | Question guard (G:74), then the model's answerQuery, then Claude while C holds | 11 (collision) |

Count: 30 rows. Today on master: 3 wrong writes (M-US9 and M-US10 tasks, M-US19 a note), 1 lost task (M-US24), 1 phrase sent to Claude (M-US29, and every other miss while C holds). The other 25 are misses with no money write. After the approved S4 rules, 10 rows would still go to the model unless MU1 and MU5 land (M-US5 to M-US10, M-US11, M-US13, M-US14, M-US17).

## Gaps

| # | Where | Gap | Proposed default | Owner |
|---|---|---|---|---|
| MU1 | S4 rule M7 | He types the word first ("costco 212.37", "uber 23.40"), but M7 sends any word-then-amount to the model | A money-shaped amount (two decimals, or a sign or currency word) as the last number, after words that are no exercise and carry no kitchen unit, is a spend when no shop runs. "milk 1.20" (row 42) becomes a spend too | Core, Product approves |
| MU2 | `TessRouter`, `ClaudeTessModel.isAvailable` | Money misses reach Claude today; the ship list's eval 15 even expects "via Claude" | A phrase where `isMoney` or a money shape holds skips Claude; the on-device model takes it or "Didn't catch that." Spends never enter Claude's context or memory. Strike eval 15's Claude route | Core, Product |
| MU3 | Guard G:109-113 | A word-first amount with a day becomes a task ("coffee 6.25 today", "trader joe's 38.20 sat") | Until Money: a two-decimal amount with a day cue and no task verb is a miss. With Money: a spend on the most recent past day | Core |
| MU4 | `isMoney` K:83 | "pay" alone counts as money, so "pay the apple card bill mon" is lost | "pay" counts only with an amount; with none it goes on to tasks, as row 24 expects | Core |
| MU5 | S4 rule M11 | Tips are a second number, so they go to the model | "plus tip N", "+ tip N", "tip N" add to the amount; "tip N%" asks with the sum (M-US12). Tess never adds a tip by herself | Core, Product |
| MU6 | S4 | Sales tax | Never guessed. "plus tax" stays in the text; a bare "tax N" asks | Product |
| MU7 | `isMoney` K:82, M12 | M12 misses "2 for $5", "each", "ea", and wrongly takes "/mo", "/month", "/yr" as unit prices | Unit price: "/lb", "/oz", "/ea", "per lb", "each", "N for $M". Recurring, not a unit price: "/mo", "/month", "/yr", "a month", "monthly", "yearly" | Core |
| MU8 | Spend class (slice 1) | Refunds and paybacks (Amazon, Venmo from Sam) | A `kind` field: spend or refund. A refund is shown apart on the month page ("1 back, 19.99"), never netted, never negative | Product, Core, Builder A |
| MU9 | Spend class, month page | Subscriptions | Kind recurring with `repeats` (monthly, yearly). Logs the first now; each next one is a ghost row on its day that waits for a tap. The spend page says "Every month" | Product, Core, Builder A |
| MU10 | S4, Q7 | "paid apple card N" would log a card bill as a spend and count it twice | A card bill asks (M-US25). The card used stays in the text; no payment field | Product |
| MU11 | `money.md` row 49 | Row 49 logs the full 60; the Q8 default logs the half | Halve with `Decimal`; keep "split, N total" in the text. Research updates row 49 after his answer | Core, Research |
| MU12 | `BottomChrome.swift:632`, `TessSpoken` | Spoken cents ("thirty eight twenty") stay words outside a workout | With a money cue or "Groceries total?" on screen, join "N M" into N.M (SN 61) | Core, Builder A |
| MU13 | CM1 `ReceiptTotal` | Costco receipts print no "$", mark savings with a trailing minus and the total with stars; restaurant slips print tip suggestions | No "$" means no currency. Trailing-minus rows, tip suggestion rows and blank TIP lines are never the pick. A blank tip line opens the dial at low confidence with "plus tip?" | Core, Builder A |
| MU14 | Ship list copy | "Logged 12.40, lunch." puts the verb first, against tess-voice rule 1 | "12.40 lunch, logged." and "$38.20 at Trader Joe's, logged."; undo "12.40 lunch taken back." | Design, Product |
| MU15 | Category (Decision 4) | Word-first shop names give half a name ("trader") | The category is the first word only when the text is one word; otherwise empty, as for "at X" | Core, Product |

Top three: MU1 (his everyday shape goes to the model), MU2 (money reaches Claude today) and MU3 (two wrong tasks today).
