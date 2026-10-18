# Pace table for the Sun Oct 18 5:00 AM PT reset (Ops, 9:20 PM PT Oct 17 (stamped from a fresh date run: 9:17 PM))

Labels: [M] measured, [I] inferred. Source for the meter: coordinator `rate_limit_event` (read 9:16 PM PT). Source for the books: `get_session(...).usage.cost_usd` per cloud session, cumulative since that session was created (so rotated threads restart at zero; not comparable with the older usage-governor.md totals).

## The meter [M]
| Window | Used | Resets |
|---|---|---|
| 5 hour | 23% | 10:50 PM PT Oct 17 |
| Week | 79% (status allowed_warning, past 75%) | Sun Oct 18 5:00 AM PT (epoch 1792324800) |

Burn: 76% at 6:45 PM to 79% at 9:16 PM = about 1.2 points per hour [M, from usage-plan.md log]. Room to 100% before the reset: 21 points in 7.7 h = about 2.7 points per hour [I]. So the week is UNDER pace by about 1.5 points per hour; by the SATURATE rule (under 1.5 push gap lanes) every cloud team may run its gap lane now. The 100% allowance ends at the reset; from 5:00 AM the cap is 90% again (usage-plan.md, 5:30 PM Oct 16).

## Team lanes against the meter (cloud teams only [M]; Mac leads' ids are not visible to Ops)
| Team | Model, effort | Session age | Spent so far | Per hour | Share of visible |
|---|---|---|---|---|---|
| Coordinator | Opus 5.5, xhigh | 9.3 h | $162.80 | $17.5 | about 61% |
| Research | Sonnet 5.5 [1m], medium | 23.9 h | $50.11 | $2.1 | 7% |
| Kitchen (fresh 6:45 PM) | Sonnet 5.5, medium | 2.6 h | $13.19 | $5.1 | 18% |
| Design | Sonnet 5.5, medium | 9.6 h | $11.40 | $1.2 | 4% |
| AI architecture | Sonnet 5.5 [1m], medium | 23.4 h | $13.86 | $0.6 | 2% |
| Motion lab | Sonnet 5.5, medium | 7.2 h | $7.19 | $1.0 | 3% |
| Product (fresh 4:30 PM) | Sonnet 5.5 [1m], medium | 4.9 h | $6.08 | $1.3 | 4% |
| QA (fresh 9 PM) | Sonnet 5.5, medium | 0.4 h | $1.25 | n/a | n/a |
| Ops (fresh 9 PM) | Sonnet 5.5, medium | 0.4 h | see ledger | n/a | n/a |
Visible total about $28.7 per hour [M]. Mac teams (Core, Builder A, Builder B) are not in this table.

## What it says
1. The week is under pace (1.2 vs 2.7 points per hour room). Idle cloud lanes are the cost of under-use: Motion lab holds, Design waits on his answer, QA stands by. Gap lanes should run now. Ask for them through Product (it owns refills).
2. The coordinator's Opus xhigh session is about 61% of visible cloud dollars [M]. Whether to change that is the coordinator's call; Ops only reports it.
3. Kitchen runs at $5.1 per hour, four times the other Sonnet teams, with a fresh thread (short history). Worth watching after the first hour; not a problem at this meter reading.
4. After the 5 AM reset: cap back to 90% of the week (about 2% per hour over 168 h, share per team from staffing-model.md). The per-team budget refit (pace ledger row 4) waits for the coordinator's approval.

## Open [I]
- Dollar-to-percent fit is stale (usage-governor.md section 3: week 100% about $8k to $11k, from Oct 16). It should be refit from this morning's reading before the refit is proposed.
- Mac teams' spend is invisible here; the meter already includes them.
