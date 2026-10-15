# Tessera board (index)

*Only the planning lead (Product lead thread) edits this file. Each team's queue lives in its own file under `board/`, and only that team's lead edits it. Updated 2026-10-15 18:42.*

## Priority order (central)

1. v1 Workouts.
2. The kitchen: cooking, then groceries.
3. Lists, ahead of M3.
4. M4 "My day, connected".
5. M5 Reading (`ship-list-m5-reading.md`, approved), then Money.

Small product calls are logged in `../product/decisions.md`.

M3 engine slices fill gaps in Core's queue. Cloud model calls (Plan my day rewording, M4 slice 6b) wait for Kaushik's OK.

## Team queues

| Team | File | Lead |
|---|---|---|
| Planning / Product | [board/product.md](board/product.md) | Product lead thread |
| Core engine (Mac) | [board/core.md](board/core.md) | Core engine; the coordinator relays |
| iOS Builder A (Mac) | [board/ios-a.md](board/ios-a.md) | iOS build; the coordinator relays |
| iOS Builder B (Mac) | [board/ios-b.md](board/ios-b.md) | Starts once ios/ship-2 merges; the coordinator relays |
| Design studio | [board/design.md](board/design.md) | Design studio |
| Kitchen and Lists | [board/kitchen.md](board/kitchen.md) | Recipes and groceries |
| Research lab | [board/research.md](board/research.md) | Research lab |
| QA | [board/qa.md](board/qa.md) | Repo maintainer |

## Cross-team order

- **Cook mode:** Core builds all of it, including the live screen. Builder A reviews the shared instruments.
- **Lists:** the engine (Core) comes before the screens. Lists screens 9 to 12 go to Builder B after its Home slices.
- **M3 slice 10:** the List shape creates a Lists `List`. Lists come first.
- **M4:** after Lists. Research's fixtures (scenarios, calendar and Health, query evals) feed Core's tests.

## Rules

- Each lead edits only its own file under `board/`. Re-read it just before you edit, keep each edit small, and never write any other team's file or this index.
- Pull the top **Next** item when **Now** is done. Nobody needs to ask first. Take obvious defaults.
- **Next** holds at least 3 ready items. When any team drops below 2, the planning lead refills it, or asks the coordinator if a decision is needed.
- Each item is one line: what it is, its spec link, and when it's done.
- Specs are in `tessera/product/`, mirrored in the repo on branch `claude/project-thread-tjn3bv` under `docs/product/` and `docs/ops/`. The Mac teams can't read this folder, so the coordinator relays their files.
- **Central (coordinator):** sets priorities, resolves conflicts between teams, merges, and keeps memory. **Local (each lead):** runs its own queue. Questions for Kaushik go to the coordinator's morning list.
