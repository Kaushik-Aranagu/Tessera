# 268 Routines keystone: the woodland, finished (v1, Oct 25; not yet reviewed)

Board: published from `routines-garden-268/board.html` (link in the session handoff). Renders in
`routines-garden-268/renders/` (S0 landing paper+black, S1 hours and weather, S2 the moves).

## Why (his words, Oct 25)
"I don't need realistic images... the garden we previously had works, but a little bit improved, more finished, more
smooth." And: "It's about making it functionally creative, functionally fun." Rounds 262-267 are closed. This is the 248
woodland, repainted from scratch (not the Codex painter) and given the tending functions.

## The look
One light from the real hour (keyframed sky, sun and moon arcs, warmth), three hazed hill layers with far tree
silhouettes, a lake that holds the sky colour and the sun's glint, soft drifting clouds, sway. Trees are flat
illustration with a crisp two-tone terminator toward the sun, a few lit leaf dabs, ground shadows that swing with the
sun. Kinds: oak, round, poplar (tall), pine (weeklies, back row), blossom, shrub. Three rows (back 0.5, mid 0.72,
front 1.0); the lake keeps the middle clear. Edges dissolve into the page (9 pt). Weather from the Weather app: rain
(streaks, lake ripples), snow (white ground, flakes), fireflies at night, the caretaker's lantern.

## What it does
- Hold a tree 1.5 s: a small cloud rains on it; on release it stands up, flowers open, a bird lands (4 s). Done.
- Buds are steps: N buds on a N-step routine; first tap selects (caption under the slot), each next tap opens a bud.
- Missed days: dry trees yellow, shrink and sag; leaves fall on the grass. No counter, no red.
- Rake: swipe along the grass under a tree; leaves blow away. Still thirsty until watered.
- Plant: tap open ground; the caretaker walks out, digs (soil flecks), walks back; a sprout appears.
- Planned rest: a lamp in the tree; it keeps its leaves.
- Growth: sprout <3 d, small 3-7, young 7-28, tree 28+, fruit 35+ (broadleaf only). Automated routines wear a thin
  light arc and are tended by the caretaker.
- Everything 1.5 to 4.5 s, inside the 5 s rule.

## Known rough edges
Day-one sprout is tiny at the front row; the selection hairline is faint; touch targets for back-row pines need the
row bias tuned on device; Reduce Motion path not written yet (still frames, cross-fades).

## Screenshot tooling (new)
Headless Chromium works here now: standalone build from cdn.playwright.dev unzipped to /tmp/claude-49350/chromium;
`session-oct25/scripts/shot.sh <html> <png> [w] [h] [ms]` with `QS='?hour=..&demo=..'`. Board supports
`?hour= &weather=rain|snow &demo=water&p= | watered | steps | swept | plant&e= | rest | month`.

## v2 (his note, Oct 25): "make sure the edges are blended well into the background... right now it looks like a frame"
The scene now dissolves instead of ending: (1) the upper sky thins into the page colour; (2) the whole scene leans
toward its background (black 26%, paper 14%) so there is less contrast to fade; (3) page-colour mist over the outer
104 pt of each side and the bottom 56 pt; (4) an alpha falloff (smootherstep, 19% of the width at the sides, 14% top,
22% bottom). The background colour is read from whatever the canvas sits on, so it works on the phone page, on black
and on the board. Outer trees moved inward so the fade never ghosts a routine. Hardest case left: a bright day on black
still reads as a soft glow (no edge).

## v3 (his notes, Oct 25): "too aggressive, too small... extend toward the edges"; "reactions more dramatic and visible"
- The canvas now spans the phone's full width (402 pt, the scene centred, 24 pt of bleed each side); sky, hills, meadow
  and path continue into the bleed. Side mist 56 pt, side alpha falloff 11%; top 12%, bottom 18%; scene lean 12% paper /
  22% black. Board sandbox is 402:182 too.
- Watering: the cloud gathers and grows, 26 drops, splashes at the foot, a cool glow on the tree while it pours. On
  release the tree springs (damped bounce, 2.6 s) with a warm glow and a light bloom; 34 petals in four colours scatter
  from the whole crown; 14 sparks rise; a ring spreads on the grass; two birds fly in from the open sky and land.
- A step: the bud pops (12 petals, a ring, a small bounce).
- Planting: soil bursts, a ring, the sprout springs.
- Ambient: a thirsty tree lets a leaf go now and then; butterflies around tended trees by day; a fish rings the lake.
- Bursts are per canvas, state is shared (finish/bloom change R once, burstDone/burstBud play on every canvas).

## v4 (his note, Oct 25): "add a little bit of colors and different kinds of trees, different shapes"
Eleven kinds now: oak, round, poplar, pine, blossom, shrub, plus willow (soft dome and a curtain of curving fronds with
leaves; yellows when thirsty), maple (orange-red), birch (white bark with dark marks, airy light crown), jacaranda (flat
purple crown, flowers on the grass under it), umbrella pine (flat crown on a forked trunk), lemon (dark green, yellow
fruit). Sample: Water = lemon, Stretch = lavender shrub, Lunch = maple, Tidy = birch, Walk = poplar, Journal = willow,
Swim = pine, Read before bed = blossom (new), Backup = shrub, Badminton = umbrella pine, Call family = jacaranda.
Neighbours never share a colour family. Wildflowers (white, yellow, pink, lilac, coral) dot the meadow, off the lake.
