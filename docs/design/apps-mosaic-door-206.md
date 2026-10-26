# 206 The apps list talks to the mosaic, and the pixel doorway (Oct 23, 10:25 AM PT)

Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp. Turn the apps wheel, then tap the middle app. Builds on 205 (apps list), 201 (moments) and 202 Revision 3 (edge). On by default.

## 1 App glance (a quiet moment per app)
- When the wheel settles on an app for 240 ms, the mosaic plays that app's glance moment.
  - Window 44 x 24, comes in by gather, hands back by dissolve after 3.4 s.
  - The sentence does not change.
  - A new pick restarts the glance.
- The mood behind gets an 18% wash toward the app's accent, and the rim samples that washed mood, never the motif.
- Motifs are pixel signs in the accent, centered:
  - Training: an 11 x 5 barbell that lifts one row every 700 ms.
  - Kitchen: an 11 x 5 pot with three steam pixels rising.
  - Routines: one clock hand on bare pixels going round (650 ms per radian), with a center pixel and no ring.
  - Tasks: a check mark drawing itself, one step per 90 ms, in ink.
  - Notes: three lines being written, with a blinking cursor on the last.
  - Lists: three rows whose lines tick to done one after another.
  - Money: three filled pixel discs (radius 3.4 tiles, no outline), each filling from the bottom to a different level; the unfilled part is the accent mixed 70% toward ground. No numbers and no bars.
- Privacy: motifs are fixed drawings and carry no data. No amounts, health, body or calories.
- Reduce Motion: the motif is shown still, with no lift, steam or rotation.

## 2 The pixel doorway (opening an app)
- Tap the middle app:
  - From the mosaic's center a wave spreads across the whole phone at 0.75 ms per pt, plus up to 30 pt of hash jitter.
  - Each 4 pt tile turns into the app's accent, flips (scaleY |cos|, 170 ms, second half mixed 55% toward ground), and lands as page ground.
  - When the wave has passed, the app's page is there.
- Back ("Home", top left) runs the same wave in reverse, back into the mosaic.
- Haptics: one soft tap at the start, one light tap when the page lands.
- Reduce Motion: a plain swap.
- Builder A: render as one Canvas or Metal pass over the screen tiles, using MotionPolicy timing.

## Lanes
- Builder A: glance motifs in MosaicView, doorway transition.
- Builder B: wheel settle callback into MosaicMoodPicker, and the navigation hook for the doorway.
- Core: add `app(kind)` glance cues to the 204 switchboard, with rank "your apps", so the priority rules apply.

## Reviewer guards (10:22 AM)
- The wash stays inside the mosaic window and rim. It never tints the page or the apps list.
- The doorway's tile flip is 170 ms, and it lands on the plain page with no pixel texture left behind.
- No app accent within ΔE 10 of Tess cobalt.
- Reduce Motion: the doorway and the glances are plain swaps.

## Ruling: no back word (coordinator, Oct 23, 4:16 PM)
Kaushik asked why there is a back word at all. Rooms and Today show no "< Home" or "Home" word at the top. To go back, swipe from the left edge, which plays the doorway in reverse; VoiceOver escape also works. The space the word used goes to the lintel.
