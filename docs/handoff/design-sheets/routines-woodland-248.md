# 248 Routines woodland (v2, Oct 24 5:20 PM PT; not yet reviewed by Kaushik)

Board: https://claude.ai/artifact/KZkqPY2U6VxDMBETRu3CML. Working files are in `routines-woodland-248/`:
`board.html` (the board; open it next to `scene.html`), `scene.html` (the woodland scene on its own, 354 x 160 pt, for
embedding), `codex-woodland-lab.html` (the untouched Codex prototype, with its sample data and controls) and four
Codex screenshots. This sheet replaces the "Routines landing waits for the landing system" line in 238: the landing is
the woodland. The inner-page rulings of 238 (kind page, maker, "From another room", receipts) still stand.

## Where it came from
After the Claude weekly limit ran out (about 2:30 AM PT Oct 24), Kaushik worked with Codex (ChatGPT) from 2:45 AM to
about 8:35 AM PT. Codex built the woodland prototype in its chat. Chat log: `~/.codex/sessions/2026/10/24/rollout-2026-10-24T02-39-49-01a16d47-e04d-78c3-a4a9-bd5d99cb5109.jsonl`
on his Mac; prototype and screenshots: `~/.codex/visualizations/2026/10/24/01a16d47-e04d-78c3-a4a9-bd5d99cb5109/originals/`
(`habit-garden-lab.html`, `habit-layout-review.html`, `habit-lifecycle-review.html`, `habit-doors-review.html`, `*.png`).
`codex-chat-oct24.md` in `docs/handoff/` digests the whole chat.

## What he decided (in his words, 5-8 AM PT)
- KEYSTONE (11:30 AM UTC): every app gets one expressive element built from its own data, in the Home mosaic's slot.
  Home has the mosaic, Notes has the word wall. "Scene is my biggest takeaway": a small living world that reacts to what
  he does, adds, completes, and that helps him navigate into the app. Not a decoration, and it must do things by itself.
- The Routines scene is a habit woodland: plants are habits, consistent habits become trees, new ones are small plants.
  Show several species and sizes.
- Life stages: sprout, small plant at day 3, medium plant at day 7, tree at day 28, first fruit at day 35. Flowers mean
  done today. Fruit means a completed week and can be collected. A nest appears on trees at 30 days. Importance sets a
  size ceiling (small plant 32, shrub 46, small tree 68, canopy tree 104 in the prototype's units), so a steady small
  habit can stay a shrub.
- Withering: three days in a row missed, or three missed within seven days. Sparse canopy, leaves still falling.
  Bare (dead): eight days in a row missed. No leaves at all. One completion cannot restore a week with too many
  misses. A planned rest keeps the foliage and quiets the plant. Replanting starts a new cycle.
- Caretaker: sits by the lake, walks out to plant a new habit, water a finished one or collect fruit, then walks back.
  Whole reaction at most 5 s (1.65 out, 1.7 working, 1.65 back). Rule for ALL effects in the app: 3 to 5 s maximum.
- Layout: the lake sits in the central clearing; the middle stays empty until the forest fills. Up to 12 to 14 plants in
  the wide view (24 sample routines tested; the rest reached through groves and the index). Every visible plant has a
  tap target and no plant hides another. Neighbouring plants never share a color family; blue only at the outer edges;
  tree shape and color are independent; background trees stay faint; the lake is a quiet silver-jade with reflective
  wavelets (blue foliage made blue water confusing); the scene blends into the page background in Paper and Black.
  Slow clouds, birds visiting new trees, butterflies, evening fireflies.
- Completion: tap a routine to open it; swipe or hold to complete, with a short flower-petal bloom and a strike. No
  "Open routine" or "Mark done" buttons.
- REJECTED: tree icons inside lists ("not needed, especially that big"), tabs and pills, a long list, a stage legend
  ("new 3, mature 2"), a percentage with bars, packing a whole grove on one screen. For inner pages he wants dials and
  swipes between dimensions, as in the other apps, with calm density.

## The redesign (board 248)
Look rules applied: no tabs, pills, legends, percentages, counters ("N of M"), tree icons, door rows at the foot or
cards. Sentence case. Figtree words, Outfit numerals at half size, Newsreader for Tess. Colors follow sheet 241:
Routines room color plum (8E4A78 light, D79BC4 black) on the title and the focused door; done green (2F6450 / 8EC7AE),
needs care wine (9A2541 / EE8E9C), new and fruit gold (7E6A1E / D9C27A), resting and begin again slate (34506F /
A7BCD6). Each page uses 3 to 4 of these.

1. Landing. Title in plum. One Tess sentence of three big phrases, each its own color so the big-type rule holds:
   "Three done, eight to tend, three to give a little care." (green, plum, wine). The woodland sits in the Home
   mosaic's slot (402 x 182 pt, scaled from the 354 x 160 scene). One caption line under it names a tapped tree and
   says its stage; a second tap opens the routine. Below, the three-place dial (64 pt slots, focus 30 pt 600 plum,
   neighbours 18 pt at 60% with up to 1.8 pt blur, none under Reduce Motion or Low Power) turns through the doors:
   Today, Body, Mind, Home, Fruit, Across the lake. The focused door's three most urgent routines sit beside it (name
   18 pt 500, one state word 12 pt in its role color). Moving the dial moves the woodland toward that grove. Swipe
   right on a routine is Done (petal bloom, Undo for 10 s), swipe left is Not now. Foot: the action word "Plant" at
   bottom left (starts the maker), Tess at bottom right. Nothing else.
