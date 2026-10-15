# Tessera board

*Owned by the planning lead (Product lead thread). Updated 2026-10-15 18:10.*

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

**Later:**
- M3 slices 1 to 12 in `ship-list-m3.md`, in order. Land the M3 List template on the kitchen `List` class.
- M4 engine slices 1, 2, 4, 5 and 9 in `ship-list-m4.md`.

## iOS build (Mac)

**Now:** v1 slice 8, edit and undo any set (`ship-list.md`).

**Next:**
1. v1 slice 9: swap an exercise within its pattern.
2. v1 slice 10: routine editing.
3. v1 slice 11: week view, rolling on after a missed day.
4. v1 slice 12: Quick Capture ghost row for "log bench 80x8".

**Later:**
- v1 slice 13, the live-mode polish pass (not rough).
- M2 slices 8, 9, 11, 12 and 13 in `ship-list-m2.md`: Today on Home, the finish moment, tasks on the day strip, full What's running, and the day-full warning.
- Hook Notes, Review and the kitchen into Home.
- M4 slice 10: snippets and widgets.

## Design studio

**Now:** steers for the M3 Feature screens: Class inspector, Body weight, Settings, and "What Tess did" (`ship-list-m3.md` slices 1, 6, 9, 12). Done when each has a one-paragraph steer like those in `ship-list-kitchen.md`.

**Next:**
1. Live-mode polish spec for v1 slice 13. Done when the motion, haptic and Reduce Motion values for Stamp, the rest dial and the PR sweep are written down for iOS build.
2. Today on Home motion (M2 slice 8). Done when the Now / Next / Later surface and its swipe gestures have a short motion note and a recording.
3. M4 screen steers: Plan my day, Shutdown, Focus block and Time Machine (`ship-list-m4.md`).

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

**Now:** test each merged slice on the simulator. Done when every merged PR has a short pass or bug note sent to the coordinator.

**Next:**
1. v1 gym flow script. Done when a written end-to-end check covers seed, prefilled hold-to-log, the dial, finishing, killing the app mid-set and resuming, and lock-screen Done.
2. Kitchen flow script. Done when a written check covers paste, scale, add to groceries, shop, cook with two timers, and finish.
3. Regression checklist. Done when a short list is run before each merge to master covers undo, export, What's running, and Reduce Motion.

**Later:**
- Performance budget checks: launch time, and the dial at 120 fps.

## Planning lead (Product lead thread)

**Now:** keep this board ahead of the builders. Done when no team's Next holds fewer than 2 items.

**Next:**
1. Finalise M4 from Research lab's scouting. Done when `ship-list-m4.md` moves from draft to ready.
2. A v1 acceptance pass. Done when each v1 slice has been checked against the latest recordings, with gaps added to the iOS build's Next.
3. Kitchen v2 scope review with the Kitchen lead.

**Later:**
- M5 candidates: "build me an app" with Claude, and daemons and automations.
