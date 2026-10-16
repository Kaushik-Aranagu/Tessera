import SwiftUI
import TesseraCore

/// TRAINING is the workout at rest (docs/design/training-mode.md): the strip unlit, the plan as lanes with their sets
/// as guides, and the START mark. Starting is the page waking: the mark's ink line lifts into the strip and lights
/// the first segment, then live mode rises.
struct TrainingPage: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let _ = model.revision
        // One view for every state, so START's flight and the sinking plan survive the switch to running.
        if let source {
            TrainingAtRest(plan: source)
        } else {
            EmptyTraining()
        }
    }

    private var source: TrainingSource? {
        if let session = model.session {
            // Running (or paused under Home): the plan with what's done, RESUME.
            return .running(session)
        }
        if let workout = model.tonightWorkout() {
            return .scheduled(workout)
        }
        if let routine = model.todaysRoutine() {
            return .routine(routine)
        }
        return model.finishedToday().first.map { .done($0) }
    }
}

// MARK: - The page

/// What the page is drawn from.
enum TrainingSource {
    case routine(ObjectRecord)
    case scheduled(ObjectRecord)
    case running(WorkoutSession)
    case done(WorkoutSummary)
}

/// One exercise of the plan as a lane: the name, the target at the right and one stroke per set.
struct TrainingLane: Identifiable, Equatable {
    let id: UUID
    let exercise: ClassDef?
    let name: String
    let target: String
    let sets: Int
    /// The set numbers already logged (drawn as dried strokes in their pigments).
    let logged: Int
}

