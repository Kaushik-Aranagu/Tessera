import SwiftUI

// The weather word's effects layer (Home 236 v2.4, v2.5): a view modifier. Behind the word: clouds (placement behind a
// seam), mist haze, a day's shine, a night's stars. In front: strokes, flakes, grains, hail, a glaze line, a bolt, a
// snow cap, mist wisps, wavy lines, frost, heat squiggles, and a 10% veil over the clouds. On the word: sway, shiver,
// waver, the thunder flash and the fog mask. Reduce Motion: none of it, only the colour.

private let effectPad: CGFloat = 26

/// A cheap fixed number in 0 ..< 1 from an index and a salt: the same stroke every frame.
private func unit(_ index: Int, _ salt: Int) -> Double {
    var value = UInt64(truncatingIfNeeded: index &* 73_856_093 ^ salt &* 19_349_663)
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value ^= value >> 31
    return Double(value % 10000) / 10000
}

struct WeatherWordEffects: ViewModifier {
    let kind: WeatherKind
    var overlays: Set<WeatherOverlay> = []
    var night = false
    var placement = WeatherCloudPlacement.standard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var size = CGSize.zero

    private var plan: WeatherPlan {
        WeatherPlan.of(kind, night: night)
    }

    func body(content: Content) -> some View {
        if reduceMotion {
            content.foregroundStyle(kind.colour(night: night))
        } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: scenePhase != .active)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                word(content, time: time)
                    .background { layer(back: true, time: time) }
                    .overlay { layer(back: false, time: time) }
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
        }
    }

    // MARK: The word

    @ViewBuilder
    private func word(_ content: Content, time: TimeInterval) -> some View {
        let flash = plan.bolt ? WeatherMotion.flash(at: time) : 0
        let base = kind.colour(night: night)
        let warn = overlays.first { $0.colour != nil }?.colour
        let tone = (warn ?? base).mix(with: Theme.Colors.Weather.bolt, by: Float(flash))
        let swayed = overlays.compactMap { $0.sway > 0 ? WeatherMotion.sway($0, at: time) : nil }.reduce(0, +)
        let shiver = overlays.contains(.windWarning) ? sin(time * 38) * 0.6 : 0
        let waver = overlays.contains(.heatWarning) ? sin(time * 5 + 1) * 0.9 : 0
        content
            .foregroundStyle(tone)
            .brightness(flash * 0.35)
            .rotationEffect(.degrees(swayed * 0.9), anchor: .bottom)
            .offset(x: swayed + shiver, y: waver)
            .transformEffect(CGAffineTransform(
                a: 1,
                b: 0,
                c: overlays.contains(.heatWarning) ? sin(time * 3) * 0.05 : 0,
                d: 1,
                tx: 0,
                ty: 0
            ))
            .mask { fogMask(time: time) }
    }

    @ViewBuilder
    private func fogMask(time: TimeInterval) -> some View {
        if plan.mist {
            Canvas { context, canvas in
                let rows = 14
                for row in 0 ..< rows {
                    let top = canvas.height * Double(row) / Double(rows)
                    let opacity = WeatherMotion.fogOpacity(row: Double(row) / Double(rows), time: time)
                    context.fill(
                        Path(CGRect(x: 0, y: top, width: canvas.width, height: canvas.height / Double(rows) + 0.5)),
                        with: .color(.black.opacity(opacity))
                    )
                }
            }
        } else {
            Rectangle()
        }
    }

    // MARK: Layers

    private func layer(back: Bool, time: TimeInterval) -> some View {
        Canvas { context, canvas in
            let rect = CGRect(x: effectPad, y: effectPad, width: size.width, height: size.height)
            if back {
                drawBack(&context, rect: rect, time: time)
            } else {
                drawFront(&context, rect: rect, time: time)
            }
            _ = canvas
        }
        .frame(width: size.width + effectPad * 2, height: size.height + effectPad * 2)
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawBack(_ context: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        let plan = plan
        if plan.mist {
            let haze = Theme.Colors.Weather.fog
            context.fill(Path(ellipseIn: rect.insetBy(dx: -16, dy: -8)),
                         with: .radialGradient(Gradient(colors: [haze.opacity(0.28), haze.opacity(0)]),
                                               center: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0,
                                               endRadius: rect.width * 0.6))
        }
        if plan.shine {
            let glow = Theme.Colors.Weather.pcloud
            let breathe = 0.16 + 0.04 * sin(time * 0.6)
            context.fill(Path(ellipseIn: rect.insetBy(dx: -14, dy: -10)),
                         with: .radialGradient(Gradient(colors: [glow.opacity(breathe), glow.opacity(0)]),
                                               center: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0,
                                               endRadius: rect.width * 0.55))
        }
        if plan.stars {
            for index in 0 ..< 9 {
                let twinkle = 0.5 + 0.5 * sin(time * (1.1 + unit(index, 3)) + unit(index, 4) * 6)
                let point = CGPoint(x: rect.minX - 8 + unit(index, 1) * (rect.width + 16),
                                    y: rect.minY - 8 + unit(index, 2) * (rect.height + 16))
                let arm = 1.5 + twinkle * 1.5
                var star = Path()
                star.move(to: CGPoint(x: point.x - arm, y: point.y))
                star.addLine(to: CGPoint(x: point.x + arm, y: point.y))
                star.move(to: CGPoint(x: point.x, y: point.y - arm))
                star.addLine(to: CGPoint(x: point.x, y: point.y + arm))
                context.stroke(star, with: .color(Theme.Colors.Weather.moon.opacity(0.35 + 0.5 * twinkle)),
                               lineWidth: 1)
            }
        }
        for cloud in plan.clouds {
            WeatherCloudDrawing.draw(&context, cloud: cloud, in: rect, placement: placement, time: time)
        }
    }

    private func drawFront(_ context: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        let plan = plan
        if !plan.clouds.isEmpty, placement.veil > 0 {
            context.fill(Path(rect.insetBy(dx: -effectPad, dy: -effectPad)),
                         with: .color(Theme.Colors.paper.opacity(placement.veil)))
        }
        let streak = plan.icy ? Theme.Colors.Weather.ice : Theme.Colors.Weather.rain
        if plan.strokes > 0 {
            WeatherFallDrawing.strokes(&context, plan: plan, rect: rect, time: time, colour: streak)
        }
        if plan.flakes > 0 || plan.grains > 0 {
            WeatherFallDrawing.flakes(&context, plan: plan, rect: rect, time: time)
        }
        if plan.hail {
            WeatherFallDrawing.hail(&context, rect: rect, time: time)
        }
        if plan.snowCap {
            WeatherFallDrawing.snowCap(&context, rect: rect)
        }
        if plan.glaze {
            WeatherFallDrawing.glaze(&context, rect: rect, time: time)
        }
        if plan.bolt, let phase = WeatherMotion.boltPhase(at: time) {
            WeatherFallDrawing.bolt(&context, rect: rect, phase: phase, time: time)
        }
        if plan.mist {
            WeatherFallDrawing.mist(&context, rect: rect, time: time)
        }
        if overlays.contains(.heatWarning) {
            WeatherFallDrawing.heat(&context, rect: rect, time: time)
        }
        if overlays.contains(.coldWarning) {
            WeatherFallDrawing.frost(&context, rect: rect, time: time)
        }
    }
}

