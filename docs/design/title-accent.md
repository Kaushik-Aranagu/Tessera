# 72. A subtle accent on titles

**Kaushik's principle, in one line:** the big type carries a touch of colour that means something, quietly, with no brush or underline behind it.

His ask (Oct 16, 1:32 PM PT): the titles, the big text, can carry "a little bit of color or accent… something subtle… we can use it to express more things", "not over the board" and "not like adding an underlining like the older brush". Three options, drawn on Home's frame (41) in Porcelain and Obsidian:
- Board: `mockups/title-accent.png`.
- Recording: `recordings/title-accent.mp4` (12 s, Porcelain), showing option 1 on a workout. Sets land and the ink fills; at done it floods, lifts once, then dries back to ink over 2 s.
- Study: `studies/title-accent.html`.

## The three options
| | What it does | What it says |
|---|---|---|
| **1. Ink that fills** (recommended) | The title's letters take its area's colour from the left as the thing gets done: sets in a workout, steps in a cook, tasks in a run. At done the whole title is coloured for a beat (one 250 ms lift), then dries back to ink over 2 s. At rest every title is plain ink | How far along, with no bar |
| 2. The word that matters | Only the word that carries the moment takes the colour: "7 pm", "set 2", "3 sessions" | Where to look first |
| 3. A tint of the area | The whole title leans about a fifth toward its area's colour, and never moves | Which area it belongs to |

## Values (all three)
- **Colours:** each area's existing data colour, mixed 72% with ink so it reads as ink with a lean, never as a link. Training is vermilion `liveInk`, Kitchen is health green, Today's tasks are cobalt, and Review is violet `ctx`. In Obsidian, each look's light partner. No new colours.
- **Contrast:** at Title 44 and Hero 56, every mix stays above 3:1 on its ground (large text).
- **Where:** heroes on Home and Title 44 on pages one tap down. Never body text, labels or keys, and never in Tess's band.
- **Motion (option 1):** the fill edge is an 8% feather. Each step tweens 600 ms on the house curve, and the done lift and dry match how moments land wet and dry elsewhere. Under Reduce Motion the fill steps without the tween, and the dry is a 150 ms crossfade (MotionPolicy).
- **Never:** a brush, an underline, a gradient that loops, or colour on a title with nothing in progress (option 1).

## Round 2: the whole title moves (his pick, Oct 16, 1:50 PM PT)
He liked option 1 but found it too forward, and the half-and-half split looked odd in between. He asked for every in-between state to mean something, for the title to get bolder and shift colour in one direction, for all the effects to join at the end, and for options 1 and 2 to combine.
- Board: `mockups/title-progress.png`. Recording: `recordings/title-progress.mp4` (15 s, Porcelain). Study: `studies/title-progress.html`.

| Moment | What the title does |
|---|---|
| In progress, `p` 0 to 1 | The whole title together: weight 500 → 640, tracking tightens by 0.012 em so the width holds, and its ink leans toward the area's colour from 0 to 60%. No split, no edge. |
| The word that matters | Wears the area's colour (72% mix) from the first step, as option 2. The rest of the title catches up to it. |
| Done | Every effect joins: full weight, full lean, and a 3 pt strike drawn left to right through the x-height (420 ms, ease-out, wraps with the lines), then one 250 ms lift. |
| Dried, 900 ms later | Over 2 s the colour, weight and the word settle to quiet ink at 50%. The strike stays, so a done title reads done at a glance. |

- **Progress source:** the thing's own count (sets in a workout, steps in a cook, tasks in a run), capped at 0.85 until done so the last step still has somewhere to go.
- **Reduce Motion:** each step lands without the tween, the strike appears whole, and the dry is a 150 ms crossfade (MotionPolicy).
- **Kept from round 1:** each area's own colour, the contrast floor, where it applies, and the nevers.

## Rulings on Research's fixture (Oct 16, 2:30 PM PT)
- **Today's tasks don't use Tess's cobalt.** Cobalt is Tess's voice only. A run of tasks stays plain ink: it grows bolder as tasks get done, and the strike draws at done. The word that matters is ink at 700, not a colour. No new colour is added.
- **Groceries' hold title moves to round 2.** The left-to-right vermilion split goes. The whole title grows bolder and leans to Kitchen's green, and the strike draws at done.
- **One strike.** Round 2's 3 pt strike replaces RevealingHero's unused 2.5 pt one.
- **The recipe title is Title 44** (sheet 69), not Hero. That's a Builder B row.

## Confirmed values (motion lab's assumptions, Oct 16)
The 250 ms lift takes the whole title to the area's 72% mix, starting when the strike ends. "Quiet ink at 50%" is ink at 50% opacity at weight 500. The dry's 900 ms is measured from done, then it runs over 2 s. Before done, p steps as 0.85 × sets done ÷ sets planned. The weight axis is Inter Tight variable, 640 at full. All confirmed as the lab built them.