private struct TrainingAtRest: View {
    let plan: TrainingSource
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.zoomNamespace) private var namespace

    /// The START tap's flight: 0 at the word, 1 landed in the strip.
    @State private var lift: CGFloat = 0
    @State private var isLifting = false
    @State private var landed = false
    @State private var liftTaps = 0
    @State private var markLine: CGRect = .zero
    @State private var firstSegment: CGRect = .zero
    /// The START sequence, cancelled if he leaves the page inside it.
    @State private var startTask: Task<Void, Never>?
    /// As live mode rises out of the first lane, the rest of the plan sinks to 0.96 and fades.
    @State private var sinking = false

    private static let space = "training"

    var body: some View {
        let lanes = lanes
        VStack(alignment: .leading, spacing: 0) {
            TrainingStrip(sets: lanes.map(\.sets), state: stripState(lanes))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frame in
                    let total = max(lanes.map(\.sets).reduce(0, +), 1)
                    let spacing = 4 * CGFloat(max(lanes.count - 1, 0))
                    let width = (frame.width - spacing) * CGFloat(lanes.first?.sets ?? 0) / CGFloat(total)
                    firstSegment = CGRect(x: frame.minX, y: frame.minY, width: width, height: frame.height)
                }
                .padding(.bottom, Theme.Spacing.l)

            Text(context(lanes))
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
                .contentTransition(.opacity)
                .padding(.bottom, Theme.Spacing.s)
                .entrance(0)

            titleButton
                .padding(.bottom, Theme.Spacing.l)
                .entrance(1, hero: true)

            StartMark(state: markState, lift: lift)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frame in
                    markLine = CGRect(x: frame.minX, y: frame.maxY - 6, width: frame.width, height: 6)
                }
                .onTapGesture { tapMark() }
                .accessibilityAddTraits(markState.isAction ? .isButton : [])
                .accessibilityAction { tapMark() }
                .padding(.bottom, Theme.Spacing.xl)
                .entrance(2)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lanes.prefix(5).enumerated()), id: \.element.id) { index, lane in
                    LaneRow(lane: lane, wakes: landed && index == 0, dried: isDone)
                        .frame(height: 72, alignment: .top)
                        // Live mode rises out of the first lane; the others sink away.
                        .modifier(ZoomSource(id: index == 0 ? WorkoutRise.sourceID : "lane-\(lane.id)",
                                             namespace: namespace))
                        .modifier(Sinking(isOn: sinking && index > 0))
                }
            }
            .accessibilityElement(children: .contain)
            .entrance(3)

            Spacer(minLength: Theme.Spacing.m)

            Group {
                planLine
                    .entrance(4)

                // Tess's slot keeps two lines' height with or without a line, so the plan line never moves.
                ZStack(alignment: .topLeading) {
                    Text(verbatim: "Tess\nTess")
                        .font(Theme.voice(size: 21))
                        .hidden()
                        .accessibilityHidden(true)
                    if let line = tessLine(lanes) {
                        Text(line)
                            .font(Theme.voice(size: 21))
                            .foregroundStyle(Theme.Colors.tess)
                            .fixedSize(horizontal: false, vertical: true)
                            .contentTransition(.opacity)
                            .transition(.opacity)
                    }
                }
                .padding(.top, Theme.Spacing.m)
                .entrance(5)
            }
            .modifier(Sinking(isOn: sinking))
        }
        .coordinateSpace(.named(Self.space))
        .overlay(alignment: .topLeading) {
            // The line in flight, from under the word up into the strip.
            if isLifting {
                LiftingLine(from: markLine, target: firstSegment, progress: lift)
                    .allowsHitTesting(false)
            }
        }
        .tesseraFeedback(.made, trigger: liftTaps)
        .onDisappear {
            // Leaving mid-START: stop it and put the page back whole. Not when the workout cover is what hid the
            // page (the sunk lanes would come back mid-zoom); the cover's close puts it back instead.
            startTask?.cancel()
            startTask = nil
            guard !model.isWorkoutPresented else { return }
            sinking = false
            landed = false
            isLifting = false
            lift = 0
        }
        .onChange(of: model.isWorkoutPresented) { _, presented in
            guard !presented else { return }
            // Back from live mode: the page is whole again.
            sinking = false
            model.workoutRisesFromLane = false
        }
    }

    // MARK: Parts

    @ViewBuilder
    private var titleButton: some View {
        let (title, route) = titleAndRoute
        Button { model.open(route) } label: {
            Text(title)
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: route, namespace: namespace))
        .accessibilityHint("Opens \(title)")
    }

    private var titleAndRoute: (String, Route) {
        switch plan {
        case let .routine(routine): (routine.title, .object(routine.id))
        case let .scheduled(workout): (workout.title, .object(workout.id))
        case let .running(session): (session.workout.title, .object(session.workout.id))
        case let .done(summary): ("\(summary.title) done", .object(summary.workout.id))
        }
    }

    /// "PUSH PULL LEGS, ROLLS ON" and ROUTINES.
    @ViewBuilder
    private var planLine: some View {
        if let planObject = model.plan {
            HStack(alignment: .firstTextBaseline) {
                let fixed = PlanSchedule.mode(of: planObject, store: model.store) == .fixed
                Text("\(planObject.title), \(fixed ? "fixed days" : "rolls on")")
                    .textRole(.label)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: Theme.Spacing.s)
                Button("Routines") { model.open(.routines(planObject.id)) }
                    .buttonStyle(InkLabelWordStyle())
            }
        }
    }

    // MARK: State

    private var isDone: Bool {
        if case .done = plan {
            return true
        }
        return false
    }

    private var markState: StartMark.State {
        switch plan {
        case let .routine(routine):
            if landed {
                return .running
            }
            return model.canStart(routine) ? .ready("Start \(routine.title)") : .label("Add an exercise to start")
        case let .scheduled(workout):
            return landed ? .running : .ready("Start \(workout.title)")
        case let .running(session):
            let total = session.entries.reduce(0) { $0 + session.targetSets(of: $1) }
            let done = session.entries.reduce(0) { $0 + session.setRows(of: $1).count }
            return .paused("Resume \(session.workout.title)", total > 0 ? Double(done) / Double(total) : 0)
        case .done:
            return .label(tomorrowLine)
        }
    }

    /// What tomorrow holds, from the same rest-day reading Now and Review use, so they never disagree: "Rest day
    /// tomorrow", else the routine the plan lands on ("Pull A tomorrow").
    private var tomorrowLine: String {
        let plan = model.plan
        let tomorrow = TesseraDay().day(1, after: AppClock.now).addingTimeInterval(12 * 3600)
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        if NowPicker(engine: model.engine).restDay(plan: plan, at: tomorrow, sessionsPerWeek: perWeek) != nil {
            return "Rest day tomorrow"
        }
        guard let next = plan.flatMap({ model.ledger.nextRoutine(in: $0, now: tomorrow) }) else {
            return "Done for today"
        }
        return "\(next.title) tomorrow"
    }

    private func stripState(_ lanes: [TrainingLane]) -> [TrainingStrip.Segment] {
        switch plan {
        case .routine, .scheduled:
            lanes.indices.map { $0 == 0 && landed ? .lit : .unlit }
        case let .running(session):
            lanes.indices.map { index in
                index < session.currentIndex ? .done : index == session.currentIndex ? .lit : .unlit
            }
        case .done:
            lanes.map { _ in .done }
        }
    }

    private var lanes: [TrainingLane] {
        switch plan {
        case let .routine(routine):
            routine.orderedChildren.compactMap(slotLane)
        case let .scheduled(workout):
            workout.orderedChildren.compactMap { entryLane($0, logged: 0) }
        case let .running(session):
            session.entries.compactMap { entryLane($0, logged: session.setRows(of: $0).count) }
        case let .done(summary):
            summary.workout.orderedChildren.compactMap { entry in
                let logged = entry.orderedChildren.count { model.store.number("reps", of: $0) != nil }
                return entryLane(entry, logged: logged, sets: logged)
            }
        }
    }

    private func slotLane(_ slot: ObjectRecord) -> TrainingLane? {
        guard let exercise = model.store.linkedClass("exercise", of: slot) else { return nil }
        let sets = Int(model.store.number("sets", of: slot) ?? 3)
        let last = model.ledger.sessions(of: exercise).first?.sets.first
        let target = last.map { "\(Format.kilograms($0.weight)) × \(Int($0.reps.rounded()))" }
            ?? TrainingPage.scheme(sets: Double(sets), repMin: model.store.number("repMin", of: slot),
                                   repMax: model.store.number("repMax", of: slot))
        return TrainingLane(id: slot.id, exercise: exercise, name: exercise.name, target: target, sets: sets,
                            logged: 0)
    }

    private func entryLane(_ entry: ObjectRecord, logged: Int, sets: Int? = nil) -> TrainingLane? {
        guard let exercise = model.store.linkedClass("exercise", of: entry) else { return nil }
        let planned = Int(model.store.number("targetSets", of: entry) ?? 3)
        let prefill = model.ledger.prefill(for: entry)
        let target = prefill.weight.map { "\(Format.kilograms($0)) × \(prefill.reps)" }
            ?? TrainingPage.target(sets: Double(planned), reps: model.store.number("targetReps", of: entry))
        return TrainingLane(id: entry.id, exercise: exercise, name: exercise.name, target: target,
                            sets: max(sets ?? planned, logged, 1), logged: logged)
    }

    /// "today, 5 exercises, about 55 min"; done: "done this afternoon".
    private func context(_ lanes: [TrainingLane]) -> String {
        if case let .done(summary) = plan {
            guard let end = summary.endedAt else { return "done today" }
            return "done this \(SpokenTime.partOfDay(end))"
        }
        if case .running = plan {
            return "running now"
        }
        let count = lanes.count
        let sets = lanes.map(\.sets).reduce(0, +)
        return "today, \(count) \(count == 1 ? "exercise" : "exercises"), \(TrainingPage.about(sets: sets))"
    }

    private func tessLine(_ lanes: [TrainingLane]) -> String? {
        if landed, let first = lanes.first {
            return "\(titleAndRoute.0) running. \(first.name) first."
        }
        switch plan {
        case let .routine(routine):
            guard let slot = routine.orderedChildren.first,
                  let exercise = model.store.linkedClass("exercise", of: slot) else { return nil }
            guard model.ledger.sessions(of: exercise).first?.sets.first != nil else {
                return "First time on \(exercise.name.lowercased()). Start light."
            }
            // The target is last time's: nothing to say (56 addendum).
            return nil
        case let .scheduled(workout):
            guard let entry = workout.orderedChildren.first,
                  let exercise = model.store.linkedClass("exercise", of: entry) else { return nil }
            let prefill = model.ledger.prefill(for: entry)
            if prefill.isFirstTime {
                return "First time on \(exercise.name.lowercased()). Start light."
            }
            // Only when the plan moved the target (progression); the same as last time is silence.
            guard prefill.source == .target, let weight = prefill.weight, weight > 0 else { return nil }
            return "\(exercise.name) is ready for \(Format.kilograms(weight)) today."
        case .running:
            return nil
        case let .done(summary):
            return summary.line
        }
    }

    // MARK: Start

    private func tapMark() {
        switch markState {
        case .ready:
            guard !isLifting, startTask == nil else { return }
            liftTaps += 1
            // Reduce Motion: nothing flies, so nothing waits; live mode crossfades in.
            guard !reduceMotion else {
                start()
                return
            }
            isLifting = true
            lift = 0
            // The house curve over 520 ms.
            withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.52), reduceMotion: reduceMotion) {
                lift = 1
            }
            startTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(520))
                guard !Task.isCancelled else { return reset() }
                withTesseraAnimation(.easeOut(duration: 0.24), reduceMotion: reduceMotion) {
                    landed = true
                    isLifting = false
                }
                // The page has woken: the plan starts to sink, and live mode rises out of the first lane.
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return reset() }
                withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.48), reduceMotion: reduceMotion) {
                    sinking = true
                }
                try? await Task.sleep(for: .milliseconds(160))
                guard !Task.isCancelled else { return reset() }
                start()
            }
        case .paused:
            model.isWorkoutPresented = true
        case .running, .label:
            break
        }
    }

    private func start() {
        model.workoutRisesFromLane = !reduceMotion
        switch plan {
        case let .routine(routine): model.startRoutine(routine)
        case let .scheduled(workout): model.startWorkout(workout)
        case .running, .done: model.isWorkoutPresented = true
        }
        reset()
    }

    private func reset() {
        if startTask?.isCancelled == true {
            sinking = false
        }
        landed = false
        isLifting = false
        lift = 0
        startTask = nil
    }
}

