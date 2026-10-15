# M3 "Make it mine" ship list (engine-first)

*Product lead, 2026-10-15 17:05. Same rules as `ship-list.md`: small end-to-end slices, velocity over perfection. Written so the engine team can build without new Home or Workout UI from iOS build. **Engine** = logic and tests only; **Feature screen** = a self-contained screen in its own `Features/` folder, rough is fine but no stock look.*

| # | Slice | Done when | Type |
|---|---|---|---|
| 1 | **Body weight app** | `BodyWeight` class (Measurable, kg), log by capture ("bw 78.4"), 7-day average, trend; feeds e1RM for bodyweight lifts | Engine + Feature screen (rough) |
| 2 | **Habits as a building block** | `Habit` class (name, target "x of 7" per week, check-ins); "4 of the last 7" count, never streaks; can attach to any class | Engine |
| 3 | **Add a field to any class** | Action that adds a typed field (text, number, mass, duration, date, choice, link) to a built-in or user class, as an overlay with undo | Engine |
| 4 | **Saved queries** | One query AST ("sets where exercise is-a HorizontalPush this week"); save it as an object that any view or Tess can run | Engine |
| 5 | **Computed fields from the formula language** | Users can define a computed field with the existing expression language (e.g. volume = weight × reps); recomputes on change | Engine |
| 6 | **Class inspector** | Opens any class: fields (inherited marked), traits, subclasses, instance count; add a field (slice 3) from here | Feature screen (rough) |
| 7 | **Tess answers from the log** | Grammar commands: "what did I lift last week", "best bench at 5", "how many workouts this month", "bw trend". Answers as one line with tappable handles | Engine |
| 8 | **Tess edits by voice or text** | "move dentist to friday", "undo", "rename push day a to push heavy", "add face pull to pull day" through the same ghost row | Engine |
| 9 | **"What Tess did" receipt** | Reads Tess's ops from the op log: today's list, each with undo | Feature screen (rough) |
| 10 | **New class from a template** | Create a user class from three templates (Tracker: number over time; List: items with done; Log: dated notes), each with a default view | Engine + Feature screen (rough) |
| 11 | **Export and import a class package** | A class with its fields, views and data as one JSON file; import restores it | Engine |
| 12 | **Settings** | Units, gym kit, rest defaults, export, Reduce Motion override | Feature screen (rough) |

## Deferred

The visual block-level Remix editor and code view (needs Design), user-built app tiles on Home (needs iOS build), automations as daemons, Claude-built apps (M4).

## Defaults taken

Body weight is in kg, logged at most once per day (later entries replace). Habits count per calendar week from Monday. New user classes live under `/me/` in the object path. Tess commands stay grammar-only; no model calls in M3.
