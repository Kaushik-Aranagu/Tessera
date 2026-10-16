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
                    .environment(\.onWorkoutGround, true)
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
            // Pages pushed inside the cover are forced dark; only the root may tell the theme the appearance.
            .environment(\.tracksAppearance, false)
            // The workout keeps the look it opened in until it closes (theme-schedule.md).
            .onAppear { ThemeStore.shared.holdWorkoutLook() }
            .onDisappear { ThemeStore.shared.releaseWorkoutLook() }
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
    /// Workout-level moments: rest is up on screen, or the workout finished early.
    @State private var moment = HapticCue()
    @Environment(\.self) private var environment
    /// The subline whose cadmium has dried.
    @State private var sublineDried: String?
    @State private var undoHaptic = 0
    @State private var editHaptic = 0
    @State private var saveHaptic = 0
    @State private var revealHaptic = 0
    /// The running order sheet (pulled down from the seam).
    @State private var isOrderOpen = false
    /// The swap panel (pulled down from the exercise name).
    @State private var isSwapOpen = false
    @State private var swapOptions: [ExerciseSwaps.Option] = []
    /// "Go" rises in where the countdown was, just after a skip.
    @State private var showsGo = false
    /// The weight numeral is a field (typed in place).
    @State private var isTypingWeight = false
    /// "81 isn't loadable; 80", for 2 s after a typed weight snaps.
    @State private var snapNote: String?
    /// "DRAG RIGHT +15 · FLING LEFT TO GO" shows for the first three rests only.
    @AppStorage("restHorizonHints") private var restHintsLeft = 3
    @State private var hintedSet: UUID?
    /// A glint sweeps the numeral once when rest ends on its own.
    @State private var restEndedGlint = false
    @State private var summaryLine: String?
    /// Typing to Tess (LiveAskField) and her reply, shown in the bar for a few seconds.
    @State private var isAsking = false
    @State private var askReply: String?

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
                                // Tess's count line from Core's summary: "5 of 5 exercises, 16 sets, 1 record."
                                summaryLine = model.ledger.summary(of: session.workout).line
                                play(.done)
                            },
                            onDone: leaveFinished
                        )
                        LiveTessCorner(
                            line: WorkoutLines.tess(session, phase: phase, summary: summaryLine),
                            mode: tessMode,
                            canUndo: session.canUndo && session.finishedAt == nil,
                            onUndo: {
                                withTesseraAnimation(reduceMotion: reduceMotion) { session.undoLastSet() }
                                undoHaptic += 1
                            }
                        )
                        .padding(.leading, Theme.Spacing.gutter)
                        .padding(.trailing, 6)
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
                    moment.play(.timeUp)
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
        // The set block keeps its layout; the ask field rides on the keyboard in a short sheet.
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $isAsking) {
            LiveAskField(isShown: $isAsking, onAsk: { phrase in ask(phrase) }, onRefuse: {
                askReply = "That looks like a Claude key. It goes in Review, under Claude."
            })
            .presentationDetents([.height(84)])
            .presentationBackground(Theme.Colors.Workout.ground)
            .presentationDragIndicator(.hidden)
        }
        .background { WorkoutField() }
        // The workout stands on the look's own base, light or dark.
        .preferredColorScheme(ThemeStore.shared.workoutLook.isDark ? .dark : .light)
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
            // One haptic per set: the key's rigid impact as it lands (no second "lock" after the stroke).
            // Its haptic is the Log set key's (the set's tap, or .success for a new best).
            if seated.records.isEmpty {
                play(.done)
            } else {
                play(.thinking, then: .done, after: 1.2)
            }
        }
        .tesseraFeedback(.undo, trigger: undoHaptic)
        .tesseraFeedback(.selection, trigger: editHaptic)
        .tesseraFeedback(.setLogged, trigger: saveHaptic)
        .tesseraFeedback(.pickedUp, trigger: revealHaptic)
        .tesseraFeedback(moment)
    }

    private func live(phase actual: WorkoutSession.Phase, now: Date) -> some View {
        // Editing a logged set takes the set block over (dial, drum, key), even during rest.
        let phase = session.isEditing ? .set : actual
        return VStack(alignment: .leading, spacing: 0) {
            header(now: now)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.m)
            ExerciseLane(session: session, laneIndex: $laneIndex, isSwapOpen: isSwapOpen, setSwap: setSwap(open:))
                .padding(.top, Theme.Spacing.m)
                .overlay(alignment: .topLeading) { swapPanel }
                .zIndex(2)
            LiveSetStrokes(session: session, phase: actual) { id in
                // Tap a stroke to edit it, the same one again to leave, another to switch.
                let isSame = session.isEditing && session.editingSetID == id
                if !isSame {
                    editHaptic += 1
                }
                withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
                    if isSame {
                        session.endEditing()
                    } else {
                        session.beginEditing(setID: id)
                    }
                }
            }
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
            // The freed space (set-block.md): the plates, drawn, or the rest horizon in their place.
            platesOrRest(phase: phase, now: now)
                .padding(.horizontal, Theme.Spacing.gutter)
            Spacer(minLength: Theme.Spacing.m)
            keyRow(phase: phase)
                .padding(.horizontal, Theme.Spacing.gutter)
            LiveTessCorner(line: askReply ?? WorkoutLines.tess(session, phase: phase, summary: summaryLine),
                           mode: tessMode,
                           canUndo: session.canUndoLast && !session.isEditing,
                           holdsLine: askReply == nil && phase == .workoutDone,
                           onUndo: {
                               withTesseraAnimation(reduceMotion: reduceMotion) { session.undoLast() }
                               undoHaptic += 1
                           },
                           onOpen: { isAsking = true },
                           onHome: { model.isWorkoutPresented = false })
                .padding(.leading, Theme.Spacing.gutter)
                .padding(.trailing, 6)
                .padding(.top, Theme.Spacing.s)
        }
        .tesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.52), value: session.isEffortShown)
    }

    private func ask(_ phrase: String) {
        // Refused again before any interpreter sees it.
        guard !LiveAskField.refuses(phrase) else { return }
        play(.thinking)
        Task { @MainActor in
            let reply = await model.ask(phrase)
            askReply = reply
            play(.done)
            try? await Task.sleep(for: .seconds(4))
            if askReply == reply {
                askReply = nil
            }
        }
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
                    Theme.Colors.Workout.ground.opacity(0.6)
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
                        onClose: { setOrder(open: false) },
                        onFinish: session.summary.sets > 0 ? {
                            setOrder(open: false)
                            finish(early: true)
                        } : nil
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
        // A best lands in cadmium and dries to the context colour within 2 s (sweep-19).
        let isWet = color.resolve(in: environment) == Paint.now.resolve(in: environment)
        return Text(text)
            .font(Theme.voice)
            .foregroundStyle(isWet && sublineDried == text ? Theme.Colors.context : color)
            .tesseraAnimation(.easeInOut(duration: 0.8), value: sublineDried)
            .task(id: text) {
                guard isWet else { return }
                try? await Task.sleep(for: .seconds(1.2))
                if !Task.isCancelled {
                    sublineDried = text
                }
            }
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
                    // Tap the countdown for +15 (the one-tap twin of dragging the horizon right).
                    Button {
                        moment.play(.selection)
                        extendRest()
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(Format.duration(remaining))
                                .font(Theme.numeral(72))
                                .foregroundStyle(Paint.cream)
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
                    // Only what just happened ("+15. Drag again for more."); the how-to is the horizon's label.
                    if let note = session.restNote {
                        Text(note)
                            .font(Theme.voice)
                            .foregroundStyle(Paint.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    }
                }
                .transition(.opacity.combined(with: .blurReplace))
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    if showsGo {
                        Text("Go")
                            .font(Theme.numeral(72))
                            .foregroundStyle(Paint.cream)
                            .transition(reduceMotion ? AnyTransition.opacity
                                : AnyTransition.offset(y: 14).combined(with: AnyTransition(.blurReplace)))
                    } else if isTypingWeight, phase == .set {
                        WeightField(weight: $session.weight, detents: session.detents, unit: unit,
                                    isTyping: $isTypingWeight, onSnapped: { note in showSnap(note) })
                            .transition(.opacity)
                    } else {
                        // The numeral is the control: drag up or down, tap to type (set-block.md).
                        WeightReel(weight: $session.weight, detents: session.detents, unit: unit,
                                   isLocked: phase != .set, spokenValue: session.spokenLoad,
                                   platesPerSide: { session.dial?.platesPerSide($0) },
                                   onType: { withTesseraAnimation(reduceMotion: reduceMotion) { isTypingWeight = true }
                                   })
                                   .modifier(GlintIf(isOn: (phase == .set && session.isPersonalRecord) ||
                                           restEndedGlint))
                    }
                    if let snapNote {
                        Text(snapNote)
                            .textRole(.label)
                            .foregroundStyle(Paint.secondary)
                            .transition(.opacity)
                    }
                }
                Spacer(minLength: Theme.Spacing.s)
                VStack(alignment: .trailing, spacing: 2) {
                    RepsRow(reps: repsBinding, ghost: lastReps, isLocked: phase != .set, onBeat: {
                        // "One more than last time.", once per set, only while Tess isn't saying anything else.
                        guard askReply == nil else { return }
                        askReply = "One more than last time."
                        Task { @MainActor in
                            try? await Task.sleep(for: .seconds(4))
                            if askReply == "One more than last time." {
                                askReply = nil
                            }
                        }
                    })
                    EffortHandle(isShown: session.isEffortShown, enabled: phase == .set, setShown: setEffort(shown:))
                }
                .transition(.opacity)
            }
        }
        .frame(height: 196, alignment: .top)
        .tesseraAnimation(.easeOut(duration: 0.32), value: phase == .set)
        .tesseraAnimation(.easeOut(duration: 0.32), value: showsGo)
    }

    /// "kg", or "kg each" for dumbbells.
    private var unit: String {
        let perHand = session.currentExercise.map { ExerciseSwaps.isPerHand($0, store: model.store) } ?? false
        return perHand ? "kg each" : "kg"
    }

    /// Under the numbers: the plates drawn large, or the estimate note after a swap; during rest, the horizon.
    @ViewBuilder
    private func platesOrRest(phase: WorkoutSession.Phase, now: Date) -> some View {
        if case .rest = phase, !session.isEditing, let fraction = session.restFraction(at: now) {
            RestHorizon(fraction: fraction, showsHint: restHintsLeft > 0, onExtend: { extendRest() },
                        onSkip: { skipRest() })
                .transition(.opacity)
                .onAppear {
                    // Count a rest once, when it starts after a new set, not when it reappears after an edit.
                    let set = session.lastSeated?.setID
                    if let set, set != hintedSet {
                        hintedSet = set
                        restHintsLeft = max(restHintsLeft - 1, 0)
                    }
                }
        } else if session.isEstimatedLoad, let from = session.swappedFrom {
            Text("An estimate from \(SwapPanel.short(from).lowercased())")
                .textRole(.label)
                .foregroundStyle(Paint.tess)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let plates = session.platesPerSide {
            PlateStack(weight: session.weight, perSide: plates, drawsPlates: true, large: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
        } else {
            // Dumbbells and machines have no plates: the space stays empty.
            Color.clear.frame(height: 1)
        }
    }

    private func showSnap(_ note: String) {
        withTesseraAnimation(reduceMotion: reduceMotion) { snapNote = note }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            withTesseraAnimation(reduceMotion: reduceMotion) { snapNote = nil }
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
            if session.isEditing {
                EditSetKeys(session: session) { saveHaptic += 1 }
            } else {
                switch phase {
                case .set:
                    // Hold to log: 0.6 s, 20 pt of drift (docs/research/ship-now.md).
                    // A new best plays .success in place of the set's tap, never both (task-reward.md).
                    PaintKey(paint: Paint.live, duration: 0.6, height: 64, drift: 20,
                             completionHaptic: session.isPersonalRecord ? .newBest : .setLogged)
                    {
                        withTesseraAnimation(reduceMotion: reduceMotion) { session.logSet() }
                    } label: { _ in
                        Text("Log set")
                    } meta: {
                        Text("Hold · \(Format.kilograms(session.weight)) × \(Int(session.reps))")
                    }
                    .accessibilityLabel(logLabel)
                    .accessibilityAction(named: "Log set") {
                        withTesseraAnimation(reduceMotion: reduceMotion) { session.logSet() }
                    }
                case .rest:
                    // The horizon above carries +15 and the fling; the key only skips.
                    PaintKey(paint: Paint.now, isTap: true, height: 64) {
                        skipRest()
                    } label: { _ in
                        Text("Skip rest")
                    }
                case .exerciseDone:
                    PaintKey(paint: Paint.cobalt, isTap: true, height: 64) {
                        if let next = session.nextUnfinishedIndex {
                            withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { laneIndex = next
                            }
                        }
                    } label: { _ in
                        Text("Next exercise")
                    }
                case .workoutDone:
                    PaintKey(paint: Paint.live, duration: 0.8, height: 64, completionHaptic: .done) {
                        finish()
                    } label: { _ in
                        Text("Finish")
                    } meta: {
                        Text("Hold · \(session.summary.sets) sets")
                    }
                    .accessibilityAction(named: "Finish workout") { finish() }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 62)
    }

    // MARK: Finish

    private var sessionStrokes: [Color] {
        session.entries.flatMap { entry in session.setRows(of: entry).map { Paint.set($0.number) } }
    }

    private func finish(early: Bool = false) {
        // The Finish key plays done itself; finishing early from the order sheet plays it here.
        if early {
            moment.play(.done)
        }
        isSwapOpen = false
        isOrderOpen = false
        withTesseraAnimation(.easeOut(duration: 0.4), reduceMotion: reduceMotion) { session.finish(early: early) }
    }

    /// The workout is already finished (FinishWorkout ran on the hold); leaving drops it into today on Home.
    private func leaveFinished() {
        model.isWorkoutPresented = false
        model.session = nil
        model.touch()
    }
}
