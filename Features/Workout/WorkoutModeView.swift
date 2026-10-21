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
    /// The corner soul runs the same router as Home's, with page .live (tess-motion.md §14).
    @State private var soul = SoulRouter(page: .live)
    /// Workout-level moments: a set seated, a new best, rest up on screen, the workout finished.
    @State private var moment = HapticCue()
    /// The set's haptic, held until its circle closes (played at once under Reduce Motion or Low Power).
    @State private var deferredCues: [Haptic] = []
    @Environment(\.lowPowerMotion) private var lowPower
    @Environment(\.dynamicTypeSize) private var typeSize
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
                            title: session.shownTitle,
                            startedAt: session.startedAt,
                            endedAt: finished,
                            summary: session.summary,
                            onGathered: {
                                // A take-back inside the gather leaves nothing to sum up.
                                guard session.finishedAt != nil else { return }
                                // Tess's count line from Core's summary: "Push Day A done, 5 of 5 exercises."
                                summaryLine = model.ledger.summary(of: session.workout).doneLine(in: model.store)
                                soul.handle(.workoutGathered)
                            },
                            onDone: leaveFinished
                        )
                        LiveTessCorner(
                            line: WorkoutLines.tess(session, phase: phase, summary: summaryLine),
                            mode: soul.mode,
                            // LOG … AND FINISH keeps a 10 s UNDO that takes back the set and the finish together.
                            canUndo: session.canTakeBackFinish(at: now),
                            eyes: model.tessHasEyes, wear: soul.wear(at:),
                            // The line (and its UNDO) stays for the whole 10 s window.
                            holdsLine: session.canTakeBackFinish(at: now),
                            onUndo: {
                                withTesseraAnimation(reduceMotion: reduceMotion) { session.takeBackFinish() }
                                let back = "\(session.shownTitle), back on."
                                askReply = back
                                undoHaptic += 1
                                Task { @MainActor in
                                    try? await Task.sleep(for: .seconds(4))
                                    if askReply == back {
                                        askReply = nil
                                    }
                                }
                            }
                        )
                        .padding(.leading, Theme.Spacing.gutter)
                        .padding(.trailing, 6)
                        .padding(.top, Theme.Spacing.l)
                    }
                    .transition(.opacity)
                } else {
                    live(phase: phase, now: now)
                        .simultaneousGesture(edgeBack)
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
                askReply = claudeKeyLine
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
        .onAppear {
            laneIndex = session.currentIndex
            // The workout can finish here: warm the done pattern so its first beat isn't late.
            DonePattern.prepare()
            #if DEBUG
                // `-workoutNearEnd` (simulator only, recordings): every set but the workout's last is logged.
                if LaunchFlags.has("-workoutNearEnd"), session.setRows(of: session.entries[0]).isEmpty {
                    let all = session.entries
                    for (index, entry) in all.enumerated() {
                        session.select(entryAt: index)
                        let keep = index == all.count - 1 ? 1 : 0
                        while session.setRows(of: entry).count < session.targetSets(of: entry) - keep {
                            session.logSet()
                            session.skipRest()
                        }
                    }
                    laneIndex = session.currentIndex
                }
            #endif
        }
        .onChange(of: laneIndex) { _, index in
            guard let index, index != session.currentIndex else { return }
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { session.select(entryAt: index) }
        }
        .onChange(of: session.currentIndex) { _, index in
            guard laneIndex != index else { return }
            withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { laneIndex = index }
        }
        .onChange(of: session.lastSeated) { _, seated in
            // A set that finished the workout plays its haptic in finish(), once.
            guard let seated, session.finishedAt == nil else { return }
            // One haptic per set, played here so it survives the key leaving (Reduce Motion, VoiceOver's action):
            // the set's tap, or .success in its place for a new best.
            // With the ink drops the one haptic waits for the circle to close (LiveSetMarks tells us); without them
            // (Reduce Motion, Low Power) it plays now.
            // A private workout never announces a best: the same plain tap for every set.
            let isPrivate = session.shownTitle != session.workout.title
            let cue: Haptic = seated.records.isEmpty || isPrivate ? .setLogged : .newBest
            if reduceMotion || lowPower {
                moment.play(cue)
            } else {
                deferredCues.append(cue)
            }
            soul.handle(seated.records.isEmpty || isPrivate ? .setLogged : .newBest)
        }
        .tesseraFeedback(.undo, trigger: undoHaptic)
        .tesseraFeedback(.selection, trigger: editHaptic)
        .tesseraFeedback(.setLogged, trigger: saveHaptic)
        .tesseraFeedback(.pickedUp, trigger: revealHaptic)
        .tesseraFeedback(moment)
    }

    /// At accessibility sizes the screen is taller than the phone: it scrolls instead of printing rows over each other.
    @ViewBuilder
    private func live(phase actual: WorkoutSession.Phase, now: Date) -> some View {
        if typeSize.isAccessibilitySize {
            ScrollView {
                liveStack(phase: actual, now: now)
            }
            .scrollIndicators(.hidden)
        } else {
            liveStack(phase: actual, now: now)
        }
    }

    private func liveStack(phase actual: WorkoutSession.Phase, now: Date) -> some View {
        // Editing a logged set takes the set block over (dial, drum, key), even during rest.
        let phase = session.isEditing ? .set : actual
        return VStack(alignment: .leading, spacing: 0) {
            header(phase: phase)
                .padding(.horizontal, Theme.Spacing.gutter)
                .padding(.top, Theme.Spacing.m)
            ExerciseLane(session: session, laneIndex: $laneIndex, isSwapOpen: isSwapOpen, setSwap: setSwap(open:))
                .padding(.top, Theme.Spacing.m)
                .overlay(alignment: .topLeading) { swapPanel }
                .overlay(alignment: .bottomLeading) { oneTapSwapWord }
                .zIndex(2)
            LiveSetMarks(session: session, phase: actual, onEdit: { id in
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
            }, onClosed: { _ in
                if !deferredCues.isEmpty {
                    moment.play(deferredCues.removeFirst())
                }
            }, onCancelled: {
                // The set was undone before its circle closed: its haptic goes with it.
                if !deferredCues.isEmpty {
                    deferredCues.removeLast()
                }
            })
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
                           mode: soul.mode,
                           canUndo: session.canUndoLast && !session.isEditing,
                           eyes: model.tessHasEyes, wear: soul.wear(at:),
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
        soul.handle(.liveAsk)
        Task { @MainActor in
            let reply = await model.ask(phrase)
            askReply = reply
            soul.handle(.liveAnswered)
            try? await Task.sleep(for: .seconds(4))
            if askReply == reply {
                askReply = nil
            }
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

    /// The context line above the name (live-workout.md): "Push A, set 1 of 4", "Rest, then set 2". No count: the
    /// strip says which exercise this is. Tap or pull down for the running order.
    private func header(phase: WorkoutSession.Phase) -> some View {
        let line = WorkoutLines.context(session, phase: phase)
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Spacing.m) { backWord; contextLine(line) }
            VStack(alignment: .leading, spacing: 0) { backWord; contextLine(line) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A swipe in from the left edge leaves the same way Back does.
    private var edgeBack: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { drag in
            if drag.startLocation.x < 24, drag.translation.width > 70, abs(drag.translation.height) < 60 {
                model.isWorkoutPresented = false
            }
        }
    }

    /// The way out is always at the top left: the session keeps running and the key on Home reads RESUME.
    /// Ending the workout stays a separate, deliberate action.
    private var backWord: some View {
        Button { model.isWorkoutPresented = false } label: {
            Text("Back")
                .textRole(.label)
                .foregroundStyle(Paint.secondary)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to Training")
        .accessibilityHint("The workout keeps running")
    }

    private func contextLine(_ line: String) -> some View {
        Group {
            Text(line)
                .font(Theme.voice)
                .foregroundStyle(Theme.Colors.context)
                .contentTransition(.opacity)
                .tesseraAnimation(value: line)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { setOrder(open: true) }
                .gesture(DragGesture(minimumDistance: 12).onEnded { drag in
                    if drag.translation.height > 30 {
                        setOrder(open: true)
                    }
                })
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Shows the running order")
        }
    }

    @ViewBuilder
    private var swapPanel: some View {
        if isSwapOpen {
            SwapPanel(options: swapOptions, current: session.currentExercise?.name ?? "This") { option in
                setSwap(open: false)
                withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.5), reduceMotion: reduceMotion) {
                    session.swap(to: option)
                }
                soul.handle(.swapped)
            }
            .padding(.horizontal, Theme.Spacing.s)
            .offset(y: 64 + Theme.Spacing.m)
            .transition(reduceMotion ? AnyTransition.opacity
                : .asymmetric(insertion: AnyTransition.offset(y: -16).combined(with: AnyTransition(.blurReplace)),
                              removal: .opacity))
        }
    }

    /// The easy swap (switch "One tap"): a small Swap word under the name applies the top alternative at once, with a
    /// 10 s UNDO; the full list is still one pull-down away. Session-only, and the load converts like the panel's.
    @ViewBuilder
    private var oneTapSwapWord: some View {
        if Choice.swapIsOneTap(), !isSwapOpen, session.finishedAt == nil, !session.isEditing,
           let entry = session.currentEntry, session.setRows(of: entry).isEmpty
        {
            Button("Swap", action: oneTapSwap)
                .buttonStyle(.labelWord(Paint.secondary))
                .padding(.leading, Theme.Spacing.gutter)
                .offset(y: 22)
                .accessibilityHint("Swaps this exercise for the closest alternative, with undo")
        }
    }

    private func oneTapSwap() {
        guard let top = session.swapOptions().first else {
            TessVoice.shared.say("Nothing to swap this for.")
            return
        }
        var record: OpRecord?
        withTesseraAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.5), reduceMotion: reduceMotion) {
            record = session.swap(to: top)
        }
        soul.handle(.swapped)
        guard let record else { return }
        let name = SwapPanel.short(top.exercise.name)
        TessVoice.shared.say("\(name), swapped in.", holds: .seconds(10), takeBack: { [session] in
            withTesseraAnimation(reduceMotion: reduceMotion) { session.undoSwap(record) }
        })
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
        let (text, color, isWet) = WorkoutLines.subline(session, phase: phase)
        // A best lands in cadmium and dries to the context colour within 2 s (sweep-19).
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
            .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            .minimumScaleFactor(0.8)
            .contentTransition(.opacity)
            .tesseraAnimation(value: text)
    }

    private func numberRow(phase: WorkoutSession.Phase, now: Date) -> some View {
        // At accessibility sizes the weight and the reps stack, so the row is never wider than the screen.
        let large = typeSize.isAccessibilitySize
        let layout = large ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.m))
            : AnyLayout(HStackLayout(alignment: .top))
        return layout {
            if case let .rest(end) = phase {
                let remaining = max(0, end.timeIntervalSince(now)).rounded(.up)
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    // Tap the countdown for +15 (the one-tap twin of dragging the horizon right).
                    Button {
                        moment.play(.selection)
                        extendRest()
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            // The countdown is the one thing in colour at rest, and it moves (live-workout.md §7).
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
                if !large {
                    Spacer(minLength: Theme.Spacing.s)
                }
                VStack(alignment: large ? .leading : .trailing, spacing: 2) {
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
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(minHeight: 196, maxHeight: large ? nil : 196, alignment: .top)
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
        } else if let plates = session.platesPerSide, !typeSize.isAccessibilitySize {
            // (Large text has no room for the drawing: it would print over the reps.)
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
                    soul.handle(.topSetAccepted)
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
        // `Int(Double)` traps on NaN, infinity or a huge value, so both reads go through the safe conversion.
        let logged = session.setRows(of: entry).last.flatMap { RecipeLimits.whole($0.reps) }
        return logged ?? session.lastTimeReps.flatMap(RecipeLimits.whole)
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
        // At accessibility sizes the key and PAUSE stack, so the row is never wider than the screen.
        let large = typeSize.isAccessibilitySize
        let layout = large ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.s))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.l))
        return layout {
            if session.isEditing {
                EditSetKeys(session: session) { saveHaptic += 1 }
            } else {
                switch phase {
                case .set:
                    // The key says what it logs (live-workout.md): "LOG 82.5 × 8", a 0.7 s hold on the ink line; the
                    // workout's last set logs and finishes in one hold. Silent: the set's haptic plays when it seats.
                    let finishes = session.isLastSetOfWorkout
                    PaintKey(paint: Paint.live, duration: 0.7, height: 64, drift: 20, isSilent: true,
                             hint: finishes ? "Logs the set and finishes the workout" : "Logs the set")
                    {
                        withTesseraAnimation(reduceMotion: reduceMotion) { session.logSet() }
                        if finishes {
                            finish(withSet: true)
                        }
                    } label: { _ in
                        Text(
                            "Log \(Format.kilograms(session.weight))\u{00A0}×\u{00A0}\(Int(session.reps))\(finishes ? " and finish" : "")"
                        )
                        .textRole(.labelStrong)
                        .textCase(.uppercase)
                        .contentTransition(.numericText())
                    } meta: {
                        EmptyView()
                    }
                    .accessibilityLabel(logLabel)
                    .accessibilityAction(named: "Log set") {
                        withTesseraAnimation(reduceMotion: reduceMotion) { session.logSet() }
                        if finishes {
                            finish(withSet: true)
                        }
                    }
                case .rest:
                    // The horizon above carries +15 and the fling; the key only skips.
                    PaintKey(paint: Paint.now, isTap: true, height: 64) {
                        skipRest()
                    } label: { _ in
                        Text("Skip rest").textRole(.labelStrong).textCase(.uppercase)
                    }
                case .exerciseDone:
                    PaintKey(paint: Paint.cobalt, isTap: true, height: 64) {
                        if let next = session.nextUnfinishedIndex {
                            withTesseraAnimation(.snappy(duration: 0.3), reduceMotion: reduceMotion) { laneIndex = next
                            }
                        }
                    } label: { _ in
                        Text("Next exercise").textRole(.labelStrong).textCase(.uppercase)
                    }
                case .workoutDone:
                    PaintKey(paint: Paint.live, duration: 0.8, height: 64, isSilent: true,
                             hint: "Finishes the workout")
                    {
                        finish()
                    } label: { _ in
                        Text("Finish").textRole(.labelStrong).textCase(.uppercase)
                    } meta: {
                        EmptyView()
                    }
                    .accessibilityAction(named: "Finish workout") { finish() }
                }
            }
            if !large {
                Spacer(minLength: 0)
            }
            if session.finishedAt == nil {
                // PAUSE leaves to Home, where the key reads RESUME with the progress line.
                Button("Pause") { model.isWorkoutPresented = false }
                    .textRole(.labelStrong)
                    .textCase(.uppercase)
                    .foregroundStyle(Paint.secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pause the workout")
            }
        }
        .frame(height: large ? nil : 62)
    }

    // MARK: Finish

    private var sessionStrokes: [Color] {
        session.entries.flatMap { entry in session.setRows(of: entry).map { Paint.set($0.number) } }
    }

    /// One haptic for the moment: done, or .success when the set it finished with was a best.
    private func finish(early: Bool = false, withSet: Bool = false) {
        let isPrivate = session.shownTitle != session.workout.title
        let best = withSet && !isPrivate && session.lastSeated?.records.isEmpty == false
        moment.play(best ? .newBest : .done)
        isSwapOpen = false
        isOrderOpen = false
        withTesseraAnimation(.easeOut(duration: 0.4), reduceMotion: reduceMotion) {
            session.finish(early: early, withSet: withSet)
        }
    }

    /// The workout is already finished (FinishWorkout ran on the hold); leaving drops it into today on Home.
    private func leaveFinished() {
        model.isWorkoutPresented = false
        model.session = nil
        model.touch()
    }
}
