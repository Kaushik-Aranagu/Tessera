import SwiftUI
import TesseraCore

/// Live workout, a foreground process (it rises as a full-screen cover). One screen, three axes:
/// x = the exercises of the session (a paged lane; the next name peeks in), y = the sets of the current exercise
/// (seated sets stack above, the dialled set sits at eye level, the remaining one waits below), z = tap the exercise
/// name to zoom into its page. The set block changes role: after a set is seated, the weight numeral and the dial
/// become the rest countdown, so nothing new appears.
///
/// Round 6 "Plein air" (docs/design/workout-v1.md): dark painterly ground, one exercise, one number, one action.
struct WorkoutModeView: View {
    @Environment(AppModel.self) private var model
    @Namespace private var zoom

    var body: some View {
        @Bindable var model = model
        if let session = model.session {
            NavigationStack(path: $model.workoutPath) {
                WorkoutContent(session: session)
                    .toolbarVisibility(.hidden, for: .navigationBar)
                    .navigationDestination(for: Route.self) { route in
                        ObjectPage(route: route)
                            .environment(\.animateEntrance, model.consumeFirstVisit(route))
                            .modifier(ArrivalTransition(
                                id: route,
                                arrival: model.arrivals[route] ?? .crossFade,
                                namespace: zoom
                            ))
                    }
            }
            .environment(\.zoomNamespace, zoom)
        } else {
            Color.clear.onAppear { model.isWorkoutPresented = false }
        }
    }
}

private typealias Paint = WorkoutPaint

private struct WorkoutContent: View {
    @Bindable var session: WorkoutSession
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The lane's scroll position (x). Kept in step with `session.currentIndex` both ways.
    @State private var laneIndex: Int?
    @State private var tessMode: TessSoul.Mode = .idle
    @State private var lockHaptic = 0
    @State private var celebrated = 0
    @State private var undoHaptic = 0
    @State private var revealHaptic = 0
    /// The running order sheet (pulled down from the seam).
    @State private var isOrderOpen = false
    /// The swap panel (pulled down from the exercise name).
    @State private var isSwapOpen = false
    @State private var swapOptions: [ExerciseSwaps.Option] = []
    /// "Go" rises in where the countdown was, just after a skip.
    @State private var showsGo = false
    /// A glint sweeps the numeral once when rest ends on its own.
    @State private var restEndedGlint = false
    @State private var summaryLine: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = AppClock.adjust(context.date)
            let phase = session.phase(at: now)
            Group {
                if let finished = session.finishedAt {
                    VStack(spacing: 0) {
                        WorkoutFinishView(
                            strokes: sessionStrokes,
                            title: session.workout.title,
                            startedAt: session.startedAt,
                            endedAt: finished,
                            summary: session.summary,
                            onGathered: {
                                summaryLine = session.summary.line
                                play(.done)
                            },
                            onDone: leaveFinished
                        )
                        WorkoutTessBar(
                            line: WorkoutLines.tess(session, phase: phase, summary: summaryLine),
                            mode: tessMode,
                            canUndo: session.canUndo && session.finishedAt == nil
                        ) {
                            withTesseraAnimation(reduceMotion: reduceMotion) { session.undoLastSet() }
                            undoHaptic += 1
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, Theme.Spacing.l)
                    }
                    .transition(.opacity)
                } else {
                    live(phase: phase, now: now)
                }
            }
            .onChange(of: phase == .set) { wasSet, isSet in
                // Rest ran out on its own (not skipped or undone): the next set rises already prefilled and one
                // glint sweeps the numeral.
                if isSet, !wasSet, let end = session.restEndsAt, end <= now {
                    restEndedGlint = true
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1.2))
                        restEndedGlint = false
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            ExerciseStrip(segments: segments)
                .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .top) { runningOrder }
        .background { PleinGround() }
        .preferredColorScheme(.dark)
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .bottom)
        .onAppear { laneIndex = session.currentIndex }
        .onChange(of: laneIndex) { _, index in
            guard let index, index != session.currentIndex else { return }
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { session.select(entryAt: index) }
        }
        .onChange(of: session.currentIndex) { _, index in
            guard laneIndex != index else { return }
            withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { laneIndex = index }
        }
        .onChange(of: session.lastSeated) { _, seated in
            guard let seated else { return }
            Task { @MainActor in
                // The key lands the set (rigid); it locks (success) once its stroke has painted in.
                try? await Task.sleep(for: .milliseconds(700))
                lockHaptic += 1
            }
            if seated.records.isEmpty {
                play(.done)
            } else {
                celebrated += 1
                play(.thinking, then: .done, after: 1.2)
            }
        }
        .sensoryFeedback(.success, trigger: lockHaptic)
        .sensoryFeedback(.decrease, trigger: undoHaptic)
        .sensoryFeedback(.impact(weight: .light), trigger: revealHaptic)
    }

    private func live(phase: WorkoutSession.Phase, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(now: now)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.m)
            ExerciseLane(session: session, laneIndex: $laneIndex, isSwapOpen: isSwapOpen, setSwap: setSwap(open:))
                .padding(.top, Theme.Spacing.m)
                .overlay(alignment: .topLeading) { swapPanel }
                .zIndex(2)
            LiveSetStrokes(session: session, phase: phase)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.l)
                .opacity(isSwapOpen ? 0 : 1)
            subline(phase: phase)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.m)
                .opacity(isSwapOpen ? 0 : 1)
            numberRow(phase: phase, now: now)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.l)
            Spacer(minLength: Theme.Spacing.s)
            setArea(phase: phase)
                .padding(.horizontal, Theme.Spacing.gutter)
            Spacer(minLength: Theme.Spacing.s)
            WeightDial(
                weight: $session.weight,
                detents: session.detents,
                isLocked: phase != .set,
                restFraction: session.restFraction(at: now),
                onExtendRest: { extendRest() },
                onSkipRest: { skipRest() }
            )
            .padding(.horizontal, 20)
            Spacer(minLength: Theme.Spacing.m)
            keyRow(phase: phase)
                .padding(.horizontal, Theme.Spacing.gutter)
            WorkoutTessBar(line: WorkoutLines.tess(session, phase: phase, summary: summaryLine), mode: tessMode,
                           canUndo: session.canUndo && session.finishedAt == nil)
            {
                withTesseraAnimation(reduceMotion: reduceMotion) { session.undoLastSet() }
                undoHaptic += 1
            }
            .padding(.horizontal, 14)
            .padding(.top, Theme.Spacing.l)
        }
        .tesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.52), value: session.isEffortShown)
    }

    private func play(_ mode: TessSoul.Mode, then next: TessSoul.Mode? = nil, after delay: Double = 0) {
        tessMode = mode
        Task { @MainActor in
            if let next {
                try? await Task.sleep(for: .seconds(delay))
                tessMode = next
            }
            try? await Task.sleep(for: .seconds(1.8))
            tessMode = .idle
        }
    }
}

