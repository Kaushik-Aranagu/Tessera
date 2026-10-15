import SwiftUI

/// Round 6 ("Plein") paint. Kept here so a restyle is a one-line change.
private enum Paint {
    static let cream = Color(hex: 0xF3ECE0)
    static let vermilion = Color(hex: 0xD9563F)
    static let stop = cream.opacity(0.38)
    static let stopReached = cream.opacity(0.9)
    static let rail = cream.opacity(0.14)
    static let off = cream.opacity(0.38)
}

/// Optional effort as a short slider with stops at 6, 6.5 … 10 and an "off" stop at the far left. One swipe sets it;
/// the marker snaps from stop to stop under the finger with a selection tick.
struct RPEStops: View {
    @Binding var rpe: Double?

    @State private var dragHaptic = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Index 0 is off; 1 … 9 are 6.0 … 10.0 in halves.
    private static let stops: [Double?] = [nil] + stride(from: 6.0, through: 10.0, by: 0.5).map(Optional.some)

    private enum Metrics {
        static let trackWidth: CGFloat = 196
        static let height: CGFloat = 44
        static let stopShort: CGFloat = 8
        static let stopLong: CGFloat = 14
        static let marker: CGFloat = 24
    }

    var body: some View {
        // At accessibility sizes the label sits above the track instead of beside it.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.s))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.l))
        layout {
            Text(title)
                .textRole(.label)
                .foregroundStyle(rpe == nil ? Paint.off : Paint.cream)
                .contentTransition(.numericText())
                .tesseraAnimation(Theme.Motion.snappy, value: rpe)
            track
        }
        .sensoryFeedback(.selection, trigger: dragHaptic)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Effort, RPE")
        .accessibilityValue(rpe.map(Self.formatted) ?? "Off")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: select(min(currentIndex + 1, Self.stops.count - 1), haptic: false)
            case .decrement: select(max(currentIndex - 1, 0), haptic: false)
            @unknown default: break
            }
        }
    }

    private var title: String {
        "RPE " + (rpe.map(Self.formatted) ?? "—")
    }

    private var track: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Paint.rail
                    .frame(height: 1)
                ForEach(Self.stops.indices, id: \.self) { index in
                    stopMark(index)
                        .position(x: x(for: index, in: width), y: proxy.size.height / 2)
                }
                Paint.vermilion
                    .shadow(color: Paint.vermilion.opacity(0.7), radius: 5)
                    .opacity(rpe == nil ? 0 : 1)
                    .frame(width: 2, height: Metrics.marker)
                    .position(x: x(for: currentIndex, in: width), y: proxy.size.height / 2)
                    .tesseraAnimation(Theme.Motion.snappy, value: currentIndex)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in select(index(at: drag.location.x, in: width), haptic: true) }
            )
        }
        .frame(width: Metrics.trackWidth, height: Metrics.height)
    }

    private func stopMark(_ index: Int) -> some View {
        let value = Self.stops[index]
        let isWhole = value.map { $0 == $0.rounded() } ?? false
        let isReached = value.map { stop in rpe.map { stop <= $0 } ?? false } ?? false
        return RoundedRectangle(cornerRadius: 0.5, style: .continuous)
            .fill(isReached ? Paint.stopReached : Paint.stop)
            .frame(
                width: value == nil ? Metrics.stopShort : 1.5,
                height: value == nil ? 1.5 : isWhole ? Metrics.stopLong
                    : Metrics.stopShort
            )
    }

    private var currentIndex: Int {
        Self.stops.firstIndex(of: rpe) ?? 0
    }

    private func x(for index: Int, in width: CGFloat) -> CGFloat {
        let inset = Metrics.stopShort / 2
        return inset + (width - 2 * inset) * CGFloat(index) / CGFloat(Self.stops.count - 1)
    }

    private func index(at x: CGFloat, in width: CGFloat) -> Int {
        let inset = Metrics.stopShort / 2
        let fraction = (x - inset) / max(width - 2 * inset, 1)
        let raw = (fraction * CGFloat(Self.stops.count - 1)).rounded()
        return min(max(Int(raw), 0), Self.stops.count - 1)
    }

    private func select(_ index: Int, haptic: Bool) {
        guard index != currentIndex else { return }
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            rpe = Self.stops[index]
        }
        if haptic {
            dragHaptic += 1
        }
    }

    private static func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 1)))
    }
}

#Preview {
    @Previewable @State var rpe: Double? = 8
    RPEStops(rpe: $rpe)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.Workout.ground)
}
