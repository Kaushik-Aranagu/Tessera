# 279 Money: the index system (spec, Oct 25)

His frame: "define a stock as a combination of certain modes of transactions... I could be tracking debts: car, home,
education, personal. I could have an index called India: my investments in India, debts I pay in India, savings I send
to India, money I send to family. Entertainment, subscriptions... They could be hierarchical, subsets of one another,
or disjoint. If we define everything in terms of indices we can build a lot of features on top. And the normalisation
problem is very important: adjust the scale and axis correctly, and the data transformation, so it represents
appropriately in the graph."

## 1. What an index is
An index is a named, saved question over the ledger, with a clock and a way of being drawn.

    Index = name + basket (a rule that selects transactions) + clock + series class + transform + baseline + liveness
          + children (optional) + alerts (optional)

- **Basket (the rule).** Any combination of: kind (Food), tag (#india), counterparty (Mum, HDFC, Netflix), account
  (ICICI, Chase), currency (INR), direction (in / out / transfer), size (over 200), recurrence (recurring / one-off /
  unplanned), text ("badminton"), time (weekends, evenings), geography (card used in India). Rules compose with
  and / or / not. Every transaction can belong to any number of indices: Netflix is in SUBSCRIPTIONS, ENTERTAINMENT,
  FIXED and MONTH at once.
- **Built-in indices** are just rules with defaults: MONTH (everything, this month), SPEND (out, not recurring, this
  month), each KIND, FIXED (recurring out), SURPRISES (one-off, unplanned), SAVE (transfers to goal accounts),
  PORTFOLIO (holdings), NET (all accounts minus all liabilities). The user's indices sit beside them as equals.
- **Set relations are explicit.** An index can declare children (DEBTS → CAR, HOME, EDUCATION, PERSONAL): the parent
  is the union, each child is drawn as a band inside it, and the watchlist indents them. Two indices can overlap
  (INDIA ∩ DEBTS = the education loan) and the overlap is shown when one is open ("also in DEBTS"). Disjointness is
  never required.
- **Derived indices.** Tess proposes them from the ledger: a counterparty you pay every month, a tag you keep using,
  a currency, a kind that doubled. "You send money to three people in India every month. Track it as INDIA?"

## 2. Making an index
Say it, or build it.
- **Say it.** "Track everything I send to India." Tess turns the sentence into a rule, shows the matching transactions
  (last three months, newest first, with the total), and the proposed clock and transform. You accept, or fix the
  rule by tapping a transaction out ("not this one", which adds a `not` term) or in.
- **Build it.** The maker is a sentence with blanks, not a form: "Track [out] [to Mum, HDFC, Zerodha] [in INR] [as a
  monthly flow]." Each blank opens a picker of the things that actually occur in your ledger. The preview chart draws
  as you choose; the summary line (count, total, share of income) updates with it.
- **Name and colour.** The name is a word (INDIA); the colour follows the dominant kind, or a user pick from the kinds
  palette; a hierarchy shares a hue with children in steps.
- **Promote.** Any index can be pinned as a door on the landing, put on the watchlist, or hidden. Doors are indices.

## 3. What every index gives you (the features fall out)
Chart (at its clock, normalised), the headline number and reading, the summary (count, total, average, share of
income, vs last period, vs plan), the record (every transaction in the basket, searchable), the forecast (where the
basket is heading at its pace, with scheduled items as drops), alerts (a threshold or a pace: "tell me when ENTERTAINMENT
passes 300" / "when DEBTS is behind schedule"), a budget (a line on the chart, the same as a plan), export, and a
door. Tess's sentences on the landing are written from indices ("INDIA is a third of what you sent last year").

## 4. Series classes and the normalisation that makes them read
The class is inferred from the basket and the clock; it decides the transform and the axis. The user can override.

| Class | Example | Natural clock | Transform | Baseline (flat) | Axis |
|---|---|---|---|---|---|
| Balance (zero-expectation) | MONTH | month by day | cumulative in minus out | 0 | absolute, 0 inside, padded |
| Flow | FOOD, INDIA, ENTERTAINMENT | 12 months by month | per-period total; this period projected | your average, or budget | absolute or indexed 100 |
| Pace | SPEND | month by day | cumulative to date ÷ same day last period | 100 | symmetric around 100 |
| Monotonic up | SAVE, NET | 24 months / 5 years | gap to plan (÷ plan × 100) + contributions as bars | 100 | symmetric around 100; level is the headline |
| Monotonic down | DEBTS | years by month | gap to schedule (÷ schedule × 100) + payments as bars; payoff date as the headline | 100 | symmetric around 100 |
| Ratio | SURPRISES, FIXED | 12 months | ÷ income of the period | the usual share | percent, 0 at the bottom |
| Live price | PORTFOLIO | 30 days, ticks | ÷ cost basis × 100 (return) | 100 | symmetric around 100 |
| Composite | INDIA = sends + investments + debt payments | 12 months | stacked flow by child; a share-of-income line over it | your average | absolute, children as bands |

Rules the renderer obeys:
1. **Pick the baseline first, then the axis.** The axis always contains the baseline; indexed series are symmetric
   about it so "above" and "below" take equal room.
2. **Monotonic series never chart the level.** A staircase says nothing; the level is the big number and the chart is
   the gap to plan or the rate (contributions, payments). The user can flip to the level with one tap if they want it.
3. **Clock by nature.** Each class declares the window at which it is readable; a pinch moves within the window, and
   the transform does not change with the zoom (a year of MONTH is twelve balance lines, not one long one).
4. **Outliers are kept, not clipped.** A one-off that would flatten the chart is drawn to the edge with a mark and its
   value, and the axis is set from the rest (robust range: 5th to 95th percentile, then padded).
5. **Projection is hollow.** The current, unfinished period is drawn as a projection (pace × period) in outline; the
   finished periods are solid.
6. **Units stay honest.** Money in the ledger's currency, never converted silently; a composite that mixes currencies
   draws each in its own band and shows the total only where a rate is known. Percent for ratios, "× 100" for indices,
   never mixed on one axis.
7. **Two series on one chart share a baseline, not an axis.** Last month behind this month: both absolute if both are
   balances; both indexed if either is indexed.
8. **Colour is never a judgement.** Direction is read from the chart; sage for yours, ink for forecast, kinds and
   user colours for baskets. No red, no green.
9. **Reduce Motion.** The draw-in and the switch become cross-fades; everything else holds.

## 5. The two examples on the board (money-indices-278, v2)
- **DEBTS** (monotonic down, hierarchical): CAR, HOME, EDUCATION, PERSONAL as children. Headline: the balance and the
  payoff date at this pace. Chart: gap to the schedule (100 = on schedule), payments as bars under, children as bands
  when open. Reading: "Ahead of schedule by two months; the car finishes in March."
- **INDIA** (composite flow, overlapping DEBTS and SAVE): sends to family, investments, the education loan. Chart:
  twelve months stacked by child, a share-of-income line over the top. Reading: "A third of what you sent last year
  went to the loan; it ends in May and the share drops to 9%."

## 6. Build notes
Indices are a first-class object (`Index`: rule AST, clock, class, overrides, children, pins, alerts) stored beside the
ledger; the rule evaluates lazily over `ObjectStore` with a cached series per clock. The renderer is one component
with the class table above; the maker is the Tess sentence grammar plus the blank-picker.
