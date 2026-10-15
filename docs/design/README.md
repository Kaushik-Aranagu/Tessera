# Tessera design specs (from Design studio)

The source of truth for how v1 looks, moves and feels. iOS build implements from these files; Design studio keeps them current.

- **Interactive mockups (canvas):** https://claude.ai/artifact/Ma6zBUdJJe4giqRNWHzF3r (private to Kaushik). The current rounds are **Round 6** (painterly Home and Workout, plus soul v2) and **Round 7** (Tess captures and the rest Live Activity), and **Round 9** (What's running as Now plus the ledger in `HomeLedger`, the live-mode details in `LiveDetails`, the exercise page, plans, the Soul Lab, and Home and Workout in Inter Tight). **Type is Inter Tight app-wide, no italics** (Kaushik, 2026-10-15); boards drawn in Fraunces show layout and paint only. Round 7's bottom dock is retired. Round 5's machined look was rejected; ignore it.
- **Mockup source:** [`mockups/`](mockups/) holds the HTML for those boards. They won't render on their own (they need the canvas runtime), but every colour, size, timing and keyframe in them is exact. Read them as reference code.

| File | What it covers |
|---|---|
| [materials.md](materials.md) | The painterly grounds, the paint colours, and where the machined precision lives (key edges, glass, ticks, the process seam) |
| [home-v1.md](home-v1.md) | Home across x (Review, Today, Training): the day stroke, the hero, hold to finish, the Later window, What's running (the running process becomes Now; suspended ones sit in the ledger under it), Ask Tess and ghost captures |
| [workout-v1.md](workout-v1.md) | Live workout: exercise lane, sets as brushstrokes, weight dial, reps drum, hold to log, rest in the dial, PR moment; the strip, swap, top-set check, effort, rest drags, finish, undo, and the instrument rules |
| [exercise-page.md](exercise-page.md) | The exercise as an object page: path, summary numbers, the painted 90-day trend, history / rep maxes / muscles |
| [plans.md](plans.md) | Plans: this week (days, sets per muscle) and the month heatmap |
| [kitchen/](kitchen/) | Kitchen build sheets, one per screen, written ahead of Core: 13 Groceries (with at-the-shop) first; `lists-9-12.md` adds values to the Lists steers and supersedes sheet 15 |
| [m3-steers.md](m3-steers.md) | M3 screen steers (body weight, class inspector, What Tess did, settings) and where Notes, Review and Kitchen enter from Home |
| [today-on-home.md](today-on-home.md) | Today on Home (M2 slices 8 and 9): the queue window with Next and Later and its rolling heading, swipe right to finish (the strike follows your finger), swipe left to send to tomorrow, the finish haptic, and the next item rising into the hero. Recording in `recordings/`, playable study in `studies/` |
| [m4-steers.md](m4-steers.md) | M4 screen steers: Plan my day with the energy drum, Shutdown, the Day log, the focus block (with its Live Activity) and What Tess knows |
| [widgets-and-snippets.md](widgets-and-snippets.md) | Widgets, Lock Screen accessories, snippets and the Tell Tess control (M4 slice 10): one thing, one seam, one control; painted grounds; tinted mode. Board in `recordings/` |
| [day-strip.md](day-strip.md) | The day strip (M2 slices 11 and 13): tasks, the workout and events as marks on the day stroke, the moving now marker, and "full" shown as the dash gaps (your slack) closing, with Make room |
| [plate-stack.md](plate-stack.md) | Concept, not scheduled: the plate stack, where paused processes are stepped slivers behind Now that fan out when you pull Now down. Recording in `recordings/` |
| [no-buttons.md](no-buttons.md) | **Ink actions, overrides earlier sheets:** no shape around anything to make it a button, card or bar. Stroke words, label words, value words, the Tess horizon and veils, plus every place on master to change. Recording `recordings/ink-actions.mp4` |
| [edit-set.md](edit-set.md) | v1 slice 8: tap a logged stroke to edit, remove or undo a set. Recording `recordings/edit-set.mp4` |
| [routine-editor.md](routine-editor.md) | v1 slice 10: the routine page is always editable. Hold to reorder, swipe to drop, value words open drums, tap a name to change it. Recording `recordings/routine-editor.mp4` |
| [voice-gym.md](voice-gym.md) | v1 slice 17: hold the Tess horizon and talk. Words appear, become the set, fly to its stroke and dry as a ghost. Recording `recordings/voice-gym.mp4` |
| [live-polish.md](live-polish.md) | Live mode polish (v1 slice 13): exact timing, curves and haptics for the stamp, rest on the dial and the PR sweep, plus the haptic map and Reduce Motion |
| [live-activity.md](live-activity.md) | The rest timer on the Lock Screen and Dynamic Island (Inter Tight, horizon line as timer, tap the set to log it), with its Go state, Undo after Done, and colour moods |
| [tess-soul.md](tess-soul.md) | Tess's living mark, v2 wet paint: its form, mode parameters, travel, going home, the shader route, and the motifs we reuse. `mockups/SoulLab.dc.html` mixes any state with the unapproved shape and colour ideas |
| [type-and-motion.md](type-and-motion.md) | The four type tiers and the motion grammar (zoom for depth, paging for siblings, entrance rules) |
| [object-model.md](object-model.md) | Classes, objects and the mapping from OS ideas to the app (for Core engine) |

Product rules these specs answer: `/mnt/project-files/tessera/product/spatial-interaction.md` (x = siblings, y = sequence, z = depth; no pills or capsules; inputs as instruments).
