import SwiftUI
import TesseraCore

// The live workout, version 2 (Design 153, behind the `liveV2` Review switch, default Off): sentence case everywhere,
// one hot action (Training's accent), the top line "Bench press, set 2 of 4" with the name as an opens word, a context
// line "Last time 80 for 8", and the weight drawn by HouseNumber with a unit turn. Presentation only: every live
// gesture, haptic and the rest wiring stay as they are.

enum LiveV2 {
    nonisolated static let choiceID = "liveV2"

    @MainActor static var isOn: Bool {
        ReviewChoices.shared.value(of: choiceID) == "On"
    }

    /// The accent of this screen: Training's accent with the switch on, the old signal paint with it off.
    @MainActor static var accent: Color {
        isOn ? Theme.Colors.Accent.training : WorkoutPaint.live
    }

    // MARK: Words (pure, tested)

    /// The name and the rest of the top line: ("Bench press", ", set 2 of 4").
    static func topParts(exercise: String, set: Int, of total: Int) -> (name: String, rest: String) {
        (exercise, ", set \(max(set, 1)) of \(max(total, set, 1))")
    }

    /// "Bench press, set 2 of 4".
    static func topLine(exercise: String, set: Int, of total: Int) -> String {
        let parts = topParts(exercise: exercise, set: set, of: total)
        return parts.name + parts.rest
    }

    /// "Last time 80 for 8": the previous session's best working set, the weight in the display unit with no symbol.
    /// Nil when there is no history.
    static func lastTime(weightKg: Double?, reps: Double?, unit: MassUnit) -> String? {
        guard let weightKg, let reps, weightKg.isFinite, reps.isFinite, reps >= 0, reps < 10000 else { return nil }
        let number = StatsMass.number(kg: weightKg, unit: unit)
        return "Last time \(number) for \(Int(reps))"
    }

    /// The best working set of a session: the heaviest, the more reps breaking a tie (the same rule the drum's ghost
    /// reads). Nil with no sets.
    static func bestSet(_ sets: [(weight: Double, reps: Double)]) -> (weight: Double, reps: Double)? {
        sets.max { left, right in
            left.weight == right.weight ? left.reps < right.reps : left.weight < right.weight
        }
    }

    /// The unit word shown beside the weight: "kg", "lb", with "each" kept for dumbbells.
    static func unitWord(_ unit: MassUnit, perHand: Bool) -> String {
        unit.symbol + (perHand ? " each" : "")
    }

    /// The other unit (a tap on the unit word turns kilograms to pounds and back).
    static func turned(_ unit: MassUnit) -> MassUnit {
        unit == .kilograms ? .pounds : .kilograms
    }

    /// A pull on the weight, 0 to 1, from how far the finger has gone (120 pt is the full pull).
    static func pressure(translation: CGFloat) -> CGFloat {
        guard translation.isFinite else { return 0 }
        return min(abs(translation) / 120, 1)
    }

    /// Turns the display unit exactly as the Measure unit swipe does: his pick for the weight kind is saved
    /// (`AppModel.chooseUnit`), and the dial's own unit follows.
    @MainActor static func turnUnit(model: AppModel) {
        let next = turned(Format.unit)
        Format.unit = next
        model.chooseUnit(next.symbol, for: .weight)
    }
}

extension WorkoutSession {
    /// The previous session's best working set for the current exercise, in kilograms.
    var lastTimeBest: (weight: Double, reps: Double)? {
        guard let exercise = currentExercise,
              let last = ledger.sessions(of: exercise, excludingWorkout: workout.id).first else { return nil }
        return LiveV2.bestSet(last.sets.map { ($0.weight, $0.reps) })
    }

    /// "Last time 80 for 8", or nil with no history.
    var lastTimeLine: String? {
        let best = lastTimeBest
        return LiveV2.lastTime(weightKg: best?.weight, reps: best?.reps, unit: Format.unit)
    }
}

// MARK: - Sentence case keys

/// A key word in sentence case (the old key word capitalises everything). With the switch Off it is exactly the old
/// role.
private struct LiveKeyWord: ViewModifier {
    func body(content: Content) -> some View {
        if LiveV2.isOn {
            let spec = Theme.concept.scale.label
            content
                .font(Theme.Typography.font(spec, weight: .bold))
                .tracking(spec.tracking * spec.size)
                .textCase(nil)
        } else {
            content.textRole(.keyWord)
        }
    }
}

extension View {
    /// `.textRole(.keyWord)`, in sentence case when Live v2 is on.
    func liveKeyWord() -> some View {
        modifier(LiveKeyWord())
    }
}

// MARK: - The top line and the context line

/// Back, then "{Exercise}, set {n} of {total}" (the name opens the exercise page), then "Last time 80 for 8" under it.
/// Outside the set phase the old context line ("Rest, then set 2") stands in for the top line.
struct LiveV2Header<Back: View>: View {
    let session: WorkoutSession
    let phase: WorkoutSession.Phase
    var onOrder: () -> Void
    @ViewBuilder var back: () -> Back

    @Environment(AppModel.self) private var model
    @Environment(\.zoomNamespace) private var zoomNamespace
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Spacing.m) { back(); top }
                VStack(alignment: .leading, spacing: 0) { back(); top }
            }
            if let last = session.lastTimeLine, phase == .set {
                Text(last)
                    .textRole(.label)
                    .foregroundStyle(WorkoutPaint.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(last)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var top: some View {
        if phase == .set, let entry = session.currentEntry,
           let exercise = session.currentExercise
        {
            let parts = LiveV2.topParts(
                exercise: WorkoutLines.sentenceCase(exercise.name),
                set: session.currentSetNumber,
                of: session.targetSets(of: entry)
            )
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 0))
            layout {
                Button { model.open(.classDef(exercise.id), .deeper) } label: {
                    Text(parts.name)
                        .textRole(.label)
                        .foregroundStyle(WorkoutPaint.cream)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opens(Route.classDef(exercise.id), namespace: zoomNamespace)
                .accessibilityHint("Opens the exercise page")
                orderWord(parts.rest)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            orderWord(WorkoutLines.context(session, phase: phase))
        }
    }

    /// The tail of the line: a tap or a pull down shows the running order, as the old context line did.
    private func orderWord(_ text: String) -> some View {
        Text(text)
            .textRole(.label)
            .foregroundStyle(WorkoutPaint.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.opacity)
            .tesseraAnimation(value: text)
            .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onOrder() }
            .gesture(DragGesture(minimumDistance: 12).onEnded { drag in
                if drag.translation.height > 30 {
                    onOrder()
                }
            })
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Shows the running order")
    }
}

// MARK: - The weight

/// The dial's number drawn by HouseNumber: the weight in the display unit, pressed heavier by the instrument's own
/// drag,
/// with the unit word turning kilograms and pounds on a tap. The dial itself still moves in kilograms.
struct LiveV2WeightNumber: View {
    let value: Double
    /// The dial's unit word ("kg" or "kg each").
    let unit: String
    let pull: CGFloat
    var onUnitTap: () -> Void

    var body: some View {
        let perHand = unit.hasSuffix("each")
        HouseNumber(
            value: Format.unit.fromKilograms(value),
            unit: LiveV2.unitWord(Format.unit, perHand: perHand),
            role: .heroNumber,
            pressure: pull,
            onUnitTap: onUnitTap
        )
        .fixedSize()
    }
}