/// The source the workout cover zooms out of when START wakes the page.
enum WorkoutRise {
    static let sourceID = "training-first-lane"
}

/// The rest of the plan sinking away under the rising workout: 0.96 and transparent.
private struct Sinking: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isOn ? 0.96 : 1)
            .opacity(isOn ? 0 : 1)
    }
}

// MARK: - The strip

/// The live workout's strip before it runs: one 3 pt segment per exercise, its length its sets, 4 pt apart.
struct TrainingStrip: View {
    enum Segment: Equatable {
        case unlit, lit, done
    }

    let sets: [Int]
    let state: [Segment]

    var body: some View {
        GeometryReader { proxy in
            let total = CGFloat(max(sets.reduce(0, +), 1))
            let spacing = 4 * CGFloat(max(sets.count - 1, 0))
            HStack(spacing: 4) {
                ForEach(sets.indices, id: \.self) { index in
                    let width = (proxy.size.width - spacing) * CGFloat(sets[index]) / total
                    segment(index < state.count ? state[index] : .unlit)
                        .frame(width: max(width, 0))
                }
            }
        }
        .frame(height: 3)
        .tesseraAnimation(.easeOut(duration: 0.42), value: state)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func segment(_ kind: Segment) -> some View {
        switch kind {
        case .unlit:
            Theme.Colors.ink.opacity(0.14)
        case .done:
            Theme.Colors.ink.opacity(0.72)
        case .lit:
            Theme.Colors.live
                .shadow(color: Theme.Colors.live.opacity(ThemeStore.shared.paintLook.isDark ? 0.8 : 0), radius: 5)
        }
    }
}

/// The ink line in flight: it narrows from the word's width to the first segment's and wets from ink to `live`.
private struct LiftingLine: View, Animatable {
    let from: CGRect
    let target: CGRect
    var progress: CGFloat

    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let x = from.minX + (target.minX - from.minX) * progress
        let y = from.midY + (target.midY - from.midY) * progress
        let width = from.width + (target.width - from.width) * progress
        let height = 4 - progress
        ZStack {
            InkLine(thickness: height).fill(Theme.Colors.ink).opacity(1 - Double(progress))
            InkLine(thickness: height).fill(Theme.Colors.live).opacity(Double(progress))
        }
        .frame(width: max(width, 1), height: 6)
        .shadow(color: Theme.Colors.live.opacity(ThemeStore.shared.paintLook.isDark ? 0.6 * progress : 0),
                radius: 5)
        .position(x: x + width / 2, y: y)
    }
}