extension View {
    /// A weather word's effects. Put it on the word's text; the word takes its cloud's colour.
    func weatherWord(_ kind: WeatherKind, overlays: Set<WeatherOverlay> = [], night: Bool = false) -> some View {
        modifier(WeatherWordEffects(kind: kind, overlays: overlays, night: night))
    }
}

// MARK: - Clouds (behind the seam: WeatherCloudPlacement decides where)

enum WeatherCloudDrawing {
    /// The puffs of a flat-bottomed cumulus: (across the width, radius as a share of the width), left to right.
    static let puffs: [(dx: Double, radius: Double)] = [(-0.31, 0.17), (-0.13, 0.26), (0.10, 0.29), (0.30, 0.19)]

    static func colours(_ tone: WeatherCloudTone) -> (top: Color, bottom: Color) {
        switch tone {
        case .white: (.white, Theme.Colors.Weather.pcloud.mix(with: .white, by: 0.35))
        case .grey: (Theme.Colors.Weather.fog.mix(with: .white, by: 0.45), Theme.Colors.Weather.fog)
        case .rain: (Theme.Colors.Weather.rain.mix(with: .white, by: 0.4), Theme.Colors.Weather.rain)
        case .storm: (
                Theme.Colors.Weather.storm.mix(with: .white, by: 0.25),
                Theme.Colors.Weather.storm.mix(with: .black, by: 0.2)
            )
        }
    }

