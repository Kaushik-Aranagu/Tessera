# Tessera design specs (from Design studio)

The source of truth for how v1 looks, moves and feels. iOS build implements from these files; Design studio keeps them current.

- **Interactive mockups (canvas):** https://claude.ai/artifact/Ma6zBUdJJe4giqRNWHzF3r (private to Kaushik). The current rounds are **Round 6** (painterly Home and Workout, plus soul v2) and **Round 7** (Tess captures and the rest Live Activity), and **Round 9** (What's running as Now plus the ledger in `HomeLedger`, the live-mode details in `LiveDetails`, the exercise page, plans, the Soul Lab, and the Inter Tight vs serif comparison boards). Round 7's bottom dock is retired. Round 5's machined look was rejected; ignore it.
- **Mockup source:** [`mockups/`](mockups/) holds the HTML for those boards. They won't render on their own (they need the canvas runtime), but every colour, size, timing and keyframe in them is exact. Read them as reference code.

| File | What it covers |
|---|---|
| [materials.md](materials.md) | The painterly grounds, the paint colours, and where the machined precision lives (key edges, glass, ticks, the process seam) |
| [home-v1.md](home-v1.md) | Home across x (Review, Today, Training): the day stroke, the hero, hold to finish, the Later window, What's running (the running process becomes Now; suspended ones sit in the ledger under it), Ask Tess and ghost captures |
| [workout-v1.md](workout-v1.md) | Live workout: exercise lane, sets as brushstrokes, weight dial, reps drum, hold to log, rest in the dial, PR moment; the strip, swap, top-set check, effort, rest drags, finish, undo, and the instrument rules |
| [exercise-page.md](exercise-page.md) | The exercise as an object page: path, summary numbers, the painted 90-day trend, history / rep maxes / muscles |
| [plans.md](plans.md) | Plans: this week (days, sets per muscle) and the month heatmap |
| [live-activity.md](live-activity.md) | The rest timer on the Lock Screen and Dynamic Island (Inter Tight, horizon line as timer, tap the set to log it), with its Go state, Undo after Done, and colour moods |
| [tess-soul.md](tess-soul.md) | Tess's living mark, v2 wet paint: its form, mode parameters, travel, going home, the shader route, and the motifs we reuse. `mockups/SoulLab.dc.html` mixes any state with the unapproved shape and colour ideas |
| [type-and-motion.md](type-and-motion.md) | The four type tiers and the motion grammar (zoom for depth, paging for siblings, entrance rules) |
| [object-model.md](object-model.md) | Classes, objects and the mapping from OS ideas to the app (for Core engine) |

Product rules these specs answer: `/mnt/project-files/tessera/product/spatial-interaction.md` (x = siblings, y = sequence, z = depth; no pills or capsules; inputs as instruments).