2. Inside a grove (also Today, Fruit, Across the lake). Back word "Routines", grove name 38 pt 700 plum, a 100 pt crop
   of the woodland, then the dimension line: three places, sideways turns them: Needs care (wine), To tend (plum),
   Done today (green), small caps 11 pt 600 tracked, a hairline under. Below that the focus wheel from 230 and 233:
   one routine in detail (name 38 pt 600, one line of age and stage, its seven strokes, one state word), the others
   as names that fade and blur away. Up and down turn the routines. The foot word follows the focus: Done, Begin again
   or Collect. Swipe right on the focused routine completes it.
3. A routine. The whole life on one hairline with five stage words (Sprout day 0, Small plant day 3, Medium day 7,
   Tree day 28, Fruit day 35), a marker that moves, the current stage large in plum (wine when withering, slate when
   bare). Under it the seven strokes (solid kept, dashed guide) and one plain sentence ("Six kept in the last seven
   days") and one care sentence. Foot: Done, Collect or Begin again.
Soft words for hard states: withering reads "needs care", bare reads "begin again", rest reads "resting". Never
"missed", "dead" or red banners in the UI.

## Motion
Everything through MotionPolicy; any effect 5 s or less. Dial and wheel: springy 0.35 s slide with the blur easing in.
Petals: 7 petals, 1.3 s, with a light haptic; strike then fade of the row. Caretaker walk 5 s with eased steps. Reduce
Motion: no walking caretaker, no petals, no blur, no drift; cross-fades only; the woodland shows a still state.

## Build notes
- The scene is a 2D canvas painter in `scene.html` (functions `landscape`, `plant`, `pond`, `keeperStep`,
  `layoutGarden`, `healthMetrics`, `lifeStage`). In the app, port it as a SwiftUI `Canvas` driven by TimelineView and
  fed from the Routines objects (stage and health from the log), not from the prototype's sample data.
- Stage and health rules are in `healthMetrics` and `growthInfo`. Port the thresholds above exactly.
- Light and Black modes both tint the scene; the scene edge fades to the page color, so keep the slot's background the
  page color.

## v2 (his 4:57 PM PT note): landing is a summary; the list behind a door is the open design problem
His words: the landing should be a summary with quick updates (what is going on, what we are doing) and doors. Behind a
door is a list of routines, and that is where he and Codex got stuck: "we need to invent or brainstorm various ways of
showing these routines." He also wants better ways to show one routine once it is open. What is there is "good enough";
try these changes. Board v2 has all of it live.

Landing v2 (replaces landing 1 above):
- Title, then the sentence (three big phrases, three colors), then the woodland in the mosaic slot, then a caption line
  for a tapped tree, then TWO updates (fixed 64 pt slots, 17 pt light, the routine's name in 600): "what is next"
  (the earliest planned tend, "Tidy a little is next, around 5:30") and "what needs a look" (the most urgent care, bare
  or fruit: "Take screen breaks needs a little care"). Each update is a routine row: tap opens it, swipe right Done,
  swipe left Not now, Undo 10 s.
- Doors on the three-place dial (64 pt slots): Today, Body, Mind, Home, Fruit, Across the lake. The focused door shows
  up to three short state lines instead of routines ("Three to tend", "One needs a little care", "One to begin
  again"), each in its role color. The list is behind the door. The woodland leans toward the focused grove.
- Foot: "Plant" and Tess. Nothing else.

The list behind a door: a lab of five (shown on "All routines"; none picked yet; recommend trying Skyline, Cloth and
Sheaf in the build spike, since they scale to 24 routines, and keeping Spoken for the Tess voice):
1. Spoken: short paragraphs grouped by state; names are the links; a tap opens the detail under its paragraph.
2. Skyline: each routine is a word standing on a ground line, taller the older it is, state color, sorted by grove,
   age or state on the top line (sideways turns it). Group names small caps under the ground.
3. Map: a clearing seen from above. X is how many days it was kept this week, Y is age. Names are placed without
   overlap. No axis labels beyond "needs care", "steady", "older".
4. Cloth: a ledger. One row per routine, name and seven strokes; regroup by grove or by state; a tap opens its line in
   place with its action.
5. Sheaf: each grove is a stack of blurred names; pull a stack down (or tap) and it fans out into rows while the others
   slide away; this is the pull-apart move he liked in the Codex studies.
The focus wheel from round 1 (inside a grove) stays a sixth option.

One routine, three ways (switch under phone 3): the whole life on a hairline (round 1); the weeks (a big Outfit
number of days kept with its unit at half size, then the last four weeks as rows of seven strokes); the day (a 24 hour
hairline with the usual time and now, and its links to the rooms it touches). A fourth idea to try: the routine's own
plant shown large, and tapping a part of it opens that fact.

Rules held in v2: no cards, pills, tabs, percentages, "N of M" counters or tree icons; unit at half size; strokes are
the Habits grammar; the 10 s Undo; the dial blur 1.8 pt, none under Reduce Motion.

## Open (with recommendations)
- Which groves: the chat used Body, Mind and Daily life; the Routines rulings used Mornings, Evenings, Body, Home, Mind
  and Borrowed from other rooms. Recommend Body, Mind, Home, plus Borrowed from other rooms as a grove across the lake.
  Mornings and Evenings are times of day: filters on Today.
- Withering and bare against the older "nothing is owed, no missed" Routines rulings (238, ADHD rules). He asked for
  withering himself, so his ask wins. Recommend keeping his thresholds, keeping the words soft, and letting a planned
  rest and the Small way protect a tree. That last point is not yet decided with him.
- Private routines (pills, body): they grow trees on the phone only and never reach Claude, widgets or backups.
- His verdict on all of 248. Nothing here is approved yet.

## Verdicts (Kaushik, Oct 25)
- List behind a door: **Sheaf**. Keep improving it: show more in each stack, smoother transitions, more inventive moves.
  Continued in sheet 249.
- One routine: **the whole life (A)** stays, but the focus moves to the routine itself: its steps (a routine can be
  one thing or many steps) and its full details first, motion second. Trends and stats are wanted, but not the
  strokes and weeks shown in v2: find a better way. Continued in sheet 249.
- Groves: **Body, Mind, Home, plus Borrowed from other rooms across the lake** (Mornings and Evenings are filters on
  Today).
- Withering: **his thresholds, soft words, and a planned rest or the Small way keeps a tree green.**