extension WorkoutContent {
    // MARK: The strip and the running order

    private var segments: [ExerciseStrip.Segment] {
        let entries = session.entries
        if session.finishedAt != nil {
            return entries.map { _ in .done }
        }
        return entries.enumerated().map { index, entry in
            if index == session.currentIndex {
                return .current
            }
            return session.isFinished(entry) ? .done : .remaining
        }
    }

    @ViewBuilder
    private var runningOrder: some View {
        if isOrderOpen {
            GeometryReader { proxy in
                ZStack(alignment: .top) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { setOrder(open: false) }
                        .accessibilityLabel("Close running order")
                        .accessibilityAddTraits(.isButton)
                    RunningOrderSheet(
                        session: session,
                        topInset: proxy.safeAreaInsets.top,
                        onSelect: { index in
                            setOrder(open: false)
                            withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) {
                                laneIndex = index
                            }
                        },
                        onClose: { setOrder(open: false) }
                    )
                    .ignoresSafeArea(edges: .top)
                    .transition(reduceMotion ? .opacity : .move(edge: .top))
                }
            }
            .transition(.opacity)
        }
    }

    private func setOrder(open: Bool) {
        if open {
            revealHaptic += 1
            isSwapOpen = false
        }
        withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.46), reduceMotion: reduceMotion) {
            isOrderOpen = open
        }
    }

    // MARK: Header and lane (x)

    private func header(now: Date) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(session.workout.title), \(Format.duration(now.timeIntervalSince(session.startedAt)))")
                .font(Theme.voice)
                .foregroundStyle(Paint.secondary)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                // Pull down on the seam (or tap it) for the running order.
                .onTapGesture { setOrder(open: true) }
                .gesture(DragGesture(minimumDistance: 12).onEnded { drag in
                    if drag.translation.height > 30 {
                        setOrder(open: true)
                    }
                })
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Shows the running order")
            Text("\((laneIndex ?? session.currentIndex) + 1) / \(session.entries.count)")
                .textRole(.label)
                .foregroundStyle(Paint.secondary)
            Button {
                model.isWorkoutPresented = false
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Paint.cream)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Minimise workout")
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var swapPanel: some View {
        if isSwapOpen {
            SwapPanel(options: swapOptions, current: session.currentExercise?.name ?? "This") { option in
                setSwap(open: false)
                withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.5), reduceMotion: reduceMotion) {
                    session.swap(to: option)
                }
                play(.done)
            }
            .padding(.horizontal, Theme.Spacing.s)
            .offset(y: 64 + Theme.Spacing.m)
            .transition(reduceMotion ? AnyTransition.opacity
                : .asymmetric(insertion: AnyTransition.offset(y: -16).combined(with: AnyTransition(.blurReplace)),
                              removal: .opacity))
        }
    }

    private func setSwap(open: Bool) {
        if open {
            swapOptions = session.swapOptions()
            revealHaptic += 1
        }
        withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.42), reduceMotion: reduceMotion) {
            isSwapOpen = open
        }
    }

    // MARK: y, in words and numbers

    private func subline(phase: WorkoutSession.Phase) -> some View {
        let (text, color) = WorkoutLines.subline(session, phase: phase)
        return Text(text)
            .font(Theme.voice)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .contentTransition(.opacity)
            .tesseraAnimation(value: text)
    }

    private func numberRow(phase: WorkoutSession.Phase, now: Date) -> some View {
        HStack(alignment: .top) {
            if case let .rest(end) = phase {
                let remaining = max(0, end.timeIntervalSince(now)).rounded(.up)
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    // Tap the countdown for +15 (the one-tap twin of dragging the dial right).
                    Button { extendRest() } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(Format.duration(remaining))
                                .font(Theme.numeral(72))
                                .foregroundStyle(Paint.now)
                                .contentTransition(.numericText(countsDown: true))
                                .animation(MotionPolicy.resolve(Theme.Motion.snappy, reduceMotion: reduceMotion),
                                           value: remaining)
                            Text("rest").font(Theme.voice).foregroundStyle(Paint.secondary)
                        }
                        .frame(minHeight: 60)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Rest, \(Int(remaining)) seconds left")
                    .accessibilityHint("Adds 15 seconds")
                    Text(session.restNote ?? "Tap or drag the dial right for 15 more. Fling it left to go.")
                        .font(Theme.voice)
                        .foregroundStyle(Paint.tess)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                        .tesseraAnimation(value: session.restNote)
                }
                .transition(.opacity.combined(with: .blurReplace))
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    if showsGo {
                        Text("Go")
                            .font(Theme.numeral(72))
                            .foregroundStyle(Paint.now)
                            .transition(reduceMotion ? AnyTransition.opacity
                                : AnyTransition.offset(y: 14).combined(with: AnyTransition(.blurReplace)))
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(Format.kilograms(session.weight))
                                .font(Theme.numeral(72))
                                .foregroundStyle(Paint.cream)
                                .contentTransition(.numericText(value: session.weight))
                                .animation(MotionPolicy.resolve(Theme.Motion.snappy, reduceMotion: reduceMotion),
                                           value: session.weight)
                                .modifier(GlintIf(isOn: (phase == .set && session.isPersonalRecord)
                                        || restEndedGlint))
                            Text(unit).font(Theme.voice).foregroundStyle(Paint.secondary)
                        }
                        .accessibilityHidden(true)
                    }
                    plateLine
                }
                Spacer(minLength: Theme.Spacing.s)
                VStack(spacing: 2) {
                    RepsDrum(reps: repsBinding, ghost: lastReps)
                        .disabled(phase != .set)
                    EffortHandle(isShown: session.isEffortShown, enabled: phase == .set, setShown: setEffort(shown:))
                }
                .transition(.opacity)
            }
        }
        .frame(height: 196, alignment: .top)
        .tesseraAnimation(.easeOut(duration: 0.32), value: phase == .set)
        .tesseraAnimation(.easeOut(duration: 0.32), value: showsGo)
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: celebrated)
    }

    /// "kg", or "kg each" for dumbbells.
    private var unit: String {
        let perHand = session.currentExercise.map { ExerciseSwaps.isPerHand($0, store: model.store) } ?? false
        return perHand ? "kg each" : "kg"
    }

    @ViewBuilder
    private var plateLine: some View {
        if session.isEstimatedLoad, let from = session.swappedFrom {
            Text("An estimate from \(SwapPanel.short(from).lowercased())")
                .textRole(.label)
                .foregroundStyle(Paint.tess)
        } else if let load = session.plateLoad {
            PlateStack(weight: session.weight, bar: load.bar, perSide: session.platesPerSide)
        }
    }

    private func setEffort(shown: Bool) {
        guard shown != session.isEffortShown else { return }
        revealHaptic += 1
        withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.52), reduceMotion: reduceMotion) {
            session.isEffortShown = shown
        }
    }

    /// Between the plate maths and the dial: the effort slider when pulled out, and the top-set check.
    private func setArea(phase: WorkoutSession.Phase) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            if session.isEffortShown, phase == .set {
                RPEStops(rpe: $session.rpe)
                    .transition(.revealLeading(reduceMotion: reduceMotion))
            }
            if let check = session.topSetCheck, check.entryID == session.currentEntry?.id {
                TopSetCheckLine(check: check) {
                    withTesseraAnimation(reduceMotion: reduceMotion) { session.acceptTopSetCheck() }
                    play(.done)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var repsBinding: Binding<Int> {
        Binding(get: { Int(session.reps) }, set: { session.reps = Double($0) })
    }

    private var lastReps: Int? {
        guard let entry = session.currentEntry else { return nil }
        return session.setRows(of: entry).last.map { Int($0.reps) } ?? session.lastTimeReps.map(Int.init)
    }
}

extension WorkoutContent {
    private var logLabel: String {
        let weight = Format.kilograms(session.weight)
        return "Hold to log set \(session.currentSetNumber), \(weight) kilograms for \(Int(session.reps)) reps"
    }

    // MARK: Rest

    private func extendRest() {
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { session.extendRest(by: 15) }
    }

    private func skipRest() {
        withTesseraAnimation(.easeOut(duration: 0.32), reduceMotion: reduceMotion) {
            session.skipRest()
            showsGo = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            withTesseraAnimation(.easeOut(duration: 0.32), reduceMotion: reduceMotion) { showsGo = false }
        }
    }

    // MARK: The key

    private func keyRow(phase: WorkoutSession.Phase) -> some View {
        HStack(spacing: Theme.Spacing.l) {
            switch phase {
            case .set:
                // Hold to log: 0.6 s, 20 pt of drift (docs/research/ship-now.md).
                PaintKey(finish: .cream, paint: Paint.live, duration: 0.6, height: 62, drift: 20) {
                    withTesseraAnimation(reduceMotion: reduceMotion) { session.logSet() }
                } label: { holding in
                    Text(holding ? "Keep holding" : "Hold to log").textRole(.bodyStrong)
                }
                .frame(width: 240)
                .accessibilityLabel(logLabel)
                .accessibilityAction(named: "Log set") {
                    withTesseraAnimation(reduceMotion: reduceMotion) { session.logSet() }
                }
                Text("\(Format.kilograms(session.weight)) × \(Int(session.reps))")
                    .textRole(.label)
                    .foregroundStyle(Paint.cream)
            case .rest:
                PaintKey(finish: .cream, paint: Paint.now, isTap: true, height: 62) {
                    skipRest()
                } label: { _ in
                    Text("Skip rest").textRole(.bodyStrong)
                }
                .frame(width: 240)
            case .exerciseDone:
                PaintKey(finish: .cream, paint: Paint.cobalt, isTap: true, height: 62) {
                    if let next = session.nextUnfinishedIndex {
                        withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { laneIndex = next }
                    }
                } label: { _ in
                    Text("Next exercise").textRole(.bodyStrong)
                }
                .frame(width: 240)
            case .workoutDone:
                PaintKey(finish: .cream, paint: Paint.live, duration: 0.8, height: 62) {
                    finish()
                } label: { holding in
                    Text(holding ? "Keep holding" : "Hold to finish").textRole(.bodyStrong)
                }
                .frame(width: 240)
                .accessibilityAction(named: "Finish workout") { finish() }
                Text("\(session.summary.sets) sets")
                    .textRole(.label)
                    .foregroundStyle(Paint.cream)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 62)
    }

    // MARK: Finish

    private var sessionStrokes: [Color] {
        session.entries.flatMap { entry in session.setRows(of: entry).map { Paint.set($0.number) } }
    }

    private func finish() {
        isSwapOpen = false
        isOrderOpen = false
        withTesseraAnimation(.easeOut(duration: 0.4), reduceMotion: reduceMotion) { session.finish() }
    }

    /// The workout is already finished (FinishWorkout ran on the hold); leaving drops it into today on Home.
    private func leaveFinished() {
        model.isWorkoutPresented = false
        model.session = nil
        model.touch()
    }
}