// MARK: - The Start mark

/// The ink-line label word that starts training (replaces the paint stroke): the line is what changes state.
struct StartMark: View {
    enum State: Equatable {
        case ready(String)
        case running
        case paused(String, Double)
        case label(String)

        var isAction: Bool {
            switch self {
            case .ready, .paused: true
            case .running, .label: false
            }
        }
    }

    let state: State
    /// The START flight: the word fades to 35% while the line leaves it.
    var lift: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word)
                .textRole(.labelStrong)
                .textCase(.uppercase)
                .foregroundStyle(Theme.Colors.ink.opacity(wordOpacity))
                .contentTransition(.opacity)
            line
        }
        .fixedSize()
        .frame(minHeight: 44, alignment: .bottom)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(word.capitalized)
    }

    private var word: String {
        switch state {
        case let .ready(word), let .paused(word, _), let .label(word): word
        case .running: "Pause"
        }
    }

    private var wordOpacity: Double {
        switch state {
        case .ready: 1 - 0.65 * Double(lift)
        case .label: 0.72
        case .running, .paused: 1
        }
    }

    @ViewBuilder
    private var line: some View {
        switch state {
        case .ready:
            // The flight draws the moving copy; the line here empties as it leaves.
            InkLine().fill(Theme.Colors.ink).opacity(lift > 0 ? 0 : 1).frame(height: 6)
        case .running:
            InkLine().fill(Theme.Colors.ink).frame(width: 28, height: 6)
        case let .paused(_, done):
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    InkLine().fill(Theme.Colors.ink.opacity(0.22))
                    InkLine().fill(Theme.Colors.ink).frame(width: proxy.size.width * min(max(done, 0), 1))
                }
            }
            .frame(height: 6)
        case .label:
            Color.clear.frame(height: 6)
        }
    }
}

