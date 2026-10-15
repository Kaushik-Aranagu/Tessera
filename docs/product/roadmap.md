# Tessera product roadmap

*Product lead, 2026-10-15. Builds on the research in `/mnt/project-files/app-os-research/` and the decisions in project memory. Milestones are ordered by what Kaushik can use daily, not by calendar.*

## North star

Tessera is a personal OS on the iPhone. Every noun is an object of a class, the screen shows only the working set, and Tess is the shell you talk to. The UI is half the product: each milestone ships only when it looks and moves at the premium bar (no cards, no stock SwiftUI, shown as simulator recordings).

## Principles that decide trade-offs

1. **One next thing.** Today shows Now, Next and Later, never the backlog.
2. **Depth costs nothing until asked.** Every name is a handle to an object page; detail loads on tap.
3. **Build the engine by building the apps.** Workouts, Today and Tasks prove the object model before users can build their own.
4. **Calm by default, alive where it matters.** A few living moments tied to real actions (Tess's paint-dab bloom, the breathing "now" tile), never decoration.
5. **Never shame.** Counts ("4 of the last 7"), not streaks; overdue rolls forward, never red.
6. **Tess acts through the same typed actions as the UI,** so everything she does can be undone.

## Milestones

| | Milestone | What Kaushik gets | Done when |
|---|---|---|---|
| **M0** | **Foundations** | The visual language locked, and the kernel underneath | Theme chosen; tokens (colour, type tiers, spacing, the house spring) and motion system in code; object store, class registry and event bus with tests; one generic object page that renders any class |
| **M1** | **Train with it** (first daily use) | Workouts end to end, a first Today, Tess v0 | Kaushik logs every gym session in Tessera for two weeks without falling back to another app |
| **M2** | **Run my day** | Tasks, Notes, Plans and the scheduler, Ready-to-Resume, widgets and the Live Activity, the Review page | Today is the first screen he opens each morning |
| **M3** | **Make it mine** | Class editor (visual plus code view), Remix a tile, add fields and views, formulas | He builds one real app of his own that looks as good as the built-in ones |
| **M4** | **Tess builds** | "Build me an app that…", Plan my day, shutdown summary, rule-based automations | Tess produces a usable app spec from one sentence, using only the block catalog |

## Team hand-offs

Specs go from Product to Design (UI language, motion, Tess's states) and Engineering (kernel, apps, integrations) through the coordinator. Each feature in `v1-features.md` gets its own spec file in this folder before build starts, beginning with Workouts.

## Open product questions

- **Theme:** Mosaic, Plein air or Kernel for the whole app. Owned by Design studio, which is asking Kaushik; Tess's "soul" is already the Plein air bloom.
- **v1 cut line:** confirmed by Kaushik on 2026-10-15: v1 is M0 + M1 (Workouts, the home page, the object system, Tess v0), and M2 follows as v1.1.
- **Spatial layout, controls and materials:** see `spatial-interaction.md` (x for siblings, y for sequence, z for depth; dial and drum inputs; zero-tolerance machined look, no pills).
