# Idle detector: when a team is below its pace line

One page. It turns the pace rules in [staffing-model.md](staffing-model.md) section 2 into a check a lead can run in a minute, so no lane sits empty. The meter outranks everything here: never pull work past the 5-hour thresholds.

## The check

1. Find the team's pace line: share x $8,500 x hours since the Sun 5:00 AM PT reset / 168 (shares are in the staffing model). Cloud teams read `get_session(...).usage.cost_usd`; Mac teams use the board load until their session ids are in the [pace ledger](pace-ledger.md).
2. A team is **idle** when either holds:
   - it is 5 points of its share or more below its pace line, or
   - it has a lane with nothing running (no model job, no CPU job) for two turns.
3. Check the meter first. At 70% of the 5-hour window halve lanes instead; above 85% only installs, privacy fixes and merges run.

## What an idle team pulls, in order

1. **Its own Next list.** Take the top item the tier allows; if two lanes are empty, take two.
2. **A CPU job** from the catalog in staffing-model section 4 (package tests, the nightly scale run, fixture checks, recordings), so the second lane is never empty.
3. **Gap discovery from Product**, when Next has fewer than 3 items: acceptance gaps, missing tests, fixture holes, recordings. Product answers the same day and rules whether an item is real.
4. **Never** re-do finished work to spend budget. Unspent budget is lost at the Sunday reset, but make-work costs more than it buys.

## Who it asks

| Situation | Ask |
|---|---|
| Next under 3 items | Product (gap discovery) |
| Waiting on a review | QA, with the PR number and head SHA |
| Waiting on a merge | The coordinator |
| Waiting on the simulator | Take a place in the queue (`lane_lock.sh wait`), do CPU work meanwhile |
| Waiting on Kaushik | Put it on the morning list through the coordinator and take the next item |
| Reserve needed (Fable, red-zone work) | The coordinator releases it in blocks of 1 to 2 points |

## Who runs it

Each lead runs the check at its own turn start, using its own board. Ops reads the same numbers at each pace-ledger row and tells the coordinator which teams were idle; Ops does not hand out work.
