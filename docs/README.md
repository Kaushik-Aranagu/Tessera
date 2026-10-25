# Docs index

Where each ship list, spec, design note, research brief and recording lives. Keep this current when you add a doc.

## Ship lists and product specs

The live copies are in the project's shared folder, `tessera/product/`. They're mirrored into the repo on branch `claude/project-thread-tjn3bv` under `docs/product/`. Master carries the kitchen and lists docs so far.

| Doc | What it is | On master |
| --- | --- | --- |
| `ship-list.md` | v1 ship list: small slices, fastest feel first | no |
| `ship-list-m2.md` | M2 "Run my day" | no |
| `ship-list-m3.md` | M3 "Make it mine" (engine-first) | no |
| `ship-list-m4.md` | M4 "My day, connected" (draft) | no |
| `ship-list-kitchen.md` | Kitchen: recipes, cooking, groceries, lists | [docs/product/ship-list-kitchen.md](product/ship-list-kitchen.md) |
| `ship-list-lists.md` | Lists app ship list | [docs/product/ship-list-lists.md](product/ship-list-lists.md) |
| `kitchen-acceptance.md` | Kitchen acceptance checks (engine and Groceries screen) | [docs/product/kitchen-acceptance.md](product/kitchen-acceptance.md) |
| `lists-acceptance.md` | Lists acceptance checks | [docs/product/lists-acceptance.md](product/lists-acceptance.md) |
| `kitchen-phrases.md` | Kitchen phrase test set for Tess, with expected results | [docs/product/kitchen-phrases.md](product/kitchen-phrases.md) |
| `kitchen-seed-recipes.md` | Everyday seed recipes in pasteable text | [docs/product/kitchen-seed-recipes.md](product/kitchen-seed-recipes.md) |
| `starter-lists.md` | Starter lists for Lists slices 3 and 4 | [docs/product/starter-lists.md](product/starter-lists.md) |
| `kitchen-v2-backlog.md` | Kitchen v2 backlog | [docs/product/kitchen-v2-backlog.md](product/kitchen-v2-backlog.md) |
| `v1-features.md` | v1 feature list | no |
| `roadmap.md` | Product roadmap | no |
| `workouts.md` | Spec: Workouts v1 (live mode, set logging, PRs, plans) | no |
| `whats-running.md` | Spec: What's running (v1) | no |
| `spatial-interaction.md` | Spec: spatial layout, controls and materials | no |
| `morning-questions.md` | Open questions for Kaushik | no |

The team board lives at `tessera/ops/board.md` in the shared folder. A copy is on the same mirror branch at `docs/ops/board.md`.

## Vision and design

- [PRODUCT_VISION.md](PRODUCT_VISION.md): the product vision, captured from Kaushik. Read it before designing a feature or changing the data model.
- [DESIGN_MOTION.md](DESIGN_MOTION.md): the design and motion playbook.

## Handoff

- [handoff/CODEX.md](handoff/CODEX.md): The Codex handoff: repo, build and test, branch and release rules, current state, queued work, privacy walls, look rules and where specs live. Kept current by Ops.
- [handoff/TESSERA-DESIGN.md](handoff/TESSERA-DESIGN.md): the consolidated design (Oct 25): every room, global rules, keystone specs, Tess, open items. Start here for design.
- [handoff/README.md](handoff/README.md): the Oct 25 design handoff package overview (note: its "do not push" lines are superseded, the owner now wants everything on GitHub).
- [handoff/codex-lanes.md](handoff/codex-lanes.md), [ops/codex-build78-progress.md](ops/codex-build78-progress.md), [ops/codex-team-addresses.md](ops/codex-team-addresses.md): Codex-era lane, build 78 progress and team address notes.
- [handoff/design-sheets/LARGE-FILES.md](handoff/design-sheets/LARGE-FILES.md): design files too large to commit.
- Design sheets added Oct 25: inspiration-252.md, keystones-251.md, kitchen-rail-259.md, kitchen-training-257.md, kitchen-training-258.md, kitchen-weather-253.md, kitchen-weather-254.md, lists-decision-280.md, money-balance-272.md, money-charge-276.md, money-five-275.md, money-index-system-279.md, money-indices-278.md, money-liquid-274.md, money-stock-277.md, money-three-273.md, money-tiles-271.md, names-281.md, routines-cat-261.md, routines-garden-266.md, routines-garden-268.md, routines-ideas-263.md, routines-keystone-260.md, routines-loops-262.md, routines-plates/BRIEF.md, routines-sheaf-249.md, weather-inside-255.md, weather-plates-256.md, weather-plates/BRIEF-for-ChatGPT.md, weather-plates/PROMPTS.md (all under `handoff/design-sheets/`).
- Designer memory rules: tessera-keystone-slot.md, tessera-keystones-locked.md, tessera-no-drawn-realism.md, tessera-no-github-push.md, tessera-skypiece.md (under `handoff/memory/`; the no-push rule applies only to the design agent).

