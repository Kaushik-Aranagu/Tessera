import SwiftUI

/// Round 6 ("Plein") paint. Kept here so a restyle is a one-line change.
private enum Paint {
    static var cream: Color {
        Theme.Colors.Workout.ink
    }

    static var vermilion: Color {
        Theme.Colors.Workout.signal
    }

    static var cadmium: Color {
        Theme.Colors.Workout.rest
    }

    static var minorTick: Color {
        cream.opacity(0.38)
    }

    static var majorTick: Color {
        cream.opacity(0.9)
    }

    static var label: Color {
        cream.opacity(0.72)
    }

    static var washTip: Color {
        cadmium.opacity(0.28)
    }
}

/// The precision dial for weight: a horizontal strip of ticks under a fixed centre needle, one tick per weight the
/// gym can load (Core's `WeightDial` detents). The dial owns vertical drags only (up is heavier, one load per 12 pt;
/// a flick carries on with momentum and settles exactly on a tick), so sideways swipes stay with paging. Tapping left
/// or right of the needle steps one load; the plus and minus beside it are the non-gesture path.
///
/// During rest the same part counts down: it locks, dims and a cadmium wash covers it, draining as `restFraction`
/// runs from 1 to 0. It then takes two drags: right past the needle adds 15 s (the fill grows under the finger and
/// "+15" rises over its edge), a fling left skips (the fill drains to nothing in 420 ms).
///
/// Hairline ticks on nothing, one lit needle (docs/design/workout-v1.md, "Weight dial" and "Rest on the dial").
struct WeightDial: View {
    @Binding var weight: Double
    /// Every loadable weight, ascending.
    var detents: [Double] = Array(stride(from: 0, through: 300, by: 2.5))
    var isLocked: Bool = false
    /// 1 → 0 while resting; nil hides the rest fill.
    var restFraction: Double?
    /// Rest drags. Nil turns them off.
    var onExtendRest: (() -> Void)?
    var onSkipRest: (() -> Void)?
    /// VoiceOver's value, e.g. "80 kilograms, 30 per side".
    var spokenValue: String?

