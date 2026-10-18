# Idle detector: what a team pulls when it is under its pace line

Ops, 1:20 AM PT Oct 18. One page. Pace line numbers: ops/reset-checklist-oct18.md (0.54 percent an hour from the Sun Oct 18 5 AM reset, plus or minus 5 points). Labels: **[M]** measured, **[I]** inferred.

## When a team counts as idle
A lead is idle when ALL are true: no worker running for it, no PR waiting on its fix, and its board Next has an item it could start. A team is also under pace when the week % is 5 or more points below the pace line (the coordinator reads it; the lead does not check the meter itself).

## What an idle lead pulls, in order (stop at the first that exists)
1. Its own board Next, top item, at the cheapest tier that fits (staffing-model.md 10-second rule).
2. A "gap" item from Product's refill list for its area (Product keeps 5+).
3. The shared gap list: stale lines on its own board (staleness.py), a doc a Mac lead cannot read in the repo (mirror it), a walk or acceptance that a landed PR left without one.
4. Nothing left: say so in ONE line to Product ("<team> Next empty") and stay quiet. Never invent work that changes rulings, pins or approval gates.

## Who it asks
- Needs a ruling or a refill: Product (one line, no list of options).
- Needs a merge: QA first (PR number and 40-char head), never a "ready to merge" note to the coordinator (leads never merge).
- Needs the Mac: coordinator relay, only for blockers.

## What it never does
- Opens a second lane because the meter looks low; the coordinator opens lanes (reset plan: second gap lane only at 5 or more points below the line).
- Starts a key-using run, a pin change, or Mac work without the owner.
- Uses Opus where Sonnet or Haiku fits; bulk docs work goes junior.
