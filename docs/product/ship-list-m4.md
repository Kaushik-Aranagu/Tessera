# M4 "My day, connected" ship list (draft)

*Planning lead, 2026-10-15 18:20 (ready). Comes after Workouts, the kitchen, and then Lists (`ship-list-lists.md`), in Kaushik's order. Same rules as earlier lists: small end-to-end slices, velocity over perfection, engine slices first. Defaults are mine, taken without asking Kaushik. Inputs: `../research/personal-os-and-productivity.md`, `../research/ai-and-tess.md` `../research/next-areas.md`, and round 3 (`m4-scouting.md`, `tess-routing.md`, `tess-eval-phrases.md`).*

**The idea.** So far Tessera knows what Kaushik logs in it. M4 lets it see the rest of his day: his calendar and his body (Apple Health). Tess then plans the day and closes it with him. All of this goes through the same objects, processes and ghost rows he already uses.

| # | Slice | Done when | Type |
|---|---|---|---|
| 1 | **Calendar mount** | Full read access once; a rolling window (yesterday to +14 days) mirrored as read-only `Event` objects under `/calendar`, refetched and diffed on change; declined invites and all-day events don't count as busy. Feeds the Now picker and day load | Engine |
| 2 | **Health mount** | On foreground only: last night's sleep with stages from the Watch (18:00–14:00 window, one source; "In bed" on nights without the Watch), today's steps, resting HR (hidden if older than 36 h), latest body weight (deduped with M3 slice 1). Missing data reads "no sleep data", never "permission denied" | Engine |
| 3 | **Day full, with real time** | Day load uses calendar free time; "full" offers to page items to Later | Engine |
| 4 | **Quiet interrupts** | Tessera's own notifications get a priority. During a workout, cook or focus block, low ones are held and released as one grouped notification at the next context switch; the running Live Activity shows "2 waiting" (`../research/quiet-interrupts.md`) | Engine |
| 5 | **Day log (Time Machine)** | A Day page per date assembles itself from the op log ("Push day, PR on bench · carbonara · 4 tasks") plus one optional line; "today: …" in the ghost row adds it; scrub back through days, undo from there | Engine + Feature screen (rough) |
| 6 | **Plan my day, rules only** | At 08:00 a Now card: "Today: 3 meetings, 4h free, slept 6h40", then a ghost plan of at most 3 lines, each accept or skip, and "Start with: X" which becomes Now. Rules: fixed events and the workout first, then carry-overs from Shutdown, then due today, then oldest touched, filled to free time; sleep under 6 h or energy at or below 2 caps it at 2 tasks and offers the lighter top set. Under 60 seconds, no model call | Engine + Feature screen |
| 6b | **Plan my day, Claude wording** | Claude rewords and reorders the rules plan through the Tess model layer (approved by Kaushik 2026-10-15); the rules plan still shows if the call fails or the cap is hit | Engine |
| 7 | **Shutdown** | At 21:00 a Now card with counts only ("Did 4 tasks, 1 workout, cooked once"); unfinished items preselected to roll (one tap to keep any); one optional line for tomorrow; "Shutdown complete" ends it and writes to the Day log. Never a list of what didn't happen | Engine + Feature screen (rough) |
| 8 | **Focus block and body double** | Start a focus block on any task: it becomes a process, Tess checks in once at halfway with a quiet Live Activity and gives a one-line wrap-up | Engine + Feature screen |
| 9 | **First-step splitter** | A task untouched for 3 days gets one offered 2-minute first step, never a lecture | Engine |
| 10 | **Snippets and widgets** | Now, log a set, add to groceries and capture as App Intent snippets and a Home Screen widget | Engine + iOS build |
| 10b | **Energy check-in** | One 1-to-5 energy log a morning on the rep drum, paired with Health sleep, shown on the Day log; low-energy days offer a lighter top set | Engine + Feature screen (rough) |
| 12 | **Tess past the grammar (on-device)** | Normaliser first (fillers out, words to digits, "and a half"), then grammar; low-confidence or no parse falls back to on-device Foundation Models with output limited to real objects; kernel validates; past 3 s or on any error: "Didn't catch that" with the best guess. Passes the 200 phrases in `tess-eval-phrases.md` (grammar rows must pass) | Engine |
| 11 | **Visible memory** | What Tess has learned (gym days, units, a sore shoulder) appears as `Fact` objects you can browse, edit or delete | Engine + Feature screen (rough) |

## Defaults taken

- Calendar and Health are read-only in M4.
- Tess is grammar first. On-device Foundation Models is a fallback for the long tail (slice 12); it's free and private, and doesn't need a cloud call. Claude is approved (2026-10-15) and goes through the Tess model layer, with a cost cap; every write still goes through the kernel.
- Plan my day and Shutdown are opt-in, with no notifications. They show up on Now at 08:00 and 21:00.
- There is at most one Tess suggestion a day.

## Next areas after M4 (from Research lab, ranked)

Money (a spend log entered on a dial, and a month count line), Reading queue (a book as a process, "p 142" moves its resume point), People (birthdays, and "last talked" from @mentions), Home upkeep (chores as habits with an interval, "watered 6 days ago"). Each one writes into the Day log.

## Deferred

Two-way calendar sync, "build me an app" with Claude, daemons and automations, a pantry with "what can I cook", nutrition, and anything shared or social.
