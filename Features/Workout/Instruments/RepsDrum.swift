import SwiftUI

/// Round 6 ("Plein") paint. Kept here so a restyle is a one-line change.
private enum Paint {
    static let cream = Color(hex: 0xF3ECE0)
    static let neighbour = cream.opacity(0.35)
    static let ghost = cream.opacity(0.55)
}

/// Reps as a vertical drum, on the opposite axis to the weight dial: just numbers in a snap scroll, no box. Three
/// rows show; the centre value is large and cream with a "× " before it, its neighbours small and dim, and the top
/// and bottom fade out. Last time's reps sit below as a ghost target.
struct RepsDrum: View {
    @Binding var reps: Int
    var range: ClosedRange<Int> = 0 ... 30
    var ghost: Int?

    @State private var scrolledReps: Int?
    @State private var phase: ScrollPhase = .idle
    /// Bumped only for changes made by the hand.
    @State private var tickHaptic = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Metrics {
        static let width: CGFloat = 92
        static let pitch: CGFloat = 44
        static let rows: CGFloat = 3
        static let current: CGFloat = 48
        static let other: CGFloat = 21
        /// Size and colour follow the roll over 160 ms.
        static let roll = Animation.easeOut(duration: 0.16)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
            drum
            if let ghost {
                Text("last \(ghost)")
                    .font(Theme.voice)
                    .foregroundStyle(Paint.ghost)
                    .frame(width: Metrics.width, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
        .onAppear { scrolledReps = clamp(reps) }
        .onChange(of: scrolledReps) { _, new in drumTurned(to: new) }
        .onChange(of: reps) { _, new in repsChanged(to: new) }
        .sensoryFeedback(.selection, trigger: tickHaptic)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reps")
        .accessibilityValue("\(reps)")
        .accessibilityHint(ghost.map { "Last time \($0)" } ?? "")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: reps = clamp(reps + 1)
            case .decrement: reps = clamp(reps - 1)
            @unknown default: break
            }
        }
    }

    private var drum: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(range), id: \.self) { value in
                    row(value)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
        .scrollPosition(id: $scrolledReps, anchor: .center)
        .contentMargins(.vertical, Metrics.pitch * (Metrics.rows - 1) / 2, for: .scrollContent)
        .onScrollPhaseChange { _, new in phase = new }
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.3),
                    .init(color: .black, location: 0.7),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(width: Metrics.width, height: Metrics.pitch * Metrics.rows)
    }

    private func row(_ value: Int) -> some View {
        let isCurrent = value == (scrolledReps ?? reps)
        return HStack(spacing: 0) {
            Text("× ")
                .opacity(isCurrent ? 1 : 0)
            Text("\(value)")
        }
        .font(Theme.numeral(Metrics.current))
        .dynamicTypeSize(...DynamicTypeSize.large)
        .foregroundStyle(isCurrent ? Paint.cream : Paint.neighbour)
        // Set at the centre size and scaled down, so a row grows smoothly as it rolls to the middle.
        .scaleEffect(isCurrent ? 1 : Metrics.other / Metrics.current, anchor: .trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(height: Metrics.pitch)
        .tesseraAnimation(Metrics.roll, value: isCurrent)
    }

    // MARK: Sync

    private var isHandDriven: Bool {
        phase == .tracking || phase == .interacting || phase == .decelerating
    }

    private func drumTurned(to value: Int?) {
        guard let value, isHandDriven, value != reps else { return }
        reps = value
        tickHaptic += 1
    }

    private func repsChanged(to value: Int) {
        let target = clamp(value)
        guard target != scrolledReps, !isHandDriven else { return }
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            scrolledReps = target
        }
    }

    private func clamp(_ value: Int) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

#Preview {
    @Previewable @State var reps = 8
    HStack(spacing: Theme.Spacing.xl) {
        RepsDrum(reps: $reps, ghost: 8)
        VStack(alignment: .leading) {
            Text("\(reps)")
                .font(Theme.numeral(64))
                .foregroundStyle(Theme.Colors.Workout.ink)
            Button("+1") { reps += 1 }
                .textRole(.label)
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Colors.Workout.ground)
}
