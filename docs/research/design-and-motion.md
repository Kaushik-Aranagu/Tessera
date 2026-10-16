# Design and motion: scouted techniques for Tessera v1

For: Design studio
Date: 2026-10-15

Ranked by (daily delight x fit with the bar) / effort. Each needs a Reduce Motion version that keeps the haptic.

1. **The dial is one instrument.** The weight dial ticks every 2.5 kg, and each tick's sharpness grows with spin speed: a slow turn feels like a watch crown, a flick like a freewheel. On release it projects where momentum would stop, settles on the nearest valid plate load, and stiffens at its limits. After the set, the same dial becomes the rest countdown, its ticks walking back as time passes. Technique: DragGesture velocity, a tight Spring, Core Haptics transients (intensity and sharpness from speed) plus a quiet tick sound fired on the same frame. Effort M. Sources: [Emil Kowalski, motion principles](https://www.ui-skills.com/skills/emilkowalski/apple-design/), [Core Haptics, WWDC19](https://developer.apple.com/videos/play/wwdc2019/520).

2. **Hold to seat.** To log a set, you press it and a light runs along its hairline seam while a continuous haptic builds. When the light closes the loop, the row drops one notch into its slot with a firm "clunk", the numbers roll, and the next set rises to eye level. Letting go early simply runs everything backwards. It borrows the (Not Boring) idea of layering six or seven kinds of feedback on one input, done in a machined voice. Technique: long-press progress, a CHHapticContinuous intensity ramp then a transient, matchedGeometryEffect into the slot, numericText. Effort M. Source: [Behind the Design: (Not Boring) Habits](https://developer.apple.com/news/?id=9ab1g4r3).

3. **One light source, real chamfers.** A single shader draws a thin highlight on every seam and edge from one shared light direction, which tilts a few degrees with the phone. This makes flat rectangles read as machined parts, with no cards or shadows. The breathing glint on the current tile is the same light drifting across that tile every few seconds. Technique: a `.colorEffect` / `.layerEffect` Metal shader with the light angle as a uniform from CoreMotion (clamped, damped), and TimelineView for the glint. Effort M. Sources: [Inferno shaders](https://github.com/twostraws/Inferno).

4. **Lit-seam position indicator.** Replace page dots with the hairline seam at the bottom (for x) or the side (for y) of each surface. Each sibling owns a segment of the seam sized to its share, and the segment you are on glows, sliding with your scroll. The running workout uses the same lit seam along the top edge. Technique: `scrollPosition` plus `onScrollGeometryChange` driving a Canvas line. Effort S.

5. **Numbers that roll like hardware.** Counters, countdowns and the Stamp use an odometer roll: each digit turns on its own drum, with a hint of motion blur and a soft settle. Technique: a `TextRenderer` that offsets and blurs each glyph run, or `.contentTransition(.numericText)` with a `KeyframeAnimator` settle. Effort S. Source: [fatbobman, TextRenderer effects](https://fatbobman.com/en/posts/creating-stunning-dynamic-text-effects-with-textrender/).

6. **Tess's bloom as a living shader.** About 40 dabs of vermilion, cobalt and cadmium drift on warped noise. Each state is a set of parameters rather than a new animation: idle is a slow drift, thinking a gathering swirl, acting sends the bloom across the screen to the object she touched, and "home" makes it contract. Because states blend into each other, she never visibly jumps between them. Technique: a Metal layer shader that samples noise twice (domain warping, as in WWDC26 322) inside a TimelineView, with matchedGeometry for the travel. Effort L. Source: [WWDC26: Compose advanced graphics effects](https://developer.apple.com/videos/play/wwdc2026/322).

7. **Ink strike.** Finishing a task draws a single hand-pulled stroke through the title, with a slightly uneven painted edge that matches the bloom, followed by a soft success haptic. It is the only painterly mark outside Tess. Technique: a `TextRenderer` that draws a stroke path across the line bounds, animated with a progress value. Effort S. Source: [Lickability, animated strikethroughs](https://lickability.com/blog/animating-strikethroughs-in-swiftui).

8. **Session compresses into one object.** When you finish, the workout's sets press together one by one, each with a fading tick haptic, into a single slab that slides into today's history on the day strip. Technique: staggered springs on a scaleEffect along y, matchedGeometry into the strip, and a Core Haptics pattern built from the set count. Effort M.

9. **Day strip as a ruler.** The day strip is engraved with hour ticks, and "now" is a cut mark that creeps along it. Scrubbing it gives a detent at each hour and slides the Now item to match. Technique: Canvas ticks, `.sensoryFeedback(.selection)` per hour, scrollTargetBehavior paging. Effort S.

10. **The PR is the one loud moment.** A beam of light sweeps across every seam on the screen in sequence, Tess's bloom bursts once, and the only `.bouncy` spring in the app settles the new number. Technique: the shader from idea 3 with an animated sweep uniform, a PhaseAnimator for the sequence, and a Core Haptics crescendo. Effort M (S once idea 3 exists).

11. **Zoom you can hold.** Opening an object zooms out of its row while the page behind steps back one tone. Pinching back follows your fingers one to one and can be reversed mid-flight. Technique: `matchedTransitionSource` plus `.navigationTransition(.zoom)`, with interactive dismissal and the tonal step tied to progress. Effort M.

## Top 3 to act on now

1. **The dial (1) and hold to seat (2).** Kaushik touches them every set of every session, so they decide whether M1 "feels like an instrument". Prototype the haptic patterns first, on a device.
2. **The one-light chamfer shader (3).** It is the base material for every theme (Mosaic glaze, Plein air, Kernel bone), and the glint, the lit seams and the PR sweep all reuse it.
3. **Odometer numbers and lit-seam indicators (5, 4).** Both are cheap, they show up on every screen, and they settle two open questions in the spec: the Stamp's number roll, and position without dots.

Context: the [2026 Apple Design Awards](https://www.apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/) went to Tide Guide and Moonlitt, each built around one signature element. That supports keeping living moments rare.
