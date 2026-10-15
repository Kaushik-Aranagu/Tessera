# Tessera board

*Owned by the planning lead (Product lead thread). Leads update their own sections. Updated 2026-10-15 18:15.*

**Priority order (central):** v1 Workouts, then the kitchen (cooking, then groceries), then Lists (ahead of M3), then M4 "My day, connected". M3 engine slices fill gaps in Core's queue.

**Rules**
- Each lead owns their section and pulls the top **Next** item when **Now** is done. Nobody needs to ask first.
- **Next** always holds at least 3 ready items. When any team drops below 2, the planning lead refills it, or asks the coordinator if a decision is needed.
- Specs are in `tessera/product/`, also mirrored in the repo on branch `claude/project-thread-tjn3bv` under `docs/product/`. The Mac teams can't read this folder, so the coordinator relays their sections.
- **Central (coordinator):** sets priorities, resolves conflicts between teams, merges, and keeps memory. **Local (each lead):** runs its own queue and takes obvious defaults. Questions for Kaushik go to the coordinator's morning list.

## Core engine (Mac)

**Done:** Groceries screen, kitchen slice 13 (#58); the kitchen engine hotfix (#70).

**Now:** Recipe page and Paste a recipe. Done when slices 10 and 11 in `ship-list-kitchen.md` are met.

**Next:**
1. Groceries polish. Done when Design's and the kitchen lead's fixes to #58 are merged.
2. Meal plan feeds groceries (the idle-time slice below).
3. Cook mode. Done when slice 12 in `ship-list-kitchen.md` is met: timers on the Lock Screen and a Cook entry on finish. Core builds the live screen too, and Builder A reviews the shared instruments.
4. Kitchen shelf. Done when slice 14 in `ship-list-kitchen.md` is met.

**Idle-time slices** (from `../research/next-areas.md` part 2; each takes an afternoon, pull one whenever blocked):
- Meal plan feeds groceries. Done when "carbonara thursday" puts its ingredients on Groceries the evening before, linked to the task.
- Logs fill habits. Done when a habit can count itself each time a Workout or Cook finishes. Needs M3 slice 2.
- Body weight is the load. Done when pull-ups and dips use the latest body weight plus added weight for e1RM and volume. Needs M3 slice 1.

**Later:**
- **Lists engine.** `ship-list-lists.md` slices, in build order 1 → 3 → 2 → 4 → 5 → 7 → 6 → 8: housekeeping, lists from text, item paragraphs, reusable, run on Now, pick one, dated items in Today, list phrases. These replace kitchen slice 15.
- M3 slices 1 to 12 in `ship-list-m3.md`. Land the M3 List template on the kitchen `List` class.
- M4 engine slices in `ship-list-m4.md`, after Lists: 1 calendar, 2 Health, 3 day full, 5 Day log, 6 Plan my day (rules only), 7 Shutdown, 12 Tess on-device fallback (with the 200-phrase eval set), 4 interrupts, 9 first step. Slice 6b, model rewording, stays parked until Kaushik OKs it.

## iOS Builder A (Mac, current iOS build thread)

*Owns: Workout, Exercise, Plans, Routine, Widgets, DesignSystem.*

**Now:** v1 slice 8, edit and undo any set (`ship-list.md`).

**Next:**
1. v1 slice 9, swap within the pattern.
2. v1 slice 10, routine editing.
3. v1 slice 11, week view with roll-on.
4. v1 slice 12, Quick Capture ghost row for sets.

**Later:**
- v1 slice 13, live-mode polish (not rough).
- v1 slices 14 to 19: progression, muscle sets, month heatmap, voice, rep maxes, HealthKit.
- Review the shared instruments in Core's cook mode (kitchen slice 12).
- M4 slice 10, widgets and snippets.

## iOS Builder B (Mac, starts once ios/ship-2 merges)

*Owns: Home, the Command/Ask Tess bar, RootView, and the glue that hooks Notes, Review and Kitchen into Home.*

**Now:** M2 slice 8, Today on Home (`ship-list-m2.md`). Done when it shows Now, then up to 3 Next and Later in a bounded surface, with swipe right for done and left for not now. It meets the UI bar.

**Next:**
1. M2 slice 9, the task finish moment (Ink strike and haptic). Not rough.
2. NowPicker wiring. Done when cooking, shopping and timed tasks become Now through the same picker as workouts.
3. M2 slice 11, the day strip showing tasks and the workout, with the now marker.
4. M2 slice 12, the full What's running ledger for tasks: suspended and waiting, with the stale rules.
5. M2 slice 13, the day-full warning.

**Later:**
- Entry points from Home into Notes, Review, Kitchen and Lists (Groceries is `GroceriesView()`, #58).
- Dated list items in Today, and a running list as Now. This wires the UI for Lists slices 5 and 6 once Core lands them.
- **Lists screens 9 to 12** in `ship-list-lists.md`, in `Features/Lists/`, after the Home slices:
  - 9, the shelf, after Core's Lists slices 1 and 3.
  - 10, a list page, after Core's Lists slices 1 and 3.
  - 11, an item opened, after Core's Lists slice 2.
  - 12, the pick-one moment, after Core's Lists slice 7.
- The Command bar hosting Tess's log answers and edits (M3 slices 7 and 8).

## Design studio

**Done (2026-10-15):** kitchen build sheets on branch `claude/project-thread-b3tu3f`, `docs/design/kitchen/`: 13 Groceries (f36ff12), 10/11 Recipe page and paste (8989878), 12 Cook mode, 14 Shelf and 15 Lists v0 (d4957ac). Reviews: Notes v0, Groceries #58 (fixes in the Design thread). M3 steers and Home entry points: `docs/design/m3-steers.md` (60932f4). Live-mode polish values for v1 slice 13: `docs/design/live-polish.md` (742ffda). Today on Home motion for M2 slices 8 and 9, with a recording: `docs/design/today-on-home.md` (e961d26). M4 screen steers: `docs/design/m4-steers.md` (ead06a0).

**Now:** A widget and snippet visual language (pulled forward for M4 slice 10).

**Always on:** review each Core or iOS screen as it merges, with file-and-change fixes posted in the Design thread.

**Next:**
1. Day strip and day-full warning motion (M2 slices 11 and 13) for Builder B.
2. Lists screens 9-12 steer pass with the Kitchen lead (`ship-list-lists.md` supersedes my sheet 15 where they differ).
3. A motion study and recording for Plan my day and Shutdown (M4 slices 6 and 7).

**Later:**
- The plate-stack concept prototype from `whats-running.md`.

## Recipes and groceries, then Lists (Kitchen lead)

**Now:** accept each kitchen screen as Core lands it, in `docs/product/kitchen-acceptance.md`. Engine 1-9 and Groceries #58 done (10 fixes relayed). Waiting on Recipe page and Paste (10, 11).

**Next:**
1. Accept the engine hotfix PR and the Groceries polish PR against the 10 fixes.
2. Design steer check on Lists screens 9-12 with Design studio before Core starts them.
3. Accept Recipe page and Paste a recipe (10, 11), Cook mode (12), Kitchen shelf (14) as each lands.

**Done:** Lists ship list `ship-list-lists.md` (#61); Lists acceptance checks `lists-acceptance.md` and starter lists `starter-lists.md` (#62); 10 seed recipes `kitchen-seed-recipes.md`; 50-phrase test set `kitchen-phrases.md`; Kitchen v2 backlog `kitchen-v2-backlog.md` (held for a week of use).

**Later:**
- Kitchen v2 scope from the backlog, after a week of use. Nutrition only if Kaushik asks.

## Research lab

**Done:** #59 next areas; #65 M4 scouting, Tess routing and eval phrases, kitchen v2; #68 widgets and snippets, retention; #69 Day log, M5 Money and Reading; PR open for `people-and-upkeep.md`.

**Now (running, all five in parallel):** Next 1 to 5 below.

**Next:**
1. Lists and templates pattern scan, for Lists slices 4 and 7 and M3 slice 10. Done when there's a brief on how Things, Reminders, Notion templates and checklist apps handle reusable lists, list templates, "pick one" and pasting a block into a list, with 3 to 5 changes to `ship-list-lists.md`.
2. Habits that count, not nag, for M3 slice 2 and the "logs fill habits" idle slice. Done when there's a brief on weekly-target models (x of 7), auto-filled check-ins, and what makes habit apps feel like guilt, tied to concrete rules.
3. Adding a field without feeling like programming, for M3 slices 3, 6 and 10. Done when there's a brief on how Notion, Airtable, Tana and Capacities let people add properties and pick types, plus the smallest "gentle slope" flow for the Class inspector.
4. Quiet interrupts on iOS, for M4 slice 4. Done when there's a brief on interruption levels, Focus filters and the Time Sensitive limits, and on how to queue low-priority notifications during a workout or cook within what iOS allows.
5. Body weight trends, for M3 slice 1. Done when there's a brief on smoothing daily swings (moving average or trend weight, as in Happy Scale and Libra) and showing them calmly.

**Later:**
- Checking the on-device context size (4K vs 8K) once a Mac lead can run it.

## QA (Repo maintainer)

*No simulator or Swift toolchain in this thread, so QA here is code review on master, not running the app.*

**Now:** reviewing the earlier merges #40 to #45 (Notes, Review, capture and day loa