## Engine

- [engine/grdb-migration.md](engine/grdb-migration.md): moving storage to GRDB, with the status of each stage.
- [engine/research-01.md](engine/research-01.md): sync, schema evolution, typed hot paths, performance and undo.

## Research briefs

[research/README.md](research/README.md) ranks the briefs and says which team each is for: AI and Tess, design and motion, exercise catalog, fitness and workouts, instrument robustness, object model and data, personal OS and productivity, ship now, storage spike, Tess's voice, What's running, and next app areas with cross-app links.

## Recordings and screenshots

All in [recordings/](recordings/) (`.mp4`, with `.gif` for the early ones) and [screenshots/](screenshots/).

| # | Recording |
| --- | --- |
| 01 | Launch reveal |
| 02 | Hold to finish |
| 03 | Bench press zoom and back |
| 04 | Start a workout |
| 05 | Log a set |
| 06 | Ask Tess command bar |
| 07 | Home and live workout |
| 08 | Round 9: workout and plans |
| 09 | Notes v0 |
| 09 | Real plan on a fresh install, first set |
| 10 | Review v0 |
| 11 | Notes polish |
| 12 | Groceries |

Screenshot: [screenshots/today-v0.jpg](screenshots/today-v0.jpg).

## QA

- [qa/review-46-to-58.md](qa/review-46-to-58.md): code review of merged PRs #46 to #58, with 13 findings by owner.
- [qa/grammar-trace.md](qa/grammar-trace.md): every kitchen phrase and 16 non-kitchen phrases traced through the Tess grammar, with 6 new findings (T1–T6).
- [qa/review-70-and-40-to-45.md](qa/review-70-and-40-to-45.md): status of every finding after Core's hotfix #70, five new bugs it introduced (H1–H5), and a review of #40 to #45 (N1–N4).
- [qa/review-data-safety.md](qa/review-data-safety.md): storage, op log and undo, and export (D1–D4).
- [qa/review-80-and-processes.md](qa/review-80-and-processes.md): status after Core's hotfix #80, its new bugs (B1–B5), and Tess, processes and HealthKit (P1–P4).
- [qa/review-84.md](qa/review-84.md): the data-safety merge #84, with what is fixed and what is still open (B3, G1, L1–L3).
- [qa/review-86.md](qa/review-86.md): the recipe page and paste-a-recipe screens (R1–R8).
- [qa/review-89.md](qa/review-89.md): Tess model layer T1, the v2 migration and the merging migration retry (M1, M2).
- [qa/rc-read-5cb92c4.md](qa/rc-read-5cb92c4.md): the release-candidate read of master for Kaushik's first phone install (GO), with W1–W3 and PL1–PL4.
- [qa/review-106.md](qa/review-106.md): Tess T2 tools shared by the on-device model and Claude (T2-1 rollback, T2-2).
- [qa/review-107-108.md](qa/review-107-108.md): Home links, Kitchen entry points and the stroke-word keys (NAV1, D4 rest persistence).
- [qa/review-107-110-113.md](qa/review-107-110-113.md): master after #107, #110, #106 and #113 (NAV1 confirmed fixed, N1, N2).
- [qa/review-109.md](qa/review-109.md): tap a logged stroke to edit a set, and the paint seed clamp.
- [qa/review-112.md](qa/review-112.md): backup and restore data safety (B1–B5) and the #114 hotfix.
- [qa/review-115.md](qa/review-115.md): grammar collision rules 1–3 (G1–G7) and the #117 hotfix.
- [qa/review-116.md](qa/review-116.md): Today queue swipes against Home's pager (Q1 blocker, Q2).
- [qa/review-118.md](qa/review-118.md): Groceries polish, the Backups entry, restore confirm (R1–R3, #120).
- [qa/review-122.md](qa/review-122.md): v1 engine gaps: RemoveSlot, clearRPE, rest days in the week, library groups (E1–E4).
- [qa/regression.md](qa/regression.md): the pre-merge checklist (undo, export, What's running, Tess phrases, Reduce Motion).
- [qa/gym-flow.md](qa/gym-flow.md): the v1 gym check (seed, prefill, dial, kill and resume, Lock Screen, edit and undo, finish).
- [qa/kitchen-flow.md](qa/kitchen-flow.md): the end-to-end kitchen run-through a Mac lead does before a kitchen PR merges. The Kitchen lead's per-slice acceptance is in [product/kitchen-acceptance.md](product/kitchen-acceptance.md).

## Running the checks

There's no CI. Before opening a PR, run `scripts/test.sh` on the Mac. It runs the engine package tests and then the app build and tests on the simulator.
