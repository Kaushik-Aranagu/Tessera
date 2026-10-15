# Tessera design specs (from Design studio)

The source of truth for how v1 looks, moves and feels. iOS build implements from these files; Design studio keeps them current.

- **Interactive mockups (canvas):** https://claude.ai/artifact/Ma6zBUdJJe4giqRNWHzF3r (private to Kaushik). The current round is **Round 6** (painterly Home and Workout, plus soul v2). Round 5's machined look was rejected; ignore it.
- **Mockup source:** [`mockups/`](mockups/) holds the HTML for those boards. They won't render on their own (they need the canvas runtime), but every colour, size, timing and keyframe in them is exact. Read them as reference code.

| File | What it covers |
|---|---|
| [materials.md](materials.md) | The painterly grounds, the paint colours, and where the machined precision lives (key edges, glass, ticks, the process seam) |
| [home-v1.md](home-v1.md) | Home across x (Review, Today, Training): the day stroke, the hero, hold to finish, and the Later window |
| [workout-v1.md](workout-v1.md) | Live workout: exercise lane, sets as brushstrokes, weight dial, reps drum, hold to log, rest in the dial, PR moment |
| [tess-soul.md](tess-soul.md) | Tess's living mark, v2 wet paint: its form, mode parameters, travel, going home, the shader route, and the motifs we reuse |
| [type-and-motion.md](type-and-motion.md) | The four type tiers and the motion grammar (zoom for depth, paging for siblings, entrance rules) |
| [object-model.md](object-model.md) | Classes, objects and the mapping from OS ideas to the app (for Core engine) |

Product rules these specs answer: `/mnt/project-files/tessera/product/spatial-interaction.md` (x = siblings, y = sequence, z = depth; no pills or capsules; inputs as instruments).