// MARK: - Lanes

/// One exercise: the name, its target at the right and one stroke per set at 48 pt pitch; future sets are the live
/// page's dashed guides at 22%, logged sets their pigment dried to the rest tint.
private struct LaneRow: View {
    let lane: TrainingLane
    /// The first guide wakes when START lands: 22% to 90%, breathing.
    var wakes = false
    var dried = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(lane.name)
                    .font(Theme.voice(size: 21).weight(.medium))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.s)
                Text(lane.target)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                ForEach(0 ..< lane.sets, id: \.self) { index in
                    stroke(index)
                        .frame(width: 40, height: 12)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(lane.name), \(lane.target), \(lane.sets) \(lane.sets == 1 ? "set" : "sets")")
    }

    @ViewBuilder
    private func stroke(_ index: Int) -> some View {
        if index < lane.logged {
            Brushstroke()
                .stroke(Theme.Colors.restTint(WorkoutPaint.set(index + 1)),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
        } else if wakes, index == lane.logged {
            TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { context in
                let breath = (sin(context.date.timeIntervalSinceReferenceDate / 2.4 * 2 * .pi) + 1) / 2
                guide.opacity(reduceMotion ? 0.9 : 0.6 + 0.3 * breath)
            }
            .transition(.opacity)
        } else {
            guide.opacity(dried ? 0.12 : 0.22)
        }
    }

    private var guide: some View {
        Brushstroke()
            .stroke(Theme.Colors.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 5]))
    }
}

// MARK: - Words

extension TrainingPage {
    /// "4 × 5–8"; a single rep count when the range is one number.
    static func scheme(sets: Double?, repMin: Double?, repMax: Double?) -> String {
        let sets = Int(sets ?? 3)
        let low = Int(repMin ?? repMax ?? 8), high = Int(repMax ?? repMin ?? 8)
        return low == high ? "\(sets) × \(low)" : "\(sets) × \(low)–\(high)"
    }

    /// "4 × 8"; with a weight, "4 × 8 · 82.5".
    static func target(sets: Double?, reps: Double?, weight: Double? = nil) -> String {
        let scheme = "\(Int(sets ?? 0)) × \(Int(reps ?? 0))"
        guard let weight, weight > 0 else { return scheme }
        return "\(scheme) · \(Format.kilograms(weight))"
    }

    /// "about 55 min": each set about two and a half minutes with its rest, to the nearest five.
    static func about(sets: Int) -> String {
        let minutes = max(5, Int((Double(sets) * 2.5 / 5).rounded()) * 5)
        return minutes >= 60 && minutes % 60 == 0 ? "about \(minutes / 60) h" : "about \(minutes) min"
    }
}

/// One specific line and one way forward.
private struct EmptyTraining: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            Text("nothing on the plan today")
                .font(Theme.voice(size: 21))
                .foregroundStyle(Theme.Colors.context)
            Text("A rest day. It counts too.")
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .siblingParallax()
            if let exercise = model.classDef(.exercise) {
                Button {
                    model.open(.classDef(exercise.id), .jump)
                } label: {
                    Text("Browse exercises →")
                        .textRole(.bodyStrong)
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(HandleButtonStyle())
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
