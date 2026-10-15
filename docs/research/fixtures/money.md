# Money fixtures

For: Core engine (M5 Money slices 1 to 4, `MoneyAmount.parse`, `LogSpend`, `LogShopTotal`, `TessGrammar+Money.swift`), Research lab. Date: 2026-10-15.

These are 50 capture rows that expand the 15 eval phrases in the approved Money ship list (`../../product/ship-list-m5-money.md`, Product 2026-10-15 19:07). Each row gives the expected intent, amount, typed text, currency, merchant, category, note and slice. A collision table, the proposed rules and the open questions follow. Grammar facts come from a static read of `origin/master` at `e56c15e` (`TessGrammar.swift`, `TessGrammar+Kitchen.swift`, `TessCapturing.swift`, `TessCaptureEngine.swift`, `Kitchen/Quantities.swift`, `Actions/ActionRegistry.swift`). Nothing was run. There is still no Money or Reading code on master, and `LogSpend` is not in `ActionRegistry`.

## How to read the tables

**Currency rule (Kaushik's default, Decision 1).** There is no home currency. An amount keeps the currency it was said in, or none. An amount with no currency word or symbol is stored as typed and the currency field stays empty. Nothing is converted. Nothing is summed across currencies. No row below assumes pounds, rupees or any other default.

**Slice ids.** S1 Spend class and actions (`MoneyAmount.parse`, `LogSpend`), S2 Spend ledger and month line, S3 Receipt total after a shop, S4 Money phrases, S5 Receipt total instrument, S6 Spend page, S7 Month page. "S4 table" means the phrase is in the slice 4 capture table as written; "S4 rule" means one of the rules under that table. **CM1** is capture-modes slice 1, receipt photo to total (`../capture-modes.md`). **M** means the grammar returns nil and the model step gets the phrase; `LogSpend` is a model tool only after S1, so on master today an M row writes nothing. **Gap** means no slice covers it and the expected column is a proposal. **Later** means the ship list puts it in Later.

**Line refs.** "G:" is `TessGrammar.swift`, "K:" is `TessGrammar+Kitchen.swift`, "Q:" is `Kitchen/Quantities.swift`, all at `e56c15e`. "GC" is `../grammar-collisions.md` (rules by number). "SN" is `spoken-normaliser.md` (rows by number). "RF" is `reading.md`.

**Clock.** Thu 15 Oct 2026, 18:00 Europe/London, the same as `../grammar-collisions.md`. "sat" in a spend is Sat 10 Oct; "fri" in a task is Fri 16 Oct.

**Store fixture.** No spends logged in October before each row, so every logged line would end "1st this month" (Decision 5). The lines below leave the ordinal off to save space. Groceries list with milk and eggs on it. Book Dune (612 pages), reading, suspended at p 120. Exercises from the built-in catalog, including Parallel Bar Dip, Cable Fly and Barbell Row.

**Contexts.**
- **I**: idle. Nothing running, no total awaited.
- **W**: live workout, Bench Press in focus, last set 80 x 8. No total awaited.
- **A**: a shop ended by `FinishShop` (reason done) 1 h ago, no spend links it, not skipped, so a total is awaited. Nothing running.
- **WA**: as A, but a workout started after the shop is live (Bench Press in focus, last set 80 x 8).
- **S**: a shop is running (Groceries is the subject in Now, so `context.process` is `Groceries.listID`).
- **R**: Dune reading, suspended. Nothing running.
- **C**: idle, Claude switched on (`../tess-model-layer.md`).
- **P**: a receipt photo is attached (CM1). OCR text uses `/` for a new line. With A or I as stated.

**Columns.** *Typed* is the `typed` field: the amount exactly as said. *Merchant* is the shop or payee word. Spend has no merchant field in S1, so the merchant stays inside the note today; the column shows what a merchant field would hold (open question 1). *Category* is one lowercased word (Decision 4). "none" means the field stays empty.

## Proposed placement of the money rule

Slice 4 says "after relative sets and before comma sets and named lifts (and after reading once it lands)". On master that gives this order (G:52-91):

1. note (G:55)
2. pasted recipe (G:58)
3. question guard (G:62)
4. process rule (G:66): cook steps, workout rest, shop items
5. relative set (G:70)
6. reading (not on master; RF placement)
7. **money (new): `.spend` and `.shopTotal`**
8. comma sets (G:73), named lift (G:76), kitchen (G:80), reschedule (G:83), task (G:90)

Money runs on the raw phrase, not on `TessGrammar.normalize(phrase)`, because `normalize` turns every comma into a space (G:378) and "12,40" would arrive as "12 40".

## Phrase rows

### Plain amounts

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | I | `spent 12.40 lunch` | 1 | LogSpend, 15 Oct 18:00. "Logged 12.40, lunch." | 12.40 | 12.40 | none | none | lunch | lunch | M. The lift rule reads 12.40 as a weight, finds no reps, fails (G:245). No date, so no task. No spend tool on master | S4 table, S1 |
| 2 | I | `spent 4.50 on coffee` | 2 | LogSpend, 15 Oct. "Logged 4.50, coffee." | 4.50 | 4.50 | none | none | coffee | coffee | M, as row 1. "on" after the amount is dropped, as "for" is in `spent 12.40 for lunch` | S4 table |
| 3 | I | `12.40 lunch` | 3 | LogSpend, 15 Oct. "Logged 12.40, lunch." | 12.40 | 12.40 | none | none | lunch | lunch | M. No `spent`, but exactly two decimal places is a money shape | S4 rule |
| 4 | I | `12,40 lunch` | 3 | LogSpend, 15 Oct. "Logged 12,40, lunch." | 12.40 | 12,40 | none | none | lunch | lunch | M. **Comma trap:** `normalize` makes it "12 40 lunch" (G:378), and `parseCommaSets` (G:73) splits it into "12" and "40 lunch", both fail. Rule M2: money reads the raw phrase; a comma with exactly 2 digits after it and no space is a decimal mark (S1 reads `12,40`) | S1, S4 rule |
| 5 | I | `12.5 lunch` | 3 | No grammar write. M: the model may call LogSpend. No model: "Didn't catch that. Try: spent 12.40 lunch." | 12.5 (model) | 12.5 | none | none | lunch | lunch | M today and after S4. One decimal place is not a money shape, so "12.5" can never steal a plate weight. With `spent` or a symbol ("spent 12.5 lunch", "€12.5 lunch") it is a spend | S4 rule |
| 6 | I | `spent 8.50 bar` | 11 | LogSpend, 15 Oct. "Logged 8.50, bar." Never Parallel Bar Dip | 8.50 | 8.50 | none | none | bar | bar | M. No reps, so no lift; whole-word matching (G:327-331) would find Parallel Bar Dip if reps were there. Rule: an amount with two decimals and no reps is never a set | S4 rule, GC 6 |
| 7 | I | `6.50 cab` | 12 | LogSpend, 15 Oct. "Logged 6.50, cab." Never Cable Fly | 6.50 | 6.50 | none | none | cab | cab | M. "cab" is a whole word, not a prefix of "cable" (G:327-331), and there are no reps | S4 rule, GC 6 |

### Symbols, codes and words

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | I | `£12.50 lunch` | 3 | LogSpend, 15 Oct. "Logged £12.50, lunch." | 12.50 | £12.50 | GBP | none | lunch | lunch | M. "£12.50" is not a `Double`, so the lift rule keeps it as a word (G:285) and fails. Spoken "twelve pounds fifty lunch" reaches the same text through SN rule 8 | S1, S4 rule |
| 9 | I | `12.50 gbp lunch` | 4 | LogSpend, 15 Oct. "Logged 12.50 gbp, lunch." | 12.50 | 12.50 gbp | GBP | none | lunch | lunch | M. The ISO code after the amount is read by `MoneyAmount.parse` like "20 eur". The code word never reaches the note | S1, S4 rule |
| 10 | I | `spent 20 eur taxi` | 4 | LogSpend, 15 Oct. "Logged €20, taxi." | 20 | 20 eur | EUR | none | taxi | taxi | M. A whole number is fine after `spent`. Feedback shows "€20" while typed keeps "20 eur" (open question 14) | S4 table, S1 |
| 11 | I | `€8 parking yesterday` | 5 | LogSpend, Wed 14 Oct. "Logged €8, parking, yesterday." | 8 | €8 | EUR | none | parking | parking | M. `TessDates` has no "yesterday" (G:406-424), so no task today. Money strips "yesterday" from the note and dates the spend | S4 table and rules |
| 12 | I | `₹450 auto` | 3 | LogSpend, 15 Oct. "Logged ₹450, auto." | 450 | ₹450 | INR | none | auto | auto | M. A whole number with a symbol is a money shape. "auto" is not an exercise word | S1, S4 rule |
| 13 | I | `450 rs auto` | 3 | LogSpend, 15 Oct. "Logged 450 rs, auto." | 450 | 450 rs | INR | none | auto | auto | M. Lift reads 450 as a weight, no reps, fails. A whole number with a currency word is a money shape; "450 auto" with no word stays M (Decision 2). Also `Rs.450`, `rs 450`, `450 rupees` (SN row 67 writes `rs`) | S1, S4 rule |
| 14 | I | `spent 20 chf taxi` | 4 | LogSpend, 15 Oct. "Logged 20 chf, taxi." | 20 | 20 chf | none (as approved). Proposal: CHF | none | taxi | taxi | M. S1 maps only EUR, GBP, USD, INR, "anything else keeps no code", so this 20 lands in the unmarked group beside unmarked spends in other money. Proposal: store any ISO 4217 code said as a word, still never converted (open question 3) | S1, Gap |
| 15 | I | `spent 1,00,000 on the bike` | 1 | LogSpend, 15 Oct. "Logged 1,00,000, bike." | 100000 | 1,00,000 | none | none | bike | the bike | M. The commas send it to `parseCommaSets` ("spent 1", "00", "000 on the bike"), which fails, and the kitchen comma list fails ("00" has no letter, K:136). Rule M2 reads Indian and Western grouping (`1,00,000`, `100,000`) before any comma split. Category skips "the" (rule M5) | S1 (extend), S4 |
| 16 | I | `lunch was a tenner` | 15 | M: LogSpend. With no model: "Didn't catch that. Try: spent 12.40 lunch." | 10 (model) | a tenner | GBP | none | lunch | lunch | M today and after S4 (messy phrase). "tenner" means ten pounds, so GBP is from the word, not a default. Spoken, SN row 63 writes "£10"; typed passes unchanged. No tool on master until S1 | S4 rule (model), S1 |
| 17 | C | `lunch with sam was 23 quid` | 15 | M: Claude calls LogSpend, ghost row "via Claude". Claude off and no on-device model: "Didn't catch that." | 23 (model) | 23 quid | GBP | none | lunch | lunch with sam | M. Eval 15 as written. The person link to Sam is Later | S4 rule (model), S1 |

### Merchants

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 18 | I | `12 50 at tesco` | 3 | No grammar write. M asks, waits for a tap: "12.50 at tesco? Or 1250?" | 12.50 or 1250 (ask) | 12 50 | none | tesco | tesco | tesco | M. Lift reads weight 12, reps 50, word "tesco" ("at" is skipped, G:285), `resolveExercise` finds nothing. `at tesco` is not a time (G:417). Two bare numbers are not a money shape and could be 12 x 50. Spoken, SN row 61 joins "twelve fifty" only after a money cue | Gap (model), SN q6 |
| 19 | I | `spent 12.50 at tesco` | 1 | LogSpend, 15 Oct. "Logged 12.50, tesco." | 12.50 | 12.50 | none | tesco | tesco | tesco | M. A leading "at" in the note is dropped like "on" and "for" (rule M5), otherwise the first-word rule makes the category "at". The category is a shop name, not a kind of spend (open question 2) | S4 table (extend), Gap |

### Dates and tasks

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 20 | I | `spent 30 dinner sat` | 6 | LogSpend, Sat 10 Oct. "Logged 30, dinner, Sat 10 Oct." Not a task | 30 | 30 | none | none | dinner | dinner | **Wrong today:** task "Spent 30 dinner", Sat 17 Oct 09:00 ("sat" at the end is a day, K:160-168, G:414). Money runs before the task rule and reads a day cue as the most recent past occurrence | S4 table and rules |
| 21 | I | `spent 12.40 lunch thu` | 6 | LogSpend, Thu 15 Oct (today). "Logged 12.40, lunch." | 12.40 | 12.40 | none | none | lunch | lunch | **Wrong today:** task "Spent 12.40 lunch", today 19:00 (the same-day rule, G:437-443). The most recent past Thursday is today, so it is today, never 8 Oct | S4 rule (extend) |
| 22 | I | `12.40 lunch fri` | 14 | As approved: not a spend, goes on to tasks: task "12.40 lunch", Fri 16 Oct 09:00. Proposal: M instead | none | none | none | none | none | none | Task today, the same. The S4 rule says a future day cue means "not a spend" and the task grammar takes it, which makes a task titled with a price. Proposal M8: a money-shaped phrase with no `pay` verb and a future cue goes to the model (open question 6) | S4 rule, Gap |
| 23 | I | `pay rent 650 fri` | 14 | Task "Pay rent 650", Fri 16 Oct 09:00. Not a spend | none | none | none | none | none | none | Task today, the same (G:352-371). "pay" is an errand verb (K:143), not `spent`; 650 has no money shape; "fri" is ahead | S4 rule |
| 24 | I | `pay rent fri` | 14 | Task "Pay rent", Fri 16 Oct 09:00 | none | none | none | none | none | none | Task today, the same. No amount, so money never looks at it. Guard row | S4 rule (guard) |
| 25 | I | `paid rent 650` | 14 | No grammar write. M: LogSpend after S1 | 650 (model) | 650 | none | none | rent | rent | M. "paid" is not a grammar prefix (SN row 67). No date, so no task. Proposal: add `paid` as a synonym of `spent` (open question 7) | S4 rule (model), Gap |
| 26 | I | `spent the day at the beach sat` | 6 | Task "Spent the day at the beach", Sat 17 Oct 09:00, unchanged | none | none | none | none | none | none | Task today, the same. `spent` binds only when an amount follows, so money passes it on | S4 rule 1 (guard) |

### Sets and set notation

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 27 | W | `80 x5` | 9 | Set 80 x 5 into Bench Press. Not a spend | none | none | none | none | none | none | Set today (G:178). Relative sets run before money. Guard | S4 rule (guard) |
| 28 | I | `80 for 5` | 9 | No grammar write. M, as today. Never a spend | none | none | none | none | none | none | M. No exercise word, so no lift (G:245). Whole numbers with no currency are not a money shape, and `W for R` stays with training | S4 rule (guard) |
| 29 | I | `bench 82.50 x 8` | 10 | Lift Bench Press 82.5 x 8. Not a spend | none | none | none | none | none | none | Lift today (G:238). Two decimals, but `x 8` is a second number, so money passes | S4 rule (guard) |
| 30 | I | `82.50 x 8` | 10 | No grammar write. M, as today. Not a spend | none | none | none | none | none | none | M (no exercise word). Rule M3: an amount followed by `x N`, `for N` or any second number belongs to training, even with two decimals | S4 rule |
| 31 | W | spoken "185 pounds for 5." to `185 lb x 5` | 9 | Set 83.9 kg x 5, unit lb. Not a spend | none | none | none | none | none | none | Set today on the normalised text (SN row 22). **"pounds" trap:** in money "pounds" is GBP; in training it is lb. Rule M4: "pounds" is money only after a money cue or after an amount with two decimals and no reps (SN rule 8 already writes `lb` here) | S4 rule, SN 22, SN 26 |

### Shop totals and receipts

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 32 | A | `38.20` | 7 | LogShopTotal, about [Groceries list, the ended shop]. "Groceries, 38.20. Logged." | 38.20 | 38.20 | none | none | groceries | Groceries | M today (no reps, no exercise). The awaited total is read from the store with `context.now`, no `TessContext.process` needed | S4 table, S3 |
| 33 | A | `£38.20` | 7 | LogShopTotal, linked as row 32. "Groceries, £38.20. Logged." | 38.20 | £38.20 | GBP | none | groceries | Groceries | M today. The currency is kept from the symbol | S4 table, S3 |
| 34 | A | `38` | 7 | Proposal: LogShopTotal 38. "Groceries, 38. Logged." | 38 | 38 | none | none | groceries | Groceries | M today (no `context.entry`, so no relative set). The S4 table only shows "38.20". While a total is awaited and nothing runs, nothing else owns a bare whole number (open question 8) | S3, Gap |
| 35 | A | `skip` | 7 | SkipShopTotal. "No total. Fine." Never asked again | none | none | none | none | none | none | M today. Also `no total` | S4 table, S3 |
| 36 | W | `38.20` | 8 | No spend, no set. M | none | none | none | none | none | none | M today. Not a whole number, so no reps-only set (G:168); no total awaited, so no shop total; a bare amount is never a spend | S4 rule |
| 37 | WA | `38` | 8 | Set 80 x 38 into Bench Press (as today). Not a total | none | none | none | none | none | none | Set today (G:168, reps 1 to 100). Relative sets run first. Rule M6: while a workout is in front, a bare amount never answers the total; only `total 38.20` does | S4 rule, GC 4 |
| 38 | P with A | Receipt `SUBTOTAL 36.40 / VAT 1.80 / TOTAL £38.20 / VISA ****4411 38.20` | 7 | Dial opens at 38.20, high confidence. Tap: LogShopTotal. Waits for a tap, no 2 s commit | 38.20 | £38.20 | GBP | none (the shop is the link) | groceries | Groceries | No Vision code on master. `ReceiptTotal.read` picks the lowest TOTAL row, VISA equals it | CM1, S3, S5 |
| 39 | P with I | Receipt `Sub Total 1,180.00 / CGST 2.5% 29.50 / SGST 2.5% 29.50 / Grand Total ₹1,239.00 / GSTIN 29ABCDE1234F1Z5` | 7 | Spend (no shop awaited), dial at 1239.00, waits for a tap | 1239.00 | ₹1,239.00 | INR | the store name row | the store name, first word | the store name | Subtotal plus taxes equals the pick, so high confidence. GSTIN is not an amount. Currency from the symbol on the total row, never from the phone's locale | CM1, S1, S4 |
| 40 | P with I | Receipt `SUMME EUR 23,47 / BAR 25,00 / RÜCKGELD 1,53` | 7 | Spend, dial at 23.47, waits for a tap | 23.47 | EUR 23,47 | EUR | the store name row | the store name, first word | the store name | Comma decimal. BAR and RÜCKGELD are cash and change rows (CM exclusion list) | CM1, S1 |

### Groceries

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 41 | S | `milk, eggs, 2 lemons` | 13 | Groceries, 3 lines, kitchen unchanged | none | none | none | none | none | none | Groceries today: the process rule passes (has a number, `IngredientLine` finds no leading amount), comma sets fail, the kitchen comma list takes it (K:51-57). No money shape. Guard | S4 rule (guard) |
| 42 | I | `milk 1.20` | 3 | No grammar write. M. Not a grocery line and not a grammar spend | 1.20 (model) | 1.20 | none | none | milk | milk | M today. Rule M7: the grammar reads an amount only at the start or after `spent`; a word then an amount goes to the model | S4 rule, Gap |
| 43 | S | `1.20 milk` | 3 | Proposal: ambiguous. Top: grocery line "1.20 milk". Alternative: spend 1.20, milk. Waits for a tap | 1.20 (alt) | 1.20 | none | none | milk | milk | Groceries today: the process rule runs first, `IngredientLine.parse` reads 1.2 as an amount (Q:122) and takes it as a line. The same happens to `12.40 lunch` during a shop. Rule M9: in a shop run, an amount with two decimals and no kitchen unit is not auto-committed | S4, GC 4, GC 9, Gap |
| 44 | I | `buy milk 1.20` | 13 | Groceries ["milk 1.20"], as today. Not a spend | none | none | none | none | none | none | Groceries today (K:39-49). Money now runs before kitchen, so rule M1: money never claims a phrase that starts with `buy`, `get`, `groceries:`, `add` or `list:` | GC 1 (guard) |

### Reading

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 45 | R | `8.99 dune` | 3 | LogSpend, 15 Oct. "Logged 8.99, dune." No page write | 8.99 | 8.99 | none | none | dune | dune | M today (lift: no reps). Reading claims only `p N`, `reading X`, `read X`, `finished X` (RF), so "dune" alone is just the note. A link to the book through `about` is Later | S4 rule |
| 46 | R | `p 12.50` | 3 | Not a spend. Reading claims `p N`; a decimal page fails: "Didn't catch that. Dune, p 12?" | none | none | none | none | none | none | M today ("p" fails the 3-letter floor, G:331). Reading runs before money, and money never claims a phrase that starts with `p`, `pg` or `page` | S4 (reading order), RF |

### Refunds and splits

| # | Ctx | Phrase | Eval | Expected intent and feedback line | Amount | Typed | Currency | Merchant | Category | Note | Today on master, and the rule | Slice |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 47 | I | `refund 12.40 amazon` | 15 | No spend. M. With no model: "Didn't catch that." | none | none | none | amazon | none | none | M today and after S4 (the amount is not first). Refunds are Later. Nothing may log +12.40 for money coming back | Later |
| 48 | I | `12.40 refund from amazon` | 3 | Proposal: no spend, M | none | none | none | amazon | none | none | M today. **Trap inside S4:** as written, the money shape makes this a spend of 12.40, category "refund". Rule M10: money yields when the note starts with `refund`, `refunded`, `returned`, `back` or `got` | Later, Gap |
| 49 | I | `spent 60 dinner split with sam` | 1 | LogSpend 60 as typed. "Logged 60, dinner split with sam." | 60 | 60 | none | none | dinner | dinner split with sam | M today. The grammar logs what was said; it never halves. Shares and splits are Later (open question 12) | S4 table, Later |
| 50 | I | `spent 12.40 lunch and 3 coffee` | 1 | Proposal: no grammar write, M | none | none | none | none | none | none | M today. As written, S4 would log 12.40 with note "lunch and 3 coffee". Rule M11: a second number after the note sends the phrase to the model. Split phrases are Later | Later, Gap |

Count: 50 rows. Every eval phrase is covered: E1 (rows 1, 15, 19, 49, 50), E2 (2), E3 (3, 4, 5, 12, 13, 18, 42, 43, 45, 46, 48), E4 (9, 10, 14), E5 (11), E6 (20, 21, 26), E7 (32 to 35, 38 to 40), E8 (36, 37), E9 (27, 28, 31), E10 (29, 30), E11 (6), E12 (7), E13 (41, 44), E14 (22 to 25), E15 (16, 17, 47). Routes: 26 rows write money through the grammar or a receipt (a spend, a shop total, or a skipped total), 9 go to the model with no grammar write, and 15 belong to another domain or write nothing and must never become a spend. Rows waiting for a tap: 18, 38, 39, 40, 43.

## Collisions with master's grammar

| # | Existing rule | Phrase that meets it | Today on master | Proposed rule |
|---|---|---|---|---|
| 1 | Relative set (G:163-186) | `80 x5`, `38` in a workout with a total awaited | Set | **M6.** Money after relative sets. While a workout is in front, a bare amount never answers the total; only `total N` or a symbol (`£38.20`) does (rows 27, 37) |
| 2 | Named lift and scheme (G:235-253, G:238) | `bench 82.50 x 8`, `82.50 x 8`, `80 for 5`, `6.50 cab`, `spent 8.50 bar` | Lift, or no lift and M | **M3.** An amount followed by `x N`, `for N` or any second number is training, even with two decimals. Whole-word lift matching (G:327-331) already keeps cab and bar out (rows 6, 7, 28 to 30) |
| 3 | `normalize` turns commas into spaces (G:378), comma sets (G:73, G:202-233) | `12,40 lunch`, `spent 1,00,000 on the bike`, receipt `23,47` | Comma split fails, M | **M2.** Money reads the raw phrase before any comma split. A comma or dot with exactly 2 digits after it is the decimal mark; other separators are grouping (rows 4, 15, 40) |
| 4 | Mass unit words (`MassUnit(parsing:)`, SN row 22) | `185 pounds for 5`, `£12.50` said as "twelve pounds fifty" | Set; M | **M4.** "pounds" is GBP only after a money cue (`spent`, `paid`, `cost`, `£`) or after a two-decimal amount with no reps. Otherwise it is lb (row 31, SN 26) |
| 5 | Process rule, shop (G:120-129, Q:122) | `1.20 milk`, `12.40 lunch` during a shop | Grocery line | **M9.** In a shop run, an amount with two decimals and no kitchen unit is ambiguous: grocery line on top (the shop is in front, GC rule 4), spend as the one-tap alternative, no 2 s commit (row 43) |
| 6 | Kitchen `buy`/`get` (K:39-49) | `buy milk 1.20`, `get 2.50 coffee` | Groceries | **M1.** Explicit prefixes keep their owner: money never claims a phrase that starts with `buy`, `get`, `groceries:`, `add`, `list:`, `note`, `todo`, `task` or `remind` (row 44) |
| 7 | Kitchen comma list (K:51-57) | `milk, eggs, 2 lemons`, `milk 1.20, eggs 2.10` | Groceries | Money never claims a phrase with a comma outside the amount itself. Prices in a list stay in the line text (row 41) |
| 8 | Task day cues (G:352-371, `TessDates` G:393-455) | `spent 30 dinner sat`, `spent 12.40 lunch thu` | Task, Sat 17 Oct; task today 19:00 | Money runs before tasks and owns its day cue: the most recent past occurrence, today included, and "today"/"yesterday" leave the note (rows 20, 21) |
| 9 | Task day cues, future | `12.40 lunch fri`, `pay rent 650 fri` | Task | As approved: a future cue means not a spend, and the task rule takes it. **M8 (proposed):** a money-shaped phrase without `pay`/`renew`/`book` and with a future cue goes to the model, so no task is titled with a price. `pay rent 650 fri` stays a task either way (rows 22, 23) |
| 10 | Errand verbs (K:142-146) and the model step | `pay rent fri`, `paid rent 650` | Task; M | `pay` is a task verb, never a spend. `paid` goes to the model until Product decides whether it is a `spent` synonym (rows 24, 25) |
| 11 | Question guard (G:94-99) | `how much did i spend on lunch`, `spent 12.40 lunch?` | Question, no write | Keep. Guard rows; money never sees them |
| 12 | Note (G:154-159) | `note: lunch was 12.40` | Note | Keep. Guard row |
| 13 | Reading (not on master; RF placement) | `p 12.50`, `8.99 dune`, `reading 1984` | M | Money after reading. Money never claims a phrase that starts with `p`, `pg`, `page`, `read`, `reading` or `finished`. A book title in a spend note is only a word (rows 45, 46) |
| 14 | Money inside itself (S4 as written) | `12.40 refund from amazon`, `spent 12.40 lunch and 3 coffee`, `spent 12.40 at tesco` | M | **M10:** refund words in the note yield to the model. **M11:** a second number after the note goes to the model. **M5:** drop a leading `at`, `on`, `for`, `the`, `a`, `my` before taking the category word (rows 19, 48, 50) |
| 15 | Model tools (`ActionRegistry` has no `LogSpend`) | every M row | No write | `LogSpend` joins the registry in S1 with name-only parameters. Until then M rows expect no spend (SN q13) |

## Proposed rules, in short

- **M1.** Explicit prefixes (`buy`, `get`, `groceries:`, `add`, `list:`, `note`, `todo`, `task`, `remind`, `p`, `read`, `reading`, `finished`) are never money.
- **M2.** Money parses the raw phrase. The last `.` or `,` with exactly 2 digits after it is the decimal mark; other separators are grouping. Sums use `Decimal(string:)` (S2).
- **M3.** An amount followed by `x N`, `for N` or any second number belongs to training.
- **M4.** "pounds" is money only after a money cue or a two-decimal amount with no reps.
- **M5.** The note drops a leading `on`, `for`, `at`, then the category is the first word with letters, skipping `the`, `a`, `my`.
- **M6.** With a workout in front, only `total N` or a currency-marked amount answers an awaited total.
- **M7.** Without `spent`, the amount must come first and have a money shape (two decimals, a symbol or a currency word).
- **M8.** A money-shaped phrase with a future day cue and no task verb goes to the model (proposed; the approved rule sends it to tasks).
- **M9.** In a shop run, a two-decimal amount with no unit is ambiguous and waits for a tap.
- **M10.** Refund words after the amount send the phrase to the model.
- **M11.** A second amount after the note sends the phrase to the model.

Swift Testing rows, beside `collisionRows` (`Ctx` gains `.shopFinished` and `.workoutShopFinished`):

```swift
.init("12,40 lunch", .idle, "spend 12.40 - lunch 15 Oct"),
.init("₹450 auto", .idle, "spend 450 INR auto 15 Oct"),
.init("spent 20 chf taxi", .idle, "spend 20 - taxi 15 Oct"),
.init("12.5 lunch", .idle, "nothing"),
.init("82.50 x 8", .idle, "nothing"),
.init("38", .workoutShopFinished, "set 80x38"), // guard
.init("1.20 milk", .shopping, "ambiguous groceries|spend"),
.init("buy milk 1.20", .idle, "groceries [milk 1.20]"), // guard
.init("pay rent fri", .idle, "task Pay rent Fri 16 Oct"), // guard
.init("12.40 refund from amazon", .idle, "nothing"),
.init("spent 12.40 lunch and 3 coffee", .idle, "nothing"),
```

## Open questions

1. **Merchant field.** Spend in S1 has no merchant. "at tesco" ends up in the note and becomes the category (row 19). Add a `merchant` text field now, or wait for places as objects (Later)?
2. **Category from a shop name.** With rule M5, `spent 12.50 at tesco` gets category "tesco", which is a shop, not a kind of spend. Is that fine until the `Category` class lands, or should `at X` leave the category empty?
3. **ISO codes outside the four.** S1 keeps no code for "chf", "aed" or "jpy", so those amounts join the unmarked group (row 14). Store any valid ISO 4217 code as said, still never converted?
4. **One decimal place.** "12.5 lunch" goes to the model (row 5). Is that right, or is one decimal plus a non-exercise word enough?
5. **Words that carry a currency.** "quid", "tenner", "fiver" mean GBP and "rs", "rupees" mean INR. Mapping them is not a home currency, but should "bucks" mean USD, and should `MoneyAmount.parse` read "a tenner" and "a fiver" itself (row 16)?
6. **Future day cue on a money-shaped phrase.** Keep the approved rule (task "12.40 lunch", Fri) or send it to the model (M8, row 22)?
7. **"paid" as a prefix.** Add `paid` and `cost` beside `spent`, or keep them for the model (row 25)?
8. **Whole-number totals.** Should a bare "38" answer an awaited total when nothing is running (row 34)?
9. **Totals during a workout.** Rule M6 lets only `total N` or a marked amount through. Agreed?
10. **Prices during a shop.** Is "1.20 milk" in a shop run a grocery line, a spend, or ambiguous (row 43)? A spend here plus the receipt total later would count the milk twice.
11. **Refunds.** Never logged as a positive spend (rows 47, 48). When refunds land, a negative amount on Spend, or its own class?
12. **Splits.** Log what he paid (60) or his share (row 49)? The grammar logs what was said until splits land.
13. **Two bare numbers.** "12 50 at tesco" asks "12.50 or 1250?" (row 18). Is asking right, or should the model pick 12.50 when a shop name follows?
14. **Feedback shape.** "spent 20 eur taxi" shows "Logged €20, taxi." while the typed field and the design steer keep "20 eur". Should the line echo the typed text?
15. **Typed text from a receipt.** Rows 38 to 40 store the OCR token ("₹1,239.00", "EUR 23,47") as typed. Is that the right source, or should typed be what the dial shows on release?
16. **Spend times.** "spent 4.50 coffee at 9" has a past time today. Should money read `at N` as 09:00 today, or leave the time as now?
17. **Ordinal on every line.** Decision 5 adds "1st this month"; the S4 table shows it only on the first row. Every logged spend, or only the first of the day?
