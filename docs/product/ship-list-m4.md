# M4 "My day, connected" ship list (draft)

*Planning lead, 2026-10-15 18:10. Comes after Workouts, the kitchen, and then Lists (`ship-list-lists.md`), in Kaushik's order. Same rules as earlier lists: small end-to-end slices, velocity over perfection, engine slices first. Defaults are mine, taken without asking Kaushik. Inputs: `../research/personal-os-and-productivity.md`, `../research/ai-and-tess.md` and `../research/next-areas.md`.*

**The idea.** So far Tessera knows what Kaushik logs in it. M4 lets it see the rest of his day: his calendar and his body (Apple Health). Tess then plans the day and closes it with him. All of this goes through the same objects, processes and ghost rows he already uses.

| # | Slice | Done when | Type |
|---|---|---|---|
| 1 | **Calendar mount** | EventKit events appear read-only as `Event` objects under `/calendar`; they feed the Now picker and day load (M2 slice 7) | Engine |
| 2 | **Health mount** | Read sleep, steps, resting HR and body weight from HealthKit into `/health`; body weight merges with M3 slice 1 | Engine |
| 3 | **Day full, with real time** | Day load uses calendar free time; "full" offers to page items to Later | Engine |
| 4 | **Interrupt masking** | Notifications get a priority; during a workout, cook or focus block low ones queue and arrive together at the next context switch | Engine |
| 5 | **Day log (Time Machine)** | A Day page per date assembles itself from the op log ("Push day, PR on bench · carbonara · 4 tasks") plus one optional line; "today: …" in the ghost row adds it; scrub back through days, undo from there | Engine + Feature screen (rough) |
| 6 | **Plan my day (Claude)** ⚠ **Needs Kaushik's OK; not in the build queue** | Morning: Tess drafts today from tasks, calendar, plan and energy (sleep); shown as a ghost plan, accepted line by line. This would be Tess's first model call (cost, and a change from grammar-only) | Engine + Feature screen |
| 7 | **Shutdown** | Evening: one screen of what got done (counts), what rolls, one optional line for tomorrow | Feature screen (rough) |
| 8 | **Focus block and body double** | Start a focus block on any task: it becomes a process, Tess checks in once at halfway with a quiet Live Activity and gives a one-line wrap-up | Engine + Feature screen |
| 9 | **First-step splitter** | A task untouched for 3 days gets one offered 2-minute first step, never a lecture | Engine |
| 10 | **Snippets and widgets** | Now, log a set, add to groceries and capture as App Intent snippets and a Home Screen widget | Engine + iOS build |
| 10b | **Energy check-in** | One 1-to-5 energy log a morning on the rep drum, paired with Health sleep, shown on the Day log; low-energy days offer a lighter top set | Engine + Feature screen (rough) |
| 11 | **Visible memory** | What Tess has learned (gym days, units, a sore shoulder) appears as `Fact` objects you can browse, edit or delete | Engine + Feature screen (rough) |

## Defaults taken

- Calendar and Health are read-only in M4.
- Tess stays grammar-only. Plan my day (slice 6) is the only model call proposed, and it waits for Kaushik's OK.
- Plan my day and Shutdown are opt-in, with no notifications. They show up on Now at 08:00 and 21:00.
- There is at most one Tess suggestion a day.

## Next areas after M4 (from Research lab, ranked)

Money (a spend log entered on a dial, and a month count line), Reading queue (a book as a process, "p 142" moves its resume point), People (birthdays, and "last talked" from @mentions), Home upkeep (chores as habits with an interval, "watered 6 days ago"). Each one writes into the Day log.

## Deferred

Two-way calendar sync, "build me an app" with Claude, daemons and automations, a pantry with "what can I cook", nutrition, and anything shared or social.
