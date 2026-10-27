# The first-review day reel (Design item 52)

**Kaushik's principle, in one line:** one screen packed for the moment, one plain line per thing, and detail one tap down; the day should read the same from morning to the 4 AM turnover.

One 60 fps recording walks a day across the new sheets (41 Home lines, 42 the tab lens, 44 training mode, 46 the week, 48 living colour), once in Porcelain and once in Obsidian, so the seams between them show before Kaushik's next look. Every seam found is listed below with its owner. Nothing here is a new rule; where the reel showed a gap, the fix is written on the sheet that owns it.

- Recordings: `recordings/day-reel-porcelain.mp4` and `recordings/day-reel-obsidian.mp4` (36 s each, the same day). Source `studies/day-reel.html` (`?look=por|obs`, `?play`).
- Boards: `mockups/day-reel-porcelain.png`, `mockups/day-reel-obsidian.png`, six stations of the day.

## The day
| Clock | Station | Sheets in play |
|---|---|---|
| 7:10 | Home. "Thursday morning", context "Push A at 6", hero "Nothing due till then.", the Start key's line, Next: Tacos tonight (2 to buy), Water the plants. Lagoon blooms in (morning pick at his first write) | 41, 48 |
| 7:12 | Hold the tabs, slide to TRAINING: the pages shrink to 78% on the stage, the lens settles under TRAINING | 42 |
| 12:15 | Training at rest: strip at the page top, "Push A at 6", Title 44 "Bench press first.", START with its line, the four lanes, the plan line at 688 | 44 |
| 6:42 | START lifts into the strip segment; live mode, "Push A running. Bench press first." in Tess's line | 44, 38 |
| 7:40 | Home again: "Push A done. Bench 85 × 8, a best." The done fleck arcs to the day label and blooms there. Ember blooms once the Done beat has dried | 41, 38, 48 |
| 7:45 | Slide to REVIEW: the week arrives band by band; a tap on Thursday makes the page read "Thursday was the bench best." | 42, 46 |
| 11:10 | Home at night: "Thursday night", "Pull A tomorrow at 6.", nothing pending. No palette change (quiet hours) | 41, 48 |
| 4:00 | The turnover: the day label rolls to Friday, context and hero to Pull A, Friday's key and Next fade in, Aurora blooms carrying the late lean | 41, 48 addendum |

## Seams found, and who owns them
1. **The lens stage on light looks** (42 ↔ 43). Sheet 42 wrote the stage as "#0A0A0C in Obsidian, the look's ground darkened 4% in the others". Builder A's #342 does exactly that and it reads right in Porcelain on the reel, so the rule stands. Owner: none; 42 already says it.
2. **A palette change after Done** (48 ↔ 38). Ember may not bloom while the Done beat is still drying: the reel holds Ember until the fleck has landed on the day label and the hero's dry (2 s) is over, so two things never arrive at once. Rule: a living-colour change waits for the end of any `Theme.Motion.dry` in flight, on top of 48's idle gate. Owner: Builder A (`TessSoul.repaint(to:)` reads the dry timer); written into `living-colours.md` cadence as a line.
3. **Never in a workout** (48 ↔ 44). Lagoon's "night after a push day" and Ember's "a best today" both become true during the workout; neither may paint until he is back on Home and idle. The reel keeps the soul still from START to Done. Owner: Builder A's idle gate (48 already says it); the reel just proves it reads right.
4. **The Thursday dab on the week** (46 ↔ 44). The training mark for Thursday appears on the Review week only once the workout is done, never at START. A running workout shows nothing on the week; the day log holds it. Owner: Core (WeekFacts counts finished sessions), Builder B (46).
5. **Title 44 on Training against Hero 56 on Home** (44 ↔ 41). The two sizes differ by design: Home's hero is the one thing of the moment, Training's title is one page's heading. The lens slide shows both at 78% side by side and the step reads as hierarchy, not a mismatch. Owner: none.
6. **The Claude-worded context line** (41 ↔ AI home-lines). When Claude rewrites the context line it arrives wet in `tess` and dries to `context` over the house 2 s; the reel shows the phone's own wording only, so no cobalt rests on Home. Owner: Builder B (AI-1), already in `docs/ai/home-lines.md` §4.
7. **The fleck's target** (38 ↔ 41). With the day bar gone the done fleck lands on the day label (41 §4). The reel shows the 30 pt wash blooming on "Thursday night"; the label's ink never changes. Owner: Builder A (task-reward), already in 41.
8. **The turnover carries the lean** (48 addendum). At 4:00 the palette change is the one allowed inside quiet hours and it arrives with the day roll, not before it: the label rolls first (320 ms), then the bloom (900 ms). Owner: Builder A; the order is written in `living-colours.md`'s addendum.
9. **Review's back word** (42 ↔ back-word). Arriving at Review by the lens, the page has no back word (it's a tab page). Tapping Thursday keeps it that way; the day's lines simply replace the week's three. Owner: Builder B (46), as drawn.

## For the builders
- Builder A: seam 2 (hold a repaint while a dry is in flight), seams 3 and 8 are already on sheet 48.
- Builder B: seams 4 and 9 on sheet 46; seam 6 is on the AI thread's home-lines.
- Core: seam 4 (WeekFacts counts finished sessions only).
- Nothing for Product to decide; the reel is for Kaushik's next look.
