import SwiftUI
import TesseraCore

private typealias Paint = WorkoutPaint

/// Reps as one value with drama (docs/design/set-block.md): "× 9" at 56 Light on the weight's line. Drag up or down,
/// one rep per 28 pt, 1 to 50. A hand change lands with a pop and five ink droplets flicked the way it moved; passing
/// last time paints a short cadmium stroke under it with a rigid tap. Prefills and Undo just roll.
struct RepsRow: View {
    @Binding var reps: Int
    var range: ClosedRange<Int> = 1 ... 50
    /// Last time's reps (the ghost "LAST 8").
    var ghost: Int?
    var isLocked = false
    /// Once per set, when reps first pass last time (Tess: "One more than last time.").
    var onBeat: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var touching = false
    @State private var axis: ScrubFeel.Axis?
    @State private var drag = ScrubFeel.Drag(pitch: ScrubFeel.repsPitch, accelerates: false)
    @State private var lastTranslation: CGFloat = 0
    @State private var start = 0
    @State private var byHand = false
    @State private var pop = false
    @State private var splash = 0
    @State private var direction: CGFloat = 1
    @State private var ticks = 0
    @State private var beats = 0
    @State private var bounds = 0
    @State private var boundFired = false
    @State private var dried = false

    private var beatsLast: Bool {
        ghost.map { reps > $0 } ?? false
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("×")
                    .font(Theme.numeral(34))
                    .foregroundStyle(Paint.cream.opacity(0.6))
                // The number is the row's real content (so the whole of it takes the drag); the neighbours float
                // above and below only while the finger is down.
                Text("\(reps)")
                    .font(Theme.numeral(56))
                    .foregroundStyle(Paint.cream)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: direction < 0))
                    .scaleEffect(pop ? 1.12 : 1)
                    .overlay { Droplets(burst: splash, up: direction > 0) }
                    .overlay {
                        if touching, !reduceMotion {
                            ZStack {
                                Text(reps > range.lowerBound ? "\(reps - 1)" : "").offset(y: -44)
                                Text(reps < range.upperBound ? "\(reps + 1)" : "").offset(y: 44)
                            }
                            .font(Theme.numeral(34))
                            .foregroundStyle(Paint.cream.opacity(0.35))
                            .transition(.opacity)
                        }
                    }
                    .fixedSize()
                .frame(minWidth: 56, alignment: .trailing)
            }
            .tesseraAnimation(.spring(response: 0.32, dampingFraction: 0.62), value: reps)
            // Passing last time: a short cadmium stroke paints under the number.
            // Colour arrives in the moment and dries to ink (Kaushik: subtle at rest).
            Brushstroke(progress: beatsLast ? 1 : 0)
                .stroke(dried ? Paint.cream.opacity(0.35) : Paint.now,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .tesseraAnimation(.easeInOut(duration: 1.2), value: dried)
                .frame(width: 44, height: 8)
                .opacity(beatsLast ? 1 : 0)
                .tesseraAnimation(.easeOut(duration: 0.26), value: beatsLast)
            if let ghost, !beatsLast {
                Text("last \(ghost)")
                    .font(Theme.voice)
                    .foregroundStyle(Paint.cream.opacity(0.55))
                    .transition(.opacity)
            }
        }
        .frame(width: 96, alignment: .trailing)
        .contentShape(Rectangle().inset(by: -12))
        .gesture(isLocked ? nil : scrub)
        .onChange(of: reps) { old, new in landed(from: old, to: new) }
        .sensoryFeedback(.selection, trigger: ticks)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 1), trigger: beats)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.6), trigger: bounds)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reps")
        .accessibilityValue(spoken)
        .accessibilityAdjustableAction { change in
            guard !isLocked else { return }
            reps = min(max(reps + (change == .increment ? 1 : -1), range.lowerBound), range.upperBound)
        }
    }

    private var spoken: String {
        guard let ghost else { return "\(reps)" }
        let delta = reps - ghost
        return switch delta {
        case 0: "\(reps), same as last time"
        case 1: "\(reps), one more than last time"
        case let more where more > 1: "\(reps), \(more) more than last time"
        default: "\(reps)"
        }
    }

    private var scrub: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !touching {
                    start = reps
                    drag = ScrubFeel.Drag(pitch: ScrubFeel.repsPitch, accelerates: false)
                    lastTranslation = 0
                    boundFired = false
                    withTesseraAnimation(.easeOut(duration: 0.18), reduceMotion: reduceMotion) { touching = true }
                }
                if axis == nil {
                    axis = ScrubFeel.axis(dx: value.translation.width, dy: value.translation.height)
                }
                guard axis == .vertical else { return }
                let delta = value.translation.height - lastTranslation
                lastTranslation = value.translation.height
                drag.add(up: -delta, speed: 0)
                let landing = ScrubFeel.land(start: start - range.lowerBound, steps: drag.steps,
                                             count: range.count)
                if landing.hitBound, !boundFired {
                    boundFired = true
                    bounds += 1
                }
                let next = landing.index + range.lowerBound
                if next != reps {
                    byHand = true
                    reps = next
                }
            }
            .onEnded { _ in
                axis = nil
                withTesseraAnimation(.easeOut(duration: 0.22), reduceMotion: reduceMotion) { touching = false }
            }
    }

    /// The drama, only for the hand's changes.
    private func landed(from old: Int, to new: Int) {
        direction = new > old ? 1 : -1
        guard byHand else { return }
        byHand = false
        ticks += 1
        if let ghost, new > ghost, old <= ghost {
            beats += 1
            onBeat()
            dried = false
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                dried = true
            }
        }
        guard !reduceMotion else { return }
        splash += 1
        withTesseraAnimation(.spring(response: 0.16, dampingFraction: 0.5), reduceMotion: reduceMotion) { pop = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            withTesseraAnimation(.spring(response: 0.2, dampingFraction: 0.7), reduceMotion: reduceMotion) {
                pop = false
            }
        }
    }
}

/// Five ink droplets (5×4, cream 55%) flicked off the number the way it moved, fading over 300 to 420 ms.
private struct Droplets: View {
    let burst: Int
    let up: Bool
    @State private var flown = false

    private static let angles: [Double] = [-70, -40, -10, 20, 55]

    var body: some View {
        ZStack {
            ForEach(Self.angles.indices, id: \.self) { index in
                let angle = Angle.degrees(Self.angles[index] + (up ? -90 : 90))
                let reach: CGFloat = 26 + CGFloat(index % 3) * 9
                DabShape(seed: index)
                    .fill(Paint.cream.opacity(0.55))
                    .frame(width: 5, height: 4)
                    .offset(x: flown ? cos(angle.radians) * reach : 0, y: flown ? sin(angle.radians) * reach : 0)
                    .opacity(flown ? 0 : 1)
                    .tesseraAnimation(.easeOut(duration: 0.3 + Double(index) * 0.03), value: flown)
            }
        }
        .opacity(burst == 0 ? 0 : 1)
        .allowsHitTesting(false)
        .onChange(of: burst) {
            flown = false
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(16))
                flown = true
            }
        }
        .accessibilityHidden(true)
    }
}