    /// The tick under the needle. Kept in step with `weight` both ways.
    @State private var scrolledIndex: Int?
    @State private var phase: ScrollPhase = .idle
    @State private var width: CGFloat = 0
    /// Bumped only for changes made by the hand, so programmatic moves stay silent.
    @State private var tickHaptic = 0
    @State private var majorHaptic = 0
    @State private var extendHaptic = 0
    @State private var skipHaptic = 0
    @State private var isTyping = false
    @State private var typedValue = ""
    /// How far the finger has dragged the rest fill (points; right is positive).
    @State private var restDrag: CGFloat = 0
    @State private var isDraining = false
    /// The detent under the needle when the vertical drag began; nil when not dragging.
    @State private var dragStartIndex: Int?
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
        /// Dragging the fill this far right adds 15 s.
        static let extendThreshold: CGFloat = 48
        /// A fling left this far (or predicted twice as far) skips.
        static let skipThreshold: CGFloat = 56
        static let drain = 0.42
        /// Vertical travel per detent.
        static let dragPitch: CGFloat = 12
        /// The most a flick carries on past the finger.
        static let maxMomentum = 24
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            strip
            restFill
            needle
        }
        .frame(height: Metrics.height)
        .contentShape(Rectangle())
        .gesture(restGesture, isEnabled: restFraction != nil && onExtendRest != nil)
        .gesture(dialGesture, isEnabled: !isLocked && restFraction == nil)
        .tesseraAnimation(value: restFraction == nil)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .onAppear { scrolledIndex = index(for: weight) }
        .onChange(of: scrolledIndex) { _, new in dialTurned(to: new) }
        .onChange(of: weight) { _, new in weightChanged(to: new) }
        // A new exercise brings new detents: the strip is rebuilt (below) and lands on the weight once laid out.
        .onChange(of: detents) { _, _ in
            Task { @MainActor in scrolledIndex = index(for: weight) }
        }
        .onChange(of: restFraction == nil) { _, ended in
            if ended {
                isDraining = false
                restDrag = 0
            }
        }
        .sensoryFeedback(.selection, trigger: tickHaptic)
        .sensoryFeedback(.impact(weight: .heavy), trigger: majorHaptic)
        .sensoryFeedback(.increase, trigger: extendHaptic)
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.7), trigger: skipHaptic)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(restFraction == nil ? "Weight" : "Rest")
        .accessibilityValue(spokenValue ?? "\(formatted(weight)) kilograms")
        .accessibilityHint(isLocked ? "Resting. Actions add 15 seconds or skip." : "Swipe up or down for one load")
        .accessibilityAdjustableAction { direction in
            guard !isLocked else { return }
            switch direction {
            case .increment: step(up: true, haptic: false)
            case .decrement: step(up: false, haptic: false)
            @unknown default: break
            }
        }
        .accessibilityAction(named: "Type value") {
            guard !isLocked else { return }
            typedValue = formatted(weight)
            isTyping = true
        }
        .accessibilityActions {
            if restFraction != nil, let onExtendRest, let onSkipRest {
                Button("Add 15 seconds", action: onExtendRest)
                Button("Skip rest", action: onSkipRest)
            }
        }
        .alert("Weight", isPresented: $isTyping) {
            TextField("Kilograms", text: $typedValue)
                .keyboardType(.decimalPad)
            Button("Set") { commitTypedValue() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Goes to the nearest weight the gym can load.")
        }
    }

    // MARK: Parts

    private var strip: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 0) {
                ForEach(detents.indices, id: \.self) { index in
                    tick(at: index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
        .scrollPosition(id: $scrolledIndex, anchor: .center)
        .id(detents.count)
        .contentMargins(.horizontal, max(0, width / 2 - Metrics.pitch / 2), for: .scrollContent)
        // Hand input is the vertical drag below; the strip only shows where the needle is.
        .scrollDisabled(true)
        .onScrollPhaseChange { _, new in phase = new }
        .onTapGesture { location in
            // The one-tap twin: left of the needle is one load lighter, right is one heavier.
            guard !isLocked, abs(location.x - width / 2) > Metrics.pitch else { return }
            step(up: location.x > width / 2, haptic: true)
        }
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
        let value = detents[index]
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
                let base = min(max(restFraction, 0), 1)
                let dragged = min(base + max(restDrag, 0) / max(proxy.size.width, 1), 1)
                let fraction = isDraining ? 0 : dragged
                let edge = proxy.size.width * fraction
                LinearGradient(colors: [Paint.cadmium.opacity(0), Paint.washTip], startPoint: .leading,
                               endPoint: .trailing)
                    .overlay(alignment: .trailing) { Paint.cadmium.frame(width: 2) }
                    .frame(width: edge, height: Metrics.washHeight)
                    .offset(y: Metrics.washTop)
                    // The countdown ticks once a second; the edge drains continuously between ticks.
                    .tesseraAnimation(restDrag == 0 ? .linear(duration: 1) : .interactiveSpring, value: fraction)
                Text("+15")
                    .textRole(.labelStrong)
                    .foregroundStyle(Paint.cadmium)
                    .fixedSize()
                    .position(x: max(edge - 16, 16), y: Metrics.washTop - 6)
                    .offset(y: restDrag >= Metrics.extendThreshold ? -8 : 4)
                    .opacity(restDrag >= Metrics.extendThreshold && !isDraining ? 1 : 0)
                    .tesseraAnimation(Theme.Motion.snappy, value: restDrag >= Metrics.extendThreshold)
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

    // MARK: Rest drags

    private var restGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { drag in
                guard !isDraining else { return }
                restDrag = drag.translation.width
            }
            .onEnded { drag in
                guard !isDraining else { return }
                let distance = drag.translation.width
                let predicted = drag.predictedEndTranslation.width
                if distance >= Metrics.extendThreshold {
                    extendHaptic += 1
                    onExtendRest?()
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { restDrag = 0 }
                } else if distance <= -Metrics.skipThreshold || predicted <= -Metrics.skipThreshold * 2.5 {
                    skipHaptic += 1
                    restDrag = 0
                    withTesseraAnimation(.easeIn(duration: Metrics.drain), reduceMotion: reduceMotion) {
                        isDraining = true
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(Metrics.drain))
                        onSkipRest?()
                    }
                } else {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { restDrag = 0 }
                }
            }
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
        guard let index, isHandDriven, !isLocked, detents.indices.contains(index) else { return }
        set(detents[index], haptic: true)
    }

    private func step(up: Bool, haptic: Bool) {
        let current = index(for: weight)
        let next = min(max(current + (up ? 1 : -1), 0), detents.count - 1)
        guard detents.indices.contains(next) else { return }
        set(detents[next], haptic: haptic)
    }

    private func set(_ newValue: Double, haptic: Bool) {
        guard newValue != weight else { return }
        let crossedMajor = Int((weight / 10).rounded(.down)) != Int((newValue / 10).rounded(.down))
        weight = newValue
        guard haptic else { return }
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
        guard let typed = Double(text.trimmingCharacters(in: .whitespaces)), !detents.isEmpty else { return }
        weight = detents[index(for: typed)]
    }

    // MARK: Values

    /// The nearest detent's index.
    private func index(for value: Double) -> Int {
        guard !detents.isEmpty else { return 0 }
        var best = 0
        for (index, detent) in detents.enumerated() where abs(detent - value) < abs(detents[best] - value) {
            best = index
        }
        return best
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
}

extension WeightDial {
    // MARK: The vertical drag

    /// Claims only drags that start more vertical than horizontal; up is heavier.
    var dialGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { drag in
                if dragStartIndex == nil {
                    guard abs(drag.translation.height) > abs(drag.translation.width) else { return }
                    dragStartIndex = index(for: weight)
                }
                guard let start = dragStartIndex else { return }
                let steps = Int((-drag.translation.height / Metrics.dragPitch).rounded(.towardZero))
                move(to: start + steps)
            }
            .onEnded { drag in
                defer { dragStartIndex = nil }
                guard let start = dragStartIndex else { return }
                let steps = Int((-drag.translation.height / Metrics.dragPitch).rounded(.towardZero))
                // Reduce Motion: no momentum, the dial stops under the finger.
                let flick = reduceMotion ? 0 : (drag.translation.height - drag.predictedEndTranslation.height)
                    / Metrics.dragPitch / 2
                let momentum = max(-Metrics.maxMomentum, min(Metrics.maxMomentum, Int(flick.rounded())))
                move(to: start + steps + momentum)
            }
    }

    private func move(to index: Int) {
        guard !detents.isEmpty else { return }
        set(detents[min(max(index, 0), detents.count - 1)], haptic: true)
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
