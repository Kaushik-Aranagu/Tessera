import SwiftUI

/// Staggered per-glyph reveal: each glyph rises slightly and sharpens from a blur.
/// Animate `progress` from 0 to 1.
struct GlyphRevealRenderer: TextRenderer, Animatable {
    var progress: Double
    /// Fraction of the total timeline each glyph takes to settle.
    var glyphSpan: Double = 0.35

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        let glyphs = layout.flatMap { line in line.flatMap(\.self) }
        let count = max(glyphs.count, 1)
        for (index, glyph) in glyphs.enumerated() {
            let start = Double(index) / Double(count) * (1 - glyphSpan)
            let local = min(max((progress - start) / glyphSpan, 0), 1)
            let eased = 1 - pow(1 - local, 3)
            // Opacity and rise only: a per-glyph blur filter costs an offscreen pass per glyph.
            // The hero's single whole-view blur (see `RevealingHero`) supplies the softness.
            var copy = context
            copy.opacity = eased
            copy.translateBy(x: 0, y: (1 - eased) * 12)
            copy.draw(glyph)
        }
    }
}

/// Draws text, then a strike line that grows across each line with `progress`; text dims as it completes.
struct StrikeRenderer: TextRenderer, Animatable {
    var progress: Double
    var color: Color
    /// Sheet 290, the pen lifts: after the strike ends, a 4 pt flick leaves the end of the line up and to the right,
    /// as a pen leaves the paper. A path, never a state: the caller runs it 0 to 1 and back to 0, and it is 0 at rest.
    var lift: Double = 0

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(progress, lift) }
        set {
            progress = newValue.first
            lift = newValue.second
        }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        var textContext = context
        textContext.opacity = 1 - 0.6 * progress
        for line in layout {
            textContext.draw(line)
        }
        guard progress > 0 else { return }
        let lines = Array(layout)
        for (index, line) in lines.enumerated() {
            // Lines strike one after another.
            let share = 1 / Double(lines.count)
            let local = min(max((progress - Double(index) * share) / share, 0), 1)
            guard local > 0 else { continue }
            let bounds = line.typographicBounds.rect
            let y = bounds.minY + bounds.height * 0.55
            var path = Path()
            path.move(to: CGPoint(x: bounds.minX, y: y))
            path.addLine(to: CGPoint(x: bounds.minX + bounds.width * local, y: y))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            if lift > 0, local >= 1, index == lines.count - 1 {
                // 4 pt long, 45 degrees up and to the right.
                let end = CGPoint(x: bounds.minX + bounds.width, y: y)
                var flick = Path()
                flick.move(to: end)
                flick.addLine(to: CGPoint(x: end.x + 2.8 * lift, y: end.y - 2.8 * lift))
                context.stroke(flick, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
    }
}

/// Text that writes itself in glyph by glyph when it appears. With `once`, it only plays the first time
/// (e.g. the greeting, once per launch).
struct RevealText: View {
    let text: String
    var role: TextRole = .hero
    var color: Color = Theme.Colors.ink
    var delay: Double = 0.1
    var once: Binding<Bool>?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: Double = 0

    var body: some View {
        let done = reduceMotion || once?.wrappedValue == true
        Text(text)
            .textRole(role)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .textRenderer(GlyphRevealRenderer(progress: done ? 1 : progress))
            .task {
                guard !done else { return }
                progress = 0
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(Theme.Motion.reveal.delay(delay)) { progress = 1 } completion: {
                    once?.wrappedValue = true
                }
            }
    }
}

/// The screen's hero: writes itself in glyph by glyph, and plays the concept's completion effect when finished.
struct RevealingHero: View {
    let text: String
    var completion: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.animateEntrance) private var animate
    @State private var reveal: Double = 0

    var body: some View {
        HeroText(text: text) { text in
            text.textRenderer(HeroRenderer(reveal: reduceMotion || !animate ? 1 : reveal, completion: completion,
                                           color: Theme.Colors.live))
        }
        .foregroundStyle(Theme.Colors.ink)
        .blur(radius: reduceMotion || !animate ? 0 : (1 - reveal) * 4)
        .task {
            guard animate, !reduceMotion else { return }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(Theme.Motion.reveal.delay(0.1)) { reveal = 1 }
        }
    }
}

struct HeroRenderer: TextRenderer, Animatable {
    var reveal: Double
    var completion: Double
    var color: Color

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(reveal, completion) }
        set { reveal = newValue.first; completion = newValue.second }
    }

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        if completion > 0 {
            CompletionRenderer(progress: completion, color: color).draw(layout: layout, in: &context)
        } else {
            GlyphRevealRenderer(progress: reveal).draw(layout: layout, in: &context)
        }
    }
}
