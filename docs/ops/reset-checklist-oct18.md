# Sunday Oct 18 5:00 AM PT reset checklist (Ops draft)

Written for the coordinator and the leads. Times are PT. Facts come from the memory index (the trigger ids and dates there are the source; check them before relying on this page).

## At the reset (5:00 AM Sun)
1. Meter: read the first rate_limit_event after 5:00 AM; note week % (should be near 0), reset time, and the budget line (about 0.54% an hour, which is 90% over 168 h; 10% stays his; see the lane plan below).
2. Pace ledger row 4 (Ops): cost per cloud team and burn per hour from the first hours of the new week; report hot teams to the coordinator.
3. Per-team budget refit (Ops): propose new shares in the staffing model from last week's data; the coordinator approves before anything changes.
4. Lanes: every lead has two lanes running and 5+ items in Next (idle detector: nothing running for two turns counts as idle). Product refills; Ops mirrors boards afterward (first mirror run was approved).
5. Saturation check (coordinator, every 40 to 60 min): week % against the hour budget; scale lanes up or down by model and effort, never by stopping.

## Triggers due Oct 18 to 22 (check each still exists)
- Sun Oct 18 8:46 AM: daily deck (trig_013LzuhW2AzYmCR7kpxQU9LD).
- Mon Oct 19 9:50 AM: training questions for Kaushik.
- Thu Oct 22 9:30 AM: all-riders-in check and signing (trig_018EE1wV8ePaUamCumwFyCtk); 9:50 AM: morning list.
- Spot-check chain (coordinator): next random check after the 1:59 PM Oct 17 trigger.
- 3-hourly team updates: every lead posts in its thread; hold anything due after 11 PM until 7:48 AM.

## Phone
- Installed build is the last release named by the coordinator; a build installed after Oct 22 needs a fresh signing profile (lapse Fri Oct 23 2:12 PM). If nothing has installed for 6 days Builder A re-signs before the lapse.

## Not on this list
Nothing here changes another team's workflow; any such change goes to the coordinator first.

## Which teams to restart first (Ops proposal, 4:15 PM Oct 17; the coordinator decides from the meter)
Order by what a stall costs, not by who is busiest:
1. Builder A (Mac): releases, installs and the Oct 23 signing lapse depend on it.
2. Core (Mac): the engine and walls changes everyone else builds on.
3. Builder B (Mac): the other build lane; shares the simulator, so start it after Builder A has the lane lock.
4. QA: every PR waits on its verdict; a stopped QA stops all merges.
5. Product, Kitchen, Design: planning and design sheets that refill the builders' boards.
6. Research, AI architecture, Tess motion lab, Ops: batch or CPU work; start last, and run on cheaper model and effort first.
If the meter is above its hourly budget at the reset, lower model and effort on 5 and 6 before pausing anyone; never stop a team.

## Lane plan for the new week (Ops, 11:35 PM PT Oct 17; input from the coordinator's 11:25 PM relay)
Labels: [K] Kaushik's words, [D] derived by Ops, [I] inferred, low confidence.

### What he actually said about usage
- [K] 5:06 PM Oct 16 (cmsg_01VTPva3JGXrfvetgUvAWE7M3e1FLSEXPDvRCHFmBTXUFM): be careful with usage but do not let work stop; 90% of the plan to this project, 10% his; do not overshoot; mind the weekly limit; switch model and effort by task.
- [K] 5:30 PM Oct 16 (governor thread, cmsg_01VTPva3JGXrfvetgUvAWE7MVypqvFmBaFTQb3evEELKnF): this week only the project may use 100%; from the next weekly window back to the 90% cap; the 5-hour limit must never be exceeded.
- [K] 5:40 PM Oct 16 (cmsg_01VTPva3JGXrfvetgUvAWE7MKsHbg1eZMcNBM2tGBfjbBv) and 5:42 PM (cmsg_01VTPva3JGXrfvetgUvAWE7M3wPJPcq3jxnNVw6y6g6ZGD): never idle; run on cheaper models and CPU work when the budget is tight, bigger model and effort only when it counts; there is always work, so saturate.
- NOT said by him: that the 90% must be spent evenly across the week. "Use it or lose it" and the pace line (share x hours since reset / 168) come from the Ops governor and staffing-model.md, which the coordinator adopted. So the even pace is a house rule, not his target.

### The numbers
- [D] 90% over 168 h = 0.54% of the week per hour, about 12.8% a day. Tonight is about 2% an hour, so about 4 times the even pace. At tonight's pace 90% is gone in about 45 hours (Monday night).
- [D] Pace line from the reset: week % allowed at hour h = 0.54 x h. At 9 AM Sun it is 2.1%, at 5 PM 6.5%, Mon 5 AM 13%, Wed 5 AM 39%, Fri 5 AM 65%, Sat 5 AM 90%.
- [D] Tolerance: plus or minus 5 points from the line (the existing "below pace by 5 points" rule, staffing-model.md). So the first day may run hotter than even: at the 9:09 to 10:00 PM Oct 17 pace (79% to 83%, about 4.7% an hour) the line plus 5 is reached in about 1.2 hours, and at 2% an hour in about 3.4 hours (5 divided by the pace minus 0.54).
- [I] Dollar fit is stale and conflicts with tonight's books. Visible cloud spend is about $29 an hour at about 2% an hour of the week, which would put 100% of the week near $1.4k of visible cloud dollars, far below usage-governor.md's $8k to $11k. Possible reasons: Mac leads and their workers (not visible), Kaushik's own use, or cost_usd is not list price. If the visible-cloud fit holds, the whole visible budget after the reset is about $8 an hour, below the coordinator session's own average of $17.5 an hour. Do not act on this before a refit from the first two hours after the reset.

