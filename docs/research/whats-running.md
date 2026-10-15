# What's running: the process list on Home

For: Product lead (spec), Design studio, Core engine, iOS build
Date: 2026-10-16

## What the research says

- **Make the resume point loud.** Altmann and Trafton: goals fade steadily after an interruption. A blatant cue at the exact spot cut resumption time; a subtle cue did no better than no cue. People mostly rehearse "what was I about to do", so store the next step, not only the position. [Trafton 2005](https://www.interruptions.net/literature/Trafton-HFES05.pdf)
- **Out of sight is out of mind.** Microsoft Research (Iqbal and Horvitz): about 27% of interrupted tasks were not resumed for 2+ hours, and hidden windows were returned to much later than visible ones. They recommend automatic context saving, visible reminders of suspended work and replay of the last few actions. [CHI 2007](https://www.erichorvitz.com/CHI_2007_Iqbal_Horvitz.pdf)
- **Open loops pull, plans calm them.** A 2025 meta-analysis found no reliable memory boost for unfinished tasks, but a reliable urge to go back to them. Masicampo and Baumeister: a concrete plan for how to continue quiets the nagging even while the task stays unfinished. So writing the next step is itself the relief. [Summary](https://www.spacedaily.com/j-v-the-zeigarnik-effect-helps-explain-why-unfinished-goals-can-feel-louder-than-completed-ones-but-modern-research-suggests-the-minds-pull-toward-open-loops-is-far-more-conditional-than-the/)
- **ADHD: put working memory outside the head.** Barkley's advice is to turn what you are holding in mind into something visible. [ADDitude](https://www.additudemag.com/working-memory-powers-executive-function/)
- **OS lessons.** The iOS app switcher shows where you were but not what is next, and swiping a card away is guilt free (keep that). htop and Activity Monitor give a terse state column and a "kill" verb (borrow the states, not the density). Stage Manager keeps recent work at the edge, which is too costly in space on a phone. Windows Timeline logged everything and was retired: a history of everything is not a resume tool. webOS cards are the anti-example: cards and endless sideways decks.
- **Live Activities** end after 8 hours and can linger on the Lock Screen for up to 4 more, so only the workout should escape the app. [ActivityKit](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- **Sunsama** rolls unfinished work forward each night, then auto-archives tasks that have rolled for several days with one neutral line ("N tasks moved to archive"). [Sunsama](https://help.sunsama.com/docs/task-rollover-and-recurring-tasks-the-basics)

## What a process holds

A built-in `Process` class in `SystemCatalog`, so it is an ordinary linkable object with a page.

| Field | Example |
|---|---|
| subject (link) | Push Day A (the Workout object) |
| owner app | Workouts |
| state | running, suspended, waiting, done, closed, put away |
| resume point (structured) | exercise 2, set 3, dial at 80 kg |
| next step (one line, verb first) | "Bench, set 3: 80 kg x 8" |
| last touched, started | 18:42, 18:10 |
| waiting on, check at | "Arjun's reply", Thu 10:00 |
| trail | last 3 op-log entries, for replay |
| ended at, end reason | 19:30, done |

The resume point and next step are written by the engine on every context switch, never typed by hand.

## States and what moves them

| From | To | Trigger |
|---|---|---|
| (none) | running | Start a workout, or open a task and act on it |
| running | suspended | Leave the object mid-way, or the app sits in the background past the rest time plus 10 minutes |
| suspended | running | Resume (one tap) |
| any open | waiting | User or Tess marks it blocked on someone or something |
| waiting | suspended | Check-at time arrives: it becomes eligible to be Now |
| running | done | Finish workout, finish task (Ink moment) |
| any open | closed | User puts it away by hand. Kept in history, no shame copy |
| suspended | put away | Stale rules below. Fully restorable |

At most one process is running. If a process is running, it **is** Now, so Home never shows two "next things".

## How many, and stale ones

- Home shows **at most 3**: the running one, then suspended by most recent touch, then waiting items whose check time has passed. More sits one level down (z), in the full list.
- Suspended and untouched for 3 days: drops out of Home into the full list.
- 7 days: put away to Later, with one line from Tess: "Put two things away. They're in Later." Never a count of misses, never red, never "overdue".
- A workout suspended for 6 hours is wrapped up with the sets already logged ("Saved Push Day, 3 of 5 exercises"), not thrown away.
- v1 only has the workout, so Home shows zero or one row.

## Three concepts

**A. The ledger.** Under Now, processes sit as full-width rows joined by hairline seams, like a machined index plate. Each row: the subject in the big tier, the next step in the second tier. State lives in the seam above the row, not in a badge: running is a lit seam with light travelling along it, suspended is a lit but still seam, waiting is an engraved, unlit seam. Tap the row to resume: it zooms from the row straight to the resume point. Swipe left to put it away (the row slides into its track and closes the gap). Pull the row down to drill in (z) to the process page with its trail. The breathing glint sits on the running row only.

**B. The top rail.** Every screen's top edge is a seam split into one segment per process, sized by recency; the running one glows (as the spatial spec already does for the workout). On Home, pulling down on the rail unrolls the list like a blind, with recency down the y axis. It is present everywhere, but the top edge belongs to the system (Notification Center), so the gesture clashes and is hard to discover.

**C. The plate stack.** Suspended processes are plates behind Now: thin, stepped tonal slivers along Now's top edge, each with its own hairline. Pull Now down and the plates fan out along y into full-width bands; release on one to bring it to the front, where it becomes Now. This is foreground and background taken literally and feels the most inventive, but it hides the next steps until you pull, which works against "visible beats hidden".

## Recommendation

**Ship A for v1, keep B's lit top seam for other screens, and plan C for M2** once tasks bring 3 or more processes. A keeps the next step visible on Home (the Microsoft finding), reuses the seams and the one light source, and costs about S on top of the kernel. C is worth prototyping when there is enough to stack.

Resume must land on a blatant cue: the set at eye level, the dial already at 80 kg, and one glint sweep across that set (with a haptic under Reduce Motion). Tess's bloom appears only when she writes or rewrites a next step (M2), so it stays rare.

Copy uses time, not judgement: "Left at set 3 of 5, 40 min ago".
