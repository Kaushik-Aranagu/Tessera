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

## Check 2: Oct 16, 7:15 PM PT (02:15Z Oct 17)

Meter [M]: weekly 34% (flat from 33% at 6:02 PM, about 1%/h over the last hour), 5-hour 28% (resets 9:40 PM PT). The 6:02 to 7:15 burn is about 0.8%/h, well under the 1.9%/h sustainable line, so the project is no longer overspending and has about 66 points of headroom for the 9.8 hours to the Sun Oct 18 5:00 AM PT reset (100% allowed this week). Team dollars not read this round: the team session ids are held by the coordinator, and the meter outranks dollars anyway. Verdict: green; the slack is unused, so lanes waiting on a lock (Builder A and Core sat behind Builder B tonight) are the limit now, not budget.

## Check 3: Oct 17, 2:35 AM PT (09:35Z)

Meter [M] (coordinator session): weekly 44%, 5-hour 24% (resets 7:00 AM PT). Since check 2 (34% at 7:15 PM) that is +10 points in 7.3 h, about 1.4%/h. Left to the Sun Oct 18 5:00 AM PT reset: 56 points in about 26.4 h, so up to 2.1%/h fits if the week is spent to 100% (allowed this week). Verdict: green with about 0.7%/h of room, so lanes can keep two running; the overnight lock-screen stall, not budget, is what cost output. Rotating the 250k+ leads (rotation-handoffs.md) would add room.

## How to add a row

1. Read `usage.cost_usd` for each team session id (coordinator holds the list).
2. Read the weekly and 5-hour meter and write the rate per hour (the pace call comes from this). Subtract the previous row for the delta; compare with the pace line.
3. A team 5 points or more below its pace line pulls from its Next list or asks Product for gap-discovery work.
