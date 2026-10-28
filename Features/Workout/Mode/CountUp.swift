import SwiftUI

/// The Done board's total counting up (sheet 349): from 0 to the final value over 900 ms with an ease-out cubic, in
/// tabular digits, in a slot as wide as the FINAL value so nothing shifts while it counts. Minutes and sets stay still.
/// With Reduce Motion the final number shows at once. This is the pure part.
enum CountUp {
    static let duration = 0.9

    /// Ease-out cubic of the linear time 0 to 1.
    static func eased(_ time: Double) -> Double {
        let clamped = min(max(time, 0), 1)
        return 1 - pow(1 - clamped, 3)
    }

    /// The value `elapsed` seconds in, counting from 0 to `final`.
    static func value(at elapsed: TimeInterval, final: Double) -> Double {
        final * eased(elapsed / duration)
    }

    /// The same, from a 0 to 1 progress (what the animated view carries).
    static func value(progress: Double, final: Double) -> Double {
        final * eased(progress)
    }

    /// The number as shown: whole units with the locale's grouping ("9,795"). The last frame is exactly the final
    /// value.
    static func text(_ value: Double) -> String {
        value.rounded().formatted(.number.precision(.fractionLength(0)).grouping(.automatic))
    }
}

/// A counting number with its unit at half size. It sizes itself to the final value (an invisible copy sets the slot),
/// so the digits never move the row.
struct CountUpNumber: View, @preconcurrency Animatable {
    let final: Double
    let unit: String
    var size: CGFloat = 44
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let shown = CountUp.text(CountUp.value(progress: progress, final: final))
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            ZStack(alignment: .trailing) {
                Text(CountUp.text(final)).hidden()
                Text(shown)
            }
            .font(Chalk.numerals(size))
            .monospacedDigit()
            .foregroundStyle(Chalk.white)
            .lineLimit(1)
            Text(unit).font(Chalk.numerals(size / 2)).foregroundStyle(Chalk.blue)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(CountUp.text(final)) \(unit)")
    }
}

/// Runs the count when it appears: 900 ms, or straight to the final number under Reduce Motion.
struct CountUpRow: View {
    let final: Double
    let unit: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress = 0.0

    var body: some View {
        CountUpNumber(final: final, unit: unit, progress: progress)
            .onAppear {
                guard !reduceMotion else {
                    progress = 1
                    return
                }
                // Linear time in; the cubic is in the value, so the count itself eases out.
                withAnimation(.linear(duration: CountUp.duration)) { progress = 1 }
            }
    }
}
