# Sheet 294: things roll over edges (Oct 26)

Kaushik, 3:41 PM PDT: "when we are scrolling stuff... like the one thing section... the text basically goes behind
some thing... the edge maybe we could improve how that looks... when things are going across a boundary... make it
look like they're rolling over so it basically gets subtly smaller and blurred out."

Board: https://claude.ai/artifact/Tq1KkB6diZUzCjV6xp98Xp. Drag the Bridge's one thing across or up.

## 1. The rule

Nothing is ever cut by an edge. Anything that crosses the edge of a clipped place rolls over it, like paper going
over the edge of a drum:
- **Only past the edge.** Nothing changes while the thing is fully inside. The roll is driven by how much of it is
  already past the edge, so it stays readable under his finger.
- **It fades through the edge, never at a line.** The moving thing carries its own soft gradient, 28 pt deep, that
  ends exactly at the edge. So the part about to leave is already faint, and nothing is ever sliced. The gradient
  sits on the moving thing only, so nothing at rest is touched and no box or band is ever drawn.
- **It rolls away, a little.** By the time three quarters of it is past the edge, it has tilted up to 16° away over
  that edge (pivoting at the far side), shrunk by up to 4%, blurred by at most 1.2 pt and faded to 8%. The curve is a
  smoothstep, so the start is gentle.
- **v1 was wrong (Kaushik, 3:56 PM):** v1 used a blur band along each edge. It read as a square box, blurred the
  first letters of text at rest by the edge, and still cut the second line. The band is gone.
- **Driven by position, not time.** A drag, a release that flies the card off, and the next card coming in all go
  through the same roll. Coming in is the same roll in reverse.
- **Reduce Motion:** no roll and no band. The crossfade from sheet 288 applies.
- **Never blur as a cover.** This is the motion of something leaving. It never replaces the layer rules (sheet 291).

## 2. Where it applies

| Place | What crosses the edge |
|---|---|
| Widget (one thing), every landing | The card going across or up, and the next one coming in. Built on the board. |
| Page rows (level 1) | The rows when a door's list turns or scrolls. Built on the board for the Watch's routine list (297). |
| Switcher word (every landing) | The word under his finger when he drags it across. Built on the board (297): it fades through the edge only, with no lean, because the drag already skews it. |
| Doors dial (reel) | It already has this: neighbours get smaller and blurred, which is the same roll. The reel's spin uses the same fade. |
| Every other place | See sheet 298: each kind of place has its own clean exit. |
| Day strip, week fold | The hours or days scrolling across. |
| Lookout hours | The hour columns going left. |
| Log wall | Words leaving the wall on a page change. |
| Departure board | No. It flaps in place and never scrolls. |

### Per place (297)

| Place | Fade depth | Lean | Shrink | Blur and fade |
|---|---|---|---|---|
| Widget card | 28 pt | 16° | 4% | yes |
| Rows | 18 pt | 10° | 3% | no: the mask is the fade, the row's own opacity stays its screen's |
| Switcher word | 22 pt | none | none | no |

A row parked half past the bottom of a list at rest is past the edge, so it shows rolled away. That is right: it
reads as "more below" instead of a cut line.

## 3. For the builders

- One modifier, `.edgeRoll(axis:depth:lean:shrink:)`, with the three presets in the table above. It reads each child's frame against the clip with `onGeometryChange` (or
  `visualEffect` with `GeometryProxy`) and applies `rotation3DEffect`, `scaleEffect`, `blur` and `opacity` from the
  overflow fraction. It goes through `MotionPolicy`, so Reduce Motion turns it off.
- The fade is a `mask` on the moving view: a linear gradient from clear at the clip edge to opaque 28 pt inside,
  placed from the same geometry. Never a blur or material over the clip.
- The look rules still hold: this is not glass, and it has no tint or fill.

## 4. Board fix

Swiping the Bridge's one thing across on the board left the widget empty. The board moved the wrong card off
(it read the current card after replacing it). This is fixed on the board. The phone app has its own code, but its
widget swipe should be checked for the same mistake.
