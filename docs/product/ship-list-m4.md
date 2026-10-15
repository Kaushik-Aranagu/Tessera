# M4 "My day, connected" ship list (draft)

*Planning lead, 2026-10-15 18:10. Comes after Workouts, the kitchen, and then Lists (`ship-list-lists.md`), in Kaushik's order. Same rules as earlier lists: small end-to-end slices, velocity over perfection, engine slices first. Defaults are mine, taken without asking Kaushik. Inputs: `../research/personal-os-and-productivity.md` and `../research/ai-and-tess.md`.*

**The idea.** So far Tessera knows what Kaushik logs in it. M4 lets it see the rest of his day: his calendar and his body (Apple Health). Tess then plans the day and closes it with him. All of this goes through the same objects, processes and ghost rows he already uses.

| # | Slice | Done when | Type |
|---|---|---|---|
| 1 | **Calendar mount** | EventKit events appear read-only as `Event` objects under `/calendar`; they feed the Now picker and day load (M2 slice 7) | Engine |
| 2 | **Health mount** | Read sleep, steps, resting HR and body weight from HealthKit into `/health`; body weight merges with M3 slice 1 | Engine |
| 3 | **Day full, with real time** | Day load uses calendar free time; "full" offers to page items to Later | Engine |
| 4 | **Interrupt masking** | Notifications get a priority; during a workout, cook or focus block low ones queue and arrive together at the next context switch | Engine |
| 5 | **Time Machine** | Op log exposed per day and per object: "what did I do Tuesday", scrub and undo | Engine + Feature screen (rough) |
| 6 | **Plan my day (Claude)** | Morning: Tess drafts today from tasks, calendar, plan and energy (sleep); shown as a ghost plan, accepted line by line | Engine + Feature screen |
| 7 | **Shutdown** | Evening: one screen of what got done (counts), what rolls, one optional line for tomorrow | Feature screen (rough) |
| 8 | **Focus block and body double** | Start a focus block on any task: it becomes a process, Tess checks in once at halfway with a quiet Live Activity and gives a one-line wrap-up | Engine + Feature screen |
| 9 | **First-step splitter** | A task untouched for 3 days gets one offered 2-minute first step, never a lecture | Engine |
| 10 | **Snippets and widgets** | Now, log a set, add to groceries and capture as App Intent snippets and a Home Screen widget | Engine + iOS build |
| 11 | **Visible memory** | What Tess has learned (gym days, units, a sore shoulder) appears as `Fact` objects you can browse, edit or delete | Engine + Feature screen (rough) |

## Defaults taken

- Calendar and Health are read-only in M4.
- Plan my day uses Sonnet 5.5 through a small proxy, and everything else stays on-device or grammar.
- Plan my day and Shutdown are opt-in, with no notifications. They show up on Now at 08:00 and 21:00.
- There is at most one Tess suggestion a day.

## Deferred

Two-way calendar sync, "build me an app" with Claude, daemons and automations, a pantry with "what can I cook", nutrition, and anything shared or social.
