# M2 "Run my day" ship list

*Product lead, 2026-10-15 16:35. Same rules as `ship-list.md`: small end-to-end slices, velocity over perfection. Engine-heavy slices come first, so Core can build ahead while iOS build finishes v1 visuals. **Engine** = Core can ship it with tests and no new screens; **Rough** = a plain first UI is fine.*

| # | Slice | Done when | Engine / Rough |
|---|---|---|---|
| 1 | **Task class and actions** | `Task` (title, due?, scheduled day, estimate?, done, rolledFrom) with create / finish / move / delete actions in the op log, plus undo | Engine |
| 2 | **Nightly roll-forward** | Unfinished tasks scheduled for today move to tomorrow at day change; after 7 rolls they go to Later with one neutral Tess line, no counts of misses | Engine |
| 3 | **Tasks as processes** | Starting a task makes it a running process (it becomes Now); leaving it mid-way suspends it with a next step; waiting tasks have a check-at time | Engine |
| 4 | **Now picker** | One rule chooses Now: running process, else the next timed task or workout, else the top of today; the next three come out in order | Engine |
| 5 | **Note class** | `Note` (title, plain text body, links to any object), with backlinks; body stored as plain text for now | Engine |
| 6 | **Capture grammar for tasks and notes** | "call mum thu", "dentist thu 3pm", "note: bar felt heavy" become ghost rows that commit after 2 s | Engine first, ghost row reuses v1 UI |
| 7 | **Day load** | Planned minutes vs free time for today; "full" flag when over, with the items that could move to Later | Engine |
| 8 | **Today on Home** | Now, then Next (up to 3) and Later in a bounded vertical surface; swipe right done, left "not now" | Rough logic, Home meets the UI bar |
| 9 | **Task finish moment** | The Ink strike and haptic on finish; rolls happen silently | No: premium moment |
| 10 | **Notes app v0** | List by recency, open and edit plain text, link to objects with @ | Rough |
| 11 | **Day strip shows tasks** | Timed tasks and the workout sit on the day strip with the moving now marker | Rough |
| 12 | **Full What's running** | Tasks join the ledger (suspended and waiting), stale rules from `whats-running.md` | Rough |
| 13 | **Day full warning** | When the day is over capacity, the strip says "full" and offers to move items to Later in one tap; neutral colour | Rough |
| 14 | **Review side v0** | Swipe to Review: what got done this week as counts, items put away, workouts | Rough |

## Deferred past M2

Rich text and collaboration in notes (CRDTs), recurring tasks beyond "every day / weekday / week", calendar import, notifications as interrupts, body double mode, widgets.

## Defaults taken

Tasks with no date go to Later, not today. Roll-forward happens at 04:00, not midnight. Notes are plain text with @ links; no Markdown rendering yet.
