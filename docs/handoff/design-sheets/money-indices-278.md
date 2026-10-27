# 278 Money: your indices (v1, Oct 25)

His frame (Oct 25): "define a stock as a combination of certain modes of transactions... monthly stock = payments and
salary; unexpected things; savings as a stock, over months or years; portfolio with live data... adjust the timescale
to how fast things change... the indices would be our doors; tap or swipe to show any one in the chart; a few things
summarised to the side... some series have expectation zero (in and out), some always increase or decrease, so
normalise so it shows correctly as a graph."

## The model
An index = basket (which transactions) + clock (its readable window) + baseline (what reads as flat) + liveness.
| Index | Basket | Clock | Baseline | Live |
|---|---|---|---|---|
| MONTH | pay + payments | this month by day | zero; chart is still yours with forecast and close | each payment |
| SPEND | everyday payments | this month by day | 100 = cumulative pace last month, same day | each payment |
| FOOD, OUT, HOME… | one kind | 12 months | 100 = your 12-month average; this month projected, hollow | this month live |
| SURPRISES | unplanned one-offs | 12 months | share of income; dashed = usual load; bars named (Fridge, Vet) | when one lands |
| SAVE | transfers to goals | 24 months | 100 = plan; level is the headline; contribution bars under | monthly |
| PORTFOLIO | holdings | 30 days | 100 = cost basis; chart is return | ticks in market hours |
| NET | own minus owe | 5 years by quarter | 100 = plan; dots | quarterly |

## Normalisation rules
zero-expectation: absolute vs zero (MONTH). pace: cumulative vs own past, indexed 100 (SPEND, kinds in-month).
monotonic: gap to plan indexed 100 + contributions as bars; level as headline (SAVE, NET). ratio: share of income
(SURPRISES, FIXED). live: indexed to window start, return not price (PORTFOLIO). clock by nature: each index declares
its window; pinch moves within it.

## The surface
One chart in the slot (compact: no watchlist). Header: INDEX · CLOCK, the big number with its label, one reading.
Baseline labelled (YOUR AVERAGE / ON PLAN / USUAL / COST). Tess's reading under the chart. Full chart: a watchlist
column of every other index as a sparkline against its own baseline with its number; tap one to switch (0.7 s: the old
chart slides and fades, the new one draws). Swipe across the chart = next/previous index. The doors under the slot are
the indices, lit one on the chart. Scrub reads the value in the index's own unit.

## Open
- Which indices ship first: MONTH, SPEND, SAVE, PORTFOLIO; kinds behind a swipe; SURPRISES needs the "unplanned" flag
  on a payment (Tess can infer: not recurring, not a kind's usual size).
- Pinch within a window; tap the headline number to toggle absolute vs indexed.
- Live data sources for PORTFOLIO; everything else is the ledger.

## v2: user-made indices and the maker (Oct 25)
DEBTS (monotonic down, children CAR/HOME/EDUCATION/PERSONAL as bands under the chart, payoff date in the reading) and
INDIA (composite: family, invested, loan stacked by child; share-of-income line over the top; overlaps DEBTS and SAVE).
The maker: a sentence with blanks ("Track [money out] to [Mum, Zerodha, HDFC] in [INR] as [a monthly flow], called
INDIA") with the matching count, total, share and overlaps. Spec: money-index-system-279.md.

## v3: two scrollers, one slot (his note, Oct 25)
"Showing that many at once, we won't have the space... a switcher at the top for high-level categories, the sidebar for
the indices in it, scrollable so more is fine; and the keystone the same size as every other app."
- The slot stays 354 x 182. Across the top: a three-place dial of categories (This month · Kinds · Saving · Investing
  · Debts · Mine), focused one large in the index colour, neighbours faded; a small caret under it. Swipe sideways on the
  dial or the chart, or tap a neighbour.
- Down the right: a scroller of the indices in the category (name, number, sparkline against its baseline), the
  focused one lit, one above and below faded, arrows when there are more. Swipe up and down on the scroller or the
  chart, or tap a row.
- The chart sits between, with the clock, headline number, reading and Tess's line (ellipsised to the chart width).
- The doors under the slot are the categories. The full chart (tap) is the same layout, larger.
- Categories are themselves indices (unions); the user's indices live under Mine or in a category they choose.
