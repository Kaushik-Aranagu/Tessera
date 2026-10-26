> REJECTED by Kaushik, 11:16 AM Oct 23: the dial layout and the simplified Tess drawing. Superseded by 209. Section 3 (screens as sheets) stays a sketch only.

# 208 Apps dial with a lens, Tess on her own layer, screens as sheets (Oct 23, 11:25 AM PT)

Board: https://claude.ai/artifact/1aLhfDtkLbG2dFYbjUFVmp. Kaushik's 11:11 and 11:12 AM asks:
- no "Apps" label
- a dial with a cool lens effect
- Tess down at the bottom, on an invisible layer over everything
- screens as overlays on top of each other
- each app you switch to moves the mosaic to something about that app

This replaces 205 part 2's vertical list and keeps 205's facts. On by default.

## 1 The apps dial (bottom of Home, edge to edge, 96 pt tall)
- No label. App names (Figtree 16, ink 3) sit on a shallow arc (radius 620 pt), 104 pt apart, each rotated along the arc and slightly smaller away from the center. The ring wraps round.
- Drag sideways: it follows the finger 1:1. On release it keeps the fling velocity (the target is position - velocity x 240 ms) and springs to the nearest app. One selection tick per app passed.
- The lens: a 92 pt circle at the center.
  - Inside it, the name under it is magnified up to 1.32x with a fisheye (1.32 x (1 - 0.4 q^2), where q is the distance from the lens center over the radius), in Figtree 600, in the app's accent.
  - The rim is a 1 pt edge-color circle with one light highlight arc at the top left and one faint shade arc at the bottom right. This is Liquid Glass on the navigation layer: no blur and no fill other than the page color.
- Under the dial, one fact line, centered: the 205 AppSummaryLine, revealed from the center outward by a clip, never a fade.
- Tap the lens to open the app through the 206 pixel doorway. Tap any other name to spin it into the lens.
- Each new pick plays that app's 206 glance in the mosaic after 240 ms, so the mosaic always turns to something about the app you're on.
- VoiceOver: the dial is an adjustable element whose value is "Kitchen, Tacos tonight, 4 to get". Reduce Motion: no fling, it snaps.

## 2 Tess on her own layer
- Tess, exactly as built (TessSoul: three dabs mixing by multiply on light and screen on dark, with her eyes and blink), sits at the bottom left just above the dial.
- She lives on a clear full-screen layer above every other layer, including the mosaic, sheets and the doorway. Only Tess and her line take touches; the rest of the layer passes touches through.
- Her one line sits beside her in ink, never cobalt. It changes with a clip from the left.
- Tapping her plays the Tess moment in the mosaic.
- She never fades; a resting Tess uses TessSoul's resting mode.

## 3 Screens as sheets
- Home is a stack: the page (sentence, Next, dial) over the mosaic layer, with Tess's clear layer on top.
- New features can come in as their own sheet sliding over or under, for example a timer sheet, or a focus sheet that dims the page but not Tess.
- The board's "See the layers" tilts the phone to show the stack. That's a board aid only, not app UI.

## Lanes
- Builder B: replace AppsListSlot with AppsDial (Canvas plus a drag gesture, the lens drawing and the fact line), and the Home layout with a Tess slot.
- Builder A: the Tess overlay as a top-level overlay in RootView (above fullScreenCovers via a window-level overlay, so she stays over the doorway and sheets), and the glances from the dial.
- Core: nothing new.

## Reviewer guards (11:15 AM)
- The lens rim stays an unfilled circle. It never becomes a capsule or pill outline.
- No accent shown in the lens is within ΔE 10 of Tess cobalt. The seven app accents in AppAccents.swift already clear this.
- The Tess overlay passes every touch through except on Tess herself and her line.
- Tess is TessSoul exactly as built: the three paint dabs with her eyes, plus one plain ink line. Never an orb or sphere (145 was rejected), and no text field.
- The dial is accessible: an adjustable action for VoiceOver, sizes up to AX5 (names and the fact wrap, never "..."), and a plain step under Reduce Motion.