    /// One cloud: puffs filled once with a top-lit gradient, soft lit bumps, a soft rim, all laid on at one alpha;
    /// it breathes and drifts slowly.
    static func draw(_ context: inout GraphicsContext, cloud: WeatherCloud, in word: CGRect,
                     placement: WeatherCloudPlacement, time: TimeInterval)
    {
        // 1.1x the line's height, level with the word; the width follows the cumulus's own proportions.
        let target = word.height * placement.height
        let width = max(target * 4 * cloud.size, 36)
        let breathe = 1 + 0.03 * sin(time * 0.7 + cloud.across * 5)
        let scale = width * breathe
        let drift = sin(time * 0.22 * cloud.drift + cloud.across * 6) * word.width * 0.05
        let centreX = word.minX + word.width * cloud.across + drift
        let baseY = word.minY + word.height * placement.centre + scale * 0.245
        var path = Path()
        for puff in puffs {
            let radius = puff.radius * scale
            path.addEllipse(in: CGRect(x: centreX + puff.dx * scale - radius, y: baseY - radius * 1.7,
                                       width: radius * 2, height: radius * 1.7))
        }
        // The flat bottom.
        let left = centreX + puffs[0].dx * scale - puffs[0].radius * scale
        let right = centreX + puffs[3].dx * scale + puffs[3].radius * scale
        path.addRoundedRect(in: CGRect(x: left, y: baseY - scale * 0.1, width: right - left, height: scale * 0.1),
                            cornerSize: CGSize(width: 2, height: 2))
        let tones = colours(cloud.tone)
        let top = baseY - puffs.map(\.radius).max()! * scale * 1.7
        context.drawLayer { layer in
            layer.opacity = WeatherCloudPlacement.alpha(cloud)
            layer.fill(path, with: .linearGradient(Gradient(colors: [tones.top, tones.bottom]),
                                                   startPoint: CGPoint(x: centreX, y: top),
                                                   endPoint: CGPoint(x: centreX, y: baseY)))
            for puff in puffs {
                let radius = puff.radius * scale * 0.45
                layer.fill(Path(ellipseIn: CGRect(x: centreX + puff.dx * scale - radius * 1.1,
                                                  y: baseY - puff.radius * scale * 1.55, width: radius * 2,
                                                  height: radius * 1.2)),
                           with: .color(tones.top.opacity(0.45)))
            }
            layer.stroke(path, with: .color(tones.top.opacity(0.35)), lineWidth: 1)
        }
    }
}

// MARK: - What falls, glints and drifts in front

enum WeatherFallDrawing {
    /// Rain, snow and hail start at mid-word and fall to just under the line.
    static func fallY(_ rect: CGRect, _ phase: Double) -> Double {
        rect.minY + rect.height * (WeatherCloudPlacement.fallStart
            + phase * (WeatherCloudPlacement.fallEnd - WeatherCloudPlacement.fallStart))
    }

