import SwiftUI

/// A light sheen that sweeps across its content every ~5 s, plus a slow breath. Use sparingly: a new personal
/// record, the item you're on now, a fresh note from Tess. Reduce Motion: no sheen.
struct Glint: ViewModifier {
    var period: Double = 5
    /// The look's sheen (gold through the letters on white looks, light over dark ones); nil reads it per frame.
    var sheen: Color?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let sweep = TessSoul.phase(time, period: period)
                // The sheen crosses during the first quarter of the period, then rests.
                let x = min(sweep / 0.24, 1) * 2 - 0.5
                content
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: (sheen ?? Theme.Colors.sheen).opacity(0.9), location: 0.5),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: UnitPoint(x: x - 0.25, y: 0.2),
                            endPoint: UnitPoint(x: x + 0.25, y: 0.8)
                        )
                        .mask(content)
                        .blendMode(sheen == nil ? Theme.Colors.sheenBlend : .plusLighter)
                        .allowsHitTesting(false)
                    }
                    .opacity(0.94 + 0.06 * sin(time * 2 * .pi / 6))
            }
        }
    }
}

extension View {
    func glint() -> some View {
        modifier(Glint())
    }
}

/// Five bars, one lit, sweeping: background work you didn't start (sync, Health import, a batch for Tess).
struct RoundRobin: View {
    var tint: Color = Theme.Colors.live
    var ink: Color = Theme.Colors.ink
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0 ..< 5, id: \.self) { index in
                    let local = TessSoul.phase(time, period: 1.25, delay: Double(index) * 0.16)
                    let lit = local < 0.18
                    RoundedRectangle(cornerRadius : 2)
                        .fill(local < 0.05 ? tint : lit ? ink : ink.opacity(0.14))
                        .frame(width: 9, height: 36)
                        .scaleEffect(
                            y: reduceMotion ? 1 : (lit ? 1.3 - local: 0.75 + 0.25 * (1 - local)),
                            anchor: .bottom
                        )
                }
            }
        }
        .frame(height: 48)
        .accessibilityLabel("Working in the background")
    }
}

/// Digits roll in place, nothing else moves: rest timers, the workout clock, a countdown.
struct Tick: View {
    let seconds: TimeInterval
    var role: TextRole = .titleNumber
    var countsDown = true

    var body: some View {
        Text(Format.duration(seconds))
            .textRole(role)
            .contentTransition(.numericText(countsDown: countsDown))
            .animation(Theme.Motion.snappy, value: Int(seconds))
    }
}
