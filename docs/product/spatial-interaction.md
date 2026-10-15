# Spec: spatial layout, controls and materials

*Product lead, 2026-10-15. Kaushik's direction from the Product lead thread. Applies to every screen in v1 (home and Workouts) and is handed to Design studio to design and prototype.*

## 1. Three axes, each with one job

Pages must not get long. Content spreads across both screen dimensions, and depth is used for drilling in.

| Axis | Meaning | Gesture |
|---|---|---|
| **Vertical (y)** | Time or sequence inside one thing: now → later, set 1 → set 5 | Swipe or scroll up and down |
| **Horizontal (x)** | Siblings: the next exercise, the next day, the next app | Swipe left and right |
| **Depth (z)** | Into an object: row → object page → linked object | Tap to zoom in; pinch or swipe down to come back out |

**Rules**
- **A page is about one screen tall.** At most about 1.3 screens; anything beyond moves to a sibling (x) or into depth (z).
- **Pages can hold their own small surfaces:** a strip inside the page that swipes sideways, or a short stack that scrolls up and down, so the page itself stays short.
- **Nested surfaces never fight their parent.** A surface inside a horizontally paged screen scrolls vertically, or it is clearly bounded and claims horizontal swipes only inside its own frame. Edge swipes always belong to the system and the page.
- **You always know where you are:** a quiet position indicator for x and y on each surface (not dots in a capsule; see materials), and the object path for z.
- **Spatial memory:** surfaces open where you left them and keep stable positions.

## 2. Home (v1)

- **Centre:** Now. The one next thing, with the day strip and its moving "now" marker.
- **Vertical surface on Now:** Next and Later, scrolling inside a bounded area, never the whole backlog.
- **Horizontal siblings:** today's workout on one side and the Review view on the other. Swiping on the day strip moves to yesterday or tomorrow.
- **Depth:** tapping anything zooms into its object page.

## 3. Workouts (v1)

Live workout mode is the clearest use of the three axes:
- **x = exercises** in today's session. Swipe to the next exercise; the strip shows what's left.
- **y = sets** within the current exercise. The current set sits at eye level; finished sets stack above, the remaining ones below.
- **z = depth:** tap the exercise name for its page (best e1RM, history, PRs, muscles); tap a muscle to go one level deeper.

## 4. Controls: physical and creative, never stock

Inputs should feel like instruments. Each one needs a Reduce Motion version and haptics.

| Input | Control | Behaviour |
|---|---|---|
| **Weight** | A precision dial (scroll wheel) | Detents every 2.5 kg with a tick haptic; plate math updates live beside it; a flick spins with momentum and settles on a valid plate load |
| **Reps** | A vertical drum | Numbers roll with `numericText`; last time's reps shown faintly as a ghost target |
| **RPE** | A short slider with machined stops | Optional, one swipe |
| **Rest** | The dial counts down, rather than a separate timer | The same object changes role, so nothing new appears |
| **Logging a set** | Hold to log | The set "seats" into its slot like a part clicking into a fixture, with a firm haptic |
| **Personal record** | A rare, bigger moment | The one place for a celebration (a light sweep across the machined edge, plus Tess's bloom) |
| **Finishing a workout** | The whole session stack compresses into one object that drops into today's history | |

**Every edit uses direct manipulation where possible:** drag a value, turn a dial, pull a row. No standard pickers, steppers or segmented controls.

## 5. Materials: "zero tolerance"

The look is precision machinery: parts that fit together so tightly the boundary is almost invisible.
- **No pills or capsules anywhere,** including buttons, tags, status indicators, background-process markers and page dots. Shapes are rectangles with small, concentric corner radii.
- **No cards.** Surfaces are separated by hairline seams (about 0.5 pt), a one-step tonal change and a single light source catching a chamfered edge, never by boxes, gaps or shadows.
- **Liquid Glass is welcome** for floating controls and chrome, but shaped like machined lenses or inlays that sit flush, not the default capsule.
- **Moving parts move like machinery:** they slide in their tracks, seat with a detent and never bounce loosely. The house spring stays tight; `.bouncy` is reserved for PRs.
- **Replaces earlier ideas:** the "pill in the status strip" for background processes and the glass "rest pill" in earlier docs are dropped. A running process now shows as a lit seam along the top edge, and rest lives in the weight dial.

## 6. Open for Design studio

- How the x/y position indicators look without dots or capsules.
- The exact seam, chamfer and light treatment for the chosen base theme.
- Whether the home's horizontal siblings wrap around or stop at the edges (the product default is that they stop, for spatial memory).
