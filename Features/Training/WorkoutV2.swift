import SwiftUI
import TesseraCore

/// The live workout, sheet 230. Top to bottom, in fixed slots that never move as things change: the band (only the
/// current lift, or the warm-up, the rest, the done line), the big number (the weight, or a countdown), the stacks
/// with the trail of reps to their right, the brief, the session wheel and the foot, which always holds ONE word.
/// A left-edge swipe leaves the workout running (the landing reads "Today, going").
struct WorkoutV2: View {
    let session: WorkoutSession
    @Environment(AppModel.self) var model
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.lowPowerMotion) var lowPower
    @Environment(\.dynamicTypeSize) var typeSize
    @State var flow: WorkoutFlow
    @State var wheelFocus = 1
    @State var cue = HapticCue()
    @State var wasVisible = false
    @State var flight = SetFlight()
    @State var finishedHaptic = 0
    @State var rowWidth: CGFloat = 0

    init(session: WorkoutSession) {
        self.session = session
        _flow = State(initialValue: WorkoutFlows.flow(for: session))
    }

    /// The slots' heights: nothing below shifts when what is inside changes.
    enum Slot {
        static let band: CGFloat = 92
        static let number: CGFloat = 100
        static let marks: CGFloat = 56
        static let brief: CGFloat = 40
        static let foot: CGFloat = 36
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = AppClock.adjust(context.date)
            let finished = session.finishedAt != nil
            let stage = flow.stage(at: now)
            screen(stage: stage, finished: finished, now: now)
                .onChange(of: isRest(stage)) { wasRest, isRest in
                    // Rest ran out on its own (not skipped): one weighty tap with the app on screen.
                    if wasRest, !isRest, let end = session.restEndsAt, end <= now {
                        cue.play(.timeUp)
                    }
                }
        }
        .padding(.horizontal, Theme.Spacing.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { Theme.Colors.paper.ignoresSafeArea() }
        .preferredColorScheme(ThemeStore.shared.workoutLook.isDark ? .dark : .light)
        .persistentSystemOverlays(.hidden)
        .tesseraFeedback(cue)
        .tesseraFeedback(.done, trigger: finishedHaptic)
        .simultaneousGesture(edgeBack)
        .onAppear {
            flow.advanceIfNeeded()
            wheelFocus = homeIndex
            DonePattern.prepare()
        }
        .onChange(of: session.currentIndex) { _, _ in
            wheelFocus = homeIndex
            flow.advanceIfNeeded()
        }
        .onChange(of: session.loggedCount) { _, _ in
            flow.advanceIfNeeded()
        }
        .task(id: session.weight) {
            wasVisible = false
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { wasVisible = true }
            }
        }
    }

    private func isRest(_ stage: WorkoutFlow.Stage) -> Bool {
        if case .rest = stage {
            return true
        }
        return false
    }

    /// A swipe in from the left edge leaves the workout running; the landing reads "Today, going".
    private var edgeBack: some Gesture {
        DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart)).onEnded { drag in
            if drag.startLocation.x < CGFloat(GestureTuning.backEdge), drag.translation.width > 70,
               abs(drag.translation.height) < 60
            {
                model.isWorkoutPresented = false
            }
        }
    }

    @ViewBuilder
    private func screen(stage: WorkoutFlow.Stage, finished: Bool, now: Date) -> some View {
        let content = VStack(alignment: .leading, spacing: 0) {
            band(stage: stage, finished: finished, now: now)
                .frame(height: Slot.band, alignment: .topLeading)
                .padding(.top, Theme.Spacing.m)
            numberSlot(stage: stage, finished: finished, now: now)
                .frame(height: Slot.number, alignment: .leading)
            marksRow(stage: stage, finished: finished)
                .frame(height: Slot.marks)
            briefSlot(stage: stage, finished: finished, now: now)
                .frame(height: Slot.brief, alignment: .leading)
            if !typeSize.isAccessibilitySize {
                Spacer(minLength: Theme.Spacing.s)
            }
            sessionWheel
            foot(stage: stage, finished: finished, now: now)
                .frame(height: Slot.foot)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, Theme.Spacing.m)
        }
        if typeSize.isAccessibilitySize {
            ScrollView { content }.scrollIndicators(.hidden)
        } else {
            content
        }
    }

    // MARK: The band

    private func band(stage: WorkoutFlow.Stage, finished: Bool, now _: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if finished {
                FittedTitle(text: session.shownTitle, color: Theme.Colors.Accent.training)
                Text("Done").font(Theme.Training.words(17, weight: .medium)).foregroundStyle(Theme.Colors.inkSecondary)
            } else {
                switch stage {
                case .warmUp:
                    if let warm = flow.warmUp {
                        FittedTitle(text: warm.name, color: Theme.Colors.Go.green)
                        Text(warm.note)
                            .font(Theme.Training.words(17))
                            .foregroundStyle(Theme.Colors.inkSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                case .done:
                    FittedTitle(text: session.shownTitle, color: Theme.Colors.Accent.training)
                    Text(TrainingWords.doneSummary(lifts: session.entries.count, warmedUp: flow.warmUp != nil))
                        .font(Theme.Training.words(17, weight: .medium))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                case .set, .rest:
                    liftBand(stage: stage)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    /// The current lift: its name (a tap opens its page), "Set 1 of 3" and the "was 185" span.
    private func liftBand(stage: WorkoutFlow.Stage) -> some View {
        let exercise = session.currentExercise
        let name = exercise?.name ?? "Lift"
        let total = session.currentEntry.map(session.targetSets(of:)) ?? 1
        return VStack(alignment: .leading, spacing: 2) {
            Button {
                if let exercise {
                    model.open(.classDef(exercise.id))
                }
            } label: {
                FittedTitle(text: name, short: name.count > 22 ? SwapPanel.short(name) : nil,
                            color: Theme.Colors.Split.color(forName: name))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the exercise page")
            HStack(spacing: Theme.Spacing.m) {
                if case .rest = stage {
                    Text(TrainingWords.next(set: session.currentSetNumber, of: total, nextLift: flow.nextLiftName))
                        .font(Theme.Training.words(17, weight: .medium))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(TrainingWords.setOf(flow.shownSetNumber, total))
                        .font(Theme.Training.words(17, weight: .medium))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .contentTransition(.numericText())
                        .tesseraAnimation(Theme.Motion.house, value: flow.shownSetNumber)
                        .lineLimit(1)
                        .frame(width: 96, alignment: .leading)
                    wasSpan
                }
            }
            .frame(height: 24, alignment: .leading)
        }
    }

    /// "was 185", in ink 2, 2 s after a weight change. Always laid out, so it never pushes anything.
    private var wasSpan: some View {
        let was = flow.weightWasKilograms ?? session.weight
        let changed = abs(was - session.weight) > 0.01
        let text = "was \(Self.weightText(was)) \(Format.unit.symbol)"
        return MeasureLine.text(text, size: 17)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .lineLimit(1)
            .opacity(changed && wasVisible ? 1 : 0)
            .accessibilityHidden(!(changed && wasVisible))
    }

    static func weightText(_ kilograms: Double) -> String {
        let value = Format.unit.fromKilograms(kilograms)
        return value.rounded() == value ? String(Int(value)) : String(format: "%g", value)
    }

    // MARK: The big number

    @ViewBuilder
    private func numberSlot(stage: WorkoutFlow.Stage, finished: Bool, now: Date) -> some View {
        if finished {
            bigClock(Format.duration((session.finishedAt ?? now).timeIntervalSince(session.startedAt)), word: nil,
                     color: Theme.Colors.ink)
        } else {
            switch stage {
            case let .warmUp(end):
                bigClock(Format.duration(max(0, end.timeIntervalSince(now)).rounded(.up)), word: "Warm-up",
                         color: Theme.Colors.Go.green)
            case let .rest(end):
                bigClock(Format.duration(max(0, end.timeIntervalSince(now)).rounded(.up)), word: "Rest",
                         color: Theme.Colors.Go.green)
            case .done:
                bigClock(Format.duration(now.timeIntervalSince(session.startedAt)), word: nil, color: Theme.Colors.ink)
            case .set:
                weightRow
            }
        }
    }

    private func bigClock(_ text: String, word: String?, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
            Text(text)
                .font(Theme.Training.number(84, weight: .thin, relativeTo: .largeTitle))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText(countsDown: true))
                .tesseraAnimation(Theme.Motion.snappy, value: text)
            if let word {
                Text(word)
                    .font(Theme.Training.words(22, weight: .semibold, relativeTo: .title3))
                    .foregroundStyle(color)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// The weight: the number scrolls (drag it, 5 lb or 2.5 kg a step; a tap opens the dial), and the unit word beside
    /// it turns pounds and kilograms. The number, the unit and the wheel are separate hit areas.
    private var weightRow: some View {
        let pounds = Format.unit == .pounds
        let _ = flow.unitTick
        return HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
            ScrollingNumber(
                value: weightBinding,
                step: NumberScroll.weightStep(poundsUnit: pounds),
                range: 0 ... (pounds ? 1000 : 450),
                format: { value in value.rounded() == value ? String(Int(value)) : String(format: "%g", value) },
                name: "Weight",
                spokenUnit: pounds ? "pounds" : "kilograms",
                dialUnit: Format.unit.symbol,
                font: Theme.Training.number(84, weight: .thin, relativeTo: .largeTitle),
                color: Theme.Colors.Accent.training,
                width: 214
            )
            .id(Format.unit)
            Button(action: turnUnit) {
                Text(Format.unit.symbol)
                    .font(Theme.Training.words(MeasureLine.unitSize(for: 84)))
                    .foregroundStyle(Theme.Colors.Accent.training)
                    .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                    .contentTransition(.interpolate)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(DragGesture(minimumDistance: 14).onEnded { _ in turnUnit() })
            .accessibilityLabel("Unit, \(pounds ? "pounds" : "kilograms")")
            .accessibilityHint("Switches between pounds and kilograms")
        }
    }

    private var weightBinding: Binding<Double> {
        Binding(
            get: { Format.unit.fromKilograms(session.weight) },
            set: { session.weight = Format.unit.toKilograms($0) }
        )
    }

    private func turnUnit() {
        let before = "\(Self.weightText(session.weight)) \(Format.unit.symbol)"
        let snapped = session.dial?.snap(session.weight) ?? session.weight
        LiveV2.turnUnit(model: model)
        session.weight = snapped
        flow.unitTurned()
        cue.play(.selection)
        let after = "\(Self.weightText(snapped)) \(Format.unit.symbol)"
        flow.say(TrainingWords.unitReceipt(from: before, to: after))
    }
}

// MARK: - The set's flight

/// The choreography of a logged set (sheet 230): the plates lift in order 70 ms apart, a green strike draws across,
/// they
/// gather to the rep number (Outfit 200, 44 pt), the number arcs to the trail on the right and shrinks to 26 pt with a
/// small bounce, "Set 1 of 3" rolls its digit, and rest starts. Reduce Motion: the trail number simply appears.
struct SetFlight: Equatable {
    var lift = 0.0
    var strike: CGFloat = 0
    var gathered = false
    var flying = false
    var x: CGFloat = 0
    var y: CGFloat = 0
    var scale: CGFloat = 1
}
