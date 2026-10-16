# Money ship list: second slice for M5 (engine-first)

**Approved by Product, 2026-10-15 19:07,** from Research's draft (`../research/ship-list-m5-money-draft.md`) with all seven defaults taken. Comes after Reading (`../product/ship-list-m5-reading.md`). Same rules as `../product/ship-list-lists.md` and `../product/ship-list-kitchen.md`: small end-to-end slices, velocity over perfection, engine first so Core can start now. **Engine** = logic and tests only; **Feature screen** = a self-contained screen in its own `Features/Money/` folder that meets the UI bar (no cards, pills, capsules or stock lists). Source: the Money part of `m5-money-reading.md` and row 2 of `next-areas.md`, smallest version only. Owners: **Core** builds engine slices, **Builder B** builds screens. Checked against `origin/master` at `285b34a`: there is no Money code, class or doc on master yet, and Reading is not on master either.

**The idea in one line.** A spend is one number logged like a set: "spent 12.40 lunch" in the ghost row, or the receipt total when a shop finishes. The only new class is `Spend`. It reuses `ObjectStore`, the op log and undo, the ghost row and `TessCaptureEngine`, `FinishShop` and the Groceries list as they are. No budgets, no limits, no red.

**Amounts are stored as typed (Kaushik's default).** There is no home currency yet. An amount keeps the currency it was said in, or none. Nothing is converted, and nothing is ever summed across currencies.

**Progressive disclosure rule.** A spend opens as its amount and its word ("12.40 lunch"). Date, currency, links and the typed text are one gesture away. The month shows one line; the list of spends behind it is one gesture away. No charts, no budgets, no streaks.

**Parse order for M5 (decisions.md, 4:10 PM PT):** notes, pasted recipes, relative sets, then reading, money, people, then comma sets, lifts and kitchen, then upkeep, then tasks.

## Slices

| # | Slice | Done when | Type | Owner |
|---|---|---|---|---|
| 1 | **Spend class and actions** | `SystemCatalog.Key.spend` (parent `thing`): amount (`.number`, for sorting and formulas), typed (`.text`, the amount exactly as typed: "12.40", "€8", "20 eur"), currency (`.text`, an ISO code only when said, else empty), note (`.text`), category (`.text`, one lowercased word), spentAt (`.date`), about (`.refList` to `thing`). `MoneyAmount.parse` reads `12.40`, `12,40`, `€8`, `£4.50`, `$3`, `20 eur`, `20 euros`, `23 quid`, `500 rs`, `₹500`, and maps known symbols and words to EUR, GBP, USD, INR; anything else keeps no code. `LogSpend(amount, typed, currency?, note, spentAt?, about?)`, `EditSpend` and `DeleteObject`, all undoable through the op log. Op summary reads "Spent 12.40, lunch". `LogSpend` is registered in `ActionRegistry` with name-only parameters (no `.object` arguments), so the on-device model and Claude can call it as a tool and the result is a pending ghost row | Engine | Core |
| 2 | **Spend ledger and month line** | `SpendLedger` (in `TesseraCore/Money/`, shaped like `ListContents`) returns a month's spends newest first and `monthLine(for:)`. Sums use `Decimal(string:)` of the typed digits, never `Double`, so 0.10 + 0.20 is 0.30. Totals are grouped by currency; spends with no currency form their own group. Line shape: "October, logged: 41 spends · groceries 312.40 · lunch 86.10" (count, then the top 2 categories by total). A second currency adds a second line ("€ 60.00 in 3 spends"). The word is "logged", never "you spent". A test with 0.10 + 0.20, a mixed EUR and unmarked month, and an empty month ("October: nothing logged yet") passes | Engine | Core |
| 3 | **Receipt total after a shop** | `ShopReceipt(store:).awaiting(at:)` returns the shop process ended by `FinishShop` with reason done within the last 2 hours that has no `Spend` linking it and was not skipped. `LogShopTotal(amount, typed, currency?)` logs a spend with note "Groceries", category "groceries", about [Groceries list, the ended shop process]. `SkipShopTotal` marks the shop skipped, so the question is asked once and never again. `NowPicker` gains one rule: while a total is awaited and nothing is running, Now reads "Groceries total?" A test at 1 h 59 and 2 h 01 after `FinishShop`, with and without a workout running, shows the prompt only in the first case without a workout. `FinishShop` itself is unchanged | Engine | Core |
| 4 | **Money phrases** | `TessGrammar+Money.swift`, a `.spend` parse case and a `.shopTotal` case, checked after relative sets and before comma sets and named lifts (and after reading once it lands). All phrases in the table below map as written, with their feedback line. All 15 eval rows pass, every phrase in `../product/kitchen-phrases.md`, the existing grammar tests and the `grammar-collisions.md` guard rows still parse the same | Engine | Core |
| 5 | **Receipt total instrument** | The amount dial shown when a shop finishes, see design steer | Feature screen `Features/Money/` | Builder B |
| 6 | **Spend page** | Object page for one spend, see design steer | Feature screen `Features/Money/` | Builder B |
| 7 | **Month page** | The Money front page: the month line, and the spends behind it, see design steer | Feature screen `Features/Money/` | Builder B |

Build order: 1 → 2 → 4 → 3; screen 6 after 1, 7 after 2, 5 after 3.

## Capture phrases (slice 4)

| Phrase | Maps to | Feedback line |
|---|---|---|
| `spent 12.40 lunch`, `spent 12.40 on lunch`, `spent 12.40 for lunch` | `LogSpend` 12.40, no currency, note "lunch", category "lunch", now | "Logged 12.40, lunch. 1st this month." |
| `12.40 lunch` (two decimal places, or a currency symbol) | as above | as above |
| `spent 20 eur taxi`, `€20 taxi` | `LogSpend` 20 EUR, typed as said | "Logged €20, taxi." |
| `spent 12.40 lunch with sam` | note "lunch with sam", category "lunch" (first word) | "Logged 12.40, lunch with sam." |
| `spent 30 dinner sat`, `spent 8 parking yesterday` | `LogSpend` dated the most recent past Saturday, or yesterday | "Logged 30, dinner, Sat 10 Oct." |
| `38.20`, `total 38.20`, `£38.20` (a total awaited) | `LogShopTotal` | "Groceries, 38.20. Logged." |
| `skip`, `no total` (a total awaited) | `SkipShopTotal` | "No total. Fine." |

Rules:
- Phrases are ghost rows like everything else: pending, commit after 2 s or on tap, undo.
- `spent` is an explicit prefix (collision rule 1): it binds only when an amount follows. "spent the day at the beach sat" has no amount and goes on to the task grammar unchanged.
- Without `spent`, an amount needs a money shape: exactly two decimal places (12.40) or a currency symbol or word. A whole number with a word ("450 groceries") is not a spend in the grammar; it goes to the model, which can call `LogSpend`.
- An amount with two decimal places and no reps is never a set. "6.50 cab" and "spent 8.50 bar" are spends, never Cable Fly or Parallel Bar Dip (collision rule 6, whole words only, and no reps means no set).
- `W x R`, `W for R` and anything with a second number after the amount stay with training. During a live workout, relative sets run first, so "80 x5", "8" and "same" never become spends.
- A spend date is never in the future. A future day cue ("tomorrow", "fri" when Friday is ahead and not today) means the phrase is not a spend and goes on to the task grammar ("pay rent 650 fri" stays a task).
- A day cue in a spend means the most recent past occurrence, the reverse of tasks. "today" and "yesterday" are stripped from the note.
- A bare amount ("38.20") is a total only while a total is awaited. Otherwise it is not a spend: during a workout the relative set rule keeps whole numbers, and "38.20" goes to the model.
- Messy phrases ("lunch with sam was 23 quid", "450 groceries") fall through to the model step. With Claude switched on (`tess-model-layer.md`), Claude calls `LogSpend` by name and the result is a pending ghost row marked "via Claude". With no model, the line is "Didn't catch that. Try: spent 12.40 lunch."

## Eval phrases (15)

Clock: Thu 15 Oct 2026, 18:00 Europe/London, the `grammar-collisions.md` fixtures. A context is idle unless stated. "Model" means the grammar returns nil and the phrase goes to the model step.

| # | Phrase | Context | Expected |
|---|---|---|---|
| 1 | `spent 12.40 lunch` | idle | spend 12.40, no currency, category lunch, 15 Oct |
| 2 | `spent 4.50 on coffee` | idle | spend 4.50, category coffee ("on" dropped) |
| 3 | `12.40 lunch` | idle | spend 12.40, category lunch |
| 4 | `spent 20 eur taxi` | idle | spend 20 EUR, typed "20 eur", category taxi |
| 5 | `€8 parking yesterday` | idle | spend 8 EUR, category parking, 14 Oct |
| 6 | `spent 30 dinner sat` | idle | spend 30, category dinner, Sat 10 Oct, not a task |
| 7 | `38.20` | 1 h after `FinishShop` | shop total 38.20, linked to Groceries and the shop |
| 8 | `38.20` | workout live, no total awaited | no spend, no set (model) |
| 9 | `80 x5` | workout live | trap: set 80 x 5, not a spend |
| 10 | `bench 82.50 x 8` | idle | trap: lift Bench Press 82.5 x 8, not a spend |
| 11 | `spent 8.50 bar` | idle | trap: spend 8.50, category bar, never Parallel Bar Dip |
| 12 | `6.50 cab` | idle | trap: spend 6.50, category cab, never Cable Fly |
| 13 | `milk, eggs, 2 lemons` | shop running | trap: groceries, 3 lines (kitchen unchanged) |
| 14 | `pay rent 650 fri` | idle | trap: task "Pay rent 650", Fri 16 Oct, not a spend |
| 15 | `lunch with sam was 23 quid` | idle, Claude on | model: ghost row spend 23 GBP, category lunch, "via Claude"; with no model, "Didn't catch that." |

As Swift Testing rows, beside `collisionRows`: `.init("spent 12.40 lunch", .idle, "spend 12.40 - lunch 15 Oct")`, `.init("80 x5", .workout, "set 80x5")`, `.init("38.20", .shopFinished, "spend.total 38.20 Groceries")`, and so on. `Ctx` gains `.shopFinished`.

## Design steers (one per screen)

Shared: light ground, the house paper and washes; Design picks the Money lean in its build sheet. Vermilion only for something running, cobalt only for Tess. Never red for an amount. Amounts are tabular figures, set as typed ("€20" stays "€20").

**5. Receipt total instrument.** When a shop finishes, the Groceries page folds away and one question stays: "Total?" in Body. Under it the **amount dial**, the weight dial's sibling: whole units on the drum, cents on a second smaller drum, and a typed field behind a tap for people who would rather type. Release commits as a ghost row ("Groceries, 38.20. Logged."). Skip is one word under it, calm copy. The same prompt is the Now slot for 2 hours.

**6. Spend page.** The hero is the amount, as typed. One context line in Body: "lunch · Thu 15 Oct, 13:10". The word is a tag that edits in place; date, currency, note and links (the shop, the Groceries list) sit one level deeper, never a form. Delete is a swipe with undo.

**7. Month page.** The month line is the hero: "October, logged" in Title tier, then the count and the top categories as one sentence. Behind it, one gesture away, the spends as a typographic ledger: day numerals in the left margin, amount in 600 and word in 400, no rows, no separators. Other currencies follow as their own short ledger. Pinch out to the previous month. No budget, no chart, no "left to spend". Empty state is one cobalt line from Tess: "Tell me what you spent. Try: spent 4.50 coffee."

## Depends on

- From master: `ObjectStore`, `SystemCatalog`, the op log and undo, `DeleteObject`, the ghost row and `TessCaptureEngine`, `ActionRegistry` (for the model tools), `FinishShop` and the Groceries list (`Groceries.listID`), `ProcessTable` (ended shops) and `NowPicker`.
- `grammar-collisions.md` rules 1, 6 and 9. Money needs no `TessContext.process` (rule 4): the awaited total is read from the store with `context.now`.
- Nothing from Reading is required. If Reading lands first, the money check sits after it in `TessGrammar.parse`; the two share no verbs.
- M4 slice 5 (Day log) is not on master. The op summaries ("Spent 12.40, lunch", "Groceries, 38.20") are written now so the Day log can show "Spent 3 times, 26.90 (lunch, coffee, taxi)" when it lands.
- The Claude route (`tess-model-layer.md`) is optional: without it, messy phrases go to the on-device model or get "Didn't catch that."

## Later

Beyond the smallest version, not in this list:
- A home currency and conversion (needs Kaushik's answer and a rate source, which is a network call).
- A `Category` class with merging and renaming (research pitfall 2); until then category is one word.
- Places and shops as objects (`450 groceries @Tesco`), and a spend linked to a person.
- Receipt scan of the total with VisionKit, on device.
- Split phrases ("spent 12.40 lunch and 3 coffee"), recurring spends (rent, subscriptions), refunds.
- The Day log line, once M4 slice 5 lands; a month widget; Shortcuts and Siri for "log a spend".
- Bank data through FinanceKit (needs a paid account and an App Store Finance app; parked with iCloud sync).
- Anything that looks like a budget: limits, envelopes, "left to spend".

## Decisions (Product took every default, 19:07)

1. **Home currency?** Default: none yet (Kaushik's default). Amounts are stored as typed; a spend with no currency word is unmarked, and the month shows one line per currency plus one for unmarked.
2. **Bare amounts without "spent"?** Default: only with two decimal places or a currency symbol or word. "450 groceries" goes to the model, so a whole number can never steal a set, a grocery line or a page number.
3. **Where does "total?" ask?** Default: on the Groceries screen as the shop finishes, and on Now for 2 hours if nothing is running. Asked once; skip or ignore and it never comes back.
4. **Is category a text word or a class?** Default: one lowercased word on the spend (the note's first word). A `Category` class with merging is Later.
5. **Ordinal in the feedback line ("14th this month")?** Default: yes, it is a count, not a judgement. No other counts on capture.
6. **Money app or Home only?** Default: its own small app, `Features/Money/`, joining Reading on the sibling rail when both exist.
7. **Bank data?** Default: stays parked (`m5-money-reading.md` question 3).

## Open questions for Kaushik (4:10 PM PT, on the coordinator's morning list; defaults hold until he answers)

1. **A shop or merchant field on a spend?** Default: no separate field yet. "38.20 at Tesco" keeps "at Tesco" in the spend's text, so nothing is lost and a field can be filled from it later.
2. **Currency codes beyond EUR, GBP, USD and INR?** Default: just those four, plus their symbols. Anything else goes to the model, which can still log it as typed.
3. **Can a bare "38" answer a waiting shop total?** Default: yes, but only while the shop-total question is the open one on screen and no workout is running, so it can never become a set.
4. **Does "paid" work like "spent"?** Default: yes when an amount follows ("paid 650 rent"). If it names a chore, that chore is ticked in the same ghost row. "paid rent" with no amount stays an upkeep check-in.
5. **A split: the full amount or his share?** Default: his share ("split 60 with Sam" logs 30), with "split, 60 total" kept in the text.