    static func strokes(_ context: inout GraphicsContext, plan: WeatherPlan, rect: CGRect, time: TimeInterval,
                        colour: Color)
    {
        let heavy = plan.strokes > 30
        for index in 0 ..< plan.strokes {
            let phase = WeatherMotion.fall(index: index, time: time, speed: 0.9 + plan.strokeLength * 0.08)
            let x = rect.minX - 4 + unit(index, 7) * (rect.width + 8) + plan.slant * phase
            let top = fallY(rect, phase)
            var stroke = Path()
            stroke.move(to: CGPoint(x: x, y: top))
            stroke.addLine(to: CGPoint(x: x + plan.slant * 0.35, y: top + plan.strokeLength))
            let fade = phase < 0.1 ? phase * 10 : 1
            context.stroke(stroke, with: .color(colour.opacity((heavy ? 0.7 : 0.5) * fade)),
                           style: StrokeStyle(
                               lineWidth: heavy ? 1.5 : (plan.strokes > 20 ? 1.1 : 0.8),
                               lineCap: .round
                           ))
            if plan.splashes, phase > 0.9 {
                let splash = (phase - 0.9) * 10
                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: x, y: rect.maxY + 1),
                    radius: 1.5 + splash * 2.5,
                    startAngle: .degrees(200),
                    endAngle: .degrees(340),
                    clockwise: false
                )
                context.stroke(arc, with: .color(colour.opacity(0.6 * (1 - splash))), lineWidth: 0.9)
            }
        }
    }

    static func flakes(_ context: inout GraphicsContext, plan: WeatherPlan, rect: CGRect, time: TimeInterval) {
        let ice = Theme.Colors.Weather.ice
        for index in 0 ..< plan.flakes {
            let phase = WeatherMotion.fall(index: index, time: time, speed: 0.22)
            let x = rect.minX + unit(index, 11) * rect.width + sin(time * 1.3 + Double(index)) * 4
            let y = fallY(rect, phase)
            let side = 1.6 + unit(index, 12) * 1.8
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: side, height: side)),
                         with: .color(ice.opacity(0.55 + 0.35 * unit(index, 13))))
        }
        // Grains: tiny fast ticks.
        for index in 0 ..< plan.grains {
            let phase = WeatherMotion.fall(index: index, time: time, speed: 1.4)
            let x = rect.minX - 2 + unit(index, 21) * (rect.width + 4)
            let y = fallY(rect, phase)
            context.fill(Path(CGRect(x: x, y: y, width: 1, height: 2.4)), with: .color(ice.opacity(0.75)))
        }
    }

    /// Ice pellets that bounce off the foot of the word.
    static func hail(_ context: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        for index in 0 ..< 12 {
            let phase = WeatherMotion.fall(index: index, time: time, speed: 0.7)
            let bounce = abs(sin(phase * .pi * 2.5)) * (1 - phase * 0.7)
            let x = rect.minX + unit(index, 31) * rect.width
            let y = rect.maxY - bounce * rect.height * 0.5
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3.2, height: 3.2)),
                         with: .color(Theme.Colors.Weather.ice.opacity(0.9)))
        }
    }

    /// Snow lying on the tops of the letters: bumps of white along the word's top edge.
    static func snowCap(_ context: inout GraphicsContext, rect: CGRect) {
        var cap = Path()
        let top = rect.minY + rect.height * 0.2
        var x = rect.minX
        cap.move(to: CGPoint(x: x, y: top + 3))
        var index = 0
        while x < rect.maxX {
            let step = 6 + unit(index, 41) * 6
            let lift = 1.5 + unit(index, 42) * 3
            cap.addQuadCurve(to: CGPoint(x: min(x + step, rect.maxX), y: top + 3),
                             control: CGPoint(x: x + step / 2, y: top - lift))
            x += step
            index += 1
        }
        cap.addLine(to: CGPoint(x: rect.minX, y: top + 3))
        context.fill(cap, with: .color(.white.opacity(0.92)))
        context.stroke(cap, with: .color(Theme.Colors.Weather.ice.opacity(0.4)), lineWidth: 0.8)
    }

    /// A line of glaze under the word with a glint that travels along it.
    static func glaze(_ context: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        let y = rect.maxY - 3
        let ice = Theme.Colors.Weather.ice
        var line = Path()
        line.move(to: CGPoint(x: rect.minX, y: y))
        line.addLine(to: CGPoint(x: rect.maxX, y: y))
        context.stroke(line, with: .color(ice.opacity(0.55)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        let glint = rect.minX + (time * 0.45).truncatingRemainder(dividingBy: 1) * rect.width
        context.fill(Path(roundedRect: CGRect(x: glint - 7, y: y - 1.2, width: 14, height: 2.4), cornerRadius: 1.2),
                     with: .linearGradient(
                         Gradient(colors: [.white.opacity(0), .white.opacity(0.95), .white.opacity(0)]),
                         startPoint: CGPoint(x: glint - 7, y: y),
                         endPoint: CGPoint(x: glint + 7, y: y)
                     ))
    }

    /// A bolt from the cloud to the foot of the word, in the bolt colour, fading over its quarter second.
    static func bolt(_ context: inout GraphicsContext, rect: CGRect, phase: Double, time: TimeInterval) {
        let seed = Int(time / WeatherPlan.boltPeriod)
        var x = rect.minX + (0.25 + unit(seed, 51) * 0.5) * rect.width
        var y = rect.minY - 2
        var path = Path()
        path.move(to: CGPoint(x: x, y: y))
        let steps = 5
        for step in 1 ... steps {
            x += (unit(seed &* 7 + step, 52) - 0.5) * 12
            y = rect.minY - 2 + (rect.height + 4) * Double(step) / Double(steps)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        let bolt = Theme.Colors.Weather.bolt
        context.stroke(path, with: .color(bolt.opacity(0.35 * (1 - phase))), lineWidth: 5)
        context.stroke(
            path,
            with: .color(bolt.opacity(1 - phase * 0.8)),
            style: StrokeStyle(lineWidth: 1.8, lineJoin: .miter)
        )
    }

    /// Long soft wisps in the page colour drifting in front of the word (up to 0.8 alpha), and a few wavy lines.
    static func mist(_ context: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        let paper = Theme.Colors.paper
        for index in 0 ..< 4 {
            let drift = (time * (0.05 + 0.02 * Double(index)) + unit(index, 61)).truncatingRemainder(dividingBy: 1)
            let width = rect.width * (0.45 + 0.2 * unit(index, 62))
            let x = rect.minX - width + drift * (rect.width + width * 2)
            let y = rect.minY + rect.height * (0.15 + 0.25 * Double(index))
            let alpha = 0.8 * (0.5 + 0.5 * sin(time * 0.5 + Double(index) * 1.7))
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 4))
                layer.fill(Path(roundedRect: CGRect(x: x, y: y, width: width, height: 7), cornerRadius: 3.5),
                           with: .color(paper.opacity(alpha)))
            }
        }
        for index in 0 ..< 3 {
            var wave = Path()
            let y = rect.minY + rect.height * (0.3 + 0.28 * Double(index))
            wave.move(to: CGPoint(x: rect.minX - 6, y: y))
            var x = rect.minX - 6
            while x < rect.maxX + 6 {
                x += 3
                wave.addLine(to: CGPoint(x: x, y: y + sin(x * 0.25 + time * 0.9 + Double(index)) * 1.6))
            }
            context.stroke(wave, with: .color(Theme.Colors.Weather.fog.opacity(0.28)), lineWidth: 0.9)
        }
    }

    /// Squiggles of heat rising off the word.
    static func heat(_ context: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        let warn = Theme.Colors.Weather.warn
        for index in 0 ..< 5 {
            let phase = WeatherMotion.fall(index: index, time: time, speed: 0.3)
            let rise = 1 - phase
            var squiggle = Path()
            let x = rect.minX + (0.1 + 0.2 * Double(index)) * rect.width
            let top = rect.minY + rect.height * rise - 4
            squiggle.move(to: CGPoint(x: x, y: top))
            for step in 1 ... 4 {
                squiggle.addLine(to: CGPoint(x: x + (step.isMultiple(of: 2) ? -1.8 : 1.8), y: top - Double(step) * 2.4))
            }
            context.stroke(squiggle, with: .color(warn.opacity(0.55 * min(rise * 2, 1))), lineWidth: 1)
        }
    }

    /// Frost crystals in ice at the word's corners, each a small six-armed star that glints.
    static func frost(_ context: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        let ice = Theme.Colors.Weather.ice
        for index in 0 ..< 6 {
            let glint = 0.5 + 0.5 * sin(time * 1.2 + Double(index) * 1.3)
            let centre = CGPoint(
                x: rect.minX + unit(index, 71) * rect.width,
                y: rect.minY - 4 + unit(index, 72) * (rect.height + 8)
            )
            let arm = 2.2 + 1.2 * glint
            var crystal = Path()
            for spoke in 0 ..< 3 {
                let angle = Double(spoke) * .pi / 3
                crystal.move(to: CGPoint(x: centre.x - cos(angle) * arm, y: centre.y - sin(angle) * arm))
                crystal.addLine(to: CGPoint(x: centre.x + cos(angle) * arm, y: centre.y + sin(angle) * arm))
            }
            context.stroke(crystal, with: .color(ice.opacity(0.5 + 0.4 * glint)), lineWidth: 0.9)
        }
    }
}
