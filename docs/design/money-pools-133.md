# Item 133: Money pools, the pool page and the move page (Oct 22)

Design sheet for Builder B (Money screens), after landing v2. Engine: Core's
product/kitchen-multidish-money-pools-engine-spec-oct22.md part B (Pool, Inflow, Spend with
one pool, Move with sent, fee and arrived; balances derived, never stored). Kaushik's
answer: pools by currency and source, every spend from a pool, moves record what was sent,
the fee and what arrived at the real rate; the month exact per currency plus one "about"
dollar total. Ideas: Money app page Hwy2xNkK37KjdvsCKn2ayY, "Under the hood". Lives inside
landing v2 (sheet 131, Money: one sentence, one total) and app character (sheet 127, Money
sage #8DBFA7 dark / #3F7A62 light, the decimal line and one total rule). Where this sheet
and the spec differ on words, this sheet wins; on numbers, the spec wins.

Review switch (default Off, from the spec): moneyPools. Off: no pool UI, Money as today.

## 1. The rules every pool screen keeps
- The decimal line: words left, integers right-aligned to one axis, cents hung smaller in
  ink 2. Foreign amounts carry their sign ("INR" in text, the local symbol in the app) and
  stay on the same axis.
- One total rule per page, above the page's one total. No other line kind.
- Sage only when money moves: a spend logged, a move made, money in. It arrives wet and
  dries to ink in 2 s. A balance is never sage, never red, never good or bad.
- No charts, no budgets, no "left to spend", no "cost you more than it needed to" (the spec
  has no market rate; the ideas page line is dropped).
- Pools, amounts, rates, fees and moves never reach Claude, logs, widgets, Live
  Activities, notifications or Siri (spec B2 walls). Private pool reads "Private pool".

## 2. Where pools sit (the rail)
Pools are places that hold lists, so they are the dial on the Money rail page (sheets 118,
119, 123). Due stays the pinned place; the month is the knob.
```
 Pinned   Due
 Knob     October / September / ...
 Dial     US checking
          India account
          Cash
          Saving
```
The landing doors (sheet 131: Due, Spending, Bills, Saving, Cash, Owed) keep their words;
with moneyPools On, Spending opens the rail on the last pool used. Unassigned pools (spec,
legacy spends) appear on the dial only when they hold lines, as "Unassigned dollars".

## 3. The pool page
```
 < Money
 US checking                               October      <- title, knob word on the right
 Dollars, account                                       <- one subtitle sentence, ink 2

 In
 Paycheck                    Oct 15        4,200.00
 Sam settled                 Oct 22           21.33
 Out
 Moved to India account      Oct 18        1,005.00     <- sent plus fee, as it left
 Rent                        Oct 1         1,850.00
 Groceries and 31 others                     912.60     <- folds after 5 lines; tap opens
 _____________________________________________________  <- the total rule
 Kept this month                             453.73
 Balance                                   2,391.73     <- ink 2, smaller, under the total
```
- Groups are "In" and "Out" as label words, not boxes. Dates are small ink 2 labels.
- Sources sit as the line word for money in ("Paycheck", "Freelance", "Gift").
- A move out reads "Moved to {pool}" with the amount that left (sent plus fee). Tapping it
  opens the move page.
- The page's one total is "Kept this month" (in minus out). Balance sits under it, ink 2,
  one size down; it is the running balance, never stored.
- Below zero: the balance line reads "Below zero by 120.00" in ink. No red, no warning.
- Swipe a spend line left to move it to another pool of the same currency; a pool of
  another currency answers "That pool holds rupees." (spec ReassignSpend).
- Write line at the foot as everywhere: "got 3200 paycheck", "spent 450 rupees coffee",
  "moved 1000 to India, got 82650, fee 5". The new line arrives in sage and dries.

## 4. The move page
```
 < India account
                                         INR 82,650.00  <- what arrived, the large number
 Moved on Oct 18 from US checking.

 Sent                                        1,000.00
 Fee                                             5.00
 _____________________________________________________
 Left US checking                            1,005.00
 Arrived                                INR 82,650.00

 Your rate was 82.24 rupees for a dollar after fees.    <- the spec sentence, ink
```
- What arrived is the hero, Outfit ExtraLight, on the decimal line, in the destination
  currency.
- Sent and Fee sit above the total rule, "Left {pool}" is the total; Arrived follows in the
  other currency. Four lines, one rule.
- The rate sentence is computed (spec: arrived / leaves, shown to 2 places), never typed.
- Every number is an instrument (sheet 131 section 2b): swipe to step, tap to type. Editing
  Sent, Fee or Arrived re-derives the rate in place; the rate line rolls digit by digit.
- "Delete this move" is a hold word at the foot (hold 0.6 s), with a 10 s Undo receipt.

## 5. Money landing with pools On (sheet 131, Money)
The landing stays B: one sentence, one total, the doors. With two currencies the total
block becomes per-currency lines, then the "about" total under the rule:
```
 Money
 Nothing is late. Rent is due Friday, and you also
 spent INR 18,400.00 in rupees this month.

 October so far
 Dollars                                      912.60
 Rupees                                INR 18,400.00
 _____________________________________________________
 In dollars, about                          1,134        <- whole dollars, empty cents slot
 Rates from Oct 18.                                      <- always shown, ink 2

 Due   Spending   Bills   Saving   Cash   Owed
```
- One currency only: no "about", the exact total, as today.
- A currency with no rate: "Rupees are not in the total." under the rule, ink 2.
- A rate older than 14 days: "These rates are old." after the date.
- Spec sentences that read as balances ("{Pool} has {amt}.") are not used on the landing;
  Money's landing leads with what is due and what moved (sheet 131).

## 6. Motion and haptics (MotionPolicy only)
- Tick: a changed number rolls digit by digit on the settle spring.
- Dry: sage fades to ink over 2 s. Reduce Motion: plain ink, no fade.
- One light impact when a move is logged; one selection tap per digit on the amount dial.

## 7. Keep every element feature (sheet 131 section 2b)
Before replacing Spending, Builder B lists today's Money gestures and carries each: amount
dial in place, shop total Enter, unit and currency "about" conversion, strike to pay on Due,
10 s Undo receipts, rail dial, pinned place and knob, Reduce Motion, AX5. At AX5 cents come
up to full size and each amount moves under its word.

## 8. Words
In, Out, Kept this month, Balance, Below zero by, Moved to, Sent, Fee, Left, Arrived, Your
rate was, In dollars, about, Rates from. Sentence case, US words, dollars. "Rupees" in
words, "INR" in text, the symbol in the app. Lakh grouping only behind its switch.

## 9. Open with the coordinator
- Rate source: memory has "ECB rates approved"; the spec says no network and uses the
  newest move rate or a typed rate. This sheet shows "Rates from {date}" for either. Kaushik
  should pick one.
