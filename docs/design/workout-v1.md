# Workout v1 (live)

Dark material. A foreground process: it rises as a full-screen cover. Mockup: `mockups/MachinedWorkout.dc.html`.

## Layout and axes: x = exercises, y = sets, z = the exercise page
- **Top edge:** the lit process seam. Label row: "PUSH DAY A · 12:48 ELAPSED" on the left, "1 OF 5" on the right.
- **Exercise lane:** one name per page at 40pt, weight 850.
  - The next name peeks 24–30pt in, dimmed to `#4A4844`, with the x ruler below.
  - Tap the name to zoom into the exercise page.
- **Seam,** then the finished sets stacked above eye level, the latest two visible: "SET 1 · 80 × 8 · e1RM 101.3".
- **Current set:** one raised block, radius 22, inset 12.
  - **Header:** "SET 3 OF 4" with "TARGET 8 @ 82.5". When the dialled set would beat the best e1RM, the header turns cadmium: "SET 3 · NEW BEST IF YOU HIT IT".
  - **Weight:** a 64pt tabular mono numeral with `.contentTransition(.numericText(value:))`, followed by "kg".
  - **Plate maths, live:** one side of the bar drawn as plates, plus the text "31.25 KG / SIDE".

    | kg | height | colour |
    |---|---|---|
    | 25 | 64 | vermilion |
    | 20 | 64 | cobalt |
    | 15 | 56 | cadmium |
    | 10 | 46 | sage |
    | 5 | 36 | `#D9D6CF` |
    | 2.5 | 28 | `#55534F` |
    | 1.25 | 22 | `#A8A49C` |

    Each plate is 9pt wide with radius 2, a 1px light left edge and a dark right edge.
  - **Reps drum** (opposite axis to the dial): a recessed slot 82×146, radius 10.
    - Values 0–30 at a 44pt pitch, three rows visible.
    - The centre row sits under a raised lens with no glass (inset 6, radius 6) and is 34pt. The others are 21pt and dim.
    - The top and bottom fade into the recess.
    - "LAST 8" sits below as a ghost target.
  - **Weight dial:** a recessed strip across the block, radius 12, 84pt tall. See "Weight dial" below.
- **Below the block:** the next set, dimmed ("SET 4 · 8 @ 82.5").
- **Hold-to-log key:** raised, radius 16, 76pt tall, with a recessed channel inset 8 (radius 8).
  - The fill is a vermilion→orange gradient over 800ms.
  - Label "Hold to log set 3", with "82.5 × 8" on the right.

## Weight dial
- **Ticks:** one every 2.5 kg at a 14pt pitch, 0–160 kg. Minor ticks 14pt tall; 22pt every 5 kg; every 10 kg a 34pt, 2pt-wide major tick with a mono label.
- **Needle:** a fixed vermilion 2pt index needle at the centre with a soft glow. The edges fade out.
- **Momentum:** a flick settles on a valid plate load.
- **Haptics:** `.sensoryFeedback(.selection)` on every tick and `.impact(weight: .heavy)` on every 10 kg.
- **Default:** last set's weight, so most sets need no input.
- **Accessibility:** an adjustable action, plus a "Type value" action that opens a keypad.

## When a set is logged
1. **Seat:** the set row travels up into the done stack (about 118pt), overshoots by 2pt, settles back 1pt and rests.
   - It runs as a 620ms keyframe animation.
   - Haptics: a rigid impact when it lands, then `.success` when it locks.
2. **Paint bleed:** a 2pt line of paint grows along the seam under that row over 900ms and stays.
   - The colour cycles vermilion → cobalt → cadmium from set to set.
   - The session leaves a stripe of colour as its history.
3. **Tess:** plays `done` (merge plus a ring splash).
4. **Rest starts, in the same block, which now plays a different role:**
   - The big numeral becomes the countdown in cadmium ("2:30 rest").
   - The dial track fills cadmium at 16%, with a 2pt cadmium edge that drains every second.
   - The dial can't be dragged during rest.
   - The key becomes "Skip rest".
   - When rest ends, the dial turns back into weight.

## PR: the only celebration
- A 2pt light sweep (`#FFE9B8`) runs twice along the block's top chamfer.
- Tess plays `thinking`-style bloom, then `done`.
- The note reads "New best: e1RM 107.7".
- `.bouncy` is allowed only here. No confetti.

## When an exercise is finished
- The key reads "Next exercise →" and pages the lane.
- When the whole workout is finished, the session stack compresses into one object and drops into today's history. This is still to design.
