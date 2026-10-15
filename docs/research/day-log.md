# Day log (Time Machine)

For: Product lead, Core engine, Design studio
Date: 2026-10-15

## What others teach us

- **Day One "On This Day", Apple Journal suggestions:** a past day is most loved when it is short and specific (a place, a photo, one moment). Apple Journal suggests moments but never writes the entry for you; people like the nudge, not the auto-essay.
- **Daylio, Exist.io, Gyroscope:** a tiny manual input (mood, one tag) next to automatic data is what makes a day feel like yours.
- **Rewind/Limitless, Google Timeline:** "record everything" is searchable but not readable. Timeline works because it collapses raw GPS into a few named visits. Lesson: store every op, show a handful of moments.
- **Bear/Obsidian daily notes:** an empty dated page is a quiet guilt trip. Ours fills itself.
- **Stoic, Reflectly:** prompted reflection works for some, nags most. Missed prompts feel like failure. One optional line, never a prompt.
- **Lived informatics (Epstein 2015, Elsden on "documentary informatics"):** people look back for stories, not stats. They lapse and return; gaps must look normal.
- **Scrubbers:** the Photos scrubber (drag the edge, labels appear, light haptics) and Apple Watch Activity history (one row per day, scroll back fast) are the models. Time Machine's stack is pretty but slow.

## Salience rule (what makes the page)

Per day, at most **one headline per app**, in a fixed app order. Everything else stays in the op log, one tap away.

| Event | Shown? | How |
|---|---|---|
| Finished process (workout, cook, focus block, recipe) | Yes | By name: "Push day", "carbonara" |
| PR, a first ever, a first in 30+ days | Yes, beats counts | "PR on bench", "first time making ramen" |
| Repeat items per app | Count only | "4 tasks", "2 notes", "3 sets of groceries" |
| Health and calendar | One fact each, quiet tier | "slept 7h10 · 3 meetings" |
| Your one line | Yes, top, largest type | As typed |
| Edits, moves, renames, reorders, deletes, settings | No | Op log only |
| Started but unfinished | No | Never shows what didn't happen |
| Undos and their undone op | No | Both drop out of the summary |

Grouping: headline line (finished things and PRs joined with "·"), then one count line, then the quiet health line. Max 3 lines plus your line. Empty days show only the date in small type, and runs of empty days collapse to one thin row ("Oct 3 to 6"), no count of missed days.

## The one optional line

- "today: rough sleep, good lift" in the ghost row writes a `DayNote` linked to the Day. Also writable from Shutdown (slice 7).
- One per day; typing again replaces it (old text stays in the op log). Plain text, no mood scale (energy is slice 10b).
- "yesterday: ..." works too.
- Never asked for. No empty field shown on past days.

## What "undo from there" means

**Means:** pick one moment on a past day, see what it will do ("Remove set bench 80x5 from Oct 12; PR moves back to 77.5"), confirm. It writes a new compensating op today. Today's log shows "undid 1 thing from Oct 12".

**Does not mean:** rewinding the whole app to that day, undoing a whole day in one tap, or cascading into later ops.

Safety rules:
1. Per moment, never per day. A headline that groups several ops (a workout) undoes as one unit.
2. Only if the object hasn't changed since. Otherwise: "Changed since; open it" (go to the object, no merge).
3. Never undo mounted data (calendar, Health); it's read-only.
4. Deletes from the past come back as restores, not as undo of the delete chain.
5. Derived values (PRs, counts) recompute; never edit them directly.
6. The undo itself is undoable today.

## Scrub gesture (y = time)

Today at the bottom, past above, like a message thread: pull down to go back. Days are rows in one vertical scroll, today expanded, past days at headline size. A thin rail on the right edge works like the Photos scrubber: drag it and the month and day float beside your thumb, a light tick per day, a firmer one at each week and month. Let go to land on that day, expanded.

## Smallest first version

1. Engine: `DaySummary(date)` folds the op log through the salience table; cached per day, recomputed when an op for that day lands.
2. Day page: date, your line, up to 3 lines. One vertical list of days with today at the bottom; collapsed empty runs.
3. "today: ..." ghost-row grammar writes `DayNote`.
4. Undo for workout sets and tasks only, with the preview and the "changed since" check.

Later: rail scrubber, "on this day" on Now, undo for other apps.

## 3 pitfalls

1. **Noise creep.** Every new app wants a line. Hold the one-headline-per-app cap and the 3-line limit; new apps compete for it.
2. **Accidental shame.** Gaps, "0 tasks", or listing abandoned things turns the log into a report card. Show only what happened; collapse empty runs.
3. **Undo that surprises.** Reverting an old set silently moves a PR or breaks a plan. Always preview the knock-on, and refuse when the object changed since.

## Yes/no for Kaushik

None blocking. Optional: is "today at the bottom, pull down for the past" right for you, or should today sit at the top? Default taken: bottom.
