import SwiftUI

/// Round 9 ("Plein") paint. Kept here so a restyle is a one-line change.
private enum Paint {
    static var cream: Color {
        Theme.Colors.Workout.ink
    }

    static var cadmium: Color {
        Theme.Colors.Workout.rest
    }

    static var rail: Color {
        cream.opacity(0.22)
    }

    static var dab: Color {
        cream.opacity(0.45)
    }

    static var whole: Color {
        cream.opacity(0.45)
    }
}

/// Effort, only when wanted: a stop-slider of nine stops from 6 to 10 in half steps along a hairline. Whole numbers
/// carry a light numeral; half steps are small dabs. The chosen stop's dab grows into a cadmium dab with a soft glow
/// and its number turns cream. Each stop the finger crosses is one selection tick. Tapping the chosen stop clears it.
/// It slides out left to right when revealed (the caller pulls it out from under the reps).
struct RPEStops: View {
    @Binding var rpe: Double?

    @State private var dragHaptic = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let stops: [Double] = Array(stride(from: 6.0, through: 10.0, by: 0.5))

    private enum Metrics {
        static let height: CGFloat = 60
        static let dab: CGFloat = 5
        static let chosen: CGFloat = 18
        static let inset: CGFloat = 14
        static let rail: CGFloat = 22
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .topLeading) {
                Paint.rail
                    .frame(width: max(width - 2 * Metrics.inset, 0), height: 0.75)
                    .offset(x: Metrics.inset, y: Metrics.rail)
                ForEach(Self.stops.indices, id: \.self) { index in
                    stop(index)
                        .position(x: x(for: index, in: width), y: Metrics.rail)
                    if Self.stops[index] == Self.stops[index].rounded() || Self.stops[index] == rpe {
                        label(index)
                            .position(x: x(for: index, in: width), y: Metrics.rail + 24)
                    }
                }
            }
            .frame(width: width, height: Metrics.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let index = index(at: drag.location.x, in: width)
                        if startedOnChosen == nil {
                            startedOnChosen = Self.stops[index] == rpe
                        }
                        select(index, haptic: true)
                    }
                    .onEnded { drag in
                        // A plain tap on the stop that was already chosen clears it.
                        if startedOnChosen == true, abs(drag.translation.width) < 6 {
                            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { rpe = nil }
                            dragHaptic += 1
                        }
                        startedOnChosen = nil
                    }
            )
        }
        .frame(height: Metrics.height)
        .tesseraFeedback(.selection, trigger: dragHaptic)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort, RPE")
        .accessibilityValue(rpe.map { "\(Self.formatted($0)), \(Self.words(for: $0))" } ?? "Not set")
        .accessibilityAdjustableAction { direction in
            let current = rpe.flatMap { Self.stops.firstIndex(of: $0) }
            switch direction {
            case .increment: select(min((current ?? -1) + 1, Self.stops.count - 1), haptic: false)
            case .decrement: select(max((current ?? 1) - 1, 0), haptic: false)
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Clear effort") { rpe = nil }
    }

    /// Whether the touch began on the stop already chosen (a tap there clears it).
    @State private var startedOnChosen: Bool?

    private func stop(_ index: Int) -> some View {
        let isChosen = Self.stops[index] == rpe
        return Circle()
            .fill(isChosen ? Paint.cadmium : Paint.dab)
            .frame(width: isChosen ? Metrics.chosen : Metrics.dab, height: isChosen ? Metrics.chosen : Metrics.dab)
            .shadow(color: Paint.cadmium.opacity(isChosen ? 0.6 : 0), radius: 8)
            .tesseraAnimation(Theme.Motion.snappy, value: isChosen)
    }

    private func label(_ index: Int) -> some View {
        let value = Self.stops[index]
        let isChosen = value == rpe
        return Text(Self.formatted(value))
            .numeral(isChosen ? 26 : 21, weight: isChosen ? .medium : .light)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .foregroundStyle(isChosen ? Paint.cream : Paint.whole)
            .fixedSize()
            .contentTransition(.opacity)
    }

    private func x(for index: Int, in width: CGFloat) -> CGFloat {
        Metrics.inset + (width - 2 * Metrics.inset) * CGFloat(index) / CGFloat(Self.stops.count - 1)
    }

    private func index(at x: CGFloat, in width: CGFloat) -> Int {
        let fraction = (x - Metrics.inset) / max(width - 2 * Metrics.inset, 1)
        let raw = (fraction * CGFloat(Self.stops.count - 1)).rounded()
        return min(max(Int(raw), 0), Self.stops.count - 1)
    }

    private func select(_ index: Int, haptic: Bool) {
        let value = Self.stops[index]
        guard value != rpe else { return }
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { rpe = value }
        if haptic {
            dragHaptic += 1
        }
    }

    static func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 1)))
    }

    /// RPE in words: "two left in the tank".
    static func words(for rpe: Double) -> String {
        switch rpe {
        case 10...: "nothing left"
        case 9.5...: "maybe one left"
        case 9...: "one left in the tank"
        case 8.5...: "one or two left"
        case 8...: "two left in the tank"
        case 7.5...: "two or three left"
        case 7...: "three left in the tank"
        case 6.5...: "three or four left"
        default: "four or more left"
        }
    }
}

#Preview {
    @Previewable @State var rpe: Double? = 8
    RPEStops(rpe: $rpe)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.Workout.ground)
}
