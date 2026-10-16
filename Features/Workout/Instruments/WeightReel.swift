import SwiftUI
import TesseraCore

private typealias Paint = WorkoutPaint

/// The weight numeral is the control (docs/design/set-block.md): drag up or down on it, one load per 12 pt, faster
/// for big moves, a fling coasts and lands on a load. The neighbours show only while the finger is down. A tap types
/// in place. The feel is Core's `ScrubFeel` (Research's fixtures); this view only draws it.
struct WeightReel: View {
    @Binding var weight: Double
    /// Every loadable weight, ascending.
    let detents: [Double]
    let unit: String
    var isLocked = false
    /// VoiceOver's value ("82.5 kilograms, 25, 5 and 1.25 per side").
    var spokenValue: String?
    /// One side's plates for a weight, so a plate of 5 kg or more going on or off can be felt.
    var platesPerSide: (Double) -> [Double]? = { _ in nil }
    var onType: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var touching = false
    @State private var axis: ScrubFeel.Axis?
    @State private var drag = ScrubFeel.Drag()
    @State private var lastTranslation: CGFloat = 0
    @State private var startIndex = 0
    /// The detent showing while the hand or a coast moves it (nil at rest: show `weight`).
    @State private var shownIndex: Int?
    @State private var direction: CGFloat = 1
    @State private var band: CGFloat = 0
    @State private var boundFired = false
    @State private var coast: Task<Void, Never>?
    @State private var ticks = 0
    @State private var lastTick = Date.distantPast
    @State private var plateBumps = 0
    @State private var bounds = 0

    private enum Metrics {
        static let numeral: CGFloat = 80
        static let neighbour: CGFloat = 34
        static let neighbourGap: CGFloat = 48
    }

