# Kitchen v2 screen acceptance: P (state on the recipe and Ingredient pages), W (CAN COOK)

*Kitchen lead, 2026-10-17 (board K1). Done-when rows Builder B can test for the screen parts of slices P and W, against Design `kitchen-v2.md` §P, §W and sheets 77, 78 and 87. L (recipe from a link) is shipped, and R (usually have) is in `groceries-ai-acceptance.md` §4 and Pantry rows S5-S6 (`pantry-acceptance.md`). The engine rows are Core's, in `pantry-acceptance.md` (Core 1-7). Where §P's older wording differs from the receipt rule (name the thing first), the receipt rule wins and the row says so. Nothing here shows or sums nutrition.*

## P. The recipe page

| # | Pass when |
|---|---|
| P1 | An out line's amount drops from 600 to 400 and the line goes to 55%, with the faint ring (11 pt, 1.3 pt stroke, ink 42%) at x 6, centred on the row; the Pantry front's out lines use the same ring |
| P2 | Low and unknown lines show nothing different. A staple stays at 45% with its amount at 400 and no ring, so a staple never reads as missing, even when its ingredient is out |
| P3 | The amount column is a fixed ~92 pt so out lines do not shift when their weight drops ("1 bunch" fits) |
| P4 | On arrival the out lines lighten over 420 ms after the page settles and each ring draws from the top (520 ms, 160 ms apart). Reduce Motion: marks and rings fade in together over 200 ms (kitchen-v2 §Reduce Motion) |
| P5 | No state anywhere: the page is exactly today's page, no rings, no empty "have" words |
| P6 | The swipe-to-Groceries moved to the INGREDIENTS side (`kitchen-sides-acceptance.md` §4): the key adds out, low and unknown lines, never in lines or staples, and its N equals the peek's dry-run count |

## P. The Ingredient page

| # | Pass when |
|---|---|
| P7 | Tapping an ingredient name on a recipe moves it up to be the hero (21 to 56 pt, 460 ms), and the back word reads the recipe's name ("‹ DAL TADKA"). Reduce Motion: a 150 ms crossfade |
| P8 | The state sentence at y 168 opens with the state as a value word (600 weight): "Out since you cooked dal on Tuesday.", "Low, after dal on Tuesday.", "In since Saturday's shop.", "In, as of now." Unknown has no sentence at all, never "Unknown" |
| P9 | Tapping the value word cycles in, low, out, in. The sentence swaps through a blur (out 120 ms, in 220 ms), one `.selection`, one op, one UNDO of 10 s (a change; 10 s under VoiceOver), and the receipt names the thing first: "Limes, out." |
| P10 | The rhythm line shows only after 3 buys and never summed or forecast: "Bought 4 times, about every 12 days." Fewer than 3 buys: no line |
| P11 | USED IN lists the recipes that hold the ingredient, names only, each linking to its recipe; the PER 100 G side is the only place nutrition appears (`never-sums-audit.md` N5) |
| P12 | A private or secret-looking ingredient name never appears in a sentence, a receipt or a link; it reads "Private item" |

## P. Telling Tess

| # | Pass when |
|---|---|
| P13 | "out of milk" sets milk out, adds it to Groceries with the last typed amount, in one op with one UNDO of 4 s (it adds a row). Receipt: "Milk, out. On Groceries." (Design's older "Milk's out. On the list." is superseded by the house receipt rule and "Groceries", not "the list") |
| P14 | "have rice" or "got milk" sets in; receipt "Rice, in." with UNDO 10 s (a change). UNDO restores the previous state and any row it added |
| P15 | "out of milk" when milk is already out and already on Groceries adds no second row; the receipt reads "Milk, already on Groceries." with no UNDO |
| P16 | A phrase with a secret, money or body word never reaches this path; it goes to the walls first (`product-decisions-walls.md`), and no state is written |

## W. CAN COOK on the shelf

| # | Pass when |
|---|---|
| W1 | The shelf's third filter word reads CAN COOK in place of FROM THE BASKET (QUICK, NOT LATELY, CAN COOK); until slice P's state exists the shelf keeps FROM THE BASKET. It is off by default and takes the vermilion carriage when on |
| W2 | On: recipes missing two or more drop (fade down 10 pt, 180 ms); the rest re-sort on the settle spring (460 ms) keeping their sizes: nothing missing first (ties to the one not cooked lately), then one missing. The context line swaps to "3 you can cook now" (digits; "1 you can cook now" for one) |
| W3 | "Missing" counts non-staple lines whose ingredient is out or unknown, never low and never in (Core row 5). A recipe whose lines are all in or low or staples reads as nothing missing |
| W4 | One missing: a line under the name unrolls left to right (360 ms, 80 ms apart) at 21/400 in the context colour, "1 missing: lemons" with the ingredient as a value word. Tapping it puts it on Groceries: the line turns sage, "lemons is on the list" until the shelf closes, and Tess says "Lemons, on Groceries." with UNDO 4 s |
| W5 | One unknown and none out: "1 to check: lemons". Tapping opens the Ingredient page and adds nothing |
| W6 | Nothing cookable: the context line reads "Nothing without a shop" and the one-missing names remain |
| W7 | With no ingredient state at all (nothing known yet) CAN COOK shows every recipe as "N to check", never "Nothing without a shop" for a phone that knows nothing, and the filter word is greyed rather than a dead end |
| W8 | Turning the filter off restores the shelf's sizes and order exactly; nothing is stored about the filter beyond the session |
| W9 | Reduce Motion: re-sorts and flights are crossfades in place, 200 ms. Dynamic Type at AX sizes: the missing line wraps under the name, one column, nothing clipped; nothing under 16 pt |
| W10 | A private recipe or ingredient name never reaches the shelf's text, the missing line or a receipt. No Claude call anywhere in P or W (`pantry-acceptance.md` Core 7) |

## Open, defaults taken

1. W7 and P15's receipt wording are Kitchen's own; Design confirms them with the next copy pass.
2. P13 keeps "Milk, out. On Groceries." (Core's wording on `pantry-acceptance.md`). If Design prefers a different line, only the receipt changes.
