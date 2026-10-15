# Spec: What's running (v1)

*Product lead, 2026-10-15. Approved by Kaushik from Research lab's process-list idea. Replaces Ready-to-Resume.*

## What it is

Tessera's open loops shown the way an OS shows processes. It externalises working memory: anything left half-done is visible, with one way back in.

## States

| State | Meaning | v1 example |
|---|---|---|
| **Running** | Active now, owns the foreground or a timer | The workout in progress, a rest timer |
| **Paused** | Left mid-way, resumable | A workout minimised or auto-paused; a half-edited routine |
| **Waiting** | Blocked on something outside the app or on time | (M2: a task waiting on someone) |

v1 implements **Running** and **Paused** for workouts and **Paused** for any object page left mid-edit. Waiting and tasks come in M2.

## Where it appears

- **On Now:** a single row under the Now item when anything is running or paused. One process shows its name, state and a one-line resume note ("Bench press, set 3 of 4, 82.5 × 8 next"). Two or more collapse into "2 running", which expands in place (y) on pull.
- **At the top seam:** a lit seam while something is running, on every screen. Tapping the seam returns to the process.
- **On the Lock Screen:** the workout's Live Activity (see `workouts.md`).
- No separate screen in v1 **(default)**. M2 adds a full process view on the Review side.

## Resume

- One control per process: tap the row (or the seam) and the process opens exactly where it was, at the same set, scroll position and draft.
- The resume note is generated automatically from the saved state; for non-workout objects it is "where you were" plus "next step" if one can be inferred, else just where you were.
- Optional: hold the row to dictate your own "next step" note (P1).

## Automatic context save (P0)

- Leaving an object mid-way (backgrounding the app, navigating away from an edit, minimising a workout) saves its state as a process snapshot: object, view position, draft values and time.
- Snapshots are written through the same action path as everything else, so they sync and appear in the op log.
- A paused process older than 7 days is quietly archived to the Review side **(default)**, never deleted, and never shown as overdue.

## Ending a process

- Finishing the thing ends its process (finishing the workout, saving the edit).
- Swipe the row sideways to end it without finishing ("Close"); the work done so far is kept. Undoable.

## Engineering notes

- A `Process` record: subject (link to the object), state, startedAt, lastActiveAt, snapshot (JSON), resumeNote. Owned by the kernel, so every app gets processes free.
- The workout's process drives the Live Activity; ending the process ends the Activity.
