import SwiftUI

/// Round 6 ("Plein") paint. Kept here so a restyle is a one-line change.
private enum Paint {
    static let cream = Color(hex: 0xF3ECE0)
    static let vermilion = Color(hex: 0xD9563F)
    static let cadmium = Color(hex: 0xE8BD4C)
    static let minorTick = cream.opacity(0.38)
    static let majorTick = cream.opacity(0.9)
    static let label = cream.opacity(0.6)
    static let washTip = cadmium.opacity(0.28)
}

/// The precision dial for weight: a horizontal strip of ticks under a fixed centre needle. A flick spins with
/// momentum and settles exactly on a tick (a valid plate load). During rest the same part counts down: it locks,
/// the dial dims and a cadmium wash covers it, draining as `restFraction` runs from 1 to 0.
///
/// Hairline ticks on nothing, one lit needle (docs/design/workout-v1.md, "Weight dial").
struct WeightDial: View {
    @Binding var weight: Double
    var range: ClosedRange<Double> = 0 ... 300
    var step: Double = 2.5
    var isLocked: Bool = false
    /// 1 → 0 while resting; nil hides the rest fill.
    var restFraction: Double?

    /// The tick under the needle. Kept in step with `weight` both ways.
    @State private var scrolledIndex: Int?
    @State private var phase: ScrollPhase = .idle
    @State private var width: CGFloat = 0
    /// Bumped only for changes made by the hand, so programmatic moves stay silent.
    @State private var tickHaptic = 0
    @State private var majorHaptic = 0
    @State private var isTyping = false
    @State private var typedValue = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Metrics {
        static let height: CGFloat = 80
        static let pitch: CGFloat = 14
        static let tickTop: CGFloat = 6
        static let minor: CGFloat = 11
        static let mid: CGFloat = 18
        static let major: CGFloat = 30
        static let needle: CGFloat = 44
        static let needleGlow: CGFloat = 10
        static let labelTop: CGFloat = 50
        static let washTop: CGFloat = 4
        static let washHeight: CGFloat = 36
        /// The dial during rest.
        static let lockedOpacity = 0.35
        static let lockedNeedleOpacity = 0.3
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            strip
            restFill
            needle
        }
        .frame(height: Metrics.height)
        .tesseraAnimation(value: restFraction == nil)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .onAppear { scrolledIndex = index(for: weight) }
        .onChange(of: scrolledIndex) { _, new in dialTurned(to: new) }
        .onChange(of: weight) { _, new in weightChanged(to: new) }
        .sensoryFeedback(.selection, trigger: tickHaptic)
        .sensoryFeedback(.impact(weight: .heavy), trigger: majorHaptic)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weight")
        .accessibilityValue("\(formatted(weight)) kilograms")
        .accessibilityHint(isLocked ? "Locked while resting" : "")
        .accessibilityAdjustableAction { direction in
            guard !isLocked else { return }
            switch direction {
            case .increment: weight = clamp(snap(weight) + step)
            case .decrement: weight = clamp(snap(weight) - step)
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Type value") {
            guard !isLocked else { return }
            typedValue = formatted(weight)
            isTyping = true
        }
        .alert("Weight", isPresented: $isTyping) {
            TextField("Kilograms", text: $typedValue)
                .keyboardType(.decimalPad)
            Button("Set") { commitTypedValue() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Rounds to the nearest \(formatted(step)) kg.")
        }
    }

    // MARK: Parts

    private var strip: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 0) {
                ForEach(0 ..< tickCount, id: \.self) { index in
                    tick(at: index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
        .scrollPosition(id: $scrolledIndex, anchor: .center)
        .contentMargins(.horizontal, max(0, width / 2 - Metrics.pitch / 2), for: .scrollContent)
        .scrollDisabled(isLocked)
        .onScrollPhaseChange { _, new in phase = new }
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.25),
                    .init(color: .black, location: 0.75),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .opacity(isLocked ? Metrics.lockedOpacity : 1)
        .tesseraAnimation(value: isLocked)
    }

    private func tick(at index: Int) -> some View {
        let value = value(at: index)
        let kind = TickKind(value)
        return Rectangle()
            .fill(kind.color)
            .frame(width: kind == .major ? 1.5 : 1, height: kind.length)
            .padding(.top, Metrics.tickTop)
            .frame(width: Metrics.pitch, height: Metrics.height, alignment: .top)
            .overlay(alignment: .top) {
                if kind == .major {
                    Text(formatted(value))
                        .textRole(.data)
                        .fontWeight(.semibold)
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .foregroundStyle(Paint.label)
                        .fixedSize()
                        .offset(y: Metrics.labelTop)
                }
            }
    }

    @ViewBuilder
    private var restFill: some View {
        if let restFraction {
            GeometryReader { proxy in
                LinearGradient(colors: [Paint.cadmium.opacity(0), Paint.washTip], startPoint: .leading,
                               endPoint: .trailing)
                    .overlay(alignment: .trailing) { Paint.cadmium.frame(width: 2) }
                    .frame(width: proxy.size.width * min(max(restFraction, 0), 1), height: Metrics.washHeight)
                    .offset(y: Metrics.washTop)
                    // The countdown ticks once a second; the edge drains continuously between ticks.
                    .tesseraAnimation(.linear(duration: 1), value: restFraction)
            }
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    private var needle: some View {
        Paint.vermilion
            .frame(width: 2, height: Metrics.needle)
            .shadow(color: Paint.vermilion.opacity(0.7), radius: Metrics.needleGlow / 2)
            .opacity(isLocked ? Metrics.lockedNeedleOpacity : 1)
            .frame(maxWidth: .infinity)
            .allowsHitTesting(false)
            .tesseraAnimation(value: isLocked)
    }

    private enum TickKind {
        case minor, mid, major

        init(_ value: Double) {
            if Self.isMultiple(value, of: 10) {
                self = .major
            } else if Self.isMultiple(value, of: 5) {
                self = .mid
            } else {
                self = .minor
            }
        }

        var length: CGFloat {
            switch self {
            case .minor: Metrics.minor
            case .mid: Metrics.mid
            case .major: Metrics.major
            }
        }

        var color: Color {
            switch self {
            case .minor, .mid: Paint.minorTick
            case .major: Paint.majorTick
            }
        }

        private static func isMultiple(_ value: Double, of base: Double) -> Bool {
            abs(value.remainder(dividingBy: base)) < 0.001
        }
    }

    // MARK: Sync

    private var isHandDriven: Bool {
        phase == .tracking || phase == .interacting || phase == .decelerating
    }

    private func dialTurned(to index: Int?) {
        guard let index, isHandDriven, !isLocked else { return }
        let newValue = value(at: index)
        guard newValue != weight else { return }
        let crossedMajor = Int((weight / 10).rounded(.down)) != Int((newValue / 10).rounded(.down))
        weight = newValue
        if crossedMajor {
            majorHaptic += 1
        } else {
            tickHaptic += 1
        }
    }

    private func weightChanged(to newValue: Double) {
        let index = index(for: newValue)
        guard index != scrolledIndex, !isHandDriven else { return }
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            scrolledIndex = index
        }
    }

    private func commitTypedValue() {
        let text = typedValue.replacingOccurrences(of: ",", with: ".")
        guard let typed = Double(text.trimmingCharacters(in: .whitespaces)) else { return }
        weight = clamp(snap(typed))
    }

    // MARK: Values

    private var tickCount: Int {
        Int(((range.upperBound - range.lowerBound) / step).rounded(.down)) + 1
    }

    private func value(at index: Int) -> Double {
        range.lowerBound + Double(index) * step
    }

    private func index(for value: Double) -> Int {
        let raw = ((value - range.lowerBound) / step).rounded()
        return min(max(Int(raw), 0), tickCount - 1)
    }

    private func snap(_ value: Double) -> Double {
        self.value(at: index(for: value))
    }

    private func clamp(_ value: Double) -> Double {
        min(max(value, range.lowerBound), self.value(at: tickCount - 1))
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
}

#Preview {
    @Previewable @State var weight = 82.5
    @Previewable @State var resting = false
    @Previewable @State var fraction = 1.0
    VStack(spacing: Theme.Spacing.xl) {
        Text("\(weight.formatted()) kg")
            .font(Theme.numeral(64))
            .contentTransition(.numericText(value: weight))
            .foregroundStyle(Theme.Colors.Workout.ink)
        WeightDial(weight: $weight, isLocked: resting, restFraction: resting ? fraction : nil)
        HStack {
            Button("+10") { weight += 10 }
            Button(resting ? "End rest" : "Rest") { resting.toggle(); fraction = 1 }
            Button("Drain") { fraction = max(0, fraction - 0.2) }
        }
        .textRole(.label)
        .foregroundStyle(Theme.Colors.Workout.inkSecondary)
    }
    .padding(Theme.Spacing.m)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.Colors.Workout.ground)
}
