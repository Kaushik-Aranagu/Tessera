# Tessera board (index)

*Only the planning lead (Product lead thread) edits this file. Each team's queue lives in its own file under `board/`, and only that team's lead edits it. Updated 2026-10-15. First phone build: PRs cut at 2:05 PM Pacific (moved from 12:45 and 1:05 PM), then the final build; review guide in `../product/review-session.md`.*

**Installed (9:57 AM PT Oct 16):** 7b321d2 (#320, #330, #334, #337, #343), over the existing app; signing lapses ~Oct 23 9:57 AM PT, reminder Oct 22 10 AM PT. Next pin waits on #366. Next build: AI-1 Home, 44 part two, 42, Ask Tess sizes.

**AI spend (9:45 AM PT Oct 16):** in-app cap $50/month (decided 9:27 AM). Dev spend from cloud runs comes out of his $200/month credits and is logged here: memory experiment ~$0.60 (570 calls; Haiku ~$0.04, Sonnet ~$0.56), Oct 16. Groceries eval ~$0.0066 plus run 0 (rerun 2, #420: 10/10 must, 0 false pairs; Kitchen verdict pending).

**Themes (Kaushik, 6:40 PM PT):** Design's top job; Builder A builds the tokens and switch after the Siri hotfix; all screens use themed tokens from now on.

## Priority order (central)

1. v1 Workouts.
2. The kitchen: cooking, then groceries.
3. Lists, ahead of M3.
4. M4 "My day, connected".
5. M5: Reading, Money, Upkeep, then People (`ship-list-m5-*.md`), all approved.
6. Build: make an app from a sentence (`ship-list-build.md`), the long-term building-blocks goal. A1 slots in after M3 slices 3, 6 and 10 and model-layer T1 to T3.

Small product calls are logged in `../product/decisions.md`.

**Foundation, right after tonight's release:** the Tess model layer (`tess-model-layer.md`). Claude is approved and goes in as early as possible. M3 engine slices fill gaps in Core's queue.

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
| AI architecture | [board/ai.md](board/ai.md) | AI architecture thread (new, Oct 16) |
| Tess motion lab | [board/motion.md](board/motion.md) | Tess motion lab thread (new, Oct 16) |

## Cross-team order

- **Breadth waves:** follow Research's `../research/breadth-map.md`. Builder A takes the cook mode screen, plus M5 Reading and Money screens. Builder B keeps M2 Home, the capture surface, Lists 9 to 12, Upkeep and People. Core stays on engine slices, since it's the bottleneck.

- **Cook mode:** the engine is merged. Builder A builds the screen (slices 12 and 12b), and Core handles any engine follow-ups.
- **Lists:** the engine (Core) comes before the screens. Lists screens 9 to 12 go to Builder B after its Home slices.
- **M3 slice 10:** the List shape creates a Lists `List`. Lists come first.
- **M4:** after Lists. Research's fixtures (scenarios, calendar and Health, query evals) feed Core's tests.

## Rules

- **Every new area needs a HomeLink word** in `HomeSpatialView`, or it's DEBUG-only and Kaushik can't reach it. Each area's first screen slice includes it.

- **Times are in Pacific time** (Kaushik, 1:56 PM PT). Anything Kaushik reads uses Pacific (PDT, UTC-7 today), never UTC. Timestamps written before this rule in `decisions.md` and on the team boards are UTC.

- Each lead edits only its own file under `board/`. Re-read it just before you edit, keep each edit small, and never write any other team's file or this index.
- Pull the top **Next** item when **Now** is done. Nobody needs to ask first. Take obvious defaults.
- **Next** holds at least 3 ready items. When any team drops below 2, the planning lead refills it, or asks the coordinator if a decision is needed.
- Each item is one line: what it is, its spec link, and when it's done.
- Specs are in `tessera/product/`, mirrored in the repo on branch `claude/project-thread-tjn3bv` under `docs/product/` and `docs/ops/`. The Mac teams can't read this folder, so the coordinator relays their files.
- **Central (coordinator):** sets priorities, resolves conflicts between teams, merges, and keeps memory. **Local (each lead):** runs its own queue. Questions for Kaushik go to the coordinator's morning list.
