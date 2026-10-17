# Pace ledger

One row per governor check. Cumulative list-price dollars per session from `get_session(...).usage.cost_usd` [M]. Cloud threads only: Core, Builder A and Builder B are not visible to this account yet (get_session returns not found), so their shares in [staffing-model.md](staffing-model.md) stay inferred.

Pace line for a team = weekly share x $8,500 x hours since the weekly reset / 168 [I]. The first weekly window of the new rules starts at the Sun Oct 18 5:00 AM PT reset; until then this table only records baselines.

## Check 1: Oct 16, 6:02 PM PT (01:02Z Oct 17)

| Team | Share % | Cumulative $ | Since 5:22 PM check | Note |
|---|---|---|---|---|
| Coordinator | 7 | 741 | +22 | largest; Opus, 317k context |
| Research | 5 | 669 | +7 | still working, 346k context |
| Design | 9 | 346 | +3 | 362k context |
| QA | 10 | 206 | +1 | 164k context |
| Product | 5 | 134 | +3 | 97k context |
| Kitchen | 4 | 93 | +1 | 240k context |
| AI arch | 3 | 90 | +1 | 301k context |
| Motion lab | 4 | 75 | +2 | 336k context |
| Usage governor | n/a | 1 | n/a | completed |
| Ops | 3 | 5 | n/a | 284k context, restart at next milestone |
| **Cloud total** | | **2,354 plus governor $1** | **about +43 in 40 min** | about $65/h cloud; meter says 5.5%/h |

Meter (ground truth, from the coordinator's rate_limit_event reads [M]): weekly 31% at 5:40 PM, 33% at 6:02 PM, 5-hour 24%. That is about 5.5% an hour against about 1.9% an hour that fits before the Sun Oct 18 5:00 AM PT reset, so the project is burning about 3 times too fast. Check 1's first reading ("hold") used the dollar line and was wrong: about $65/h of cloud spend cannot be 5.5% an hour of an $8.5k week, so either the real weekly limit is about $1.2k to $2k [I] or the Mac leads (not visible here) burn most of it. Use the meter rate, not dollars, for every pace call; dollars only rank teams against each other.

Hottest cloud threads since 5:22 PM: Coordinator +$22, Research +$7. Threads over 250k context (Research, Design, Kitchen, AI arch, Motion lab, Coordinator, Ops) pay the most per turn; restart them at their next milestone ([worker-rotation.md](worker-rotation.md)).

## How to add a row

1. Read `usage.cost_usd` for each team session id (coordinator holds the list).
2. Read the weekly and 5-hour meter and write the rate per hour (the pace call comes from this). Subtract the previous row for the delta; compare with the pace line.
3. A team 5 points or more below its pace line pulls from its Next list or asks Product for gap-discovery work.
