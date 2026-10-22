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
    /// "4 × 5–8": the plan's scheme; the second line at rest.
    var scheme = ""
    /// Today's weight with its unit ("82.5 kg"); none when there is no weight yet.
    var weight: String?
    /// The same weight in kilograms (stored), so the row can draw it as a measure with a swipeable unit.
    var weightKilograms: Double?
    /// What the exercise works, for the lane's figure.
    var muscles: [(name: String, role: MuscleRole)] = []
    /// The sets logged so far as ink-drop marks (the circles that replace the dashed strokes).
    var marks: [SetMarkSpec] = []

    static func == (lhs: TrainingLane, rhs: TrainingLane) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.weightKilograms == rhs.weightKilograms && lhs.target == rhs
            .target && lhs.sets == rhs.sets
            && lhs.logged == rhs.logged && lhs.scheme == rhs.scheme && lhs.weight == rhs.weight && lhs.marks == rhs
            .marks
    }
}

private struct TrainingAtRest: View {
    let plan: TrainingSource
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.zoomNamespace) private var namespace
    @Environment(\.dynamicTypeSize) private var typeSize

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
        let day = MuscleReading.union(lanes.map(\.muscles))
        // The works line adds two lines under the name; the page's spacing tightens by what it adds so the bar word
        // above never moves.
        let tight = worksLine(day) != nil
        VStack(alignment: .leading, spacing: 0) {
            TrainingStrip(sets: lanes.map(\.sets), state: stripState(lanes))
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frame in
                    let total = max(lanes.map(\.sets).reduce(0, +), 1)
                    let spacing = 4 * CGFloat(max(lanes.count - 1, 0))
                    let width = (frame.width - spacing) * CGFloat(lanes.first?.sets ?? 0) / CGFloat(total)
                    firstSegment = CGRect(x: frame.minX, y: frame.minY, width: width, height: frame.height)
                }
                .padding(.bottom, tight ? Theme.Spacing.m : Theme.Spacing.l)

            LandingSentenceView(sentence: sentence(lanes), opens: { model.open(titleAndRoute.1) })
                .contentTransition(.opacity)
                .padding(.bottom, tight ? Theme.Spacing.xs : Theme.Spacing.s)
                .modifier(ZoomSource(id: titleAndRoute.1, namespace: namespace))
                .entrance(1, hero: true)

            // A private workout says nothing about what it works (its figure still draws).
            if let works = worksLine(day) {
                Text(works)
                    .font(Theme.voice(size: 21))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 220, alignment: .leading)
                    .padding(.bottom, Theme.Spacing.s)
            }

            StartMark(state: markState, lift: lift)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frame in
                    markLine = CGRect(x: frame.minX, y: frame.maxY - 6, width: frame.width, height: 6)
                }
                .onTapGesture { tapMark() }
                .accessibilityAddTraits(markState.isAction ? .isButton : [])
                .accessibilityAction { tapMark() }
                .padding(.bottom, Theme.Spacing.m)
                .entrance(2)

            // The lanes are the page's one bounded window: they take the room the week and the doors leave.
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lanes.prefix(5).enumerated()), id: \.element.id) { index, lane in
                        LaneRow(lane: lane, wakes: landed && index == 0, dried: isDone,
                                isPrivate: isPrivateDay,
                                showsStrokes: isRunning || isDone || lane.logged > 0)
                            // Rows are 72 pt; at large text a row grows with its wrapped name instead of printing over
                            // the next one.
                            .frame(height: typeSize.isAccessibilitySize ? nil : 72, alignment: .top)
                            // Live mode rises out of the first lane; the others sink away.
                            .modifier(ZoomSource(id: index == 0 ? WorkoutRise.sourceID : "lane-\(lane.id)",
                                                 namespace: namespace))
                            .modifier(Sinking(isOn: sinking && index > 0))
                    }
                }
                .accessibilityElement(children: .contain)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: typeSize.isAccessibilitySize ? nil : .infinity, alignment: .top)
            .entrance(3)

            TrainingWeekMarks(dots: TrainingWeek.dots(model, now: AppClock.now, hasSessionToday: hasSessionToday))
                .padding(.vertical, Theme.Spacing.s)
                .modifier(Sinking(isOn: sinking))

            TrainingDoors(doors: doors)
                .modifier(Sinking(isOn: sinking))

            Group {
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
                .padding(.top, tight ? Theme.Spacing.xs : Theme.Spacing.m)
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

    /// "Works chest, shoulders and triceps" (the day's primary muscles); none for a private workout or when nothing
    /// is stored.
    private func worksLine(_ day: MuscleReading.Muscles) -> String? {
        guard !isPrivateDay, !typeSize.isAccessibilitySize else { return nil }
        let primary = day.filter { $0.role == .primary }.map(\.name)
        return primary.isEmpty ? nil : MuscleWords.works(primary)
    }

    private var isPrivateDay: Bool {
        titleAndRoute.0 == ObjectPrivacy.routineLabel
    }

    @ViewBuilder
    private var titleButton: some View {
        let (title, route) = titleAndRoute
        Button { model.open(route) } label: {
            Text(title)
                .textRole(.title)
                .foregroundStyle(Theme.Colors.ink)
                // The day's name wraps to a second line and, if that is still too long, scales a little: never "...".
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(HandleButtonStyle())
        .modifier(ZoomSource(id: route, namespace: namespace))
        .accessibilityHint("Opens \(title)")
    }

    /// A routine or workout's name as Training shows it: "Private workout" when private (G274).
    private func shown(_ title: String) -> String {
        ObjectPrivacy.routineTitle(title, in: model.store)
    }

    private var titleAndRoute: (String, Route) {
        switch plan {
        case let .routine(routine): (shown(routine.title), .object(routine.id))
        case let .scheduled(workout): (shown(workout.title), .object(workout.id))
        case let .running(session): (shown(session.workout.title), .object(session.workout.id))
        case let .done(summary): ("\(shown(summary.title)) done", .object(summary.workout.id))
        }
    }

    // MARK: State

    private var isDone: Bool {
        if case .done = plan {
            return true
        }
        return false
    }

    /// A session still to do (or running) today: the week's today mark stays open.
    private var hasSessionToday: Bool {
        if case .done = plan {
            return false
        }
        return true
    }

    private var isRunning: Bool {
        if case .running = plan {
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
            return model
                .canStart(routine) ? .ready("Start \(shown(routine.title))") : .label("Add an exercise to start")
        case let .scheduled(workout):
            return landed ? .running : .ready("Start \(shown(workout.title))")
        case let .running(session):
            let total = session.entries.reduce(0) { $0 + session.targetSets(of: $1) }
            let done = session.entries.reduce(0) { $0 + session.setRows(of: $1).count }
            return .paused("Resume \(shown(session.workout.title))", total > 0 ? Double(done) / Double(total) : 0)
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
        return "\(shown(next.title)) tomorrow"
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
        let scheme = TrainingPage.scheme(sets: Double(sets), repMin: model.store.number("repMin", of: slot),
                                         repMax: model.store.number("repMax", of: slot))
        let target = last.map { "\(Format.mass($0.weight)) × \(Int($0.reps.rounded()))" } ?? scheme
        return TrainingLane(id: slot.id, exercise: exercise, name: exercise.name, target: target, sets: sets,
                            logged: 0, scheme: scheme, weight: last.map { Self.weightText($0.weight) },
                            weightKilograms: last?.weight,
                            muscles: MuscleReading.muscles(of: exercise, store: model.store))
    }

    private func entryLane(_ entry: ObjectRecord, logged: Int, sets: Int? = nil) -> TrainingLane? {
        guard let exercise = model.store.linkedClass("exercise", of: entry) else { return nil }
        let planned = Int(model.store.number("targetSets", of: entry) ?? 3)
        let prefill = model.ledger.prefill(for: entry)
        let scheme = TrainingPage.target(sets: Double(planned), reps: model.store.number("targetReps", of: entry))
        let target = prefill.weight.map { "\(Format.mass($0)) × \(prefill.reps)" } ?? scheme
        return TrainingLane(id: entry.id, exercise: exercise, name: exercise.name, target: target,
                            sets: max(sets ?? planned, logged, 1), logged: logged,
                            scheme: scheme,
                            weight: prefill.weight.map { Self.weightText($0) },
                            weightKilograms: prefill.weight,
                            muscles: MuscleReading.muscles(of: exercise, store: model.store),
                            marks: marks(of: entry))
    }

    /// The entry's logged sets as marks (target reps from the entry; a best from the running session).
    private func marks(of entry: ObjectRecord) -> [SetMarkSpec] {
        let rows = entry.orderedChildren.compactMap { set -> (UUID, Double, Double)? in
            guard let weight = model.store.number("weight", of: set), let reps = model.store.number("reps", of: set)
            else { return nil }
            return (set.id, weight, reps)
        }
        guard !rows.isEmpty else { return [] }
        let target = Int(model.store.number("targetReps", of: entry) ?? 8)
        let heaviest = rows.map(\.1).max() ?? 0
        let bests = Set(model.session?.bests.map(\.setID) ?? [])
        return rows.enumerated().map { index, row in
            SetMarkSpec(id: row.0, number: index + 1, reps: Int(row.2.rounded()), target: target, weight: row.1,
                        heaviest: heaviest, isBest: bests.contains(row.0), isPrivate: isPrivateDay)
        }
    }

    /// "82.5 kg": a weight with its unit.
    private static func weightText(_ value: Double) -> String {
        Format.mass(value)
    }

    /// The page's sentence: Core's template for a day still to do; a running or finished workout says so.
    private func sentence(_ lanes: [TrainingLane]) -> SentenceParts {
        let title = titleAndRoute.0
        switch plan {
        case .running:
            return SentenceParts(text: "\(title) is running.", key: title)
        case let .done(summary):
            let when = summary.endedAt.map { TrainingPage.doneWhen($0) } ?? "done today"
            return SentenceParts(text: "\(shown(summary.title)) \(when).", key: shown(summary.title))
        case .routine, .scheduled:
            let sets = lanes.map(\.sets).reduce(0, +)
            // A private workout names no lift and no weight.
            let opener = isPrivateDay ? nil : lanes.first.flatMap { lane in
                lane.weightKilograms.map { (exercise: lane.name, weight: Format.mass($0)) }
            }
            return TrainingPage.sentence(
                session: title,
                minutes: sets > 0 ? TrainingPage.estimatedMinutes(sets: sets) : nil,
                opener: opener
            )
        }
    }

    /// Plan, Library and Log as ink words with a short value each. The Plan word keeps "fixed days" or "rolls on".
    private var doors: [TrainingDoor] {
        var doors: [TrainingDoor] = []
        if let planObject = model.plan {
            let fixed = PlanSchedule.mode(of: planObject, store: model.store) == .fixed
            doors.append(TrainingDoor(id: "plan", word: "Plan",
                                      value: "\(planObject.title), \(fixed ? "fixed days" : "rolls on")",
                                      route: .routines(planObject.id)))
        }
        if let exercise = model.classDef(.exercise) {
            let count = ExerciseLibraryList.groups(model).reduce(0) { $0 + $1.exercises.count }
            doors.append(TrainingDoor(id: "library", word: "Library",
                                      value: count > 0 ? "\(count) \(count == 1 ? "exercise" : "exercises")" : nil,
                                      route: .classDef(exercise.id)))
        }
        if let workout = model.classDef(.workout) {
            let done = TrainingWeek.doneThisWeek(model, now: AppClock.now)
            doors.append(TrainingDoor(id: "log", word: "Log", value: done > 0 ? "\(done) this week" : nil,
                                      route: .classDef(workout.id)))
        }
        return doors
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
            // Only from the plan's own target (raised by progression, or a weight set in the plan); opening at last
            // time's weight is silence.
            guard prefill.source == .target, let weight = prefill.weight, weight > 0 else { return nil }
            return "\(exercise.name) is ready for \(Format.mass(weight)) today."
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
            InkLine(thickness: height).fill(Theme.Colors.live).opacity(1 - Double(progress))
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
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word)
                .textRole(.bodyStrong)
                .foregroundStyle(Theme.Colors.ink.opacity(wordOpacity))
                .contentTransition(.opacity)
            line
        }
        // At large text the key wraps to a second line instead of running off the screen.
        .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: true)
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
            InkLine().fill(Theme.Colors.live).opacity(lift > 0 ? 0 : 1).frame(height: 6)
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

/// One exercise (Design brief 1, sheet 107; Kaushik, Oct 20: no figure beside the name): the
/// name (21 medium, one line, top 6) and under it, at top 38, the scheme ("4 × 5–8") with today's weight at
/// the right edge ("82.5 kg", none when there is none). Once the workout is running the second line is the set
/// strokes live mode draws: logged ones painted in the rest tint, the rest dashed guides. No lines between rows
/// (Kaushik, Oct 20).
private struct LaneRow: View {
    let lane: TrainingLane
    /// The first guide wakes when START lands: 22% to 90%, breathing.
    var wakes = false
    var dried = false
    /// A private workout names no muscles.
    var isPrivate = false
    var showsStrokes = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(lane.name)
                    .font(Theme.voice(size: 21).weight(.medium))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                    .fixedSize(horizontal: false, vertical: typeSize.isAccessibilitySize)
                    .padding(.top, 6)
                secondLine
                    .padding(.top, typeSize.isAccessibilitySize ? 4 : 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var secondLine: some View {
        if showsStrokes {
            HStack(spacing: 8) {
                ForEach(0 ..< lane.sets, id: \.self) { index in
                    stroke(index)
                        .frame(width: 26, height: 22)
                }
            }
            .frame(height: 24, alignment: .leading)
        } else {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 0))
            layout {
                Text(lane.scheme)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .monospacedDigit()
                if !typeSize.isAccessibilitySize {
                    Spacer(minLength: Theme.Spacing.s)
                }
                if let kilograms = lane.weightKilograms {
                    MeasureView(measure: Measure(kilograms, "kg"), controls: [.unit])
                } else if let weight = lane.weight {
                    Text(weight)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                        .monospacedDigit()
                }
            }
        }
    }

    private var label: String {
        let works = isPrivate ? "" : MuscleReading.spoken(lane.muscles)
        let sets = "\(lane.sets) \(lane.sets == 1 ? "set" : "sets")"
        return ([lane.name, lane.target, sets] + (works.isEmpty ? [] : [works])).joined(separator: ", ")
    }

    /// A logged set is its brush circle (22 pt); the ones to come are faint rings, the next one breathing when START
    /// has landed.
    @ViewBuilder
    private func stroke(_ index: Int) -> some View {
        if index < lane.marks.count {
            SetMarkCircle(spec: lane.marks[index], side: 22)
        } else if wakes, index == lane.marks.count {
            TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { context in
                let breath = (sin(context.date.timeIntervalSinceReferenceDate / 2.4 * 2 * .pi) + 1) / 2
                ring.opacity(reduceMotion ? 0.9 : 0.6 + 0.3 * breath)
            }
            .transition(.opacity)
        } else {
            ring.opacity(dried ? 0.12 : 0.22)
        }
    }

    private var ring: some View {
        Circle().stroke(Theme.Colors.ink, lineWidth: 1.4).frame(width: 16, height: 16)
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
        return "\(scheme) · \(Format.mass(weight))"
    }

    /// "about 55 min": each set about two and a half minutes with its rest, to the nearest five.
    /// "5 exercises, about 40 min".
    static func planPhrase(lanes: [TrainingLane]) -> String {
        let count = lanes.count
        let sets = lanes.map(\.sets).reduce(0, +)
        return "\(count) \(count == 1 ? "exercise" : "exercises"), \(about(sets: sets))"
    }

    static func about(sets: Int) -> String {
        "about \(HouseTime.minutes(estimatedMinutes(sets: sets)))"
    }

    /// The finished workout's context word (docs/research/time-words-sweep.md TW5; decisions 12:35 PM PT Oct 16):
    /// "done early this morning" from 4 to 7 am, "done tonight" from 9 pm to the 4 am edge, never "this night".
    static func doneWhen(_ end: Date, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: end) {
        case 4 ..< 7: "done early this morning"
        case 7 ..< 12: "done this morning"
        case 12 ..< 17: "done this afternoon"
        case 17 ..< 21: "done this evening"
        default: "done tonight"
        }
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

private extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