    var body: some View {
        let index = shownIndex ?? currentIndex
        let value = detents.indices.contains(index) ? detents[index] : weight
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            ZStack {
                if touching, !reduceMotion {
                    neighbour(index - 1).offset(y: -Metrics.neighbourGap - 8)
                    neighbour(index + 1).offset(y: Metrics.neighbourGap + 8)
                }
                Text(Format.kilograms(value))
                    .font(Theme.numeral(Metrics.numeral))
                    .foregroundStyle(Paint.cream)
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .opacity : .numericText(countsDown: direction < 0))
                    .tesseraAnimation(.spring(response: 0.3, dampingFraction: 0.8), value: value)
                    .offset(y: band)
            }
            .fixedSize()
            Text(unit)
                .font(Theme.voice)
                .foregroundStyle(Paint.secondary)
        }
        .contentShape(Rectangle().inset(by: -16))
        .gesture(isLocked ? nil : scrub)
        .sensoryFeedback(.selection, trigger: ticks)
        .sensoryFeedback(.impact(weight: .light), trigger: plateBumps)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.6), trigger: bounds)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weight")
        .accessibilityValue(spokenValue ?? "\(Format.kilograms(weight)) kilograms")
        .accessibilityHint("Swipe up or down to change by one load. Double tap to type.")
        .accessibilityAdjustableAction { change in
            guard !isLocked else { return }
            let step = change == .increment ? 1 : -1
            weight = detents[ScrubFeel.land(start: currentIndex, steps: step, count: detents.count).index]
        }
        .accessibilityAction { if !isLocked { onType() } }
    }

    private func neighbour(_ index: Int) -> some View {
        Text(detents.indices.contains(index) ? Format.kilograms(detents[index]) : "")
            .font(Theme.numeral(Metrics.neighbour))
            .foregroundStyle(Paint.cream.opacity(0.35))
            .transition(.opacity.animation(.easeOut(duration: 0.18)))
    }

    private var currentIndex: Int {
        guard !detents.isEmpty else { return 0 }
        return detents.indices.min { abs(detents[$0] - weight) < abs(detents[$1] - weight) } ?? 0
    }

    // MARK: The gesture

    private var scrub: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !touching {
                    begin()
                }
                if axis == nil {
                    axis = ScrubFeel.axis(dx: value.translation.width, dy: value.translation.height)
                }
                // Sideways belongs to the exercise lane, decided once.
                guard axis == .vertical else { return }
                let delta = value.translation.height - lastTranslation
                lastTranslation = value.translation.height
                drag.add(up: -delta, speed: abs(value.velocity.height))
                show(drag.steps, overflowing: -value.translation.height)
            }
            .onEnded { value in
                defer { axis = nil }
                guard axis == .vertical else {
                    if axis == nil, hypot(value.translation.width, value.translation.height) < 10 {
                        end()
                        onType()
                    } else {
                        end()
                    }
                    return
                }
                let extra = -(value.predictedEndTranslation.height - value.translation.height)
                let coastSteps = ScrubFeel.coast(predictedExtra: extra)
                withTesseraAnimation(.spring(response: 0.3, dampingFraction: 0.7), reduceMotion: reduceMotion) {
                    band = 0
                }
                play(coast: coastSteps)
            }
    }

    private func begin() {
        coast?.cancel()
        // A touch during a coast stops it on the detent showing.
        startIndex = shownIndex ?? currentIndex
        if let shownIndex {
            weight = detents[shownIndex]
        }
        drag = ScrubFeel.Drag()
        lastTranslation = 0
        boundFired = false
        withTesseraAnimation(.easeOut(duration: 0.18), reduceMotion: reduceMotion) { touching = true }
    }

    private func end() {
        withTesseraAnimation(.easeOut(duration: 0.22), reduceMotion: reduceMotion) {
            touching = false
            band = 0
        }
        shownIndex = nil
    }

    /// Shows `steps` from the start, ticking per detent passed; past an end the numeral rubber-bands.
    private func show(_ steps: Int, overflowing pull: CGFloat) {
        let landing = ScrubFeel.land(start: startIndex, steps: steps, count: detents.count)
        if landing.hitBound {
            if !boundFired {
                boundFired = true
                bounds += 1
            }
            if !reduceMotion {
                let over = Double(pull) - Double(landing.index - startIndex) * ScrubFeel.pitch
                band = -CGFloat(ScrubFeel.rubberBand(overflow: over))
            }
        } else {
            band = 0
        }
        step(to: landing.index)
        // The hand's own moves commit as they go, so the plates drop on under the finger.
        weight = detents[landing.index]
    }

    private func step(to index: Int) {
        let previous = shownIndex ?? currentIndex
        guard index != previous else { return }
        direction = index > previous ? 1 : -1
        let now = Date.now
        if now.timeIntervalSince(lastTick) >= 0.03 {
            ticks += 1
            lastTick = now
        }
        if heavyPlateChanged(from: detents[previous], to: detents[index]) {
            plateBumps += 1
        }
        shownIndex = index
    }

    /// A coast plays out detent by detent, easing out, and commits the weight once at the end.
    private func play(coast steps: Int) {
        let from = shownIndex ?? currentIndex
        let landing = ScrubFeel.land(start: from, steps: steps, count: detents.count)
        let count = landing.index - from
        guard count != 0 else { return end() }
        if landing.hitBound {
            bounds += 1
        }
        if reduceMotion {
            weight = detents[landing.index]
            ticks += 1
            return end()
        }
        coast = Task { @MainActor in
            let start = Date.now
            for passed in 1 ... abs(count) {
                let at = ScrubFeel.coastTime(passed, of: count)
                let wait = at - Date.now.timeIntervalSince(start)
                if wait > 0 {
                    try? await Task.sleep(for: .seconds(wait))
                }
                guard !Task.isCancelled else { return }
                step(to: from + (count > 0 ? passed : -passed))
            }
            weight = detents[landing.index]
            end()
        }
    }

    private func heavyPlateChanged(from old: Double, to new: Double) -> Bool {
        guard let before = platesPerSide(old), let after = platesPerSide(new) else { return false }
        let heavy = { (plates: [Double]) in plates.filter { $0 >= 5 }.sorted() }
        return heavy(before) != heavy(after)
    }
}
