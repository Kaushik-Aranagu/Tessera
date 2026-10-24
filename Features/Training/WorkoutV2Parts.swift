import SwiftUI
import TesseraCore

// MARK: - The stacks and the trail

extension WorkoutV2 {
    /// The current lift's stacks on the left, one per planned set, and the trail of what was done on the right ("5 5").
    @ViewBuilder
    func marksRow(stage: WorkoutFlow.Stage, finished: Bool) -> some View {
        let rows = flow.rows()
        let current = rows.first { $0.state == .current } ?? rows.first
        if finished || current == nil || !showsMarks(stage) {
            Color.clear
        } else if let lift = current {
            let moment = flow.moment?.entryID == lift.id ? flow.moment : nil
            let trail = moment == nil ? lift.doneReps : Array(lift.doneReps.dropLast())
            ZStack(alignment: .bottomLeading) {
                HStack(alignment: .bottom, spacing: Theme.Spacing.m) {
                    stacks(lift, moment: moment)
                    Spacer(minLength: Theme.Spacing.m)
                    Text(TrainingWords.trail(trail))
                        .font(Theme.Training.number(26, weight: .light))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                        .frame(height: 32)
                }
                if moment != nil {
                    flying(moment)
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottomLeading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
            .task(id: moment?.id) { await fly(moment, in: lift) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(markSpeech(lift))
        } else {
            Color.clear
        }
    }

    private func showsMarks(_ stage: WorkoutFlow.Stage) -> Bool {
        switch stage {
        case .set, .rest: true
        case .warmUp, .done: false
        }
    }

    private func markSpeech(_ lift: LiftRow) -> String {
        let done = lift.doneReps.isEmpty ? "no sets yet" : lift.doneReps.map(TrainingWords.reps).joined(separator: ", ")
        return "\(lift.name), \(lift.sets) sets planned, \(done)"
    }

    private func stacks(_ lift: LiftRow, moment: WorkoutFlow.Moment?) -> some View {
        HStack(alignment: .bottom, spacing: StackMarkGeometry.gap) {
            ForEach(Array(lift.marks.enumerated()), id: \.offset) { index, mark in
                let inFlight = moment.map { $0.number - 1 == index } ?? false
                StackMark(spec: mark, lift: inFlight ? flight.lift : nil)
                    .opacity(inFlight && flight.gathered ? 0 : 1)
                    .scaleEffect(inFlight && flight.gathered ? 0.4 : 1)
                    .overlay {
                        // The green strike draws across the stack as it fills.
                        if inFlight {
                            Rectangle()
                                .fill(Theme.Colors.Go.green)
                                .frame(height: StackMarkGeometry.Stroke.lifted)
                                .scaleEffect(x: flight.strike, anchor: .leading)
                                .padding(.horizontal, -3)
                        }
                    }
            }
        }
        .frame(height: StackMarkGeometry.focus.height, alignment: .bottom)
    }

    /// The rep number in the air: Outfit 200 at 44 pt where the stack was, then on its way to the trail at 26 pt.
    @ViewBuilder
    private func flying(_ moment: WorkoutFlow.Moment?) -> some View {
        if let moment, flight.gathered {
            Text("\(moment.reps)")
                .font(Theme.Training.number(44, weight: .thin))
                .foregroundStyle(Theme.Colors.Go.green)
                .scaleEffect(flight.scale)
                .position(x: flight.x, y: flight.y)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// Runs the choreography for one logged set, then lets the screen move on (the set count rolls, rest shows).
    func fly(_ moment: WorkoutFlow.Moment?, in _: LiftRow) async {
        guard let moment else {
            flight = SetFlight()
            return
        }
        // Reduce Motion and Low Power: the trail number simply appears.
        if reduceMotion || lowPower {
            withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { flow.momentLanded() }
            return
        }
        let reps = Double(moment.reps)
        let startX = CGFloat(moment.number - 1) * (StackMarkGeometry.normal.width + StackMarkGeometry.gap) + 6
        let restY = Slot.marks - 16
        flight = SetFlight(lift: 0, strike: 0, gathered: false, flying: false, x: startX, y: restY, scale: 1)
        // 1. The plates lift in order, 70 ms apart.
        withAnimation(.linear(duration: 0.07 * reps)) { flight.lift = reps }
        try? await Task.sleep(for: .seconds(0.07 * reps + 0.1))
        guard !Task.isCancelled else { return land(moment) }
        // 2. The green strike draws across.
        withAnimation(.easeOut(duration: 0.24)) { flight.strike = 1 }
        try? await Task.sleep(for: .seconds(0.28))
        guard !Task.isCancelled else { return land(moment) }
        // 3. They gather into the number.
        withAnimation(Theme.Motion.house) {
            flight.gathered = true
            flight.scale = 1
        }
        try? await Task.sleep(for: .seconds(0.3))
        guard !Task.isCancelled else { return land(moment) }
        // 4. The number arcs to the trail and shrinks to 26 pt with a small bounce (x and y ease differently).
        let endX = max(rowWidth - 12, startX)
        withAnimation(.easeInOut(duration: 0.5)) { flight.x = endX }
        withAnimation(.easeOut(duration: 0.22)) { flight.y = 6 }
        try? await Task.sleep(for: .seconds(0.22))
        withAnimation(.spring(duration: 0.5, bounce: 0.35)) {
            flight.y = restY
            flight.scale = 26.0 / 44.0
        }
        try? await Task.sleep(for: .seconds(0.4))
        land(moment)
    }

    private func land(_ moment: WorkoutFlow.Moment) {
        guard flow.moment?.id == moment.id else { return }
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
            flow.momentLanded()
            flight = SetFlight()
        }
    }
}

// MARK: - The brief

extension WorkoutV2 {
    /// One line under the stacks: a receipt with its Undo, else the confirmation of the set just logged, else what
    /// last time was. Fixed slot; the line fits it and never wraps.
    func briefSlot(stage _: WorkoutFlow.Stage, finished: Bool, now: Date) -> some View {
        Group {
            if finished {
                finishedBrief(now: now)
            } else if let brief = flow.brief {
                briefLine(brief)
            } else if let confirmation = flow.confirmation, flow.moment == nil {
                confirmationLine(confirmation, now: now)
            } else if let last = lastTimeLine, flow.confirmation == nil {
                briefText(last)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentTransition(.opacity)
        .tesseraAnimation(Theme.Motion.house, value: flow.brief?.id)
    }

    private func briefText(_ text: String) -> some View {
        MeasureLine.text(text, size: 17)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func undoWord(_ action: @escaping () -> Void) -> some View {
        Button {
            cue.play(.undo)
            action()
        } label: {
            Text("Undo")
                .font(Theme.Training.words(17, weight: .semibold))
                .foregroundStyle(Theme.Colors.Accent.training)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func briefLine(_ brief: WorkoutFlow.Brief) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            ViewThatFits(in: .horizontal) {
                briefText(brief.text).fixedSize()
                briefText(brief.short ?? brief.text)
            }
            if let undo = brief.undo {
                Spacer(minLength: 0)
                undoWord {
                    undo()
                    flow.brief = nil
                }
            }
        }
    }

    /// "Set 1, 5 reps." with the 5 scrolling (no steppers); it keeps itself after 5 s ("Set 1, 5 reps, kept."), and the
    /// set can be taken back for 10 s.
    private func confirmationLine(_ confirmation: WorkoutFlow.Confirmation, now: Date) -> some View {
        let parts = TrainingWords.confirmationParts(set: confirmation.number, reps: confirmation.reps,
                                                    kept: confirmation.kept)
        let planned = Int(session.targetRepsOfCurrent)
        return HStack(spacing: 0) {
            Text(parts.before)
            if confirmation.kept {
                Text("\(confirmation.reps)").foregroundStyle(Theme.Colors.Accent.training)
            } else {
                ScrollingNumber(
                    value: Binding(get: { Double(confirmation.reps) }, set: { flow.setConfirmedReps(Int($0)) }),
                    step: 1, range: 1 ... Double(planned + 10), format: { String(Int($0)) }, name: "Reps",
                    spokenUnit: nil, font: Theme.Training.words(17, weight: .semibold),
                    color: Theme.Colors.Accent.training,
                    width: 26, alignment: .center
                )
            }
            Text(parts.after).lineLimit(1)
            if flow.canUndoLog(at: now) {
                Spacer(minLength: 0)
                undoWord { flow.undoLog() }
            }
        }
        .font(Theme.Training.words(17, weight: .medium))
        .foregroundStyle(Theme.Colors.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .task(id: "\(confirmation.setID)-\(confirmation.token)") {
            try? await Task.sleep(for: .seconds(WorkoutFlow.confirmSeconds))
            if !Task.isCancelled {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) {
                    flow.keepConfirmation(token: confirmation.token)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func finishedBrief(now: Date) -> some View {
        if session.canUndoFinish(at: now) {
            HStack(spacing: Theme.Spacing.m) {
                briefText("\(session.shownTitle), done.")
                Spacer(minLength: 0)
                undoWord { session.undoFinish() }
            }
        } else {
            briefText(doneBrief)
        }
    }

    /// "Last time 185 lb for 5": the unit rides at half size (the seam splits it).
    var lastTimeLine: String? {
        session.lastTimeBest.map { "Last time \(Format.mass($0.weight)) for \(Int($0.reps))" }
    }

    /// "Bench held at 185. Next Push A is Friday." (a private workout keeps the lift and its weight to itself).
    var doneBrief: String {
        TrainingWords.doneBrief(
            lift: session.entries.first.flatMap { session.exerciseClass(of: $0)?.name } ?? "Lift",
            held: "\(Self.weightText(session.weight)) \(Format.unit.symbol)", nextName: nextName, nextDay: nextDayName
        )
    }

    private var nextName: String {
        model.plan.flatMap { model.ledger.nextRoutine(in: $0, now: AppClock.now)?.title }
            .map { ObjectPrivacy.routineTitle($0, in: model.store) } ?? "your next session"
    }

    private var nextDayName: String {
        let plan = model.plan
        let perWeek = NowPage.sessionsPerWeek(model: model, plan: plan)
        let picker = NowPicker(engine: model.engine)
        let tesseraDay = TesseraDay()
        for ahead in 1 ... 7 {
            let day = tesseraDay.day(ahead, after: AppClock.now).addingTimeInterval(12 * 3600)
            if picker.restDay(plan: plan, at: day, sessionsPerWeek: perWeek) == nil {
                return day.formatted(.dateTime.weekday(.wide))
            }
        }
        return "soon"
    }
}

// MARK: - The session wheel

/// One row of the session wheel: the header that scrolls away, or a lift.
struct SessionWheelItem: Identifiable, Equatable {
    enum Kind: Equatable {
        case header(lifts: Int)
        case lift(LiftRow)
    }

    let id: String
    let kind: Kind
}

extension WorkoutV2 {
    var wheelItems: [SessionWheelItem] {
        let rows = flow.rows()
        return [SessionWheelItem(id: "header", kind: .header(lifts: rows.count))]
            + rows.map { SessionWheelItem(id: $0.id.uuidString, kind: .lift($0)) }
    }

    /// The wheel's home: the current lift (row 0 is the header).
    var homeIndex: Int {
        1 + min(session.currentIndex, max(session.entries.count - 1, 0))
    }

    var sessionWheel: some View {
        DepthWheel(
            items: wheelItems, focus: $wheelFocus, home: homeIndex, style: .session, minFocus: 1,
            paused: !model.workoutPath.isEmpty, label: "This session",
            onTap: { item, wasFocused in
                guard wasFocused, case let .lift(row) = item.kind, let classID = row.classID else { return }
                model.open(.classDef(classID))
            },
            rowIdentifier: { $0.id }
        ) { item, state in
            switch item.kind {
            case let .header(lifts):
                sessionHeader(lifts)
            case let .lift(row):
                liftRow(row, state: state)
            }
        }
        .padding(.bottom, Theme.Spacing.xs)
    }

    private func sessionHeader(_ lifts: Int) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            Text("This session")
            Text("\(lifts) \(lifts == 1 ? "lift" : "lifts")")
        }
        .font(Theme.Training.words(15, weight: .semibold, relativeTo: .footnote))
        .textCase(.uppercase)
        .tracking(0.6)
        .foregroundStyle(Theme.Colors.Slate.label)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// A lift on the wheel: its name (22 pt 600 cobalt with "now" for the current one, ink 600 for a browsed one, ink 2
    /// for the rest), what it holds, and its stacks at the right. Finished lifts strike in go green, skipped in ink 3.
    private func liftRow(_ row: LiftRow, state: WheelRowState) -> some View {
        let isNow = row.state == .current
        let isBrowsed = state.isFocused && !isNow
        let kindColor = Theme.Colors.Split.color(forName: row.name)
        let color: Color = isNow ? kindColor : (isBrowsed ? Theme.Colors.ink : Theme.Colors.inkSecondary)
        let weight: Font.Weight = isNow || isBrowsed ? .semibold : .regular
        return HStack(spacing: Theme.Spacing.s) {
            Text(row.name)
                .font(Theme.Training.words(22, weight: weight, relativeTo: .title3))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
                .overlay { strike(for: row.state) }
                .layoutPriority(1)
            if isNow {
                Text("now")
                    .font(Theme.Training.words(15, weight: .semibold, relativeTo: .footnote))
                    .foregroundStyle(kindColor)
                    .lineLimit(1)
            }
            Spacer(minLength: Theme.Spacing.s)
            Text(row.info)
                .font(Theme.Training.words(16))
                .foregroundStyle(Theme.Colors.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            // Tapping a lift's stacks opens its page, whether or not the row is in front.
            StackRow(sets: row.marks, spoken: row.info)
                .contentShape(Rectangle())
                .highPriorityGesture(TapGesture().onEnded {
                    if let classID = row.classID {
                        model.open(.classDef(classID))
                    }
                })
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.name), \(row.info)\(isNow ? ", now" : "")")
    }

    @ViewBuilder
    private func strike(for state: LiftRow.State) -> some View {
        switch state {
        case .done:
            Rectangle().fill(Theme.Colors.Go.green).frame(height: 1)
        case .skipped:
            Rectangle().fill(Theme.Colors.inkTertiary).frame(height: 1)
        case .current, .upcoming:
            EmptyView()
        }
    }
}

// MARK: - The foot

extension WorkoutV2 {
    /// The foot holds ONE word: Done warming up, Log set N, Skip rest, Finish. Drag it left or right for other options.
    @ViewBuilder
    func foot(stage: WorkoutFlow.Stage, finished: Bool, now _: Date) -> some View {
        if finished {
            ActionWord(word: "Back to today", action: leave)
        } else {
            switch stage {
            case .warmUp:
                ActionWord(word: TrainingWords.doneWarming, left: ActionOption(name: "Skip warm up") {
                    flow.finishWarmUp()
                }, color: Theme.Colors.Go.green) {
                    flow.finishWarmUp()
                }
            case .rest:
                ActionWord(word: TrainingWords.skipRest, left: skipLiftOption, color: Theme.Colors.Go.green) {
                    withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) { session.skipRest() }
                }
            case .set:
                ActionWord(word: TrainingWords.footLog(set: session.currentSetNumber), left: skipLiftOption,
                           right: sameAgainOption)
                {
                    logSet()
                }
            case .done:
                ActionWord(word: TrainingWords.finish, left: ActionOption(name: "End workout", perform: endWorkout)) {
                    finish()
                }
            }
        }
    }

    /// "Skip this lift", or "End workout" when it is the last one left. Both come with a true Undo.
    private var skipLiftOption: ActionOption {
        flow.liftsToGo <= 1
            ? ActionOption(name: "End workout", perform: endWorkout)
            : ActionOption(name: "Skip this lift") {
                let name = session.currentExercise?.name ?? "Lift"
                let undo = flow.skipLift()
                flow.say("\(name), skipped.", undo: undo)
            }
    }

    /// Right, after a set: the same set again (same weight, the reps just done).
    private var sameAgainOption: ActionOption? {
        guard let entry = session.currentEntry, let last = session.setRows(of: entry).last else { return nil }
        return ActionOption(name: "Same again") {
            session.weight = last.weight
            logSet(reps: last.reps)
        }
    }

    private func logSet(reps: Double? = nil) {
        withTesseraAnimation(Theme.Motion.snappy, reduceMotion: reduceMotion) {
            flow.logWholeSet(reps: reps)
        }
        cue.play(.setLogged)
    }

    private func finish() {
        cue.play(.done)
        finishedHaptic += 1
        withTesseraAnimation(.easeOut(duration: 0.4), reduceMotion: reduceMotion) { flow.finish() }
    }

    /// "End workout": finishes with what is logged; Undo restores the running workout.
    private func endWorkout() {
        finish()
    }

    /// The workout is finished; leaving drops it into today (the old finish's own steps).
    private func leave() {
        if FinishWords.isOn, let finished = session.finishedAt {
            let label = ObjectPrivacy.shownLabel(of: session.workout, in: model.store, classes: model.classes)
            FinishMoment.shared.record(
                name: session.workout.title,
                privateLabel: label ?? (session.isPrivate ? session.shownTitle : nil),
                setCount: session.summary.sets,
                duration: finished.timeIntervalSince(session.startedAt),
                routineID: model.store.linkedObjects("routine", of: session.workout).first?.id
            )
        }
        let finishedWorkout = session.workout
        WorkoutFlows.drop(session)
        model.isWorkoutPresented = false
        model.session = nil
        model.touch()
        if LiveV2.isOn, PagesV2Switch.isOn {
            model.open(.object(finishedWorkout.id), .deeper)
        }
    }
}
