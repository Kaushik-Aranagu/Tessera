import SwiftUI

// Sheet 213: how the one thing on Home arrives. Every curve is a pure function of the seconds since the page showed,
// so the timings are testable; the views only read them. Reduce Motion: everything is simply there.

enum ThingEntrance {
    /// The three tiers rise 10 pt with a clip reveal, 0/80/160 ms apart, over 0.5 s.
    static let tierRise: CGFloat = 10
    static let tierStagger: TimeInterval = 0.08
    static let tierSeconds: TimeInterval = 0.5
    /// Grocery items drop in 110 ms apart with a small overshoot.
    static let dropStagger: TimeInterval = 0.11
    static let dropSeconds: TimeInterval = 0.32
    /// A task title writes in left to right, stepped, over 0.9 s.
    static let writeSeconds: TimeInterval = 0.9
    static let writeSteps = 24
    /// A list count ticks up from 0.
    static let tickSeconds: TimeInterval = 0.8
    /// The pixel sign rises 12 pt.
    static let signRise: CGFloat = 12
    static let signSeconds: TimeInterval = 0.5
    /// A board digit turns over in 300 ms, each one 70 ms after the last.
    static let flipSeconds: TimeInterval = 0.3
    static let flipStagger: TimeInterval = 0.07

    static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    /// Ease-out cubic.
    static func easeOut(_ value: Double) -> Double {
        1 - pow(1 - clamp(value), 3)
    }

    /// 0...1 for a tier: 0 before its turn, 1 when it has settled.
    static func tier(_ index: Int, elapsed: TimeInterval) -> Double {
        easeOut((elapsed - Double(index) * tierStagger) / tierSeconds)
    }

    static func tierOffset(_ index: Int, elapsed: TimeInterval) -> CGFloat {
        tierRise * (1 - tier(index, elapsed: elapsed))
    }

    /// The vertical scale of a digit on the board: |cos| over the turn, never thinner than 0.08, 1 when settled.
    static func flipScale(_ index: Int, elapsed: TimeInterval) -> Double {
        let unit = (elapsed - Double(index) * flipStagger) / flipSeconds
        if unit <= 0 {
            return 0.08
        }
        if unit >= 1 {
            return 1
        }
        return max(abs(cos(Double.pi * unit)), 0.08)
    }

    /// A grocery item's offset above its place: falls from `height` and overshoots by ~12% once.
    static func dropOffset(_ index: Int, elapsed: TimeInterval, height: CGFloat = 14) -> CGFloat {
        let unit = clamp((elapsed - Double(index) * dropStagger) / dropSeconds)
        if unit <= 0 {
            return -height
        }
        let overshoot = 1.70158, back = overshoot + 1
        let eased = 1 + back * pow(unit - 1, 3) + overshoot * pow(unit - 1, 2)
        return -height * CGFloat(1 - eased)
    }

    /// Whether an item has started to appear.
    static func dropVisible(_ index: Int, elapsed: TimeInterval) -> Bool {
        elapsed >= Double(index) * dropStagger
    }

    /// The share of the title's width that is written, in steps (a pen, not a wipe).
    static func written(elapsed: TimeInterval) -> Double {
        let unit = clamp(elapsed / writeSeconds)
        return (unit * Double(writeSteps)).rounded(.down) / Double(writeSteps)
    }

    /// The count shown while it ticks up to `target`.
    static func count(to target: Int, elapsed: TimeInterval) -> Int {
        Int((Double(target) * easeOut(elapsed / tickSeconds)).rounded())
    }

    static func signOffset(elapsed: TimeInterval) -> CGFloat {
        signRise * (1 - CGFloat(easeOut(elapsed / signSeconds)))
    }
}

/// Seconds since this view appeared; nil under Reduce Motion (the settled state).
private struct ThingClock<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let settleAfter: TimeInterval
    @ViewBuilder let content: (TimeInterval?) -> Content
    @State private var start = Date()

    var body: some View {
        if reduceMotion {
            content(nil)
        } else {
            TimelineView(.animation(paused: Date().timeIntervalSince(start) > settleAfter)) { context in
                content(context.date.timeIntervalSince(start))
            }
        }
    }
}

extension View {
    /// A tier of the thing rising 10 pt with a clip reveal, staggered by its index (0, 1, 2).
    func thingTier(_ index: Int) -> some View {
        modifier(ThingTier(index: index))
    }

    /// The pixel sign rising 12 pt as the page shows.
    func thingSignRise() -> some View {
        ThingClock(settleAfter: ThingEntrance.signSeconds + 0.1) { elapsed in
            self.offset(y: elapsed.map { ThingEntrance.signOffset(elapsed: $0) } ?? 0)
                .opacity(elapsed.map { ThingEntrance.easeOut($0 / 0.2) } ?? 1)
        }
    }
}

private struct ThingTier: ViewModifier {
    let index: Int

    func body(content: Content) -> some View {
        ThingClock(settleAfter: ThingEntrance.tierSeconds + 0.3) { elapsed in
            let value = elapsed.map { ThingEntrance.tier(index, elapsed: $0) } ?? 1
            content
                .offset(y: elapsed.map { ThingEntrance.tierOffset(index, elapsed: $0) } ?? 0)
                .mask(alignment: .bottom) {
                    Rectangle().scaleEffect(y: max(value, 0.001), anchor: .bottom)
                }
                .opacity(value > 0 ? 1 : 0)
        }
    }
}

/// A title that writes itself in left to right, a stepped clip over 0.9 s.
struct ThingWrittenTitle: View {
    let text: String
    var font: Font = .title

    var body: some View {
        ThingClock(settleAfter: ThingEntrance.writeSeconds + 0.1) { elapsed in
            let share = elapsed.map { ThingEntrance.written(elapsed: $0) } ?? 1
            Text(text)
                .font(font)
                .mask(alignment: .leading) {
                    GeometryReader { proxy in
                        Rectangle().frame(width: proxy.size.width * share)
                    }
                }
        }
    }
}

/// A count that ticks up from 0 to its value.
struct ThingCount: View {
    let value: Int
    var font: Font = .largeTitle

    var body: some View {
        ThingClock(settleAfter: ThingEntrance.tickSeconds + 0.1) { elapsed in
            Text("\(elapsed.map { ThingEntrance.count(to: value, elapsed: $0) } ?? value)")
                .font(font)
                .monospacedDigit()
                .contentTransition(.identity)
        }
    }
}

/// Digits that flip like the board, one after another.
struct ThingFlipDigits: View {
    let text: String
    var font: Font = .largeTitle

    var body: some View {
        let settle = Double(text.count) * ThingEntrance.flipStagger + ThingEntrance.flipSeconds + 0.1
        ThingClock(settleAfter: settle) { elapsed in
            HStack(spacing: 0) {
                ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(font)
                        .monospacedDigit()
                        .scaleEffect(y: elapsed.map { ThingEntrance.flipScale(index, elapsed: $0) } ?? 1)
                }
            }
        }
    }
}
