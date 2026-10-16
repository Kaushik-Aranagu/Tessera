# Spec: What's running (v1)

*Product lead, 2026-10-15, revised with Research lab round 2 (`../research/whats-running.md`). Approved by Kaushik from Research lab's process-list idea. Replaces Ready-to-Resume.*

## Why

Interrupted work fades unless the exact resume spot is cued loudly, and hidden work comes back much later than visible work. Writing the next step is itself the relief from an open loop. So Tessera keeps open loops visible on Home, each with its next step and a single resume control. A history of everything is not the goal.

## The Process class (built in)

`Process` is a built-in class in the system catalog: an ordinary, linkable object with its own page.

| Field | Example |
|---|---|
| subject (link) | Push Day A (the Workout) |
| owner app | Workouts |
| state | running, suspended, waiting, done, closed, put away |
| resume point (structured) | exercise 2, set 3, dial at 80 kg |
| next step (one line, verb first) | "Bench, set 3: 80 kg × 8" |
| started, last touched | 18:10, 18:42 |
| waiting on, check at | "Arjun's reply", Thu 10:00 (M2) |
| trail | last 3 op-log entries, for replay |
| ended at, end reason | 19:30, done |

The engine writes the resume point and next step on every context switch. Nobody types them.

## States

| From | To | Trigger |
|---|---|---|
| (none) | running | Start a workout, or open a task and act on it |
| running | suspended | Leave the object mid-way, or the app stays in the background longer than the rest time plus 10 minutes |
| suspended | running | Resume (one tap) |
| any open | waiting | Marked as blocked on someone or something (M2) |
| waiting | suspended | The check-at time arrives, so it can become Now again |
| running | done | Finish the workout or task |
| any open | closed | Put away by hand; kept in history, with no shame copy |
| suspended | put away | Stale rules below; fully restorable |

**Only one process can be running at a time, and a running process is Now,** so Home never shows two "next things".

## On Home: the ledger (v1)

- **The running process takes the Now slot itself,** not a ledger row (agreed with Design studio, `docs/design/` commit e81c24d).
- **The ledger holds only suspended and waiting processes:** at most 3 rows under Now, suspended ones by most recent touch first, then waiting ones whose check time has passed. The rest sit one level deeper (z) in the full list.
- Each row is full width and joined to the next by a hairline seam, like a machined index plate. The subject is in the big type tier, and the next step in the second tier.
- **State lives in the seam above the row, not in a badge:**
  - suspended: a lit, still seam;
  - waiting: an engraved, unlit seam.
- The breathing glint belongs to Now (the running process), not to ledger rows.
- **Tap to resume:** zoom from the row straight to the resume point. **Swipe left to put it away:** the row slides into its track and the gap closes. **Pull down on the row** to open the process page with its trail.
- Copy states time, never judgement: "Left at set 3 of 5, 40 min ago".
- In v1 only workouts are processes: a running workout is Now, and a suspended one is the single ledger row.

## Other screens

The top edge shows a lit seam while something is running, as in `spatial-interaction.md`. Tapping it returns to the process. Only the workout gets a Live Activity, because Live Activities end after 8 hours.

## Resume lands on a loud cue

Resuming a workout opens live mode with the set at eye level, the dial already preset (for example at 80 kg), and one glint sweep across that set. Under Reduce Motion, a haptic replaces the sweep. Tess's bloom appears only when she writes or rewrites a next step (M2), so it stays rare.

## Stale processes

- Suspended and untouched for **3 days**: leaves Home and moves into the full list.
- **7 days**: put away to Later, with one line from Tess: "Put two things away. They're in Later." It never counts misses and never says "overdue", and nothing is red.
- **A workout suspended for 6 hours** is wrapped up with the sets already logged ("Saved Push Day, 3 of 5 exercises"), never thrown away.

## Later

- **M2:** tasks and waiting items become processes.
- **M2 concept to prototype:** the "plate stack", where suspended processes sit as stepped slivers behind Now and fan out when you pull Now down. It's worth trying once there are 3 or more processes.


## Addendum, 12:17 AM PT Oct 16 (Design 41)
In v1 the ledger row leaves Home: the only process is a workout, and a suspended workout is the hero with the Start key's progress line. Once a second kind of process exists, suspended and waiting processes return as plain Next rows at the top of Next (title and time, at most 3, in the order above, no detail line). See decisions.md.