### Lane plan [I], for the coordinator to approve
Keep every team running (never stop one); change how much each costs. Cost is mostly re-reading context, so the levers in order are: (1) model and effort of the biggest sessions (the coordinator is about 61% of visible cloud dollars: Opus xhigh), (2) context size (rotate leads past about 300k), (3) lane count, (4) Haiku or Sonnet-low helpers for bulk doc work.
| Team | Lanes at 5 AM | Model, effort | Note |
|---|---|---|---|
| Coordinator | n/a | consider lower effort | biggest lever; the coordinator decides |
| Product | 1 (refill) | Sonnet medium | switches to the plan at the reset |
| QA | 1 | Sonnet medium | verdict latency matters more than cost |
| Kitchen | 1 | Sonnet medium | $5 an hour on a fresh thread; recheck at 7 AM |
| Design | 1 | Sonnet medium | waits on his answer; no gap lane |
| Research | 1, CPU/batch | Sonnet low | cheaper first |
| AI architecture | 1 | Sonnet low or Haiku | |
| Motion lab | 0 to 1 | Sonnet low | holds until work is sent |
| Ops | 1 | Sonnet low | docs and ledger only |
| Core, Builder A, Builder B (Mac) | 1 each, only while the Mac is unlocked | Opus or Sonnet medium | Mac burn is not visible; read the meter before adding a second lane |
Rule that replaces the two-lane default for this week: second (gap) lane opens only when week % is at least 5 points below the pace line; it closes when week % is at line + 3 (2 points inside the 5-point band).

### When Product switches
- 5:00 AM Sun: Product moves every cloud lead to the table above (one lane each) as soon as the coordinator confirms the first post-reset reading is under 5% for the week.
- 7:00 AM: Ops reads the meter and the books for the first two hours; the dollar fit is refit before any share is proposed; result to the coordinator in one line.
- Then every 3 hours with the team updates: week % against the pace line; open a gap lane only by the rule above; trim by lowering model and effort before closing a lane.

### Open for the coordinator
- Do you want the pace line as a house rule (even spending), or the 90% only as a ceiling with front-loading allowed? Kaushik has not said. Default in this plan: pace line with plus or minus 5 points.
- Coordinator model and effort after the reset.

## Huddle push override (coordinator relay, 12:37 PM PT Oct 19; Kaushik 12:37 PM: every feature and stretch goal, full effort)
Replaces the even-pace rule above until the huddle. The week was at 17%, on pace.
- Cloud teams may run two lanes.
- Stronger model and effort for build and design work; cheaper ones for routine docs.
- Pace may rise to about 1% an hour. The weekly ceiling stays at 90%.
- Re-trim only if the projection crosses 90% before Sun Oct 25 5 AM PDT, or if any five-hour window goes past 80%. Never by stopping a team.
- Research's hold on new hunts ended at 7 AM Oct 19; the 5:45 PM Oct 18 trim is gone.

## Usage trim (coordinator relay, 1:47 PM PT Oct 19)
- Week meter read 22% at 1:43 PM (+3 in the last hour, +6 since 10:44 AM). Ease cloud lanes to about 1%/h now.
- Routine docs, ledger work and QA re-pins: Haiku or Sonnet at low effort. Stronger models only for build specs and design that gate batches 2 to 4. No lane sits idle.
- Mac leads (Builder A, Builder B, Core) stay as they are. Next check 2:44 PM; a deeper trim follows if the meter reads 24% or more.

## Usage trim, step 2 (coordinator relay, 2:44 PM PT Oct 19)
- Week meter 24% (+2 in the last hour), 5-hour window 26%. Tighten every cloud lane from about 1%/h to about 0.5%/h.
- One working lane per cloud team, no parallel subagents. Haiku, or Sonnet on low effort, for docs PRs, QA re-pins and routine replies. Opus only for a real design or architecture call.
- Product holds the stretch design for batches 9 and 10 until batches 2 to 4 ship. No lane polls or idles: a finished lane ends its turn.
- Mac leads keep their batch work. Next check at the 4:48 PM overview.

## Usage brakes lifted (coordinator relay, 5:57 PM PT Oct 19; Kaushik: "it's okay for now about the usage, let's be a little aggressive")
- Trim steps 1 and 2 and the Kitchen and AI architecture pauses are lifted. Cloud lanes pick model and effort by task again; Fable stays rare. The 90% weekly ceiling still stands and the coordinator keeps the hourly meter.
