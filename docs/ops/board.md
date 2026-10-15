# Tessera board

*Owned by the planning lead (Product lead thread). Leads update their own sections. Updated 2026-10-15 18:15.*

**Priority order (central):** v1 Workouts, then the kitchen (cooking, then groceries), then Lists (ahead of M3), then M4 "My day, connected". M3 engine slices fill gaps in Core's queue.

**Rules**
- Each lead owns their section and pulls the top **Next** item when **Now** is done. Nobody needs to ask first.
- **Next** always holds at least 3 ready items. When any team drops below 2, the planning lead refills it, or asks the coordinator if a decision is needed.
- Specs are in `tessera/product/`, also mirrored in the repo on branch `claude/project-thread-tjn3bv` under `docs/product/`. The Mac teams can't read this folder, so the coordinator relays their sections.
- **Central (coordinator):** sets priorities, resolves conflicts between teams, merges, and keeps memory. **Local (each lead):** runs its own queue and takes obvious defaults. Questions for Kaushik go to the coordinator's morning list.

## Core engine (Mac)

**Done:** Groceries screen, kitchen slice 13 (#58).

**Now:** a kitchen engine hotfix. Done when the six fixes from the kitchen lead's acceptance check (`kitchen-acceptance.md`) are merged, including the lift-parsing regression.

**Next:**
1. Recipe page and Paste a recipe. Done when slices 10 and 11 in `ship-list-kitchen.md` are met.
2. Groceries polish. Done when Design's and the kitchen lead's fixes to #58 are merged.
3. Meal plan feeds groceries (the idle-time slice below).
4. Cook mode. Done when slice 12 in `ship-list-kitchen.md` is met: timers on the Lock Screen and a Cook entry on finish. Core builds the live screen too, and Builder A reviews the shared instruments.
5. Kitchen shelf. Done when slice 14 in `ship-list-kitchen.md` is met.

**Idle-time slices** (from `../research/next-areas.md` part 2; each takes an afternoon, pull one whenever blocked):
- Meal plan feeds groceries. Done when "carbonara thursday" puts its ingredients on Groceries the evening before, linked to the task.
- Logs fill habits. Done when a habit can count itself each time a Workout or Cook finishes. Needs M3 slice 2.
- Body weight is the load. Done when pull-ups and dips use the latest body weight plus added weight for e1RM and volume. Needs M3 slice 1.

**Later:**
- **Lists engine.** `ship-list-lists.md` slices, in build order 1 → 3 → 2 → 4 → 5 → 7 → 6 → 8: housekeeping, lists from text, item paragraphs, reusable, run on Now, pick one, dated items in Today, list phrases. These replace kitchen slice 15.
- M3 slices 1 to 12 in `ship-list-m3.md`. Land the M3 List template on the kitchen `List` class.
- M4 engine slices 1, 2, 4, 5 (Day log) and 9 in `ship-list-m4.md`. These come after Lists. Slice 6, Plan my day, stays out until Kaushik OKs a model call.

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

**Done (2026-10-15):** kitchen build sheets on branch `claude/project-thread-b3tu3f`, `docs/design/kitchen/`: 13 Groceries (f36ff12), 10/11 Recipe page and paste (8989878), 12 Cook mode, 14 Shelf and 15 Lists v0 (d4957ac). Reviews: Notes v0, Groceries #58 (fixes in the Design thread). M3 steers and Home entry points: `docs/design/m3-steers.md` (60932f4).

**Now:** Live-mode polish spec for v1 slice 13. Done when the motion, haptic and Reduce Motion values for Stamp, the rest dial and the PR sweep are written down for iOS build.

**Always on:** review each Core or iOS screen as it merges, with file-and-change fixes posted in the Design thread.

**Next:**
1. Today on Home motion (M2 slice 8). Done when the Now / Next / Later surface and its swipe gestures have a short motion note and a recording.
2. M4 screen steers: Day log, Shutdown, Focus block and the energy check-in (`ship-list-m4.md`). Plan my day waits for Kaushik's OK.
3. A widget and snippet visual language (pulled forward for M4 slice 10).

**Later:**
- Lists screens 9-12 steer pass with the Kitchen lead (`ship-list-lists.md` supersedes my sheet 15 where they differ).
- The plate-stack concept prototype from `whats-running.md`.

## Recipes and groceries, then Lists (Kitchen lead)

**Now:** accept each kitchen screen as Core lands it, in `docs/product/kitchen-acceptance.md`. Engine 1-9 and Groceries #58 done (10 fixes relayed). Waiting on Recipe page and Paste (10, 11).

**Next:**
1. Accept the engine hotfix PR and the Groceries polish PR against the 10 fixes.
2. Design steer check on Lists screens 9-12 with Design studio before Core starts them.
3. Accept Recipe page and Paste a recipe (10, 11), Cook mode (12), Kitchen shelf (14) as each lands.

**Done:** Lists ship list `ship-list-lists.md` (#61); Lists acceptance checks `lists-acceptance.md` and starter lists `starter-lists.md` (#62, to merge); 10 seed recipes `kitchen-seed-recipes.md`; 50-phrase test set `kitchen-phrases.md`; Kitchen v2 backlog `kitchen-v2-backlog.md` (held for a week of use).

**Later:**
- Kitchen v2 scope from the backlog, after a week of use. Nutrition only if Kaushik asks.

## Research lab

**Now:** M4 scouting. Done when there's a ranked brief on calendar and health mounts, Plan my day and Shutdown patterns, and body doubling, each tied to an `ship-list-m4.md` slice.

**Next:**
1. Tess beyond grammar. Done when there's a brief on when the grammar runs out, on-device model routing, and an eval set of 200 capture phrases across workouts, tasks and the kitchen.
2. Kitchen v2 research for the Kitchen lead. Done when pantry tracking that doesn't feel like a chore and web recipe extraction are scouted.
3. Widget and snippet patterns. Done when the best iOS 26/27 interactive widget and snippet examples are scouted for M4 slice 10.

**Later:**
- What makes a personal OS stick past week 3: a retention and habit research brief.

## QA (Repo maintainer)

*No simulator or Swift toolchain in this thread, so QA here is code review on master, not running the app.*

**Now:** review each new merge to master. #46 to #58 are done: 13 bugs, written up in `tessera/qa/review-46-to-58.md` and sent to the coordinator for routing.

**Next:**
1. v1 gym flow script. Done when a written end-to-end check covers seed, prefilled hold-to-log, the dial, finishing, killing the app mid-set and resuming, and lock-screen Done.
2. Regression checklist. Done when a short pre-merge list covers undo, export, What's running, and Reduce Motion.
3. Keep the docs index at `docs/README.md` current (merged as #60).

**Done:** kitchen flow check at `docs/qa/kitchen-flow.md`, commit 0803f09 on `claude/project-thread-ri9mgm`, waiting to merge.

**Later:**
- Performance budget checks (launch time, dial at 120 fps). These need a Mac lead to run them.

## Planning lead (Product lead thread)

**Now:** keep this board ahead of the builders. Done when no team's Next holds fewer than 2 items.

**Next:**
1. Finalise M4 from Research lab's scouting. Done when `ship-list-m4.md` moves from draft to ready.
2. A v1 acceptance pass. Done when each v1 slice has been checked against the latest recordings, with gaps added to the iOS build's Next.
3. Kitchen v2 scope review with the Kitchen lead.

**Later:**
- M5 candidates, in Research lab's order: Money, Reading queue, People and Home upkeep. Also "build me an app" with Claude, and daem