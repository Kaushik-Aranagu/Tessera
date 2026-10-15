# Docs index

Where each ship list, spec, design note, research brief and recording lives. Keep this current when you add a doc.

## Ship lists and product specs

The live copies are in the project's shared folder, `tessera/product/`. They're mirrored into the repo on branch `claude/project-thread-tjn3bv` under `docs/product/`. Master carries only the kitchen ship list so far.

| Doc | What it is | On master |
| --- | --- | --- |
| `ship-list.md` | v1 ship list: small slices, fastest feel first | no |
| `ship-list-m2.md` | M2 "Run my day" | no |
| `ship-list-m3.md` | M3 "Make it mine" (engine-first) | no |
| `ship-list-m4.md` | M4 "My day, connected" (draft) | no |
| `ship-list-kitchen.md` | Kitchen: recipes, cooking, groceries, lists | [docs/product/ship-list-kitchen.md](product/ship-list-kitchen.md) |
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

- [qa/gym-flow.md](qa/gym-flow.md): the v1 gym check (seed, prefill, dial, kill and resume, Lock Screen, edit and undo, finish).
- [qa/kitchen-flow.md](qa/kitchen-flow.md): the end-to-end kitchen check a Mac lead runs before a kitchen PR merges.

## Running the checks

There's no CI. Before opening a PR, run `scripts/test.sh` on the Mac. It runs the engine package tests and then the app build and tests on the simulator.
