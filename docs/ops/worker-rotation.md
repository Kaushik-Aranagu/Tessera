# Worker rotation

Applies to merge, docs and code workers. Source of the numbers: usage-governor (/mnt/project-files/tessera/ops/usage-governor.md) sections 2 and 5 (kept outside the repo; copy figures here if it moves).

## Rule

- Restart a worker fresh once its context passes about **250k tokens**, or at the **next milestone** (PR merged, PR opened, gate done), whichever comes first.
- Never restart mid-step (half-run build, half-applied rebase). Finish the step, write the hand-off, then restart.
- A restart is a new worker given the hand-off note and nothing else. Do not paste the old transcript.
- Lanes that sit at 370k tokens (QA was) cost at least $0.07 per turn before saying a word. Rotation is the cheapest saving we have.

## Hand-off note (exactly 3 lines)

```
DONE: <what is finished, with PR numbers and head SHAs>
OPEN: <what is not finished and why, one sentence>
NEXT: <the exact command or message to run first>
```

Example: `DONE: #596 merged at 2c52361; board updated. OPEN: staffing PR waits on QA verdict. NEXT: python3 -B -I scripts/ops/premerge_check.py 601`

## Resume by message or spawn fresh

Resume the existing worker by message when **both** hold:
- Its last turn was under an hour ago (prompt cache still warm), and
- Its context is small (well under 250k) and the next task is the same lane.

Spawn fresh when the cache is cold, the context is large, or the task is a different lane.

## Cold-wake cost (usage-governor section 2)

- Sonnet and Opus both charge $0.20 per 1M tokens for cache reads; our bill is about 52% cache reads, 29% cache writes, 19% output.
- Waking an idle thread after the 1 h cache expired re-writes the whole context: 370k tokens on Opus is about **$1.50** for one "no reply needed" (inferred).
- Idle-thread ping: warm $0.05 to $0.10, cold $0.50 to $1.50 (about 0.2% of the 5-hour window).
- So batch messages to idle threads into one note ([relay-batch](relay-batch.md)); every cold wake pays a full rewrite.
