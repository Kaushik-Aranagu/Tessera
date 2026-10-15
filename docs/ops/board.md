# Tessera board

*Owned by the planning lead (Product lead thread). Updated 2026-10-15 18:12.*

**Priority order (central):** v1 Workouts, then the kitchen (cooking, then groceries), then Lists, then M4 "My day, connected". M3 engine slices fill gaps in Core's queue.

**Rules**
- Each lead owns their section and pulls the top **Next** item when **Now** is done. Nobody needs to ask first.
- **Next** always holds at least 3 ready items. When any team drops below 2, the planning lead refills it, or asks the coordinator if a decision is needed.
- Specs are in `tessera/product/`, also mirrored in the repo on branch `claude/project-thread-tjn3bv` under `docs/product/`. The Mac teams can't read this folder, so the coordinator relays their sections.
- **Central (coordinator):** sets priorities, resolves conflicts between teams, merges, and keeps memory. **Local (each lead):** runs its own queue and takes obvious defaults. Questions for Kaushik go to the coordinator's morning list.

## Core engine (Mac)

**Now:** Groceries screen. Done when it meets slice 13 in `ship-list-kitchen.md`.

**Next:**
1. Recipe page and Paste a recipe. Done when slices 10 and 11 in `ship-list-kitchen.md` are met.
2. Cook mode. Done when slice 12 in `ship-list-kitchen.md` is met: timers on the Lock Screen and a Cook entry on finish.
3. Kitchen shelf. Done when slice 14 in `ship-list-kitchen.md` is met.
4. Lists app v0. Done when slice 15 in `ship-list-kitchen.md` is met.

**Idle-time slices** (from `../research/next-areas.md` part 2; each takes an afternoon, pull one whenever blocked):
- Meal plan feeds groceries. Done when "carbonara thursday" puts its ingredients on Groceries the evening before, linked to the task.
- Logs fill habits. Done when a habit can count itself each time a Workout or Cook finishes. Needs M3 slice 2.
- Body weight is the load. Done when pull-ups and dips use the latest body weight plus added weight for e1RM and volume. Needs M3 slice 1.

**Later:**
- **Lists**, from `ship-list-lists.md`. The Recipes and groceries thread is drafting it, and it comes next after the kitchen screens.
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
- The cook-mode live screen, if it reuses the instruments (kitchen slice 12, coordinated with Core).
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
- Entry points from Home into Notes, Review and Kitchen (Groceries is `GroceriesView()`, #58).
- The Command bar hosting Tess's log answers and edits (M3 slices 7 and 8).

## Design studio

**Now:** steers for the M3 Feature screens: Class inspector, Body weight, Settings, and "What Tess did" (`ship-list-m3.md` slices 1, 6, 9, 12). Done when each has a one-paragraph steer like those in `ship-list-kitchen.md`.

**Next:**
1. Live-mode polish spec for v1 slice 13. Done when the motion, haptic and Reduce Motion values for Stamp, the rest dial and the PR sweep are written down for iOS build.
2. Today on Home motion (M2 slice 8). Done when the Now / Next / Later surface and its swipe gestures have a short motion note and a recording.
3. M4 screen steers: Day log, Shutdown, Focus block and the energy check-in (`ship-list-m4.md`). Plan my day waits for Kaushik's OK.

**Later:**
- A widget and snippet visual language.
- The plate-stack concept prototype from `whats-running.md`.

## Recipes and groceries (Kitchen lead)

**Now:** review each kitchen screen as Core lands it against your design steers. Done when every merged kitchen screen has a pass or a fix list sent to the coordinator.

**Next:**
1. Kitchen v2 scope. Done when there's a ship list for pantry and "what can I cook", a meal-plan week view, and web or AI recipe import, all engine-first.
2. Seed recipes. Done when about 10 everyday recipes are in pasteable text, so the kitchen isn't empty on day one.
3. A capture grammar test set. Done when there are 50 real kitchen phrases with their expected results, for Core's tests.

**Later:**
- Nutrition, after Kaushik asks for it.

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

**Now:** review merged PRs #46 to #57 for bugs and cross-PR clashes. Done when each finding is posted in the Repo maintainer thread with file:line and a fix, for the coordinator to route.

**Next:**
1. Review each new PR as it merges to master.
2. Docs index at `docs/README.md`. Commit fe13d3d is on branch `claude/project-thread-ri9mgm`, waiting for the coordinator to merge.
3. Kitchen flow script. Done when a written check covers paste, scale, add to groceries, shop, cook with two timers, and finish, for a Mac lead to run.
4. v1 gym flow script. Done when a written end-to-end check covers seed, prefilled hold-to-log, the dial, finishing, killing the app mid-set and resuming, and lock-screen Done.
5. Regression checklist. Done when a short pre-merge list covers undo, export, What's running, and Reduce Motion.

**Later:**
- Performance budget checks (launch time, dial at 120 fps). These need a Mac lead to run them.

## Planning lead (Product lead thread)

**Now:** keep this board ahead of the builders. Done when no team's Next holds fewer than 2 items.

**Next:**
1. Finalise M4 from Research lab's scouting. Done when `ship-list-m4.md` moves from draft to ready.
2. A v1 acceptance pass. Done when each v1 slice has been checked against the latest recordings, with gaps added to the iOS build's Next.
3. Kitchen v2 scope review with the Kitchen lead.

**Later:**
- M5 candidates, in Research lab's order: Money, Reading queue, People and Home upkeep. Also "build me an app" with Claude, and daemons.
