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
- [qa/regression.md](qa/regression.md): the pre-merge checklist (undo, export, What's running, Tess phrases, Reduce Motion).
- [qa/gym-flow.md](qa/gym-flow.md): the v1 gym check (seed, prefill, dial, kill and resume, Lock Screen, edit and undo, finish).
- [qa/kitchen-flow.md](qa/kitchen-flow.md): the end-to-end kitchen run-through a Mac lead does before a kitchen PR merges. The Kitchen lead's per-slice acceptance is in [product/kitchen-acceptance.md](product/kitchen-acceptance.md).

## Running the checks

There's no CI. Before opening a PR, run `scripts/test.sh` on the Mac. It runs the engine package tests and then the app build and tests on the simulator.
