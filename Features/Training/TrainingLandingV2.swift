import SwiftUI
import TesseraCore

/// Training's landing, v2 (sheet 230), in fixed slots: the "Training" title at 40 pt, three stat lines, a 118 pt slot
/// for today, two doors (This week and Library, each a 26 pt word with one ink 2 line under it) and one action word at
/// the foot. It never jumps into the workout and shows no weight or bar. Pages slide in from the right; the left edge
/// or Esc goes back. A private workout shows "Private workout" in the name slot.
struct TrainingLandingV2: View {
    enum Page: Equatable {
        case today, week, library
    }

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var page: Page?
    @State private var cue = HapticCue()
    @State private var brief: LandingBrief?
    @FocusState private var keyboard: Bool

    var stats: TrainingStatsSource = LedgerTrainingStats()

    struct LandingBrief: Identifiable {
        let id = UUID()
        let text: String
        let undo: (() -> Void)?
    }

    enum Slot {
        static let today: CGFloat = 118
        static let line: CGFloat = 28
        static let brief: CGFloat = 40
        static let foot: CGFloat = 36
    }

    var body: some View {
        let _ = model.revision
        ZStack(alignment: .topLeading) {
            if let page {
                pageView(page)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
                    .zIndex(1)
            } else {
                landing
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(x: -40)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .focusable()
        .focused($keyboard)
        .onKeyPress(.escape) {
            guard page != nil else { return .ignored }
            close()
            return .handled
        }
        .simultaneousGesture(edgeBack)
        .tesseraFeedback(cue)
    }

    // MARK: Pages

    private func open(_ next: Page) {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { page = next }
        cue.play(.pageTurn)
    }

    private func close() {
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { page = nil }
        cue.play(.pageTurn)
    }

    /// A drag in from the left edge goes back, as the system's does elsewhere.
    private var edgeBack: some Gesture {
        DragGesture(minimumDistance: CGFloat(GestureTuning.dragStart), coordinateSpace: .global).onEnded { drag in
            guard page != nil, drag.startLocation.x < CGFloat(GestureTuning.backEdge) + 4,
                  drag.translation.width > 70, abs(drag.translation.height) < 60 else { return }
            close()
        }
    }

    private func pageView(_ page: Page) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            BackWord(title: "Training", action: close)
            switch page {
            case .today:
                TrainingPage(inside: true)
            case .week:
                TrainingWeekPage(openToday: { open(.today) })
            case .library:
                TrainingLibraryV2(openToday: { open(.today) })
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: The landing

    private var landing: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = AppClock.adjust(context.date)
            let headline = stats.headline(model: model, now: now)
            let slot = slot(now: now)
            VStack(alignment: .leading, spacing: 0) {
                Text("Training")
                    .font(Theme.Training.words(40, weight: .semibold, relativeTo: .largeTitle))
                    .foregroundStyle(Theme.Colors.Accent.training)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, Theme.Spacing.s)
                statLines(headline)
                    .padding(.top, Theme.Spacing.m)
                todaySlot(slot, now: now)
                    .frame(height: typeSize.isAccessibilitySize ? nil : Slot.today, alignment: .topLeading)
                    .padding(.top, Theme.Spacing.l)
                doors(headline)
                    .padding(.top, Theme.Spacing.l)
                briefLine
                    .frame(height: Slot.brief, alignment: .leading)
                    .padding(.top, Theme.Spacing.s)
                foot(slot)
                    .frame(height: Slot.foot)
                    .padding(.top, Theme.Spacing.s)
                    .padding(.bottom, HomeSpatialView.dockClearance)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    // MARK: Stat lines

    /// "3 of 6 this week", "5 weeks in a row on plan", "+10 lb on bench since Oct 1" (the gain in go green); a tap on a
    /// line opens that lift, or the week.
    private func statLines(_ headline: TrainingHeadline) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Two lines (v3.2): the streak, its number in slate, and the gain in green. "3 of 6" lives on the week's
            // door.
            if headline.hasPlan {
                statButton(
                    Text("\(headline.weeksInARow)").font(Theme.Training.number(17, weight: .regular))
                        .foregroundStyle(Theme.Colors.Slate.label)
                        + Text(headline.streakLine.drop(while: { $0.isNumber })).font(Theme.Training.words(
                            17,
                            weight: .medium
                        )),
                    label: headline.streakLine
                ) { open(.week) }
            }
            if let parts = headline.gainParts(unit: Format.unit) {
                statButton(
                    MeasureLine.text(parts.gain, size: 17, weight: .medium).foregroundStyle(Theme.Colors.Go.green)
                        + MeasureLine.text(parts.rest, size: 17, weight: .medium),
                    label: parts.gain + parts.rest
                ) {
                    if let id = headline.gain?.classID {
                        model.open(.classDef(id))
                    }
                }
            }
            if let new = headline.newThing {
                statButton(
                    Text("New: \(new)").font(Theme.Training.words(17, weight: .medium))
                        .foregroundStyle(Theme.Colors.Gold.label),
                    label: "New, \(new)"
                ) { open(.library) }
            }
        }
    }

    private func statButton(_ text: Text, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            text
                .font(Theme.Training.words(17, weight: .medium))
                .foregroundStyle(Theme.Colors.ink)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Today's slot

    /// What today is, from the same source the Today's workout page reads.
    private func slot(now _: Date) -> TodaySlot {
        guard let source = model.trainingSource else { return .nothing }
        switch source {
        case let .running(session):
            let name = session.shownTitle
            let total = session.currentEntry.map(session.targetSets(of:)) ?? 1
            let liftsToGo = session.entries.count { !session.isFinished($0) }
            let lift = session.isPrivate ? nil : session.currentExercise?.name
            let line = lift.map { TrainingWords.going(lift: $0, set: session.currentSetNumber, of: total,
                                                      liftsToGo: liftsToGo) }
                ?? "Under way. \(liftsToGo) \(liftsToGo == 1 ? "lift" : "lifts") to go."
            return TodayClock.shared.isPaused ? .paused(name: name, whereLine: line)
                : .inProgress(name: name, whereLine: line)
        case let .done(summary):
            return .done(name: ObjectPrivacy.routineTitle(summary.title, in: model.store))
        case let .routine(routine):
            let name = ObjectPrivacy.routineTitle(routine.title, in: model.store)
            return SkippedToday.isSet ? .skipped(name: name) : .notStarted(name: name)
        case let .scheduled(workout):
            let name = ObjectPrivacy.routineTitle(workout.title, in: model.store)
            return SkippedToday.isSet ? .skipped(name: name) : .notStarted(name: name)
        }
    }

    @ViewBuilder
    private func todaySlot(_ slot: TodaySlot, now: Date) -> some View {
        switch slot {
        case let .notStarted(name):
            Button { open(.today) } label: {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    if typeSize.isAccessibilitySize {
                        Text(name)
                            .font(Theme.Training.words(24, weight: .semibold, relativeTo: .title))
                            .foregroundStyle(Theme.Colors.Split.color(forName: name))
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        FittedTitle(text: name, color: Theme.Colors.Split.color(forName: name))
                    }
                    MeasureLine.text(notStartedLine, size: 17)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .lineLimit(typeSize.isAccessibilitySize ? 2 : 1)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens today's workout")
        case let .inProgress(name, whereLine), let .paused(name, whereLine):
            runningSlot(slot, name: name, whereLine: whereLine, now: now)
        case let .done(name):
            struckSlot(name: name, line: "Done today")
        case let .skipped(name):
            struckSlot(name: name, line: "Skipped today")
        case .nothing:
            Button { open(.library) } label: {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Nothing planned")
                        .font(Theme.Training.words(34, weight: .semibold, relativeTo: .title))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("Build a routine in the library.")
                        .font(Theme.Training.words(17))
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// "4 lifts, about 55 min" for a day still to do.
    private var notStartedLine: String {
        var lifts = 0, sets = 0
        switch model.trainingSource {
        case let .routine(routine):
            let slots = routine.orderedChildren
            lifts = slots.count
            sets = slots.reduce(0) { $0 + Int(model.store.number("sets", of: $1) ?? 3) }
        case let .scheduled(workout):
            let entries = workout.orderedChildren
            lifts = entries.count
            sets = entries.reduce(0) { $0 + Int(model.store.number("targetSets", of: $1) ?? 3) }
        default: break
        }
        guard lifts > 0 else { return "Nothing to start yet" }
        return "\(lifts) \(lifts == 1 ? "lift" : "lifts"), about \(TrainingPage.estimatedMinutes(sets: sets)) min"
    }

    /// In progress: the green header, the clock with its Pause word, and where he is.
    private func runningSlot(_ slot: TodaySlot, name _: String, whereLine: String, now: Date) -> some View {
        let paused = TodayClock.shared.isPaused
        let started = model.session?.startedAt ?? now
        let elapsed = TodayClock.shared.elapsed(since: started, now: now)
        return Button { open(.today) } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(slot.header ?? "")
                    .font(Theme.Training.words(15, weight: .semibold, relativeTo: .footnote))
                    .foregroundStyle(paused ? Theme.Colors.inkTertiary : Theme.Colors.Go.green)
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                    Text(Format.duration(elapsed))
                        .font(Theme.Training.number(56, weight: .thin, relativeTo: .largeTitle))
                        .foregroundStyle(paused ? Theme.Colors.inkTertiary : Theme.Colors.ink)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .tesseraAnimation(Theme.Motion.snappy, value: Int(elapsed))
                    Text(slot.clockWord ?? "")
                        .font(Theme.Training.words(22, weight: .semibold, relativeTo: .title3))
                        .foregroundStyle(Theme.Colors.Accent.training)
                        .lineLimit(1)
                        .onTapGesture { togglePause() }
                        .accessibilityAddTraits(.isButton)
                }
                Text(whereLine)
                    .font(Theme.Training.words(17))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens today's workout")
        .accessibilityAction(named: slot.clockWord ?? "Pause") { togglePause() }
    }

    private func struckSlot(name: String, line: String) -> some View {
        Button { open(.today) } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(name)
                    .font(Theme.Training.words(34, weight: .semibold, relativeTo: .title))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    // A 1 px strike, not a decoration: the day is done or skipped.
                    .overlay { Rectangle().fill(Theme.Colors.inkSecondary).frame(height: 1) }
                Text(line)
                    .font(Theme.Training.words(17))
                    .foregroundStyle(Theme.Colors.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func togglePause() {
        if TodayClock.shared.isPaused {
            TodayClock.shared.resume()
        } else {
            TodayClock.shared.pause()
        }
        cue.play(.selection)
    }

    // MARK: Doors

    private func doors(_ headline: TrainingHeadline) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            door("This week", line: weekLine(headline)) { open(.week) }
            door("Library", line: MeasureLine.text(libraryLine, size: 17)) { open(.library) }
        }
    }

    private func door(_ word: String, line: Text, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(word)
                    .font(Theme.Training.words(26, weight: .semibold, relativeTo: .title2))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                line
                    .foregroundStyle(Theme.Colors.ink)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(word)
    }

    /// "3 of 6 this week, Pull A next": the 3 and the name in blue (today and what is next), the rest ink.
    private func weekLine(_ headline: TrainingHeadline) -> Text {
        guard headline.hasPlan else { return Text("") }
        let week = model.ledger.week(containing: AppClock.now, plan: model.plan, now: AppClock.now)
        let names = week.filter { $0.state == .today || $0.state == .upcoming }.compactMap { day in
            day.planned.map { ObjectPrivacy.routineTitle($0.title, in: model.store) }
        }
        let words = Theme.Training.words(17)
        let count = Text("\(headline.done)").font(Theme.Training.number(17, weight: .regular))
            .foregroundStyle(Theme.Colors.Accent.training)
        let rest = Text(" of \(headline.planned) this week").font(words)
        guard let next = names.first else { return count + rest }
        let firstIsToday = week.first { $0.state == .today || $0.state == .upcoming }?.state == .today
        return count + rest + Text(", ").font(words) + Text(next).font(words)
            .foregroundStyle(Theme.Colors.Split.color(forName: next))
            + Text(firstIsToday ? " today" : " next").font(words)
    }

    private var libraryLine: String {
        let routines = model.objects(of: .routine).filter { !$0.isDeleted }.count
        let exercises = model.classDef(.exercise).map { ClassResolver.descendants(of: $0).count } ?? 0
        return "\(routines) \(routines == 1 ? "routine" : "routines"), \(exercises) exercises"
    }

    // MARK: The foot

    @ViewBuilder
    private var briefLine: some View {
        if let brief {
            HStack(spacing: Theme.Spacing.m) {
                Text(brief.text)
                    .font(Theme.Training.words(17))
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let undo = brief.undo {
                    Button {
                        cue.play(.undo)
                        undo()
                        self.brief = nil
                    } label: {
                        Text("Undo")
                            .font(Theme.Training.words(17, weight: .semibold))
                            .foregroundStyle(Theme.Colors.Accent.training)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .transition(.opacity)
        } else {
            Color.clear
        }
    }

    private func say(_ text: String, undo: (() -> Void)?) {
        let line = LandingBrief(text: text, undo: undo)
        withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { brief = line }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(GestureTuning.undoSeconds))
            if brief?.id == line.id {
                withTesseraAnimation(Theme.Motion.house, reduceMotion: reduceMotion) { brief = nil }
            }
        }
    }

    /// The action word: "Start Push A" or "Resume Push A". Left: Skip today (not started) or End workout. Right while
    /// it runs: Pause, or Go on.
    @ViewBuilder
    private func foot(_ slot: TodaySlot) -> some View {
        if let word = slot.actionWord {
            switch slot {
            case .notStarted:
                ActionWord(word: typeSize.isAccessibilitySize ? "Start" : word,
                           left: ActionOption(name: "Skip today", perform: skipToday), action: start)
                    .accessibilityLabel(word)
            default:
                ActionWord(
                    word: word,
                    left: ActionOption(name: "End workout", perform: endWorkout),
                    right: ActionOption(name: TodayClock.shared.isPaused ? "Go on" : "Pause", perform: togglePause)
                ) {
                    model.isWorkoutPresented = true
                }
            }
        } else if case .skipped = slot {
            ActionWord(word: "Undo skip") {
                SkippedToday.set(false)
                model.touch()
            }
        } else {
            Color.clear
        }
    }

    private func start() {
        model.workoutRisesFromLane = false
        switch model.trainingSource {
        case let .routine(routine): model.startRoutine(routine)
        case let .scheduled(workout): model.startWorkout(workout)
        case .running, .done: model.isWorkoutPresented = true
        case nil: open(.library)
        }
        TodayClock.shared.reset()
    }

    private func skipToday() {
        SkippedToday.set(true)
        model.touch()
        say("Today, skipped.") {
            SkippedToday.set(false)
            model.touch()
        }
    }

    /// "End workout": finishes with what is logged; Undo restores the running workout.
    private func endWorkout() {
        guard let session = model.session else { return }
        let workout = session.workout
        let name = session.shownTitle
        let record = try? model.engine.perform(FinishWorkout(workout: workout.id, time: AppClock.now), by: .user).record
        model.session = nil
        TodayClock.shared.reset()
        model.touch()
        say("\(name), ended.") {
            if let record {
                model.engine.undo(record)
            }
            model.session = WorkoutSession(workout: workout, model: model)
            model.touch()
        }
    }
}
