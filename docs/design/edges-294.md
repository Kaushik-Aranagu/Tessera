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
- **It rolls away.** By the time three quarters of it is past the edge, it has tilted up to 24° away over that edge (pivoting at the
  far side), shrunk by up to 5%, blurred by up to 2.4 pt and faded to 40%. The curve is a smoothstep, so the start
  is gentle.
- **The edge itself is soft.** A thin band along each edge (18 pt across, 16 pt up and down) blurs by 2.5 pt whatever
  passes under it. The band fades from the edge inward, and shows only while something is moving (180 ms in and
  out), so text at rest is never touched.
- **Driven by position, not time.** A drag, a release that flies the card off, and the next card coming in all go
  through the same roll. Coming in is the same roll in reverse.
- **Reduce Motion:** no roll and no band. The crossfade from sheet 288 applies.
- **Never blur as a cover.** This is the motion of something leaving. It never replaces the layer rules (sheet 291).

## 2. Where it applies

| Place | What crosses the edge |
|---|---|
| Widget (one thing), every landing | The card going across or up, and the next one coming in. Built on the board. |
| Page rows (level 1) | The rows when a door's list turns or scrolls. |
| Doors dial (reel) | It already has this: neighbours get smaller and blurred, which is the same roll. The reel's spin uses the band. |
| Day strip, week fold | The hours or days scrolling across. |
| Lookout hours | The hour columns going left. |
| Log wall | Words leaving the wall on a page change. |
| Departure board | No. It flaps in place and never scrolls. |

## 3. For the builders

- One modifier, `.edgeRoll(axis:)`. It reads each child's frame against the clip with `onGeometryChange` (or
  `visualEffect` with `GeometryProxy`) and applies `rotation3DEffect`, `scaleEffect`, `blur` and `opacity` from the
  overflow fraction. It goes through `MotionPolicy`, so Reduce Motion turns it off.
- The edge band is a `blur` mask on the clip's edges, shown while the place reports a move in progress.
- The look rules still hold: this is not glass, and it has no tint or fill.

## 4. Board fix

Swiping the Bridge's one thing across on the board left the widget empty. The board moved the wrong card off
(it read the current card after replacing it). This is fixed on the board. The phone app has its own code, but its
widget swipe should be checked for the same mistake.
